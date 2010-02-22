unit utils;

interface

uses
  Windows, SysUtils;

function GetAppVersion: string;
function GetApplicationDirectory: TFileName;
function GetWorkingTempDirectory: TFileName;
procedure LoadConfigDebug;
procedure LoadConfigMain;
procedure SaveConfigDebug;
procedure SaveConfigMain;

implementation

uses
  Forms, SysTools, XmlConf, Main, DebugLog;

const
  WORKING_TEMP_DIR = 'IPACTemp';
  CONFIG_ID        = 'ipacbrowser';

var
  sWorkingTempDirectory: TFileName;
  Configuration: TXmlConfigurationFile;
  
//------------------------------------------------------------------------------

function GetApplicationDirectory: TFileName;
begin
  GetApplicationDirectory :=
    IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName));
end;

//------------------------------------------------------------------------------

function GetAppVersion: string;
begin
  Result := GetApplicationVersion(LANG_FRENCH, SUBLANG_FRENCH);
end;

//------------------------------------------------------------------------------

procedure SaveFormConfig(Section: string; Form: TForm);
begin
  with Configuration do begin
    WriteInteger(Section, 'state', Integer(Form.WindowState));

    if Form.WindowState = wsMaximized then begin
      WriteInteger(Section, 'width', ReadInteger(Section, 'width', Form.Width));
      WriteInteger(Section, 'height', ReadInteger(Section, 'height', Form.Height));
      WriteInteger(Section, 'left', ReadInteger(Section, 'left', Form.Left));
      WriteInteger(Section, 'top', ReadInteger(Section, 'top', Form.Top));
    end else begin
      WriteInteger(Section, 'width', Form.Width);
      WriteInteger(Section, 'height', Form.Height);
      WriteInteger(Section, 'left', Form.Left);
      WriteInteger(Section, 'top', Form.Top);
    end;
  end;
end;

//------------------------------------------------------------------------------

procedure LoadFormConfig(Section: string; Form: TForm);
begin
  with Configuration do begin
    Form.Left := ReadInteger(Section, 'left', Form.Left);
    Form.Top := ReadInteger(Section, 'top', Form.Top);
    Form.Width := ReadInteger(Section, 'width', Form.Width);
    Form.Height := ReadInteger(Section, 'height', Form.Height);
    Form.WindowState := TWindowState(ReadInteger(Section, 'state',
      Integer(Form.WindowState)));
  end;
end;

//------------------------------------------------------------------------------

procedure LoadConfigDebug;
begin
  with Configuration do begin
    frmDebugLog.OnTop := ReadBool('debug', 'ontop', False);
    LoadFormConfig('debug', frmDebugLog);
    frmMain.DebugLogVisible := ReadBool('debug', 'visible', False);    
  end;
end;

//------------------------------------------------------------------------------

procedure LoadConfigMain;
begin
  with Configuration do begin
    frmMain.AutoSave := ReadBool('options', 'autosave', False);
    frmMain.MakeBackup := ReadBool('options', 'makebackup', True);
  end;
end;

//------------------------------------------------------------------------------

procedure SaveConfigDebug;
begin
  with Configuration do begin
    WriteBool('debug', 'visible', frmMain.DebugLogVisible);
    WriteBool('debug', 'ontop', frmDebugLog.OnTop);
    SaveFormConfig('debug', frmDebugLog);
  end;
end;

//------------------------------------------------------------------------------

procedure SaveConfigMain;
begin
  with Configuration do begin
    WriteBool('options', 'autosave', frmMain.AutoSave);
    WriteBool('options', 'makebackup', frmMain.MakeBackup);
  end;
end;

//------------------------------------------------------------------------------

procedure InitWorkingDirectory;
begin
  sWorkingTempDirectory := GetTempDir + WORKING_TEMP_DIR + '\';
  if not DirectoryExists(sWorkingTempDirectory) then
    ForceDirectories(sWorkingTempDirectory);
end;

//------------------------------------------------------------------------------

procedure DeleteWorkingTempDirectory;
begin
  if DirectoryExists(sWorkingTempDirectory) then
    DeleteDirectory(sWorkingTempDirectory);
end;

//------------------------------------------------------------------------------

function GetWorkingTempDirectory: TFileName;
begin
  if sWorkingTempDirectory = '' then
    InitWorkingDirectory;
  Result := sWorkingTempDirectory; 
end;

//------------------------------------------------------------------------------

function GetConfigFile: TFileName;
begin
  Result := GetApplicationDirectory + 'config.xml';
end;

//------------------------------------------------------------------------------

function InitConfigurationFile: TXmlConfigurationFile;
begin
  Result := TXmlConfigurationFile.Create(GetConfigFile, CONFIG_ID);
end;

//------------------------------------------------------------------------------

initialization
  sWorkingTempDirectory := '';              // see GetWorkingTempDirectory
  Configuration := InitConfigurationFile;   // Create the Configuration object

//------------------------------------------------------------------------------

finalization
  DeleteWorkingTempDirectory;
  Configuration.Free;

//------------------------------------------------------------------------------

end.