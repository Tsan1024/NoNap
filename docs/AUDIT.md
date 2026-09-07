# Audit & verify NoNap

The macOS build asks for a narrow slice of root, so it should be easy to check, not taken on
faith. This page is the practical companion to [SECURITY.md](../SECURITY.md): the latter
explains *why* the design is safe, this one shows you *how to confirm it yourself* and how
to verify a download you did not build.

There is no Apple account behind any of this. Every check below is free and runs on your
machine.

## Read it in about ten minutes

The whole app is one file. To satisfy yourself it does what it claims and nothing else:

| Read | What you are checking |
|---|---|
| [`macos/App.swift`](../macos/App.swift) | Normal root calls are only `sudo -n /usr/bin/pmset -a disablesleep 0/1`. One-time setup uses a fixed in-memory command to atomically install the grant; no mutable bundle script is executed as root. No network calls. |
| [`macos/nonap.sudoers.template`](../macos/nonap.sudoers.template) / [`macos/grant.sh`](../macos/grant.sh) | The passwordless grant permits exactly those two fully-specified commands, no wildcards, installed `root:wheel 0440`; its temporary file is created and validated in root-owned `/etc/sudoers.d`. |
| [`macos/build.sh`](../macos/build.sh) | `swiftc` + a hand-assembled, ad-hoc-signed bundle. No downloaded blobs, no install-time scripts baked into the binary. |
| [`macos/uninstall.sh`](../macos/uninstall.sh) | Removes the app, the login item, and the sudoers drop-in, then proves `sudo -n pmset …` prompts again. |
| [`windows/src/NoNap.App/PowerController.cs`](../windows/src/NoNap.App/PowerController.cs) | Saves, changes, verifies, and restores the Windows AC/DC lid actions; the only native calls are visible in one file. |

The single privileged file on your system is `/etc/sudoers.d/nonap-disablesleep`. Read
it, and `sudo rm` it any time to revoke everything.

## Verify a release you downloaded (did not build)

Release zips are built on a GitHub-hosted runner, checksummed, and signed with a Sigstore
build-provenance attestation. Two checks, both offline-friendly:

```sh
# 1. Integrity: the bytes match what the release published.
shasum -a 256 -c SHA256SUMS

# 2. Provenance: this exact zip was built by NoNap's GitHub Actions release
#    workflow, from this repo, at the released commit (SLSA Build L2, Sigstore-signed).
gh attestation verify <asset> -R Tsan1024/NoNap
```

What each one proves:

- **`shasum -c`** proves the file was not altered after publishing. It says nothing about
  *who* built it, so it is necessary but not sufficient on its own.
- **`gh attestation verify`** proves the file came out of this project's release workflow
  (a specific repository + commit + workflow), cryptographically, with no shared secret to
  leak. This is the strong link from "the source you can read" to "the binary you ran." It
  needs the GitHub CLI (`brew install gh`); the attestation itself lives in this repo and on
  the public Sigstore transparency log.

Neither check is Gatekeeper. macOS still treats the prebuilt app as unnotarized (see
[SECURITY.md](../SECURITY.md#code-signing-notarization-and-gatekeeper)). The point of these
two is supply-chain trust: that the download is the thing this repository built.

## Reproduce the build

The compile is deterministic for a given toolchain, so you can rebuild and compare the
**unsigned executable** byte for byte:

```sh
git clone https://github.com/Tsan1024/NoNap.git
cd NoNap && git checkout v<version>

# Choose arm64 or x86_64 to match the archive, then rebuild the executable.
ARCH=arm64
swiftc -O -parse-as-library -target "$ARCH-apple-macos26.0" \
  -framework AppKit -framework ServiceManagement macos/App.swift macos/BatteryEstimate.swift -o /tmp/NoNap-rebuilt

# Unzip the release and compare the Mach-O inside the bundle.
ditto -x -k "NoNap-<version>-macOS-$ARCH.zip" /tmp/rel
shasum -a 256 /tmp/NoNap-rebuilt /tmp/rel/NoNap.app/Contents/MacOS/NoNap
```

Caveats, stated honestly:

- The two hashes match **only with the same Swift/Command Line Tools version** used by the
  release runner (`macos-latest`). A different compiler version will produce a different,
  still-correct binary. The release job prints its toolchain in the **Toolchain** step so you
  can match it.
- The **signed** `.app` is only *likely* reproducible: ad-hoc code signatures embed
  non-deterministic data, so compare the unsigned Mach-O above, not the signed bundle. See
  the [Reproducible Builds definition](https://reproducible-builds.org/docs/definition/).

For most people the attestation is the easier and stronger guarantee; reproducing the build
is the deepest check if you want it.

## Scan it with VirusTotal

You can upload the release zip to [VirusTotal](https://www.virustotal.com) (free,
non-commercial, results public) for a multi-engine scan:

```sh
# With a free VirusTotal API key:
curl -s --request POST --url https://www.virustotal.com/api/v3/files \
  --header "x-apikey: $VT_API_KEY" \
  --form file=@NoNap-<version>-macOS-<arch>.zip
# …then open the returned analysis URL, or just drag the zip onto virustotal.com.
```

Note: ad-hoc-signed, unnotarized binaries draw more *heuristic* flags than notarized ones, so
read any detection in context. A clean result is reassuring, not absolute; pair it with the
attestation above.

**Public VirusTotal report (v1.1.0):** https://www.virustotal.com/gui/file/30a43590629b6a3cd2e1610c249c137c4b235a5f319ce8d8a9e866c1fd914cde

That is the permalink for the v1.1.0 zip (the SHA-256 matches `SHA256SUMS`). It goes live once the file is submitted to VirusTotal. Browser submission requires a one-time reCAPTCHA, so submit it from your browser (drag the zip onto virustotal.com) or with the API.

## Notarization (planned, not yet done)

NoNap is ad-hoc signed and **not notarized** today, because notarization needs a paid
Apple Developer ID. It is on the roadmap. The exact steps, for transparency and so anyone can
do it from a fork, are:

```sh
# One-time: store an app-specific password for notarytool.
xcrun notarytool store-credentials "notarytool-password" \
  --apple-id "<apple-id>" --team-id <TeamID> --password <app-specific-password>

# Re-sign with a Developer ID cert + hardened runtime + secure timestamp.
codesign --force --options runtime --timestamp \
  --sign "Developer ID Application: <Name> (<TeamID>)" NoNap.app

ditto -c -k --keepParent NoNap.app NoNap.zip
xcrun notarytool submit NoNap.zip --keychain-profile "notarytool-password" --wait
xcrun stapler staple NoNap.app
```

Prerequisite: [Apple Developer Program, $99/yr](https://developer.apple.com/programs/whats-included/),
and a "Developer ID Application" certificate. Notarization removes the
"Apple could not verify this app" first-launch block; it does not change anything about how
the app works. The `/etc/sudoers.d` install step is what makes NoNap ineligible for the
Mac App **Store**, but it does not block notarized *direct* distribution (notarization is an
automated malware scan, not a behavioral policy review).
