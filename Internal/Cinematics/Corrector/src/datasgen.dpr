program datasgen;

{$APPTYPE CONSOLE}

// Don't forget to undef DEBUG_SCNFEDITOR in scnfedit.pas



{$R 'lzmabin.res' 'lzmabin.rc'}

uses
  Windows,
  SysUtils,
  XMLDom,
  XMLIntf,
  MSXMLDom,
  XMLDoc,
  ActiveX,
  systools in '..\..\..\..\Common\systools.pas',
  chrcodec in '..\..\..\..\Common\SubsUtil\chrcodec.pas',
  hashidx in '..\..\..\..\Common\hashidx.pas',
  MD5Api in '..\..\..\..\Common\MD5\MD5Api.pas',
  MD5Core in '..\..\..\..\Common\MD5\MD5Core.pas',
  filespec in '..\..\..\..\Common\filespec.pas',
  srfkeydb in '..\..\..\..\Packages\Cinematics Subtitles Editor\src\engine\srfkeydb.pas',
  workdir in '..\..\..\..\Common\workdir.pas',
  lzmadec in '..\..\..\..\Common\lzmadec.pas',
  srfedit in '..\..\..\..\Packages\Cinematics Subtitles Editor\src\engine\srfedit.pas';

const
  OUTPUT_FILE_EXT = '.dbi';
  MAX_DATABASE_FILES = 256;
  
var
  DBINumEntries, FilesCount, FileIndex: Integer;
  Filter, DiscNumber: string;
  SRFEditor: TSRFEditor;
  SR: TSearchRec;
  PrgName, PKSDirectory, TCDOutputFile, FoundFile, DBIOutputFile,
  DBIOutputDirectory: TFileName;
  TCD_XMLDoc, DBI_XMLDoc: IXMLDocument;
  InfoNode, Node,
  FileNamesRootNode,
  ContainerDiscsRootNode: IXMLNode;

  GameVersion: TGameVersion;
  Region: TGameRegion;
  PlatformVersion: TPlatformVersion;

//------------------------------------------------------------------------------

(*function GetGameVersionRootNode(GameVersion: TGameVersion): IXMLNode;
var
  sVersion: string;

begin
  sVersion := GameVersionToCodeStr(GameVersion);
  Result := XMLDoc.DocumentElement.ChildNodes.FindNode(sVersion);
  if not Assigned(Result) then
    Result := XMLDoc.DocumentElement.AddChild(sVersion);
end;*)

//------------------------------------------------------------------------------

procedure AddEntryToDatabase;
var
  Key: string;
  i: Integer;
  Node, FileNode,
  SubtitleNode: IXMLNode;

begin
  try
    Key := SRFEditor.HashKey;
    Node := FileNamesRootNode.ChildNodes.FindNode(Key);

    if not Assigned(Node) then begin      
      FileNode := FileNamesRootNode.AddChild(Key);

      // Disque number
  //    Node := FileNode.AddChild('DiscNumber');
  //    Node.NodeValue := DiscNumber;

      // Subtitles
      Node := FileNode.AddChild('Subtitles');
      Node.Attributes['Count'] := SRFEditor.Subtitles.Count;
      for i := 0 to SRFEditor.Subtitles.Count - 1 do
      begin
        SubtitleNode := TCD_XMLDoc.CreateNode('Subtitle');
//        SubtitleNode.Attributes['Code'] := SRFEditor.Subtitles[i].Code;
        SubtitleNode.NodeValue := SRFEditor.Subtitles[i].RawText;
        Node.ChildNodes.Add(SubtitleNode);
      end;
    end else begin
      // la node existe d�j�. 
      WriteLn('Key "', Key, '" already in database'); (*(entry count = ',
        Node.ChildNodes.FindNode('Subtitles').Attributes['Count'], ', new entry count = ',
        SCNFEditor.Subtitles.Count
      );*)
    end;

  except
    on E:Exception do
      WriteLn('AddEntryToDatabase: Exception - ', E.Message);
  end;
end;

//------------------------------------------------------------------------------

function UpdateDBI: Boolean;
var
  Key: string;
  
begin
  Result := False;
  Key := SRFEditor.HashKey;

  Node := ContainerDiscsRootNode.ChildNodes.FindNode(Key); // search for the key in DBI
  if not Assigned(Node) then begin // add the new key to the database
    Inc(DBINumEntries);  
    Node := ContainerDiscsRootNode.AddChild(Key);
    Node.Attributes['i'] := FileIndex;
    Node.Attributes['d'] := DiscNumber;
    Result := True;

    WriteLn('ACCEPT: "' + Key + '" (i = ', FileIndex, ', d = ', DiscNumber, ')');
  end else
    WriteLn('REJECT: "' + Key + '" (i = ', Node.Attributes['i'], ', d = ', Node.Attributes['d'], ')');
