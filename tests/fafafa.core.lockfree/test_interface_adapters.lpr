program test_interface_adapters;


{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.base,
  // 原子统一：tests 不再引用 fafafa.core.sync
  fafafa.core.lockfree,
  fafafa.core.collections.queue,
  fafafa.core.collections.stack;

type
  TIntQueue = specialize TLockFreeQueueAdapter<Integer>;
  TIntStack = specialize TLockFreeStackAdapter<Integer>;

procedure TestQueueAdapter;
var
  LQueueAdapter: TIntQueue;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 测试队列适配器 ===');
  
  LQueueAdapter := TIntQueue.CreateWithCapacity(100);
  try
    // 测试入队
    WriteLn('测试入队操作...');
    for I := 1 to 10 do
    begin
      LQueueAdapter.Enqueue(I);
      WriteLn('  入队: ', I);
    end;
    
    // 测试出队
    WriteLn('测试出队操作...');
    while LQueueAdapter.Dequeue(LValue) do
    begin
      WriteLn('  出队: ', LValue);
    end;
    
    // 测试Push/Pop别名
    WriteLn('测试Push/Pop别名...');
    LQueueAdapter.Push(100);
    LQueueAdapter.Push(200);
    
    if LQueueAdapter.Pop(LValue) then
      WriteLn('  Pop: ', LValue);
    if LQueueAdapter.Pop(LValue) then
      WriteLn('  Pop: ', LValue);
    
    WriteLn('队列适配器测试完成！');
    
  finally
    LQueueAdapter.Free;
  end;
  WriteLn;
end;

procedure TestStackAdapter;
var
  LStackAdapter: TIntStack;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 测试栈适配器 ===');
  
  LStackAdapter := TIntStack.CreateNew;
  try
    // 测试压栈
    WriteLn('测试压栈操作...');
    for I := 1 to 10 do
    begin
      LStackAdapter.Push(I);
      WriteLn('  压栈: ', I);
    end;
    
    // 测试弹栈
    WriteLn('测试弹栈操作...');
    while LStackAdapter.TryPop(LValue) do
    begin
      WriteLn('  弹栈: ', LValue);
    end;
    
    // 测试空栈
    WriteLn('测试空栈状态...');
    WriteLn('  栈是否为空: ', LStackAdapter.IsEmpty);
    
    // 测试异常处理
    WriteLn('测试异常处理...');
    try
      LValue := LStackAdapter.Pop; // 应该抛出异常
      WriteLn('  错误：应该抛出异常但没有');
    except
      on E: Exception do
        WriteLn('  正确：捕获到异常 - ', E.Message);
    end;
    
    WriteLn('栈适配器测试完成！');
    
  finally
    LStackAdapter.Free;
  end;
  WriteLn;
end;

procedure TestInterfaceUsage;
var
  LQueue: TIntQueue;
  LStack: TIntStack;
  LValue: Integer;
begin
  WriteLn('=== 测试接口门面使用 ===');
  
  // 创建适配器实例
  LQueue := TIntQueue.CreateWithCapacity(50);
  LStack := TIntStack.CreateNew;
  
  try
    // 通过适配器使用标准接口
    WriteLn('通过适配器使用队列接口...');
    LQueue.Enqueue(1);
    LQueue.Enqueue(2);
    LQueue.Enqueue(3);
    
    while LQueue.Dequeue(LValue) do
      WriteLn('  队列元素: ', LValue);
    
    WriteLn('通过适配器使用栈接口...');
    LStack.Push(10);
    LStack.Push(20);
    LStack.Push(30);
    
    while LStack.TryPop(LValue) do
      WriteLn('  栈元素: ', LValue);
    
    WriteLn('接口门面测试完成！');
    
  finally
    LQueue.Free;
    LStack.Free;
  end;
  WriteLn;
end;

begin
  try
    WriteLn('fafafa.core.lockfree 接口适配器测试');
    WriteLn('====================================');
    WriteLn;
    
    TestQueueAdapter;
    TestStackAdapter;
    TestInterfaceUsage;
    
    WriteLn('所有测试完成！');
    WriteLn;
    
  except
    on E: Exception do
    begin
      WriteLn('测试失败: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.
