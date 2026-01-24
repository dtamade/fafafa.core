# fafafa.core.sync.namedSemaphore

## 概述

`fafafa.core.sync.namedSemaphore` 模块提供了高性能、跨平台的命名信号量实现，支持进程间同步和资源计数管理。该模块采用现代化的 RAII 模式设计，完全遵循 `fafafa.core.sync.namedMutex` 的架构模式，符合 Rust、Java、Go 等主流开发语言的最佳实践。

## 核心特性

### ✨ 现代化设计
- **RAII 模式**：自动资源管理，无需手动释放信号量
- **类型安全**：强类型接口，编译时错误检查
- **零成本抽象**：高性能实现，无运行时开销

### 🚀 高性能实现
- **Windows**：原生 Win32 Semaphore API (`CreateSemaphore`/`ReleaseSemaphore`)
- **Unix/Linux**：POSIX named semaphore API (`sem_open`/`sem_post`/`sem_wait`)
- **优化的超时机制**：无轮询，真正的阻塞式超时

### 🌍 跨平台支持
- **完全隐藏平台差异**：统一的 API 接口
- **自动平台检测**：编译时选择最优实现
- **一致的行为**：跨平台相同的语义

### 📊 丰富的信号量类型
- **二进制信号量**：类似互斥锁，但支持多次释放
- **计数信号量**：经典的资源池管理
- **自定义配置**：灵活的初始计数和最大计数设置

## 架构设计

### 模块结构

```
fafafa.core.sync.namedSemaphore/
├── fafafa.core.sync.namedSemaphore.base.pas      # 基础接口定义
├── fafafa.core.sync.namedSemaphore.windows.pas   # Windows 平台实现
├── fafafa.core.sync.namedSemaphore.unix.pas      # Unix/Linux 平台实现
└── fafafa.core.sync.namedSemaphore.pas           # 工厂门面层
```

### 设计模式

本模块完全遵循 `fafafa.core.sync.namedMutex` 的设计模式：

1. **分层架构**：接口层 → 实现层 → 门面层
2. **RAII 守卫**：自动资源管理
3. **工厂模式**：隐藏实现细节
4. **配置驱动**：灵活的参数调整

## 快速开始

### 基本使用

```pascal
uses fafafa.core.sync.namedSemaphore;

var
  LSemaphore: INamedSemaphore;
  LGuard: INamedSemaphoreGuard;
begin
  // 创建命名信号量
  LSemaphore := CreateNamedSemaphore('MyAppSemaphore');

  // RAII 模式：自动管理信号量生命周期
  LGuard := LSemaphore.Wait;
  try
    // 临界区代码
    WriteLn('在信号量保护下执行');
  finally
    LGuard := nil; // 自动释放信号量
  end;
end;
```

### 计数信号量（资源池）

```pascal
var
  LSemaphore: INamedSemaphore;
  LGuards: array[1..3] of INamedSemaphoreGuard;
  I: Integer;
begin
  // 创建资源池：最多3个并发访问
  LSemaphore := CreateCountingSemaphore('ResourcePool', 3);

  // 获取多个资源
  for I := 1 to 3 do
  begin
    LGuards[I] := LSemaphore.TryWait;
    if Assigned(LGuards[I]) then
      WriteLn('获取资源 ', I);
  end;

  // 自动释放所有资源
  for I := 1 to 3 do
    LGuards[I] := nil;
end;
```

### 二进制信号量（事件通知）

```pascal
var
  LSemaphore: INamedSemaphore;
  LGuard: INamedSemaphoreGuard;
begin
  // 创建二进制信号量（初始无信号）
  LSemaphore := CreateBinarySemaphore('EventSignal', False);

  // 在另一个线程/进程中释放信号
  LSemaphore.Release;

  // 等待信号
  LGuard := LSemaphore.Wait;
  WriteLn('收到信号！');
  LGuard := nil;
end;
```

## API 参考

### 工厂函数

#### 主要工厂函数

