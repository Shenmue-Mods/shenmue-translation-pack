unit Main;

interface

uses
  Windows, SysUtils, Forms, Graphics, Classes, Controls, StdCtrls, ComCtrls,
  ExtCtrls, JvExStdCtrls, JvCombobox, JvDriveCtrls, OpThBase, Unpacker, Common,
  AppEvnts, Dialogs, JvBaseDlg, JvBrowseFolder, JvRichEdit, JvExComCtrls,
  JvListView, JvExControls, JvLinkLabel, UITools;

type
  TfrmMain = class(TForm)
    pcWizard: TPageControl;
    tsHome: TTabSheet;
    pnlTop: TPanel;
    pnlBottom: TPanel;
    pnlLeft: TPanel;
    tsDisclamer: TTabSheet;
    tsDiscAuth: TTabSheet;
    tsAuthFail: TTabSheet;
    btnPrev: TButton;
    btnNext: TButton;
    btnCancel: TButton;
    btnAbout: TButton;
    imgLeft: TImage;
    imgBottom: TImage;
    imgTop: TImage;
    tsLicense: TTabSheet;
    tsParams: TTabSheet;
    tsDone: TTabSheet;
    tsWorking: TTabSheet;
    lblHomeTitle: TLabel;
    lblLicenseTitle: TLabel;
    rbnLicenseAccept: TRadioButton;
    rbnLicenseDecline: TRadioButton;
    lblDiscAuthTitle: TLabel;
    lblDisclamerTitle: TLabel;
    lblAuthFailTitle: TLabel;
    lblParamsTitle: TLabel;
    lblWorkingTitle: TLabel;
    lblDoneTitle: TLabel;
    grpDiscAuthSelectDrive: TGroupBox;
    grpDiscAuthProgress: TGroupBox;
    pbValidator: TProgressBar;
    cbxDrives: TJvDriveCombo;
    grpWorkingProgress: TGroupBox;
    pbTotal: TProgressBar;
    grpParamsExtract: TGroupBox;
    edtOutputDir: TEdit;
    btnParamsBrowse: TButton;
    tsReady: TTabSheet;
    tsDoneFail: TTabSheet;
    lblReadyTitle: TLabel;
    lblDoneFailTitle: TLabel;
    lblUnpackProgress: TLabel;
    grpDoneFailErrorMessage: TGroupBox;
    memDoneFail: TMemo;
    ApplicationEvents: TApplicationEvents;
    bfdOutput: TJvBrowseForFolderDialog;
    imgError: TImage;
    imgWarn: TImage;
    reEula: TJvRichEdit;
    grpInfos: TGroupBox;
    lvwInfos: TJvListView;
    chkDisclamerRead: TCheckBox;
    lklHomeMessage: TJvLinkLabel;
    lklReleaseInfosDblClick: TJvLinkLabel;
    lklDisclamerMessage: TJvLinkLabel;
    lklLicenseMessage: TJvLinkLabel;
    lklDiscAuthMessage: TJvLinkLabel;
    lklAuthFailMessage: TJvLinkLabel;
    lklParamsMessage: TJvLinkLabel;
    lklReadyMessage: TJvLinkLabel;
    lklWorkingMessage: TJvLinkLabel;
    lklDoneMessage: TJvLinkLabel;
    lklDoneFailMessage: TJvLinkLabel;
    lklDiscAuthWarning: TJvLinkLabel;
    lklParamsUnpackedSize: TJvLinkLabel;
    lklParamsExtractToOutputDir: TJvLinkLabel;
    lklDoneFailGroupMessage: TJvLinkLabel;
    tmrLoadRes: TTimer;
    chkOpenOutputDir: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure pcWizardChanging(Sender: TObject; var AllowChange: Boolean);
    procedure btnNextClick(Sender: TObject);
    procedure btnPrevClick(Sender: TObject);
    procedure pcWizardChange(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure rbnLicenseAcceptClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ApplicationEventsException(Sender: TObject; E: Exception);
    procedure btnParamsBrowseClick(Sender: TObject);
    procedure reEulaURLClick(Sender: TObject; const URLText: string;
      Button: TMouseButton);
    procedure btnAboutClick(Sender: TObject);
    procedure lvwInfosAdvancedCustomDrawSubItem(Sender: TCustomListView;
      Item: TListItem; SubItem: Integer; State: TCustomDrawState;
      Stage: TCustomDrawStage; var DefaultDraw: Boolean);
    procedure lvwInfosMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure lvwInfosDblClick(Sender: TObject);
    procedure chkDisclamerReadClick(Sender: TObject);
    procedure lklHomeMessageLinkClick(Sender: TObject; LinkNumber: Integer;
      LinkText, LinkParam: string);
    procedure tmrLoadResTimer(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure pcWizardDrawTab(Control: TCustomTabControl; TabIndex: Integer;
      const Rect: TRect; Active: Boolean);
  private
    { Déclarations privées }
    fCanceledByClosingWindow: Boolean;
    fStatusProgress: Double;
    fStatusProgressMax: Double;    
    fWorkingThread: TOperationThread;
    fUnlockPasswords: TPackagePasswords;
    fUnpackedSize: Int64;
    fSecondaryResourceExtracted: Boolean;

    procedure AddDebug(Msg: string);

    procedure DiscValidatorFailed(Sender: TObject);
    procedure DiscValidatorProgress(Sender: TObject; Current, Total: Int64);
    procedure DiscValidatorSuccess(Sender: TObject; const MediaKey: string);
    procedure DiscValidatorFinish(Sender: TObject);

    procedure PackageUnlockStart(Sender: TObject; Total: Int64);
    procedure PackageUnlockProgress(Sender: TObject; Current, Total: Int64);
    procedure PackageUnlockFinish(Sender: TObject);

    procedure WorkingThreadTerminateHandler(Sender: TObject);

    procedure DoIdentificationProcess;
    procedure DoCheckExtractParams;
    procedure DoUnlockPackage;

    procedure InitWizard;
    procedure InitSecondaryExtraResources;
    function GetPageIndex: Integer;
    function GetPageIndexMax: Integer;
    function OnWizardBeforePageChange: Boolean;
    procedure OnWizardAfterPageChange;
    procedure SetPageIndex(const Value: Integer);
    procedure SetUnpackedSize(const Value: Int64);

    procedure SetStatusProgress(const Value: Double);
    procedure SetStatusProgressMax(const MaxValue: Double);

    property SecondaryResourceExtracted: Boolean read fSecondaryResourceExtracted;
    property UnlockPasswords: TPackagePasswords read fUnlockPasswords;
    property UnpackedSize: Int64 read fUnpackedSize write SetUnpackedSize;
    property WorkingThread: TOperationThread read fWorkingThread
      write fWorkingThread;
  public
    { Déclarations publiques }
    procedure Next;
    procedure Previous;
    function MsgBox(Text, Title: string; Flags: Integer): Integer;
    property PageIndex: Integer read GetPageIndex write SetPageIndex;
    property PageIndexMax: Integer read GetPageIndexMax;
  end;

var
  frmMain: TfrmMain;

implementation

uses
  SysTools, ResMan, JvTypes, DiscAuth, Math, WorkDir, About, AppVer;

const
  // Screen pages indexes
  SCREEN_HOME = 0;
  SCREEN_DISCLAMER = 1;
  SCREEN_LICENSE = 2;
  SCREEN_CHECKDISC = 3;
  SCREEN_CHECKDISC_FAILED = 4;
  SCREEN_EXTRACT_PARAMETERS = 5;
  SCREEN_READY_TO_EXTRACT = 6;
  SCREEN_WORKING = 7;
  SCREEN_FINISH = 8;
  SCREEN_FINISH_FAILED = 9;

  // Buttons action behaviors
  BUTTON_ACTION_DEFAULT = 0;
  BUTTON_ACTION_DO_IDENTIFICATION = 1;
  BUTTON_ACTION_FINISH = 2;
  BUTTON_ACTION_SHOW_CHECKDISC = 3;
  BUTTON_ACTION_DO_UNLOCK_PACKAGE = 4;
  BUTTON_ACTION_CHECK_EXTRACT_PARAMS = 5;

{$R *.dfm}

procedure TfrmMain.AddDebug(Msg: string);
begin
  memDoneFail.Lines.Add(DateToStr(Now) + ' ' + TimeToStr(Now) + ': ' + Msg);
end;

procedure TfrmMain.ApplicationEventsException(Sender: TObject; E: Exception);
begin
  AddDebug('UNCAUGHT EXCEPTION: ' + E.ClassName + ' - ' + E.Message);
  LoadWizardUI('DoneFail');
  PageIndex := SCREEN_FINISH_FAILED;
end;

procedure TfrmMain.btnAboutClick(Sender: TObject);
begin
  RunAboutBox;
end;

procedure TfrmMain.btnCancelClick(Sender: TObject);
begin
  fCanceledByClosingWindow := False;
  Close;
end;

procedure TfrmMain.btnNextClick(Sender: TObject);
begin
  Next;
end;

procedure TfrmMain.btnParamsBrowseClick(Sender: TObject);
begin
  with bfdOutput do
  begin
    if DirectoryExists(edtOutputDir.Text) then
      Directory := edtOutputDir.Text;
    if Execute then
      edtOutputDir.Text := Directory;
  end;
end;

procedure TfrmMain.btnPrevClick(Sender: TObject);
begin
  Previous;
end;

procedure TfrmMain.chkDisclamerReadClick(Sender: TObject);
begin
  btnNext.Enabled := chkDisclamerRead.Checked;
end;

procedure TfrmMain.DiscValidatorFailed(Sender: TObject);
begin
  // Error when trying to get the media key !!
  PageIndex := SCREEN_CHECKDISC_FAILED;
end;

procedure TfrmMain.DiscValidatorFinish(Sender: TObject);
var
  Thread: TDiscValidatorThread;

begin
  pbValidator.Position := 0;
  // if discvalidator is cancelled, then show the failed screen...
  Thread := WorkingThread as TDiscValidatorThread;
  if Thread.Aborted then
    PageIndex := SCREEN_CHECKDISC_FAILED;
  cbxDrives.Enabled := True;
end;

procedure TfrmMain.DiscValidatorProgress;
begin
  pbValidator.Max := Total;
  pbValidator.Position := Current;
end;

procedure TfrmMain.DiscValidatorSuccess;
var
  USize: Int64;

begin
{$IFDEF DEBUG}
  WriteLn('DiscValidatorSuccess: MediaKey = ', MediaKey);
{$ENDIF}

  // The media key was successfully retrieved, now we have to check if it's valid or not.
  // The MAIN method of this shit... GetUnlockKeys will try to get the unlock keys of the
  // release package!!!
  if GetUnlockKeys(MediaKey, UnlockPasswords, USize) then
  begin
    UnpackedSize := USize;
    PageIndex := SCREEN_EXTRACT_PARAMETERS;
  end else
    PageIndex := SCREEN_CHECKDISC_FAILED;
end;

procedure TfrmMain.DoCheckExtractParams;
var
  Drive: TFileName;
  i: Integer;
  Space: Int64;
  S: string;
  SU: TSizeUnit;

  function _GetMsgText(Code: string): string;
  begin
    Result := GetStringUI('MsgText', Code);
    Result := StringReplace(Result, '<#OutputDrive>', Drive, [rfIgnoreCase, rfReplaceAll]);
  end;

begin
  // if the path is empty can't continue.
  Drive := UpperCase(ExtractFileDrive(edtOutputDir.Text));
  if Length(Drive) < 2 then
  begin
    MsgBox(_GetMsgText('OutputDirectoryNotSpecified'), GetStringUI('MsgTitle', 'Error'), MB_ICONERROR);
    Exit;
  end;

  // Getting the drive index
  i := DriveCharToInteger(Drive[1]);
  if i = -1 then
  begin
    MsgBox(_GetMsgText('DriveInvalid'), GetStringUI('MsgTitle', 'Error'), MB_ICONERROR);
    Exit;
  end;

  // Getting free space
  Space := DiskFree(i);
  if Space = -1 then
  begin
    MsgBox(_GetMsgText('DriveDoesntExists'), GetStringUI('MsgTitle', 'Error'), MB_ICONERROR);
    Exit;
  end;

  // Calculating if we can extract the files here...
  Space := Space - UnpackedSize;
  if Space < 0 then
  begin
    S := _GetMsgText('DriveNoMuchSpace');
    S := StringReplace(S, '<#NeededSpace>', FormatByteSize(Space, SU) + ' '
      + SizeUnitToString(SU), [rfReplaceAll, rfIgnoreCase]);
    MsgBox(S, GetStringUI('MsgTitle', 'Warning'), MB_ICONWARNING);
    Exit;
  end;

  // OK, go to the next page.
  PageIndex := SCREEN_READY_TO_EXTRACT;
end;

procedure TfrmMain.DoIdentificationProcess;
begin
  fCanceledByClosingWindow := True;
  
  btnNext.Enabled := False;
  btnPrev.Enabled := False;
  cbxDrives.Enabled := False;
  
  // Do the disc authentification...

  WorkingThread.Free; // destroying previous thread object if exists

  // create a new thread for validate the disc...
  WorkingThread := TDiscValidatorThread.Create;
  with (WorkingThread as TDiscValidatorThread) do begin
    OnFail := DiscValidatorFailed;
    OnProgress := DiscValidatorProgress;
    OnSuccess := DiscValidatorSuccess;
    OnFinish := DiscValidatorFinish;
    Drive := cbxDrives.Drive;
    Resume;
  end;
end;

procedure TfrmMain.DoUnlockPackage;
begin
  PageIndex := SCREEN_WORKING;
  fCanceledByClosingWindow := True;
  WorkingThread.Free;
  WorkingThread := TPackageExtractorThread.Create;
  with (WorkingThread as TPackageExtractorThread) do
  begin
    Passwords.Assign(UnlockPasswords);
    OnStart := PackageUnlockStart;
    OnProgress := PackageUnlockProgress;
    OnFinish := PackageUnlockFinish;
    OutputDirectory := edtOutputDir.Text;
    Resume;
  end;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
var
  CanDo: Integer;

begin
  if Assigned(WorkingThread) and (not WorkingThread.Terminated) then
  begin
    Action := caNone;
    WorkingThread.Suspend;

    // Disable buttons...
    btnCancel.Enabled := False;
    SetCloseWindowButtonState(Self, False);

    CanDo := MsgBox(GetStringUI('MsgText', 'ConfirmCancel'),
      GetStringUI('MsgTitle', 'Question'),
      MB_ICONQUESTION + MB_YESNO + MB_DEFBUTTON2);

    if CanDo = IDYES then begin
      // The OnTerminate event is for auto-closing the window when the thread is stopped
      WorkingThread.OnTerminate := WorkingThreadTerminateHandler;

      // Cancel the DiscValidator process...
      WorkingThread.Abort;
    end else begin
      btnCancel.Enabled := True;
      SetCloseWindowButtonState(Self, True);
    end;

    WorkingThread.Resume;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
{$IFDEF DEBUG}
  edtOutputDir.Text := 'C:\Temp\~rlzout\';
{$ELSE}
  edtOutputDir.Text := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName));
{$ENDIF}
  edtOutputDir.SelectAll;

  DoubleBuffered := True;
  pbValidator.DoubleBuffered := True;
  pcWizard.DoubleBuffered := True;

  Caption := Application.Title;
  fUnlockPasswords := TPackagePasswords.Create;

  // Init the About Box
  InitAboutBox(
    Application.Title,
    GetApplicationVersion
  );

  InitWizard;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  UnlockPasswords.Free;
  WorkingThread.Free;
  cbxDrives.ImageSize := isSmall;
