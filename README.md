<!-- Language switcher. Keep this row identical across every README.<lang>.md. -->
<p align="center">
  <b>English</b> &nbsp;·&nbsp;
  <a href="README.zh-CN.md">简体中文</a> &nbsp;·&nbsp;
  <a href="README.es.md">Español</a> &nbsp;·&nbsp;
  <a href="README.ja.md">日本語</a> &nbsp;·&nbsp;
  <a href="README.fr.md">Français</a> &nbsp;·&nbsp;
  <a href="README.de.md">Deutsch</a>
</p>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/hero-dark.gif">
    <source media="(prefers-color-scheme: light)" srcset="assets/hero-light.gif">
    <img alt="Sleepless: keep your Mac awake with the lid closed" src="assets/hero-light.gif" width="780">
  </picture>
</p>

<p align="center">
  <b>Sleepless keeps your MacBook awake with the lid closed, on battery, with no external display.</b><br>
  <sub>One native menu-bar switch, with an auto-off timer and a battery-floor cutoff so you never drain it flat.</sub>
</p>

<p align="center">
  <a href="https://github.com/Aboudjem/Sleepless/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/Aboudjem/Sleepless/ci.yml?branch=main&label=CI&logo=githubactions&logoColor=white"></a>
  <a href="https://github.com/Aboudjem/Sleepless/releases/latest"><img alt="Release" src="https://img.shields.io/github/v/release/Aboudjem/Sleepless?label=release&logo=apple&logoColor=white"></a>
  <a href="https://github.com/Aboudjem/Sleepless/releases"><img alt="Downloads" src="https://img.shields.io/github/downloads/Aboudjem/Sleepless/total?label=downloads"></a>
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/github/license/Aboudjem/Sleepless?color=blue"></a>
  <img alt="Platform" src="https://img.shields.io/badge/macOS-26%20·%20Apple%20Silicon-7c5cf0?logo=apple&logoColor=white">
  <a href="https://github.com/Aboudjem/Sleepless/stargazers"><img alt="Stars" src="https://img.shields.io/github/stars/Aboudjem/Sleepless?style=social"></a>
</p>

<p align="center">
  <img alt="Sleepless demo: flip the switch, set an auto-off timer, drag the battery-floor slider" src="assets/demo.gif" width="760">
</p>

> [!NOTE]
> Closing the lid normally sleeps your Mac, and `caffeinate`-based apps (KeepingYouAwake and friends) **cannot** change that, by design. Sleepless flips the one setting that can, `pmset disablesleep`, then guards it with an auto-off timer and a battery-floor cutoff so it is safe to forget.

## What Sleepless does

Sleepless is a tiny macOS menu-bar app that keeps your MacBook awake with the lid closed, on battery, with no external display and no dummy HDMI plug. You click the coffee cup in the menu bar, flip one switch, and close the lid: your Mac keeps running. Flip it back, or let the auto-off timer or the battery floor turn it off for you, and normal sleep returns. A reboot always resets it.

It is a single native AppKit file. No Dock icon, no background daemon, no kernel extension, no dependencies. If you have ever typed `sudo pmset -a disablesleep 1` in Terminal and then forgotten to turn it back off, this is that command as a safe, one-click switch.

## Why other keep-awake apps can't do this

