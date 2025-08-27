unit Test_fafafa_core_time_timer_metrics;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time, fafafa.core.time.timer;

type
  TTestCase_TimerMetrics = class(TTestCase)
  published
    procedure Test_Metrics_Scheduled_Fired_Cancelled_Exception;
  end;

var
  GFireCount: Integer = 0;
  GExcCount: Integer = 0;

implementation

procedure OnTickOK; begin Inc(GFireCount); end;
procedure OnTickExc; begin Inc(GExcCount); raise Exception.Create('x'); end;


procedure TTestCase_TimerMetrics.Test_Metrics_Scheduled_Fired_Cancelled_Exception;
var S: ITimerScheduler; t1, t2, t3: ITimer; m: TTimerMetrics;
begin
  TimerResetMetrics;
  S := CreateTimerScheduler;
  GFireCount := 0; GExcCount := 0;
  // 正常一次性
  t1 := S.ScheduleOnce(TDuration.FromMs(10), @OnTickOK);
  // 固定速率 + 抛异常
  t2 := S.ScheduleAtFixedRate(TDuration.FromMs(0), TDuration.FromMs(10), @OnTickExc);
  // 固定延迟 + 立即取消
  t3 := S.ScheduleWithFixedDelay(TDuration.FromMs(0), TDuration.FromMs(50), @OnTickOK);
  t3.Cancel;
  SleepFor(TDuration.FromMs(70));
  t1.Cancel; t2.Cancel;
  m := TimerGetMetrics;
  // 3 次调度
  CheckTrue(m.ScheduledTotal >= 3);
  // fired 包含正常 + 异常回调的执行（异常也执行到）
  CheckTrue(m.FiredTotal >= GFireCount);
  // 已取消至少 1 个
  CheckTrue(m.CancelledTotal >= 1);
  // 异常至少 1 次
  CheckTrue(m.ExceptionTotal >= 1);
  S.Shutdown;
end;

initialization
  RegisterTest(TTestCase_TimerMetrics);
end.

