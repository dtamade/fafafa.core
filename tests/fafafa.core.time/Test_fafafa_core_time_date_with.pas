unit Test_fafafa_core_time_date_with;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.date,
  fafafa.core.time.timeofday,
  fafafa.core.time.naivedatetime,
  fafafa.core.time.helpers;

type
  TTestCase_TDate_With = class(TTestCase)
  published
    // ═══════════════════════════════════════════════════════════════
    // WithYear 测试
    // ═══════════════════════════════════════════════════════════════
    procedure Test_WithYear_NormalValue_Success;
    procedure Test_WithYear_LeapYearFeb29_AdjustsDay;
    procedure Test_WithYear_SameYear_ReturnsSelf;
    
    // ═══════════════════════════════════════════════════════════════
    // WithMonth 测试
    // ═══════════════════════════════════════════════════════════════
    procedure Test_WithMonth_NormalValue_Success;
    procedure Test_WithMonth_Day31ToMonth30_AdjustsDay;
    procedure Test_WithMonth_Jan31ToFeb_AdjustsDay;
    procedure Test_WithMonth_SameMonth_ReturnsSelf;
    
    // ═══════════════════════════════════════════════════════════════
    // WithDay 测试
    // ═══════════════════════════════════════════════════════════════
    procedure Test_WithDay_NormalValue_Success;
    procedure Test_WithDay_SameDay_ReturnsSelf;
    procedure Test_WithDay_InvalidDay_Raises;
    
    // ═══════════════════════════════════════════════════════════════
    // TryWith* 安全版本测试
    // ═══════════════════════════════════════════════════════════════
    procedure Test_TryWithYear_ValidYear_ReturnsTrue;
    procedure Test_TryWithYear_InvalidYear_ReturnsFalse;
    procedure Test_TryWithMonth_ValidMonth_ReturnsTrue;
    procedure Test_TryWithMonth_InvalidMonth_ReturnsFalse;
    procedure Test_TryWithDay_ValidDay_ReturnsTrue;
    procedure Test_TryWithDay_InvalidDay_ReturnsFalse;
    
    // ═══════════════════════════════════════════════════════════════
    // AndTime / AndHms 测试
    // ═══════════════════════════════════════════════════════════════
    procedure Test_AndTime_NormalValue_Success;
    procedure Test_AndHms_NormalValue_Success;
    procedure Test_AndHms_WithMilliseconds_Success;
    procedure Test_TryAndHms_ValidTime_ReturnsTrue;
    procedure Test_TryAndHms_InvalidTime_ReturnsFalse;
  end;

implementation

{ TTestCase_TDate_With }

// ═══════════════════════════════════════════════════════════════
// WithYear 测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_TDate_With.Test_WithYear_NormalValue_Success;
var
  d, r: TDate;
begin
  // Arrange
  d := TDate.Create(2024, 6, 15);
  
  // Act
  r := d.WithYear(2025);
  
  // Assert
  CheckEquals(2025, r.GetYear);
  CheckEquals(6, r.GetMonth);
  CheckEquals(15, r.GetDay);
end;

procedure TTestCase_TDate_With.Test_WithYear_LeapYearFeb29_AdjustsDay;
var
  d, r: TDate;
begin
  // Arrange: 2024 是闰年，2月有29天
  d := TDate.Create(2024, 2, 29);
  
  // Act: 2025 不是闰年
  r := d.WithYear(2025);
  
  // Assert: 应该调整为2月28日
  CheckEquals(2025, r.GetYear);
  CheckEquals(2, r.GetMonth);
  CheckEquals(28, r.GetDay);
end;

procedure TTestCase_TDate_With.Test_WithYear_SameYear_ReturnsSelf;
var
  d, r: TDate;
begin
  // Arrange
  d := TDate.Create(2024, 6, 15);
  
  // Act
  r := d.WithYear(2024);
  
  // Assert
  CheckTrue(d = r);
end;

// ═══════════════════════════════════════════════════════════════
// WithMonth 测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_TDate_With.Test_WithMonth_NormalValue_Success;
var
  d, r: TDate;