```pascal
// 基础创建函数
function CreateNamedSemaphore(const AName: string): INamedSemaphore;
function CreateNamedSemaphore(const AName: string; AInitialCount, AMaxCount: Integer): INamedSemaphore;
function CreateNamedSemaphore(const AName: string; const AConfig: TNamedSemaphoreConfig): INamedSemaphore;

// 全局信号量
function CreateGlobalNamedSemaphore(const AName: string): INamedSemaphore;
function CreateGlobalNamedSemaphore(const AName: string; AInitialCount, AMaxCount: Integer): INamedSemaphore;
```

#### 便利函数

```pascal
// 二进制信号量
function CreateBinarySemaphore(const AName: string): INamedSemaphore;
function CreateBinarySemaphore(const AName: string; AInitiallySignaled: Boolean): INamedSemaphore;

// 计数信号量
function CreateCountingSemaphore(const AName: string; AMaxCount: Integer): INamedSemaphore;
function CreateCountingSemaphore(const AName: string; AInitialCount, AMaxCount: Integer): INamedSemaphore;
```

#### 兼容性函数

```pascal
// 向后兼容（推荐使用 CreateNamedSemaphore）
function MakeNamedSemaphore(const AName: string): INamedSemaphore;
function MakeNamedSemaphore(const AName: string; AInitialCount, AMaxCount: Integer): INamedSemaphore;
function TryOpenNamedSemaphore(const AName: string): INamedSemaphore;
```

### 接口定义

#### INamedSemaphore

```pascal
INamedSemaphore = interface
  // 核心信号量操作 - 返回 RAII 守卫
  function Wait: INamedSemaphoreGuard;                              // 阻塞等待
  function TryWait: INamedSemaphoreGuard;                          // 非阻塞尝试
  function TryWaitFor(ATimeoutMs: Cardinal): INamedSemaphoreGuard; // 带超时等待
  
  // 释放操作
  procedure Release; overload;                                      // 释放一个计数
  procedure Release(ACount: Integer); overload;                    // 释放多个计数

  // 查询操作
  function GetName: string;           // 获取信号量名称
  function GetCurrentCount: Integer;  // 获取当前可用计数（如果支持）
  function GetMaxCount: Integer;      // 获取最大计数值
end;
```

#### INamedSemaphoreGuard

```pascal
INamedSemaphoreGuard = interface
  function GetName: string;           // 获取信号量名称
  function GetCount: Integer;         // 获取当前计数值（如果支持）
  // 析构时自动释放信号量，无需手动调用 Release
end;
```

### 配置结构

```pascal
TNamedSemaphoreConfig = record
  TimeoutMs: Cardinal;           // 默认超时时间（毫秒）
  RetryIntervalMs: Cardinal;     // 重试间隔（毫秒）
  MaxRetries: Integer;           // 最大重试次数
  UseGlobalNamespace: Boolean;   // 是否使用全局命名空间
  InitialCount: Integer;         // 初始计数值
  MaxCount: Integer;             // 最大计数值
end;
```

## 使用场景

### 1. 资源池管理

```pascal
// 数据库连接池
var
  LConnectionPool: INamedSemaphore;
  LConnection: INamedSemaphoreGuard;
begin
  LConnectionPool := CreateCountingSemaphore('DBConnectionPool', 10);
  
  LConnection := LConnectionPool.Wait; // 获取连接
  try
    // 使用数据库连接
    ExecuteQuery('SELECT * FROM users');
  finally
    LConnection := nil; // 自动归还连接
  end;
end;
```

### 2. 并发控制

```pascal
// 限制同时下载的文件数
var
  LDownloadSemaphore: INamedSemaphore;
  LGuard: INamedSemaphoreGuard;
begin
  LDownloadSemaphore := CreateCountingSemaphore('DownloadLimit', 3);
  
  LGuard := LDownloadSemaphore.Wait;
  try
    DownloadFile('http://example.com/file.zip');
  finally
    LGuard := nil;
  end;
end;
```

### 3. 事件通知

