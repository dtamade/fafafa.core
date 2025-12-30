unit fafafa.core.simd.sse41;

{$mode objfpc}
{$I fafafa.core.settings.inc}
{$asmmode intel}

interface

uses
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch;

// === SSE4.1 Backend Implementation ===
// Provides SIMD-accelerated operations using x86-64 SSE4.1 instructions.
// SSE4.1 is a major update with many practical instructions.
//
// Key SSE4.1 instructions:
// - DPPS/DPPD: Direct dot product with mask (huge performance gain)
// - ROUNDPS/ROUNDPD: Hardware rounding (floor, ceil, trunc, nearest)
// - BLENDPS/BLENDPD/PBLENDW/PBLENDVB: Vector blending
// - INSERTPS/EXTRACTPS: Insert/extract single F32 elements
// - PINSRB/PINSRD/PINSRQ, PEXTRB/PEXTRD/PEXTRQ: Integer insert/extract
// - PMULLD: 32-bit integer multiplication (missing in SSE2!)
// - PMOVSX/PMOVZX: Sign/zero extend packed integers
// - PCMPEQQ: 64-bit integer comparison
// - PACKUSDW: Unsigned pack dwords to words
// - PTEST: Packed bit test (CF and ZF flags)
// - PMAXSD/PMINSD, PMAXUD/PMINUD: 32-bit signed/unsigned min/max
// - MPSADBW: Multi-packed sum of absolute differences (for motion estimation)

procedure RegisterSSE41Backend;

implementation

uses
  SysUtils,
  fafafa.core.simd.cpuinfo;

// === SSE4.1 Dot Product ===
// DPPS/DPPD provide single-instruction dot product with masking

