unit fafafa.core.simd.text;

{$mode objfpc}{$H+}
{$IFDEF CPUX86_64}{$asmmode intel}{$ENDIF}

interface

function Utf8Validate_Scalar(p: Pointer; len: SizeUInt): LongBool;
{$IFDEF CPUX86_64}
function Utf8Validate_SSE2(p: Pointer; len: SizeUInt): LongBool; // ASCII 快路径（含非 ASCII 直接返回 False 的探测）
function Utf8Validate_FastPath(p: Pointer; len: SizeUInt): LongBool; // 组合：ASCII 快路径 + 非 ASCII 回退标量
// ASCII 无大小写等价比较（忽略大小写）
function AsciiEqualIgnoreCase_SSE2(a, b: Pointer; len: SizeUInt): LongBool;
function AsciiEqualIgnoreCase_AVX2(a, b: Pointer; len: SizeUInt): LongBool;
{$ENDIF}


{$IFDEF CPUAARCH64}
function Utf8Validate_NEON_ASCII(p: Pointer; len: SizeUInt): LongBool; // ASCII 快路径（非 ASCII 返回 False）
procedure ToLowerAscii_NEON(p: Pointer; len: SizeUInt);
procedure ToUpperAscii_NEON(p: Pointer; len: SizeUInt);
{$ENDIF}

procedure ToLowerAscii_Scalar(p: Pointer; len: SizeUInt);
procedure ToUpperAscii_Scalar(p: Pointer; len: SizeUInt);
// 标量：ASCII 无大小写等价比较（'A'..'Z' -> 加 32 与 'a'..'z' 比较；非字母直接比较）
function AsciiEqualIgnoreCase_Scalar(a, b: Pointer; len: SizeUInt): LongBool;


implementation

function Utf8Validate_Scalar(p: Pointer; len: SizeUInt): LongBool;
var
  i: SizeUInt;
  b: Byte;
  pb: PByte;
  need: Integer;
begin
  pb := PByte(p);
  need := 0;
  i := 0;
  while i < len do
  begin
    b := pb[i];
    if need = 0 then
    begin
      if (b and $80) = 0 then
      begin
        Inc(i);
        Continue;
      end
      else if (b and $E0) = $C0 then
      begin
        need := 1;
      end
      else if (b and $F0) = $E0 then
      begin
        need := 2;
      end
      else if (b and $F8) = $F0 then
      begin
        need := 3;
      end
      else
        Exit(False);
      Inc(i);
    end
    else
    begin
      if (b and $C0) <> $80 then Exit(False);
      Dec(need);
      Inc(i);
    end;
  end;
  Result := (need = 0);
end;

{$IFDEF CPUX86_64}
function Utf8Validate_SSE2(p: Pointer; len: SizeUInt): LongBool; assembler; nostackframe;
asm
  // r8 = p, r9 = len
  mov     r8,  qword ptr [p]
  mov     r9,  qword ptr [len]
  test    r9,  r9
  jz      @@ok

  // 处理 16 字节块，ASCII 快路径：若 PMOVMSKB 掩码为 0 则全 ASCII
  mov     rcx, r9
  shr     rcx, 4
  jz      @@tail
@@loop:
  movdqu  xmm0, [r8]
  pmovmskb eax, xmm0
  test    eax, eax
  jnz     @@non_ascii
  add     r8, 16
  dec     rcx
  jnz     @@loop

@@tail:
  and     r9, 15
  jz      @@ok
  // 尾部逐字节检查最高位
@@tail_loop:
  mov     al, byte ptr [r8]
  test    al, $80
  jnz     @@non_ascii
  inc     r8
  dec     r9
  jnz     @@tail_loop
  jmp     @@ok

@@ok:
  mov     eax, 1
  ret

@@non_ascii:
  xor     eax, eax
  ret
end;

function Utf8Validate_FastPath(p: Pointer; len: SizeUInt): LongBool;
begin
  // ASCII 则 SSE2 快速返回 True；非 ASCII 交给标量完整校验
  if Utf8Validate_SSE2(p, len) then Exit(True);
  Result := Utf8Validate_Scalar(p, len);
end;
{$ENDIF}

