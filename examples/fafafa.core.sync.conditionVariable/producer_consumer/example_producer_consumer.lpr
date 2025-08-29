program example_producer_consumer;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.mutex, fafafa.core.sync.conditionVariable;

var
  Mutex: IMutex;
  Cond: IConditionVariable;
  Queue: array of Integer;
  Done: Boolean;


procedure Consumer; forward;

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
      Cond.Signal; // 通知消费者
    finally
      Mutex.Release;
    end;
    Sleep(50);
  end;
  Mutex.Acquire;
  try
    Done := True;
    Cond.Broadcast; // 通知所有等待的消费者退出
  finally
    Mutex.Release;
  end;
end;

// 使用显式线程类，避免匿名线程在部分平台上的不确定性
Type
  TProducerThread = class(TThread)
  protected
    procedure Execute; override;
  end;
  TConsumerThread = class(TThread)
  protected
    procedure Execute; override;
  end;

procedure TProducerThread.Execute;
begin
  Producer;
end;

procedure TConsumerThread.Execute;
begin
  Consumer;
end;


procedure Consumer;
var val: Integer; ok: Boolean;
begin
  while True do
  begin
    Mutex.Acquire;
    try
      while (Length(Queue)=0) and (not Done) do
      begin
        ok := Cond.Wait(Mutex, 200); // 短超时轮询，避免卡死
        if not ok then ;
      end;
      if (Length(Queue)=0) and Done then Exit;
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

  T1 := TProducerThread.Create(True);
  T2 := TConsumerThread.Create(True);
  T1.FreeOnTerminate := False; T2.FreeOnTerminate := False;
  T1.Start; T2.Start;
  T1.WaitFor; T2.WaitFor;
  T1.Free; T2.Free;

  Writeln('示例完成。');
end.

