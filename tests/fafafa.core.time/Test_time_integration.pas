unit Test_time_integration;

{$MODE OBJFPC}{$H+}

interface

uses
  SysUtils, Classes,
  fafafa.core.math,
  fafafa.core.time,
  fafafa.core.time.clock,
  fafafa.core.time.clock.safe,
  fafafa.core.time.timer,
  fafafa.core.time.timer.safe,
  fafafa.core.time.duration.safe,
  fafafa.core.time.stopwatch,
  fafafa.core.result,
  fafafa.core.testing;

type
  // 综合测试套件
  TTimeIntegrationTests = class(TTestCase)
  published
    // Duration 和 Clock 集成测试
    procedure TestDurationWithClock;
    procedure TestSafeDurationWithSafeClock;
    
    // Timer 和 Clock 集成测试
    procedure TestTimerWithClock;
    procedure TestSafeTimerWithSafeClock;
    
    // Stopwatch 和 Clock 集成测试
    procedure TestStopwatchWithClock;
    procedure TestStopwatchLapFunctionality;
    
    // 多组件协同测试
    procedure TestTimerDurationCalculation;
    procedure TestStopwatchTimerSynchronization;
    procedure TestSafeComponentsErrorPropagation;
    
    // 性能和压力测试
    procedure TestHighFrequencyTimers;
    procedure TestLongRunningOperations;
    procedure TestConcurrentTimerOperations;
    
    // 边界条件测试
    procedure TestZeroDurationHandling;
    procedure TestMaxDurationHandling;
    procedure TestClockPrecision;
  end;

implementation

{ TTimeIntegrationTests }

procedure TTimeIntegrationTests.TestDurationWithClock;
var
  Clock: IMonotonicClock;
  Start, End: TInstant;
  Duration: TDuration;
  ElapsedMs: Int64;
begin
  Clock := CreateMonotonicClock;
  
  // 测试基本的时间测量
  Start := Clock.Now;
  Clock.SleepFor(TDuration.FromMillis(100));
  End := Clock.Now;
  
  Duration := End.Sub(Start);
  ElapsedMs := Duration.AsMillis;
  
  // 验证测量精度（允许10ms误差）
  AssertTrue('Duration measurement should be approximately 100ms', 
    (ElapsedMs >= 90) and (ElapsedMs <= 110));
  
  // 测试 Duration 算术运算
  var D1 := TDuration.FromSecs(5);
  var D2 := TDuration.FromMillis(500);
  var D3 := D1.Add(D2);
  
  AssertEquals('5s + 500ms should equal 5500ms', 5500, D3.AsMillis);
  
  // 测试 Duration 比较
  AssertTrue('5s should be greater than 500ms', D1.GreaterThan(D2));
  AssertFalse('500ms should not be greater than 5s', D2.GreaterThan(D1));
end;

procedure TTimeIntegrationTests.TestSafeDurationWithSafeClock;
var
  Clock: IMonotonicClockSafe;
  Start, End: TInstant;
  Duration: TDuration;
  SafeResult: TResult<TDuration, string>;
begin
  Clock := CreateMonotonicClockSafe;
  
  // 测试安全的时间测量
  var StartResult := Clock.TryNow;
  AssertTrue('Should get start time', StartResult.IsOk);
  Start := StartResult.Unwrap;
  
  Clock.TrySleepFor(TDuration.FromMillis(50));
  
  var EndResult := Clock.TryNow;
  AssertTrue('Should get end time', EndResult.IsOk);
  End := EndResult.Unwrap;
  
  // 使用安全 Duration 运算
  SafeResult := CheckedSub(End.Value, Start.Value);
  AssertTrue('Safe duration calculation should succeed', SafeResult.IsOk);
  
  Duration := TDuration(SafeResult.Unwrap);
  AssertTrue('Duration should be at least 40ms', Duration.AsMillis >= 40);
  
  // 测试溢出保护
  var MaxDur := TDuration(High(Int64));
  var AddResult := CheckedAdd(MaxDur.Value, 1000);
  AssertTrue('Adding to max duration should fail', AddResult.IsErr);
  
  // 测试饱和运算
  var SatResult := SaturatingAdd(MaxDur.Value, 1000);
  AssertEquals('Saturating add should return max value', High(Int64), SatResult);
end;

procedure TTimeIntegrationTests.TestTimerWithClock;
var
  Clock: IMonotonicClock;
  Scheduler: ITimerScheduler;
  Timer: ITimer;
  Executed: Boolean;
  ExecutionTime: TInstant;
