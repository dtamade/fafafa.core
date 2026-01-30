# fafafa.core.fs API参考文档
# fafafa.core API 总览

- OS 模块（系统信息与能力探测）
  - 文档：docs/fafafa.core.os.md（快速上手、构建与运行、FAQ、平台差异）
  - 示例：examples/fafafa.core.os/example_basic.lpi / example_capabilities.lpi

---


## 📚 模块概览

fafafa.core.fs提供了完整的文件系统操作API，包括：

- **底层API** (`fafafa.core.fs`) - 平台特定的文件系统调用
- **高级接口** (`fafafa.core.fs.highlevel`) - 面向对象的文件操作类（IFsFile）；提供 No-Exception 包装（TFsFileNoExcept）
- **路径操作** (`fafafa.core.fs.path`) - 路径处理和验证函数
- **错误处理** (`fafafa.core.fs.errors`) - 统一的错误处理机制

## 🏗️ 核心类型

### 文件打开模式 (TFsOpenMode)

```pascal
type
  TFsOpenMode = (
    fomRead,      // 只读模式
    fomWrite,     // 只写模式（截断）
    fomReadWrite, // 读写模式
    fomCreate,    // 创建模式（读写，截断）
    fomAppend     // 追加模式
  );

### 目录遍历 WalkDir 选项（TFsWalkOptions）

- UseStreaming: Boolean
  - True：流式遍历（不排序），逐项回调；内存占用低；顺序依赖底层枚举
  - False：缓冲+可排序；当 Sort=True 时收集所有条目后进行稳定排序
- Sort: Boolean
  - True：稳定排序输出；与 UseStreaming=True 冲突时会走缓冲路径
  - False：不排序

示例：

```pascal
var opts: TFsWalkOptions; rc: Integer;
begin
  opts := FsDefaultWalkOptions;
  // 流式遍历（不排序）
  opts.UseStreaming := True;
  opts.Sort := False;
  rc := WalkDir('root', opts, @OnVisit);

  // 缓冲+排序
  opts := FsDefaultWalkOptions;
  opts.Sort := True;
  rc := WalkDir('root', opts, @OnVisit);
end;

#### OnError 错误处理（简述）

- 策略：`TFsWalkErrorAction = (weaContinue, weaSkipSubtree, weaAbort)`
- 回调：`TFsWalkOnError = function(const Path: string; Error: Integer; Depth: Integer): TFsWalkErrorAction of object;`
- 语义：
  - weaContinue：忽略错误继续；若根路径无效，整体返回 0（等价空遍历）
  - weaSkipSubtree：跳过当前子树继续
  - weaAbort：立即返回统一负错误码
- 默认（OnError=nil）：沿用旧行为；根路径无效直接返回负统一错误码


### WalkDir 进阶示例

```pascal
function PreSkipDot(const APath: string; ABasic: TfsDirEntType; ADepth: Integer): Boolean;
var name: string;
begin
  name := ExtractFileName(APath);
  // 跳过隐藏目录与文件，并剪枝
  Result := (name = '') or (name[1] <> '.');
end;

function PostOnlyLargeFiles(const APath: string; const AStat: TfsStat; ADepth: Integer): Boolean;
begin
  // 只回调大于 1KB 的文件；目录总是允许
  if (AStat.Mode and S_IFMT) = S_IFDIR then Exit(True);
  Result := AStat.Size > 1024;
end;

function OnVisit(const APath: string; const AStat: TfsStat; ADepth: Integer): Boolean;
begin
  // TODO: 处理条目；返回 False 可早停
  Result := True;
end;

var opts: TFsWalkOptions; stats: TFsWalkStats; rc: Integer;
begin
  FillChar(stats, SizeOf(stats), 0);
  opts := FsDefaultWalkOptions;
  opts.PreFilter := @PreSkipDot;
  opts.PostFilter := @PostOnlyLargeFiles;
  opts.Stats := @stats;
  opts.MaxDepth := 3;

  // 流式（不排序）
  opts.UseStreaming := True;
  opts.Sort := False;
  rc := WalkDir('root', opts, @OnVisit);
end;
```

