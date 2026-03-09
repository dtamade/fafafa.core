unit fafafa.core.simd.sse41;

{$mode objfpc}
{$I fafafa.core.settings.inc}
{$asmmode intel}

interface

uses
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch,
  fafafa.core.simd.backend.priority;

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
//
// ✅ Task 5.1: Enhanced SSE4.1 implementation
// - Inherits from SSSE3 via CloneDispatchTable
// - PMULLD: Critical 32-bit integer multiplication (SSE2 only has 16-bit!)
// - ROUNDPS/ROUNDPD: Hardware rounding operations
// - DPPS/DPPD: Single-instruction dot product
// - PMINSD/PMAXSD: Signed 32-bit min/max
// - PMINUD/PMAXUD: Unsigned 32-bit min/max
// - PMINSB/PMAXSB: Signed 8-bit min/max (new!)
// - PMINUW/PMAXUW: Unsigned 16-bit min/max (new!)

procedure RegisterSSE41Backend;

// === SSE4.1 Exported Functions ===

// Dot product (DPPS/DPPD - huge performance gain)
function SSE41DotF32x4_Full(const a, b: TVecF32x4): TVecF32x4;
function SSE41DotF32x4(const a, b: TVecF32x4): Single;
function SSE41DotF32x3(const a, b: TVecF32x4): Single;
function SSE41DotF64x2(const a, b: TVecF64x2): Double;

// Rounding (ROUNDPS/ROUNDPD - hardware precision)
function SSE41RoundF32x4(const a: TVecF32x4): TVecF32x4;
function SSE41FloorF32x4(const a: TVecF32x4): TVecF32x4;
function SSE41CeilF32x4(const a: TVecF32x4): TVecF32x4;
function SSE41TruncF32x4(const a: TVecF32x4): TVecF32x4;
function SSE41RoundF64x2(const a: TVecF64x2): TVecF64x2;
function SSE41FloorF64x2(const a: TVecF64x2): TVecF64x2;
function SSE41CeilF64x2(const a: TVecF64x2): TVecF64x2;
function SSE41TruncF64x2(const a: TVecF64x2): TVecF64x2;

// Blending
function SSE41BlendF32x4_1(const a, b: TVecF32x4): TVecF32x4;
function SSE41BlendVF32x4(const a, b: TVecF32x4; const mask: TMaskF32x4): TVecF32x4;

// Integer multiply (PMULLD - critical missing instruction in SSE2!)
function SSE41MulI32x4(const a, b: TVecI32x4): TVecI32x4;

// 32-bit signed min/max (PMINSD/PMAXSD - new in SSE4.1!)
function SSE41MinI32x4(const a, b: TVecI32x4): TVecI32x4;
function SSE41MaxI32x4(const a, b: TVecI32x4): TVecI32x4;

// 32-bit unsigned min/max (PMINUD/PMAXUD - new in SSE4.1!)
function SSE41MinU32x4(const a, b: TVecU32x4): TVecU32x4;
function SSE41MaxU32x4(const a, b: TVecU32x4): TVecU32x4;

// 8-bit signed min/max (PMINSB/PMAXSB - new in SSE4.1!)
function SSE41MinI8x16(const a, b: TVecI8x16): TVecI8x16;
function SSE41MaxI8x16(const a, b: TVecI8x16): TVecI8x16;

// 16-bit unsigned min/max (PMINUW/PMAXUW - new in SSE4.1!)
function SSE41MinU16x8(const a, b: TVecU16x8): TVecU16x8;
function SSE41MaxU16x8(const a, b: TVecU16x8): TVecU16x8;

