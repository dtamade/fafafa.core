program demo_basic;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  fafafa.core.sync.event, fafafa.core.sync.base;

var
  Event: IEvent;
  Result: TWaitResult;

begin
  WriteLn('fafafa.core 事件同步原语 - 基础演示');
  WriteLn('====================================');
  WriteLn;
  
  // 创建自动重置事件
  WriteLn('1. 创建自动重置事件');
  Event := MakeEvent(False, False);
  if Event.IsManualReset then
    WriteLn('   事件类型：手动重置')
  else
    WriteLn('   事件类型：自动重置');
  if Event.IsSignaled then
    WriteLn('   初始状态：信号')
  else
    WriteLn('   初始状态：未信号');
  WriteLn;
  
  // 测试等待超时
  WriteLn('2. 测试等待超时');
  Result := Event.WaitFor(100);
  WriteLn('   等待结果：', Ord(Result), ' (0=信号, 1=超时, 2=错误)');
  WriteLn;
  
  // 设置事件并等待
  WriteLn('3. 设置事件并等待');
  Event.SetEvent;
  if Event.IsSignaled then
    WriteLn('   设置事件后状态：信号')
  else
    WriteLn('   设置事件后状态：未信号');
  Result := Event.WaitFor(100);
  WriteLn('   等待结果：', Ord(Result));
  if Event.IsSignaled then
    WriteLn('   等待后状态：信号')
  else
    WriteLn('   等待后状态：未信号');
  WriteLn;
  
  // 测试手动重置事件
  WriteLn('4. 测试手动重置事件');
  Event := MakeEvent(True, False);
  Event.SetEvent;
  WriteLn('   设置后第一次等待：', Ord(Event.WaitFor(0)));
  WriteLn('   第二次等待：', Ord(Event.WaitFor(0)));
  Event.ResetEvent;
  WriteLn('   重置后等待：', Ord(Event.WaitFor(10)));
  WriteLn;
  
  // 测试 TryWait
  WriteLn('5. 测试 TryWait');
  Event.SetEvent;
  WriteLn('   TryWait 结果：', Event.TryWait);
  WriteLn('   再次 TryWait：', Event.TryWait);
  WriteLn;
  
  WriteLn('演示完成！');
  WriteLn('按回车键退出...');
  ReadLn;
end.
