unit fafafa.core.fs;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes
  {$IFDEF WINDOWS}
  , Windows
  {$ELSE}
  , BaseUnix, Unix, UnixType
  {$ENDIF};

type
  TfsFile = THandle;

  // 目录条目基础类型（供回调式枚举使用，用于快速判定目录/文件/链接）
  TfsDirEntType = (
    fsDETUnknown = 0,
    fsDETFile    = 1,
    fsDETDir     = 2,
    fsDETSymlink = 3
  );

  // 回调式 scandir 的回调签名（对象方法）
  TfsScandirEachProc = function(const aName: string; aType: TfsDirEntType): Boolean of object;

const
  INVALID_HANDLE_VALUE = THandle(-1);

type
  TTimeSpec = record
    Sec: Int64;
    Nsec: Int64;
  end;

  TfsStat = record
    Dev: UInt64;
    Mode: UInt64;
    NLink: UInt64;
    UID: UInt64;
    GID: UInt64;
    RDev: UInt64;
    Ino: UInt64;
    Size: UInt64;
    BlkSize: UInt64;
    Blocks: UInt64;
    Flags: UInt64;
    Gen: UInt64;
    ATime: TTimeSpec;
    MTime: TTimeSpec;
    CTime: TTimeSpec;
    BTime: TTimeSpec;
  end;
  PfsStat = ^TfsStat;

const
  // Access modes for fs_open
  O_RDONLY = 0;
  O_WRONLY = 1;
  O_RDWR   = 2;
  // Optional flags for fs_open
  O_APPEND = $0008;
  O_CREAT  = $0200;
  O_EXCL   = $0800;
  O_TRUNC  = $0400;

  // Optional sharing flags (Windows maps to CreateFile share mode; ignored on Unix)
  O_SHARE_READ   = $010000;
  O_SHARE_WRITE  = $020000;
  O_SHARE_DELETE = $040000;
  O_SHARE_MASK   = $070000;

const
  // File type flags for TfsStat.Mode field
  S_IFMT   = $F000; // Bit mask for the file type bit fields
  S_IFDIR  = $4000; // Directory
  S_IFREG  = $8000; // Regular file
  S_IFLNK  = $A000; // Symbolic link

  // File permission modes
  S_IRWXU = $0700; S_IRUSR = $0400; S_IWUSR = $0200; S_IXUSR = $0100;
  S_IRWXG = $0070; S_IRGRP = $0040; S_IWGRP = $0020; S_IXGRP = $0010;
  S_IRWXO = $0007; S_IROTH = $0004; S_IWOTH = $0002; S_IXOTH = $0001;

const
  UV_FS_COPYFILE_EXCL = 1;

  // Seek whence constants
  SEEK_SET = 0;  // 从文件开始位置
  SEEK_CUR = 1;  // 从当前位置
  SEEK_END = 2;  // 从文件结束位置

  // Access mode constants for fs_access
  F_OK = 0;  // 文件存在
  R_OK = 4;  // 可读
  W_OK = 2;  // 可写
  X_OK = 1;  // 可执行

  // File locking constants
  LOCK_SH = 1;  // 共享锁
  LOCK_EX = 2;  // 排他锁
  LOCK_NB = 4;  // 非阻塞
  LOCK_UN = 8;  // 解锁

// --- API Functions ---

{**
 * fs_open
 *
 * @desc
 *   打开或创建一个文件, 返回文件句柄.
 *
 * @params
 *   aPath  要打开的文件的路径.
 *   aFlags  文件打开标志, 由 O_* 常量进行位或操作构成.
 *   aMode   文件权限模式 (仅在创建文件时于 Unix 系统上生效).
 *
 * @return
 *   成功时返回有效文件句柄, 失败时返回 INVALID_HANDLE_VALUE。
 *   注意：错误码可通过（Windows）GetSavedFsErrorCode() 获取系统错误，再用 SystemErrorToFsError() 统一为 TFsErrorCode；
 *         或在启用 FS_UNIFIED_ERRORS 时直接使用统一负错误码（不改变返回句柄规则）。
 *}
function fs_open(const aPath: string; aFlags, aMode: Integer): TfsFile;

