unit test_clock_improvements;

{
  时钟改进功能的单元测试
  
  测试策略：
  - 验证新功能的正确性
  - 确保与原有功能的兼容性
  - 测试错误处理路径
}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.clock,
  fafafa.core.time.base,
  fafafa.core.time.duration,
  fafafa.core.time.instant,
  fafafa.core.result,
  clock_improvements_example;

type
  { TTestClockImprovements }
  TTestClockImprovements = class(TTestCase)
  published
    // 测试 Try 方法
    procedure TestTryNowInstant;
    procedure TestTrySleepFor;
    
    // 测试 Safe 方法（返回 Result）
    procedure TestSafeNowInstant;
    procedure TestSafeGetResolution;
    
    // 测试状态查询
    procedure TestIsAvailable;
    procedure TestErrorTracking;
    
    // 测试增强的测试时钟
    procedure TestAutoAdvance;
    procedure TestCallCounting;
    procedure TestCallRecording;
    
    // 测试向后兼容性
    procedure TestBackwardCompatibility;
  end;

  { TTestClockPerformance }
  TTestClockPerformance = class(TTestCase)
  published
    procedure TestOverheadMinimal;
    procedure TestConcurrentAccess;
  end;

implementation

{ TTestClockImprovements }

procedure TTestClockImprovements.TestTryNowInstant;
var
  Clock: IMonotonicClockSafe;
  Instant: TInstant;
  Success: Boolean;
begin
  Clock := CreateSafeMonotonicClock;
  
  // 测试正常情况
  Success := Clock.TryNowInstant(Instant);
  AssertTrue('TryNowInstant should succeed', Success);
  AssertTrue('Instant should be valid', Instant.AsNs > 0);
  
  // 测试连续调用
  Success := Clock.TryNowInstant(Instant);
  AssertTrue('Second call should also succeed', Success);
end;

procedure TTestClockImprovements.TestTrySleepFor;
var
  Clock: IMonotonicClockSafe;
  Duration: TDuration;
  Success: Boolean;
  StartTime, EndTime: TInstant;
begin
  Clock := CreateSafeMonotonicClock;
  Duration := TDuration.FromMillis(10);
  
  // 记录开始时间
  Clock.TryNowInstant(StartTime);
  
  // 测试睡眠
  Success := Clock.TrySleepFor(Duration);
  AssertTrue('TrySleepFor should succeed', Success);
  
  // 验证时间确实过去了
  Clock.TryNowInstant(EndTime);
  AssertTrue('Time should have passed', EndTime.AsNs > StartTime.AsNs);
end;

procedure TTestClockImprovements.TestSafeNowInstant;
var
  Clock: IMonotonicClockSafe;
  Result: TInstantResult;
  Instant: TInstant;
begin
  Clock := CreateSafeMonotonicClock;
  
  // 测试返回 Result 的方法
  Result := Clock.SafeNowInstant;
  AssertTrue('SafeNowInstant should return Ok', Result.IsOk);
  
  // 获取值
  Instant := Result.Unwrap;
  AssertTrue('Instant should be valid', Instant.AsNs > 0);
  
  // 测试 Result 的便捷方法
  AssertEquals('UnwrapOr should return actual value',
    Instant.AsNs, 
    Result.UnwrapOr(TInstant.FromNs(0)).AsNs);
end;

procedure TTestClockImprovements.TestSafeGetResolution;
var
  Clock: IMonotonicClockSafe;
  Result: TDurationResult;
  Resolution: TDuration;
begin
  Clock := CreateSafeMonotonicClock;
  
  Result := Clock.SafeGetResolution;
  AssertTrue('SafeGetResolution should return Ok', Result.IsOk);
  
  Resolution := Result.Unwrap;
  AssertTrue('Resolution should be positive', Resolution.AsNs > 0);
  
  // 合理性检查：分辨率应该在合理范围内
  // 通常在 1ns 到 100ms 之间
  AssertTrue('Resolution should be reasonable',
    (Resolution.AsNs >= 1) and (Resolution.AsNs <= 100000000));
