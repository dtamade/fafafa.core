unit fafafa.core.simd.bitwise;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.types;

// === 位运算（对标 Rust std::simd）===
// 统一使用 simd_ 前缀，遵循 Rust 命名规范

// === 1. 按位与（AND）===

// 整数按位与
function simd_and_i8x16(const a, b: TSimdI8x16): TSimdI8x16; inline;
function simd_and_i8x32(const a, b: TSimdI8x32): TSimdI8x32; inline;
function simd_and_i8x64(const a, b: TSimdI8x64): TSimdI8x64; inline;

function simd_and_i16x8(const a, b: TSimdI16x8): TSimdI16x8; inline;
function simd_and_i16x16(const a, b: TSimdI16x16): TSimdI16x16; inline;
function simd_and_i16x32(const a, b: TSimdI16x32): TSimdI16x32; inline;

function simd_and_i32x4(const a, b: TSimdI32x4): TSimdI32x4; inline;
function simd_and_i32x8(const a, b: TSimdI32x8): TSimdI32x8; inline;
function simd_and_i32x16(const a, b: TSimdI32x16): TSimdI32x16; inline;

function simd_and_i64x2(const a, b: TSimdI64x2): TSimdI64x2; inline;
function simd_and_i64x4(const a, b: TSimdI64x4): TSimdI64x4; inline;
function simd_and_i64x8(const a, b: TSimdI64x8): TSimdI64x8; inline;

// 无符号整数按位与
function simd_and_u8x16(const a, b: TSimdU8x16): TSimdU8x16; inline;
function simd_and_u8x32(const a, b: TSimdU8x32): TSimdU8x32; inline;
function simd_and_u8x64(const a, b: TSimdU8x64): TSimdU8x64; inline;

function simd_and_u16x8(const a, b: TSimdU16x8): TSimdU16x8; inline;
function simd_and_u16x16(const a, b: TSimdU16x16): TSimdU16x16; inline;
function simd_and_u16x32(const a, b: TSimdU16x32): TSimdU16x32; inline;

function simd_and_u32x4(const a, b: TSimdU32x4): TSimdU32x4; inline;
function simd_and_u32x8(const a, b: TSimdU32x8): TSimdU32x8; inline;
function simd_and_u32x16(const a, b: TSimdU32x16): TSimdU32x16; inline;

function simd_and_u64x2(const a, b: TSimdU64x2): TSimdU64x2; inline;
function simd_and_u64x4(const a, b: TSimdU64x4): TSimdU64x4; inline;
function simd_and_u64x8(const a, b: TSimdU64x8): TSimdU64x8; inline;

// === 2. 按位或（OR）===

// 整数按位或
function simd_or_i8x16(const a, b: TSimdI8x16): TSimdI8x16; inline;
function simd_or_i8x32(const a, b: TSimdI8x32): TSimdI8x32; inline;
function simd_or_i16x8(const a, b: TSimdI16x8): TSimdI16x8; inline;
function simd_or_i16x16(const a, b: TSimdI16x16): TSimdI16x16; inline;
function simd_or_i32x4(const a, b: TSimdI32x4): TSimdI32x4; inline;
function simd_or_i32x8(const a, b: TSimdI32x8): TSimdI32x8; inline;
function simd_or_i64x2(const a, b: TSimdI64x2): TSimdI64x2; inline;
function simd_or_i64x4(const a, b: TSimdI64x4): TSimdI64x4; inline;

// 无符号整数按位或
function simd_or_u8x16(const a, b: TSimdU8x16): TSimdU8x16; inline;
function simd_or_u8x32(const a, b: TSimdU8x32): TSimdU8x32; inline;
function simd_or_u16x8(const a, b: TSimdU16x8): TSimdU16x8; inline;
function simd_or_u16x16(const a, b: TSimdU16x16): TSimdU16x16; inline;
function simd_or_u32x4(const a, b: TSimdU32x4): TSimdU32x4; inline;
function simd_or_u32x8(const a, b: TSimdU32x8): TSimdU32x8; inline;
function simd_or_u64x2(const a, b: TSimdU64x2): TSimdU64x2; inline;
function simd_or_u64x4(const a, b: TSimdU64x4): TSimdU64x4; inline;

// === 3. 按位异或（XOR）===

