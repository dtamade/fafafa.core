unit Test_fafafa_core_time_timer_max_executions;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

{*
  执行次数限制功能测试

  验证 SetMaxExecutions/GetMaxExecutions 功能：
  1. 周期定时器在达到指定执行次数后自动停止
  2. 一次性定时器不支持此功能
  3. 已取消的定时器返回 False
*}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time, fafafa.core.time.timer;

type
  TTestCase_TimerMaxExecutions = class(TTestCase)
  published
    // 基础功能测试
    procedure Test_SetMaxExecutions_PeriodicTimer_ReturnsTrue;
    procedure Test_SetMaxExecutions_OnceTimer_ReturnsFalse;
    procedure Test_SetMaxExecutions_CancelledTimer_ReturnsFalse;
    procedure Test_GetMaxExecutions_ReturnsSetValue;

    // 执行限制测试
    procedure Test_FixedRate_StopsAfterMaxExecutions;
    procedure Test_FixedDelay_StopsAfterMaxExecutions;
    procedure Test_MaxExecutions_Zero_NoLimit;
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

{ 基础功能测试 }

procedure TTestCase_TimerMaxExecutions.Test_SetMaxExecutions_PeriodicTimer_ReturnsTrue;
var
  sch: ITimerScheduler;
  tm: ITimer;
  ok: Boolean;
begin
  sch := CreateTimerScheduler;
  try
    tm := sch.ScheduleAtFixedRate(TDuration.FromMs(1000), TDuration.FromMs(100), @OnFired);
    ok := tm.SetMaxExecutions(5);
    CheckTrue(ok, 'SetMaxExecutions should return True for periodic timer');
    tm.Cancel;
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_TimerMaxExecutions.Test_SetMaxExecutions_OnceTimer_ReturnsFalse;
var
  sch: ITimerScheduler;
  tm: ITimer;
  ok: Boolean;
begin
  sch := CreateTimerScheduler;
  try
    tm := sch.ScheduleOnce(TDuration.FromMs(1000), @OnFired);
    ok := tm.SetMaxExecutions(5);
    CheckFalse(ok, 'SetMaxExecutions should return False for once timer');
    tm.Cancel;
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_TimerMaxExecutions.Test_SetMaxExecutions_CancelledTimer_ReturnsFalse;
var
  sch: ITimerScheduler;
  tm: ITimer;
  ok: Boolean;
begin
  sch := CreateTimerScheduler;
  try
    tm := sch.ScheduleAtFixedRate(TDuration.FromMs(1000), TDuration.FromMs(100), @OnFired);
    tm.Cancel;
    ok := tm.SetMaxExecutions(5);
    CheckFalse(ok, 'SetMaxExecutions should return False for cancelled timer');
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_TimerMaxExecutions.Test_GetMaxExecutions_ReturnsSetValue;
var
  sch: ITimerScheduler;
  tm: ITimer;
  maxExec: QWord;
begin
  sch := CreateTimerScheduler;
  try
    tm := sch.ScheduleAtFixedRate(TDuration.FromMs(1000), TDuration.FromMs(100), @OnFired);

    // 初始值应为 0
    maxExec := tm.GetMaxExecutions;
    CheckEquals(0, maxExec, 'Initial MaxExecutions should be 0');

    // 设置后应返回设置的值
    tm.SetMaxExecutions(10);
    maxExec := tm.GetMaxExecutions;
    CheckEquals(10, maxExec, 'GetMaxExecutions should return 10');

    tm.Cancel;
  finally
    sch.Shutdown;
  end;
end;

{ 执行限制测试 }

procedure TTestCase_TimerMaxExecutions.Test_FixedRate_StopsAfterMaxExecutions;
var
  sch: ITimerScheduler;
  tm: ITimer;
  execCount: QWord;
begin
  GFiredCount := 0;
  sch := CreateTimerScheduler;
  try
    // 设置最大执行 3 次的定时器，每 20ms 触发一次
    tm := sch.ScheduleAtFixedRate(TDuration.FromMs(10), TDuration.FromMs(20), @OnFired);
    tm.SetMaxExecutions(3);

    // 等待足够时间让定时器执行
    SleepFor(TDuration.FromMs(200));

    // 验证执行次数
    execCount := tm.GetExecutionCount;
    CheckEquals(3, execCount, 'ExecutionCount should be exactly 3');
    CheckEquals(3, GFiredCount, Format('GFiredCount should be 3, got %d', [GFiredCount]));

    // 定时器应该已自动取消
    CheckTrue(tm.IsCancelled, 'Timer should be cancelled after reaching max executions');
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_TimerMaxExecutions.Test_FixedDelay_StopsAfterMaxExecutions;
var
  sch: ITimerScheduler;
  tm: ITimer;
  execCount: QWord;
begin
  GFiredCount := 0;
  sch := CreateTimerScheduler;
  try
    // 设置最大执行 5 次的定时器，每 15ms 延迟
    tm := sch.ScheduleWithFixedDelay(TDuration.FromMs(10), TDuration.FromMs(15), @OnFired);
    tm.SetMaxExecutions(5);

    // 等待足够时间让定时器执行
    SleepFor(TDuration.FromMs(200));

    // 验证执行次数
    execCount := tm.GetExecutionCount;
    CheckEquals(5, execCount, 'ExecutionCount should be exactly 5');
    CheckEquals(5, GFiredCount, Format('GFiredCount should be 5, got %d', [GFiredCount]));

    // 定时器应该已自动取消
    CheckTrue(tm.IsCancelled, 'Timer should be cancelled after reaching max executions');
  finally
    sch.Shutdown;
  end;
end;

procedure TTestCase_TimerMaxExecutions.Test_MaxExecutions_Zero_NoLimit;
var
  sch: ITimerScheduler;
  tm: ITimer;
  execCount: QWord;
begin
  GFiredCount := 0;
  sch := CreateTimerScheduler;
  try
    // MaxExecutions = 0 表示无限制
    tm := sch.ScheduleAtFixedRate(TDuration.FromMs(10), TDuration.FromMs(20), @OnFired);
    // 默认值应该是 0，不需要设置

    // 等待让定时器执行多次
    SleepFor(TDuration.FromMs(100));

    // 验证执行多次
    execCount := tm.GetExecutionCount;
    CheckTrue(execCount >= 3, Format('ExecutionCount should be >= 3, got %d', [execCount]));

    // 定时器应该仍在运行（未取消）
    CheckFalse(tm.IsCancelled, 'Timer should not be cancelled when MaxExecutions is 0');

    tm.Cancel;
  finally
    sch.Shutdown;
  end;
end;

initialization
  InitCriticalSection(GFiredLock);
  RegisterTest(TTestCase_TimerMaxExecutions);

finalization
  DoneCriticalSection(GFiredLock);

end.
