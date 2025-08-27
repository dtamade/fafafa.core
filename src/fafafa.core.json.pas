unit fafafa.core.json;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.types,
  fafafa.core.json.ptr;

type
  EJsonValueError = class(Exception)
  private
    FCode: TJsonErrorCode;
  public
    constructor Create(ACode: TJsonErrorCode; const AMsg: string);
    property Code: TJsonErrorCode read FCode;
  end;

  EJsonParseError = class(Exception)
  private
    FCode: TJsonErrorCode;
    FPosition: SizeUInt;
    FLine: SizeUInt;
    FColumn: SizeUInt;
  public
    constructor Create(ACode: TJsonErrorCode; const AMsg: string; APos, ALine, ACol: SizeUInt);
    property Code: TJsonErrorCode read FCode;
    property Position: SizeUInt read FPosition;
    property Line: SizeUInt read FLine;
    property Column: SizeUInt read FColumn;
  end;

  IJsonValue = interface
    ['{B19C3E9F-1B3E-4A5A-9B7F-2C6D8F0A1B2C}']
    function GetType: TJsonValueType;
    function IsNull: Boolean;
    function IsBoolean: Boolean;
    function IsNumber: Boolean;
    function IsInteger: Boolean;
    function IsUInteger: Boolean;
    function IsString: Boolean;
    function IsArray: Boolean;
    function IsObject: Boolean;
    function GetBoolean: Boolean;
    function GetInteger: Int64;
    function GetUInteger: UInt64;
    function GetFloat: Double;
    function GetString: String;
    function GetUtf8String: UTF8String;
    function GetStringLength: SizeUInt;
    function GetArraySize: SizeUInt;
    function GetArrayItem(AIndex: SizeUInt): IJsonValue;
    function GetObjectSize: SizeUInt;
    function GetObjectValue(const AKey: String): IJsonValue;
    function GetObjectValueN(const AKey: PChar; AKeyLen: SizeUInt): IJsonValue;
    function HasObjectKey(const AKey: String): Boolean;
    function HasObjectKeyN(const AKey: PChar; AKeyLen: SizeUInt): Boolean;
  end;

  IJsonDocument = interface
    ['{A1B2C3D4-E5F6-1234-ABCD-567890ABCDEF}']
    function GetRoot: IJsonValue;
    function GetAllocator: TAllocator;
    function GetBytesRead: SizeUInt;
    function GetValuesRead: SizeUInt;
    property Root: IJsonValue read GetRoot;
    property Allocator: TAllocator read GetAllocator;
    property BytesRead: SizeUInt read GetBytesRead;
    property ValuesRead: SizeUInt read GetValuesRead;
  end;

  IJsonReader = interface
    ['{F7C4BFD5-848B-46F3-9E68-DC2A1BCA5D85}']
    function ReadFromString(const AJson: String; AFlags: TJsonReadFlags = []): IJsonDocument;
    function ReadFromStringN(const AJson: PChar; ALength: SizeUInt; AFlags: TJsonReadFlags = []): IJsonDocument;
    function ReadFromFile(const APath: String; AFlags: TJsonReadFlags = []): IJsonDocument;
    function ReadFromStream(AStream: TStream; AFlags: TJsonReadFlags = []): IJsonDocument;
  end;

  IJsonWriter = interface
    ['{E7E2A7C1-6B1C-4E5D-8BB0-7D73F1E9D5A1}']
    function WriteToString(ADocument: IJsonDocument; AFlags: TJsonWriteFlags = []): String;
    function WriteToFile(ADocument: IJsonDocument; const APath: String; AFlags: TJsonWriteFlags = []): Boolean;
    function WriteToStream(ADocument: IJsonDocument; AStream: TStream; AFlags: TJsonWriteFlags = []): Boolean;
  end;

  // Streaming Reader（分块喂入，无异常返回）
  IJsonStreamReader = interface
    ['{9B99CB8C-0C9C-4F66-9B2E-3B4B9E2E3F77}']
    // 向增量缓冲喂入数据片段（不拷贝调用方缓冲，内部持有一块固定缓冲）
    // 返回值：0 表示成功；非 0 表示错误码（jecInvalidParameter 等）
    function Feed(const AChunk: PChar; ALength: SizeUInt): Integer;
    // 尝试解析当前缓冲，成功则返回 0 并产出文档；若需要更多数据返回 jecMore
    function TryRead(out ADoc: IJsonDocument): Integer;
    // 复位状态（可选）
    procedure Reset;
  end;

  // 工厂
  function NewJsonStreamReader(ABufferCapacity: SizeUInt; AAllocator: TAllocator = nil; AFlags: TJsonReadFlags = []): IJsonStreamReader;
  // 可选：Reader/Writer 配置对象（资源限额等）
  TJsonReadOptions = record
    Flags: TJsonReadFlags;
    MaxDepth: SizeUInt;       // 0 表示不限制
    MaxValues: SizeUInt;      // 0 表示不限制
    MaxStringBytes: SizeUInt; // 0 表示不限制
    MaxDocBytes: SizeUInt;    // 0 表示不限制
    class function Default: TJsonReadOptions; static;
  end;

  TJsonWriteOptions = record
    Flags: TJsonWriteFlags;
    MaxDepth: SizeUInt; // 0 表示不限制；预留，Writer 遍历防止异常深度
    class function Default: TJsonWriteOptions; static;
  end;

  function NewJsonReader(AAllocator: TAllocator = nil): IJsonReader;
  function NewJsonWriter: IJsonWriter;
  function CreateJsonReader(AAllocator: TAllocator = nil): IJsonReader; deprecated 'Use NewJsonReader';
  function CreateJsonWriter: IJsonWriter; deprecated 'Use NewJsonWriter';
  function NewJsonStreamReader(ABufferCapacity: SizeUInt; AAllocator: TAllocator = nil; AFlags: TJsonReadFlags = []): IJsonStreamReader;
  // 可选重载：从 Options 构造 Reader（未来扩展）
  // function NewJsonReaderWithOptions(const Opt: TJsonReadOptions; AAllocator: TAllocator = nil): IJsonReader;


// 工厂（与框架风格对齐，提供 New*，保留 Create* 兼容）
function NewJsonReader(AAllocator: TAllocator = nil): IJsonReader;
function NewJsonWriter: IJsonWriter;
function CreateJsonReader(AAllocator: TAllocator = nil): IJsonReader; deprecated 'Use NewJsonReader';
function CreateJsonWriter: IJsonWriter; deprecated 'Use NewJsonWriter';
// 将 fixed 文档包装为 IJsonDocument（接口持有并释放底层文档）
function JsonWrapDocument(ADoc: TJsonDocument): IJsonDocument;
// JSON Pointer 便捷方法（只读）：基于接口包装，内部委派到 fixed.ptr
function JsonPointerGet(ARoot: IJsonValue; const APointer: String): IJsonValue; overload;
function JsonPointerGet(ADoc: IJsonDocument; const APointer: String): IJsonValue; overload;

