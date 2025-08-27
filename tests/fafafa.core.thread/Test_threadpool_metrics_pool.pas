unit Test_threadpool_metrics_pool;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

type
  TTestCase_TThreadPool_Metrics_Pool = class(TTestCase)
  published
    procedure Test_TaskItemPool_Counters_Basic;
  end;

implementation

procedure TTestCase_TThreadPool_Metrics_Pool.Test_TaskItemPool_Counters_Basic;
var
  P: IThreadPool;
  M: IThreadPoolMetrics;
  I: Integer;
  F: IFuture;
begin
  // 小型线程池，便于控制
  P := CreateThreadPool(1, 2, 100, 64, TRejectPolicy.rpAbort);

  // 提交多批短任务，促使对象池多次借还
  for I := 1 to 50 do
  begin
    F := P.Submit(function(Data: Pointer): Boolean begin Result := True; end, nil);
    AssertTrue(F.WaitFor(2000));
  end;

  // 拉取指标
  M := GetThreadPoolMetrics(P);
  AssertTrue('PoolHit >= 1', M.TaskItemPoolHit >= 1);
  AssertTrue('PoolReturn >= 1', M.TaskItemPoolReturn >= 1);
  // Miss 至少为 1（首次 New），不强制较大值，避免平台差
  AssertTrue('PoolMiss >= 1', M.TaskItemPoolMiss >= 1);
  // Drop 正常情况下可能为 0（容量足够），只要求 >=0
  AssertTrue('PoolDrop >= 0', M.TaskItemPoolDrop >= 0);

  P.Shutdown;
  P.AwaitTermination(3000);
end;

initialization
  RegisterTest(TTestCase_TThreadPool_Metrics_Pool);

end.

