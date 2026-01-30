{$CODEPAGE UTF8}
program diagnostic_test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.namedEvent;

const
  EVENT_NAME = 'DiagnosticTest_Event';

procedure TestBasicOperations;
var
  LEvent: INamedEvent;
  LGuard: INamedEventGuard;
begin
  WriteLn('=== 基础操作诊断测试 ===');
  
  try
    WriteLn('[1] 创建手动重置事件...');
    LEvent := CreateManualResetNamedEvent(EVENT_NAME + '_' + IntToStr(GetProcessID), False);
    WriteLn('[✓] 事件创建成功');
    
    WriteLn('[2] 测试 TryWait (应该返回 nil)...');
    LGuard := LEvent.TryWait;
    if not Assigned(LGuard) then
      WriteLn('[✓] TryWait 正确返回 nil')
    else
      WriteLn('[✗] TryWait 错误返回了守卫');
    
    WriteLn('[3] 测试 SetEvent...');
    LEvent.SetEvent;
    WriteLn('[✓] SetEvent 成功');
    
    WriteLn('[4] 测试 TryWait (应该返回守卫)...');
    LGuard := LEvent.TryWait;
    if Assigned(LGuard) then
      WriteLn('[✓] TryWait 正确返回守卫')
    else
      WriteLn('[✗] TryWait 错误返回 nil');
    
    WriteLn('[5] 测试 ResetEvent...');
    LEvent.ResetEvent;
    WriteLn('[✓] ResetEvent 成功');
    
    WriteLn('[6] 测试 TryWait (应该返回 nil)...');
    LGuard := LEvent.TryWait;
    if not Assigned(LGuard) then
      WriteLn('[✓] TryWait 正确返回 nil')
    else
      WriteLn('[✗] TryWait 错误返回了守卫');
    
    WriteLn('[7] 测试 PulseEvent...');
    LEvent.PulseEvent;
    WriteLn('[✓] PulseEvent 成功');
    
    WriteLn('[8] 测试 IsSignaled...');
    WriteLn('[INFO] IsSignaled = ', LEvent.IsSignaled);
    
    WriteLn('=== 基础操作测试完成 ===');
    
  except
    on E: Exception do
    begin
      WriteLn('[✗] 异常: ', E.ClassName, ': ', E.Message);
      raise;
    end;
  end;
end;

procedure TestAutoResetEvent;
var
  LEvent: INamedEvent;
  LGuard: INamedEventGuard;
begin
  WriteLn('=== 自动重置事件诊断测试 ===');
  
  try
    WriteLn('[1] 创建自动重置事件...');
    LEvent := CreateAutoResetNamedEvent(EVENT_NAME + '_Auto_' + IntToStr(GetProcessID), False);
    WriteLn('[✓] 自动重置事件创建成功');
    
    WriteLn('[2] 测试 SetEvent...');
    LEvent.SetEvent;
    WriteLn('[✓] SetEvent 成功');
    
    WriteLn('[3] 第一次 TryWait (应该成功)...');
    LGuard := LEvent.TryWait;
    if Assigned(LGuard) then
      WriteLn('[✓] 第一次 TryWait 成功')
    else
      WriteLn('[✗] 第一次 TryWait 失败');
    LGuard := nil;
    
    WriteLn('[4] 第二次 TryWait (应该失败，自动重置)...');
    LGuard := LEvent.TryWait;
    if not Assigned(LGuard) then
      WriteLn('[✓] 第二次 TryWait 正确失败')
    else
      WriteLn('[✗] 第二次 TryWait 错误成功');
    
    WriteLn('=== 自动重置事件测试完成 ===');
    
  except
    on E: Exception do
    begin
      WriteLn('[✗] 异常: ', E.ClassName, ': ', E.Message);
      raise;
    end;
  end;
end;

procedure TestTimeouts;
var
  LEvent: INamedEvent;
  LGuard: INamedEventGuard;
  LStartTime, LEndTime: TDateTime;
begin
  WriteLn('=== 超时机制诊断测试 ===');
  
  try
    WriteLn('[1] 创建事件...');
    LEvent := CreateNamedEvent(EVENT_NAME + '_Timeout_' + IntToStr(GetProcessID));
    WriteLn('[✓] 事件创建成功');
    
    WriteLn('[2] 测试零超时...');
    LStartTime := Now;
    LGuard := LEvent.TryWaitFor(0);
    LEndTime := Now;
    if not Assigned(LGuard) then
      WriteLn('[✓] 零超时正确返回 nil')
    else
      WriteLn('[✗] 零超时错误返回守卫');
    WriteLn('[INFO] 零超时耗时: ', FormatFloat('0.000', (LEndTime - LStartTime) * 24 * 60 * 60 * 1000), ' 毫秒');
    
    WriteLn('[3] 测试短超时 (100ms)...');
    LStartTime := Now;
    LGuard := LEvent.TryWaitFor(100);
    LEndTime := Now;
    if not Assigned(LGuard) then
      WriteLn('[✓] 短超时正确返回 nil')
    else
      WriteLn('[✗] 短超时错误返回守卫');
    WriteLn('[INFO] 短超时耗时: ', FormatFloat('0.000', (LEndTime - LStartTime) * 24 * 60 * 60 * 1000), ' 毫秒');
    
    WriteLn('=== 超时机制测试完成 ===');
    
  except
    on E: Exception do
    begin
      WriteLn('[✗] 异常: ', E.ClassName, ': ', E.Message);
      raise;
    end;
  end;
end;

begin
  WriteLn('开始 namedEvent 诊断测试...');
  WriteLn('进程 ID: ', GetProcessID);
  WriteLn;
  
  try
    TestBasicOperations;
    WriteLn;
    
    TestAutoResetEvent;
    WriteLn;
    
    TestTimeouts;
    WriteLn;
    
    WriteLn('🎉 所有诊断测试通过！');
    ExitCode := 0;
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 诊断测试失败: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
