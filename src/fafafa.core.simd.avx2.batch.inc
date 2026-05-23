// ============================================================================
// AVX2 Batch Array Operations
// 策略: 主循环 2x 展开 (每次 16 个 float, 2 x 256-bit)
//        中间层 8-float 块 (1 x 256-bit)
//        SSE2 回退 4-float 块 (1 x 128-bit)
//        标量尾部处理剩余 0-3 元素
// 注意: 每个函数末尾需要 vzeroupper 避免 AVX/SSE 转换惩罚
// ============================================================================

procedure AVX2ArrayAddF32(aSrc1, aSrc2, aDst: PSingle; aCount: SizeUInt);
var
  i: SizeUInt;
  pS1, pS2, pD: PSingle;
begin
  {$PUSH}{$Q-}{$R-}
  if aCount = 0 then Exit;
  pS1 := aSrc1; pS2 := aSrc2; pD := aDst;
  i := 0;

  while i + 16 <= aCount do
  begin
    asm
      mov    rax, pS1
      mov    rdx, pS2
      mov    rcx, pD
      mov    r8, i
      shl    r8, 2
      vmovups ymm0, [rax + r8]
      vmovups ymm1, [rdx + r8]
      vaddps  ymm0, ymm0, ymm1
      vmovups [rcx + r8], ymm0
      vmovups ymm2, [rax + r8 + 32]
      vmovups ymm3, [rdx + r8 + 32]
      vaddps  ymm2, ymm2, ymm3
      vmovups [rcx + r8 + 32], ymm2
    end;
    Inc(i, 16);
  end;

  if i + 8 <= aCount then
  begin
    asm
      mov    rax, pS1
      mov    rdx, pS2
      mov    rcx, pD
      mov    r8, i
      shl    r8, 2
      vmovups ymm0, [rax + r8]
      vmovups ymm1, [rdx + r8]
      vaddps  ymm0, ymm0, ymm1
      vmovups [rcx + r8], ymm0
    end;
    Inc(i, 8);
  end;

  if i + 4 <= aCount then
  begin
    asm
      mov    rax, pS1
      mov    rdx, pS2
      mov    rcx, pD
      mov    r8, i
      shl    r8, 2
      vmovups xmm0, [rax + r8]
      vmovups xmm1, [rdx + r8]
      vaddps  xmm0, xmm0, xmm1
      vmovups [rcx + r8], xmm0
    end;
    Inc(i, 4);
  end;

  while i < aCount do
  begin
    pD[i] := pS1[i] + pS2[i];
    Inc(i);
  end;

  asm vzeroupper end;
  {$POP}
end;

procedure AVX2ArrayMulF32(aSrc1, aSrc2, aDst: PSingle; aCount: SizeUInt);
var
  i: SizeUInt;
  pS1, pS2, pD: PSingle;
begin
  {$PUSH}{$Q-}{$R-}
  if aCount = 0 then Exit;
  pS1 := aSrc1; pS2 := aSrc2; pD := aDst;
  i := 0;

  while i + 16 <= aCount do
  begin
    asm
      mov    rax, pS1
      mov    rdx, pS2
      mov    rcx, pD
      mov    r8, i
      shl    r8, 2
      vmovups ymm0, [rax + r8]
      vmovups ymm1, [rdx + r8]
      vmulps  ymm0, ymm0, ymm1
      vmovups [rcx + r8], ymm0
      vmovups ymm2, [rax + r8 + 32]
      vmovups ymm3, [rdx + r8 + 32]
      vmulps  ymm2, ymm2, ymm3
      vmovups [rcx + r8 + 32], ymm2
    end;
    Inc(i, 16);
  end;

  if i + 8 <= aCount then
  begin
    asm
      mov    rax, pS1
      mov    rdx, pS2
      mov    rcx, pD
      mov    r8, i
      shl    r8, 2
      vmovups ymm0, [rax + r8]
      vmovups ymm1, [rdx + r8]
      vmulps  ymm0, ymm0, ymm1
      vmovups [rcx + r8], ymm0
    end;
    Inc(i, 8);
  end;

  if i + 4 <= aCount then
  begin
    asm
      mov    rax, pS1
      mov    rdx, pS2
      mov    rcx, pD
      mov    r8, i
      shl    r8, 2
      vmovups xmm0, [rax + r8]
      vmovups xmm1, [rdx + r8]
      vmulps  xmm0, xmm0, xmm1
      vmovups [rcx + r8], xmm0
    end;
    Inc(i, 4);
  end;

  while i < aCount do
  begin
    pD[i] := pS1[i] * pS2[i];
    Inc(i);
  end;

  asm vzeroupper end;
  {$POP}
