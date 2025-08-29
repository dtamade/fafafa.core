unit fafafa.core.simd.core;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.types;

// === 核心 SIMD 接口（对标 Rust std::simd）===
// 统一使用 simd_ 前缀，遵循 Rust 命名规范

// === 1. 向量算术运算 ===

// 加法运算
function simd_add_f32x4(const a, b: TSimdF32x4): TSimdF32x4;
function simd_add_f32x8(const a, b: TSimdF32x8): TSimdF32x8;
function simd_add_f32x16(const a, b: TSimdF32x16): TSimdF32x16;
function simd_add_f64x2(const a, b: TSimdF64x2): TSimdF64x2;
function simd_add_f64x4(const a, b: TSimdF64x4): TSimdF64x4;
function simd_add_i32x4(const a, b: TSimdI32x4): TSimdI32x4;
function simd_add_i32x8(const a, b: TSimdI32x8): TSimdI32x8;
function simd_add_i32x16(const a, b: TSimdI32x16): TSimdI32x16;

// 减法运算
function simd_sub_f32x4(const a, b: TSimdF32x4): TSimdF32x4;
function simd_sub_f32x8(const a, b: TSimdF32x8): TSimdF32x8;
function simd_sub_f32x16(const a, b: TSimdF32x16): TSimdF32x16;
function simd_sub_f64x2(const a, b: TSimdF64x2): TSimdF64x2;
function simd_sub_f64x4(const a, b: TSimdF64x4): TSimdF64x4;
function simd_sub_i32x4(const a, b: TSimdI32x4): TSimdI32x4;
function simd_sub_i32x8(const a, b: TSimdI32x8): TSimdI32x8;

// 乘法运算
function simd_mul_f32x4(const a, b: TSimdF32x4): TSimdF32x4;
function simd_mul_f32x8(const a, b: TSimdF32x8): TSimdF32x8;
function simd_mul_f32x16(const a, b: TSimdF32x16): TSimdF32x16;
function simd_mul_f64x2(const a, b: TSimdF64x2): TSimdF64x2;
function simd_mul_f64x4(const a, b: TSimdF64x4): TSimdF64x4;
function simd_mul_i32x4(const a, b: TSimdI32x4): TSimdI32x4;
function simd_mul_i32x8(const a, b: TSimdI32x8): TSimdI32x8;

// 除法运算（仅浮点）
function simd_div_f32x4(const a, b: TSimdF32x4): TSimdF32x4;
function simd_div_f32x8(const a, b: TSimdF32x8): TSimdF32x8;
function simd_div_f32x16(const a, b: TSimdF32x16): TSimdF32x16;
function simd_div_f64x2(const a, b: TSimdF64x2): TSimdF64x2;
function simd_div_f64x4(const a, b: TSimdF64x4): TSimdF64x4;

// === 2. 比较运算 ===

// 相等比较
function simd_eq_f32x4(const a, b: TSimdF32x4): TSimdMask4;
function simd_eq_f32x8(const a, b: TSimdF32x8): TSimdMask8;
function simd_eq_f64x2(const a, b: TSimdF64x2): TSimdMask2;
function simd_eq_i32x4(const a, b: TSimdI32x4): TSimdMask4;
function simd_eq_i32x8(const a, b: TSimdI32x8): TSimdMask8;

// 小于比较
function simd_lt_f32x4(const a, b: TSimdF32x4): TSimdMask4;
function simd_lt_f32x8(const a, b: TSimdF32x8): TSimdMask8;
function simd_lt_f64x2(const a, b: TSimdF64x2): TSimdMask2;
function simd_lt_i32x4(const a, b: TSimdI32x4): TSimdMask4;

// 小于等于比较
function simd_le_f32x4(const a, b: TSimdF32x4): TSimdMask4;
function simd_le_f64x2(const a, b: TSimdF64x2): TSimdMask2;
function simd_le_i32x4(const a, b: TSimdI32x4): TSimdMask4;

// === 3. 数学函数 ===

