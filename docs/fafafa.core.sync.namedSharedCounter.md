# fafafa.core.sync.namedSharedCounter

跨进程命名共享计数器。

## 概述

`fafafa.core.sync.namedSharedCounter` 模块提供了一个跨进程的命名共享计数器，使用共享内存和原子操作实现高性能的计数器同步。适用于需要在多个进程间共享状态的场景。

## 特性

- **跨进程共享**: 不同进程可以通过相同的名称访问同一个计数器
- **原子操作**: 所有操作都是原子的，线程安全
- **高性能**: 使用共享内存，无需 IPC 通信开销
- **平台原生**: Windows 使用命名文件映射，Unix 使用 POSIX 共享内存

## 安装

```pascal
uses
  fafafa.core.sync.namedSharedCounter;
```

## API 参考

### INamedSharedCounter 接口

```pascal
type
  INamedSharedCounter = interface
    // 获取当前值
    function GetValue: Int64;

    // 设置值
    procedure SetValue(AValue: Int64);

    // 原子增加
    function Add(ADelta: Int64): Int64;

    // 原子减少
    function Sub(ADelta: Int64): Int64;

    // 原子递增
    function Inc: Int64;

    // 原子递减
    function Dec: Int64;

    // 原子比较并交换
    function CompareExchange(AOld, ANew: Int64): Int64;

    // 原子交换
    function Exchange(ANew: Int64): Int64;

    // 获取计数器名称
    function GetName: string;

    property Value: Int64 read GetValue write SetValue;
    property Name: string read GetName;
  end;
```

### 工厂函数

```pascal
// 创建或打开命名共享计数器
function CreateNamedSharedCounter(const AName: string;
                                   AInitialValue: Int64 = 0): INamedSharedCounter;

// 尝试打开已存在的命名共享计数器
function OpenNamedSharedCounter(const AName: string): INamedSharedCounter;
```

## 使用示例

### 基本用法

```pascal
var
  Counter: INamedSharedCounter;
begin
  Counter := CreateNamedSharedCounter('MyAppCounter', 0);

  Counter.Inc;
  WriteLn('当前值: ', Counter.Value);

  Counter.Add(10);
  WriteLn('加 10 后: ', Counter.Value);
end;
```

### 跨进程共享

**进程 A (生产者)**:
```pascal
var
  Counter: INamedSharedCounter;
begin
  Counter := CreateNamedSharedCounter('ItemCounter', 0);

  while True do
  begin
    ProduceItem();
    Counter.Inc;
    WriteLn('已生产: ', Counter.Value);
  end;
end;
```

**进程 B (消费者)**:
```pascal
var
  Counter: INamedSharedCounter;
  LastSeen: Int64;
begin
  Counter := OpenNamedSharedCounter('ItemCounter');
  LastSeen := 0;

  while True do
  begin
    if Counter.Value > LastSeen then
    begin
      ConsumeItems(Counter.Value - LastSeen);
      LastSeen := Counter.Value;
    end;
    Sleep(10);
  end;
end;
```

### 原子操作示例

```pascal
var
  Counter: INamedSharedCounter;
  OldValue: Int64;
begin
  Counter := CreateNamedSharedCounter('AtomicDemo', 100);

  // 原子比较并交换
  OldValue := Counter.CompareExchange(100, 200);
  if OldValue = 100 then
    WriteLn('CAS 成功: 100 -> 200')
  else
    WriteLn('CAS 失败: 当前值 = ', OldValue);

  // 原子交换
  OldValue := Counter.Exchange(500);
  WriteLn('Exchange: ', OldValue, ' -> 500');
end;
```

### 统计计数器

```pascal
type
  TStatsCounter = class
  private
    FRequests: INamedSharedCounter;
    FErrors: INamedSharedCounter;
    FBytes: INamedSharedCounter;
  public
    constructor Create(const APrefix: string);
    procedure RecordRequest(ABytes: Int64; AHasError: Boolean);
    procedure PrintStats;
  end;

constructor TStatsCounter.Create(const APrefix: string);
begin
  FRequests := CreateNamedSharedCounter(APrefix + '_requests', 0);
  FErrors := CreateNamedSharedCounter(APrefix + '_errors', 0);
  FBytes := CreateNamedSharedCounter(APrefix + '_bytes', 0);
end;

procedure TStatsCounter.RecordRequest(ABytes: Int64; AHasError: Boolean);
begin
  FRequests.Inc;
  FBytes.Add(ABytes);
  if AHasError then
    FErrors.Inc;
end;

procedure TStatsCounter.PrintStats;
begin
  WriteLn('请求数: ', FRequests.Value);
  WriteLn('错误数: ', FErrors.Value);
  WriteLn('字节数: ', FBytes.Value);
end;
```

### 分布式限流器

```pascal
function TryAcquireSlot(Counter: INamedSharedCounter; MaxSlots: Int64): Boolean;
var
  Current: Int64;
begin
  repeat
    Current := Counter.Value;
    if Current >= MaxSlots then
      Exit(False);
  until Counter.CompareExchange(Current, Current + 1) = Current;
  Result := True;
end;

procedure ReleaseSlot(Counter: INamedSharedCounter);
begin
  Counter.Dec;
end;
```

## 平台实现细节

### Windows

- 使用 `CreateFileMapping` / `OpenFileMapping`
- 共享内存命名格式: `Local\<name>`
- 原子操作使用 `InterlockedXxx` 函数

### Unix/Linux

- 使用 POSIX 共享内存 (`shm_open` / `mmap`)
- 共享内存命名格式: `/<name>`
- 原子操作使用编译器内置原子操作

## 内存布局

```
+----------------+
|    Int64 值    |  8 字节原子计数器
+----------------+
```

## 性能特点

| 操作 | 延迟 | 说明 |
|------|------|------|
| Inc/Dec | ~10ns | 原子操作，无系统调用 |
| CompareExchange | ~15ns | 可能需要重试 |
| GetValue | ~5ns | 简单内存读取 |
| SetValue | ~10ns | 原子写入 |

## 注意事项

1. **命名冲突**: 确保不同用途的计数器使用不同的名称
2. **权限**: 在某些系统上可能需要适当的权限创建共享内存
3. **清理**: 在 Unix 系统上，共享内存需要显式清理（使用 `shm_unlink`）
4. **溢出**: Int64 范围为 -2^63 到 2^63-1，注意溢出

## 与其他同步原语对比

| 特性 | NamedSharedCounter | NamedSemaphore | NamedMutex |
|------|-------------------|----------------|------------|
| 跨进程 | ✅ | ✅ | ✅ |
| 原子计数 | ✅ | 受限 | ❌ |
| 阻塞等待 | ❌ | ✅ | ✅ |
| 性能 | ★★★★★ | ★★★☆☆ | ★★★☆☆ |

## 相关模块

- `fafafa.core.sync.namedSemaphore` - 命名信号量
- `fafafa.core.sync.namedMutex` - 命名互斥锁
- `fafafa.core.atomic` - 进程内原子操作

## 版本历史

- v1.0.0 (2025-12): 初始版本
