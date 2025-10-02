program example_wait_notify;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  Classes, SysUtils,
  fafafa.core.sync.mutex, fafafa.core.sync.condvar;

var
  Mutex: IMutex;
  Cond: ICondVar;
  Ready: Boolean;

procedure Worker;
begin
  Mutex.Acquire;
  try
    while not Ready do
      Cond.Wait(Mutex); // 无超时等待
    Writeln('[工作线程] 收到通知，开始工作');
  finally
    Mutex.Release;
  end;
end;

begin
  Mutex := MakeMutex;
  Cond := MakeCondVar;
  Ready := False;

  with TThread.CreateAnonymousThread(@Worker) do
  begin
    FreeOnTerminate := False;
    Start;
    Sleep(100);

    Mutex.Acquire;
    try
      Ready := True;
      Cond.Signal; // 通知单个等待者
      Writeln('[主线程] 已发出通知');
    finally
      Mutex.Release;
    end;

    WaitFor;
    Free;
  end;

  Writeln('示例完成。');
end.

