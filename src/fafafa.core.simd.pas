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
  , fafafa.core.simd.avx2
  , fafafa.core.simd.avx512
  {$ENDIF}
  {$IFDEF SIMD_ARM_AVAILABLE}
  , fafafa.core.simd.neon
  {$ENDIF}
  {$IFDEF SIMD_RISCV_AVAILABLE}
  , fafafa.core.simd.riscvv
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

// === F64x2 Operations (128-bit Double) ===
// ✅ P0.3: 添加缺失的 F64x2 高级 API

// F64x2 arithmetic
function VecF64x2Add(const a, b: TVecF64x2): TVecF64x2; inline;
function VecF64x2Sub(const a, b: TVecF64x2): TVecF64x2; inline;
function VecF64x2Mul(const a, b: TVecF64x2): TVecF64x2; inline;
function VecF64x2Div(const a, b: TVecF64x2): TVecF64x2; inline;

// === I32x4 Operations (128-bit Integer) ===
// ✅ P0.3: 添加缺失的 I32x4 高级 API

// I32x4 arithmetic
function VecI32x4Add(const a, b: TVecI32x4): TVecI32x4; inline;
function VecI32x4Sub(const a, b: TVecI32x4): TVecI32x4; inline;
function VecI32x4Mul(const a, b: TVecI32x4): TVecI32x4; inline;

// I32x4 bitwise operations
function VecI32x4And(const a, b: TVecI32x4): TVecI32x4; inline;
function VecI32x4Or(const a, b: TVecI32x4): TVecI32x4; inline;
function VecI32x4Xor(const a, b: TVecI32x4): TVecI32x4; inline;
function VecI32x4Not(const a: TVecI32x4): TVecI32x4; inline;
function VecI32x4AndNot(const a, b: TVecI32x4): TVecI32x4; inline;

// I32x4 shift operations
function VecI32x4ShiftLeft(const a: TVecI32x4; count: Integer): TVecI32x4; inline;
function VecI32x4ShiftRight(const a: TVecI32x4; count: Integer): TVecI32x4; inline;
function VecI32x4ShiftRightArith(const a: TVecI32x4; count: Integer): TVecI32x4; inline;

// I32x4 comparison
function VecI32x4CmpEq(const a, b: TVecI32x4): TMask4; inline;
function VecI32x4CmpLt(const a, b: TVecI32x4): TMask4; inline;
function VecI32x4CmpGt(const a, b: TVecI32x4): TMask4; inline;

// I32x4 min/max
function VecI32x4Min(const a, b: TVecI32x4): TVecI32x4; inline;
function VecI32x4Max(const a, b: TVecI32x4): TVecI32x4; inline;

// === I64x2 Operations (128-bit Integer, 64-bit elements) ===
// ✅ P1.3: 添加 I64x2 高级 API

// I64x2 arithmetic
function VecI64x2Add(const a, b: TVecI64x2): TVecI64x2; inline;
function VecI64x2Sub(const a, b: TVecI64x2): TVecI64x2; inline;

// I64x2 bitwise operations
function VecI64x2And(const a, b: TVecI64x2): TVecI64x2; inline;
function VecI64x2Or(const a, b: TVecI64x2): TVecI64x2; inline;
function VecI64x2Xor(const a, b: TVecI64x2): TVecI64x2; inline;
function VecI64x2Not(const a: TVecI64x2): TVecI64x2; inline;
function VecI64x2AndNot(const a, b: TVecI64x2): TVecI64x2; inline;

// === F32x8 Operations (256-bit Float, AVX) ===
// ✅ P0.3: 添加缺失的 F32x8 高级 API

// F32x8 arithmetic
function VecF32x8Add(const a, b: TVecF32x8): TVecF32x8; inline;
function VecF32x8Sub(const a, b: TVecF32x8): TVecF32x8; inline;
function VecF32x8Mul(const a, b: TVecF32x8): TVecF32x8; inline;
function VecF32x8Div(const a, b: TVecF32x8): TVecF32x8; inline;

// === I32x8 Operations (256-bit Integer, AVX2) ===
// ✅ P1.1: 添加缺失的 I32x8 高级 API

// I32x8 arithmetic
function VecI32x8Add(const a, b: TVecI32x8): TVecI32x8; inline;
function VecI32x8Sub(const a, b: TVecI32x8): TVecI32x8; inline;
function VecI32x8Mul(const a, b: TVecI32x8): TVecI32x8; inline;