```

```

### 文件共享模式 (TFsShareMode)

```pascal
type
  TFsShareMode = set of (
    fsmRead,    // 允许其他进程读取
    fsmWrite,   // 允许其他进程写入
    fsmDelete   // 允许其他进程删除/重命名
  );
```

说明：
- Windows：映射到 CreateFileW 的共享标志（FILE_SHARE_READ/WRITE/DELETE）。若调用方传空集合（[]），为保持兼容，将启用“全共享”。
- Unix (English): TFsShareMode is currently ignored (there are no CreateFile-like share flags). If sharing semantics are required, consider advisory locking (fcntl) at a higher layer.
- 用法示例：
  - 只读并仅共享读取：Open(path, fomRead, [fsmRead])
  - 读写并共享读写：Open(path, fomReadWrite, [fsmRead, fsmWrite])
  - 不允许删除：不要包含 fsmDelete

### 路径信息结构 (TPathInfo)

```pascal
type
  TPathInfo = record
    Path: string;        // 完整路径
    Directory: string;   // 目录部分
    FileName: string;    // 文件名部分
    BaseName: string;    // 基础名称（无扩展名）
    Extension: string;   // 扩展名
    IsAbsolute: Boolean; // 是否为绝对路径
    IsRelative: Boolean; // 是否为相对路径
    Exists: Boolean;     // 是否存在
  end;
```

## 🎯 核心类

### IFsFile / TFsFile - 高级文件操作接口/类

#### 构造和析构

```pascal
constructor Create;
destructor Destroy; override;
```

#### 文件操作方法

```pascal
// 打开文件（接口）
procedure Open(const aPath: string; aMode: TFsOpenMode);

// 关闭文件
procedure Close;

// 读取数据
function Read(var aBuffer; aCount: Integer): Integer;

// 写入数据
function Write(const aBuffer; aCount: Integer): Integer;

// 刷新缓冲区
procedure Flush;

// 截断文件
procedure Truncate(aSize: Int64);
```

#### 便利方法（TFsFile 实现）

```pascal
// 字符串操作
function ReadString(aEncoding: TEncoding = nil): string;
procedure WriteString(const aText: string; aEncoding: TEncoding = nil);

// 字节数组操作
function ReadBytes: TBytes;
procedure WriteBytes(const aBytes: TBytes);
```

#### 属性

```pascal
property Handle: TfsFile read FHandle;           // 文件句柄
property Path: string read FPath;                // 文件路径
property IsOpen: Boolean read FIsOpen;           // 是否已打开
property Size: Int64 read GetSize;               // 文件大小
property Position: Int64 read GetPosition write SetPosition; // 文件位置
```

#### 使用示例

```pascal
var
  LFile: TFsFile;
  LContent: string;
begin
  LFile := TFsFile.Create;
  try
    // 创建并写入文件
    LFile.Open('example.txt', fomCreate);
    LFile.WriteString('Hello, World!');
    LFile.Close;


### 工厂与便捷选项（IFsFile）

- OpenFileEx：
  - `function OpenFileEx(const Path: string; const Opts: TFsOpenOptions): IFsFile;`
  - 以选项打开并返回 IFsFile；失败抛出 EFsError，且保证异常路径释放实例
- FsOpts* 便捷别名：
  - `FsOptsReadOnly / FsOptsWriteTruncate / FsOptsReadWrite`
  - 为 `FsOpenOptions_*` 的简写，便于快速书写

    // 读取文件
    LFile.Open('example.txt', fomRead);
    LContent := LFile.ReadString;
    LFile.Close;

    Writeln('内容: ', LContent);
  finally
    LFile.Free;
  end;
end;
```

## 🛤️ 路径操作函数

### 路径验证和清理

