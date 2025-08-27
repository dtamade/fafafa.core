program example_ultimate;
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
    for i := 1 to 300 do
      s += i;
    Blackhole(s);
  end;
end;

var
  tests: array of TQuickBenchmark;
begin
  SetLength(tests, 1);
  tests[0] := benchmark('accumulate', @Work);

  // ultimate 组合演示：内部 orchestrate，库层不直接输出
  ultimate_benchmark('终极套件', tests);
end.