```pascal
// 进程间事件通知
var
  LEventSemaphore: INamedSemaphore;
  LGuard: INamedSemaphoreGuard;
begin
  LEventSemaphore := CreateBinarySemaphore('ProcessEvent', False);
  
  // 等待事件
  LGuard := LEventSemaphore.Wait;
  WriteLn('事件已触发！');
  LGuard := nil;
end;

// 在另一个进程中触发事件
procedure TriggerEvent;
var
  LEventSemaphore: INamedSemaphore;
begin
  LEventSemaphore := CreateBinarySemaphore('ProcessEvent', False);
  LEventSemaphore.Release; // 触发事件
end;
```

### 4. 生产者-消费者模式

```pascal
// 生产者
procedure Producer;
var
  LBufferSemaphore: INamedSemaphore;
begin
  LBufferSemaphore := CreateCountingSemaphore('Buffer', 0, 100);
  
  // 生产数据
  ProduceData;
  LBufferSemaphore.Release; // 通知有新数据
end;

// 消费者
procedure Consumer;
var
  LBufferSemaphore: INamedSemaphore;
  LGuard: INamedSemaphoreGuard;
begin
  LBufferSemaphore := CreateCountingSemaphore('Buffer', 0, 100);
  
  LGuard := LBufferSemaphore.Wait; // 等待数据
  try
    ConsumeData;
  finally
    LGuard := nil;
  end;
end;
```

## 平台差异

### Windows 平台

- **API**：使用 `CreateSemaphore`/`ReleaseSemaphore`
- **命名规则**：支持 `Global\` 和 `Local\` 前缀
- **最大长度**：260 字符 (MAX_PATH)
- **计数查询**：不支持查询当前计数（返回 -1）
- **超时支持**：完整支持毫秒级超时

### Unix/Linux 平台

- **API**：使用 POSIX named semaphore (`sem_open`/`sem_post`/`sem_wait`)
- **命名规则**：自动添加 `/` 前缀，符合 POSIX 规范
- **最大长度**：255 字符 (NAME_MAX)
- **计数查询**：支持查询当前计数（`sem_getvalue`）
- **超时支持**：支持 `sem_timedwait`

## 命名规则

### Windows 平台

- 名称长度限制：260 字符 (MAX_PATH)
- 支持 `Global\` 前缀：跨会话共享
- 支持 `Local\` 前缀：当前会话内共享
- 不能包含反斜杠（除前缀外）

### Unix/Linux 平台

- 名称长度限制：255 字符 (NAME_MAX)
- 自动添加 `/` 前缀符合 POSIX 规范
- 不能包含额外的 `/` 字符
- 区分大小写

## Unix 平台详解

### 权限管理

#### 创建权限

命名信号量在 Unix 平台上使用 POSIX 命名信号量实现，创建时需要指定权限：

```pascal
// 默认权限：0644 (rw-r--r--)
LSem := MakeNamedSemaphore('MySemaphore', 5);

// 自定义权限
LConfig := DefaultNamedSemaphoreConfig;
LConfig.Permissions := &0666;  // rw-rw-rw-
LSem := MakeNamedSemaphoreWithConfig('MySemaphore', 5, LConfig);
```

**权限说明**：
- **0644** (默认)：所有者可读写，组和其他用户只读
- **0666**：所有用户可读写
- **0600**：仅所有者可读写
- **0660**：所有者和组可读写

**权限影响**：
- 创建者进程的 umask 会影响最终权限
- 其他进程访问时需要有相应的读写权限
- 权限不足会导致 `sem_open` 失败并返回 `EACCES` 错误

#### 所有权

- 命名信号量的所有者是创建它的进程的有效用户ID (euid)
- 所有者可以修改权限（通过 `chmod` 系统调用）
- 非所有者进程需要有相应权限才能访问

### 命名空间管理

#### 命名规则

Unix 平台的命名信号量遵循 POSIX 命名信号量规范：

```pascal
// 自动添加 / 前缀
LSem := MakeNamedSemaphore('MySemaphore', 5);
// 实际名称：/MySemaphore

