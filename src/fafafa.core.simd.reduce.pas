unit fafafa.core.simd.reduce;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.types;

// === 聚合运算（对标 Rust std::simd）===
// 统一使用 simd_ 前缀，遵循 Rust 命名规范

// === 1. 求和（Reduce Add）===

// 浮点求和
function simd_reduce_add_f32x4(const a: TSimdF32x4): Single; inline;
function simd_reduce_add_f32x8(const a: TSimdF32x8): Single; inline;
function simd_reduce_add_f32x16(const a: TSimdF32x16): Single; inline;
function simd_reduce_add_f64x2(const a: TSimdF64x2): Double; inline;
function simd_reduce_add_f64x4(const a: TSimdF64x4): Double; inline;
function simd_reduce_add_f64x8(const a: TSimdF64x8): Double; inline;

// 整数求和
function simd_reduce_add_i8x16(const a: TSimdI8x16): Int32; inline;
function simd_reduce_add_i8x32(const a: TSimdI8x32): Int32; inline;
function simd_reduce_add_i16x8(const a: TSimdI16x8): Int32; inline;
function simd_reduce_add_i16x16(const a: TSimdI16x16): Int32; inline;
function simd_reduce_add_i32x4(const a: TSimdI32x4): Int32; inline;
function simd_reduce_add_i32x8(const a: TSimdI32x8): Int32; inline;
function simd_reduce_add_i64x2(const a: TSimdI64x2): Int64; inline;
function simd_reduce_add_i64x4(const a: TSimdI64x4): Int64; inline;

// 无符号整数求和
function simd_reduce_add_u8x16(const a: TSimdU8x16): UInt32; inline;
function simd_reduce_add_u8x32(const a: TSimdU8x32): UInt32; inline;
function simd_reduce_add_u16x8(const a: TSimdU16x8): UInt32; inline;
function simd_reduce_add_u16x16(const a: TSimdU16x16): UInt32; inline;
function simd_reduce_add_u32x4(const a: TSimdU32x4): UInt32; inline;
function simd_reduce_add_u32x8(const a: TSimdU32x8): UInt32; inline;
function simd_reduce_add_u64x2(const a: TSimdU64x2): UInt64; inline;
function simd_reduce_add_u64x4(const a: TSimdU64x4): UInt64; inline;

// === 2. 求积（Reduce Multiply）===

// 浮点求积
function simd_reduce_mul_f32x4(const a: TSimdF32x4): Single; inline;
function simd_reduce_mul_f32x8(const a: TSimdF32x8): Single; inline;
function simd_reduce_mul_f64x2(const a: TSimdF64x2): Double; inline;
function simd_reduce_mul_f64x4(const a: TSimdF64x4): Double; inline;

// 整数求积
function simd_reduce_mul_i16x8(const a: TSimdI16x8): Int32; inline;
function simd_reduce_mul_i32x4(const a: TSimdI32x4): Int32; inline;
function simd_reduce_mul_i32x8(const a: TSimdI32x8): Int32; inline;
function simd_reduce_mul_i64x2(const a: TSimdI64x2): Int64; inline;

// 无符号整数求积
function simd_reduce_mul_u16x8(const a: TSimdU16x8): UInt32; inline;
function simd_reduce_mul_u32x4(const a: TSimdU32x4): UInt32; inline;
function simd_reduce_mul_u32x8(const a: TSimdU32x8): UInt32; inline;
function simd_reduce_mul_u64x2(const a: TSimdU64x2): UInt64; inline;

// === 3. 最小值（Reduce Min）===

// 浮点最小值
function simd_reduce_min_f32x4(const a: TSimdF32x4): Single; inline;
function simd_reduce_min_f32x8(const a: TSimdF32x8): Single; inline;
function simd_reduce_min_f32x16(const a: TSimdF32x16): Single; inline;
function simd_reduce_min_f64x2(const a: TSimdF64x2): Double; inline;
function simd_reduce_min_f64x4(const a: TSimdF64x4): Double; inline;
function simd_reduce_min_f64x8(const a: TSimdF64x8): Double; inline;

