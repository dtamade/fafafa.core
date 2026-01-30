program example_frontend_console;

{$codepage utf8}
{$mode objfpc}{$H+}
{$modeswitch anonymousfunctions}

uses
  SysUtils,
  fafafa.core.benchmark,
  fafafa.core.benchmark.frontend;

function Work(n: Integer): Integer;
begin
  Result := n*n + n;
end;

var
  FE: IBenchmarkFrontend;
  Cfg: TBenchmarkConfig;
  R: IBenchmarkResult;

begin
  FE := CreateConsoleFrontend;
  Cfg := CreateDefaultBenchmarkConfig;
  Cfg.WarmupIterations := 1;
  Cfg.MeasureIterations := 5;

  R := FE.RunOne('work(123)',
    procedure (S: IBenchmarkState)
    begin
      while S.KeepRunning do Work(123);
    end,
    Cfg
  );

  FE.RenderOne(R);
end.

