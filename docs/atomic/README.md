# fafafa.core.atomic - 高性能原子操作模块

## 概述

`fafafa.core.atomic` 提供现代化、跨平台的原子操作实现，API 设计参考 C++11 `<atomic>` 和 Rust `std::sync::atomic`。

## 特性

- **跨平台支持**：Windows、Linux、macOS、FreeBSD
- **高性能实现**：使用平台原生原子指令（x86 LOCK 前缀、ARM LDREX/STREX）
- **无锁设计**：避免传统锁的开销和竞争
- **内存序控制**：支持 6 种 C++11 内存排序语义
- **类型安全**：泛型封装确保类型一致性
- **低开销抽象**：大量函数标记为 `inline`，实际是否内联由编译器决定（例如 FPC 对包含 `asm` 的过程/函数通常不会内联）

## 文件结构

| 文件 | 说明 |
|------|------|
| `fafafa.core.atomic.pas` | 底层原子操作原语 |
| `fafafa.core.atomic.base.pas` | 类型安全封装（`TAtomicInt32` 等） |
| `fafafa.core.sync.spin.atomic.pas` | 基于原子操作的自旋锁 |

## 快速开始

### 基本用法

```pascal
uses
  fafafa.core.atomic,
  fafafa.core.atomic.base;

var
  Counter: Int32 = 0;
  
// 底层 API
atomic_fetch_add(Counter, 1);           // 原子加 1，返回旧值
atomic_store(Counter, 100, mo_release); // 原子存储，release 语义
Val := atomic_load(Counter, mo_acquire);// 原子读取，acquire 语义

// 类型安全封装（推荐）
var
  AtomicCounter: TAtomicInt32;
begin
  AtomicCounter.Store(0);
  AtomicCounter.FetchAdd(1);  // 返回 0
  AtomicCounter.FetchAdd(1);  // 返回 1
  WriteLn(AtomicCounter.Load); // 输出 2
end;
```

### Compare-And-Swap (CAS)

```pascal
var
  Value: Int32 = 10;
  Expected: Int32 = 10;
  Desired: Int32 = 20;

// 强 CAS：不会虚假失败
if atomic_compare_exchange_strong(Value, Expected, Desired) then
  WriteLn('成功：Value 现在是 20')
else
  WriteLn('失败：当前值是 ', Expected);

// 弱 CAS：可能虚假失败，但在某些平台更快（如 ARM）
// 通常在循环中使用
repeat
  Expected := atomic_load(Value);
  Desired := Expected + 1;
until atomic_compare_exchange_weak(Value, Expected, Desired);
```

## 类型安全封装

推荐使用类型安全封装，避免类型混淆错误：

| 类型 | 底层类型 | 说明 |
|------|----------|------|
| `TAtomicInt32` | Int32 | 32 位有符号整数 |
| `TAtomicUInt32` | UInt32 | 32 位无符号整数 |
| `TAtomicInt64` | Int64 | 64 位有符号整数 |
| `TAtomicUInt64` | UInt64 | 64 位无符号整数 |
| `TAtomicBool` | Boolean | 布尔值 |
| `TAtomicPtr` | Pointer | 指针 |
| `TAtomicISize` | PtrInt | 平台相关有符号整数 |
| `TAtomicUSize` | PtrUInt | 平台相关无符号整数 |

### 封装 API 示例

```pascal
var
  Atom: TAtomicInt64;
begin
  // 存储和加载
  Atom.Store(100);
  Val := Atom.Load;
  
  // 原子交换
  OldVal := Atom.Exchange(200);  // 返回 100
  
  // CAS
  Expected := 200;
  if Atom.CompareExchangeStrong(Expected, 300) then
    // 成功
  else
    // Expected 被更新为当前值
    
  // 读-改-写操作
  Atom.FetchAdd(10);   // 返回旧值
  Atom.FetchSub(5);
  Atom.FetchAnd($FF);
  Atom.FetchOr($100);
  Atom.FetchXor($55);
  
  // 便捷方法
  Atom.Increment;  // 等价于 FetchAdd(1) + 1
  Atom.Decrement;
  
  // 访问原始值（非原子）
  RawPtr := Atom.GetMut;  // 返回指向内部值的指针
  FinalVal := Atom.IntoInner;  // 消费并返回值
end;
```

## 内存序（Memory Order）

支持 C++11 定义的 6 种内存序：

| 内存序 | 说明 | 典型用途 |
|--------|------|----------|
| `mo_relaxed` | 仅保证原子性，无同步 | 计数器、统计 |
| `mo_consume` | 当前实现等价 `mo_acquire`（更强） | 建议直接用 `mo_acquire` |
| `mo_acquire` | 获取语义（读） | 锁获取、消费者 |
| `mo_release` | 释放语义（写） | 锁释放、生产者 |
| `mo_acq_rel` | 获取+释放（RMW） | 自旋锁、双向同步 |
| `mo_seq_cst` | 顺序一致性（最强） | 默认，最安全 |

