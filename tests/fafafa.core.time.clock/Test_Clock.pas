program Test_Clock;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, DateUtils,
  fafafa.core.math,
  fafafa.core.time.base,
  fafafa.core.time.duration,
  fafafa.core.time.instant,
  fafafa.core.time.clock,
  fafafa.core.thread.cancel;

var
  TotalTests: Integer = 0;
  PassedTests: Integer = 0;
  FailedTests: Integer = 0;

procedure AssertTrue(Condition: Boolean; const TestName: string);
begin
  Inc(TotalTests);
  if Condition then
  begin
    Inc(PassedTests);
    WriteLn('  ✓ ', TestName);
  end
  else
  begin
    Inc(FailedTests);
    WriteLn('  ✗ ', TestName);
  end;
end;

procedure AssertEquals(Expected, Actual: Int64; const TestName: string);
begin
  Inc(TotalTests);
  if Expected = Actual then
  begin
    Inc(PassedTests);
    WriteLn('  ✓ ', TestName);
  end
  else
  begin
    Inc(FailedTests);
    WriteLn('  ✗ ', TestName);
    WriteLn('    Expected: ', Expected);
    WriteLn('    Actual:   ', Actual);
  end;
end;

procedure AssertRange(Min, Max, Actual: Int64; const TestName: string);
begin
  Inc(TotalTests);
  if (Actual >= Min) and (Actual <= Max) then
  begin
    Inc(PassedTests);
    WriteLn('  ✓ ', TestName);
  end
  else
  begin
    Inc(FailedTests);
    WriteLn('  ✗ ', TestName);
    WriteLn('    Expected: ', Min, ' to ', Max);
    WriteLn('    Actual:   ', Actual);
  end;
end;

// ============================================================================
// Factory Function Tests
// ============================================================================

procedure Test_CreateMonotonicClock;
var
  c: IMonotonicClock;
begin
  WriteLn('Test_CreateMonotonicClock:');
  c := CreateMonotonicClock;
  AssertTrue(c <> nil, 'CreateMonotonicClock returns non-nil');
end;

procedure Test_CreateSystemClock;
var
  c: ISystemClock;
begin
  WriteLn('Test_CreateSystemClock:');
  c := CreateSystemClock;
  AssertTrue(c <> nil, 'CreateSystemClock returns non-nil');
end;

procedure Test_CreateClock;
var
  c: IClock;
begin
  WriteLn('Test_CreateClock:');
  c := CreateClock;
  AssertTrue(c <> nil, 'CreateClock returns non-nil');
end;

procedure Test_CreateFixedClock;
var
  c: IFixedClock;
begin
  WriteLn('Test_CreateFixedClock:');
  c := CreateFixedClock;
  AssertTrue(c <> nil, 'CreateFixedClock returns non-nil');
end;

procedure Test_DefaultMonotonicClock;
var
  c: IMonotonicClock;
begin
  WriteLn('Test_DefaultMonotonicClock:');
  c := DefaultMonotonicClock;
  AssertTrue(c <> nil, 'DefaultMonotonicClock returns non-nil');
end;

procedure Test_DefaultSystemClock;
var
  c: ISystemClock;
begin
  WriteLn('Test_DefaultSystemClock:');
  c := DefaultSystemClock;
  AssertTrue(c <> nil, 'DefaultSystemClock returns non-nil');
end;

procedure Test_DefaultClock;
var
  c: IClock;
begin
  WriteLn('Test_DefaultClock:');
  c := DefaultClock;
  AssertTrue(c <> nil, 'DefaultClock returns non-nil');
end;

// ============================================================================
// IMonotonicClock Tests
// ============================================================================

procedure Test_MonotonicClock_NowInstant;
var
  c: IMonotonicClock;
  t1, t2: TInstant;
begin
  WriteLn('Test_MonotonicClock_NowInstant:');
  c := CreateMonotonicClock;
  t1 := c.NowInstant;
  Sleep(10);
  t2 := c.NowInstant;
  AssertTrue(t2.GreaterThan(t1), 'Time is monotonically increasing');
end;

procedure Test_MonotonicClock_SleepFor;
var
  c: IMonotonicClock;
  t1, t2: TInstant;
  d: TDuration;
begin
  WriteLn('Test_MonotonicClock_SleepFor:');
  c := CreateMonotonicClock;
  t1 := c.NowInstant;
  c.SleepFor(TDuration.FromMs(50));
  t2 := c.NowInstant;
  d := t2.Diff(t1);
  AssertTrue(d.AsMs >= 45, 'SleepFor waits at least 45ms');
  AssertTrue(d.AsMs < 200, 'SleepFor completes within 200ms');
