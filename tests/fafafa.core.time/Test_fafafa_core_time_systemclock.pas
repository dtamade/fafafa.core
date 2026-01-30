unit Test_fafafa_core_time_systemclock;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  DateUtils,
  fafafa.core.time;

type
  TTestCase_SystemClock = class(TTestCase)
  published
    procedure Test_NowUnixMsNs_MonotonicityAndRange;
  end;

implementation

procedure TTestCase_SystemClock.Test_NowUnixMsNs_MonotonicityAndRange;
var ms1, ms2, ns1, ns2: Int64;
begin
  ms1 := NowUnixMs;
  ns1 := NowUnixNs;
  Sleep(10);
  ms2 := NowUnixMs;
  ns2 := NowUnixNs;
  CheckTrue(ms2 >= ms1);
  CheckTrue(ns2 >= ns1);
  // 合理范围：大于 2020-01-01
  CheckTrue(ms2 > 1577836800000);
  CheckTrue(ns2 > 1577836800000 * Int64(1000000));
end;

initialization
  RegisterTest(TTestCase_SystemClock);
end.

