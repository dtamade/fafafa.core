program Test_Format;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, DateUtils,
  fafafa.core.time.base,
  fafafa.core.time.duration,
  fafafa.core.time.date,
  fafafa.core.time.timeofday,
  fafafa.core.time.format;

var
  TotalTests: Integer = 0;
  PassedTests: Integer = 0;
  FailedTests: Integer = 0;

procedure AssertEquals(const Expected, Actual, TestName: string);
begin
  Inc(TotalTests);
  if Expected = Actual then
  begin
    Inc(PassedTests);
    WriteLn('  ✓ ', TestName);
  end
  else
  begin
    Inc(FailedTests);
    WriteLn('  ✗ ', TestName);
    WriteLn('    Expected: "', Expected, '"');
    WriteLn('    Actual:   "', Actual, '"');
  end;
end;

procedure AssertContains(const Substring, Actual, TestName: string);
begin
  Inc(TotalTests);
  if Pos(Substring, Actual) > 0 then
  begin
    Inc(PassedTests);
    WriteLn('  ✓ ', TestName);
  end
  else
  begin
    Inc(FailedTests);
    WriteLn('  ✗ ', TestName);
    WriteLn('    Expected to contain: "', Substring, '"');
    WriteLn('    Actual: "', Actual, '"');
  end;
end;

procedure AssertTrue(Condition: Boolean; const TestName: string);
begin
  Inc(TotalTests);
  if Condition then
  begin
    Inc(PassedTests);
    WriteLn('  ✓ ', TestName);
  end
  else
  begin
    Inc(FailedTests);
    WriteLn('  ✗ ', TestName);
  end;
end;

// ============================================================================
// FormatDateTime Tests
// ============================================================================

procedure Test_FormatDateTime_ISO8601;
var
  dt: TDateTime;
  s: string;
begin
  WriteLn('Test_FormatDateTime_ISO8601:');
  dt := EncodeDateTime(2024, 12, 25, 14, 30, 45, 123);
  s := FormatDateTime(dt, dtfISO8601);
  AssertContains('2024-12-25', s, 'Contains date part');
  AssertContains('14:30:45', s, 'Contains time part');
end;

procedure Test_FormatDateTime_ISO8601Date;
var
  dt: TDateTime;
  s: string;
begin
  WriteLn('Test_FormatDateTime_ISO8601Date:');
  dt := EncodeDateTime(2024, 1, 15, 9, 5, 0, 0);
  s := FormatDateTime(dt, dtfISO8601Date);
  AssertContains('2024-01-15', s, 'ISO8601 date format');
end;

procedure Test_FormatDateTime_ISO8601Time;
var
  dt: TDateTime;
  s: string;
begin
  WriteLn('Test_FormatDateTime_ISO8601Time:');
  dt := EncodeDateTime(2024, 1, 1, 23, 59, 59, 0);
  s := FormatDateTime(dt, dtfISO8601Time);
  AssertContains('23:59:59', s, 'ISO8601 time format');
end;

procedure Test_FormatDateTime_Short;
var
  dt: TDateTime;
  s: string;
begin
  WriteLn('Test_FormatDateTime_Short:');
  dt := EncodeDateTime(2024, 12, 25, 14, 30, 0, 0);
  s := FormatDateTime(dt, dtfShort);
  // Short format: m/d/yy h:nn AM/PM
  AssertTrue(Length(s) > 0, 'Short format produces output');
end;

procedure Test_FormatDateTime_Medium;
var
  dt: TDateTime;
  s: string;
begin
  WriteLn('Test_FormatDateTime_Medium:');
  dt := EncodeDateTime(2024, 12, 25, 14, 30, 45, 0);
  s := FormatDateTime(dt, dtfMedium);
  // Medium format includes month name abbreviation
  AssertTrue(Length(s) > 0, 'Medium format produces output');
end;

procedure Test_FormatDateTime_Long;
var
  dt: TDateTime;
  s: string;
begin
  WriteLn('Test_FormatDateTime_Long:');
  dt := EncodeDateTime(2024, 12, 25, 14, 30, 45, 0);
  s := FormatDateTime(dt, dtfLong);
  // Long format includes full month name
  AssertTrue(Length(s) > 0, 'Long format produces output');
end;

procedure Test_FormatDateTime_Full;
var
  dt: TDateTime;
  s: string;
