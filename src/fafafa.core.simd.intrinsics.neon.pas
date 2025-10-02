unit fafafa.core.simd.intrinsics.neon;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  === fafafa.core.simd.intrinsics.neon ===
  ARM NEON 指令集支�?  
  NEON �?ARM �?SIMD 指令集扩�?  提供 128-bit 向量运算能力
  
  特性：
  - 128-bit 向量寄存�?(q0-q15)
  - 64-bit 向量寄存�?(d0-d31)
  - 整数和浮点运�?  - 饱和运算
  - 向量加载/存储
  
  兼容性：ARMv7-A 及更新的 ARM 处理�?}

interface

uses
  fafafa.core.simd.intrinsics.base;

{$IFDEF CPUARM}

// === NEON 基础类型 ===
type
  // 64-bit 向量类型
  TNeon64 = record
    case Integer of
      0: (n64_u64: UInt64);
      1: (n64_i64: Int64);
      2: (n64_u32: array[0..1] of UInt32);
      3: (n64_i32: array[0..1] of LongInt);
      4: (n64_u16: array[0..3] of UInt16);
      5: (n64_i16: array[0..3] of SmallInt);
      6: (n64_u8: array[0..7] of UInt8);
      7: (n64_i8: array[0..7] of ShortInt);
      8: (n64_f32: array[0..1] of Single);
  end;
  PNeon64 = ^TNeon64;

  // 128-bit 向量类型 (使用现有�?TM128)
  TNeon128 = TM128;
  PNeon128 = ^TNeon128;

// === NEON 基础函数 ===
// Load/Store
function neon_vld1q_u32(const Ptr: Pointer): TNeon128;
function neon_vld1q_f32(const Ptr: Pointer): TNeon128;
function neon_vld1_u32(const Ptr: Pointer): TNeon64;
function neon_vld1_f32(const Ptr: Pointer): TNeon64;
procedure neon_vst1q_u32(var Dest; const Src: TNeon128);
procedure neon_vst1q_f32(var Dest; const Src: TNeon128);
procedure neon_vst1_u32(var Dest; const Src: TNeon64);
procedure neon_vst1_f32(var Dest; const Src: TNeon64);

// Set/Duplicate
function neon_vdupq_n_u32(Value: UInt32): TNeon128;
function neon_vdupq_n_f32(Value: Single): TNeon128;
function neon_vdup_n_u32(Value: UInt32): TNeon64;
function neon_vdup_n_f32(Value: Single): TNeon64;

// Arithmetic
function neon_vaddq_u32(const a, b: TNeon128): TNeon128;
function neon_vaddq_f32(const a, b: TNeon128): TNeon128;
function neon_vsubq_u32(const a, b: TNeon128): TNeon128;
function neon_vsubq_f32(const a, b: TNeon128): TNeon128;
function neon_vmulq_u32(const a, b: TNeon128): TNeon128;
function neon_vmulq_f32(const a, b: TNeon128): TNeon128;

// Logical
function neon_vandq_u32(const a, b: TNeon128): TNeon128;
function neon_vorrq_u32(const a, b: TNeon128): TNeon128;
function neon_veorq_u32(const a, b: TNeon128): TNeon128;
function neon_vbicq_u32(const a, b: TNeon128): TNeon128;

// Compare
function neon_vceqq_u32(const a, b: TNeon128): TNeon128;
function neon_vceqq_f32(const a, b: TNeon128): TNeon128;
function neon_vcgtq_u32(const a, b: TNeon128): TNeon128;
function neon_vcgtq_f32(const a, b: TNeon128): TNeon128;

// Min/Max
function neon_vmaxq_u32(const a, b: TNeon128): TNeon128;
function neon_vmaxq_f32(const a, b: TNeon128): TNeon128;
function neon_vminq_u32(const a, b: TNeon128): TNeon128;
function neon_vminq_f32(const a, b: TNeon128): TNeon128;

{$ENDIF} // CPUARM

implementation

{$IFDEF CPUARM}

// === NEON 函数实现 (Pascal 版本) ===
function neon_vld1q_u32(const Ptr: Pointer): TNeon128;
begin
  Result := PTM128(Ptr)^;
end;

function neon_vld1q_f32(const Ptr: Pointer): TNeon128;
begin
  Result := PTM128(Ptr)^;
end;

function neon_vld1_u32(const Ptr: Pointer): TNeon64;
begin
  Result.n64_u64 := PUInt64(Ptr)^;
end;

function neon_vld1_f32(const Ptr: Pointer): TNeon64;
begin
  Result.n64_u64 := PUInt64(Ptr)^;
end;

procedure neon_vst1q_u32(var Dest; const Src: TNeon128);
begin
  PTM128(@Dest)^ := Src;
end;

