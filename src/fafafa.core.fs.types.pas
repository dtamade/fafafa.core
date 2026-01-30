unit fafafa.core.fs.types;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$modeswitch typehelpers}
{$modeswitch advancedrecords}

{!
  fafafa.core.fs.types - 高级文件系统类型抽象

  提供与 Rust std::fs 对齐的现代类型系统：
  - TFsFileType: 文件类型枚举
  - TFsPermissions: 权限记录类型
  - TFsMetadata: 元数据包装类

  设计原则：
  1. 隐藏平台差异，提供统一抽象
  2. 提供便捷的辅助方法
  3. 保持与底层 TfsStat 的兼容性
}

interface

uses
  SysUtils, Classes,
  fafafa.core.fs;

const
  UnixDateDelta = 25569;  // Days between 1899-12-30 and 1970-01-01

type
  // ============================================================================
  // TFsFileType - 文件类型枚举
  // ============================================================================
  // 对标 Rust std::fs::FileType
  TFsFileType = (
    ftRegular,      // 普通文件
    ftDirectory,    // 目录
    ftSymlink,      // 符号链接
    ftBlockDevice,  // 块设备 (Unix)
    ftCharDevice,   // 字符设备 (Unix)
    ftFifo,         // 命名管道 (Unix)
    ftSocket,       // 套接字 (Unix)
    ftUnknown       // 未知类型
  );

  // ============================================================================
  // TFsFileTypeHelper - 文件类型辅助方法
  // ============================================================================
  TFsFileTypeHelper = type helper for TFsFileType
    function IsRegular: Boolean; inline;
    function IsDirectory: Boolean; inline;
    function IsSymlink: Boolean; inline;
    function IsBlockDevice: Boolean; inline;
    function IsCharDevice: Boolean; inline;
    function IsFifo: Boolean; inline;
    function IsSocket: Boolean; inline;
    function ToString: string;
  end;

  // ============================================================================
  // TFsPermissions - 权限记录类型
  // ============================================================================
  // 对标 Rust std::fs::Permissions
  TFsPermissions = record
  private
    FMode: UInt32;
    function GetReadOnly: Boolean;
    function GetOwnerRead: Boolean;
    function GetOwnerWrite: Boolean;
    function GetOwnerExecute: Boolean;
    function GetGroupRead: Boolean;
    function GetGroupWrite: Boolean;
    function GetGroupExecute: Boolean;
    function GetOtherRead: Boolean;
    function GetOtherWrite: Boolean;
    function GetOtherExecute: Boolean;
  public
    // 构造
    class function FromMode(AMode: UInt32): TFsPermissions; static;
    class function Default: TFsPermissions; static;
    class function ReadOnly: TFsPermissions; static;
    class function ReadWrite: TFsPermissions; static;
    class function Executable: TFsPermissions; static;

    // 权限检查
    function IsReadOnly: Boolean;
    function CanRead(AOwner, AGroup, AOther: Boolean): Boolean;
    function CanWrite(AOwner, AGroup, AOther: Boolean): Boolean;
    function CanExecute(AOwner, AGroup, AOther: Boolean): Boolean;

    // 权限修改 (返回新记录，不修改原记录)
    function WithReadOnly(AReadOnly: Boolean): TFsPermissions;
    function WithOwner(ARead, AWrite, AExecute: Boolean): TFsPermissions;
    function WithGroup(ARead, AWrite, AExecute: Boolean): TFsPermissions;
    function WithOther(ARead, AWrite, AExecute: Boolean): TFsPermissions;

    // 转换
    function ToMode: UInt32;
    function ToOctalString: string;
    function ToString: string;

    // 属性
    property Mode: UInt32 read FMode write FMode;
    property OwnerRead: Boolean read GetOwnerRead;
    property OwnerWrite: Boolean read GetOwnerWrite;
    property OwnerExecute: Boolean read GetOwnerExecute;
    property GroupRead: Boolean read GetGroupRead;
    property GroupWrite: Boolean read GetGroupWrite;
    property GroupExecute: Boolean read GetGroupExecute;
    property OtherRead: Boolean read GetOtherRead;
    property OtherWrite: Boolean read GetOtherWrite;
    property OtherExecute: Boolean read GetOtherExecute;
  end;

  // ============================================================================
  // TFsMetadata - 元数据包装类
  // ============================================================================
  // 对标 Rust std::fs::Metadata
  TFsMetadata = class
  private
    FStat: TfsStat;
    FPath: string;
    FValid: Boolean;
  public
    constructor Create; overload;
    constructor Create(const AStat: TfsStat); overload;
    constructor Create(const AStat: TfsStat; const APath: string); overload;

    // 从路径加载
    class function FromPath(const APath: string; AFollowLinks: Boolean = True): TFsMetadata; static;
    class function FromHandle(AHandle: TfsFile): TFsMetadata; static;

    // 文件类型
    function FileType: TFsFileType;
    function IsFile: Boolean;
    function IsDir: Boolean;
    function IsSymlink: Boolean;
    function IsBlockDevice: Boolean;
    function IsCharDevice: Boolean;

    // 大小
    function Size: Int64;
    function SizeOnDisk: Int64;  // 实际占用磁盘空间

    // 时间戳
    function AccessTime: TDateTime;
    function ModifyTime: TDateTime;
    function ChangeTime: TDateTime;
    function AccessTimeUnix: Int64;
    function ModifyTimeUnix: Int64;
    function ChangeTimeUnix: Int64;

    // 权限
    function Permissions: TFsPermissions;
    function ModeRaw: UInt32;

    // 链接信息
    function Inode: UInt64;
    function Device: UInt64;
    function LinkCount: UInt64;

    // 拥有者信息 (Unix)
    function UID: UInt32;
    function GID: UInt32;

    // 块信息 (Unix)
    function BlockSize: Int64;
    function Blocks: Int64;

    // 有效性检查
    function IsValid: Boolean;

    // 原始数据访问
    property RawStat: TfsStat read FStat;
    property Path: string read FPath;
  end;

