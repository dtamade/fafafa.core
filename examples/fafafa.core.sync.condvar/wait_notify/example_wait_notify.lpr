program example_wait_notify;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
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
      Cond.Wait(Mutex);
    Writeln('[工作线程] 收到通知，开始工作');
  finally
    Mutex.Release;
  end;
end;

begin
  Mutex := MakeMutex;
  Cond := MakeCondVar;
  Ready := False;

  // 注意：某些环境下需要在 uses 中引入 cthreads 以启用线程支持
  with TThread.CreateAnonymousThread(@Worker) do
  begin
    FreeOnTerminate := False;
    Start;

    Sleep(100);
    Mutex.Acquire;
    try
      Ready := True;
      Cond.Signal;
      Writeln('[主线程] 已发出通知');
    finally
      Mutex.Release;
    end;

    WaitFor;
    Free;
  end;

  Writeln('示例完成。');
end.

