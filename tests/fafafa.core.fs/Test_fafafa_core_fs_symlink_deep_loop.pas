{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_symlink_deep_loop;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs, fafafa.core.fs.walk, fafafa.core.fs.tree, fafafa.core.fs.fileio, fafafa.core.fs.directory, fafafa.core.fs.options, fafafa.core.fs.path;

type
  TTestCase_SymlinkDeepLoop = class(TTestCase)
  private
    FCount: Integer;
    function Enabled: Boolean;
    function RootDir: string;
    procedure EnsureClean(const P: string);
    function VisitorCount(const APath: string; const AStat: fafafa.core.fs.TfsStat; ADepth: Integer): Boolean;
  published
    procedure Test_Symlink_DeepChain_Follow_And_MaxDepth;
    procedure Test_Symlink_SelfLoop_NoCrash;
    procedure Test_Symlink_SmallCycle_NoCrash;
    procedure Test_Symlink_ParentLoop_NoCrash;
  end;

implementation

function TTestCase_SymlinkDeepLoop.VisitorCount(const APath: string; const AStat: fafafa.core.fs.TfsStat; ADepth: Integer): Boolean;
begin
  if False and (ADepth = 0) then; // suppress unused
  if False and (AStat.Size = 0) then; // suppress unused
  Inc(FCount);
  Result := True;
end;


function TTestCase_SymlinkDeepLoop.Enabled: Boolean;
begin
  {$IFDEF WINDOWS}
  Result := GetEnvironmentVariable('FAFAFA_TEST_SYMLINK') = '1';
  {$ELSE}
  Result := GetEnvironmentVariable('FAFAFA_TEST_SYMLINK') <> '0';
  {$ENDIF}
end;

function TTestCase_SymlinkDeepLoop.RootDir: string;
begin
  Result := 'walk_symlink_cases_' + IntToStr(Random(100000));
end;

procedure TTestCase_SymlinkDeepLoop.EnsureClean(const P: string);
var
  Opts: TFsRemoveTreeOptions;
begin
  // 用 RemoveTreeEx(FollowSymlinks=False) 清理包含符号链接环的目录树，避免 DeleteDirectory(fs_stat) 跟随链接导致失败
  try
    Opts := FsDefaultRemoveTreeOptions;
    Opts.FollowSymlinks := False;
    Opts.ErrorPolicy := epContinue;
    RemoveTreeEx(P, Opts);
  except
  end;
end;

procedure TTestCase_SymlinkDeepLoop.Test_Symlink_DeepChain_Follow_And_MaxDepth;
var
  R, D1, D2, D3, L1, L2: string;
  Opt: TFsWalkOptions;
begin
  if not Enabled then Exit;

  R := RootDir;
  EnsureClean(R);
  try
    CreateDirectory(R);
    D1 := IncludeTrailingPathDelimiter(R) + 'd1';
    D2 := IncludeTrailingPathDelimiter(R) + 'd2';
    D3 := IncludeTrailingPathDelimiter(R) + 'd3';
    CreateDirectory(D1);
    CreateDirectory(D2);
    CreateDirectory(D3);

  {$IFDEF UNIX}
  L1 := IncludeTrailingPathDelimiter(D1) + 'to_d2';
  AssertEquals(0, fs_symlink('../d2', L1));
  L2 := IncludeTrailingPathDelimiter(D2) + 'to_d3';
  AssertEquals(0, fs_symlink('../d3', L2));
  {$ELSE}
  // Windows: 尽力而为；失败则跳过
  L1 := IncludeTrailingPathDelimiter(D1) + 'to_d2';
  L2 := IncludeTrailingPathDelimiter(D2) + 'to_d3';
  if (fs_symlink('../d2', L1) <> 0) or (fs_symlink('../d3', L2) <> 0) then
  begin
    EnsureClean(R); Exit;
  end;
  {$ENDIF}

  FCount := 0;
  Opt := FsDefaultWalkOptions;
  Opt.FollowSymlinks := True;
  Opt.MaxDepth := 3;
  WalkDir(R, Opt, @VisitorCount);
  AssertTrue('应能遍历到若干条目且不死循环', FCount > 0);

  finally
    EnsureClean(R);
  end;
end;

procedure TTestCase_SymlinkDeepLoop.Test_Symlink_SelfLoop_NoCrash;
var
  R, D1, L1: string;
  Opt: TFsWalkOptions;
begin
  if not Enabled then Exit;

  R := RootDir;
  EnsureClean(R);
  try
    CreateDirectory(R);
    D1 := IncludeTrailingPathDelimiter(R) + 'd1';
    CreateDirectory(D1);

  {$IFDEF UNIX}
  L1 := IncludeTrailingPathDelimiter(D1) + 'self';
  AssertEquals(0, fs_symlink('.', L1));
  {$ELSE}
  L1 := IncludeTrailingPathDelimiter(D1) + 'self';
  if fs_symlink('.', L1) <> 0 then begin EnsureClean(R); Exit; end;
  {$ENDIF}

  FCount := 0;
  Opt := FsDefaultWalkOptions;
  Opt.FollowSymlinks := True;
  Opt.MaxDepth := 4;
  WalkDir(R, Opt, @VisitorCount);
  AssertTrue('自环不应导致崩溃或无穷递归', FCount > 0);

  finally
    EnsureClean(R);
  end;
end;

procedure TTestCase_SymlinkDeepLoop.Test_Symlink_SmallCycle_NoCrash;
var
  R, D1, D2, L1, L2: string;
  Opt: TFsWalkOptions;
begin
  if not Enabled then Exit;

  R := RootDir;
  EnsureClean(R);
  try
    CreateDirectory(R);
    D1 := IncludeTrailingPathDelimiter(R) + 'd1';
    D2 := IncludeTrailingPathDelimiter(R) + 'd2';
    CreateDirectory(D1);
    CreateDirectory(D2);

  {$IFDEF UNIX}
  L1 := IncludeTrailingPathDelimiter(D1) + 'to_d2';
  AssertEquals(0, fs_symlink('../d2', L1));
  L2 := IncludeTrailingPathDelimiter(D2) + 'to_d1';
  AssertEquals(0, fs_symlink('../d1', L2));
  {$ELSE}
  L1 := IncludeTrailingPathDelimiter(D1) + 'to_d2';
  L2 := IncludeTrailingPathDelimiter(D2) + 'to_d1';
  if (fs_symlink('../d2', L1) <> 0) or (fs_symlink('../d1', L2) <> 0) then
  begin
    EnsureClean(R); Exit;
  end;
  {$ENDIF}

  FCount := 0;
  Opt := FsDefaultWalkOptions;
  Opt.FollowSymlinks := True;
  Opt.MaxDepth := 5;
  WalkDir(R, Opt, @VisitorCount);
  AssertTrue('小环不应导致崩溃或无穷递归', FCount > 0);

  finally
    EnsureClean(R);
  end;
end;


procedure TTestCase_SymlinkDeepLoop.Test_Symlink_ParentLoop_NoCrash;
var
  R, D1, D2, LUp: string;
  Opt: TFsWalkOptions;
begin
  if not Enabled then Exit;

  R := RootDir;
  EnsureClean(R);
  try
    CreateDirectory(R);
    D1 := IncludeTrailingPathDelimiter(R) + 'dir';
    D2 := IncludeTrailingPathDelimiter(D1) + 'sub';
    CreateDirectory(D1);
    CreateDirectory(D2);

  {$IFDEF UNIX}
  // 在 D1 下创建指向其父目录 R 的链接，构成父环
  LUp := IncludeTrailingPathDelimiter(D1) + 'up';
  AssertEquals(0, fs_symlink('..', LUp));
  {$ELSE}
  LUp := IncludeTrailingPathDelimiter(D1) + 'up';
  if fs_symlink('..', LUp) <> 0 then begin EnsureClean(R); Exit; end;
  {$ENDIF}

  FCount := 0;
  Opt := FsDefaultWalkOptions;
  Opt.FollowSymlinks := True;
  Opt.MaxDepth := 6;
  WalkDir(R, Opt, @VisitorCount);
  AssertTrue('父环不应导致崩溃或无穷递归', FCount > 0);

  finally
    EnsureClean(R);
  end;
end;

initialization
  RegisterTest(TTestCase_SymlinkDeepLoop);
end.

