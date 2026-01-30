unit fafafa.core.fs.dir;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$modeswitch advancedrecords}

{!
  fafafa.core.fs.dir - Rust 风格的目录迭代器

  对标 Rust std::fs::read_dir 和 DirEntry，提供：
  - TFsDirEntry: 目录条目（对标 Rust DirEntry）
  - TFsReadDir: 目录迭代器（对标 Rust ReadDir）
  - for-in 循环支持

  用法示例：
    var
      Dir: TFsReadDir;
      Entry: TFsDirEntry;
    begin
      Dir := FsReadDir('/path/to/dir');
      try
        while Dir.Next(Entry) do
        begin
          WriteLn(Entry.FileName);
          if Entry.IsFile then
            WriteLn('  Size: ', Entry.Metadata.Size);
        end;
      finally
        Dir.Free;
      end;

      // 或使用 for-in（需要枚举器支持）
      for Entry in FsReadDir('/path/to/dir') do
        WriteLn(Entry.FileName);
    end;
}

interface

uses
  SysUtils, Classes,
  fafafa.core.fs,
  fafafa.core.fs.types;

type
  // 前向声明
  TFsReadDir = class;

  // ============================================================================
  // TFsDirEntry - 目录条目
  // ============================================================================
  // 对标 Rust std::fs::DirEntry
  TFsDirEntry = record
  private
    FPath: string;         // 完整路径
    FFileName: string;     // 文件名
    FBasicType: TfsDirEntType;
    FStatCached: Boolean;
    FStat: TfsStat;
    function GetMetadata: TFsMetadata;
    function GetFileType: TFsFileType;
  public
    // 基本属性
    property Path: string read FPath;
    property FileName: string read FFileName;

    // 类型检查（快速，不需要 stat）
    function IsFile: Boolean;
    function IsDir: Boolean;
    function IsSymlink: Boolean;

    // 完整类型（可能需要 stat）
    function FileType: TFsFileType;

    // 元数据（延迟加载）
    function Metadata: TFsMetadata;

    // 内部使用
    procedure Init(const APath, AFileName: string; AType: TfsDirEntType);
  end;

  // ============================================================================
  // TFsReadDir - 目录迭代器
  // ============================================================================
  // 对标 Rust std::fs::ReadDir
  TFsReadDir = class
  private
    FPath: string;
    FEntries: TStringList;
    FTypes: TList;
    FIndex: Integer;
    FValid: Boolean;
    FError: Integer;
  public
    constructor Create(const APath: string);
    destructor Destroy; override;

    // 迭代方法
    function Next(out AEntry: TFsDirEntry): Boolean;
    function HasNext: Boolean;
    procedure Reset;

    // 状态
    function IsValid: Boolean;
    function Error: Integer;
    function Count: Integer;

    // 路径
    property Path: string read FPath;
  end;

  // ============================================================================
  // TFsDirEntryEnumerator - for-in 枚举器
  // ============================================================================
  TFsDirEntryEnumerator = class
  private
    FDir: TFsReadDir;
    FCurrent: TFsDirEntry;
    FOwnsDir: Boolean;
  public
    constructor Create(ADir: TFsReadDir; AOwnsDir: Boolean = False);
    destructor Destroy; override;
    function MoveNext: Boolean;
    function GetCurrent: TFsDirEntry;
    property Current: TFsDirEntry read GetCurrent;
  end;

// ============================================================================
// 便捷函数
// ============================================================================

// 读取目录（返回迭代器，调用方需要 Free）
function FsReadDir(const APath: string): TFsReadDir;

// 读取目录到列表
function FsReadDirNames(const APath: string): TStringList;
function FsReadDirEntries(const APath: string): TList;

// 检查目录是否为空
function FsIsDirEmpty(const APath: string): Boolean;

// 统计目录内容
function FsCountFiles(const APath: string): Integer;
function FsCountDirs(const APath: string): Integer;

implementation

// ============================================================================
// TFsDirEntry
// ============================================================================

procedure TFsDirEntry.Init(const APath, AFileName: string; AType: TfsDirEntType);
begin
  FPath := APath;
  FFileName := AFileName;
  FBasicType := AType;
  FStatCached := False;
  FStat := Default(TfsStat);
end;

function TFsDirEntry.IsFile: Boolean;
begin
  Result := FBasicType = fsDETFile;
end;

function TFsDirEntry.IsDir: Boolean;
begin
  Result := FBasicType = fsDETDir;
end;

function TFsDirEntry.IsSymlink: Boolean;
begin
  Result := FBasicType = fsDETSymlink;
end;

function TFsDirEntry.GetFileType: TFsFileType;
begin
  case FBasicType of
    fsDETFile:    Result := ftRegular;
    fsDETDir:     Result := ftDirectory;
    fsDETSymlink: Result := ftSymlink;
  else
    // 需要 stat 来确定类型
    if not FStatCached then
    begin
      if fs_lstat(FPath, FStat) = 0 then
        FStatCached := True;
    end;
    if FStatCached then
      Result := FileTypeFromMode(FStat.Mode)
    else
      Result := ftUnknown;
  end;
end;

function TFsDirEntry.FileType: TFsFileType;
begin
  Result := GetFileType;
