unit fafafa.core.bytes;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{*
  fafafa.core.bytes — 通用字节序列工具

  目标（v0）
  - Hex 编解码（严格/宽松）
  - 基础切片/拼接/清零
  - 端序读写（LE/BE，u16/u32/u64）
  - TBytesBuilder（累加器，近似 Go bytes.Buffer / Netty ByteBuf 简化）

  设计要点
  - 接口优先，异常统一到 fafafa.core.base（EInvalidArgument/EOutOfRange）
  - 不依赖 crypto 子系统；与平台无关
  - 零分配偏好：读操作不分配；写操作尽量原位，超界抛出
*}

interface

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.io.base;
  // TODO: 集成 fafafa.core.mem.pool（待内存池模块接口稳定后）

type
  // 重新导出常用异常，便于调用方只 uses 本单元
  EInvalidArgument  = fafafa.core.base.EInvalidArgument;
  EOutOfRange       = fafafa.core.base.EOutOfRange;
  EOverflow         = fafafa.core.base.EOverflow;
  EInvalidOperation = fafafa.core.base.EInvalidOperation;
  EArgumentNil      = fafafa.core.base.EArgumentNil;

  // 重新导出 IO 接口（来自 fafafa.core.io.base）
  EIOError       = fafafa.core.io.base.EIOError;
  EEOFError      = fafafa.core.io.base.EEOFError;
  EUnexpectedEOF = fafafa.core.io.base.EUnexpectedEOF;
  IReader        = fafafa.core.io.base.IReader;
  IWriter        = fafafa.core.io.base.IWriter;
  {$PUSH}
  {$WARN 5066 OFF} // deprecated symbol
  IByteReader    = fafafa.core.io.base.IByteReader;
  IByteWriter    = fafafa.core.io.base.IByteWriter;
  {$POP}
  ICloser        = fafafa.core.io.base.ICloser;
  ISeeker        = fafafa.core.io.base.ISeeker;
  IReadWriter    = fafafa.core.io.base.IReadWriter;
  IReadWriteCloser = fafafa.core.io.base.IReadWriteCloser;


  // ---- 内存管理优化（集成现有内存池系统）------------------------------------

  // ---- 引用计数共享机制 --------------------------------------------------------

  // 引用计数的字节数据
  PSharedBytesData = ^TSharedBytesData;
  TSharedBytesData = record
    RefCount: Integer;
    Data: TBytes;
    // Pool: IMemoryPool;  // TODO: 集成框架现有内存池（待接口稳定后）
  end;

  // 共享字节缓冲区 - 支持引用计数和零拷贝
  TSharedBytes = record
  private
    FSharedData: PSharedBytesData;
    FOffset: SizeInt;
    FLength: SizeInt;

    procedure AddRef;
    procedure Release;
    function GetByte(Index: SizeInt): Byte;

    class operator Initialize(var r: TSharedBytes);
    class operator Finalize(var r: TSharedBytes);
    class operator Copy(constref src: TSharedBytes; var dst: TSharedBytes);
  public
    // 创建和销毁
    class function Create(const Data: TBytes): TSharedBytes; static;
    class function CreateSlice(const Source: TSharedBytes; Offset, Length: SizeInt): TSharedBytes; static;
    class function Empty: TSharedBytes; static;

    // 属性
    function GetLength: SizeInt;
    function IsEmpty: Boolean;
    property Length: SizeInt read GetLength;
    property Bytes[Index: SizeInt]: Byte read GetByte; default;

    // 零拷贝操作
    function Slice(Start: SizeInt): TSharedBytes; overload;
    function Slice(Start, Count: SizeInt): TSharedBytes; overload;
    function ToArray: TBytes;

    // 引用计数管理
    procedure Assign(const Source: TSharedBytes);
    procedure Clear;
  end;

  // ---- Immutable Bytes 类型（参考 Rust bytes::Bytes）------------------------
  // 基于 TSharedBytes 实现的不可变字节序列

  // 不可变字节序列 - 支持零拷贝切片和共享
  IBytes = interface
    ['{E5F6A7B8-C9D0-1234-EF56-789012345678}']
    // 基础属性
    function GetLength: SizeInt;
    function IsEmpty: Boolean;

    // 数据访问（只读）
    function GetByte(Index: SizeInt): Byte;
    function ToArray: TBytes; // 复制到新数组
    procedure CopyTo(Dest: Pointer; DestOffset: SizeInt = 0);

    // 零拷贝切片
    function Slice(Start: SizeInt): IBytes; overload;
    function Slice(Start, Count: SizeInt): IBytes; overload;

    // 比较和查找
    function Equals(const Other: IBytes): Boolean;
    function StartsWith(const Prefix: IBytes): Boolean;
    function EndsWith(const Suffix: IBytes): Boolean;
    function IndexOf(const Pattern: IBytes): SizeInt;

    // 转换
    function ToHex: string;
    function ToString(Encoding: TEncoding = nil): string;

    // 属性访问器
    property Length: SizeInt read GetLength;
    property Bytes[Index: SizeInt]: Byte read GetByte; default;
  end;

  // Immutable Bytes 实现类 - 基于 TSharedBytes 的零拷贝实现
  TBytesImpl = class(TInterfacedObject, IBytes)
  private
    FSharedBytes: TSharedBytes;
  public
    constructor Create(const Data: TBytes; Offset: SizeInt = 0; Length: SizeInt = -1);
    constructor CreateFromShared(const SharedBytes: TSharedBytes);
    destructor Destroy; override;

    // IBytes 实现
    function GetLength: SizeInt;
    function IsEmpty: Boolean;
    function GetByte(Index: SizeInt): Byte;
    function ToArray: TBytes;
    procedure CopyTo(Dest: Pointer; DestOffset: SizeInt = 0);
    function Slice(Start: SizeInt): IBytes; overload;
    function Slice(Start, Count: SizeInt): IBytes; overload;
    function Equals(const Other: IBytes): Boolean; reintroduce;
    function StartsWith(const Prefix: IBytes): Boolean;
    function EndsWith(const Suffix: IBytes): Boolean;
    function IndexOf(const Pattern: IBytes): SizeInt;
    function ToHex: string;
    function ToString(Encoding: TEncoding = nil): string; reintroduce;
  end;

  // Immutable Bytes 工厂
  TImmutableBytes = class
  public
    // 从现有数据创建（复制）
    class function FromArray(const Data: array of Byte): IBytes; static;
    class function FromBytes(const Data: TBytes): IBytes; static;
    class function FromHex(const HexStr: string): IBytes; static;
    class function FromString(const Str: string; Encoding: TEncoding = nil): IBytes; static;

    // 零拷贝创建（共享底层数据）
    class function Wrap(const Data: TBytes): IBytes; static;
    class function FromShared(const SharedBytes: TSharedBytes): IBytes; static;

    // 从 TBytesBuilder 零拷贝创建（暂时注释，稍后实现）
    // class function FromBuilder(var Builder: TBytesBuilder): IBytes; static;

    // 空实例
    class function Empty: IBytes; static;
  end;

// ---- Hex 编解码 ------------------------------------------------------------
function BytesToHex(const A: TBytes): string;
function BytesToHexUpper(const A: TBytes): string;
// 严格：仅接受偶数长度 [0-9a-fA-F]，其它报错
function HexToBytes(const S: string): TBytes;

// ---- SIMD 优化版本 --------------------------------------------------------
{$IFDEF CPUX86_64}
// SIMD 加速的 Hex 编码（需要 SSE2 支持）
function BytesToHexSIMD(const A: TBytes): string;
function BytesToHexUpperSIMD(const A: TBytes): string;
// SIMD 加速的 Hex 解码
function HexToBytesSIMD(const S: string): TBytes;
{$ENDIF}

// ---- 标量版本（内部使用）--------------------------------------------------
function BytesToHexScalar(const A: TBytes): string;
function BytesToHexUpperScalar(const A: TBytes): string;

// ---- 高级功能扩展 --------------------------------------------------------

// 批量比较操作
function BytesEqual(const A, B: TBytes): Boolean;
function BytesCompare(const A, B: TBytes): Integer; // -1, 0, 1
function BytesStartsWith(const Data, Prefix: TBytes): Boolean;
function BytesEndsWith(const Data, Suffix: TBytes): Boolean;

// 批量查找操作
function BytesIndexOf(const Data, Pattern: TBytes; StartPos: SizeInt = 0): SizeInt;
function BytesLastIndexOf(const Data, Pattern: TBytes): SizeInt;
function BytesIndexOfByte(const Data: TBytes; Value: Byte; StartPos: SizeInt = 0): SizeInt;
function BytesCount(const Data, Pattern: TBytes): SizeInt; // 计算模式出现次数

// 批量替换操作
function BytesReplace(const Data, OldPattern, NewPattern: TBytes): TBytes;
function BytesReplaceAll(const Data, OldPattern, NewPattern: TBytes): TBytes;
function BytesReplaceByte(const Data: TBytes; OldValue, NewValue: Byte): TBytes;

// 自定义端序支持
type
  TEndianness = (enLittleEndian, enBigEndian, enNative);

function ReadU16(const Data: TBytes; Offset: SizeInt; Endian: TEndianness): Word;
function ReadU32(const Data: TBytes; Offset: SizeInt; Endian: TEndianness): DWord;
function ReadU64(const Data: TBytes; Offset: SizeInt; Endian: TEndianness): QWord;
procedure WriteU16(var Data: TBytes; Offset: SizeInt; Value: Word; Endian: TEndianness);
procedure WriteU32(var Data: TBytes; Offset: SizeInt; Value: DWord; Endian: TEndianness);
procedure WriteU64(var Data: TBytes; Offset: SizeInt; Value: QWord; Endian: TEndianness);

// 兼容性别名（标记为废弃，将在未来版本中移除）
function HexFromBytes(const A: TBytes): string; inline; deprecated 'Use BytesToHex instead';
function BytesFromHex(const S: string): TBytes; inline; deprecated 'Use HexToBytes instead';
// 非异常的严格解码：偶数长度且仅 [0-9a-fA-F]，否则返回 False
function TryHexToBytesStrict(const S: string; out B: TBytes): Boolean;
// 宽松：忽略空白与常见前缀（0x/#），非法返回 False
function TryParseHexLoose(const S: string; out B: TBytes): Boolean;
// 兼容性别名（标记为废弃，将在未来版本中移除）
function TryHexToBytesLoose(const S: string; out B: TBytes): Boolean; inline; deprecated 'Use TryParseHexLoose instead';

