# IFsFile 接口与迁移（设计与现状）

最后更新：2025-08-12（已落地：IFsFile 与 TFsFileNoExcept；perf 一键脚本 Win/Linux）  负责人：Augment Agent

## 目标
- 为底层文件操作提供面向接口的抽象，便于依赖注入、替换实现（内存文件、模拟/加密/压缩层等）
- 保持与现有 TFsFile/低层 fs_* API 的向后兼容
- 与现代竞品（Rust File、Go os.File、Java SeekableByteChannel）在抽象与语义上对齐

## 设计原则
- 面向接口：以 IFsFile 定义行为，具体实现由 TFsFile 或其他类提供
- 错误模型：对外抛出 EFsError（承载统一 TFsErrorCode 与系统错误码），或返回值中统一负值（由高层封装转异常）
- 跨平台一致：Windows/Unix 行为一致，差异由内部消化

## 接口与实现现状

```
type
  TFsOpenMode = (
    fomRead,        // 只读
    fomWrite,       // 仅写（清零）
    fomReadWrite,   // 读写
    fomAppend       // 追加
  );

  IFsFile = interface
    ['{6B7925C9-4E32-4E4D-9B3A-0D1E3D3B8A71}']
    // 生命周期
    procedure Open(const APath: string; AMode: TFsOpenMode); // 默认共享策略（兼容模式）
  // 实现类还提供：Open(const aPath: string; aMode: TFsOpenMode; aShare: TFsShareMode) 以显式控制共享
    procedure Close;
    function  IsOpen: Boolean;

    // 位置与大小
    function  Seek(ADistance: Int64; AWhence: Integer): Int64; // SEEK_SET/CUR/END
    function  Tell: Int64;
    function  Size: Int64;                // 通过 fstat 获取
    procedure Truncate(ANewSize: Int64);  // 截断或扩展

    // 同步
    procedure Flush; // 等价于 fs_fsync（或缓冲刷盘）

    // 读写（阻塞）
    function  Read(var ABuffer; ACount: SizeUInt): Integer;   // 返回读取字节数，0=EOF
    function  Write(const ABuffer; ACount: SizeUInt): Integer; // 返回写入字节数

    // 可选：定位读写
    function  PRead(var ABuffer; ACount: SizeUInt; AOffset: Int64): Integer;   // 可默认用 Seek+Read 实现
    function  PWrite(const ABuffer; ACount: SizeUInt; AOffset: Int64): Integer; // 可默认用 Seek+Write 实现
  end;

function NewFsFile: IFsFile; // 工厂：返回默认实现（TFsFileAdapter）
function NewFsFileNoExcept: TFsFileNoExcept; // 无异常包装：返回负错误码
```

说明：
- 默认实现 TFsFileAdapter 内部直接调用现有 fs_open/fs_read/fs_write 等低层 API
- 错误处理：
  - Adapter 方式 A：方法抛出 EFsError（带统一码 TFsErrorCode、SystemErrorCode、Path 等上下文）
  - Adapter 方式 B：方法返回整数（>=0 成功，<0 统一负错误码），再由上层统一抛异常
- 迁移：现有使用 TFsFile 的调用方可逐步替换为 IFsFile（工厂返回适配器包装 TFsFile 或直接低层）

## 行为细节
- Open：
  - fomWrite 清空文件；fomAppend 写入时定位到末尾
  - 不存在且写模式：创建
  - 共享（TFsShareMode，Windows 生效，Unix 当前忽略）：
    - fsmRead/fsmWrite/fsmDelete 分别映射到 CreateFileW 的 FILE_SHARE_READ/WRITE/DELETE
    - 兼容性：传入空集合（[]）时默认启用全共享（READ|WRITE|DELETE）
    - Unix (English): TFsShareMode is currently ignored (no CreateFile-like share flags). If you need inter-process coordination, consider advisory locking (fcntl) at a higher layer.
  - 失败：抛出 EFsError 或返回统一负码（依实现策略）
- Seek/Tell：遵循 fs_seek/fs_tell 语义，失败返回负码或抛异常
- Flush：调用 fs_fsync
- Size：通过 fs_fstat 获取 Size
- Truncate：调用 fs_ftruncate
- PRead/PWrite：可选优化路径（Windows 使用 OVERLAPPED，Unix 使用 pread/pwrite）；无优化时用 Seek+Read/Write 退化实现

## 测试计划（fpcunit）
- TTestCase_IFsFile_OpenClose
  - Open 不同模式（Read/Write/ReadWrite/Append）；不存在文件的行为；权限错误
- TTestCase_IFsFile_ReadWrite
  - 小/中/大缓冲区的读写；EOF；Write 后 Size 变化
- TTestCase_IFsFile_SeekTell
  - 绝对/相对/末尾定位；非法定位（负位置）
- TTestCase_IFsFile_Truncate
  - 截断后 Size/读取验证；扩展后空洞
- TTestCase_IFsFile_Flush
  - 写入后 Flush；（可在 Windows 以文件占用与时间戳间接验证）
- TTestCase_IFsFile_PReadPWrite（可选）
  - 随机位置的块读写，验证偏移与内容

注：初期将测试以默认 Adapter 返回值为负码的策略编写，随后再增加“抛异常策略”的变体测试（通过编译开关或构造函数参数选择）。

