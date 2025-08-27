unit Test_cancel_token_postsubmit;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

Type
  TTestCase_CancelToken_PostSubmit = class(TTestCase)
  published
    procedure Test_ThreadPool_Submit_TokenCancel_After_Submit_Pending;
    procedure Test_Scheduler_TokenCancel_After_Schedule_Before_Due;
  end;

implementation

function SleepWork(Data: Pointer): Boolean;
begin
  SysUtils.Sleep(NativeUInt(Data));
  Result := True;
end;

function MarkTrue(Data: Pointer): Boolean;
begin
  if Assigned(Data) then PBoolean(Data)^ := True;
  Result := True;
end;

procedure TTestCase_CancelToken_PostSubmit.Test_ThreadPool_Submit_TokenCancel_After_Submit_Pending;
var P: IThreadPool; Cts: ICancellationTokenSource; F1,F2: IFuture; Executed: Boolean; ok: Boolean;
begin
  Executed := False;
  P := CreateFixedThreadPool(1);
  try
    // 占住唯一 worker，保证第二个任务处于排队等待
    F1 := P.Submit(@SleepWork, nil, Pointer(200));
    Cts := CreateCancellationTokenSource;
    F2 := P.Submit(@MarkTrue, Cts.Token, @Executed);
    // 稍等让 F2 入队，然后取消 Token
    SysUtils.Sleep(30);  // 给队列入队更充足的时间，降低竞态对预期的影响
    Cts.Cancel;
    // 等待或取消：应由 Token 提前返回 False，且不执行
    ok := FutureWaitOrCancel(F2, Cts.Token, 500);
    AssertFalse('token cancel should win', ok);
    AssertFalse('pending task should not execute when token cancelled', Executed);
    // 收尾
    AssertTrue('first work should complete', F1.WaitFor(3000));
  finally
    P.Shutdown; P.AwaitTermination(2000);
  end;
end;

procedure TTestCase_CancelToken_PostSubmit.Test_Scheduler_TokenCancel_After_Schedule_Before_Due;
var S: ITaskScheduler; Cts: ICancellationTokenSource; F: IFuture; Executed: Boolean; ok: Boolean;
begin
  Executed := False;
  S := CreateTaskScheduler;
  try
    Cts := CreateCancellationTokenSource;
    // 计划 150ms 后执行，随后 20ms 内取消
    F := S.Schedule(@MarkTrue, 150, Cts.Token, @Executed);
    AssertTrue('future should be created', Assigned(F));
    SysUtils.Sleep(20);
    Cts.Cancel;
    ok := FutureWaitOrCancel(F, Cts.Token, 500);
    AssertFalse('token cancel should return false', ok);
    // 额外等待，确保不会误执行
    SysUtils.Sleep(200);
    AssertFalse('scheduled task should not execute when token cancelled', Executed);
  finally
    S.Shutdown;
  end;
end;

initialization
  RegisterTest(TTestCase_CancelToken_PostSubmit);

end.

