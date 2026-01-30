unit Test_fafafa_core_time_operators;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time;

type
  TTestCase_TimeOperators = class(TTestCase)
  published
    procedure Test_Duration_CompareOps;
    procedure Test_Instant_CompareOps;
  end;

implementation

procedure TTestCase_TimeOperators.Test_Duration_CompareOps;
var a,b,c: TDuration;
begin
  a := TDuration.FromMs(1);
  b := TDuration.FromMs(1);
  c := TDuration.FromMs(2);
  CheckTrue(a = b);
  CheckFalse(a <> b);
  CheckTrue(c > a);
  CheckTrue(a < c);
  CheckTrue(a <= b);
  CheckTrue(c >= a);
end;

procedure TTestCase_TimeOperators.Test_Instant_CompareOps;
var t0,t1,t2: TInstant;
begin
  t0 := TInstant.FromNsSinceEpoch(10);
  t1 := TInstant.FromNsSinceEpoch(10);
  t2 := TInstant.FromNsSinceEpoch(12);
  CheckTrue(t0 = t1);
  CheckFalse(t0 <> t1);
  CheckTrue(t2 > t0);
  CheckTrue(t0 < t2);
  CheckTrue(t0 <= t1);
  CheckTrue(t2 >= t0);
end;

initialization
  RegisterTest(TTestCase_TimeOperators);
end.

