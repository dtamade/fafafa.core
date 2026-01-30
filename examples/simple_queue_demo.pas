program simple_queue_demo;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.collections.vecdeque;

type
  TIntQueue = specialize TVecDeque<Integer>;

var
  LQueue: TIntQueue;
  LValue: Integer;

begin
  WriteLn('=== 简单队列演示 ===');
  
  LQueue := TIntQueue.Create;
  try
    // 入队
    WriteLn('入队: 10, 20, 30');
    LQueue.Enqueue(10);
    LQueue.Enqueue(20);
    LQueue.Enqueue(30);
    WriteLn('队列大小: ', LQueue.Count);
    
    // 出队
    WriteLn('出队测试:');
    LValue := LQueue.Dequeue;
    WriteLn('  出队: ', LValue);
    LValue := LQueue.Dequeue;
    WriteLn('  出队: ', LValue);
    LValue := LQueue.Dequeue;
    WriteLn('  出队: ', LValue);
    
    WriteLn('队列大小: ', LQueue.Count);
    WriteLn('队列是否为空: ', LQueue.IsEmpty);
    
    WriteLn('✅ 队列演示完成');
    
  finally
    LQueue.Free;
  end;
end.
