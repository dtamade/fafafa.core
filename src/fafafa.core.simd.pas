unit fafafa.core.simd;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  // 新的 SIMD 模块架构
  fafafa.core.simd.types,
  fafafa.core.simd.arithmetic,
  fafafa.core.simd.compare,
  fafafa.core.simd.math,
  fafafa.core.simd.reduce,
  fafafa.core.simd.bitwise,
  
  // 保留的旧模块（向后兼容）
  fafafa.core.simd.core,
  fafafa.core.simd.scalar,
  fafafa.core.simd.detect,
  fafafa.core.simd.mem,
  fafafa.core.simd.search,
  fafafa.core.simd.text,
  fafafa.core.simd.bitset;

// === 重新导出所有类型 ===
type
  // 浮点向量类型
  TSimdF32x4  = fafafa.core.simd.types.TSimdF32x4;
  TSimdF32x8  = fafafa.core.simd.types.TSimdF32x8;
  TSimdF32x16 = fafafa.core.simd.types.TSimdF32x16;
  TSimdF64x2  = fafafa.core.simd.types.TSimdF64x2;
  TSimdF64x4  = fafafa.core.simd.types.TSimdF64x4;
  TSimdF64x8  = fafafa.core.simd.types.TSimdF64x8;

  // 有符号整数向量类型
  TSimdI8x16  = fafafa.core.simd.types.TSimdI8x16;
  TSimdI8x32  = fafafa.core.simd.types.TSimdI8x32;
  TSimdI8x64  = fafafa.core.simd.types.TSimdI8x64;
  TSimdI16x8  = fafafa.core.simd.types.TSimdI16x8;
  TSimdI16x16 = fafafa.core.simd.types.TSimdI16x16;
  TSimdI16x32 = fafafa.core.simd.types.TSimdI16x32;
  TSimdI32x4  = fafafa.core.simd.types.TSimdI32x4;
  TSimdI32x8  = fafafa.core.simd.types.TSimdI32x8;
  TSimdI32x16 = fafafa.core.simd.types.TSimdI32x16;
  TSimdI64x2  = fafafa.core.simd.types.TSimdI64x2;
  TSimdI64x4  = fafafa.core.simd.types.TSimdI64x4;
  TSimdI64x8  = fafafa.core.simd.types.TSimdI64x8;

  // 无符号整数向量类型
  TSimdU8x16  = fafafa.core.simd.types.TSimdU8x16;
  TSimdU8x32  = fafafa.core.simd.types.TSimdU8x32;
  TSimdU8x64  = fafafa.core.simd.types.TSimdU8x64;
  TSimdU16x8  = fafafa.core.simd.types.TSimdU16x8;
  TSimdU16x16 = fafafa.core.simd.types.TSimdU16x16;
  TSimdU16x32 = fafafa.core.simd.types.TSimdU16x32;
  TSimdU32x4  = fafafa.core.simd.types.TSimdU32x4;
  TSimdU32x8  = fafafa.core.simd.types.TSimdU32x8;
  TSimdU32x16 = fafafa.core.simd.types.TSimdU32x16;
  TSimdU64x2  = fafafa.core.simd.types.TSimdU64x2;
  TSimdU64x4  = fafafa.core.simd.types.TSimdU64x4;
  TSimdU64x8  = fafafa.core.simd.types.TSimdU64x8;

  // 掩码类型
  TSimdMask2  = fafafa.core.simd.types.TSimdMask2;
  TSimdMask4  = fafafa.core.simd.types.TSimdMask4;
  TSimdMask8  = fafafa.core.simd.types.TSimdMask8;
  TSimdMask16 = fafafa.core.simd.types.TSimdMask16;
  TSimdMask32 = fafafa.core.simd.types.TSimdMask32;
  TSimdMask64 = fafafa.core.simd.types.TSimdMask64;

// === 重新导出核心算术运算函数 ===

// 加法运算
function simd_add_f32x4(const a, b: TSimdF32x4): TSimdF32x4; inline;
function simd_add_f32x8(const a, b: TSimdF32x8): TSimdF32x8; inline;
function simd_add_f64x2(const a, b: TSimdF64x2): TSimdF64x2; inline;
function simd_add_f64x4(const a, b: TSimdF64x4): TSimdF64x4; inline;

function simd_add_i8x16(const a, b: TSimdI8x16): TSimdI8x16; inline;
function simd_add_i16x8(const a, b: TSimdI16x8): TSimdI16x8; inline;
function simd_add_i32x4(const a, b: TSimdI32x4): TSimdI32x4; inline;
function simd_add_i64x2(const a, b: TSimdI64x2): TSimdI64x2; inline;

