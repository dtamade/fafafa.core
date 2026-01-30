unit fafafa.core.ini;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes;

type
  TIniValueType = (
    ivtString
  );

  TIniErrorCode = (
    iecSuccess,
    iecInvalidParameter,
    iecInvalidIni,
    iecDuplicateKey,
    iecFileIO
  );

  TIniError = record
    Code: TIniErrorCode;
    Message: String;
    Position: SizeUInt; // 字节偏移
    Line: SizeUInt;     // 行号（1 基）
    Column: SizeUInt;   // 列号（1 基）
  public
    procedure Clear; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    function HasError: Boolean; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    function ToString: String;
  end;



  IIniSection = interface
  ['{B0C9D3B7-6B9E-4D0F-8F28-1F6A02E8E8A1}']
    function Name: String;
    function Contains(const AKey: String): Boolean;
    function TryGetString(const AKey: String; out AOut: String): Boolean;
    function TryGetInt(const AKey: String; out AOut: Int64): Boolean;
    function TryGetBool(const AKey: String; out AOut: Boolean): Boolean;
    function TryGetFloat(const AKey: String; out AOut: Double): Boolean;
    function KeyCount: SizeInt;
    function KeyAt(const AIndex: SizeInt): String;
  end;

  // 内部可变接口（解析阶段使用）
  IIniSectionMutable = interface(IIniSection)
  ['{8D5B7B2E-2C11-4B7F-9B4C-9C5F7A1E3D92}']
    procedure PutKV(const AKey, AValue: String);
    procedure PutStr(const AKey, AValue: String);
    procedure PutInt(const AKey: String; const AValue: Int64);
    procedure PutBool(const AKey: String; const AValue: Boolean);
    procedure PutFloat(const AKey: String; const AValue: Double);
    function RemoveKey(const AKey: String): Boolean;
  end;

  // 内部只读扩展（写出时使用），不破坏公共 API
  IIniSectionInternal = interface(IIniSection)
  ['{B7EC5D7E-7C1D-4A49-AF3C-9C6B3E4A0C11}']
    function GetHeaderPad: TStrings;
    function GetBodyLines: TStrings;
    procedure SetHasKeys(const V: Boolean);
    function GetHasKeys: Boolean;
    procedure SetDirty(const V: Boolean);
    function GetDirty: Boolean;
  end;




  IIniDocument = interface
  ['{C6B1C4E3-63B3-4BE5-8CE7-19E5C9A9E4D7}']
    function SectionCount: SizeInt;
    function SectionNameAt(const AIndex: SizeInt): String;
    function HasSection(const AName: String): Boolean;
    function GetSection(const AName: String): IIniSection;
    function TryGetString(const ASection, AKey: String; out AOut: String): Boolean;
    procedure SetString(const ASection, AKey, AValue: String);
    procedure SetInt(const ASection, AKey: String; const AValue: Int64);
    procedure SetBool(const ASection, AKey: String; const AValue: Boolean);
    procedure SetFloat(const ASection, AKey: String; const AValue: Double);
    // 增量 API（兼容增强）
    function HasKey(const ASection, AKey: String): Boolean;
    function RemoveKey(const ASection, AKey: String): Boolean;
    function RemoveSection(const ASection: String): Boolean;
  // Facade Set* helpers for tests and external use (not interface methods)

  end;

// Facade Set* helpers for tests and external use (global procedures)
procedure SetString(const ADoc: IIniDocument; const ASection, AKey, AValue: String);
procedure SetInt(const ADoc: IIniDocument; const ASection, AKey: String; const AValue: Int64);
procedure SetBool(const ADoc: IIniDocument; const ASection, AKey: String; const AValue: Boolean);
procedure SetFloat(const ADoc: IIniDocument; const ASection, AKey: String; const AValue: Double);

  type
  IIniDocumentInternal = interface(IIniDocument)
  ['{A3D6ED6B-1E51-4B67-9C61-5C8B3D092E77}']
    function GetPrelude: TStrings;
    function IsDirty: Boolean;
    function GetEntryCount: SizeInt;
    function GetEntryRaw(const AIndex: SizeInt): String;
  end;

  // AST 节点定义：保持文本顺序与注释/空白
  TIniEntryKind = (iekPrelude, iekSectionHeader, iekKeyValue, iekComment, iekBlank);
  PIniEntry = ^TIniEntry;
  TIniEntry = record
    Kind: TIniEntryKind;
    Section: String;   // 归属节名（Prelude/SectionHeader 可为空）
    Key: String;
    Value: String;
    Raw: String;       // 原始文本（用于回放）
  end;


  TIniReadFlag = (
    irfDefault,
    irfCaseSensitiveKeys,
    irfCaseSensitiveSections,
    irfDuplicateKeyError,
    irfInlineComment,     // value supports inline comments (';' or '#') after value
    irfStrictKeyChars,    // 键名仅允许 [A-Za-z0-9_.-]
    irfAllowQuotedValue   // 保留外层引号，不再在 inline-comment 模式下去除
  );
  TIniReadFlags = set of TIniReadFlag;

  TIniWriteFlag = (
    iwfDefault,
    iwfSpacesAroundEquals, // 输出时在分隔符两侧留空格
    iwfPreferColon,        // 写出时优先使用 ':' 作为分隔符
    iwfBoolUpperCase,      // 写出时将 true/false 转为大写
    iwfForceLF,            // 写出统一使用 LF 换行
    iwfWriteBOM,           // 写入 UTF-8 BOM（仅 ToFile 生效）
    iwfStableKeyOrder,     // 重组输出时对键名排序，获得稳定顺序
    iwfTrailingNewline,    // 输出末尾确保存在一个换行
    iwfNoSectionSpacer,    // 不在每个节后自动追加空行
    iwfQuoteValuesWhenNeeded, // 当值包含分隔符/注释符/前后空白时加引号
    iwfQuoteSpaces         // 值中包含任意空格或制表符时加引号

  );
  TIniWriteFlags = set of TIniWriteFlag;

