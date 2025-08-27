unit fafafa.core.simd.mem;

{$mode objfpc}{$H+}
{$IFDEF CPUX86_64}{$asmmode intel}{$ENDIF}

interface
uses
  fafafa.core.simd.types;



function MemEqual_Scalar(a, b: Pointer; len: SizeUInt): LongBool;
function MemEqual_SSE2(a, b: Pointer; len: SizeUInt): LongBool; // x86_64 + SSE2 微内核
function MemEqual_AVX2(a, b: Pointer; len: SizeUInt): LongBool; // x86_64 + AVX2 微内核
function MemFindByte_Scalar(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
function MemFindByte_SSE2(p: Pointer; len: SizeUInt; value: Byte): PtrInt; // x86_64 + SSE2 微内核
function MemFindByte_AVX2(p: Pointer; len: SizeUInt; value: Byte): PtrInt; // x86_64 + AVX2 微内核
function MemDiffRange_Scalar(a, b: Pointer; len: SizeUInt): TDiffRange;
function MemDiffRange_SSE2(a, b: Pointer; len: SizeUInt): TDiffRange; // x86_64 + SSE2 微内核（混合实现）
function MemDiffRange_AVX2(a, b: Pointer; len: SizeUInt): TDiffRange; // x86_64 + AVX2 微内核

{$ifdef FAFAFA_SIMD_NO_ASM}
  {$define DISABLE_X86_ASM}
{$endif}

implementation

function MemEqual_Scalar(a, b: Pointer; len: SizeUInt): LongBool;
var
  i: SizeUInt;
  pa, pb: PByte;
begin
  {$IFDEF DEBUG}
  if len <> 0 then begin Assert(a<>nil, 'MemEqual_Scalar: a=nil'); Assert(b<>nil, 'MemEqual_Scalar: b=nil'); end;
  {$ENDIF}
  pa := PByte(a); pb := PByte(b);
  if len = 0 then begin Result := True; Exit; end;
  for i := 0 to len-1 do
  begin
    if pa[i] <> pb[i] then Exit(False);
  end;
  Result := True;
end;

{$IFDEF CPUX86_64}
// x86_64 + SSE2：使用 MOVDQU/PCMPEQB/PMOVMSKB 快速比较，每 16 字节一块；尾部回落标量
{$IFNDEF DISABLE_X86_ASM}
function MemEqual_SSE2(a, b: Pointer; len: SizeUInt): LongBool; assembler; nostackframe;
asm
  mov     r8,  qword ptr [a]
  mov     r9,  qword ptr [b]
  mov     r10, qword ptr [len]
  test    r10, r10
  jz      @@eq
  mov     rax, r10
  shr     rax, 4
  jz      @@tail
@@loop:
  movdqu  xmm0, [r8]
  movdqu  xmm1, [r9]
  pcmpeqb xmm0, xmm1
  pmovmskb eax, xmm0
  cmp     eax, 0FFFFh
  jne     @@ne
  add     r8, 16
  add     r9, 16
  dec     rax
  jnz     @@loop
@@tail:
  and     r10, 15
  jz      @@eq
@@tailloop:
  mov     al, byte ptr [r8]
  cmp     al, byte ptr [r9]
  jne     @@ne
  inc     r8
  inc     r9
  dec     r10
  jnz     @@tailloop
@@eq:
  mov     eax, 1
  ret
@@ne:
  xor     eax, eax
  ret
end;
{$ELSE}
function MemEqual_SSE2(a, b: Pointer; len: SizeUInt): LongBool;
begin
  Result := MemEqual_Scalar(a, b, len);
end;
{$ENDIF}

{$IFNDEF DISABLE_X86_ASM}
// x86_64 + AVX2：32 字节块比较（VMOVDQU/VPCMPEQB/VPMOVMSKB），必要处 vzeroupper；尾部回落 SSE2/标量
function MemEqual_AVX2(a, b: Pointer; len: SizeUInt): LongBool; assembler; nostackframe;
asm
  mov     r8,  qword ptr [a]
  mov     r9,  qword ptr [b]
  mov     r10, qword ptr [len]
  test    r10, r10
  jz      @@eq
  mov     rax, r10
  shr     rax, 5
  jz      @@tail_avx
@@loop_avx:
  vmovdqu ymm0, [r8]
  vmovdqu ymm1, [r9]
  vpcmpeqb ymm0, ymm0, ymm1
  vpmovmskb eax, ymm0
  cmp     eax, -1
  jne     @@ne
  add     r8, 32
  add     r9, 32
  dec     rax
  jnz     @@loop_avx
@@tail_avx:
  mov     rax, r10
  and     rax, 31
  jz      @@eq
  cmp     rax, 16
  jb      @@tail_bytes
  vzeroupper
  movdqu  xmm0, [r8]
  movdqu  xmm1, [r9]
  pcmpeqb xmm0, xmm1
  pmovmskb eax, xmm0
  cmp     eax, 0FFFFh
  jne     @@ne
  add     r8, 16
  add     r9, 16
  sub     rax, 16
  jz      @@eq
@@tail_bytes:
  mov     rcx, rax
@@tailloop:
  mov     al, byte ptr [r8]
  cmp     al, byte ptr [r9]
  jne     @@ne
  inc     r8
  inc     r9
  dec     rcx
  jnz     @@tailloop
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
{$ELSE}
function MemEqual_AVX2(a, b: Pointer; len: SizeUInt): LongBool;
begin
  Result := MemEqual_Scalar(a, b, len);
end;
{$ENDIF}
{$ENDIF}

function MemFindByte_Scalar(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
var
  i: SizeUInt;
  pb: PByte;
begin
  {$IFDEF DEBUG}
  if len <> 0 then Assert(p<>nil, 'MemFindByte_Scalar: p=nil');
  {$ENDIF}
  pb := PByte(p);
  if len = 0 then Exit(-1);
  for i := 0 to len-1 do
    if pb[i] = value then Exit(PtrInt(i));
  Result := -1;
end;

function MemDiffRange_Scalar(a, b: Pointer; len: SizeUInt): TDiffRange;
var
  i: SizeUInt;
  pa, pb: PByte;
  first, last: PtrInt;
begin
  {$IFDEF DEBUG}
  if len <> 0 then begin Assert(a<>nil, 'MemDiffRange_Scalar: a=nil'); Assert(b<>nil, 'MemDiffRange_Scalar: b=nil'); end;
  {$ENDIF}
  pa := PByte(a); pb := PByte(b);
  first := -1; last := -1;
  if len = 0 then begin Result.First := -1; Result.Last := -1; Exit; end;
  for i := 0 to len-1 do
  begin
    if pa[i] <> pb[i] then
    begin
      if first = -1 then first := PtrInt(i);
      last := PtrInt(i);
    end;
  end;
  Result.First := first;
  Result.Last := last;
end;


{$IFDEF CPUX86_64}
// x86_64 + SSE2：查找首个匹配字节；找不到返回 -1
{$IF (not Defined(DISABLE_X86_ASM)) or Defined(FAFAFA_SIMD_ENABLE_MEMFINDBYTE)}
function MemFindByte_SSE2(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
var
  val32: Cardinal;
begin
  val32 := value;
  asm
    mov     r8,  qword ptr [p]
    mov     r9,  qword ptr [len]
    mov     eax, dword ptr [val32]
    imul    eax, eax, 01010101h
    test    r9, r9
    jz      @@not_found
    movd    xmm1, eax
    pshufd  xmm1, xmm1, 0
    mov     r11d, eax
    mov     rcx, r9
    shr     rcx, 4
    jz      @@tail
    xor     rdx, rdx
  @@loop:
    movdqu  xmm0, [r8+rdx]
    pcmpeqb xmm0, xmm1
    pmovmskb eax, xmm0
    test    eax, eax
    jnz     @@found_in_block
    add     rdx, 16
    dec     rcx
    jnz     @@loop
  @@tail:
    and     r9, 15
    jz      @@not_found
  @@tailloop:
    mov     al, byte ptr [r8+rdx]
    cmp     al, r11b
    je      @@found_tail
    inc     rdx
    dec     r9
    jnz     @@tailloop
    jmp     @@not_found
  @@found_in_block:
    bsf     ecx, eax
    lea     rax, [rdx+rcx]
    mov     qword ptr [Result], rax
    jmp     @@exit
  @@found_tail:
    mov     rax, rdx
    mov     qword ptr [Result], rax
    jmp     @@exit
  @@not_found:
    mov     rax, -1
    mov     qword ptr [Result], rax
  @@exit:
  end;
end;
{$ELSE}
function MemFindByte_SSE2(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
begin
  Result := MemFindByte_Scalar(p, len, value);
end;
{$ENDIF}

// x86_64 + AVX2：查找首匹配字节（32B 宽），尾部 SSE2/字节
{$IF (not Defined(DISABLE_X86_ASM)) or Defined(FAFAFA_SIMD_ENABLE_MEMFINDBYTE)}
function MemFindByte_AVX2(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
var
  val32: Cardinal;
begin
  val32 := value;
  asm
    mov     r8,  qword ptr [p]
    mov     r9,  qword ptr [len]
    mov     eax, dword ptr [val32]
    imul    eax, eax, 01010101h
    mov     r11d, eax               // keep value in r11b for tail byte compare
    test    r9,  r9
    jz      @@not_found
    vzeroupper
    movd    xmm1, eax
    pshufd  xmm1, xmm1, 0
    vinsertf128 ymm1, ymm1, xmm1, 1
    mov     rcx, r9
    shr     rcx, 5
    jz      @@tail
    xor     rdx, rdx
  @@loop:
    vmovdqu ymm0, [r8+rdx]
    vpcmpeqb ymm0, ymm0, ymm1
    vpmovmskb eax, ymm0
    test    eax, eax
    jnz     @@found
    add     rdx, 32
    dec     rcx
    jnz     @@loop
  @@tail:
    and     r9, 31
    jz      @@not_found
    cmp     r9, 16
    jb      @@tail_bytes
    movdqu  xmm0, [r8+rdx]
    pcmpeqb xmm0, xmm1
    pmovmskb eax, xmm0
    test    eax, eax
    jnz     @@found_sse
    add     rdx, 16
    sub     r9, 16
    jz      @@not_found
  @@tail_bytes:
  @@tail_loop:
    mov     al, byte ptr [r8+rdx]
    cmp     al, r11b
    je      @@found_tail
    inc     rdx
    dec     r9
    jnz     @@tail_loop
    jmp     @@not_found
  @@found:
    bsf     ecx, eax
    lea     rax, [rdx+rcx]
    mov     qword ptr [Result], rax
    vzeroupper
    jmp     @@exit
  @@found_sse:
    bsf     ecx, eax
    lea     rax, [rdx+rcx]
    mov     qword ptr [Result], rax
    vzeroupper
    jmp     @@exit
  @@found_tail:
    mov     rax, rdx
    mov     qword ptr [Result], rax
    vzeroupper
    jmp     @@exit
  @@not_found:
    mov     rax, -1
    mov     qword ptr [Result], rax
    vzeroupper
  @@exit:
  end;
end;
{$ELSE}
function MemFindByte_AVX2(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
begin
  Result := MemFindByte_Scalar(p, len, value);
end;
{$ENDIF}
{$ENDIF}

{$IFDEF CPUX86_64}
// x86_64 + SSE2：前向/后向 16B 扫描 + 块内定位
{$IFNDEF DISABLE_X86_ASM}
function MemDiffRange_SSE2(a, b: Pointer; len: SizeUInt): TDiffRange; assembler; nostackframe;
asm
  mov     r8,  qword ptr [a]
  mov     r9,  qword ptr [b]
  mov     r10, qword ptr [len]
  push    rsi
  push    rdi
  mov     ecx, -1
  mov     edx, -1
  test    r10, r10
  jz      @@emit
  xor     r11, r11
  mov     rax, r10
  shr     rax, 4
  jz      @@tail_fwd
@@loop_fwd:
  movdqu  xmm0, [r8+r11]
  movdqu  xmm1, [r9+r11]
  pcmpeqb xmm0, xmm1
  pmovmskb eax, xmm0
  cmp     eax, 0FFFFh
  jne     @@found_fwd_blk
  add     r11, 16
  dec     rax
  jnz     @@loop_fwd
@@tail_fwd:
  mov     rax, r10
  and     rax, 15
  jz      @@after_first
  mov     rdx, r8
  add     rdx, r11
  mov     rsi, r9
  add     rsi, r11
  xor     rdi, rdi
@@tail_fwd_loop:
  mov     al, byte ptr [rdx+rdi]
  cmp     al, byte ptr [rsi+rdi]
  jne     @@set_first_tail
  inc     rdi
  dec     rax
  jnz     @@tail_fwd_loop
  jmp     @@after_first
@@set_first_tail:
  lea     ecx, [r11+rdi]
  jmp     @@scan_bwd
@@found_fwd_blk:
  not     eax
  and     eax, 0FFFFh
  bsf     ecx, eax
  lea     ecx, [r11+rcx]
@@scan_bwd:
  mov     rax, r10
  and     rax, 15
  mov     r11, r10
  sub     r11, rax
  test    rax, rax
  jz      @@bwd_blocks
  mov     rdx, r8
  add     rdx, r11
  mov     rsi, r9
  add     rsi, r11
  dec     rax
@@bwd_tail_loop:
  mov     al, byte ptr [rdx+rax]
  cmp     al, byte ptr [rsi+rax]
  jne     @@set_last_tail
  dec     rax
  jns     @@bwd_tail_loop
@@bwd_blocks:
  test    r11, r11
  jz      @@emit
  sub     r11, 16
@@loop_bwd:
  movdqu  xmm0, [r8+r11]
  movdqu  xmm1, [r9+r11]
  pcmpeqb xmm0, xmm1
  pmovmskb eax, xmm0
  cmp     eax, 0FFFFh
  jne     @@found_bwd_blk
  sub     r11, 16
  jns     @@loop_bwd
  jmp     @@emit
@@found_bwd_blk:
  not     eax
  and     eax, 0FFFFh
  bsr     edx, eax
  add     edx, r11d
  jmp     @@emit
@@set_last_tail:
  lea     edx, [r11+rax]
  jmp     @@emit
@@after_first:
  cmp     ecx, -1
  jne     @@scan_bwd
  jmp     @@all_equal
@@emit:
  mov     dword ptr [Result], ecx
  mov     dword ptr [Result+4], edx
  pop     rdi
  pop     rsi
  ret
@@all_equal:
  mov     dword ptr [Result], -1
  mov     dword ptr [Result+4], -1
  pop     rdi
  pop     rsi
  ret
end;
{$ELSE}
function MemDiffRange_SSE2(a, b: Pointer; len: SizeUInt): TDiffRange;
begin
  Result := MemDiffRange_Scalar(a, b, len);
end;
{$ENDIF}

// x86_64 + AVX2：32B 块扫描 + 块内定位；尾部策略同 SSE2
{$IFNDEF DISABLE_X86_ASM}
function MemDiffRange_AVX2(a, b: Pointer; len: SizeUInt): TDiffRange; assembler; nostackframe;
asm
  mov     r8,  qword ptr [a]
  mov     r9,  qword ptr [b]
  mov     r10, qword ptr [len]
  // preserve non-volatile registers used below (Win64): rsi, rdi
  push    rsi
  push    rdi
  mov     ecx, -1
  mov     edx, -1
  test    r10, r10
  jz      @@emit
  xor     r11, r11
  mov     rax, r10
  shr     rax, 5
  jz      @@tail_fwd
@@loop_fwd32:
  vmovdqu ymm0, [r8+r11]
  vmovdqu ymm1, [r9+r11]
  vpcmpeqb ymm0, ymm0, ymm1
  vpmovmskb eax, ymm0
  cmp     eax, -1
  jne     @@found_fwd_blk
  add     r11, 32
  dec     rax
  jnz     @@loop_fwd32
@@tail_fwd:
  mov     rax, r10
  and     rax, 31
  jz      @@after_first
  cmp     rax, 16
  jb      @@tail_bytes
  movdqu  xmm0, [r8+r11]
  movdqu  xmm1, [r9+r11]
  pcmpeqb xmm0, xmm1
  pmovmskb eax, xmm0
  cmp     eax, 0FFFFh
  jne     @@found_fwd_sse
  add     r11, 16
  sub     rax, 16
  jz      @@after_first
@@tail_bytes:
  mov     rsi, r8
  add     rsi, r11
  mov     rdi, r9
  add     rdi, r11
  xor     rdx, rdx
@@tail_loop:
  test    rax, rax
  jz      @@after_first
  mov     al, byte ptr [rsi+rdx]
  cmp     al, byte ptr [rdi+rdx]
  jne     @@set_first_tail
  inc     rdx
  dec     rax
  jmp     @@tail_loop
@@set_first_tail:
  lea     ecx, [r11+rdx]
  jmp     @@scan_bwd
@@found_fwd_blk:
  not     eax
  bsf     ecx, eax
  lea     ecx, [r11+rcx]
  jmp     @@scan_bwd
@@found_fwd_sse:
  not     eax
  and     eax, 0FFFFh
  bsf     ecx, eax
  lea     ecx, [r11+rcx]
@@scan_bwd:
  mov     rax, r10
  and     rax, 31
  mov     r11, r10
  sub     r11, rax
  test    rax, rax
  jz      @@bwd_blocks
  dec     rax
  mov     rsi, r8
  add     rsi, r11
  mov     rdi, r9
  add     rdi, r11
@@bwd_tail:
  mov     al, byte ptr [rsi+rax]
  cmp     al, byte ptr [rdi+rax]
  jne     @@set_last_tail
  dec     rax
  jns     @@bwd_tail
@@bwd_blocks:
  test    r11, r11
  jz      @@emit
  sub     r11, 32
@@loop_bwd32:
  vmovdqu ymm0, [r8+r11]
  vmovdqu ymm1, [r9+r11]
  vpcmpeqb ymm0, ymm0, ymm1
  vpmovmskb eax, ymm0
  cmp     eax, -1
  jne     @@found_bwd_blk
  sub     r11, 32
  jns     @@loop_bwd32
  jmp     @@emit
@@found_bwd_blk:
  not     eax
  bsr     edx, eax
  add     edx, r11d
  jmp     @@emit
@@set_last_tail:
  lea     edx, [r11+rax]
  jmp     @@emit
@@after_first:
  cmp     ecx, -1
  jne     @@scan_bwd
  jmp     @@all_equal
@@emit:
  mov     dword ptr [Result], ecx
  mov     dword ptr [Result+4], edx
  vzeroupper
  pop     rdi
  pop     rsi
  ret
@@all_equal:
  mov     dword ptr [Result], -1
  mov     dword ptr [Result+4], -1
  vzeroupper
  pop     rdi
  pop     rsi
  ret
end;
{$ELSE}
function MemDiffRange_AVX2(a, b: Pointer; len: SizeUInt): TDiffRange;
begin
  Result := MemDiffRange_Scalar(a, b, len);
end;
{$ENDIF}
{$ENDIF}

end.

