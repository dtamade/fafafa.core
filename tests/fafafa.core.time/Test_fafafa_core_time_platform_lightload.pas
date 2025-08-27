unit Test_fafafa_core_time_platform_lightload;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time;

type
  TTestCase_PlatformLightLoad = class(TTestCase)
  published
    procedure Test_Balanced_vs_ULowLatency_UnderLightCPU;
  end;

implementation

function MedianOf3(const a, b, c: Int64): Int64;
var x, y, z: Int64;
begin
  x := a; y := b; z := c;
  if x > y then begin x := x xor y; y := x xor y; x := x xor y; end; // swap x,y
  if y > z then begin y := y xor z; z := y xor z; y := y xor z; end; // swap y,z
  if x > y then begin x := x xor y; y := x xor y; x := x xor y; end; // swap x,y
  Result := y; // now x<=y<=z
end;

procedure BusyWaitNs(const ns: Int64);
var t0, t1: TInstant;
begin
  t0 := NowInstant;
  repeat
    t1 := NowInstant;
  until t1.Diff(t0).AsNs >= ns;
end;

procedure TTestCase_PlatformLightLoad.Test_Balanced_vs_ULowLatency_UnderLightCPU;
var
  saved: TSleepStrategy;
  a1,a2,a3, b1,b2,b3: Int64; // ms
  dBal, dUL: Int64; // median
begin
  saved := GetSleepStrategy;
  try
    {$IFDEF LINUX}
    // Balanced 3 次
    SetSleepStrategy(Balanced);
    BusyWaitNs(2 * 1000 * 1000); // ~2ms 轻负载
    a1 := TimeIt(function: TDuration begin SleepFor(TDuration.FromMs(3)); Result := TDuration.Zero; end).AsMs;
    BusyWaitNs(2 * 1000 * 1000);
    a2 := TimeIt(function: TDuration begin SleepFor(TDuration.FromMs(3)); Result := TDuration.Zero; end).AsMs;
    BusyWaitNs(2 * 1000 * 1000);
    a3 := TimeIt(function: TDuration begin SleepFor(TDuration.FromMs(3)); Result := TDuration.Zero; end).AsMs;
    dBal := MedianOf3(a1,a2,a3);
    // UltraLowLatency 3 次
    SetSleepStrategy(UltraLowLatency);
    BusyWaitNs(2 * 1000 * 1000);
    b1 := TimeIt(function: TDuration begin SleepFor(TDuration.FromMs(3)); Result := TDuration.Zero; end).AsMs;
    BusyWaitNs(2 * 1000 * 1000);
    b2 := TimeIt(function: TDuration begin SleepFor(TDuration.FromMs(3)); Result := TDuration.Zero; end).AsMs;
    BusyWaitNs(2 * 1000 * 1000);
    b3 := TimeIt(function: TDuration begin SleepFor(TDuration.FromMs(3)); Result := TDuration.Zero; end).AsMs;
    dUL := MedianOf3(b1,b2,b3);
    // 断言
    CheckTrue(dUL <= dBal + 8, Format('UL(=%d) too slow vs Bal(=%d)', [dUL, dBal]));
    CheckTrue((dUL >= 1) and (dUL <= 60), Format('UL out of range: %d ms', [dUL]));
    {$ENDIF}

    {$IFDEF DARWIN}
    // Balanced 3 次
    SetSleepStrategy(Balanced);
    BusyWaitNs(2 * 1000 * 1000);
    a1 := TimeIt(function: TDuration begin SleepFor(TDuration.FromMs(3)); Result := TDuration.Zero; end).AsMs;
    BusyWaitNs(2 * 1000 * 1000);
    a2 := TimeIt(function: TDuration begin SleepFor(TDuration.FromMs(3)); Result := TDuration.Zero; end).AsMs;
    BusyWaitNs(2 * 1000 * 1000);
    a3 := TimeIt(function: TDuration begin SleepFor(TDuration.FromMs(3)); Result := TDuration.Zero; end).AsMs;
    dBal := MedianOf3(a1,a2,a3);
    // UltraLowLatency 3 次
    SetSleepStrategy(UltraLowLatency);
    BusyWaitNs(2 * 1000 * 1000);
    b1 := TimeIt(function: TDuration begin SleepFor(TDuration.FromMs(3)); Result := TDuration.Zero; end).AsMs;
    BusyWaitNs(2 * 1000 * 1000);
    b2 := TimeIt(function: TDuration begin SleepFor(TDuration.FromMs(3)); Result := TDuration.Zero; end).AsMs;
    BusyWaitNs(2 * 1000 * 1000);
    b3 := TimeIt(function: TDuration begin SleepFor(TDuration.FromMs(3)); Result := TDuration.Zero; end).AsMs;
    dUL := MedianOf3(b1,b2,b3);
    // 断言
    CheckTrue(dUL <= dBal + 8, Format('UL(=%d) too slow vs Bal(=%d)', [dUL, dBal]));
    CheckTrue((dUL >= 1) and (dUL <= 40), Format('UL out of range: %d ms', [dUL]));
    {$ENDIF}
  finally
    SetSleepStrategy(saved);
  end;
end;

initialization
  RegisterTest(TTestCase_PlatformLightLoad);
end.