function simd_add_u8x16(const a, b: TSimdU8x16): TSimdU8x16; inline;
function simd_add_u16x8(const a, b: TSimdU16x8): TSimdU16x8; inline;
function simd_add_u32x4(const a, b: TSimdU32x4): TSimdU32x4; inline;
function simd_add_u64x2(const a, b: TSimdU64x2): TSimdU64x2; inline;

// 减法运算
function simd_sub_f32x4(const a, b: TSimdF32x4): TSimdF32x4; inline;
function simd_sub_f32x8(const a, b: TSimdF32x8): TSimdF32x8; inline;
function simd_sub_f64x2(const a, b: TSimdF64x2): TSimdF64x2; inline;
function simd_sub_f64x4(const a, b: TSimdF64x4): TSimdF64x4; inline;

function simd_sub_i8x16(const a, b: TSimdI8x16): TSimdI8x16; inline;
function simd_sub_i16x8(const a, b: TSimdI16x8): TSimdI16x8; inline;
function simd_sub_i32x4(const a, b: TSimdI32x4): TSimdI32x4; inline;
function simd_sub_i64x2(const a, b: TSimdI64x2): TSimdI64x2; inline;

function simd_sub_u8x16(const a, b: TSimdU8x16): TSimdU8x16; inline;
function simd_sub_u16x8(const a, b: TSimdU16x8): TSimdU16x8; inline;
function simd_sub_u32x4(const a, b: TSimdU32x4): TSimdU32x4; inline;
function simd_sub_u64x2(const a, b: TSimdU64x2): TSimdU64x2; inline;

// 乘法运算
function simd_mul_f32x4(const a, b: TSimdF32x4): TSimdF32x4; inline;
function simd_mul_f32x8(const a, b: TSimdF32x8): TSimdF32x8; inline;
function simd_mul_f64x2(const a, b: TSimdF64x2): TSimdF64x2; inline;
function simd_mul_f64x4(const a, b: TSimdF64x4): TSimdF64x4; inline;

function simd_mul_i16x8(const a, b: TSimdI16x8): TSimdI16x8; inline;
function simd_mul_i32x4(const a, b: TSimdI32x4): TSimdI32x4; inline;
function simd_mul_i64x2(const a, b: TSimdI64x2): TSimdI64x2; inline;

function simd_mul_u16x8(const a, b: TSimdU16x8): TSimdU16x8; inline;
function simd_mul_u32x4(const a, b: TSimdU32x4): TSimdU32x4; inline;
function simd_mul_u64x2(const a, b: TSimdU64x2): TSimdU64x2; inline;

// 除法运算（仅浮点）
function simd_div_f32x4(const a, b: TSimdF32x4): TSimdF32x4; inline;
function simd_div_f32x8(const a, b: TSimdF32x8): TSimdF32x8; inline;
function simd_div_f64x2(const a, b: TSimdF64x2): TSimdF64x2; inline;
function simd_div_f64x4(const a, b: TSimdF64x4): TSimdF64x4; inline;

// === 重新导出核心比较运算函数 ===

// 相等比较（仅核心类型）
function simd_eq_f32x4(const a, b: TSimdF32x4): TSimdMask4; inline;
function simd_eq_i32x4(const a, b: TSimdI32x4): TSimdMask4; inline;

// 小于比较（仅核心类型）
function simd_lt_f32x4(const a, b: TSimdF32x4): TSimdMask4; inline;
function simd_lt_i32x4(const a, b: TSimdI32x4): TSimdMask4; inline;

// === 重新导出核心数学函数 ===

// 绝对值（仅核心类型）
function simd_abs_f32x4(const a: TSimdF32x4): TSimdF32x4; inline;
function simd_abs_i32x4(const a: TSimdI32x4): TSimdI32x4; inline;

// 平方根（仅浮点）
function simd_sqrt_f32x4(const a: TSimdF32x4): TSimdF32x4; inline;

// 最小值/最大值（仅核心类型）
function simd_min_f32x4(const a, b: TSimdF32x4): TSimdF32x4; inline;
function simd_max_f32x4(const a, b: TSimdF32x4): TSimdF32x4; inline;
function simd_min_i32x4(const a, b: TSimdI32x4): TSimdI32x4; inline;
function simd_max_i32x4(const a, b: TSimdI32x4): TSimdI32x4; inline;

