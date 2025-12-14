unit Test_fafafa_core_time_facade;

{$mode objfpc}{$H+}

{
  Test: 门面单元 fafafa.core.time 完整性测试
  
  目标：
  - 验证所有核心类型通过门面单元可访问
  - 验证便捷函数可用
  
  遵循 TDD 规范：此测试先于实现编写
}

interface

uses
  Classes, SysUtils, DateUtils, fpcunit, testregistry,
  // 只引用门面单元，测试其是否转出了所有需要的类型
  fafafa.core.time;

type
  TTestCase_Facade = class(TTestCase)
  published
    // ═══════════════════════════════════════════════════════════════
    // 类型转出测试 - 验证通过门面单元可以访问各类型
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_TDuration_Accessible;
    procedure Test_TInstant_Accessible;
    procedure Test_TDate_Accessible;
    procedure Test_TTimeOfDay_Accessible;
    procedure Test_TNaiveDateTime_Accessible;
    procedure Test_TZonedDateTime_Accessible;
    procedure Test_TUtcOffset_Accessible;
    procedure Test_TIsoWeek_Accessible;
    
    // 新增类型转出测试 (Phase 1)
    procedure Test_TPeriod_Accessible;
    procedure Test_TDateRange_Accessible;
    procedure Test_TTimeRange_Accessible;
    
    // ═══════════════════════════════════════════════════════════════
    // 便捷函数测试 - 验证顶级快速函数可用
    // ═══════════════════════════════════════════════════════════════
    
    // 已有函数
    procedure Test_NowInstant_ReturnsValidInstant;
    procedure Test_NowUTC_ReturnsValidDateTime;
    procedure Test_NowLocal_ReturnsValidDateTime;
    procedure Test_NowUnixMs_ReturnsPositiveValue;
    
    // 新增便捷函数 (Phase 1)
    procedure Test_NowDate_ReturnsValidDate;
    procedure Test_NowTime_ReturnsValidTimeOfDay;
    procedure Test_NowZoned_ReturnsValidZonedDateTime;
    procedure Test_NowNaive_ReturnsValidNaiveDateTime;
  end;

implementation

{ TTestCase_Facade }

// ═══════════════════════════════════════════════════════════════
// 类型转出测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_Facade.Test_TDuration_Accessible;
var
  D: TDuration;
begin
  D := TDuration.FromMs(1000);
  AssertEquals('Duration should be 1 second', 1000, D.AsMs);
end;

procedure TTestCase_Facade.Test_TInstant_Accessible;
var
  I: TInstant;
begin
  I := TInstant.Zero;
  AssertEquals('Zero instant should have 0 ns', 0, I.AsNsSinceEpoch);
end;

procedure TTestCase_Facade.Test_TDate_Accessible;
var
  D: TDate;
begin
  D := TDate.Create(2024, 1, 15);
  AssertEquals('Year should be 2024', 2024, D.GetYear);
  AssertEquals('Month should be 1', 1, D.GetMonth);
  AssertEquals('Day should be 15', 15, D.GetDay);
end;

procedure TTestCase_Facade.Test_TTimeOfDay_Accessible;
var
  T: TTimeOfDay;
begin
  T := TTimeOfDay.Create(14, 30, 0);
  AssertEquals('Hour should be 14', 14, T.GetHour);
  AssertEquals('Minute should be 30', 30, T.GetMinute);
end;

procedure TTestCase_Facade.Test_TNaiveDateTime_Accessible;
var
  DT: TNaiveDateTime;
begin
  DT := TNaiveDateTime.Create(2024, 1, 15, 14, 30, 0, 0);
  AssertEquals('Year should be 2024', 2024, DT.Year);
  AssertEquals('Hour should be 14', 14, DT.Hour);
end;

procedure TTestCase_Facade.Test_TZonedDateTime_Accessible;
var
  ZDT: TZonedDateTime;
begin
  ZDT := TZonedDateTime.Create(2024, 1, 15, 14, 30, 0, TUtcOffset.UTC);
  AssertEquals('Year should be 2024', 2024, ZDT.Year);
  AssertTrue('Offset should be UTC', ZDT.Offset.IsUTC);
end;

procedure TTestCase_Facade.Test_TUtcOffset_Accessible;
var
  Off: TUtcOffset;
begin
  Off := TUtcOffset.FromHours(8);
  AssertEquals('Offset should be 8 hours', 8, Off.Hours);
end;

procedure TTestCase_Facade.Test_TIsoWeek_Accessible;
var
  W: TIsoWeek;
begin
  W := TIsoWeek.Create(2024, 1);
  AssertEquals('Year should be 2024', 2024, W.Year);
  AssertEquals('Week should be 1', 1, W.Week);
end;

