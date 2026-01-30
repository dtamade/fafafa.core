unit Test_fafafa_core_time_duration_saturating_ops;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.time;

type
  TTestCase_DurationSaturatingOps = class(TTestCase)
  published
    procedure Test_Add_Saturating_Up_Down;
    procedure Test_From_Constructors_Saturating;
  end;

implementation

procedure TTestCase_DurationSaturatingOps.Test_Add_Saturating_Up_Down;
var a,b,c: TDuration;
begin
  a := TDuration.FromNs(High(Int64)-5);
  b := TDuration.FromNs(10);
  c := a + b;
  CheckEquals(High(Int64), c.AsNs, 'add up saturate to High(Int64)');

  a := TDuration.FromNs(Low(Int64)+5);
  b := TDuration.FromNs(-10);
  c := a + b;
  CheckEquals(Low(Int64), c.AsNs, 'add down saturate to Low(Int64)');
end;

procedure TTestCase_DurationSaturatingOps.Test_From_Constructors_Saturating;
var d: TDuration; ok: Boolean; big: Int64;
begin
  // TryFromSec overflow should fail
  big := (High(Int64) div 1000000000) + 1;
  ok := TDuration.TryFromSec(big, d);
  CheckFalse(ok);

  // FromMs saturates (use a large value that will overflow when multiplied by 1000000)
  big := (High(Int64) div 1000000) + 1;
  d := TDuration.FromMs(big);
  CheckEquals(High(Int64), d.AsNs);
end;

initialization
  RegisterTest(TTestCase_DurationSaturatingOps);
end.

