{$CODEPAGE UTF8}
program stress_test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.namedEvent;

const
  MAX_EVENTS = 1000;
  OPERATIONS_PER_EVENT = 1000;

procedure TestMassEventCreation;
var
  LEvents: array of INamedEvent;
  I: Integer;
  LStartTime, LEndTime: TDateTime;
begin
  WriteLn('=== 大量事件创建测试 ===');
  SetLength(LEvents, MAX_EVENTS);
  
  LStartTime := Now;
  
  try
    for I := 0 to MAX_EVENTS-1 do
    begin
      LEvents[I] := CreateNamedEvent('StressTest_' + IntToStr(I) + '_' + IntToStr(GetProcessID));
      
      if (I + 1) mod 100 = 0 then
        WriteLn('已创建 ', I + 1, ' 个事件');
    end;
    
    LEndTime := Now;
    WriteLn('✅ 成功创建 ', MAX_EVENTS, ' 个事件');
    WriteLn('耗时: ', FormatFloat('0.000', (LEndTime - LStartTime) * 24 * 60 * 60), ' 秒');
    WriteLn('平均每个事件: ', FormatFloat('0.000', (LEndTime - LStartTime) * 24 * 60 * 60 * 1000 / MAX_EVENTS), ' 毫秒');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 大量事件创建失败: ', E.Message);
      raise;
    end;
  end;
  
  // 清理
  for I := 0 to MAX_EVENTS-1 do
    LEvents[I] := nil;
  SetLength(LEvents, 0);
end;

procedure TestHighFrequencyOperations;
var
  LEvent: INamedEvent;
  LGuard: INamedEventGuard;
  I: Integer;
  LStartTime, LEndTime: TDateTime;
  LSuccessCount: Integer;
begin
  WriteLn('=== 高频操作测试 ===');
  
  LEvent := CreateAutoResetNamedEvent('HighFreq_' + IntToStr(GetProcessID), False);
  LSuccessCount := 0;
  
  LStartTime := Now;
  
  try
    for I := 1 to OPERATIONS_PER_EVENT do
    begin
      // 快速设置和等待
      LEvent.SetEvent;
      LGuard := LEvent.TryWait;
      if Assigned(LGuard) then
      begin
        Inc(LSuccessCount);
        LGuard := nil;
      end;
      
      // 每1000次操作报告一次
      if I mod 1000 = 0 then
        WriteLn('已完成 ', I, ' 次操作，成功 ', LSuccessCount, ' 次');
    end;
    
    LEndTime := Now;
    WriteLn('✅ 高频操作测试完成');
    WriteLn('总操作数: ', OPERATIONS_PER_EVENT);
    WriteLn('成功操作数: ', LSuccessCount);
    WriteLn('成功率: ', (LSuccessCount * 100.0 / OPERATIONS_PER_EVENT):0:2, '%');
    WriteLn('耗时: ', FormatFloat('0.000', (LEndTime - LStartTime) * 24 * 60 * 60), ' 秒');
    WriteLn('操作频率: ', FormatFloat('0.0', OPERATIONS_PER_EVENT / ((LEndTime - LStartTime) * 24 * 60 * 60)), ' 操作/秒');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 高频操作测试失败: ', E.Message);
      raise;
    end;
  end;
end;

procedure TestExtremeTimeouts;
var
  LEvent: INamedEvent;
  LGuard: INamedEventGuard;
  LStartTime, LEndTime: TDateTime;
begin
  WriteLn('=== 极限超时测试 ===');
  
  LEvent := CreateNamedEvent('TimeoutTest_' + IntToStr(GetProcessID));
  
  try
    // 测试零超时
    WriteLn('测试零超时...');
    LStartTime := Now;
    LGuard := LEvent.TryWaitFor(0);
    LEndTime := Now;
    if not Assigned(LGuard) then
      WriteLn('✅ 零超时正确返回 nil，耗时: ', FormatFloat('0.000', (LEndTime - LStartTime) * 24 * 60 * 60 * 1000), ' 毫秒')
    else
      WriteLn('❌ 零超时应该返回 nil');
    
    // 测试短超时
    WriteLn('测试短超时 (1ms)...');
    LStartTime := Now;
    LGuard := LEvent.TryWaitFor(1);
    LEndTime := Now;
    if not Assigned(LGuard) then
      WriteLn('✅ 短超时正确返回 nil，耗时: ', FormatFloat('0.000', (LEndTime - LStartTime) * 24 * 60 * 60 * 1000), ' 毫秒')
    else
      WriteLn('❌ 短超时应该返回 nil');
    
    // 测试长超时（但立即触发）
    WriteLn('测试长超时但立即触发...');
    LEvent.SetEvent;
    LStartTime := Now;
    LGuard := LEvent.TryWaitFor(10000);
    LEndTime := Now;
    if Assigned(LGuard) then
      WriteLn('✅ 长超时立即触发成功，耗时: ', FormatFloat('0.000', (LEndTime - LStartTime) * 24 * 60 * 60 * 1000), ' 毫秒')
    else
      WriteLn('❌ 长超时立即触发失败');
    
    WriteLn('✅ 极限超时测试完成');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 极限超时测试失败: ', E.Message);
      raise;
    end;
  end;
end;

begin
  WriteLn('开始压力测试...');
  
  try
    TestMassEventCreation;
    WriteLn;
    
    TestHighFrequencyOperations;
    WriteLn;
    
    TestExtremeTimeouts;
    WriteLn;
    
    WriteLn('🎉 所有压力测试通过！');
    ExitCode := 0;
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 压力测试失败: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
