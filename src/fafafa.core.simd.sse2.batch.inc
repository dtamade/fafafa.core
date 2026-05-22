// ============================================================================
// SSE2 Batch Array Operations
// 策略: 主循环 2x 展开 (每次 8 个 float)，标量尾部处理剩余元素
// ============================================================================

procedure SSE2ArrayAddF32(aSrc1, aSrc2, aDst: PSingle; aCount: SizeUInt);
var
  i: SizeUInt;
  pS1, pS2, pD: PSingle;
begin
  {$PUSH}{$Q-}{$R-}
  if aCount = 0 then Exit;
  pS1 := aSrc1;
  pS2 := aSrc2;
  pD := aDst;
  i := 0;

  // 主循环: 2x 展开, 每次处理 8 个 float (2 x 128-bit)
  while i + 8 <= aCount do
  begin
    asm
      mov    rax, pS1
      mov    rdx, pS2
      mov    rcx, pD
      mov    r8, i
      shl    r8, 2          // i * sizeof(Single)
      movups xmm0, [rax + r8]
      movups xmm1, [rdx + r8]
      addps  xmm0, xmm1
      movups [rcx + r8], xmm0
      movups xmm2, [rax + r8 + 16]
      movups xmm3, [rdx + r8 + 16]
      addps  xmm2, xmm3
      movups [rcx + r8 + 16], xmm2
    end;
    Inc(i, 8);
  end;

  // 4-float 块处理
  if i + 4 <= aCount then
  begin
    asm
      mov    rax, pS1
      mov    rdx, pS2
      mov    rcx, pD
      mov    r8, i
      shl    r8, 2
      movups xmm0, [rax + r8]
      movups xmm1, [rdx + r8]
      addps  xmm0, xmm1
      movups [rcx + r8], xmm0
    end;
    Inc(i, 4);
  end;

  // 标量尾部
  while i < aCount do
  begin
    pD[i] := pS1[i] + pS2[i];
    Inc(i);
  end;
  {$POP}
end;

procedure SSE2ArrayMulF32(aSrc1, aSrc2, aDst: PSingle; aCount: SizeUInt);
var
  i: SizeUInt;
  pS1, pS2, pD: PSingle;
begin
  {$PUSH}{$Q-}{$R-}
  if aCount = 0 then Exit;
  pS1 := aSrc1;
  pS2 := aSrc2;
  pD := aDst;
  i := 0;

  while i + 8 <= aCount do
  begin
    asm
      mov    rax, pS1
      mov    rdx, pS2
      mov    rcx, pD
      mov    r8, i
      shl    r8, 2
      movups xmm0, [rax + r8]
      movups xmm1, [rdx + r8]
      mulps  xmm0, xmm1
      movups [rcx + r8], xmm0
      movups xmm2, [rax + r8 + 16]
      movups xmm3, [rdx + r8 + 16]
      mulps  xmm2, xmm3
      movups [rcx + r8 + 16], xmm2
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
      movups xmm0, [rax + r8]
      movups xmm1, [rdx + r8]
      mulps  xmm0, xmm1
      movups [rcx + r8], xmm0
    end;
    Inc(i, 4);
  end;

  while i < aCount do
  begin
    pD[i] := pS1[i] * pS2[i];
    Inc(i);
  end;
  {$POP}
end;

procedure SSE2ArrayMulScalarF32(aSrc, aDst: PSingle; aCount: SizeUInt; aScalar: Single);
var
  i: SizeUInt;
  pS, pD: PSingle;
  LScalar: Single;
