program example_benchmarks_console;

{$codepage utf8}
{$mode objfpc}{$H+}
{$modeswitch anonymousfunctions}

uses
  SysUtils, fafafa.core.benchmark;

var
  Reporter: IBenchmarkReporter;
  Results: TBenchmarkResultArray;
  Tests: array of TQuickBenchmark;
  I: Integer;

function Work(x: Integer): Integer;
begin
  Result := x * x + 1;
end;

begin
  Reporter := CreateConsoleReporter;
  SetDefaultBenchmarkReporter(Reporter);

  SetLength(Tests, 2);
  Tests[0] := benchmark('work(10)',
    procedure(S: IBenchmarkState)
    var v: Integer;
    begin
      v := 0;
      while S.KeepRunning do v := Work(10);
    end);
  Tests[1] := benchmark('work(100)',
    procedure(S: IBenchmarkState)
    var v: Integer;
    begin
      v := 0;
      while S.KeepRunning do v := Work(100);
    end);

  Results := benchmarks(Tests);
  for I := 0 to High(Results) do
    Reporter.ReportResult(Results[I]);
end.

