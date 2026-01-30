unit fafafa.core.csv;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}


interface

uses
  Classes, SysUtils;

type
  TStringArray = array of UnicodeString;
  TCSVTable = array of TStringArray;

  // 额外方言与错误枚举
  TECSVQuoteMode = (csvQuoteMinimal, csvQuoteAll, csvQuoteNone, csvQuoteNonNumeric);
  TECSVTerminator = (csvTermAuto, csvTermCRLF, csvTermLF);
  TECSVErrorCode = (
    csvErrUnknown,
    csvErrUnexpectedQuote,
    csvErrUnterminatedQuote,
    csvErrFieldCountMismatch,
    csvErrRecordTooLarge,
    csvErrInvalidUTF8,
    csvErrInvalidEscape,
    csvErrInvalidFieldForQuoteMode,
    csvErrIndexOutOfRange
  );
  TCSVNameMatchMode = (csvNameExact, csvNameAsciiCI);
  TCSVRecordKind = (csvRecordUnicode, csvRecordBytes);
  // Trim 粒度模式（Phase 2 新增）
  TECSVTrimMode = (csvTrimNone, csvTrimHeaders, csvTrimFields, csvTrimAll);

  // CSV 方言配置（接口优先：与 Go/Rust/Java 常见配置对齐）
  TCSVDialect = record
    Delimiter: WideChar;        // 分隔符，默认 ','
    Quote: WideChar;            // 引号字符，默认 '"'
    Escape: WideChar;           // 独立转义字符（默认 #0=关闭；RFC4180 以双引号翻倍为主）
    UseCRLF: Boolean;           // 写入换行使用 CRLF（默认 True）；读取端同时兼容 CRLF/LF
    TrimSpaces: Boolean;        // 读取时修剪未引号包裹字段两侧空格
    AllowLazyQuotes: Boolean;   // 读取宽松引号（不严格闭合）
    AllowVariableFields: Boolean; // 行字段数可变（否则严格要求一致）
    HasHeader: Boolean;         // 首行是否为 header
    // 新增：
    Comment: WideChar;          // 注释行起始字符（默认 #0 关闭）
    IgnoreEmptyLines: Boolean;  // 忽略空行（默认 False）
    QuoteMode: TECSVQuoteMode;  // 写入引号策略（默认 Minimal）
    DoubleQuote: Boolean;       // 写入时是否对引号翻倍（默认 True）
    MaxRecordBytes: SizeUInt;   // 单条记录最大字节数（默认 16MiB）
    Terminator: TECSVTerminator;// 写入记录分隔符（默认 Auto，沿用 UseCRLF）
    // UTF-8 策略（互斥，默认均为 False -> 按系统默认解码行为）
    StrictUTF8: Boolean;        // 严格模式：遇到非法 UTF-8 抛错
    ReplaceInvalidUTF8: Boolean;// 宽松模式：非法序列替换为 U+FFFD
    // 名称匹配策略（表头映射）
    NameMatchMode: TCSVNameMatchMode; // 默认 csvNameAsciiCI
    // Trim 粒度模式（Phase 2 新增）
    TrimMode: TECSVTrimMode; // 默认 csvTrimNone；向后兼容：设置 TrimSpaces=True 等效于 csvTrimFields
    // 引号处理开关（与 Rust csv crate 对齐）
    Quoting: Boolean;           // 是否启用引号特殊处理（默认 True）；False 时引号被视为普通字符
  end;

  // 错误类型：包含行列定位信息 + 错误码
  ECSVError = class(ECore)  // ✅ CSV-001: 继承自 ECore
  private
    FLine: SizeInt;
    FColumn: SizeInt;
    FCode: TECSVErrorCode;
  public
    constructor CreatePos(const Msg: string; const ALine, AColumn: SizeInt); reintroduce;
    constructor CreatePosEx(const Msg: string; const ALine, AColumn: SizeInt; const ACode: TECSVErrorCode);
    property Line: SizeInt read FLine;
    property Column: SizeInt read FColumn;
    property Code: TECSVErrorCode read FCode;
  end;

  // 记录视图接口
  ICSVRecord = interface
    ['{7C7D94E9-5B9B-4F2E-9F5C-3F2B0F5A7A1D}']
    function Count: SizeInt;
    function Field(const Index: SizeInt): string;
    function FieldU(const Index: SizeInt): UnicodeString; // Unicode-safe accessor
    function TryGetByName(const Name: string; out Value: string): Boolean;
    function TryGetByNameU(const Name: UnicodeString; out Value: UnicodeString): Boolean;
    function AsArray: TStringArray;
    // P1: 性能路径（零拷贝/低分配访问）
    function TryGetFieldBytes(const Index: SizeInt; out Value: RawByteString): Boolean; // 返回 UTF-8 字节；有效期至下一次 ReadNext
    function GetFieldSlice(const Index: SizeInt; out Ptr: PAnsiChar; out Len: SizeInt): Boolean; // 零拷贝切片，生命周期同记录
    // P2: 安全 Try 接口（Unicode）
    function TryGetFieldU(const Index: SizeInt; out Value: UnicodeString): Boolean;
    // P3: 类型转换便捷方法（按索引）
    function AsStr(const Index: SizeInt): string;
    function AsInt(const Index: SizeInt; const Default: Integer = 0): Integer;
    function AsInt64(const Index: SizeInt; const Default: Int64 = 0): Int64;
    function AsFloat(const Index: SizeInt; const Default: Double = 0): Double;
    function AsBool(const Index: SizeInt; const Default: Boolean = False): Boolean;
    // P3: 类型转换便捷方法（按列名）
    function AsStrByName(const Name: string): string;
    function AsIntByName(const Name: string; const Default: Integer = 0): Integer;
    function AsInt64ByName(const Name: string; const Default: Int64 = 0): Int64;
    function AsFloatByName(const Name: string; const Default: Double = 0): Double;
    function AsBoolByName(const Name: string; const Default: Boolean = False): Boolean;
  end;

  // Reader 接口
  ICSVReader = interface
    ['{B7B1A6C2-5F7C-4B9A-A4B7-5D6F3A8C1F21}']
    function Dialect: TCSVDialect;
    function Headers: TStringArray;
    function ReadNext(out Rec: ICSVRecord): Boolean;
    procedure Reset;
    function ReadAll: TCSVTable;
    function Line: SizeInt;
    function Column: SizeInt;
  end;

  ICSVReaderBuilder = interface
    ['{0E1B5C9D-3F2D-4D6E-A57C-49B7E8A10B3A}']
    function FromStream(AStream: TStream): ICSVReaderBuilder;
    function FromFile(const FileName: string): ICSVReaderBuilder;
    function FromString(const Content: string): ICSVReaderBuilder; // 从字符串读取
    function Dialect(const D: TCSVDialect): ICSVReaderBuilder;
    function BufferSize(const Bytes: SizeUInt): ICSVReaderBuilder; // 默认 65536
    function ReuseRecord(const Enabled: Boolean): ICSVReaderBuilder; // 复用记录以减少分配
    // 直接通过 Builder 暴露关键读取策略
    function MaxRecordBytes(const Bytes: SizeUInt): ICSVReaderBuilder; // 0 表示不限制（不推荐）
    function StrictUTF8(const Enabled: Boolean): ICSVReaderBuilder; // 默认 False
    function ReplaceInvalidUTF8(const Enabled: Boolean): ICSVReaderBuilder; // 默认 False
    function RecordKind(const Kind: TCSVRecordKind): ICSVReaderBuilder; // 默认 Unicode
    // 快捷配置方法（与 Rust csv crate 对齐）
    function Delimiter(const Ch: WideChar): ICSVReaderBuilder;
    function Quote(const Ch: WideChar): ICSVReaderBuilder;
    function HasHeader(const Enabled: Boolean): ICSVReaderBuilder;
    function Flexible(const Enabled: Boolean): ICSVReaderBuilder; // alias for AllowVariableFields
    function TrimSpaces(const Enabled: Boolean): ICSVReaderBuilder;
    function Comment(const Ch: WideChar): ICSVReaderBuilder;
    function DoubleQuote(const Enabled: Boolean): ICSVReaderBuilder;
    function Escape(const Ch: WideChar): ICSVReaderBuilder;
    function LazyQuotes(const Enabled: Boolean): ICSVReaderBuilder; // alias for AllowLazyQuotes
    function Quoting(const Enabled: Boolean): ICSVReaderBuilder; // 是否启用引号特殊处理（默认 True）
    // 别名方法（与 Rust csv crate 命名对齐）
    function HasHeaders(const Enabled: Boolean): ICSVReaderBuilder; // alias for HasHeader
    function Trim(const Mode: TECSVTrimMode): ICSVReaderBuilder; // 直接设置 TrimMode
    function Build: ICSVReader;
  end;

  // Writer 接口
  ICSVWriter = interface
    ['{F3B0C9A1-7D42-4E5D-8D3A-9326C9D0C412}']
    function Dialect: TCSVDialect;
    procedure WriteRow(const Fields: array of string);
    procedure WriteRowU(const Fields: array of UnicodeString);
    procedure WriteAll(const Rows: array of TStringArray);
    procedure WriteAllU(const Rows: array of TStringArray);
    procedure Flush;
    procedure Close; // release underlying stream/handle; idempotent
  end;

  ICSVWriterBuilder = interface
    ['{5D62E13E-6C3A-4CBB-B7E9-3D8FBA5D7A0C}']
    function ToStream(AStream: TStream): ICSVWriterBuilder;
    function ToFile(const FileName: string): ICSVWriterBuilder;
    function Dialect(const D: TCSVDialect): ICSVWriterBuilder;
    function WithHeaders(const Headers: array of string): ICSVWriterBuilder;
    function WriteBOM(const Enabled: Boolean): ICSVWriterBuilder; // 默认 False
    function Terminator(const T: TECSVTerminator): ICSVWriterBuilder; // 默认 Auto
    // 快捷配置方法（与 Rust csv crate 对齐）
    function Delimiter(const Ch: WideChar): ICSVWriterBuilder;
    function Quote(const Ch: WideChar): ICSVWriterBuilder;
    function DoubleQuote(const Enabled: Boolean): ICSVWriterBuilder;
    function QuoteMode(const Mode: TECSVQuoteMode): ICSVWriterBuilder;
    function UseCRLF(const Enabled: Boolean): ICSVWriterBuilder;
    function Escape(const Ch: WideChar): ICSVWriterBuilder; // 转义字符快捷配置
    function Build: ICSVWriter;
  end;

// 便捷函数（已实现）
function DefaultRFC4180: TCSVDialect;
function ExcelDialect: TCSVDialect;
function UnixDialect: TCSVDialect;

function OpenCSVReader(const FileName: string; const D: TCSVDialect): ICSVReader;
function OpenCSVWriter(const FileName: string; const D: TCSVDialect): ICSVWriter;
// Builder factory (without exposing concrete class)
function CSVWriterBuilder: ICSVWriterBuilder;
function CSVReaderBuilder: ICSVReaderBuilder;

// 便捷静态创建函数（与 Rust csv::Reader/Writer::from_path/from_reader 对齐）
function CreateCSVReader(const FileName: string): ICSVReader; overload;
function CreateCSVReader(AStream: TStream; AOwnsStream: Boolean = False): ICSVReader; overload;
function CreateCSVWriter(const FileName: string): ICSVWriter; overload;
function CreateCSVWriter(AStream: TStream; AOwnsStream: Boolean = False): ICSVWriter; overload;

// 预设方言（新增）
function TSVDialect: TCSVDialect;   // Tab 分隔
function PipeDialect: TCSVDialect; // 管道分隔 '|'

// 门面/快速 API（新增，与 Rust csv crate 对齐）
function ReadCSVFile(const FileName: string): TCSVTable; overload;
function ReadCSVFile(const FileName: string; const D: TCSVDialect): TCSVTable; overload;
procedure WriteCSVFile(const FileName: string; const Table: TCSVTable); overload;
procedure WriteCSVFile(const FileName: string; const Table: TCSVTable; const D: TCSVDialect); overload;
function ParseCSVString(const Content: string): TCSVTable; overload;
function ParseCSVString(const Content: string; const D: TCSVDialect): TCSVTable; overload;
function ToCSVString(const Table: TCSVTable): string; overload;
function ToCSVString(const Table: TCSVTable; const D: TCSVDialect): string; overload;

implementation

// UTF-8 helpers (unit-scope)
function IsValidUTF8(const R: RawByteString): Boolean;
var
  i, l, need: SizeInt;
  b: Byte;
