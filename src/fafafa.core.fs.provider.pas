unit fafafa.core.fs.provider;

{$mode objfpc}{$H+}

{!
  IFileSystemProvider - 文件系统抽象接口

  Issue #11: 提供统一的文件系统抽象层，支持:
  - Mock 测试（内存文件系统）
  - 虚拟文件系统
  - 远程文件系统代理

  使用示例:
    var
      FS: IFileSystemProvider;
    begin
      FS := GetDefaultFileSystem;  // 获取真实文件系统
      // 或
      FS := TMemoryFileSystem.Create;  // 使用内存文件系统进行测试

      if FS.FileExists('/path/to/file') then
        Data := FS.ReadFile('/path/to/file');
    end;
}

interface

uses
  SysUtils, Classes;

type
  { 文件类型枚举 }
  TFsFileType = (
    ftUnknown,      // 未知类型
    ftFile,         // 普通文件
    ftDirectory,    // 目录
    ftSymlink,      // 符号链接
    ftDevice,       // 设备文件
    ftPipe,         // 管道
    ftSocket        // 套接字
  );

  { 文件信息记录 }
  TFsFileInfo = record
    Path: string;           // 完整路径
    Name: string;           // 文件名
    FileType: TFsFileType;  // 文件类型
    Size: Int64;            // 文件大小（字节）
    ModificationTime: TDateTime;  // 修改时间
    AccessTime: TDateTime;        // 访问时间
    CreationTime: TDateTime;      // 创建时间
    IsReadOnly: Boolean;    // 是否只读
    IsHidden: Boolean;      // 是否隐藏
  end;

  { 目录项 }
  TFsDirEntry = record
    Name: string;           // 文件/目录名
    FileType: TFsFileType;  // 类型
  end;
  TFsDirEntries = array of TFsDirEntry;

  { 文件系统提供者接口 }
  IFileSystemProvider = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']

    // === 文件操作 ===

    { 读取文件内容为字节数组 }
    function ReadFile(const APath: string): TBytes;

    { 读取文件内容为字符串 }
    function ReadTextFile(const APath: string): string;

    { 写入字节数组到文件 }
    procedure WriteFile(const APath: string; const AData: TBytes);

    { 写入字符串到文件 }
    procedure WriteTextFile(const APath: string; const AText: string);

    { 原子写入文件（写入临时文件后重命名） }
    procedure WriteFileAtomic(const APath: string; const AData: TBytes);

    { 删除文件 }
    procedure DeleteFile(const APath: string);

    { 复制文件 }
    procedure CopyFile(const ASrc, ADst: string; AOverwrite: Boolean = False);

    { 移动/重命名文件 }
    procedure MoveFile(const ASrc, ADst: string; AOverwrite: Boolean = False);

    // === 目录操作 ===

    { 创建目录 }
    procedure CreateDirectory(const APath: string; ARecursive: Boolean = True);

    { 删除目录 }
    procedure DeleteDirectory(const APath: string; ARecursive: Boolean = False);

    { 列出目录内容 }
    function ListDirectory(const APath: string): TFsDirEntries;

    // === 存在性检查 ===

    { 检查路径是否存在 }
    function Exists(const APath: string): Boolean;

    { 检查是否为文件 }
    function IsFile(const APath: string): Boolean;

    { 检查是否为目录 }
    function IsDirectory(const APath: string): Boolean;

    { 检查是否为符号链接 }
    function IsSymlink(const APath: string): Boolean;

    // === 元数据 ===

    { 获取文件信息 }
    function GetFileInfo(const APath: string): TFsFileInfo;

    { 获取文件大小 }
    function GetFileSize(const APath: string): Int64;

    { 获取修改时间 }
    function GetModificationTime(const APath: string): TDateTime;

    { 设置修改时间 }
    procedure SetModificationTime(const APath: string; ATime: TDateTime);

    // === 路径操作 ===

    { 获取当前工作目录 }
    function GetCurrentDirectory: string;

    { 设置当前工作目录 }
    procedure SetCurrentDirectory(const APath: string);

    { 获取临时目录 }
    function GetTempDirectory: string;
  end;

  { 真实文件系统提供者 - 使用操作系统文件系统 }
  TRealFileSystemProvider = class(TInterfacedObject, IFileSystemProvider)
  public
    // 文件操作
    function ReadFile(const APath: string): TBytes;
    function ReadTextFile(const APath: string): string;
    procedure WriteFile(const APath: string; const AData: TBytes);
    procedure WriteTextFile(const APath: string; const AText: string);
    procedure WriteFileAtomic(const APath: string; const AData: TBytes);
    procedure DeleteFile(const APath: string);
    procedure CopyFile(const ASrc, ADst: string; AOverwrite: Boolean = False);
    procedure MoveFile(const ASrc, ADst: string; AOverwrite: Boolean = False);

    // 目录操作
    procedure CreateDirectory(const APath: string; ARecursive: Boolean = True);
    procedure DeleteDirectory(const APath: string; ARecursive: Boolean = False);
    function ListDirectory(const APath: string): TFsDirEntries;

    // 存在性检查
    function Exists(const APath: string): Boolean;
    function IsFile(const APath: string): Boolean;
    function IsDirectory(const APath: string): Boolean;
    function IsSymlink(const APath: string): Boolean;

    // 元数据
    function GetFileInfo(const APath: string): TFsFileInfo;
    function GetFileSize(const APath: string): Int64;
    function GetModificationTime(const APath: string): TDateTime;
    procedure SetModificationTime(const APath: string; ATime: TDateTime);

    // 路径操作
    function GetCurrentDirectory: string;
    procedure SetCurrentDirectory(const APath: string);
    function GetTempDirectory: string;
  end;

