unit fafafa.core.fs.open;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$modeswitch advancedrecords}

{!
  fafafa.core.fs.open - Rust 风格的 OpenOptions Builder

  对标 Rust std::fs::OpenOptions，提供链式调用 API：

  用法示例：
    var F: TfsFile;
    begin
      // 方式1：链式调用
      F := TFsOpenOptionsBuilder.New
             .Read(True)
             .Write(True)
             .Create(True)
             .Open('foo.txt');

      // 方式2：使用预设
      F := TFsOpenOptionsBuilder.ForReading.Open('foo.txt');
      F := TFsOpenOptionsBuilder.ForWriting.Open('foo.txt');
      F := TFsOpenOptionsBuilder.ForAppending.Open('foo.txt');
    end;
}

interface

uses
  SysUtils,
  fafafa.core.fs,
  fafafa.core.fs.errors;

type
  // ============================================================================
  // TFsOpenOptionsBuilder - OpenOptions Builder 模式
  // ============================================================================
  // 对标 Rust std::fs::OpenOptions
  TFsOpenOptionsBuilder = record
  private
    FRead: Boolean;
    FWrite: Boolean;
    FAppend: Boolean;
    FCreate: Boolean;
    FCreateNew: Boolean;
    FTruncate: Boolean;
    FMode: UInt32;           // Unix 权限模式
    FShareRead: Boolean;     // Windows 共享读
    FShareWrite: Boolean;    // Windows 共享写
    FShareDelete: Boolean;   // Windows 共享删除
  public
    // 构造
    class function New: TFsOpenOptionsBuilder; static;

    // 预设快捷方式
    class function ForReading: TFsOpenOptionsBuilder; static;
    class function ForWriting: TFsOpenOptionsBuilder; static;
    class function ForAppending: TFsOpenOptionsBuilder; static;
    class function ForReadWrite: TFsOpenOptionsBuilder; static;
    class function ForCreating: TFsOpenOptionsBuilder; static;

    // 链式设置方法
    function Read(AValue: Boolean): TFsOpenOptionsBuilder;
    function Write(AValue: Boolean): TFsOpenOptionsBuilder;
    function Append(AValue: Boolean): TFsOpenOptionsBuilder;
    function Create_(AValue: Boolean): TFsOpenOptionsBuilder;  // Create 是保留字
    function CreateNew(AValue: Boolean): TFsOpenOptionsBuilder;
    function Truncate(AValue: Boolean): TFsOpenOptionsBuilder;
    function Mode(AMode: UInt32): TFsOpenOptionsBuilder;
    function ShareRead(AValue: Boolean): TFsOpenOptionsBuilder;
    function ShareWrite(AValue: Boolean): TFsOpenOptionsBuilder;
    function ShareDelete(AValue: Boolean): TFsOpenOptionsBuilder;

    // 执行打开
    function Open(const APath: string): TfsFile;
    function TryOpen(const APath: string; out AHandle: TfsFile): Integer;

    // 转换为底层标志
    function ToFlags: Integer;
    function ToMode: UInt32;
  end;

  // ============================================================================
  // TFsFile 扩展辅助方法
  // ============================================================================
  // 提供静态方法用于快速文件操作

  TFsFileHelper = record
    // 快速打开方法
    class function Open(const APath: string): TfsFile; static;
    class function Create_(const APath: string): TfsFile; static;
    class function CreateNew(const APath: string): TfsFile; static;

    // 使用 Builder 打开
    class function Options: TFsOpenOptionsBuilder; static;
  end;

implementation

const
  // 默认文件权限 0644 = rw-r--r--
  DEFAULT_FILE_MODE = S_IRUSR or S_IWUSR or S_IRGRP or S_IROTH;

// ============================================================================
// TFsOpenOptionsBuilder
// ============================================================================

class function TFsOpenOptionsBuilder.New: TFsOpenOptionsBuilder;
begin
  Result.FRead := False;
  Result.FWrite := False;
  Result.FAppend := False;
  Result.FCreate := False;
  Result.FCreateNew := False;
  Result.FTruncate := False;
  Result.FMode := DEFAULT_FILE_MODE;
  Result.FShareRead := False;
  Result.FShareWrite := False;
  Result.FShareDelete := False;
end;

class function TFsOpenOptionsBuilder.ForReading: TFsOpenOptionsBuilder;
begin
  Result := New;
  Result.FRead := True;
  Result.FShareRead := True;
end;

class function TFsOpenOptionsBuilder.ForWriting: TFsOpenOptionsBuilder;
begin
  Result := New;
  Result.FWrite := True;
  Result.FCreate := True;
  Result.FTruncate := True;
end;

class function TFsOpenOptionsBuilder.ForAppending: TFsOpenOptionsBuilder;
begin
  Result := New;
  Result.FWrite := True;
  Result.FAppend := True;
  Result.FCreate := True;