end;

procedure TfrmMain.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = Chr(VK_ESCAPE) then
  begin
    Key := #0;
    Close;
  end;
end;

function TfrmMain.GetPageIndex: Integer;
begin
  Result := pcWizard.ActivePageIndex;
end;

function TfrmMain.GetPageIndexMax: Integer;
begin
  Result := pcWizard.PageCount - 1;
end;

procedure TfrmMain.InitSecondaryExtraResources;
begin
  if not SecondaryResourceExtracted then
  begin
{$IFDEF DEBUG}
  WriteLn('InitSecondaryExtraResources');
{$ENDIF}
  
    // Decompress Secondary resource. Primary are ready.
    fSecondaryResourceExtracted := DecompressSecondaryExtraResourcePackage;
    
    // Load the EULA
    if FileExists(GetWorkingTempDirectory + APPCONFIG_EULA) then
      reEula.Lines.LoadFromFile(GetWorkingTempDirectory + APPCONFIG_EULA);
  end;
end;

procedure TfrmMain.InitWizard;
var
  S: string;
{$IFDEF RELEASE}
  i: Integer;
{$ENDIF}

begin
{$IFDEF RELEASE}
  // There is a memory leak in the JvDriveCtrl and it's really anonying...
  cbxDrives.ImageSize := isLarge;

  // Hide PageControl Tabs
  for i := 0 to pcWizard.PageCount - 1 do
    pcWizard.Pages[i].TabVisible := False;
{$ENDIF}

  // Handling the Color of the Wizard TPageControl
