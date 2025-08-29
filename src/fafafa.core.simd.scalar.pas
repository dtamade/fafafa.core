unit fafafa.core.simd.scalar;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.types;

// === 标量参考实现（性能基准和正确性验证）===
// 所有函数使用 simd_*_scalar 后缀

// === 1. 向量算术运算 ===

// 加法运算
function simd_add_f32x4_scalar(const a, b: TSimdF32x4): TSimdF32x4;
function simd_add_f32x8_scalar(const a, b: TSimdF32x8): TSimdF32x8;
function simd_add_f64x2_scalar(const a, b: TSimdF64x2): TSimdF64x2;
function simd_add_i32x4_scalar(const a, b: TSimdI32x4): TSimdI32x4;

// 减法运算
function simd_sub_f32x4_scalar(const a, b: TSimdF32x4): TSimdF32x4;
function simd_sub_f32x8_scalar(const a, b: TSimdF32x8): TSimdF32x8;
function simd_sub_f64x2_scalar(const a, b: TSimdF64x2): TSimdF64x2;
function simd_sub_i32x4_scalar(const a, b: TSimdI32x4): TSimdI32x4;

// 乘法运算
function simd_mul_f32x4_scalar(const a, b: TSimdF32x4): TSimdF32x4;
function simd_mul_f32x8_scalar(const a, b: TSimdF32x8): TSimdF32x8;
function simd_mul_f64x2_scalar(const a, b: TSimdF64x2): TSimdF64x2;
function simd_mul_i32x4_scalar(const a, b: TSimdI32x4): TSimdI32x4;

// 除法运算
function simd_div_f32x4_scalar(const a, b: TSimdF32x4): TSimdF32x4;
function simd_div_f32x8_scalar(const a, b: TSimdF32x8): TSimdF32x8;
function simd_div_f64x2_scalar(const a, b: TSimdF64x2): TSimdF64x2;

// === 2. 比较运算 ===

function simd_eq_f32x4_scalar(const a, b: TSimdF32x4): TSimdMask4;
function simd_eq_f64x2_scalar(const a, b: TSimdF64x2): TSimdMask2;
function simd_eq_i32x4_scalar(const a, b: TSimdI32x4): TSimdMask4;

function simd_lt_f32x4_scalar(const a, b: TSimdF32x4): TSimdMask4;
function simd_lt_f64x2_scalar(const a, b: TSimdF64x2): TSimdMask2;
function simd_lt_i32x4_scalar(const a, b: TSimdI32x4): TSimdMask4;

function simd_le_f32x4_scalar(const a, b: TSimdF32x4): TSimdMask4;
function simd_le_f64x2_scalar(const a, b: TSimdF64x2): TSimdMask2;
function simd_le_i32x4_scalar(const a, b: TSimdI32x4): TSimdMask4;

// === 3. 数学函数 ===

function simd_abs_f32x4_scalar(const a: TSimdF32x4): TSimdF32x4;
function simd_abs_f64x2_scalar(const a: TSimdF64x2): TSimdF64x2;
function simd_abs_i32x4_scalar(const a: TSimdI32x4): TSimdI32x4;

function simd_sqrt_f32x4_scalar(const a: TSimdF32x4): TSimdF32x4;
function simd_sqrt_f64x2_scalar(const a: TSimdF64x2): TSimdF64x2;

function simd_min_f32x4_scalar(const a, b: TSimdF32x4): TSimdF32x4;
function simd_min_f64x2_scalar(const a, b: TSimdF64x2): TSimdF64x2;
function simd_min_i32x4_scalar(const a, b: TSimdI32x4): TSimdI32x4;

function simd_max_f32x4_scalar(const a, b: TSimdF32x4): TSimdF32x4;
function simd_max_f64x2_scalar(const a, b: TSimdF64x2): TSimdF64x2;
function simd_max_i32x4_scalar(const a, b: TSimdI32x4): TSimdI32x4;

// === 4. 聚合运算 ===

