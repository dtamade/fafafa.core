{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_walkdir_edges;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs, fafafa.core.fs.walk, fafafa.core.fs.directory, fafafa.core.fs.options;

type
  TTestCase_WalkDir_Edges = class(TTestCase)
  published
    procedure Test_Walk_MaxDepth_Prefilter_Postfilter;
  end;

implementation

procedure EnsureClean(const P: string);
begin
  try
    DeleteDirectory(P, True);
  except
  end;
end;

procedure CreateText(const P, S: string);
var F: TextFile;
begin
  ForceDirectories(ExtractFileDir(P));
  AssignFile(F, P);
  Rewrite(F);
  Write(F, S);
  Close(F);
end;

type
  TFilters = class
  public
    function Pre(const aPath: string; aType: TfsDirEntType; aDepth: Integer): Boolean;
    function Post(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean;
  end;

function TFilters.Pre(const aPath: string; aType: TfsDirEntType; aDepth: Integer): Boolean;
begin
  if (aDepth = 1) and (ExtractFileName(aPath) = 'skipdir') then Exit(False);
  Result := True;
end;

function TFilters.Post(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean;
begin
  Result := ExtractFileExt(aPath) <> '.tmp';
end;

type
  TCounter = class
  public
    Count: Integer;
    function OnEach(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean;
  end;

function TCounter.OnEach(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean;
begin
  Inc(Count);
  Result := True;
end;

procedure TTestCase_WalkDir_Edges.Test_Walk_MaxDepth_Prefilter_Postfilter;
var
  Root: string;
  Opts: TFsWalkOptions;
  C: TCounter;
  R: Integer;
  F: TFilters;

begin
  Root := 'walk_edges_' + IntToStr(GetTickCount64);
  EnsureClean(Root);
  CreateText(IncludeTrailingPathDelimiter(Root) + 'a.txt', 'a');
  CreateText(IncludeTrailingPathDelimiter(Root) + 'b.tmp', 'b');
  ForceDirectories(IncludeTrailingPathDelimiter(Root) + 'skipdir');
  CreateText(IncludeTrailingPathDelimiter(Root) + 'skipdir' + PathDelim + 'x.txt', 'x');

  Opts := FsDefaultWalkOptions;
  Opts.IncludeFiles := True;
  Opts.IncludeDirs := False;
  Opts.MaxDepth := -1;


  C := TCounter.Create;
  try
    C.Count := 0;
    // 使用对象方法过滤器（避免旧编译器对内嵌 var 的限制）
    // 将声明上移到过程 var 段
    R := 0; // init
    F := TFilters.Create;
    try
      Opts.PreFilter := @F.Pre;
      Opts.PostFilter := @F.Post;
      R := WalkDir(Root, Opts, @C.OnEach);
      AssertTrue('walk ok', R >= 0);
      // 预期：a.txt 被计数，b.tmp 被 PostFilter 丢弃，skipdir 子树被 PreFilter 跳过
      AssertEquals('count', 1, C.Count);
    finally
      F.Free;
    end;
  finally
    C.Free;
  end;

  EnsureClean(Root);
end;

initialization
  RegisterTest(TTestCase_WalkDir_Edges);
end.

