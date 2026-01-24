# fafafa.core.sync.namedMutex

## 概述

`fafafa.core.sync.namedMutex` 模块提供了高性能、跨平台的命名互斥锁实现，支持进程间同步。该模块采用现代化的 RAII 模式设计，符合 Rust、Java、Go 等主流开发语言的最佳实践。

## 核心特性

### ✨ 现代化设计
- **RAII 模式**：自动资源管理，无需手动释放锁
- **类型安全**：强类型接口，编译时错误检查
- **零成本抽象**：高性能实现，无运行时开销

### 🚀 高性能实现
- **Windows**：原生 Win32 Mutex API
- **Unix/Linux**：pthread_mutex + 共享内存，支持 `pthread_mutex_timedlock`
- **优化的超时机制**：无轮询，真正的阻塞式超时

### 🌍 跨平台支持
- **完全隐藏平台差异**：统一的 API 接口
- **自动平台检测**：编译时选择最优实现
- **一致的行为**：跨平台相同的语义

## 架构设计

### 模块结构

```
fafafa.core.sync.namedMutex/
├── fafafa.core.sync.namedMutex.base.pas      # 基础接口定义
├── fafafa.core.sync.namedMutex.windows.pas   # Windows 平台实现
├── fafafa.core.sync.namedMutex.unix.pas      # Unix/Linux 平台实现
└── fafafa.core.sync.namedMutex.pas           # 工厂门面层
```

## 快速开始

### 基本使用

```pascal
uses fafafa.core.sync.namedMutex;

var
  LMutex: INamedMutex;
  LGuard: INamedMutexGuard;
begin
  // 创建命名互斥锁
  LMutex := CreateNamedMutex('MyAppMutex');

  // RAII 模式：自动管理锁生命周期
  LGuard := LMutex.Lock;
  try
    // 临界区代码
    WriteLn('在互斥锁保护下执行');
  finally
    LGuard := nil; // 自动释放锁
  end;
end;
```

### 非阻塞尝试

```pascal
var
  LMutex: INamedMutex;
  LGuard: INamedMutexGuard;
begin
  LMutex := CreateNamedMutex('MyAppMutex');

  // 非阻塞尝试获取锁
  LGuard := LMutex.TryLock;
  if Assigned(LGuard) then
  begin
    // 成功获取锁
    WriteLn('获取到锁，执行临界区代码');
    LGuard := nil; // 释放锁
  end
  else
    WriteLn('锁被其他进程占用');
end;
```

### 带超时的获取

```pascal
var
  LMutex: INamedMutex;
  LGuard: INamedMutexGuard;
begin
  LMutex := CreateNamedMutex('MyAppMutex');

  // 等待最多 5 秒
  LGuard := LMutex.TryLockFor(5000);
  if Assigned(LGuard) then
  begin
    WriteLn('在超时内获取到锁');
    LGuard := nil;
  end
  else
    WriteLn('超时，未能获取锁');
end;
```

## API 参考

### 核心接口

#### INamedMutex

主要的命名互斥锁接口。

```pascal
INamedMutex = interface
  // 现代化锁操作（推荐使用）
  function Lock: INamedMutexGuard;                              // 阻塞获取
  function TryLock: INamedMutexGuard;                          // 非阻塞尝试
  function TryLockFor(ATimeoutMs: Cardinal): INamedMutexGuard; // 带超时获取

  // 查询操作
  function GetName: string;           // 获取互斥锁名称
end;
```

#### INamedMutexGuard

RAII 模式的锁守卫，析构时自动释放锁。

```pascal
INamedMutexGuard = interface
  function GetName: string;           // 获取互斥锁名称
  // 析构时自动释放锁，无需手动调用 Release
end;
```

### 配置结构

#### TNamedMutexConfig

```pascal
TNamedMutexConfig = record
  TimeoutMs: Cardinal;           // 默认超时时间（毫秒）
  RetryIntervalMs: Cardinal;     // 重试间隔（毫秒）
  MaxRetries: Integer;           // 最大重试次数
  UseGlobalNamespace: Boolean;   // 是否使用全局命名空间
  InitialOwner: Boolean;         // 是否初始拥有
end;
```

