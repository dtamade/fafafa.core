program perf_walk_bench;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, DateUtils, Classes,
  fafafa.core.fs, fafafa.core.fs.highlevel;

procedure WriteSmallFile(const P: string);
var
  F: TFsFile;
begin
  F := TFsFile.Create;
  try
    F.Open(P, fomCreate);
    F.WriteString('x');
    F.Close;
  finally
    F.Free;
  end;
end;

function NowMs: Int64;
begin
  Result := MilliSecondsBetween(Now, 0);
end;

procedure CheckOk(const Name: string; Code: Integer);
begin
  if Code < 0 then
  begin
    Writeln('ERROR in ', Name, ': ', Code);
    Halt(2);
  end;
end;

function GenerateTree(const Root: string; Depth, Fanout, FilesPerDir: Integer): Integer;
var
  d, i: Integer;
  dirPath, filePath: string;
begin
  Result := 0;
  if Depth <= 0 then Exit;
  for i := 1 to FilesPerDir do
  begin
    filePath := IncludeTrailingPathDelimiter(Root) + 'f' + IntToStr(i) + '.bin';
    WriteSmallFile(filePath);
  end;
  for d := 1 to Fanout do
  begin
    dirPath := IncludeTrailingPathDelimiter(Root) + 'd' + IntToStr(d);
    CheckOk('mkdir', fs_mkdir(dirPath, S_IRWXU));
    Inc(Result, GenerateTree(dirPath, Depth - 1, Fanout, FilesPerDir));
  end;
end;

type
  TVisitor = class
    Cnt: Integer;
    function Call(const APath: string; const AStat: TfsStat; ADepth: Integer): Boolean;
  end;

function TVisitor.Call(const APath: string; const AStat: TfsStat; ADepth: Integer): Boolean;
begin
  Inc(Cnt);
  Result := True;
end;

function WalkCount(const Root: string): Integer;
var
  V: TVisitor;
  Opt: TFsWalkOptions;
begin
  V := TVisitor.Create;
  try
    V.Cnt := 0;
    Opt := FsDefaultWalkOptions;
    Opt.FollowSymlinks := False;
    Opt.IncludeFiles := True;
    Opt.IncludeDirs := True;
    CheckOk('WalkDir', WalkDir(Root, Opt, @V.Call));
    Result := V.Cnt;
  finally
    V.Free;
  end;
end;

var
  Root, Mode: string;
  Depth, Fanout, FilesPerDir: Integer;
  t0, t1: Int64;
  Count: Integer;
begin
  // Args: [root] [mode=gen|walk] [depth] [fanout] [filesPerDir]
  if ParamCount >= 1 then Root := ParamStr(1) else Root := 'walk_bench_root';
  if ParamCount >= 2 then Mode := ParamStr(2) else Mode := 'genwalk';
  if ParamCount >= 3 then Depth := StrToIntDef(ParamStr(3), 3) else Depth := 3;
  if ParamCount >= 4 then Fanout := StrToIntDef(ParamStr(4), 4) else Fanout := 4;
  if ParamCount >= 5 then FilesPerDir := StrToIntDef(ParamStr(5), 2) else FilesPerDir := 2;

  if Mode = 'gen' then
  begin
    ForceDirectories(Root);
    GenerateTree(Root, Depth, Fanout, FilesPerDir);
    Writeln('Tree generated at ', Root);
    Halt(0);
  end
  else if (Mode = 'walk') or (Mode = 'genwalk') then
  begin
    if Mode = 'genwalk' then
    begin
      ForceDirectories(Root);
      GenerateTree(Root, Depth, Fanout, FilesPerDir);
    end;
    t0 := NowMs;
    Count := WalkCount(Root);
    t1 := NowMs;
    if t1 = t0 then t1 := t0 + 1;
    Writeln('Walk entries: ', Count, ', time: ', (t1 - t0), ' ms');

    // 写入文件 + CSV 摘要
    var
      OutDir, OutPath: string;
      TF: Text;
    begin
      OutDir := 'tests' + PathDelim + 'fafafa.core.fs' + PathDelim + 'performance-data';
      OutPath := OutDir + PathDelim + 'perf_walk_latest.txt';
      ForceDirectories(OutDir);
      AssignFile(TF, OutPath);
      Rewrite(TF);
      try
        Writeln(TF, 'Walk entries: ', Count, ', time: ', (t1 - t0), ' ms');
        Writeln(TF, 'CSV,Walk,', Root, ',', Depth, ',', Fanout, ',', FilesPerDir, ',', (t1 - t0), ',', Count);
      finally
        CloseFile(TF);
      end;
    end;

  end
  else
  begin
    Writeln('Usage: perf_walk_bench [root] [gen|walk|genwalk] [depth] [fanout] [filesPerDir]');
    Halt(1);
  end;
end.

