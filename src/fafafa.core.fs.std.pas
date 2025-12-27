unit fafafa.core.fs.std;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

{!
  fafafa.core.fs.std - Rust 风格文件系统 API 统一门面

  此单元重新导出所有 Rust std::fs 对齐的类型和函数，
  用户只需引用此单元即可使用完整的现代 API。

  用法示例：
    uses
      fafafa.core.fs.std;

    var
      F: TFile;
      P: TFsPath;
      Meta: TFsMetadata;
    begin
      // 文件操作
      F := TFile.Open('data.txt');
      try
        WriteLn(F.ReadString);
      finally
        F.Free;
      end;

      // 路径操作
      P := Path('/home/user/file.txt');
      WriteLn(P.FileName);
      WriteLn(P.Parent.Value);

      // 元数据
      Meta := FsMetadata('file.txt');
      try
        WriteLn('Size: ', Meta.Size);
        WriteLn('Permissions: ', Meta.Permissions.ToString);
      finally
        Meta.Free;
      end;

      // 便捷函数
      FsWriteString('output.txt', 'Hello!');
      WriteLn(FsReadToString('output.txt'));

      // 目录迭代
      for Entry in FsReadDir('/path') do
        WriteLn(Entry.FileName);
    end;

  包含模块：
    - fafafa.core.fs.types    : TFsFileType, TFsPermissions, TFsMetadata
    - fafafa.core.fs.open     : TFsOpenOptionsBuilder
    - fafafa.core.fs.fileobj  : TFile, FsRead*, FsWrite*
    - fafafa.core.fs.dir      : TFsReadDir, TFsDirEntry
    - fafafa.core.fs.pathobj  : TFsPath, TFsPathBuf, Path(), PathBuf()
    - fafafa.core.fs.bufio    : TFsBufReader, TFsBufWriter
    - fafafa.core.fs.errors   : EFsError, TFsErrorCode
}

interface

uses
  SysUtils, Classes,
  // 底层模块
  fafafa.core.fs,
  fafafa.core.fs.errors,
  fafafa.core.fs.path,
  fafafa.core.fs.options,
  // Rust 风格模块
  fafafa.core.fs.types,
  fafafa.core.fs.open,
  fafafa.core.fs.fileobj,
  fafafa.core.fs.dir,
  fafafa.core.fs.pathobj,
  fafafa.core.fs.bufio;

// ============================================================================
// 重新导出类型
// ============================================================================

type
  // 文件类型
  TFsFileType = fafafa.core.fs.types.TFsFileType;
  TFsPermissions = fafafa.core.fs.types.TFsPermissions;
  TFsMetadata = fafafa.core.fs.types.TFsMetadata;

  // 文件操作
  TFile = fafafa.core.fs.fileobj.TFile;
  TFsOpenOptionsBuilder = fafafa.core.fs.open.TFsOpenOptionsBuilder;

  // 目录迭代
  TFsReadDir = fafafa.core.fs.dir.TFsReadDir;
  TFsDirEntry = fafafa.core.fs.dir.TFsDirEntry;

  // 路径
  TFsPath = fafafa.core.fs.pathobj.TFsPath;
  TFsPathBuf = fafafa.core.fs.pathobj.TFsPathBuf;

  // 缓冲读写器
  TFsBufReader = fafafa.core.fs.bufio.TFsBufReader;
  TFsBufWriter = fafafa.core.fs.bufio.TFsBufWriter;
  TFsLineCallback = fafafa.core.fs.bufio.TFsLineCallback;

  // 错误处理
  EFsError = fafafa.core.fs.errors.EFsError;
  TFsErrorCode = fafafa.core.fs.errors.TFsErrorCode;

// ============================================================================
// 重新导出常量
// ============================================================================

const
  // 文件类型常量
  ftRegular = fafafa.core.fs.types.ftRegular;
  ftDirectory = fafafa.core.fs.types.ftDirectory;
  ftSymlink = fafafa.core.fs.types.ftSymlink;
  ftBlockDevice = fafafa.core.fs.types.ftBlockDevice;
  ftCharDevice = fafafa.core.fs.types.ftCharDevice;
  ftFifo = fafafa.core.fs.types.ftFifo;
  ftSocket = fafafa.core.fs.types.ftSocket;
  ftUnknown = fafafa.core.fs.types.ftUnknown;

  // 错误码常量
  FS_ERROR_FILE_NOT_FOUND = fafafa.core.fs.errors.FS_ERROR_FILE_NOT_FOUND;
  FS_ERROR_ACCESS_DENIED = fafafa.core.fs.errors.FS_ERROR_ACCESS_DENIED;
  FS_ERROR_FILE_EXISTS = fafafa.core.fs.errors.FS_ERROR_FILE_EXISTS;
  FS_ERROR_PERMISSION_DENIED = fafafa.core.fs.errors.FS_ERROR_PERMISSION_DENIED;
  FS_ERROR_IO_ERROR = fafafa.core.fs.errors.FS_ERROR_IO_ERROR;