// 便捷 TryGet：对象键查找
function JsonTryGetObjectValue(ARoot: IJsonValue; const AKey: String; out AOut: IJsonValue): Boolean;
// 便捷 TryGet：数组索引
function JsonTryGetArrayItem(ARoot: IJsonValue; AIndex: SizeUInt; out AOut: IJsonValue): Boolean;

  type

  // for-in support: key-value pairs
  TJsonObjectPair = record
    Key: String;
    Value: IJsonValue;
  end;
  TJsonObjectPairUtf8 = record
    Key: UTF8String;
    Value: IJsonValue;
  end;

  // for-in enumerators (array)
  TJsonArrayEnumerator = record
  private
    FRoot: IJsonValue;
    FIter: TJsonArrayIterator;
    FInited: Boolean;
    FCurrent: IJsonValue;
  public
    function MoveNext: Boolean;
    function GetCurrent: IJsonValue;
    property Current: IJsonValue read GetCurrent;
  end;

  TJsonArrayEnumerable = record
    FRoot: IJsonValue;
    function GetEnumerator: TJsonArrayEnumerator;
  end;

  // for-in enumerators (object -> String key)
  TJsonObjectEnumerator = record
  private
    FRoot: IJsonValue;
    FIter: TJsonObjectIterator;
    FInited: Boolean;
    FCurrent: TJsonObjectPair;
  public
    function MoveNext: Boolean;
    function GetCurrent: TJsonObjectPair;
    property Current: TJsonObjectPair read GetCurrent;
  end;

  TJsonObjectEnumerable = record
    FRoot: IJsonValue;
    function GetEnumerator: TJsonObjectEnumerator;
  end;

  // for-in enumerators (object -> UTF8String key)
  TJsonObjectEnumeratorUtf8 = record
  private
    FRoot: IJsonValue;
    FIter: TJsonObjectIterator;
    FInited: Boolean;
    FCurrent: TJsonObjectPairUtf8;
  public
    function MoveNext: Boolean;
    function GetCurrent: TJsonObjectPairUtf8;
    property Current: TJsonObjectPairUtf8 read GetCurrent;
  end;

  TJsonObjectEnumerableUtf8 = record
    FRoot: IJsonValue;
    function GetEnumerator: TJsonObjectEnumeratorUtf8;
  end;

  // constructors for for-in
  function JsonArrayItems(ARoot: IJsonValue): TJsonArrayEnumerable;
  function JsonObjectPairs(ARoot: IJsonValue): TJsonObjectEnumerable;
  function JsonObjectPairsUtf8(ARoot: IJsonValue): TJsonObjectEnumerableUtf8;

type
  // 迭代器回调（返回 False 以提前停止遍历）
  TJsonArrayEachFunc = reference to function(Index: SizeUInt; Item: IJsonValue): Boolean;
  TJsonObjectEachFunc = reference to function(const Key: String; Value: IJsonValue): Boolean;

  TJsonObjectEachRawFunc = reference to function(KeyPtr: PChar; KeyLen: SizeUInt; Value: IJsonValue): Boolean;

// 遍历便捷函数：返回 False 表示参数非法或不是对应容器
function JsonArrayForEach(ARoot: IJsonValue; AEach: TJsonArrayEachFunc): Boolean;
function JsonObjectForEach(ARoot: IJsonValue; AEach: TJsonObjectEachFunc): Boolean;

function JsonObjectForEachRaw(ARoot: IJsonValue; AEach: TJsonObjectEachRawFunc): Boolean;


  // Typed TryGet helpers
  function JsonTryGetInt(ARoot: IJsonValue; out AOut: Int64): Boolean;
  function JsonTryGetUInt(ARoot: IJsonValue; out AOut: UInt64): Boolean;
  function JsonTryGetBool(ARoot: IJsonValue; out AOut: Boolean): Boolean;
  function JsonTryGetFloat(ARoot: IJsonValue; out AOut: Double): Boolean;
  function JsonTryGetStr(ARoot: IJsonValue; out AOut: String): Boolean;
  function JsonTryGetUtf8(ARoot: IJsonValue; out AOut: UTF8String): Boolean;

  // OrDefault helpers (no exception thrown)
  function JsonGetIntOrDefault(ARoot: IJsonValue; ADefault: Int64 = 0): Int64;
  function JsonGetUIntOrDefault(ARoot: IJsonValue; ADefault: UInt64 = 0): UInt64;
  function JsonGetBoolOrDefault(ARoot: IJsonValue; ADefault: Boolean = False): Boolean;
class function TJsonReadOptions.Default: TJsonReadOptions;
begin
  Result.Flags := [];
  Result.MaxDepth := 512;
  Result.MaxValues := 1_000_000;
  Result.MaxStringBytes := 16 * 1024 * 1024; // 16MB
  Result.MaxDocBytes := 128 * 1024 * 1024;   // 128MB
end;

class function TJsonWriteOptions.Default: TJsonWriteOptions;
begin
  Result.Flags := [];
  Result.MaxDepth := 1024;
end;

  function JsonGetFloatOrDefault(ARoot: IJsonValue; ADefault: Double = 0.0): Double;
  function JsonGetStrOrDefault(ARoot: IJsonValue; const ADefault: String = ''): String;
  // UTF-8 friendly OrDefault
  function JsonGetUtf8OrDefault(ARoot: IJsonValue; const ADefault: UTF8String = ''): UTF8String;
  // UTF-8 key helpers (avoid String codepage roundtrips)
  function JsonHasKeyUtf8(ARoot: IJsonValue; const AKey: UTF8String): Boolean;
  function JsonGetValueUtf8(ARoot: IJsonValue; const AKey: UTF8String): IJsonValue;


  // Pointer + default helpers
  function JsonGetIntOrDefaultByPtr(ARoot: IJsonValue; const APointer: String; ADefault: Int64 = 0): Int64;
  function JsonGetUIntOrDefaultByPtr(ARoot: IJsonValue; const APointer: String; ADefault: UInt64 = 0): UInt64;
  function JsonGetBoolOrDefaultByPtr(ARoot: IJsonValue; const APointer: String; ADefault: Boolean = False): Boolean;
  function JsonGetFloatOrDefaultByPtr(ARoot: IJsonValue; const APointer: String; ADefault: Double = 0.0): Double;
  function JsonGetStrOrDefaultByPtr(ARoot: IJsonValue; const APointer: String; const ADefault: String = ''): String;
  function JsonGetUtf8OrDefaultByPtr(ARoot: IJsonValue; const APointer: String; const ADefault: UTF8String = ''): UTF8String;



implementation

uses
  fafafa.core.json.errors,
  fafafa.core.json.incr;


// Internal bridge interfaces used only inside this unit
// They must be declared before classes that implement them.
type
  IJsonDocumentIntf = interface
    ['{5F5A5D2E-9A6F-4B13-9C2B-7E0B5E5F2C11}']
    function GetDoc: TJsonDocument;
  end;
  IJsonValueIntf = interface
    ['{9A3C4D5E-6F70-4213-8B9C-0A1B2C3D4E5F}']
    function GetRaw: PJsonValue;
    function GetDoc: TJsonDocument;
    function GetOwnerIntf: IJsonDocumentIntf; // keep owner interface to ensure lifetime
  end;




