unit mtedit;

interface

uses
  Windows, SysUtils, Classes;

const
  SHENMUE2_MT7_TEXTURE_SECTION  = 'TXT7'; // Shenmue II Textures Section
  SHENMUE1_MT6_TEXTURE_SECTION  = 'TEXD'; // Shenmue I Textures Section
  SHENMUE1_SECTION_IGNORE       = 'TEXN'; // Because it's written with the TEXD section
  TEXN_HEADER_SECTION_SIZE      = 16;
  TXT7_HEADER_FIXED_SIZE        = 12;     // TXT7 header size is variable but it 16 bytes length almost
  TXT7_TEXTURE_NAME_SIZE        = 8;
  GBIX_PVR_HEADER               = 'GBIX';
  DDS_PVR_HEADER                = 'DDS ';
  PVR_HEADER                    = 'PVRT';
  GBIX_PVR_HEADER_FIXED_SIZE    = 8; // 4 'GBIX' + 4 'GBIX size'
  PVRT_HEADER_SIZE              = 16;

type
  // The main class to use !
  TModelTexturedEditor = class;

  // Used to detect the game/file version
  TGameVersion = (gvUndef, gvShenmue, gvShenmue2, gvShenmue2X);
  
  // Used to parse each section in file
  TRawSectionHeader = record
    Name: array[0..3] of Char;  // Section Name Signature (MDP7, TXT7...)
    Size: Integer;              // Section Size
  end;

  // Contains each texture recorded in the TXT section
  TTexturesList = class;

  // Contains each section contained in the file
  TSectionsList = class;

  // Entry of the TSectionsList
  TSectionsListEntry = class;

  // Exports format for the textures
  TExportFormat = (efAll, efPVR, efDDS);
  
  // Texture list entry
  // Textures are PVR or DDS inside a GBIX container.
  // The GBIX format is: [GBIX_HEADER] (12 bytes) ... [TEX_DATA] (variable, in DDS/PVR format)
  TTexturesListEntry = class(TObject)
  private
    fTextureName: array[0..TXT7_TEXTURE_NAME_SIZE - 1] of Byte;
    fImportFileName: TFileName;
    fMTEditorOwner: TModelTexturedEditor;
    fOwner: TTexturesList;
    fIndex: Integer;
    fIsFileSection: Boolean;
    fSectionIndex: Integer;
    fSize: Integer;
    fOffset: Integer;
    fUpdated: Boolean;
    fRelativeOffset: Integer;
    fDataOffset: Integer;
    fPVRTextureOffset: Integer;
    fDataSize: Integer;
    fTextureSize: Integer;
    function GetTexturesSection: TSectionsListEntry;
  protected
    function GetLoadedFileName: TFileName;
    property MTEditorOwner: TModelTexturedEditor read fMTEditorOwner;
  public
    constructor Create(AOwner: TTexturesList);

    procedure CancelImport;
    function ImportFromFile(const FileName: TFileName): Boolean;
    procedure ExportToFile(const FileName: TFileName; OutputFormat: TExportFormat);
    function ExportToFolder(const Folder: TFileName): TFileName; overload;
    function ExportToFolder(const Folder: TFileName; OutputFormat: TExportFormat): TFileName; overload;
    function GetOutputTextureFileName(OutputFormat: TExportFormat): TFileName;
    function IsFileSection: Boolean; // if this texture is a registered section (TEXN). Shenmue 1 only.

    property DataOffset: Integer read fDataOffset;                // give the data offset in relative format (PVRT data or DDS data)
    property DataSize: Integer read fDataSize;                    // size of the texture data without headers [GBIX+PVRT]
    property Index: Integer read fIndex;                          // give this item index in the TexturesList
    property ImportFileName: TFileName read fImportFileName;
    property Offset: Integer read fOffset;                        // GBIX starting offset in absolute format
    property RelativeOffset: Integer read fRelativeOffset;        // GBIX starting offset in relative format for writting within TXT7 section (Shenmue 2 only)
    property Section: TSectionsListEntry read GetTexturesSection; // for TEXD (Shenmue 1) only.
    property Size: Integer read fSize;                            // GBIX total size
    property TextureOffset: Integer read fPVRTextureOffset;       // PVRT starting offset in absolute format [PVRT offset]
    property TextureSize: Integer read fTextureSize;              // PVRT size (without GBIX header) [PVRT only]
    property Owner: TTexturesList read fOwner;
    property Updated: Boolean read fUpdated;
  end;

  // Texture list
  // This is a Section item but with Textures specifics properties
  // TEXD: Shenmue 1
  // TXT7: Shenmue 2
  TTexturesList = class(TObject)
  private
    fXboxTXT7HeaderPaddingSize: Integer; // padding size for the TXT7 header (padding before fXboxUnknowValueInEndingHeader value)
    fXboxUnknowValueInEndingHeader: Integer; // unknow value after the TXT7 header
    fXboxTexturesSectionSize_ValueToAdd: Integer; // For Xbox version, the size of the TXT7 version is different as the REAL section size... WHY???!!
    fTexturesSectionIndex: Integer; // Index of the TXT section in the Section array (init by ParseTexturesSection)
    fOwner: TModelTexturedEditor;
    fTexturesList: TList;
    function GetItem(Index: Integer): TTexturesListEntry;
    function GetCount: Integer;
    function GetTexturesSectionEntry: TSectionsListEntry;
  protected
    function Add(const Index, GBIX_RelativeOffset, GBIX_Offset, PVRT_Offset,
      PVRT_DataOffset, GBIX_Size, PVRT_Size, PVRT_DataSize: Integer;
      IsEntryFileSection: Boolean; SectionIndex: Integer): Integer; overload;
    function Add(const Index, GBIX_RelativeOffset, GBIX_Offset, PVRT_Offset,
      PVRT_DataOffset, GBIX_Size, PVRT_Size, PVRT_DataSize: Integer): Integer; overload;
    procedure Clear;
    function ComputePaddingSize(DataSize: Integer): Integer;
    function GBIX_GetSectionSize(var FileStream: TFileStream): Integer;
    function ParseTextureData(var F: file; const GBIX_Offset, GBIX_Size: Integer;
      var PVRT_Offset, PVRT_DataOffset, PVRT_Size, PVRT_DataSize,
          Xbox_PaddingTextureSize: Integer): Boolean; overload;
    function ParseTextureData(var F: file; const GBIX_Offset, GBIX_Size: Integer;
      var PVRT_Offset, PVRT_DataOffset, PVRT_Size, PVRT_DataSize: Integer): Boolean; overload;
    procedure ParseTexturesSection_Shenmue2_MT7(var F: file);
    procedure ParseTexturesSection_Shenmue_MT5_MT6(var F: file);
    procedure WriteTexturesSection_Shenmue2_MT7(var InStream, OutStream: TFileStream);
    procedure WriteTexturesSection_Shenmue_MT5_MT6(var InStream, OutStream: TFileStream);
  public
    constructor Create(AOwner: TModelTexturedEditor);
    destructor Destroy; override;
    property Count: Integer read GetCount;
    property Items[Index: Integer]: TTexturesListEntry read GetItem; default;
    property Owner: TModelTexturedEditor read fOwner;
    property GraphicSection: TSectionsListEntry read GetTexturesSectionEntry; // TXT7 (Shenmue 2) or TEXD (Shenmue 1)
  end;

  // Section list entry
  TSectionsListEntry = class(TObject)
  private
    fOwner: TSectionsList;
    fName: string;
    fSize: Integer;
    fOffset: Integer;
    fIsTextures: Boolean;
    fIgnore: Boolean;
    function GetModelTexturedEditor: TModelTexturedEditor;
  protected
    property MTEditor: TModelTexturedEditor read GetModelTexturedEditor;
  public
    constructor Create(Owner: TSectionsList);
    procedure ExportToFile(const Directory: TFileName);
    procedure SaveToFile(const FileName: TFileName);
    property Ignored: Boolean read fIgnore;
    property IsTextures: Boolean read fIsTextures;
    property Name: string read fName;
    property Offset: Integer read fOffset;
    property Owner: TSectionsList read fOwner;
    property Size: Integer read fSize;
  end;

  // Sections list
  TSectionsList = class(TObject)
  private
    fOwner: TModelTexturedEditor;
    fSectionsList: TList;
    function GetItem(Index: Integer): TSectionsListEntry;
    function GetCount: Integer;
  protected
    function Add(const Name: string; const Offset, Size: Integer): Integer;
    procedure Clear;
    function GetTexturesSectionSize(var F: file;
      TexturesSectionOffset: Integer; var GameVersion: TGameVersion): Integer;
    function IsTexturesSection(var F: file; SectionName: string): Boolean;
    function ParseFile(var F: file): TGameVersion;
  public
    constructor Create(AOwner: TModelTexturedEditor);
    destructor Destroy; override;
    property Count: Integer read GetCount;
    property Items[Index: Integer]: TSectionsListEntry read GetItem; default;
    property Owner: TModelTexturedEditor read fOwner;
 end;

  // Main object
  TModelTexturedEditor = class(TObject)
  private
    fGameVersion: TGameVersion;
    fLoadedFileName: TFileName;
    fSections: TSectionsList;
    fTextures: TTexturesList;
    fFileLoaded: Boolean;
    fMakeBackup: Boolean;
  protected
    function GetTempFileName: TFileName;
  public
    constructor Create;
    destructor Destroy; override;
    function Close: Boolean;
    function LoadFromFile(const FileName: TFileName): Boolean;
    function Reload: Boolean;
    function Save: Boolean;
    function SaveToFile(const FileName: TFileName): Boolean;
    property FileLoaded: Boolean read fFileLoaded;
    property GameVersion: TGameVersion read fGameVersion;
    property MakeBackup: Boolean read fMakeBackup write fMakeBackup;
    property SourceFileName: TFileName read fLoadedFileName;
    property Sections: TSectionsList read fSections;
    property Textures: TTexturesList read fTextures;
  end;

 //------------------------------------------------------------------------------
