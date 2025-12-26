unit fafafa.core.simd.riscvv;

{$mode objfpc}
{$I fafafa.core.settings.inc}

// =============================================================
//  ⚠️  EXPERIMENTAL - 实验性后端  ⚠️
// =============================================================
// 此后端处于实验阶段，可能存在以下问题：
// - API 可能在未来版本中发生重大变更
// - 功能覆盖不完整，许多操作回退到 scalar 实现
// - 未经过完整的测试和性能验证
// - 仅在 RISC-V 平台上有原生加速，其他平台使用 scalar 回退
//
// 生产环境请谨慎使用。欢迎提交 bug 报告和改进建议。
// =============================================================

{$IF DEFINED(CPURISCV64) OR DEFINED(CPURISCV32)}
  {$NOTE RISC-V V backend is experimental - API may change}
{$ELSE}
  {$NOTE RISC-V V backend: using scalar fallback on non-RISC-V platform}
{$ENDIF}

interface

uses
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch;

// =============================================================
// RISC-V V (Vector Extension) SIMD Backend
// =============================================================
// This unit implements SIMD operations using RISC-V V extension.
// On non-RISC-V platforms, scalar fallback implementations are used.
//
// RISC-V V Key Features:
// - Scalable vector length (VLEN)
// - Vector registers v0-v31
// - LMUL (length multiplier) for flexible register grouping
// - Rich predication via mask registers
//
// Key Instructions Used:
// - vle32.v/vse32.v: Load/store 32-bit elements
// - vle64.v/vse64.v: Load/store 64-bit elements
// - vfadd.vv/vfsub.vv/vfmul.vv/vfdiv.vv: Float arithmetic
// - vadd.vv/vsub.vv/vmul.vv: Integer arithmetic
// - vfmin.vv/vfmax.vv: Float min/max
// - vfsqrt.v: Float square root
// - vmfeq.vv/vmflt.vv/vmfle.vv: Float comparison
// - vand.vv/vor.vv/vxor.vv: Bitwise operations
// - vsll.vx/vsrl.vx/vsra.vx: Shift operations
// =============================================================

procedure RegisterRISCVVBackend;

