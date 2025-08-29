unit fafafa.core.simd.compare;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.types;

// === 比较运算（对标 Rust std::simd）===
// 统一使用 simd_ 前缀，遵循 Rust 命名规范

// === 1. 相等比较 ===

// 32位浮点相等比较
function simd_eq_f32x4(const a, b: TSimdF32x4): TSimdMask4; inline;
function simd_eq_f32x8(const a, b: TSimdF32x8): TSimdMask8; inline;
function simd_eq_f32x16(const a, b: TSimdF32x16): TSimdMask16; inline;

// 64位浮点相等比较
function simd_eq_f64x2(const a, b: TSimdF64x2): TSimdMask2; inline;
function simd_eq_f64x4(const a, b: TSimdF64x4): TSimdMask4; inline;
function simd_eq_f64x8(const a, b: TSimdF64x8): TSimdMask8; inline;

// 整数相等比较
function simd_eq_i8x16(const a, b: TSimdI8x16): TSimdMask16; inline;
function simd_eq_i8x32(const a, b: TSimdI8x32): TSimdMask32; inline;
function simd_eq_i16x8(const a, b: TSimdI16x8): TSimdMask8; inline;
function simd_eq_i16x16(const a, b: TSimdI16x16): TSimdMask16; inline;
function simd_eq_i32x4(const a, b: TSimdI32x4): TSimdMask4; inline;
function simd_eq_i32x8(const a, b: TSimdI32x8): TSimdMask8; inline;
function simd_eq_i64x2(const a, b: TSimdI64x2): TSimdMask2; inline;
function simd_eq_i64x4(const a, b: TSimdI64x4): TSimdMask4; inline;

// 无符号整数相等比较
function simd_eq_u8x16(const a, b: TSimdU8x16): TSimdMask16; inline;
function simd_eq_u8x32(const a, b: TSimdU8x32): TSimdMask32; inline;
function simd_eq_u16x8(const a, b: TSimdU16x8): TSimdMask8; inline;
function simd_eq_u16x16(const a, b: TSimdU16x16): TSimdMask16; inline;
function simd_eq_u32x4(const a, b: TSimdU32x4): TSimdMask4; inline;
function simd_eq_u32x8(const a, b: TSimdU32x8): TSimdMask8; inline;
function simd_eq_u64x2(const a, b: TSimdU64x2): TSimdMask2; inline;
function simd_eq_u64x4(const a, b: TSimdU64x4): TSimdMask4; inline;

// === 2. 不等比较 ===

// 32位浮点不等比较
function simd_ne_f32x4(const a, b: TSimdF32x4): TSimdMask4; inline;
function simd_ne_f32x8(const a, b: TSimdF32x8): TSimdMask8; inline;
function simd_ne_f64x2(const a, b: TSimdF64x2): TSimdMask2; inline;
function simd_ne_f64x4(const a, b: TSimdF64x4): TSimdMask4; inline;

// 整数不等比较
function simd_ne_i8x16(const a, b: TSimdI8x16): TSimdMask16; inline;
function simd_ne_i16x8(const a, b: TSimdI16x8): TSimdMask8; inline;
function simd_ne_i32x4(const a, b: TSimdI32x4): TSimdMask4; inline;
function simd_ne_i32x8(const a, b: TSimdI32x8): TSimdMask8; inline;
function simd_ne_i64x2(const a, b: TSimdI64x2): TSimdMask2; inline;

// 无符号整数不等比较
function simd_ne_u8x16(const a, b: TSimdU8x16): TSimdMask16; inline;
function simd_ne_u16x8(const a, b: TSimdU16x8): TSimdMask8; inline;
function simd_ne_u32x4(const a, b: TSimdU32x4): TSimdMask4; inline;
function simd_ne_u64x2(const a, b: TSimdU64x2): TSimdMask2; inline;

// === 3. 小于比较 ===

// 32位浮点小于比较
function simd_lt_f32x4(const a, b: TSimdF32x4): TSimdMask4; inline;
function simd_lt_f32x8(const a, b: TSimdF32x8): TSimdMask8; inline;
function simd_lt_f64x2(const a, b: TSimdF64x2): TSimdMask2; inline;
function simd_lt_f64x4(const a, b: TSimdF64x4): TSimdMask4; inline;