begin
  Clock := CreateMonotonicClock;
  Scheduler := CreateTimerScheduler(Clock);
  Executed := False;
  
  // 测试一次性定时器
  var StartTime := Clock.Now;
  Timer := Scheduler.ScheduleOnce(
    TDuration.FromMillis(100),
    procedure
    begin
      Executed := True;
      ExecutionTime := Clock.Now;
    end
  );
  
  // 等待执行
  Clock.SleepFor(TDuration.FromMillis(150));
  
  AssertTrue('Timer should have executed', Executed);
  
  // 验证执行时间
  var Delay := ExecutionTime.Sub(StartTime);
  AssertTrue('Timer should execute after approximately 100ms',
    (Delay.AsMillis >= 90) and (Delay.AsMillis <= 110));
  
  // 测试定时器取消
  Executed := False;
  Timer := Scheduler.ScheduleOnce(
    TDuration.FromMillis(200),
    procedure
    begin
      Executed := True;
    end
  );
  
  Clock.SleepFor(TDuration.FromMillis(50));
  Timer.Cancel;
  Clock.SleepFor(TDuration.FromMillis(200));
  
  AssertFalse('Cancelled timer should not execute', Executed);
  
  Scheduler.Shutdown;
end;

procedure TTimeIntegrationTests.TestSafeTimerWithSafeClock;
var
  Clock: IMonotonicClockSafe;
  Scheduler: ISafeTimerScheduler;
  Timer: ISafeTimer;
  ExecutionCount: Integer;
  ErrorCount: Integer;
begin
  Clock := CreateMonotonicClockSafe;
  Scheduler := CreateSafeTimerScheduler(Clock);
  ExecutionCount := 0;
  ErrorCount := 0;
  
  // 测试带错误处理的定时器
  Timer := Scheduler.ScheduleSafeOnce(
    TDuration.FromMillis(50),
    function: TResult<Boolean, TTimerErrorInfo>
    var
      ErrorInfo: TTimerErrorInfo;
    begin
      Inc(ExecutionCount);
      if ExecutionCount = 1 then
      begin
        // 第一次执行失败
        ErrorInfo.Error := teCallbackError;
        ErrorInfo.Message := 'Test error';
        Inc(ErrorCount);
        Result := TResult<Boolean, TTimerErrorInfo>.Err(ErrorInfo);
      end
      else
      begin
        // 重试成功
        Result := TResult<Boolean, TTimerErrorInfo>.Ok(True);
      end;
    end,
    tesRetry  // 使用重试策略
  );
  
  // 等待执行和重试
  Sleep(500);
  
  var Stats := Timer.Stats;
  AssertTrue('Timer should have executed multiple times', Stats.ExecutedCount > 1);
  AssertEquals('Should have one error', 1, Stats.ErrorCount);
  AssertTrue('Should have retries', Stats.RetryCount > 0);
  
  Scheduler.Shutdown;
end;

procedure TTimeIntegrationTests.TestStopwatchWithClock;
var
  Clock: IMonotonicClock;
  Stopwatch: TStopwatch;
  Elapsed: TDuration;
begin
  Clock := CreateMonotonicClock;
  
  // 测试基本计时
  Stopwatch.Start(Clock);
  Clock.SleepFor(TDuration.FromMillis(100));
  Stopwatch.Stop;
  
  Elapsed := Stopwatch.Elapsed;
  AssertTrue('Stopwatch should measure approximately 100ms',
    (Elapsed.AsMillis >= 90) and (Elapsed.AsMillis <= 110));
  
  // 测试暂停和恢复
  Stopwatch.Reset;
  Stopwatch.Start(Clock);
  Clock.SleepFor(TDuration.FromMillis(50));
  Stopwatch.Stop;
  
  var FirstElapsed := Stopwatch.Elapsed;
  
  Clock.SleepFor(TDuration.FromMillis(50)); // 暂停期间
  
  Stopwatch.Start(Clock); // 恢复
  Clock.SleepFor(TDuration.FromMillis(50));
  Stopwatch.Stop;
  
  var TotalElapsed := Stopwatch.Elapsed;
  
  // 验证暂停期间不计时
  AssertTrue('Total elapsed should be approximately 100ms (excluding pause)',
    (TotalElapsed.AsMillis >= 90) and (TotalElapsed.AsMillis <= 110));
end;

procedure TTimeIntegrationTests.TestStopwatchLapFunctionality;
var
  Clock: IMonotonicClock;
  Stopwatch: TStopwatch;
  LapTimes: array of TDuration;
  I: Integer;
