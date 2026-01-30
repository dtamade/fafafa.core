unit Test_threadpool_policy_queue0;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

type
  { TTestCase_TThreadPoolPolicy_Queue0 }
  TTestCase_TThreadPoolPolicy_Queue0 = class(TTestCase)
  private
    FPool: IThreadPool;
    procedure DoSubmitAbortQueue0;
  published
    procedure Test_RejectPolicy_Abort_Queue0;
    procedure Test_RejectPolicy_CallerRuns_Queue0;
  end;

implementation

procedure TTestCase_TThreadPoolPolicy_Queue0.DoSubmitAbortQueue0;
begin
  // 第一次提交占用工作线程（或直接触发拒绝，均可）
  FPool.Submit(function(): Boolean
  var T0: QWord;
  begin
    T0 := GetTickCount64;
    while (GetTickCount64 - T0) < 100 do ;
    Result := True;
  end);
  // 第二次提交：若前一任务已占用线程且队列=0，则应被拒绝并抛出 EThreadPoolError
  FPool.Submit(function(): Boolean begin Result := True; end);
end;

procedure TTestCase_TThreadPoolPolicy_Queue0.Test_RejectPolicy_Abort_Queue0;
var
  RunM: TRunMethod;
begin
  FPool := CreateThreadPool(1, 1, 60000, 0, TRejectPolicy.rpAbort);
  try
    RunM := @DoSubmitAbortQueue0;
    AssertException(EThreadPoolError, RunM);
  finally
    if Assigned(FPool) then begin FPool.Shutdown; FPool.AwaitTermination(2000); end;
    FPool := nil;
  end;
end;

procedure TTestCase_TThreadPoolPolicy_Queue0.Test_RejectPolicy_CallerRuns_Queue0;
var
  LPool: IThreadPool;
  CallerId, ExecId: TThreadID;
begin
  LPool := CreateThreadPool(1, 1, 60000, 0, TRejectPolicy.rpCallerRuns);
  try
    CallerId := GetCurrentThreadId;
    LPool.Submit(function(): Boolean
    var T0: QWord;
    begin
      T0 := GetTickCount64;
      while (GetTickCount64 - T0) < 100 do ;
      Result := True;
    end);
    LPool.Submit(function(): Boolean
    begin
      ExecId := GetCurrentThreadId;
      Result := True;
    end);
    AssertEquals('CallerRuns should execute in caller', PtrUInt(CallerId), PtrUInt(ExecId));
  finally
    LPool.Shutdown; LPool.AwaitTermination(2000);
  end;
end;

initialization
  RegisterTest(TTestCase_TThreadPoolPolicy_Queue0);

end.

