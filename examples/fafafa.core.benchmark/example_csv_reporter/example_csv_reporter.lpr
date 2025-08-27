program example_csv_reporter;
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
      s += i * (i and 1);
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
  tests[0] := benchmark('mix.sum', @Work);

  results := benchmarks(tests);

  outPath := 'bin' + DirectorySeparator + 'results.csv';
  reporter := CreateCSVReporter(outPath);
  reporter.SetFormat('schema=2;decimals=3;sep=;schema_in_column=true');
  reporter.ReportResults(results);

  WriteLn('CSV written: ', outPath, ' (schema=2, decimals=3, sep=;)');
end.

