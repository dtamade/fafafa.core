unit Test_scheduler_metrics;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

type
  TTestCase_TTaskScheduler_Metrics = class(TTestCase)
  published
    procedure Test_Metrics_Scheduled_Executed;
    procedure Test_Metrics_Cancelled_And_Active;
  end;

implementation

procedure TTestCase_TTaskScheduler_Metrics.Test_Metrics_Scheduled_Executed;
var
  S: ITaskScheduler;
  M: ITaskSchedulerMetrics;
  F1, F2, F3: IFuture;
  C: Integer;
begin
  S := CreateTaskScheduler;
  C := 0;
  F1 := S.Schedule(function(Data: Pointer): Boolean begin Inc(C); Result := True; end, 50, nil);
  F2 := S.Schedule(function(Data: Pointer): Boolean begin Inc(C); Result := True; end, 60, nil);
  F3 := S.Schedule(function(Data: Pointer): Boolean begin Inc(C); Result := True; end, 70, nil);
  AssertTrue(F1.WaitFor(2000));
  AssertTrue(F2.WaitFor(2000));
  AssertTrue(F3.WaitFor(2000));
  M := S.GetMetrics;
  AssertTrue('TotalScheduled>=3', M.GetTotalScheduled >= 3);
  AssertTrue('TotalExecuted>=3', M.GetTotalExecuted >= 3);
  AssertEquals('ActiveTasks should be 0', 0, M.GetActiveTasks);
  S.Shutdown;
end;

procedure TTestCase_TTaskScheduler_Metrics.Test_Metrics_Cancelled_And_Active;
var
  S: ITaskScheduler;
  M: ITaskSchedulerMetrics;
  F1, F2: IFuture;
  Flag: Boolean;
begin
  S := CreateTaskScheduler;
  Flag := False;
  F1 := S.Schedule(function(Data: Pointer): Boolean begin PBoolean(Data)^ := True; Result := True; end, 200, @Flag);
  F2 := S.Schedule(function(Data: Pointer): Boolean begin Result := True; end, 200, nil);
  // 取消一个
  AssertTrue(F2.Cancel);
  // 等待另一个执行
  AssertTrue(F1.WaitFor(2000));
  // 检查指标
  M := S.GetMetrics;
  AssertTrue('TotalScheduled>=2', M.GetTotalScheduled >= 2);
  AssertTrue('TotalCancelled>=1', M.GetTotalCancelled >= 1);
  AssertTrue('TotalExecuted>=1', M.GetTotalExecuted >= 1);
  AssertEquals('ActiveTasks should be 0', 0, M.GetActiveTasks);
  S.Shutdown;
end;

initialization
  RegisterTest(TTestCase_TTaskScheduler_Metrics);

end.