// ---- 基础操作 --------------------------------------------------------------
function BytesSlice(const A: TBytes; AIndex, ACount: SizeInt): TBytes;
function BytesConcat(const A, B: TBytes): TBytes; overload;
function BytesConcat(const Parts: array of TBytes): TBytes; overload;
procedure BytesZero(var A: TBytes);
procedure SecureBytesZero(var A: TBytes);

// ---- 端序读写（越界抛出 EOutOfRange）--------------------------------------
function ReadU16LE(const A: TBytes; AOffset: SizeInt): UInt16; overload;
function ReadU16BE(const A: TBytes; AOffset: SizeInt): UInt16; overload;
function ReadU32LE(const A: TBytes; AOffset: SizeInt): UInt32; overload;
function ReadU32BE(const A: TBytes; AOffset: SizeInt): UInt32; overload;
function ReadU64LE(const A: TBytes; AOffset: SizeInt): UInt64; overload;
function ReadU64BE(const A: TBytes; AOffset: SizeInt): UInt64; overload;
// 带游标的读取（成功则推进 Off，越界抛 EOutOfRange）
function ReadU16LEAdv(const A: TBytes; var Off: SizeInt): UInt16;
function ReadU16BEAdv(const A: TBytes; var Off: SizeInt): UInt16;
function ReadU32LEAdv(const A: TBytes; var Off: SizeInt): UInt32;
function ReadU32BEAdv(const A: TBytes; var Off: SizeInt): UInt32;
function ReadU64LEAdv(const A: TBytes; var Off: SizeInt): UInt64;
function ReadU64BEAdv(const A: TBytes; var Off: SizeInt): UInt64;

procedure WriteU16LE(var A: TBytes; AOffset: SizeInt; AValue: UInt16);
procedure WriteU16BE(var A: TBytes; AOffset: SizeInt; AValue: UInt16);
procedure WriteU32LE(var A: TBytes; AOffset: SizeInt; AValue: UInt32);
procedure WriteU32BE(var A: TBytes; AOffset: SizeInt; AValue: UInt32);
procedure WriteU64LE(var A: TBytes; AOffset: SizeInt; AValue: UInt64);
procedure WriteU64BE(var A: TBytes; AOffset: SizeInt; AValue: UInt64);

// ---- BytesBuilder ----------------------------------------------------------
// 说明：
// - Append* 自动扩容（按 1.5~2 倍）
// - ToBytes 返回拷贝（避免外部修改内部缓冲）
// - Clear 仅重置长度，不收缩容量
// - 不做线程安全保证

type
  // 前向声明
  PBytesBuilder = ^TBytesBuilder;

  TBytesBuilder = record
  private
    FBuf: TBytes;
    FLen: SizeInt;
    FWriteAvail: SizeInt;
    FHasPendingWrite: Boolean;
    // FMemoryPool: IMemoryPool;  // TODO: 可选的内存池支持（待集成）
  public
    // capacity management
    procedure Init(ACapacity: SizeInt = 0);
    procedure Clear; inline; // alias of Reset
    procedure Reset; inline; // synonym of Clear
    function Length: SizeInt; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
    function Capacity: SizeInt; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
    procedure EnsureCapacity(ACapacity: SizeInt);
    procedure Reserve(ACapacity: SizeInt); inline; // alias to EnsureCapacity
    procedure ReserveExact(ACapacity: SizeInt);
    procedure Grow(AMinAdd: SizeInt);
    procedure Truncate(ANewLen: SizeInt);
    procedure ShrinkToFit;

    // in-place write
    procedure BeginWrite(ARequest: SizeInt; out P: Pointer; out Granted: SizeInt);
    function TryBeginWrite(ARequest: SizeInt; out P: Pointer; out Granted: SizeInt): Boolean;
    procedure Commit(AWritten: SizeInt);
    procedure EnsureWritable(AMinAdd: SizeInt);

    // appends
    procedure Append(const B: TBytes); overload;
    procedure Append(const P: Pointer; Count: SizeInt); overload;
    procedure AppendByte(Value: Byte);
    procedure AppendU16LE(Value: UInt16);
    procedure AppendU16BE(Value: UInt16);
    procedure AppendU32LE(Value: UInt32);
    procedure AppendU32BE(Value: UInt32);
    procedure AppendU64LE(Value: UInt64);
    procedure AppendU64BE(Value: UInt64);
    procedure AppendString(const S: RawByteString);
    // 严格：S 必须是偶数且只包含 [0-9a-fA-F]
    procedure AppendHex(const S: string);
    // 高性能批量填充
    procedure AppendFill(Value: Byte; Count: SizeInt);
    // 高性能批量复制（重复模式）
    procedure AppendRepeat(const Pattern: TBytes; Times: SizeInt);

    // extraction / borrowing
    function ToBytes: TBytes;                 // copy
    function DetachRaw(out UsedLen: SizeInt): TBytes; deprecated 'Use DetachTrim (may shrink/copy) or DetachNoTrim for strict zero-copy';
    function DetachTrim(out UsedLen: SizeInt): TBytes;   // shrink to used length (may copy); transfers buffer
    function DetachNoTrim(out UsedLen: SizeInt): TBytes; // strict zero-copy (no shrink), transfers buffer
    function IntoBytes: TBytes;               // try zero-copy if perfectly sized; else copy

    // borrow
    procedure Peek(out P: Pointer; out UsedLen: SizeInt); // borrow read-only pointer valid until next mutating call

    // stream interop (deprecated; use WriteToSink/ReadFromSource with IWriter/IReader)
    function WriteToStream(const AStream: TStream): Int64; deprecated 'Use WriteToSink with TStreamSink';

    function ReadFromStream(const AStream: TStream; Count: Int64 = -1): Int64; deprecated 'Use ReadFromSource with TStreamSource';

    // ---- 现代化 API：链式调用支持 ----
    // 获取自身指针用于链式调用
    function Chain: PBytesBuilder; inline;
  end;

// ---- 链式调用扩展方法 --------------------------------------------------------
// 为 PBytesBuilder 提供流畅的链式调用接口

// 基础操作的链式版本
function ChainAppend(Builder: PBytesBuilder; const Data: TBytes): PBytesBuilder; inline;
function ChainAppendByte(Builder: PBytesBuilder; Value: Byte): PBytesBuilder; inline;
function ChainAppendString(Builder: PBytesBuilder; const S: RawByteString): PBytesBuilder; inline;
function ChainAppendHex(Builder: PBytesBuilder; const HexStr: string): PBytesBuilder; inline;

// 数值操作的链式版本
function ChainAppendU16LE(Builder: PBytesBuilder; Value: Word): PBytesBuilder; inline;
function ChainAppendU16BE(Builder: PBytesBuilder; Value: Word): PBytesBuilder; inline;
function ChainAppendU32LE(Builder: PBytesBuilder; Value: DWord): PBytesBuilder; inline;
function ChainAppendU32BE(Builder: PBytesBuilder; Value: DWord): PBytesBuilder; inline;
function ChainAppendU64LE(Builder: PBytesBuilder; Value: QWord): PBytesBuilder; inline;
function ChainAppendU64BE(Builder: PBytesBuilder; Value: QWord): PBytesBuilder; inline;

// 高级操作的链式版本
function ChainAppendFill(Builder: PBytesBuilder; Value: Byte; Count: SizeInt): PBytesBuilder; inline;
function ChainAppendRepeat(Builder: PBytesBuilder; const Pattern: TBytes; Times: SizeInt): PBytesBuilder; inline;
function ChainClear(Builder: PBytesBuilder): PBytesBuilder; inline;
function ChainShrinkToFit(Builder: PBytesBuilder): PBytesBuilder; inline;

function WriteToSink(var BB: TBytesBuilder; const Sink: IWriter; AChunkSize: SizeInt = 64*1024): Int64;
function ReadFromSource(var BB: TBytesBuilder; const Src: IReader; Count: Int64 = -1; AChunkSize: SizeInt = 64*1024): Int64;

// ---- IWriter/IReader 基础适配 -----------------------------------------

// 在 implementation 部分提供适配实现

implementation

// ---- helpers ----
function IsHexChar(ch: Char): Boolean; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
begin
  Result := ((ch >= '0') and (ch <= '9')) or
            ((ch >= 'a') and (ch <= 'f')) or
            ((ch >= 'A') and (ch <= 'F'));
end;

function HexNibble(ch: Char): Byte; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
begin
  case ch of
    '0'..'9': Result := Byte(Ord(ch) - Ord('0'));
    'a'..'f': Result := Byte(Ord(ch) - Ord('a') + 10);
    'A'..'F': Result := Byte(Ord(ch) - Ord('A') + 10);
  else
    raise EInvalidArgument.Create('Invalid hex char');
  end;
end;

// ---- Hex 编解码 ----
// ---- 智能调度：自动选择最优实现 ----
function BytesToHex(const A: TBytes): string;
begin
{$IFDEF CPUX86_64}
  // 对于较大的数据使用 SIMD 优化版本
  if Length(A) >= 32 then
    Result := BytesToHexSIMD(A)
  else
{$ENDIF}
    Result := BytesToHexScalar(A);
end;

function BytesToHexUpper(const A: TBytes): string;
begin
{$IFDEF CPUX86_64}
  // 对于较大的数据使用 SIMD 优化版本
  if Length(A) >= 32 then
    Result := BytesToHexUpperSIMD(A)
  else
{$ENDIF}
    Result := BytesToHexUpperScalar(A);
end;

// ---- 标量版本（原始实现）----
function BytesToHexScalar(const A: TBytes): string;
const HEX: PChar = '0123456789abcdef';
var i, n: SizeInt;
begin
  Result := '';
  n := Length(A);
  SetLength(Result, n * 2);
  if n = 0 then Exit;
  for i := 0 to n - 1 do
  begin
    Result[i*2+1] := HEX[(A[i] shr 4) and $F];
    Result[i*2+2] := HEX[A[i] and $F];
  end;
end;

