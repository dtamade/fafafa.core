// === F32x8 Operations (simulate with 2x F32x4) ===

// ✅ SIMD Quality Iteration 4.4: 2×128-bit SSE2 ASM 实现
function SSE2AddF32x8(const a, b: TVecF32x8): TVecF32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    // Load 2×128-bit
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    movups xmm2, [rdx]
    movups xmm3, [rdx+16]
    // Add
    addps  xmm0, xmm2
    addps  xmm1, xmm3
    // Store
    movups [rcx], xmm0
    movups [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2AddF32x4(a.lo, b.lo);
  Result.hi := SSE2AddF32x4(a.hi, b.hi);
{$ENDIF}
end;

function SSE2SubF32x8(const a, b: TVecF32x8): TVecF32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    movups xmm2, [rdx]
    movups xmm3, [rdx+16]
    subps  xmm0, xmm2
    subps  xmm1, xmm3
    movups [rcx], xmm0
    movups [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2SubF32x4(a.lo, b.lo);
  Result.hi := SSE2SubF32x4(a.hi, b.hi);
{$ENDIF}
end;

function SSE2MulF32x8(const a, b: TVecF32x8): TVecF32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    movups xmm2, [rdx]
    movups xmm3, [rdx+16]
    mulps  xmm0, xmm2
    mulps  xmm1, xmm3
    movups [rcx], xmm0
    movups [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2MulF32x4(a.lo, b.lo);
  Result.hi := SSE2MulF32x4(a.hi, b.hi);
{$ENDIF}
end;

function SSE2DivF32x8(const a, b: TVecF32x8): TVecF32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    movups xmm2, [rdx]
    movups xmm3, [rdx+16]
    divps  xmm0, xmm2
    divps  xmm1, xmm3
    movups [rcx], xmm0
    movups [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2DivF32x4(a.lo, b.lo);
  Result.hi := SSE2DivF32x4(a.hi, b.hi);
{$ENDIF}
end;

