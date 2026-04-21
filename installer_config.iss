; Script généré par Antigravity pour l'application AGEPA
; Assurez-vous d'avoir installé Inno Setup (https://jrsoftware.org/isdl.php)

#define MyAppName "AGEPA App"
#define MyAppVersion "1.2.0"
#define MyAppPublisher "AGEPA"
#define MyAppExeName "agepa_app.exe"
#define BuildPath "d:\Workspace\FlutterApps\agepa_app\build\windows\x64\runner\Release"

[Setup]
; Identifiant unique (Généré pour cette application)
AppId={{D3E8A1F1-2B1A-4B2E-8E5A-C0F1A2D3E4F5}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
; Emplacement et nom du fichier d'installation généré
OutputDir="d:\Workspace\FlutterApps\agepa_app\installer"
OutputBaseFilename=AGEPA_App_Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
CloseApplications=force

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; L'exécutable principal
Source: "{#BuildPath}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
; Toutes les DLLs et dépendances
Source: "{#BuildPath}\*.dll"; DestDir: "{app}"; Flags: ignoreversion
; Le dossier des ressources (data)
Source: "{#BuildPath}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
