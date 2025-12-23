# fafafa.core.sync 现代同步原语

## 概述

本文档介绍 `fafafa.core.sync` 模块中的现代同步原语，这些原语参照 Rust/Go/Java 的设计，提供更高级别的同步抽象。

| 原语 | 灵感来源 | 用途 |
|------|----------|------|
| **LazyLock** | Rust `std::sync::LazyLock` | 线程安全懒加载 |
| **OnceLock** | Rust `std::sync::OnceLock` | 单次初始化容器 |
| **WaitGroup** | Go `sync.WaitGroup` | 等待一组任务完成 |
| **Latch** | Java `CountDownLatch` | 一次性倒计数同步 |
| **Parker** | Rust `std::thread::park` | 轻量级线程暂停/唤醒 |

---

## LazyLock - 线程安全懒加载

### 概述

`TLazyLock<T>` 是一个泛型容器，接受初始化器函数，在第一次访问时自动执行初始化。类似于 Rust 的 `std::sync::LazyLock`。

### 特性

- **延迟初始化**: 创建时不执行初始化器，第一次访问时才执行
- **线程安全**: 多线程环境下初始化器只执行一次
- **无锁快路径**: 初始化完成后访问无额外开销

### 状态

```
TLazyState
├── lsUninit       // 未初始化
├── lsInitializing // 正在初始化（某线程正在执行）
└── lsInitialized  // 已初始化
```

### API

```pascal
type
  generic TLazyLock<T> = class
    constructor Create(AInitializer: TInit);

    // 获取值（触发初始化）
    function GetValue: T;

    // 强制初始化
    procedure Force;
    function ForceInit: Boolean;  // 返回是否首次初始化

    // 不触发初始化的访问
    function TryGet: PT;                      // 返回指针或 nil
    function TryGetValue(out AValue: T): Boolean;
    function GetOrElse(const ADefault: T): T;

    // 状态查询
    function IsInitialized: Boolean;
  end;
```

### 使用示例

```pascal
uses fafafa.core.sync.lazylock;

type
  TMyLazyLock = specialize TLazyLock<Integer>;

function ExpensiveComputation: Integer;
begin
  Sleep(1000);  // 模拟耗时计算
  Result := 42;
end;

var
  Lazy: TMyLazyLock;
begin
  Lazy := TMyLazyLock.Create(@ExpensiveComputation);
  try
    // 第一次访问时执行 ExpensiveComputation
    WriteLn(Lazy.GetValue);  // 输出: 42

    // 后续访问直接返回缓存值
    WriteLn(Lazy.GetValue);  // 立即返回 42
  finally
    Lazy.Free;
  end;
end;
```

### 多线程示例

```pascal
var
  Lazy: TMyLazyLock;

// 多个线程同时访问
TThread.CreateAnonymousThread(procedure begin
  WriteLn('Thread 1: ', Lazy.GetValue);
end).Start;

TThread.CreateAnonymousThread(procedure begin
  WriteLn('Thread 2: ', Lazy.GetValue);
end).Start;

// 只有一个线程会执行初始化器
```

---

## OnceLock - 单次初始化容器

### 概述

`TOnceLock<T>` 是一个线程安全的容器，保证值只能被设置一次。类似于 Rust 的 `std::sync::OnceLock`。

### 与 LazyLock 的区别

| 特性 | LazyLock | OnceLock |
|------|----------|----------|
| 初始化时机 | 创建时绑定初始化器 | 运行时手动设置值 |
| 初始化方式 | 自动（首次访问） | 手动调用 SetValue/TrySet |
| 典型场景 | 全局单例、配置 | 一次性通知、Result 容器 |

### 状态

```
TOnceLockState
├── olsUnset    // 未设置
├── olsSetting  // 正在设置（某线程正在写入）
└── olsSet      // 已设置
```

### API

```pascal
type
  generic TOnceLock<T> = class
    constructor Create;

    // 设置值
    procedure SetValue(const AValue: T);      // 已设置则抛异常
    function TrySet(const AValue: T): Boolean; // 已设置返回 False

    // 获取值
    function GetValue: T;                     // 未设置则抛异常
    function TryGet: PT;                      // 未设置返回 nil

    // 获取或初始化
    function GetOrInit(AInitializer: TInitFunc): T;
    function GetOrTryInit(AInitializer: TInitFunc; out AError: Exception): T;

    // 取出值
    function Take: T;      // 取出并清空（转移所有权）
    function IntoInner: T; // 取出但不清空

    // 等待
    procedure Wait;
    function WaitTimeout(ATimeoutMs: Cardinal): Boolean;

    // 状态查询
    function IsSet: Boolean;
  end;
```

### 使用示例