begin
  // Arrange
  d := TDate.Create(2024, 6, 15);
  
  // Act
  r := d.WithMonth(8);
  
  // Assert
  CheckEquals(2024, r.GetYear);
  CheckEquals(8, r.GetMonth);
  CheckEquals(15, r.GetDay);
end;

procedure TTestCase_TDate_With.Test_WithMonth_Day31ToMonth30_AdjustsDay;
var
  d, r: TDate;
begin
  // Arrange: 1月31日
  d := TDate.Create(2024, 1, 31);
  
  // Act: 改为4月（只有30天）
  r := d.WithMonth(4);
  
  // Assert: 应该调整为4月30日
  CheckEquals(2024, r.GetYear);
  CheckEquals(4, r.GetMonth);
  CheckEquals(30, r.GetDay);
end;

procedure TTestCase_TDate_With.Test_WithMonth_Jan31ToFeb_AdjustsDay;
var
  d, r: TDate;
begin
  // Arrange: 1月31日
  d := TDate.Create(2024, 1, 31);
  
  // Act: 改为2月（2024是闰年，最多29天）
  r := d.WithMonth(2);
  
  // Assert: 应该调整为2月29日
  CheckEquals(2024, r.GetYear);
  CheckEquals(2, r.GetMonth);
  CheckEquals(29, r.GetDay);
end;

procedure TTestCase_TDate_With.Test_WithMonth_SameMonth_ReturnsSelf;
var
  d, r: TDate;
begin
  // Arrange
  d := TDate.Create(2024, 6, 15);
  
  // Act
  r := d.WithMonth(6);
  
  // Assert
  CheckTrue(d = r);
end;

// ═══════════════════════════════════════════════════════════════
// WithDay 测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_TDate_With.Test_WithDay_NormalValue_Success;
var
  d, r: TDate;
begin
  // Arrange
  d := TDate.Create(2024, 6, 15);
  
  // Act
  r := d.WithDay(20);
  
  // Assert
  CheckEquals(2024, r.GetYear);
  CheckEquals(6, r.GetMonth);
  CheckEquals(20, r.GetDay);
end;

procedure TTestCase_TDate_With.Test_WithDay_SameDay_ReturnsSelf;
var
  d, r: TDate;
begin
  // Arrange
  d := TDate.Create(2024, 6, 15);
  
  // Act
  r := d.WithDay(15);
  
  // Assert
  CheckTrue(d = r);
end;

procedure TTestCase_TDate_With.Test_WithDay_InvalidDay_Raises;
var
  d: TDate;
  raised: Boolean;
begin
  // Arrange
  d := TDate.Create(2024, 6, 15); // 6月只有30天
  raised := False;
  
  // Act & Assert
  try
    d.WithDay(31);
  except
    raised := True;
  end;
  
  CheckTrue(raised, 'Expected exception for invalid day');
end;

// ═══════════════════════════════════════════════════════════════
// TryWith* 安全版本测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_TDate_With.Test_TryWithYear_ValidYear_ReturnsTrue;
var
  d, r: TDate;
  ok: Boolean;
begin
  // Arrange
  d := TDate.Create(2024, 6, 15);
  
  // Act
  ok := d.TryWithYear(2025, r);
  
  // Assert
  CheckTrue(ok);
  CheckEquals(2025, r.GetYear);
end;

procedure TTestCase_TDate_With.Test_TryWithYear_InvalidYear_ReturnsFalse;
var
  d, r: TDate;
  ok: Boolean;
begin
  // Arrange
  d := TDate.Create(2024, 6, 15);
  
  // Act
  ok := d.TryWithYear(0, r);
  
  // Assert
  CheckFalse(ok);
end;

procedure TTestCase_TDate_With.Test_TryWithMonth_ValidMonth_ReturnsTrue;
var
  d, r: TDate;
  ok: Boolean;
begin
  // Arrange
  d := TDate.Create(2024, 6, 15);
  
  // Act
  ok := d.TryWithMonth(8, r);
  
  // Assert
  CheckTrue(ok);
  CheckEquals(8, r.GetMonth);
end;

procedure TTestCase_TDate_With.Test_TryWithMonth_InvalidMonth_ReturnsFalse;
var
  d, r: TDate;
  ok: Boolean;