// 绝对值
function simd_abs_f32x4(const a: TSimdF32x4): TSimdF32x4;
function simd_abs_f32x8(const a: TSimdF32x8): TSimdF32x8;
function simd_abs_f64x2(const a: TSimdF64x2): TSimdF64x2;
function simd_abs_i32x4(const a: TSimdI32x4): TSimdI32x4;

// 平方根
function simd_sqrt_f32x4(const a: TSimdF32x4): TSimdF32x4;
function simd_sqrt_f32x8(const a: TSimdF32x8): TSimdF32x8;
function simd_sqrt_f64x2(const a: TSimdF64x2): TSimdF64x2;
function simd_sqrt_f64x4(const a: TSimdF64x4): TSimdF64x4;

// 最小值
function simd_min_f32x4(const a, b: TSimdF32x4): TSimdF32x4;
function simd_min_f32x8(const a, b: TSimdF32x8): TSimdF32x8;
function simd_min_f64x2(const a, b: TSimdF64x2): TSimdF64x2;
function simd_min_i32x4(const a, b: TSimdI32x4): TSimdI32x4;

// 最大值
function simd_max_f32x4(const a, b: TSimdF32x4): TSimdF32x4;
function simd_max_f32x8(const a, b: TSimdF32x8): TSimdF32x8;
function simd_max_f64x2(const a, b: TSimdF64x2): TSimdF64x2;
function simd_max_i32x4(const a, b: TSimdI32x4): TSimdI32x4;

// === 4. 聚合运算（Reduce Operations）===

// 求和
function simd_reduce_add_f32x4(const a: TSimdF32x4): Single;
function simd_reduce_add_f32x8(const a: TSimdF32x8): Single;
function simd_reduce_add_f64x2(const a: TSimdF64x2): Double;
function simd_reduce_add_i32x4(const a: TSimdI32x4): Int32;
function simd_reduce_add_i32x8(const a: TSimdI32x8): Int32;

// 求积
function simd_reduce_mul_f32x4(const a: TSimdF32x4): Single;
function simd_reduce_mul_f64x2(const a: TSimdF64x2): Double;
function simd_reduce_mul_i32x4(const a: TSimdI32x4): Int32;

// 最小值
function simd_reduce_min_f32x4(const a: TSimdF32x4): Single;
function simd_reduce_min_f32x8(const a: TSimdF32x8): Single;
function simd_reduce_min_f64x2(const a: TSimdF64x2): Double;
function simd_reduce_min_i32x4(const a: TSimdI32x4): Int32;

// 最大值
function simd_reduce_max_f32x4(const a: TSimdF32x4): Single;
function simd_reduce_max_f32x8(const a: TSimdF32x8): Single;
function simd_reduce_max_f64x2(const a: TSimdF64x2): Double;
function simd_reduce_max_i32x4(const a: TSimdI32x4): Int32;

// === 5. 内存操作 ===

// 对齐加载
function simd_load_f32x4(p: PSingle): TSimdF32x4;
function simd_load_f32x8(p: PSingle): TSimdF32x8;
function simd_load_f64x2(p: PDouble): TSimdF64x2;
function simd_load_i32x4(p: PInt32): TSimdI32x4;

// 非对齐加载
function simd_loadu_f32x4(p: PSingle): TSimdF32x4;
function simd_loadu_f32x8(p: PSingle): TSimdF32x8;
function simd_loadu_f64x2(p: PDouble): TSimdF64x2;
function simd_loadu_i32x4(p: PInt32): TSimdI32x4;

// 对齐存储
procedure simd_store_f32x4(p: PSingle; const a: TSimdF32x4);
procedure simd_store_f32x8(p: PSingle; const a: TSimdF32x8);
procedure simd_store_f64x2(p: PDouble; const a: TSimdF64x2);
procedure simd_store_i32x4(p: PInt32; const a: TSimdI32x4);

// 非对齐存储
procedure simd_storeu_f32x4(p: PSingle; const a: TSimdF32x4);
procedure simd_storeu_f32x8(p: PSingle; const a: TSimdF32x8);
procedure simd_storeu_f64x2(p: PDouble; const a: TSimdF64x2);
procedure simd_storeu_i32x4(p: PInt32; const a: TSimdI32x4);

