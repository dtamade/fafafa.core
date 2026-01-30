{$mode objfpc}{$H+}{$J-}
{$I ..\..\src\fafafa.core.settings.inc}

unit Test_fafafa_core_time_deadline;

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.math,
  fafafa.core.time.duration,
  fafafa.core.time.instant,
  fafafa.core.time.timeout,
  fafafa.core.time.clock;

type
  { TTestDeadline - TDeadline 测试 }
  TTestDeadline = class(TTestCase)
  published
    // 构造函数测试
    procedure Test_Never_ReturnsMaxInstant;
    procedure Test_Now_ReturnsCurrentTime;
    procedure Test_After_CreatesDeadlineInFuture;
    procedure Test_At_CreatesDeadlineAtSpecifiedInstant;
    procedure Test_FromInstant_SameAsAt;
    procedure Test_FromNow_SameAsAfter;
    
    // 查询操作测试
    procedure Test_GetInstant_ReturnsStoredInstant;
    procedure Test_Remaining_ReturnsPositiveForFuture;
    procedure Test_Remaining_ReturnsNegativeForPast;
    procedure Test_RemainingClampedZero_ClampsNegative;
    procedure Test_HasExpired_FalseForFuture;
    procedure Test_HasExpired_TrueForPast;
    procedure Test_HasExpired_NeverIsFalse;
    procedure Test_IsNever_TrueForNever;
    procedure Test_IsNever_FalseForOther;
    
    // 时间计算测试
    procedure Test_Overdue_ZeroForFuture;
    procedure Test_Overdue_PositiveForPast;
    
    // 操作测试
    procedure Test_Extend_AddsTime;
    procedure Test_Extend_NeverRemainsNever;
    procedure Test_ExtendTo_SetsNewInstant;
    
    // 比较测试
    procedure Test_Compare_EqualDeadlines;
    procedure Test_Compare_NeverGreaterThanAll;
    procedure Test_Compare_EarlierLessThanLater;
    procedure Test_Equal_SameDeadlines;
    procedure Test_LessThan_EarlierDeadline;
    procedure Test_GreaterThan_LaterDeadline;
    
    // 运算符测试
    procedure Test_Operator_Equal;
    procedure Test_Operator_LessThan;
    procedure Test_Operator_GreaterThan;
    
    // ToString 测试
    procedure Test_ToString_Never;
    procedure Test_ToString_Future;
  end;

implementation

{ TTestDeadline }

procedure TTestDeadline.Test_Never_ReturnsMaxInstant;
var
  D: TDeadline;
begin
  D := TDeadline.Never;
  CheckTrue(D.IsNever, 'Never deadline should be marked as never');
  CheckFalse(D.HasExpired, 'Never deadline should never expire');
end;

procedure TTestDeadline.Test_Now_ReturnsCurrentTime;
var
  D: TDeadline;
  Before, After: TInstant;
begin
  Before := NowInstant;
  D := TDeadline.Now;
  After := NowInstant;
  
  CheckTrue((D.GetInstant.Compare(Before) >= 0) and (D.GetInstant.Compare(After) <= 0),
    'Now deadline should be between before and after instants');
end;

procedure TTestDeadline.Test_After_CreatesDeadlineInFuture;
var
  D: TDeadline;
  Duration: TDuration;
begin
  Duration := TDuration.FromMs(100);
  D := TDeadline.After(Duration);
  
  CheckFalse(D.HasExpired, 'Deadline 100ms in future should not be expired');
  CheckTrue(D.Remaining.AsMs > 0, 'Remaining time should be positive');
end;

procedure TTestDeadline.Test_At_CreatesDeadlineAtSpecifiedInstant;
var
  D: TDeadline;
  T: TInstant;
begin
  T := NowInstant.Add(TDuration.FromMs(500));
  D := TDeadline.At(T);
  
  CheckTrue(D.GetInstant.Equal(T), 'Deadline should be at specified instant');
end;

procedure TTestDeadline.Test_FromInstant_SameAsAt;
var
  D1, D2: TDeadline;
  T: TInstant;
begin
  T := NowInstant.Add(TDuration.FromMs(200));
  D1 := TDeadline.At(T);
  D2 := TDeadline.FromInstant(T);
  
  CheckTrue(D1.Equal(D2), 'FromInstant should be same as At');
end;

procedure TTestDeadline.Test_FromNow_SameAsAfter;
var
  D1, D2: TDeadline;
  Duration: TDuration;