// Insert/Extract
function SSE41InsertF32x4(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4;
function SSE41ExtractF32x4(const a: TVecF32x4; index: Integer): Single;

// 64-bit comparison (PCMPEQQ - new in SSE4.1!)
function SSE41CmpEqI64x2(const a, b: TVecI64x2): TMask2;

// Pack (PACKUSDW - new in SSE4.1!)
function SSE41PackUSDW(const a, b: TVecI32x4): TVecU16x8;

// Test (PTEST - new in SSE4.1!)
function SSE41TestAllZeros(const a, b: TVecU8x16): Boolean;
function SSE41TestAllOnes(const a, b: TVecU8x16): Boolean;

// Length (optimized with DPPS)
function SSE41LengthF32x4(const a: TVecF32x4): Single;
function SSE41LengthF32x3(const a: TVecF32x4): Single;

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
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rdx]
    dpps   xmm0, xmm1, $FF   // All 4 inputs, broadcast to all 4 outputs
    movups [rcx], xmm0
  end;
end;

// Dot product returning scalar (broadcast to lane 0 only)
// $F1 = all 4 inputs, output only to element 0
function SSE41DotF32x4(const a, b: TVecF32x4): Single;
var
  pa, pb: Pointer;
begin
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    movups xmm0, [rax]
    movups xmm1, [rdx]
    dpps   xmm0, xmm1, $F1   // 4 inputs, 1 output
    movss  [result], xmm0
  end;
end;

// 3-element dot product (ignoring w)
// $71 = lower 3 inputs (xyz), output to element 0
function SSE41DotF32x3(const a, b: TVecF32x4): Single;
var
  pa, pb: Pointer;
begin
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
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
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movups xmm0, [rax]
    roundps xmm0, xmm0, 0    // Round to nearest
    movups [rcx], xmm0
  end;
end;

function SSE41FloorF32x4(const a: TVecF32x4): TVecF32x4;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movups xmm0, [rax]
    roundps xmm0, xmm0, 1    // Floor
    movups [rcx], xmm0
  end;
end;

function SSE41CeilF32x4(const a: TVecF32x4): TVecF32x4;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movups xmm0, [rax]
    roundps xmm0, xmm0, 2    // Ceil
    movups [rcx], xmm0
  end;
end;

function SSE41TruncF32x4(const a: TVecF32x4): TVecF32x4;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movups xmm0, [rax]
    roundps xmm0, xmm0, 3    // Truncate (toward zero)
    movups [rcx], xmm0
  end;
end;

function SSE41RoundF64x2(const a: TVecF64x2): TVecF64x2;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movupd xmm0, [rax]
    roundpd xmm0, xmm0, 0
    movupd [rcx], xmm0
  end;
end;

function SSE41FloorF64x2(const a: TVecF64x2): TVecF64x2;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movupd xmm0, [rax]
    roundpd xmm0, xmm0, 1
    movupd [rcx], xmm0
  end;
end;

function SSE41CeilF64x2(const a: TVecF64x2): TVecF64x2;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movupd xmm0, [rax]
    roundpd xmm0, xmm0, 2
    movupd [rcx], xmm0
  end;
end;

function SSE41TruncF64x2(const a: TVecF64x2): TVecF64x2;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movupd xmm0, [rax]
    roundpd xmm0, xmm0, 3
    movupd [rcx], xmm0
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
// ✅ This is one of the most important SSE4.1 instructions!
// SSE2 only has 16-bit multiply (PMULLW)

function SSE41MulI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pmulld xmm0, xmm1
    movdqu [rcx], xmm0
  end;
end;

// ✅ NEW: U32x4 multiplication using PMULLD (same bit pattern)
function SSE41MulU32x4(const a, b: TVecU32x4): TVecU32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pmulld xmm0, xmm1      // Same instruction, works for unsigned too
    movdqu [rcx], xmm0
  end;
end;

// === SSE4.1 Min/Max for 32-bit integers ===
// ✅ PMINSD/PMAXSD: Signed 32-bit min/max (NEW in SSE4.1!)
// SSE2 doesn't have these - requires compare+select workaround

function SSE41MinI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pminsd xmm0, xmm1      // Signed 32-bit min
    movdqu [rcx], xmm0
  end;
