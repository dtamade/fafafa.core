unit fafafa.core.simd.intrinsics.sse41;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  === fafafa.core.simd.intrinsics.sse41 ===
  SSE4.1 (Streaming SIMD Extensions 4.1) 指令集支�?  
  SSE4.1 �?Intel �?2006 年引入的 SIMD 指令集扩�?  主要增加了更多的整数运算、混合操作和字符串处理指�?  
  特性：
  - 扩展的整�?min/max 操作
  - 点积指令 (DPPS, DPPD)
  - 混合操作 (BLENDPS, BLENDPD, BLENDVPS, BLENDVPD)
  - 舍入指令 (ROUNDPS, ROUNDPD, ROUNDSS, ROUNDSD)
  - 插入/提取指令增强
  - 零扩展加�?  - 测试指令 (PTEST)
  
  兼容性：大部分现�?x86/x64 处理器都支持
}

interface

uses
  fafafa.core.simd.intrinsics.base;

// === SSE4.1 扩展�?Min/Max 操作 ===
function sse41_max_epi8(const a, b: TM128): TM128;   // 有符�?位最大�?function sse41_max_epi32(const a, b: TM128): TM128;  // 有符�?2位最大�?function sse41_max_epu16(const a, b: TM128): TM128;  // 无符�?6位最大�?function sse41_max_epu32(const a, b: TM128): TM128;  // 无符�?2位最大�?function sse41_min_epi8(const a, b: TM128): TM128;   // 有符�?位最小�?function sse41_min_epi32(const a, b: TM128): TM128;  // 有符�?2位最小�?function sse41_min_epu16(const a, b: TM128): TM128;  // 无符�?6位最小�?function sse41_min_epu32(const a, b: TM128): TM128;  // 无符�?2位最小�?
// === SSE4.1 点积指令 ===
function sse41_dp_ps(const a, b: TM128; imm8: Byte): TM128;  // 单精度点�?function sse41_dp_pd(const a, b: TM128; imm8: Byte): TM128;  // 双精度点�?
// === SSE4.1 混合操作 ===
function sse41_blend_ps(const a, b: TM128; imm8: Byte): TM128;     // 单精度混�?function sse41_blend_pd(const a, b: TM128; imm8: Byte): TM128;     // 双精度混�?function sse41_blendv_ps(const a, b, mask: TM128): TM128;          // 变量单精度混�?function sse41_blendv_pd(const a, b, mask: TM128): TM128;          // 变量双精度混�?function sse41_blendv_epi8(const a, b, mask: TM128): TM128;        // 变量8位整数混�?
// === SSE4.1 舍入指令 ===
function sse41_round_ps(const a: TM128; rounding: Byte): TM128;    // 单精度舍�?function sse41_round_pd(const a: TM128; rounding: Byte): TM128;    // 双精度舍�?function sse41_round_ss(const a, b: TM128; rounding: Byte): TM128; // 标量单精度舍�?function sse41_round_sd(const a, b: TM128; rounding: Byte): TM128; // 标量双精度舍�?
// === SSE4.1 插入/提取指令增强 ===
function sse41_insert_ps(const a, b: TM128; imm8: Byte): TM128;    // 插入单精�?function sse41_extract_ps(const a: TM128; imm8: Byte): Cardinal;   // 提取单精�?function sse41_insert_epi8(const a: TM128; Value: Integer; imm8: Byte): TM128;  // 插入8位整�?function sse41_insert_epi32(const a: TM128; Value: Integer; imm8: Byte): TM128; // 插入32位整�?function sse41_insert_epi64(const a: TM128; Value: Int64; imm8: Byte): TM128;   // 插入64位整�?function sse41_extract_epi8(const a: TM128; imm8: Byte): Integer;  // 提取8位整�?function sse41_extract_epi32(const a: TM128; imm8: Byte): Integer; // 提取32位整�?function sse41_extract_epi64(const a: TM128; imm8: Byte): Int64;   // 提取64位整�?
// === SSE4.1 零扩展加�?===
function sse41_loadl_epi64(const Ptr: Pointer): TM128;             // 加载64位并零扩�?
// === SSE4.1 转换指令 ===
function sse41_cvtepi8_epi16(const a: TM128): TM128;   // 8位到16位符号扩�?function sse41_cvtepi8_epi32(const a: TM128): TM128;   // 8位到32位符号扩�?function sse41_cvtepi8_epi64(const a: TM128): TM128;   // 8位到64位符号扩�?function sse41_cvtepi16_epi32(const a: TM128): TM128;  // 16位到32位符号扩�?function sse41_cvtepi16_epi64(const a: TM128): TM128;  // 16位到64位符号扩�?function sse41_cvtepi32_epi64(const a: TM128): TM128;  // 32位到64位符号扩�?
function sse41_cvtepu8_epi16(const a: TM128): TM128;   // 8位到16位零扩展
function sse41_cvtepu8_epi32(const a: TM128): TM128;   // 8位到32位零扩展
function sse41_cvtepu8_epi64(const a: TM128): TM128;   // 8位到64位零扩展
function sse41_cvtepu16_epi32(const a: TM128): TM128;  // 16位到32位零扩展
function sse41_cvtepu16_epi64(const a: TM128): TM128;  // 16位到64位零扩展
function sse41_cvtepu32_epi64(const a: TM128): TM128;  // 32位到64位零扩展

