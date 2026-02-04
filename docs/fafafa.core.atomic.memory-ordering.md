# fafafa.core.atomic 内存顺序指南

本指南详细解释原子操作的内存顺序（Memory Ordering）语义，帮助你正确使用 `fafafa.core.atomic` 模块。

## 为什么需要内存顺序？

在多核 CPU 上，编译器和处理器会对指令进行重排序以提高性能。这在单线程程序中是安全的，但在多线程程序中可能导致数据竞争。

```
Thread A                    Thread B
─────────                   ─────────
data := 42;                 while flag = 0 do ;
flag := 1;                  WriteLn(data);  // 可能输出 0！
```

**问题**：Thread B 可能在 `data` 写入之前看到 `flag = 1`。

**解决**：使用正确的内存顺序保证可见性。

## 内存顺序类型

### mo_relaxed（松弛序）

**语义**：只保证原子性，不保证顺序

**用途**：
- 计数器、统计信息
- 不需要与其他操作同步的场景

**性能**：最快（无内存屏障）

```pascal
// 简单计数器 - 不需要同步
atomic_fetch_add(Counter, 1, mo_relaxed);

// 读取统计信息
Total := atomic_load(Counter, mo_relaxed);
```

**⚠️ 不要用于**：线程间通信、生产者-消费者模式

---

### mo_acquire（获取序）

**语义**：此操作之后的读写不会被重排到此操作之前

**用途**：
- 读取共享数据
- 与 `mo_release` 配对使用
- 锁的获取操作

**性能**：中等（可能需要 load fence）

```pascal
// 消费者：获取数据
if atomic_load(Flag, mo_acquire) = 1 then
begin
  // 保证能看到 Data 的最新值
  Value := Data;
end;
```

**图解**：
```
            ┌─────────────────────────┐
            │    mo_acquire load      │
            └───────────┬─────────────┘
                        │
                        ▼ 屏障：之后的操作不能重排到这里之前
                   后续读写
```

---

### mo_release（释放序）

**语义**：此操作之前的读写不会被重排到此操作之后

**用途**：
- 写入共享数据
- 与 `mo_acquire` 配对使用
- 锁的释放操作

**性能**：中等（可能需要 store fence）

```pascal
// 生产者：发布数据
Data := 42;
atomic_store(Flag, 1, mo_release);
// 保证 Data 在 Flag 之前写入
```

**图解**：
```
                   之前读写
                        │
                        ▼ 屏障：之前的操作不能重排到这里之后
            ┌─────────────────────────┐
            │    mo_release store     │
            └─────────────────────────┘
```

---

### mo_acq_rel（获取-释放序）

**语义**：同时具有 acquire 和 release 语义

**用途**：
- Read-Modify-Write 操作（如 CAS、fetch_add）
- 需要同时读取和写入的原子操作

**性能**：较慢（完整的双向屏障）

```pascal
// 原子地增加并获取旧值
OldValue := atomic_fetch_add(Counter, 1, mo_acq_rel);
// 之前的写入对后续读取可见
// 之后的读取能看到之前的写入
```

---

### mo_seq_cst（顺序一致性）

**语义**：最强的顺序保证，所有线程看到相同的操作顺序

**用途**：
- 需要全局顺序的场景
- 不确定时的默认选择
- 调试和验证

**性能**：最慢（完整的内存屏障）

```pascal
// 最安全但最慢的选择
atomic_store(Flag, 1, mo_seq_cst);
Value := atomic_load(Data, mo_seq_cst);
```

**⚠️ 注意**：除非必要，否则使用更弱的顺序以获得更好的性能

---

## 常见模式

### 1. 生产者-消费者（单写单读）

```pascal
var
  Data: Integer;
  Ready: Int32 = 0;

// 生产者线程
procedure Producer;
begin
  Data := CalculateResult;  // 准备数据
  atomic_store(Ready, 1, mo_release);  // 发布
end;

// 消费者线程
procedure Consumer;
begin
  while atomic_load(Ready, mo_acquire) = 0 do
    CpuRelax;

  // 现在可以安全读取 Data
  ProcessData(Data);
end;
```

### 2. 自旋锁

```pascal
var
  Locked: Int32 = 0;

procedure SpinLock;
begin
  while atomic_exchange(Locked, 1, mo_acquire) = 1 do
    CpuRelax;
  // 获取锁成功
end;

procedure SpinUnlock;
begin
  atomic_store(Locked, 0, mo_release);
end;
```

### 3. 引用计数