// 整数按位异或
function simd_xor_i8x16(const a, b: TSimdI8x16): TSimdI8x16; inline;
function simd_xor_i8x32(const a, b: TSimdI8x32): TSimdI8x32; inline;
function simd_xor_i16x8(const a, b: TSimdI16x8): TSimdI16x8; inline;
function simd_xor_i16x16(const a, b: TSimdI16x16): TSimdI16x16; inline;
function simd_xor_i32x4(const a, b: TSimdI32x4): TSimdI32x4; inline;
function simd_xor_i32x8(const a, b: TSimdI32x8): TSimdI32x8; inline;
function simd_xor_i64x2(const a, b: TSimdI64x2): TSimdI64x2; inline;
function simd_xor_i64x4(const a, b: TSimdI64x4): TSimdI64x4; inline;

// 无符号整数按位异或
function simd_xor_u8x16(const a, b: TSimdU8x16): TSimdU8x16; inline;
function simd_xor_u8x32(const a, b: TSimdU8x32): TSimdU8x32; inline;
function simd_xor_u16x8(const a, b: TSimdU16x8): TSimdU16x8; inline;
function simd_xor_u16x16(const a, b: TSimdU16x16): TSimdU16x16; inline;
function simd_xor_u32x4(const a, b: TSimdU32x4): TSimdU32x4; inline;
function simd_xor_u32x8(const a, b: TSimdU32x8): TSimdU32x8; inline;
function simd_xor_u64x2(const a, b: TSimdU64x2): TSimdU64x2; inline;
function simd_xor_u64x4(const a, b: TSimdU64x4): TSimdU64x4; inline;

// === 4. 按位取反（NOT）===

// 整数按位取反
function simd_not_i8x16(const a: TSimdI8x16): TSimdI8x16; inline;
function simd_not_i8x32(const a: TSimdI8x32): TSimdI8x32; inline;
function simd_not_i16x8(const a: TSimdI16x8): TSimdI16x8; inline;
function simd_not_i16x16(const a: TSimdI16x16): TSimdI16x16; inline;
function simd_not_i32x4(const a: TSimdI32x4): TSimdI32x4; inline;
function simd_not_i32x8(const a: TSimdI32x8): TSimdI32x8; inline;
function simd_not_i64x2(const a: TSimdI64x2): TSimdI64x2; inline;
function simd_not_i64x4(const a: TSimdI64x4): TSimdI64x4; inline;

// 无符号整数按位取反
function simd_not_u8x16(const a: TSimdU8x16): TSimdU8x16; inline;
function simd_not_u8x32(const a: TSimdU8x32): TSimdU8x32; inline;
function simd_not_u16x8(const a: TSimdU16x8): TSimdU16x8; inline;
function simd_not_u16x16(const a: TSimdU16x16): TSimdU16x16; inline;
function simd_not_u32x4(const a: TSimdU32x4): TSimdU32x4; inline;
function simd_not_u32x8(const a: TSimdU32x8): TSimdU32x8; inline;
function simd_not_u64x2(const a: TSimdU64x2): TSimdU64x2; inline;
function simd_not_u64x4(const a: TSimdU64x4): TSimdU64x4; inline;

// === 5. 位移运算 ===

// 左移
function simd_shl_i16x8(const a: TSimdI16x8; shift: Integer): TSimdI16x8; inline;
function simd_shl_i16x16(const a: TSimdI16x16; shift: Integer): TSimdI16x16; inline;
function simd_shl_i32x4(const a: TSimdI32x4; shift: Integer): TSimdI32x4; inline;
function simd_shl_i32x8(const a: TSimdI32x8; shift: Integer): TSimdI32x8; inline;
function simd_shl_i64x2(const a: TSimdI64x2; shift: Integer): TSimdI64x2; inline;
function simd_shl_i64x4(const a: TSimdI64x4; shift: Integer): TSimdI64x4; inline;

function simd_shl_u16x8(const a: TSimdU16x8; shift: Integer): TSimdU16x8; inline;
function simd_shl_u16x16(const a: TSimdU16x16; shift: Integer): TSimdU16x16; inline;
function simd_shl_u32x4(const a: TSimdU32x4; shift: Integer): TSimdU32x4; inline;
function simd_shl_u32x8(const a: TSimdU32x8; shift: Integer): TSimdU32x8; inline;
function simd_shl_u64x2(const a: TSimdU64x2; shift: Integer): TSimdU64x2; inline;
function simd_shl_u64x4(const a: TSimdU64x4; shift: Integer): TSimdU64x4; inline;

