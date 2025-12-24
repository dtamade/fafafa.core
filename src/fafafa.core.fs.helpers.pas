unit fafafa.core.fs.helpers;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

{**
 * fafafa.core.fs.helpers - 文件系统辅助函数
 *
 * 提供封装 fs_stat/fs_lstat 的便捷函数，消除代码重复。
 * 所有函数返回 Boolean，避免调用方重复检查错误码。
 *
 * @author Claude Code (技术债务修复)
 * @date 2025-12-23
 *}

interface

uses
  fafafa.core.fs;

type
  // 文件类型枚举（简化版）
  TFsFileType = (
    ftUnknown,    // 未知或不存在
    ftFile,       // 普通文件
    ftDirectory,  // 目录
    ftSymlink,    // 符号链接
    ftDevice,     // 设备文件
    ftPipe,       // 管道
    ftSocket      // 套接字
  );

// ===== 文件类型检查（跟随符号链接）=====

{** 检查路径是否为普通文件（跟随符号链接）*}
function FsIsFile(const aPath: string): Boolean;

{** 检查路径是否为目录（跟随符号链接）*}
function FsIsDirectory(const aPath: string): Boolean;

{** 检查路径是否存在（跟随符号链接）*}
function FsExists(const aPath: string): Boolean;

{** 获取文件类型（跟随符号链接）*}
function FsGetFileType(const aPath: string): TFsFileType;

// ===== 文件类型检查（不跟随符号链接）=====

{** 检查路径是否为符号链接 *}
function FsIsSymlink(const aPath: string): Boolean;

{** 检查路径是否为普通文件（不跟随符号链接）*}
function FsIsFileLstat(const aPath: string): Boolean;

{** 检查路径是否为目录（不跟随符号链接）*}
function FsIsDirectoryLstat(const aPath: string): Boolean;

{** 检查路径是否存在（不跟随符号链接）*}
function FsExistsLstat(const aPath: string): Boolean;

{** 获取文件类型（不跟随符号链接）*}
function FsGetFileTypeLstat(const aPath: string): TFsFileType;

// ===== 安全 Stat 封装 =====

{** 安全获取文件状态（跟随符号链接），成功返回 True *}
function FsStatSafe(const aPath: string; out aStat: TfsStat): Boolean;

{** 安全获取文件状态（不跟随符号链接），成功返回 True *}
function FsLstatSafe(const aPath: string; out aStat: TfsStat): Boolean;

// ===== 文件属性获取 =====

{** 获取文件大小，失败返回 -1 *}
function FsGetFileSize(const aPath: string): Int64;

{** 获取文件大小（通过句柄），失败返回 -1 *}
function FsGetFileSizeByHandle(aHandle: TfsFile): Int64;

{** 检查文件模式是否匹配指定类型 *}
function FsCheckMode(aMode: UInt64; aExpectedType: UInt64): Boolean; inline;

implementation

// ===== 内部辅助函数 =====

function ModeToFileType(aMode: UInt64): TFsFileType;
begin
  case aMode and S_IFMT of
    S_IFREG:  Result := ftFile;
    S_IFDIR:  Result := ftDirectory;
    S_IFLNK:  Result := ftSymlink;
    {$IFDEF UNIX}
    S_IFCHR,
    S_IFBLK:  Result := ftDevice;
    S_IFIFO:  Result := ftPipe;
    S_IFSOCK: Result := ftSocket;
    {$ENDIF}
  else
    Result := ftUnknown;
  end;
end;

// ===== 文件类型检查（跟随符号链接）=====

function FsIsFile(const aPath: string): Boolean;
var
  LStat: TfsStat;
begin
  Result := (fs_stat(aPath, LStat) = 0) and ((LStat.Mode and S_IFMT) = S_IFREG);
end;

function FsIsDirectory(const aPath: string): Boolean;
var
  LStat: TfsStat;
begin
  Result := (fs_stat(aPath, LStat) = 0) and ((LStat.Mode and S_IFMT) = S_IFDIR);
end;

function FsExists(const aPath: string): Boolean;
var
  LStat: TfsStat;
begin
  Result := fs_stat(aPath, LStat) = 0;
end;

function FsGetFileType(const aPath: string): TFsFileType;
var
  LStat: TfsStat;
begin
  if fs_stat(aPath, LStat) = 0 then
    Result := ModeToFileType(LStat.Mode)
  else
    Result := ftUnknown;
end;

// ===== 文件类型检查（不跟随符号链接）=====

function FsIsSymlink(const aPath: string): Boolean;
var
  LStat: TfsStat;
begin
  Result := (fs_lstat(aPath, LStat) = 0) and ((LStat.Mode and S_IFMT) = S_IFLNK);
end;

function FsIsFileLstat(const aPath: string): Boolean;
var
  LStat: TfsStat;
begin
  Result := (fs_lstat(aPath, LStat) = 0) and ((LStat.Mode and S_IFMT) = S_IFREG);
end;

function FsIsDirectoryLstat(const aPath: string): Boolean;
var
  LStat: TfsStat;
begin
  Result := (fs_lstat(aPath, LStat) = 0) and ((LStat.Mode and S_IFMT) = S_IFDIR);
end;

function FsExistsLstat(const aPath: string): Boolean;
var
  LStat: TfsStat;
begin
  Result := fs_lstat(aPath, LStat) = 0;
end;

function FsGetFileTypeLstat(const aPath: string): TFsFileType;
var
  LStat: TfsStat;
begin
  if fs_lstat(aPath, LStat) = 0 then
    Result := ModeToFileType(LStat.Mode)
  else
    Result := ftUnknown;
end;

// ===== 安全 Stat 封装 =====

function FsStatSafe(const aPath: string; out aStat: TfsStat): Boolean;
begin
  Result := fs_stat(aPath, aStat) = 0;
end;

function FsLstatSafe(const aPath: string; out aStat: TfsStat): Boolean;
begin
  Result := fs_lstat(aPath, aStat) = 0;
end;

// ===== 文件属性获取 =====

function FsGetFileSize(const aPath: string): Int64;
var
  LStat: TfsStat;
begin
  if fs_stat(aPath, LStat) = 0 then
    Result := LStat.Size
  else
    Result := -1;
end;

function FsGetFileSizeByHandle(aHandle: TfsFile): Int64;
var
  LStat: TfsStat;
begin
  if fs_fstat(aHandle, LStat) = 0 then
    Result := LStat.Size
  else
    Result := -1;
end;

function FsCheckMode(aMode: UInt64; aExpectedType: UInt64): Boolean;
begin
  Result := (aMode and S_IFMT) = aExpectedType;
end;

end.