// === 重新导出核心聚合运算函数 ===

// 求和（仅核心类型）
function simd_reduce_add_f32x4(const a: TSimdF32x4): Single; inline;
function simd_reduce_add_i32x4(const a: TSimdI32x4): Int32; inline;

// 最小值/最大值聚合（仅核心类型）
function simd_reduce_min_f32x4(const a: TSimdF32x4): Single; inline;
function simd_reduce_max_f32x4(const a: TSimdF32x4): Single; inline;
function simd_reduce_min_i32x4(const a: TSimdI32x4): Int32; inline;
function simd_reduce_max_i32x4(const a: TSimdI32x4): Int32; inline;

implementation

// === 算术运算实现（内联门面函数）===

// 加法运算
function simd_add_f32x4(const a, b: TSimdF32x4): TSimdF32x4;
begin
  Result := fafafa.core.simd.arithmetic.simd_add_f32x4(a, b);
end;

function simd_add_f32x8(const a, b: TSimdF32x8): TSimdF32x8;
begin
  Result := fafafa.core.simd.arithmetic.simd_add_f32x8(a, b);
end;

function simd_add_f64x2(const a, b: TSimdF64x2): TSimdF64x2;
begin
  Result := fafafa.core.simd.arithmetic.simd_add_f64x2(a, b);
end;

function simd_add_f64x4(const a, b: TSimdF64x4): TSimdF64x4;
begin
  Result := fafafa.core.simd.arithmetic.simd_add_f64x4(a, b);
end;

// 整数加法
function simd_add_i8x16(const a, b: TSimdI8x16): TSimdI8x16;
begin
  Result := fafafa.core.simd.arithmetic.simd_add_i8x16(a, b);
end;

function simd_add_i16x8(const a, b: TSimdI16x8): TSimdI16x8;
begin
  Result := fafafa.core.simd.arithmetic.simd_add_i16x8(a, b);
end;

function simd_add_i32x4(const a, b: TSimdI32x4): TSimdI32x4;
begin
  Result := fafafa.core.simd.arithmetic.simd_add_i32x4(a, b);
end;

function simd_add_i64x2(const a, b: TSimdI64x2): TSimdI64x2;
begin
  Result := fafafa.core.simd.arithmetic.simd_add_i64x2(a, b);
end;

// 无符号整数加法
function simd_add_u8x16(const a, b: TSimdU8x16): TSimdU8x16;
begin
  Result := fafafa.core.simd.arithmetic.simd_add_u8x16(a, b);
end;

function simd_add_u16x8(const a, b: TSimdU16x8): TSimdU16x8;
begin
  Result := fafafa.core.simd.arithmetic.simd_add_u16x8(a, b);
end;

function simd_add_u32x4(const a, b: TSimdU32x4): TSimdU32x4;
begin
  Result := fafafa.core.simd.arithmetic.simd_add_u32x4(a, b);
end;

function simd_add_u64x2(const a, b: TSimdU64x2): TSimdU64x2;
begin
  Result := fafafa.core.simd.arithmetic.simd_add_u64x2(a, b);
end;

// === 减法运算实现 ===

function simd_sub_f32x4(const a, b: TSimdF32x4): TSimdF32x4;
begin
  Result := fafafa.core.simd.arithmetic.simd_sub_f32x4(a, b);
end;

function simd_sub_f32x8(const a, b: TSimdF32x8): TSimdF32x8;
begin
  Result := fafafa.core.simd.arithmetic.simd_sub_f32x8(a, b);
end;

function simd_sub_f64x2(const a, b: TSimdF64x2): TSimdF64x2;
begin
  Result := fafafa.core.simd.arithmetic.simd_sub_f64x2(a, b);
end;

function simd_sub_f64x4(const a, b: TSimdF64x4): TSimdF64x4;
begin
  Result := fafafa.core.simd.arithmetic.simd_sub_f64x4(a, b);
end;

function simd_sub_i8x16(const a, b: TSimdI8x16): TSimdI8x16;
begin
  Result := fafafa.core.simd.arithmetic.simd_sub_i8x16(a, b);
end;

function simd_sub_i16x8(const a, b: TSimdI16x8): TSimdI16x8;
begin
  Result := fafafa.core.simd.arithmetic.simd_sub_i16x8(a, b);
end;

function simd_sub_i32x4(const a, b: TSimdI32x4): TSimdI32x4;
begin
  Result := fafafa.core.simd.arithmetic.simd_sub_i32x4(a, b);
