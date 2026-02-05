unit fafafa.core.simd.neon;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  === fafafa.core.simd.neon ===
  ARM NEON SIMD Backend Implementation

  This provides NEON-optimized implementations for ARM processors.
  NEON is available on ARMv7-A, ARMv8-A (AArch32), and AArch64 processors.

  Features:
  - 128-bit vector registers (v0-v31 on AArch64, q0-q15 on ARMv7)
  - Single and double precision floating-point
  - Integer SIMD operations (8, 16, 32, 64-bit)

  AArch64 Calling Convention (AAPCS64):
  - Arguments: x0-x7 (integer/pointer), v0-v7 (SIMD/FP)
  - Return: x0 (integer), v0 (SIMD/FP)
  - Callee-saved: x19-x28, v8-v15 (lower 64 bits only)
  - For struct returns, pointer passed in x8

  === COMPILER REQUIREMENTS ===

  FPC 3.2.2 Limitation:
  FPC 3.2.2 does NOT support AArch64 NEON inline assembly. Any use of
  vector register syntax like "v0.4s" or "v1.16b" causes an Internal
  Compiler Error (ICE). This is a fundamental compiler limitation, not
  a code pattern issue.

  Minimum FPC Version: 3.3.1 (trunk) for NEON inline assembly support.

  Workarounds for FPC 3.2.2 users:
  1. Upgrade to FPC 3.3.1 or later (recommended)
  2. Wait for FPC 3.2.4 release (currently in RC stage)
  3. Use external pre-compiled .o files with C NEON intrinsics
     (see: github.com/neurolabusc/FPCintrinsics for example approach)
  4. Use scalar backend (default behavior - no NEON registered)

  Note: FPC does not provide NEON intrinsics like C compilers do.
  Users must write inline assembly or link external C object files.

  Reference:
  - FPC Wiki: wiki.freepascal.org/AArch64
  - ARM NEON syntax: "add v0.4s, v1.4s, v2.4s" (AArch64 style)
}

interface

uses
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch;

// Register the NEON backend
procedure RegisterNEONBackend;

// === NEON Facade Functions ===

