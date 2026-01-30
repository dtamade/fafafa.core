unit fafafa.core.fs.errors;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.base;  // ✅ FS-001: 引入 ECore 基类

type
  // 文件系统错误代码枚举 (按递增顺序排列)
  TFsErrorCode = (
    FS_ERROR_UNKNOWN = -999,
    FS_ERROR_PERMISSION_DENIED = -10,
    FS_ERROR_IO_ERROR = -9,
    FS_ERROR_INVALID_PARAMETER = -8,
    FS_ERROR_DIRECTORY_NOT_EMPTY = -7,
    FS_ERROR_FILE_EXISTS = -6,
    FS_ERROR_INVALID_PATH = -5,
    FS_ERROR_DISK_FULL = -4,
    FS_ERROR_ACCESS_DENIED = -3,
    FS_ERROR_FILE_NOT_FOUND = -2,
    FS_ERROR_INVALID_HANDLE = -1,
    FS_SUCCESS = 0
  );

  // 文件系统异常类
  EFsError = class(ECore)  // ✅ FS-001: 继承自 ECore
  private
    FErrorCode: TFsErrorCode;
    FSystemErrorCode: Integer;
    FOp: string;
    FPath: string;
    FPath2: string;
  public
    constructor Create(aErrorCode: TFsErrorCode; const aMessage: string; aSystemErrorCode: Integer = 0);
    class function CreateEx(aErrorCode: TFsErrorCode; const aOp, aPath, aPath2, aMessage: string; aSystemErrorCode: Integer = 0): EFsError; static;
    property ErrorCode: TFsErrorCode read FErrorCode;
    property SystemErrorCode: Integer read FSystemErrorCode;
    property Op: string read FOp;
    property Path: string read FPath;
    property Path2: string read FPath2;
  end;

// 错误代码转换函数
function SystemErrorToFsError(aSystemError: Integer): TFsErrorCode;
function FsErrorToString(aErrorCode: TFsErrorCode): string;
function GetLastFsError: TFsErrorCode;

// 构建模式：低层是否已返回统一的 TFsErrorCode（通过条件编译控制，默认 False）
function FsLowLevelReturnsUnified: Boolean;

// 错误分类辅助（高层判定）
type
  TFsErrorKind = (
    fekNone,
    fekNotFound,
    fekPermission,
    fekExists,
    fekInvalid,
    fekDiskFull,
    fekIO,
    fekUnknown
  );

function FsErrorKind(aErrorCode: Integer): TFsErrorKind;
function IsNotFound(aErrorCode: Integer): Boolean;
function IsPermission(aErrorCode: Integer): Boolean;
function IsExists(aErrorCode: Integer): Boolean;

// 错误检查辅助函数
procedure CheckFsResult(aResult: Integer; const aOperation: string);
procedure CheckFsResultEx(aResult: Integer; const aOperation, aPath, aPath2: string);
function IsValidHandle(aHandle: THandle): Boolean;

implementation

{$IFDEF WINDOWS}
uses Windows, fafafa.core.fs;
{$ELSE}
uses BaseUnix;
{$ENDIF}

constructor EFsError.Create(aErrorCode: TFsErrorCode; const aMessage: string; aSystemErrorCode: Integer);
begin
  inherited Create(aMessage);
  FErrorCode := aErrorCode;
  FSystemErrorCode := aSystemErrorCode;
  FOp := '';
  FPath := '';
  FPath2 := '';
end;

class function EFsError.CreateEx(aErrorCode: TFsErrorCode; const aOp, aPath, aPath2, aMessage: string; aSystemErrorCode: Integer): EFsError;
begin
  Result := EFsError.Create(aErrorCode, aMessage, aSystemErrorCode);
  Result.FOp := aOp;
  Result.FPath := aPath;
  Result.FPath2 := aPath2;
end;

function SystemErrorToFsError(aSystemError: Integer): TFsErrorCode;
begin
  {$IFDEF WINDOWS}
  case aSystemError of
    ERROR_SUCCESS: Result := FS_SUCCESS;
    ERROR_FILE_NOT_FOUND, ERROR_PATH_NOT_FOUND: Result := FS_ERROR_FILE_NOT_FOUND;
    ERROR_ACCESS_DENIED, ERROR_SHARING_VIOLATION: Result := FS_ERROR_ACCESS_DENIED;
    ERROR_DISK_FULL, ERROR_HANDLE_DISK_FULL: Result := FS_ERROR_DISK_FULL;
    ERROR_INVALID_NAME, ERROR_BAD_PATHNAME, ERROR_FILENAME_EXCED_RANGE: Result := FS_ERROR_INVALID_PATH;
    ERROR_FILE_EXISTS, ERROR_ALREADY_EXISTS: Result := FS_ERROR_FILE_EXISTS;
    ERROR_DIR_NOT_EMPTY: Result := FS_ERROR_DIRECTORY_NOT_EMPTY;
    ERROR_INVALID_PARAMETER, ERROR_INVALID_HANDLE, ERROR_NOT_SUPPORTED: Result := FS_ERROR_INVALID_PARAMETER;
  else
    Result := FS_ERROR_UNKNOWN;
  end;
  {$ELSE}
  case aSystemError of
    0: Result := FS_SUCCESS;
    ESysENOENT: Result := FS_ERROR_FILE_NOT_FOUND;
    ESysEACCES: Result := FS_ERROR_ACCESS_DENIED;
    ESysEPERM: Result := FS_ERROR_PERMISSION_DENIED;
    ESysENOSPC: Result := FS_ERROR_DISK_FULL;
    ESysEINVAL: Result := FS_ERROR_INVALID_PARAMETER;
    ESysEEXIST: Result := FS_ERROR_FILE_EXISTS;
    ESysENOTEMPTY: Result := FS_ERROR_DIRECTORY_NOT_EMPTY;
    ESysENAMETOOLONG: Result := FS_ERROR_INVALID_PATH;
    ESysEXDEV: Result := FS_ERROR_INVALID_PARAMETER;
    ESysENOTDIR, ESysEISDIR: Result := FS_ERROR_INVALID_PARAMETER;
    ESysEBUSY: Result := FS_ERROR_ACCESS_DENIED;
    ESysETIMEDOUT: Result := FS_ERROR_INVALID_PARAMETER;
    {$if declared(ESysENOTSUP)}
      {$if ESysENOTSUP <> ESysEOPNOTSUPP}
    ESysENOTSUP: Result := FS_ERROR_INVALID_PARAMETER;
      {$endif}
    {$endif}
    ESysEOPNOTSUPP: Result := FS_ERROR_INVALID_PARAMETER;
    ESysEIO: Result := FS_ERROR_IO_ERROR;
  else
    Result := FS_ERROR_UNKNOWN;
  end;
  {$ENDIF}