//  pcWizard.OwnerDraw := True;
  pcWizard.Brush.Style := bsSolid;

  // Select the home.
  pcWizard.ActivePage := tsHome;

  // Loading message file
  InitializeResourcesManager; // don't move this !

  // Load images
  InitializeSkin;

  // Load the first page resource!
  LoadWizardUI('Home');

  // Modify the Wizard Title
  S := AppNameWizardTitle;
  if S <> '' then Caption := S;
  if AppNameShow and (Caption <> Application.Title) then
    Caption := Caption + ' - ' + Application.Title;
      
  // Fill the home infos
  FillReleaseInfo;

  // Set if the button must be disabled or not.
  OnWizardAfterPageChange;
end;

procedure TfrmMain.lvwInfosAdvancedCustomDrawSubItem(Sender: TCustomListView;
  Item: TListItem; SubItem: Integer; State: TCustomDrawState;
  Stage: TCustomDrawStage; var DefaultDraw: Boolean);
begin
// Item.Data := LISTVIEW_RELEASE_INFO_ITEM_WEBURL;
  if (SubItem > 0) and (Integer(Item.Data) = LISTVIEW_RELEASE_INFO_ITEM_WEBURL) then
  begin
    Sender.Canvas.Font.Color := clBlue;
    Sender.Canvas.Font.Style := [fsUnderline];
  end;