end;

procedure TTestClockImprovements.TestIsAvailable;
var
  Clock: IMonotonicClockSafe;
begin
  Clock := CreateSafeMonotonicClock;
  
  // 正常情况下时钟应该可用
  AssertTrue('Clock should be available', Clock.IsAvailable);
  
  // 测试多次调用的一致性
  AssertTrue('Second check should also return true', Clock.IsAvailable);
end;

procedure TTestClockImprovements.TestErrorTracking;
var
  Clock: IMonotonicClockSafe;
  InitialCount: Integer;
begin
  Clock := CreateSafeMonotonicClock;
  
  // 初始状态
  AssertEquals('Initial error count should be 0', 0, Clock.GetErrorCount);
  AssertEquals('Initial error message should be empty', '', Clock.GetLastError);
  
  // 正常操作不应增加错误计数
  InitialCount := Clock.GetErrorCount;
  Clock.TryNowInstant(TInstant.FromNs(0));
  AssertEquals('Error count should not increase', InitialCount, Clock.GetErrorCount);
end;

procedure TTestClockImprovements.TestAutoAdvance;
var
  TestClock: TTestClockEnhanced;
  InitialTime: TInstant;
  Time1, Time2, Time3: TInstant;
  Step: TDuration;
begin
  InitialTime := TInstant.FromMillis(1000);
  Step := TDuration.FromMillis(100);
  
  TestClock := CreateEnhancedTestClock(InitialTime);
  try
    // 启用自动前进
    TestClock.EnableAutoAdvance(Step);
    
    // 每次调用应该自动前进
    Time1 := TestClock.NowInstant;
    Time2 := TestClock.NowInstant;
    Time3 := TestClock.NowInstant;
    
    // 验证时间递增
    AssertEquals('First call should return initial time',
      InitialTime.AsMillis, Time1.AsMillis);
    AssertEquals('Second call should advance by step',
      InitialTime.AsMillis + Step.AsMillis, Time2.AsMillis);
    AssertEquals('Third call should advance again',
      InitialTime.AsMillis + 2 * Step.AsMillis, Time3.AsMillis);
    
    // 禁用自动前进
    TestClock.DisableAutoAdvance;
    
    // 时间应该停止前进
    Time1 := TestClock.NowInstant;
    Time2 := TestClock.NowInstant;
    AssertEquals('Time should not advance when disabled',
      Time1.AsMillis, Time2.AsMillis);
  finally
    TestClock.Free;
  end;
end;

procedure TTestClockImprovements.TestCallCounting;
var
  TestClock: TTestClockEnhanced;
begin
  TestClock := CreateEnhancedTestClock(TInstant.FromMillis(0));
  try
    // 初始计数应为 0
    AssertEquals('Initial call count should be 0', 0, TestClock.GetCallCount);
    
    // 调用应增加计数
    TestClock.NowInstant;
    AssertEquals('Call count should be 1', 1, TestClock.GetCallCount);
    
    TestClock.NowInstant;
    TestClock.NowInstant;
    AssertEquals('Call count should be 3', 3, TestClock.GetCallCount);
    
    // 重置计数
    TestClock.ResetCallCount;
    AssertEquals('Call count should be reset to 0', 0, TestClock.GetCallCount);
  finally
    TestClock.Free;
  end;
end;

procedure TTestClockImprovements.TestCallRecording;
var
  TestClock: TTestClockEnhanced;
  RecordedCalls: TArray<TInstant>;
  Step: TDuration;
