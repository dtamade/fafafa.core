unit fafafa.core.simd.math;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.types;

// === 数学函数（对标 Rust std::simd）===
// 统一使用 simd_ 前缀，遵循 Rust 命名规范

// === 1. 绝对值 ===

// 浮点绝对值
function simd_abs_f32x4(const a: TSimdF32x4): TSimdF32x4; inline;
function simd_abs_f32x8(const a: TSimdF32x8): TSimdF32x8; inline;
function simd_abs_f32x16(const a: TSimdF32x16): TSimdF32x16; inline;
function simd_abs_f64x2(const a: TSimdF64x2): TSimdF64x2; inline;
function simd_abs_f64x4(const a: TSimdF64x4): TSimdF64x4; inline;
function simd_abs_f64x8(const a: TSimdF64x8): TSimdF64x8; inline;

// 整数绝对值
function simd_abs_i8x16(const a: TSimdI8x16): TSimdI8x16; inline;
function simd_abs_i8x32(const a: TSimdI8x32): TSimdI8x32; inline;
function simd_abs_i16x8(const a: TSimdI16x8): TSimdI16x8; inline;
function simd_abs_i16x16(const a: TSimdI16x16): TSimdI16x16; inline;
function simd_abs_i32x4(const a: TSimdI32x4): TSimdI32x4; inline;
function simd_abs_i32x8(const a: TSimdI32x8): TSimdI32x8; inline;
function simd_abs_i64x2(const a: TSimdI64x2): TSimdI64x2; inline;
function simd_abs_i64x4(const a: TSimdI64x4): TSimdI64x4; inline;

// === 2. 平方根 ===

function simd_sqrt_f32x4(const a: TSimdF32x4): TSimdF32x4; inline;
function simd_sqrt_f32x8(const a: TSimdF32x8): TSimdF32x8; inline;
function simd_sqrt_f32x16(const a: TSimdF32x16): TSimdF32x16; inline;
function simd_sqrt_f64x2(const a: TSimdF64x2): TSimdF64x2; inline;
function simd_sqrt_f64x4(const a: TSimdF64x4): TSimdF64x4; inline;
function simd_sqrt_f64x8(const a: TSimdF64x8): TSimdF64x8; inline;

// === 3. 倒数平方根 ===

function simd_rsqrt_f32x4(const a: TSimdF32x4): TSimdF32x4; inline;
function simd_rsqrt_f32x8(const a: TSimdF32x8): TSimdF32x8; inline;
function simd_rsqrt_f32x16(const a: TSimdF32x16): TSimdF32x16; inline;

// === 4. 最小值 ===

// 浮点最小值
function simd_min_f32x4(const a, b: TSimdF32x4): TSimdF32x4; inline;
function simd_min_f32x8(const a, b: TSimdF32x8): TSimdF32x8; inline;
function simd_min_f32x16(const a, b: TSimdF32x16): TSimdF32x16; inline;
function simd_min_f64x2(const a, b: TSimdF64x2): TSimdF64x2; inline;
function simd_min_f64x4(const a, b: TSimdF64x4): TSimdF64x4; inline;
function simd_min_f64x8(const a, b: TSimdF64x8): TSimdF64x8; inline;

// 有符号整数最小值
function simd_min_i8x16(const a, b: TSimdI8x16): TSimdI8x16; inline;
function simd_min_i8x32(const a, b: TSimdI8x32): TSimdI8x32; inline;
function simd_min_i16x8(const a, b: TSimdI16x8): TSimdI16x8; inline;
function simd_min_i16x16(const a, b: TSimdI16x16): TSimdI16x16; inline;
function simd_min_i32x4(const a, b: TSimdI32x4): TSimdI32x4; inline;
function simd_min_i32x8(const a, b: TSimdI32x8): TSimdI32x8; inline;
function simd_min_i64x2(const a, b: TSimdI64x2): TSimdI64x2; inline;
function simd_min_i64x4(const a, b: TSimdI64x4): TSimdI64x4; inline;

// 无符号整数最小值
function simd_min_u8x16(const a, b: TSimdU8x16): TSimdU8x16; inline;
function simd_min_u8x32(const a, b: TSimdU8x32): TSimdU8x32; inline;
function simd_min_u16x8(const a, b: TSimdU16x8): TSimdU16x8; inline;
function simd_min_u16x16(const a, b: TSimdU16x16): TSimdU16x16; inline;
function simd_min_u32x4(const a, b: TSimdU32x4): TSimdU32x4; inline;
function simd_min_u32x8(const a, b: TSimdU32x8): TSimdU32x8; inline;
function simd_min_u64x2(const a, b: TSimdU64x2): TSimdU64x2; inline;
function simd_min_u64x4(const a, b: TSimdU64x4): TSimdU64x4; inline;

