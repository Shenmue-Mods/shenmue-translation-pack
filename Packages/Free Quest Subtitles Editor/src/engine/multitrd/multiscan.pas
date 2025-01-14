(*

  This unit was made to control the subtitles retriver process.
  It uses the textdata unit to store each subtitle info.
*)

unit multiscan;

interface

uses
  SysUtils, Classes, Forms, Math, ComCtrls, TextData, CharsLst, ScnfUtil;

type
  TMultiTranslationSubtitlesRetriever = class(TThread)
  private
    fRefreshRequested: Boolean;
    fEntry: TTextDataItem;
    fFillGTView: Boolean;
//    fBufNode: TTreeNode;
    fStrBuf: string;
    fFilesList: TStringList;
    fIntBuf: Integer;
    fStrCurrentOperation: string;
    fStrSubtitle: string;
    fSubtitleInfoList: TSubtitlesInfoList;
    fBaseDir: string;
    fFileListParam: string;
    fDecodeSubtitles: Boolean;
    fCharsList: TSubsCharsList;
    fMultiTranslationTextData: TMultiTranslationTextData;
//    fEnabled: Boolean;

    procedure InitializeProgressWindow(const FilesCount: Integer);
    procedure AddDebug(const Text: string);
    procedure ClearTextDataList;
    procedure UpdatePercentage;
    procedure UpdateProgressOperation(const S: string);
    procedure UpdateViewSubsList(const Subtitle: string;
      DataInfo: TSubtitlesInfoList);
//    procedure ChangeUpdateMemoViewState(const Enabled: Boolean);

    // --- don't call directly ---
    procedure SyncAddDebug;
    procedure SyncAddSubtitleEntry;
    procedure SyncInitializeProgressWindow;
    procedure SyncUpdateProgressOperation;
    procedure SyncUpdateViewSubsList;
    procedure AddSubtitleEntry;
//    procedure SyncChangeUpdateMemoViewState;
    
  protected
    procedure Execute; override;

    property CharsList: TSubsCharsList read fCharsList write fCharsList;
    property Entry: TTextDataItem read fEntry write fEntry;
    property FillView: Boolean read fFillGTView;
    property WorkTextDataList: TMultiTranslationTextData read
      fMultiTranslationTextData write fMultiTranslationTextData;
  public
    constructor Create(const BaseDir: string; const FileList: string; DecodeSubtitles: Boolean; var ResultTextDataList: TMultiTranslationTextData; UseGlobalTranslationView, RefreshRequest: Boolean);
    property RefreshRequested: Boolean read fRefreshRequested;
  end;

// -----------------------------------------------------------------------------
implementation
// -----------------------------------------------------------------------------

uses
  Main, Progress, ScnfEdit, Common, IconsUI, UITools;

// -----------------------------------------------------------------------------
// TMultiTranslationSubtitlesRetriever
// -----------------------------------------------------------------------------

procedure TMultiTranslationSubtitlesRetriever.AddDebug(const Text: string);
begin
  fStrBuf := Text;
  Synchronize(SyncAddDebug);
end;

procedure TMultiTranslationSubtitlesRetriever.AddSubtitleEntry;
begin
  Synchronize(SyncAddSubtitleEntry);
end;

procedure TMultiTranslationSubtitlesRetriever.ClearTextDataList;
begin
  Synchronize(WorkTextDataList.Clear);
end;

constructor TMultiTranslationSubtitlesRetriever.Create(const BaseDir: string;
  const FileList: string; DecodeSubtitles: Boolean;
  var ResultTextDataList: TMultiTranslationTextData; UseGlobalTranslationView,
  RefreshRequest: Boolean);
begin
  FreeOnTerminate := True;
  fBaseDir := BaseDir;
  fFileListParam := FileList;
  fDecodeSubtitles := DecodeSubtitles;
  fFillGTView := UseGlobalTranslationView;
  fRefreshRequested := RefreshRequest;
  
  if not Assigned(ResultTextDataList) then
    raise Exception.Create('Error: ResultTextDataList not assigned!');

  WorkTextDataList := ResultTextDataList;
  
  inherited Create(True);
