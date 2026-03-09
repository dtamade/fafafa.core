// === ✅ I64x2 Comparison Operations (SSE2 emulation) ===
// SSE2 没有原生 64 位整数比较指令（PCMPEQQ 是 SSE4.1）
// 使用两个 32 位比较 + AND/OR 逻辑实现

// CmpEqI64x2: 使用两个 32 位比较 + AND
// 比较高 32 位和低 32 位是否都相等
// pcmpeqd xmm0, xmm1  // 32位比较
// pshufd xmm2, xmm0, 0xB1  // 交换每个 64 位元素内的高低 32 位
// pand xmm0, xmm2  // 两部分都相等才算相等
function SSE2CmpEqI64x2(const a, b: TVecI64x2): TMask2;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pcmpeqd xmm0, xmm1       // 32 位元素比较: [a0L==b0L, a0H==b0H, a1L==b1L, a1H==b1H]
    pshufd  xmm2, xmm0, $B1  // 交换高低 32 位: [a0H==b0H, a0L==b0L, a1H==b1H, a1L==b1L]
    pand    xmm0, xmm2       // 每个 64 位元素：高低都相等才为真
    movmskpd eax, xmm0       // 提取每个 64 位元素的符号位（位 63）
    mov    mask, eax
  end;
  Result := TMask2(mask);
end;

// CmpNeI64x2: NOT(CmpEq)
function SSE2CmpNeI64x2(const a, b: TVecI64x2): TMask2;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    movdqu xmm0, [rax]
    movdqu xmm1, [rdx]
    pcmpeqd xmm0, xmm1       // 32 位比较
    pshufd  xmm2, xmm0, $B1  // 交换高低 32 位
    pand    xmm0, xmm2       // AND
    pcmpeqd xmm3, xmm3       // 全 1
    pxor    xmm0, xmm3       // NOT
    movmskpd eax, xmm0
    mov    mask, eax
  end;
  Result := TMask2(mask);
end;

// CmpGtI64x2: 64 位有符号大于比较（SSE2 模拟）
// 算法: (a_high > b_high) || (a_high == b_high && a_low > b_low)
// 注意: 高 32 位使用有符号比较，低 32 位使用无符号比较
function SSE2CmpGtI64x2(const a, b: TVecI64x2): TMask2;
var
  pa, pb: Pointer;
  mask: Integer;
begin
  pa := @a;
  pb := @b;
  asm
    mov    rax, pa
    mov    rdx, pb
    movdqu xmm0, [rax]         // xmm0 = a = [a0L, a0H, a1L, a1H]
    movdqu xmm1, [rdx]         // xmm1 = b = [b0L, b0H, b1L, b1H]

    // Step 1: 计算 a_high > b_high (有符号 32 位比较)
    movdqa xmm2, xmm0
    pcmpgtd xmm2, xmm1         // xmm2 = [a0L>b0L?, a0H>b0H?, a1L>b1L?, a1H>b1H?]
    pshufd xmm3, xmm2, $F5     // xmm3 = [a0H>b0H?, a0H>b0H?, a1H>b1H?, a1H>b1H?] ($F5 = 11_11_01_01)

    // Step 2: 计算 a_high == b_high
    movdqa xmm4, xmm0
    pcmpeqd xmm4, xmm1         // xmm4 = [a0L==b0L?, a0H==b0H?, a1L==b1L?, a1H==b1H?]
    pshufd xmm5, xmm4, $F5     // xmm5 = [a0H==b0H?, a0H==b0H?, a1H==b1H?, a1H==b1H?]

    // Step 3: 计算 a_low > b_low (无符号比较)
    // 无符号比较技巧: 翻转符号位后用有符号比较
    // a_low >u b_low  <=>  (a_low ^ 0x80000000) >s (b_low ^ 0x80000000)
    movdqa xmm6, xmm0
    movdqa xmm7, xmm1
    // 准备 0x80000000 常量
    pcmpeqd xmm4, xmm4         // 全 1
    psrld   xmm4, 31           // 每个 dword = 1
    pslld   xmm4, 31           // 每个 dword = 0x80000000
    pxor    xmm6, xmm4         // 翻转 a 的符号位
    pxor    xmm7, xmm4         // 翻转 b 的符号位
    pcmpgtd xmm6, xmm7         // 无符号比较结果
    pshufd  xmm6, xmm6, $A0    // 只保留低 32 位结果 [a0L>b0L?, 0, a1L>b1L?, 0] ($A0 = 10_10_00_00)

    // Step 4: 组合结果
    // result = (a_high > b_high) || ((a_high == b_high) && (a_low > b_low))
    pand   xmm5, xmm6          // (a_high == b_high) && (a_low > b_low)
    por    xmm3, xmm5          // 最终结果

    // Step 5: 提取每个 64 位元素的最高位
    movmskpd eax, xmm3
    mov    mask, eax
  end;
  Result := TMask2(mask);
end;

// CmpLtI64x2: a < b = b > a
function SSE2CmpLtI64x2(const a, b: TVecI64x2): TMask2;
begin
  Result := SSE2CmpGtI64x2(b, a);
end;

// CmpGeI64x2: a >= b = NOT(a < b) = NOT(b > a)
function SSE2CmpGeI64x2(const a, b: TVecI64x2): TMask2;
begin
  Result := TMask2((not Byte(SSE2CmpGtI64x2(b, a))) and 3);
end;

// CmpLeI64x2: a <= b = NOT(a > b)
function SSE2CmpLeI64x2(const a, b: TVecI64x2): TMask2;
begin
  Result := TMask2((not Byte(SSE2CmpGtI64x2(a, b))) and 3);
end;