// === 5. 最大值 ===

// 浮点最大值
function simd_max_f32x4(const a, b: TSimdF32x4): TSimdF32x4; inline;
function simd_max_f32x8(const a, b: TSimdF32x8): TSimdF32x8; inline;
function simd_max_f32x16(const a, b: TSimdF32x16): TSimdF32x16; inline;
function simd_max_f64x2(const a, b: TSimdF64x2): TSimdF64x2; inline;
function simd_max_f64x4(const a, b: TSimdF64x4): TSimdF64x4; inline;
function simd_max_f64x8(const a, b: TSimdF64x8): TSimdF64x8; inline;

// 有符号整数最大值
function simd_max_i8x16(const a, b: TSimdI8x16): TSimdI8x16; inline;
function simd_max_i8x32(const a, b: TSimdI8x32): TSimdI8x32; inline;
function simd_max_i16x8(const a, b: TSimdI16x8): TSimdI16x8; inline;
function simd_max_i16x16(const a, b: TSimdI16x16): TSimdI16x16; inline;
function simd_max_i32x4(const a, b: TSimdI32x4): TSimdI32x4; inline;
function simd_max_i32x8(const a, b: TSimdI32x8): TSimdI32x8; inline;
function simd_max_i64x2(const a, b: TSimdI64x2): TSimdI64x2; inline;
function simd_max_i64x4(const a, b: TSimdI64x4): TSimdI64x4; inline;

// 无符号整数最大值
function simd_max_u8x16(const a, b: TSimdU8x16): TSimdU8x16; inline;
function simd_max_u8x32(const a, b: TSimdU8x32): TSimdU8x32; inline;
function simd_max_u16x8(const a, b: TSimdU16x8): TSimdU16x8; inline;
function simd_max_u16x16(const a, b: TSimdU16x16): TSimdU16x16; inline;
function simd_max_u32x4(const a, b: TSimdU32x4): TSimdU32x4; inline;
function simd_max_u32x8(const a, b: TSimdU32x8): TSimdU32x8; inline;
function simd_max_u64x2(const a, b: TSimdU64x2): TSimdU64x2; inline;
function simd_max_u64x4(const a, b: TSimdU64x4): TSimdU64x4; inline;

// === 6. 取整函数 ===

// 向上取整
function simd_ceil_f32x4(const a: TSimdF32x4): TSimdF32x4; inline;
function simd_ceil_f32x8(const a: TSimdF32x8): TSimdF32x8; inline;
function simd_ceil_f64x2(const a: TSimdF64x2): TSimdF64x2; inline;
function simd_ceil_f64x4(const a: TSimdF64x4): TSimdF64x4; inline;

// 向下取整
function simd_floor_f32x4(const a: TSimdF32x4): TSimdF32x4; inline;
function simd_floor_f32x8(const a: TSimdF32x8): TSimdF32x8; inline;
function simd_floor_f64x2(const a: TSimdF64x2): TSimdF64x2; inline;
function simd_floor_f64x4(const a: TSimdF64x4): TSimdF64x4; inline;

// 四舍五入
function simd_round_f32x4(const a: TSimdF32x4): TSimdF32x4; inline;
function simd_round_f32x8(const a: TSimdF32x8): TSimdF32x8; inline;
function simd_round_f64x2(const a: TSimdF64x2): TSimdF64x2; inline;
function simd_round_f64x4(const a: TSimdF64x4): TSimdF64x4; inline;

// 截断（向零取整）
function simd_trunc_f32x4(const a: TSimdF32x4): TSimdF32x4; inline;
function simd_trunc_f32x8(const a: TSimdF32x8): TSimdF32x8; inline;
function simd_trunc_f64x2(const a: TSimdF64x2): TSimdF64x2; inline;
function simd_trunc_f64x4(const a: TSimdF64x4): TSimdF64x4; inline;

// === 7. 高级数学函数（规划中）===

// 三角函数
function simd_sin_f32x4(const a: TSimdF32x4): TSimdF32x4; inline;
function simd_cos_f32x4(const a: TSimdF32x4): TSimdF32x4; inline;
function simd_tan_f32x4(const a: TSimdF32x4): TSimdF32x4; inline;

