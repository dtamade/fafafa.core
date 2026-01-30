unit fafafa.core.fs.fileobj;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$modeswitch advancedrecords}

{!
  fafafa.core.fs.file - Rust 风格的 File 包装类

  对标 Rust std::fs::File，提供：
  - TFile: 文件句柄包装类（自动关闭）
  - 读写方法：Read, Write, ReadAll, WriteAll
  - 定位方法：Seek, Tell, Rewind
  - 同步方法：Sync, SyncData
  - 元数据：Metadata, SetLen, SetPermissions

  用法示例：
    var
      F: TFile;
      Data: TBytes;
    begin
      // 打开文件读取
      F := TFile.Open('data.bin');
      try
        Data := F.ReadAll;
        WriteLn('Size: ', F.Metadata.Size);
      finally
        F.Free;  // 自动关闭句柄
      end;

      // 创建文件写入
      F := TFile.Create_('output.txt');
      try
        F.WriteString('Hello, World!');
        F.Sync;
      finally
        F.Free;
      end;
    end;
}

interface

uses
  SysUtils, Classes,
  fafafa.core.fs,
  fafafa.core.fs.errors,
  fafafa.core.fs.types,
  fafafa.core.fs.open,
  fafafa.core.fs.traits;

type
  // ============================================================================
  // TFile - 文件包装类
  // ============================================================================
  // 对标 Rust std::fs::File
  // 实现 IFsRead, IFsWrite, IFsSeek, IFsReadWrite 接口
  // 注意：手动管理生命周期，不使用接口引用计数自动释放
  TFile = class(TInterfacedObject, IFsRead, IFsWrite, IFsSeek, IFsReadWrite)
  private
    FHandle: TfsFile;
    FPath: string;
    FOwnsHandle: Boolean;
    function GetIsOpen: Boolean;
  protected
    // 禁用引用计数自动释放，使用手动内存管理
    function _AddRef: LongInt; {$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
    function _Release: LongInt; {$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
  public
    // 构造/析构
    constructor Create(AHandle: TfsFile; const APath: string = ''; AOwnsHandle: Boolean = True);
    destructor Destroy; override;

    // 静态工厂方法
    class function Open(const APath: string): TFile; static;
    class function Create_(const APath: string): TFile; static;
    class function CreateNew(const APath: string): TFile; static;
    class function OpenReadWrite(const APath: string): TFile; static;
    class function OpenAppend(const APath: string): TFile; static;
    class function WithOptions(const APath: string; const AOptions: TFsOpenOptionsBuilder): TFile; static;

    // 读取方法
    function Read(var ABuffer; ACount: Integer): Integer;
    function ReadBytes(ACount: Integer): TBytes;
    function ReadAll: TBytes;
    function ReadString: string;
    function ReadLine: string;

    // 写入方法
    function Write(const ABuffer; ACount: Integer): Integer;
    function WriteBytes(const AData: TBytes): Integer;
    function WriteString(const AStr: string): Integer;
    function WriteLn(const AStr: string = ''): Integer;
    procedure WriteAll(const AData: TBytes);

    // 定位方法
    function Seek(AOffset: Int64; AOrigin: Integer = SEEK_SET): Int64;
    function Tell: Int64;
    function Position: Int64;  // IFsSeek 接口要求，等同于 Tell
    procedure Rewind;
    function SeekEnd: Int64;

    // 同步方法
    procedure Sync;
    procedure SyncData;
    procedure Flush;  // IFsWrite 接口要求

    // 截断
    procedure SetLen(ALen: Int64);
    procedure Truncate;  // 从当前位置截断

    // 元数据
    function Metadata: TFsMetadata;
    function Size: Int64;
    procedure SetPermissions(AMode: UInt32);

    // 复制
    function TryClone: TFile;

    // 句柄访问
    property Handle: TfsFile read FHandle;
    property Path: string read FPath;
    property IsOpen: Boolean read GetIsOpen;

    // 关闭（通常不需要手动调用，析构时自动关闭）
    procedure Close;
  end;

// ============================================================================
// 便捷函数（对标 Rust std::fs 模块函数）
// ============================================================================

// 读取整个文件
function FsRead(const APath: string): TBytes;
function FsReadToString(const APath: string): string;

// 写入整个文件
procedure FsWrite(const APath: string; const AData: TBytes);
procedure FsWriteString(const APath: string; const AStr: string);

// 追加到文件
procedure FsAppend(const APath: string; const AData: TBytes);
procedure FsAppendString(const APath: string; const AStr: string);

// 复制文件
procedure FsCopy(const ASrc, ADst: string);
function FsTryCopy(const ASrc, ADst: string): Integer;

// 重命名/移动文件
procedure FsRename(const ASrc, ADst: string);
function FsTryRename(const ASrc, ADst: string): Integer;

// 删除文件
procedure FsRemoveFile(const APath: string);
function FsTryRemoveFile(const APath: string): Integer;

// 创建目录
procedure FsCreateDir(const APath: string);
procedure FsCreateDirAll(const APath: string);
function FsTryCreateDir(const APath: string): Integer;

// 删除目录
procedure FsRemoveDir(const APath: string);
function FsTryRemoveDir(const APath: string): Integer;

// 符号链接
procedure FsSymlink(const ATarget, ALink: string);
procedure FsHardLink(const ASrc, ADst: string);
function FsReadLink(const APath: string): string;

// 权限
function FsMetadata(const APath: string): TFsMetadata;
procedure FsSetPermissions(const APath: string; AMode: UInt32);

// 规范化路径
function FsCanonicalize(const APath: string): string;

implementation

// ============================================================================
// TFile
// ============================================================================

function TFile._AddRef: LongInt; {$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
begin
  // 不使用引用计数，返回 -1 表示禁用
  Result := -1;
end;

function TFile._Release: LongInt; {$IFNDEF WINDOWS}cdecl{$ELSE}stdcall{$ENDIF};
begin
  // 不使用引用计数，不自动释放
  Result := -1;
end;

constructor TFile.Create(AHandle: TfsFile; const APath: string; AOwnsHandle: Boolean);
begin
  inherited Create;
  FHandle := AHandle;
  FPath := APath;
  FOwnsHandle := AOwnsHandle;
end;

destructor TFile.Destroy;
begin
  if FOwnsHandle and IsValidHandle(FHandle) then
    fs_close(FHandle);
  inherited Destroy;
end;

function TFile.GetIsOpen: Boolean;
begin
  Result := IsValidHandle(FHandle);
end;

class function TFile.Open(const APath: string): TFile;
var
  H: TfsFile;
begin
  H := TFsOpenOptionsBuilder.ForReading.Open(APath);
  Result := TFile.Create(H, APath);
end;

class function TFile.Create_(const APath: string): TFile;
var
  H: TfsFile;
begin
  H := TFsOpenOptionsBuilder.ForWriting.Open(APath);
  Result := TFile.Create(H, APath);
end;

class function TFile.CreateNew(const APath: string): TFile;
var
  H: TfsFile;
begin
  H := TFsOpenOptionsBuilder.ForCreating.Open(APath);
  Result := TFile.Create(H, APath);
end;

class function TFile.OpenReadWrite(const APath: string): TFile;
var
  H: TfsFile;
begin
  H := TFsOpenOptionsBuilder.ForReadWrite.Open(APath);
  Result := TFile.Create(H, APath);
end;

class function TFile.OpenAppend(const APath: string): TFile;
var
  H: TfsFile;
begin
  H := TFsOpenOptionsBuilder.ForAppending.Open(APath);
  Result := TFile.Create(H, APath);
end;

class function TFile.WithOptions(const APath: string; const AOptions: TFsOpenOptionsBuilder): TFile;
var
  H: TfsFile;
begin
  H := AOptions.Open(APath);
  Result := TFile.Create(H, APath);
end;

function TFile.Read(var ABuffer; ACount: Integer): Integer;
begin
  Result := fs_read(FHandle, @ABuffer, ACount, -1);
  if Result < 0 then
    raise EFsError.Create(TFsErrorCode(Result), 'Read failed', -Result);
end;

function TFile.ReadBytes(ACount: Integer): TBytes;
var
  N: Integer;
begin
  SetLength(Result, ACount);
  if ACount = 0 then Exit;
  N := fs_read(FHandle, @Result[0], ACount, -1);
  if N < 0 then
    raise EFsError.Create(TFsErrorCode(N), 'Read failed', -N);
  if N < ACount then
    SetLength(Result, N);
end;

function TFile.ReadAll: TBytes;
var
  LSize, LPos: Int64;
  N: Integer;
begin
  LPos := Tell;
  LSize := Size - LPos;
  if LSize <= 0 then
  begin
    SetLength(Result, 0);
    Exit;
  end;
  SetLength(Result, LSize);
  N := fs_read(FHandle, @Result[0], LSize, -1);
  if N < 0 then
    raise EFsError.Create(TFsErrorCode(N), 'ReadAll failed', -N);
  if N < LSize then
    SetLength(Result, N);
end;

function TFile.ReadString: string;
var
  Data: TBytes;
begin
  Data := ReadAll;
  if Length(Data) = 0 then
    Result := ''
  else
    SetString(Result, PAnsiChar(@Data[0]), Length(Data));
end;

function TFile.ReadLine: string;
var
  C: Char;
  N: Integer;
begin
  Result := '';
  repeat
    N := fs_read(FHandle, @C, 1, -1);
    if N <= 0 then Break;
    if C = #10 then Break;
    if C <> #13 then
      Result := Result + C;
  until False;
end;

function TFile.Write(const ABuffer; ACount: Integer): Integer;
begin
  Result := fs_write(FHandle, @ABuffer, ACount, -1);
  if Result < 0 then
    raise EFsError.Create(TFsErrorCode(Result), 'Write failed', -Result);
end;

function TFile.WriteBytes(const AData: TBytes): Integer;
begin
  if Length(AData) = 0 then
    Exit(0);
  Result := Write(AData[0], Length(AData));
end;

function TFile.WriteString(const AStr: string): Integer;
begin
  if Length(AStr) = 0 then
    Exit(0);
  Result := Write(AStr[1], Length(AStr));
end;

function TFile.WriteLn(const AStr: string): Integer;
const
  LF: Char = #10;
begin
  Result := WriteString(AStr);
  Inc(Result, Write(LF, 1));
end;

procedure TFile.WriteAll(const AData: TBytes);
var
  Written, Total, N: Integer;
begin
  Total := Length(AData);
  Written := 0;
  while Written < Total do
  begin
    N := fs_write(FHandle, @AData[Written], Total - Written, -1);
    if N < 0 then
      raise EFsError.Create(TFsErrorCode(N), 'WriteAll failed', -N);
    if N = 0 then
      raise EFsError.Create(FS_ERROR_IO_ERROR, 'WriteAll: unexpected zero bytes written', 0);
    Inc(Written, N);
  end;
end;

function TFile.Seek(AOffset: Int64; AOrigin: Integer): Int64;
begin
  Result := fs_seek(FHandle, AOffset, AOrigin);
  if Result < 0 then
    raise EFsError.Create(TFsErrorCode(Result), 'Seek failed', -Result);
end;

function TFile.Tell: Int64;
begin
  Result := fs_tell(FHandle);
  if Result < 0 then
    raise EFsError.Create(TFsErrorCode(Result), 'Tell failed', -Result);
end;

procedure TFile.Rewind;
begin
  Seek(0, SEEK_SET);
end;

function TFile.SeekEnd: Int64;
begin
  Result := Seek(0, SEEK_END);
end;

procedure TFile.Sync;
begin
  CheckFsResult(fs_fsync(FHandle), 'Sync');
end;

procedure TFile.SyncData;
begin
  // On most Unix systems, fsync syncs both data and metadata
  // On some systems there's fdatasync for data-only sync
  // For now, just use fsync
  Sync;
end;

procedure TFile.Flush;
begin
  // TFile 是无缓冲的，Flush 直接调用 Sync
  Sync;
end;

function TFile.Position: Int64;
begin
  Result := Tell;
end;

procedure TFile.SetLen(ALen: Int64);
begin
  CheckFsResult(fs_ftruncate(FHandle, ALen), 'SetLen');
end;

procedure TFile.Truncate;
var
  Pos: Int64;
begin
  Pos := Tell;
  SetLen(Pos);
end;

function TFile.Metadata: TFsMetadata;
begin
  Result := TFsMetadata.FromHandle(FHandle);
end;

function TFile.Size: Int64;
var
  S: TfsStat;
begin
  if fs_fstat(FHandle, S) = 0 then
    Result := S.Size
  else
    Result := -1;
end;

procedure TFile.SetPermissions(AMode: UInt32);
begin
  CheckFsResult(fs_fchmod(FHandle, AMode), 'SetPermissions');
end;

function TFile.TryClone: TFile;
begin
  // Clone is not directly supported via dup()
  // For now, return nil to indicate not supported
  Result := nil;
end;

procedure TFile.Close;
begin
  if IsValidHandle(FHandle) then
  begin
    fs_close(FHandle);
    FHandle := INVALID_HANDLE_VALUE;
  end;
end;

// ============================================================================
// 便捷函数
// ============================================================================

function FsRead(const APath: string): TBytes;
var
  F: TFile;
begin
  F := TFile.Open(APath);
  try
    Result := F.ReadAll;
  finally
    F.Free;
  end;
end;

function FsReadToString(const APath: string): string;
var
  F: TFile;
begin
  F := TFile.Open(APath);
  try
    Result := F.ReadString;
  finally
    F.Free;
  end;
end;

procedure FsWrite(const APath: string; const AData: TBytes);
var
  F: TFile;
begin
  F := TFile.Create_(APath);
  try
    F.WriteAll(AData);
  finally
    F.Free;
  end;
end;

procedure FsWriteString(const APath: string; const AStr: string);
var
  F: TFile;
begin
  F := TFile.Create_(APath);
  try
    F.WriteString(AStr);
  finally
    F.Free;
  end;
end;

procedure FsAppend(const APath: string; const AData: TBytes);
var
  F: TFile;
begin
  F := TFile.OpenAppend(APath);
  try
    F.WriteAll(AData);
  finally
    F.Free;
  end;
end;

procedure FsAppendString(const APath: string; const AStr: string);
var
  F: TFile;
begin
  F := TFile.OpenAppend(APath);
  try
    F.WriteString(AStr);
  finally
    F.Free;
  end;
end;

procedure FsCopy(const ASrc, ADst: string);
begin
  CheckFsResult(fs_copyfile(ASrc, ADst, 0), 'Copy');
end;

function FsTryCopy(const ASrc, ADst: string): Integer;
begin
  Result := fs_copyfile(ASrc, ADst, 0);
end;

procedure FsRename(const ASrc, ADst: string);
begin
  CheckFsResult(fs_rename(ASrc, ADst), 'Rename');
end;

function FsTryRename(const ASrc, ADst: string): Integer;
begin
  Result := fs_rename(ASrc, ADst);
end;

procedure FsRemoveFile(const APath: string);
begin
  CheckFsResult(fs_unlink(APath), 'RemoveFile');
end;

function FsTryRemoveFile(const APath: string): Integer;
begin
  Result := fs_unlink(APath);
end;

procedure FsCreateDir(const APath: string);
begin
  CheckFsResult(fs_mkdir(APath, S_IRWXU or S_IRGRP or S_IXGRP or S_IROTH or S_IXOTH), 'CreateDir');
end;

procedure FsCreateDirAll(const APath: string);
var
  Parts: TStringArray;
  I: Integer;
  Current: string;
  R: Integer;
begin
  Parts := APath.Split([PathDelim]);
  Current := '';
  for I := 0 to High(Parts) do
  begin
    if Parts[I] = '' then
    begin
      if I = 0 then
        Current := PathDelim;
      Continue;
    end;
    if Current = '' then
      Current := Parts[I]
    else if Current = PathDelim then
      Current := Current + Parts[I]
    else
      Current := Current + PathDelim + Parts[I];

    R := fs_mkdir(Current, S_IRWXU or S_IRGRP or S_IXGRP or S_IROTH or S_IXOTH);
    // Ignore EEXIST error
    if (R < 0) and (R <> Integer(FS_ERROR_FILE_EXISTS)) then
      CheckFsResult(R, 'CreateDirAll: ' + Current);
  end;
end;

function FsTryCreateDir(const APath: string): Integer;
begin
  Result := fs_mkdir(APath, S_IRWXU or S_IRGRP or S_IXGRP or S_IROTH or S_IXOTH);
end;

procedure FsRemoveDir(const APath: string);
begin
  CheckFsResult(fs_rmdir(APath), 'RemoveDir');
end;

function FsTryRemoveDir(const APath: string): Integer;
begin
  Result := fs_rmdir(APath);
end;

procedure FsSymlink(const ATarget, ALink: string);
begin
  CheckFsResult(fs_symlink(ATarget, ALink), 'Symlink');
end;

procedure FsHardLink(const ASrc, ADst: string);
begin
  CheckFsResult(fs_link(ASrc, ADst), 'HardLink');
end;

function FsReadLink(const APath: string): string;
var
  R: Integer;
begin
  R := fs_readlink_s(APath, Result);
  if R < 0 then
    raise EFsError.Create(TFsErrorCode(R), 'ReadLink failed: ' + APath, -R);
end;

function FsMetadata(const APath: string): TFsMetadata;
begin
  Result := TFsMetadata.FromPath(APath, True);
end;

procedure FsSetPermissions(const APath: string; AMode: UInt32);
begin
  CheckFsResult(fs_chmod(APath, AMode), 'SetPermissions');
end;

function FsCanonicalize(const APath: string): string;
var
  R: Integer;
begin
  R := fs_realpath_s(APath, Result);
  if R < 0 then
    raise EFsError.Create(TFsErrorCode(R), 'Canonicalize failed: ' + APath, -R);
end;

end.
