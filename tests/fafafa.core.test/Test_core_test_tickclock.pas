unit Test_core_test_tickclock;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.test.core,
  fafafa.core.test.clock.tick,
  fafafa.core.time.tick;

type
  TTestCase_CoreTest_TickClock = class(TTestCase)
  published
    procedure Test_TickClock_Monotonic_NonDecreasing;
    procedure Test_TickClock_Internal_Default_Provider_Works;
  end;

procedure RegisterTests;

implementation

procedure TTestCase_CoreTest_TickClock.Test_TickClock_Monotonic_NonDecreasing;
var
  C: IClock;
  a, b: QWord;
begin
  C := CreateHighResClock;
  a := C.NowMonotonicMs;
  Sleep(1);
  b := C.NowMonotonicMs;
  AssertTrue('monotonic should be non-decreasing', b >= a);
end;

procedure TTestCase_CoreTest_TickClock.Test_TickClock_Internal_Default_Provider_Works;
var
  C: IClock;
begin
  C := TTickClock.Create(nil); // nil triggers CreateDefaultTick
  AssertTrue('monotonic should be non-zero', C.NowMonotonicMs > 0);
end;

procedure RegisterTests;
begin
  RegisterTest(TTestCase_CoreTest_TickClock);
end;

end.