end;

function SSE41MaxI32x4(const a, b: TVecI32x4): TVecI32x4;
var
  pa, pb, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pmaxsd xmm0, xmm1      // Signed 32-bit max
    movdqu [rcx], xmm0
  end;
end;

// ✅ PMINUD/PMAXUD: Unsigned 32-bit min/max (NEW in SSE4.1!)
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

// ✅ NEW: PMINSB/PMAXSB - Signed 8-bit min/max (NEW in SSE4.1!)
// SSE2/SSSE3 don't have these for signed bytes!
function SSE41MinI8x16(const a, b: TVecI8x16): TVecI8x16;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pminsb xmm0, xmm1      // Signed 8-bit min
    movdqu [result], xmm0
  end;
end;

function SSE41MaxI8x16(const a, b: TVecI8x16): TVecI8x16;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pmaxsb xmm0, xmm1      // Signed 8-bit max
    movdqu [result], xmm0
  end;
end;

// ✅ NEW: PMINUW/PMAXUW - Unsigned 16-bit min/max (NEW in SSE4.1!)
function SSE41MinU16x8(const a, b: TVecU16x8): TVecU16x8;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pminuw xmm0, xmm1      // Unsigned 16-bit min
    movdqu [result], xmm0
  end;
end;

function SSE41MaxU16x8(const a, b: TVecU16x8): TVecU16x8;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pmaxuw xmm0, xmm1      // Unsigned 16-bit max
    movdqu [result], xmm0
  end;
end;

// === SSE4.1 Insert/Extract ===

function SSE41InsertF32x4(const a: TVecF32x4; value: Single; index: Integer): TVecF32x4;
var
  pa, pr: Pointer;
  safeIndex: Integer;
  v: Single;
begin
  safeIndex := index;
  if safeIndex < 0 then safeIndex := 0
  else if safeIndex > 3 then safeIndex := 3;

  // Make the scalar value addressable for inline asm.
  v := value;

  pa := @a;
  pr := @Result;

  case safeIndex of
    0: asm
         mov    rax, pa
         mov    rcx, pr
         movups xmm0, [rax]
         movss  xmm1, v
         insertps xmm0, xmm1, $00  // Insert to element 0
         movups [rcx], xmm0
       end;
    1: asm
         mov    rax, pa
         mov    rcx, pr
         movups xmm0, [rax]
         movss  xmm1, v
         insertps xmm0, xmm1, $10  // Insert to element 1
         movups [rcx], xmm0
       end;
    2: asm
         mov    rax, pa
         mov    rcx, pr
         movups xmm0, [rax]
         movss  xmm1, v
         insertps xmm0, xmm1, $20  // Insert to element 2
         movups [rcx], xmm0
       end;
    3: asm
         mov    rax, pa
         mov    rcx, pr
         movups xmm0, [rax]
         movss  xmm1, v
         insertps xmm0, xmm1, $30  // Insert to element 3
         movups [rcx], xmm0
       end;
  end;
end;

function SSE41ExtractF32x4(const a: TVecF32x4; index: Integer): Single;
var
  pa: Pointer;
  safeIndex: Integer;
  tmp: UInt32;
begin
  safeIndex := index;
  if safeIndex < 0 then safeIndex := 0
  else if safeIndex > 3 then safeIndex := 3;

  tmp := 0;
  Result := 0.0;

  pa := @a;

  case safeIndex of
    0: asm
         mov    rax, pa
         movups xmm0, [rax]
         extractps eax, xmm0, 0
         mov    [tmp], eax
       end;
    1: asm
         mov    rax, pa
         movups xmm0, [rax]
         extractps eax, xmm0, 1
         mov    [tmp], eax
       end;
    2: asm
         mov    rax, pa
         movups xmm0, [rax]
         extractps eax, xmm0, 2
         mov    [tmp], eax
       end;
    3: asm
         mov    rax, pa
         movups xmm0, [rax]
         extractps eax, xmm0, 3
         mov    [tmp], eax
       end;
  end;
  Move(tmp, Result, SizeOf(Result));
