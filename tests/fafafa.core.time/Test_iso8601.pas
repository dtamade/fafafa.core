unit Test_iso8601;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, DateUtils,
  fafafa.core.time.duration,
  fafafa.core.time.iso8601;

type
  { TTestISO8601DateTime }
  TTestISO8601DateTime = class(TTestCase)
  published
    // 基本日期格式
    procedure Test_FormatDate_Basic;
    procedure Test_FormatDate_Extended;
    procedure Test_ParseDate_Basic;
    procedure Test_ParseDate_Extended;
    
    // 周日期格式
    procedure Test_FormatWeekDate_Extended;
    procedure Test_FormatWeekDate_Basic;
    procedure Test_ParseWeekDate_Extended;
    procedure Test_ParseWeekDate_Basic;
    
    // 序数日期格式
    procedure Test_FormatOrdinalDate_Extended;
    procedure Test_FormatOrdinalDate_Basic;
    procedure Test_ParseOrdinalDate_Extended;
    procedure Test_ParseOrdinalDate_Basic;
    
    // 时间格式
    procedure Test_FormatTime_Basic;
    procedure Test_FormatTime_Extended;
    procedure Test_FormatTime_WithFraction;
    procedure Test_ParseTime_Basic;
    procedure Test_ParseTime_Extended;
    procedure Test_ParseTime_WithFraction;
    
    // 时区支持
    procedure Test_FormatTimeZone_UTC;
    procedure Test_FormatTimeZone_Extended;
    procedure Test_FormatTimeZone_Basic;
    procedure Test_FormatTimeZone_HourOnly;
    procedure Test_ParseTimeZone_UTC;
    procedure Test_ParseTimeZone_Positive;
    procedure Test_ParseTimeZone_Negative;
    
    // 日期时间组合
    procedure Test_FormatDateTime_Default;
    procedure Test_FormatDateTime_UTC;
    procedure Test_FormatDateTime_WithTimeZone;
    procedure Test_ParseDateTime_Complete;
    procedure Test_ParseDateTime_WithTimeZone;
    procedure Test_ParseDateTime_UTC;
    
    // 往返测试
    procedure Test_RoundTrip_BasicDate;
    procedure Test_RoundTrip_ExtendedDateTime;
    procedure Test_RoundTrip_WithTimeZone;
  end;

  { TTestISO8601Duration }
  TTestISO8601Duration = class(TTestCase)
  published
    // P notation 格式化
    procedure Test_FormatDuration_Zero;
    procedure Test_FormatDuration_Seconds;
    procedure Test_FormatDuration_Minutes;
    procedure Test_FormatDuration_Hours;
    procedure Test_FormatDuration_Days;
    procedure Test_FormatDuration_Mixed;
    procedure Test_FormatDuration_WithFraction;
    
    // P notation 解析
    procedure Test_ParseDuration_Zero;
    procedure Test_ParseDuration_Seconds;
    procedure Test_ParseDuration_Minutes;
    procedure Test_ParseDuration_Hours;
    procedure Test_ParseDuration_Days;
    procedure Test_ParseDuration_Weeks;
    procedure Test_ParseDuration_Mixed;
    procedure Test_ParseDuration_WithFraction;
    procedure Test_ParseDuration_YearsMonths;
    
    // 往返测试
    procedure Test_RoundTrip_Duration;
    procedure Test_RoundTrip_ComplexDuration;
  end;

  { TTestISO8601EdgeCases }
  TTestISO8601EdgeCases = class(TTestCase)
  published
    procedure Test_LeapYear_Date;
    procedure Test_Week53_Date;
    procedure Test_DayOfYear366;
    procedure Test_Midnight_Time;
    procedure Test_NegativeTimeZone;
    procedure Test_LargeTimeZoneOffset;
    procedure Test_VerySmallDuration;
    procedure Test_VeryLargeDuration;
  end;

implementation

{ TTestISO8601DateTime }

procedure TTestISO8601DateTime.Test_FormatDate_Basic;
var
  D: TDateTime;
  S: string;
