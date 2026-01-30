unit Test_threadpool_caller_runs_race;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

implementation

procedure Busy(const MS: Cardinal); inline;
var
  T0: QWord;
begin
  T0 := GetTickCount64;
  while (GetTickCount64 - T0) < MS do ;
end;

// 测试类：遵循规范 TTestCase_类名称
type
  TTestCase_ThreadPool = class(TTestCase)
  published
    procedure Test_CallerRuns_Race_Many_Submissions;
  end;

procedure TTestCase_ThreadPool.Test_CallerRuns_Race_Many_Submissions;
const
  Core = 1; MaxThreads = 1; KeepMs = 60000; QueueCap = 32; // 小队列以更易触发背压
var
  P: IThreadPool;
  Futures: array of IFuture;
  SubmitCount, DoneCount: Integer;
  CallerExecCount: Integer;
  CallerId: TThreadID;
  I: Integer;
begin
  P := CreateThreadPool(Core, MaxThreads, KeepMs, QueueCap, TRejectPolicy.rpCallerRuns);
  try
    CallerId := GetCurrentThreadId;
    SubmitCount := 200;
    SetLength(Futures, SubmitCount);
    DoneCount := 0; CallerExecCount := 0;

    // 先占满工作线程，制造持续背压
    Futures[0] := P.Submit(function(): Boolean
    begin
      Busy(200);
      InterlockedIncrement(DoneCount);
      Result := True;
    end);

    // 并发快速提交其余任务，部分将以 CallerRuns 执行
    for I := 1 to SubmitCount-1 do
    begin
      Futures[I] := P.Submit(function(): Boolean
      var
        ExecId: TThreadID;
      begin
        ExecId := GetCurrentThreadId;
        if ExecId = CallerId then InterlockedIncrement(CallerExecCount);
        InterlockedIncrement(DoneCount);
        Result := True;
      end);
    end;

    // 等全部完成（宽松 5s）
    if not Join(Futures, 5000) then
      raise Exception.Create('Join timeout in CallerRuns race');

    AssertEquals('all submitted tasks should complete', SubmitCount, DoneCount);
    AssertTrue('some tasks should execute in caller thread (CallerRuns)', CallerExecCount > 0);
  finally
    P.Shutdown; P.AwaitTermination(3000);
  end;
end;

initialization
  // 注册整个测试类
  RegisterTest(TTestCase_ThreadPool);

end.