end;

procedure TfrmMain.lvwInfosDblClick(Sender: TObject);
begin
  if lvwInfos.Cursor = crHandPoint then
    OpenLink(lvwInfos.ItemFocused.SubItems[0]);
end;

procedure TfrmMain.lvwInfosMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  HoverItem: TListItem;

begin
  lvwInfos.Cursor := crDefault;
  if (X > lvwInfos.Columns[0].Width) then
  begin
    HoverItem := lvwInfos.GetItemAt(X,  Y);
    if Assigned(HoverItem) and (HoverItem.SubItems.Count > 0) then
      if Integer(HoverItem.Data) = LISTVIEW_RELEASE_INFO_ITEM_WEBURL then
        lvwInfos.Cursor := crHandPoint;
  end;
end;

function TfrmMain.MsgBox(Text, Title: string; Flags: Integer): Integer;
begin
  Result := MessageBoxA(Handle, PAnsiChar(Text), PAnsiChar(Title), Flags);
end;

procedure TfrmMain.Next;
begin
  case btnNext.Tag of
    // Default: Next page
    BUTTON_ACTION_DEFAULT:
      pcWizard.SelectNextPage(True, False);

    // Finish
    BUTTON_ACTION_FINISH:
      begin
        if (PageIndex = SCREEN_FINISH) and chkOpenOutputDir.Checked then
          OpenWindowsExplorer(edtOutputDir.Text);
        Close;
      end;

    // Launch Identification process
    BUTTON_ACTION_DO_IDENTIFICATION:
      DoIdentificationProcess;

    // Check the extract params.
    BUTTON_ACTION_CHECK_EXTRACT_PARAMS:
      DoCheckExtractParams;

    // Launch the unpack process
    BUTTON_ACTION_DO_UNLOCK_PACKAGE:
      DoUnlockPackage;
  end;
