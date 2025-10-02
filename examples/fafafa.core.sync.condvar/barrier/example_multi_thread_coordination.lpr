program example_multi_thread_coordination;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.mutex, fafafa.core.sync.condvar;

var
  Mutex: IMutex;
  Cond: ICondVar;
  Arrived: Integer;
  Need: Integer = 3;

procedure Worker(const Name: String);
begin
  // 做一些准备工作（随机耗时）
  Sleep(Random(120)+30);

  Mutex.Acquire;
  try
    Inc(Arrived);
    Writeln('[', Name, '] 抵达屏障 (', Arrived, '/', Need, ')');
    if Arrived = Need then
      Cond.Broadcast
    else
      while Arrived < Need do
        Cond.Wait(Mutex); // 等待其他线程到齐
    Writeln('[', Name, '] 通过屏障');
  finally
    Mutex.Release;
  end;
end;

procedure Worker1; begin Worker('T1'); end;
procedure Worker2; begin Worker('T2'); end;
procedure Worker3; begin Worker('T3'); end;

var T1,T2,T3: TThread;
begin
  Randomize;
  Mutex := MakeMutex;
  Cond := MakeCondVar;
  Arrived := 0;

  T1 := TThread.CreateAnonymousThread(@Worker1);
  T2 := TThread.CreateAnonymousThread(@Worker2);
  T3 := TThread.CreateAnonymousThread(@Worker3);
  T1.Start; T2.Start; T3.Start;
  T1.WaitFor; T2.WaitFor; T3.WaitFor;
  T1.Free; T2.Free; T3.Free;

  Writeln('示例完成。');
end.