{ EJsonValueError }
constructor EJsonValueError.Create(ACode: TJsonErrorCode; const AMsg: string);
begin
  inherited Create(AMsg);
  FCode := ACode;
end;

{ EJsonParseError }
constructor EJsonParseError.Create(ACode: TJsonErrorCode; const AMsg: string; APos, ALine, ACol: SizeUInt);
begin
  inherited Create(AMsg);
  FCode := ACode; FPosition := APos; FLine := ALine; FColumn := ACol;
end;

type
  TJsonValueImpl = class(TInterfacedObject, IJsonValue, IJsonValueIntf)
  private
    FValue: PJsonValue;
    FDocument: TJsonDocument;
    FOwnerDocIntf: IJsonDocumentIntf; // hold owner interface to extend lifetime
  public
    constructor Create(AValue: PJsonValue; ADocument: TJsonDocument); overload;
    constructor Create(AValue: PJsonValue; AOwner: IJsonDocumentIntf); overload;
    // IJsonValueIntf
    function GetRaw: PJsonValue; inline;
    function GetDoc: TJsonDocument; inline;
    function GetOwnerIntf: IJsonDocumentIntf; inline;
    // IJsonValue
    function GetType: TJsonValueType;
    function IsNull: Boolean;
    function IsBoolean: Boolean;
    function IsNumber: Boolean;
    function IsInteger: Boolean;
    function IsUInteger: Boolean;
    function IsString: Boolean;
    function IsArray: Boolean;
    function IsObject: Boolean;
    function GetBoolean: Boolean;
    function GetInteger: Int64;
    function GetUInteger: UInt64;
    function GetFloat: Double;
    function GetString: String;
    function GetUtf8String: UTF8String;
    function GetStringLength: SizeUInt;
    function GetArraySize: SizeUInt;
    function GetArrayItem(AIndex: SizeUInt): IJsonValue;
    function GetObjectSize: SizeUInt;
    function GetObjectValue(const AKey: String): IJsonValue;
    function GetObjectValueUtf8(const AKey: UTF8String): IJsonValue;
    function GetObjectValueN(const AKey: PChar; AKeyLen: SizeUInt): IJsonValue;
    function HasObjectKey(const AKey: String): Boolean;
    function HasObjectKeyUtf8(const AKey: UTF8String): Boolean;
    function HasObjectKeyN(const AKey: PChar; AKeyLen: SizeUInt): Boolean;
  end;

  TJsonDocumentImpl = class(TInterfacedObject, IJsonDocument, IJsonDocumentIntf)
  private
    FDoc: TJsonDocument;
  public
    constructor Create(ADoc: TJsonDocument);
    destructor Destroy; override;
    // IJsonDocumentIntf
    function GetDoc: TJsonDocument; inline;
    // IJsonDocument
    function GetRoot: IJsonValue;
    function GetAllocator: TAllocator;
    function GetBytesRead: SizeUInt;
    function GetValuesRead: SizeUInt;
  end;

  TJsonReaderImpl = class(TInterfacedObject, IJsonReader)
  private
    FAllocator: TAllocator;
  public
    constructor Create(AAllocator: TAllocator);
    function ReadFromString(const AJson: String; AFlags: TJsonReadFlags = []): IJsonDocument;
    function ReadFromStringN(const AJson: PChar; ALength: SizeUInt; AFlags: TJsonReadFlags = []): IJsonDocument;
    function ReadFromFile(const APath: String; AFlags: TJsonReadFlags = []): IJsonDocument;
    function ReadFromStream(AStream: TStream; AFlags: TJsonReadFlags = []): IJsonDocument;
  end;

  TJsonWriterImpl = class(TInterfacedObject, IJsonWriter)
  public
    function WriteToString(ADocument: IJsonDocument; AFlags: TJsonWriteFlags = []): String;
    function WriteToFile(ADocument: IJsonDocument; const APath: String; AFlags: TJsonWriteFlags = []): Boolean;
    function WriteToStream(ADocument: IJsonDocument; AStream: TStream; AFlags: TJsonWriteFlags = []): Boolean;
  end;

  TJsonStreamReaderImpl = class(TInterfacedObject, IJsonStreamReader)
  private
    FState: PJsonIncrState;
    FAllocator: TAllocator;
    FFlags: TJsonReadFlags;
    FBuffer: RawByteString;
  public
    constructor Create(ABufferCapacity: SizeUInt; AAllocator: TAllocator; AFlags: TJsonReadFlags);
    destructor Destroy; override;
    function Feed(const AChunk: PChar; ALength: SizeUInt): Integer;
    function TryRead(out ADoc: IJsonDocument): Integer;
    procedure Reset;
  end;

{ TJsonValueImpl }
constructor TJsonValueImpl.Create(AValue: PJsonValue; ADocument: TJsonDocument);
begin
  inherited Create;
  FValue := AValue;
  FDocument := ADocument;
  FOwnerDocIntf := nil;
end;

constructor TJsonValueImpl.Create(AValue: PJsonValue; AOwner: IJsonDocumentIntf);
begin
  inherited Create;
  FValue := AValue;
  if Assigned(AOwner) then begin
    FOwnerDocIntf := AOwner;
    FDocument := AOwner.GetDoc;
  end else begin
    FOwnerDocIntf := nil;
    FDocument := nil;
  end;
end;

function TJsonValueImpl.GetRaw: PJsonValue; inline; begin Result := FValue; end;
function TJsonValueImpl.GetDoc: TJsonDocument; inline; begin Result := FDocument; end;
function TJsonValueImpl.GetOwnerIntf: IJsonDocumentIntf; inline; begin Result := FOwnerDocIntf; end;

function TJsonValueImpl.GetType: TJsonValueType;
begin
  if not Assigned(FValue) then Exit(jvtNull);
  case UnsafeGetType(FValue) of
    YYJSON_TYPE_NULL:   Exit(jvtNull);
    YYJSON_TYPE_BOOL:   Exit(jvtBoolean);
    YYJSON_TYPE_NUM:    Exit(jvtNumber);
    YYJSON_TYPE_STR:    Exit(jvtString);
    YYJSON_TYPE_ARR:    Exit(jvtArray);
    YYJSON_TYPE_OBJ:    Exit(jvtObject);
  else
    Exit(jvtNull);
  end;
end;

function TJsonValueImpl.IsNull: Boolean; begin Result := (not Assigned(FValue)) or UnsafeIsNull(FValue); end;
function TJsonValueImpl.IsBoolean: Boolean; begin Result := Assigned(FValue) and JsonIsBool(FValue); end;
function TJsonValueImpl.IsNumber: Boolean; begin Result := Assigned(FValue) and JsonIsNum(FValue); end;
function TJsonValueImpl.IsString: Boolean; begin Result := Assigned(FValue) and JsonIsStr(FValue); end;
function TJsonValueImpl.IsArray: Boolean; begin Result := Assigned(FValue) and JsonIsArr(FValue); end;
function TJsonValueImpl.IsObject: Boolean; begin Result := Assigned(FValue) and JsonIsObj(FValue); end;