end;

// === SSE4.1 64-bit Comparison ===
// ✅ PCMPEQQ: 64-bit integer equality (NEW in SSE4.1!)
// SSE2 only has up to 32-bit comparison

function SSE41CmpEqI64x2(const a, b: TVecI64x2): TMask2;
var
  pa, pb: Pointer;
  maskVal: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpeqq  xmm0, xmm1
    movmskpd eax, xmm0
    mov      maskVal, eax
  end;
  Result := TMask2(maskVal);
end;

// === SSE4.1 Pack ===
// ✅ PACKUSDW: Pack 32-bit signed integers to 16-bit unsigned with saturation (NEW!)

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
// ✅ PTEST: Packed bit test (NEW in SSE4.1!)

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
// Using DPPS for dot product with self

function SSE41LengthF32x4(const a: TVecF32x4): Single;
var
  pa: Pointer;
begin
  pa := @a;
  asm
    mov    rax, pa
    movups xmm0, [rax]
    dpps   xmm0, xmm0, $FF   // Dot product with self = sum of squares
    sqrtss xmm0, xmm0        // Square root of element 0
    movss  [result], xmm0
  end;
end;

function SSE41LengthF32x3(const a: TVecF32x4): Single;
var
  pa: Pointer;
begin
  pa := @a;
  asm
    mov    rax, pa
    movups xmm0, [rax]
    dpps   xmm0, xmm0, $71   // Dot product xyz with self
    sqrtss xmm0, xmm0
    movss  [result], xmm0
  end;
end;

// ✅ NEW: SSE4.1 Optimized Normalize using DPPS
function SSE41NormalizeF32x4(const a: TVecF32x4): TVecF32x4;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movups xmm0, [rax]       // Load vector
    movaps xmm1, xmm0        // Copy for dot product
    dpps   xmm1, xmm1, $FF   // length^2 in all lanes
    rsqrtps xmm1, xmm1       // 1/length in all lanes
    mulps  xmm0, xmm1        // Normalize
    movups [rcx], xmm0
  end;
end;

function SSE41NormalizeF32x3(const a: TVecF32x4): TVecF32x4;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movups xmm0, [rax]
    movaps xmm1, xmm0
    dpps   xmm1, xmm1, $7F   // xyz dot product, broadcast to all
    rsqrtps xmm1, xmm1
    mulps  xmm0, xmm1
    // Zero w component
    pcmpeqd xmm2, xmm2
    psrldq xmm2, 4
    andps  xmm0, xmm2
    movups [rcx], xmm0
  end;
end;

// ✅ NEW: SSE4.1 Select operations using BLENDVPS
function SSE41SelectF32x4(const mask: TMask4; const a, b: TVecF32x4): TVecF32x4;
var
  pmask, pa, pb, pr: Pointer;
  maskVec: TVecI32x4;
  i: Integer;
begin
  // Expand mask bits to full vector mask
  for i := 0 to 3 do
    if (mask shr i) and 1 <> 0 then
      maskVec.i[i] := Int32($FFFFFFFF)
    else
      maskVec.i[i] := 0;

  pmask := @maskVec;
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov    rax, pmask
    mov    rdx, pa
    mov    r8, pb
    mov    rcx, pr
    movdqu xmm0, [rax]       // mask -> xmm0 (implicit for blendvps)
    movups xmm1, [r8]        // b (source when mask bit set)
    movups xmm2, [rdx]       // a (source when mask bit clear)
    // blendvps: xmm2 = (mask[i] < 0) ? xmm1[i] : xmm2[i]
    blendvps xmm2, xmm1
    movups [rcx], xmm2
  end;
end;

// === Backend Registration ===

{$I fafafa.core.simd.sse41.register.inc}


end.