// 不能包含额外的 / 字符
LSem := MakeNamedSemaphore('App/MySemaphore', 5);  // 错误！会抛出异常
```

**命名限制**：
- 名称长度：最多 255 字符 (NAME_MAX)
- 必须以字母或数字开头
- 只能包含字母、数字、下划线、点号
- 不能包含 `/` 字符（除了自动添加的前缀）
- 区分大小写：`MySemaphore` 和 `mysemaphore` 是不同的信号量

#### 命名空间隔离

Unix 平台的命名信号量是**全局的**，没有类似 Windows 的 `Global\` 和 `Local\` 命名空间：

```pascal
// Unix 平台：所有进程共享同一命名空间
// 进程 A
LSem := MakeNamedSemaphore('SharedSemaphore', 5);

// 进程 B（不同用户）
LSem := MakeNamedSemaphore('SharedSemaphore', 5);  // 访问同一个信号量（如果权限允许）
```

**命名空间特点**：
- 所有进程共享同一命名空间
- 不同用户的进程可以访问同一命名对象（如果权限允许）
- 建议使用应用程序特定的前缀避免冲突：
  ```pascal
  LSem := MakeNamedSemaphore('MyApp.Module.Semaphore', 5);
  ```

#### 命名冲突处理

```pascal
// 场景1：同名信号量已存在
LSem1 := MakeNamedSemaphore('SharedSemaphore', 5);  // 创建
LSem2 := MakeNamedSemaphore('SharedSemaphore', 5);  // 打开现有的

// 场景2：避免冲突的命名策略
LSem := MakeNamedSemaphore('com.mycompany.myapp.semaphore', 5);  // 使用反向域名
LSem := MakeNamedSemaphore(Format('MyApp.%d.Semaphore', [GetProcessID]), 5);  // 包含进程ID
```

### 清理语义

#### 自动清理

Unix 平台的命名信号量具有以下自动清理特性：

**进程退出时**：
- 进程持有的信号量资源会自动释放
- 信号量的引用计数减1
- 如果引用计数降为0，信号量对象会被标记为删除

**系统重启时**：
- 所有命名信号量会被清理
- 不会留下"僵尸"对象

#### 手动清理

```pascal
// 方式1：通过接口引用计数自动清理
var
  LSem: INamedSemaphore;
begin
  LSem := MakeNamedSemaphore('MySemaphore', 5);
  // 使用信号量...
  LSem := nil;  // 自动调用 sem_close
end;

// 方式2：显式删除（仅创建者）
LSem := MakeNamedSemaphore('MySemaphore', 5);
// 使用完毕后
sem_unlink('/MySemaphore');  // 从系统中删除（需要手动调用系统API）
```

**清理注意事项**：
- `sem_close` 只是关闭当前进程的引用，不会删除信号量对象
- `sem_unlink` 会从系统中删除信号量，但已打开的引用仍然有效
- 建议由创建者进程负责调用 `sem_unlink` 清理

#### 资源泄漏预防

```pascal
// 好的做法：使用 try-finally 确保清理
var
  LSem: INamedSemaphore;
begin
  LSem := MakeNamedSemaphore('MySemaphore', 5);
  try
    // 使用信号量...
  finally
    LSem := nil;  // 确保释放
  end;
end;
```

### 系统限制

#### 资源限制

Unix 系统对命名信号量有以下限制：

```bash
# 查看系统限制
cat /proc/sys/kernel/sem
# 输出：SEMMSL  SEMMNS  SEMOPM  SEMMNI
#       250     32000   32      128
```

**常见限制**：
- **SEMMNI**：系统范围内的信号量集数量（通常为 128）
- **SEMMNS**：系统范围内的信号量总数（通常为 32000）
- **SEMMSL**：每个信号量集的最大信号量数（通常为 250）

**超出限制时**：
- `sem_open` 会失败并返回 `ENOSPC` 错误
- 需要清理未使用的信号量或调整系统限制

#### 文件系统位置

命名信号量在文件系统中的位置：

```bash
# Linux
/dev/shm/sem.MySemaphore

# macOS
/var/tmp/sem.MySemaphore

# 查看所有命名信号量
ls -l /dev/shm/sem.* 2>/dev/null || ls -l /var/tmp/sem.* 2>/dev/null
```

### 信号量特性

#### 计数值管理

Unix 平台的 POSIX 信号量支持计数值：

```pascal
// 创建初始计数为 5 的信号量
LSem := MakeNamedSemaphore('MySemaphore', 5);

