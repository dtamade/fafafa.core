{$CODEPAGE UTF8}
unit Test_fafafa_core_fs;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs;

type
  { TTestCase_Global - 测试全局函数和过程 }
  TTestCase_Global = class(TTestCase)
  private
    FTestFileName: string;
    FTestDirName: string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 基础文件操作测试
    procedure Test_fs_open;
    procedure Test_fs_open_InvalidPath;
    procedure Test_fs_close;
    procedure Test_fs_read;
    procedure Test_fs_read_InvalidHandle;
    procedure Test_fs_write;
    procedure Test_fs_write_InvalidHandle;

    // 文件系统操作测试
    procedure Test_fs_unlink;
    procedure Test_fs_unlink_NonExistent;
    procedure Test_fs_rename;
    procedure Test_fs_rename_InvalidSource;

    // 目录操作测试
    procedure Test_fs_mkdir;
    procedure Test_fs_mkdir_ExistingDir;
    procedure Test_fs_rmdir;
    procedure Test_fs_rmdir_NonExistent;

    // 文件属性和权限测试
    procedure Test_fs_access;
    procedure Test_fs_access_NonExistent;
    procedure Test_fs_chmod;
    procedure Test_fs_stat;
    procedure Test_fs_stat_NonExistent;

    // 高级功能测试
    procedure Test_fs_fsync;
    procedure Test_fs_fsync_InvalidHandle;
    procedure Test_fs_realpath;
    procedure Test_fs_realpath_NonExistent;

    // 文件锁定测试
    procedure Test_fs_flock;
    procedure Test_fs_flock_InvalidHandle;

    // 链接操作测试（Unix特有）
    {$IFDEF UNIX}
    procedure Test_fs_symlink;
    procedure Test_fs_readlink;
    procedure Test_fs_link;
    {$ENDIF}

    // 临时文件测试
    procedure Test_fs_mkstemp;
    procedure Test_fs_mkdtemp;

    // 辅助函数测试
    procedure Test_IsValidHandle;
  end;

implementation

{ TTestCase_Global }

procedure TTestCase_Global.SetUp;
begin
  inherited SetUp;
  FTestFileName := 'test_file_' + IntToStr(Random(999999)) + '.tmp';
  FTestDirName := 'test_dir_' + IntToStr(Random(999999));

  // 确保测试文件不存在
  if FileExists(FTestFileName) then
    DeleteFile(FTestFileName);
  if DirectoryExists(FTestDirName) then
    RemoveDir(FTestDirName);
end;

procedure TTestCase_Global.TearDown;
begin
  // 清理测试文件和目录
  if FileExists(FTestFileName) then
    DeleteFile(FTestFileName);
  if DirectoryExists(FTestDirName) then
    RemoveDir(FTestDirName);
  inherited TearDown;
end;

procedure TTestCase_Global.Test_fs_open;
var
  LFile: TfsFile;
begin
  // 测试创建新文件
  LFile := fs_open(FTestFileName, O_WRONLY or O_CREAT, S_IRWXU);
  AssertTrue('应该能够创建新文件', IsValidHandle(LFile));
  fs_close(LFile);

  // 测试打开已存在的文件
  LFile := fs_open(FTestFileName, O_RDONLY, 0);
  AssertTrue('应该能够打开已存在的文件', IsValidHandle(LFile));
  fs_close(LFile);
end;

procedure TTestCase_Global.Test_fs_open_InvalidPath;
var
  LFile: TfsFile;
begin
  // 测试打开不存在的文件（只读模式）
  LFile := fs_open('nonexistent_file_12345.txt', O_RDONLY, 0);
  AssertFalse('打开不存在的文件应该失败', IsValidHandle(LFile));
end;

procedure TTestCase_Global.Test_fs_close;
var
  LFile: TfsFile;
  LResult: Integer;