// 有符号整数小于比较
function simd_lt_i8x16(const a, b: TSimdI8x16): TSimdMask16; inline;
function simd_lt_i16x8(const a, b: TSimdI16x8): TSimdMask8; inline;
function simd_lt_i32x4(const a, b: TSimdI32x4): TSimdMask4; inline;
function simd_lt_i32x8(const a, b: TSimdI32x8): TSimdMask8; inline;
function simd_lt_i64x2(const a, b: TSimdI64x2): TSimdMask2; inline;

// 无符号整数小于比较
function simd_lt_u8x16(const a, b: TSimdU8x16): TSimdMask16; inline;
function simd_lt_u16x8(const a, b: TSimdU16x8): TSimdMask8; inline;
function simd_lt_u32x4(const a, b: TSimdU32x4): TSimdMask4; inline;
function simd_lt_u64x2(const a, b: TSimdU64x2): TSimdMask2; inline;

// === 4. 小于等于比较 ===

function simd_le_f32x4(const a, b: TSimdF32x4): TSimdMask4; inline;
function simd_le_f32x8(const a, b: TSimdF32x8): TSimdMask8; inline;
function simd_le_f64x2(const a, b: TSimdF64x2): TSimdMask2; inline;
function simd_le_f64x4(const a, b: TSimdF64x4): TSimdMask4; inline;

function simd_le_i8x16(const a, b: TSimdI8x16): TSimdMask16; inline;
function simd_le_i16x8(const a, b: TSimdI16x8): TSimdMask8; inline;
function simd_le_i32x4(const a, b: TSimdI32x4): TSimdMask4; inline;
function simd_le_i64x2(const a, b: TSimdI64x2): TSimdMask2; inline;

function simd_le_u8x16(const a, b: TSimdU8x16): TSimdMask16; inline;
function simd_le_u16x8(const a, b: TSimdU16x8): TSimdMask8; inline;
function simd_le_u32x4(const a, b: TSimdU32x4): TSimdMask4; inline;
function simd_le_u64x2(const a, b: TSimdU64x2): TSimdMask2; inline;

// === 5. 大于比较 ===

function simd_gt_f32x4(const a, b: TSimdF32x4): TSimdMask4; inline;
function simd_gt_f32x8(const a, b: TSimdF32x8): TSimdMask8; inline;
function simd_gt_f64x2(const a, b: TSimdF64x2): TSimdMask2; inline;
function simd_gt_f64x4(const a, b: TSimdF64x4): TSimdMask4; inline;

function simd_gt_i8x16(const a, b: TSimdI8x16): TSimdMask16; inline;
function simd_gt_i16x8(const a, b: TSimdI16x8): TSimdMask8; inline;
function simd_gt_i32x4(const a, b: TSimdI32x4): TSimdMask4; inline;
function simd_gt_i64x2(const a, b: TSimdI64x2): TSimdMask2; inline;

function simd_gt_u8x16(const a, b: TSimdU8x16): TSimdMask16; inline;
function simd_gt_u16x8(const a, b: TSimdU16x8): TSimdMask8; inline;
function simd_gt_u32x4(const a, b: TSimdU32x4): TSimdMask4; inline;
function simd_gt_u64x2(const a, b: TSimdU64x2): TSimdMask2; inline;

// === 6. 大于等于比较 ===

function simd_ge_f32x4(const a, b: TSimdF32x4): TSimdMask4; inline;
function simd_ge_f32x8(const a, b: TSimdF32x8): TSimdMask8; inline;
function simd_ge_f64x2(const a, b: TSimdF64x2): TSimdMask2; inline;
function simd_ge_f64x4(const a, b: TSimdF64x4): TSimdMask4; inline;

function simd_ge_i8x16(const a, b: TSimdI8x16): TSimdMask16; inline;
function simd_ge_i16x8(const a, b: TSimdI16x8): TSimdMask8; inline;
function simd_ge_i32x4(const a, b: TSimdI32x4): TSimdMask4; inline;
function simd_ge_i64x2(const a, b: TSimdI64x2): TSimdMask2; inline;

function simd_ge_u8x16(const a, b: TSimdU8x16): TSimdMask16; inline;
function simd_ge_u16x8(const a, b: TSimdU16x8): TSimdMask8; inline;
function simd_ge_u32x4(const a, b: TSimdU32x4): TSimdMask4; inline;
function simd_ge_u64x2(const a, b: TSimdU64x2): TSimdMask2; inline;

implementation

uses
  fafafa.core.simd.scalar;

// === 相等比较实现 ===

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

function simd_eq_f32x16(const a, b: TSimdF32x16): TSimdMask16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] = b[i];
end;

function simd_eq_f64x2(const a, b: TSimdF64x2): TSimdMask2;
begin
  Result := simd_eq_f64x2_scalar(a, b);