end;

// -----------------------------------------------------------------------------

procedure TMultiTranslationSubtitlesRetriever.Execute;
var
  i, j: Integer;
  BaseDir, FileName: TFileName;
  _tmp_scnf_edit: TSCNFEditor;
//  Code: string;
  Text: string;
  List: TSubtitlesInfoList;
(*  CharsList: TSubsCharsList;
  CharsListFound: Boolean;
  PrevGameVersion: TGameVersion;  *)

begin
  BaseDir := IncludeTrailingPathDelimiter(frmMain.SelectedDirectory);

  fFilesList := TStringList.Create;
  fFilesList.Text := Self.fFileListParam;

  ClearTextDataList;

  //----------------------------------------------------------------------------
  // BUILDING THE TEXT DATA LIST
  //----------------------------------------------------------------------------

  CharsList := TSubsCharsList.Create;
  _tmp_scnf_edit := TSCNFEditor.Create;
  try
    _tmp_scnf_edit.CharsList.Active := False;
    _tmp_scnf_edit.NPCInfos.LoadFromFile(GetNPCInfoFile);
    
    // scanning all found files
    InitializeProgressWindow(fFilesList.Count);

    // For each file found...
    for i := 0 to fFilesList.Count - 1 do begin
      if Terminated then Break;
      FileName := BaseDir + fFilesList[i];

      UpdateProgressOperation('Scanning "' + ExtractFileName(FileName) + '"...');

      // Retrieve all subs from this file
      _tmp_scnf_edit.LoadFromFile(FileName);

      // Adding each subtitle of the file to the "database"
      for j := 0 to _tmp_scnf_edit.Subtitles.Count - 1 do begin
        fStrBuf := _tmp_scnf_edit.Subtitles[j].Text; // SubtitleKey

        Entry := TTextDataItem.Create;
        Entry.Code := _tmp_scnf_edit.Subtitles[j].Code;
        Entry.FileName := FileName;
        Entry.GameVersion := _tmp_scnf_edit.GameVersion;
        Entry.Gender := _tmp_scnf_edit.Gender;
//        _tmp_scnf_edit.Subtitles[j].CharID;
        
        AddSubtitleEntry;
      end;

      UpdatePercentage;
    end;

//    Synchronize(MultiTranslationTextData.Subtitles.Sort);

    //----------------------------------------------------------------------------
    // FILLING THE GLOBAL-TRANSLATION VIEW
    //----------------------------------------------------------------------------

    if FillView then begin

      // Adding all infos to the TreeView
      InitializeProgressWindow(WorkTextDataList.Count);
      UpdateProgressOperation('Updating Global-Translation view with extracted datas...');
  //    PrevGameVersion := gvUndef;

      for i := 0 to WorkTextDataList.Count - 1 do begin
        if Terminated then Break;
        Text := WorkTextDataList.Subtitles[i].SubtitleKey;
        // List := MultiTranslationTextData.GetSubtitleInfo(Text);
        List := WorkTextDataList.FindBySubtitleKey(Text);

        // Loading the correct charslist
        (*if not IsTheSameCharsList(PrevGameVersion, _tmp_scnf_edit.GameVersion) then begin
          CharsListFound := CharsList.LoadFromFile(GetCorrectCharsList(_tmp_scnf_edit.GameVersion));
          if CharsListFound then
            CharsList.Active := fDecodeSubtitles
          else
            CharsList.Active := False;
        end;
        PrevGameVersion := _tmp_scnf_edit.GameVersion;*)

  //      UpdateViewSubsList(CharsList.DecodeSubtitle(Text), List);

        UpdateViewSubsList(Text, List);
        UpdatePercentage;
      end;

    end; // UseGlobalTranslationView

  finally
    fFilesList.Free;
    _tmp_scnf_edit.Free;
    CharsList.Free;
  end;
