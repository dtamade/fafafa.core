unit fafafa.core.simd.arithmetic;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.types;

// === 向量算术运算（对标 Rust std::simd）===
// 统一使用 simd_ 前缀，遵循 Rust 命名规范

// === 1. 加法运算 ===

// 32位浮点加法
function simd_add_f32x4(const a, b: TSimdF32x4): TSimdF32x4; inline;
function simd_add_f32x8(const a, b: TSimdF32x8): TSimdF32x8; inline;
function simd_add_f32x16(const a, b: TSimdF32x16): TSimdF32x16; inline;

// 64位浮点加法
function simd_add_f64x2(const a, b: TSimdF64x2): TSimdF64x2; inline;
function simd_add_f64x4(const a, b: TSimdF64x4): TSimdF64x4; inline;
function simd_add_f64x8(const a, b: TSimdF64x8): TSimdF64x8; inline;

// 8位整数加法
function simd_add_i8x16(const a, b: TSimdI8x16): TSimdI8x16; inline;
function simd_add_i8x32(const a, b: TSimdI8x32): TSimdI8x32; inline;
function simd_add_i8x64(const a, b: TSimdI8x64): TSimdI8x64; inline;

// 16位整数加法
function simd_add_i16x8(const a, b: TSimdI16x8): TSimdI16x8; inline;
function simd_add_i16x16(const a, b: TSimdI16x16): TSimdI16x16; inline;
function simd_add_i16x32(const a, b: TSimdI16x32): TSimdI16x32; inline;

// 32位整数加法
function simd_add_i32x4(const a, b: TSimdI32x4): TSimdI32x4; inline;
function simd_add_i32x8(const a, b: TSimdI32x8): TSimdI32x8; inline;
function simd_add_i32x16(const a, b: TSimdI32x16): TSimdI32x16; inline;

// 64位整数加法
function simd_add_i64x2(const a, b: TSimdI64x2): TSimdI64x2; inline;
function simd_add_i64x4(const a, b: TSimdI64x4): TSimdI64x4; inline;
function simd_add_i64x8(const a, b: TSimdI64x8): TSimdI64x8; inline;

// 无符号整数加法
function simd_add_u8x16(const a, b: TSimdU8x16): TSimdU8x16; inline;
function simd_add_u8x32(const a, b: TSimdU8x32): TSimdU8x32; inline;
function simd_add_u8x64(const a, b: TSimdU8x64): TSimdU8x64; inline;

function simd_add_u16x8(const a, b: TSimdU16x8): TSimdU16x8; inline;
function simd_add_u16x16(const a, b: TSimdU16x16): TSimdU16x16; inline;
function simd_add_u16x32(const a, b: TSimdU16x32): TSimdU16x32; inline;

function simd_add_u32x4(const a, b: TSimdU32x4): TSimdU32x4; inline;
function simd_add_u32x8(const a, b: TSimdU32x8): TSimdU32x8; inline;
function simd_add_u32x16(const a, b: TSimdU32x16): TSimdU32x16; inline;

function simd_add_u64x2(const a, b: TSimdU64x2): TSimdU64x2; inline;
function simd_add_u64x4(const a, b: TSimdU64x4): TSimdU64x4; inline;
function simd_add_u64x8(const a, b: TSimdU64x8): TSimdU64x8; inline;

// === 2. 减法运算 ===

// 32位浮点减法
function simd_sub_f32x4(const a, b: TSimdF32x4): TSimdF32x4; inline;
function simd_sub_f32x8(const a, b: TSimdF32x8): TSimdF32x8; inline;
function simd_sub_f32x16(const a, b: TSimdF32x16): TSimdF32x16; inline;

// 64位浮点减法
function simd_sub_f64x2(const a, b: TSimdF64x2): TSimdF64x2; inline;
function simd_sub_f64x4(const a, b: TSimdF64x4): TSimdF64x4; inline;
function simd_sub_f64x8(const a, b: TSimdF64x8): TSimdF64x8; inline;

// 整数减法
function simd_sub_i8x16(const a, b: TSimdI8x16): TSimdI8x16; inline;
function simd_sub_i8x32(const a, b: TSimdI8x32): TSimdI8x32; inline;
function simd_sub_i16x8(const a, b: TSimdI16x8): TSimdI16x8; inline;
function simd_sub_i16x16(const a, b: TSimdI16x16): TSimdI16x16; inline;
function simd_sub_i32x4(const a, b: TSimdI32x4): TSimdI32x4; inline;
function simd_sub_i32x8(const a, b: TSimdI32x8): TSimdI32x8; inline;
function simd_sub_i64x2(const a, b: TSimdI64x2): TSimdI64x2; inline;
function simd_sub_i64x4(const a, b: TSimdI64x4): TSimdI64x4; inline;