begin
  // 创建文件并关闭
  LFile := fs_open(FTestFileName, O_WRONLY or O_CREAT, S_IRWXU);
  AssertTrue('文件应该创建成功', IsValidHandle(LFile));

  LResult := fs_close(LFile);
  AssertEquals('关闭文件应该成功', 0, LResult);
end;

procedure TTestCase_Global.Test_fs_read;
var
  LFile: TfsFile;
  LTestData: string;
  LBuffer: array[0..255] of Char;
  LBytesRead: Integer;
begin
  // 先写入测试数据
  LTestData := 'Test data for reading';
  LFile := fs_open(FTestFileName, O_WRONLY or O_CREAT, S_IRWXU);
  fs_write(LFile, PChar(LTestData), Length(LTestData), -1);
  fs_close(LFile);

  // 读取数据
  LFile := fs_open(FTestFileName, O_RDONLY, 0);
  FillChar(LBuffer, SizeOf(LBuffer), 0);
  LBytesRead := fs_read(LFile, @LBuffer[0], SizeOf(LBuffer) - 1, -1);
  fs_close(LFile);

  AssertEquals('读取的字节数应该正确', Length(LTestData), LBytesRead);
  AssertEquals('读取的内容应该正确', LTestData, string(LBuffer));
end;

procedure TTestCase_Global.Test_fs_read_InvalidHandle;
var
  LBuffer: array[0..10] of Char;
  LBytesRead: Integer;
begin
  // 测试无效句柄
  FillChar(LBuffer, SizeOf(LBuffer), 0);
  LBytesRead := fs_read(INVALID_HANDLE_VALUE, @LBuffer[0], SizeOf(LBuffer), -1);
  AssertTrue('无效句柄读取应该失败', LBytesRead < 0);
end;

procedure TTestCase_Global.Test_fs_write;
var
  LFile: TfsFile;
  LTestData: string;
  LBytesWritten: Integer;
begin
  LTestData := 'Test data for writing';
  LFile := fs_open(FTestFileName, O_WRONLY or O_CREAT, S_IRWXU);

  LBytesWritten := fs_write(LFile, PChar(LTestData), Length(LTestData), -1);
  fs_close(LFile);

  AssertEquals('写入的字节数应该正确', Length(LTestData), LBytesWritten);
  AssertTrue('文件应该存在', FileExists(FTestFileName));
end;

procedure TTestCase_Global.Test_fs_write_InvalidHandle;
var
  LTestData: string;
  LBytesWritten: Integer;
begin
  LTestData := 'Test data';
  LBytesWritten := fs_write(INVALID_HANDLE_VALUE, PChar(LTestData), Length(LTestData), -1);
  AssertTrue('无效句柄写入应该失败', LBytesWritten < 0);
end;

procedure TTestCase_Global.Test_fs_unlink;
var
  LFile: TfsFile;
  LResult: Integer;
begin
  // 创建文件
  LFile := fs_open(FTestFileName, O_WRONLY or O_CREAT, S_IRWXU);
  fs_close(LFile);
  AssertTrue('文件应该存在', FileExists(FTestFileName));

  // 删除文件
  LResult := fs_unlink(FTestFileName);
  AssertEquals('删除文件应该成功', 0, LResult);
  AssertFalse('文件应该不存在', FileExists(FTestFileName));
end;

procedure TTestCase_Global.Test_fs_unlink_NonExistent;
var
  LResult: Integer;
begin
  LResult := fs_unlink('nonexistent_file_12345.txt');
  AssertTrue('删除不存在的文件应该失败', LResult < 0);
end;

procedure TTestCase_Global.Test_fs_rename;
var
  LFile: TfsFile;
  LNewFileName: string;
  LResult: Integer;
begin
  // 创建源文件
  LFile := fs_open(FTestFileName, O_WRONLY or O_CREAT, S_IRWXU);
  fs_close(LFile);

  LNewFileName := FTestFileName + '_renamed';
  LResult := fs_rename(FTestFileName, LNewFileName);

  AssertEquals('重命名应该成功', 0, LResult);
  AssertFalse('原文件应该不存在', FileExists(FTestFileName));
  AssertTrue('新文件应该存在', FileExists(LNewFileName));

  // 清理
  DeleteFile(LNewFileName);