procedure neon_vst1q_f32(var Dest; const Src: TNeon128);
begin
  PTM128(@Dest)^ := Src;
end;

procedure neon_vst1_u32(var Dest; const Src: TNeon64);
begin
  PUInt64(@Dest)^ := Src.n64_u64;
end;

procedure neon_vst1_f32(var Dest; const Src: TNeon64);
begin
  PUInt64(@Dest)^ := Src.n64_u64;
end;

function neon_vdupq_n_u32(Value: UInt32): TNeon128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_u32[i] := Value;
end;

function neon_vdupq_n_f32(Value: Single): TNeon128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128_f32[i] := Value;
end;

function neon_vdup_n_u32(Value: UInt32): TNeon64;
begin
  Result.n64_u32[0] := Value;
  Result.n64_u32[1] := Value;
end;

function neon_vdup_n_f32(Value: Single): TNeon64;
begin
  Result.n64_f32[0] := Value;
  Result.n64_f32[1] := Value;
end;

function neon_vaddq_u32(const a, b: TNeon128): TNeon128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_u32[i] := a.m128i_u32[i] + b.m128i_u32[i];
end;

function neon_vaddq_f32(const a, b: TNeon128): TNeon128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128_f32[i] := a.m128_f32[i] + b.m128_f32[i];
end;

function neon_vsubq_u32(const a, b: TNeon128): TNeon128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_u32[i] := a.m128i_u32[i] - b.m128i_u32[i];
end;

function neon_vsubq_f32(const a, b: TNeon128): TNeon128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128_f32[i] := a.m128_f32[i] - b.m128_f32[i];
end;

function neon_vmulq_u32(const a, b: TNeon128): TNeon128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_u32[i] := a.m128i_u32[i] * b.m128i_u32[i];
end;

function neon_vmulq_f32(const a, b: TNeon128): TNeon128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128_f32[i] := a.m128_f32[i] * b.m128_f32[i];
end;

function neon_vandq_u32(const a, b: TNeon128): TNeon128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_u32[i] := a.m128i_u32[i] and b.m128i_u32[i];
end;

function neon_vorrq_u32(const a, b: TNeon128): TNeon128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_u32[i] := a.m128i_u32[i] or b.m128i_u32[i];
end;

function neon_veorq_u32(const a, b: TNeon128): TNeon128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_u32[i] := a.m128i_u32[i] xor b.m128i_u32[i];
end;

function neon_vbicq_u32(const a, b: TNeon128): TNeon128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_u32[i] := a.m128i_u32[i] and (not b.m128i_u32[i]);
end;

function neon_vceqq_u32(const a, b: TNeon128): TNeon128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128i_u32[i] = b.m128i_u32[i] then
      Result.m128i_u32[i] := $FFFFFFFF
    else
      Result.m128i_u32[i] := $00000000;
end;

function neon_vceqq_f32(const a, b: TNeon128): TNeon128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128_f32[i] = b.m128_f32[i] then
      Result.m128i_u32[i] := $FFFFFFFF
    else
      Result.m128i_u32[i] := $00000000;
end;

function neon_vcgtq_u32(const a, b: TNeon128): TNeon128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128i_u32[i] > b.m128i_u32[i] then
      Result.m128i_u32[i] := $FFFFFFFF
    else
      Result.m128i_u32[i] := $00000000;
end;

function neon_vcgtq_f32(const a, b: TNeon128): TNeon128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128_f32[i] > b.m128_f32[i] then
      Result.m128i_u32[i] := $FFFFFFFF
    else
      Result.m128i_u32[i] := $00000000;
end;

function neon_vmaxq_u32(const a, b: TNeon128): TNeon128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128i_u32[i] > b.m128i_u32[i] then
      Result.m128i_u32[i] := a.m128i_u32[i]
    else
      Result.m128i_u32[i] := b.m128i_u32[i];
end;

function neon_vmaxq_f32(const a, b: TNeon128): TNeon128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128_f32[i] > b.m128_f32[i] then
      Result.m128_f32[i] := a.m128_f32[i]
    else
      Result.m128_f32[i] := b.m128_f32[i];
end;

function neon_vminq_u32(const a, b: TNeon128): TNeon128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128i_u32[i] < b.m128i_u32[i] then
      Result.m128i_u32[i] := a.m128i_u32[i]
    else
      Result.m128i_u32[i] := b.m128i_u32[i];
end;

function neon_vminq_f32(const a, b: TNeon128): TNeon128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128_f32[i] < b.m128_f32[i] then
      Result.m128_f32[i] := a.m128_f32[i]
    else
      Result.m128_f32[i] := b.m128_f32[i];
end;

{$ELSE}
// �?ARM 平台的空实现
{$ENDIF} // CPUARM

end.


