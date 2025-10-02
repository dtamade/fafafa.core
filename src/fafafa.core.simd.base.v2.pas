unit fafafa.core.simd.base.v2;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils;

// =============================================================
// 说明
// - 本单元为重新设计后的 SIMD 基础单元（候选：替代�?simd.types�?
// - 统一承载：向量类型、掩码、元素类型、后端、能力集合、工厂接�?
// - 不直接耦合 CPUInfo；如需 CPUInfo，请在上层使�?fafafa.core.simd.cpuinfo.*
// - 便于后续 runtime dispatch 与后端扩�?
// =============================================================

// === 向量数据类型（record + variant 部分�?===
type
  // 128-bit
  TVecF32x4 = record
    case Integer of
      0: (f: array[0..3] of Single);
      1: (raw: array[0..15] of Byte);
  end;

  TVecF64x2 = record
    case Integer of
      0: (d: array[0..1] of Double);
      1: (raw: array[0..15] of Byte);
  end;

  TVecI32x4 = record
    case Integer of
      0: (i: array[0..3] of Int32);
      1: (raw: array[0..15] of Byte);
  end;

  TVecI64x2 = record
    case Integer of
      0: (i: array[0..1] of Int64);
      1: (raw: array[0..15] of Byte);
  end;

  TVecI16x8 = record
    case Integer of
      0: (i: array[0..7] of Int16);
      1: (raw: array[0..15] of Byte);
  end;

  TVecI8x16 = record
    case Integer of
      0: (i: array[0..15] of Int8);
      1: (raw: array[0..15] of Byte);
  end;

  // 256-bit
  TVecF32x8 = record
    case Integer of
      0: (f: array[0..7] of Single);
      1: (lo, hi: TVecF32x4);
      2: (raw: array[0..31] of Byte);
  end;

  TVecF64x4 = record
    case Integer of
      0: (d: array[0..3] of Double);
      1: (lo, hi: TVecF64x2);
      2: (raw: array[0..31] of Byte);
  end;

  TVecI32x8 = record
    case Integer of
      0: (i: array[0..7] of Int32);
      1: (lo, hi: TVecI32x4);
      2: (raw: array[0..31] of Byte);
  end;

  TVecI16x16 = record
    case Integer of
      0: (i: array[0..15] of Int16);
      1: (lo, hi: TVecI16x8);
      2: (raw: array[0..31] of Byte);
  end;

  TVecI8x32 = record
    case Integer of
      0: (i: array[0..31] of Int8);
      1: (lo, hi: TVecI8x16);
      2: (raw: array[0..31] of Byte);
  end;

// === 掩码类型（位掩码�?===
type
  TMask2  = type Byte;   // �?2 位有�?
  TMask4  = type Byte;   // �?4 位有�?
  TMask8  = type Byte;   // �?8 位有�?
  TMask16 = type Word;   // �?16 位有�?
  TMask32 = type DWord;  // �?32 位有�?

// === 元素类型枚举 ===
type
  TSimdElementType = (
    setFloat32,
    setFloat64,
    setInt8,
    setInt16,
    setInt32,
    setInt64,
    setUInt8,
    setUInt16,
    setUInt32,
    setUInt64
  );

// === 后端与能�?===
type
  TSimdBackend = (
    sbScalar,
    sbSSE2,
    sbAVX2,
    sbAVX512,
    sbNEON,
    sbRISCVV
  );

  TSimdCapability = (
    scBasicArithmetic,
    scComparison,
    scMathFunctions,
    scReduction,
    scShuffle,
    scFMA,
    scFastMath,
    scIntegerOps,
    scLoadStore,
    scGather,
    scMaskedOps
  );
  TSimdCapabilities  = set of TSimdCapability;
  TSimdCapabilitySet = TSimdCapabilities; // 别名

  TSimdBackendInfo = record
    Backend: TSimdBackend;
    Name: string;
    Description: string;
    Capabilities: TSimdCapabilities;
    Available: Boolean;
    Priority: Integer; // 越大优先级越�?
  end;

// === 常量：便捷掩�?===
const
  MASK2_ALL_SET  : TMask2  = $03;
  MASK4_ALL_SET  : TMask4  = $0F;
  MASK8_ALL_SET  : TMask8  = $FF;
  MASK16_ALL_SET : TMask16 = $FFFF;
  MASK32_ALL_SET : TMask32 = $FFFFFFFF;

  MASK2_NONE_SET  : TMask2  = $00;
  MASK4_NONE_SET  : TMask4  = $00;
  MASK8_NONE_SET  : TMask8  = $00;
  MASK16_NONE_SET : TMask16 = $0000;
  MASK32_NONE_SET : TMask32 = $00000000;

