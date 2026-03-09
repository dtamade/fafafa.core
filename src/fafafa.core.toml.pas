unit fafafa.core.toml;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}
{$WARN 3124 OFF} // suppress "Inlining disabled" noise in strict 0-hints builds

interface

uses
  SysUtils, Classes;

type
  {**
   * TOML 值类型
   * 参考 TOML v1.0.0 基本类型与容器类型
   *}
  TTomlValueType = (
    tvtString,
    tvtInteger,
    tvtFloat,
    tvtBoolean,
    tvtOffsetDateTime,
    tvtLocalDateTime,
    tvtLocalDate,
    tvtLocalTime,
    tvtArray,
    tvtTable
  );

  {**
   * 解析/序列化 错误代码
   *}
  TTomlErrorCode = (
    tecSuccess,
    tecInvalidParameter,
    tecInvalidToml,
    tecDuplicateKey,
    tecTypeMismatch,
    tecMemory,
    tecFileIO,
    tecLimitExceeded
  );

  {**
   * 错误信息（行列/偏移）
   *}
  TTomlError = record
    Code: TTomlErrorCode;
    Message: String;
    Position: SizeUInt; // 字节偏移
    Line: SizeUInt;     // 行号（从1开始）
    Column: SizeUInt;   // 列号（从1开始）
  public
    procedure Clear; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    function HasError: Boolean; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    function ToString: String;
  end;

  // 前向声明
  ITomlValue = interface;
  ITomlTable = interface;
  ITomlArray = interface;
  ITomlDocument = interface;
  ITomlMutableValue = interface;
  ITomlMutableDocument = interface;

  {**
   * 不可变 TOML 值接口
   * 最小接口面，后续迭代扩展（TryGetXxx 等）
   *}
  ITomlValue = interface
  ['{4E5D7B2F-1D88-4A39-9741-0A59C9AF3B4F}']
    function GetType: TTomlValueType;
    function TryGetString(out AOut: String): Boolean;
    function TryGetInteger(out AOut: Int64): Boolean;
    function TryGetFloat(out AOut: Double): Boolean;
    function TryGetBoolean(out AOut: Boolean): Boolean;
    // 返回日期/时间值的原始无引号文本（当类型为日期/时间族时）
    function TryGetTemporalText(out AOut: String): Boolean;
  end;

  {** 现代接口：Table/Array **}
  ITomlTable = interface(ITomlValue)
  ['{E6A9F1B9-83B2-4A29-B8A1-3C31F3C1C2E1}']
    function Contains(const AKey: String): Boolean;
    function GetValue(const AKey: String): ITomlValue;
    function KeyCount: SizeInt;
    function KeyAt(const AIndex: SizeInt): String;
  end;

  ITomlArray = interface(ITomlValue)
  ['{8B0C2E1D-1E7F-47E0-99B2-5C2E0B3D8A7F}']
    function Count: SizeInt;
    function Item(const AIndex: SizeInt): ITomlValue;
  end;

  ITomlMutableArray = interface(ITomlArray)
  ['{A2F6D8C1-7C3E-4F4A-9C0B-8E2B5C9D1F34}']
    procedure AddItem(const AValue: ITomlValue);
    procedure SetAllowMixed(const AValue: Boolean);
  end;

  { 可变表接口：解析阶段的内部可变操作 }
  ITomlMutableTable = interface(ITomlTable)
  ['{5A9C9B8E-7D52-4F2F-9C57-8D9F1F3A7B21}']
    procedure AddPair(const AKey: String; const AValue: ITomlValue);
  end;

  {**
   * 不可变 TOML 文档
   * Root 为一个 table
   *}
  ITomlDocument = interface
  ['{B3B4E1E1-5D8F-46C2-9A58-7F8B5B7E6A92}']
    function GetRoot: ITomlTable;
    property Root: ITomlTable read GetRoot;
  end;

  {** 可变值接口（占位，后续实现） **}
  ITomlMutableValue = interface(ITomlValue)
  ['{2D3B7C6A-2F47-4B7C-BE2A-17F2E6B1D1C1}']
  end;

  {** 可变文档接口（占位，后续实现） **}
  ITomlMutableDocument = interface(ITomlDocument)
  ['{F2C6B3A9-5A1C-4E3D-9AA4-4B2B8B0E6C3F}']
  end;



  {**
   * 读取/写入选项（保持最小化，后续扩展）
   *}
  TTomlReadFlag = (
    trfDefault,
    trfStopWhenDone,
    trfAllowMixedNewlines,
    trfUseV2,       // kept for backward-compat; default is V2 now
    trfUseV1        // force legacy V1 parser
  );
  TTomlReadFlags = set of TTomlReadFlag;

  TTomlWriteFlag = (
    twfDefault,
    twfPretty,
    twfSortKeys,
    twfSpacesAroundEquals,
    twfTightEquals
  );
  // TODO(nav.Writer.Flags):
  // - twfPretty：控制节段之间的空行（根标量→首个表头也插入空行）
  // - twfSortKeys：标量/AoT/子表各自内部可选字典序，保持段内稳定
  // - twfSpacesAroundEquals：当前与默认等价（key = value），保留未来策略切换
  // - twfTightEquals：切换为紧凑等号（key=value）；若与 Spaces 同时指定，则以 Tight 优先
  TTomlWriteFlags = set of TTomlWriteFlag;

{ 门面函数：对外 API（最小骨架） }
  // 资源限制配置（解析/写出，可选）
  TTomlLimits = record
    MaxInputBytes: SizeUInt;   // 0 表示不限制
    MaxDepth: SizeUInt;        // 嵌套深度上限
    MaxKeys: SizeUInt;         // 键数量上限
    MaxStringBytes: SizeUInt;  // 单个字符串字节上限
  end;

function Parse(const AText: RawByteString; out ADoc: ITomlDocument; out AErr: TTomlError; const AFlags: TTomlReadFlags = []): Boolean; overload;
function ParseFile(const AFileName: String; out ADoc: ITomlDocument; out AErr: TTomlError; const AFlags: TTomlReadFlags = []): Boolean; overload;
function ParseStream(const AStream: TStream; out ADoc: ITomlDocument; out AErr: TTomlError; const AFlags: TTomlReadFlags = []): Boolean; overload;

function ToToml(const ADoc: ITomlDocument; const AFlags: TTomlWriteFlags = []): RawByteString;

{ 流畅构建接口（避免关键词冲突）：Builder }
type
  ITomlBuilder = interface
  ['{8E3F1D8D-7F7B-4A5B-A0C1-1C2B3D4E5F60}']
  function BeginTable(const APath: String): ITomlBuilder;
  function EndTable: ITomlBuilder;
  function PutStr(const AKey, AValue: String): ITomlBuilder;      // 写入当前表下的键
  function PutInt(const AKey: String; const AValue: Int64): ITomlBuilder;
  function PutBool(const AKey: String; const AValue: Boolean): ITomlBuilder;
  function PutFloat(const AKey: String; const AValue: Double): ITomlBuilder;
  function PutAtStr(const APath, AValue: String): ITomlBuilder;   // 按 dotted path 写入
  function PutAtInt(const APath: String; const AValue: Int64): ITomlBuilder;
  function PutAtBool(const APath: String; const AValue: Boolean): ITomlBuilder;
  function PutAtFloat(const APath: String; const AValue: Double): ITomlBuilder;
  // 最小 AoT 构建 API
  // Temporal 写入（使用原始文本与类型）
  function PutTemporalText(const AKey, AText: String; AKind: TTomlValueType): ITomlBuilder;
  function PutAtTemporalText(const APath, AText: String; AKind: TTomlValueType): ITomlBuilder;

  // 标量数组写入（值上下文）
  function PutArrayOfInt(const AKey: String; const Items: array of Int64): ITomlBuilder;
  function PutArrayOfFloat(const AKey: String; const Items: array of Double): ITomlBuilder;
  function PutArrayOfBool(const AKey: String; const Items: array of Boolean): ITomlBuilder;
  function PutArrayOfStr(const AKey: String; const Items: array of String): ITomlBuilder;
  function PutAtArrayOfInt(const APath: String; const Items: array of Int64): ITomlBuilder;
  function PutAtArrayOfFloat(const APath: String; const Items: array of Double): ITomlBuilder;
  function PutAtArrayOfBool(const APath: String; const Items: array of Boolean): ITomlBuilder;
  function PutAtArrayOfStr(const APath: String; const Items: array of String): ITomlBuilder;

  // 工厂：创建数组与简单值
  function NewArray: ITomlMutableArray;
  function NewIntValue(const AValue: Int64): ITomlValue;
  function NewFloatValue(const AValue: Double): ITomlValue;
  function NewBoolValue(const AValue: Boolean): ITomlValue;
  function NewStrValue(const AValue: String): ITomlValue;
  // 一般数组写入（允许嵌套数组）
  function PutArray(const AKey: String; const Arr: ITomlArray): ITomlBuilder;
  function PutAtArray(const APath: String; const Arr: ITomlArray): ITomlBuilder;

  function EnsureArray(const APath: String): ITomlBuilder;         // 确保 path 为数组
  function PushTable(const APath: String): ITomlBuilder;           // 向数组表追加新表，并将上下文切到该表
  function Build: ITomlDocument;
  function SaveToFile(const AFileName: String; const AFlags: TTomlWriteFlags = []): Boolean;
end;

{ Fluent Builder 入口与便捷读取 API }
function ParseWithLimits(const AText: RawByteString; const ALimits: TTomlLimits; out ADoc: ITomlDocument; out AErr: TTomlError; const AFlags: TTomlReadFlags = []): Boolean; overload;
function NewDoc: ITomlBuilder;
function GetString(const ADoc: ITomlDocument; const APath, ADefault: String): String;
function GetInt(const ADoc: ITomlDocument; const APath: String; const ADefault: Int64): Int64;
function GetBool(const ADoc: ITomlDocument; const APath: String; const ADefault: Boolean): Boolean;
function TryGetString(const ADoc: ITomlDocument; const APath: String; out AValue: String): Boolean;
function TryGetInt(const ADoc: ITomlDocument; const APath: String; out AValue: Int64): Boolean;
function TryGetBool(const ADoc: ITomlDocument; const APath: String; out AValue: Boolean): Boolean;


{ 通用路径存在性与取值 API }
function Has(const ADoc: ITomlDocument; const APath: String): Boolean;
function TryGetValue(const ADoc: ITomlDocument; const APath: String; out AValue: ITomlValue): Boolean;
implementation

uses
  fafafa.core.toml.parser.v2;

procedure SetErrorAtStart(var AOutErr: TTomlError; const ACode: TTomlErrorCode; const AMsg: String);
begin
  AOutErr.Code := ACode;
  AOutErr.Message := AMsg;
  AOutErr.Position := 0;
  AOutErr.Line := 1;
  AOutErr.Column := 1;
end;

type
  TTomlBuilderImpl = class(TInterfacedObject, ITomlBuilder)
  private
    FDoc: ITomlMutableTable;
    FStack: array of ITomlMutableTable;
  public
    constructor Create;
    function BeginTable(const APath: String): ITomlBuilder;
    function EndTable: ITomlBuilder;
    function PutStr(const AKey, AValue: String): ITomlBuilder;
    function PutInt(const AKey: String; const AValue: Int64): ITomlBuilder;
    function PutBool(const AKey: String; const AValue: Boolean): ITomlBuilder;
    function PutFloat(const AKey: String; const AValue: Double): ITomlBuilder;
    function PutAtStr(const APath, AValue: String): ITomlBuilder;
    function PutAtInt(const APath: String; const AValue: Int64): ITomlBuilder;
    function PutAtBool(const APath: String; const AValue: Boolean): ITomlBuilder;
    function PutAtFloat(const APath: String; const AValue: Double): ITomlBuilder;
    function PutTemporalText(const AKey, AText: String; AKind: TTomlValueType): ITomlBuilder;
    function PutAtTemporalText(const APath, AText: String; AKind: TTomlValueType): ITomlBuilder;
    function PutArrayOfInt(const AKey: String; const Items: array of Int64): ITomlBuilder;
    function PutArrayOfFloat(const AKey: String; const Items: array of Double): ITomlBuilder;
    function PutArrayOfBool(const AKey: String; const Items: array of Boolean): ITomlBuilder;
    function PutArrayOfStr(const AKey: String; const Items: array of String): ITomlBuilder;
    function PutAtArrayOfInt(const APath: String; const Items: array of Int64): ITomlBuilder;
    function PutAtArrayOfFloat(const APath: String; const Items: array of Double): ITomlBuilder;
    function PutAtArrayOfBool(const APath: String; const Items: array of Boolean): ITomlBuilder;
    function PutAtArrayOfStr(const APath: String; const Items: array of String): ITomlBuilder;
    function NewArray: ITomlMutableArray;
    function NewIntValue(const AValue: Int64): ITomlValue;
    function NewFloatValue(const AValue: Double): ITomlValue;
    function NewBoolValue(const AValue: Boolean): ITomlValue;
    function NewStrValue(const AValue: String): ITomlValue;
    function PutArray(const AKey: String; const Arr: ITomlArray): ITomlBuilder;
    function PutAtArray(const APath: String; const Arr: ITomlArray): ITomlBuilder;
    function EnsureArray(const APath: String): ITomlBuilder;
    function PushTable(const APath: String): ITomlBuilder;
    function Build: ITomlDocument;
    function SaveToFile(const AFileName: String; const AFlags: TTomlWriteFlags = []): Boolean;
  end;

function NewDoc: ITomlBuilder;
begin
  Result := TTomlBuilderImpl.Create;
end;


{ 内部最小实现：仅确保可编译，后续按 TDD 迭代 }

