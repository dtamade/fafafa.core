// === SSE2 Memory Functions ===

function MemEqual_SSE2(a, b: Pointer; len: SizeUInt): LongBool;
var
  pa, pb: PByte;
  i: SizeUInt;
  maskA, maskB: Integer;
begin
  {$PUSH}{$Q-}{$R-}  // Disable overflow/range checks for SIMD loop
  if len = 0 then
  begin
    Result := True;
    Exit;
  end;

  if (a = nil) or (b = nil) then
  begin
    Result := (a = b);
    Exit;
  end;

  pa := PByte(a);
  pb := PByte(b);
  i := 0;

  // Process 16 bytes at a time using SSE2
  while i + 16 <= len do
  begin
    asm
      mov   rax, pa
      mov   rdx, pb
      add   rax, i
      add   rdx, i
      movdqu xmm0, [rax]
      movdqu xmm1, [rdx]
      pcmpeqb xmm0, xmm1
      pmovmskb eax, xmm0
      mov   maskA, eax
    end;

    if maskA <> $FFFF then
    begin
      Result := False;
      Exit;
    end;

    Inc(i, 16);
  end;

  // Handle remaining bytes
  while i < len do
  begin
    if pa[i] <> pb[i] then
    begin
      Result := False;
      Exit;
    end;
    Inc(i);
  end;

  Result := True;
  {$POP}
end;