end;

procedure Test_MonotonicClock_SleepUntil;
var
  c: IMonotonicClock;
  t1, target, t2: TInstant;
  d: TDuration;
begin
  WriteLn('Test_MonotonicClock_SleepUntil:');
  c := CreateMonotonicClock;
  t1 := c.NowInstant;
  target := t1.Add(TDuration.FromMs(50));
  c.SleepUntil(target);
  t2 := c.NowInstant;
  d := t2.Diff(t1);
  AssertTrue(d.AsMs >= 45, 'SleepUntil waits at least 45ms');
  AssertTrue(d.AsMs < 200, 'SleepUntil completes within 200ms');
end;

procedure Test_MonotonicClock_WaitFor_Success;
var
  c: IMonotonicClock;
  t1, t2: TInstant;
  d: TDuration;
  success: Boolean;
begin
  WriteLn('Test_MonotonicClock_WaitFor_Success:');
  c := CreateMonotonicClock;
  t1 := c.NowInstant;
  success := c.WaitFor(TDuration.FromMs(50), nil);
  t2 := c.NowInstant;
  d := t2.Diff(t1);
  AssertTrue(success, 'WaitFor returns True on success');
  AssertTrue(d.AsMs >= 45, 'WaitFor waits at least 45ms');
end;

procedure Test_MonotonicClock_WaitFor_Cancelled;
var
  c: IMonotonicClock;
  cts: ICancellationTokenSource;
  t1, t2: TInstant;
  d: TDuration;
  success: Boolean;
begin
  WriteLn('Test_MonotonicClock_WaitFor_Cancelled:');
  c := CreateMonotonicClock;
  cts := CreateCancellationTokenSource;
  cts.Cancel; // Pre-cancel
  t1 := c.NowInstant;
  success := c.WaitFor(TDuration.FromMs(1000), cts.Token);
  t2 := c.NowInstant;
  d := t2.Diff(t1);
  AssertTrue(not success, 'WaitFor returns False when cancelled');
  AssertTrue(d.AsMs < 50, 'Cancelled WaitFor returns quickly');
end;

procedure Test_MonotonicClock_WaitUntil_Cancelled;
var
  c: IMonotonicClock;
  cts: ICancellationTokenSource;
  t1, target, t2: TInstant;
  d: TDuration;
  success: Boolean;
begin
  WriteLn('Test_MonotonicClock_WaitUntil_Cancelled:');
  c := CreateMonotonicClock;
  cts := CreateCancellationTokenSource;
  cts.Cancel; // Pre-cancel
  t1 := c.NowInstant;
  target := t1.Add(TDuration.FromMs(1000));
  success := c.WaitUntil(target, cts.Token);
  t2 := c.NowInstant;
  d := t2.Diff(t1);
  AssertTrue(not success, 'WaitUntil returns False when cancelled');
  AssertTrue(d.AsMs < 50, 'Cancelled WaitUntil returns quickly');
end;

procedure Test_MonotonicClock_GetResolution;
var
  c: IMonotonicClock;
  r: TDuration;
begin
  WriteLn('Test_MonotonicClock_GetResolution:');
  c := CreateMonotonicClock;
  r := c.GetResolution;
  // Resolution should be positive and less than 1 second
  AssertTrue(r.AsNs > 0, 'Resolution is positive');
  AssertTrue(r.AsSec < 1, 'Resolution is better than 1 second');
end;

procedure Test_MonotonicClock_GetName;
var
  c: IMonotonicClock;
  n: string;
begin
  WriteLn('Test_MonotonicClock_GetName:');
  c := CreateMonotonicClock;
  n := c.GetName;
  AssertTrue(Length(n) > 0, 'GetName returns non-empty string');
end;

// ============================================================================
// ISystemClock Tests
// ============================================================================

procedure Test_SystemClock_NowUTC;
var
  c: ISystemClock;
  t: TDateTime;
begin
  WriteLn('Test_SystemClock_NowUTC:');
  c := CreateSystemClock;
  t := c.NowUTC;
  // Should be a valid date (after year 2000, before year 3000)
  AssertTrue(YearOf(t) >= 2000, 'Year is at least 2000');
  AssertTrue(YearOf(t) < 3000, 'Year is before 3000');
end;

procedure Test_SystemClock_NowLocal;
var
  c: ISystemClock;
  t: TDateTime;
begin
  WriteLn('Test_SystemClock_NowLocal:');
  c := CreateSystemClock;
  t := c.NowLocal;
  // Should be a valid date
  AssertTrue(YearOf(t) >= 2000, 'Year is at least 2000');
  AssertTrue(YearOf(t) < 3000, 'Year is before 3000');