// 门面 API
  // Expose concrete document class type for tests; methods implemented in implementation section
  TIniDocumentImpl = class(TInterfacedObject, IIniDocument, IIniDocumentInternal)
  private
    FSectionNames: TStringList; // section names in order
    FSections: TInterfaceList;  // parallel list: IIniSection per name
  private
    FPrelude: TStringList; // 文件最前面的注释与空白行
    FEntries: array of TIniEntry; // 文件级条目序列（Prelude/SectionHeader/Key/Comment/Blank）
    FDirty: Boolean; // 任意 Set* 修改后为 True
  public
    constructor Create;
    destructor Destroy; override;
    function SectionCount: SizeInt;
    function SectionNameAt(const AIndex: SizeInt): String;
    function HasSection(const AName: String): Boolean;
    function GetSection(const AName: String): IIniSection;
  public
    // 仅供内部友元使用（写出时）
    function GetPrelude: TStrings;
    // IIniDocumentInternal additions
    function IsDirty: Boolean;
    function GetEntryCount: SizeInt;
    function GetEntryRaw(const AIndex: SizeInt): String;
    // public facade APIs
    function EnsureSection(const AName: String): IIniSectionMutable;
    function TryGetString(const ASection, AKey: String; out AOut: String): Boolean;
    function TryGetInt(const ASection, AKey: String; out AOut: Int64): Boolean;
    function TryGetBool(const ASection, AKey: String; out AOut: Boolean): Boolean;
    function TryGetFloat(const ASection, AKey: String; out AOut: Double): Boolean;
    procedure SetString(const ASection, AKey, AValue: String);
    function HasKey(const ASection, AKey: String): Boolean;
    function RemoveKey(const ASection, AKey: String): Boolean;
    function RemoveSection(const ASection: String): Boolean;
    procedure SetInt(const ASection, AKey: String; const AValue: Int64);
    procedure SetBool(const ASection, AKey: String; const AValue: Boolean);
    procedure SetFloat(const ASection, AKey: String; const AValue: Double);
  end;

function Parse(const AText: RawByteString; out ADoc: IIniDocument; out AErr: TIniError; const AFlags: TIniReadFlags = []): Boolean; overload;
function ParseFile(const AFileName: String; out ADoc: IIniDocument; out AErr: TIniError; const AFlags: TIniReadFlags = []): Boolean; overload;
function ParseStream(const AStream: TStream; out ADoc: IIniDocument; out AErr: TIniError; const AFlags: TIniReadFlags = []): Boolean; overload;
function ToFile(const ADoc: IIniDocument; const AFileName: String; const AFlags: TIniWriteFlags = [iwfSpacesAroundEquals]): Boolean;
function ParseFileEx(const AFileName: String; out ADoc: IIniDocument; out AErr: TIniError; out DetectedEncoding: String; const AFlags: TIniReadFlags = []): Boolean;



function ToIni(const ADoc: IIniDocument; const AFlags: TIniWriteFlags = [iwfSpacesAroundEquals]): RawByteString;

implementation



type
  TIniSectionImpl = class(TInterfacedObject, IIniSection, IIniSectionMutable, IIniSectionInternal)
  private
    FName: String;
    FKeys: TStringList; // key -> value
    FHeaderPad: TStringList; // 注释/空行，位于节头之后、首个键之前
    FBodyLines: TStringList; // 节内主体的原始行（键、注释、空行的顺序）
    FHasKeys: Boolean; // 是否已经出现过键，区分 HeaderPad 与 BodyLines 区域中界
    FDirty: Boolean; // 本节是否有修改
  public
    constructor Create(const AName: String);
    destructor Destroy; override;
    function Name: String;
    function Contains(const AKey: String): Boolean;
    function TryGetString(const AKey: String; out AOut: String): Boolean;
    function TryGetInt(const AKey: String; out AOut: Int64): Boolean;
    function TryGetBool(const AKey: String; out AOut: Boolean): Boolean;
    function TryGetFloat(const AKey: String; out AOut: Double): Boolean;
    function KeyCount: SizeInt;
    function KeyAt(const AIndex: SizeInt): String;
    procedure PutKV(const AKey, AValue: String);
    procedure PutStr(const AKey, AValue: String);
    procedure PutInt(const AKey: String; const AValue: Int64);
    procedure PutBool(const AKey: String; const AValue: Boolean);
    procedure PutFloat(const AKey: String; const AValue: Double);
    function RemoveKey(const AKey: String): Boolean;
    procedure AddHeaderPadLine(const S: String);
    // IIniSectionInternal
    function GetHeaderPad: TStrings;
    function GetBodyLines: TStrings;
    procedure SetHasKeys(const V: Boolean);
    function GetHasKeys: Boolean;
    procedure SetDirty(const V: Boolean);
    function GetDirty: Boolean;
  end;

{ TIniError }
procedure TIniError.Clear;
begin
  Code := iecSuccess;
  Message := '';
  Position := 0;
  Line := 0;
  Column := 0;
end;

function TIniError.HasError: Boolean;
begin
  Result := Code <> iecSuccess;
end;

function TIniError.ToString: String;
begin
  if not HasError then Exit('OK');
  Result := Format('[%d:%d] %s (code=%d)', [Line, Column, Message, Ord(Code)]);
end;

{ TIniSectionImpl }
constructor TIniSectionImpl.Create(const AName: String);
begin
  inherited Create;
  FName := AName;
  FKeys := TStringList.Create;
  FKeys.CaseSensitive := False;
  FKeys.Sorted := False;
  FKeys.Duplicates := dupIgnore;
  FHeaderPad := TStringList.Create;
  FBodyLines := TStringList.Create;
  FHasKeys := False;
  FDirty := False;

end;

destructor TIniSectionImpl.Destroy;
begin

  FBodyLines.Free;
  FHeaderPad.Free;
  FKeys.Free;
  inherited Destroy;
end;

function TIniSectionImpl.GetBodyLines: TStrings;
begin
  Result := FBodyLines;
end;

procedure TIniSectionImpl.SetDirty(const V: Boolean);
begin
  FDirty := V;
end;

function TIniSectionImpl.GetDirty: Boolean;
begin
  Result := FDirty;
end;

procedure TIniSectionImpl.SetHasKeys(const V: Boolean);
begin
  FHasKeys := V;
end;

function TIniSectionImpl.GetHasKeys: Boolean;
begin
  Result := FHasKeys;