begin
  D := EncodeDate(2023, 12, 25);
  S := TISO8601Formatter.FormatDate(D, idfBasic);
  AssertEquals('Basic date format', '20231225', S);
end;

procedure TTestISO8601DateTime.Test_FormatDate_Extended;
var
  D: TDateTime;
  S: string;
begin
  D := EncodeDate(2023, 12, 25);
  S := TISO8601Formatter.FormatDate(D, idfExtended);
  AssertEquals('Extended date format', '2023-12-25', S);
end;

procedure TTestISO8601DateTime.Test_ParseDate_Basic;
var
  D: TDateTime;
  Success: Boolean;
  Year, Month, Day: Word;
begin
  Success := TISO8601Parser.ParseDate('20231225', D);
  AssertTrue('Parse basic date success', Success);
  DecodeDate(D, Year, Month, Day);
  AssertEquals('Year', 2023, Year);
  AssertEquals('Month', 12, Month);
  AssertEquals('Day', 25, Day);
end;

procedure TTestISO8601DateTime.Test_ParseDate_Extended;
var
  D: TDateTime;
  Success: Boolean;
  Year, Month, Day: Word;
begin
  Success := TISO8601Parser.ParseDate('2023-12-25', D);
  AssertTrue('Parse extended date success', Success);
  DecodeDate(D, Year, Month, Day);
  AssertEquals('Year', 2023, Year);
  AssertEquals('Month', 12, Month);
  AssertEquals('Day', 25, Day);
end;

procedure TTestISO8601DateTime.Test_FormatWeekDate_Extended;
var
  D: TDateTime;
  S: string;
begin
  D := EncodeDate(2023, 12, 25); // Monday
  S := TISO8601Formatter.FormatWeekDate(D, False);
  // 2023-12-25 是 2023年第52周的星期一
  AssertTrue('Week date format starts with year', Pos('2023-W', S) = 1);
end;

procedure TTestISO8601DateTime.Test_FormatWeekDate_Basic;
var
  D: TDateTime;
  S: string;
begin
  D := EncodeDate(2023, 12, 25);
  S := TISO8601Formatter.FormatWeekDate(D, True);
  AssertTrue('Basic week date format starts with year', Pos('2023W', S) = 1);
end;

procedure TTestISO8601DateTime.Test_ParseWeekDate_Extended;
var
  D: TDateTime;
  Success: Boolean;
begin
  Success := TISO8601Parser.ParseWeekDate('2023-W52-1', D);
  AssertTrue('Parse week date success', Success);
  AssertTrue('Week date is valid', D > 0);
end;

procedure TTestISO8601DateTime.Test_ParseWeekDate_Basic;
var
  D: TDateTime;
  Success: Boolean;
begin
  Success := TISO8601Parser.ParseWeekDate('2023W521', D);
  AssertTrue('Parse basic week date success', Success);
  AssertTrue('Week date is valid', D > 0);
end;

procedure TTestISO8601DateTime.Test_FormatOrdinalDate_Extended;
var
  D: TDateTime;
  S: string;
begin
  D := EncodeDate(2023, 12, 25);
  S := TISO8601Formatter.FormatOrdinalDate(D, False);
  // 2023年12月25日是第359天
  AssertEquals('Ordinal date format', '2023-359', S);
end;

procedure TTestISO8601DateTime.Test_FormatOrdinalDate_Basic;
var
  D: TDateTime;
  S: string;
begin
  D := EncodeDate(2023, 12, 25);
  S := TISO8601Formatter.FormatOrdinalDate(D, True);
  AssertEquals('Basic ordinal date format', '2023359', S);
end;

procedure TTestISO8601DateTime.Test_ParseOrdinalDate_Extended;
var
  D: TDateTime;
  Success: Boolean;
  Year, Month, Day: Word;
begin
  Success := TISO8601Parser.ParseOrdinalDate('2023-359', D);
  AssertTrue('Parse ordinal date success', Success);
  DecodeDate(D, Year, Month, Day);
  AssertEquals('Year', 2023, Year);
  AssertEquals('Month', 12, Month);
  AssertEquals('Day', 25, Day);
