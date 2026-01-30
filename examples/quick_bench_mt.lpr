{$mode objfpc}{$H+}
{$codepage utf8}
program quick_bench_mt;

uses
  SysUtils,
  fafafa.core.benchmark;

procedure MTWork(state: IBenchmarkState; threadIndex: Integer);
var
  i: Integer;
begin
  for i := 1 to 2000 do
    Blackhole(i + threadIndex);
end;

var
  C: TBenchmarkConfig;
  R: IBenchmarkResult;
begin
  C := CreateDefaultBenchmarkConfig;
  C.WarmupIterations := 1;
  C.MeasureIterations := 5;

  R := RunMultiThreadBenchmark('mt.work', @MTWork, 4, C);
  WriteLn(Format('mean = %.2f %s/op', [R.GetTimePerIteration(buMicroSeconds), 'μs']));
end.