begin
  Clock := CreateMonotonicClock;
  
  Stopwatch.Start(Clock);
  
  // 记录多个 Lap
  for I := 1 to 3 do
  begin
    Clock.SleepFor(TDuration.FromMillis(50 * I)); // 50ms, 100ms, 150ms
    Stopwatch.Lap;
  end;
  
  Stopwatch.Stop;
  
  // 验证 Lap 数量
  AssertEquals('Should have 3 laps', 3, Stopwatch.GetLapCount);
  
  // 获取所有 Lap 时间
  SetLength(LapTimes, Stopwatch.GetLapCount);
  for I := 0 to High(LapTimes) do
    LapTimes[I] := Stopwatch.GetLapDuration(I);
  
  // 验证 Lap 时间递增
  for I := 1 to High(LapTimes) do
  begin
    AssertTrue('Each lap should be longer than the previous',
      LapTimes[I].AsMillis > LapTimes[I-1].AsMillis);
  end;
  
  // 验证 Lap 间隔
  var Intervals := Stopwatch.GetLapIntervals;
  AssertEquals('Should have 3 intervals', 3, Length(Intervals));
  
  // 第一个间隔应该约 50ms
  AssertTrue('First interval should be approximately 50ms',
    (Intervals[0].AsMillis >= 40) and (Intervals[0].AsMillis <= 60));
end;

procedure TTimeIntegrationTests.TestTimerDurationCalculation;
var
  Clock: IMonotonicClock;
  Scheduler: ITimerScheduler;
  Stopwatch: TStopwatch;
  TimerDuration: TDuration;
  ActualDuration: TDuration;
begin
  Clock := CreateMonotonicClock;
  Scheduler := CreateTimerScheduler(Clock);
  
  TimerDuration := TDuration.FromMillis(75);
  
  // 使用 Stopwatch 测量定时器的实际执行时间
  Stopwatch.Start(Clock);
  
  var Executed := False;
  var Timer := Scheduler.ScheduleOnce(
    TimerDuration,
    procedure
    begin
      Stopwatch.Stop;
      Executed := True;
    end
  );
  
  // 等待定时器执行
  Clock.SleepFor(TDuration.FromMillis(100));
  
  AssertTrue('Timer should have executed', Executed);
  
  ActualDuration := Stopwatch.Elapsed;
  
  // 验证定时器精度
  var Difference := Abs(ActualDuration.AsMillis - TimerDuration.AsMillis);
  AssertTrue('Timer should be accurate within 10ms', Difference <= 10);
  
  Scheduler.Shutdown;
end;

procedure TTimeIntegrationTests.TestStopwatchTimerSynchronization;
var
  Clock: IMonotonicClock;
  Scheduler: ITimerScheduler;
  Stopwatch: TStopwatch;
  ExecutionTimes: array of TDuration;
  ExecutionIndex: Integer;
begin
  Clock := CreateMonotonicClock;
  Scheduler := CreateTimerScheduler(Clock);
  SetLength(ExecutionTimes, 3);
  ExecutionIndex := 0;
  
  Stopwatch.Start(Clock);
  
  // 创建周期性定时器，记录每次执行的时间点
  var Timer := Scheduler.ScheduleAtFixedRate(
    TDuration.FromMillis(50),  // 初始延迟
    TDuration.FromMillis(100), // 周期
    procedure
    begin
      if ExecutionIndex < Length(ExecutionTimes) then
      begin
        ExecutionTimes[ExecutionIndex] := Stopwatch.Elapsed;
        Inc(ExecutionIndex);
      end;
    end
  );
  
  // 等待所有执行完成
  Clock.SleepFor(TDuration.FromMillis(400));
  Timer.Cancel;
  
  AssertEquals('Should have 3 executions', 3, ExecutionIndex);
  
  // 验证执行时间点
  // 第一次: ~50ms
  AssertTrue('First execution at ~50ms',
    (ExecutionTimes[0].AsMillis >= 40) and (ExecutionTimes[0].AsMillis <= 60));
  
  // 第二次: ~150ms (50 + 100)
  AssertTrue('Second execution at ~150ms',
    (ExecutionTimes[1].AsMillis >= 140) and (ExecutionTimes[1].AsMillis <= 160));
  
  // 第三次: ~250ms (50 + 200)
  AssertTrue('Third execution at ~250ms',
    (ExecutionTimes[2].AsMillis >= 240) and (ExecutionTimes[2].AsMillis <= 260));
  
  Scheduler.Shutdown;
end;