end;

//------------------------------------------------------------------------------

procedure InitParameters;

  procedure DetermineGameInformation(Param: string);
  begin
    // game version
    GameVersion := gvUndef;
    if IsInString('s1', param) then
      GameVersion := gvShenmue
    else if IsInString('whats', param) then
      GameVersion := gvUndef // incorrect..
    else if IsInString('s2', param) then
      GameVersion := gvShenmue2;

    // game region
    Region := prUndef;
    if IsInString('jap', param) then
      Region := prJapan
    else if IsInString('eur', param) then
      Region := prEurope
    else if IsInString('usa', param) then
      Region := prUSA;

    // platform version
    PlatformVersion := pvUndef;
    if IsInString('dc', param) then
      PlatformVersion := pvDreamcast
    else if IsInString('xb', param) then
      PlatformVersion := pvXbox;         
  end;

begin
  // <PKS_Folder> <Filter> <OutputFile> <DBI_Folder> <DiscNumber> <GameVersion>
  try
    PKSDirectory := IncludeTrailingPathDelimiter(ParamStr(1));
    Filter := ParamStr(2);
    TCDOutputFile := ParamStr(3);
    FileIndex := StrToInt(ExtractFileName(ChangeFileExt(TCDOutputFile, '')));
    DBIOutputDirectory := IncludeTrailingPathDelimiter(ParamStr(4));
    DiscNumber := ParamStr(5);
    DetermineGameInformation(paramstr(6));
  except
    WriteLn('Invalid parameters!');
    Exit;
  end;
end;

//------------------------------------------------------------------------------

procedure InitDBI;
var
  HeaderNode: IXMLNode;
  
begin
  DBINumEntries := 0;
  
  with DBI_XMLDoc do begin
    Options := [doNodeAutoCreate, doAttrNull];
    ParseOptions:= [];
    Active := True;
    Version := '1.0';
    Encoding := 'utf-8'; //'ISO-8859-1';
  end;

  DBIOutputFile := DBIOutputDirectory + 'index'  //LowerCase(SRFGameVersionToCodeString(GameVersion))
    + OUTPUT_FILE_EXT;

  // Loading the DBIOutputFile
  if not FileExists(DBIOutputFile) then begin
    // Creating the root
    DBI_XMLDoc.DocumentElement := DBI_XMLDoc.CreateNode('TextCorrectorDatabaseIndex');

//    Node := DBI_XMLDoc.DocumentElement.AddChild('GameVersion');
//    Node.NodeValue := SRFGameVersionToCodeString(GameVersion);

    HeaderNode := DBI_XMLDoc.DocumentElement.AddChild('HeaderInfo');
    Node := HeaderNode.AddChild('Version');
    Node.NodeValue := GameVersionToCodeString(GameVersion);
    Node := HeaderNode.AddChild('Region');
    Node.NodeValue := GameRegionToCodeString(Region);
    Node := HeaderNode.AddChild('System');
    Node.NodeValue := PlatformVersionToCodeString(PlatformVersion);        

    ContainerDiscsRootNode := DBI_XMLDoc.DocumentElement.AddChild('Entries');
    ContainerDiscsRootNode.Attributes['Count'] := 0;
  end else begin
    DBI_XMLDoc.LoadFromFile(DBIOutputFile);

    ContainerDiscsRootNode := DBI_XMLDoc.DocumentElement.ChildNodes.FindNode('Entries');
    if not Assigned(ContainerDiscsRootNode) then
      ContainerDiscsRootNode := DBI_XMLDoc.DocumentElement.AddChild('Entries');
  end;
end;

//------------------------------------------------------------------------------

procedure ShowHelp;
begin
  WriteLn('Shenmue Corrector Data Generator - INTERNAL TOOL', sLineBreak,
        sLineBreak,
        'Usage: ', sLineBreak,
        '       ', PrgName, ' <PKS_Folder> <Filter> <OutputFile> <DBI_Folder> <DiscNumber> <GameVersion>', sLineBreak,
        sLineBreak,
        'Where: ', sLineBreak,
        '       <PKS_Folder>  : The target directory which contains PKS files', sLineBreak,
        '       <Filter>      : The filter for searching files (ie "*.*")', sLineBreak,
        '       <OutputFile>  : The output TCD file, MUST BE A NUMBER', sLineBreak,
        '       <DBI_Folder>  : The target directory where to store the output DBI', sLineBreak,
        '       <DiscNumber>  : The disc number of the folder (ie "1")', sLineBreak,
        '       <GameVersion> : The game version of the folder (see below)', sLineBreak,
        sLineBreak,
        'Game Version values:', sLineBreak,
        '       whats         : What''s Shenmue JAP DC', sLineBreak,
        '       s1_dc_jap     : Shenmue 1 JAP DC', sLineBreak,
        '       s1_dc_eur     : Shenmue 1 PAL DC', sLineBreak,
        '       s2_dc_jap     : Shenmue 2 JAP DC', sLineBreak,
        '       s2_dc_eur     : Shenmue 2 PAL DC', sLineBreak,
        '       s2_xb_eur     : Shenmue 2X PAL Xbox', sLineBreak,
        sLineBreak,
        'Example:', sLineBreak,
        '       ', PrgName, ' .\db_root\disc1\ *.* 1.tcd .\db_root\ 1 s1_dc_eur'
  );
  ExitCode := 1;
