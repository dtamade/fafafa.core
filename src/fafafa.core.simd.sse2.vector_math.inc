// === Vector Math Functions ===

// Dot product (4 elements)
function SSE2DotF32x4(const a, b: TVecF32x4): Single;
var
  pa, pb: Pointer;
begin
  pa := @a;
  pb := @b;
  asm
    mov     rax, pa
    mov     rdx, pb
    movups  xmm0, [rax]
    movups  xmm1, [rdx]
    mulps   xmm0, xmm1     // Element-wise multiply
    // Horizontal add: [a*b, c*d, e*f, g*h] -> sum
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $4E // Swap high/low pairs
    addps   xmm0, xmm1
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $B1 // Swap adjacent
    addss   xmm0, xmm1
    movss   [result], xmm0
  end;
end;

// Dot product (3 elements, ignore w)
function SSE2DotF32x3(const a, b: TVecF32x4): Single;
var
  t: TVecF32x4;
  pa, pb: Pointer;
begin
  pa := @a;
  pb := @b;
  asm
    mov     rax, pa
    mov     rdx, pb
    movups  xmm0, [rax]
    movups  xmm1, [rdx]
    mulps   xmm0, xmm1
    // Zero the w component before summing
    xorps   xmm1, xmm1
    movss   xmm1, xmm0     // xmm1 = [x, 0, 0, 0]
    shufps  xmm0, xmm0, $E9 // xmm0 = [y, z, z, w]
    addss   xmm1, xmm0     // x + y
    shufps  xmm0, xmm0, $E9
    addss   xmm1, xmm0     // x + y + z
    movss   [result], xmm1
  end;
end;

// Cross product (3D)
function SSE2CrossF32x3(const a, b: TVecF32x4): TVecF32x4;
var
  pa, pb, pr: Pointer;
begin
  // Cross = (a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x, 0)
  pa := @a;
  pb := @b;
  pr := @Result;
  asm
    mov     rax, pa
    mov     rdx, pb
    mov     rcx, pr
    movups  xmm0, [rax]        // a = [x, y, z, w]
    movups  xmm1, [rdx]        // b = [x, y, z, w]
    
    // Shuffle a: [y, z, x, w]
    movaps  xmm2, xmm0
    shufps  xmm2, xmm2, $C9    // 11 00 10 01 -> y,z,x,w
    
    // Shuffle b: [z, x, y, w]
    movaps  xmm3, xmm1
    shufps  xmm3, xmm3, $D2    // 11 01 00 10 -> z,x,y,w
    
    mulps   xmm2, xmm3         // [a.y*b.z, a.z*b.x, a.x*b.y, ...]
    
    // Shuffle a: [z, x, y, w]
    movaps  xmm4, xmm0
    shufps  xmm4, xmm4, $D2
    
    // Shuffle b: [y, z, x, w]
    movaps  xmm5, xmm1
    shufps  xmm5, xmm5, $C9
    
    mulps   xmm4, xmm5         // [a.z*b.y, a.x*b.z, a.y*b.x, ...]
    
    subps   xmm2, xmm4         // Subtract to get [x', y', z', w']
    
    movups  [rcx], xmm2
  end;
  Result.f[3] := 0.0; // Ensure w=0
end;

// Vector length (4 elements)
function SSE2LengthF32x4(const a: TVecF32x4): Single;
var
  pa: Pointer;
begin
  pa := @a;
  asm
    mov     rax, pa
    movups  xmm0, [rax]
    mulps   xmm0, xmm0      // Square each element
    // Horizontal add
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $4E
    addps   xmm0, xmm1
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $B1
    addss   xmm0, xmm1
    sqrtss  xmm0, xmm0      // Square root
    movss   [result], xmm0
  end;
end;

// Vector length (3 elements)
function SSE2LengthF32x3(const a: TVecF32x4): Single;
var
  pa: Pointer;
begin
  pa := @a;
  asm
    mov     rax, pa
    movups  xmm0, [rax]
    // Zero w before squaring
    pcmpeqd xmm1, xmm1
    psrldq  xmm1, 4          // Shift right to create mask [FF,FF,FF,00]
    andps   xmm0, xmm1       // Zero w
    mulps   xmm0, xmm0
    // Horizontal add
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $4E
    addps   xmm0, xmm1
    movaps  xmm1, xmm0
    shufps  xmm1, xmm1, $B1
    addss   xmm0, xmm1
    sqrtss  xmm0, xmm0
    movss   [result], xmm0
  end;
end;

// Normalize vector (4 elements)
function SSE2NormalizeF32x4(const a: TVecF32x4): TVecF32x4;
var
  pa, pr: Pointer;
  len: Single;
