// === Additional Facade Functions with SSE2 ===

// MinMax with SSE2
procedure MinMaxBytes_SSE2(p: Pointer; len: SizeUInt; out minVal, maxVal: Byte);
var
  pb: PByte;
  i: SizeUInt;
  minAcc, maxAcc: Integer;
begin
  if (len = 0) or (p = nil) then
  begin
    minVal := 0;
    maxVal := 0;
    Exit;
  end;

  pb := PByte(p);
  i := 0;
  minAcc := 255;
  maxAcc := 0;

  // Process 16 bytes at a time
  while i + 16 <= len do
  begin
    asm
      mov     rax, pb
      add     rax, i
      movdqu  xmm0, [rax]
      
      // Get min
      movdqa  xmm1, xmm0
      psrlw   xmm1, 8
      pminub  xmm0, xmm1
      movdqa  xmm1, xmm0
      psrld   xmm1, 16
      pminub  xmm0, xmm1
      movdqa  xmm1, xmm0
      psrlq   xmm1, 32
      pminub  xmm0, xmm1
      movdqa  xmm1, xmm0
      psrldq  xmm1, 8
      pminub  xmm0, xmm1
      movd    eax, xmm0
      and     eax, $FF
      cmp     eax, minAcc
      jge     @skipmin
      mov     minAcc, eax
    @skipmin:
      
      // Get max
      mov     rax, pb
      add     rax, i
      movdqu  xmm0, [rax]
      movdqa  xmm1, xmm0
      psrlw   xmm1, 8
      pmaxub  xmm0, xmm1
      movdqa  xmm1, xmm0
      psrld   xmm1, 16
      pmaxub  xmm0, xmm1
      movdqa  xmm1, xmm0
      psrlq   xmm1, 32
      pmaxub  xmm0, xmm1
      movdqa  xmm1, xmm0
      psrldq  xmm1, 8
      pmaxub  xmm0, xmm1
      movd    eax, xmm0
      and     eax, $FF
      cmp     eax, maxAcc
      jle     @skipmax
      mov     maxAcc, eax
    @skipmax:
    end;
    Inc(i, 16);
  end;

  // Handle remaining bytes
  while i < len do
  begin
    if pb[i] < minAcc then
      minAcc := pb[i];
    if pb[i] > maxAcc then
      maxAcc := pb[i];
    Inc(i);
  end;

  minVal := Byte(minAcc);
  maxVal := Byte(maxAcc);
end;

// Popcount with SSE2 (using lookup table)
function BitsetPopCount_SSE2(p: Pointer; len: SizeUInt): SizeUInt;
var
  pb: PByte;
  i: SizeUInt;
  count: SizeUInt;
  b: Byte;
const
  PopCountTable: array[0..15] of Byte = (
    0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4
  );
begin
  if (len = 0) or (p = nil) then
  begin
    Result := 0;
    Exit;
  end;

  pb := PByte(p);
  count := 0;
  i := 0;

  // Use SWAR technique for bulk processing
  while i + 8 <= len do
  begin
    asm
      mov     rax, pb
      add     rax, i
      mov     rdx, [rax]      // Load 8 bytes
      
      // SWAR popcount
      mov     rcx, rdx
      shr     rcx, 1
      mov     r8, $5555555555555555
      and     rcx, r8
      sub     rdx, rcx
      
      mov     rcx, rdx
      shr     rcx, 2
      mov     r8, $3333333333333333
      and     rdx, r8
      and     rcx, r8
      add     rdx, rcx
      
      mov     rcx, rdx
      shr     rcx, 4
      add     rdx, rcx
      mov     r8, $0F0F0F0F0F0F0F0F
      and     rdx, r8
      
      mov     r8, $0101010101010101
      imul    rdx, r8
      shr     rdx, 56
      
      add     count, rdx
    end;
    Inc(i, 8);
  end;

  // Handle remaining bytes
  while i < len do
  begin
    b := pb[i];
    Inc(count, PopCountTable[b and $0F] + PopCountTable[b shr 4]);
    Inc(i);
  end;

  Result := count;
end;

