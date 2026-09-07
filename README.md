<p align="center">
  <img src="assets/nonap-icon.png" width="112" alt="NoNap icon">
</p>

<h1 align="center">NoNap</h1>

<p align="center"><strong>Close the lid. Keep it working.</strong></p>
<p align="center"><a href="README.zh-CN.md">简体中文</a></p>

NoNap is a small macOS menu-bar and Windows tray utility for long-running local work. Turn it on before closing your laptop and the system can continue compiling, downloading, training, or running an agent.

The macOS and Windows apps use their platform's native power-management interfaces. No account or telemetry is involved.

## Interface

<p align="center">
  <img src="assets/nonap-panel.png" width="296" alt="NoNap menu-bar panel">
</p>

## What you get

- One switch for lid-closed operation.
- A 0–24 hour countdown shown with explicit units (`10h 00m → 9h 59m`) and a matching slider; `0` means no limit.
- A configurable battery cutoff from 5% to 50%.
- Automatic stop when Low Power Mode or Battery Saver becomes active on battery.
- A display-only battery-time estimate based on native system data.
- Optional Open at Login and English / Simplified Chinese UI.

NoNap remembers a manual language selection. On first launch, it uses Simplified Chinese when the Mac's preferred language starts with `zh`; otherwise it uses English.

## Platforms

| Platform | Support | Implementation |
|---|---|---|
| macOS | Apple silicon (arm64) and Intel (x86_64), macOS 26 or later | Swift, AppKit, IOKit, `pmset` |
| Windows | Windows 10/11 x64 | C#/.NET 8, WPF, Windows Power APIs |

The implementations live in [`macos/`](macos/) and [`windows/`](windows/). They share the
same product behavior but use separate native code and release packages.

## Install on macOS

NoNap supports Apple silicon and Intel x86_64 Macs running macOS 26 or later.
Download the archive matching your Mac from [Releases](https://github.com/Tsan1024/NoNap/releases):
`macOS-arm64` for Apple silicon or `macOS-x86_64` for Intel.

```sh
git clone https://github.com/Tsan1024/NoNap.git
cd NoNap
./macos/install.sh
```

The installer builds `/Applications/NoNap.app`, asks once for administrator approval, installs a narrowly scoped sudoers rule, and launches the app.

That rule permits only these two commands for the current user:

```text
/usr/bin/pmset -a disablesleep 0
/usr/bin/pmset -a disablesleep 1
```

To build without installing anything:

```sh
./macos/build.sh
```

To create a DMG:

```sh
./macos/package.sh
```

## Install on Windows

Download `NoNap-<version>-Windows-x64-Setup.exe` from
[Releases](https://github.com/Tsan1024/NoNap/releases), or use the portable x64 zip.
Windows Group Policy can prevent power-plan changes on managed computers; NoNap reports
that condition and remains off.

To build from source, install the .NET 8 SDK and run:

```powershell
.\windows\build.ps1
```

See [`windows/README.md`](windows/README.md) for the Windows power and recovery model.

## Remove on macOS

```sh
./macos/uninstall.sh
```

The uninstaller restores normal sleep, removes the app and login item, deletes the sudoers rule, and verifies that passwordless `pmset` access is gone.

## Safety notes

Lid-closed operation can increase heat and battery use. Keep the computer ventilated, choose a battery cutoff, and use a finite timer when leaving work unattended. The battery-time estimate changes with workload and never controls the safety cutoff.

See [SECURITY.md](SECURITY.md) for the permission model and [docs/AUDIT.md](docs/AUDIT.md) for verification steps.

## Acknowledgements

NoNap began as a derivative of [Sleepless](https://github.com/Aboudjem/Sleepless), created by Adam Boudjemaa. Thanks to Adam and the Sleepless project for the original menu-bar implementation and `pmset` approach. NoNap is independently maintained and is not an official Sleepless release. Original copyright notices are retained under the MIT license.

## License

[MIT](LICENSE)