// I32x8 bitwise operations
function VecI32x8And(const a, b: TVecI32x8): TVecI32x8; inline;
function VecI32x8Or(const a, b: TVecI32x8): TVecI32x8; inline;
function VecI32x8Xor(const a, b: TVecI32x8): TVecI32x8; inline;
function VecI32x8Not(const a: TVecI32x8): TVecI32x8; inline;
function VecI32x8AndNot(const a, b: TVecI32x8): TVecI32x8; inline;

// I32x8 shift operations
function VecI32x8ShiftLeft(const a: TVecI32x8; count: Integer): TVecI32x8; inline;
function VecI32x8ShiftRight(const a: TVecI32x8; count: Integer): TVecI32x8; inline;
function VecI32x8ShiftRightArith(const a: TVecI32x8; count: Integer): TVecI32x8; inline;

// I32x8 comparison
function VecI32x8CmpEq(const a, b: TVecI32x8): TMask8; inline;
function VecI32x8CmpLt(const a, b: TVecI32x8): TMask8; inline;
function VecI32x8CmpGt(const a, b: TVecI32x8): TMask8; inline;

// I32x8 min/max
function VecI32x8Min(const a, b: TVecI32x8): TVecI32x8; inline;
function VecI32x8Max(const a, b: TVecI32x8): TVecI32x8; inline;

// === I32x16 Operations (512-bit Integer, AVX-512) ===
// ✅ P1.2: 添加 I32x16 高级 API

// I32x16 arithmetic
function VecI32x16Add(const a, b: TVecI32x16): TVecI32x16; inline;
function VecI32x16Sub(const a, b: TVecI32x16): TVecI32x16; inline;
function VecI32x16Mul(const a, b: TVecI32x16): TVecI32x16; inline;

// I32x16 bitwise operations
function VecI32x16And(const a, b: TVecI32x16): TVecI32x16; inline;
function VecI32x16Or(const a, b: TVecI32x16): TVecI32x16; inline;
function VecI32x16Xor(const a, b: TVecI32x16): TVecI32x16; inline;
function VecI32x16Not(const a: TVecI32x16): TVecI32x16; inline;
function VecI32x16AndNot(const a, b: TVecI32x16): TVecI32x16; inline;

// I32x16 shift operations
function VecI32x16ShiftLeft(const a: TVecI32x16; count: Integer): TVecI32x16; inline;
function VecI32x16ShiftRight(const a: TVecI32x16; count: Integer): TVecI32x16; inline;
function VecI32x16ShiftRightArith(const a: TVecI32x16; count: Integer): TVecI32x16; inline;

// I32x16 comparison
function VecI32x16CmpEq(const a, b: TVecI32x16): TMask16; inline;
function VecI32x16CmpLt(const a, b: TVecI32x16): TMask16; inline;
function VecI32x16CmpGt(const a, b: TVecI32x16): TMask16; inline;

// I32x16 min/max
function VecI32x16Min(const a, b: TVecI32x16): TVecI32x16; inline;
function VecI32x16Max(const a, b: TVecI32x16): TVecI32x16; inline;

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

// === F64x2 Operations Implementation ===
// ✅ P0.3: F64x2 高级 API 实现

function VecF64x2Add(const a, b: TVecF64x2): TVecF64x2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AddF64x2) then
    Result := dispatch^.AddF64x2(a, b)
  else
  begin
    Result.d[0] := a.d[0] + b.d[0];
    Result.d[1] := a.d[1] + b.d[1];
  end;
end;

function VecF64x2Sub(const a, b: TVecF64x2): TVecF64x2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.SubF64x2) then
    Result := dispatch^.SubF64x2(a, b)
  else
  begin
    Result.d[0] := a.d[0] - b.d[0];
    Result.d[1] := a.d[1] - b.d[1];
  end;
end;

function VecF64x2Mul(const a, b: TVecF64x2): TVecF64x2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MulF64x2) then
    Result := dispatch^.MulF64x2(a, b)
  else
  begin
    Result.d[0] := a.d[0] * b.d[0];
    Result.d[1] := a.d[1] * b.d[1];
  end;
end;

function VecF64x2Div(const a, b: TVecF64x2): TVecF64x2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.DivF64x2) then
    Result := dispatch^.DivF64x2(a, b)
  else
  begin
    Result.d[0] := a.d[0] / b.d[0];
    Result.d[1] := a.d[1] / b.d[1];
  end;
end;

// === I32x4 Operations Implementation ===
// ✅ P0.3: I32x4 高级 API 实现