// === 6. 重排和混洗 ===

// 广播单个值
function simd_splat_f32x4(value: Single): TSimdF32x4;
function simd_splat_f32x8(value: Single): TSimdF32x8;
function simd_splat_i32x4(value: Int32): TSimdI32x4;

// 提取元素
function simd_extract_f32x4(const a: TSimdF32x4; index: Integer): Single;
function simd_extract_i32x4(const a: TSimdI32x4; index: Integer): Int32;

// 插入元素
function simd_insert_f32x4(const a: TSimdF32x4; value: Single; index: Integer): TSimdF32x4;
function simd_insert_i32x4(const a: TSimdI32x4; value: Int32; index: Integer): TSimdI32x4;

// === 7. 条件选择 ===

// 基于掩码选择
function simd_select_f32x4(const mask: TSimdMask4; const a, b: TSimdF32x4): TSimdF32x4;
function simd_select_f32x8(const mask: TSimdMask8; const a, b: TSimdF32x8): TSimdF32x8;
function simd_select_i32x4(const mask: TSimdMask4; const a, b: TSimdI32x4): TSimdI32x4;

// === 8. AVX2 优化函数 ===
{$IFDEF CPUX86_64}
function simd_memequal_avx2(a, b: Pointer; len: SizeUInt): Boolean;
function simd_memfindbyte_avx2(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
{$ENDIF}

implementation

uses
  fafafa.core.simd.scalar;

// 内联内存比较函数（替代 SysUtils.CompareMem）
function CompareMem(P1, P2: Pointer; Length: SizeUInt): Boolean; inline;
var
  pb1, pb2: PByte;
  i: SizeUInt;
begin
  pb1 := PByte(P1);
  pb2 := PByte(P2);
  for i := 0 to Length - 1 do
  begin
    if pb1[i] <> pb2[i] then
      Exit(False);
  end;
  Result := True;
end;

// 内联数学函数（避免依赖外部单元）
function Min(a, b: Single): Single; inline;
begin
  if a < b then Result := a else Result := b;
end;

function Max(a, b: Single): Single; inline;
begin
  if a > b then Result := a else Result := b;
end;

function Min(a, b: Double): Double; inline;
begin
  if a < b then Result := a else Result := b;
end;

function Max(a, b: Double): Double; inline;
begin
  if a > b then Result := a else Result := b;
end;

function Min(a, b: Int32): Int32; inline;
begin
  if a < b then Result := a else Result := b;
end;

function Max(a, b: Int32): Int32; inline;
begin
  if a > b then Result := a else Result := b;
end;

function Sqrt(x: Single): Single; inline;
begin
  Result := System.Sqrt(x);
end;

function Sqrt(x: Double): Double; inline;
begin
  Result := System.Sqrt(x);
end;

function Abs(x: Single): Single; inline;
begin
  if x < 0 then Result := -x else Result := x;
end;

function Abs(x: Double): Double; inline;
begin
  if x < 0 then Result := -x else Result := x;
end;

function Abs(x: Int32): Int32; inline;
begin
  if x < 0 then Result := -x else Result := x;
end;

// 当前使用标量实现作为默认实现
// 后续将被动态派发系统替换

function simd_add_f32x4(const a, b: TSimdF32x4): TSimdF32x4;
begin
  Result := simd_add_f32x4_scalar(a, b);
end;

function simd_reduce_add_f32x4(const a: TSimdF32x4): Single;
begin
  Result := simd_reduce_add_f32x4_scalar(a);
end;

function simd_splat_f32x4(value: Single): TSimdF32x4;
begin
  Result := simd_splat_f32x4_scalar(value);
end;

// === 临时实现（使用标量回退）===
// 这些将在后续步骤中被真正的SIMD实现替换

function simd_add_f32x8(const a, b: TSimdF32x8): TSimdF32x8;
begin
  Result := simd_add_f32x8_scalar(a, b);
end;

function simd_add_f32x16(const a, b: TSimdF32x16): TSimdF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] + b[i];
end;