// ============================================================================
// 便捷函数
// ============================================================================

// 从 Mode 获取文件类型
function FileTypeFromMode(AMode: UInt32): TFsFileType;

// 获取文件元数据
function GetMetadata(const APath: string; AFollowLinks: Boolean = True): TFsMetadata;
function GetSymlinkMetadata(const APath: string): TFsMetadata;

// 权限检查便捷函数
function IsReadOnly(const APath: string): Boolean;
function IsExecutable(const APath: string): Boolean;

implementation

const
  // Unix 文件类型常量
  S_IFMT   = $F000;  // 类型掩码
  S_IFREG  = $8000;  // 普通文件
  S_IFDIR  = $4000;  // 目录
  S_IFLNK  = $A000;  // 符号链接
  S_IFBLK  = $6000;  // 块设备
  S_IFCHR  = $2000;  // 字符设备
  S_IFIFO  = $1000;  // FIFO
  S_IFSOCK = $C000;  // 套接字

  // Unix 权限常量
  S_IRUSR = $0100;  // 用户读
  S_IWUSR = $0080;  // 用户写
  S_IXUSR = $0040;  // 用户执行
  S_IRGRP = $0020;  // 组读
  S_IWGRP = $0010;  // 组写
  S_IXGRP = $0008;  // 组执行
  S_IROTH = $0004;  // 其他读
  S_IWOTH = $0002;  // 其他写
  S_IXOTH = $0001;  // 其他执行

// ============================================================================
// TFsFileTypeHelper
// ============================================================================

function TFsFileTypeHelper.IsRegular: Boolean;
begin
  Result := Self = ftRegular;
end;

function TFsFileTypeHelper.IsDirectory: Boolean;
begin
  Result := Self = ftDirectory;
end;

function TFsFileTypeHelper.IsSymlink: Boolean;
begin
  Result := Self = ftSymlink;
end;

function TFsFileTypeHelper.IsBlockDevice: Boolean;
begin
  Result := Self = ftBlockDevice;
end;

function TFsFileTypeHelper.IsCharDevice: Boolean;
begin
  Result := Self = ftCharDevice;
end;

function TFsFileTypeHelper.IsFifo: Boolean;
begin
  Result := Self = ftFifo;
end;

function TFsFileTypeHelper.IsSocket: Boolean;
begin
  Result := Self = ftSocket;
end;