### 内存序使用示例

```pascal
// 生产者-消费者模式
var
  Data: Int32;
  Ready: Int32 = 0;

// 生产者线程
Data := 42;
atomic_store(Ready, 1, mo_release);  // 确保 Data 在 Ready 之前可见

// 消费者线程
while atomic_load(Ready, mo_acquire) = 0 do
  cpu_pause;  // 自旋等待
// 此时 Data 保证可见
WriteLn(Data);  // 42
```

### 默认内存序

- **Load/Store（无 order 重载）**：
  - **x86/x86_64**：由于 TSO（Total Store Order），默认使用 `mo_relaxed`
  - **ARM/ARM64**：默认使用 `mo_acquire`/`mo_release`
- **RMW/CAS（无 order 重载）**：默认使用 `mo_seq_cst`（最强、最安全）
- **不确定时**：使用 `mo_seq_cst`（最安全）

## 底层 API 参考

### 原子加载

```pascal
function atomic_load(var aObj: Int32): Int32;
function atomic_load(var aObj: Int32; aOrder: memory_order_t): Int32;
function atomic_load_64(var aObj: Int64): Int64;
function atomic_load_64(var aObj: Int64; aOrder: memory_order_t): Int64;
```

### 原子存储

```pascal
procedure atomic_store(var aObj: Int32; aDesired: Int32);
procedure atomic_store(var aObj: Int32; aDesired: Int32; aOrder: memory_order_t);
procedure atomic_store_64(var aObj: Int64; aDesired: Int64);
procedure atomic_store_64(var aObj: Int64; aDesired: Int64; aOrder: memory_order_t);
```

### 原子交换

```pascal
function atomic_exchange(var aObj: Int32; aDesired: Int32): Int32;
function atomic_exchange(var aObj: Int32; aDesired: Int32; aOrder: memory_order_t): Int32;
function atomic_exchange_64(var aObj: Int64; aDesired: Int64): Int64;
```

### Compare-And-Swap

```pascal
// 强 CAS：不会虚假失败
function atomic_compare_exchange_strong(var aObj: Int32; 
  var aExpected: Int32; aDesired: Int32): Boolean;
function atomic_compare_exchange_strong(var aObj: Int32; 
  var aExpected: Int32; aDesired: Int32;
  aSuccessOrder, aFailureOrder: memory_order_t): Boolean;

// 弱 CAS：可能虚假失败（ARM 上更快）
function atomic_compare_exchange_weak(var aObj: Int32; 
  var aExpected: Int32; aDesired: Int32): Boolean;
```

### 读-改-写操作

```pascal
// 算术操作
function atomic_fetch_add(var aObj: Int32; aArg: Int32): Int32;  // 返回旧值
function atomic_fetch_sub(var aObj: Int32; aArg: Int32): Int32;

// 位操作
function atomic_fetch_and(var aObj: Int32; aArg: Int32): Int32;
function atomic_fetch_or(var aObj: Int32; aArg: Int32): Int32;
function atomic_fetch_xor(var aObj: Int32; aArg: Int32): Int32;
function atomic_fetch_nand(var aObj: Int32; aArg: Int32): Int32;  // NOT(old AND arg)

// 比较操作
function atomic_fetch_max(var aObj: Int32; aArg: Int32): Int32;  // 返回旧值，存 max
function atomic_fetch_min(var aObj: Int32; aArg: Int32): Int32;  // 返回旧值，存 min

// 便捷方法
function atomic_increment(var aObj: Int32): Int32;  // 返回新值
function atomic_decrement(var aObj: Int32): Int32;  // 返回新值
```

### 原子标志

```pascal
type
  atomic_flag_t = type Int32;

function atomic_flag_test_and_set(var aFlag: atomic_flag_t): Boolean;
function atomic_flag_test(var aFlag: atomic_flag_t): Boolean;
procedure atomic_flag_clear(var aFlag: atomic_flag_t);
```

### 内存屏障

```pascal
procedure atomic_thread_fence(aOrder: memory_order_t);
```

### 带标签指针（Lock-free ABA 防护）

```pascal
type
  atomic_tagged_ptr_t = type PtrUInt;

// x86_64: tag is 16-bit (high 16 bits of the word)
// other 64-bit: tag uses low TAG_BITS (default TAG_BITS = 3; requires pointer alignment)
// 32-bit: tag is UInt32, but only low TAG_BITS are used (default TAG_BITS = 2; requires pointer alignment)
// TAG_BITS can be customized via: FAFAFA_ATOMIC_TAG_BITS_64 / FAFAFA_ATOMIC_TAG_BITS_32
function atomic_tagged_ptr(aPtr: Pointer; aTag: {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF}): atomic_tagged_ptr_t;
function atomic_tagged_ptr_get_ptr(const aTaggedPtr: atomic_tagged_ptr_t): Pointer;
function atomic_tagged_ptr_get_tag(const aTaggedPtr: atomic_tagged_ptr_t): {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF};
function atomic_tagged_ptr_compare_exchange_strong(...): Boolean;
```