function simd_reduce_add_f32x4_scalar(const a: TSimdF32x4): Single;
function simd_reduce_add_f32x8_scalar(const a: TSimdF32x8): Single;
function simd_reduce_add_f64x2_scalar(const a: TSimdF64x2): Double;
function simd_reduce_add_i32x4_scalar(const a: TSimdI32x4): Int32;

function simd_reduce_mul_f32x4_scalar(const a: TSimdF32x4): Single;
function simd_reduce_mul_f64x2_scalar(const a: TSimdF64x2): Double;
function simd_reduce_mul_i32x4_scalar(const a: TSimdI32x4): Int32;

function simd_reduce_min_f32x4_scalar(const a: TSimdF32x4): Single;
function simd_reduce_min_f64x2_scalar(const a: TSimdF64x2): Double;
function simd_reduce_min_i32x4_scalar(const a: TSimdI32x4): Int32;

function simd_reduce_max_f32x4_scalar(const a: TSimdF32x4): Single;
function simd_reduce_max_f64x2_scalar(const a: TSimdF64x2): Double;
function simd_reduce_max_i32x4_scalar(const a: TSimdI32x4): Int32;

// === 5. 内存操作 ===

function simd_load_f32x4_scalar(p: PSingle): TSimdF32x4;
function simd_load_f64x2_scalar(p: PDouble): TSimdF64x2;
function simd_load_i32x4_scalar(p: PInt32): TSimdI32x4;

procedure simd_store_f32x4_scalar(p: PSingle; const a: TSimdF32x4);
procedure simd_store_f64x2_scalar(p: PDouble; const a: TSimdF64x2);
procedure simd_store_i32x4_scalar(p: PInt32; const a: TSimdI32x4);

// === 6. 重排和混洗 ===

function simd_splat_f32x4_scalar(value: Single): TSimdF32x4;
function simd_splat_f32x8_scalar(value: Single): TSimdF32x8;
function simd_splat_i32x4_scalar(value: Int32): TSimdI32x4;

function simd_extract_f32x4_scalar(const a: TSimdF32x4; index: Integer): Single;
function simd_extract_i32x4_scalar(const a: TSimdI32x4; index: Integer): Int32;

function simd_insert_f32x4_scalar(const a: TSimdF32x4; value: Single; index: Integer): TSimdF32x4;
function simd_insert_i32x4_scalar(const a: TSimdI32x4; value: Int32; index: Integer): TSimdI32x4;

// === 7. 条件选择 ===

function simd_select_f32x4_scalar(const mask: TSimdMask4; const a, b: TSimdF32x4): TSimdF32x4;
function simd_select_i32x4_scalar(const mask: TSimdMask4; const a, b: TSimdI32x4): TSimdI32x4;

implementation

uses
  Math;

// === 1. 向量算术运算实现 ===

function simd_add_f32x4_scalar(const a, b: TSimdF32x4): TSimdF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] + b[i];
end;

function simd_add_f32x8_scalar(const a, b: TSimdF32x8): TSimdF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] + b[i];
end;

function simd_add_f64x2_scalar(const a, b: TSimdF64x2): TSimdF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] + b[i];
end;

function simd_add_i32x4_scalar(const a, b: TSimdI32x4): TSimdI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] + b[i];
end;

function simd_sub_f32x4_scalar(const a, b: TSimdF32x4): TSimdF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] - b[i];
end;

function simd_sub_f32x8_scalar(const a, b: TSimdF32x8): TSimdF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] - b[i];
end;

function simd_sub_f64x2_scalar(const a, b: TSimdF64x2): TSimdF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] - b[i];
end;

function simd_sub_i32x4_scalar(const a, b: TSimdI32x4): TSimdI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] - b[i];
end;

function simd_mul_f32x4_scalar(const a, b: TSimdF32x4): TSimdF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] * b[i];
end;

function simd_mul_f32x8_scalar(const a, b: TSimdF32x8): TSimdF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] * b[i];
end;

function simd_mul_f64x2_scalar(const a, b: TSimdF64x2): TSimdF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] * b[i];
end;