end;

function simd_eq_f64x4(const a, b: TSimdF64x4): TSimdMask4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] = b[i];
end;

function simd_eq_f64x8(const a, b: TSimdF64x8): TSimdMask8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] = b[i];
end;

// 整数相等比较
function simd_eq_i8x16(const a, b: TSimdI8x16): TSimdMask16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] = b[i];
end;

function simd_eq_i8x32(const a, b: TSimdI8x32): TSimdMask32;
var i: Integer;
begin
  for i := 0 to 31 do
    Result[i] := a[i] = b[i];
end;

function simd_eq_i16x8(const a, b: TSimdI16x8): TSimdMask8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] = b[i];
end;

function simd_eq_i16x16(const a, b: TSimdI16x16): TSimdMask16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] = b[i];
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

function simd_eq_i64x2(const a, b: TSimdI64x2): TSimdMask2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] = b[i];
end;

function simd_eq_i64x4(const a, b: TSimdI64x4): TSimdMask4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] = b[i];
end;

// 无符号整数相等比较
function simd_eq_u8x16(const a, b: TSimdU8x16): TSimdMask16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] = b[i];
end;

function simd_eq_u8x32(const a, b: TSimdU8x32): TSimdMask32;
var i: Integer;
begin
  for i := 0 to 31 do
    Result[i] := a[i] = b[i];
end;

function simd_eq_u16x8(const a, b: TSimdU16x8): TSimdMask8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] = b[i];
end;

function simd_eq_u16x16(const a, b: TSimdU16x16): TSimdMask16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] = b[i];
end;

function simd_eq_u32x4(const a, b: TSimdU32x4): TSimdMask4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] = b[i];
end;

function simd_eq_u32x8(const a, b: TSimdU32x8): TSimdMask8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] = b[i];
end;

function simd_eq_u64x2(const a, b: TSimdU64x2): TSimdMask2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] = b[i];
end;

function simd_eq_u64x4(const a, b: TSimdU64x4): TSimdMask4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] = b[i];
end;

// === 不等比较实现 ===

function simd_ne_f32x4(const a, b: TSimdF32x4): TSimdMask4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] <> b[i];
end;

function simd_ne_f32x8(const a, b: TSimdF32x8): TSimdMask8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] <> b[i];
end;

function simd_ne_f64x2(const a, b: TSimdF64x2): TSimdMask2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] <> b[i];
end;

function simd_ne_f64x4(const a, b: TSimdF64x4): TSimdMask4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] <> b[i];
end;

function simd_ne_i8x16(const a, b: TSimdI8x16): TSimdMask16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] <> b[i];
end;

function simd_ne_i16x8(const a, b: TSimdI16x8): TSimdMask8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] <> b[i];
end;

function simd_ne_i32x4(const a, b: TSimdI32x4): TSimdMask4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] <> b[i];
end;

function simd_ne_i32x8(const a, b: TSimdI32x8): TSimdMask8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] <> b[i];
end;

function simd_ne_i64x2(const a, b: TSimdI64x2): TSimdMask2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] <> b[i];
end;

function simd_ne_u8x16(const a, b: TSimdU8x16): TSimdMask16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] <> b[i];
end;

function simd_ne_u16x8(const a, b: TSimdU16x8): TSimdMask8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] <> b[i];
end;

function simd_ne_u32x4(const a, b: TSimdU32x4): TSimdMask4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] <> b[i];
end;

function simd_ne_u64x2(const a, b: TSimdU64x2): TSimdMask2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] <> b[i];
end;

// === 小于比较实现 ===

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

function simd_lt_f64x4(const a, b: TSimdF64x4): TSimdMask4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] < b[i];
end;

function simd_lt_i8x16(const a, b: TSimdI8x16): TSimdMask16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] < b[i];
end;

function simd_lt_i16x8(const a, b: TSimdI16x8): TSimdMask8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] < b[i];
end;

function simd_lt_i32x4(const a, b: TSimdI32x4): TSimdMask4;
begin
  Result := simd_lt_i32x4_scalar(a, b);
end;

function simd_lt_i32x8(const a, b: TSimdI32x8): TSimdMask8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] < b[i];
end;

function simd_lt_i64x2(const a, b: TSimdI64x2): TSimdMask2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] < b[i];
end;

function simd_lt_u8x16(const a, b: TSimdU8x16): TSimdMask16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] < b[i];
end;

function simd_lt_u16x8(const a, b: TSimdU16x8): TSimdMask8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] < b[i];
end;