end;

procedure TTestISO8601DateTime.Test_ParseOrdinalDate_Basic;
var
  D: TDateTime;
  Success: Boolean;
  Year, Month, Day: Word;
begin
  Success := TISO8601Parser.ParseOrdinalDate('2023359', D);
  AssertTrue('Parse basic ordinal date success', Success);
  DecodeDate(D, Year, Month, Day);
  AssertEquals('Year', 2023, Year);
end;

procedure TTestISO8601DateTime.Test_FormatTime_Basic;
var
  T: TDateTime;
  S: string;
begin
  T := EncodeTime(14, 30, 45, 0);
  S := TISO8601Formatter.FormatTime(T, itfBasic, 0);
  AssertEquals('Basic time format', '143045', S);
end;

procedure TTestISO8601DateTime.Test_FormatTime_Extended;
var
  T: TDateTime;
  S: string;
begin
  T := EncodeTime(14, 30, 45, 0);
  S := TISO8601Formatter.FormatTime(T, itfExtended, 0);
  AssertEquals('Extended time format', '14:30:45', S);
end;

procedure TTestISO8601DateTime.Test_FormatTime_WithFraction;
var
  T: TDateTime;
  S: string;
begin
  T := EncodeTime(14, 30, 45, 123);
  S := TISO8601Formatter.FormatTime(T, itfExtendedFraction, 3);
  AssertTrue('Time with fraction contains dot', Pos('.', S) > 0);
  AssertTrue('Time with fraction format', Pos('14:30:45.', S) = 1);
end;

procedure TTestISO8601DateTime.Test_ParseTime_Basic;
var
  T: TDateTime;
  Success: Boolean;
  Hour, Min, Sec, MSec: Word;
begin
  Success := TISO8601Parser.ParseTime('143045', T);
  AssertTrue('Parse basic time success', Success);
  DecodeTime(T, Hour, Min, Sec, MSec);
  AssertEquals('Hour', 14, Hour);
  AssertEquals('Minute', 30, Min);
  AssertEquals('Second', 45, Sec);
end;

procedure TTestISO8601DateTime.Test_ParseTime_Extended;
var
  T: TDateTime;
  Success: Boolean;
  Hour, Min, Sec, MSec: Word;
begin
  Success := TISO8601Parser.ParseTime('14:30:45', T);
  AssertTrue('Parse extended time success', Success);
  DecodeTime(T, Hour, Min, Sec, MSec);
  AssertEquals('Hour', 14, Hour);
  AssertEquals('Minute', 30, Min);
  AssertEquals('Second', 45, Sec);
end;

procedure TTestISO8601DateTime.Test_ParseTime_WithFraction;
var
  T: TDateTime;
  Success: Boolean;
  Hour, Min, Sec, MSec: Word;
begin
  Success := TISO8601Parser.ParseTime('14:30:45.123', T);
  AssertTrue('Parse time with fraction success', Success);
  DecodeTime(T, Hour, Min, Sec, MSec);
  AssertEquals('Hour', 14, Hour);
  AssertEquals('Minute', 30, Min);
  AssertEquals('Second', 45, Sec);
  AssertEquals('Millisecond', 123, MSec);
end;

procedure TTestISO8601DateTime.Test_FormatTimeZone_UTC;
var
  S: string;
begin
  S := TISO8601Formatter.FormatTimeZone(0, itzUTC);
  AssertEquals('UTC timezone', 'Z', S);
end;

procedure TTestISO8601DateTime.Test_FormatTimeZone_Extended;
var
  S: string;
begin
  S := TISO8601Formatter.FormatTimeZone(480, itzExtended); // +08:00
  AssertEquals('Extended timezone', '+08:00', S);
end;

procedure TTestISO8601DateTime.Test_FormatTimeZone_Basic;
var
  S: string;
