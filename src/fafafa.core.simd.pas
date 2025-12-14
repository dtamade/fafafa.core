unit fafafa.core.simd;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.types,
  fafafa.core.simd.dispatch,
  fafafa.core.simd.cpuinfo,
  fafafa.core.simd.memutils,
  fafafa.core.simd.scalar
  {$IFDEF SIMD_X86_AVAILABLE}
  , fafafa.core.simd.sse2
  {$ENDIF}
  ;

// === Modern SIMD Framework for FreePascal ===
// This is the main user interface for the SIMD framework.
// It provides:
// 1. High-level vector types with operator overloading
// 2. Automatic backend selection and dispatch
// 3. Type-safe SIMD operations
// 4. Memory management utilities

// === Re-export Core Types ===
type
  // Vector types (re-exported from types unit)
  TVecF32x4 = fafafa.core.simd.types.TVecF32x4;
  TVecF32x8 = fafafa.core.simd.types.TVecF32x8;
  TVecF64x2 = fafafa.core.simd.types.TVecF64x2;
  TVecF64x4 = fafafa.core.simd.types.TVecF64x4;
  TVecI32x4 = fafafa.core.simd.types.TVecI32x4;
  TVecI32x8 = fafafa.core.simd.types.TVecI32x8;
  TVecI64x2 = fafafa.core.simd.types.TVecI64x2;
  TVecI16x8 = fafafa.core.simd.types.TVecI16x8;
  TVecI8x16 = fafafa.core.simd.types.TVecI8x16;
  TVecU32x4 = fafafa.core.simd.types.TVecU32x4;
  TVecU64x2 = fafafa.core.simd.types.TVecU64x2;
  TVecU16x8 = fafafa.core.simd.types.TVecU16x8;
  TVecU8x16 = fafafa.core.simd.types.TVecU8x16;
  TVecU32x8 = fafafa.core.simd.types.TVecU32x8;
  TVecF32x16 = fafafa.core.simd.types.TVecF32x16;
  TVecF64x8 = fafafa.core.simd.types.TVecF64x8;
  TVecI32x16 = fafafa.core.simd.types.TVecI32x16;
  
  // Mask types
  TMask2 = fafafa.core.simd.types.TMask2;
  TMask4 = fafafa.core.simd.types.TMask4;
  TMask8 = fafafa.core.simd.types.TMask8;
  TMask16 = fafafa.core.simd.types.TMask16;
  TMask32 = fafafa.core.simd.types.TMask32;
  
  // Backend types
  TSimdBackend = fafafa.core.simd.types.TSimdBackend;
  TSimdBackendInfo = fafafa.core.simd.types.TSimdBackendInfo;
  TCPUInfo = fafafa.core.simd.types.TCPUInfo;
  TSimdBackendArray = fafafa.core.simd.cpuinfo.TSimdBackendArray;

  // === Rust-Style Short Aliases (portable-simd compatible naming) ===
  // 128-bit float vectors
  f32x4 = TVecF32x4;   // Rust: Simd<f32, 4>
  f64x2 = TVecF64x2;   // Rust: Simd<f64, 2>
  
  // 128-bit signed integer vectors
  i8x16  = TVecI8x16;   // Rust: Simd<i8, 16>
  i16x8  = TVecI16x8;   // Rust: Simd<i16, 8>
  i32x4  = TVecI32x4;   // Rust: Simd<i32, 4>
  i64x2  = TVecI64x2;   // Rust: Simd<i64, 2>
  
  // 128-bit unsigned integer vectors
  u8x16  = TVecU8x16;   // Rust: Simd<u8, 16>
  u16x8  = TVecU16x8;   // Rust: Simd<u16, 8>
  u32x4  = TVecU32x4;   // Rust: Simd<u32, 4>
  u64x2  = TVecU64x2;   // Rust: Simd<u64, 2>
  
  // 256-bit vectors (AVX)
  f32x8  = TVecF32x8;   // Rust: Simd<f32, 8>
  f64x4  = TVecF64x4;   // Rust: Simd<f64, 4>
  i32x8  = TVecI32x8;   // Rust: Simd<i32, 8>
  u32x8  = TVecU32x8;   // Rust: Simd<u32, 8>
  
  // 512-bit vectors (AVX-512)
  f32x16 = TVecF32x16;  // Rust: Simd<f32, 16>
  f64x8  = TVecF64x8;   // Rust: Simd<f64, 8>
  i32x16 = TVecI32x16;  // Rust: Simd<i32, 16>

// === High-Level Vector Operations ===

// F32x4 operations
function VecF32x4Add(const a, b: TVecF32x4): TVecF32x4; inline;
function VecF32x4Sub(const a, b: TVecF32x4): TVecF32x4; inline;
function VecF32x4Mul(const a, b: TVecF32x4): TVecF32x4; inline;
function VecF32x4Div(const a, b: TVecF32x4): TVecF32x4; inline;

