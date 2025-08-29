unit fafafa.core.simd.v2.core;

{$mode objfpc}{$H+}

interface

uses
  fafafa.core.simd.v2.types;

// === 核心 SIMD 接口（对标 Rust std::simd）===

// === 1. 向量算术运算 ===

// 加法运算
function simd_add_f32x4(const a, b: TSimdF32x4): TSimdF32x4;
function simd_add_f32x8(const a, b: TSimdF32x8): TSimdF32x8;
function simd_add_f32x16(const a, b: TSimdF32x16): TSimdF32x16;
function simd_add_f64x2(const a, b: TSimdF64x2): TSimdF64x2;
function simd_add_f64x4(const a, b: TSimdF64x4): TSimdF64x4;
function simd_add_f64x8(const a, b: TSimdF64x8): TSimdF64x8;
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

// 不等比较
function simd_ne_f32x4(const a, b: TSimdF32x4): TSimdMask4;
function simd_ne_f64x2(const a, b: TSimdF64x2): TSimdMask2;
function simd_ne_i32x4(const a, b: TSimdI32x4): TSimdMask4;

// 小于比较
function simd_lt_f32x4(const a, b: TSimdF32x4): TSimdMask4;
function simd_lt_f32x8(const a, b: TSimdF32x8): TSimdMask8;
function simd_lt_f64x2(const a, b: TSimdF64x2): TSimdMask2;
function simd_lt_i32x4(const a, b: TSimdI32x4): TSimdMask4;

// 小于等于比较
function simd_le_f32x4(const a, b: TSimdF32x4): TSimdMask4;
function simd_le_f64x2(const a, b: TSimdF64x2): TSimdMask2;
function simd_le_i32x4(const a, b: TSimdI32x4): TSimdMask4;

// 大于比较
function simd_gt_f32x4(const a, b: TSimdF32x4): TSimdMask4;
function simd_gt_f64x2(const a, b: TSimdF64x2): TSimdMask2;
function simd_gt_i32x4(const a, b: TSimdI32x4): TSimdMask4;

// 大于等于比较
function simd_ge_f32x4(const a, b: TSimdF32x4): TSimdMask4;
function simd_ge_f64x2(const a, b: TSimdF64x2): TSimdMask2;
function simd_ge_i32x4(const a, b: TSimdI32x4): TSimdMask4;

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

// 倒数平方根
function simd_rsqrt_f32x4(const a: TSimdF32x4): TSimdF32x4;
function simd_rsqrt_f32x8(const a: TSimdF32x8): TSimdF32x8;

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

// 向上取整
function simd_ceil_f32x4(const a: TSimdF32x4): TSimdF32x4;
function simd_ceil_f64x2(const a: TSimdF64x2): TSimdF64x2;

// 向下取整
function simd_floor_f32x4(const a: TSimdF32x4): TSimdF32x4;
function simd_floor_f64x2(const a: TSimdF64x2): TSimdF64x2;

// 四舍五入
function simd_round_f32x4(const a: TSimdF32x4): TSimdF32x4;
function simd_round_f64x2(const a: TSimdF64x2): TSimdF64x2;

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

// === 6. 位运算 ===

// 按位与
function simd_and_u8x16(const a, b: TSimdU8x16): TSimdU8x16;
function simd_and_u8x32(const a, b: TSimdU8x32): TSimdU8x32;
function simd_and_i32x4(const a, b: TSimdI32x4): TSimdI32x4;

// 按位或
function simd_or_u8x16(const a, b: TSimdU8x16): TSimdU8x16;
function simd_or_u8x32(const a, b: TSimdU8x32): TSimdU8x32;
function simd_or_i32x4(const a, b: TSimdI32x4): TSimdI32x4;

// 按位异或
function simd_xor_u8x16(const a, b: TSimdU8x16): TSimdU8x16;
function simd_xor_u8x32(const a, b: TSimdU8x32): TSimdU8x32;
function simd_xor_i32x4(const a, b: TSimdI32x4): TSimdI32x4;

// 按位取反
function simd_not_u8x16(const a: TSimdU8x16): TSimdU8x16;
function simd_not_u8x32(const a: TSimdU8x32): TSimdU8x32;
function simd_not_i32x4(const a: TSimdI32x4): TSimdI32x4;

// === 7. 移位运算 ===

// 左移
function simd_shl_i32x4(const a: TSimdI32x4; count: Integer): TSimdI32x4;
function simd_shl_i32x8(const a: TSimdI32x8; count: Integer): TSimdI32x8;

// 右移（算术）
function simd_shr_i32x4(const a: TSimdI32x4; count: Integer): TSimdI32x4;
function simd_shr_i32x8(const a: TSimdI32x8; count: Integer): TSimdI32x8;

// 右移（逻辑）
function simd_shrl_u32x4(const a: TSimdI32x4; count: Integer): TSimdI32x4;
function simd_shrl_u32x8(const a: TSimdI32x8; count: Integer): TSimdI32x8;

// === 8. 类型转换 ===

// 浮点到整数转换
function simd_cvt_f32x4_to_i32x4(const a: TSimdF32x4): TSimdI32x4;
function simd_cvt_f64x2_to_i32x2(const a: TSimdF64x2): TSimdI32x2;

// 整数到浮点转换
function simd_cvt_i32x4_to_f32x4(const a: TSimdI32x4): TSimdF32x4;
function simd_cvt_i32x2_to_f64x2(const a: TSimdI32x2): TSimdF64x2;

// 位转换（不改变位模式）
function simd_cast_f32x4_to_i32x4(const a: TSimdF32x4): TSimdI32x4;
function simd_cast_i32x4_to_f32x4(const a: TSimdI32x4): TSimdF32x4;

// === 9. 重排和混洗 ===

// 广播单个值
function simd_splat_f32x4(value: Single): TSimdF32x4;
function simd_splat_f32x8(value: Single): TSimdF32x8;
function simd_splat_i32x4(value: Int32): TSimdI32x4;

// 混洗操作
function simd_shuffle_f32x4(const a, b: TSimdF32x4; i0, i1, i2, i3: Integer): TSimdF32x4;
function simd_shuffle_i32x4(const a, b: TSimdI32x4; i0, i1, i2, i3: Integer): TSimdI32x4;

// 提取元素
function simd_extract_f32x4(const a: TSimdF32x4; index: Integer): Single;
function simd_extract_i32x4(const a: TSimdI32x4; index: Integer): Int32;

// 插入元素
function simd_insert_f32x4(const a: TSimdF32x4; value: Single; index: Integer): TSimdF32x4;
function simd_insert_i32x4(const a: TSimdI32x4; value: Int32; index: Integer): TSimdI32x4;

// === 10. 条件选择 ===

// 基于掩码选择
function simd_select_f32x4(const mask: TSimdMask4; const a, b: TSimdF32x4): TSimdF32x4;
function simd_select_f32x8(const mask: TSimdMask8; const a, b: TSimdF32x8): TSimdF32x8;
function simd_select_i32x4(const mask: TSimdMask4; const a, b: TSimdI32x4): TSimdI32x4;

implementation

// 实现将在具体的指令集模块中提供
// 这里只提供标量回退实现作为示例

function simd_add_f32x4(const a, b: TSimdF32x4): TSimdF32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] + b[i];
end;

function simd_reduce_add_f32x4(const a: TSimdF32x4): Single;
var i: Integer;
begin
  Result := 0.0;
  for i := 0 to 3 do
    Result := Result + a[i];
end;

// ... 其他函数的标量实现

end.