implementation
//------------------------------------------------------------------------------

uses
  SysTools;
  
const
  GAME_INTEGER_SIZE = 4;
  
{ TTexturesList }

function TTexturesList.Add(const Index, GBIX_RelativeOffset, GBIX_Offset, PVRT_Offset,
  PVRT_DataOffset, GBIX_Size, PVRT_Size, PVRT_DataSize: Integer;
  IsEntryFileSection: Boolean; SectionIndex: Integer): Integer;
var
  Item: TTexturesListEntry;

begin
  Item := TTexturesListEntry.Create(Self);
  Item.fIndex := Index;                             // Texture index

  // Shenmue 1 only
  Item.fIsFileSection := IsEntryFileSection;        // Is this texture an section entry 'TEXN' (Shenmue 1 only)
  Item.fSectionIndex := SectionIndex;               // The section entry index (Shenmue 1 only)

  // GBIX
  Item.fRelativeOffset := GBIX_RelativeOffset;      // GBIX relative offset (TXT7 only)
  Item.fOffset := GBIX_Offset;                      // GBIX absolute offset
  Item.fSize := GBIX_Size;                          // GBIX total size

  // PVRT without GBIX header
  Item.fPVRTextureOffset := PVRT_Offset;            // PVRT absolute offset
  Item.fTextureSize := PVRT_Size;                   // PVRT size

  // Texture data only
  Item.fDataOffset := PVRT_DataOffset;              // PVRT data absolute offset
  Item.fDataSize := PVRT_DataSize;                  // PVRT data size

  // Adding to array
  Result := fTexturesList.Add(Item);
end;

//------------------------------------------------------------------------------

function TTexturesList.Add(const Index, GBIX_RelativeOffset, GBIX_Offset, PVRT_Offset,
  PVRT_DataOffset, GBIX_Size, PVRT_Size, PVRT_DataSize: Integer): Integer;
begin
  // IsEntryFileSection = False because we are adding a inner section...
  Result := Add(Index, GBIX_RelativeOffset, GBIX_Offset, PVRT_Offset, PVRT_DataOffset,
    GBIX_Size, PVRT_Size, PVRT_DataSize, False, -1);
end;

//------------------------------------------------------------------------------

procedure TTexturesList.Clear;
var
  i: Integer;

begin
  for i := 0 to fTexturesList.Count - 1 do
    TTexturesListEntry(fTexturesList[i]).Free;
  fTexturesList.Clear;
end;

function TTexturesList.ComputePaddingSize(DataSize: Integer): Integer;
var
  current_num, total_null_bytes: Integer;

begin
  //Finding the correct number of null bytes after file data
  current_num := 0;
  total_null_bytes := 0;
  while current_num <> dataSize do
  begin
    if total_null_bytes = 0 then begin
      total_null_bytes := 31;
    end
    else begin
      Dec(total_null_bytes);
    end;
    Inc(current_num);
  end;

  Result := total_null_bytes;
  if Result = 0 then Result := 32;
end;

//------------------------------------------------------------------------------

constructor TTexturesList.Create;
begin
  fOwner := AOwner;
  fTexturesList := TList.Create;
  fTexturesSectionIndex  := -1;
end;

//------------------------------------------------------------------------------

destructor TTexturesList.Destroy;
begin
  Clear;
  fTexturesList.Free;
  inherited;
end;

//------------------------------------------------------------------------------

function TTexturesList.GBIX_GetSectionSize(var FileStream: TFileStream): Integer;
var
  Saved_Offset,
  HeaderReadSize: Integer;
  
begin
  Saved_Offset := FileStream.Position;
  FileStream.Seek(Saved_Offset + 4, soFromBeginning); // 4 for 'GBIX' signature
  FileStream.Read(HeaderReadSize, GAME_INTEGER_SIZE); // read GBIX size (after signature)
  FileStream.Seek(Saved_Offset, soFromBeginning); // we know now the GBIX section size
  Result := GBIX_PVR_HEADER_FIXED_SIZE + HeaderReadSize;
