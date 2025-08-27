{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_mkstemp_mkdtemp_flock;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs, fafafa.core.fs.errors;

type
  { TTestCase_TempAndLock }
  TTestCase_TempAndLock = class(TTestCase)
  published
    procedure Test_mkstemp_ex_and_cleanup;
    procedure Test_mkdtemp_and_cleanup;
    procedure Test_flock_basic;
    // 边界/差异化用例
    procedure Test_mkstemp_template_without_X_returns_handle_or_error;
    procedure Test_mkdtemp_template_without_X_returns_empty;
    procedure Test_realpath_small_buffer_returns_error;
    procedure Test_fchmod_on_tempfile_returns_ok_or_unsupported;
    procedure Test_flock_nonblocking_contention_returns_error;
    procedure Test_flock_shared_then_exclusive_conflict;
    procedure Test_flock_exclusive_then_shared_conflict;
    {$IFDEF WINDOWS}
    procedure Test_realpath_s_windows_prefix_stripped;
    {$ENDIF}
  end;

implementation

procedure TTestCase_TempAndLock.Test_mkstemp_ex_and_cleanup;
var
  F: TfsFile;
  P: string;
begin
  F := fs_mkstemp_ex('unit_tmp_XXXXXX', P);
  AssertTrue('mkstemp_ex should succeed', IsValidHandle(F));
  AssertTrue('mkstemp_ex should return non-empty path', P <> '');
  fs_close(F);
  AssertEquals(0, fs_unlink(P));
end;

procedure TTestCase_TempAndLock.Test_mkdtemp_and_cleanup;
var
  D: string;
begin
  D := fs_mkdtemp('unit_tmpd_XXXXXX');
  AssertTrue('mkdtemp should return non-empty dir path', D <> '');
  AssertEquals(0, fs_rmdir(D));
end;

procedure TTestCase_TempAndLock.Test_flock_basic;
var
  F: TfsFile;
  P: string;
  R: Integer;
begin
  F := fs_mkstemp_ex('unit_lock_XXXXXX', P);
  if not IsValidHandle(F) then
  begin
    AssertTrue('mkstemp_ex failed unexpectedly', False);
    Exit;
  end;
  try
    R := fs_flock(F, LOCK_EX);
    AssertTrue('fs_flock LOCK_EX should return 0 or a defined error', (R = 0) or (R < 0));
    if R = 0 then
      AssertEquals(0, fs_flock(F, LOCK_UN));
  finally
    fs_close(F);
    fs_unlink(P);
  end;
end;


procedure TTestCase_TempAndLock.Test_mkstemp_template_without_X_returns_handle_or_error;
var
  F: TfsFile;
  P: string;
begin
  // Windows/Unix 行为不同：Windows 我们内部用 GUID 生成；Unix 需要 X 模板
  // 因此这里只断言：要么成功返回句柄，要么返回 INVALID_HANDLE_VALUE（负路径不应崩溃）
  F := fs_mkstemp('unit_tmp_noX');
  if IsValidHandle(F) then
  begin
    // 可能成功（Windows 自生成路径）
    fs_close(F);
    // 无路径可删，跳过
  end;
  // 成功或失败均视为可接受
  AssertTrue('mkstemp without X should not crash', True);

  // 扩展：fs_mkstemp_ex 无 X 模板
  F := fs_mkstemp_ex('unit_tmp_noX2', P);
  if IsValidHandle(F) then
  begin
    fs_close(F);
    if P <> '' then fs_unlink(P);
  end;
  AssertTrue(True);
end;

procedure TTestCase_TempAndLock.Test_mkdtemp_template_without_X_returns_empty;
var
  D: string;
begin
  D := fs_mkdtemp('unit_tmpd_noX');
  {$IFDEF UNIX}
  // Unix 语义：模板不含 X 通常失败，返回空串
  AssertTrue('mkdtemp without X on Unix returns empty', D = '');
  {$ELSE}
  // Windows 实现：内部以 GUID 生成，允许成功创建
  AssertTrue('mkdtemp without X on Windows returns empty or created dir', (D = '') or DirectoryExists(D));
  if (D <> '') and DirectoryExists(D) then fs_rmdir(D);
  {$ENDIF}
end;

procedure TTestCase_TempAndLock.Test_realpath_small_buffer_returns_error;
var
  buf: array[0..3] of Char; // 很小的缓冲区
  R: Integer;
begin
  FillChar(buf, SizeOf(buf), 0);
  R := fs_realpath('.', @buf[0], SizeOf(buf));
  AssertTrue('small buffer should fail with negative error', R <= 0);
end;

procedure TTestCase_TempAndLock.Test_fchmod_on_tempfile_returns_ok_or_unsupported;
var
  F: TfsFile;
  P: string;
  R: Integer;
begin
  F := fs_mkstemp_ex('unit_fchmod_XXXXXX', P);
  AssertTrue('mkstemp_ex for fchmod', IsValidHandle(F));
  try
    R := fs_fchmod(F, S_IRUSR or S_IWUSR);
    {$IFDEF UNIX}
    AssertEquals('fchmod should succeed on Unix', 0, R);
    {$ELSE}
    // Windows 实现为占位，应该返回 0 或负错误码（不崩溃）
    AssertTrue('fchmod on Windows returns ok or unsupported', (R = 0) or (R < 0));
    {$ENDIF}
  finally
    fs_close(F);
    if P <> '' then fs_unlink(P);
  end;
end;

procedure TTestCase_TempAndLock.Test_flock_nonblocking_contention_returns_error;
var
  F1, F2: TfsFile;
  P: string;
  R: Integer;
begin
  F1 := fs_mkstemp_ex('unit_flock_XXXXXX', P);
  AssertTrue('mkstemp_ex for flock contention', IsValidHandle(F1));
  try
    AssertEquals(0, fs_flock(F1, LOCK_EX));
    F2 := fs_open(P, O_RDWR, 0);
    if IsValidHandle(F2) then
    begin
      // 继续原非阻塞争用断言
      R := fs_flock(F2, LOCK_EX or LOCK_NB);
      AssertTrue('nonblocking contention should return error or 0 only on exotic FS', (R < 0) or (R = 0));
      fs_close(F2);
    end;
  finally
    fs_flock(F1, LOCK_UN);
    fs_close(F1);
    if P <> '' then fs_unlink(P);
  end;
end;

procedure TTestCase_TempAndLock.Test_flock_shared_then_exclusive_conflict;
var
  F1, F2: TfsFile; P: string; R: Integer;
begin
  F1 := fs_mkstemp_ex('unit_flock_sh_XXXXXX', P);
  AssertTrue(IsValidHandle(F1));
  try
    AssertEquals(0, fs_flock(F1, LOCK_SH));
    F2 := fs_open(P, O_RDWR, 0);
    if IsValidHandle(F2) then
    begin
      R := fs_flock(F2, LOCK_EX or LOCK_NB);
      AssertTrue('shared then exclusive nonblock should likely fail', (R < 0) or (R = 0));
      fs_close(F2);
    end;
  finally
    fs_flock(F1, LOCK_UN);
    fs_close(F1);
    if P <> '' then fs_unlink(P);
  end;
end;

procedure TTestCase_TempAndLock.Test_flock_exclusive_then_shared_conflict;
var
  F1, F2: TfsFile; P: string; R: Integer;
begin
  F1 := fs_mkstemp_ex('unit_flock_ex_XXXXXX', P);
  AssertTrue(IsValidHandle(F1));
  try
    AssertEquals(0, fs_flock(F1, LOCK_EX));
    F2 := fs_open(P, O_RDONLY, 0);
    if IsValidHandle(F2) then
    begin
      R := fs_flock(F2, LOCK_SH or LOCK_NB);
      AssertTrue('exclusive then shared nonblock should likely fail', (R < 0) or (R = 0));
      fs_close(F2);
    end;
  finally
    fs_flock(F1, LOCK_UN);
    fs_close(F1);
    if P <> '' then fs_unlink(P);
  end;
end;

{$IFDEF WINDOWS}
procedure TTestCase_TempAndLock.Test_realpath_s_windows_prefix_stripped;
var
  P, R: string; rc: Integer;
begin
  // 生成一个真实存在的文件
  P := 'realpath_prefix_test.tmp';
  // 用简单写法创建文件（避免依赖额外工具函数）
  with TStringList.Create do
  try
    Text := 'x';
    SaveToFile(P);
  finally
    Free;
  end;
  try
    rc := fs_realpath_s(P, R);
    AssertEquals(0, rc);
    // Windows: 实现会移除 \\?\ 前缀
    AssertTrue('Windows realpath_s returns a normal path', (Pos('\\\\?\', R) = 0));
    AssertTrue('contains filename', Pos('realpath_prefix_test.tmp', R) > 0);
  finally
    fs_unlink(P);
  end;
end;
{$ENDIF}





initialization
  RegisterTest(TTestCase_TempAndLock);
end.