begin
  l := Length(R);
  i := 1;
  while i <= l do
  begin
    b := Byte(R[i]);
    if (b and $80) = 0 then
    begin
      Inc(i);
      Continue;
    end
    else if (b and $E0) = $C0 then
    begin
      need := 1;
      if (i+need) > l then Exit(False);
      if (Byte(R[i+1]) and $C0) <> $80 then Exit(False);
      if (b = $C0) or (b = $C1) then Exit(False);
      Inc(i, 2);
      Continue;
    end
    else if (b and $F0) = $E0 then
    begin
      need := 2;
      if (i+need) > l then Exit(False);
      if ((Byte(R[i+1]) and $C0) <> $80) or ((Byte(R[i+2]) and $C0) <> $80) then Exit(False);
      if (b = $E0) and (Byte(R[i+1]) < $A0) then Exit(False);
      Inc(i, 3);
      Continue;
    end
    else if (b and $F8) = $F0 then
    begin
      need := 3;
      if (i+need) > l then Exit(False);
      if ((Byte(R[i+1]) and $C0) <> $80) or ((Byte(R[i+2]) and $C0) <> $80) or ((Byte(R[i+3]) and $C0) <> $80) then Exit(False);
      if (b = $F0) and (Byte(R[i+1]) < $90) then Exit(False);
      if (b > $F4) or ((b = $F4) and (Byte(R[i+1]) > $8F)) then Exit(False);
      Inc(i, 4);
      Continue;
    end
    else
      Exit(False);
  end;
  Result := True;
end;

function EncodeUTF8(const U: UnicodeString): RawByteString; inline;
begin
  Result := UTF8Encode(U);
end;


{ ECSVError }
constructor ECSVError.CreatePos(const Msg: string; const ALine, AColumn: SizeInt);
begin
  inherited Create(Msg);
  FLine := ALine;
  FColumn := AColumn;
  FCode := csvErrUnknown;
end;

constructor ECSVError.CreatePosEx(const Msg: string; const ALine, AColumn: SizeInt; const ACode: TECSVErrorCode);
begin
  inherited Create(Msg);
  FLine := ALine;
  FColumn := AColumn;
  FCode := ACode;
end;


type
  TCSVRecordImpl = class(TInterfacedObject, ICSVRecord)
  private
    FFields: TStringArray;
    FHeaders: TStringArray;
    // 单行连续缓冲与切片索引
    FRowBuf: RawByteString;
    FOffsets: array of SizeInt;
    FLengths: array of SizeInt;
    // 每记录级别的字段字节缓存（用于 GetFieldSlice/TryGetFieldBytes 的后备路径，保证生命周期与记录一致）
    FCachedFieldBytes: array of RawByteString;
    // Header 名到索引的 ASCII 不区分大小写映射（首个重复名保留）
    FHeaderMapBuilt: Boolean;
    FHeaderMapCap: SizeInt;
    FHeaderMapKeys: array of RawByteString;
    FHeaderMapIdx: array of SizeInt;
    // 名称匹配与记录模式
    FNameMatchMode: TCSVNameMatchMode;
    FRecordKind: TCSVRecordKind;
    FTrimSpaces: Boolean;
    FStrictUTF8: Boolean;
    FReplaceInvalidUTF8: Boolean;
    FWasQuoted: array of Boolean;   // 每字段是否被引号包裹（用于延后 TrimSpaces）
    FDecoded: array of Boolean;     // 每字段是否已完成解码（Bytes 模式）
    procedure ResetHeaderMap; inline;
    procedure EnsureHeaderMapBuilt; inline;
    function AsciiLower(const S: RawByteString): RawByteString; inline;
    function HashFNV1a64(const S: RawByteString): QWord; inline;
    function FindHeaderIndexCI_Raw(const NameRaw: RawByteString): SizeInt; inline;
    procedure EnsureFieldDecoded(const Index: SizeInt);
  public
    constructor Create(const AFields, AHeaders: TStringArray; const ARowBuf: RawByteString; const AOffsets, ALengths: array of SizeInt);
    procedure AssignParsed(const AFields, AHeaders: TStringArray; const ARowBuf: RawByteString; const AOffsets, ALengths: array of SizeInt);
    procedure AssignParsedEx(const AFields, AHeaders: TStringArray; const ARowBuf: RawByteString;
      const AOffsets, ALengths: array of SizeInt; const AWasQuoted: array of Boolean;
      const ARecordKind: TCSVRecordKind; const ATrimSpaces, AStrictUTF8, AReplaceInvalidUTF8: Boolean);
    procedure SetNameMatchMode(const M: TCSVNameMatchMode);
    function Count: SizeInt;
    function Field(const Index: SizeInt): string;
    function FieldU(const Index: SizeInt): UnicodeString;
    function TryGetFieldU(const Index: SizeInt; out Value: UnicodeString): Boolean;
    function TryGetByName(const Name: string; out Value: string): Boolean;
    function TryGetByNameU(const Name: UnicodeString; out Value: UnicodeString): Boolean;
    function AsArray: TStringArray;
    function TryGetFieldBytes(const Index: SizeInt; out Value: RawByteString): Boolean;
    function GetFieldSlice(const Index: SizeInt; out Ptr: PAnsiChar; out Len: SizeInt): Boolean;
    // P3: 类型转换便捷方法（按索引）
    function AsStr(const Index: SizeInt): string;
    function AsInt(const Index: SizeInt; const Default: Integer = 0): Integer;
    function AsInt64(const Index: SizeInt; const Default: Int64 = 0): Int64;
    function AsFloat(const Index: SizeInt; const Default: Double = 0): Double;
    function AsBool(const Index: SizeInt; const Default: Boolean = False): Boolean;
    // P3: 类型转换便捷方法（按列名）
    function AsStrByName(const Name: string): string;
    function AsIntByName(const Name: string; const Default: Integer = 0): Integer;
    function AsInt64ByName(const Name: string; const Default: Int64 = 0): Int64;
    function AsFloatByName(const Name: string; const Default: Double = 0): Double;
    function AsBoolByName(const Name: string; const Default: Boolean = False): Boolean;
  end;
  TCSVReaderImpl = class(TInterfacedObject, ICSVReader)
  private
    FDialect: TCSVDialect;
    FHeaders: TStringArray;
    FOwnsStream: Boolean;
    FStream: TStream;
    FLine: SizeInt;
    FCol: SizeInt;
    FRecordStartLine: SizeInt;
    FRecordStartCol: SizeInt;
    FHeadersParsed: Boolean;
    FExpectedFields: SizeInt; // -1 means unknown yet (strict mode)
    FSkipStrict: Boolean;     // skip strict check for current record (e.g., header)
  private
    // 每记录行的字节缓冲与索引（单行 UTF-8 连续缓冲）
    FRowBuf: RawByteString;                 // single-row UTF-8 contiguous buffer
    FOffsets: array of SizeInt;             // per-field start (1-based in AnsiString)
    FLengths: array of SizeInt;             // per-field length in bytes
    FWasQuoted: array of Boolean;           // per-field quoted flag (for lazy TrimSpaces)
    FRecordKind: TCSVRecordKind;            // record storage mode
    FReuseRecord: Boolean;                  // whether to reuse record instance
    FCurrentRecord: ICSVRecord;             // cached record for reuse
    procedure LoadAllFromStream(AStream: TStream);
    function ParseRecord(out Fields: TStringArray): Boolean;
  private
    // streaming parser scaffolding
    FBuf: RawByteString;        // chunk buffer (dynamically filled)
    FBufPos: SizeInt;           // 1-based position in buffer
    FBufLen: SizeInt;           // bytes valid in buffer
    FBOMChecked: Boolean;       // BOM skip processed
    FChunkSize: SizeUInt;       // streaming read chunk size (default 65536); set by builder
    procedure EnsureBuffered;   // ensure buffer has data for streaming
    procedure BeginRecord;      // mark record start (for streaming)
    procedure EndRecord;        // finalize record (for streaming)
    // character APIs
    function GetNextChar(out Ch: Char): Boolean; inline;
    function PeekChar(out Ch: Char): Boolean; inline;
    procedure SetChunkSize(const Bytes: SizeUInt);
  public
    constructor Create(AStream: TStream; AOwnsStream: Boolean; const ADialect: TCSVDialect);
    destructor Destroy; override;
    // ICSVReader
    function Dialect: TCSVDialect;
    function Headers: TStringArray;
    function ReadNext(out Rec: ICSVRecord): Boolean;
    procedure Reset;
    function ReadAll: TCSVTable;
    function Line: SizeInt;
    function Column: SizeInt;
  end;
  TCSVWriterImpl = class(TInterfacedObject, ICSVWriter)
  private
    FDialect: TCSVDialect;
    FStream: TStream;
    FOwnsStream: Boolean;
    FHeadersWritten: Boolean;
    // Cached writer members for performance
    FDelimB: RawByteString;
    FCachedQuote: AnsiChar;
    FCachedEscape: AnsiChar;
    FLineBuf: RawByteString; // reusable line buffer capacity
    FInitHeaders: TStringArray;
    FWriteBOM: Boolean;
    FBOMWritten: Boolean;

    procedure RefreshWriterCache;

    // Byte-level helpers
    function NeedsQuotingBytes(const S: RawByteString): Boolean;
    // optimized helpers to precompute sizes and write into preallocated buffer
    function CountSpecialForQuote(const S: RawByteString): SizeInt; inline;
    procedure AppendFieldInto(var Dest: RawByteString; var P: SizeInt; const FieldBytes: RawByteString; const DelimB: RawByteString; const IsFirst: Boolean);
    procedure AppendFieldIntoPlanned(var Dest: RawByteString; var P: SizeInt; const FieldBytes: RawByteString; const DelimB: RawByteString; const IsFirst, NeedsQuote: Boolean);
    procedure EnsureBOM;
    procedure WriteLineBytes(const Line: RawByteString);
    procedure WriteHeadersIfNeeded;
  public
    constructor Create(AStream: TStream; AOwnsStream: Boolean; const ADialect: TCSVDialect; const AHeaders: TStringArray; const AWriteBOM: Boolean = False);
    destructor Destroy; override;
    function Dialect: TCSVDialect;
    procedure WriteRow(const Fields: array of string);
    procedure WriteRowU(const Fields: array of UnicodeString);
    procedure WriteAll(const Rows: array of TStringArray);
    procedure WriteAllU(const Rows: array of TStringArray);
    procedure Flush;
    procedure Close;
  end;



  TCSVReaderBuilder = class(TInterfacedObject, ICSVReaderBuilder)
  private
    FStream: TStream;
    FFileName: string;
    FDialect: TCSVDialect;
    FBufferSize: SizeUInt;
    FReuseRecord: Boolean;
    FMaxRecordBytes: SizeUInt;
    FStrictUTF8: Boolean;
    FReplaceInvalidUTF8: Boolean;
    FRecordKind: TCSVRecordKind;
    FOwnedStringStream: TStringStream; // 用于 FromString 创建的流
  public
    constructor Create;
    destructor Destroy; override;
    function FromStream(AStream: TStream): ICSVReaderBuilder;
    function FromFile(const FileName: string): ICSVReaderBuilder;
    function FromString(const Content: string): ICSVReaderBuilder;
    function Dialect(const D: TCSVDialect): ICSVReaderBuilder;
    function BufferSize(const Bytes: SizeUInt): ICSVReaderBuilder;
    function ReuseRecord(const Enabled: Boolean): ICSVReaderBuilder;
    function MaxRecordBytes(const Bytes: SizeUInt): ICSVReaderBuilder;
    function StrictUTF8(const Enabled: Boolean): ICSVReaderBuilder;
    function ReplaceInvalidUTF8(const Enabled: Boolean): ICSVReaderBuilder;
    function RecordKind(const Kind: TCSVRecordKind): ICSVReaderBuilder;
    // 快捷配置方法
    function Delimiter(const Ch: WideChar): ICSVReaderBuilder;
    function Quote(const Ch: WideChar): ICSVReaderBuilder;
    function HasHeader(const Enabled: Boolean): ICSVReaderBuilder;
    function Flexible(const Enabled: Boolean): ICSVReaderBuilder;
    function TrimSpaces(const Enabled: Boolean): ICSVReaderBuilder;
    function Comment(const Ch: WideChar): ICSVReaderBuilder;
    function DoubleQuote(const Enabled: Boolean): ICSVReaderBuilder;
    function Escape(const Ch: WideChar): ICSVReaderBuilder;
    function LazyQuotes(const Enabled: Boolean): ICSVReaderBuilder;
    function Quoting(const Enabled: Boolean): ICSVReaderBuilder;
    // 别名方法
    function HasHeaders(const Enabled: Boolean): ICSVReaderBuilder;
    function Trim(const Mode: TECSVTrimMode): ICSVReaderBuilder;
    function Build: ICSVReader;
  end;

  TCSVWriterBuilder = class(TInterfacedObject, ICSVWriterBuilder)
  private
    FStream: TStream;
    FFileName: string;
    FDialect: TCSVDialect;
    FHeaders: TStringArray;
    FWriteBOM: Boolean;
    FTerminator: TECSVTerminator;
  public
    constructor Create;
    function ToStream(AStream: TStream): ICSVWriterBuilder;
    function ToFile(const FileName: string): ICSVWriterBuilder;
    function Dialect(const D: TCSVDialect): ICSVWriterBuilder;
    function WithHeaders(const Headers: array of string): ICSVWriterBuilder;
    function WriteBOM(const Enabled: Boolean): ICSVWriterBuilder;
    function Terminator(const T: TECSVTerminator): ICSVWriterBuilder;
    // 快捷配置方法
    function Delimiter(const Ch: WideChar): ICSVWriterBuilder;
    function Quote(const Ch: WideChar): ICSVWriterBuilder;
    function DoubleQuote(const Enabled: Boolean): ICSVWriterBuilder;
    function QuoteMode(const Mode: TECSVQuoteMode): ICSVWriterBuilder;
    function UseCRLF(const Enabled: Boolean): ICSVWriterBuilder;
    function Escape(const Ch: WideChar): ICSVWriterBuilder;
    function Build: ICSVWriter;
  end;