function simd_mul_i32x4_scalar(const a, b: TSimdI32x4): TSimdI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] * b[i];
end;

function simd_div_f32x4_scalar(const a, b: TSimdF32x4): TSimdF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] / b[i];
end;

function simd_div_f32x8_scalar(const a, b: TSimdF32x8): TSimdF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] / b[i];
end;

function simd_div_f64x2_scalar(const a, b: TSimdF64x2): TSimdF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] / b[i];
end;

// === 4. 聚合运算实现 ===

function simd_reduce_add_f32x4_scalar(const a: TSimdF32x4): Single;
var i: Integer;
begin
  Result := 0.0;
  for i := 0 to 3 do
    Result := Result + a[i];
end;

function simd_reduce_add_f32x8_scalar(const a: TSimdF32x8): Single;
var i: Integer;
begin
  Result := 0.0;
  for i := 0 to 7 do
    Result := Result + a[i];
end;

function simd_reduce_add_f64x2_scalar(const a: TSimdF64x2): Double;
var i: Integer;
begin
  Result := 0.0;
  for i := 0 to 1 do
    Result := Result + a[i];
end;

function simd_reduce_add_i32x4_scalar(const a: TSimdI32x4): Int32;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    Result := Result + a[i];
end;

// === 6. 重排和混洗实现 ===

function simd_splat_f32x4_scalar(value: Single): TSimdF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := value;
end;

function simd_splat_f32x8_scalar(value: Single): TSimdF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := value;
end;

function simd_splat_i32x4_scalar(value: Int32): TSimdI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := value;
end;

function simd_extract_f32x4_scalar(const a: TSimdF32x4; index: Integer): Single;
begin
  if (index >= 0) and (index <= 3) then
    Result := a[index]
  else
    Result := 0.0;
end;

function simd_extract_i32x4_scalar(const a: TSimdI32x4; index: Integer): Int32;
begin
  if (index >= 0) and (index <= 3) then
    Result := a[index]
  else
    Result := 0;
end;

function simd_insert_f32x4_scalar(const a: TSimdF32x4; value: Single; index: Integer): TSimdF32x4;
begin
  Result := a;
  if (index >= 0) and (index <= 3) then
    Result[index] := value;
end;

function simd_insert_i32x4_scalar(const a: TSimdI32x4; value: Int32; index: Integer): TSimdI32x4;
begin
  Result := a;
  if (index >= 0) and (index <= 3) then
    Result[index] := value;
end;

// === 5. 内存操作实现 ===

function simd_load_f32x4_scalar(p: PSingle): TSimdF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := p[i];
end;

function simd_load_f64x2_scalar(p: PDouble): TSimdF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := p[i];
end;

function simd_load_i32x4_scalar(p: PInt32): TSimdI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := p[i];
end;

procedure simd_store_f32x4_scalar(p: PSingle; const a: TSimdF32x4);
var i: Integer;
begin
  for i := 0 to 3 do
    p[i] := a[i];
end;

procedure simd_store_f64x2_scalar(p: PDouble; const a: TSimdF64x2);
var i: Integer;
begin
  for i := 0 to 1 do
    p[i] := a[i];
end;

procedure simd_store_i32x4_scalar(p: PInt32; const a: TSimdI32x4);
var i: Integer;
begin
  for i := 0 to 3 do
    p[i] := a[i];
end;

// === 7. 条件选择实现 ===

function simd_select_f32x4_scalar(const mask: TSimdMask4; const a, b: TSimdF32x4): TSimdF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if mask[i] then
      Result[i] := a[i]
    else
      Result[i] := b[i];
end;

function simd_select_i32x4_scalar(const mask: TSimdMask4; const a, b: TSimdI32x4): TSimdI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    if mask[i] then
      Result[i] := a[i]
    else
      Result[i] := b[i];
end;

// === 2. 比较运算实现 ===

function simd_eq_f32x4_scalar(const a, b: TSimdF32x4): TSimdMask4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] = b[i];
end;

