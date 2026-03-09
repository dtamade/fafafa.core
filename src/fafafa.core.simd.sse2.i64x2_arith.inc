// === ✅ P3: I64x2 Arithmetic and Bitwise Operations (SSE2) ===
// SSE2 提供 paddq/psubq 用于 64-bit 整数运算

// I64x2 加法 (PADDQ)
function SSE2AddI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  paddq  xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  paddq  xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// I64x2 减法 (PSUBQ)
function SSE2SubI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  psubq  xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  psubq  xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// I64x2 位与 (PAND)
function SSE2AndI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  pand   xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  pand   xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// I64x2 位或 (POR)
function SSE2OrI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  por    xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  por    xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// I64x2 位异或 (PXOR)
function SSE2XorI64x2(const a, b: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  pxor   xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  pxor   xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// I64x2 位非 (PXOR with all 1s)
function SSE2NotI64x2(const a: TVecI64x2): TVecI64x2; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu  xmm0, [rdi]
  pcmpeqd xmm1, xmm1      // all 1s
  pxor    xmm0, xmm1      // NOT = XOR with all 1s
  movdqu  [rax], xmm0
  {$ELSE}
  movdqu  xmm0, [rcx]
  pcmpeqd xmm1, xmm1
  pxor    xmm0, xmm1
  movdqu  [rax], xmm0
  {$ENDIF}
end;

