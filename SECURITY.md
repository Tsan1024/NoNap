# Security Policy

NoNap changes a security-sensitive power setting, so it owes you a precise account of
what changes on each supported platform and how those changes are reversed.

## Reporting a vulnerability

If you find a security issue, please **do not open a public issue**. Use GitHub's
private vulnerability reporting for this repository with details and reproduction steps.
Coordinated disclosure is appreciated.

Supported version: the latest release on the `main` branch.

## What NoNap actually does on macOS

NoNap keeps a Mac awake with the lid closed by toggling an undocumented but
long-standing `pmset` setting:

```
sudo pmset -a disablesleep 1   # keep awake, even lid-closed
sudo pmset -a disablesleep 0   # restore normal sleep
```

`disablesleep` is **not** in Apple's `pmset(1)` man page (check: `man pmset`), but it
sets the kernel's `SleepDisabled` flag, which you can observe yourself:

```
pmset -g | grep SleepDisabled   # 1 = on, 0/absent = off
```

Because it is undocumented, Apple could change or remove it in a future macOS. NoNap
reads the live value back after every toggle, so the menu-bar state always reflects
reality rather than assuming the command worked.

## The macOS passwordless grant — exactly what it permits

A GUI app has no terminal to type a password into, so NoNap runs `pmset` through a
tightly scoped `/etc/sudoers.d` drop-in. The first in-app toggle (or `macos/grant.sh` for a
source install) writes this, owned `root:wheel`, mode `0440`:

```
<you> ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1
```

**This grant lets one user run, as root, exactly two fully-specified commands and nothing
else.** sudoers matches command arguments *literally* — and this rule contains **no
wildcards** — so the match is total. From the sudoers manual: *"If a Cmnd has associated
command line arguments, then the arguments in the Cmnd must match exactly those given by
the user on the command line (or match the wildcards if there are any)."*

Consequences you can rely on:

- `sudo pmset -a sleep 0`, `sudo pmset restoredefaults`, `sudo pmset -a hibernatemode 0`,
  or any other argument vector **do not match** the rule and will demand a password. The
  grant cannot be widened by appending flags.
- Normal toggles call `sudo` with an **argv array**, not a shell string
  (`Process.arguments` in `macos/App.swift`), so there is no command substitution or
  word-splitting surface in the recurring privileged path.
- The one-time setup runs a fixed command from the already-running app. It validates the
  account name and creates, validates, and renames its temporary file entirely inside
  root-owned `/etc/sudoers.d`; it never executes a mutable bundle resource as root.
- There is no persistent privileged helper or daemon. The permanent rule points directly
  at Apple's `/usr/bin/pmset`, and the sudoers file is `root:wheel 0440`.

## Honest residual risk

The grant is passwordless **by design**: any process already running as your user can flip
the sleep flag silently. We are not pretending the attack surface is zero. But the worst
case is *"your Mac was kept awake, or allowed to sleep."* It is **not** data exfiltration
and **not** root code execution — the two pinned arguments to one Apple binary do not
provide either.

If that trade is not acceptable to you, build from source and **don't** run `macos/install.sh`;
you can toggle `sudo pmset -a disablesleep 1/0` manually instead and skip the grant.

## Reboot resets it (a safety net you can verify)

`disablesleep` is a **runtime** setting. A reboot restores normal sleep — there is no way
for NoNap to leave your Mac permanently unable to sleep. Verify it yourself: toggle on,
reboot, then `pmset -g | grep SleepDisabled` should read `0`.

NoNap adds a second belt-and-suspenders: a **battery-floor auto-off** (default 15%)
that flips the flag back to `0` while the Mac is awake and discharging, so a forgotten
"on" state can't drain the battery to empty. Normal app termination also restores sleep.
Force-killing or crashing any user-space app can bypass its in-process timer and battery
monitor; reboot remains the recovery path for that case.

## What NoNap does on Windows

The Windows app is a per-user WPF tray application. It does not install a service or driver
and its manifest requests `asInvoker`, not administrator elevation. When the user enables
NoNap, it:

1. Reads the active power-plan GUID and the existing AC and DC lid-close actions.
2. Journals those values under `%LOCALAPPDATA%\NoNap\power-session.json`.
3. Sets both lid-close actions to `Do nothing` through the Windows Power APIs.
4. Holds a `PowerRequestSystemRequired` request while the session is active.

