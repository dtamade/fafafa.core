program fafafa_core_simd_darwin_link_smoke;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch,
  fafafa.core.time.cpu,
  fafafa.core.time.tick,
  fafafa.core.time.stopwatch;

var
  LBackend: TSimdBackend;
  LTick: ITick;
  LStopwatch: TStopwatch;
begin
  SchedYield;
  NanoSleep(1);
  LTick := MakeBestTick;
  LBackend := GetActiveBackend;
  if (LBackend = sbScalar) and (LTick.Resolution = 0) then
    Halt(1);
  LStopwatch := TStopwatch.StartNew;
  LStopwatch.Stop;
end.
