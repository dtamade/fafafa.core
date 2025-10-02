unit Test_fafafa_core_time_instant_saturation_bounds;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.time;

type
  TTestCase_InstantSaturationBounds = class(TTestCase)
  published
    procedure Test_Add_Overflow_Saturates;
    procedure Test_Sub_Underflow_Saturates;
  end;

implementation

procedure TTestCase_InstantSaturationBounds.Test_Add_Overflow_Saturates;
var i0, i1: TInstant; d: TDuration; outI: TInstant; ok: Boolean;
begin
  i0 := TInstant.FromNsSinceEpoch(High(QWord)-3);
  d := TDuration.FromNs(10);
  ok := i0.CheckedAdd(d, outI);
  CheckFalse(ok);
  i1 := i0.Add(d);
  CheckEquals(QWord(High(QWord)), i1.AsNsSinceEpoch);
end;

procedure TTestCase_InstantSaturationBounds.Test_Sub_Underflow_Saturates;
var i0, i1: TInstant; d: TDuration; ok: Boolean; outI: TInstant;
begin
  i0 := TInstant.FromNsSinceEpoch(5);
  d := TDuration.FromNs(10);
  ok := i0.CheckedSub(d, outI);
  CheckFalse(ok);
  i1 := i0.Sub(d);
  CheckEquals(QWord(0), i1.AsNsSinceEpoch);
end;

initialization
  RegisterTest(TTestCase_InstantSaturationBounds);
end.

