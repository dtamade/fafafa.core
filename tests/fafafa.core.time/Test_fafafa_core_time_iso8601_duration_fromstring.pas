{$mode objfpc}{$H+}{$J-}

unit Test_fafafa_core_time_iso8601_duration_fromstring;

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.iso8601;

type
  { TTestISO8601DurationFromString }
  TTestISO8601DurationFromString = class(TTestCase)
  published
    // 基本解析测试
    procedure Test_FromString_SimpleSeconds;
    procedure Test_FromString_SimpleMinutes;
    procedure Test_FromString_SimpleHours;
    procedure Test_FromString_SimpleDays;
    procedure Test_FromString_SimpleMonths;
    procedure Test_FromString_SimpleYears;
    procedure Test_FromString_SimpleWeeks;
    
    // 组合测试
    procedure Test_FromString_DateOnly;
    procedure Test_FromString_TimeOnly;
    procedure Test_FromString_DateAndTime;
    procedure Test_FromString_Full;
    
    // 小数测试
    procedure Test_FromString_FractionalSeconds;
    procedure Test_FromString_FractionalWithComma;
    
    // 边界/特殊情况
    procedure Test_FromString_Empty_ReturnsZero;
    procedure Test_FromString_InvalidFormat_ReturnsZero;
    procedure Test_FromString_ZeroDuration;
    
    // 往返测试
    procedure Test_RoundTrip_DateAndTime;
  end;

implementation

{ TTestISO8601DurationFromString }

procedure TTestISO8601DurationFromString.Test_FromString_SimpleSeconds;
var d: TISO8601Duration;
begin
  d := TISO8601Duration.FromString('PT45S');
  AssertEquals('Seconds', 45, Round(d.Seconds));
  AssertEquals('Minutes', 0, d.Minutes);
  AssertEquals('Hours', 0, d.Hours);
  AssertEquals('Days', 0, d.Days);
  AssertEquals('Months', 0, d.Months);
  AssertEquals('Years', 0, d.Years);
end;

procedure TTestISO8601DurationFromString.Test_FromString_SimpleMinutes;
var d: TISO8601Duration;
begin
  d := TISO8601Duration.FromString('PT30M');
  AssertEquals('Minutes', 30, d.Minutes);
  AssertEquals('Seconds', 0, Round(d.Seconds));
end;

procedure TTestISO8601DurationFromString.Test_FromString_SimpleHours;
var d: TISO8601Duration;
begin
  d := TISO8601Duration.FromString('PT24H');
  AssertEquals('Hours', 24, d.Hours);
end;

procedure TTestISO8601DurationFromString.Test_FromString_SimpleDays;
var d: TISO8601Duration;
begin
  d := TISO8601Duration.FromString('P7D');
  AssertEquals('Days', 7, d.Days);
end;

procedure TTestISO8601DurationFromString.Test_FromString_SimpleMonths;
var d: TISO8601Duration;
begin
  d := TISO8601Duration.FromString('P3M');
  AssertEquals('Months', 3, d.Months);
end;

procedure TTestISO8601DurationFromString.Test_FromString_SimpleYears;
var d: TISO8601Duration;
begin
  d := TISO8601Duration.FromString('P2Y');
  AssertEquals('Years', 2, d.Years);
end;

procedure TTestISO8601DurationFromString.Test_FromString_SimpleWeeks;
var d: TISO8601Duration;
begin
  d := TISO8601Duration.FromString('P2W');
  AssertEquals('Days (2 weeks = 14 days)', 14, d.Days);
end;

procedure TTestISO8601DurationFromString.Test_FromString_DateOnly;
var d: TISO8601Duration;
begin
  d := TISO8601Duration.FromString('P1Y2M3D');
  AssertEquals('Years', 1, d.Years);
  AssertEquals('Months', 2, d.Months);
  AssertEquals('Days', 3, d.Days);
  AssertEquals('Hours', 0, d.Hours);
  AssertEquals('Minutes', 0, d.Minutes);
  AssertEquals('Seconds', 0, Round(d.Seconds));