function DefaultRFC4180: TCSVDialect;
begin
  Result.Delimiter := ',';
  Result.Quote := '"';
  Result.Escape := #0; // 默认关闭独立转义，采用双引号翻倍
  Result.UseCRLF := True;
  Result.TrimSpaces := False;
  Result.AllowLazyQuotes := False;
  Result.AllowVariableFields := False;
  Result.HasHeader := False;
  Result.Comment := #0;
  Result.IgnoreEmptyLines := False;
  Result.QuoteMode := csvQuoteMinimal;
  Result.DoubleQuote := True;
  Result.MaxRecordBytes := 16 * 1024 * 1024; // 16MiB
  Result.Terminator := csvTermAuto;
  Result.StrictUTF8 := False;
  Result.ReplaceInvalidUTF8 := False;
  Result.NameMatchMode := csvNameAsciiCI;
  Result.TrimMode := csvTrimNone; // 默认不 trim；向后兼容：TrimSpaces=True 等效于 csvTrimFields
  Result.Quoting := True; // 默认启用引号特殊处理
end;

function ExcelDialect: TCSVDialect;
begin
  // 采用与 RFC4180 接近的默认行为；区域性分号差异留给用户自定义
  Result := DefaultRFC4180;
  Result.UseCRLF := True;
  Result.TrimSpaces := False;
end;

function UnixDialect: TCSVDialect;
begin
  Result := DefaultRFC4180;
  Result.UseCRLF := False; // 使用 LF
end;

function OpenCSVReader(const FileName: string; const D: TCSVDialect): ICSVReader;
begin
  Result := TCSVReaderBuilder.Create
    .FromFile(FileName)
    .Dialect(D)
    .Build;
end;

function CSVReaderBuilder: ICSVReaderBuilder;
begin
  Result := TCSVReaderBuilder.Create;
end;

function OpenCSVWriter(const FileName: string; const D: TCSVDialect): ICSVWriter;
begin
  Result := TCSVWriterBuilder.Create
    .ToFile(FileName)
    .Dialect(D)
    .Build;
end;

function CSVWriterBuilder: ICSVWriterBuilder;
begin
  Result := TCSVWriterBuilder.Create;
end;

{ 便捷静态创建函数（与 Rust csv::Reader/Writer::from_path/from_reader 对齐） }
function CreateCSVReader(const FileName: string): ICSVReader;
begin
  Result := CSVReaderBuilder.FromFile(FileName).Build;
end;

function CreateCSVReader(AStream: TStream; AOwnsStream: Boolean = False): ICSVReader;
var
  R: TCSVReaderImpl;
begin
  R := TCSVReaderImpl.Create(AStream, AOwnsStream, DefaultRFC4180);
  Result := R;
end;

function CreateCSVWriter(const FileName: string): ICSVWriter;
begin
  Result := CSVWriterBuilder.ToFile(FileName).Build;
end;

function CreateCSVWriter(AStream: TStream; AOwnsStream: Boolean = False): ICSVWriter;
var
  Empty: TStringArray;
begin
  SetLength(Empty, 0);
  Result := TCSVWriterImpl.Create(AStream, AOwnsStream, DefaultRFC4180, Empty, False);
end;

{ 预设方言 }
function TSVDialect: TCSVDialect;
begin
  Result := DefaultRFC4180;
  Result.Delimiter := #9; // Tab
end;

function PipeDialect: TCSVDialect;
begin
  Result := DefaultRFC4180;
  Result.Delimiter := '|';
end;

{ 门面 API }
function ReadCSVFile(const FileName: string): TCSVTable;
begin
  Result := ReadCSVFile(FileName, DefaultRFC4180);
end;

function ReadCSVFile(const FileName: string; const D: TCSVDialect): TCSVTable;
var
  R: ICSVReader;
begin
  R := OpenCSVReader(FileName, D);
  Result := R.ReadAll;
end;

procedure WriteCSVFile(const FileName: string; const Table: TCSVTable);
begin
  WriteCSVFile(FileName, Table, DefaultRFC4180);
end;

procedure WriteCSVFile(const FileName: string; const Table: TCSVTable; const D: TCSVDialect);
var
  W: ICSVWriter;
  I: SizeInt;
begin
  W := OpenCSVWriter(FileName, D);
  for I := 0 to High(Table) do
    W.WriteRowU(Table[I]);
  W.Close;
end;

function ParseCSVString(const Content: string): TCSVTable;
begin
  Result := ParseCSVString(Content, DefaultRFC4180);
end;

function ParseCSVString(const Content: string; const D: TCSVDialect): TCSVTable;
var
  R: ICSVReader;
begin
  R := CSVReaderBuilder
    .FromString(Content)
    .Dialect(D)
    .Build;
  Result := R.ReadAll;
end;

function ToCSVString(const Table: TCSVTable): string;
begin
  Result := ToCSVString(Table, DefaultRFC4180);
end;

function ToCSVString(const Table: TCSVTable; const D: TCSVDialect): string;
var
  MS: TMemoryStream;
  W: ICSVWriter;
  I: SizeInt;
  Buf: RawByteString;
begin
  if Length(Table) = 0 then
  begin
    Result := '';
    Exit;
  end;
  MS := TMemoryStream.Create;
  try
    W := CSVWriterBuilder
      .ToStream(MS)
      .Dialect(D)
      .Build;
    for I := 0 to High(Table) do
      W.WriteRowU(Table[I]);
    W.Flush;
    SetLength(Buf, MS.Size);
    if MS.Size > 0 then
    begin
      MS.Position := 0;
      MS.ReadBuffer(Pointer(Buf)^, MS.Size);
    end;
    Result := string(Buf);
  finally
    MS.Free;
  end;
end;

{ TCSVRecordImpl }
constructor TCSVRecordImpl.Create(const AFields, AHeaders: TStringArray; const ARowBuf: RawByteString; const AOffsets, ALengths: array of SizeInt);
begin
  inherited Create;
  AssignParsed(AFields, AHeaders, ARowBuf, AOffsets, ALengths);
end;

procedure TCSVRecordImpl.AssignParsed(const AFields, AHeaders: TStringArray; const ARowBuf: RawByteString; const AOffsets, ALengths: array of SizeInt);
begin
  FFields := AFields;
  FHeaders := AHeaders;
  FRowBuf := ARowBuf;
  SetLength(FOffsets, Length(AOffsets));
  if Length(AOffsets) > 0 then
    Move(AOffsets[0], FOffsets[0], Length(AOffsets)*SizeOf(SizeInt));
  SetLength(FLengths, Length(ALengths));
  if Length(ALengths) > 0 then
    Move(ALengths[0], FLengths[0], Length(ALengths)*SizeOf(SizeInt));
  // 清理缓存与头映射，延迟重建
  SetLength(FCachedFieldBytes, 0);
  ResetHeaderMap;
end;

procedure TCSVRecordImpl.AssignParsedEx(const AFields, AHeaders: TStringArray; const ARowBuf: RawByteString;
  const AOffsets, ALengths: array of SizeInt; const AWasQuoted: array of Boolean;
  const ARecordKind: TCSVRecordKind; const ATrimSpaces, AStrictUTF8, AReplaceInvalidUTF8: Boolean);
var
  n: SizeInt;
begin
  // 基础字段与切片
  AssignParsed(AFields, AHeaders, ARowBuf, AOffsets, ALengths);
  // 运行时策略
  FRecordKind := ARecordKind;
  FTrimSpaces := ATrimSpaces;
  FStrictUTF8 := AStrictUTF8;
  FReplaceInvalidUTF8 := AReplaceInvalidUTF8;
  // 引号标记（用于延后 TrimSpaces）
  n := Length(AFields);
  SetLength(FWasQuoted, n);
  if Length(AWasQuoted) >= n then
    Move(AWasQuoted[0], FWasQuoted[0], n*SizeOf(Boolean))
  else if n > 0 then
    FillChar(FWasQuoted[0], n*SizeOf(Boolean), 0);
  // 解码标志
  SetLength(FDecoded, n);
  if FRecordKind = csvRecordUnicode then
  begin
    // 已完成解码
    if n > 0 then FillChar(FDecoded[0], n*SizeOf(Boolean), 1);
  end
  else
  begin
    if n > 0 then FillChar(FDecoded[0], n*SizeOf(Boolean), 0);
  end;
end;


procedure TCSVRecordImpl.SetNameMatchMode(const M: TCSVNameMatchMode);
begin
  if FNameMatchMode <> M then
  begin
    FNameMatchMode := M;
    ResetHeaderMap; // 模式变化需要重建 header map
  end;
end;

function TCSVRecordImpl.Count: SizeInt;
begin
  Result := Length(FFields);
end;

function TCSVRecordImpl.Field(const Index: SizeInt): string;
begin
  if (Index < 0) or (Index >= Length(FFields)) then
    raise ECSVError.CreatePosEx(Format('CSV error: field index out of range (index=%d, count=%d)',
      [Index, Length(FFields)]), 0, 0, csvErrIndexOutOfRange);
  // Bytes 模式按需解码再返回 UTF-8 字节
  if FRecordKind = csvRecordBytes then EnsureFieldDecoded(Index);
  Result := UTF8Encode(FFields[Index]);
end;

function TCSVRecordImpl.FieldU(const Index: SizeInt): UnicodeString;
begin
  if (Index < 0) or (Index >= Length(FFields)) then
    raise ECSVError.CreatePosEx(Format('CSV error: field index out of range (index=%d, count=%d)',
      [Index, Length(FFields)]), 0, 0, csvErrIndexOutOfRange);
  if FRecordKind = csvRecordBytes then EnsureFieldDecoded(Index);
  Result := FFields[Index];
end;

function TCSVRecordImpl.TryGetFieldU(const Index: SizeInt; out Value: UnicodeString): Boolean;
begin
  if (Index < 0) or (Index >= Length(FFields)) then Exit(False);
  if FRecordKind = csvRecordBytes then EnsureFieldDecoded(Index);
  Value := FFields[Index];
  Result := True;
end;

function TCSVRecordImpl.TryGetByName(const Name: string; out Value: string): Boolean;
var
  idx: SizeInt;
  raw: RawByteString;
  I: SizeInt;
  hdrRaw, nameRaw: RawByteString;
begin
  Result := False;
  EnsureHeaderMapBuilt;
  // 规范化 ASCII（小写）后按 O(1) 查找/或 Exact
  raw := UTF8Encode(UnicodeString(Name));
  SetCodePage(raw, CP_UTF8, False);
  idx := FindHeaderIndexCI_Raw(raw);
  if (idx >= 0) and (idx < Length(FFields)) then
  begin
    if FRecordKind = csvRecordBytes then EnsureFieldDecoded(idx);
    Value := UTF8Encode(FFields[idx]);
    Exit(True);
  end;
  // 兜底：线性扫描（极端退化时），遵循 NameMatchMode
  nameRaw := raw; // 已按 UTF-8 编码
  if FNameMatchMode = csvNameAsciiCI then
    nameRaw := AsciiLower(nameRaw);
  for I := 0 to High(FHeaders) do
  begin
    hdrRaw := UTF8Encode(UnicodeString(FHeaders[I]));
    SetCodePage(hdrRaw, CP_UTF8, False);
    if FNameMatchMode = csvNameAsciiCI then
      hdrRaw := AsciiLower(hdrRaw);
    if hdrRaw = nameRaw then
    begin
      if I <= High(FFields) then
      begin
        if FRecordKind = csvRecordBytes then EnsureFieldDecoded(I);
        Value := UTF8Encode(FFields[I]);
        Exit(True);
      end;
    end;
  end;
end;

function TCSVRecordImpl.TryGetByNameU(const Name: UnicodeString; out Value: UnicodeString): Boolean;
var
  idx: SizeInt;
  raw: RawByteString;
  I: SizeInt;
  LowerName: UnicodeString;