end;

procedure AVX2ArrayMulScalarF32(aSrc, aDst: PSingle; aCount: SizeUInt; aScalar: Single);
var
  i: SizeUInt;
  pS, pD: PSingle;
  LScalar: Single;
begin
  {$PUSH}{$Q-}{$R-}
  if aCount = 0 then Exit;
  pS := aSrc; pD := aDst; LScalar := aScalar;
  i := 0;

  while i + 16 <= aCount do
  begin
    asm
      mov    rax, pS
      mov    rcx, pD
      mov    r8, i
      shl    r8, 2
      vmovss xmm4, [LScalar]
      vbroadcastss ymm4, xmm4
      vmovups ymm0, [rax + r8]
      vmulps  ymm0, ymm0, ymm4
      vmovups [rcx + r8], ymm0
      vmovups ymm1, [rax + r8 + 32]
      vmulps  ymm1, ymm1, ymm4
      vmovups [rcx + r8 + 32], ymm1
    end;
    Inc(i, 16);
  end;

  if i + 8 <= aCount then
  begin
    asm
      mov    rax, pS
      mov    rcx, pD
      mov    r8, i
      shl    r8, 2
      vmovss xmm4, [LScalar]
      vbroadcastss ymm4, xmm4
      vmovups ymm0, [rax + r8]
      vmulps  ymm0, ymm0, ymm4
      vmovups [rcx + r8], ymm0
    end;
    Inc(i, 8);
  end;

  while i < aCount do
  begin
    pD[i] := pS[i] * LScalar;
    Inc(i);
  end;

  asm vzeroupper end;
  {$POP}
end;

procedure AVX2ArrayAxpyF32(aAlpha: Single; aX, aY, aDst: PSingle; aCount: SizeUInt);
var
  i: SizeUInt;
  pX, pY, pD: PSingle;
  LAlpha: Single;
begin
  {$PUSH}{$Q-}{$R-}
  if aCount = 0 then Exit;
  pX := aX; pY := aY; pD := aDst; LAlpha := aAlpha;
  i := 0;

  while i + 16 <= aCount do
  begin
    asm
      mov    rax, pX
      mov    rdx, pY
      mov    rcx, pD
      mov    r8, i
      shl    r8, 2
      vmovss xmm5, [LAlpha]
      vbroadcastss ymm5, xmm5
      vmovups ymm0, [rax + r8]
      vmulps  ymm0, ymm0, ymm5
      vaddps  ymm0, ymm0, [rdx + r8]
      vmovups [rcx + r8], ymm0
      vmovups ymm1, [rax + r8 + 32]
      vmulps  ymm1, ymm1, ymm5
      vaddps  ymm1, ymm1, [rdx + r8 + 32]
      vmovups [rcx + r8 + 32], ymm1
    end;
    Inc(i, 16);
  end;

  if i + 8 <= aCount then
  begin
    asm
      mov    rax, pX
      mov    rdx, pY
      mov    rcx, pD
      mov    r8, i
      shl    r8, 2
      vmovss xmm5, [LAlpha]
      vbroadcastss ymm5, xmm5
      vmovups ymm0, [rax + r8]
      vmulps  ymm0, ymm0, ymm5
      vaddps  ymm0, ymm0, [rdx + r8]
      vmovups [rcx + r8], ymm0
    end;
    Inc(i, 8);
  end;

  while i < aCount do
  begin
    pD[i] := LAlpha * pX[i] + pY[i];
    Inc(i);
  end;

  asm vzeroupper end;
  {$POP}
end;

