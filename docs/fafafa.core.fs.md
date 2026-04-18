# fafafa.core.fs - 文件系统模块

> See also: 示例总表（fafafa.core.fs）：docs/EXAMPLES.md#文件系统模块示例总表（fafafa.core.fs）



## 目录（TOC）
- 快速上手（代码）
- 构建与运行示例
- 错误模型
- 行为矩阵（Resolve/ResolvePathEx/Canonicalize）
- 平台差异与最佳实践
- 错误处理示例
- 最佳实践清单（Checklist）
- FAQ（常见问题）

## 快速上手（代码）

- 低层 fs_* 风格
```pascal
var h: TfsFile; buf: array[0..255] of Char; n: Integer;
begin
  h := fs_open('hello.txt', O_RDWR or O_CREAT, S_IRWXU);
  if not IsValidHandle(h) then Halt(1);
  try
    n := fs_write(h, PChar('hi'), 2, -1);
    n := fs_read(h, @buf[0], 2, 0);
  finally
    fs_close(h);
  end;
end;
```

- 高层 IFsFile 风格
```pascal
var f: IFsFile;
begin
  f := TFsFile.Create;
  f.Open('hello.txt', fomReadWrite);
  f.WriteString('hi');
  f.Seek(0, SEEK_SET);
  f.Read(buf, 2);
  f.Close;
end;
```

## 📋 模块概述

`fafafa.core.fs` 是 fafafa 框架中的核心文件系统模块，提供跨平台的高性能文件系统操作接口。该模块设计理念借鉴了现代语言（Rust、Go、Java）中优秀的文件系统库，提供统一、安全、高效的文件操作API。

## 🎯 设计目标

- **跨平台兼容性**: 统一的API在Windows、Linux、macOS等平台上提供一致的行为
- **高性能**: 直接调用系统API，最小化性能开销
- **类型安全**: 强类型设计，编译时捕获错误
- **现代化接口**: 借鉴Rust std::fs、Go os包等现代设计理念
- **错误处理**: 明确的错误返回机制，便于调试和处理；提供 IFsFile（异常语义）与 TFsFileNoExcept（负码语义）两套入口

## 🏗️ 架构设计

### 核心类型

```pascal
// 文件句柄类型
TfsFile = THandle;

## 快速上手：示例输出（示例化）

- example_resolve_and_walk（核心路径解析 + 遍历）
```
ResolvePathEx("./samples", FollowLinks=False, TouchDisk=False) => samples
ResolvePathEx("./samples", FollowLinks=True,  TouchDisk=True)  => C:\work\project\samples
WalkDir: dirs=12 files=48 errors=0 (UseStreaming=True, Sort=False)
PreFilter: skip .git/node_modules
```

- example_copytree_follow（FollowSymlinks=True/False 行为差异）
```
FollowSymlinks=False => exists A/to_B? false
FollowSymlinks=False => exists B/file.txt? true
FollowSymlinks=True  => exists A/to_B/file.txt? true
```

## 构建与运行示例

- 一键运行（推荐）
  - Windows：examples\fafafa.core.fs\example_resolve_and_walk\buildOrRun.bat
  - Linux/macOS：examples/fafafa.core.fs/example_resolve_and_walk/buildOrRun.sh

- 其他示例
  - example_copytree_follow：可在 IDE 中直接打开 .lpr 构建运行；或使用 lazbuild（如提供 .lpi）
  - 注意：Windows 上需要管理员或开发者模式方可创建 symlink；或设置环境变量 FAFAFA_TEST_SYMLINK=1 以条件化测试


// 文件状态结构（跨平台抽象，字段按需使用）
TfsStat = record
  Mode: Cardinal;  // 文件类型与权限位（结合 S_IFMT 判断类型）
  Size: Int64;     // 文件大小（字节）
  // ... 其余平台相关字段省略
end;
```

### 模块结构

```
fafafa.core.fs
├── 核心API (fafafa.core.fs.pas)
├── 平台实现
│   ├── Windows (fafafa.core.fs.windows.inc)
│   └── Unix/Linux (fafafa.core.fs.unix.inc)
├── 错误处理 (fafafa.core.fs.errors.pas)
├── 高级API (fafafa.core.fs.highlevel.pas)
- WalkDir 高层遍历：见 docs/fafafa.core.fs.walk.md


## ⚠️ 错误模型（Error Model）

为兼顾跨平台兼容与可读性，模块采用“可切换”的分层错误返回约定：

- 低层（fs_* 基础 API）默认行为
  - 失败返回“系统错误码”的相反数：Windows 返回 -GetLastError()；Unix 返回 -errno
  - 例：fs_stat 失败 → 返回 -ERROR_FILE_NOT_FOUND（Windows）或 -ESysENOENT（Unix）
  - 说明：这有助于保留系统原生差异，便于定位与诊断

- 高层（WalkDir 等封装 API）
  - 失败返回 TFsErrorCode 的负值（跨平台统一）：如 -FS_ERROR_FILE_NOT_FOUND、-FS_ERROR_ACCESS_DENIED 等
  - 统一分类更便于业务侧做分支处理（配合 FsErrorKind()）


- 重要：FS_UNIFIED_ERRORS 在工程默认启用，低层直接返回 TFsErrorCode 负值；若你依赖旧语义（系统负错误码），可在 src/fafafa.core.settings.inc 中注释该开关恢复旧行为（不推荐）。

- 构建开关：FS_UNIFIED_ERRORS（默认启用）
  - 关闭：低层返回系统负错误码；FsLowLevelReturnsUnified=False
  - 开启（默认）：低层直接返回 TFsErrorCode 负值；FsLowLevelReturnsUnified=True
  - 推荐用法：
    1) 高层/应用层仅依赖 FsErrorKind(aResult) 分类，避免绑定具体负值
    2) 低层如需统一码，使用 SystemErrorToFsError(aResult)；当 FsLowLevelReturnsUnified=True 时，aResult 已是统一码

- fs_open 的推荐失败处理（返回句柄而非错误码）
  - fs_open 成功返回有效 TfsFile 句柄，失败返回 INVALID_HANDLE_VALUE
  - 使用模式：
- fs_errno（线程局部错误码，跨平台统一入口）
  - fs_open 失败后，通过 fs_errno() 获取最近一次错误码；成功时返回 0
  - FS_UNIFIED_ERRORS=On（默认）：返回统一负错误码（如 -FS_ERROR_FILE_NOT_FOUND）
  - FS_UNIFIED_ERRORS=Off：返回负系统错误码（Windows: -GetLastError；Unix: -errno）
  - 建议：仅基于 FsErrorKind(Err) 做分类，不绑定具体数值

    1) if not IsValidHandle(H) then
    2)   LErr := GetSavedFsErrorCode();     // Windows：内部已保存最近失败的系统错误码
    3)   LEfs := SystemErrorToFsError(LErr); // 统一为 TFsErrorCode
    4)   // 根据 FsErrorKind(LEfs) 或 FsErrorToString(LEfs) 进行处理/日志

最佳实践：
- 高层业务只依赖 FsErrorKind 分支，不依赖具体负值，保证开关开/关一致
- 写库代码时，若需要判断“低层是否已统一”，可查询 FsLowLevelReturnsUnified
- WalkDir 已内置守护：两种模式下对外始终返回 TFsErrorCode 负值

└── 路径操作 (fafafa.core.fs.path.pas)
```

## 📚 公共API

### 基础文件操作

#### fs_open
```pascal
function fs_open(const aPath: string; aFlags, aMode: Integer): TfsFile;
```
- **用途**: 打开或创建文件
- **参数**:
  - `aPath`: 文件路径
  - `aFlags`: 打开标志 (O_RDONLY, O_WRONLY, O_RDWR, O_CREAT, O_TRUNC 等)
  - `aMode`: 文件权限模式
