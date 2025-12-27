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
  fafafa.core.simd.dispatch,
  fafafa.core.simd.cpuinfo;

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
{$IFDEF CPUAARCH64}

// === F32x4 Arithmetic Operations ===

function NEONAddF32x4(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  // x0 = @a, x1 = @b, x8 = @result (hidden param for struct return)
  ldr   q0, [x0]          // v0 = a
  ldr   q1, [x1]          // v1 = b
  fadd  v0.4s, v0.4s, v1.4s  // v0 = a + b
  str   q0, [x8]          // store result
end;

function NEONSubF32x4(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  ldr   q0, [x0]
  ldr   q1, [x1]
  fsub  v0.4s, v0.4s, v1.4s
  str   q0, [x8]
end;

function NEONMulF32x4(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  ldr   q0, [x0]
  ldr   q1, [x1]
  fmul  v0.4s, v0.4s, v1.4s
  str   q0, [x8]
end;

function NEONDivF32x4(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  ldr   q0, [x0]
  ldr   q1, [x1]
  fdiv  v0.4s, v0.4s, v1.4s
  str   q0, [x8]
end;

// === F64x2 Arithmetic Operations ===

function NEONAddF64x2(const a, b: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  ldr   q0, [x0]
  ldr   q1, [x1]
  fadd  v0.2d, v0.2d, v1.2d
  str   q0, [x8]
end;

function NEONSubF64x2(const a, b: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  ldr   q0, [x0]
  ldr   q1, [x1]
  fsub  v0.2d, v0.2d, v1.2d
  str   q0, [x8]
end;

function NEONMulF64x2(const a, b: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  ldr   q0, [x0]
  ldr   q1, [x1]
  fmul  v0.2d, v0.2d, v1.2d
  str   q0, [x8]
end;

function NEONDivF64x2(const a, b: TVecF64x2): TVecF64x2; assembler; nostackframe;
asm
  ldr   q0, [x0]
  ldr   q1, [x1]
  fdiv  v0.2d, v0.2d, v1.2d
  str   q0, [x8]
end;

// === I32x4 Arithmetic Operations ===

function NEONAddI32x4(const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  ldr   q0, [x0]
  ldr   q1, [x1]
  add   v0.4s, v0.4s, v1.4s
  str   q0, [x8]
end;

function NEONSubI32x4(const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  ldr   q0, [x0]
  ldr   q1, [x1]
  sub   v0.4s, v0.4s, v1.4s
  str   q0, [x8]
end;

function NEONMulI32x4(const a, b: TVecI32x4): TVecI32x4; assembler; nostackframe;
asm
  ldr   q0, [x0]
  ldr   q1, [x1]
  mul   v0.4s, v0.4s, v1.4s
  str   q0, [x8]
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
  ldr   q0, [x0]
  fabs  v0.4s, v0.4s
  str   q0, [x8]
end;

function NEONSqrtF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  ldr   q0, [x0]
  fsqrt v0.4s, v0.4s
  str   q0, [x8]
end;

function NEONMinF32x4(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  ldr   q0, [x0]
  ldr   q1, [x1]
  fmin  v0.4s, v0.4s, v1.4s
  str   q0, [x8]
end;

function NEONMaxF32x4(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  ldr   q0, [x0]
  ldr   q1, [x1]
  fmax  v0.4s, v0.4s, v1.4s
  str   q0, [x8]
end;

// === Extended Math Functions ===

function NEONFmaF32x4(const a, b, c: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  // x0=@a, x1=@b, x2=@c, x8=@result
  ldr   q0, [x0]           // v0 = a
  ldr   q1, [x1]           // v1 = b
  ldr   q2, [x2]           // v2 = c
  fmla  v2.4s, v0.4s, v1.4s  // v2 = a*b + c
  str   q2, [x8]
end;

function NEONRcpF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  ldr   q0, [x0]
  frecpe v0.4s, v0.4s       // Approximate reciprocal
  str   q0, [x8]
end;

function NEONRsqrtF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  ldr   q0, [x0]
  frsqrte v0.4s, v0.4s      // Approximate reciprocal sqrt
  str   q0, [x8]
end;

// === Rounding Operations ===

function NEONFloorF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  ldr   q0, [x0]
  frintm v0.4s, v0.4s       // Round toward -infinity (floor)
  str   q0, [x8]
end;

function NEONCeilF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  ldr   q0, [x0]
  frintp v0.4s, v0.4s       // Round toward +infinity (ceil)
  str   q0, [x8]
end;

function NEONRoundF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  ldr   q0, [x0]
  frintn v0.4s, v0.4s       // Round to nearest, ties to even
  str   q0, [x8]
end;

function NEONTruncF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  ldr   q0, [x0]
  frintz v0.4s, v0.4s       // Round toward zero (truncate)
  str   q0, [x8]
end;

function NEONClampF32x4(const a, minVal, maxVal: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  // x0=@a, x1=@minVal, x2=@maxVal, x8=@result
  ldr   q0, [x0]            // a
  ldr   q1, [x1]            // minVal
  ldr   q2, [x2]            // maxVal
  fmax  v0.4s, v0.4s, v1.4s // max(a, minVal)
  fmin  v0.4s, v0.4s, v2.4s // min(result, maxVal)
  str   q0, [x8]
end;

// === Vector Math Operations ===

function NEONDotF32x4(const a, b: TVecF32x4): Single; assembler; nostackframe;
asm
  ldr   q0, [x0]
  ldr   q1, [x1]
  fmul  v0.4s, v0.4s, v1.4s   // Element-wise multiply
  faddp v0.4s, v0.4s, v0.4s   // Pairwise add: [a*b+c*d, e*f+g*h, ...]
  faddp s0, v0.2s             // Final add
  // Result in s0
end;

function NEONDotF32x3(const a, b: TVecF32x4): Single; assembler; nostackframe;
asm
  ldr   q0, [x0]
  ldr   q1, [x1]
  fmul  v0.4s, v0.4s, v1.4s   // Element-wise multiply
  mov   v0.s[3], wzr          // Zero the w component
  faddp v0.4s, v0.4s, v0.4s
  faddp s0, v0.2s
end;

function NEONCrossF32x3(const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  // Cross product: (a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x, 0)
  ldr   q0, [x0]              // a = [x, y, z, w]
  ldr   q1, [x1]              // b = [x, y, z, w]
  
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
  fsub  v0.4s, v4.4s, v2.4s   // Subtract
  
  // Zero w component
  mov   v0.s[3], wzr
  str   q0, [x8]
end;

function NEONLengthF32x4(const a: TVecF32x4): Single; assembler; nostackframe;
asm
  ldr   q0, [x0]
  fmul  v0.4s, v0.4s, v0.4s   // Square each element
  faddp v0.4s, v0.4s, v0.4s   // Pairwise add
  faddp s0, v0.2s             // Sum all
  fsqrt s0, s0                // Square root
end;

function NEONLengthF32x3(const a: TVecF32x4): Single; assembler; nostackframe;
asm
  ldr   q0, [x0]
  mov   v0.s[3], wzr          // Zero w component
  fmul  v0.4s, v0.4s, v0.4s   // Square each element
  faddp v0.4s, v0.4s, v0.4s
  faddp s0, v0.2s
  fsqrt s0, s0
end;

function NEONNormalizeF32x4(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  ldr   q0, [x0]
  fmul  v1.4s, v0.4s, v0.4s   // Square each element
  faddp v1.4s, v1.4s, v1.4s   // Sum squares
  faddp s1, v1.2s
  fsqrt s1, s1                // length
  
  // Check for zero length
  fcmp  s1, #0.0
  beq   .Lzero_len4
  
  // Reciprocal length and multiply
  fmov  s2, #1.0
  fdiv  s1, s2, s1            // 1/length
  dup   v1.4s, v1.s[0]        // Broadcast
  fmul  v0.4s, v0.4s, v1.4s
  str   q0, [x8]
  ret
  
.Lzero_len4:
  str   q0, [x8]              // Return original if zero length
end;

function NEONNormalizeF32x3(const a: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  ldr   q0, [x0]
  mov   v0.s[3], wzr          // Zero w for calculation
  fmul  v1.4s, v0.4s, v0.4s
  faddp v1.4s, v1.4s, v1.4s
  faddp s1, v1.2s
  fsqrt s1, s1
  
  fcmp  s1, #0.0
  beq   .Lzero_len3
  
  fmov  s2, #1.0
  fdiv  s1, s2, s1
  dup   v1.4s, v1.s[0]
  ldr   q0, [x0]              // Reload original
  fmul  v0.4s, v0.4s, v1.4s
  mov   v0.s[3], wzr          // Ensure w=0
  str   q0, [x8]
  ret
  
.Lzero_len3:
  ldr   q0, [x0]
  mov   v0.s[3], wzr
  str   q0, [x8]
end;

// === Selection Operation ===

function NEONSelectF32x4(const mask: TMask4; const a, b: TVecF32x4): TVecF32x4; assembler; nostackframe;
asm
  // w0 = mask (4-bit), x1 = @a, x2 = @b, x8 = @result
  ldr   q0, [x1]              // a
  ldr   q1, [x2]              // b
  
  // Expand 4-bit mask to 128-bit mask
  // Each bit becomes 32 bits of all 1s or all 0s
  movi  v2.4s, #0
  
  // Bit 0
  tst   w0, #1
  beq   .Lbit0_zero
  movi  v3.4s, #0xFF
  ins   v2.s[0], v3.s[0]
.Lbit0_zero:
  
  // Bit 1
  tst   w0, #2
  beq   .Lbit1_zero
  movi  v3.4s, #0xFF
  ins   v2.s[1], v3.s[0]
.Lbit1_zero:
  
  // Bit 2
  tst   w0, #4
  beq   .Lbit2_zero
  movi  v3.4s, #0xFF
  ins   v2.s[2], v3.s[0]
.Lbit2_zero:
  
  // Bit 3
  tst   w0, #8
  beq   .Lbit3_zero
  movi  v3.4s, #0xFF
  ins   v2.s[3], v3.s[0]
.Lbit3_zero:
  
  // BSL: bit select - result = (a AND mask) OR (b AND NOT mask)
  bsl   v2.16b, v0.16b, v1.16b
  str   q2, [x8]
end;

function NEONInsertF32x4(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4; assembler; nostackframe;
asm
  // x0 = @a, s0 = value (in FP reg), w1 = index, x8 = @result
  ldr   q1, [x0]              // Load a into v1
  and   w1, w1, #3            // index & 3
  
  cbz   w1, .Lins0
  cmp   w1, #1
  beq   .Lins1
  cmp   w1, #2
  beq   .Lins2
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
  str   q1, [x8]
end;

// === Reduction Operations ===

function NEONReduceAddF32x4(const a: TVecF32x4): Single; assembler; nostackframe;
asm
  ldr   q0, [x0]
  faddp v0.4s, v0.4s, v0.4s  // Pairwise add: [a+b, c+d, a+b, c+d]
  faddp s0, v0.2s            // Final add: a+b+c+d
  // Result in s0 (v0.s[0]), returned via FP reg
end;

function NEONReduceMinF32x4(const a: TVecF32x4): Single; assembler; nostackframe;
asm
  ldr   q0, [x0]
  fminp v0.4s, v0.4s, v0.4s  // Pairwise min
  fminp s0, v0.2s
end;

function NEONReduceMaxF32x4(const a: TVecF32x4): Single; assembler; nostackframe;
asm
  ldr   q0, [x0]
  fmaxp v0.4s, v0.4s, v0.4s  // Pairwise max
  fmaxp s0, v0.2s
end;

function NEONReduceMulF32x4(const a: TVecF32x4): Single; assembler; nostackframe;
asm
  ldr   q0, [x0]
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
  ldr   q0, [x0]
  str   q0, [x8]
end;

function NEONLoadF32x4Aligned(p: PSingle): TVecF32x4; assembler; nostackframe;
asm
  ldr   q0, [x0]
  str   q0, [x8]
end;

procedure NEONStoreF32x4(p: PSingle; const a: TVecF32x4); assembler; nostackframe;
asm
  // x0 = p, x1 = @a
  ldr   q0, [x1]
  str   q0, [x0]
end;

procedure NEONStoreF32x4Aligned(p: PSingle; const a: TVecF32x4); assembler; nostackframe;
asm
  ldr   q0, [x1]
  str   q0, [x0]
end;

// === Utility Operations ===

function NEONSplatF32x4(value: Single): TVecF32x4; assembler; nostackframe;
asm
  // s0 = value (passed in FP reg)
  dup   v0.4s, v0.s[0]      // Duplicate to all lanes
  str   q0, [x8]
end;

function NEONZeroF32x4: TVecF32x4; assembler; nostackframe;
asm
  movi  v0.4s, #0
  str   q0, [x8]
end;

function NEONExtractF32x4(const a: TVecF32x4; index: Integer): Single; assembler; nostackframe;
asm
  // x0 = @a, w1 = index (lower 32 bits of x1)
  ldr   q0, [x0]
  and   w1, w1, #3          // index & 3
  // Use index to extract - need computed branch or table
  cbz   w1, .L0
  cmp   w1, #1
  beq   .L1
  cmp   w1, #2
  beq   .L2
  // else index=3
  mov   s0, v0.s[3]
  ret
.L0:
  // s0 already has v0.s[0]
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
  ldr   q0, [x0]
  ldr   q1, [x1]
  fcmeq v0.4s, v0.4s, v1.4s  // Compare equal, all 1s if true
  // Extract mask: shrink to bytes and extract
  xtn   v0.4h, v0.4s         // Narrow 32->16 bits
  xtn   v0.8b, v0.8h         // Narrow 16->8 bits
  umov  w0, v0.b[0]          // Get byte 0
  umov  w1, v0.b[1]
  umov  w2, v0.b[2]
  umov  w3, v0.b[3]
  and   w0, w0, #1
  orr   w0, w0, w1, lsl #1
  orr   w0, w0, w2, lsl #2
  orr   w0, w0, w3, lsl #3
end;

function NEONCmpLtF32x4(const a, b: TVecF32x4): TMask4; assembler; nostackframe;
asm
  ldr   q0, [x0]
  ldr   q1, [x1]
  fcmlt v0.4s, v0.4s, v1.4s
  xtn   v0.4h, v0.4s
  xtn   v0.8b, v0.8h
  umov  w0, v0.b[0]
  umov  w1, v0.b[1]
  umov  w2, v0.b[2]
  umov  w3, v0.b[3]
  and   w0, w0, #1
  orr   w0, w0, w1, lsl #1
  orr   w0, w0, w2, lsl #2
  orr   w0, w0, w3, lsl #3
end;

function NEONCmpLeF32x4(const a, b: TVecF32x4): TMask4; assembler; nostackframe;
asm
  ldr   q0, [x0]
  ldr   q1, [x1]
  fcmle v0.4s, v0.4s, v1.4s
  xtn   v0.4h, v0.4s
  xtn   v0.8b, v0.8h
  umov  w0, v0.b[0]
  umov  w1, v0.b[1]
  umov  w2, v0.b[2]
  umov  w3, v0.b[3]
  and   w0, w0, #1
  orr   w0, w0, w1, lsl #1
  orr   w0, w0, w2, lsl #2
  orr   w0, w0, w3, lsl #3
end;

function NEONCmpGtF32x4(const a, b: TVecF32x4): TMask4; assembler; nostackframe;
asm
  ldr   q0, [x0]
  ldr   q1, [x1]
  fcmgt v0.4s, v0.4s, v1.4s
  xtn   v0.4h, v0.4s
  xtn   v0.8b, v0.8h
  umov  w0, v0.b[0]
  umov  w1, v0.b[1]
  umov  w2, v0.b[2]
  umov  w3, v0.b[3]
  and   w0, w0, #1
  orr   w0, w0, w1, lsl #1
  orr   w0, w0, w2, lsl #2
  orr   w0, w0, w3, lsl #3
end;

function NEONCmpGeF32x4(const a, b: TVecF32x4): TMask4; assembler; nostackframe;
asm
  ldr   q0, [x0]
  ldr   q1, [x1]
  fcmge v0.4s, v0.4s, v1.4s
  xtn   v0.4h, v0.4s
  xtn   v0.8b, v0.8h
  umov  w0, v0.b[0]
  umov  w1, v0.b[1]
  umov  w2, v0.b[2]
  umov  w3, v0.b[3]
  and   w0, w0, #1
  orr   w0, w0, w1, lsl #1
  orr   w0, w0, w2, lsl #2
  orr   w0, w0, w3, lsl #3
end;

function NEONCmpNeF32x4(const a, b: TVecF32x4): TMask4; assembler; nostackframe;
asm
  ldr   q0, [x0]
  ldr   q1, [x1]
  fcmeq v0.4s, v0.4s, v1.4s  // Equal
  not   v0.16b, v0.16b       // Invert for not-equal
  xtn   v0.4h, v0.4s
  xtn   v0.8b, v0.8h
  umov  w0, v0.b[0]
  umov  w1, v0.b[1]
  umov  w2, v0.b[2]
  umov  w3, v0.b[3]
  and   w0, w0, #1
  orr   w0, w0, w1, lsl #1
  orr   w0, w0, w2, lsl #2
  orr   w0, w0, w3, lsl #3
end;

// === Facade Functions with NEON ===

function MemEqual_NEON(a, b: Pointer; len: SizeUInt): LongBool; assembler; nostackframe;
asm
  // x0 = a, x1 = b, x2 = len
  cbz   x2, .Lequal          // len == 0, return true
  
  // Process 16 bytes at a time
.Lloop16:
  cmp   x2, #16
  blo   .Ltail
  ldr   q0, [x0], #16
  ldr   q1, [x1], #16
  cmeq  v0.16b, v0.16b, v1.16b
  // Check if all bytes equal (all 1s)
  uminv b2, v0.16b           // Min of all bytes
  umov  w3, v2.b[0]
  cmp   w3, #255
  bne   .Lnotequal
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
  bne   .Lnotequal
  subs  x2, x2, #1
  bne   .Ltailloop
  
.Lequal:
  mov   w0, #1
  ret
  
.Lnotequal:
  mov   w0, #0
end;

function SumBytes_NEON(p: Pointer; len: SizeUInt): UInt64; assembler; nostackframe;
asm
  // x0 = p, x1 = len
  movi  v0.16b, #0           // Accumulator (16 bytes)
  movi  v1.2d, #0            // 64-bit accumulator
  cbz   x1, .Ldone
  
.Lloop16:
  cmp   x1, #16
  blo   .Ltail
  ldr   q2, [x0], #16
  uaddlp v2.8h, v2.16b       // Pairwise add bytes -> 8 x 16-bit
  uaddlp v2.4s, v2.8h        // -> 4 x 32-bit
  uaddlp v2.2d, v2.4s        // -> 2 x 64-bit
  add   v1.2d, v1.2d, v2.2d
  sub   x1, x1, #16
  cbnz  x1, .Lloop16
  b     .Lfinal
  
.Ltail:
  cbz   x1, .Lfinal
.Ltailloop:
  ldrb  w2, [x0], #1
  add   x3, x3, x2
  subs  x1, x1, #1
  bne   .Ltailloop
  // Add tail sum to vector
  dup   v2.2d, x3
  add   v1.2d, v1.2d, v2.2d
  
.Lfinal:
  addp  d0, v1.2d            // Add two 64-bit lanes
  fmov  x0, d0               // Move to GP reg for return
  
.Ldone:
end;

function CountByte_NEON(p: Pointer; len: SizeUInt; value: Byte): SizeUInt; assembler; nostackframe;
asm
  // x0 = p, x1 = len, w2 = value
  dup   v0.16b, w2           // Broadcast search value
  movi  v1.2d, #0            // Count accumulator
  cbz   x1, .Ldone
  
.Lloop16:
  cmp   x1, #16
  blo   .Ltail
  ldr   q2, [x0], #16
  cmeq  v2.16b, v2.16b, v0.16b  // Compare (0xFF for match)
  // Count matches: each match is 0xFF = -1, so negate and add
  cnt   v2.16b, v2.16b       // Count bits in each byte (8 for match)
  uaddlp v2.8h, v2.16b       // Pairwise add
  uaddlp v2.4s, v2.8h
  uaddlp v2.2d, v2.4s
  // Divide by 8 since we counted bits
  ushr  v2.2d, v2.2d, #3
  add   v1.2d, v1.2d, v2.2d
  sub   x1, x1, #16
  cbnz  x1, .Lloop16
  b     .Lfinal
  
.Ltail:
  cbz   x1, .Lfinal
  mov   x3, #0
.Ltailloop:
  ldrb  w4, [x0], #1
  cmp   w4, w2
  cinc  x3, x3, eq
  subs  x1, x1, #1
  bne   .Ltailloop
  dup   v2.2d, x3
  add   v1.2d, v1.2d, v2.2d
  
.Lfinal:
  addp  d0, v1.2d
  fmov  x0, d0
  
.Ldone:
end;

function MemFindByte_NEON(p: Pointer; len: SizeUInt; value: Byte): PtrInt; assembler; nostackframe;
asm
  // x0 = p, x1 = len, w2 = value
  mov   x3, x0               // Save original pointer
  dup   v0.16b, w2           // Broadcast search value
  cbz   x1, .Lnotfound
  
.Lloop16:
  cmp   x1, #16
  blo   .Ltail
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
  blo   .Lscan
  
.Lfoundexact:
  add   x0, x0, x5
  sub   x0, x0, x3           // Return offset
  ret
  
.Ltail:
  cbz   x1, .Lnotfound
.Ltailloop:
  ldrb  w4, [x0]
  cmp   w4, w2
  beq   .Lfoundtail
  add   x0, x0, #1
  subs  x1, x1, #1
  bne   .Ltailloop
  b     .Lnotfound
  
.Lfoundtail:
  sub   x0, x0, x3
  ret
  
.Lnotfound:
  mov   x0, #-1
end;

{$ELSE}
// === Scalar Fallback for non-AArch64 platforms ===

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
begin
  Result := a.f[index and 3];
end;

function NEONInsertF32x4(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4;
begin
  Result := a;
  Result.f[index and 3] := value;
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

{$ENDIF} // CPUAARCH64

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
  // ✅ 运行时检测：如果 CPU 不支持 NEON，则不注册后端
  if not HasNEON then
    Exit;

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