// 右移（算术右移，有符号）
function simd_shr_i16x8(const a: TSimdI16x8; shift: Integer): TSimdI16x8; inline;
function simd_shr_i16x16(const a: TSimdI16x16; shift: Integer): TSimdI16x16; inline;
function simd_shr_i32x4(const a: TSimdI32x4; shift: Integer): TSimdI32x4; inline;
function simd_shr_i32x8(const a: TSimdI32x8; shift: Integer): TSimdI32x8; inline;
function simd_shr_i64x2(const a: TSimdI64x2; shift: Integer): TSimdI64x2; inline;
function simd_shr_i64x4(const a: TSimdI64x4; shift: Integer): TSimdI64x4; inline;

// 右移（逻辑右移，无符号）
function simd_shr_u16x8(const a: TSimdU16x8; shift: Integer): TSimdU16x8; inline;
function simd_shr_u16x16(const a: TSimdU16x16; shift: Integer): TSimdU16x16; inline;
function simd_shr_u32x4(const a: TSimdU32x4; shift: Integer): TSimdU32x4; inline;
function simd_shr_u32x8(const a: TSimdU32x8; shift: Integer): TSimdU32x8; inline;
function simd_shr_u64x2(const a: TSimdU64x2; shift: Integer): TSimdU64x2; inline;
function simd_shr_u64x4(const a: TSimdU64x4; shift: Integer): TSimdU64x4; inline;

// === 6. 位计数函数 ===

// 前导零计数
function simd_leading_zeros_u32x4(const a: TSimdU32x4): TSimdU32x4; inline;
function simd_leading_zeros_u32x8(const a: TSimdU32x8): TSimdU32x8; inline;
function simd_leading_zeros_u64x2(const a: TSimdU64x2): TSimdU64x2; inline;
function simd_leading_zeros_u64x4(const a: TSimdU64x4): TSimdU64x4; inline;

// 尾随零计数
function simd_trailing_zeros_u32x4(const a: TSimdU32x4): TSimdU32x4; inline;
function simd_trailing_zeros_u32x8(const a: TSimdU32x8): TSimdU32x8; inline;
function simd_trailing_zeros_u64x2(const a: TSimdU64x2): TSimdU64x2; inline;
function simd_trailing_zeros_u64x4(const a: TSimdU64x4): TSimdU64x4; inline;

// 位计数（popcount）
function simd_popcount_u8x16(const a: TSimdU8x16): TSimdU8x16; inline;
function simd_popcount_u8x32(const a: TSimdU8x32): TSimdU8x32; inline;
function simd_popcount_u16x8(const a: TSimdU16x8): TSimdU16x8; inline;
function simd_popcount_u16x16(const a: TSimdU16x16): TSimdU16x16; inline;
function simd_popcount_u32x4(const a: TSimdU32x4): TSimdU32x4; inline;
function simd_popcount_u32x8(const a: TSimdU32x8): TSimdU32x8; inline;
function simd_popcount_u64x2(const a: TSimdU64x2): TSimdU64x2; inline;
function simd_popcount_u64x4(const a: TSimdU64x4): TSimdU64x4; inline;

implementation

// === 按位与实现 ===

function simd_and_i8x16(const a, b: TSimdI8x16): TSimdI8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] and b[i];
end;

function simd_and_i8x32(const a, b: TSimdI8x32): TSimdI8x32;
var i: Integer;
begin
  for i := 0 to 31 do
    Result[i] := a[i] and b[i];
end;

function simd_and_i8x64(const a, b: TSimdI8x64): TSimdI8x64;
var i: Integer;
begin
  for i := 0 to 63 do
    Result[i] := a[i] and b[i];
end;

function simd_and_i16x8(const a, b: TSimdI16x8): TSimdI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] and b[i];
end;

function simd_and_i16x16(const a, b: TSimdI16x16): TSimdI16x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] and b[i];
end;

function simd_and_i16x32(const a, b: TSimdI16x32): TSimdI16x32;
var i: Integer;
begin
  for i := 0 to 31 do
    Result[i] := a[i] and b[i];
end;

function simd_and_i32x4(const a, b: TSimdI32x4): TSimdI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] and b[i];
end;

function simd_and_i32x8(const a, b: TSimdI32x8): TSimdI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] and b[i];
end;