{**
 * fs_close
 *
 * @desc
 *   关闭一个已打开的文件句柄.
 *
 * @params
 *   aFile  要关闭的文件句柄.
 *
 * @return
 *   成功时返回 0, 失败时返回一个负值的错误码.
 *}
function fs_close(aFile: TfsFile): Integer;

{**
 * fs_read
 *
 * @desc
 *   从一个文件句柄读取数据.
 *
 * @params
 *   aFile    要读取的文件句柄.
 *   aBuffer  用于存放读取数据的缓冲区指针.
 *   aLength  要读取的最大字节数.
 *   aOffset  文件内的读取起始偏移量. 如果为 -1, 则从当前文件位置读取.
 *
 * @return
 *   成功时返回实际读取的字节数 (0 表示已到文件末尾).
 *   失败时返回一个负值的错误码.
 *}
function fs_read(aFile: TfsFile; const aBuffer: Pointer; aLength: SizeUInt; aOffset: Int64): Integer;

{**
 * fs_write
 *
 * @desc
 *   向一个文件句柄写入数据.
 *
 * @params
 *   aFile    要写入的文件句柄.
 *   aBuffer  包含要写入数据的缓冲区指针.
 *   aLength  要写入的字节数.
 *   aOffset  文件内的写入起始偏移量. 如果为 -1, 则从当前文件位置写入 (或在追加模式下写入到末尾).
 *
 * @return
 *   成功时返回实际写入的字节数.
 *   失败时返回一个负值的错误码.
 *}
function fs_write(aFile: TfsFile; const aBuffer: Pointer; aLength: SizeUInt; aOffset: Int64): Integer;

{**
 * fs_unlink
 *
 * @desc
 *   删除一个文件.
 *
 * @params
 *   aPath  要删除的文件的路径.
 *
 * @return
 *   成功时返回 0, 失败时返回一个负值的错误码.
 *}
function fs_unlink(const aPath: string): Integer;

{**
 * fs_rename
 *
 * @desc
 *   重命名或移动一个文件或目录.
 *
 * @params
 *   aOldPath  原始路径.
 *   aNewPath  目标路径.
 *
 * @return
 *   成功时返回 0, 失败时返回一个负值的错误码.
 *}
function fs_rename(const aOldPath, aNewPath: string): Integer;

{**
 * fs_copyfile
 *
 * @desc
 *   复制一个文件.
 *
 * @params
 *   aPath     源文件路径.
 *   aNewPath  目标文件路径.
 *   aFlags    复制标志 (例如 UV_FS_COPYFILE_EXCL).
 *
 * @return
 *   成功时返回 0, 失败时返回一个负值的错误码.
 *}
function fs_copyfile(const aPath, aNewPath: string; aFlags: Integer): Integer;


  {**
   * fs_replace
   *
   * @desc
   *   用 aSrc 原子替换 aDst（目标存在则覆盖）。
   *   - 同卷：尽量使用 rename/MoveFileEx 的原子语义；
   *   - 跨卷（Unix EXDEV）：回退为 copy -> 原子替换（覆盖）；最后清理临时。
   *   注意：仅支持“文件”目标；目录不在本函数覆盖范围。
   *
   * @usage
   *   var rc: Integer;
   *   rc := fs_replace('draft.tmp', 'final.bin');
   *   if rc < 0 then begin
   *     // 处理统一负错误码（如需要可用 ToUnifiedFsErrorCode 做守护转换）
   *   end;
   *
   * @returns
   *   0 表示成功；负数为统一错误码。
   *}
  function fs_replace(const aSrc, aDst: string): Integer;

{**
 * fs_mkdir
 *
 * @desc
 *   创建一个目录.
 *
 * @params
 *   aPath  要创建的目录的路径.
 *   aMode  目录权限模式 (在 Windows 上通常被忽略).
 *
 * @return
 *   成功时返回 0, 失败时返回一个负值的错误码.
 *}
function fs_mkdir(const aPath: string; aMode: Integer): Integer;

{**
 * fs_rmdir
 *
 * @desc
 *   删除一个空的目录.
 *
 * @params
 *   aPath  要删除的目录的路径.
 *
 * @return
 *   成功时返回 0, 失败时返回一个负值的错误码.
 *}