function VecI32x4Add(const a, b: TVecI32x4): TVecI32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AddI32x4) then
    Result := dispatch^.AddI32x4(a, b)
  else
  begin
    Result.i[0] := a.i[0] + b.i[0];
    Result.i[1] := a.i[1] + b.i[1];
    Result.i[2] := a.i[2] + b.i[2];
    Result.i[3] := a.i[3] + b.i[3];
  end;
end;

function VecI32x4Sub(const a, b: TVecI32x4): TVecI32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.SubI32x4) then
    Result := dispatch^.SubI32x4(a, b)
  else
  begin
    Result.i[0] := a.i[0] - b.i[0];
    Result.i[1] := a.i[1] - b.i[1];
    Result.i[2] := a.i[2] - b.i[2];
    Result.i[3] := a.i[3] - b.i[3];
  end;
end;

function VecI32x4Mul(const a, b: TVecI32x4): TVecI32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MulI32x4) then
    Result := dispatch^.MulI32x4(a, b)
  else
  begin
    Result.i[0] := a.i[0] * b.i[0];
    Result.i[1] := a.i[1] * b.i[1];
    Result.i[2] := a.i[2] * b.i[2];
    Result.i[3] := a.i[3] * b.i[3];
  end;
end;

function VecI32x4And(const a, b: TVecI32x4): TVecI32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AndI32x4) then
    Result := dispatch^.AndI32x4(a, b)
  else
  begin
    Result.i[0] := a.i[0] and b.i[0];
    Result.i[1] := a.i[1] and b.i[1];
    Result.i[2] := a.i[2] and b.i[2];
    Result.i[3] := a.i[3] and b.i[3];
  end;
end;

function VecI32x4Or(const a, b: TVecI32x4): TVecI32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.OrI32x4) then
    Result := dispatch^.OrI32x4(a, b)
  else
  begin
    Result.i[0] := a.i[0] or b.i[0];
    Result.i[1] := a.i[1] or b.i[1];
    Result.i[2] := a.i[2] or b.i[2];
    Result.i[3] := a.i[3] or b.i[3];
  end;
end;

function VecI32x4Xor(const a, b: TVecI32x4): TVecI32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.XorI32x4) then
    Result := dispatch^.XorI32x4(a, b)
  else
  begin
    Result.i[0] := a.i[0] xor b.i[0];
    Result.i[1] := a.i[1] xor b.i[1];
    Result.i[2] := a.i[2] xor b.i[2];
    Result.i[3] := a.i[3] xor b.i[3];
  end;
end;

function VecI32x4Not(const a: TVecI32x4): TVecI32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.NotI32x4) then
    Result := dispatch^.NotI32x4(a)
  else
  begin
    Result.i[0] := not a.i[0];
    Result.i[1] := not a.i[1];
    Result.i[2] := not a.i[2];
    Result.i[3] := not a.i[3];
  end;
end;

function VecI32x4AndNot(const a, b: TVecI32x4): TVecI32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AndNotI32x4) then
    Result := dispatch^.AndNotI32x4(a, b)
  else
  begin
    Result.i[0] := (not a.i[0]) and b.i[0];
    Result.i[1] := (not a.i[1]) and b.i[1];
    Result.i[2] := (not a.i[2]) and b.i[2];
    Result.i[3] := (not a.i[3]) and b.i[3];
  end;
end;

function VecI32x4ShiftLeft(const a: TVecI32x4; count: Integer): TVecI32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftLeftI32x4) then
    Result := dispatch^.ShiftLeftI32x4(a, count)
  else
  begin
    Result.i[0] := a.i[0] shl count;
    Result.i[1] := a.i[1] shl count;
    Result.i[2] := a.i[2] shl count;
    Result.i[3] := a.i[3] shl count;
  end;
end;

function VecI32x4ShiftRight(const a: TVecI32x4; count: Integer): TVecI32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftRightI32x4) then
    Result := dispatch^.ShiftRightI32x4(a, count)
  else
  begin
    // Logical shift (unsigned)
    Result.i[0] := Int32(UInt32(a.i[0]) shr count);
    Result.i[1] := Int32(UInt32(a.i[1]) shr count);
    Result.i[2] := Int32(UInt32(a.i[2]) shr count);
    Result.i[3] := Int32(UInt32(a.i[3]) shr count);
  end;
end;