end;

function TIniSectionImpl.Name: String;
begin
  Result := FName;
end;

function TIniSectionImpl.Contains(const AKey: String): Boolean;
begin
  Result := FKeys.IndexOfName(AKey) >= 0;
end;

function TIniSectionImpl.TryGetString(const AKey: String; out AOut: String): Boolean;
var Idx: Integer; V: String;
begin
  Idx := FKeys.IndexOfName(AKey);
  Result := Idx >= 0;
  if Result then
    AOut := Copy(FKeys[Idx], Length(FKeys.Names[Idx]) + 2, MaxInt) // name=value
  else
    AOut := '';
end;

function TIniSectionImpl.GetHeaderPad: TStrings;
begin
  Result := FHeaderPad;
end;

function TIniSectionImpl.TryGetInt(const AKey: String; out AOut: Int64): Boolean;
var S: String;
begin
  Result := TryGetString(AKey, S);
  if not Result then Exit;
  Result := TryStrToInt64(Trim(S), AOut);
end;

function TIniSectionImpl.TryGetBool(const AKey: String; out AOut: Boolean): Boolean;
var S: String;
    L: String;
begin
  Result := TryGetString(AKey, S);
  if not Result then Exit;
  L := LowerCase(Trim(S));
  if (L='1') or (L='true') or (L='yes') or (L='on') then begin AOut:=True; Exit(True); end;
  if (L='0') or (L='false') or (L='no') or (L='off') then begin AOut:=False; Exit(True); end;
  Result := False;
end;

function TIniSectionImpl.TryGetFloat(const AKey: String; out AOut: Double): Boolean;
var S: String; FS: TFormatSettings;
begin
  Result := TryGetString(AKey, S);
  if not Result then Exit;
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';
  Result := TryStrToFloat(Trim(S), AOut, FS);
end;

function TIniSectionImpl.KeyCount: SizeInt;
begin
  Result := FKeys.Count;
end;

function TIniSectionImpl.KeyAt(const AIndex: SizeInt): String;
begin
  if (AIndex < 0) or (AIndex >= FKeys.Count) then
    raise Exception.CreateFmt('Key index out of range: %d', [AIndex]);
  Result := FKeys.Names[AIndex];
end;

procedure TIniSectionImpl.PutKV(const AKey, AValue: String);
var Idx: Integer;
begin
  Idx := FKeys.IndexOfName(AKey);
  if Idx >= 0 then
    FKeys.ValueFromIndex[Idx] := AValue
  else
    FKeys.Add(AKey + '=' + AValue);

  // 注意：PutKV 不标记脏，供解析阶段复用；由 PutStr/PutInt/PutBool/PutFloat 标记脏
end;

procedure TIniSectionImpl.AddHeaderPadLine(const S: String);
begin
  FHeaderPad.Add(S);
end;

procedure TIniSectionImpl.PutStr(const AKey, AValue: String);
begin
  PutKV(AKey, AValue);
  FDirty := True;
end;

procedure TIniSectionImpl.PutInt(const AKey: String; const AValue: Int64);
begin
  PutKV(AKey, IntToStr(AValue));
  FDirty := True;
end;

procedure TIniSectionImpl.PutBool(const AKey: String; const AValue: Boolean);
begin
  if AValue then PutKV(AKey, 'true') else PutKV(AKey, 'false');
  FDirty := True;
end;

procedure TIniSectionImpl.PutFloat(const AKey: String; const AValue: Double);
var FS: TFormatSettings;
begin
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';
  PutKV(AKey, FloatToStr(AValue, FS));
  FDirty := True;
end;

function TIniSectionImpl.RemoveKey(const AKey: String): Boolean;
var Idx: Integer;
begin
  Idx := FKeys.IndexOfName(AKey);
  if Idx < 0 then Exit(False);
  FKeys.Delete(Idx);

  FDirty := True;
  Result := True;
end;


{ TIniDocumentImpl }
constructor TIniDocumentImpl.Create;
begin
  inherited Create;
  FPrelude := TStringList.Create;
  FSectionNames := TStringList.Create;
  FSectionNames.CaseSensitive := False;
  FSectionNames.Sorted := False;
  FSectionNames.Duplicates := dupIgnore;
  FSections := TInterfaceList.Create;
  FDirty := False;
  SetLength(FEntries, 0);
end;

destructor TIniDocumentImpl.Destroy;
begin
  FSections := nil; // interface list auto releases
  FSectionNames.Free;
  FPrelude.Free;
  inherited Destroy;
end;

function TIniDocumentImpl.SectionCount: SizeInt;
begin
  Result := FSectionNames.Count;
end;

function TIniDocumentImpl.SectionNameAt(const AIndex: SizeInt): String;
begin
  if (AIndex < 0) or (AIndex >= FSectionNames.Count) then
    raise Exception.CreateFmt('Section index out of range: %d', [AIndex]);
  Result := FSectionNames[AIndex];
end;

function TIniDocumentImpl.HasSection(const AName: String): Boolean;
begin
  Result := FSectionNames.IndexOf(AName) >= 0;
end;

function TIniDocumentImpl.GetSection(const AName: String): IIniSection;
var Idx: Integer;
begin
  Idx := FSectionNames.IndexOf(AName);
  if (Idx < 0) or (Idx >= FSections.Count) then Exit(nil);
  Result := (FSections.Items[Idx] as IIniSection);
end;

function TIniDocumentImpl.EnsureSection(const AName: String): IIniSectionMutable;
var Idx: Integer;
    Sec: TIniSectionImpl;
    Iface: IIniSection;
begin
  Idx := FSectionNames.IndexOf(AName);
  if Idx >= 0 then
    Exit((FSections.Items[Idx] as IIniSectionMutable));

  // create when not exists
  Sec := TIniSectionImpl.Create(AName);
  Iface := Sec;
  FSectionNames.Add(AName);
  FSections.Add(Iface as IInterface);
  Result := Sec as IIniSectionMutable;
  Exit;
end;

function TIniDocumentImpl.HasKey(const ASection, AKey: String): Boolean;
var Sec: IIniSection;
begin
  Result := False;
  Sec := GetSection(ASection);
  if Sec = nil then Exit(False);
  Result := Sec.Contains(AKey);