begin
  WriteLn('Test_FormatDateTime_Full:');
  dt := EncodeDateTime(2024, 12, 25, 14, 30, 45, 0);
  s := FormatDateTime(dt, dtfFull);
  // Full format includes weekday
  AssertTrue(Length(s) > 0, 'Full format produces output');
end;

procedure Test_FormatDateTime_CustomPattern;
var
  dt: TDateTime;
  s: string;
begin
  WriteLn('Test_FormatDateTime_CustomPattern:');
  dt := EncodeDateTime(2024, 10, 4, 14, 30, 45, 0);
  s := FormatDateTime(dt, 'yyyy-mm-dd');
  AssertEquals('2024-10-04', s, 'Custom pattern yyyy-mm-dd');
end;

// ============================================================================
// FormatDate Tests
// ============================================================================

procedure Test_FormatDate_ISO8601;
var
  d: TDate;
  s: string;
begin
  WriteLn('Test_FormatDate_ISO8601:');
  d := TDate.Create(2024, 10, 25);
  s := FormatDate(d, dtfISO8601Date);
  AssertEquals('2024-10-25', s, 'ISO8601 date');
end;

procedure Test_FormatDate_Short;
var
  d: TDate;
  s: string;
begin
  WriteLn('Test_FormatDate_Short:');
  d := TDate.Create(2024, 12, 25);
  s := FormatDate(d, dtfShort);
  AssertTrue(Length(s) > 0, 'Short date produces output');
end;

procedure Test_FormatDate_CustomPattern;
var
  d: TDate;
  s: string;
begin
  WriteLn('Test_FormatDate_CustomPattern:');
  d := TDate.Create(2024, 7, 4);
  s := FormatDate(d, 'dd-mm-yyyy');
  AssertEquals('04-07-2024', s, 'Custom pattern dd-mm-yyyy');
end;

// ============================================================================
// FormatTime Tests
// ============================================================================

procedure Test_FormatTime_ISO8601;
var
  t: TTimeOfDay;
  s: string;
begin
  WriteLn('Test_FormatTime_ISO8601:');
  t := TTimeOfDay.Create(14, 30, 45);
  s := FormatTime(t, dtfISO8601Time);
  AssertContains('14:30:45', s, 'ISO8601 time');
end;

procedure Test_FormatTime_Short;
var
  t: TTimeOfDay;
  s: string;
begin
  WriteLn('Test_FormatTime_Short:');
  t := TTimeOfDay.Create(14, 30, 0);
  s := FormatTime(t, dtfShort);
  AssertTrue(Length(s) > 0, 'Short time produces output');
end;

procedure Test_FormatTime_CustomPattern;
var
  t: TTimeOfDay;
  s: string;
begin
  WriteLn('Test_FormatTime_CustomPattern:');
  t := TTimeOfDay.Create(9, 5, 30);
  s := FormatTime(t, 'hh:nn:ss');
  AssertEquals('09:05:30', s, 'Custom pattern hh:nn:ss');
end;

// ============================================================================
// FormatDuration Tests
// ============================================================================

procedure Test_FormatDuration_Compact;
var
  d: TDuration;
  s: string;
begin
  WriteLn('Test_FormatDuration_Compact:');
  d := TDuration.FromSec(3723); // 1h 2m 3s
  s := FormatDuration(d, dfCompact);
  AssertEquals('1h2m3s', s, 'Compact: 1h2m3s');
end;

procedure Test_FormatDuration_Compact_Hours;
var
  d: TDuration;
  s: string;
begin
  WriteLn('Test_FormatDuration_Compact_Hours:');
  d := TDuration.FromSec(7200); // 2h
  s := FormatDuration(d, dfCompact);
  AssertEquals('2h', s, 'Compact: 2h');
end;

procedure Test_FormatDuration_Compact_Minutes;
var
  d: TDuration;
  s: string;
begin
  WriteLn('Test_FormatDuration_Compact_Minutes:');
  d := TDuration.FromSec(1800); // 30m
  s := FormatDuration(d, dfCompact);
  AssertEquals('30m', s, 'Compact: 30m');
end;

procedure Test_FormatDuration_Compact_Seconds;
var
  d: TDuration;
  s: string;
begin
  WriteLn('Test_FormatDuration_Compact_Seconds:');
  d := TDuration.FromSec(45);
  s := FormatDuration(d, dfCompact);
  AssertEquals('45s', s, 'Compact: 45s');
end;

procedure Test_FormatDuration_Compact_Milliseconds;
var
  d: TDuration;
  s: string;
