program test_sse2_functions;

{$mode delphi}
{$asmmode intel}

uses
  fafafa.core.simd.intrinsics.base,
  fafafa.core.simd.intrinsics.x86.sse2_fixed;

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

begin
  WriteLn('=== SSE2 函数测试 ===');
  
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
  
  // 测试 shuffle
  WriteLn('11. 测试 simd_shuffle_epi32');
  result := simd_shuffle_epi32(a, 0);
  PrintM128('shuffle(a, 0)', result);
  
  // 测试 max/min
  WriteLn('12. 测试 simd_max_epi16');
  result := simd_max_epi16(a, b);
  PrintM128('max(a, b)', result);
  
  WriteLn('13. 测试 simd_min_epi16');
  result := simd_min_epi16(a, b);
  PrintM128('min(a, b)', result);
  
  WriteLn('=== 测试完成 ===');
end.
