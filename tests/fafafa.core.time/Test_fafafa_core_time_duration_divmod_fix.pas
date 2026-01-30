{$mode objfpc}{$H+}{$J-}

unit Test_fafafa_core_time_duration_divmod_fix;

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.duration;

type
  { TTestDurationDivModFix }
  TTestDurationDivModFix = class(TTestCase)
  published
    // ISSUE-1: 测试 div 运算符抛出除零异常
    procedure Test_Div_ByZero_ShouldRaise;
    procedure Test_Div_Positive_ByZero_ShouldRaise;
    procedure Test_Div_Negative_ByZero_ShouldRaise;
    procedure Test_Div_Normal_ShouldWork;
    procedure Test_Div_ByNegativeOne_WithLowInt64_ShouldSaturate;
    
    // ISSUE-1: 测试 Divi 方法抛出除零异常
    procedure Test_Divi_ByZero_ShouldRaise;
    
    // ISSUE-2: 测试 Modulo 方法抛出除零异常
    procedure Test_Modulo_ByZero_ShouldRaise;
    procedure Test_Modulo_Positive_ByZero_ShouldRaise;
    procedure Test_Modulo_Negative_ByZero_ShouldRaise;
    procedure Test_Modulo_Normal_ShouldWork;
    
    // 验证 Checked* 版本仍然按预期工作
    procedure Test_CheckedDivBy_ZeroReturnsFalse;
    procedure Test_CheckedModulo_ZeroReturnsFalse;
    
    // 验证 SaturatingDiv 仍然饱和而不抛异常
    procedure Test_SaturatingDiv_ZeroSaturates;
  end;

implementation

{ TTestDurationDivModFix }

procedure TTestDurationDivModFix.Test_Div_ByZero_ShouldRaise;
var
  d: TDuration;
  result: TDuration;
  raised: Boolean;
  zero: Int64;
begin
  d := TDuration.FromSec(100);
  raised := False;
  zero := 0;  // 使用变量避免编译期除零检测
  
  try
    result := d div zero;  // 应该抛出 EDivByZero 异常
  except
    on E: EDivByZero do
      raised := True;
  end;
  
  AssertTrue('div by zero should raise EDivByZero', raised);
end;

procedure TTestDurationDivModFix.Test_Div_Positive_ByZero_ShouldRaise;
var
  d: TDuration;
  result: TDuration;
  raised: Boolean;
  zero: Int64;
begin
  d := TDuration.FromSec(1000);
  raised := False;
  zero := 0;
  
  try
    result := d div zero;
  except
    on E: EDivByZero do
      raised := True;
  end;
  
  AssertTrue('Positive duration div by zero should raise', raised);
end;

procedure TTestDurationDivModFix.Test_Div_Negative_ByZero_ShouldRaise;
var
  d: TDuration;
  result: TDuration;
  raised: Boolean;
  zero: Int64;
begin
  d := TDuration.FromSec(-1000);
  raised := False;
  zero := 0;
  
  try
    result := d div zero;
  except
    on E: EDivByZero do
      raised := True;
  end;
  
  AssertTrue('Negative duration div by zero should raise', raised);
end;

procedure TTestDurationDivModFix.Test_Div_Normal_ShouldWork;
var
  d: TDuration;
  result: TDuration;
begin
  d := TDuration.FromSec(100);
  result := d div 10;
  
  AssertEquals('Normal division should work', 
               10, result.AsSec);
end;

procedure TTestDurationDivModFix.Test_Div_ByNegativeOne_WithLowInt64_ShouldSaturate;
var
  d: TDuration;
  result: TDuration;
begin
  // Low(Int64) / -1 会溢出，应该饱和到 High(Int64)
  d := TDuration.FromNs(Low(Int64));
  result := d div (-1);
  
  AssertEquals('Low(Int64) div -1 should saturate to High(Int64)', 
               High(Int64), result.AsNs);
end;