end;

class function TFsOpenOptionsBuilder.ForReadWrite: TFsOpenOptionsBuilder;
begin
  Result := New;
  Result.FRead := True;
  Result.FWrite := True;
end;

class function TFsOpenOptionsBuilder.ForCreating: TFsOpenOptionsBuilder;
begin
  Result := New;
  Result.FWrite := True;
  Result.FCreate := True;
  Result.FCreateNew := True;
end;

function TFsOpenOptionsBuilder.Read(AValue: Boolean): TFsOpenOptionsBuilder;
begin
  Result := Self;
  Result.FRead := AValue;
end;

function TFsOpenOptionsBuilder.Write(AValue: Boolean): TFsOpenOptionsBuilder;
begin
  Result := Self;
  Result.FWrite := AValue;
end;

function TFsOpenOptionsBuilder.Append(AValue: Boolean): TFsOpenOptionsBuilder;
begin
  Result := Self;
  Result.FAppend := AValue;
end;

function TFsOpenOptionsBuilder.Create_(AValue: Boolean): TFsOpenOptionsBuilder;
begin
  Result := Self;
  Result.FCreate := AValue;
end;

function TFsOpenOptionsBuilder.CreateNew(AValue: Boolean): TFsOpenOptionsBuilder;
begin
  Result := Self;
  Result.FCreateNew := AValue;
end;

function TFsOpenOptionsBuilder.Truncate(AValue: Boolean): TFsOpenOptionsBuilder;
begin
  Result := Self;
  Result.FTruncate := AValue;
end;

function TFsOpenOptionsBuilder.Mode(AMode: UInt32): TFsOpenOptionsBuilder;
begin
  Result := Self;
  Result.FMode := AMode;
end;

function TFsOpenOptionsBuilder.ShareRead(AValue: Boolean): TFsOpenOptionsBuilder;
begin
  Result := Self;
  Result.FShareRead := AValue;
end;

function TFsOpenOptionsBuilder.ShareWrite(AValue: Boolean): TFsOpenOptionsBuilder;
begin
  Result := Self;
  Result.FShareWrite := AValue;
end;

function TFsOpenOptionsBuilder.ShareDelete(AValue: Boolean): TFsOpenOptionsBuilder;
begin
  Result := Self;
  Result.FShareDelete := AValue;
end;

function TFsOpenOptionsBuilder.ToFlags: Integer;
begin
  Result := 0;

  // 读写模式
  if FRead and FWrite then
    Result := O_RDWR
  else if FWrite then
    Result := O_WRONLY
  else if FRead then
    Result := O_RDONLY
  else
    Result := O_RDONLY;  // 默认只读

  // 创建标志
  if FCreate then
    Result := Result or O_CREAT;
  if FCreateNew then
    Result := Result or O_CREAT or O_EXCL;
  if FTruncate then
    Result := Result or O_TRUNC;
  if FAppend then
    Result := Result or O_APPEND;

  // 共享标志 (Windows)
  if FShareRead then
    Result := Result or O_SHARE_READ;
  if FShareWrite then
    Result := Result or O_SHARE_WRITE;
  if FShareDelete then
    Result := Result or O_SHARE_DELETE;
end;

function TFsOpenOptionsBuilder.ToMode: UInt32;
begin
  Result := FMode;
end;

function TFsOpenOptionsBuilder.TryOpen(const APath: string; out AHandle: TfsFile): Integer;
begin
  AHandle := fs_open(APath, ToFlags, ToMode);
  if not IsValidHandle(AHandle) then
  begin
    Result := fs_errno;
    if Result = 0 then
      Result := Integer(FS_ERROR_UNKNOWN);
  end
  else
    Result := 0;
end;

function TFsOpenOptionsBuilder.Open(const APath: string): TfsFile;
var
  LResult: Integer;
begin
  LResult := TryOpen(APath, Result);
  if LResult < 0 then
    raise EFsError.Create(TFsErrorCode(LResult), 'Failed to open file: ' + APath, -LResult);
end;

// ============================================================================
// TFsFileHelper
// ============================================================================

class function TFsFileHelper.Open(const APath: string): TfsFile;
begin
  Result := TFsOpenOptionsBuilder.ForReading.Open(APath);
end;

class function TFsFileHelper.Create_(const APath: string): TfsFile;
begin
  Result := TFsOpenOptionsBuilder.ForWriting.Open(APath);
end;

class function TFsFileHelper.CreateNew(const APath: string): TfsFile;
begin
  Result := TFsOpenOptionsBuilder.ForCreating.Open(APath);
end;

class function TFsFileHelper.Options: TFsOpenOptionsBuilder;
begin
  Result := TFsOpenOptionsBuilder.New;
end;

end.
