unit Test_fafafa_core_time_naivedatetime_with;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.date,
  fafafa.core.time.timeofday,
  fafafa.core.time.naivedatetime,
  fafafa.core.time.zoneddatetime,
  fafafa.core.time.offset,
  fafafa.core.time.helpers;

type
  TTestCase_TNaiveDateTime_With = class(TTestCase)
  published
    // ═══════════════════════════════════════════════════════════════
    // WithYear/WithMonth/WithDay 测试
    // ═══════════════════════════════════════════════════════════════
    procedure Test_WithYear_NormalValue_Success;
    procedure Test_WithMonth_NormalValue_Success;
    procedure Test_WithDay_NormalValue_Success;
    
    // ═══════════════════════════════════════════════════════════════
    // WithHour/WithMinute/WithSecond/WithMillisecond 测试
    // ═══════════════════════════════════════════════════════════════
    procedure Test_WithHour_NormalValue_Success;
    procedure Test_WithMinute_NormalValue_Success;
    procedure Test_WithSecond_NormalValue_Success;
    procedure Test_WithMillisecond_NormalValue_Success;
    
    // ═══════════════════════════════════════════════════════════════
    // AndOffset / AndUtc / AndLocal 测试
    // ═══════════════════════════════════════════════════════════════
    procedure Test_AndOffset_CreatesZonedDateTime;
    procedure Test_AndUtc_CreatesUtcZonedDateTime;
    procedure Test_AndLocal_CreatesLocalZonedDateTime;
    
    // ═══════════════════════════════════════════════════════════════
    // 链式调用测试
    // ═══════════════════════════════════════════════════════════════
    procedure Test_ChainedWith_Success;
    procedure Test_ChainedAndUtc_Success;
  end;

implementation

{ TTestCase_TNaiveDateTime_With }

// ═══════════════════════════════════════════════════════════════
// WithYear/WithMonth/WithDay 测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_TNaiveDateTime_With.Test_WithYear_NormalValue_Success;
var
  dt, r: TNaiveDateTime;
begin
  // Arrange
  dt := TNaiveDateTime.Create(2024, 6, 15, 10, 30, 45, 123);
  
  // Act
  r := dt.WithYear(2025);
  
  // Assert
  CheckEquals(2025, r.Year);
  CheckEquals(6, r.Month);
  CheckEquals(15, r.Day);
  CheckEquals(10, r.Hour);
  CheckEquals(30, r.Minute);
  CheckEquals(45, r.Second);
  CheckEquals(123, r.Millisecond);
end;

procedure TTestCase_TNaiveDateTime_With.Test_WithMonth_NormalValue_Success;
var
  dt, r: TNaiveDateTime;
begin
  // Arrange
  dt := TNaiveDateTime.Create(2024, 6, 15, 10, 30, 45, 123);
  
  // Act
  r := dt.WithMonth(8);
  
  // Assert
  CheckEquals(2024, r.Year);
  CheckEquals(8, r.Month);
  CheckEquals(15, r.Day);
  CheckEquals(10, r.Hour);
end;

procedure TTestCase_TNaiveDateTime_With.Test_WithDay_NormalValue_Success;
var
  dt, r: TNaiveDateTime;
begin
  // Arrange
  dt := TNaiveDateTime.Create(2024, 6, 15, 10, 30, 45, 123);
  
  // Act
  r := dt.WithDay(20);
  
  // Assert
  CheckEquals(2024, r.Year);
  CheckEquals(6, r.Month);
  CheckEquals(20, r.Day);
  CheckEquals(10, r.Hour);
end;

// ═══════════════════════════════════════════════════════════════
// WithHour/WithMinute/WithSecond/WithMillisecond 测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_TNaiveDateTime_With.Test_WithHour_NormalValue_Success;
var
  dt, r: TNaiveDateTime;
begin
  // Arrange
  dt := TNaiveDateTime.Create(2024, 6, 15, 10, 30, 45, 123);
  
  // Act
  r := dt.WithHour(14);
  
  // Assert
  CheckEquals(2024, r.Year);
  CheckEquals(6, r.Month);
  CheckEquals(15, r.Day);
  CheckEquals(14, r.Hour);
  CheckEquals(30, r.Minute);
  CheckEquals(45, r.Second);
  CheckEquals(123, r.Millisecond);
end;

procedure TTestCase_TNaiveDateTime_With.Test_WithMinute_NormalValue_Success;
var
  dt, r: TNaiveDateTime;
begin
  // Arrange
  dt := TNaiveDateTime.Create(2024, 6, 15, 10, 30, 45, 123);
  
  // Act
  r := dt.WithMinute(45);
  
  // Assert
  CheckEquals(10, r.Hour);
  CheckEquals(45, r.Minute);
  CheckEquals(45, r.Second);
end;

