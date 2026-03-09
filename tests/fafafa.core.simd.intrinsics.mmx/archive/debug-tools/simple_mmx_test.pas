program simple_mmx_test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.intrinsics.mmx;

var
  a, b, result: TM64;

begin
  WriteLn('Simple MMX Test');
  WriteLn('===============');
  
  // 测试基本的 set 和 add 操作
  a := mmx_set1_pi32(100);
  b := mmx_set1_pi32(200);
  result := mmx_paddd(a, b);
  
  WriteLn('Test mmx_set1_pi32 and mmx_paddd:');
  WriteLn('a = mmx_set1_pi32(100)');
  WriteLn('b = mmx_set1_pi32(200)');
  WriteLn('result = mmx_paddd(a, b)');
  WriteLn('result.mm_i32[0] = ', result.mm_i32[0]);
  WriteLn('result.mm_i32[1] = ', result.mm_i32[1]);
  
  if (result.mm_i32[0] = 300) and (result.mm_i32[1] = 300) then
    WriteLn('✓ Test PASSED')
  else
    WriteLn('✗ Test FAILED');
    
  WriteLn('');
  WriteLn('Simple MMX test completed.');
end.
