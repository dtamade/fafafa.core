program walk_demo;
{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.fs, fafafa.core.fs.highlevel;

function PreSkipHidden(const APath: string; ABasic: TfsDirEntType; ADepth: Integer): Boolean;
var name: string;
begin
  name := ExtractFileName(APath);
  Result := (name = '') or (name[1] <> '.');
end;

function PostOnlyFiles(const APath: string; const AStat: TfsStat; ADepth: Integer): Boolean;
begin
  // only files; directories always allowed for recursion
  if (AStat.Mode and S_IFMT) = S_IFDIR then Exit(True);
  Result := True;
end;

function OnVisit(const APath: string; const AStat: TfsStat; ADepth: Integer): Boolean;
begin
  WriteLn(StringOfChar(' ', ADepth * 2), APath);
  Result := True;
end;

var
  opts: TFsWalkOptions;
  stats: TFsWalkStats;
  rc: Integer;
  root: string;
begin
  if ParamCount >= 1 then root := ParamStr(1) else root := GetCurrentDir;
  FillChar(stats, SizeOf(stats), 0);
  opts := FsDefaultWalkOptions;
  opts.PreFilter := @PreSkipHidden;
  opts.PostFilter := @PostOnlyFiles;
  opts.Stats := @stats;

  // streaming mode for low memory
  opts.UseStreaming := True;
  opts.Sort := False;

  rc := WalkDir(root, opts, @OnVisit);
  if rc <> 0 then
  begin
    WriteLn('WalkDir failed: ', rc);
    Halt(1);
  end;
  WriteLn('Dirs=', stats.DirsVisited, ' Files=', stats.FilesVisited, ' Errors=', stats.Errors);
end.