```pascal
uses fafafa.core.sync.oncelock;

type
  TStringOnceLock = specialize TOnceLock<string>;

var
  Config: TStringOnceLock;
begin
  Config := TStringOnceLock.Create;
  try
    // 设置值（只能设置一次）
    Config.SetValue('Production');

    // 再次设置会抛出 EOnceLockAlreadySet
    // Config.SetValue('Development');  // 异常！

    // 使用 TrySet 安全设置
    if not Config.TrySet('Development') then
      WriteLn('Already configured');

    WriteLn(Config.GetValue);  // 输出: Production
  finally
    Config.Free;
  end;
end;
```

### GetOrInit 模式

```pascal
function LoadConfig: string;
begin
  Result := ReadConfigFromFile;
end;

var
  Config: TStringOnceLock;
  Value: string;
begin
  Config := TStringOnceLock.Create;
  try
    // 多线程安全：只有一个线程执行 LoadConfig
    Value := Config.GetOrInit(@LoadConfig);
  finally
    Config.Free;
  end;
end;
```

---

## WaitGroup - Go 风格等待组

### 概述

`IWaitGroup` 用于等待一组并发操作完成。主线程调用 `Add` 设置任务数量，工作线程完成后调用 `Done`，主线程调用 `Wait` 阻塞直到所有任务完成。

### 工厂函数

```pascal
function MakeWaitGroup: IWaitGroup;
```

### API

```pascal
type
  IWaitGroup = interface(ISynchronizable)
    // 增加/减少计数器
    procedure Add(ADelta: Integer);
    procedure Done;  // 等同于 Add(-1)

    // 等待
    procedure Wait;
    function WaitTimeout(ATimeoutMs: Cardinal): Boolean;
    function WaitDuration(const ADuration: TDuration): TWaitResult;

    // 状态查询
    function GetCount: Integer;
  end;
```

### 使用示例

```pascal
uses fafafa.core.sync.waitgroup;

var
  WG: IWaitGroup;
  I: Integer;
begin
  WG := MakeWaitGroup;
  WG.Add(3);  // 3 个工作任务

  for I := 1 to 3 do
    TThread.CreateAnonymousThread(procedure begin
      try
        // 模拟工作
        Sleep(Random(1000));
        WriteLn('Worker done');
      finally
        WG.Done;  // 必须调用！
      end;
    end).Start;

  WG.Wait;  // 等待所有工作完成
  WriteLn('All done!');
end;
```

### 带超时等待

```pascal
if WG.WaitTimeout(5000) then
  WriteLn('All tasks completed')
else
  WriteLn('Timeout: some tasks still running');
```

### 注意事项

1. **计数器不能为负**: `Done` 调用次数不能超过 `Add` 的总量
2. **先 Add 后启动**: 应在启动工作线程前调用 `Add`
3. **异常安全**: 工作线程应在 `finally` 块中调用 `Done`

```pascal
// ✅ 正确
WG.Add(N);
for I := 1 to N do
  StartWorker;

// ❌ 错误：可能在 Wait 开始后才 Add
for I := 1 to N do
begin
  WG.Add(1);  // 竞态！
  StartWorker;
end;
```

---

## Latch - 一次性倒计数同步

### 概述

`ILatch` 是一次性的同步原语，计数只能减少不能增加。适合"门控启动"或"完成等待"场景。

### 与 WaitGroup 的区别

| 特性 | WaitGroup | Latch |
|------|-----------|-------|
| 计数方向 | 可增可减 | 只减 |
| 重用性 | 可重用 | 一次性 |
| 典型场景 | 动态任务数 | 固定任务数 |

### 工厂函数

```pascal
function MakeLatch(ACount: Integer): ILatch;
```

### API

```pascal
type
  ILatch = interface(ISynchronizable)
    // 减少计数
    procedure CountDown;

    // 等待
    procedure Await;
    function AwaitTimeout(ATimeoutMs: Cardinal): Boolean;
    function AwaitDuration(const ADuration: TDuration): TWaitResult;

    // 状态查询
    function GetCount: Integer;
  end;
```

### 使用模式 1：门控启动

```pascal
uses fafafa.core.sync.latch;

var
  StartGate: ILatch;
  I: Integer;
begin
  StartGate := MakeLatch(1);  // 计数 = 1

  // 创建等待启动的工作线程
  for I := 1 to 10 do
    TThread.CreateAnonymousThread(procedure begin
      StartGate.Await;  // 等待启动信号
      WriteLn('Worker started');
      // 开始工作...
    end).Start;

  // 准备工作（初始化等）
  Sleep(100);

  // 打开门，所有工作线程同时开始
  StartGate.CountDown;
end;
```

### 使用模式 2：完成等待

```pascal
const N = 5;
var
  DoneLatch: ILatch;
  I: Integer;
begin
  DoneLatch := MakeLatch(N);  // 等待 5 个任务

  for I := 1 to N do
    TThread.CreateAnonymousThread(procedure begin
      // 工作...
      Sleep(Random(1000));
      DoneLatch.CountDown;  // 完成
    end).Start;

  DoneLatch.Await;  // 等待所有任务完成
  WriteLn('All tasks done!');
end;
```

### 两阶段同步