{$IFDEF CPUX86_64}
// SSE2：ASCII 忽略大小写比较（16B 块 + 尾部）
function AsciiEqualIgnoreCase_SSE2(a, b: Pointer; len: SizeUInt): LongBool; assembler; nostackframe;
asm
  // r8=a, r9=b, r10=len
  mov     r8,  qword ptr [a]
  mov     r9,  qword ptr [b]
  mov     r10, qword ptr [len]
  test    r10, r10
  jz      @@eq
  // constants: 0x80, 'A'^0x80, 'Z'^0x80, 0x20
  mov     eax, $80808080
  movd    xmm6, eax
  pshufd  xmm6, xmm6, 0
  mov     eax, $C1C1C1C1
  movd    xmm7, eax
  pshufd  xmm7, xmm7, 0
  mov     eax, $DADADADA
  movd    xmm5, eax
  pshufd  xmm5, xmm5, 0
  mov     eax, $20202020
  movd    xmm4, eax
  pshufd  xmm4, xmm4, 0
  pcmpeqb xmm3, xmm3            // ones
@@loop16:
  cmp     r10, 16
  jb      @@tail
  movdqu  xmm0, [r8]
  movdqu  xmm1, [r9]
  // map x to lowercase
  movdqa  xmm8, xmm0
  pxor    xmm8, xmm6            // tmp = x ^ 0x80
  movdqa  xmm9, xmm7
  pcmpgtb xmm9, xmm8            // A' > tmp
  pxor    xmm9, xmm3            // not lower
  movdqa  xmm10, xmm8
  pcmpgtb xmm10, xmm5           // tmp > Z'
  pxor    xmm10, xmm3           // not upper
  pand    xmm9, xmm10           // in-range
  pand    xmm9, xmm4            // & 0x20
  por     xmm0, xmm9
  // map y to lowercase
  movdqa  xmm8, xmm1
  pxor    xmm8, xmm6
  movdqa  xmm9, xmm7
  pcmpgtb xmm9, xmm8
  pxor    xmm9, xmm3
  movdqa  xmm10, xmm8
  pcmpgtb xmm10, xmm5
  pxor    xmm10, xmm3
  pand    xmm9, xmm10
  pand    xmm9, xmm4
  por     xmm1, xmm9
  // compare
  pcmpeqb xmm0, xmm1
  pmovmskb eax, xmm0
  cmp     eax, 0FFFFh
  jne     @@ne
  add     r8, 16
  add     r9, 16
  sub     r10, 16
  jmp     @@loop16
@@tail:
  test    r10, r10
  jz      @@eq
@@tloop:
  mov     al, byte ptr [r8]
  mov     dl, byte ptr [r9]
  // map to lowercase
  cmp     al, 'A'
  jb      @@a_done
  cmp     al, 'Z'
  ja      @@a_done
  or      al, $20
@@a_done:
  cmp     dl, 'A'
  jb      @@d_done
  cmp     dl, 'Z'
  ja      @@d_done
  or      dl, $20
@@d_done:
  cmp     al, dl
  jne     @@ne
  inc     r8
  inc     r9
  dec     r10
  jnz     @@tloop
  jmp     @@eq
@@eq:
  mov     eax, 1
  ret
@@ne:
  xor     eax, eax
  ret
end;
{$ENDIF}


{$IFDEF CPUX86_64}
// AVX2：ASCII 忽略大小写比较（32B 块）
function AsciiEqualIgnoreCase_AVX2(a, b: Pointer; len: SizeUInt): LongBool; assembler; nostackframe;
asm
  mov     r8,  qword ptr [a]
  mov     r9,  qword ptr [b]
  mov     r10, qword ptr [len]
  test    r10, r10
  jz      @@eq
  vzeroupper
  // constants
  mov     eax, $80808080
  vmovd   xmm6, eax
  vpshufd xmm6, xmm6, 0
  mov     eax, $C1C1C1C1
  vmovd   xmm7, eax
  vpshufd xmm7, xmm7, 0
  mov     eax, $DADADADA
  vmovd   xmm5, eax
  vpshufd xmm5, xmm5, 0
  mov     eax, $20202020
  vmovd   xmm4, eax
  vpshufd xmm4, xmm4, 0
  vinsertf128 ymm6, ymm6, xmm6, 1
  vinsertf128 ymm7, ymm7, xmm7, 1
  vinsertf128 ymm5, ymm5, xmm5, 1
  vinsertf128 ymm4, ymm4, xmm4, 1
  vpcmpeqb xmm2, xmm2, xmm2
  vinsertf128 ymm2, ymm2, xmm2, 1
