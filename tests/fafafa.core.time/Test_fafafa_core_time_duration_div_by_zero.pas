{$mode objfpc}{$H+}{$J-}

unit Test_fafafa_core_time_duration_div_by_zero;

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.math,
  fafafa.core.time.duration;

type
  { TTestDurationDivByZero }
  TTestDurationDivByZero = class(TTestCase)
  published
    // / 运算符除零测试
    procedure Test_DivOperator_ByZero_RaisesException;
    procedure Test_DivOperator_NormalCase_ReturnsCorrectRatio;
    
    // div 运算符除零测试（验证一致性）
    procedure Test_IntDiv_ByZero_RaisesException;
    
    // Divi 方法除零测试
    procedure Test_Divi_ByZero_RaisesException;
    
    // Modulo 除零测试
    procedure Test_Modulo_ByZero_RaisesException;
  end;

implementation

{ TTestDurationDivByZero }

procedure TTestDurationDivByZero.Test_DivOperator_ByZero_RaisesException;
var
  a, b: TDuration;
  r: Double;
  exceptionRaised: Boolean;
begin
  a := TDuration.FromSec(10);
  b := TDuration.Zero;
  
  exceptionRaised := False;
  try
    r := a / b;  // 应该抛出异常
  except
    on E: EDivByZero do
      exceptionRaised := True;
  end;
  
  AssertTrue('Division by zero should raise EDivByZero', exceptionRaised);
end;

procedure TTestDurationDivByZero.Test_DivOperator_NormalCase_ReturnsCorrectRatio;
var
  a, b: TDuration;
  r: Double;
begin
  a := TDuration.FromSec(10);
  b := TDuration.FromSec(2);
  
  r := a / b;
  
  AssertTrue('10s / 2s should be 5.0', Abs(r - 5.0) < 0.001);
end;

procedure TTestDurationDivByZero.Test_IntDiv_ByZero_RaisesException;
var
  a: TDuration;
  r: TDuration;
  exceptionRaised: Boolean;
begin
  a := TDuration.FromSec(10);
  
  exceptionRaised := False;
  try
    r := a div 0;  // 应该抛出异常
  except
    on E: EDivByZero do
      exceptionRaised := True;
  end;
  
  AssertTrue('Integer division by zero should raise EDivByZero', exceptionRaised);
end;

procedure TTestDurationDivByZero.Test_Divi_ByZero_RaisesException;
var
  a: TDuration;
  r: TDuration;
  exceptionRaised: Boolean;
begin
  a := TDuration.FromSec(10);
  
  exceptionRaised := False;
  try
    r := a.Divi(0);  // 应该抛出异常
  except
    on E: EDivByZero do
      exceptionRaised := True;
  end;
  
  AssertTrue('Divi(0) should raise EDivByZero', exceptionRaised);
end;

procedure TTestDurationDivByZero.Test_Modulo_ByZero_RaisesException;
var
  a, b: TDuration;
  r: TDuration;
  exceptionRaised: Boolean;
begin
  a := TDuration.FromSec(10);
  b := TDuration.Zero;
  
  exceptionRaised := False;
  try
    r := a.Modulo(b);  // 应该抛出异常
  except
    on E: EDivByZero do
      exceptionRaised := True;
  end;
  
  AssertTrue('Modulo by zero should raise EDivByZero', exceptionRaised);
end;

initialization
  RegisterTest(TTestDurationDivByZero);

end.