// 指数和对数函数
function simd_exp_f32x4(const a: TSimdF32x4): TSimdF32x4; inline;
function simd_exp2_f32x4(const a: TSimdF32x4): TSimdF32x4; inline;
function simd_log_f32x4(const a: TSimdF32x4): TSimdF32x4; inline;
function simd_log2_f32x4(const a: TSimdF32x4): TSimdF32x4; inline;
function simd_log10_f32x4(const a: TSimdF32x4): TSimdF32x4; inline;

// 幂函数
function simd_pow_f32x4(const a, b: TSimdF32x4): TSimdF32x4; inline;

implementation

uses
  fafafa.core.simd.scalar,
  Math;

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

function Min(a, b: Int8): Int8; inline;
begin
  if a < b then Result := a else Result := b;
end;

function Max(a, b: Int8): Int8; inline;
begin
  if a > b then Result := a else Result := b;
end;

function Min(a, b: Int16): Int16; inline;
begin
  if a < b then Result := a else Result := b;
end;

function Max(a, b: Int16): Int16; inline;
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

function Min(a, b: Int64): Int64; inline;
begin
  if a < b then Result := a else Result := b;
end;

function Max(a, b: Int64): Int64; inline;
begin
  if a > b then Result := a else Result := b;
end;

function Min(a, b: Byte): Byte; inline;
begin
  if a < b then Result := a else Result := b;
end;

function Max(a, b: Byte): Byte; inline;
begin
  if a > b then Result := a else Result := b;
end;

function Min(a, b: UInt16): UInt16; inline;
begin
  if a < b then Result := a else Result := b;
end;

function Max(a, b: UInt16): UInt16; inline;
begin
  if a > b then Result := a else Result := b;
end;

function Min(a, b: UInt32): UInt32; inline;
begin
  if a < b then Result := a else Result := b;
end;

function Max(a, b: UInt32): UInt32; inline;
begin
  if a > b then Result := a else Result := b;
end;

function Min(a, b: UInt64): UInt64; inline;
begin
  if a < b then Result := a else Result := b;
end;

function Max(a, b: UInt64): UInt64; inline;
begin
  if a > b then Result := a else Result := b;
end;

function Abs(x: Single): Single; inline;
begin
  if x < 0 then Result := -x else Result := x;
end;

function Abs(x: Double): Double; inline;
begin
  if x < 0 then Result := -x else Result := x;
end;

function Abs(x: Int8): Int8; inline;
begin
  if x < 0 then Result := -x else Result := x;
end;

function Abs(x: Int16): Int16; inline;
begin
  if x < 0 then Result := -x else Result := x;
end;

function Abs(x: Int32): Int32; inline;
begin
  if x < 0 then Result := -x else Result := x;
end;

function Abs(x: Int64): Int64; inline;
begin
  if x < 0 then Result := -x else Result := x;
end;

function Sqrt(x: Single): Single; inline;
begin
  Result := System.Sqrt(x);
end;

function Sqrt(x: Double): Double; inline;
begin
  Result := System.Sqrt(x);
end;

// === 绝对值实现 ===

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

function simd_abs_f32x16(const a: TSimdF32x16): TSimdF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := Abs(a[i]);
end;

function simd_abs_f64x2(const a: TSimdF64x2): TSimdF64x2;
begin
  Result := simd_abs_f64x2_scalar(a);
end;

function simd_abs_f64x4(const a: TSimdF64x4): TSimdF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Abs(a[i]);
end;

function simd_abs_f64x8(const a: TSimdF64x8): TSimdF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := Abs(a[i]);
end;

// 整数绝对值
function simd_abs_i8x16(const a: TSimdI8x16): TSimdI8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := Abs(a[i]);
end;

function simd_abs_i8x32(const a: TSimdI8x32): TSimdI8x32;
var i: Integer;
begin
  for i := 0 to 31 do
    Result[i] := Abs(a[i]);
end;

function simd_abs_i16x8(const a: TSimdI16x8): TSimdI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := Abs(a[i]);
end;

function simd_abs_i16x16(const a: TSimdI16x16): TSimdI16x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := Abs(a[i]);
end;

function simd_abs_i32x4(const a: TSimdI32x4): TSimdI32x4;
begin
  Result := simd_abs_i32x4_scalar(a);
end;

function simd_abs_i32x8(const a: TSimdI32x8): TSimdI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := Abs(a[i]);
end;

function simd_abs_i64x2(const a: TSimdI64x2): TSimdI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := Abs(a[i]);
end;

function simd_abs_i64x4(const a: TSimdI64x4): TSimdI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Abs(a[i]);
end;

// === 平方根实现 ===

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

function simd_sqrt_f32x16(const a: TSimdF32x16): TSimdF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
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

function simd_sqrt_f64x8(const a: TSimdF64x8): TSimdF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := Sqrt(a[i]);
end;