end;

//------------------------------------------------------------------------------

function TTexturesList.GetCount: Integer;
begin
  Result := fTexturesList.Count;
end;

//------------------------------------------------------------------------------

function TTexturesList.GetItem(Index: Integer): TTexturesListEntry;
begin
  Result := TTexturesListEntry(fTexturesList[Index]);
end;

//------------------------------------------------------------------------------

function TTexturesList.GetTexturesSectionEntry: TSectionsListEntry;
begin
  Result := Owner.Sections[fTexturesSectionIndex];
end;
 
//------------------------------------------------------------------------------

function TTexturesList.ParseTextureData(var F: file; const GBIX_Offset,
  GBIX_Size: Integer; var PVRT_Offset, PVRT_DataOffset, PVRT_Size,
  PVRT_DataSize, Xbox_PaddingTextureSize: Integer): Boolean;
var
  RawHeader: TRawSectionHeader;
  
  function GBIX_GetSectionSize(var F: file): Integer;
  begin
    BlockRead(F, RawHeader, SizeOf(TRawSectionHeader));
    Result := GBIX_PVR_HEADER_FIXED_SIZE + RawHeader.Size;
  end;

begin
  Seek(F, GBIX_Offset); // don't need to save the position
  PVRT_Offset := GBIX_Offset + GBIX_GetSectionSize(F); // PVRT offset
  PVRT_Size := GBIX_Size - (PVRT_Offset - GBIX_Offset);

  Seek(F, PVRT_Offset);
  BlockRead(F, RawHeader, SizeOf(TRawSectionHeader));

  // Calculate padding for the Xbox version
  Xbox_PaddingTextureSize := 0;
  if Owner.GameVersion = gvShenmue2X then
    Xbox_PaddingTextureSize := ComputePaddingSize(RawHeader.Size);
      
  PVRT_DataOffset := FilePos(F) + 8; // Data offset (skipping PVRT header)
  PVRT_DataSize := PVRT_Size - (PVRT_DataOffset - PVRT_Offset);

  Result := (RawHeader.Name = PVR_HEADER);

{$IFDEF DEBUG}
  if not Result then  
    WriteLn('ParseTextureData: IMPOSSIBLE!!! PVRT header NOT found ?!');
{$ENDIF}
end;

function TTexturesList.ParseTextureData(var F: file; const GBIX_Offset,
  GBIX_Size: Integer; var PVRT_Offset, PVRT_DataOffset, PVRT_Size,
  PVRT_DataSize: Integer): Boolean;
var
  NotUsedCrap: Integer;
  
begin
  Result := ParseTextureData(F, GBIX_Offset, GBIX_Size, PVRT_Offset, PVRT_DataOffset,
    PVRT_Size, PVRT_DataSize, NotUsedCrap);  
end;

procedure TTexturesList.ParseTexturesSection_Shenmue2_MT7(var F: file);
var
  i, TexturesSectionOffset, TexturesCount,
  GBIX_CalcSize, GBIX_TextureInnerOffset, GBIX_HeaderOffset,
  PVRT_HeaderOffset, PVRT_DataOffset,
  PVRT_Size, PVRT_DataSize,
  TexturesNameTableStartOffset, SavedOffset,
  TXT7_SectionHeaderSize,
  Xbox_PaddingTextureSize,
  LastTextureIndex: Integer;
  TexturesSectionItem: TSectionsListEntry;
  CurrentTexture, TmpTextItem: TTexturesListEntry;

begin
  if fTexturesSectionIndex = -1 then Exit;

{$IFDEF DEBUG}
  WriteLn('*** MT7 PARSING TEXTURES SECTION: ', sLineBreak);
{$ENDIF}

  TexturesSectionItem := GraphicSection;

  // Positionning on the Section Count offset inside the Textures section (TXT7)
  TexturesSectionOffset := TexturesSectionItem.Offset + SizeOf(TRawSectionHeader);  // 8 for section name [4] + section size [4]
  Seek(F, TexturesSectionOffset);
  BlockRead(F, TexturesCount, GAME_INTEGER_SIZE);

  // Positionning at the end of the textures table inside the Textures section
  TexturesNameTableStartOffset := (TexturesSectionOffset + GAME_INTEGER_SIZE)
    + (TexturesCount * GAME_INTEGER_SIZE);
  Seek(F, TexturesNameTableStartOffset);
  GBIX_CalcSize := TexturesSectionItem.Size;
  TXT7_SectionHeaderSize := (TexturesNameTableStartOffset
    + (TexturesCount * TXT7_TEXTURE_NAME_SIZE)) - TexturesSectionItem.Offset;

  // Reading all textures offset info from the back <- to the start
  LastTextureIndex := TexturesCount - 1;
  for i := LastTextureIndex downto 0 do begin
    // reading current texture entry
    Seek(F, FilePos(F) - GAME_INTEGER_SIZE);
    BlockRead(F, GBIX_TextureInnerOffset, GAME_INTEGER_SIZE);
    Seek(F, FilePos(F) - GAME_INTEGER_SIZE); // Because we are reading entries from the BACK!!! (one loop optimization)

    // Computing the texture GBIX size
    GBIX_CalcSize := GBIX_CalcSize - GBIX_TextureInnerOffset;

    // Computing the PVRT header offset and the PVRT data offset
    SavedOffset := FilePos(F);
    GBIX_HeaderOffset := TexturesSectionItem.Offset + GBIX_TextureInnerOffset; // GBIX offset
    ParseTextureData(F, GBIX_HeaderOffset, GBIX_CalcSize, PVRT_HeaderOffset,
      PVRT_DataOffset, PVRT_Size, PVRT_DataSize, Xbox_PaddingTextureSize);      
    Seek(F, SavedOffset);

    // Xbox version
    // Padding is not for the last texture (read in the first position)
    if (Owner.GameVersion = gvShenmue2X) and (i <> LastTextureIndex) then begin
      Inc(Xbox_PaddingTextureSize, 4); // "4" is for the "unknow value" after padding
      Dec(GBIX_CalcSize, Xbox_PaddingTextureSize);
      Dec(PVRT_Size, Xbox_PaddingTextureSize);
      Dec(PVRT_DataSize, Xbox_PaddingTextureSize);
    end;
    
    // Adding the new texture entry
    Add(i, GBIX_TextureInnerOffset, GBIX_HeaderOffset, PVRT_HeaderOffset,
      PVRT_DataOffset, GBIX_CalcSize, PVRT_Size, PVRT_DataSize);

    // The old texture offset becomes the new CalcSize to compute the next texture size
    GBIX_CalcSize := GBIX_TextureInnerOffset;
  end;

  // Sorting TexturesList, reading the texture name and calculating total textures size
  for i := 0 to Count - 1 do begin
    CurrentTexture := Items[i];

    { Sorting to descendant [i:0->CurrentTexture.Index:3] ... [i:4->0]
      -> ascendante [i:0->CurrentTexture.Index:0] ... [i:4->4] texture order }
    TmpTextItem := fTexturesList.Items[CurrentTexture.Index];
    fTexturesList.Items[CurrentTexture.Index] := fTexturesList.Items[i];
    fTexturesList.Items[TmpTextItem.Index] := TmpTextItem;

    // Reading textures name
    Seek(F, TexturesNameTableStartOffset + (i * TXT7_TEXTURE_NAME_SIZE));
    BlockRead(F, Items[i].fTextureName, TXT7_TEXTURE_NAME_SIZE);
  end;

  // Special XBox...
  fXboxTXT7HeaderPaddingSize := -1;
  if Owner.GameVersion = gvShenmue2X then begin
    // Skipping padding zone
    fXboxTXT7HeaderPaddingSize := ComputePaddingSize(TXT7_SectionHeaderSize);
    Seek(F, TexturesSectionItem.Offset + TXT7_SectionHeaderSize + fXboxTXT7HeaderPaddingSize);

    // Value after TXT7 section padding...
    BlockRead(F, fXboxUnknowValueInEndingHeader, GAME_INTEGER_SIZE);

    // This value was filled in ParseTexturesSection_Shenmue2_MT7
    // I keep only the 'surplus' value
    // Will be summed in the SaveToFile method.
    Dec(fXboxTexturesSectionSize_ValueToAdd, TexturesSectionItem.Size);
  end else
    fXboxTexturesSectionSize_ValueToAdd := 0; // if not Shenmue2X, this is not necessary

