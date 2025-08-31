unit fafafa.core.simd.ops.x86;

{$I fafafa.core.settings.inc}

interface

{$IFDEF SIMD_X86_AVAILABLE}

uses
  fafafa.core.simd.types;

// === x86 SIMD 操作实现 ===

// 单精度浮点向量操作 (SSE)
function X86_VecF32x4_Add(const a, b: TVecF32x4): TVecF32x4;
function X86_VecF32x4_Sub(const a, b: TVecF32x4): TVecF32x4;
function X86_VecF32x4_Mul(const a, b: TVecF32x4): TVecF32x4;
function X86_VecF32x4_Div(const a, b: TVecF32x4): TVecF32x4;

// 向量加载和存储
function X86_VecF32x4_Load(const ptr: Pointer): TVecF32x4;
procedure X86_VecF32x4_Store(const vec: TVecF32x4; ptr: Pointer);
function X86_VecF32x4_LoadUnaligned(const ptr: Pointer): TVecF32x4;
procedure X86_VecF32x4_StoreUnaligned(const vec: TVecF32x4; ptr: Pointer);

// 向量创建
function X86_VecF32x4_Set(x, y, z, w: Single): TVecF32x4;
function X86_VecF32x4_SetAll(value: Single): TVecF32x4;
function X86_VecF32x4_Zero: TVecF32x4;

// 向量数学函数
function X86_VecF32x4_Sqrt(const a: TVecF32x4): TVecF32x4;
function X86_VecF32x4_Min(const a, b: TVecF32x4): TVecF32x4;
function X86_VecF32x4_Max(const a, b: TVecF32x4): TVecF32x4;

implementation

uses
  fafafa.core.simd.cpuinfo.x86;

// === SSE 实现 ===

function X86_VecF32x4_Add(const a, b: TVecF32x4): TVecF32x4;
begin
  if HasSSE then
  begin
    // 使用 SSE addps 指令
    asm
      movups xmm0, a
      movups xmm1, b
      addps xmm0, xmm1
      movups Result, xmm0
    end;
  end
  else
  begin
    // 标量回退
    Result.f[0] := a.f[0] + b.f[0];
    Result.f[1] := a.f[1] + b.f[1];
    Result.f[2] := a.f[2] + b.f[2];
    Result.f[3] := a.f[3] + b.f[3];
  end;
end;

function X86_VecF32x4_Sub(const a, b: TVecF32x4): TVecF32x4;
begin
  if HasSSE then
  begin
    // 使用 SSE subps 指令
    asm
      movups xmm0, a
      movups xmm1, b
      subps xmm0, xmm1
      movups Result, xmm0
    end;
  end
  else
  begin
    // 标量回退
    Result.f[0] := a.f[0] - b.f[0];
    Result.f[1] := a.f[1] - b.f[1];
    Result.f[2] := a.f[2] - b.f[2];
    Result.f[3] := a.f[3] - b.f[3];
  end;
end;

function X86_VecF32x4_Mul(const a, b: TVecF32x4): TVecF32x4;
begin
  if HasSSE then
  begin
    // 使用 SSE mulps 指令
    asm
      movups xmm0, a
      movups xmm1, b
      mulps xmm0, xmm1
      movups Result, xmm0
    end;
  end
  else
  begin
    // 标量回退
    Result.f[0] := a.f[0] * b.f[0];
    Result.f[1] := a.f[1] * b.f[1];
    Result.f[2] := a.f[2] * b.f[2];
    Result.f[3] := a.f[3] * b.f[3];
  end;
end;

function X86_VecF32x4_Div(const a, b: TVecF32x4): TVecF32x4;
begin
  if HasSSE then
  begin
    // 使用 SSE divps 指令
    asm
      movups xmm0, a
      movups xmm1, b
      divps xmm0, xmm1
      movups Result, xmm0
    end;
  end
  else
  begin
    // 标量回退
    Result.f[0] := a.f[0] / b.f[0];
    Result.f[1] := a.f[1] / b.f[1];
    Result.f[2] := a.f[2] / b.f[2];
    Result.f[3] := a.f[3] / b.f[3];
  end;
end;

function X86_VecF32x4_Load(const ptr: Pointer): TVecF32x4;
begin
  if HasSSE then
  begin
    // 使用 SSE movaps 指令（对齐加载）
    asm
      mov rax, ptr
      movaps xmm0, [rax]
      movups Result, xmm0
    end;
  end
  else
  begin
    // 标量回退
    Move(ptr^, Result, SizeOf(TVecF32x4));
  end;
end;

