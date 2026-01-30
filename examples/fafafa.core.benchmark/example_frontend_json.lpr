program example_frontend_json;

{$codepage utf8}
{$mode objfpc}{$H+}
{$modeswitch anonymousfunctions}

uses
  SysUtils,
  fafafa.core.benchmark,
  fafafa.core.benchmark.frontend.json;

function Work(n: Integer): Integer;
begin
  Result := n*n + n;
end;

var
  FE: IJSONBenchmarkFrontend;
  Cfg: TBenchmarkConfig;
  R: IBenchmarkResult;
  OutPath: string;
begin
  // 写到可执行文件同目录，便于 CI/本地断言
  OutPath := ExtractFilePath(ParamStr(0)) + 'example_frontend.json';
  FE := CreateJSONFrontend(OutPath);
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

  // 使用 RenderMany 生成包含 benchmarks 数组的 JSON，便于 CI 断言
  if FileExists(OutPath) then DeleteFile(OutPath);
  FE.RenderMany([R]);
  WriteLn('Wrote JSON to: ', OutPath);
end.