// ============================================================================
// 重新导出函数 - 路径
// ============================================================================

// 快速创建路径
function Path(const APath: string): TFsPath; inline;
function PathBuf(const APath: string): TFsPathBuf; inline;

// ============================================================================
// 重新导出函数 - 文件读写
// ============================================================================

// 读取文件
function FsRead(const APath: string): TBytes; inline;
function FsReadToString(const APath: string): string; inline;

// 写入文件
procedure FsWrite(const APath: string; const AData: TBytes); inline;
procedure FsWriteString(const APath: string; const AStr: string); inline;

// 追加文件
procedure FsAppend(const APath: string; const AData: TBytes); inline;
procedure FsAppendString(const APath: string; const AStr: string); inline;

// ============================================================================
// 重新导出函数 - 文件操作
// ============================================================================

// 复制
procedure FsCopy(const ASrc, ADst: string); inline;
function FsTryCopy(const ASrc, ADst: string): Integer; inline;

// 重命名/移动
procedure FsRename(const ASrc, ADst: string); inline;
function FsTryRename(const ASrc, ADst: string): Integer; inline;

// 删除
procedure FsRemoveFile(const APath: string); inline;
function FsTryRemoveFile(const APath: string): Integer; inline;

// ============================================================================
// 重新导出函数 - 目录操作
// ============================================================================

// 创建目录
procedure FsCreateDir(const APath: string); inline;
procedure FsCreateDirAll(const APath: string); inline;
function FsTryCreateDir(const APath: string): Integer; inline;

// 删除目录
procedure FsRemoveDir(const APath: string); inline;
function FsTryRemoveDir(const APath: string): Integer; inline;

// 读取目录
function FsReadDir(const APath: string): TFsReadDir; inline;
function FsReadDirNames(const APath: string): TStringList; inline;
function FsIsDirEmpty(const APath: string): Boolean; inline;
function FsCountFiles(const APath: string): Integer; inline;
function FsCountDirs(const APath: string): Integer; inline;

// ============================================================================
// 重新导出函数 - 符号链接
// ============================================================================

procedure FsSymlink(const ATarget, ALink: string); inline;
procedure FsHardLink(const ASrc, ADst: string); inline;
function FsReadLink(const APath: string): string; inline;

// ============================================================================
// 重新导出函数 - 元数据
// ============================================================================

function FsMetadata(const APath: string): TFsMetadata; inline;
procedure FsSetPermissions(const APath: string; AMode: UInt32); inline;
function FsCanonicalize(const APath: string): string; inline;

// ============================================================================
// 重新导出函数 - 类型转换
// ============================================================================

function FileTypeFromMode(AMode: UInt32): TFsFileType; inline;

// ============================================================================
// 重新导出函数 - 缓冲读写器
// ============================================================================

// 创建缓冲读取器并打开文件
function FsBufReader(const APath: string; ABufSize: Integer = 8192): TFsBufReader; inline;

// 创建缓冲写入器并打开文件
function FsBufWriter(const APath: string; ABufSize: Integer = 8192): TFsBufWriter; inline;

// 逐行读取文件（回调方式）
procedure FsForEachLine(const APath: string; ACallback: TFsLineCallback); inline;

implementation

// ============================================================================
// 路径函数
// ============================================================================

function Path(const APath: string): TFsPath;
begin
  Result := fafafa.core.fs.pathobj.Path(APath);
end;

function PathBuf(const APath: string): TFsPathBuf;
begin
  Result := fafafa.core.fs.pathobj.PathBuf(APath);
end;

// ============================================================================
// 文件读写函数
// ============================================================================

function FsRead(const APath: string): TBytes;
begin
  Result := fafafa.core.fs.fileobj.FsRead(APath);
end;

function FsReadToString(const APath: string): string;
begin
  Result := fafafa.core.fs.fileobj.FsReadToString(APath);
end;

procedure FsWrite(const APath: string; const AData: TBytes);
begin
  fafafa.core.fs.fileobj.FsWrite(APath, AData);
end;

procedure FsWriteString(const APath: string; const AStr: string);
begin
  fafafa.core.fs.fileobj.FsWriteString(APath, AStr);
end;

procedure FsAppend(const APath: string; const AData: TBytes);
begin
  fafafa.core.fs.fileobj.FsAppend(APath, AData);
