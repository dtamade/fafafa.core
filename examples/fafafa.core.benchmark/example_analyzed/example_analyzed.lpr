program example_analyzed;
{$APPTYPE CONSOLE}
{$MODE ObjFPC}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.benchmark;

procedure SumUp(aState: IBenchmarkState);
var
  i, s: Integer;
begin
  while aState.KeepRunning do
  begin
    s := 0;
    for i := 1 to 1000 do
      s += i;
    Blackhole(s);
  end;
end;

var
  tests: array of TQuickBenchmark;
  reporter: IBenchmarkReporter;
begin
  SetLength(tests, 1);
  tests[0] := benchmark('sum.1..1000', @SumUp);

  // 运行带分析的基准（库层不打印，由 Reporter 输出）
  analyzed_benchmark('分析示例', tests);

  // 也可直接用 Reporter 输出标准结果：
  reporter := CreateConsoleReporterAsciiOnly;
  reporter.ReportResults(benchmarks(tests));
end.