### 工厂函数

#### 现代化工厂函数（推荐）

```pascal
// 主要工厂函数
function CreateNamedMutex(const AName: string; const AConfig: TNamedMutexConfig): INamedMutex;

// 便利工厂函数
function CreateNamedMutex(const AName: string): INamedMutex;
function CreateNamedMutex(const AName: string; ATimeoutMs: Cardinal): INamedMutex;
function CreateGlobalNamedMutex(const AName: string): INamedMutex;
```

#### 配置辅助函数

```pascal
function DefaultNamedMutexConfig: TNamedMutexConfig;
function NamedMutexConfigWithTimeout(ATimeoutMs: Cardinal): TNamedMutexConfig;
function GlobalNamedMutexConfig: TNamedMutexConfig;
```

## 平台实现

### Windows 平台

- 使用 `CreateMutex`/`OpenMutex` API
- 支持 `Global\` 和 `Local\` 命名空间
- 支持遗弃状态检测 (`WAIT_ABANDONED`)
- 支持跨会话的全局互斥锁

### Unix/Linux 平台

- 使用 POSIX named semaphore (`sem_open`/`sem_close`)
- 名称自动添加 `/` 前缀符合 POSIX 规范
- 通过信号量值 0/1 实现互斥语义
- 支持超时操作 (`sem_timedwait`)

## Unix 平台详解

### 权限管理

#### 创建权限

命名互斥锁在 Unix 平台上使用 POSIX 命名信号量实现，创建时需要指定权限：

```pascal
// 默认权限：0644 (rw-r--r--)
LMutex := MakeNamedMutex('MyMutex');

// 自定义权限
LConfig := DefaultNamedMutexConfig;
LConfig.Permissions := &0666;  // rw-rw-rw-
LMutex := MakeNamedMutexWithConfig('MyMutex', LConfig);
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

Unix 平台的命名互斥锁遵循 POSIX 命名信号量规范：

```pascal
// 自动添加 / 前缀
LMutex := MakeNamedMutex('MyMutex');
// 实际名称：/MyMutex

// 不能包含额外的 / 字符
LMutex := MakeNamedMutex('App/MyMutex');  // 错误！会抛出异常
```

**命名限制**：
- 名称长度：最多 255 字符 (NAME_MAX)
- 必须以字母或数字开头
- 只能包含字母、数字、下划线、点号
- 不能包含 `/` 字符（除了自动添加的前缀）
- 区分大小写：`MyMutex` 和 `mymutex` 是不同的互斥锁

#### 命名空间隔离

Unix 平台的命名信号量是**全局的**，没有类似 Windows 的 `Global\` 和 `Local\` 命名空间：

```pascal
// Unix 平台：所有进程共享同一命名空间
// 进程 A
LMutex := MakeNamedMutex('SharedMutex');

// 进程 B（不同用户）
LMutex := MakeNamedMutex('SharedMutex');  // 访问同一个互斥锁（如果权限允许）
```

**命名空间特点**：
- 所有进程共享同一命名空间
- 不同用户的进程可以访问同一命名对象（如果权限允许）
- 建议使用应用程序特定的前缀避免冲突：
  ```pascal
  LMutex := MakeNamedMutex('MyApp.Module.Mutex');
  ```

#### 命名冲突处理

```pascal
// 场景1：同名互斥锁已存在
LMutex1 := MakeNamedMutex('SharedMutex');  // 创建
LMutex2 := MakeNamedMutex('SharedMutex');  // 打开现有的

// 场景2：避免冲突的命名策略
LMutex := MakeNamedMutex('com.mycompany.myapp.mutex');  // 使用反向域名
LMutex := MakeNamedMutex(Format('MyApp.%d.Mutex', [GetProcessID]));  // 包含进程ID
```

### 清理语义

#### 自动清理

Unix 平台的命名信号量具有以下自动清理特性：

**进程退出时**：
- 进程持有的互斥锁会自动释放
- 信号量的引用计数减1
- 如果引用计数降为0，信号量对象会被标记为删除

**系统重启时**：
- 所有命名信号量会被清理
- 不会留下"僵尸"对象

#### 手动清理

```pascal
// 方式1：通过接口引用计数自动清理
var
  LMutex: INamedMutex;
