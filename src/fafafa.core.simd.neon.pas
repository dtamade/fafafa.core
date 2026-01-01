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
  fafafa.core.math,
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

  // Horizontal sum (avoid faddp)
  ext   v1.16b, v0.16b, v0.16b, #8
  fadd  v0.4s, v0.4s, v1.4s
  ext   v1.16b, v0.16b, v0.16b, #4
  fadd  v0.4s, v0.4s, v1.4s
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
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := a.f[i] + b.f[i];
end;

function NEONSubF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := a.f[i] - b.f[i];
end;

function NEONMulF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := a.f[i] * b.f[i];
end;

function NEONDivF32x8(const a, b: TVecF32x8): TVecF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result.f[i] := a.f[i] / b.f[i];
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

// ✅ P4: SelectF64x2 (Scalar Fallback)
function NEONSelectF64x2(const mask: TMask2; const a, b: TVecF64x2): TVecF64x2;
begin
  Result := ScalarSelectF64x2(mask, a, b);
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