function AVX2ReduceSumF32(aSrc: PSingle; aCount: SizeUInt): Single;
var
  i: SizeUInt;
  pS: PSingle;
  LSum: Single;
begin
  {$PUSH}{$Q-}{$R-}
  if aCount = 0 then begin Result := 0; Exit; end;
  pS := aSrc;
  i := 0;
  LSum := 0;

  if aCount >= 16 then
  begin
    asm
      mov    rax, pS
      vxorps ymm0, ymm0, ymm0   // acc0
      vxorps ymm1, ymm1, ymm1   // acc1
    end;
    while i + 16 <= aCount do
    begin
      asm
        mov    rax, pS
        mov    r8, i
        shl    r8, 2
        vaddps ymm0, ymm0, [rax + r8]
        vaddps ymm1, ymm1, [rax + r8 + 32]
      end;
      Inc(i, 16);
    end;
    asm
      vaddps  ymm0, ymm0, ymm1          // merge accumulators
      // 256→128 reduce
      vextractf128 xmm1, ymm0, 1
      vaddps  xmm0, xmm0, xmm1
      // 128→scalar reduce
      vhaddps xmm0, xmm0, xmm0
      vhaddps xmm0, xmm0, xmm0
      vmovss  LSum, xmm0
    end;
  end;

  if i + 8 <= aCount then
  begin
    asm
      mov    rax, pS
      mov    r8, i
      shl    r8, 2
      vmovups ymm0, [rax + r8]
      vextractf128 xmm1, ymm0, 1
      vaddps  xmm0, xmm0, xmm1
      vhaddps xmm0, xmm0, xmm0
      vhaddps xmm0, xmm0, xmm0
      addss   xmm0, LSum
      movss   LSum, xmm0
    end;
    Inc(i, 8);
  end;

  while i < aCount do
  begin
    LSum := LSum + pS[i];
    Inc(i);
  end;

  asm vzeroupper end;
  Result := LSum;
  {$POP}
end;

function AVX2ReduceDotF32(aSrc1, aSrc2: PSingle; aCount: SizeUInt): Single;
var
  i: SizeUInt;
  pS1, pS2: PSingle;
  LSum: Single;
begin
  {$PUSH}{$Q-}{$R-}
  if aCount = 0 then begin Result := 0; Exit; end;
  pS1 := aSrc1; pS2 := aSrc2;
  i := 0;
  LSum := 0;

  if aCount >= 16 then
  begin
    asm
      vxorps ymm0, ymm0, ymm0
      vxorps ymm1, ymm1, ymm1
    end;
    while i + 16 <= aCount do
    begin
      asm
        mov    rax, pS1
        mov    rdx, pS2
        mov    r8, i
        shl    r8, 2
        vmovups ymm2, [rax + r8]
        vmulps  ymm2, ymm2, [rdx + r8]
        vaddps  ymm0, ymm0, ymm2
        vmovups ymm3, [rax + r8 + 32]
        vmulps  ymm3, ymm3, [rdx + r8 + 32]
        vaddps  ymm1, ymm1, ymm3
      end;
      Inc(i, 16);
    end;
    asm
      vaddps  ymm0, ymm0, ymm1
      vextractf128 xmm1, ymm0, 1
      vaddps  xmm0, xmm0, xmm1
      vhaddps xmm0, xmm0, xmm0
      vhaddps xmm0, xmm0, xmm0
      vmovss  LSum, xmm0
    end;
  end;

  if i + 8 <= aCount then
  begin
    asm
      mov    rax, pS1
      mov    rdx, pS2
      mov    r8, i
      shl    r8, 2
      vmovups ymm2, [rax + r8]
      vmulps  ymm2, ymm2, [rdx + r8]
      vextractf128 xmm1, ymm2, 1
      vaddps  xmm2, xmm2, xmm1
      vhaddps xmm2, xmm2, xmm2
      vhaddps xmm2, xmm2, xmm2
      addss   xmm2, LSum
      movss   LSum, xmm2
    end;
    Inc(i, 8);
  end;

  while i < aCount do
  begin
    LSum := LSum + pS1[i] * pS2[i];
    Inc(i);
  end;

  asm vzeroupper end;
  Result := LSum;
  {$POP}
end;