{$IFDEF DEBUG}
  if Owner.GameVersion = gvShenmue2X then begin
    WriteLn(
      'TXT7 Padding Size: ', fXboxTXT7HeaderPaddingSize, sLineBreak,
      'TXT7 Header Size: ', TXT7_SectionHeaderSize, sLineBreak,
      'TXT7 Xbox Unknow Value: ', fXboxUnknowValueInEndingHeader, sLineBreak,
      'TXT7 Textures Size to Add in Header: ', fXboxTexturesSectionSize_ValueToAdd, sLineBreak
    );
  end;

  WriteLn('Textures List:');
{$ENDIF}
end;

procedure TTexturesList.ParseTexturesSection_Shenmue_MT5_MT6(var F: file);
const
  TEXD_SIGN_SIZE = 8;

var
  i, TexturesCount, PVRT_HeaderOffset,
  GBIX_Size, SectionIndex, PVRT_DataOffset,
  PVRT_Size, PVRT_DataSize,
  GBIX_HeaderOffset, SavedOffset: Integer;
  SectionItem: TSectionsListEntry;

begin
{$IFDEF DEBUG}
    WriteLn('*** MT5/MT6 PARSING TEXTURES SECTION: ');
{$ENDIF}

  // Get TEXD infos
  // the Sections.Count > 1 is for controlling there is at least one TEXN section... maybe.
  if (fTexturesSectionIndex <> -1) and (Owner.Sections.Count > 1) then begin
    // Read the textures TEXN count in the TEXD section
    Seek(F, Owner.Sections[fTexturesSectionIndex].Offset + TEXD_SIGN_SIZE); // skip "TEXD" sign + "TEXD" size
    BlockRead(F, TexturesCount, GAME_INTEGER_SIZE);

    for i := 0 to TexturesCount - 1 do begin
      SectionIndex := fTexturesSectionIndex + 1 + i;
      SectionItem := Owner.Sections[SectionIndex]; // get "TEXN" section

      // Get the GBIX PVR size
      Seek(F, SectionItem.Offset + 4);
      BlockRead(F, GBIX_Size, GAME_INTEGER_SIZE);
      Dec(GBIX_Size, TEXN_HEADER_SECTION_SIZE); // 16 is the "TEXN" section header

      GBIX_HeaderOffset := SectionItem.Offset + TEXN_HEADER_SECTION_SIZE;

      // Computing the PVRT header offset and the PVRT data offset
      SavedOffset := FilePos(F);
      ParseTextureData(F, GBIX_HeaderOffset, GBIX_Size, PVRT_HeaderOffset,
        PVRT_DataOffset, PVRT_Size, PVRT_DataSize);
      Seek(F, SavedOffset);

      Add(i, GBIX_HeaderOffset, GBIX_HeaderOffset, PVRT_HeaderOffset,
        PVRT_DataOffset, GBIX_Size, PVRT_Size, PVRT_DataSize, True, SectionIndex); // 16 to skip "TEXN" header
    end;
  end;
end;

procedure TTexturesList.WriteTexturesSection_Shenmue2_MT7(var InStream,
  OutStream: TFileStream);
var
  ImportedFileStream: TFileStream;
  i: Integer;
  CurrentTexture: TTexturesListEntry;
  TXT7_Section_Size_Offset, TXT7_Section_Size_Value,
  TXT7_Textures_Table_Offset, Saved_Offset,
  TXT7_Section_Offset, Texture_Size, GBIX_Offset,
  PVRT_Offset, PVRT_HeaderSizeOffset, IntBuf, 
  TextureDataSize_ForPaddingCalc, TotalPaddingSize: LongWord;
  SignBuf: array[0..3] of Char;
  TextureName: string;
  Padding: array[0..31] of Char;
  