function TJsonValueImpl.IsInteger: Boolean; inline;
begin
  Result := Assigned(FValue) and JsonIsInt(FValue);
end;

function TJsonValueImpl.IsUInteger: Boolean; inline;
begin
  Result := Assigned(FValue) and JsonIsUint(FValue);
end;

function TJsonValueImpl.GetBoolean: Boolean;
begin
  if not IsBoolean then raise EJsonValueError.Create(jecInvalidParameter, JSON_ERR_VALUE_NOT_BOOLEAN);
  Result := JsonGetBool(FValue);
end;

function TJsonValueImpl.GetInteger: Int64;
begin
  if not IsNumber then raise EJsonValueError.Create(jecInvalidParameter, JSON_ERR_VALUE_NOT_NUMBER);
  if JsonIsInt(FValue) then
  begin
    if JsonIsSint(FValue) then
      Result := JsonGetSint(FValue)
    else
    begin
      // uint -> int64 with range check
      if JsonGetUint(FValue) > UInt64(High(Int64)) then
        raise EJsonValueError.Create(jecInvalidNumber, JSON_ERR_NUMBER_OUT_OF_RANGE)

      else
        Result := Int64(JsonGetUint(FValue));
    end;
  end
  else
    raise EJsonValueError.Create(jecInvalidParameter, JSON_ERR_INVALID_NUMBER_TYPE);
end;

function TJsonValueImpl.GetUInteger: UInt64;
begin
  if not IsNumber then raise EJsonValueError.Create(jecInvalidParameter, JSON_ERR_VALUE_NOT_NUMBER);
  if JsonIsInt(FValue) then
  begin
    if JsonIsUint(FValue) then
      Result := JsonGetUint(FValue)
    else
    begin
      // sint -> uint64 must be non-negative
      if JsonGetSint(FValue) < 0 then
        raise EJsonValueError.Create(jecInvalidNumber, JSON_ERR_NUMBER_OUT_OF_RANGE)
      else
        Result := UInt64(JsonGetSint(FValue));
    end;
  end
  else
    raise EJsonValueError.Create(jecInvalidParameter, JSON_ERR_INVALID_NUMBER_TYPE);
end;

function TJsonValueImpl.GetFloat: Double;
begin
  if not IsNumber then raise EJsonValueError.Create(jecInvalidParameter, JSON_ERR_VALUE_NOT_NUMBER);
  Result := JsonGetNum(FValue);
end;

function TJsonValueImpl.GetString: String;
var U: UTF8String;
begin
  if not IsString then raise EJsonValueError.Create(jecInvalidParameter, JSON_ERR_VALUE_NOT_STRING);
  U := JsonGetStrUtf8(FValue);
  Result := String(U);
end;

function TJsonValueImpl.GetStringLength: SizeUInt;
begin
  if not IsString then raise EJsonValueError.Create(jecInvalidParameter, JSON_ERR_VALUE_NOT_STRING);
  Result := JsonGetLen(FValue);
end;

function TJsonValueImpl.GetUtf8String: UTF8String;
begin
  if not IsString then raise EJsonValueError.Create(jecInvalidParameter, JSON_ERR_VALUE_NOT_STRING);
  Result := JsonGetStrUtf8(FValue);
end;

function TJsonValueImpl.GetArraySize: SizeUInt;
begin
  if not IsArray then raise EJsonValueError.Create(jecInvalidParameter, JSON_ERR_VALUE_NOT_ARRAY);
  Result := JsonGetLen(FValue);
end;

function TJsonValueImpl.GetArrayItem(AIndex: SizeUInt): IJsonValue;
var P: PJsonValue;
begin
  if not IsArray then raise EJsonValueError.Create(jecInvalidParameter, JSON_ERR_VALUE_NOT_ARRAY);
  P := JsonArrGet(FValue, AIndex);
  if P <> nil then
  begin
    if Assigned(FOwnerDocIntf) then
      Result := TJsonValueImpl.Create(P, FOwnerDocIntf)
    else
      Result := TJsonValueImpl.Create(P, FDocument);
  end
  else
    Result := nil;
end;

function TJsonValueImpl.GetObjectSize: SizeUInt;
begin
  if not IsObject then raise EJsonValueError.Create(jecInvalidParameter, JSON_ERR_VALUE_NOT_OBJECT);
  Result := JsonGetLen(FValue);
end;

function TJsonValueImpl.GetObjectValue(const AKey: String): IJsonValue;
begin
  Result := GetObjectValueN(PChar(AKey), Length(AKey));
end;

function TJsonValueImpl.GetObjectValueN(const AKey: PChar; AKeyLen: SizeUInt): IJsonValue;
var P: PJsonValue;
begin
  if not IsObject then raise EJsonValueError.Create(jecInvalidParameter, JSON_ERR_VALUE_NOT_OBJECT);
  P := JsonObjGetN(FValue, AKey, AKeyLen);
  if P <> nil then
  begin
    if Assigned(FOwnerDocIntf) then
      Result := TJsonValueImpl.Create(P, FOwnerDocIntf)
    else
      Result := TJsonValueImpl.Create(P, FDocument);
  end
  else
    Result := nil;
end;
function TJsonReaderImpl.ReadFromFile(const APath: String; AFlags: TJsonReadFlags): IJsonDocument;
var Err: TJsonError; Doc: TJsonDocument; Alc: TAllocator; Opt: TJsonReadOptions;
begin
  Opt := TJsonReadOptions.Default;
  JsonMaxDepth := Opt.MaxDepth; JsonMaxValues := Opt.MaxValues;
  JsonMaxStringBytes := Opt.MaxStringBytes; JsonMaxDocBytes := Opt.MaxDocBytes;

  if Assigned(FAllocator) then Alc := FAllocator else Alc := GetRtlAllocator();
  Err := Default(TJsonError);
  Doc := JsonReadFile(APath, AFlags, Alc, Err);
  if Assigned(Doc) then Exit(TJsonDocumentImpl.Create(Doc));
  raise EJsonParseError.Create(Err.Code, JsonFormatErrorMessage(Err), Err.Position, 0, 0);
end;

function TJsonReaderImpl.ReadFromStream(AStream: TStream; AFlags: TJsonReadFlags): IJsonDocument;
var Buf: RawByteString; ReadBytes: SizeInt; Opt: TJsonReadOptions;
begin
  Opt := TJsonReadOptions.Default;
  JsonMaxDepth := Opt.MaxDepth; JsonMaxValues := Opt.MaxValues;
  JsonMaxStringBytes := Opt.MaxStringBytes; JsonMaxDocBytes := Opt.MaxDocBytes;

  if (AStream = nil) then
    raise EJsonParseError.Create(jecInvalidParameter, 'Stream is nil', 0, 0, 0);
  SetLength(Buf, AStream.Size - AStream.Position);
  if Length(Buf) > 0 then begin
    ReadBytes := AStream.Read(Pointer(Buf)^, Length(Buf));
    SetLength(Buf, ReadBytes);
  end;
  Result := ReadFromStringN(PChar(Pointer(Buf)), Length(Buf), AFlags);
