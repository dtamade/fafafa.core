unit fafafa.core.simd.ops.avx;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

{$IFDEF SIMD_X86_AVAILABLE}

uses
  fafafa.core.simd.types;

// === AVX 256-bit 向量操作 ===

// 单精度浮点向量操�?(256-bit, 8 个元�?
function AVX_VecF32x8_Add(const a, b: TVecF32x8): TVecF32x8;
function AVX_VecF32x8_Sub(const a, b: TVecF32x8): TVecF32x8;
function AVX_VecF32x8_Mul(const a, b: TVecF32x8): TVecF32x8;
function AVX_VecF32x8_Div(const a, b: TVecF32x8): TVecF32x8;

// 双精度浮点向量操�?(256-bit, 4 个元�?
function AVX_VecF64x4_Add(const a, b: TVecF64x4): TVecF64x4;
function AVX_VecF64x4_Sub(const a, b: TVecF64x4): TVecF64x4;
function AVX_VecF64x4_Mul(const a, b: TVecF64x4): TVecF64x4;
function AVX_VecF64x4_Div(const a, b: TVecF64x4): TVecF64x4;

// 向量加载和存�?function AVX_VecF32x8_Load(const ptr: Pointer): TVecF32x8;
procedure AVX_VecF32x8_Store(const vec: TVecF32x8; ptr: Pointer);
function AVX_VecF32x8_LoadUnaligned(const ptr: Pointer): TVecF32x8;
procedure AVX_VecF32x8_StoreUnaligned(const vec: TVecF32x8; ptr: Pointer);

// 向量创建
function AVX_VecF32x8_Set(v0, v1, v2, v3, v4, v5, v6, v7: Single): TVecF32x8;
function AVX_VecF32x8_SetAll(value: Single): TVecF32x8;
function AVX_VecF32x8_Zero: TVecF32x8;

// 向量数学函数
function AVX_VecF32x8_Sqrt(const a: TVecF32x8): TVecF32x8;
function AVX_VecF32x8_Min(const a, b: TVecF32x8): TVecF32x8;
function AVX_VecF32x8_Max(const a, b: TVecF32x8): TVecF32x8;

// FMA 操作 (需�?FMA 支持)
function AVX_VecF32x8_FMA(const a, b, c: TVecF32x8): TVecF32x8; // a * b + c

// 水平操作
function AVX_VecF32x8_HorizontalAdd(const a: TVecF32x8): Single;

implementation

uses
  fafafa.core.simd.cpuinfo.x86;

// === AVX 256-bit 实现 ===

function AVX_VecF32x8_Add(const a, b: TVecF32x8): TVecF32x8;
begin
  if HasAVX then
  begin
    // 使用 AVX vaddps 指令
    asm
      vmovups ymm0, a
      vmovups ymm1, b
      vaddps ymm0, ymm0, ymm1
      vmovups Result, ymm0
      vzeroupper  // 清理上半部分以避免性能损失
    end;
  end
  else
  begin
    // 回退到两�?128-bit 操作
    Result.lo := X86_VecF32x4_Add(a.lo, b.lo);
    Result.hi := X86_VecF32x4_Add(a.hi, b.hi);
  end;
end;

function AVX_VecF32x8_Sub(const a, b: TVecF32x8): TVecF32x8;
begin
  if HasAVX then
  begin
    asm
      vmovups ymm0, a
      vmovups ymm1, b
      vsubps ymm0, ymm0, ymm1
      vmovups Result, ymm0
      vzeroupper
    end;
  end
  else
  begin
    Result.lo := X86_VecF32x4_Sub(a.lo, b.lo);
    Result.hi := X86_VecF32x4_Sub(a.hi, b.hi);
  end;
end;

function AVX_VecF32x8_Mul(const a, b: TVecF32x8): TVecF32x8;
begin
  if HasAVX then
  begin
    asm
      vmovups ymm0, a
      vmovups ymm1, b
      vmulps ymm0, ymm0, ymm1
      vmovups Result, ymm0
      vzeroupper
    end;
  end
  else
  begin
    Result.lo := X86_VecF32x4_Mul(a.lo, b.lo);
    Result.hi := X86_VecF32x4_Mul(a.hi, b.hi);
  end;
end;

function AVX_VecF32x8_Div(const a, b: TVecF32x8): TVecF32x8;
begin
  if HasAVX then
  begin
    asm
      vmovups ymm0, a
      vmovups ymm1, b
      vdivps ymm0, ymm0, ymm1
      vmovups Result, ymm0
      vzeroupper
    end;
  end
  else
  begin
    Result.lo := X86_VecF32x4_Div(a.lo, b.lo);
    Result.hi := X86_VecF32x4_Div(a.hi, b.hi);
  end;
end;

function AVX_VecF32x8_Load(const ptr: Pointer): TVecF32x8;
begin
  if HasAVX then
  begin
    asm
      mov rax, ptr
      vmovaps ymm0, [rax]
      vmovups Result, ymm0
      vzeroupper
    end;
  end
  else
  begin
    Move(ptr^, Result, SizeOf(TVecF32x8));
  end;
end;

procedure AVX_VecF32x8_Store(const vec: TVecF32x8; ptr: Pointer);
begin
  if HasAVX then
  begin
    asm
      vmovups ymm0, vec
      mov rax, ptr
      vmovaps [rax], ymm0
      vzeroupper
    end;
  end
  else
  begin
    Move(vec, ptr^, SizeOf(TVecF32x8));
  end;
