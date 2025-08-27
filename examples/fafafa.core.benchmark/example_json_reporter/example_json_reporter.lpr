program example_json_reporter;
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
    for i := 1 to 750 do
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
  tests[0] := benchmark('sum.to.750', @Work);

  results := benchmarks(tests);

  outPath := 'bin' + DirectorySeparator + 'results.json';
  reporter := CreateJSONReporter(outPath);
  reporter.SetFormat('schema=2;decimals=4');
  reporter.ReportResults(results);

  WriteLn('JSON written: ', outPath, ' (schema=2, decimals=4)');
end.