procedure TTimeIntegrationTests.TestSafeComponentsErrorPropagation;
var
  Clock: IMonotonicClockSafe;
  Scheduler: ISafeTimerScheduler;
  ErrorPropagated: Boolean;
begin
  Clock := CreateMonotonicClockSafe;
  Scheduler := CreateSafeTimerScheduler(Clock);
  ErrorPropagated := False;
  
  // 测试错误从 Clock 传播到 Timer
  var Timer := Scheduler.ScheduleSafeOnce(
    TDuration.FromMillis(50),
    function: TResult<Boolean, TTimerErrorInfo>
    var
      ErrorInfo: TTimerErrorInfo;
      TimeResult: TResult<TInstant, string>;
    begin
      // 尝试获取时间（在真实场景中可能失败）
      TimeResult := Clock.TryNow;
      if TimeResult.IsErr then
      begin
        ErrorInfo.Error := teClockError;
        ErrorInfo.Message := 'Clock error: ' + TimeResult.UnwrapErr;
        ErrorPropagated := True;
        Result := TResult<Boolean, TTimerErrorInfo>.Err(ErrorInfo);
      end
      else
      begin
        // 模拟其他错误
        if Random(2) = 0 then
        begin
          ErrorInfo.Error := teCallbackError;
          ErrorInfo.Message := 'Random error';
          Result := TResult<Boolean, TTimerErrorInfo>.Err(ErrorInfo);
        end
        else
          Result := TResult<Boolean, TTimerErrorInfo>.Ok(True);
      end;
    end,
    tesContinue
  );
  
  Sleep(100);
  
  var Stats := Timer.Stats;
  
  // 验证统计信息
  AssertTrue('Should have at least one execution', Stats.ExecutedCount > 0);
  
  // 如果有错误，验证错误记录
  if Stats.ErrorCount > 0 then
  begin
    AssertTrue('Should have error information', 
      Stats.LastError.Message <> '');
  end;
  
  Scheduler.Shutdown;
end;

procedure TTimeIntegrationTests.TestHighFrequencyTimers;
var
  Clock: IMonotonicClock;
  Scheduler: ITimerScheduler;
  ExecutionCount: Integer;
  StartTime, EndTime: TInstant;
begin
  Clock := CreateMonotonicClock;
  Scheduler := CreateTimerScheduler(Clock);
  ExecutionCount := 0;
  
  StartTime := Clock.Now;
  
  // 创建高频定时器（每10ms执行一次）
  var Timer := Scheduler.ScheduleAtFixedRate(
    TDuration.Zero,           // 无初始延迟
    TDuration.FromMillis(10), // 10ms 周期
    procedure
    begin
      Inc(ExecutionCount);
      if ExecutionCount >= 20 then
        Timer.Cancel;
    end
  );
  
  // 等待执行完成
  Clock.SleepFor(TDuration.FromMillis(300));
  
  EndTime := Clock.Now;
  
  AssertEquals('Should have exactly 20 executions', 20, ExecutionCount);
  
  // 验证总时间（应该约 200ms）
  var TotalTime := EndTime.Sub(StartTime);
  AssertTrue('Total time should be approximately 200ms',
    (TotalTime.AsMillis >= 180) and (TotalTime.AsMillis <= 250));
  
  Scheduler.Shutdown;
end;

procedure TTimeIntegrationTests.TestLongRunningOperations;
var
  Clock: IMonotonicClock;
  Stopwatch: TStopwatch;
  LongDuration: TDuration;
begin
  Clock := CreateMonotonicClock;
  
  // 测试长时间运行（1秒）
  LongDuration := TDuration.FromSecs(1);
  
  Stopwatch.Start(Clock);
  Clock.SleepFor(LongDuration);
  Stopwatch.Stop;
  
  var Elapsed := Stopwatch.Elapsed;
  
  // 验证精度（允许20ms误差）
  AssertTrue('Long duration measurement should be accurate',
    Abs(Elapsed.AsMillis - 1000) <= 20);
  
  // 测试 Duration 格式化
  var Formatted := Format('Elapsed: %d seconds, %d milliseconds',
    [Elapsed.AsSecs, Elapsed.AsMillis mod 1000]);
  
  AssertTrue('Formatted string should contain "1 second"',
    Pos('1 second', Formatted) > 0);
end;

procedure TTimeIntegrationTests.TestConcurrentTimerOperations;
var
  Clock: IMonotonicClock;
  Scheduler: ITimerScheduler;
  Counters: array[0..2] of Integer;
  I: Integer;