```pascal
// 验证路径安全性
function ValidatePath(const aPath: string): Boolean;

// 清理路径中的危险字符
function SanitizePath(const aPath: string): string;

// 检查是否为有效路径
function IsValidPath(const aPath: string): Boolean;

// 检查是否为有效文件名
function IsValidFileName(const aFileName: string): Boolean;

// 清理文件名
function SanitizeFileName(const aFileName: string): string;
```

### 路径构造和解析

```pascal
// 解析路径信息
function ParsePath(const aPath: string): TPathInfo;

// 连接路径
function JoinPath(const aPath1, aPath2: string): string; overload;
function JoinPath(const aParts: array of string): string; overload;

// 标准化路径
function NormalizePath(const aPath: string): string;

// 解析相对路径
function ResolvePath(const aPath: string): string;
```

### 路径查询

```pascal
// 路径类型判断
function IsAbsolutePath(const aPath: string): Boolean;
function IsRelativePath(const aPath: string): Boolean;

// 路径存在性检查
function PathExists(const aPath: string): Boolean;

// 获取路径类型
function GetPathType(const aPath: string): TPathType;
```

### 路径组件提取

```pascal
// 提取目录部分
function ExtractDirectory(const aPath: string): string;

// 提取文件名
function ExtractFileName(const aPath: string): string;

// 提取基础名称（无扩展名）
function ExtractBaseName(const aPath: string): string;

// 提取文件扩展名
function ExtractFileExtension(const aPath: string): string;

// 提取驱动器（Windows）
function ExtractDrive(const aPath: string): string;
```

### 路径转换

```pascal
// 转换为绝对路径
function ToAbsolutePath(const aPath: string): string;

// 转换为相对路径
function ToRelativePath(const aPath, aBasePath: string): string;

// 转换为Unix风格路径
function ToUnixPath(const aPath: string): string;

// 转换为Windows风格路径
function ToWindowsPath(const aPath: string): string;

// 转换为本地风格路径
function ToNativePath(const aPath: string): string;
```

### 路径比较

```pascal
// 比较路径是否相等
function PathsEqual(const aPath1, aPath2: string): Boolean;

// 检查是否为子路径
function IsSubPath(const aPath, aParentPath: string): Boolean;

// 获取公共路径
function GetCommonPath(const aPaths: array of string): string;
```

### 路径操作

```pascal
// 更改文件扩展名
function ChangeExtension(const aPath, aNewExt: string): string;

// 追加路径
function AppendPath(const aBasePath, aSubPath: string): string;

// 获取父路径
function GetParentPath(const aPath: string): string;

// 获取路径深度
function GetPathDepth(const aPath: string): Integer;
```

### 特殊路径

```pascal
// 获取当前目录
function GetCurrentDirectory: string;

// 获取临时目录
function GetTempDirectory: string;

// 获取用户主目录
function GetHomeDirectory: string;

// 获取可执行文件目录
function GetExecutableDirectory: string;
```

## 🔧 便利函数

### 文本文件操作

```pascal
// 读取文本文件
function ReadTextFile(const aPath: string; aEncoding: TEncoding = nil): string;

// 写入文本文件
procedure WriteTextFile(const aPath, aText: string; aEncoding: TEncoding = nil);
```

### 二进制文件操作

```pascal
// 读取二进制文件
function ReadBinaryFile(const aPath: string): TBytes;

// 写入二进制文件
procedure WriteBinaryFile(const aPath: string; const aData: TBytes);
```

### 文件系统查询

```pascal
// 检查文件是否存在
function FileExists(const aPath: string): Boolean;

// 检查目录是否存在
function DirectoryExists(const aPath: string): Boolean;

// 获取文件大小
function GetFileSize(const aPath: string): Int64;

// 获取文件修改时间
function GetFileModificationTime(const aPath: string): TDateTime;
```

## ⚠️ 错误处理与 No-Exception 模式

### No-Exception 包装（TFsFileNoExcept）