begin
  Result := False;
  EnsureHeaderMapBuilt;
  // 仍按 ASCII 大小写不敏感（保持现有行为与测试），后续可挂到 NameMatchMode 切 Exact
  raw := UTF8Encode(Name);
  SetCodePage(raw, CP_UTF8, False);
  idx := FindHeaderIndexCI_Raw(raw);
  if (idx >= 0) and (idx < Length(FFields)) then
  begin
    if FRecordKind = csvRecordBytes then EnsureFieldDecoded(idx);
    Value := FFields[idx];
    Exit(True);
  end;
  // 兜底：线性扫描（与旧行为一致），遵循 NameMatchMode
  if FNameMatchMode = csvNameAsciiCI then
  begin
    LowerName := LowerCase(Name);
    for I := 0 to High(FHeaders) do
    begin
      if LowerCase(UnicodeString(FHeaders[I])) = LowerName then
      begin
        if I < Length(FFields) then
        begin
          if FRecordKind = csvRecordBytes then EnsureFieldDecoded(I);
          Value := FFields[I];
          Exit(True);
        end
        else Exit(False);
      end;
    end;
  end
  else
  begin
    for I := 0 to High(FHeaders) do
    begin
      if UnicodeString(FHeaders[I]) = Name then
      begin
        if I < Length(FFields) then
        begin
          if FRecordKind = csvRecordBytes then EnsureFieldDecoded(I);
          Value := FFields[I];
          Exit(True);
        end
        else Exit(False);
      end;
    end;
  end;
  Result := False;
end;

function TCSVRecordImpl.AsciiLower(const S: RawByteString): RawByteString; inline;
var i: SizeInt; b: Byte; c: AnsiChar;
begin
  Result := S;
  for i := 1 to Length(Result) do
  begin
    b := Byte(Result[i]);
    if (b >= Ord('A')) and (b <= Ord('Z')) then
    begin
      c := AnsiChar(b + 32);
      Result[i] := c;
    end;
  end;
end;

function TCSVRecordImpl.HashFNV1a64(const S: RawByteString): QWord; inline;
const FNV_OFFSET_BASIS: QWord = 1469598103934665603;
      FNV_PRIME: QWord = 1099511628211;
var i: SizeInt;
begin
  Result := FNV_OFFSET_BASIS;
  for i := 1 to Length(S) do
  begin
    Result := Result xor Byte(S[i]);
    Result := Result * FNV_PRIME;
  end;
end;

procedure TCSVRecordImpl.ResetHeaderMap; inline;
begin
  FHeaderMapBuilt := False;
  FHeaderMapCap := 0;
  SetLength(FHeaderMapKeys, 0);
  SetLength(FHeaderMapIdx, 0);
end;

procedure TCSVRecordImpl.EnsureHeaderMapBuilt; inline;
var
  n, cap, i, mask, pos: SizeInt;
  key, norm: RawByteString;
  h: QWord;
begin
  if FHeaderMapBuilt then Exit;
  n := Length(FHeaders);
  if n = 0 then begin ResetHeaderMap; FHeaderMapBuilt := True; Exit; end;
  // 取 >=2*n 的 2 次幂容量
  cap := 1; while cap < (n shl 1) do cap := cap shl 1;
  FHeaderMapCap := cap;
  SetLength(FHeaderMapKeys, cap);
  SetLength(FHeaderMapIdx, cap);
  for i := 0 to cap-1 do FHeaderMapIdx[i] := -1;
  mask := cap - 1;
  for i := 0 to n-1 do
  begin
    key := EncodeUTF8(UnicodeString(FHeaders[i]));
    SetCodePage(key, CP_UTF8, False);
    if FNameMatchMode = csvNameAsciiCI then
      norm := AsciiLower(key)
    else
      norm := key; // exact
    // 仅保留首个重复名
    h := HashFNV1a64(norm);
    pos := SizeInt(h and QWord(mask));
    while True do
    begin
      if (FHeaderMapIdx[pos] = -1) then
      begin
        FHeaderMapKeys[pos] := norm;
        FHeaderMapIdx[pos] := i;
        Break;
      end
      else if (FHeaderMapKeys[pos] = norm) then
      begin
        // 已存在（重复表头），保留首次的不覆盖
        Break;
      end
      else
      begin
        pos := (pos + 1) and mask;
      end;
    end;
  end;
  FHeaderMapBuilt := True;
end;

function TCSVRecordImpl.FindHeaderIndexCI_Raw(const NameRaw: RawByteString): SizeInt; inline;
var
  cap, mask, pos, start: SizeInt;
  norm: RawByteString;
  h: QWord;
begin
  Result := -1;
  if not FHeaderMapBuilt then Exit;
  cap := FHeaderMapCap;
  if cap <= 0 then Exit;
  mask := cap - 1;
  if FNameMatchMode = csvNameAsciiCI then
    norm := AsciiLower(NameRaw)
  else
    norm := NameRaw;
  h := HashFNV1a64(norm);
  pos := SizeInt(h and QWord(mask));
  start := pos;
  while True do
  begin
    if FHeaderMapIdx[pos] = -1 then Exit(-1);
    if FHeaderMapKeys[pos] = norm then Exit(FHeaderMapIdx[pos]);
    pos := (pos + 1) and mask;
    if pos = start then Exit(-1);
  end;
end;

procedure TCSVRecordImpl.EnsureFieldDecoded(const Index: SizeInt);
var
  Tmp: RawByteString;
begin
  if (Index < 0) or (Index >= Length(FFields)) then Exit;
  if (FRecordKind <> csvRecordBytes) then Exit;
  if (Length(FDecoded) <= Index) then
    SetLength(FDecoded, Length(FFields));
  if FDecoded[Index] then Exit;
  // 从 FRowBuf 提取该字段字节切片
  if (Index < Length(FOffsets)) and (Index < Length(FLengths)) then
  begin
    if FLengths[Index] = 0 then
    begin
      FFields[Index] := '';
      FDecoded[Index] := True;
      Exit;
    end;
    SetString(Tmp, PAnsiChar(Pointer(FRowBuf)) + (FOffsets[Index]-1), FLengths[Index]);
    SetCodePage(Tmp, CP_UTF8, False);
    // UTF-8 策略：严格 or 替换非法（保持与解析阶段一致）
    if FStrictUTF8 then
    begin
      if not IsValidUTF8(Tmp) then
        raise ECSVError.Create('CSV error: invalid UTF-8 sequence');
      FFields[Index] := UTF8Decode(Tmp);
    end
    else if FReplaceInvalidUTF8 then
      FFields[Index] := UTF8Decode(Tmp)
    else
      FFields[Index] := UTF8Decode(Tmp);
    if FTrimSpaces and (not FWasQuoted[Index]) then
      FFields[Index] := Trim(FFields[Index]);
    FDecoded[Index] := True;
  end
  else
  begin
    // 回退：若无 offsets（理论上不会出现），用已有 FFields
    FDecoded[Index] := True;
  end;
end;

function TCSVRecordImpl.AsArray: TStringArray;
var
  i: SizeInt;
begin
  if FRecordKind = csvRecordBytes then
  begin
    // 一次性解码全部字段，确保返回的数组与 Unicode 模式一致
    for i := 0 to High(FFields) do
      EnsureFieldDecoded(i);
  end;
  Result := FFields;
end;

function TCSVRecordImpl.TryGetFieldBytes(const Index: SizeInt; out Value: RawByteString): Boolean;
begin
  if (Index < 0) or (Index >= Length(FFields)) then Exit(False);
  if (Index < Length(FOffsets)) and (Index < Length(FLengths)) then
  begin
    if FLengths[Index] = 0 then begin Value := ''; Exit(True); end;
    SetString(Value, PAnsiChar(Pointer(FRowBuf)) + (FOffsets[Index]-1), FLengths[Index]);
    Exit(True);
  end;
  // 回退：缓存一次编码结果，保证生命周期与记录一致
  if Length(FCachedFieldBytes) < Length(FFields) then
    SetLength(FCachedFieldBytes, Length(FFields));
  if FCachedFieldBytes[Index] = '' then
    FCachedFieldBytes[Index] := UTF8Encode(FFields[Index]);
  Value := FCachedFieldBytes[Index];
  Result := True;
end;

function TCSVRecordImpl.GetFieldSlice(const Index: SizeInt; out Ptr: PAnsiChar; out Len: SizeInt): Boolean;
begin
  if (Index < 0) or (Index >= Length(FFields)) then Exit(False);
  if (Index < Length(FOffsets)) and (Index < Length(FLengths)) then
  begin
    Ptr := PAnsiChar(Pointer(FRowBuf)) + (FOffsets[Index]-1);
    Len := FLengths[Index];
    Exit(True);
  end;
  // 回退：从缓存获取稳定切片（必要时编码并缓存）
  if Length(FCachedFieldBytes) < Length(FFields) then
    SetLength(FCachedFieldBytes, Length(FFields));
  if FCachedFieldBytes[Index] = '' then
    FCachedFieldBytes[Index] := UTF8Encode(FFields[Index]);
  if FCachedFieldBytes[Index] <> '' then
  begin
    Ptr := PAnsiChar(Pointer(FCachedFieldBytes[Index]));
    Len := Length(FCachedFieldBytes[Index]);
  end
  else begin
    Ptr := nil; Len := 0;
  end;
  Result := True;
end;

{ TCSVRecordImpl - P3: 类型转换便捷方法 }
function TCSVRecordImpl.AsStr(const Index: SizeInt): string;
begin
  if (Index < 0) or (Index >= Length(FFields)) then
    Exit('');
  if FRecordKind = csvRecordBytes then EnsureFieldDecoded(Index);
  Result := UTF8Encode(FFields[Index]);
end;

function TCSVRecordImpl.AsInt(const Index: SizeInt; const Default: Integer = 0): Integer;
var
  S: string;
  Code: Integer;
begin
  S := AsStr(Index);
  if S = '' then Exit(Default);
  Val(S, Result, Code);
  if Code <> 0 then Result := Default;
end;

function TCSVRecordImpl.AsInt64(const Index: SizeInt; const Default: Int64 = 0): Int64;
var
  S: string;
  Code: Integer;
begin
  S := AsStr(Index);
  if S = '' then Exit(Default);
  Val(S, Result, Code);
  if Code <> 0 then Result := Default;
end;

function TCSVRecordImpl.AsFloat(const Index: SizeInt; const Default: Double = 0): Double;
var
  S: string;
  Code: Integer;
begin
  S := AsStr(Index);
  if S = '' then Exit(Default);
  Val(S, Result, Code);
  if Code <> 0 then Result := Default;
end;

function TCSVRecordImpl.AsBool(const Index: SizeInt; const Default: Boolean = False): Boolean;
var
  S: string;
begin
  S := LowerCase(AsStr(Index));
  if (S = 'true') or (S = '1') or (S = 'yes') or (S = 'y') or (S = 'on') then
    Exit(True);
  if (S = 'false') or (S = '0') or (S = 'no') or (S = 'n') or (S = 'off') then
    Exit(False);
  Result := Default;
end;

function TCSVRecordImpl.AsStrByName(const Name: string): string;
var
  Value: string;
begin
  if TryGetByName(Name, Value) then
    Result := Value
  else
    Result := '';
end;

function TCSVRecordImpl.AsIntByName(const Name: string; const Default: Integer = 0): Integer;
var
  S: string;
  Code: Integer;
begin
  S := AsStrByName(Name);
  if S = '' then Exit(Default);
  Val(S, Result, Code);
  if Code <> 0 then Result := Default;
end;

function TCSVRecordImpl.AsInt64ByName(const Name: string; const Default: Int64 = 0): Int64;
var
  S: string;
  Code: Integer;
begin
  S := AsStrByName(Name);
  if S = '' then Exit(Default);
  Val(S, Result, Code);
  if Code <> 0 then Result := Default;
end;

function TCSVRecordImpl.AsFloatByName(const Name: string; const Default: Double = 0): Double;
var
  S: string;
  Code: Integer;
begin
  S := AsStrByName(Name);
  if S = '' then Exit(Default);
  Val(S, Result, Code);
  if Code <> 0 then Result := Default;
end;

function TCSVRecordImpl.AsBoolByName(const Name: string; const Default: Boolean = False): Boolean;
var
  S: string;
begin
  S := LowerCase(AsStrByName(Name));
  if (S = 'true') or (S = '1') or (S = 'yes') or (S = 'y') or (S = 'on') then
    Exit(True);
  if (S = 'false') or (S = '0') or (S = 'no') or (S = 'n') or (S = 'off') then
    Exit(False);
  Result := Default;
end;

{ TCSVReaderBuilder }
constructor TCSVReaderBuilder.Create;
begin
  inherited Create;
  FDialect := DefaultRFC4180;
  FStream := nil;
  FFileName := '';
  FBufferSize := 262144; // default 256KB for better throughput; builder override still takes precedence
  FReuseRecord := False;
  FMaxRecordBytes := 0; // 0 means use dialect default
  FStrictUTF8 := False;
  FReplaceInvalidUTF8 := False;
  FRecordKind := csvRecordUnicode; // 默认 Unicode 模式
  FOwnedStringStream := nil;
end;

