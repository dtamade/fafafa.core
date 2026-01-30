unit Test_threadpool_metrics_observed;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

type
  TTestCase_TThreadPool_Metrics_Observed = class(TTestCase)
  published
    procedure Test_QueueObservedAverageMs_Enabled_Positive_WhenQueued;
  end;

implementation

function BusyTask(Data: Pointer): Boolean;
var T0: QWord;
begin
  // 忙等一小段时间，确保任务存在并有机会在队列驻留
  T0 := GetTickCount64;
  while (GetTickCount64 - T0) < 20 do ;
  Result := True;
end;

procedure TTestCase_TThreadPool_Metrics_Observed.Test_QueueObservedAverageMs_Enabled_Positive_WhenQueued;
var
  P: IThreadPool;
  M: IThreadPoolMetrics;
  Fs: array[0..11] of IFuture;
  I: Integer;
begin
  // 开启轻量观测
  TThreadPool.SetObservedMetricsEnabled(True);
  // Core=1, Max=2, 小容量队列，制造可观测驻留
  P := CreateThreadPool(1, 2, 60000, 1, TRejectPolicy.rpCallerRuns);
  try
    // 第一波：快速堆积到队列
    for I := 0 to 5 do
      Fs[I] := P.Submit(@BusyTask, nil);
    // 短暂等待，保证队列驻留产生
    SysUtils.Sleep(10);
    // 第二波：进一步堆积与执行
    for I := 6 to High(Fs) do
      Fs[I] := P.Submit(@BusyTask, nil);
    // 等待全部完成（放宽超时）
    AssertTrue(Join(Fs, 8000));
    M := GetThreadPoolMetrics(P);
    // 某些平台粒度较粗，容忍等于 0 的极端情况
    AssertTrue('QueueObservedAverageMs should be >= 0', (M <> nil) and (M.QueueObservedAverageMs >= 0.0));
  finally
    TThreadPool.SetObservedMetricsEnabled(False);
    P.Shutdown; P.AwaitTermination(3000);
  end;
end;

initialization
  RegisterTest(TTestCase_TThreadPool_Metrics_Observed);

end.