function simd_and_i32x16(const a, b: TSimdI32x16): TSimdI32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] and b[i];
end;

function simd_and_i64x2(const a, b: TSimdI64x2): TSimdI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] and b[i];
end;

function simd_and_i64x4(const a, b: TSimdI64x4): TSimdI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] and b[i];
end;

function simd_and_i64x8(const a, b: TSimdI64x8): TSimdI64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] and b[i];
end;

// 无符号整数按位与
function simd_and_u8x16(const a, b: TSimdU8x16): TSimdU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] and b[i];
end;

function simd_and_u8x32(const a, b: TSimdU8x32): TSimdU8x32;
var i: Integer;
begin
  for i := 0 to 31 do
    Result[i] := a[i] and b[i];
end;

function simd_and_u8x64(const a, b: TSimdU8x64): TSimdU8x64;
var i: Integer;
begin
  for i := 0 to 63 do
    Result[i] := a[i] and b[i];
end;

function simd_and_u16x8(const a, b: TSimdU16x8): TSimdU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] and b[i];
end;

function simd_and_u16x16(const a, b: TSimdU16x16): TSimdU16x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] and b[i];
end;

function simd_and_u16x32(const a, b: TSimdU16x32): TSimdU16x32;
var i: Integer;
begin
  for i := 0 to 31 do
    Result[i] := a[i] and b[i];
end;

function simd_and_u32x4(const a, b: TSimdU32x4): TSimdU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] and b[i];
end;

function simd_and_u32x8(const a, b: TSimdU32x8): TSimdU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] and b[i];
end;

function simd_and_u32x16(const a, b: TSimdU32x16): TSimdU32x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] and b[i];
end;

function simd_and_u64x2(const a, b: TSimdU64x2): TSimdU64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] and b[i];
end;

function simd_and_u64x4(const a, b: TSimdU64x4): TSimdU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] and b[i];
end;

function simd_and_u64x8(const a, b: TSimdU64x8): TSimdU64x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] and b[i];
end;

// === 按位或实现 ===

function simd_or_i8x16(const a, b: TSimdI8x16): TSimdI8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] or b[i];
end;

function simd_or_i8x32(const a, b: TSimdI8x32): TSimdI8x32;
var i: Integer;
begin
  for i := 0 to 31 do
    Result[i] := a[i] or b[i];
end;

function simd_or_i16x8(const a, b: TSimdI16x8): TSimdI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] or b[i];
end;

function simd_or_i16x16(const a, b: TSimdI16x16): TSimdI16x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] or b[i];
end;

function simd_or_i32x4(const a, b: TSimdI32x4): TSimdI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] or b[i];
end;

function simd_or_i32x8(const a, b: TSimdI32x8): TSimdI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] or b[i];
end;

function simd_or_i64x2(const a, b: TSimdI64x2): TSimdI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] or b[i];
end;

function simd_or_i64x4(const a, b: TSimdI64x4): TSimdI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] or b[i];
end;

// 无符号整数按位或
function simd_or_u8x16(const a, b: TSimdU8x16): TSimdU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] or b[i];
end;

function simd_or_u8x32(const a, b: TSimdU8x32): TSimdU8x32;
var i: Integer;
begin
  for i := 0 to 31 do
    Result[i] := a[i] or b[i];
end;

function simd_or_u16x8(const a, b: TSimdU16x8): TSimdU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] or b[i];
end;

function simd_or_u16x16(const a, b: TSimdU16x16): TSimdU16x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] or b[i];
end;

function simd_or_u32x4(const a, b: TSimdU32x4): TSimdU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] or b[i];
end;

function simd_or_u32x8(const a, b: TSimdU32x8): TSimdU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] or b[i];
end;

function simd_or_u64x2(const a, b: TSimdU64x2): TSimdU64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] or b[i];
end;

function simd_or_u64x4(const a, b: TSimdU64x4): TSimdU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] or b[i];
end;

// === 按位异或实现 ===

function simd_xor_i8x16(const a, b: TSimdI8x16): TSimdI8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] xor b[i];
end;

function simd_xor_i8x32(const a, b: TSimdI8x32): TSimdI8x32;
var i: Integer;
begin
  for i := 0 to 31 do
    Result[i] := a[i] xor b[i];
end;

function simd_xor_i16x8(const a, b: TSimdI16x8): TSimdI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] xor b[i];
end;