{ 获取默认文件系统提供者（真实文件系统） }
function GetDefaultFileSystem: IFileSystemProvider;

{ 获取共享的默认文件系统实例（单例） }
function DefaultFileSystem: IFileSystemProvider;

implementation

uses
  fafafa.core.fs.fileio,
  fafafa.core.fs.directory,
  fafafa.core.fs.helpers,
  fafafa.core.fs.path,
  fafafa.core.fs.options;

var
  GDefaultFileSystem: IFileSystemProvider = nil;

{ TRealFileSystemProvider }

function TRealFileSystemProvider.ReadFile(const APath: string): TBytes;
begin
  Result := ReadBinaryFile(APath);
end;

function TRealFileSystemProvider.ReadTextFile(const APath: string): string;
begin
  Result := fafafa.core.fs.fileio.ReadTextFile(APath);
end;

procedure TRealFileSystemProvider.WriteFile(const APath: string; const AData: TBytes);
begin
  WriteBinaryFile(APath, AData);
end;

procedure TRealFileSystemProvider.WriteTextFile(const APath: string; const AText: string);
begin
  fafafa.core.fs.fileio.WriteTextFile(APath, AText);
end;

procedure TRealFileSystemProvider.WriteFileAtomic(const APath: string; const AData: TBytes);
begin
  fafafa.core.fs.fileio.WriteFileAtomic(APath, AData);
end;

procedure TRealFileSystemProvider.DeleteFile(const APath: string);
begin
  fafafa.core.fs.directory.DeleteFile(APath);
end;

procedure TRealFileSystemProvider.CopyFile(const ASrc, ADst: string; AOverwrite: Boolean);
var
  Opts: TFsCopyOptions;
begin
  Opts := FsDefaultCopyOptions;
  Opts.Overwrite := AOverwrite;
  FsCopyFileEx(ASrc, ADst, Opts);
end;

procedure TRealFileSystemProvider.MoveFile(const ASrc, ADst: string; AOverwrite: Boolean);
var
  Opts: TFsMoveOptions;
begin
  Opts := FsDefaultMoveOptions;
  Opts.Overwrite := AOverwrite;
  FsMoveFileEx(ASrc, ADst, Opts);
end;

procedure TRealFileSystemProvider.CreateDirectory(const APath: string; ARecursive: Boolean);
begin
  fafafa.core.fs.directory.CreateDirectory(APath, ARecursive);
