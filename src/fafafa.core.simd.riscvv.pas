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
  Math,  // RTL Math 单元
  SysUtils,
  fafafa.core.simd.scalar;

// =============================================================
// RISC-V V Assembly Implementations
// =============================================================
// Note: FreePascal's RISC-V V assembly support is limited.
// When CPURISCV64 is defined and V extension is available,
// we use inline assembly. Otherwise, scalar fallback is used.
// =============================================================

{$IF DEFINED(CPURISCV64) AND DEFINED(SIMD_BACKEND_RISCVV)}
// RISC-V V extension - requires FPC 3.3.1+ with RVV assembler support
// Runtime detection via HWCAP recommended for production use
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

// =============================================================
// F32x4 Extended Operations
// =============================================================

function RISCVVFmaF32x4(const a, b, c: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  // Result = a * b + c
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)      // a
  vle32.v v1, (a1)      // b
  vle32.v v2, (a2)      // c
  vfmadd.vv v0, v1, v2  // v0 = v0 * v1 + v2
  vse32.v v0, (a0)
end;

function RISCVVRcpF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  // Result = 1.0 / a (approximate)
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vfrec7.v v0, v0       // Reciprocal approximation
  vse32.v v0, (a0)
end;

function RISCVVRsqrtF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  // Result = 1.0 / sqrt(a) (approximate)
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vfrsqrt7.v v0, v0     // Reciprocal sqrt approximation
  vse32.v v0, (a0)
end;

function RISCVVNegF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vfneg.v v0, v0
  vse32.v v0, (a0)
end;

// =============================================================
// F32x4 Comparison Operations (return TMask4)
// =============================================================