end;

// -----------------------------------------------------------------------------

procedure TMultiTranslationSubtitlesRetriever.InitializeProgressWindow(const FilesCount: Integer);
begin
  fIntBuf := FilesCount;
  Synchronize(SyncInitializeProgressWindow);
end;

// -----------------------------------------------------------------------------

procedure TMultiTranslationSubtitlesRetriever.UpdateProgressOperation(const S: string);
begin
  fStrCurrentOperation := S;
  Synchronize(SyncUpdateProgressOperation);
end;

// -----------------------------------------------------------------------------

procedure TMultiTranslationSubtitlesRetriever.UpdateViewSubsList(
  const Subtitle: string; DataInfo: TSubtitlesInfoList);
begin
  fStrSubtitle := Subtitle;
  fSubtitleInfoList := DataInfo;
  Synchronize(SyncUpdateViewSubsList);
end;

// -----------------------------------------------------------------------------

procedure TMultiTranslationSubtitlesRetriever.UpdatePercentage;
begin
  Synchronize(frmProgress.UpdateProgressBar);
end;

// -----------------------------------------------------------------------------
// DON'T CALL DIRECTLY THESES METHODS
// -----------------------------------------------------------------------------

(*procedure TMultiTranslationSubtitlesRetriever.SyncChangeUpdateMemoViewState;
begin
  if fEnabled then begin
    frmMain.tvMultiSubs.OnChange := frmMain.tvMultiSubsChange;
//    frmMain.mMTNewSub.OnChange := frmMain.mMTNewSubChange;
  end else begin
    frmMain.tvMultiSubs.OnChange := nil;
//    frmMain.mMTNewSub.OnChange := nil;
  end;
end;
*)

// -----------------------------------------------------------------------------

procedure TMultiTranslationSubtitlesRetriever.SyncAddDebug;
begin
  frmMain.AddDebug(fStrBuf);
end;

procedure TMultiTranslationSubtitlesRetriever.SyncAddSubtitleEntry;
begin
  WorkTextDataList.Add(fStrBuf, Entry);
end;

procedure TMultiTranslationSubtitlesRetriever.SyncInitializeProgressWindow;
begin
  frmProgress.pbar.Max := fIntBuf;
  frmProgress.pbar.Position := 0;
end;

// -----------------------------------------------------------------------------

procedure TMultiTranslationSubtitlesRetriever.SyncUpdateProgressOperation;
begin
  frmProgress.lInfos.Caption := fStrCurrentOperation;
end;

// -----------------------------------------------------------------------------

procedure TMultiTranslationSubtitlesRetriever.SyncUpdateViewSubsList;
var
  RootNode, TranslatedNode, EntriesNode, Node: TTreeNode;
  j: Integer;
  Code, FileName: string;
  GameVersion,
  PrevGameVersion: TGameVersion;
  CharsListProblematic, // true if in the same subtitle, 2 games types are present
  CharsListFound: Boolean;

  function NewNodeType(NodeViewType: TMultiTranslationNodeViewType;
    GameVersion: TGameVersion): PMultiTranslationNodeType;
  begin
    Result := New(PMultiTranslationNodeType);
    Result^.NodeViewType := NodeViewType;
    Result^.GameVersion := GameVersion;
  end;

  procedure SetGameVersion(Node: TTreeNode; GameVersion: TGameVersion);
  begin
    PMultiTranslationNodeType(Node.Data)^.GameVersion := GameVersion;
  end;

