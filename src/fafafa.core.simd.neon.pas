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
// NOTE:
// FPC 3.2.2 on AArch64 can hit an internal compiler error when compiling large
// amounts of inline NEON assembler. Keep these implementations opt-in.
// Enable via: -dFAFAFA_SIMD_NEON_ASM (and ensure SIMD_VECTOR_ASM_DISABLED is NOT defined).
{$IFDEF CPUAARCH64}
  {$IFDEF FAFAFA_SIMD_NEON_ASM}
    // FPC 3.2.2 has reproducible internal errors on AArch64 NEON inline asm (e.g. "ldr q0, [x0]").
    // Require a newer compiler for the opt-in asm path to avoid ICEs.
    {$IFDEF FPC}
      {$IF FPC_FULLVERSION < 030301}
        {$MESSAGE FATAL 'FAFAFA_SIMD_NEON_ASM requires FPC >= 3.3.1 (3.2.2 ICE on AArch64 NEON inline asm)'}
      {$ENDIF}
    {$ENDIF}
    {$IFNDEF SIMD_VECTOR_ASM_DISABLED}
      {$DEFINE FAFAFA_SIMD_NEON_ASM_ENABLED}
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

// === Facade Functions with NEON ===

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
  ldr   q0, [x0], #16
  ldr   q1, [x1], #16
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

  ldr   q0, [x0], #16
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

  ldr   q1, [x0], #16
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
  ldr   q1, [x0]
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

procedure MinMaxBytes_NEON(p: Pointer; len: SizeUInt; out minVal, maxVal: Byte);
begin
  MinMaxBytes_Scalar(p, len, minVal, maxVal);
end;

function Utf8Validate_NEON(p: Pointer; len: SizeUInt): Boolean;
begin
  Result := Utf8Validate_Scalar(p, len);
end;

function AsciiIEqual_NEON(a, b: Pointer; len: SizeUInt): Boolean;
begin
  Result := AsciiIEqual_Scalar(a, b, len);
end;

procedure ToLowerAscii_NEON(p: Pointer; len: SizeUInt);
begin
  ToLowerAscii_Scalar(p, len);
end;

procedure ToUpperAscii_NEON(p: Pointer; len: SizeUInt);
begin
  ToUpperAscii_Scalar(p, len);
end;

function BytesIndexOf_NEON(haystack: Pointer; haystackLen: SizeUInt; needle: Pointer; needleLen: SizeUInt): PtrInt;
begin
  Result := BytesIndexOf_Scalar(haystack, haystackLen, needle, needleLen);
end;

function BitsetPopCount_NEON(p: Pointer; byteLen: SizeUInt): SizeUInt;
begin
  Result := BitsetPopCount_Scalar(p, byteLen);
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

  // Register the backend
  RegisterBackend(sbNEON, table);
end;

initialization
  {$IFDEF CPUAARCH64}
  // Auto-register on AArch64 platforms
  RegisterNEONBackend;
  // ✅ P1-D: Register rebuilder callback for VectorAsmEnabled changes
  RegisterBackendRebuilder(sbNEON, @RegisterNEONBackend);
  {$ENDIF}
  {$IFDEF CPUARM}
  // Also register on 32-bit ARM with NEON support
  // Note: May need runtime detection for older ARMv6 without NEON
  RegisterNEONBackend;
  // ✅ P1-D: Register rebuilder callback for VectorAsmEnabled changes
  RegisterBackendRebuilder(sbNEON, @RegisterNEONBackend);
  {$ENDIF}

end.
