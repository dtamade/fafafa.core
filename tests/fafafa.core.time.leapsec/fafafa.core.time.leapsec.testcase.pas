unit fafafa.core.time.leapsec.testcase;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.time.leapsec;

type
  TTestCase_LeapSecond = class(TTestCase)
  published
    // === 闰秒表测试 ===
    procedure Test_LeapSecondCount;
    procedure Test_IsLeapSecondMoment_2016Dec31;
    procedure Test_IsLeapSecondMoment_2015Jun30;
    procedure Test_IsLeapSecondMoment_NormalTime;
    
    // === TAI-UTC 偏移测试 ===
    procedure Test_GetTAIOffset_2017;
    procedure Test_GetTAIOffset_2000;
    procedure Test_GetTAIOffset_1980;
    
    // === UTC-SLS 涂抹测试 ===
    procedure Test_UTCSLS_BeforeSmearWindow;
    procedure Test_UTCSLS_DuringSmearWindow;
    procedure Test_UTCSLS_AtLeapSecond;
    procedure Test_UTCSLS_AfterLeapSecond;
  end;

implementation

// === 闰秒表测试 ===

procedure TTestCase_LeapSecond.Test_LeapSecondCount;
begin
  // 截至 2017-01-01，共有 27 次正闰秒
  CheckTrue(GetLeapSecondCount >= 27, 'Should have at least 27 leap seconds');
end;

procedure TTestCase_LeapSecond.Test_IsLeapSecondMoment_2016Dec31;
begin
  // 2016-12-31 23:59:60 UTC - 最近的闰秒
  // Unix 时间: 1483228800 是 2017-01-01 00:00:00 UTC
  // 闰秒发生在前一秒 (1483228799)
  CheckTrue(IsLeapSecondMoment(1483228799), '2016-12-31 23:59:59 should be leap second moment');
end;

procedure TTestCase_LeapSecond.Test_IsLeapSecondMoment_2015Jun30;
begin
  // 2015-06-30 23:59:60 UTC
  // Unix 时间: 1435708800 是 2015-07-01 00:00:00 UTC
  CheckTrue(IsLeapSecondMoment(1435708799), '2015-06-30 23:59:59 should be leap second moment');
end;

procedure TTestCase_LeapSecond.Test_IsLeapSecondMoment_NormalTime;
begin
  // 普通时刻不应该是闰秒
  CheckFalse(IsLeapSecondMoment(1500000000), 'Normal time should not be leap second');
  CheckFalse(IsLeapSecondMoment(0), 'Epoch should not be leap second');
end;

// === TAI-UTC 偏移测试 ===

procedure TTestCase_LeapSecond.Test_GetTAIOffset_2017;
begin
  // 2017年1月1日后，TAI-UTC = 37秒
  // 1483228800 = 2017-01-01 00:00:00 UTC
  CheckEquals(37, GetTAIMinusUTC(1483228800), 'TAI-UTC should be 37s after 2017-01-01');
end;

procedure TTestCase_LeapSecond.Test_GetTAIOffset_2000;
begin
  // 2000年1月1日，TAI-UTC = 32秒
  // 946684800 = 2000-01-01 00:00:00 UTC
  CheckEquals(32, GetTAIMinusUTC(946684800), 'TAI-UTC should be 32s at 2000-01-01');
end;

procedure TTestCase_LeapSecond.Test_GetTAIOffset_1980;
begin
  // 1980年1月1日，TAI-UTC = 19秒
  // 315532800 = 1980-01-01 00:00:00 UTC
  CheckEquals(19, GetTAIMinusUTC(315532800), 'TAI-UTC should be 19s at 1980-01-01');
end;

// === UTC-SLS 涂抹测试 ===

procedure TTestCase_LeapSecond.Test_UTCSLS_BeforeSmearWindow;
begin
  // 在涂抹窗口之前，SLS 时间 = UTC 时间
  // 2016-12-31 23:43:19 UTC (闰秒前 1001 秒)
  // 1483228799 - 1001 = 1483227798
  CheckEquals(1483227798, ApplyUTCSLS(1483227798), 'Before smear window: SLS = UTC');
end;

procedure TTestCase_LeapSecond.Test_UTCSLS_DuringSmearWindow;
var
  UtcTime, SlsTime: Int64;
begin
  // 在涂抹窗口中间，SLS 时间略有偏移
  // 2016-12-31 23:51:39 UTC (闰秒前 500 秒)
  UtcTime := 1483228799 - 500;
  SlsTime := ApplyUTCSLS(UtcTime);
  // 在窗口中间，偏移约 0.5 秒（取整后可能相等或差 1）
  CheckTrue(Abs(SlsTime - UtcTime) <= 1, 'During smear: SLS close to UTC');
end;

procedure TTestCase_LeapSecond.Test_UTCSLS_AtLeapSecond;
var
  SlsTime: Int64;
begin
  // 在闰秒时刻，SLS 时间平滑过渡
  // 1483228799 = 2016-12-31 23:59:59 UTC (闰秒)
  SlsTime := ApplyUTCSLS(1483228799);
  // SLS 不会出现 :60 秒，而是平滑过渡
  CheckTrue(SlsTime >= 1483228799, 'At leap second: SLS should be >= UTC');
end;

procedure TTestCase_LeapSecond.Test_UTCSLS_AfterLeapSecond;
begin
  // 闰秒后，SLS 时间 = UTC 时间
  // 1483228800 = 2017-01-01 00:00:00 UTC
  CheckEquals(1483228800, ApplyUTCSLS(1483228800), 'After leap second: SLS = UTC');
end;

initialization
  RegisterTest(TTestCase_LeapSecond);
end.