## 渐进式迁移策略
- 第 1 阶段（已完成）：接口与工厂落地；提供 TFsFileNoExcept（负码语义）与测试；默认行为不变
- 第 2 阶段（进行中）：为 Adapter 增加 PRead/PWrite 优化路径（保持签名与语义）
- 第 3 阶段：业务模块逐步改造为依赖 IFsFile（便于 Mock/替换）
- 第 4 阶段：封装 TFsFile 细节，避免直接依赖具体类

## 对齐竞品（摘要）
- Rust File：Read/Write/seek/metadata，同步/阻塞；OpenOptions builder
- Go os.File：Read/Write/Seek/Stat/Sync；FileMode 与权限；Append/Truncate
- Java SeekableByteChannel：position/read/write/truncate/force；Files.newByteChannel

## 迁移步骤（简版）
1) 用 NewFsFile/NewFsFileNoExcept 替换直接使用 TFsFile 的构造
2) 接口化字段：将类成员从 TFsFile 改为 IFsFile（必要时改造构造函数注入）
3) 错误处理：
   - 异常语义：捕获 EFsError；或继续让异常向上传播
   - 负码语义：按 FsErrorKind/IsNotFound/IsPermission 等工具分类处理
4) 读写字符串：统一使用 TEncoding.GetString/GetBytes，避免隐式转换
5) 行为验证：运行 tests/fafafa.core.fs/BuildOrTest.*；必要时补充边界用例

## 示例：从 TFsFile 迁移到 IFsFile（异常语义）

```pascal
// 旧：直接用 TFsFile（易散落在代码中，异常捕获分散）
var F: TFsFile;
begin
  F.Open('data.bin', fomReadWrite);
  try
    // ...读写...
  finally
    F.Close;
  end;
end;

// 新：依赖 IFsFile 接口（便于注入/Mock/替换实现）
var IFile: IFsFile;
begin
  IFile := NewFsFile;
  IFile.Open('data.bin', fomReadWrite);
  try
    // ...读写...
  finally
    IFile.Close;
  end;
end;
```

## 示例：No-Exception（负码语义）典型错误分类

```pascal
var FN: TFsFileNoExcept; code, n: Integer;
    buf: array[0..4095] of Byte; path: string;
begin
  FN := NewFsFileNoExcept;
  path := 'maybe_missing.bin';
  code := FN.Open(path, fomRead);
  if code < 0 then
  begin
    // 统一分类，不依赖具体负值
    if IsNotFound(code) then
      Writeln('not found')
    else if IsPermission(code) then
      Writeln('permission denied')
    else if IsExists(code) then
      Writeln('already exists')
    else
      Writeln('others: ', Ord(code));
    Exit;
  end;
  code := FN.Read(buf, SizeOf(buf), n);
  // ...
  FN.Close;
end;
```

## 下一步

## 两种错误语义（异常/负码）

- 默认：异常语义（EFsError）更简洁，建议应用层使用；测试优先覆盖异常语义
- 备选：No-Exception Wrapper（TFsFileNoExcept）返回 TFsErrorCode 负码，适合热路径或旧代码迁移

示例：

异常语义：
```
var f: IFsFile;
f := NewFsFile;
f.Open('data.bin', fomReadWrite);
try
  // 读写...
finally
  f.Close;
end;
```

负码语义：
```
var fn: TFsFileNoExcept; code, n: Integer; pos, size: Int64;
fn := NewFsFileNoExcept;
code := fn.Open('data.bin', fomReadWrite);
if code < 0 then exit;
code := fn.Write(buf, len, n);
code := fn.Seek(0, SEEK_END, pos);
code := fn.Size(size);
code := fn.Close;
```


## 错误码与分类对照

- TFsErrorCode（负值为错误，0 为成功）：
  - 0 = FS_SUCCESS
  - -1 = FS_ERROR_INVALID_HANDLE
  - -2 = FS_ERROR_FILE_NOT_FOUND
  - -3 = FS_ERROR_ACCESS_DENIED
  - -4 = FS_ERROR_DISK_FULL
  - -5 = FS_ERROR_INVALID_PATH
  - -6 = FS_ERROR_FILE_EXISTS
  - -7 = FS_ERROR_DIRECTORY_NOT_EMPTY
  - -8 = FS_ERROR_INVALID_PARAMETER
  - -9 = FS_ERROR_IO_ERROR
  - -10 = FS_ERROR_PERMISSION_DENIED
  - 其他 = FS_ERROR_UNKNOWN（-999 作为兜底）

- FsErrorKind（分类）：
  - fekNone          → aErrorCode >= 0
  - fekNotFound      → FS_ERROR_FILE_NOT_FOUND
  - fekPermission    → FS_ERROR_ACCESS_DENIED / FS_ERROR_PERMISSION_DENIED
  - fekExists        → FS_ERROR_FILE_EXISTS
  - fekInvalid       → FS_ERROR_INVALID_PATH / FS_ERROR_INVALID_PARAMETER / FS_ERROR_INVALID_HANDLE
  - fekDiskFull      → FS_ERROR_DISK_FULL
  - fekIO            → FS_ERROR_IO_ERROR
  - fekUnknown       → 其余

- 仅提交文档与测试骨架；不更改 src 实现
- 确认接口字段与错误策略后，再实现 TFsFileAdapter 并添加到 src（小步 PR）

