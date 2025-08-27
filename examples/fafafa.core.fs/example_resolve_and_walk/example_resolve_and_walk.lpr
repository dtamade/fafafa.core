{$CODEPAGE UTF8}
program example_resolve_and_walk;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.fs, fafafa.core.fs.highlevel, fafafa.core.fs.path;

procedure DemoResolve;
var P, A, B: string;
begin
  Writeln('--- ResolvePathEx demo ---');
  P := 'example.tmp';
  A := ResolvePathEx(P, True, False);
  B := ResolvePathEx(P, True, True);
  Writeln('Input  : ', P);
  Writeln('Abs    : ', A);
  Writeln('Real   : ', B);
end;

type
  TWalker = class
  public
    function Pre(const aPath: string; aBasic: TfsDirEntType; aDepth: Integer): Boolean;
    function Post(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean;
    function Visit(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean;
  end;

function TWalker.Pre(const aPath: string; aBasic: TfsDirEntType; aDepth: Integer): Boolean;
begin
  Result := (ExtractFileName(aPath) = '') or (ExtractFileName(aPath)[1] <> '.');
end;

function TWalker.Post(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean;
begin
  if (aStat.Mode and S_IFMT) = S_IFDIR then Exit(True);
  Result := aStat.Size > 0;
end;

function TWalker.Visit(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean;
begin
  Writeln(Format('%d: %s', [aDepth, aPath]));
  Result := True;
end;

procedure DemoWalk;
var Opts: TFsWalkOptions;
    Walker: TWalker;
begin
  Writeln('--- WalkDir demo ---');
  Opts := FsDefaultWalkOptions;
  Walker := TWalker.Create;
  try
    Opts.PreFilter := @Walker.Pre;
    Opts.PostFilter := @Walker.Post;
    WalkDir('.', Opts, @Walker.Visit);
  finally
    Walker.Free;
  end;
end;

begin
  try
    DemoResolve;
    DemoWalk;
  except
    on E: Exception do
      Writeln('Error: ', E.Message);
  end;
end.