function VecI32x4ShiftRightArith(const a: TVecI32x4; count: Integer): TVecI32x4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftRightArithI32x4) then
    Result := dispatch^.ShiftRightArithI32x4(a, count)
  else
  begin
    // Arithmetic shift (signed)
    Result.i[0] := SarLongint(a.i[0], count);
    Result.i[1] := SarLongint(a.i[1], count);
    Result.i[2] := SarLongint(a.i[2], count);
    Result.i[3] := SarLongint(a.i[3], count);
  end;
end;

function VecI32x4CmpEq(const a, b: TVecI32x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpEqI32x4) then
    Result := dispatch^.CmpEqI32x4(a, b)
  else
  begin
    Result := 0;
    if a.i[0] = b.i[0] then Result := Result or 1;
    if a.i[1] = b.i[1] then Result := Result or 2;
    if a.i[2] = b.i[2] then Result := Result or 4;
    if a.i[3] = b.i[3] then Result := Result or 8;
  end;
end;

function VecI32x4CmpLt(const a, b: TVecI32x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpLtI32x4) then
    Result := dispatch^.CmpLtI32x4(a, b)
  else
  begin
    Result := 0;
    if a.i[0] < b.i[0] then Result := Result or 1;
    if a.i[1] < b.i[1] then Result := Result or 2;
    if a.i[2] < b.i[2] then Result := Result or 4;
    if a.i[3] < b.i[3] then Result := Result or 8;
  end;
end;

function VecI32x4CmpGt(const a, b: TVecI32x4): TMask4;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpGtI32x4) then
    Result := dispatch^.CmpGtI32x4(a, b)
  else
  begin
    Result := 0;
    if a.i[0] > b.i[0] then Result := Result or 1;
    if a.i[1] > b.i[1] then Result := Result or 2;
    if a.i[2] > b.i[2] then Result := Result or 4;
    if a.i[3] > b.i[3] then Result := Result or 8;
  end;
end;

function VecI32x4Min(const a, b: TVecI32x4): TVecI32x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MinI32x4) then
    Result := dispatch^.MinI32x4(a, b)
  else
  begin
    for i := 0 to 3 do
      if a.i[i] < b.i[i] then
        Result.i[i] := a.i[i]
      else
        Result.i[i] := b.i[i];
  end;
end;

function VecI32x4Max(const a, b: TVecI32x4): TVecI32x4;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MaxI32x4) then
    Result := dispatch^.MaxI32x4(a, b)
  else
  begin
    for i := 0 to 3 do
      if a.i[i] > b.i[i] then
        Result.i[i] := a.i[i]
      else
        Result.i[i] := b.i[i];
  end;
end;

// === I64x2 Operations Implementation ===
// ✅ P1.3: I64x2 高级 API 实现

function VecI64x2Add(const a, b: TVecI64x2): TVecI64x2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AddI64x2) then
    Result := dispatch^.AddI64x2(a, b)
  else
  begin
    Result.i[0] := a.i[0] + b.i[0];
    Result.i[1] := a.i[1] + b.i[1];
  end;
end;

function VecI64x2Sub(const a, b: TVecI64x2): TVecI64x2;
var dispatch: PSimdDispatchTable;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.SubI64x2) then
    Result := dispatch^.SubI64x2(a, b)
  else
  begin
    Result.i[0] := a.i[0] - b.i[0];
    Result.i[1] := a.i[1] - b.i[1];
  end;
end;

function VecI64x2And(const a, b: TVecI64x2): TVecI64x2;
begin
  // Bitwise operations - scalar fallback (no dispatch entry)
  Result.i[0] := a.i[0] and b.i[0];
  Result.i[1] := a.i[1] and b.i[1];
end;

function VecI64x2Or(const a, b: TVecI64x2): TVecI64x2;
begin
  Result.i[0] := a.i[0] or b.i[0];
  Result.i[1] := a.i[1] or b.i[1];
end;

function VecI64x2Xor(const a, b: TVecI64x2): TVecI64x2;
begin
  Result.i[0] := a.i[0] xor b.i[0];
  Result.i[1] := a.i[1] xor b.i[1];
end;

function VecI64x2Not(const a: TVecI64x2): TVecI64x2;
begin
  Result.i[0] := not a.i[0];
  Result.i[1] := not a.i[1];
end;

function VecI64x2AndNot(const a, b: TVecI64x2): TVecI64x2;
begin
  // (~a) and b
  Result.i[0] := (not a.i[0]) and b.i[0];
  Result.i[1] := (not a.i[1]) and b.i[1];
end;

// === F32x8 Operations Implementation ===
// ✅ P0.3: F32x8 (256-bit) 高级 API 实现

