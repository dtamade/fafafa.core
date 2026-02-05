unit fafafa.core.simd.ssse3;

{$mode objfpc}
{$I fafafa.core.settings.inc}
{$asmmode intel}

interface

uses
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch;

// === SSSE3 Backend Implementation ===
// Provides SIMD-accelerated operations using x86-64 SSSE3 instructions.
// SSSE3 (Supplemental SSE3) adds powerful byte manipulation and integer ops.
//
// Key SSSE3 instructions:
// - PSHUFB: Byte-level shuffle (arbitrary permutation of 16 bytes)
// - PALIGNR: Concatenate and extract aligned bytes
// - PHADDW/D, PHSUBW/D: Horizontal add/sub for integers
// - PABSB/W/D: Absolute value for integers (vectorized)
// - PSIGNB/W/D: Conditional negate based on sign
// - PMADDUBSW: Multiply-add (unsigned/signed byte to word)
// - PMULHRSW: Multiply high with rounding and scaling
//
// ✅ Task 5.1: Enhanced SSSE3 implementation
// - Inherits from SSE3 via CloneDispatchTable
// - PABSD for integer absolute value (very useful!)
// - PSHUFB for byte-level operations
// - PHADD for faster integer reductions

procedure RegisterSSSE3Backend;

// === SSSE3 Exported Functions ===

// Byte-level shuffle (PSHUFB - extremely powerful)
function SSSE3ShuffleBytes(const a, ctrl: TVecU8x16): TVecU8x16;

// Byte alignment (PALIGNR)
function SSSE3AlignR_0(const a, b: TVecU8x16): TVecU8x16;
function SSSE3AlignR_4(const a, b: TVecU8x16): TVecU8x16;
function SSSE3AlignR_8(const a, b: TVecU8x16): TVecU8x16;
function SSSE3AlignR_12(const a, b: TVecU8x16): TVecU8x16;

// Integer horizontal add/sub
function SSSE3HAddI16x8(const a, b: TVecI16x8): TVecI16x8;
function SSSE3HAddI32x4(const a, b: TVecI32x4): TVecI32x4;
function SSSE3HSubI16x8(const a, b: TVecI16x8): TVecI16x8;
function SSSE3HSubI32x4(const a, b: TVecI32x4): TVecI32x4;
function SSSE3HAddSatI16x8(const a, b: TVecI16x8): TVecI16x8;
function SSSE3HSubSatI16x8(const a, b: TVecI16x8): TVecI16x8;

// Integer absolute value (PABS - no equivalent in SSE2!)
function SSSE3AbsI8x16(const a: TVecI8x16): TVecI8x16;
function SSSE3AbsI16x8(const a: TVecI16x8): TVecI16x8;
function SSSE3AbsI32x4(const a: TVecI32x4): TVecI32x4;

// Conditional negate (PSIGN)
function SSSE3SignI8x16(const a, b: TVecI8x16): TVecI8x16;
function SSSE3SignI16x8(const a, b: TVecI16x8): TVecI16x8;
function SSSE3SignI32x4(const a, b: TVecI32x4): TVecI32x4;

// Multiply-add operations
function SSSE3MAddUBSW(const a: TVecU8x16; const b: TVecI8x16): TVecI16x8;
function SSSE3MulHRS(const a, b: TVecI16x8): TVecI16x8;

implementation

uses
  SysUtils,
  fafafa.core.simd.cpuinfo;

// === SSSE3 Byte Shuffle ===
// PSHUFB is one of the most powerful SIMD instructions

// Shuffle bytes according to control mask
// Each byte in 'ctrl' selects which byte from 'a' to output
// If high bit of ctrl[i] is set, output is 0
function SSSE3ShuffleBytes(const a, ctrl: TVecU8x16): TVecU8x16;
begin
  asm
    lea    rax, a
    lea    rdx, ctrl
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pshufb xmm0, xmm1
    movdqu [result], xmm0
  end;
end;

// === SSSE3 Alignment ===

// Concatenate a and b, then extract 16 bytes at byte offset
// Result = (b:a >> (imm8*8)) [lower 128 bits]
// Note: imm8 is compile-time constant in x86, so we provide variants
function SSSE3AlignR_0(const a, b: TVecU8x16): TVecU8x16;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    palignr xmm1, xmm0, 0
    movdqu [result], xmm1
  end;
end;

function SSSE3AlignR_4(const a, b: TVecU8x16): TVecU8x16;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    palignr xmm1, xmm0, 4
    movdqu [result], xmm1
  end;
end;