begin
  LMutex := MakeNamedMutex('MyMutex');
  // 使用互斥锁...
  LMutex := nil;  // 自动调用 sem_close
end;

// 方式2：显式删除（仅创建者）
LMutex := MakeNamedMutex('MyMutex');
// 使用完毕后
sem_unlink('/MyMutex');  // 从系统中删除（需要手动调用系统API）
```

**清理注意事项**：
- `sem_close` 只是关闭当前进程的引用，不会删除信号量对象
- `sem_unlink` 会从系统中删除信号量，但已打开的引用仍然有效
- 建议由创建者进程负责调用 `sem_unlink` 清理

#### 资源泄漏预防

```pascal
// 好的做法：使用 try-finally 确保清理
var
  LMutex: INamedMutex;
begin
  LMutex := MakeNamedMutex('MyMutex');
  try
    // 使用互斥锁...
  finally
    LMutex := nil;  // 确保释放
  end;
end;

// 避免：忘记释放引用
var
  LMutex: INamedMutex;
begin
  LMutex := MakeNamedMutex('MyMutex');
  // 使用互斥锁...
  // 忘记设置 LMutex := nil
end;  // 引用计数在作用域结束时自动减少，但最好显式清理
```

### 系统限制

#### 资源限制

Unix 系统对命名信号量有以下限制：

```bash
# 查看系统限制
cat /proc/sys/kernel/sem
# 输出：SEMMSL  SEMMNS  SEMOPM  SEMMNI
#       250     32000   32      128

# 查看当前使用情况
ls -l /dev/shm/sem.*
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
/dev/shm/sem.MyMutex

# macOS
/var/tmp/sem.MyMutex

# 查看所有命名信号量
ls -l /dev/shm/sem.* 2>/dev/null || ls -l /var/tmp/sem.* 2>/dev/null
```

### 跨平台差异

#### Windows vs Unix

| 特性 | Windows | Unix/Linux |
|------|---------|------------|
| 实现机制 | 内核 Mutex 对象 | POSIX 命名信号量 |
| 命名空间 | `Global\` / `Local\` | 全局（无隔离） |
| 权限模型 | ACL（访问控制列表） | Unix 权限（rwx） |
| 遗弃检测 | 支持 (`WAIT_ABANDONED`) | 不支持 |
| 自动清理 | 进程退出时自动 | 进程退出时自动 |
| 持久化 | 仅在进程存在时 | 仅在进程存在时 |
| 系统重启 | 自动清理 | 自动清理 |

#### 可移植性建议

```pascal
// 好的做法：使用统一的命名约定
{$IFDEF WINDOWS}
  LMutex := MakeNamedMutex('Global\MyApp.Mutex');
{$ELSE}
  LMutex := MakeNamedMutex('MyApp.Mutex');
{$ENDIF}

// 更好的做法：使用配置抽象平台差异
LConfig := DefaultNamedMutexConfig;
{$IFDEF WINDOWS}
  LConfig.UseGlobalNamespace := True;
{$ELSE}
  LConfig.Permissions := &0666;
{$ENDIF}
LMutex := MakeNamedMutexWithConfig('MyApp.Mutex', LConfig);
```

### 调试与诊断

#### 查看命名信号量

```bash
# Linux：查看所有命名信号量
ls -lh /dev/shm/sem.*

# macOS：查看所有命名信号量
ls -lh /var/tmp/sem.*

# 查看特定信号量的详细信息
stat /dev/shm/sem.MyMutex
```

#### 清理僵尸信号量

```bash
# 手动删除未使用的信号量
rm /dev/shm/sem.MyMutex

# 清理所有信号量（谨慎使用！）
rm /dev/shm/sem.*
```

#### 常见问题诊断

**问题1：权限不足**
```
错误：sem_open failed with EACCES
原因：当前用户没有访问权限
解决：
1. 检查信号量文件权限：ls -l /dev/shm/sem.MyMutex
2. 修改权限：chmod 666 /dev/shm/sem.MyMutex
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
LMutex := MakeNamedMutex('com.mycompany.myapp.mutex');
```

## 使用示例

### 基本使用

```pascal
uses fafafa.core.sync.namedMutex;

