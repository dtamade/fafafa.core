program queue_demo;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.collections.vecdeque;

type
  TIntQueue = specialize TVecDeque<Integer>;
  TStringQueue = specialize TVecDeque<String>;

procedure DemoBasicQueueOperations;
var
  LQueue: TIntQueue;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 基本队列操作演示 ===');
  
  LQueue := TIntQueue.Create;
  try
    WriteLn('1. 创建空队列');
    WriteLn('   队列是否为空: ', LQueue.IsEmpty);
    WriteLn('   队列大小: ', LQueue.Count);
    WriteLn;
    
    WriteLn('2. 入队操作 (Enqueue)');
    for I := 1 to 5 do
    begin
      LQueue.Enqueue(I * 10);
      WriteLn('   入队: ', I * 10, ', 当前大小: ', LQueue.Count);
    end;
    WriteLn;
    
    WriteLn('3. 查看队首元素 (Peek)');
    LValue := LQueue.Peek;
    WriteLn('   队首元素: ', LValue, ' (不移除)');
    WriteLn('   队列大小: ', LQueue.Count);
    WriteLn;
    
    WriteLn('4. 出队操作 (Dequeue)');
    while not LQueue.IsEmpty do
    begin
      LValue := LQueue.Dequeue;
      WriteLn('   出队: ', LValue, ', 剩余大小: ', LQueue.Count);
    end;
    WriteLn;
    
  finally
    LQueue.Free;
  end;
end;

procedure DemoSafeOperations;
var
  LQueue: TIntQueue;
  LValue: Integer;
  LSuccess: Boolean;
begin
  WriteLn('=== 安全操作演示 ===');
  
  LQueue := TIntQueue.Create;
  try
    WriteLn('1. 空队列安全操作');
    LSuccess := LQueue.Dequeue(LValue);
    WriteLn('   安全出队结果: ', LSuccess);
    
    LSuccess := LQueue.Peek(LValue);
    WriteLn('   安全查看结果: ', LSuccess);
    WriteLn;
    
    WriteLn('2. 添加元素后的安全操作');
    LQueue.Enqueue(100);
    LQueue.Enqueue(200);
    
    LSuccess := LQueue.Peek(LValue);
    WriteLn('   安全查看: 成功=', LSuccess, ', 值=', LValue);
    
    LSuccess := LQueue.Dequeue(LValue);
    WriteLn('   安全出队: 成功=', LSuccess, ', 值=', LValue);
    
    LSuccess := LQueue.Dequeue(LValue);
    WriteLn('   安全出队: 成功=', LSuccess, ', 值=', LValue);
    
    LSuccess := LQueue.Dequeue(LValue);
    WriteLn('   空队列安全出队: 成功=', LSuccess);
    WriteLn;
    
  finally
    LQueue.Free;
  end;
end;

procedure DemoAliasOperations;
var
  LQueue: TIntQueue;
  LValue: Integer;
begin
  WriteLn('=== 别名操作演示 (Push/Pop) ===');
  
  LQueue := TIntQueue.Create;
  try
    WriteLn('1. 使用 Push 入队');
    LQueue.Push(1);
    LQueue.Push(2);
    LQueue.Push(3);
    WriteLn('   Push 3个元素后大小: ', LQueue.Count);
    WriteLn;
    
    WriteLn('2. 使用 Pop 出队');
    LValue := LQueue.Pop;
    WriteLn('   Pop 结果: ', LValue);
    WriteLn('   剩余大小: ', LQueue.Count);
    WriteLn;
    
    WriteLn('3. 安全 Pop');
    if LQueue.Pop(LValue) then
      WriteLn('   安全 Pop: ', LValue);
    if LQueue.Pop(LValue) then
      WriteLn('   安全 Pop: ', LValue);
    if LQueue.Pop(LValue) then
      WriteLn('   安全 Pop: ', LValue)
    else
      WriteLn('   队列已空，Pop 失败');
    WriteLn;
    
  finally
    LQueue.Free;
  end;
end;

procedure DemoStringQueue;
var
  LQueue: TStringQueue;
  LValue: String;
begin
  WriteLn('=== 字符串队列演示 ===');
  
  LQueue := TStringQueue.Create;
  try
    WriteLn('1. 字符串入队');
    LQueue.Enqueue('第一个');
    LQueue.Enqueue('第二个');
    LQueue.Enqueue('第三个');
    WriteLn('   入队3个字符串，大小: ', LQueue.Count);
    WriteLn;
    
    WriteLn('2. 字符串出队');
    while not LQueue.IsEmpty do
    begin
      LValue := LQueue.Dequeue;
      WriteLn('   出队: "', LValue, '"');
    end;
    WriteLn;
    
  finally
    LQueue.Free;
  end;
end;

procedure DemoArrayOperations;
var
  LQueue: TIntQueue;
  LArray: array[0..3] of Integer = (10, 20, 30, 40);
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 数组操作演示 ===');
  
  LQueue := TIntQueue.Create;
  try
    WriteLn('1. 从数组批量入队');
    LQueue.Enqueue(LArray);
    WriteLn('   批量入队后大小: ', LQueue.Count);
    WriteLn;
    
    WriteLn('2. 验证入队顺序');
    for I := 0 to High(LArray) do
    begin
      LValue := LQueue.Dequeue;
      WriteLn('   期望: ', LArray[I], ', 实际: ', LValue, ', 匹配: ', LArray[I] = LValue);
    end;
    WriteLn;
    
  finally
    LQueue.Free;
  end;
end;

begin
  WriteLn('🚀 队列功能演示程序');
  WriteLn('使用 TVecDeque 实现的高性能队列');
  WriteLn('=====================================');
  WriteLn;
  
  try
    DemoBasicQueueOperations;
    DemoSafeOperations;
    DemoAliasOperations;
    DemoStringQueue;
    DemoArrayOperations;
    
    WriteLn('🎉 所有演示完成！');
    WriteLn;
    WriteLn('总结:');
    WriteLn('- TVecDeque 完全实现了 IQueue<T> 接口');
    WriteLn('- 支持 Enqueue/Dequeue 和 Push/Pop 操作');
    WriteLn('- 提供安全的操作版本 (返回布尔值)');
    WriteLn('- 支持批量操作和多种数据类型');
    WriteLn('- 基于环形缓冲区，性能优异');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 错误: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
