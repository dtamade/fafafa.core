// === ✅ P1: Mask Operations SIMD Implementation ===
// 使用 bsf (bit scan forward) 和 SWAR popcount 加速
// Mask 类型是小整数（TMask2/4/8/16），可以用标量指令优化

// --- TMask2 Operations (2 bits) ---
function SSE2Mask2All(mask: TMask2): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  and   edi, 3        // 只保留低 2 位
  cmp   edi, 3        // 检查是否都为 1
  sete  al            // 设置结果
  {$ELSE}
  and   ecx, 3
  cmp   ecx, 3
  sete  al
  {$ENDIF}
end;

function SSE2Mask2Any(mask: TMask2): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  test  edi, 3        // 测试低 2 位
  setne al            // 任何位设置则为 true
  {$ELSE}
  test  ecx, 3
  setne al
  {$ENDIF}
end;

function SSE2Mask2None(mask: TMask2): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  test  edi, 3
  sete  al            // 没有位设置则为 true
  {$ELSE}
  test  ecx, 3
  sete  al
  {$ENDIF}
end;

function SSE2Mask2PopCount(mask: TMask2): Integer; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  and   edi, 3        // 只保留低 2 位
  mov   eax, edi
  shr   eax, 1        // 第二位移到位 0
  and   eax, 1        // 取第二位
  and   edi, 1        // 取第一位
  add   eax, edi      // 相加
  {$ELSE}
  and   ecx, 3
  mov   eax, ecx
  shr   eax, 1
  and   eax, 1
  and   ecx, 1
  add   eax, ecx
  {$ENDIF}
end;

function SSE2Mask2FirstSet(mask: TMask2): Integer; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  and   edi, 3        // 只保留低 2 位
  bsf   eax, edi      // 找第一个设置的位
  jnz   @done
  mov   eax, -1       // 没有设置的位
@done:
  {$ELSE}
  and   ecx, 3
  bsf   eax, ecx
  jnz   @done
  mov   eax, -1
@done:
  {$ENDIF}
end;

// --- TMask4 Operations (4 bits) ---
function SSE2Mask4All(mask: TMask4): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  and   edi, 15       // 只保留低 4 位
  cmp   edi, 15
  sete  al
  {$ELSE}
  and   ecx, 15
  cmp   ecx, 15
  sete  al
  {$ENDIF}
end;

function SSE2Mask4Any(mask: TMask4): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  test  edi, 15
  setne al
  {$ELSE}
  test  ecx, 15
  setne al
  {$ENDIF}
end;

function SSE2Mask4None(mask: TMask4): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  test  edi, 15
  sete  al
  {$ELSE}
  test  ecx, 15
  sete  al
  {$ENDIF}
end;

function SSE2Mask4PopCount(mask: TMask4): Integer; assembler; nostackframe;
// SWAR popcount for 4 bits
asm
  {$IFDEF UNIX}
  and   edi, 15
  mov   eax, edi
  shr   eax, 1
  and   eax, $5       // 0101 pattern
  sub   edi, eax
  mov   eax, edi
  shr   eax, 2
  and   edi, $3       // 0011 pattern
  and   eax, $3
  add   eax, edi
  {$ELSE}
  and   ecx, 15
  mov   eax, ecx
  shr   eax, 1
  and   eax, $5
  sub   ecx, eax
  mov   eax, ecx
  shr   eax, 2
  and   ecx, $3
  and   eax, $3
  add   eax, ecx
  {$ENDIF}
end;

function SSE2Mask4FirstSet(mask: TMask4): Integer; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  and   edi, 15
  bsf   eax, edi
  jnz   @done
  mov   eax, -1
@done:
  {$ELSE}
  and   ecx, 15
  bsf   eax, ecx
  jnz   @done
  mov   eax, -1
@done:
  {$ENDIF}
end;