destructor TCSVReaderBuilder.Destroy;
begin
  FreeAndNil(FOwnedStringStream);
  inherited Destroy;
end;

function TCSVReaderBuilder.FromString(const Content: string): ICSVReaderBuilder;
begin
  FreeAndNil(FOwnedStringStream);
  FOwnedStringStream := TStringStream.Create(Content);
  FStream := FOwnedStringStream;
  FFileName := '';
  Result := Self;
end;

function TCSVReaderBuilder.Delimiter(const Ch: WideChar): ICSVReaderBuilder;
begin
  FDialect.Delimiter := Ch;
  Result := Self;
end;

function TCSVReaderBuilder.Quote(const Ch: WideChar): ICSVReaderBuilder;
begin
  FDialect.Quote := Ch;
  Result := Self;
end;

function TCSVReaderBuilder.HasHeader(const Enabled: Boolean): ICSVReaderBuilder;
begin
  FDialect.HasHeader := Enabled;
  Result := Self;
end;

function TCSVReaderBuilder.Flexible(const Enabled: Boolean): ICSVReaderBuilder;
begin
  FDialect.AllowVariableFields := Enabled;
  Result := Self;
end;

function TCSVReaderBuilder.TrimSpaces(const Enabled: Boolean): ICSVReaderBuilder;
begin
  FDialect.TrimSpaces := Enabled;
  // 向后兼容：TrimSpaces=True 等效于 csvTrimFields（仅 trim 数据字段，不 trim 表头）
  if Enabled then
    FDialect.TrimMode := csvTrimFields
  else if FDialect.TrimMode = csvTrimFields then
    FDialect.TrimMode := csvTrimNone; // 复位（仅当之前是 csvTrimFields 时）
  Result := Self;
end;

function TCSVReaderBuilder.Comment(const Ch: WideChar): ICSVReaderBuilder;
begin
  FDialect.Comment := Ch;
  Result := Self;
end;

function TCSVReaderBuilder.DoubleQuote(const Enabled: Boolean): ICSVReaderBuilder;
begin
  FDialect.DoubleQuote := Enabled;
  Result := Self;
end;

function TCSVReaderBuilder.Escape(const Ch: WideChar): ICSVReaderBuilder;
begin
  FDialect.Escape := Ch;
  Result := Self;
end;

function TCSVReaderBuilder.LazyQuotes(const Enabled: Boolean): ICSVReaderBuilder;
begin
  FDialect.AllowLazyQuotes := Enabled;
  Result := Self;
end;

function TCSVReaderBuilder.Quoting(const Enabled: Boolean): ICSVReaderBuilder;
begin
  FDialect.Quoting := Enabled;
  Result := Self;
end;

function TCSVReaderBuilder.HasHeaders(const Enabled: Boolean): ICSVReaderBuilder;
begin
  // 别名：与 Rust has_headers 命名对齐
  Result := HasHeader(Enabled);
end;

function TCSVReaderBuilder.Trim(const Mode: TECSVTrimMode): ICSVReaderBuilder;
begin
  FDialect.TrimMode := Mode;
  // 同步 TrimSpaces 向后兼容标志
  FDialect.TrimSpaces := (Mode = csvTrimFields) or (Mode = csvTrimAll);
  Result := Self;
end;

{ TCSVReaderImpl }
procedure TCSVReaderImpl.LoadAllFromStream(AStream: TStream);
begin
  // Initialize for true streaming: do not preload entire stream into memory.
  // Parser will consume via GetNextChar/PeekChar which use EnsureBuffered.
  if Assigned(AStream) then
    AStream.Position := 0;
  // initialize streaming buffer state
  SetLength(FBuf, 0);
  FBufPos := 1;
  FBufLen := 0;
  FBOMChecked := False;
  // position counters
  FLine := 1;
  FCol := 1;
end;

procedure TCSVReaderImpl.EnsureBuffered;
var
  N: SizeInt;
  Off: SizeInt;
begin
  // If current buffer not exhausted, do nothing
  if (FBufLen > 0) and (FBufPos <= FBufLen) then Exit;
  if not Assigned(FStream) then Exit;
  if FStream.Position >= FStream.Size then Exit;

  // Ensure chunk size
  if FChunkSize = 0 then FChunkSize := 65536;
  SetLength(FBuf, FChunkSize);

  // Read next chunk into FBuf (temporary)
  N := FStream.Read(Pointer(FBuf)^, FChunkSize);
  if N <= 0 then
  begin
    SetLength(FBuf, 0);
    FBufPos := 1;
    FBufLen := 0;
    Exit;
  end;

  // Handle UTF-8 BOM only once on first read
  Off := 0;
  if not FBOMChecked then
  begin
    if (N >= 3) and (Byte(PAnsiChar(Pointer(FBuf))[0]) = $EF) and (Byte(PAnsiChar(Pointer(FBuf))[1]) = $BB) and (Byte(PAnsiChar(Pointer(FBuf))[2]) = $BF) then
      Off := 3;
    FBOMChecked := True;
  end;

  if (N - Off) <= 0 then
  begin
    // BOM consumed entire small chunk; try to read again on next call
    SetLength(FBuf, 0);
    FBufPos := 1;
    FBufLen := 0;
    Exit;
  end;

  // Shift buffer to remove BOM if needed and set lengths
  if Off > 0 then
  begin
    System.Move(PAnsiChar(Pointer(FBuf))[Off], Pointer(FBuf)^, N - Off);
  end;
  SetLength(FBuf, N - Off);
  FBufPos := 1;
  FBufLen := N - Off;
end;

procedure TCSVReaderImpl.BeginRecord;
begin
  // future streaming: mark record start against buffered positions
  FRecordStartLine := FLine;
  FRecordStartCol := 1; // record-level errors are reported at column 1 (record start)
end;

procedure TCSVReaderImpl.EndRecord;
begin
  // future streaming: finalize/commit any buffered state if needed
end;

procedure TCSVReaderImpl.SetChunkSize(const Bytes: SizeUInt);
begin
  if Bytes > 0 then FChunkSize := Bytes;
end;

function TCSVReaderImpl.GetNextChar(out Ch: Char): Boolean; inline;
begin
  EnsureBuffered;
  if FBufPos <= FBufLen then
  begin
    Ch := Char(byte(FBuf[FBufPos]));
    Inc(FBufPos); Inc(FCol);
    Exit(True);
  end;
  Exit(False);
end;

function TCSVReaderImpl.PeekChar(out Ch: Char): Boolean; inline;
begin
  EnsureBuffered;
  if FBufPos <= FBufLen then
  begin
    Ch := Char(byte(FBuf[FBufPos]));
    Exit(True);
  end;
  Exit(False);
end;

{ TCSVWriterImpl }
constructor TCSVWriterImpl.Create(AStream: TStream; AOwnsStream: Boolean; const ADialect: TCSVDialect; const AHeaders: TStringArray; const AWriteBOM: Boolean = False);
begin
  inherited Create;
  FDialect := ADialect;
  FStream := AStream;
  RefreshWriterCache;

  FOwnsStream := AOwnsStream;
  FHeadersWritten := False;
  FInitHeaders := AHeaders;
  FWriteBOM := AWriteBOM;
  FBOMWritten := False;
end;

destructor TCSVWriterImpl.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TCSVWriterImpl.Dialect: TCSVDialect;
begin
  Result := FDialect;
end;

// 判断字节串是否为数字格式（整数或浮点数）
function IsNumericBytes(const S: RawByteString): Boolean;
var
  I, L: SizeInt;
  Ch: Byte;
  HasDigit, HasDot: Boolean;
begin
  L := Length(S);
  if L = 0 then Exit(False);
  HasDigit := False;
  HasDot := False;
  I := 1;
  // 允许前导正负号
  if (S[1] = '+') or (S[1] = '-') then
    Inc(I);
  // 仅正负号不算数字
  if I > L then Exit(False);
  while I <= L do
  begin
    Ch := Byte(S[I]);
    if (Ch >= Ord('0')) and (Ch <= Ord('9')) then
      HasDigit := True
    else if Ch = Ord('.') then
    begin
      if HasDot then Exit(False); // 多个小数点
      HasDot := True;
    end
    else
      Exit(False); // 非数字字符
    Inc(I);
  end;
  Result := HasDigit;
end;

function TCSVWriterImpl.NeedsQuotingBytes(const S: RawByteString): Boolean;
var
  I: SizeInt;
  DelimB, QuoteB, CommentB: Byte;
  HasSpecial: Boolean;
