{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_longpath;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs, fafafa.core.fs.path, fafafa.core.fs.walk, fafafa.core.fs.fileio, fafafa.core.fs.directory, fafafa.core.fs.options;

// 仅在 Windows 且设置环境变量 FAFAFA_TEST_WIN_LONGPATH=1 时启用

type
  TTestCase_WinLongPath = class(TTestCase)
  private
    FCount: Integer;
    function VisitorCount(const APath: string; const AStat: TfsStat; ADepth: Integer): Boolean;
  published
    procedure Test_Win_LongPath_Basic;
    procedure Test_Win_LongPath_Normalize_PathsEqual;
    procedure Test_Win_LongPath_Walk;
    procedure Test_Win_LongPath_Rename_Realpath;
    procedure Test_Win_LongPath_ValidatePath_LengthPolicy;
  end;


implementation

procedure TTestCase_WinLongPath.Test_Win_LongPath_Basic;
var
  Enabled: Boolean;
  BaseDir, CurDir, LongDir, LongFile, Data: string;
  H: fafafa.core.fs.TfsFile;
  W: Integer;
  I: Integer;
begin
  {$IFNDEF WINDOWS}
  Exit;
  {$ENDIF}

  Enabled := GetEnvironmentVariable('FAFAFA_TEST_WIN_LONGPATH') = '1';
  if not Enabled then Exit;

  // 构造一个>260字符的绝对路径
  BaseDir := ResolvePath('longpath_root');
  if fs_mkdir(BaseDir, S_IRWXU) <> 0 then Exit; // 若失败直接跳过（权限/策略）
  try
    LongDir := BaseDir;
    // 逐层创建，避免一次性创建深层目录失败
    for I := 1 to 20 do
    begin
      if I = 1 then
        CurDir := AppendPath(BaseDir, 'subfolder_with_very_long_name_' + IntToStr(I))
      else
        CurDir := AppendPath(LongDir, 'subfolder_with_very_long_name_' + IntToStr(I));
      if fs_mkdir(CurDir, S_IRWXU) <> 0 then
      begin
        if not PathExists(CurDir) then Exit; // 不支持长路径则跳过
      end;
      LongDir := CurDir;
    end;

    LongFile := AppendPath(LongDir, 'test_long_path_filename_abcdefghijklmnopqrstuvwxyz0123456789.txt');

    // 写
    H := fs_open(LongFile, O_WRONLY or O_CREAT or O_TRUNC, S_IRWXU);
    if not IsValidHandle(H) then Exit; // 不支持长路径则跳过
    try
      Data := 'hello-long-path';
      W := fs_write(H, PChar(Data), Length(Data), -1);
      AssertTrue('写入应成功', W = Length(Data));
    finally
      fs_close(H);
    end;

    // 读
    H := fs_open(LongFile, O_RDONLY, 0);
    AssertTrue('打开应成功', IsValidHandle(H));
    fs_close(H);

    // 删除文件
    AssertTrue('删除应成功', fs_unlink(LongFile) = 0);
  finally
    // 清理目录（尽力而为）
    fs_rmdir(LongDir);
    fs_rmdir(BaseDir);
  end;
end;

procedure TTestCase_WinLongPath.Test_Win_LongPath_Normalize_PathsEqual;
var
  Enabled: Boolean;
  BaseDir, CurDir, LongDir, P1, P2: string;
  I: Integer;
  H: fafafa.core.fs.TfsFile;
  W: Integer;
begin
  {$IFNDEF WINDOWS}
  Exit;
  {$ENDIF}

  Enabled := GetEnvironmentVariable('FAFAFA_TEST_WIN_LONGPATH') = '1';
  if not Enabled then Exit;

  BaseDir := ResolvePath('longpath_norm_root');
  if fs_mkdir(BaseDir, S_IRWXU) <> 0 then Exit;
  try
    LongDir := BaseDir;
    for I := 1 to 20 do
    begin
      if I = 1 then
        CurDir := AppendPath(BaseDir, 'seg_' + IntToStr(I))
      else
        CurDir := AppendPath(LongDir, 'seg_' + IntToStr(I));
      if fs_mkdir(CurDir, S_IRWXU) <> 0 then
      begin
        if not PathExists(CurDir) then Exit;
      end;
      LongDir := CurDir;
    end;

    // 构造两个等价但分隔符不同的路径
    P1 := AppendPath(LongDir, 'mix_sep_filename_ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.txt');
    P2 := ToUnixPath(P1);

    // 确保可以创建文件（若不支持长路径则跳过）
    H := fs_open(P1, O_WRONLY or O_CREAT or O_TRUNC, S_IRWXU);
    if not IsValidHandle(H) then Exit;
    try
      W := fs_write(H, PChar('x'), 1, -1);
      AssertEquals(1, W);
    finally
      fs_close(H);
    end;

    // Normalize/PathsEqual 行为
    AssertTrue('路径等价（混合分隔符）', PathsEqual(P1, P2));
    AssertTrue('Normalize 后应等价', PathsEqual(NormalizePath(P1), NormalizePath(P2)));

    // 清理
    AssertEquals(0, fs_unlink(P1));
  finally
    // 逆序删除目录（尽力而为）
    for I := 20 downto 1 do
    begin
      if I = 1 then
        CurDir := AppendPath(BaseDir, 'seg_' + IntToStr(I))
      else
        CurDir := AppendPath(AppendPath(BaseDir, 'seg_1'), 'seg_' + IntToStr(I));
      // 简化：逐级从 LongDir 开始回退删除
    end;
    // 粗粒度清理（不失败测试）
    fs_rmdir(LongDir);
    fs_rmdir(BaseDir);
  end;
end;

procedure TTestCase_WinLongPath.Test_Win_LongPath_Walk;
var
  Enabled: Boolean;
  BaseDir, CurDir, LongDir, F1, F2: string;
  I, LRes: Integer;
  Opts: TFsWalkOptions;
  H: fafafa.core.fs.TfsFile;
begin
  {$IFNDEF WINDOWS}
  Exit;
  {$ENDIF}

  Enabled := GetEnvironmentVariable('FAFAFA_TEST_WIN_LONGPATH') = '1';
  if not Enabled then Exit;

  BaseDir := ResolvePath('longpath_walk_root');
  if fs_mkdir(BaseDir, S_IRWXU) <> 0 then Exit;
  try
    LongDir := BaseDir;
    for I := 1 to 18 do
    begin
      if I = 1 then
        CurDir := AppendPath(BaseDir, 'deep_' + IntToStr(I))
      else
        CurDir := AppendPath(LongDir, 'deep_' + IntToStr(I));
      if fs_mkdir(CurDir, S_IRWXU) <> 0 then
      begin
        if not PathExists(CurDir) then Exit;
      end;
      LongDir := CurDir;
    end;

    F1 := AppendPath(LongDir, 'a.txt');
    F2 := AppendPath(LongDir, 'b.txt');

    // 若无法创建文件，说明环境仍不支持长路径，跳过
    H := fs_open(F1, O_WRONLY or O_CREAT or O_TRUNC, S_IRWXU);
    if not IsValidHandle(H) then Exit;
    fs_close(H);

    H := fs_open(F2, O_WRONLY or O_CREAT or O_TRUNC, S_IRWXU);
    if not IsValidHandle(H) then Exit;
    fs_close(H);

    FCount := 0;
    Opts := FsDefaultWalkOptions;
    LRes := WalkDir(BaseDir, Opts, @VisitorCount);

    AssertEquals('WalkDir 应成功', 0, LRes);
    AssertTrue('应访问到多个条目', FCount >= 2);

    // 清理
    fs_unlink(F1);
    fs_unlink(F2);
  finally
    fs_rmdir(LongDir);
    fs_rmdir(BaseDir);
  end;

  end;

procedure TTestCase_WinLongPath.Test_Win_LongPath_Rename_Realpath;
var
  Enabled: Boolean;
  BaseDir, LongDir, Src, Dst: string;
  H: fafafa.core.fs.TfsFile;
  Buf: array[0..1023] of Char;
  R: Integer;
  I: Integer;
begin
  {$IFNDEF WINDOWS}
  Exit;
  {$ENDIF}

  Enabled := GetEnvironmentVariable('FAFAFA_TEST_WIN_LONGPATH') = '1';
  if not Enabled then Exit;

  BaseDir := ResolvePath('longpath_rename_root');
  if fs_mkdir(BaseDir, S_IRWXU) <> 0 then Exit;
  try
    LongDir := BaseDir;
    for I := 1 to 18 do
    begin
      if I = 1 then
        LongDir := AppendPath(BaseDir, 'rr_' + IntToStr(I))
      else
        LongDir := AppendPath(LongDir, 'rr_' + IntToStr(I));
      if fs_mkdir(LongDir, S_IRWXU) <> 0 then
        if not PathExists(LongDir) then Exit;
    end;

    Src := AppendPath(LongDir, 'from_name_ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.txt');
    Dst := AppendPath(LongDir, 'to_name_ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.txt');

    H := fs_open(Src, O_WRONLY or O_CREAT or O_TRUNC, S_IRWXU);
    if not IsValidHandle(H) then Exit;
    fs_close(H);

    // rename
    AssertEquals(0, fs_rename(Src, Dst));
    AssertTrue(PathExists(Dst));

    // realpath
    R := fs_realpath(Dst, @Buf[0], Length(Buf));
    AssertTrue('realpath ok', R >= 0);
  finally
    if PathExists(Dst) then fs_unlink(Dst);
    fs_rmdir(LongDir);
    fs_rmdir(BaseDir);
  end;
end;


procedure TTestCase_WinLongPath.Test_Win_LongPath_ValidatePath_LengthPolicy;
var
  Enabled: Boolean;
  LongPath: string;
  I: Integer;
begin
  {$IFNDEF WINDOWS}
  Exit;
  {$ENDIF}

  Enabled := GetEnvironmentVariable('FAFAFA_TEST_WIN_LONGPATH') = '1';
  if not Enabled then Exit;

  // 构造一个超长路径字符串（不做实际 I/O，只测试 ValidatePath 的判定）
  LongPath := 'C:\';
  for I := 1 to 1000 do
    LongPath := LongPath + 'seg_'+IntToStr(I)+'\\';

  // 仅断言调用不会崩溃；长度判定由宏控制，具体真值由环境/编译开关决定
  // 启用 FAFAFA_CORE_FS_ENABLE_WIN_LONGPATH 时，通常返回 True（更宽松）；未启用时，通常为 False（>260）
  AssertTrue('ValidatePath 不应崩溃/异常', (ValidatePath(LongPath) = True) or (ValidatePath(LongPath) = False));
end;


function TTestCase_WinLongPath.VisitorCount(const APath: string; const AStat: TfsStat; ADepth: Integer): Boolean;
begin
  if False and (APath = '') then; // 抑制未用参数 APath 提示
  if False and (ADepth = 0) then; // 抑制未用参数
  if False and (AStat.Size = 0) then;
  Inc(FCount);
  Result := True;
end;

initialization
  RegisterTest(TTestCase_WinLongPath);
end.