- **返回**: 文件句柄，失败时返回INVALID_HANDLE_VALUE
- **异常**: 无（通过返回值判断）

#### fs_close
```pascal
function fs_close(AFile: TfsFile): Integer;
```
- **用途**: 关闭文件句柄
- **参数**: `AFile` - 文件句柄
- **返回**: 成功返回0，失败返回-1

#### fs_read
```pascal
function fs_read(AFile: TfsFile; ABuffer: Pointer; ASize: Cardinal; AOffset: Int64 = -1): Integer;
```
- **用途**: 从文件读取数据
- **参数**:
  - `AFile`: 文件句柄
  - `ABuffer`: 读取缓冲区
  - `ASize`: 要读取的字节数
  - `AOffset`: 读取偏移量（-1表示当前位置）
- **返回**: 实际读取的字节数，失败返回-1

#### fs_write
```pascal
function fs_write(AFile: TfsFile; ABuffer: Pointer; ASize: Cardinal; AOffset: Int64 = -1): Integer;
```
- **用途**: 向文件写入数据
- **参数**:
  - `AFile`: 文件句柄
  - `ABuffer`: 写入缓冲区
  - `ASize`: 要写入的字节数
  - `AOffset`: 写入偏移量（-1表示当前位置）
- **返回**: 实际写入的字节数，失败返回-1

### 文件系统操作

#### fs_unlink
```pascal
function fs_unlink(const APath: string): Integer;
```
- **用途**: 删除文件
- **参数**: `APath` - 文件路径
- **返回**: 成功返回0，失败返回-1

#### fs_rename
```pascal
function fs_rename(const AOldPath, ANewPath: string): Integer;
```
- **用途**: 重命名/移动文件
- **参数**:
  - `AOldPath`: 原路径
  - `ANewPath`: 新路径
- **返回**: 成功返回0，失败返回-1

#### fs_mkdir
```pascal
function fs_mkdir(const APath: string; AMode: Cardinal): Integer;
```
- **用途**: 创建目录
- **参数**:
  - `APath`: 目录路径
  - `AMode`: 目录权限
- **返回**: 成功返回0，失败返回-1

#### fs_rmdir
```pascal
function fs_rmdir(const APath: string): Integer;
```
- **用途**: 删除空目录
- **参数**: `APath` - 目录路径
- **返回**: 成功返回0，失败返回-1

### 文件属性和权限

#### fs_stat
```pascal
function fs_stat(const APath: string; out AStat: TfsStat): Integer;
```
- **用途**: 获取文件状态信息
- **参数**:
  - `APath`: 文件路径
  - `AStat`: 输出的状态信息
- **返回**: 成功返回0，失败返回-1

#### fs_access
```pascal
function fs_access(const APath: string; AMode: Integer): Integer;
```
- **用途**: 检查文件访问权限
- **参数**:
  - `APath`: 文件路径
  - `AMode`: 检查模式 (F_OK, R_OK, W_OK, X_OK)
- **返回**: 成功返回0，失败返回-1

#### fs_chmod
```pascal
function fs_chmod(const APath: string; AMode: Cardinal): Integer;
```
- **用途**: 修改文件权限
- **参数**:
  - `APath`: 文件路径
  - `AMode`: 新的权限模式
- **返回**: 成功返回0，失败返回-1

### 高级功能

#### ResolvePathEx（路径解析增强）
```pascal
function ResolvePathEx(const aPath: string; const aFollowLinks: Boolean; const aTouchDisk: Boolean = False): string;
```
- 语义：
  - aTouchDisk=False（默认）：仅做规范化 + 绝对化，不触盘（与 ResolvePath 行为等价）
  - aTouchDisk=True 且 aFollowLinks=True：若路径存在，尝试调用 realpath（fs_realpath）解析真实路径；失败回退为非触盘路径
  - aTouchDisk=True 且 aFollowLinks=False：仍返回绝对规范路径（不跟随符号链接，保持与 ResolvePath 等价）
- 跨平台：遵循 FS_UNIFIED_ERRORS 一致的错误策略；Windows 下真实路径行为受系统支持影响


### 示例：ResolvePathEx 用法（不触盘 vs 触盘+跟随）
```pascal
var P, A, B: string;
begin
  P := 'example.tmp';
  A := ResolvePathEx(P, True, False);  // 仅规范化+绝对化（不触盘）
  B := ResolvePathEx(P, True, True);   // 若存在则 realpath（触盘+跟随链接），失败回退
end;
```

#### Canonicalize（触盘真实路径）
```pascal
function Canonicalize(const aPath: string; const aFollowLinks: Boolean = True): string;
```
- 语义：
  - 先做 ResolvePath（规范化+绝对化，不触盘）
  - 若路径存在且 aFollowLinks=True，则尝试 `fs_realpath` 获取真实路径；失败回退为规范绝对路径
  - 与 Rust `std::fs::canonicalize` 语义一致；用于需要“落在磁盘上的真实路径”的场景
- 注意：频繁 realpath 会有性能开销；默认仅在确需真实路径时才使用

#### WriteFileAtomic / WriteTextFileAtomic（原子写入）
```pascal
procedure WriteFileAtomic(const aPath: string; const aData: TBytes);
procedure WriteTextFileAtomic(const aPath, aText: string; aEncoding: TEncoding = nil);
```
- 语义：
  - 在目标同目录创建临时文件，写入完成后使用 `fs_replace` 原子覆盖目标
  - 若中途失败，尽力清理临时文件；不会破坏既有目标
- 使用场景：配置写入、元数据落盘、日志切换等需要“要么全写入，要么不改变”语义
- 示例：
```pascal
var S: string;
begin
  S := '{"ver":1}';
  WriteTextFileAtomic('config.json', S, TEncoding.UTF8);
end;
```



#### fs_fsync
```pascal
function fs_fsync(AFile: TfsFile): Integer;
```
- **用途**: 强制将文件数据同步到磁盘
- **参数**: `AFile` - 文件句柄
- **返回**: 成功返回0，失败返回-1

#### fs_realpath
```pascal
function fs_realpath(const APath: string; ABuffer: PChar; ASize: Cardinal): Integer;
```
- **用途**: 获取文件的绝对路径
- **参数**:
  - `APath`: 相对路径
  - `ABuffer`: 输出缓冲区
  - `ASize`: 缓冲区大小
- **返回**: 成功返回路径长度，失败返回-1

#### fs_flock
```pascal
function fs_flock(AFile: TfsFile; AOperation: Integer): Integer;
```
- **用途**: 文件锁定操作
- **参数**:
  - `AFile`: 文件句柄
  - `AOperation`: 锁定操作 (LOCK_SH, LOCK_EX, LOCK_UN, LOCK_NB)
- **返回**: 成功返回0，失败返回-1

### 链接操作（平台差异：Unix 完整支持；Windows 受权限/策略限制，默认不保证可用）

#### fs_symlink
```pascal
function fs_symlink(const ATarget, ALinkPath: string): Integer;
```
- **用途**: 创建符号链接
- **参数**:
  - `ATarget`: 目标路径
  - `ALinkPath`: 链接路径
- **返回**: 成功返回0，失败返回-1

#### fs_readlink
```pascal
function fs_readlink(const APath: string; ABuffer: PChar; ASize: Cardinal): Integer;
```
- **用途**: 读取符号链接目标
- **参数**:
  - `APath`: 符号链接路径
  - `ABuffer`: 输出缓冲区
  - `ASize`: 缓冲区大小
- **返回**: 成功返回目标路径长度，失败返回-1

#### fs_link
```pascal
function fs_link(const AOldPath, ANewPath: string): Integer;
```
- **用途**: 创建硬链接
- **参数**:
  - `AOldPath`: 原文件路径
  - `ANewPath`: 链接路径