end;

function FsErrorToString(aErrorCode: TFsErrorCode): string;
begin
  case aErrorCode of
    FS_SUCCESS: Result := 'Success';
    FS_ERROR_INVALID_HANDLE: Result := 'Invalid file handle';
    FS_ERROR_FILE_NOT_FOUND: Result := 'File or directory not found';
    FS_ERROR_ACCESS_DENIED: Result := 'Access denied';
    FS_ERROR_DISK_FULL: Result := 'Disk full';
    FS_ERROR_INVALID_PATH: Result := 'Invalid path';
    FS_ERROR_FILE_EXISTS: Result := 'File already exists';
    FS_ERROR_DIRECTORY_NOT_EMPTY: Result := 'Directory not empty';
    FS_ERROR_INVALID_PARAMETER: Result := 'Invalid parameter';
    FS_ERROR_IO_ERROR: Result := 'I/O error';
    FS_ERROR_PERMISSION_DENIED: Result := 'Permission denied';
  else
    Result := 'Unknown error';
  end;
end;

function GetLastFsError: TFsErrorCode;
begin
  {$IFDEF WINDOWS}
  // 使用保存的错误代码，避免被其他调用清除
  Result := SystemErrorToFsError(GetSavedFsErrorCode());
  {$ELSE}
  Result := SystemErrorToFsError(fpgeterrno);
  {$ENDIF}
end;

function FsLowLevelReturnsUnified: Boolean;
begin
  {$IFDEF FS_UNIFIED_ERRORS}
  Result := True;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function FsErrorKind(aErrorCode: Integer): TFsErrorKind;
var
  LFs: TFsErrorCode;
begin
  // aErrorCode 可能是负错误码，也可能是0/正数（成功）。
  if aErrorCode >= 0 then
  begin
    Result := fekNone;
    Exit;
  end;
  LFs := TFsErrorCode(aErrorCode);
  case LFs of
    FS_ERROR_FILE_NOT_FOUND: Result := fekNotFound;
    FS_ERROR_ACCESS_DENIED, FS_ERROR_PERMISSION_DENIED: Result := fekPermission;
    FS_ERROR_FILE_EXISTS: Result := fekExists;
    FS_ERROR_INVALID_PATH, FS_ERROR_INVALID_PARAMETER, FS_ERROR_INVALID_HANDLE: Result := fekInvalid;
    FS_ERROR_DISK_FULL: Result := fekDiskFull;
    FS_ERROR_IO_ERROR: Result := fekIO;
  else
    Result := fekUnknown;
  end;
end;

function IsNotFound(aErrorCode: Integer): Boolean;
begin
  Result := FsErrorKind(aErrorCode) = fekNotFound;
end;

function IsPermission(aErrorCode: Integer): Boolean;
begin
  Result := FsErrorKind(aErrorCode) = fekPermission;
end;

function IsExists(aErrorCode: Integer): Boolean;
begin
  Result := FsErrorKind(aErrorCode) = fekExists;
end;

procedure CheckFsResult(aResult: Integer; const aOperation: string);
var
  LErrorCode: TFsErrorCode;
  LMessage: string;
begin
  if aResult < 0 then
  begin
    LErrorCode := TFsErrorCode(aResult);
    LMessage := Format('Operation "%s" failed: %s', [aOperation, FsErrorToString(LErrorCode)]);
    raise EFsError.Create(LErrorCode, LMessage, -aResult);
  end;
end;

procedure CheckFsResultEx(aResult: Integer; const aOperation, aPath, aPath2: string);
var
  LErrorCode: TFsErrorCode;
  LMessage: string;
begin
  if aResult < 0 then
  begin
    LErrorCode := TFsErrorCode(aResult);
    if aPath2 <> '' then
      LMessage := Format('%s("%s" -> "%s") failed: %s', [aOperation, aPath, aPath2, FsErrorToString(LErrorCode)])
    else if aPath <> '' then
      LMessage := Format('%s("%s") failed: %s', [aOperation, aPath, FsErrorToString(LErrorCode)])
    else
      LMessage := Format('Operation "%s" failed: %s', [aOperation, FsErrorToString(LErrorCode)]);
    raise EFsError.CreateEx(LErrorCode, aOperation, aPath, aPath2, LMessage, -aResult);
  end;
end;

function IsValidHandle(aHandle: THandle): Boolean;
begin
  {$IFDEF WINDOWS}
  Result := (aHandle <> THandle(INVALID_HANDLE_VALUE)) and (aHandle <> 0);
  {$ELSE}
  Result := Integer(aHandle) >= 0;
  {$ENDIF}
end;

end.
