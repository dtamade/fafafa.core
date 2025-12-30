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

procedure RegisterSSSE3Backend;

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

// === Backend Registration ===

procedure RegisterSSSE3Backend;
var
  dispatchTable: TSimdDispatchTable;
begin
  // Only register if SSSE3 is available
  if not HasSSSE3 then
    Exit;

  // ✅ 修复 P0-1: 从 SSE3 继承实现（SSSE3 是 SSE3 的超集）
  dispatchTable := Default(TSimdDispatchTable);

  // Set backend info BEFORE cloning (will be preserved)
  with dispatchTable.BackendInfo do
  begin
    Backend := sbSSSE3;
    Name := 'SSSE3';
    Description := 'x86-64 SSSE3 SIMD implementation (byte shuffle, integer abs)';
    Capabilities := [scBasicArithmetic, scComparison, scMathFunctions, scReduction,
                     scShuffle, scIntegerOps, scLoadStore];
    Available := True;
    Priority := 18; // Higher than SSE3 (15)
  end;

  // Clone from SSE3 backend (inherits SSE3 → SSE2 → all optimizations)
  // Fall back to SSE2 if SSE3 not registered, then to scalar baseline
  if not CloneDispatchTable(sbSSE3, dispatchTable) then
    if not CloneDispatchTable(sbSSE2, dispatchTable) then
      FillBaseDispatchTable(dispatchTable);

  // Update backend identifier
  dispatchTable.Backend := sbSSSE3;

  // SSSE3 improvements: integer absolute value, byte shuffle
  // Note: AbsI8x16/AbsI16x8/AbsI32x4/ReduceAddI32x4 not in dispatch table yet
  // When these are added to TSimdDispatchTable, enable the following:
  // if IsVectorAsmEnabled then
  // begin
  //   dispatchTable.AbsI8x16 := @SSSE3AbsI8x16;
  //   dispatchTable.AbsI16x8 := @SSSE3AbsI16x8;
  //   dispatchTable.AbsI32x4 := @SSSE3AbsI32x4;
  //   dispatchTable.ReduceAddI32x4 := @SSSE3ReduceAddI32x4;
  // end;

  // SSSE3 functions are available for direct use:
  // - SSSE3ShuffleBytes (PSHUFB)
  // - SSSE3AlignR_* (PALIGNR)
  // - SSSE3HAddI16x8/I32x4 (PHADDW/D)
  // - SSSE3AbsI8x16/I16x8/I32x4 (PABSB/W/D)
  // - SSSE3SignI8x16/I16x8/I32x4 (PSIGNB/W/D)
  // - SSSE3MAddUBSW (PMADDUBSW)
  // - SSSE3MulHRS (PMULHRSW)

  // Register the backend
  RegisterBackend(sbSSSE3, dispatchTable);
end;

initialization
  RegisterSSSE3Backend;
  RegisterBackendRebuilder(sbSSSE3, @RegisterSSSE3Backend);

end.