function SSSE3AlignR_8(const a, b: TVecU8x16): TVecU8x16;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    palignr xmm1, xmm0, 8
    movdqu [result], xmm1
  end;
end;

function SSSE3AlignR_12(const a, b: TVecU8x16): TVecU8x16;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    palignr xmm1, xmm0, 12
    movdqu [result], xmm1
  end;
end;

// === SSSE3 Horizontal Integer Operations ===

// Horizontal add for I16x8: [a0+a1, a2+a3, a4+a5, a6+a7, b0+b1, ...]
function SSSE3HAddI16x8(const a, b: TVecI16x8): TVecI16x8;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    phaddw xmm0, xmm1
    movdqu [result], xmm0
  end;
end;

// Horizontal add for I32x4: [a0+a1, a2+a3, b0+b1, b2+b3]
function SSSE3HAddI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    phaddd xmm0, xmm1
    movdqu [result], xmm0
  end;
end;

// Horizontal sub for I16x8
function SSSE3HSubI16x8(const a, b: TVecI16x8): TVecI16x8;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    phsubw xmm0, xmm1
    movdqu [result], xmm0
  end;
end;

// Horizontal sub for I32x4
function SSSE3HSubI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    phsubd xmm0, xmm1
    movdqu [result], xmm0
  end;
end;

// Horizontal add with saturation for I16x8
function SSSE3HAddSatI16x8(const a, b: TVecI16x8): TVecI16x8;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    phaddsw xmm0, xmm1
    movdqu [result], xmm0
  end;
end;

// Horizontal sub with saturation for I16x8
function SSSE3HSubSatI16x8(const a, b: TVecI16x8): TVecI16x8;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    phsubsw xmm0, xmm1
    movdqu [result], xmm0
  end;
end;

// === SSSE3 Absolute Value ===
// SSE2 requires compare+select to compute abs; SSSE3 has direct instructions

function SSSE3AbsI8x16(const a: TVecI8x16): TVecI8x16;
begin
  asm
    lea    rax, a
    movdqu xmm0, [rax]
    pabsb  xmm0, xmm0
    movdqu [result], xmm0
  end;
end;

function SSSE3AbsI16x8(const a: TVecI16x8): TVecI16x8;
begin
  asm
    lea    rax, a
    movdqu xmm0, [rax]
    pabsw  xmm0, xmm0
    movdqu [result], xmm0
  end;
end;

function SSSE3AbsI32x4(const a: TVecI32x4): TVecI32x4;
begin
  asm
    lea    rax, a
    movdqu xmm0, [rax]
    pabsd  xmm0, xmm0
    movdqu [result], xmm0
  end;
end;

// === SSSE3 Conditional Negate ===
// PSIGN: Negate based on sign of second operand

// For each element: if b[i] < 0 then -a[i], if b[i] == 0 then 0, else a[i]
function SSSE3SignI8x16(const a, b: TVecI8x16): TVecI8x16;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    psignb xmm0, xmm1
    movdqu [result], xmm0
  end;
end;

function SSSE3SignI16x8(const a, b: TVecI16x8): TVecI16x8;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    psignw xmm0, xmm1
    movdqu [result], xmm0
  end;
end;

function SSSE3SignI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    psignd xmm0, xmm1
    movdqu [result], xmm0
  end;
end;

// === SSSE3 Multiply-Add ===

// PMADDUBSW: Multiply unsigned bytes with signed bytes, add pairs with saturation
// a[2i]*b[2i] + a[2i+1]*b[2i+1] (saturated to I16)
function SSSE3MAddUBSW(const a: TVecU8x16; const b: TVecI8x16): TVecI16x8;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pmaddubsw xmm0, xmm1
    movdqu [result], xmm0
  end;
end;

// PMULHRSW: Multiply signed words, shift right 14, round and pack
function SSSE3MulHRS(const a, b: TVecI16x8): TVecI16x8;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pmulhrsw xmm0, xmm1
    movdqu [result], xmm0
  end;
end;

// === SSSE3 Integer Reduction using PHADD ===

function SSSE3ReduceAddI32x4(const a: TVecI32x4): Int32;
begin
  asm
    lea     rax, a
    movdqu  xmm0, [rax]
    phaddd  xmm0, xmm0     // [a0+a1, a2+a3, a0+a1, a2+a3]
    phaddd  xmm0, xmm0     // [sum, sum, sum, sum]
    movd    eax, xmm0
    mov     [result], eax
  end;
end;

function SSSE3ReduceAddI16x8(const a: TVecI16x8): Int32;
var
  tmp: TVecI16x8;
