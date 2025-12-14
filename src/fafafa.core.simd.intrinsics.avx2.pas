unit fafafa.core.simd.intrinsics.avx2;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  === fafafa.core.simd.intrinsics.avx2 ===
  AVX2 (Advanced Vector Extensions 2) 指令集支�?  
  AVX2 �?Intel �?2013 年引入的 256-bit SIMD 指令集扩�?  将大部分 SSE 整数指令扩展�?256-bit
  
  特性：
  - 256-bit 整数运算
  - 变量移位指令
  - 聚集/分散加载存储
  - 广播指令
  - 融合乘加指令 (FMA)
  
  兼容性：Intel Haswell (2013) 及更新的处理�?}

interface

uses
  SysUtils,
  fafafa.core.simd.intrinsics.base;

// === AVX2 256-bit 整数运算 ===
// Load/Store
function avx2_load_si256(const Ptr: Pointer): TM256;
function avx2_loadu_si256(const Ptr: Pointer): TM256;
procedure avx2_store_si256(var Dest; const Src: TM256);
procedure avx2_storeu_si256(var Dest; const Src: TM256);

// Set/Zero
function avx2_setzero_si256: TM256;
function avx2_set1_epi32(Value: LongInt): TM256;
function avx2_set1_epi16(Value: SmallInt): TM256;
function avx2_set1_epi8(Value: ShortInt): TM256;

// Arithmetic
function avx2_add_epi32(const a, b: TM256): TM256;
function avx2_add_epi16(const a, b: TM256): TM256;
function avx2_add_epi8(const a, b: TM256): TM256;
function avx2_sub_epi32(const a, b: TM256): TM256;
function avx2_sub_epi16(const a, b: TM256): TM256;
function avx2_sub_epi8(const a, b: TM256): TM256;

// Multiply
function avx2_mullo_epi32(const a, b: TM256): TM256;
function avx2_mullo_epi16(const a, b: TM256): TM256;
function avx2_mulhi_epi16(const a, b: TM256): TM256;
function avx2_mulhi_epu16(const a, b: TM256): TM256;

// Logical
function avx2_and_si256(const a, b: TM256): TM256;
function avx2_andnot_si256(const a, b: TM256): TM256;
function avx2_or_si256(const a, b: TM256): TM256;
function avx2_xor_si256(const a, b: TM256): TM256;

// Compare
function avx2_cmpeq_epi32(const a, b: TM256): TM256;
function avx2_cmpeq_epi16(const a, b: TM256): TM256;
function avx2_cmpeq_epi8(const a, b: TM256): TM256;
function avx2_cmpgt_epi32(const a, b: TM256): TM256;
function avx2_cmpgt_epi16(const a, b: TM256): TM256;
function avx2_cmpgt_epi8(const a, b: TM256): TM256;

// Min/Max
function avx2_max_epi32(const a, b: TM256): TM256;
function avx2_max_epi16(const a, b: TM256): TM256;
function avx2_max_epi8(const a, b: TM256): TM256;
function avx2_min_epi32(const a, b: TM256): TM256;
function avx2_min_epi16(const a, b: TM256): TM256;
function avx2_min_epi8(const a, b: TM256): TM256;

// Variable Shift (AVX2 新特�?
function avx2_sllv_epi32(const a, count: TM256): TM256;
function avx2_sllv_epi64(const a, count: TM256): TM256;
function avx2_srlv_epi32(const a, count: TM256): TM256;
function avx2_srlv_epi64(const a, count: TM256): TM256;
function avx2_srav_epi32(const a, count: TM256): TM256;

// Broadcast (AVX2 新特�?
function avx2_broadcastss_ps(const a: TM128): TM256;
function avx2_broadcastsd_pd(const a: TM128): TM256;
function avx2_broadcastsi128_si256(const a: TM128): TM256;

// Gather (AVX2 新特�?
function avx2_gather_epi32(const base_addr: Pointer; const vindex: TM256; scale: Integer): TM256;
function avx2_gather_epi64(const base_addr: Pointer; const vindex: TM128; scale: Integer): TM256;
function avx2_gather_ps(const base_addr: Pointer; const vindex: TM256; scale: Integer): TM256;
function avx2_gather_pd(const base_addr: Pointer; const vindex: TM128; scale: Integer): TM256;