begin
  Duration := TDuration.FromMs(100);
  D1 := TDeadline.After(Duration);
  D2 := TDeadline.FromNow(Duration);
  
  // 允许少量时间差
  CheckTrue(Abs(D1.GetInstant.Diff(D2.GetInstant).AsMs) < 10,
    'FromNow should be approximately same as After');
end;

procedure TTestDeadline.Test_GetInstant_ReturnsStoredInstant;
var
  D: TDeadline;
  T: TInstant;
begin
  T := NowInstant;
  D := TDeadline.At(T);
  
  CheckTrue(D.GetInstant.Equal(T), 'GetInstant should return stored instant');
end;

procedure TTestDeadline.Test_Remaining_ReturnsPositiveForFuture;
var
  D: TDeadline;
begin
  D := TDeadline.After(TDuration.FromMs(1000));
  CheckTrue(D.Remaining.AsMs > 0, 'Remaining should be positive for future deadline');
end;

procedure TTestDeadline.Test_Remaining_ReturnsNegativeForPast;
var
  D: TDeadline;
  PastInstant: TInstant;
begin
  PastInstant := NowInstant.Sub(TDuration.FromMs(100));
  D := TDeadline.At(PastInstant);
  
  CheckTrue(D.Remaining.IsNegative, 'Remaining should be negative for past deadline');
end;

procedure TTestDeadline.Test_RemainingClampedZero_ClampsNegative;
var
  D: TDeadline;
  PastInstant, Now: TInstant;
begin
  Now := NowInstant;
  PastInstant := Now.Sub(TDuration.FromMs(100));
  D := TDeadline.At(PastInstant);
  
  CheckEquals(0, D.RemainingClampedZero(Now).AsMs, 'RemainingClampedZero should return 0 for past deadline');
end;

procedure TTestDeadline.Test_HasExpired_FalseForFuture;
var
  D: TDeadline;
begin
  D := TDeadline.After(TDuration.FromMs(1000));
  CheckFalse(D.HasExpired, 'Future deadline should not be expired');
end;

procedure TTestDeadline.Test_HasExpired_TrueForPast;
var
  D: TDeadline;
  PastInstant: TInstant;
begin
  PastInstant := NowInstant.Sub(TDuration.FromMs(100));
  D := TDeadline.At(PastInstant);
  
  CheckTrue(D.HasExpired, 'Past deadline should be expired');
end;

procedure TTestDeadline.Test_HasExpired_NeverIsFalse;
var
  D: TDeadline;
begin
  D := TDeadline.Never;
  CheckFalse(D.HasExpired, 'Never deadline should never be expired');
end;

procedure TTestDeadline.Test_IsNever_TrueForNever;
var
  D: TDeadline;
begin
  D := TDeadline.Never;
  CheckTrue(D.IsNever, 'Never deadline should return true for IsNever');
end;

procedure TTestDeadline.Test_IsNever_FalseForOther;
var
  D: TDeadline;
begin
  D := TDeadline.After(TDuration.FromMs(100));
  CheckFalse(D.IsNever, 'Normal deadline should return false for IsNever');
end;

procedure TTestDeadline.Test_Overdue_ZeroForFuture;
var
  D: TDeadline;
begin
  D := TDeadline.After(TDuration.FromMs(1000));
  CheckEquals(0, D.Overdue(NowInstant).AsMs, 'Overdue should be 0 for future deadline');
end;

procedure TTestDeadline.Test_Overdue_PositiveForPast;
var
  D: TDeadline;
  PastInstant, Now: TInstant;
begin
  Now := NowInstant;
  PastInstant := Now.Sub(TDuration.FromMs(100));
  D := TDeadline.At(PastInstant);
  
  CheckTrue(D.Overdue(Now).AsMs >= 100, 'Overdue should be positive for past deadline');
end;

procedure TTestDeadline.Test_Extend_AddsTime;
var
  D, Extended: TDeadline;
  Extension: TDuration;
begin
  D := TDeadline.After(TDuration.FromMs(100));
  Extension := TDuration.FromMs(200);
  Extended := D.Extend(Extension);
  
  CheckTrue(Extended.Remaining.AsMs > D.Remaining.AsMs,
    'Extended deadline should have more remaining time');
end;

procedure TTestDeadline.Test_Extend_NeverRemainsNever;
var
  D, Extended: TDeadline;