begin
  // Adding the original node
  RootNode := frmMain.tvMultiSubs.Items.Add(nil, fStrSubtitle);
  RootNode.Data := NewNodeType(nvtSubtitleKey, gvUndef);
  RootNode.ImageIndex := GT_ICON_NOT_TRANSLATED;
  RootNode.SelectedIndex := GT_ICON_NOT_TRANSLATED;
  RootNode.OverlayIndex := -1;

  try
    // Adding the NewSubtitle node
    TranslatedNode := frmMain.tvMultiSubs.Items.AddChild(RootNode, MT_NOT_TRANSLATED_YET);
    TranslatedNode.Data := NewNodeType(nvtSubTranslated, gvUndef);
    TranslatedNode.ImageIndex := GT_ICON_TRANSLATED_TEXT;
    TranslatedNode.SelectedIndex := GT_ICON_TRANSLATED_TEXT;
    TranslatedNode.OverlayIndex := -1;

    // Creating the Entries node if needed
    EntriesNode := frmMain.tvMultiSubs.Items.AddChild(RootNode, 'Subtitles');
    EntriesNode.Data := NewNodeType(nvtUndef, gvUndef);
    EntriesNode.ImageIndex := GT_ICON_SUBTITLES_FOLDER;
    EntriesNode.SelectedIndex := GT_ICON_SUBTITLES_FOLDER;
    EntriesNode.OverlayIndex := -1;

    // Put plural or not...
    Code := 'entry';
    if fSubtitleInfoList.Count <> 1 then Code := 'entries';
    EntriesNode.Text := EntriesNode.Text + ' (' +
      IntToStr(fSubtitleInfoList.Count) + ' ' + Code + ')';

    // Filling the "EntriesNode"
    PrevGameVersion := gvUndef;
    CharsListProblematic := False;   
    for j := 0 to fSubtitleInfoList.Count - 1 do begin
      FileName := ExtractFileName(fSubtitleInfoList.Items[j].FileName);
      Code := fSubtitleInfoList.Items[j].Code;
      GameVersion := fSubtitleInfoList.Items[j].GameVersion;

      // Checks if for the SAME subtitles TWO charsets are used (Problem!
      // How to determine the right charset??)
      if (PrevGameVersion <> gvUndef) and (not CharsListProblematic) then
        CharsListProblematic := not IsTheSameCharsList(PrevGameVersion, GameVersion);
      PrevGameVersion := GameVersion;

      // Adding the file node
      Node := FindNode(EntriesNode, FileName);
      if Node = nil then begin
        Node := frmMain.tvMultiSubs.Items.AddChild(EntriesNode, FileName);
        Node.Data := NewNodeType(nvtSourceFile, GameVersion);
        Node.ImageIndex := GT_ICON_PAKS_FILE;
        Node.SelectedIndex := GT_ICON_PAKS_FILE;
        Node.OverlayIndex := -1;
      end;

      // Adding the Sub code node
      Node := frmMain.tvMultiSubs.Items.AddChild(Node, Code);
      Node.Data := NewNodeType(nvtSubCode, gvUndef);
      Node.ImageIndex := GT_ICON_SUBTITLE_CODE;
      Node.SelectedIndex := GT_ICON_SUBTITLE_CODE;
      Node.OverlayIndex := -1;
    end;

    // Final: setting the GameVersion for the RootNode (SubKey) and TranslatedNode (TranslatedText)
    if CharsListProblematic then begin
      AddDebug('WARNING: Chars list problem for the subtitle "'
        + fStrSubtitle + '" ! Two different game versions was detected, '
        + 'so unable to multi-translate this item.');
      RootNode.ImageIndex := GT_ICON_ERRORNOUS_SUBTITLE;
      RootNode.SelectedIndex := GT_ICON_ERRORNOUS_SUBTITLE;
      RootNode.OverlayIndex := -1;
    end else begin
      SetGameVersion(RootNode, PrevGameVersion);
      SetGameVersion(TranslatedNode, PrevGameVersion);

      CharsListFound := CharsList.LoadFromFile(GetCorrectCharsList(PrevGameVersion));
      if CharsListFound then
        CharsList.Active := fDecodeSubtitles
      else
        CharsList.Active := False;
      RootNode.Text := CharsList.DecodeSubtitle(RootNode.Text);
    end;

    RootNode.Selected := True;
  except 
    // nothing
  end;
end;

// -----------------------------------------------------------------------------
  
end.