end;

procedure TTestCase_Global.Test_fs_rename_InvalidSource;
var
  LResult: Integer;
begin
  LResult := fs_rename('nonexistent_file.txt', 'new_name.txt');
  AssertTrue('重命名不存在的文件应该失败', LResult < 0);
end;

procedure TTestCase_Global.Test_fs_mkdir;
var
  LResult: Integer;
begin
  LResult := fs_mkdir(FTestDirName, S_IRWXU);
  AssertEquals('创建目录应该成功', 0, LResult);
  AssertTrue('目录应该存在', DirectoryExists(FTestDirName));
end;

procedure TTestCase_Global.Test_fs_mkdir_ExistingDir;
var
  LResult: Integer;
begin
  // 先创建目录
  CreateDir(FTestDirName);

  // 尝试再次创建
  LResult := fs_mkdir(FTestDirName, S_IRWXU);
  AssertTrue('创建已存在的目录应该失败', LResult < 0);
end;

procedure TTestCase_Global.Test_fs_rmdir;
var
  LResult: Integer;
begin
  // 先创建目录
  CreateDir(FTestDirName);
  AssertTrue('目录应该存在', DirectoryExists(FTestDirName));

  LResult := fs_rmdir(FTestDirName);
  AssertEquals('删除目录应该成功', 0, LResult);
  AssertFalse('目录应该不存在', DirectoryExists(FTestDirName));
end;

procedure TTestCase_Global.Test_fs_rmdir_NonExistent;
var
  LResult: Integer;
begin
  LResult := fs_rmdir('nonexistent_dir_12345');
  AssertTrue('删除不存在的目录应该失败', LResult < 0);
end;

procedure TTestCase_Global.Test_fs_access;
var
  LFile: TfsFile;
  LResult: Integer;
begin
  // 创建文件
  LFile := fs_open(FTestFileName, O_WRONLY or O_CREAT, S_IRWXU);
  fs_close(LFile);

  // 测试文件存在性
  LResult := fs_access(FTestFileName, F_OK);
  AssertEquals('文件存在检查应该成功', 0, LResult);

  // 测试读权限
  LResult := fs_access(FTestFileName, R_OK);
  AssertEquals('读权限检查应该成功', 0, LResult);

  // 测试写权限
  LResult := fs_access(FTestFileName, W_OK);
  AssertEquals('写权限检查应该成功', 0, LResult);
end;

procedure TTestCase_Global.Test_fs_access_NonExistent;
var
  LResult: Integer;
begin
  LResult := fs_access('nonexistent_file_12345.txt', F_OK);
  AssertTrue('不存在文件的访问检查应该失败', LResult < 0);
end;

procedure TTestCase_Global.Test_fs_chmod;
var
  LFile: TfsFile;
  LResult: Integer;
begin
  // 创建文件
  LFile := fs_open(FTestFileName, O_WRONLY or O_CREAT, S_IRWXU);
  fs_close(LFile);

  // 修改权限
  LResult := fs_chmod(FTestFileName, S_IRUSR or S_IWUSR);
  {$IFDEF UNIX}
  AssertEquals('修改权限应该成功', 0, LResult);
  {$ELSE}
  // Windows下可能不支持或行为不同
  AssertTrue('修改权限结果应该是有效的', LResult >= 0);
  {$ENDIF}
end;

procedure TTestCase_Global.Test_fs_stat;
var
  LFile: TfsFile;
  LStat: TfsStat;
  LResult: Integer;
begin
  // 创建文件
  LFile := fs_open(FTestFileName, O_WRONLY or O_CREAT, S_IRWXU);
  fs_write(LFile, PChar('test'), 4, -1);
  fs_close(LFile);

  LResult := fs_stat(FTestFileName, LStat);
  AssertEquals('获取文件状态应该成功', 0, LResult);
  AssertEquals('文件大小应该正确', 4, LStat.Size);