// Pack/Unpack
function avx2_packs_epi32(const a, b: TM256): TM256;
function avx2_packs_epi16(const a, b: TM256): TM256;
function avx2_packus_epi32(const a, b: TM256): TM256;
function avx2_packus_epi16(const a, b: TM256): TM256;
function avx2_unpackhi_epi32(const a, b: TM256): TM256;
function avx2_unpackhi_epi16(const a, b: TM256): TM256;
function avx2_unpackhi_epi8(const a, b: TM256): TM256;
function avx2_unpacklo_epi32(const a, b: TM256): TM256;
function avx2_unpacklo_epi16(const a, b: TM256): TM256;
function avx2_unpacklo_epi8(const a, b: TM256): TM256;

// Permute
function avx2_permute4x64_epi64(const a: TM256; imm8: Byte): TM256;
function avx2_permute4x64_pd(const a: TM256; imm8: Byte): TM256;
function avx2_permutevar8x32_epi32(const a, idx: TM256): TM256;
function avx2_permutevar8x32_ps(const a: TM256; const idx: TM256): TM256;

implementation

// === 基础函数实现 (Pascal 版本) ===
function avx2_load_si256(const Ptr: Pointer): TM256;
begin
  Result := PTM256(Ptr)^;
end;

function avx2_loadu_si256(const Ptr: Pointer): TM256;
begin
  Result := PTM256(Ptr)^;
end;

procedure avx2_store_si256(var Dest; const Src: TM256);
begin
  PTM256(@Dest)^ := Src;
end;

procedure avx2_storeu_si256(var Dest; const Src: TM256);
begin
  PTM256(@Dest)^ := Src;
end;

function avx2_setzero_si256: TM256;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

function avx2_set1_epi32(Value: LongInt): TM256;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.m256i_i32[i] := Value;
end;

function avx2_set1_epi16(Value: SmallInt): TM256;
var
  i: Integer;
begin
  for i := 0 to 15 do
    Result.m256i_i16[i] := Value;
end;

function avx2_set1_epi8(Value: ShortInt): TM256;
var
  i: Integer;
begin
  for i := 0 to 31 do
    Result.m256i_i8[i] := Value;
end;