// 有符号整数最小值
function simd_reduce_min_i8x16(const a: TSimdI8x16): Int8; inline;
function simd_reduce_min_i8x32(const a: TSimdI8x32): Int8; inline;
function simd_reduce_min_i16x8(const a: TSimdI16x8): Int16; inline;
function simd_reduce_min_i16x16(const a: TSimdI16x16): Int16; inline;
function simd_reduce_min_i32x4(const a: TSimdI32x4): Int32; inline;
function simd_reduce_min_i32x8(const a: TSimdI32x8): Int32; inline;
function simd_reduce_min_i64x2(const a: TSimdI64x2): Int64; inline;
function simd_reduce_min_i64x4(const a: TSimdI64x4): Int64; inline;

// 无符号整数最小值
function simd_reduce_min_u8x16(const a: TSimdU8x16): Byte; inline;
function simd_reduce_min_u8x32(const a: TSimdU8x32): Byte; inline;
function simd_reduce_min_u16x8(const a: TSimdU16x8): UInt16; inline;
function simd_reduce_min_u16x16(const a: TSimdU16x16): UInt16; inline;
function simd_reduce_min_u32x4(const a: TSimdU32x4): UInt32; inline;
function simd_reduce_min_u32x8(const a: TSimdU32x8): UInt32; inline;
function simd_reduce_min_u64x2(const a: TSimdU64x2): UInt64; inline;
function simd_reduce_min_u64x4(const a: TSimdU64x4): UInt64; inline;

// === 4. 最大值（Reduce Max）===

// 浮点最大值
function simd_reduce_max_f32x4(const a: TSimdF32x4): Single; inline;
function simd_reduce_max_f32x8(const a: TSimdF32x8): Single; inline;
function simd_reduce_max_f32x16(const a: TSimdF32x16): Single; inline;
function simd_reduce_max_f64x2(const a: TSimdF64x2): Double; inline;
function simd_reduce_max_f64x4(const a: TSimdF64x4): Double; inline;
function simd_reduce_max_f64x8(const a: TSimdF64x8): Double; inline;

// 有符号整数最大值
function simd_reduce_max_i8x16(const a: TSimdI8x16): Int8; inline;
function simd_reduce_max_i8x32(const a: TSimdI8x32): Int8; inline;
function simd_reduce_max_i16x8(const a: TSimdI16x8): Int16; inline;
function simd_reduce_max_i16x16(const a: TSimdI16x16): Int16; inline;
function simd_reduce_max_i32x4(const a: TSimdI32x4): Int32; inline;
function simd_reduce_max_i32x8(const a: TSimdI32x8): Int32; inline;
function simd_reduce_max_i64x2(const a: TSimdI64x2): Int64; inline;
function simd_reduce_max_i64x4(const a: TSimdI64x4): Int64; inline;

// 无符号整数最大值
function simd_reduce_max_u8x16(const a: TSimdU8x16): Byte; inline;
function simd_reduce_max_u8x32(const a: TSimdU8x32): Byte; inline;
function simd_reduce_max_u16x8(const a: TSimdU16x8): UInt16; inline;
function simd_reduce_max_u16x16(const a: TSimdU16x16): UInt16; inline;
function simd_reduce_max_u32x4(const a: TSimdU32x4): UInt32; inline;
function simd_reduce_max_u32x8(const a: TSimdU32x8): UInt32; inline;
function simd_reduce_max_u64x2(const a: TSimdU64x2): UInt64; inline;
function simd_reduce_max_u64x4(const a: TSimdU64x4): UInt64; inline;

// === 5. 逻辑运算（Reduce Logic）===