end;

procedure Test_SystemClock_NowUnixMs;
var
  c: ISystemClock;
  ms1, ms2: Int64;
begin
  WriteLn('Test_SystemClock_NowUnixMs:');
  c := CreateSystemClock;
  ms1 := c.NowUnixMs;
  Sleep(10);
  ms2 := c.NowUnixMs;
  AssertTrue(ms1 > 0, 'Unix timestamp is positive');
  AssertTrue(ms2 >= ms1, 'Unix timestamp is monotonic');
  AssertTrue(ms2 - ms1 >= 10, 'At least 10ms passed');
end;

procedure Test_SystemClock_NowUnixNs;
var
  c: ISystemClock;
  ns1, ns2: Int64;
begin
  WriteLn('Test_SystemClock_NowUnixNs:');
  c := CreateSystemClock;
  ns1 := c.NowUnixNs;
  Sleep(10);
  ns2 := c.NowUnixNs;
  AssertTrue(ns1 > 0, 'Unix ns timestamp is positive');
  AssertTrue(ns2 >= ns1, 'Unix ns timestamp is monotonic');
  AssertTrue(ns2 - ns1 >= 10000000, 'At least 10ms passed (in ns)');
end;

procedure Test_SystemClock_GetTimeZoneOffset;
var
  c: ISystemClock;
  offset: TDuration;
  offsetHours: Int64;
begin
  WriteLn('Test_SystemClock_GetTimeZoneOffset:');
  c := CreateSystemClock;
  offset := c.GetTimeZoneOffset;
  // Offset should be between -14 and +14 hours (convert seconds to hours)
  offsetHours := offset.AsSec div 3600;
  AssertTrue(Abs(offsetHours) <= 14, 'Offset is within valid range');
end;

procedure Test_SystemClock_GetTimeZoneName;
var
  c: ISystemClock;
  n: string;
begin
  WriteLn('Test_SystemClock_GetTimeZoneName:');
  c := CreateSystemClock;
  n := c.GetTimeZoneName;
  // May be empty on some systems, but should not crash
  AssertTrue(True, 'GetTimeZoneName does not crash');
end;

// ============================================================================
// IClock Tests (Combined Interface)
// ============================================================================

procedure Test_Clock_GetMonotonicClock;
var
  c: IClock;
  mono: IMonotonicClock;
begin
  WriteLn('Test_Clock_GetMonotonicClock:');
  c := CreateClock;
  mono := c.GetMonotonicClock;
  AssertTrue(mono <> nil, 'GetMonotonicClock returns non-nil');
end;

procedure Test_Clock_GetSystemClock;
var
  c: IClock;
  sys: ISystemClock;
begin
  WriteLn('Test_Clock_GetSystemClock:');
  c := CreateClock;
  sys := c.GetSystemClock;
  AssertTrue(sys <> nil, 'GetSystemClock returns non-nil');
end;

// ============================================================================
// IFixedClock Tests
// ============================================================================

procedure Test_FixedClock_SetInstant;
var
  c: IFixedClock;
  t1, t2: TInstant;
begin
  WriteLn('Test_FixedClock_SetInstant:');
  c := CreateFixedClock;
  t1 := TInstant.FromNsSinceEpoch(1234567890000000000);
  c.SetInstant(t1);
  t2 := c.NowInstant;
  AssertTrue(t1.Equal(t2), 'SetInstant sets the instant correctly');
end;

procedure Test_FixedClock_SetDateTime;
var
  c: IFixedClock;
  dt1, dt2: TDateTime;
begin
  WriteLn('Test_FixedClock_SetDateTime:');
  c := CreateFixedClock;
  dt1 := EncodeDateTime(2024, 12, 25, 14, 30, 0, 0);
  c.SetDateTime(dt1);
  dt2 := c.NowUTC;
  // Check date components match (TDateTime precision is ~1ms)
  AssertTrue(YearOf(dt2) = 2024, 'Year matches');
  AssertTrue(MonthOf(dt2) = 12, 'Month matches');
  AssertTrue(DayOf(dt2) = 25, 'Day matches');
  AssertTrue(HourOf(dt2) = 14, 'Hour matches');
  AssertTrue(MinuteOf(dt2) = 30, 'Minute matches');
end;

procedure Test_FixedClock_AdvanceBy;
var
  c: IFixedClock;
  t1, t2: TInstant;
  d: TDuration;