// === 倒数平方根实现 ===

function simd_rsqrt_f32x4(const a: TSimdF32x4): TSimdF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := 1.0 / Sqrt(a[i]);
end;

function simd_rsqrt_f32x8(const a: TSimdF32x8): TSimdF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := 1.0 / Sqrt(a[i]);
end;

function simd_rsqrt_f32x16(const a: TSimdF32x16): TSimdF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := 1.0 / Sqrt(a[i]);
end;

// === 最小值实现 ===

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

function simd_min_f32x16(const a, b: TSimdF32x16): TSimdF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := Min(a[i], b[i]);
end;

function simd_min_f64x2(const a, b: TSimdF64x2): TSimdF64x2;
begin
  Result := simd_min_f64x2_scalar(a, b);
end;

function simd_min_f64x4(const a, b: TSimdF64x4): TSimdF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Min(a[i], b[i]);
end;

function simd_min_f64x8(const a, b: TSimdF64x8): TSimdF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := Min(a[i], b[i]);
end;

// 有符号整数最小值
function simd_min_i8x16(const a, b: TSimdI8x16): TSimdI8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := Min(a[i], b[i]);
end;

function simd_min_i8x32(const a, b: TSimdI8x32): TSimdI8x32;
var i: Integer;
begin
  for i := 0 to 31 do
    Result[i] := Min(a[i], b[i]);
end;

function simd_min_i16x8(const a, b: TSimdI16x8): TSimdI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := Min(a[i], b[i]);
end;

function simd_min_i16x16(const a, b: TSimdI16x16): TSimdI16x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := Min(a[i], b[i]);
end;

function simd_min_i32x4(const a, b: TSimdI32x4): TSimdI32x4;
begin
  Result := simd_min_i32x4_scalar(a, b);
end;

function simd_min_i32x8(const a, b: TSimdI32x8): TSimdI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := Min(a[i], b[i]);
end;

function simd_min_i64x2(const a, b: TSimdI64x2): TSimdI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := Min(a[i], b[i]);
end;

function simd_min_i64x4(const a, b: TSimdI64x4): TSimdI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Min(a[i], b[i]);
end;

// 无符号整数最小值
function simd_min_u8x16(const a, b: TSimdU8x16): TSimdU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := Min(a[i], b[i]);
end;

function simd_min_u8x32(const a, b: TSimdU8x32): TSimdU8x32;
var i: Integer;
begin
  for i := 0 to 31 do
    Result[i] := Min(a[i], b[i]);
end;

function simd_min_u16x8(const a, b: TSimdU16x8): TSimdU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := Min(a[i], b[i]);
end;

function simd_min_u16x16(const a, b: TSimdU16x16): TSimdU16x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := Min(a[i], b[i]);
end;

function simd_min_u32x4(const a, b: TSimdU32x4): TSimdU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Min(a[i], b[i]);
end;

function simd_min_u32x8(const a, b: TSimdU32x8): TSimdU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := Min(a[i], b[i]);
end;

function simd_min_u64x2(const a, b: TSimdU64x2): TSimdU64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := Min(a[i], b[i]);
end;

function simd_min_u64x4(const a, b: TSimdU64x4): TSimdU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Min(a[i], b[i]);
end;

// === 最大值实现 ===

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

function simd_max_f32x16(const a, b: TSimdF32x16): TSimdF32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := Max(a[i], b[i]);
end;

function simd_max_f64x2(const a, b: TSimdF64x2): TSimdF64x2;
begin
  Result := simd_max_f64x2_scalar(a, b);
end;

function simd_max_f64x4(const a, b: TSimdF64x4): TSimdF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Max(a[i], b[i]);
end;

function simd_max_f64x8(const a, b: TSimdF64x8): TSimdF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := Max(a[i], b[i]);
end;

// 有符号整数最大值
function simd_max_i8x16(const a, b: TSimdI8x16): TSimdI8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := Max(a[i], b[i]);
end;

function simd_max_i8x32(const a, b: TSimdI8x32): TSimdI8x32;
var i: Integer;
begin
  for i := 0 to 31 do
    Result[i] := Max(a[i], b[i]);
end;

function simd_max_i16x8(const a, b: TSimdI16x8): TSimdI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := Max(a[i], b[i]);
end;

function simd_max_i16x16(const a, b: TSimdI16x16): TSimdI16x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := Max(a[i], b[i]);
end;

function simd_max_i32x4(const a, b: TSimdI32x4): TSimdI32x4;
begin
  Result := simd_max_i32x4_scalar(a, b);