function avx2_add_epi32(const a, b: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.m256i_i32[i] := a.m256i_i32[i] + b.m256i_i32[i];
end;

function avx2_add_epi16(const a, b: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 15 do
    Result.m256i_i16[i] := a.m256i_i16[i] + b.m256i_i16[i];
end;

function avx2_add_epi8(const a, b: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 31 do
    Result.m256i_i8[i] := a.m256i_i8[i] + b.m256i_i8[i];
end;

function avx2_sub_epi32(const a, b: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.m256i_i32[i] := a.m256i_i32[i] - b.m256i_i32[i];
end;

function avx2_sub_epi16(const a, b: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 15 do
    Result.m256i_i16[i] := a.m256i_i16[i] - b.m256i_i16[i];
end;

function avx2_sub_epi8(const a, b: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 31 do
    Result.m256i_i8[i] := a.m256i_i8[i] - b.m256i_i8[i];
end;

function avx2_mullo_epi32(const a, b: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.m256i_i32[i] := a.m256i_i32[i] * b.m256i_i32[i];
end;

function avx2_mullo_epi16(const a, b: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 15 do
    Result.m256i_i16[i] := a.m256i_i16[i] * b.m256i_i16[i];
end;

function avx2_mulhi_epi16(const a, b: TM256): TM256;
var
  i: Integer;
  temp: LongInt;
begin
  for i := 0 to 15 do
  begin
    temp := LongInt(a.m256i_i16[i]) * LongInt(b.m256i_i16[i]);
    Result.m256i_i16[i] := SmallInt(temp shr 16);
  end;
end;

function avx2_mulhi_epu16(const a, b: TM256): TM256;
var
  i: Integer;
  temp: Cardinal;
begin
  for i := 0 to 15 do
  begin
    temp := Cardinal(a.m256i_u16[i]) * Cardinal(b.m256i_u16[i]);
    Result.m256i_u16[i] := UInt16(temp shr 16);
  end;
end;

function avx2_and_si256(const a, b: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.m256i_u32[i] := a.m256i_u32[i] and b.m256i_u32[i];
end;

function avx2_andnot_si256(const a, b: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.m256i_u32[i] := (not a.m256i_u32[i]) and b.m256i_u32[i];
end;

function avx2_or_si256(const a, b: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.m256i_u32[i] := a.m256i_u32[i] or b.m256i_u32[i];
end;

function avx2_xor_si256(const a, b: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.m256i_u32[i] := a.m256i_u32[i] xor b.m256i_u32[i];
end;

function avx2_cmpeq_epi32(const a, b: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 7 do
    if a.m256i_i32[i] = b.m256i_i32[i] then
      Result.m256i_u32[i] := $FFFFFFFF
    else
      Result.m256i_u32[i] := $00000000;
end;

function avx2_cmpeq_epi16(const a, b: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 15 do
    if a.m256i_i16[i] = b.m256i_i16[i] then
      Result.m256i_u16[i] := $FFFF
    else
      Result.m256i_u16[i] := $0000;
end;

function avx2_cmpeq_epi8(const a, b: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 31 do
    if a.m256i_i8[i] = b.m256i_i8[i] then
      Result.m256i_u8[i] := $FF
    else
      Result.m256i_u8[i] := $00;
end;

function avx2_cmpgt_epi32(const a, b: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 7 do
    if a.m256i_i32[i] > b.m256i_i32[i] then
      Result.m256i_u32[i] := $FFFFFFFF
    else
      Result.m256i_u32[i] := $00000000;
end;

function avx2_cmpgt_epi16(const a, b: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 15 do
    if a.m256i_i16[i] > b.m256i_i16[i] then
      Result.m256i_u16[i] := $FFFF
    else
      Result.m256i_u16[i] := $0000;
end;

function avx2_cmpgt_epi8(const a, b: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 31 do
    if a.m256i_i8[i] > b.m256i_i8[i] then
      Result.m256i_u8[i] := $FF
    else
      Result.m256i_u8[i] := $00;
end;

function avx2_max_epi32(const a, b: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 7 do
    if a.m256i_i32[i] > b.m256i_i32[i] then
      Result.m256i_i32[i] := a.m256i_i32[i]
    else
      Result.m256i_i32[i] := b.m256i_i32[i];
end;

function avx2_max_epi16(const a, b: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 15 do
    if a.m256i_i16[i] > b.m256i_i16[i] then
      Result.m256i_i16[i] := a.m256i_i16[i]
    else
      Result.m256i_i16[i] := b.m256i_i16[i];
end;

function avx2_max_epi8(const a, b: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 31 do
    if a.m256i_i8[i] > b.m256i_i8[i] then
      Result.m256i_i8[i] := a.m256i_i8[i]
    else
      Result.m256i_i8[i] := b.m256i_i8[i];
end;

function avx2_min_epi32(const a, b: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 7 do
    if a.m256i_i32[i] < b.m256i_i32[i] then
      Result.m256i_i32[i] := a.m256i_i32[i]
    else
      Result.m256i_i32[i] := b.m256i_i32[i];
end;

function avx2_min_epi16(const a, b: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 15 do
    if a.m256i_i16[i] < b.m256i_i16[i] then
      Result.m256i_i16[i] := a.m256i_i16[i]
    else
      Result.m256i_i16[i] := b.m256i_i16[i];
end;

function avx2_min_epi8(const a, b: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 31 do
    if a.m256i_i8[i] < b.m256i_i8[i] then
      Result.m256i_i8[i] := a.m256i_i8[i]
    else
      Result.m256i_i8[i] := b.m256i_i8[i];
end;

// === AVX2 新特性的简化实�?===
function avx2_sllv_epi32(const a, count: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 7 do
    if count.m256i_u32[i] >= 32 then
      Result.m256i_u32[i] := 0
    else
      Result.m256i_u32[i] := a.m256i_u32[i] shl count.m256i_u32[i];
end;

function avx2_sllv_epi64(const a, count: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if count.m256i_u64[i] >= 64 then
      Result.m256i_u64[i] := 0
    else
      Result.m256i_u64[i] := a.m256i_u64[i] shl count.m256i_u64[i];
end;

function avx2_srlv_epi32(const a, count: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 7 do
    if count.m256i_u32[i] >= 32 then
      Result.m256i_u32[i] := 0
    else
      Result.m256i_u32[i] := a.m256i_u32[i] shr count.m256i_u32[i];
end;

function avx2_srlv_epi64(const a, count: TM256): TM256;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if count.m256i_u64[i] >= 64 then
      Result.m256i_u64[i] := 0
    else
      Result.m256i_u64[i] := a.m256i_u64[i] shr count.m256i_u64[i];
end;

function avx2_srav_epi32(const a, count: TM256): TM256;
var
  i: Integer;
  shift_count: Cardinal;
  value: LongInt;
begin
  for i := 0 to 7 do
  begin
    shift_count := count.m256i_u32[i];
    if shift_count >= 32 then
      shift_count := 31;
    
    value := a.m256i_i32[i];
    if shift_count = 0 then
      Result.m256i_i32[i] := value
    else if value >= 0 then
      Result.m256i_i32[i] := value shr shift_count
    else
      Result.m256i_i32[i] := (value shr shift_count) or ((-1) shl (32 - shift_count));
  end;
end;

function avx2_broadcastss_ps(const a: TM128): TM256;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.m256_f32[i] := a.m128_f32[0];
end;

function avx2_broadcastsd_pd(const a: TM128): TM256;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m256_f64[i] := a.m128d_f64[0];
end;

function avx2_broadcastsi128_si256(const a: TM128): TM256;
begin
  Result.m256_m128[0] := a;
  Result.m256_m128[1] := a;
end;

// 其他复杂函数的占位符实现
// 说明：以下 AVX2 intrinsics 目前尚未提供正确实现。为了避免被误用导致
// 静默错误结果，这些函数会在调用时抛出 ENotImplemented 异常。

function avx2_gather_epi32(const base_addr: Pointer; const vindex: TM256; scale: Integer): TM256;
begin
  raise ENotImplemented.Create('avx2_gather_epi32 is not implemented yet');
end;

function avx2_gather_epi64(const base_addr: Pointer; const vindex: TM128; scale: Integer): TM256;
begin
  raise ENotImplemented.Create('avx2_gather_epi64 is not implemented yet');
end;

function avx2_gather_ps(const base_addr: Pointer; const vindex: TM256; scale: Integer): TM256;
begin
  raise ENotImplemented.Create('avx2_gather_ps is not implemented yet');
end;

function avx2_gather_pd(const base_addr: Pointer; const vindex: TM128; scale: Integer): TM256;
begin
  raise ENotImplemented.Create('avx2_gather_pd is not implemented yet');
end;

function avx2_packs_epi32(const a, b: TM256): TM256;
begin
  raise ENotImplemented.Create('avx2_packs_epi32 is not implemented yet');
end;

function avx2_packs_epi16(const a, b: TM256): TM256;
begin
  raise ENotImplemented.Create('avx2_packs_epi16 is not implemented yet');
end;

function avx2_packus_epi32(const a, b: TM256): TM256;
begin
  raise ENotImplemented.Create('avx2_packus_epi32 is not implemented yet');
end;

function avx2_packus_epi16(const a, b: TM256): TM256;
begin
  raise ENotImplemented.Create('avx2_packus_epi16 is not implemented yet');
end;

function avx2_unpackhi_epi32(const a, b: TM256): TM256;
begin
  raise ENotImplemented.Create('avx2_unpackhi_epi32 is not implemented yet');
end;

function avx2_unpackhi_epi16(const a, b: TM256): TM256;
begin
  raise ENotImplemented.Create('avx2_unpackhi_epi16 is not implemented yet');
end;

function avx2_unpackhi_epi8(const a, b: TM256): TM256;
begin
  raise ENotImplemented.Create('avx2_unpackhi_epi8 is not implemented yet');
end;

function avx2_unpacklo_epi32(const a, b: TM256): TM256;
begin
  raise ENotImplemented.Create('avx2_unpacklo_epi32 is not implemented yet');
end;

function avx2_unpacklo_epi16(const a, b: TM256): TM256;
begin
  raise ENotImplemented.Create('avx2_unpacklo_epi16 is not implemented yet');
end;

function avx2_unpacklo_epi8(const a, b: TM256): TM256;
begin
  raise ENotImplemented.Create('avx2_unpacklo_epi8 is not implemented yet');
end;

function avx2_permute4x64_epi64(const a: TM256; imm8: Byte): TM256;
begin
  raise ENotImplemented.Create('avx2_permute4x64_epi64 is not implemented yet');
end;

function avx2_permute4x64_pd(const a: TM256; imm8: Byte): TM256;
begin
  raise ENotImplemented.Create('avx2_permute4x64_pd is not implemented yet');
end;

function avx2_permutevar8x32_epi32(const a, idx: TM256): TM256;
begin
  raise ENotImplemented.Create('avx2_permutevar8x32_epi32 is not implemented yet');
end;

function avx2_permutevar8x32_ps(const a: TM256; const idx: TM256): TM256;
begin
  raise ENotImplemented.Create('avx2_permutevar8x32_ps is not implemented yet');
end;

end.