function simd_xor_i16x16(const a, b: TSimdI16x16): TSimdI16x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] xor b[i];
end;

function simd_xor_i32x4(const a, b: TSimdI32x4): TSimdI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] xor b[i];
end;

function simd_xor_i32x8(const a, b: TSimdI32x8): TSimdI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] xor b[i];
end;

function simd_xor_i64x2(const a, b: TSimdI64x2): TSimdI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] xor b[i];
end;

function simd_xor_i64x4(const a, b: TSimdI64x4): TSimdI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] xor b[i];
end;

// 无符号整数按位异或
function simd_xor_u8x16(const a, b: TSimdU8x16): TSimdU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] xor b[i];
end;

function simd_xor_u8x32(const a, b: TSimdU8x32): TSimdU8x32;
var i: Integer;
begin
  for i := 0 to 31 do
    Result[i] := a[i] xor b[i];
end;

function simd_xor_u16x8(const a, b: TSimdU16x8): TSimdU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] xor b[i];
end;

function simd_xor_u16x16(const a, b: TSimdU16x16): TSimdU16x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] xor b[i];
end;

function simd_xor_u32x4(const a, b: TSimdU32x4): TSimdU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] xor b[i];
end;

function simd_xor_u32x8(const a, b: TSimdU32x8): TSimdU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] xor b[i];
end;

function simd_xor_u64x2(const a, b: TSimdU64x2): TSimdU64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] xor b[i];
end;

function simd_xor_u64x4(const a, b: TSimdU64x4): TSimdU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] xor b[i];
end;

// === 按位取反实现 ===

function simd_not_i8x16(const a: TSimdI8x16): TSimdI8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := not a[i];
end;

function simd_not_i8x32(const a: TSimdI8x32): TSimdI8x32;
var i: Integer;
begin
  for i := 0 to 31 do
    Result[i] := not a[i];
end;

function simd_not_i16x8(const a: TSimdI16x8): TSimdI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := not a[i];
end;

function simd_not_i16x16(const a: TSimdI16x16): TSimdI16x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := not a[i];
end;

function simd_not_i32x4(const a: TSimdI32x4): TSimdI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := not a[i];
end;

function simd_not_i32x8(const a: TSimdI32x8): TSimdI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := not a[i];
end;

function simd_not_i64x2(const a: TSimdI64x2): TSimdI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := not a[i];
end;

function simd_not_i64x4(const a: TSimdI64x4): TSimdI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := not a[i];
end;

// 无符号整数按位取反
function simd_not_u8x16(const a: TSimdU8x16): TSimdU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := not a[i];
end;

function simd_not_u8x32(const a: TSimdU8x32): TSimdU8x32;
var i: Integer;
begin
  for i := 0 to 31 do
    Result[i] := not a[i];
end;

function simd_not_u16x8(const a: TSimdU16x8): TSimdU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := not a[i];
end;

function simd_not_u16x16(const a: TSimdU16x16): TSimdU16x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := not a[i];
end;

function simd_not_u32x4(const a: TSimdU32x4): TSimdU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := not a[i];
end;

function simd_not_u32x8(const a: TSimdU32x8): TSimdU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := not a[i];
end;

function simd_not_u64x2(const a: TSimdU64x2): TSimdU64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := not a[i];
end;

function simd_not_u64x4(const a: TSimdU64x4): TSimdU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := not a[i];
end;

// === 位移运算实现 ===

// 左移
function simd_shl_i16x8(const a: TSimdI16x8; shift: Integer): TSimdI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] shl shift;
end;

function simd_shl_i16x16(const a: TSimdI16x16; shift: Integer): TSimdI16x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] shl shift;
end;

function simd_shl_i32x4(const a: TSimdI32x4; shift: Integer): TSimdI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] shl shift;
end;

function simd_shl_i32x8(const a: TSimdI32x8; shift: Integer): TSimdI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] shl shift;
end;

function simd_shl_i64x2(const a: TSimdI64x2; shift: Integer): TSimdI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] shl shift;
end;

function simd_shl_i64x4(const a: TSimdI64x4; shift: Integer): TSimdI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] shl shift;
end;

function simd_shl_u16x8(const a: TSimdU16x8; shift: Integer): TSimdU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] shl shift;
end;

function simd_shl_u16x16(const a: TSimdU16x16; shift: Integer): TSimdU16x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] shl shift;
end;