begin
  TXT7_Section_Offset := OutStream.Position;
  TotalPaddingSize := 0; // total padding size for the xbox version
  
  // Write TXT7 section name
  TextureName := GraphicSection.Name;
  OutStream.Write(TextureName[1], 4);

  // Write TXT7 section size
  TXT7_Section_Size_Value := $FFFFFFFF;
  TXT7_Section_Size_Offset := OutStream.Position;
  OutStream.Write(TXT7_Section_Size_Value, GAME_INTEGER_SIZE); // reserve space for writing the size

  // Write Textures count
  IntBuf := Count;
  OutStream.Write(IntBuf, GAME_INTEGER_SIZE);

  // Reserve space for writing textures offsets header table
  TXT7_Textures_Table_Offset := OutStream.Position;
  IntBuf := $EEEEEEEE;
  for i := 0 to Count - 1 do
    OutStream.Write(IntBuf, GAME_INTEGER_SIZE);

  // Writing textures name
  for i := 0 to Count - 1 do
    OutStream.Write(Items[i].fTextureName, TXT7_TEXTURE_NAME_SIZE);

  // Xbox special header operations...
  if Owner.GameVersion = gvShenmue2X then begin
    // Write padding
    ZeroMemory(@Padding, fXboxTXT7HeaderPaddingSize);
    OutStream.Write(Padding, fXboxTXT7HeaderPaddingSize);

    // Write unknow value...
    OutStream.Write(fXboxUnknowValueInEndingHeader, GAME_INTEGER_SIZE);

    // Storing padding size
    Inc(TotalPaddingSize, fXboxTXT7HeaderPaddingSize + GAME_INTEGER_SIZE);
  end;

  // Write Textures
  TXT7_Section_Size_Value := 0;
  for i := 0 to Count - 1 do begin
    CurrentTexture := Items[i];

    // Updating textures header table offset
    Saved_Offset := OutStream.Position;
    OutStream.Seek(TXT7_Textures_Table_Offset + LongWord(i * GAME_INTEGER_SIZE), soFromBeginning);
    IntBuf := Saved_Offset - TXT7_Section_Offset;
    OutStream.Write(IntBuf, GAME_INTEGER_SIZE);
    OutStream.Seek(Saved_Offset, soFromBeginning);

    // Write the texture it self
    if CurrentTexture.Updated then begin

      // Writing GBIX header from source
      GBIX_Offset := GraphicSection.Offset + CurrentTexture.RelativeOffset;
      InStream.Seek(GBIX_Offset, soFromBeginning);
      IntBuf := GBIX_GetSectionSize(InStream);
      OutStream.CopyFrom(InStream, IntBuf);
      Inc(TXT7_Section_Size_Value, IntBuf); // adding the GBIX header size to the TXT7 section total size
      PVRT_Offset := GBIX_Offset + IntBuf;
       
      // Load the imported texture file
      ImportedFileStream := TFileStream.Create(CurrentTexture.ImportFileName, fmOpenRead);
      try
        Texture_Size := ImportedFileStream.Size; // adding the new imported PVR texture size to the TXT7 total size

        (*
          InStream = The source MTx file
          OutStream = The new destination (hacked) MTx file
          ImportedFileStream = The new texture data to write in the OutStream
        *)
        
        // Skip GBIX header (don't needed)
        // This header is skipped if the imported file is Xbox or Dreamcast
        ImportedFileStream.Read(SignBuf, SizeOf(SignBuf));
        if SignBuf = GBIX_PVR_HEADER then begin
          ImportedFileStream.Seek(0, soFromBeginning); // to beginning of the file
          IntBuf := GBIX_GetSectionSize(ImportedFileStream);
          ImportedFileStream.Seek(IntBuf, soFromBeginning); // skip GBIX header
          Dec(Texture_Size, IntBuf); // dec GBIX size
        end else
          ImportedFileStream.Seek(0, soFromBeginning);
                  
        (* 
          Now we are positionned on the PVRT header in the ImportedFileStream
          In Dreamcast version, the work is done, we can copy the stream to the output file
          In Xbox version, if the file imported is a DDS (DirectDraw Surface), so without
          the PVRT header, we must copy it from the InStream (source stream) and
          update the PVRT header data size.
        *)
        
        // Xbox version (create a PVRT header if needed)
        TextureDataSize_ForPaddingCalc := Texture_Size;
        if Owner.GameVersion = gvShenmue2X then begin
          ImportedFileStream.Seek(0, soBeginning);
          ImportedFileStream.Read(SignBuf, SizeOf(SignBuf));

          // if imported texture is DDS...
          if SignBuf = DDS_PVR_HEADER then begin
            // We must dump PVRT header from source
            PVRT_HeaderSizeOffset := OutStream.Position + 4; // 4 for the "PVRT" signature

            // Writing PVRT header from source [16 bytes]
            InStream.Seek(PVRT_Offset, soFromBeginning);
            OutStream.CopyFrom(InStream, PVRT_HEADER_SIZE);

            // Updating PVRT section size with the imported texture size
            OutStream.Seek(PVRT_HeaderSizeOffset, soFromBeginning);
            OutStream.Write(Texture_Size, GAME_INTEGER_SIZE);
            InStream.Seek(PVRT_Offset + PVRT_HEADER_SIZE, soFromBeginning);
            OutStream.Seek(OutStream.Size, soFromBeginning); // we wrote the new Texture_Size, skip to the end of the OutStream file
          end; 

          ImportedFileStream.Seek(0, soBeginning);            
        end;

        // Copy the new texture data stream to the MT file
        OutStream.CopyFrom(ImportedFileStream, Texture_Size);
      finally
        ImportedFileStream.Free;
      end;

    end else begin
      // Write original texture
      // Section.Offset + InsideTexture.Offset because texture offset are in relative format (not absolute)
      Texture_Size := CurrentTexture.Size;
      TextureDataSize_ForPaddingCalc := CurrentTexture.DataSize;
      InStream.Seek(GraphicSection.Offset + CurrentTexture.RelativeOffset, soFromBeginning);
      OutStream.CopyFrom(InStream, Texture_Size);
    end;

    // Writing Padding (for Xbox)
    if (Owner.GameVersion = gvShenmue2X) and (i <> Count - 1) then begin
      // Computing value...
      IntBuf := ComputePaddingSize(TextureDataSize_ForPaddingCalc);
      ZeroMemory(@Padding, IntBuf);
      OutStream.Write(Padding, IntBuf);

      // Write unknow value...
      OutStream.Write(fXboxUnknowValueInEndingHeader, GAME_INTEGER_SIZE);

      // Storing padding size
      Inc(TotalPaddingSize, IntBuf + GAME_INTEGER_SIZE);            
    end;

    // Adding the texture size
    Inc(TXT7_Section_Size_Value, Texture_Size);
  end;

  // Updating texture section size!
  Inc(TXT7_Section_Size_Value, TXT7_HEADER_FIXED_SIZE); // adding TXT7 header fixed size (12 bytes, 4 for TXT7 sign, 4 for TXT7 section size and 4 for textures count)
  Inc(TXT7_Section_Size_Value, Count * (TXT7_TEXTURE_NAME_SIZE + GAME_INTEGER_SIZE)); // adding textures info: textures count * (4 [texture offset] + 8 [texture name])

  // Special Xbox...
  if Owner.GameVersion = gvShenmue2X then begin
    Inc(TXT7_Section_Size_Value, Self.fXboxTexturesSectionSize_ValueToAdd);
    Inc(TXT7_Section_Size_Value, TotalPaddingSize); // size of the padding bytes + the unknow value (4 bytes)    
  end;

  // Writing updated TXT7 section size
  OutStream.Seek(TXT7_Section_Size_Offset, soFromBeginning);
  OutStream.Write(TXT7_Section_Size_Value, GAME_INTEGER_SIZE);
end;

procedure TTexturesList.WriteTexturesSection_Shenmue_MT5_MT6(var InStream,
  OutStream: TFileStream);
var
  i, Texture_Section_Size, IntBuf,
  TEXN_SizeOffset, GBIX_OriginalSize: Integer;
  ImportedFileStream: TFileStream;
  SignBuf: array[0..3] of Char;
  CurrentTexture: TTexturesListEntry;

