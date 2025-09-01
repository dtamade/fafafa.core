unit fafafa.core.simd.ops.avx2;

{$I fafafa.core.settings.inc}

interface

{$IFDEF SIMD_X86_AVAILABLE}

uses
  fafafa.core.simd.types;

// === AVX2 256-bit 整数向量操作 ===

// 32位整数向量操作 (256-bit, 8x int32)
function AVX2_VecI32x8_Add(const a, b: TVecI32x8): TVecI32x8;
function AVX2_VecI32x8_Sub(const a, b: TVecI32x8): TVecI32x8;
function AVX2_VecI32x8_Mul(const a, b: TVecI32x8): TVecI32x8; // vpmulld

// 向量加载和存储
function AVX2_VecI32x8_Load(const ptr: Pointer): TVecI32x8;
procedure AVX2_VecI32x8_Store(const vec: TVecI32x8; ptr: Pointer);
function AVX2_VecI32x8_LoadUnaligned(const ptr: Pointer): TVecI32x8;
procedure AVX2_VecI32x8_StoreUnaligned(const vec: TVecI32x8; ptr: Pointer);

// 向量创建
function AVX2_VecI32x8_SetAll(value: Int32): TVecI32x8; // vpbroadcastd
function AVX2_VecI32x8_Zero: TVecI32x8;                  // vpxor

implementation

uses
  fafafa.core.simd.cpuinfo.x86;

{$asmmode intel}

function AVX2_VecI32x8_Add(const a, b: TVecI32x8): TVecI32x8;
begin
  if HasAVX2 then
  begin
    asm
      vmovdqu ymm0, a
      vmovdqu ymm1, b
      vpaddd ymm0, ymm0, ymm1
      vmovdqu Result, ymm0
      vzeroupper
    end;
  end
  else
  begin
    // 回退由上层决定，这里给出安全后备
    Result.lo.i[0] := a.i[0] + b.i[0];
    Result.i[1] := a.i[1] + b.i[1];
    Result.i[2] := a.i[2] + b.i[2];
    Result.i[3] := a.i[3] + b.i[3];
    Result.i[4] := a.i[4] + b.i[4];
    Result.i[5] := a.i[5] + b.i[5];
    Result.i[6] := a.i[6] + b.i[6];
    Result.i[7] := a.i[7] + b.i[7];
  end;
end;

function AVX2_VecI32x8_Sub(const a, b: TVecI32x8): TVecI32x8;
begin
  if HasAVX2 then
  begin
    asm
      vmovdqu ymm0, a
      vmovdqu ymm1, b
      vpsubd ymm0, ymm0, ymm1
      vmovdqu Result, ymm0
      vzeroupper
    end;
  end
  else
  begin
    Result.i[0] := a.i[0] - b.i[0];
    Result.i[1] := a.i[1] - b.i[1];
    Result.i[2] := a.i[2] - b.i[2];
    Result.i[3] := a.i[3] - b.i[3];
    Result.i[4] := a.i[4] - b.i[4];
    Result.i[5] := a.i[5] - b.i[5];
    Result.i[6] := a.i[6] - b.i[6];
    Result.i[7] := a.i[7] - b.i[7];
  end;
end;

function AVX2_VecI32x8_Mul(const a, b: TVecI32x8): TVecI32x8;
begin
  if HasAVX2 then
  begin
    asm
      vmovdqu ymm0, a
      vmovdqu ymm1, b
      vpmulld ymm0, ymm0, ymm1
      vmovdqu Result, ymm0
      vzeroupper
    end;
  end
  else
  begin
    Result.i[0] := a.i[0] * b.i[0];
    Result.i[1] := a.i[1] * b.i[1];
    Result.i[2] := a.i[2] * b.i[2];
    Result.i[3] := a.i[3] * b.i[3];
    Result.i[4] := a.i[4] * b.i[4];
    Result.i[5] := a.i[5] * b.i[5];
    Result.i[6] := a.i[6] * b.i[6];
    Result.i[7] := a.i[7] * b.i[7];
  end;
end;

function AVX2_VecI32x8_Load(const ptr: Pointer): TVecI32x8;
begin
  if HasAVX2 then
  begin
    asm
      mov rax, ptr
      vmovdqa ymm0, [rax]
      vmovdqu Result, ymm0
      vzeroupper
    end;
  end
  else
  begin
    Move(ptr^, Result, SizeOf(TVecI32x8));
  end;
end;

procedure AVX2_VecI32x8_Store(const vec: TVecI32x8; ptr: Pointer);
begin
  if HasAVX2 then
  begin
    asm
      vmovdqu ymm0, vec
      mov rax, ptr
      vmovdqa [rax], ymm0
      vzeroupper
    end;
  end
  else
  begin
    Move(vec, ptr^, SizeOf(TVecI32x8));
  end;
end;

function AVX2_VecI32x8_LoadUnaligned(const ptr: Pointer): TVecI32x8;
begin
  if HasAVX2 then
  begin
    asm
      mov rax, ptr
      vmovdqu ymm0, [rax]
      vmovdqu Result, ymm0
      vzeroupper
    end;
  end
  else
  begin
    Move(ptr^, Result, SizeOf(TVecI32x8));
  end;
end;

procedure AVX2_VecI32x8_StoreUnaligned(const vec: TVecI32x8; ptr: Pointer);
begin
  if HasAVX2 then
  begin
    asm
      vmovdqu ymm0, vec
      mov rax, ptr
      vmovdqu [rax], ymm0
      vzeroupper
    end;
  end
  else
  begin
    Move(vec, ptr^, SizeOf(TVecI32x8));
  end;
end;

function AVX2_VecI32x8_SetAll(value: Int32): TVecI32x8;
begin
  if HasAVX2 then
  begin
    asm
      vmovd xmm0, value
      vpbroadcastd ymm0, xmm0
      vmovdqu Result, ymm0
      vzeroupper
    end;
  end
  else
  begin
    Result.i[0] := value; Result.i[1] := value; Result.i[2] := value; Result.i[3] := value;
    Result.i[4] := value; Result.i[5] := value; Result.i[6] := value; Result.i[7] := value;
  end;
end;

function AVX2_VecI32x8_Zero: TVecI32x8;
begin
  if HasAVX2 then
  begin
    asm
      vpxor ymm0, ymm0, ymm0
      vmovdqu Result, ymm0
      vzeroupper
    end;
  end
  else
  begin
    FillChar(Result, SizeOf(Result), 0);
  end;
end;

{$ENDIF} // SIMD_X86_AVAILABLE

end.
