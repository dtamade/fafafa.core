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
  // 模拟工作：简单循环，确保有可测量的操作
  for i := 1 to 1000 do
    state.Blackhole(i);
end;

procedure WorkV2(state: IBenchmarkState);
var
  i: Integer;
begin
  for i := 1 to 1000 do
  begin
    state.Pause;
    // 模拟暂停区（不计时）
    state.Resume;
    state.Blackhole(i*2);
  end;
end;

var
  R: IBenchmarkResult;
  C: TBenchmarkConfig;
  ratio: Double;
begin
  // 一行跑：默认短配置 + 控制台输出
  R := Bench('work.v1', @Work);

  // 一行测：ns/op（不输出）
  WriteLn('MeasureNs(work.v1) = ', Format('%.2f ns/op', [MeasureNs(@Work)]));

  // 指定配置运行
  C := CreateDefaultBenchmarkConfig;
  C.WarmupIterations := 2;
  C.MeasureIterations := 5;
  BenchWithConfig('work.v1.config', @Work, C);

  // 一行比：返回倍率（越小越好），并打印
  ratio := Compare('work.v1', 'work.v2', @Work, @WorkV2);
  WriteLn('speed ratio (v1/v2): ', Format('%.2fx', [ratio]));
end.

