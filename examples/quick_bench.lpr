{$mode objfpc}{$H+}
{$codepage utf8}
program quick_bench;

uses
  SysUtils,
  fafafa.core.benchmark;

procedure Work(state: IBenchmarkState);
var
  i: Integer;
begin
  while state.KeepRunning do
  begin
    for i := 1 to 1000 do
      state.Blackhole(i);
  end;
end;

procedure WorkV2(state: IBenchmarkState);
var
  i: Integer;
begin
  while state.KeepRunning do
  begin
    for i := 1 to 1000 do
    begin
      state.Pause;
      // 模拟不计时的准备阶段
      state.Resume;
      state.Blackhole(i*2);
    end;
  end;
end;

var
  R: IBenchmarkResult;
  C: TBenchmarkConfig;
  ratio: Double;
begin
  R := Bench('work.v1', @Work);
  WriteLn('MeasureNs(work.v1) = ', Format('%.2f ns/op', [MeasureNs(@Work)]));

  C := CreateDefaultBenchmarkConfig;
  C.WarmupIterations := 2;
  C.MeasureIterations := 5;
  BenchWithConfig('work.v1.config', @Work, C);

  ratio := Compare('work.v1', 'work.v2', @Work, @WorkV2);
  WriteLn('speed ratio (v1/v2): ', Format('%.2fx', [ratio]));
end.