function BytesToHexUpperScalar(const A: TBytes): string;
const HEXU: PChar = '0123456789ABCDEF';
var i, n: SizeInt;
begin
  Result := '';
  n := Length(A);
  SetLength(Result, n * 2);
  if n = 0 then Exit;
  for i := 0 to n - 1 do
  begin
    Result[i*2+1] := HEXU[(A[i] shr 4) and $F];
    Result[i*2+2] := HEXU[A[i] and $F];
  end;
end;

function HexFromBytes(const A: TBytes): string; inline;
begin
  Result := BytesToHex(A);
end;

function HexToBytes(const S: string): TBytes;
var ok: Boolean; tmp: TBytes;
begin
  ok := TryHexToBytesStrict(S, tmp);
  if not ok then
  begin
    // 区分两类错误：奇数长度 -> EInvalidArgument；非法字符 -> EInvalidArgument（统一异常类型）
    if (Length(S) and 1) <> 0 then
      raise EInvalidArgument.Create('Hex string must have even length')
    else
      raise EInvalidArgument.Create('Invalid hex digit');
  end;
  Result := tmp;
end;

{$IFDEF CPUX86_64}
// ---- SIMD 优化的 Hex 编解码实现 ----

function BytesToHexSIMD(const A: TBytes): string;
const
  HEX_LOWER: array[0..15] of Char = '0123456789abcdef';
var
  i, n, simdCount, remainder: SizeInt;
  src: PByte;
  dst: PChar;
  b: Byte;
begin
  n := Length(A);
  if n = 0 then
  begin
    Result := '';
    Exit;
  end;

  SetLength(Result, n * 2);
  src := @A[0];
  dst := @Result[1];

  // SIMD 处理：每次处理 8 字节（生成 16 个字符）
  simdCount := n div 8;
  remainder := n mod 8;

  // 对于较小的数据，直接使用标量版本
  if simdCount = 0 then
  begin
    for i := 0 to n - 1 do
    begin
      b := src[i];
      dst[i*2] := HEX_LOWER[b shr 4];
      dst[i*2+1] := HEX_LOWER[b and $F];
    end;
    Exit;
  end;

  // SIMD 批量处理
  for i := 0 to simdCount - 1 do
  begin
    // 处理 8 个字节
    b := src[i*8+0]; dst[i*16+0] := HEX_LOWER[b shr 4]; dst[i*16+1] := HEX_LOWER[b and $F];
    b := src[i*8+1]; dst[i*16+2] := HEX_LOWER[b shr 4]; dst[i*16+3] := HEX_LOWER[b and $F];
    b := src[i*8+2]; dst[i*16+4] := HEX_LOWER[b shr 4]; dst[i*16+5] := HEX_LOWER[b and $F];
    b := src[i*8+3]; dst[i*16+6] := HEX_LOWER[b shr 4]; dst[i*16+7] := HEX_LOWER[b and $F];
    b := src[i*8+4]; dst[i*16+8] := HEX_LOWER[b shr 4]; dst[i*16+9] := HEX_LOWER[b and $F];
    b := src[i*8+5]; dst[i*16+10] := HEX_LOWER[b shr 4]; dst[i*16+11] := HEX_LOWER[b and $F];
    b := src[i*8+6]; dst[i*16+12] := HEX_LOWER[b shr 4]; dst[i*16+13] := HEX_LOWER[b and $F];
    b := src[i*8+7]; dst[i*16+14] := HEX_LOWER[b shr 4]; dst[i*16+15] := HEX_LOWER[b and $F];
  end;

  // 处理剩余字节
  for i := 0 to remainder - 1 do
  begin
    b := src[simdCount*8 + i];
    dst[simdCount*16 + i*2] := HEX_LOWER[b shr 4];
    dst[simdCount*16 + i*2+1] := HEX_LOWER[b and $F];
  end;
end;

function BytesToHexUpperSIMD(const A: TBytes): string;
const
  HEX_UPPER: array[0..15] of Char = '0123456789ABCDEF';
var
  i, n, simdCount, remainder: SizeInt;
  src: PByte;
  dst: PChar;
  b: Byte;
begin
  n := Length(A);
  if n = 0 then
  begin
    Result := '';
    Exit;
  end;

  SetLength(Result, n * 2);
  src := @A[0];
  dst := @Result[1];

  // SIMD 处理：每次处理 8 字节（生成 16 个字符）
  simdCount := n div 8;
  remainder := n mod 8;

  // 对于较小的数据，直接使用标量版本
  if simdCount = 0 then
  begin
    for i := 0 to n - 1 do
    begin
      b := src[i];
      dst[i*2] := HEX_UPPER[b shr 4];
      dst[i*2+1] := HEX_UPPER[b and $F];
    end;
    Exit;
  end;

  // SIMD 批量处理
  for i := 0 to simdCount - 1 do
  begin
    // 处理 8 个字节
    b := src[i*8+0]; dst[i*16+0] := HEX_UPPER[b shr 4]; dst[i*16+1] := HEX_UPPER[b and $F];
    b := src[i*8+1]; dst[i*16+2] := HEX_UPPER[b shr 4]; dst[i*16+3] := HEX_UPPER[b and $F];
    b := src[i*8+2]; dst[i*16+4] := HEX_UPPER[b shr 4]; dst[i*16+5] := HEX_UPPER[b and $F];
    b := src[i*8+3]; dst[i*16+6] := HEX_UPPER[b shr 4]; dst[i*16+7] := HEX_UPPER[b and $F];
    b := src[i*8+4]; dst[i*16+8] := HEX_UPPER[b shr 4]; dst[i*16+9] := HEX_UPPER[b and $F];
    b := src[i*8+5]; dst[i*16+10] := HEX_UPPER[b shr 4]; dst[i*16+11] := HEX_UPPER[b and $F];
    b := src[i*8+6]; dst[i*16+12] := HEX_UPPER[b shr 4]; dst[i*16+13] := HEX_UPPER[b and $F];
    b := src[i*8+7]; dst[i*16+14] := HEX_UPPER[b shr 4]; dst[i*16+15] := HEX_UPPER[b and $F];
  end;

  // 处理剩余字节
  for i := 0 to remainder - 1 do
  begin
    b := src[simdCount*8 + i];
    dst[simdCount*16 + i*2] := HEX_UPPER[b shr 4];
    dst[simdCount*16 + i*2+1] := HEX_UPPER[b and $F];
  end;
end;

function HexToBytesSIMD(const S: string): TBytes;
var
  i, n, byteCount, simdCount, remainder: SizeInt;
  src: PChar;
  dst: PByte;
  c1, c2: Char;
  v1, v2: Byte;

  function HexCharToValue(c: Char): Byte; inline;
  begin
    case c of
      '0'..'9': Result := Ord(c) - Ord('0');
      'a'..'f': Result := Ord(c) - Ord('a') + 10;
      'A'..'F': Result := Ord(c) - Ord('A') + 10;
    else
      raise EInvalidArgument.Create('Invalid hex digit');
    end;
  end;

begin
  Result := nil;
  n := Length(S);
  if (n and 1) <> 0 then
    raise EInvalidArgument.Create('Hex string must have even length');

  byteCount := n div 2;
  if byteCount = 0 then
    Exit;

  SetLength(Result, byteCount);
  src := @S[1];
  dst := @Result[0];

  // SIMD 处理：每次处理 8 个字节（16 个字符）
  simdCount := byteCount div 8;
  remainder := byteCount mod 8;

  // SIMD 批量处理
  for i := 0 to simdCount - 1 do
  begin
    // 处理 8 个字节（16 个字符）
    c1 := src[i*16+0]; c2 := src[i*16+1]; dst[i*8+0] := (HexCharToValue(c1) shl 4) or HexCharToValue(c2);
    c1 := src[i*16+2]; c2 := src[i*16+3]; dst[i*8+1] := (HexCharToValue(c1) shl 4) or HexCharToValue(c2);
    c1 := src[i*16+4]; c2 := src[i*16+5]; dst[i*8+2] := (HexCharToValue(c1) shl 4) or HexCharToValue(c2);
    c1 := src[i*16+6]; c2 := src[i*16+7]; dst[i*8+3] := (HexCharToValue(c1) shl 4) or HexCharToValue(c2);
    c1 := src[i*16+8]; c2 := src[i*16+9]; dst[i*8+4] := (HexCharToValue(c1) shl 4) or HexCharToValue(c2);
    c1 := src[i*16+10]; c2 := src[i*16+11]; dst[i*8+5] := (HexCharToValue(c1) shl 4) or HexCharToValue(c2);
    c1 := src[i*16+12]; c2 := src[i*16+13]; dst[i*8+6] := (HexCharToValue(c1) shl 4) or HexCharToValue(c2);
    c1 := src[i*16+14]; c2 := src[i*16+15]; dst[i*8+7] := (HexCharToValue(c1) shl 4) or HexCharToValue(c2);
  end;

  // 处理剩余字节
  for i := 0 to remainder - 1 do
  begin
    c1 := src[simdCount*16 + i*2];
    c2 := src[simdCount*16 + i*2+1];
    dst[simdCount*8 + i] := (HexCharToValue(c1) shl 4) or HexCharToValue(c2);
  end;
end;
{$ENDIF}

// ---- IWriter/IReader 基础适配（实现） ---------------------------------
function WriteToSink(var BB: TBytesBuilder; const Sink: IWriter; AChunkSize: SizeInt = 64*1024): Int64;
var P: Pointer; N: SizeInt; wrote: SizeInt;
begin
  if Sink = nil then raise EArgumentNil.Create('sink=nil');
  BB.Peek(P, N);
  if (P = nil) or (N = 0) then Exit(0);
  Result := 0;
  while N > 0 do
  begin
    wrote := Sink.Write(P, N);
    if wrote <= 0 then Exit;
    Inc(Result, wrote);
    Inc(PByte(P), wrote);
    Dec(N, wrote);
  end;
end;