function TFsFileTypeHelper.ToString: string;
begin
  case Self of
    ftRegular:     Result := 'regular';
    ftDirectory:   Result := 'directory';
    ftSymlink:     Result := 'symlink';
    ftBlockDevice: Result := 'block_device';
    ftCharDevice:  Result := 'char_device';
    ftFifo:        Result := 'fifo';
    ftSocket:      Result := 'socket';
  else
    Result := 'unknown';
  end;
end;

// ============================================================================
// TFsPermissions
// ============================================================================

class function TFsPermissions.FromMode(AMode: UInt32): TFsPermissions;
begin
  Result.FMode := AMode and $1FF;  // 只保留权限位 (低 9 位)
end;

class function TFsPermissions.Default: TFsPermissions;
begin
  // 0644: rw-r--r--
  Result.FMode := S_IRUSR or S_IWUSR or S_IRGRP or S_IROTH;
end;

class function TFsPermissions.ReadOnly: TFsPermissions;
begin
  // 0444: r--r--r--
  Result.FMode := S_IRUSR or S_IRGRP or S_IROTH;
end;

class function TFsPermissions.ReadWrite: TFsPermissions;
begin
  // 0666: rw-rw-rw-
  Result.FMode := S_IRUSR or S_IWUSR or S_IRGRP or S_IWGRP or S_IROTH or S_IWOTH;
end;

class function TFsPermissions.Executable: TFsPermissions;
begin
  // 0755: rwxr-xr-x
  Result.FMode := S_IRUSR or S_IWUSR or S_IXUSR or S_IRGRP or S_IXGRP or S_IROTH or S_IXOTH;
end;

function TFsPermissions.GetReadOnly: Boolean;
begin
  // 只读 = 没有任何写权限
  Result := (FMode and (S_IWUSR or S_IWGRP or S_IWOTH)) = 0;
end;

function TFsPermissions.GetOwnerRead: Boolean;
begin
  Result := (FMode and S_IRUSR) <> 0;
end;

function TFsPermissions.GetOwnerWrite: Boolean;
begin
  Result := (FMode and S_IWUSR) <> 0;
end;

function TFsPermissions.GetOwnerExecute: Boolean;
begin
  Result := (FMode and S_IXUSR) <> 0;
end;

function TFsPermissions.GetGroupRead: Boolean;
begin
  Result := (FMode and S_IRGRP) <> 0;
end;

function TFsPermissions.GetGroupWrite: Boolean;
begin
  Result := (FMode and S_IWGRP) <> 0;
end;

function TFsPermissions.GetGroupExecute: Boolean;
begin
  Result := (FMode and S_IXGRP) <> 0;
end;

function TFsPermissions.GetOtherRead: Boolean;
begin
  Result := (FMode and S_IROTH) <> 0;
end;

function TFsPermissions.GetOtherWrite: Boolean;
begin
  Result := (FMode and S_IWOTH) <> 0;
end;

function TFsPermissions.GetOtherExecute: Boolean;
begin
  Result := (FMode and S_IXOTH) <> 0;
end;

function TFsPermissions.IsReadOnly: Boolean;
begin
  Result := GetReadOnly;
end;

function TFsPermissions.CanRead(AOwner, AGroup, AOther: Boolean): Boolean;
begin
  Result := False;
  if AOwner and OwnerRead then Result := True;
  if AGroup and GroupRead then Result := True;
  if AOther and OtherRead then Result := True;
end;

function TFsPermissions.CanWrite(AOwner, AGroup, AOther: Boolean): Boolean;
begin
  Result := False;
  if AOwner and OwnerWrite then Result := True;
  if AGroup and GroupWrite then Result := True;
  if AOther and OtherWrite then Result := True;
end;

function TFsPermissions.CanExecute(AOwner, AGroup, AOther: Boolean): Boolean;
begin
  Result := False;
  if AOwner and OwnerExecute then Result := True;
  if AGroup and GroupExecute then Result := True;
  if AOther and OtherExecute then Result := True;
end;

function TFsPermissions.WithReadOnly(AReadOnly: Boolean): TFsPermissions;
begin
  Result.FMode := FMode;
  if AReadOnly then
    Result.FMode := Result.FMode and (not (S_IWUSR or S_IWGRP or S_IWOTH))
  else
    Result.FMode := Result.FMode or S_IWUSR;  // 至少给 owner 写权限
