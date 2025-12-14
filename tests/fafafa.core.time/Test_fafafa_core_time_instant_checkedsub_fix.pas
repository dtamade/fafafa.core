{$mode objfpc}{$H+}{$J-}

unit Test_fafafa_core_time_instant_checkedsub_fix;

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.instant, fafafa.core.time.duration;

type
  { TTestInstantCheckedSubFix }
  TTestInstantCheckedSubFix = class(TTestCase)
  published
    // ISSUE-6: 测试 CheckedSub 方法不会因为 Low(Int64) 导致溢出
    procedure Test_CheckedSub_WithLowInt64_ShouldReturnFalse;
    procedure Test_CheckedSub_WithHighInt64_ShouldWork;
    procedure Test_CheckedSub_WithZero_ShouldSucceed;
    procedure Test_CheckedSub_WithPositive_ShouldDecrease;
    procedure Test_CheckedSub_WithNegative_ShouldIncrease;
    procedure Test_CheckedSub_Underflow_ReturnsFalse;
    procedure Test_CheckedSub_Overflow_ReturnsFalse;
    procedure Test_CheckedSub_AtBoundary_ShouldSucceed;
  end;

implementation

{ TTestInstantCheckedSubFix }

procedure TTestInstantCheckedSubFix.Test_CheckedSub_WithLowInt64_ShouldReturnFalse;
var
  t: TInstant;
  d: TDuration;
  r: TInstant;
  ok: Boolean;
begin
  // 这是 ISSUE-6 CheckedSub 的核心测试用例
  // D.AsNs = Low(Int64) = -9223372036854775808
  // CheckedSub 无法处理 Low(Int64)（因为其绝对值无法表示为 Int64），
  // 所以应该返回 False
  
  t := TInstant.FromUnixSec(1000000000); // 约 2001 年
  d := TDuration.FromNs(Low(Int64));
  
  ok := t.CheckedSub(d, r);
  
  // 期望结果：返回 False（因为无法安全计算）
  AssertFalse('CheckedSub with Low(Int64) should return False', ok);
end;

procedure TTestInstantCheckedSubFix.Test_CheckedSub_WithHighInt64_ShouldWork;
var
  t: TInstant;
  d: TDuration;
  r: TInstant;
  ok: Boolean;
begin
  // D.AsNs = High(Int64)
  // CheckedSub(High(Int64)) 应该成功，因为 t 足够大
  
  t := TInstant.FromNsSinceEpoch(High(UInt64));
  d := TDuration.FromNs(High(Int64));
  
  ok := t.CheckedSub(d, r);
  
  AssertTrue('CheckedSub with High(Int64) should succeed', ok);
  // High(UInt64) - High(Int64) = 9223372036854775808
  AssertEquals('CheckedSub result', UInt64(9223372036854775808), r.AsNsSinceEpoch);
end;

procedure TTestInstantCheckedSubFix.Test_CheckedSub_WithZero_ShouldSucceed;
var
  t: TInstant;
  d: TDuration;
  r: TInstant;
  ok: Boolean;
begin
  t := TInstant.FromUnixSec(1000000000);
  d := TDuration.Zero;
  
  ok := t.CheckedSub(d, r);
  
  AssertTrue('CheckedSub with Zero should succeed', ok);
  AssertEquals('CheckedSub with Zero should return same', 
               t.AsNsSinceEpoch, r.AsNsSinceEpoch);
end;

procedure TTestInstantCheckedSubFix.Test_CheckedSub_WithPositive_ShouldDecrease;
var
  t: TInstant;
  d: TDuration;
  r: TInstant;
  ok: Boolean;
  expected: UInt64;
begin
  t := TInstant.FromUnixSec(1000000000); // 1000000000 * 10^9 ns
  d := TDuration.FromSec(100);           // 100 * 10^9 ns
  
  ok := t.CheckedSub(d, r);
  
  AssertTrue('CheckedSub with positive duration should succeed', ok);
  expected := UInt64(1000000000) * 1000000000 - UInt64(100) * 1000000000;
  AssertEquals('CheckedSub result', expected, r.AsNsSinceEpoch);
end;

procedure TTestInstantCheckedSubFix.Test_CheckedSub_WithNegative_ShouldIncrease;
var
  t: TInstant;
  d: TDuration;
  r: TInstant;
  ok: Boolean;
  expected: UInt64;
begin
  // 减去负持续时间 == 加上正持续时间
  t := TInstant.FromUnixSec(100);
  d := TDuration.FromSec(-100); // 负 100 秒
  
  ok := t.CheckedSub(d, r);
  
  AssertTrue('CheckedSub with negative duration should succeed', ok);
  expected := UInt64(100) * 1000000000 + UInt64(100) * 1000000000;
  AssertEquals('CheckedSub result', expected, r.AsNsSinceEpoch);
end;

procedure TTestInstantCheckedSubFix.Test_CheckedSub_Underflow_ReturnsFalse;
var
  t: TInstant;
  d: TDuration;
  r: TInstant;
  ok: Boolean;
begin
  // 减去比当前时间更大的持续时间，应该返回 False
  t := TInstant.FromUnixSec(100);
  d := TDuration.FromSec(1000); // 远大于 t
  
  ok := t.CheckedSub(d, r);
  
  AssertFalse('CheckedSub that would underflow should return False', ok);
end;

procedure TTestInstantCheckedSubFix.Test_CheckedSub_Overflow_ReturnsFalse;
var
  t: TInstant;
  d: TDuration;
  r: TInstant;
  ok: Boolean;
begin
  // 减去大负数，使其超过 High(UInt64)
  // t 接近 High(UInt64)，减去 Low(Int64)+1 (一个可以表示的大负数)
  t := TInstant.FromNsSinceEpoch(High(UInt64) - 100);
  d := TDuration.FromNs(Low(Int64) + 1); // -9223372036854775807
  
  ok := t.CheckedSub(d, r);
  
  // CheckedSub(-9223372036854775807) 等价于 CheckedAdd(9223372036854775807)
  // 由于 t 接近 High(UInt64)，这会导致溢出
  AssertFalse('CheckedSub that would overflow should return False', ok);
end;

procedure TTestInstantCheckedSubFix.Test_CheckedSub_AtBoundary_ShouldSucceed;
var
  t: TInstant;
  d: TDuration;
  r: TInstant;
  ok: Boolean;
begin
  // 精确边界测试：刚好不溢出
  t := TInstant.FromUnixSec(100);
  d := TDuration.FromNs(t.AsNsSinceEpoch); // 刚好减到 0
  
  ok := t.CheckedSub(d, r);
  
  AssertTrue('CheckedSub at exact boundary should succeed', ok);
  AssertEquals('Result should be 0', UInt64(0), r.AsNsSinceEpoch);
end;

initialization
  RegisterTest(TTestInstantCheckedSubFix);

end.