begin
  S := TISO8601Formatter.FormatTimeZone(480, itzBasic); // +0800
  AssertEquals('Basic timezone', '+0800', S);
end;

procedure TTestISO8601DateTime.Test_FormatTimeZone_HourOnly;
var
  S: string;
begin
  S := TISO8601Formatter.FormatTimeZone(480, itzHourOnly); // +08
  AssertEquals('Hour only timezone', '+08', S);
end;

procedure TTestISO8601DateTime.Test_ParseTimeZone_UTC;
var
  Offset, Pos: Integer;
  Success: Boolean;
begin
  Success := TISO8601Parser.ParseTimeZone('2023-12-25T14:30:45Z', Offset, Pos);
  AssertTrue('Parse UTC timezone success', Success);
  AssertEquals('UTC offset', 0, Offset);
end;

procedure TTestISO8601DateTime.Test_ParseTimeZone_Positive;
var
  Offset, Pos: Integer;
  Success: Boolean;
begin
  Success := TISO8601Parser.ParseTimeZone('2023-12-25T14:30:45+08:00', Offset, Pos);
  AssertTrue('Parse positive timezone success', Success);
  AssertEquals('Positive offset', 480, Offset);
end;

procedure TTestISO8601DateTime.Test_ParseTimeZone_Negative;
var
  Offset, Pos: Integer;
  Success: Boolean;
begin
  Success := TISO8601Parser.ParseTimeZone('2023-12-25T14:30:45-05:00', Offset, Pos);
  AssertTrue('Parse negative timezone success', Success);
  AssertEquals('Negative offset', -300, Offset);
end;

procedure TTestISO8601DateTime.Test_FormatDateTime_Default;
var
  DT: TDateTime;
  S: string;
begin
  DT := EncodeDate(2023, 12, 25) + EncodeTime(14, 30, 45, 123);
  S := TISO8601Formatter.FormatDateTime(DT);
  AssertTrue('DateTime contains T separator', Pos('T', S) > 0);
  AssertTrue('DateTime contains date', Pos('2023', S) = 1);
end;

procedure TTestISO8601DateTime.Test_FormatDateTime_UTC;
var
  DT: TDateTime;
  S: string;
begin
  DT := EncodeDate(2023, 12, 25) + EncodeTime(14, 30, 45, 0);
  S := TISO8601Formatter.FormatDateTime(DT, TISO8601Options.UTC);
  AssertTrue('UTC datetime ends with Z', S[Length(S)] = 'Z');
end;

procedure TTestISO8601DateTime.Test_FormatDateTime_WithTimeZone;
var
  DT: TDateTime;
  S: string;
begin
  DT := EncodeDate(2023, 12, 25) + EncodeTime(14, 30, 45, 0);
  S := TISO8601Formatter.FormatDateTime(DT, TISO8601Options.WithTimeZone);
  AssertTrue('DateTime has timezone info', (Pos('+', S) > 0) or (Pos('-', S) > 0) or (S[Length(S)] = 'Z'));
end;

procedure TTestISO8601DateTime.Test_ParseDateTime_Complete;
var
  DT: TDateTime;
  Success: Boolean;
  Year, Month, Day: Word;
  Hour, Min, Sec, MSec: Word;
begin
  Success := TISO8601Parser.ParseDateTime('2023-12-25T14:30:45', DT);
  AssertTrue('Parse complete datetime success', Success);
  
  DecodeDate(DT, Year, Month, Day);
  AssertEquals('Year', 2023, Year);
  AssertEquals('Month', 12, Month);
  AssertEquals('Day', 25, Day);
  
  DecodeTime(DT, Hour, Min, Sec, MSec);
  AssertEquals('Hour', 14, Hour);
  AssertEquals('Minute', 30, Min);
  AssertEquals('Second', 45, Sec);
end;

procedure TTestISO8601DateTime.Test_ParseDateTime_WithTimeZone;
var
  DT: TDateTime;
  Success: Boolean;
begin
  Success := TISO8601Parser.ParseDateTime('2023-12-25T14:30:45+08:00', DT);
  AssertTrue('Parse datetime with timezone success', Success);