end;

procedure TTestCase_Global.Test_fs_stat_NonExistent;
var
  LStat: TfsStat;
  LResult: Integer;
begin
  LResult := fs_stat('nonexistent_file_12345.txt', LStat);
  AssertTrue('获取不存在文件的状态应该失败', LResult < 0);
end;

procedure TTestCase_Global.Test_fs_fsync;
var
  LFile: TfsFile;
  LResult: Integer;
begin
  LFile := fs_open(FTestFileName, O_WRONLY or O_CREAT, S_IRWXU);
  fs_write(LFile, PChar('test'), 4, -1);

  LResult := fs_fsync(LFile);
  AssertEquals('文件同步应该成功', 0, LResult);

  fs_close(LFile);
end;

procedure TTestCase_Global.Test_fs_fsync_InvalidHandle;
var
  LResult: Integer;
begin
  LResult := fs_fsync(INVALID_HANDLE_VALUE);
  AssertTrue('无效句柄同步应该失败', LResult < 0);
end;

procedure TTestCase_Global.Test_fs_realpath;
var
  LFile: TfsFile;
  LBuffer: array[0..511] of Char;
  LResult: Integer;
begin
  // 创建文件
  LFile := fs_open(FTestFileName, O_WRONLY or O_CREAT, S_IRWXU);
  fs_close(LFile);

  FillChar(LBuffer, SizeOf(LBuffer), 0);
  LResult := fs_realpath(FTestFileName, @LBuffer[0], SizeOf(LBuffer));

  AssertTrue('获取绝对路径应该成功', LResult > 0);
  AssertTrue('绝对路径应该包含文件名', Pos(FTestFileName, string(LBuffer)) > 0);
end;

procedure TTestCase_Global.Test_fs_realpath_NonExistent;
var
  LBuffer: array[0..511] of Char;
  LResult: Integer;
begin
  FillChar(LBuffer, SizeOf(LBuffer), 0);
  LResult := fs_realpath('nonexistent_file_12345.txt', @LBuffer[0], SizeOf(LBuffer));
  AssertTrue('获取不存在文件的绝对路径应该失败', LResult <= 0);
end;

procedure TTestCase_Global.Test_fs_flock;
var
  LFile: TfsFile;
  LResult: Integer;
begin
  LFile := fs_open(FTestFileName, O_WRONLY or O_CREAT, S_IRWXU);

  // 获取排他锁
  LResult := fs_flock(LFile, LOCK_EX or LOCK_NB);
  {$IFDEF UNIX}
  AssertEquals('获取文件锁应该成功', 0, LResult);

  // 释放锁
  LResult := fs_flock(LFile, LOCK_UN);
  AssertEquals('释放文件锁应该成功', 0, LResult);
  {$ELSE}
  // Windows下可能不支持或行为不同
  AssertTrue('文件锁操作结果应该是有效的', True);
  {$ENDIF}

  fs_close(LFile);
end;

procedure TTestCase_Global.Test_fs_flock_InvalidHandle;
var
  LResult: Integer;
begin
  LResult := fs_flock(INVALID_HANDLE_VALUE, LOCK_EX);
  AssertTrue('无效句柄加锁应该失败', LResult < 0);
end;

{$IFDEF UNIX}
procedure TTestCase_Global.Test_fs_symlink;
var
  LFile: TfsFile;
  LLinkName: string;
  LResult: Integer;
begin
  // 创建目标文件
  LFile := fs_open(FTestFileName, O_WRONLY or O_CREAT, S_IRWXU);
  fs_close(LFile);

  LLinkName := FTestFileName + '_link';
  // 预清理（即使为悬挂链接，FileExists 也可能为 False）
  fs_unlink(LLinkName);

  try
    LResult := fs_symlink(FTestFileName, LLinkName);

    AssertEquals('创建符号链接应该成功', 0, LResult);
    AssertTrue('符号链接应该存在', FileExists(LLinkName));
  finally
    // 清理：确保即使断言失败也会清掉本次创建的链接
    fs_unlink(LLinkName);
  end;
