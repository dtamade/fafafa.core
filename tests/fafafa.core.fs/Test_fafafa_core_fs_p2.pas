unit Test_fafafa_core_fs_p2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.fs;

type
  TTestCase_P2 = class(TTestCase)
  published
    procedure Test_fs_replace_FileToExisting;
    procedure Test_fs_realpath_s_OkAndNotExist;
    procedure Test_fs_readlink_s_Conditionally;
  end;

implementation

function WriteAllText(const APath, AText: string): Boolean;
var
  f: THandle;
  buf: RawByteString;
  w: Integer;
begin
  Result := False;
  f := fs_open(APath, FMODE_READWRITE or FMODE_CREATE or FMODE_TRUNC, 0);
  if f = INVALID_HANDLE_VALUE then Exit(False);
  try
    buf := UTF8Encode(AText);
    w := fs_write(f, PChar(buf), Length(buf), -1);
    Result := (w = Length(buf));
  finally
    fs_close(f);
  end;
end;

function ReadAllText(const APath: string): string;
var
  f: THandle;
  stat: TfsStat;
  n: Integer;
  s: RawByteString;
begin
  if fs_stat(APath, stat) <> 0 then Exit('');
  SetLength(s, stat.Size);
  f := fs_open(APath, FMODE_READ, 0);
  if f = INVALID_HANDLE_VALUE then Exit('');
  try
    n := fs_read(f, PChar(s), Length(s), -1);
    if n > 0 then
      SetString(Result, PChar(s), n)
    else
      Result := '';
  finally
    fs_close(f);
  end;
end;

procedure TTestCase_P2.Test_fs_replace_FileToExisting;
var
  tmpDir, srcFile, dstFile: string;
  res: Integer;
  content: string;
begin
  tmpDir := GetTempDir(False);
  srcFile := tmpDir + 'fs_replace_src.txt';
  dstFile := tmpDir + 'fs_replace_dst.txt';

  // 准备源和目标
  AssertTrue('write src', WriteAllText(srcFile, 'SRC'));
  AssertTrue('write dst', WriteAllText(dstFile, 'DST'));

  // 执行替换
  res := fs_replace(srcFile, dstFile);
  AssertEquals('fs_replace ok', 0, res);

  // 验证目标内容已变更
  content := ReadAllText(dstFile);
  AssertEquals('dst content replaced', 'SRC', content);

  // 清理
  fs_unlink(srcFile);
  fs_unlink(dstFile);
end;

procedure TTestCase_P2.Test_fs_realpath_s_OkAndNotExist;
var
  tmpDir, aPath, resolved: string;
  res: Integer;
begin
  tmpDir := GetTempDir(False);
  aPath := tmpDir + 'realpath_s_dummy.txt';
  // 创建文件
  AssertTrue('create file', WriteAllText(aPath, 'X'));
  res := fs_realpath_s(aPath, resolved);
  AssertEquals('realpath_s ok', 0, res);
  AssertTrue('resolved contains filename', Pos('realpath_s_dummy.txt', resolved) > 0);
  fs_unlink(aPath);

  // 不存在
  res := fs_realpath_s(aPath, resolved);
  AssertTrue('realpath_s not exist is error', res < 0);
end;

procedure TTestCase_P2.Test_fs_readlink_s_Conditionally;
var
  tmpDir, targetFile, linkFile, outTarget: string;
  res: Integer;
begin
  tmpDir := GetTempDir(False);
  targetFile := tmpDir + 'rl_target.txt';
  linkFile := tmpDir + 'rl_link.lnk';

  AssertTrue('create target', WriteAllText(targetFile, 'T'));

  res := fs_symlink(targetFile, linkFile);
  if res < 0 then
  begin
    // Windows 无管理员/Dev 模式可能失败；此时跳过用例
    Exit;
  end;

  res := fs_readlink_s(linkFile, outTarget);
  AssertEquals('readlink_s ok', 0, res);
  // 有的平台可能返回相对或绝对路径，此处仅检查包含文件名
  AssertTrue('outTarget contains filename', Pos('rl_target.txt', outTarget) > 0);

  fs_unlink(linkFile);
  fs_unlink(targetFile);
end;

initialization
  RegisterTest(TTestCase_P2);

end.

