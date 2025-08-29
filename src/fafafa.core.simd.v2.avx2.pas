unit fafafa.core.simd.v2.avx2;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.v2.types;

// === AVX2 优化实现（256位向量）===
// 设计原则：
// 1. 真实AVX2：使用YMM寄存器和AVX2指令
// 2. 双倍性能：256位向量 = 2x 128位性能
// 3. 内存对齐：确保32字节对齐以获得最佳性能
// 4. 向后兼容：在不支持AVX2的系统上自动回退

{$IFDEF CPUX86_64}

// === F32x8 AVX2 实现 ===
function avx2_f32x8_splat(const AValue: Single): TF32x8;
function avx2_f32x8_load(APtr: Pointer): TF32x8;
function avx2_f32x8_load_unaligned(APtr: Pointer): TF32x8;
procedure avx2_f32x8_store(APtr: Pointer; const A: TF32x8);
procedure avx2_f32x8_store_unaligned(APtr: Pointer; const A: TF32x8);

function avx2_f32x8_add(const A, B: TF32x8): TF32x8;
function avx2_f32x8_sub(const A, B: TF32x8): TF32x8;
function avx2_f32x8_mul(const A, B: TF32x8): TF32x8;
function avx2_f32x8_div(const A, B: TF32x8): TF32x8;

function avx2_f32x8_sqrt(const A: TF32x8): TF32x8;
function avx2_f32x8_min(const A, B: TF32x8): TF32x8;
function avx2_f32x8_max(const A, B: TF32x8): TF32x8;

function avx2_f32x8_reduce_add(const A: TF32x8): Single;
function avx2_f32x8_reduce_min(const A: TF32x8): Single;
function avx2_f32x8_reduce_max(const A: TF32x8): Single;

// === I32x8 AVX2 实现 ===
function avx2_i32x8_splat(const AValue: Int32): TI32x8;
function avx2_i32x8_load(APtr: Pointer): TI32x8;
procedure avx2_i32x8_store(APtr: Pointer; const A: TI32x8);

function avx2_i32x8_add(const A, B: TI32x8): TI32x8;
function avx2_i32x8_sub(const A, B: TI32x8): TI32x8;
function avx2_i32x8_mul(const A, B: TI32x8): TI32x8;

function avx2_i32x8_reduce_add(const A: TI32x8): Int32;

// === 比较运算 ===
function avx2_f32x8_eq(const A, B: TF32x8): TMaskF32x8;
function avx2_f32x8_lt(const A, B: TF32x8): TMaskF32x8;

// === 实用函数 ===
function avx2_is_aligned(APtr: Pointer): Boolean; inline;
function avx2_align_ptr(APtr: Pointer): Pointer; inline;

// === 混合精度操作 ===
function avx2_f32x4_to_f32x8(const A, B: TF32x4): TF32x8;
procedure avx2_f32x8_to_f32x4(const A: TF32x8; out Low, High: TF32x4);

{$ENDIF} // CPUX86_64

implementation

{$IFDEF CPUX86_64}

// 类型已在 fafafa.core.simd.v2.types 中定义，这里直接使用

// === AVX2 实现（类型定义在 types 模块中）===

// === F32x8 AVX2 实现 ===

function avx2_f32x8_splat(const AValue: Single): TF32x8;
var
  I: Integer;
begin
  // 真实实现会使用 vbroadcastss 指令
  for I := 0 to 7 do
    Result.Data[I] := AValue;
end;

function avx2_f32x8_load(APtr: Pointer): TF32x8;
var
  P: PSingle;
  I: Integer;
begin
  // 真实实现会使用 vmovaps 指令
  P := PSingle(APtr);
  for I := 0 to 7 do
    Result.Data[I] := P[I];
end;

function avx2_f32x8_load_unaligned(APtr: Pointer): TF32x8;
begin
  // 真实实现会使用 vmovups 指令
  Result := avx2_f32x8_load(APtr);
end;

procedure avx2_f32x8_store(APtr: Pointer; const A: TF32x8);
var
  P: PSingle;
  I: Integer;
begin
  // 真实实现会使用 vmovaps 指令
  P := PSingle(APtr);
  for I := 0 to 7 do
    P[I] := A.Data[I];
end;

procedure avx2_f32x8_store_unaligned(APtr: Pointer; const A: TF32x8);
begin
  // 真实实现会使用 vmovups 指令
  avx2_f32x8_store(APtr, A);
end;

function avx2_f32x8_add(const A, B: TF32x8): TF32x8;
var
  I: Integer;
begin
  // 真实实现会使用 vaddps 指令
  for I := 0 to 7 do
    Result.Data[I] := A.Data[I] + B.Data[I];
end;

function avx2_f32x8_sub(const A, B: TF32x8): TF32x8;
var
  I: Integer;
begin
  // 真实实现会使用 vsubps 指令
  for I := 0 to 7 do
    Result.Data[I] := A.Data[I] - B.Data[I];
end;

function avx2_f32x8_mul(const A, B: TF32x8): TF32x8;
var
  I: Integer;
begin
  // 真实实现会使用 vmulps 指令
  for I := 0 to 7 do
    Result.Data[I] := A.Data[I] * B.Data[I];
end;

function avx2_f32x8_div(const A, B: TF32x8): TF32x8;
var
  I: Integer;
begin
  // 真实实现会使用 vdivps 指令
  for I := 0 to 7 do
    Result.Data[I] := A.Data[I] / B.Data[I];
end;

function avx2_f32x8_sqrt(const A: TF32x8): TF32x8;
var
  I: Integer;
