unit Test_fafafa_core_time_timeofday_with;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.timeofday,
  fafafa.core.time.helpers;

type
  TTestCase_TTimeOfDay_With = class(TTestCase)
  published
    // ═══════════════════════════════════════════════════════════════
    // WithHour 测试
    // ═══════════════════════════════════════════════════════════════
    procedure Test_WithHour_NormalValue_Success;
    procedure Test_WithHour_SameHour_ReturnsSelf;
    procedure Test_WithHour_InvalidHour_Raises;
    
    // ═══════════════════════════════════════════════════════════════
    // WithMinute 测试
    // ═══════════════════════════════════════════════════════════════
    procedure Test_WithMinute_NormalValue_Success;
    procedure Test_WithMinute_SameMinute_ReturnsSelf;
    procedure Test_WithMinute_InvalidMinute_Raises;
    
    // ═══════════════════════════════════════════════════════════════
    // WithSecond 测试
    // ═══════════════════════════════════════════════════════════════
    procedure Test_WithSecond_NormalValue_Success;
    procedure Test_WithSecond_SameSecond_ReturnsSelf;
    procedure Test_WithSecond_InvalidSecond_Raises;
    
    // ═══════════════════════════════════════════════════════════════
    // WithMillisecond 测试
    // ═══════════════════════════════════════════════════════════════
    procedure Test_WithMillisecond_NormalValue_Success;
    procedure Test_WithMillisecond_SameMillisecond_ReturnsSelf;
    procedure Test_WithMillisecond_InvalidMillisecond_Raises;
    
    // ═══════════════════════════════════════════════════════════════
    // TryWith* 安全版本测试
    // ═══════════════════════════════════════════════════════════════
    procedure Test_TryWithHour_ValidHour_ReturnsTrue;
    procedure Test_TryWithHour_InvalidHour_ReturnsFalse;
    procedure Test_TryWithMinute_ValidMinute_ReturnsTrue;
    procedure Test_TryWithMinute_InvalidMinute_ReturnsFalse;
    procedure Test_TryWithSecond_ValidSecond_ReturnsTrue;
    procedure Test_TryWithSecond_InvalidSecond_ReturnsFalse;
    procedure Test_TryWithMillisecond_ValidMs_ReturnsTrue;
    procedure Test_TryWithMillisecond_InvalidMs_ReturnsFalse;
  end;

implementation

{ TTestCase_TTimeOfDay_With }

// ═══════════════════════════════════════════════════════════════
// WithHour 测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_TTimeOfDay_With.Test_WithHour_NormalValue_Success;
var
  t, r: TTimeOfDay;
begin
  // Arrange
  t := TTimeOfDay.Create(10, 30, 45, 123);
  
  // Act
  r := t.WithHour(14);
  
  // Assert
  CheckEquals(14, r.GetHour);
  CheckEquals(30, r.GetMinute);
  CheckEquals(45, r.GetSecond);
  CheckEquals(123, r.GetMillisecond);
end;

procedure TTestCase_TTimeOfDay_With.Test_WithHour_SameHour_ReturnsSelf;
var
  t, r: TTimeOfDay;
begin
  // Arrange
  t := TTimeOfDay.Create(10, 30, 45, 123);
  
  // Act
  r := t.WithHour(10);
  
  // Assert
  CheckTrue(t = r);
end;

procedure TTestCase_TTimeOfDay_With.Test_WithHour_InvalidHour_Raises;
var
  t: TTimeOfDay;
  raised: Boolean;
begin
  // Arrange
  t := TTimeOfDay.Create(10, 30, 45, 123);
  raised := False;
  
  // Act & Assert
  try
    t.WithHour(24);
  except
    raised := True;
  end;
  
  CheckTrue(raised, 'Expected exception for invalid hour');
end;

// ═══════════════════════════════════════════════════════════════
// WithMinute 测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_TTimeOfDay_With.Test_WithMinute_NormalValue_Success;
var
  t, r: TTimeOfDay;
begin
  // Arrange
  t := TTimeOfDay.Create(10, 30, 45, 123);
  
  // Act
  r := t.WithMinute(45);
  
  // Assert
  CheckEquals(10, r.GetHour);
  CheckEquals(45, r.GetMinute);
  CheckEquals(45, r.GetSecond);
  CheckEquals(123, r.GetMillisecond);
end;

procedure TTestCase_TTimeOfDay_With.Test_WithMinute_SameMinute_ReturnsSelf;
var
  t, r: TTimeOfDay;
begin
  // Arrange
  t := TTimeOfDay.Create(10, 30, 45, 123);
  
  // Act
  r := t.WithMinute(30);
  
  // Assert
  CheckTrue(t = r);
end;

procedure TTestCase_TTimeOfDay_With.Test_WithMinute_InvalidMinute_Raises;
var
  t: TTimeOfDay;
  raised: Boolean;
begin
  // Arrange
  t := TTimeOfDay.Create(10, 30, 45, 123);
  raised := False;
  
  // Act & Assert
  try
    t.WithMinute(60);
  except
    raised := True;
  end;
  
  CheckTrue(raised, 'Expected exception for invalid minute');
end;

// ═══════════════════════════════════════════════════════════════
// WithSecond 测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_TTimeOfDay_With.Test_WithSecond_NormalValue_Success;
var
  t, r: TTimeOfDay;
begin
  // Arrange
  t := TTimeOfDay.Create(10, 30, 45, 123);
  
  // Act
  r := t.WithSecond(30);
  
  // Assert
  CheckEquals(10, r.GetHour);
  CheckEquals(30, r.GetMinute);
  CheckEquals(30, r.GetSecond);
  CheckEquals(123, r.GetMillisecond);
end;