- **返回**: 成功返回0，失败返回-1

### 临时文件

#### fs_mkstemp
```pascal
function fs_mkstemp(var ATemplate: string): TfsFile;
```
- **用途**: 创建临时文件
- **参数**: `ATemplate` - 文件名模板（包含XXXXXX）
- **返回**: 文件句柄，失败返回INVALID_HANDLE_VALUE

#### fs_mkdtemp
```pascal
function fs_mkdtemp(var ATemplate: string): string;
```
- **用途**: 创建临时目录
- **参数**: `ATemplate` - 目录名模板（包含XXXXXX）
- **返回**: 创建的目录路径，失败返回空字符串

### 临时文件/目录与文件锁（跨平台）
- mkstemp/mkstemp_ex：创建临时文件，返回句柄（及最终路径，_ex 变体）
  - 模板示例：'myapp_tmp_XXXXXX'（X 由实现替换为随机字符）
  - 清理：使用 fs_close 关闭句柄后 fs_unlink 删除
- mkdtemp：创建临时目录，返回最终路径；使用 fs_rmdir 清理
- flock：文件锁（LOCK_SH/LOCK_EX/LOCK_UN/LOCK_NB）
  - Unix：遵循系统 flock 语义；建议总是配对解锁并在 finally 内清理
  - Windows：提供基本互斥/共享，语义与 POSIX 不完全等价，建议作为进程内/同机轻量协调，跨进程强锁建议使用更高层机制
- 示例：examples/fafafa.core.fs/example_temp_and_lock.lpr


### 辅助函数

#### IsValidHandle
```pascal
function IsValidHandle(AHandle: TfsFile): Boolean;
```
- **用途**: 检查文件句柄是否有效
- **参数**: `AHandle` - 文件句柄
- **返回**: 有效返回True，无效返回False

## 🔧 使用示例

### 基础文件操作
```pascal
var
  LFile: TfsFile;
  LData: string;
  LBuffer: array[0..255] of Char;
  LBytesRead: Integer;
begin
  // 创建并写入文件
  LFile := fs_open('test.txt', O_WRONLY or O_CREAT or O_TRUNC, S_IRWXU);
  if IsValidHandle(LFile) then
  begin
    LData := 'Hello, World!';
    fs_write(LFile, PChar(LData), Length(LData), -1);
    fs_close(LFile);
  end;

  // 读取文件
  LFile := fs_open('test.txt', O_RDONLY, 0);
  if IsValidHandle(LFile) then
  begin
    LBytesRead := fs_read(LFile, @LBuffer[0], SizeOf(LBuffer) - 1, -1);
    LBuffer[LBytesRead] := #0;
    WriteLn('Read: ', string(LBuffer));
    fs_close(LFile);


  end;

  // 删除文件
  fs_unlink('test.txt');
end;
```

### 文件权限检查
```pascal
var
  LResult: Integer;
begin
  // 检查文件是否存在
  LResult := fs_access('myfile.txt', F_OK);
  if LResult = 0 then
    WriteLn('File exists')
  else
    WriteLn('File does not exist');

  // 检查读写权限
  if fs_access('myfile.txt', R_OK) = 0 then
    WriteLn('File is readable');
  if fs_access('myfile.txt', W_OK) = 0 then

### 示例：WalkDir 最小用法（含 PreFilter 与 PostFilter）
```pascal
var Opts: TFsWalkOptions; Count: Integer;
function Pre(const P: string; T: TfsDirEntType; D: Integer): Boolean;
begin
  // 跳过以点开头的目录（如 .git）及其子树
  Result := (ExtractFileName(P) = '') or (ExtractFileName(P)[1] <> '.');
end;
function Post(const P: string; const S: TfsStat; D: Integer): Boolean;
begin
  // 仅回调非空文件，目录总是允许
  if (S.Mode and S_IFMT) = S_IFDIR then Exit(True);
  Result := S.Size > 0;
end;
function Visit(const P: string; const S: TfsStat; D: Integer): Boolean;
begin
  Inc(Count);
  Result := True;
end;
begin
  Count := 0;
  Opts := FsDefaultWalkOptions;
  Opts.PreFilter := @Pre;
  Opts.PostFilter := @Post;
  if WalkDir('some_root', Opts, @Visit) = 0 then ; // 成功：Count 计数有效
end;
```

    WriteLn('File is writable');
end;
```

### 目录操作
```pascal
var
  LResult: Integer;
begin
  // 创建目录
  LResult := fs_mkdir('testdir', S_IRWXU);
  if LResult = 0 then
    WriteLn('Directory created successfully');

  // 删除目录
  LResult := fs_rmdir('testdir');
  if LResult = 0 then
    WriteLn('Directory removed successfully');
end;
```


### 最佳实践示例（FsCopyTreeEx）

- 目标：安全复制目录树，默认不跟随符号链接，必要时可切换
- 推荐：优先 Overwrite=True（目标存在时先移除）、FollowSymlinks=False（保守）、必要时 PreserveTimes/Perms（POSIX 有效）

示例（推荐参数组合）：
```
var C: TFsCopyTreeOptions;
begin
  C.Overwrite := True;
  C.FollowSymlinks := False; // 保守：不跟随，不复制链接本体与其目标
  C.PreserveTimes := True;   // POSIX 有效；Windows best‑effort
  C.PreservePerms := True;   // POSIX 有效；Windows 忽略
  FsCopyTreeEx('src_dir', 'dst_dir', C);
end;
```

- 扩展阅读：docs/partials/fs.best_practices.md（路径、安全、遍历、Copy/Move 策略）
- 相关示例：examples/fafafa.core.fs/example_copytree_follow（演示 FollowSymlinks=True/False 行为差异）
- 测试参考：
  - tests/fafafa.core.fs/Test_fafafa_core_fs_copytree_symlink.pas（Follow=True/False 行为，含 Windows 条件化 symlink）
  - tests/fafafa.core.fs/Test_fafafa_core_fs_copytree_move.pas（覆盖基本复制/移动与 Overwrite 策略）

## 🔗 模块依赖


## 最佳实践

提示：更完整的操作建议见 docs/partials/fs.best_practices.md。默认策略建议：FollowSymlinks 保持 False（保守），在确需跟随链接的场景显式开启，并参考示例 examples/fafafa.core.fs/example_copytree_follow。测试开关速查见该分片的“测试开关速查（Windows/跨平台）”小节。

- 错误处理
  - 高层仅依赖 FsErrorKind/Is* 分类分支，不绑定具体负值，跨平台一致
  - 需要异常语义时用 IFsFile；需要无异常路径时用 TFsFileNoExcept 并显式检查返回码
- 路径使用
  - 比较路径一律先 Normalize/Resolve，再用 PathsEqual/IsSubPath；避免直接字符串比较
  - 默认不触盘，只有确需真实路径时才用 ResolvePathEx(..., FollowLinks=True, TouchDisk=True)
  - 与外部系统交互时优先 ToNativePath，避免分隔符/大小写差异带来的偶发问题
- 符号链接
  - 明确选择是否 FollowLinks；默认策略应保守（不跟随），在需要时再开启
  - Windows 下 symlink 受权限/策略限制，测试用例使用条件开关 FAFAFA_TEST_SYMLINK
- Windows 长路径
  - 仅在系统 LongPathsEnabled 为 True 且依赖方验证通过后，开启 FAFAFA_CORE_FS_ENABLE_WIN_LONGPATH
  - 用例以条件化方式运行，避免在不支持环境误报
- 性能
  - 读写尽量批量化（较大缓冲）；避免频繁调用 realpath 等触盘操作
  - Walk 过滤器尽量早过滤（PreFilter）并按需统计，减少分配与系统调用