function VecF32x8Add(const a, b: TVecF32x8): TVecF32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AddF32x8) then
    Result := dispatch^.AddF32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.f[i] := a.f[i] + b.f[i];
  end;
end;

function VecF32x8Sub(const a, b: TVecF32x8): TVecF32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.SubF32x8) then
    Result := dispatch^.SubF32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.f[i] := a.f[i] - b.f[i];
  end;
end;

function VecF32x8Mul(const a, b: TVecF32x8): TVecF32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MulF32x8) then
    Result := dispatch^.MulF32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.f[i] := a.f[i] * b.f[i];
  end;
end;

function VecF32x8Div(const a, b: TVecF32x8): TVecF32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.DivF32x8) then
    Result := dispatch^.DivF32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.f[i] := a.f[i] / b.f[i];
  end;
end;

// === I32x8 Operations Implementation ===
// ✅ P1.1: I32x8 高级 API 实现

function VecI32x8Add(const a, b: TVecI32x8): TVecI32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AddI32x8) then
    Result := dispatch^.AddI32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := a.i[i] + b.i[i];
  end;
end;

function VecI32x8Sub(const a, b: TVecI32x8): TVecI32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.SubI32x8) then
    Result := dispatch^.SubI32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := a.i[i] - b.i[i];
  end;
end;

function VecI32x8Mul(const a, b: TVecI32x8): TVecI32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MulI32x8) then
    Result := dispatch^.MulI32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := a.i[i] * b.i[i];
  end;
end;

function VecI32x8And(const a, b: TVecI32x8): TVecI32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AndI32x8) then
    Result := dispatch^.AndI32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := a.i[i] and b.i[i];
  end;
end;

function VecI32x8Or(const a, b: TVecI32x8): TVecI32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.OrI32x8) then
    Result := dispatch^.OrI32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := a.i[i] or b.i[i];
  end;
end;

function VecI32x8Xor(const a, b: TVecI32x8): TVecI32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.XorI32x8) then
    Result := dispatch^.XorI32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := a.i[i] xor b.i[i];
  end;
end;

function VecI32x8Not(const a: TVecI32x8): TVecI32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.NotI32x8) then
    Result := dispatch^.NotI32x8(a)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := not a.i[i];
  end;
end;

function VecI32x8AndNot(const a, b: TVecI32x8): TVecI32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AndNotI32x8) then
    Result := dispatch^.AndNotI32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := (not a.i[i]) and b.i[i];
  end;
end;

function VecI32x8ShiftLeft(const a: TVecI32x8; count: Integer): TVecI32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftLeftI32x8) then
    Result := dispatch^.ShiftLeftI32x8(a, count)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := a.i[i] shl count;
  end;
end;

function VecI32x8ShiftRight(const a: TVecI32x8; count: Integer): TVecI32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftRightI32x8) then
    Result := dispatch^.ShiftRightI32x8(a, count)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := Int32(UInt32(a.i[i]) shr count);
  end;
end;

function VecI32x8ShiftRightArith(const a: TVecI32x8; count: Integer): TVecI32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftRightArithI32x8) then
    Result := dispatch^.ShiftRightArithI32x8(a, count)
  else
  begin
    for i := 0 to 7 do
      Result.i[i] := SarLongint(a.i[i], count);
  end;
end;

function VecI32x8CmpEq(const a, b: TVecI32x8): TMask8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpEqI32x8) then
    Result := dispatch^.CmpEqI32x8(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 7 do
      if a.i[i] = b.i[i] then Result := Result or (1 shl i);
  end;
end;

function VecI32x8CmpLt(const a, b: TVecI32x8): TMask8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpLtI32x8) then
    Result := dispatch^.CmpLtI32x8(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 7 do
      if a.i[i] < b.i[i] then Result := Result or (1 shl i);
  end;
end;

function VecI32x8CmpGt(const a, b: TVecI32x8): TMask8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpGtI32x8) then
    Result := dispatch^.CmpGtI32x8(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 7 do
      if a.i[i] > b.i[i] then Result := Result or (1 shl i);
  end;
end;

function VecI32x8Min(const a, b: TVecI32x8): TVecI32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MinI32x8) then
    Result := dispatch^.MinI32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      if a.i[i] < b.i[i] then
        Result.i[i] := a.i[i]
      else
        Result.i[i] := b.i[i];
  end;
end;

