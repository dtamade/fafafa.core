// === I32x8 Operations (native 256-bit AVX2) ===

function AVX2AddI32x8(const a, b: TVecI32x8): TVecI32x8;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu ymm0, [rdx]
    vpaddd  ymm0, ymm0, [rcx]
    vmovdqu [rax], ymm0
    vzeroupper
  end;
end;

function AVX2SubI32x8(const a, b: TVecI32x8): TVecI32x8;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu ymm0, [rdx]
    vpsubd  ymm0, ymm0, [rcx]
    vmovdqu [rax], ymm0
    vzeroupper
  end;
end;

function AVX2MulI32x8(const a, b: TVecI32x8): TVecI32x8;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu ymm0, [rdx]
    vpmulld ymm0, ymm0, [rcx]
    vmovdqu [rax], ymm0
    vzeroupper
  end;
end;

// I32x8 Bitwise Operations

function AVX2AndI32x8(const a, b: TVecI32x8): TVecI32x8;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu ymm0, [rdx]
    vpand   ymm0, ymm0, [rcx]
    vmovdqu [rax], ymm0
    vzeroupper
  end;
end;

function AVX2OrI32x8(const a, b: TVecI32x8): TVecI32x8;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu ymm0, [rdx]
    vpor    ymm0, ymm0, [rcx]
    vmovdqu [rax], ymm0
    vzeroupper
  end;
end;

function AVX2XorI32x8(const a, b: TVecI32x8): TVecI32x8;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu ymm0, [rdx]
    vpxor   ymm0, ymm0, [rcx]
    vmovdqu [rax], ymm0
    vzeroupper
  end;
end;

function AVX2NotI32x8(const a: TVecI32x8): TVecI32x8;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;

  asm
    mov     rax, pr
    mov     rdx, pa
    vpcmpeqd ymm1, ymm1, ymm1   // all 1s
    vmovdqu ymm0, [rdx]
    vpxor   ymm0, ymm0, ymm1    // NOT = XOR with all 1s
    vmovdqu [rax], ymm0
    vzeroupper
  end;
end;

function AVX2AndNotI32x8(const a, b: TVecI32x8): TVecI32x8;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu ymm0, [rdx]
    vpandn  ymm0, ymm0, [rcx]   // (NOT a) AND b
    vmovdqu [rax], ymm0
    vzeroupper
  end;
end;

// I32x8 Shift Operations

function AVX2ShiftLeftI32x8(const a: TVecI32x8; count: Integer): TVecI32x8;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;

  if (count < 0) or (count >= 32) then
  begin
    FillChar(Result, SizeOf(Result), 0);
    Exit;
  end;

  asm
    mov     rax, pr
    mov     rdx, pa
    vmovdqu ymm0, [rdx]
    mov     ecx, count
    vmovd   xmm1, ecx
    vpslld  ymm0, ymm0, xmm1
    vmovdqu [rax], ymm0
    vzeroupper
  end;
end;

function AVX2ShiftRightI32x8(const a: TVecI32x8; count: Integer): TVecI32x8;
var
  pa, pr: Pointer;
begin
  pr := @Result;
  pa := @a;

  if (count < 0) or (count >= 32) then
  begin
    FillChar(Result, SizeOf(Result), 0);
    Exit;
  end;

  asm
    mov     rax, pr
    mov     rdx, pa
    vmovdqu ymm0, [rdx]
    mov     ecx, count
    vmovd   xmm1, ecx
    vpsrld  ymm0, ymm0, xmm1    // Logical right shift
    vmovdqu [rax], ymm0
    vzeroupper
  end;
end;

function AVX2ShiftRightArithI32x8(const a: TVecI32x8; count: Integer): TVecI32x8;
var
  pa, pr: Pointer;
  i: Integer;