// Dot product for F32x4 with full 4-element output
// imm8 bits: [7:4] = input mask, [3:0] = output mask
// $FF = all inputs, all outputs
function SSE41DotF32x4_Full(const a, b: TVecF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movups xmm0, [rax]
    movups xmm1, [rdx]
    dpps   xmm0, xmm1, $FF   // All 4 inputs, broadcast to all 4 outputs
    movups [result], xmm0
  end;
end;

// Dot product returning scalar (broadcast to lane 0 only)
// $F1 = all 4 inputs, output only to element 0
function SSE41DotF32x4(const a, b: TVecF32x4): Single;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movups xmm0, [rax]
    movups xmm1, [rdx]
    dpps   xmm0, xmm1, $F1   // 4 inputs, 1 output
    movss  [result], xmm0
  end;
end;

// 3-element dot product (ignoring w)
// $71 = lower 3 inputs (xyz), output to element 0
function SSE41DotF32x3(const a, b: TVecF32x4): Single;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movups xmm0, [rax]
    movups xmm1, [rdx]
    dpps   xmm0, xmm1, $71   // 3 inputs (xyz), 1 output
    movss  [result], xmm0
  end;
end;

// Dot product for F64x2
function SSE41DotF64x2(const a, b: TVecF64x2): Double;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movupd xmm0, [rax]
    movupd xmm1, [rdx]
    dppd   xmm0, xmm1, $31   // Both inputs, output to element 0
    movlpd [result], xmm0
  end;
end;

// === SSE4.1 Rounding ===
// Hardware rounding with immediate control:
// 0 = Round to nearest (even), 1 = Floor, 2 = Ceil, 3 = Truncate

function SSE41RoundF32x4(const a: TVecF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    movups xmm0, [rax]
    roundps xmm0, xmm0, 0    // Round to nearest
    movups [result], xmm0
  end;
end;

function SSE41FloorF32x4(const a: TVecF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    movups xmm0, [rax]
    roundps xmm0, xmm0, 1    // Floor
    movups [result], xmm0
  end;
end;

function SSE41CeilF32x4(const a: TVecF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    movups xmm0, [rax]
    roundps xmm0, xmm0, 2    // Ceil
    movups [result], xmm0
  end;
end;

function SSE41TruncF32x4(const a: TVecF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    movups xmm0, [rax]
    roundps xmm0, xmm0, 3    // Truncate (toward zero)
    movups [result], xmm0
  end;
end;

function SSE41RoundF64x2(const a: TVecF64x2): TVecF64x2;
begin
  asm
    lea    rax, a
    movupd xmm0, [rax]
    roundpd xmm0, xmm0, 0
    movupd [result], xmm0
  end;
end;

function SSE41FloorF64x2(const a: TVecF64x2): TVecF64x2;
begin
  asm
    lea    rax, a
    movupd xmm0, [rax]
    roundpd xmm0, xmm0, 1
    movupd [result], xmm0
  end;
end;

function SSE41CeilF64x2(const a: TVecF64x2): TVecF64x2;
begin
  asm
    lea    rax, a
    movupd xmm0, [rax]
    roundpd xmm0, xmm0, 2
    movupd [result], xmm0
  end;
end;

function SSE41TruncF64x2(const a: TVecF64x2): TVecF64x2;
begin
  asm
    lea    rax, a
    movupd xmm0, [rax]
    roundpd xmm0, xmm0, 3
    movupd [result], xmm0
  end;
end;

// === SSE4.1 Blending ===
// More efficient than SSE2 bit operations for selecting elements

// Blend based on immediate mask
function SSE41BlendF32x4_1(const a, b: TVecF32x4): TVecF32x4;
begin
  // Select element 0 from b, rest from a
  asm
    lea    rax, a
    lea    rdx, b
    movups xmm0, [rax]
    movups xmm1, [rdx]
    blendps xmm0, xmm1, 1    // Mask: bit 0 set
    movups [result], xmm0
  end;
end;

// Variable blend using mask vector (SSE4.1 blendvps)
function SSE41BlendVF32x4(const a, b: TVecF32x4; const mask: TMaskF32x4): TVecF32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    lea    rcx, mask
    movups xmm0, [rax]
    movups xmm1, [rdx]
    movups xmm2, [rcx]
    // Move mask to xmm0 implicit operand
    movaps xmm3, xmm2
    movaps xmm0, [rax]
    movaps xmm1, [rdx]
    // blendvps uses xmm0 implicitly as mask, which is inconvenient
    // We need to shuffle: xmm0=mask for blendvps xmm1, xmm2
    // Actually: blendvps xmm1, xmm2, <xmm0> selects from xmm2 where xmm0 high bit set
    movaps xmm0, xmm3       // mask -> xmm0
    movaps xmm1, [rax]      // a
    movaps xmm2, [rdx]      // b
    // blendvps xmm1, xmm2, xmm0: for each element, if xmm0 high bit set, take from xmm2
    blendvps xmm1, xmm2         // xmm0 is implicit mask operand in FPC
    movups [result], xmm1
  end;
end;

// === SSE4.1 Integer Multiply ===
// PMULLD: 32-bit integer multiplication (finally!)

function SSE41MulI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pmulld xmm0, xmm1
    movdqu [result], xmm0
  end;
end;

// === SSE4.1 Min/Max for 32-bit integers ===

function SSE41MinI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pminsd xmm0, xmm1      // Signed 32-bit min
    movdqu [result], xmm0
  end;
end;

function SSE41MaxI32x4(const a, b: TVecI32x4): TVecI32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pmaxsd xmm0, xmm1      // Signed 32-bit max
    movdqu [result], xmm0
  end;
end;

function SSE41MinU32x4(const a, b: TVecU32x4): TVecU32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pminud xmm0, xmm1      // Unsigned 32-bit min
    movdqu [result], xmm0
  end;
end;

function SSE41MaxU32x4(const a, b: TVecU32x4): TVecU32x4;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pmaxud xmm0, xmm1      // Unsigned 32-bit max
    movdqu [result], xmm0
  end;
end;

// === SSE4.1 Insert/Extract ===

function SSE41InsertF32x4(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4;
var
  safeIndex: Integer;
begin
  safeIndex := index;
  if safeIndex < 0 then safeIndex := 0
  else if safeIndex > 3 then safeIndex := 3;

  Result := a;
  case safeIndex of
    0: asm
         lea    rax, a
         movups xmm0, [rax]
         movss  xmm1, value
         insertps xmm0, xmm1, $00  // Insert to element 0
         movups [result], xmm0
       end;
    1: asm
         lea    rax, a
         movups xmm0, [rax]
         movss  xmm1, value
         insertps xmm0, xmm1, $10  // Insert to element 1
         movups [result], xmm0
       end;
    2: asm
         lea    rax, a
         movups xmm0, [rax]
         movss  xmm1, value
         insertps xmm0, xmm1, $20  // Insert to element 2
         movups [result], xmm0
       end;
    3: asm
         lea    rax, a
         movups xmm0, [rax]
         movss  xmm1, value
         insertps xmm0, xmm1, $30  // Insert to element 3
         movups [result], xmm0
       end;
  end;
end;

function SSE41ExtractF32x4(const a: TVecF32x4; index: Integer): Single;
var
  safeIndex: Integer;
  tmp: UInt32;
begin
  safeIndex := index;
  if safeIndex < 0 then safeIndex := 0
  else if safeIndex > 3 then safeIndex := 3;

  tmp := 0;
  Result := 0.0;

  case safeIndex of
    0: asm
         lea    rax, a
         movups xmm0, [rax]
         extractps eax, xmm0, 0
         mov    [tmp], eax
       end;
    1: asm
         lea    rax, a
         movups xmm0, [rax]
         extractps eax, xmm0, 1
         mov    [tmp], eax
       end;
    2: asm
         lea    rax, a
         movups xmm0, [rax]
         extractps eax, xmm0, 2
         mov    [tmp], eax
       end;
    3: asm
         lea    rax, a
         movups xmm0, [rax]
         extractps eax, xmm0, 3
         mov    [tmp], eax
       end;
  end;
  Move(tmp, Result, SizeOf(Result));
end;

// === SSE4.1 64-bit Comparison ===

function SSE41CmpEqI64x2(const a, b: TVecI64x2): TMask2;
var
  maskVal: Integer;
begin
  asm
    lea      rax, a
    lea      rdx, b
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqq  xmm0, xmm1
    movmskpd eax, xmm0
    mov      maskVal, eax
  end;
  Result := TMask2(maskVal);
end;

// === SSE4.1 Pack ===

// Pack 32-bit signed integers to 16-bit unsigned with saturation
function SSE41PackUSDW(const a, b: TVecI32x4): TVecU16x8;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    packusdw xmm0, xmm1
    movdqu [result], xmm0
  end;
end;

// === SSE4.1 Test ===

// Test if all bits are zero: returns True if (a AND b) == 0
function SSE41TestAllZeros(const a, b: TVecU8x16): Boolean;
var
  zf: Boolean;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    ptest  xmm0, xmm1
    setz   al
    mov    [zf], al
  end;
  Result := zf;
end;

// Test if all bits are one: returns True if (a AND NOT b) == 0
function SSE41TestAllOnes(const a, b: TVecU8x16): Boolean;
var
  cf: Boolean;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    ptest  xmm0, xmm1
    setc   al
    mov    [cf], al
  end;
  Result := cf;
end;

// === SSE4.1 Optimized Length ===

function SSE41LengthF32x4(const a: TVecF32x4): Single;
begin
  asm
    lea    rax, a
    movups xmm0, [rax]
    dpps   xmm0, xmm0, $FF   // Dot product with self = sum of squares
    sqrtss xmm0, xmm0        // Square root of element 0
    movss  [result], xmm0
  end;
end;

function SSE41LengthF32x3(const a: TVecF32x4): Single;
begin
  asm
    lea    rax, a
    movups xmm0, [rax]
    dpps   xmm0, xmm0, $71   // Dot product xyz with self
    sqrtss xmm0, xmm0
    movss  [result], xmm0
  end;
end;

// === Backend Registration ===

procedure RegisterSSE41Backend;
var
  dispatchTable: TSimdDispatchTable;
begin
  // Only register if SSE4.1 is available
  if not HasSSE41 then
    Exit;

  // ✅ 修复 P0-1: 从 SSSE3 继承实现（SSE4.1 是 SSSE3 的超集）
  dispatchTable := Default(TSimdDispatchTable);

  // Set backend info BEFORE cloning (will be preserved)
  with dispatchTable.BackendInfo do
  begin
    Backend := sbSSE41;
    Name := 'SSE4.1';
    Description := 'x86-64 SSE4.1 SIMD implementation (dot product, rounding, pmulld)';
    Capabilities := [scBasicArithmetic, scComparison, scMathFunctions, scReduction,
                     scShuffle, scIntegerOps, scLoadStore];
    Available := True;
    Priority := 20; // Higher than SSSE3 (18)
  end;

  // Clone from SSSE3 → SSE3 → SSE2 chain
  if not CloneDispatchTable(sbSSSE3, dispatchTable) then
    if not CloneDispatchTable(sbSSE3, dispatchTable) then
      if not CloneDispatchTable(sbSSE2, dispatchTable) then
        FillBaseDispatchTable(dispatchTable);

  // Update backend identifier
  dispatchTable.Backend := sbSSE41;

  // SSE4.1 provides major improvements
  if IsVectorAsmEnabled then
  begin
    // Override dot product with single-instruction DPPS
    dispatchTable.DotF32x4 := @SSE41DotF32x4;
    dispatchTable.DotF32x3 := @SSE41DotF32x3;
    // DotF64x2 not in dispatch table yet - SSE4.1 DPPD available when added
    // dispatchTable.DotF64x2 := @SSE41DotF64x2;

    // Override rounding operations with hardware ROUNDPS
    dispatchTable.RoundF32x4 := @SSE41RoundF32x4;
    dispatchTable.FloorF32x4 := @SSE41FloorF32x4;
    dispatchTable.CeilF32x4 := @SSE41CeilF32x4;
    dispatchTable.TruncF32x4 := @SSE41TruncF32x4;

    dispatchTable.RoundF64x2 := @SSE41RoundF64x2;
    dispatchTable.FloorF64x2 := @SSE41FloorF64x2;
    dispatchTable.CeilF64x2 := @SSE41CeilF64x2;
    dispatchTable.TruncF64x2 := @SSE41TruncF64x2;

    // Override 32-bit integer multiply with PMULLD
    dispatchTable.MulI32x4 := @SSE41MulI32x4;

    // Override 32-bit integer min/max
    dispatchTable.MinI32x4 := @SSE41MinI32x4;
    dispatchTable.MaxI32x4 := @SSE41MaxI32x4;
    // MinU32x4/MaxU32x4 not in dispatch table yet - SSE4.1 PMINUD/PMAXUD available when added
    // dispatchTable.MinU32x4 := @SSE41MinU32x4;
    // dispatchTable.MaxU32x4 := @SSE41MaxU32x4;

    // Override length with DPPS-based version
    dispatchTable.LengthF32x4 := @SSE41LengthF32x4;
    dispatchTable.LengthF32x3 := @SSE41LengthF32x3;

    // Override insert/extract
    dispatchTable.InsertF32x4 := @SSE41InsertF32x4;
    dispatchTable.ExtractF32x4 := @SSE41ExtractF32x4;

    // Override 64-bit comparison
    dispatchTable.CmpEqI64x2 := @SSE41CmpEqI64x2;
  end;

  // Register the backend
  RegisterBackend(sbSSE41, dispatchTable);
end;

initialization
  RegisterSSE41Backend;
  RegisterBackendRebuilder(sbSSE41, @RegisterSSE41Backend);

end.