```pascal
var
  RefCount: Int32 = 1;

procedure AddRef;
begin
  atomic_fetch_add(RefCount, 1, mo_relaxed);
  // relaxed 足够：只需要原子性
end;

function Release: Boolean;
begin
  // acq_rel：确保所有使用在销毁之前完成
  if atomic_fetch_sub(RefCount, 1, mo_acq_rel) = 1 then
  begin
    atomic_thread_fence(mo_acquire);  // 最终获取
    Result := True;  // 可以销毁
  end
  else
    Result := False;
end;
```

### 4. 双重检查锁定（Singleton）

```pascal
var
  Instance: TObject = nil;
  Initialized: Int32 = 0;

function GetInstance: TObject;
begin
  if atomic_load(Initialized, mo_acquire) = 0 then
  begin
    GlobalLock.Acquire;
    try
      if Initialized = 0 then
      begin
        Instance := TObject.Create;
        atomic_store(Initialized, 1, mo_release);
      end;
    finally
      GlobalLock.Release;
    end;
  end;
  Result := Instance;
end;
```

## 选择指南

```
需要什么保证？
│
├── 只需要原子性？
│   └── mo_relaxed（最快）
│
├── 读取共享数据？
│   └── mo_acquire
│
├── 写入共享数据？
│   └── mo_release
│
├── 原子读-改-写？
│   └── mo_acq_rel
│
└── 不确定/需要最强保证？
    └── mo_seq_cst（最慢但最安全）
```

## 性能对比

| 内存顺序 | x86-64 开销 | ARM64 开销 | 适用场景 |
|---------|-------------|------------|----------|
| mo_relaxed | 无 | 无 | 计数器 |
| mo_acquire | 无* | DMB ISHLD | 读同步 |
| mo_release | 无* | DMB ISH | 写同步 |
| mo_acq_rel | 无* | DMB ISH | RMW 操作 |
| mo_seq_cst | MFENCE | DMB ISH + 额外 | 全局顺序 |

*x86-64 有强内存模型，大部分顺序自动满足

## 常见错误

### ❌ 错误 1：对通信数据使用 relaxed

```pascal
// 错误：Flag 用 relaxed 不能保证 Data 可见
Data := 42;
atomic_store(Flag, 1, mo_relaxed);  // ❌

// 正确：
Data := 42;
atomic_store(Flag, 1, mo_release);  // ✅
```

### ❌ 错误 2：acquire/release 不配对

```pascal
// 错误：只有 release 没有 acquire
atomic_store(Flag, 1, mo_release);

// ... 在另一个线程 ...
if Flag = 1 then  // ❌ 普通读取没有 acquire 语义
  ProcessData;

// 正确：
if atomic_load(Flag, mo_acquire) = 1 then  // ✅
  ProcessData;
```

### ❌ 错误 3：过度使用 seq_cst

```pascal
// 不必要的性能损失
atomic_fetch_add(Counter, 1, mo_seq_cst);  // ❌ 计数器不需要

// 正确：
atomic_fetch_add(Counter, 1, mo_relaxed);  // ✅
```

## API 快速参考

```pascal
// 加载
function atomic_load(var Obj; Order: memory_order_t = mo_seq_cst): T;

// 存储
procedure atomic_store(var Obj; Value: T; Order: memory_order_t = mo_seq_cst);

// 交换
function atomic_exchange(var Obj; Desired: T; Order: memory_order_t = mo_seq_cst): T;

// 比较交换
function atomic_compare_exchange_strong(var Obj; var Expected: T; Desired: T;
  SuccessOrder: memory_order_t = mo_seq_cst;
  FailureOrder: memory_order_t = mo_seq_cst): Boolean;

// 原子加/减
function atomic_fetch_add(var Obj; Arg: T; Order: memory_order_t = mo_seq_cst): T;
function atomic_fetch_sub(var Obj; Arg: T; Order: memory_order_t = mo_seq_cst): T;

// 内存屏障
procedure atomic_thread_fence(Order: memory_order_t);
```

## 相关文档

- [fafafa.core.sync.selection-guide](fafafa.core.sync.selection-guide.md) - 同步原语选择
- [fafafa.core.sync.scopedlock](fafafa.core.sync.scopedlock.md) - 多锁获取
- [fafafa.core.sync.seqlock](fafafa.core.sync.seqlock.md) - 序列锁

## 参考资料

- [C++ Memory Model](https://en.cppreference.com/w/cpp/atomic/memory_order)
- [Preshing on Programming - Memory Ordering](https://preshing.com/20120913/acquire-and-release-semantics/)
- [Intel x86 Memory Ordering](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)