end;

procedure FsAppendString(const APath: string; const AStr: string);
begin
  fafafa.core.fs.fileobj.FsAppendString(APath, AStr);
end;

// ============================================================================
// 文件操作函数
// ============================================================================

procedure FsCopy(const ASrc, ADst: string);
begin
  fafafa.core.fs.fileobj.FsCopy(ASrc, ADst);
end;

function FsTryCopy(const ASrc, ADst: string): Integer;
begin
  Result := fafafa.core.fs.fileobj.FsTryCopy(ASrc, ADst);
end;

procedure FsRename(const ASrc, ADst: string);
begin
  fafafa.core.fs.fileobj.FsRename(ASrc, ADst);
end;

function FsTryRename(const ASrc, ADst: string): Integer;
begin
  Result := fafafa.core.fs.fileobj.FsTryRename(ASrc, ADst);
end;

procedure FsRemoveFile(const APath: string);
begin
  fafafa.core.fs.fileobj.FsRemoveFile(APath);
end;

function FsTryRemoveFile(const APath: string): Integer;
begin
  Result := fafafa.core.fs.fileobj.FsTryRemoveFile(APath);
end;

// ============================================================================
// 目录操作函数
// ============================================================================

procedure FsCreateDir(const APath: string);
begin
  fafafa.core.fs.fileobj.FsCreateDir(APath);
end;

procedure FsCreateDirAll(const APath: string);
begin
  fafafa.core.fs.fileobj.FsCreateDirAll(APath);
end;

function FsTryCreateDir(const APath: string): Integer;
begin
  Result := fafafa.core.fs.fileobj.FsTryCreateDir(APath);
end;

procedure FsRemoveDir(const APath: string);
begin
  fafafa.core.fs.fileobj.FsRemoveDir(APath);
end;

function FsTryRemoveDir(const APath: string): Integer;
begin
  Result := fafafa.core.fs.fileobj.FsTryRemoveDir(APath);
end;

function FsReadDir(const APath: string): TFsReadDir;
begin
  Result := fafafa.core.fs.dir.FsReadDir(APath);
end;

function FsReadDirNames(const APath: string): TStringList;
begin
  Result := fafafa.core.fs.dir.FsReadDirNames(APath);
end;

function FsIsDirEmpty(const APath: string): Boolean;
begin
  Result := fafafa.core.fs.dir.FsIsDirEmpty(APath);
end;

function FsCountFiles(const APath: string): Integer;
begin
  Result := fafafa.core.fs.dir.FsCountFiles(APath);
end;

function FsCountDirs(const APath: string): Integer;
begin
  Result := fafafa.core.fs.dir.FsCountDirs(APath);
end;

// ============================================================================
// 符号链接函数
// ============================================================================

procedure FsSymlink(const ATarget, ALink: string);
begin
  fafafa.core.fs.fileobj.FsSymlink(ATarget, ALink);
end;

procedure FsHardLink(const ASrc, ADst: string);
begin
  fafafa.core.fs.fileobj.FsHardLink(ASrc, ADst);
end;

function FsReadLink(const APath: string): string;
begin
  Result := fafafa.core.fs.fileobj.FsReadLink(APath);
end;

// ============================================================================
// 元数据函数
// ============================================================================

function FsMetadata(const APath: string): TFsMetadata;
begin
  Result := fafafa.core.fs.fileobj.FsMetadata(APath);
end;

procedure FsSetPermissions(const APath: string; AMode: UInt32);
begin
  fafafa.core.fs.fileobj.FsSetPermissions(APath, AMode);
end;

function FsCanonicalize(const APath: string): string;
begin
  Result := fafafa.core.fs.fileobj.FsCanonicalize(APath);
end;

// ============================================================================
// 类型转换函数
// ============================================================================

function FileTypeFromMode(AMode: UInt32): TFsFileType;
begin
  Result := fafafa.core.fs.types.FileTypeFromMode(AMode);
end;

// ============================================================================
// 缓冲读写器函数
// ============================================================================

function FsBufReader(const APath: string; ABufSize: Integer): TFsBufReader;
begin
  Result := fafafa.core.fs.bufio.FsBufReader(APath, ABufSize);
end;

function FsBufWriter(const APath: string; ABufSize: Integer): TFsBufWriter;
begin
  Result := fafafa.core.fs.bufio.FsBufWriter(APath, ABufSize);
end;

procedure FsForEachLine(const APath: string; ACallback: TFsLineCallback);
begin
  fafafa.core.fs.bufio.FsForEachLine(APath, ACallback);
end;

end.
