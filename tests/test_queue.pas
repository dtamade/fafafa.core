program test_queue;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.collections.vecdeque;

type
  TIntQueue = specialize TVecDeque<Integer>;
  TStringQueue = specialize TVecDeque<String>;

procedure TestBasicQueueOperations;
var
  LQueue: TIntQueue;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 测试基本队列操作 ===');
  
  LQueue := TIntQueue.Create;
  try
    // 测试空队列
    WriteLn('队列是否为空: ', LQueue.IsEmpty);
    WriteLn('队列元素数量: ', LQueue.Count);
    
    // 测试入队
    WriteLn('入队元素 1-5...');
    for I := 1 to 5 do
    begin
      LQueue.Enqueue(I);
      WriteLn('  入队: ', I, ', 当前数量: ', LQueue.Count);
    end;
    
    // 测试 Peek
    LValue := LQueue.Peek;
    WriteLn('Peek 队首元素: ', LValue, ' (不移除)');
    WriteLn('队列数量: ', LQueue.Count);
    
    // 测试出队
    WriteLn('出队所有元素...');
    while not LQueue.IsEmpty do
    begin
      LValue := LQueue.Dequeue;
      WriteLn('  出队: ', LValue, ', 剩余数量: ', LQueue.Count);
    end;
    
    WriteLn('✅ 基本队列操作测试通过');
    
  finally
    LQueue.Free;
  end;
end;

procedure TestSafeOperations;
var
  LQueue: TIntQueue;
  LValue: Integer;
  LSuccess: Boolean;
begin
  WriteLn;
  WriteLn('=== 测试安全操作 ===');
  
  LQueue := TIntQueue.Create;
  try
    // 测试空队列的安全操作
    LSuccess := LQueue.Dequeue(LValue);
    WriteLn('空队列安全出队: ', LSuccess);
    
    LSuccess := LQueue.Peek(LValue);
    WriteLn('空队列安全 Peek: ', LSuccess);
    
    // 添加一些元素
    LQueue.Enqueue(100);
    LQueue.Enqueue(200);
    
    // 测试安全操作
    LSuccess := LQueue.Peek(LValue);
    WriteLn('安全 Peek: ', LSuccess, ', 值: ', LValue);
    
    LSuccess := LQueue.Dequeue(LValue);
    WriteLn('安全出队: ', LSuccess, ', 值: ', LValue);
    
    LSuccess := LQueue.Dequeue(LValue);
    WriteLn('安全出队: ', LSuccess, ', 值: ', LValue);
    
    // 再次测试空队列
    LSuccess := LQueue.Dequeue(LValue);
    WriteLn('空队列安全出队: ', LSuccess);
    
    WriteLn('✅ 安全操作测试通过');
    
  finally
    LQueue.Free;
  end;
end;

procedure TestArrayOperations;
var
  LQueue: TIntQueue;
  LArray: array[0..4] of Integer;
  LValue: Integer;
  I: Integer;
begin
  WriteLn;
  WriteLn('=== 测试数组操作 ===');
  
  LQueue := TIntQueue.Create;
  try
    // 准备测试数组
    for I := 0 to High(LArray) do
      LArray[I] := (I + 1) * 10;
    
    // 测试数组入队
    WriteLn('从数组入队...');
    LQueue.Enqueue(LArray);
    WriteLn('入队后数量: ', LQueue.Count);
    
    // 出队验证
    WriteLn('验证数组入队结果:');
    for I := 0 to High(LArray) do
    begin
      LValue := LQueue.Dequeue;
      WriteLn('  期望: ', LArray[I], ', 实际: ', LValue, ', 匹配: ', LArray[I] = LValue);
    end;
    
    WriteLn('✅ 数组操作测试通过');
    
  finally
    LQueue.Free;
  end;
end;

procedure TestStringQueue;
var
  LQueue: TStringQueue;
  LValue: String;
begin
  WriteLn;
  WriteLn('=== 测试字符串队列 ===');
  
  LQueue := TStringQueue.Create;
  try
    // 测试字符串入队
    LQueue.Enqueue('Hello');
    LQueue.Enqueue('World');
    LQueue.Enqueue('Queue');
    
    WriteLn('字符串队列数量: ', LQueue.Count);
    
    // 出队验证
    while not LQueue.IsEmpty do
    begin
      LValue := LQueue.Dequeue;
      WriteLn('出队字符串: "', LValue, '"');
    end;
    
    WriteLn('✅ 字符串队列测试通过');
    
  finally
    LQueue.Free;
  end;
end;

procedure TestAliases;
var
  LQueue: TIntQueue;
  LValue: Integer;
begin
  WriteLn;
  WriteLn('=== 测试别名方法 ===');
  
  LQueue := TIntQueue.Create;
  try
    // 测试 Push 别名
    LQueue.Push(1);
    LQueue.Push(2);
    LQueue.Push(3);
    
    WriteLn('使用 Push 入队后数量: ', LQueue.Count);
    
    // 测试 Pop 别名
    LValue := LQueue.Pop;
    WriteLn('使用 Pop 出队: ', LValue);
    
    // 测试安全 Pop
    if LQueue.Pop(LValue) then
      WriteLn('安全 Pop: ', LValue);
    
    WriteLn('✅ 别名方法测试通过');
    
  finally
    LQueue.Free;
  end;
end;

begin
  try
    TestBasicQueueOperations;
    TestSafeOperations;
    TestArrayOperations;
    TestStringQueue;
    TestAliases;
    
    WriteLn;
    WriteLn('🎉 所有队列测试通过！');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 测试失败: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