end;

function AVX_VecF32x8_LoadUnaligned(const ptr: Pointer): TVecF32x8;
begin
  if HasAVX then
  begin
    asm
      mov rax, ptr
      vmovups ymm0, [rax]
      vmovups Result, ymm0
      vzeroupper
    end;
  end
  else
  begin
    Move(ptr^, Result, SizeOf(TVecF32x8));
  end;
end;

procedure AVX_VecF32x8_StoreUnaligned(const vec: TVecF32x8; ptr: Pointer);
begin
  if HasAVX then
  begin
    asm
      vmovups ymm0, vec
      mov rax, ptr
      vmovups [rax], ymm0
      vzeroupper
    end;
  end
  else
  begin
    Move(vec, ptr^, SizeOf(TVecF32x8));
  end;
end;

function AVX_VecF32x8_SetAll(value: Single): TVecF32x8;
begin
  if HasAVX then
  begin
    asm
      vbroadcastss ymm0, value
      vmovups Result, ymm0
      vzeroupper
    end;
  end
  else
  begin
    // 标量回退
    Result.f[0] := value; Result.f[1] := value; Result.f[2] := value; Result.f[3] := value;
    Result.f[4] := value; Result.f[5] := value; Result.f[6] := value; Result.f[7] := value;
  end;
end;

function AVX_VecF32x8_Zero: TVecF32x8;
begin
  if HasAVX then
  begin
    asm
      vxorps ymm0, ymm0, ymm0
      vmovups Result, ymm0
      vzeroupper
    end;
  end
  else
  begin
    FillChar(Result, SizeOf(Result), 0);
  end;
end;

function AVX_VecF32x8_Sqrt(const a: TVecF32x8): TVecF32x8;
begin
  if HasAVX then
  begin
    asm
      vmovups ymm0, a
      vsqrtps ymm0, ymm0
      vmovups Result, ymm0
      vzeroupper
    end;
  end
  else
  begin
    Result.lo := X86_VecF32x4_Sqrt(a.lo);
    Result.hi := X86_VecF32x4_Sqrt(a.hi);
  end;
end;

function AVX_VecF32x8_FMA(const a, b, c: TVecF32x8): TVecF32x8;
begin
  if HasFMA then
  begin
    // 使用 FMA vfmadd231ps 指令
    asm
      vmovups ymm0, c      // 加数
      vmovups ymm1, a      // 乘数1
      vmovups ymm2, b      // 乘数2
      vfmadd231ps ymm0, ymm1, ymm2  // ymm0 = ymm1 * ymm2 + ymm0
      vmovups Result, ymm0
      vzeroupper
    end;
  end
  else if HasAVX then
  begin
    // 回退�?AVX 乘法+加法
    asm
      vmovups ymm0, a
      vmovups ymm1, b
      vmovups ymm2, c
      vmulps ymm0, ymm0, ymm1
      vaddps ymm0, ymm0, ymm2
      vmovups Result, ymm0
      vzeroupper
    end;
  end
  else
  begin
    // 标量回退
    Result := AVX_VecF32x8_Add(AVX_VecF32x8_Mul(a, b), c);
  end;
end;

function AVX_VecF32x8_HorizontalAdd(const a: TVecF32x8): Single;
var
  temp: TVecF32x4;
begin
  if HasAVX then
  begin
    // 使用 AVX 水平加法
    asm
      vmovups ymm0, a
      vextractf128 xmm1, ymm0, 1  // 提取�?28�?      vaddps xmm0, xmm0, xmm1     // 加到�?28�?      vhaddps xmm0, xmm0, xmm0    // 水平加法
      vhaddps xmm0, xmm0, xmm0    // 再次水平加法
      vmovss Result, xmm0
      vzeroupper
    end;
  end
  else
  begin
    // 回退到标量加�?    Result := a.f[0] + a.f[1] + a.f[2] + a.f[3] + a.f[4] + a.f[5] + a.f[6] + a.f[7];
  end;
end;

// 其他函数的实�?..
function AVX_VecF32x8_Set(v0, v1, v2, v3, v4, v5, v6, v7: Single): TVecF32x8;
begin
  Result.f[0] := v0; Result.f[1] := v1; Result.f[2] := v2; Result.f[3] := v3;
  Result.f[4] := v4; Result.f[5] := v5; Result.f[6] := v6; Result.f[7] := v7;
end;

function AVX_VecF32x8_Min(const a, b: TVecF32x8): TVecF32x8;
begin
  if HasAVX then
  begin
    asm
      vmovups ymm0, a
      vmovups ymm1, b
      vminps ymm0, ymm0, ymm1
      vmovups Result, ymm0
      vzeroupper
    end;
  end
  else
  begin
    Result.lo := X86_VecF32x4_Min(a.lo, b.lo);
    Result.hi := X86_VecF32x4_Min(a.hi, b.hi);
  end;
end;

function AVX_VecF32x8_Max(const a, b: TVecF32x8): TVecF32x8;
begin
  if HasAVX then
  begin
    asm
      vmovups ymm0, a
      vmovups ymm1, b
      vmaxps ymm0, ymm0, ymm1
      vmovups Result, ymm0
      vzeroupper
    end;
  end
  else
  begin
    Result.lo := X86_VecF32x4_Max(a.lo, b.lo);
    Result.hi := X86_VecF32x4_Max(a.hi, b.hi);
  end;
end;

// 双精度实现省�?..

{$ENDIF} // SIMD_X86_AVAILABLE

end.