end;

function TIniDocumentImpl.RemoveKey(const ASection, AKey: String): Boolean;
var Sec: IIniSectionMutable; SecInt: IIniSectionInternal;
begin
  Result := False;
  Sec := EnsureSection(ASection);
  if Sec = nil then Exit(False);
  Result := (Sec as TIniSectionImpl).RemoveKey(AKey);
  if Result then
  begin
    if Supports(Sec, IIniSectionInternal, SecInt) then SecInt.SetDirty(True);
    FDirty := True;
  end;
end;

function TIniDocumentImpl.RemoveSection(const ASection: String): Boolean;
var Idx: Integer;
begin
  Result := False;
  Idx := FSectionNames.IndexOf(ASection);
  if Idx < 0 then Exit(False);
  FSectionNames.Delete(Idx);
  FSections.Delete(Idx);
  FDirty := True;
  Result := True;
end;

function TIniDocumentImpl.IsDirty: Boolean;
begin
  Result := FDirty;
end;

function TIniDocumentImpl.GetEntryCount: SizeInt;
begin
  Result := Length(FEntries);
end;

function TIniDocumentImpl.GetEntryRaw(const AIndex: SizeInt): String;
begin
  if (AIndex < 0) or (AIndex >= Length(FEntries)) then Exit('');
  Result := FEntries[AIndex].Raw;
end;

function TIniDocumentImpl.GetPrelude: TStrings;
begin
  Result := FPrelude;
end;


function TIniDocumentImpl.TryGetString(const ASection, AKey: String; out AOut: String): Boolean;
var Sec: IIniSection;
begin
  Sec := GetSection(ASection);
  if Sec = nil then Exit(False);
  Result := Sec.TryGetString(AKey, AOut);
end;

function TIniDocumentImpl.TryGetInt(const ASection, AKey: String; out AOut: Int64): Boolean;
var Sec: IIniSection;
begin
  Sec := GetSection(ASection);
  if Sec = nil then Exit(False);
  Result := Sec.TryGetInt(AKey, AOut);
end;

function TIniDocumentImpl.TryGetBool(const ASection, AKey: String; out AOut: Boolean): Boolean;
var Sec: IIniSection;
begin
  Sec := GetSection(ASection);
  if Sec = nil then Exit(False);
  Result := Sec.TryGetBool(AKey, AOut);
end;

function TIniDocumentImpl.TryGetFloat(const ASection, AKey: String; out AOut: Double): Boolean;
var Sec: IIniSection;
begin
  Sec := GetSection(ASection);
  if Sec = nil then Exit(False);
  Result := Sec.TryGetFloat(AKey, AOut);
end;

