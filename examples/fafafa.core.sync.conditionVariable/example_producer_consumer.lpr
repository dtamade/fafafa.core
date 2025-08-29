program example_producer_consumer;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  Classes, SysUtils,
  fafafa.core.sync.mutex, fafafa.core.sync.conditionVariable;

var
  Mutex: IMutex;
  Cond: IConditionVariable;
  Queue: array of Integer;
  Done: Boolean;

procedure Producer;
var i: Integer;
begin
  for i := 1 to 5 do
  begin
    Mutex.Acquire;
    try
      SetLength(Queue, Length(Queue)+1);
      Queue[High(Queue)] := i;
      Writeln('[生产者] 生产: ', i);
      // 通知消费者有新数据
      Cond.Signal;
    finally
      Mutex.Release;
    end;
    Sleep(50);
  end;
  // 发送结束信号
  Mutex.Acquire;
  try
    Done := True;
    Cond.Broadcast;
  finally
    Mutex.Release;
  end;
end;

procedure Consumer;
var val: Integer; ok: Boolean;
begin
  while True do
  begin
    Mutex.Acquire;
    try
      // 等待直到队列非空或结束
      while (Length(Queue)=0) and (not Done) do
      begin
        ok := Cond.Wait(Mutex, 200); // 短超时轮询，便于示例稳定
        if not ok then ;
      end;
      if (Length(Queue)=0) and Done then Exit;
      // 消费
      val := Queue[0];
      Delete(Queue, 0, 1);
      Writeln('  [消费者] 消费: ', val);
    finally
      Mutex.Release;
    end;
    Sleep(20);
  end;
end;

var
  T1, T2: TThread;
begin
  Mutex := MakeMutex;
  Cond := MakeConditionVariable;
  Done := False; SetLength(Queue, 0);

  T1 := TThread.CreateAnonymousThread(@Producer);
  T2 := TThread.CreateAnonymousThread(@Consumer);
  T1.Start; T2.Start;
  T1.WaitFor; T2.WaitFor;
  T1.Free; T2.Free;

  Writeln('示例完成。');
end.