end;

procedure TfrmMain.OnWizardAfterPageChange;
var
  UISectionName: string;
  
begin
  // Reset default values
  btnPrev.Enabled := PageIndex > 0;
  btnNext.Enabled := True;

  btnPrev.Caption := GetStringUI('Buttons', 'Previous');
  btnNext.Caption := GetStringUI('Buttons', 'Next');
  btnNext.Tag := BUTTON_ACTION_DEFAULT;
  btnPrev.Tag := BUTTON_ACTION_DEFAULT;

  rbnLicenseAccept.Checked := False;
  rbnLicenseDecline.Checked := True;

  // Do something special with the current page...
  case PageIndex of
    // Disclamer
    SCREEN_DISCLAMER:
      btnNext.Enabled := chkDisclamerRead.Checked;

    // License
    SCREEN_LICENSE:
      begin
        chkDisclamerRead.Checked := False;
        btnNext.Enabled := rbnLicenseAccept.Checked;
      end;

    // Check disc
    SCREEN_CHECKDISC:
      begin                           
        btnNext.Caption := GetStringUI('Buttons', 'Start');
        btnNext.Tag := BUTTON_ACTION_DO_IDENTIFICATION;
      end;

    // Authentification failed
    SCREEN_CHECKDISC_FAILED:
      begin
        btnPrev.Caption := GetStringUI('Buttons', 'Retry');
        btnNext.Caption := GetStringUI('Buttons', 'Finish');
        btnNext.Tag := BUTTON_ACTION_FINISH;
      end;

    // Parameters
    SCREEN_EXTRACT_PARAMETERS:
      begin
        btnPrev.Tag := BUTTON_ACTION_SHOW_CHECKDISC;
        btnNext.Tag := BUTTON_ACTION_CHECK_EXTRACT_PARAMS;
        edtOutputDir.SetFocus;
      end;

    // Ready to extract
    SCREEN_READY_TO_EXTRACT:
      begin
        btnNext.Caption := GetStringUI('Buttons', 'Start');
        btnNext.Tag := BUTTON_ACTION_DO_UNLOCK_PACKAGE;
        SetStatusProgress(0);
      end;

    // Working...
    SCREEN_WORKING:
      begin
        btnPrev.Enabled := False;
        btnNext.Enabled := False;
      end;

    // Finish OK
    SCREEN_FINISH:
      begin
        btnPrev.Enabled := False;
        btnNext.Caption := GetStringUI('Buttons', 'Finish');
        btnNext.Tag := BUTTON_ACTION_FINISH;
      end;

    // Finish failed...
    SCREEN_FINISH_FAILED:
      begin
        btnPrev.Enabled := False;
        btnNext.Caption := GetStringUI('Buttons', 'Finish');
        btnNext.Tag := BUTTON_ACTION_FINISH;
      end;
  end;

  // Load Wizard strings UI...
  UISectionName := pcWizard.FindNextPage(pcWizard.ActivePage, True, False).Name;
  UISectionName := Copy(UISectionName, 3, Length(UISectionName) - 2);
  LoadWizardUI(UISectionName);
  if UISectionName = 'AuthFail' then
    LoadWizardUI('Params'); // load too...
  if UISectionName = 'Done' then
    LoadWizardUi('DoneFail');  