// 获取当前计数值
LCount := LSem.GetValue;
WriteLn('当前计数: ', LCount);

// Post 操作增加计数
LSem.Post;  // 计数 +1

// Wait 操作减少计数
LSem.Wait;  // 计数 -1，如果计数为 0 则阻塞
```

**计数值特点**：
- 初始计数值在创建时指定
- `Post` 操作原子地增加计数值
- `Wait` 操作原子地减少计数值（如果计数为 0 则阻塞）
- 计数值不能为负数

#### 超时控制

Unix 平台支持原生的超时控制：

```pascal
// 带超时的等待
if LSem.WaitTimeout(1000) then  // 1秒超时
  WriteLn('获取信号量成功')
else
  WriteLn('等待超时');
```

**超时实现**：
- 使用 `sem_timedwait` 实现
- 超时精度取决于系统调度器（通常为毫秒级）
- 超时时返回 `ETIMEDOUT` 错误

### 跨平台差异

#### Windows vs Unix

| 特性 | Windows | Unix/Linux |
|------|---------|------------|
| 实现机制 | 内核 Semaphore 对象 | POSIX 命名信号量 |
| 命名空间 | `Global\` / `Local\` | 全局（无隔离） |
| 权限模型 | ACL（访问控制列表） | Unix 权限（rwx） |
| 计数值查询 | 不支持 | 支持（sem_getvalue） |
| 超时控制 | 支持 | 支持（原生） |
| 自动清理 | 进程退出时自动 | 进程退出时自动 |
| 持久化 | 仅在进程存在时 | 仅在进程存在时 |
| 系统重启 | 自动清理 | 自动清理 |

#### 可移植性建议

```pascal
// 好的做法：使用统一的命名约定
{$IFDEF WINDOWS}
  LSem := MakeNamedSemaphore('Global\MyApp.Semaphore', 5);
{$ELSE}
  LSem := MakeNamedSemaphore('MyApp.Semaphore', 5);
{$ENDIF}

// 更好的做法：使用配置抽象平台差异
LConfig := DefaultNamedSemaphoreConfig;
{$IFDEF WINDOWS}
  LConfig.UseGlobalNamespace := True;
{$ELSE}
  LConfig.Permissions := &0666;
{$ENDIF}
LSem := MakeNamedSemaphoreWithConfig('MyApp.Semaphore', 5, LConfig);
```

### 调试与诊断

#### 查看命名信号量

```bash
# Linux：查看所有命名信号量
ls -lh /dev/shm/sem.*

# macOS：查看所有命名信号量
ls -lh /var/tmp/sem.*

# 查看特定信号量的详细信息
stat /dev/shm/sem.MySemaphore
```

#### 清理僵尸信号量

```bash
# 手动删除未使用的信号量
rm /dev/shm/sem.MySemaphore

# 清理所有信号量（谨慎使用！）
rm /dev/shm/sem.*
```

#### 常见问题诊断

**问题1：权限不足**
```
错误：sem_open failed with EACCES
原因：当前用户没有访问权限
解决：
1. 检查信号量文件权限：ls -l /dev/shm/sem.MySemaphore
2. 修改权限：chmod 666 /dev/shm/sem.MySemaphore
3. 或使用更宽松的创建权限：LConfig.Permissions := &0666
```

**问题2：资源耗尽**
```
错误：sem_open failed with ENOSPC
原因：系统信号量数量达到上限
解决：
1. 查看系统限制：cat /proc/sys/kernel/sem
2. 清理未使用的信号量：rm /dev/shm/sem.*
3. 调整系统限制（需要 root）：sysctl -w kernel.sem="250 32000 32 256"
```

**问题3：名称冲突**
```
错误：不同应用使用相同名称
原因：命名空间全局共享
解决：使用应用程序特定的前缀
LSem := MakeNamedSemaphore('com.mycompany.myapp.semaphore', 5);
```

**问题4：计数值异常**
```
错误：信号量计数值不符合预期
原因：多个进程同时操作或异常退出
解决：
1. 使用 GetValue 查看当前计数
2. 检查是否有进程异常退出未释放
3. 必要时重新创建信号量
```

## 错误处理

### 异常类型

- `EInvalidArgument`: 无效的信号量名称或计数参数
- `ELockError`: 信号量操作失败
- `ETimeoutError`: 获取超时

### 常见错误

```pascal
// 无效名称
try
  CreateNamedSemaphore('');