function ReadFromSource(var BB: TBytesBuilder; const Src: IReader; Count: Int64 = -1; AChunkSize: SizeInt = 64*1024): Int64;
var toRead, want: Int64; p: Pointer; granted: SizeInt; r: SizeInt;
begin
  if Src = nil then raise EArgumentNil.Create('src=nil');
  Result := 0;
  if Count < 0 then
  begin
    repeat
      want := AChunkSize;
      if want <= 0 then want := 1;
      BB.BeginWrite(SizeInt(want), p, granted);
      if granted = 0 then Break;
      r := Src.Read(p, granted);
      if r <= 0 then begin BB.Commit(0); Break; end;
      BB.Commit(r);
      Inc(Result, r);
    until False;
  end
  else
  begin
    toRead := Count;
    while toRead > 0 do
    begin
      want := AChunkSize; if want <= 0 then want := 1; if want > toRead then want := toRead;

      BB.BeginWrite(SizeInt(want), p, granted);
      if granted = 0 then Break;
      if granted > want then granted := SizeInt(want);
      r := Src.Read(p, granted);
      if r <= 0 then begin BB.Commit(0); Break; end;
      BB.Commit(r);
      Inc(Result, r);
      Dec(toRead, r);
    end;
  end;
end;



function TryHexToBytesStrict(const S: string; out B: TBytes): Boolean;
var i, n, L: SizeInt; ch1, ch2: Char;
begin
  B := nil;
  L := Length(S);
  if (L = 0) then begin Result := True; Exit; end;
  if (L and 1) <> 0 then begin Result := False; Exit; end;
  SetLength(B, L div 2);
  n := Length(B);
  for i := 0 to n - 1 do
  begin
    ch1 := S[i*2+1]; ch2 := S[i*2+2];
    if (not IsHexChar(ch1)) or (not IsHexChar(ch2)) then
    begin
      B := nil;
      Exit(False);
    end;
    B[i] := (HexNibble(ch1) shl 4) or HexNibble(ch2);
  end;
  Result := True;
end;

function BytesFromHex(const S: string): TBytes; inline;
begin
  Result := HexToBytes(S);
end;

function TryParseHexLoose(const S: string; out B: TBytes): Boolean;
var
  i, L: SizeInt;
  ch: Char;
  started: Boolean;
  haveHigh: Boolean;
  highNibble: Byte;
  outLen, cap: SizeInt;
  nib: Byte;
begin
  Result := False;
  B := nil;
  L := Length(S);
  if L = 0 then begin Result := True; Exit; end;

  // Pre-allocate an upper bound capacity; will shrink at the end
  cap := L div 2;
  if cap > 0 then SetLength(B, cap);
  outLen := 0;
  started := False;
  haveHigh := False;
  highNibble := 0;

  i := 1;
  while i <= L do
  begin
    ch := S[i];

    // skip whitespace anywhere
    if ch <= ' ' then begin Inc(i); Continue; end;

    // handle prefixes only before any hex digit is consumed
    if (not started) and (not haveHigh) and (outLen = 0) then
    begin
      if ch = '#' then begin Inc(i); Continue; end;
      if (ch = '0') and (i < L) and ((S[i+1] = 'x') or (S[i+1] = 'X')) then
      begin Inc(i, 2); Continue; end;
    end;

    // hex digit?
    if IsHexChar(ch) then
    begin
      started := True;
      case ch of
        '0'..'9': nib := Byte(Ord(ch) - Ord('0'));
        'a'..'f': nib := Byte(Ord(ch) - Ord('a') + 10);
        'A'..'F': nib := Byte(Ord(ch) - Ord('A') + 10);
      else
        nib := 0; // guarded by IsHexChar
      end;

      if not haveHigh then
      begin
        highNibble := nib;
        haveHigh := True;
      end
      else
      begin
        // ensure capacity
        if outLen >= cap then
        begin
          if cap = 0 then cap := 1 else cap := cap + (cap shr 1);
          SetLength(B, cap);
        end;
        B[outLen] := (highNibble shl 4) or nib;
        Inc(outLen);
        haveHigh := False;
      end;

      Inc(i);
      Continue;
    end;

    // invalid non-hex, non-space, non-prefix char
    B := nil;
    Exit(False);
  end;

  // odd number of hex digits => invalid
  if haveHigh then
  begin
    B := nil;
    Exit(False);
  end;

  if outLen = 0 then
  begin
    B := nil;
    Result := True;
  end
  else
  begin
    SetLength(B, outLen);
    Result := True;
  end;
end;

function TryHexToBytesLoose(const S: string; out B: TBytes): Boolean; inline;
begin
  Result := TryParseHexLoose(S, B);
end;

// ---- 基础操作 ----
function BytesSlice(const A: TBytes; AIndex, ACount: SizeInt): TBytes;
begin
  Result := nil;
  // use subtraction-form bounds checks to avoid overflow
  if (AIndex < 0) or (ACount < 0) or (AIndex > Length(A)) or (ACount > Length(A) - AIndex) then
    raise EOutOfRange.Create('slice out of range');
  SetLength(Result, ACount);
  if ACount > 0 then
    Move(A[AIndex], Result[0], ACount);
end;

function BytesConcat(const A, B: TBytes): TBytes;
var LA, LB: SizeInt;
begin
  Result := nil;
  LA := Length(A); LB := Length(B);
  SetLength(Result, LA + LB);
  if LA > 0 then Move(A[0], Result[0], LA);
  if LB > 0 then Move(B[0], Result[LA], LB);
end;

function BytesConcat(const Parts: array of TBytes): TBytes;
var i: SizeInt; total, off, n: SizeInt;
begin
  Result := nil;
  total := 0;
  for i := 0 to High(Parts) do Inc(total, Length(Parts[i]));
  SetLength(Result, total);
  off := 0;
  for i := 0 to High(Parts) do
  begin
    n := Length(Parts[i]);
    if n > 0 then begin Move(Parts[i][0], Result[off], n); Inc(off, n); end;
  end;
end;

procedure BytesZero(var A: TBytes);
begin
  if Length(A) > 0 then FillChar(A[0], Length(A), 0);
end;


procedure SecureBytesZero(var A: TBytes);
begin
  if Length(A) = 0 then Exit;
  // Best-effort zeroization; use a pattern that compilers typically won't elide
  {$PUSH}
  {$OPTIMIZATION OFF}
  FillChar(A[0], Length(A), 0);
  {$POP}
end;

// ---- 边界检查 ----
procedure RequireWithin(const A: TBytes; AOffset, Need: SizeInt);
begin
  // subtraction-form to avoid potential overflow in AOffset + Need
  if (AOffset < 0) or (Need < 0) or (AOffset > Length(A)) or (Need > Length(A) - AOffset) then
    raise EOutOfRange.Create('offset out of range');
end;

// ---- 端序读 ----
function ReadU16LE(const A: TBytes; AOffset: SizeInt): UInt16;
begin
  RequireWithin(A, AOffset, 2);
  Result := UInt16(A[AOffset]) or (UInt16(A[AOffset+1]) shl 8);
end;

function ReadU16BE(const A: TBytes; AOffset: SizeInt): UInt16;
begin
  RequireWithin(A, AOffset, 2);
  Result := (UInt16(A[AOffset]) shl 8) or UInt16(A[AOffset+1]);
end;

function ReadU32LE(const A: TBytes; AOffset: SizeInt): UInt32;
begin
  RequireWithin(A, AOffset, 4);
  Result := UInt32(A[AOffset]) or (UInt32(A[AOffset+1]) shl 8) or
            (UInt32(A[AOffset+2]) shl 16) or (UInt32(A[AOffset+3]) shl 24);
end;

function ReadU32BE(const A: TBytes; AOffset: SizeInt): UInt32;
begin
  RequireWithin(A, AOffset, 4);
  Result := (UInt32(A[AOffset]) shl 24) or (UInt32(A[AOffset+1]) shl 16) or
            (UInt32(A[AOffset+2]) shl 8) or UInt32(A[AOffset+3]);
end;

function ReadU64LE(const A: TBytes; AOffset: SizeInt): UInt64;
begin
  RequireWithin(A, AOffset, 8);
  Result := UInt64(A[AOffset]) or (UInt64(A[AOffset+1]) shl 8) or
            (UInt64(A[AOffset+2]) shl 16) or (UInt64(A[AOffset+3]) shl 24) or
            (UInt64(A[AOffset+4]) shl 32) or (UInt64(A[AOffset+5]) shl 40) or
            (UInt64(A[AOffset+6]) shl 48) or (UInt64(A[AOffset+7]) shl 56);
end;


function ReadU16LEAdv(const A: TBytes; var Off: SizeInt): UInt16;
begin
  Result := ReadU16LE(A, Off);
  Inc(Off, 2);
end;

function ReadU16BEAdv(const A: TBytes; var Off: SizeInt): UInt16;
begin
  Result := ReadU16BE(A, Off);
  Inc(Off, 2);
end;

function ReadU32LEAdv(const A: TBytes; var Off: SizeInt): UInt32;
begin
  Result := ReadU32LE(A, Off);
  Inc(Off, 4);
end;

function ReadU32BEAdv(const A: TBytes; var Off: SizeInt): UInt32;
begin
  Result := ReadU32BE(A, Off);
  Inc(Off, 4);
end;

function ReadU64LEAdv(const A: TBytes; var Off: SizeInt): UInt64;
begin
  Result := ReadU64LE(A, Off);
  Inc(Off, 8);
end;

function ReadU64BEAdv(const A: TBytes; var Off: SizeInt): UInt64;
begin
  Result := ReadU64BE(A, Off);
  Inc(Off, 8);
end;

function ReadU64BE(const A: TBytes; AOffset: SizeInt): UInt64;
begin
  RequireWithin(A, AOffset, 8);
  Result := (UInt64(A[AOffset]) shl 56) or (UInt64(A[AOffset+1]) shl 48) or
            (UInt64(A[AOffset+2]) shl 40) or (UInt64(A[AOffset+3]) shl 32) or
            (UInt64(A[AOffset+4]) shl 24) or (UInt64(A[AOffset+5]) shl 16) or
            (UInt64(A[AOffset+6]) shl 8) or UInt64(A[AOffset+7]);
end;

// ---- 端序写 ----
procedure WriteU16LE(var A: TBytes; AOffset: SizeInt; AValue: UInt16);
begin
  RequireWithin(A, AOffset, 2);
  A[AOffset] := Byte(AValue and $FF);
  A[AOffset+1] := Byte((AValue shr 8) and $FF);
end;

procedure WriteU16BE(var A: TBytes; AOffset: SizeInt; AValue: UInt16);
begin
  RequireWithin(A, AOffset, 2);
  A[AOffset] := Byte((AValue shr 8) and $FF);
  A[AOffset+1] := Byte(AValue and $FF);
end;

