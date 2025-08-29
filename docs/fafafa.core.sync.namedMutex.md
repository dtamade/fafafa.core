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