begin
  D := TDeadline.Never;
  Extended := D.Extend(TDuration.FromMs(100));
  
  CheckTrue(Extended.IsNever, 'Extended Never deadline should still be Never');
end;

procedure TTestDeadline.Test_ExtendTo_SetsNewInstant;
var
  D, Extended: TDeadline;
  NewInstant: TInstant;
begin
  D := TDeadline.After(TDuration.FromMs(100));
  NewInstant := NowInstant.Add(TDuration.FromMs(500));
  Extended := D.ExtendTo(NewInstant);
  
  CheckTrue(Extended.GetInstant.Equal(NewInstant), 'ExtendTo should set new instant');
end;

procedure TTestDeadline.Test_Compare_EqualDeadlines;
var
  T: TInstant;
  D1, D2: TDeadline;
begin
  T := NowInstant;
  D1 := TDeadline.At(T);
  D2 := TDeadline.At(T);
  
  CheckEquals(0, D1.Compare(D2), 'Equal deadlines should compare as 0');
end;

procedure TTestDeadline.Test_Compare_NeverGreaterThanAll;
var
  D1, D2: TDeadline;
begin
  D1 := TDeadline.Never;
  D2 := TDeadline.After(TDuration.FromMs(1000000));
  
  CheckTrue(D1.Compare(D2) > 0, 'Never should be greater than any finite deadline');
end;

procedure TTestDeadline.Test_Compare_EarlierLessThanLater;
var
  D1, D2: TDeadline;
begin
  D1 := TDeadline.After(TDuration.FromMs(100));
  D2 := TDeadline.After(TDuration.FromMs(200));
  
  CheckTrue(D1.Compare(D2) < 0, 'Earlier deadline should compare as less than later');
end;

procedure TTestDeadline.Test_Equal_SameDeadlines;
var
  T: TInstant;
  D1, D2: TDeadline;
begin
  T := NowInstant;
  D1 := TDeadline.At(T);
  D2 := TDeadline.At(T);
  
  CheckTrue(D1.Equal(D2), 'Same deadlines should be equal');
end;

procedure TTestDeadline.Test_LessThan_EarlierDeadline;
var
  D1, D2: TDeadline;
begin
  D1 := TDeadline.After(TDuration.FromMs(100));
  D2 := TDeadline.After(TDuration.FromMs(200));
  
  CheckTrue(D1.LessThan(D2), 'Earlier deadline should be less than later');
end;

procedure TTestDeadline.Test_GreaterThan_LaterDeadline;
var
  D1, D2: TDeadline;
begin
  D1 := TDeadline.After(TDuration.FromMs(200));
  D2 := TDeadline.After(TDuration.FromMs(100));
  
  CheckTrue(D1.GreaterThan(D2), 'Later deadline should be greater than earlier');
end;

procedure TTestDeadline.Test_Operator_Equal;
var
  T: TInstant;
  D1, D2: TDeadline;
begin
  T := NowInstant;
  D1 := TDeadline.At(T);
  D2 := TDeadline.At(T);
  
  CheckTrue(D1 = D2, 'Operator = should return true for equal deadlines');
end;

procedure TTestDeadline.Test_Operator_LessThan;
var
  D1, D2: TDeadline;
begin
  D1 := TDeadline.After(TDuration.FromMs(100));
  D2 := TDeadline.After(TDuration.FromMs(200));
  
  CheckTrue(D1 < D2, 'Operator < should return true for earlier deadline');
end;

procedure TTestDeadline.Test_Operator_GreaterThan;
var
  D1, D2: TDeadline;
begin
  D1 := TDeadline.After(TDuration.FromMs(200));
  D2 := TDeadline.After(TDuration.FromMs(100));
  
  CheckTrue(D1 > D2, 'Operator > should return true for later deadline');
end;

procedure TTestDeadline.Test_ToString_Never;
var
  D: TDeadline;
begin
  D := TDeadline.Never;
  CheckEquals('Never', D.ToString, 'Never deadline should have "Never" string');
end;

procedure TTestDeadline.Test_ToString_Future;
var
  D: TDeadline;
  S: string;
begin
  D := TDeadline.After(TDuration.FromMs(100));
  S := D.ToString;
  
  CheckTrue(Pos('In', S) > 0, 'Future deadline string should contain "In"');
end;

initialization
  RegisterTest(TTestDeadline);

end.
