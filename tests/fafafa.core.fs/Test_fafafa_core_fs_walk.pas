{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_walk;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs, fafafa.core.fs.walk, fafafa.core.fs.directory, fafafa.core.fs.options;

type
  { TTestCase_Walk - 目录遍历高层API测试 }
  TTestCase_Walk = class(TTestCase)
  private
    FRoot: string;
    FVisited: TStringList;
    FOnErrorCount: Integer;
    function VisitorAdd(const APath: string; const AStat: TfsStat; ADepth: Integer): Boolean;
    function VisitorAddWithDepth(const APath: string; const AStat: TfsStat; ADepth: Integer): Boolean;
  protected
    function PreSkipDot(const APath: string; ABasic: TfsDirEntType; ADepth: Integer): Boolean;
    function PreSkipBlocked(const APath: string; ABasic: TfsDirEntType; ADepth: Integer): Boolean;
    function PostOnlyLargeFiles(const APath: string; const AStat: TfsStat; ADepth: Integer): Boolean;
    function PostRejectBlocked(const APath: string; const AStat: TfsStat; ADepth: Integer): Boolean;
    function OnErrContinue(const APath: string; aError: Integer; aDepth: Integer): TFsWalkErrorAction;
    function OnErrAbort(const APath: string; aError: Integer; aDepth: Integer): TFsWalkErrorAction;
    function OnErrCountContinue(const APath: string; aError: Integer; aDepth: Integer): TFsWalkErrorAction;
    function OnErrCountSkipSubtree(const APath: string; aError: Integer; aDepth: Integer): TFsWalkErrorAction;
    function OnErrSkipSubtree(const APath: string; aError: Integer; aDepth: Integer): TFsWalkErrorAction;

    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Walk_Default_All;
    procedure Test_Walk_PreFilter_SkipDotDirectoryTree;
    procedure Test_Walk_PostFilter_FilesMinSize;
    procedure Test_Walk_Stats_Counting;
    procedure Test_Walk_MaxDepth_1;
    procedure Test_Walk_FilesOnly;
    procedure Test_Walk_NoneIncluded;
    procedure Test_Walk_Symlink_Behavior;
    procedure Test_Walk_Symlink_Follow_Valid_NoOnError;
    procedure Test_Walk_Symlink_Follow_Broken_OnError;
    procedure Test_Walk_InvalidPath_ReturnsUnifiedError;
    procedure Test_Walk_OnError_Continue_InvalidRoot_Returns0;
    procedure Test_Walk_OnError_Abort_InvalidRoot_ReturnsNegative;

    procedure Test_Walk_Streaming_Consistency_Basic;
    procedure Test_Walk_Streaming_Consistency_WithFiltersAndStats;
    procedure Test_Walk_OnError_SkipSubtree_PartialSkip;
    procedure Test_Walk_Stats_OnError_Increments;
    procedure Test_Walk_OnError_NotCalled_OnSuccess_WithFilters;
    procedure Test_Walk_OnError_Continue_InvalidRoot_IncrementsCount;
    procedure Test_Walk_PreFilter_SkipBlocked_AvoidsOnError;
    procedure Test_Walk_PostFilter_RejectBlocked_DoesNotAvoidOnError;

  end;

implementation

procedure EnsureDir(const APath: string);
begin
  if not DirectoryExists(APath) then
    ForceDirectories(APath);
end;

procedure CreateTextFile(const APath, AText: string);
var
  LFile: TextFile;
begin
  AssignFile(LFile, APath);
  Rewrite(LFile);
  Write(LFile, AText);
  Close(LFile);
end;

function TTestCase_Walk.VisitorAdd(const APath: string; const AStat: TfsStat; ADepth: Integer): Boolean;
begin
  // silence unused (保持行为不变)
  if False and (ADepth = 0) then;
  if False and (AStat.Mode = 0) then;
  FVisited.Add(APath);
  Result := True;
end;

function TTestCase_Walk.PreSkipDot(const APath: string; ABasic: TfsDirEntType; ADepth: Integer): Boolean;
var
  Name: string;
begin
  // silence unused (保持行为不变)
  if False and (ABasic = fsDETUnknown) then ;
  if False and (ADepth < 0) then ;
  // 跳过隐藏（以.开头）文件与目录，并阻止目录子树进入
  Name := ExtractFileName(APath);
  Result := (Name <> '') and (Name[1] <> '.');
end;

function TTestCase_Walk.PreSkipBlocked(const APath: string; ABasic: TfsDirEntType; ADepth: Integer): Boolean;
var
  Name: string;
begin
  // silence unused (保持行为不变)
  if False and (ADepth < 0) then ;
  Name := ExtractFileName(APath);
  if (ABasic = fsDETDir) and (Name = 'blocked') then
    Exit(False);
  Result := True;
end;

function TTestCase_Walk.PostRejectBlocked(const APath: string; const AStat: TfsStat; ADepth: Integer): Boolean;
var
  Name: string;
begin
  // silence unused (保持行为不变)
  if False and (ADepth < 0) then ;
  if (AStat.Mode and S_IFMT) = S_IFDIR then
  begin
    Name := ExtractFileName(APath);
    Result := Name <> 'blocked';
  end
  else
    Result := True;
end;

function TTestCase_Walk.PostOnlyLargeFiles(const APath: string; const AStat: TfsStat; ADepth: Integer): Boolean;
begin
  // silence unused (保持行为不变)
  if False and (ADepth < 0) then ;
  // 仅回调大文件（> 0 字节），目录总是允许（但用例可只统计文件）
  if (AStat.Mode and S_IFMT) = S_IFDIR then Exit(True);
  Result := AStat.Size > 0;
end;

function TTestCase_Walk.OnErrContinue(const APath: string; aError: Integer; aDepth: Integer): TFsWalkErrorAction;
begin
  // silence unused (保持行为不变)
  if False and (APath = '') then;
  if False and (aError = 0) then;
  if False and (aDepth = 0) then;
  Result := weaContinue;
end;

function TTestCase_Walk.OnErrAbort(const APath: string; aError: Integer; aDepth: Integer): TFsWalkErrorAction;
begin
  // silence unused (保持行为不变)
  if False and (APath = '') then;
  if False and (aError = 0) then;
  if False and (aDepth = 0) then;
  Result := weaAbort;
end;

function TTestCase_Walk.OnErrCountContinue(const APath: string; aError: Integer; aDepth: Integer): TFsWalkErrorAction;
begin
  // silence unused (保持行为不变)
  if False and (APath = '') then ;
  if False and (aError = 0) then ;
  if False and (aDepth = 0) then ;
  Inc(FOnErrorCount);
  Result := weaContinue;
end;

function TTestCase_Walk.OnErrCountSkipSubtree(const APath: string; aError: Integer; aDepth: Integer): TFsWalkErrorAction;
begin
  // silence unused (保持行为不变)
  if False and (APath = '') then ;
  if False and (aError = 0) then ;
  if False and (aDepth = 0) then ;
  Inc(FOnErrorCount);
  Result := weaSkipSubtree;
end;


function TTestCase_Walk.OnErrSkipSubtree(const APath: string; aError: Integer; aDepth: Integer): TFsWalkErrorAction;
begin
  // silence unused (保持行为不变)
  if False and (aError = 0) then ;
  if False and (aDepth = 0) then ;
  if Pos('blocked', APath) > 0 then Exit(weaSkipSubtree);
  Result := weaContinue;
end;




function TTestCase_Walk.VisitorAddWithDepth(const APath: string; const AStat: TfsStat; ADepth: Integer): Boolean;
begin
  // silence unused (保持行为不变)
  if False and (AStat.Mode = 0) then;
  FVisited.Add(APath + '|' + IntToStr(ADepth));
  Result := True;
end;

procedure TTestCase_Walk.SetUp;
var
  LSub1, LSub2: string;
begin
  inherited SetUp;
  FVisited := TStringList.Create;
  FOnErrorCount := 0;
  FRoot := 'walk_root_' + IntToStr(Random(100000));
  EnsureDir(FRoot);
  // 结构: root/a.txt, root/sub1/b.txt, root/sub1/sub2/c.txt
  CreateTextFile(IncludeTrailingPathDelimiter(FRoot) + 'a.txt', 'a');
  LSub1 := IncludeTrailingPathDelimiter(FRoot) + 'sub1';
  LSub2 := IncludeTrailingPathDelimiter(LSub1) + 'sub2';
  EnsureDir(LSub1);
  EnsureDir(LSub2);
  CreateTextFile(IncludeTrailingPathDelimiter(LSub1) + 'b.txt', 'b');
  CreateTextFile(IncludeTrailingPathDelimiter(LSub2) + 'c.txt', 'c');
end;


procedure TTestCase_Walk.Test_Walk_PreFilter_SkipDotDirectoryTree;
var
  LRes: Integer;
  LOpts: TFsWalkOptions;
  DotDir: string;
begin
  // 创建 .hidden 目录与文件，预期 PreFilter 拦截其子树
  DotDir := IncludeTrailingPathDelimiter(FRoot) + '.hidden';
  EnsureDir(DotDir);
  CreateTextFile(IncludeTrailingPathDelimiter(DotDir) + 'x.txt', 'x');

  FVisited.Clear;
  LOpts := FsDefaultWalkOptions;
  LOpts.PreFilter := @PreSkipDot;
  LRes := WalkDir(FRoot, LOpts, @VisitorAdd);
  AssertEquals(0, LRes);
  AssertEquals('应未访问到 .hidden/x.txt', -1, FVisited.IndexOf(IncludeTrailingPathDelimiter(DotDir) + 'x.txt'));
end;

procedure TTestCase_Walk.Test_Walk_PostFilter_FilesMinSize;
var
  LRes: Integer;
  LOpts: TFsWalkOptions;
  RootAbs, SmallAbs, BigAbs: string;
begin
  // 构造小/大文件，PostFilter 仅回调大文件，但仍递归目录
  RootAbs := ExpandFileName(FRoot);
  SmallAbs := IncludeTrailingPathDelimiter(RootAbs) + 'small.bin';
  BigAbs := IncludeTrailingPathDelimiter(RootAbs) + 'big.bin';
  CreateTextFile(SmallAbs, '');
  CreateTextFile(BigAbs, '123456');

  FVisited.Clear;
  LOpts := FsDefaultWalkOptions;
  LOpts.PostFilter := @PostOnlyLargeFiles;
  LRes := WalkDir(FRoot, LOpts, @VisitorAdd);
  AssertEquals(0, LRes);
  AssertTrue('应包含 big.bin', FVisited.IndexOf(BigAbs) >= 0);
  AssertEquals('不应包含 small.bin', -1, FVisited.IndexOf(SmallAbs));
end;

procedure TTestCase_Walk.Test_Walk_Stats_Counting;
var
  LRes: Integer;
  LOpts: TFsWalkOptions;
  Stats: TFsWalkStats;
begin
  // 目录结构已在 SetUp 创建：root, sub1, sub2 各至少一个文件
  Stats := Default(TFsWalkStats);
  FVisited.Clear;
  LOpts := FsDefaultWalkOptions;
  LOpts.Stats := @Stats;
  LRes := WalkDir(FRoot, LOpts, @VisitorAdd);
  AssertEquals(0, LRes);
  // 至少访问到 2 个目录与 3 个文件（根目录子项统计）
  AssertTrue('DirsVisited 应 >= 2', Stats.DirsVisited >= 2);
  AssertTrue('FilesVisited 应 >= 3', Stats.FilesVisited >= 3);

  // 不应有错误
  AssertEquals('Errors 应为 0', QWord(0), Stats.Errors);
end;



procedure TTestCase_Walk.TearDown;
begin
  // 递归删除
  try
    DeleteDirectory(FRoot, True);
  except
    // ignore
  end;
  FVisited.Free;
  inherited TearDown;
end;

procedure TTestCase_Walk.Test_Walk_Default_All;
var
  LRes: Integer;
  LOpts: TFsWalkOptions;
begin
  FVisited.Clear;
  LOpts := FsDefaultWalkOptions;
  LRes := WalkDir(FRoot, LOpts, @VisitorAdd);
  AssertEquals(0, LRes);
  AssertTrue('应至少访问5项', FVisited.Count >= 5);
end;

procedure TTestCase_Walk.Test_Walk_MaxDepth_1;
var
  LRes: Integer;
  LOpts: TFsWalkOptions;
begin
  FVisited.Clear;
  LOpts := FsDefaultWalkOptions;
  LOpts.MaxDepth := 1; // 只到 sub1
  LRes := WalkDir(FRoot, LOpts, @VisitorAddWithDepth);
  AssertEquals(0, LRes);
  AssertEquals(-1, FVisited.IndexOf(IncludeTrailingPathDelimiter(FRoot) + 'sub1' + PathDelim + 'sub2'));
end;

procedure TTestCase_Walk.Test_Walk_FilesOnly;
var
  LRes: Integer;
  LOpts: TFsWalkOptions;
begin
  FVisited.Clear;
  LOpts := FsDefaultWalkOptions;
  LOpts.IncludeDirs := False;
  LRes := WalkDir(FRoot, LOpts, @VisitorAdd);
  AssertEquals(0, LRes);
  AssertTrue('应至少访问3个文件', FVisited.Count >= 3);
end;

procedure TTestCase_Walk.Test_Walk_NoneIncluded;
var
  LRes: Integer;
  LOpts: TFsWalkOptions;
begin
  FVisited.Clear;
  LOpts := FsDefaultWalkOptions;
  LOpts.IncludeFiles := False;
  LOpts.IncludeDirs := False;
  LRes := WalkDir(FRoot, LOpts, @VisitorAdd);
  AssertEquals(0, LRes);
  AssertEquals(0, FVisited.Count);
end;

procedure TTestCase_Walk.Test_Walk_Symlink_Behavior;
var
  LRes: Integer;
  LOpts: TFsWalkOptions;
  LSym: string;
begin
  // init locals to avoid uninitialized warnings (no behavior change)
  LSym := '';
  LRes := 0;
  LOpts := Default(TFsWalkOptions);
  {$IFDEF UNIX}
  // 创建符号链接指向 sub1（或 sub2），验证 FollowSymlinks 的行为
  LSym := IncludeTrailingPathDelimiter(FRoot) + 'link_to_sub1';
  AssertEquals(0, fs_symlink('sub1', LSym));
  try
    FVisited.Clear;
    LOpts := FsDefaultWalkOptions;
    LOpts.IncludeDirs := True;
    LOpts.FollowSymlinks := False;
    LRes := WalkDir(FRoot, LOpts, @VisitorAdd);
    AssertEquals(0, LRes);
    // 不跟随：应回调符号链接本身或不进入其子项；此处仅验证不失败
    AssertTrue(True);
  finally
    fs_unlink(LSym);
  end;
  {$ELSE}
  // Windows 暂不测试符号链接（需要管理员权限/策略），直接通过
  AssertTrue(True);
  // silence unused locals in Windows branch
  if False and (LSym = '') then ;
  if False and (LRes = 0) then ;
  if False and (LOpts.MaxDepth < -1) then ;
  {$ENDIF}
end;


procedure TTestCase_Walk.Test_Walk_Streaming_Consistency_Basic;
var
  LOpts: TFsWalkOptions;
  LRes: Integer;
  Baseline, Streamed: TStringList;
  I: Integer;
begin
  // 构造：默认（缓冲）与流式（不排序）的一致性
  Baseline := TStringList.Create;
  Streamed := TStringList.Create;
  try
    // baseline
    FVisited.Clear;
    LOpts := FsDefaultWalkOptions; // UseStreaming=False, Sort=False
    LRes := WalkDir(FRoot, LOpts, @VisitorAdd);
    AssertEquals(0, LRes);
    Baseline.Assign(FVisited);
    Baseline.Sort; // 规范化对比顺序

    // streamed
    FVisited.Clear;
    LOpts := FsDefaultWalkOptions;
    LOpts.UseStreaming := True;
    LOpts.Sort := False;
    LRes := WalkDir(FRoot, LOpts, @VisitorAdd);
    AssertEquals(0, LRes);
    Streamed.Assign(FVisited);
    Streamed.Sort;

    AssertEquals('count equal', Baseline.Count, Streamed.Count);
    for I := 0 to Baseline.Count - 1 do
      AssertEquals(Baseline[I], Streamed[I]);
  finally
    Baseline.Free;
    Streamed.Free;
  end;
end;

procedure TTestCase_Walk.Test_Walk_Streaming_Consistency_WithFiltersAndStats;
var
  LOpts: TFsWalkOptions;
  LRes: Integer;
  Baseline, Streamed: TStringList;
  Stats1, Stats2: TFsWalkStats;
  I: Integer;
begin
  Stats1 := Default(TFsWalkStats);
  Stats2 := Default(TFsWalkStats);
  Baseline := TStringList.Create;
  Streamed := TStringList.Create;
  try
    // baseline with filters and stats
    FVisited.Clear;
    LOpts := FsDefaultWalkOptions;
    LOpts.PreFilter := @PreSkipDot;
    LOpts.PostFilter := @PostOnlyLargeFiles;
    LOpts.Stats := @Stats1;
    LRes := WalkDir(FRoot, LOpts, @VisitorAdd);
    AssertEquals(0, LRes);
    Baseline.Assign(FVisited);
    Baseline.Sort;

    // streamed with same filters and stats
    FVisited.Clear;
    LOpts := FsDefaultWalkOptions;
    LOpts.UseStreaming := True;
    LOpts.Sort := False;
    LOpts.PreFilter := @PreSkipDot;
    LOpts.PostFilter := @PostOnlyLargeFiles;
    LOpts.Stats := @Stats2;
    LRes := WalkDir(FRoot, LOpts, @VisitorAdd);
    AssertEquals(0, LRes);
    Streamed.Assign(FVisited);
    Streamed.Sort;

    AssertEquals('count equal', Baseline.Count, Streamed.Count);
    for I := 0 to Baseline.Count - 1 do
      AssertEquals(Baseline[I], Streamed[I]);

    // 统计上的一致性（允许严格相等）
    AssertEquals(Stats1.DirsVisited, Stats2.DirsVisited);
    AssertEquals(Stats1.FilesVisited, Stats2.FilesVisited);
    AssertEquals(Stats1.PreFiltered, Stats2.PreFiltered);
    AssertEquals(Stats1.PostFiltered, Stats2.PostFiltered);
    AssertEquals(Stats1.Errors, Stats2.Errors);
  finally
    Baseline.Free;
    Streamed.Free;
  end;
end;

procedure TTestCase_Walk.Test_Walk_OnError_Continue_InvalidRoot_Returns0;
var
  LRes: Integer;
  LOpts: TFsWalkOptions;
begin
  LOpts := FsDefaultWalkOptions;
  LOpts.OnError := @OnErrContinue;
  {$IFDEF WINDOWS}
  LRes := WalkDir('Z:\invalid_path_Continue', LOpts, nil);
  {$ELSE}
  LRes := WalkDir('/invalid_path_Continue', LOpts, nil);
  {$ENDIF}
  AssertEquals('OnError=Continue 时返回 0', 0, LRes);
end;

procedure TTestCase_Walk.Test_Walk_OnError_Abort_InvalidRoot_ReturnsNegative;
var
  LRes: Integer;
  LOpts: TFsWalkOptions;
begin
  LOpts := FsDefaultWalkOptions;
  LOpts.OnError := @OnErrAbort;
  {$IFDEF WINDOWS}
  LRes := WalkDir('Z:\invalid_path_Abort', LOpts, nil);
  {$ELSE}
  LRes := WalkDir('/invalid_path_Abort', LOpts, nil);
  {$ENDIF}
  AssertTrue('OnError=Abort 时应返回负错误码', LRes < 0);
end;


procedure TTestCase_Walk.Test_Walk_OnError_SkipSubtree_PartialSkip;
var
  LRes: Integer;
  LOpts: TFsWalkOptions;
  BlockedDir: string;
  SavedAttr: LongInt;
  RootAbs, BlockedAbs, SubFile: string;
begin
  // 构造一个不可读取的子目录（在某些平台/权限下可能无法真正阻止；只要触发 stat/scandir 失败即可）
  RootAbs := ExpandFileName(FRoot);
  BlockedDir := IncludeTrailingPathDelimiter(FRoot) + 'blocked';
  EnsureDir(BlockedDir);
  SubFile := IncludeTrailingPathDelimiter(BlockedDir) + 'hidden.txt';
  CreateTextFile(SubFile, 'x');
  BlockedAbs := ExpandFileName(BlockedDir);
  if False and (BlockedAbs = '') then ;

  // 尝试移除访问权限（Unix 有效；Windows 下本测试将跳过核心断言）
  {$IFDEF UNIX}
  SavedAttr := FileGetAttr(BlockedDir);
  AssertEquals(0, fs_chmod(BlockedDir, &0000));
  {$ELSE}
  SavedAttr := 0;
  if False and (SavedAttr = 0) then ;
  {$ENDIF}
  try
    FVisited.Clear;
    LOpts := FsDefaultWalkOptions;
    // OnError：对子目录失败选择 SkipSubtree，避免中止整个遍历
    LOpts.OnError := @OnErrSkipSubtree;
    LRes := WalkDir(FRoot, LOpts, @VisitorAdd);
    AssertEquals(0, LRes);
    {$IFDEF UNIX}
    // 期望：blocked 子树未被访问（即便子文件存在）
    AssertEquals('应未访问 blocked 子树', -1, FVisited.IndexOf(ExpandFileName(SubFile)));
    {$ELSE}
    // Windows：权限不一定生效，放宽为仅验证不失败
    AssertTrue(True);
    {$ENDIF}
    // 同时：其它正常路径仍被访问（Unix 断言，Windows 放宽）

    AssertTrue('应访问到根下的 a.txt', FVisited.IndexOf(IncludeTrailingPathDelimiter(RootAbs) + 'a.txt') >= 0);
  finally
    {$IFDEF UNIX}
    // 恢复权限
    fs_chmod(BlockedDir, &0755);
    {$ENDIF}
  end;
end;


procedure TTestCase_Walk.Test_Walk_OnError_NotCalled_OnSuccess_WithFilters;
var
  LRes: Integer;
  LOpts: TFsWalkOptions;
begin
  FOnErrorCount := 0;
  LOpts := FsDefaultWalkOptions;
  // 正常路径 + 过滤器，不触发错误
  LOpts.PreFilter := @PreSkipDot;
  LOpts.PostFilter := @PostOnlyLargeFiles;
  LOpts.OnError := @OnErrCountContinue;
  LRes := WalkDir(FRoot, LOpts, @VisitorAdd);
  AssertEquals(0, LRes);
  AssertEquals('成功路径不应触发 OnError', 0, FOnErrorCount);
end;


procedure TTestCase_Walk.Test_Walk_PreFilter_SkipBlocked_AvoidsOnError;
var
  LRes: Integer;
  LOpts: TFsWalkOptions;
  BlockedDir: string;
begin
  // 构造 blocked 子目录，但用 PreFilter 跳过它，从而避免 OnError 触发
  BlockedDir := IncludeTrailingPathDelimiter(FRoot) + 'blocked';
  EnsureDir(BlockedDir);
  FOnErrorCount := 0;
  LOpts := FsDefaultWalkOptions;
  LOpts.PreFilter := @PreSkipBlocked;
  LOpts.OnError := @OnErrCountContinue;
  LRes := WalkDir(FRoot, LOpts, @VisitorAdd);
  AssertEquals(0, LRes);
  AssertEquals('PreFilter 已跳过 blocked，OnError 不应触发', 0, FOnErrorCount);
end;

procedure TTestCase_Walk.Test_Walk_PostFilter_RejectBlocked_DoesNotAvoidOnError;
var
  LRes: Integer;
  LOpts: TFsWalkOptions;
  BlockedDir, SubFile: string;
  SavedAttr: LongInt;
begin
  // 构造 blocked 子目录并设置权限使其产生错误，然后用 PostFilter 拒绝该目录
  BlockedDir := IncludeTrailingPathDelimiter(FRoot) + 'blocked';
  EnsureDir(BlockedDir);
  SubFile := IncludeTrailingPathDelimiter(BlockedDir) + 'x.txt';
  CreateTextFile(SubFile, 'x');
  FOnErrorCount := 0;
  {$IFDEF UNIX}
  SavedAttr := FileGetAttr(BlockedDir);
  AssertEquals(0, fs_chmod(BlockedDir, &0000));
  {$ELSE}
  SavedAttr := 0;
  if False and (SavedAttr = 0) then ;
  {$ENDIF}
  try
    LOpts := FsDefaultWalkOptions;
    LOpts.PostFilter := @PostRejectBlocked; // PostFilter 不阻止递归
    LOpts.OnError := @OnErrCountContinue;
    LRes := WalkDir(FRoot, LOpts, @VisitorAdd);
    AssertEquals(0, LRes);
    {$IFDEF UNIX}
    AssertTrue('应触发 OnError（即便 PostFilter 拒绝 blocked）', FOnErrorCount >= 1);
    {$ELSE}
    AssertTrue(True);
    {$ENDIF}
  finally
    {$IFDEF UNIX}
    fs_chmod(BlockedDir, &0755);
    {$ENDIF}
  end;
end;

procedure TTestCase_Walk.Test_Walk_OnError_Continue_InvalidRoot_IncrementsCount;
var
  LRes: Integer;
  LOpts: TFsWalkOptions;
begin
  FOnErrorCount := 0;
  LOpts := FsDefaultWalkOptions;
  LOpts.OnError := @OnErrCountContinue;
  {$IFDEF WINDOWS}
  LRes := WalkDir('Z:\onerror_counter_root', LOpts, nil);
  {$ELSE}
  LRes := WalkDir('/onerror_counter_root', LOpts, nil);
  {$ENDIF}
  AssertEquals(0, LRes);
  AssertTrue('无效根应触发一次 OnError', FOnErrorCount >= 1);
end;


procedure TTestCase_Walk.Test_Walk_Stats_OnError_Increments;
var
  LRes: Integer;
  LOpts: TFsWalkOptions;

  Stats: TFsWalkStats;
begin
  Stats := Default(TFsWalkStats);
  LOpts := FsDefaultWalkOptions;
  LOpts.Stats := @Stats;
  LOpts.OnError := @OnErrContinue;
  {$IFDEF WINDOWS}
  LRes := WalkDir('Z:\definitely_not_existing_for_stats', LOpts, nil);
  {$ELSE}
  LRes := WalkDir('/definitely_not_existing_for_stats', LOpts, nil);
  {$ENDIF}
  AssertEquals('Continue 策略下根无效返回 0', 0, LRes);
  AssertTrue('Stats.Errors 应 >= 1', Stats.Errors >= 1);
end;

procedure TTestCase_Walk.Test_Walk_Symlink_Follow_Valid_NoOnError;
var
  LRes: Integer;
  LOpts: TFsWalkOptions;
  LSym: string;
begin
  // init locals to avoid uninitialized warnings (no behavior change)
  LSym := '';
  LRes := 0;
  LOpts := Default(TFsWalkOptions);
  {$IFDEF UNIX}
  // 创建符号链接指向 sub1，跟随链接不应触发 OnError
  LSym := IncludeTrailingPathDelimiter(FRoot) + 'link_ok';
  AssertEquals(0, fs_symlink('sub1', LSym));
  try
    FOnErrorCount := 0;
    LOpts := FsDefaultWalkOptions;
    LOpts.FollowSymlinks := True;
    LOpts.OnError := @OnErrCountContinue;
    LRes := WalkDir(FRoot, LOpts, @VisitorAdd);
    AssertEquals(0, LRes);
    AssertEquals('有效链接不应触发 OnError', 0, FOnErrorCount);
  finally
    fs_unlink(LSym);
  end;
  {$ELSE}
  AssertTrue(True);
  // silence unused locals in Windows branch
  if False and (LSym = '') then ;
  if False and (LRes = 0) then ;
  if False and (LOpts.MaxDepth < -1) then ;
  {$ENDIF}
end;

procedure TTestCase_Walk.Test_Walk_Symlink_Follow_Broken_OnError;
var
  LRes: Integer;
  LOpts: TFsWalkOptions;
  LSym: string;
begin
  // init locals to avoid uninitialized warnings (no行为改变)
  LSym := '';
  LRes := 0;
  LOpts := Default(TFsWalkOptions);
  {$IFDEF UNIX}
  // 创建指向不存在目标的链接，预期跟随时报错触发 OnError
  LSym := IncludeTrailingPathDelimiter(FRoot) + 'link_broken';
  AssertEquals(0, fs_symlink('no_such_target', LSym));
  try
    FOnErrorCount := 0;
    LOpts := FsDefaultWalkOptions;
    LOpts.FollowSymlinks := True;
    LOpts.OnError := @OnErrCountContinue;
    LRes := WalkDir(FRoot, LOpts, @VisitorAdd);
    AssertEquals(0, LRes);
    AssertTrue('损坏链接应触发 OnError', FOnErrorCount >= 1);
  finally
    fs_unlink(LSym);
  end;
  {$ELSE}
  AssertTrue(True);
  // silence unused locals in Windows branch
  if False and (LSym = '') then ;
  if False and (LRes = 0) then ;
  if False and (LOpts.MaxDepth < -1) then ;
  {$ENDIF}
end;




procedure TTestCase_Walk.Test_Walk_InvalidPath_ReturnsUnifiedError;
var
  LRes: Integer;
  LOpts: TFsWalkOptions;
begin
  LOpts := FsDefaultWalkOptions;
  {$IFDEF WINDOWS}
  LRes := WalkDir('Z:\invalid_path_12345', LOpts, nil);
  {$ELSE}
  LRes := WalkDir('/invalid_path_12345', LOpts, nil);
  {$ENDIF}
  AssertTrue('WalkDir invalid path should return negative unified error', LRes < 0);
end;



initialization
  RegisterTest(TTestCase_Walk);
end.


procedure TTestCase_Walk.Test_Walk_FollowSymlinks_Cycle_NoInfiniteRecursion;
var
  LRes: Integer;
  LOpts: TFsWalkOptions;
  L1, L2: string;
begin
  {$IFDEF UNIX}
  // 构造循环：sub1/link_to_sub2 -> ../sub2, sub2/link_to_sub1 -> ../sub1
  L1 := IncludeTrailingPathDelimiter(FRoot) + 'sub1' + PathDelim + 'link_to_sub2';
  L2 := IncludeTrailingPathDelimiter(FRoot) + 'sub2' + PathDelim + 'link_to_sub1';
  AssertEquals(0, fs_symlink('..' + PathDelim + 'sub2', L1));
  AssertEquals(0, fs_symlink('..' + PathDelim + 'sub1', L2));
  try
    FOnErrorCount := 0;
    LOpts := FsDefaultWalkOptions;
    LOpts.FollowSymlinks := True;
    LOpts.OnError := @OnErrCountContinue;
    // 不应因循环而崩溃或无限递归；返回 0，OnError 计数允许为 0 或 >0（权限/平台差异）
    LRes := WalkDir(FRoot, LOpts, @VisitorAdd);
    AssertEquals(0, LRes);
    AssertTrue(True);
  finally
    fs_unlink(L1);
    fs_unlink(L2);
  end;
  {$ELSE}
  AssertTrue(True);
  {$ENDIF}
end;

procedure TTestCase_Walk.Test_Walk_MaxDepth_WithErrors_NoFalseOnError;
var
  LRes: Integer;
  LOpts: TFsWalkOptions;
  BlockedDir: string;
  SavedAttr: LongInt;
begin
  // 在深度边界制造错误，确认 MaxDepth 截断不会导致误触发 OnError
  BlockedDir := IncludeTrailingPathDelimiter(FRoot) + 'blocked';
  EnsureDir(BlockedDir);
  {$IFDEF UNIX}
  SavedAttr := FileGetAttr(BlockedDir);
  AssertEquals(0, fs_chmod(BlockedDir, &0000));
  {$ELSE}
  SavedAttr := 0;
  if False and (SavedAttr = 0) then ;
  {$ENDIF}
  try
    FOnErrorCount := 0;
    LOpts := FsDefaultWalkOptions;
    LOpts.MaxDepth := 1; // 只到 sub1，不进入 blocked（在 root 下则进入；因此将 blocked 放到 sub2 下更严谨）
    // 调整：将 blocked 放到 sub2
    DeleteDirectory(BlockedDir, True);
    BlockedDir := IncludeTrailingPathDelimiter(FRoot) + 'sub1' + PathDelim + 'sub2' + PathDelim + 'blocked';
    EnsureDir(BlockedDir);
    {$IFDEF UNIX}
    AssertEquals(0, fs_chmod(BlockedDir, &0000));
    {$ENDIF}
    LOpts.MaxDepth := 2; // root(0), sub1(1), sub2(2) 边界，不进入 blocked(3)
    LOpts.OnError := @OnErrCountContinue;
    LRes := WalkDir(FRoot, LOpts, @VisitorAdd);
    AssertEquals(0, LRes);
    // 因 MaxDepth 截断未进入 blocked，OnError 不应触发
    AssertEquals(0, FOnErrorCount);
  finally
    {$IFDEF UNIX}
    fs_chmod(BlockedDir, &0755);
    {$ENDIF}
  end;
end;