// 逻辑与
function simd_reduce_and_mask4(const a: TSimdMask4): Boolean; inline;
function simd_reduce_and_mask8(const a: TSimdMask8): Boolean; inline;
function simd_reduce_and_mask16(const a: TSimdMask16): Boolean; inline;
function simd_reduce_and_mask32(const a: TSimdMask32): Boolean; inline;

// 逻辑或
function simd_reduce_or_mask4(const a: TSimdMask4): Boolean; inline;
function simd_reduce_or_mask8(const a: TSimdMask8): Boolean; inline;
function simd_reduce_or_mask16(const a: TSimdMask16): Boolean; inline;
function simd_reduce_or_mask32(const a: TSimdMask32): Boolean; inline;

// 异或
function simd_reduce_xor_mask4(const a: TSimdMask4): Boolean; inline;
function simd_reduce_xor_mask8(const a: TSimdMask8): Boolean; inline;
function simd_reduce_xor_mask16(const a: TSimdMask16): Boolean; inline;
function simd_reduce_xor_mask32(const a: TSimdMask32): Boolean; inline;

implementation

uses
  fafafa.core.simd.scalar;

// === 求和实现 ===

function simd_reduce_add_f32x4(const a: TSimdF32x4): Single;
begin
  Result := simd_reduce_add_f32x4_scalar(a);
end;

function simd_reduce_add_f32x8(const a: TSimdF32x8): Single;
begin
  Result := simd_reduce_add_f32x8_scalar(a);
end;

function simd_reduce_add_f32x16(const a: TSimdF32x16): Single;
var i: Integer;
begin
  Result := 0.0;
  for i := 0 to 15 do
    Result := Result + a[i];
end;

function simd_reduce_add_f64x2(const a: TSimdF64x2): Double;
begin
  Result := simd_reduce_add_f64x2_scalar(a);
end;

function simd_reduce_add_f64x4(const a: TSimdF64x4): Double;
var i: Integer;
begin
  Result := 0.0;
  for i := 0 to 3 do
    Result := Result + a[i];
end;

function simd_reduce_add_f64x8(const a: TSimdF64x8): Double;
var i: Integer;
begin
  Result := 0.0;
  for i := 0 to 7 do
    Result := Result + a[i];
end;

// 整数求和
function simd_reduce_add_i8x16(const a: TSimdI8x16): Int32;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    Result := Result + a[i];
end;

function simd_reduce_add_i8x32(const a: TSimdI8x32): Int32;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 31 do
    Result := Result + a[i];
end;

function simd_reduce_add_i16x8(const a: TSimdI16x8): Int32;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    Result := Result + a[i];
end;

function simd_reduce_add_i16x16(const a: TSimdI16x16): Int32;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    Result := Result + a[i];
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

function simd_reduce_add_i64x2(const a: TSimdI64x2): Int64;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    Result := Result + a[i];
end;

function simd_reduce_add_i64x4(const a: TSimdI64x4): Int64;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    Result := Result + a[i];
end;

// 无符号整数求和
function simd_reduce_add_u8x16(const a: TSimdU8x16): UInt32;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    Result := Result + a[i];
end;

function simd_reduce_add_u8x32(const a: TSimdU8x32): UInt32;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 31 do
    Result := Result + a[i];
end;

function simd_reduce_add_u16x8(const a: TSimdU16x8): UInt32;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    Result := Result + a[i];
end;

function simd_reduce_add_u16x16(const a: TSimdU16x16): UInt32;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
    Result := Result + a[i];
end;

function simd_reduce_add_u32x4(const a: TSimdU32x4): UInt32;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    Result := Result + a[i];
end;

function simd_reduce_add_u32x8(const a: TSimdU32x8): UInt32;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 7 do
    Result := Result + a[i];
end;

function simd_reduce_add_u64x2(const a: TSimdU64x2): UInt64;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 1 do
    Result := Result + a[i];
end;

function simd_reduce_add_u64x4(const a: TSimdU64x4): UInt64;
var i: Integer;
begin
  Result := 0;
  for i := 0 to 3 do
    Result := Result + a[i];