On turn-off, safety cutoff, normal exit, or uninstall, NoNap clears its power request and
restores the journaled actions. At the next launch it restores an unfinished journal before
doing anything else. If a user or administrator changes either lid action away from the
value NoNap wrote while a session is active, restoration preserves that newer value.

Group Policy or device-management policy may reject the change. NoNap reports the failure
and stays off. Windows cannot guarantee identical closed-lid behavior on every firmware and
Modern Standby implementation, so the Windows build should be treated as best effort and
tested on the target laptop before unattended use.

## Code signing, notarization, and Gatekeeper

NoNap is **ad-hoc signed and not notarized** — it has no paid Apple Developer ID. The
trust model is *read the source, build it yourself*. (Notarization is also not a malware
guarantee: signed, notarized macOS stealers have shipped.)

- **Build from source (recommended):** locally compiled apps are **not quarantined**, so
  Gatekeeper does not prompt — it just runs.
- **Download the prebuilt `.app`:** a release zip carries `com.apple.quarantine`, so
  Gatekeeper blocks first launch. Approve it via **System Settings → Privacy & Security →
  Open Anyway**, then confirm. Note: macOS 15 (Sequoia) **removed** the old
  right-click → Open bypass, so the System Settings path is the supported flow on macOS 15+.

## Why NoNap can't be on the Mac App Store

Some people trust App Store apps more, so it is worth saying plainly: NoNap can never
ship there, and that is a property of what it does, not an oversight.

App Review **§2.4.5(v)** states apps "may not request escalation to root privileges or use
setuid attributes." The passwordless root `pmset` toggle is exactly that, so it is the
decisive block. Two more rules independently rule it out: **§2.4.5(i)** (apps must be
sandboxed, and the sandbox has no entitlement for root or arbitrary system-file writes) and
**§2.5.2 / §2.4.5(ii)** (apps must be self-contained in their bundle and may not write
outside their container, which the `/etc/sudoers.d` drop-in does). A privileged-helper
workaround does not rescue it either: a helper installed from a sandboxed app must itself be
sandboxed, so it still cannot write `/etc/sudoers.d` or run arbitrary root commands.

The practical consequence: NoNap is **direct-download / Homebrew only**, by design. The
verification steps below, plus building from source, are how trust is established instead.

## Verifying a download

If you grab a prebuilt release instead of building it, you can confirm it is genuinely this
project's build, with no Apple account and no shared secret:

```sh
shasum -a 256 -c SHA256SUMS                                  # bytes match what was published
gh attestation verify <asset> -R Tsan1024/NoNap               # built by this repo's release workflow
```

The full walkthrough (what each check proves, how to reproduce the build, and a VirusTotal
scan) is in **[docs/AUDIT.md](docs/AUDIT.md)**.

## Completely removing the privilege

`./macos/uninstall.sh` restores normal sleep, removes the app and login item, deletes the
sudoers drop-in, and then **proves** revocation by showing that `sudo -n pmset …` prompts
for a password again. The single file to audit or delete by hand is
`/etc/sudoers.d/nonap-disablesleep`.

## Primary sources

- Apple `pmset(1)` man page (no `disablesleep`): https://keith.github.io/xcode-man-pages/pmset.1.html
- sudoers manual (exact-arg match, includedir filename rules): https://www.sudo.ws/docs/man/1.9.0/sudoers.man/
- Passwordless sudo for programs (scope / root-own / revoke): https://jozefcipa.com/blog/how-to-use-sudo-without-a-password-in-your-programs/
- Apple — Safely open apps / Open Anyway flow: https://support.apple.com/en-us/102445
- Apple Developer — Sequoia removes Control-click Gatekeeper bypass: https://developer.apple.com/news/?id=saqachfa
- Living without notarization (ad-hoc + quarantine behavior): https://eclecticlight.co/2024/10/01/living-without-notarization/
- App Store Review Guidelines (§2.4.5 root escalation / sandbox / self-contained): https://developer.apple.com/app-store/review/guidelines/
- GitHub artifact attestations (build provenance, SLSA): https://docs.github.com/en/actions/security-guides/using-artifact-attestations-to-establish-provenance-for-builds