function MemFindByte_SSE2(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
var
  pb: PByte;
  i: SizeUInt;
  mask: Integer;
  bitPos: Integer;
begin
  if (len = 0) or (p = nil) then
  begin
    Result := -1;
    Exit;
  end;

  pb := PByte(p);
  i := 0;

  // Process 16 bytes at a time using SSE2
  while i + 16 <= len do
  begin
    asm
      mov      rax, pb
      add      rax, i
      movzx    edx, value
      movd     xmm1, edx
      punpcklbw xmm1, xmm1
      pshuflw  xmm1, xmm1, 0
      punpcklqdq xmm1, xmm1  // Broadcast value to all 16 bytes
      movdqu   xmm0, [rax]
      pcmpeqb  xmm0, xmm1
      pmovmskb eax, xmm0
      mov      mask, eax
    end;

    if mask <> 0 then
    begin
      // Find first set bit
      asm
        bsf eax, mask
        mov bitPos, eax
      end;
      Result := PtrInt(i) + bitPos;
      Exit;
    end;

    Inc(i, 16);
  end;

  // Handle remaining bytes
  while i < len do
  begin
    if pb[i] = value then
    begin
      Result := PtrInt(i);
      Exit;
    end;
    Inc(i);
  end;

  Result := -1;
end;

procedure MemCopy_SSE2(src, dst: Pointer; len: SizeUInt); assembler; nostackframe;
asm
  {$IFDEF UNIX}
  // RDI = src, RSI = dst, RDX = len
  test rdx, rdx
  jz @done
  test rdi, rdi
  jz @done
  test rsi, rsi
  jz @done
  cmp rdi, rsi
  je @done

  xor rcx, rcx           // i = 0

@loop16:
  lea rax, [rcx + 16]
  cmp rax, rdx
  ja @remainder
  movdqu xmm0, [rdi + rcx]
  movdqu [rsi + rcx], xmm0
  add rcx, 16
  jmp @loop16

@remainder:
  cmp rcx, rdx
  jae @done
  mov al, [rdi + rcx]
  mov [rsi + rcx], al
  inc rcx
  jmp @remainder

@done:
  {$ELSE}
  // Windows x64: RCX = src, RDX = dst, R8 = len
  test r8, r8
  jz @done
  test rcx, rcx
  jz @done
  test rdx, rdx
  jz @done
  cmp rcx, rdx
  je @done

  xor r9, r9            // i = 0

@loop16:
  lea rax, [r9 + 16]
  cmp rax, r8
  ja @remainder
  movdqu xmm0, [rcx + r9]
  movdqu [rdx + r9], xmm0
  add r9, 16
  jmp @loop16

@remainder:
  cmp r9, r8
  jae @done
  mov al, [rcx + r9]
  mov [rdx + r9], al
  inc r9
  jmp @remainder

@done:
  {$ENDIF}
end;

procedure MemSet_SSE2(dst: Pointer; len: SizeUInt; value: Byte); assembler; nostackframe;
asm
  {$IFDEF UNIX}
  // RDI = dst, RSI = len, RDX = value
  test rsi, rsi
  jz @done
  test rdi, rdi
  jz @done

  // Broadcast value to all 16 bytes
  movd xmm0, edx
  punpcklbw xmm0, xmm0
  pshuflw xmm0, xmm0, 0
  punpcklqdq xmm0, xmm0

  xor rcx, rcx           // i = 0

@loop16:
  lea rax, [rcx + 16]
  cmp rax, rsi
  ja @remainder
  movdqu [rdi + rcx], xmm0
  add rcx, 16
  jmp @loop16

@remainder:
  cmp rcx, rsi
  jae @done
  mov [rdi + rcx], dl
  inc rcx
  jmp @remainder

@done:
  {$ELSE}
  // Windows x64: RCX = dst, RDX = len, R8 = value
  test rdx, rdx
  jz @done
  test rcx, rcx
  jz @done

  // Broadcast value to all 16 bytes
  movzx r8d, r8b
  movd xmm0, r8d
  punpcklbw xmm0, xmm0
  pshuflw xmm0, xmm0, 0
  punpcklqdq xmm0, xmm0

  xor r9, r9             // i = 0
  mov al, r8b

@loop16:
  lea rax, [r9 + 16]
  cmp rax, rdx
  ja @remainder
  movdqu [rcx + r9], xmm0
  add r9, 16
  jmp @loop16

@remainder:
  cmp r9, rdx
  jae @done
  mov [rcx + r9], al
  inc r9
  jmp @remainder

@done:
  {$ENDIF}
end;

function SumBytes_SSE2(p: Pointer; len: SizeUInt): UInt64;
var
  pb: PByte;
  i: SizeUInt;
  sum0, sum1, sum2, sum3: UInt32;
begin
  {$PUSH}{$Q-}{$R-}  // Disable overflow/range checks for SIMD loop
  if (len = 0) or (p = nil) then
  begin
    Result := 0;
    Exit;
  end;

  pb := PByte(p);
  i := 0;
  sum0 := 0;
  sum1 := 0;
  sum2 := 0;
  sum3 := 0;

  // Process 16 bytes at a time using SSE2
  // Use psadbw (sum of absolute differences) with zero to sum bytes
  while i + 16 <= len do
  begin
    asm
      mov      rax, pb
      add      rax, i
      movdqu   xmm0, [rax]
      pxor     xmm1, xmm1      // Zero register
      psadbw   xmm0, xmm1      // Sum bytes: result in low 16 bits of each 64-bit lane
      movd     eax, xmm0       // Get lower 64-bit sum
      add      sum0, eax
      psrldq   xmm0, 8         // Shift right 8 bytes
      movd     eax, xmm0       // Get upper 64-bit sum
      add      sum1, eax
    end;
    Inc(i, 16);
  end;

  // Handle remaining bytes
  while i < len do
  begin
    Inc(sum2, pb[i]);
    Inc(i);
  end;

  Result := UInt64(sum0) + UInt64(sum1) + UInt64(sum2) + UInt64(sum3);
  {$POP}
end;

function CountByte_SSE2(p: Pointer; len: SizeUInt; value: Byte): SizeUInt; assembler; nostackframe;
// SysV: RDI = p, RSI = len, RDX = value
// Win64: RCX = p, RDX = len, R8 = value
// Use SWAR popcount for 16-bit mask
asm
  {$IFDEF UNIX}
  xor rax, rax           // count = 0
  test rsi, rsi
  jz @done
  test rdi, rdi
  jz @done

  // Broadcast value to all 16 bytes in xmm1
  movzx edx, dl
  movd xmm1, edx
  punpcklbw xmm1, xmm1
  pshuflw xmm1, xmm1, 0
  punpcklqdq xmm1, xmm1

  xor rcx, rcx           // i = 0

@loop16:
  lea r8, [rcx + 16]
  cmp r8, rsi
  ja @remainder
  movdqu xmm0, [rdi + rcx]
  pcmpeqb xmm0, xmm1
  pmovmskb r8d, xmm0
  // Popcount using SWAR
  mov r9d, r8d
  shr r9d, 1
  and r9d, $5555
  sub r8d, r9d
  mov r9d, r8d
  shr r9d, 2
  and r8d, $3333
  and r9d, $3333
  add r8d, r9d
  mov r9d, r8d
  shr r9d, 4
  add r8d, r9d
  and r8d, $0F0F
  mov r9d, r8d
  shr r9d, 8
  add r8d, r9d
  and r8d, $FF
  add rax, r8
  add rcx, 16
  jmp @loop16

@remainder:
  cmp rcx, rsi
  jae @done
  movzx r8d, byte ptr [rdi + rcx]
  cmp r8d, edx
  jne @skip
  inc rax
@skip:
  inc rcx
  jmp @remainder

@done:
  {$ELSE}
  xor rax, rax           // count = 0
  test rdx, rdx
  jz @done
  test rcx, rcx
  jz @done

  // Broadcast value to all 16 bytes in xmm1
  movzx r8d, r8b
  movd xmm1, r8d
  punpcklbw xmm1, xmm1
  pshuflw xmm1, xmm1, 0
  punpcklqdq xmm1, xmm1

  xor r9, r9             // i = 0

@loop16:
  lea r10, [r9 + 16]
  cmp r10, rdx
  ja @remainder
  movdqu xmm0, [rcx + r9]
  pcmpeqb xmm0, xmm1
  pmovmskb r10d, xmm0
  // Popcount using SWAR
  mov r11d, r10d
  shr r11d, 1
  and r11d, $5555
  sub r10d, r11d
  mov r11d, r10d
  shr r11d, 2
  and r10d, $3333
  and r11d, $3333
  add r10d, r11d
  mov r11d, r10d
  shr r11d, 4
  add r10d, r11d
  and r10d, $0F0F
  mov r11d, r10d
  shr r11d, 8
  add r10d, r11d
  and r10d, $FF
  add rax, r10
  add r9, 16
  jmp @loop16

@remainder:
  cmp r9, rdx
  jae @done
  movzx r10d, byte ptr [rcx + r9]
  cmp r10d, r8d
  jne @skip
  inc rax
@skip:
  inc r9
  jmp @remainder

@done:
  {$ENDIF}
end;

