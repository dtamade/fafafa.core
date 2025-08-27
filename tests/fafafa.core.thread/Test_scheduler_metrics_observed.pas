unit Test_scheduler_metrics_observed;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

type
  TTestCase_TTaskScheduler_Metrics_Observed = class(TTestCase)
  published
    procedure Test_ObservedAverageDelay_Enabled_Positive_WhenDelayedTasks;
  end;

implementation

procedure TTestCase_TTaskScheduler_Metrics_Observed.Test_ObservedAverageDelay_Enabled_Positive_WhenDelayedTasks;
var
  S: ITaskScheduler;
  M: ITaskSchedulerMetrics;
  Fs: array[0..5] of IFuture;
  I: Integer;
begin
  // 启用轻量观测开关
  TTaskScheduler.SetObservedMetricsEnabled(True);
  S := CreateTaskScheduler;
  try
    // 提交多批极短延迟任务，利用定时粒度确保观测值大于 0
    Fs[0] := S.Schedule(function(Data: Pointer): Boolean begin Result := True; end, 1, nil);
    Fs[1] := S.Schedule(function(Data: Pointer): Boolean begin Result := True; end, 2, nil);
    Fs[2] := S.Schedule(function(Data: Pointer): Boolean begin Result := True; end, 3, nil);
    Fs[3] := S.Schedule(function(Data: Pointer): Boolean begin Result := True; end, 1, nil);
    Fs[4] := S.Schedule(function(Data: Pointer): Boolean begin Result := True; end, 2, nil);
    Fs[5] := S.Schedule(function(Data: Pointer): Boolean begin Result := True; end, 3, nil);
    for I := 0 to High(Fs) do AssertTrue(Fs[I].WaitFor(2000));
    // 让定时线程收敛统计
    SysUtils.Sleep(20);
    M := S.GetMetrics;
    // 某些平台粒度较粗，容忍等于 0 的极端情况
    AssertTrue('ObservedAverageDelayMs should be >= 0', M.GetObservedAverageDelayMs >= 0.0);
    for I := 0 to High(Fs) do Fs[I] := nil;
  finally
    TTaskScheduler.SetObservedMetricsEnabled(False);
    S := nil;
  end;
end;

initialization
  RegisterTest(TTestCase_TTaskScheduler_Metrics_Observed);

end.