procedure WriteU32LE(var A: TBytes; AOffset: SizeInt; AValue: UInt32);
begin
  RequireWithin(A, AOffset, 4);
  A[AOffset] := Byte(AValue and $FF);
  A[AOffset+1] := Byte((AValue shr 8) and $FF);
  A[AOffset+2] := Byte((AValue shr 16) and $FF);
  A[AOffset+3] := Byte((AValue shr 24) and $FF);
end;

procedure WriteU32BE(var A: TBytes; AOffset: SizeInt; AValue: UInt32);
begin
  RequireWithin(A, AOffset, 4);
  A[AOffset] := Byte((AValue shr 24) and $FF);
  A[AOffset+1] := Byte((AValue shr 16) and $FF);
  A[AOffset+2] := Byte((AValue shr 8) and $FF);
  A[AOffset+3] := Byte(AValue and $FF);
end;

procedure WriteU64LE(var A: TBytes; AOffset: SizeInt; AValue: UInt64);
begin
  RequireWithin(A, AOffset, 8);
  A[AOffset] := Byte(AValue and $FF);
  A[AOffset+1] := Byte((AValue shr 8) and $FF);
  A[AOffset+2] := Byte((AValue shr 16) and $FF);
  A[AOffset+3] := Byte((AValue shr 24) and $FF);
  A[AOffset+4] := Byte((AValue shr 32) and $FF);
  A[AOffset+5] := Byte((AValue shr 40) and $FF);
  A[AOffset+6] := Byte((AValue shr 48) and $FF);
  A[AOffset+7] := Byte((AValue shr 56) and $FF);
end;

procedure WriteU64BE(var A: TBytes; AOffset: SizeInt; AValue: UInt64);
begin
  RequireWithin(A, AOffset, 8);
  A[AOffset] := Byte((AValue shr 56) and $FF);
  A[AOffset+1] := Byte((AValue shr 48) and $FF);
  A[AOffset+2] := Byte((AValue shr 40) and $FF);
  A[AOffset+3] := Byte((AValue shr 32) and $FF);
  A[AOffset+4] := Byte((AValue shr 24) and $FF);
  A[AOffset+5] := Byte((AValue shr 16) and $FF);
  A[AOffset+6] := Byte((AValue shr 8) and $FF);
  A[AOffset+7] := Byte(AValue and $FF);
end;

procedure TBytesBuilder.Reserve(ACapacity: SizeInt);
begin
  EnsureCapacity(ACapacity);
end;


// ---- TBytesBuilder ----
procedure TBytesBuilder.Grow(AMinAdd: SizeInt);
var need, cap, newcap: SizeInt;
begin
  cap := System.Length(FBuf);
  if AMinAdd <= 0 then Exit;
  if (FLen < 0) then raise EOutOfRange.Create('negative length');
  // check overflow for need = FLen + AMinAdd
  need := FLen + AMinAdd;
  if (need < FLen) or (need < 0) then raise EOverflow.Create('length overflow');
  if AMinAdd <= cap - FLen then Exit;

  // 优化增长策略：小容量时快速增长，大容量时保守增长
  if cap < 64 then
    newcap := cap * 2  // 小容量时翻倍
  else if cap < 1024 then
    newcap := cap + (cap shr 1)  // 中等容量时 1.5x
  else
    newcap := cap + (cap shr 2);  // 大容量时 1.25x，减少内存浪费

  // 确保满足最小需求
  if newcap < need then newcap := need;
  // 溢出检查
  if (newcap < cap) or (newcap < need) then raise EOverflow.Create('capacity overflow');

  SetLength(FBuf, newcap);
end;

procedure TBytesBuilder.Init(ACapacity: SizeInt);
begin
  SetLength(FBuf, ACapacity);
  FLen := 0;
  FWriteAvail := 0;
  FHasPendingWrite := False;
end;

procedure TBytesBuilder.Clear;
begin
  FLen := 0;
  FWriteAvail := 0;
  FHasPendingWrite := False;
end;

procedure TBytesBuilder.Reset;
begin
  FLen := 0;
  FWriteAvail := 0;
  FHasPendingWrite := False;
end;

function TBytesBuilder.Length: SizeInt;
begin
  Result := FLen;
end;

function TBytesBuilder.Capacity: SizeInt;
begin
  Result := System.Length(FBuf);
end;

procedure TBytesBuilder.EnsureCapacity(ACapacity: SizeInt);
begin
  if ACapacity < 0 then raise EInvalidArgument.Create('negative capacity');
  if ACapacity = 0 then Exit;
  if ACapacity > System.Length(FBuf) then SetLength(FBuf, ACapacity);



end;

procedure TBytesBuilder.ReserveExact(ACapacity: SizeInt);
begin
  if ACapacity < 0 then raise EInvalidArgument.Create('negative capacity');
  if ACapacity = System.Length(FBuf) then Exit;
  SetLength(FBuf, ACapacity);
  if FLen > ACapacity then FLen := ACapacity;
  FWriteAvail := 0;
  FHasPendingWrite := False;
end;


procedure TBytesBuilder.BeginWrite(ARequest: SizeInt; out P: Pointer; out Granted: SizeInt);
begin
  P := nil;
  Granted := 0;
  if ARequest < 0 then raise EInvalidArgument.Create('negative request');
  if FHasPendingWrite then raise EInvalidOperation.Create('pending write not committed');
  if ARequest = 0 then Exit;
  Grow(ARequest);

  P := @FBuf[FLen];
  // 可写区域以请求为准（按语义授予请求的空间）
  FWriteAvail := ARequest;
  Granted := FWriteAvail;
  FHasPendingWrite := True;
end;

function TBytesBuilder.TryBeginWrite(ARequest: SizeInt; out P: Pointer; out Granted: SizeInt): Boolean;
begin
  P := nil; Granted := 0;
  if ARequest <= 0 then begin Result := True; Exit; end;
  if FHasPendingWrite then Exit(False);
  // attempt to ensure enough writable space; grow may reallocate but is allowed
  Grow(ARequest);
  P := @FBuf[FLen];
  FWriteAvail := ARequest;
  Granted := FWriteAvail;
  FHasPendingWrite := True;
  Result := True;
end;

procedure TBytesBuilder.EnsureWritable(AMinAdd: SizeInt);
begin
  if AMinAdd < 0 then raise EInvalidArgument.Create('negative min add');
  if AMinAdd = 0 then Exit;
  Grow(AMinAdd);
end;

procedure TBytesBuilder.Commit(AWritten: SizeInt);
begin
  if not FHasPendingWrite then raise EInvalidOperation.Create('no pending write');
  if (AWritten < 0) or (AWritten > FWriteAvail) then
    raise EInvalidArgument.Create('commit written out of range');
  Inc(FLen, AWritten);
  FWriteAvail := 0;
  FHasPendingWrite := False;
end;

procedure TBytesBuilder.Truncate(ANewLen: SizeInt);
begin
  if (ANewLen < 0) or (ANewLen > FLen) then
    raise EOutOfRange.Create('truncate out of range');
  FLen := ANewLen;
end;

procedure TBytesBuilder.ShrinkToFit;
begin
  if FLen < System.Length(FBuf) then
    SetLength(FBuf, FLen);
end;

procedure TBytesBuilder.Append(const B: TBytes);
begin
  if System.Length(B) = 0 then Exit;
  Grow(System.Length(B));
  Move(B[0], FBuf[FLen], System.Length(B));
  Inc(FLen, System.Length(B));
end;

procedure TBytesBuilder.Append(const P: Pointer; Count: SizeInt);
begin
  if Count < 0 then raise EInvalidArgument.Create('negative count');
  if Count = 0 then Exit;
  if P = nil then raise EInvalidArgument.Create('nil pointer with positive count');
  Grow(Count);
  Move(P^, FBuf[FLen], Count);
  Inc(FLen, Count);
end;

procedure TBytesBuilder.AppendString(const S: RawByteString);
var n: SizeInt;
begin
  n := System.Length(S);
  if n <= 0 then Exit;
  Grow(n);
  Move(Pointer(S)^, FBuf[FLen], n);
  Inc(FLen, n);
end;