begin
  if FDialect.QuoteMode = csvQuoteAll then Exit(True);
  if Length(S) = 0 then Exit(False);

  // csvQuoteNonNumeric：非数字字段总是加引号
  if FDialect.QuoteMode = csvQuoteNonNumeric then
  begin
    if not IsNumericBytes(S) then Exit(True);
    // 数字字段仍需检查特殊字符
  end;

  DelimB := Byte(Ord(FDialect.Delimiter) and $FF);
  QuoteB := Byte(Ord(FDialect.Quote) and $FF);
  CommentB := Byte(Ord(FDialect.Comment) and $FF);
  HasSpecial := False;
  for I := 1 to Length(S) do
  begin
    if (Byte(S[I]) = DelimB) or (Byte(S[I]) = QuoteB) or (S[I] = #10) or (S[I] = #13) then
    begin
      HasSpecial := True;
      Break;
    end;
  end;
  if (FDialect.Comment <> #0) and (Length(S) > 0) and (Byte(S[1]) = CommentB) then
    HasSpecial := True;
  if (Length(S) > 0) and ((S[1] = ' ') or (S[Length(S)] = ' ')) then
    HasSpecial := True;

  if FDialect.QuoteMode = csvQuoteNone then
  begin
    if HasSpecial then
      raise ECSVError.CreatePosEx('CSV error: field not allowed under QuoteMode=None', 0, 0, csvErrInvalidFieldForQuoteMode);
    Exit(False);
  end;

  Result := HasSpecial;
end;

function TCSVWriterImpl.CountSpecialForQuote(const S: RawByteString): SizeInt;
var
  Q, E: AnsiChar;
  I, Cnt: SizeInt;
begin
  Q := AnsiChar(Byte(Ord(FDialect.Quote) and $FF));
  E := AnsiChar(Byte(Ord(FDialect.Escape) and $FF));
  Cnt := 0;
  for I := 1 to Length(S) do
  begin
    if (FDialect.DoubleQuote) and (S[I] = Q) then Inc(Cnt)
    else if (FDialect.Escape <> #0) and (S[I] = Q) then Inc(Cnt)
    else if (FDialect.Escape <> #0) and (S[I] = E) then Inc(Cnt);
  end;
  Result := Cnt;
end;




procedure TCSVWriterImpl.AppendFieldInto(var Dest: RawByteString; var P: SizeInt; const FieldBytes: RawByteString; const DelimB: RawByteString; const IsFirst: Boolean);
var
  Q, E: AnsiChar;
  I, L: SizeInt;
begin
  if not IsFirst then
  begin
    Move(Pointer(DelimB)^, PAnsiChar(@Dest[P])^, Length(DelimB));
    Inc(P, Length(DelimB));
  end;
  if NeedsQuotingBytes(FieldBytes) then
  begin
    Q := FCachedQuote;
    E := FCachedEscape;
    // write opening quote
    PAnsiChar(@Dest[P])^ := Q; Inc(P);
    I := 1;
    while I <= Length(FieldBytes) do
    begin
      if (FDialect.DoubleQuote) and (FieldBytes[I] = Q) then
      begin
        PAnsiChar(@Dest[P])^ := Q; Inc(P);
        PAnsiChar(@Dest[P])^ := Q; Inc(P);
        Inc(I);
      end
      else if (not FDialect.DoubleQuote) and (FDialect.Escape <> #0) and (FieldBytes[I] = Q) then
      begin
        // Escape mode: quote -> E+Q
        PAnsiChar(@Dest[P])^ := E; Inc(P);
        PAnsiChar(@Dest[P])^ := Q; Inc(P);
        Inc(I);
      end
      else if (FDialect.Escape <> #0) and (FieldBytes[I] = E) then
      begin
        // Escape the escape itself: E -> E+E
        PAnsiChar(@Dest[P])^ := E; Inc(P);
        PAnsiChar(@Dest[P])^ := E; Inc(P);
        Inc(I);
      end
      else
      begin
        PAnsiChar(@Dest[P])^ := AnsiChar(FieldBytes[I]); Inc(P);
        Inc(I);
      end;
    end;
    // closing quote
    PAnsiChar(@Dest[P])^ := Q; Inc(P);
  end
  else
  begin
    L := Length(FieldBytes);
    if L > 0 then
    begin
      Move(Pointer(FieldBytes)^, PAnsiChar(@Dest[P])^, L);
      Inc(P, L);
    end;
  end;
end;

procedure TCSVWriterImpl.AppendFieldIntoPlanned(var Dest: RawByteString; var P: SizeInt; const FieldBytes: RawByteString; const DelimB: RawByteString; const IsFirst, NeedsQuote: Boolean);
var
  Q, E: AnsiChar;
  I, L: SizeInt;
begin
  if not IsFirst then
  begin
    Move(Pointer(DelimB)^, PAnsiChar(@Dest[P])^, Length(DelimB));
    Inc(P, Length(DelimB));
  end;
  if NeedsQuote then
  begin
    Q := FCachedQuote;
    E := FCachedEscape;
    PAnsiChar(@Dest[P])^ := Q; Inc(P);
    I := 1;
    while I <= Length(FieldBytes) do
    begin
      if (FDialect.DoubleQuote) and (FieldBytes[I] = Q) then
      begin
        PAnsiChar(@Dest[P])^ := Q; Inc(P);
        PAnsiChar(@Dest[P])^ := Q; Inc(P);
        Inc(I);
      end
      else if (not FDialect.DoubleQuote) and (FDialect.Escape <> #0) and (FieldBytes[I] = Q) then
      begin
        // Escape mode: quote -> E+Q
        PAnsiChar(@Dest[P])^ := E; Inc(P);
        PAnsiChar(@Dest[P])^ := Q; Inc(P);
        Inc(I);
      end
      else if (FDialect.Escape <> #0) and (FieldBytes[I] = E) then
      begin
        // Escape the escape itself: E -> E+E
        PAnsiChar(@Dest[P])^ := E; Inc(P);
        PAnsiChar(@Dest[P])^ := E; Inc(P);
        Inc(I);
      end
      else
      begin
        PAnsiChar(@Dest[P])^ := AnsiChar(FieldBytes[I]); Inc(P);
        Inc(I);
      end;
    end;
    PAnsiChar(@Dest[P])^ := Q; Inc(P);
  end
  else
  begin
    L := Length(FieldBytes);
    if L > 0 then
    begin
      Move(Pointer(FieldBytes)^, PAnsiChar(@Dest[P])^, L);
      Inc(P, L);
    end;
  end;
end;





procedure TCSVWriterImpl.EnsureBOM;
const
  UTF8BOM: array[0..2] of Byte = ($EF, $BB, $BF);
begin
  if (not FWriteBOM) or FBOMWritten then Exit;
  FStream.WriteBuffer(UTF8BOM, SizeOf(UTF8BOM));
  FBOMWritten := True;
end;

procedure TCSVWriterImpl.RefreshWriterCache;
begin
  FDelimB := EncodeUTF8(UnicodeString(FDialect.Delimiter));
  FCachedQuote := AnsiChar(Byte(Ord(FDialect.Quote) and $FF));
  FCachedEscape := AnsiChar(Byte(Ord(FDialect.Escape) and $FF));
  SetCodePage(FDelimB, CP_UTF8, False);
end;

procedure TCSVWriterImpl.WriteLineBytes(const Line: RawByteString);
var
  Sep: RawByteString;
begin
  EnsureBOM;
  case FDialect.Terminator of
    csvTermCRLF: Sep := #13#10;
    csvTermLF: Sep := #10;
  else
    if FDialect.UseCRLF then Sep := #13#10 else Sep := #10;
  end;
  SetCodePage(Sep, CP_UTF8, False);
  if Length(Line) > 0 then
    FStream.WriteBuffer(Pointer(Line)^, Length(Line));
  if Length(Sep) > 0 then
    FStream.WriteBuffer(Pointer(Sep)^, Length(Sep));
end;

procedure TCSVWriterImpl.WriteHeadersIfNeeded;
var
  I: SizeInt;
  Line: RawByteString;
  FieldBytes: RawByteString;
  DelimB: RawByteString;
  Total: SizeInt;
  P: SizeInt;
begin
  if FHeadersWritten then Exit;
  if Length(FInitHeaders) = 0 then Exit;
  // Precompute one-shot capacity for headers
  DelimB := FDelimB;
  Total := 0;
  for I := 0 to High(FInitHeaders) do
  begin
    if I > 0 then Inc(Total, Length(DelimB));
    FieldBytes := EncodeUTF8(UnicodeString(FInitHeaders[I]));
    if NeedsQuotingBytes(FieldBytes) then
      Inc(Total, 2 + Length(FieldBytes) + CountSpecialForQuote(FieldBytes))
    else
      Inc(Total, Length(FieldBytes));
  end;
  if Length(FLineBuf) < Total then SetLength(FLineBuf, Total);
  SetLength(FLineBuf, Total);
  SetCodePage(FLineBuf, CP_UTF8, False);
  P := 1;
  for I := 0 to High(FInitHeaders) do
  begin
    FieldBytes := EncodeUTF8(UnicodeString(FInitHeaders[I]));
    AppendFieldInto(FLineBuf, P, FieldBytes, DelimB, I=0);
  end;
  // shrink to actual size written
  if P > 1 then SetLength(FLineBuf, P-1) else SetLength(FLineBuf, 0);
  Line := FLineBuf;
  WriteLineBytes(Line);
  FHeadersWritten := True;
end;

procedure TCSVWriterImpl.WriteRow(const Fields: array of string);
var
  I: SizeInt;
  FieldBytes: RawByteString;
  DelimB: RawByteString;
  Total: SizeInt;
  P: SizeInt;
  FieldsB: array of RawByteString;
  NeedsQ: array of Boolean;
  Specials: array of SizeInt;
  N: SizeInt;
begin
  WriteHeadersIfNeeded;
  DelimB := FDelimB;
  // First pass: encode once and compute total bytes (and cache quoting decisions)
  N := High(Fields) + 1;
  SetLength(FieldsB, N);
  SetLength(NeedsQ, N);
  SetLength(Specials, N);
  Total := 0;
  for I := 0 to High(Fields) do
  begin
    FieldsB[I] := EncodeUTF8(UnicodeString(Fields[I]));
    FieldBytes := FieldsB[I];
    if I > 0 then Inc(Total, Length(DelimB));
    NeedsQ[I] := NeedsQuotingBytes(FieldBytes);
    if NeedsQ[I] then
      Specials[I] := CountSpecialForQuote(FieldBytes)
    else
      Specials[I] := 0;
    if NeedsQ[I] then
      Inc(Total, 2 + Length(FieldBytes) + Specials[I])
    else
      Inc(Total, Length(FieldBytes));
  end;
  // Reuse writer line buffer to avoid reallocation churn
  if Length(FLineBuf) < Total then SetLength(FLineBuf, Total);
  SetLength(FLineBuf, Total);
  SetCodePage(FLineBuf, CP_UTF8, False);
  P := 1;
  for I := 0 to High(Fields) do
  begin
    FieldBytes := FieldsB[I];
    AppendFieldIntoPlanned(FLineBuf, P, FieldBytes, DelimB, I=0, NeedsQ[I]);
  end;
  if P > 1 then SetLength(FLineBuf, P-1) else SetLength(FLineBuf, 0);
  WriteLineBytes(FLineBuf);
end;

procedure TCSVWriterImpl.WriteRowU(const Fields: array of UnicodeString);
var
  I: SizeInt;
  FieldBytes: RawByteString;
  DelimB: RawByteString;
  Total: SizeInt;
  P: SizeInt;
  FieldsB: array of RawByteString;
  NeedsQ: array of Boolean;
  Specials: array of SizeInt;
  N: SizeInt;
begin
  WriteHeadersIfNeeded;
  DelimB := FDelimB;
  // First pass: encode once and compute total bytes (and cache quoting decisions)
  N := High(Fields) + 1;
  SetLength(FieldsB, N);
  SetLength(NeedsQ, N);
  SetLength(Specials, N);
  Total := 0;
  for I := 0 to High(Fields) do
  begin
    FieldsB[I] := EncodeUTF8(Fields[I]);
    FieldBytes := FieldsB[I];
    if I > 0 then Inc(Total, Length(DelimB));
    NeedsQ[I] := NeedsQuotingBytes(FieldBytes);
    if NeedsQ[I] then
      Specials[I] := CountSpecialForQuote(FieldBytes)
    else
      Specials[I] := 0;
    if NeedsQ[I] then
      Inc(Total, 2 + Length(FieldBytes) + Specials[I])
    else
      Inc(Total, Length(FieldBytes));
  end;
  // Reuse writer line buffer to avoid reallocation churn
  if Length(FLineBuf) < Total then SetLength(FLineBuf, Total);
  SetLength(FLineBuf, Total);
  SetCodePage(FLineBuf, CP_UTF8, False);
  P := 1;
  for I := 0 to High(Fields) do
  begin
    FieldBytes := FieldsB[I];
    AppendFieldIntoPlanned(FLineBuf, P, FieldBytes, DelimB, I=0, NeedsQ[I]);
  end;
  if P > 1 then SetLength(FLineBuf, P-1) else SetLength(FLineBuf, 0);
  WriteLineBytes(FLineBuf);
end;

procedure TCSVWriterImpl.WriteAll(const Rows: array of TStringArray);
var
  I: SizeInt;
  J: SizeInt;
  Tmp: array of string;
begin
  for I := 0 to High(Rows) do
  begin
    SetLength(Tmp, Length(Rows[I]));
    for J := 0 to High(Rows[I]) do
      // Convert UnicodeString to UTF-8 explicitly to avoid implicit narrowing
      Tmp[J] := UTF8Encode(Rows[I][J]);
    WriteRow(Tmp);
  end;
end;

procedure TCSVWriterImpl.WriteAllU(const Rows: array of TStringArray);
var
  I: SizeInt;
begin
  for I := 0 to High(Rows) do
    WriteRowU(Rows[I]);
end;


procedure TCSVWriterImpl.Flush;
begin
  // Compatibility no-op: many RTL streams write-through; Close guarantees visibility.
  // If platform/RTL exposes a safe flush API, it can be wired here via conditional compilation.
end;

procedure TCSVWriterImpl.Close;
begin
  if FOwnsStream and Assigned(FStream) then
  begin
    FreeAndNil(FStream);
  end;
end;




constructor TCSVReaderImpl.Create(AStream: TStream; AOwnsStream: Boolean; const ADialect: TCSVDialect);
begin
  inherited Create;
  FDialect := ADialect;
  FStream := AStream;
  FOwnsStream := AOwnsStream;
  SetLength(FHeaders, 0);
  FHeadersParsed := False;
  FExpectedFields := -1;
  FChunkSize := 65536; // default; may be overridden by builder via SetChunkSize
  if Assigned(FStream) then
    LoadAllFromStream(FStream);
end;

destructor TCSVReaderImpl.Destroy;
begin
  if FOwnsStream and Assigned(FStream) then
    FreeAndNil(FStream);
  inherited Destroy;
end;

function TCSVReaderImpl.Dialect: TCSVDialect;
begin
  Result := FDialect;
end;

function TCSVReaderImpl.Headers: TStringArray;
var
  tmp: TStringArray;
  i: SizeInt;
  ShouldTrimHeaders: Boolean;
begin
  if (not FHeadersParsed) and FDialect.HasHeader then
  begin
    if ParseRecord(tmp) then
    begin
      // Apply TrimMode for headers
      ShouldTrimHeaders := (FDialect.TrimMode = csvTrimHeaders) or (FDialect.TrimMode = csvTrimAll);
      if ShouldTrimHeaders then
        for i := 0 to High(tmp) do
          tmp[i] := Trim(tmp[i]);
      FHeaders := tmp;
      FHeadersParsed := True;
      FSkipStrict := True;
    end
    else
      FHeadersParsed := True;
  end;
  Result := FHeaders;
end;

function TCSVReaderImpl.Line: SizeInt;
begin
  Result := FLine;
end;

function TCSVReaderImpl.Column: SizeInt;
begin
  Result := FCol;
end;

procedure TCSVReaderImpl.Reset;
begin
  // reset positions and buffered state for streaming
  if Assigned(FStream) then
    FStream.Position := 0;
  SetLength(FBuf, 0);
  FBufPos := 1; FBufLen := 0;
  FBOMChecked := False;
  // logical parser state
  FLine := 1;
  FCol := 1;
  SetLength(FHeaders, 0);
  FHeadersParsed := False;
  FExpectedFields := -1;
  FSkipStrict := False;
end;

function TCSVReaderImpl.ParseRecord(out Fields: TStringArray): Boolean;
var
  InQuotes: Boolean;
  WasQuoted: Boolean;
  C, NextCh: Char;
  FieldBuilder: RawByteString;
  FieldCount: SizeInt;
  EmittedOnBreak: Boolean;
  AllEmpty: Boolean;
  K: SizeInt;
  BufLen, BufCap: SizeInt;
  BytesCount: SizeUInt;
  procedure EmitField;
  var
    S: UnicodeString;
    Tmp: RawByteString;
    idx: SizeInt;
    CurLen, Need, Cap, Start, L: SizeInt;
    NewCap: SizeInt;
  begin
    Tmp := Copy(FieldBuilder, 1, BufLen);
    // 总是保留原始字节到 FRowBuf，配合 offsets/lengths
    SetCodePage(Tmp, CP_UTF8, False);
    if FRecordKind = csvRecordUnicode then
    begin
      // 立即解码为 UnicodeString
      if FDialect.StrictUTF8 then
      begin
        if not IsValidUTF8(Tmp) then
          raise ECSVError.CreatePosEx('CSV error: invalid UTF-8 sequence', FRecordStartLine, FRecordStartCol, csvErrInvalidUTF8);
        S := UTF8Decode(Tmp);
      end
      else if FDialect.ReplaceInvalidUTF8 then
        S := UTF8Decode(Tmp)
      else
      begin
        S := UTF8Decode(Tmp);
      end;
      // TrimMode 控制：不在 EmitField 里做 trim，由上层 (Headers/ReadNext) 根据上下文决定
      // 这里只记录 WasQuoted，上层会检查
    SetLength(Fields, Length(Fields)+1);
    idx := High(Fields);
    Fields[idx] := S;
    // 设置 WasQuoted 供上层 TrimMode 检查
    if Length(FWasQuoted) < Length(Fields) then SetLength(FWasQuoted, Length(Fields));
    FWasQuoted[idx] := WasQuoted;
    end
    else
    begin
      // Bytes 模式：延迟解码，先放占位空串，并记录 quoted 信息
      SetLength(Fields, Length(Fields)+1);
      idx := High(Fields);
      Fields[idx] := '';
      if Length(FWasQuoted) < Length(Fields) then SetLength(FWasQuoted, Length(Fields));
      FWasQuoted[idx] := WasQuoted;
    end;
    // 追加到单行缓冲，并记录 offset/len（避免重复拼接导致的 O(n^2) 拷贝）
    if Length(FOffsets) < (Length(Fields)) then SetLength(FOffsets, Length(Fields));
    if Length(FLengths) < (Length(Fields)) then SetLength(FLengths, Length(Fields));
    FOffsets[idx] := Length(FRowBuf) + 1;
    if Length(Tmp) > 0 then
    begin
      // 采用倍增策略管理 FRowBuf 容量，避免频繁重分配
      CurLen := Length(FRowBuf);
      Need  := CurLen + Length(Tmp);
      Cap   := Length(FRowBuf);
      // RawByteString 的 SetLength 既控制逻辑长度也控制容量，这里用一次扩容再回填
      if Cap < Need then
      begin
        NewCap := Cap;
        if NewCap < 16 then NewCap := 16;
        while NewCap < Need do NewCap := NewCap * 2;
        // 扩容到 NewCap，再回填逻辑长度
        SetLength(FRowBuf, NewCap);
        // 回填现有内容长度（CurLen）保持不变
        SetLength(FRowBuf, CurLen);
      end;
      // 将 Tmp 附加到 FRowBuf 末尾（一次 Move，O(n) 累计摊销 O(1)）
      Start := CurLen + 1;
      L := Length(Tmp);
      if L > 0 then
      begin
        SetLength(FRowBuf, Need);
        Move(Pointer(Tmp)^, PAnsiChar(@FRowBuf[Start])^, L);
      end;
    end;
    FLengths[idx] := Length(Tmp);
    // 清理字段 builder，保留容量
    BufLen := 0;
    // no-op to keep capacity
    WasQuoted := False;
    Inc(FieldCount);
    EndRecord; // streaming placeholder: finalize record-level state if needed
  end;

  procedure EnsureCap(Need: SizeInt); inline;
  var NewCap: SizeInt;
  begin
    if Need <= BufCap then Exit;
    NewCap := BufCap;
    if NewCap < 16 then NewCap := 16;
    while NewCap < Need do NewCap := NewCap * 2;
    SetLength(FieldBuilder, NewCap);
    BufCap := NewCap;
  end;
  procedure AppendByte(B: Byte); inline;
  begin
    EnsureCap(BufLen+1);
    Inc(BufLen);
    FieldBuilder[BufLen] := AnsiChar(B);
    Inc(BytesCount);
    if (FDialect.MaxRecordBytes > 0) and (BytesCount > FDialect.MaxRecordBytes) then
      raise ECSVError.CreatePosEx('CSV error: record too large', FRecordStartLine, FRecordStartCol, csvErrRecordTooLarge);
  end;
begin
  SetLength(Fields,0);
  // snapshot record start immediately when entering record parsing
  BeginRecord;
  if not PeekChar(C) then Exit(False);
  InQuotes := False;
  WasQuoted := False;
  FieldBuilder := '';
  BufLen := 0; BufCap := 0;
  FieldCount := 0;
  EmittedOnBreak := False;
  // 限制：单条记录最大字节数（累加器）
  BytesCount := 0;

  while True do
  begin
    if not PeekChar(C) then
    begin
      // EOF: if no data has been accumulated in this record, return False (no record)
      if (FieldCount = 0) and (BufLen = 0) then Exit(False);
      // 如果仅遇到空行（无任何字符），EmitField 会在下方统一执行
      Break;
    end;

    // 注释行：仅在记录开始位置且未在引号内
    if (not InQuotes) and (FieldCount = 0) and (BufLen = 0) and (FDialect.Comment <> #0) and (C = Char(FDialect.Comment)) then
    begin
      // 跳过到行尾并消费换行，避免产生空记录
      repeat
        if not GetNextChar(C) then Break; // consume until we hit EOL or EOF
      until (C = #10) or (C = #13);
      // 若是 CRLF，额外消费 LF
      if (C = #13) and PeekChar(NextCh) and (NextCh = #10) then GetNextChar(NextCh);
      Inc(FLine); FCol := 1;
      // 继续下一行起始
      Continue;
    end;


    if not InQuotes then
    begin
      // 快路径：批量消费普通字节，直到遇到分隔符/引号/CR/LF
      // 当 Quoting=False 时，引号被视为普通字符
      while True do
      begin
        if (C = #13) or (C = #10) or (C = Char(FDialect.Delimiter)) then Break;
        if FDialect.Quoting and (C = Char(FDialect.Quote)) then Break;
        GetNextChar(C);
        AppendByte(Byte(C));
        if not PeekChar(C) then Break;
      end;

      // If we exited fast path due to lack of lookahead (no more chars available now),
      // break outer loop and let the end-of-loop finalization emit the field once.
      if not PeekChar(C) then
      begin
        Break;
      end;

      if (C = #13) then
      begin
        GetNextChar(C);
        if PeekChar(C) and (C = #10) then begin GetNextChar(C); end;
        Inc(FLine); FCol := 1;
        if (BufLen = 0) and (FieldCount = 0) then
        begin
          if FDialect.IgnoreEmptyLines then Continue;
          WasQuoted := False;
        end;
        EmitField; EmittedOnBreak := True; Break;
      end
      else if (C = #10) then
      begin
        GetNextChar(C);
        Inc(FLine); FCol := 1;
        if (BufLen = 0) and (FieldCount = 0) then
        begin
          if FDialect.IgnoreEmptyLines then Continue;
          WasQuoted := False;
        end;
        EmitField; EmittedOnBreak := True; Break;
      end
      else if C = Char(FDialect.Delimiter) then
      begin
        GetNextChar(C);
        EmitField; Continue;
      end
      else if FDialect.Quoting and (C = Char(FDialect.Quote)) then
      begin
        // 仅当 Quoting=True 时处理引号
        if BufLen = 0 then
        begin
          GetNextChar(C);
          InQuotes := True; WasQuoted := True; Continue;
        end
        else
        begin
          if FDialect.AllowLazyQuotes then
          begin
            GetNextChar(C);
            AppendByte(Byte(FDialect.Quote));
            Continue;
          end
          else
            raise ECSVError.CreatePosEx('CSV error: unexpected quote in unquoted field', FRecordStartLine, FRecordStartCol, csvErrUnexpectedQuote);
        end;
      end
      else if (FDialect.Escape = #0) and (C = '\') then
      begin
        GetNextChar(C);
        AppendByte(Byte('\'));
        Continue;
      end
      else
      begin
        // 常规字符已在快路径处理，这里兜底
        GetNextChar(C);
        AppendByte(Byte(C));
      end;
    end
    else
    begin
      // Check escape first when escape is enabled
      if (FDialect.Escape <> #0) and (Byte(Ord(C) and $FF) = Byte(Ord(FDialect.Escape) and $FF)) then
      begin
        // consume escape and interpret the following character; drop the escape itself
        GetNextChar(C); // consumed escape
        if GetNextChar(NextCh) then
        begin
          if Byte(Ord(NextCh) and $FF) = Byte(Ord(FDialect.Quote) and $FF) then
          begin
            // \" -> '"'
            AppendByte(Byte(FDialect.Quote));
            Continue;
          end
          else if Byte(Ord(NextCh) and $FF) = Byte(Ord(FDialect.Escape) and $FF) then
          begin
            // \\ -> '\'
            AppendByte(Byte(FDialect.Escape));
            Continue;
          end
          else
          begin
            // unknown escape sequence: keep the char after escape
            AppendByte(Byte(NextCh));
            Continue;
          end;
        end
        else
        begin
          // stray escape at end of input: drop it
          Continue;
        end;
      end
      else if Byte(Ord(C) and $FF) = Byte(Ord(FDialect.Quote) and $FF) then
      begin
        // consume current quote and look ahead
        GetNextChar(C);
        if PeekChar(NextCh) and (Byte(Ord(NextCh) and $FF) = Byte(Ord(FDialect.Quote) and $FF)) then
        begin
          // doubled quote inside quoted field -> append one quote
          GetNextChar(NextCh);
          AppendByte(Byte(FDialect.Quote));
          Continue;
        end
        else
        begin
          // closing quote
          InQuotes := False;
          Continue;
        end;
      end
      else
      begin
        // Escape disabled inside quoted field: backslash is literal
        if (FDialect.Escape = #0) and (C = '\') then
        begin
          // Treat backslash literally and do not special-case following quotes here.
          // Let the generic double-quote logic handle any subsequent doubled quotes.
          GetNextChar(C); // consume backslash
          AppendByte(Byte('\'));
          Continue;
        end;
        // Preserve original newlines inside quoted fields (no normalization)
        if C = #13 then
        begin
          GetNextChar(C); // consume CR
          AppendByte(Byte(#13));
          if PeekChar(NextCh) and (NextCh = #10) then
          begin
            GetNextChar(NextCh); // consume LF
            AppendByte(Byte(#10));
          end;
        end
        else if C = #10 then
        begin
          GetNextChar(C); // consume LF
          AppendByte(Byte(#10));
        end
        else
        begin
          GetNextChar(C);
          AppendByte(Byte(C));
        end;
      end;
    end;
  end;
  // end of data: finalize
  if InQuotes then
  begin
    if FDialect.AllowLazyQuotes then
    begin
      // finalize quoted field at EOF (lenient)
      InQuotes := False;
    end
    else
      raise ECSVError.CreatePosEx('CSV error: unterminated quoted field', FRecordStartLine, 1, csvErrUnterminatedQuote);
  end;
  if not EmittedOnBreak then
  begin
    // 如果本记录没有任何内容（BufLen=0 且尚未发出字段），则这是空输入末尾，不生成记录
    if (FieldCount = 0) and (BufLen = 0) then Exit(False);
    // 在 EOF 一定发出一个字段：
    // - 常规情况：BufLen>0 发出最后一个字段
    // - 以分隔符结尾：BufLen=0 发出空字段，确保 'a,b,' 解析为 3 个字段
    EmitField;
  end;
  // Strictness checks (skip once for header if requested)
  if (not FDialect.AllowVariableFields) and (not FSkipStrict) then
  begin
    if FExpectedFields = -1 then
    begin
      // 不使用“全空字段行”设定严格字段数基线（例如 ',,,' 或 ''）
      AllEmpty := True;
      for K := 0 to High(Fields) do
        if Fields[K] <> '' then begin AllEmpty := False; Break; end;
      if not AllEmpty then
      begin
        // 若上一条记录是“全空字段行”，基线应使用本条 FieldCount
        FExpectedFields := FieldCount;
      end
      else
      begin
        // 留待下一条非空记录设定
      end;
    end
    else if FieldCount <> FExpectedFields then
      raise ECSVError.CreatePosEx('CSV error: field count mismatch', FRecordStartLine, FRecordStartCol, csvErrFieldCountMismatch);
  end
  else if FSkipStrict then
    FSkipStrict := False;
  Result := True;
end;

function TCSVReaderImpl.ReadNext(out Rec: ICSVRecord): Boolean;
var
  Fields: TStringArray;
  i: SizeInt;
begin
  // parse headers once
  if (not FHeadersParsed) and FDialect.HasHeader then
  begin
    if not ParseRecord(FHeaders) then Exit(False);
    FHeadersParsed := True;
    // header should not determine strict field count
    FSkipStrict := True;
    // Apply TrimMode for headers (csvTrimHeaders or csvTrimAll)
    if (FDialect.TrimMode = csvTrimHeaders) or (FDialect.TrimMode = csvTrimAll) then
      for i := 0 to High(FHeaders) do
        FHeaders[i] := Trim(FHeaders[i]);
  end
  else if (not FHeadersParsed) then
  begin
    // no header mode
    FHeadersParsed := True;
  end;

  // 每条记录开始前清空行缓冲与索引表
  FRowBuf := '';
  SetLength(FOffsets, 0);
  SetLength(FLengths, 0);
  SetLength(FWasQuoted, 0);
  if not ParseRecord(Fields) then Exit(False);
  // TrimMode 控制：数据字段 trim（csvTrimFields 或 csvTrimAll）
  // 同时支持向后兼容：如果 TrimSpaces=True 但 TrimMode=csvTrimNone，也 trim 数据字段
  if (FDialect.TrimMode = csvTrimFields) or (FDialect.TrimMode = csvTrimAll)
     or ((FDialect.TrimSpaces) and (FDialect.TrimMode = csvTrimNone)) then
  begin
    for i := 0 to High(Fields) do
      if (i >= Length(FWasQuoted)) or (not FWasQuoted[i]) then
        Fields[i] := Trim(Fields[i]);
  end;
  if FReuseRecord and Assigned(FCurrentRecord) then
  begin
    (FCurrentRecord as TCSVRecordImpl).AssignParsedEx(Fields, FHeaders, FRowBuf, FOffsets, FLengths, FWasQuoted,
      FRecordKind, FDialect.TrimSpaces, FDialect.StrictUTF8, FDialect.ReplaceInvalidUTF8);
    (FCurrentRecord as TCSVRecordImpl).SetNameMatchMode(FDialect.NameMatchMode);
    Rec := FCurrentRecord;
  end
  else if FReuseRecord then
  begin
    FCurrentRecord := TCSVRecordImpl.Create(Fields, FHeaders, FRowBuf, FOffsets, FLengths);
    (FCurrentRecord as TCSVRecordImpl).AssignParsedEx(Fields, FHeaders, FRowBuf, FOffsets, FLengths, FWasQuoted,
      FRecordKind, FDialect.TrimSpaces, FDialect.StrictUTF8, FDialect.ReplaceInvalidUTF8);
    (FCurrentRecord as TCSVRecordImpl).SetNameMatchMode(FDialect.NameMatchMode);
    Rec := FCurrentRecord;
  end
  else
  begin
    Rec := TCSVRecordImpl.Create(Fields, FHeaders, FRowBuf, FOffsets, FLengths);
    (Rec as TCSVRecordImpl).AssignParsedEx(Fields, FHeaders, FRowBuf, FOffsets, FLengths, FWasQuoted,
      FRecordKind, FDialect.TrimSpaces, FDialect.StrictUTF8, FDialect.ReplaceInvalidUTF8);
    (Rec as TCSVRecordImpl).SetNameMatchMode(FDialect.NameMatchMode);
  end;
  Result := True;
end;

function TCSVReaderImpl.ReadAll: TCSVTable;
var
  L: SizeInt;
  Fields: TStringArray;
  i: SizeInt;
  Tmp: RawByteString;
begin
  SetLength(Result, 0);
  // consume header if present
  if (not FHeadersParsed) and FDialect.HasHeader then
  begin
    if not ParseRecord(FHeaders) then Exit(Result);
    FHeadersParsed := True;
    // header should not determine strict field count
    FSkipStrict := True;
  end
  else if (not FHeadersParsed) then
  begin
    FHeadersParsed := True;
  end;

  while ParseRecord(Fields) do
  begin
    // Bytes 模式：此处按需批量解码，确保 ReadAll 返回的表格与 Unicode 模式一致
    if FRecordKind = csvRecordBytes then
    begin
      // 构造一个临时记录视图以复用 EnsureFieldDecoded 逻辑较重，不值得
      // 简化：直接在此处逐字段手动解码（复用解析阶段 UTF-8 策略与 TrimSpaces/WasQuoted）
      // 当前 ParseRecord 已把 FRowBuf/FOffsets/FLengths/WasQuoted 填好，可以直接逐字段解码
      for i := 0 to High(Fields) do
      begin
        if (i < Length(FOffsets)) and (i < Length(FLengths)) then
        begin
          if FLengths[i] = 0 then
          begin
            Fields[i] := '';
            Continue;
          end;
          SetString(Tmp, PAnsiChar(Pointer(FRowBuf)) + (FOffsets[i]-1), FLengths[i]);
          SetCodePage(Tmp, CP_UTF8, False);
          if FDialect.StrictUTF8 then
          begin
            if not IsValidUTF8(Tmp) then
              raise ECSVError.CreatePosEx('CSV error: invalid UTF-8 sequence', FRecordStartLine, FRecordStartCol, csvErrInvalidUTF8);
            Fields[i] := UTF8Decode(Tmp);
          end
          else if FDialect.ReplaceInvalidUTF8 then
            Fields[i] := UTF8Decode(Tmp)
          else
            Fields[i] := UTF8Decode(Tmp);
          if FDialect.TrimSpaces and (not (i < Length(FWasQuoted)) or (not FWasQuoted[i])) then
            Fields[i] := Trim(Fields[i]);
        end;
      end;
    end
    else
    begin
      // Unicode 模式：应用 TrimMode/TrimSpaces
      // TrimMode 控制：数据字段 trim（csvTrimFields 或 csvTrimAll）
      // 同时支持向后兼容：如果 TrimSpaces=True 但 TrimMode=csvTrimNone，也 trim 数据字段
      if (FDialect.TrimMode = csvTrimFields) or (FDialect.TrimMode = csvTrimAll)
         or ((FDialect.TrimSpaces) and (FDialect.TrimMode = csvTrimNone)) then
      begin
        for i := 0 to High(Fields) do
          if (i >= Length(FWasQuoted)) or (not FWasQuoted[i]) then
            Fields[i] := Trim(Fields[i]);
      end;
    end;
    L := Length(Result);
    SetLength(Result, L+1);
    Result[L] := Fields;
  end;
end;

function TCSVReaderBuilder.FromStream(AStream: TStream): ICSVReaderBuilder;
begin
  FStream := AStream;
  FFileName := '';
  Result := Self;
end;

function TCSVReaderBuilder.MaxRecordBytes(const Bytes: SizeUInt): ICSVReaderBuilder;
begin
  FMaxRecordBytes := Bytes;
  Result := Self;
end;

function TCSVReaderBuilder.StrictUTF8(const Enabled: Boolean): ICSVReaderBuilder;
begin
  FStrictUTF8 := Enabled;
  if Enabled then FReplaceInvalidUTF8 := False; // 互斥：Strict 优先
  Result := Self;
end;

function TCSVReaderBuilder.ReplaceInvalidUTF8(const Enabled: Boolean): ICSVReaderBuilder;
begin
  FReplaceInvalidUTF8 := Enabled;
  if Enabled then FStrictUTF8 := False; // 互斥
  Result := Self;
end;

function TCSVReaderBuilder.RecordKind(const Kind: TCSVRecordKind): ICSVReaderBuilder;
begin
  FRecordKind := Kind;
  Result := Self;
end;

function TCSVReaderBuilder.BufferSize(const Bytes: SizeUInt): ICSVReaderBuilder;
begin
  if Bytes > 0 then FBufferSize := Bytes;
  Result := Self;
end;

function TCSVReaderBuilder.ReuseRecord(const Enabled: Boolean): ICSVReaderBuilder;
begin
  FReuseRecord := Enabled;
  Result := Self;
end;

function TCSVReaderBuilder.FromFile(const FileName: string): ICSVReaderBuilder;
begin
  FFileName := FileName;
  FStream := nil;
  Result := Self;
end;

function TCSVReaderBuilder.Dialect(const D: TCSVDialect): ICSVReaderBuilder;
begin
  FDialect := D;
  Result := Self;
end;

function TCSVReaderBuilder.Build: ICSVReader;
var
  LStream: TStream;
  R: TCSVReaderImpl;
  D: TCSVDialect;
begin
  // Apply builder overrides onto a local dialect copy
  D := FDialect;
  if FMaxRecordBytes > 0 then D.MaxRecordBytes := FMaxRecordBytes;
  if FStrictUTF8 then begin D.StrictUTF8 := True; D.ReplaceInvalidUTF8 := False; end
  else if FReplaceInvalidUTF8 then begin D.ReplaceInvalidUTF8 := True; D.StrictUTF8 := False; end;

  if Assigned(FStream) then
  begin
    R := TCSVReaderImpl.Create(FStream, False, D);
    R.SetChunkSize(FBufferSize);
    R.FReuseRecord := FReuseRecord;
    R.FRecordKind := FRecordKind;
    Result := R;
    Exit;
  end;
  if FFileName <> '' then
  begin
    LStream := TFileStream.Create(FFileName, fmOpenRead or fmShareDenyNone);
    R := TCSVReaderImpl.Create(LStream, True, D);
    R.SetChunkSize(FBufferSize);
    R.FReuseRecord := FReuseRecord;
    (R as TCSVReaderImpl).FRecordKind := FRecordKind;
    Result := R;
    Exit;
  end;
  Result := nil;
end;

{ TCSVWriterBuilder }
constructor TCSVWriterBuilder.Create;
begin
  inherited Create;
  FDialect := DefaultRFC4180;
  FStream := nil;
  FFileName := '';
  SetLength(FHeaders, 0);
  FWriteBOM := False;
  FTerminator := csvTermAuto;
end;

function TCSVWriterBuilder.ToStream(AStream: TStream): ICSVWriterBuilder;
begin
  FStream := AStream;
  FFileName := '';
  Result := Self;
end;

function TCSVWriterBuilder.WriteBOM(const Enabled: Boolean): ICSVWriterBuilder;
begin
  FWriteBOM := Enabled;
  Result := Self;
end;

function TCSVWriterBuilder.Terminator(const T: TECSVTerminator): ICSVWriterBuilder;
begin
  FTerminator := T;
  Result := Self;
end;

function TCSVWriterBuilder.ToFile(const FileName: string): ICSVWriterBuilder;
begin
  FFileName := FileName;
  FStream := nil;
  Result := Self;
end;

function TCSVWriterBuilder.Dialect(const D: TCSVDialect): ICSVWriterBuilder;
begin
  FDialect := D;
  Result := Self;
end;

function TCSVWriterBuilder.WithHeaders(const Headers: array of string): ICSVWriterBuilder;
var
  I: SizeInt;
begin
  SetLength(FHeaders, Length(Headers));
  for I := 0 to High(Headers) do
    // Promote to UnicodeString explicitly to avoid implicit Ansi->Unicode conversion warnings
    FHeaders[I] := UnicodeString(Headers[I]);
  Result := Self;
end;

function TCSVWriterBuilder.Delimiter(const Ch: WideChar): ICSVWriterBuilder;
begin
  FDialect.Delimiter := Ch;
  Result := Self;
end;

function TCSVWriterBuilder.Quote(const Ch: WideChar): ICSVWriterBuilder;
begin
  FDialect.Quote := Ch;
  Result := Self;
end;

function TCSVWriterBuilder.DoubleQuote(const Enabled: Boolean): ICSVWriterBuilder;
begin
  FDialect.DoubleQuote := Enabled;
  Result := Self;
end;

function TCSVWriterBuilder.QuoteMode(const Mode: TECSVQuoteMode): ICSVWriterBuilder;
begin
  FDialect.QuoteMode := Mode;
  Result := Self;
end;

function TCSVWriterBuilder.UseCRLF(const Enabled: Boolean): ICSVWriterBuilder;
begin
  FDialect.UseCRLF := Enabled;
  Result := Self;
end;

function TCSVWriterBuilder.Escape(const Ch: WideChar): ICSVWriterBuilder;
begin
  FDialect.Escape := Ch;
  Result := Self;
end;

function TCSVWriterBuilder.Build: ICSVWriter;
var
  LStream: TStream;
begin
  // Apply terminator override to dialect before constructing the writer
  if FTerminator <> csvTermAuto then
    FDialect.Terminator := FTerminator;

  if Assigned(FStream) then
    Exit(TCSVWriterImpl.Create(FStream, False, FDialect, FHeaders, FWriteBOM));

  if FFileName <> '' then
  begin
    // Create or truncate, then reopen with shared read/write so readers can open concurrently
    if FileExists(FFileName) then
    begin
      LStream := TFileStream.Create(FFileName, fmOpenReadWrite or fmShareDenyNone);
      try
        LStream.Size := 0; // truncate
      except
        LStream.Free;
        raise;
      end;
    end
    else
    begin
      // ensure file exists
      LStream := TFileStream.Create(FFileName, fmCreate);
      FreeAndNil(LStream);
      LStream := TFileStream.Create(FFileName, fmOpenReadWrite or fmShareDenyNone);
    end;
    Exit(TCSVWriterImpl.Create(LStream, True, FDialect, FHeaders, FWriteBOM));
  end;
  Result := nil;
end;

end.