except
  on E: EInvalidArgument do
    WriteLn('错误：', E.Message);
end;

// 无效计数
try
  CreateNamedSemaphore('test', -1, 5);
except
  on E: EInvalidArgument do
    WriteLn('错误：', E.Message);
end;

// 超时处理
var
  LGuard: INamedSemaphoreGuard;
begin
  LGuard := LSemaphore.TryWaitFor(1000);
  if not Assigned(LGuard) then
    WriteLn('获取信号量超时');
end;
```

## 最佳实践

### 1. 使用 RAII 模式

```pascal
// ✅ 推荐：使用 RAII 守卫
var LGuard := LSemaphore.Wait;
try
  // 临界区代码
finally
  LGuard := nil; // 自动释放
end;

// ❌ 不推荐：手动管理（已弃用）
LSemaphore.Acquire;
try
  // 临界区代码
finally
  LSemaphore.Release;
end;
```

### 2. 合理设置计数

```pascal
// ✅ 根据实际资源数设置
var LConnectionPool := CreateCountingSemaphore('DBPool', 10, 10);

// ❌ 避免过大的计数值
var LBadPool := CreateCountingSemaphore('BadPool', 1000000, 1000000);
```

### 3. 处理超时

```pascal
// ✅ 合理的超时处理
var LGuard := LSemaphore.TryWaitFor(5000); // 5秒超时
if Assigned(LGuard) then
begin
  // 处理资源
  LGuard := nil;
end
else
  WriteLn('资源繁忙，请稍后重试');
```

### 4. 命名约定

```pascal
// ✅ 清晰的命名
var LDatabasePool := CreateCountingSemaphore('MyApp.Database.ConnectionPool', 10);
var LFileAccess := CreateBinarySemaphore('MyApp.FileAccess.ConfigFile');

// ❌ 模糊的命名
var LSem1 := CreateNamedSemaphore('sem1');
```

### 5. 错误处理

```pascal
// ✅ 完整的错误处理
try
  var LSemaphore := CreateNamedSemaphore('MyResource', 5, 10);
  var LGuard := LSemaphore.TryWaitFor(1000);
  if Assigned(LGuard) then
  begin
    // 使用资源
    LGuard := nil;
  end
  else
    WriteLn('获取资源超时');
except
  on E: EInvalidArgument do
    WriteLn('参数错误：', E.Message);
  on E: ELockError do
    WriteLn('信号量错误：', E.Message);
end;
```

## 性能考虑

### 1. 平台选择
- **Windows**：使用内核对象，性能优异
- **Unix/Linux**：使用 POSIX 信号量，跨平台兼容性好

### 2. 计数管理
- 避免频繁的大量释放操作
- 合理设置初始计数和最大计数

### 3. 超时设置
- 根据应用场景设置合理的超时值
- 避免无限等待（除非确实需要）

## 示例程序

模块提供了完整的示例程序：

- `example_namedSemaphore_basic.lpr` - 基础功能演示
- `example_namedSemaphore_crossprocess.lpr` - 跨进程演示

运行示例：
```bash
# 编译并运行基础示例
lazbuild examples/fafafa.core.sync.namedSemaphore/example_namedSemaphore_basic.lpr
./examples/fafafa.core.sync.namedSemaphore/bin/example_namedSemaphore_basic

# 跨进程演示
./examples/fafafa.core.sync.namedSemaphore/bin/example_namedSemaphore_crossprocess server
./examples/fafafa.core.sync.namedSemaphore/bin/example_namedSemaphore_crossprocess client 1
```

## 版本历史

- **v1.0.0** - 初始版本
  - 完整的跨平台信号量实现
  - RAII 模式支持
  - 丰富的工厂函数
  - 完整的测试套件和文档