end;

function TFsPermissions.WithOwner(ARead, AWrite, AExecute: Boolean): TFsPermissions;
begin
  Result.FMode := FMode and (not (S_IRUSR or S_IWUSR or S_IXUSR));
  if ARead then Result.FMode := Result.FMode or S_IRUSR;
  if AWrite then Result.FMode := Result.FMode or S_IWUSR;
  if AExecute then Result.FMode := Result.FMode or S_IXUSR;
end;

function TFsPermissions.WithGroup(ARead, AWrite, AExecute: Boolean): TFsPermissions;
begin
  Result.FMode := FMode and (not (S_IRGRP or S_IWGRP or S_IXGRP));
  if ARead then Result.FMode := Result.FMode or S_IRGRP;
  if AWrite then Result.FMode := Result.FMode or S_IWGRP;
  if AExecute then Result.FMode := Result.FMode or S_IXGRP;
end;

function TFsPermissions.WithOther(ARead, AWrite, AExecute: Boolean): TFsPermissions;
begin
  Result.FMode := FMode and (not (S_IROTH or S_IWOTH or S_IXOTH));
  if ARead then Result.FMode := Result.FMode or S_IROTH;
  if AWrite then Result.FMode := Result.FMode or S_IWOTH;
  if AExecute then Result.FMode := Result.FMode or S_IXOTH;
end;

function TFsPermissions.ToMode: UInt32;
begin
  Result := FMode;
end;

function TFsPermissions.ToOctalString: string;
begin
  Result := Format('0%o', [FMode]);
end;

function TFsPermissions.ToString: string;
var
  S: string;
begin
  S := '';
  // Owner
  if OwnerRead then S := S + 'r' else S := S + '-';
  if OwnerWrite then S := S + 'w' else S := S + '-';
  if OwnerExecute then S := S + 'x' else S := S + '-';
  // Group
  if GroupRead then S := S + 'r' else S := S + '-';
  if GroupWrite then S := S + 'w' else S := S + '-';
  if GroupExecute then S := S + 'x' else S := S + '-';
  // Other
  if OtherRead then S := S + 'r' else S := S + '-';
  if OtherWrite then S := S + 'w' else S := S + '-';
  if OtherExecute then S := S + 'x' else S := S + '-';
  Result := S;
end;

// ============================================================================
// TFsMetadata
// ============================================================================

constructor TFsMetadata.Create;
begin
  inherited Create;
  FStat := Default(TfsStat);
  FPath := '';
  FValid := False;
end;

constructor TFsMetadata.Create(const AStat: TfsStat);
begin
  inherited Create;
  FStat := AStat;
  FPath := '';
  FValid := True;
end;

constructor TFsMetadata.Create(const AStat: TfsStat; const APath: string);
begin
  inherited Create;
  FStat := AStat;
  FPath := APath;
  FValid := True;
end;

class function TFsMetadata.FromPath(const APath: string; AFollowLinks: Boolean): TFsMetadata;
var
  LStat: TfsStat;
  LResult: Integer;
begin
  LStat := Default(TfsStat);
  if AFollowLinks then
    LResult := fs_stat(APath, LStat)
  else
    LResult := fs_lstat(APath, LStat);

  Result := TFsMetadata.Create;
  Result.FPath := APath;
  if LResult = 0 then
  begin
    Result.FStat := LStat;
    Result.FValid := True;
  end
  else
    Result.FValid := False;
end;

class function TFsMetadata.FromHandle(AHandle: TfsFile): TFsMetadata;
var
  LStat: TfsStat;
  LResult: Integer;
begin
  LStat := Default(TfsStat);
  LResult := fs_fstat(AHandle, LStat);

  Result := TFsMetadata.Create;
  if LResult = 0 then
  begin
    Result.FStat := LStat;
    Result.FValid := True;
  end
  else
    Result.FValid := False;
end;

function TFsMetadata.FileType: TFsFileType;
begin
  Result := FileTypeFromMode(FStat.Mode);
end;

function TFsMetadata.IsFile: Boolean;
begin
  Result := FileType = ftRegular;
