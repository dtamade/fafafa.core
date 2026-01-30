{$mode objfpc}{$H+}{$J-}

unit Test_fafafa_core_time_instant_sub_fix;

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.instant, fafafa.core.time.duration;

type
  { TTestInstantSubFix }
  TTestInstantSubFix = class(TTestCase)
  published
    // ISSUE-6: 测试 Sub 方法不会因为 Low(Int64) 导致溢出
    procedure Test_Sub_WithLowInt64_ShouldNotOverflow;
    procedure Test_Sub_WithHighInt64_ShouldWork;
    procedure Test_Sub_WithZero_ShouldReturnSame;
    procedure Test_Sub_WithPositive_ShouldDecrease;
    procedure Test_Sub_WithNegative_ShouldIncrease;
    procedure Test_Sub_ResultSaturatesAtZero;
    procedure Test_Sub_ResultSaturatesAtMax;
    procedure Test_Sub_EdgeCase_NearMaxDuration;
    procedure Test_Sub_Consistency_WithAdd;
  end;

implementation

{ TTestInstantSubFix }

procedure TTestInstantSubFix.Test_Sub_WithLowInt64_ShouldNotOverflow;
var
  t: TInstant;
  d: TDuration;
  result: TInstant;
begin
  // 这是 ISSUE-6 的核心测试用例
  // D.AsNs = Low(Int64) = -9223372036854775808
  // Sub(D) 应该等价于 Add(|Low(Int64)|)
  // 由于 |Low(Int64)| 无法表示为 Int64，应该饱和到 High(UInt64)
  
  t := TInstant.FromUnixSec(1000000000); // 约 2001 年
  d := TDuration.FromNs(Low(Int64));
  
  result := t.Sub(d);
  
  // 期望结果：应该饱和到 High(UInt64)
  AssertEquals('Sub with Low(Int64) should saturate to max', 
               High(UInt64), result.AsNsSinceEpoch);
end;

procedure TTestInstantSubFix.Test_Sub_WithHighInt64_ShouldWork;
var
  t: TInstant;
  d: TDuration;
  result: TInstant;
begin
  // D.AsNs = High(Int64)
  // Sub(High(Int64)) 应该等价于减去最大正持续时间
  
  t := TInstant.FromNsSinceEpoch(High(UInt64));
  d := TDuration.FromNs(High(Int64));
  
  result := t.Sub(d);
  
  // High(UInt64) - High(Int64) = 9223372036854775808
  AssertEquals('Sub with High(Int64)', 
               UInt64(9223372036854775808), result.AsNsSinceEpoch);
end;

procedure TTestInstantSubFix.Test_Sub_WithZero_ShouldReturnSame;
var
  t: TInstant;
  d: TDuration;
  result: TInstant;
begin
  t := TInstant.FromUnixSec(1000000000);
  d := TDuration.Zero;
  
  result := t.Sub(d);
  
  AssertEquals('Sub with Zero should return same', 
               t.AsNsSinceEpoch, result.AsNsSinceEpoch);
end;

procedure TTestInstantSubFix.Test_Sub_WithPositive_ShouldDecrease;
var
  t: TInstant;
  d: TDuration;
  result: TInstant;
  expected: UInt64;
begin
  t := TInstant.FromUnixSec(1000000000); // 1000000000 * 10^9 ns
  d := TDuration.FromSec(100);           // 100 * 10^9 ns
  
  result := t.Sub(d);
  
  expected := UInt64(1000000000) * 1000000000 - UInt64(100) * 1000000000;
  AssertEquals('Sub with positive duration should decrease', 
               expected, result.AsNsSinceEpoch);
end;

procedure TTestInstantSubFix.Test_Sub_WithNegative_ShouldIncrease;
var
  t: TInstant;
  d: TDuration;
  result: TInstant;
  expected: UInt64;
begin
  // 减去负持续时间 == 加上正持续时间
  t := TInstant.FromUnixSec(1000000000);
  d := TDuration.FromSec(-100); // 负 100 秒
  
  result := t.Sub(d);
  
  expected := UInt64(1000000000) * 1000000000 + UInt64(100) * 1000000000;
  AssertEquals('Sub with negative duration should increase', 
               expected, result.AsNsSinceEpoch);
end;

procedure TTestInstantSubFix.Test_Sub_ResultSaturatesAtZero;
var
  t: TInstant;
  d: TDuration;
  result: TInstant;
begin
  // 减去比当前时间更大的持续时间，应该饱和到 0
  t := TInstant.FromUnixSec(100);
  d := TDuration.FromSec(1000); // 远大于 t
  
  result := t.Sub(d);
  
  AssertEquals('Sub that would underflow should saturate to 0', 
               0, result.AsNsSinceEpoch);
end;

procedure TTestInstantSubFix.Test_Sub_ResultSaturatesAtMax;
var
  t: TInstant;
  d: TDuration;
  result: TInstant;
begin
  // 减去大负数，使其超过 High(UInt64) 并饱和
  // 使用 High(UInt64) - 1000 和 Low(Int64) （绝对值无法表示为 Int64）
  t := TInstant.FromNsSinceEpoch(High(UInt64) - 1000);
  d := TDuration.FromNs(Low(Int64)); // Low(Int64) 的绝对值无法表示为 Int64
  
  result := t.Sub(d);
  
  // Sub(Low(Int64)) 应该饱和到 High(UInt64)
  AssertEquals('Sub with Low(Int64) should saturate to max', 
               High(UInt64), result.AsNsSinceEpoch);
end;

procedure TTestInstantSubFix.Test_Sub_EdgeCase_NearMaxDuration;
var
  t: TInstant;
  d: TDuration;
  result: TInstant;
begin
  // 接近最大值的边界测试
  t := TInstant.FromNsSinceEpoch(High(UInt64) - 1000);
  d := TDuration.FromNs(-500); // 减去 -500，即加 500
  
  result := t.Sub(d);
  
  AssertEquals('Sub near max boundary', 
               High(UInt64) - 500, result.AsNsSinceEpoch);
end;

procedure TTestInstantSubFix.Test_Sub_Consistency_WithAdd;
var
  t: TInstant;
  d: TDuration;
  result1, result2: TInstant;
begin
  // Sub(D) 应该等于 Add(-D) （在没有溢出的情况下）
  t := TInstant.FromUnixSec(1000000000);
  d := TDuration.FromSec(100);
  
  result1 := t.Sub(d);
  result2 := t.Add(TDuration.FromNs(-d.AsNs));
  
  AssertEquals('Sub(D) should equal Add(-D)', 
               result1.AsNsSinceEpoch, result2.AsNsSinceEpoch);
end;

initialization
  RegisterTest(TTestInstantSubFix);

end.