end;

function simd_max_i32x8(const a, b: TSimdI32x8): TSimdI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := Max(a[i], b[i]);
end;

function simd_max_i64x2(const a, b: TSimdI64x2): TSimdI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := Max(a[i], b[i]);
end;

function simd_max_i64x4(const a, b: TSimdI64x4): TSimdI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Max(a[i], b[i]);
end;

// 无符号整数最大值
function simd_max_u8x16(const a, b: TSimdU8x16): TSimdU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := Max(a[i], b[i]);
end;

function simd_max_u8x32(const a, b: TSimdU8x32): TSimdU8x32;
var i: Integer;
begin
  for i := 0 to 31 do
    Result[i] := Max(a[i], b[i]);
end;

function simd_max_u16x8(const a, b: TSimdU16x8): TSimdU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := Max(a[i], b[i]);
end;

function simd_max_u16x16(const a, b: TSimdU16x16): TSimdU16x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := Max(a[i], b[i]);
end;

function simd_max_u32x4(const a, b: TSimdU32x4): TSimdU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Max(a[i], b[i]);
end;

function simd_max_u32x8(const a, b: TSimdU32x8): TSimdU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := Max(a[i], b[i]);
end;

function simd_max_u64x2(const a, b: TSimdU64x2): TSimdU64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := Max(a[i], b[i]);
end;

function simd_max_u64x4(const a, b: TSimdU64x4): TSimdU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Max(a[i], b[i]);
end;

// === 取整函数实现 ===

// 向上取整
function simd_ceil_f32x4(const a: TSimdF32x4): TSimdF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Ceil(a[i]);
end;

function simd_ceil_f32x8(const a: TSimdF32x8): TSimdF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := Ceil(a[i]);
end;

function simd_ceil_f64x2(const a: TSimdF64x2): TSimdF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := Ceil(a[i]);
end;

function simd_ceil_f64x4(const a: TSimdF64x4): TSimdF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Ceil(a[i]);
end;

// 向下取整
function simd_floor_f32x4(const a: TSimdF32x4): TSimdF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Floor(a[i]);
end;

function simd_floor_f32x8(const a: TSimdF32x8): TSimdF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := Floor(a[i]);
end;

function simd_floor_f64x2(const a: TSimdF64x2): TSimdF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := Floor(a[i]);
end;

function simd_floor_f64x4(const a: TSimdF64x4): TSimdF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Floor(a[i]);
end;

// 四舍五入
function simd_round_f32x4(const a: TSimdF32x4): TSimdF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := System.Round(a[i]);
end;

function simd_round_f32x8(const a: TSimdF32x8): TSimdF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := System.Round(a[i]);
end;

function simd_round_f64x2(const a: TSimdF64x2): TSimdF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := System.Round(a[i]);
end;

function simd_round_f64x4(const a: TSimdF64x4): TSimdF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := System.Round(a[i]);
end;

// 截断（向零取整）
function simd_trunc_f32x4(const a: TSimdF32x4): TSimdF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := System.Trunc(a[i]);
end;

function simd_trunc_f32x8(const a: TSimdF32x8): TSimdF32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := System.Trunc(a[i]);
end;

function simd_trunc_f64x2(const a: TSimdF64x2): TSimdF64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := System.Trunc(a[i]);
end;

function simd_trunc_f64x4(const a: TSimdF64x4): TSimdF64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := System.Trunc(a[i]);
end;

// === 高级数学函数实现（标量回退）===

// 三角函数
function simd_sin_f32x4(const a: TSimdF32x4): TSimdF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Sin(a[i]);
end;

function simd_cos_f32x4(const a: TSimdF32x4): TSimdF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Cos(a[i]);
end;

function simd_tan_f32x4(const a: TSimdF32x4): TSimdF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Sin(a[i]) / Cos(a[i]);
end;

// 指数和对数函数
function simd_exp_f32x4(const a: TSimdF32x4): TSimdF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Exp(a[i]);
end;

function simd_exp2_f32x4(const a: TSimdF32x4): TSimdF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Power(2.0, a[i]);
end;

function simd_log_f32x4(const a: TSimdF32x4): TSimdF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Ln(a[i]);
end;

function simd_log2_f32x4(const a: TSimdF32x4): TSimdF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Log2(a[i]);
end;

function simd_log10_f32x4(const a: TSimdF32x4): TSimdF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Log10(a[i]);
end;

// 幂函数
function simd_pow_f32x4(const a, b: TSimdF32x4): TSimdF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := Power(a[i], b[i]);
end;

end.