procedure TTestCase_TNaiveDateTime_With.Test_WithSecond_NormalValue_Success;
var
  dt, r: TNaiveDateTime;
begin
  // Arrange
  dt := TNaiveDateTime.Create(2024, 6, 15, 10, 30, 45, 123);
  
  // Act
  r := dt.WithSecond(30);
  
  // Assert
  CheckEquals(10, r.Hour);
  CheckEquals(30, r.Minute);
  CheckEquals(30, r.Second);
end;

procedure TTestCase_TNaiveDateTime_With.Test_WithMillisecond_NormalValue_Success;
var
  dt, r: TNaiveDateTime;
begin
  // Arrange
  dt := TNaiveDateTime.Create(2024, 6, 15, 10, 30, 45, 123);
  
  // Act
  r := dt.WithMillisecond(500);
  
  // Assert
  CheckEquals(10, r.Hour);
  CheckEquals(30, r.Minute);
  CheckEquals(45, r.Second);
  CheckEquals(500, r.Millisecond);
end;

// ═══════════════════════════════════════════════════════════════
// AndOffset / AndUtc / AndLocal 测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_TNaiveDateTime_With.Test_AndOffset_CreatesZonedDateTime;
var
  dt: TNaiveDateTime;
  zdt: TZonedDateTime;
  offset: TUtcOffset;
begin
  // Arrange
  dt := TNaiveDateTime.Create(2024, 6, 15, 10, 30, 45, 0);
  offset := TUtcOffset.FromHours(8); // UTC+8
  
  // Act
  zdt := dt.AndOffset(offset);
  
  // Assert
  CheckEquals(2024, zdt.Year);
  CheckEquals(6, zdt.Month);
  CheckEquals(15, zdt.Day);
  CheckEquals(10, zdt.Hour);
  CheckEquals(30, zdt.Minute);
  CheckEquals(45, zdt.Second);
  CheckEquals(8 * 3600, zdt.Offset.TotalSeconds);
end;

procedure TTestCase_TNaiveDateTime_With.Test_AndUtc_CreatesUtcZonedDateTime;
var
  dt: TNaiveDateTime;
  zdt: TZonedDateTime;
begin
  // Arrange
  dt := TNaiveDateTime.Create(2024, 6, 15, 10, 30, 45, 0);
  
  // Act
  zdt := dt.AndUtc;
  
  // Assert
  CheckEquals(2024, zdt.Year);
  CheckEquals(6, zdt.Month);
  CheckEquals(15, zdt.Day);
  CheckEquals(10, zdt.Hour);
  CheckEquals(0, zdt.Offset.TotalSeconds); // UTC 偏移为 0
end;

procedure TTestCase_TNaiveDateTime_With.Test_AndLocal_CreatesLocalZonedDateTime;
var
  dt: TNaiveDateTime;
  zdt: TZonedDateTime;
begin
  // Arrange
  dt := TNaiveDateTime.Create(2024, 6, 15, 10, 30, 45, 0);
  
  // Act
  zdt := dt.AndLocal;
  
  // Assert
  CheckEquals(2024, zdt.Year);
  CheckEquals(6, zdt.Month);
  CheckEquals(15, zdt.Day);
  CheckEquals(10, zdt.Hour);
  // 本地偏移取决于系统时区，不做具体断言
end;

// ═══════════════════════════════════════════════════════════════
// 链式调用测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_TNaiveDateTime_With.Test_ChainedWith_Success;
var
  dt, r: TNaiveDateTime;
begin
  // Arrange
  dt := TNaiveDateTime.Create(2024, 6, 15, 10, 30, 45, 123);
  
  // Act - 链式修改年、月、时
  r := dt.WithYear(2025).WithMonth(12).WithHour(20);
  
  // Assert
  CheckEquals(2025, r.Year);
  CheckEquals(12, r.Month);
  CheckEquals(15, r.Day);
  CheckEquals(20, r.Hour);
  CheckEquals(30, r.Minute);
end;

procedure TTestCase_TNaiveDateTime_With.Test_ChainedAndUtc_Success;
var
  d: TDate;
  zdt: TZonedDateTime;
begin
  // Arrange
  d := TDate.Create(2024, 6, 15);
  
  // Act - 从 TDate 链式创建 TZonedDateTime (UTC)
  zdt := d.AndHms(10, 30, 45).AndUtc;
  
  // Assert
  CheckEquals(2024, zdt.Year);
  CheckEquals(6, zdt.Month);
  CheckEquals(15, zdt.Day);
  CheckEquals(10, zdt.Hour);
  CheckEquals(30, zdt.Minute);
  CheckEquals(45, zdt.Second);
  CheckEquals(0, zdt.Offset.TotalSeconds); // UTC
end;

initialization
  RegisterTest(TTestCase_TNaiveDateTime_With);

end.