begin
  pr := @Result;
  pa := @a;

  if count < 0 then
  begin
    Result := a;
    Exit;
  end;

  if count >= 32 then
  begin
    // Arithmetic shift >= 32: result is all 0s or all 1s depending on sign
    for i := 0 to 7 do
      if a.i[i] < 0 then
        Result.i[i] := -1
      else
        Result.i[i] := 0;
    Exit;
  end;

  asm
    mov     rax, pr
    mov     rdx, pa
    vmovdqu ymm0, [rdx]
    mov     ecx, count
    vmovd   xmm1, ecx
    vpsrad  ymm0, ymm0, xmm1    // Arithmetic right shift
    vmovdqu [rax], ymm0
    vzeroupper
  end;
end;

// I32x8 Comparison Operations

function AVX2CmpEqI32x8(const a, b: TVecI32x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;

  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu ymm0, [rdx]
    vpcmpeqd ymm0, ymm0, [rcx]
    vmovmskps eax, ymm0         // Extract sign bits (1 bit per 32-bit element)
    mov     mask, eax
    vzeroupper
  end;

  Result := TMask8(mask);
end;

function AVX2CmpLtI32x8(const a, b: TVecI32x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;

  // a < b is equivalent to b > a
  asm
    mov     rdx, pb
    mov     rcx, pa
    vmovdqu ymm0, [rdx]
    vpcmpgtd ymm0, ymm0, [rcx]  // b > a
    vmovmskps eax, ymm0
    mov     mask, eax
    vzeroupper
  end;

  Result := TMask8(mask);
end;

function AVX2CmpGtI32x8(const a, b: TVecI32x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;

  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu ymm0, [rdx]
    vpcmpgtd ymm0, ymm0, [rcx]
    vmovmskps eax, ymm0
    mov     mask, eax
    vzeroupper
  end;

  Result := TMask8(mask);
end;

// ✅ P0-2: 补充缺失的比较函数
function AVX2CmpLeI32x8(const a, b: TVecI32x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;

  // a <= b is equivalent to NOT(a > b)
  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu ymm0, [rdx]
    vpcmpgtd ymm0, ymm0, [rcx]   // a > b
    vmovmskps eax, ymm0
    xor     eax, $FF              // NOT (8 bits for 8 elements)
    mov     mask, eax
    vzeroupper
  end;

  Result := TMask8(mask);
end;

function AVX2CmpGeI32x8(const a, b: TVecI32x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;

  // a >= b is equivalent to NOT(a < b) = NOT(b > a)
  asm
    mov     rdx, pb
    mov     rcx, pa
    vmovdqu ymm0, [rdx]
    vpcmpgtd ymm0, ymm0, [rcx]   // b > a = a < b
    vmovmskps eax, ymm0
    xor     eax, $FF              // NOT (8 bits for 8 elements)
    mov     mask, eax
    vzeroupper
  end;

  Result := TMask8(mask);
end;

function AVX2CmpNeI32x8(const a, b: TVecI32x8): TMask8;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;

  // a != b is equivalent to NOT(a == b)
  asm
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu ymm0, [rdx]
    vpcmpeqd ymm0, ymm0, [rcx]   // a == b
    vmovmskps eax, ymm0
    xor     eax, $FF              // NOT (8 bits for 8 elements)
    mov     mask, eax
    vzeroupper
  end;

  Result := TMask8(mask);
end;

// I32x8 Min/Max Operations

function AVX2MinI32x8(const a, b: TVecI32x8): TVecI32x8;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu ymm0, [rdx]
    vpminsd ymm0, ymm0, [rcx]   // Signed min
    vmovdqu [rax], ymm0
    vzeroupper
  end;
end;

function AVX2MaxI32x8(const a, b: TVecI32x8): TVecI32x8;
var
  pa, pb, pr: Pointer;
begin
  pr := @Result;
  pa := @a;
  pb := @b;

  asm
    mov     rax, pr
    mov     rdx, pa
    mov     rcx, pb
    vmovdqu ymm0, [rdx]
    vpmaxsd ymm0, ymm0, [rcx]   // Signed max
    vmovdqu [rax], ymm0
    vzeroupper
  end;
end;