function simd_shl_u32x4(const a: TSimdU32x4; shift: Integer): TSimdU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] shl shift;
end;

function simd_shl_u32x8(const a: TSimdU32x8; shift: Integer): TSimdU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] shl shift;
end;

function simd_shl_u64x2(const a: TSimdU64x2; shift: Integer): TSimdU64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] shl shift;
end;

function simd_shl_u64x4(const a: TSimdU64x4; shift: Integer): TSimdU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] shl shift;
end;

// 右移（算术右移，有符号）
function simd_shr_i16x8(const a: TSimdI16x8; shift: Integer): TSimdI16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] div (1 shl shift);
end;

function simd_shr_i16x16(const a: TSimdI16x16; shift: Integer): TSimdI16x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] div (1 shl shift);
end;

function simd_shr_i32x4(const a: TSimdI32x4; shift: Integer): TSimdI32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] div (1 shl shift);
end;

function simd_shr_i32x8(const a: TSimdI32x8; shift: Integer): TSimdI32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] div (1 shl shift);
end;

function simd_shr_i64x2(const a: TSimdI64x2; shift: Integer): TSimdI64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] div (Int64(1) shl shift);
end;

function simd_shr_i64x4(const a: TSimdI64x4; shift: Integer): TSimdI64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] div (Int64(1) shl shift);
end;

// 右移（逻辑右移，无符号）
function simd_shr_u16x8(const a: TSimdU16x8; shift: Integer): TSimdU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] shr shift;
end;

function simd_shr_u16x16(const a: TSimdU16x16; shift: Integer): TSimdU16x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := a[i] shr shift;
end;

function simd_shr_u32x4(const a: TSimdU32x4; shift: Integer): TSimdU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] shr shift;
end;

function simd_shr_u32x8(const a: TSimdU32x8; shift: Integer): TSimdU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := a[i] shr shift;
end;

function simd_shr_u64x2(const a: TSimdU64x2; shift: Integer): TSimdU64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := a[i] shr shift;
end;

function simd_shr_u64x4(const a: TSimdU64x4; shift: Integer): TSimdU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := a[i] shr shift;
end;

// === 位计数函数实现 ===

// 内联位计数辅助函数
function PopCount(x: Byte): Byte; inline;
begin
  x := x - ((x shr 1) and $55);
  x := (x and $33) + ((x shr 2) and $33);
  Result := ((x + (x shr 4)) and $0F);
end;

function PopCount(x: UInt16): UInt16; inline;
begin
  x := x - ((x shr 1) and $5555);
  x := (x and $3333) + ((x shr 2) and $3333);
  x := (x + (x shr 4)) and $0F0F;
  Result := (x + (x shr 8)) and $001F;
end;

function PopCount(x: UInt32): UInt32; inline;
begin
  x := x - ((x shr 1) and $55555555);
  x := (x and $33333333) + ((x shr 2) and $33333333);
  x := (x + (x shr 4)) and $0F0F0F0F;
  x := x + (x shr 8);
  x := x + (x shr 16);
  Result := x and $0000003F;
end;

function PopCount(x: UInt64): UInt64; inline;
begin
  x := x - ((x shr 1) and $5555555555555555);
  x := (x and $3333333333333333) + ((x shr 2) and $3333333333333333);
  x := (x + (x shr 4)) and $0F0F0F0F0F0F0F0F;
  x := x + (x shr 8);
  x := x + (x shr 16);
  x := x + (x shr 32);
  Result := x and $000000000000007F;
end;

function LeadingZeros(x: UInt32): UInt32; inline;
var count: UInt32;
begin
  if x = 0 then Exit(32);
  count := 0;
  if (x and $FFFF0000) = 0 then begin count := count + 16; x := x shl 16; end;
  if (x and $FF000000) = 0 then begin count := count + 8; x := x shl 8; end;
  if (x and $F0000000) = 0 then begin count := count + 4; x := x shl 4; end;
  if (x and $C0000000) = 0 then begin count := count + 2; x := x shl 2; end;
  if (x and $80000000) = 0 then count := count + 1;
  Result := count;
end;

