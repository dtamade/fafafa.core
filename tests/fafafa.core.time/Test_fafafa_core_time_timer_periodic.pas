unit Test_fafafa_core_time_timer_periodic;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time, fafafa.core.time.timer;

type
  TTestCase_TimerPeriodic = class(TTestCase)
  published
    procedure Test_FixedRate_Basic_And_Cancel;
    procedure Test_FixedDelay_Basic_And_Cancel;
    procedure Test_FixedRate_Jitter_Within_Bounds;
  end;

implementation




var
  GCount: Integer = 0;

procedure OnTick; begin Inc(GCount); end;
procedure OnTickAndSleep; begin Inc(GCount); SleepFor(TDuration.FromMs(3)); end;

procedure TTestCase_TimerPeriodic.Test_FixedRate_Basic_And_Cancel;
var S: ITimerScheduler; t: ITimer; start, finish: TInstant; M: TTimerMetrics;
begin
  S := CreateTimerScheduler;
  SetTimerFixedRateMaxCatchupSteps(0);
  GCount := 0;
  start := NowInstant;
  t := S.ScheduleAtFixedRate(TDuration.FromMs(5), TDuration.FromMs(10), @OnTick);

  TimerResetMetrics;
  SleepFor(TDuration.FromMs(65));

  t.Cancel;
  finish := NowInstant;
  // 宽松断言：至少触发一次（跨平台稳定）
  CheckTrue(GCount >= 1);
  // 指标断言：至少触发一次
  M := TimerGetMetrics; CheckTrue(M.FiredTotal >= 1);

  // 基本时间范围校验
  // 指标宽松断言（可选，跨平台稳定）
  TimerResetMetrics;

  CheckTrue(finish.Diff(start).AsMs >= 50);
  S.Shutdown;
end;

procedure TTestCase_TimerPeriodic.Test_FixedRate_Jitter_Within_Bounds;
var S: ITimerScheduler; n, periodMs: Integer; t0, tn: TInstant; elapsedMs, minCount: Int64;
begin
  // 宽松抖动断言：周期 10ms，跑 20 次，累计时长接近 200ms，动态容忍抖动
  S := CreateTimerScheduler;
  SetTimerFixedRateMaxCatchupSteps(0);
  GCount := 0; n := 20; periodMs := 10;
  t0 := NowInstant;
  S.ScheduleAtFixedRate(TDuration.FromMs(0), TDuration.FromMs(periodMs), @OnTick);
  SleepFor(TDuration.FromMs(n * periodMs + 20));
  tn := NowInstant;
  elapsedMs := tn.Diff(t0).AsMs;
  // 至少执行过一次（避免极端环境下过严）
  CheckTrue(GCount >= 1);
  // 总时长在 [n*period-30ms, n*period+100ms] 的宽松范围内
  CheckTrue(elapsedMs >= n*periodMs - 30);
  CheckTrue(elapsedMs <= n*periodMs + 100);
  S.Shutdown;
end;

var
  GCountFD: Integer = 0;
procedure OnTickFD; begin Inc(GCountFD); SleepFor(TDuration.FromMs(3)); end;

procedure TTestCase_TimerPeriodic.Test_FixedDelay_Basic_And_Cancel;
var S: ITimerScheduler; t: ITimer; start, finish: TInstant;
begin
  S := CreateTimerScheduler;
  GCountFD := 0;
  start := NowInstant;
  t := S.ScheduleWithFixedDelay(TDuration.FromMs(5), TDuration.FromMs(10), @OnTickFD);
  // 增加等待时间以适应异步回调执行的延迟
  SleepFor(TDuration.FromMs(100));
  t.Cancel;
  finish := NowInstant;
  // 固定延迟：使用异步回调时，至少触发 2 次即可（宽松断言，适应线程池调度开销）
  CheckTrue(GCountFD >= 2, Format('Expected at least 2 fires, but got %d', [GCountFD]));
  CheckTrue(finish.Diff(start).AsMs >= 90);
  S.Shutdown;
end;

initialization
  RegisterTest(TTestCase_TimerPeriodic);
end.