function SSE2AndNotI64x2(const a, b: TVecI64x2): TVecI64x2;
begin
  asm
    lea    rax, a
    lea    rdx, b
    movdqu xmm0, [rax]
    pandn  xmm0, [rdx]
    movdqu [result], xmm0
  end;
end;

function SSE2ShiftLeftI64x2(const a: TVecI64x2; count: Integer): TVecI64x2;
begin
  Result.i[0] := a.i[0] shl count;
  Result.i[1] := a.i[1] shl count;
end;

function SSE2ShiftRightI64x2(const a: TVecI64x2; count: Integer): TVecI64x2;
begin
  Result.i[0] := Int64(UInt64(a.i[0]) shr count);
  Result.i[1] := Int64(UInt64(a.i[1]) shr count);
end;

function SSE2ShiftRightArithI64x2(const a: TVecI64x2; count: Integer): TVecI64x2;
begin
  Result.i[0] := a.i[0] shr count;
  Result.i[1] := a.i[1] shr count;
end;

function SSE2MinI64x2(const a, b: TVecI64x2): TVecI64x2;
var
  LMask: TMask2;
begin
  LMask := SSE2CmpLtI64x2(a, b);
  if (LMask and 1) <> 0 then Result.i[0] := a.i[0] else Result.i[0] := b.i[0];
  if (LMask and 2) <> 0 then Result.i[1] := a.i[1] else Result.i[1] := b.i[1];
end;

function SSE2MaxI64x2(const a, b: TVecI64x2): TVecI64x2;
var
  LMask: TMask2;
begin
  LMask := SSE2CmpGtI64x2(a, b);
  if (LMask and 1) <> 0 then Result.i[0] := a.i[0] else Result.i[0] := b.i[0];
  if (LMask and 2) <> 0 then Result.i[1] := a.i[1] else Result.i[1] := b.i[1];
end;

function SSE2AddU64x2(const a, b: TVecU64x2): TVecU64x2;
begin
  Result.u[0] := a.u[0] + b.u[0];
  Result.u[1] := a.u[1] + b.u[1];
end;

function SSE2SubU64x2(const a, b: TVecU64x2): TVecU64x2;
begin
  Result.u[0] := a.u[0] - b.u[0];
  Result.u[1] := a.u[1] - b.u[1];
end;

function SSE2AndU64x2(const a, b: TVecU64x2): TVecU64x2;
begin
  Result.u[0] := a.u[0] and b.u[0];
  Result.u[1] := a.u[1] and b.u[1];
end;

function SSE2OrU64x2(const a, b: TVecU64x2): TVecU64x2;
begin
  Result.u[0] := a.u[0] or b.u[0];
  Result.u[1] := a.u[1] or b.u[1];
end;

function SSE2XorU64x2(const a, b: TVecU64x2): TVecU64x2;
begin
  Result.u[0] := a.u[0] xor b.u[0];
  Result.u[1] := a.u[1] xor b.u[1];
end;

function SSE2NotU64x2(const a: TVecU64x2): TVecU64x2;
begin
  Result.u[0] := not a.u[0];
  Result.u[1] := not a.u[1];
end;

function SSE2AndNotU64x2(const a, b: TVecU64x2): TVecU64x2;
begin
  Result.u[0] := (not a.u[0]) and b.u[0];
  Result.u[1] := (not a.u[1]) and b.u[1];
end;

function SSE2CmpEqU64x2(const a, b: TVecU64x2): TMask2;
begin
  Result := 0;
  if a.u[0] = b.u[0] then Result := Result or 1;
  if a.u[1] = b.u[1] then Result := Result or 2;
end;

function SSE2CmpLtU64x2(const a, b: TVecU64x2): TMask2;
const
  SIGN_MASK: QWord = QWord($8000000000000000);
var
  LAdjustedA, LAdjustedB: TVecI64x2;
begin
  LAdjustedA.i[0] := Int64(a.u[0] xor SIGN_MASK);
  LAdjustedA.i[1] := Int64(a.u[1] xor SIGN_MASK);
  LAdjustedB.i[0] := Int64(b.u[0] xor SIGN_MASK);
  LAdjustedB.i[1] := Int64(b.u[1] xor SIGN_MASK);
  Result := SSE2CmpLtI64x2(LAdjustedA, LAdjustedB);
end;

function SSE2CmpGtU64x2(const a, b: TVecU64x2): TMask2;
const
  SIGN_MASK: QWord = QWord($8000000000000000);
var
  LAdjustedA, LAdjustedB: TVecI64x2;
begin
  LAdjustedA.i[0] := Int64(a.u[0] xor SIGN_MASK);
  LAdjustedA.i[1] := Int64(a.u[1] xor SIGN_MASK);
  LAdjustedB.i[0] := Int64(b.u[0] xor SIGN_MASK);
  LAdjustedB.i[1] := Int64(b.u[1] xor SIGN_MASK);
  Result := SSE2CmpGtI64x2(LAdjustedA, LAdjustedB);
end;

function SSE2MinU64x2(const a, b: TVecU64x2): TVecU64x2;
var
  LMask: TMask2;
begin
  LMask := SSE2CmpLtU64x2(a, b);
  if (LMask and 1) <> 0 then Result.u[0] := a.u[0] else Result.u[0] := b.u[0];
  if (LMask and 2) <> 0 then Result.u[1] := a.u[1] else Result.u[1] := b.u[1];
end;

function SSE2MaxU64x2(const a, b: TVecU64x2): TVecU64x2;
var
  LMask: TMask2;
begin
  LMask := SSE2CmpGtU64x2(a, b);
  if (LMask and 1) <> 0 then Result.u[0] := a.u[0] else Result.u[0] := b.u[0];
  if (LMask and 2) <> 0 then Result.u[1] := a.u[1] else Result.u[1] := b.u[1];
end;

