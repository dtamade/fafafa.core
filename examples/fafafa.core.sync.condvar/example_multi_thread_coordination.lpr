program example_multi_thread_coordination;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  Classes, SysUtils,
  fafafa.core.sync.mutex, fafafa.core.sync.condvar;

var
  Mutex: IMutex;
  Cond: IConditionVariable;
  Arrived: Integer;
  Need: Integer = 3;

procedure Worker(const Name: String);
begin
  // 做一些准备工作
  Sleep(Random(120)+30);

  Mutex.Acquire;
  try
    Inc(Arrived);
    Writeln('[', Name, '] 抵达屏障 (', Arrived, '/', Need, ')');
    if Arrived = Need then
      Cond.Broadcast
    else
      while Arrived < Need do
        Cond.Wait(Mutex);
    Writeln('[', Name, '] 通过屏障');
  finally
    Mutex.Release;
  end;
end;

var T1,T2,T3: TThread;
begin
  Randomize;
  Mutex := MakeMutex;
  Cond := MakeConditionVariable;
  Arrived := 0;

  T1 := TThread.CreateAnonymousThread(@procedure begin Worker('T1'); end);
  T2 := TThread.CreateAnonymousThread(@procedure begin Worker('T2'); end);
  T3 := TThread.CreateAnonymousThread(@procedure begin Worker('T3'); end);
  T1.Start; T2.Start; T3.Start;
  T1.WaitFor; T2.WaitFor; T3.WaitFor;
  T1.Free; T2.Free; T3.Free;

  Writeln('示例完成。');
end.

