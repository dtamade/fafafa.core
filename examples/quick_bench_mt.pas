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
  // 模拟每个线程的工作；用 Blackhole 防止优化
  for i := 1 to 2000 do
    state.Blackhole(i + threadIndex);
end;

var
  C: TBenchmarkConfig;
  TC: TMultiThreadConfig;
  R: IBenchmarkResult;
begin
  // 自定义配置：更少迭代，快速观测
  C := CreateDefaultBenchmarkConfig;
  C.WarmupIterations := 1;
  C.MeasureIterations := 5;

  // 多线程配置：4 线程，按需统计每线程工作量（可选）
  TC := CreateMultiThreadConfig(4 {threads}, 0 {workPerThread}, True {sync});

  // 直接使用便捷函数运行多线程基准
  R := RunMultiThreadBenchmark('mt.work', @MTWork, TC.ThreadCount, C);

  // 打印每次操作平均时间（μs/op）
  WriteLn(Format('mean = %.2f %s/op', [R.GetTimePerIteration(buMicroSeconds), 'μs']));
end.