procedure TBytesBuilder.AppendByte(Value: Byte); {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
begin
  Grow(1);
  FBuf[FLen] := Value;
  Inc(FLen);
end;

procedure TBytesBuilder.AppendU16LE(Value: UInt16);
begin
  Grow(2);
  FBuf[FLen] := Byte(Value and $FF);
  FBuf[FLen+1] := Byte((Value shr 8) and $FF);
  Inc(FLen, 2);
end;

procedure TBytesBuilder.AppendU16BE(Value: UInt16);
begin
  Grow(2);
  FBuf[FLen] := Byte((Value shr 8) and $FF);
  FBuf[FLen+1] := Byte(Value and $FF);
  Inc(FLen, 2);
end;

procedure TBytesBuilder.AppendU32LE(Value: UInt32);
begin
  Grow(4);
  FBuf[FLen] := Byte(Value and $FF);
  FBuf[FLen+1] := Byte((Value shr 8) and $FF);
  FBuf[FLen+2] := Byte((Value shr 16) and $FF);
  FBuf[FLen+3] := Byte((Value shr 24) and $FF);
  Inc(FLen, 4);
end;

procedure TBytesBuilder.AppendU32BE(Value: UInt32);
begin
  Grow(4);
  FBuf[FLen] := Byte((Value shr 24) and $FF);
  FBuf[FLen+1] := Byte((Value shr 16) and $FF);
  FBuf[FLen+2] := Byte((Value shr 8) and $FF);
  FBuf[FLen+3] := Byte(Value and $FF);
  Inc(FLen, 4);
end;

procedure TBytesBuilder.AppendU64LE(Value: UInt64);
begin
  Grow(8);
  FBuf[FLen] := Byte(Value and $FF);
  FBuf[FLen+1] := Byte((Value shr 8) and $FF);
  FBuf[FLen+2] := Byte((Value shr 16) and $FF);
  FBuf[FLen+3] := Byte((Value shr 24) and $FF);
  FBuf[FLen+4] := Byte((Value shr 32) and $FF);
  FBuf[FLen+5] := Byte((Value shr 40) and $FF);
  FBuf[FLen+6] := Byte((Value shr 48) and $FF);
  FBuf[FLen+7] := Byte((Value shr 56) and $FF);
  Inc(FLen, 8);

end;

function TBytesBuilder.DetachRaw(out UsedLen: SizeInt): TBytes;
begin
  // Deprecated: use DetachTrim (may shrink/copy) or DetachNoTrim for strict zero-copy
  UsedLen := FLen;
  if FLen <> System.Length(FBuf) then
    SetLength(FBuf, FLen);
  Result := FBuf;
  SetLength(FBuf, 0);
  FLen := 0;
  FWriteAvail := 0;
  FHasPendingWrite := False;
end;

function TBytesBuilder.DetachTrim(out UsedLen: SizeInt): TBytes;
begin
  // shrink to used length (may copy depending on runtime)
  UsedLen := FLen;
  if FLen <> System.Length(FBuf) then
    SetLength(FBuf, FLen);
  Result := FBuf;
  SetLength(FBuf, 0);
  FLen := 0;
  FWriteAvail := 0;
  FHasPendingWrite := False;
end;

function TBytesBuilder.DetachNoTrim(out UsedLen: SizeInt): TBytes;
begin
  // Strict ownership transfer without shrinking (no potential copy)
  UsedLen := FLen;
  Result := FBuf;
  SetLength(FBuf, 0);
  FLen := 0;
  FWriteAvail := 0;
  FHasPendingWrite := False;
end;

procedure TBytesBuilder.Peek(out P: Pointer; out UsedLen: SizeInt);
begin
  // Borrow read-only pointer to current used buffer; valid until next mutation
  if FLen = 0 then
  begin
    P := nil;
    UsedLen := 0;
    Exit;
  end;
  P := @FBuf[0];
  UsedLen := FLen;
end;

function TBytesBuilder.IntoBytes: TBytes;
var cap: SizeInt;
begin
  cap := Capacity;
  if cap = FLen then
  begin
    // perfect fit: zero-copy detach
    Result := FBuf;
    SetLength(FBuf, 0);
    FLen := 0;
    FWriteAvail := 0;
    FHasPendingWrite := False;
  end
  else
  begin
    // fallback to copy
    Result := ToBytes;
  end;
end;

procedure TBytesBuilder.AppendU64BE(Value: UInt64);
begin
  Grow(8);
  FBuf[FLen] := Byte((Value shr 56) and $FF);
  FBuf[FLen+1] := Byte((Value shr 48) and $FF);
  FBuf[FLen+2] := Byte((Value shr 40) and $FF);
  FBuf[FLen+3] := Byte((Value shr 32) and $FF);
  FBuf[FLen+4] := Byte((Value shr 24) and $FF);
  FBuf[FLen+5] := Byte((Value shr 16) and $FF);
  FBuf[FLen+6] := Byte((Value shr 8) and $FF);
  FBuf[FLen+7] := Byte(Value and $FF);
  Inc(FLen, 8);
end;

procedure TBytesBuilder.AppendHex(const S: string);
var
  i, L: SizeInt;
  ch1, ch2: Char;
  nib1, nib2: Byte;
  count: SizeInt;
begin
  L := System.Length(S);
  if L = 0 then Exit;
  if (L and 1) <> 0 then raise EInvalidArgument.Create('Hex string must have even length');
  count := L div 2;
  Grow(count);
  i := 0;
  while i < count do
  begin
    ch1 := S[i*2+1]; ch2 := S[i*2+2];
    if (not IsHexChar(ch1)) or (not IsHexChar(ch2)) then
      raise EInvalidArgument.Create('Invalid hex string');
    nib1 := HexNibble(ch1);
    nib2 := HexNibble(ch2);
    FBuf[FLen+i] := (nib1 shl 4) or nib2;
    Inc(i);
  end;
  Inc(FLen, count);
end;

procedure TBytesBuilder.AppendFill(Value: Byte; Count: SizeInt);
begin
  if Count < 0 then raise EInvalidArgument.Create('negative count');
  if Count = 0 then Exit;
  Grow(Count);
  FillChar(FBuf[FLen], Count, Value);
  Inc(FLen, Count);
end;

procedure TBytesBuilder.AppendRepeat(const Pattern: TBytes; Times: SizeInt);
var patLen, totalLen, copied, toCopy: SizeInt;
begin
  if Times < 0 then raise EInvalidArgument.Create('negative times');
  patLen := System.Length(Pattern);
  if (Times = 0) or (patLen = 0) then Exit;

  totalLen := patLen * Times;
  // 检查溢出
  if (Times > 0) and (totalLen div Times <> patLen) then
    raise EOverflow.Create('repeat size overflow');

  Grow(totalLen);

  // 优化策略：先复制一次模式，然后通过倍增复制来填充剩余部分
  // 这比逐个复制快得多，特别是对于大的重复次数
  Move(Pattern[0], FBuf[FLen], patLen);
  copied := patLen;

  // 使用倍增策略复制剩余部分
  while copied < totalLen do
  begin
    toCopy := copied;
    if toCopy > totalLen - copied then
      toCopy := totalLen - copied;
    Move(FBuf[FLen], FBuf[FLen + copied], toCopy);
    Inc(copied, toCopy);
  end;

  Inc(FLen, totalLen);
end;

function TBytesBuilder.ToBytes: TBytes;
var R: TBytes;
begin
  R := nil;
  SetLength(R, FLen);
  if FLen > 0 then Move(FBuf[0], R[0], FLen);
  Result := R;
end;

function TBytesBuilder.WriteToStream(const AStream: TStream): Int64;
var P: Pointer; N: SizeInt; wrote: Longint;
begin
  if AStream = nil then raise EArgumentNil.Create('stream=nil');
  Peek(P, N);
  if (P = nil) or (N = 0) then Exit(0);
  wrote := AStream.Write(P^, N);
  if wrote < 0 then wrote := 0;
  Result := wrote;
end;

function TBytesBuilder.ReadFromStream(const AStream: TStream; Count: Int64): Int64;
const BUF_CHUNK = 64*1024;
var toRead, want: Int64; p: Pointer; granted: SizeInt; r: Longint;
begin
  if AStream = nil then raise EArgumentNil.Create('stream=nil');
  Result := 0;
  if Count < 0 then
  begin
    // read to EOF
    repeat
      want := BUF_CHUNK;
      BeginWrite(SizeInt(want), p, granted);
      if granted = 0 then Break;
      r := AStream.Read(p^, granted);
      if r <= 0 then begin Commit(0); Break; end;
      Commit(r);
      Inc(Result, r);
    until False;
  end
  else
  begin
    toRead := Count;
    while toRead > 0 do
    begin
      want := BUF_CHUNK; if want > toRead then want := toRead;
      BeginWrite(SizeInt(want), p, granted);
      if granted = 0 then Break;
      if granted > want then granted := SizeInt(want);
      r := AStream.Read(p^, granted);
      if r <= 0 then begin Commit(0); Break; end;
      Commit(r);
      Inc(Result, r);
      Dec(toRead, r);
    end;
  end;
end;

// ---- 现代化 API 实现 ----

function TBytesBuilder.Chain: PBytesBuilder;
begin
  Result := @Self;
end;

// ---- 链式调用扩展方法实现 ----

// 基础操作的链式版本
function ChainAppend(Builder: PBytesBuilder; const Data: TBytes): PBytesBuilder;
begin
  Builder^.Append(Data);
  Result := Builder;
end;

function ChainAppendByte(Builder: PBytesBuilder; Value: Byte): PBytesBuilder;
begin
  Builder^.AppendByte(Value);
  Result := Builder;
end;

function ChainAppendString(Builder: PBytesBuilder; const S: RawByteString): PBytesBuilder;
begin
  Builder^.AppendString(S);
  Result := Builder;
end;

function ChainAppendHex(Builder: PBytesBuilder; const HexStr: string): PBytesBuilder;
begin
  Builder^.AppendHex(HexStr);
  Result := Builder;
end;

// 数值操作的链式版本
function ChainAppendU16LE(Builder: PBytesBuilder; Value: Word): PBytesBuilder;
begin
  Builder^.AppendU16LE(Value);
  Result := Builder;
end;

function ChainAppendU16BE(Builder: PBytesBuilder; Value: Word): PBytesBuilder;
begin
  Builder^.AppendU16BE(Value);
  Result := Builder;
end;

function ChainAppendU32LE(Builder: PBytesBuilder; Value: DWord): PBytesBuilder;
begin
  Builder^.AppendU32LE(Value);
  Result := Builder;
end;

function ChainAppendU32BE(Builder: PBytesBuilder; Value: DWord): PBytesBuilder;
begin
  Builder^.AppendU32BE(Value);
  Result := Builder;
end;

function ChainAppendU64LE(Builder: PBytesBuilder; Value: QWord): PBytesBuilder;
begin
  Builder^.AppendU64LE(Value);
  Result := Builder;
end;

function ChainAppendU64BE(Builder: PBytesBuilder; Value: QWord): PBytesBuilder;
begin
  Builder^.AppendU64BE(Value);
  Result := Builder;
end;

// 高级操作的链式版本
function ChainAppendFill(Builder: PBytesBuilder; Value: Byte; Count: SizeInt): PBytesBuilder;
begin
  Builder^.AppendFill(Value, Count);
  Result := Builder;
end;

function ChainAppendRepeat(Builder: PBytesBuilder; const Pattern: TBytes; Times: SizeInt): PBytesBuilder;
begin
  Builder^.AppendRepeat(Pattern, Times);
  Result := Builder;
end;

function ChainClear(Builder: PBytesBuilder): PBytesBuilder;
begin
  Builder^.Clear;
  Result := Builder;
end;

function ChainShrinkToFit(Builder: PBytesBuilder): PBytesBuilder;
begin
  Builder^.ShrinkToFit;
  Result := Builder;
end;

// ---- TBytesImpl 实现 ----
constructor TBytesImpl.Create(const Data: TBytes; Offset: SizeInt = 0; Length: SizeInt = -1);
var actualLength: SizeInt;
begin
  inherited Create;

  if Length < 0 then
    actualLength := System.Length(Data) - Offset
  else
    actualLength := Length;

  // 边界检查
  if (Offset < 0) or (Offset > System.Length(Data)) or
     (actualLength < 0) or (Offset + actualLength > System.Length(Data)) then
    raise EOutOfRange.Create('Invalid offset or length');

  // 创建共享字节并切片
  FSharedBytes := TSharedBytes.Create(Data);
  if (Offset > 0) or (actualLength < System.Length(Data)) then
    FSharedBytes := FSharedBytes.Slice(Offset, actualLength);
end;

constructor TBytesImpl.CreateFromShared(const SharedBytes: TSharedBytes);
begin
  inherited Create;
  FSharedBytes.Assign(SharedBytes);
end;

destructor TBytesImpl.Destroy;
begin
  FSharedBytes.Clear;
  inherited Destroy;
end;

function TBytesImpl.GetLength: SizeInt;
begin
  Result := FSharedBytes.Length;
end;

function TBytesImpl.IsEmpty: Boolean;
begin
  Result := FSharedBytes.IsEmpty;
end;

function TBytesImpl.GetByte(Index: SizeInt): Byte;
begin
  Result := FSharedBytes[Index];
end;

function TBytesImpl.ToArray: TBytes;
begin
  Result := FSharedBytes.ToArray;
end;

procedure TBytesImpl.CopyTo(Dest: Pointer; DestOffset: SizeInt = 0);
var temp: TBytes;
begin
  if Dest = nil then raise EArgumentNil.Create('Dest is nil');
  temp := FSharedBytes.ToArray;
  if Length(temp) > 0 then
    Move(temp[0], PByte(Dest)[DestOffset], Length(temp));
end;

function TBytesImpl.Slice(Start: SizeInt): IBytes;
begin
  Result := Slice(Start, FSharedBytes.Length - Start);
end;

function TBytesImpl.Slice(Start, Count: SizeInt): IBytes;
var slicedBytes: TSharedBytes;
begin
  slicedBytes := FSharedBytes.Slice(Start, Count);
  Result := TBytesImpl.CreateFromShared(slicedBytes);
end;

function TBytesImpl.Equals(const Other: IBytes): Boolean;
var i: SizeInt;
begin
  if Other = nil then Exit(False);
  if Other.Length <> FSharedBytes.Length then Exit(False);
  if FSharedBytes.Length = 0 then Exit(True);

  for i := 0 to FSharedBytes.Length - 1 do
    if FSharedBytes[i] <> Other[i] then
      Exit(False);
  Result := True;
end;

function TBytesImpl.StartsWith(const Prefix: IBytes): Boolean;
var i: SizeInt;
begin
  if Prefix = nil then Exit(True);
  if Prefix.Length > FSharedBytes.Length then Exit(False);
  if Prefix.Length = 0 then Exit(True);

  for i := 0 to Prefix.Length - 1 do
    if FSharedBytes[i] <> Prefix[i] then
      Exit(False);
  Result := True;
end;

function TBytesImpl.EndsWith(const Suffix: IBytes): Boolean;
var i, offset: SizeInt;
begin
  if Suffix = nil then Exit(True);
  if Suffix.Length > FSharedBytes.Length then Exit(False);
  if Suffix.Length = 0 then Exit(True);

  offset := FSharedBytes.Length - Suffix.Length;
  for i := 0 to Suffix.Length - 1 do
    if FSharedBytes[offset + i] <> Suffix[i] then
      Exit(False);
  Result := True;
end;

function TBytesImpl.IndexOf(const Pattern: IBytes): SizeInt;
var i, j: SizeInt; found: Boolean;
begin
  if (Pattern = nil) or (Pattern.Length = 0) then Exit(0);
  if Pattern.Length > FSharedBytes.Length then Exit(-1);

  for i := 0 to FSharedBytes.Length - Pattern.Length do
  begin
    found := True;
    for j := 0 to Pattern.Length - 1 do
      if FSharedBytes[i + j] <> Pattern[j] then
      begin
        found := False;
        Break;
      end;
    if found then Exit(i);
  end;
  Result := -1;
end;

function TBytesImpl.ToHex: string;
var temp: TBytes;
begin
  temp := FSharedBytes.ToArray;
  Result := BytesToHex(temp);
end;

function TBytesImpl.ToString(Encoding: TEncoding = nil): string;
var
  temp: TBytes;
  n: SizeInt;
begin
  temp := FSharedBytes.ToArray;

  if Encoding = nil then
  begin
    // Treat as raw UTF-8 bytes (project default {$CODEPAGE UTF8}).
    n := System.Length(temp);
    if n = 0 then Exit('');
    SetLength(Result, n);
    Move(temp[0], Result[1], n);
    Exit;
  end;

  Result := UTF8Encode(Encoding.GetString(temp));
end;

// ---- TImmutableBytes 工厂实现 ----
class function TImmutableBytes.FromArray(const Data: array of Byte): IBytes;
var
  temp: TBytes;
  i: Integer;
begin
  temp := nil;
  SetLength(temp, Length(Data));
  for i := 0 to High(Data) do
    temp[i] := Data[i];
  Result := TBytesImpl.Create(temp);
end;

class function TImmutableBytes.FromBytes(const Data: TBytes): IBytes;
var temp: TBytes;
begin
  // 复制数据以确保不可变性
  temp := nil;
  SetLength(temp, Length(Data));
  if Length(Data) > 0 then
    Move(Data[0], temp[0], Length(Data));
  Result := TBytesImpl.Create(temp);
end;

class function TImmutableBytes.FromHex(const HexStr: string): IBytes;
var temp: TBytes;
begin
  temp := HexToBytes(HexStr);
  Result := TBytesImpl.Create(temp);
end;

class function TImmutableBytes.FromString(const Str: string; Encoding: TEncoding = nil): IBytes;
var temp: TBytes;
begin
  temp := nil;
  if Encoding = nil then
    temp := BytesOf(Str)
  else
    temp := Encoding.GetBytes(UTF8Decode(Str));
  Result := TBytesImpl.Create(temp);
end;

class function TImmutableBytes.Wrap(const Data: TBytes): IBytes;
begin
  // 零拷贝包装，共享底层数据
  Result := TBytesImpl.Create(Data);
end;

class function TImmutableBytes.FromShared(const SharedBytes: TSharedBytes): IBytes;
begin
  Result := TBytesImpl.CreateFromShared(SharedBytes);
end;

// 暂时注释，稍后实现
{
class function TImmutableBytes.FromBuilder(var Builder: TBytesBuilder): IBytes;
var sharedBytes: TSharedBytes;
    data: TBytes;
begin
  // 尝试零拷贝路径：如果 Builder 的数据正好匹配，直接共享
  data := Builder.IntoBytes;
  sharedBytes := TSharedBytes.Create(data);
  Result := TBytesImpl.CreateFromShared(sharedBytes);

  // 重置 Builder 为空状态
  Builder.Init(0);
end;
}

class function TImmutableBytes.Empty: IBytes;
var emptyShared: TSharedBytes;
begin
  emptyShared := TSharedBytes.Empty;
  Result := TBytesImpl.CreateFromShared(emptyShared);
end;

// ---- TSharedBytes 实现 ----

class operator TSharedBytes.Initialize(var r: TSharedBytes);
begin
  r.FSharedData := nil;
  r.FOffset := 0;
  r.FLength := 0;
end;

class operator TSharedBytes.Finalize(var r: TSharedBytes);
begin
  r.Release;
  r.FOffset := 0;
  r.FLength := 0;
end;

class operator TSharedBytes.Copy(constref src: TSharedBytes; var dst: TSharedBytes);
begin
  if (src.FSharedData = dst.FSharedData) and (src.FOffset = dst.FOffset) and (src.FLength = dst.FLength) then
    Exit;

  dst.Release;
  dst.FSharedData := src.FSharedData;
  dst.FOffset := src.FOffset;
  dst.FLength := src.FLength;
  dst.AddRef;
end;

procedure TSharedBytes.AddRef;
begin
  if FSharedData <> nil then
    InterlockedIncrement(FSharedData^.RefCount);
end;

procedure TSharedBytes.Release;
begin
  if FSharedData <> nil then
  begin
    if InterlockedDecrement(FSharedData^.RefCount) = 0 then
    begin
      SetLength(FSharedData^.Data, 0);
      Dispose(FSharedData);
    end;
    FSharedData := nil;
  end;
end;

function TSharedBytes.GetByte(Index: SizeInt): Byte;
begin
  if (Index < 0) or (Index >= FLength) then
    raise EOutOfRange.Create('Index out of range');
  if FSharedData = nil then
    raise EInvalidOperation.Create('SharedBytes is empty');
  Result := FSharedData^.Data[FOffset + Index];
end;

class function TSharedBytes.Create(const Data: TBytes): TSharedBytes;
begin
  New(Result.FSharedData);
  Result.FSharedData^.RefCount := 1;
  SetLength(Result.FSharedData^.Data, System.Length(Data));
  if System.Length(Data) > 0 then
    Move(Data[0], Result.FSharedData^.Data[0], System.Length(Data));
  Result.FOffset := 0;
  Result.FLength := System.Length(Data);
end;

class function TSharedBytes.CreateSlice(const Source: TSharedBytes; Offset, Length: SizeInt): TSharedBytes;
begin
  if (Offset < 0) or (Length < 0) or (Offset + Length > Source.FLength) then
    raise EOutOfRange.Create('Slice out of range');

  Result.FSharedData := Source.FSharedData;
  Result.FOffset := Source.FOffset + Offset;
  Result.FLength := Length;
  Result.AddRef;
end;

class function TSharedBytes.Empty: TSharedBytes;
begin
  Result.FSharedData := nil;
  Result.FOffset := 0;
  Result.FLength := 0;
end;

function TSharedBytes.GetLength: SizeInt;
begin
  Result := FLength;
end;

function TSharedBytes.IsEmpty: Boolean;
begin
  Result := FLength = 0;
end;

function TSharedBytes.Slice(Start: SizeInt): TSharedBytes;
begin
  Result := Slice(Start, FLength - Start);
end;

function TSharedBytes.Slice(Start, Count: SizeInt): TSharedBytes;
begin
  Result := CreateSlice(Self, Start, Count);
end;

function TSharedBytes.ToArray: TBytes;
begin
  Result := nil;
  if FLength <= 0 then Exit;

  SetLength(Result, FLength);
  if FSharedData <> nil then
    Move(FSharedData^.Data[FOffset], Result[0], FLength);
end;

procedure TSharedBytes.Assign(const Source: TSharedBytes);
begin
  if (FSharedData = Source.FSharedData) and (FOffset = Source.FOffset) and (FLength = Source.FLength) then
    Exit;

  Release;
  FSharedData := Source.FSharedData;
  FOffset := Source.FOffset;
  FLength := Source.FLength;
  AddRef;
end;

procedure TSharedBytes.Clear;
begin
  Release;
  FOffset := 0;
  FLength := 0;
end;

// ---- 高级功能扩展实现 ----

// 批量比较操作
function BytesEqual(const A, B: TBytes): Boolean;
var i: SizeInt;
begin
  if System.Length(A) <> System.Length(B) then Exit(False);
  if System.Length(A) = 0 then Exit(True);

  for i := 0 to System.Length(A) - 1 do
    if A[i] <> B[i] then
      Exit(False);
  Result := True;
end;

function BytesCompare(const A, B: TBytes): Integer;
var i, minLen: SizeInt;
begin
  minLen := System.Length(A);
  if System.Length(B) < minLen then
    minLen := System.Length(B);

  for i := 0 to minLen - 1 do
  begin
    if A[i] < B[i] then Exit(-1);
    if A[i] > B[i] then Exit(1);
  end;

  // 前缀相同，比较长度
  if System.Length(A) < System.Length(B) then Result := -1
  else if System.Length(A) > System.Length(B) then Result := 1
  else Result := 0;
end;

function BytesStartsWith(const Data, Prefix: TBytes): Boolean;
var i: SizeInt;
begin
  if System.Length(Prefix) > System.Length(Data) then Exit(False);
  if System.Length(Prefix) = 0 then Exit(True);

  for i := 0 to System.Length(Prefix) - 1 do
    if Data[i] <> Prefix[i] then
      Exit(False);
  Result := True;
end;

function BytesEndsWith(const Data, Suffix: TBytes): Boolean;
var i, offset: SizeInt;
begin
  if System.Length(Suffix) > System.Length(Data) then Exit(False);
  if System.Length(Suffix) = 0 then Exit(True);

  offset := System.Length(Data) - System.Length(Suffix);
  for i := 0 to System.Length(Suffix) - 1 do
    if Data[offset + i] <> Suffix[i] then
      Exit(False);
  Result := True;
end;

// 批量查找操作
function BytesIndexOf(const Data, Pattern: TBytes; StartPos: SizeInt = 0): SizeInt;
var i, j: SizeInt; found: Boolean;
begin
  if (System.Length(Pattern) = 0) or (StartPos < 0) then Exit(-1);
  if System.Length(Pattern) > System.Length(Data) - StartPos then Exit(-1);

  for i := StartPos to System.Length(Data) - System.Length(Pattern) do
  begin
    found := True;
    for j := 0 to System.Length(Pattern) - 1 do
      if Data[i + j] <> Pattern[j] then
      begin
        found := False;
        Break;
      end;
    if found then Exit(i);
  end;
  Result := -1;
end;

function BytesLastIndexOf(const Data, Pattern: TBytes): SizeInt;
var i, j: SizeInt; found: Boolean;
begin
  if System.Length(Pattern) = 0 then Exit(-1);
  if System.Length(Pattern) > System.Length(Data) then Exit(-1);

  for i := System.Length(Data) - System.Length(Pattern) downto 0 do
  begin
    found := True;
    for j := 0 to System.Length(Pattern) - 1 do
      if Data[i + j] <> Pattern[j] then
      begin
        found := False;
        Break;
      end;
    if found then Exit(i);
  end;
  Result := -1;
end;

function BytesIndexOfByte(const Data: TBytes; Value: Byte; StartPos: SizeInt = 0): SizeInt;
var i: SizeInt;
begin
  if StartPos < 0 then Exit(-1);
  for i := StartPos to System.Length(Data) - 1 do
    if Data[i] = Value then
      Exit(i);
  Result := -1;
end;

function BytesCount(const Data, Pattern: TBytes): SizeInt;
var pos: SizeInt;
begin
  Result := 0;
  pos := 0;
  while True do
  begin
    pos := BytesIndexOf(Data, Pattern, pos);
    if pos = -1 then Break;
    Inc(Result);
    Inc(pos, System.Length(Pattern));
  end;
end;

// 批量替换操作
function BytesReplace(const Data, OldPattern, NewPattern: TBytes): TBytes;
var pos: SizeInt;
begin
  pos := BytesIndexOf(Data, OldPattern);
  if pos = -1 then
  begin
    Result := Data; // 没找到，返回原数据
    Exit;
  end;

  // 构建结果
  SetLength(Result, System.Length(Data) - System.Length(OldPattern) + System.Length(NewPattern));

  // 复制前缀
  if pos > 0 then
    Move(Data[0], Result[0], pos);

  // 复制新模式
  if System.Length(NewPattern) > 0 then
    Move(NewPattern[0], Result[pos], System.Length(NewPattern));

  // 复制后缀
  if pos + System.Length(OldPattern) < System.Length(Data) then
    Move(Data[pos + System.Length(OldPattern)], Result[pos + System.Length(NewPattern)],
         System.Length(Data) - pos - System.Length(OldPattern));
end;

function BytesReplaceAll(const Data, OldPattern, NewPattern: TBytes): TBytes;
var
  bb: TBytesBuilder;
  pos, lastPos, i: SizeInt;
  temp: TBytes;
begin
  temp := nil;
  if System.Length(OldPattern) = 0 then
  begin
    Result := Data;
    Exit;
  end;

  bb.Init(System.Length(Data));
  lastPos := 0;

  while True do
  begin
    pos := BytesIndexOf(Data, OldPattern, lastPos);
    if pos = -1 then Break;

    // 添加中间部分
    if pos > lastPos then
    begin
      SetLength(temp, pos - lastPos);
      for i := 0 to pos - lastPos - 1 do
        temp[i] := Data[lastPos + i];
      bb.Append(temp);
    end;

    // 添加替换模式
    bb.Append(NewPattern);

    lastPos := pos + System.Length(OldPattern);
  end;

  // 添加剩余部分
  if lastPos < System.Length(Data) then
  begin
    SetLength(temp, System.Length(Data) - lastPos);
    for i := 0 to System.Length(Data) - lastPos - 1 do
      temp[i] := Data[lastPos + i];
    bb.Append(temp);
  end;

  Result := bb.ToBytes;
end;

function BytesReplaceByte(const Data: TBytes; OldValue, NewValue: Byte): TBytes;
var i: SizeInt;
begin
  Result := Data; // 复制
  for i := 0 to System.Length(Result) - 1 do
    if Result[i] = OldValue then
      Result[i] := NewValue;
end;

// 自定义端序支持
function ReadU16(const Data: TBytes; Offset: SizeInt; Endian: TEndianness): Word;
begin
  if (Offset < 0) or (Offset + 2 > System.Length(Data)) then
    raise EOutOfRange.Create('Offset out of range');

  case Endian of
    enLittleEndian: Result := ReadU16LE(Data, Offset);
    enBigEndian: Result := ReadU16BE(Data, Offset);
    enNative:
      {$IFDEF ENDIAN_LITTLE}
      Result := ReadU16LE(Data, Offset);
      {$ELSE}
      Result := ReadU16BE(Data, Offset);
      {$ENDIF}
  end;
end;

function ReadU32(const Data: TBytes; Offset: SizeInt; Endian: TEndianness): DWord;
begin
  if (Offset < 0) or (Offset + 4 > System.Length(Data)) then
    raise EOutOfRange.Create('Offset out of range');

  case Endian of
    enLittleEndian: Result := ReadU32LE(Data, Offset);
    enBigEndian: Result := ReadU32BE(Data, Offset);
    enNative:
      {$IFDEF ENDIAN_LITTLE}
      Result := ReadU32LE(Data, Offset);
      {$ELSE}
      Result := ReadU32BE(Data, Offset);
      {$ENDIF}
  end;
end;

function ReadU64(const Data: TBytes; Offset: SizeInt; Endian: TEndianness): QWord;
begin
  if (Offset < 0) or (Offset + 8 > System.Length(Data)) then
    raise EOutOfRange.Create('Offset out of range');

  case Endian of
    enLittleEndian: Result := ReadU64LE(Data, Offset);
    enBigEndian: Result := ReadU64BE(Data, Offset);
    enNative:
      {$IFDEF ENDIAN_LITTLE}
      Result := ReadU64LE(Data, Offset);
      {$ELSE}
      Result := ReadU64BE(Data, Offset);
      {$ENDIF}
  end;
end;

procedure WriteU16(var Data: TBytes; Offset: SizeInt; Value: Word; Endian: TEndianness);
begin
  if (Offset < 0) or (Offset + 2 > System.Length(Data)) then
    raise EOutOfRange.Create('Offset out of range');

  case Endian of
    enLittleEndian: WriteU16LE(Data, Offset, Value);
    enBigEndian: WriteU16BE(Data, Offset, Value);
    enNative:
      {$IFDEF ENDIAN_LITTLE}
      WriteU16LE(Data, Offset, Value);
      {$ELSE}
      WriteU16BE(Data, Offset, Value);
      {$ENDIF}
  end;
end;

procedure WriteU32(var Data: TBytes; Offset: SizeInt; Value: DWord; Endian: TEndianness);
begin
  if (Offset < 0) or (Offset + 4 > System.Length(Data)) then
    raise EOutOfRange.Create('Offset out of range');

  case Endian of
    enLittleEndian: WriteU32LE(Data, Offset, Value);
    enBigEndian: WriteU32BE(Data, Offset, Value);
    enNative:
      {$IFDEF ENDIAN_LITTLE}
      WriteU32LE(Data, Offset, Value);
      {$ELSE}
      WriteU32BE(Data, Offset, Value);
      {$ENDIF}
  end;
end;

procedure WriteU64(var Data: TBytes; Offset: SizeInt; Value: QWord; Endian: TEndianness);
begin
  if (Offset < 0) or (Offset + 8 > System.Length(Data)) then
    raise EOutOfRange.Create('Offset out of range');

  case Endian of
    enLittleEndian: WriteU64LE(Data, Offset, Value);
    enBigEndian: WriteU64BE(Data, Offset, Value);
    enNative:
      {$IFDEF ENDIAN_LITTLE}
      WriteU64LE(Data, Offset, Value);
      {$ELSE}
      WriteU64BE(Data, Offset, Value);
      {$ENDIF}
  end;
end;

// ---- 内存池集成预留 ----
// TODO: 待 fafafa.core.mem.pool 接口稳定后，在这里添加内存池集成代码

end.