end;

function TFsMetadata.IsDir: Boolean;
begin
  Result := FileType = ftDirectory;
end;

function TFsMetadata.IsSymlink: Boolean;
begin
  Result := FileType = ftSymlink;
end;

function TFsMetadata.IsBlockDevice: Boolean;
begin
  Result := FileType = ftBlockDevice;
end;

function TFsMetadata.IsCharDevice: Boolean;
begin
  Result := FileType = ftCharDevice;
end;

function TFsMetadata.Size: Int64;
begin
  Result := FStat.Size;
end;

function TFsMetadata.SizeOnDisk: Int64;
begin
  // blocks * 512 (标准块大小)
  Result := FStat.Blocks * 512;
end;

function TFsMetadata.AccessTime: TDateTime;
begin
  Result := FStat.ATime.Sec / 86400.0 + UnixDateDelta;
end;

function TFsMetadata.ModifyTime: TDateTime;
begin
  Result := FStat.MTime.Sec / 86400.0 + UnixDateDelta;
end;

function TFsMetadata.ChangeTime: TDateTime;
begin
  Result := FStat.CTime.Sec / 86400.0 + UnixDateDelta;
end;

function TFsMetadata.AccessTimeUnix: Int64;
begin
  Result := FStat.ATime.Sec;
end;

function TFsMetadata.ModifyTimeUnix: Int64;
begin
  Result := FStat.MTime.Sec;
end;

function TFsMetadata.ChangeTimeUnix: Int64;
begin
  Result := FStat.CTime.Sec;
end;

function TFsMetadata.Permissions: TFsPermissions;
begin
  Result := TFsPermissions.FromMode(FStat.Mode);
end;

function TFsMetadata.ModeRaw: UInt32;
begin
  Result := FStat.Mode;
end;

function TFsMetadata.Inode: UInt64;
begin
  Result := FStat.Ino;
end;

function TFsMetadata.Device: UInt64;
begin
  Result := FStat.Dev;
end;

function TFsMetadata.LinkCount: UInt64;
begin
  Result := FStat.NLink;
end;

function TFsMetadata.UID: UInt32;
begin
  Result := FStat.UID;
end;

function TFsMetadata.GID: UInt32;
begin
  Result := FStat.GID;
end;

function TFsMetadata.BlockSize: Int64;
begin
  Result := FStat.BlkSize;
end;

function TFsMetadata.Blocks: Int64;
begin
  Result := FStat.Blocks;
end;

function TFsMetadata.IsValid: Boolean;
begin
  Result := FValid;
end;

// ============================================================================
// 便捷函数
// ============================================================================

function FileTypeFromMode(AMode: UInt32): TFsFileType;
var
  LType: UInt32;
begin
  LType := AMode and S_IFMT;
  case LType of
    S_IFREG:  Result := ftRegular;
    S_IFDIR:  Result := ftDirectory;
    S_IFLNK:  Result := ftSymlink;
    S_IFBLK:  Result := ftBlockDevice;
    S_IFCHR:  Result := ftCharDevice;
    S_IFIFO:  Result := ftFifo;
    S_IFSOCK: Result := ftSocket;
  else
    Result := ftUnknown;
  end;
end;

function GetMetadata(const APath: string; AFollowLinks: Boolean): TFsMetadata;
begin
  Result := TFsMetadata.FromPath(APath, AFollowLinks);
end;

function GetSymlinkMetadata(const APath: string): TFsMetadata;
begin
  Result := TFsMetadata.FromPath(APath, False);
end;

function IsReadOnly(const APath: string): Boolean;
var
  Meta: TFsMetadata;
begin
  Meta := TFsMetadata.FromPath(APath, True);
  try
    if Meta.IsValid then
      Result := Meta.Permissions.IsReadOnly
    else
      Result := True;  // 无法访问视为只读
  finally
    Meta.Free;
  end;
end;

function IsExecutable(const APath: string): Boolean;
var
  Meta: TFsMetadata;
begin
  Meta := TFsMetadata.FromPath(APath, True);
  try
    if Meta.IsValid then
      Result := Meta.Permissions.CanExecute(True, True, True)
    else
      Result := False;
  finally
    Meta.Free;
  end;
end;

end.
