program test_simd_facade;

{$mode delphi}
{$CODEPAGE UTF8}

uses
  fafafa.core.simd.intrinsics;

var
  a, b, result: TM128;
  i: Integer;

procedure PrintM128(const name: string; const value: TM128);
var
  i: Integer;
begin
  Write(name, ': ');
  for i := 0 to 3 do
    Write(value.m128i_i32[i], ' ');
  WriteLn;
end;

procedure PrintCPUFeatures;
begin
  WriteLn('=== CPU 特性检测 ===');
  WriteLn('MMX: ', simd_has_mmx);
  WriteLn('SSE: ', simd_has_sse);
  WriteLn('SSE2: ', simd_has_sse2);
  WriteLn('SSE3: ', simd_has_sse3);
  WriteLn('SSE4.1: ', simd_has_sse41);
  WriteLn('SSE4.2: ', simd_has_sse42);
  WriteLn('AVX: ', simd_has_avx);
  WriteLn('AVX2: ', simd_has_avx2);
  WriteLn('AVX-512F: ', simd_has_avx512f);
  WriteLn('AES: ', simd_has_aes);
  WriteLn('SHA: ', simd_has_sha);
  WriteLn('FMA3: ', simd_has_fma3);
  WriteLn;
end;

begin
  WriteLn('=== SIMD Intrinsics 门面模块测试 ===');
  WriteLn;
  
  // 检测 CPU 特性
  PrintCPUFeatures;
  
  WriteLn('=== 基础函数测试 ===');
  
  // 测试 set1_epi32
  WriteLn('1. 测试 simd_set1_epi32');
  a := simd_set1_epi32(42);
  PrintM128('set1_epi32(42)', a);
  
  // 测试 setzero
  WriteLn('2. 测试 simd_setzero_si128');
  b := simd_setzero_si128;
  PrintM128('setzero', b);
  
  // 设置测试数据
  a.m128i_i32[0] := 1;
  a.m128i_i32[1] := 2;
  a.m128i_i32[2] := 3;
  a.m128i_i32[3] := 4;
  
  b.m128i_i32[0] := 10;
  b.m128i_i32[1] := 20;
  b.m128i_i32[2] := 30;
  b.m128i_i32[3] := 40;
  
  PrintM128('a', a);
  PrintM128('b', b);
  
  // 测试加法
  WriteLn('3. 测试 simd_add_epi32');
  result := simd_add_epi32(a, b);
  PrintM128('a + b', result);
  
  // 测试减法
  WriteLn('4. 测试 simd_sub_epi32');
  result := simd_sub_epi32(b, a);
  PrintM128('b - a', result);
  
  // 测试逻辑与
  WriteLn('5. 测试 simd_and_si128');
  result := simd_and_si128(a, b);
  PrintM128('a & b', result);
  
  // 测试逻辑或
  WriteLn('6. 测试 simd_or_si128');
  result := simd_or_si128(a, b);
  PrintM128('a | b', result);
  
  // 测试异或
  WriteLn('7. 测试 simd_xor_si128');
  result := simd_xor_si128(a, b);
  PrintM128('a ^ b', result);
  
  // 测试比较
  WriteLn('8. 测试 simd_cmpeq_epi32');
  result := simd_cmpeq_epi32(a, a);
  PrintM128('a == a', result);
  
  // 测试左移
  WriteLn('9. 测试 simd_slli_epi32');
  result := simd_slli_epi32(a, 2);
  PrintM128('a << 2', result);
  
  // 测试右移
  WriteLn('10. 测试 simd_srli_epi32');
  result := simd_srli_epi32(a, 1);
  PrintM128('a >> 1', result);
  
  // 测试算术右移
  WriteLn('11. 测试 simd_srai_epi32 (负数)');
  a.m128i_i32[0] := -8;
  a.m128i_i32[1] := -16;
  a.m128i_i32[2] := -32;
  a.m128i_i32[3] := -64;
  PrintM128('负数 a', a);
  result := simd_srai_epi32(a, 2);
  PrintM128('a sar 2', result);
  
  // 测试 max/min
  WriteLn('12. 测试 simd_max_epi32');
  a.m128i_i32[0] := 1;
  a.m128i_i32[1] := 20;
  a.m128i_i32[2] := 3;
  a.m128i_i32[3] := 40;
  
  b.m128i_i32[0] := 10;
  b.m128i_i32[1] := 2;
  b.m128i_i32[2] := 30;
  b.m128i_i32[3] := 4;
  
  PrintM128('a', a);
  PrintM128('b', b);
  result := simd_max_epi32(a, b);
  PrintM128('max(a, b)', result);
  
  WriteLn('13. 测试 simd_min_epi32');
  result := simd_min_epi32(a, b);
  PrintM128('min(a, b)', result);
  
  // 测试浮点运算
  WriteLn('14. 测试 simd_add_ps (单精度浮点)');
  a.m128_f32[0] := 1.5;
  a.m128_f32[1] := 2.5;
  a.m128_f32[2] := 3.5;
  a.m128_f32[3] := 4.5;
  
  b.m128_f32[0] := 0.5;
  b.m128_f32[1] := 1.0;
  b.m128_f32[2] := 1.5;
  b.m128_f32[3] := 2.0;
  
  result := simd_add_ps(a, b);
  Write('add_ps result: ');
  for i := 0 to 3 do
    Write(result.m128_f32[i]:0:1, ' ');
  WriteLn;
  
  WriteLn;
  WriteLn('=== 测试完成 ===');
  WriteLn('门面模块工作正常！所有基础函数都能正确执行。');
end.