- 安全
  - 外部输入先 SanitizePath/IsValidPath；拼路径使用 JoinPath/AppendPath，避免手拼分隔符
  - 删除/覆盖前做 Exists/Access 校验，必要时二次确认
- 测试与示例
  - tests/examples 可使用 {$CODEPAGE UTF8} 输出中文；库单元不加入 CODEPAGE 宏
  - 临时资源（文件/目录）在 finally 中清理；跑完保持 heaptrc 0 泄漏

- 常见陷阱（避免）
  - 直接字符串比较路径；在大小写不敏感平台导致误判
  - 靠相对路径进行安全/权限判断；应先 Resolve 到绝对路径
  - 假定所有环境都支持 symlink/长路径；应通过环境变量/检测条件化执行
  - 忽略返回值/错误分类；应记录日志并做最小可恢复回退

- **fafafa.core.fs.errors**: 错误处理和异常定义；提供错误分类辅助：TFsErrorKind、FsErrorKind/IsNotFound/IsPermission/IsExists
- **fafafa.core.fs.path**: 路径操作工具；说明了 Windows/Unix 大小写与分隔符差异，提供 Normalize/Resolve/ToRelative/IsSubPath/GetCommonPath/PathsEqual
- **fafafa.core.fs.highlevel**: 高级文件操作API（TFsFile 及读写便捷函数）



### 文件系统监控（草案）

- 目标：跨平台 Watch/Notify：Created/Modified/Deleted/Renamed/Overflow/Attrib；递归、过滤、事件合并；原生后端优先，polling 兜底。
- 接口：

```pascal
// 单元：fafafa.core.fs.watch

type
  TFsWatchEventKind = (wekCreated, wekModified, wekDeleted, wekRenamed, wekOverflow, wekAttrib);
  TFsWatchEvent = record
    Kind: TFsWatchEventKind;
    Path, OldPath: string;
    IsDir: Boolean;
    Timestamp: QWord;
    RawError: Integer;
  end;
  TFsWatchOptions = record
    Recursive: Boolean;
    CoalesceLatencyMs: Integer;
    MaxQueue: Integer;
    FollowSymlinks: Boolean;
    Filters: TFsWatchFilters;
    Backend: TFsWatchBackend;
  end;
  IFsWatchObserver = interface
    procedure OnEvent(const E: TFsWatchEvent);
    procedure OnError(const Code: Integer; const Message: string);
  end;
  IFsWatcher = interface
    function Start(const Root: string; const Opts: TFsWatchOptions; const Obs: IFsWatchObserver): Integer;
    procedure Stop;
    function IsRunning: Boolean;
    function Stats(out Dropped, Delivered: QWord): Boolean;
  end;
```

- 行为差异：
  - Windows: ReadDirectoryChangesW + IOCP；递归可能以多句柄实现
  - Linux: inotify；溢出以 wekOverflow 指示
  - macOS: FSEvents；路径级事件、批合并
  - 无原生：低频 polling 兜底
- 测试：条件化 fpcunit（创建/修改/删除/重命名；递归；过滤；溢出）；示例 example_fs_watch.lpr


### 复制/移动内核加速（草案）

- 目的：在不改变对外 API 的前提下，优先走平台原生的高速路径；失败透明回退到安全路径
- 能力与回退（概览）：
  - Windows：CopyFile2 → CopyFileEx → CopyFileW → read/write 循环（跨卷 Move 回退）
  - Linux：copy_file_range → sendfile → read/write 循环（EXDEV/EINVAL 回退）
  - macOS/FreeBSD：fcopyfile/sendfile → read/write 循环
- 控制：
  - 编译期禁用：FAFAFA_CORE_FS_DISABLE_COPYACCEL
  - 运行时开关：环境变量 FAFAFA_FS_COPYACCEL=0/1（默认 1）
- 单元：`src/fafafa.core.fs.copyaccel.pas`（当前为占位，实现逐步补齐）
- 测试与基准：
  - 功能：单文件复制/移动、小/大文件、跨卷、PreserveTimes/Perms 一致性
  - 性能：1GB/4GB 文件复制时间对比脚本（本地运行，不进 CI）


### 异步 I/O 外观（Phase‑1 草案）

- 目标：以现有 fafafa.core.fs.async 中的 IAsyncFile 为基，提供统一命名 IFsFileAsync 的别名与复制移动的异步选项类型
- 单元：`src/fafafa.core.fs.async.iface.pas`
- 内容：
  - type IFsFileAsync = IAsyncFile;
  - record TFsCopyAsyncOptions = (Overwrite/PreserveTimes/PreservePerms/FollowSymlinks/CopySymlinksAsLinks)
  - future 门面函数类型：TCopyFileAsync / TMoveFileAsync（返回 IFuture；带取消令牌）
- 实现：后续在门面单元提供 CreateFsFileAsync/CopyFileAsync/MoveFileAsync 等工厂，不改动现有 IAsyncFile 结构


## 与现代库对齐（Rust / Go / Java）

- 设计取舍
  - Rust std::fs：Result/ErrorKind 分类 → 本模块提供 FsErrorKind 与 IFsFile/NoExcept 两套语义
  - Go io/fs + filepath：最小接口 + 便利函数 → 保持小而美核心，扩展走接口化（IFsFile 已落地）
  - Java NIO Files/Path：静态便捷方法 + 路径对象 → 提供高层便捷函数与路径工具（Normalize/Resolve/PathsEqual）

### 行为矩阵：Resolve / ResolvePathEx / Canonicalize

- 说明：以下矩阵中，“触盘”表示会访问文件系统（如 realpath）；“不触盘”仅做字符串级规范化与绝对化。

| API                         | FollowLinks | TouchDisk | 目标是否存在 | 行为                                                                 |
|----------------------------|-------------|-----------|--------------|----------------------------------------------------------------------|
| Resolve                    | N/A         | N/A       | 任意         | 不触盘：Normalize + 绝对化                                           |
| ResolvePathEx              | True        | False     | 任意         | 不触盘：等同 Resolve                                                  |
| ResolvePathEx              | True        | True      | 存在         | 触盘：realpath 成功则返回真实路径；失败回退为 Resolve 结果           |
| ResolvePathEx              | True        | True      | 不存在       | 不触盘：返回 Resolve 结果                                            |
| ResolvePathEx              | False       | True/False| 任意         | 不跟随链接：不触盘，返回 Resolve 结果                                |
| Canonicalize               | True        | 内部固定  | 存在         | 触盘：尝试 realpath；失败回退为 Resolve 结果                          |
| Canonicalize               | True        | 内部固定  | 不存在       | 不触盘：返回 Resolve 结果                                            |
| Canonicalize               | False       | 内部固定  | 任意         | 不跟随链接：不触盘，返回 Resolve 结果                                |

- 建议：默认使用 Resolve/ResolvePathEx(TouchDisk=False)；仅在需要真实落盘路径时使用 Canonicalize 或 ResolvePathEx(TouchDisk=True, FollowLinks=True)。


#### 示例：Canonicalize vs Resolve（快速运行）

- 一键运行示例：examples/fafafa.core.fs/example_canonicalize_vs_resolve/buildOrRun.bat
- 该示例展示 Resolve（不触盘）、ResolvePathEx（可选触盘/跟随链接）与 Canonicalize（触盘真实路径）的输出差异。

示例代码片段：

```pascal
{$CODEPAGE UTF8}
program example_canonicalize_vs_resolve;

{$mode objfpc}{$H+}

uses
  SysUtils, fafafa.core.fs.path;

var P, R, REx, C1, C2: string;
begin
  P := 'example.tmp';
  R := ResolvePath(P);
  REx := ResolvePathEx(P, True, False);
  C1 := Canonicalize(P, True);
  C2 := Canonicalize(P, False);
  Writeln('Resolve  : ', R);
  Writeln('ResolveEx: ', REx);
  Writeln('Canon(F) : ', C1);
  Writeln('Canon(NF): ', C2);
end.
```


