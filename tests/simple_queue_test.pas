program simple_queue_test;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.collections.vecdeque;

type
  TIntQueue = specialize TVecDeque<Integer>;

var
  LQueue: TIntQueue;
  LValue: Integer;
  I: Integer;

begin
  WriteLn('=== 简单队列测试 ===');
  
  LQueue := TIntQueue.Create;
  try
    // 测试入队
    WriteLn('入队 1, 2, 3...');
    LQueue.Enqueue(1);
    LQueue.Enqueue(2);
    LQueue.Enqueue(3);
    
    WriteLn('队列数量: ', LQueue.Count);
    
    // 测试出队
    WriteLn('出队测试:');
    while not LQueue.IsEmpty do
    begin
      LValue := LQueue.Dequeue;
      WriteLn('  出队: ', LValue);
    end;
    
    WriteLn('✅ 队列测试完成');
    
  finally
    LQueue.Free;
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.