// F32x4 comparison
function VecF32x4CmpEq(const a, b: TVecF32x4): TMask4; inline;
function VecF32x4CmpLt(const a, b: TVecF32x4): TMask4; inline;
function VecF32x4CmpLe(const a, b: TVecF32x4): TMask4; inline;
function VecF32x4CmpGt(const a, b: TVecF32x4): TMask4; inline;
function VecF32x4CmpGe(const a, b: TVecF32x4): TMask4; inline;
function VecF32x4CmpNe(const a, b: TVecF32x4): TMask4; inline;

// F32x4 math functions
function VecF32x4Abs(const a: TVecF32x4): TVecF32x4; inline;
function VecF32x4Sqrt(const a: TVecF32x4): TVecF32x4; inline;
function VecF32x4Min(const a, b: TVecF32x4): TVecF32x4; inline;
function VecF32x4Max(const a, b: TVecF32x4): TVecF32x4; inline;

// F32x4 extended math
function VecF32x4Fma(const a, b, c: TVecF32x4): TVecF32x4; inline;    // a*b+c
function VecF32x4Rcp(const a: TVecF32x4): TVecF32x4; inline;          // 1/x (approximate)
function VecF32x4Rsqrt(const a: TVecF32x4): TVecF32x4; inline;        // 1/sqrt(x) (approximate)
function VecF32x4Floor(const a: TVecF32x4): TVecF32x4; inline;
function VecF32x4Ceil(const a: TVecF32x4): TVecF32x4; inline;
function VecF32x4Round(const a: TVecF32x4): TVecF32x4; inline;
function VecF32x4Trunc(const a: TVecF32x4): TVecF32x4; inline;
function VecF32x4Clamp(const a, minVal, maxVal: TVecF32x4): TVecF32x4; inline;

// 3D/4D Vector math
function VecF32x4Dot(const a, b: TVecF32x4): Single; inline;          // Dot product (4 elements)
function VecF32x3Dot(const a, b: TVecF32x4): Single; inline;          // Dot product (3 elements)
function VecF32x3Cross(const a, b: TVecF32x4): TVecF32x4; inline;     // Cross product
function VecF32x4Length(const a: TVecF32x4): Single; inline;          // Length (4 elements)
function VecF32x3Length(const a: TVecF32x4): Single; inline;          // Length (3 elements)
function VecF32x4Normalize(const a: TVecF32x4): TVecF32x4; inline;    // Normalize (4 elements)
function VecF32x3Normalize(const a: TVecF32x4): TVecF32x4; inline;    // Normalize (3 elements)

// F32x4 reduction
function VecF32x4ReduceAdd(const a: TVecF32x4): Single; inline;
function VecF32x4ReduceMin(const a: TVecF32x4): Single; inline;
function VecF32x4ReduceMax(const a: TVecF32x4): Single; inline;
function VecF32x4ReduceMul(const a: TVecF32x4): Single; inline;

// F32x4 memory operations
function VecF32x4Load(p: PSingle): TVecF32x4; inline;
function VecF32x4LoadAligned(p: PSingle): TVecF32x4; inline;
procedure VecF32x4Store(p: PSingle; const a: TVecF32x4); inline;
procedure VecF32x4StoreAligned(p: PSingle; const a: TVecF32x4); inline;

