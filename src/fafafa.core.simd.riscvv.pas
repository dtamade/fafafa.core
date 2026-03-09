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
  fafafa.core.simd.dispatch,
  fafafa.core.simd.backend.priority;

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
// RISC-V V extension inline asm is experimental and currently depends on
// compiler branches with RVV opcode support.
// Default policy: keep asm OFF unless explicitly opted in.
// Opt-in define: FAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM
// Per-backend gate: FAFAFA_SIMD_ENABLE_RISCVV_ASM
// Compiler capability gate: FAFAFA_SIMD_RISCVV_ASM_COMPILER_READY
// Opcode capability gate: FAFAFA_SIMD_RISCVV_ASM_OPCODE_READY
// Global emergency switch: SIMD_VECTOR_ASM_DISABLED
  {$IFNDEF SIMD_VECTOR_ASM_DISABLED}
    {$IFDEF FAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM}
      {$IFDEF FAFAFA_SIMD_ENABLE_RISCVV_ASM}
        {$IFDEF FAFAFA_SIMD_RISCVV_ASM_COMPILER_READY}
          {$IFDEF FAFAFA_SIMD_RISCVV_ASM_OPCODE_READY}
            {$DEFINE RISCVV_ASSEMBLY}
          {$ENDIF}
        {$ENDIF}
      {$ENDIF}
    {$ENDIF}
  {$ENDIF}
{$ENDIF}

{$IFDEF RISCVV_ASSEMBLY}

// =============================================================
// F32x4 Operations (128-bit, 4x Single)
// =============================================================