type
  TTomlSimpleValue = class(TInterfacedObject, ITomlValue)
  private
    FType: TTomlValueType;
    FString: String;
    FInt: Int64;
    FFloat: Double;
    FBool: Boolean;
    FTemporalText: String; // 用于存储日期/时间类的原始文本表示
  public
    constructor CreateString(const AValue: String);
    constructor CreateInteger(const AValue: Int64);
    constructor CreateFloat(const AValue: Double);
    constructor CreateBoolean(const AValue: Boolean);
    constructor CreateTemporal(const AKind: TTomlValueType; const AText: String);
    function GetType: TTomlValueType;
    function TryGetString(out AOut: String): Boolean;
    function TryGetInteger(out AOut: Int64): Boolean;
    function TryGetFloat(out AOut: Double): Boolean;
    function TryGetBoolean(out AOut: Boolean): Boolean;
    function TryGetTemporalText(out AOut: String): Boolean;
  end;

  TTomlSimpleTable = class(TInterfacedObject, ITomlMutableTable, ITomlTable, ITomlValue)
  private
    FKeys: array of String;        // 简易键数组（保持插入顺序）
    FValues: array of ITomlValue;  // 与键对应的值
    FBuckets: array of SizeInt;    // 开放定址哈希桶，存放索引（-1 空）
    FMask: SizeInt;                // 桶容量-1（容量为2幂）
    function HashOf(const AKey: String): SizeUInt; inline;
    procedure EnsureCapacity;
    procedure Rehash(ANewCapPow2: SizeInt);
    function IndexOf(const AKey: String): SizeInt;


  public
    // ITomlValue
    function GetType: TTomlValueType;
    function TryGetString(out AOut: String): Boolean;
    function TryGetInteger(out AOut: Int64): Boolean;
    function TryGetFloat(out AOut: Double): Boolean;
    function TryGetBoolean(out AOut: Boolean): Boolean;
    function TryGetTemporalText(out AOut: String): Boolean;
    // ITomlMutableTable / ITomlTable
    procedure AddPair(const AKey: String; const AValue: ITomlValue);
    function Contains(const AKey: String): Boolean;
    function GetValue(const AKey: String): ITomlValue;
    function KeyCount: SizeInt;
    function KeyAt(const AIndex: SizeInt): String;
    function GetItem(const AKey: String): ITomlValue;
  end;

  TTomlSimpleArray = class(TInterfacedObject, ITomlMutableArray, ITomlArray, ITomlValue)
  private
    FItems: array of ITomlValue;
    FKindInitialized: Boolean;
    FKind: TTomlValueType;
    FAllowMixed: Boolean;
  public
    constructor Create; reintroduce;
    procedure SetAllowMixed(const AValue: Boolean);
    // ITomlValue
    function GetType: TTomlValueType;
    function TryGetString(out AOut: String): Boolean;
    function TryGetInteger(out AOut: Int64): Boolean;
    function TryGetFloat(out AOut: Double): Boolean;
    function TryGetBoolean(out AOut: Boolean): Boolean;
    function TryGetTemporalText(out AOut: String): Boolean;
    // ITomlArray
    function Count: SizeInt;
    function Item(const AIndex: SizeInt): ITomlValue;
    // ITomlMutableArray
    procedure AddItem(const AValue: ITomlValue);
  end;

  TTomlSimpleDocument = class(TInterfacedObject, ITomlDocument)
  private
    FRoot: ITomlTable; // Root Table
  public
    constructor Create; overload;
    constructor CreateWithRoot(const ARoot: ITomlTable); overload;
    function GetRoot: ITomlTable;
  end;

{ TTomlError }
procedure TTomlError.Clear;
begin
  Code := tecSuccess;
  Message := '';
  Position := 0;
  Line := 0;
  Column := 0;
end;

function TTomlError.HasError: Boolean;
begin
  Result := Code <> tecSuccess;
end;
{ TTomlSimpleArray }
function TTomlSimpleArray.GetType: TTomlValueType; begin Result := tvtArray; end;
function TTomlSimpleArray.TryGetString(out AOut: String): Boolean; begin AOut:=''; Exit(False); end;
function TTomlSimpleArray.TryGetInteger(out AOut: Int64): Boolean; begin AOut:=0; Exit(False); end;
function TTomlSimpleArray.TryGetFloat(out AOut: Double): Boolean; begin AOut:=0.0; Exit(False); end;
function TTomlSimpleArray.TryGetBoolean(out AOut: Boolean): Boolean; begin AOut:=False; Exit(False); end;
function TTomlSimpleArray.TryGetTemporalText(out AOut: String): Boolean; begin AOut:=''; Exit(False); end;
function TTomlSimpleArray.Count: SizeInt; begin Result := Length(FItems); end;
function TTomlSimpleArray.Item(const AIndex: SizeInt): ITomlValue; begin Result := FItems[AIndex]; end;
procedure TTomlSimpleArray.AddItem(const AValue: ITomlValue);
var N: SizeInt; K: TTomlValueType;
begin
  if AValue = nil then Exit;
  K := AValue.GetType;
  if not FKindInitialized then
  begin
    FKindInitialized := True;
    FKind := K;
  end
  else if (K <> FKind) and (not FAllowMixed) then
  begin
    // 数组同构约束：默认强制同构；当允许混合时跳过
    raise Exception.Create('Array type mismatch');
  end;
  N := Length(FItems);
  SetLength(FItems, N+1);

  FItems[N] := AValue;
end;

constructor TTomlSimpleArray.Create;
begin
  inherited Create;
  FAllowMixed := False;
  FKindInitialized := False;
  SetLength(FItems, 0);
end;

procedure TTomlSimpleArray.SetAllowMixed(const AValue: Boolean);
begin
  FAllowMixed := AValue;
end;




function TTomlError.ToString: String;
begin
  if not HasError then
    Exit('OK');
  Result := Format('Error(%d) %s at L%u C%u (pos %u)', [Ord(Code), Message, Line, Column, Position]);
end;

{ TTomlSimpleValue }
constructor TTomlSimpleValue.CreateString(const AValue: String);
begin
  inherited Create;
  FType := tvtString;
  FString := AValue;
end;

constructor TTomlSimpleValue.CreateInteger(const AValue: Int64);
begin
  inherited Create;
  FType := tvtInteger;
  FInt := AValue;
end;

constructor TTomlSimpleValue.CreateFloat(const AValue: Double);
begin
  inherited Create;
  FType := tvtFloat;
  FFloat := AValue;
end;

constructor TTomlSimpleValue.CreateBoolean(const AValue: Boolean);
begin
  inherited Create;
  FType := tvtBoolean;
  FBool := AValue;
end;

constructor TTomlSimpleValue.CreateTemporal(const AKind: TTomlValueType; const AText: String);
begin
  inherited Create;
  case AKind of
    tvtOffsetDateTime, tvtLocalDateTime, tvtLocalDate, tvtLocalTime:
      begin
        FType := AKind;
        FTemporalText := AText;
      end
  else
    raise Exception.Create('Invalid temporal kind');
  end;
end;

function TTomlSimpleValue.GetType: TTomlValueType;
begin
  Result := FType;
end;

function TTomlSimpleValue.TryGetString(out AOut: String): Boolean;
begin
  Result := FType = tvtString;
  if Result then AOut := FString;
end;

function TTomlSimpleValue.TryGetInteger(out AOut: Int64): Boolean;
begin
  Result := FType = tvtInteger;
  if Result then AOut := FInt;
end;

function TTomlSimpleValue.TryGetFloat(out AOut: Double): Boolean;
begin
  Result := FType = tvtFloat;
  if Result then AOut := FFloat;
end;

function TTomlSimpleValue.TryGetBoolean(out AOut: Boolean): Boolean;
begin
  Result := FType = tvtBoolean;
  if Result then AOut := FBool;
end;

function TTomlSimpleValue.TryGetTemporalText(out AOut: String): Boolean;
begin
  case FType of
    tvtOffsetDateTime, tvtLocalDateTime, tvtLocalDate, tvtLocalTime:
      begin AOut := FTemporalText; Exit(True); end;
  else
    AOut := ''; Exit(False);
  end;
end;

function TTomlSimpleTable.TryGetTemporalText(out AOut: String): Boolean;
begin
  AOut := '';
  Exit(False);
end;


// ITomlValue for TTomlSimpleTable
function TTomlSimpleTable.GetType: TTomlValueType; begin Result := tvtTable; end;
function TTomlSimpleTable.TryGetString(out AOut: String): Boolean; begin AOut:=''; Exit(False); end;
function TTomlSimpleTable.TryGetInteger(out AOut: Int64): Boolean; begin AOut:=0; Exit(False); end;
function TTomlSimpleTable.TryGetFloat(out AOut: Double): Boolean; begin AOut:=0.0; Exit(False); end;
function TTomlSimpleTable.TryGetBoolean(out AOut: Boolean): Boolean; begin AOut:=False; Exit(False); end;



{ TTomlSimpleTable }

function TTomlSimpleTable.HashOf(const AKey: String): SizeUInt;
var
  I: SizeInt;
  H: SizeUInt;
begin
  // 简单高性能哈希（FNV-1a 变体）
  H := 2166136261;
  for I := 1 to Length(AKey) do
  begin
    H := H xor Ord(AKey[I]);
    H := H * 16777619;
  end;
  Result := H;
end;

procedure TTomlSimpleTable.EnsureCapacity;
var
  LCount, LCap: SizeInt;
begin
  LCount := Length(FKeys);
  LCap := Length(FBuckets);
  if (LCap = 0) then
    Rehash(8)
  else if (LCount * 2 >= LCap) then
    Rehash(LCap * 2);
end;

procedure TTomlSimpleTable.Rehash(ANewCapPow2: SizeInt);
var
  I, LPos: SizeInt;
  H: SizeUInt;
  LNewMask: SizeInt;
  LNewBuckets: array of SizeInt;
begin
  // 使容量为 2 的幂
  LNewMask := 1;
  while LNewMask < ANewCapPow2 do LNewMask := LNewMask shl 1;
  Dec(LNewMask);
  LNewBuckets := nil;
  SetLength(LNewBuckets, LNewMask + 1);
  for I := 0 to High(LNewBuckets) do LNewBuckets[I] := -1;

  // 重新插入现有键
  for I := 0 to High(FKeys) do
  begin
    H := HashOf(FKeys[I]);
    LPos := H and LNewMask;
    while LNewBuckets[LPos] <> -1 do
      LPos := (LPos + 1) and LNewMask;
    LNewBuckets[LPos] := I;
  end;

  FBuckets := LNewBuckets;
  FMask := LNewMask;
end;

function TTomlSimpleTable.Contains(const AKey: String): Boolean;
var
  H: SizeUInt;
  LPos, LIdx: SizeInt;
  I: SizeInt;
begin
  if Length(FBuckets) = 0 then
  begin
    for I := 0 to High(FKeys) do
      if (FKeys[I] = AKey) then Exit(True);
    Exit(False);
  end;
  H := HashOf(AKey);
  LPos := H and FMask;
  while True do
  begin
    LIdx := FBuckets[LPos];
    if LIdx = -1 then Break;
    if (FKeys[LIdx] = AKey) then Exit(True);
    LPos := (LPos + 1) and FMask;
  end;
  // 兜底线性扫描，防止极端情况下哈希未命中
  for I := 0 to High(FKeys) do
    if (FKeys[I] = AKey) then Exit(True);
  Result := False;
end;

function TTomlSimpleTable.GetValue(const AKey: String): ITomlValue;
var
  H: SizeUInt;
  LPos, LIdx: SizeInt;
  I: SizeInt;
begin
  Result := nil;
  if Length(FBuckets) = 0 then
  begin
    for I := 0 to High(FKeys) do
      if (FKeys[I] = AKey) then Exit(FValues[I]);
    Exit(nil);
  end;
  H := HashOf(AKey);
  LPos := H and FMask;
  while True do
  begin
    LIdx := FBuckets[LPos];
    if LIdx = -1 then Break;
    if (FKeys[LIdx] = AKey) then Exit(FValues[LIdx]);
    LPos := (LPos + 1) and FMask;
  end;
  // 兜底线性扫描
  for I := 0 to High(FKeys) do
    if (FKeys[I] = AKey) then Exit(FValues[I]);
  Result := nil;
end;

function TTomlSimpleTable.KeyCount: SizeInt;
begin
  Result := Length(FKeys);
end;

function TTomlSimpleTable.KeyAt(const AIndex: SizeInt): String;
begin
  if (AIndex < 0) or (AIndex >= Length(FKeys)) then
    Exit('');
  Result := FKeys[AIndex];
end;

function TTomlSimpleTable.GetItem(const AKey: String): ITomlValue;
begin
  Result := GetValue(AKey);
end;

{ TTomlSimpleDocument }
constructor TTomlSimpleDocument.Create;
begin
  inherited Create;
  FRoot := TTomlSimpleTable.Create as ITomlTable;
end;

constructor TTomlSimpleDocument.CreateWithRoot(const ARoot: ITomlTable);
begin
  inherited Create;
  FRoot := ARoot;
end;

function TTomlSimpleDocument.GetRoot: ITomlTable;
begin
  Result := FRoot;
end;

procedure TTomlSimpleTable.AddPair(const AKey: String; const AValue: ITomlValue);
var
  LLen, LPos, LIdx: SizeInt;
  H: SizeUInt;
begin
  // 若已存在相同键：保持插入顺序不变，仅替换值，避免重复键污染桶
  LIdx := IndexOf(AKey);
  if LIdx >= 0 then
  begin
    FValues[LIdx] := AValue;
    Exit;
  end;

  EnsureCapacity;
  LLen := Length(FKeys);
  SetLength(FKeys, LLen + 1);
  SetLength(FValues, LLen + 1);
  FKeys[LLen] := AKey;
  FValues[LLen] := AValue;

  // 写入哈希桶
  H := HashOf(AKey);
  LPos := H and FMask;
  while FBuckets[LPos] <> -1 do
    LPos := (LPos + 1) and FMask;
  FBuckets[LPos] := LLen;
  {$IFDEF DEBUG}
  // WriteLn('DEBUG AddPair self=', PtrUInt(Self), ' key=', AKey);
  {$ENDIF}
end;

function TTomlSimpleTable.IndexOf(const AKey: String): SizeInt;
var
  H: SizeUInt;
  LPos: SizeInt;
begin
  if Length(FBuckets) = 0 then Exit(-1);
  H := HashOf(AKey);
  LPos := H and FMask;
  while True do
  begin
    Result := FBuckets[LPos];
    if Result = -1 then Exit(-1);
    if (FKeys[Result] = AKey) then Exit;
    LPos := (LPos + 1) and FMask;
  end;
end;
{ TTomlBuilderImpl }
constructor TTomlBuilderImpl.Create;
begin
  inherited Create;
  FDoc := TTomlSimpleTable.Create as ITomlMutableTable;
  SetLength(FStack, 1);
  FStack[0] := FDoc;
end;

function TTomlBuilderImpl.BeginTable(const APath: String): ITomlBuilder;
var
  Curr: ITomlMutableTable;
  Seg: String;
  P, PEnd: PChar;
  V0, V1, LT, LT1: ITomlValue;
  A0, A1: ITomlArray;
  MA, MA1: ITomlMutableArray;
  NT, NT1: ITomlMutableTable;
begin
  // Always resolve from root to avoid accidental relative context
  Curr := FDoc;
  if APath = '' then
  begin
    SetLength(FStack, Length(FStack)+1);
    FStack[High(FStack)] := Curr;
    Exit(Self);
  end;
  P := PChar(APath); PEnd := P + Length(APath); Seg := '';
  while P < PEnd do
  begin
    if P^ = '.' then
    begin
      if Seg <> '' then
      begin
        V0 := Curr.GetValue(Seg);
        if V0 = nil then begin Curr.AddPair(Seg, TTomlSimpleTable.Create as ITomlValue); V0 := Curr.GetValue(Seg); end;
        if (V0.GetType = tvtTable) then Curr := (V0 as ITomlMutableTable)
        else if (V0.GetType = tvtArray) then
        begin
          // 若为数组表，则进入最后一个表项
          A0 := (V0 as ITomlArray);
          if A0.Count > 0 then
          begin
            LT := A0.Item(A0.Count-1);
            if (LT <> nil) and (LT.GetType = tvtTable) then Curr := (LT as ITomlMutableTable)
            else raise Exception.Create('Invalid AoT element type');
          end
          else
          begin
            // 空数组则创建一个新表项并下钻
            MA := (V0 as ITomlMutableArray);
            NT := TTomlSimpleTable.Create as ITomlMutableTable;
            MA.AddItem(NT as ITomlValue);
            Curr := NT;
          end;
        end
        else
          raise Exception.Create('Path segment is not a table nor AoT');
        Seg := '';
      end;
      Inc(P);
      Continue;
    end;
    Seg := Seg + P^; Inc(P);
  end;
  if Seg <> '' then
  begin
    V1 := Curr.GetValue(Seg);
    if V1 = nil then begin Curr.AddPair(Seg, TTomlSimpleTable.Create as ITomlValue); V1 := Curr.GetValue(Seg); end;
    if (V1.GetType = tvtTable) then Curr := (V1 as ITomlMutableTable)
    else if (V1.GetType = tvtArray) then
    begin
      A1 := (V1 as ITomlArray);
      if A1.Count > 0 then
      begin
        LT1 := A1.Item(A1.Count-1);
        if (LT1 <> nil) and (LT1.GetType = tvtTable) then Curr := (LT1 as ITomlMutableTable)
        else raise Exception.Create('Invalid AoT element type');
      end
      else
      begin
        MA1 := (V1 as ITomlMutableArray);
        NT1 := TTomlSimpleTable.Create as ITomlMutableTable;
        MA1.AddItem(NT1 as ITomlValue);
        Curr := NT1;
      end;
    end
    else
      raise Exception.Create('Path segment is not a table nor AoT');
  end;
  SetLength(FStack, Length(FStack)+1);
  FStack[High(FStack)] := Curr;
  Result := Self;
