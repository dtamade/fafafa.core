unit Test_threadpool_metrics_more;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

type
  { TTestCase_TThreadPool_Metrics_More }
  TTestCase_TThreadPool_Metrics_More = class(TTestCase)
  published
    procedure Test_CallerRuns_AtMax_Increments_Metric;
    procedure Test_KeepAlive_Shrink_Metrics_Basic;
  end;

implementation

procedure Busy(const MS: Cardinal);
var T0: QWord; begin T0 := GetTickCount64; while (GetTickCount64 - T0) < MS do ; end;

procedure TTestCase_TThreadPool_Metrics_More.Test_CallerRuns_AtMax_Increments_Metric;
var
  P: IThreadPool;
  M: IThreadPoolMetrics;
  CallerId, ExecId: TThreadID;
  AtMaxBefore, AtMaxAfter: Int64;
  F1, F2: IFuture;
  TStart: QWord;
  Latch: ICountDownLatch;
begin
  // Core=1, Max=1, 大队列容量，避免触发“队列满”的 CallerRuns 分支，确保命中 @max 分支
  P := CreateThreadPool(1, 1, 60000, 1024, TRejectPolicy.rpCallerRuns);
  try
    M := GetThreadPoolMetrics(P);
    AtMaxBefore := 0;
    if M <> nil then AtMaxBefore := M.CallerRunsAtMax;

    // 占满唯一工作线程，并用门闩确保其已开始执行
    Latch := CreateCountDownLatch(1);
    F1 := P.Submit(function(): Boolean
    begin
      Latch.CountDown; // 标记 F1 已进入执行
      Busy(150);
      Result := True;
    end);

    // 等待 F1 已进入执行状态，确保此时 Active=1
    AssertTrue('latch wait', Latch.Await(1000));

    // 第二个提交：在达到 Max 时触发 CallerRuns（应在调用线程执行）
    CallerId := GetCurrentThreadId;
    ExecId := 0;
    F2 := P.Submit(function(): Boolean
    begin
      ExecId := GetCurrentThreadId;
      Result := True;
    end);

    // 等待 CallerRuns 任务快速完成并记录线程ID
    TStart := GetTickCount64;
    while (GetTickCount64 - TStart) < 1000 do
    begin
      if ExecId <> 0 then Break;
      SysUtils.Sleep(5);
    end;

    AssertEquals('CallerRuns(@max) should execute in caller thread', PtrUInt(CallerId), PtrUInt(ExecId));

    // 断言指标增长
    M := GetThreadPoolMetrics(P);
    AtMaxAfter := 0;
    if M <> nil then AtMaxAfter := M.CallerRunsAtMax;
    AssertTrue('CallerRunsAtMax should increment', AtMaxAfter >= AtMaxBefore + 1);

    // 收尾
    AssertTrue(F1.WaitFor(2000));
    AssertTrue(F2.WaitFor(2000));
  finally
    P.Shutdown; P.AwaitTermination(3000);
  end;
end;

procedure TTestCase_TThreadPool_Metrics_More.Test_KeepAlive_Shrink_Metrics_Basic;
var
  P: IThreadPool;
  M: IThreadPoolMetrics;
  Keep: Cardinal;
  I: Integer;
  Attempts, SuccImm, SuccTo: Int64;
  Core: Integer;
  t0: QWord;
begin
  Core := 1; Keep := 200;
  P := CreateThreadPool(Core, 3, Keep, 64, TRejectPolicy.rpAbort);
  try
    // 触发扩张
    for I := 1 to 6 do
      P.Submit(function(): Boolean begin Busy(150); Result := True; end);

    // 等待扩张与任务执行（轮询，最多 ~1s）
    t0 := GetTickCount64;
    while (P.PoolSize < 2) and ((GetTickCount64 - t0) <= 1000) do
      SysUtils.Sleep(10);
    AssertTrue('pool should expand beyond core', P.PoolSize >= 2);

    // 等空闲并超过 KeepAlive
    SysUtils.Sleep(Keep + 250);

    // 指标断言
    M := GetThreadPoolMetrics(P);
    Attempts := 0; SuccImm := 0; SuccTo := 0;
    if M <> nil then
    begin
      Attempts := M.KeepAliveShrinkAttempts;
      SuccImm := M.KeepAliveShrinkImmediate;
      SuccTo := M.KeepAliveShrinkTimeout;
    end;
    AssertTrue('KeepAliveShrinkAttempts>0', Attempts > 0);
    AssertTrue('Shrink success (immediate or timeout) > 0', (SuccImm > 0) or (SuccTo > 0));
    AssertEquals('pool should shrink back to core', Core, P.PoolSize);
  finally
    P.Shutdown; P.AwaitTermination(3000);
  end;
end;

initialization
  RegisterTest(TTestCase_TThreadPool_Metrics_More);

end.

