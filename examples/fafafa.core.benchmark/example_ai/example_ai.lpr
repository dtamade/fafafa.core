program example_ai;
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
    s := 1;
    for i := 1 to 100 do
      s := (s * i) mod 1000003;
    Blackhole(s);
  end;
end;

var
  tests: array of TQuickBenchmark;
begin
  SetLength(tests, 1);
  tests[0] := benchmark('ai.work', @Work);

  // AI 组合演示（内部调用 ultimate + 其它 orchestrations），库层不直接输出
  ai_benchmark(tests);
end.