### Copy/Move 高层 API（异常语义）

- 接口（位于 fafafa.core.fs.highlevel）
  - FsCopyFileEx(const Src, Dst: string; const Opts: TFsCopyOptions)
    - Overwrite=False → 使用 UV_FS_COPYFILE_EXCL，不覆盖已存在目标
    - PreserveTimes → best-effort：fs_stat + fs_utime 设置 atime/mtime（平台支持差异）
    - PreservePerms → best-effort：fs_stat + fs_chmod 设置低 9 位权限（POSIX 有效，Windows 忽略）
  - FsMoveFileEx(const Src, Dst: string; const Opts: TFsMoveOptions)
    - 首选 fs_rename（同卷 O(1)）；失败（如跨卷）→ 回退为 FsCopyFileEx + 删除源
    - Overwrite=True 时，若目标存在，先 fs_unlink 目标
- Move 语义（更新）：
  - FsCopyFileEx：Overwrite=True 时统一以“预 unlink”实现覆盖，降低平台差异导致的失败
  - FsMoveTreeEx：若目标不存在，优先整树 rename（同卷 O(1)）；失败（跨卷/占用）则复制后删除源；当 Overwrite=False 且目标存在时抛错
- PreserveTimes/Perms（平台）：
  - POSIX：优先 utimensat/futimens（纳秒），回退 fputimes/fpfutimes（微秒）

提示：关于目录树操作与符号链接行为，请继续阅读下一小节“目录树 Copy/Move（异常语义）”。  - Windows：使用 SetFileTime（best-effort），精度与可用性依平台不同
- 复制性能（平台优化）：
  - Windows：fs_copyfile 使用 CopyFileExW；当 Overwrite=False（UV_FS_COPYFILE_EXCL）时使用 COPY_FILE_FAIL_IF_EXISTS 由系统直接保障排他
  - POSIX：fs_copyfile 优先 copy_file_range（HAS_COPY_FILE_RANGE）；其次 sendfile（HAS_SENDFILE）；均不可用时回退 read/write 循环（64KB 缓冲）



- 行为说明
  - 复制：
    - Overwrite=False 且目标存在 → 抛出 EFsError（内部由 UV_FS_COPYFILE_EXCL 触发）
    - Overwrite=True → 覆盖目标
  - 移动：
    - 优先 rename；失败则 copy + unlink 源
    - Overwrite=False 且目标存在 → 在 rename 或回退 copy 阶段抛出 EFsError（不覆盖）

- 示例

```pascal
var C: TFsCopyOptions; M: TFsMoveOptions;
begin
  C.Overwrite := False; C.PreserveTimes := False; C.PreservePerms := False;
  FsCopyFileEx('a.txt', 'b.txt', C);

  M.Overwrite := True; M.PreserveTimes := False; M.PreservePerms := False;

### Walk 防环机制与平台实现
- 触发条件：仅当 FollowSymlinks=True 时启用 visited-set；默认 False 为零开销
- 关键：为每个即将递归进入的目录生成稳定 Key；若重复则跳过，避免环
- Unix：优先使用 (Dev,Ino) 作为 Key（来自 lstat/fstat）；不可用时退化为 realpath_s
- Windows（当前实现）：使用 realpath_s 作为 Key 的退化方案，确保正确性；未来版本将优先使用 VolumeSerialNumber+FileIndex（GetFileInformationByHandle），仅在不可用时退化到 realpath_s
- 性能建议：
  - 仅在业务语义确需“跟随符号链接”时开启 FollowSymlinks
  - 大型目录树下建议关闭 Sort 与使用 UseStreaming 以减少内存与排序开销

  FsMoveFileEx('b.txt', 'c.txt', M);
end;
```

- 设计取舍
  - 保持小而美：用低层 API 组合，不引入复杂跨平台分支
  - “尽量不触盘”：仅在 PreserveTimes/Perms 需要时读取/设置 stat/utime/chmod
  - 未来可扩展目录级操作（FsCopyTree/FsMoveTree）与错误策略（Continue/SkipSubtree/Abort）

### 目录树 Copy/Move（异常语义）

- 接口（位于 fafafa.core.fs.highlevel）
  - FsCopyTreeEx(const SrcRoot, DstRoot: string; const Opts: TFsCopyTreeOptions)
  - FsMoveTreeEx(const SrcRoot, DstRoot: string; const Opts: TFsMoveTreeOptions)

- 行为与选项
  - Overwrite
    - False：目标存在则抛 EFsError（与文件级一致）
    - True：为避免平台差异导致的复制失败，复制文件前若目标存在会先 fs_unlink 再复制
  - PreserveTimes/PreservePerms：best-effort（与文件级一致）
  - FollowSymlinks
    - 默认 False（保守）：遍历不跟随符号链接（仅按基础类型判定目录/文件，避免环）；目录树复制时将跳过符号链接本体且不复制其目标
    - True：遍历跟随符号链接（内部有 visited-set 防环保护），复制目标内容
  - 遍历策略
    - IncludeFiles=True，IncludeDirs=False：仅递归进入目录，不对目录节点触发回调，避免重复 mkdir/复制

- 示例
```pascal
var C: TFsCopyTreeOptions; M: TFsMoveTreeOptions;
begin
  C.Overwrite := True;
  C.FollowSymlinks := False;
  FsCopyTreeEx('src_dir', 'dst_dir', C);

  M.Overwrite := True;
  M.FollowSymlinks := True;
  FsMoveTreeEx('src_dir2', 'dst_dir2', M);
end;
```
- 更多实践与示例：见 docs/partials/fs.best_practices.md 与 examples/fafafa.core.fs/example_copytree_follow（Windows 需管理员/开发者模式或设置环境变量 FAFAFA_TEST_SYMLINK=1）


- 注意事项
  - Root 解析使用 ResolvePath（与 WalkDir 内部保持一致），相对路径映射使用 ToRelativePath
  - Windows 下符号链接受权限策略影响，需管理员/开发者模式或设置 FAFAFA_TEST_SYMLINK=1 才能在测试环境创建


> Note（Windows 符号链接）
> - 创建符号链接需要管理员权限或启用“开发者模式”；普通用户默认无权创建
> - 测试中可通过设置环境变量 FAFAFA_TEST_SYMLINK=1 来条件化启用/跳过相关用例
> - 目录符号链接需要 SYMBOLIC_LINK_FLAG_DIRECTORY 标志（本模块已按目标类型自动传递）
> - 某些系统策略/杀软/文件系统限制可能导致创建或解析失败，建议在失败时根据 FsErrorKind 做降级处理或跳过

#### PreserveTimes/Perms 示例（best‑effort）
```pascal
var C: TFsCopyTreeOptions;
begin
  C.Overwrite := True;
  C.FollowSymlinks := False;
  C.PreserveTimes := True;
  C.PreservePerms := True;
  FsCopyTreeEx('src_dir', 'dst_dir', C);
end;
```
- POSIX：优先 utimensat/futimens（纳秒），回退 fputimes/fpfutimes（微秒）；权限仅尝试设置低 9 位（chmod），ACL/umask/挂载点可能导致差异
- Windows：时间戳通过 SetFileTime best‑effort；权限位不等价 POSIX，建议使用 ACL 工具链管理权限



- 路径解析矩阵（Resolve vs ResolvePathEx）
  - Resolve：规范化 + 绝对化，不触盘
  - ResolvePathEx(Path, FollowLinks, TouchDisk=False)
    - TouchDisk=False：行为与 Resolve 等价
    - TouchDisk=True 且 FollowLinks=True：若存在尝试 realpath（fs_realpath）；失败回退
    - TouchDisk=True 且 FollowLinks=False：不跟随链接，回退为绝对规范路径
