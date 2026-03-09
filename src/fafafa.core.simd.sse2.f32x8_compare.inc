// === F32x8 Comparison Operations (direct 2×128-bit ASM) ===
// ✅ Converted from recursive calls to eliminate function call overhead

function SSE2CmpEqF32x8(const a, b: TVecF32x8): TMask8;
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    // Compare lo (first 128 bits)
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpeqps  xmm0, xmm1      // a.lo == b.lo
    movmskps eax, xmm0       // Extract 4-bit mask
    mov      lo_mask, eax
    // Compare hi (second 128 bits)
    movups   xmm0, [rax+16]
    movups   xmm1, [rdx+16]
    cmpeqps  xmm0, xmm1      // a.hi == b.hi
    movmskps eax, xmm0       // Extract 4-bit mask
    mov      hi_mask, eax
  end;
  Result := TMask8(lo_mask or (hi_mask shl 4));
end;

function SSE2CmpLtF32x8(const a, b: TVecF32x8): TMask8;
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    // Compare lo (first 128 bits)
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpltps  xmm0, xmm1      // a.lo < b.lo
    movmskps eax, xmm0       // Extract 4-bit mask
    mov      lo_mask, eax
    // Compare hi (second 128 bits)
    movups   xmm0, [rax+16]
    movups   xmm1, [rdx+16]
    cmpltps  xmm0, xmm1      // a.hi < b.hi
    movmskps eax, xmm0       // Extract 4-bit mask
    mov      hi_mask, eax
  end;
  Result := TMask8(lo_mask or (hi_mask shl 4));
end;

function SSE2CmpLeF32x8(const a, b: TVecF32x8): TMask8;
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    // Compare lo (first 128 bits)
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpleps  xmm0, xmm1      // a.lo <= b.lo
    movmskps eax, xmm0       // Extract 4-bit mask
    mov      lo_mask, eax
    // Compare hi (second 128 bits)
    movups   xmm0, [rax+16]
    movups   xmm1, [rdx+16]
    cmpleps  xmm0, xmm1      // a.hi <= b.hi
    movmskps eax, xmm0       // Extract 4-bit mask
    mov      hi_mask, eax
  end;
  Result := TMask8(lo_mask or (hi_mask shl 4));
end;

function SSE2CmpGtF32x8(const a, b: TVecF32x8): TMask8;
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  // GT: swap operands and use LT
  pa := @a;
  pb := @b;
  asm
    mov      rax, pb
    mov      rdx, pa
    // Compare lo (first 128 bits) - swapped operands
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpltps  xmm0, xmm1      // b.lo < a.lo => a.lo > b.lo
    movmskps eax, xmm0       // Extract 4-bit mask
    mov      lo_mask, eax
    // Compare hi (second 128 bits) - swapped operands
    movups   xmm0, [rax+16]
    movups   xmm1, [rdx+16]
    cmpltps  xmm0, xmm1      // b.hi < a.hi => a.hi > b.hi
    movmskps eax, xmm0       // Extract 4-bit mask
    mov      hi_mask, eax
  end;
  Result := TMask8(lo_mask or (hi_mask shl 4));
end;

function SSE2CmpGeF32x8(const a, b: TVecF32x8): TMask8;
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  // GE: swap operands and use LE
  pa := @a;
  pb := @b;
  asm
    mov      rax, pb
    mov      rdx, pa
    // Compare lo (first 128 bits) - swapped operands
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpleps  xmm0, xmm1      // b.lo <= a.lo => a.lo >= b.lo
    movmskps eax, xmm0       // Extract 4-bit mask
    mov      lo_mask, eax
    // Compare hi (second 128 bits) - swapped operands
    movups   xmm0, [rax+16]
    movups   xmm1, [rdx+16]
    cmpleps  xmm0, xmm1      // b.hi <= a.hi => a.hi >= b.hi
    movmskps eax, xmm0       // Extract 4-bit mask
    mov      hi_mask, eax
  end;
  Result := TMask8(lo_mask or (hi_mask shl 4));
end;

function SSE2CmpNeF32x8(const a, b: TVecF32x8): TMask8;
var
  pa, pb: Pointer;
  lo_mask, hi_mask: UInt32;
begin
  pa := @a;
  pb := @b;
  asm
    mov      rax, pa
    mov      rdx, pb
    // Compare lo (first 128 bits)
    movups   xmm0, [rax]
    movups   xmm1, [rdx]
    cmpneqps xmm0, xmm1      // a.lo != b.lo
    movmskps eax, xmm0       // Extract 4-bit mask
    mov      lo_mask, eax
    // Compare hi (second 128 bits)
    movups   xmm0, [rax+16]
    movups   xmm1, [rdx+16]
    cmpneqps xmm0, xmm1      // a.hi != b.hi
    movmskps eax, xmm0       // Extract 4-bit mask
    mov      hi_mask, eax
  end;
  Result := TMask8(lo_mask or (hi_mask shl 4));
end;