function simd_add_f64x2(const a, b: TSimdF64x2): TSimdF64x2;
begin
  Result := simd_add_f64x2_scalar(a, b);
end;

function simd_add_f64x4(const a, b: TSimdF64x4): TSimdF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] + b[i];
end;

function simd_add_i32x4(const a, b: TSimdI32x4): TSimdI32x4;
begin
  Result := simd_add_i32x4_scalar(a, b);
end;

function simd_add_i32x8(const a, b: TSimdI32x8): TSimdI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] + b[i];
end;

function simd_add_i32x16(const a, b: TSimdI32x16): TSimdI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] + b[i];
end;

// 减法运算
function simd_sub_f32x4(const a, b: TSimdF32x4): TSimdF32x4;
begin
  Result := simd_sub_f32x4_scalar(a, b);
end;

function simd_sub_f32x8(const a, b: TSimdF32x8): TSimdF32x8;
begin
  Result := simd_sub_f32x8_scalar(a, b);
end;

function simd_sub_f32x16(const a, b: TSimdF32x16): TSimdF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] - b[i];
end;

function simd_sub_f64x2(const a, b: TSimdF64x2): TSimdF64x2;
begin
  Result := simd_sub_f64x2_scalar(a, b);
end;

function simd_sub_f64x4(const a, b: TSimdF64x4): TSimdF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] - b[i];
end;

function simd_sub_i32x4(const a, b: TSimdI32x4): TSimdI32x4;
begin
  Result := simd_sub_i32x4_scalar(a, b);
end;

function simd_sub_i32x8(const a, b: TSimdI32x8): TSimdI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] - b[i];
end;

// 乘法运算
function simd_mul_f32x4(const a, b: TSimdF32x4): TSimdF32x4;
begin
  Result := simd_mul_f32x4_scalar(a, b);
end;

function simd_mul_f32x8(const a, b: TSimdF32x8): TSimdF32x8;
begin
  Result := simd_mul_f32x8_scalar(a, b);
end;

function simd_mul_f32x16(const a, b: TSimdF32x16): TSimdF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] * b[i];
end;

function simd_mul_f64x2(const a, b: TSimdF64x2): TSimdF64x2;
begin
  Result := simd_mul_f64x2_scalar(a, b);
end;

function simd_mul_f64x4(const a, b: TSimdF64x4): TSimdF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] * b[i];
end;

function simd_mul_i32x4(const a, b: TSimdI32x4): TSimdI32x4;
begin
  Result := simd_mul_i32x4_scalar(a, b);
end;

function simd_mul_i32x8(const a, b: TSimdI32x8): TSimdI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] * b[i];
end;

// 除法运算
function simd_div_f32x4(const a, b: TSimdF32x4): TSimdF32x4;
begin
  Result := simd_div_f32x4_scalar(a, b);
end;

function simd_div_f32x8(const a, b: TSimdF32x8): TSimdF32x8;
begin
  Result := simd_div_f32x8_scalar(a, b);
end;

function simd_div_f32x16(const a, b: TSimdF32x16): TSimdF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] / b[i];
end;

function simd_div_f64x2(const a, b: TSimdF64x2): TSimdF64x2;
begin
  Result := simd_div_f64x2_scalar(a, b);
end;

function simd_div_f64x4(const a, b: TSimdF64x4): TSimdF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] / b[i];
end;

// 比较运算
function simd_eq_f32x4(const a, b: TSimdF32x4): TSimdMask4;
begin
  Result := simd_eq_f32x4_scalar(a, b);
end;

function simd_eq_f32x8(const a, b: TSimdF32x8): TSimdMask8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] = b[i];
end;

function simd_eq_f64x2(const a, b: TSimdF64x2): TSimdMask2;
begin
  Result := simd_eq_f64x2_scalar(a, b);
end;

function simd_eq_i32x4(const a, b: TSimdI32x4): TSimdMask4;
begin
  Result := simd_eq_i32x4_scalar(a, b);
