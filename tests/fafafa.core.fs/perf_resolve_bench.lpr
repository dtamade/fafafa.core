program perf_resolve_bench;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, DateUtils,


  fafafa.core.fs.path;

function NowMs: Int64;
begin
  Result := MilliSecondsBetween(Now, 0);
end;

procedure BenchResolve(const Root: string; Iters: Integer);
var
  i: Integer;
  t0, t1, dtFalse, dtTrue: Int64;
  p, r, s1, s2, s3, outDir, outPath: string;
  TF: Text;
begin
  p := Root;
  t0 := NowMs;
  for i := 1 to Iters do r := ResolvePathEx(p, True{follow}, False{touchDisk});
  t1 := NowMs;
  dtFalse := (t1 - t0);
  s1 := 'ResolvePathEx: TouchDisk=False, iters=' + IntToStr(Iters) + ', time=' + IntToStr(dtFalse) + ' ms, last=' + r;
  Writeln(s1);

  t0 := NowMs;
  for i := 1 to Iters do r := ResolvePathEx(p, True{follow}, True{touchDisk});
  t1 := NowMs;
  dtTrue := (t1 - t0);
  s2 := 'ResolvePathEx: TouchDisk=True,  iters=' + IntToStr(Iters) + ', time=' + IntToStr(dtTrue) + ' ms, last=' + r;
  Writeln(s2);

  // 落盘，便于在无控制台输出的环境读取
  s3 := 'CSV,ResolvePathEx,' + p + ',' + IntToStr(Iters) + ',' + IntToStr(dtFalse) + ',' + IntToStr(dtTrue);
  outDir := 'tests\fafafa.core.fs\performance-data';
  outPath := outDir + '\perf_resolve_latest.txt';
  ForceDirectories(outDir);
  AssignFile(TF, outPath);
  Rewrite(TF);
  try
    Writeln(TF, s1);
    Writeln(TF, s2);
    Writeln(TF, s3);
  finally
    CloseFile(TF);
  end;
end;

var
  Root: string;
  Iters: Integer;
begin
  if ParamCount >= 1 then Root := ParamStr(1) else Root := 'tests/fafafa.core.fs/walk_bench_root';
  if ParamCount >= 2 then Iters := StrToIntDef(ParamStr(2), 1000) else Iters := 1000;
  BenchResolve(Root, Iters);
end.