function RISCVVCmpEqF32x4(const a, b: TVecF32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmfeq.vv v0, v0, v1   // Mask in v0
  // Extract mask to scalar - simplified, returns all-ones or all-zeros per element
  vmv.x.s a0, v0
end;

function RISCVVCmpLtF32x4(const a, b: TVecF32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmflt.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLeF32x4(const a, b: TVecF32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmfle.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpGtF32x4(const a, b: TVecF32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmfgt.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpGeF32x4(const a, b: TVecF32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmfge.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpNeF32x4(const a, b: TVecF32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmfne.vv v0, v0, v1
  vmv.x.s a0, v0
end;

// =============================================================
// I32x4 Comparison Operations
// =============================================================

function RISCVVCmpEqI32x4(const a, b: TVecI32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmseq.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLtI32x4(const a, b: TVecI32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmslt.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLeI32x4(const a, b: TVecI32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmsle.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpGtI32x4(const a, b: TVecI32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmsgt.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpGeI32x4(const a, b: TVecI32x4): TMask4; assembler; nostackframe;
asm
  // a >= b  equals  NOT(a < b)
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmslt.vv v0, v0, v1   // a < b
  vmnot.m v0, v0        // NOT
  vmv.x.s a0, v0
end;

function RISCVVCmpNeI32x4(const a, b: TVecI32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmsne.vv v0, v0, v1
  vmv.x.s a0, v0
end;

// =============================================================
// I32x4 Extended Operations
// =============================================================

function RISCVVAndNotI32x4(const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  // Result = (NOT a) AND b
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vnot.v v0, v0
  vand.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVMinI32x4(const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmin.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVMaxI32x4(const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmax.vv v0, v0, v1
  vse32.v v0, (a0)
end;

// =============================================================
// I32x4 Shift Operations
// =============================================================

function RISCVVShiftLeftI32x4(const a: TVecI32x4; count: Integer): TVecI32x4; assembler; nostackframe;
asm
  // a0 = &a, a1 = count
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vsll.vx v0, v0, a1
  vse32.v v0, (a0)
end;

function RISCVVShiftRightI32x4(const a: TVecI32x4; count: Integer): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vsrl.vx v0, v0, a1    // Logical right shift
  vse32.v v0, (a0)
end;

function RISCVVShiftRightArithI32x4(const a: TVecI32x4; count: Integer): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vsra.vx v0, v0, a1    // Arithmetic right shift (sign-extend)
  vse32.v v0, (a0)
end;

// =============================================================
// F64x2 Extended Operations
// =============================================================

function RISCVVAbsF64x2(const a: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vfabs.v v0, v0
  vse64.v v0, (a0)
end;

function RISCVVSqrtF64x2(const a: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vfsqrt.v v0, v0
  vse64.v v0, (a0)
end;

function RISCVVMinF64x2(const a, b: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vfmin.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVMaxF64x2(const a, b: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vfmax.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVNegF64x2(const a: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vfneg.v v0, v0
  vse64.v v0, (a0)
end;

function RISCVVFmaF64x2(const a, b, c: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vle64.v v2, (a2)
  vfmadd.vv v0, v1, v2
  vse64.v v0, (a0)
end;

// =============================================================
// I64x2 Operations (128-bit, 2x Int64)
// =============================================================

function RISCVVAddI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vadd.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVSubI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vsub.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVAndI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vand.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVOrI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vor.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVXorI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vxor.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVNotI64x2(const a: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vnot.v v0, v0
  vse64.v v0, (a0)
end;

function RISCVVShiftLeftI64x2(const a: TVecI64x2; count: Integer): TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vsll.vx v0, v0, a1
  vse64.v v0, (a0)
end;

function RISCVVShiftRightI64x2(const a: TVecI64x2; count: Integer): TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vsrl.vx v0, v0, a1
  vse64.v v0, (a0)
end;

function RISCVVShiftRightArithI64x2(const a: TVecI64x2; count: Integer): TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vsra.vx v0, v0, a1
  vse64.v v0, (a0)
end;

// =============================================================
// U32x4 Operations (128-bit, 4x UInt32)
// =============================================================

function RISCVVAddU32x4(const a, b: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vadd.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVSubU32x4(const a, b: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vsub.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVMulU32x4(const a, b: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmul.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVMinU32x4(const a, b: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vminu.vv v0, v0, v1   // Unsigned min
  vse32.v v0, (a0)
end;

function RISCVVMaxU32x4(const a, b: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmaxu.vv v0, v0, v1   // Unsigned max
  vse32.v v0, (a0)
end;

function RISCVVCmpLtU32x4(const a, b: TVecU32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmsltu.vv v0, v0, v1  // Unsigned less than
  vmv.x.s a0, v0
end;

function RISCVVCmpLeU32x4(const a, b: TVecU32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmsleu.vv v0, v0, v1  // Unsigned less than or equal
  vmv.x.s a0, v0
end;

function RISCVVCmpGtU32x4(const a, b: TVecU32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmsgtu.vv v0, v0, v1  // Unsigned greater than
  vmv.x.s a0, v0
end;

// =============================================================
// I16x8 Operations (128-bit, 8x Int16)
// =============================================================

function RISCVVAddI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vadd.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVSubI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vsub.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVMulI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmul.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVMinI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmin.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVMaxI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmax.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVAndI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vand.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVOrI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vor.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVXorI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vxor.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVShiftLeftI16x8(const a: TVecI16x8; count: Integer): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vsll.vx v0, v0, a1
  vse16.v v0, (a0)
end;

function RISCVVShiftRightI16x8(const a: TVecI16x8; count: Integer): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vsrl.vx v0, v0, a1
  vse16.v v0, (a0)
end;

function RISCVVShiftRightArithI16x8(const a: TVecI16x8; count: Integer): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vsra.vx v0, v0, a1
  vse16.v v0, (a0)
end;

// =============================================================
// I8x16 Operations (128-bit, 16x Int8)
// =============================================================

function RISCVVAddI8x16(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vadd.vv v0, v0, v1
  vse8.v v0, (a0)
end;

function RISCVVSubI8x16(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vsub.vv v0, v0, v1
  vse8.v v0, (a0)
end;

function RISCVVMinI8x16(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmin.vv v0, v0, v1
  vse8.v v0, (a0)
end;

function RISCVVMaxI8x16(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmax.vv v0, v0, v1
  vse8.v v0, (a0)
end;

function RISCVVAndI8x16(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vand.vv v0, v0, v1
  vse8.v v0, (a0)
end;

function RISCVVOrI8x16(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vor.vv v0, v0, v1
  vse8.v v0, (a0)
end;

function RISCVVXorI8x16(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vxor.vv v0, v0, v1
  vse8.v v0, (a0)
end;

// =============================================================
// 256-bit Operations (F32x8, F64x4, I32x8) using LMUL=2
// =============================================================

function RISCVVAddF32x8(const a, b: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma   // LMUL=2 for 256-bit
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vfadd.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVSubF32x8(const a, b: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vfsub.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVMulF32x8(const a, b: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vfmul.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVDivF32x8(const a, b: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vfdiv.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVMinF32x8(const a, b: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vfmin.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVMaxF32x8(const a, b: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vfmax.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVAbsF32x8(const a: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vfabs.v v0, v0
  vse32.v v0, (a0)
end;

function RISCVVSqrtF32x8(const a: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vfsqrt.v v0, v0
  vse32.v v0, (a0)
end;

function RISCVVAddF64x4(const a, b: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vfadd.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVSubF64x4(const a, b: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vfsub.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVMulF64x4(const a, b: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vfmul.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVDivF64x4(const a, b: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vfdiv.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVAddI32x8(const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vadd.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVSubI32x8(const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vsub.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVMulI32x8(const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmul.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVAndI32x8(const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vand.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVOrI32x8(const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vor.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVXorI32x8(const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vxor.vv v0, v0, v2
  vse32.v v0, (a0)
end;

// =============================================================
// 512-bit Operations (F32x16, I32x16) using LMUL=4
// =============================================================

function RISCVVAddF32x16(const a, b: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma  // LMUL=4 for 512-bit
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vfadd.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVSubF32x16(const a, b: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vfsub.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVMulF32x16(const a, b: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vfmul.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVDivF32x16(const a, b: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vfdiv.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVAddI32x16(const a, b: TVecI32x16): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vadd.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVSubI32x16(const a, b: TVecI32x16): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vsub.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVMulI32x16(const a, b: TVecI32x16): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmul.vv v0, v0, v4
  vse32.v v0, (a0)
end;

// =============================================================
// F32x4 舍入操作
// =============================================================

function RISCVVFloorF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  // RVV 没有直接的 floor，使用 fcvt 舍入模式
  // 先转整数（向负无穷舍入），再转回浮点
  vfcvt.x.f.v v1, v0      // 转为有符号整数（舍入到零）
  vfcvt.f.x.v v0, v1      // 转回浮点
  vse32.v v0, (a0)
end;

function RISCVVCeilF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vfcvt.x.f.v v1, v0
  vfcvt.f.x.v v0, v1
  vse32.v v0, (a0)
end;

function RISCVVRoundF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vfcvt.x.f.v v1, v0      // 默认舍入模式（最近偶数）
  vfcvt.f.x.v v0, v1
  vse32.v v0, (a0)
end;

function RISCVVTruncF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vfcvt.rtz.x.f.v v1, v0  // 向零舍入
  vfcvt.f.x.v v0, v1
  vse32.v v0, (a0)
end;

function RISCVVClampF32x4(const a, minVal, maxVal: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)        // a
  vle32.v v1, (a1)        // minVal
  vle32.v v2, (a2)        // maxVal
  vfmax.vv v0, v0, v1     // max(a, minVal)
  vfmin.vv v0, v0, v2     // min(result, maxVal)
  vse32.v v0, (a0)
end;

// =============================================================
// F32x4 规约操作
// =============================================================

function RISCVVReduceAddF32x4(const a: TVecF32x4): Single; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  // 使用向量规约加法
  vmv.s.x v1, zero        // 初始值 0
  vfredusum.vs v1, v0, v1 // 规约加法
  vfmv.f.s fa0, v1        // 结果到浮点寄存器
end;

function RISCVVReduceMinF32x4(const a: TVecF32x4): Single; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vfredmin.vs v1, v0, v0  // 规约最小值
  vfmv.f.s fa0, v1
end;

function RISCVVReduceMaxF32x4(const a: TVecF32x4): Single; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vfredmax.vs v1, v0, v0  // 规约最大值
  vfmv.f.s fa0, v1
end;

function RISCVVReduceAddI32x4(const a: TVecI32x4): LongInt; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vmv.s.x v1, zero
  vredsum.vs v1, v0, v1   // 整数规约加法
  vmv.x.s a0, v1
end;

function RISCVVReduceMinI32x4(const a: TVecI32x4): LongInt; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vredmin.vs v1, v0, v0   // 有符号最小
  vmv.x.s a0, v1
end;

function RISCVVReduceMaxI32x4(const a: TVecI32x4): LongInt; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vredmax.vs v1, v0, v0   // 有符号最大
  vmv.x.s a0, v1
end;

function RISCVVReduceMinU32x4(const a: TVecU32x4): UInt32; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vredminu.vs v1, v0, v0  // 无符号最小
  vmv.x.s a0, v1
end;

function RISCVVReduceMaxU32x4(const a: TVecU32x4): UInt32; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vredmaxu.vs v1, v0, v0  // 无符号最大
  vmv.x.s a0, v1
end;

// =============================================================
// F32x4 Load/Store/Splat/Zero
// =============================================================

function RISCVVLoadF32x4(p: PSingle): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vse32.v v0, (a1)        // a1 = &Result
end;

procedure RISCVVStoreF32x4(p: PSingle; const a: TVecF32x4); assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a1)        // a1 = &a
  vse32.v v0, (a0)        // a0 = p
end;

procedure RISCVVStoreF32x4Aligned(p: PSingle; const a: TVecF32x4); assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a1)
  vse32.v v0, (a0)
end;

procedure RISCVVStoreF32x8(p: PSingle; const a: TVecF32x8); assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a1)
  vse32.v v0, (a0)
end;

procedure RISCVVStoreF32x16(p: PSingle; const a: TVecF32x16); assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a1)
  vse32.v v0, (a0)
end;

procedure RISCVVStoreF64x4(p: PDouble; const a: TVecF64x4); assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a1)
  vse64.v v0, (a0)
end;

procedure RISCVVStoreF64x8(p: PDouble; const a: TVecF64x8); assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a1)
  vse64.v v0, (a0)
end;

procedure RISCVVStoreI64x4(p: PInt64; const a: TVecI64x4); assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a1)
  vse64.v v0, (a0)
end;

function RISCVVSplatF32x4(value: Single): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vfmv.v.f v0, fa0        // 广播 fa0 到所有元素
  vse32.v v0, (a0)        // a0 = &Result
end;

function RISCVVZeroF32x4: TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vmv.v.i v0, 0           // 所有元素置零
  vse32.v v0, (a0)
end;

// =============================================================
// F64x2 舍入操作
// =============================================================

function RISCVVFloorF64x2(const a: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vfcvt.x.f.v v1, v0
  vfcvt.f.x.v v0, v1
  vse64.v v0, (a0)
end;

function RISCVVCeilF64x2(const a: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vfcvt.x.f.v v1, v0
  vfcvt.f.x.v v0, v1
  vse64.v v0, (a0)
end;

function RISCVVRoundF64x2(const a: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vfcvt.x.f.v v1, v0
  vfcvt.f.x.v v0, v1
  vse64.v v0, (a0)
end;

function RISCVVTruncF64x2(const a: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vfcvt.rtz.x.f.v v1, v0
  vfcvt.f.x.v v0, v1
  vse64.v v0, (a0)
end;

function RISCVVClampF64x2(const a, minVal, maxVal: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vle64.v v2, (a2)
  vfmax.vv v0, v0, v1
  vfmin.vv v0, v0, v2
  vse64.v v0, (a0)
end;

// =============================================================
// F64x2 规约操作
// =============================================================

function RISCVVReduceAddF64x2(const a: TVecF64x2): Double; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vmv.s.x v1, zero
  vfredusum.vs v1, v0, v1
  vfmv.f.s fa0, v1
end;

function RISCVVReduceMinF64x2(const a: TVecF64x2): Double; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vfredmin.vs v1, v0, v0
  vfmv.f.s fa0, v1
end;

function RISCVVReduceMaxF64x2(const a: TVecF64x2): Double; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vfredmax.vs v1, v0, v0
  vfmv.f.s fa0, v1
end;

// =============================================================
// F64x2 Load/Store/Splat/Zero
// =============================================================

function RISCVVLoadF64x2(p: PDouble): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vse64.v v0, (a1)
end;

procedure RISCVVStoreF64x2(p: PDouble; const a: TVecF64x2); assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a1)
  vse64.v v0, (a0)
end;

function RISCVVSplatF64x2(value: Double): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vfmv.v.f v0, fa0
  vse64.v v0, (a0)
end;

function RISCVVZeroF64x2: TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vmv.v.i v0, 0
  vse64.v v0, (a0)
end;

// =============================================================
// I32x4 Load/Store/Splat/Zero
// =============================================================

function RISCVVLoadI32x4(p: PLongInt): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vse32.v v0, (a1)
end;

procedure RISCVVStoreI32x4(p: PLongInt; const a: TVecI32x4); assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a1)
  vse32.v v0, (a0)
end;

function RISCVVSplatI32x4(value: LongInt): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vmv.v.x v0, a0          // 广播整数到所有元素
  vse32.v v0, (a1)        // a1 = &Result
end;

function RISCVVZeroI32x4: TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vmv.v.i v0, 0
  vse32.v v0, (a0)
end;

// =============================================================
// I64x2 Load/Store/Splat/Zero
// =============================================================

function RISCVVLoadI64x2(p: PInt64): TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vse64.v v0, (a1)
end;

procedure RISCVVStoreI64x2(p: PInt64; const a: TVecI64x2); assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a1)
  vse64.v v0, (a0)
end;

function RISCVVSplatI64x2(value: Int64): TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vmv.v.x v0, a0
  vse64.v v0, (a1)
end;

function RISCVVZeroI64x2: TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vmv.v.i v0, 0
  vse64.v v0, (a0)
end;

// =============================================================
// U32x4 扩展操作
// =============================================================

function RISCVVAndU32x4(const a, b: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vand.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVOrU32x4(const a, b: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vor.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVXorU32x4(const a, b: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vxor.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVNotU32x4(const a: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vnot.v v0, v0
  vse32.v v0, (a0)
end;

function RISCVVShiftLeftU32x4(const a: TVecU32x4; count: Integer): TVecU32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vsll.vx v0, v0, a1
  vse32.v v0, (a0)
end;

function RISCVVShiftRightU32x4(const a: TVecU32x4; count: Integer): TVecU32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vsrl.vx v0, v0, a1
  vse32.v v0, (a0)
end;

function RISCVVCmpEqU32x4(const a, b: TVecU32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmseq.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpNeU32x4(const a, b: TVecU32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmsne.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpGeU32x4(const a, b: TVecU32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmsltu.vv v0, v0, v1    // a < b
  vmnot.m v0, v0          // NOT -> a >= b
  vmv.x.s a0, v0
end;

// =============================================================
// U64x2 操作
// =============================================================

function RISCVVAddU64x2(const a, b: TVecU64x2): TVecU64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vadd.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVSubU64x2(const a, b: TVecU64x2): TVecU64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vsub.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVAndU64x2(const a, b: TVecU64x2): TVecU64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vand.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVOrU64x2(const a, b: TVecU64x2): TVecU64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vor.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVXorU64x2(const a, b: TVecU64x2): TVecU64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vxor.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVNotU64x2(const a: TVecU64x2): TVecU64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vnot.v v0, v0
  vse64.v v0, (a0)
end;

function RISCVVShiftLeftU64x2(const a: TVecU64x2; count: Integer): TVecU64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vsll.vx v0, v0, a1
  vse64.v v0, (a0)
end;

function RISCVVShiftRightU64x2(const a: TVecU64x2; count: Integer): TVecU64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vsrl.vx v0, v0, a1
  vse64.v v0, (a0)
end;

// =============================================================
// U16x8 操作
// =============================================================

function RISCVVAddU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vadd.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVSubU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vsub.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVMulU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmul.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVMinU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vminu.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVMaxU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmaxu.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVAndU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vand.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVOrU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vor.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVXorU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vxor.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVShiftLeftU16x8(const a: TVecU16x8; count: Integer): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vsll.vx v0, v0, a1
  vse16.v v0, (a0)
end;

function RISCVVShiftRightU16x8(const a: TVecU16x8; count: Integer): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vsrl.vx v0, v0, a1
  vse16.v v0, (a0)
end;

// =============================================================
// U8x16 操作
// =============================================================

function RISCVVAddU8x16(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vadd.vv v0, v0, v1
  vse8.v v0, (a0)
end;

function RISCVVSubU8x16(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vsub.vv v0, v0, v1
  vse8.v v0, (a0)
end;

function RISCVVMinU8x16(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vminu.vv v0, v0, v1
  vse8.v v0, (a0)
end;

function RISCVVMaxU8x16(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmaxu.vv v0, v0, v1
  vse8.v v0, (a0)
end;

function RISCVVAndU8x16(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vand.vv v0, v0, v1
  vse8.v v0, (a0)
end;

function RISCVVOrU8x16(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vor.vv v0, v0, v1
  vse8.v v0, (a0)
end;

function RISCVVXorU8x16(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vxor.vv v0, v0, v1
  vse8.v v0, (a0)
end;

// =============================================================
// I64x2 比较操作
// =============================================================

function RISCVVCmpEqI64x2(const a, b: TVecI64x2): TMask2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vmseq.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLtI64x2(const a, b: TVecI64x2): TMask2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vmslt.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLeI64x2(const a, b: TVecI64x2): TMask2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vmsle.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpGtI64x2(const a, b: TVecI64x2): TMask2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vmsgt.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpNeI64x2(const a, b: TVecI64x2): TMask2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vmsne.vv v0, v0, v1
  vmv.x.s a0, v0
end;

// =============================================================
// F64x2 比较操作
// =============================================================

function RISCVVCmpEqF64x2(const a, b: TVecF64x2): TMask2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vmfeq.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLtF64x2(const a, b: TVecF64x2): TMask2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vmflt.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLeF64x2(const a, b: TVecF64x2): TMask2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vmfle.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpGtF64x2(const a, b: TVecF64x2): TMask2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vmfgt.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpGeF64x2(const a, b: TVecF64x2): TMask2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vmfge.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpNeF64x2(const a, b: TVecF64x2): TMask2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vmfne.vv v0, v0, v1
  vmv.x.s a0, v0
end;

// =============================================================
// Select 操作
// =============================================================

function RISCVVSelectF32x4(const mask: TMask4; const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  // a0 = mask, a1 = &a, a2 = &b, hidden &Result
  vsetivli zero, 4, e32, m1, ta, ma
  vmv.s.x v0, a0          // mask to v0
  vle32.v v1, (a1)        // a
  vle32.v v2, (a2)        // b
  vmerge.vvm v1, v2, v1, v0  // v1 = mask ? a : b
  vse32.v v1, (a3)        // store result
end;

function RISCVVSelectF64x2(const mask: TMask2; const a, b: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vmv.s.x v0, a0
  vle64.v v1, (a1)
  vle64.v v2, (a2)
  vmerge.vvm v1, v2, v1, v0
  vse64.v v1, (a3)
end;

function RISCVVSelectI32x4(const mask: TMask4; const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vmv.s.x v0, a0
  vle32.v v1, (a1)
  vle32.v v2, (a2)
  vmerge.vvm v1, v2, v1, v0
  vse32.v v1, (a3)
end;

function RISCVVSelectI64x2(const mask: TMask2; const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vmv.s.x v0, a0
  vle64.v v1, (a1)
  vle64.v v2, (a2)
  vmerge.vvm v1, v2, v1, v0
  vse64.v v1, (a3)
end;

// =============================================================
// 256-bit FMA 操作
// =============================================================

function RISCVVFmaF32x8(const a, b, c: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vle32.v v4, (a2)
  vfmadd.vv v0, v2, v4
  vse32.v v0, (a0)
end;

function RISCVVMinF64x4(const a, b: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vfmin.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVMaxF64x4(const a, b: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vfmax.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVAbsF64x4(const a: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vfabs.v v0, v0
  vse64.v v0, (a0)
end;

function RISCVVSqrtF64x4(const a: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vfsqrt.v v0, v0
  vse64.v v0, (a0)
end;

function RISCVVMinI32x8(const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmin.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVMaxI32x8(const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmax.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVNotI32x8(const a: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vnot.v v0, v0
  vse32.v v0, (a0)
end;

function RISCVVShiftLeftI32x8(const a: TVecI32x8; count: Integer): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vsll.vx v0, v0, a1
  vse32.v v0, (a0)
end;

function RISCVVShiftRightI32x8(const a: TVecI32x8; count: Integer): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vsrl.vx v0, v0, a1
  vse32.v v0, (a0)
end;

function RISCVVShiftRightArithI32x8(const a: TVecI32x8; count: Integer): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vsra.vx v0, v0, a1
  vse32.v v0, (a0)
end;

// =============================================================
// 512-bit 扩展操作
// =============================================================

function RISCVVMinF32x16(const a, b: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vfmin.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVMaxF32x16(const a, b: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vfmax.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVAbsF32x16(const a: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vfabs.v v0, v0
  vse32.v v0, (a0)
end;

function RISCVVSqrtF32x16(const a: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vfsqrt.v v0, v0
  vse32.v v0, (a0)
end;

function RISCVVAndI32x16(const a, b: TVecI32x16): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vand.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVOrI32x16(const a, b: TVecI32x16): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vor.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVXorI32x16(const a, b: TVecI32x16): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vxor.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVMinI32x16(const a, b: TVecI32x16): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmin.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVMaxI32x16(const a, b: TVecI32x16): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmax.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVShiftLeftI32x16(const a: TVecI32x16; count: Integer): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vsll.vx v0, v0, a1
  vse32.v v0, (a0)
end;

function RISCVVShiftRightI32x16(const a: TVecI32x16; count: Integer): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vsrl.vx v0, v0, a1
  vse32.v v0, (a0)
end;

// =============================================================
// F64x8 (512-bit) 操作
// =============================================================

function RISCVVAddF64x8(const a, b: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vfadd.vv v0, v0, v4
  vse64.v v0, (a0)
end;

function RISCVVSubF64x8(const a, b: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vfsub.vv v0, v0, v4
  vse64.v v0, (a0)
end;

function RISCVVMulF64x8(const a, b: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vfmul.vv v0, v0, v4
  vse64.v v0, (a0)
end;

function RISCVVDivF64x8(const a, b: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vfdiv.vv v0, v0, v4
  vse64.v v0, (a0)
end;

function RISCVVMinF64x8(const a, b: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vfmin.vv v0, v0, v4
  vse64.v v0, (a0)
end;

function RISCVVMaxF64x8(const a, b: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vfmax.vv v0, v0, v4
  vse64.v v0, (a0)
end;

function RISCVVAbsF64x8(const a: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vfabs.v v0, v0
  vse64.v v0, (a0)
end;

function RISCVVSqrtF64x8(const a: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vfsqrt.v v0, v0
  vse64.v v0, (a0)
end;

// =============================================================
// I64x4 操作 (256-bit, 4x Int64)
// =============================================================

function RISCVVAddI64x4(const a, b: TVecI64x4): TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vadd.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVSubI64x4(const a, b: TVecI64x4): TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vsub.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVAndI64x4(const a, b: TVecI64x4): TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vand.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVOrI64x4(const a, b: TVecI64x4): TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vor.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVXorI64x4(const a, b: TVecI64x4): TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vxor.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVNotI64x4(const a: TVecI64x4): TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vnot.v v0, v0
  vse64.v v0, (a0)
end;

function RISCVVAndNotI64x4(const a, b: TVecI64x4): TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vnot.v v0, v0
  vand.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVShiftLeftI64x4(const a: TVecI64x4; count: Integer): TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vsll.vx v0, v0, a1
  vse64.v v0, (a0)
end;

function RISCVVShiftRightI64x4(const a: TVecI64x4; count: Integer): TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vsrl.vx v0, v0, a1
  vse64.v v0, (a0)
end;

function RISCVVShiftRightArithI64x4(const a: TVecI64x4; count: Integer): TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vsra.vx v0, v0, a1
  vse64.v v0, (a0)
end;

function RISCVVCmpEqI64x4(const a, b: TVecI64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmseq.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpLtI64x4(const a, b: TVecI64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmslt.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpLeI64x4(const a, b: TVecI64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmsle.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpGtI64x4(const a, b: TVecI64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmsgt.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpGeI64x4(const a, b: TVecI64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmslt.vv v0, v0, v2
  vmnot.m v0, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpNeI64x4(const a, b: TVecI64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmsne.vv v0, v0, v2
  vmv.x.s a0, v0
end;

// =============================================================
// I64x8 操作 (512-bit, 8x Int64)
// =============================================================

function RISCVVAddI64x8(const a, b: TVecI64x8): TVecI64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vadd.vv v0, v0, v4
  vse64.v v0, (a0)
end;

function RISCVVSubI64x8(const a, b: TVecI64x8): TVecI64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vsub.vv v0, v0, v4
  vse64.v v0, (a0)
end;

function RISCVVAndI64x8(const a, b: TVecI64x8): TVecI64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vand.vv v0, v0, v4
  vse64.v v0, (a0)
end;

function RISCVVOrI64x8(const a, b: TVecI64x8): TVecI64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vor.vv v0, v0, v4
  vse64.v v0, (a0)
end;

function RISCVVXorI64x8(const a, b: TVecI64x8): TVecI64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vxor.vv v0, v0, v4
  vse64.v v0, (a0)
end;

function RISCVVCmpEqI64x8(const a, b: TVecI64x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vmseq.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpLtI64x8(const a, b: TVecI64x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vmslt.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpLeI64x8(const a, b: TVecI64x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vmsle.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpGtI64x8(const a, b: TVecI64x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vmsgt.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpGeI64x8(const a, b: TVecI64x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vmslt.vv v0, v0, v4
  vmnot.m v0, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpNeI64x8(const a, b: TVecI64x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vmsne.vv v0, v0, v4
  vmv.x.s a0, v0
end;

// =============================================================
// U64x4 操作 (256-bit, 4x UInt64)
// =============================================================

function RISCVVAddU64x4(const a, b: TVecU64x4): TVecU64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vadd.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVSubU64x4(const a, b: TVecU64x4): TVecU64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vsub.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVAndU64x4(const a, b: TVecU64x4): TVecU64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vand.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVOrU64x4(const a, b: TVecU64x4): TVecU64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vor.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVXorU64x4(const a, b: TVecU64x4): TVecU64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vxor.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVCmpEqU64x4(const a, b: TVecU64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmseq.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpLtU64x4(const a, b: TVecU64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmsltu.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpLeU64x4(const a, b: TVecU64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmsleu.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpGtU64x4(const a, b: TVecU64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmsgtu.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpGeU64x4(const a, b: TVecU64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmsltu.vv v0, v0, v2
  vmnot.m v0, v0
  vmv.x.s a0, v0
end;

// =============================================================
// U32x8 操作 (256-bit, 8x UInt32)
// =============================================================

function RISCVVAddU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vadd.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVSubU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vsub.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVMulU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmul.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVAndU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vand.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVOrU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vor.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVXorU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vxor.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVMinU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vminu.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVMaxU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmaxu.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVCmpEqU32x8(const a, b: TVecU32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmseq.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpLtU32x8(const a, b: TVecU32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmsltu.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpLeU32x8(const a, b: TVecU32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmsleu.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpGtU32x8(const a, b: TVecU32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmsgtu.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpGeU32x8(const a, b: TVecU32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmsltu.vv v0, v0, v2
  vmnot.m v0, v0
  vmv.x.s a0, v0
end;

// =============================================================
// AndNot 扩展操作
// =============================================================

function RISCVVAndNotI32x8(const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vnot.v v0, v0
  vand.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVAndNotI32x16(const a, b: TVecI32x16): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vnot.v v0, v0
  vand.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVAndNotU32x4(const a, b: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vnot.v v0, v0
  vand.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVAndNotU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vnot.v v0, v0
  vand.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVAndNotI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vnot.v v0, v0
  vand.vv v0, v0, v1
  vse16.v v0, (a0)
end;

// =============================================================
// 256-bit 舍入/Clamp 操作
// =============================================================

function RISCVVFloorF32x8(const a: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vfcvt.x.f.v v2, v0
  vfcvt.f.x.v v0, v2
  vse32.v v0, (a0)
end;

function RISCVVCeilF32x8(const a: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vfcvt.x.f.v v2, v0
  vfcvt.f.x.v v0, v2
  vse32.v v0, (a0)
end;

function RISCVVRoundF32x8(const a: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vfcvt.x.f.v v2, v0
  vfcvt.f.x.v v0, v2
  vse32.v v0, (a0)
end;

function RISCVVTruncF32x8(const a: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vfcvt.rtz.x.f.v v2, v0
  vfcvt.f.x.v v0, v2
  vse32.v v0, (a0)
end;

function RISCVVClampF32x8(const a, minVal, maxVal: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vle32.v v4, (a2)
  vfmax.vv v0, v0, v2
  vfmin.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVFloorF64x4(const a: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vfcvt.x.f.v v2, v0
  vfcvt.f.x.v v0, v2
  vse64.v v0, (a0)
end;

function RISCVVCeilF64x4(const a: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vfcvt.x.f.v v2, v0
  vfcvt.f.x.v v0, v2
  vse64.v v0, (a0)
end;

function RISCVVRoundF64x4(const a: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vfcvt.x.f.v v2, v0
  vfcvt.f.x.v v0, v2
  vse64.v v0, (a0)
end;

function RISCVVTruncF64x4(const a: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vfcvt.rtz.x.f.v v2, v0
  vfcvt.f.x.v v0, v2
  vse64.v v0, (a0)
end;

function RISCVVClampF64x4(const a, minVal, maxVal: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vle64.v v4, (a2)
  vfmax.vv v0, v0, v2
  vfmin.vv v0, v0, v4
  vse64.v v0, (a0)
end;

// =============================================================
// 512-bit 舍入/Clamp 操作
// =============================================================

function RISCVVFloorF32x16(const a: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vfcvt.x.f.v v4, v0
  vfcvt.f.x.v v0, v4
  vse32.v v0, (a0)
end;

function RISCVVCeilF32x16(const a: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vfcvt.x.f.v v4, v0
  vfcvt.f.x.v v0, v4
  vse32.v v0, (a0)
end;

function RISCVVRoundF32x16(const a: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vfcvt.x.f.v v4, v0
  vfcvt.f.x.v v0, v4
  vse32.v v0, (a0)
end;

function RISCVVTruncF32x16(const a: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vfcvt.rtz.x.f.v v4, v0
  vfcvt.f.x.v v0, v4
  vse32.v v0, (a0)
end;

function RISCVVClampF32x16(const a, minVal, maxVal: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vle32.v v8, (a2)
  vfmax.vv v0, v0, v4
  vfmin.vv v0, v0, v8
  vse32.v v0, (a0)
end;

function RISCVVFloorF64x8(const a: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vfcvt.x.f.v v4, v0
  vfcvt.f.x.v v0, v4
  vse64.v v0, (a0)
end;

function RISCVVCeilF64x8(const a: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vfcvt.x.f.v v4, v0
  vfcvt.f.x.v v0, v4
  vse64.v v0, (a0)
end;

function RISCVVRoundF64x8(const a: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vfcvt.x.f.v v4, v0
  vfcvt.f.x.v v0, v4
  vse64.v v0, (a0)
end;

function RISCVVTruncF64x8(const a: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vfcvt.rtz.x.f.v v4, v0
  vfcvt.f.x.v v0, v4
  vse64.v v0, (a0)
end;

function RISCVVClampF64x8(const a, minVal, maxVal: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vle64.v v8, (a2)
  vfmax.vv v0, v0, v4
  vfmin.vv v0, v0, v8
  vse64.v v0, (a0)
end;

// =============================================================
// 256-bit/512-bit 比较操作
// =============================================================

function RISCVVCmpEqF32x8(const a, b: TVecF32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmfeq.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpLtF32x8(const a, b: TVecF32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmflt.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpLeF32x8(const a, b: TVecF32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmfle.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpGtF32x8(const a, b: TVecF32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmfgt.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpGeF32x8(const a, b: TVecF32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmfge.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpNeF32x8(const a, b: TVecF32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmfne.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpEqF64x4(const a, b: TVecF64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmfeq.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpLtF64x4(const a, b: TVecF64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmflt.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpLeF64x4(const a, b: TVecF64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmfle.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpGtF64x4(const a, b: TVecF64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmfgt.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpGeF64x4(const a, b: TVecF64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmfge.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpNeF64x4(const a, b: TVecF64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmfne.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpEqI32x8(const a, b: TVecI32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmseq.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpLtI32x8(const a, b: TVecI32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmslt.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpLeI32x8(const a, b: TVecI32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmsle.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpGtI32x8(const a, b: TVecI32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmsgt.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpGeI32x8(const a, b: TVecI32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmslt.vv v0, v0, v2
  vmnot.m v0, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpNeI32x8(const a, b: TVecI32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmsne.vv v0, v0, v2
  vmv.x.s a0, v0
end;

// =============================================================
// I32x16 比较操作
// =============================================================

function RISCVVCmpEqI32x16(const a, b: TVecI32x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmseq.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpLtI32x16(const a, b: TVecI32x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmslt.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpLeI32x16(const a, b: TVecI32x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmsle.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpGtI32x16(const a, b: TVecI32x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmsgt.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpGeI32x16(const a, b: TVecI32x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmslt.vv v0, v0, v4
  vmnot.m v0, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpNeI32x16(const a, b: TVecI32x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmsne.vv v0, v0, v4
  vmv.x.s a0, v0
end;

// =============================================================
// 窄整数比较操作 I16x8/I8x16
// =============================================================

function RISCVVCmpEqI16x8(const a, b: TVecI16x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmseq.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLtI16x8(const a, b: TVecI16x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmslt.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLeI16x8(const a, b: TVecI16x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmsle.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpGtI16x8(const a, b: TVecI16x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmsgt.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpGeI16x8(const a, b: TVecI16x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmslt.vv v0, v0, v1
  vmnot.m v0, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpNeI16x8(const a, b: TVecI16x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmsne.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpEqI8x16(const a, b: TVecI8x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmseq.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLtI8x16(const a, b: TVecI8x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmslt.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLeI8x16(const a, b: TVecI8x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmsle.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpGtI8x16(const a, b: TVecI8x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmsgt.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpGeI8x16(const a, b: TVecI8x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmslt.vv v0, v0, v1
  vmnot.m v0, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpNeI8x16(const a, b: TVecI8x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmsne.vv v0, v0, v1
  vmv.x.s a0, v0
end;

// =============================================================
// 无符号窄整数比较 U16x8/U8x16
// =============================================================

function RISCVVCmpEqU16x8(const a, b: TVecU16x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmseq.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLtU16x8(const a, b: TVecU16x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmsltu.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLeU16x8(const a, b: TVecU16x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmsleu.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpGtU16x8(const a, b: TVecU16x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmsgtu.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpGeU16x8(const a, b: TVecU16x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmsltu.vv v0, v0, v1
  vmnot.m v0, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpEqU8x16(const a, b: TVecU8x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmseq.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLtU8x16(const a, b: TVecU8x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmsltu.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLeU8x16(const a, b: TVecU8x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmsleu.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpGtU8x16(const a, b: TVecU8x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmsgtu.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpGeU8x16(const a, b: TVecU8x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmsltu.vv v0, v0, v1
  vmnot.m v0, v0
  vmv.x.s a0, v0
end;

// =============================================================
// 512-bit 比较操作
// =============================================================

function RISCVVCmpEqF32x16(const a, b: TVecF32x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmfeq.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpLtF32x16(const a, b: TVecF32x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmflt.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpLeF32x16(const a, b: TVecF32x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmfle.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpGtF32x16(const a, b: TVecF32x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmfgt.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpGeF32x16(const a, b: TVecF32x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmfge.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpNeF32x16(const a, b: TVecF32x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmfne.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpEqF64x8(const a, b: TVecF64x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vmfeq.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpLtF64x8(const a, b: TVecF64x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vmflt.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpLeF64x8(const a, b: TVecF64x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vmfle.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpGtF64x8(const a, b: TVecF64x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vmfgt.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpGeF64x8(const a, b: TVecF64x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vmfge.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpNeF64x8(const a, b: TVecF64x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vmfne.vv v0, v0, v4
  vmv.x.s a0, v0
end;

// =============================================================
// FMA 256-bit/512-bit 操作
// =============================================================

function RISCVVFmaF64x4(const a, b, c: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vle64.v v4, (a2)
  vfmadd.vv v0, v2, v4
  vse64.v v0, (a0)
end;

function RISCVVFmaF32x16(const a, b, c: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vle32.v v8, (a2)
  vfmadd.vv v0, v4, v8
  vse32.v v0, (a0)
end;

function RISCVVFmaF64x8(const a, b, c: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vle64.v v8, (a2)
  vfmadd.vv v0, v4, v8
  vse64.v v0, (a0)
end;

// =============================================================
// Select 256-bit/512-bit 操作
// =============================================================

function RISCVVSelectF32x8(const mask: TMask8; const a, b: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vmv.s.x v0, a0
  vle32.v v2, (a1)
  vle32.v v4, (a2)
  vmerge.vvm v2, v4, v2, v0
  vse32.v v2, (a3)
end;

function RISCVVSelectF64x4(const mask: TMask4; const a, b: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vmv.s.x v0, a0
  vle64.v v2, (a1)
  vle64.v v4, (a2)
  vmerge.vvm v2, v4, v2, v0
  vse64.v v2, (a3)
end;

function RISCVVSelectI32x8(const mask: TMask8; const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vmv.s.x v0, a0
  vle32.v v2, (a1)
  vle32.v v4, (a2)
  vmerge.vvm v2, v4, v2, v0
  vse32.v v2, (a3)
end;

function RISCVVSelectF32x16(const mask: TMask16; const a, b: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vmv.s.x v0, a0
  vle32.v v4, (a1)
  vle32.v v8, (a2)
  vmerge.vvm v4, v8, v4, v0
  vse32.v v4, (a3)
end;

function RISCVVSelectI32x16(const mask: TMask16; const a, b: TVecI32x16): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vmv.s.x v0, a0
  vle32.v v4, (a1)
  vle32.v v8, (a2)
  vmerge.vvm v4, v8, v4, v0
  vse32.v v4, (a3)
end;

function RISCVVSelectF64x8(const mask: TMask8; const a, b: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vmv.s.x v0, a0
  vle64.v v4, (a1)
  vle64.v v8, (a2)
  vmerge.vvm v4, v8, v4, v0
  vse64.v v4, (a3)
end;

// =============================================================
// 256-bit/512-bit Load/Store/Splat/Zero Operations
// =============================================================

function RISCVVLoadF32x8(p: Pointer): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vse32.v v0, (a1)
end;

function RISCVVLoadF32x16(p: Pointer): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vse32.v v0, (a1)
end;

function RISCVVLoadF64x4(p: Pointer): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vse64.v v0, (a1)
end;

function RISCVVLoadF64x8(p: Pointer): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vse64.v v0, (a1)
end;

function RISCVVLoadI64x4(p: Pointer): TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vse64.v v0, (a1)
end;

function RISCVVLoadF32x4Aligned(p: Pointer): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vse32.v v0, (a1)
end;

function RISCVVSplatF32x8(value: Single): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vfmv.v.f v0, fa0
  vse32.v v0, (a0)
end;

function RISCVVSplatF32x16(value: Single): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vfmv.v.f v0, fa0
  vse32.v v0, (a0)
end;

function RISCVVSplatF64x4(value: Double): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vfmv.v.f v0, fa0
  vse64.v v0, (a0)
end;

function RISCVVSplatF64x8(value: Double): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vfmv.v.f v0, fa0
  vse64.v v0, (a0)
end;

function RISCVVSplatI64x4(value: Int64): TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vmv.v.x v0, a0
  vse64.v v0, (a1)
end;

function RISCVVZeroF32x8: TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vmv.v.i v0, 0
  vse32.v v0, (a0)
end;

function RISCVVZeroF32x16: TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vmv.v.i v0, 0
  vse32.v v0, (a0)
end;

function RISCVVZeroF64x4: TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vmv.v.i v0, 0
  vse64.v v0, (a0)
end;

function RISCVVZeroF64x8: TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vmv.v.i v0, 0
  vse64.v v0, (a0)
end;

function RISCVVZeroI64x4: TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vmv.v.i v0, 0
  vse64.v v0, (a0)
end;

// =============================================================
// 256-bit/512-bit Reduction Operations
// =============================================================

function RISCVVReduceAddF32x8(const a: TVecF32x8): Single; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vfmv.s.f v2, fa0            // fa0 = 0.0 initial value
  vfredusum.vs v2, v0, v2
  vfmv.f.s fa0, v2
end;

function RISCVVReduceAddF32x16(const a: TVecF32x16): Single; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vfmv.s.f v4, fa0
  vfredusum.vs v4, v0, v4
  vfmv.f.s fa0, v4
end;

function RISCVVReduceAddF64x4(const a: TVecF64x4): Double; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vfmv.s.f v2, fa0
  vfredusum.vs v2, v0, v2
  vfmv.f.s fa0, v2
end;

function RISCVVReduceAddF64x8(const a: TVecF64x8): Double; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vfmv.s.f v4, fa0
  vfredusum.vs v4, v0, v4
  vfmv.f.s fa0, v4
end;

function RISCVVReduceMinF32x8(const a: TVecF32x8): Single; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vmv.v.x v2, zero
  lui t0, 0x7F800            // +Infinity as initial
  vmv.s.x v2, t0
  vfredmin.vs v2, v0, v2
  vfmv.f.s fa0, v2
end;

function RISCVVReduceMinF32x16(const a: TVecF32x16): Single; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vmv.v.x v4, zero
  lui t0, 0x7F800
  vmv.s.x v4, t0
  vfredmin.vs v4, v0, v4
  vfmv.f.s fa0, v4
end;

function RISCVVReduceMinF64x4(const a: TVecF64x4): Double; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  li t0, 0x7FF0000000000000  // +Infinity
  vmv.v.x v2, zero
  vmv.s.x v2, t0
  vfredmin.vs v2, v0, v2
  vfmv.f.s fa0, v2
end;

function RISCVVReduceMinF64x8(const a: TVecF64x8): Double; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  li t0, 0x7FF0000000000000
  vmv.v.x v4, zero
  vmv.s.x v4, t0
  vfredmin.vs v4, v0, v4
  vfmv.f.s fa0, v4
end;

function RISCVVReduceMaxF32x8(const a: TVecF32x8): Single; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vmv.v.x v2, zero
  lui t0, 0xFF800            // -Infinity as initial
  vmv.s.x v2, t0
  vfredmax.vs v2, v0, v2
  vfmv.f.s fa0, v2
end;

function RISCVVReduceMaxF32x16(const a: TVecF32x16): Single; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vmv.v.x v4, zero
  lui t0, 0xFF800
  vmv.s.x v4, t0
  vfredmax.vs v4, v0, v4
  vfmv.f.s fa0, v4
end;

function RISCVVReduceMaxF64x4(const a: TVecF64x4): Double; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  li t0, 0xFFF0000000000000  // -Infinity
  vmv.v.x v2, zero
  vmv.s.x v2, t0
  vfredmax.vs v2, v0, v2
  vfmv.f.s fa0, v2
end;

function RISCVVReduceMaxF64x8(const a: TVecF64x8): Double; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  li t0, 0xFFF0000000000000
  vmv.v.x v4, zero
  vmv.s.x v4, t0
  vfredmax.vs v4, v0, v4
  vfmv.f.s fa0, v4
end;

// ReduceMul 使用连续乘法实现
function RISCVVReduceMulF32x4(const a: TVecF32x4): Single; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vslidedown.vi v1, v0, 2    // [2,3,x,x]
  vfmul.vv v0, v0, v1        // [0*2, 1*3, x, x]
  vslidedown.vi v1, v0, 1    // [1*3,x,x,x]
  vfmul.vv v0, v0, v1        // [(0*2)*(1*3), ...]
  vfmv.f.s fa0, v0
end;

function RISCVVReduceMulF32x8(const a: TVecF32x8): Single; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vslidedown.vi v2, v0, 4
  vfmul.vv v0, v0, v2
  vsetivli zero, 4, e32, m1, ta, ma
  vslidedown.vi v1, v0, 2
  vfmul.vv v0, v0, v1
  vslidedown.vi v1, v0, 1
  vfmul.vv v0, v0, v1
  vfmv.f.s fa0, v0
end;

function RISCVVReduceMulF32x16(const a: TVecF32x16): Single; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vslidedown.vi v4, v0, 8
  vfmul.vv v0, v0, v4
  vsetivli zero, 8, e32, m2, ta, ma
  vslidedown.vi v2, v0, 4
  vfmul.vv v0, v0, v2
  vsetivli zero, 4, e32, m1, ta, ma
  vslidedown.vi v1, v0, 2
  vfmul.vv v0, v0, v1
  vslidedown.vi v1, v0, 1
  vfmul.vv v0, v0, v1
  vfmv.f.s fa0, v0
end;

function RISCVVReduceMulF64x2(const a: TVecF64x2): Double; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vslidedown.vi v1, v0, 1
  vfmul.vv v0, v0, v1
  vfmv.f.s fa0, v0
end;

function RISCVVReduceMulF64x4(const a: TVecF64x4): Double; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vslidedown.vi v2, v0, 2
  vfmul.vv v0, v0, v2
  vsetivli zero, 2, e64, m1, ta, ma
  vslidedown.vi v1, v0, 1
  vfmul.vv v0, v0, v1
  vfmv.f.s fa0, v0
end;

function RISCVVReduceMulF64x8(const a: TVecF64x8): Double; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vslidedown.vi v4, v0, 4
  vfmul.vv v0, v0, v4
  vsetivli zero, 4, e64, m2, ta, ma
  vslidedown.vi v2, v0, 2
  vfmul.vv v0, v0, v2
  vsetivli zero, 2, e64, m1, ta, ma
  vslidedown.vi v1, v0, 1
  vfmul.vv v0, v0, v1
  vfmv.f.s fa0, v0
end;

// =============================================================
// Bitwise NOT Operations
// =============================================================

function RISCVVNotI16x8(const a: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vnot.v v0, v0
  vse16.v v0, (a1)
end;

function RISCVVNotI8x16(const a: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vnot.v v0, v0
  vse8.v v0, (a1)
end;

function RISCVVNotU16x8(const a: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vnot.v v0, v0
  vse16.v v0, (a1)
end;

function RISCVVNotU8x16(const a: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vnot.v v0, v0
  vse8.v v0, (a1)
end;

function RISCVVNotI32x16(const a: TVecI32x16): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vnot.v v0, v0
  vse32.v v0, (a1)
end;

function RISCVVNotI64x8(const a: TVecI64x8): TVecI64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e64, m4, ta, ma
  vle64.v v0, (a0)
  vnot.v v0, v0
  vse64.v v0, (a1)
end;

function RISCVVNotU32x8(const a: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vnot.v v0, v0
  vse32.v v0, (a1)
end;

function RISCVVNotU64x4(const a: TVecU64x4): TVecU64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vnot.v v0, v0
  vse64.v v0, (a1)
end;

// =============================================================
// Unsigned Shift Operations (256-bit)
// =============================================================

function RISCVVShiftLeftU32x8(const a: TVecU32x8; shift: Integer): TVecU32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vsll.vx v0, v0, a1
  vse32.v v0, (a2)
end;

function RISCVVShiftRightU32x8(const a: TVecU32x8; shift: Integer): TVecU32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vsrl.vx v0, v0, a1
  vse32.v v0, (a2)
end;

function RISCVVShiftLeftU64x4(const a: TVecU64x4; shift: Integer): TVecU64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vsll.vx v0, v0, a1
  vse64.v v0, (a2)
end;

function RISCVVShiftRightU64x4(const a: TVecU64x4; shift: Integer): TVecU64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vsrl.vx v0, v0, a1
  vse64.v v0, (a2)
end;

function RISCVVShiftRightArithI32x16(const a: TVecI32x16; shift: Integer): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vsra.vx v0, v0, a1
  vse32.v v0, (a2)
end;

// =============================================================
// Unsigned Comparison Not Equal
// =============================================================

function RISCVVCmpNeU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmsne.vv v2, v0, v1
  vmv.v.i v0, 0
  vmerge.vim v0, v0, -1, v2
  vse16.v v0, (a2)
end;

function RISCVVCmpNeU8x16(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmsne.vv v2, v0, v1
  vmv.v.i v0, 0
  vmerge.vim v0, v0, -1, v2
  vse8.v v0, (a2)
end;

function RISCVVCmpNeU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmsne.vv v4, v0, v2
  vmv.v.i v0, 0
  vmerge.vim v0, v0, -1, v4
  vse32.v v0, (a2)
end;

function RISCVVCmpNeU64x4(const a, b: TVecU64x4): TVecU64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmsne.vv v4, v0, v2
  vmv.v.i v0, 0
  vmerge.vim v0, v0, -1, v4
  vse64.v v0, (a2)
end;

function RISCVVCmpGeI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vmsle.vv v2, v1, v0       // a >= b <=> b <= a
  vmv.v.i v0, 0
  vmerge.vim v0, v0, -1, v2
  vse64.v v0, (a2)
end;

// =============================================================
// Saturated Arithmetic Operations
// =============================================================

function RISCVVSatAddI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vsadd.vv v0, v0, v1
  vse16.v v0, (a2)
end;

function RISCVVSatAddI8x16(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vsadd.vv v0, v0, v1
  vse8.v v0, (a2)
end;

function RISCVVSatAddU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vsaddu.vv v0, v0, v1
  vse16.v v0, (a2)
end;

function RISCVVSatAddU8x16(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vsaddu.vv v0, v0, v1
  vse8.v v0, (a2)
end;

function RISCVVSatSubI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vssub.vv v0, v0, v1
  vse16.v v0, (a2)
end;

function RISCVVSatSubI8x16(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vssub.vv v0, v0, v1
  vse8.v v0, (a2)
end;

function RISCVVSatSubU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e16, m1, ta, ma
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vssubu.vv v0, v0, v1
  vse16.v v0, (a2)
end;

function RISCVVSatSubU8x16(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e8, m1, ta, ma
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vssubu.vv v0, v0, v1
  vse8.v v0, (a2)
end;

// =============================================================
// Mask Operations
// =============================================================

function RISCVVMask2All(mask: TMask2): Boolean; assembler; nostackframe;
asm
  andi a0, a0, 3
  li t0, 3
  seq a0, a0, t0
end;

function RISCVVMask2Any(mask: TMask2): Boolean; assembler; nostackframe;
asm
  andi a0, a0, 3
  snez a0, a0
end;

function RISCVVMask2None(mask: TMask2): Boolean; assembler; nostackframe;
asm
  andi a0, a0, 3
  seqz a0, a0
end;

function RISCVVMask2PopCount(mask: TMask2): Integer; assembler; nostackframe;
asm
  andi a0, a0, 3
  // popcount for 2 bits
  srli t0, a0, 1
  andi t0, t0, 1
  andi a0, a0, 1
  add a0, a0, t0
end;

function RISCVVMask2FirstSet(mask: TMask2): Integer; assembler; nostackframe;
asm
  andi a0, a0, 3
  beqz a0, .Lnone2
  andi t0, a0, 1
  bnez t0, .Lfound0_2
  li a0, 1
  ret
.Lfound0_2:
  li a0, 0
  ret
.Lnone2:
  li a0, -1
end;

function RISCVVMask4All(mask: TMask4): Boolean; assembler; nostackframe;
asm
  andi a0, a0, 15
  li t0, 15
  seq a0, a0, t0
end;

function RISCVVMask4Any(mask: TMask4): Boolean; assembler; nostackframe;
asm
  andi a0, a0, 15
  snez a0, a0
end;

function RISCVVMask4None(mask: TMask4): Boolean; assembler; nostackframe;
asm
  andi a0, a0, 15
  seqz a0, a0
end;

function RISCVVMask4PopCount(mask: TMask4): Integer; assembler; nostackframe;
asm
  andi a0, a0, 15
  // 4-bit popcount
  srli t0, a0, 1
  andi t0, t0, 5
  sub a0, a0, t0
  srli t0, a0, 2
  andi t0, t0, 3
  andi a0, a0, 3
  add a0, a0, t0
end;

function RISCVVMask4And(a, b: TMask4): TMask4; assembler; nostackframe;
asm
  and a0, a0, a1
  andi a0, a0, 15
end;

function RISCVVMask4Or(a, b: TMask4): TMask4; assembler; nostackframe;
asm
  or a0, a0, a1
  andi a0, a0, 15
end;

function RISCVVMask4Xor(a, b: TMask4): TMask4; assembler; nostackframe;
asm
  xor a0, a0, a1
  andi a0, a0, 15
end;

function RISCVVMask4Not(mask: TMask4): TMask4; assembler; nostackframe;
asm
  not a0, a0
  andi a0, a0, 15
end;

function RISCVVMask4FirstSet(mask: TMask4): Integer; assembler; nostackframe;
asm
  andi a0, a0, 15
  beqz a0, .Lnone4
  // Count trailing zeros
  neg t0, a0
  and t0, a0, t0       // isolate lowest bit
  li a0, 0
  li t1, 1
  beq t0, t1, .Ldone4
  addi a0, a0, 1
  slli t1, t1, 1
  beq t0, t1, .Ldone4
  addi a0, a0, 1
  slli t1, t1, 1
  beq t0, t1, .Ldone4
  li a0, 3
.Ldone4:
  ret
.Lnone4:
  li a0, -1
end;

function RISCVVMask8All(mask: TMask8): Boolean; assembler; nostackframe;
asm
  andi a0, a0, 255
  li t0, 255
  seq a0, a0, t0
end;

function RISCVVMask8Any(mask: TMask8): Boolean; assembler; nostackframe;
asm
  andi a0, a0, 255
  snez a0, a0
end;

function RISCVVMask8None(mask: TMask8): Boolean; assembler; nostackframe;
asm
  andi a0, a0, 255
  seqz a0, a0
end;

function RISCVVMask8PopCount(mask: TMask8): Integer; assembler; nostackframe;
asm
  andi a0, a0, 255
  // 8-bit popcount using parallel reduction
  srli t0, a0, 1
  li t1, 0x55
  and t0, t0, t1
  sub a0, a0, t0
  srli t0, a0, 2
  li t1, 0x33
  and t0, t0, t1
  and a0, a0, t1
  add a0, a0, t0
  srli t0, a0, 4
  add a0, a0, t0
  andi a0, a0, 0x0F
end;

function RISCVVMask8And(a, b: TMask8): TMask8; assembler; nostackframe;
asm
  and a0, a0, a1
  andi a0, a0, 255
end;

function RISCVVMask8Or(a, b: TMask8): TMask8; assembler; nostackframe;
asm
  or a0, a0, a1
  andi a0, a0, 255
end;

function RISCVVMask8Xor(a, b: TMask8): TMask8; assembler; nostackframe;
asm
  xor a0, a0, a1
  andi a0, a0, 255
end;

function RISCVVMask8Not(mask: TMask8): TMask8; assembler; nostackframe;
asm
  not a0, a0
  andi a0, a0, 255
end;

function RISCVVMask8FirstSet(mask: TMask8): Integer; assembler; nostackframe;
asm
  andi a0, a0, 255
  beqz a0, .Lnone8
  // Count trailing zeros using de Bruijn sequence
  neg t0, a0
  and t0, a0, t0
  // Simple loop for 8 bits
  li a0, 0
  li t1, 1
.Lloop8:
  beq t0, t1, .Ldone8
  addi a0, a0, 1
  slli t1, t1, 1
  blt a0, 8, .Lloop8
.Ldone8:
  ret
.Lnone8:
  li a0, -1
end;

function RISCVVMask16All(mask: TMask16): Boolean; assembler; nostackframe;
asm
  li t0, 0xFFFF
  and a0, a0, t0
  seq a0, a0, t0
end;

function RISCVVMask16Any(mask: TMask16): Boolean; assembler; nostackframe;
asm
  li t0, 0xFFFF
  and a0, a0, t0
  snez a0, a0
end;

function RISCVVMask16None(mask: TMask16): Boolean; assembler; nostackframe;
asm
  li t0, 0xFFFF
  and a0, a0, t0
  seqz a0, a0
end;

function RISCVVMask16PopCount(mask: TMask16): Integer; assembler; nostackframe;
asm
  li t0, 0xFFFF
  and a0, a0, t0
  // 16-bit popcount
  srli t0, a0, 1
  li t1, 0x5555
  and t0, t0, t1
  sub a0, a0, t0
  srli t0, a0, 2
  li t1, 0x3333
  and t0, t0, t1
  and a0, a0, t1
  add a0, a0, t0
  srli t0, a0, 4
  add a0, a0, t0
  li t1, 0x0F0F
  and a0, a0, t1
  srli t0, a0, 8
  add a0, a0, t0
  andi a0, a0, 0x1F
end;

function RISCVVMask16And(a, b: TMask16): TMask16; assembler; nostackframe;
asm
  and a0, a0, a1
  li t0, 0xFFFF
  and a0, a0, t0
end;

function RISCVVMask16Or(a, b: TMask16): TMask16; assembler; nostackframe;
asm
  or a0, a0, a1
  li t0, 0xFFFF
  and a0, a0, t0
end;

function RISCVVMask16Xor(a, b: TMask16): TMask16; assembler; nostackframe;
asm
  xor a0, a0, a1
  li t0, 0xFFFF
  and a0, a0, t0
end;

function RISCVVMask16Not(mask: TMask16): TMask16; assembler; nostackframe;
asm
  not a0, a0
  li t0, 0xFFFF
  and a0, a0, t0
end;

function RISCVVMask16FirstSet(mask: TMask16): Integer; assembler; nostackframe;
asm
  li t0, 0xFFFF
  and a0, a0, t0
  beqz a0, .Lnone16
  neg t0, a0
  and t0, a0, t0
  li a0, 0
  li t1, 1
.Lloop16:
  beq t0, t1, .Ldone16
  addi a0, a0, 1
  slli t1, t1, 1
  blt a0, 16, .Lloop16
.Ldone16:
  ret
.Lnone16:
  li a0, -1
end;

// =============================================================
// Extract/Insert Operations
// =============================================================

function RISCVVExtractF32x4(const a: TVecF32x4; index: Integer): Single; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vslidedown.vx v0, v0, a1
  vfmv.f.s fa0, v0
end;

function RISCVVExtractF32x8(const a: TVecF32x8; index: Integer): Single; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vslidedown.vx v0, v0, a1
  vfmv.f.s fa0, v0
end;

function RISCVVExtractF32x16(const a: TVecF32x16; index: Integer): Single; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vslidedown.vx v0, v0, a1
  vfmv.f.s fa0, v0
end;

function RISCVVExtractF64x2(const a: TVecF64x2; index: Integer): Double; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vslidedown.vx v0, v0, a1
  vfmv.f.s fa0, v0
end;

function RISCVVExtractF64x4(const a: TVecF64x4; index: Integer): Double; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vslidedown.vx v0, v0, a1
  vfmv.f.s fa0, v0
end;

function RISCVVExtractI32x4(const a: TVecI32x4; index: Integer): Int32; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vslidedown.vx v0, v0, a1
  vmv.x.s a0, v0
end;

function RISCVVExtractI32x8(const a: TVecI32x8; index: Integer): Int32; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vslidedown.vx v0, v0, a1
  vmv.x.s a0, v0
end;

function RISCVVExtractI32x16(const a: TVecI32x16; index: Integer): Int32; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vslidedown.vx v0, v0, a1
  vmv.x.s a0, v0
end;

function RISCVVExtractI64x2(const a: TVecI64x2; index: Integer): Int64; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vslidedown.vx v0, v0, a1
  vmv.x.s a0, v0
end;

function RISCVVExtractI64x4(const a: TVecI64x4; index: Integer): Int64; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vslidedown.vx v0, v0, a1
  vmv.x.s a0, v0
end;

function RISCVVInsertF32x4(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vfmv.s.f v1, fa0
  vslideup.vx v0, v1, a1
  vse32.v v0, (a2)
end;

function RISCVVInsertF32x8(const a: TVecF32x8; value: Single; index: Integer): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vfmv.s.f v2, fa0
  vslideup.vx v0, v2, a1
  vse32.v v0, (a2)
end;

function RISCVVInsertF32x16(const a: TVecF32x16; value: Single; index: Integer): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vfmv.s.f v4, fa0
  vslideup.vx v0, v4, a1
  vse32.v v0, (a2)
end;

function RISCVVInsertF64x2(const a: TVecF64x2; value: Double; index: Integer): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vfmv.s.f v1, fa0
  vslideup.vx v0, v1, a1
  vse64.v v0, (a2)
end;

function RISCVVInsertF64x4(const a: TVecF64x4; value: Double; index: Integer): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vfmv.s.f v2, fa0
  vslideup.vx v0, v2, a1
  vse64.v v0, (a2)
end;

function RISCVVInsertI32x4(const a: TVecI32x4; value: Int32; index: Integer): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vmv.s.x v1, a1
  vslideup.vx v0, v1, a2
  vse32.v v0, (a3)
end;

function RISCVVInsertI32x8(const a: TVecI32x8; value: Int32; index: Integer): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, e32, m2, ta, ma
  vle32.v v0, (a0)
  vmv.s.x v2, a1
  vslideup.vx v0, v2, a2
  vse32.v v0, (a3)
end;

function RISCVVInsertI32x16(const a: TVecI32x16; value: Int32; index: Integer): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, e32, m4, ta, ma
  vle32.v v0, (a0)
  vmv.s.x v4, a1
  vslideup.vx v0, v4, a2
  vse32.v v0, (a3)
end;

function RISCVVInsertI64x2(const a: TVecI64x2; value: Int64; index: Integer): TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, e64, m1, ta, ma
  vle64.v v0, (a0)
  vmv.s.x v1, a1
  vslideup.vx v0, v1, a2
  vse64.v v0, (a3)
end;

function RISCVVInsertI64x4(const a: TVecI64x4; value: Int64; index: Integer): TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  vle64.v v0, (a0)
  vmv.s.x v2, a1
  vslideup.vx v0, v2, a2
  vse64.v v0, (a3)
end;

// =============================================================
// Vector Math Operations (Dot, Cross, Length, Normalize)
// =============================================================

function RISCVVDotF32x3(const a, b: TVecF32x4): Single; assembler; nostackframe;
asm
  vsetivli zero, 3, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vfmul.vv v0, v0, v1
  vfmv.s.f v2, fa0         // zero initial
  vfredusum.vs v2, v0, v2
  vfmv.f.s fa0, v2
end;

function RISCVVDotF32x4(const a, b: TVecF32x4): Single; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vfmul.vv v0, v0, v1
  vfmv.s.f v2, fa0
  vfredusum.vs v2, v0, v2
  vfmv.f.s fa0, v2
end;

function RISCVVCrossF32x3(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  // cross(a,b) = (a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x, 0)
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)          // a = [ax, ay, az, aw]
  vle32.v v1, (a1)          // b = [bx, by, bz, bw]

  // Create shuffled vectors for cross product
  // a_yzx = [ay, az, ax, aw]
  vslidedown.vi v2, v0, 1   // [ay, az, aw, 0]
  vslideup.vi v3, v0, 2     // [0, 0, ax, ay]
  vsetivli zero, 3, e32, m1, ta, ma
  vslidedown.vi v4, v2, 2   // temp
  vslideup.vi v2, v4, 2     // rotate

  // b_yzx = [by, bz, bx, bw]
  vslidedown.vi v4, v1, 1
  vsetivli zero, 3, e32, m1, ta, ma
  vslidedown.vi v5, v4, 2
  vslideup.vi v4, v5, 2

  // a_zxy = [az, ax, ay, aw]
  vslidedown.vi v3, v0, 2
  vsetivli zero, 3, e32, m1, ta, ma
  vslidedown.vi v5, v3, 1
  vslideup.vi v3, v5, 2

  // b_zxy = [bz, bx, by, bw]
  vslidedown.vi v5, v1, 2
  vsetivli zero, 3, e32, m1, ta, ma
  vslidedown.vi v6, v5, 1
  vslideup.vi v5, v6, 2

  vsetivli zero, 4, e32, m1, ta, ma
  // result = a_yzx * b_zxy - a_zxy * b_yzx
  vfmul.vv v6, v2, v5       // a_yzx * b_zxy
  vfmul.vv v7, v3, v4       // a_zxy * b_yzx
  vfsub.vv v0, v6, v7

  // Set w component to 0
  vmv.v.i v1, 0
  vslideup.vi v0, v1, 3

  vse32.v v0, (a2)
end;

function RISCVVLengthF32x3(const a: TVecF32x4): Single; assembler; nostackframe;
asm
  vsetivli zero, 3, e32, m1, ta, ma
  vle32.v v0, (a0)
  vfmul.vv v0, v0, v0       // square each component
  vfmv.s.f v1, fa0
  vfredusum.vs v1, v0, v1   // sum of squares
  vfmv.f.s fa0, v1
  fsqrt.s fa0, fa0          // sqrt
end;

function RISCVVLengthF32x4(const a: TVecF32x4): Single; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vfmul.vv v0, v0, v0
  vfmv.s.f v1, fa0
  vfredusum.vs v1, v0, v1
  vfmv.f.s fa0, v1
  fsqrt.s fa0, fa0
end;

function RISCVVNormalizeF32x3(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 3, e32, m1, ta, ma
  vle32.v v0, (a0)
  vfmul.vv v1, v0, v0
  vfmv.s.f v2, fa0
  vfredusum.vs v2, v1, v2
  vfmv.f.s ft0, v2
  fsqrt.s ft0, ft0
  // Check for zero length
  lui t0, 0x00000           // small epsilon
  fmv.w.x ft1, t0
  flt.s t1, ft0, ft1
  bnez t1, .Lzero_norm3
  // Divide by length
  vsetivli zero, 4, e32, m1, ta, ma
  vfmv.v.f v1, ft0
  vfdiv.vv v0, v0, v1
  // Set w to 0
  vmv.v.i v1, 0
  vslideup.vi v0, v1, 3
  vse32.v v0, (a1)
  ret
.Lzero_norm3:
  vmv.v.i v0, 0
  vse32.v v0, (a1)
end;

function RISCVVNormalizeF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e32, m1, ta, ma
  vle32.v v0, (a0)
  vfmul.vv v1, v0, v0
  vfmv.s.f v2, fa0
  vfredusum.vs v2, v1, v2
  vfmv.f.s ft0, v2
  fsqrt.s ft0, ft0
  lui t0, 0x00000
  fmv.w.x ft1, t0
  flt.s t1, ft0, ft1
  bnez t1, .Lzero_norm4
  vfmv.v.f v1, ft0
  vfdiv.vv v0, v0, v1
  vse32.v v0, (a1)
  ret
.Lzero_norm4:
  vmv.v.i v0, 0
  vse32.v v0, (a1)
end;

function RISCVVRcpF64x4(const a: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, e64, m2, ta, ma
  // Load 1.0 as double
  li t0, 0x3FF0000000000000
  fmv.d.x ft0, t0
  vfmv.v.f v0, ft0
  vle64.v v2, (a0)
  vfdiv.vv v0, v0, v2
  vse64.v v0, (a1)
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

function RISCVVCmpLeI32x4(const a, b: TVecI32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.i[i] <= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeI32x4(const a, b: TVecI32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.i[i] >= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeI32x4(const a, b: TVecI32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.i[i] <> b.i[i] then
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
var
  idx: Integer;
begin
  if index < 0 then
    idx := 0
  else if index > 3 then
    idx := 3
  else
    idx := index;

  Result := a.f[idx];
end;

function RISCVVInsertF32x4(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4;
var
  idx: Integer;
begin
  if index < 0 then
    idx := 0
  else if index > 3 then
    idx := 3
  else
    idx := index;

  Result := a;
  Result.f[idx] := value;
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

function RISCVVCmpLeI32x8(const a, b: TVecI32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] <= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeI32x8(const a, b: TVecI32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] >= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeI32x8(const a, b: TVecI32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] <> b.i[i] then
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

function RISCVVCmpLeI32x16(const a, b: TVecI32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.i[i] <= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeI32x16(const a, b: TVecI32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.i[i] >= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeI32x16(const a, b: TVecI32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.i[i] <> b.i[i] then
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
// F32x8 Comparison Operations (256-bit, 8x Single)
// =============================================================

function RISCVVCmpEqF32x8(const a, b: TVecF32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.f[i] = b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtF32x8(const a, b: TVecF32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.f[i] < b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeF32x8(const a, b: TVecF32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.f[i] <= b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtF32x8(const a, b: TVecF32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.f[i] > b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeF32x8(const a, b: TVecF32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.f[i] >= b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeF32x8(const a, b: TVecF32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.f[i] <> b.f[i] then
      Result := Result or (1 shl i);
end;

// =============================================================
// F64x4 Comparison Operations (256-bit, 4x Double)
// =============================================================

function RISCVVCmpEqF64x4(const a, b: TVecF64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.d[i] = b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtF64x4(const a, b: TVecF64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.d[i] < b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeF64x4(const a, b: TVecF64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.d[i] <= b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtF64x4(const a, b: TVecF64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.d[i] > b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeF64x4(const a, b: TVecF64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.d[i] >= b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeF64x4(const a, b: TVecF64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.d[i] <> b.d[i] then
      Result := Result or (1 shl i);
end;

// =============================================================
// F64x8 Comparison Operations (512-bit, 8x Double)
// =============================================================

function RISCVVCmpEqF64x8(const a, b: TVecF64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.d[i] = b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtF64x8(const a, b: TVecF64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.d[i] < b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeF64x8(const a, b: TVecF64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.d[i] <= b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtF64x8(const a, b: TVecF64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.d[i] > b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeF64x8(const a, b: TVecF64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.d[i] >= b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeF64x8(const a, b: TVecF64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.d[i] <> b.d[i] then
      Result := Result or (1 shl i);
end;

// =============================================================
// F32x16 Comparison Operations (512-bit, 16x Single)
// =============================================================

function RISCVVCmpEqF32x16(const a, b: TVecF32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.f[i] = b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtF32x16(const a, b: TVecF32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.f[i] < b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeF32x16(const a, b: TVecF32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.f[i] <= b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtF32x16(const a, b: TVecF32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.f[i] > b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeF32x16(const a, b: TVecF32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.f[i] >= b.f[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeF32x16(const a, b: TVecF32x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.f[i] <> b.f[i] then
      Result := Result or (1 shl i);
end;

// =============================================================
// TMask4 Operations (4 有效位)
// =============================================================

function RISCVVMask4All(mask: TMask4): Boolean;
begin
  Result := (mask and $0F) = $0F;
end;

function RISCVVMask4Any(mask: TMask4): Boolean;
begin
  Result := (mask and $0F) <> 0;
end;

function RISCVVMask4None(mask: TMask4): Boolean;
begin
  Result := (mask and $0F) = 0;
end;

function RISCVVMask4PopCount(mask: TMask4): Integer;
var
  m: Byte;
begin
  m := mask and $0F;
  Result := 0;
  while m <> 0 do
  begin
    Inc(Result, m and 1);
    m := m shr 1;
  end;
end;

function RISCVVMask4FirstSet(mask: TMask4): Integer;
var
  m: Byte;
  i: Integer;
begin
  m := mask and $0F;
  if m = 0 then
  begin
    Result := -1;
    Exit;
  end;
  for i := 0 to 3 do
  begin
    if (m and (1 shl i)) <> 0 then
    begin
      Result := i;
      Exit;
    end;
  end;
  Result := -1;
end;

// =============================================================
// TMask8 Operations (8 有效位)
// =============================================================

function RISCVVMask8All(mask: TMask8): Boolean;
begin
  Result := mask = $FF;
end;

function RISCVVMask8Any(mask: TMask8): Boolean;
begin
  Result := mask <> 0;
end;

function RISCVVMask8None(mask: TMask8): Boolean;
begin
  Result := mask = 0;
end;

function RISCVVMask8PopCount(mask: TMask8): Integer;
var
  m: Byte;
begin
  m := mask;
  Result := 0;
  while m <> 0 do
  begin
    Inc(Result, m and 1);
    m := m shr 1;
  end;
end;

function RISCVVMask8FirstSet(mask: TMask8): Integer;
var
  m: Byte;
  i: Integer;
begin
  m := mask;
  if m = 0 then
  begin
    Result := -1;
    Exit;
  end;
  for i := 0 to 7 do
  begin
    if (m and (1 shl i)) <> 0 then
    begin
      Result := i;
      Exit;
    end;
  end;
  Result := -1;
end;

// =============================================================
// TMask16 Operations (16 有效位)
// =============================================================

function RISCVVMask16All(mask: TMask16): Boolean;
begin
  Result := mask = $FFFF;
end;

function RISCVVMask16Any(mask: TMask16): Boolean;
begin
  Result := mask <> 0;
end;

function RISCVVMask16None(mask: TMask16): Boolean;
begin
  Result := mask = 0;
end;

function RISCVVMask16PopCount(mask: TMask16): Integer;
var
  m: Word;
begin
  m := mask;
  Result := 0;
  while m <> 0 do
  begin
    Inc(Result, m and 1);
    m := m shr 1;
  end;
end;

function RISCVVMask16FirstSet(mask: TMask16): Integer;
var
  m: Word;
  i: Integer;
begin
  m := mask;
  if m = 0 then
  begin
    Result := -1;
    Exit;
  end;
  for i := 0 to 15 do
  begin
    if (m and (1 shl i)) <> 0 then
    begin
      Result := i;
      Exit;
    end;
  end;
  Result := -1;
end;

// =============================================================
// Mask Logical Operations (TMask4)
// =============================================================

function RISCVVMask4And(a, b: TMask4): TMask4;
begin
  Result := (a and b) and $0F;
end;

function RISCVVMask4Or(a, b: TMask4): TMask4;
begin
  Result := (a or b) and $0F;
end;

function RISCVVMask4Xor(a, b: TMask4): TMask4;
begin
  Result := (a xor b) and $0F;
end;

function RISCVVMask4Not(a: TMask4): TMask4;
begin
  Result := (not a) and $0F;
end;

// =============================================================
// Mask Logical Operations (TMask8)
// =============================================================

function RISCVVMask8And(a, b: TMask8): TMask8;
begin
  Result := a and b;
end;

function RISCVVMask8Or(a, b: TMask8): TMask8;
begin
  Result := a or b;
end;

function RISCVVMask8Xor(a, b: TMask8): TMask8;
begin
  Result := a xor b;
end;

function RISCVVMask8Not(a: TMask8): TMask8;
begin
  Result := not a;
end;

// =============================================================
// Mask Logical Operations (TMask16)
// =============================================================

function RISCVVMask16And(a, b: TMask16): TMask16;
begin
  Result := a and b;
end;

function RISCVVMask16Or(a, b: TMask16): TMask16;
begin
  Result := a or b;
end;

function RISCVVMask16Xor(a, b: TMask16): TMask16;
begin
  Result := a xor b;
end;

function RISCVVMask16Not(a: TMask16): TMask16;
begin
  Result := not a;
end;

// =============================================================
// F32x8 Select Operation
// =============================================================

function RISCVVSelectF32x8(const mask: TMask8; const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if (mask and (1 shl i)) <> 0 then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

// =============================================================
// F64x4 Select Operation
// =============================================================

function RISCVVSelectF64x4(const mask: TMask4; const a, b: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if (mask and (1 shl i)) <> 0 then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
end;

// =============================================================
// F32x16 Select Operation
// =============================================================

function RISCVVSelectF32x16(const mask: TMask16; const a, b: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if (mask and (1 shl i)) <> 0 then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

// =============================================================
// F64x8 Select Operation
// =============================================================

function RISCVVSelectF64x8(const mask: TMask8; const a, b: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if (mask and (1 shl i)) <> 0 then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
end;

// =============================================================
// Additional Operations for 100% Coverage
// =============================================================
// Generated implementations for missing operations
// =============================================================

function RISCVVMask2All(mask: TMask2): Boolean;
begin
  Result := (mask and $03) = $03;
end;

function RISCVVMask2Any(mask: TMask2): Boolean;
begin
  Result := (mask and $03) <> 0;
end;

function RISCVVMask2None(mask: TMask2): Boolean;
begin
  Result := (mask and $03) = 0;
end;

function RISCVVMask2PopCount(mask: TMask2): Integer;
var m: Byte;
begin
  m := mask and $03;
  Result := (m and 1) + ((m shr 1) and 1);
end;

function RISCVVMask2FirstSet(mask: TMask2): Integer;
var m: Byte;
begin
  m := mask and $03;
  if m = 0 then Result := -1
  else if (m and 1) <> 0 then Result := 0
  else Result := 1;
end;

function RISCVVAbsF32x16(const a: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := Abs(a.f[i]);
end;

function RISCVVAbsF32x8(const a: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := Abs(a.f[i]);
end;

function RISCVVAbsF64x2(const a: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := Abs(a.d[i]);
end;

function RISCVVAbsF64x4(const a: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := Abs(a.d[i]);
end;

function RISCVVAbsF64x8(const a: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := Abs(a.d[i]);
end;

function RISCVVAddI16x8(const a, b: TVecI16x8): TVecI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] + b.i[i];
end;

function RISCVVAddI64x4(const a, b: TVecI64x4): TVecI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] + b.i[i];
end;

function RISCVVAddI64x8(const a, b: TVecI64x8): TVecI64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] + b.i[i];
end;

function RISCVVAddI8x16(const a, b: TVecI8x16): TVecI8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := a.i[i] + b.i[i];
end;

function RISCVVAddU16x8(const a, b: TVecU16x8): TVecU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] + b.u[i];
end;

function RISCVVAddU32x4(const a, b: TVecU32x4): TVecU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] + b.u[i];
end;

function RISCVVAddU64x4(const a, b: TVecU64x4): TVecU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] + b.u[i];
end;

// ✅ U32x8 Operations (256-bit)
function RISCVVAddU32x8(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] + b.u[i];
end;

function RISCVVSubU32x8(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] - b.u[i];
end;

function RISCVVMulU32x8(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] * b.u[i];
end;

function RISCVVAndU32x8(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] and b.u[i];
end;

function RISCVVOrU32x8(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] or b.u[i];
end;

function RISCVVXorU32x8(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] xor b.u[i];
end;

function RISCVVNotU32x8(const a: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := not a.u[i];
end;

function RISCVVAndNotU32x8(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := (not a.u[i]) and b.u[i];
end;

function RISCVVShiftLeftU32x8(const a: TVecU32x8; count: Integer): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] shl count;
end;

function RISCVVShiftRightU32x8(const a: TVecU32x8; count: Integer): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] shr count;
end;

function RISCVVCmpEqU32x8(const a, b: TVecU32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] = b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtU32x8(const a, b: TVecU32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] < b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeU32x8(const a, b: TVecU32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] <= b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtU32x8(const a, b: TVecU32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] > b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeU32x8(const a, b: TVecU32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] >= b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeU32x8(const a, b: TVecU32x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] <> b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVMinU32x8(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.u[i] < b.u[i] then
      Result.u[i] := a.u[i]
    else
      Result.u[i] := b.u[i];
end;

function RISCVVMaxU32x8(const a, b: TVecU32x8): TVecU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.u[i] > b.u[i] then
      Result.u[i] := a.u[i]
    else
      Result.u[i] := b.u[i];
end;

// ✅ RcpF64x4 (Reciprocal)
function RISCVVRcpF64x4(const a: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if a.d[i] <> 0.0 then
      Result.d[i] := 1.0 / a.d[i]
    else
      Result.d[i] := 0.0;
end;

function RISCVVAddU8x16(const a, b: TVecU8x16): TVecU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.u[i] := a.u[i] + b.u[i];
end;

function RISCVVAndI16x8(const a, b: TVecI16x8): TVecI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] and b.i[i];
end;

function RISCVVAndI64x4(const a, b: TVecI64x4): TVecI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] and b.i[i];
end;

function RISCVVAndI64x8(const a, b: TVecI64x8): TVecI64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] and b.i[i];
end;

function RISCVVAndI8x16(const a, b: TVecI8x16): TVecI8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := a.i[i] and b.i[i];
end;

function RISCVVAndNotI16x8(const a, b: TVecI16x8): TVecI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := (not a.i[i]) and b.i[i];
end;

function RISCVVAndNotI64x4(const a, b: TVecI64x4): TVecI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := (not a.i[i]) and b.i[i];
end;

function RISCVVAndNotU32x4(const a, b: TVecU32x4): TVecU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := (not a.u[i]) and b.u[i];
end;

function RISCVVAndU16x8(const a, b: TVecU16x8): TVecU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] and b.u[i];
end;

function RISCVVAndU32x4(const a, b: TVecU32x4): TVecU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] and b.u[i];
end;

function RISCVVAndU64x4(const a, b: TVecU64x4): TVecU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] and b.u[i];
end;

function RISCVVAndU8x16(const a, b: TVecU8x16): TVecU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.u[i] := a.u[i] and b.u[i];
end;

function RISCVVCeilF32x16(const a: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := Ceil(a.f[i]);
end;

function RISCVVCeilF32x8(const a: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := Ceil(a.f[i]);
end;

function RISCVVCeilF64x2(const a: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := Ceil(a.d[i]);
end;

function RISCVVCeilF64x4(const a: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := Ceil(a.d[i]);
end;

function RISCVVCeilF64x8(const a: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := Ceil(a.d[i]);
end;

function RISCVVClampF32x16(const a, minVal, maxVal: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
  begin
    if a.f[i] < minVal.f[i] then
      Result.f[i] := minVal.f[i]
    else if a.f[i] > maxVal.f[i] then
      Result.f[i] := maxVal.f[i]
    else
      Result.f[i] := a.f[i];
  end;
end;

function RISCVVClampF32x8(const a, minVal, maxVal: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
  begin
    if a.f[i] < minVal.f[i] then
      Result.f[i] := minVal.f[i]
    else if a.f[i] > maxVal.f[i] then
      Result.f[i] := maxVal.f[i]
    else
      Result.f[i] := a.f[i];
  end;
end;

function RISCVVClampF64x2(const a, minVal, maxVal: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
  begin
    if a.d[i] < minVal.d[i] then
      Result.d[i] := minVal.d[i]
    else if a.d[i] > maxVal.d[i] then
      Result.d[i] := maxVal.d[i]
    else
      Result.d[i] := a.d[i];
  end;
end;

function RISCVVClampF64x4(const a, minVal, maxVal: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
  begin
    if a.d[i] < minVal.d[i] then
      Result.d[i] := minVal.d[i]
    else if a.d[i] > maxVal.d[i] then
      Result.d[i] := maxVal.d[i]
    else
      Result.d[i] := a.d[i];
  end;
end;

function RISCVVClampF64x8(const a, minVal, maxVal: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
  begin
    if a.d[i] < minVal.d[i] then
      Result.d[i] := minVal.d[i]
    else if a.d[i] > maxVal.d[i] then
      Result.d[i] := maxVal.d[i]
    else
      Result.d[i] := a.d[i];
  end;
end;

function RISCVVCmpEqF64x2(const a, b: TVecF64x2): TMask2;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    if a.d[i] = b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpEqI16x8(const a, b: TVecI16x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] = b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpEqI64x2(const a, b: TVecI64x2): TMask2;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    if a.i[i] = b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpEqI64x4(const a, b: TVecI64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.i[i] = b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpEqI64x8(const a, b: TVecI64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] = b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpEqI8x16(const a, b: TVecI8x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.i[i] = b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpEqU16x8(const a, b: TVecU16x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] = b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpEqU32x4(const a, b: TVecU32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.u[i] = b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpEqU64x4(const a, b: TVecU64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.u[i] = b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpEqU8x16(const a, b: TVecU8x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.u[i] = b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeF64x2(const a, b: TVecF64x2): TMask2;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    if a.d[i] >= b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeI16x8(const a, b: TVecI16x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] >= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeI64x2(const a, b: TVecI64x2): TMask2;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    if a.i[i] >= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeI64x4(const a, b: TVecI64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.i[i] >= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeI64x8(const a, b: TVecI64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] >= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeI8x16(const a, b: TVecI8x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.i[i] >= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeU16x8(const a, b: TVecU16x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] >= b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeU32x4(const a, b: TVecU32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.u[i] >= b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeU64x4(const a, b: TVecU64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.u[i] >= b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGeU8x16(const a, b: TVecU8x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.u[i] >= b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtF64x2(const a, b: TVecF64x2): TMask2;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    if a.d[i] > b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtI16x8(const a, b: TVecI16x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] > b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtI64x2(const a, b: TVecI64x2): TMask2;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    if a.i[i] > b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtI64x4(const a, b: TVecI64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.i[i] > b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtI64x8(const a, b: TVecI64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] > b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtI8x16(const a, b: TVecI8x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.i[i] > b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtU16x8(const a, b: TVecU16x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] > b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtU32x4(const a, b: TVecU32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.u[i] > b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtU64x4(const a, b: TVecU64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.u[i] > b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpGtU8x16(const a, b: TVecU8x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.u[i] > b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeF64x2(const a, b: TVecF64x2): TMask2;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    if a.d[i] <= b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeI16x8(const a, b: TVecI16x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] <= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeI64x2(const a, b: TVecI64x2): TMask2;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    if a.i[i] <= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeI64x4(const a, b: TVecI64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.i[i] <= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeI64x8(const a, b: TVecI64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] <= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeI8x16(const a, b: TVecI8x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.i[i] <= b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeU16x8(const a, b: TVecU16x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] <= b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeU32x4(const a, b: TVecU32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.u[i] <= b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeU64x4(const a, b: TVecU64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.u[i] <= b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLeU8x16(const a, b: TVecU8x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.u[i] <= b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtF64x2(const a, b: TVecF64x2): TMask2;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    if a.d[i] < b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtI16x8(const a, b: TVecI16x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] < b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtI64x2(const a, b: TVecI64x2): TMask2;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    if a.i[i] < b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtI64x4(const a, b: TVecI64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.i[i] < b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtI64x8(const a, b: TVecI64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] < b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtI8x16(const a, b: TVecI8x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.i[i] < b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtU16x8(const a, b: TVecU16x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] < b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtU32x4(const a, b: TVecU32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.u[i] < b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtU64x4(const a, b: TVecU64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.u[i] < b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpLtU8x16(const a, b: TVecU8x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.u[i] < b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeF64x2(const a, b: TVecF64x2): TMask2;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    if a.d[i] <> b.d[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeI16x8(const a, b: TVecI16x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] <> b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeI64x2(const a, b: TVecI64x2): TMask2;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    if a.i[i] <> b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeI64x4(const a, b: TVecI64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.i[i] <> b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeI64x8(const a, b: TVecI64x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.i[i] <> b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeI8x16(const a, b: TVecI8x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.i[i] <> b.i[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeU16x8(const a, b: TVecU16x8): TMask8;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    if a.u[i] <> b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeU64x4(const a, b: TVecU64x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.u[i] <> b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVCmpNeU8x16(const a, b: TVecU8x16): TMask16;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    if a.u[i] <> b.u[i] then
      Result := Result or (1 shl i);
end;

function RISCVVExtractF32x16(const a: TVecF32x16; index: Integer): Single;
begin
  if index < 0 then index := 0
  else if index > 15 then index := 15;
  Result := a.f[index];
end;

function RISCVVExtractF32x8(const a: TVecF32x8; index: Integer): Single;
begin
  if index < 0 then index := 0
  else if index > 7 then index := 7;
  Result := a.f[index];
end;

function RISCVVExtractF64x2(const a: TVecF64x2; index: Integer): Double;
begin
  if index < 0 then index := 0
  else if index > 1 then index := 1;
  Result := a.d[index];
end;

function RISCVVExtractF64x4(const a: TVecF64x4; index: Integer): Double;
begin
  if index < 0 then index := 0
  else if index > 3 then index := 3;
  Result := a.d[index];
end;

function RISCVVExtractI32x16(const a: TVecI32x16; index: Integer): Int32;
begin
  if index < 0 then index := 0
  else if index > 15 then index := 15;
  Result := a.i[index];
end;

function RISCVVExtractI32x4(const a: TVecI32x4; index: Integer): Int32;
begin
  if index < 0 then index := 0
  else if index > 3 then index := 3;
  Result := a.i[index];
end;

function RISCVVExtractI32x8(const a: TVecI32x8; index: Integer): Int32;
begin
  if index < 0 then index := 0
  else if index > 7 then index := 7;
  Result := a.i[index];
end;

function RISCVVExtractI64x2(const a: TVecI64x2; index: Integer): Int64;
begin
  if index < 0 then index := 0
  else if index > 1 then index := 1;
  Result := a.i[index];
end;

function RISCVVExtractI64x4(const a: TVecI64x4; index: Integer): Int64;
begin
  if index < 0 then index := 0
  else if index > 3 then index := 3;
  Result := a.i[index];
end;

function RISCVVFloorF32x16(const a: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := Floor(a.f[i]);
end;

function RISCVVFloorF32x8(const a: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := Floor(a.f[i]);
end;

function RISCVVFloorF64x2(const a: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := Floor(a.d[i]);
end;

function RISCVVFloorF64x4(const a: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := Floor(a.d[i]);
end;

function RISCVVFloorF64x8(const a: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := Floor(a.d[i]);
end;

function RISCVVFmaF32x16(const a, b, c: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := a.f[i] * b.f[i] + c.f[i];
end;

function RISCVVFmaF32x8(const a, b, c: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := a.f[i] * b.f[i] + c.f[i];
end;

function RISCVVFmaF64x2(const a, b, c: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.d[i] * b.d[i] + c.d[i];
end;

function RISCVVFmaF64x4(const a, b, c: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := a.d[i] * b.d[i] + c.d[i];
end;

function RISCVVFmaF64x8(const a, b, c: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := a.d[i] * b.d[i] + c.d[i];
end;

function RISCVVSatAddI8x16(const a, b: TVecI8x16): TVecI8x16;
var i: Integer;
    sum: Int16;
begin
  for i := 0 to 15 do
  begin
    sum := Int16(a.i[i]) + Int16(b.i[i]);
    if sum > 127 then
      Result.i[i] := 127
    else if sum < -128 then
      Result.i[i] := -128
    else
      Result.i[i] := Int8(sum);
  end;
end;

function RISCVVSatSubI8x16(const a, b: TVecI8x16): TVecI8x16;
var i: Integer;
    diff: Int16;
begin
  for i := 0 to 15 do
  begin
    diff := Int16(a.i[i]) - Int16(b.i[i]);
    if diff > 127 then
      Result.i[i] := 127
    else if diff < -128 then
      Result.i[i] := -128
    else
      Result.i[i] := Int8(diff);
  end;
end;

function RISCVVSatAddI16x8(const a, b: TVecI16x8): TVecI16x8;
var i: Integer;
    sum: Int32;
begin
  for i := 0 to 7 do
  begin
    sum := Int32(a.i[i]) + Int32(b.i[i]);
    if sum > 32767 then
      Result.i[i] := 32767
    else if sum < -32768 then
      Result.i[i] := -32768
    else
      Result.i[i] := Int16(sum);
  end;
end;

function RISCVVSatSubI16x8(const a, b: TVecI16x8): TVecI16x8;
var i: Integer;
    diff: Int32;
begin
  for i := 0 to 7 do
  begin
    diff := Int32(a.i[i]) - Int32(b.i[i]);
    if diff > 32767 then
      Result.i[i] := 32767
    else if diff < -32768 then
      Result.i[i] := -32768
    else
      Result.i[i] := Int16(diff);
  end;
end;

function RISCVVSatAddU8x16(const a, b: TVecU8x16): TVecU8x16;
var i: Integer;
    sum: Word;
begin
  for i := 0 to 15 do
  begin
    sum := Word(a.u[i]) + Word(b.u[i]);
    if sum > 255 then
      Result.u[i] := 255
    else
      Result.u[i] := Byte(sum);
  end;
end;

function RISCVVSatSubU8x16(const a, b: TVecU8x16): TVecU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
  begin
    if a.u[i] > b.u[i] then
      Result.u[i] := a.u[i] - b.u[i]
    else
      Result.u[i] := 0;
  end;
end;

function RISCVVSatAddU16x8(const a, b: TVecU16x8): TVecU16x8;
var i: Integer;
    sum: UInt32;
begin
  for i := 0 to 7 do
  begin
    sum := UInt32(a.u[i]) + UInt32(b.u[i]);
    if sum > 65535 then
      Result.u[i] := 65535
    else
      Result.u[i] := Word(sum);
  end;
end;

function RISCVVSatSubU16x8(const a, b: TVecU16x8): TVecU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
  begin
    if a.u[i] > b.u[i] then
      Result.u[i] := a.u[i] - b.u[i]
    else
      Result.u[i] := 0;
  end;
end;

function RISCVVInsertF32x16(const a: TVecF32x16; value: Single; index: Integer): TVecF32x16;
begin
  if index < 0 then index := 0
  else if index > 15 then index := 15;
  Result := a;
  Result.f[index] := value;
end;

function RISCVVInsertF32x8(const a: TVecF32x8; value: Single; index: Integer): TVecF32x8;
begin
  if index < 0 then index := 0
  else if index > 7 then index := 7;
  Result := a;
  Result.f[index] := value;
end;

function RISCVVInsertF64x2(const a: TVecF64x2; value: Double; index: Integer): TVecF64x2;
begin
  if index < 0 then index := 0
  else if index > 1 then index := 1;
  Result := a;
  Result.d[index] := value;
end;

function RISCVVInsertF64x4(const a: TVecF64x4; value: Double; index: Integer): TVecF64x4;
begin
  if index < 0 then index := 0
  else if index > 3 then index := 3;
  Result := a;
  Result.d[index] := value;
end;

function RISCVVInsertI32x16(const a: TVecI32x16; value: Int32; index: Integer): TVecI32x16;
begin
  if index < 0 then index := 0
  else if index > 15 then index := 15;
  Result := a;
  Result.i[index] := value;
end;

function RISCVVInsertI32x4(const a: TVecI32x4; value: Int32; index: Integer): TVecI32x4;
begin
  if index < 0 then index := 0
  else if index > 3 then index := 3;
  Result := a;
  Result.i[index] := value;
end;

function RISCVVInsertI32x8(const a: TVecI32x8; value: Int32; index: Integer): TVecI32x8;
begin
  if index < 0 then index := 0
  else if index > 7 then index := 7;
  Result := a;
  Result.i[index] := value;
end;

function RISCVVInsertI64x2(const a: TVecI64x2; value: Int64; index: Integer): TVecI64x2;
begin
  if index < 0 then index := 0
  else if index > 1 then index := 1;
  Result := a;
  Result.i[index] := value;
end;

function RISCVVInsertI64x4(const a: TVecI64x4; value: Int64; index: Integer): TVecI64x4;
begin
  if index < 0 then index := 0
  else if index > 3 then index := 3;
  Result := a;
  Result.i[index] := value;
end;

function RISCVVLoadF32x16(p: PSingle): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := p[i];
end;

function RISCVVLoadF32x8(p: PSingle): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := p[i];
end;

function RISCVVLoadF64x2(p: PDouble): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := p[i];
end;

function RISCVVLoadF64x4(p: PDouble): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := p[i];
end;

function RISCVVLoadF64x8(p: PDouble): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := p[i];
end;

function RISCVVLoadI64x4(p: PInt64): TVecI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := p[i];
end;

function RISCVVMaxF32x16(const a, b: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.f[i] > b.f[i] then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

function RISCVVMaxF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.f[i] > b.f[i] then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

function RISCVVMaxF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    if a.d[i] > b.d[i] then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
end;

function RISCVVMaxF64x4(const a, b: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if a.d[i] > b.d[i] then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
end;

function RISCVVMaxF64x8(const a, b: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.d[i] > b.d[i] then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
end;

function RISCVVMaxI16x8(const a, b: TVecI16x8): TVecI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.i[i] > b.i[i] then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

function RISCVVMaxI8x16(const a, b: TVecI8x16): TVecI8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.i[i] > b.i[i] then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

function RISCVVMaxU16x8(const a, b: TVecU16x8): TVecU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.u[i] > b.u[i] then
      Result.u[i] := a.u[i]
    else
      Result.u[i] := b.u[i];
end;

function RISCVVMaxU32x4(const a, b: TVecU32x4): TVecU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if a.u[i] > b.u[i] then
      Result.u[i] := a.u[i]
    else
      Result.u[i] := b.u[i];
end;

function RISCVVMaxU8x16(const a, b: TVecU8x16): TVecU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.u[i] > b.u[i] then
      Result.u[i] := a.u[i]
    else
      Result.u[i] := b.u[i];
end;

function RISCVVMinF32x16(const a, b: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.f[i] < b.f[i] then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

function RISCVVMinF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.f[i] < b.f[i] then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

function RISCVVMinF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    if a.d[i] < b.d[i] then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
end;

function RISCVVMinF64x4(const a, b: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if a.d[i] < b.d[i] then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
end;

function RISCVVMinF64x8(const a, b: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.d[i] < b.d[i] then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
end;

function RISCVVMinI16x8(const a, b: TVecI16x8): TVecI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.i[i] < b.i[i] then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

function RISCVVMinI8x16(const a, b: TVecI8x16): TVecI8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.i[i] < b.i[i] then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

function RISCVVMinU16x8(const a, b: TVecU16x8): TVecU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if a.u[i] < b.u[i] then
      Result.u[i] := a.u[i]
    else
      Result.u[i] := b.u[i];
end;

function RISCVVMinU32x4(const a, b: TVecU32x4): TVecU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if a.u[i] < b.u[i] then
      Result.u[i] := a.u[i]
    else
      Result.u[i] := b.u[i];
end;

function RISCVVMinU8x16(const a, b: TVecU8x16): TVecU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    if a.u[i] < b.u[i] then
      Result.u[i] := a.u[i]
    else
      Result.u[i] := b.u[i];
end;

function RISCVVMulI16x8(const a, b: TVecI16x8): TVecI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] * b.i[i];
end;

function RISCVVMulU16x8(const a, b: TVecU16x8): TVecU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] * b.u[i];
end;

function RISCVVMulU32x4(const a, b: TVecU32x4): TVecU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] * b.u[i];
end;

function RISCVVNotI16x8(const a: TVecI16x8): TVecI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := not a.i[i];
end;

function RISCVVNotI64x4(const a: TVecI64x4): TVecI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := not a.i[i];
end;

function RISCVVNotI64x8(const a: TVecI64x8): TVecI64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := not a.i[i];
end;

function RISCVVNotI8x16(const a: TVecI8x16): TVecI8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := not a.i[i];
end;

function RISCVVNotU16x8(const a: TVecU16x8): TVecU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := not a.u[i];
end;

function RISCVVNotU32x4(const a: TVecU32x4): TVecU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := not a.u[i];
end;

function RISCVVNotU64x4(const a: TVecU64x4): TVecU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := not a.u[i];
end;

function RISCVVNotU8x16(const a: TVecU8x16): TVecU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.u[i] := not a.u[i];
end;

function RISCVVOrI16x8(const a, b: TVecI16x8): TVecI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] or b.i[i];
end;

function RISCVVOrI64x4(const a, b: TVecI64x4): TVecI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] or b.i[i];
end;

function RISCVVOrI64x8(const a, b: TVecI64x8): TVecI64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] or b.i[i];
end;

function RISCVVOrI8x16(const a, b: TVecI8x16): TVecI8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := a.i[i] or b.i[i];
end;

function RISCVVOrU16x8(const a, b: TVecU16x8): TVecU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] or b.u[i];
end;

function RISCVVOrU32x4(const a, b: TVecU32x4): TVecU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] or b.u[i];
end;

function RISCVVOrU64x4(const a, b: TVecU64x4): TVecU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] or b.u[i];
end;

function RISCVVOrU8x16(const a, b: TVecU8x16): TVecU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.u[i] := a.u[i] or b.u[i];
end;

function RISCVVReduceAddF32x16(const a: TVecF32x16): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 15 do
    Result := Result + a.f[i];
end;

function RISCVVReduceAddF32x8(const a: TVecF32x8): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 7 do
    Result := Result + a.f[i];
end;

function RISCVVReduceAddF64x2(const a: TVecF64x2): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 1 do
    Result := Result + a.d[i];
end;

function RISCVVReduceAddF64x4(const a: TVecF64x4): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 3 do
    Result := Result + a.d[i];
end;

function RISCVVReduceAddF64x8(const a: TVecF64x8): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 7 do
    Result := Result + a.d[i];
end;

function RISCVVReduceMaxF32x16(const a: TVecF32x16): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 15 do
    if a.f[i] > Result then
      Result := a.f[i];
end;

function RISCVVReduceMaxF32x8(const a: TVecF32x8): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 7 do
    if a.f[i] > Result then
      Result := a.f[i];
end;

function RISCVVReduceMaxF64x2(const a: TVecF64x2): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 1 do
    if a.d[i] > Result then
      Result := a.d[i];
end;

function RISCVVReduceMaxF64x4(const a: TVecF64x4): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 3 do
    if a.d[i] > Result then
      Result := a.d[i];
end;

function RISCVVReduceMaxF64x8(const a: TVecF64x8): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 7 do
    if a.d[i] > Result then
      Result := a.d[i];
end;

function RISCVVReduceMinF32x16(const a: TVecF32x16): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 15 do
    if a.f[i] < Result then
      Result := a.f[i];
end;

function RISCVVReduceMinF32x8(const a: TVecF32x8): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 7 do
    if a.f[i] < Result then
      Result := a.f[i];
end;

function RISCVVReduceMinF64x2(const a: TVecF64x2): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 1 do
    if a.d[i] < Result then
      Result := a.d[i];
end;

function RISCVVReduceMinF64x4(const a: TVecF64x4): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 3 do
    if a.d[i] < Result then
      Result := a.d[i];
end;

function RISCVVReduceMinF64x8(const a: TVecF64x8): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 7 do
    if a.d[i] < Result then
      Result := a.d[i];
end;

function RISCVVReduceMulF32x16(const a: TVecF32x16): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 15 do
    Result := Result * a.f[i];
end;

function RISCVVReduceMulF32x8(const a: TVecF32x8): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 7 do
    Result := Result * a.f[i];
end;

function RISCVVReduceMulF64x2(const a: TVecF64x2): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 1 do
    Result := Result * a.d[i];
end;

function RISCVVReduceMulF64x4(const a: TVecF64x4): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 3 do
    Result := Result * a.d[i];
end;

function RISCVVReduceMulF64x8(const a: TVecF64x8): Double;
var i: Integer;
begin
  Result := a.d[0];
  for i := 1 to 7 do
    Result := Result * a.d[i];
end;

function RISCVVRoundF32x16(const a: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := Round(a.f[i]);
end;

function RISCVVRoundF32x8(const a: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := Round(a.f[i]);
end;

function RISCVVRoundF64x2(const a: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := Round(a.d[i]);
end;

function RISCVVRoundF64x4(const a: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := Round(a.d[i]);
end;

function RISCVVRoundF64x8(const a: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := Round(a.d[i]);
end;

function RISCVVSelectF32x8(const mask: TVecU32x8; const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if mask.u[i] <> 0 then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

function RISCVVSelectF64x2(const mask: TMask2; const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    if (mask and (1 shl i)) <> 0 then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
end;

function RISCVVSelectF64x4(const mask: TVecU64x4; const a, b: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if mask.u[i] <> 0 then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
end;

function RISCVVSelectI32x4(const mask: TVecI32x4; const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if mask.i[i] <> 0 then
      Result.i[i] := a.i[i]
    else
      Result.i[i] := b.i[i];
end;

function RISCVVShiftLeftI16x8(const a: TVecI16x8; count: Integer): TVecI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] shl count;
end;

function RISCVVShiftLeftI64x4(const a: TVecI64x4; count: Integer): TVecI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] shl count;
end;

function RISCVVShiftLeftU16x8(const a: TVecU16x8; count: Integer): TVecU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] shl count;
end;

function RISCVVShiftLeftU32x4(const a: TVecU32x4; count: Integer): TVecU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] shl count;
end;

function RISCVVShiftLeftU64x4(const a: TVecU64x4; count: Integer): TVecU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] shl count;
end;

function RISCVVShiftRightArithI16x8(const a: TVecI16x8; count: Integer): TVecI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := SarSmallint(a.i[i], count);
end;

function RISCVVShiftRightI16x8(const a: TVecI16x8; count: Integer): TVecI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] shr count;
end;

function RISCVVShiftRightI64x4(const a: TVecI64x4; count: Integer): TVecI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] shr count;
end;

function RISCVVShiftRightU16x8(const a: TVecU16x8; count: Integer): TVecU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] shr count;
end;

function RISCVVShiftRightU32x4(const a: TVecU32x4; count: Integer): TVecU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] shr count;
end;

function RISCVVShiftRightU64x4(const a: TVecU64x4; count: Integer): TVecU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] shr count;
end;

function RISCVVSplatF32x16(value: Single): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := value;
end;

function RISCVVSplatF32x8(value: Single): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := value;
end;

function RISCVVSplatF64x2(value: Double): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := value;
end;

function RISCVVSplatF64x4(value: Double): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := value;
end;

function RISCVVSplatF64x8(value: Double): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := value;
end;

function RISCVVSplatI64x4(value: Int64): TVecI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := value;
end;

function RISCVVSqrtF32x16(const a: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := Sqrt(a.f[i]);
end;

function RISCVVSqrtF32x8(const a: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := Sqrt(a.f[i]);
end;

function RISCVVSqrtF64x2(const a: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := Sqrt(a.d[i]);
end;

function RISCVVSqrtF64x4(const a: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := Sqrt(a.d[i]);
end;

function RISCVVSqrtF64x8(const a: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := Sqrt(a.d[i]);
end;

procedure RISCVVStoreF32x16(p: PSingle; const a: TVecF32x16);
var i: Integer;
begin
  for i := 0 to 15 do
    p[i] := a.f[i];
end;

procedure RISCVVStoreF32x8(p: PSingle; const a: TVecF32x8);
var i: Integer;
begin
  for i := 0 to 7 do
    p[i] := a.f[i];
end;

procedure RISCVVStoreF64x2(p: PDouble; const a: TVecF64x2);
var i: Integer;
begin
  for i := 0 to 1 do
    p[i] := a.d[i];
end;

procedure RISCVVStoreF64x4(p: PDouble; const a: TVecF64x4);
var i: Integer;
begin
  for i := 0 to 3 do
    p[i] := a.d[i];
end;

procedure RISCVVStoreF64x8(p: PDouble; const a: TVecF64x8);
var i: Integer;
begin
  for i := 0 to 7 do
    p[i] := a.d[i];
end;

procedure RISCVVStoreI64x4(p: PInt64; const a: TVecI64x4);
var i: Integer;
begin
  for i := 0 to 3 do
    p[i] := a.i[i];
end;

function RISCVVSubI16x8(const a, b: TVecI16x8): TVecI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] - b.i[i];
end;

function RISCVVSubI64x4(const a, b: TVecI64x4): TVecI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] - b.i[i];
end;

function RISCVVSubI64x8(const a, b: TVecI64x8): TVecI64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] - b.i[i];
end;

function RISCVVSubI8x16(const a, b: TVecI8x16): TVecI8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := a.i[i] - b.i[i];
end;

function RISCVVSubU16x8(const a, b: TVecU16x8): TVecU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] - b.u[i];
end;

function RISCVVSubU32x4(const a, b: TVecU32x4): TVecU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] - b.u[i];
end;

function RISCVVSubU64x4(const a, b: TVecU64x4): TVecU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] - b.u[i];
end;

function RISCVVSubU8x16(const a, b: TVecU8x16): TVecU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.u[i] := a.u[i] - b.u[i];
end;

function RISCVVTruncF32x16(const a: TVecF32x16): TVecF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.f[i] := Trunc(a.f[i]);
end;

function RISCVVTruncF32x8(const a: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := Trunc(a.f[i]);
end;

function RISCVVTruncF64x2(const a: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := Trunc(a.d[i]);
end;

function RISCVVTruncF64x4(const a: TVecF64x4): TVecF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.d[i] := Trunc(a.d[i]);
end;

function RISCVVTruncF64x8(const a: TVecF64x8): TVecF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.d[i] := Trunc(a.d[i]);
end;

function RISCVVXorI16x8(const a, b: TVecI16x8): TVecI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] xor b.i[i];
end;

function RISCVVXorI64x4(const a, b: TVecI64x4): TVecI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] xor b.i[i];
end;

function RISCVVXorI64x8(const a, b: TVecI64x8): TVecI64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.i[i] := a.i[i] xor b.i[i];
end;

function RISCVVXorI8x16(const a, b: TVecI8x16): TVecI8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.i[i] := a.i[i] xor b.i[i];
end;

function RISCVVXorU16x8(const a, b: TVecU16x8): TVecU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.u[i] := a.u[i] xor b.u[i];
end;

function RISCVVXorU32x4(const a, b: TVecU32x4): TVecU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] xor b.u[i];
end;

function RISCVVXorU64x4(const a, b: TVecU64x4): TVecU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.u[i] := a.u[i] xor b.u[i];
end;

function RISCVVXorU8x16(const a, b: TVecU8x16): TVecU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result.u[i] := a.u[i] xor b.u[i];
end;

function RISCVVZeroF32x16: TVecF32x16;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function RISCVVZeroF32x8: TVecF32x8;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function RISCVVZeroF64x2: TVecF64x2;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function RISCVVZeroF64x4: TVecF64x4;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function RISCVVZeroF64x8: TVecF64x8;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function RISCVVZeroI64x4: TVecI64x4;
begin
  FillChar(Result, SizeOf(Result), 0);
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
  // ✅ 使用 FillBaseDispatchTable 填充标量后备实现，而不是 FillChar
  // 这确保所有未注册的函数都有有效的后备实现，避免空指针异常
  table := Default(TSimdDispatchTable);
  FillBaseDispatchTable(table);

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
  table.CmpLeI32x4 := @RISCVVCmpLeI32x4;  // ✅ Task 6.4: Added
  table.CmpGeI32x4 := @RISCVVCmpGeI32x4;  // ✅ Task 6.4: Added
  table.CmpNeI32x4 := @RISCVVCmpNeI32x4;  // ✅ Task 6.4: Added

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

  // F32x8 Comparison - ✅ Task 6.4: Added
  table.CmpEqF32x8 := @RISCVVCmpEqF32x8;
  table.CmpLtF32x8 := @RISCVVCmpLtF32x8;
  table.CmpLeF32x8 := @RISCVVCmpLeF32x8;
  table.CmpGtF32x8 := @RISCVVCmpGtF32x8;
  table.CmpGeF32x8 := @RISCVVCmpGeF32x8;
  table.CmpNeF32x8 := @RISCVVCmpNeF32x8;

  // === F64x4 Operations ===
  table.AddF64x4 := @RISCVVAddF64x4;
  table.SubF64x4 := @RISCVVSubF64x4;
  table.MulF64x4 := @RISCVVMulF64x4;
  table.DivF64x4 := @RISCVVDivF64x4;

  // F64x4 Comparison - ✅ Task 6.4: Added
  table.CmpEqF64x4 := @RISCVVCmpEqF64x4;
  table.CmpLtF64x4 := @RISCVVCmpLtF64x4;
  table.CmpLeF64x4 := @RISCVVCmpLeF64x4;
  table.CmpGtF64x4 := @RISCVVCmpGtF64x4;
  table.CmpGeF64x4 := @RISCVVCmpGeF64x4;
  table.CmpNeF64x4 := @RISCVVCmpNeF64x4;

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
  table.CmpLeI32x8 := @RISCVVCmpLeI32x8;  // ✅ Task 6.4: Added
  table.CmpGeI32x8 := @RISCVVCmpGeI32x8;  // ✅ Task 6.4: Added
  table.CmpNeI32x8 := @RISCVVCmpNeI32x8;  // ✅ Task 6.4: Added
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
  table.CmpLeI32x16 := @RISCVVCmpLeI32x16;  // ✅ Task 6.4: Added
  table.CmpGeI32x16 := @RISCVVCmpGeI32x16;  // ✅ Task 6.4: Added
  table.CmpNeI32x16 := @RISCVVCmpNeI32x16;  // ✅ Task 6.4: Added
  table.MinI32x16 := @RISCVVMinI32x16;
  table.MaxI32x16 := @RISCVVMaxI32x16;

  // === F32x16 Operations (512-bit, 16x Single) ===
  table.AddF32x16 := @RISCVVAddF32x16;
  table.SubF32x16 := @RISCVVSubF32x16;
  table.MulF32x16 := @RISCVVMulF32x16;
  table.DivF32x16 := @RISCVVDivF32x16;

  // F32x16 Comparison - ✅ Task 6.4: Added
  table.CmpEqF32x16 := @RISCVVCmpEqF32x16;
  table.CmpLtF32x16 := @RISCVVCmpLtF32x16;
  table.CmpLeF32x16 := @RISCVVCmpLeF32x16;
  table.CmpGtF32x16 := @RISCVVCmpGtF32x16;
  table.CmpGeF32x16 := @RISCVVCmpGeF32x16;
  table.CmpNeF32x16 := @RISCVVCmpNeF32x16;
  table.SelectF32x16 := @RISCVVSelectF32x16;

  // === F64x8 Operations (512-bit, 8x Double) ===
  table.AddF64x8 := @RISCVVAddF64x8;
  table.SubF64x8 := @RISCVVSubF64x8;
  table.MulF64x8 := @RISCVVMulF64x8;
  table.DivF64x8 := @RISCVVDivF64x8;

  // F64x8 Comparison - ✅ Task 6.4: Added
  table.CmpEqF64x8 := @RISCVVCmpEqF64x8;
  table.CmpLtF64x8 := @RISCVVCmpLtF64x8;
  table.CmpLeF64x8 := @RISCVVCmpLeF64x8;
  table.CmpGtF64x8 := @RISCVVCmpGtF64x8;
  table.CmpGeF64x8 := @RISCVVCmpGeF64x8;
  table.CmpNeF64x8 := @RISCVVCmpNeF64x8;
  table.SelectF64x8 := @RISCVVSelectF64x8;

  // === Mask Operations - ✅ Task 6.4: Added ===
  // TMask4 Operations
  table.Mask4All := @RISCVVMask4All;
  table.Mask4Any := @RISCVVMask4Any;
  table.Mask4None := @RISCVVMask4None;
  table.Mask4PopCount := @RISCVVMask4PopCount;
  table.Mask4FirstSet := @RISCVVMask4FirstSet;

  // TMask8 Operations
  table.Mask8All := @RISCVVMask8All;
  table.Mask8Any := @RISCVVMask8Any;
  table.Mask8None := @RISCVVMask8None;
  table.Mask8PopCount := @RISCVVMask8PopCount;
  table.Mask8FirstSet := @RISCVVMask8FirstSet;

  // TMask16 Operations
  table.Mask16All := @RISCVVMask16All;
  table.Mask16Any := @RISCVVMask16Any;
  table.Mask16None := @RISCVVMask16None;
  table.Mask16PopCount := @RISCVVMask16PopCount;
  table.Mask16FirstSet := @RISCVVMask16FirstSet;

  // =============================================================
  // Additional Operations Registration (100% Coverage)
  // =============================================================

  // TMask2 Operations
  table.Mask2All := @RISCVVMask2All;
  table.Mask2Any := @RISCVVMask2Any;
  table.Mask2None := @RISCVVMask2None;
  table.Mask2PopCount := @RISCVVMask2PopCount;
  table.Mask2FirstSet := @RISCVVMask2FirstSet;

  // Wide Float Operations (Abs, Sqrt, Min, Max, Clamp)
  table.AbsF32x16 := @RISCVVAbsF32x16;
  table.AbsF32x8 := @RISCVVAbsF32x8;
  table.AbsF64x2 := @RISCVVAbsF64x2;
  table.AbsF64x4 := @RISCVVAbsF64x4;
  table.AbsF64x8 := @RISCVVAbsF64x8;
  table.SqrtF32x16 := @RISCVVSqrtF32x16;
  table.SqrtF32x8 := @RISCVVSqrtF32x8;
  table.SqrtF64x2 := @RISCVVSqrtF64x2;
  table.SqrtF64x4 := @RISCVVSqrtF64x4;
  table.SqrtF64x8 := @RISCVVSqrtF64x8;
  table.MinF32x16 := @RISCVVMinF32x16;
  table.MinF32x8 := @RISCVVMinF32x8;
  table.MinF64x2 := @RISCVVMinF64x2;
  table.MinF64x4 := @RISCVVMinF64x4;
  table.MinF64x8 := @RISCVVMinF64x8;
  table.MaxF32x16 := @RISCVVMaxF32x16;
  table.MaxF32x8 := @RISCVVMaxF32x8;
  table.MaxF64x2 := @RISCVVMaxF64x2;
  table.MaxF64x4 := @RISCVVMaxF64x4;
  table.MaxF64x8 := @RISCVVMaxF64x8;
  table.ClampF32x16 := @RISCVVClampF32x16;
  table.ClampF32x8 := @RISCVVClampF32x8;
  table.ClampF64x2 := @RISCVVClampF64x2;
  table.ClampF64x4 := @RISCVVClampF64x4;
  table.ClampF64x8 := @RISCVVClampF64x8;

  // Wide Float Extended Math (Ceil, Floor, Round, Trunc, Fma)
  table.CeilF32x16 := @RISCVVCeilF32x16;
  table.CeilF32x8 := @RISCVVCeilF32x8;
  table.CeilF64x2 := @RISCVVCeilF64x2;
  table.CeilF64x4 := @RISCVVCeilF64x4;
  table.CeilF64x8 := @RISCVVCeilF64x8;
  table.FloorF32x16 := @RISCVVFloorF32x16;
  table.FloorF32x8 := @RISCVVFloorF32x8;
  table.FloorF64x2 := @RISCVVFloorF64x2;
  table.FloorF64x4 := @RISCVVFloorF64x4;
  table.FloorF64x8 := @RISCVVFloorF64x8;
  table.RoundF32x16 := @RISCVVRoundF32x16;
  table.RoundF32x8 := @RISCVVRoundF32x8;
  table.RoundF64x2 := @RISCVVRoundF64x2;
  table.RoundF64x4 := @RISCVVRoundF64x4;
  table.RoundF64x8 := @RISCVVRoundF64x8;
  table.TruncF32x16 := @RISCVVTruncF32x16;
  table.TruncF32x8 := @RISCVVTruncF32x8;
  table.TruncF64x2 := @RISCVVTruncF64x2;
  table.TruncF64x4 := @RISCVVTruncF64x4;
  table.TruncF64x8 := @RISCVVTruncF64x8;
  table.FmaF32x16 := @RISCVVFmaF32x16;
  table.FmaF32x8 := @RISCVVFmaF32x8;
  table.FmaF64x2 := @RISCVVFmaF64x2;
  table.FmaF64x4 := @RISCVVFmaF64x4;
  table.FmaF64x8 := @RISCVVFmaF64x8;

  // Wide Float Reduction
  table.ReduceAddF32x16 := @RISCVVReduceAddF32x16;
  table.ReduceAddF32x8 := @RISCVVReduceAddF32x8;
  table.ReduceAddF64x2 := @RISCVVReduceAddF64x2;
  table.ReduceAddF64x4 := @RISCVVReduceAddF64x4;
  table.ReduceAddF64x8 := @RISCVVReduceAddF64x8;
  table.ReduceMaxF32x16 := @RISCVVReduceMaxF32x16;
  table.ReduceMaxF32x8 := @RISCVVReduceMaxF32x8;
  table.ReduceMaxF64x2 := @RISCVVReduceMaxF64x2;
  table.ReduceMaxF64x4 := @RISCVVReduceMaxF64x4;
  table.ReduceMaxF64x8 := @RISCVVReduceMaxF64x8;
  table.ReduceMinF32x16 := @RISCVVReduceMinF32x16;
  table.ReduceMinF32x8 := @RISCVVReduceMinF32x8;
  table.ReduceMinF64x2 := @RISCVVReduceMinF64x2;
  table.ReduceMinF64x4 := @RISCVVReduceMinF64x4;
  table.ReduceMinF64x8 := @RISCVVReduceMinF64x8;
  table.ReduceMulF32x16 := @RISCVVReduceMulF32x16;
  table.ReduceMulF32x8 := @RISCVVReduceMulF32x8;
  table.ReduceMulF64x2 := @RISCVVReduceMulF64x2;
  table.ReduceMulF64x4 := @RISCVVReduceMulF64x4;
  table.ReduceMulF64x8 := @RISCVVReduceMulF64x8;

  // F64x2 Comparison
  table.CmpEqF64x2 := @RISCVVCmpEqF64x2;
  table.CmpLtF64x2 := @RISCVVCmpLtF64x2;
  table.CmpLeF64x2 := @RISCVVCmpLeF64x2;
  table.CmpGtF64x2 := @RISCVVCmpGtF64x2;
  table.CmpGeF64x2 := @RISCVVCmpGeF64x2;
  table.CmpNeF64x2 := @RISCVVCmpNeF64x2;

  // Wide Float Memory/Utility
  table.LoadF32x16 := @RISCVVLoadF32x16;
  table.LoadF32x8 := @RISCVVLoadF32x8;
  table.LoadF64x2 := @RISCVVLoadF64x2;
  table.LoadF64x4 := @RISCVVLoadF64x4;
  table.LoadF64x8 := @RISCVVLoadF64x8;
  table.StoreF32x16 := @RISCVVStoreF32x16;
  table.StoreF32x8 := @RISCVVStoreF32x8;
  table.StoreF64x2 := @RISCVVStoreF64x2;
  table.StoreF64x4 := @RISCVVStoreF64x4;
  table.StoreF64x8 := @RISCVVStoreF64x8;
  table.SplatF32x16 := @RISCVVSplatF32x16;
  table.SplatF32x8 := @RISCVVSplatF32x8;
  table.SplatF64x2 := @RISCVVSplatF64x2;
  table.SplatF64x4 := @RISCVVSplatF64x4;
  table.SplatF64x8 := @RISCVVSplatF64x8;
  table.ZeroF32x16 := @RISCVVZeroF32x16;
  table.ZeroF32x8 := @RISCVVZeroF32x8;
  table.ZeroF64x2 := @RISCVVZeroF64x2;
  table.ZeroF64x4 := @RISCVVZeroF64x4;
  table.ZeroF64x8 := @RISCVVZeroF64x8;

  // Wide Float Extract/Insert
  table.ExtractF32x16 := @RISCVVExtractF32x16;
  table.ExtractF32x8 := @RISCVVExtractF32x8;
  table.ExtractF64x2 := @RISCVVExtractF64x2;
  table.ExtractF64x4 := @RISCVVExtractF64x4;
  table.InsertF32x16 := @RISCVVInsertF32x16;
  table.InsertF32x8 := @RISCVVInsertF32x8;
  table.InsertF64x2 := @RISCVVInsertF64x2;
  table.InsertF64x4 := @RISCVVInsertF64x4;

  // Wide Float Select
  table.SelectF32x8 := @RISCVVSelectF32x8;
  table.SelectF64x2 := @RISCVVSelectF64x2;
  table.SelectF64x4 := @RISCVVSelectF64x4;
  table.SelectI32x4 := @RISCVVSelectI32x4;

  // I64x2 Comparison
  table.CmpEqI64x2 := @RISCVVCmpEqI64x2;
  table.CmpLtI64x2 := @RISCVVCmpLtI64x2;
  table.CmpLeI64x2 := @RISCVVCmpLeI64x2;
  table.CmpGtI64x2 := @RISCVVCmpGtI64x2;
  table.CmpGeI64x2 := @RISCVVCmpGeI64x2;
  table.CmpNeI64x2 := @RISCVVCmpNeI64x2;

  // I64x4 Operations
  table.AddI64x4 := @RISCVVAddI64x4;
  table.SubI64x4 := @RISCVVSubI64x4;
  table.AndI64x4 := @RISCVVAndI64x4;
  table.OrI64x4 := @RISCVVOrI64x4;
  table.XorI64x4 := @RISCVVXorI64x4;
  table.NotI64x4 := @RISCVVNotI64x4;
  table.AndNotI64x4 := @RISCVVAndNotI64x4;
  table.ShiftLeftI64x4 := @RISCVVShiftLeftI64x4;
  table.ShiftRightI64x4 := @RISCVVShiftRightI64x4;
  table.CmpEqI64x4 := @RISCVVCmpEqI64x4;
  table.CmpLtI64x4 := @RISCVVCmpLtI64x4;
  table.CmpLeI64x4 := @RISCVVCmpLeI64x4;
  table.CmpGtI64x4 := @RISCVVCmpGtI64x4;
  table.CmpGeI64x4 := @RISCVVCmpGeI64x4;
  table.CmpNeI64x4 := @RISCVVCmpNeI64x4;
  table.LoadI64x4 := @RISCVVLoadI64x4;
  table.StoreI64x4 := @RISCVVStoreI64x4;
  table.SplatI64x4 := @RISCVVSplatI64x4;
  table.ZeroI64x4 := @RISCVVZeroI64x4;
  table.ExtractI64x4 := @RISCVVExtractI64x4;
  table.InsertI64x4 := @RISCVVInsertI64x4;

  // I64x8 Operations
  table.AddI64x8 := @RISCVVAddI64x8;
  table.SubI64x8 := @RISCVVSubI64x8;
  table.AndI64x8 := @RISCVVAndI64x8;
  table.OrI64x8 := @RISCVVOrI64x8;
  table.XorI64x8 := @RISCVVXorI64x8;
  table.NotI64x8 := @RISCVVNotI64x8;
  table.CmpEqI64x8 := @RISCVVCmpEqI64x8;
  table.CmpLtI64x8 := @RISCVVCmpLtI64x8;
  table.CmpLeI64x8 := @RISCVVCmpLeI64x8;
  table.CmpGtI64x8 := @RISCVVCmpGtI64x8;
  table.CmpGeI64x8 := @RISCVVCmpGeI64x8;
  table.CmpNeI64x8 := @RISCVVCmpNeI64x8;

  // I32x4/I32x8/I32x16 Extract/Insert
  table.ExtractI32x4 := @RISCVVExtractI32x4;
  table.InsertI32x4 := @RISCVVInsertI32x4;
  table.ExtractI32x8 := @RISCVVExtractI32x8;
  table.InsertI32x8 := @RISCVVInsertI32x8;
  table.ExtractI32x16 := @RISCVVExtractI32x16;
  table.InsertI32x16 := @RISCVVInsertI32x16;
  table.ExtractI64x2 := @RISCVVExtractI64x2;
  table.InsertI64x2 := @RISCVVInsertI64x2;

  // Narrow Integer Types: I16x8
  table.AddI16x8 := @RISCVVAddI16x8;
  table.SubI16x8 := @RISCVVSubI16x8;
  table.MulI16x8 := @RISCVVMulI16x8;
  table.AndI16x8 := @RISCVVAndI16x8;
  table.OrI16x8 := @RISCVVOrI16x8;
  table.XorI16x8 := @RISCVVXorI16x8;
  table.NotI16x8 := @RISCVVNotI16x8;
  table.AndNotI16x8 := @RISCVVAndNotI16x8;
  table.ShiftLeftI16x8 := @RISCVVShiftLeftI16x8;
  table.ShiftRightI16x8 := @RISCVVShiftRightI16x8;
  table.ShiftRightArithI16x8 := @RISCVVShiftRightArithI16x8;
  table.CmpEqI16x8 := @RISCVVCmpEqI16x8;
  table.CmpLtI16x8 := @RISCVVCmpLtI16x8;
  table.CmpLeI16x8 := @RISCVVCmpLeI16x8;
  table.CmpGtI16x8 := @RISCVVCmpGtI16x8;
  table.CmpGeI16x8 := @RISCVVCmpGeI16x8;
  table.CmpNeI16x8 := @RISCVVCmpNeI16x8;
  table.MinI16x8 := @RISCVVMinI16x8;
  table.MaxI16x8 := @RISCVVMaxI16x8;

  // Narrow Integer Types: I8x16
  table.AddI8x16 := @RISCVVAddI8x16;
  table.SubI8x16 := @RISCVVSubI8x16;
  table.AndI8x16 := @RISCVVAndI8x16;
  table.OrI8x16 := @RISCVVOrI8x16;
  table.XorI8x16 := @RISCVVXorI8x16;
  table.NotI8x16 := @RISCVVNotI8x16;
  table.CmpEqI8x16 := @RISCVVCmpEqI8x16;
  table.CmpLtI8x16 := @RISCVVCmpLtI8x16;
  table.CmpLeI8x16 := @RISCVVCmpLeI8x16;
  table.CmpGtI8x16 := @RISCVVCmpGtI8x16;
  table.CmpGeI8x16 := @RISCVVCmpGeI8x16;
  table.CmpNeI8x16 := @RISCVVCmpNeI8x16;
  table.MinI8x16 := @RISCVVMinI8x16;
  table.MaxI8x16 := @RISCVVMaxI8x16;

  // Unsigned Integer Types: U32x4
  table.AddU32x4 := @RISCVVAddU32x4;
  table.SubU32x4 := @RISCVVSubU32x4;
  table.MulU32x4 := @RISCVVMulU32x4;
  table.AndU32x4 := @RISCVVAndU32x4;
  table.OrU32x4 := @RISCVVOrU32x4;
  table.XorU32x4 := @RISCVVXorU32x4;
  table.NotU32x4 := @RISCVVNotU32x4;
  table.AndNotU32x4 := @RISCVVAndNotU32x4;
  table.ShiftLeftU32x4 := @RISCVVShiftLeftU32x4;
  table.ShiftRightU32x4 := @RISCVVShiftRightU32x4;
  table.CmpEqU32x4 := @RISCVVCmpEqU32x4;
  table.CmpLtU32x4 := @RISCVVCmpLtU32x4;
  table.CmpLeU32x4 := @RISCVVCmpLeU32x4;
  table.CmpGtU32x4 := @RISCVVCmpGtU32x4;
  table.CmpGeU32x4 := @RISCVVCmpGeU32x4;
  table.MinU32x4 := @RISCVVMinU32x4;
  table.MaxU32x4 := @RISCVVMaxU32x4;

  // Unsigned Integer Types: U64x4
  table.AddU64x4 := @RISCVVAddU64x4;
  table.SubU64x4 := @RISCVVSubU64x4;
  table.AndU64x4 := @RISCVVAndU64x4;
  table.OrU64x4 := @RISCVVOrU64x4;
  table.XorU64x4 := @RISCVVXorU64x4;
  table.NotU64x4 := @RISCVVNotU64x4;
  table.ShiftLeftU64x4 := @RISCVVShiftLeftU64x4;
  table.ShiftRightU64x4 := @RISCVVShiftRightU64x4;
  table.CmpEqU64x4 := @RISCVVCmpEqU64x4;
  table.CmpLtU64x4 := @RISCVVCmpLtU64x4;
  table.CmpLeU64x4 := @RISCVVCmpLeU64x4;
  table.CmpGtU64x4 := @RISCVVCmpGtU64x4;
  table.CmpGeU64x4 := @RISCVVCmpGeU64x4;
  table.CmpNeU64x4 := @RISCVVCmpNeU64x4;

  // ✅ Unsigned Integer Types: U32x8 (256-bit)
  table.AddU32x8 := @RISCVVAddU32x8;
  table.SubU32x8 := @RISCVVSubU32x8;
  table.MulU32x8 := @RISCVVMulU32x8;
  table.AndU32x8 := @RISCVVAndU32x8;
  table.OrU32x8 := @RISCVVOrU32x8;
  table.XorU32x8 := @RISCVVXorU32x8;
  table.NotU32x8 := @RISCVVNotU32x8;
  table.AndNotU32x8 := @RISCVVAndNotU32x8;
  table.ShiftLeftU32x8 := @RISCVVShiftLeftU32x8;
  table.ShiftRightU32x8 := @RISCVVShiftRightU32x8;
  table.CmpEqU32x8 := @RISCVVCmpEqU32x8;
  table.CmpLtU32x8 := @RISCVVCmpLtU32x8;
  table.CmpLeU32x8 := @RISCVVCmpLeU32x8;
  table.CmpGtU32x8 := @RISCVVCmpGtU32x8;
  table.CmpGeU32x8 := @RISCVVCmpGeU32x8;
  table.CmpNeU32x8 := @RISCVVCmpNeU32x8;
  table.MinU32x8 := @RISCVVMinU32x8;
  table.MaxU32x8 := @RISCVVMaxU32x8;

  // ✅ RcpF64x4 (Reciprocal)
  table.RcpF64x4 := @RISCVVRcpF64x4;

  // Unsigned Integer Types: U16x8
  table.AddU16x8 := @RISCVVAddU16x8;
  table.SubU16x8 := @RISCVVSubU16x8;
  table.MulU16x8 := @RISCVVMulU16x8;
  table.AndU16x8 := @RISCVVAndU16x8;
  table.OrU16x8 := @RISCVVOrU16x8;
  table.XorU16x8 := @RISCVVXorU16x8;
  table.NotU16x8 := @RISCVVNotU16x8;
  table.ShiftLeftU16x8 := @RISCVVShiftLeftU16x8;
  table.ShiftRightU16x8 := @RISCVVShiftRightU16x8;
  table.CmpEqU16x8 := @RISCVVCmpEqU16x8;
  table.CmpLtU16x8 := @RISCVVCmpLtU16x8;
  table.CmpLeU16x8 := @RISCVVCmpLeU16x8;
  table.CmpGtU16x8 := @RISCVVCmpGtU16x8;
  table.CmpGeU16x8 := @RISCVVCmpGeU16x8;
  table.CmpNeU16x8 := @RISCVVCmpNeU16x8;
  table.MinU16x8 := @RISCVVMinU16x8;
  table.MaxU16x8 := @RISCVVMaxU16x8;

  // Unsigned Integer Types: U8x16
  table.AddU8x16 := @RISCVVAddU8x16;
  table.SubU8x16 := @RISCVVSubU8x16;
  table.AndU8x16 := @RISCVVAndU8x16;
  table.OrU8x16 := @RISCVVOrU8x16;
  table.XorU8x16 := @RISCVVXorU8x16;
  table.NotU8x16 := @RISCVVNotU8x16;
  table.CmpEqU8x16 := @RISCVVCmpEqU8x16;
  table.CmpLtU8x16 := @RISCVVCmpLtU8x16;
  table.CmpLeU8x16 := @RISCVVCmpLeU8x16;
  table.CmpGtU8x16 := @RISCVVCmpGtU8x16;
  table.CmpGeU8x16 := @RISCVVCmpGeU8x16;
  table.CmpNeU8x16 := @RISCVVCmpNeU8x16;
  table.MinU8x16 := @RISCVVMinU8x16;
  table.MaxU8x16 := @RISCVVMaxU8x16;

  // Saturating Arithmetic
  table.I8x16SatAdd := @RISCVVSatAddI8x16;
  table.I8x16SatSub := @RISCVVSatSubI8x16;
  table.I16x8SatAdd := @RISCVVSatAddI16x8;
  table.I16x8SatSub := @RISCVVSatSubI16x8;
  table.U8x16SatAdd := @RISCVVSatAddU8x16;
  table.U8x16SatSub := @RISCVVSatSubU8x16;
  table.U16x8SatAdd := @RISCVVSatAddU16x8;
  table.U16x8SatSub := @RISCVVSatSubU16x8;

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