- 统一错误模型

### 构建宏与平台支持矩阵（最佳实践）

目标：在“可用即用”的前提下启用更高性能/更高精度的实现；不可用时保持自动回退，不改变外部语义。

- 宏一览与推荐
  - HAS_COPY_FILE_RANGE（POSIX）
    - 启用条件：内核与 C 库提供 copy_file_range（现代 Linux 内核更佳）
    - 作用：fs_copyfile 优先走内核零拷贝路径，减少用户态往返
    - 注意：跨文件系统可能返回 EXDEV/EINVAL；当前实现遇错即返回错误（不二次回退）。若你的应用大量“跨盘复制”，可暂不启用本宏，沿用 sendfile/read-write 路径
  - HAS_SENDFILE（POSIX）
    - 作用：作为 copy_file_range 不可用时的下一优先路径
    - 注意：不同类 Unix 对“文件→文件”的支持差异大；不支持时将报错并回退到 read/write 实现
  - HAS_UTIMENS / HAS_FUTIMENS（POSIX）
    - 作用：fs_utime/fs_futime 使用纳秒级 utimensat/futimens；不可用时回退到 fputimes/fpfutimes（微秒精度）
  - Windows 无需上述宏：复制使用 CopyFileExW；时间戳使用 SetFileTime（best‑effort）

- 推荐组合（按场景）
  - Linux（同盘/同挂载复制为主）：开启 HAS_COPY_FILE_RANGE + HAS_UTIMENS + HAS_FUTIMENS；HAS_SENDFILE 可选
  - Linux（频繁跨盘复制）：仅开启 HAS_UTIMENS/HAS_FUTIMENS；不启用 HAS_COPY_FILE_RANGE 以避免 EXDEV 立即失败
  - 其他类 Unix：根据平台文档评估 sendfile 对“文件→文件”的支持，再决定是否开启 HAS_SENDFILE

- 启用示例（仅文档指引，不改变项目默认设置）
  - FPC 命令行
    - fpc -dHAS_COPY_FILE_RANGE -dHAS_UTIMENS -dHAS_FUTIMENS your.lpr
  - lazbuild（示例）
    - lazbuild --compileroptions="-dHAS_COPY_FILE_RANGE -dHAS_UTIMENS -dHAS_FUTIMENS" your.lpi
  - Makefile（示意）

### 统一错误码映射（常见项）
- 说明：FS_UNIFIED_ERRORS=On 时，低层直接返回 TFsErrorCode 的负值；Off 时可通过 SystemErrorToFsError 将系统码统一。
- 常见映射（节选）：
  - NotFound：Windows=ERROR_FILE_NOT_FOUND/ERROR_PATH_NOT_FOUND → -FS_ERROR_FILE_NOT_FOUND；Unix=ENOENT → -FS_ERROR_FILE_NOT_FOUND
  - AccessDenied：Windows=ERROR_ACCESS_DENIED → -FS_ERROR_ACCESS_DENIED；Unix=EACCES/EPERM → -FS_ERROR_ACCESS_DENIED/FS_ERROR_PERMISSION_DENIED
  - Exists：Windows=ERROR_FILE_EXISTS/ERROR_ALREADY_EXISTS → -FS_ERROR_FILE_EXISTS；Unix=EEXIST → -FS_ERROR_FILE_EXISTS
  - NotEmpty：Windows=ERROR_DIR_NOT_EMPTY → -FS_ERROR_DIRECTORY_NOT_EMPTY；Unix=ENOTEMPTY → -FS_ERROR_DIRECTORY_NOT_EMPTY
  - Invalid：Windows=ERROR_INVALID_PARAMETER/ERROR_INVALID_NAME → -FS_ERROR_INVALID_PARAMETER/FS_ERROR_INVALID_PATH；Unix=EINVAL → -FS_ERROR_INVALID_PARAMETER
  - NoSpace：Windows=ERROR_DISK_FULL/ERROR_HANDLE_DISK_FULL → -FS_ERROR_DISK_FULL；Unix=ENOSPC → -FS_ERROR_DISK_FULL
  - IO：Windows=ERROR_IO_DEVICE 等 → -FS_ERROR_IO_ERROR；Unix=EIO → -FS_ERROR_IO_ERROR
- 建议：在业务层使用 FsErrorKind() 或 IsNotFound/IsPermission/IsExists 等分类辅助，避免与具体数值耦合。

    - FPCOPTS += -dHAS_COPY_FILE_RANGE -dHAS_UTIMENS -dHAS_FUTIMENS

- 行为保障
  - 若对应功能不可用或发生错误，低层返回统一负错误码；高层保持既有异常/No‑Exception 语义
  - 未启用宏时，自动走安全回退路径（read/write 或微秒级时间戳）

  - 默认启用 FS_UNIFIED_ERRORS：低层直接返回统一错误码负值；建议业务侧仅依赖 FsErrorKind 分类
- 参考文档
  - 详见 docs/fafafa.core.fs.competitor-study.md（竞品调研与落地建议）


### 平台快速检查清单（实践指南）

目的：在不同平台用最小成本确认功能与性能路径“按预期启用/回退”，不引入额外依赖。

- Windows（默认即可）
  1) WalkDir：大目录遍历应走 FindFirstFileExW（LargeFetch）—无需额外配置；必要时以调试日志或性能采样确认
  2) 复制：FsCopyFileEx/FsCopyTreeEx 中 Overwrite=False → 应报“已存在”；Overwrite=True → 能覆盖（内部 pre-unlink + CopyFileExW）
  3) 时间戳：SetFileTime 为 best‑effort，精度可能不及 POSIX；若需精确对齐，请在跨平台层作宽松比较

- Linux/macOS（按需启用宏，保持可回退）
  1) 建议宏：
     - 同盘/同挂载复制为主：-dHAS_COPY_FILE_RANGE -dHAS_UTIMENS -dHAS_FUTIMENS
     - 频繁跨盘复制：仅 -dHAS_UTIMENS -dHAS_FUTIMENS（避免 copy_file_range 在 EXDEV 时立即失败）
  2) 覆盖语义自检：
     - FsCopyFileEx：Overwrite=False + 目标已存在 → 抛错；True → 覆盖
     - FsMoveFileEx：同卷 rename；跨卷完成复制后删除源
  3) 时间戳自检：
     - PreserveTimes=True：复制后用 fs_stat 对比源/目标 atime/mtime；按需容忍 1–3s 浮动（不同文件系统/挂载参数会影响精度）
  4) 回退验证：
     - 未定义 HAS_COPY_FILE_RANGE/HAS_SENDFILE 时，复制走 read/write；功能不变

- 通用注意
  - 错误模型：低层返回统一负码；高层异常携带 ErrorCode，可用 FsErrorKind 分类
  - 长路径/符号链接：Windows 受策略限制；POSIX 注意环路与权限

### 性能提示：Resolve/ResolvePathEx/realpath
- 默认建议：优先使用 Resolve/ResolvePathEx(TouchDisk=False)；仅在确需真实落盘路径时才开启 TouchDisk=True 或调用 Canonicalize
- 真实路径解析（realpath）会触发系统调用并可能进行磁盘访问，在大目录/频繁调用时成本较高
- 缓存建议：对同一父目录多次解析可自行缓存父级结果，减少重复 realpath
- 基准脚本：
  - Windows/Linux：tests/fafafa.core.fs/BuildOrRunResolvePerf.(bat|sh)
  - 产物目录：tests/fafafa.core.fs/performance-data/

  - 性能评估建议在静音环境运行，避免杀毒/索引服务干扰

