// === Extended Math Functions ===

// FMA emulation: a*b + c (SSE2 has no native FMA)
function SSE2FmaF32x4(const a, b, c: TVecF32x4): TVecF32x4;
var
  pa, pb, pc, pr: Pointer;
begin
  pa := @a;
  pb := @b;
  pc := @c;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pb
    mov    rcx, pc
    mov    r8, pr
    movups xmm0, [rax]
    movups xmm1, [rdx]
    movups xmm2, [rcx]
    mulps  xmm0, xmm1
    addps  xmm0, xmm2
    movups [r8], xmm0
  end;
end;

// Reciprocal approximation (1/x)
function SSE2RcpF32x4(const a: TVecF32x4): TVecF32x4;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movups xmm0, [rax]
    rcpps  xmm0, xmm0     // Approximate reciprocal (12-bit precision)
    movups [rcx], xmm0
  end;
end;

// Reciprocal square root approximation (1/sqrt(x))
function SSE2RsqrtF32x4(const a: TVecF32x4): TVecF32x4;
var
  pa, pr: Pointer;
begin
  pa := @a;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rcx, pr
    movups xmm0, [rax]
    rsqrtps xmm0, xmm0    // Approximate rsqrt (12-bit precision)
    movups [rcx], xmm0
  end;
end;

// Floor/Ceil/Round/Trunc: Use SSE4.1 roundps if available, otherwise scalar fallback
// SSE4.1 roundps immediate values:
//   0 = Round to nearest (even)
//   1 = Round toward negative infinity (floor)
//   2 = Round toward positive infinity (ceil) 
//   3 = Round toward zero (truncate)

var
  g_HasSSE41: Boolean = False;
  g_SSE41CheckState: LongInt = 0; // 0=未检查, 1=检查中, 2=已完成

// ✅ Thread-safe SSE4.1 detection using atomic operations
procedure CheckSSE41;
var
  oldState: LongInt;
begin
  // 快速路径: 已完成检查
  if g_SSE41CheckState = 2 then Exit;

  oldState := InterlockedCompareExchange(g_SSE41CheckState, 1, 0);
  if oldState = 0 then
  begin
    // 我们是第一个检查者
    g_HasSSE41 := HasSSE41;
    WriteBarrier;
    InterlockedExchange(g_SSE41CheckState, 2);
  end
  else if oldState = 1 then
  begin
    // 另一个线程正在检查，自旋等待
    while g_SSE41CheckState <> 2 do
    begin
      ReadBarrier;
      ThreadSwitch;
    end;
  end;
  // oldState = 2: 已完成，直接返回
end;

function SSE2FloorF32x4(const a: TVecF32x4): TVecF32x4;
var
  pa, pr: Pointer;
  i: Integer;
begin
  CheckSSE41;
  if g_HasSSE41 then
  begin
    pa := @a;
    pr := @Result;
    asm
      mov    rax, pa
      mov    rcx, pr
      movups xmm0, [rax]
      // roundps xmm0, xmm0, 1  (floor)
      db $66, $0F, $3A, $08, $C0, $01
      movups [rcx], xmm0
    end;
  end
  else
  begin
    for i := 0 to 3 do
    begin
      // Preserve IEEE754 exceptional values instead of converting through Int().
      if IsNan(a.f[i]) or IsInfinite(a.f[i]) then
      begin
        Result.f[i] := a.f[i];
        Continue;
      end;

      Result.f[i] := Int(a.f[i]);
      if (a.f[i] < 0) and (Result.f[i] <> a.f[i]) then
        Result.f[i] := Result.f[i] - 1.0;
    end;
  end;
end;

function SSE2CeilF32x4(const a: TVecF32x4): TVecF32x4;
var
  pa, pr: Pointer;
  i: Integer;
begin
  CheckSSE41;
  if g_HasSSE41 then
  begin
    pa := @a;
    pr := @Result;
    asm
      mov    rax, pa
      mov    rcx, pr
      movups xmm0, [rax]
      // roundps xmm0, xmm0, 2  (ceil)
      db $66, $0F, $3A, $08, $C0, $02
      movups [rcx], xmm0
    end;
  end
  else
  begin
    for i := 0 to 3 do
    begin
      // Preserve IEEE754 exceptional values instead of converting through Int().
      if IsNan(a.f[i]) or IsInfinite(a.f[i]) then
      begin
        Result.f[i] := a.f[i];
        Continue;
      end;

      Result.f[i] := Int(a.f[i]);
      if (a.f[i] > 0) and (Result.f[i] <> a.f[i]) then
        Result.f[i] := Result.f[i] + 1.0;
    end;
  end;
end;

function SSE2RoundF32x4(const a: TVecF32x4): TVecF32x4;
var
  pa, pr: Pointer;
  i: Integer;
  LBits: DWord;
begin
  CheckSSE41;
  if g_HasSSE41 then
  begin
    pa := @a;
    pr := @Result;
    asm
      mov    rax, pa
      mov    rcx, pr
      movups xmm0, [rax]
      // roundps xmm0, xmm0, 0  (round to nearest even)
      db $66, $0F, $3A, $08, $C0, $00
      movups [rcx], xmm0
    end;
  end
  else
  begin
    LBits := 0;
    for i := 0 to 3 do
    begin
      // Preserve IEEE754 exceptional values instead of forcing scalar conversion.
      if IsNan(a.f[i]) or IsInfinite(a.f[i]) then
        Result.f[i] := a.f[i]
      else
      begin
        Result.f[i] := Round(a.f[i]);
        if Result.f[i] = 0.0 then
        begin
          Move(a.f[i], LBits, SizeOf(LBits));
          if (LBits and DWord($80000000)) <> 0 then
            Result.f[i] := -0.0;
        end;
      end;
    end;
  end;
end;

function SSE2TruncF32x4(const a: TVecF32x4): TVecF32x4;
var
  pa, pr: Pointer;
  i: Integer;
  LBits: DWord;
begin
  CheckSSE41;
  if g_HasSSE41 then
  begin
    pa := @a;
    pr := @Result;
    asm
      mov    rax, pa
      mov    rcx, pr
      movups xmm0, [rax]
      // roundps xmm0, xmm0, 3  (truncate)
      db $66, $0F, $3A, $08, $C0, $03
      movups [rcx], xmm0
    end;
  end
  else
  begin
    LBits := 0;
    for i := 0 to 3 do
    begin
      // Preserve IEEE754 exceptional values instead of forcing Int() conversion.
      if IsNan(a.f[i]) or IsInfinite(a.f[i]) then
        Result.f[i] := a.f[i]
      else
      begin
        Result.f[i] := Int(a.f[i]);
        if Result.f[i] = 0.0 then
        begin
          Move(a.f[i], LBits, SizeOf(LBits));
          if (LBits and DWord($80000000)) <> 0 then
            Result.f[i] := -0.0;
        end;
      end;
    end;
  end;
end;

// Clamp using SSE2 min/max
function SSE2ClampF32x4(const a, minVal, maxVal: TVecF32x4): TVecF32x4;
var
  pa, pMin, pMax, pr: Pointer;
begin
  pa := @a;
  pMin := @minVal;
  pMax := @maxVal;
  pr := @Result;
  asm
    mov    rax, pa
    mov    rdx, pMin
    mov    rcx, pMax
    mov    r8, pr
    movups xmm0, [rax]
    movups xmm1, [rdx]
    movups xmm2, [rcx]
    maxps  xmm0, xmm1     // max(a, minVal)
    minps  xmm0, xmm2     // min(result, maxVal)
    movups [r8], xmm0
  end;
end;