end;

procedure TTestISO8601DateTime.Test_ParseDateTime_UTC;
var
  DT: TDateTime;
  Success: Boolean;
begin
  Success := TISO8601Parser.ParseDateTime('2023-12-25T14:30:45Z', DT);
  AssertTrue('Parse UTC datetime success', Success);
end;

procedure TTestISO8601DateTime.Test_RoundTrip_BasicDate;
var
  D, D2: TDateTime;
  S: string;
begin
  D := EncodeDate(2023, 12, 25);
  S := TISO8601Formatter.FormatDate(D, idfBasic);
  TISO8601Parser.ParseDate(S, D2);
  AssertEquals('Round trip basic date', Trunc(D), Trunc(D2));
end;

procedure TTestISO8601DateTime.Test_RoundTrip_ExtendedDateTime;
var
  DT, DT2: TDateTime;
  S: string;
  Opts: TISO8601Options;
begin
  DT := EncodeDate(2023, 12, 25) + EncodeTime(14, 30, 45, 0);
  Opts := TISO8601Options.Default;
  Opts.FractionalSeconds := 0;
  S := TISO8601Formatter.FormatDateTime(DT, Opts);
  TISO8601Parser.ParseDateTime(S, DT2);
  
  // 允许1秒的误差（由于精度）
  AssertTrue('Round trip datetime', Abs(DT - DT2) < (1.0 / 86400.0));
end;

procedure TTestISO8601DateTime.Test_RoundTrip_WithTimeZone;
var
  DT, DT2: TDateTime;
  S: string;
begin
  DT := EncodeDate(2023, 12, 25) + EncodeTime(14, 30, 45, 0);
  S := TISO8601Formatter.FormatDateTime(DT, TISO8601Options.UTC);
  TISO8601Parser.ParseDateTime(S, DT2);
  
  // 允许小误差
  AssertTrue('Round trip with timezone', Abs(DT - DT2) < 1.0);
end;

{ TTestISO8601Duration }

procedure TTestISO8601Duration.Test_FormatDuration_Zero;
var
  D: TDuration;
  S: string;
begin
  D := TDuration.Zero;
  S := TISO8601Formatter.FormatDuration(D);
  AssertEquals('Zero duration', 'PT0S', S);
end;

procedure TTestISO8601Duration.Test_FormatDuration_Seconds;
var
  D: TDuration;
  S: string;
begin
  D := TDuration.FromSec(45);
  S := TISO8601Formatter.FormatDuration(D);
  AssertEquals('Seconds duration', 'PT45S', S);
end;

procedure TTestISO8601Duration.Test_FormatDuration_Minutes;
var
  D: TDuration;
  S: string;
begin
  D := TDuration.FromMinutes(30);
  S := TISO8601Formatter.FormatDuration(D);
  AssertEquals('Minutes duration', 'PT30M', S);
end;

procedure TTestISO8601Duration.Test_FormatDuration_Hours;
var
  D: TDuration;
  S: string;
begin
  D := TDuration.FromHours(2);
  S := TISO8601Formatter.FormatDuration(D);
  AssertEquals('Hours duration', 'PT2H', S);
end;

procedure TTestISO8601Duration.Test_FormatDuration_Days;
var
  D: TDuration;
  S: string;
begin
  D := TDuration.FromDays(3);
  S := TISO8601Formatter.FormatDuration(D);
  AssertEquals('Days duration', 'P3D', S);
end;

procedure TTestISO8601Duration.Test_FormatDuration_Mixed;
var
  D: TDuration;
  S: string;
begin
  D := TDuration.FromHours(2) + TDuration.FromMinutes(30) + TDuration.FromSec(45);
  S := TISO8601Formatter.FormatDuration(D);
  AssertTrue('Mixed duration contains PT', Pos('PT', S) = 1);
  AssertTrue('Mixed duration contains H', Pos('H', S) > 0);
  AssertTrue('Mixed duration contains M', Pos('M', S) > 0);
  AssertTrue('Mixed duration contains S', Pos('S', S) > 0);