function LeadingZeros(x: UInt64): UInt64; inline;
var count: UInt64;
begin
  if x = 0 then Exit(64);
  count := 0;
  if (x and $FFFFFFFF00000000) = 0 then begin count := count + 32; x := x shl 32; end;
  if (x and $FFFF000000000000) = 0 then begin count := count + 16; x := x shl 16; end;
  if (x and $FF00000000000000) = 0 then begin count := count + 8; x := x shl 8; end;
  if (x and $F000000000000000) = 0 then begin count := count + 4; x := x shl 4; end;
  if (x and $C000000000000000) = 0 then begin count := count + 2; x := x shl 2; end;
  if (x and $8000000000000000) = 0 then count := count + 1;
  Result := count;
end;

function TrailingZeros(x: UInt32): UInt32; inline;
var count: UInt32;
begin
  if x = 0 then Exit(32);
  count := 0;
  if (x and $0000FFFF) = 0 then begin count := count + 16; x := x shr 16; end;
  if (x and $000000FF) = 0 then begin count := count + 8; x := x shr 8; end;
  if (x and $0000000F) = 0 then begin count := count + 4; x := x shr 4; end;
  if (x and $00000003) = 0 then begin count := count + 2; x := x shr 2; end;
  if (x and $00000001) = 0 then count := count + 1;
  Result := count;
end;

function TrailingZeros(x: UInt64): UInt64; inline;
var count: UInt64;
begin
  if x = 0 then Exit(64);
  count := 0;
  if (x and $00000000FFFFFFFF) = 0 then begin count := count + 32; x := x shr 32; end;
  if (x and $000000000000FFFF) = 0 then begin count := count + 16; x := x shr 16; end;
  if (x and $00000000000000FF) = 0 then begin count := count + 8; x := x shr 8; end;
  if (x and $000000000000000F) = 0 then begin count := count + 4; x := x shr 4; end;
  if (x and $0000000000000003) = 0 then begin count := count + 2; x := x shr 2; end;
  if (x and $0000000000000001) = 0 then count := count + 1;
  Result := count;
end;

// 前导零计数
function simd_leading_zeros_u32x4(const a: TSimdU32x4): TSimdU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := LeadingZeros(a[i]);
end;

function simd_leading_zeros_u32x8(const a: TSimdU32x8): TSimdU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := LeadingZeros(a[i]);
end;

function simd_leading_zeros_u64x2(const a: TSimdU64x2): TSimdU64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := LeadingZeros(a[i]);
end;

function simd_leading_zeros_u64x4(const a: TSimdU64x4): TSimdU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := LeadingZeros(a[i]);
end;

// 尾随零计数
function simd_trailing_zeros_u32x4(const a: TSimdU32x4): TSimdU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := TrailingZeros(a[i]);
end;

function simd_trailing_zeros_u32x8(const a: TSimdU32x8): TSimdU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := TrailingZeros(a[i]);
end;

function simd_trailing_zeros_u64x2(const a: TSimdU64x2): TSimdU64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := TrailingZeros(a[i]);
end;

function simd_trailing_zeros_u64x4(const a: TSimdU64x4): TSimdU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := TrailingZeros(a[i]);
end;

// 位计数（popcount）
function simd_popcount_u8x16(const a: TSimdU8x16): TSimdU8x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := PopCount(a[i]);
end;

function simd_popcount_u8x32(const a: TSimdU8x32): TSimdU8x32;
var i: Integer;
begin
  for i := 0 to 31 do
    Result[i] := PopCount(a[i]);
end;

function simd_popcount_u16x8(const a: TSimdU16x8): TSimdU16x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := PopCount(a[i]);
end;

function simd_popcount_u16x16(const a: TSimdU16x16): TSimdU16x16;
var i: Integer;
begin
  for i := 0 to 15 do
    Result[i] := PopCount(a[i]);
end;

function simd_popcount_u32x4(const a: TSimdU32x4): TSimdU32x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := PopCount(a[i]);
end;

function simd_popcount_u32x8(const a: TSimdU32x8): TSimdU32x8;
var i: Integer;
begin
  for i := 0 to 7 do
    Result[i] := PopCount(a[i]);
end;

function simd_popcount_u64x2(const a: TSimdU64x2): TSimdU64x2;
var i: Integer;
begin
  for i := 0 to 1 do
    Result[i] := PopCount(a[i]);
end;

function simd_popcount_u64x4(const a: TSimdU64x4): TSimdU64x4;
var i: Integer;
begin
  for i := 0 to 3 do
    Result[i] := PopCount(a[i]);
end;

end.