end;


function TJsonValueImpl.HasObjectKey(const AKey: String): Boolean;
begin
  Result := HasObjectKeyN(PChar(AKey), Length(AKey));
end;

function TJsonValueImpl.HasObjectKeyN(const AKey: PChar; AKeyLen: SizeUInt): Boolean;
begin
  if not IsObject then Exit(False);
  Result := JsonObjGetN(FValue, AKey, AKeyLen) <> nil;
end;

{ TJsonDocumentImpl }
constructor TJsonDocumentImpl.Create(ADoc: TJsonDocument);
begin
  inherited Create;
  FDoc := ADoc;
end;

destructor TJsonDocumentImpl.Destroy;
begin
  FDoc.Free;
  inherited Destroy;
end;

function TJsonDocumentImpl.GetDoc: TJsonDocument; inline; begin Result := FDoc; end;

function TJsonDocumentImpl.GetRoot: IJsonValue;
begin
  if Assigned(FDoc) and Assigned(FDoc.Root) then
    Result := TJsonValueImpl.Create(FDoc.Root, Self as IJsonDocumentIntf)
  else
    Result := nil;
end;

function TJsonDocumentImpl.GetAllocator: TAllocator; begin if Assigned(FDoc) then Result := FDoc.Allocator else Result := nil; end;
function TJsonDocumentImpl.GetBytesRead: SizeUInt; begin if Assigned(FDoc) then Result := FDoc.BytesRead else Result := 0; end;
function TJsonDocumentImpl.GetValuesRead: SizeUInt; begin if Assigned(FDoc) then Result := FDoc.ValuesRead else Result := 0; end;

{ TJsonReaderImpl }
constructor TJsonReaderImpl.Create(AAllocator: TAllocator);
begin
  inherited Create;
  FAllocator := AAllocator;
end;

function TJsonReaderImpl.ReadFromString(const AJson: String; AFlags: TJsonReadFlags): IJsonDocument;
var Err: TJsonError; Doc: TJsonDocument; Alc: TAllocator; Opt: TJsonReadOptions;
begin
  // 注入默认限额（可在未来通过 NewJsonReaderWithOptions 定制）
  Opt := TJsonReadOptions.Default;
  JsonMaxDepth := Opt.MaxDepth;
  JsonMaxValues := Opt.MaxValues;
  JsonMaxStringBytes := Opt.MaxStringBytes;
  JsonMaxDocBytes := Opt.MaxDocBytes;


  if Assigned(FAllocator) then Alc := FAllocator else Alc := GetRtlAllocator();
  Err := Default(TJsonError);
  Doc := JsonReadOpts(PChar(AJson), Length(AJson), AFlags, Alc, Err);
  if Assigned(Doc) then Exit(TJsonDocumentImpl.Create(Doc));
  raise EJsonParseError.Create(Err.Code, JsonFormatErrorMessage(Err), Err.Position, 0, 0);
end;

function TJsonReaderImpl.ReadFromStringN(const AJson: PChar; ALength: SizeUInt; AFlags: TJsonReadFlags): IJsonDocument;
var Err: TJsonError; Doc: TJsonDocument; Alc: TAllocator; Opt: TJsonReadOptions;
begin
  Opt := TJsonReadOptions.Default;
  JsonMaxDepth := Opt.MaxDepth; JsonMaxValues := Opt.MaxValues;
  JsonMaxStringBytes := Opt.MaxStringBytes; JsonMaxDocBytes := Opt.MaxDocBytes;

  if Assigned(FAllocator) then Alc := FAllocator else Alc := GetRtlAllocator();
  Err := Default(TJsonError);
  Doc := JsonReadOpts(AJson, ALength, AFlags, Alc, Err);
  if Assigned(Doc) then Exit(TJsonDocumentImpl.Create(Doc));
  raise EJsonParseError.Create(Err.Code, JsonFormatErrorMessage(Err), Err.Position, 0, 0);
end;

{ TJsonWriterImpl }
function TJsonWriterImpl.WriteToString(ADocument: IJsonDocument; AFlags: TJsonWriteFlags): String;
var DocIntf: IJsonDocumentIntf; D: TJsonDocument;
begin
  if ADocument = nil then raise EJsonParseError.Create(jecInvalidParameter, JSON_ERR_DOCUMENT_IS_NIL, 0, 0, 0);
  if not Supports(ADocument, IJsonDocumentIntf, DocIntf) then
    raise EJsonParseError.Create(jecInvalidParameter, JSON_ERR_INVALID_DOCUMENT, 0, 0, 0);
  D := DocIntf.GetDoc;
  if (D = nil) or (D.Root = nil) then
    raise EJsonParseError.Create(jecInvalidParameter, JSON_ERR_NO_ROOT_VALUE, 0, 0, 0);
  Result := JsonWriteToString(D, AFlags);
end;

function NewJsonReader(AAllocator: TAllocator): IJsonReader; begin Result := TJsonReaderImpl.Create(AAllocator); end;
function NewJsonWriter: IJsonWriter; begin Result := TJsonWriterImpl.Create; end;
function NewJsonStreamReader(ABufferCapacity: SizeUInt; AAllocator: TAllocator; AFlags: TJsonReadFlags): IJsonStreamReader; begin Result := TJsonStreamReaderImpl.Create(ABufferCapacity, AAllocator, AFlags); end;
function CreateJsonReader(AAllocator: TAllocator): IJsonReader; begin Result := NewJsonReader(AAllocator); end;
function CreateJsonWriter: IJsonWriter; begin Result := NewJsonWriter; end;

function JsonWrapDocument(ADoc: TJsonDocument): IJsonDocument;
begin
  if ADoc = nil then Exit(nil);
  Result := TJsonDocumentImpl.Create(ADoc);
end;

function TJsonWriterImpl.WriteToFile(ADocument: IJsonDocument; const APath: String; AFlags: TJsonWriteFlags): Boolean;
var DocIntf: IJsonDocumentIntf; D: TJsonDocument; Err: TJsonWriteError;
begin
  Result := False;
  if (ADocument = nil) then Exit;
procedure JsonSetReadLimits(const Opt: TJsonReadOptions);
begin
  JsonMaxDepth := Opt.MaxDepth;
  JsonMaxValues := Opt.MaxValues;
  JsonMaxStringBytes := Opt.MaxStringBytes;
  JsonMaxDocBytes := Opt.MaxDocBytes;
end;

  if not Supports(ADocument, IJsonDocumentIntf, DocIntf) then Exit;
  D := DocIntf.GetDoc;
  Result := fafafa.core.json.core.JsonWriteFile(APath, D, AFlags, D.Allocator, Err);
end;

function TJsonWriterImpl.WriteToStream(ADocument: IJsonDocument; AStream: TStream; AFlags: TJsonWriteFlags): Boolean;
var DocIntf: IJsonDocumentIntf; D: TJsonDocument;
begin
  Result := False;
  if (ADocument = nil) or (AStream = nil) then Exit;
  if not Supports(ADocument, IJsonDocumentIntf, DocIntf) then Exit;
  D := DocIntf.GetDoc;
  Result := fafafa.core.json.core.JsonWriteToStream(D, AStream, AFlags);