function RISCVVAddF32x4(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  // a0 = &a, a1 = &b, a0 (return) = &Result
  // Set vector length to 4 elements of 32-bit
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vfadd.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVSubF32x4(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vfsub.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVMulF32x4(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vfmul.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVDivF32x4(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vfdiv.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVAbsF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vfsgnjx.vv v0, v0, v0
  vse32.v v0, (a0)
end;

function RISCVVSqrtF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vfsqrt.v v0, v0
  vse32.v v0, (a0)
end;

function RISCVVMinF32x4(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vfmin.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVMaxF32x4(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
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
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vfadd.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVSubF64x2(const a, b: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vfsub.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVMulF64x2(const a, b: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vfmul.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVDivF64x2(const a, b: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
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
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vadd.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVSubI32x4(const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vsub.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVMulI32x4(const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmul.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVAndI32x4(const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vand.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVOrI32x4(const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vor.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVXorI32x4(const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vxor.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVNotI32x4(const a: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vxor.vi v0, v0, -1
  vse32.v v0, (a0)
end;

// =============================================================
// F32x4 Extended Operations
// =============================================================

function RISCVVFmaF32x4(const a, b, c: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  // Result = a * b + c
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)      // a
  vle32.v v1, (a1)      // b
  vle32.v v2, (a2)      // c
  vfmadd.vv v0, v1, v2  // v0 = v0 * v1 + v2
  vse32.v v0, (a0)
end;

function RISCVVRcpF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  // Result = 1.0 / a (approximate)
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vfrec7.v v0, v0       // Reciprocal approximation
  vse32.v v0, (a0)
end;

function RISCVVRsqrtF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  // Result = 1.0 / sqrt(a) (approximate)
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vfrsqrt7.v v0, v0     // Reciprocal sqrt approximation
  vse32.v v0, (a0)
end;

function RISCVVNegF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vfsgnjn.vv v0, v0, v0
  vse32.v v0, (a0)
end;

// =============================================================
// F32x4 Comparison Operations (return TMask4)
// =============================================================

function RISCVVCmpEqF32x4(const a, b: TVecF32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmfeq.vv v0, v0, v1   // Mask in v0
  // Extract mask to scalar - simplified, returns all-ones or all-zeros per element
  vmv.x.s a0, v0
end;

function RISCVVCmpLtF32x4(const a, b: TVecF32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmflt.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLeF32x4(const a, b: TVecF32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmfle.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpGtF32x4(const a, b: TVecF32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmflt.vv v0, v1, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpGeF32x4(const a, b: TVecF32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmfle.vv v0, v1, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpNeF32x4(const a, b: TVecF32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
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
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmseq.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLtI32x4(const a, b: TVecI32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmslt.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLeI32x4(const a, b: TVecI32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmsle.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpGtI32x4(const a, b: TVecI32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmslt.vv v0, v1, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpGeI32x4(const a, b: TVecI32x4): TMask4; assembler; nostackframe;
asm
  // a >= b  equals  NOT(a < b)
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmslt.vv v0, v0, v1   // a < b
  vmnand.mm v0, v0, v0        // NOT
  vmv.x.s a0, v0
end;

function RISCVVCmpNeI32x4(const a, b: TVecI32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
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
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vxor.vi v0, v0, -1
  vand.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVMinI32x4(const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmin.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVMaxI32x4(const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
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
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vsll.vx v0, v0, a1
  vse32.v v0, (a0)
end;

function RISCVVShiftRightI32x4(const a: TVecI32x4; count: Integer): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vsrl.vx v0, v0, a1    // Logical right shift
  vse32.v v0, (a0)
end;

function RISCVVShiftRightArithI32x4(const a: TVecI32x4; count: Integer): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vsra.vx v0, v0, a1    // Arithmetic right shift (sign-extend)
  vse32.v v0, (a0)
end;

// =============================================================
// F64x2 Extended Operations
// =============================================================

function RISCVVAbsF64x2(const a: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vfsgnjx.vv v0, v0, v0
  vse64.v v0, (a0)
end;

function RISCVVSqrtF64x2(const a: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vfsqrt.v v0, v0
  vse64.v v0, (a0)
end;

function RISCVVMinF64x2(const a, b: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vfmin.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVMaxF64x2(const a, b: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vfmax.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVNegF64x2(const a: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vfsgnjn.vv v0, v0, v0
  vse64.v v0, (a0)
end;

function RISCVVFmaF64x2(const a, b, c: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
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
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vadd.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVSubI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vsub.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVAndI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vand.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVOrI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vor.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVXorI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vxor.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVNotI64x2(const a: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vxor.vi v0, v0, -1
  vse64.v v0, (a0)
end;

function RISCVVShiftLeftI64x2(const a: TVecI64x2; count: Integer): TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vsll.vx v0, v0, a1
  vse64.v v0, (a0)
end;

function RISCVVShiftRightI64x2(const a: TVecI64x2; count: Integer): TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vsrl.vx v0, v0, a1
  vse64.v v0, (a0)
end;

function RISCVVShiftRightArithI64x2(const a: TVecI64x2; count: Integer): TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vsra.vx v0, v0, a1
  vse64.v v0, (a0)
end;

// =============================================================
// U32x4 Operations (128-bit, 4x UInt32)
// =============================================================

function RISCVVAddU32x4(const a, b: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vadd.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVSubU32x4(const a, b: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vsub.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVMulU32x4(const a, b: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmul.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVMinU32x4(const a, b: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vminu.vv v0, v0, v1   // Unsigned min
  vse32.v v0, (a0)
end;

function RISCVVMaxU32x4(const a, b: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmaxu.vv v0, v0, v1   // Unsigned max
  vse32.v v0, (a0)
end;

function RISCVVCmpLtU32x4(const a, b: TVecU32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmsltu.vv v0, v0, v1  // Unsigned less than
  vmv.x.s a0, v0
end;

function RISCVVCmpLeU32x4(const a, b: TVecU32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmsleu.vv v0, v0, v1  // Unsigned less than or equal
  vmv.x.s a0, v0
end;

function RISCVVCmpGtU32x4(const a, b: TVecU32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmsltu.vv v0, v1, v0  // Unsigned greater than
  vmv.x.s a0, v0
end;

// =============================================================
// I16x8 Operations (128-bit, 8x Int16)
// =============================================================

function RISCVVAddI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vadd.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVSubI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vsub.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVMulI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmul.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVMinI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmin.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVMaxI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmax.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVAndI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vand.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVOrI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vor.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVXorI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vxor.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVShiftLeftI16x8(const a: TVecI16x8; count: Integer): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vsll.vx v0, v0, a1
  vse16.v v0, (a0)
end;

function RISCVVShiftRightI16x8(const a: TVecI16x8; count: Integer): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vsrl.vx v0, v0, a1
  vse16.v v0, (a0)
end;

function RISCVVShiftRightArithI16x8(const a: TVecI16x8; count: Integer): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vsra.vx v0, v0, a1
  vse16.v v0, (a0)
end;

// =============================================================
// I8x16 Operations (128-bit, 16x Int8)
// =============================================================

function RISCVVAddI8x16(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vadd.vv v0, v0, v1
  vse8.v v0, (a0)
end;

function RISCVVSubI8x16(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vsub.vv v0, v0, v1
  vse8.v v0, (a0)
end;

function RISCVVMinI8x16(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmin.vv v0, v0, v1
  vse8.v v0, (a0)
end;

function RISCVVMaxI8x16(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmax.vv v0, v0, v1
  vse8.v v0, (a0)
end;

function RISCVVAndI8x16(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vand.vv v0, v0, v1
  vse8.v v0, (a0)
end;

function RISCVVOrI8x16(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vor.vv v0, v0, v1
  vse8.v v0, (a0)
end;

function RISCVVXorI8x16(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
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
  vsetivli zero, 8, 0xD1   // LMUL=2 for 256-bit
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vfadd.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVSubF32x8(const a, b: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vfsub.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVMulF32x8(const a, b: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vfmul.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVDivF32x8(const a, b: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vfdiv.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVMinF32x8(const a, b: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vfmin.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVMaxF32x8(const a, b: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vfmax.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVAbsF32x8(const a: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vfsgnjx.vv v0, v0, v0
  vse32.v v0, (a0)
end;

function RISCVVSqrtF32x8(const a: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vfsqrt.v v0, v0
  vse32.v v0, (a0)
end;

function RISCVVAddF64x4(const a, b: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vfadd.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVSubF64x4(const a, b: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vfsub.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVMulF64x4(const a, b: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vfmul.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVDivF64x4(const a, b: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vfdiv.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVAddI32x8(const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vadd.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVSubI32x8(const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vsub.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVMulI32x8(const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmul.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVAndI32x8(const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vand.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVOrI32x8(const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vor.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVXorI32x8(const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
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
  vsetivli zero, 16, 0xD2  // LMUL=4 for 512-bit
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vfadd.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVSubF32x16(const a, b: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vfsub.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVMulF32x16(const a, b: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vfmul.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVDivF32x16(const a, b: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vfdiv.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVAddI32x16(const a, b: TVecI32x16): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vadd.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVSubI32x16(const a, b: TVecI32x16): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vsub.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVMulI32x16(const a, b: TVecI32x16): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
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
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  // RVV 没有直接的 floor，使用 fcvt 舍入模式
  // 先转整数（向负无穷舍入），再转回浮点
  vfcvt.x.f.v v1, v0      // 转为有符号整数（舍入到零）
  vfcvt.f.x.v v0, v1      // 转回浮点
  vse32.v v0, (a0)
end;

function RISCVVCeilF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vfcvt.x.f.v v1, v0
  vfcvt.f.x.v v0, v1
  vse32.v v0, (a0)
end;

function RISCVVRoundF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vfcvt.x.f.v v1, v0      // 默认舍入模式（最近偶数）
  vfcvt.f.x.v v0, v1
  vse32.v v0, (a0)
end;

function RISCVVTruncF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vfcvt.rtz.x.f.v v1, v0  // 向零舍入
  vfcvt.f.x.v v0, v1
  vse32.v v0, (a0)
end;

function RISCVVClampF32x4(const a, minVal, maxVal: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
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
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  // 使用向量规约加法
  vmv.s.x v1, zero        // 初始值 0
  vfredusum.vs v1, v0, v1 // 规约加法
  vfmv.f.s f10, v1        // 结果到浮点寄存器
end;

function RISCVVReduceMinF32x4(const a: TVecF32x4): Single; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vfredmin.vs v1, v0, v0  // 规约最小值
  vfmv.f.s f10, v1
end;

function RISCVVReduceMaxF32x4(const a: TVecF32x4): Single; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vfredmax.vs v1, v0, v0  // 规约最大值
  vfmv.f.s f10, v1
end;

function RISCVVReduceAddI32x4(const a: TVecI32x4): LongInt; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vmv.s.x v1, zero
  vredsum.vs v1, v0, v1   // 整数规约加法
  vmv.x.s a0, v1
end;

function RISCVVReduceMinI32x4(const a: TVecI32x4): LongInt; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vredmin.vs v1, v0, v0   // 有符号最小
  vmv.x.s a0, v1
end;

function RISCVVReduceMaxI32x4(const a: TVecI32x4): LongInt; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vredmax.vs v1, v0, v0   // 有符号最大
  vmv.x.s a0, v1
end;

function RISCVVReduceMinU32x4(const a: TVecU32x4): UInt32; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vredminu.vs v1, v0, v0  // 无符号最小
  vmv.x.s a0, v1
end;

function RISCVVReduceMaxU32x4(const a: TVecU32x4): UInt32; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vredmaxu.vs v1, v0, v0  // 无符号最大
  vmv.x.s a0, v1
end;

// =============================================================
// F32x4 Load/Store/Splat/Zero
// =============================================================

function RISCVVLoadF32x4(p: PSingle): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vse32.v v0, (a1)        // a1 = &Result
end;

procedure RISCVVStoreF32x4(p: PSingle; const a: TVecF32x4); assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a1)        // a1 = &a
  vse32.v v0, (a0)        // a0 = p
end;

procedure RISCVVStoreF32x4Aligned(p: PSingle; const a: TVecF32x4); assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a1)
  vse32.v v0, (a0)
end;

procedure RISCVVStoreF32x8(p: PSingle; const a: TVecF32x8); assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a1)
  vse32.v v0, (a0)
end;

procedure RISCVVStoreF32x16(p: PSingle; const a: TVecF32x16); assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a1)
  vse32.v v0, (a0)
end;

procedure RISCVVStoreF64x4(p: PDouble; const a: TVecF64x4); assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a1)
  vse64.v v0, (a0)
end;

procedure RISCVVStoreF64x8(p: PDouble; const a: TVecF64x8); assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a1)
  vse64.v v0, (a0)
end;

procedure RISCVVStoreI64x4(p: PInt64; const a: TVecI64x4); assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a1)
  vse64.v v0, (a0)
end;

function RISCVVSplatF32x4(value: Single): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vfmv.v.f v0, f10        // 广播 f10 到所有元素
  vse32.v v0, (a0)        // a0 = &Result
end;

function RISCVVZeroF32x4: TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vmv.v.i v0, 0           // 所有元素置零
  vse32.v v0, (a0)
end;

// =============================================================
// F64x2 舍入操作
// =============================================================

function RISCVVFloorF64x2(const a: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vfcvt.x.f.v v1, v0
  vfcvt.f.x.v v0, v1
  vse64.v v0, (a0)
end;

function RISCVVCeilF64x2(const a: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vfcvt.x.f.v v1, v0
  vfcvt.f.x.v v0, v1
  vse64.v v0, (a0)
end;

function RISCVVRoundF64x2(const a: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vfcvt.x.f.v v1, v0
  vfcvt.f.x.v v0, v1
  vse64.v v0, (a0)
end;

function RISCVVTruncF64x2(const a: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vfcvt.rtz.x.f.v v1, v0
  vfcvt.f.x.v v0, v1
  vse64.v v0, (a0)
end;

function RISCVVClampF64x2(const a, minVal, maxVal: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
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
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vmv.s.x v1, zero
  vfredusum.vs v1, v0, v1
  vfmv.f.s f10, v1
end;

function RISCVVReduceMinF64x2(const a: TVecF64x2): Double; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vfredmin.vs v1, v0, v0
  vfmv.f.s f10, v1
end;

function RISCVVReduceMaxF64x2(const a: TVecF64x2): Double; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vfredmax.vs v1, v0, v0
  vfmv.f.s f10, v1
end;

// =============================================================
// F64x2 Load/Store/Splat/Zero
// =============================================================

function RISCVVLoadF64x2(p: PDouble): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vse64.v v0, (a1)
end;

procedure RISCVVStoreF64x2(p: PDouble; const a: TVecF64x2); assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a1)
  vse64.v v0, (a0)
end;

function RISCVVSplatF64x2(value: Double): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vfmv.v.f v0, f10
  vse64.v v0, (a0)
end;

function RISCVVZeroF64x2: TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vmv.v.i v0, 0
  vse64.v v0, (a0)
end;

// =============================================================
// I32x4 Load/Store/Splat/Zero
// =============================================================

function RISCVVLoadI32x4(p: PLongInt): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vse32.v v0, (a1)
end;

procedure RISCVVStoreI32x4(p: PLongInt; const a: TVecI32x4); assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a1)
  vse32.v v0, (a0)
end;

function RISCVVSplatI32x4(value: LongInt): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vmv.v.x v0, a0          // 广播整数到所有元素
  vse32.v v0, (a1)        // a1 = &Result
end;

function RISCVVZeroI32x4: TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vmv.v.i v0, 0
  vse32.v v0, (a0)
end;

// =============================================================
// I64x2 Load/Store/Splat/Zero
// =============================================================

function RISCVVLoadI64x2(p: PInt64): TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vse64.v v0, (a1)
end;

procedure RISCVVStoreI64x2(p: PInt64; const a: TVecI64x2); assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a1)
  vse64.v v0, (a0)
end;

function RISCVVSplatI64x2(value: Int64): TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vmv.v.x v0, a0
  vse64.v v0, (a1)
end;

function RISCVVZeroI64x2: TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vmv.v.i v0, 0
  vse64.v v0, (a0)
end;

// =============================================================
// U32x4 扩展操作
// =============================================================

function RISCVVAndU32x4(const a, b: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vand.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVOrU32x4(const a, b: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vor.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVXorU32x4(const a, b: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vxor.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVNotU32x4(const a: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vxor.vi v0, v0, -1
  vse32.v v0, (a0)
end;

function RISCVVShiftLeftU32x4(const a: TVecU32x4; count: Integer): TVecU32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vsll.vx v0, v0, a1
  vse32.v v0, (a0)
end;

function RISCVVShiftRightU32x4(const a: TVecU32x4; count: Integer): TVecU32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vsrl.vx v0, v0, a1
  vse32.v v0, (a0)
end;

function RISCVVCmpEqU32x4(const a, b: TVecU32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmseq.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpNeU32x4(const a, b: TVecU32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmsne.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpGeU32x4(const a, b: TVecU32x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmsltu.vv v0, v0, v1    // a < b
  vmnand.mm v0, v0, v0          // NOT -> a >= b
  vmv.x.s a0, v0
end;

// =============================================================
// U64x2 操作
// =============================================================

function RISCVVAddU64x2(const a, b: TVecU64x2): TVecU64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vadd.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVSubU64x2(const a, b: TVecU64x2): TVecU64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vsub.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVAndU64x2(const a, b: TVecU64x2): TVecU64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vand.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVOrU64x2(const a, b: TVecU64x2): TVecU64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vor.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVXorU64x2(const a, b: TVecU64x2): TVecU64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vxor.vv v0, v0, v1
  vse64.v v0, (a0)
end;

function RISCVVNotU64x2(const a: TVecU64x2): TVecU64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vxor.vi v0, v0, -1
  vse64.v v0, (a0)
end;

function RISCVVShiftLeftU64x2(const a: TVecU64x2; count: Integer): TVecU64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vsll.vx v0, v0, a1
  vse64.v v0, (a0)
end;

function RISCVVShiftRightU64x2(const a: TVecU64x2; count: Integer): TVecU64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vsrl.vx v0, v0, a1
  vse64.v v0, (a0)
end;

// =============================================================
// U16x8 操作
// =============================================================

function RISCVVAddU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vadd.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVSubU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vsub.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVMulU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmul.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVMinU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vminu.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVMaxU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmaxu.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVAndU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vand.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVOrU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vor.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVXorU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vxor.vv v0, v0, v1
  vse16.v v0, (a0)
end;

function RISCVVShiftLeftU16x8(const a: TVecU16x8; count: Integer): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vsll.vx v0, v0, a1
  vse16.v v0, (a0)
end;

function RISCVVShiftRightU16x8(const a: TVecU16x8; count: Integer): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vsrl.vx v0, v0, a1
  vse16.v v0, (a0)
end;

// =============================================================
// U8x16 操作
// =============================================================

function RISCVVAddU8x16(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vadd.vv v0, v0, v1
  vse8.v v0, (a0)
end;

function RISCVVSubU8x16(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vsub.vv v0, v0, v1
  vse8.v v0, (a0)
end;

function RISCVVMinU8x16(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vminu.vv v0, v0, v1
  vse8.v v0, (a0)
end;

function RISCVVMaxU8x16(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmaxu.vv v0, v0, v1
  vse8.v v0, (a0)
end;

function RISCVVAndU8x16(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vand.vv v0, v0, v1
  vse8.v v0, (a0)
end;

function RISCVVOrU8x16(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vor.vv v0, v0, v1
  vse8.v v0, (a0)
end;

function RISCVVXorU8x16(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
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
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vmseq.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLtI64x2(const a, b: TVecI64x2): TMask2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vmslt.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLeI64x2(const a, b: TVecI64x2): TMask2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vmsle.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpGtI64x2(const a, b: TVecI64x2): TMask2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vmslt.vv v0, v1, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpNeI64x2(const a, b: TVecI64x2): TMask2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vmsne.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVAndNotI64x2(const a, b: TVecI64x2): TVecI64x2;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    Result.i[LIndex] := (not a.i[LIndex]) and b.i[LIndex];
end;

function RISCVVMinI64x2(const a, b: TVecI64x2): TVecI64x2;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    if a.i[LIndex] < b.i[LIndex] then
      Result.i[LIndex] := a.i[LIndex]
    else
      Result.i[LIndex] := b.i[LIndex];
end;

function RISCVVMaxI64x2(const a, b: TVecI64x2): TVecI64x2;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    if a.i[LIndex] > b.i[LIndex] then
      Result.i[LIndex] := a.i[LIndex]
    else
      Result.i[LIndex] := b.i[LIndex];
end;

function RISCVVAndNotU64x2(const a, b: TVecU64x2): TVecU64x2;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    Result.u[LIndex] := (not a.u[LIndex]) and b.u[LIndex];
end;

function RISCVVCmpEqU64x2(const a, b: TVecU64x2): TMask2;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to 1 do
    if a.u[LIndex] = b.u[LIndex] then
      Result := Result or (1 shl LIndex);
end;

function RISCVVCmpLtU64x2(const a, b: TVecU64x2): TMask2;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to 1 do
    if a.u[LIndex] < b.u[LIndex] then
      Result := Result or (1 shl LIndex);
end;

function RISCVVCmpGtU64x2(const a, b: TVecU64x2): TMask2;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to 1 do
    if a.u[LIndex] > b.u[LIndex] then
      Result := Result or (1 shl LIndex);
end;

function RISCVVMinU64x2(const a, b: TVecU64x2): TVecU64x2;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    if a.u[LIndex] < b.u[LIndex] then
      Result.u[LIndex] := a.u[LIndex]
    else
      Result.u[LIndex] := b.u[LIndex];
end;

function RISCVVMaxU64x2(const a, b: TVecU64x2): TVecU64x2;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    if a.u[LIndex] > b.u[LIndex] then
      Result.u[LIndex] := a.u[LIndex]
    else
      Result.u[LIndex] := b.u[LIndex];
end;

// =============================================================
// F64x2 比较操作
// =============================================================

function RISCVVCmpEqF64x2(const a, b: TVecF64x2): TMask2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vmfeq.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLtF64x2(const a, b: TVecF64x2): TMask2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vmflt.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLeF64x2(const a, b: TVecF64x2): TMask2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vmfle.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpGtF64x2(const a, b: TVecF64x2): TMask2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vmflt.vv v0, v1, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpGeF64x2(const a, b: TVecF64x2): TMask2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vmfle.vv v0, v1, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpNeF64x2(const a, b: TVecF64x2): TMask2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
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
  vsetivli zero, 4, 0xD0
  vmv.s.x v0, a0          // mask to v0
  vle32.v v1, (a1)        // a
  vle32.v v2, (a2)        // b
  vmerge.vvm v1, v2, v1, v0  // v1 = mask ? a : b
  vse32.v v1, (a3)        // store result
end;

function RISCVVSelectF64x2(const mask: TMask2; const a, b: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vmv.s.x v0, a0
  vle64.v v1, (a1)
  vle64.v v2, (a2)
  vmerge.vvm v1, v2, v1, v0
  vse64.v v1, (a3)
end;

function RISCVVSelectI32x4(const mask: TVecI32x4; const a, b: TVecI32x4): TVecI32x4;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    if mask.i[LIndex] <> 0 then
      Result.i[LIndex] := a.i[LIndex]
    else
      Result.i[LIndex] := b.i[LIndex];
end;

function RISCVVSelectI64x2(const mask: TMask2; const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
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
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vle32.v v4, (a2)
  vfmadd.vv v0, v2, v4
  vse32.v v0, (a0)
end;

function RISCVVMinF64x4(const a, b: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vfmin.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVMaxF64x4(const a, b: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vfmax.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVAbsF64x4(const a: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vfsgnjx.vv v0, v0, v0
  vse64.v v0, (a0)
end;

function RISCVVSqrtF64x4(const a: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vfsqrt.v v0, v0
  vse64.v v0, (a0)
end;

function RISCVVMinI32x8(const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmin.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVMaxI32x8(const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmax.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVNotI32x8(const a: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vxor.vi v0, v0, -1
  vse32.v v0, (a0)
end;

function RISCVVShiftLeftI32x8(const a: TVecI32x8; count: Integer): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vsll.vx v0, v0, a1
  vse32.v v0, (a0)
end;

function RISCVVShiftRightI32x8(const a: TVecI32x8; count: Integer): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vsrl.vx v0, v0, a1
  vse32.v v0, (a0)
end;

function RISCVVShiftRightArithI32x8(const a: TVecI32x8; count: Integer): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vsra.vx v0, v0, a1
  vse32.v v0, (a0)
end;

// =============================================================
// 512-bit 扩展操作
// =============================================================

function RISCVVMinF32x16(const a, b: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vfmin.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVMaxF32x16(const a, b: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vfmax.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVAbsF32x16(const a: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vfsgnjx.vv v0, v0, v0
  vse32.v v0, (a0)
end;

function RISCVVSqrtF32x16(const a: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vfsqrt.v v0, v0
  vse32.v v0, (a0)
end;

function RISCVVAndI32x16(const a, b: TVecI32x16): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vand.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVOrI32x16(const a, b: TVecI32x16): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vor.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVXorI32x16(const a, b: TVecI32x16): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vxor.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVMinI32x16(const a, b: TVecI32x16): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmin.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVMaxI32x16(const a, b: TVecI32x16): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmax.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVShiftLeftI32x16(const a: TVecI32x16; count: Integer): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vsll.vx v0, v0, a1
  vse32.v v0, (a0)
end;

function RISCVVShiftRightI32x16(const a: TVecI32x16; count: Integer): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vsrl.vx v0, v0, a1
  vse32.v v0, (a0)
end;

// =============================================================
// F64x8 (512-bit) 操作
// =============================================================

function RISCVVAddF64x8(const a, b: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vfadd.vv v0, v0, v4
  vse64.v v0, (a0)
end;

function RISCVVSubF64x8(const a, b: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vfsub.vv v0, v0, v4
  vse64.v v0, (a0)
end;

function RISCVVMulF64x8(const a, b: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vfmul.vv v0, v0, v4
  vse64.v v0, (a0)
end;

function RISCVVDivF64x8(const a, b: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vfdiv.vv v0, v0, v4
  vse64.v v0, (a0)
end;

function RISCVVMinF64x8(const a, b: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vfmin.vv v0, v0, v4
  vse64.v v0, (a0)
end;

function RISCVVMaxF64x8(const a, b: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vfmax.vv v0, v0, v4
  vse64.v v0, (a0)
end;

function RISCVVAbsF64x8(const a: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vfsgnjx.vv v0, v0, v0
  vse64.v v0, (a0)
end;

function RISCVVSqrtF64x8(const a: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vfsqrt.v v0, v0
  vse64.v v0, (a0)
end;

// =============================================================
// I64x4 操作 (256-bit, 4x Int64)
// =============================================================

function RISCVVAddI64x4(const a, b: TVecI64x4): TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vadd.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVSubI64x4(const a, b: TVecI64x4): TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vsub.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVAndI64x4(const a, b: TVecI64x4): TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vand.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVOrI64x4(const a, b: TVecI64x4): TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vor.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVXorI64x4(const a, b: TVecI64x4): TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vxor.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVNotI64x4(const a: TVecI64x4): TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vxor.vi v0, v0, -1
  vse64.v v0, (a0)
end;

function RISCVVAndNotI64x4(const a, b: TVecI64x4): TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vxor.vi v0, v0, -1
  vand.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVShiftLeftI64x4(const a: TVecI64x4; count: Integer): TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vsll.vx v0, v0, a1
  vse64.v v0, (a0)
end;

function RISCVVShiftRightI64x4(const a: TVecI64x4; count: Integer): TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vsrl.vx v0, v0, a1
  vse64.v v0, (a0)
end;

function RISCVVShiftRightArithI64x4(const a: TVecI64x4; count: Integer): TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vsra.vx v0, v0, a1
  vse64.v v0, (a0)
end;

function RISCVVCmpEqI64x4(const a, b: TVecI64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmseq.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpLtI64x4(const a, b: TVecI64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmslt.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpLeI64x4(const a, b: TVecI64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmsle.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpGtI64x4(const a, b: TVecI64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmslt.vv v0, v2, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpGeI64x4(const a, b: TVecI64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmslt.vv v0, v0, v2
  vmnand.mm v0, v0, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpNeI64x4(const a, b: TVecI64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
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
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vadd.vv v0, v0, v4
  vse64.v v0, (a0)
end;

function RISCVVSubI64x8(const a, b: TVecI64x8): TVecI64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vsub.vv v0, v0, v4
  vse64.v v0, (a0)
end;

function RISCVVAndI64x8(const a, b: TVecI64x8): TVecI64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vand.vv v0, v0, v4
  vse64.v v0, (a0)
end;

function RISCVVOrI64x8(const a, b: TVecI64x8): TVecI64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vor.vv v0, v0, v4
  vse64.v v0, (a0)
end;

function RISCVVXorI64x8(const a, b: TVecI64x8): TVecI64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vxor.vv v0, v0, v4
  vse64.v v0, (a0)
end;

function RISCVVCmpEqI64x8(const a, b: TVecI64x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vmseq.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpLtI64x8(const a, b: TVecI64x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vmslt.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpLeI64x8(const a, b: TVecI64x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vmsle.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpGtI64x8(const a, b: TVecI64x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vmslt.vv v0, v4, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpGeI64x8(const a, b: TVecI64x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vmslt.vv v0, v0, v4
  vmnand.mm v0, v0, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpNeI64x8(const a, b: TVecI64x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
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
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vadd.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVSubU64x4(const a, b: TVecU64x4): TVecU64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vsub.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVAndU64x4(const a, b: TVecU64x4): TVecU64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vand.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVOrU64x4(const a, b: TVecU64x4): TVecU64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vor.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVXorU64x4(const a, b: TVecU64x4): TVecU64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vxor.vv v0, v0, v2
  vse64.v v0, (a0)
end;

function RISCVVCmpEqU64x4(const a, b: TVecU64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmseq.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpLtU64x4(const a, b: TVecU64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmsltu.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpLeU64x4(const a, b: TVecU64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmsleu.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpGtU64x4(const a, b: TVecU64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmsltu.vv v0, v2, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpGeU64x4(const a, b: TVecU64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmsltu.vv v0, v0, v2
  vmnand.mm v0, v0, v0
  vmv.x.s a0, v0
end;

// =============================================================
// U32x8 操作 (256-bit, 8x UInt32)
// =============================================================

function RISCVVAddU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vadd.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVSubU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vsub.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVMulU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmul.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVAndU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vand.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVOrU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vor.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVXorU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vxor.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVMinU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vminu.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVMaxU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmaxu.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVCmpEqU32x8(const a, b: TVecU32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmseq.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpLtU32x8(const a, b: TVecU32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmsltu.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpLeU32x8(const a, b: TVecU32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmsleu.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpGtU32x8(const a, b: TVecU32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmsltu.vv v0, v2, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpGeU32x8(const a, b: TVecU32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmsltu.vv v0, v0, v2
  vmnand.mm v0, v0, v0
  vmv.x.s a0, v0
end;

// =============================================================
// AndNot 扩展操作
// =============================================================

function RISCVVAndNotI32x8(const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vxor.vi v0, v0, -1
  vand.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVAndNotI32x16(const a, b: TVecI32x16): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vxor.vi v0, v0, -1
  vand.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVAndNotU32x4(const a, b: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vxor.vi v0, v0, -1
  vand.vv v0, v0, v1
  vse32.v v0, (a0)
end;

function RISCVVAndNotU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vxor.vi v0, v0, -1
  vand.vv v0, v0, v2
  vse32.v v0, (a0)
end;

function RISCVVAndNotI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vxor.vi v0, v0, -1
  vand.vv v0, v0, v1
  vse16.v v0, (a0)
end;

// =============================================================
// 256-bit 舍入/Clamp 操作
// =============================================================

function RISCVVFloorF32x8(const a: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vfcvt.x.f.v v2, v0
  vfcvt.f.x.v v0, v2
  vse32.v v0, (a0)
end;

function RISCVVCeilF32x8(const a: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vfcvt.x.f.v v2, v0
  vfcvt.f.x.v v0, v2
  vse32.v v0, (a0)
end;

function RISCVVRoundF32x8(const a: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vfcvt.x.f.v v2, v0
  vfcvt.f.x.v v0, v2
  vse32.v v0, (a0)
end;

function RISCVVTruncF32x8(const a: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vfcvt.rtz.x.f.v v2, v0
  vfcvt.f.x.v v0, v2
  vse32.v v0, (a0)
end;

function RISCVVClampF32x8(const a, minVal, maxVal: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vle32.v v4, (a2)
  vfmax.vv v0, v0, v2
  vfmin.vv v0, v0, v4
  vse32.v v0, (a0)
end;

function RISCVVFloorF64x4(const a: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vfcvt.x.f.v v2, v0
  vfcvt.f.x.v v0, v2
  vse64.v v0, (a0)
end;

function RISCVVCeilF64x4(const a: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vfcvt.x.f.v v2, v0
  vfcvt.f.x.v v0, v2
  vse64.v v0, (a0)
end;

function RISCVVRoundF64x4(const a: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vfcvt.x.f.v v2, v0
  vfcvt.f.x.v v0, v2
  vse64.v v0, (a0)
end;

function RISCVVTruncF64x4(const a: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vfcvt.rtz.x.f.v v2, v0
  vfcvt.f.x.v v0, v2
  vse64.v v0, (a0)
end;

function RISCVVClampF64x4(const a, minVal, maxVal: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
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
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vfcvt.x.f.v v4, v0
  vfcvt.f.x.v v0, v4
  vse32.v v0, (a0)
end;

function RISCVVCeilF32x16(const a: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vfcvt.x.f.v v4, v0
  vfcvt.f.x.v v0, v4
  vse32.v v0, (a0)
end;

function RISCVVRoundF32x16(const a: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vfcvt.x.f.v v4, v0
  vfcvt.f.x.v v0, v4
  vse32.v v0, (a0)
end;

function RISCVVTruncF32x16(const a: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vfcvt.rtz.x.f.v v4, v0
  vfcvt.f.x.v v0, v4
  vse32.v v0, (a0)
end;

function RISCVVClampF32x16(const a, minVal, maxVal: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vle32.v v8, (a2)
  vfmax.vv v0, v0, v4
  vfmin.vv v0, v0, v8
  vse32.v v0, (a0)
end;

function RISCVVFloorF64x8(const a: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vfcvt.x.f.v v4, v0
  vfcvt.f.x.v v0, v4
  vse64.v v0, (a0)
end;

function RISCVVCeilF64x8(const a: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vfcvt.x.f.v v4, v0
  vfcvt.f.x.v v0, v4
  vse64.v v0, (a0)
end;

function RISCVVRoundF64x8(const a: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vfcvt.x.f.v v4, v0
  vfcvt.f.x.v v0, v4
  vse64.v v0, (a0)
end;

function RISCVVTruncF64x8(const a: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vfcvt.rtz.x.f.v v4, v0
  vfcvt.f.x.v v0, v4
  vse64.v v0, (a0)
end;

function RISCVVClampF64x8(const a, minVal, maxVal: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
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
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmfeq.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpLtF32x8(const a, b: TVecF32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmflt.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpLeF32x8(const a, b: TVecF32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmfle.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpGtF32x8(const a, b: TVecF32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmflt.vv v0, v2, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpGeF32x8(const a, b: TVecF32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmfle.vv v0, v2, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpNeF32x8(const a, b: TVecF32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmfne.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpEqF64x4(const a, b: TVecF64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmfeq.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpLtF64x4(const a, b: TVecF64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmflt.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpLeF64x4(const a, b: TVecF64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmfle.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpGtF64x4(const a, b: TVecF64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmflt.vv v0, v2, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpGeF64x4(const a, b: TVecF64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmfle.vv v0, v2, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpNeF64x4(const a, b: TVecF64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vmfne.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpEqI32x8(const a, b: TVecI32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmseq.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpLtI32x8(const a, b: TVecI32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmslt.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpLeI32x8(const a, b: TVecI32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmsle.vv v0, v0, v2
  vmv.x.s a0, v0
end;

function RISCVVCmpGtI32x8(const a, b: TVecI32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmslt.vv v0, v2, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpGeI32x8(const a, b: TVecI32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v2, (a1)
  vmslt.vv v0, v0, v2
  vmnand.mm v0, v0, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpNeI32x8(const a, b: TVecI32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
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
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmseq.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpLtI32x16(const a, b: TVecI32x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmslt.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpLeI32x16(const a, b: TVecI32x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmsle.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpGtI32x16(const a, b: TVecI32x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmslt.vv v0, v4, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpGeI32x16(const a, b: TVecI32x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmslt.vv v0, v0, v4
  vmnand.mm v0, v0, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpNeI32x16(const a, b: TVecI32x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
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
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmseq.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLtI16x8(const a, b: TVecI16x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmslt.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLeI16x8(const a, b: TVecI16x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmsle.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpGtI16x8(const a, b: TVecI16x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmslt.vv v0, v1, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpGeI16x8(const a, b: TVecI16x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmslt.vv v0, v0, v1
  vmnand.mm v0, v0, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpNeI16x8(const a, b: TVecI16x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmsne.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpEqI8x16(const a, b: TVecI8x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmseq.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLtI8x16(const a, b: TVecI8x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmslt.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLeI8x16(const a, b: TVecI8x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmsle.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpGtI8x16(const a, b: TVecI8x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmslt.vv v0, v1, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpGeI8x16(const a, b: TVecI8x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmslt.vv v0, v0, v1
  vmnand.mm v0, v0, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpNeI8x16(const a, b: TVecI8x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
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
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmseq.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLtU16x8(const a, b: TVecU16x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmsltu.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLeU16x8(const a, b: TVecU16x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmsleu.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpGtU16x8(const a, b: TVecU16x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmsltu.vv v0, v1, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpGeU16x8(const a, b: TVecU16x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmsltu.vv v0, v0, v1
  vmnand.mm v0, v0, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpEqU8x16(const a, b: TVecU8x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmseq.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLtU8x16(const a, b: TVecU8x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmsltu.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpLeU8x16(const a, b: TVecU8x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmsleu.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpGtU8x16(const a, b: TVecU8x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmsltu.vv v0, v1, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpGeU8x16(const a, b: TVecU8x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmsltu.vv v0, v0, v1
  vmnand.mm v0, v0, v0
  vmv.x.s a0, v0
end;

// =============================================================
// 512-bit 比较操作
// =============================================================

function RISCVVCmpEqF32x16(const a, b: TVecF32x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmfeq.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpLtF32x16(const a, b: TVecF32x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmflt.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpLeF32x16(const a, b: TVecF32x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmfle.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpGtF32x16(const a, b: TVecF32x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmflt.vv v0, v4, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpGeF32x16(const a, b: TVecF32x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmfle.vv v0, v4, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpNeF32x16(const a, b: TVecF32x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vmfne.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpEqF64x8(const a, b: TVecF64x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vmfeq.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpLtF64x8(const a, b: TVecF64x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vmflt.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpLeF64x8(const a, b: TVecF64x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vmfle.vv v0, v0, v4
  vmv.x.s a0, v0
end;

function RISCVVCmpGtF64x8(const a, b: TVecF64x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vmflt.vv v0, v4, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpGeF64x8(const a, b: TVecF64x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vmfle.vv v0, v4, v0
  vmv.x.s a0, v0
end;

function RISCVVCmpNeF64x8(const a, b: TVecF64x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
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
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v2, (a1)
  vle64.v v4, (a2)
  vfmadd.vv v0, v2, v4
  vse64.v v0, (a0)
end;

function RISCVVFmaF32x16(const a, b, c: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vle32.v v4, (a1)
  vle32.v v8, (a2)
  vfmadd.vv v0, v4, v8
  vse32.v v0, (a0)
end;

function RISCVVFmaF64x8(const a, b, c: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vle64.v v4, (a1)
  vle64.v v8, (a2)
  vfmadd.vv v0, v4, v8
  vse64.v v0, (a0)
end;

// =============================================================
// Select 256-bit/512-bit 操作
// =============================================================

function RISCVVSelectF32x8(const mask: TVecU32x8; const a, b: TVecF32x8): TVecF32x8;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
    if mask.u[LIndex] <> 0 then
      Result.f[LIndex] := a.f[LIndex]
    else
      Result.f[LIndex] := b.f[LIndex];
end;

function RISCVVSelectF64x4(const mask: TVecU64x4; const a, b: TVecF64x4): TVecF64x4;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    if mask.u[LIndex] <> 0 then
      Result.d[LIndex] := a.d[LIndex]
    else
      Result.d[LIndex] := b.d[LIndex];
end;

function RISCVVSelectI32x8(const mask: TMask8; const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vmv.s.x v0, a0
  vle32.v v2, (a1)
  vle32.v v4, (a2)
  vmerge.vvm v2, v4, v2, v0
  vse32.v v2, (a3)
end;

function RISCVVSelectF32x16(const mask: TMask16; const a, b: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vmv.s.x v0, a0
  vle32.v v4, (a1)
  vle32.v v8, (a2)
  vmerge.vvm v4, v8, v4, v0
  vse32.v v4, (a3)
end;

function RISCVVSelectI32x16(const mask: TMask16; const a, b: TVecI32x16): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vmv.s.x v0, a0
  vle32.v v4, (a1)
  vle32.v v8, (a2)
  vmerge.vvm v4, v8, v4, v0
  vse32.v v4, (a3)
end;

function RISCVVSelectF64x8(const mask: TMask8; const a, b: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vmv.s.x v0, a0
  vle64.v v4, (a1)
  vle64.v v8, (a2)
  vmerge.vvm v4, v8, v4, v0
  vse64.v v4, (a3)
end;

// =============================================================
// 256-bit/512-bit Load/Store/Splat/Zero Operations
// =============================================================

function RISCVVLoadF32x8(p: PSingle): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vse32.v v0, (a1)
end;

function RISCVVLoadF32x16(p: PSingle): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vse32.v v0, (a1)
end;

function RISCVVLoadF64x4(p: PDouble): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vse64.v v0, (a1)
end;

function RISCVVLoadF64x8(p: PDouble): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vse64.v v0, (a1)
end;

function RISCVVLoadI64x4(p: PInt64): TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vse64.v v0, (a1)
end;

function RISCVVLoadF32x4Aligned(p: PSingle): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vse32.v v0, (a1)
end;

function RISCVVSplatF32x8(value: Single): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vfmv.v.f v0, f10
  vse32.v v0, (a0)
end;

function RISCVVSplatF32x16(value: Single): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vfmv.v.f v0, f10
  vse32.v v0, (a0)
end;

function RISCVVSplatF64x4(value: Double): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vfmv.v.f v0, f10
  vse64.v v0, (a0)
end;

function RISCVVSplatF64x8(value: Double): TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vfmv.v.f v0, f10
  vse64.v v0, (a0)
end;

function RISCVVSplatI64x4(value: Int64): TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vmv.v.x v0, a0
  vse64.v v0, (a1)
end;

function RISCVVZeroF32x8: TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vmv.v.i v0, 0
  vse32.v v0, (a0)
end;

function RISCVVZeroF32x16: TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vmv.v.i v0, 0
  vse32.v v0, (a0)
end;

function RISCVVZeroF64x4: TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vmv.v.i v0, 0
  vse64.v v0, (a0)
end;

function RISCVVZeroF64x8: TVecF64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vmv.v.i v0, 0
  vse64.v v0, (a0)
end;

function RISCVVZeroI64x4: TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vmv.v.i v0, 0
  vse64.v v0, (a0)
end;

// =============================================================
// 256-bit/512-bit Reduction Operations
// =============================================================

function RISCVVReduceAddF32x8(const a: TVecF32x8): Single; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vfmv.s.f v2, f10            // f10 = 0.0 initial value
  vfredusum.vs v2, v0, v2
  vfmv.f.s f10, v2
end;

function RISCVVReduceAddF32x16(const a: TVecF32x16): Single; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vfmv.s.f v4, f10
  vfredusum.vs v4, v0, v4
  vfmv.f.s f10, v4
end;

function RISCVVReduceAddF64x4(const a: TVecF64x4): Double; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vfmv.s.f v2, f10
  vfredusum.vs v2, v0, v2
  vfmv.f.s f10, v2
end;

function RISCVVReduceAddF64x8(const a: TVecF64x8): Double; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vfmv.s.f v4, f10
  vfredusum.vs v4, v0, v4
  vfmv.f.s f10, v4
end;

function RISCVVReduceMinF32x8(const a: TVecF32x8): Single; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vmv.v.x v2, zero
  lui t0, 0x7F800            // +Infinity as initial
  vmv.s.x v2, t0
  vfredmin.vs v2, v0, v2
  vfmv.f.s f10, v2
end;

function RISCVVReduceMinF32x16(const a: TVecF32x16): Single; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vmv.v.x v4, zero
  lui t0, 0x7F800
  vmv.s.x v4, t0
  vfredmin.vs v4, v0, v4
  vfmv.f.s f10, v4
end;

function RISCVVReduceMinF64x4(const a: TVecF64x4): Double; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  li t0, 0x7FF0000000000000  // +Infinity
  vmv.v.x v2, zero
  vmv.s.x v2, t0
  vfredmin.vs v2, v0, v2
  vfmv.f.s f10, v2
end;

function RISCVVReduceMinF64x8(const a: TVecF64x8): Double; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  li t0, 0x7FF0000000000000
  vmv.v.x v4, zero
  vmv.s.x v4, t0
  vfredmin.vs v4, v0, v4
  vfmv.f.s f10, v4
end;

function RISCVVReduceMaxF32x8(const a: TVecF32x8): Single; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vmv.v.x v2, zero
  lui t0, 0xFF800            // -Infinity as initial
  vmv.s.x v2, t0
  vfredmax.vs v2, v0, v2
  vfmv.f.s f10, v2
end;

function RISCVVReduceMaxF32x16(const a: TVecF32x16): Single; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vmv.v.x v4, zero
  lui t0, 0xFF800
  vmv.s.x v4, t0
  vfredmax.vs v4, v0, v4
  vfmv.f.s f10, v4
end;

function RISCVVReduceMaxF64x4(const a: TVecF64x4): Double; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  li t0, 0xFFF0000000000000  // -Infinity
  vmv.v.x v2, zero
  vmv.s.x v2, t0
  vfredmax.vs v2, v0, v2
  vfmv.f.s f10, v2
end;

function RISCVVReduceMaxF64x8(const a: TVecF64x8): Double; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  li t0, 0xFFF0000000000000
  vmv.v.x v4, zero
  vmv.s.x v4, t0
  vfredmax.vs v4, v0, v4
  vfmv.f.s f10, v4
end;

// ReduceMul 使用连续乘法实现
function RISCVVReduceMulF32x4(const a: TVecF32x4): Single; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vslidedown.vi v1, v0, 2    // [2,3,x,x]
  vfmul.vv v0, v0, v1        // [0*2, 1*3, x, x]
  vslidedown.vi v1, v0, 1    // [1*3,x,x,x]
  vfmul.vv v0, v0, v1        // [(0*2)*(1*3), ...]
  vfmv.f.s f10, v0
end;

function RISCVVReduceMulF32x8(const a: TVecF32x8): Single; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vslidedown.vi v2, v0, 4
  vfmul.vv v0, v0, v2
  vsetivli zero, 4, 0xD0
  vslidedown.vi v1, v0, 2
  vfmul.vv v0, v0, v1
  vslidedown.vi v1, v0, 1
  vfmul.vv v0, v0, v1
  vfmv.f.s f10, v0
end;

function RISCVVReduceMulF32x16(const a: TVecF32x16): Single; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vslidedown.vi v4, v0, 8
  vfmul.vv v0, v0, v4
  vsetivli zero, 8, 0xD1
  vslidedown.vi v2, v0, 4
  vfmul.vv v0, v0, v2
  vsetivli zero, 4, 0xD0
  vslidedown.vi v1, v0, 2
  vfmul.vv v0, v0, v1
  vslidedown.vi v1, v0, 1
  vfmul.vv v0, v0, v1
  vfmv.f.s f10, v0
end;

function RISCVVReduceMulF64x2(const a: TVecF64x2): Double; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vslidedown.vi v1, v0, 1
  vfmul.vv v0, v0, v1
  vfmv.f.s f10, v0
end;

function RISCVVReduceMulF64x4(const a: TVecF64x4): Double; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vslidedown.vi v2, v0, 2
  vfmul.vv v0, v0, v2
  vsetivli zero, 2, 0xD8
  vslidedown.vi v1, v0, 1
  vfmul.vv v0, v0, v1
  vfmv.f.s f10, v0
end;

function RISCVVReduceMulF64x8(const a: TVecF64x8): Double; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vslidedown.vi v4, v0, 4
  vfmul.vv v0, v0, v4
  vsetivli zero, 4, 0xD9
  vslidedown.vi v2, v0, 2
  vfmul.vv v0, v0, v2
  vsetivli zero, 2, 0xD8
  vslidedown.vi v1, v0, 1
  vfmul.vv v0, v0, v1
  vfmv.f.s f10, v0
end;

// =============================================================
// Bitwise NOT Operations
// =============================================================

function RISCVVNotI16x8(const a: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vxor.vi v0, v0, -1
  vse16.v v0, (a1)
end;

function RISCVVNotI8x16(const a: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vxor.vi v0, v0, -1
  vse8.v v0, (a1)
end;

function RISCVVNotU16x8(const a: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vxor.vi v0, v0, -1
  vse16.v v0, (a1)
end;

function RISCVVNotU8x16(const a: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vxor.vi v0, v0, -1
  vse8.v v0, (a1)
end;

function RISCVVNotI32x16(const a: TVecI32x16): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vxor.vi v0, v0, -1
  vse32.v v0, (a1)
end;

function RISCVVNotI64x8(const a: TVecI64x8): TVecI64x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xDA
  vle64.v v0, (a0)
  vxor.vi v0, v0, -1
  vse64.v v0, (a1)
end;

function RISCVVNotU32x8(const a: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vxor.vi v0, v0, -1
  vse32.v v0, (a1)
end;

function RISCVVNotU64x4(const a: TVecU64x4): TVecU64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vxor.vi v0, v0, -1
  vse64.v v0, (a1)
end;

// =============================================================
// Unsigned Shift Operations (256-bit)
// =============================================================

function RISCVVShiftLeftU32x8(const a: TVecU32x8; shift: Integer): TVecU32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vsll.vx v0, v0, a1
  vse32.v v0, (a2)
end;

function RISCVVShiftRightU32x8(const a: TVecU32x8; shift: Integer): TVecU32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vsrl.vx v0, v0, a1
  vse32.v v0, (a2)
end;

function RISCVVShiftLeftU64x4(const a: TVecU64x4; shift: Integer): TVecU64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vsll.vx v0, v0, a1
  vse64.v v0, (a2)
end;

function RISCVVShiftRightU64x4(const a: TVecU64x4; shift: Integer): TVecU64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vsrl.vx v0, v0, a1
  vse64.v v0, (a2)
end;

function RISCVVShiftRightArithI32x16(const a: TVecI32x16; shift: Integer): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vsra.vx v0, v0, a1
  vse32.v v0, (a2)
end;

// =============================================================
// Unsigned Comparison Not Equal
// =============================================================

function RISCVVCmpNeU16x8(const a, b: TVecU16x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vmsne.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpNeU8x16(const a, b: TVecU8x16): TMask16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vmsne.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpNeU32x8(const a, b: TVecU32x8): TMask8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vmsne.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpNeU64x4(const a, b: TVecU64x4): TMask4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vmsne.vv v0, v0, v1
  vmv.x.s a0, v0
end;

function RISCVVCmpGeI64x2(const a, b: TVecI64x2): TMask2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vle64.v v1, (a1)
  vmsle.vv v0, v1, v0       // a >= b <=> b <= a
  vmv.x.s a0, v0
end;

// =============================================================
// Saturated Arithmetic Operations
// =============================================================

function RISCVVSatAddI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vsadd.vv v0, v0, v1
  vse16.v v0, (a2)
end;

function RISCVVSatAddI8x16(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vsadd.vv v0, v0, v1
  vse8.v v0, (a2)
end;

function RISCVVSatAddU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vsaddu.vv v0, v0, v1
  vse16.v v0, (a2)
end;

function RISCVVSatAddU8x16(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vsaddu.vv v0, v0, v1
  vse8.v v0, (a2)
end;

function RISCVVSatSubI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vssub.vv v0, v0, v1
  vse16.v v0, (a2)
end;

function RISCVVSatSubI8x16(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
  vle8.v v0, (a0)
  vle8.v v1, (a1)
  vssub.vv v0, v0, v1
  vse8.v v0, (a2)
end;

function RISCVVSatSubU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xC8
  vle16.v v0, (a0)
  vle16.v v1, (a1)
  vssubu.vv v0, v0, v1
  vse16.v v0, (a2)
end;

function RISCVVSatSubU8x16(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xC0
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
  xor a0, a0, t0
  seqz a0, a0
end;

function RISCVVMask2Any(mask: TMask2): Boolean; assembler; nostackframe;
asm
  andi a0, a0, 3
  sltu a0, zero, a0
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
  xor a0, a0, t0
  seqz a0, a0
end;

function RISCVVMask4Any(mask: TMask4): Boolean; assembler; nostackframe;
asm
  andi a0, a0, 15
  sltu a0, zero, a0
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
  xor a0, a0, t0
  seqz a0, a0
end;

function RISCVVMask8Any(mask: TMask8): Boolean; assembler; nostackframe;
asm
  andi a0, a0, 255
  sltu a0, zero, a0
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
  li t2, 8
  blt a0, t2, .Lloop8
.Ldone8:
  ret
.Lnone8:
  li a0, -1
end;

function RISCVVMask16All(mask: TMask16): Boolean; assembler; nostackframe;
asm
  li t0, 0xFFFF
  and a0, a0, t0
  xor a0, a0, t0
  seqz a0, a0
end;

function RISCVVMask16Any(mask: TMask16): Boolean; assembler; nostackframe;
asm
  li t0, 0xFFFF
  and a0, a0, t0
  sltu a0, zero, a0
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
  li t2, 16
  blt a0, t2, .Lloop16
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
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vslidedown.vx v0, v0, a1
  vfmv.f.s f10, v0
end;

function RISCVVExtractF32x8(const a: TVecF32x8; index: Integer): Single; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vslidedown.vx v0, v0, a1
  vfmv.f.s f10, v0
end;

function RISCVVExtractF32x16(const a: TVecF32x16; index: Integer): Single; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vslidedown.vx v0, v0, a1
  vfmv.f.s f10, v0
end;

function RISCVVExtractF64x2(const a: TVecF64x2; index: Integer): Double; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vslidedown.vx v0, v0, a1
  vfmv.f.s f10, v0
end;

function RISCVVExtractF64x4(const a: TVecF64x4; index: Integer): Double; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vslidedown.vx v0, v0, a1
  vfmv.f.s f10, v0
end;

function RISCVVExtractI32x4(const a: TVecI32x4; index: Integer): Int32; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vslidedown.vx v0, v0, a1
  vmv.x.s a0, v0
end;

function RISCVVExtractI32x8(const a: TVecI32x8; index: Integer): Int32; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vslidedown.vx v0, v0, a1
  vmv.x.s a0, v0
end;

function RISCVVExtractI32x16(const a: TVecI32x16; index: Integer): Int32; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vslidedown.vx v0, v0, a1
  vmv.x.s a0, v0
end;

function RISCVVExtractI64x2(const a: TVecI64x2; index: Integer): Int64; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vslidedown.vx v0, v0, a1
  vmv.x.s a0, v0
end;

function RISCVVExtractI64x4(const a: TVecI64x4; index: Integer): Int64; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vslidedown.vx v0, v0, a1
  vmv.x.s a0, v0
end;

function RISCVVInsertF32x4(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vfmv.s.f v1, f10
  vslideup.vx v0, v1, a1
  vse32.v v0, (a2)
end;

function RISCVVInsertF32x8(const a: TVecF32x8; value: Single; index: Integer): TVecF32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vfmv.s.f v2, f10
  vslideup.vx v0, v2, a1
  vse32.v v0, (a2)
end;

function RISCVVInsertF32x16(const a: TVecF32x16; value: Single; index: Integer): TVecF32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vfmv.s.f v4, f10
  vslideup.vx v0, v4, a1
  vse32.v v0, (a2)
end;

function RISCVVInsertF64x2(const a: TVecF64x2; value: Double; index: Integer): TVecF64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vfmv.s.f v1, f10
  vslideup.vx v0, v1, a1
  vse64.v v0, (a2)
end;

function RISCVVInsertF64x4(const a: TVecF64x4; value: Double; index: Integer): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  vle64.v v0, (a0)
  vfmv.s.f v2, f10
  vslideup.vx v0, v2, a1
  vse64.v v0, (a2)
end;

function RISCVVInsertI32x4(const a: TVecI32x4; value: Int32; index: Integer): TVecI32x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vmv.s.x v1, a1
  vslideup.vx v0, v1, a2
  vse32.v v0, (a3)
end;

function RISCVVInsertI32x8(const a: TVecI32x8; value: Int32; index: Integer): TVecI32x8; assembler; nostackframe;
asm
  vsetivli zero, 8, 0xD1
  vle32.v v0, (a0)
  vmv.s.x v2, a1
  vslideup.vx v0, v2, a2
  vse32.v v0, (a3)
end;

function RISCVVInsertI32x16(const a: TVecI32x16; value: Int32; index: Integer): TVecI32x16; assembler; nostackframe;
asm
  vsetivli zero, 16, 0xD2
  vle32.v v0, (a0)
  vmv.s.x v4, a1
  vslideup.vx v0, v4, a2
  vse32.v v0, (a3)
end;

function RISCVVInsertI64x2(const a: TVecI64x2; value: Int64; index: Integer): TVecI64x2; assembler; nostackframe;
asm
  vsetivli zero, 2, 0xD8
  vle64.v v0, (a0)
  vmv.s.x v1, a1
  vslideup.vx v0, v1, a2
  vse64.v v0, (a3)
end;

function RISCVVInsertI64x4(const a: TVecI64x4; value: Int64; index: Integer): TVecI64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
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
  vsetivli zero, 3, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vfmul.vv v0, v0, v1
  vfmv.s.f v2, f10         // zero initial
  vfredusum.vs v2, v0, v2
  vfmv.f.s f10, v2
end;

function RISCVVDotF32x4(const a, b: TVecF32x4): Single; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vle32.v v1, (a1)
  vfmul.vv v0, v0, v1
  vfmv.s.f v2, f10
  vfredusum.vs v2, v0, v2
  vfmv.f.s f10, v2
end;

function RISCVVCrossF32x3(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  // cross(a,b) = (a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x, 0)
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)          // a = [ax, ay, az, aw]
  vle32.v v1, (a1)          // b = [bx, by, bz, bw]

  // Create shuffled vectors for cross product
  // a_yzx = [ay, az, ax, aw]
  vslidedown.vi v2, v0, 1   // [ay, az, aw, 0]
  vslideup.vi v3, v0, 2     // [0, 0, ax, ay]
  vsetivli zero, 3, 0xD0
  vslidedown.vi v4, v2, 2   // temp
  vslideup.vi v2, v4, 2     // rotate

  // b_yzx = [by, bz, bx, bw]
  vslidedown.vi v4, v1, 1
  vsetivli zero, 3, 0xD0
  vslidedown.vi v5, v4, 2
  vslideup.vi v4, v5, 2

  // a_zxy = [az, ax, ay, aw]
  vslidedown.vi v3, v0, 2
  vsetivli zero, 3, 0xD0
  vslidedown.vi v5, v3, 1
  vslideup.vi v3, v5, 2

  // b_zxy = [bz, bx, by, bw]
  vslidedown.vi v5, v1, 2
  vsetivli zero, 3, 0xD0
  vslidedown.vi v6, v5, 1
  vslideup.vi v5, v6, 2

  vsetivli zero, 4, 0xD0
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
  vsetivli zero, 3, 0xD0
  vle32.v v0, (a0)
  vfmul.vv v0, v0, v0       // square each component
  vfmv.s.f v1, f10
  vfredusum.vs v1, v0, v1   // sum of squares
  vfmv.f.s f10, v1
  fsqrt.s f10, f10          // sqrt
end;

function RISCVVLengthF32x4(const a: TVecF32x4): Single; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vfmul.vv v0, v0, v0
  vfmv.s.f v1, f10
  vfredusum.vs v1, v0, v1
  vfmv.f.s f10, v1
  fsqrt.s f10, f10
end;

function RISCVVNormalizeF32x3(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  vsetivli zero, 3, 0xD0
  vle32.v v0, (a0)
  vfmul.vv v1, v0, v0
  vfmv.s.f v2, f10
  vfredusum.vs v2, v1, v2
  vfmv.f.s f0, v2
  fsqrt.s f0, f0
  // Check for zero length
  lui t0, 0x00000           // small epsilon
  fmv.w.x f1, t0
  flt.s t1, f0, f1
  bnez t1, .Lzero_norm3
  // Divide by length
  vsetivli zero, 4, 0xD0
  vfmv.v.f v1, f0
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
  vsetivli zero, 4, 0xD0
  vle32.v v0, (a0)
  vfmul.vv v1, v0, v0
  vfmv.s.f v2, f10
  vfredusum.vs v2, v1, v2
  vfmv.f.s f0, v2
  fsqrt.s f0, f0
  lui t0, 0x00000
  fmv.w.x f1, t0
  flt.s t1, f0, f1
  bnez t1, .Lzero_norm4
  vfmv.v.f v1, f0
  vfdiv.vv v0, v0, v1
  vse32.v v0, (a1)
  ret
.Lzero_norm4:
  vmv.v.i v0, 0
  vse32.v v0, (a1)
end;

function RISCVVRcpF64x4(const a: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  vsetivli zero, 4, 0xD9
  // Load 1.0 as double
  li t0, 0x3FF0000000000000
  fmv.d.x f0, t0
  vfmv.v.f v0, f0
  vle64.v v2, (a0)
  vfdiv.vv v0, v0, v2
  vse64.v v0, (a1)
end;

{$I fafafa.core.simd.riscvv.facade.inc}

{$I fafafa.core.simd.riscvv.helpers.inc}

// =============================================================
// Backend Registration
// =============================================================

{$I fafafa.core.simd.riscvv.register.inc}


end.
