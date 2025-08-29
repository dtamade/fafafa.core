program basic_event_usage;

{$mode objfpc}{$H+}

{ 
  基础事件使用示例
  
  本示例演示：
  1. 如何创建和使用事件
  2. 手动重置 vs 自动重置事件的区别
  3. 基本的等待和信号操作
}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  fafafa.core.sync.event, fafafa.core.sync.base;

procedure DemoAutoResetEvent;
var
  Event: IEvent;
  Result: TWaitResult;
begin
  WriteLn('=== 自动重置事件演示 ===');
  
  // 创建自动重置事件，初始状态为未信号
  Event := CreateEvent(False, False);
  WriteLn('创建自动重置事件，初始状态：未信号');
  
  // 尝试等待（应该超时）
  WriteLn('尝试等待 100ms...');
  Result := Event.WaitFor(100);
  if Result = wrTimeout then
    WriteLn('等待结果：超时')
  else
    WriteLn('等待结果：信号');

  // 设置事件为信号状态
  WriteLn('设置事件为信号状态');
  Event.SetEvent;
  
  // 第一次等待（应该成功，并自动重置）
  WriteLn('第一次等待...');
  Result := Event.WaitFor(100);
  WriteLn('等待结果：', IfThen(Result = wrSignaled, '成功', '失败'));
  
  // 第二次等待（应该超时，因为自动重置了）
  WriteLn('第二次等待...');
  Result := Event.WaitFor(100);
  WriteLn('等待结果：', IfThen(Result = wrTimeout, '超时（自动重置）', '意外成功'));
  
  WriteLn;
end;

procedure DemoManualResetEvent;
var
  Event: IEvent;
  Result: TWaitResult;
begin
  WriteLn('=== 手动重置事件演示 ===');
  
  // 创建手动重置事件，初始状态为未信号
  Event := CreateEvent(True, False);
  WriteLn('创建手动重置事件，初始状态：未信号');
  
  // 尝试等待（应该超时）
  WriteLn('尝试等待 100ms...');
  Result := Event.WaitFor(100);
  WriteLn('等待结果：', IfThen(Result = wrTimeout, '超时', '信号'));
  
  // 设置事件为信号状态
  WriteLn('设置事件为信号状态');
  Event.SetEvent;
  
  // 第一次等待（应该成功）
  WriteLn('第一次等待...');
  Result := Event.WaitFor(100);
  WriteLn('等待结果：', IfThen(Result = wrSignaled, '成功', '失败'));
  
  // 第二次等待（仍然应该成功，因为是手动重置）
  WriteLn('第二次等待...');
  Result := Event.WaitFor(100);
  WriteLn('等待结果：', IfThen(Result = wrSignaled, '成功（保持信号）', '失败'));
  
  // 手动重置事件
  WriteLn('手动重置事件');
  Event.ResetEvent;
  
  // 第三次等待（应该超时）
  WriteLn('第三次等待...');
  Result := Event.WaitFor(100);
  WriteLn('等待结果：', IfThen(Result = wrTimeout, '超时（已重置）', '意外成功'));
  
  WriteLn;
end;

procedure DemoEventStates;
var
  Event: IEvent;
begin
  WriteLn('=== 事件状态查询演示 ===');
  
  Event := CreateEvent(True, False); // 手动重置，未信号
  
  WriteLn('初始状态：');
  WriteLn('  是否为信号状态：', Event.IsSignaled);
  WriteLn('  是否为手动重置：', Event.IsManualReset);
  WriteLn('  等待线程数：', Event.GetWaitingThreadCount);
  WriteLn('  最后错误：', Ord(Event.GetLastError));
  
  Event.SetEvent;
  WriteLn('设置信号后：');
  WriteLn('  是否为信号状态：', Event.IsSignaled);
  WriteLn('  最后错误：', Ord(Event.GetLastError));
  
  Event.ResetEvent;
  WriteLn('重置后：');
  WriteLn('  是否为信号状态：', Event.IsSignaled);
  WriteLn('  最后错误：', Ord(Event.GetLastError));
  
  WriteLn;
end;

procedure DemoTryWaitMethod;
var
  Event: IEvent;
begin
  WriteLn('=== TryWait 方法演示 ===');
  
  Event := CreateEvent(False, False); // 自动重置，未信号
  
  WriteLn('未信号状态下的 TryWait：', Event.TryWait);
  
  Event.SetEvent;
  WriteLn('信号状态下的 TryWait：', Event.TryWait);
  WriteLn('再次 TryWait（自动重置后）：', Event.TryWait);
  
  WriteLn;
end;

procedure DemoErrorHandling;
var
  Event: IEvent;
  Result: TWaitResult;
begin
  WriteLn('=== 错误处理演示 ===');
  
  Event := CreateEvent(True, False);
  
  // 正常操作
  Event.SetEvent;
  WriteLn('正常操作后的错误状态：', Ord(Event.GetLastError));
  
  // 等待操作
  Result := Event.WaitFor(0);
  WriteLn('等待操作结果：', Ord(Result));
  WriteLn('等待操作后的错误状态：', Ord(Event.GetLastError));
  
  // 超时操作
  Event.ResetEvent;
  Result := Event.WaitFor(10);
  WriteLn('超时操作结果：', Ord(Result));
  WriteLn('超时操作后的错误状态：', Ord(Event.GetLastError));
  
  WriteLn;
end;

begin
  WriteLn('fafafa.core 事件同步原语 - 基础使用示例');
  WriteLn('================================================');
  WriteLn;
  
  try
    DemoAutoResetEvent;
    DemoManualResetEvent;
    DemoEventStates;
    DemoTryWaitMethod;
    DemoErrorHandling;
    
    WriteLn('所有演示完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('发生错误：', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.