end;

function JsonPointerGet(ARoot: IJsonValue; const APointer: String): IJsonValue;
var VIntf: IJsonValueIntf; P: PJsonValue; D: TJsonDocument;
begin
  Result := nil;
  if (ARoot = nil) then Exit;
  if not Supports(ARoot, IJsonValueIntf, VIntf) then Exit;


  D := VIntf.GetDoc;
  P := fafafa.core.json.ptr.JsonPtrGet(VIntf.GetRaw, PChar(APointer));
  if P <> nil then
  begin
    if Assigned(VIntf.GetOwnerIntf) then
      Result := TJsonValueImpl.Create(P, VIntf.GetOwnerIntf)
    else
      Result := TJsonValueImpl.Create(P, D);
  end;
end;

function TJsonArrayEnumerator.MoveNext: Boolean;
var VIntf: IJsonValueIntf; P: PJsonValue; D: TJsonDocument;
begin
  Result := False;
  if not FInited then
  begin
    FInited := True;
    if (FRoot <> nil) and Supports(FRoot, IJsonValueIntf, VIntf) and JsonIsArr(VIntf.GetRaw) then
function NewJsonStreamReader(ABufferCapacity: SizeUInt; AAllocator: TAllocator; AFlags: TJsonReadFlags): IJsonStreamReader;
begin
  Result := TJsonStreamReaderImpl.Create(ABufferCapacity, AAllocator, AFlags);
end;

{ TJsonStreamReaderImpl }
constructor TJsonStreamReaderImpl.Create(ABufferCapacity: SizeUInt; AAllocator: TAllocator; AFlags: TJsonReadFlags);
begin
  inherited Create;
  if ABufferCapacity = 0 then ABufferCapacity := 64 * 1024;
  SetLength(FBuffer, ABufferCapacity);
  FAllocator := AAllocator;
  FFlags := AFlags;
  FState := JsonIncrNew(PChar(Pointer(FBuffer)), Length(FBuffer), FFlags, FAllocator);
end;

destructor TJsonStreamReaderImpl.Destroy;
begin
  if Assigned(FState) then JsonIncrFree(FState);
  FState := nil;
  FBuffer := '';
  inherited Destroy;
end;

function TJsonStreamReaderImpl.Feed(const AChunk: PChar; ALength: SizeUInt): Integer;
begin
  if (FState = nil) or (AChunk = nil) or (ALength = 0) then Exit(Ord(jecInvalidParameter));
  // 直接喂入到预分配缓冲，内部维护 Avail/Consumed
  // 注意：JsonIncrRead 会根据 AFeedLen 推进 Avail 并解析
  // 这里仅校验总容量是否足够（保守：满时返回 InvalidParameter）
  if (FState^.Avail + ALength > FState^.BufCap) then Exit(Ord(jecInvalidParameter));
  Move(AChunk^, (FState^.Buf + FState^.Avail)^, ALength);
  Inc(FState^.Avail, ALength);
  Exit(0);
end;

function TJsonStreamReaderImpl.TryRead(out ADoc: IJsonDocument): Integer;
var Err: TJsonError; Doc: TJsonDocument;
begin
  ADoc := nil; Err := Default(TJsonError);
  if (FState = nil) then Exit(Ord(jecInvalidParameter));
  Doc := JsonIncrRead(FState, 0, Err);
  if Assigned(Doc) then
  begin
    ADoc := TJsonDocumentImpl.Create(Doc);
    Exit(0);
  end;
  Exit(Ord(Err.Code));
end;

procedure TJsonStreamReaderImpl.Reset;
begin
  if Assigned(FState) then
  begin
    FState^.Avail := 0; FState^.Consumed := 0; FState^.PendingUtf8 := 0;
  end;
end;

      JsonArrIterInit(VIntf.GetRaw, @FIter);
  end;
  if not JsonArrIterHasNext(@FIter) then Exit(False);
  P := JsonArrIterNext(@FIter);
  if Supports(FRoot, IJsonValueIntf, VIntf) then D := VIntf.GetDoc else D := nil;
  FCurrent := TJsonValueImpl.Create(P, D);
  Result := True;
end;

function TJsonArrayEnumerator.GetCurrent: IJsonValue;
begin
  Result := FCurrent;
end;

function TJsonArrayEnumerable.GetEnumerator: TJsonArrayEnumerator;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.FRoot := FRoot;
end;

function TJsonObjectEnumerator.MoveNext: Boolean;
var VIntf: IJsonValueIntf; K, V: PJsonValue; D: TJsonDocument; KeyStr: String;
begin
  Result := False;
  if not FInited then
  begin
    FInited := True;
    if (FRoot <> nil) and Supports(FRoot, IJsonValueIntf, VIntf) and JsonIsObj(VIntf.GetRaw) then
      JsonObjIterInit(VIntf.GetRaw, @FIter);
  end;
  if not JsonObjIterHasNext(@FIter) then Exit(False);
  K := JsonObjIterNext(@FIter); V := JsonObjIterGetVal(K);
  if Supports(FRoot, IJsonValueIntf, VIntf) then D := VIntf.GetDoc else D := nil;
  SetString(KeyStr, K^.Data.Str, JsonGetLen(K));
  FCurrent.Key := KeyStr;
  FCurrent.Value := TJsonValueImpl.Create(V, D);
  Result := True;
end;

function TJsonObjectEnumerator.GetCurrent: TJsonObjectPair;
begin
  Result := FCurrent;
end;

function TJsonObjectEnumerable.GetEnumerator: TJsonObjectEnumerator;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.FRoot := FRoot;
end;

function TJsonObjectEnumeratorUtf8.MoveNext: Boolean;
var VIntf: IJsonValueIntf; K, V: PJsonValue; D: TJsonDocument; KeyUtf8: UTF8String;
begin
  Result := False;
  if not FInited then
  begin
    FInited := True;
    if (FRoot <> nil) and Supports(FRoot, IJsonValueIntf, VIntf) and JsonIsObj(VIntf.GetRaw) then
      JsonObjIterInit(VIntf.GetRaw, @FIter);
  end;
  if not JsonObjIterHasNext(@FIter) then Exit(False);
  K := JsonObjIterNext(@FIter); V := JsonObjIterGetVal(K);
  if Supports(FRoot, IJsonValueIntf, VIntf) then D := VIntf.GetDoc else D := nil;
  SetString(KeyUtf8, K^.Data.Str, JsonGetLen(K));
  FCurrent.Key := KeyUtf8;
  FCurrent.Value := TJsonValueImpl.Create(V, D);
  Result := True;
end;

function TJsonObjectEnumeratorUtf8.GetCurrent: TJsonObjectPairUtf8;
begin
  Result := FCurrent;
end;

function TJsonObjectEnumerableUtf8.GetEnumerator: TJsonObjectEnumeratorUtf8;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.FRoot := FRoot;
end;