end;

function simd_sub_i64x2(const a, b: TSimdI64x2): TSimdI64x2;
begin
  Result := fafafa.core.simd.arithmetic.simd_sub_i64x2(a, b);
end;

function simd_sub_u8x16(const a, b: TSimdU8x16): TSimdU8x16;
begin
  Result := fafafa.core.simd.arithmetic.simd_sub_u8x16(a, b);
end;

function simd_sub_u16x8(const a, b: TSimdU16x8): TSimdU16x8;
begin
  Result := fafafa.core.simd.arithmetic.simd_sub_u16x8(a, b);
end;

function simd_sub_u32x4(const a, b: TSimdU32x4): TSimdU32x4;
begin
  Result := fafafa.core.simd.arithmetic.simd_sub_u32x4(a, b);
end;

function simd_sub_u64x2(const a, b: TSimdU64x2): TSimdU64x2;
begin
  Result := fafafa.core.simd.arithmetic.simd_sub_u64x2(a, b);
end;

// === 乘法运算实现 ===

function simd_mul_f32x4(const a, b: TSimdF32x4): TSimdF32x4;
begin
  Result := fafafa.core.simd.arithmetic.simd_mul_f32x4(a, b);
end;

function simd_mul_f32x8(const a, b: TSimdF32x8): TSimdF32x8;
begin
  Result := fafafa.core.simd.arithmetic.simd_mul_f32x8(a, b);
end;

function simd_mul_f64x2(const a, b: TSimdF64x2): TSimdF64x2;
begin
  Result := fafafa.core.simd.arithmetic.simd_mul_f64x2(a, b);
end;

function simd_mul_f64x4(const a, b: TSimdF64x4): TSimdF64x4;
begin
  Result := fafafa.core.simd.arithmetic.simd_mul_f64x4(a, b);
end;

function simd_mul_i16x8(const a, b: TSimdI16x8): TSimdI16x8;
begin
  Result := fafafa.core.simd.arithmetic.simd_mul_i16x8(a, b);
end;

function simd_mul_i32x4(const a, b: TSimdI32x4): TSimdI32x4;
begin
  Result := fafafa.core.simd.arithmetic.simd_mul_i32x4(a, b);
end;

function simd_mul_i64x2(const a, b: TSimdI64x2): TSimdI64x2;
begin
  Result := fafafa.core.simd.arithmetic.simd_mul_i64x2(a, b);
end;

function simd_mul_u16x8(const a, b: TSimdU16x8): TSimdU16x8;
begin
  Result := fafafa.core.simd.arithmetic.simd_mul_u16x8(a, b);
end;

function simd_mul_u32x4(const a, b: TSimdU32x4): TSimdU32x4;
begin
  Result := fafafa.core.simd.arithmetic.simd_mul_u32x4(a, b);
end;

function simd_mul_u64x2(const a, b: TSimdU64x2): TSimdU64x2;
begin
  Result := fafafa.core.simd.arithmetic.simd_mul_u64x2(a, b);
end;

// === 除法运算实现 ===

function simd_div_f32x4(const a, b: TSimdF32x4): TSimdF32x4;
begin
  Result := fafafa.core.simd.arithmetic.simd_div_f32x4(a, b);
end;

function simd_div_f32x8(const a, b: TSimdF32x8): TSimdF32x8;
begin
  Result := fafafa.core.simd.arithmetic.simd_div_f32x8(a, b);
end;

function simd_div_f64x2(const a, b: TSimdF64x2): TSimdF64x2;
begin
  Result := fafafa.core.simd.arithmetic.simd_div_f64x2(a, b);
end;

function simd_div_f64x4(const a, b: TSimdF64x4): TSimdF64x4;
begin
  Result := fafafa.core.simd.arithmetic.simd_div_f64x4(a, b);
end;

// === 比较运算实现 ===

function simd_eq_f32x4(const a, b: TSimdF32x4): TSimdMask4;
begin
  Result := fafafa.core.simd.compare.simd_eq_f32x4(a, b);
end;

function simd_eq_f32x8(const a, b: TSimdF32x8): TSimdMask8;
begin
  Result := fafafa.core.simd.compare.simd_eq_f32x8(a, b);
end;

function simd_eq_f64x2(const a, b: TSimdF64x2): TSimdMask2;
begin
  Result := fafafa.core.simd.compare.simd_eq_f64x2(a, b);
end;