end;

// === 求积实现 ===

function simd_reduce_mul_f32x4(const a: TSimdF32x4): Single;
begin
  Result := simd_reduce_mul_f32x4_scalar(a);
end;

function simd_reduce_mul_f32x8(const a: TSimdF32x8): Single;
var i: Integer;
begin
  Result := 1.0;
  for i := 0 to 7 do
    Result := Result * a[i];
end;

function simd_reduce_mul_f64x2(const a: TSimdF64x2): Double;
begin
  Result := simd_reduce_mul_f64x2_scalar(a);
end;

function simd_reduce_mul_f64x4(const a: TSimdF64x4): Double;
var i: Integer;
begin
  Result := 1.0;
  for i := 0 to 3 do
    Result := Result * a[i];
end;

// 整数求积
function simd_reduce_mul_i16x8(const a: TSimdI16x8): Int32;
var i: Integer;
begin
  Result := 1;
  for i := 0 to 7 do
    Result := Result * a[i];
end;

function simd_reduce_mul_i32x4(const a: TSimdI32x4): Int32;
begin
  Result := simd_reduce_mul_i32x4_scalar(a);
end;

function simd_reduce_mul_i32x8(const a: TSimdI32x8): Int32;
var i: Integer;
begin
  Result := 1;
  for i := 0 to 7 do
    Result := Result * a[i];
end;

function simd_reduce_mul_i64x2(const a: TSimdI64x2): Int64;
var i: Integer;
begin
  Result := 1;
  for i := 0 to 1 do
    Result := Result * a[i];
end;

// 无符号整数求积
function simd_reduce_mul_u16x8(const a: TSimdU16x8): UInt32;
var i: Integer;
begin
  Result := 1;
  for i := 0 to 7 do
    Result := Result * a[i];
end;

function simd_reduce_mul_u32x4(const a: TSimdU32x4): UInt32;
var i: Integer;
begin
  Result := 1;
  for i := 0 to 3 do
    Result := Result * a[i];
end;

function simd_reduce_mul_u32x8(const a: TSimdU32x8): UInt32;
var i: Integer;
begin
  Result := 1;
  for i := 0 to 7 do
    Result := Result * a[i];
end;

function simd_reduce_mul_u64x2(const a: TSimdU64x2): UInt64;
var i: Integer;
begin
  Result := 1;
  for i := 0 to 1 do
    Result := Result * a[i];
end;

// === 最小值实现 ===

function simd_reduce_min_f32x4(const a: TSimdF32x4): Single;
begin
  Result := simd_reduce_min_f32x4_scalar(a);
end;

function simd_reduce_min_f32x8(const a: TSimdF32x8): Single;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 7 do
    if a[i] < Result then Result := a[i];
end;

function simd_reduce_min_f32x16(const a: TSimdF32x16): Single;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 15 do
    if a[i] < Result then Result := a[i];
end;

function simd_reduce_min_f64x2(const a: TSimdF64x2): Double;
begin
  Result := simd_reduce_min_f64x2_scalar(a);
end;

function simd_reduce_min_f64x4(const a: TSimdF64x4): Double;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 3 do
    if a[i] < Result then Result := a[i];
end;

function simd_reduce_min_f64x8(const a: TSimdF64x8): Double;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 7 do
    if a[i] < Result then Result := a[i];
end;

// 有符号整数最小值
function simd_reduce_min_i8x16(const a: TSimdI8x16): Int8;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 15 do
    if a[i] < Result then Result := a[i];
end;

function simd_reduce_min_i8x32(const a: TSimdI8x32): Int8;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 31 do
    if a[i] < Result then Result := a[i];
end;

function simd_reduce_min_i16x8(const a: TSimdI16x8): Int16;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 7 do
    if a[i] < Result then Result := a[i];
end;