end;

function simd_eq_i32x8(const a, b: TSimdI32x8): TSimdMask8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] = b[i];
end;

function simd_lt_f32x4(const a, b: TSimdF32x4): TSimdMask4;
begin
  Result := simd_lt_f32x4_scalar(a, b);
end;

function simd_lt_f32x8(const a, b: TSimdF32x8): TSimdMask8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] < b[i];
end;

function simd_lt_f64x2(const a, b: TSimdF64x2): TSimdMask2;
begin
  Result := simd_lt_f64x2_scalar(a, b);
end;

function simd_lt_i32x4(const a, b: TSimdI32x4): TSimdMask4;
begin
  Result := simd_lt_i32x4_scalar(a, b);
end;

function simd_le_f32x4(const a, b: TSimdF32x4): TSimdMask4;
begin
  Result := simd_le_f32x4_scalar(a, b);
end;

function simd_le_f64x2(const a, b: TSimdF64x2): TSimdMask2;
begin
  Result := simd_le_f64x2_scalar(a, b);
end;

function simd_le_i32x4(const a, b: TSimdI32x4): TSimdMask4;
begin
  Result := simd_le_i32x4_scalar(a, b);
end;

// 数学函数
function simd_abs_f32x4(const a: TSimdF32x4): TSimdF32x4;
begin
  Result := simd_abs_f32x4_scalar(a);
end;

function simd_abs_f32x8(const a: TSimdF32x8): TSimdF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := Abs(a[i]);
end;

function simd_abs_f64x2(const a: TSimdF64x2): TSimdF64x2;
begin
  Result := simd_abs_f64x2_scalar(a);
end;

function simd_abs_i32x4(const a: TSimdI32x4): TSimdI32x4;
begin
  Result := simd_abs_i32x4_scalar(a);
end;

function simd_sqrt_f32x4(const a: TSimdF32x4): TSimdF32x4;
begin
  Result := simd_sqrt_f32x4_scalar(a);
end;

function simd_sqrt_f32x8(const a: TSimdF32x8): TSimdF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := Sqrt(a[i]);
end;

function simd_sqrt_f64x2(const a: TSimdF64x2): TSimdF64x2;
begin
  Result := simd_sqrt_f64x2_scalar(a);
end;

function simd_sqrt_f64x4(const a: TSimdF64x4): TSimdF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Sqrt(a[i]);
end;

function simd_min_f32x4(const a, b: TSimdF32x4): TSimdF32x4;
begin
  Result := simd_min_f32x4_scalar(a, b);
end;

function simd_min_f32x8(const a, b: TSimdF32x8): TSimdF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := Min(a[i], b[i]);
end;

function simd_min_f64x2(const a, b: TSimdF64x2): TSimdF64x2;
begin
  Result := simd_min_f64x2_scalar(a, b);
end;

function simd_min_i32x4(const a, b: TSimdI32x4): TSimdI32x4;
begin
  Result := simd_min_i32x4_scalar(a, b);
end;

function simd_max_f32x4(const a, b: TSimdF32x4): TSimdF32x4;
begin
  Result := simd_max_f32x4_scalar(a, b);
end;

function simd_max_f32x8(const a, b: TSimdF32x8): TSimdF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := Max(a[i], b[i]);
end;

function simd_max_f64x2(const a, b: TSimdF64x2): TSimdF64x2;
begin
  Result := simd_max_f64x2_scalar(a, b);
end;

function simd_max_i32x4(const a, b: TSimdI32x4): TSimdI32x4;
begin
  Result := simd_max_i32x4_scalar(a, b);
end;

// 聚合运算
function simd_reduce_add_f32x8(const a: TSimdF32x8): Single;
begin
  Result := simd_reduce_add_f32x8_scalar(a);
end;

function simd_reduce_add_f64x2(const a: TSimdF64x2): Double;
begin
  Result := simd_reduce_add_f64x2_scalar(a);
end;