- 快速操作（纯批处理，推荐）：
  - Resolve 专项：tests\\fafafa.core.fs\\BuildOrRunResolvePerf.bat [root] [iters]
  - Walk 专项：tests\\fafafa.core.fs\\BuildOrRunWalkPerf.bat
  - 汇总一键：tests\\fafafa.core.fs\\BuildOrRunPerfAll.bat（自动与 baseline 对比并输出 CSV 摘要）
  - 基线更新：将 perf_resolve_latest.txt/ perf_walk_latest.txt 覆盖为对应 baseline 文件


## 🧪 测试覆盖

## 🧭 API 速查表（Cheatsheet）
- 打开/读取/写入（无异常语义）：fs_open/fs_read/fs_write/fs_close；失败返回负码或 INVALID_HANDLE_VALUE（fs_open）
- 打开/读取/写入（异常语义）：IFsFile/TFsFile；失败抛出 EFsError（配合 FsErrorKind 分类）
- 路径解析：Resolve（不触盘）、ResolvePathEx(Path, FollowLinks, TouchDisk=False)
- 路径比较：Normalize + PathsEqual；子路径判断：IsSubPath
- 遍历：WalkDir(root, Options, @Visit)；过滤：Options.PreFilter/Options.PostFilter
- 临时文件/目录：fs_mkstemp/fs_mkdtemp
- 锁/同步：fs_flock（注意跨平台差异）
- 真实路径：fs_realpath（触盘，建议按需调用）


### 平台差异与最佳实践补充

- fs_errno（错误来源）
  - 含义：仅报告“最近一次 fs_open 失败”的线程本地错误码；其它 API 以返回值为准
  - 建议：判断错误时优先用返回值并结合 FsErrorKind/Is* 分类；仅在 open 失败场景参考 fs_errno

- mkstemp/mkdtemp（模板规则）
  - Unix：模板必须以 6 个 X 结尾（XXXXXX）；不满足通常失败或返回空
  - Windows：不强制 X 规则，内部以 GUID 生成唯一名；建议仍保留前缀以便调试

- fchmod（权限语义）
  - Unix：正常支持
  - Windows：best‑effort/可能不支持（占位实现返回 0 或负码）；建议上层用 FsErrorKind 判定并降级

- realpath/realpath_s（路径前缀）
  - Windows：实现会去除 \\?\ 前缀并返回 UTF‑8 字符串；缓冲区需包含终止符
  - 缓冲不足：返回统一负错误码

- flock（共享/独占）
  - 不同平台/文件系统的兼容性差异较大；非阻塞（LOCK_NB）在争用时预期返回负码
  - 建议：跨进程/跨语言互操作时优先用“文件级协议 + 重试/回退”策略

示例：

### 错误处理建议与示例

- 建议：优先检查函数返回值（负码为错），并用 FsErrorKind/Is* 做分类；仅在 fs_open 失败时可参考 fs_errno（线程本地）

示例：

```pascal
var h: TfsFile; rc: Integer;
begin
  h := fs_open('data.txt', O_RDONLY, 0);
  if not IsValidHandle(h) then
  begin
    rc := fs_errno; // 仅针对 fs_open 的失败有意义（线程本地保存）
    case FsErrorKind(rc) of
      fekNotFound:   ; // 提示文件不存在
      fekPermission: ; // 提示权限问题
      else            ; // 其它错误统一处理
    end;
    Exit;
  end;
  try
    // 正常读写逻辑...
  finally
    fs_close(h);
  end;
end;
```

- 一键示例（Windows）：examples\fafafa.core.fs\example_resolve_and_walk\buildOrRun.bat
- 一键示例（Linux/macOS）：examples/fafafa.core.fs/example_resolve_and_walk/buildOrRun.sh
- 示例输出/FAQ：见下文“示例工程/常见错误与排查（FAQ）”


### 最佳实践清单（Checklist）

- 路径解析选择
  - 不触盘：Resolve / ResolvePathEx(TouchDisk=False)
  - 触盘并解析链接：ResolvePathEx(TouchDisk=True) 或 Canonicalize（存在时）
- 路径比较/归一
  - 一律使用 Normalize + PathsEqual/IsSubPath，不直接用字符串等号
- 错误处理
  - 以返回值为准（负码即错）+ FsErrorKind 分类；fs_open 失败可参考 fs_errno（线程本地）
- 目录遍历
  - 默认 FollowLinks=False；配合 PreFilter/PostFilter 限定范围；深链或环路由 visited-set 保护
- 临时文件/目录
  - 文件：优先 fs_mkstemp_ex 获取句柄与最终路径，使用后 fs_close + fs_unlink
  - 目录：fs_mkdtemp 使用后 fs_rmdir 清理
- 同步与锁
  - flock 非阻塞（LOCK_NB）+ 重试/回退；跨平台不要强依赖具体返回码语义
- 性能
  - 避免无谓 realpath；合并小 IO；可选启用 Unix 的 FS_USE_PREAD（仅在兼容时）
- 安全
  - 复制/移动时默认不跟随符号链接；对目标写入前验证 IsSubPath(目标, 允许根)
- Windows 专项
  - 长路径：必要时启用 FAFAFA_CORE_FS_ENABLE_WIN_LONGPATH 并做条件化测试
  - realpath_s 已移除 \\?\ 前缀；注意缓冲区大小

### Do / Don’t（速览）

- Do：
  - 使用 Resolve/ResolvePathEx/Canonicalize 的决策矩阵
  - 用 FsErrorKind/Is* 做错误分支（而非比对具体数值）
  - WalkDir 配合过滤器与 OnError 策略，减少磁盘触达
- Don’t：
  - 不直接字符串比较路径
  - 不在库代码中输出中文或使用 {$CODEPAGE UTF8}（仅测试/示例允许）
  - 不假设 flock 在所有平台具备完全一致的语义

### 常见陷阱与规避

- 缓冲不足：realpath/读写 API 需预留终止符；失败返回统一负码
- Windows 只读属性与访问判断：fs_access 在 Windows 以轻量属性推断，可与 POSIX 不同
- 模板不含 X：Unix 下 mkstemp/mkdtemp 失败；Windows 可成功（采用 GUID）


模块包含完整的测试套件，覆盖所有公共API：
- 基础文件操作测试
- 错误处理测试
- 权限和属性测试
- 跨平台兼容性测试
- 性能基准测试

测试位置：`tests/fafafa.core.fs/`

## 📊 性能特性

- 一键基准与归档：tests/fafafa.core.fs/BuildOrRunPerf.(bat|sh)、ArchivePerfResult.(bat|sh)
  - 默认 64MB 顺序读写（128KB 块）、4KB 随机读 5000 次
  - 结果归档至 tests/fafafa.core.fs/performance-data/；可设 baseline.txt 对比

- **零拷贝**: 直接操作系统缓冲区，避免不必要的内存拷贝
- **批量操作**: 支持大块数据的高效读写
- **异步友好**: API设计便于集成异步I/O框架

## 🧪 条件化测试开关（最佳实践）

为避免环境差异导致误报，以下测试默认跳过，需显式开启：

- Windows 长路径（>260 字符）
  - PowerShell:  $env:FAFAFA_TEST_WIN_LONGPATH="1"; tests\fafafa.core.fs\BuildOrTest.bat test
  - CMD:        set FAFAFA_TEST_WIN_LONGPATH=1 && tests\fafafa.core.fs\BuildOrTest.bat test

- 符号链接（Symlink）
  - Unix（默认开启）：如需关闭，设置 FAFAFA_TEST_SYMLINK=0
  - Windows（权限/策略要求）：
    - PowerShell:  $env:FAFAFA_TEST_SYMLINK="1"; tests\fafafa.core.fs\BuildOrTest.bat test
    - CMD:        set FAFAFA_TEST_SYMLINK=1 && tests\fafafa.core.fs\BuildOrTest.bat test