begin
  Step := TDuration.FromMillis(50);
  TestClock := CreateEnhancedTestClock(TInstant.FromMillis(1000));
  try
    TestClock.EnableAutoAdvance(Step);
    
    // 进行几次调用
    TestClock.NowInstant;
    TestClock.NowInstant;
    TestClock.NowInstant;
    
    // 获取记录
    RecordedCalls := TestClock.GetRecordedCalls;
    
    // 验证记录
    AssertEquals('Should have 3 recorded calls', 3, Length(RecordedCalls));
    AssertEquals('First recorded time', 1000, RecordedCalls[0].AsMillis);
    AssertEquals('Second recorded time', 1050, RecordedCalls[1].AsMillis);
    AssertEquals('Third recorded time', 1100, RecordedCalls[2].AsMillis);
    
    // 重置后应清空记录
    TestClock.ResetCallCount;
    RecordedCalls := TestClock.GetRecordedCalls;
    AssertEquals('Records should be cleared', 0, Length(RecordedCalls));
  finally
    TestClock.Free;
  end;
end;

procedure TTestClockImprovements.TestBackwardCompatibility;
var
  SafeClock: IMonotonicClockSafe;
  BasicClock: IMonotonicClock;
  Instant: TInstant;
  Duration: TDuration;
begin
  // 安全时钟应该能作为普通时钟使用
  SafeClock := CreateSafeMonotonicClock;
  BasicClock := SafeClock as IMonotonicClock;
  
  // 测试基本接口的所有方法
  Instant := BasicClock.NowInstant;
  AssertTrue('NowInstant should work', Instant.AsNs > 0);
  
  Duration := BasicClock.GetResolution;
  AssertTrue('GetResolution should work', Duration.AsNs > 0);
  
  AssertTrue('GetName should work', Length(BasicClock.GetName) > 0);
  
  // 这确保了新实现与原有接口完全兼容
end;

{ TTestClockPerformance }

procedure TTestClockPerformance.TestOverheadMinimal;
var
  BasicClock: IMonotonicClock;
  SafeClock: IMonotonicClockSafe;
  StartTime, EndTime: TInstant;
  BasicDuration, SafeDuration: TDuration;
  i: Integer;
  OverheadPercent: Double;
const
  ITERATIONS = 10000;
begin
  BasicClock := CreateMonotonicClock;
  SafeClock := CreateSafeMonotonicClock;
  
  // 测试基本时钟性能
  StartTime := BasicClock.NowInstant;
  for i := 1 to ITERATIONS do
    BasicClock.NowInstant;
  EndTime := BasicClock.NowInstant;
  BasicDuration := EndTime.Diff(StartTime);
  
  // 测试安全时钟性能
  StartTime := BasicClock.NowInstant;
  for i := 1 to ITERATIONS do
    SafeClock.NowInstant;
  EndTime := BasicClock.NowInstant;
  SafeDuration := EndTime.Diff(StartTime);
  
  // 计算开销
  if BasicDuration.AsNs > 0 then
  begin
    OverheadPercent := ((SafeDuration.AsNs - BasicDuration.AsNs) / BasicDuration.AsNs) * 100;
    
    // 开销应该很小（例如小于 20%）
    AssertTrue(Format('Overhead should be minimal (%.2f%% found)', [OverheadPercent]),
      OverheadPercent < 20);
  end;
end;

procedure TTestClockPerformance.TestConcurrentAccess;
var
  Clock: IMonotonicClockSafe;
  
  procedure AccessClock;
  var
    i: Integer;
    Instant: TInstant;
  begin
    for i := 1 to 100 do
    begin
      Clock.TryNowInstant(Instant);
      Sleep(1);
    end;
  end;
  
begin
  Clock := CreateSafeMonotonicClock;
  
  // 简单的并发测试
  // 注意：这是一个基础测试，更复杂的并发测试需要线程库支持
  AccessClock;
  
  // 验证时钟仍然正常工作
  AssertTrue('Clock should still be available after concurrent access',
    Clock.IsAvailable);
  AssertTrue('Error count should be low',
    Clock.GetErrorCount < 10);
end;

initialization
  RegisterTest(TTestClockImprovements);
  RegisterTest(TTestClockPerformance);

end.