begin
  {$PUSH}{$Q-}{$R-}
  if aCount = 0 then Exit;
  pS := aSrc;
  pD := aDst;
  LScalar := aScalar;
  i := 0;

  while i + 8 <= aCount do
  begin
    asm
      mov    rax, pS
      mov    rcx, pD
      mov    r8, i
      shl    r8, 2
      // 广播标量到 xmm4
      movss  xmm4, LScalar
      shufps xmm4, xmm4, 0
      movups xmm0, [rax + r8]
      mulps  xmm0, xmm4
      movups [rcx + r8], xmm0
      movups xmm1, [rax + r8 + 16]
      mulps  xmm1, xmm4
      movups [rcx + r8 + 16], xmm1
    end;
    Inc(i, 8);
  end;

  if i + 4 <= aCount then
  begin
    asm
      mov    rax, pS
      mov    rcx, pD
      mov    r8, i
      shl    r8, 2
      movss  xmm4, LScalar
      shufps xmm4, xmm4, 0
      movups xmm0, [rax + r8]
      mulps  xmm0, xmm4
      movups [rcx + r8], xmm0
    end;
    Inc(i, 4);
  end;

  while i < aCount do
  begin
    pD[i] := pS[i] * LScalar;
    Inc(i);
  end;
  {$POP}
end;

procedure SSE2ArrayAxpyF32(aAlpha: Single; aX, aY, aDst: PSingle; aCount: SizeUInt);
var
  i: SizeUInt;
  pX, pY, pD: PSingle;
  LAlpha: Single;
begin
  {$PUSH}{$Q-}{$R-}
  if aCount = 0 then Exit;
  pX := aX;
  pY := aY;
  pD := aDst;
  LAlpha := aAlpha;
  i := 0;

  // dst[i] = alpha * x[i] + y[i]
  while i + 8 <= aCount do
  begin
    asm
      mov    rax, pX
      mov    rdx, pY
      mov    rcx, pD
      mov    r8, i
      shl    r8, 2
      // 广播 alpha
      movss  xmm5, LAlpha
      shufps xmm5, xmm5, 0
      // 第一组: alpha * x + y
      movups xmm0, [rax + r8]
      mulps  xmm0, xmm5
      movups xmm1, [rdx + r8]
      addps  xmm0, xmm1
      movups [rcx + r8], xmm0
      // 第二组
      movups xmm2, [rax + r8 + 16]
      mulps  xmm2, xmm5
      movups xmm3, [rdx + r8 + 16]
      addps  xmm2, xmm3
      movups [rcx + r8 + 16], xmm2
    end;
    Inc(i, 8);
  end;

  if i + 4 <= aCount then
  begin
    asm
      mov    rax, pX
      mov    rdx, pY
      mov    rcx, pD
      mov    r8, i
      shl    r8, 2
      movss  xmm5, LAlpha
      shufps xmm5, xmm5, 0
      movups xmm0, [rax + r8]
      mulps  xmm0, xmm5
      movups xmm1, [rdx + r8]
      addps  xmm0, xmm1
      movups [rcx + r8], xmm0
    end;
    Inc(i, 4);
  end;

  while i < aCount do
  begin
    pD[i] := LAlpha * pX[i] + pY[i];
    Inc(i);
  end;
  {$POP}
end;

function SSE2ReduceSumF32(aSrc: PSingle; aCount: SizeUInt): Single;
var
  i: SizeUInt;
  pS: PSingle;
  acc0, acc1: Single;