procedure TTestDurationDivModFix.Test_Divi_ByZero_ShouldRaise;
var
  d: TDuration;
  result: TDuration;
  raised: Boolean;
  zero: Int64;
begin
  d := TDuration.FromSec(100);
  raised := False;
  zero := 0;
  
  try
    result := d.Divi(zero);  // 应该抛出 EDivByZero 异常
  except
    on E: EDivByZero do
      raised := True;
  end;
  
  AssertTrue('Divi by zero should raise EDivByZero', raised);
end;

procedure TTestDurationDivModFix.Test_Modulo_ByZero_ShouldRaise;
var
  d, divisor: TDuration;
  result: TDuration;
  raised: Boolean;
begin
  d := TDuration.FromSec(100);
  divisor := TDuration.Zero;
  raised := False;
  
  try
    result := d.Modulo(divisor);  // 应该抛出 EDivByZero 异常
  except
    on E: EDivByZero do
      raised := True;
  end;
  
  AssertTrue('Modulo by zero should raise EDivByZero', raised);
end;

procedure TTestDurationDivModFix.Test_Modulo_Positive_ByZero_ShouldRaise;
var
  d, divisor: TDuration;
  result: TDuration;
  raised: Boolean;
begin
  d := TDuration.FromSec(1000);
  divisor := TDuration.Zero;
  raised := False;
  
  try
    result := d.Modulo(divisor);
  except
    on E: EDivByZero do
      raised := True;
  end;
  
  AssertTrue('Positive modulo by zero should raise', raised);
end;

procedure TTestDurationDivModFix.Test_Modulo_Negative_ByZero_ShouldRaise;
var
  d, divisor: TDuration;
  result: TDuration;
  raised: Boolean;
begin
  d := TDuration.FromSec(-1000);
  divisor := TDuration.Zero;
  raised := False;
  
  try
    result := d.Modulo(divisor);
  except
    on E: EDivByZero do
      raised := True;
  end;
  
  AssertTrue('Negative modulo by zero should raise', raised);
end;

procedure TTestDurationDivModFix.Test_Modulo_Normal_ShouldWork;
var
  d, divisor, result: TDuration;
begin
  d := TDuration.FromSec(100);
  divisor := TDuration.FromSec(30);
  result := d.Modulo(divisor);
  
  // 100 mod 30 = 10
  AssertEquals('Normal modulo should work', 
               10, result.AsSec);
end;

procedure TTestDurationDivModFix.Test_CheckedDivBy_ZeroReturnsFalse;
var
  d, result: TDuration;
  success: Boolean;
  zero: Int64;
begin
  d := TDuration.FromSec(100);
  zero := 0;  // 使用变量避免编译期除零检测
  success := d.CheckedDivBy(zero, result);
  
  AssertFalse('CheckedDivBy zero should return False', success);
end;

procedure TTestDurationDivModFix.Test_CheckedModulo_ZeroReturnsFalse;
var
  d, divisor, result: TDuration;
  success: Boolean;
begin
  d := TDuration.FromSec(100);
  divisor := TDuration.Zero;
  success := d.CheckedModulo(divisor, result);
  
  AssertFalse('CheckedModulo zero should return False', success);
end;

procedure TTestDurationDivModFix.Test_SaturatingDiv_ZeroSaturates;
var
  d, result: TDuration;
  zero: Int64;
begin
  // SaturatingDiv 应该饱和而不是抛异常（保持原有行为）
  d := TDuration.FromSec(100);
  zero := 0;  // 使用变量避免编译期除零检测
  result := d.SaturatingDiv(zero);
  
  AssertEquals('SaturatingDiv by zero should saturate to High(Int64)', 
               High(Int64), result.AsNs);
  
  // 负数应该饱和到 Low(Int64)
  d := TDuration.FromSec(-100);
  result := d.SaturatingDiv(zero);
  
  AssertEquals('Negative SaturatingDiv by zero should saturate to Low(Int64)', 
               Low(Int64), result.AsNs);
end;

initialization
  RegisterTest(TTestDurationDivModFix);

end.
