unit xmlconf;

interface

uses
  Windows, SysUtils, XMLDom, XMLIntf, MSXMLDom, XMLDoc, ActiveX;
  
type
  EXMLConfigurationFile = class(Exception);
  EInvalidConfigID = class(EXmlConfigurationFile);

  TXmlConfigurationFile = class
  private
    fXMLDocument: IXMLDocument;
    fLoadedFileName: TFileName;
    fConfigID: string;
  protected
    function GetSectionNode(Section: string; var ResultNode: IXMLNode;
      AllowCreate: Boolean): Boolean;
    procedure InitDocument;
    property XMLDocument: IXMLDocument read fXMLDocument;
  public
    constructor Create(const FileName: TFileName; const ConfigID: string);
    destructor Destroy; override;
    function ReadBool(const Section, Key: string; DefaultValue: Boolean): Boolean; overload;
    function ReadInteger(const Section, Key: string; DefaultValue: Integer): Integer; overload;
    function ReadString(const Section, Key: string; DefaultValue: string): string; overload;
    procedure WriteBool(const Section, Key: string; Value: Boolean); overload;
    procedure WriteInteger(const Section, Key: string; Value: Integer); overload;
    procedure WriteString(const Section, Key, Value: string); overload;
    property ConfigID: string read fConfigID;
    property LoadedFileName: TFileName read fLoadedFileName;
  end;
  
implementation

uses
  Variants;
  
{ TXmlConfigurationFile }

constructor TXmlConfigurationFile.Create(const FileName: TFileName;
  const ConfigID: string);
begin
  CoInitialize(nil);
  fLoadedFileName := FileName;
  fConfigID := ConfigID;
  InitDocument;
end;

destructor TXmlConfigurationFile.Destroy;
begin
  XMLDocument.SaveToFile(LoadedFileName);
  XMLDocument.Active := False;
  fXMLDocument := nil;
  inherited;
end;


function TXmlConfigurationFile.GetSectionNode(Section: string;
  var ResultNode: IXMLNode; AllowCreate: Boolean): Boolean;
begin
  Result := False;
  if Section = '' then
    ResultNode := XMLDocument.DocumentElement
  else begin
    ResultNode := XMLDocument.DocumentElement.ChildNodes.FindNode(Section);
    Result :=  Assigned(ResultNode);

    // Create node if requested
    if (not Result) and AllowCreate then begin
      ResultNode := XMLDocument.CreateNode(Section);
      XMLDocument.DocumentElement.ChildNodes.Add(ResultNode);
      Result := True;
    end;
    
  end; // else
end;

procedure TXmlConfigurationFile.InitDocument;
var
  ReadConfigID: string;

begin
  fXMLDocument := TXMLDocument.Create(nil);
  
  // Setting XMLDocument properties
  with XMLDocument do begin
    Options := [doNodeAutoCreate];
    ParseOptions:= [];
    NodeIndentStr:= '  ';
    Active := True;
    Version := '1.0';
    Encoding := 'ISO-8859-1';
  end;

  // Loading the current file
  if FileExists(LoadedFileName) then begin
    XMLDocument.LoadFromFile(LoadedFileName);

    // Checking the root
    ReadConfigID := XMLDocument.DocumentElement.NodeName;
    if ReadConfigID <> ConfigID then
      raise EInvalidConfigID.Create('Invalid configuration file. ' +
        'The ConfigID is incorrect.' + sLineBreak +
        'ConfigID requested: "' + ConfigID + '", found: "' + ReadConfigID + '"' + sLineBreak + 
        'Input file: "' + LoadedFileName + '".'
      );
  end else
    XMLDocument.DocumentElement := XMLDocument.CreateNode(ConfigID);
end;

function TXmlConfigurationFile.ReadBool(const Section, Key: string;
  DefaultValue: Boolean): Boolean;
begin
  Result := StrToBool(ReadString(Section,
    Key, LowerCase(BoolToStr(DefaultValue, True))));
end;

function TXmlConfigurationFile.ReadInteger(const Section, Key: string;
  DefaultValue: Integer): Integer;
begin
  Result := StrToInt(ReadString(Section, Key, IntToStr(DefaultValue)));
end;

function TXmlConfigurationFile.ReadString(const Section, Key: string;
  DefaultValue: string): string;
var
  RootNode, Node: IXMLNode;

begin
  Result := DefaultValue;
  try
    if GetSectionNode(Section, RootNode, False) then begin
      Node := RootNode.ChildNodes.FindNode(Key);
      if Assigned(Node) and (not VarIsNull(Node.NodeValue)) then
        Result := Node.NodeValue;
    end;
  except
  end;
end;

procedure TXmlConfigurationFile.WriteBool(const Section, Key: string; Value: Boolean);
begin
  WriteString(Section, Key, LowerCase(BoolToStr(Value, True)));
end;

procedure TXmlConfigurationFile.WriteInteger(const Section, Key: string;
  Value: Integer);
begin
  WriteString(Section, Key, IntToStr(Value));
end;

procedure TXmlConfigurationFile.WriteString(const Section, Key, Value: string);
var
  RootNode,
  CurrentNode: IXMLNode;
  
begin
  if GetSectionNode(Section, RootNode, True) then begin

    CurrentNode := RootNode.ChildNodes.FindNode(Key);
    if not Assigned(CurrentNode) then begin
      CurrentNode := XMLDocument.CreateNode(Key);
      RootNode.ChildNodes.Add(CurrentNode);
    end;

    CurrentNode.NodeValue := Value;
  end;
end;

end.