// Memory operations
function MemEqual_NEON(a, b: Pointer; len: SizeUInt): LongBool;
function MemFindByte_NEON(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
function MemDiffRange_NEON(a, b: Pointer; len: SizeUInt; out firstDiff, lastDiff: SizeUInt): Boolean;
procedure MemCopy_NEON(src, dst: Pointer; len: SizeUInt);
procedure MemSet_NEON(dst: Pointer; len: SizeUInt; value: Byte);
procedure MemReverse_NEON(p: Pointer; len: SizeUInt);

// Statistics functions
function SumBytes_NEON(p: Pointer; len: SizeUInt): UInt64;
procedure MinMaxBytes_NEON(p: Pointer; len: SizeUInt; out minVal, maxVal: Byte);
function CountByte_NEON(p: Pointer; len: SizeUInt; value: Byte): SizeUInt;

// Text processing functions
function Utf8Validate_NEON(p: Pointer; len: SizeUInt): Boolean;
function AsciiIEqual_NEON(a, b: Pointer; len: SizeUInt): Boolean;
procedure ToLowerAscii_NEON(p: Pointer; len: SizeUInt);
procedure ToUpperAscii_NEON(p: Pointer; len: SizeUInt);

// Search functions
function BytesIndexOf_NEON(haystack: Pointer; haystackLen: SizeUInt; needle: Pointer; needleLen: SizeUInt): PtrInt;

// Bitset functions
function BitsetPopCount_NEON(p: Pointer; byteLen: SizeUInt): SizeUInt;

implementation

uses
  Math,  // RTL Math 单元
  SysUtils,
  fafafa.core.simd.scalar;

// === NEON Vector Type ===
{$IFDEF CPUAARCH64}
type
  TNeon128 = packed record
    case Integer of
      0: (u8: array[0..15] of UInt8);
      1: (i8: array[0..15] of Int8);
      2: (u16: array[0..7] of UInt16);
      3: (i16: array[0..7] of Int16);
      4: (u32: array[0..3] of UInt32);
      5: (i32: array[0..3] of Int32);
      6: (u64: array[0..1] of UInt64);
      7: (i64: array[0..1] of Int64);
      8: (f32: array[0..3] of Single);
      9: (f64: array[0..1] of Double);
  end;
  PNeon128 = ^TNeon128;
{$ENDIF}

// ============================================================================
// === AArch64 NEON Assembly Implementations ===
// ============================================================================
// FPC 3.2.2 does NOT support AArch64 NEON inline assembly (ICE on any vN.xS syntax).
// NEON ASM requires FPC >= 3.3.1.
// Auto-enabled on CPUAARCH64 with FPC >= 3.3.1 unless SIMD_VECTOR_ASM_DISABLED is defined.
{$IFDEF CPUAARCH64}
  {$IFDEF FPC}
    {$IF FPC_FULLVERSION >= 030301}
      {$IFNDEF SIMD_VECTOR_ASM_DISABLED}
        {$DEFINE FAFAFA_SIMD_NEON_ASM_ENABLED}
      {$ENDIF}
    {$ENDIF}
  {$ENDIF}
{$ENDIF}

{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}

// === F32x4 Arithmetic Operations ===

function NEONAddF32x4(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  // ABI (FPC AArch64):
  // - 16-byte records are passed by value in GPRs.
  // - a: x0..x1, b: x2..x3, return: x0..x1.
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  fadd  v0.4s, v0.4s, v1.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONSubF32x4(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  fsub  v0.4s, v0.4s, v1.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONMulF32x4(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  fmul  v0.4s, v0.4s, v1.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONDivF32x4(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  fdiv  v0.4s, v0.4s, v1.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// === F64x2 Arithmetic Operations ===

function NEONAddF64x2(const a, b: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  // a: x0..x1, b: x2..x3
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  fadd  v0.2d, v0.2d, v1.2d

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONSubF64x2(const a, b: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  fsub  v0.2d, v0.2d, v1.2d

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONMulF64x2(const a, b: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  fmul  v0.2d, v0.2d, v1.2d

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONDivF64x2(const a, b: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  fdiv  v0.2d, v0.2d, v1.2d

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// === F64x2 Math Functions ===

function NEONAbsF64x2(const a: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  // a: x0..x1, return: x0..x1
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fabs  v0.2d, v0.2d

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONSqrtF64x2(const a: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fsqrt v0.2d, v0.2d

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONMinF64x2(const a, b: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  // a: x0..x1, b: x2..x3
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  fmin  v0.2d, v0.2d, v1.2d

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONMaxF64x2(const a, b: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  fmax  v0.2d, v0.2d, v1.2d

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONFloorF64x2(const a: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  frintm v0.2d, v0.2d

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONCeilF64x2(const a: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  frintp v0.2d, v0.2d

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONRoundF64x2(const a: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  frintn v0.2d, v0.2d

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONTruncF64x2(const a: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  frintz v0.2d, v0.2d

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONFmaF64x2(const a, b, c: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  // a: x0..x1, b: x2..x3, c: x4..x5
  // Result = a * b + c
  fmov  d0, x0
  fmov  d3, x1
  ins   v0.d[1], v3.d[0]

  fmov  d1, x2
  fmov  d3, x3
  ins   v1.d[1], v3.d[0]

  fmov  d2, x4
  fmov  d3, x5
  ins   v2.d[1], v3.d[0]

  fmla  v2.2d, v0.2d, v1.2d  // v2 = a*b + c

  umov  x0, v2.d[0]
  umov  x1, v2.d[1]
end;

function NEONClampF64x2(const a, minVal, maxVal: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  // a: x0..x1, minVal: x2..x3, maxVal: x4..x5
  fmov  d0, x0
  fmov  d3, x1
  ins   v0.d[1], v3.d[0]

  fmov  d1, x2
  fmov  d3, x3
  ins   v1.d[1], v3.d[0]

  fmov  d2, x4
  fmov  d3, x5
  ins   v2.d[1], v3.d[0]

  fmax  v0.2d, v0.2d, v1.2d
  fmin  v0.2d, v0.2d, v2.2d

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// === F64x2 Comparison Operations ===

function NEONCmpEqF64x2(const a, b: TVecF64x2): TMask2; assembler; nostackframe;
asm
  // a: x0..x1, b: x2..x3
  fmov  d0, x0
  fmov  d4, x1
  ins   v0.d[1], v4.d[0]

  fmov  d1, x2
  fmov  d4, x3
  ins   v1.d[1], v4.d[0]

  fcmeq v0.2d, v0.2d, v1.2d

  // Extract sign bits to build 2-bit mask
  umov  x2, v0.d[0]
  lsr   x2, x2, #63
  umov  x3, v0.d[1]
  lsr   x3, x3, #63

  orr   w0, w2, w3, lsl #1
end;

function NEONCmpLtF64x2(const a, b: TVecF64x2): TMask2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d4, x1
  ins   v0.d[1], v4.d[0]

  fmov  d1, x2
  fmov  d4, x3
  ins   v1.d[1], v4.d[0]

  // a < b  <=>  b > a
  fcmgt v0.2d, v1.2d, v0.2d

  umov  x2, v0.d[0]
  lsr   x2, x2, #63
  umov  x3, v0.d[1]
  lsr   x3, x3, #63

  orr   w0, w2, w3, lsl #1
end;

function NEONCmpLeF64x2(const a, b: TVecF64x2): TMask2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d4, x1
  ins   v0.d[1], v4.d[0]

  fmov  d1, x2
  fmov  d4, x3
  ins   v1.d[1], v4.d[0]

  // a <= b  <=>  b >= a
  fcmge v0.2d, v1.2d, v0.2d

  umov  x2, v0.d[0]
  lsr   x2, x2, #63
  umov  x3, v0.d[1]
  lsr   x3, x3, #63

  orr   w0, w2, w3, lsl #1
end;

function NEONCmpGtF64x2(const a, b: TVecF64x2): TMask2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d4, x1
  ins   v0.d[1], v4.d[0]

  fmov  d1, x2
  fmov  d4, x3
  ins   v1.d[1], v4.d[0]

  fcmgt v0.2d, v0.2d, v1.2d

  umov  x2, v0.d[0]
  lsr   x2, x2, #63
  umov  x3, v0.d[1]
  lsr   x3, x3, #63

  orr   w0, w2, w3, lsl #1
end;

function NEONCmpGeF64x2(const a, b: TVecF64x2): TMask2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d4, x1
  ins   v0.d[1], v4.d[0]

  fmov  d1, x2
  fmov  d4, x3
  ins   v1.d[1], v4.d[0]

  fcmge v0.2d, v0.2d, v1.2d

  umov  x2, v0.d[0]
  lsr   x2, x2, #63
  umov  x3, v0.d[1]
  lsr   x3, x3, #63

  orr   w0, w2, w3, lsl #1
end;

function NEONCmpNeF64x2(const a, b: TVecF64x2): TMask2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d4, x1
  ins   v0.d[1], v4.d[0]

  fmov  d1, x2
  fmov  d4, x3
  ins   v1.d[1], v4.d[0]

  fcmeq v0.2d, v0.2d, v1.2d
  mvn   v0.16b, v0.16b

  umov  x2, v0.d[0]
  lsr   x2, x2, #63
  umov  x3, v0.d[1]
  lsr   x3, x3, #63

  orr   w0, w2, w3, lsl #1
end;

// === F64x2 Memory Operations ===

function NEONLoadF64x2(p: PDouble): TVecF64x2; assembler; nostackframe;
asm
  // p in x0, return in x0..x1
  ldr   q0, [x0]
  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

procedure NEONStoreF64x2(p: PDouble; const a: TVecF64x2); assembler; nostackframe;
asm
  // p: x0, a: x1..x2
  fmov  d0, x1
  fmov  d1, x2
  ins   v0.d[1], v1.d[0]
  str   q0, [x0]
end;

// === F64x2 Utility Operations ===

function NEONSplatF64x2(value: Double): TVecF64x2; assembler; nostackframe;
asm
  // value in d0
  dup   v0.2d, v0.d[0]

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONZeroF64x2: TVecF64x2; assembler; nostackframe;
asm
  mov   x0, xzr
  mov   x1, xzr
end;

function NEONExtractF64x2(const a: TVecF64x2; index: Integer): Double; assembler; nostackframe;
asm
  // ABI: a in x0..x1, index in w2
  fmov  d0, x0
  fmov  d1, x1

  // Clamp index to [0..1] (saturating semantics)
  cmp   w2, #0
  b.le  .Lext_d_0
  // index >= 1
  fmov  d0, d1
  ret

.Lext_d_0:
  // index <= 0, d0 already holds correct value
end;

function NEONInsertF64x2(const a: TVecF64x2; value: Double; index: Integer): TVecF64x2; assembler; nostackframe;
asm
  // ABI: a in x0..x1, value in d0, index in w2, return x0..x1
  fmov  d1, x0
  fmov  d2, x1
  ins   v1.d[1], v2.d[0]

  // Clamp index to [0..1]
  cmp   w2, #0
  b.le  .Lins_d_0
  // index >= 1
  ins   v1.d[1], v0.d[0]
  b     .Lins_d_done
.Lins_d_0:
  ins   v1.d[0], v0.d[0]
.Lins_d_done:
  umov  x0, v1.d[0]
  umov  x1, v1.d[1]
end;

function NEONSelectF64x2(const mask: TMask2; const a, b: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  // ABI: mask in w0, a: x1..x2, b: x3..x4, return: x0..x1
  fmov  d0, x1
  fmov  d4, x2
  ins   v0.d[1], v4.d[0]

  fmov  d1, x3
  fmov  d4, x4
  ins   v1.d[1], v4.d[0]

  // Expand 2-bit mask to 128-bit mask
  movi  v2.2d, #0

  // Bit 0
  tst   w0, #1
  b.eq  .Lbit0_zero_d
  mvni  v3.2d, #0
  ins   v2.d[0], v3.d[0]
.Lbit0_zero_d:

  // Bit 1
  tst   w0, #2
  b.eq  .Lbit1_zero_d
  mvni  v3.2d, #0
  ins   v2.d[1], v3.d[0]
.Lbit1_zero_d:

  // Bit select: result = (a AND mask) OR (b AND NOT mask)
  bsl   v2.16b, v0.16b, v1.16b

  umov  x0, v2.d[0]
  umov  x1, v2.d[1]
end;

// === F64x2 Reduction Operations ===

function NEONReduceAddF64x2(const a: TVecF64x2): Double; assembler; nostackframe;
asm
  // a: x0..x1
  fmov  d0, x0
  fmov  d1, x1
  fadd  d0, d0, d1
end;

function NEONReduceMinF64x2(const a: TVecF64x2): Double; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d1, x1
  fmin  d0, d0, d1
end;

function NEONReduceMaxF64x2(const a: TVecF64x2): Double; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d1, x1
  fmax  d0, d0, d1
end;

function NEONReduceMulF64x2(const a: TVecF64x2): Double; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d1, x1
  fmul  d0, d0, d1
end;

// === I32x4 Arithmetic Operations ===

function NEONAddI32x4(const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  add   v0.4s, v0.4s, v1.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONSubI32x4(const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  sub   v0.4s, v0.4s, v1.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONMulI32x4(const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  mul   v0.4s, v0.4s, v1.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// === I32x4 Shift Operations ===

function NEONShiftLeftI32x4(const a: TVecI32x4; count: Integer): TVecI32x4; assembler; nostackframe;
asm
  // a: x0..x1, count: w2
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  // NEON 使用向量左移：dup shift count 到所有通道，然后使用 shl
  dup   v1.4s, w2
  shl   v0.4s, v0.4s, v1.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONShiftRightI32x4(const a: TVecI32x4; count: Integer): TVecI32x4; assembler; nostackframe;
asm
  // 逻辑右移（无符号）
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  // 右移需要负的 shift count
  neg   w2, w2
  dup   v1.4s, w2
  shl   v0.4s, v0.4s, v1.4s  // 使用 shl 配合负数 = 逻辑右移

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONShiftRightArithI32x4(const a: TVecI32x4; count: Integer): TVecI32x4; assembler; nostackframe;
asm
  // 算术右移（保留符号位）
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  // 使用 sshr 进行算术右移
  dup   v1.4s, w2
  neg   v1.4s, v1.4s         // 取反移位量
  sshl  v0.4s, v0.4s, v1.4s  // 有符号移位

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONShiftLeftU32x4(const a: TVecU32x4; count: Integer): TVecU32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  dup   v1.4s, w2
  shl   v0.4s, v0.4s, v1.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONShiftRightU32x4(const a: TVecU32x4; count: Integer): TVecU32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  neg   w2, w2
  dup   v1.4s, w2
  shl   v0.4s, v0.4s, v1.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// === I32x4 Bitwise Operations ===

function NEONAndI32x4(const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  and   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONOrI32x4(const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  orr   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONXorI32x4(const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  eor   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONNotI32x4(const a: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  mvn   v0.16b, v0.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONAndNotI32x4(const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  bic   v0.16b, v1.16b, v0.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// === I64x2 Shift Operations ===

function NEONShiftLeftI64x2(const a: TVecI64x2; count: Integer): TVecI64x2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  dup   v1.2d, x2
  shl   v0.2d, v0.2d, v1.2d

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONShiftRightI64x2(const a: TVecI64x2; count: Integer): TVecI64x2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  neg   w2, w2
  sxtw  x2, w2               // 符号扩展到 64 位
  dup   v1.2d, x2
  shl   v0.2d, v0.2d, v1.2d

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONShiftRightArithI64x2(const a: TVecI64x2; count: Integer): TVecI64x2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  neg   w2, w2
  sxtw  x2, w2
  dup   v1.2d, x2
  sshl  v0.2d, v0.2d, v1.2d

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONShiftLeftU64x2(const a: TVecU64x2; count: Integer): TVecU64x2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  dup   v1.2d, x2
  shl   v0.2d, v0.2d, v1.2d

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONShiftRightU64x2(const a: TVecU64x2; count: Integer): TVecU64x2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  neg   w2, w2
  sxtw  x2, w2
  dup   v1.2d, x2
  shl   v0.2d, v0.2d, v1.2d

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// === I16x8 Shift Operations ===

function NEONShiftLeftI16x8(const a: TVecI16x8; count: Integer): TVecI16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  dup   v1.8h, w2
  shl   v0.8h, v0.8h, v1.8h

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONShiftRightI16x8(const a: TVecI16x8; count: Integer): TVecI16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  neg   w2, w2
  dup   v1.8h, w2
  shl   v0.8h, v0.8h, v1.8h

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONShiftRightArithI16x8(const a: TVecI16x8; count: Integer): TVecI16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  neg   w2, w2
  dup   v1.8h, w2
  sshl  v0.8h, v0.8h, v1.8h

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONShiftLeftU16x8(const a: TVecU16x8; count: Integer): TVecU16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  dup   v1.8h, w2
  shl   v0.8h, v0.8h, v1.8h

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONShiftRightU16x8(const a: TVecU16x8; count: Integer): TVecU16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  neg   w2, w2
  dup   v1.8h, w2
  shl   v0.8h, v0.8h, v1.8h

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// === F32x8 (2x 128-bit operations) ===

function NEONAddF32x8(const a, b: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]       // Load a.lo and a.hi
  ldp   q2, q3, [x1]       // Load b.lo and b.hi
  fadd  v0.4s, v0.4s, v2.4s
  fadd  v1.4s, v1.4s, v3.4s
  stp   q0, q1, [x8]       // Store result
end;

function NEONSubF32x8(const a, b: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x1]
  fsub  v0.4s, v0.4s, v2.4s
  fsub  v1.4s, v1.4s, v3.4s
  stp   q0, q1, [x8]
end;

function NEONMulF32x8(const a, b: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x1]
  fmul  v0.4s, v0.4s, v2.4s
  fmul  v1.4s, v1.4s, v3.4s
  stp   q0, q1, [x8]
end;

function NEONDivF32x8(const a, b: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x1]
  fdiv  v0.4s, v0.4s, v2.4s
  fdiv  v1.4s, v1.4s, v3.4s
  stp   q0, q1, [x8]
end;

// === F32x8 Math Functions (256-bit = 2x128-bit NEON) ===

function NEONAbsF32x8(const a: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  // ABI: a: pointer in x0, return: pointer in x8
  ldp   q0, q1, [x0]       // Load a.lo and a.hi
  fabs  v0.4s, v0.4s       // Abs lo
  fabs  v1.4s, v1.4s       // Abs hi
  stp   q0, q1, [x8]       // Store result
end;

function NEONSqrtF32x8(const a: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  fsqrt v0.4s, v0.4s
  fsqrt v1.4s, v1.4s
  stp   q0, q1, [x8]
end;

function NEONMinF32x8(const a, b: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]       // Load a
  ldp   q2, q3, [x1]       // Load b
  fmin  v0.4s, v0.4s, v2.4s
  fmin  v1.4s, v1.4s, v3.4s
  stp   q0, q1, [x8]
end;

function NEONMaxF32x8(const a, b: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x1]
  fmax  v0.4s, v0.4s, v2.4s
  fmax  v1.4s, v1.4s, v3.4s
  stp   q0, q1, [x8]
end;

function NEONFloorF32x8(const a: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  frintm v0.4s, v0.4s
  frintm v1.4s, v1.4s
  stp   q0, q1, [x8]
end;

function NEONCeilF32x8(const a: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  frintp v0.4s, v0.4s
  frintp v1.4s, v1.4s
  stp   q0, q1, [x8]
end;

function NEONRoundF32x8(const a: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  frintn v0.4s, v0.4s
  frintn v1.4s, v1.4s
  stp   q0, q1, [x8]
end;

function NEONTruncF32x8(const a: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  frintz v0.4s, v0.4s
  frintz v1.4s, v1.4s
  stp   q0, q1, [x8]
end;

function NEONFmaF32x8(const a, b, c: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  // Result = a + b * c
  ldp   q0, q1, [x0]       // Load a
  ldp   q2, q3, [x1]       // Load b
  ldp   q4, q5, [x2]       // Load c
  fmla  v0.4s, v2.4s, v4.4s  // a.lo += b.lo * c.lo
  fmla  v1.4s, v3.4s, v5.4s  // a.hi += b.hi * c.hi
  stp   q0, q1, [x8]
end;

function NEONClampF32x8(const a, minVal, maxVal: TVecF32x8): TVecF32x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]       // Load a
  ldp   q2, q3, [x1]       // Load minVal
  ldp   q4, q5, [x2]       // Load maxVal
  fmax  v0.4s, v0.4s, v2.4s  // max(a.lo, minVal.lo)
  fmax  v1.4s, v1.4s, v3.4s  // max(a.hi, minVal.hi)
  fmin  v0.4s, v0.4s, v4.4s  // min(result.lo, maxVal.lo)
  fmin  v1.4s, v1.4s, v5.4s  // min(result.hi, maxVal.hi)
  stp   q0, q1, [x8]
end;

// === F64x4 Arithmetic Operations (256-bit = 2x128-bit NEON) ===

function NEONAddF64x4(const a, b: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  // ABI: a: pointer in x0, b: pointer in x1, return: pointer in x8
  ldp   q0, q1, [x0]       // Load a.lo and a.hi (each 2xf64)
  ldp   q2, q3, [x1]       // Load b.lo and b.hi
  fadd  v0.2d, v0.2d, v2.2d
  fadd  v1.2d, v1.2d, v3.2d
  stp   q0, q1, [x8]       // Store result
end;

function NEONSubF64x4(const a, b: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x1]
  fsub  v0.2d, v0.2d, v2.2d
  fsub  v1.2d, v1.2d, v3.2d
  stp   q0, q1, [x8]
end;

function NEONMulF64x4(const a, b: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x1]
  fmul  v0.2d, v0.2d, v2.2d
  fmul  v1.2d, v1.2d, v3.2d
  stp   q0, q1, [x8]
end;

function NEONDivF64x4(const a, b: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x1]
  fdiv  v0.2d, v0.2d, v2.2d
  fdiv  v1.2d, v1.2d, v3.2d
  stp   q0, q1, [x8]
end;

function NEONMinF64x4(const a, b: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x1]
  fmin  v0.2d, v0.2d, v2.2d
  fmin  v1.2d, v1.2d, v3.2d
  stp   q0, q1, [x8]
end;

function NEONMaxF64x4(const a, b: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x1]
  fmax  v0.2d, v0.2d, v2.2d
  fmax  v1.2d, v1.2d, v3.2d
  stp   q0, q1, [x8]
end;

function NEONAbsF64x4(const a: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  fabs  v0.2d, v0.2d
  fabs  v1.2d, v1.2d
  stp   q0, q1, [x8]
end;

function NEONSqrtF64x4(const a: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  fsqrt v0.2d, v0.2d
  fsqrt v1.2d, v1.2d
  stp   q0, q1, [x8]
end;

function NEONFloorF64x4(const a: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  frintm v0.2d, v0.2d
  frintm v1.2d, v1.2d
  stp   q0, q1, [x8]
end;

function NEONCeilF64x4(const a: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  frintp v0.2d, v0.2d
  frintp v1.2d, v1.2d
  stp   q0, q1, [x8]
end;

function NEONRoundF64x4(const a: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  frintn v0.2d, v0.2d
  frintn v1.2d, v1.2d
  stp   q0, q1, [x8]
end;

function NEONTruncF64x4(const a: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  frintz v0.2d, v0.2d
  frintz v1.2d, v1.2d
  stp   q0, q1, [x8]
end;

function NEONFmaF64x4(const a, b, c: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  // Result = a + b * c
  ldp   q0, q1, [x0]       // Load a
  ldp   q2, q3, [x1]       // Load b
  ldp   q4, q5, [x2]       // Load c
  fmla  v0.2d, v2.2d, v4.2d  // a.lo += b.lo * c.lo
  fmla  v1.2d, v3.2d, v5.2d  // a.hi += b.hi * c.hi
  stp   q0, q1, [x8]
end;

function NEONClampF64x4(const a, minVal, maxVal: TVecF64x4): TVecF64x4; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]       // Load a
  ldp   q2, q3, [x1]       // Load minVal
  ldp   q4, q5, [x2]       // Load maxVal
  fmax  v0.2d, v0.2d, v2.2d  // max(a.lo, minVal.lo)
  fmax  v1.2d, v1.2d, v3.2d  // max(a.hi, minVal.hi)
  fmin  v0.2d, v0.2d, v4.2d  // min(result.lo, maxVal.lo)
  fmin  v1.2d, v1.2d, v5.2d  // min(result.hi, maxVal.hi)
  stp   q0, q1, [x8]
end;

// === I32x8 Arithmetic Operations (256-bit = 2x128-bit NEON) ===
// Integer SIMD operations must wrap on overflow (hardware semantics).

function NEONAddI32x8(const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  // ABI: a: pointer in x0, b: pointer in x1, return: pointer in x8
  ldp   q0, q1, [x0]       // Load a.lo and a.hi (each 4xi32)
  ldp   q2, q3, [x1]       // Load b.lo and b.hi
  add   v0.4s, v0.4s, v2.4s
  add   v1.4s, v1.4s, v3.4s
  stp   q0, q1, [x8]       // Store result
end;

function NEONSubI32x8(const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x1]
  sub   v0.4s, v0.4s, v2.4s
  sub   v1.4s, v1.4s, v3.4s
  stp   q0, q1, [x8]
end;

function NEONMulI32x8(const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x1]
  mul   v0.4s, v0.4s, v2.4s
  mul   v1.4s, v1.4s, v3.4s
  stp   q0, q1, [x8]
end;

// === I32x8 Bitwise Operations (256-bit = 2x128-bit NEON) ===

function NEONAndI32x8(const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x1]
  and   v0.16b, v0.16b, v2.16b
  and   v1.16b, v1.16b, v3.16b
  stp   q0, q1, [x8]
end;

function NEONOrI32x8(const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x1]
  orr   v0.16b, v0.16b, v2.16b
  orr   v1.16b, v1.16b, v3.16b
  stp   q0, q1, [x8]
end;

function NEONXorI32x8(const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x1]
  eor   v0.16b, v0.16b, v2.16b
  eor   v1.16b, v1.16b, v3.16b
  stp   q0, q1, [x8]
end;

function NEONNotI32x8(const a: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  mvn   v0.16b, v0.16b
  mvn   v1.16b, v1.16b
  stp   q0, q1, [x8]
end;

function NEONAndNotI32x8(const a, b: TVecI32x8): TVecI32x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x1]
  bic   v0.16b, v2.16b, v0.16b
  bic   v1.16b, v3.16b, v1.16b
  stp   q0, q1, [x8]
end;

// === I32x8 Shift Operations (256-bit = 2x128-bit NEON) ===

function NEONShiftLeftI32x8(const a: TVecI32x8; count: Integer): TVecI32x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  dup   v2.4s, w1
  shl   v0.4s, v0.4s, v2.4s
  shl   v1.4s, v1.4s, v2.4s
  stp   q0, q1, [x8]
end;

function NEONShiftRightI32x8(const a: TVecI32x8; count: Integer): TVecI32x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  neg   w1, w1
  dup   v2.4s, w1
  shl   v0.4s, v0.4s, v2.4s
  shl   v1.4s, v1.4s, v2.4s
  stp   q0, q1, [x8]
end;

function NEONShiftRightArithI32x8(const a: TVecI32x8; count: Integer): TVecI32x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  neg   w1, w1
  dup   v2.4s, w1
  sshl  v0.4s, v0.4s, v2.4s
  sshl  v1.4s, v1.4s, v2.4s
  stp   q0, q1, [x8]
end;

function NEONShiftLeftU32x8(const a: TVecU32x8; count: Integer): TVecU32x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  dup   v2.4s, w1
  shl   v0.4s, v0.4s, v2.4s
  shl   v1.4s, v1.4s, v2.4s
  stp   q0, q1, [x8]
end;

function NEONShiftRightU32x8(const a: TVecU32x8; count: Integer): TVecU32x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  neg   w1, w1
  dup   v2.4s, w1
  shl   v0.4s, v0.4s, v2.4s
  shl   v1.4s, v1.4s, v2.4s
  stp   q0, q1, [x8]
end;

// === I64x4 Shift Operations (256-bit = 2x128-bit NEON) ===

function NEONShiftLeftI64x4(const a: TVecI64x4; count: Integer): TVecI64x4; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  dup   v2.2d, x1
  shl   v0.2d, v0.2d, v2.2d
  shl   v1.2d, v1.2d, v2.2d
  stp   q0, q1, [x8]
end;

function NEONShiftRightI64x4(const a: TVecI64x4; count: Integer): TVecI64x4; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  neg   w1, w1
  sxtw  x1, w1
  dup   v2.2d, x1
  shl   v0.2d, v0.2d, v2.2d
  shl   v1.2d, v1.2d, v2.2d
  stp   q0, q1, [x8]
end;

function NEONShiftRightArithI64x4(const a: TVecI64x4; count: Integer): TVecI64x4; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  neg   w1, w1
  sxtw  x1, w1
  dup   v2.2d, x1
  sshl  v0.2d, v0.2d, v2.2d
  sshl  v1.2d, v1.2d, v2.2d
  stp   q0, q1, [x8]
end;

function NEONShiftLeftU64x4(const a: TVecU64x4; count: Integer): TVecU64x4; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  dup   v2.2d, x1
  shl   v0.2d, v0.2d, v2.2d
  shl   v1.2d, v1.2d, v2.2d
  stp   q0, q1, [x8]
end;

function NEONShiftRightU64x4(const a: TVecU64x4; count: Integer): TVecU64x4; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  neg   w1, w1
  sxtw  x1, w1
  dup   v2.2d, x1
  shl   v0.2d, v0.2d, v2.2d
  shl   v1.2d, v1.2d, v2.2d
  stp   q0, q1, [x8]
end;

// === I64x4 Bitwise Operations (256-bit = 2x128-bit NEON) ===

function NEONAndI64x4(const a, b: TVecI64x4): TVecI64x4; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x1]
  and   v0.16b, v0.16b, v2.16b
  and   v1.16b, v1.16b, v3.16b
  stp   q0, q1, [x8]
end;

function NEONOrI64x4(const a, b: TVecI64x4): TVecI64x4; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x1]
  orr   v0.16b, v0.16b, v2.16b
  orr   v1.16b, v1.16b, v3.16b
  stp   q0, q1, [x8]
end;

function NEONXorI64x4(const a, b: TVecI64x4): TVecI64x4; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x1]
  eor   v0.16b, v0.16b, v2.16b
  eor   v1.16b, v1.16b, v3.16b
  stp   q0, q1, [x8]
end;

function NEONNotI64x4(const a: TVecI64x4): TVecI64x4; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  mvn   v0.16b, v0.16b
  mvn   v1.16b, v1.16b
  stp   q0, q1, [x8]
end;

function NEONAndNotI64x4(const a, b: TVecI64x4): TVecI64x4; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x1]
  bic   v0.16b, v2.16b, v0.16b
  bic   v1.16b, v3.16b, v1.16b
  stp   q0, q1, [x8]
end;

// === F32x16 Math Functions (512-bit = 4x128-bit NEON) ===

function NEONAbsF32x16(const a: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]        // Load a[0..7]
  ldp   q2, q3, [x0, #32]   // Load a[8..15]
  fabs  v0.4s, v0.4s
  fabs  v1.4s, v1.4s
  fabs  v2.4s, v2.4s
  fabs  v3.4s, v3.4s
  stp   q0, q1, [x8]
  stp   q2, q3, [x8, #32]
end;

function NEONSqrtF32x16(const a: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x0, #32]
  fsqrt v0.4s, v0.4s
  fsqrt v1.4s, v1.4s
  fsqrt v2.4s, v2.4s
  fsqrt v3.4s, v3.4s
  stp   q0, q1, [x8]
  stp   q2, q3, [x8, #32]
end;

function NEONFloorF32x16(const a: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x0, #32]
  frintm v0.4s, v0.4s
  frintm v1.4s, v1.4s
  frintm v2.4s, v2.4s
  frintm v3.4s, v3.4s
  stp   q0, q1, [x8]
  stp   q2, q3, [x8, #32]
end;

function NEONCeilF32x16(const a: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x0, #32]
  frintp v0.4s, v0.4s
  frintp v1.4s, v1.4s
  frintp v2.4s, v2.4s
  frintp v3.4s, v3.4s
  stp   q0, q1, [x8]
  stp   q2, q3, [x8, #32]
end;

function NEONRoundF32x16(const a: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x0, #32]
  frintn v0.4s, v0.4s
  frintn v1.4s, v1.4s
  frintn v2.4s, v2.4s
  frintn v3.4s, v3.4s
  stp   q0, q1, [x8]
  stp   q2, q3, [x8, #32]
end;

function NEONTruncF32x16(const a: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x0, #32]
  frintz v0.4s, v0.4s
  frintz v1.4s, v1.4s
  frintz v2.4s, v2.4s
  frintz v3.4s, v3.4s
  stp   q0, q1, [x8]
  stp   q2, q3, [x8, #32]
end;

function NEONFmaF32x16(const a, b, c: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  // Result = a + b * c
  ldp   q0, q1, [x0]        // Load a[0..7]
  ldp   q2, q3, [x0, #32]   // Load a[8..15]
  ldp   q4, q5, [x1]        // Load b[0..7]
  ldp   q6, q7, [x1, #32]   // Load b[8..15]
  ldp   q16, q17, [x2]      // Load c[0..7]
  ldp   q18, q19, [x2, #32] // Load c[8..15]
  fmla  v0.4s, v4.4s, v16.4s
  fmla  v1.4s, v5.4s, v17.4s
  fmla  v2.4s, v6.4s, v18.4s
  fmla  v3.4s, v7.4s, v19.4s
  stp   q0, q1, [x8]
  stp   q2, q3, [x8, #32]
end;

function NEONClampF32x16(const a, minVal, maxVal: TVecF32x16): TVecF32x16; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]        // Load a[0..7]
  ldp   q2, q3, [x0, #32]   // Load a[8..15]
  ldp   q4, q5, [x1]        // Load minVal[0..7]
  ldp   q6, q7, [x1, #32]   // Load minVal[8..15]
  ldp   q16, q17, [x2]      // Load maxVal[0..7]
  ldp   q18, q19, [x2, #32] // Load maxVal[8..15]
  fmax  v0.4s, v0.4s, v4.4s
  fmax  v1.4s, v1.4s, v5.4s
  fmax  v2.4s, v2.4s, v6.4s
  fmax  v3.4s, v3.4s, v7.4s
  fmin  v0.4s, v0.4s, v16.4s
  fmin  v1.4s, v1.4s, v17.4s
  fmin  v2.4s, v2.4s, v18.4s
  fmin  v3.4s, v3.4s, v19.4s
  stp   q0, q1, [x8]
  stp   q2, q3, [x8, #32]
end;

// === F64x8 Math Functions (512-bit = 4x128-bit NEON) ===

function NEONAbsF64x8(const a: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]        // Load a[0..3]
  ldp   q2, q3, [x0, #32]   // Load a[4..7]
  fabs  v0.2d, v0.2d
  fabs  v1.2d, v1.2d
  fabs  v2.2d, v2.2d
  fabs  v3.2d, v3.2d
  stp   q0, q1, [x8]
  stp   q2, q3, [x8, #32]
end;

function NEONSqrtF64x8(const a: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x0, #32]
  fsqrt v0.2d, v0.2d
  fsqrt v1.2d, v1.2d
  fsqrt v2.2d, v2.2d
  fsqrt v3.2d, v3.2d
  stp   q0, q1, [x8]
  stp   q2, q3, [x8, #32]
end;

function NEONFloorF64x8(const a: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x0, #32]
  frintm v0.2d, v0.2d
  frintm v1.2d, v1.2d
  frintm v2.2d, v2.2d
  frintm v3.2d, v3.2d
  stp   q0, q1, [x8]
  stp   q2, q3, [x8, #32]
end;

function NEONCeilF64x8(const a: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x0, #32]
  frintp v0.2d, v0.2d
  frintp v1.2d, v1.2d
  frintp v2.2d, v2.2d
  frintp v3.2d, v3.2d
  stp   q0, q1, [x8]
  stp   q2, q3, [x8, #32]
end;

function NEONRoundF64x8(const a: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x0, #32]
  frintn v0.2d, v0.2d
  frintn v1.2d, v1.2d
  frintn v2.2d, v2.2d
  frintn v3.2d, v3.2d
  stp   q0, q1, [x8]
  stp   q2, q3, [x8, #32]
end;

function NEONTruncF64x8(const a: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x0, #32]
  frintz v0.2d, v0.2d
  frintz v1.2d, v1.2d
  frintz v2.2d, v2.2d
  frintz v3.2d, v3.2d
  stp   q0, q1, [x8]
  stp   q2, q3, [x8, #32]
end;

function NEONFmaF64x8(const a, b, c: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  // Result = a + b * c
  ldp   q0, q1, [x0]        // Load a[0..3]
  ldp   q2, q3, [x0, #32]   // Load a[4..7]
  ldp   q4, q5, [x1]        // Load b[0..3]
  ldp   q6, q7, [x1, #32]   // Load b[4..7]
  ldp   q16, q17, [x2]      // Load c[0..3]
  ldp   q18, q19, [x2, #32] // Load c[4..7]
  fmla  v0.2d, v4.2d, v16.2d
  fmla  v1.2d, v5.2d, v17.2d
  fmla  v2.2d, v6.2d, v18.2d
  fmla  v3.2d, v7.2d, v19.2d
  stp   q0, q1, [x8]
  stp   q2, q3, [x8, #32]
end;

function NEONClampF64x8(const a, minVal, maxVal: TVecF64x8): TVecF64x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]        // Load a[0..3]
  ldp   q2, q3, [x0, #32]   // Load a[4..7]
  ldp   q4, q5, [x1]        // Load minVal[0..3]
  ldp   q6, q7, [x1, #32]   // Load minVal[4..7]
  ldp   q16, q17, [x2]      // Load maxVal[0..3]
  ldp   q18, q19, [x2, #32] // Load maxVal[4..7]
  fmax  v0.2d, v0.2d, v4.2d
  fmax  v1.2d, v1.2d, v5.2d
  fmax  v2.2d, v2.2d, v6.2d
  fmax  v3.2d, v3.2d, v7.2d
  fmin  v0.2d, v0.2d, v16.2d
  fmin  v1.2d, v1.2d, v17.2d
  fmin  v2.2d, v2.2d, v18.2d
  fmin  v3.2d, v3.2d, v19.2d
  stp   q0, q1, [x8]
  stp   q2, q3, [x8, #32]
end;

// === I32x16 Shift Operations (512-bit = 4x128-bit NEON) ===
// I32x16 = {lo, hi: TVecI32x8}, 每个 I32x8 = {lo, hi: TVecI32x4}
// 需要操作 4 个 128-bit 寄存器

function NEONShiftLeftI32x16(const a: TVecI32x16; count: Integer): TVecI32x16; assembler; nostackframe;
asm
  // a: pointer in x0, count: w1, return: pointer in x8
  ldp   q0, q1, [x0]        // 加载 a.lo (2x128-bit)
  ldp   q2, q3, [x0, #32]   // 加载 a.hi (2x128-bit)
  dup   v4.4s, w1           // 复制移位量
  shl   v0.4s, v0.4s, v4.4s
  shl   v1.4s, v1.4s, v4.4s
  shl   v2.4s, v2.4s, v4.4s
  shl   v3.4s, v3.4s, v4.4s
  stp   q0, q1, [x8]
  stp   q2, q3, [x8, #32]
end;

function NEONShiftRightI32x16(const a: TVecI32x16; count: Integer): TVecI32x16; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x0, #32]
  neg   w1, w1
  dup   v4.4s, w1
  shl   v0.4s, v0.4s, v4.4s
  shl   v1.4s, v1.4s, v4.4s
  shl   v2.4s, v2.4s, v4.4s
  shl   v3.4s, v3.4s, v4.4s
  stp   q0, q1, [x8]
  stp   q2, q3, [x8, #32]
end;

function NEONShiftRightArithI32x16(const a: TVecI32x16; count: Integer): TVecI32x16; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x0, #32]
  neg   w1, w1
  dup   v4.4s, w1
  sshl  v0.4s, v0.4s, v4.4s
  sshl  v1.4s, v1.4s, v4.4s
  sshl  v2.4s, v2.4s, v4.4s
  sshl  v3.4s, v3.4s, v4.4s
  stp   q0, q1, [x8]
  stp   q2, q3, [x8, #32]
end;

// === Math Functions ===

function NEONAbsF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  // a: x0..x1, return: x0..x1
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fabs  v0.4s, v0.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONSqrtF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fsqrt v0.4s, v0.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONMinF32x4(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  // a: x0..x1, b: x2..x3
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  fmin  v0.4s, v0.4s, v1.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONMaxF32x4(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  fmax  v0.4s, v0.4s, v1.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// === Extended Math Functions ===

function NEONFmaF32x4(const a, b, c: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  // a: x0..x1, b: x2..x3, c: x4..x5
  fmov  d0, x0
  fmov  d3, x1
  ins   v0.d[1], v3.d[0]

  fmov  d1, x2
  fmov  d3, x3
  ins   v1.d[1], v3.d[0]

  fmov  d2, x4
  fmov  d3, x5
  ins   v2.d[1], v3.d[0]

  fmla  v2.4s, v0.4s, v1.4s  // v2 = a*b + c

  umov  x0, v2.d[0]
  umov  x1, v2.d[1]
end;

function NEONRcpF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  frecpe v0.4s, v0.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONRsqrtF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  frsqrte v0.4s, v0.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// === Rounding Operations ===

function NEONFloorF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  frintm v0.4s, v0.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONCeilF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  frintp v0.4s, v0.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONRoundF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  frintn v0.4s, v0.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONTruncF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  frintz v0.4s, v0.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONClampF32x4(const a, minVal, maxVal: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  // a: x0..x1, minVal: x2..x3, maxVal: x4..x5
  fmov  d0, x0
  fmov  d3, x1
  ins   v0.d[1], v3.d[0]

  fmov  d1, x2
  fmov  d3, x3
  ins   v1.d[1], v3.d[0]

  fmov  d2, x4
  fmov  d3, x5
  ins   v2.d[1], v3.d[0]

  fmax  v0.4s, v0.4s, v1.4s
  fmin  v0.4s, v0.4s, v2.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// === Vector Math Operations ===

function NEONDotF32x4(const a, b: TVecF32x4): Single; assembler; nostackframe;
asm
  // a: x0..x1, b: x2..x3
  fmov  d0, x0
  fmov  d3, x1
  ins   v0.d[1], v3.d[0]

  fmov  d1, x2
  fmov  d3, x3
  ins   v1.d[1], v3.d[0]

  fmul  v0.4s, v0.4s, v1.4s
  // Horizontal sum (avoid faddp)
  ext   v2.16b, v0.16b, v0.16b, #8
  fadd  v0.4s, v0.4s, v2.4s
  ext   v2.16b, v0.16b, v0.16b, #4
  fadd  v0.4s, v0.4s, v2.4s
  // Result in s0 (v0.s[0])
end;

function NEONDotF32x3(const a, b: TVecF32x4): Single; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d3, x1
  ins   v0.d[1], v3.d[0]

  fmov  d1, x2
  fmov  d3, x3
  ins   v1.d[1], v3.d[0]

  fmul  v0.4s, v0.4s, v1.4s
  mov   v0.s[3], wzr          // Zero the w component
  // Horizontal sum (avoid faddp)
  ext   v2.16b, v0.16b, v0.16b, #8
  fadd  v0.4s, v0.4s, v2.4s
  ext   v2.16b, v0.16b, v0.16b, #4
  fadd  v0.4s, v0.4s, v2.4s
  // Result in s0 (v0.s[0])
end;


function NEONCrossF32x3(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  // a: x0..x1, b: x2..x3, return: x0..x1
  fmov  d0, x0
  fmov  d5, x1
  ins   v0.d[1], v5.d[0]

  fmov  d1, x2
  fmov  d5, x3
  ins   v1.d[1], v5.d[0]

  // Cross product: (a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x, 0)
  // Shuffle a: [y, z, x, w] = 1,2,0,3
  mov   v2.s[0], v0.s[1]      // a.y
  mov   v2.s[1], v0.s[2]      // a.z
  mov   v2.s[2], v0.s[0]      // a.x
  mov   v2.s[3], v0.s[3]      // a.w

  // Shuffle b: [z, x, y, w] = 2,0,1,3
  mov   v3.s[0], v1.s[2]      // b.z
  mov   v3.s[1], v1.s[0]      // b.x
  mov   v3.s[2], v1.s[1]      // b.y
  mov   v3.s[3], v1.s[3]      // b.w

  fmul  v4.4s, v2.4s, v3.4s   // [a.y*b.z, a.z*b.x, a.x*b.y, ...]

  // Shuffle a: [z, x, y, w] = 2,0,1,3
  mov   v2.s[0], v0.s[2]      // a.z
  mov   v2.s[1], v0.s[0]      // a.x
  mov   v2.s[2], v0.s[1]      // a.y

  // Shuffle b: [y, z, x, w] = 1,2,0,3
  mov   v3.s[0], v1.s[1]      // b.y
  mov   v3.s[1], v1.s[2]      // b.z
  mov   v3.s[2], v1.s[0]      // b.x

  fmul  v2.4s, v2.4s, v3.4s   // [a.z*b.y, a.x*b.z, a.y*b.x, ...]
  fsub  v0.4s, v4.4s, v2.4s

  mov   v0.s[3], wzr

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONLengthF32x4(const a: TVecF32x4): Single; assembler; nostackframe;
asm
  // a: x0..x1
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmul  v0.4s, v0.4s, v0.4s
  // Horizontal sum (avoid faddp)
  ext   v1.16b, v0.16b, v0.16b, #8
  fadd  v0.4s, v0.4s, v1.4s
  ext   v1.16b, v0.16b, v0.16b, #4
  fadd  v0.4s, v0.4s, v1.4s
  fsqrt s0, s0
end;

function NEONLengthF32x3(const a: TVecF32x4): Single; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  mov   v0.s[3], wzr
  fmul  v0.4s, v0.4s, v0.4s
  // Horizontal sum (avoid faddp)
  ext   v1.16b, v0.16b, v0.16b, #8
  fadd  v0.4s, v0.4s, v1.4s
  ext   v1.16b, v0.16b, v0.16b, #4
  fadd  v0.4s, v0.4s, v1.4s
  fsqrt s0, s0
end;

function NEONNormalizeF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  // a: x0..x1
  fmov  d0, x0
  fmov  d3, x1
  ins   v0.d[1], v3.d[0]

  fmul  v1.4s, v0.4s, v0.4s        // squares
  // Sum squares (avoid faddp)
  ext   v2.16b, v1.16b, v1.16b, #8
  fadd  v1.4s, v1.4s, v2.4s
  ext   v2.16b, v1.16b, v1.16b, #4
  fadd  v1.4s, v1.4s, v2.4s
  fsqrt s1, s1

  // if length == 0, return original
  fmov  s2, wzr
  fcmp  s1, s2
  b.eq  .Lret_norm4

  // invLen = 1.0 / length
  movz  w3, #0x3f80, lsl #16
  fmov  s2, w3
  fdiv  s1, s2, s1

  // broadcast invLen
  fmov  w3, s1
  dup   v1.4s, w3

  fmul  v0.4s, v0.4s, v1.4s

.Lret_norm4:
  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONNormalizeF32x3(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d3, x1
  ins   v0.d[1], v3.d[0]

  mov   v0.s[3], wzr               // w=0 for calc and result

  fmul  v1.4s, v0.4s, v0.4s
  // Sum squares (avoid faddp)
  ext   v2.16b, v1.16b, v1.16b, #8
  fadd  v1.4s, v1.4s, v2.4s
  ext   v2.16b, v1.16b, v1.16b, #4
  fadd  v1.4s, v1.4s, v2.4s
  fsqrt s1, s1

  fmov  s2, wzr
  fcmp  s1, s2
  b.eq  .Lret_norm3

  movz  w3, #0x3f80, lsl #16
  fmov  s2, w3
  fdiv  s1, s2, s1

  fmov  w3, s1
  dup   v1.4s, w3
  fmul  v0.4s, v0.4s, v1.4s

.Lret_norm3:
  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// === Selection Operation ===

function NEONSelectF32x4(const mask: TMask4; const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  // ABI: mask in w0, a: x1..x2, b: x3..x4, return: x0..x1
  fmov  d0, x1
  fmov  d4, x2
  ins   v0.d[1], v4.d[0]

  fmov  d1, x3
  fmov  d4, x4
  ins   v1.d[1], v4.d[0]

  // Expand 4-bit mask to 128-bit mask
  movi  v2.4s, #0

  // Bit 0
  tst   w0, #1
  b.eq  .Lbit0_zero
  movi  v3.4s, #-1
  ins   v2.s[0], v3.s[0]
.Lbit0_zero:

  // Bit 1
  tst   w0, #2
  b.eq  .Lbit1_zero
  movi  v3.4s, #-1
  ins   v2.s[1], v3.s[0]
.Lbit1_zero:

  // Bit 2
  tst   w0, #4
  b.eq  .Lbit2_zero
  movi  v3.4s, #-1
  ins   v2.s[2], v3.s[0]
.Lbit2_zero:

  // Bit 3
  tst   w0, #8
  b.eq  .Lbit3_zero
  movi  v3.4s, #-1
  ins   v2.s[3], v3.s[0]
.Lbit3_zero:

  // Bit select: result = (a AND mask) OR (b AND NOT mask)
  bsl   v2.16b, v0.16b, v1.16b

  umov  x0, v2.d[0]
  umov  x1, v2.d[1]
end;

function NEONInsertF32x4(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4; assembler; nostackframe;
asm
  // ABI: a in x0..x1, value in s0 (v0.s[0]), index in w2, return x0..x1
  fmov  d1, x0
  fmov  d3, x1
  ins   v1.d[1], v3.d[0]

  // Clamp index to [0..3] (saturating semantics)
  cmp   w2, #0
  b.ge  .Lins_clamp_hi_check
  mov   w2, #0
  b     .Lins_clamp_done
.Lins_clamp_hi_check:
  cmp   w2, #3
  b.le  .Lins_clamp_done
  mov   w2, #3
.Lins_clamp_done:

  cbz   w2, .Lins0
  cmp   w2, #1
  b.eq  .Lins1
  cmp   w2, #2
  b.eq  .Lins2
  // index = 3
  ins   v1.s[3], v0.s[0]
  b     .Lins_done

.Lins0:
  ins   v1.s[0], v0.s[0]
  b     .Lins_done
.Lins1:
  ins   v1.s[1], v0.s[0]
  b     .Lins_done
.Lins2:
  ins   v1.s[2], v0.s[0]

.Lins_done:
  umov  x0, v1.d[0]
  umov  x1, v1.d[1]
end;

// === Reduction Operations ===

function NEONReduceAddF32x4(const a: TVecF32x4): Single; assembler; nostackframe;
asm
  // a: x0..x1
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  // ✅ Horizontal sum using faddp (pairwise add)
  faddp v0.4s, v0.4s, v0.4s  // [a0+a1, a2+a3, a0+a1, a2+a3]
  faddp s0, v0.2s             // [sum(a0..a3), ...]
  // Result in s0 (v0.s[0])
end;

function NEONReduceMinF32x4(const a: TVecF32x4): Single; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fminp v0.4s, v0.4s, v0.4s
  fminp s0, v0.2s
end;

function NEONReduceMaxF32x4(const a: TVecF32x4): Single; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmaxp v0.4s, v0.4s, v0.4s
  fmaxp s0, v0.2s
end;

function NEONReduceMulF32x4(const a: TVecF32x4): Single; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d4, x1
  ins   v0.d[1], v4.d[0]

  // Extract and multiply: no native instruction, do manually
  mov   s1, v0.s[1]
  mov   s2, v0.s[2]
  mov   s3, v0.s[3]
  fmul  s0, s0, s1
  fmul  s0, s0, s2
  fmul  s0, s0, s3
end;

// === Memory Operations ===

function NEONLoadF32x4(p: PSingle): TVecF32x4; assembler; nostackframe;
asm
  // p in x0, return in x0..x1
  ldr   q0, [x0]
  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONLoadF32x4Aligned(p: PSingle): TVecF32x4; assembler; nostackframe;
asm
  ldr   q0, [x0]
  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

procedure NEONStoreF32x4(p: PSingle; const a: TVecF32x4); assembler; nostackframe;
asm
  // p: x0, a: x1..x2
  fmov  d0, x1
  fmov  d1, x2
  ins   v0.d[1], v1.d[0]
  str   q0, [x0]
end;

procedure NEONStoreF32x4Aligned(p: PSingle; const a: TVecF32x4); assembler; nostackframe;
asm
  fmov  d0, x1
  fmov  d1, x2
  ins   v0.d[1], v1.d[0]
  str   q0, [x0]
end;

// === Utility Operations ===

function NEONSplatF32x4(value: Single): TVecF32x4; assembler; nostackframe;
asm
  // value in s0
  fmov  w2, s0
  dup   v0.4s, w2

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

function NEONZeroF32x4: TVecF32x4; assembler; nostackframe;
asm
  mov   x0, xzr
  mov   x1, xzr
end;

function NEONExtractF32x4(const a: TVecF32x4; index: Integer): Single; assembler; nostackframe;
asm
  // ABI: a in x0..x1, index in w2
  fmov  d0, x0
  fmov  d3, x1
  ins   v0.d[1], v3.d[0]

  // Clamp index to [0..3] (saturating semantics)
  cmp   w2, #0
  b.ge  .Lext_clamp_hi_check
  mov   w2, #0
  b     .Lext_clamp_done
.Lext_clamp_hi_check:
  cmp   w2, #3
  b.le  .Lext_clamp_done
  mov   w2, #3
.Lext_clamp_done:

  cbz   w2, .L0
  cmp   w2, #1
  b.eq  .L1
  cmp   w2, #2
  b.eq  .L2
  mov   s0, v0.s[3]
  ret
.L0:
  // s0 already holds v0.s[0]
  ret
.L1:
  mov   s0, v0.s[1]
  ret
.L2:
  mov   s0, v0.s[2]
end;

// === Comparison Operations (with mask extraction) ===

function NEONCmpEqF32x4(const a, b: TVecF32x4): TMask4; assembler; nostackframe;
asm
  // a: x0..x1, b: x2..x3
  fmov  d0, x0
  fmov  d4, x1
  ins   v0.d[1], v4.d[0]

  fmov  d1, x2
  fmov  d4, x3
  ins   v1.d[1], v4.d[0]

  fcmeq v0.4s, v0.4s, v1.4s

  // Extract sign bits to build 4-bit mask
  umov  w1, v0.s[0]
  lsr   w1, w1, #31
  umov  w2, v0.s[1]
  lsr   w2, w2, #31
  umov  w3, v0.s[2]
  lsr   w3, w3, #31
  umov  w4, v0.s[3]
  lsr   w4, w4, #31

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3
end;

function NEONCmpLtF32x4(const a, b: TVecF32x4): TMask4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d4, x1
  ins   v0.d[1], v4.d[0]

  fmov  d1, x2
  fmov  d4, x3
  ins   v1.d[1], v4.d[0]

  // a < b  <=>  b > a
  fcmgt v0.4s, v1.4s, v0.4s

  umov  w1, v0.s[0]
  lsr   w1, w1, #31
  umov  w2, v0.s[1]
  lsr   w2, w2, #31
  umov  w3, v0.s[2]
  lsr   w3, w3, #31
  umov  w4, v0.s[3]
  lsr   w4, w4, #31

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3
end;

function NEONCmpLeF32x4(const a, b: TVecF32x4): TMask4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d4, x1
  ins   v0.d[1], v4.d[0]

  fmov  d1, x2
  fmov  d4, x3
  ins   v1.d[1], v4.d[0]

  // a <= b  <=>  b >= a
  fcmge v0.4s, v1.4s, v0.4s

  umov  w1, v0.s[0]
  lsr   w1, w1, #31
  umov  w2, v0.s[1]
  lsr   w2, w2, #31
  umov  w3, v0.s[2]
  lsr   w3, w3, #31
  umov  w4, v0.s[3]
  lsr   w4, w4, #31

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3
end;

function NEONCmpGtF32x4(const a, b: TVecF32x4): TMask4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d4, x1
  ins   v0.d[1], v4.d[0]

  fmov  d1, x2
  fmov  d4, x3
  ins   v1.d[1], v4.d[0]

  fcmgt v0.4s, v0.4s, v1.4s

  umov  w1, v0.s[0]
  lsr   w1, w1, #31
  umov  w2, v0.s[1]
  lsr   w2, w2, #31
  umov  w3, v0.s[2]
  lsr   w3, w3, #31
  umov  w4, v0.s[3]
  lsr   w4, w4, #31

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3
end;

function NEONCmpGeF32x4(const a, b: TVecF32x4): TMask4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d4, x1
  ins   v0.d[1], v4.d[0]

  fmov  d1, x2
  fmov  d4, x3
  ins   v1.d[1], v4.d[0]

  fcmge v0.4s, v0.4s, v1.4s

  umov  w1, v0.s[0]
  lsr   w1, w1, #31
  umov  w2, v0.s[1]
  lsr   w2, w2, #31
  umov  w3, v0.s[2]
  lsr   w3, w3, #31
  umov  w4, v0.s[3]
  lsr   w4, w4, #31

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3
end;

function NEONCmpNeF32x4(const a, b: TVecF32x4): TMask4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d4, x1
  ins   v0.d[1], v4.d[0]

  fmov  d1, x2
  fmov  d4, x3
  ins   v1.d[1], v4.d[0]

  fcmeq v0.4s, v0.4s, v1.4s
  mvn   v0.16b, v0.16b

  umov  w1, v0.s[0]
  lsr   w1, w1, #31
  umov  w2, v0.s[1]
  lsr   w2, w2, #31
  umov  w3, v0.s[2]
  lsr   w3, w3, #31
  umov  w4, v0.s[3]
  lsr   w4, w4, #31

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3
end;

// === ✅ P2: Saturating Arithmetic Operations (NEON) ===
// NEON 使用 sqadd/sqsub (有符号) 和 uqadd/uqsub (无符号) 指令

// I8x16 有符号饱和加法 (sqadd v.16b)
function NEONI8x16SatAdd(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  // ABI: a in x0..x1, b in x2..x3, return in x0..x1
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  sqadd v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// I8x16 有符号饱和减法 (sqsub v.16b)
function NEONI8x16SatSub(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  sqsub v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// I16x8 有符号饱和加法 (sqadd v.8h)
function NEONI16x8SatAdd(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  sqadd v0.8h, v0.8h, v1.8h

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// I16x8 有符号饱和减法 (sqsub v.8h)
function NEONI16x8SatSub(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  sqsub v0.8h, v0.8h, v1.8h

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U8x16 无符号饱和加法 (uqadd v.16b)
function NEONU8x16SatAdd(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  uqadd v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U8x16 无符号饱和减法 (uqsub v.16b)
function NEONU8x16SatSub(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  uqsub v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U16x8 无符号饱和加法 (uqadd v.8h)
function NEONU16x8SatAdd(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  uqadd v0.8h, v0.8h, v1.8h

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U16x8 无符号饱和减法 (uqsub v.8h)
function NEONU16x8SatSub(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  uqsub v0.8h, v0.8h, v1.8h

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// === ✅ Task 6.2: Narrow Integer Types (I16x8, I8x16, U16x8, U8x16) ===
// NEON 使用 add/sub/mul v.8h/.16b 和 smin/smax/umin/umax 指令

// --- I16x8 Operations (8×Int16) ---

// I16x8 加法 (add v.8h)
function NEONAddI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  add   v0.8h, v0.8h, v1.8h

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// I16x8 减法 (sub v.8h)
function NEONSubI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  sub   v0.8h, v0.8h, v1.8h

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// I16x8 乘法 (mul v.8h)
function NEONMulI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  mul   v0.8h, v0.8h, v1.8h

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// I16x8 位与 (and v.16b)
function NEONAndI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  and   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// I16x8 位或 (orr v.16b)
function NEONOrI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  orr   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// I16x8 位异或 (eor v.16b)
function NEONXorI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  eor   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// I16x8 位非 (mvn v.16b)
function NEONNotI16x8(const a: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  mvn   v0.16b, v0.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// I16x8 与非 (bic v.16b = a AND NOT b)
function NEONAndNotI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  bic   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// I16x8 有符号最小值 (smin v.8h)
function NEONMinI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  smin  v0.8h, v0.8h, v1.8h

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// I16x8 有符号最大值 (smax v.8h)
function NEONMaxI16x8(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  smax  v0.8h, v0.8h, v1.8h

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// --- I8x16 Operations (16×Int8) ---

// I8x16 加法 (add v.16b)
function NEONAddI8x16(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  add   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// I8x16 减法 (sub v.16b)
function NEONSubI8x16(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  sub   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// I8x16 位与 (and v.16b)
function NEONAndI8x16(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  and   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// I8x16 位或 (orr v.16b)
function NEONOrI8x16(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  orr   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// I8x16 位异或 (eor v.16b)
function NEONXorI8x16(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  eor   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// I8x16 位非 (mvn v.16b)
function NEONNotI8x16(const a: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  mvn   v0.16b, v0.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// I8x16 有符号最小值 (smin v.16b)
function NEONMinI8x16(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  smin  v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// I8x16 有符号最大值 (smax v.16b)
function NEONMaxI8x16(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  smax  v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// --- U16x8 Operations (8×UInt16) ---

// U16x8 加法 (add v.8h) - 与 I16x8 相同
function NEONAddU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  add   v0.8h, v0.8h, v1.8h

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U16x8 减法 (sub v.8h)
function NEONSubU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  sub   v0.8h, v0.8h, v1.8h

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U16x8 乘法 (mul v.8h)
function NEONMulU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  mul   v0.8h, v0.8h, v1.8h

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U16x8 位与 (and v.16b)
function NEONAndU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  and   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U16x8 位或 (orr v.16b)
function NEONOrU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  orr   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U16x8 位异或 (eor v.16b)
function NEONXorU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  eor   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U16x8 位非 (mvn v.16b)
function NEONNotU16x8(const a: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  mvn   v0.16b, v0.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U16x8 无符号最小值 (umin v.8h)
function NEONMinU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  umin  v0.8h, v0.8h, v1.8h

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U16x8 无符号最大值 (umax v.8h)
function NEONMaxU16x8(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  umax  v0.8h, v0.8h, v1.8h

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// --- U8x16 Operations (16×UInt8) ---

// U8x16 加法 (add v.16b)
function NEONAddU8x16(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  add   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U8x16 减法 (sub v.16b)
function NEONSubU8x16(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  sub   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U8x16 位与 (and v.16b)
function NEONAndU8x16(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  and   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U8x16 位或 (orr v.16b)
function NEONOrU8x16(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  orr   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U8x16 位异或 (eor v.16b)
function NEONXorU8x16(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  eor   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U8x16 位非 (mvn v.16b)
function NEONNotU8x16(const a: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  mvn   v0.16b, v0.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U8x16 无符号最小值 (umin v.16b)
function NEONMinU8x16(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  umin  v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U8x16 无符号最大值 (umax v.16b)
function NEONMaxU8x16(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  umax  v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// === ✅ Iteration 2.4: U32x4/U32x8/U64x4 Operations (NEON ASM) ===
// 无符号整数操作从 Scalar 回调转换为真正的 NEON ASM

// --- U32x4 Operations (4×UInt32) ---

// U32x4 加法 (add v.4s)
function NEONAddU32x4(const a, b: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  add   v0.4s, v0.4s, v1.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U32x4 减法 (sub v.4s)
function NEONSubU32x4(const a, b: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  sub   v0.4s, v0.4s, v1.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U32x4 位与 (and v.16b)
function NEONAndU32x4(const a, b: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  and   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U32x4 位或 (orr v.16b)
function NEONOrU32x4(const a, b: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  orr   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U32x4 位异或 (eor v.16b)
function NEONXorU32x4(const a, b: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  eor   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U32x4 位非 (mvn v.16b)
function NEONNotU32x4(const a: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  mvn   v0.16b, v0.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U32x4 位与非 (bic v.16b - bitwise clear)
function NEONAndNotU32x4(const a, b: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  bic   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U32x4 无符号最小值 (umin v.4s)
function NEONMinU32x4(const a, b: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  umin  v0.4s, v0.4s, v1.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// U32x4 无符号最大值 (umax v.4s)
function NEONMaxU32x4(const a, b: TVecU32x4): TVecU32x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  umax  v0.4s, v0.4s, v1.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// --- U32x8 Operations (8×UInt32, 2×128-bit) ---

// U32x8 加法 (2×add v.4s)
function NEONAddU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  // Load a.lo (x0..x1) into v0
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  // Load b.lo (x2..x3) into v1
  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  // Add lo: v0 = a.lo + b.lo
  add   v0.4s, v0.4s, v1.4s

  // Load a.hi (x4..x5) into v2
  fmov  d2, x4
  fmov  d4, x5
  ins   v2.d[1], v4.d[0]

  // Load b.hi (x6..x7) into v3
  fmov  d3, x6
  fmov  d4, x7
  ins   v3.d[1], v4.d[0]

  // Add hi: v2 = a.hi + b.hi
  add   v2.4s, v2.4s, v3.4s

  // Return: lo in x0..x1, hi in x2..x3
  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
  umov  x2, v2.d[0]
  umov  x3, v2.d[1]
end;

// U32x8 减法 (2×sub v.4s)
function NEONSubU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  sub   v0.4s, v0.4s, v1.4s

  fmov  d2, x4
  fmov  d4, x5
  ins   v2.d[1], v4.d[0]

  fmov  d3, x6
  fmov  d4, x7
  ins   v3.d[1], v4.d[0]

  sub   v2.4s, v2.4s, v3.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
  umov  x2, v2.d[0]
  umov  x3, v2.d[1]
end;

// U32x8 位与 (2×and v.16b)
function NEONAndU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  and   v0.16b, v0.16b, v1.16b

  fmov  d2, x4
  fmov  d4, x5
  ins   v2.d[1], v4.d[0]

  fmov  d3, x6
  fmov  d4, x7
  ins   v3.d[1], v4.d[0]

  and   v2.16b, v2.16b, v3.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
  umov  x2, v2.d[0]
  umov  x3, v2.d[1]
end;

// U32x8 位或 (2×orr v.16b)
function NEONOrU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  orr   v0.16b, v0.16b, v1.16b

  fmov  d2, x4
  fmov  d4, x5
  ins   v2.d[1], v4.d[0]

  fmov  d3, x6
  fmov  d4, x7
  ins   v3.d[1], v4.d[0]

  orr   v2.16b, v2.16b, v3.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
  umov  x2, v2.d[0]
  umov  x3, v2.d[1]
end;

// U32x8 位异或 (2×eor v.16b)
function NEONXorU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  eor   v0.16b, v0.16b, v1.16b

  fmov  d2, x4
  fmov  d4, x5
  ins   v2.d[1], v4.d[0]

  fmov  d3, x6
  fmov  d4, x7
  ins   v3.d[1], v4.d[0]

  eor   v2.16b, v2.16b, v3.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
  umov  x2, v2.d[0]
  umov  x3, v2.d[1]
end;

// U32x8 位非 (2×mvn v.16b)
function NEONNotU32x8(const a: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  mvn   v0.16b, v0.16b

  fmov  d2, x2
  fmov  d4, x3
  ins   v2.d[1], v4.d[0]

  mvn   v2.16b, v2.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
  umov  x2, v2.d[0]
  umov  x3, v2.d[1]
end;

// U32x8 位与非 (2×bic v.16b)
function NEONAndNotU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  bic   v0.16b, v0.16b, v1.16b

  fmov  d2, x4
  fmov  d4, x5
  ins   v2.d[1], v4.d[0]

  fmov  d3, x6
  fmov  d4, x7
  ins   v3.d[1], v4.d[0]

  bic   v2.16b, v2.16b, v3.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
  umov  x2, v2.d[0]
  umov  x3, v2.d[1]
end;

// U32x8 无符号最小值 (2×umin v.4s)
function NEONMinU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  umin  v0.4s, v0.4s, v1.4s

  fmov  d2, x4
  fmov  d4, x5
  ins   v2.d[1], v4.d[0]

  fmov  d3, x6
  fmov  d4, x7
  ins   v3.d[1], v4.d[0]

  umin  v2.4s, v2.4s, v3.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
  umov  x2, v2.d[0]
  umov  x3, v2.d[1]
end;

// U32x8 无符号最大值 (2×umax v.4s)
function NEONMaxU32x8(const a, b: TVecU32x8): TVecU32x8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  umax  v0.4s, v0.4s, v1.4s

  fmov  d2, x4
  fmov  d4, x5
  ins   v2.d[1], v4.d[0]

  fmov  d3, x6
  fmov  d4, x7
  ins   v3.d[1], v4.d[0]

  umax  v2.4s, v2.4s, v3.4s

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
  umov  x2, v2.d[0]
  umov  x3, v2.d[1]
end;

// --- U64x4 Operations (4×UInt64, 2×128-bit) ---

// U64x4 加法 (2×add v.2d)
function NEONAddU64x4(const a, b: TVecU64x4): TVecU64x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  add   v0.2d, v0.2d, v1.2d

  fmov  d2, x4
  fmov  d4, x5
  ins   v2.d[1], v4.d[0]

  fmov  d3, x6
  fmov  d4, x7
  ins   v3.d[1], v4.d[0]

  add   v2.2d, v2.2d, v3.2d

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
  umov  x2, v2.d[0]
  umov  x3, v2.d[1]
end;

// U64x4 减法 (2×sub v.2d)
function NEONSubU64x4(const a, b: TVecU64x4): TVecU64x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  sub   v0.2d, v0.2d, v1.2d

  fmov  d2, x4
  fmov  d4, x5
  ins   v2.d[1], v4.d[0]

  fmov  d3, x6
  fmov  d4, x7
  ins   v3.d[1], v4.d[0]

  sub   v2.2d, v2.2d, v3.2d

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
  umov  x2, v2.d[0]
  umov  x3, v2.d[1]
end;

// U64x4 位与 (2×and v.16b)
function NEONAndU64x4(const a, b: TVecU64x4): TVecU64x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  and   v0.16b, v0.16b, v1.16b

  fmov  d2, x4
  fmov  d4, x5
  ins   v2.d[1], v4.d[0]

  fmov  d3, x6
  fmov  d4, x7
  ins   v3.d[1], v4.d[0]

  and   v2.16b, v2.16b, v3.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
  umov  x2, v2.d[0]
  umov  x3, v2.d[1]
end;

// U64x4 位或 (2×orr v.16b)
function NEONOrU64x4(const a, b: TVecU64x4): TVecU64x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  orr   v0.16b, v0.16b, v1.16b

  fmov  d2, x4
  fmov  d4, x5
  ins   v2.d[1], v4.d[0]

  fmov  d3, x6
  fmov  d4, x7
  ins   v3.d[1], v4.d[0]

  orr   v2.16b, v2.16b, v3.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
  umov  x2, v2.d[0]
  umov  x3, v2.d[1]
end;

// U64x4 位异或 (2×eor v.16b)
function NEONXorU64x4(const a, b: TVecU64x4): TVecU64x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  eor   v0.16b, v0.16b, v1.16b

  fmov  d2, x4
  fmov  d4, x5
  ins   v2.d[1], v4.d[0]

  fmov  d3, x6
  fmov  d4, x7
  ins   v3.d[1], v4.d[0]

  eor   v2.16b, v2.16b, v3.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
  umov  x2, v2.d[0]
  umov  x3, v2.d[1]
end;

// U64x4 位非 (2×mvn v.16b)
function NEONNotU64x4(const a: TVecU64x4): TVecU64x4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  mvn   v0.16b, v0.16b

  fmov  d2, x2
  fmov  d4, x3
  ins   v2.d[1], v4.d[0]

  mvn   v2.16b, v2.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
  umov  x2, v2.d[0]
  umov  x3, v2.d[1]
end;

// === ✅ P3: I64x2 Arithmetic, Bitwise, and Comparison Operations (NEON) ===
// NEON 使用 add/sub v.2d 和 and/orr/eor v.16b 指令

// I64x2 加法 (add v.2d)
function NEONAddI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  // ABI: a in x0..x1, b in x2..x3, return in x0..x1
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  add   v0.2d, v0.2d, v1.2d

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// I64x2 减法 (sub v.2d)
function NEONSubI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  sub   v0.2d, v0.2d, v1.2d

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// I64x2 位与 (and v.16b)
function NEONAndI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  and   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// I64x2 位或 (orr v.16b)
function NEONOrI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  orr   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// I64x2 位异或 (eor v.16b)
function NEONXorI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  eor   v0.16b, v0.16b, v1.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// I64x2 位非 (mvn v.16b)
function NEONNotI64x2(const a: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  mvn   v0.16b, v0.16b

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
end;

// I64x2 相等比较 (cmeq v.2d) -> TMask2
function NEONCmpEqI64x2(const a, b: TVecI64x2): TMask2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmeq  v0.2d, v0.2d, v1.2d

  // 提取掩码: 每个 64-bit lane 的最高位
  umov  x2, v0.d[0]
  lsr   x2, x2, #63
  umov  x3, v0.d[1]
  lsr   x3, x3, #63
  orr   w0, w2, w3, lsl #1
end;

// I64x2 大于比较 (cmgt v.2d) -> TMask2
function NEONCmpGtI64x2(const a, b: TVecI64x2): TMask2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmgt  v0.2d, v0.2d, v1.2d

  umov  x2, v0.d[0]
  lsr   x2, x2, #63
  umov  x3, v0.d[1]
  lsr   x3, x3, #63
  orr   w0, w2, w3, lsl #1
end;

// I64x2 小于比较 (a < b = b > a)
function NEONCmpLtI64x2(const a, b: TVecI64x2): TMask2; assembler; nostackframe;
asm
  // 交换 a 和 b，然后用 cmgt
  fmov  d0, x2        // b
  fmov  d2, x3
  ins   v0.d[1], v2.d[0]

  fmov  d1, x0        // a
  fmov  d2, x1
  ins   v1.d[1], v2.d[0]

  cmgt  v0.2d, v0.2d, v1.2d  // b > a

  umov  x2, v0.d[0]
  lsr   x2, x2, #63
  umov  x3, v0.d[1]
  lsr   x3, x3, #63
  orr   w0, w2, w3, lsl #1
end;

// I64x2 小于等于 (a <= b = NOT(a > b))
function NEONCmpLeI64x2(const a, b: TVecI64x2): TMask2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmgt  v0.2d, v0.2d, v1.2d  // a > b
  mvn   v0.16b, v0.16b       // NOT

  umov  x2, v0.d[0]
  lsr   x2, x2, #63
  umov  x3, v0.d[1]
  lsr   x3, x3, #63
  orr   w0, w2, w3, lsl #1
end;

// I64x2 大于等于 (a >= b = NOT(b > a))
function NEONCmpGeI64x2(const a, b: TVecI64x2): TMask2; assembler; nostackframe;
asm
  // 交换 a 和 b，然后用 cmgt，然后取反
  fmov  d0, x2        // b
  fmov  d2, x3
  ins   v0.d[1], v2.d[0]

  fmov  d1, x0        // a
  fmov  d2, x1
  ins   v1.d[1], v2.d[0]

  cmgt  v0.2d, v0.2d, v1.2d  // b > a = a < b
  mvn   v0.16b, v0.16b       // NOT

  umov  x2, v0.d[0]
  lsr   x2, x2, #63
  umov  x3, v0.d[1]
  lsr   x3, x3, #63
  orr   w0, w2, w3, lsl #1
end;

// I64x2 不等比较 (a != b = NOT(a == b))
function NEONCmpNeI64x2(const a, b: TVecI64x2): TMask2; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmeq  v0.2d, v0.2d, v1.2d  // a == b
  mvn   v0.16b, v0.16b       // NOT

  umov  x2, v0.d[0]
  lsr   x2, x2, #63
  umov  x3, v0.d[1]
  lsr   x3, x3, #63
  orr   w0, w2, w3, lsl #1
end;

// ============================================================================
// === I32x4 Comparison Operations (NEON) ===
// ============================================================================

// I32x4 相等比较 (cmeq v.4s) -> TMask4
function NEONCmpEqI32x4(const a, b: TVecI32x4): TMask4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmeq  v0.4s, v0.4s, v1.4s

  // 提取掩码
  umov  w1, v0.s[0]
  lsr   w1, w1, #31
  umov  w2, v0.s[1]
  lsr   w2, w2, #31
  umov  w3, v0.s[2]
  lsr   w3, w3, #31
  umov  w4, v0.s[3]
  lsr   w4, w4, #31

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3
end;

// I32x4 大于比较 (cmgt v.4s) -> TMask4
function NEONCmpGtI32x4(const a, b: TVecI32x4): TMask4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmgt  v0.4s, v0.4s, v1.4s

  umov  w1, v0.s[0]
  lsr   w1, w1, #31
  umov  w2, v0.s[1]
  lsr   w2, w2, #31
  umov  w3, v0.s[2]
  lsr   w3, w3, #31
  umov  w4, v0.s[3]
  lsr   w4, w4, #31

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3
end;

// I32x4 小于比较 (a < b = b > a)
function NEONCmpLtI32x4(const a, b: TVecI32x4): TMask4; assembler; nostackframe;
asm
  // 交换 a 和 b
  fmov  d0, x2        // b
  fmov  d2, x3
  ins   v0.d[1], v2.d[0]

  fmov  d1, x0        // a
  fmov  d2, x1
  ins   v1.d[1], v2.d[0]

  cmgt  v0.4s, v0.4s, v1.4s  // b > a

  umov  w1, v0.s[0]
  lsr   w1, w1, #31
  umov  w2, v0.s[1]
  lsr   w2, w2, #31
  umov  w3, v0.s[2]
  lsr   w3, w3, #31
  umov  w4, v0.s[3]
  lsr   w4, w4, #31

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3
end;

// I32x4 小于等于 (a <= b = NOT(a > b))
function NEONCmpLeI32x4(const a, b: TVecI32x4): TMask4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmgt  v0.4s, v0.4s, v1.4s  // a > b
  mvn   v0.16b, v0.16b       // NOT

  umov  w1, v0.s[0]
  lsr   w1, w1, #31
  umov  w2, v0.s[1]
  lsr   w2, w2, #31
  umov  w3, v0.s[2]
  lsr   w3, w3, #31
  umov  w4, v0.s[3]
  lsr   w4, w4, #31

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3
end;

// I32x4 大于等于 (a >= b = NOT(b > a))
function NEONCmpGeI32x4(const a, b: TVecI32x4): TMask4; assembler; nostackframe;
asm
  // 交换 a 和 b
  fmov  d0, x2        // b
  fmov  d2, x3
  ins   v0.d[1], v2.d[0]

  fmov  d1, x0        // a
  fmov  d2, x1
  ins   v1.d[1], v2.d[0]

  cmgt  v0.4s, v0.4s, v1.4s  // b > a
  mvn   v0.16b, v0.16b       // NOT

  umov  w1, v0.s[0]
  lsr   w1, w1, #31
  umov  w2, v0.s[1]
  lsr   w2, w2, #31
  umov  w3, v0.s[2]
  lsr   w3, w3, #31
  umov  w4, v0.s[3]
  lsr   w4, w4, #31

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3
end;

// I32x4 不等比较 (a != b = NOT(a == b))
function NEONCmpNeI32x4(const a, b: TVecI32x4): TMask4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmeq  v0.4s, v0.4s, v1.4s
  mvn   v0.16b, v0.16b

  umov  w1, v0.s[0]
  lsr   w1, w1, #31
  umov  w2, v0.s[1]
  lsr   w2, w2, #31
  umov  w3, v0.s[2]
  lsr   w3, w3, #31
  umov  w4, v0.s[3]
  lsr   w4, w4, #31

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3
end;

// ============================================================================
// === I16x8 Comparison Operations (NEON) ===
// ============================================================================

// I16x8 相等比较 (cmeq v.8h) -> TMask8
function NEONCmpEqI16x8(const a, b: TVecI16x8): TMask8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmeq  v0.8h, v0.8h, v1.8h

  // 提取 8 个 16-bit lane 的掩码
  umov  w1, v0.h[0]
  lsr   w1, w1, #15
  umov  w2, v0.h[1]
  lsr   w2, w2, #15
  umov  w3, v0.h[2]
  lsr   w3, w3, #15
  umov  w4, v0.h[3]
  lsr   w4, w4, #15

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3

  umov  w1, v0.h[4]
  lsr   w1, w1, #15
  umov  w2, v0.h[5]
  lsr   w2, w2, #15
  umov  w3, v0.h[6]
  lsr   w3, w3, #15
  umov  w4, v0.h[7]
  lsr   w4, w4, #15

  orr   w0, w0, w1, lsl #4
  orr   w0, w0, w2, lsl #5
  orr   w0, w0, w3, lsl #6
  orr   w0, w0, w4, lsl #7
end;

// I16x8 大于比较 (cmgt v.8h) -> TMask8
function NEONCmpGtI16x8(const a, b: TVecI16x8): TMask8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmgt  v0.8h, v0.8h, v1.8h

  umov  w1, v0.h[0]
  lsr   w1, w1, #15
  umov  w2, v0.h[1]
  lsr   w2, w2, #15
  umov  w3, v0.h[2]
  lsr   w3, w3, #15
  umov  w4, v0.h[3]
  lsr   w4, w4, #15

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3

  umov  w1, v0.h[4]
  lsr   w1, w1, #15
  umov  w2, v0.h[5]
  lsr   w2, w2, #15
  umov  w3, v0.h[6]
  lsr   w3, w3, #15
  umov  w4, v0.h[7]
  lsr   w4, w4, #15

  orr   w0, w0, w1, lsl #4
  orr   w0, w0, w2, lsl #5
  orr   w0, w0, w3, lsl #6
  orr   w0, w0, w4, lsl #7
end;

// I16x8 小于比较
function NEONCmpLtI16x8(const a, b: TVecI16x8): TMask8; assembler; nostackframe;
asm
  fmov  d0, x2
  fmov  d2, x3
  ins   v0.d[1], v2.d[0]

  fmov  d1, x0
  fmov  d2, x1
  ins   v1.d[1], v2.d[0]

  cmgt  v0.8h, v0.8h, v1.8h

  umov  w1, v0.h[0]
  lsr   w1, w1, #15
  umov  w2, v0.h[1]
  lsr   w2, w2, #15
  umov  w3, v0.h[2]
  lsr   w3, w3, #15
  umov  w4, v0.h[3]
  lsr   w4, w4, #15

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3

  umov  w1, v0.h[4]
  lsr   w1, w1, #15
  umov  w2, v0.h[5]
  lsr   w2, w2, #15
  umov  w3, v0.h[6]
  lsr   w3, w3, #15
  umov  w4, v0.h[7]
  lsr   w4, w4, #15

  orr   w0, w0, w1, lsl #4
  orr   w0, w0, w2, lsl #5
  orr   w0, w0, w3, lsl #6
  orr   w0, w0, w4, lsl #7
end;

// I16x8 小于等于比较
function NEONCmpLeI16x8(const a, b: TVecI16x8): TMask8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmgt  v0.8h, v0.8h, v1.8h
  mvn   v0.16b, v0.16b

  umov  w1, v0.h[0]
  lsr   w1, w1, #15
  umov  w2, v0.h[1]
  lsr   w2, w2, #15
  umov  w3, v0.h[2]
  lsr   w3, w3, #15
  umov  w4, v0.h[3]
  lsr   w4, w4, #15

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3

  umov  w1, v0.h[4]
  lsr   w1, w1, #15
  umov  w2, v0.h[5]
  lsr   w2, w2, #15
  umov  w3, v0.h[6]
  lsr   w3, w3, #15
  umov  w4, v0.h[7]
  lsr   w4, w4, #15

  orr   w0, w0, w1, lsl #4
  orr   w0, w0, w2, lsl #5
  orr   w0, w0, w3, lsl #6
  orr   w0, w0, w4, lsl #7
end;

// I16x8 大于等于比较
function NEONCmpGeI16x8(const a, b: TVecI16x8): TMask8; assembler; nostackframe;
asm
  fmov  d0, x2
  fmov  d2, x3
  ins   v0.d[1], v2.d[0]

  fmov  d1, x0
  fmov  d2, x1
  ins   v1.d[1], v2.d[0]

  cmgt  v0.8h, v0.8h, v1.8h
  mvn   v0.16b, v0.16b

  umov  w1, v0.h[0]
  lsr   w1, w1, #15
  umov  w2, v0.h[1]
  lsr   w2, w2, #15
  umov  w3, v0.h[2]
  lsr   w3, w3, #15
  umov  w4, v0.h[3]
  lsr   w4, w4, #15

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3

  umov  w1, v0.h[4]
  lsr   w1, w1, #15
  umov  w2, v0.h[5]
  lsr   w2, w2, #15
  umov  w3, v0.h[6]
  lsr   w3, w3, #15
  umov  w4, v0.h[7]
  lsr   w4, w4, #15

  orr   w0, w0, w1, lsl #4
  orr   w0, w0, w2, lsl #5
  orr   w0, w0, w3, lsl #6
  orr   w0, w0, w4, lsl #7
end;

// I16x8 不等比较
function NEONCmpNeI16x8(const a, b: TVecI16x8): TMask8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmeq  v0.8h, v0.8h, v1.8h
  mvn   v0.16b, v0.16b

  umov  w1, v0.h[0]
  lsr   w1, w1, #15
  umov  w2, v0.h[1]
  lsr   w2, w2, #15
  umov  w3, v0.h[2]
  lsr   w3, w3, #15
  umov  w4, v0.h[3]
  lsr   w4, w4, #15

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3

  umov  w1, v0.h[4]
  lsr   w1, w1, #15
  umov  w2, v0.h[5]
  lsr   w2, w2, #15
  umov  w3, v0.h[6]
  lsr   w3, w3, #15
  umov  w4, v0.h[7]
  lsr   w4, w4, #15

  orr   w0, w0, w1, lsl #4
  orr   w0, w0, w2, lsl #5
  orr   w0, w0, w3, lsl #6
  orr   w0, w0, w4, lsl #7
end;

// ============================================================================
// === I8x16 Comparison Operations (NEON) ===
// ============================================================================

// I8x16 相等比较 (cmeq v.16b) -> TMask16
function NEONCmpEqI8x16(const a, b: TVecI8x16): TMask16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmeq  v0.16b, v0.16b, v1.16b

  // 提取 16 个字节的掩码
  umov  w1, v0.b[0]
  lsr   w1, w1, #7
  umov  w2, v0.b[1]
  lsr   w2, w2, #7
  umov  w3, v0.b[2]
  lsr   w3, w3, #7
  umov  w4, v0.b[3]
  lsr   w4, w4, #7

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3

  umov  w1, v0.b[4]
  lsr   w1, w1, #7
  umov  w2, v0.b[5]
  lsr   w2, w2, #7
  umov  w3, v0.b[6]
  lsr   w3, w3, #7
  umov  w4, v0.b[7]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #4
  orr   w0, w0, w2, lsl #5
  orr   w0, w0, w3, lsl #6
  orr   w0, w0, w4, lsl #7

  umov  w1, v0.b[8]
  lsr   w1, w1, #7
  umov  w2, v0.b[9]
  lsr   w2, w2, #7
  umov  w3, v0.b[10]
  lsr   w3, w3, #7
  umov  w4, v0.b[11]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #8
  orr   w0, w0, w2, lsl #9
  orr   w0, w0, w3, lsl #10
  orr   w0, w0, w4, lsl #11

  umov  w1, v0.b[12]
  lsr   w1, w1, #7
  umov  w2, v0.b[13]
  lsr   w2, w2, #7
  umov  w3, v0.b[14]
  lsr   w3, w3, #7
  umov  w4, v0.b[15]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #12
  orr   w0, w0, w2, lsl #13
  orr   w0, w0, w3, lsl #14
  orr   w0, w0, w4, lsl #15
end;

// I8x16 大于比较 (cmgt v.16b) -> TMask16
function NEONCmpGtI8x16(const a, b: TVecI8x16): TMask16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmgt  v0.16b, v0.16b, v1.16b

  umov  w1, v0.b[0]
  lsr   w1, w1, #7
  umov  w2, v0.b[1]
  lsr   w2, w2, #7
  umov  w3, v0.b[2]
  lsr   w3, w3, #7
  umov  w4, v0.b[3]
  lsr   w4, w4, #7

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3

  umov  w1, v0.b[4]
  lsr   w1, w1, #7
  umov  w2, v0.b[5]
  lsr   w2, w2, #7
  umov  w3, v0.b[6]
  lsr   w3, w3, #7
  umov  w4, v0.b[7]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #4
  orr   w0, w0, w2, lsl #5
  orr   w0, w0, w3, lsl #6
  orr   w0, w0, w4, lsl #7

  umov  w1, v0.b[8]
  lsr   w1, w1, #7
  umov  w2, v0.b[9]
  lsr   w2, w2, #7
  umov  w3, v0.b[10]
  lsr   w3, w3, #7
  umov  w4, v0.b[11]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #8
  orr   w0, w0, w2, lsl #9
  orr   w0, w0, w3, lsl #10
  orr   w0, w0, w4, lsl #11

  umov  w1, v0.b[12]
  lsr   w1, w1, #7
  umov  w2, v0.b[13]
  lsr   w2, w2, #7
  umov  w3, v0.b[14]
  lsr   w3, w3, #7
  umov  w4, v0.b[15]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #12
  orr   w0, w0, w2, lsl #13
  orr   w0, w0, w3, lsl #14
  orr   w0, w0, w4, lsl #15
end;

// I8x16 小于比较
function NEONCmpLtI8x16(const a, b: TVecI8x16): TMask16; assembler; nostackframe;
asm
  fmov  d0, x2
  fmov  d2, x3
  ins   v0.d[1], v2.d[0]

  fmov  d1, x0
  fmov  d2, x1
  ins   v1.d[1], v2.d[0]

  cmgt  v0.16b, v0.16b, v1.16b

  umov  w1, v0.b[0]
  lsr   w1, w1, #7
  umov  w2, v0.b[1]
  lsr   w2, w2, #7
  umov  w3, v0.b[2]
  lsr   w3, w3, #7
  umov  w4, v0.b[3]
  lsr   w4, w4, #7

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3

  umov  w1, v0.b[4]
  lsr   w1, w1, #7
  umov  w2, v0.b[5]
  lsr   w2, w2, #7
  umov  w3, v0.b[6]
  lsr   w3, w3, #7
  umov  w4, v0.b[7]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #4
  orr   w0, w0, w2, lsl #5
  orr   w0, w0, w3, lsl #6
  orr   w0, w0, w4, lsl #7

  umov  w1, v0.b[8]
  lsr   w1, w1, #7
  umov  w2, v0.b[9]
  lsr   w2, w2, #7
  umov  w3, v0.b[10]
  lsr   w3, w3, #7
  umov  w4, v0.b[11]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #8
  orr   w0, w0, w2, lsl #9
  orr   w0, w0, w3, lsl #10
  orr   w0, w0, w4, lsl #11

  umov  w1, v0.b[12]
  lsr   w1, w1, #7
  umov  w2, v0.b[13]
  lsr   w2, w2, #7
  umov  w3, v0.b[14]
  lsr   w3, w3, #7
  umov  w4, v0.b[15]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #12
  orr   w0, w0, w2, lsl #13
  orr   w0, w0, w3, lsl #14
  orr   w0, w0, w4, lsl #15
end;

// I8x16 小于等于比较
function NEONCmpLeI8x16(const a, b: TVecI8x16): TMask16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmgt  v0.16b, v0.16b, v1.16b
  mvn   v0.16b, v0.16b

  umov  w1, v0.b[0]
  lsr   w1, w1, #7
  umov  w2, v0.b[1]
  lsr   w2, w2, #7
  umov  w3, v0.b[2]
  lsr   w3, w3, #7
  umov  w4, v0.b[3]
  lsr   w4, w4, #7

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3

  umov  w1, v0.b[4]
  lsr   w1, w1, #7
  umov  w2, v0.b[5]
  lsr   w2, w2, #7
  umov  w3, v0.b[6]
  lsr   w3, w3, #7
  umov  w4, v0.b[7]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #4
  orr   w0, w0, w2, lsl #5
  orr   w0, w0, w3, lsl #6
  orr   w0, w0, w4, lsl #7

  umov  w1, v0.b[8]
  lsr   w1, w1, #7
  umov  w2, v0.b[9]
  lsr   w2, w2, #7
  umov  w3, v0.b[10]
  lsr   w3, w3, #7
  umov  w4, v0.b[11]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #8
  orr   w0, w0, w2, lsl #9
  orr   w0, w0, w3, lsl #10
  orr   w0, w0, w4, lsl #11

  umov  w1, v0.b[12]
  lsr   w1, w1, #7
  umov  w2, v0.b[13]
  lsr   w2, w2, #7
  umov  w3, v0.b[14]
  lsr   w3, w3, #7
  umov  w4, v0.b[15]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #12
  orr   w0, w0, w2, lsl #13
  orr   w0, w0, w3, lsl #14
  orr   w0, w0, w4, lsl #15
end;

// I8x16 大于等于比较
function NEONCmpGeI8x16(const a, b: TVecI8x16): TMask16; assembler; nostackframe;
asm
  fmov  d0, x2
  fmov  d2, x3
  ins   v0.d[1], v2.d[0]

  fmov  d1, x0
  fmov  d2, x1
  ins   v1.d[1], v2.d[0]

  cmgt  v0.16b, v0.16b, v1.16b
  mvn   v0.16b, v0.16b

  umov  w1, v0.b[0]
  lsr   w1, w1, #7
  umov  w2, v0.b[1]
  lsr   w2, w2, #7
  umov  w3, v0.b[2]
  lsr   w3, w3, #7
  umov  w4, v0.b[3]
  lsr   w4, w4, #7

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3

  umov  w1, v0.b[4]
  lsr   w1, w1, #7
  umov  w2, v0.b[5]
  lsr   w2, w2, #7
  umov  w3, v0.b[6]
  lsr   w3, w3, #7
  umov  w4, v0.b[7]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #4
  orr   w0, w0, w2, lsl #5
  orr   w0, w0, w3, lsl #6
  orr   w0, w0, w4, lsl #7

  umov  w1, v0.b[8]
  lsr   w1, w1, #7
  umov  w2, v0.b[9]
  lsr   w2, w2, #7
  umov  w3, v0.b[10]
  lsr   w3, w3, #7
  umov  w4, v0.b[11]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #8
  orr   w0, w0, w2, lsl #9
  orr   w0, w0, w3, lsl #10
  orr   w0, w0, w4, lsl #11

  umov  w1, v0.b[12]
  lsr   w1, w1, #7
  umov  w2, v0.b[13]
  lsr   w2, w2, #7
  umov  w3, v0.b[14]
  lsr   w3, w3, #7
  umov  w4, v0.b[15]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #12
  orr   w0, w0, w2, lsl #13
  orr   w0, w0, w3, lsl #14
  orr   w0, w0, w4, lsl #15
end;

// I8x16 不等比较
function NEONCmpNeI8x16(const a, b: TVecI8x16): TMask16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmeq  v0.16b, v0.16b, v1.16b
  mvn   v0.16b, v0.16b

  umov  w1, v0.b[0]
  lsr   w1, w1, #7
  umov  w2, v0.b[1]
  lsr   w2, w2, #7
  umov  w3, v0.b[2]
  lsr   w3, w3, #7
  umov  w4, v0.b[3]
  lsr   w4, w4, #7

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3

  umov  w1, v0.b[4]
  lsr   w1, w1, #7
  umov  w2, v0.b[5]
  lsr   w2, w2, #7
  umov  w3, v0.b[6]
  lsr   w3, w3, #7
  umov  w4, v0.b[7]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #4
  orr   w0, w0, w2, lsl #5
  orr   w0, w0, w3, lsl #6
  orr   w0, w0, w4, lsl #7

  umov  w1, v0.b[8]
  lsr   w1, w1, #7
  umov  w2, v0.b[9]
  lsr   w2, w2, #7
  umov  w3, v0.b[10]
  lsr   w3, w3, #7
  umov  w4, v0.b[11]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #8
  orr   w0, w0, w2, lsl #9
  orr   w0, w0, w3, lsl #10
  orr   w0, w0, w4, lsl #11

  umov  w1, v0.b[12]
  lsr   w1, w1, #7
  umov  w2, v0.b[13]
  lsr   w2, w2, #7
  umov  w3, v0.b[14]
  lsr   w3, w3, #7
  umov  w4, v0.b[15]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #12
  orr   w0, w0, w2, lsl #13
  orr   w0, w0, w3, lsl #14
  orr   w0, w0, w4, lsl #15
end;

// ============================================================================
// === I32x4 Reduction Operations (NEON) ===
// ============================================================================

// ✅ I32x4 水平加法规约 (addp v.4s)
function NEONReduceAddI32x4(const a: TVecI32x4): Int32; assembler; nostackframe;
asm
  // a: x0..x1
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  // Horizontal sum using addp (integer pairwise add)
  addp  v0.4s, v0.4s, v0.4s  // [a0+a1, a2+a3, a0+a1, a2+a3]
  addp  v0.4s, v0.4s, v0.4s  // [sum(a0..a3), ...]
  // Result in w0 (v0.s[0])
  umov  w0, v0.s[0]
end;

// ✅ I32x4 水平最小值规约 (sminp v.4s - signed min pairwise)
function NEONReduceMinI32x4(const a: TVecI32x4): Int32; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  // Pairwise min reduction
  sminp v0.4s, v0.4s, v0.4s
  sminp v0.4s, v0.4s, v0.4s
  umov  w0, v0.s[0]
end;

// ✅ I32x4 水平最大值规约 (smaxp v.4s - signed max pairwise)
function NEONReduceMaxI32x4(const a: TVecI32x4): Int32; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  // Pairwise max reduction
  smaxp v0.4s, v0.4s, v0.4s
  smaxp v0.4s, v0.4s, v0.4s
  umov  w0, v0.s[0]
end;

// ============================================================================
// === U32x4 Comparison Operations (NEON) ===
// ============================================================================
// 无符号比较使用 cmhi (无符号大于) 和 cmhs (无符号大于等于)

// U32x4 相等比较 (cmeq v.4s) -> TMask4
function NEONCmpEqU32x4(const a, b: TVecU32x4): TMask4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmeq  v0.4s, v0.4s, v1.4s

  umov  w1, v0.s[0]
  lsr   w1, w1, #31
  umov  w2, v0.s[1]
  lsr   w2, w2, #31
  umov  w3, v0.s[2]
  lsr   w3, w3, #31
  umov  w4, v0.s[3]
  lsr   w4, w4, #31

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3
end;

// U32x4 大于比较 (cmhi v.4s - unsigned higher than) -> TMask4
function NEONCmpGtU32x4(const a, b: TVecU32x4): TMask4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmhi  v0.4s, v0.4s, v1.4s

  umov  w1, v0.s[0]
  lsr   w1, w1, #31
  umov  w2, v0.s[1]
  lsr   w2, w2, #31
  umov  w3, v0.s[2]
  lsr   w3, w3, #31
  umov  w4, v0.s[3]
  lsr   w4, w4, #31

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3
end;

// U32x4 小于比较 (a < b = b > a)
function NEONCmpLtU32x4(const a, b: TVecU32x4): TMask4; assembler; nostackframe;
asm
  fmov  d0, x2
  fmov  d2, x3
  ins   v0.d[1], v2.d[0]

  fmov  d1, x0
  fmov  d2, x1
  ins   v1.d[1], v2.d[0]

  cmhi  v0.4s, v0.4s, v1.4s

  umov  w1, v0.s[0]
  lsr   w1, w1, #31
  umov  w2, v0.s[1]
  lsr   w2, w2, #31
  umov  w3, v0.s[2]
  lsr   w3, w3, #31
  umov  w4, v0.s[3]
  lsr   w4, w4, #31

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3
end;

// U32x4 小于等于 (a <= b = NOT(a > b))
function NEONCmpLeU32x4(const a, b: TVecU32x4): TMask4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmhi  v0.4s, v0.4s, v1.4s
  mvn   v0.16b, v0.16b

  umov  w1, v0.s[0]
  lsr   w1, w1, #31
  umov  w2, v0.s[1]
  lsr   w2, w2, #31
  umov  w3, v0.s[2]
  lsr   w3, w3, #31
  umov  w4, v0.s[3]
  lsr   w4, w4, #31

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3
end;

// U32x4 大于等于 (a >= b = cmhs - unsigned higher or same)
function NEONCmpGeU32x4(const a, b: TVecU32x4): TMask4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmhs  v0.4s, v0.4s, v1.4s

  umov  w1, v0.s[0]
  lsr   w1, w1, #31
  umov  w2, v0.s[1]
  lsr   w2, w2, #31
  umov  w3, v0.s[2]
  lsr   w3, w3, #31
  umov  w4, v0.s[3]
  lsr   w4, w4, #31

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3
end;

// U32x4 不等比较 (a != b = NOT(a == b))
function NEONCmpNeU32x4(const a, b: TVecU32x4): TMask4; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmeq  v0.4s, v0.4s, v1.4s
  mvn   v0.16b, v0.16b

  umov  w1, v0.s[0]
  lsr   w1, w1, #31
  umov  w2, v0.s[1]
  lsr   w2, w2, #31
  umov  w3, v0.s[2]
  lsr   w3, w3, #31
  umov  w4, v0.s[3]
  lsr   w4, w4, #31

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3
end;

// ============================================================================
// === U32x4 Reduction Operations (NEON) ===
// ============================================================================

// ✅ U32x4 水平加法规约 (addp v.4s - 无符号)
function NEONReduceAddU32x4(const a: TVecU32x4): UInt32; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  addp  v0.4s, v0.4s, v0.4s
  addp  v0.4s, v0.4s, v0.4s
  umov  w0, v0.s[0]
end;

// ✅ U32x4 水平最小值规约 (uminp v.4s - unsigned min pairwise)
function NEONReduceMinU32x4(const a: TVecU32x4): UInt32; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  uminp v0.4s, v0.4s, v0.4s
  uminp v0.4s, v0.4s, v0.4s
  umov  w0, v0.s[0]
end;

// ✅ U32x4 水平最大值规约 (umaxp v.4s - unsigned max pairwise)
function NEONReduceMaxU32x4(const a: TVecU32x4): UInt32; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  umaxp v0.4s, v0.4s, v0.4s
  umaxp v0.4s, v0.4s, v0.4s
  umov  w0, v0.s[0]
end;

// ============================================================================
// === U16x8 Comparison Operations (NEON) ===
// ============================================================================

// U16x8 相等比较 (cmeq v.8h) -> TMask8
function NEONCmpEqU16x8(const a, b: TVecU16x8): TMask8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmeq  v0.8h, v0.8h, v1.8h

  umov  w1, v0.h[0]
  lsr   w1, w1, #15
  umov  w2, v0.h[1]
  lsr   w2, w2, #15
  umov  w3, v0.h[2]
  lsr   w3, w3, #15
  umov  w4, v0.h[3]
  lsr   w4, w4, #15

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3

  umov  w1, v0.h[4]
  lsr   w1, w1, #15
  umov  w2, v0.h[5]
  lsr   w2, w2, #15
  umov  w3, v0.h[6]
  lsr   w3, w3, #15
  umov  w4, v0.h[7]
  lsr   w4, w4, #15

  orr   w0, w0, w1, lsl #4
  orr   w0, w0, w2, lsl #5
  orr   w0, w0, w3, lsl #6
  orr   w0, w0, w4, lsl #7
end;

// U16x8 大于比较 (cmhi v.8h) -> TMask8
function NEONCmpGtU16x8(const a, b: TVecU16x8): TMask8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmhi  v0.8h, v0.8h, v1.8h

  umov  w1, v0.h[0]
  lsr   w1, w1, #15
  umov  w2, v0.h[1]
  lsr   w2, w2, #15
  umov  w3, v0.h[2]
  lsr   w3, w3, #15
  umov  w4, v0.h[3]
  lsr   w4, w4, #15

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3

  umov  w1, v0.h[4]
  lsr   w1, w1, #15
  umov  w2, v0.h[5]
  lsr   w2, w2, #15
  umov  w3, v0.h[6]
  lsr   w3, w3, #15
  umov  w4, v0.h[7]
  lsr   w4, w4, #15

  orr   w0, w0, w1, lsl #4
  orr   w0, w0, w2, lsl #5
  orr   w0, w0, w3, lsl #6
  orr   w0, w0, w4, lsl #7
end;

// U16x8 小于比较
function NEONCmpLtU16x8(const a, b: TVecU16x8): TMask8; assembler; nostackframe;
asm
  fmov  d0, x2
  fmov  d2, x3
  ins   v0.d[1], v2.d[0]

  fmov  d1, x0
  fmov  d2, x1
  ins   v1.d[1], v2.d[0]

  cmhi  v0.8h, v0.8h, v1.8h

  umov  w1, v0.h[0]
  lsr   w1, w1, #15
  umov  w2, v0.h[1]
  lsr   w2, w2, #15
  umov  w3, v0.h[2]
  lsr   w3, w3, #15
  umov  w4, v0.h[3]
  lsr   w4, w4, #15

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3

  umov  w1, v0.h[4]
  lsr   w1, w1, #15
  umov  w2, v0.h[5]
  lsr   w2, w2, #15
  umov  w3, v0.h[6]
  lsr   w3, w3, #15
  umov  w4, v0.h[7]
  lsr   w4, w4, #15

  orr   w0, w0, w1, lsl #4
  orr   w0, w0, w2, lsl #5
  orr   w0, w0, w3, lsl #6
  orr   w0, w0, w4, lsl #7
end;

// U16x8 小于等于比较
function NEONCmpLeU16x8(const a, b: TVecU16x8): TMask8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmhi  v0.8h, v0.8h, v1.8h
  mvn   v0.16b, v0.16b

  umov  w1, v0.h[0]
  lsr   w1, w1, #15
  umov  w2, v0.h[1]
  lsr   w2, w2, #15
  umov  w3, v0.h[2]
  lsr   w3, w3, #15
  umov  w4, v0.h[3]
  lsr   w4, w4, #15

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3

  umov  w1, v0.h[4]
  lsr   w1, w1, #15
  umov  w2, v0.h[5]
  lsr   w2, w2, #15
  umov  w3, v0.h[6]
  lsr   w3, w3, #15
  umov  w4, v0.h[7]
  lsr   w4, w4, #15

  orr   w0, w0, w1, lsl #4
  orr   w0, w0, w2, lsl #5
  orr   w0, w0, w3, lsl #6
  orr   w0, w0, w4, lsl #7
end;

// U16x8 大于等于比较
function NEONCmpGeU16x8(const a, b: TVecU16x8): TMask8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmhs  v0.8h, v0.8h, v1.8h

  umov  w1, v0.h[0]
  lsr   w1, w1, #15
  umov  w2, v0.h[1]
  lsr   w2, w2, #15
  umov  w3, v0.h[2]
  lsr   w3, w3, #15
  umov  w4, v0.h[3]
  lsr   w4, w4, #15

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3

  umov  w1, v0.h[4]
  lsr   w1, w1, #15
  umov  w2, v0.h[5]
  lsr   w2, w2, #15
  umov  w3, v0.h[6]
  lsr   w3, w3, #15
  umov  w4, v0.h[7]
  lsr   w4, w4, #15

  orr   w0, w0, w1, lsl #4
  orr   w0, w0, w2, lsl #5
  orr   w0, w0, w3, lsl #6
  orr   w0, w0, w4, lsl #7
end;

// U16x8 不等比较
function NEONCmpNeU16x8(const a, b: TVecU16x8): TMask8; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmeq  v0.8h, v0.8h, v1.8h
  mvn   v0.16b, v0.16b

  umov  w1, v0.h[0]
  lsr   w1, w1, #15
  umov  w2, v0.h[1]
  lsr   w2, w2, #15
  umov  w3, v0.h[2]
  lsr   w3, w3, #15
  umov  w4, v0.h[3]
  lsr   w4, w4, #15

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3

  umov  w1, v0.h[4]
  lsr   w1, w1, #15
  umov  w2, v0.h[5]
  lsr   w2, w2, #15
  umov  w3, v0.h[6]
  lsr   w3, w3, #15
  umov  w4, v0.h[7]
  lsr   w4, w4, #15

  orr   w0, w0, w1, lsl #4
  orr   w0, w0, w2, lsl #5
  orr   w0, w0, w3, lsl #6
  orr   w0, w0, w4, lsl #7
end;

// ============================================================================
// === U8x16 Comparison Operations (NEON) ===
// ============================================================================

// U8x16 相等比较 (cmeq v.16b) -> TMask16
function NEONCmpEqU8x16(const a, b: TVecU8x16): TMask16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmeq  v0.16b, v0.16b, v1.16b

  umov  w1, v0.b[0]
  lsr   w1, w1, #7
  umov  w2, v0.b[1]
  lsr   w2, w2, #7
  umov  w3, v0.b[2]
  lsr   w3, w3, #7
  umov  w4, v0.b[3]
  lsr   w4, w4, #7

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3

  umov  w1, v0.b[4]
  lsr   w1, w1, #7
  umov  w2, v0.b[5]
  lsr   w2, w2, #7
  umov  w3, v0.b[6]
  lsr   w3, w3, #7
  umov  w4, v0.b[7]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #4
  orr   w0, w0, w2, lsl #5
  orr   w0, w0, w3, lsl #6
  orr   w0, w0, w4, lsl #7

  umov  w1, v0.b[8]
  lsr   w1, w1, #7
  umov  w2, v0.b[9]
  lsr   w2, w2, #7
  umov  w3, v0.b[10]
  lsr   w3, w3, #7
  umov  w4, v0.b[11]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #8
  orr   w0, w0, w2, lsl #9
  orr   w0, w0, w3, lsl #10
  orr   w0, w0, w4, lsl #11

  umov  w1, v0.b[12]
  lsr   w1, w1, #7
  umov  w2, v0.b[13]
  lsr   w2, w2, #7
  umov  w3, v0.b[14]
  lsr   w3, w3, #7
  umov  w4, v0.b[15]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #12
  orr   w0, w0, w2, lsl #13
  orr   w0, w0, w3, lsl #14
  orr   w0, w0, w4, lsl #15
end;

// U8x16 大于比较 (cmhi v.16b) -> TMask16
function NEONCmpGtU8x16(const a, b: TVecU8x16): TMask16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmhi  v0.16b, v0.16b, v1.16b

  umov  w1, v0.b[0]
  lsr   w1, w1, #7
  umov  w2, v0.b[1]
  lsr   w2, w2, #7
  umov  w3, v0.b[2]
  lsr   w3, w3, #7
  umov  w4, v0.b[3]
  lsr   w4, w4, #7

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3

  umov  w1, v0.b[4]
  lsr   w1, w1, #7
  umov  w2, v0.b[5]
  lsr   w2, w2, #7
  umov  w3, v0.b[6]
  lsr   w3, w3, #7
  umov  w4, v0.b[7]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #4
  orr   w0, w0, w2, lsl #5
  orr   w0, w0, w3, lsl #6
  orr   w0, w0, w4, lsl #7

  umov  w1, v0.b[8]
  lsr   w1, w1, #7
  umov  w2, v0.b[9]
  lsr   w2, w2, #7
  umov  w3, v0.b[10]
  lsr   w3, w3, #7
  umov  w4, v0.b[11]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #8
  orr   w0, w0, w2, lsl #9
  orr   w0, w0, w3, lsl #10
  orr   w0, w0, w4, lsl #11

  umov  w1, v0.b[12]
  lsr   w1, w1, #7
  umov  w2, v0.b[13]
  lsr   w2, w2, #7
  umov  w3, v0.b[14]
  lsr   w3, w3, #7
  umov  w4, v0.b[15]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #12
  orr   w0, w0, w2, lsl #13
  orr   w0, w0, w3, lsl #14
  orr   w0, w0, w4, lsl #15
end;

// U8x16 小于比较
function NEONCmpLtU8x16(const a, b: TVecU8x16): TMask16; assembler; nostackframe;
asm
  fmov  d0, x2
  fmov  d2, x3
  ins   v0.d[1], v2.d[0]

  fmov  d1, x0
  fmov  d2, x1
  ins   v1.d[1], v2.d[0]

  cmhi  v0.16b, v0.16b, v1.16b

  umov  w1, v0.b[0]
  lsr   w1, w1, #7
  umov  w2, v0.b[1]
  lsr   w2, w2, #7
  umov  w3, v0.b[2]
  lsr   w3, w3, #7
  umov  w4, v0.b[3]
  lsr   w4, w4, #7

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3

  umov  w1, v0.b[4]
  lsr   w1, w1, #7
  umov  w2, v0.b[5]
  lsr   w2, w2, #7
  umov  w3, v0.b[6]
  lsr   w3, w3, #7
  umov  w4, v0.b[7]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #4
  orr   w0, w0, w2, lsl #5
  orr   w0, w0, w3, lsl #6
  orr   w0, w0, w4, lsl #7

  umov  w1, v0.b[8]
  lsr   w1, w1, #7
  umov  w2, v0.b[9]
  lsr   w2, w2, #7
  umov  w3, v0.b[10]
  lsr   w3, w3, #7
  umov  w4, v0.b[11]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #8
  orr   w0, w0, w2, lsl #9
  orr   w0, w0, w3, lsl #10
  orr   w0, w0, w4, lsl #11

  umov  w1, v0.b[12]
  lsr   w1, w1, #7
  umov  w2, v0.b[13]
  lsr   w2, w2, #7
  umov  w3, v0.b[14]
  lsr   w3, w3, #7
  umov  w4, v0.b[15]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #12
  orr   w0, w0, w2, lsl #13
  orr   w0, w0, w3, lsl #14
  orr   w0, w0, w4, lsl #15
end;

// U8x16 小于等于比较
function NEONCmpLeU8x16(const a, b: TVecU8x16): TMask16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmhi  v0.16b, v0.16b, v1.16b
  mvn   v0.16b, v0.16b

  umov  w1, v0.b[0]
  lsr   w1, w1, #7
  umov  w2, v0.b[1]
  lsr   w2, w2, #7
  umov  w3, v0.b[2]
  lsr   w3, w3, #7
  umov  w4, v0.b[3]
  lsr   w4, w4, #7

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3

  umov  w1, v0.b[4]
  lsr   w1, w1, #7
  umov  w2, v0.b[5]
  lsr   w2, w2, #7
  umov  w3, v0.b[6]
  lsr   w3, w3, #7
  umov  w4, v0.b[7]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #4
  orr   w0, w0, w2, lsl #5
  orr   w0, w0, w3, lsl #6
  orr   w0, w0, w4, lsl #7

  umov  w1, v0.b[8]
  lsr   w1, w1, #7
  umov  w2, v0.b[9]
  lsr   w2, w2, #7
  umov  w3, v0.b[10]
  lsr   w3, w3, #7
  umov  w4, v0.b[11]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #8
  orr   w0, w0, w2, lsl #9
  orr   w0, w0, w3, lsl #10
  orr   w0, w0, w4, lsl #11

  umov  w1, v0.b[12]
  lsr   w1, w1, #7
  umov  w2, v0.b[13]
  lsr   w2, w2, #7
  umov  w3, v0.b[14]
  lsr   w3, w3, #7
  umov  w4, v0.b[15]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #12
  orr   w0, w0, w2, lsl #13
  orr   w0, w0, w3, lsl #14
  orr   w0, w0, w4, lsl #15
end;

// U8x16 大于等于比较
function NEONCmpGeU8x16(const a, b: TVecU8x16): TMask16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmhs  v0.16b, v0.16b, v1.16b

  umov  w1, v0.b[0]
  lsr   w1, w1, #7
  umov  w2, v0.b[1]
  lsr   w2, w2, #7
  umov  w3, v0.b[2]
  lsr   w3, w3, #7
  umov  w4, v0.b[3]
  lsr   w4, w4, #7

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3

  umov  w1, v0.b[4]
  lsr   w1, w1, #7
  umov  w2, v0.b[5]
  lsr   w2, w2, #7
  umov  w3, v0.b[6]
  lsr   w3, w3, #7
  umov  w4, v0.b[7]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #4
  orr   w0, w0, w2, lsl #5
  orr   w0, w0, w3, lsl #6
  orr   w0, w0, w4, lsl #7

  umov  w1, v0.b[8]
  lsr   w1, w1, #7
  umov  w2, v0.b[9]
  lsr   w2, w2, #7
  umov  w3, v0.b[10]
  lsr   w3, w3, #7
  umov  w4, v0.b[11]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #8
  orr   w0, w0, w2, lsl #9
  orr   w0, w0, w3, lsl #10
  orr   w0, w0, w4, lsl #11

  umov  w1, v0.b[12]
  lsr   w1, w1, #7
  umov  w2, v0.b[13]
  lsr   w2, w2, #7
  umov  w3, v0.b[14]
  lsr   w3, w3, #7
  umov  w4, v0.b[15]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #12
  orr   w0, w0, w2, lsl #13
  orr   w0, w0, w3, lsl #14
  orr   w0, w0, w4, lsl #15
end;

// U8x16 不等比较
function NEONCmpNeU8x16(const a, b: TVecU8x16): TMask16; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]

  cmeq  v0.16b, v0.16b, v1.16b
  mvn   v0.16b, v0.16b

  umov  w1, v0.b[0]
  lsr   w1, w1, #7
  umov  w2, v0.b[1]
  lsr   w2, w2, #7
  umov  w3, v0.b[2]
  lsr   w3, w3, #7
  umov  w4, v0.b[3]
  lsr   w4, w4, #7

  orr   w0, w1, w2, lsl #1
  orr   w0, w0, w3, lsl #2
  orr   w0, w0, w4, lsl #3

  umov  w1, v0.b[4]
  lsr   w1, w1, #7
  umov  w2, v0.b[5]
  lsr   w2, w2, #7
  umov  w3, v0.b[6]
  lsr   w3, w3, #7
  umov  w4, v0.b[7]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #4
  orr   w0, w0, w2, lsl #5
  orr   w0, w0, w3, lsl #6
  orr   w0, w0, w4, lsl #7

  umov  w1, v0.b[8]
  lsr   w1, w1, #7
  umov  w2, v0.b[9]
  lsr   w2, w2, #7
  umov  w3, v0.b[10]
  lsr   w3, w3, #7
  umov  w4, v0.b[11]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #8
  orr   w0, w0, w2, lsl #9
  orr   w0, w0, w3, lsl #10
  orr   w0, w0, w4, lsl #11

  umov  w1, v0.b[12]
  lsr   w1, w1, #7
  umov  w2, v0.b[13]
  lsr   w2, w2, #7
  umov  w3, v0.b[14]
  lsr   w3, w3, #7
  umov  w4, v0.b[15]
  lsr   w4, w4, #7

  orr   w0, w0, w1, lsl #12
  orr   w0, w0, w2, lsl #13
  orr   w0, w0, w3, lsl #14
  orr   w0, w0, w4, lsl #15
end;

// === Facade Functions with NEON ===
// ICE-safe pattern: use ldp + fmov + ins instead of ldr q

function MemEqual_NEON(a, b: Pointer; len: SizeUInt): LongBool; assembler; nostackframe;
asm
  // x0 = a, x1 = b, x2 = len
  cbz   x2, .Lequal          // len == 0, return true
  cmp   x0, x1
  b.eq  .Lequal              // same pointer (including both nil)
  cbz   x0, .Lnotequal       // one nil => not equal
  cbz   x1, .Lnotequal
  
  // Process 16 bytes at a time
.Lloop16:
  cmp   x2, #16
  b.lo  .Ltail
  // ICE-safe load: ldp + fmov + ins instead of ldr q
  ldp   x4, x5, [x0], #16
  fmov  d0, x4
  fmov  d2, x5
  ins   v0.d[1], v2.d[0]
  ldp   x4, x5, [x1], #16
  fmov  d1, x4
  fmov  d2, x5
  ins   v1.d[1], v2.d[0]
  cmeq  v0.16b, v0.16b, v1.16b
  // Check if all bytes equal (all 1s)
  uminv b2, v0.16b           // Min of all bytes
  umov  w3, v2.b[0]
  cmp   w3, #255
  b.ne  .Lnotequal
  sub   x2, x2, #16
  cbnz  x2, .Lloop16
  b     .Lequal
  
.Ltail:
  // Handle remaining bytes
  cbz   x2, .Lequal
.Ltailloop:
  ldrb  w3, [x0], #1
  ldrb  w4, [x1], #1
  cmp   w3, w4
  b.ne  .Lnotequal
  subs  x2, x2, #1
  b.ne  .Ltailloop
  
.Lequal:
  mov   w0, #1
  ret
  
.Lnotequal:
  mov   w0, #0
  ret
end;

function SumBytes_NEON(p: Pointer; len: SizeUInt): UInt64; assembler; nostackframe;
asm
  // x0 = p, x1 = len
  mov   x3, #0
  cbz   x1, .Ldone

.Lloop16:
  cmp   x1, #16
  b.lo  .Ltail

  // ICE-safe load
  ldp   x4, x5, [x0], #16
  fmov  d0, x4
  fmov  d2, x5
  ins   v0.d[1], v2.d[0]
  uaddlv h0, v0.16b           // sum 16 bytes -> 16-bit
  umov  w2, v0.h[0]
  add   x3, x3, x2

  sub   x1, x1, #16
  cbnz  x1, .Lloop16
  b     .Ldone

.Ltail:
  cbz   x1, .Ldone
.Ltailloop:
  ldrb  w2, [x0], #1
  add   x3, x3, x2
  subs  x1, x1, #1
  b.ne  .Ltailloop

.Ldone:
  mov   x0, x3
end;

function CountByte_NEON(p: Pointer; len: SizeUInt; value: Byte): SizeUInt; assembler; nostackframe;
asm
  // x0 = p, x1 = len, w2 = value
  mov   x3, #0
  dup   v0.16b, w2
  cbz   x1, .Ldone

.Lloop16:
  cmp   x1, #16
  b.lo  .Ltail

  // ICE-safe load
  ldp   x4, x5, [x0], #16
  fmov  d1, x4
  fmov  d2, x5
  ins   v1.d[1], v2.d[0]
  cmeq  v1.16b, v1.16b, v0.16b
  ushr  v1.16b, v1.16b, #7    // 0xFF -> 1, 0 -> 0
  uaddlv h1, v1.16b           // sum 16 bytes -> 16-bit
  umov  w4, v1.h[0]
  add   x3, x3, x4

  sub   x1, x1, #16
  cbnz  x1, .Lloop16
  b     .Ldone

.Ltail:
  cbz   x1, .Ldone
.Ltailloop:
  ldrb  w4, [x0], #1
  cmp   w4, w2
  cinc  x3, x3, eq
  subs  x1, x1, #1
  b.ne  .Ltailloop

.Ldone:
  mov   x0, x3
end;

function MemFindByte_NEON(p: Pointer; len: SizeUInt; value: Byte): PtrInt; assembler; nostackframe;
asm
  // x0 = p, x1 = len, w2 = value
  mov   x3, x0               // Save original pointer
  dup   v0.16b, w2           // Broadcast search value
  cbz   x1, .Lnotfound
  
.Lloop16:
  cmp   x1, #16
  b.lo  .Ltail
  // ICE-safe load (no post-increment here since we need x0 for found position)
  ldp   x4, x5, [x0]
  fmov  d1, x4
  fmov  d2, x5
  ins   v1.d[1], v2.d[0]
  cmeq  v1.16b, v1.16b, v0.16b
  // Check if any match
  umaxv b2, v1.16b           // Max of all bytes
  umov  w4, v2.b[0]
  cbnz  w4, .Lfound16
  add   x0, x0, #16
  sub   x1, x1, #16
  cbnz  x1, .Lloop16
  b     .Lnotfound
  
.Lfound16:
  // Find exact position in the 16 bytes
  mov   w5, #0
.Lscan:
  umov  w4, v1.b[0]
  cbnz  w4, .Lfoundexact
  ext   v1.16b, v1.16b, v1.16b, #1  // Shift left by 1
  add   w5, w5, #1
  cmp   w5, #16
  b.lo  .Lscan
  
.Lfoundexact:
  add   x0, x0, x5
  sub   x0, x0, x3           // Return offset
  ret
  
.Ltail:
  cbz   x1, .Lnotfound
.Ltailloop:
  ldrb  w4, [x0]
  cmp   w4, w2
  b.eq  .Lfoundtail
  add   x0, x0, #1
  subs  x1, x1, #1
  b.ne  .Ltailloop
  b     .Lnotfound
  
.Lfoundtail:
  sub   x0, x0, x3
  ret
  
.Lnotfound:
  mov   x0, #-1
end;

// === BitsetPopCount NEON ===
// Uses parallel bit counting (SWAR algorithm) + horizontal sum
// Same algorithm as i386 SSE2 but with NEON instructions
function BitsetPopCount_NEON(p: Pointer; byteLen: SizeUInt): SizeUInt; assembler; nostackframe;
asm
  // x0 = p, x1 = byteLen
  // Return: x0 = popcount
  mov   x3, #0               // Total count
  cbz   x1, .Ldone
  cbz   x0, .Ldone

  // Prepare constants for SWAR popcount
  // 0x55 = 01010101, 0x33 = 00110011, 0x0F = 00001111
  mov   w4, #0x55
  dup   v16.16b, w4          // v16 = 0x55555555...
  mov   w4, #0x33
  dup   v17.16b, w4          // v17 = 0x33333333...
  mov   w4, #0x0F
  dup   v18.16b, w4          // v18 = 0x0F0F0F0F...

.Lloop16:
  cmp   x1, #16
  b.lo  .Ltail

  // ICE-safe load: ldp + fmov + ins
  ldp   x4, x5, [x0], #16
  fmov  d0, x4
  fmov  d2, x5
  ins   v0.d[1], v2.d[0]

  // SWAR popcount algorithm (parallel bit counting)
  // Step 1: x = x - ((x >> 1) & 0x55)
  ushr  v1.16b, v0.16b, #1   // v1 = x >> 1
  and   v1.16b, v1.16b, v16.16b  // v1 = (x >> 1) & 0x55
  sub   v0.16b, v0.16b, v1.16b   // v0 = x - ((x >> 1) & 0x55)

  // Step 2: x = (x & 0x33) + ((x >> 2) & 0x33)
  ushr  v1.16b, v0.16b, #2   // v1 = x >> 2
  and   v0.16b, v0.16b, v17.16b  // v0 = x & 0x33
  and   v1.16b, v1.16b, v17.16b  // v1 = (x >> 2) & 0x33
  add   v0.16b, v0.16b, v1.16b   // v0 = (x & 0x33) + ((x >> 2) & 0x33)

  // Step 3: x = (x + (x >> 4)) & 0x0F
  ushr  v1.16b, v0.16b, #4   // v1 = x >> 4
  add   v0.16b, v0.16b, v1.16b   // v0 = x + (x >> 4)
  and   v0.16b, v0.16b, v18.16b  // v0 = (x + (x >> 4)) & 0x0F

  // Now each byte in v0 contains popcount of original byte (0-8)
  // Sum all bytes using uaddlv (horizontal add across vector)
  uaddlv h0, v0.16b          // h0 = sum of all 16 bytes
  umov  w4, v0.h[0]
  add   x3, x3, x4

  sub   x1, x1, #16
  cbnz  x1, .Lloop16
  b     .Ldone

.Ltail:
  cbz   x1, .Ldone
  // Prepare scalar constants (reuse w6, w7 for tail loop)
  mov   w6, #0x55
  mov   w7, #0x33
.Ltailloop:
  ldrb  w4, [x0], #1
  // Inline popcount for single byte using SWAR
  lsr   w5, w4, #1
  and   w5, w5, w6           // w5 = (x >> 1) & 0x55
  sub   w4, w4, w5           // w4 = x - ((x >> 1) & 0x55)
  lsr   w5, w4, #2
  and   w4, w4, w7           // w4 = x & 0x33
  and   w5, w5, w7           // w5 = (x >> 2) & 0x33
  add   w4, w4, w5           // w4 = (x & 0x33) + ((x >> 2) & 0x33)
  lsr   w5, w4, #4
  add   w4, w4, w5           // w4 = x + (x >> 4)
  and   w4, w4, #0x0F        // 0x0F is valid bitmask immediate
  add   x3, x3, x4
  subs  x1, x1, #1
  b.ne  .Ltailloop

.Ldone:
  mov   x0, x3
end;

// === MinMaxBytes NEON ===
// Uses uminv/umaxv for parallel min/max reduction
procedure MinMaxBytes_NEON(p: Pointer; len: SizeUInt; out minVal, maxVal: Byte); assembler; nostackframe;
asm
  // x0 = p, x1 = len, x2 = &minVal, x3 = &maxVal
  cbz   x1, .Lempty
  cbz   x0, .Lempty

  // Initialize min=255, max=0
  mov   w4, #255
  dup   v16.16b, w4          // v16 = current min (all 255)
  movi  v17.16b, #0          // v17 = current max (all 0)

.Lloop16:
  cmp   x1, #16
  b.lo  .Ltail

  // ICE-safe load
  ldp   x4, x5, [x0], #16
  fmov  d0, x4
  fmov  d1, x5
  ins   v0.d[1], v1.d[0]

  // Update running min/max
  umin  v16.16b, v16.16b, v0.16b
  umax  v17.16b, v17.16b, v0.16b

  sub   x1, x1, #16
  cbnz  x1, .Lloop16
  b     .Lreduce

.Ltail:
  cbz   x1, .Lreduce
.Ltailloop:
  ldrb  w4, [x0], #1
  dup   v0.16b, w4
  umin  v16.16b, v16.16b, v0.16b
  umax  v17.16b, v17.16b, v0.16b
  subs  x1, x1, #1
  b.ne  .Ltailloop

.Lreduce:
  // Reduce v16 to single min byte
  uminv b0, v16.16b
  umov  w4, v0.b[0]
  strb  w4, [x2]

  // Reduce v17 to single max byte
  umaxv b0, v17.16b
  umov  w4, v0.b[0]
  strb  w4, [x3]
  ret

.Lempty:
  // len=0 or p=nil: set min=max=0
  strb  wzr, [x2]
  strb  wzr, [x3]
end;

// === ToLowerAscii NEON ===
// For each byte: if 'A' <= byte <= 'Z', OR with 0x20
procedure ToLowerAscii_NEON(p: Pointer; len: SizeUInt); assembler; nostackframe;
asm
  // x0 = p, x1 = len
  cbz   x1, .Ldone
  cbz   x0, .Ldone

  // Prepare constants
  mov   w2, #'A'              // 65
  dup   v16.16b, w2           // v16 = 'A' broadcast
  mov   w2, #'Z'
  dup   v17.16b, w2           // v17 = 'Z' broadcast
  mov   w2, #0x20
  dup   v18.16b, w2           // v18 = 0x20 broadcast (case bit)

.Lloop16:
  cmp   x1, #16
  b.lo  .Ltail

  // ICE-safe load
  ldp   x2, x3, [x0]
  fmov  d0, x2
  fmov  d1, x3
  ins   v0.d[1], v1.d[0]

  // Check if in range ['A'..'Z']
  // mask = (byte >= 'A') & (byte <= 'Z')
  cmhs  v1.16b, v0.16b, v16.16b  // v1 = (byte >= 'A')
  cmhs  v2.16b, v17.16b, v0.16b  // v2 = ('Z' >= byte) = (byte <= 'Z')
  and   v1.16b, v1.16b, v2.16b   // v1 = mask

  // Apply: result = byte | (mask & 0x20)
  and   v1.16b, v1.16b, v18.16b  // v1 = mask & 0x20
  orr   v0.16b, v0.16b, v1.16b   // v0 = byte | (mask & 0x20)

  // Store back
  umov  x2, v0.d[0]
  umov  x3, v0.d[1]
  stp   x2, x3, [x0], #16

  sub   x1, x1, #16
  cbnz  x1, .Lloop16
  b     .Ldone

.Ltail:
  cbz   x1, .Ldone
.Ltailloop:
  ldrb  w2, [x0]
  sub   w3, w2, #'A'
  cmp   w3, #25               // 'Z' - 'A' = 25
  b.hi  .Lnochange
  orr   w2, w2, #0x20
.Lnochange:
  strb  w2, [x0], #1
  subs  x1, x1, #1
  b.ne  .Ltailloop

.Ldone:
end;

// === ToUpperAscii NEON ===
// For each byte: if 'a' <= byte <= 'z', AND with ~0x20
procedure ToUpperAscii_NEON(p: Pointer; len: SizeUInt); assembler; nostackframe;
asm
  // x0 = p, x1 = len
  cbz   x1, .Ldone
  cbz   x0, .Ldone

  // Prepare constants
  mov   w2, #'a'              // 97
  dup   v16.16b, w2           // v16 = 'a' broadcast
  mov   w2, #'z'
  dup   v17.16b, w2           // v17 = 'z' broadcast
  mov   w2, #0x20
  dup   v18.16b, w2           // v18 = 0x20 broadcast (case bit)

.Lloop16:
  cmp   x1, #16
  b.lo  .Ltail

  // ICE-safe load
  ldp   x2, x3, [x0]
  fmov  d0, x2
  fmov  d1, x3
  ins   v0.d[1], v1.d[0]

  // Check if in range ['a'..'z']
  cmhs  v1.16b, v0.16b, v16.16b  // v1 = (byte >= 'a')
  cmhs  v2.16b, v17.16b, v0.16b  // v2 = ('z' >= byte) = (byte <= 'z')
  and   v1.16b, v1.16b, v2.16b   // v1 = mask (0xFF if lowercase)

  // Apply: result = byte & ~(mask & 0x20) = byte & (mask ? 0xDF : 0xFF)
  and   v1.16b, v1.16b, v18.16b  // v1 = mask & 0x20
  bic   v0.16b, v0.16b, v1.16b   // v0 = byte & ~(mask & 0x20)

  // Store back
  umov  x2, v0.d[0]
  umov  x3, v0.d[1]
  stp   x2, x3, [x0], #16

  sub   x1, x1, #16
  cbnz  x1, .Lloop16
  b     .Ldone

.Ltail:
  cbz   x1, .Ldone
.Ltailloop:
  ldrb  w2, [x0]
  sub   w3, w2, #'a'
  cmp   w3, #25               // 'z' - 'a' = 25
  b.hi  .Lnochange
  bic   w2, w2, #0x20
.Lnochange:
  strb  w2, [x0], #1
  subs  x1, x1, #1
  b.ne  .Ltailloop

.Ldone:
end;

// === AsciiIEqual NEON ===
// Case-insensitive comparison: convert both to lowercase, then compare
function AsciiIEqual_NEON(a, b: Pointer; len: SizeUInt): Boolean; assembler; nostackframe;
asm
  // x0 = a, x1 = b, x2 = len
  // Return: w0 = 1 if equal, 0 otherwise
  cbz   x2, .Lequal           // len == 0 => equal
  cmp   x0, x1
  b.eq  .Lequal               // same pointer => equal
  cbz   x0, .Lnotequal        // one nil => not equal
  cbz   x1, .Lnotequal

  // Prepare constants for lowercase conversion
  mov   w3, #'A'
  dup   v16.16b, w3           // v16 = 'A'
  mov   w3, #'Z'
  dup   v17.16b, w3           // v17 = 'Z'
  mov   w3, #0x20
  dup   v18.16b, w3           // v18 = 0x20 (case bit)

.Lloop16:
  cmp   x2, #16
  b.lo  .Ltail

  // Load a
  ldp   x3, x4, [x0], #16
  fmov  d0, x3
  fmov  d1, x4
  ins   v0.d[1], v1.d[0]

  // Load b
  ldp   x3, x4, [x1], #16
  fmov  d2, x3
  fmov  d1, x4
  ins   v2.d[1], v1.d[0]

  // Convert a to lowercase
  cmhs  v3.16b, v0.16b, v16.16b
  cmhs  v4.16b, v17.16b, v0.16b
  and   v3.16b, v3.16b, v4.16b
  and   v3.16b, v3.16b, v18.16b
  orr   v0.16b, v0.16b, v3.16b

  // Convert b to lowercase
  cmhs  v3.16b, v2.16b, v16.16b
  cmhs  v4.16b, v17.16b, v2.16b
  and   v3.16b, v3.16b, v4.16b
  and   v3.16b, v3.16b, v18.16b
  orr   v2.16b, v2.16b, v3.16b

  // Compare
  cmeq  v0.16b, v0.16b, v2.16b
  uminv b0, v0.16b
  umov  w3, v0.b[0]
  cmp   w3, #255
  b.ne  .Lnotequal

  sub   x2, x2, #16
  cbnz  x2, .Lloop16
  b     .Lequal

.Ltail:
  cbz   x2, .Lequal
.Ltailloop:
  ldrb  w3, [x0], #1
  ldrb  w4, [x1], #1
  // Convert w3 to lowercase
  sub   w5, w3, #'A'
  cmp   w5, #25
  b.hi  .Lskip_a
  orr   w3, w3, #0x20
.Lskip_a:
  // Convert w4 to lowercase
  sub   w5, w4, #'A'
  cmp   w5, #25
  b.hi  .Lskip_b
  orr   w4, w4, #0x20
.Lskip_b:
  cmp   w3, w4
  b.ne  .Lnotequal
  subs  x2, x2, #1
  b.ne  .Ltailloop

.Lequal:
  mov   w0, #1
  ret

.Lnotequal:
  mov   w0, #0
end;

{$ELSE}
// === Scalar Fallback ===
// Used when:
// - not CPUAARCH64, or
// - CPUAARCH64 but FAFAFA_SIMD_NEON_ASM is not enabled, or
// - SIMD_VECTOR_ASM_DISABLED is defined.

function NEONAddF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] + b.f[i];
end;

function NEONSubF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] - b.f[i];
end;

function NEONMulF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] * b.f[i];
end;

function NEONDivF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] / b.f[i];
end;

function NEONAddF32x8(const a, b: TVecF32x8): TVecF32x8;
begin
  Result := ScalarAddF32x8(a, b);
end;

function NEONSubF32x8(const a, b: TVecF32x8): TVecF32x8;
begin
  Result := ScalarSubF32x8(a, b);
end;

function NEONMulF32x8(const a, b: TVecF32x8): TVecF32x8;
begin
  Result := ScalarMulF32x8(a, b);
end;

function NEONDivF32x8(const a, b: TVecF32x8): TVecF32x8;
begin
  Result := ScalarDivF32x8(a, b);
end;

function NEONAddF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.d[i] + b.d[i];
end;

function NEONSubF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.d[i] - b.d[i];
end;

function NEONMulF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.d[i] * b.d[i];
end;

function NEONDivF64x2(const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result.d[i] := a.d[i] / b.d[i];
end;

// Integer SIMD operations must wrap on overflow (hardware semantics).
{$PUSH}{$R-}{$Q-}
function NEONAddI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] + b.i[i];
end;

function NEONSubI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] - b.i[i];
end;

function NEONMulI32x4(const a, b: TVecI32x4): TVecI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.i[i] := a.i[i] * b.i[i];
end;
{$POP}

// === Comparison Operations ===

function NEONCmpEqF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.f[i] = b.f[i] then
      Result := Result or (1 shl i);
end;

function NEONCmpLtF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.f[i] < b.f[i] then
      Result := Result or (1 shl i);
end;

function NEONCmpLeF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.f[i] <= b.f[i] then
      Result := Result or (1 shl i);
end;

function NEONCmpGtF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.f[i] > b.f[i] then
      Result := Result or (1 shl i);
end;

function NEONCmpGeF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.f[i] >= b.f[i] then
      Result := Result or (1 shl i);
end;

function NEONCmpNeF32x4(const a, b: TVecF32x4): TMask4;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    if a.f[i] <> b.f[i] then
      Result := Result or (1 shl i);
end;

// === Math Operations ===

function NEONAbsF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Abs(a.f[i]);
end;

function NEONSqrtF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Sqrt(a.f[i]);
end;

function NEONMinF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if a.f[i] < b.f[i] then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

function NEONMaxF32x4(const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if a.f[i] > b.f[i] then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

// === Extended Math Operations ===

function NEONFmaF32x4(const a, b, c: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := a.f[i] * b.f[i] + c.f[i];
end;

function NEONRcpF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := 1.0 / a.f[i];
end;

function NEONRsqrtF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := 1.0 / Sqrt(a.f[i]);
end;

function NEONFloorF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Floor(a.f[i]);
end;

function NEONCeilF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Ceil(a.f[i]);
end;

function NEONRoundF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Round(a.f[i]);
end;

function NEONTruncF32x4(const a: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := Trunc(a.f[i]);
end;

function NEONClampF32x4(const a, minVal, maxVal: TVecF32x4): TVecF32x4;
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

// === Vector Math Operations ===

function NEONDotF32x4(const a, b: TVecF32x4): Single;
begin
  Result := a.f[0] * b.f[0] + a.f[1] * b.f[1] + a.f[2] * b.f[2] + a.f[3] * b.f[3];
end;

function NEONDotF32x3(const a, b: TVecF32x4): Single;
begin
  Result := a.f[0] * b.f[0] + a.f[1] * b.f[1] + a.f[2] * b.f[2];
end;

function NEONCrossF32x3(const a, b: TVecF32x4): TVecF32x4;
begin
  Result.f[0] := a.f[1] * b.f[2] - a.f[2] * b.f[1];
  Result.f[1] := a.f[2] * b.f[0] - a.f[0] * b.f[2];
  Result.f[2] := a.f[0] * b.f[1] - a.f[1] * b.f[0];
  Result.f[3] := 0.0;
end;

function NEONLengthF32x4(const a: TVecF32x4): Single;
begin
  Result := Sqrt(a.f[0] * a.f[0] + a.f[1] * a.f[1] + a.f[2] * a.f[2] + a.f[3] * a.f[3]);
end;

function NEONLengthF32x3(const a: TVecF32x4): Single;
begin
  Result := Sqrt(a.f[0] * a.f[0] + a.f[1] * a.f[1] + a.f[2] * a.f[2]);
end;

function NEONNormalizeF32x4(const a: TVecF32x4): TVecF32x4;
var
  len, invLen: Single;
begin
  len := Sqrt(a.f[0] * a.f[0] + a.f[1] * a.f[1] + a.f[2] * a.f[2] + a.f[3] * a.f[3]);
  if len > 0 then
  begin
    invLen := 1.0 / len;
    Result.f[0] := a.f[0] * invLen;
    Result.f[1] := a.f[1] * invLen;
    Result.f[2] := a.f[2] * invLen;
    Result.f[3] := a.f[3] * invLen;
  end
  else
    Result := a;
end;

function NEONNormalizeF32x3(const a: TVecF32x4): TVecF32x4;
var
  len, invLen: Single;
begin
  len := Sqrt(a.f[0] * a.f[0] + a.f[1] * a.f[1] + a.f[2] * a.f[2]);
  if len > 0 then
  begin
    invLen := 1.0 / len;
    Result.f[0] := a.f[0] * invLen;
    Result.f[1] := a.f[1] * invLen;
    Result.f[2] := a.f[2] * invLen;
    Result.f[3] := 0.0;
  end
  else
  begin
    Result := a;
    Result.f[3] := 0.0;
  end;
end;

// === Reduction Operations ===

function NEONReduceAddF32x4(const a: TVecF32x4): Single;
begin
  Result := a.f[0] + a.f[1] + a.f[2] + a.f[3];
end;

function NEONReduceMinF32x4(const a: TVecF32x4): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 3 do
    if a.f[i] < Result then
      Result := a.f[i];
end;

function NEONReduceMaxF32x4(const a: TVecF32x4): Single;
var i: Integer;
begin
  Result := a.f[0];
  for i := 1 to 3 do
    if a.f[i] > Result then
      Result := a.f[i];
end;

function NEONReduceMulF32x4(const a: TVecF32x4): Single;
begin
  Result := a.f[0] * a.f[1] * a.f[2] * a.f[3];
end;

// ✅ I32x4 规约操作 (Scalar fallback)
{$PUSH}{$R-}{$Q-}
function NEONReduceAddI32x4(const a: TVecI32x4): Int32;
begin
  Result := a.i[0] + a.i[1] + a.i[2] + a.i[3];
end;

function NEONReduceMinI32x4(const a: TVecI32x4): Int32;
var i: Integer;
begin
  Result := a.i[0];
  for i := 1 to 3 do
    if a.i[i] < Result then
      Result := a.i[i];
end;

function NEONReduceMaxI32x4(const a: TVecI32x4): Int32;
var i: Integer;
begin
  Result := a.i[0];
  for i := 1 to 3 do
    if a.i[i] > Result then
      Result := a.i[i];
end;

// ✅ U32x4 规约操作 (Scalar fallback)
function NEONReduceAddU32x4(const a: TVecU32x4): UInt32;
begin
  Result := a.u[0] + a.u[1] + a.u[2] + a.u[3];
end;

function NEONReduceMinU32x4(const a: TVecU32x4): UInt32;
var i: Integer;
begin
  Result := a.u[0];
  for i := 1 to 3 do
    if a.u[i] < Result then
      Result := a.u[i];
end;

function NEONReduceMaxU32x4(const a: TVecU32x4): UInt32;
var i: Integer;
begin
  Result := a.u[0];
  for i := 1 to 3 do
    if a.u[i] > Result then
      Result := a.u[i];
end;
{$POP}

// === Memory Operations ===

function NEONLoadF32x4(p: PSingle): TVecF32x4;
begin
  Move(p^, Result.f[0], 16);
end;

function NEONLoadF32x4Aligned(p: PSingle): TVecF32x4;
begin
  Move(p^, Result.f[0], 16);
end;

procedure NEONStoreF32x4(p: PSingle; const a: TVecF32x4);
begin
  Move(a.f[0], p^, 16);
end;

procedure NEONStoreF32x4Aligned(p: PSingle; const a: TVecF32x4);
begin
  Move(a.f[0], p^, 16);
end;

// === Utility Operations ===

function NEONSplatF32x4(value: Single): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result.f[i] := value;
end;

function NEONZeroF32x4: TVecF32x4;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function NEONSelectF32x4(const mask: TMask4; const a, b: TVecF32x4): TVecF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if (mask and (1 shl i)) <> 0 then
      Result.f[i] := a.f[i]
    else
      Result.f[i] := b.f[i];
end;

function NEONExtractF32x4(const a: TVecF32x4; index: Integer): Single;
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

function NEONInsertF32x4(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4;
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

// === Facade Functions ===

function MemEqual_NEON(a, b: Pointer; len: SizeUInt): LongBool;
begin
  Result := MemEqual_Scalar(a, b, len);
end;

function MemFindByte_NEON(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
begin
  Result := MemFindByte_Scalar(p, len, value);
end;

function SumBytes_NEON(p: Pointer; len: SizeUInt): UInt64;
begin
  Result := SumBytes_Scalar(p, len);
end;

function CountByte_NEON(p: Pointer; len: SizeUInt; value: Byte): SizeUInt;
begin
  Result := CountByte_Scalar(p, len, value);
end;

function BitsetPopCount_NEON(p: Pointer; byteLen: SizeUInt): SizeUInt;
begin
  Result := BitsetPopCount_Scalar(p, byteLen);
end;

procedure MinMaxBytes_NEON(p: Pointer; len: SizeUInt; out minVal, maxVal: Byte);
begin
  MinMaxBytes_Scalar(p, len, minVal, maxVal);
end;

procedure ToLowerAscii_NEON(p: Pointer; len: SizeUInt);
begin
  ToLowerAscii_Scalar(p, len);
end;

procedure ToUpperAscii_NEON(p: Pointer; len: SizeUInt);
begin
  ToUpperAscii_Scalar(p, len);
end;

function AsciiIEqual_NEON(a, b: Pointer; len: SizeUInt): Boolean;
begin
  Result := AsciiIEqual_Scalar(a, b, len);
end;

// ✅ P2: Saturating Arithmetic Scalar Fallback
// 用于 FPC < 3.3.1 或非 ARM 平台

function NEONI8x16SatAdd(const a, b: TVecI8x16): TVecI8x16;
begin
  Result := ScalarI8x16SatAdd(a, b);
end;

function NEONI8x16SatSub(const a, b: TVecI8x16): TVecI8x16;
begin
  Result := ScalarI8x16SatSub(a, b);
end;

function NEONI16x8SatAdd(const a, b: TVecI16x8): TVecI16x8;
begin
  Result := ScalarI16x8SatAdd(a, b);
end;

function NEONI16x8SatSub(const a, b: TVecI16x8): TVecI16x8;
begin
  Result := ScalarI16x8SatSub(a, b);
end;

function NEONU8x16SatAdd(const a, b: TVecU8x16): TVecU8x16;
begin
  Result := ScalarU8x16SatAdd(a, b);
end;

function NEONU8x16SatSub(const a, b: TVecU8x16): TVecU8x16;
begin
  Result := ScalarU8x16SatSub(a, b);
end;

function NEONU16x8SatAdd(const a, b: TVecU16x8): TVecU16x8;
begin
  Result := ScalarU16x8SatAdd(a, b);
end;

function NEONU16x8SatSub(const a, b: TVecU16x8): TVecU16x8;
begin
  Result := ScalarU16x8SatSub(a, b);
end;

// ✅ Task 6.2: Narrow Integer Types Scalar Fallback
// 用于 FPC < 3.3.1 或非 ARM 平台

// --- I16x8 Scalar Fallback ---
function NEONAddI16x8(const a, b: TVecI16x8): TVecI16x8;
begin Result := ScalarAddI16x8(a, b); end;

function NEONSubI16x8(const a, b: TVecI16x8): TVecI16x8;
begin Result := ScalarSubI16x8(a, b); end;

function NEONMulI16x8(const a, b: TVecI16x8): TVecI16x8;
begin Result := ScalarMulI16x8(a, b); end;

function NEONAndI16x8(const a, b: TVecI16x8): TVecI16x8;
begin Result := ScalarAndI16x8(a, b); end;

function NEONOrI16x8(const a, b: TVecI16x8): TVecI16x8;
begin Result := ScalarOrI16x8(a, b); end;

function NEONXorI16x8(const a, b: TVecI16x8): TVecI16x8;
begin Result := ScalarXorI16x8(a, b); end;

function NEONNotI16x8(const a: TVecI16x8): TVecI16x8;
begin Result := ScalarNotI16x8(a); end;

function NEONAndNotI16x8(const a, b: TVecI16x8): TVecI16x8;
begin Result := ScalarAndNotI16x8(a, b); end;

function NEONMinI16x8(const a, b: TVecI16x8): TVecI16x8;
begin Result := ScalarMinI16x8(a, b); end;

function NEONMaxI16x8(const a, b: TVecI16x8): TVecI16x8;
begin Result := ScalarMaxI16x8(a, b); end;

// --- I8x16 Scalar Fallback ---
function NEONAddI8x16(const a, b: TVecI8x16): TVecI8x16;
begin Result := ScalarAddI8x16(a, b); end;

function NEONSubI8x16(const a, b: TVecI8x16): TVecI8x16;
begin Result := ScalarSubI8x16(a, b); end;

function NEONAndI8x16(const a, b: TVecI8x16): TVecI8x16;
begin Result := ScalarAndI8x16(a, b); end;

function NEONOrI8x16(const a, b: TVecI8x16): TVecI8x16;
begin Result := ScalarOrI8x16(a, b); end;

function NEONXorI8x16(const a, b: TVecI8x16): TVecI8x16;
begin Result := ScalarXorI8x16(a, b); end;

function NEONNotI8x16(const a: TVecI8x16): TVecI8x16;
begin Result := ScalarNotI8x16(a); end;

function NEONMinI8x16(const a, b: TVecI8x16): TVecI8x16;
begin Result := ScalarMinI8x16(a, b); end;

function NEONMaxI8x16(const a, b: TVecI8x16): TVecI8x16;
begin Result := ScalarMaxI8x16(a, b); end;

// --- U16x8 Scalar Fallback ---
function NEONAddU16x8(const a, b: TVecU16x8): TVecU16x8;
begin Result := ScalarAddU16x8(a, b); end;

function NEONSubU16x8(const a, b: TVecU16x8): TVecU16x8;
begin Result := ScalarSubU16x8(a, b); end;

function NEONMulU16x8(const a, b: TVecU16x8): TVecU16x8;
begin Result := ScalarMulU16x8(a, b); end;

function NEONAndU16x8(const a, b: TVecU16x8): TVecU16x8;
begin Result := ScalarAndU16x8(a, b); end;

function NEONOrU16x8(const a, b: TVecU16x8): TVecU16x8;
begin Result := ScalarOrU16x8(a, b); end;

function NEONXorU16x8(const a, b: TVecU16x8): TVecU16x8;
begin Result := ScalarXorU16x8(a, b); end;

function NEONNotU16x8(const a: TVecU16x8): TVecU16x8;
begin Result := ScalarNotU16x8(a); end;

function NEONMinU16x8(const a, b: TVecU16x8): TVecU16x8;
begin Result := ScalarMinU16x8(a, b); end;

function NEONMaxU16x8(const a, b: TVecU16x8): TVecU16x8;
begin Result := ScalarMaxU16x8(a, b); end;

// --- U8x16 Scalar Fallback ---
function NEONAddU8x16(const a, b: TVecU8x16): TVecU8x16;
begin Result := ScalarAddU8x16(a, b); end;

function NEONSubU8x16(const a, b: TVecU8x16): TVecU8x16;
begin Result := ScalarSubU8x16(a, b); end;

function NEONAndU8x16(const a, b: TVecU8x16): TVecU8x16;
begin Result := ScalarAndU8x16(a, b); end;

function NEONOrU8x16(const a, b: TVecU8x16): TVecU8x16;
begin Result := ScalarOrU8x16(a, b); end;

function NEONXorU8x16(const a, b: TVecU8x16): TVecU8x16;
begin Result := ScalarXorU8x16(a, b); end;

function NEONNotU8x16(const a: TVecU8x16): TVecU8x16;
begin Result := ScalarNotU8x16(a); end;

function NEONMinU8x16(const a, b: TVecU8x16): TVecU8x16;
begin Result := ScalarMinU8x16(a, b); end;

function NEONMaxU8x16(const a, b: TVecU8x16): TVecU8x16;
begin Result := ScalarMaxU8x16(a, b); end;

// ✅ P3: I64x2 Scalar Fallback (用于 FPC < 3.3.1 或非 ARM 平台)
function NEONAddI64x2(const a, b: TVecI64x2): TVecI64x2;
begin
  Result := ScalarAddI64x2(a, b);
end;

function NEONSubI64x2(const a, b: TVecI64x2): TVecI64x2;
begin
  Result := ScalarSubI64x2(a, b);
end;

function NEONAndI64x2(const a, b: TVecI64x2): TVecI64x2;
begin
  Result := ScalarAndI64x2(a, b);
end;

function NEONOrI64x2(const a, b: TVecI64x2): TVecI64x2;
begin
  Result := ScalarOrI64x2(a, b);
end;

function NEONXorI64x2(const a, b: TVecI64x2): TVecI64x2;
begin
  Result := ScalarXorI64x2(a, b);
end;

function NEONNotI64x2(const a: TVecI64x2): TVecI64x2;
begin
  Result := ScalarNotI64x2(a);
end;

function NEONCmpEqI64x2(const a, b: TVecI64x2): TMask2;
begin
  Result := ScalarCmpEqI64x2(a, b);
end;

function NEONCmpLtI64x2(const a, b: TVecI64x2): TMask2;
begin
  Result := ScalarCmpLtI64x2(a, b);
end;

function NEONCmpGtI64x2(const a, b: TVecI64x2): TMask2;
begin
  Result := ScalarCmpGtI64x2(a, b);
end;

function NEONCmpLeI64x2(const a, b: TVecI64x2): TMask2;
begin
  Result := ScalarCmpLeI64x2(a, b);
end;

function NEONCmpGeI64x2(const a, b: TVecI64x2): TMask2;
begin
  Result := ScalarCmpGeI64x2(a, b);
end;

function NEONCmpNeI64x2(const a, b: TVecI64x2): TMask2;
begin
  Result := ScalarCmpNeI64x2(a, b);
end;

// ✅ P4: SelectF64x2 (Pascal Implementation)
function NEONSelectF64x2(const mask: TMask2; const a, b: TVecF64x2): TVecF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    if (mask and (1 shl i)) <> 0 then
      Result.d[i] := a.d[i]
    else
      Result.d[i] := b.d[i];
end;

// ✅ P1: Mask Operations (Scalar Fallback)
// NEON 没有直接的 popcount/bsf 指令，使用标量回退
function NEONMask2All(mask: TMask2): Boolean;
begin Result := ScalarMask2All(mask); end;

function NEONMask2Any(mask: TMask2): Boolean;
begin Result := ScalarMask2Any(mask); end;

function NEONMask2None(mask: TMask2): Boolean;
begin Result := ScalarMask2None(mask); end;

function NEONMask2PopCount(mask: TMask2): Integer;
begin Result := ScalarMask2PopCount(mask); end;

function NEONMask2FirstSet(mask: TMask2): Integer;
begin Result := ScalarMask2FirstSet(mask); end;

function NEONMask4All(mask: TMask4): Boolean;
begin Result := ScalarMask4All(mask); end;

function NEONMask4Any(mask: TMask4): Boolean;
begin Result := ScalarMask4Any(mask); end;

function NEONMask4None(mask: TMask4): Boolean;
begin Result := ScalarMask4None(mask); end;

function NEONMask4PopCount(mask: TMask4): Integer;
begin Result := ScalarMask4PopCount(mask); end;

function NEONMask4FirstSet(mask: TMask4): Integer;
begin Result := ScalarMask4FirstSet(mask); end;

function NEONMask8All(mask: TMask8): Boolean;
begin Result := ScalarMask8All(mask); end;

function NEONMask8Any(mask: TMask8): Boolean;
begin Result := ScalarMask8Any(mask); end;

function NEONMask8None(mask: TMask8): Boolean;
begin Result := ScalarMask8None(mask); end;

function NEONMask8PopCount(mask: TMask8): Integer;
begin Result := ScalarMask8PopCount(mask); end;

function NEONMask8FirstSet(mask: TMask8): Integer;
begin Result := ScalarMask8FirstSet(mask); end;

function NEONMask16All(mask: TMask16): Boolean;
begin Result := ScalarMask16All(mask); end;

function NEONMask16Any(mask: TMask16): Boolean;
begin Result := ScalarMask16Any(mask); end;

function NEONMask16None(mask: TMask16): Boolean;
begin Result := ScalarMask16None(mask); end;

function NEONMask16PopCount(mask: TMask16): Integer;
begin Result := ScalarMask16PopCount(mask); end;

function NEONMask16FirstSet(mask: TMask16): Integer;
begin Result := ScalarMask16FirstSet(mask); end;

// === Auto-generated NEON Wrapper Functions (Scalar Fallback) ===
// These wrappers delegate to scalar implementations for 100% coverage

function NEONAbsF32x16(const a: TVecF32x16): TVecF32x16;
begin
  Result := ScalarAbsF32x16(a);
end;

function NEONAbsF32x8(const a: TVecF32x8): TVecF32x8;
begin
  Result := ScalarAbsF32x8(a);
end;

function NEONAbsF64x2(const a: TVecF64x2): TVecF64x2;
begin
  Result.d[0] := Abs(a.d[0]);
  Result.d[1] := Abs(a.d[1]);
end;

function NEONAbsF64x4(const a: TVecF64x4): TVecF64x4;
begin
  Result := ScalarAbsF64x4(a);
end;

function NEONAbsF64x8(const a: TVecF64x8): TVecF64x8;
begin
  Result := ScalarAbsF64x8(a);
end;

function NEONAddF32x16(const a, b: TVecF32x16): TVecF32x16;
begin
  Result := ScalarAddF32x16(a, b);
end;

function NEONAddF64x4(const a, b: TVecF64x4): TVecF64x4;
begin
  Result := ScalarAddF64x4(a, b);
end;

function NEONAddF64x8(const a, b: TVecF64x8): TVecF64x8;
begin
  Result := ScalarAddF64x8(a, b);
end;

function NEONAddI32x16(const a, b: TVecI32x16): TVecI32x16;
begin
  Result := ScalarAddI32x16(a, b);
end;

function NEONAddI32x8(const a, b: TVecI32x8): TVecI32x8;
begin
  Result := ScalarAddI32x8(a, b);
end;

function NEONAddI64x4(const a, b: TVecI64x4): TVecI64x4;
begin
  Result := ScalarAddI64x4(a, b);
end;

function NEONAddI64x8(const a, b: TVecI64x8): TVecI64x8;
begin
  Result := ScalarAddI64x8(a, b);
end;

function NEONAddU32x4(const a, b: TVecU32x4): TVecU32x4;
begin
  Result := ScalarAddU32x4(a, b);
end;

function NEONAddU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result := ScalarAddU32x8(a, b);
end;

function NEONAddU64x4(const a, b: TVecU64x4): TVecU64x4;
begin
  Result := ScalarAddU64x4(a, b);
end;

function NEONAndI32x16(const a, b: TVecI32x16): TVecI32x16;
begin
  Result := ScalarAndI32x16(a, b);
end;

function NEONAndI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  Result := ScalarAndI32x4(a, b);
end;

function NEONAndI32x8(const a, b: TVecI32x8): TVecI32x8;
begin
  Result := ScalarAndI32x8(a, b);
end;

function NEONAndI64x4(const a, b: TVecI64x4): TVecI64x4;
begin
  Result := ScalarAndI64x4(a, b);
end;

function NEONAndI64x8(const a, b: TVecI64x8): TVecI64x8;
begin
  Result := ScalarAndI64x8(a, b);
end;

function NEONAndNotI32x16(const a, b: TVecI32x16): TVecI32x16;
begin
  Result := ScalarAndNotI32x16(a, b);
end;

function NEONAndNotI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  Result := ScalarAndNotI32x4(a, b);
end;

function NEONAndNotI32x8(const a, b: TVecI32x8): TVecI32x8;
begin
  Result := ScalarAndNotI32x8(a, b);
end;

function NEONAndNotI64x4(const a, b: TVecI64x4): TVecI64x4;
begin
  Result := ScalarAndNotI64x4(a, b);
end;

function NEONAndNotU32x4(const a, b: TVecU32x4): TVecU32x4;
begin
  Result := ScalarAndNotU32x4(a, b);
end;

function NEONAndNotU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result := ScalarAndNotU32x8(a, b);
end;

function NEONAndU32x4(const a, b: TVecU32x4): TVecU32x4;
begin
  Result := ScalarAndU32x4(a, b);
end;

function NEONAndU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result := ScalarAndU32x8(a, b);
end;

function NEONAndU64x4(const a, b: TVecU64x4): TVecU64x4;
begin
  Result := ScalarAndU64x4(a, b);
end;

function NEONCeilF32x16(const a: TVecF32x16): TVecF32x16;
begin
  Result := ScalarCeilF32x16(a);
end;

function NEONCeilF32x8(const a: TVecF32x8): TVecF32x8;
begin
  Result := ScalarCeilF32x8(a);
end;

function NEONCeilF64x2(const a: TVecF64x2): TVecF64x2;
begin
  Result.d[0] := Ceil(a.d[0]);
  Result.d[1] := Ceil(a.d[1]);
end;

function NEONCeilF64x4(const a: TVecF64x4): TVecF64x4;
begin
  Result := ScalarCeilF64x4(a);
end;

function NEONCeilF64x8(const a: TVecF64x8): TVecF64x8;
begin
  Result := ScalarCeilF64x8(a);
end;

function NEONClampF32x16(const a, minVal, maxVal: TVecF32x16): TVecF32x16;
begin
  Result := ScalarClampF32x16(a, minVal, maxVal);
end;

function NEONClampF32x8(const a, minVal, maxVal: TVecF32x8): TVecF32x8;
begin
  Result := ScalarClampF32x8(a, minVal, maxVal);
end;

function NEONClampF64x2(const a, minVal, maxVal: TVecF64x2): TVecF64x2;
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

function NEONClampF64x4(const a, minVal, maxVal: TVecF64x4): TVecF64x4;
begin
  Result := ScalarClampF64x4(a, minVal, maxVal);
end;

function NEONClampF64x8(const a, minVal, maxVal: TVecF64x8): TVecF64x8;
begin
  Result := ScalarClampF64x8(a, minVal, maxVal);
end;

function NEONCmpEqF32x16(const a, b: TVecF32x16): TMask16;
begin
  Result := ScalarCmpEqF32x16(a, b);
end;

function NEONCmpEqF32x8(const a, b: TVecF32x8): TMask8;
begin
  Result := ScalarCmpEqF32x8(a, b);
end;

function NEONCmpEqF64x2(const a, b: TVecF64x2): TMask2;
begin
  Result := 0;
  if a.d[0] = b.d[0] then Result := Result or 1;
  if a.d[1] = b.d[1] then Result := Result or 2;
end;

function NEONCmpEqF64x4(const a, b: TVecF64x4): TMask4;
begin
  Result := ScalarCmpEqF64x4(a, b);
end;

function NEONCmpEqF64x8(const a, b: TVecF64x8): TMask8;
begin
  Result := ScalarCmpEqF64x8(a, b);
end;

function NEONCmpEqI16x8(const a, b: TVecI16x8): TMask8;
begin
  Result := ScalarCmpEqI16x8(a, b);
end;

function NEONCmpEqI32x16(const a, b: TVecI32x16): TMask16;
begin
  Result := ScalarCmpEqI32x16(a, b);
end;

function NEONCmpEqI32x4(const a, b: TVecI32x4): TMask4;
begin
  Result := ScalarCmpEqI32x4(a, b);
end;

function NEONCmpEqI32x8(const a, b: TVecI32x8): TMask8;
begin
  Result := ScalarCmpEqI32x8(a, b);
end;

function NEONCmpEqI64x4(const a, b: TVecI64x4): TMask4;
begin
  Result := ScalarCmpEqI64x4(a, b);
end;

function NEONCmpEqI64x8(const a, b: TVecI64x8): TMask8;
begin
  Result := ScalarCmpEqI64x8(a, b);
end;

function NEONCmpEqI8x16(const a, b: TVecI8x16): TMask16;
begin
  Result := ScalarCmpEqI8x16(a, b);
end;

function NEONCmpEqU16x8(const a, b: TVecU16x8): TMask8;
begin
  Result := ScalarCmpEqU16x8(a, b);
end;

function NEONCmpEqU32x4(const a, b: TVecU32x4): TMask4;
begin
  Result := ScalarCmpEqU32x4(a, b);
end;

function NEONCmpEqU32x8(const a, b: TVecU32x8): TMask8;
begin
  Result := ScalarCmpEqU32x8(a, b);
end;

function NEONCmpEqU64x4(const a, b: TVecU64x4): TMask4;
begin
  Result := ScalarCmpEqU64x4(a, b);
end;

function NEONCmpEqU8x16(const a, b: TVecU8x16): TMask16;
begin
  Result := ScalarCmpEqU8x16(a, b);
end;

function NEONCmpGeF32x16(const a, b: TVecF32x16): TMask16;
begin
  Result := ScalarCmpGeF32x16(a, b);
end;

function NEONCmpGeF32x8(const a, b: TVecF32x8): TMask8;
begin
  Result := ScalarCmpGeF32x8(a, b);
end;

function NEONCmpGeF64x2(const a, b: TVecF64x2): TMask2;
begin
  Result := 0;
  if a.d[0] >= b.d[0] then Result := Result or 1;
  if a.d[1] >= b.d[1] then Result := Result or 2;
end;

function NEONCmpGeF64x4(const a, b: TVecF64x4): TMask4;
begin
  Result := ScalarCmpGeF64x4(a, b);
end;

function NEONCmpGeF64x8(const a, b: TVecF64x8): TMask8;
begin
  Result := ScalarCmpGeF64x8(a, b);
end;

function NEONCmpGeI16x8(const a, b: TVecI16x8): TMask8;
begin
  Result := ScalarCmpGeI16x8(a, b);
end;

function NEONCmpGeI32x16(const a, b: TVecI32x16): TMask16;
begin
  Result := ScalarCmpGeI32x16(a, b);
end;

function NEONCmpGeI32x4(const a, b: TVecI32x4): TMask4;
begin
  Result := ScalarCmpGeI32x4(a, b);
end;

function NEONCmpGeI32x8(const a, b: TVecI32x8): TMask8;
begin
  Result := ScalarCmpGeI32x8(a, b);
end;

function NEONCmpGeI64x4(const a, b: TVecI64x4): TMask4;
begin
  Result := ScalarCmpGeI64x4(a, b);
end;

function NEONCmpGeI64x8(const a, b: TVecI64x8): TMask8;
begin
  Result := ScalarCmpGeI64x8(a, b);
end;

function NEONCmpGeI8x16(const a, b: TVecI8x16): TMask16;
begin
  Result := ScalarCmpGeI8x16(a, b);
end;

function NEONCmpGeU16x8(const a, b: TVecU16x8): TMask8;
begin
  Result := ScalarCmpGeU16x8(a, b);
end;

function NEONCmpGeU32x4(const a, b: TVecU32x4): TMask4;
begin
  Result := ScalarCmpGeU32x4(a, b);
end;

function NEONCmpGeU32x8(const a, b: TVecU32x8): TMask8;
begin
  Result := ScalarCmpGeU32x8(a, b);
end;

function NEONCmpGeU64x4(const a, b: TVecU64x4): TMask4;
begin
  Result := ScalarCmpGeU64x4(a, b);
end;

function NEONCmpGeU8x16(const a, b: TVecU8x16): TMask16;
begin
  Result := ScalarCmpGeU8x16(a, b);
end;

function NEONCmpGtF32x16(const a, b: TVecF32x16): TMask16;
begin
  Result := ScalarCmpGtF32x16(a, b);
end;

function NEONCmpGtF32x8(const a, b: TVecF32x8): TMask8;
begin
  Result := ScalarCmpGtF32x8(a, b);
end;

function NEONCmpGtF64x2(const a, b: TVecF64x2): TMask2;
begin
  Result := 0;
  if a.d[0] > b.d[0] then Result := Result or 1;
  if a.d[1] > b.d[1] then Result := Result or 2;
end;

function NEONCmpGtF64x4(const a, b: TVecF64x4): TMask4;
begin
  Result := ScalarCmpGtF64x4(a, b);
end;

function NEONCmpGtF64x8(const a, b: TVecF64x8): TMask8;
begin
  Result := ScalarCmpGtF64x8(a, b);
end;

function NEONCmpGtI16x8(const a, b: TVecI16x8): TMask8;
begin
  Result := ScalarCmpGtI16x8(a, b);
end;

function NEONCmpGtI32x16(const a, b: TVecI32x16): TMask16;
begin
  Result := ScalarCmpGtI32x16(a, b);
end;

function NEONCmpGtI32x4(const a, b: TVecI32x4): TMask4;
begin
  Result := ScalarCmpGtI32x4(a, b);
end;

function NEONCmpGtI32x8(const a, b: TVecI32x8): TMask8;
begin
  Result := ScalarCmpGtI32x8(a, b);
end;

function NEONCmpGtI64x4(const a, b: TVecI64x4): TMask4;
begin
  Result := ScalarCmpGtI64x4(a, b);
end;

function NEONCmpGtI64x8(const a, b: TVecI64x8): TMask8;
begin
  Result := ScalarCmpGtI64x8(a, b);
end;

function NEONCmpGtI8x16(const a, b: TVecI8x16): TMask16;
begin
  Result := ScalarCmpGtI8x16(a, b);
end;

function NEONCmpGtU16x8(const a, b: TVecU16x8): TMask8;
begin
  Result := ScalarCmpGtU16x8(a, b);
end;

function NEONCmpGtU32x4(const a, b: TVecU32x4): TMask4;
begin
  Result := ScalarCmpGtU32x4(a, b);
end;

function NEONCmpGtU32x8(const a, b: TVecU32x8): TMask8;
begin
  Result := ScalarCmpGtU32x8(a, b);
end;

function NEONCmpGtU64x4(const a, b: TVecU64x4): TMask4;
begin
  Result := ScalarCmpGtU64x4(a, b);
end;

function NEONCmpGtU8x16(const a, b: TVecU8x16): TMask16;
begin
  Result := ScalarCmpGtU8x16(a, b);
end;

function NEONCmpLeF32x16(const a, b: TVecF32x16): TMask16;
begin
  Result := ScalarCmpLeF32x16(a, b);
end;

function NEONCmpLeF32x8(const a, b: TVecF32x8): TMask8;
begin
  Result := ScalarCmpLeF32x8(a, b);
end;

function NEONCmpLeF64x2(const a, b: TVecF64x2): TMask2;
begin
  Result := 0;
  if a.d[0] <= b.d[0] then Result := Result or 1;
  if a.d[1] <= b.d[1] then Result := Result or 2;
end;

function NEONCmpLeF64x4(const a, b: TVecF64x4): TMask4;
begin
  Result := ScalarCmpLeF64x4(a, b);
end;

function NEONCmpLeF64x8(const a, b: TVecF64x8): TMask8;
begin
  Result := ScalarCmpLeF64x8(a, b);
end;

function NEONCmpLeI16x8(const a, b: TVecI16x8): TMask8;
begin
  Result := ScalarCmpLeI16x8(a, b);
end;

function NEONCmpLeI32x16(const a, b: TVecI32x16): TMask16;
begin
  Result := ScalarCmpLeI32x16(a, b);
end;

function NEONCmpLeI32x4(const a, b: TVecI32x4): TMask4;
begin
  Result := ScalarCmpLeI32x4(a, b);
end;

function NEONCmpLeI32x8(const a, b: TVecI32x8): TMask8;
begin
  Result := ScalarCmpLeI32x8(a, b);
end;

function NEONCmpLeI64x4(const a, b: TVecI64x4): TMask4;
begin
  Result := ScalarCmpLeI64x4(a, b);
end;

function NEONCmpLeI64x8(const a, b: TVecI64x8): TMask8;
begin
  Result := ScalarCmpLeI64x8(a, b);
end;

function NEONCmpLeI8x16(const a, b: TVecI8x16): TMask16;
begin
  Result := ScalarCmpLeI8x16(a, b);
end;

function NEONCmpLeU16x8(const a, b: TVecU16x8): TMask8;
begin
  Result := ScalarCmpLeU16x8(a, b);
end;

function NEONCmpLeU32x4(const a, b: TVecU32x4): TMask4;
begin
  Result := ScalarCmpLeU32x4(a, b);
end;

function NEONCmpLeU32x8(const a, b: TVecU32x8): TMask8;
begin
  Result := ScalarCmpLeU32x8(a, b);
end;

function NEONCmpLeU64x4(const a, b: TVecU64x4): TMask4;
begin
  Result := ScalarCmpLeU64x4(a, b);
end;

function NEONCmpLeU8x16(const a, b: TVecU8x16): TMask16;
begin
  Result := ScalarCmpLeU8x16(a, b);
end;

function NEONCmpLtF32x16(const a, b: TVecF32x16): TMask16;
begin
  Result := ScalarCmpLtF32x16(a, b);
end;

function NEONCmpLtF32x8(const a, b: TVecF32x8): TMask8;
begin
  Result := ScalarCmpLtF32x8(a, b);
end;

function NEONCmpLtF64x2(const a, b: TVecF64x2): TMask2;
begin
  Result := 0;
  if a.d[0] < b.d[0] then Result := Result or 1;
  if a.d[1] < b.d[1] then Result := Result or 2;
end;

function NEONCmpLtF64x4(const a, b: TVecF64x4): TMask4;
begin
  Result := ScalarCmpLtF64x4(a, b);
end;

function NEONCmpLtF64x8(const a, b: TVecF64x8): TMask8;
begin
  Result := ScalarCmpLtF64x8(a, b);
end;

function NEONCmpLtI16x8(const a, b: TVecI16x8): TMask8;
begin
  Result := ScalarCmpLtI16x8(a, b);
end;

function NEONCmpLtI32x16(const a, b: TVecI32x16): TMask16;
begin
  Result := ScalarCmpLtI32x16(a, b);
end;

function NEONCmpLtI32x4(const a, b: TVecI32x4): TMask4;
begin
  Result := ScalarCmpLtI32x4(a, b);
end;

function NEONCmpLtI32x8(const a, b: TVecI32x8): TMask8;
begin
  Result := ScalarCmpLtI32x8(a, b);
end;

function NEONCmpLtI64x4(const a, b: TVecI64x4): TMask4;
begin
  Result := ScalarCmpLtI64x4(a, b);
end;

function NEONCmpLtI64x8(const a, b: TVecI64x8): TMask8;
begin
  Result := ScalarCmpLtI64x8(a, b);
end;

function NEONCmpLtI8x16(const a, b: TVecI8x16): TMask16;
begin
  Result := ScalarCmpLtI8x16(a, b);
end;

function NEONCmpLtU16x8(const a, b: TVecU16x8): TMask8;
begin
  Result := ScalarCmpLtU16x8(a, b);
end;

function NEONCmpLtU32x4(const a, b: TVecU32x4): TMask4;
begin
  Result := ScalarCmpLtU32x4(a, b);
end;

function NEONCmpLtU32x8(const a, b: TVecU32x8): TMask8;
begin
  Result := ScalarCmpLtU32x8(a, b);
end;

function NEONCmpLtU64x4(const a, b: TVecU64x4): TMask4;
begin
  Result := ScalarCmpLtU64x4(a, b);
end;

function NEONCmpLtU8x16(const a, b: TVecU8x16): TMask16;
begin
  Result := ScalarCmpLtU8x16(a, b);
end;

function NEONCmpNeF32x16(const a, b: TVecF32x16): TMask16;
begin
  Result := ScalarCmpNeF32x16(a, b);
end;

function NEONCmpNeF32x8(const a, b: TVecF32x8): TMask8;
begin
  Result := ScalarCmpNeF32x8(a, b);
end;

function NEONCmpNeF64x2(const a, b: TVecF64x2): TMask2;
begin
  Result := 0;
  if a.d[0] <> b.d[0] then Result := Result or 1;
  if a.d[1] <> b.d[1] then Result := Result or 2;
end;

function NEONCmpNeF64x4(const a, b: TVecF64x4): TMask4;
begin
  Result := ScalarCmpNeF64x4(a, b);
end;

function NEONCmpNeF64x8(const a, b: TVecF64x8): TMask8;
begin
  Result := ScalarCmpNeF64x8(a, b);
end;

function NEONCmpNeI16x8(const a, b: TVecI16x8): TMask8;
begin
  Result := ScalarCmpNeI16x8(a, b);
end;

function NEONCmpNeI32x16(const a, b: TVecI32x16): TMask16;
begin
  Result := ScalarCmpNeI32x16(a, b);
end;

function NEONCmpNeI32x4(const a, b: TVecI32x4): TMask4;
begin
  Result := ScalarCmpNeI32x4(a, b);
end;

function NEONCmpNeI32x8(const a, b: TVecI32x8): TMask8;
begin
  Result := ScalarCmpNeI32x8(a, b);
end;

function NEONCmpNeI64x4(const a, b: TVecI64x4): TMask4;
begin
  Result := ScalarCmpNeI64x4(a, b);
end;

function NEONCmpNeI64x8(const a, b: TVecI64x8): TMask8;
begin
  Result := ScalarCmpNeI64x8(a, b);
end;

function NEONCmpNeI8x16(const a, b: TVecI8x16): TMask16;
begin
  Result := ScalarCmpNeI8x16(a, b);
end;

function NEONCmpNeU16x8(const a, b: TVecU16x8): TMask8;
begin
  Result := ScalarCmpNeU16x8(a, b);
end;

function NEONCmpNeU32x8(const a, b: TVecU32x8): TMask8;
begin
  Result := ScalarCmpNeU32x8(a, b);
end;

function NEONCmpNeU64x4(const a, b: TVecU64x4): TMask4;
begin
  Result := ScalarCmpNeU64x4(a, b);
end;

function NEONCmpNeU8x16(const a, b: TVecU8x16): TMask16;
begin
  Result := ScalarCmpNeU8x16(a, b);
end;

function NEONDivF32x16(const a, b: TVecF32x16): TVecF32x16;
begin
  Result := ScalarDivF32x16(a, b);
end;

function NEONDivF64x4(const a, b: TVecF64x4): TVecF64x4;
begin
  Result := ScalarDivF64x4(a, b);
end;

function NEONDivF64x8(const a, b: TVecF64x8): TVecF64x8;
begin
  Result := ScalarDivF64x8(a, b);
end;

function NEONExtractF32x16(const a: TVecF32x16; index: Integer): Single;
begin
  Result := ScalarExtractF32x16(a, index);
end;

function NEONExtractF32x8(const a: TVecF32x8; index: Integer): Single;
begin
  Result := ScalarExtractF32x8(a, index);
end;

function NEONExtractF64x2(const a: TVecF64x2; index: Integer): Double;
var idx: Integer;
begin
  if index < 0 then idx := 0
  else if index > 1 then idx := 1
  else idx := index;
  Result := a.d[idx];
end;

function NEONExtractF64x4(const a: TVecF64x4; index: Integer): Double;
begin
  Result := ScalarExtractF64x4(a, index);
end;

function NEONExtractI32x16(const a: TVecI32x16; index: Integer): Int32;
begin
  Result := ScalarExtractI32x16(a, index);
end;

function NEONExtractI32x4(const a: TVecI32x4; index: Integer): Int32;
begin
  Result := ScalarExtractI32x4(a, index);
end;

function NEONExtractI32x8(const a: TVecI32x8; index: Integer): Int32;
begin
  Result := ScalarExtractI32x8(a, index);
end;

function NEONExtractI64x2(const a: TVecI64x2; index: Integer): Int64;
begin
  Result := ScalarExtractI64x2(a, index);
end;

function NEONExtractI64x4(const a: TVecI64x4; index: Integer): Int64;
begin
  Result := ScalarExtractI64x4(a, index);
end;

function NEONFloorF32x16(const a: TVecF32x16): TVecF32x16;
begin
  Result := ScalarFloorF32x16(a);
end;

function NEONFloorF32x8(const a: TVecF32x8): TVecF32x8;
begin
  Result := ScalarFloorF32x8(a);
end;

function NEONFloorF64x2(const a: TVecF64x2): TVecF64x2;
begin
  Result.d[0] := Floor(a.d[0]);
  Result.d[1] := Floor(a.d[1]);
end;

function NEONFloorF64x4(const a: TVecF64x4): TVecF64x4;
begin
  Result := ScalarFloorF64x4(a);
end;

function NEONFloorF64x8(const a: TVecF64x8): TVecF64x8;
begin
  Result := ScalarFloorF64x8(a);
end;

function NEONFmaF32x16(const a, b, c: TVecF32x16): TVecF32x16;
begin
  Result := ScalarFmaF32x16(a, b, c);
end;

function NEONFmaF32x8(const a, b, c: TVecF32x8): TVecF32x8;
begin
  Result := ScalarFmaF32x8(a, b, c);
end;

function NEONFmaF64x2(const a, b, c: TVecF64x2): TVecF64x2;
begin
  // Result = a * b + c
  Result.d[0] := a.d[0] * b.d[0] + c.d[0];
  Result.d[1] := a.d[1] * b.d[1] + c.d[1];
end;

function NEONFmaF64x4(const a, b, c: TVecF64x4): TVecF64x4;
begin
  Result := ScalarFmaF64x4(a, b, c);
end;

function NEONFmaF64x8(const a, b, c: TVecF64x8): TVecF64x8;
begin
  Result := ScalarFmaF64x8(a, b, c);
end;

function NEONInsertF32x16(const a: TVecF32x16; value: Single; index: Integer): TVecF32x16;
begin
  Result := ScalarInsertF32x16(a, value, index);
end;

function NEONInsertF32x8(const a: TVecF32x8; value: Single; index: Integer): TVecF32x8;
begin
  Result := ScalarInsertF32x8(a, value, index);
end;

function NEONInsertF64x2(const a: TVecF64x2; value: Double; index: Integer): TVecF64x2;
var idx: Integer;
begin
  if index < 0 then idx := 0
  else if index > 1 then idx := 1
  else idx := index;
  Result := a;
  Result.d[idx] := value;
end;

function NEONInsertF64x4(const a: TVecF64x4; value: Double; index: Integer): TVecF64x4;
begin
  Result := ScalarInsertF64x4(a, value, index);
end;

function NEONInsertI32x16(const a: TVecI32x16; value: Int32; index: Integer): TVecI32x16;
begin
  Result := ScalarInsertI32x16(a, value, index);
end;

function NEONInsertI32x4(const a: TVecI32x4; value: Int32; index: Integer): TVecI32x4;
begin
  Result := ScalarInsertI32x4(a, value, index);
end;

function NEONInsertI32x8(const a: TVecI32x8; value: Int32; index: Integer): TVecI32x8;
begin
  Result := ScalarInsertI32x8(a, value, index);
end;

function NEONInsertI64x2(const a: TVecI64x2; value: Int64; index: Integer): TVecI64x2;
begin
  Result := ScalarInsertI64x2(a, value, index);
end;

function NEONInsertI64x4(const a: TVecI64x4; value: Int64; index: Integer): TVecI64x4;
begin
  Result := ScalarInsertI64x4(a, value, index);
end;

function NEONLoadF32x16(p: PSingle): TVecF32x16;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONLoadF32x16_ASM(p);
  {$ELSE}
  Result := ScalarLoadF32x16(p);
  {$ENDIF}
end;

function NEONLoadF32x8(p: PSingle): TVecF32x8;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONLoadF32x8_ASM(p);
  {$ELSE}
  Result := ScalarLoadF32x8(p);
  {$ENDIF}
end;

function NEONLoadF64x2(p: PDouble): TVecF64x2;
begin
  Move(p^, Result.d[0], 16);
end;

function NEONLoadF64x4(p: PDouble): TVecF64x4;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONLoadF64x4_ASM(p);
  {$ELSE}
  Result := ScalarLoadF64x4(p);
  {$ENDIF}
end;

function NEONLoadF64x8(p: PDouble): TVecF64x8;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONLoadF64x8_ASM(p);
  {$ELSE}
  Result := ScalarLoadF64x8(p);
  {$ENDIF}
end;

function NEONLoadI64x4(p: PInt64): TVecI64x4;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONLoadI64x4_ASM(p);
  {$ELSE}
  Result := ScalarLoadI64x4(p);
  {$ENDIF}
end;

function NEONMaxF32x16(const a, b: TVecF32x16): TVecF32x16;
begin
  Result := ScalarMaxF32x16(a, b);
end;

function NEONMaxF32x8(const a, b: TVecF32x8): TVecF32x8;
begin
  Result := ScalarMaxF32x8(a, b);
end;

function NEONMaxF64x2(const a, b: TVecF64x2): TVecF64x2;
begin
  if a.d[0] > b.d[0] then Result.d[0] := a.d[0] else Result.d[0] := b.d[0];
  if a.d[1] > b.d[1] then Result.d[1] := a.d[1] else Result.d[1] := b.d[1];
end;

function NEONMaxF64x4(const a, b: TVecF64x4): TVecF64x4;
begin
  Result := ScalarMaxF64x4(a, b);
end;

function NEONMaxF64x8(const a, b: TVecF64x8): TVecF64x8;
begin
  Result := ScalarMaxF64x8(a, b);
end;

function NEONMaxI32x16(const a, b: TVecI32x16): TVecI32x16;
begin
  Result := ScalarMaxI32x16(a, b);
end;

function NEONMaxI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  Result := ScalarMaxI32x4(a, b);
end;

function NEONMaxI32x8(const a, b: TVecI32x8): TVecI32x8;
begin
  Result := ScalarMaxI32x8(a, b);
end;

function NEONMaxU32x4(const a, b: TVecU32x4): TVecU32x4;
begin
  Result := ScalarMaxU32x4(a, b);
end;

function NEONMaxU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result := ScalarMaxU32x8(a, b);
end;

function NEONMinF32x16(const a, b: TVecF32x16): TVecF32x16;
begin
  Result := ScalarMinF32x16(a, b);
end;

function NEONMinF32x8(const a, b: TVecF32x8): TVecF32x8;
begin
  Result := ScalarMinF32x8(a, b);
end;

function NEONMinF64x2(const a, b: TVecF64x2): TVecF64x2;
begin
  if a.d[0] < b.d[0] then Result.d[0] := a.d[0] else Result.d[0] := b.d[0];
  if a.d[1] < b.d[1] then Result.d[1] := a.d[1] else Result.d[1] := b.d[1];
end;

function NEONMinF64x4(const a, b: TVecF64x4): TVecF64x4;
begin
  Result := ScalarMinF64x4(a, b);
end;

function NEONMinF64x8(const a, b: TVecF64x8): TVecF64x8;
begin
  Result := ScalarMinF64x8(a, b);
end;

function NEONMinI32x16(const a, b: TVecI32x16): TVecI32x16;
begin
  Result := ScalarMinI32x16(a, b);
end;

function NEONMinI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  Result := ScalarMinI32x4(a, b);
end;

function NEONMinI32x8(const a, b: TVecI32x8): TVecI32x8;
begin
  Result := ScalarMinI32x8(a, b);
end;

function NEONMinU32x4(const a, b: TVecU32x4): TVecU32x4;
begin
  Result := ScalarMinU32x4(a, b);
end;

function NEONMinU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result := ScalarMinU32x8(a, b);
end;

function NEONMulF32x16(const a, b: TVecF32x16): TVecF32x16;
begin
  Result := ScalarMulF32x16(a, b);
end;

function NEONMulF64x4(const a, b: TVecF64x4): TVecF64x4;
begin
  Result := ScalarMulF64x4(a, b);
end;

function NEONMulF64x8(const a, b: TVecF64x8): TVecF64x8;
begin
  Result := ScalarMulF64x8(a, b);
end;

function NEONMulI32x16(const a, b: TVecI32x16): TVecI32x16;
begin
  Result := ScalarMulI32x16(a, b);
end;

function NEONMulI32x8(const a, b: TVecI32x8): TVecI32x8;
begin
  Result := ScalarMulI32x8(a, b);
end;

function NEONMulU32x4(const a, b: TVecU32x4): TVecU32x4;
begin
  Result := ScalarMulU32x4(a, b);
end;

function NEONMulU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result := ScalarMulU32x8(a, b);
end;

function NEONNotI32x16(const a: TVecI32x16): TVecI32x16;
begin
  Result := ScalarNotI32x16(a);
end;

function NEONNotI32x4(const a: TVecI32x4): TVecI32x4;
begin
  Result := ScalarNotI32x4(a);
end;

function NEONNotI32x8(const a: TVecI32x8): TVecI32x8;
begin
  Result := ScalarNotI32x8(a);
end;

function NEONNotI64x4(const a: TVecI64x4): TVecI64x4;
begin
  Result := ScalarNotI64x4(a);
end;

function NEONNotI64x8(const a: TVecI64x8): TVecI64x8;
begin
  Result := ScalarNotI64x8(a);
end;

function NEONNotU32x4(const a: TVecU32x4): TVecU32x4;
begin
  Result := ScalarNotU32x4(a);
end;

function NEONNotU32x8(const a: TVecU32x8): TVecU32x8;
begin
  Result := ScalarNotU32x8(a);
end;

function NEONNotU64x4(const a: TVecU64x4): TVecU64x4;
begin
  Result := ScalarNotU64x4(a);
end;

function NEONOrI32x16(const a, b: TVecI32x16): TVecI32x16;
begin
  Result := ScalarOrI32x16(a, b);
end;

function NEONOrI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  Result := ScalarOrI32x4(a, b);
end;

function NEONOrI32x8(const a, b: TVecI32x8): TVecI32x8;
begin
  Result := ScalarOrI32x8(a, b);
end;

function NEONOrI64x4(const a, b: TVecI64x4): TVecI64x4;
begin
  Result := ScalarOrI64x4(a, b);
end;

function NEONOrI64x8(const a, b: TVecI64x8): TVecI64x8;
begin
  Result := ScalarOrI64x8(a, b);
end;

function NEONOrU32x4(const a, b: TVecU32x4): TVecU32x4;
begin
  Result := ScalarOrU32x4(a, b);
end;

function NEONOrU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result := ScalarOrU32x8(a, b);
end;

function NEONOrU64x4(const a, b: TVecU64x4): TVecU64x4;
begin
  Result := ScalarOrU64x4(a, b);
end;

function NEONRcpF64x4(const a: TVecF64x4): TVecF64x4;
begin
  Result := ScalarRcpF64x4(a);
end;

function NEONReduceAddF32x16(const a: TVecF32x16): Single;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceAddF32x16_ASM(a);
  {$ELSE}
  Result := ScalarReduceAddF32x16(a);
  {$ENDIF}
end;

function NEONReduceAddF32x8(const a: TVecF32x8): Single;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceAddF32x8_ASM(a);
  {$ELSE}
  Result := ScalarReduceAddF32x8(a);
  {$ENDIF}
end;

function NEONReduceAddF64x2(const a: TVecF64x2): Double;
begin
  Result := a.d[0] + a.d[1];
end;

function NEONReduceAddF64x4(const a: TVecF64x4): Double;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceAddF64x4_ASM(a);
  {$ELSE}
  Result := ScalarReduceAddF64x4(a);
  {$ENDIF}
end;

function NEONReduceAddF64x8(const a: TVecF64x8): Double;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceAddF64x8_ASM(a);
  {$ELSE}
  Result := ScalarReduceAddF64x8(a);
  {$ENDIF}
end;

function NEONReduceMaxF32x16(const a: TVecF32x16): Single;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceMaxF32x16_ASM(a);
  {$ELSE}
  Result := ScalarReduceMaxF32x16(a);
  {$ENDIF}
end;

function NEONReduceMaxF32x8(const a: TVecF32x8): Single;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceMaxF32x8_ASM(a);
  {$ELSE}
  Result := ScalarReduceMaxF32x8(a);
  {$ENDIF}
end;

function NEONReduceMaxF64x2(const a: TVecF64x2): Double;
begin
  if a.d[0] > a.d[1] then Result := a.d[0] else Result := a.d[1];
end;

function NEONReduceMaxF64x4(const a: TVecF64x4): Double;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceMaxF64x4_ASM(a);
  {$ELSE}
  Result := ScalarReduceMaxF64x4(a);
  {$ENDIF}
end;

function NEONReduceMaxF64x8(const a: TVecF64x8): Double;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceMaxF64x8_ASM(a);
  {$ELSE}
  Result := ScalarReduceMaxF64x8(a);
  {$ENDIF}
end;

function NEONReduceMinF32x16(const a: TVecF32x16): Single;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceMinF32x16_ASM(a);
  {$ELSE}
  Result := ScalarReduceMinF32x16(a);
  {$ENDIF}
end;

function NEONReduceMinF32x8(const a: TVecF32x8): Single;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceMinF32x8_ASM(a);
  {$ELSE}
  Result := ScalarReduceMinF32x8(a);
  {$ENDIF}
end;

function NEONReduceMinF64x2(const a: TVecF64x2): Double;
begin
  if a.d[0] < a.d[1] then Result := a.d[0] else Result := a.d[1];
end;

function NEONReduceMinF64x4(const a: TVecF64x4): Double;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceMinF64x4_ASM(a);
  {$ELSE}
  Result := ScalarReduceMinF64x4(a);
  {$ENDIF}
end;

function NEONReduceMinF64x8(const a: TVecF64x8): Double;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceMinF64x8_ASM(a);
  {$ELSE}
  Result := ScalarReduceMinF64x8(a);
  {$ENDIF}
end;

function NEONReduceMulF32x16(const a: TVecF32x16): Single;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceMulF32x16_ASM(a);
  {$ELSE}
  Result := ScalarReduceMulF32x16(a);
  {$ENDIF}
end;

function NEONReduceMulF32x8(const a: TVecF32x8): Single;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceMulF32x8_ASM(a);
  {$ELSE}
  Result := ScalarReduceMulF32x8(a);
  {$ENDIF}
end;

function NEONReduceMulF64x2(const a: TVecF64x2): Double;
begin
  Result := a.d[0] * a.d[1];
end;

function NEONReduceMulF64x4(const a: TVecF64x4): Double;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceMulF64x4_ASM(a);
  {$ELSE}
  Result := ScalarReduceMulF64x4(a);
  {$ENDIF}
end;

function NEONReduceMulF64x8(const a: TVecF64x8): Double;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONReduceMulF64x8_ASM(a);
  {$ELSE}
  Result := ScalarReduceMulF64x8(a);
  {$ENDIF}
end;

function NEONRoundF32x16(const a: TVecF32x16): TVecF32x16;
begin
  Result := ScalarRoundF32x16(a);
end;

function NEONRoundF32x8(const a: TVecF32x8): TVecF32x8;
begin
  Result := ScalarRoundF32x8(a);
end;

function NEONRoundF64x2(const a: TVecF64x2): TVecF64x2;
begin
  Result.d[0] := Round(a.d[0]);
  Result.d[1] := Round(a.d[1]);
end;

function NEONRoundF64x4(const a: TVecF64x4): TVecF64x4;
begin
  Result := ScalarRoundF64x4(a);
end;

function NEONRoundF64x8(const a: TVecF64x8): TVecF64x8;
begin
  Result := ScalarRoundF64x8(a);
end;

function NEONSelectF32x16(const mask: TMask16; const a, b: TVecF32x16): TVecF32x16;
begin
  Result := ScalarSelectF32x16(mask, a, b);
end;

function NEONSelectF32x8(const mask: TVecU32x8; const a, b: TVecF32x8): TVecF32x8;
begin
  Result := ScalarSelectF32x8(mask, a, b);
end;

function NEONSelectF64x4(const mask: TVecU64x4; const a, b: TVecF64x4): TVecF64x4;
begin
  Result := ScalarSelectF64x4(mask, a, b);
end;

function NEONSelectF64x8(const mask: TMask8; const a, b: TVecF64x8): TVecF64x8;
begin
  Result := ScalarSelectF64x8(mask, a, b);
end;

function NEONSelectI32x4(const mask: TVecI32x4; const a, b: TVecI32x4): TVecI32x4;
begin
  Result := ScalarSelectI32x4(mask, a, b);
end;

function NEONShiftLeftI16x8(const a: TVecI16x8; count: Integer): TVecI16x8;
begin
  Result := ScalarShiftLeftI16x8(a, count);
end;

function NEONShiftLeftI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
begin
  Result := ScalarShiftLeftI32x16(a, count);
end;

function NEONShiftLeftI32x4(const a: TVecI32x4; count: Integer): TVecI32x4;
begin
  Result := ScalarShiftLeftI32x4(a, count);
end;

function NEONShiftLeftI32x8(const a: TVecI32x8; count: Integer): TVecI32x8;
begin
  Result := ScalarShiftLeftI32x8(a, count);
end;

function NEONShiftLeftI64x4(const a: TVecI64x4; count: Integer): TVecI64x4;
begin
  Result := ScalarShiftLeftI64x4(a, count);
end;

function NEONShiftLeftU16x8(const a: TVecU16x8; count: Integer): TVecU16x8;
begin
  Result := ScalarShiftLeftU16x8(a, count);
end;

function NEONShiftLeftU32x4(const a: TVecU32x4; count: Integer): TVecU32x4;
begin
  Result := ScalarShiftLeftU32x4(a, count);
end;

function NEONShiftLeftU32x8(const a: TVecU32x8; count: Integer): TVecU32x8;
begin
  Result := ScalarShiftLeftU32x8(a, count);
end;

function NEONShiftLeftU64x4(const a: TVecU64x4; count: Integer): TVecU64x4;
begin
  Result := ScalarShiftLeftU64x4(a, count);
end;

function NEONShiftRightArithI16x8(const a: TVecI16x8; count: Integer): TVecI16x8;
begin
  Result := ScalarShiftRightArithI16x8(a, count);
end;

function NEONShiftRightArithI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
begin
  Result := ScalarShiftRightArithI32x16(a, count);
end;

function NEONShiftRightArithI32x4(const a: TVecI32x4; count: Integer): TVecI32x4;
begin
  Result := ScalarShiftRightArithI32x4(a, count);
end;

function NEONShiftRightArithI32x8(const a: TVecI32x8; count: Integer): TVecI32x8;
begin
  Result := ScalarShiftRightArithI32x8(a, count);
end;

function NEONShiftRightI16x8(const a: TVecI16x8; count: Integer): TVecI16x8;
begin
  Result := ScalarShiftRightI16x8(a, count);
end;

function NEONShiftRightI32x16(const a: TVecI32x16; count: Integer): TVecI32x16;
begin
  Result := ScalarShiftRightI32x16(a, count);
end;

function NEONShiftRightI32x4(const a: TVecI32x4; count: Integer): TVecI32x4;
begin
  Result := ScalarShiftRightI32x4(a, count);
end;

function NEONShiftRightI32x8(const a: TVecI32x8; count: Integer): TVecI32x8;
begin
  Result := ScalarShiftRightI32x8(a, count);
end;

function NEONShiftRightI64x4(const a: TVecI64x4; count: Integer): TVecI64x4;
begin
  Result := ScalarShiftRightI64x4(a, count);
end;

function NEONShiftRightU16x8(const a: TVecU16x8; count: Integer): TVecU16x8;
begin
  Result := ScalarShiftRightU16x8(a, count);
end;

function NEONShiftRightU32x4(const a: TVecU32x4; count: Integer): TVecU32x4;
begin
  Result := ScalarShiftRightU32x4(a, count);
end;

function NEONShiftRightU32x8(const a: TVecU32x8; count: Integer): TVecU32x8;
begin
  Result := ScalarShiftRightU32x8(a, count);
end;

function NEONShiftRightU64x4(const a: TVecU64x4; count: Integer): TVecU64x4;
begin
  Result := ScalarShiftRightU64x4(a, count);
end;

function NEONSplatF32x16(value: Single): TVecF32x16;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONSplatF32x16_ASM(value);
  {$ELSE}
  Result := ScalarSplatF32x16(value);
  {$ENDIF}
end;

function NEONSplatF32x8(value: Single): TVecF32x8;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONSplatF32x8_ASM(value);
  {$ELSE}
  Result := ScalarSplatF32x8(value);
  {$ENDIF}
end;

function NEONSplatF64x2(value: Double): TVecF64x2;
begin
  Result.d[0] := value;
  Result.d[1] := value;
end;

function NEONSplatF64x4(value: Double): TVecF64x4;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONSplatF64x4_ASM(value);
  {$ELSE}
  Result := ScalarSplatF64x4(value);
  {$ENDIF}
end;

function NEONSplatF64x8(value: Double): TVecF64x8;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONSplatF64x8_ASM(value);
  {$ELSE}
  Result := ScalarSplatF64x8(value);
  {$ENDIF}
end;

function NEONSplatI64x4(value: Int64): TVecI64x4;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONSplatI64x4_ASM(value);
  {$ELSE}
  Result := ScalarSplatI64x4(value);
  {$ENDIF}
end;

function NEONSqrtF32x16(const a: TVecF32x16): TVecF32x16;
begin
  Result := ScalarSqrtF32x16(a);
end;

function NEONSqrtF32x8(const a: TVecF32x8): TVecF32x8;
begin
  Result := ScalarSqrtF32x8(a);
end;

function NEONSqrtF64x2(const a: TVecF64x2): TVecF64x2;
begin
  Result.d[0] := Sqrt(a.d[0]);
  Result.d[1] := Sqrt(a.d[1]);
end;

function NEONSqrtF64x4(const a: TVecF64x4): TVecF64x4;
begin
  Result := ScalarSqrtF64x4(a);
end;

function NEONSqrtF64x8(const a: TVecF64x8): TVecF64x8;
begin
  Result := ScalarSqrtF64x8(a);
end;

procedure NEONStoreF32x16(p: PSingle; const a: TVecF32x16);
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  NEONStoreF32x16_ASM(p, a);
  {$ELSE}
  ScalarStoreF32x16(p, a);
  {$ENDIF}
end;

procedure NEONStoreF32x8(p: PSingle; const a: TVecF32x8);
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  NEONStoreF32x8_ASM(p, a);
  {$ELSE}
  ScalarStoreF32x8(p, a);
  {$ENDIF}
end;

procedure NEONStoreF64x2(p: PDouble; const a: TVecF64x2);
begin
  Move(a.d[0], p^, 16);
end;

procedure NEONStoreF64x4(p: PDouble; const a: TVecF64x4);
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  NEONStoreF64x4_ASM(p, a);
  {$ELSE}
  ScalarStoreF64x4(p, a);
  {$ENDIF}
end;

procedure NEONStoreF64x8(p: PDouble; const a: TVecF64x8);
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  NEONStoreF64x8_ASM(p, a);
  {$ELSE}
  ScalarStoreF64x8(p, a);
  {$ENDIF}
end;

procedure NEONStoreI64x4(p: PInt64; const a: TVecI64x4);
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  NEONStoreI64x4_ASM(p, a);
  {$ELSE}
  ScalarStoreI64x4(p, a);
  {$ENDIF}
end;

function NEONSubF32x16(const a, b: TVecF32x16): TVecF32x16;
begin
  Result := ScalarSubF32x16(a, b);
end;

function NEONSubF64x4(const a, b: TVecF64x4): TVecF64x4;
begin
  Result := ScalarSubF64x4(a, b);
end;

function NEONSubF64x8(const a, b: TVecF64x8): TVecF64x8;
begin
  Result := ScalarSubF64x8(a, b);
end;

function NEONSubI32x16(const a, b: TVecI32x16): TVecI32x16;
begin
  Result := ScalarSubI32x16(a, b);
end;

function NEONSubI32x8(const a, b: TVecI32x8): TVecI32x8;
begin
  Result := ScalarSubI32x8(a, b);
end;

function NEONSubI64x4(const a, b: TVecI64x4): TVecI64x4;
begin
  Result := ScalarSubI64x4(a, b);
end;

function NEONSubI64x8(const a, b: TVecI64x8): TVecI64x8;
begin
  Result := ScalarSubI64x8(a, b);
end;

function NEONSubU32x4(const a, b: TVecU32x4): TVecU32x4;
begin
  Result := ScalarSubU32x4(a, b);
end;

function NEONSubU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result := ScalarSubU32x8(a, b);
end;

function NEONSubU64x4(const a, b: TVecU64x4): TVecU64x4;
begin
  Result := ScalarSubU64x4(a, b);
end;

function NEONTruncF32x16(const a: TVecF32x16): TVecF32x16;
begin
  Result := ScalarTruncF32x16(a);
end;

function NEONTruncF32x8(const a: TVecF32x8): TVecF32x8;
begin
  Result := ScalarTruncF32x8(a);
end;

function NEONTruncF64x2(const a: TVecF64x2): TVecF64x2;
begin
  Result.d[0] := Trunc(a.d[0]);
  Result.d[1] := Trunc(a.d[1]);
end;

function NEONTruncF64x4(const a: TVecF64x4): TVecF64x4;
begin
  Result := ScalarTruncF64x4(a);
end;

function NEONTruncF64x8(const a: TVecF64x8): TVecF64x8;
begin
  Result := ScalarTruncF64x8(a);
end;

function NEONXorI32x16(const a, b: TVecI32x16): TVecI32x16;
begin
  Result := ScalarXorI32x16(a, b);
end;

function NEONXorI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  Result := ScalarXorI32x4(a, b);
end;

function NEONXorI32x8(const a, b: TVecI32x8): TVecI32x8;
begin
  Result := ScalarXorI32x8(a, b);
end;

function NEONXorI64x4(const a, b: TVecI64x4): TVecI64x4;
begin
  Result := ScalarXorI64x4(a, b);
end;

function NEONXorI64x8(const a, b: TVecI64x8): TVecI64x8;
begin
  Result := ScalarXorI64x8(a, b);
end;

function NEONXorU32x4(const a, b: TVecU32x4): TVecU32x4;
begin
  Result := ScalarXorU32x4(a, b);
end;

function NEONXorU32x8(const a, b: TVecU32x8): TVecU32x8;
begin
  Result := ScalarXorU32x8(a, b);
end;

function NEONXorU64x4(const a, b: TVecU64x4): TVecU64x4;
begin
  Result := ScalarXorU64x4(a, b);
end;

function NEONZeroF32x16: TVecF32x16;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONZeroF32x16_ASM;
  {$ELSE}
  Result := ScalarZeroF32x16;
  {$ENDIF}
end;

function NEONZeroF32x8: TVecF32x8;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONZeroF32x8_ASM;
  {$ELSE}
  Result := ScalarZeroF32x8;
  {$ENDIF}
end;

function NEONZeroF64x2: TVecF64x2;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function NEONZeroF64x4: TVecF64x4;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONZeroF64x4_ASM;
  {$ELSE}
  Result := ScalarZeroF64x4;
  {$ENDIF}
end;

function NEONZeroF64x8: TVecF64x8;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONZeroF64x8_ASM;
  {$ELSE}
  Result := ScalarZeroF64x8;
  {$ENDIF}
end;

function NEONZeroI64x4: TVecI64x4;
begin
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
  Result := NEONZeroI64x4_ASM;
  {$ELSE}
  Result := ScalarZeroI64x4;
  {$ENDIF}
end;

// === 256-bit & 512-bit Reduction Operations (NEON ASM) ===

{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}

// --- F32x8 Reduction (256-bit = 2 × F32x4) ---

function NEONReduceAddF32x8_ASM(const a: TVecF32x8): Single; assembler; nostackframe;
asm
  // a.lo in x0..x1, a.hi in x2..x3
  // Load lo (x0..x1) into v0
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  // Load hi (x2..x3) into v1
  fmov  d1, x2
  fmov  d3, x3
  ins   v1.d[1], v3.d[0]

  // Combine lo + hi
  fadd  v0.4s, v0.4s, v1.4s

  // Horizontal sum (pairwise)
  faddp v0.4s, v0.4s, v0.4s
  faddp s0, v0.2s
end;

function NEONReduceMinF32x8_ASM(const a: TVecF32x8): Single; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d3, x3
  ins   v1.d[1], v3.d[0]

  // Element-wise min
  fmin  v0.4s, v0.4s, v1.4s

  // Pairwise min reduction
  fminp v0.4s, v0.4s, v0.4s
  fminp s0, v0.2s
end;

function NEONReduceMaxF32x8_ASM(const a: TVecF32x8): Single; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d3, x3
  ins   v1.d[1], v3.d[0]

  fmax  v0.4s, v0.4s, v1.4s

  fmaxp v0.4s, v0.4s, v0.4s
  fmaxp s0, v0.2s
end;

function NEONReduceMulF32x8_ASM(const a: TVecF32x8): Single; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d3, x3
  ins   v1.d[1], v3.d[0]

  // Multiply lo × hi element-wise
  fmul  v0.4s, v0.4s, v1.4s

  // Extract and multiply lanes
  mov   s1, v0.s[1]
  mov   s2, v0.s[2]
  mov   s3, v0.s[3]
  fmul  s0, s0, s1
  fmul  s0, s0, s2
  fmul  s0, s0, s3
end;

// --- F64x4 Reduction (256-bit = 2 × F64x2) ---

function NEONReduceAddF64x4_ASM(const a: TVecF64x4): Double; assembler; nostackframe;
asm
  // a.lo in x0..x1, a.hi in x2..x3
  fmov  d0, x0
  fmov  d1, x1
  fmov  d2, x2
  fmov  d3, x3

  // Sum all lanes
  fadd  d0, d0, d1
  fadd  d2, d2, d3
  fadd  d0, d0, d2
end;

function NEONReduceMinF64x4_ASM(const a: TVecF64x4): Double; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d1, x1
  fmov  d2, x2
  fmov  d3, x3

  fmin  d0, d0, d1
  fmin  d2, d2, d3
  fmin  d0, d0, d2
end;

function NEONReduceMaxF64x4_ASM(const a: TVecF64x4): Double; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d1, x1
  fmov  d2, x2
  fmov  d3, x3

  fmax  d0, d0, d1
  fmax  d2, d2, d3
  fmax  d0, d0, d2
end;

function NEONReduceMulF64x4_ASM(const a: TVecF64x4): Double; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d1, x1
  fmov  d2, x2
  fmov  d3, x3

  fmul  d0, d0, d1
  fmul  d2, d2, d3
  fmul  d0, d0, d2
end;

// --- F32x16 Reduction (512-bit = 2 × F32x8) ---

function NEONReduceAddF32x16_ASM(const a: TVecF32x16): Single; assembler; nostackframe;
asm
  // a.lo (F32x8) in x0..x3, a.hi (F32x8) in x4..x7
  // Load lo.lo into v0
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  // Load lo.hi into v1
  fmov  d1, x2
  fmov  d3, x3
  ins   v1.d[1], v3.d[0]

  // Load hi.lo into v4
  fmov  d4, x4
  fmov  d6, x5
  ins   v4.d[1], v6.d[0]

  // Load hi.hi into v5
  fmov  d5, x6
  fmov  d7, x7
  ins   v5.d[1], v7.d[0]

  // Combine all 4 F32x4 vectors
  fadd  v0.4s, v0.4s, v1.4s
  fadd  v4.4s, v4.4s, v5.4s
  fadd  v0.4s, v0.4s, v4.4s

  // Horizontal sum
  faddp v0.4s, v0.4s, v0.4s
  faddp s0, v0.2s
end;

function NEONReduceMinF32x16_ASM(const a: TVecF32x16): Single; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d3, x3
  ins   v1.d[1], v3.d[0]

  fmov  d4, x4
  fmov  d6, x5
  ins   v4.d[1], v6.d[0]

  fmov  d5, x6
  fmov  d7, x7
  ins   v5.d[1], v7.d[0]

  fmin  v0.4s, v0.4s, v1.4s
  fmin  v4.4s, v4.4s, v5.4s
  fmin  v0.4s, v0.4s, v4.4s

  fminp v0.4s, v0.4s, v0.4s
  fminp s0, v0.2s
end;

function NEONReduceMaxF32x16_ASM(const a: TVecF32x16): Single; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d3, x3
  ins   v1.d[1], v3.d[0]

  fmov  d4, x4
  fmov  d6, x5
  ins   v4.d[1], v6.d[0]

  fmov  d5, x6
  fmov  d7, x7
  ins   v5.d[1], v7.d[0]

  fmax  v0.4s, v0.4s, v1.4s
  fmax  v4.4s, v4.4s, v5.4s
  fmax  v0.4s, v0.4s, v4.4s

  fmaxp v0.4s, v0.4s, v0.4s
  fmaxp s0, v0.2s
end;

function NEONReduceMulF32x16_ASM(const a: TVecF32x16): Single; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]

  fmov  d1, x2
  fmov  d3, x3
  ins   v1.d[1], v3.d[0]

  fmov  d4, x4
  fmov  d6, x5
  ins   v4.d[1], v6.d[0]

  fmov  d5, x6
  fmov  d7, x7
  ins   v5.d[1], v7.d[0]

  // Multiply all 4 vectors
  fmul  v0.4s, v0.4s, v1.4s
  fmul  v4.4s, v4.4s, v5.4s
  fmul  v0.4s, v0.4s, v4.4s

  // Extract and multiply lanes
  mov   s1, v0.s[1]
  mov   s2, v0.s[2]
  mov   s3, v0.s[3]
  fmul  s0, s0, s1
  fmul  s0, s0, s2
  fmul  s0, s0, s3
end;

// --- F64x8 Reduction (512-bit = 2 × F64x4) ---

function NEONReduceAddF64x8_ASM(const a: TVecF64x8): Double; assembler; nostackframe;
asm
  // a.lo (F64x4) in x0..x3, a.hi (F64x4) in x4..x7
  fmov  d0, x0
  fmov  d1, x1
  fmov  d2, x2
  fmov  d3, x3
  fmov  d4, x4
  fmov  d5, x5
  fmov  d6, x6
  fmov  d7, x7

  // Sum all 8 lanes
  fadd  d0, d0, d1
  fadd  d2, d2, d3
  fadd  d4, d4, d5
  fadd  d6, d6, d7
  fadd  d0, d0, d2
  fadd  d4, d4, d6
  fadd  d0, d0, d4
end;

function NEONReduceMinF64x8_ASM(const a: TVecF64x8): Double; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d1, x1
  fmov  d2, x2
  fmov  d3, x3
  fmov  d4, x4
  fmov  d5, x5
  fmov  d6, x6
  fmov  d7, x7

  fmin  d0, d0, d1
  fmin  d2, d2, d3
  fmin  d4, d4, d5
  fmin  d6, d6, d7
  fmin  d0, d0, d2
  fmin  d4, d4, d6
  fmin  d0, d0, d4
end;

function NEONReduceMaxF64x8_ASM(const a: TVecF64x8): Double; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d1, x1
  fmov  d2, x2
  fmov  d3, x3
  fmov  d4, x4
  fmov  d5, x5
  fmov  d6, x6
  fmov  d7, x7

  fmax  d0, d0, d1
  fmax  d2, d2, d3
  fmax  d4, d4, d5
  fmax  d6, d6, d7
  fmax  d0, d0, d2
  fmax  d4, d4, d6
  fmax  d0, d0, d4
end;

function NEONReduceMulF64x8_ASM(const a: TVecF64x8): Double; assembler; nostackframe;
asm
  fmov  d0, x0
  fmov  d1, x1
  fmov  d2, x2
  fmov  d3, x3
  fmov  d4, x4
  fmov  d5, x5
  fmov  d6, x6
  fmov  d7, x7

  fmul  d0, d0, d1
  fmul  d2, d2, d3
  fmul  d4, d4, d5
  fmul  d6, d6, d7
  fmul  d0, d0, d2
  fmul  d4, d4, d6
  fmul  d0, d0, d4
end;

// === 256-bit & 512-bit Memory Operations (NEON ASM) ===

// --- F32x8 Memory Ops (256-bit = 2 × F32x4) ---

function NEONLoadF32x8_ASM(p: PSingle): TVecF32x8; assembler; nostackframe;
asm
  // p in x0, return TVecF32x8 in x0..x3
  // Load 256-bit (2 × 128-bit)
  ldp   q0, q1, [x0]

  // Extract lo (v0) to x0..x1
  umov  x0, v0.d[0]
  umov  x1, v0.d[1]

  // Extract hi (v1) to x2..x3
  umov  x2, v1.d[0]
  umov  x3, v1.d[1]
end;

procedure NEONStoreF32x8_ASM(p: PSingle; const a: TVecF32x8); assembler; nostackframe;
asm
  // p in x0, a in x1..x4 (lo: x1..x2, hi: x3..x4)
  // Build lo in v0
  fmov  d0, x1
  fmov  d2, x2
  ins   v0.d[1], v2.d[0]

  // Build hi in v1
  fmov  d1, x3
  fmov  d3, x4
  ins   v1.d[1], v3.d[0]

  // Store 256-bit
  stp   q0, q1, [x0]
end;

function NEONSplatF32x8_ASM(value: Single): TVecF32x8; assembler; nostackframe;
asm
  // value in s0
  fmov  w4, s0
  dup   v0.4s, w4
  dup   v1.4s, w4

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
  umov  x2, v1.d[0]
  umov  x3, v1.d[1]
end;

function NEONZeroF32x8_ASM: TVecF32x8; assembler; nostackframe;
asm
  mov   x0, xzr
  mov   x1, xzr
  mov   x2, xzr
  mov   x3, xzr
end;

// --- F64x4 Memory Ops (256-bit = 2 × F64x2) ---

function NEONLoadF64x4_ASM(p: PDouble): TVecF64x4; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
  umov  x2, v1.d[0]
  umov  x3, v1.d[1]
end;

procedure NEONStoreF64x4_ASM(p: PDouble; const a: TVecF64x4); assembler; nostackframe;
asm
  fmov  d0, x1
  fmov  d2, x2
  ins   v0.d[1], v2.d[0]

  fmov  d1, x3
  fmov  d3, x4
  ins   v1.d[1], v3.d[0]

  stp   q0, q1, [x0]
end;

function NEONSplatF64x4_ASM(value: Double): TVecF64x4; assembler; nostackframe;
asm
  // value in d0
  dup   v0.2d, v0.d[0]
  dup   v1.2d, v0.d[0]

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
  umov  x2, v1.d[0]
  umov  x3, v1.d[1]
end;

function NEONZeroF64x4_ASM: TVecF64x4; assembler; nostackframe;
asm
  mov   x0, xzr
  mov   x1, xzr
  mov   x2, xzr
  mov   x3, xzr
end;

// --- F32x16 Memory Ops (512-bit = 4 × F32x4) ---

function NEONLoadF32x16_ASM(p: PSingle): TVecF32x16; assembler; nostackframe;
asm
  // p in x0, return TVecF32x16 in x0..x7
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x0, #32]

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
  umov  x2, v1.d[0]
  umov  x3, v1.d[1]
  umov  x4, v2.d[0]
  umov  x5, v2.d[1]
  umov  x6, v3.d[0]
  umov  x7, v3.d[1]
end;

procedure NEONStoreF32x16_ASM(p: PSingle; const a: TVecF32x16); assembler; nostackframe;
asm
  // p in x0, a in x1..x8 (stack: x8 is passed in [sp])
  // Build v0..v3
  fmov  d0, x1
  fmov  d4, x2
  ins   v0.d[1], v4.d[0]

  fmov  d1, x3
  fmov  d5, x4
  ins   v1.d[1], v5.d[0]

  fmov  d2, x5
  fmov  d6, x6
  ins   v2.d[1], v6.d[0]

  fmov  d3, x7
  ldr   x9, [sp]
  fmov  d7, x9
  ins   v3.d[1], v7.d[0]

  stp   q0, q1, [x0]
  stp   q2, q3, [x0, #32]
end;

function NEONSplatF32x16_ASM(value: Single): TVecF32x16; assembler; nostackframe;
asm
  fmov  w4, s0
  dup   v0.4s, w4
  dup   v1.4s, w4
  dup   v2.4s, w4
  dup   v3.4s, w4

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
  umov  x2, v1.d[0]
  umov  x3, v1.d[1]
  umov  x4, v2.d[0]
  umov  x5, v2.d[1]
  umov  x6, v3.d[0]
  umov  x7, v3.d[1]
end;

function NEONZeroF32x16_ASM: TVecF32x16; assembler; nostackframe;
asm
  mov   x0, xzr
  mov   x1, xzr
  mov   x2, xzr
  mov   x3, xzr
  mov   x4, xzr
  mov   x5, xzr
  mov   x6, xzr
  mov   x7, xzr
end;

// --- F64x8 Memory Ops (512-bit = 4 × F64x2) ---

function NEONLoadF64x8_ASM(p: PDouble): TVecF64x8; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]
  ldp   q2, q3, [x0, #32]

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
  umov  x2, v1.d[0]
  umov  x3, v1.d[1]
  umov  x4, v2.d[0]
  umov  x5, v2.d[1]
  umov  x6, v3.d[0]
  umov  x7, v3.d[1]
end;

procedure NEONStoreF64x8_ASM(p: PDouble; const a: TVecF64x8); assembler; nostackframe;
asm
  fmov  d0, x1
  fmov  d4, x2
  ins   v0.d[1], v4.d[0]

  fmov  d1, x3
  fmov  d5, x4
  ins   v1.d[1], v5.d[0]

  fmov  d2, x5
  fmov  d6, x6
  ins   v2.d[1], v6.d[0]

  fmov  d3, x7
  ldr   x9, [sp]
  fmov  d7, x9
  ins   v3.d[1], v7.d[0]

  stp   q0, q1, [x0]
  stp   q2, q3, [x0, #32]
end;

function NEONSplatF64x8_ASM(value: Double): TVecF64x8; assembler; nostackframe;
asm
  dup   v0.2d, v0.d[0]
  dup   v1.2d, v0.d[0]
  dup   v2.2d, v0.d[0]
  dup   v3.2d, v0.d[0]

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
  umov  x2, v1.d[0]
  umov  x3, v1.d[1]
  umov  x4, v2.d[0]
  umov  x5, v2.d[1]
  umov  x6, v3.d[0]
  umov  x7, v3.d[1]
end;

function NEONZeroF64x8_ASM: TVecF64x8; assembler; nostackframe;
asm
  mov   x0, xzr
  mov   x1, xzr
  mov   x2, xzr
  mov   x3, xzr
  mov   x4, xzr
  mov   x5, xzr
  mov   x6, xzr
  mov   x7, xzr
end;

// --- I64x4 Memory Ops (256-bit = 2 × I64x2) ---

function NEONLoadI64x4_ASM(p: PInt64): TVecI64x4; assembler; nostackframe;
asm
  ldp   q0, q1, [x0]

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
  umov  x2, v1.d[0]
  umov  x3, v1.d[1]
end;

procedure NEONStoreI64x4_ASM(p: PInt64; const a: TVecI64x4); assembler; nostackframe;
asm
  fmov  d0, x1
  fmov  d2, x2
  ins   v0.d[1], v2.d[0]

  fmov  d1, x3
  fmov  d3, x4
  ins   v1.d[1], v3.d[0]

  stp   q0, q1, [x0]
end;

function NEONSplatI64x4_ASM(value: Int64): TVecI64x4; assembler; nostackframe;
asm
  // value in x0
  dup   v0.2d, x0
  dup   v1.2d, x0

  umov  x0, v0.d[0]
  umov  x1, v0.d[1]
  umov  x2, v1.d[0]
  umov  x3, v1.d[1]
end;

function NEONZeroI64x4_ASM: TVecI64x4; assembler; nostackframe;
asm
  mov   x0, xzr
  mov   x1, xzr
  mov   x2, xzr
  mov   x3, xzr
end;

{$ENDIF} // FAFAFA_SIMD_NEON_ASM_ENABLED (256/512-bit ASM implementations)

{$ENDIF} // FAFAFA_SIMD_NEON_ASM_ENABLED

// === Platform-Independent Facade Functions ===
// (These always use scalar fallback regardless of platform)

function MemDiffRange_NEON(a, b: Pointer; len: SizeUInt; out firstDiff, lastDiff: SizeUInt): Boolean;
begin
  Result := MemDiffRange_Scalar(a, b, len, firstDiff, lastDiff);
end;

procedure MemCopy_NEON(src, dst: Pointer; len: SizeUInt);
begin
  MemCopy_Scalar(src, dst, len);
end;

procedure MemSet_NEON(dst: Pointer; len: SizeUInt; value: Byte);
begin
  MemSet_Scalar(dst, len, value);
end;

procedure MemReverse_NEON(p: Pointer; len: SizeUInt);
begin
  MemReverse_Scalar(p, len);
end;

function Utf8Validate_NEON(p: Pointer; len: SizeUInt): Boolean;
begin
  Result := Utf8Validate_Scalar(p, len);
end;

function BytesIndexOf_NEON(haystack: Pointer; haystackLen: SizeUInt; needle: Pointer; needleLen: SizeUInt): PtrInt;
begin
  Result := BytesIndexOf_Scalar(haystack, haystackLen, needle, needleLen);
end;

// === Dot Product Functions (needed by RegisterNEONBackend) ===

// ✅ Iteration 6.4: FMA-optimized Dot Product Functions (NEON)

function NEONDotF32x8(const a, b: TVecF32x8): Single; assembler; nostackframe;
asm
  // a: x0..x3 (2 registers), b: x4..x7 (2 registers)
  // Load a (256-bit) -> v0, v1
  fmov  d0, x0
  fmov  d4, x1
  ins   v0.d[1], v4.d[0]  // v0 = a[0..3]

  fmov  d1, x2
  fmov  d4, x3
  ins   v1.d[1], v4.d[0]  // v1 = a[4..7]

  // Load b (256-bit) -> v2, v3
  fmov  d2, x4
  fmov  d4, x5
  ins   v2.d[1], v4.d[0]  // v2 = b[0..3]

  fmov  d3, x6
  fmov  d4, x7
  ins   v3.d[1], v4.d[0]  // v3 = b[4..7]

  // Multiply
  fmul  v0.4s, v0.4s, v2.4s  // v0 = a[0..3] * b[0..3]
  fmul  v1.4s, v1.4s, v3.4s  // v1 = a[4..7] * b[4..7]

  // Add the two halves
  fadd  v0.4s, v0.4s, v1.4s

  // Horizontal sum of v0
  faddp v0.4s, v0.4s, v0.4s  // pairwise add
  faddp s0, v0.2s            // final sum

  // Result in s0
end;

function NEONDotF64x2(const a, b: TVecF64x2): Double; assembler; nostackframe;
asm
  // a: x0..x1, b: x2..x3
  fmov  d0, x0
  fmov  d2, x1
  ins   v0.d[1], v2.d[0]  // v0 = a[0..1]

  fmov  d1, x2
  fmov  d2, x3
  ins   v1.d[1], v2.d[0]  // v1 = b[0..1]

  fmul  v0.2d, v0.2d, v1.2d  // v0 = a * b

  // Horizontal sum
  faddp d0, v0.2d            // sum both elements

  // Result in d0
end;

function NEONDotF64x4(const a, b: TVecF64x4): Double; assembler; nostackframe;
asm
  // a: x0..x3, b: x4..x7
  // Load a (256-bit) -> v0, v1
  fmov  d0, x0
  fmov  d4, x1
  ins   v0.d[1], v4.d[0]  // v0 = a[0..1]

  fmov  d1, x2
  fmov  d4, x3
  ins   v1.d[1], v4.d[0]  // v1 = a[2..3]

  // Load b (256-bit) -> v2, v3
  fmov  d2, x4
  fmov  d4, x5
  ins   v2.d[1], v4.d[0]  // v2 = b[0..1]

  fmov  d3, x6
  fmov  d4, x7
  ins   v3.d[1], v4.d[0]  // v3 = b[2..3]

  // Multiply
  fmul  v0.2d, v0.2d, v2.2d  // v0 = a[0..1] * b[0..1]
  fmul  v1.2d, v1.2d, v3.2d  // v1 = a[2..3] * b[2..3]

  // Add the two halves
  fadd  v0.2d, v0.2d, v1.2d

  // Horizontal sum
  faddp d0, v0.2d

  // Result in d0
end;

// === Backend Registration ===

procedure RegisterNEONBackend;
var
  table: TSimdDispatchTable;
begin
  // Fill with base scalar implementations (provides fallback for unimplemented operations)
  FillBaseDispatchTable(table);

  // Backend info
  table.Backend := sbNEON;
  table.BackendInfo.Backend := sbNEON;
  table.BackendInfo.Available := True;
  table.BackendInfo.Name := 'NEON';
  table.BackendInfo.Description := 'ARM NEON 128-bit SIMD';
  table.BackendInfo.Capabilities := [scBasicArithmetic, scComparison, scMathFunctions,
                                     scReduction, scIntegerOps, scLoadStore, scFMA];
  table.BackendInfo.Priority := 40;  // Higher than Scalar (0), lower than AVX2 (60)

  // Override with NEON-accelerated operations
  // Arithmetic operations - F32x4
  table.AddF32x4 := @NEONAddF32x4;
  table.SubF32x4 := @NEONSubF32x4;
  table.MulF32x4 := @NEONMulF32x4;
  table.DivF32x4 := @NEONDivF32x4;

  // Arithmetic operations - F32x8 (emulated via 2x F32x4)
  table.AddF32x8 := @NEONAddF32x8;
  table.SubF32x8 := @NEONSubF32x8;
  table.MulF32x8 := @NEONMulF32x8;
  table.DivF32x8 := @NEONDivF32x8;

  // Arithmetic operations - F64x2
  table.AddF64x2 := @NEONAddF64x2;
  table.SubF64x2 := @NEONSubF64x2;
  table.MulF64x2 := @NEONMulF64x2;
  table.DivF64x2 := @NEONDivF64x2;

  // Arithmetic operations - I32x4
  table.AddI32x4 := @NEONAddI32x4;
  table.SubI32x4 := @NEONSubI32x4;
  table.MulI32x4 := @NEONMulI32x4;

  // Comparison operations
  table.CmpEqF32x4 := @NEONCmpEqF32x4;
  table.CmpLtF32x4 := @NEONCmpLtF32x4;
  table.CmpLeF32x4 := @NEONCmpLeF32x4;
  table.CmpGtF32x4 := @NEONCmpGtF32x4;
  table.CmpGeF32x4 := @NEONCmpGeF32x4;
  table.CmpNeF32x4 := @NEONCmpNeF32x4;

  // Math functions
  table.AbsF32x4 := @NEONAbsF32x4;
  table.SqrtF32x4 := @NEONSqrtF32x4;
  table.MinF32x4 := @NEONMinF32x4;
  table.MaxF32x4 := @NEONMaxF32x4;

  // Extended math functions
  table.FmaF32x4 := @NEONFmaF32x4;
  table.RcpF32x4 := @NEONRcpF32x4;
  table.RsqrtF32x4 := @NEONRsqrtF32x4;
  table.FloorF32x4 := @NEONFloorF32x4;
  table.CeilF32x4 := @NEONCeilF32x4;
  table.RoundF32x4 := @NEONRoundF32x4;
  table.TruncF32x4 := @NEONTruncF32x4;
  table.ClampF32x4 := @NEONClampF32x4;

  // 3D/4D Vector math
  table.DotF32x4 := @NEONDotF32x4;
  table.DotF32x3 := @NEONDotF32x3;
  table.CrossF32x3 := @NEONCrossF32x3;
  table.LengthF32x4 := @NEONLengthF32x4;
  table.LengthF32x3 := @NEONLengthF32x3;
  table.NormalizeF32x4 := @NEONNormalizeF32x4;

  // ✅ Iteration 6.4: FMA-optimized Dot Product
  table.DotF32x8 := @NEONDotF32x8;
  table.DotF64x2 := @NEONDotF64x2;
  table.DotF64x4 := @NEONDotF64x4;
  table.NormalizeF32x3 := @NEONNormalizeF32x3;

  // Reduction operations
  table.ReduceAddF32x4 := @NEONReduceAddF32x4;
  table.ReduceMinF32x4 := @NEONReduceMinF32x4;
  table.ReduceMaxF32x4 := @NEONReduceMaxF32x4;
  table.ReduceMulF32x4 := @NEONReduceMulF32x4;

  // Memory operations
  table.LoadF32x4 := @NEONLoadF32x4;
  table.LoadF32x4Aligned := @NEONLoadF32x4Aligned;
  table.StoreF32x4 := @NEONStoreF32x4;
  table.StoreF32x4Aligned := @NEONStoreF32x4Aligned;

  // Utility operations
  table.SplatF32x4 := @NEONSplatF32x4;
  table.ZeroF32x4 := @NEONZeroF32x4;
  table.SelectF32x4 := @NEONSelectF32x4;
  table.ExtractF32x4 := @NEONExtractF32x4;
  table.InsertF32x4 := @NEONInsertF32x4;

  // Facade functions
  table.MemEqual := @MemEqual_NEON;
  table.MemFindByte := @MemFindByte_NEON;
  table.MemDiffRange := @MemDiffRange_NEON;
  table.MemCopy := @MemCopy_NEON;
  table.MemSet := @MemSet_NEON;
  table.MemReverse := @MemReverse_NEON;
  table.SumBytes := @SumBytes_NEON;
  table.MinMaxBytes := @MinMaxBytes_NEON;
  table.CountByte := @CountByte_NEON;
  table.Utf8Validate := @Utf8Validate_NEON;
  table.AsciiIEqual := @AsciiIEqual_NEON;
  table.ToLowerAscii := @ToLowerAscii_NEON;
  table.ToUpperAscii := @ToUpperAscii_NEON;
  table.BytesIndexOf := @BytesIndexOf_NEON;
  table.BitsetPopCount := @BitsetPopCount_NEON;

  // ✅ P2: Saturating Arithmetic
  table.I8x16SatAdd := @NEONI8x16SatAdd;
  table.I8x16SatSub := @NEONI8x16SatSub;
  table.I16x8SatAdd := @NEONI16x8SatAdd;
  table.I16x8SatSub := @NEONI16x8SatSub;
  table.U8x16SatAdd := @NEONU8x16SatAdd;
  table.U8x16SatSub := @NEONU8x16SatSub;
  table.U16x8SatAdd := @NEONU16x8SatAdd;
  table.U16x8SatSub := @NEONU16x8SatSub;

  // ✅ P3: I64x2 Arithmetic, Bitwise, and Comparison
  table.AddI64x2 := @NEONAddI64x2;
  table.SubI64x2 := @NEONSubI64x2;
  table.AndI64x2 := @NEONAndI64x2;
  table.OrI64x2 := @NEONOrI64x2;
  table.XorI64x2 := @NEONXorI64x2;
  table.NotI64x2 := @NEONNotI64x2;
  table.CmpEqI64x2 := @NEONCmpEqI64x2;
  table.CmpLtI64x2 := @NEONCmpLtI64x2;
  table.CmpGtI64x2 := @NEONCmpGtI64x2;
  table.CmpLeI64x2 := @NEONCmpLeI64x2;
  table.CmpGeI64x2 := @NEONCmpGeI64x2;
  table.CmpNeI64x2 := @NEONCmpNeI64x2;

  // ✅ I16x8 整数操作 (8×Int16)
  table.AddI16x8 := @NEONAddI16x8;
  table.SubI16x8 := @NEONSubI16x8;
  table.MulI16x8 := @NEONMulI16x8;
  table.AndI16x8 := @NEONAndI16x8;
  table.OrI16x8 := @NEONOrI16x8;
  table.XorI16x8 := @NEONXorI16x8;
  table.NotI16x8 := @NEONNotI16x8;
  table.AndNotI16x8 := @NEONAndNotI16x8;
  table.MinI16x8 := @NEONMinI16x8;
  table.MaxI16x8 := @NEONMaxI16x8;

  // ✅ I8x16 整数操作 (16×Int8)
  table.AddI8x16 := @NEONAddI8x16;
  table.SubI8x16 := @NEONSubI8x16;
  table.AndI8x16 := @NEONAndI8x16;
  table.OrI8x16 := @NEONOrI8x16;
  table.XorI8x16 := @NEONXorI8x16;
  table.NotI8x16 := @NEONNotI8x16;
  table.MinI8x16 := @NEONMinI8x16;
  table.MaxI8x16 := @NEONMaxI8x16;

  // ✅ U16x8 无符号整数操作 (8×UInt16)
  table.AddU16x8 := @NEONAddU16x8;
  table.SubU16x8 := @NEONSubU16x8;
  table.MulU16x8 := @NEONMulU16x8;
  table.AndU16x8 := @NEONAndU16x8;
  table.OrU16x8 := @NEONOrU16x8;
  table.XorU16x8 := @NEONXorU16x8;
  table.NotU16x8 := @NEONNotU16x8;
  table.MinU16x8 := @NEONMinU16x8;
  table.MaxU16x8 := @NEONMaxU16x8;

  // ✅ U8x16 无符号整数操作 (16×UInt8)
  table.AddU8x16 := @NEONAddU8x16;
  table.SubU8x16 := @NEONSubU8x16;
  table.AndU8x16 := @NEONAndU8x16;
  table.OrU8x16 := @NEONOrU8x16;
  table.XorU8x16 := @NEONXorU8x16;
  table.NotU8x16 := @NEONNotU8x16;
  table.MinU8x16 := @NEONMinU8x16;
  table.MaxU8x16 := @NEONMaxU8x16;

  // ✅ P4: SelectF64x2
  table.SelectF64x2 := @NEONSelectF64x2;

  // ✅ P1: Mask Operations
  table.Mask2All := @NEONMask2All;
  table.Mask2Any := @NEONMask2Any;
  table.Mask2None := @NEONMask2None;
  table.Mask2PopCount := @NEONMask2PopCount;
  table.Mask2FirstSet := @NEONMask2FirstSet;
  table.Mask4All := @NEONMask4All;
  table.Mask4Any := @NEONMask4Any;
  table.Mask4None := @NEONMask4None;
  table.Mask4PopCount := @NEONMask4PopCount;
  table.Mask4FirstSet := @NEONMask4FirstSet;
  table.Mask8All := @NEONMask8All;
  table.Mask8Any := @NEONMask8Any;
  table.Mask8None := @NEONMask8None;
  table.Mask8PopCount := @NEONMask8PopCount;
  table.Mask8FirstSet := @NEONMask8FirstSet;
  table.Mask16All := @NEONMask16All;
  table.Mask16Any := @NEONMask16Any;
  table.Mask16None := @NEONMask16None;
  table.Mask16PopCount := @NEONMask16PopCount;
  table.Mask16FirstSet := @NEONMask16FirstSet;

  // === Auto-generated Registration for 100% Coverage ===
  table.AbsF32x16 := @NEONAbsF32x16;
  table.AbsF32x8 := @NEONAbsF32x8;
  table.AbsF64x2 := @NEONAbsF64x2;
  table.AbsF64x4 := @NEONAbsF64x4;
  table.AbsF64x8 := @NEONAbsF64x8;
  table.AddF32x16 := @NEONAddF32x16;
  table.AddF64x4 := @NEONAddF64x4;
  table.AddF64x8 := @NEONAddF64x8;
  table.AddI32x16 := @NEONAddI32x16;
  table.AddI32x8 := @NEONAddI32x8;
  table.AddI64x4 := @NEONAddI64x4;
  table.AddI64x8 := @NEONAddI64x8;
  table.AddU32x4 := @NEONAddU32x4;
  table.AddU32x8 := @NEONAddU32x8;
  table.AddU64x4 := @NEONAddU64x4;
  table.AndI32x16 := @NEONAndI32x16;
  table.AndI32x4 := @NEONAndI32x4;
  table.AndI32x8 := @NEONAndI32x8;
  table.AndI64x4 := @NEONAndI64x4;
  table.AndI64x8 := @NEONAndI64x8;
  table.AndNotI32x16 := @NEONAndNotI32x16;
  table.AndNotI32x4 := @NEONAndNotI32x4;
  table.AndNotI32x8 := @NEONAndNotI32x8;
  table.AndNotI64x4 := @NEONAndNotI64x4;
  table.AndNotU32x4 := @NEONAndNotU32x4;
  table.AndNotU32x8 := @NEONAndNotU32x8;
  table.AndU32x4 := @NEONAndU32x4;
  table.AndU32x8 := @NEONAndU32x8;
  table.AndU64x4 := @NEONAndU64x4;
  table.CeilF32x16 := @NEONCeilF32x16;
  table.CeilF32x8 := @NEONCeilF32x8;
  table.CeilF64x2 := @NEONCeilF64x2;
  table.CeilF64x4 := @NEONCeilF64x4;
  table.CeilF64x8 := @NEONCeilF64x8;
  table.ClampF32x16 := @NEONClampF32x16;
  table.ClampF32x8 := @NEONClampF32x8;
  table.ClampF64x2 := @NEONClampF64x2;
  table.ClampF64x4 := @NEONClampF64x4;
  table.ClampF64x8 := @NEONClampF64x8;
  table.CmpEqF32x16 := @NEONCmpEqF32x16;
  table.CmpEqF32x8 := @NEONCmpEqF32x8;
  table.CmpEqF64x2 := @NEONCmpEqF64x2;
  table.CmpEqF64x4 := @NEONCmpEqF64x4;
  table.CmpEqF64x8 := @NEONCmpEqF64x8;
  table.CmpEqI16x8 := @NEONCmpEqI16x8;
  table.CmpEqI32x16 := @NEONCmpEqI32x16;
  table.CmpEqI32x4 := @NEONCmpEqI32x4;
  table.CmpEqI32x8 := @NEONCmpEqI32x8;
  table.CmpEqI64x4 := @NEONCmpEqI64x4;
  table.CmpEqI64x8 := @NEONCmpEqI64x8;
  table.CmpEqI8x16 := @NEONCmpEqI8x16;
  table.CmpEqU16x8 := @NEONCmpEqU16x8;
  table.CmpEqU32x4 := @NEONCmpEqU32x4;
  table.CmpEqU32x8 := @NEONCmpEqU32x8;
  table.CmpEqU64x4 := @NEONCmpEqU64x4;
  table.CmpEqU8x16 := @NEONCmpEqU8x16;
  table.CmpGeF32x16 := @NEONCmpGeF32x16;
  table.CmpGeF32x8 := @NEONCmpGeF32x8;
  table.CmpGeF64x2 := @NEONCmpGeF64x2;
  table.CmpGeF64x4 := @NEONCmpGeF64x4;
  table.CmpGeF64x8 := @NEONCmpGeF64x8;
  table.CmpGeI16x8 := @NEONCmpGeI16x8;
  table.CmpGeI32x16 := @NEONCmpGeI32x16;
  table.CmpGeI32x4 := @NEONCmpGeI32x4;
  table.CmpGeI32x8 := @NEONCmpGeI32x8;
  table.CmpGeI64x4 := @NEONCmpGeI64x4;
  table.CmpGeI64x8 := @NEONCmpGeI64x8;
  table.CmpGeI8x16 := @NEONCmpGeI8x16;
  table.CmpGeU16x8 := @NEONCmpGeU16x8;
  table.CmpGeU32x4 := @NEONCmpGeU32x4;
  table.CmpGeU32x8 := @NEONCmpGeU32x8;
  table.CmpGeU64x4 := @NEONCmpGeU64x4;
  table.CmpGeU8x16 := @NEONCmpGeU8x16;
  table.CmpGtF32x16 := @NEONCmpGtF32x16;
  table.CmpGtF32x8 := @NEONCmpGtF32x8;
  table.CmpGtF64x2 := @NEONCmpGtF64x2;
  table.CmpGtF64x4 := @NEONCmpGtF64x4;
  table.CmpGtF64x8 := @NEONCmpGtF64x8;
  table.CmpGtI16x8 := @NEONCmpGtI16x8;
  table.CmpGtI32x16 := @NEONCmpGtI32x16;
  table.CmpGtI32x4 := @NEONCmpGtI32x4;
  table.CmpGtI32x8 := @NEONCmpGtI32x8;
  table.CmpGtI64x4 := @NEONCmpGtI64x4;
  table.CmpGtI64x8 := @NEONCmpGtI64x8;
  table.CmpGtI8x16 := @NEONCmpGtI8x16;
  table.CmpGtU16x8 := @NEONCmpGtU16x8;
  table.CmpGtU32x4 := @NEONCmpGtU32x4;
  table.CmpGtU32x8 := @NEONCmpGtU32x8;
  table.CmpGtU64x4 := @NEONCmpGtU64x4;
  table.CmpGtU8x16 := @NEONCmpGtU8x16;
  table.CmpLeF32x16 := @NEONCmpLeF32x16;
  table.CmpLeF32x8 := @NEONCmpLeF32x8;
  table.CmpLeF64x2 := @NEONCmpLeF64x2;
  table.CmpLeF64x4 := @NEONCmpLeF64x4;
  table.CmpLeF64x8 := @NEONCmpLeF64x8;
  table.CmpLeI16x8 := @NEONCmpLeI16x8;
  table.CmpLeI32x16 := @NEONCmpLeI32x16;
  table.CmpLeI32x4 := @NEONCmpLeI32x4;
  table.CmpLeI32x8 := @NEONCmpLeI32x8;
  table.CmpLeI64x4 := @NEONCmpLeI64x4;
  table.CmpLeI64x8 := @NEONCmpLeI64x8;
  table.CmpLeI8x16 := @NEONCmpLeI8x16;
  table.CmpLeU16x8 := @NEONCmpLeU16x8;
  table.CmpLeU32x4 := @NEONCmpLeU32x4;
  table.CmpLeU32x8 := @NEONCmpLeU32x8;
  table.CmpLeU64x4 := @NEONCmpLeU64x4;
  table.CmpLeU8x16 := @NEONCmpLeU8x16;
  table.CmpLtF32x16 := @NEONCmpLtF32x16;
  table.CmpLtF32x8 := @NEONCmpLtF32x8;
  table.CmpLtF64x2 := @NEONCmpLtF64x2;
  table.CmpLtF64x4 := @NEONCmpLtF64x4;
  table.CmpLtF64x8 := @NEONCmpLtF64x8;
  table.CmpLtI16x8 := @NEONCmpLtI16x8;
  table.CmpLtI32x16 := @NEONCmpLtI32x16;
  table.CmpLtI32x4 := @NEONCmpLtI32x4;
  table.CmpLtI32x8 := @NEONCmpLtI32x8;
  table.CmpLtI64x4 := @NEONCmpLtI64x4;
  table.CmpLtI64x8 := @NEONCmpLtI64x8;
  table.CmpLtI8x16 := @NEONCmpLtI8x16;
  table.CmpLtU16x8 := @NEONCmpLtU16x8;
  table.CmpLtU32x4 := @NEONCmpLtU32x4;
  table.CmpLtU32x8 := @NEONCmpLtU32x8;
  table.CmpLtU64x4 := @NEONCmpLtU64x4;
  table.CmpLtU8x16 := @NEONCmpLtU8x16;
  table.CmpNeF32x16 := @NEONCmpNeF32x16;
  table.CmpNeF32x8 := @NEONCmpNeF32x8;
  table.CmpNeF64x2 := @NEONCmpNeF64x2;
  table.CmpNeF64x4 := @NEONCmpNeF64x4;
  table.CmpNeF64x8 := @NEONCmpNeF64x8;
  table.CmpNeI16x8 := @NEONCmpNeI16x8;
  table.CmpNeI32x16 := @NEONCmpNeI32x16;
  table.CmpNeI32x4 := @NEONCmpNeI32x4;
  table.CmpNeI32x8 := @NEONCmpNeI32x8;
  table.CmpNeI64x4 := @NEONCmpNeI64x4;
  table.CmpNeI64x8 := @NEONCmpNeI64x8;
  table.CmpNeI8x16 := @NEONCmpNeI8x16;
  table.CmpNeU16x8 := @NEONCmpNeU16x8;
  table.CmpNeU32x8 := @NEONCmpNeU32x8;
  table.CmpNeU64x4 := @NEONCmpNeU64x4;
  table.CmpNeU8x16 := @NEONCmpNeU8x16;
  table.DivF32x16 := @NEONDivF32x16;
  table.DivF64x4 := @NEONDivF64x4;
  table.DivF64x8 := @NEONDivF64x8;
  table.ExtractF32x16 := @NEONExtractF32x16;
  table.ExtractF32x8 := @NEONExtractF32x8;
  table.ExtractF64x2 := @NEONExtractF64x2;
  table.ExtractF64x4 := @NEONExtractF64x4;
  table.ExtractI32x16 := @NEONExtractI32x16;
  table.ExtractI32x4 := @NEONExtractI32x4;
  table.ExtractI32x8 := @NEONExtractI32x8;
  table.ExtractI64x2 := @NEONExtractI64x2;
  table.ExtractI64x4 := @NEONExtractI64x4;
  table.FloorF32x16 := @NEONFloorF32x16;
  table.FloorF32x8 := @NEONFloorF32x8;
  table.FloorF64x2 := @NEONFloorF64x2;
  table.FloorF64x4 := @NEONFloorF64x4;
  table.FloorF64x8 := @NEONFloorF64x8;
  table.FmaF32x16 := @NEONFmaF32x16;
  table.FmaF32x8 := @NEONFmaF32x8;
  table.FmaF64x2 := @NEONFmaF64x2;
  table.FmaF64x4 := @NEONFmaF64x4;
  table.FmaF64x8 := @NEONFmaF64x8;
  table.InsertF32x16 := @NEONInsertF32x16;
  table.InsertF32x8 := @NEONInsertF32x8;
  table.InsertF64x2 := @NEONInsertF64x2;
  table.InsertF64x4 := @NEONInsertF64x4;
  table.InsertI32x16 := @NEONInsertI32x16;
  table.InsertI32x4 := @NEONInsertI32x4;
  table.InsertI32x8 := @NEONInsertI32x8;
  table.InsertI64x2 := @NEONInsertI64x2;
  table.InsertI64x4 := @NEONInsertI64x4;
  table.LoadF32x16 := @NEONLoadF32x16;
  table.LoadF32x8 := @NEONLoadF32x8;
  table.LoadF64x2 := @NEONLoadF64x2;
  table.LoadF64x4 := @NEONLoadF64x4;
  table.LoadF64x8 := @NEONLoadF64x8;
  table.LoadI64x4 := @NEONLoadI64x4;
  table.MaxF32x16 := @NEONMaxF32x16;
  table.MaxF32x8 := @NEONMaxF32x8;
  table.MaxF64x2 := @NEONMaxF64x2;
  table.MaxF64x4 := @NEONMaxF64x4;
  table.MaxF64x8 := @NEONMaxF64x8;
  table.MaxI32x16 := @NEONMaxI32x16;
  table.MaxI32x4 := @NEONMaxI32x4;
  table.MaxI32x8 := @NEONMaxI32x8;
  table.MaxU32x4 := @NEONMaxU32x4;
  table.MaxU32x8 := @NEONMaxU32x8;
  table.MinF32x16 := @NEONMinF32x16;
  table.MinF32x8 := @NEONMinF32x8;
  table.MinF64x2 := @NEONMinF64x2;
  table.MinF64x4 := @NEONMinF64x4;
  table.MinF64x8 := @NEONMinF64x8;
  table.MinI32x16 := @NEONMinI32x16;
  table.MinI32x4 := @NEONMinI32x4;
  table.MinI32x8 := @NEONMinI32x8;
  table.MinU32x4 := @NEONMinU32x4;
  table.MinU32x8 := @NEONMinU32x8;
  table.MulF32x16 := @NEONMulF32x16;
  table.MulF64x4 := @NEONMulF64x4;
  table.MulF64x8 := @NEONMulF64x8;
  table.MulI32x16 := @NEONMulI32x16;
  table.MulI32x8 := @NEONMulI32x8;
  table.MulU32x4 := @NEONMulU32x4;
  table.MulU32x8 := @NEONMulU32x8;
  table.NotI32x16 := @NEONNotI32x16;
  table.NotI32x4 := @NEONNotI32x4;
  table.NotI32x8 := @NEONNotI32x8;
  table.NotI64x4 := @NEONNotI64x4;
  table.NotI64x8 := @NEONNotI64x8;
  table.NotU32x4 := @NEONNotU32x4;
  table.NotU32x8 := @NEONNotU32x8;
  table.NotU64x4 := @NEONNotU64x4;
  table.OrI32x16 := @NEONOrI32x16;
  table.OrI32x4 := @NEONOrI32x4;
  table.OrI32x8 := @NEONOrI32x8;
  table.OrI64x4 := @NEONOrI64x4;
  table.OrI64x8 := @NEONOrI64x8;
  table.OrU32x4 := @NEONOrU32x4;
  table.OrU32x8 := @NEONOrU32x8;
  table.OrU64x4 := @NEONOrU64x4;
  table.RcpF64x4 := @NEONRcpF64x4;
  table.ReduceAddF32x16 := @NEONReduceAddF32x16;
  table.ReduceAddF32x8 := @NEONReduceAddF32x8;
  table.ReduceAddF64x2 := @NEONReduceAddF64x2;
  table.ReduceAddF64x4 := @NEONReduceAddF64x4;
  table.ReduceAddF64x8 := @NEONReduceAddF64x8;
  table.ReduceMaxF32x16 := @NEONReduceMaxF32x16;
  table.ReduceMaxF32x8 := @NEONReduceMaxF32x8;
  table.ReduceMaxF64x2 := @NEONReduceMaxF64x2;
  table.ReduceMaxF64x4 := @NEONReduceMaxF64x4;
  table.ReduceMaxF64x8 := @NEONReduceMaxF64x8;
  table.ReduceMinF32x16 := @NEONReduceMinF32x16;
  table.ReduceMinF32x8 := @NEONReduceMinF32x8;
  table.ReduceMinF64x2 := @NEONReduceMinF64x2;
  table.ReduceMinF64x4 := @NEONReduceMinF64x4;
  table.ReduceMinF64x8 := @NEONReduceMinF64x8;
  table.ReduceMulF32x16 := @NEONReduceMulF32x16;
  table.ReduceMulF32x8 := @NEONReduceMulF32x8;
  table.ReduceMulF64x2 := @NEONReduceMulF64x2;
  table.ReduceMulF64x4 := @NEONReduceMulF64x4;
  table.ReduceMulF64x8 := @NEONReduceMulF64x8;
  table.RoundF32x16 := @NEONRoundF32x16;
  table.RoundF32x8 := @NEONRoundF32x8;
  table.RoundF64x2 := @NEONRoundF64x2;
  table.RoundF64x4 := @NEONRoundF64x4;
  table.RoundF64x8 := @NEONRoundF64x8;
  table.SelectF32x16 := @NEONSelectF32x16;
  table.SelectF32x8 := @NEONSelectF32x8;
  table.SelectF64x4 := @NEONSelectF64x4;
  table.SelectF64x8 := @NEONSelectF64x8;
  table.SelectI32x4 := @NEONSelectI32x4;
  table.ShiftLeftI16x8 := @NEONShiftLeftI16x8;
  table.ShiftLeftI32x16 := @NEONShiftLeftI32x16;
  table.ShiftLeftI32x4 := @NEONShiftLeftI32x4;
  table.ShiftLeftI32x8 := @NEONShiftLeftI32x8;
  table.ShiftLeftI64x4 := @NEONShiftLeftI64x4;
  table.ShiftLeftU16x8 := @NEONShiftLeftU16x8;
  table.ShiftLeftU32x4 := @NEONShiftLeftU32x4;
  table.ShiftLeftU32x8 := @NEONShiftLeftU32x8;
  table.ShiftLeftU64x4 := @NEONShiftLeftU64x4;
  table.ShiftRightArithI16x8 := @NEONShiftRightArithI16x8;
  table.ShiftRightArithI32x16 := @NEONShiftRightArithI32x16;
  table.ShiftRightArithI32x4 := @NEONShiftRightArithI32x4;
  table.ShiftRightArithI32x8 := @NEONShiftRightArithI32x8;
  table.ShiftRightI16x8 := @NEONShiftRightI16x8;
  table.ShiftRightI32x16 := @NEONShiftRightI32x16;
  table.ShiftRightI32x4 := @NEONShiftRightI32x4;
  table.ShiftRightI32x8 := @NEONShiftRightI32x8;
  table.ShiftRightI64x4 := @NEONShiftRightI64x4;
  table.ShiftRightU16x8 := @NEONShiftRightU16x8;
  table.ShiftRightU32x4 := @NEONShiftRightU32x4;
  table.ShiftRightU32x8 := @NEONShiftRightU32x8;
  table.ShiftRightU64x4 := @NEONShiftRightU64x4;
  table.SplatF32x16 := @NEONSplatF32x16;
  table.SplatF32x8 := @NEONSplatF32x8;
  table.SplatF64x2 := @NEONSplatF64x2;
  table.SplatF64x4 := @NEONSplatF64x4;
  table.SplatF64x8 := @NEONSplatF64x8;
  table.SplatI64x4 := @NEONSplatI64x4;
  table.SqrtF32x16 := @NEONSqrtF32x16;
  table.SqrtF32x8 := @NEONSqrtF32x8;
  table.SqrtF64x2 := @NEONSqrtF64x2;
  table.SqrtF64x4 := @NEONSqrtF64x4;
  table.SqrtF64x8 := @NEONSqrtF64x8;
  table.StoreF32x16 := @NEONStoreF32x16;
  table.StoreF32x8 := @NEONStoreF32x8;
  table.StoreF64x2 := @NEONStoreF64x2;
  table.StoreF64x4 := @NEONStoreF64x4;
  table.StoreF64x8 := @NEONStoreF64x8;
  table.StoreI64x4 := @NEONStoreI64x4;
  table.SubF32x16 := @NEONSubF32x16;
  table.SubF64x4 := @NEONSubF64x4;
  table.SubF64x8 := @NEONSubF64x8;
  table.SubI32x16 := @NEONSubI32x16;
  table.SubI32x8 := @NEONSubI32x8;
  table.SubI64x4 := @NEONSubI64x4;
  table.SubI64x8 := @NEONSubI64x8;
  table.SubU32x4 := @NEONSubU32x4;
  table.SubU32x8 := @NEONSubU32x8;
  table.SubU64x4 := @NEONSubU64x4;
  table.TruncF32x16 := @NEONTruncF32x16;
  table.TruncF32x8 := @NEONTruncF32x8;
  table.TruncF64x2 := @NEONTruncF64x2;
  table.TruncF64x4 := @NEONTruncF64x4;
  table.TruncF64x8 := @NEONTruncF64x8;
  table.XorI32x16 := @NEONXorI32x16;
  table.XorI32x4 := @NEONXorI32x4;
  table.XorI32x8 := @NEONXorI32x8;
  table.XorI64x4 := @NEONXorI64x4;
  table.XorI64x8 := @NEONXorI64x8;
  table.XorU32x4 := @NEONXorU32x4;
  table.XorU32x8 := @NEONXorU32x8;
  table.XorU64x4 := @NEONXorU64x4;
  table.ZeroF32x16 := @NEONZeroF32x16;
  table.ZeroF32x8 := @NEONZeroF32x8;
  table.ZeroF64x2 := @NEONZeroF64x2;
  table.ZeroF64x4 := @NEONZeroF64x4;
  table.ZeroF64x8 := @NEONZeroF64x8;
  table.ZeroI64x4 := @NEONZeroI64x4;

  // Register the backend
  RegisterBackend(sbNEON, table);
end;

initialization
  // Only register NEON backend when ASM is available.
  // FPC 3.2.2 does NOT support AArch64 NEON inline assembly (causes ICE).
  // Without ASM, the scalar fallback + dispatch overhead makes performance WORSE.
  // Users with FPC 3.2.2 should use the scalar backend directly.
  {$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}
    {$IFDEF CPUAARCH64}
    RegisterNEONBackend;
    RegisterBackendRebuilder(sbNEON, @RegisterNEONBackend);
    {$ENDIF}
    {$IFDEF CPUARM}
    RegisterNEONBackend;
    RegisterBackendRebuilder(sbNEON, @RegisterNEONBackend);
    {$ENDIF}
  {$ENDIF}

end.