// 无符号整数减法
function simd_sub_u8x16(const a, b: TSimdU8x16): TSimdU8x16; inline;
function simd_sub_u8x32(const a, b: TSimdU8x32): TSimdU8x32; inline;
function simd_sub_u16x8(const a, b: TSimdU16x8): TSimdU16x8; inline;
function simd_sub_u16x16(const a, b: TSimdU16x16): TSimdU16x16; inline;
function simd_sub_u32x4(const a, b: TSimdU32x4): TSimdU32x4; inline;
function simd_sub_u32x8(const a, b: TSimdU32x8): TSimdU32x8; inline;
function simd_sub_u64x2(const a, b: TSimdU64x2): TSimdU64x2; inline;
function simd_sub_u64x4(const a, b: TSimdU64x4): TSimdU64x4; inline;

// === 3. 乘法运算 ===

// 32位浮点乘法
function simd_mul_f32x4(const a, b: TSimdF32x4): TSimdF32x4; inline;
function simd_mul_f32x8(const a, b: TSimdF32x8): TSimdF32x8; inline;
function simd_mul_f32x16(const a, b: TSimdF32x16): TSimdF32x16; inline;

// 64位浮点乘法
function simd_mul_f64x2(const a, b: TSimdF64x2): TSimdF64x2; inline;
function simd_mul_f64x4(const a, b: TSimdF64x4): TSimdF64x4; inline;
function simd_mul_f64x8(const a, b: TSimdF64x8): TSimdF64x8; inline;

// 整数乘法
function simd_mul_i16x8(const a, b: TSimdI16x8): TSimdI16x8; inline;
function simd_mul_i16x16(const a, b: TSimdI16x16): TSimdI16x16; inline;
function simd_mul_i32x4(const a, b: TSimdI32x4): TSimdI32x4; inline;
function simd_mul_i32x8(const a, b: TSimdI32x8): TSimdI32x8; inline;
function simd_mul_i64x2(const a, b: TSimdI64x2): TSimdI64x2; inline;
function simd_mul_i64x4(const a, b: TSimdI64x4): TSimdI64x4; inline;

// 无符号整数乘法
function simd_mul_u16x8(const a, b: TSimdU16x8): TSimdU16x8; inline;
function simd_mul_u16x16(const a, b: TSimdU16x16): TSimdU16x16; inline;
function simd_mul_u32x4(const a, b: TSimdU32x4): TSimdU32x4; inline;
function simd_mul_u32x8(const a, b: TSimdU32x8): TSimdU32x8; inline;
function simd_mul_u64x2(const a, b: TSimdU64x2): TSimdU64x2; inline;
function simd_mul_u64x4(const a, b: TSimdU64x4): TSimdU64x4; inline;

// === 4. 除法运算（仅浮点）===

function simd_div_f32x4(const a, b: TSimdF32x4): TSimdF32x4; inline;
function simd_div_f32x8(const a, b: TSimdF32x8): TSimdF32x8; inline;
function simd_div_f32x16(const a, b: TSimdF32x16): TSimdF32x16; inline;

function simd_div_f64x2(const a, b: TSimdF64x2): TSimdF64x2; inline;
function simd_div_f64x4(const a, b: TSimdF64x4): TSimdF64x4; inline;
function simd_div_f64x8(const a, b: TSimdF64x8): TSimdF64x8; inline;

implementation

uses
  fafafa.core.simd.scalar;

// === 加法运算实现 ===

function simd_add_f32x4(const a, b: TSimdF32x4): TSimdF32x4;
begin
  Result := simd_add_f32x4_scalar(a, b);
end;

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

function simd_add_f64x8(const a, b: TSimdF64x8): TSimdF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] + b[i];
end;

// 8位整数加法
function simd_add_i8x16(const a, b: TSimdI8x16): TSimdI8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] + b[i];
end;

function simd_add_i8x32(const a, b: TSimdI8x32): TSimdI8x32;
var i: Integer;
begin
  for i := 0 to 31 do
    Result[i] := a[i] + b[i];
end;

function simd_add_i8x64(const a, b: TSimdI8x64): TSimdI8x64;
var i: Integer;
begin
  for i := 0 to 63 do
    Result[i] := a[i] + b[i];
end;

// 16位整数加法
function simd_add_i16x8(const a, b: TSimdI16x8): TSimdI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] + b[i];
end;

function simd_add_i16x16(const a, b: TSimdI16x16): TSimdI16x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] + b[i];
end;

function simd_add_i16x32(const a, b: TSimdI16x32): TSimdI16x32;
var i: Integer;
begin
  for i := 0 to 31 do
    Result[i] := a[i] + b[i];
end;

// 32位整数加法
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

// 64位整数加法
function simd_add_i64x2(const a, b: TSimdI64x2): TSimdI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] + b[i];
end;

function simd_add_i64x4(const a, b: TSimdI64x4): TSimdI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] + b[i];
end;

function simd_add_i64x8(const a, b: TSimdI64x8): TSimdI64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] + b[i];
end;

