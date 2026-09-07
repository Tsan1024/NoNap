# NoNap for Windows

The Windows app supports Windows 10 and Windows 11 on x64 computers. It is a native
.NET 8 WPF tray application.

## Power behavior

When enabled, NoNap:

1. Saves the active power plan and its plugged-in and battery lid-close actions.
2. Changes both lid-close actions to `Do nothing`.
3. creates a Windows `PowerRequestSystemRequired` request to prevent idle sleep.
4. Restores the saved actions when the timer ends, the battery safety policy fires,
   the user turns NoNap off, or the app exits normally.

The saved session is journaled under `%LOCALAPPDATA%\NoNap`. If the previous process did
not exit normally, the next launch restores the saved settings before showing the UI.
NoNap preserves a lid setting changed outside the app while a session is active.

Windows Group Policy or device-management policy can reject power-plan changes. NoNap
reports that failure and remains off.

## Build

Install the .NET 8 SDK, then run in PowerShell:

```powershell
.\windows\build.ps1
```

The self-contained x64 executable is written to `windows\dist\win-x64\NoNap.exe`.
The release workflow also creates an Inno Setup installer and a portable zip. The
uninstaller asks the running app to stop, verifies that the saved lid actions were restored,
and aborts removal if recovery fails.