procedure TTestCase_TTimeOfDay_With.Test_WithSecond_SameSecond_ReturnsSelf;
var
  t, r: TTimeOfDay;
begin
  // Arrange
  t := TTimeOfDay.Create(10, 30, 45, 123);
  
  // Act
  r := t.WithSecond(45);
  
  // Assert
  CheckTrue(t = r);
end;

procedure TTestCase_TTimeOfDay_With.Test_WithSecond_InvalidSecond_Raises;
var
  t: TTimeOfDay;
  raised: Boolean;
begin
  // Arrange
  t := TTimeOfDay.Create(10, 30, 45, 123);
  raised := False;
  
  // Act & Assert
  try
    t.WithSecond(60);
  except
    raised := True;
  end;
  
  CheckTrue(raised, 'Expected exception for invalid second');
end;

// ═══════════════════════════════════════════════════════════════
// WithMillisecond 测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_TTimeOfDay_With.Test_WithMillisecond_NormalValue_Success;
var
  t, r: TTimeOfDay;
begin
  // Arrange
  t := TTimeOfDay.Create(10, 30, 45, 123);
  
  // Act
  r := t.WithMillisecond(500);
  
  // Assert
  CheckEquals(10, r.GetHour);
  CheckEquals(30, r.GetMinute);
  CheckEquals(45, r.GetSecond);
  CheckEquals(500, r.GetMillisecond);
end;

procedure TTestCase_TTimeOfDay_With.Test_WithMillisecond_SameMillisecond_ReturnsSelf;
var
  t, r: TTimeOfDay;
begin
  // Arrange
  t := TTimeOfDay.Create(10, 30, 45, 123);
  
  // Act
  r := t.WithMillisecond(123);
  
  // Assert
  CheckTrue(t = r);
end;

procedure TTestCase_TTimeOfDay_With.Test_WithMillisecond_InvalidMillisecond_Raises;
var
  t: TTimeOfDay;
  raised: Boolean;
begin
  // Arrange
  t := TTimeOfDay.Create(10, 30, 45, 123);
  raised := False;
  
  // Act & Assert
  try
    t.WithMillisecond(1000);
  except
    raised := True;
  end;
  
  CheckTrue(raised, 'Expected exception for invalid millisecond');
end;

// ═══════════════════════════════════════════════════════════════
// TryWith* 安全版本测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_TTimeOfDay_With.Test_TryWithHour_ValidHour_ReturnsTrue;
var
  t, r: TTimeOfDay;
  ok: Boolean;
begin
  // Arrange
  t := TTimeOfDay.Create(10, 30, 45, 123);
  
  // Act
  ok := t.TryWithHour(14, r);
  
  // Assert
  CheckTrue(ok);
  CheckEquals(14, r.GetHour);
end;

procedure TTestCase_TTimeOfDay_With.Test_TryWithHour_InvalidHour_ReturnsFalse;
var
  t, r: TTimeOfDay;
  ok: Boolean;
begin
  // Arrange
  t := TTimeOfDay.Create(10, 30, 45, 123);
  
  // Act
  ok := t.TryWithHour(24, r);
  
  // Assert
  CheckFalse(ok);
end;

procedure TTestCase_TTimeOfDay_With.Test_TryWithMinute_ValidMinute_ReturnsTrue;
var
  t, r: TTimeOfDay;
  ok: Boolean;
begin
  // Arrange
  t := TTimeOfDay.Create(10, 30, 45, 123);
  
  // Act
  ok := t.TryWithMinute(45, r);
  
  // Assert
  CheckTrue(ok);
  CheckEquals(45, r.GetMinute);
end;

procedure TTestCase_TTimeOfDay_With.Test_TryWithMinute_InvalidMinute_ReturnsFalse;
var
  t, r: TTimeOfDay;
  ok: Boolean;
begin
  // Arrange
  t := TTimeOfDay.Create(10, 30, 45, 123);
  
  // Act
  ok := t.TryWithMinute(60, r);
  
  // Assert
  CheckFalse(ok);
end;

procedure TTestCase_TTimeOfDay_With.Test_TryWithSecond_ValidSecond_ReturnsTrue;
var
  t, r: TTimeOfDay;
  ok: Boolean;
begin
  // Arrange
  t := TTimeOfDay.Create(10, 30, 45, 123);
  
  // Act
  ok := t.TryWithSecond(30, r);
  
  // Assert
  CheckTrue(ok);
  CheckEquals(30, r.GetSecond);
end;

procedure TTestCase_TTimeOfDay_With.Test_TryWithSecond_InvalidSecond_ReturnsFalse;
var
  t, r: TTimeOfDay;
  ok: Boolean;
begin
  // Arrange
  t := TTimeOfDay.Create(10, 30, 45, 123);
  
  // Act
  ok := t.TryWithSecond(60, r);
  
  // Assert
  CheckFalse(ok);
end;

procedure TTestCase_TTimeOfDay_With.Test_TryWithMillisecond_ValidMs_ReturnsTrue;
var
  t, r: TTimeOfDay;
  ok: Boolean;
begin
  // Arrange
  t := TTimeOfDay.Create(10, 30, 45, 123);
  
  // Act
  ok := t.TryWithMillisecond(500, r);
  
  // Assert
  CheckTrue(ok);
  CheckEquals(500, r.GetMillisecond);
end;

procedure TTestCase_TTimeOfDay_With.Test_TryWithMillisecond_InvalidMs_ReturnsFalse;
var
  t, r: TTimeOfDay;
  ok: Boolean;
begin
  // Arrange
  t := TTimeOfDay.Create(10, 30, 45, 123);
  
  // Act
  ok := t.TryWithMillisecond(1000, r);
  
  // Assert
  CheckFalse(ok);
end;

initialization
  RegisterTest(TTestCase_TTimeOfDay_With);

end.
