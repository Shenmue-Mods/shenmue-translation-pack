program fontutil;

uses
  Forms,
  main in 'main.pas' {frmMain},
  fontmgr in 'engine\fontmgr.pas',
  fontexec in 'fontexec.pas',
  systools in '..\..\..\Common\systools.pas',
  uitools in '..\..\..\Common\uitools.pas',
  appver in '..\..\..\Common\appver.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Shenmue Font Utility';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
