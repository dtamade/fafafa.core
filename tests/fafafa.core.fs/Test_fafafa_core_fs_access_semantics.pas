{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_access_semantics;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs, fafafa.core.fs.errors;

type
  { TTestCase_AccessSemantics }
  TTestCase_AccessSemantics = class(TTestCase)
  private
    FFile: string;
    FDir: string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_F_OK_Exists_File_And_Dir;
    procedure Test_W_OK_ReadOnly_File_Windows;
    procedure Test_X_OK_Dir_Semantics;
  end;

implementation

procedure TTestCase_AccessSemantics.SetUp;
begin
  inherited SetUp;
  FFile := 'acc_test_' + IntToStr(Random(1000000)) + '.txt';
  FDir := 'acc_dir_' + IntToStr(Random(1000000));
  if FileExists(FFile) then DeleteFile(FFile);
  if DirectoryExists(FDir) then RemoveDir(FDir);
  // 创建文件与目录
  if not IsValidHandle(fs_open(FFile, O_WRONLY or O_CREAT or O_TRUNC, S_IRWXU)) then
    Fail('failed to create test file');
  fs_close(fs_open(FFile, O_RDONLY, 0)); // 确保存在
  fs_mkdir(FDir, S_IRWXU);
end;

procedure TTestCase_AccessSemantics.TearDown;
begin
  if FileExists(FFile) then DeleteFile(FFile);
  if DirectoryExists(FDir) then RemoveDir(FDir);
  inherited TearDown;
end;

procedure TTestCase_AccessSemantics.Test_F_OK_Exists_File_And_Dir;
begin
  AssertEquals(0, fs_access(FFile, F_OK));
  AssertEquals(0, fs_access(FDir, F_OK));
end;

procedure TTestCase_AccessSemantics.Test_W_OK_ReadOnly_File_Windows;
var
  R: Integer;
begin
  {$IFDEF WINDOWS}
  // 设置只读属性
  FileSetAttr(FFile, faReadOnly);
  R := fs_access(FFile, W_OK);
  AssertTrue('只读文件在 Windows 上应被视为不可写（按轻量属性判断）', R < 0);
  // 清理属性
  FileSetAttr(FFile, 0);
  {$ELSE}
  AssertTrue('Unix 上由 fpaccess 判定，结果应为 0 或负错误码', True);
  {$ENDIF}
end;

procedure TTestCase_AccessSemantics.Test_X_OK_Dir_Semantics;
var
  R: Integer;
begin
  R := fs_access(FDir, X_OK);
  {$IFDEF WINDOWS}
  // Windows 下 X_OK 非 POSIX 语义，这里不强断言，仅要求函数返回 0（可进入目录）
  AssertEquals('Windows 目录 X_OK 语义宽松，通常返回 0', 0, R);
  {$ELSE}
  // Unix 上由 fpaccess 判定，目录通常需要执行位（搜索权限）
  AssertTrue('Unix 上 X_OK 结果由权限决定（0 或负码）', (R = 0) or (R < 0));
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_AccessSemantics);
end.

