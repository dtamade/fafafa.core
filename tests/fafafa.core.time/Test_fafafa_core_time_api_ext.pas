unit Test_fafafa_core_time_api_ext;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time, fafafa.core.time.consts;

type
  TTestCase_TimeApiExt = class(TTestCase)
  published
    procedure Test_Duration_Abs_Neg_Basic;
    procedure Test_Duration_TryFrom_OverflowAndOk;
    procedure Test_Instant_CheckedAddSub_Bounds;
    procedure Test_Instant_NonNegativeDiff_Since;
    procedure Test_SliceSleep_Config_GetSet;
  end;

implementation

procedure TTestCase_TimeApiExt.Test_Duration_Abs_Neg_Basic;
var d: TDuration;
begin
  d := TDuration.FromNs(-5);
  CheckEquals(5, d.Abs.AsNs);
  // Neg 饱和：Low(Int64) 取反饱和为 High(Int64)
  d := TDuration.FromNs(Low(Int64));
  CheckEquals(High(Int64), d.Neg.AsNs);
  // Abs 饱和：Low(Int64) 的绝对值饱和为 High(Int64)
  d := TDuration.FromNs(Low(Int64));
  CheckEquals(High(Int64), d.Abs.AsNs);
end;


procedure TTestCase_TimeApiExt.Test_Duration_TryFrom_OverflowAndOk;
var d: TDuration; ok: Boolean; big: Int64;
begin
  ok := TDuration.TryFromNs(42, d);
  CheckTrue(ok);
  CheckEquals(42, d.AsNs);
  ok := TDuration.TryFromUs(7, d);
  CheckTrue(ok);
  CheckEquals(7 * NANOSECONDS_PER_MICRO, d.AsNs);
  ok := TDuration.TryFromMs(123, d);
  CheckTrue(ok);
  CheckEquals(123 * NANOSECONDS_PER_MILLI, d.AsNs);
  // 构造会溢出的输入：以纳秒换算可能超界
  big := High(Int64) div NANOSECONDS_PER_SECOND + 1;
  ok := TDuration.TryFromSec(big, d);
  CheckFalse(ok);
end;

procedure TTestCase_TimeApiExt.Test_Instant_CheckedAddSub_Bounds;
var i0, i1: TInstant; d: TDuration; outI: TInstant; ok: Boolean;
begin
  i0 := TInstant.FromNsSinceEpoch(10);
  d := TDuration.FromNs(5);
  ok := i0.CheckedAdd(d, outI);
  CheckTrue(ok);
  CheckEquals(QWord(15), outI.AsNsSinceEpoch);
  ok := i0.CheckedSub(d, outI);
  CheckTrue(ok);
  CheckEquals(QWord(5), outI.AsNsSinceEpoch);
  // 下溢
  d := TDuration.FromNs(20);
  ok := i0.CheckedSub(d, outI);
  CheckFalse(ok);
  // 上溢
  i1 := TInstant.FromNsSinceEpoch(High(QWord)-3);
  d := TDuration.FromNs(10);
  ok := i1.CheckedAdd(d, outI);
  CheckFalse(ok);
end;

procedure TTestCase_TimeApiExt.Test_Instant_NonNegativeDiff_Since;
var a,b: TInstant; d: TDuration;
begin
  a := TInstant.FromNsSinceEpoch(100);
  b := TInstant.FromNsSinceEpoch(90);
  d := a.Since(b);
  CheckEquals(10, d.AsNs);
  d := b.NonNegativeDiff(a);
  CheckEquals(0, d.AsNs);
end;

procedure TTestCase_TimeApiExt.Test_SliceSleep_Config_GetSet;
var ms: Integer;
begin
  // 仅断言 setter/getter 的行为，不做实际耗时断言
  SetSliceSleepMsFor(PlatLinux, 2);
  SetSliceSleepMsFor(PlatDarwin, 3);
  ms := GetSliceSleepMsFor(PlatLinux);
  CheckEquals(2, ms);
  ms := GetSliceSleepMsFor(PlatDarwin);
  CheckEquals(3, ms);
  SetSliceSleepMs(1);
  CheckEquals(1, GetSliceSleepMsFor(PlatLinux));
  CheckEquals(1, GetSliceSleepMsFor(PlatDarwin));
end;

initialization
  RegisterTest(TTestCase_TimeApiExt);
end.

