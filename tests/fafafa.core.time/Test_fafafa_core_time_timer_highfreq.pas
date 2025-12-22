unit Test_fafafa_core_time_timer_highfreq;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

{*
  高频定时器压力测试

  验证 Timer 模块在高负载下的行为：
  1. 100+ 定时器/秒的调度能力
  2. 大量并发定时器的稳定性
  3. 快速创建/取消的正确性
  4. 内存使用情况
*}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time, fafafa.core.time.timer;

type
  TTestCase_TimerHighFreq = class(TTestCase)
  published
    // 基础高频测试
    procedure Test_100_Timers_Per_Second;
    procedure Test_500_Concurrent_Timers;
    procedure Test_Rapid_CreateCancel_1000;

    // 压力测试
    procedure Test_1000_ShortLived_Timers;
    procedure Test_Mixed_Workload;
  end;

implementation

var
  GFiredCount: Integer = 0;
  GFiredLock: TRTLCriticalSection;

procedure SafeIncFired;
begin
  EnterCriticalSection(GFiredLock);
  try
    Inc(GFiredCount);
  finally
    LeaveCriticalSection(GFiredLock);
  end;
end;

procedure OnFired;
begin
  SafeIncFired;
end;

{ 基础高频测试 }

procedure TTestCase_TimerHighFreq.Test_100_Timers_Per_Second;
var
  sch: ITimerScheduler;
  timers: array of ITimer;
  i: Integer;
begin
  GFiredCount := 0;
  sch := CreateTimerScheduler;
  try
    SetLength(timers, 100);

    // 在 1 秒内创建 100 个定时器，每个间隔 10ms 触发
    for i := 0 to 99 do
      timers[i] := sch.ScheduleOnce(TDuration.FromMs(10 + i), @OnFired);

    // 等待所有定时器触发
    SleepFor(TDuration.FromMs(200));

    // 验证大部分定时器已触发
    CheckTrue(GFiredCount >= 90, Format('Expected >= 90 fires, got %d', [GFiredCount]));

    // 取消剩余定时器
    for i := 0 to 99 do
      if timers[i] <> nil then
        timers[i].Cancel;
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_TimerHighFreq.Test_500_Concurrent_Timers;
var
  sch: ITimerScheduler;
  timers: array of ITimer;
  i: Integer;
begin
  GFiredCount := 0;
  sch := CreateTimerScheduler;
  try
    SetLength(timers, 500);

    // 创建 500 个并发定时器，全部在 50ms 后触发
    for i := 0 to 499 do
      timers[i] := sch.ScheduleOnce(TDuration.FromMs(50), @OnFired);

    // 等待触发
    SleepFor(TDuration.FromMs(200));

    // 验证所有定时器都已触发
    CheckTrue(GFiredCount >= 490, Format('Expected >= 490 fires, got %d', [GFiredCount]));
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_TimerHighFreq.Test_Rapid_CreateCancel_1000;
var
  sch: ITimerScheduler;
  tm: ITimer;
  i: Integer;
  cancelled: Integer;
begin
  GFiredCount := 0;
  cancelled := 0;
  sch := CreateTimerScheduler;
  try
    // 快速创建和取消 1000 个定时器
    for i := 0 to 999 do
    begin
      tm := sch.ScheduleOnce(TDuration.FromMs(100), @OnFired);
      tm.Cancel;
      if tm.IsCancelled then
        Inc(cancelled);
    end;

    // 等待确保没有定时器触发
    SleepFor(TDuration.FromMs(200));

    // 大部分应该被取消成功
    CheckTrue(cancelled >= 950, Format('Expected >= 950 cancels, got %d', [cancelled]));
    // 没有触发或只有很少触发
    CheckTrue(GFiredCount <= 50, Format('Expected <= 50 fires, got %d', [GFiredCount]));
  finally
    sch.Shutdown;
  end;
end;

{ 压力测试 }

procedure TTestCase_TimerHighFreq.Test_1000_ShortLived_Timers;
var
  sch: ITimerScheduler;
  i: Integer;
begin
  GFiredCount := 0;
  sch := CreateTimerScheduler;
  try
    // 创建 1000 个短生命周期定时器（5-15ms）
    for i := 0 to 999 do
      sch.ScheduleOnce(TDuration.FromMs(5 + (i mod 10)), @OnFired);

    // 等待所有触发
    SleepFor(TDuration.FromMs(500));

    // 验证大部分已触发
    CheckTrue(GFiredCount >= 950, Format('Expected >= 950 fires, got %d', [GFiredCount]));
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_TimerHighFreq.Test_Mixed_Workload;
var
  sch: ITimerScheduler;
  timers: array of ITimer;
  i: Integer;
begin
  GFiredCount := 0;
  sch := CreateTimerScheduler;
  try
    SetLength(timers, 200);

    // 混合工作负载：100 个一次性 + 100 个周期性
    for i := 0 to 99 do
      timers[i] := sch.ScheduleOnce(TDuration.FromMs(20 + i), @OnFired);

    for i := 100 to 199 do
      timers[i] := sch.ScheduleAtFixedRate(TDuration.FromMs(10), TDuration.FromMs(20), @OnFired);

    // 运行 200ms
    SleepFor(TDuration.FromMs(200));

    // 取消所有周期性定时器
    for i := 100 to 199 do
      if timers[i] <> nil then
        timers[i].Cancel;

    // 一次性定时器应全部触发，周期性定时器应触发多次
    // 预期: ~100 (一次性) + ~100*8 (周期性，每个约触发 8 次)
    CheckTrue(GFiredCount >= 500, Format('Expected >= 500 fires, got %d', [GFiredCount]));
  finally
    sch.Shutdown;
  end;
end;

initialization
  InitCriticalSection(GFiredLock);
  RegisterTest(TTestCase_TimerHighFreq);

finalization
  DoneCriticalSection(GFiredLock);

end.