begin
  // Arrange
  d := TDate.Create(2024, 6, 15);
  
  // Act
  ok := d.TryWithMonth(13, r);
  
  // Assert
  CheckFalse(ok);
end;

procedure TTestCase_TDate_With.Test_TryWithDay_ValidDay_ReturnsTrue;
var
  d, r: TDate;
  ok: Boolean;
begin
  // Arrange
  d := TDate.Create(2024, 6, 15);
  
  // Act
  ok := d.TryWithDay(20, r);
  
  // Assert
  CheckTrue(ok);
  CheckEquals(20, r.GetDay);
end;

procedure TTestCase_TDate_With.Test_TryWithDay_InvalidDay_ReturnsFalse;
var
  d, r: TDate;
  ok: Boolean;
begin
  // Arrange
  d := TDate.Create(2024, 6, 15); // 6月只有30天
  
  // Act
  ok := d.TryWithDay(31, r);
  
  // Assert
  CheckFalse(ok);
end;

// ═══════════════════════════════════════════════════════════════
// AndTime / AndHms 测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_TDate_With.Test_AndTime_NormalValue_Success;
var
  d: TDate;
  t: TTimeOfDay;
  dt: TNaiveDateTime;
begin
  // Arrange
  d := TDate.Create(2024, 6, 15);
  t := TTimeOfDay.Create(14, 30, 45, 123);
  
  // Act
  dt := d.AndTime(t);
  
  // Assert
  CheckEquals(2024, dt.Year);
  CheckEquals(6, dt.Month);
  CheckEquals(15, dt.Day);
  CheckEquals(14, dt.Hour);
  CheckEquals(30, dt.Minute);
  CheckEquals(45, dt.Second);
  CheckEquals(123, dt.Millisecond);
end;

procedure TTestCase_TDate_With.Test_AndHms_NormalValue_Success;
var
  d: TDate;
  dt: TNaiveDateTime;
begin
  // Arrange
  d := TDate.Create(2024, 6, 15);
  
  // Act
  dt := d.AndHms(14, 30, 45);
  
  // Assert
  CheckEquals(2024, dt.Year);
  CheckEquals(6, dt.Month);
  CheckEquals(15, dt.Day);
  CheckEquals(14, dt.Hour);
  CheckEquals(30, dt.Minute);
  CheckEquals(45, dt.Second);
  CheckEquals(0, dt.Millisecond);
end;

procedure TTestCase_TDate_With.Test_AndHms_WithMilliseconds_Success;
var
  d: TDate;
  dt: TNaiveDateTime;
begin
  // Arrange
  d := TDate.Create(2024, 6, 15);
  
  // Act
  dt := d.AndHmsMs(14, 30, 45, 500);
  
  // Assert
  CheckEquals(2024, dt.Year);
  CheckEquals(6, dt.Month);
  CheckEquals(15, dt.Day);
  CheckEquals(14, dt.Hour);
  CheckEquals(30, dt.Minute);
  CheckEquals(45, dt.Second);
  CheckEquals(500, dt.Millisecond);
end;

procedure TTestCase_TDate_With.Test_TryAndHms_ValidTime_ReturnsTrue;
var
  d: TDate;
  dt: TNaiveDateTime;
  ok: Boolean;
begin
  // Arrange
  d := TDate.Create(2024, 6, 15);
  
  // Act
  ok := d.TryAndHms(14, 30, 45, dt);
  
  // Assert
  CheckTrue(ok);
  CheckEquals(14, dt.Hour);
  CheckEquals(30, dt.Minute);
  CheckEquals(45, dt.Second);
end;

procedure TTestCase_TDate_With.Test_TryAndHms_InvalidTime_ReturnsFalse;
var
  d: TDate;
  dt: TNaiveDateTime;
  ok: Boolean;
begin
  // Arrange
  d := TDate.Create(2024, 6, 15);
  
  // Act
  ok := d.TryAndHms(25, 0, 0, dt); // 无效小时
  
  // Assert
  CheckFalse(ok);
end;

initialization
  RegisterTest(TTestCase_TDate_With);

end.