var
  LMutex: INamedMutex;
begin
  // 创建命名互斥锁
  LMutex := MakeNamedMutex('MyAppMutex');
  
  // 获取互斥锁
  LMutex.Acquire;
  try
    // 临界区代码
    WriteLn('执行受保护的操作');
  finally
    LMutex.Release;
  end;
end;
```

### 非阻塞获取

```pascal
var
  LMutex: INamedMutex;
begin
  LMutex := MakeNamedMutex('MyAppMutex');
  
  // 立即尝试获取
  if LMutex.TryAcquire then
  begin
    try
      WriteLn('获取成功');
    finally
      LMutex.Release;
    end;
  end
  else
    WriteLn('无法立即获取');
    
  // 带超时尝试获取
  if LMutex.TryAcquire(5000) then
  begin
    try
      WriteLn('在超时内获取成功');
    finally
      LMutex.Release;
    end;
  end
  else
    WriteLn('超时未能获取');
end;
```

### 跨进程同步

```pascal
// 进程 A
var
  LMutex: INamedMutex;
begin
  LMutex := MakeNamedMutex('SharedResource');
  LMutex.Acquire;
  try
    // 访问共享资源
    ProcessSharedResource;
  finally
    LMutex.Release;
  end;
end;

// 进程 B (使用相同名称)
var
  LMutex: INamedMutex;
begin
  LMutex := MakeNamedMutex('SharedResource'); // 同名
  LMutex.Acquire; // 等待进程 A 释放
  try
    // 访问共享资源
    ProcessSharedResource;
  finally
    LMutex.Release;
  end;
end;
```

### 全局互斥锁

```pascal
var
  LMutex: INamedMutex;
begin
  // 创建跨会话的全局互斥锁
  LMutex := MakeGlobalNamedMutex('GlobalAppMutex');
  
  LMutex.Acquire;
  try
    WriteLn('全局互斥锁获取成功');
  finally
    LMutex.Release;
  end;
end;
```

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

## 错误处理

### 异常类型

- `EInvalidArgument`: 无效的互斥锁名称
- `ELockError`: 互斥锁操作失败
- `ETimeoutError`: 获取超时（Windows 平台）

### 常见错误

1. **空名称**: 互斥锁名称不能为空
2. **名称过长**: 超过平台限制的名称长度
3. **无效字符**: 包含平台不支持的字符
4. **权限不足**: 无法创建或访问命名对象
5. **双重释放**: 尝试释放未拥有的互斥锁

## 性能考虑

### 最佳实践

1. **尽量减少锁持有时间**: 只在必要时持有互斥锁
2. **避免嵌套锁**: 防止死锁情况
3. **使用 try-finally**: 确保互斥锁总是被释放
4. **合理设置超时**: 避免无限等待
5. **复用互斥锁实例**: 避免频繁创建销毁

### 平台差异

- **Windows**: 内核对象，性能较好，支持遗弃检测
- **Unix/Linux**: 用户空间信号量，轻量级，但无遗弃检测

## 注意事项

1. **进程退出清理**: 进程异常退出时，系统会自动释放互斥锁
2. **名称唯一性**: 相同名称的互斥锁引用同一个系统对象
3. **权限问题**: 某些系统可能需要特殊权限创建全局对象
4. **资源清理**: 互斥锁对象会在析构时自动清理系统资源
5. **线程安全**: 同一进程内多线程访问同一命名互斥锁是安全的

## 测试

模块包含完整的单元测试，覆盖：

- 基本创建和操作
- 多实例同步
- 超时功能
- 错误处理
- 跨进程基础验证

运行测试：
```bash
cd tests/fafafa.core.sync.namedMutex
./buildOrTest.bat  # Windows
```

## 相关模块

- `fafafa.core.sync.mutex`: 线程间互斥锁
- `fafafa.core.sync.semaphore`: 信号量
- `fafafa.core.sync.event`: 事件对象
- `fafafa.core.sync.rwlock`: 读写锁