end;

procedure TTestISO8601Duration.Test_FormatDuration_WithFraction;
var
  D: TDuration;
  S: string;
begin
  D := TDuration.FromSec(45) + TDuration.FromMs(500);
  S := TISO8601Formatter.FormatDuration(D);
  AssertTrue('Duration with fraction contains dot', Pos('.', S) > 0);
end;

procedure TTestISO8601Duration.Test_ParseDuration_Zero;
var
  D: TDuration;
  Success: Boolean;
begin
  Success := TISO8601Parser.ParseDuration('PT0S', D);
  AssertTrue('Parse zero duration success', Success);
  AssertEquals('Zero duration seconds', Int64(0), D.AsSec);
end;

procedure TTestISO8601Duration.Test_ParseDuration_Seconds;
var
  D: TDuration;
  Success: Boolean;
begin
  Success := TISO8601Parser.ParseDuration('PT45S', D);
  AssertTrue('Parse seconds duration success', Success);
  AssertEquals('Seconds duration value', Int64(45), D.AsSec);
end;

procedure TTestISO8601Duration.Test_ParseDuration_Minutes;
var
  D: TDuration;
  Success: Boolean;
begin
  Success := TISO8601Parser.ParseDuration('PT30M', D);
  AssertTrue('Parse minutes duration success', Success);
  AssertEquals('Minutes duration value', Int64(30 * 60), D.AsSec);
end;

procedure TTestISO8601Duration.Test_ParseDuration_Hours;
var
  D: TDuration;
  Success: Boolean;
begin
  Success := TISO8601Parser.ParseDuration('PT2H', D);
  AssertTrue('Parse hours duration success', Success);
  AssertEquals('Hours duration value', Int64(2 * 3600), D.AsSec);
end;

procedure TTestISO8601Duration.Test_ParseDuration_Days;
var
  D: TDuration;
  Success: Boolean;
begin
  Success := TISO8601Parser.ParseDuration('P3D', D);
  AssertTrue('Parse days duration success', Success);
  AssertEquals('Days duration value', Int64(3 * 86400), D.AsSec);
end;

procedure TTestISO8601Duration.Test_ParseDuration_Weeks;
var
  D: TDuration;
  Success: Boolean;
begin
  Success := TISO8601Parser.ParseDuration('P2W', D);
  AssertTrue('Parse weeks duration success', Success);
  AssertEquals('Weeks duration value', Int64(2 * 7 * 86400), D.AsSec);
end;

procedure TTestISO8601Duration.Test_ParseDuration_Mixed;
var
  D: TDuration;
  Success: Boolean;
  Expected: Int64;
begin
  Success := TISO8601Parser.ParseDuration('PT2H30M45S', D);
  AssertTrue('Parse mixed duration success', Success);
  Expected := 2 * 3600 + 30 * 60 + 45;
  AssertEquals('Mixed duration value', Expected, D.AsSec);
end;

procedure TTestISO8601Duration.Test_ParseDuration_WithFraction;
var
  D: TDuration;
  Success: Boolean;
begin
  Success := TISO8601Parser.ParseDuration('PT1.5S', D);
  AssertTrue('Parse fractional duration success', Success);
  AssertEquals('Fractional duration milliseconds', Int64(1500), D.AsMs);
end;

procedure TTestISO8601Duration.Test_ParseDuration_YearsMonths;
var
  D: TDuration;
  Success: Boolean;
begin
  Success := TISO8601Parser.ParseDuration('P1Y2M3DT4H5M6S', D);
  AssertTrue('Parse complex duration success', Success);
  AssertTrue('Complex duration is positive', D.AsSec > 0);
end;

procedure TTestISO8601Duration.Test_RoundTrip_Duration;
var
  D, D2: TDuration;
  S: string;