begin
  // Saving the "TEXD" section
  InStream.Seek(GraphicSection.Offset, soFromBeginning);
  OutStream.CopyFrom(InStream, GraphicSection.Size);

  // Saving "TEXN" sections
  for i := 0 to Count - 1 do begin
    CurrentTexture := Items[i];
    // Write the texture section header "TEXN"
    InStream.Seek(CurrentTexture.Section.Offset, soFromBeginning);
    TEXN_SizeOffset := OutStream.Position + 4; // 4 for the "TEXN" signature
    OutStream.CopyFrom(InStream, TEXN_HEADER_SECTION_SIZE); // 16 is the size of the TEXN header section

    (*
      InStream = The source MTx file
      OutStream = The new destination (hacked) MTx file
      ImportedFileStream = The new texture data to write in the OutStream
    *)

    if Items[i].Updated then begin

      // Writing GBIX header from source
      GBIX_OriginalSize := (CurrentTexture.TextureOffset - CurrentTexture.Offset);      
      InStream.Seek(CurrentTexture.Offset, soFromBeginning);
      OutStream.CopyFrom(InStream, GBIX_OriginalSize);
       
      // Load the imported texture file
      ImportedFileStream := TFileStream.Create(CurrentTexture.ImportFileName, fmOpenRead);
      try
        Texture_Section_Size := ImportedFileStream.Size; // adding the new imported PVR texture size to the TXT7 total size

        // Skip GBIX header (don't needed)
        // This header is skipped if the imported file is "GBIX" / "PVRT"
        ImportedFileStream.Read(SignBuf, 4);
        if SignBuf = GBIX_PVR_HEADER then begin
          ImportedFileStream.Seek(0, soFromBeginning); // to beginning of the file
          IntBuf := GBIX_GetSectionSize(ImportedFileStream);
          ImportedFileStream.Seek(IntBuf, soFromBeginning); // skip GBIX header
          Dec(Texture_Section_Size, IntBuf); // dec GBIX size
        end else
          ImportedFileStream.Seek(0, soBeginning);       

        // Copy the new texture data stream to the MT file
        OutStream.CopyFrom(ImportedFileStream, Texture_Section_Size);
      finally
        ImportedFileStream.Free;
      end;

      // Updating TEXN section size
      Inc(Texture_Section_Size, GBIX_OriginalSize); // adding the original GBIX size
      Inc(Texture_Section_Size, TEXN_HEADER_SECTION_SIZE); // adding the TEXN header size
      OutStream.Seek(TEXN_SizeOffset, soBeginning);
      OutStream.Write(Texture_Section_Size, GAME_INTEGER_SIZE);
      OutStream.Seek(0, soFromEnd); // positionning at the end of the stream to continue the texture writing.
    end else begin
      // Write the original texture
      InStream.Seek(CurrentTexture.Offset, soFromBeginning);
      OutStream.CopyFrom(InStream, CurrentTexture.Size);
    end; // if texture updated

  end; // for
end;

{ TSectionsList }

function TSectionsList.Add(const Name: string; const Offset, Size: Integer): Integer;
var
  Item: TSectionsListEntry;
  
begin
  Item := TSectionsListEntry.Create(Self);
  Item.fName := Name;
  Item.fOffset := Offset;
  Item.fSize := Size;
  Result := fSectionsList.Add(Item);
  {$IFDEF DEBUG} WriteLn('  ', Item.fName, ' [@', Item.fOffset, ', ', Item.fSize, ']'); {$ENDIF}
end;

procedure TSectionsList.Clear;
var
  i: Integer;

begin
  for i := 0 to fSectionsList.Count - 1 do
    TSectionsListEntry(fSectionsList[i]).Free;
  fSectionsList.Clear;
  Owner.Textures.fTexturesSectionIndex  := -1;
end;

constructor TSectionsList.Create(AOwner: TModelTexturedEditor);
begin
  fOwner := AOwner;
  fSectionsList := TList.Create;
end;

destructor TSectionsList.Destroy;
begin
  Clear;
  fSectionsList.Free;
  inherited;
end;

function TSectionsList.GetCount: Integer;
begin
  Result := fSectionsList.Count
end;

function TSectionsList.GetItem(Index: Integer): TSectionsListEntry;
begin
  Result := TSectionsListEntry(fSectionsList[Index]);
end;

function TSectionsList.GetTexturesSectionSize(var F: file;
  TexturesSectionOffset: Integer; var GameVersion: TGameVersion): Integer;
var
  TexturesCount, LastTextureOffset, PVRT_DataSize,
  PVRT_Offset, LastTextureOffsetValue_HeaderTableOffset: Integer;
  TexturesSectionHeader: TRawSectionHeader;

begin
  (*
    The xbox version of the game has a TXT7 section size calculated very strangly...
    It doesn't give the right next section offset... because the size written in the
    section header doesn't match the real section size.
  *)
  
  Result := TexturesSectionOffset;
  GameVersion := gvUndef;

  Seek(F, TexturesSectionOffset);

  // Read the texture sign
  BlockRead(F, TexturesSectionHeader, SizeOf(TRawSectionHeader));

  // Detecting game version
  if TexturesSectionHeader.Name = SHENMUE1_MT6_TEXTURE_SECTION then begin
    // This is Shenmue 1 "TEXD" section

    GameVersion := gvShenmue;

    // skip to the next section
    Result := TexturesSectionHeader.Size;

  end else begin

    // This is Shenmue II "TXT7" section
    GameVersion := gvShenmue2;
    
    // Read the textures count inside the TXT7 section
    BlockRead(F, TexturesCount, GAME_INTEGER_SIZE);
    if TexturesCount > 0 then begin
    
      // Go to the last texture inside the TXT7 section
      LastTextureOffsetValue_HeaderTableOffset := FilePos(F)
        + ((TexturesCount - 1) * GAME_INTEGER_SIZE);
      Seek(F, LastTextureOffsetValue_HeaderTableOffset);
      BlockRead(F, LastTextureOffset, GAME_INTEGER_SIZE);
      LastTextureOffset := TexturesSectionOffset + LastTextureOffset;
      Seek(F, LastTextureOffset);

      // Skip the GBIX section
      BlockRead(F, TexturesSectionHeader, SizeOf(TRawSectionHeader)); // Read the GBIX header
      PVRT_Offset := FilePos(F) + TexturesSectionHeader.Size;
      Seek(F, PVRT_Offset);                                           // Skip the GBIX section

      // Skip the PVRT header
      BlockRead(F, TexturesSectionHeader, SizeOf(TRawSectionHeader)); // Read the PVRT header
      PVRT_DataSize := TexturesSectionHeader.Size;
      Seek(F, FilePos(F) + 8);                                        // Skip the PVRT header and jump to the PVRT data

      // Saving the position before reading data signature
      LastTextureOffset := FilePos(F);
      
      // Read the texture data signature
      BlockRead(F, TexturesSectionHeader, SizeOf(TRawSectionHeader));

      // Skip to the next section
      Result := ((LastTextureOffset + PVRT_DataSize) - TexturesSectionOffset);

      if TexturesSectionHeader.Name = DDS_PVR_HEADER then
        GameVersion := gvShenmue2X
      else
        Dec(Result, 4); // fix for the DC version ...
        // the PVRT data size is computed from the DDS signature for the XBOX version
        // the PVRT data size is computed from after the "pvrt data size" entry for the DC version (-4 bytes compared to the XB version)
    end; // TexturesCount > 0

  end;