function fs_rmdir(const aPath: string): Integer;

{**
 * fs_scandir
 *
 * @desc
 *   读取一个目录的内容.
 *
 * @params
 *   aPath     要扫描的目录路径.
 *   aEntries  用于接收目录条目名称的字符串列表.
 *
 * @return
 *   成功时返回 0, 失败时返回一个负值的错误码.
 *}
function fs_scandir(const aPath: string; var aEntries: TStringList): Integer;

{**
 * fs_scandir_each
 *
 * @desc
 *   以回调方式枚举目录内容，提供基础类型信息，避免上层为判断类型再二次 stat。
 *
 * @params
 *   aPath     目录路径
 *   aOnEntry  回调，参数：(Name, BasicType)，返回 True 继续，False 早停
 *
 * @return
 *   成功返回 0，失败返回负错误码
 *}
function fs_scandir_each(const aPath: string; aOnEntry: TfsScandirEachProc): Integer;

{**
 * fs_stat
 *
 * @desc
 *   获取文件或目录的状态信息. 如果路径是符号链接, 则获取链接指向的目标的状态.
 *
 * @params
 *   aPath  文件或目录的路径.
 *   aStat  用于接收状态信息的记录.
 *
 * @return
 *   成功时返回 0, 失败时返回一个负值的错误码.
 *}
function fs_stat(const aPath: string; out aStat: TfsStat): Integer;

{**
 * fs_lstat
 *
 * @desc
 *   获取文件或目录的状态信息. 如果路径是符号链接, 则获取链接本身的状态.
 *
 * @params
 *   aPath  文件或目录的路径.
 *   aStat  用于接收状态信息的记录.
 *
 * @return
 *   成功时返回 0, 失败时返回一个负值的错误码.
 *}
function fs_lstat(const aPath: string; out aStat: TfsStat): Integer;

{**
 * fs_fstat
 *
 * @desc
 *   通过已打开的文件句柄获取文件的状态信息.
 *
 * @params
 *   aFile  已打开的文件句柄.
 *   aStat  用于接收状态信息的记录.
 *
 * @return
 *   成功时返回 0, 失败时返回一个负值的错误码.
 *}
function fs_fstat(aFile: TfsFile; out aStat: TfsStat): Integer;

{**
 * fs_ftruncate
 *
 * @desc
 *   将一个文件截断到指定的长度。
 *
 * @params
 *   aFile    要截断的文件句柄。
 *   aOffset  目标长度/Size（注意：参数名保持 aOffset 不变，仅语义为“目标长度”）。
 *
 * @return
 *   成功时返回 0，失败时返回一个负值的错误码。
 *}
function fs_ftruncate(aFile: TfsFile; aOffset: Int64): Integer;

{**
 * fs_seek
 *
 * @desc
 *   设置文件指针位置.
 *
 * @params
 *   aFile    文件句柄.
 *   aOffset  偏移量.
 *   aWhence  起始位置 (SEEK_SET, SEEK_CUR, SEEK_END).
 *
 * @return
 *   成功时返回新的文件位置, 失败时返回一个负值的错误码.
 *}
function fs_seek(aFile: TfsFile; aOffset: Int64; aWhence: Integer): Int64;

{**
 * fs_tell
 *
 * @desc
 *   获取当前文件指针位置.
 *
 * @params
 *   aFile  文件句柄.
 *
 * @return
 *   成功时返回当前文件位置, 失败时返回一个负值的错误码.
 *}
function fs_tell(aFile: TfsFile): Int64;

{**
 * GetSavedFsErrorCode
 *
 * @desc
 *   获取保存的文件系统错误代码 (仅Windows平台).
 *
 * @return
 *   最后保存的系统错误代码.
 *}
{$IFDEF WINDOWS}
function GetSavedFsErrorCode: DWORD;
{$ENDIF}


  {**
   * fs_errno
   *
   * @desc
   *   获取最近一次 fs_open 失败的错误码（线程局部）。
   *   - 在启用 FS_UNIFIED_ERRORS 时，返回统一负错误码；
   *   - 否则返回负的系统错误码（Windows: GetLastError；Unix: errno）。
   *
   * @return
   *   负错误码；若无错误或尚未发生错误则返回 0。
   *}
  function fs_errno: Integer;