// ═══════════════════════════════════════════════════════════════
// 新增类型转出测试 (Phase 1)
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_Facade.Test_TPeriod_Accessible;
var
  P: TPeriod;
begin
  P := TPeriod.Create(1, 2, 3);
  AssertEquals('Years should be 1', 1, P.Years);
  AssertEquals('Months should be 2', 2, P.Months);
  AssertEquals('Days should be 3', 3, P.Days);
end;

procedure TTestCase_Facade.Test_TDateRange_Accessible;
var
  R: TDateRange;
  StartDate, EndDate: TDate;
begin
  StartDate := TDate.Create(2024, 1, 1);
  EndDate := TDate.Create(2024, 1, 31);
  R := TDateRange.Create(StartDate, EndDate);
  AssertEquals('Duration should be 30 days', 30, R.GetDuration);
end;

procedure TTestCase_Facade.Test_TTimeRange_Accessible;
var
  R: TTimeRange;
  StartTime, EndTime: TTimeOfDay;
begin
  StartTime := TTimeOfDay.Create(9, 0);
  EndTime := TTimeOfDay.Create(17, 0);
  R := TTimeRange.Create(StartTime, EndTime);
  AssertFalse('Should not cross midnight', R.CrossesMiddnight);
end;

// ═══════════════════════════════════════════════════════════════
// 便捷函数测试 - 已有函数
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_Facade.Test_NowInstant_ReturnsValidInstant;
var
  I1, I2: TInstant;
begin
  I1 := NowInstant;
  I2 := NowInstant;
  // Second call should be >= first
  AssertTrue('Second instant should be >= first', I2 >= I1);
end;

procedure TTestCase_Facade.Test_NowUTC_ReturnsValidDateTime;
var
  DT: TDateTime;
begin
  DT := NowUTC;
  // Should return a reasonable year (2020-2100)
  AssertTrue('Year should be reasonable', (YearOf(DT) >= 2020) and (YearOf(DT) <= 2100));
end;

procedure TTestCase_Facade.Test_NowLocal_ReturnsValidDateTime;
var
  DT: TDateTime;
begin
  DT := NowLocal;
  // Should return a reasonable year (2020-2100)
  AssertTrue('Year should be reasonable', (YearOf(DT) >= 2020) and (YearOf(DT) <= 2100));
end;

procedure TTestCase_Facade.Test_NowUnixMs_ReturnsPositiveValue;
var
  Ms: Int64;
begin
  Ms := NowUnixMs;
  // Should be > 0 and > Jan 1, 2020 in ms
  AssertTrue('Unix ms should be positive and recent', Ms > 1577836800000);
end;

// ═══════════════════════════════════════════════════════════════
// 新增便捷函数测试 (Phase 1)
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_Facade.Test_NowDate_ReturnsValidDate;
var
  D: TDate;
begin
  D := NowDate;
  // Should return a reasonable year (2020-2100)
  AssertTrue('Year should be reasonable', (D.GetYear >= 2020) and (D.GetYear <= 2100));
  AssertTrue('Month should be valid', (D.GetMonth >= 1) and (D.GetMonth <= 12));
  AssertTrue('Day should be valid', (D.GetDay >= 1) and (D.GetDay <= 31));
end;

procedure TTestCase_Facade.Test_NowTime_ReturnsValidTimeOfDay;
var
  T: TTimeOfDay;
begin
  T := NowTime;
  // Should return valid time components
  AssertTrue('Hour should be valid', (T.GetHour >= 0) and (T.GetHour <= 23));
  AssertTrue('Minute should be valid', (T.GetMinute >= 0) and (T.GetMinute <= 59));
  AssertTrue('Second should be valid', (T.GetSecond >= 0) and (T.GetSecond <= 59));
end;

procedure TTestCase_Facade.Test_NowZoned_ReturnsValidZonedDateTime;
var
  ZDT: TZonedDateTime;
begin
  ZDT := NowZoned;
  // Should return a reasonable year (2020-2100)
  AssertTrue('Year should be reasonable', (ZDT.Year >= 2020) and (ZDT.Year <= 2100));
  // Offset should be within valid range (-12 to +14 hours)
  AssertTrue('Offset hours should be valid', 
    (ZDT.Offset.Hours >= -12) and (ZDT.Offset.Hours <= 14));
end;

procedure TTestCase_Facade.Test_NowNaive_ReturnsValidNaiveDateTime;
var
  NDT: TNaiveDateTime;
begin
  NDT := NowNaive;
  // Should return a reasonable year (2020-2100)
  AssertTrue('Year should be reasonable', (NDT.Year >= 2020) and (NDT.Year <= 2100));
  AssertTrue('Hour should be valid', (NDT.Hour >= 0) and (NDT.Hour <= 23));
end;

initialization
  RegisterTest(TTestCase_Facade);

end.
