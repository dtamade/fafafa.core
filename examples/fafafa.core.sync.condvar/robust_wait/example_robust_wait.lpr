program example_robust_wait;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils, DateUtils,
  fafafa.core.sync.mutex, fafafa.core.sync.condvar;

var
  M: IMutex;
  CV: IConditionVariable;
  Ready: Boolean;
  Attempts: Integer;

procedure Worker;
var deadline: TDateTime; msleft: Integer; woke: Boolean;
begin
  // 尝试在总时限内等待条件成立，每次 Wait 使用短超时，合计重试
  deadline := Now + EncodeTime(0,0,0,2); // 2 秒总期限
  M.Acquire;
  try
    while not Ready do
    begin
      msleft := MilliSecondsBetween(Now, deadline);
      if msleft <= 0 then Break;
      // 每次最多等 100ms，结合剩余时间取较小值
      if msleft > 100 then msleft := 100;
      woke := CV.Wait(M, msleft);
      Inc(Attempts);
      if not woke then
        Writeln('[工作线程] 一次超时重试 (累计=', Attempts, ')');
    end;
    if Ready then
      Writeln('[工作线程] 条件成立，继续工作')
    else
      Writeln('[工作线程] 超过总体时限，放弃等待');
  finally
    M.Release;
  end;
end;

begin
  M := MakeMutex;
  CV := MakeConditionVariable;
  Ready := False; Attempts := 0;

  with TThread.CreateAnonymousThread(@Worker) do
  begin
    FreeOnTerminate := False;
    Start;

    // 主线程模拟延迟，再设置条件并广播
    Sleep(450);
    M.Acquire;
    try
      Ready := True;
      CV.Broadcast;
      Writeln('[主线程] 设置条件并广播');
    finally
      M.Release;
    end;

    WaitFor;
    Free;
  end;

  Writeln('健壮等待示例完成。');
end.