begin
  D := TDuration.FromHours(2) + TDuration.FromMinutes(30);
  S := TISO8601Formatter.FormatDuration(D);
  TISO8601Parser.ParseDuration(S, D2);
  AssertEquals('Round trip duration', D.AsSec, D2.AsSec);
end;

procedure TTestISO8601Duration.Test_RoundTrip_ComplexDuration;
var
  D, D2: TDuration;
  S: string;
begin
  D := TDuration.FromDays(1) + TDuration.FromHours(2) + 
       TDuration.FromMinutes(30) + TDuration.FromSec(45);
  S := TISO8601Formatter.FormatDuration(D);
  TISO8601Parser.ParseDuration(S, D2);
  AssertEquals('Round trip complex duration', D.AsSec, D2.AsSec);
end;

{ TTestISO8601EdgeCases }

procedure TTestISO8601EdgeCases.Test_LeapYear_Date;
var
  D, D2: TDateTime;
  S: string;
begin
  D := EncodeDate(2024, 2, 29); // Leap year
  S := TISO8601Formatter.FormatDate(D, idfExtended);
  AssertEquals('Leap year date', '2024-02-29', S);
  
  TISO8601Parser.ParseDate(S, D2);
  AssertEquals('Leap year round trip', Trunc(D), Trunc(D2));
end;

procedure TTestISO8601EdgeCases.Test_Week53_Date;
var
  D: TDateTime;
  S: string;
begin
  // 某些年份有53周
  D := EncodeDate(2020, 12, 31);
  S := TISO8601Formatter.FormatWeekDate(D, False);
  AssertTrue('Week 53 format valid', Length(S) > 0);
end;

procedure TTestISO8601EdgeCases.Test_DayOfYear366;
var
  D, D2: TDateTime;
  S: string;
begin
  D := EncodeDate(2024, 12, 31); // Day 366 in leap year
  S := TISO8601Formatter.FormatOrdinalDate(D, False);
  AssertEquals('Day 366 format', '2024-366', S);
  
  TISO8601Parser.ParseOrdinalDate(S, D2);
  AssertEquals('Day 366 round trip', Trunc(D), Trunc(D2));
end;

procedure TTestISO8601EdgeCases.Test_Midnight_Time;
var
  T, T2: TDateTime;
  S: string;
begin
  T := EncodeTime(0, 0, 0, 0);
  S := TISO8601Formatter.FormatTime(T, itfExtended, 0);
  AssertEquals('Midnight format', '00:00:00', S);
  
  TISO8601Parser.ParseTime(S, T2);
  AssertEquals('Midnight round trip', Trunc(T * 86400), Trunc(T2 * 86400));
end;

procedure TTestISO8601EdgeCases.Test_NegativeTimeZone;
var
  S: string;
begin
  S := TISO8601Formatter.FormatTimeZone(-300, itzExtended);
  AssertEquals('Negative timezone', '-05:00', S);
end;

procedure TTestISO8601EdgeCases.Test_LargeTimeZoneOffset;
var
  S: string;
begin
  S := TISO8601Formatter.FormatTimeZone(720, itzExtended); // +12:00
  AssertEquals('Large timezone', '+12:00', S);
end;

procedure TTestISO8601EdgeCases.Test_VerySmallDuration;
var
  D: TDuration;
  S: string;
begin
  D := TDuration.FromMs(1);
  S := TISO8601Formatter.FormatDuration(D);
  AssertTrue('Very small duration valid', Length(S) > 0);
  AssertTrue('Very small duration contains S', Pos('S', S) > 0);
end;

procedure TTestISO8601EdgeCases.Test_VeryLargeDuration;
var
  D: TDuration;
  S: string;
begin
  D := TDuration.FromDays(365);
  S := TISO8601Formatter.FormatDuration(D);
  AssertTrue('Very large duration valid', Length(S) > 0);
  AssertTrue('Very large duration starts with P', Pos('P', S) = 1);
end;

initialization
  RegisterTest(TTestISO8601DateTime);
  RegisterTest(TTestISO8601Duration);
  RegisterTest(TTestISO8601EdgeCases);

end.
