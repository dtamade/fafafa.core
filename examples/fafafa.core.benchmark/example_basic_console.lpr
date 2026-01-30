program example_basic_console;

{$codepage utf8}
{$mode objfpc}{$H+}
{$modeswitch anonymousfunctions}

uses
  SysUtils,
  fafafa.core.benchmark;

var
  Reporter: IBenchmarkReporter;
  Cfg: TBenchmarkConfig;
  Res: IBenchmarkResult;

function Fib(n: Integer): Integer;
begin
  if n<=1 then Exit(n);
  Result := Fib(n-1)+Fib(n-2);
end;

begin
  Reporter := CreateConsoleReporter;
  SetDefaultBenchmarkReporter(Reporter);

  Cfg := CreateDefaultBenchmarkConfig;
  Cfg.MeasureIterations := 1000;

  Res := BenchWithConfig('fib(10)',
    procedure (S: IBenchmarkState)
    begin
      while S.KeepRunning do Fib(10);
    end,
    Cfg
  );

  Reporter.ReportResult(Res);
end.