```pascal
function NewFsFileNoExcept: TFsFileNoExcept;
// 使用示例
var fn: TFsFileNoExcept; code, n: Integer; pos: Int64;
begin
  fn := NewFsFileNoExcept;
  code := fn.Open('data.bin', fomReadWrite);
  if code < 0 then Exit;
  code := fn.Write(buf, len, n);
  code := fn.Seek(0, SEEK_END, pos);
  code := fn.Close;
end;
```

> 提示：用 FsErrorKind/IsNotFound/IsPermission 等工具进行分类，避免依赖具体负值

### 异常模型

### 异常类型

```pascal
type
  EFsError = class(Exception)
  private
    FErrorCode: TFsErrorCode;
    FSystemErrorCode: Integer;
  public
    constructor Create(aErrorCode: TFsErrorCode; const aMessage: string; aSystemErrorCode: Integer);
    property ErrorCode: TFsErrorCode read FErrorCode;
    property SystemErrorCode: Integer read FSystemErrorCode;
  end;
```

### 错误代码

```pascal
type
  TFsErrorCode = (
    FS_ERROR_SUCCESS = 0,
    FS_ERROR_FILE_NOT_FOUND = -1,
    FS_ERROR_ACCESS_DENIED = -2,
    FS_ERROR_INVALID_PARAMETER = -3,
    FS_ERROR_INVALID_HANDLE = -4,
    FS_ERROR_INVALID_PATH = -5,
    FS_ERROR_DISK_FULL = -6,
    FS_ERROR_IO_ERROR = -7,
    FS_ERROR_UNKNOWN = -999
  );
```

### 错误处理函数

```pascal
// 获取最后的文件系统错误
function GetLastFsError: TFsErrorCode;

// 将错误代码转换为字符串
function FsErrorToString(aErrorCode: TFsErrorCode): string;

// 将系统错误转换为文件系统错误
function SystemErrorToFsError(aSystemError: Integer): TFsErrorCode;
```

### 错误处理示例

```pascal
try
  LFile.Open('nonexistent.txt', fomRead);
except
  on E: EFsError do
  begin
    Writeln('文件系统错误: ', E.Message);
    Writeln('错误代码: ', Integer(E.ErrorCode));
    Writeln('系统错误: ', E.SystemErrorCode);
  end;
end;
```

## 🔒 安全特性

### 路径安全验证

```pascal
// 自动阻止的危险模式
ValidatePath('../../../etc/passwd');        // False - 路径遍历
ValidatePath('file' + #0 + 'name.txt');     // False - 空字节注入
ValidatePath('CON');                         // False - Windows保留名
ValidatePath('%2e%2e/encoded.txt');         // False - URL编码攻击
```

### 安全的路径清理

```pascal
// 自动清理危险内容
SanitizePath('file<name>.txt');             // 'file_name_.txt'
SanitizePath('../dangerous/path.txt');      // 'dangerous/path.txt'
SanitizePath('file' + #0 + 'name.txt');     // 'filename.txt'
```

## 📝 使用最佳实践

### 1. 资源管理

```pascal
// 推荐：使用try-finally确保资源释放
LFile := TFsFile.Create;
try
  LFile.Open('file.txt', fomRead);
  // 文件操作...
finally
  LFile.Free; // 自动调用Close
end;
```

### 2. 错误处理

```pascal
// 推荐：捕获特定异常
try
  LFile.Open(LPath, fomRead);
except
  on E: EFsError do
    case E.ErrorCode of
      FS_ERROR_FILE_NOT_FOUND: Writeln('文件不存在');
      FS_ERROR_ACCESS_DENIED: Writeln('访问被拒绝');
      else Writeln('其他错误: ', E.Message);
    end;
end;
```

### 3. 路径处理

```pascal
// 推荐：始终验证路径
if ValidatePath(LUserPath) then
begin
  LFile.Open(LUserPath, fomRead);
  // 安全的文件操作...
end
else
  raise Exception.Create('不安全的路径');
```

---

**📚 完整的API参考，助您高效开发！**