## 性能说明

### x86/x86_64 优化

- `LOCK` 前缀指令隐含全内存屏障
- 普通 `atomic_load/atomic_store` 的 `mo_acquire/mo_release` 在 x86/x86_64 上无需额外 CPU fence（仅编译器屏障即可）；`mo_seq_cst` 仍保持强顺序
- `fetch_and/or/xor` 等操作无需额外屏障
- `atomic_exchange` 使用 `XCHG` 指令（隐含 LOCK）
- `fetch_add/sub` 使用 `LOCK XADD`

### ARM/ARM64 注意事项

- 需要显式内存屏障（`DMB`/`DSB`）
- 弱 CAS（`LDXR`/`STXR`）可能虚假失败
- 64 位操作在 32 位 ARM 上不可用（需要 LDREXD/STREXD）

### Lock-free 状态查询

```pascal
function atomic_is_lock_free_32: Boolean;  // 32 位操作是否无锁
function atomic_is_lock_free_64: Boolean;  // 64 位操作是否无锁
function atomic_is_lock_free_ptr: Boolean; // 指针操作是否无锁
```

## 常见模式

### 引用计数

```pascal
type
  TRefCounted = class
  private
    FRefCount: TAtomicInt32;
  public
    procedure AddRef;
    procedure Release;
  end;

procedure TRefCounted.AddRef;
begin
  FRefCount.FetchAdd(1, mo_relaxed);
end;

procedure TRefCounted.Release;
begin
  if FRefCount.FetchSub(1, mo_acq_rel) = 1 then
  begin
    // 最后一个引用，释放资源
    atomic_thread_fence(mo_acquire);
    Free;
  end;
end;
```

### 自旋锁

```pascal
var
  Lock: TAtomicBool;

procedure Acquire;
begin
  while Lock.Exchange(True, mo_acquire) do
    cpu_pause;
end;

procedure Release;
begin
  Lock.Store(False, mo_release);
end;
```

### 无锁栈（使用带标签指针防止 ABA）

```pascal
type
  PNode = ^TNode;
  TNode = record
    Value: Int32;
    Next: PNode;
  end;

var
  Head: atomic_tagged_ptr_t;

procedure Push(Value: Int32);
var
  NewNode: PNode;
  OldHead, NewHead: atomic_tagged_ptr_t;
begin
  New(NewNode);
  NewNode^.Value := Value;
  repeat
    OldHead := atomic_tagged_ptr_load(Head);
    NewNode^.Next := atomic_tagged_ptr_get_ptr(OldHead);
    NewHead := atomic_tagged_ptr(NewNode, atomic_tagged_ptr_next(OldHead));
  until atomic_tagged_ptr_compare_exchange_weak(Head, OldHead, NewHead);
end;
```

## 注意事项

1. **原子操作仅保证单个操作的原子性**，复合操作需要额外同步
2. **避免 ABA 问题**：使用带标签指针或 Hazard Pointer
3. **避免虚假共享**：确保原子变量在独立缓存行
4. **选择合适的内存序**：过强浪费性能，过弱导致 bug
5. **32 位平台**：64 位原子操作仅在 x86 上可用（需要 CMPXCHG8B 才 lock-free；若 CPU 不支持或无 CPUID，则退化为锁实现，`atomic_is_lock_free_64` 返回 False）。
   另外，32-bit 原子原语依赖 FPC 的 `Interlocked*`，底层通常需要 CPU 支持 `CMPXCHG` / `XADD` 等指令。
6. **atomic_tagged_ptr（64 位）**：
   - x86_64：默认使用“低 48 位指针 + 高 16 位 tag”打包（适用于典型用户态 48-bit VA）。
   - 其他 64-bit：为避免假设“指针一定是 48-bit VA”，默认使用“低 TAG_BITS 位 tag”（默认 TAG_BITS = 3）。这要求指针按 `2^TAG_BITS` 对齐，同时 tag 可用范围更小，更容易回卷。TAG_BITS 可通过 `FAFAFA_ATOMIC_TAG_BITS_64` 调整。

## 相关模块

- `fafafa.core.sync` - 同步原语（Mutex、Condvar、Semaphore）
- `fafafa.core.lockfree` - 无锁数据结构
- `fafafa.core.mem` - 内存管理

## 版本历史

### v2.0 (feature/atomic-v2)

**已完成：**
- 新增 `TAtomicISize`、`TAtomicUSize` 类型
- x86 性能优化：移除 `fetch_and/or/xor` 多余屏障
- 新增 `fetch_max`、`fetch_min`、`fetch_nand` 操作
- 新增带内存序参数的 API 版本
- 32 位 x86 64 位原子操作（CMPXCHG8B；并带运行时检测 + fallback）
- 补齐 32-bit x86 测试与回归用例
- 完整 API 文档