function simd_reduce_add_i32x4(const a: TSimdI32x4): Int32;
begin
  Result := simd_reduce_add_i32x4_scalar(a);
end;

function simd_reduce_add_i32x8(const a: TSimdI32x8): Int32;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    Result := Result + a[i];
end;

function simd_reduce_mul_f32x4(const a: TSimdF32x4): Single;
begin
  Result := simd_reduce_mul_f32x4_scalar(a);
end;

function simd_reduce_mul_f64x2(const a: TSimdF64x2): Double;
begin
  Result := simd_reduce_mul_f64x2_scalar(a);
end;

function simd_reduce_mul_i32x4(const a: TSimdI32x4): Int32;
begin
  Result := simd_reduce_mul_i32x4_scalar(a);
end;

function simd_reduce_min_f32x4(const a: TSimdF32x4): Single;
begin
  Result := simd_reduce_min_f32x4_scalar(a);
end;

function simd_reduce_min_f32x8(const a: TSimdF32x8): Single;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 7 do
    Result := Min(Result, a[i]);
end;

function simd_reduce_min_f64x2(const a: TSimdF64x2): Double;
begin
  Result := simd_reduce_min_f64x2_scalar(a);
end;

function simd_reduce_min_i32x4(const a: TSimdI32x4): Int32;
begin
  Result := simd_reduce_min_i32x4_scalar(a);
end;

function simd_reduce_max_f32x4(const a: TSimdF32x4): Single;
begin
  Result := simd_reduce_max_f32x4_scalar(a);
end;

function simd_reduce_max_f32x8(const a: TSimdF32x8): Single;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 7 do
    Result := Max(Result, a[i]);
end;

function simd_reduce_max_f64x2(const a: TSimdF64x2): Double;
begin
  Result := simd_reduce_max_f64x2_scalar(a);
end;

function simd_reduce_max_i32x4(const a: TSimdI32x4): Int32;
begin
  Result := simd_reduce_max_i32x4_scalar(a);
end;

// 内存操作
function simd_load_f32x4(p: PSingle): TSimdF32x4;
begin
  Result := simd_load_f32x4_scalar(p);
end;

function simd_load_f32x8(p: PSingle): TSimdF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := p[i];
end;

function simd_load_f64x2(p: PDouble): TSimdF64x2;
begin
  Result := simd_load_f64x2_scalar(p);
end;

function simd_load_i32x4(p: PInt32): TSimdI32x4;
begin
  Result := simd_load_i32x4_scalar(p);
end;

function simd_loadu_f32x4(p: PSingle): TSimdF32x4;
begin
  Result := simd_load_f32x4_scalar(p); // 标量版本不区分对齐
end;

function simd_loadu_f32x8(p: PSingle): TSimdF32x8;
begin
  Result := simd_load_f32x8(p); // 标量版本不区分对齐
end;

function simd_loadu_f64x2(p: PDouble): TSimdF64x2;
begin
  Result := simd_load_f64x2_scalar(p); // 标量版本不区分对齐
end;

function simd_loadu_i32x4(p: PInt32): TSimdI32x4;
begin
  Result := simd_load_i32x4_scalar(p); // 标量版本不区分对齐
end;

procedure simd_store_f32x4(p: PSingle; const a: TSimdF32x4);
begin
  simd_store_f32x4_scalar(p, a);
end;

procedure simd_store_f32x8(p: PSingle; const a: TSimdF32x8);
var i: Integer;
begin
  for i := 0 to 7 do
    p[i] := a[i];
end;

procedure simd_store_f64x2(p: PDouble; const a: TSimdF64x2);
begin
  simd_store_f64x2_scalar(p, a);
end;

procedure simd_store_i32x4(p: PInt32; const a: TSimdI32x4);
begin
  simd_store_i32x4_scalar(p, a);
end;

procedure simd_storeu_f32x4(p: PSingle; const a: TSimdF32x4);
begin
  simd_store_f32x4_scalar(p, a); // 标量版本不区分对齐
end;

procedure simd_storeu_f32x8(p: PSingle; const a: TSimdF32x8);
begin
  simd_store_f32x8(p, a); // 标量版本不区分对齐