// 解析器（最小实现）
function InternalParseFromStrings(const Lines: TStrings; out Doc: IIniDocument; out Err: TIniError; const AFlags: TIniReadFlags): Boolean;
var
  I: Integer;
  L: String;
  CurSec: IIniSectionMutable;
  P: SizeInt; ch: Char;
  Key, Val, SecName: String;
  Impl: TIniDocumentImpl;
  E: TIniEntry;
  SeenHeader: Boolean;
  CurSecName: String;
  j: SizeInt;
  inSQ, inDQ: Boolean;
  PosAcc: SizeUInt; // approx char offset, used for Err.Position
  LTrim: String; Off: SizeInt;
  ErrColLocal: SizeInt;
  ErrKind: Integer;
  procedure AppendEntry(const AE: TIniEntry);
  var N: SizeInt;
  begin
    N := Length(Impl.FEntries);
    SetLength(Impl.FEntries, N + 1);
    Impl.FEntries[N] := AE;
  end;
  function TreatAsPrelude: Boolean;
  begin
    // 在出现任何节头或默认节键之前的注释/空行，归属文件级 Prelude
    Result := (CurSecName = '') and (CurSec <> nil) and
              (not (CurSec as IIniSectionInternal).GetHasKeys) and (not SeenHeader);
  end;
  function FindKVSep(const S: String; out SepPos: SizeInt; out SepCh: Char): Boolean;
  var k: SizeInt; sq, dq: Boolean; chL: Char;
  begin
    sq := False; dq := False; SepPos := 0; SepCh := #0;
    for k := 1 to Length(S) do
    begin
      chL := S[k];
      if (chL = '''') and (not dq) then sq := not sq
      else if (chL = '"') and (not sq) then dq := not dq
      else if (not sq) and (not dq) and ((chL = '=') or (chL = ':')) then
      begin
        SepPos := k; SepCh := chL; Exit(True);
      end;
    end;
    Result := False;
  end;
  function ScanKVLine(const S: String; out SepPos: SizeInt; out SepCh: Char;
    out Key, Val: String; out ErrCol: SizeInt; const Flags: TIniReadFlags; out ErrKind: Integer): Boolean;
  const
    ERR_NONE = 0;
    ERR_NO_SEP = 1;
    ERR_UNCLOSED_QUOTE = 2;
  var
    k, j: SizeInt;
    inSQ, inDQ: Boolean;
    chL: Char;
  begin
    ErrKind := ERR_NONE;
    ErrCol := 1;
    SepPos := 0; SepCh := #0;
    inSQ := False; inDQ := False;
    // 一次扫描：找到未在引号内的第一个 KV 分隔符
    for k := 1 to Length(S) do
    begin
      chL := S[k];
      if (chL = '''') and (not inDQ) then inSQ := not inSQ
      else if (chL = '"') and (not inSQ) then inDQ := not inDQ
      else if (not inSQ) and (not inDQ) and ((chL = '=') or (chL = ':')) then
      begin
        SepPos := k; SepCh := chL; Break;
      end;
    end;
    if SepPos = 0 then
    begin
      ErrKind := ERR_NO_SEP;
      ErrCol := 1;
      Exit(False);
    end;

    Key := Trim(Copy(S, 1, SepPos - 1));
    Val := Trim(Copy(S, SepPos + 1, MaxInt));

    // 行内注释处理（引号感知）
    if (irfInlineComment in Flags) then
    begin
      inSQ := False; inDQ := False;
      for j := 1 to Length(Val) do
      begin
        if (Val[j] = '''') and (not inDQ) then inSQ := not inSQ
        else if (Val[j] = '"') and (not inSQ) then inDQ := not inDQ
        else if (not inSQ) and (not inDQ) and ((Val[j] = ';') or (Val[j] = '#')) then
        begin
          Val := Trim(Copy(Val, 1, j - 1));
          Break;
        end;
      end;
      if inSQ or inDQ then
      begin
        ErrKind := ERR_UNCLOSED_QUOTE;
        ErrCol := SepPos + 1; // 指向分隔符之后
        Exit(False);
      end;
      if not (irfAllowQuotedValue in Flags) then
      begin
        if Length(Val) >= 2 then
          if (((Val[1] = '"') and (Val[Length(Val)] = '"')) or
              ((Val[1] = '''') and (Val[Length(Val)] = ''''))) then
            Val := Copy(Val, 2, Length(Val) - 2);
      end;
    end;

    Result := True;
  end;

begin
  Result := False;
  Err.Clear;
  Impl := TIniDocumentImpl.Create;
  Doc := Impl;
  CurSec := Impl.EnsureSection(''); // 默认节
  SeenHeader := False;
  CurSecName := '';
  PosAcc := 0;
  for I := 0 to Lines.Count - 1 do
  begin
    L := Lines[I];
    // 允许前置空白：用于精确 Column 计算（Off）
    LTrim := L;
    Off := 1;
    while (Off <= Length(LTrim)) and (LTrim[Off] in [' ', #9]) do Inc(Off);
    // 空行或注释：在节头部或主体中保留
    if Trim(L) = '' then
    begin
      if TreatAsPrelude then
        Impl.FPrelude.Add('')
      else if CurSec <> nil then
      begin
        if not (CurSec as IIniSectionInternal).GetHasKeys then
          (CurSec as TIniSectionImpl).AddHeaderPadLine('')
        else
          (CurSec as IIniSectionInternal).GetBodyLines.Add('');
      end
      else
        Impl.FPrelude.Add('');
      // entries: prelude blank vs section blank
      FillChar(E, SizeOf(E), 0);
      if TreatAsPrelude or (not SeenHeader) then E.Kind := iekPrelude else E.Kind := iekBlank;
      E.Section := CurSecName;
      E.Raw := L;
      AppendEntry(E);
      Inc(PosAcc, Length(L) + 1);
      Continue;
    end;
    if (LTrim[Off] = ';') or (LTrim[Off] = '#') then
    begin
      if TreatAsPrelude then
        Impl.FPrelude.Add(L)
      else if CurSec <> nil then
      begin
        if not (CurSec as IIniSectionInternal).GetHasKeys then
          (CurSec as TIniSectionImpl).AddHeaderPadLine(L)
        else
          (CurSec as IIniSectionInternal).GetBodyLines.Add(L);
      end
      else
        Impl.FPrelude.Add(L);
      // entries: prelude comment vs section comment
      FillChar(E, SizeOf(E), 0);
      if TreatAsPrelude or (not SeenHeader) then E.Kind := iekPrelude else E.Kind := iekComment;
      E.Section := CurSecName;
      E.Raw := L;
      AppendEntry(E);
      Inc(PosAcc, Length(L) + 1);
      Continue;
    end;
    if (LTrim[Off] = '[') then
    begin
      // 查找对应的 ']'
      P := 0;
      for j := Off+1 to Length(L) do
        if L[j] = ']' then begin P := j; Break; end;
      if P <= Off then
      begin
        Err.Code := iecInvalidIni;
        Err.Line := I + 1;
        Err.Column := Off; // 指向 '[' 的列
        Err.Position := PosAcc + Err.Column;
        Err.Message := 'Unclosed section header';
        Exit(False);
      end;
      SecName := Trim(Copy(L, Off+1, P - (Off+1)));
      // 检查节头后的尾随字符：只允许空白或注释
      j := P + 1;
      while (j <= Length(L)) and (L[j] in [' ', #9]) do Inc(j);
      if (j <= Length(L)) and (L[j] <> ';') and (L[j] <> '#') then
      begin
        Err.Code := iecInvalidIni;
        Err.Line := I + 1;
        Err.Column := j;
        Err.Position := PosAcc + Err.Column;
        Err.Message := 'Unexpected characters after section header';
        Exit(False);
      end;
      CurSecName := SecName;
      // entries: section header
      FillChar(E, SizeOf(E), 0);
      E.Kind := iekSectionHeader;
      E.Section := CurSecName;
      E.Raw := L;
      AppendEntry(E);
      CurSec := Impl.EnsureSection(SecName);
      SeenHeader := True;
      Inc(PosAcc, Length(L) + 1);
      Continue;
    end;
    // key = value 或 key: value（行级 tokenizer 扫描）
    ErrColLocal := 1; ErrKind := 0;
    if not ScanKVLine(L, P, ch, Key, Val, ErrColLocal, AFlags, ErrKind) then
    begin
      Err.Code := iecInvalidIni;
      Err.Line := I + 1;
      case ErrKind of
        1: begin
             Err.Column := 1;
             Err.Message := 'Expect key=value';
           end;
        2: begin
             Err.Column := ErrColLocal;
             Err.Message := 'Unclosed quote in value';
           end;
      else
        Err.Column := 1;
        Err.Message := 'Invalid INI line';
      end;
      Err.Position := PosAcc + Err.Column;
      Exit(False);
    end;
    // 大小写敏感/重复键策略（在首次需要时一次性固定）
    if irfCaseSensitiveSections in AFlags then
      Impl.FSectionNames.CaseSensitive := True;
    if irfCaseSensitiveKeys in AFlags then
      (CurSec as TIniSectionImpl).FKeys.CaseSensitive := True;

    // 可选：严格键名字符
    if (irfStrictKeyChars in AFlags) then
    begin
      for j := 1 to Length(Key) do
        if not (Key[j] in ['A'..'Z','a'..'z','0'..'9','_','-','.']) then
        begin
          Err.Code := iecInvalidIni;
          Err.Line := I + 1;
          Err.Column := j; // 指向非法字符
          Err.Position := PosAcc + Err.Column;
          Err.Message := 'Illegal character in key';
          Exit(False);
        end;
    end;

    if Key = '' then
    begin
      Err.Code := iecInvalidIni;
      Err.Line := I + 1;
      Err.Column := 1;
      Err.Position := PosAcc + Err.Column;
      Err.Message := 'Empty key';
      Exit(False);
    end;
    if (not (irfDuplicateKeyError in AFlags)) then
    begin
      // 覆盖默认：已在 PutKV 中处理
    end
    else
    begin
      if (CurSec as TIniSectionImpl).FKeys.IndexOfName(Key) >= 0 then
      begin
        Err.Code := iecDuplicateKey;
        Err.Line := I + 1;
        Err.Column := 1;
        Err.Position := PosAcc + Err.Column;
        Err.Message := 'Duplicate key';
        Exit(False);
      end;
    end;
    // entries: key=value
    FillChar(E, SizeOf(E), 0);
    E.Kind := iekKeyValue;
    E.Section := CurSecName;
    E.Key := Key;
    E.Value := Val;
    E.Raw := L;
    SetLength(Impl.FEntries, Length(Impl.FEntries)+1);
    Impl.FEntries[High(Impl.FEntries)] := E;

    CurSec.PutKV(Key, Val);
    // 记录主体原始行
    (CurSec as IIniSectionInternal).SetHasKeys(True);
    (CurSec as IIniSectionInternal).GetBodyLines.Add(L);
    Inc(PosAcc, Length(L) + 1);
  end;
  Result := True;
end;

function Parse(const AText: RawByteString; out ADoc: IIniDocument; out AErr: TIniError; const AFlags: TIniReadFlags): Boolean;
var SL: TStringList;
begin
  SL := TStringList.Create;
  try
    // 统一按 UTF-8 解码，RawByteString 视为 UTF-8 字节
    {$IFDEF WINDOWS}
    SL.Text := UTF8Decode(AText);
    {$ELSE}
    SL.Text := UTF8Decode(AText);
    {$ENDIF}
    Result := InternalParseFromStrings(SL, ADoc, AErr, AFlags);
  finally
    SL.Free;
  end;
end;

function DetectAndLoadAsUTF8(const AStream: TStream): RawByteString;
var
  Ms: TMemoryStream;
  Len: SizeInt;
  S: RawByteString;
  I, Count: SizeInt;
  WS: UnicodeString;
  loB, hiB: Byte;
begin
  Ms := TMemoryStream.Create;
  try
    Ms.CopyFrom(AStream, 0);
    Ms.Position := 0;
    Len := Ms.Size;
    SetLength(S, Len);
    if Len > 0 then Ms.ReadBuffer(S[1], Len);
    // Detect BOM: UTF-8, UTF-16 LE/BE
    if (Len >= 3) and (Byte(S[1])=$EF) and (Byte(S[2])=$BB) and (Byte(S[3])=$BF) then
    begin
      // strip UTF-8 BOM
      Result := Copy(S, 4, MaxInt);
      Exit;
    end
    else if (Len >= 2) and (Byte(S[1])=$FF) and (Byte(S[2])=$FE) then
    begin
      // UTF-16 LE -> convert to UTF-8
      Count := (Len-2) div 2;
      SetLength(WS, Count);
      for I := 0 to Count-1 do
      begin
        loB := Byte(S[3 + I*2]);
        hiB := Byte(S[4 + I*2]);
        WS[I+1] := WideChar(Word(hiB) shl 8 or loB);
      end;
      Result := UTF8Encode(WS);
      Exit;
    end
    else if (Len >= 2) and (Byte(S[1])=$FE) and (Byte(S[2])=$FF) then
    begin
      // UTF-16 BE -> convert to UTF-8
      Count := (Len-2) div 2;
      SetLength(WS, Count);
      for I := 0 to Count-1 do
      begin
        hiB := Byte(S[3 + I*2]);
        loB := Byte(S[4 + I*2]);
        WS[I+1] := WideChar(Word(hiB) shl 8 or loB);
      end;
      Result := UTF8Encode(WS);
      Exit;
    end
    else
    begin
      // Assume UTF-8 without BOM
      Result := S;
    end;
  finally
    Ms.Free;
  end;
end;

function ToFile(const ADoc: IIniDocument; const AFileName: String; const AFlags: TIniWriteFlags): Boolean;
var FS: TFileStream; Bytes: RawByteString;
begin
  Result := False;
  if (ADoc = nil) or (AFileName = '') then Exit(False);
  Bytes := ToIni(ADoc, AFlags);
  FS := TFileStream.Create(AFileName, fmCreate);
  try
    // 可选写入 UTF-8 BOM
    if iwfWriteBOM in AFlags then
    begin
      FS.WriteByte($EF); FS.WriteByte($BB); FS.WriteByte($BF);
    end;
    if Length(Bytes) > 0 then FS.WriteBuffer(Bytes[1], Length(Bytes));
    Result := True;
  finally
    FS.Free;
  end;
end;
function ParseFileEx(const AFileName: String; out ADoc: IIniDocument; out AErr: TIniError; out DetectedEncoding: String; const AFlags: TIniReadFlags): Boolean;
var FS: TFileStream; Ms: TMemoryStream; b0,b1,b2: Byte;
begin
  DetectedEncoding := '';
  Result := False;
  AErr.Clear;
  if (AFileName = '') or (not FileExists(AFileName)) then
  begin
    AErr.Code := iecFileIO; AErr.Message := 'File not found';
    Exit(False);
  end;
  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    Ms := TMemoryStream.Create;
    try
      Ms.CopyFrom(FS, 0);
      Ms.Position := 0;
      if Ms.Size >= 3 then
      begin
        Ms.ReadBuffer(b0, 1); Ms.ReadBuffer(b1, 1); Ms.ReadBuffer(b2, 1);
        if (b0=$EF) and (b1=$BB) and (b2=$BF) then DetectedEncoding := 'UTF-8-BOM'
        else DetectedEncoding := 'UTF-8';
      end
      else if Ms.Size >= 2 then
      begin
        Ms.ReadBuffer(b0,1); Ms.ReadBuffer(b1,1);
        if (b0=$FF) and (b1=$FE) then DetectedEncoding := 'UTF-16LE'
        else if (b0=$FE) and (b1=$FF) then DetectedEncoding := 'UTF-16BE'
        else DetectedEncoding := 'UTF-8';
      end
      else
        DetectedEncoding := 'UTF-8';
    finally
      Ms.Free;
    end;
    FS.Position := 0;
    Result := ParseStream(FS, ADoc, AErr, AFlags);
  finally
    FS.Free;
  end;
end;

function ParseStream(const AStream: TStream; out ADoc: IIniDocument; out AErr: TIniError; const AFlags: TIniReadFlags): Boolean;
var SL: TStringList; Bytes: RawByteString;
begin
  SL := TStringList.Create;
  try
    Bytes := DetectAndLoadAsUTF8(AStream);
    SL.Text := UTF8Decode(Bytes);
    Result := InternalParseFromStrings(SL, ADoc, AErr, AFlags);
  finally
    SL.Free;
  end;
end;

function ParseFile(const AFileName: String; out ADoc: IIniDocument; out AErr: TIniError; const AFlags: TIniReadFlags): Boolean;
var FS: TFileStream;
begin
  Result := False;
  AErr.Clear;
  if (AFileName = '') or (not FileExists(AFileName)) then
  begin
    AErr.Code := iecFileIO;
    AErr.Message := 'File not found';
    AErr.Line := 0; AErr.Column := 0; AErr.Position := 0;
    Exit(False);
  end;
  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    Result := ParseStream(FS, ADoc, AErr, AFlags);
  finally
    FS.Free;
  end;
end;

procedure TIniDocumentImpl.SetString(const ASection, AKey, AValue: String);
var Sec: IIniSectionMutable;
begin
  Sec := EnsureSection(ASection);
  Sec.PutStr(AKey, AValue);
  FDirty := True;
end;

procedure TIniDocumentImpl.SetInt(const ASection, AKey: String; const AValue: Int64);
var Sec: IIniSectionMutable;
begin
  Sec := EnsureSection(ASection);
  Sec.PutInt(AKey, AValue);
  FDirty := True;
end;

procedure TIniDocumentImpl.SetBool(const ASection, AKey: String; const AValue: Boolean);
var Sec: IIniSectionMutable;
begin
  Sec := EnsureSection(ASection);
  Sec.PutBool(AKey, AValue);
  FDirty := True;
end;

procedure TIniDocumentImpl.SetFloat(const ASection, AKey: String; const AValue: Double);
var Sec: IIniSectionMutable;
begin
  Sec := EnsureSection(ASection);
  Sec.PutFloat(AKey, AValue);
  FDirty := True;
end;


// Facade Set* helpers (implementation)
procedure SetString(const ADoc: IIniDocument; const ASection, AKey, AValue: String);
begin
  if ADoc = nil then Exit;
  ADoc.SetString(ASection, AKey, AValue);
end;

procedure SetInt(const ADoc: IIniDocument; const ASection, AKey: String; const AValue: Int64);
begin
  if ADoc = nil then Exit;
  ADoc.SetInt(ASection, AKey, AValue);
end;

procedure SetBool(const ADoc: IIniDocument; const ASection, AKey: String; const AValue: Boolean);
begin
  if ADoc = nil then Exit;
  ADoc.SetBool(ASection, AKey, AValue);
end;

procedure SetFloat(const ADoc: IIniDocument; const ASection, AKey: String; const AValue: Double);
begin
  if ADoc = nil then Exit;
  ADoc.SetFloat(ASection, AKey, AValue);
end;

function ToIni(const ADoc: IIniDocument; const AFlags: TIniWriteFlags): RawByteString;
var
  SB: TStringBuilder;
  I, J: Integer;
  SecName, Key, Val: String;
  Sec: IIniSection;
  Sep: String;
  EOL: String;
  LText: String;
  DocInt: IIniDocumentInternal;
  SecInt: IIniSectionInternal;
  Tmp: TStringList;
  procedure AppendLineEOL(const S: String);
  begin
    SB.Append(S).Append(EOL);
  end;
begin
  // 分隔符策略
  if iwfPreferColon in AFlags then
    Sep := ':'
  else
    Sep := '=';
  if iwfSpacesAroundEquals in AFlags then
    Sep := ' ' + Sep + ' ';

  // 换行策略：生成时确定，避免后处理替换
  if iwfForceLF in AFlags then EOL := #10 else EOL := LineEnding;

  SB := TStringBuilder.Create;
  try
    if Supports(ADoc, IIniDocumentInternal, DocInt) then
    begin
      // 优先从 Entries 原样回放（未脏且存在条目）
      if (not DocInt.IsDirty) and (DocInt.GetEntryCount > 0) then
      begin
        for I := 0 to DocInt.GetEntryCount - 1 do
          AppendLineEOL(DocInt.GetEntryRaw(I));
      end
      else
      begin
        // 文件前导注释与空白
        if DocInt.GetPrelude <> nil then
          for J := 0 to DocInt.GetPrelude.Count - 1 do
            AppendLineEOL(DocInt.GetPrelude[J]);

        // 按顺序写出所有节（包括空名默认节在首位时）
        for I := 0 to ADoc.SectionCount - 1 do
        begin
          SecName := ADoc.SectionNameAt(I);
          if SecName <> '' then
            AppendLineEOL('[' + SecName + ']');
          // 节头部注释
          Sec := ADoc.GetSection(SecName);
          if (Sec <> nil) and Supports(Sec, IIniSectionInternal, SecInt) then
          begin
            if SecInt.GetHeaderPad <> nil then
              for J := 0 to SecInt.GetHeaderPad.Count - 1 do
                AppendLineEOL(SecInt.GetHeaderPad[J]);
            // 如果存在主体回放行，且本节未脏，则严格回放主体原样；否则按键重组（以修改为准）
            if (not SecInt.GetDirty) and (SecInt.GetBodyLines <> nil) and (SecInt.GetBodyLines.Count > 0) then
            begin
              for J := 0 to SecInt.GetBodyLines.Count - 1 do
                AppendLineEOL(SecInt.GetBodyLines[J]);
              Continue;
            end;
          end;

          if Sec <> nil then
          begin
            if iwfStableKeyOrder in AFlags then
            begin
              Tmp := TStringList.Create;
              try
                Tmp.Sorted := True; Tmp.Duplicates := dupIgnore; Tmp.CaseSensitive := False;
                for J := 0 to Sec.KeyCount - 1 do Tmp.Add(Sec.KeyAt(J));
                for J := 0 to Tmp.Count - 1 do
                begin
                  Key := Tmp[J];
                  Sec.TryGetString(Key, Val);
                  if iwfBoolUpperCase in AFlags then
                  begin
                    if SameText(Trim(Val), 'true') then Val := 'TRUE'
                    else if SameText(Trim(Val), 'false') then Val := 'FALSE';
                  end;
                  if (iwfQuoteValuesWhenNeeded in AFlags) or (iwfQuoteSpaces in AFlags) then
                  begin
                    if (iwfQuoteSpaces in AFlags) then
                    begin
                      if (Pos(' ', Val) > 0) or (Pos(#9, Val) > 0) then
                        Val := '"' + Val + '"'
                      else if (iwfQuoteValuesWhenNeeded in AFlags) then
                      begin
                        if (Pos('=', Val) > 0) or (Pos(':', Val) > 0) or (Pos(';', Val) > 0) or (Pos('#', Val) > 0) or
                           ((Length(Val) > 0) and ((Val[1] = ' ') or (Val[Length(Val)] = ' '))) then
                          Val := '"' + Val + '"';
                      end;
                    end
                    else
                    begin
                      if (Pos('=', Val) > 0) or (Pos(':', Val) > 0) or (Pos(';', Val) > 0) or (Pos('#', Val) > 0) or
                         ((Length(Val) > 0) and ((Val[1] = ' ') or (Val[Length(Val)] = ' '))) then
                        Val := '"' + Val + '"';
                    end;
                  end;
                  AppendLineEOL(Key + Sep + Val);
                end;
              finally
                Tmp.Free;
              end;
            end
            else
            begin
              for J := 0 to Sec.KeyCount - 1 do
              begin
                Key := Sec.KeyAt(J);
                Sec.TryGetString(Key, Val);
                // 布尔大小写策略
                if iwfBoolUpperCase in AFlags then
                begin
                  if SameText(Trim(Val), 'true') then Val := 'TRUE'
                  else if SameText(Trim(Val), 'false') then Val := 'FALSE';
                end;
                if (iwfQuoteValuesWhenNeeded in AFlags) or (iwfQuoteSpaces in AFlags) then
                begin
                  if (iwfQuoteSpaces in AFlags) then
                  begin
                    if (Pos(' ', Val) > 0) or (Pos(#9, Val) > 0) then
                      Val := '"' + Val + '"'
                    else if (iwfQuoteValuesWhenNeeded in AFlags) then
                    begin
                      if (Pos('=', Val) > 0) or (Pos(':', Val) > 0) or (Pos(';', Val) > 0) or (Pos('#', Val) > 0) or
                         ((Length(Val) > 0) and ((Val[1] = ' ') or (Val[Length(Val)] = ' '))) then
                        Val := '"' + Val + '"';
                    end;
                  end
                  else
                  begin
                    if (Pos('=', Val) > 0) or (Pos(':', Val) > 0) or (Pos(';', Val) > 0) or (Pos('#', Val) > 0) or
                       ((Length(Val) > 0) and ((Val[1] = ' ') or (Val[Length(Val)] = ' '))) then
                      Val := '"' + Val + '"';
                  end;
                end;
                AppendLineEOL(Key + Sep + Val);
              end;
            end;
          end;
          if (SecName <> '') and (not (iwfNoSectionSpacer in AFlags)) then
            SB.Append(EOL); // 额外空行分隔节（可通过 iwfNoSectionSpacer 禁用）
        end;
      end;
    end
    else
    begin
      // 无内部接口，退回旧逻辑
      // 文件前导注释与空白无法获取，故仅输出各节
      for I := 0 to ADoc.SectionCount - 1 do
      begin
        SecName := ADoc.SectionNameAt(I);
        if SecName <> '' then AppendLineEOL('[' + SecName + ']');
        Sec := ADoc.GetSection(SecName);
        if Sec <> nil then
          for J := 0 to Sec.KeyCount - 1 do
          begin
            Key := Sec.KeyAt(J);
            Sec.TryGetString(Key, Val);
            if (iwfQuoteValuesWhenNeeded in AFlags) or (iwfQuoteSpaces in AFlags) then
            begin
              if (iwfQuoteSpaces in AFlags) then
              begin
                if (Pos(' ', Val) > 0) or (Pos(#9, Val) > 0) then
                  Val := '"' + Val + '"'
                else if (iwfQuoteValuesWhenNeeded in AFlags) then
                begin
                  if (Pos('=', Val) > 0) or (Pos(':', Val) > 0) or (Pos(';', Val) > 0) or (Pos('#', Val) > 0) or
                     ((Length(Val) > 0) and ((Val[1] = ' ') or (Val[Length(Val)] = ' '))) then
                    Val := '"' + Val + '"';
                end;
              end
              else
              begin
                if (Pos('=', Val) > 0) or (Pos(':', Val) > 0) or (Pos(';', Val) > 0) or (Pos('#', Val) > 0) or
                   ((Length(Val) > 0) and ((Val[1] = ' ') or (Val[Length(Val)] = ' '))) then
                  Val := '"' + Val + '"';
              end;
            end;
            AppendLineEOL(Key + Sep + Val);
          end;
        if SecName <> '' then SB.Append(EOL);
      end;
    end;

    LText := SB.ToString;
    // Ensure trailing newline when requested (only for non-empty output)
    if (iwfTrailingNewline in AFlags) then
    begin
      if (Length(LText) > 0) then
      begin
        // Check if LText already ends with EOL; if not, append
        if (Length(LText) < Length(EOL)) or (Copy(LText, Length(LText)-Length(EOL)+1, Length(EOL)) <> EOL) then
          LText := LText + EOL;
      end;
    end;
    {$IFDEF WINDOWS}
    Result := RawByteString(LText);
    {$ELSE}
    Result := UTF8Encode(LText);
    {$ENDIF}
  finally
    SB.Free;
  end;
end;

end.