function simd_lt_u32x4(const a, b: TSimdU32x4): TSimdMask4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] < b[i];
end;

function simd_lt_u64x2(const a, b: TSimdU64x2): TSimdMask2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] < b[i];
end;

// === 小于等于比较实现 ===

function simd_le_f32x4(const a, b: TSimdF32x4): TSimdMask4;
begin
  Result := simd_le_f32x4_scalar(a, b);
end;

function simd_le_f32x8(const a, b: TSimdF32x8): TSimdMask8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] <= b[i];
end;

function simd_le_f64x2(const a, b: TSimdF64x2): TSimdMask2;
begin
  Result := simd_le_f64x2_scalar(a, b);
end;

function simd_le_f64x4(const a, b: TSimdF64x4): TSimdMask4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] <= b[i];
end;

function simd_le_i8x16(const a, b: TSimdI8x16): TSimdMask16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] <= b[i];
end;

function simd_le_i16x8(const a, b: TSimdI16x8): TSimdMask8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] <= b[i];
end;

function simd_le_i32x4(const a, b: TSimdI32x4): TSimdMask4;
begin
  Result := simd_le_i32x4_scalar(a, b);
end;

function simd_le_i64x2(const a, b: TSimdI64x2): TSimdMask2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] <= b[i];
end;

function simd_le_u8x16(const a, b: TSimdU8x16): TSimdMask16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] <= b[i];
end;

function simd_le_u16x8(const a, b: TSimdU16x8): TSimdMask8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] <= b[i];
end;

function simd_le_u32x4(const a, b: TSimdU32x4): TSimdMask4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] <= b[i];
end;

function simd_le_u64x2(const a, b: TSimdU64x2): TSimdMask2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] <= b[i];
end;

// === 大于比较实现 ===

function simd_gt_f32x4(const a, b: TSimdF32x4): TSimdMask4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] > b[i];
end;

function simd_gt_f32x8(const a, b: TSimdF32x8): TSimdMask8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] > b[i];
end;

function simd_gt_f64x2(const a, b: TSimdF64x2): TSimdMask2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] > b[i];
end;

function simd_gt_f64x4(const a, b: TSimdF64x4): TSimdMask4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] > b[i];
end;

function simd_gt_i8x16(const a, b: TSimdI8x16): TSimdMask16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] > b[i];
end;

function simd_gt_i16x8(const a, b: TSimdI16x8): TSimdMask8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] > b[i];
end;

function simd_gt_i32x4(const a, b: TSimdI32x4): TSimdMask4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] > b[i];
end;

function simd_gt_i64x2(const a, b: TSimdI64x2): TSimdMask2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] > b[i];
end;

function simd_gt_u8x16(const a, b: TSimdU8x16): TSimdMask16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] > b[i];
end;

function simd_gt_u16x8(const a, b: TSimdU16x8): TSimdMask8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] > b[i];
end;

function simd_gt_u32x4(const a, b: TSimdU32x4): TSimdMask4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] > b[i];
end;

function simd_gt_u64x2(const a, b: TSimdU64x2): TSimdMask2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] > b[i];
end;

// === 大于等于比较实现 ===

function simd_ge_f32x4(const a, b: TSimdF32x4): TSimdMask4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] >= b[i];
end;

function simd_ge_f32x8(const a, b: TSimdF32x8): TSimdMask8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] >= b[i];
end;

function simd_ge_f64x2(const a, b: TSimdF64x2): TSimdMask2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] >= b[i];
end;

function simd_ge_f64x4(const a, b: TSimdF64x4): TSimdMask4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] >= b[i];
end;

function simd_ge_i8x16(const a, b: TSimdI8x16): TSimdMask16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] >= b[i];
end;

function simd_ge_i16x8(const a, b: TSimdI16x8): TSimdMask8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] >= b[i];
end;

function simd_ge_i32x4(const a, b: TSimdI32x4): TSimdMask4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] >= b[i];
end;

function simd_ge_i64x2(const a, b: TSimdI64x2): TSimdMask2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] >= b[i];
end;

function simd_ge_u8x16(const a, b: TSimdU8x16): TSimdMask16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] >= b[i];
end;

function simd_ge_u16x8(const a, b: TSimdU16x8): TSimdMask8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] >= b[i];
end;

function simd_ge_u32x4(const a, b: TSimdU32x4): TSimdMask4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] >= b[i];
end;

function simd_ge_u64x2(const a, b: TSimdU64x2): TSimdMask2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] >= b[i];
end;

end.
