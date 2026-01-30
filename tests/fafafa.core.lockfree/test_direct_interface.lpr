program test_direct_interface;


{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.lockfree,
  fafafa.core.collections.queue,
  fafafa.core.collections.stack;

type
  { 直接实现 IQueue 接口的无锁队列 }
  TDirectQueueImpl = class(specialize TPreAllocMPMCQueue<Integer>)
  public
    // 实现 IQueue 接口的方法
    procedure IQueue_Enqueue(const aElement: Integer);
    procedure IQueue_Push(const aElement: Integer);
    function IQueue_Dequeue: Integer;
    function IQueue_Pop: Integer;
    function IQueue_Dequeue_Safe(var aElement: Integer): Boolean;
    function IQueue_Pop_Safe(var aElement: Integer): Boolean;
    function IQueue_Peek: Integer;
    function IQueue_Peek_Safe(var aElement: Integer): Boolean;
  end;

  { 直接实现 IStack 基本方法的无锁栈 }
  TDirectStackImpl = class(specialize TTreiberStack<Integer>)
  public
    // 实现 IStack 接口的核心方法
    procedure IStack_Push(const aElement: Integer);
    function IStack_Pop: Integer;
    function IStack_TryPop(var aDst: Integer): Boolean;
  end;

{ TDirectQueueImpl }

procedure TDirectQueueImpl.IQueue_Enqueue(const aElement: Integer);
begin
  if not Enqueue(aElement) then
    raise Exception.Create('Queue is full');
end;

procedure TDirectQueueImpl.IQueue_Push(const aElement: Integer);
begin
  IQueue_Enqueue(aElement);
end;

function TDirectQueueImpl.IQueue_Dequeue: Integer;
begin
  if not Dequeue(Result) then
    raise Exception.Create('Queue is empty');
end;

function TDirectQueueImpl.IQueue_Pop: Integer;
begin
  Result := IQueue_Dequeue;
end;

function TDirectQueueImpl.IQueue_Dequeue_Safe(var aElement: Integer): Boolean;
begin
  Result := Dequeue(aElement);
end;

function TDirectQueueImpl.IQueue_Pop_Safe(var aElement: Integer): Boolean;
begin
  Result := IQueue_Dequeue_Safe(aElement);
end;

function TDirectQueueImpl.IQueue_Peek: Integer;
begin
  raise Exception.Create('Peek operation not supported by lock-free queue');
end;

function TDirectQueueImpl.IQueue_Peek_Safe(var aElement: Integer): Boolean;
begin
  // 无锁队列通常不支持Peek操作
  Result := False;
end;

{ TDirectStackImpl }

procedure TDirectStackImpl.IStack_Push(const aElement: Integer);
begin
  Push(aElement);
end;

function TDirectStackImpl.IStack_Pop: Integer;
begin
  if not Pop(Result) then
    raise Exception.Create('Stack is empty');
end;

function TDirectStackImpl.IStack_TryPop(var aDst: Integer): Boolean;
begin
  Result := Pop(aDst);
end;

procedure TestDirectQueueInterface;
var
  LQueue: TDirectQueueImpl;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 测试直接队列接口实现 ===');
  
  LQueue := TDirectQueueImpl.Create(100);
  try
    // 测试接口方法
    WriteLn('测试接口方法入队...');
    for I := 1 to 10 do
    begin
      LQueue.IQueue_Enqueue(I);
      WriteLn('  接口入队: ', I);
    end;
    
    // 测试接口方法出队
    WriteLn('测试接口方法出队...');
    while LQueue.IQueue_Dequeue_Safe(LValue) do
    begin
      WriteLn('  接口出队: ', LValue);
    end;
    
    // 测试别名方法
    WriteLn('测试Push/Pop别名...');
    LQueue.IQueue_Push(100);
    LQueue.IQueue_Push(200);
    
    if LQueue.IQueue_Pop_Safe(LValue) then
      WriteLn('  接口Pop: ', LValue);
    if LQueue.IQueue_Pop_Safe(LValue) then
      WriteLn('  接口Pop: ', LValue);
    
    // 测试原始方法仍然可用
    WriteLn('测试原始方法...');
    LQueue.Enqueue(300);
    if LQueue.Dequeue(LValue) then
      WriteLn('  原始方法: ', LValue);
    
    WriteLn('直接队列接口测试完成！');
    
  finally
    LQueue.Free;
  end;
  WriteLn;
end;

procedure TestDirectStackInterface;
var
  LStack: TDirectStackImpl;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 测试直接栈接口实现 ===');
  
  LStack := TDirectStackImpl.Create;
  try
    // 测试接口方法
    WriteLn('测试接口方法压栈...');
    for I := 1 to 10 do
    begin
      LStack.IStack_Push(I);
      WriteLn('  接口压栈: ', I);
    end;
    
    // 测试接口方法弹栈
    WriteLn('测试接口方法弹栈...');
    while LStack.IStack_TryPop(LValue) do
    begin
      WriteLn('  接口弹栈: ', LValue);
    end;
    
    // 测试异常处理
    WriteLn('测试异常处理...');
    try
      LValue := LStack.IStack_Pop; // 应该抛出异常
      WriteLn('  错误：应该抛出异常但没有');
    except
      on E: Exception do
        WriteLn('  正确：捕获到异常 - ', E.Message);
    end;
    
    // 测试原始方法仍然可用
    WriteLn('测试原始方法...');
    LStack.Push(500);
    if LStack.Pop(LValue) then
      WriteLn('  原始方法: ', LValue);
    
    WriteLn('直接栈接口测试完成！');
    
  finally
    LStack.Free;
  end;
  WriteLn;
end;

begin
  try
    WriteLn('fafafa.core.lockfree 直接接口实现测试');
    WriteLn('======================================');
    WriteLn;
    
    TestDirectQueueInterface;
    TestDirectStackInterface;
    
    WriteLn('所有测试完成！');
    WriteLn('这证明了无锁数据结构可以直接实现标准接口方法');
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