Most keep-awake apps (KeepingYouAwake, Caffeine, Theine, Lungo, and the built-in `caffeinate` command) are built on macOS power assertions. Power assertions stop the *idle* timer, but they cannot override the hardware lid-close trigger, so a closed lid still sleeps the Mac. The KeepingYouAwake maintainer says this plainly: "caffeinate doesn't support this. KYA uses caffeinate under the hood" ([issue #66](https://github.com/newmarcel/KeepingYouAwake/issues/66)).

The one setting that overrides lid-close sleep is `pmset disablesleep`, which sets the kernel's `SleepDisabled` flag. Sleepless toggles exactly that, reads the value back so the menu bar never lies, and wraps it in safety nets. Amphetamine can also keep the lid closed, but it builds on the same assertion layer and is widely reported to fail on Apple Silicon when the power source changes ([Amphetamine-Enhancer #28](https://github.com/x74353/Amphetamine-Enhancer/issues/28)).

## Features

|  |  |
|---|---|
| ☕ **One switch** | Click the coffee cup in the menu bar, flip the toggle. An empty cup means normal sleep, a full cup means awake, a full cup with a dot means awake on battery with the safety net live. |
| ⏲️ **Auto-off timer** | Keep awake for 1 hour or 2 hours with a live countdown, then it turns itself off. The timer lives in memory only, so quitting or rebooting clears it. |
| 🔋 **Battery-floor cutoff** | Pick a floor (5–50%, default 15%). On battery, Sleepless turns itself off before you run flat. |
| 🪫 **Low Power Mode auto-off** | On battery, if Low Power Mode is on, Sleepless steps aside and lets the Mac sleep, the same safety shape as the battery floor. |
| 🖥️ **No display, no dongle** | Just the lid closed, on battery. No external monitor, no dummy HDMI plug, no clamshell adapter. |
| 🚀 **Launch at login** | Optional, off by default. It always starts in the off state and never re-enables sleep prevention on its own. |
| 🪶 **Tiny and native** | One AppKit file with SF Symbols. No Dock icon, no background daemon, no kext, no dependencies. |

## Install

**Homebrew** (recommended):

```sh
brew install --cask aboudjem/tap/sleepless
# one-time: add the passwordless grant (it prints exactly what it writes first)
/Applications/Sleepless.app/Contents/Resources/grant.sh
```

**Build from source** (the trust path: read it, build it, no Gatekeeper prompt):

```sh
git clone https://github.com/Aboudjem/Sleepless.git
cd Sleepless && ./install.sh
```

**Or download the app:** grab the [latest release](https://github.com/Aboudjem/Sleepless/releases/latest), unzip, and move `Sleepless.app` to `/Applications`. It is ad-hoc signed, so approve the first launch in **System Settings → Privacy & Security → Open Anyway** (the old right-click → Open trick was removed in macOS 15).

Downloaded a release? You can confirm it is genuinely this project's build, with no Apple account:

```sh
shasum -a 256 -c SHA256SUMS
gh attestation verify Sleepless-*.zip -R Aboudjem/Sleepless
```

The full verification walkthrough is in [docs/AUDIT.md](docs/AUDIT.md).

## How to use

1. Click the coffee cup in the menu bar.
2. Flip **Keep awake with lid closed** on.
3. Optionally pick a 1h or 2h auto-off timer, and set the battery floor you trust.
4. Close the lid. Your Mac keeps running on battery.

Turn the switch off, let the timer or battery floor turn it off, or reboot, and normal sleep returns. `./uninstall.sh` removes everything and proves the grant is gone.

## Sleepless vs the alternatives

| | **Sleepless** | Amphetamine | KeepingYouAwake | `caffeinate` |
|---|:---:|:---:|:---:|:---:|
| Awake, lid closed, no monitor | ✅ ¹ | ⚠️ ² | ❌ ³ | ❌ |
| On battery | ✅ | ✅ | ✅ (lid open) | ⚠️ ⁴ |
| Auto-off timer | ✅ | ✅ | ✅ | ❌ |
| Auto-off on low battery | ✅ | ✅ | ✅ | ❌ |
| Open source | ✅ MIT | ❌ App Store | ✅ MIT | Apple |
| Cost | Free | Free | Free | Free |

<sub>As of 2026-06. ¹ Sleepless uses `pmset disablesleep`, the mechanism built for lid-close, and reads the flag back so the UI reflects reality; behavior on any keep-awake tool is still hardware and macOS-version dependent. ² Amphetamine documents closed-display mode but is widely reported to fail on Apple Silicon when the power source changes ([Amphetamine-Enhancer #28](https://github.com/x74353/Amphetamine-Enhancer/issues/28); the developer's own [failed-sessions note](https://iffy.freshdesk.com/support/solutions/articles/48001180528)); the app itself is closed source (only its support repo is open). ³ KeepingYouAwake cannot keep the lid closed by design, since it wraps `caffeinate` ([issue #66](https://github.com/newmarcel/KeepingYouAwake/issues/66)). ⁴ `caffeinate -i` runs on battery; `-s` is AC-only per the man page. Corrections welcome.</sub>

## Use it to…

- 🤖 **Finish a long job after you walk away.** An AI agent run, a build, a render, ML training, a big `brew`/`npm` install: switch it on, close the lid, drop it in your bag, come back to a finished job.
- 📡 **Share your hotspot on the move.** Internet Sharing or Personal Hotspot from the Mac keeps serving with the lid shut.
- ⬇️ **Leave big transfers running.** Large downloads, uploads, or a Time Machine backup complete while you step away.
- 🖥️ **Keep a server or SSH session alive.** A local dev server, a sync daemon, or a remote session stays reachable, lid closed.
- 🎧 **Keep audio going.** Music or a long render keeps playing in the bag.

> [!TIP]
> Set the battery floor to a level you trust (say 20%) and an auto-off timer, and you can do all of the above without babysitting the battery.

## How it works

`caffeinate` and the power assertions it uses can't override the hardware lid-close trigger, so a closed lid always sleeps the Mac. The one system setting that overrides it is `pmset disablesleep`, which flips the kernel's `SleepDisabled` flag. Sleepless toggles it from a native switch, reads the live value back so the UI never lies, and reverts it at your battery floor, in Low Power Mode, or when the timer ends. A reboot also resets it.

Because a GUI app can't type a password, the installer adds a tightly scoped `/etc/sudoers.d` rule (root-owned, `0440`) that permits **exactly two commands and nothing else**:

```
<you> ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1
```

- **It can't be widened.** `sudoers` matches arguments literally with no wildcards, so any other command re-prompts for a password.
- **No daemon, no helper script** for an attacker to hijack. It calls Apple's `/usr/bin/pmset` directly with an argv array, no shell.
- **Always reversible.** A reboot resets the flag, the battery floor and timer turn it off, and `./uninstall.sh` removes the grant and proves it.

The full threat model, the undocumented-but-real `disablesleep` evidence, why it can't go on the Mac App Store, and how to verify a download are in **[SECURITY.md](SECURITY.md)** and **[docs/AUDIT.md](docs/AUDIT.md)**.

## FAQ

<details>
<summary><b>How do I keep my MacBook awake with the lid closed without a monitor?</b></summary>

Install Sleepless, click the coffee cup in the menu bar, flip the switch on, and close the lid. It keeps the Mac awake on battery with no external display, using `pmset disablesleep`. No dummy HDMI plug or clamshell adapter is needed.
</details>

<details>
<summary><b>Why does my MacBook sleep when I close the lid even with Amphetamine or KeepingYouAwake?</b></summary>

Because those tools are built on macOS power assertions, which stop the idle timer but cannot override the hardware lid-close trigger. KeepingYouAwake wraps `caffeinate`, whose maintainer confirms it "doesn't support this" ([issue #66](https://github.com/newmarcel/KeepingYouAwake/issues/66)). Amphetamine tries, but is widely reported to break on Apple Silicon when the power source changes. `pmset disablesleep`, which Sleepless uses, is a lower-level setting that can override lid-close sleep.
</details>

<details>
<summary><b>Does <code>pmset disablesleep</code> still work on Apple Silicon (M1/M2/M3)?</b></summary>

Yes. `pmset -a disablesleep 1` sets the kernel's `SleepDisabled` flag on Apple Silicon, confirmed firsthand on macOS 26.3, which keeps a MacBook awake with the lid closed on battery. Apple does not officially document the setting, so verify it on your own machine with `pmset -g | grep SleepDisabled` (it should read `1`). Most claims that it "no longer works on M1/M2/M3" actually describe `caffeinate` or caffeinate-based apps (Amphetamine, KeepingYouAwake), which were never able to prevent lid-closed sleep, a different mechanism, not a `pmset disablesleep` regression.
</details>

<details>
<summary><b>Can I keep my MacBook awake on battery with the lid closed?</b></summary>

Yes. That is the whole point of Sleepless, and it is what sets it apart from `caffeinate`-based apps. Set a battery floor and an auto-off timer so it can't drain the Mac while it runs unattended.
</details>

<details>
<summary><b>What is the difference between <code>caffeinate</code> and disabling lid sleep?</b></summary>

`caffeinate` holds a power assertion that prevents *idle* sleep while the lid is open, and it cannot stop a closed lid from sleeping the Mac. Disabling lid sleep with `pmset disablesleep` flips a kernel flag that overrides the lid-close trigger itself, which is why it works with the lid shut.
</details>

<details>
<summary><b>How is Sleepless different from Amphetamine and KeepingYouAwake?</b></summary>

Sleepless does one thing, lid-closed keep-awake on battery, with a safety-first design: an auto-off timer, a battery-floor cutoff, Low Power Mode auto-off, and a reboot reset. It is open source (MIT), one small AppKit file with no daemon or kext, and it uses `pmset disablesleep` rather than the assertion layer that limits the others.
</details>

<details>
<summary><b>Is it safe to run a MacBook with the lid closed? Will it overheat or drain the battery?</b></summary>

It is safe for light, unattended work like downloads, syncs, or a hotspot. Heavy sustained load with the lid fully closed reduces airflow, so use judgement there. To protect the battery, Sleepless turns itself off at the floor you set and in Low Power Mode, and the auto-off timer caps how long it stays on.
</details>

<details>
<summary><b>Do I need a dummy HDMI display plug to use clamshell mode?</b></summary>

No. Apple's official clamshell mode needs external power and a display, but Sleepless keeps the Mac awake with the lid closed on battery alone, with no display and no HDMI dongle.
</details>

<details>
<summary><b>Does Sleepless require sudo, a kernel extension, or a background daemon?</b></summary>

It needs one tightly scoped `sudo` grant (two exact `pmset` commands, nothing else) so a GUI app can flip the setting without a password prompt. There is no kernel extension and no background daemon. The whole app is a single AppKit file.
</details>

<details>
<summary><b>The coffee cup doesn't show in my menu bar.</b></summary>

macOS 26 can hide menu-bar items. Check System Settings (Control Center / Menu Bar) and allow Sleepless to show its item. Confirm it is running with <code>pgrep -x Sleepless</code>.
</details>

<details>
<summary><b>How do I stop Sleepless and restore normal sleep?</b></summary>

Flip the switch off, or let the auto-off timer or the battery floor turn it off, and normal sleep returns immediately. A reboot also resets it, and `./uninstall.sh` removes the app, the login item, and the sudoers grant, then proves the grant is gone.
</details>

<details>
<summary><b>Can I run AI agents or long jobs overnight with the lid closed?</b></summary>

Yes. Switch Sleepless on, set a battery floor, close the lid, and an agent run, build, render, or training job keeps going. Plug in for an all-nighter, or stay on battery with a floor and timer so it stops itself before the battery runs low.
</details>

<details>
<summary><b>Why isn't it notarized?</b></summary>

It is a personal, open-source tool with no paid Apple Developer ID, so it is ad-hoc signed. Build from source to skip Gatekeeper entirely, or use the **Open Anyway** flow for the prebuilt app. Notarization is documented as a planned next step in [docs/AUDIT.md](docs/AUDIT.md).
</details>

<details>
<summary><b>Does it work on Intel or older macOS?</b></summary>

It is verified on **macOS 26 Apple Silicon**. `disablesleep` is undocumented, so other versions or hardware aren't guaranteed. Try it and report back, honest reports are welcome.
</details>

## Contributing

Issues and PRs welcome, especially translations and test reports from other hardware. See [CONTRIBUTING.md](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md). Sleepless stays deliberately small.

## License

[MIT](LICENSE) © 2026 Adam Boudjemaa.

<p align="center">
  <sub>If Sleepless saved you a trip to Terminal, a ⭐ helps other people find it.</sub>
</p>