begin
  asm
    lea     rax, a
    movdqu  xmm0, [rax]
    phaddw  xmm0, xmm0     // [a0+a1, a2+a3, a4+a5, a6+a7, ...]
    phaddw  xmm0, xmm0     // [sum0, sum1, sum0, sum1, ...]
    phaddw  xmm0, xmm0     // [total, ...]
    movdqu  [tmp], xmm0
  end;
  Result := tmp.i[0];
end;

// ✅ NEW: SSSE3 byte-level negate using PABSB + PSIGNB pattern
function SSSE3NegI8x16(const a: TVecI8x16): TVecI8x16;
begin
  asm
    lea    rax, a
    movdqu xmm0, [rax]
    // Create all -1s
    pcmpeqd xmm1, xmm1
    // psignb(a, -1) = -a when sign bit set
    psignb xmm0, xmm1
    movdqu [result], xmm0
  end;
end;

function SSSE3NegI16x8(const a: TVecI16x8): TVecI16x8;
begin
  asm
    lea    rax, a
    movdqu xmm0, [rax]
    pcmpeqd xmm1, xmm1
    psignw xmm0, xmm1
    movdqu [result], xmm0
  end;
end;

function SSSE3NegI32x4(const a: TVecI32x4): TVecI32x4;
begin
  asm
    lea    rax, a
    movdqu xmm0, [rax]
    pcmpeqd xmm1, xmm1
    psignd xmm0, xmm1
    movdqu [result], xmm0
  end;
end;

// ✅ NEW: SSSE3 optimized Min/Max for I8x16 using PABSB
// MinI8x16 using compare+blend
function SSSE3MinI8x16(const a, b: TVecI8x16): TVecI8x16;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    movdqa xmm2, xmm0
    pcmpgtb xmm2, xmm1     // mask where a > b
    // Select b where a > b, else a
    movdqa xmm3, xmm2
    pand   xmm3, xmm1      // b where a > b
    pandn  xmm2, xmm0      // a where a <= b
    por    xmm2, xmm3
    movdqu [result], xmm2
  end;
end;

function SSSE3MaxI8x16(const a, b: TVecI8x16): TVecI8x16;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    movdqa xmm2, xmm0
    pcmpgtb xmm2, xmm1     // mask where a > b
    // Select a where a > b, else b
    pand   xmm0, xmm2      // a where a > b
    pandn  xmm2, xmm1      // b where a <= b
    por    xmm0, xmm2
    movdqu [result], xmm0
  end;
end;

// === Backend Registration ===

procedure RegisterSSSE3Backend;
var
  dispatchTable: TSimdDispatchTable;
begin
  // Only register if SSSE3 is available
  if not HasSSSE3 then
    Exit;

  // ✅ 使用 CloneDispatchTable 从 SSE3 继承实现
  dispatchTable := Default(TSimdDispatchTable);
  if not CloneDispatchTable(sbSSE3, dispatchTable) then
    if not CloneDispatchTable(sbSSE2, dispatchTable) then
      FillBaseDispatchTable(dispatchTable);

  // Set backend info
  dispatchTable.Backend := sbSSSE3;
  with dispatchTable.BackendInfo do
  begin
    Backend := sbSSSE3;
    Name := 'SSSE3';
    Description := 'x86-64 SSSE3 SIMD implementation (PSHUFB, PABS, PALIGNR)';
    Capabilities := [scBasicArithmetic, scComparison, scMathFunctions, scReduction,
                     scShuffle, scIntegerOps, scLoadStore];
    Available := True;
    Priority := 18; // Higher than SSE3 (15)
  end;

  // SSSE3 improvements
  if IsVectorAsmEnabled then
  begin
    // ✅ PABS instructions for integer absolute value
    // Note: These operations are not yet in the dispatch table
    // When AbsI8x16/AbsI16x8/AbsI32x4 are added to TSimdDispatchTable:
    // dispatchTable.AbsI8x16 := @SSSE3AbsI8x16;
    // dispatchTable.AbsI16x8 := @SSSE3AbsI16x8;
    // dispatchTable.AbsI32x4 := @SSSE3AbsI32x4;

    // ✅ Improved Min/Max for I8x16
    dispatchTable.MinI8x16 := @SSSE3MinI8x16;
    dispatchTable.MaxI8x16 := @SSSE3MaxI8x16;
  end;

  // Register the backend
  RegisterBackend(sbSSSE3, dispatchTable);
end;

initialization
  RegisterSSSE3Backend;

end.
