program benchmark_fs_scan_stat;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes,
  fafafa.core.fs;

function GetArgValue(const Key, DefaultVal: string): string;
var
  i, L: Integer;
  S, K: string;
begin
  Result := DefaultVal;
  K := '--' + Key + '=';
  L := Length(K);
  for i := 1 to ParamCount do
  begin
    S := ParamStr(i);
    if (Length(S) >= L) and (Copy(S,1,L) = K) then
    begin
      Result := Copy(S, L+1, MaxInt);
      Exit;
    end;
  end;
end;

function ToUIntDef(const S: string; Def: QWord): QWord;
var v: QWord;
begin
  try
    if S = '' then Exit(Def);
    v := StrToQWord(S);
    Result := v;
  except
    Result := Def;
  end;
end;

procedure BenchScandir(const Dir: string; Runs: Integer);
var
  i: Integer;
  t0, t1: QWord;
  Entries: TStringList;
  rc: Integer;
begin
  Entries := TStringList.Create;
  try
    // warmup
    rc := fs_scandir(Dir, Entries);
    if rc < 0 then
    begin
      Writeln('scandir warmup failed rc=', rc);
      Exit;
    end;

    t0 := GetTickCount64;
    for i := 1 to Runs do
    begin
      Entries.Clear;
      rc := fs_scandir(Dir, Entries);
      if rc < 0 then
      begin
        Writeln('scandir failed rc=', rc, ' at run ', i);
        Break;
      end;
    end;
    t1 := GetTickCount64;

    if rc >= 0 then
    begin
      Writeln('[scandir] dir=', Dir);
      Writeln('  runs=', Runs, ' entries(last)=', Entries.Count);
      Writeln('  elapsed_ms=', (t1 - t0));
      if Runs > 0 then
        Writeln('  avg_ms_per_run=', FormatFloat('0.000', (t1 - t0)/Runs));
    end;
  finally
    Entries.Free;
  end;
end;

procedure BenchStat(const Dir: string; RepeatCount: Integer);
var
  Entries: TStringList;
  Stats: TfsStat;
  i, j: Integer;
  Path: string;
  t0, t1: QWord;
  rc: Integer;
begin
  Entries := TStringList.Create;
  try
    rc := fs_scandir(Dir, Entries);
    if rc < 0 then
    begin
      Writeln('prepare scandir failed rc=', rc);
      Exit;
    end;

    // warmup one pass
    for i := 0 to Entries.Count - 1 do
    begin
      Path := IncludeTrailingPathDelimiter(Dir) + Entries[i];
      if fs_stat(Path, Stats) < 0 then ;
    end;

    t0 := GetTickCount64;
    for j := 1 to RepeatCount do
    begin
      for i := 0 to Entries.Count - 1 do
      begin
        Path := IncludeTrailingPathDelimiter(Dir) + Entries[i];
        rc := fs_stat(Path, Stats);
        if rc < 0 then
        begin
          Writeln('stat failed rc=', rc, ' on ', Path);
          Break;
        end;
      end;
    end;
    t1 := GetTickCount64;

    if rc >= 0 then
    begin
      Writeln('[stat] dir=', Dir);
      Writeln('  files=', Entries.Count, ' repeats=', RepeatCount);
      Writeln('  total_calls=', Int64(Entries.Count) * RepeatCount);
      Writeln('  elapsed_ms=', (t1 - t0));
      if (Entries.Count > 0) and (RepeatCount > 0) then
        Writeln('  ns_per_call=', FormatFloat('0', ((t1 - t0) * 1e6) / (Entries.Count * RepeatCount)), ' ns');
    end;
  finally
    Entries.Free;
  end;
end;

procedure PrintUsage;
begin
  Writeln('Usage: benchmark_fs_scan_stat [--dir=PATH] [--runs=N] [--repeat=M]');
  Writeln('  --dir     directory to scan/stat (default: current directory)');
  Writeln('  --runs    number of scandir runs (default: 10)');
  Writeln('  --repeat  number of full stat passes over entries (default: 5)');
end;

var
  Dir: string;
  Runs: Integer;
  RepeatCount: Integer;
begin
  if ParamCount > 0 then
  begin
    if (ParamStr(1) = '-h') or (ParamStr(1) = '--help') then
    begin
      PrintUsage;
      Halt(0);
    end;
  end;

  Dir := GetArgValue('dir', GetCurrentDir);
  Runs := Integer(ToUIntDef(GetArgValue('runs', ''), 10));
  RepeatCount := Integer(ToUIntDef(GetArgValue('repeat', ''), 5));

  Writeln('benchmark_fs_scan_stat starting...');
  Writeln('dir=', Dir);
  Writeln('runs=', Runs, ' repeat=', RepeatCount);

  BenchScandir(Dir, Runs);
  BenchStat(Dir, RepeatCount);

  Writeln('done.');
end.

