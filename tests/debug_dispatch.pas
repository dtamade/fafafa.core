program debug_dispatch;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.simd.v2.types,
  fafafa.core.simd.v2.detect,
  fafafa.core.simd.v2.dispatch;

var
  Caps: TSimdISASet;
  Context: TSimdContext;
  TestA, TestB, TestC: TF32x4;
  
begin
  WriteLn('=== 调试派发系统 ===');
  
  // 检测硬件能力
  WriteLn('检测硬件能力...');
  Caps := simd_detect_capabilities;
  WriteLn('检测到的能力：');
  if isaScalar in Caps then WriteLn('  - Scalar');
  if isaSSE2 in Caps then WriteLn('  - SSE2');
  if isaAVX2 in Caps then WriteLn('  - AVX2');
  
  // 获取上下文
  Context := simd_get_context;
  WriteLn('当前活动 ISA：', Ord(Context.ActiveISA));
  WriteLn('最佳配置：', simd_get_best_profile);
  
  // 测试派发验证
  WriteLn('测试派发验证...');
  try
    TestA := simd_dispatch_f32x4_splat(2.0);
    WriteLn('TestA splat(2.0) = [', TestA.Extract(0):0:1, ', ', TestA.Extract(1):0:1, ', ', TestA.Extract(2):0:1, ', ', TestA.Extract(3):0:1, ']');
    
    TestB := simd_dispatch_f32x4_splat(3.0);
    WriteLn('TestB splat(3.0) = [', TestB.Extract(0):0:1, ', ', TestB.Extract(1):0:1, ', ', TestB.Extract(2):0:1, ', ', TestB.Extract(3):0:1, ']');
    
    TestC := simd_dispatch_f32x4_add(TestA, TestB);
    WriteLn('TestC = TestA + TestB = [', TestC.Extract(0):0:1, ', ', TestC.Extract(1):0:1, ', ', TestC.Extract(2):0:1, ', ', TestC.Extract(3):0:1, ']');
    
    if Abs(TestC.Extract(0) - 5.0) < 0.001 then
      WriteLn('✅ 派发验证通过！')
    else
      WriteLn('❌ 派发验证失败！');
      
  except
    on E: Exception do
      WriteLn('❌ 派发验证异常：', E.Message);
  end;
  
  // 手动验证
  WriteLn('手动验证派发...');
  if simd_validate_dispatch then
    WriteLn('✅ 手动验证通过！')
  else
    WriteLn('❌ 手动验证失败！');
    
  WriteLn('调试完成。');
end.