function simd_reduce_min_i16x16(const a: TSimdI16x16): Int16;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 15 do
    if a[i] < Result then Result := a[i];
end;

function simd_reduce_min_i32x4(const a: TSimdI32x4): Int32;
begin
  Result := simd_reduce_min_i32x4_scalar(a);
end;

function simd_reduce_min_i32x8(const a: TSimdI32x8): Int32;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 7 do
    if a[i] < Result then Result := a[i];
end;

function simd_reduce_min_i64x2(const a: TSimdI64x2): Int64;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 1 do
    if a[i] < Result then Result := a[i];
end;

function simd_reduce_min_i64x4(const a: TSimdI64x4): Int64;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 3 do
    if a[i] < Result then Result := a[i];
end;

// 无符号整数最小值
function simd_reduce_min_u8x16(const a: TSimdU8x16): Byte;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 15 do
    if a[i] < Result then Result := a[i];
end;

function simd_reduce_min_u8x32(const a: TSimdU8x32): Byte;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 31 do
    if a[i] < Result then Result := a[i];
end;

function simd_reduce_min_u16x8(const a: TSimdU16x8): UInt16;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 7 do
    if a[i] < Result then Result := a[i];
end;

function simd_reduce_min_u16x16(const a: TSimdU16x16): UInt16;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 15 do
    if a[i] < Result then Result := a[i];
end;

function simd_reduce_min_u32x4(const a: TSimdU32x4): UInt32;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 3 do
    if a[i] < Result then Result := a[i];
end;

function simd_reduce_min_u32x8(const a: TSimdU32x8): UInt32;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 7 do
    if a[i] < Result then Result := a[i];
end;

function simd_reduce_min_u64x2(const a: TSimdU64x2): UInt64;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 1 do
    if a[i] < Result then Result := a[i];
end;

function simd_reduce_min_u64x4(const a: TSimdU64x4): UInt64;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 3 do
    if a[i] < Result then Result := a[i];
end;

// === 最大值实现 ===

function simd_reduce_max_f32x4(const a: TSimdF32x4): Single;
begin
  Result := simd_reduce_max_f32x4_scalar(a);
end;

function simd_reduce_max_f32x8(const a: TSimdF32x8): Single;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 7 do
    if a[i] > Result then Result := a[i];
end;

function simd_reduce_max_f32x16(const a: TSimdF32x16): Single;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 15 do
    if a[i] > Result then Result := a[i];
end;

function simd_reduce_max_f64x2(const a: TSimdF64x2): Double;
begin
  Result := simd_reduce_max_f64x2_scalar(a);
end;

function simd_reduce_max_f64x4(const a: TSimdF64x4): Double;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 3 do
    if a[i] > Result then Result := a[i];
end;

function simd_reduce_max_f64x8(const a: TSimdF64x8): Double;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 7 do
    if a[i] > Result then Result := a[i];
end;

// 有符号整数最大值
function simd_reduce_max_i8x16(const a: TSimdI8x16): Int8;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 15 do
    if a[i] > Result then Result := a[i];
end;

function simd_reduce_max_i8x32(const a: TSimdI8x32): Int8;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 31 do
    if a[i] > Result then Result := a[i];
end;

function simd_reduce_max_i16x8(const a: TSimdI16x8): Int16;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 7 do
    if a[i] > Result then Result := a[i];
end;

function simd_reduce_max_i16x16(const a: TSimdI16x16): Int16;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 15 do
    if a[i] > Result then Result := a[i];
end;

function simd_reduce_max_i32x4(const a: TSimdI32x4): Int32;
begin
  Result := simd_reduce_max_i32x4_scalar(a);
end;

function simd_reduce_max_i32x8(const a: TSimdI32x8): Int32;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 7 do
    if a[i] > Result then Result := a[i];
end;

function simd_reduce_max_i64x2(const a: TSimdI64x2): Int64;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 1 do
    if a[i] > Result then Result := a[i];