end;

function TfrmMain.OnWizardBeforePageChange;
begin
  Result := True;
end;

procedure TfrmMain.PackageUnlockFinish(Sender: TObject);
var
  Thread: TPackageExtractorThread;

begin
{$IFDEF DEBUG}
  Write('Finish: ');
{$ENDIF}

  Thread := Sender as TPackageExtractorThread;
  if Thread.Aborted then
  begin
    // Aborted
    AddDebug(GetStringUI('MsgText', 'OperationCanceled'));
    PageIndex := SCREEN_FINISH_FAILED;
{$IFDEF DEBUG}
  WriteLn('Aborted');
{$ENDIF}
  end else if (not Thread.Success) then
  begin
    // Error
    AddDebug(Thread.ErrorMessage);
    PageIndex := SCREEN_FINISH_FAILED;
{$IFDEF DEBUG}
  WriteLn('Errpr');
{$ENDIF}
  end else begin
    // Success
    SetStatusProgress(MaxDouble);
    PageIndex := SCREEN_FINISH;
{$IFDEF DEBUG}
  WriteLn('Success');
{$ENDIF}
  end;
end;

procedure TfrmMain.PackageUnlockProgress(Sender: TObject; Current,
  Total: Int64);
begin
{$IFDEF DEBUG}
  Write('  ', Current, '/', Total, #13);
{$ENDIF}
  SetStatusProgress(Current);
end;

procedure TfrmMain.PackageUnlockStart(Sender: TObject; Total: Int64);
begin
{$IFDEF DEBUG}
  WriteLn('Total: ', Total);
{$ENDIF}
  SetStatusProgressMax(Total);
  SetStatusProgress(0);
end;

procedure TfrmMain.pcWizardChange;
begin
  OnWizardAfterPageChange;
end;

procedure TfrmMain.pcWizardChanging;
begin
  AllowChange := ((PageIndex > 0) or (PageIndex < PageIndexMax))
    and OnWizardBeforePageChange;
end;

procedure TfrmMain.pcWizardDrawTab(Control: TCustomTabControl;
  TabIndex: Integer; const Rect: TRect; Active: Boolean);
begin
  TabSheetCustomDraw(Control, TabIndex, Rect);
end;

procedure TfrmMain.Previous;
begin
  case btnPrev.Tag of
    // Default : Previous page
    BUTTON_ACTION_DEFAULT:
      pcWizard.SelectNextPage(False, False);

    // Return to the disc auth page...
    BUTTON_ACTION_SHOW_CHECKDISC:
      PageIndex := SCREEN_CHECKDISC;
  end;
end;

procedure TfrmMain.rbnLicenseAcceptClick(Sender: TObject);
begin
  if PageIndex = SCREEN_LICENSE then
    btnNext.Enabled := rbnLicenseAccept.Checked;
end;

procedure TfrmMain.reEulaURLClick(Sender: TObject; const URLText: string;
  Button: TMouseButton);
begin
  OpenLink(URLText);
end;

procedure TfrmMain.SetPageIndex(const Value: Integer);
begin
  pcWizard.ActivePageIndex := Value;
  pcWizardChange(Self);
end;

procedure TfrmMain.SetStatusProgress(const Value: Double);
var
  Step: Double;

begin
  if Value > fStatusProgressMax then
    fStatusProgress := fStatusProgressMax
  else
    fStatusProgress := Value;

  Step := 0;
  if fStatusProgressMax <> 0 then
    Step := SimpleRoundTo((fStatusProgress / fStatusProgressMax) * 100, -2);
  pbTotal.Position := Ceil(Step);
  lblUnpackProgress.Caption := FormatFloat('0.00', Step) + '%';
end;

procedure TfrmMain.SetStatusProgressMax(const MaxValue: Double);
begin
  fStatusProgressMax := MaxValue;
  pbTotal.Max := 100;
  SetStatusProgress(0);
end;

procedure TfrmMain.SetUnpackedSize(const Value: Int64);
var
  SizeUnit: TSizeUnit;
  SizeStr: string;

begin
  fUnpackedSize := Value;
  try
    lklParamsUnpackedSize.Caption := GetStringUI('Params', 'lklparamsUnpackedSize');
    SizeStr := FormatByteSize(UnpackedSize, SizeUnit) + ' ' + SizeUnitToString(SizeUnit);
    lklParamsUnpackedSize.UpdateDynamicTag(0, SizeStr);
  except
    MsgBox('Please include the <dynamic> tag on the lklParamsUnpackedSize entry !', 'Error', MB_ICONERROR);
  end;
end;

procedure TfrmMain.tmrLoadResTimer(Sender: TObject);
begin
  tmrLoadRes.Enabled := False;
  InitSecondaryExtraResources;
end;

procedure TfrmMain.WorkingThreadTerminateHandler;
begin
  // The thread is closed, we can close the application now.
  if fCanceledByClosingWindow then  
    Close
  else begin
    btnCancel.Enabled := True;
    SetCloseWindowButtonState(Self, True);
  end;
end;

procedure TfrmMain.lklHomeMessageLinkClick(Sender: TObject;
  LinkNumber: Integer; LinkText, LinkParam: string);
var
  URL: string;
  LinkSender: TJvLinkLabel;

begin
  LinkSender := (Sender as TJvLinkLabel);
  URL := GetLink(LinkSender.Name, LinkNumber);
{$IFDEF DEBUG}
  WriteLn('LinkClick: ', LinkNumber, ', ', LinkText, sLineBreak,
    '  URL = ', URL);
{$ENDIF}
  if URL <> '' then
    OpenLink(URL);
  LinkSender.Invalidate;
end;

//------------------------------------------------------------------------------

end.