begin
  {$PUSH}{$Q-}{$R-}
  if aCount = 0 then begin Result := 0; Exit; end;
  pS := aSrc;
  i := 0;
  acc0 := 0;
  acc1 := 0;

  // 主循环: 2 个累加器减少依赖链延迟, 每次处理 8 个 float
  if aCount >= 8 then
  begin
    asm
      mov    rax, pS
      mov    r8, i
      mov    r9, aCount
      xorps  xmm6, xmm6     // acc0 = 0
      xorps  xmm7, xmm7     // acc1 = 0

    @loop8:
      lea    rcx, [r8 + 8]
      cmp    rcx, r9
      ja     @done8
      mov    rdx, r8
      shl    rdx, 2
      movups xmm0, [rax + rdx]
      addps  xmm6, xmm0
      movups xmm1, [rax + rdx + 16]
      addps  xmm7, xmm1
      add    r8, 8
      jmp    @loop8

    @done8:
      // 合并两个累加器
      addps  xmm6, xmm7
      // 水平求和 xmm6
      movaps xmm0, xmm6
      shufps xmm0, xmm0, $4E
      addps  xmm6, xmm0
      movaps xmm0, xmm6
      shufps xmm0, xmm0, $B1
      addss  xmm6, xmm0
      movss  acc0, xmm6
      mov    i, r8
    end;
  end;

  // 4-float 块处理
  if i + 4 <= aCount then
  begin
    asm
      mov    rax, pS
      mov    r8, i
      shl    r8, 2
      movups xmm0, [rax + r8]
      movaps xmm1, xmm0
      shufps xmm1, xmm1, $4E
      addps  xmm0, xmm1
      movaps xmm1, xmm0
      shufps xmm1, xmm1, $B1
      addss  xmm0, xmm1
      movss  acc1, xmm0
    end;
    Inc(i, 4);
  end;

  Result := acc0 + acc1;

  // 标量尾部
  while i < aCount do
  begin
    Result := Result + pS[i];
    Inc(i);
  end;
  {$POP}
end;

function SSE2ReduceDotF32(aSrc1, aSrc2: PSingle; aCount: SizeUInt): Single;
var
  i: SizeUInt;
  pS1, pS2: PSingle;
  acc0, acc1: Single;
begin
  {$PUSH}{$Q-}{$R-}
  if aCount = 0 then begin Result := 0; Exit; end;
  pS1 := aSrc1;
  pS2 := aSrc2;
  i := 0;
  acc0 := 0;
  acc1 := 0;

  // 主循环: 2 个累加器, 每次处理 8 个 float
  if aCount >= 8 then
  begin
    asm
      mov    rax, pS1
      mov    rdx, pS2
      mov    r8, i
      mov    r9, aCount
      xorps  xmm6, xmm6     // acc0 = 0
      xorps  xmm7, xmm7     // acc1 = 0

    @loop8:
      lea    rcx, [r8 + 8]
      cmp    rcx, r9
      ja     @done8
      mov    r10, r8
      shl    r10, 2
      // 第一组: src1 * src2, 累加到 acc0
      movups xmm0, [rax + r10]
      movups xmm1, [rdx + r10]
      mulps  xmm0, xmm1
      addps  xmm6, xmm0
      // 第二组: 累加到 acc1
      movups xmm2, [rax + r10 + 16]
      movups xmm3, [rdx + r10 + 16]
      mulps  xmm2, xmm3
      addps  xmm7, xmm2
      add    r8, 8
      jmp    @loop8

    @done8:
      // 合并两个累加器
      addps  xmm6, xmm7
      // 水平求和
      movaps xmm0, xmm6
      shufps xmm0, xmm0, $4E
      addps  xmm6, xmm0
      movaps xmm0, xmm6
      shufps xmm0, xmm0, $B1
      addss  xmm6, xmm0
      movss  acc0, xmm6
      mov    i, r8
    end;
  end;

  // 4-float 块处理
  if i + 4 <= aCount then
  begin
    asm
      mov    rax, pS1
      mov    rdx, pS2
      mov    r8, i
      shl    r8, 2
      movups xmm0, [rax + r8]
      movups xmm1, [rdx + r8]
      mulps  xmm0, xmm1
      movaps xmm1, xmm0
      shufps xmm1, xmm1, $4E
      addps  xmm0, xmm1
      movaps xmm1, xmm0
      shufps xmm1, xmm1, $B1
      addss  xmm0, xmm1
      movss  acc1, xmm0
    end;
    Inc(i, 4);
  end;

  Result := acc0 + acc1;

  // 标量尾部
  while i < aCount do
  begin
    Result := Result + pS1[i] * pS2[i];
    Inc(i);
  end;
  {$POP}
end;
