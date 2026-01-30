{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_errno_mapping;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs.errors;

type
  { TTestCase_ErrnoMapping - 验证 SystemErrorToFsError 的典型映射 }
  TTestCase_ErrnoMapping = class(TTestCase)
  published
    procedure Test_Windows_Mapping_Sample;
    procedure Test_Unix_Mapping_Sample;
  end;

implementation

{$IFDEF WINDOWS}
uses Windows;
{$ELSE}
uses BaseUnix;
{$ENDIF}

procedure TTestCase_ErrnoMapping.Test_Windows_Mapping_Sample;
{$IFDEF WINDOWS}
begin
  // 注意：仅在 Windows 下运行；CI 其他平台将跳过
  AssertEquals(Integer(FS_ERROR_FILE_NOT_FOUND), Integer(SystemErrorToFsError(ERROR_FILE_NOT_FOUND)));
  AssertEquals(Integer(FS_ERROR_FILE_NOT_FOUND), Integer(SystemErrorToFsError(ERROR_PATH_NOT_FOUND)));
  AssertEquals(Integer(FS_ERROR_ACCESS_DENIED), Integer(SystemErrorToFsError(ERROR_ACCESS_DENIED)));
  AssertEquals(Integer(FS_ERROR_ACCESS_DENIED), Integer(SystemErrorToFsError(ERROR_SHARING_VIOLATION)));
  AssertEquals(Integer(FS_ERROR_INVALID_PATH), Integer(SystemErrorToFsError(ERROR_INVALID_NAME)));
  AssertEquals(Integer(FS_ERROR_INVALID_PATH), Integer(SystemErrorToFsError(ERROR_BAD_PATHNAME)));
  AssertEquals(Integer(FS_ERROR_INVALID_PATH), Integer(SystemErrorToFsError(ERROR_FILENAME_EXCED_RANGE)));
  AssertEquals(Integer(FS_ERROR_FILE_EXISTS), Integer(SystemErrorToFsError(ERROR_FILE_EXISTS)));
  AssertEquals(Integer(FS_ERROR_FILE_EXISTS), Integer(SystemErrorToFsError(ERROR_ALREADY_EXISTS)));
  AssertEquals(Integer(FS_ERROR_DIRECTORY_NOT_EMPTY), Integer(SystemErrorToFsError(ERROR_DIR_NOT_EMPTY)));
  AssertEquals(Integer(FS_ERROR_DISK_FULL), Integer(SystemErrorToFsError(ERROR_DISK_FULL)));
  AssertEquals(Integer(FS_ERROR_INVALID_PARAMETER), Integer(SystemErrorToFsError(ERROR_INVALID_PARAMETER)));
  AssertEquals(Integer(FS_ERROR_INVALID_PARAMETER), Integer(SystemErrorToFsError(ERROR_INVALID_HANDLE)));
  AssertEquals(Integer(FS_ERROR_INVALID_PARAMETER), Integer(SystemErrorToFsError(ERROR_NOT_SUPPORTED)));
end;
{$ELSE}
begin
  // 非 Windows 平台跳过
  AssertTrue(True);
end;
{$ENDIF}

procedure TTestCase_ErrnoMapping.Test_Unix_Mapping_Sample;
{$IFNDEF WINDOWS}
begin
  // 注意：仅在 Unix 下运行；Windows 将跳过
  AssertEquals(Integer(FS_ERROR_FILE_NOT_FOUND), Integer(SystemErrorToFsError(ESysENOENT)));
  AssertEquals(Integer(FS_ERROR_ACCESS_DENIED), Integer(SystemErrorToFsError(ESysEACCES)));
  AssertEquals(Integer(FS_ERROR_PERMISSION_DENIED), Integer(SystemErrorToFsError(ESysEPERM)));
  AssertEquals(Integer(FS_ERROR_DISK_FULL), Integer(SystemErrorToFsError(ESysENOSPC)));
  AssertEquals(Integer(FS_ERROR_INVALID_PARAMETER), Integer(SystemErrorToFsError(ESysEINVAL)));
  AssertEquals(Integer(FS_ERROR_FILE_EXISTS), Integer(SystemErrorToFsError(ESysEEXIST)));
  AssertEquals(Integer(FS_ERROR_DIRECTORY_NOT_EMPTY), Integer(SystemErrorToFsError(ESysENOTEMPTY)));
  AssertEquals(Integer(FS_ERROR_INVALID_PATH), Integer(SystemErrorToFsError(ESysENAMETOOLONG)));
  AssertEquals(Integer(FS_ERROR_INVALID_PARAMETER), Integer(SystemErrorToFsError(ESysEXDEV)));
  AssertEquals(Integer(FS_ERROR_INVALID_PARAMETER), Integer(SystemErrorToFsError(ESysENOTDIR)));
  AssertEquals(Integer(FS_ERROR_INVALID_PARAMETER), Integer(SystemErrorToFsError(ESysEISDIR)));
  AssertEquals(Integer(FS_ERROR_ACCESS_DENIED), Integer(SystemErrorToFsError(ESysEBUSY)));
  AssertEquals(Integer(FS_ERROR_INVALID_PARAMETER), Integer(SystemErrorToFsError(ESysETIMEDOUT)));
  AssertEquals(Integer(FS_ERROR_INVALID_PARAMETER), Integer(SystemErrorToFsError(ESysENOTSUP)));
  AssertEquals(Integer(FS_ERROR_INVALID_PARAMETER), Integer(SystemErrorToFsError(ESysEOPNOTSUPP)));
  AssertEquals(Integer(FS_ERROR_IO_ERROR), Integer(SystemErrorToFsError(ESysEIO)));
end;
{$ELSE}
begin
  // Windows 平台跳过
  AssertTrue(True);
end;
{$ENDIF}

initialization
  RegisterTest(TTestCase_ErrnoMapping);
end.