说明：
- 无论是否开启，这些测试均不改变实现，只用于验证在支持环境下的行为
- CI 中建议保持默认（关闭），在专用环境/Runner 上单独开启

- **内存安全**: 严格的边界检查和资源管理

## 🔒 安全与行为差异

- **路径验证**: 防止路径遍历攻击
- **权限检查**: 严格的文件权限验证
- **资源管理**: 自动的文件句柄清理
- **错误处理**: 明确的错误状态和异常处理；低层返回负错误码（-errno / -GetLastError），高层可用 FsErrorKind 与 IsNotFound/IsPermission/IsExists 判定
- **Windows 长路径行为与限制**
  - 仅在 LongPathsEnabled 为 True 且/或启用 FAFAFA_CORE_FS_ENABLE_WIN_LONGPATH 宏时，才建议在生产环境使用超长路径
  - 测试：通过环境变量 FAFAFA_TEST_WIN_LONGPATH=1 显式开启长路径测试；在不支持环境将自动跳过
  - 兼容性：部分旧 API/第三方库对 \?\ 前缀不兼容；建议统一通过 ToNativePath/ResolvePathEx 规避分隔符/大小写问题，必要时保守降级
  - ValidatePath（Windows 路径长度判定）
    - 若启用 FAFAFA_CORE_FS_ENABLE_WIN_LONGPATH：放宽到 ~32767 宽字符限制（保守检查）
    - 未启用：沿用传统 MAX_PATH=260 限制
    - 提示：这是“路径合法性检查”的保守策略，不影响实际 I/O 路径扩展前缀逻辑（\?\、\?\UNC\），仅作为输入早期筛查之用


## 示例工程
- 路径：examples/fafafa.core.fs/example_resolve_and_walk
- 功能：演示 ResolvePathEx（不触盘/触盘+跟随）与 WalkDir（PreFilter/PostFilter）
- 构建与运行（Windows）：examples\fafafa.core.fs\example_resolve_and_walk\buildOrRun.bat
- 说明：输出包含绝对/真实路径与遍历的条目列表（过滤掉以“.”开头的目录，忽略空文件）
- 示例输出（节选）：

```
--- ResolvePathEx demo ---
Input  : example.tmp
Abs    : D:\...\example.tmp
Real   : D:\...\example.tmp
--- WalkDir demo ---
0: <repo_root>
1: <repo_root>\bin
1: <repo_root>\docs
1: <repo_root>\src
1: ...
```


  - 性能：创建深层目录/文件时建议逐层创建与清理，避免一次性失败；减少不必要的 realpath 调用

- **平台差异（路径）**:

## 🛠️ 常见错误与排查（FAQ）
- 路径分隔符与大小写
  - Windows 大小写不敏感且分隔符 \ 与 / 均可；Unix 区分大小写仅 / 有效
  - 建议统一使用 Normalize/Resolve + PathsEqual/IsSubPath 进行比较，避免直接字符串等号
- 触盘 vs 不触盘
  - Resolve 默认不触盘；仅当确需真实路径时使用 ResolvePathEx(..., FollowLinks=True, TouchDisk=True)
  - realpath（触盘）失败会自动回退，注意避免在热路径频繁调用
- 长路径前提
  - Windows 需 LongPathsEnabled 且（可选）启用 FAFAFA_CORE_FS_ENABLE_WIN_LONGPATH 宏；测试用例通过 FAFAFA_TEST_WIN_LONGPATH 控制
- 符号链接
  - 默认不跟随；如需跟随，在 Walk/ResolvePathEx 中显式开启 FollowLinks
  - Windows 下 symlink 受权限/策略限制；测试需显式开启 FAFAFA_TEST_SYMLINK
- 错误分类与处理
  - 业务仅依赖 FsErrorKind/Is* 分类；低层返回值是否统一由 FS_UNIFIED_ERRORS 控制（默认已启用）

- 构建失败：Can't find unit fafafa.core.fs
  - 检查 .lpi 的 <OtherUnitFiles> 是否包含 src 目录（例如 ../../../src 或项目根下的 src）
  - 使用 lazbuild 构建时工作目录是否为工程根；或在 .bat 中显式使用绝对路径
- 真实路径/长路径异常
  - Windows 未开启 LongPathsEnabled 或未定义 FAFAFA_CORE_FS_ENABLE_WIN_LONGPATH；请参考“Windows 长路径支持”小节
- 符号链接相关失败
  - Windows 默认策略限制创建 symlink；需以管理员权限或启用 Developer Mode，并在测试/示例前设置 FAFAFA_TEST_SYMLINK=1

### 符号链接与长路径常见问题（FAQ 补充）
- Windows 无法创建符号链接
  - 现象：fs_symlink 失败或示例/测试跳过
  - 排查：是否以管理员权限运行或启用“开发者模式”；是否设置 FAFAFA_TEST_SYMLINK=1
- 长路径相关操作异常
  - 现象：路径超长时报错或第三方库不识配
  - 排查：系统 LongPathsEnabled 是否开启；（可选）启用 FAFAFA_CORE_FS_ENABLE_WIN_LONGPATH；注意与旧 API/第三方的 \?\ 前缀兼容性

- 运行时路径输出与预期不同
  - ResolvePathEx 默认不触盘；若需真实路径，请传 TouchDisk=True；另注意 FollowLinks 的取值


## 🧵 Windows 长路径支持（FAFAFA_CORE_FS_ENABLE_WIN_LONGPATH）

- 背景：传统 Win32 API 存在 MAX_PATH 限制。启用该开关后，模块会在“绝对路径”上自动加上 Win32 扩展前缀：
  - 驱动器盘符路径：\\?\C:\...
  - UNC 路径：\\?\UNC\server\share\...
- 默认：关闭（保守，不改变旧行为）。启用方法：在 src/fafafa.core.settings.inc 中取消注释 {$DEFINE FAFAFA_CORE_FS_ENABLE_WIN_LONGPATH}
- 注意事项：
  1) 系统或组策略需允许长路径（Win10+ 可配置 LongPathsEnabled）
  2) 相对路径不会加前缀（会交由 API 解析或先绝对化）
  3) 与部分旧 API/第三方库交互可能存在兼容性问题，建议先在本地环境验证
- 测试建议：
  - 在 tests/fafafa.core.fs 中添加条件化用例，仅在检测到系统支持长路径时才运行；或使用环境变量控制是否执行该用例

  - Windows：路径比较大小写不敏感（PathsEqual 内部使用 AnsiCompareText），分隔符 \ 与 / 均可；驱动器与 UNC 前缀特殊处理
  - Unix：路径比较大小写敏感，仅 / 为分隔符

---

*文档版本: 1.1（更新平台实现与错误分类辅助说明）*
*最后更新: 2025-01-06*



### Darwin/macOS 注记

- 实现与行为：本模块在 Darwin/macOS 沿用 unix.inc 分支，整体行为与 Linux 基本一致；个别系统调用按可用性自动回退（保持对外语义一致）。
- 路径与大小写：macOS 常见文件系统（APFS 默认）可能为大小写不敏感；建议路径比较一律使用 Normalize/Resolve + PathsEqual/IsSubPath，避免直接字符串等号。
- 真实路径解析：Canonicalize/ResolvePathEx(TouchDisk=True) 在目标存在时会触盘调用 realpath；失败自动回退为规范化绝对路径。
- 权限与时间戳：PreserveTimes/Perms 为 best‑effort；时间戳精度取决于平台；权限位以 POSIX 低 9 位为主，ACL/挂载选项可能影响最终效果。
- 符号链接：FollowSymlinks=False 为默认保守策略；开启跟随后，WalkDir 内部有 visited‑set 防环保护。
