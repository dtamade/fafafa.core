{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_errors;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs.errors;

type
  { TTestCase_Errors - 错误分类与辅助判定测试 }
  TTestCase_Errors = class(TTestCase)
  published
    procedure Test_FsErrorKind_Mapping;
    procedure Test_IsHelpers;
  end;

implementation

procedure TTestCase_Errors.Test_FsErrorKind_Mapping;
begin
  // 成功
  AssertTrue(FsErrorKind(0) = fekNone);
  // Not Found
  AssertTrue(FsErrorKind(Ord(FS_ERROR_FILE_NOT_FOUND)) = fekNotFound);
  // Permission
  AssertTrue(FsErrorKind(Ord(FS_ERROR_ACCESS_DENIED)) = fekPermission);
  AssertTrue(FsErrorKind(Ord(FS_ERROR_PERMISSION_DENIED)) = fekPermission);
  // Exists
  AssertTrue(FsErrorKind(Ord(FS_ERROR_FILE_EXISTS)) = fekExists);
  // Invalid
  AssertTrue(FsErrorKind(Ord(FS_ERROR_INVALID_PATH)) = fekInvalid);
  AssertTrue(FsErrorKind(Ord(FS_ERROR_INVALID_PARAMETER)) = fekInvalid);
  AssertTrue(FsErrorKind(Ord(FS_ERROR_INVALID_HANDLE)) = fekInvalid);
  // Disk full
  AssertTrue(FsErrorKind(Ord(FS_ERROR_DISK_FULL)) = fekDiskFull);
  // IO
  AssertTrue(FsErrorKind(Ord(FS_ERROR_IO_ERROR)) = fekIO);
  // Unknown
  AssertTrue(FsErrorKind(-12345) = fekUnknown);
end;

procedure TTestCase_Errors.Test_IsHelpers;
begin
  AssertTrue(IsNotFound(Ord(FS_ERROR_FILE_NOT_FOUND)));
  AssertTrue(IsPermission(Ord(FS_ERROR_ACCESS_DENIED)));
  AssertTrue(IsExists(Ord(FS_ERROR_FILE_EXISTS)));

  AssertFalse(IsNotFound(0));
  AssertFalse(IsPermission(0));
  AssertFalse(IsExists(0));
end;

initialization
  RegisterTest(TTestCase_Errors);
end.