// === Facade Functions ===
// Memory operations
function MemEqual_RISCVV(a, b: Pointer; len: SizeUInt): LongBool;
function MemFindByte_RISCVV(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
function MemDiffRange_RISCVV(a, b: Pointer; len: SizeUInt; out firstDiff, lastDiff: SizeUInt): Boolean;
procedure MemCopy_RISCVV(src, dst: Pointer; len: SizeUInt);
procedure MemSet_RISCVV(dst: Pointer; len: SizeUInt; value: Byte);
procedure MemReverse_RISCVV(p: Pointer; len: SizeUInt);

// Statistics functions
function SumBytes_RISCVV(p: Pointer; len: SizeUInt): UInt64;
procedure MinMaxBytes_RISCVV(p: Pointer; len: SizeUInt; out minVal, maxVal: Byte);
function CountByte_RISCVV(p: Pointer; len: SizeUInt; value: Byte): SizeUInt;

// Text processing functions
function Utf8Validate_RISCVV(p: Pointer; len: SizeUInt): Boolean;
function AsciiIEqual_RISCVV(a, b: Pointer; len: SizeUInt): Boolean;
procedure ToLowerAscii_RISCVV(p: Pointer; len: SizeUInt);
procedure ToUpperAscii_RISCVV(p: Pointer; len: SizeUInt);

// Search functions
function BytesIndexOf_RISCVV(haystack: Pointer; haystackLen: SizeUInt; needle: Pointer; needleLen: SizeUInt): PtrInt;

// Bitset functions
function BitsetPopCount_RISCVV(p: Pointer; byteLen: SizeUInt): SizeUInt;

implementation

uses
  fafafa.core.math,
  SysUtils,
  fafafa.core.simd.scalar;

// =============================================================
// RISC-V V Assembly Implementations
// =============================================================
// Note: FreePascal's RISC-V V assembly support is limited.
// When CPURISCV64 is defined and V extension is available,
// we use inline assembly. Otherwise, scalar fallback is used.
// =============================================================

{$IFDEF CPURISCV64}
// RISC-V V extension detection
// In practice, this would need runtime detection via HWCAP or similar
{$DEFINE RISCVV_ASSEMBLY}
{$ENDIF}

{$IFDEF RISCVV_ASSEMBLY}

// =============================================================
// F32x4 Operations (128-bit, 4x Single)
// =============================================================

function RISCVVAddF32x4(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  // a0 = &a, a1 = &b, a0 (return) = &Result
  // Set vector length to 4 elements of 32-bit
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vfadd.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVSubF32x4(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vfsub.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVMulF32x4(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vfmul.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVDivF32x4(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vfdiv.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVAbsF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vfabs.v v0, v0
  vse32.v v0, (a0)
end;

function RISCVVSqrtF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vfsqrt.v v0, v0
  vse32.v v0, (a0)
end;

function RISCVVMinF32x4(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vfmin.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVMaxF32x4(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vfmax.vv v0, v0, v1
  vse32.v v0, (a0)
end;

// =============================================================
// F64x2 Operations (128-bit, 2x Double)
// =============================================================

function RISCVVAddF64x2(const a, b: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vfadd.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVSubF64x2(const a, b: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vfsub.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVMulF64x2(const a, b: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vfmul.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVDivF64x2(const a, b: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vfdiv.vv v0, v0, v1
  vse64.v v0, (a0)
end;

// =============================================================
// I32x4 Operations (128-bit, 4x Int32)
// =============================================================

function RISCVVAddI32x4(const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vadd.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVSubI32x4(const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vsub.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVMulI32x4(const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmul.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVAndI32x4(const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vand.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVOrI32x4(const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vor.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVXorI32x4(const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vxor.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVNotI32x4(const a: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vnot.v v0, v0
  vse32.v v0, (a0)
end;

{$ELSE}

// =============================================================
// Scalar Fallback Implementations
// =============================================================
// Used when RISC-V V extension is not available

// =============================================================
// F32x4 Operations (128-bit, 4x Single)
// =============================================================

function RISCVVAddF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] + b.f[i];
end;

function RISCVVSubF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] - b.f[i];
end;

function RISCVVMulF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] * b.f[i];
end;

function RISCVVDivF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] / b.f[i];
end;

function RISCVVAbsF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Abs(a.f[i]);
end;

function RISCVVSqrtF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Sqrt(a.f[i]);
end;

function RISCVVMinF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if a.f[i] < b.f[i] then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

function RISCVVMaxF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if a.f[i] > b.f[i] then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

// =============================================================
// F64x2 Operations (128-bit, 2x Double)
// =============================================================

function RISCVVAddF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.d[i] + b.d[i];
end;

function RISCVVSubF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.d[i] - b.d[i];
end;

function RISCVVMulF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.d[i] * b.d[i];
end;

function RISCVVDivF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.d[i] / b.d[i];
end;

// =============================================================
// I32x4 Operations (128-bit, 4x Int32)
// =============================================================

function RISCVVAddI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] + b.i[i];
end;

function RISCVVSubI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] - b.i[i];
end;

function RISCVVMulI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] * b.i[i];
end;

function RISCVVAndI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] and b.i[i];
end;

function RISCVVOrI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] or b.i[i];
end;

function RISCVVXorI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] xor b.i[i];
end;

function RISCVVNotI32x4(const a: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := not a.i[i];
end;

{$ENDIF}

// =============================================================
// Common Implementations (both assembly and scalar paths)
// =============================================================

// =============================================================
// F32x4 Extended Math Operations
// =============================================================

function RISCVVFmaF32x4(const a, b, c: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  // a * b + c
  for i := 0 to 3 do
    Result.f[i] := a.f[i] * b.f[i] + c.f[i];
end;

function RISCVVRcpF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := 1.0 / a.f[i];
end;

function RISCVVRsqrtF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := 1.0 / Sqrt(a.f[i]);
end;

function RISCVVFloorF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Floor(a.f[i]);
end;

function RISCVVCeilF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Ceil(a.f[i]);
end;

function RISCVVRoundF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Round(a.f[i]);
end;

function RISCVVTruncF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Trunc(a.f[i]);
end;

function RISCVVClampF32x4(const a, minVal, maxVal: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
  begin
    if a.f[i] < minVal.f[i] then
      Result.f[i] := minVal.f[i]
    else if a.f[i] > maxVal.f[i] then
      Result.f[i] := maxVal.f[i]
    else
      Result.f[i] := a.f[i];
  end;
end;

// =============================================================
// F32x4 Comparison Operations
// =============================================================

function RISCVVCmpEqF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.f[i] = b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.f[i] < b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.f[i] <= b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.f[i] > b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.f[i] >= b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.f[i] <> b.f[i] then
      Result := Result or (1 shl i);
end;

// =============================================================
// I32x4 Comparison Operations
// =============================================================

function RISCVVCmpEqI32x4(const a, b: TVecI32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.i[i] = b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtI32x4(const a, b: TVecI32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.i[i] < b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtI32x4(const a, b: TVecI32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.i[i] > b.i[i] then
      Result := Result or (1 shl i);
end;

// =============================================================
// I32x4 Extended Operations
// =============================================================

function RISCVVAndNotI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  // (~a) and b
  for i := 0 to 3 do
    Result.i[i] := (not a.i[i]) and b.i[i];
end;

function RISCVVShiftLeftI32x4(const a: TVecI32x4; count: Integer): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] shl count;
end;

function RISCVVShiftRightI32x4(const a: TVecI32x4; count: Integer): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := Int32(UInt32(a.i[i]) shr count);
end;

function RISCVVShiftRightArithI32x4(const a: TVecI32x4; count: Integer): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := SarLongint(a.i[i], count);
end;

function RISCVVMinI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if a.i[i] < b.i[i] then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

function RISCVVMaxI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if a.i[i] > b.i[i] then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

// =============================================================
// I64x2 Operations (128-bit, 2x Int64)
// =============================================================

function RISCVVAddI64x2(const a, b: TVecI64x2): TVecI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.i[i] := a.i[i] + b.i[i];
end;

function RISCVVSubI64x2(const a, b: TVecI64x2): TVecI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.i[i] := a.i[i] - b.i[i];
end;

function RISCVVAndI64x2(const a, b: TVecI64x2): TVecI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.i[i] := a.i[i] and b.i[i];
end;

function RISCVVOrI64x2(const a, b: TVecI64x2): TVecI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.i[i] := a.i[i] or b.i[i];
end;

function RISCVVXorI64x2(const a, b: TVecI64x2): TVecI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.i[i] := a.i[i] xor b.i[i];
end;

function RISCVVNotI64x2(const a: TVecI64x2): TVecI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.i[i] := not a.i[i];
end;

// =============================================================
// F32x4 Vector Math Operations
// =============================================================

function RISCVVDotF32x4(const a, b: TVecF32x4): Single;
begin
  Result := a.f[0] * b.f[0] + a.f[1] * b.f[1] + a.f[2] * b.f[2] + a.f[3] * b.f[3];
end;

function RISCVVDotF32x3(const a, b: TVecF32x4): Single;
begin
  Result := a.f[0] * b.f[0] + a.f[1] * b.f[1] + a.f[2] * b.f[2];
end;

function RISCVVCrossF32x3(const a, b: TVecF32x4): TVecF32x4;
begin
  Result.f[0] := a.f[1] * b.f[2] - a.f[2] * b.f[1];
  Result.f[1] := a.f[2] * b.f[0] - a.f[0] * b.f[2];
  Result.f[2] := a.f[0] * b.f[1] - a.f[1] * b.f[0];
  Result.f[3] := 0.0;
end;

function RISCVVLengthF32x4(const a: TVecF32x4): Single;
begin
  Result := Sqrt(a.f[0] * a.f[0] + a.f[1] * a.f[1] + a.f[2] * a.f[2] + a.f[3] * a.f[3]);
end;

function RISCVVLengthF32x3(const a: TVecF32x4): Single;
begin
  Result := Sqrt(a.f[0] * a.f[0] + a.f[1] * a.f[1] + a.f[2] * a.f[2]);
end;

function RISCVVNormalizeF32x4(const a: TVecF32x4): TVecF32x4;
var len, invLen: Single;
    i: Integer;
begin
  len := RISCVVLengthF32x4(a);
  if len > 1e-10 then
  begin
    invLen := 1.0 / len;
    for i := 0 to 3 do
      Result.f[i] := a.f[i] * invLen;
  end
  else
    Result := a;
end;

function RISCVVNormalizeF32x3(const a: TVecF32x4): TVecF32x4;
var len, invLen: Single;
begin
  len := RISCVVLengthF32x3(a);
  if len > 1e-10 then
  begin
    invLen := 1.0 / len;
    Result.f[0] := a.f[0] * invLen;
    Result.f[1] := a.f[1] * invLen;
    Result.f[2] := a.f[2] * invLen;
    Result.f[3] := 0.0;
  end
  else
    Result := a;
end;

// =============================================================
// F32x4 Reduction Operations
// =============================================================

function RISCVVReduceAddF32x4(const a: TVecF32x4): Single;
begin
  Result := a.f[0] + a.f[1] + a.f[2] + a.f[3];
end;

function RISCVVReduceMinF32x4(const a: TVecF32x4): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 3 do
    if a.f[i] < Result then
      Result := a.f[i];
end;

function RISCVVReduceMaxF32x4(const a: TVecF32x4): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 3 do
    if a.f[i] > Result then
      Result := a.f[i];
end;

function RISCVVReduceMulF32x4(const a: TVecF32x4): Single;
begin
  Result := a.f[0] * a.f[1] * a.f[2] * a.f[3];
end;

// =============================================================
// F32x4 Memory Operations
// =============================================================

function RISCVVLoadF32x4(p: PSingle): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := p[i];
end;

function RISCVVLoadF32x4Aligned(p: PSingle): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := p[i];
end;

procedure RISCVVStoreF32x4(p: PSingle; const a: TVecF32x4);
var i: Integer;
begin
  for i := 0 to 3 do
    p[i] := a.f[i];
end;

procedure RISCVVStoreF32x4Aligned(p: PSingle; const a: TVecF32x4);
var i: Integer;
begin
  for i := 0 to 3 do
    p[i] := a.f[i];
end;

// =============================================================
// F32x4 Utility Operations
// =============================================================

function RISCVVSplatF32x4(value: Single): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := value;
end;

function RISCVVZeroF32x4: TVecF32x4;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function RISCVVSelectF32x4(const mask: TMask4; const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if (mask and (1 shl i)) <> 0 then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

function RISCVVExtractF32x4(const a: TVecF32x4; index: Integer): Single;
begin
  Result := a.f[index and 3];
end;

function RISCVVInsertF32x4(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4;
begin
  Result := a;
  Result.f[index and 3] := value;
end;

// =============================================================
// F32x8 Operations (256-bit, 8x Single)
// =============================================================

function RISCVVAddF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := a.f[i] + b.f[i];
end;

function RISCVVSubF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := a.f[i] - b.f[i];
end;

function RISCVVMulF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := a.f[i] * b.f[i];
end;

function RISCVVDivF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := a.f[i] / b.f[i];
end;

// =============================================================
// F64x4 Operations (256-bit, 4x Double)
// =============================================================

function RISCVVAddF64x4(const a, b: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := a.d[i] + b.d[i];
end;

function RISCVVSubF64x4(const a, b: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := a.d[i] - b.d[i];
end;

function RISCVVMulF64x4(const a, b: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := a.d[i] * b.d[i];
end;

function RISCVVDivF64x4(const a, b: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := a.d[i] / b.d[i];
end;

// =============================================================
// I32x8 Operations (256-bit, 8x Int32)
// =============================================================

function RISCVVAddI32x8(const a, b: TVecI32x8): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] + b.i[i];
end;

function RISCVVSubI32x8(const a, b: TVecI32x8): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] - b.i[i];
end;

function RISCVVMulI32x8(const a, b: TVecI32x8): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] * b.i[i];
end;

function RISCVVAndI32x8(const a, b: TVecI32x8): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] and b.i[i];
end;

function RISCVVOrI32x8(const a, b: TVecI32x8): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] or b.i[i];
end;

function RISCVVXorI32x8(const a, b: TVecI32x8): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] xor b.i[i];
end;

function RISCVVNotI32x8(const a: TVecI32x8): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := not a.i[i];
end;

function RISCVVAndNotI32x8(const a, b: TVecI32x8): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := (not a.i[i]) and b.i[i];
end;

function RISCVVShiftLeftI32x8(const a: TVecI32x8; count: Integer): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] shl count;
end;

function RISCVVShiftRightI32x8(const a: TVecI32x8; count: Integer): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := Int32(UInt32(a.i[i]) shr count);
end;

function RISCVVShiftRightArithI32x8(const a: TVecI32x8; count: Integer): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := SarLongint(a.i[i], count);
end;

function RISCVVCmpEqI32x8(const a, b: TVecI32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] = b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtI32x8(const a, b: TVecI32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] < b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtI32x8(const a, b: TVecI32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] > b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVMinI32x8(const a, b: TVecI32x8): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.i[i] < b.i[i] then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

function RISCVVMaxI32x8(const a, b: TVecI32x8): TVecI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.i[i] > b.i[i] then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

// =============================================================
// I32x16 Operations (512-bit, 16x Int32)
// =============================================================

function RISCVVAddI32x16(const a, b: TVecI32x16): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := a.i[i] + b.i[i];
end;

function RISCVVSubI32x16(const a, b: TVecI32x16): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := a.i[i] - b.i[i];
end;

function RISCVVMulI32x16(const a, b: TVecI32x16): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := a.i[i] * b.i[i];
end;

function RISCVVAndI32x16(const a, b: TVecI32x16): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := a.i[i] and b.i[i];
end;

function RISCVVOrI32x16(const a, b: TVecI32x16): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := a.i[i] or b.i[i];
end;

function RISCVVXorI32x16(const a, b: TVecI32x16): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := a.i[i] xor b.i[i];
end;

function RISCVVNotI32x16(const a: TVecI32x16): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := not a.i[i];
end;

function RISCVVAndNotI32x16(const a, b: TVecI32x16): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := (not a.i[i]) and b.i[i];
end;

function RISCVVShiftLeftI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := a.i[i] shl count;
end;

function RISCVVShiftRightI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := Int32(UInt32(a.i[i]) shr count);
end;

function RISCVVShiftRightArithI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := SarLongint(a.i[i], count);
end;

function RISCVVCmpEqI32x16(const a, b: TVecI32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.i[i] = b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtI32x16(const a, b: TVecI32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.i[i] < b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtI32x16(const a, b: TVecI32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.i[i] > b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVMinI32x16(const a, b: TVecI32x16): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.i[i] < b.i[i] then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

function RISCVVMaxI32x16(const a, b: TVecI32x16): TVecI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.i[i] > b.i[i] then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

// =============================================================
// F32x16 Operations (512-bit, 16x Single)
// =============================================================

function RISCVVAddF32x16(const a, b: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := a.f[i] + b.f[i];
end;

function RISCVVSubF32x16(const a, b: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := a.f[i] - b.f[i];
end;

function RISCVVMulF32x16(const a, b: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := a.f[i] * b.f[i];
end;

function RISCVVDivF32x16(const a, b: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := a.f[i] / b.f[i];
end;

// =============================================================
// F64x8 Operations (512-bit, 8x Double)
// =============================================================

function RISCVVAddF64x8(const a, b: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := a.d[i] + b.d[i];
end;

function RISCVVSubF64x8(const a, b: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := a.d[i] - b.d[i];
end;

function RISCVVMulF64x8(const a, b: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := a.d[i] * b.d[i];
end;

function RISCVVDivF64x8(const a, b: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := a.d[i] / b.d[i];
end;

// =============================================================
// Facade Function Implementations
// =============================================================
// These delegate to the scalar backend's implementations

function MemEqual_RISCVV(a, b: Pointer; len: SizeUInt): LongBool;
begin
  Result := MemEqual_Scalar(a, b, len);
end;

function MemFindByte_RISCVV(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
begin
  Result := MemFindByte_Scalar(p, len, value);
end;

function MemDiffRange_RISCVV(a, b: Pointer; len: SizeUInt; out firstDiff, lastDiff: SizeUInt): Boolean;
begin
  Result := MemDiffRange_Scalar(a, b, len, firstDiff, lastDiff);
end;

procedure MemCopy_RISCVV(src, dst: Pointer; len: SizeUInt);
begin
  MemCopy_Scalar(src, dst, len);
end;

procedure MemSet_RISCVV(dst: Pointer; len: SizeUInt; value: Byte);
begin
  MemSet_Scalar(dst, len, value);
end;

procedure MemReverse_RISCVV(p: Pointer; len: SizeUInt);
begin
  MemReverse_Scalar(p, len);
end;

function SumBytes_RISCVV(p: Pointer; len: SizeUInt): UInt64;
begin
  Result := SumBytes_Scalar(p, len);
end;

procedure MinMaxBytes_RISCVV(p: Pointer; len: SizeUInt; out minVal, maxVal: Byte);
begin
  MinMaxBytes_Scalar(p, len, minVal, maxVal);
end;

function CountByte_RISCVV(p: Pointer; len: SizeUInt; value: Byte): SizeUInt;
begin
  Result := CountByte_Scalar(p, len, value);
end;

function Utf8Validate_RISCVV(p: Pointer; len: SizeUInt): Boolean;
begin
  Result := Utf8Validate_Scalar(p, len);
end;

function AsciiIEqual_RISCVV(a, b: Pointer; len: SizeUInt): Boolean;
begin
  Result := AsciiIEqual_Scalar(a, b, len);
end;

procedure ToLowerAscii_RISCVV(p: Pointer; len: SizeUInt);
begin
  ToLowerAscii_Scalar(p, len);
end;

procedure ToUpperAscii_RISCVV(p: Pointer; len: SizeUInt);
begin
  ToUpperAscii_Scalar(p, len);
end;

function BytesIndexOf_RISCVV(haystack: Pointer; haystackLen: SizeUInt; needle: Pointer; needleLen: SizeUInt): PtrInt;
begin
  Result := BytesIndexOf_Scalar(haystack, haystackLen, needle, needleLen);
end;

function BitsetPopCount_RISCVV(p: Pointer; byteLen: SizeUInt): SizeUInt;
begin
  Result := BitsetPopCount_Scalar(p, byteLen);
end;

// =============================================================
// Backend Registration
// =============================================================

procedure RegisterRISCVVBackend;
var
  table: TSimdDispatchTable;
begin
  FillChar(table, SizeOf(table), 0);

  // Backend info
  table.Backend := sbRISCVV;
  table.BackendInfo.Backend := sbRISCVV;
  table.BackendInfo.Name := 'RISC-V V';
  table.BackendInfo.Description := 'RISC-V Vector Extension (RVV)';
  table.BackendInfo.Available := True;
  table.BackendInfo.Priority := 35;  // Between Scalar (10) and NEON (40)
  table.BackendInfo.Capabilities := [
    scBasicArithmetic,
    scComparison,
    scMathFunctions,
    scReduction,
    scShuffle,
    scIntegerOps,
    scLoadStore
  ];

  // === F32x4 Operations ===
  table.AddF32x4 := @RISCVVAddF32x4;
  table.SubF32x4 := @RISCVVSubF32x4;
  table.MulF32x4 := @RISCVVMulF32x4;
  table.DivF32x4 := @RISCVVDivF32x4;

  // F32x4 Math
  table.AbsF32x4 := @RISCVVAbsF32x4;
  table.SqrtF32x4 := @RISCVVSqrtF32x4;
  table.MinF32x4 := @RISCVVMinF32x4;
  table.MaxF32x4 := @RISCVVMaxF32x4;
  table.FmaF32x4 := @RISCVVFmaF32x4;
  table.RcpF32x4 := @RISCVVRcpF32x4;
  table.RsqrtF32x4 := @RISCVVRsqrtF32x4;
  table.FloorF32x4 := @RISCVVFloorF32x4;
  table.CeilF32x4 := @RISCVVCeilF32x4;
  table.RoundF32x4 := @RISCVVRoundF32x4;
  table.TruncF32x4 := @RISCVVTruncF32x4;
  table.ClampF32x4 := @RISCVVClampF32x4;

  // F32x4 Vector Math
  table.DotF32x4 := @RISCVVDotF32x4;
  table.DotF32x3 := @RISCVVDotF32x3;
  table.CrossF32x3 := @RISCVVCrossF32x3;
  table.LengthF32x4 := @RISCVVLengthF32x4;
  table.LengthF32x3 := @RISCVVLengthF32x3;
  table.NormalizeF32x4 := @RISCVVNormalizeF32x4;
  table.NormalizeF32x3 := @RISCVVNormalizeF32x3;

  // F32x4 Reduction
  table.ReduceAddF32x4 := @RISCVVReduceAddF32x4;
  table.ReduceMinF32x4 := @RISCVVReduceMinF32x4;
  table.ReduceMaxF32x4 := @RISCVVReduceMaxF32x4;
  table.ReduceMulF32x4 := @RISCVVReduceMulF32x4;

  // F32x4 Comparison
  table.CmpEqF32x4 := @RISCVVCmpEqF32x4;
  table.CmpLtF32x4 := @RISCVVCmpLtF32x4;
  table.CmpLeF32x4 := @RISCVVCmpLeF32x4;
  table.CmpGtF32x4 := @RISCVVCmpGtF32x4;
  table.CmpGeF32x4 := @RISCVVCmpGeF32x4;
  table.CmpNeF32x4 := @RISCVVCmpNeF32x4;

  // F32x4 Memory
  table.LoadF32x4 := @RISCVVLoadF32x4;
  table.LoadF32x4Aligned := @RISCVVLoadF32x4Aligned;
  table.StoreF32x4 := @RISCVVStoreF32x4;
  table.StoreF32x4Aligned := @RISCVVStoreF32x4Aligned;

  // F32x4 Utility
  table.SplatF32x4 := @RISCVVSplatF32x4;
  table.ZeroF32x4 := @RISCVVZeroF32x4;
  table.SelectF32x4 := @RISCVVSelectF32x4;
  table.ExtractF32x4 := @RISCVVExtractF32x4;
  table.InsertF32x4 := @RISCVVInsertF32x4;

  // === F64x2 Operations ===
  table.AddF64x2 := @RISCVVAddF64x2;
  table.SubF64x2 := @RISCVVSubF64x2;
  table.MulF64x2 := @RISCVVMulF64x2;
  table.DivF64x2 := @RISCVVDivF64x2;

  // === I32x4 Operations ===
  table.AddI32x4 := @RISCVVAddI32x4;
  table.SubI32x4 := @RISCVVSubI32x4;
  table.MulI32x4 := @RISCVVMulI32x4;

  // I32x4 Bitwise
  table.AndI32x4 := @RISCVVAndI32x4;
  table.OrI32x4 := @RISCVVOrI32x4;
  table.XorI32x4 := @RISCVVXorI32x4;
  table.NotI32x4 := @RISCVVNotI32x4;
  table.AndNotI32x4 := @RISCVVAndNotI32x4;

  // I32x4 Shift
  table.ShiftLeftI32x4 := @RISCVVShiftLeftI32x4;
  table.ShiftRightI32x4 := @RISCVVShiftRightI32x4;
  table.ShiftRightArithI32x4 := @RISCVVShiftRightArithI32x4;

  // I32x4 Comparison
  table.CmpEqI32x4 := @RISCVVCmpEqI32x4;
  table.CmpLtI32x4 := @RISCVVCmpLtI32x4;
  table.CmpGtI32x4 := @RISCVVCmpGtI32x4;

  // I32x4 Min/Max
  table.MinI32x4 := @RISCVVMinI32x4;
  table.MaxI32x4 := @RISCVVMaxI32x4;

  // === I64x2 Operations ===
  table.AddI64x2 := @RISCVVAddI64x2;
  table.SubI64x2 := @RISCVVSubI64x2;
  table.AndI64x2 := @RISCVVAndI64x2;
  table.OrI64x2 := @RISCVVOrI64x2;
  table.XorI64x2 := @RISCVVXorI64x2;
  table.NotI64x2 := @RISCVVNotI64x2;

  // === F32x8 Operations ===
  table.AddF32x8 := @RISCVVAddF32x8;
  table.SubF32x8 := @RISCVVSubF32x8;
  table.MulF32x8 := @RISCVVMulF32x8;
  table.DivF32x8 := @RISCVVDivF32x8;

  // === F64x4 Operations ===
  table.AddF64x4 := @RISCVVAddF64x4;
  table.SubF64x4 := @RISCVVSubF64x4;
  table.MulF64x4 := @RISCVVMulF64x4;
  table.DivF64x4 := @RISCVVDivF64x4;

  // === I32x8 Operations ===
  table.AddI32x8 := @RISCVVAddI32x8;
  table.SubI32x8 := @RISCVVSubI32x8;
  table.MulI32x8 := @RISCVVMulI32x8;
  table.AndI32x8 := @RISCVVAndI32x8;
  table.OrI32x8 := @RISCVVOrI32x8;
  table.XorI32x8 := @RISCVVXorI32x8;
  table.NotI32x8 := @RISCVVNotI32x8;
  table.AndNotI32x8 := @RISCVVAndNotI32x8;
  table.ShiftLeftI32x8 := @RISCVVShiftLeftI32x8;
  table.ShiftRightI32x8 := @RISCVVShiftRightI32x8;
  table.ShiftRightArithI32x8 := @RISCVVShiftRightArithI32x8;
  table.CmpEqI32x8 := @RISCVVCmpEqI32x8;
  table.CmpLtI32x8 := @RISCVVCmpLtI32x8;
  table.CmpGtI32x8 := @RISCVVCmpGtI32x8;
  table.MinI32x8 := @RISCVVMinI32x8;
  table.MaxI32x8 := @RISCVVMaxI32x8;

  // === I32x16 Operations ===
  table.AddI32x16 := @RISCVVAddI32x16;
  table.SubI32x16 := @RISCVVSubI32x16;
  table.MulI32x16 := @RISCVVMulI32x16;
  table.AndI32x16 := @RISCVVAndI32x16;
  table.OrI32x16 := @RISCVVOrI32x16;
  table.XorI32x16 := @RISCVVXorI32x16;
  table.NotI32x16 := @RISCVVNotI32x16;
  table.AndNotI32x16 := @RISCVVAndNotI32x16;
  table.ShiftLeftI32x16 := @RISCVVShiftLeftI32x16;
  table.ShiftRightI32x16 := @RISCVVShiftRightI32x16;
  table.ShiftRightArithI32x16 := @RISCVVShiftRightArithI32x16;
  table.CmpEqI32x16 := @RISCVVCmpEqI32x16;
  table.CmpLtI32x16 := @RISCVVCmpLtI32x16;
  table.CmpGtI32x16 := @RISCVVCmpGtI32x16;
  table.MinI32x16 := @RISCVVMinI32x16;
  table.MaxI32x16 := @RISCVVMaxI32x16;

  // === F32x16 Operations (512-bit, 16x Single) ===
  table.AddF32x16 := @RISCVVAddF32x16;
  table.SubF32x16 := @RISCVVSubF32x16;
  table.MulF32x16 := @RISCVVMulF32x16;
  table.DivF32x16 := @RISCVVDivF32x16;

  // === F64x8 Operations (512-bit, 8x Double) ===
  table.AddF64x8 := @RISCVVAddF64x8;
  table.SubF64x8 := @RISCVVSubF64x8;
  table.MulF64x8 := @RISCVVMulF64x8;
  table.DivF64x8 := @RISCVVDivF64x8;

  // === Facade Functions ===
  table.MemEqual := @MemEqual_RISCVV;
  table.MemFindByte := @MemFindByte_RISCVV;
  table.MemDiffRange := @MemDiffRange_RISCVV;
  table.MemCopy := @MemCopy_RISCVV;
  table.MemSet := @MemSet_RISCVV;
  table.MemReverse := @MemReverse_RISCVV;
  table.SumBytes := @SumBytes_RISCVV;
  table.MinMaxBytes := @MinMaxBytes_RISCVV;
  table.CountByte := @CountByte_RISCVV;
  table.Utf8Validate := @Utf8Validate_RISCVV;
  table.AsciiIEqual := @AsciiIEqual_RISCVV;
  table.ToLowerAscii := @ToLowerAscii_RISCVV;
  table.ToUpperAscii := @ToUpperAscii_RISCVV;
  table.BytesIndexOf := @BytesIndexOf_RISCVV;
  table.BitsetPopCount := @BitsetPopCount_RISCVV;

  // Register the backend
  RegisterBackend(sbRISCVV, table);
end;

// =============================================================
// Initialization
// =============================================================
// Auto-register on RISC-V platforms with V extension

initialization
  {$IFDEF CPURISCV64}
  // On RISC-V 64-bit, attempt to register
  // In practice, runtime detection of V extension would be needed
  RegisterRISCVVBackend;
  // ✅ P1-D: Register rebuilder callback for VectorAsmEnabled changes
  RegisterBackendRebuilder(sbRISCVV, @RegisterRISCVVBackend);
  {$ENDIF}
  {$IFDEF CPURISCV32}
  RegisterRISCVVBackend;
  // ✅ P1-D: Register rebuilder callback for VectorAsmEnabled changes
  RegisterBackendRebuilder(sbRISCVV, @RegisterRISCVVBackend);
  {$ENDIF}

end.