end;

function TSectionsList.IsTexturesSection(var F: file; SectionName: string): Boolean;
begin
  Result := (SectionName = SHENMUE1_MT6_TEXTURE_SECTION)
    or (SectionName = SHENMUE2_MT7_TEXTURE_SECTION);
end;

function TSectionsList.ParseFile(var F: file): TGameVersion;
var
  RawEntry: TRawSectionHeader;
  Offset, NextSectionOffset, SectionIndex, RealTexturesSectionSize: Integer;
  Done: Boolean;

  function IsValidSection(var Entry: TRawSectionHeader): Boolean;
  var
    i: Integer;

  begin
    Result := True;
    for i := Low(Entry.Name) to High(Entry.Name) do
      Result := Result and (Entry.Name[i] <> #0);
    Result := Result and (Entry.Size <> 0);
  end;

begin
  Result := gvUndef;
  
{$IFDEF DEBUG}
  WriteLn('*** PARSING SECTIONS ***');
{$ENDIF}

  Done := False;

  // Parsing the file 
  while not Done do begin
    Offset := FilePos(F);
    BlockRead(F, RawEntry, SizeOf(TRawSectionHeader));

    // Parsing the section
//    if (RawEntry.Size < FileSize(F)) then begin
      SectionIndex := Add(RawEntry.Name, Offset, RawEntry.Size);
      NextSectionOffset := Offset + RawEntry.Size;

      // Detecting the Textures section & Game version
      if IsTexturesSection(F, RawEntry.Name) then begin
        RealTexturesSectionSize := GetTexturesSectionSize(F, Offset, Result);
        NextSectionOffset := Offset + RealTexturesSectionSize;

        // The new section added is the textures section.
        Items[SectionIndex].fIsTextures := True;
        Owner.Textures.fTexturesSectionIndex := SectionIndex;

        // For the xbox version, the size in the header doesn't match the REAL section size... F?CK! 
        Items[SectionIndex].fSize := RealTexturesSectionSize;
        Owner.Textures.fXboxTexturesSectionSize_ValueToAdd := RawEntry.Size; // will be computed in 'ParseTexturesSection_Shenmue2_MT7'
      end;

      // If Shenmue 1, we ignore TEXN sections (the TEXD section is the header)
      if RawEntry.Name = SHENMUE1_SECTION_IGNORE then
        Items[SectionIndex].fIgnore := True;

      // Seeking to next section
      Seek(F, NextSectionOffset);
//    end;

//  Done := (EOF(F) and (Offset + SizeOf(TRawSectionHeader) < FileSize(F))) or (not IsValidSectionName(RawEntry.Name));
    Done := (not IsValidSection(RawEntry)) or EOF(F);
  end; // while
end;

{ TModelTexturedEditor }

function TModelTexturedEditor.Close: Boolean;
begin
  Result := False;
  if FileLoaded then begin
    Textures.Clear;
    Sections.Clear;
    fLoadedFileName := '';
    fFileLoaded := False;
    fGameVersion := gvUndef;
    Result := True;
  end;
end;

constructor TModelTexturedEditor.Create;
begin
  fGameVersion := gvUndef;
  fSections := TSectionsList.Create(Self);
  fTextures := TTexturesList.Create(Self);
end;

destructor TModelTexturedEditor.Destroy;
begin
  fSections.Free;
  fTextures.Free;
  inherited;
end;

function TModelTexturedEditor.GetTempFileName: TFileName;

  function GetTempDir : string;
  var
    Dir: array[0..MAX_PATH] of Char;

  begin
    Result := '';
    if GetTempPath(SizeOf(Dir), Dir) <> 0 then
      Result := IncludeTrailingPathDelimiter(StrPas(Dir));
  end;

begin
  Result := GetTempDir + IntToHex(Random($FFFFFFF), 8) + '.SiZ';
end;

function TModelTexturedEditor.LoadFromFile(const FileName: TFileName): Boolean;
var
  F: file;
{$IFDEF DEBUG}
  i: Integer;
{$ENDIF}

begin
  Result := False;
  if not FileExists(FileName) then Exit;

  // Closing current file
  Close;

  // Opening the new file
  Result := True;
  fFileLoaded := True;
  fLoadedFileName := ExpandFileName(FileName);

{$IFDEF DEBUG}
  WriteLn('*** OPENING NEW FILE ***');
  WriteLn('FileName: ', ExtractFileName(FileName));
  WriteLn('');
{$ENDIF}

  // Opening the file
  AssignFile(F, FileName);
  FileMode := fmOpenRead;
  {$I-}Reset(F, 1);{$I+}
  if IOResult <> 0 then Exit;

  try

    try
      // Retrieve file sections
      fGameVersion := Sections.ParseFile(F);

{$IFDEF DEBUG}
      WriteLn('');
{$ENDIF}

      // Parse the texture section
      if GameVersion = gvShenmue then
        Textures.ParseTexturesSection_Shenmue_MT5_MT6(F)
      else if (GameVersion = gvShenmue2) or (GameVersion = gvShenmue2X) then
        Textures.ParseTexturesSection_Shenmue2_MT7(F);

{$IFDEF DEBUG}
      // Showing Textures
      with Textures do begin

        if Count > 0 then begin
          for i := 0 to Count - 1 do
            WriteLn('  #', i, ': GBIX [@', Items[i].Offset, ', ', Items[i].Size, ']',
              '; PVRT [@', Items[i].TextureOffset, ', ', Items[i].TextureSize, ']',
              '; Data [@', Items[i].DataOffset, ', ', Items[i].DataSize, ']'
            );
        end else
          WriteLn('  (empty)');
          
        WriteLn('');
      end;
{$ENDIF}
        
    except
      on E:Exception do begin
{$IFDEF DEBUG}
        WriteLn('READ ERROR: "', ExtractFileName(FileName), '", message: "', E.Message, '"', sLineBreak);
{$ENDIF}
//        Result := False;
      end;
    end;

  finally
    CloseFile(F);
  end;

  // A valid loaded file contains textures.
  Result := Textures.Count > 0;
  if not Result then Close; // invalid file!!
  
//  end {$IFNDEF DEBUG}; {$ELSE} else WriteLn('UNDEFINED FILE FORMAT !!'); {$ENDIF}
end;

function TModelTexturedEditor.Reload: Boolean;
begin
  Result := LoadFromFile(SourceFileName);
end;

function TModelTexturedEditor.Save: Boolean;
begin
  Result := SaveToFile(SourceFileName);
end;

function TModelTexturedEditor.SaveToFile(const FileName: TFileName): Boolean;
var
  i: Integer;
  InStream, OutStream: TFileStream;
  TempFileName: TFileName;

begin
  Result := False;
  if not FileExists(SourceFileName) then Exit;

  TempFileName := GetTempFileName;

{$IFDEF DEBUG}
  WriteLn('*** SAVING AND PATCHING FILE ***');
{$ENDIF}

  InStream := TFileStream.Create(SourceFileName, fmOpenRead);
  OutStream := TFileStream.Create(TempFileName, fmCreate);
  try

    for i := 0 to Sections.Count - 1 do begin

{$IFDEF DEBUG}
      Write('  ', Sections[i].Name, ', offset: ', Sections[i].Offset,
        ', size: ', Sections[i].Size);
{$ENDIF}

      if Sections[i].IsTextures then begin
{$IFDEF DEBUG}
        Write(', (Textures Section)');
{$ENDIF}
        case GameVersion of
{$IFDEF DEBUG}
          gvUndef:
            WriteLn('UNDEFINED GAME VERSION ?!!');
{$ENDIF}
          gvShenmue:
            Textures.WriteTexturesSection_Shenmue_MT5_MT6(InStream, OutStream);

          gvShenmue2:
            Textures.WriteTexturesSection_Shenmue2_MT7(InStream, OutStream);

          gvShenmue2X:
            Textures.WriteTexturesSection_Shenmue2_MT7(InStream, OutStream);
        end;

      end else begin

        // Write file section that isn't a Texture section
        if not Sections[i].Ignored then begin // if not ignored (because we have already written it)
          InStream.Seek(Sections[i].Offset, soFromBeginning);
          OutStream.CopyFrom(InStream, Sections[i].Size);
        end;
        
      end;

{$IFDEF DEBUG}
      WriteLn('');
{$ENDIF}
    end;

  finally
    InStream.Free;
    OutStream.Free;
  end;

  // Same filename for source and destination
  if FileName = SourceFileName then
    if MakeBackup then
      CopyFile(PChar(SourceFileName), PChar(SourceFileName + '.BAK'), False);

  // Saving to the target file name
  if FileExists(TempFileName) then begin
    Result := CopyFile(PChar(TempFileName), PChar(FileName), False);
    DeleteFile(TempFileName);
  end;

  // Reloading the file
  LoadFromFile(SourceFileName);
end;

{ TTexturesListEntry }

procedure TTexturesListEntry.CancelImport;
begin
  fUpdated := False;
  fImportFileName := '';
end;

constructor TTexturesListEntry.Create(AOwner: TTexturesList);
begin
  fOwner := AOwner;
  fMTEditorOwner := Owner.Owner;
end;

procedure TTexturesListEntry.ExportToFile(const FileName: TFileName; OutputFormat: TExportFormat);
var
  F_src, F_dest: file;
  TextureOffset, TextureSize: Integer;

begin

  // Opening the file
  AssignFile(F_src, GetLoadedFileName);
  FileMode := fmOpenRead;
  {$I-}Reset(F_src, 1);{$I+}
  if IOResult <> 0 then Exit;

  // opening the dest file
  AssignFile(F_dest, FileName);
  FileMode := fmOpenWrite;
  {$I-}ReWrite(F_dest, 1);{$I+}
  if IOResult <> 0 then Exit;

  // GBIX save...
  TextureOffset := Offset;
  TextureSize := Size;

  // copy the texture
  case OutputFormat of
    efAll: raise Exception.Create('ExportToFile: The efAll value is ONLY for the ExportToFolder method.');
    efDDS:
          begin
            // Data only (DDS...)
            TextureOffset := DataOffset;
            TextureSize := DataSize;
          end;
  end;

  CopyFileBlock(F_src, F_dest, TextureOffset, TextureSize);

  CloseFile(F_src);
  CloseFile(F_dest);
end;

function TTexturesListEntry.ExportToFolder(const Folder: TFileName): TFileName;
var
  OutputFormat: TExportFormat;

begin
  if (MTEditorOwner.GameVersion = gvShenmue2X) then
    OutputFormat := efAll
  else
    OutputFormat := efPVR;

  Result := ExportToFolder(Folder, OutputFormat);
end;

function TTexturesListEntry.ExportToFolder(const Folder: TFileName; OutputFormat: TExportFormat): TFileName;
var
  DDSResult: TFileName;

begin
  if OutputFormat <> efDDS then begin
    // efAll & efPVR: Result is the PVR file
    Result := IncludeTrailingPathDelimiter(Folder) + GetOutputTextureFileName(efPVR);
    ExportToFile(Result, efPVR);
  end;

  if (OutputFormat <> efPVR) then begin
    DDSResult := IncludeTrailingPathDelimiter(Folder) + GetOutputTextureFileName(efDDS);
    ExportToFile(DDSResult, efDDS);
  end;

  // efDDS: Result is the DDS file
  if (OutputFormat = efDDS) then
    Result := DDSResult;
end;

function TTexturesListEntry.GetLoadedFileName: TFileName;
begin
  Result := Owner.Owner.SourceFileName
end;

function TTexturesListEntry.GetOutputTextureFileName(OutputFormat: TExportFormat): TFileName;
var
  sFormat: string;

begin
  case OutputFormat of
    efPVR: sFormat := 'pvr';
    efDDS: sFormat := 'dds';
    efAll: raise Exception.Create('ExportToFile: The efAll value is ONLY for the ExportToFolder method.');
  end;

  Result := ExtractFileName(GetLoadedFileName) + '_' + UpperCase(sFormat)
    + '#' + Format('%2.2d', [Index + 1]) + '.' + sFormat;
end;

function TTexturesListEntry.GetTexturesSection: TSectionsListEntry;
begin
  if fSectionIndex = -1 then
    raise Exception.Create('Please use the IsFileSection method before calling this!');
  Result := MTEditorOwner.Sections[fSectionIndex];
end;

function TTexturesListEntry.ImportFromFile(const FileName: TFileName): Boolean;
begin
  Result := FileExists(FileName);
  if not Result then Exit;
  fImportFileName := FileName;
  fUpdated := True;
end;

function TTexturesListEntry.IsFileSection: Boolean;
begin
  Result := fIsFileSection;
end;

{ TSectionsListEntry }

constructor TSectionsListEntry.Create(Owner: TSectionsList);
begin
  fOwner := Owner;
  fIsTextures := False;
  fIgnore := False;
end;

procedure TSectionsListEntry.ExportToFile(const Directory: TFileName);
var
  FileName: TFileName;
  
begin
  FileName := IncludeTrailingPathDelimiter(Directory)
    + ExtractFileName(MTEditor.SourceFileName) + '_' + Name + '.BIN';
  SaveToFile(FileName);  
end;

function TSectionsListEntry.GetModelTexturedEditor: TModelTexturedEditor;
begin
  Result := Owner.Owner;
end;

procedure TSectionsListEntry.SaveToFile(const FileName: TFileName);
var
  InStream, OutStream: TFileStream;

begin
  InStream := TFileStream.Create(MTEditor.SourceFileName, fmOpenRead);
  OutStream := TFileStream.Create(FileName, fmCreate);
  try
    InStream.Seek(Offset, soFromBeginning);
    OutStream.CopyFrom(InStream, Size);
  finally
    InStream.Free;
    OutStream.Free;
  end;
end;

end.