function simd_eq_f64x2_scalar(const a, b: TSimdF64x2): TSimdMask2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] = b[i];
end;

function simd_eq_i32x4_scalar(const a, b: TSimdI32x4): TSimdMask4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] = b[i];
end;

function simd_lt_f32x4_scalar(const a, b: TSimdF32x4): TSimdMask4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] < b[i];
end;

function simd_lt_f64x2_scalar(const a, b: TSimdF64x2): TSimdMask2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] < b[i];
end;

function simd_lt_i32x4_scalar(const a, b: TSimdI32x4): TSimdMask4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] < b[i];
end;

function simd_le_f32x4_scalar(const a, b: TSimdF32x4): TSimdMask4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] <= b[i];
end;

function simd_le_f64x2_scalar(const a, b: TSimdF64x2): TSimdMask2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] <= b[i];
end;

function simd_le_i32x4_scalar(const a, b: TSimdI32x4): TSimdMask4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] <= b[i];
end;

// === 3. 数学函数实现 ===

function simd_abs_f32x4_scalar(const a: TSimdF32x4): TSimdF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Abs(a[i]);
end;

function simd_abs_f64x2_scalar(const a: TSimdF64x2): TSimdF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := Abs(a[i]);
end;

function simd_abs_i32x4_scalar(const a: TSimdI32x4): TSimdI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Abs(a[i]);
end;

function simd_sqrt_f32x4_scalar(const a: TSimdF32x4): TSimdF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Sqrt(a[i]);
end;

function simd_sqrt_f64x2_scalar(const a: TSimdF64x2): TSimdF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := Sqrt(a[i]);
end;

function simd_min_f32x4_scalar(const a, b: TSimdF32x4): TSimdF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Min(a[i], b[i]);
end;

function simd_min_f64x2_scalar(const a, b: TSimdF64x2): TSimdF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := Min(a[i], b[i]);
end;

function simd_min_i32x4_scalar(const a, b: TSimdI32x4): TSimdI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Min(a[i], b[i]);
end;

function simd_max_f32x4_scalar(const a, b: TSimdF32x4): TSimdF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Max(a[i], b[i]);
end;

function simd_max_f64x2_scalar(const a, b: TSimdF64x2): TSimdF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := Max(a[i], b[i]);
end;

function simd_max_i32x4_scalar(const a, b: TSimdI32x4): TSimdI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Max(a[i], b[i]);
end;

// === 4. 聚合运算实现（剩余部分）===

function simd_reduce_mul_f32x4_scalar(const a: TSimdF32x4): Single;
var i: Integer;
begin
  Result := 1.0;
  for i := 0 to 3 do
    Result := Result * a[i];
end;

function simd_reduce_mul_f64x2_scalar(const a: TSimdF64x2): Double;
var i: Integer;
begin
  Result := 1.0;
  for i := 0 to 1 do
    Result := Result * a[i];
end;

function simd_reduce_mul_i32x4_scalar(const a: TSimdI32x4): Int32;
var i: Integer;
begin
  Result := 1;
  for i := 0 to 3 do
    Result := Result * a[i];
end;

function simd_reduce_min_f32x4_scalar(const a: TSimdF32x4): Single;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 3 do
    Result := Min(Result, a[i]);
end;

function simd_reduce_min_f64x2_scalar(const a: TSimdF64x2): Double;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 1 do
    Result := Min(Result, a[i]);
end;

function simd_reduce_min_i32x4_scalar(const a: TSimdI32x4): Int32;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 3 do
    Result := Min(Result, a[i]);
end;

function simd_reduce_max_f32x4_scalar(const a: TSimdF32x4): Single;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 3 do
    Result := Max(Result, a[i]);
end;

function simd_reduce_max_f64x2_scalar(const a: TSimdF64x2): Double;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 1 do
    Result := Max(Result, a[i]);
end;

function simd_reduce_max_i32x4_scalar(const a: TSimdI32x4): Int32;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 3 do
    Result := Max(Result, a[i]);
end;

end.