```pascal
var
  StartGate, DoneGate: ILatch;
begin
  StartGate := MakeLatch(1);
  DoneGate := MakeLatch(N);

  for I := 1 to N do
    TThread.CreateAnonymousThread(procedure begin
      StartGate.Await;  // 等待启动
      try
        // 工作...
      finally
        DoneGate.CountDown;  // 报告完成
      end;
    end).Start;

  // 准备就绪，启动所有线程
  StartGate.CountDown;

  // 等待所有线程完成
  DoneGate.Await;
end;
```

---

## Parker - 轻量级线程暂停/唤醒

### 概述

`IParker` 提供比条件变量更轻量的线程暂停/唤醒机制。类似于 Rust 的 `std::thread::park`/`unpark`。

### Permit 机制

Parker 使用二进制许可（permit）：
- `Unpark` 设置许可为 available
- `Park` 消费许可，如果没有许可则阻塞
- 多次 `Unpark` 只存储一个许可（不累积）

```
Unpark → Unpark → Park → 立即返回（消费一个许可）
Park → （阻塞）→ Unpark → 唤醒
```

### 工厂函数

```pascal
function MakeParker: IParker;
```

### API

```pascal
type
  IParker = interface(ISynchronizable)
    // 暂停
    procedure Park;
    function ParkTimeout(ATimeoutMs: Cardinal): Boolean;
    function ParkDuration(const ADuration: TDuration): TWaitResult;

    // 唤醒/发放许可
    procedure Unpark;
  end;
```

### 使用示例

```pascal
uses fafafa.core.sync.parker;

var
  P: IParker;
begin
  P := MakeParker;

  // 线程 A（等待者）
  TThread.CreateAnonymousThread(procedure begin
    WriteLn('Thread A: parking...');
    P.Park;  // 等待唤醒
    WriteLn('Thread A: unparked!');
  end).Start;

  // 线程 B（唤醒者）
  Sleep(100);  // 等待 A 进入 Park
  P.Unpark;    // 唤醒 A
end;
```

### Permit 预发放

```pascal
var
  P: IParker;
begin
  P := MakeParker;

  // 先发放许可
  P.Unpark;

  // Park 立即返回（消费预发放的许可）
  P.Park;  // 不阻塞！

  // 再次 Park 会阻塞（许可已消费）
  // P.Park;  // 阻塞！
end;
```

### 带超时的 Park

```pascal
if P.ParkTimeout(1000) then
  WriteLn('Unparked by another thread')
else
  WriteLn('Timeout');
```

### 典型应用场景

1. **简单的线程通知**: 比条件变量更轻量
2. **自定义同步原语**: 作为底层构建块
3. **任务队列**: 通知工作线程有新任务

---

## 最佳实践

### 1. 选择正确的原语

| 场景 | 推荐原语 |
|------|----------|
| 全局单例/配置 | LazyLock |
| 一次性结果容器 | OnceLock |
| 等待动态任务 | WaitGroup |
| 固定任务门控 | Latch |
| 简单线程通知 | Parker |

### 2. 异常安全

```pascal
// ✅ 使用 try-finally 确保 Done/CountDown 被调用
TThread.CreateAnonymousThread(procedure begin
  try
    // 工作...
  finally
    WG.Done;
  end;
end).Start;
```

### 3. 避免死锁

```pascal
// ❌ 危险：可能在 Wait 之前没有 Add
TThread.CreateAnonymousThread(procedure begin
  WG.Add(1);  // 竞态！
  // ...
end).Start;
WG.Wait;

// ✅ 安全：先 Add
WG.Add(1);
TThread.CreateAnonymousThread(procedure begin
  // ...
end).Start;
WG.Wait;
```

### 4. 超时处理

```pascal
// 避免无限等待
if not WG.WaitTimeout(30000) then
begin
  WriteLn('Warning: some tasks still running after 30s');
  // 处理超时情况
end;
```

---

## 异常类型

| 异常 | 模块 | 触发条件 |
|------|------|----------|
| `EWaitGroupError` | WaitGroup | 计数器变为负数 |
| `EOnceLockEmpty` | OnceLock | 获取未设置的值 |
| `EOnceLockAlreadySet` | OnceLock | 重复设置值 |

---

## 相关文档

- [fafafa.core.sync](fafafa.core.sync.md) - 主同步模块
- [fafafa.core.sync.mutex](fafafa.core.sync.mutex.md) - 互斥锁
- [fafafa.core.sync.condvar](fafafa.core.sync.condvar.md) - 条件变量
- [fafafa.core.sync.rwlock](fafafa.core.sync.rwlock.md) - 读写锁
- [fafafa.core.sync.benchmark](fafafa.core.sync.benchmark.md) - 性能基准

---

## 版本历史

### v1.0.0 (2025-12)
- LazyLock/OnceLock: Rust 风格懒加载
- WaitGroup: Go 风格等待组
- Latch: Java 风格倒计数锁存器
- Parker: Rust 风格线程暂停/唤醒
