program example_thread_scheduler_cancel_timeout;
{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.thread;

type
  PTaskParam = ^TTaskParam;
  TTaskParam = record
    Token: ICancellationToken;
    DurMs: Integer;
  end;

function Work(Data: Pointer): Boolean;
var
  P: PTaskParam;
  elapsed: Integer;
begin
  Result := False;
  P := PTaskParam(Data);
  elapsed := 0;
  while elapsed < P^.DurMs do
  begin
    Sleep(20);
    Inc(elapsed, 20);
    if Assigned(P^.Token) and P^.Token.IsCancellationRequested then
    begin
      Writeln('[work] cancelled at ', elapsed, 'ms');
      Exit(False);
    end;
  end;
  Writeln('[work] completed');
  Result := True;
end;

procedure Demo_Scheduler_Cancel_Timeout;
var
  Sch: ITaskScheduler;
  Cts: ICancellationTokenSource;
  P: PTaskParam;
  F: IFuture;
  ok: Boolean;
begin
  Writeln('Scenario: Scheduler cancel and timeout');
  Sch := CreateTaskScheduler;
  Cts := CreateCancellationTokenSource;
  New(P); P^.Token := Cts.Token; P^.DurMs := 2000;
  try
    // 延迟 200ms 调度任务，允许通过 Token 取消
    F := Sch.Schedule(@Work, 200, Cts.Token, P);

    // 等待 100ms 即取消（任务尚未开始或刚开始）
    Sleep(100);
    Cts.Cancel;

    // 使用 FutureWaitOrCancel 等待结果（应返回 False）
    ok := FutureWaitOrCancel(F, Cts.Token, 1000);
    Writeln('FutureWaitOrCancel -> ', ok);
  finally
    if Assigned(P) then begin P^.Token := nil; Dispose(P); end;
    Sch.Shutdown;
    Cts := nil;
  end;
end;

begin
  Demo_Scheduler_Cancel_Timeout;
end.

