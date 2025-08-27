{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_errno;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs, fafafa.core.fs.errors;

type
  { TTestCase_Errno - 验证 fs_open 失败后的 fs_errno 行为 }
  TTestCase_Errno = class(TTestCase)
  published
    procedure Test_fs_open_Failure_Sets_fs_errno;
  end;

implementation

procedure TTestCase_Errno.Test_fs_open_Failure_Sets_fs_errno;
var
  LFile: TfsFile;
  Err: Integer;
  Missing: string;
begin
  Missing := 'definitely_not_exists_' + IntToStr(Random(1000000)) + '.tmp';
  // 确保文件不存在
  if FileExists(Missing) then
    DeleteFile(Missing);

  // 尝试只读打开不存在的文件
  LFile := fs_open(Missing, O_RDONLY, 0);
  AssertFalse('打开不存在的文件应失败，返回无效句柄', IsValidHandle(LFile));

  // 读取错误码
  Err := fs_errno();
  AssertTrue('fs_errno 应返回非零负错误码', Err < 0);

  // 在统一错误码模式下，应该归类为 NotFound
  if FsLowLevelReturnsUnified then
  begin
    AssertTrue('统一错误码：应归类为 NotFound', IsNotFound(Err));
  end;
end;

initialization
  RegisterTest(TTestCase_Errno);
end.