procedure X86_VecF32x4_Store(const vec: TVecF32x4; ptr: Pointer);
begin
  if HasSSE then
  begin
    // 使用 SSE movaps 指令（对齐存储）
    asm
      movups xmm0, vec
      mov rax, ptr
      movaps [rax], xmm0
    end;
  end
  else
  begin
    // 标量回退
    Move(vec, ptr^, SizeOf(TVecF32x4));
  end;
end;

function X86_VecF32x4_LoadUnaligned(const ptr: Pointer): TVecF32x4;
begin
  if HasSSE then
  begin
    // 使用 SSE movups 指令（非对齐加载）
    asm
      mov rax, ptr
      movups xmm0, [rax]
      movups Result, xmm0
    end;
  end
  else
  begin
    // 标量回退
    Move(ptr^, Result, SizeOf(TVecF32x4));
  end;
end;

procedure X86_VecF32x4_StoreUnaligned(const vec: TVecF32x4; ptr: Pointer);
begin
  if HasSSE then
  begin
    // 使用 SSE movups 指令（非对齐存储）
    asm
      movups xmm0, vec
      mov rax, ptr
      movups [rax], xmm0
    end;
  end
  else
  begin
    // 标量回退
    Move(vec, ptr^, SizeOf(TVecF32x4));
  end;
end;

function X86_VecF32x4_Set(x, y, z, w: Single): TVecF32x4;
begin
  // 直接设置值（标量方式，因为 SSE 的 set 指令比较复杂）
  Result.f[0] := x;
  Result.f[1] := y;
  Result.f[2] := z;
  Result.f[3] := w;
end;

function X86_VecF32x4_SetAll(value: Single): TVecF32x4;
begin
  if HasSSE then
  begin
    // 使用 SSE 广播单个值
    asm
      movss xmm0, value
      shufps xmm0, xmm0, 0  // 广播到所有通道
      movups Result, xmm0
    end;
  end
  else
  begin
    // 标量回退
    Result.f[0] := value;
    Result.f[1] := value;
    Result.f[2] := value;
    Result.f[3] := value;
  end;
end;

function X86_VecF32x4_Zero: TVecF32x4;
begin
  if HasSSE then
  begin
    // 使用 SSE xorps 指令清零
    asm
      xorps xmm0, xmm0
      movups Result, xmm0
    end;
  end
  else
  begin
    // 标量回退
    FillChar(Result, SizeOf(Result), 0);
  end;
end;

function X86_VecF32x4_Sqrt(const a: TVecF32x4): TVecF32x4;
begin
  if HasSSE then
  begin
    // 使用 SSE sqrtps 指令
    asm
      movups xmm0, a
      sqrtps xmm0, xmm0
      movups Result, xmm0
    end;
  end
  else
  begin
    // 标量回退
    Result.f[0] := Sqrt(a.f[0]);
    Result.f[1] := Sqrt(a.f[1]);
    Result.f[2] := Sqrt(a.f[2]);
    Result.f[3] := Sqrt(a.f[3]);
  end;
end;

function X86_VecF32x4_Min(const a, b: TVecF32x4): TVecF32x4;
begin
  if HasSSE then
  begin
    // 使用 SSE minps 指令
    asm
      movups xmm0, a
      movups xmm1, b
      minps xmm0, xmm1
      movups Result, xmm0
    end;
  end
  else
  begin
    // 标量回退
    if a.f[0] < b.f[0] then Result.f[0] := a.f[0] else Result.f[0] := b.f[0];
    if a.f[1] < b.f[1] then Result.f[1] := a.f[1] else Result.f[1] := b.f[1];
    if a.f[2] < b.f[2] then Result.f[2] := a.f[2] else Result.f[2] := b.f[2];
    if a.f[3] < b.f[3] then Result.f[3] := a.f[3] else Result.f[3] := b.f[3];
  end;
end;

function X86_VecF32x4_Max(const a, b: TVecF32x4): TVecF32x4;
begin
  if HasSSE then
  begin
    // 使用 SSE maxps 指令
    asm
      movups xmm0, a
      movups xmm1, b
      maxps xmm0, xmm1
      movups Result, xmm0
    end;
  end
  else
  begin
    // 标量回退
    if a.f[0] > b.f[0] then Result.f[0] := a.f[0] else Result.f[0] := b.f[0];
    if a.f[1] > b.f[1] then Result.f[1] := a.f[1] else Result.f[1] := b.f[1];
    if a.f[2] > b.f[2] then Result.f[2] := a.f[2] else Result.f[2] := b.f[2];
    if a.f[3] > b.f[3] then Result.f[3] := a.f[3] else Result.f[3] := b.f[3];
  end;
end;

{$ENDIF} // SIMD_X86_AVAILABLE

end.