end;

procedure TTestISO8601DurationFromString.Test_FromString_TimeOnly;
var d: TISO8601Duration;
begin
  d := TISO8601Duration.FromString('PT4H5M6S');
  AssertEquals('Hours', 4, d.Hours);
  AssertEquals('Minutes', 5, d.Minutes);
  AssertEquals('Seconds', 6, Round(d.Seconds));
  AssertEquals('Years', 0, d.Years);
  AssertEquals('Months', 0, d.Months);
  AssertEquals('Days', 0, d.Days);
end;

procedure TTestISO8601DurationFromString.Test_FromString_DateAndTime;
var d: TISO8601Duration;
begin
  d := TISO8601Duration.FromString('P10DT12H30M');
  AssertEquals('Days', 10, d.Days);
  AssertEquals('Hours', 12, d.Hours);
  AssertEquals('Minutes', 30, d.Minutes);
end;

procedure TTestISO8601DurationFromString.Test_FromString_Full;
var d: TISO8601Duration;
begin
  d := TISO8601Duration.FromString('P1Y2M3DT4H5M6S');
  AssertEquals('Years', 1, d.Years);
  AssertEquals('Months', 2, d.Months);
  AssertEquals('Days', 3, d.Days);
  AssertEquals('Hours', 4, d.Hours);
  AssertEquals('Minutes', 5, d.Minutes);
  AssertEquals('Seconds', 6, Round(d.Seconds));
end;

procedure TTestISO8601DurationFromString.Test_FromString_FractionalSeconds;
var d: TISO8601Duration;
begin
  d := TISO8601Duration.FromString('PT1.5S');
  AssertTrue('Seconds should be approximately 1.5', Abs(d.Seconds - 1.5) < 0.001);
end;

procedure TTestISO8601DurationFromString.Test_FromString_FractionalWithComma;
var d: TISO8601Duration;
begin
  // ISO 8601 允许逗号作为小数分隔符
  d := TISO8601Duration.FromString('PT1,5S');
  AssertTrue('Seconds should be approximately 1.5', Abs(d.Seconds - 1.5) < 0.001);
end;

procedure TTestISO8601DurationFromString.Test_FromString_Empty_ReturnsZero;
var d: TISO8601Duration;
begin
  d := TISO8601Duration.FromString('');
  AssertEquals('All fields should be 0', 0, d.Years + d.Months + d.Days + 
               d.Hours + d.Minutes + Round(d.Seconds));
end;

procedure TTestISO8601DurationFromString.Test_FromString_InvalidFormat_ReturnsZero;
var d: TISO8601Duration;
begin
  // 无效格式（不以 P 开头）
  d := TISO8601Duration.FromString('T1H30M');
  AssertEquals('All fields should be 0', 0, d.Years + d.Months + d.Days + 
               d.Hours + d.Minutes + Round(d.Seconds));
end;

procedure TTestISO8601DurationFromString.Test_FromString_ZeroDuration;
var d: TISO8601Duration;
begin
  d := TISO8601Duration.FromString('PT0S');
  AssertEquals('Seconds', 0, Round(d.Seconds));
end;

procedure TTestISO8601DurationFromString.Test_RoundTrip_DateAndTime;
var
  original, parsed: TISO8601Duration;
  str: string;
begin
  // 创建原始值
  original.Years := 0;
  original.Months := 0;
  original.Days := 5;
  original.Hours := 12;
  original.Minutes := 30;
  original.Seconds := 45;
  
  // 转为字符串再解析回来
  str := original.ToString;
  parsed := TISO8601Duration.FromString(str);
  
  AssertEquals('Days roundtrip', original.Days, parsed.Days);
  AssertEquals('Hours roundtrip', original.Hours, parsed.Hours);
  AssertEquals('Minutes roundtrip', original.Minutes, parsed.Minutes);
  AssertTrue('Seconds roundtrip', Abs(original.Seconds - parsed.Seconds) < 0.001);
end;

initialization
  RegisterTest(TTestISO8601DurationFromString);

end.
