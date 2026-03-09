// === ✅ P2-1: Saturating Arithmetic (SSE2 硬件加速) ===
// SSE2 提供专门的饱和算术指令，比标量实现快 8-16x

// I8x16 有符号饱和加法 (PADDSB)
function SSE2I8x16SatAdd(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  // x86-64 SysV ABI: a -> RDI, b -> RSI, Result -> RAX
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  paddsb xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  // Windows x64: a -> RCX, b -> RDX, Result -> RAX
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  paddsb xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// I8x16 有符号饱和减法 (PSUBSB)
function SSE2I8x16SatSub(const a, b: TVecI8x16): TVecI8x16; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  psubsb xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  psubsb xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// I16x8 有符号饱和加法 (PADDSW)
function SSE2I16x8SatAdd(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  paddsw xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  paddsw xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// I16x8 有符号饱和减法 (PSUBSW)
function SSE2I16x8SatSub(const a, b: TVecI16x8): TVecI16x8; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  psubsw xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  psubsw xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// U8x16 无符号饱和加法 (PADDUSB)
function SSE2U8x16SatAdd(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  paddusb xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  paddusb xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// U8x16 无符号饱和减法 (PSUBUSB)
function SSE2U8x16SatSub(const a, b: TVecU8x16): TVecU8x16; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  psubusb xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  psubusb xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// U16x8 无符号饱和加法 (PADDUSW)
function SSE2U16x8SatAdd(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  paddusw xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  paddusw xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

// U16x8 无符号饱和减法 (PSUBUSW)
function SSE2U16x8SatSub(const a, b: TVecU16x8): TVecU16x8; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movdqu xmm0, [rdi]
  movdqu xmm1, [rsi]
  psubusw xmm0, xmm1
  movdqu [rax], xmm0
  {$ELSE}
  movdqu xmm0, [rcx]
  movdqu xmm1, [rdx]
  psubusw xmm0, xmm1
  movdqu [rax], xmm0
  {$ENDIF}
end;