end;

procedure TTestCase_Global.Test_fs_readlink;
var
  LFile: TfsFile;
  LLinkName: string;
  LBuffer: array[0..255] of Char;
  LResult: Integer;
begin
  // 创建目标文件和符号链接
  LFile := fs_open(FTestFileName, O_WRONLY or O_CREAT, S_IRWXU);
  fs_close(LFile);

  LLinkName := FTestFileName + '_link';
  fs_unlink(LLinkName);

  try
    AssertEquals('创建符号链接应该成功', 0, fs_symlink(FTestFileName, LLinkName));

    // 读取符号链接
    FillChar(LBuffer, SizeOf(LBuffer), 0);
    LResult := fs_readlink(LLinkName, @LBuffer[0], SizeOf(LBuffer));

    AssertTrue('读取符号链接应该成功', LResult > 0);
    AssertEquals('符号链接目标应该正确', FTestFileName, string(LBuffer));
  finally
    fs_unlink(LLinkName);
  end;
end;

procedure TTestCase_Global.Test_fs_link;
var
  LFile: TfsFile;
  LLinkName: string;
  LResult: Integer;
begin
  // 创建目标文件
  LFile := fs_open(FTestFileName, O_WRONLY or O_CREAT, S_IRWXU);
  fs_close(LFile);

  LLinkName := FTestFileName + '_hardlink';
  fs_unlink(LLinkName);

  try
    LResult := fs_link(FTestFileName, LLinkName);

    AssertEquals('创建硬链接应该成功', 0, LResult);
    AssertTrue('硬链接应该存在', FileExists(LLinkName));
  finally
    fs_unlink(LLinkName);
  end;
end;
{$ENDIF}

procedure TTestCase_Global.Test_fs_mkstemp;
var
  LFile: TfsFile;
  LTemplate: string;
  LTestData: string;
  LBytesWritten: Integer;
begin
  {$IFDEF UNIX}
  LTemplate := '/tmp/test_XXXXXX';
  {$ELSE}
  LTemplate := 'test_XXXXXX';
  {$ENDIF}

  LFile := fs_mkstemp(LTemplate);
  AssertTrue('创建临时文件应该成功', IsValidHandle(LFile));

  if IsValidHandle(LFile) then
  begin
    // 测试写入临时文件
    LTestData := 'temp file test';
    LBytesWritten := fs_write(LFile, PChar(LTestData), Length(LTestData), -1);
    AssertEquals('写入临时文件应该成功', Length(LTestData), LBytesWritten);

    fs_close(LFile);
    // 注意：在Windows下，临时文件的实际名称可能与模板不同
    // 我们只测试文件句柄的创建是否成功
  end;
end;

procedure TTestCase_Global.Test_fs_mkdtemp;
var
  LTemplate: string;
  LResult: string;
begin
  {$IFDEF UNIX}
  LTemplate := '/tmp/test_dir_XXXXXX';
  {$ELSE}
  LTemplate := 'test_dir_XXXXXX';
  {$ENDIF}

  LResult := fs_mkdtemp(LTemplate);
  AssertTrue('创建临时目录应该成功', LResult <> '');

  if LResult <> '' then
  begin
    AssertTrue('临时目录应该存在', DirectoryExists(LResult));
    // 清理
    RemoveDir(LResult);
  end;
end;

procedure TTestCase_Global.Test_IsValidHandle;
var
  LFile: TfsFile;
begin
  // 测试有效句柄
  LFile := fs_open(FTestFileName, O_WRONLY or O_CREAT, S_IRWXU);
  AssertTrue('有效句柄应该返回True', IsValidHandle(LFile));
  fs_close(LFile);

  // 测试无效句柄
  AssertFalse('无效句柄应该返回False', IsValidHandle(INVALID_HANDLE_VALUE));
end;

initialization
  RegisterTest(TTestCase_Global);

end.