begin
  Clock := CreateMonotonicClock;
  Scheduler := CreateTimerScheduler(Clock);
  
  for I := 0 to High(Counters) do
    Counters[I] := 0;
  
  // 创建多个并发定时器
  for I := 0 to High(Counters) do
  begin
    var Index := I; // 捕获循环变量
    Scheduler.ScheduleAtFixedRate(
      TDuration.FromMillis(20 * (Index + 1)), // 不同的初始延迟
      TDuration.FromMillis(50),               // 相同的周期
      procedure
      begin
        Inc(Counters[Index]);
        if Counters[Index] >= 3 then
          ; // Could cancel here if we had the timer reference
      end
    );
  end;
  
  // 等待执行
  Clock.SleepFor(TDuration.FromMillis(300));
  
  // 验证所有定时器都执行了
  for I := 0 to High(Counters) do
  begin
    AssertTrue(Format('Timer %d should have executed at least once', [I]),
      Counters[I] > 0);
  end;
  
  Scheduler.Shutdown;
end;

procedure TTimeIntegrationTests.TestZeroDurationHandling;
var
  Clock: IMonotonicClock;
  Scheduler: ITimerScheduler;
  Executed: Boolean;
begin
  Clock := CreateMonotonicClock;
  Scheduler := CreateTimerScheduler(Clock);
  Executed := False;
  
  // 测试零延迟定时器
  Scheduler.ScheduleOnce(
    TDuration.Zero,
    procedure
    begin
      Executed := True;
    end
  );
  
  // 给一点时间让定时器执行
  Clock.SleepFor(TDuration.FromMillis(10));
  
  AssertTrue('Zero-delay timer should execute immediately', Executed);
  
  // 测试零 Duration 的算术
  var Zero := TDuration.Zero;
  var One := TDuration.FromMillis(1);
  
  AssertEquals('Zero + One should equal One', One.Value, Zero.Add(One).Value);
  AssertEquals('One - One should equal Zero', Zero.Value, One.Sub(One).Value);
  AssertTrue('Zero should be less than One', Zero.LessThan(One));
  
  Scheduler.Shutdown;
end;

procedure TTimeIntegrationTests.TestMaxDurationHandling;
var
  MaxDur, HalfMax: TDuration;
  AddResult, MulResult: TResult<TDuration, string>;
begin
  MaxDur := TDuration(High(Int64));
  HalfMax := TDuration(High(Int64) div 2);
  
  // 测试最大值的安全运算
  AddResult := CheckedAdd(HalfMax.Value, HalfMax.Value);
  AssertTrue('Adding two halves of max should succeed', AddResult.IsOk);
  
  AddResult := CheckedAdd(MaxDur.Value, 1);
  AssertTrue('Adding to max should fail', AddResult.IsErr);
  
  MulResult := CheckedMul(HalfMax.Value, 3);
  AssertTrue('Multiplying half-max by 3 should fail', MulResult.IsErr);
  
  // 测试饱和运算
  var SatAdd := SaturatingAdd(MaxDur.Value, 1000);
  AssertEquals('Saturating add should cap at max', High(Int64), SatAdd);
  
  var SatMul := SaturatingMul(HalfMax.Value, 3);
  AssertEquals('Saturating mul should cap at max', High(Int64), SatMul);
end;

procedure TTimeIntegrationTests.TestClockPrecision;
var
  Clock: IMonotonicClock;
  Measurements: array[0..9] of TInstant;
  Deltas: array[0..8] of Int64;
  I: Integer;
  MinDelta, MaxDelta: Int64;
begin
  Clock := CreateMonotonicClock;
  
  // 快速连续获取时间戳
  for I := 0 to High(Measurements) do
  begin
    Measurements[I] := Clock.Now;
    // 很小的延迟
    Sleep(1);
  end;
  
  // 计算时间差
  MinDelta := High(Int64);
  MaxDelta := 0;
  
  for I := 0 to High(Deltas) do
  begin
    Deltas[I] := Measurements[I + 1].Sub(Measurements[I]).AsMicros;
    if Deltas[I] < MinDelta then MinDelta := Deltas[I];
    if Deltas[I] > MaxDelta then MaxDelta := Deltas[I];
  end;
  
  // 验证时钟精度
  AssertTrue('Clock should have microsecond precision', MinDelta > 0);
  AssertTrue('Clock measurements should be monotonic', MinDelta >= 0);
  
  // 输出精度信息（用于调试）
  WriteLn(Format('Clock precision: Min delta = %d us, Max delta = %d us',
    [MinDelta, MaxDelta]));
end;

initialization
  RegisterTest(TTimeIntegrationTests);

end.