@@loop32:
  cmp     r10, 32
  jb      @@tail
  vmovdqu ymm0, [r8]
  vmovdqu ymm1, [r9]
  // map x to lowercase
  vpxor   ymm8, ymm0, ymm6
  vpcmpgtb ymm9, ymm7, ymm8      // A' > tmp
  vpxor   ymm9, ymm9, ymm2       // not lower
  vpcmpgtb ymm10, ymm8, ymm5     // tmp > Z'
  vpxor   ymm10, ymm10, ymm2     // not upper
  vpand   ymm9, ymm9, ymm10      // in-range
  vpand   ymm9, ymm9, ymm4       // & 0x20
  vpor    ymm0, ymm0, ymm9
  // map y to lowercase
  vpxor   ymm8, ymm1, ymm6
  vpcmpgtb ymm9, ymm7, ymm8
  vpxor   ymm9, ymm9, ymm2
  vpcmpgtb ymm10, ymm8, ymm5
  vpxor   ymm10, ymm10, ymm2
  vpand   ymm9, ymm9, ymm10
  vpand   ymm9, ymm9, ymm4
  vpor    ymm1, ymm1, ymm9
  // compare
  vpcmpeqb ymm0, ymm0, ymm1
  vpmovmskb eax, ymm0
  cmp     eax, -1
  jne     @@ne
  add     r8, 32
  add     r9, 32
  sub     r10, 32
  jmp     @@loop32
@@tail:
  test    r10, r10
  jz      @@eq
  cmp     r10, 16
  jb      @@bytes
  // process 16 via SSE2 path
  sub     r10, 16
  // fallthrough: map 16 for tail compare
  movdqu  xmm0, [r8]
  movdqu  xmm1, [r9]
  // constants in xmm4..xmm7 are valid
  movdqa  xmm11, xmm0
  pxor    xmm11, xmm6
  movdqa  xmm12, xmm7
  pcmpgtb xmm12, xmm11
  pcmpeqb xmm3, xmm3
  pxor    xmm12, xmm3
  movdqa  xmm13, xmm11
  pcmpgtb xmm13, xmm5
  pxor    xmm13, xmm3
  pand    xmm12, xmm13
  pand    xmm12, xmm4
  por     xmm0, xmm12
  movdqa  xmm11, xmm1
  pxor    xmm11, xmm6
  movdqa  xmm12, xmm7
  pcmpgtb xmm12, xmm11
  pxor    xmm12, xmm3
  movdqa  xmm13, xmm11
  pcmpgtb xmm13, xmm5
  pxor    xmm13, xmm3
  pand    xmm12, xmm13
  pand    xmm12, xmm4
  por     xmm1, xmm12
  pcmpeqb xmm0, xmm1
  pmovmskb eax, xmm0
  cmp     eax, 0FFFFh
  jne     @@ne
  add     r8, 16
  add     r9, 16
@@bytes:
  test    r10, r10
  jz      @@eq
@@bloop:
  mov     al, byte ptr [r8]
  mov     dl, byte ptr [r9]
  // map to lowercase
  cmp     al, 'A'
  jb      @@a_done
  cmp     al, 'Z'
  ja      @@a_done
  or      al, $20
@@a_done:
  cmp     dl, 'A'
  jb      @@d_done
  cmp     dl, 'Z'
  ja      @@d_done
  or      dl, $20
@@d_done:
  cmp     al, dl
  jne     @@ne
  inc     r8
  inc     r9
  dec     r10
  jnz     @@bloop
  jmp     @@eq
@@eq:
  mov     eax, 1
  vzeroupper
  ret
@@ne:
  xor     eax, eax
  vzeroupper
  ret
end;
{$ENDIF}


procedure ToLowerAscii_Scalar(p: Pointer; len: SizeUInt);
var
  i: SizeUInt;
  pb: PByte;
begin
  pb := PByte(p);
  for i := 0 to len-1 do
  begin
    if (pb[i] >= Ord('A')) and (pb[i] <= Ord('Z')) then
      pb[i] := pb[i] + 32;
  end;
end;

// 标量：ASCII 无大小写等价比较（'A'..'Z' -> 加 32 与 'a'..'z' 比较；非字母直接比较）
function AsciiEqualIgnoreCase_Scalar(a, b: Pointer; len: SizeUInt): LongBool;
var
  i: SizeUInt; pa, pb: PByte; xa, xb: Byte;
begin
  pa := PByte(a); pb := PByte(b);
  for i:=0 to len-1 do
  begin
    xa := pa[i]; xb := pb[i];
    if (xa >= Ord('A')) and (xa <= Ord('Z')) then Inc(xa, 32);
    if (xb >= Ord('A')) and (xb <= Ord('Z')) then Inc(xb, 32);
    if xa <> xb then Exit(False);
  end;
  Result := True;
end;



procedure ToUpperAscii_Scalar(p: Pointer; len: SizeUInt);
var
  i: SizeUInt;
  pb: PByte;
begin
  pb := PByte(p);



  for i := 0 to len-1 do
  begin
    if (pb[i] >= Ord('a')) and (pb[i] <= Ord('z')) then
      pb[i] := pb[i] - 32;
  end;
end;

end.