end;

function TTomlBuilderImpl.EndTable: ITomlBuilder;
begin
  if Length(FStack) > 1 then SetLength(FStack, Length(FStack)-1);
  Result := Self;
end;

function TTomlBuilderImpl.PutStr(const AKey, AValue: String): ITomlBuilder;
var Curr: ITomlMutableTable;
begin
  Curr := FStack[High(FStack)];
  Curr.AddPair(AKey, TTomlSimpleValue.CreateString(AValue) as ITomlValue);
  Result := Self;
end;

function TTomlBuilderImpl.PutInt(const AKey: String; const AValue: Int64): ITomlBuilder;
var Curr: ITomlMutableTable;
begin
  Curr := FStack[High(FStack)];
  Curr.AddPair(AKey, TTomlSimpleValue.CreateInteger(AValue) as ITomlValue);
  Result := Self;
end;

function TTomlBuilderImpl.PutBool(const AKey: String; const AValue: Boolean): ITomlBuilder;
var Curr: ITomlMutableTable;
begin
  Curr := FStack[High(FStack)];
  Curr.AddPair(AKey, TTomlSimpleValue.CreateBoolean(AValue) as ITomlValue);
  Result := Self;
end;

function TTomlBuilderImpl.PutFloat(const AKey: String; const AValue: Double): ITomlBuilder;
var Curr: ITomlMutableTable;
begin
  Curr := FStack[High(FStack)];
  Curr.AddPair(AKey, TTomlSimpleValue.CreateFloat(AValue) as ITomlValue);
  Result := Self;
end;

function TTomlBuilderImpl.PutAtStr(const APath, AValue: String): ITomlBuilder;
var idx: SizeInt; TablePath, Key: String;
begin
  idx := LastDelimiter('.', APath);
  if idx > 0 then begin TablePath := Copy(APath, 1, idx-1); Key := Copy(APath, idx+1, MaxInt); end
  else begin TablePath := ''; Key := APath; end;
  BeginTable(TablePath);
  PutStr(Key, AValue);
  EndTable;
  Result := Self;
end;

function TTomlBuilderImpl.PutAtInt(const APath: String; const AValue: Int64): ITomlBuilder;
var idx: SizeInt; TablePath, Key: String;
begin
  idx := LastDelimiter('.', APath);
  if idx > 0 then begin TablePath := Copy(APath, 1, idx-1); Key := Copy(APath, idx+1, MaxInt); end
  else begin TablePath := ''; Key := APath; end;
  BeginTable(TablePath);
  PutInt(Key, AValue);
  EndTable;
  Result := Self;
end;

function TTomlBuilderImpl.PutAtBool(const APath: String; const AValue: Boolean): ITomlBuilder;
var idx: SizeInt; TablePath, Key: String;
begin
  idx := LastDelimiter('.', APath);
  if idx > 0 then begin TablePath := Copy(APath, 1, idx-1); Key := Copy(APath, idx+1, MaxInt); end
  else begin TablePath := ''; Key := APath; end;
  BeginTable(TablePath);
  PutBool(Key, AValue);
  EndTable;
  Result := Self;
end;

function TTomlBuilderImpl.PutAtFloat(const APath: String; const AValue: Double): ITomlBuilder;
var idx: SizeInt; TablePath, Key: String;
begin
  idx := LastDelimiter('.', APath);
  if idx > 0 then begin TablePath := Copy(APath, 1, idx-1); Key := Copy(APath, idx+1, MaxInt); end
  else begin TablePath := ''; Key := APath; end;
  BeginTable(TablePath);
  PutFloat(Key, AValue);
  EndTable;
  Result := Self;
end;

function TTomlBuilderImpl.PutTemporalText(const AKey, AText: String; AKind: TTomlValueType): ITomlBuilder;
var Curr: ITomlMutableTable; V: ITomlValue;
begin
  Curr := FStack[High(FStack)];
  V := TTomlSimpleValue.CreateTemporal(AKind, AText) as ITomlValue;
  Curr.AddPair(AKey, V);
  Result := Self;
end;

function TTomlBuilderImpl.PutArrayOfInt(const AKey: String; const Items: array of Int64): ITomlBuilder;
var Curr: ITomlMutableTable; Arr: ITomlMutableArray; i: SizeInt;
begin
  Curr := FStack[High(FStack)]; Arr := TTomlSimpleArray.Create as ITomlMutableArray;
  for i := Low(Items) to High(Items) do Arr.AddItem(TTomlSimpleValue.CreateInteger(Items[i]) as ITomlValue);
  Curr.AddPair(AKey, Arr as ITomlValue);
  Result := Self;
end;

function TTomlBuilderImpl.PutArrayOfFloat(const AKey: String; const Items: array of Double): ITomlBuilder;
var Curr: ITomlMutableTable; Arr: ITomlMutableArray; i: SizeInt;
begin
  Curr := FStack[High(FStack)]; Arr := TTomlSimpleArray.Create as ITomlMutableArray;
  for i := Low(Items) to High(Items) do Arr.AddItem(TTomlSimpleValue.CreateFloat(Items[i]) as ITomlValue);
  Curr.AddPair(AKey, Arr as ITomlValue);
  Result := Self;
end;

function TTomlBuilderImpl.PutArrayOfBool(const AKey: String; const Items: array of Boolean): ITomlBuilder;
var Curr: ITomlMutableTable; Arr: ITomlMutableArray; i: SizeInt;
begin
  Curr := FStack[High(FStack)]; Arr := TTomlSimpleArray.Create as ITomlMutableArray;
  for i := Low(Items) to High(Items) do Arr.AddItem(TTomlSimpleValue.CreateBoolean(Items[i]) as ITomlValue);
  Curr.AddPair(AKey, Arr as ITomlValue);
  Result := Self;
end;

function TTomlBuilderImpl.PutArrayOfStr(const AKey: String; const Items: array of String): ITomlBuilder;
var Curr: ITomlMutableTable; Arr: ITomlMutableArray; i: SizeInt;
begin
  Curr := FStack[High(FStack)]; Arr := TTomlSimpleArray.Create as ITomlMutableArray;
  for i := Low(Items) to High(Items) do Arr.AddItem(TTomlSimpleValue.CreateString(Items[i]) as ITomlValue);
  Curr.AddPair(AKey, Arr as ITomlValue);
  Result := Self;
end;

function TTomlBuilderImpl.PutAtArrayOfInt(const APath: String; const Items: array of Int64): ITomlBuilder;
var idx: SizeInt; TablePath, Key: String; i: SizeInt;
begin
  idx := LastDelimiter('.', APath);
  if idx > 0 then begin TablePath := Copy(APath, 1, idx-1); Key := Copy(APath, idx+1, MaxInt); end
  else begin TablePath := ''; Key := APath; end;
  BeginTable(TablePath);
  Result := PutArrayOfInt(Key, Items);
  EndTable;
end;

function TTomlBuilderImpl.PutAtArrayOfFloat(const APath: String; const Items: array of Double): ITomlBuilder;
var idx: SizeInt; TablePath, Key: String;
begin
  idx := LastDelimiter('.', APath);
  if idx > 0 then begin TablePath := Copy(APath, 1, idx-1); Key := Copy(APath, idx+1, MaxInt); end
  else begin TablePath := ''; Key := APath; end;
  BeginTable(TablePath);
  Result := PutArrayOfFloat(Key, Items);
  EndTable;
end;

function TTomlBuilderImpl.PutAtArrayOfBool(const APath: String; const Items: array of Boolean): ITomlBuilder;
var idx: SizeInt; TablePath, Key: String;
begin
  idx := LastDelimiter('.', APath);
  if idx > 0 then begin TablePath := Copy(APath, 1, idx-1); Key := Copy(APath, idx+1, MaxInt); end
  else begin TablePath := ''; Key := APath; end;
  BeginTable(TablePath);
  Result := PutArrayOfBool(Key, Items);
  EndTable;
end;

function TTomlBuilderImpl.NewArray: ITomlMutableArray;
begin
  Result := TTomlSimpleArray.Create as ITomlMutableArray;
end;

function TTomlBuilderImpl.NewIntValue(const AValue: Int64): ITomlValue;
begin
  Result := TTomlSimpleValue.CreateInteger(AValue) as ITomlValue;
end;

function TTomlBuilderImpl.NewFloatValue(const AValue: Double): ITomlValue;
begin
  Result := TTomlSimpleValue.CreateFloat(AValue) as ITomlValue;
end;

function TTomlBuilderImpl.NewBoolValue(const AValue: Boolean): ITomlValue;
begin
  Result := TTomlSimpleValue.CreateBoolean(AValue) as ITomlValue;
end;

function TTomlBuilderImpl.NewStrValue(const AValue: String): ITomlValue;
begin
  Result := TTomlSimpleValue.CreateString(AValue) as ITomlValue;
end;

function TTomlBuilderImpl.PutArray(const AKey: String; const Arr: ITomlArray): ITomlBuilder;
var Curr: ITomlMutableTable;
begin
  Curr := FStack[High(FStack)];
  Curr.AddPair(AKey, Arr as ITomlValue);
  Result := Self;
end;

function TTomlBuilderImpl.PutAtArray(const APath: String; const Arr: ITomlArray): ITomlBuilder;
var idx: SizeInt; TablePath, Key: String;
begin
  idx := LastDelimiter('.', APath);
  if idx > 0 then begin TablePath := Copy(APath, 1, idx-1); Key := Copy(APath, idx+1, MaxInt); end
  else begin TablePath := ''; Key := APath; end;
  BeginTable(TablePath);
  Result := PutArray(Key, Arr);
  EndTable;
end;

function TTomlBuilderImpl.PutAtArrayOfStr(const APath: String; const Items: array of String): ITomlBuilder;
var idx: SizeInt; TablePath, Key: String;
begin
  idx := LastDelimiter('.', APath);
  if idx > 0 then begin TablePath := Copy(APath, 1, idx-1); Key := Copy(APath, idx+1, MaxInt); end
  else begin TablePath := ''; Key := APath; end;
  BeginTable(TablePath);
  Result := PutArrayOfStr(Key, Items);
  EndTable;
end;

function TTomlBuilderImpl.PutAtTemporalText(const APath, AText: String; AKind: TTomlValueType): ITomlBuilder;
var idx: SizeInt; TablePath, Key: String;
begin
  idx := LastDelimiter('.', APath);
  if idx > 0 then begin TablePath := Copy(APath, 1, idx-1); Key := Copy(APath, idx+1, MaxInt); end
  else begin TablePath := ''; Key := APath; end;
  BeginTable(TablePath);
  PutTemporalText(Key, AText, AKind);
  EndTable;
  Result := Self;
end;

function TTomlBuilderImpl.EnsureArray(const APath: String): ITomlBuilder;
var
  Curr: ITomlMutableTable;
  P, PEnd: PChar;
  Seg: String;
  V: ITomlValue;
  Arr: ITomlMutableArray;
begin
  // 下钻到父表
  // Always resolve from root for absolute path operations
  Curr := FDoc;
  if APath = '' then Exit(Self);
  P := PChar(APath); PEnd := P + Length(APath); Seg := '';
  // 收集最后一个段作为数组名
  while (P < PEnd) and (P^ <> '.') do begin Seg := Seg + P^; Inc(P); end;
  while (P < PEnd) do
  begin
    V := Curr.GetValue(Seg);
    if (V = nil) then begin Curr.AddPair(Seg, TTomlSimpleTable.Create as ITomlValue); V := Curr.GetValue(Seg); end;
    if (V.GetType <> tvtTable) then Exit(Self);
    Curr := (V as ITomlMutableTable);
    Inc(P); Seg := '';
    while (P < PEnd) and (P^ <> '.') do begin Seg := Seg + P^; Inc(P); end;
  end;
  // 最后一个段：确保为数组
  V := Curr.GetValue(Seg);
  if (V = nil) then begin Arr := TTomlSimpleArray.Create as ITomlMutableArray; Curr.AddPair(Seg, Arr as ITomlValue); end
  else if (V.GetType = tvtArray) then Exit(Self)
  else Exit(Self);
  Result := Self;
end;

function TTomlBuilderImpl.PushTable(const APath: String): ITomlBuilder;
var
  Curr: ITomlMutableTable;
  P, PEnd: PChar; Seg: String; V: ITomlValue; Arr: ITomlMutableArray; NewT: ITomlMutableTable;
begin
  // Always start from root to append into array-of-tables at absolute path
  Curr := FDoc;
  if APath = '' then Exit(Self);
  // 遍历到父表
  P := PChar(APath); PEnd := P + Length(APath); Seg := '';
  while (P < PEnd) and (P^ <> '.') do begin Seg := Seg + P^; Inc(P); end;
  while (P < PEnd) do
  begin
    V := Curr.GetValue(Seg);
    if (V = nil) then begin Curr.AddPair(Seg, TTomlSimpleTable.Create as ITomlValue); V := Curr.GetValue(Seg); end;
    if (V.GetType <> tvtTable) then Exit(Self);
    Curr := (V as ITomlMutableTable);
    Inc(P); Seg := '';
    while (P < PEnd) and (P^ <> '.') do begin Seg := Seg + P^; Inc(P); end;
  end;
  // 最后段为数组名：确保数组并追加一个表项
  V := Curr.GetValue(Seg);

  if (V = nil) then begin Arr := TTomlSimpleArray.Create as ITomlMutableArray; Curr.AddPair(Seg, Arr as ITomlValue); end
  else if (V.GetType <> tvtArray) then Exit(Self)
  else Arr := (V as ITomlMutableArray);
  if V = nil then Arr := (Curr.GetValue(Seg) as ITomlMutableArray);
  NewT := TTomlSimpleTable.Create as ITomlMutableTable;
  Arr.AddItem(NewT as ITomlValue);
  // 切换上下文到新表
  SetLength(FStack, Length(FStack)+1);
  FStack[High(FStack)] := NewT;
  Result := Self;