begin
  WriteLn('Test_FixedClock_AdvanceBy:');
  c := CreateFixedClock;
  c.SetInstant(TInstant.FromNsSinceEpoch(0));
  t1 := c.NowInstant;
  d := TDuration.FromMs(100);
  c.AdvanceBy(d);
  t2 := c.NowInstant;
  AssertEquals(100, t2.Diff(t1).AsMs, 'AdvanceBy advances by correct amount');
end;

procedure Test_FixedClock_AdvanceTo;
var
  c: IFixedClock;
  target, t2: TInstant;
begin
  WriteLn('Test_FixedClock_AdvanceTo:');
  c := CreateFixedClock;
  c.SetInstant(TInstant.FromNsSinceEpoch(0));
  target := TInstant.FromUnixMs(500);
  c.AdvanceTo(target);
  t2 := c.NowInstant;
  AssertTrue(t2.Equal(target), 'AdvanceTo sets instant correctly');
end;

procedure Test_FixedClock_Reset;
var
  c: IFixedClock;
  t1: TInstant;
begin
  WriteLn('Test_FixedClock_Reset:');
  c := CreateFixedClock;
  c.SetInstant(TInstant.FromUnixMs(12345));
  c.Reset;
  t1 := c.NowInstant;
  // After reset, instant should be 0
  AssertEquals(0, Int64(t1.AsNsSinceEpoch), 'Reset sets instant to 0');
end;

procedure Test_FixedClock_GetFixedInstant;
var
  c: IFixedClock;
  t1, t2: TInstant;
begin
  WriteLn('Test_FixedClock_GetFixedInstant:');
  c := CreateFixedClock;
  t1 := TInstant.FromUnixMs(42);
  c.SetInstant(t1);
  t2 := c.GetFixedInstant;
  AssertTrue(t1.Equal(t2), 'GetFixedInstant returns correct instant');
end;

procedure Test_FixedClock_SleepFor_NoOp;
var
  c: IFixedClock;
  t1, t2: TInstant;
begin
  WriteLn('Test_FixedClock_SleepFor_NoOp:');
  c := CreateFixedClock;
  c.SetInstant(TInstant.FromUnixMs(100));
  t1 := c.NowInstant;
  c.SleepFor(TDuration.FromMs(50)); // Should not actually sleep
  t2 := c.NowInstant;
  // FixedClock.SleepFor advances time instead of sleeping
  AssertTrue(t2.GreaterThan(t1) or t2.Equal(t1), 'Time does not go backwards');
end;

// ============================================================================
// Convenience Function Tests
// ============================================================================

procedure Test_NowInstant;
var
  t1, t2: TInstant;
begin
  WriteLn('Test_NowInstant:');
  t1 := NowInstant;
  Sleep(10);
  t2 := NowInstant;
  AssertTrue(t2.GreaterThan(t1), 'NowInstant is monotonic');
end;

procedure Test_NowUTC;
var
  t: TDateTime;
begin
  WriteLn('Test_NowUTC:');
  t := NowUTC;
  AssertTrue(YearOf(t) >= 2020, 'NowUTC returns valid year');
end;

procedure Test_NowLocal;
var
  t: TDateTime;
begin
  WriteLn('Test_NowLocal:');
  t := NowLocal;
  AssertTrue(YearOf(t) >= 2020, 'NowLocal returns valid year');
end;

procedure Test_NowUnixMs;
var
  ms: Int64;
begin
  WriteLn('Test_NowUnixMs:');
  ms := NowUnixMs;
  // Should be after year 2000 (946684800000 ms)
  AssertTrue(ms > 946684800000, 'NowUnixMs is after year 2000');
end;

procedure Test_NowUnixNs;
var
  ns: Int64;
begin
  WriteLn('Test_NowUnixNs:');
  ns := NowUnixNs;
  // Should be positive
  AssertTrue(ns > 0, 'NowUnixNs is positive');
end;

procedure Test_SleepFor;
var
  t1, t2: TInstant;
  d: TDuration;
begin
  WriteLn('Test_SleepFor:');
  t1 := NowInstant;
  SleepFor(TDuration.FromMs(50));
  t2 := NowInstant;
  d := t2.Diff(t1);
  AssertTrue(d.AsMs >= 45, 'SleepFor waits at least 45ms');
end;

procedure Test_TimeIt;
var
  d: TDuration;
begin
  WriteLn('Test_TimeIt:');
  d := TimeIt(procedure begin Sleep(50); end);
  AssertTrue(d.AsMs >= 45, 'TimeIt measures at least 45ms');
  AssertTrue(d.AsMs < 200, 'TimeIt measures less than 200ms');
end;