begin
  WriteLn('Test_FormatDuration_Compact_Milliseconds:');
  d := TDuration.FromMs(500);
  s := FormatDuration(d, dfCompact);
  AssertEquals('500ms', s, 'Compact: 500ms');
end;

procedure Test_FormatDuration_Compact_Zero;
var
  d: TDuration;
  s: string;
begin
  WriteLn('Test_FormatDuration_Compact_Zero:');
  d := TDuration.Zero;
  s := FormatDuration(d, dfCompact);
  AssertEquals('0s', s, 'Compact: 0s');
end;

procedure Test_FormatDuration_Verbose;
var
  d: TDuration;
  s: string;
begin
  WriteLn('Test_FormatDuration_Verbose:');
  d := TDuration.FromSec(3661); // 1h 1m 1s
  s := FormatDuration(d, dfVerbose);
  AssertContains('hour', s, 'Verbose contains hour');
  AssertContains('minute', s, 'Verbose contains minute');
end;

procedure Test_FormatDuration_Precise;
var
  d: TDuration;
  s: string;
begin
  WriteLn('Test_FormatDuration_Precise:');
  d := TDuration.FromMs(5432123); // 1:30:32.123
  s := FormatDuration(d, dfPrecise);
  AssertContains(':', s, 'Precise contains colon');
end;

procedure Test_FormatDuration_Human;
var
  d: TDuration;
  s: string;
begin
  WriteLn('Test_FormatDuration_Human:');
  d := TDuration.FromSec(7200); // 2 hours
  s := FormatDuration(d, dfHuman);
  AssertContains('about', s, 'Human contains about');
  AssertContains('hour', s, 'Human contains hour');
end;

procedure Test_FormatDuration_ISO8601;
var
  d: TDuration;
  s: string;
begin
  WriteLn('Test_FormatDuration_ISO8601:');
  d := TDuration.FromSec(3723); // 1h 2m 3s
  s := FormatDuration(d, dfISO8601);
  AssertEquals('PT1H2M3S', s, 'ISO8601: PT1H2M3S');
end;

procedure Test_FormatDuration_ISO8601_WithMs;
var
  d: TDuration;
  s: string;
begin
  WriteLn('Test_FormatDuration_ISO8601_WithMs:');
  d := TDuration.FromMs(3723500); // 1h 2m 3.5s
  s := FormatDuration(d, dfISO8601);
  AssertContains('PT', s, 'ISO8601 starts with PT');
  AssertContains('H', s, 'ISO8601 contains H');
  AssertContains('M', s, 'ISO8601 contains M');
  AssertContains('S', s, 'ISO8601 contains S');
end;

// ============================================================================
// FormatDurationHuman Convenience Functions
// ============================================================================

procedure Test_FormatDurationHuman_Nanoseconds;
var
  d: TDuration;
  s: string;
begin
  WriteLn('Test_FormatDurationHuman_Nanoseconds:');
  d := TDuration.FromNs(999);
  s := FormatDurationHuman(d);
  AssertEquals('999ns', s, 'Human: 999ns');
end;

procedure Test_FormatDurationHuman_Microseconds;
var
  d: TDuration;
  s: string;
begin
  WriteLn('Test_FormatDurationHuman_Microseconds:');
  d := TDuration.FromUs(42);
  s := FormatDurationHuman(d);
  AssertEquals('42us', s, 'Human: 42us');
end;

procedure Test_FormatDurationHuman_Milliseconds;
var
  d: TDuration;
  s: string;
begin
  WriteLn('Test_FormatDurationHuman_Milliseconds:');
  d := TDuration.FromMs(7);
  s := FormatDurationHuman(d);
  AssertEquals('7ms', s, 'Human: 7ms');
end;

procedure Test_FormatDurationHuman_Seconds;
var
  d: TDuration;
  s: string;
begin
  WriteLn('Test_FormatDurationHuman_Seconds:');
  d := TDuration.FromSec(2);
  s := FormatDurationHuman(d);
  AssertEquals('2s', s, 'Human: 2s');
end;

procedure Test_FormatDurationHuman_Abbr_Toggle;
var
  s: string;
begin
  WriteLn('Test_FormatDurationHuman_Abbr_Toggle:');
  SetDurationFormatUseAbbr(False);
  try
    s := FormatDurationHuman(TDuration.FromMs(3));
    AssertEquals('3 milliseconds', s, 'Non-abbr: 3 milliseconds');
    s := FormatDurationHuman(TDuration.FromSec(1));
    AssertEquals('1 seconds', s, 'Non-abbr: 1 seconds');
  finally
    SetDurationFormatUseAbbr(True);
  end;
