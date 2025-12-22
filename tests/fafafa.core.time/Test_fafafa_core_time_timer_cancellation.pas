unit Test_fafafa_core_time_timer_cancellation;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

{*
  定时器取消令牌集成测试

  验证 ICancellationToken 与定时器调度的集成：
  - 已取消令牌不创建定时器
  - 令牌取消阻止回调执行
  - 周期定时器令牌取消
*}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.timer,
  fafafa.core.time.duration,
  fafafa.core.time.instant,
  fafafa.core.thread.cancel;

type
  TTestCase_TimerCancellation = class(TTestCase)
  private
    FScheduler: ITimerScheduler;
    FCallbackCount: Integer;
    procedure IncrementCallback;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 已取消令牌测试
    procedure Test_ScheduleWithToken_AlreadyCancelled_ReturnsNil;
    procedure Test_ScheduleFixedRateWithToken_AlreadyCancelled_ReturnsNil;
    procedure Test_ScheduleFixedDelayWithToken_AlreadyCancelled_ReturnsNil;

    // 令牌取消阻止执行测试
    procedure Test_ScheduleWithToken_CancelBeforeExecution_NoCallback;
    procedure Test_ScheduleFixedRateWithToken_CancelStopsExecution;
    procedure Test_ScheduleFixedDelayWithToken_CancelStopsExecution;

    // 正常执行测试
    procedure Test_ScheduleWithToken_NotCancelled_ExecutesCallback;
  end;

implementation

{ TTestCase_TimerCancellation }

procedure TTestCase_TimerCancellation.SetUp;
begin
  inherited SetUp;
  FScheduler := CreateTimerScheduler(nil);
  FCallbackCount := 0;
end;

procedure TTestCase_TimerCancellation.TearDown;
begin
  if FScheduler <> nil then
  begin
    FScheduler.Shutdown;
    FScheduler := nil;
  end;
  inherited TearDown;
end;

procedure TTestCase_TimerCancellation.IncrementCallback;
begin
  InterlockedIncrement(FCallbackCount);
end;

{ 已取消令牌测试 }

procedure TTestCase_TimerCancellation.Test_ScheduleWithToken_AlreadyCancelled_ReturnsNil;
var
  source: ICancellationTokenSource;
  timer: ITimer;
begin
  source := CreateCancellationTokenSource;
  source.Cancel;  // 先取消

  timer := FScheduler.ScheduleWithToken(
    TDuration.FromSec(1),
    TimerCallbackMethod(@Self.IncrementCallback),
    source.Token);

  CheckTrue(timer = nil, 'Timer should be nil when token is already cancelled');
end;

procedure TTestCase_TimerCancellation.Test_ScheduleFixedRateWithToken_AlreadyCancelled_ReturnsNil;
var
  source: ICancellationTokenSource;
  timer: ITimer;
begin
  source := CreateCancellationTokenSource;
  source.Cancel;

  timer := FScheduler.ScheduleFixedRateWithToken(
    TDuration.FromMs(100),
    TDuration.FromMs(100),
    TimerCallbackMethod(@Self.IncrementCallback),
    source.Token);

  CheckTrue(timer = nil, 'Timer should be nil when token is already cancelled');
end;

procedure TTestCase_TimerCancellation.Test_ScheduleFixedDelayWithToken_AlreadyCancelled_ReturnsNil;
var
  source: ICancellationTokenSource;
  timer: ITimer;
begin
  source := CreateCancellationTokenSource;
  source.Cancel;

  timer := FScheduler.ScheduleFixedDelayWithToken(
    TDuration.FromMs(100),
    TDuration.FromMs(100),
    TimerCallbackMethod(@Self.IncrementCallback),
    source.Token);

  CheckTrue(timer = nil, 'Timer should be nil when token is already cancelled');
end;

{ 令牌取消阻止执行测试 }

procedure TTestCase_TimerCancellation.Test_ScheduleWithToken_CancelBeforeExecution_NoCallback;
var
  source: ICancellationTokenSource;
  timer: ITimer;
begin
  source := CreateCancellationTokenSource;

  // 调度一个 500ms 后触发的定时器
  timer := FScheduler.ScheduleWithToken(
    TDuration.FromMs(500),
    TimerCallbackMethod(@Self.IncrementCallback),
    source.Token);

  CheckTrue(timer <> nil, 'Timer should be created');

  // 在触发前取消令牌
  Sleep(100);
  source.Cancel;

  // 等待定时器触发时间过去
  Sleep(600);

  // 回调不应被执行
  CheckEquals(0, FCallbackCount, 'Callback should not execute when token is cancelled');
end;

procedure TTestCase_TimerCancellation.Test_ScheduleFixedRateWithToken_CancelStopsExecution;
var
  source: ICancellationTokenSource;
  timer: ITimer;
  count1, count2: Integer;
begin
  source := CreateCancellationTokenSource;

  // 调度一个每 50ms 触发的定时器
  timer := FScheduler.ScheduleFixedRateWithToken(
    TDuration.FromMs(50),
    TDuration.FromMs(50),
    TimerCallbackMethod(@Self.IncrementCallback),
    source.Token);

  CheckTrue(timer <> nil, 'Timer should be created');

  // 等待几次触发
  Sleep(200);
  count1 := FCallbackCount;
  CheckTrue(count1 > 0, 'Callback should have been called at least once');

  // 取消令牌
  source.Cancel;

  // 再等待一段时间
  Sleep(200);
  count2 := FCallbackCount;

  // 取消后不应有更多回调
  CheckEquals(count1, count2, 'No more callbacks after token cancellation');
end;

procedure TTestCase_TimerCancellation.Test_ScheduleFixedDelayWithToken_CancelStopsExecution;
var
  source: ICancellationTokenSource;
  timer: ITimer;
  count1, count2: Integer;
begin
  source := CreateCancellationTokenSource;

  // 调度一个每 50ms 触发的定时器
  timer := FScheduler.ScheduleFixedDelayWithToken(
    TDuration.FromMs(50),
    TDuration.FromMs(50),
    TimerCallbackMethod(@Self.IncrementCallback),
    source.Token);

  CheckTrue(timer <> nil, 'Timer should be created');

  // 等待几次触发
  Sleep(200);
  count1 := FCallbackCount;
  CheckTrue(count1 > 0, 'Callback should have been called at least once');

  // 取消令牌
  source.Cancel;

  // 再等待一段时间
  Sleep(200);
  count2 := FCallbackCount;

  // 取消后不应有更多回调
  CheckEquals(count1, count2, 'No more callbacks after token cancellation');
end;

{ 正常执行测试 }

procedure TTestCase_TimerCancellation.Test_ScheduleWithToken_NotCancelled_ExecutesCallback;
var
  source: ICancellationTokenSource;
  timer: ITimer;
begin
  source := CreateCancellationTokenSource;

  // 调度一个 100ms 后触发的定时器
  timer := FScheduler.ScheduleWithToken(
    TDuration.FromMs(100),
    TimerCallbackMethod(@Self.IncrementCallback),
    source.Token);

  CheckTrue(timer <> nil, 'Timer should be created');

  // 等待触发
  Sleep(200);

  // 回调应被执行
  CheckEquals(1, FCallbackCount, 'Callback should execute once');
end;

initialization
  RegisterTest(TTestCase_TimerCancellation);

end.