// ============================================================================
// Sleep Strategy Tests
// ============================================================================

procedure Test_SetGetSleepStrategy;
var
  original, current: TSleepStrategy;
begin
  WriteLn('Test_SetGetSleepStrategy:');
  original := GetSleepStrategy;
  
  SetSleepStrategy(ssLowLatency);
  current := GetSleepStrategy;
  AssertTrue(current = ssLowLatency, 'Set to LowLatency');
  
  SetSleepStrategy(ssLowPower);
  current := GetSleepStrategy;
  AssertTrue(current = ssLowPower, 'Set to LowPower');
  
  // Restore original
  SetSleepStrategy(original);
end;

procedure Test_SetSleepStrategyParams;
var
  spin, micro, slice: Int64;
begin
  WriteLn('Test_SetSleepStrategyParams:');
  // Set custom params
  SetSleepStrategyParams(5000, 10000, 100000); // 5us, 10us, 100us
  GetSleepStrategyParams(spin, micro, slice);
  
  AssertEquals(5000, spin, 'Final spin set correctly');
  AssertEquals(10000, micro, 'Micro sleep set correctly');
  AssertEquals(100000, slice, 'Slice sleep set correctly');
  
  // Strategy should be custom
  AssertTrue(GetSleepStrategy = ssCustom, 'Strategy is custom');
  
  // Restore to balanced
  SetSleepStrategy(ssBalanced);
end;

// ============================================================================
// Cancellation Check Interval Tests
// ============================================================================

procedure Test_SetGetCancellationCheckInterval;
var
  original, current: TDuration;
begin
  WriteLn('Test_SetGetCancellationCheckInterval:');
  original := GetCancellationCheckInterval;
  
  SetCancellationCheckInterval(TDuration.FromMs(5));
  current := GetCancellationCheckInterval;
  AssertEquals(5, current.AsMs, 'Interval set to 5ms');
  
  SetCancellationCheckInterval(TDuration.FromUs(500));
  current := GetCancellationCheckInterval;
  AssertEquals(500, current.AsUs, 'Interval set to 500us');
  
  // Restore original
  SetCancellationCheckInterval(original);
end;

// ============================================================================
// Main
// ============================================================================

begin
  WriteLn;
  WriteLn('========================================');
  WriteLn('  fafafa.core.time.clock Tests');
  WriteLn('========================================');
  WriteLn;
  
  // Factory function tests
  Test_CreateMonotonicClock;
  Test_CreateSystemClock;
  Test_CreateClock;
  Test_CreateFixedClock;
  Test_DefaultMonotonicClock;
  Test_DefaultSystemClock;
  Test_DefaultClock;
  
  // IMonotonicClock tests
  Test_MonotonicClock_NowInstant;
  Test_MonotonicClock_SleepFor;
  Test_MonotonicClock_SleepUntil;
  Test_MonotonicClock_WaitFor_Success;
  Test_MonotonicClock_WaitFor_Cancelled;
  Test_MonotonicClock_WaitUntil_Cancelled;
  Test_MonotonicClock_GetResolution;
  Test_MonotonicClock_GetName;
  
  // ISystemClock tests
  Test_SystemClock_NowUTC;
  Test_SystemClock_NowLocal;
  Test_SystemClock_NowUnixMs;
  Test_SystemClock_NowUnixNs;
  Test_SystemClock_GetTimeZoneOffset;
  Test_SystemClock_GetTimeZoneName;
  
  // IClock tests
  Test_Clock_GetMonotonicClock;
  Test_Clock_GetSystemClock;
  
  // IFixedClock tests
  Test_FixedClock_SetInstant;
  Test_FixedClock_SetDateTime;
  Test_FixedClock_AdvanceBy;
  Test_FixedClock_AdvanceTo;
  Test_FixedClock_Reset;
  Test_FixedClock_GetFixedInstant;
  Test_FixedClock_SleepFor_NoOp;
  
  // Convenience function tests
  Test_NowInstant;
  Test_NowUTC;
  Test_NowLocal;
  Test_NowUnixMs;
  Test_NowUnixNs;
  Test_SleepFor;
  Test_TimeIt;
  
  // Sleep strategy tests
  Test_SetGetSleepStrategy;
  Test_SetSleepStrategyParams;
  
  // Cancellation check interval tests
  Test_SetGetCancellationCheckInterval;
  
  WriteLn;
  WriteLn('========================================');
  WriteLn('  Total: ', TotalTests, '  Passed: ', PassedTests, '  Failed: ', FailedTests);
  WriteLn('========================================');
  
  if FailedTests > 0 then
    Halt(1);
end.
