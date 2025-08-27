program example_predictive;
{$APPTYPE CONSOLE}
{$MODE ObjFPC}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.benchmark;

procedure Work(aState: IBenchmarkState);
var
  i, s: Integer;
begin
  while aState.KeepRunning do
  begin
    s := 0;
    for i := 1 to 500 do
      s += i * i;
    Blackhole(s);
  end;
end;

var
  tests: array of TQuickBenchmark;
  reporter: IBenchmarkReporter;
begin
  SetLength(tests, 1);
  tests[0] := benchmark('square.sum', @Work);

  // 预测性基准（库层不直接输出；由 Reporter 负责渲染）
  predictive_benchmark('预测示例', tests);

  // 也可显式输出标准结果
  reporter := CreateConsoleReporterAsciiOnly;
  reporter.ReportResults(benchmarks(tests));
end.

