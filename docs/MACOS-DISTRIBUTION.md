# Signed macOS distribution

This workflow is for direct downloads, not Mac App Store submission. It never
installs the app or changes sleep settings. The existing GitHub release workflow
still builds ad-hoc-signed artifacts; it does not use this local notarization flow.

## One-time credentials

Create a Developer ID Application certificate with its private key in the local
login keychain. Confirm it with `security find-identity -v -p codesigning`.

Create an app-specific password at https://account.apple.com/ under Sign-In and
Security. In your own Terminal, store credentials interactively:

```sh
xcrun notarytool store-credentials NoNap-notary --apple-id YOUR_APPLE_ACCOUNT --team-id YOUR_TEAM_ID
```

Omit `--password` so the password is entered at the secure prompt. Do not put it
in chat, source files, shell history, or environment files. Credentials are
validated with Apple and saved in the keychain. Never commit exported private keys.

## Build and notarize

From the repository root, replace the example identity with your actual identity:

```sh
export SIGNING_IDENTITY='Developer ID Application: YOUR_NAME (YOUR_TEAM_ID)'
TARGET=arm64-apple-macos26.0 ./macos/build.sh ./macos/dist/arm64
./macos/notarize.sh NoNap-notary ./macos/dist/arm64

TARGET=x86_64-apple-macos26.0 ./macos/build.sh ./macos/dist/x86_64
./macos/notarize.sh NoNap-notary ./macos/dist/x86_64
```

The build enables Hardened Runtime, requests a secure timestamp, and checks the
signature. Notarization submits an app ZIP, checks for Apple's Accepted result,
staples the app, packages it in a signed DMG, then submits and staples the DMG.
It verifies tickets and Gatekeeper assessments and refreshes the DMG checksum
after stapling. Apple submission reports are retained in each output directory.

If already signed builds are ready, run only the `notarize.sh` commands. Do not
run the default build/package command afterward: it rebuilds with ad-hoc signing
unless SIGNING_IDENTITY is set, and rebuilding removes the stapled app ticket.

The two architecture folders contain identically named DMGs. Before uploading
both to one release, give them architecture-specific filenames and regenerate
their `.sha256` files. Keep existing public release assets until replacements
have passed installation testing. These scripts do not publish automatically.

## Failures and verification

For a rejected submission, use its ID from `notarization-app.json` or
`notarization-dmg.json`:

```sh
xcrun notarytool log SUBMISSION_ID --keychain-profile NoNap-notary
```

If waiting times out, query `notarytool info SUBMISSION_ID --keychain-profile
NoNap-notary` before resubmitting. A valid code signature alone is not proof of
notarization. Test the downloaded artifact on a clean Mac, including launch,
permission approval, timer and battery behavior, and uninstall. Intel builds
require separate Intel testing; cross-compilation alone does not verify runtime
behavior. Signing and notarization do not remove administrator permission needed
by the current power-management implementation.
