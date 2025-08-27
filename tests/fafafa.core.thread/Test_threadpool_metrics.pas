unit Test_threadpool_metrics;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

type
  { TTestCase_TThreadPool_Metrics }
  TTestCase_TThreadPool_Metrics = class(TTestCase)
  published
    procedure Test_Metrics_Submit_Complete_Abort;
    procedure Test_Metrics_Pool_Active_Queue;
  end;

implementation

procedure TTestCase_TThreadPool_Metrics.Test_Metrics_Submit_Complete_Abort;
var
  LPool: IThreadPool;
  LMetrics: IThreadPoolMetrics;
  I: Integer;
  LOk: Integer;
begin
  // 固定 1 核心 1 最大，队列容量为 1，策略 Abort
  LPool := CreateThreadPool(1, 1, 60000, 1, TRejectPolicy.rpAbort);
  LMetrics := LPool.GetMetrics;
  LOk := 0;

  // 第一个任务占满工作线程
  LPool.Submit(function(): Boolean
  var T0: QWord;
  begin
    T0 := GetTickCount64;
    while (GetTickCount64 - T0) < 100 do ;
    InterlockedIncrement(LOk);
    Result := True;
  end);

  // 第二个任务入队（容量=1），第三个应被拒绝
  LPool.Submit(function(): Boolean
  begin
    InterlockedIncrement(LOk);
    Result := True;
  end);

  try
    LPool.Submit(function(): Boolean
    begin
      InterlockedIncrement(LOk);
      Result := True;
    end);
    Fail('应当抛出 EThreadPoolError，但没有抛出');
  except
    on E: Exception do ; // 预期
  end;

  // 等待一会儿让前 2 个任务都完成
  SysUtils.Sleep(200);

  // 校验指标：Submitted 至少 3（提交 3 次，无论是否拒绝）
  AssertTrue('Submitted >= 3', LMetrics.TotalSubmitted >= 3);
  // Completed 至少 2（执行成功的任务数）
  AssertTrue('Completed >= 2', LMetrics.TotalCompleted >= 2);
  // Rejected 至少 1（第三个被拒绝）
  AssertTrue('Rejected >= 1', LMetrics.TotalRejected >= 1);

  // 关闭线程池，避免泄漏
  LPool.Shutdown;
  LPool.AwaitTermination(3000);
end;

procedure TTestCase_TThreadPool_Metrics.Test_Metrics_Pool_Active_Queue;
var
  LPool: IThreadPool;
  LMetrics: IThreadPoolMetrics;
  LStart: QWord;
  I: Integer;
begin
  // 建立固定大小线程池，不限制队列（-1）
  LPool := CreateThreadPool(2, 2, 60000, -1, TRejectPolicy.rpAbort);
  LMetrics := LPool.GetMetrics;

  // 提交 4 个短任务，观察 Pool/Active/Queue 的合理范围
  for I := 1 to 4 do
    LPool.Submit(function(): Boolean
    begin
      SysUtils.Sleep(10);
      Result := True;
    end);

  // 立即读取指标，Active 应该 >=1（已经开始执行），PoolSize 应该 =2
  AssertTrue('PoolSize=2', LPool.PoolSize = 2);
  AssertTrue('ActiveCount>=1', LPool.ActiveCount >= 1);
  AssertTrue('QueueSize>=0', LPool.QueueSize >= 0);

  // 等待任务都完成
  SysUtils.Sleep(200);
  AssertTrue('QueueSize=0', LPool.QueueSize = 0);

  // 关闭线程池
  LPool.Shutdown;
  LPool.AwaitTermination(3000);
end;

initialization
  RegisterTest(TTestCase_TThreadPool_Metrics);

end.

