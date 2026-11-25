; Instalador de Valtiq para Windows (Inno Setup 6).
;
; Lo arma el workflow "Build Windows" en GitHub; nadie tiene que instalar
; Inno Setup. Para compilarlo a mano en Windows:
;   iscc /DAppVersion=1.9.1 /DSourceDir=<carpeta Release> /DOutputDir=dist windows\installer\valtiq.iss
;
; - Se instala en la carpeta del usuario (%LOCALAPPDATA%\Programs\Valtiq),
;   sin pedir permisos de administrador.
; - Crea el acceso en el menú Inicio (así sale en la búsqueda) y, si el
;   usuario lo marca, en el escritorio.
; - Se desinstala desde Configuración → Aplicaciones.
; - Los datos (base de datos, perfil) viven en otra carpeta
;   (%APPDATA%\com.valtiq\...) y NO se borran al desinstalar ni al
;   actualizar.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\build\windows\x64\runner\Release"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\dist"
#endif

[Setup]
; Este AppId identifica a Valtiq ante Windows: NUNCA cambiarlo, o una
; versión nueva se instalaría al lado de la vieja en vez de actualizarla.
AppId={{6F3B2A1C-8D4E-4C7A-9B1F-2E5D7A9C3B60}
AppName=Valtiq
AppVersion={#AppVersion}
AppVerName=Valtiq {#AppVersion}
AppPublisher=Valtiq
AppPublisherURL=https://github.com/Sebastian-Code-0/Valtiq
AppSupportURL=https://github.com/Sebastian-Code-0/Valtiq/issues
DefaultDirName={autopf}\Valtiq
DefaultGroupName=Valtiq
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#OutputDir}
OutputBaseFilename=valtiq-v{#AppVersion}-windows-instalador
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\valtiq.exe
UninstallDisplayName=Valtiq
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
; Si Valtiq está abierto al actualizar, se ofrece cerrarlo.
CloseApplications=yes

[Languages]
Name: "es"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "escritorio"; Description: "Crear un acceso directo en el escritorio"; GroupDescription: "Accesos directos:"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; El AppUserModelID debe ser el mismo de NotificationService
; (lib/services/notification_service.dart): así Windows asocia los avisos
; a este acceso directo, con su nombre y su logo.
Name: "{autoprograms}\Valtiq"; Filename: "{app}\valtiq.exe"; AppUserModelID: "com.valtiq.Valtiq"
Name: "{autodesktop}\Valtiq"; Filename: "{app}\valtiq.exe"; Tasks: escritorio; AppUserModelID: "com.valtiq.Valtiq"

[Run]
Filename: "{app}\valtiq.exe"; Description: "Abrir Valtiq"; Flags: nowait postinstall skipifsilent