// === 基础接口 ===
type
  ISimdVector = interface
    ['{B8F5E2A1-4C3D-4E5F-9A8B-1C2D3E4F5A6B}']
    function GetSize: Integer;
    function GetElementCount: Integer;
    function GetElementType: TSimdElementType;
    function GetBackend: TSimdBackend;
    property Size: Integer read GetSize;
    property ElementCount: Integer read GetElementCount;
    property ElementType: TSimdElementType read GetElementType;
    property Backend: TSimdBackend read GetBackend;
  end;

  ISimdMath = interface
    ['{C9A6F3B2-5D4E-4F6A-8B9C-2D3E4F5A6B7C}']
    function Add(const A, B: ISimdVector): ISimdVector;
    function Sub(const A, B: ISimdVector): ISimdVector;
    function Mul(const A, B: ISimdVector): ISimdVector;
    function Divide(const A, B: ISimdVector): ISimdVector;
    function Sqrt(const A: ISimdVector): ISimdVector;
    function Abs(const A: ISimdVector): ISimdVector;
    function Min(const A, B: ISimdVector): ISimdVector;
    function Max(const A, B: ISimdVector): ISimdVector;
  end;

  ISimdMemory = interface
    ['{D0B7A4C3-6E5F-5A7B-9C0D-3E4F5A6B7C8D}']
    function Load(const Data: Pointer; Count: Integer): ISimdVector;
    function LoadAligned(const Data: Pointer; Count: Integer): ISimdVector;
    procedure Store(const Vector: ISimdVector; Data: Pointer);
    procedure StoreAligned(const Vector: ISimdVector; Data: Pointer);
    function Gather(const BaseAddr: Pointer; const Indices: array of Integer): ISimdVector;
    procedure Scatter(const Vector: ISimdVector; BaseAddr: Pointer; const Indices: array of Integer);
  end;

  ISimdConversion = interface
    ['{E1C8B5D4-7F6A-6B8C-0D1E-4F5A6B7C8D9E}']
    function ConvertToFloat(const A: ISimdVector): ISimdVector;
    function ConvertToInt(const A: ISimdVector): ISimdVector;
    function ConvertToDouble(const A: ISimdVector): ISimdVector;
    function Pack(const A, B: ISimdVector): ISimdVector;
    function Unpack(const A: ISimdVector): ISimdVector;
    function Shuffle(const A: ISimdVector; const Mask: array of Integer): ISimdVector;
  end;

  ISimdBackendFactory = interface
    ['{F2D9C6E5-8A7B-7C9D-1E2F-5A6B7C8D9E0F}']
    function GetBackend: TSimdBackend;
    function IsAvailable: Boolean;
    function CreateMath: ISimdMath;
    function CreateMemory: ISimdMemory;
    function CreateConversion: ISimdConversion;
    function GetCapabilities: TSimdCapabilitySet;
  end;

// === 后端工厂注册与选择 ===
procedure RegisterBackendFactory(Backend: TSimdBackend; Factory: ISimdBackendFactory);
function GetBackendFactory(Backend: TSimdBackend): ISimdBackendFactory;
function GetBestBackendFactory: ISimdBackendFactory;

type
  TSimdBackendFactoryArray = array of ISimdBackendFactory;
function GetAvailableBackendFactories: TSimdBackendFactoryArray;

implementation

var
  g_BackendFactories: array[TSimdBackend] of ISimdBackendFactory;

procedure RegisterBackendFactory(Backend: TSimdBackend; Factory: ISimdBackendFactory);
begin
  if Factory = nil then
    raise EArgumentNilException.Create('Factory cannot be nil');
  g_BackendFactories[Backend] := Factory;
end;

function GetBackendFactory(Backend: TSimdBackend): ISimdBackendFactory;
begin
  Result := g_BackendFactories[Backend];
  if (Result = nil) or (not Result.IsAvailable) then
    Result := nil;
end;

function GetBestBackendFactory: ISimdBackendFactory;
var
  backend: TSimdBackend;
  factory: ISimdBackendFactory;
begin
  Result := nil;
  // 简单策略：按枚举从高到低（可在生产实现中替换为更细化的优先�?评分�?
  for backend := High(TSimdBackend) downto Low(TSimdBackend) do
  begin
    factory := GetBackendFactory(backend);
    if factory <> nil then
    begin
      Result := factory;
      Exit;
    end;
  end;
end;

function GetAvailableBackendFactories: TSimdBackendFactoryArray;
var
  backend: TSimdBackend;
  factory: ISimdBackendFactory;
  count: Integer;
begin
  SetLength(Result, Ord(High(TSimdBackend)) - Ord(Low(TSimdBackend)) + 1);
  count := 0;
  for backend := High(TSimdBackend) downto Low(TSimdBackend) do
  begin
    factory := GetBackendFactory(backend);
    if factory <> nil then
    begin
      Result[count] := factory;
      Inc(count);
    end;
  end;
  SetLength(Result, count);
end;

finalization
  FillChar(g_BackendFactories, SizeOf(g_BackendFactories), 0);

end.