// === SSE4.1 测试指令 ===
function sse41_test_all_zeros(const a, mask: TM128): Boolean;      // 测试全零
function sse41_test_all_ones(const a: TM128): Boolean;             // 测试全一
function sse41_test_mix_ones_zeros(const a, mask: TM128): Boolean; // 测试混合

// === SSE4.1 其他指令 ===
function sse41_mullo_epi32(const a, b: TM128): TM128;              // 32位乘法低�?function sse41_mul_epi32(const a, b: TM128): TM128;                // 32位乘法到64�?function sse41_packus_epi32(const a, b: TM128): TM128;             // 32位打包到16位无符号饱和

implementation

uses
  Math;  // RTL Math 单元 (Round, Int)

// === Min/Max 操作实现 ===
function sse41_max_epi8(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 15 do
    if a.m128i_i8[i] > b.m128i_i8[i] then
      Result.m128i_i8[i] := a.m128i_i8[i]
    else
      Result.m128i_i8[i] := b.m128i_i8[i];
end;

function sse41_max_epi32(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128i_i32[i] > b.m128i_i32[i] then
      Result.m128i_i32[i] := a.m128i_i32[i]
    else
      Result.m128i_i32[i] := b.m128i_i32[i];
end;

function sse41_max_epu16(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 7 do
    if a.m128i_u16[i] > b.m128i_u16[i] then
      Result.m128i_u16[i] := a.m128i_u16[i]
    else
      Result.m128i_u16[i] := b.m128i_u16[i];
end;

function sse41_max_epu32(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128i_u32[i] > b.m128i_u32[i] then
      Result.m128i_u32[i] := a.m128i_u32[i]
    else
      Result.m128i_u32[i] := b.m128i_u32[i];
end;

function sse41_min_epi8(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 15 do
    if a.m128i_i8[i] < b.m128i_i8[i] then
      Result.m128i_i8[i] := a.m128i_i8[i]
    else
      Result.m128i_i8[i] := b.m128i_i8[i];
end;

function sse41_min_epi32(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128i_i32[i] < b.m128i_i32[i] then
      Result.m128i_i32[i] := a.m128i_i32[i]
    else
      Result.m128i_i32[i] := b.m128i_i32[i];
end;

function sse41_min_epu16(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 7 do
    if a.m128i_u16[i] < b.m128i_u16[i] then
      Result.m128i_u16[i] := a.m128i_u16[i]
    else
      Result.m128i_u16[i] := b.m128i_u16[i];
end;

function sse41_min_epu32(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if a.m128i_u32[i] < b.m128i_u32[i] then
      Result.m128i_u32[i] := a.m128i_u32[i]
    else
      Result.m128i_u32[i] := b.m128i_u32[i];
end;

// === 点积指令实现 ===
function sse41_dp_ps(const a, b: TM128; imm8: Byte): TM128;
var
  i: Integer;
  sum: Single;
begin
  // 简化的点积实现
  sum := 0;
  for i := 0 to 3 do
    if (imm8 and (1 shl (i + 4))) <> 0 then
      sum := sum + a.m128_f32[i] * b.m128_f32[i];
  
  FillChar(Result, SizeOf(Result), 0);
  for i := 0 to 3 do
    if (imm8 and (1 shl i)) <> 0 then
      Result.m128_f32[i] := sum;
end;

function sse41_dp_pd(const a, b: TM128; imm8: Byte): TM128;
var
  i: Integer;
  sum: Double;
begin
  // 简化的双精度点积实�?  sum := 0;
  for i := 0 to 1 do
    if (imm8 and (1 shl (i + 4))) <> 0 then
      sum := sum + a.m128d_f64[i] * b.m128d_f64[i];
  
  FillChar(Result, SizeOf(Result), 0);
  for i := 0 to 1 do
    if (imm8 and (1 shl i)) <> 0 then
      Result.m128d_f64[i] := sum;
end;

// === 混合操作实现 ===
function sse41_blend_ps(const a, b: TM128; imm8: Byte): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if (imm8 and (1 shl i)) <> 0 then
      Result.m128_f32[i] := b.m128_f32[i]
    else
      Result.m128_f32[i] := a.m128_f32[i];
end;

function sse41_blend_pd(const a, b: TM128; imm8: Byte): TM128;
var
  i: Integer;
begin
  for i := 0 to 1 do
    if (imm8 and (1 shl i)) <> 0 then
      Result.m128d_f64[i] := b.m128d_f64[i]
    else
      Result.m128d_f64[i] := a.m128d_f64[i];
end;

function sse41_blendv_ps(const a, b, mask: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    if (mask.m128i_u32[i] and $80000000) <> 0 then
      Result.m128_f32[i] := b.m128_f32[i]
    else
      Result.m128_f32[i] := a.m128_f32[i];
end;

function sse41_blendv_pd(const a, b, mask: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 1 do
    if (mask.m128i_u64[i] and $8000000000000000) <> 0 then
      Result.m128d_f64[i] := b.m128d_f64[i]
    else
      Result.m128d_f64[i] := a.m128d_f64[i];
end;

function sse41_blendv_epi8(const a, b, mask: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 15 do
    if (mask.m128i_u8[i] and $80) <> 0 then
      Result.m128i_u8[i] := b.m128i_u8[i]
    else
      Result.m128i_u8[i] := a.m128i_u8[i];
end;

// === 舍入指令实现 ===
function sse41_round_ps(const a: TM128; rounding: Byte): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
  begin
    case rounding and 7 of
      0: Result.m128_f32[i] := Round(a.m128_f32[i]);      // 最近偶�?      1: Result.m128_f32[i] := Int(a.m128_f32[i] - 0.5);  // 向下
      2: Result.m128_f32[i] := Int(a.m128_f32[i] + 0.5);  // 向上
      3: Result.m128_f32[i] := Int(a.m128_f32[i]);        // 向零
      else Result.m128_f32[i] := a.m128_f32[i];
    end;
  end;
end;

function sse41_round_pd(const a: TM128; rounding: Byte): TM128;
var
  i: Integer;
begin
  for i := 0 to 1 do
  begin
    case rounding and 7 of
      0: Result.m128d_f64[i] := Round(a.m128d_f64[i]);
      1: Result.m128d_f64[i] := Int(a.m128d_f64[i] - 0.5);
      2: Result.m128d_f64[i] := Int(a.m128d_f64[i] + 0.5);
      3: Result.m128d_f64[i] := Int(a.m128d_f64[i]);
      else Result.m128d_f64[i] := a.m128d_f64[i];
    end;
  end;
end;

function sse41_round_ss(const a, b: TM128; rounding: Byte): TM128;
begin
  Result := a;
  case rounding and 7 of
    0: Result.m128_f32[0] := Round(b.m128_f32[0]);
    1: Result.m128_f32[0] := Int(b.m128_f32[0] - 0.5);
    2: Result.m128_f32[0] := Int(b.m128_f32[0] + 0.5);
    3: Result.m128_f32[0] := Int(b.m128_f32[0]);
    else Result.m128_f32[0] := b.m128_f32[0];
  end;
end;

function sse41_round_sd(const a, b: TM128; rounding: Byte): TM128;
begin
  Result := a;
  case rounding and 7 of
    0: Result.m128d_f64[0] := Round(b.m128d_f64[0]);
    1: Result.m128d_f64[0] := Int(b.m128d_f64[0] - 0.5);
    2: Result.m128d_f64[0] := Int(b.m128d_f64[0] + 0.5);
    3: Result.m128d_f64[0] := Int(b.m128d_f64[0]);
    else Result.m128d_f64[0] := b.m128d_f64[0];
  end;
end;

// === 其他函数的简化实�?===
function sse41_insert_ps(const a, b: TM128; imm8: Byte): TM128;
begin
  Result := a;
  // 简化实�?  Result.m128_f32[imm8 and 3] := b.m128_f32[(imm8 shr 6) and 3];
end;

function sse41_extract_ps(const a: TM128; imm8: Byte): Cardinal;
begin
  Result := a.m128i_u32[imm8 and 3];
end;

function sse41_insert_epi8(const a: TM128; Value: Integer; imm8: Byte): TM128;
begin
  Result := a;
  Result.m128i_i8[imm8 and 15] := ShortInt(Value);
end;

function sse41_insert_epi32(const a: TM128; Value: Integer; imm8: Byte): TM128;
begin
  Result := a;
  Result.m128i_i32[imm8 and 3] := Value;
end;

function sse41_insert_epi64(const a: TM128; Value: Int64; imm8: Byte): TM128;
begin
  Result := a;
  Result.m128i_i64[imm8 and 1] := Value;
end;

function sse41_extract_epi8(const a: TM128; imm8: Byte): Integer;
begin
  Result := a.m128i_u8[imm8 and 15];
end;

function sse41_extract_epi32(const a: TM128; imm8: Byte): Integer;
begin
  Result := a.m128i_i32[imm8 and 3];
end;

function sse41_extract_epi64(const a: TM128; imm8: Byte): Int64;
begin
  Result := a.m128i_i64[imm8 and 1];
end;

function sse41_loadl_epi64(const Ptr: Pointer): TM128;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.m128i_i64[0] := PInt64(Ptr)^;
end;

// === 转换指令的简化实�?===
function sse41_cvtepi8_epi16(const a: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.m128i_i16[i] := a.m128i_i8[i];
end;

function sse41_cvtepi8_epi32(const a: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_i32[i] := a.m128i_i8[i];
end;

function sse41_cvtepi8_epi64(const a: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 1 do
    Result.m128i_i64[i] := a.m128i_i8[i];
end;

function sse41_cvtepi16_epi32(const a: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_i32[i] := a.m128i_i16[i];
end;

function sse41_cvtepi16_epi64(const a: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 1 do
    Result.m128i_i64[i] := a.m128i_i16[i];
end;

function sse41_cvtepi32_epi64(const a: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 1 do
    Result.m128i_i64[i] := a.m128i_i32[i];
end;

function sse41_cvtepu8_epi16(const a: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 7 do
    Result.m128i_u16[i] := a.m128i_u8[i];
end;

function sse41_cvtepu8_epi32(const a: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_u32[i] := a.m128i_u8[i];
end;

function sse41_cvtepu8_epi64(const a: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 1 do
    Result.m128i_u64[i] := a.m128i_u8[i];
end;

function sse41_cvtepu16_epi32(const a: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_u32[i] := a.m128i_u16[i];
end;

function sse41_cvtepu16_epi64(const a: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 1 do
    Result.m128i_u64[i] := a.m128i_u16[i];
end;

function sse41_cvtepu32_epi64(const a: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 1 do
    Result.m128i_u64[i] := a.m128i_u32[i];
end;

// === 测试指令实现 ===
function sse41_test_all_zeros(const a, mask: TM128): Boolean;
var
  i: Integer;
begin
  Result := True;
  for i := 0 to 3 do
    if (a.m128i_u32[i] and mask.m128i_u32[i]) <> 0 then
    begin
      Result := False;
      Exit;
    end;
end;

function sse41_test_all_ones(const a: TM128): Boolean;
var
  i: Integer;
begin
  Result := True;
  for i := 0 to 3 do
    if a.m128i_u32[i] <> $FFFFFFFF then
    begin
      Result := False;
      Exit;
    end;
end;

function sse41_test_mix_ones_zeros(const a, mask: TM128): Boolean;
var
  i: Integer;
  has_zero, has_one: Boolean;
begin
  has_zero := False;
  has_one := False;
  
  for i := 0 to 3 do
  begin
    if (a.m128i_u32[i] and mask.m128i_u32[i]) = 0 then
      has_zero := True
    else
      has_one := True;
  end;
  
  Result := has_zero and has_one;
end;

// === 其他指令实现 ===
function sse41_mullo_epi32(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 3 do
    Result.m128i_i32[i] := a.m128i_i32[i] * b.m128i_i32[i];
end;

function sse41_mul_epi32(const a, b: TM128): TM128;
var
  i: Integer;
begin
  for i := 0 to 1 do
    Result.m128i_i64[i] := Int64(a.m128i_i32[i * 2]) * Int64(b.m128i_i32[i * 2]);
end;

function sse41_packus_epi32(const a, b: TM128): TM128;
var
  i: Integer;
  temp: LongInt;
begin
  for i := 0 to 3 do
  begin
    temp := a.m128i_i32[i];
    if temp < 0 then
      Result.m128i_u16[i] := 0
    else if temp > 65535 then
      Result.m128i_u16[i] := 65535
    else
      Result.m128i_u16[i] := UInt16(temp);
      
    temp := b.m128i_i32[i];
    if temp < 0 then
      Result.m128i_u16[i + 4] := 0
    else if temp > 65535 then
      Result.m128i_u16[i + 4] := 65535
    else
      Result.m128i_u16[i + 4] := UInt16(temp);
  end;
end;

end.