end;

procedure TRealFileSystemProvider.DeleteDirectory(const APath: string; ARecursive: Boolean);
begin
  fafafa.core.fs.directory.DeleteDirectory(APath, ARecursive);
end;

function TRealFileSystemProvider.ListDirectory(const APath: string): TFsDirEntries;
var
  SearchRec: TSearchRec;
  Count: Integer;
begin
  Result := nil;
  Count := 0;

  if FindFirst(IncludeTrailingPathDelimiter(APath) + '*', faAnyFile, SearchRec) = 0 then
  begin
    try
      repeat
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
        begin
          SetLength(Result, Count + 1);
          Result[Count].Name := SearchRec.Name;
          if (SearchRec.Attr and faDirectory) <> 0 then
            Result[Count].FileType := ftDirectory
          else
            Result[Count].FileType := ftFile;
          Inc(Count);
        end;
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
  end;
end;

function TRealFileSystemProvider.Exists(const APath: string): Boolean;
begin
  Result := FsExists(APath);
end;

function TRealFileSystemProvider.IsFile(const APath: string): Boolean;
begin
  Result := FsIsFile(APath);
end;

function TRealFileSystemProvider.IsDirectory(const APath: string): Boolean;
begin
  Result := FsIsDirectory(APath);
end;

function TRealFileSystemProvider.IsSymlink(const APath: string): Boolean;
begin
  Result := FsIsSymlink(APath);
end;

function TRealFileSystemProvider.GetFileInfo(const APath: string): TFsFileInfo;
var
  SearchRec: TSearchRec;
begin
  Result.Path := APath;
  Result.Name := ExtractFileName(APath);
  Result.FileType := ftUnknown;
  Result.Size := 0;
  Result.ModificationTime := 0;
  Result.AccessTime := 0;
  Result.CreationTime := 0;
  Result.IsReadOnly := False;
  Result.IsHidden := False;

  if FindFirst(APath, faAnyFile, SearchRec) = 0 then
  begin
    try
      if (SearchRec.Attr and faDirectory) <> 0 then
        Result.FileType := ftDirectory
      else
        Result.FileType := ftFile;
      Result.Size := SearchRec.Size;
      Result.ModificationTime := SearchRec.TimeStamp;
      Result.IsReadOnly := (SearchRec.Attr and faReadOnly) <> 0;
      {$IFDEF WINDOWS}
      Result.IsHidden := (SearchRec.Attr and faHidden) <> 0;
      {$ELSE}
      Result.IsHidden := (Length(Result.Name) > 0) and (Result.Name[1] = '.');
      {$ENDIF}
    finally
      FindClose(SearchRec);
    end;
  end;
end;

function TRealFileSystemProvider.GetFileSize(const APath: string): Int64;
begin
  Result := fafafa.core.fs.directory.GetFileSize(APath);
end;

function TRealFileSystemProvider.GetModificationTime(const APath: string): TDateTime;
begin
  Result := fafafa.core.fs.directory.GetFileModificationTime(APath);
end;

procedure TRealFileSystemProvider.SetModificationTime(const APath: string; ATime: TDateTime);
var
  Age: LongInt;
begin
  Age := DateTimeToFileDate(ATime);
  FileSetDate(APath, Age);
end;

function TRealFileSystemProvider.GetCurrentDirectory: string;
begin
  Result := SysUtils.GetCurrentDir;
end;

procedure TRealFileSystemProvider.SetCurrentDirectory(const APath: string);
begin
  SysUtils.SetCurrentDir(APath);
end;

function TRealFileSystemProvider.GetTempDirectory: string;
begin
  Result := SysUtils.GetTempDir(False);
end;

{ 工厂函数 }

function GetDefaultFileSystem: IFileSystemProvider;
begin
  Result := TRealFileSystemProvider.Create;
end;

function DefaultFileSystem: IFileSystemProvider;
begin
  if GDefaultFileSystem = nil then
    GDefaultFileSystem := TRealFileSystemProvider.Create;
  Result := GDefaultFileSystem;
end;

end.