end;

procedure Test_FormatDurationHuman_SecPrecision;
var
  s: string;
begin
  WriteLn('Test_FormatDurationHuman_SecPrecision:');
  SetDurationFormatSecPrecision(3);
  try
    s := FormatDurationHuman(TDuration.FromNs(1500000000)); // 1.5s
    AssertEquals('1.500s', s, 'Precision 3: 1.500s');
  finally
    SetDurationFormatSecPrecision(0);
  end;
end;

// ============================================================================
// FormatDuration Convenience Functions
// ============================================================================

procedure Test_FormatDurationCompact;
var
  d: TDuration;
  s: string;
begin
  WriteLn('Test_FormatDurationCompact:');
  d := TDuration.FromSec(90);
  s := FormatDurationCompact(d);
  AssertEquals('1m30s', s, 'Compact: 1m30s');
end;

procedure Test_FormatDurationVerbose;
var
  d: TDuration;
  s: string;
begin
  WriteLn('Test_FormatDurationVerbose:');
  d := TDuration.FromSec(3600);
  s := FormatDurationVerbose(d);
  AssertContains('hour', s, 'Verbose: contains hour');
end;

procedure Test_FormatDurationPrecise;
var
  d: TDuration;
  s: string;
begin
  WriteLn('Test_FormatDurationPrecise:');
  d := TDuration.FromMs(3723456); // 1:02:03.456
  s := FormatDurationPrecise(d);
  AssertContains(':', s, 'Precise: contains colon');
end;

procedure Test_FormatDurationISO8601;
var
  d: TDuration;
  s: string;
begin
  WriteLn('Test_FormatDurationISO8601:');
  d := TDuration.FromSec(3661);
  s := FormatDurationISO8601(d);
  AssertContains('PT', s, 'ISO8601: contains PT');
end;

// ============================================================================
// FormatRelativeTime Tests
// ============================================================================

procedure Test_FormatRelativeTime_JustNow;
var
  dt, base: TDateTime;
  s: string;
begin
  WriteLn('Test_FormatRelativeTime_JustNow:');
  base := Now;
  dt := base;
  s := FormatRelativeTime(dt, base);
  AssertEquals('just now', s, 'Just now');
end;

procedure Test_FormatRelativeTime_SecondsAgo;
var
  dt, base: TDateTime;
  s: string;
begin
  WriteLn('Test_FormatRelativeTime_SecondsAgo:');
  base := Now;
  dt := base - (30 / 86400); // 30 seconds ago
  s := FormatRelativeTime(dt, base);
  AssertContains('seconds', s, 'Contains seconds');
  AssertContains('ago', s, 'Contains ago');
end;

procedure Test_FormatRelativeTime_MinutesAgo;
var
  dt, base: TDateTime;
  s: string;
begin
  WriteLn('Test_FormatRelativeTime_MinutesAgo:');
  base := Now;
  dt := base - (5 / 1440); // 5 minutes ago
  s := FormatRelativeTime(dt, base);
  AssertContains('minutes', s, 'Contains minutes');
  AssertContains('ago', s, 'Contains ago');
end;

procedure Test_FormatRelativeTime_HoursAgo;
var
  dt, base: TDateTime;
  s: string;
begin
  WriteLn('Test_FormatRelativeTime_HoursAgo:');
  base := Now;
  dt := base - (2 / 24); // 2 hours ago
  s := FormatRelativeTime(dt, base);
  AssertContains('hours', s, 'Contains hours');
  AssertContains('ago', s, 'Contains ago');
end;

procedure Test_FormatRelativeTime_DaysAgo;
var
  dt, base: TDateTime;
  s: string;
begin
  WriteLn('Test_FormatRelativeTime_DaysAgo:');
  base := Now;
  dt := base - 3; // 3 days ago
  s := FormatRelativeTime(dt, base);
  AssertContains('days', s, 'Contains days');
  AssertContains('ago', s, 'Contains ago');
end;

procedure Test_FormatRelativeTime_Future;
var
  dt, base: TDateTime;
  s: string;
begin
  WriteLn('Test_FormatRelativeTime_Future:');
  base := Now;
  dt := base + (5 / 1440); // in 5 minutes
  s := FormatRelativeTime(dt, base);
  AssertContains('in ', s, 'Contains "in "');
end;

// ============================================================================
// TFormatOptions Tests
// ============================================================================

