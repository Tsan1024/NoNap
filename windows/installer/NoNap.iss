#ifndef MyAppVersion
  #define MyAppVersion "0.0.3"
#endif

#define MyAppName "NoNap"
#define MyAppPublisher "NoNap contributors"
#define MyAppURL "https://github.com/Tsan1024/NoNap"
#define MyAppExeName "NoNap.exe"

[Setup]
AppId={{62BA4864-117D-4FF8-B175-8F45556D8148}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases
DefaultDirName={localappdata}\Programs\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
LicenseFile=..\..\LICENSE
OutputDir=..\dist\installer
OutputBaseFilename=NoNap-{#MyAppVersion}-Windows-x64-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#MyAppExeName}
SetupIconFile=..\assets\NoNap.ico
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\dist\win-x64\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
function InitializeUninstall(): Boolean;
var
  ResultCode: Integer;
begin
  Result := Exec(
    ExpandConstant('{app}\{#MyAppExeName}'),
    '--restore-and-exit',
    '',
    SW_HIDE,
    ewWaitUntilTerminated,
    ResultCode
  ) and (ResultCode = 0);

  if not Result then
    MsgBox(
      'NoNap could not restore the previous lid settings. Open NoNap and turn it off before uninstalling.',
      mbError,
      MB_OK
    );
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
    RegDeleteValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Run', 'NoNap');
end;