function simd_eq_f64x4(const a, b: TSimdF64x4): TSimdMask4;
begin
  Result := fafafa.core.simd.compare.simd_eq_f64x4(a, b);
end;

function simd_eq_i8x16(const a, b: TSimdI8x16): TSimdMask16;
begin
  Result := fafafa.core.simd.compare.simd_eq_i8x16(a, b);
end;

function simd_eq_i16x8(const a, b: TSimdI16x8): TSimdMask8;
begin
  Result := fafafa.core.simd.compare.simd_eq_i16x8(a, b);
end;

function simd_eq_i32x4(const a, b: TSimdI32x4): TSimdMask4;
begin
  Result := fafafa.core.simd.compare.simd_eq_i32x4(a, b);
end;

function simd_eq_i64x2(const a, b: TSimdI64x2): TSimdMask2;
begin
  Result := fafafa.core.simd.compare.simd_eq_i64x2(a, b);
end;

function simd_eq_u8x16(const a, b: TSimdU8x16): TSimdMask16;
begin
  Result := fafafa.core.simd.compare.simd_eq_u8x16(a, b);
end;

function simd_eq_u16x8(const a, b: TSimdU16x8): TSimdMask8;
begin
  Result := fafafa.core.simd.compare.simd_eq_u16x8(a, b);
end;

function simd_eq_u32x4(const a, b: TSimdU32x4): TSimdMask4;
begin
  Result := fafafa.core.simd.compare.simd_eq_u32x4(a, b);
end;

function simd_eq_u64x2(const a, b: TSimdU64x2): TSimdMask2;
begin
  Result := fafafa.core.simd.compare.simd_eq_u64x2(a, b);
end;

// === 剩余的比较运算实现 ===

function simd_lt_f32x4(const a, b: TSimdF32x4): TSimdMask4;
begin
  Result := fafafa.core.simd.compare.simd_lt_f32x4(a, b);
end;

function simd_lt_i32x4(const a, b: TSimdI32x4): TSimdMask4;
begin
  Result := fafafa.core.simd.compare.simd_lt_i32x4(a, b);
end;

// === 数学函数实现 ===

function simd_abs_f32x4(const a: TSimdF32x4): TSimdF32x4;
begin
  Result := fafafa.core.simd.math.simd_abs_f32x4(a);
end;

function simd_abs_i32x4(const a: TSimdI32x4): TSimdI32x4;
begin
  Result := fafafa.core.simd.math.simd_abs_i32x4(a);
end;

function simd_sqrt_f32x4(const a: TSimdF32x4): TSimdF32x4;
begin
  Result := fafafa.core.simd.math.simd_sqrt_f32x4(a);
end;

function simd_min_f32x4(const a, b: TSimdF32x4): TSimdF32x4;
begin
  Result := fafafa.core.simd.math.simd_min_f32x4(a, b);
end;

function simd_max_f32x4(const a, b: TSimdF32x4): TSimdF32x4;
begin
  Result := fafafa.core.simd.math.simd_max_f32x4(a, b);
end;

function simd_min_i32x4(const a, b: TSimdI32x4): TSimdI32x4;
begin
  Result := fafafa.core.simd.math.simd_min_i32x4(a, b);
end;

function simd_max_i32x4(const a, b: TSimdI32x4): TSimdI32x4;
begin
  Result := fafafa.core.simd.math.simd_max_i32x4(a, b);
end;

// === 聚合运算实现 ===

function simd_reduce_add_f32x4(const a: TSimdF32x4): Single;
begin
  Result := fafafa.core.simd.reduce.simd_reduce_add_f32x4(a);
end;

function simd_reduce_add_i32x4(const a: TSimdI32x4): Int32;
begin
  Result := fafafa.core.simd.reduce.simd_reduce_add_i32x4(a);
end;

function simd_reduce_min_f32x4(const a: TSimdF32x4): Single;
begin
  Result := fafafa.core.simd.reduce.simd_reduce_min_f32x4(a);
end;

function simd_reduce_max_f32x4(const a: TSimdF32x4): Single;
begin
  Result := fafafa.core.simd.reduce.simd_reduce_max_f32x4(a);
end;

function simd_reduce_min_i32x4(const a: TSimdI32x4): Int32;
begin
  Result := fafafa.core.simd.reduce.simd_reduce_min_i32x4(a);
end;

function simd_reduce_max_i32x4(const a: TSimdI32x4): Int32;
begin
  Result := fafafa.core.simd.reduce.simd_reduce_max_i32x4(a);
end;

end.