function VecI32x8Max(const a, b: TVecI32x8): TVecI32x8;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MaxI32x8) then
    Result := dispatch^.MaxI32x8(a, b)
  else
  begin
    for i := 0 to 7 do
      if a.i[i] > b.i[i] then
        Result.i[i] := a.i[i]
      else
        Result.i[i] := b.i[i];
  end;
end;

// === I32x16 Operations Implementation ===
// ✅ P1.2: I32x16 高级 API 实现

function VecI32x16Add(const a, b: TVecI32x16): TVecI32x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AddI32x16) then
    Result := dispatch^.AddI32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := a.i[i] + b.i[i];
  end;
end;

function VecI32x16Sub(const a, b: TVecI32x16): TVecI32x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.SubI32x16) then
    Result := dispatch^.SubI32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := a.i[i] - b.i[i];
  end;
end;

function VecI32x16Mul(const a, b: TVecI32x16): TVecI32x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MulI32x16) then
    Result := dispatch^.MulI32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := a.i[i] * b.i[i];
  end;
end;

function VecI32x16And(const a, b: TVecI32x16): TVecI32x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AndI32x16) then
    Result := dispatch^.AndI32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := a.i[i] and b.i[i];
  end;
end;

function VecI32x16Or(const a, b: TVecI32x16): TVecI32x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.OrI32x16) then
    Result := dispatch^.OrI32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := a.i[i] or b.i[i];
  end;
end;

function VecI32x16Xor(const a, b: TVecI32x16): TVecI32x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.XorI32x16) then
    Result := dispatch^.XorI32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := a.i[i] xor b.i[i];
  end;
end;

function VecI32x16Not(const a: TVecI32x16): TVecI32x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.NotI32x16) then
    Result := dispatch^.NotI32x16(a)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := not a.i[i];
  end;
end;

function VecI32x16AndNot(const a, b: TVecI32x16): TVecI32x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.AndNotI32x16) then
    Result := dispatch^.AndNotI32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := (not a.i[i]) and b.i[i];
  end;
end;

function VecI32x16ShiftLeft(const a: TVecI32x16; count: Integer): TVecI32x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftLeftI32x16) then
    Result := dispatch^.ShiftLeftI32x16(a, count)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := a.i[i] shl count;
  end;
end;

function VecI32x16ShiftRight(const a: TVecI32x16; count: Integer): TVecI32x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftRightI32x16) then
    Result := dispatch^.ShiftRightI32x16(a, count)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := Int32(UInt32(a.i[i]) shr count);
  end;
end;

function VecI32x16ShiftRightArith(const a: TVecI32x16; count: Integer): TVecI32x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.ShiftRightArithI32x16) then
    Result := dispatch^.ShiftRightArithI32x16(a, count)
  else
  begin
    for i := 0 to 15 do
      Result.i[i] := SarLongint(a.i[i], count);
  end;
end;

function VecI32x16CmpEq(const a, b: TVecI32x16): TMask16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpEqI32x16) then
    Result := dispatch^.CmpEqI32x16(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 15 do
      if a.i[i] = b.i[i] then Result := Result or (1 shl i);
  end;
end;

function VecI32x16CmpLt(const a, b: TVecI32x16): TMask16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpLtI32x16) then
    Result := dispatch^.CmpLtI32x16(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 15 do
      if a.i[i] < b.i[i] then Result := Result or (1 shl i);
  end;
end;

function VecI32x16CmpGt(const a, b: TVecI32x16): TMask16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.CmpGtI32x16) then
    Result := dispatch^.CmpGtI32x16(a, b)
  else
  begin
    Result := 0;
    for i := 0 to 15 do
      if a.i[i] > b.i[i] then Result := Result or (1 shl i);
  end;
end;

function VecI32x16Min(const a, b: TVecI32x16): TVecI32x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MinI32x16) then
    Result := dispatch^.MinI32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      if a.i[i] < b.i[i] then
        Result.i[i] := a.i[i]
      else
        Result.i[i] := b.i[i];
  end;
end;

function VecI32x16Max(const a, b: TVecI32x16): TVecI32x16;
var dispatch: PSimdDispatchTable;
    i: Integer;
begin
  dispatch := GetDispatchTable;
  if (dispatch <> nil) and Assigned(dispatch^.MaxI32x16) then
    Result := dispatch^.MaxI32x16(a, b)
  else
  begin
    for i := 0 to 15 do
      if a.i[i] > b.i[i] then
        Result.i[i] := a.i[i]
      else
        Result.i[i] := b.i[i];
  end;
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


