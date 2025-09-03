program debug_test;

{$mode delphi}
{$asmmode intel}

uses
  fafafa.core.simd.intrinsics.base,
  fafafa.core.simd.intrinsics.x86.sse2_fixed;

var
  result: TM128;
  i: Integer;

begin
  WriteLn('=== 调试测试 ===');
  
  // 测试 setzero
  result := simd_setzero_si128;
  Write('setzero: ');
  for i := 0 to 3 do
    Write(result.m128i_i32[i], ' ');
  WriteLn;
  
  // 手动设置一个值来测试
  result.m128i_i32[0] := 123;
  result.m128i_i32[1] := 456;
  result.m128i_i32[2] := 789;
  result.m128i_i32[3] := 999;
  
  Write('manual set: ');
  for i := 0 to 3 do
    Write(result.m128i_i32[i], ' ');
  WriteLn;
  
  // 测试 set1_epi32
  result := simd_set1_epi32(42);
  Write('set1_epi32(42): ');
  for i := 0 to 3 do
    Write(result.m128i_i32[i], ' ');
  WriteLn;
  
  WriteLn('=== 调试完成 ===');
end.