end;

function simd_reduce_max_i64x4(const a: TSimdI64x4): Int64;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 3 do
    if a[i] > Result then Result := a[i];
end;

// 无符号整数最大值
function simd_reduce_max_u8x16(const a: TSimdU8x16): Byte;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 15 do
    if a[i] > Result then Result := a[i];
end;

function simd_reduce_max_u8x32(const a: TSimdU8x32): Byte;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 31 do
    if a[i] > Result then Result := a[i];
end;

function simd_reduce_max_u16x8(const a: TSimdU16x8): UInt16;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 7 do
    if a[i] > Result then Result := a[i];
end;

function simd_reduce_max_u16x16(const a: TSimdU16x16): UInt16;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 15 do
    if a[i] > Result then Result := a[i];
end;

function simd_reduce_max_u32x4(const a: TSimdU32x4): UInt32;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 3 do
    if a[i] > Result then Result := a[i];
end;

function simd_reduce_max_u32x8(const a: TSimdU32x8): UInt32;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 7 do
    if a[i] > Result then Result := a[i];
end;

function simd_reduce_max_u64x2(const a: TSimdU64x2): UInt64;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 1 do
    if a[i] > Result then Result := a[i];
end;

function simd_reduce_max_u64x4(const a: TSimdU64x4): UInt64;
var i: Integer;
begin
  Result := a[0];
  for i := 1 to 3 do
    if a[i] > Result then Result := a[i];
end;

// === 逻辑运算实现 ===

// 逻辑与
function simd_reduce_and_mask4(const a: TSimdMask4): Boolean;
var i: Integer;
begin
  Result := True;
  for i := 0 to 3 do
    Result := Result and a[i];
end;

function simd_reduce_and_mask8(const a: TSimdMask8): Boolean;
var i: Integer;
begin
  Result := True;
  for i := 0 to 7 do
    Result := Result and a[i];
end;

function simd_reduce_and_mask16(const a: TSimdMask16): Boolean;
var i: Integer;
begin
  Result := True;
  for i := 0 to 15 do
    Result := Result and a[i];
end;

function simd_reduce_and_mask32(const a: TSimdMask32): Boolean;
var i: Integer;
begin
  Result := True;
  for i := 0 to 31 do
    Result := Result and a[i];
end;

// 逻辑或
function simd_reduce_or_mask4(const a: TSimdMask4): Boolean;
var i: Integer;
begin
  Result := False;
  for i := 0 to 3 do
    Result := Result or a[i];
end;

function simd_reduce_or_mask8(const a: TSimdMask8): Boolean;
var i: Integer;
begin
  Result := False;
  for i := 0 to 7 do
    Result := Result or a[i];
end;

function simd_reduce_or_mask16(const a: TSimdMask16): Boolean;
var i: Integer;
begin
  Result := False;
  for i := 0 to 15 do
    Result := Result or a[i];
end;

function simd_reduce_or_mask32(const a: TSimdMask32): Boolean;
var i: Integer;
begin
  Result := False;
  for i := 0 to 31 do
    Result := Result or a[i];
end;

// 异或
function simd_reduce_xor_mask4(const a: TSimdMask4): Boolean;
var i: Integer;
begin
  Result := False;
  for i := 0 to 3 do
    Result := Result xor a[i];
end;

function simd_reduce_xor_mask8(const a: TSimdMask8): Boolean;
var i: Integer;
begin
  Result := False;
  for i := 0 to 7 do
    Result := Result xor a[i];
end;

function simd_reduce_xor_mask16(const a: TSimdMask16): Boolean;
var i: Integer;
begin
  Result := False;
  for i := 0 to 15 do
    Result := Result xor a[i];
end;

function simd_reduce_xor_mask32(const a: TSimdMask32): Boolean;
var i: Integer;
begin
  Result := False;
  for i := 0 to 31 do
    Result := Result xor a[i];
end;

end.