procedure Test_FormatOptions_Default;
var
  opts: TFormatOptions;
begin
  WriteLn('Test_FormatOptions_Default:');
  opts := TFormatOptions.Default;
  AssertTrue(not opts.UseUTC, 'Default UseUTC is False');
  AssertTrue(not opts.ShowMilliseconds, 'Default ShowMilliseconds is False');
  AssertTrue(opts.Use24Hour, 'Default Use24Hour is True');
  AssertTrue(not opts.ShowTimeZone, 'Default ShowTimeZone is False');
end;

procedure Test_FormatOptions_UTC;
var
  opts: TFormatOptions;
begin
  WriteLn('Test_FormatOptions_UTC:');
  opts := TFormatOptions.UTC;
  AssertTrue(opts.UseUTC, 'UTC UseUTC is True');
  AssertTrue(opts.ShowTimeZone, 'UTC ShowTimeZone is True');
end;

procedure Test_FormatOptions_Local;
var
  opts: TFormatOptions;
begin
  WriteLn('Test_FormatOptions_Local:');
  opts := TFormatOptions.Local;
  AssertTrue(not opts.UseUTC, 'Local UseUTC is False');
  AssertTrue(opts.ShowTimeZone, 'Local ShowTimeZone is True');
end;

procedure Test_FormatOptions_Precise;
var
  opts: TFormatOptions;
begin
  WriteLn('Test_FormatOptions_Precise:');
  opts := TFormatOptions.Precise;
  AssertTrue(opts.ShowMilliseconds, 'Precise ShowMilliseconds is True');
end;

// ============================================================================
// TDurationFormatOptions Tests
// ============================================================================

procedure Test_DurationFormatOptions_Default;
var
  opts: TDurationFormatOptions;
begin
  WriteLn('Test_DurationFormatOptions_Default:');
  opts := TDurationFormatOptions.Default;
  AssertTrue(not opts.ShowZeroUnits, 'Default ShowZeroUnits is False');
  AssertTrue(opts.UseAbbreviation, 'Default UseAbbreviation is True');
  AssertTrue(opts.MaxUnits = 3, 'Default MaxUnits is 3');
  AssertTrue(opts.Precision = 0, 'Default Precision is 0');
end;

procedure Test_DurationFormatOptions_Compact;
var
  opts: TDurationFormatOptions;
begin
  WriteLn('Test_DurationFormatOptions_Compact:');
  opts := TDurationFormatOptions.Compact;
  AssertTrue(opts.UseAbbreviation, 'Compact UseAbbreviation is True');
  AssertTrue(opts.MaxUnits = 2, 'Compact MaxUnits is 2');
end;

procedure Test_DurationFormatOptions_Verbose;
var
  opts: TDurationFormatOptions;
begin
  WriteLn('Test_DurationFormatOptions_Verbose:');
  opts := TDurationFormatOptions.Verbose;
  AssertTrue(not opts.UseAbbreviation, 'Verbose UseAbbreviation is False');
  AssertTrue(opts.MaxUnits = 3, 'Verbose MaxUnits is 3');
end;

procedure Test_DurationFormatOptions_Precise;
var
  opts: TDurationFormatOptions;
begin
  WriteLn('Test_DurationFormatOptions_Precise:');
  opts := TDurationFormatOptions.Precise;
  AssertTrue(opts.ShowZeroUnits, 'Precise ShowZeroUnits is True');
  AssertTrue(opts.Precision = 3, 'Precise Precision is 3');
end;

// ============================================================================
// Formatter Interface Tests
// ============================================================================

procedure Test_CreateTimeFormatter;
var
  f: ITimeFormatter;
begin
  WriteLn('Test_CreateTimeFormatter:');
  f := CreateTimeFormatter;
  AssertTrue(f <> nil, 'CreateTimeFormatter returns non-nil');
end;

procedure Test_CreateTimeFormatter_WithLocale;
var
  f: ITimeFormatter;
begin
  WriteLn('Test_CreateTimeFormatter_WithLocale:');
  f := CreateTimeFormatter('en-US');
  AssertTrue(f <> nil, 'CreateTimeFormatter with locale returns non-nil');
  AssertEquals('en-US', f.GetLocale, 'Locale is en-US');
end;

procedure Test_CreateDurationFormatter;
var
  f: IDurationFormatter;
begin
  WriteLn('Test_CreateDurationFormatter:');
  f := CreateDurationFormatter;
  AssertTrue(f <> nil, 'CreateDurationFormatter returns non-nil');
