unit Test_core_test_clock;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.math,
  fafafa.core.test.core;

type
  TTestCase_CoreTest_Clock = class(TTestCase)
  published
    procedure Test_SystemClock_Monotonic_NonDecreasing;
    procedure Test_FixedClock_Returns_Configured_Values;
  end;

procedure RegisterTests;

implementation

procedure TTestCase_CoreTest_Clock.Test_SystemClock_Monotonic_NonDecreasing;
var
  C: IClock;
  a, b: QWord;
begin
  C := TSystemClock.Create;
  a := C.NowMonotonicMs;
  Sleep(1);
  b := C.NowMonotonicMs;
  AssertTrue('monotonic should be non-decreasing', b >= a);
end;

procedure TTestCase_CoreTest_Clock.Test_FixedClock_Returns_Configured_Values;
var
  C: TFixedClock;
  dt: TDateTime;
  ms: QWord;
begin
  dt := EncodeDate(2020,1,2) + EncodeTime(3,4,5,0);
  ms := 123456;
  C := TFixedClock.Create(dt, ms);
  AssertTrue('UTC matches', Abs(C.NowUTC - dt) < 1e-9);
  AssertTrue('mono matches', C.NowMonotonicMs = ms);
  C.SetNowUTC(dt + 1/86400);
  C.SetNowMonotonicMs(ms+1);
  AssertTrue('UTC updated', C.NowUTC > dt);
  AssertTrue('mono updated', C.NowMonotonicMs = ms+1);
end;

procedure RegisterTests;
begin
  RegisterTest(TTestCase_CoreTest_Clock);
end;

end.