// --- TMask8 Operations (8 bits) ---
function SSE2Mask8All(mask: TMask8): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  cmp   dil, $FF
  sete  al
  {$ELSE}
  cmp   cl, $FF
  sete  al
  {$ENDIF}
end;

function SSE2Mask8Any(mask: TMask8): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  test  dil, dil
  setne al
  {$ELSE}
  test  cl, cl
  setne al
  {$ENDIF}
end;

function SSE2Mask8None(mask: TMask8): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  test  dil, dil
  sete  al
  {$ELSE}
  test  cl, cl
  sete  al
  {$ENDIF}
end;

function SSE2Mask8PopCount(mask: TMask8): Integer; assembler; nostackframe;
// SWAR popcount for 8 bits
asm
  {$IFDEF UNIX}
  movzx eax, dil
  mov   edx, eax
  shr   edx, 1
  and   edx, $55
  sub   eax, edx
  mov   edx, eax
  shr   edx, 2
  and   eax, $33
  and   edx, $33
  add   eax, edx
  mov   edx, eax
  shr   edx, 4
  add   eax, edx
  and   eax, $0F
  {$ELSE}
  movzx eax, cl
  mov   edx, eax
  shr   edx, 1
  and   edx, $55
  sub   eax, edx
  mov   edx, eax
  shr   edx, 2
  and   eax, $33
  and   edx, $33
  add   eax, edx
  mov   edx, eax
  shr   edx, 4
  add   eax, edx
  and   eax, $0F
  {$ENDIF}
end;

function SSE2Mask8FirstSet(mask: TMask8): Integer; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movzx edi, dil
  bsf   eax, edi
  jnz   @done
  mov   eax, -1
@done:
  {$ELSE}
  movzx ecx, cl
  bsf   eax, ecx
  jnz   @done
  mov   eax, -1
@done:
  {$ENDIF}
end;

// --- TMask16 Operations (16 bits) ---
function SSE2Mask16All(mask: TMask16): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  cmp   di, $FFFF
  sete  al
  {$ELSE}
  cmp   cx, $FFFF
  sete  al
  {$ENDIF}
end;

function SSE2Mask16Any(mask: TMask16): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  test  di, di
  setne al
  {$ELSE}
  test  cx, cx
  setne al
  {$ENDIF}
end;

function SSE2Mask16None(mask: TMask16): Boolean; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  test  di, di
  sete  al
  {$ELSE}
  test  cx, cx
  sete  al
  {$ENDIF}
end;

function SSE2Mask16PopCount(mask: TMask16): Integer; assembler; nostackframe;
// SWAR popcount for 16 bits
asm
  {$IFDEF UNIX}
  movzx eax, di
  mov   edx, eax
  shr   edx, 1
  and   edx, $5555
  sub   eax, edx
  mov   edx, eax
  shr   edx, 2
  and   eax, $3333
  and   edx, $3333
  add   eax, edx
  mov   edx, eax
  shr   edx, 4
  add   eax, edx
  and   eax, $0F0F
  mov   edx, eax
  shr   edx, 8
  add   eax, edx
  and   eax, $FF
  {$ELSE}
  movzx eax, cx
  mov   edx, eax
  shr   edx, 1
  and   edx, $5555
  sub   eax, edx
  mov   edx, eax
  shr   edx, 2
  and   eax, $3333
  and   edx, $3333
  add   eax, edx
  mov   edx, eax
  shr   edx, 4
  add   eax, edx
  and   eax, $0F0F
  mov   edx, eax
  shr   edx, 8
  add   eax, edx
  and   eax, $FF
  {$ENDIF}
end;

function SSE2Mask16FirstSet(mask: TMask16): Integer; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  movzx edi, di
  bsf   eax, edi
  jnz   @done
  mov   eax, -1
@done:
  {$ELSE}
  movzx ecx, cx
  bsf   eax, ecx
  jnz   @done
  mov   eax, -1
@done:
  {$ENDIF}
end;

