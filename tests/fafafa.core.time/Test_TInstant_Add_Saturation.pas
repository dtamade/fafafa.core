unit Test_TInstant_Add_Saturation;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time;

type
  TTestCase_InstantSaturation = class(TTestCase)
  published
    procedure Test_Add_Saturates_Upwards;
    procedure Test_Add_Saturates_Downwards;
  end;

implementation

procedure TTestCase_InstantSaturation.Test_Add_Saturates_Upwards;
var
  t0, t1: TInstant;
  huge: TDuration;
begin
  t0 := TInstant.FromNsSinceEpoch(High(QWord) - 10);
  huge := TDuration.FromNs(1000000); // 大正值
  t1 := t0.Add(huge);
  CheckEquals(QWord(High(QWord)), t1.AsNsSinceEpoch);
end;

procedure TTestCase_InstantSaturation.Test_Add_Saturates_Downwards;
var
  t0, t1: TInstant;
  neg: TDuration;
begin
  t0 := TInstant.FromNsSinceEpoch(5);
  neg := TDuration.FromNs(-1000000); // 大负值
  t1 := t0.Add(neg);
  CheckEquals(QWord(0), t1.AsNsSinceEpoch);
end;

initialization
  RegisterTest(TTestCase_InstantSaturation);
end.

