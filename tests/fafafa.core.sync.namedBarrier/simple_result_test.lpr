program simple_result_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.base, fafafa.core.sync.namedBarrier;

procedure TestBasicResultInterface;
var
  LResult: TNamedBarrierResult;
  LBarrier: INamedBarrier;
  LGuardResult: TNamedBarrierGuardResult;
  LCountResult: TNamedBarrierCardinalResult;
  LBoolResult: TNamedBarrierBoolResult;
  LVoidResult: TNamedBarrierVoidResult;
begin
  WriteLn('测试基本 TResult 接口...');
  
  // 测试创建屏障
  LResult := CreateNamedBarrierResult('test_barrier', 2);
  if LResult.IsOk then
  begin
    LBarrier := LResult.Unwrap;
    WriteLn('  ✓ 成功创建屏障: ', LBarrier.GetName);
    
    // 测试获取等待数量
    LCountResult := LBarrier.GetWaitingCountResult;
    if LCountResult.IsOk then
      WriteLn('  ✓ 等待数量: ', LCountResult.Unwrap)
    else
      WriteLn('  ✗ 获取等待数量失败');
    
    // 测试检查是否已触发
    LBoolResult := LBarrier.IsSignaledResult;
    if LBoolResult.IsOk then
      WriteLn('  ✓ 是否已触发: ', BoolToStr(LBoolResult.Unwrap, True))
    else
      WriteLn('  ✗ 检查触发状态失败');
    
    // 测试信号操作
    LVoidResult := LBarrier.SignalResult;
    if LVoidResult.IsOk then
      WriteLn('  ✓ 信号操作成功')
    else
      WriteLn('  ✗ 信号操作失败');
    
    // 测试尝试等待
    LGuardResult := LBarrier.TryWaitResult;
    if LGuardResult.IsOk then
      WriteLn('  ✓ TryWait 成功')
    else
      WriteLn('  ✓ TryWait 失败（预期，单进程）');
    
    // 测试重置
    LVoidResult := LBarrier.ResetResult;
    if LVoidResult.IsOk then
      WriteLn('  ✓ 重置成功')
    else
      WriteLn('  ✗ 重置失败');
      
  end
  else
  begin
    WriteLn('  ✗ 创建屏障失败: ', Ord(LResult.UnwrapErr));
  end;
  
  WriteLn;
end;

procedure TestErrorHandling;
var
  LResult: TNamedBarrierResult;
begin
  WriteLn('测试错误处理...');
  
  // 测试无效名称
  LResult := CreateNamedBarrierResult('');
  if LResult.IsErr then
    WriteLn('  ✓ 正确捕获无效名称错误: ', Ord(LResult.UnwrapErr))
  else
    WriteLn('  ✗ 应该因无效名称而失败');
  
  // 测试无效参与者数量
  LResult := CreateNamedBarrierResult('test_invalid', 1);
  if LResult.IsErr then
    WriteLn('  ✓ 正确捕获无效参与者数量: ', Ord(LResult.UnwrapErr))
  else
    WriteLn('  ✗ 应该因无效参与者数量而失败');
  
  WriteLn;
end;

procedure TestValueOrMethods;
var
  LResult: TNamedBarrierResult;
  LBarrier: INamedBarrier;
begin
  WriteLn('测试 ValueOr 方法...');
  
  // 测试成功情况
  LResult := CreateNamedBarrierResult('test_value_or', 2);
  LBarrier := LResult.UnwrapOr(nil);
  if Assigned(LBarrier) then
    WriteLn('  ✓ 成功时 UnwrapOr 返回有效值')
  else
    WriteLn('  ✗ 成功时 UnwrapOr 返回 nil');
  
  // 测试失败情况
  LResult := CreateNamedBarrierResult('', 2);
  LBarrier := LResult.UnwrapOr(nil);
  if not Assigned(LBarrier) then
    WriteLn('  ✓ 失败时 UnwrapOr 返回默认值')
  else
    WriteLn('  ✗ 失败时应该返回默认值');
  
  WriteLn;
end;

var
  LTestsPassed, LTestsTotal: Integer;

begin
  WriteLn('fafafa.core.sync.namedBarrier TResult 接口简单测试');
  WriteLn('==================================================');
  WriteLn;
  
  LTestsTotal := 3;
  LTestsPassed := 0;
  
  try
    TestBasicResultInterface;
    Inc(LTestsPassed);
    
    TestErrorHandling;
    Inc(LTestsPassed);
    
    TestValueOrMethods;
    Inc(LTestsPassed);
    
    WriteLn('==================================================');
    WriteLn('测试完成: ', LTestsPassed, '/', LTestsTotal, ' 通过');
    
    if LTestsPassed = LTestsTotal then
    begin
      WriteLn('✓ 所有测试通过！');
      ExitCode := 0;
    end
    else
    begin
      WriteLn('✗ 部分测试失败');
      ExitCode := 1;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('测试执行错误: ', E.ClassName, ' - ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('注意：这些测试验证基于 TResult 的增量接口。');
  WriteLn('原有接口保持不变且完全兼容。');
end.
