program example_realtime;
{$APPTYPE CONSOLE}
{$MODE ObjFPC}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.benchmark;

procedure Work(aState: IBenchmarkState);
var
  i: Integer;
  s: string;
begin
  while aState.KeepRunning do
  begin
    s := '';
    for i := 1 to 100 do
      s := s + 'x';
    Blackhole(Length(s));
  end;
end;

var
  tests: array of TQuickBenchmark;
begin
  SetLength(tests, 1);
  tests[0] := benchmark('string.concat', @Work);

  // 演示实时监控基准（库层无直接输出；内部通过 Reporter 输出标准统计）
  realtime_benchmark('实时监控示例', tests);
end.