function JsonArrayItems(ARoot: IJsonValue): TJsonArrayEnumerable;
begin
  Result.FRoot := ARoot;
end;

function JsonObjectPairs(ARoot: IJsonValue): TJsonObjectEnumerable;
begin
  Result.FRoot := ARoot;
end;

function JsonObjectPairsUtf8(ARoot: IJsonValue): TJsonObjectEnumerableUtf8;
begin
  Result.FRoot := ARoot;
end;

function JsonTryGetUtf8(ARoot: IJsonValue; out AOut: UTF8String): Boolean;
begin
  AOut := '';
  Result := (ARoot <> nil) and ARoot.IsString;
  if Result then AOut := ARoot.GetUtf8String;
end;

function JsonGetIntOrDefaultByPtr(ARoot: IJsonValue; const APointer: String; ADefault: Int64): Int64;
var V: IJsonValue;
begin
  V := JsonPointerGet(ARoot, APointer);
  if (V <> nil) and V.IsNumber then Exit(V.GetInteger) else Exit(ADefault);
end;

function JsonGetUIntOrDefaultByPtr(ARoot: IJsonValue; const APointer: String; ADefault: UInt64): UInt64;
var V: IJsonValue; U: UInt64;
begin
  V := JsonPointerGet(ARoot, APointer);
  if (V <> nil) and V.IsNumber then
  begin
    U := V.GetUInteger; Exit(U);
  end;
  Exit(ADefault);
end;

function JsonGetBoolOrDefaultByPtr(ARoot: IJsonValue; const APointer: String; ADefault: Boolean): Boolean;
var V: IJsonValue;
begin
  V := JsonPointerGet(ARoot, APointer);
  if (V <> nil) and V.IsBoolean then Exit(V.GetBoolean) else Exit(ADefault);
end;

function JsonGetFloatOrDefaultByPtr(ARoot: IJsonValue; const APointer: String; ADefault: Double): Double;
var V: IJsonValue;
begin
  V := JsonPointerGet(ARoot, APointer);
  if (V <> nil) and V.IsNumber then Exit(V.GetFloat) else Exit(ADefault);
end;

function JsonGetStrOrDefaultByPtr(ARoot: IJsonValue; const APointer: String; const ADefault: String): String;
var V: IJsonValue;
begin
  V := JsonPointerGet(ARoot, APointer);
  if (V <> nil) and V.IsString then Exit(V.GetString) else Exit(ADefault);
end;

function JsonGetUtf8OrDefaultByPtr(ARoot: IJsonValue; const APointer: String; const ADefault: UTF8String): UTF8String;
var V: IJsonValue;
begin
  V := JsonPointerGet(ARoot, APointer);
  if (V <> nil) and V.IsString then Exit(V.GetUtf8String) else Exit(ADefault);
end;

function TJsonValueImpl.GetObjectValueUtf8(const AKey: UTF8String): IJsonValue;
begin
  Result := GetObjectValueN(PChar(AKey), Length(AKey));
end;

function TJsonValueImpl.HasObjectKeyUtf8(const AKey: UTF8String): Boolean;
begin
  Result := HasObjectKeyN(PChar(AKey), Length(AKey));
end;


function JsonPointerGet(ADoc: IJsonDocument; const APointer: String): IJsonValue;
var DocIntf: IJsonDocumentIntf; P: PJsonValue; D: TJsonDocument;
begin
  Result := nil;
  if (ADoc = nil) then Exit;
  if not Supports(ADoc, IJsonDocumentIntf, DocIntf) then Exit;
  D := DocIntf.GetDoc;
  P := fafafa.core.json.ptr.JsonPtrGet(D.Root, PChar(APointer));
  if P <> nil then
    Result := TJsonValueImpl.Create(P, DocIntf);
end;


function JsonTryGetObjectValue(ARoot: IJsonValue; const AKey: String; out AOut: IJsonValue): Boolean;
var VIntf: IJsonValueIntf; P: PJsonValue; D: TJsonDocument; K: AnsiString;
begin
  AOut := nil; Result := False;
  if (ARoot = nil) or (AKey = '') then Exit;
  if not Supports(ARoot, IJsonValueIntf, VIntf) then Exit;
  D := VIntf.GetDoc;
  K := AnsiString(AKey);
  P := JsonObjGetN(VIntf.GetRaw, PChar(K), Length(K));
  if P <> nil then
  begin
    if Assigned(VIntf.GetOwnerIntf) then
      AOut := TJsonValueImpl.Create(P, VIntf.GetOwnerIntf)
    else
      AOut := TJsonValueImpl.Create(P, D);
    Exit(True);
  end;
end;

function JsonTryGetArrayItem(ARoot: IJsonValue; AIndex: SizeUInt; out AOut: IJsonValue): Boolean;
var VIntf: IJsonValueIntf; P: PJsonValue; D: TJsonDocument;
begin
  AOut := nil; Result := False;
  if (ARoot = nil) then Exit;
  if not Supports(ARoot, IJsonValueIntf, VIntf) then Exit;
  D := VIntf.GetDoc;
  P := JsonArrGet(VIntf.GetRaw, AIndex);
  if P <> nil then
  begin
    if Assigned(VIntf.GetOwnerIntf) then
      AOut := TJsonValueImpl.Create(P, VIntf.GetOwnerIntf)
    else
      AOut := TJsonValueImpl.Create(P, D);
    Exit(True);
  end;
end;


function JsonArrayForEach(ARoot: IJsonValue; AEach: TJsonArrayEachFunc): Boolean;
var VIntf: IJsonValueIntf; D: TJsonDocument; Iter: TJsonArrayIterator; P: PJsonValue; I: SizeUInt;
begin
  Result := False;
  if (ARoot = nil) or not Assigned(AEach) then Exit;
  if not Supports(ARoot, IJsonValueIntf, VIntf) then Exit;
  if not JsonIsArr(VIntf.GetRaw) then Exit;
  D := VIntf.GetDoc;
  if JsonArrIterInit(VIntf.GetRaw, @Iter) then
  begin
    Result := True; I := 0;
    while JsonArrIterHasNext(@Iter) do
    begin
      P := JsonArrIterNext(@Iter);
      if Assigned(VIntf.GetOwnerIntf) then
      begin
        if not AEach(I, TJsonValueImpl.Create(P, VIntf.GetOwnerIntf)) then Exit(True);
      end
      else
      begin
        if not AEach(I, TJsonValueImpl.Create(P, D)) then Exit(True);
      end;
      Inc(I);
    end;
  end;
end;

function JsonHasKeyUtf8(ARoot: IJsonValue; const AKey: UTF8String): Boolean;
var VIntf: IJsonValueIntf;
begin
  Result := False;
  if (ARoot = nil) then Exit;
  if not Supports(ARoot, IJsonValueIntf, VIntf) then Exit;
  if (VIntf.GetRaw = nil) or (not JsonIsObj(VIntf.GetRaw)) then Exit;
  Result := JsonObjGetN(VIntf.GetRaw, PChar(AKey), Length(AKey)) <> nil;
