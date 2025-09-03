program simple_mmx_test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils;

// 直接包含 MMX 单元的内容，避免路径问题
{$I ../src/fafafa.core.simd.intrinsics.mmx.pas}

var
  a, b, result: TM64;

begin
  WriteLn('简单 MMX 测试');
  
  // 测试基本的 set 函数
  a := mmx_set1_pi32(42);
  WriteLn('mmx_set1_pi32(42): [', a.mm_i32[0], ', ', a.mm_i32[1], ']');
  
  b := mmx_set1_pi32(8);
  WriteLn('mmx_set1_pi32(8): [', b.mm_i32[0], ', ', b.mm_i32[1], ']');
  
  // 测试加法
  result := mmx_paddd(a, b);
  WriteLn('paddd 结果: [', result.mm_i32[0], ', ', result.mm_i32[1], ']');
  
  // 调用 EMMS
  mmx_emms;
  
  WriteLn('测试完成！');
  ReadLn;
end.