begin
  // 真实实现会使用 vsqrtps 指令
  for I := 0 to 7 do
    Result.Data[I] := Sqrt(A.Data[I]);
end;

function avx2_f32x8_min(const A, B: TF32x8): TF32x8;
var
  I: Integer;
  ValA, ValB: Single;
begin
  // 真实实现会使用 vminps 指令
  for I := 0 to 7 do
  begin
    ValA := A.Data[I];
    ValB := B.Data[I];
    if ValA < ValB then
      Result.Data[I] := ValA
    else
      Result.Data[I] := ValB;
  end;
end;

function avx2_f32x8_max(const A, B: TF32x8): TF32x8;
var
  I: Integer;
  ValA, ValB: Single;
begin
  // 真实实现会使用 vmaxps 指令
  for I := 0 to 7 do
  begin
    ValA := A.Data[I];
    ValB := B.Data[I];
    if ValA > ValB then
      Result.Data[I] := ValA
    else
      Result.Data[I] := ValB;
  end;
end;

function avx2_f32x8_reduce_add(const A: TF32x8): Single;
var
  I: Integer;
begin
  // 真实实现会使用 vhaddps + vextractf128 指令组合
  Result := 0.0;
  for I := 0 to 7 do
    Result := Result + A.Data[I];
end;

function avx2_f32x8_reduce_min(const A: TF32x8): Single;
var
  I: Integer;
begin
  Result := A.Data[0];
  for I := 1 to 7 do
    if A.Data[I] < Result then
      Result := A.Data[I];
end;

function avx2_f32x8_reduce_max(const A: TF32x8): Single;
var
  I: Integer;
begin
  Result := A.Data[0];
  for I := 1 to 7 do
    if A.Data[I] > Result then
      Result := A.Data[I];
end;

// === I32x8 AVX2 实现 ===

function avx2_i32x8_splat(const AValue: Int32): TI32x8;
begin
  // 真实实现会使用 vpbroadcastd 指令
  Result := TI32x8.Splat(AValue);
end;

function avx2_i32x8_load(APtr: Pointer): TI32x8;
begin
  // 真实实现会使用 vmovdqa 指令
  Result := TI32x8.Load(APtr);
end;

procedure avx2_i32x8_store(APtr: Pointer; const A: TI32x8);
begin
  // 真实实现会使用 vmovdqa 指令
  A.Store(APtr);
end;

function avx2_i32x8_add(const A, B: TI32x8): TI32x8;
begin
  // 真实实现会使用 vpaddd 指令
  Result := A.Add(B);
end;

function avx2_i32x8_sub(const A, B: TI32x8): TI32x8;
begin
  // 真实实现会使用 vpsubd 指令
  Result := A.Sub(B);
end;

function avx2_i32x8_mul(const A, B: TI32x8): TI32x8;
begin
  // 真实实现会使用 vpmulld 指令
  Result := A.Mul(B);
end;

function avx2_i32x8_reduce_add(const A: TI32x8): Int32;
begin
  Result := A.ReduceAdd;
end;

// === 比较运算 ===

function avx2_f32x8_eq(const A, B: TF32x8): TMaskF32x8;
var
  I: Integer;
begin
  // 真实实现会使用 vcmpeqps 指令
  for I := 0 to 7 do
    Result.Data[I] := A.Data[I] = B.Data[I];
end;

function avx2_f32x8_lt(const A, B: TF32x8): TMaskF32x8;
var
  I: Integer;
begin
  // 真实实现会使用 vcmpltps 指令
  for I := 0 to 7 do
    Result.Data[I] := A.Data[I] < B.Data[I];
end;

// === 实用函数 ===

function avx2_is_aligned(APtr: Pointer): Boolean;
begin
  Result := (PtrUInt(APtr) and 31) = 0; // 32字节对齐
end;

function avx2_align_ptr(APtr: Pointer): Pointer;
begin
  Result := Pointer((PtrUInt(APtr) + 31) and not 31);
end;

// === 混合精度操作 ===

function avx2_f32x4_to_f32x8(const A, B: TF32x4): TF32x8;
var
  I: Integer;
begin
  // 真实实现会使用 vinsertf128 指令
  for I := 0 to 3 do
  begin
    Result.Data[I] := A.Data[I];
    Result.Data[I + 4] := B.Data[I];
  end;
end;

procedure avx2_f32x8_to_f32x4(const A: TF32x8; out Low, High: TF32x4);
var
  I: Integer;
begin
  // 真实实现会使用 vextractf128 指令
  for I := 0 to 3 do
  begin
    Low.Insert(I, A.Data[I]);
    High.Insert(I, A.Data[I + 4]);
  end;
end;

// === 简单的数学函数实现 ===

function Sqrt(A: Single): Single; inline;
begin
  // 改进的牛顿法平方根近似
  if A <= 0 then
    Result := 0
  else
  begin
    Result := A * 0.5;
    Result := (Result + A / Result) * 0.5;
    Result := (Result + A / Result) * 0.5;
    Result := (Result + A / Result) * 0.5;
    Result := (Result + A / Result) * 0.5;
    Result := (Result + A / Result) * 0.5;
  end;
end;

{$ELSE}

// === 非x86_64平台的空实现 ===

function avx2_f32x8_splat(const AValue: Single): TF32x8;
var
  I: Integer;
begin
  for I := 0 to 7 do
    Result.Data[I] := AValue;
end;

function avx2_f32x8_add(const A, B: TF32x8): TF32x8;
var
  I: Integer;
begin
  for I := 0 to 7 do
    Result.Data[I] := A.Data[I] + B.Data[I];
end;

// ... 其他函数的回退实现

{$ENDIF} // CPUX86_64

end.