end;

function TTomlBuilderImpl.Build: ITomlDocument;
begin
  Result := TTomlSimpleDocument.CreateWithRoot(FDoc as ITomlTable);
end;

function TTomlBuilderImpl.SaveToFile(const AFileName: String; const AFlags: TTomlWriteFlags): Boolean;
var S: RawByteString; FS: TFileStream;
begin
  S := ToToml(Build, AFlags);
  FS := TFileStream.Create(AFileName, fmCreate);
  try
    if Length(S) > 0 then FS.WriteBuffer(S[1], Length(S));
    Result := True;
  finally
    FS.Free;
  end;
end;



{ 门面函数实现（占位实现） }

function _Parse_Internal_V1(const AText: RawByteString; out ADoc: ITomlDocument; out AErr: TTomlError; const AFlags: TTomlReadFlags): Boolean; forward;
function ValidateDocLimits(const ADoc: ITomlDocument; const ALimits: TTomlLimits; out AErr: TTomlError): Boolean; forward;

function HasNestedArrayLiteral(const AText: RawByteString): Boolean;
var
  LIndex: SizeInt;
  LLen: SizeInt;
begin
  Result := False;
  LLen := Length(AText);
  LIndex := 1;
  while LIndex <= LLen do
  begin
    if AText[LIndex] = '=' then
    begin
      Inc(LIndex);
      while (LIndex <= LLen) and (AText[LIndex] in [' ', #9]) do
        Inc(LIndex);
      if (LIndex + 1 <= LLen) and (AText[LIndex] = '[') and (AText[LIndex + 1] = '[') then
        Exit(True);
      Continue;
    end;
    Inc(LIndex);
  end;
end;

function Parse(const AText: RawByteString; out ADoc: ITomlDocument; out AErr: TTomlError; const AFlags: TTomlReadFlags): Boolean;
begin
  // Explicit parser selection keeps deterministic behavior.
  if (trfUseV1 in AFlags) then
    Exit(_Parse_Internal_V1(AText, ADoc, AErr, AFlags));
  if (trfUseV2 in AFlags) then
    Exit(TomlParseV2(AText, ADoc, AErr));

  // Nested array literals (e.g. a = [[1,2],[3,4]]) are handled by V2.
  if HasNestedArrayLiteral(AText) then
    Exit(TomlParseV2(AText, ADoc, AErr));

  // Default path keeps legacy-compatible semantics.
  Result := _Parse_Internal_V1(AText, ADoc, AErr, AFlags);
end;

function ParseWithLimits(const AText: RawByteString; const ALimits: TTomlLimits; out ADoc: ITomlDocument; out AErr: TTomlError; const AFlags: TTomlReadFlags): Boolean;
begin
  Result := Parse(AText, ADoc, AErr, AFlags);
  if Result then
  begin
    if not ValidateDocLimits(ADoc, ALimits, AErr) then Exit(False);
  end;
end;


function _Parse_Internal_V1(const AText: RawByteString; out ADoc: ITomlDocument; out AErr: TTomlError; const AFlags: TTomlReadFlags): Boolean;
var
  LDoc: ITomlDocument;
  LRoot: ITomlMutableTable;
  P, PEnd: PChar; R: PChar;
  LKey, LStr: String;
  LStart: PChar;


  L0: PChar;
  LValInt: Int64;
  LValBool: Boolean;
	  LContext: ITomlMutableTable;
	  LValFloat: Double;
	  LContextPath: String;
	  LHeaderPath: String;
	  LFullKeyPath: String;
	  LParsedKey: String;
  // dotted keys 相关临时变量（提前声明，避免内联 var 带来的语法不兼容）
  LCur: ITomlMutableTable;
  LFinalKey: String;
  LExisting: ITomlValue;
  LNew: ITomlMutableTable;
  LNextSeg: String;
  // 路径段收集（除去最终键）
  LPath: array of String;
  LPathLen: SizeInt;
  I: SizeInt;
  // 数组解析的临时变量（避免内联 var）
  Arr: ITomlMutableArray;
  ValI: Int64;
  ArrIsString, ArrIsBool, ArrIsFloat, HasType: Boolean;
  ExpectComma, Done: Boolean;

  function IsArrayOfTablesValue(const V: ITomlValue): Boolean; inline;
  var A: ITomlArray; i: SizeInt; item: ITomlValue;
  begin
    Result := False;
    if (V = nil) or (V.GetType <> tvtArray) then Exit(False);
    A := (V as ITomlArray);
    if A.Count = 0 then Exit(False);
    for i := 0 to A.Count - 1 do
    begin
      item := A.Item(i);
      if (item = nil) or (item.GetType <> tvtTable) then Exit(False);
    end;
    Result := True;
  end;

function ValidateDocLimits(const ADoc: ITomlDocument; const ALimits: TTomlLimits; out AErr: TTomlError): Boolean;
  function TraverseValue(const V: ITomlValue; Depth: SizeUInt; var KeyCount: SizeUInt): Boolean;
  var
    T: ITomlTable;
    A: ITomlArray;
    I: SizeInt;
    K: String;
    Child: ITomlValue;
    S: String;
  begin
    Result := True;
    if V = nil then Exit(True);
    if (ALimits.MaxDepth > 0) and (Depth > ALimits.MaxDepth) then
    begin
      SetErrorAtStart(AErr, tecLimitExceeded, 'document exceeds max depth limit');
      Exit(False);
    end;
    case V.GetType of
      tvtTable:
        begin
          T := (V as ITomlTable);
          for I := 0 to T.KeyCount - 1 do
          begin
            K := T.KeyAt(I);
            Inc(KeyCount);
            if (ALimits.MaxKeys > 0) and (KeyCount > ALimits.MaxKeys) then
            begin
              SetErrorAtStart(AErr, tecLimitExceeded, 'document exceeds max keys limit');
              Exit(False);
            end;
            Child := T.GetValue(K);
            if not TraverseValue(Child, Depth + 1, KeyCount) then Exit(False);
          end;
        end;
      tvtArray:
        begin
          A := (V as ITomlArray);
          for I := 0 to A.Count - 1 do
          begin
            Child := A.Item(I);
            if not TraverseValue(Child, Depth + 1, KeyCount) then Exit(False);
          end;
        end;
      tvtString:
        begin
          if V.TryGetString(S) then
          begin
            if (ALimits.MaxStringBytes > 0) and (Length(S) > ALimits.MaxStringBytes) then
            begin
              SetErrorAtStart(AErr, tecLimitExceeded, 'string value exceeds max length limit');
              Exit(False);
            end;
          end;
        end;
    else
      // scalars ok
    end;
    Result := True;
  end;
var
  Root: ITomlTable;
  Cnt: SizeUInt;
begin
  AErr.Clear;
  if ADoc = nil then Exit(True);
  Root := ADoc.GetRoot;
  if Root = nil then Exit(True);
  Cnt := 0;
  Result := TraverseValue(Root as ITomlValue, 1, Cnt);
end;

  procedure SkipSpaces; inline;
  begin
    while (P < PEnd) and (P^ in [#9, ' ']) do Inc(P);
  end;

  procedure SkipComment; inline;
  begin
    while (P < PEnd) and not (P^ in [#10, #13]) do Inc(P);
  end;

  function ReadIdentifier(out AOut: String): Boolean; inline;
  var
    L0: PChar;
  begin
    // 保留：旧的 bare key（不含 '-') 解析器，后续将全面用 ReadKey 替换
    AOut := '';
    if (P >= PEnd) or not (P^ in ['A'..'Z','a'..'z','_']) then Exit(False);
    L0 := P;
    Inc(P);
    while (P < PEnd) and (P^ in ['A'..'Z','a'..'z','0'..'9','_']) do Inc(P);
    SetString(AOut, L0, P - L0);
    Result := True;
  end;

  function ReadIdentifierFrom(var R: PChar; out AOut: String): Boolean; inline;
  var
    L0: PChar;
  begin
    // 保留：旧的 bare key from 指针解析器
    AOut := '';
    if (R >= PEnd) or not (R^ in ['A'..'Z','a'..'z','_']) then Exit(False);
    L0 := R;
    Inc(R);
    while (R < PEnd) and (R^ in ['A'..'Z','a'..'z','0'..'9','_']) do Inc(R);
    SetString(AOut, L0, R - L0);
    Result := True;
  end;

  function HexValLocal(C: Char; out V: Integer): Boolean; inline;
  begin
    case C of
      '0'..'9': begin V := Ord(C) - Ord('0'); Exit(True); end;
      'a'..'f': begin V := 10 + Ord(C) - Ord('a'); Exit(True); end;
      'A'..'F': begin V := 10 + Ord(C) - Ord('A'); Exit(True); end;
    end;
    V := 0; Result := False;
  end;

  function TryReadUnicodeEscape4(out CodePoint: Cardinal): Boolean; inline;
  var j, hv: Integer; P0: PChar;
  begin
    Result := False; CodePoint := 0; P0 := P; // P 指向 'u'
    if (P + 4 >= PEnd) then Exit(False);
    // 先窥探4位
    if not (HexValLocal((P+1)^, hv) and HexValLocal((P+2)^, hv) and HexValLocal((P+3)^, hv) and HexValLocal((P+4)^, hv)) then Exit(False);
    Inc(P); CodePoint := 0;
    for j := 1 to 4 do begin if not HexValLocal(P^, hv) then begin P := P0; Exit(False); end; CodePoint := (CodePoint shl 4) or Cardinal(hv); Inc(P); end;
    // 禁止代理项
    if (CodePoint >= $D800) and (CodePoint <= $DFFF) then begin P := P0; Exit(False); end;
    Result := True;
  end;

  function TryReadUnicodeEscape8(out CodePoint: QWord): Boolean; inline;
  var j, hv: Integer; P0: PChar; tmp: QWord;
  begin
    Result := False; CodePoint := 0; P0 := P; // P 指向 'U'
    if (P + 8 >= PEnd) then Exit(False);
    if not (HexValLocal((P+1)^, hv) and HexValLocal((P+2)^, hv) and HexValLocal((P+3)^, hv) and HexValLocal((P+4)^, hv)
            and HexValLocal((P+5)^, hv) and HexValLocal((P+6)^, hv) and HexValLocal((P+7)^, hv) and HexValLocal((P+8)^, hv)) then Exit(False);
    Inc(P); tmp := 0;
    for j := 1 to 8 do begin if not HexValLocal(P^, hv) then begin P := P0; Exit(False); end; tmp := (tmp shl 4) or QWord(hv); Inc(P); end;
    if (tmp > $10FFFF) or ((tmp >= $D800) and (tmp <= $DFFF)) then begin P := P0; Exit(False); end;
    CodePoint := tmp;
    Result := True;
  end;

  // Forward declaration to allow ReadKey to reuse string parser
  function ReadString(out AOut: String): Boolean; forward;


  function ReadKey(out AOut: String): Boolean; inline;
  var
    L0: PChar;
    LBuf: String;
    Ch: Char;
    Closed: Boolean;
    // for unicode escapes
    CP: Cardinal; CP2: QWord;
    i, v, i2, v2: Integer;
    tmp, tmp2: String;
  begin
    AOut := '';
    if (P >= PEnd) then Exit(False);
    // quoted key: "..."
    if P^ = '"' then
    begin
      Exit(ReadString(AOut));
      // 针对 key 的基本字符串解析（不支持三引号多行）
      Inc(P);
      LBuf := '';
      Closed := False;
      while (P < PEnd) do
      begin
        Ch := P^; Inc(P);
        if Ch = '"' then begin Closed := True; Break; end;
        if Ch = '\\' then
        begin
          // Writeln('ESC in key, next=', P^);
          if P >= PEnd then Exit(False);
          case P^ of
            '"':  begin Ch := '"'; Inc(P); end;
            '\':  begin Ch := '\'; Inc(P); end;
            'n':   begin Ch := #10;  Inc(P); end;
            'r':   begin Ch := #13;  Inc(P); end;
            't':   begin Ch := #9;   Inc(P); end;
            'b':   begin Ch := #8;   Inc(P); end;
            'f':   begin Ch := #12;  Inc(P); end;
            'u':   begin
                      // Writeln('ESC u in key');
                      if not TryReadUnicodeEscape4(CP) then Exit(False);
                      if CP <= $7F then tmp := Char(CP)
                      else if CP <= $7FF then tmp := Char($C0 or (CP shr 6)) + Char($80 or (CP and $3F))
                      else tmp := Char($E0 or (CP shr 12)) + Char($80 or ((CP shr 6) and $3F)) + Char($80 or (CP and $3F));
                      LBuf := LBuf + tmp;
                      Continue;
                   end;
            'U':   begin
                      // Writeln('ESC U in key');
                      if not TryReadUnicodeEscape8(CP2) then Exit(False);
                      if CP2 <= $7F then tmp2 := Char(CP2)
                      else if CP2 <= $7FF then tmp2 := Char($C0 or (CP2 shr 6)) + Char($80 or (CP2 and $3F))
                      else if CP2 <= $FFFF then tmp2 := Char($E0 or (CP2 shr 12)) + Char($80 or ((CP2 shr 6) and $3F)) + Char($80 or (CP2 and $3F))
                      else tmp2 := Char($F0 or (CP2 shr 18)) + Char($80 or ((CP2 shr 12) and $3F)) + Char($80 or ((CP2 shr 6) and $3F)) + Char($80 or (CP2 and $3F));
                      LBuf := LBuf + tmp2;
                      Continue;
                   end;
          else
            Exit(False);
          end;
        end
        else
        begin
          LBuf := LBuf + Ch;
        end;
      end;
      if not Closed then Exit(False);
      AOut := LBuf;
      Exit(True);
    end;
    // bare key: A..Z a..z 0..9 _ -
    if not (P^ in ['A'..'Z','a'..'z','0'..'9','_','-']) then Exit(False);
    L0 := P;
    Inc(P);
    while (P < PEnd) do
    begin
      Ch := P^;
      if not (Ch in ['A'..'Z','a'..'z','0'..'9','_','-']) then Break;
      Inc(P);
    end;
    SetString(AOut, L0, P - L0);
    Result := True;
  end;

  // TODO(fafafa.core.toml.Reader): 字符串/Unicode 转义
  // - 支持 \uXXXX 与 \UXXXXXXXX（严格 4/8 个 hex）；
  // - 禁止代理项码点 (D800–DFFF)，上界 ≤ U+10FFFF；
  // - 负例详见 tests（unicode_negatives / _ext）。
  // TODO(nav.Reader.Strings): 通用字符串解析（keys/values 复用），严格 \\ 转义、\u/\U 边界、禁止代理项
  function ReadString(out AOut: String): Boolean; inline;
  var
    LCh: Char;
    LBuf: String;
    LLen: SizeInt;
    // unicode escape helpers
    CP: Cardinal; CP2: QWord;
    i, v, i2, v2: Integer;
    tmp, tmp2: String;
    Q: PChar;

  begin
    AOut := '';
    if (P >= PEnd) then Exit(False);
    // 三引号多行字符串 """..."""
    if (PEnd - P >= 3) and (P^='"') and ((P+1)^='"') and ((P+2)^='"') then
    begin
      Inc(P,3);
      // TOML: 如果紧跟着的是换行（LF 或 CRLF），需要修剪（跳过一次换行）
      if (P < PEnd) then
      begin
        if P^ = #13 then begin if ((P+1) < PEnd) and ((P+1)^ = #10) then Inc(P,2) else Inc(P); end
        else if P^ = #10 then Inc(P);
      end;
      LBuf := '';
      while (P < PEnd) do
      begin
        // 结束条件：三引号
        if (PEnd - P >= 3) and (P^='"') and ((P+1)^='"') and ((P+2)^='"') then
        begin Inc(P,3); Break; end;
        LCh := P^; Inc(P);
        if LCh = '\\' then
        begin
          if P >= PEnd then Break;
          // 行尾反斜杠续行：反斜杠后仅有空白（空格/Tab）直至换行，则跳过换行并修剪下一行的起始空白
          if (P < PEnd) then
          begin
            // 使用局部指针扫描（避免内联 var 语法兼容问题）
            Q := P;
            while (Q < PEnd) and ((Q^ = ' ') or (Q^ = #9)) do Inc(Q);
            if (Q < PEnd) and ((Q^ = #10) or (Q^ = #13)) then
            begin
              // 跳过行结束（支持 CRLF 或 LF）
              if Q^ = #13 then begin if ((Q+1) < PEnd) and ((Q+1)^ = #10) then Inc(Q,2) else Inc(Q); end
              else Inc(Q);
              // 修剪下一行起始空白（空格/Tab）
              while (Q < PEnd) and ((Q^ = ' ') or (Q^ = #9)) do Inc(Q);
              P := Q;
              Continue; // 不附加任何字符，相当于拼接相邻两行
            end;
          end;
          case P^ of
            '"':  begin LCh := '"'; Inc(P); end;
            '\':  begin LCh := '\';  Inc(P); end;
            'n':   begin LBuf := LBuf + LineEnding; Inc(P); Continue; end;
            'r':   begin LCh := #13;  Inc(P); end;
            't':   begin LCh := #9;   Inc(P); end;
            'b':   begin LCh := #8;   Inc(P); end;
            'f':   begin LCh := #12;  Inc(P); end;
            'u':   begin
                      if not TryReadUnicodeEscape4(CP) then Exit(False);
                      if CP <= $7F then tmp := Char(CP)
                      else if CP <= $7FF then tmp := Char($C0 or (CP shr 6)) + Char($80 or (CP and $3F))
                      else tmp := Char($E0 or (CP shr 12)) + Char($80 or ((CP shr 6) and $3F)) + Char($80 or (CP and $3F));
                      LBuf := LBuf + tmp;
                      Continue;
                    end;
            'U':   begin
                      if not TryReadUnicodeEscape8(CP2) then Exit(False);
                      if CP2 <= $7F then tmp2 := Char(CP2)
                      else if CP2 <= $7FF then tmp2 := Char($C0 or (CP2 shr 6)) + Char($80 or (CP2 and $3F))
                      else if CP2 <= $FFFF then tmp2 := Char($E0 or (CP2 shr 12)) + Char($80 or ((CP2 shr 6) and $3F)) + Char($80 or (CP2 and $3F))
                      else tmp2 := Char($F0 or (CP2 shr 18)) + Char($80 or ((CP2 shr 12) and $3F)) + Char($80 or ((CP2 shr 6) and $3F)) + Char($80 or (CP2 and $3F));
                      LBuf := LBuf + tmp2;
                      Continue;
                    end;
          else
            ; // 未知转义：按规范应报错；此处保持为字面（可按需调整）
          end;
        end;
        LLen := Length(LBuf); SetLength(LBuf, LLen + 1); LBuf[LLen + 1] := LCh;
      end;
      AOut := LBuf; Exit(True);
    end;
    // 普通双引号字符串，支持转义
    if (P^='"') then
    begin
      Inc(P);
      LBuf := '';
      while (P < PEnd) do
      begin
        LCh := P^; Inc(P);
        if LCh = '"' then break;
        if LCh = '\' then
        begin
          if P >= PEnd then Exit(False);
          case P^ of
            '"':  begin LCh := '"'; Inc(P); end;
            '\':  begin LCh := '\';  Inc(P); end;
            'n':   begin LCh := #10;  Inc(P); end;
            'r':   begin LCh := #13;  Inc(P); end;
            't':   begin LCh := #9;   Inc(P); end;
            'b':   begin LCh := #8;   Inc(P); end;
            'f':   begin LCh := #12;  Inc(P); end;
            'u':   begin
                      if not TryReadUnicodeEscape4(CP) then Exit(False);
                      if CP <= $7F then tmp := Char(CP)
                      else if CP <= $7FF then tmp := Char($C0 or (CP shr 6)) + Char($80 or (CP and $3F))
                      else tmp := Char($E0 or (CP shr 12)) + Char($80 or ((CP shr 6) and $3F)) + Char($80 or (CP and $3F));
                      LBuf := LBuf + tmp;
                      Continue;
                    end;
            'U':   begin
                      if not TryReadUnicodeEscape8(CP2) then Exit(False);
                      if CP2 <= $7F then tmp2 := Char(CP2)
                      else if CP2 <= $7FF then tmp2 := Char($C0 or (CP2 shr 6)) + Char($80 or (CP2 and $3F))
                      else if CP2 <= $FFFF then tmp2 := Char($E0 or (CP2 shr 12)) + Char($80 or ((CP2 shr 6) and $3F)) + Char($80 or (CP2 and $3F))
                      else tmp2 := Char($F0 or (CP2 shr 18)) + Char($80 or ((CP2 shr 12) and $3F)) + Char($80 or ((CP2 shr 6) and $3F)) + Char($80 or (CP2 and $3F));
                      LBuf := LBuf + tmp2;
                      Continue;
                    end;
          else
            LCh := P^; Inc(P);
          end;
        end;
        LLen := Length(LBuf); SetLength(LBuf, LLen + 1); LBuf[LLen + 1] := LCh;
      end;
      AOut := LBuf; Exit(True);
    end;
    // 单引号字面量字符串（含三引号多行），不处理转义
    if (P^='''') then
    begin
      // 三单引号多行
      if (PEnd - P >= 3) and ((P+1)^='''') and ((P+2)^='''') then
      begin
        Inc(P,3);
        // 字面量三引号多行：同样修剪开头单次换行
        if (P < PEnd) then
        begin
          if P^ = #13 then begin if ((P+1) < PEnd) and ((P+1)^ = #10) then Inc(P,2) else Inc(P); end
          else if P^ = #10 then Inc(P);
        end;
        LBuf := '';
        while (P < PEnd) do
        begin
          if (PEnd - P >= 3) and (P^='''') and ((P+1)^='''') and ((P+2)^='''') then
          begin Inc(P,3); Break; end;
          LCh := P^; Inc(P);
          LLen := Length(LBuf); SetLength(LBuf, LLen + 1); LBuf[LLen + 1] := LCh;
        end;
        AOut := LBuf; Exit(True);
      end
      else
      begin
        Inc(P);
        LBuf := '';
        while (P < PEnd) do
        begin
          LCh := P^; Inc(P);
          if LCh = '''' then break; // 无转义
          LLen := Length(LBuf); SetLength(LBuf, LLen + 1); LBuf[LLen + 1] := LCh;
        end;
        AOut := LBuf; Exit(True);
      end;
    end;
    Result := False;
  end;

  procedure SetError(const ACode: TTomlErrorCode; const AMsg: String; APtr: PChar = nil);
  var
    Q: PChar; L, C: SizeUInt; Ch: Char;
  begin
    AErr.Code := ACode;
    AErr.Message := AMsg;
    if APtr = nil then APtr := P;
    AErr.Position := APtr - LStart;
    L := 1; C := 1; Q := LStart;
    while Q < APtr do
    begin
      Ch := Q^; Inc(Q);
      if Ch = #13 then
      begin
        if (Q < APtr) and (Q^ = #10) then Inc(Q);
        Inc(L); C := 1;
      end
      else if Ch = #10 then
      begin
        Inc(L); C := 1;
      end
      else
        Inc(C);
    end;
    AErr.Line := L;
    AErr.Column := C;
  end;


  function ReadInteger(out AOut: Int64): Boolean; inline;
  var
    LNeg, PrevUnderscore: Boolean;
    LDigitCount: SizeInt;
    LFirstDigitZero: Boolean;
  begin
    AOut := 0;
    LNeg := False;
    if (P < PEnd) and (P^ = '+') then Inc(P)
    else if (P < PEnd) and (P^ = '-') then begin LNeg := True; Inc(P); end;
    if (P >= PEnd) or not (P^ in ['0'..'9']) then Exit(False);
    // 主循环，禁止连续 '_'，禁止以 '_' 结束
    LDigitCount := 0;
    LFirstDigitZero := False;
    PrevUnderscore := False;
    while (P < PEnd) and (P^ in ['0'..'9','_']) do
    begin
      if P^ = '_' then
      begin
        if PrevUnderscore then Exit(False);
        PrevUnderscore := True;
        Inc(P);
        continue;
      end;
      PrevUnderscore := False;
      Inc(LDigitCount);
      if LDigitCount = 1 then
        LFirstDigitZero := (P^ = '0')
      else if LFirstDigitZero then
        Exit(False); // 十进制整数禁止前导零（如 01、0_1）
      AOut := AOut * 10 + Ord(P^) - Ord('0');
      Inc(P);
    end;
    if PrevUnderscore then Exit(False);
    if LNeg then AOut := -AOut;
    Result := True;
  end;

  function ReadFloat(out AOut: Double): Boolean; inline;
  var
    L0: PChar;
    HasDot, HasExp: Boolean;
    FS: TFormatSettings;
    Tmp, Tmp2: String;
    I: SizeInt;
    PrevUnderscore: Boolean;
    LIntDigitCount: SizeInt;
    LFirstDigitZero: Boolean;
  begin
    AOut := 0.0;
    L0 := P;
    HasDot := False; HasExp := False;
    if (P < PEnd) and (P^ in ['+','-']) then Inc(P);
    if (P >= PEnd) or not (P^ in ['0'..'9']) then Exit(False);
    // 收集整数部分，禁止连续 '_'，禁止以 '_' 结束
    LIntDigitCount := 0;
    LFirstDigitZero := False;
    PrevUnderscore := False;
    while (P < PEnd) and (P^ in ['0'..'9','_']) do
    begin
      if P^ = '_' then
      begin
        if PrevUnderscore then begin P := L0; Exit(False); end;
        PrevUnderscore := True;
        Inc(P);
      end
      else
      begin
        PrevUnderscore := False;
        Inc(LIntDigitCount);
        if LIntDigitCount = 1 then
          LFirstDigitZero := (P^ = '0')
        else if LFirstDigitZero then begin P := L0; Exit(False); end; // 浮点整数部分禁止前导零
        Inc(P);
      end;
    end;
    // 小数点
    if (P < PEnd) and (P^ = '.') then
    begin
      if PrevUnderscore then begin P := L0; Exit(False); end; // 禁止 1_.2
      HasDot := True; Inc(P);
      // 小数点后不能紧跟 '_'，且必须至少一位数字
      if (P >= PEnd) or (P^ = '_') or not (P^ in ['0'..'9','_']) then begin P := L0; Exit(False); end;
      PrevUnderscore := False;
      while (P < PEnd) and (P^ in ['0'..'9','_']) do
      begin
        if P^ = '_' then
        begin
          if PrevUnderscore then begin P := L0; Exit(False); end;
          PrevUnderscore := True; Inc(P);
        end
        else
        begin
          PrevUnderscore := False; Inc(P);
        end;
      end;
      if PrevUnderscore then begin P := L0; Exit(False); end;
    end;
    // 指数部分 e/E
    if (P < PEnd) and (P^ in ['e','E']) then
    begin
      HasExp := True; Inc(P);
      if (P < PEnd) and (P^ in ['+','-']) then Inc(P);
      // 指数部分必须是数字，不允许 '_' 开头，也不允许下划线
      if (P >= PEnd) or not (P^ in ['0'..'9']) then begin P := L0; Exit(False); end;
      while (P < PEnd) and (P^ in ['0'..'9']) do Inc(P);
    end;
    if not (HasDot or HasExp) then begin P := L0; Exit(False); end;
    SetString(Tmp, L0, P - L0);
    // 去除下划线再解析
    Tmp2 := '';
    for I := 1 to Length(Tmp) do if Tmp[I] <> '_' then Tmp2 := Tmp2 + Tmp[I];
    FS := DefaultFormatSettings; FS.DecimalSeparator := '.';
    if not TryStrToFloat(Tmp2, AOut, FS) then begin P := L0; Exit(False); end;
    Result := True;
  end;


  function ReadBoolean(out AOut: Boolean): Boolean; inline;
  var
    L0: PChar;
    LLen: SizeInt;
    LTmp: RawByteString;
  begin
    AOut := False;
    L0 := P;
    while (P < PEnd) and (P^ in ['a'..'z','A'..'Z']) do Inc(P);
    LLen := P - L0;
    if LLen = 0 then Exit(False);
    SetString(LTmp, L0, LLen);
    if (String(LTmp) = 'true') or (String(LTmp) = 'false') then
    begin
      AOut := (String(LTmp) = 'true');
      Exit(True);
    end
    else if (String(LTmp) = 'nan') or (String(LTmp) = 'inf') or (String(LTmp) = '-inf') then
    begin
      // TOML: nan/inf 都是不允许的
      Exit(False);
    end
    else
      Exit(False);
  end;
begin
  AErr.Clear;
  if AFlags <> [] then;
  LRoot := TTomlSimpleTable.Create as ITomlMutableTable;
  // 初始化解析上下文
  LContext := nil;
  LHeaderPath := '';
  LFullKeyPath := '';
  {$IFDEF DEBUG}
  // 调试时可将上下文预设为根，便于观测
  // LContext := LRoot;
  // WriteLn('DEBUG RootObjPtr=', PtrUInt(LRoot));
  {$ENDIF}
  P := PChar(AText);
  LStart := P;

  PEnd := P + Length(AText);
  while P < PEnd do
  begin
    // 跳过空白与换行
    // [table] and [[array-of-tables]] headers: [a.b] or [[a.b]]
    if (P^ = '[') then
    begin
      // detect [[ array of tables ]]
      if (P+1 < PEnd) and ((P+1)^ = '[') then
      begin
        // consume [[
        Inc(P, 2);
        SkipSpaces;
        // read first segment
        if not ReadKey(LKey) then begin SetError(tecInvalidToml, 'Invalid array-of-tables header'); Exit(False); end;
      {$IFDEF DEBUG}
      // Writeln('DEBUG aot first seg: "', LKey, '"');
      {$ENDIF}
        // traverse segments until ]]
        LCur := LRoot; LFinalKey := LKey; SkipSpaces;
        while (P < PEnd) and not ((P^ = ']') and ((P+1) < PEnd) and ((P+1)^ = ']')) do
        begin
          if P^ = '.' then
          begin
            Inc(P); SkipSpaces;
            if not ReadKey(LNextSeg) then begin SetError(tecInvalidToml, 'Invalid array-of-tables segment'); Exit(False); end;
          {$IFDEF DEBUG}
          // Writeln('DEBUG aot seg: "', LNextSeg, '"');
          {$ENDIF}
            // ensure previous segment is a table
            LExisting := LCur.GetValue(LFinalKey);
            if (LExisting = nil) then
            begin
              LNew := TTomlSimpleTable.Create as ITomlMutableTable;
              LCur.AddPair(LFinalKey, LNew as ITomlValue);
              LCur := LNew;
            end
            else if (LExisting.GetType = tvtTable) then
              LCur := (LExisting as ITomlMutableTable)
            else begin SetError(tecTypeMismatch, 'Array-of-tables path segment is not a table'); Exit(False); end;
            LFinalKey := LNextSeg; SkipSpaces;
          end
          else begin SetError(tecInvalidToml, 'Unexpected char in array-of-tables header'); Exit(False); end;
        end;
        // expect closing ]]
        if not ((P < PEnd) and (P^ = ']') and ((P+1) < PEnd) and ((P+1)^ = ']')) then begin SetError(tecInvalidToml, 'Unclosed array-of-tables header'); Exit(False); end;
        Inc(P, 2);
        // now ensure LFinalKey holds an array, append a new table and set context
        LExisting := LCur.GetValue(LFinalKey);
        if (LExisting = nil) then
        begin
          // create array and first table
          Arr := TTomlSimpleArray.Create as ITomlMutableArray;
          LCur.AddPair(LFinalKey, Arr as ITomlValue);
          LNew := TTomlSimpleTable.Create as ITomlMutableTable;
          Arr.AddItem(LNew as ITomlValue);
          LContext := LNew;
        end
        else if (LExisting.GetType = tvtArray) then
        begin
          // append new table item
          Arr := (LExisting as ITomlMutableArray);
          LNew := TTomlSimpleTable.Create as ITomlMutableTable;
          Arr.AddItem(LNew as ITomlValue);
          LContext := LNew;
        end
        else begin SetError(tecTypeMismatch, 'Array-of-tables conflicts with existing non-array'); Exit(False); end;
        // eat trailing spaces/comment/eol
        while (P < PEnd) and (P^ in [#9, ' ']) do Inc(P);
        if (P < PEnd) and (P^ = '#') then SkipComment;
        while (P < PEnd) and (P^ in [#10, #13]) do Inc(P);
        Continue;
      end;
      Inc(P);
      SkipSpaces;
      // 读取路径的首段（支持 quoted key）
      if not ReadKey(LKey) then
      begin
        SetError(tecInvalidToml, 'Invalid table header');
        Exit(False);
      end;
      // 解析剩余 dotted 段直到遇到 ]（表头始终从根出发）
      LCur := LRoot;
      LHeaderPath := LKey;
      LFinalKey := LKey;
      SkipSpaces;
      while (P < PEnd) and (P^ <> ']') do
      begin
        if P^ = '.' then
        begin
          Inc(P); SkipSpaces;
          if not ReadKey(LNextSeg) then
          begin SetError(tecInvalidToml, 'Invalid table header segment'); Exit(False); end;
          {$IFDEF DEBUG}
          // Writeln('DEBUG table header seg: "', LNextSeg, '"');
          {$ENDIF}
          // ensure 之前段为子表
          LExisting := LCur.GetValue(LFinalKey);
          if (LExisting = nil) then
          begin
            // 记录表头路径（用于冲突检查与诊断）
            LHeaderPath := LHeaderPath + '.' + LNextSeg;
            LNew := TTomlSimpleTable.Create as ITomlMutableTable;
            LCur.AddPair(LFinalKey, LNew as ITomlValue);
            LCur := LNew;
          end
          else if (LExisting.GetType = tvtTable) then
            LCur := (LExisting as ITomlMutableTable)
          else if IsArrayOfTablesValue(LExisting) then
          begin
            // 当上一段是数组表时，继续的子段写入该数组最后一个表项
            if (LExisting as ITomlArray).Count = 0 then begin SetError(tecTypeMismatch, 'Array-of-tables is empty'); Exit(False); end;
            LCur := ((LExisting as ITomlArray).Item((LExisting as ITomlArray).Count - 1) as ITomlMutableTable);
          end
          else
          begin SetError(tecTypeMismatch, 'Table header path segment is not a table'); Exit(False); end;
          LFinalKey := LNextSeg;
          SkipSpaces;

        end
        else
        begin
          // 非 '.' 非 ']'，非法
          SetError(tecInvalidToml, 'Unexpected char in table header');
          Exit(False);
        end;
      end;
      // 检查目标键是否已被定义为非表（冲突）
      LExisting := LCur.GetValue(LFinalKey);
      if (LExisting <> nil) and (LExisting.GetType <> tvtTable) then
      begin
        SetError(tecTypeMismatch, 'Table header conflicts with a non-table value');
        Exit(False);
      end;
      // 关闭 ']' 并确保最终表存在
      if (P >= PEnd) or (P^ <> ']') then begin SetError(tecInvalidToml, 'Unclosed table header'); Exit(False); end;
      Inc(P);
      // ensure 最后一段为表；同一路径重复 [table] 定义不可接受
      LExisting := LCur.GetValue(LFinalKey);
      if (LExisting = nil) then
      begin
        LNew := TTomlSimpleTable.Create as ITomlMutableTable;
        LCur.AddPair(LFinalKey, LNew as ITomlValue);
        LContext := LNew; // 切换当前上下文
      end
      else
      begin
        if (LExisting.GetType = tvtTable) then
        begin
          SetError(tecDuplicateKey, 'Table header redefinition is not allowed');
        end
        else
        begin
          SetError(tecTypeMismatch, 'Table header conflicts with non-table');
        end;
        Exit(False);
      end;
      // 吃掉行尾和注释
      while (P < PEnd) and (P^ in [#9, ' ']) do Inc(P);
      if (P < PEnd) and (P^ = '#') then SkipComment;
      while (P < PEnd) and (P^ in [#10, #13]) do Inc(P);
      Continue;
    end;
    while (P < PEnd) and (P^ in [#9, ' ', #10, #13]) do Inc(P);
    if P >= PEnd then Break;
    if P^ = '#' then begin SkipComment; Continue; end;

    // 读取 key（支持简单 dotted keys：a.b.c，无空格）
    if not ReadKey(LKey) then
    begin
      SetError(tecInvalidToml, 'Invalid key');
      Exit(False);
    end;
    // Writeln('KEY: ', LKey);

    // 增量式下钻：逐段 ensure 子表，最后一段作为最终键
    // 在存在显式 [table] 头之后，键值应写入当前上下文表；否则写入根
    if LContext <> nil then LCur := LContext else LCur := LRoot;
    LFinalKey := LKey; // 当前候选为首段
	    // 构建完整 dotted 路径（相对于根）
	    LFullKeyPath := LKey;
    // 允许在点号周围存在空格： a . b . c
    SkipSpaces;
    while (P < PEnd) and (P^ = '.') do

    begin
      Inc(P);
      SkipSpaces;
      if not ReadKey(LNextSeg) then
      begin
        SetError(tecInvalidToml, 'Invalid dotted key segment');
        Exit(False);

      end; // 点后必须是标识符
      // Writeln('SEG: ', LNextSeg);
      SkipSpaces;
	      // 记录完整路径（包含下一个段）用于与表头路径比较（基于根路径）
	      if LFullKeyPath = '' then LFullKeyPath := LFinalKey + '.' + LNextSeg else LFullKeyPath := LFullKeyPath + '.' + LNextSeg;

      // 将当前候选段作为子表 ensure
      LExisting := LCur.GetValue(LFinalKey);
      if (LExisting = nil) then
      begin
        LNew := TTomlSimpleTable.Create as ITomlMutableTable;
        LCur.AddPair(LFinalKey, LNew as ITomlValue);
        {$IFDEF DEBUG}
        // Writeln('  created subtable: ', LFinalKey);
        {$ENDIF}
        LCur := LNew;
      end
      else if (LExisting.GetType = tvtTable) then
      begin
	      if (LContext <> nil) and (LExisting <> nil) and (LExisting.GetType = tvtTable) and (LHeaderPath = LFullKeyPath) then
	      begin
	        SetError(tecDuplicateKey, 'Dotted key conflicts with existing table from header');
	        Exit(False);
	      end;
        {$IFDEF DEBUG}
        // Writeln('  reuse subtable: ', LFinalKey);
        {$ENDIF}
        LCur := (LExisting as ITomlMutableTable);
      end
      else
      begin
        SetError(tecTypeMismatch, 'Path segment is not a table');
        Exit(False);
      end;

      // 下一个段成为新的候选最终键
      LFinalKey := LNextSeg;
    end;

    SkipSpaces;
    if (P >= PEnd) or (P^ <> '=') then begin SetError(tecInvalidToml, 'Expected = after key'); Exit(False); end;
    Inc(P);
    SkipSpaces;
    {$IFDEF DEBUG}
    // WriteLn('DEBUG dotted: FinalKey=', LFinalKey);
    // WriteLn('DEBUG before insert: root.keys=', (LRoot as ITomlTable).KeyCount);
    // if (LRoot as ITomlTable).KeyCount>0 then WriteLn('DEBUG root.KeyAt(0)=', (LRoot as ITomlTable).KeyAt(0));
    {$ENDIF}

    // 重复键检测（同一表内不允许重复定义）
    if LCur.Contains(LFinalKey) then
    begin
      SetError(tecDuplicateKey, 'Duplicate key');
      Exit(False);
    end;

    // 读取 value → 写入到 LCur[LFinalKey]
    if (P < PEnd) and ((P^ = '"') or (P^ = '''')) then
    begin
      if not ReadString(LStr) then begin SetError(tecInvalidToml, 'Invalid string'); Exit(False); end;
      LCur.AddPair(LFinalKey, TTomlSimpleValue.CreateString(LStr) as ITomlValue);
    end
    else if (P < PEnd) and (P^ in ['{','[','+','-','0'..'9','T','Z']) then
      // TODO(nav.Reader.ValueDispatch): 快速分流 value：string/inline/array/number/bool/datetime
    begin
      // 日期时间四类最小格式（基于首字符快速分流）：
      //  - OffsetDateTime: YYYY-MM-DDThh:mm:ss(Z or ±hh:mm)
      //  - LocalDateTime: YYYY-MM-DDThh:mm:ss
      //  - LocalDate:     YYYY-MM-DD
      //  - LocalTime:     hh:mm:ss
      if (P^ in ['0'..'9']) then
      begin
        // 可能是日期或时间开头
        // 尝试读取 YYYY-MM-DD
        L0 := P;
        if (PEnd - P >= 10) and (P[4] = '-') and (P[7] = '-') then
        begin
          Inc(P, 10);
          if (P < PEnd) and (P^ = 'T') then
          begin
            // LocalDateTime 或 OffsetDateTime
            Inc(P); // 过 T
            if (PEnd - P >= 8) and (P[2] = ':') and (P[5] = ':') then
            begin
              Inc(P, 8);
              // 可选偏移 Z 或 ±hh:mm（注意：-0700 属于非法格式；见负例用例）
              if (P < PEnd) and ((P^ = 'Z') or (P^ in ['+','-'])) then
              begin
                if P^ = 'Z' then Inc(P)
                else if (PEnd - P >= 6) and (P[3] = ':') then Inc(P, 6)
                else begin SetError(tecInvalidToml, 'Invalid offset datetime'); Exit(False); end;
                SetString(LStr, L0, P - L0);
                // 存为 OffsetDateTime 文本
                LCur.AddPair(LFinalKey, (TTomlSimpleValue.CreateString('') as ITomlValue));
                (LCur.GetValue(LFinalKey) as TTomlSimpleValue).FType := tvtOffsetDateTime;
                (LCur.GetValue(LFinalKey) as TTomlSimpleValue).FTemporalText := LStr;
              end
              else
              begin
                SetString(LStr, L0, P - L0);
                LCur.AddPair(LFinalKey, (TTomlSimpleValue.CreateString('') as ITomlValue));
                (LCur.GetValue(LFinalKey) as TTomlSimpleValue).FType := tvtLocalDateTime;
                (LCur.GetValue(LFinalKey) as TTomlSimpleValue).FTemporalText := LStr;
              end;
              Continue;
            end;
          end
          else
          begin
            // LocalDate
            SetString(LStr, L0, P - L0);
            LCur.AddPair(LFinalKey, (TTomlSimpleValue.CreateString('') as ITomlValue));
            (LCur.GetValue(LFinalKey) as TTomlSimpleValue).FType := tvtLocalDate;
            (LCur.GetValue(LFinalKey) as TTomlSimpleValue).FTemporalText := LStr;
            Continue;
          end;
        end
        else if (PEnd - P >= 8) and (P[2] = ':') and (P[5] = ':') then
        begin
          // LocalTime
          Inc(P, 8);
          SetString(LStr, L0, P - L0);
          LCur.AddPair(LFinalKey, (TTomlSimpleValue.CreateString('') as ITomlValue));
          (LCur.GetValue(LFinalKey) as TTomlSimpleValue).FType := tvtLocalTime;
          (LCur.GetValue(LFinalKey) as TTomlSimpleValue).FTemporalText := LStr;
          Continue;
        end;
        // 否则按数字处理（回落到数值解析）
        P := L0;
      end;
      if (P^ = '{') then
      begin
        // parse inline table { k = v, ... }
        Inc(P); SkipSpaces;
        LNew := TTomlSimpleTable.Create as ITomlMutableTable; // temporary table to fill
        // allow empty inline: {}
        if (P < PEnd) and (P^ = '}') then begin Inc(P); LCur.AddPair(LFinalKey, LNew as ITomlValue); Continue; end;
        ExpectComma := False;
        while (P < PEnd) do
        begin
          if ExpectComma then
          begin
            if P^ <> ',' then begin SetError(tecInvalidToml, 'Expected comma in inline table'); Exit(False); end;
            Inc(P); SkipSpaces;
          end;
          // read key
          if not ReadKey(LKey) then begin SetError(tecInvalidToml, 'Invalid inline table key'); Exit(False); end;
          {$IFDEF DEBUG}
          // Writeln('DEBUG inline key: "', LKey, '"');
          {$ENDIF}
          SkipSpaces; if (P >= PEnd) or (P^ <> '=') then begin SetError(tecInvalidToml, 'Expected = in inline table'); Exit(False); end;
          Inc(P); SkipSpaces;
          // value: support string/int/bool/float/minimal datetime; nested inline/arrays could be extended later
          if (P < PEnd) and ((P^ = '"') or (P^ = '''')) then begin if not ReadString(LStr) then begin SetError(tecInvalidToml, 'Invalid inline string'); Exit(False); end; LNew.AddPair(LKey, TTomlSimpleValue.CreateString(LStr) as ITomlValue); end
          else if ReadFloat(LValFloat) then LNew.AddPair(LKey, TTomlSimpleValue.CreateFloat(LValFloat) as ITomlValue)
          else if ReadInteger(LValInt) then LNew.AddPair(LKey, TTomlSimpleValue.CreateInteger(LValInt) as ITomlValue)
          else if ReadBoolean(LValBool) then LNew.AddPair(LKey, TTomlSimpleValue.CreateBoolean(LValBool) as ITomlValue)
          else begin SetError(tecInvalidToml, 'Unsupported inline table value'); Exit(False); end;
          SkipSpaces;
          // end or more
          if (P < PEnd) and (P^ = '}') then begin Inc(P); LCur.AddPair(LFinalKey, LNew as ITomlValue); Break; end;
          ExpectComma := True;
          SkipSpaces;
        end;
        Continue;
      end;


      if (P^ = '[') then
      begin
        // 最小实现：支持整型数组与字符串数组；禁止混合
        Inc(P); SkipSpaces;
        Arr := TTomlSimpleArray.Create as ITomlMutableArray;
        ExpectComma := False; Done := False; ArrIsString := False; HasType := False;
        while (P < PEnd) and not Done do
        begin
          SkipSpaces;
          if (P^ = ']') then begin Inc(P); Done := True; Break; end;
          // 空数组直接收尾
          if not ExpectComma and not HasType and (P^ = ']') then begin Inc(P); Done := True; Break; end;
          if ExpectComma then
          begin
            if P^ <> ',' then begin SetError(tecInvalidToml, 'Expected comma'); Exit(False); end;
            Inc(P); SkipSpaces;
          end;
          // 首元素决定数组元素类型（字符串/布尔/整数/浮点），禁止混合
          if not HasType then
          begin
            ArrIsString := (P^ = '"');
            ArrIsBool := (P^ in ['t','T','f','F']);
            ArrIsFloat := False;
            // 粗略预判浮点：存在 '.' 或 e/E；否则按整数
            // 备份位置尝试读取浮点；若成功则标记 ArrIsFloat 并回退
            L0 := P;
            if not (ArrIsString or ArrIsBool) then
            begin
              if ReadFloat(LValFloat) then ArrIsFloat := True;
              P := L0;
            end;
            HasType := True;
          end;
          if ArrIsString then
          begin
            if not ReadString(LStr) then begin SetError(tecInvalidToml, 'Invalid array string'); Exit(False); end;
            Arr.AddItem(TTomlSimpleValue.CreateString(LStr) as ITomlValue);
          end
          else if ArrIsBool then
          begin
            if not ReadBoolean(LValBool) then begin SetError(tecInvalidToml, 'Invalid array boolean'); Exit(False); end;
            Arr.AddItem(TTomlSimpleValue.CreateBoolean(LValBool) as ITomlValue);
          end
          else if ArrIsFloat then
          begin
            if not ReadFloat(LValFloat) then begin SetError(tecInvalidToml, 'Invalid array float'); Exit(False); end;
            Arr.AddItem(TTomlSimpleValue.CreateFloat(LValFloat) as ITomlValue);
          end
          else
          begin
            if not ReadInteger(ValI) then begin SetError(tecInvalidToml, 'Invalid array integer'); Exit(False); end;
            Arr.AddItem(TTomlSimpleValue.CreateInteger(ValI) as ITomlValue);
          end;
          SkipSpaces; ExpectComma := True;
        end;
        LCur.AddPair(LFinalKey, Arr as ITomlValue);
      end
      else
      begin
        // 数值：优先尝试浮点（要求含小数点或指数）；失败再回退为整数
        if ReadFloat(LValFloat) then
          LCur.AddPair(LFinalKey, TTomlSimpleValue.CreateFloat(LValFloat) as ITomlValue)
        else if ReadInteger(LValInt) then
          LCur.AddPair(LFinalKey, TTomlSimpleValue.CreateInteger(LValInt) as ITomlValue)
        else
        begin
          SetError(tecInvalidToml, 'Invalid number');
          Exit(False);
        end;
      end;
    end // close datetime/array/number branch
    else
    begin
      if ReadBoolean(LValBool) then
        LCur.AddPair(LFinalKey, TTomlSimpleValue.CreateBoolean(LValBool) as ITomlValue)
      else
      begin
        SetError(tecInvalidToml, 'Invalid value');
        Exit(False);
      end;
    end;

    // 行末与后续空白/注释；若存在非注释/非换行的多余字符，报错
    while (P < PEnd) and (P^ in [#9, ' ']) do Inc(P);
    if (P < PEnd) and not (P^ in [#10, #13, '#']) then
    begin
      SetError(tecInvalidToml, 'Trailing characters after value');
      Exit(False);
    end;
    if (P < PEnd) and (P^ = '#') then SkipComment;
    while (P < PEnd) and (P^ in [#10, #13]) do Inc(P);
  end;

  LDoc := TTomlSimpleDocument.CreateWithRoot(LRoot as ITomlTable);
  // end parse
  ADoc := LDoc;
  Result := True;
end;

function ValidateDocLimits(const ADoc: ITomlDocument; const ALimits: TTomlLimits; out AErr: TTomlError): Boolean;
  function TraverseValue(const V: ITomlValue; Depth: SizeUInt; var KeyCount: SizeUInt): Boolean;
  var
    T: ITomlTable;
    A: ITomlArray;
    I: SizeInt;
    K: String;
    Child: ITomlValue;
    S: String;
  begin
    Result := True;
    if V = nil then Exit(True);
    if (ALimits.MaxDepth > 0) and (Depth > ALimits.MaxDepth) then
    begin
      SetErrorAtStart(AErr, tecLimitExceeded, 'document exceeds max depth limit');
      Exit(False);
    end;
    case V.GetType of
      tvtTable:
        begin
          T := (V as ITomlTable);
          for I := 0 to T.KeyCount - 1 do
          begin
            K := T.KeyAt(I);
            Inc(KeyCount);
            if (ALimits.MaxKeys > 0) and (KeyCount > ALimits.MaxKeys) then
            begin
              SetErrorAtStart(AErr, tecLimitExceeded, 'document exceeds max keys limit');
              Exit(False);
            end;
            Child := T.GetValue(K);
            if not TraverseValue(Child, Depth + 1, KeyCount) then Exit(False);
          end;
        end;
      tvtArray:
        begin
          A := (V as ITomlArray);
          for I := 0 to A.Count - 1 do
          begin
            Child := A.Item(I);
            if not TraverseValue(Child, Depth + 1, KeyCount) then Exit(False);
          end;
        end;
      tvtString:
        begin
          if V.TryGetString(S) then
          begin
            if (ALimits.MaxStringBytes > 0) and (Length(S) > ALimits.MaxStringBytes) then
            begin
              SetErrorAtStart(AErr, tecLimitExceeded, 'string value exceeds max length limit');
              Exit(False);
            end;
          end;
        end;
    else
      // scalars ok
    end;
    Result := True;
  end;
var
  Root: ITomlTable;
  Cnt: SizeUInt;
begin
  AErr.Clear;
  if ADoc = nil then Exit(True);
  Root := ADoc.GetRoot;
  if Root = nil then Exit(True);
  Cnt := 0;
  Result := TraverseValue(Root as ITomlValue, 1, Cnt);
end;


function ParseStream(const AStream: TStream; out ADoc: ITomlDocument; out AErr: TTomlError; const AFlags: TTomlReadFlags): Boolean;
var
  LSS: TStringStream;
  LText: RawByteString;
  rem: Int64;
  Lims: TTomlLimits;
  MS: TMemoryStream;
  LSize: SizeInt;
begin
  AErr.Clear;
  LText := '';
  if (AStream = nil) then
  begin
    // 参数错误：统一使用 SetErrorAtStart 标准化定位（Position=0, Line=1, Column=1）
    SetErrorAtStart(AErr, tecInvalidParameter, 'Stream is nil');
    Exit(False);
  end;
  // 流大小快速探测（仅文件流），避免读取过大输入
  try
    if AStream is TFileStream then
    begin
      rem := (AStream as TFileStream).Size;
      // 默认限额（仅用于 ParseStream 的预检；非强制）
      Lims.MaxInputBytes := 8 * 1024 * 1024;
      Lims.MaxDepth := 256;
      Lims.MaxKeys := 100000;
      Lims.MaxStringBytes := 1 * 1024 * 1024;
      if (Lims.MaxInputBytes > 0) and (rem > Lims.MaxInputBytes) then
      begin
        SetErrorAtStart(AErr, tecLimitExceeded, 'input exceeds configured size limit');
        Exit(False);
      end;
    end;
  except
    // ignore probing errors
  end;
  // 将流读入内存（原始字节，不做编码转换；后续可做增量/零拷贝优化）
  MS := TMemoryStream.Create;
  try
    MS.CopyFrom(AStream, 0);
    LSize := MS.Size;
    if LSize > 0 then
    begin
      SetLength(LText, LSize);
      Move(PByte(MS.Memory)^, LText[1], LSize);
    end
    else
      LText := '';
  finally
    MS.Free;
  end;
  Result := Parse(LText, ADoc, AErr, AFlags);
end;

function ParseFile(const AFileName: String; out ADoc: ITomlDocument; out AErr: TTomlError; const AFlags: TTomlReadFlags): Boolean;
var
  LFS: TFileStream;
begin
  AErr.Clear;
  if (AFileName = '') or (not FileExists(AFileName)) then
  begin
    // 参数/IO 错误：统一使用 SetErrorAtStart 标准化定位（Position=0, Line=1, Column=1）
    SetErrorAtStart(AErr, tecFileIO, 'File not found');
    Exit(False);
  end;
  LFS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    Result := ParseStream(LFS, ADoc, AErr, AFlags);
  finally
    LFS.Free;
  end;
end;

function ToToml(const ADoc: ITomlDocument; const AFlags: TTomlWriteFlags): RawByteString;
  function EscapeString(const S: String): String; inline;
  var
    I: SizeInt;
    C: Char;
    R: String;
    P, Cap: SizeInt;
    procedure EnsureCap(Need: SizeInt); inline;
    begin
      if Need <= Cap then Exit;
      if Cap = 0 then Cap := 16;
      while Cap < Need do Cap := Cap * 2;
      SetLength(R, Cap);
    end;
    procedure AppendChar(ch: Char); inline;
    begin
      Inc(P); EnsureCap(P);
      R[P] := ch;
    end;
    procedure Append2(a,b: Char); inline;
    begin
      EnsureCap(P+2);
      Inc(P); R[P] := a;
      Inc(P); R[P] := b;
    end;
    procedure AppendUnicode4(code: Integer); inline;
    const HEX: String = '0123456789abcdef';
    begin
      EnsureCap(P+6);
      Inc(P); R[P] := '\';
      Inc(P); R[P] := 'u';
      Inc(P); R[P] := HEX[((code shr 12) and $F)+1];
      Inc(P); R[P] := HEX[((code shr 8) and $F)+1];
      Inc(P); R[P] := HEX[((code shr 4) and $F)+1];
      Inc(P); R[P] := HEX[(code and $F)+1];
    end;
  begin
    P := 0; Cap := 0; SetLength(R, 0);
    for I := 1 to Length(S) do
    begin
      C := S[I];
      case C of
        '"':  Append2('\','"');
        '\':  Append2('\','\');
        #10:  Append2('\','n');
        #13:  Append2('\','r');
        #9:   Append2('\','t');
        #8:   Append2('\','b');
        #12:  Append2('\','f');
      else
        if Ord(C) < 32 then
          AppendUnicode4(Ord(C))
        else
          AppendChar(C);
      end;
    end;
    SetLength(R, P);
    Result := R;
  end;

  function NeedsQuotingKey(const S: String): Boolean; inline;
  var I: SizeInt; C: Char;
  begin
    if S = '' then Exit(True);
    for I := 1 to Length(S) do
    begin
      C := S[I];
      if not (C in ['A'..'Z','a'..'z','0'..'9','_','-']) then Exit(True);
    end;
    Result := False;
  end;

  function RenderKey(const S: String): String; inline;
  begin
    if NeedsQuotingKey(S) then
      Result := '"' + EscapeString(S) + '"'
    else
      Result := S;
  end;
var
  Lines: TStringList;
  OutBuf: String;
  Root: ITomlTable;

  function IsArrayOfTables(const V: ITomlValue): Boolean; inline;
  var A: ITomlArray; i: SizeInt; item: ITomlValue;
  begin
    Result := False;
    if (V = nil) or (V.GetType <> tvtArray) then Exit(False);
    A := (V as ITomlArray);
    if A.Count = 0 then Exit(False);
    for i := 0 to A.Count - 1 do
    begin
      item := A.Item(i);
      if (item = nil) or (item.GetType <> tvtTable) then Exit(False);
    end;
    Result := True;
  end;

  function IsScalar(const V: ITomlValue): Boolean; inline;
  begin
    if V = nil then Exit(False);
    case V.GetType of
      tvtArray: Exit(not IsArrayOfTables(V));
      tvtString, tvtInteger, tvtFloat, tvtBoolean,
      tvtOffsetDateTime, tvtLocalDateTime, tvtLocalDate, tvtLocalTime: Exit(True);
    else
      Exit(False);
    end;
  end;

  procedure AppendLine(const S: String); inline;
  begin
    Lines.Add(S);
  end;

  procedure AppendBlank; inline;
  var last: String;
  begin
    if Lines.Count = 0 then Exit;
    last := Lines[Lines.Count-1];
    if last <> '' then Lines.Add('');
  end;


  function EqStr: String; inline;
  begin
    // 等号风格：
    // - 默认更可读（key = value）
    // - twfTightEquals 时为紧凑等号（key=value）
    // - 当同时指定 twfTightEquals 与 twfSpacesAroundEquals，以 Tight 优先
    if (twfTightEquals in AFlags) then
      Result := '='
    else
      Result := ' = ';
  end;

  function ScalarToText(const V: ITomlValue): String;
  var
    // compatibility temporaries for FPC <= 3.2 that dislike inline var
    varBody: String; C2: Char;
    Ls: String; Li: Int64; Lb: Boolean; Lf: Double; FS: TFormatSettings;
    // 避免内联 var 的临时变量
    A2: ITomlArray; k2: SizeInt; parts2: String; item2: ITomlValue;
  begin
    case V.GetType of
      tvtString:
        begin
          if V.TryGetString(Ls) then
          begin
            // 始终使用基本字符串并进行必要转义，避免多行字符串影响快照稳定性
            Exit('"' + EscapeString(Ls) + '"');
          end
          else Exit('""');
        end;
      tvtInteger: if V.TryGetInteger(Li) then Exit(IntToStr(Li)) else Exit('0');
      tvtBoolean: if V.TryGetBoolean(Lb) then begin if Lb then Exit('true') else Exit('false'); end else Exit('false');
      tvtFloat:
        begin
          if V.TryGetFloat(Lf) then
          begin
            // 使用固定小数点或指数形式；尽量使用 '.' 作为小数点
            FS := DefaultFormatSettings; FS.DecimalSeparator := '.';
            Result := FloatToStr(Lf, FS);
            if (Pos('.', Result) = 0) and (Pos('e', Result) = 0) and (Pos('E', Result) = 0) then
              Result := Result + '.0';
            Exit(Result);
          end
          else Exit('0.0');
        end;
      tvtOffsetDateTime, tvtLocalDateTime, tvtLocalDate, tvtLocalTime:
        begin
          if V.TryGetTemporalText(Ls) then Exit(Ls)
          else raise Exception.Create('Temporal value missing text');
        end;
      tvtArray:
        begin
          // 递归输出：支持标量与嵌套数组
          A2 := (V as ITomlArray);
          k2 := 0; parts2 := '';
          while k2 < A2.Count do
          begin
            if parts2 <> '' then parts2 := parts2 + ', ';
            item2 := A2.Item(k2);
            // 嵌套数组：递归渲染
            if (item2 <> nil) and (item2.GetType = tvtArray) then
            begin
              parts2 := parts2 + ScalarToText(item2);
            end
            else if item2.TryGetString(Ls) then parts2 := parts2 + '"' + EscapeString(Ls) + '"'
            else if item2.TryGetBoolean(Lb) then begin if Lb then parts2 := parts2 + 'true' else parts2 := parts2 + 'false'; end
            else if item2.TryGetFloat(Lf) then
            begin
              FS := DefaultFormatSettings; FS.DecimalSeparator := '.';
              Ls := FloatToStr(Lf, FS);
              if (Pos('.', Ls) = 0) and (Pos('e', Ls) = 0) and (Pos('E', Ls) = 0) then
                Ls := Ls + '.0';
              parts2 := parts2 + Ls;
            end
            else if item2.TryGetInteger(Li) then parts2 := parts2 + IntToStr(Li)
            else parts2 := parts2 + '0';
            Inc(k2);
          end;
          Exit('[' + parts2 + ']');
        end;
    else
      Exit('""');
    end;
  end;

  procedure WriteTable(const Path: String; const T: ITomlTable);
  type
    TIdxArray = array of SizeInt;
  var
    I, J: SizeInt;
    K: String;
    V: ITomlValue;
    SubPath: String;
    A2: ITomlArray;
    k2: SizeInt;

    function LessKey(const A, B: SizeInt): Boolean; inline;
    var
      Sa, Sb: String;
      Qa, Qb: Boolean;
    begin
      Sa := T.KeyAt(A);
      Sb := T.KeyAt(B);
      // 自定义排序：未需引号的键优先，其次按字典序
      // 这样可使 "host", "port" 排在需要引号的 "user name" 之前
      if (twfSortKeys in AFlags) then
      begin
        Qa := NeedsQuotingKey(Sa);
        Qb := NeedsQuotingKey(Sb);
        if Qa <> Qb then Exit(Qa = False);
      end;
      Result := Sa < Sb;
    end;

    procedure SortIndexes(var A: TIdxArray; L, R: Integer);
    var
      I2, J2, P, Tmp: Integer;
    begin
      if L >= R then Exit;
      I2 := L; J2 := R; P := A[(L+R) shr 1];
      repeat
        while LessKey(A[I2], P) do Inc(I2);
        while LessKey(P, A[J2]) do Dec(J2);
        if I2 <= J2 then begin Tmp := A[I2]; A[I2] := A[J2]; A[J2] := Tmp; Inc(I2); Dec(J2); end;
      until I2 > J2;
      if L < J2 then SortIndexes(A, L, J2);
      if I2 < R then SortIndexes(A, I2, R);
    end;

    function BuildIndexes(const OnlyScalars: Boolean): TIdxArray;
    var
      Count: Integer;
    begin
      Result := nil;
      if T = nil then Exit;
      // 先统计数量以便分配
      Count := 0;
      I := 0;
      while I <= T.KeyCount - 1 do
      begin
        V := T.GetValue(T.KeyAt(I));
        if OnlyScalars then
        begin
          if IsScalar(V) then Inc(Count);
        end
        else
        begin
          if (V <> nil) and (V.GetType = tvtTable) then Inc(Count);
        end;
        Inc(I);
      end;
      SetLength(Result, Count);
      // 填充索引
      J := 0;






      I := 0;
      while I <= T.KeyCount - 1 do
      begin
        V := T.GetValue(T.KeyAt(I));
        if OnlyScalars then
        begin
          if IsScalar(V) then begin Result[J] := I; Inc(J); end;
        end
        else
        begin
          if (V <> nil) and (V.GetType = tvtTable) then begin Result[J] := I; Inc(J); end;
        end;
        Inc(I);
      end;
      // 可选排序
      if (Length(Result) > 1) and (twfSortKeys in AFlags) then
        SortIndexes(Result, 0, High(Result));
    end;

    function BuildAoTIndexes: TIdxArray;
    var
      Count: Integer;
    begin
      Result := nil;
      if T = nil then Exit;
      Count := 0;
      I := 0;
      while I <= T.KeyCount - 1 do
      begin
        V := T.GetValue(T.KeyAt(I));
        if IsArrayOfTables(V) then Inc(Count);
        Inc(I);
      end;
      SetLength(Result, Count);
      J := 0;
      I := 0;
      while I <= T.KeyCount - 1 do
      begin
        V := T.GetValue(T.KeyAt(I));
        if IsArrayOfTables(V) then begin Result[J] := I; Inc(J); end;
        Inc(I);
      end;
      if (Length(Result) > 1) and (twfSortKeys in AFlags) then
        SortIndexes(Result, 0, High(Result));
    end;


  var
    Idx: TIdxArray;
  begin
    if T = nil then Exit;

    // 1) 本表中的标量键（优先输出）
    Idx := BuildIndexes(True);
    J := 0;
    while J <= High(Idx) do
    begin
      K := T.KeyAt(Idx[J]); V := T.GetValue(K);
      // TODO(nav.Writer.EmitScalar):
      // - 顺序：标量优先；其次 AoT；最后子表（递归同规则）
      // - 等号风格：由 EqStr 决定，当前默认含空格；twfSpacesAroundEquals 预留开关
      AppendLine(RenderKey(K) + EqStr + ScalarToText(V));
      Inc(J);
    end;
    // 2) 数组表 [[path]]（优先输出）
    Idx := BuildAoTIndexes;
    J := 0;
    while J <= High(Idx) do
    begin
      K := T.KeyAt(Idx[J]); V := T.GetValue(K);
      if Path = '' then SubPath := RenderKey(K) else SubPath := Path + '.' + RenderKey(K);
      A2 := (V as ITomlArray);
      k2 := 0;
      while k2 < A2.Count do
      begin
        // TODO(nav.Writer.Pretty.BlankLines):
        // - 在节段之间插入空行（标量→AoT、AoT→子表、子表→下一个子表组）
        // - 根级“最后一个标量”与第一个表头之间也插入一个空行（见 tests）
        if (twfPretty in AFlags) then AppendBlank;
        AppendLine('[[' + SubPath + ']]');
        WriteTable(SubPath, (A2.Item(k2) as ITomlTable));
        Inc(k2);
      end;
      Inc(J);
    end;

    // 3) 子表（常规）
    Idx := BuildIndexes(False);
    J := 0;
    while J <= High(Idx) do
    begin
      K := T.KeyAt(Idx[J]); V := T.GetValue(K);
      if Path = '' then SubPath := RenderKey(K) else SubPath := Path + '.' + RenderKey(K);
      if (V <> nil) and (V.GetType = tvtTable) then
      begin
        // TODO(nav.Writer.Pretty.BlankLines.Subtables): 子表表头连续输出前插入空行
        if (twfPretty in AFlags) then AppendBlank;
        AppendLine('[' + SubPath + ']');
        WriteTable(SubPath, V as ITomlTable);
      end;
      Inc(J);
    end;
  end;

begin
  Lines := TStringList.Create;
  try
    if (ADoc = nil) then Exit(RawByteString(''));
    Root := ADoc.GetRoot;
    if Root = nil then Exit(RawByteString(''));
    WriteTable('', Root);
    OutBuf := Lines.Text;
    // 去掉最后一个自动附加的行结束符，使之与原行为一致（末尾无换行）
    if (Length(OutBuf) >= Length(LineEnding)) and
       (Copy(OutBuf, Length(OutBuf)-Length(LineEnding)+1, Length(LineEnding)) = LineEnding) then
      SetLength(OutBuf, Length(OutBuf)-Length(LineEnding));
    Result := RawByteString(OutBuf);
  finally
    Lines.Free;
  end;
end;

function GetString(const ADoc: ITomlDocument; const APath, ADefault: String): String;
var
  T: ITomlTable; V: ITomlValue; Seg: String; P, PEnd: PChar;
begin
  Result := ADefault;
  if (ADoc = nil) or (ADoc.GetRoot = nil) then Exit;


  T := ADoc.GetRoot;
  P := PChar(APath); PEnd := P + Length(APath); Seg := '';
  while (P < PEnd) and (P^ <> '.') do begin Seg := Seg + P^; Inc(P); end;
  while (P < PEnd) do
  begin
    V := T.GetValue(Seg);
    if (V = nil) or (V.GetType <> tvtTable) then Exit;
    T := (V as ITomlTable);
    Inc(P); Seg := '';
    while (P < PEnd) and (P^ <> '.') do begin Seg := Seg + P^; Inc(P); end;
  end;
  V := T.GetValue(Seg);
  if (V <> nil) and V.TryGetString(Result) then Exit;
end;

function GetInt(const ADoc: ITomlDocument; const APath: String; const ADefault: Int64): Int64;
var
  T: ITomlTable; V: ITomlValue; Seg: String; P, PEnd: PChar; TmpI: Int64;
begin
  Result := ADefault;
  if (ADoc = nil) or (ADoc.GetRoot = nil) then Exit;
  T := ADoc.GetRoot;
  P := PChar(APath); PEnd := P + Length(APath); Seg := '';
  while (P < PEnd) and (P^ <> '.') do begin Seg := Seg + P^; Inc(P); end;
  while (P < PEnd) do
  begin
    V := T.GetValue(Seg);
    if (V = nil) or (V.GetType <> tvtTable) then Exit;
    T := (V as ITomlTable);
    Inc(P); Seg := '';
    while (P < PEnd) and (P^ <> '.') do begin Seg := Seg + P^; Inc(P); end;
  end;
  V := T.GetValue(Seg);
  if (V <> nil) and V.TryGetInteger(TmpI) then Result := TmpI;
end;

function GetBool(const ADoc: ITomlDocument; const APath: String; const ADefault: Boolean): Boolean;
var
  T: ITomlTable; V: ITomlValue; Seg: String; P, PEnd: PChar; TmpB: Boolean;
begin
  Result := ADefault;
  if (ADoc = nil) or (ADoc.GetRoot = nil) then Exit;
  T := ADoc.GetRoot;
  P := PChar(APath); PEnd := P + Length(APath); Seg := '';
  while (P < PEnd) and (P^ <> '.') do begin Seg := Seg + P^; Inc(P); end;
  while P < PEnd do
  begin
    V := T.GetValue(Seg);
    if (V = nil) or (V.GetType <> tvtTable) then Exit;
    T := (V as ITomlTable);
    Inc(P); Seg := '';
    while (P < PEnd) and (P^ <> '.') do begin Seg := Seg + P^; Inc(P); end;
  end;
  V := T.GetValue(Seg);
  if (V <> nil) and V.TryGetBoolean(TmpB) then Result := TmpB;
end;

function TryGetValue(const ADoc: ITomlDocument; const APath: String; out AValue: ITomlValue): Boolean;
var
  T: ITomlTable; V: ITomlValue; Seg: String; P, PEnd: PChar;
begin
  Result := False;
  AValue := nil;
  if (ADoc = nil) or (ADoc.GetRoot = nil) then Exit;
  T := ADoc.GetRoot;
  P := PChar(APath); PEnd := P + Length(APath); Seg := '';
  while (P < PEnd) and (P^ <> '.') do begin Seg := Seg + P^; Inc(P); end;
  while (P < PEnd) do
  begin
    V := T.GetValue(Seg);
    if (V = nil) or (V.GetType <> tvtTable) then Exit;
    T := (V as ITomlTable);
    Inc(P); Seg := '';
    while (P < PEnd) and (P^ <> '.') do begin Seg := Seg + P^; Inc(P); end;
  end;
  V := T.GetValue(Seg);
  if V <> nil then begin AValue := V; Result := True; end;
end;

function Has(const ADoc: ITomlDocument; const APath: String): Boolean;
var
  V: ITomlValue;
begin
  Result := TryGetValue(ADoc, APath, V);
end;


function TryGetString(const ADoc: ITomlDocument; const APath: String; out AValue: String): Boolean;
var
  T: ITomlTable; V: ITomlValue; Seg: String; P, PEnd: PChar;
begin
  Result := False;
  AValue := '';
  if (ADoc = nil) or (ADoc.GetRoot = nil) then Exit;
  T := ADoc.GetRoot;
  P := PChar(APath); PEnd := P + Length(APath); Seg := '';
  while (P < PEnd) and (P^ <> '.') do begin Seg := Seg + P^; Inc(P); end;
  while (P < PEnd) do
  begin
    V := T.GetValue(Seg);
    if (V = nil) or (V.GetType <> tvtTable) then Exit;
    T := (V as ITomlTable);
    Inc(P); Seg := '';
    while (P < PEnd) and (P^ <> '.') do begin Seg := Seg + P^; Inc(P); end;
  end;
  V := T.GetValue(Seg);
  if (V <> nil) and V.TryGetString(AValue) then Result := True;
end;

function TryGetInt(const ADoc: ITomlDocument; const APath: String; out AValue: Int64): Boolean;
var
  T: ITomlTable; V: ITomlValue; Seg: String; P, PEnd: PChar; Tmp: Int64;
begin
  Result := False;
  AValue := 0;
  if (ADoc = nil) or (ADoc.GetRoot = nil) then Exit;
  T := ADoc.GetRoot;
  P := PChar(APath); PEnd := P + Length(APath); Seg := '';
  while (P < PEnd) and (P^ <> '.') do begin Seg := Seg + P^; Inc(P); end;
  while (P < PEnd) do
  begin
    V := T.GetValue(Seg);
    if (V = nil) or (V.GetType <> tvtTable) then Exit;
    T := (V as ITomlTable);
    Inc(P); Seg := '';
    while (P < PEnd) and (P^ <> '.') do begin Seg := Seg + P^; Inc(P); end;
  end;
  V := T.GetValue(Seg);
  if (V <> nil) and V.TryGetInteger(Tmp) then begin AValue := Tmp; Result := True; end;
end;

function TryGetBool(const ADoc: ITomlDocument; const APath: String; out AValue: Boolean): Boolean;
var
  T: ITomlTable; V: ITomlValue; Seg: String; P, PEnd: PChar; Tmp: Boolean;
begin
  Result := False;
  AValue := False;
  if (ADoc = nil) or (ADoc.GetRoot = nil) then Exit;
  T := ADoc.GetRoot;
  P := PChar(APath); PEnd := P + Length(APath); Seg := '';
  while (P < PEnd) and (P^ <> '.') do begin Seg := Seg + P^; Inc(P); end;
  while (P < PEnd) do
  begin
    V := T.GetValue(Seg);
    if (V = nil) or (V.GetType <> tvtTable) then Exit;
    T := (V as ITomlTable);
    Inc(P); Seg := '';
    while (P < PEnd) and (P^ <> '.') do begin Seg := Seg + P^; Inc(P); end;
  end;
  V := T.GetValue(Seg);
  if (V <> nil) and V.TryGetBoolean(Tmp) then begin AValue := Tmp; Result := True; end;
end;



end.

