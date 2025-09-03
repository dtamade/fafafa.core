program test_original_mmx;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.intrinsics.mmx in '../src/fafafa.core.simd.intrinsics.mmx.pas';

var
  a, b, result: TM64;

begin
  WriteLn('测试原始 MMX 模块');
  WriteLn('==================');
  
  // 测试基本的 set 函数
  a := mmx_set1_pi32(42);
  WriteLn('mmx_set1_pi32(42): [', a.mm_i32[0], ', ', a.mm_i32[1], ']');
  
  b := mmx_set_pi32(100, 200);
  WriteLn('mmx_set_pi32(100, 200): [', b.mm_i32[0], ', ', b.mm_i32[1], ']');
  
  // 测试加法
  result := mmx_paddd(a, b);
  WriteLn('paddd 结果: [', result.mm_i32[0], ', ', result.mm_i32[1], ']');
  
  // 调用 EMMS
  mmx_emms;
  
  WriteLn('测试完成！');
  ReadLn;
end.