end;

function TFsDirEntry.GetMetadata: TFsMetadata;
begin
  Result := TFsMetadata.FromPath(FPath, True);
end;

function TFsDirEntry.Metadata: TFsMetadata;
begin
  Result := GetMetadata;
end;

// ============================================================================
// TFsReadDir
// ============================================================================

constructor TFsReadDir.Create(const APath: string);
var
  LDir: TfsFile;
  LEntries: TStringList;
  I: Integer;
begin
  inherited Create;
  FPath := APath;
  FEntries := TStringList.Create;
  FTypes := TList.Create;
  FIndex := 0;
  FValid := False;
  FError := 0;

  // 读取目录内容
  LEntries := TStringList.Create;
  try
    FError := fs_scandir(APath, LEntries);
    if FError = 0 then
    begin
      FValid := True;
      // 复制条目，类型暂时设为 Unknown（需要时再查询）
      for I := 0 to LEntries.Count - 1 do
      begin
        FEntries.Add(LEntries[I]);
        FTypes.Add(Pointer(PtrInt(fsDETUnknown)));
      end;
    end;
  finally
    LEntries.Free;
  end;
end;

destructor TFsReadDir.Destroy;
begin
  FEntries.Free;
  FTypes.Free;
  inherited Destroy;
end;

function TFsReadDir.Next(out AEntry: TFsDirEntry): Boolean;
var
  LName: string;
  LType: TfsDirEntType;
  LPath: string;
begin
  Result := False;
  if not FValid then Exit;
  if FIndex >= FEntries.Count then Exit;

  LName := FEntries[FIndex];
  LType := TfsDirEntType(PtrInt(FTypes[FIndex]));
  LPath := IncludeTrailingPathDelimiter(FPath) + LName;

  AEntry.Init(LPath, LName, LType);
  Inc(FIndex);
  Result := True;
end;

function TFsReadDir.HasNext: Boolean;
begin
  Result := FValid and (FIndex < FEntries.Count);
end;

procedure TFsReadDir.Reset;
begin
  FIndex := 0;
end;

function TFsReadDir.IsValid: Boolean;
begin
  Result := FValid;
end;

function TFsReadDir.Error: Integer;
begin
  Result := FError;
end;

function TFsReadDir.Count: Integer;
begin
  if FValid then
    Result := FEntries.Count
  else
    Result := 0;
end;

// ============================================================================
// TFsDirEntryEnumerator
// ============================================================================

constructor TFsDirEntryEnumerator.Create(ADir: TFsReadDir; AOwnsDir: Boolean);
begin
  inherited Create;
  FDir := ADir;
  FOwnsDir := AOwnsDir;
  FCurrent := Default(TFsDirEntry);
end;

destructor TFsDirEntryEnumerator.Destroy;
begin
  if FOwnsDir and Assigned(FDir) then
    FDir.Free;
  inherited Destroy;
end;

function TFsDirEntryEnumerator.MoveNext: Boolean;
begin
  Result := FDir.Next(FCurrent);
end;

function TFsDirEntryEnumerator.GetCurrent: TFsDirEntry;
begin
  Result := FCurrent;
end;

// ============================================================================
// 便捷函数
// ============================================================================

function FsReadDir(const APath: string): TFsReadDir;
begin
  Result := TFsReadDir.Create(APath);
end;

function FsReadDirNames(const APath: string): TStringList;
var
  Dir: TFsReadDir;
  Entry: TFsDirEntry;
begin
  Result := TStringList.Create;
  Dir := TFsReadDir.Create(APath);
  try
    while Dir.Next(Entry) do
      Result.Add(Entry.FileName);
  finally
    Dir.Free;
  end;
end;

function FsReadDirEntries(const APath: string): TList;
var
  Dir: TFsReadDir;
  Entry: TFsDirEntry;
  PEntry: ^TFsDirEntry;
begin
  Result := TList.Create;
  Dir := TFsReadDir.Create(APath);
  try
    while Dir.Next(Entry) do
    begin
      New(PEntry);
      PEntry^ := Entry;
      Result.Add(PEntry);
    end;
  finally
    Dir.Free;
  end;
end;

function FsIsDirEmpty(const APath: string): Boolean;
var
  Dir: TFsReadDir;
begin
  Dir := TFsReadDir.Create(APath);
  try
    Result := Dir.IsValid and (Dir.Count = 0);
  finally
    Dir.Free;
  end;
end;

function FsCountFiles(const APath: string): Integer;
var
  Dir: TFsReadDir;
  Entry: TFsDirEntry;
begin
  Result := 0;
  Dir := TFsReadDir.Create(APath);
  try
    while Dir.Next(Entry) do
      if Entry.IsFile then
        Inc(Result);
  finally
    Dir.Free;
  end;
end;

function FsCountDirs(const APath: string): Integer;
var
  Dir: TFsReadDir;
  Entry: TFsDirEntry;
begin
  Result := 0;
  Dir := TFsReadDir.Create(APath);
  try
    while Dir.Next(Entry) do
      if Entry.IsDir then
        Inc(Result);
  finally
    Dir.Free;
  end;
end;

end.