// 无符号整数加法
function simd_add_u8x16(const a, b: TSimdU8x16): TSimdU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] + b[i];
end;

function simd_add_u8x32(const a, b: TSimdU8x32): TSimdU8x32;
var i: Integer;
begin
  for i := 0 to 31 do
    Result[i] := a[i] + b[i];
end;

function simd_add_u8x64(const a, b: TSimdU8x64): TSimdU8x64;
var i: Integer;
begin
  for i := 0 to 63 do
    Result[i] := a[i] + b[i];
end;

function simd_add_u16x8(const a, b: TSimdU16x8): TSimdU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] + b[i];
end;

function simd_add_u16x16(const a, b: TSimdU16x16): TSimdU16x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] + b[i];
end;

function simd_add_u16x32(const a, b: TSimdU16x32): TSimdU16x32;
var i: Integer;
begin
  for i := 0 to 31 do
    Result[i] := a[i] + b[i];
end;

function simd_add_u32x4(const a, b: TSimdU32x4): TSimdU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] + b[i];
end;

function simd_add_u32x8(const a, b: TSimdU32x8): TSimdU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] + b[i];
end;

function simd_add_u32x16(const a, b: TSimdU32x16): TSimdU32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] + b[i];
end;

function simd_add_u64x2(const a, b: TSimdU64x2): TSimdU64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] + b[i];
end;

function simd_add_u64x4(const a, b: TSimdU64x4): TSimdU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] + b[i];
end;

function simd_add_u64x8(const a, b: TSimdU64x8): TSimdU64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] + b[i];
end;

// === 减法运算实现 ===

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

function simd_sub_f64x8(const a, b: TSimdF64x8): TSimdF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] - b[i];
end;

// 整数减法
function simd_sub_i8x16(const a, b: TSimdI8x16): TSimdI8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] - b[i];
end;

function simd_sub_i8x32(const a, b: TSimdI8x32): TSimdI8x32;
var i: Integer;
begin
  for i := 0 to 31 do
    Result[i] := a[i] - b[i];
end;

function simd_sub_i16x8(const a, b: TSimdI16x8): TSimdI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] - b[i];
end;

function simd_sub_i16x16(const a, b: TSimdI16x16): TSimdI16x16;
var i: Integer;
begin
  for i := 0 to 15 do
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

function simd_sub_i64x2(const a, b: TSimdI64x2): TSimdI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] - b[i];
end;

function simd_sub_i64x4(const a, b: TSimdI64x4): TSimdI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] - b[i];
end;

// 无符号整数减法
function simd_sub_u8x16(const a, b: TSimdU8x16): TSimdU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] - b[i];
end;

function simd_sub_u8x32(const a, b: TSimdU8x32): TSimdU8x32;
var i: Integer;
begin
  for i := 0 to 31 do
    Result[i] := a[i] - b[i];
end;

function simd_sub_u16x8(const a, b: TSimdU16x8): TSimdU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] - b[i];
end;

function simd_sub_u16x16(const a, b: TSimdU16x16): TSimdU16x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] - b[i];
end;

function simd_sub_u32x4(const a, b: TSimdU32x4): TSimdU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] - b[i];
end;

function simd_sub_u32x8(const a, b: TSimdU32x8): TSimdU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] - b[i];
end;

function simd_sub_u64x2(const a, b: TSimdU64x2): TSimdU64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] - b[i];
end;

function simd_sub_u64x4(const a, b: TSimdU64x4): TSimdU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] - b[i];
end;

// === 乘法运算实现 ===

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

function simd_mul_f64x8(const a, b: TSimdF64x8): TSimdF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] * b[i];
end;

// 整数乘法
function simd_mul_i16x8(const a, b: TSimdI16x8): TSimdI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] * b[i];
end;

function simd_mul_i16x16(const a, b: TSimdI16x16): TSimdI16x16;
var i: Integer;
begin
  for i := 0 to 15 do
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

function simd_mul_i64x2(const a, b: TSimdI64x2): TSimdI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] * b[i];
end;

function simd_mul_i64x4(const a, b: TSimdI64x4): TSimdI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] * b[i];
end;

// 无符号整数乘法
function simd_mul_u16x8(const a, b: TSimdU16x8): TSimdU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] * b[i];
end;

function simd_mul_u16x16(const a, b: TSimdU16x16): TSimdU16x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] * b[i];
end;

function simd_mul_u32x4(const a, b: TSimdU32x4): TSimdU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] * b[i];
end;

function simd_mul_u32x8(const a, b: TSimdU32x8): TSimdU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] * b[i];
end;

function simd_mul_u64x2(const a, b: TSimdU64x2): TSimdU64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] * b[i];
end;

function simd_mul_u64x4(const a, b: TSimdU64x4): TSimdU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] * b[i];
end;

// === 除法运算实现（仅浮点）===

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

function simd_div_f64x8(const a, b: TSimdF64x8): TSimdF64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] / b[i];
end;

end.
