program example_adaptive;
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
    for i := 1 to 200 do
      s += (i mod 7) * (i mod 11);
    Blackhole(s);
  end;
end;

var
  tests: array of TQuickBenchmark;
  reporter: IBenchmarkReporter;
begin
  SetLength(tests, 1);
  tests[0] := benchmark('mod.mul', @Work);

  // 自适应基准（库层不直接输出；由 Reporter 负责渲染）
  adaptive_benchmark('自适应示例', tests);

  // 再用 Reporter 输出标准结果
  reporter := CreateConsoleReporterAsciiOnly;
  reporter.ReportResults(benchmarks(tests));
end.

