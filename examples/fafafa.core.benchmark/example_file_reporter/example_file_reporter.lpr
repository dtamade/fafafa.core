program example_file_reporter;
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
    for i := 1 to 1000 do
      s += i;
    Blackhole(s);
  end;
end;

var
  tests: array of TQuickBenchmark;
  reporter: IBenchmarkReporter;
  results: TBenchmarkResultArray;
  outPath: string;
begin
  SetLength(tests, 1);
  tests[0] := benchmark('sum.to.1000', @Work);

  // 运行测试但不立即输出
  results := benchmarks(tests);

  // 写入文件（相对于当前示例的 bin 目录）
  outPath := 'bin' + DirectorySeparator + 'results.txt';
  reporter := CreateFileReporter(outPath);
  reporter.ReportResults(results);

  // 控制台提示文件位置（示例层输出可接受）
  WriteLn('Results written to: ', outPath);
end.