end;

function JsonGetValueUtf8(ARoot: IJsonValue; const AKey: UTF8String): IJsonValue;
var VIntf: IJsonValueIntf; P: PJsonValue; D: TJsonDocument;
begin
  Result := nil;
  if (ARoot = nil) then Exit;
  if not Supports(ARoot, IJsonValueIntf, VIntf) then Exit;
  if (VIntf.GetRaw = nil) or (not JsonIsObj(VIntf.GetRaw)) then Exit;
  D := VIntf.GetDoc;
  P := JsonObjGetN(VIntf.GetRaw, PChar(AKey), Length(AKey));
  if P <> nil then
  begin
    if Assigned(VIntf.GetOwnerIntf) then
      Exit(TJsonValueImpl.Create(P, VIntf.GetOwnerIntf))
    else
      Exit(TJsonValueImpl.Create(P, D));
  end;
end;

function JsonObjectForEach(ARoot: IJsonValue; AEach: TJsonObjectEachFunc): Boolean;
var VIntf: IJsonValueIntf; D: TJsonDocument; Iter: TJsonObjectIterator; K, V: PJsonValue; Key: String;
begin
  Result := False;
  if (ARoot = nil) or not Assigned(AEach) then Exit;
  if not Supports(ARoot, IJsonValueIntf, VIntf) then Exit;
  if not JsonIsObj(VIntf.GetRaw) then Exit;
  D := VIntf.GetDoc;
  if JsonObjIterInit(VIntf.GetRaw, @Iter) then
  begin
    Result := True;
    while JsonObjIterHasNext(@Iter) do
    begin
      K := JsonObjIterNext(@Iter);
      V := JsonObjIterGetVal(K);
      SetString(Key, K^.Data.Str, JsonGetLen(K));
      if Assigned(VIntf.GetOwnerIntf) then
      begin
        if not AEach(Key, TJsonValueImpl.Create(V, VIntf.GetOwnerIntf)) then Exit(True);
      end
      else
      begin
        if not AEach(Key, TJsonValueImpl.Create(V, D)) then Exit(True);
      end;
    end;
  end;
end;

function JsonObjectForEachRaw(ARoot: IJsonValue; AEach: TJsonObjectEachRawFunc): Boolean;
var VIntf: IJsonValueIntf; D: TJsonDocument; Iter: TJsonObjectIterator; K, V: PJsonValue;
begin
  Result := False;
  if (ARoot = nil) or not Assigned(AEach) then Exit;
  if not Supports(ARoot, IJsonValueIntf, VIntf) then Exit;
  if not JsonIsObj(VIntf.GetRaw) then Exit;
  D := VIntf.GetDoc;
  if JsonObjIterInit(VIntf.GetRaw, @Iter) then
  begin
    Result := True;
    while JsonObjIterHasNext(@Iter) do
    begin
      K := JsonObjIterNext(@Iter);
      V := JsonObjIterGetVal(K);
      if Assigned(VIntf.GetOwnerIntf) then
      begin
        if not AEach(JsonGetStr(K), JsonGetLen(K), TJsonValueImpl.Create(V, VIntf.GetOwnerIntf)) then Exit(True);
      end
      else
      begin
        if not AEach(JsonGetStr(K), JsonGetLen(K), TJsonValueImpl.Create(V, D)) then Exit(True);
      end;
    end;
  end;
end;

function JsonTryGetInt(ARoot: IJsonValue; out AOut: Int64): Boolean;
var VIntf: IJsonValueIntf;
begin
  AOut := 0;
  Result := False;
  if (ARoot = nil) then Exit;
  if not Supports(ARoot, IJsonValueIntf, VIntf) then Exit;
  if (VIntf.GetRaw = nil) then Exit;
  if JsonIsInt(VIntf.GetRaw) then
  begin
    if JsonIsSint(VIntf.GetRaw) then AOut := JsonGetSint(VIntf.GetRaw)
    else begin
      if JsonGetUint(VIntf.GetRaw) > UInt64(High(Int64)) then Exit(False);
      AOut := Int64(JsonGetUint(VIntf.GetRaw));
    end;
    Exit(True);
  end;
end;

function JsonTryGetUInt(ARoot: IJsonValue; out AOut: UInt64): Boolean;
var VIntf: IJsonValueIntf;
begin
  AOut := 0;
  Result := False;
  if (ARoot = nil) then Exit;
  if not Supports(ARoot, IJsonValueIntf, VIntf) then Exit;

  if (VIntf.GetRaw = nil) then Exit;
  if JsonIsInt(VIntf.GetRaw) then
  begin
    if JsonIsUint(VIntf.GetRaw) then AOut := JsonGetUint(VIntf.GetRaw)
    else begin
      if JsonGetSint(VIntf.GetRaw) < 0 then Exit(False);
      AOut := UInt64(JsonGetSint(VIntf.GetRaw));
    end;
    Exit(True);
  end;
end;

function JsonTryGetBool(ARoot: IJsonValue; out AOut: Boolean): Boolean;
begin
  AOut := False;
  Result := (ARoot <> nil) and ARoot.IsBoolean;

  if Result then AOut := ARoot.GetBoolean;
end;

function JsonTryGetFloat(ARoot: IJsonValue; out AOut: Double): Boolean;
begin
  AOut := 0.0;
  Result := (ARoot <> nil) and ARoot.IsNumber;
  if Result then AOut := ARoot.GetFloat;
end;

function JsonTryGetStr(ARoot: IJsonValue; out AOut: String): Boolean;
begin
  AOut := '';
  Result := (ARoot <> nil) and ARoot.IsString;
  if Result then AOut := ARoot.GetString;
end;

function JsonGetIntOrDefault(ARoot: IJsonValue; ADefault: Int64): Int64;
var V: Int64;
begin
  if JsonTryGetInt(ARoot, V) then Exit(V);
  Result := ADefault;
end;

function JsonGetUIntOrDefault(ARoot: IJsonValue; ADefault: UInt64): UInt64;
var V: UInt64;
begin
  if JsonTryGetUInt(ARoot, V) then Exit(V);
  Result := ADefault;
end;

function JsonGetBoolOrDefault(ARoot: IJsonValue; ADefault: Boolean): Boolean;
begin
  if (ARoot <> nil) and ARoot.IsBoolean then Exit(ARoot.GetBoolean);
  Result := ADefault;
end;

function JsonGetFloatOrDefault(ARoot: IJsonValue; ADefault: Double): Double;
begin
  if (ARoot <> nil) and ARoot.IsNumber then Exit(ARoot.GetFloat);
  Result := ADefault;
end;

function JsonGetStrOrDefault(ARoot: IJsonValue; const ADefault: String): String;
begin
  if (ARoot <> nil) and ARoot.IsString then Exit(ARoot.GetString);
  Result := ADefault;
end;

function JsonGetUtf8OrDefault(ARoot: IJsonValue; const ADefault: UTF8String): UTF8String;
begin
  if (ARoot <> nil) and ARoot.IsString then Exit(ARoot.GetUtf8String);
  Result := ADefault;
end;



end.