end;

procedure simd_storeu_f64x2(p: PDouble; const a: TSimdF64x2);
begin
  simd_store_f64x2_scalar(p, a); // 标量版本不区分对齐
end;

procedure simd_storeu_i32x4(p: PInt32; const a: TSimdI32x4);
begin
  simd_store_i32x4_scalar(p, a); // 标量版本不区分对齐
end;

// 重排和混洗
function simd_splat_f32x8(value: Single): TSimdF32x8;
begin
  Result := simd_splat_f32x8_scalar(value);
end;

function simd_splat_i32x4(value: Int32): TSimdI32x4;
begin
  Result := simd_splat_i32x4_scalar(value);
end;

function simd_extract_f32x4(const a: TSimdF32x4; index: Integer): Single;
begin
  Result := simd_extract_f32x4_scalar(a, index);
end;

function simd_extract_i32x4(const a: TSimdI32x4; index: Integer): Int32;
begin
  Result := simd_extract_i32x4_scalar(a, index);
end;

function simd_insert_f32x4(const a: TSimdF32x4; value: Single; index: Integer): TSimdF32x4;
begin
  Result := simd_insert_f32x4_scalar(a, value, index);
end;

function simd_insert_i32x4(const a: TSimdI32x4; value: Int32; index: Integer): TSimdI32x4;
begin
  Result := simd_insert_i32x4_scalar(a, value, index);
end;

// 条件选择
function simd_select_f32x4(const mask: TSimdMask4; const a, b: TSimdF32x4): TSimdF32x4;
begin
  Result := simd_select_f32x4_scalar(mask, a, b);
end;

function simd_select_f32x8(const mask: TSimdMask8; const a, b: TSimdF32x8): TSimdF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    if mask[i] then
      Result[i] := a[i]
    else
      Result[i] := b[i];
end;

function simd_select_i32x4(const mask: TSimdMask4; const a, b: TSimdI32x4): TSimdI32x4;
begin
  Result := simd_select_i32x4_scalar(mask, a, b);
end;

// === AVX2 优化实现 ===

{$IFDEF CPUX86_64}
// AVX2 版本的内存比较 - 目标性能 4+ GB/s
function simd_memequal_avx2(a, b: Pointer; len: SizeUInt): Boolean;
var
  pa, pb: PByte;
  i: SizeUInt;
  chunks: SizeUInt;
begin
  if len = 0 then Exit(True);
  if (a = nil) or (b = nil) then Exit(False);

  pa := PByte(a);
  pb := PByte(b);

  // 32 字节对齐的 AVX2 处理
  chunks := len div 32;
  for i := 0 to chunks - 1 do
  begin
    // TODO: 添加真实的 AVX2 汇编实现
    // 暂时使用标量实现作为占位符
    if not CompareMem(@pa[i * 32], @pb[i * 32], 32) then
      Exit(False);
  end;

  // 处理剩余字节
  i := chunks * 32;
  while i < len do
  begin
    if pa[i] <> pb[i] then Exit(False);
    Inc(i);
  end;

  Result := True;
end;

// AVX2 版本的字节查找 - 目标性能 5+ GB/s
function simd_memfindbyte_avx2(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
var
  pb: PByte;
  i, j: SizeUInt;
  chunks: SizeUInt;
begin
  if (len = 0) or (p = nil) then Exit(-1);

  pb := PByte(p);

  // 32 字节对齐的 AVX2 处理
  chunks := len div 32;
  for i := 0 to chunks - 1 do
  begin
    // TODO: 添加真实的 AVX2 汇编实现
    // 暂时使用标量实现作为占位符
    for j := 0 to 31 do
    begin
      if pb[i * 32 + j] = value then
        Exit(PtrInt(i * 32 + j));
    end;
  end;

  // 处理剩余字节
  i := chunks * 32;
  while i < len do
  begin
    if pb[i] = value then Exit(PtrInt(i));
    Inc(i);
  end;

  Result := -1;
end;
{$ENDIF}

end.