end;

//------------------------------------------------------------------------------

procedure InitTCD;
begin
  try
  
    // initialization for the XML file
    with TCD_XMLDoc do begin
      Options := [doNodeAutoCreate, doAttrNull];
      ParseOptions:= [];
      NodeIndentStr:= '  ';
      Active := True;
      Version := '1.0';
      Encoding := 'utf-8'; //'ISO-8859-1';
    end;

    // Starting to open PKS files and generate TCD files
    FilesCount := 0;
    if not FileExists(TCDOutputFile) then begin
      // Creating the root
      TCD_XMLDoc.DocumentElement := TCD_XMLDoc.CreateNode('TextCorrectorDatabase');

      // adding the file info
      InfoNode := TCD_XMLDoc.DocumentElement.AddChild('HeaderInfo');
      Node := InfoNode.AddChild('Version');
      Node.NodeValue := GameVersionToCodeString(GameVersion);
      Node := InfoNode.AddChild('Region');
      Node.NodeValue := GameRegionToCodeString(Region);
      Node := InfoNode.AddChild('System');
      Node.NodeValue := PlatformVersionToCodeString(PlatformVersion);      
      Node := InfoNode.AddChild('DiscNumber');
      Node.NodeValue := DiscNumber;

      // creating the filenames entries root
      FileNamesRootNode := TCD_XMLDoc.DocumentElement.AddChild('FileNames');
      FileNamesRootNode.Attributes['Count'] := 0;      
    end else begin
      TCD_XMLDoc.LoadFromFile(TCDOutputFile);
      FileNamesRootNode := TCD_XMLDoc.DocumentElement.ChildNodes.FindNode('FileNames');
      if not Assigned(FileNamesRootNode) then
        FileNamesRootNode := TCD_XMLDoc.DocumentElement.AddChild('FileNames')
      else
        FilesCount := FileNamesRootNode.Attributes['Count'];
    end;

  except
    on E:Exception do WriteLn('EXCEPTION InitTCD: "' + E.Message + '".');
  end;
end;

//------------------------------------------------------------------------------

begin
  ReportMemoryLeaksOnShutDown := True;

  PrgName := ExtractFileName(ChangeFileExt(ParamStr(0), ''));
  if ParamCount < 5 then begin
    ShowHelp;
    Exit;
  end;

  InitParameters;

  CoInitialize(nil);    
  TCD_XMLDoc := TXMLDocument.Create(nil);
  DBI_XMLDoc := TXMLDocument.Create(nil);
  SRFEditor := TSRFEditor.Create;
  try
    try
      InitTCD;

      InitDBI;

      // Searching the selected directory
      if FindFirst(PKSDirectory + Filter, faAnyFile, SR) = 0 then
      begin
        repeat
          FoundFile := PKSDirectory + SR.Name;
          WriteLn('*** LOADING: ', FoundFile);

          SRFEditor.LoadFromFile(FoundFile);

          // this is a valid file
          if SRFEditor.Loaded then begin
            if UpdateDBI then begin // this entry wasn't in the DBI file so must add it
              AddEntryToDatabase;
              Inc(FilesCount);
            end;
          end;

        until FindNext(SR) <> 0;
        FindClose(SR);
      end;

      FileNamesRootNode.Attributes['Count'] := FilesCount;
//        Integer(FileNamesRootNode.Attributes['Count']) + FilesCount;
      ContainerDiscsRootNode.Attributes['Count'] :=
        Integer(ContainerDiscsRootNode.Attributes['Count']) + DBINumEntries;

      // Saving the file
      TCD_XMLDoc.SaveToFile(TCDOutputFile);
      DBI_XMLDoc.SaveToFile(DBIOutputFile);
    except
      on E:Exception do
        Writeln('MAIN EXCEPTION: ', FoundFile, ': ', E.Message);
    end;

  finally
    SRFEditor.Free;
    TCD_XMLDoc.Active := False;
    TCD_XMLDoc := nil;
    DBI_XMLDoc.Active := False;
    DBI_XMLDoc := nil;
  end;
end.