end;

procedure Test_CreateDurationFormatter_WithLocale;
var
  f: IDurationFormatter;
begin
  WriteLn('Test_CreateDurationFormatter_WithLocale:');
  f := CreateDurationFormatter('zh-CN');
  AssertTrue(f <> nil, 'CreateDurationFormatter with locale returns non-nil');
  AssertEquals('zh-CN', f.GetLocale, 'Locale is zh-CN');
end;

procedure Test_DefaultTimeFormatter;
var
  f: ITimeFormatter;
begin
  WriteLn('Test_DefaultTimeFormatter:');
  f := DefaultTimeFormatter;
  AssertTrue(f <> nil, 'DefaultTimeFormatter returns non-nil');
end;

procedure Test_DefaultDurationFormatter;
var
  f: IDurationFormatter;
begin
  WriteLn('Test_DefaultDurationFormatter:');
  f := DefaultDurationFormatter;
  AssertTrue(f <> nil, 'DefaultDurationFormatter returns non-nil');
end;

// ============================================================================
// Main
// ============================================================================

begin
  WriteLn;
  WriteLn('========================================');
  WriteLn('  fafafa.core.time.format Tests');
  WriteLn('========================================');
  WriteLn;
  
  // FormatDateTime tests
  Test_FormatDateTime_ISO8601;
  Test_FormatDateTime_ISO8601Date;
  Test_FormatDateTime_ISO8601Time;
  Test_FormatDateTime_Short;
  Test_FormatDateTime_Medium;
  Test_FormatDateTime_Long;
  Test_FormatDateTime_Full;
  Test_FormatDateTime_CustomPattern;
  
  // FormatDate tests
  Test_FormatDate_ISO8601;
  Test_FormatDate_Short;
  Test_FormatDate_CustomPattern;
  
  // FormatTime tests
  Test_FormatTime_ISO8601;
  Test_FormatTime_Short;
  Test_FormatTime_CustomPattern;
  
  // FormatDuration tests
  Test_FormatDuration_Compact;
  Test_FormatDuration_Compact_Hours;
  Test_FormatDuration_Compact_Minutes;
  Test_FormatDuration_Compact_Seconds;
  Test_FormatDuration_Compact_Milliseconds;
  Test_FormatDuration_Compact_Zero;
  Test_FormatDuration_Verbose;
  Test_FormatDuration_Precise;
  Test_FormatDuration_Human;
  Test_FormatDuration_ISO8601;
  Test_FormatDuration_ISO8601_WithMs;
  
  // FormatDurationHuman tests
  Test_FormatDurationHuman_Nanoseconds;
  Test_FormatDurationHuman_Microseconds;
  Test_FormatDurationHuman_Milliseconds;
  Test_FormatDurationHuman_Seconds;
  Test_FormatDurationHuman_Abbr_Toggle;
  Test_FormatDurationHuman_SecPrecision;
  
  // FormatDuration convenience functions
  Test_FormatDurationCompact;
  Test_FormatDurationVerbose;
  Test_FormatDurationPrecise;
  Test_FormatDurationISO8601;
  
  // FormatRelativeTime tests
  Test_FormatRelativeTime_JustNow;
  Test_FormatRelativeTime_SecondsAgo;
  Test_FormatRelativeTime_MinutesAgo;
  Test_FormatRelativeTime_HoursAgo;
  Test_FormatRelativeTime_DaysAgo;
  Test_FormatRelativeTime_Future;
  
  // TFormatOptions tests
  Test_FormatOptions_Default;
  Test_FormatOptions_UTC;
  Test_FormatOptions_Local;
  Test_FormatOptions_Precise;
  
  // TDurationFormatOptions tests
  Test_DurationFormatOptions_Default;
  Test_DurationFormatOptions_Compact;
  Test_DurationFormatOptions_Verbose;
  Test_DurationFormatOptions_Precise;
  
  // Formatter interface tests
  Test_CreateTimeFormatter;
  Test_CreateTimeFormatter_WithLocale;
  Test_CreateDurationFormatter;
  Test_CreateDurationFormatter_WithLocale;
  Test_DefaultTimeFormatter;
  Test_DefaultDurationFormatter;
  
  WriteLn;
  WriteLn('========================================');
  WriteLn('  Total: ', TotalTests, '  Passed: ', PassedTests, '  Failed: ', FailedTests);
  WriteLn('========================================');
  
  if FailedTests > 0 then
    Halt(1);
end.
