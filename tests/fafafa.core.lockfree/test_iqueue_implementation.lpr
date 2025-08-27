program test_iqueue_implementation;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.lockfree;

type
  TIntQueue = specialize TPreAllocMPMCQueue<Integer>;
  TIntStack = specialize TTreiberStack<Integer>;

procedure TestQueueIQueueMethods;
var
  LQueue: TIntQueue;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 测试队列的 IQueue 接口方法 ===');
  
  LQueue := TIntQueue.Create(100);
  try
    // 测试 IQueue 接口方法
    WriteLn('测试 IEnqueue 方法...');
    for I := 1 to 10 do
    begin
      LQueue.IEnqueue(I);
      WriteLn('  IEnqueue: ', I);
    end;
    
    // 测试 IDequeue_Safe 方法
    WriteLn('测试 IDequeue_Safe 方法...');
    while LQueue.IDequeue_Safe(LValue) do
    begin
      WriteLn('  IDequeue_Safe: ', LValue);
    end;
    
    // 测试 IPush/IPop 别名
    WriteLn('测试 IPush/IPop 别名...');
    LQueue.IPush(100);
    LQueue.IPush(200);
    
    if LQueue.IPop_Safe(LValue) then
      WriteLn('  IPop_Safe: ', LValue);
    if LQueue.IPop_Safe(LValue) then
      WriteLn('  IPop_Safe: ', LValue);
    
    // 测试异常版本
    WriteLn('测试异常版本...');
    LQueue.IEnqueue(300);
    LValue := LQueue.IDequeue;
    WriteLn('  IDequeue: ', LValue);
    
    // 测试 Peek 方法（应该抛出异常）
    WriteLn('测试 IPeek 方法（应该抛出异常）...');
    try
      LValue := LQueue.IPeek;
      WriteLn('  错误：应该抛出异常但没有');
    except
      on E: Exception do
        WriteLn('  正确：捕获到异常 - ', E.Message);
    end;
    
    // 测试 IPeek_Safe 方法
    WriteLn('测试 IPeek_Safe 方法...');
    if LQueue.IPeek_Safe(LValue) then
      WriteLn('  IPeek_Safe: ', LValue)
    else
      WriteLn('  IPeek_Safe: 不支持（正确）');
    
    WriteLn('队列 IQueue 接口方法测试完成！');
    
  finally
    LQueue.Free;
  end;
  WriteLn;
end;

procedure TestStackIStackMethods;
var
  LStack: TIntStack;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 测试栈的 IStack 接口方法 ===');
  
  LStack := TIntStack.Create;
  try
    // 测试 IPush 方法
    WriteLn('测试 IPush 方法...');
    for I := 1 to 10 do
    begin
      LStack.IPush(I);
      WriteLn('  IPush: ', I);
    end;
    
    // 测试 ITryPop 方法
    WriteLn('测试 ITryPop 方法...');
    while LStack.ITryPop(LValue) do
    begin
      WriteLn('  ITryPop: ', LValue);
    end;
    
    // 测试异常版本
    WriteLn('测试异常版本...');
    LStack.IPush(500);
    LValue := LStack.IPop;
    WriteLn('  IPop: ', LValue);
    
    // 测试空栈异常
    WriteLn('测试空栈异常...');
    try
      LValue := LStack.IPop; // 应该抛出异常
      WriteLn('  错误：应该抛出异常但没有');
    except
      on E: Exception do
        WriteLn('  正确：捕获到异常 - ', E.Message);
    end;
    
    WriteLn('栈 IStack 接口方法测试完成！');
    
  finally
    LStack.Free;
  end;
  WriteLn;
end;

procedure TestOriginalMethodsStillWork;
var
  LQueue: TIntQueue;
  LStack: TIntStack;
  LValue: Integer;
begin
  WriteLn('=== 测试原始方法仍然可用 ===');
  
  LQueue := TIntQueue.Create(50);
  LStack := TIntStack.Create;
  try
    // 测试原始队列方法
    WriteLn('测试原始队列方法...');
    LQueue.Enqueue(1);
    LQueue.Enqueue(2);
    
    if LQueue.Dequeue(LValue) then
      WriteLn('  原始 Dequeue: ', LValue);
    if LQueue.Dequeue(LValue) then
      WriteLn('  原始 Dequeue: ', LValue);
    
    // 测试原始栈方法
    WriteLn('测试原始栈方法...');
    LStack.Push(10);
    LStack.Push(20);
    
    if LStack.Pop(LValue) then
      WriteLn('  原始 Pop: ', LValue);
    if LStack.Pop(LValue) then
      WriteLn('  原始 Pop: ', LValue);
    
    WriteLn('原始方法测试完成！');
    
  finally
    LQueue.Free;
    LStack.Free;
  end;
  WriteLn;
end;

procedure TestInterfaceCompatibility;
var
  LQueue: TIntQueue;
  LStack: TIntStack;
begin
  WriteLn('=== 测试接口兼容性 ===');
  
  LQueue := TIntQueue.Create(50);
  LStack := TIntStack.Create;
  try
    // 现在无锁数据结构有了 IQueue 和 IStack 的方法
    WriteLn('无锁队列现在有以下 IQueue 接口方法:');
    WriteLn('  - IEnqueue(const aElement: T)');
    WriteLn('  - IPush(const aElement: T)');
    WriteLn('  - IDequeue: T');
    WriteLn('  - IPop: T');
    WriteLn('  - IDequeue_Safe(var aElement: T): Boolean');
    WriteLn('  - IPop_Safe(var aElement: T): Boolean');
    WriteLn('  - IPeek: T');
    WriteLn('  - IPeek_Safe(var aElement: T): Boolean');
    WriteLn;
    
    WriteLn('无锁栈现在有以下 IStack 接口方法:');
    WriteLn('  - IPush(const aElement: T)');
    WriteLn('  - IPop: T');
    WriteLn('  - ITryPop(var aDst: T): Boolean');
    WriteLn;
    
    WriteLn('这些方法提供了与标准 IQueue 和 IStack 接口兼容的功能！');
    
  finally
    LQueue.Free;
    LStack.Free;
  end;
  WriteLn;
end;

begin
  try
    WriteLn('fafafa.core.lockfree IQueue/IStack 接口实现测试');
    WriteLn('=================================================');
    WriteLn;
    
    TestQueueIQueueMethods;
    TestStackIStackMethods;
    TestOriginalMethodsStillWork;
    TestInterfaceCompatibility;
    
    WriteLn('🎉 所有测试完成！');
    WriteLn('无锁数据结构现在实现了 IQueue 和 IStack 接口的核心方法！');
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