// F32x4 utility operations
function VecF32x4Splat(value: Single): TVecF32x4; inline;
function VecF32x4Zero: TVecF32x4; inline;
function VecF32x4Select(const mask: TMask4; const a, b: TVecF32x4): TVecF32x4; inline;
function VecF32x4Extract(const a: TVecF32x4; index: Integer): Single; inline;
function VecF32x4Insert(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4; inline;

// === Framework Information ===

// Get current backend information
function GetCurrentBackend: TSimdBackend;
function GetCurrentBackendInfo: TSimdBackendInfo;

// Get CPU information
function GetCPUInformation: TCPUInfo;

// Get list of available backends
function GetAvailableBackendList: TSimdBackendArray;

// Force a specific backend (for testing)
procedure ForceBackend(backend: TSimdBackend);
procedure ResetBackendSelection;

// === Memory Utilities (Re-exported) ===

// Aligned memory allocation
function AllocateAligned(size: NativeUInt; alignment: NativeUInt = 32): Pointer;
procedure FreeAligned(ptr: Pointer);

// Alignment checking
function IsPointerAligned(ptr: Pointer; alignment: NativeUInt = 32): Boolean;

implementation

// === High-Level Vector Operations Implementation ===

function VecF32x4Add(const a, b: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.AddF32x4(a, b);
end;

function VecF32x4Sub(const a, b: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.SubF32x4(a, b);
end;

function VecF32x4Mul(const a, b: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.MulF32x4(a, b);
end;

function VecF32x4Div(const a, b: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.DivF32x4(a, b);
end;

function VecF32x4CmpEq(const a, b: TVecF32x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.CmpEqF32x4(a, b);
end;

function VecF32x4CmpLt(const a, b: TVecF32x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.CmpLtF32x4(a, b);
end;

function VecF32x4CmpLe(const a, b: TVecF32x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.CmpLeF32x4(a, b);
end;

function VecF32x4CmpGt(const a, b: TVecF32x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.CmpGtF32x4(a, b);
end;

function VecF32x4CmpGe(const a, b: TVecF32x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.CmpGeF32x4(a, b);
end;

function VecF32x4CmpNe(const a, b: TVecF32x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.CmpNeF32x4(a, b);
end;

function VecF32x4Abs(const a: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.AbsF32x4(a);
end;

function VecF32x4Sqrt(const a: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.SqrtF32x4(a);
end;

function VecF32x4Min(const a, b: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.MinF32x4(a, b);
end;

function VecF32x4Max(const a, b: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.MaxF32x4(a, b);
end;

// === Extended Math Functions ===

function VecF32x4Fma(const a, b, c: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.FmaF32x4(a, b, c);
end;

function VecF32x4Rcp(const a: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.RcpF32x4(a);
end;

function VecF32x4Rsqrt(const a: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.RsqrtF32x4(a);
end;

function VecF32x4Floor(const a: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.FloorF32x4(a);
end;

function VecF32x4Ceil(const a: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.CeilF32x4(a);
end;

function VecF32x4Round(const a: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.RoundF32x4(a);
end;

function VecF32x4Trunc(const a: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.TruncF32x4(a);
end;

function VecF32x4Clamp(const a, minVal, maxVal: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.ClampF32x4(a, minVal, maxVal);
end;

// === 3D/4D Vector Math ===

function VecF32x4Dot(const a, b: TVecF32x4): Single;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.DotF32x4(a, b);
end;

function VecF32x3Dot(const a, b: TVecF32x4): Single;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.DotF32x3(a, b);
end;

function VecF32x3Cross(const a, b: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.CrossF32x3(a, b);
end;

function VecF32x4Length(const a: TVecF32x4): Single;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.LengthF32x4(a);
end;

function VecF32x3Length(const a: TVecF32x4): Single;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.LengthF32x3(a);
end;

function VecF32x4Normalize(const a: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.NormalizeF32x4(a);
end;

function VecF32x3Normalize(const a: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.NormalizeF32x3(a);
end;

function VecF32x4ReduceAdd(const a: TVecF32x4): Single;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.ReduceAddF32x4(a);
end;

function VecF32x4ReduceMin(const a: TVecF32x4): Single;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.ReduceMinF32x4(a);
end;

function VecF32x4ReduceMax(const a: TVecF32x4): Single;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.ReduceMaxF32x4(a);
end;

function VecF32x4ReduceMul(const a: TVecF32x4): Single;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.ReduceMulF32x4(a);
end;

function VecF32x4Load(p: PSingle): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.LoadF32x4(p);
end;

function VecF32x4LoadAligned(p: PSingle): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.LoadF32x4Aligned(p);
end;

procedure VecF32x4Store(p: PSingle; const a: TVecF32x4);
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  dispatch^.StoreF32x4(p, a);
end;

procedure VecF32x4StoreAligned(p: PSingle; const a: TVecF32x4);
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  dispatch^.StoreF32x4Aligned(p, a);
end;

function VecF32x4Splat(value: Single): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.SplatF32x4(value);
end;

function VecF32x4Zero: TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.ZeroF32x4();
end;

function VecF32x4Select(const mask: TMask4; const a, b: TVecF32x4): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.SelectF32x4(mask, a, b);
end;

function VecF32x4Extract(const a: TVecF32x4; index: Integer): Single;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.ExtractF32x4(a, index);
end;

function VecF32x4Insert(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  Result := dispatch^.InsertF32x4(a, value, index);
end;

// === Framework Information ===

function GetCurrentBackend: TSimdBackend;
begin
  Result := GetActiveBackend;
end;

function GetCurrentBackendInfo: TSimdBackendInfo;
begin
  Result := GetBackendInfo(GetActiveBackend);
end;

function GetCPUInformation: TCPUInfo;
begin
  Result := GetCPUInfo;
end;

function GetAvailableBackendList: TSimdBackendArray;
begin
  Result := GetAvailableBackends;
end;

procedure ForceBackend(backend: TSimdBackend);
begin
  SetActiveBackend(backend);
end;

procedure ResetBackendSelection;
begin
  ResetToAutomaticBackend;
end;

// === Memory Utilities ===

function AllocateAligned(size: NativeUInt; alignment: NativeUInt): Pointer;
begin
  Result := AlignedAlloc(size, alignment);
end;

procedure FreeAligned(ptr: Pointer);
begin
  AlignedFree(ptr);
end;

function IsPointerAligned(ptr: Pointer; alignment: NativeUInt): Boolean;
begin
  Result := IsAligned(ptr, alignment);
end;

end.