{**
 * fs_chmod
 *
 * @desc
 *   修改文件或目录的权限.
 *
 * @params
 *   aPath  文件或目录的路径.
 *   aMode  新的权限模式.
 *
 * @return
 *   成功时返回 0, 失败时返回一个负值的错误码.
 *}
function fs_chmod(const aPath: string; aMode: Integer): Integer;

{**
 * fs_fchmod
 *
 * @desc
 *   通过已打开的文件句柄修改文件的权限.
 *
 * @params
 *   aFile  已打开的文件句柄.
 *   aMode  新的权限模式.
 *
 * @return
 *   成功时返回 0, 失败时返回一个负值的错误码.
 *}
function fs_fchmod(aFile: TfsFile; aMode: Integer): Integer;

{**
 * fs_utime
 *
 * @desc
 *   修改文件的访问和修改时间.
 *
 * @params
 *   aPath   文件或目录的路径.
 *   aAtime  新的访问时间 (Unix timestamp).
 *   aMtime  新的修改时间 (Unix timestamp).
 *
 * @return
 *   成功时返回 0, 失败时返回一个负值的错误码.
 *}
function fs_utime(const aPath: string; aAtime, aMtime: Double): Integer;

{**
 * fs_futime
 *
 * @desc
 *   通过已打开的文件句柄修改文件的访问和修改时间.
 *
 * @params
 *   aFile   已打开的文件句柄.
 *   aAtime  新的访问时间 (Unix timestamp).
 *   aMtime  新的修改时间 (Unix timestamp).
 *
 * @return
 *   成功时返回 0, 失败时返回一个负值的错误码.
 *}
function fs_futime(aFile: TfsFile; aAtime, aMtime: Double): Integer;



{**
 * fs_fsync
 *
 * @desc
 *   强制将文件数据刷新到磁盘.
 *
 * @params
 *   aFile  文件句柄.
 *
 * @return
 *   成功时返回 0, 失败时返回一个负值的错误码.
 *}
function fs_fsync(aFile: TfsFile): Integer;

{**
 * fs_access
 *
 * @desc
 *   检查文件的访问权限.
 *
 * @params
 *   aPath  文件路径.
 *   aMode  访问模式 (F_OK, R_OK, W_OK, X_OK).
 *
 * @return
 *   成功时返回 0, 失败时返回一个负值的错误码.
 *}
function fs_access(const aPath: string; aMode: Integer): Integer;

{**
 * fs_link
 *
 * @desc
 *   创建硬链接.
 *
 * @params
 *   aPath     源文件路径.
 *   aNewPath  链接路径.
 *
 * @return
 *   成功时返回 0, 失败时返回一个负值的错误码.
 *}
function fs_link(const aPath, aNewPath: string): Integer;

{**
 * fs_symlink
 *
 * @desc
 *   创建符号链接.
 *
 * @params
 *   aPath     目标路径.
 *   aNewPath  链接路径.
 *
 * @return
 *   成功时返回 0, 失败时返回一个负值的错误码.
 *}
function fs_symlink(const aPath, aNewPath: string): Integer;

{**
 * fs_readlink
 *
 * @desc
 *   读取符号链接的目标路径.
 *
 * @params
 *   aPath    符号链接路径.
 *   aBuffer  用于存储目标路径的缓冲区.
 *   aSize    缓冲区大小.
 *
 * @return
 *   成功时返回目标路径长度, 失败时返回一个负值的错误码.
 *}
function fs_readlink(const aPath: string; aBuffer: PChar; aSize: SizeUInt): Integer;

{**
 * fs_flock
 *
 * @desc
 *   对文件进行锁定操作.
 *
 * @params
 *   aFile      文件句柄.
 *   aOperation 锁定操作 (LOCK_SH, LOCK_EX, LOCK_UN, 可与LOCK_NB组合).
 *
 * @return
 *   成功时返回 0, 失败时返回一个负值的错误码.
 *}
function fs_flock(aFile: TfsFile; aOperation: Integer): Integer;