begin
  len := SSE2LengthF32x4(a);
  if len > 0 then
  begin
    pa := @a;
    pr := @Result;
    asm
      mov     rax, pa
      mov     rcx, pr
      movups  xmm0, [rax]
      movss   xmm1, len
      shufps  xmm1, xmm1, 0   // Broadcast length
      divps   xmm0, xmm1      // Divide each element by length
      movups  [rcx], xmm0
    end;
  end
  else
    Result := a;
end;

// Normalize vector (3 elements, w=0)
function SSE2NormalizeF32x3(const a: TVecF32x4): TVecF32x4;
var
  pa, pr: Pointer;
  len: Single;
begin
  len := SSE2LengthF32x3(a);
  if len > 0 then
  begin
    pa := @a;
    pr := @Result;
    asm
      mov     rax, pa
      mov     rcx, pr
      movups  xmm0, [rax]
      movss   xmm1, len
      shufps  xmm1, xmm1, 0
      divps   xmm0, xmm1
      movups  [rcx], xmm0
    end;
    Result.f[3] := 0.0;
  end
  else
  begin
    Result := a;
    Result.f[3] := 0.0;
  end;
end;

// ✅ F32x8 扩展函数 (2026-02-05) - 使用 2x F32x4 仿真

function SSE2FmaF32x8(const a, b, c: TVecF32x8): TVecF32x8;
{$IFDEF CPUX64}
var pa, pb, pc, pr: Pointer;
begin
  pa := @a; pb := @b; pc := @c; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    r8,  pc
    mov    rcx, pr
    // Load a
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    // Load b
    movups xmm2, [rdx]
    movups xmm3, [rdx+16]
    // Multiply a * b
    mulps  xmm0, xmm2
    mulps  xmm1, xmm3
    // Load c
    movups xmm4, [r8]
    movups xmm5, [r8+16]
    // Add c
    addps  xmm0, xmm4
    addps  xmm1, xmm5
    // Store
    movups [rcx], xmm0
    movups [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2FmaF32x4(a.lo, b.lo, c.lo);
  Result.hi := SSE2FmaF32x4(a.hi, b.hi, c.hi);
{$ENDIF}
end;

// ✅ SIMD Quality Iteration 6.3: F32x8 舍入操作 SSE2 ASM 实现
function SSE2FloorF32x8(const a: TVecF32x8): TVecF32x8;
{$IFDEF CPUX64}
var
  pa, pr: Pointer;
  LIndex: Integer;
const
  OneSingle: array[0..3] of Single = (1.0, 1.0, 1.0, 1.0);
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr

    // 加载低 4 个 float
    movups xmm0, [rax]
    // 加载高 4 个 float
    movups xmm4, [rax+16]

    // === 处理低 4 个元素 (xmm0) ===
    // 保存原值
    movaps xmm1, xmm0
    // 截断转整数
    cvttps2dq xmm0, xmm0
    // 转回浮点
    cvtdq2ps xmm0, xmm0
    // 比较: 原值 < 截断值？
    movaps xmm2, xmm1
    cmpltps xmm2, xmm0
    // 加载 1.0
    movups xmm3, [rip + OneSingle]
    // 掩码 & 1.0
    andps  xmm2, xmm3
    // 减去修正值
    subps  xmm0, xmm2

    // === 处理高 4 个元素 (xmm4) ===
    // 保存原值
    movaps xmm5, xmm4
    // 截断转整数
    cvttps2dq xmm4, xmm4
    // 转回浮点
    cvtdq2ps xmm4, xmm4
    // 比较: 原值 < 截断值？
    movaps xmm6, xmm5
    cmpltps xmm6, xmm4
    // 掩码 & 1.0
    andps  xmm6, xmm3
    // 减去修正值
    subps  xmm4, xmm6

    // 保存结果
    movups [rcx], xmm0
    movups [rcx+16], xmm4
  end;
{$ELSE}
var
  LIndex: Integer;
begin
  Result.lo := SSE2FloorF32x4(a.lo);
  Result.hi := SSE2FloorF32x4(a.hi);
{$ENDIF}
  for LIndex := 0 to 7 do
    if IsNan(a.f[LIndex]) or IsInfinite(a.f[LIndex]) then
      Result.f[LIndex] := a.f[LIndex];
end;

function SSE2CeilF32x8(const a: TVecF32x8): TVecF32x8;
{$IFDEF CPUX64}
var
  pa, pr: Pointer;
  LIndex: Integer;
const
  OneSingle: array[0..3] of Single = (1.0, 1.0, 1.0, 1.0);
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr

    // 加载低 4 个 float
    movups xmm0, [rax]
    // 加载高 4 个 float
    movups xmm4, [rax+16]

    // === 处理低 4 个元素 (xmm0) ===
    // 保存原值
    movaps xmm1, xmm0
    // 截断转整数
    cvttps2dq xmm0, xmm0
    // 转回浮点
    cvtdq2ps xmm0, xmm0
    // 比较: 截断值 < 原值？
    cmpltps xmm0, xmm1
    // 加载 1.0
    movups xmm3, [rip + OneSingle]
    // 掩码 & 1.0
    andps  xmm0, xmm3
    // 重新加载截断值
    movaps xmm2, xmm1
    cvttps2dq xmm2, xmm2
    cvtdq2ps xmm2, xmm2
    // 加上修正值
    addps  xmm0, xmm2

    // === 处理高 4 个元素 (xmm4) ===
    // 保存原值
    movaps xmm5, xmm4
    // 截断转整数
    cvttps2dq xmm4, xmm4
    // 转回浮点
    cvtdq2ps xmm4, xmm4
    // 比较: 截断值 < 原值？
    cmpltps xmm4, xmm5
    // 掩码 & 1.0
    andps  xmm4, xmm3
    // 重新加载截断值
    movaps xmm6, xmm5
    cvttps2dq xmm6, xmm6
    cvtdq2ps xmm6, xmm6
    // 加上修正值
    addps  xmm4, xmm6

    // 保存结果
    movups [rcx], xmm0
    movups [rcx+16], xmm4
  end;
{$ELSE}
var
  LIndex: Integer;
begin
  Result.lo := SSE2CeilF32x4(a.lo);
  Result.hi := SSE2CeilF32x4(a.hi);
{$ENDIF}
  for LIndex := 0 to 7 do
    if IsNan(a.f[LIndex]) or IsInfinite(a.f[LIndex]) then
      Result.f[LIndex] := a.f[LIndex];
end;

function SSE2RoundF32x8(const a: TVecF32x8): TVecF32x8;
begin
  Result.lo := SSE2RoundF32x4(a.lo);
  Result.hi := SSE2RoundF32x4(a.hi);
end;

function SSE2TruncF32x8(const a: TVecF32x8): TVecF32x8;
begin
  Result.lo := SSE2TruncF32x4(a.lo);
  Result.hi := SSE2TruncF32x4(a.hi);
end;

function SSE2AbsF32x8(const a: TVecF32x8): TVecF32x8;
{$IFDEF CPUX64}
var pa, pr: Pointer;
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    // Create sign mask (0x7FFFFFFF)
    pcmpeqd xmm2, xmm2       // all 1s
    psrld   xmm2, 1           // clear sign bit
    movaps  xmm3, xmm2
    // Clear sign bits
    andps   xmm0, xmm2
    andps   xmm1, xmm3
    movups  [rcx], xmm0
    movups  [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2AbsF32x4(a.lo);
  Result.hi := SSE2AbsF32x4(a.hi);
{$ENDIF}
end;

function SSE2SqrtF32x8(const a: TVecF32x8): TVecF32x8;
{$IFDEF CPUX64}
var pa, pr: Pointer;
begin
  pa := @a; pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    sqrtps xmm0, xmm0
    sqrtps xmm1, xmm1
    movups [rcx], xmm0
    movups [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2SqrtF32x4(a.lo);
  Result.hi := SSE2SqrtF32x4(a.hi);
{$ENDIF}
end;

function SSE2MinF32x8(const a, b: TVecF32x8): TVecF32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    movups xmm2, [rdx]
    movups xmm3, [rdx+16]
    minps  xmm0, xmm2
    minps  xmm1, xmm3
    movups [rcx], xmm0
    movups [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2MinF32x4(a.lo, b.lo);
  Result.hi := SSE2MinF32x4(a.hi, b.hi);
{$ENDIF}
end;

function SSE2MaxF32x8(const a, b: TVecF32x8): TVecF32x8;
{$IFDEF CPUX64}
var pa, pb, pr: Pointer;
begin
  pa := @a; pb := @b; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pr
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    movups xmm2, [rdx]
    movups xmm3, [rdx+16]
    maxps  xmm0, xmm2
    maxps  xmm1, xmm3
    movups [rcx], xmm0
    movups [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2MaxF32x4(a.lo, b.lo);
  Result.hi := SSE2MaxF32x4(a.hi, b.hi);
{$ENDIF}
end;

function SSE2ClampF32x8(const a, minVal, maxVal: TVecF32x8): TVecF32x8;
{$IFDEF CPUX64}
var pa, pmin, pmax, pr: Pointer;
begin
  pa := @a; pmin := @minVal; pmax := @maxVal; pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pmin
    mov    r8,  pmax
    mov    rcx, pr
    // Load a
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    // Load minVal
    movups xmm2, [rdx]
    movups xmm3, [rdx+16]
    // Max with minVal
    maxps  xmm0, xmm2
    maxps  xmm1, xmm3
    // Load maxVal
    movups xmm4, [r8]
    movups xmm5, [r8+16]
    // Min with maxVal
    minps  xmm0, xmm4
    minps  xmm1, xmm5
    // Store
    movups [rcx], xmm0
    movups [rcx+16], xmm1
  end;
{$ELSE}
begin
  Result.lo := SSE2ClampF32x4(a.lo, minVal.lo, maxVal.lo);
  Result.hi := SSE2ClampF32x4(a.hi, minVal.hi, maxVal.hi);
{$ENDIF}
end;

function SSE2ReduceAddF32x8(const a: TVecF32x8): Single;
{$IFDEF CPUX64}
var pa: Pointer; res: Single;
begin
  pa := @a;
  asm
    mov    rax, pa
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    // Merge lo + hi
    addps  xmm0, xmm1
    // Horizontal add (SSE3 style, but we use SSE2 shuffles)
    movaps xmm1, xmm0
    shufps xmm1, xmm1, $4E      // swap high/low 64-bit
    addps  xmm0, xmm1
    movaps xmm1, xmm0
    shufps xmm1, xmm1, $B1      // swap adjacent pairs
    addps  xmm0, xmm1
    movss  res, xmm0
  end;
  Result := res;
{$ELSE}
begin
  Result := SSE2ReduceAddF32x4(a.lo) + SSE2ReduceAddF32x4(a.hi);
{$ENDIF}
end;

function SSE2ReduceMinF32x8(const a: TVecF32x8): Single;
{$IFDEF CPUX64}
var pa: Pointer; res: Single;
begin
  pa := @a;
  asm
    mov    rax, pa
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    // Merge lo + hi with min
    minps  xmm0, xmm1
    // Horizontal min
    movaps xmm1, xmm0
    shufps xmm1, xmm1, $4E
    minps  xmm0, xmm1
    movaps xmm1, xmm0
    shufps xmm1, xmm1, $B1
    minps  xmm0, xmm1
    movss  res, xmm0
  end;
  Result := res;
{$ELSE}
var
  lo, hi: Single;
begin
  lo := SSE2ReduceMinF32x4(a.lo);
  hi := SSE2ReduceMinF32x4(a.hi);
  if lo < hi then Result := lo else Result := hi;
{$ENDIF}
end;

function SSE2ReduceMaxF32x8(const a: TVecF32x8): Single;
{$IFDEF CPUX64}
var pa: Pointer; res: Single;
begin
  pa := @a;
  asm
    mov    rax, pa
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    // Merge lo + hi with max
    maxps  xmm0, xmm1
    // Horizontal max
    movaps xmm1, xmm0
    shufps xmm1, xmm1, $4E
    maxps  xmm0, xmm1
    movaps xmm1, xmm0
    shufps xmm1, xmm1, $B1
    maxps  xmm0, xmm1
    movss  res, xmm0
  end;
  Result := res;
{$ELSE}
var
  lo, hi: Single;
begin
  lo := SSE2ReduceMaxF32x4(a.lo);
  hi := SSE2ReduceMaxF32x4(a.hi);
  if lo > hi then Result := lo else Result := hi;
{$ENDIF}
end;

function SSE2ReduceMulF32x8(const a: TVecF32x8): Single;
{$IFDEF CPUX64}
var pa: Pointer; res: Single;
begin
  pa := @a;
  asm
    mov    rax, pa
    movups xmm0, [rax]
    movups xmm1, [rax+16]
    // Merge lo * hi
    mulps  xmm0, xmm1
    // Horizontal mul
    movaps xmm1, xmm0
    shufps xmm1, xmm1, $4E
    mulps  xmm0, xmm1
    movaps xmm1, xmm0
    shufps xmm1, xmm1, $B1
    mulps  xmm0, xmm1
    movss  res, xmm0
  end;
  Result := res;
{$ELSE}
begin
  Result := SSE2ReduceMulF32x4(a.lo) * SSE2ReduceMulF32x4(a.hi);
{$ENDIF}
end;

function SSE2LoadF32x8(p: PSingle): TVecF32x8;
begin
  Result.lo := SSE2LoadF32x4(p);
  Result.hi := SSE2LoadF32x4(p + 4);
end;

procedure SSE2StoreF32x8(p: PSingle; const a: TVecF32x8);
begin
  SSE2StoreF32x4(p, a.lo);
  SSE2StoreF32x4(p + 4, a.hi);
end;

function SSE2SplatF32x8(value: Single): TVecF32x8;
begin
  Result.lo := SSE2SplatF32x4(value);
  Result.hi := SSE2SplatF32x4(value);
end;

function SSE2ZeroF32x8: TVecF32x8;
begin
  Result.lo := SSE2ZeroF32x4;
  Result.hi := SSE2ZeroF32x4;
end;