{**
 * fs_realpath_s
 *
 * @desc
 *   便捷版本：将解析后的绝对路径直接返回为字符串。
 *   Windows：内部优先使用 GetFinalPathNameByHandleW，并移除 "\\\\?\\" 前缀（失败回退）。
 *   Unix：基于 realpath 实现。
 *
 * @returns
 *   成功返回 0 并写入 aResolved；失败返回统一负错误码。
 *}
function fs_realpath_s(const aPath: string; out aResolved: string): Integer;

{**
 * fs_readlink_s
 *
 * @desc
 *   便捷版本：将符号链接目标直接返回为字符串。
 *   Windows：在无管理员/开发者模式下可能不支持创建/读取符号链接，调用方需兼容 -EACCES/-EPERM。
 *
 * @returns
 *   成功返回 0 并赋值 aTarget；失败返回统一负错误码。
 *}
function fs_readlink_s(const aPath: string; out aTarget: string): Integer;

{**
 * fs_realpath
 *
 * @desc
 *   获取文件的绝对路径.
 *
 * @params
 *   aPath         相对或绝对路径.
 *   aResolvedPath 用于存储解析后路径的缓冲区.
 *   aSize         缓冲区大小.
 *
 * @return
 *   成功时返回解析后的路径长度, 失败时返回一个负值的错误码.
 *}
function fs_realpath(const aPath: string; aResolvedPath: PChar; aSize: SizeUInt): Integer;

{**
 * fs_mkdtemp
 *
 * @desc
 *   创建临时目录.
 *
 * @params
 *   aTemplate 目录名模板 (必须以6个X结尾).
 *
 * @return
 *   成功时返回创建的目录路径, 失败时返回空字符串.
 *}
function fs_mkdtemp(const aTemplate: string): string;

{**
 * fs_mkstemp
 *
 * @desc
 *   创建临时文件.
 *
 * @params
 *   aTemplate 文件名模板 (必须以6个X结尾).
 *
 * @return
 *   成功时返回文件句柄, 失败时返回INVALID_HANDLE_VALUE.
 *}
function fs_mkstemp(const aTemplate: string): TfsFile;

{**
 * fs_mkstemp_ex
 *
 * @desc
 *   创建临时文件，并返回最终创建的文件路径。
 *
 * @params
 *   aTemplate 文件名模板 (必须以6个X结尾)
 *   aPath     输出参数：创建的文件的完整路径
 *
 * @return
 *   成功时返回文件句柄, 失败时返回INVALID_HANDLE_VALUE.
 *}
function fs_mkstemp_ex(const aTemplate: string; out aPath: string): TfsFile;

{**
 * IsValidHandle
 *
 * @desc
 *   检查文件句柄是否有效.
 *
 * @params
 *   aHandle  要检查的文件句柄.
 *
 * @return
 *   如果句柄有效返回 True, 否则返回 False.
 *}
function IsValidHandle(aHandle: TfsFile): Boolean; inline;

implementation

uses
  fafafa.core.math;

{$IFDEF WINDOWS}
  {$I fafafa.core.fs.windows.inc}
{$ELSE}
  {$I fafafa.core.fs.unix.inc}
{$ENDIF}

function fs_realpath_s(const aPath: string; out aResolved: string): Integer;
var
  Buf: array[0..4095] of Char;
  R: Integer;
begin
  aResolved := '';
  R := fs_realpath(aPath, @Buf[0], Length(Buf));
  if R < 0 then Exit(R);
  SetString(aResolved, PChar(@Buf[0]), R);
  Result := 0;
end;

function fs_readlink_s(const aPath: string; out aTarget: string): Integer;
var
  Buf: array[0..4095] of Char;
  R: Integer;
begin
  aTarget := '';
  R := fs_readlink(aPath, @Buf[0], Length(Buf));
  if R < 0 then Exit(R);
  SetString(aTarget, PChar(@Buf[0]), R);
  Result := 0;
end;


function IsValidHandle(aHandle: TfsFile): Boolean; inline;
begin
  {$IFDEF WINDOWS}
  Result := aHandle <> INVALID_HANDLE_VALUE;
  {$ELSE}
  Result := aHandle >= 0;
  {$ENDIF}
end;

end.