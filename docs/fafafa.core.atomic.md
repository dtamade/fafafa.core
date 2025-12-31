# fafafa.core.atomic

现代化、高性能、跨平台的 FreePascal 原子操作库，提供无锁编程的基础设施。

## 概述

`fafafa.core.atomic` 提供了完整的原子操作 API，支持：
- 基础原子操作（加载、存储、交换、比较交换）
- 读-修改-写操作（fetch_add、fetch_and、fetch_or、fetch_xor）
- 内存序控制（relaxed、consume、acquire、release、acq_rel、seq_cst）
- 指针运算（fetch_add、fetch_sub）
- 带标签指针（tagged pointer）用于解决 ABA 问题

## 支持的数据类型

- **整数类型**：Int32、Int64、UInt32、UInt64
- **指针类型**：Pointer、PtrInt、PtrUInt
- **带标签指针**：atomic_tagged_ptr_t（指针 + 版本标签）

## 内存序说明

### 内存序类型
```pascal
type
  memory_order_t = (
    mo_relaxed,   // 最弱序：仅保证原子性，无同步语义
    mo_consume,   // 当前实现：等价 mo_acquire（更强；跨平台一致性）
    mo_acquire,   // 获取序：防止后续读写重排到此操作之前
    mo_release,   // 释放序：防止之前读写重排到此操作之后
    mo_acq_rel,   // 获取+释放（RMW）：用于 read-modify-write 操作
    mo_seq_cst    // 顺序一致：全局统一顺序，最强保证
  );
```

### 使用建议
- **mo_relaxed**：计数器、统计信息等无同步要求的场景
- **mo_consume**：当前实现等价 `mo_acquire`，建议直接使用 `mo_acquire`
- **mo_acquire/mo_release**：生产者-消费者模式、锁实现
- **mo_acq_rel**：RMW 场景（如引用计数 decrement、一些无锁结构）
- **mo_seq_cst**：需要全局一致性的复杂同步（最安全的默认选择）

## 基础 API

### 原子加载与存储
```pascal
// 原子加载
function atomic_load(var target: Int32): Int32; overload;
function atomic_load(var target: Int32; order: memory_order_t): Int32; overload;

function atomic_load_64(var target: Int64): Int64; overload;
function atomic_load_64(var target: Int64; order: memory_order_t): Int64; overload;

function atomic_load(var target: Pointer): Pointer; overload;
function atomic_load(var target: Pointer; order: memory_order_t): Pointer; overload;

// 原子存储
procedure atomic_store(var target: Int32; value: Int32); overload;
procedure atomic_store(var target: Int32; value: Int32; order: memory_order_t); overload;

procedure atomic_store_64(var target: Int64; value: Int64); overload;
procedure atomic_store_64(var target: Int64; value: Int64; order: memory_order_t); overload;

procedure atomic_store(var target: Pointer; value: Pointer); overload;
procedure atomic_store(var target: Pointer; value: Pointer; order: memory_order_t); overload;
```

### 原子交换
```pascal
// 原子交换：返回旧值，设置新值
// （无 order 版本默认使用 seq_cst）
function atomic_exchange(var target: Int32; desired: Int32): Int32; overload;
function atomic_exchange(var target: Int32; desired: Int32; order: memory_order_t): Int32; overload;

function atomic_exchange_64(var target: Int64; desired: Int64): Int64; overload;
function atomic_exchange_64(var target: Int64; desired: Int64; order: memory_order_t): Int64; overload;

function atomic_exchange(var target: Pointer; desired: Pointer): Pointer; overload;
function atomic_exchange(var target: Pointer; desired: Pointer; order: memory_order_t): Pointer; overload;
```

### 比较交换（CAS）
```pascal
// 强比较交换：如果 target = expected，则设置为 desired，返回是否成功
// （无 order 版本默认使用 seq_cst）
function atomic_compare_exchange_strong(
  var target: Int32;
  var expected: Int32;
  desired: Int32
): Boolean; overload;

// 双内存序版本（对齐 C++11 / Rust）：success_order 与 failure_order
function atomic_compare_exchange_strong(
  var target: Int32;
  var expected: Int32;
  desired: Int32;
  success_order, failure_order: memory_order_t
): Boolean; overload;

// 弱比较交换：允许虚假失败（在循环中使用性能更好；某些平台更快）
function atomic_compare_exchange_weak(
  var target: Int32;
  var expected: Int32;
  desired: Int32
): Boolean; overload;

function atomic_compare_exchange_weak(
  var target: Int32;
  var expected: Int32;
  desired: Int32;
  success_order, failure_order: memory_order_t
): Boolean; overload;
```

### 读-修改-写操作
```pascal
// （无 order 版本默认使用 seq_cst）

// 原子加法：返回旧值
function atomic_fetch_add(var target: Int32; delta: Int32): Int32; overload;
function atomic_fetch_add(var target: Int32; delta: Int32; order: memory_order_t): Int32; overload;

function atomic_fetch_sub(var target: Int32; delta: Int32): Int32; overload;
function atomic_fetch_sub(var target: Int32; delta: Int32; order: memory_order_t): Int32; overload;

// 位运算：返回旧值
function atomic_fetch_and(var target: Int32; mask: Int32): Int32; overload;
function atomic_fetch_and(var target: Int32; mask: Int32; order: memory_order_t): Int32; overload;

function atomic_fetch_or(var target: Int32; mask: Int32): Int32; overload;
function atomic_fetch_or(var target: Int32; mask: Int32; order: memory_order_t): Int32; overload;

function atomic_fetch_xor(var target: Int32; mask: Int32): Int32; overload;
function atomic_fetch_xor(var target: Int32; mask: Int32; order: memory_order_t): Int32; overload;

// 便利函数：返回新值（这些接口为 seq_cst；如需指定内存序请用 fetch_add/fetch_sub）
function atomic_increment(var target: Int32): Int32;
function atomic_decrement(var target: Int32): Int32;
```

### 指针运算
```pascal
// 指针偏移（字节为单位）
function atomic_fetch_add(var target: Pointer; deltaBytes: PtrInt): Pointer;
function atomic_fetch_sub(var target: Pointer; deltaBytes: PtrInt): Pointer;
```

## 带标签指针 API

用于解决 ABA 问题的带版本标签的指针（单字宽度打包实现）：

```pascal
type
  // x86_64: tag 使用高 16 位（指针使用低 48 位）
  // 其他 64-bit: 为避免假设“指针一定是 48-bit VA”，默认改用低 TAG_BITS 位（默认 TAG_BITS = 3；要求指针按 2^TAG_BITS 对齐）
  // 32-bit: tag 使用低 TAG_BITS 位（默认 TAG_BITS = 2；要求指针按 2^TAG_BITS 对齐）
  // 可通过编译宏调整：FAFAFA_ATOMIC_TAG_BITS_64 / FAFAFA_ATOMIC_TAG_BITS_32
  atomic_tagged_ptr_t = type PtrUInt;

// 创建带标签指针
function atomic_tagged_ptr(ptr: Pointer; tag: {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF}): atomic_tagged_ptr_t;

// 提取指针和标签
function atomic_tagged_ptr_get_ptr(const tagged: atomic_tagged_ptr_t): Pointer;
function atomic_tagged_ptr_get_tag(const tagged: atomic_tagged_ptr_t): {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF};

// 标签递增（用于版本控制）
function atomic_tagged_ptr_next(const tagged: atomic_tagged_ptr_t): {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF};

// 原子操作（默认版本）
// - Load/Store 默认：x86/x86_64 为 mo_relaxed；弱内存序平台为 mo_acquire/mo_release
// - Exchange/CAS 默认：mo_seq_cst
function atomic_tagged_ptr_load(var target: atomic_tagged_ptr_t): atomic_tagged_ptr_t; overload;
procedure atomic_tagged_ptr_store(var target: atomic_tagged_ptr_t; desired: atomic_tagged_ptr_t); overload;
function atomic_tagged_ptr_exchange(var target: atomic_tagged_ptr_t; desired: atomic_tagged_ptr_t): atomic_tagged_ptr_t; overload;
function atomic_tagged_ptr_compare_exchange_strong(var target: atomic_tagged_ptr_t; var expected: atomic_tagged_ptr_t; desired: atomic_tagged_ptr_t): Boolean; overload;
function atomic_tagged_ptr_compare_exchange_weak(var target: atomic_tagged_ptr_t; var expected: atomic_tagged_ptr_t; desired: atomic_tagged_ptr_t): Boolean; overload;

// 原子操作（显式 memory_order）
function atomic_tagged_ptr_load(var target: atomic_tagged_ptr_t; order: memory_order_t): atomic_tagged_ptr_t; overload;
procedure atomic_tagged_ptr_store(var target: atomic_tagged_ptr_t; desired: atomic_tagged_ptr_t; order: memory_order_t); overload;
function atomic_tagged_ptr_exchange(var target: atomic_tagged_ptr_t; desired: atomic_tagged_ptr_t; order: memory_order_t): atomic_tagged_ptr_t; overload;
function atomic_tagged_ptr_compare_exchange_strong(var target: atomic_tagged_ptr_t; var expected: atomic_tagged_ptr_t; desired: atomic_tagged_ptr_t; success_order, failure_order: memory_order_t): Boolean; overload;
function atomic_tagged_ptr_compare_exchange_weak(var target: atomic_tagged_ptr_t; var expected: atomic_tagged_ptr_t; desired: atomic_tagged_ptr_t; success_order, failure_order: memory_order_t): Boolean; overload;
```

## 性能特征

### 单线程性能（Win64，ns/op）
- **基础操作**：7-13 ns/op（inc/dec/fetch_add）
- **CAS 操作**：9-12 ns/op（compare_exchange）
- **位运算**：10-15 ns/op（fetch_and/or/xor）

### 多线程扩展性
- **低冲突场景**：接近线性扩展
- **高冲突场景**：CAS 循环有退避机制，避免活锁

### 内存序开销
- **mo_relaxed**：最低开销，接近普通内存访问
- **mo_seq_cst**：额外 10-20% 开销，但提供最强保证

## 跨平台兼容性

### 支持平台
- **Windows**：x86、x86_64（基于 Windows Interlocked API）
- **Linux/macOS**：x86_64（基于 GCC/Clang 内建函数）
- **其他平台**：通过 FPC RTL 的 System.InterlockedXXX 函数

### 平台差异
- **32 位系统**：64 位操作可能有额外开销
- **弱内存序架构**（ARM）：mo_relaxed 与 mo_seq_cst 差异更明显
- **对齐要求**：某些平台要求自然对齐（通常自动满足）

## 使用建议

### 选择合适的内存序
```pascal
// 简单计数器：使用 relaxed
atomic_fetch_add(counter, 1, mo_relaxed);

// 生产者-消费者：使用 acquire/release
atomic_store(ready_flag, 1, mo_release);  // 生产者
if atomic_load(ready_flag, mo_acquire) = 1 then  // 消费者

// 复杂同步：使用 seq_cst（默认）
if atomic_compare_exchange_strong(state, expected, new_state) then
```

### CAS 循环模式
```pascal
// 使用 weak CAS 在循环中
repeat
  old_val := atomic_load(target);
  new_val := compute_new_value(old_val);
until atomic_compare_exchange_weak(target, old_val, new_val);
```

### ABA 问题解决
```pascal
// 使用 tagged pointer
var node_ptr: atomic_tagged_ptr_t;
var expected, desired: atomic_tagged_ptr_t;

repeat
  expected := atomic_tagged_ptr_load(node_ptr);
  // ... 计算新值 ...
  desired := atomic_tagged_ptr(new_node, atomic_tagged_ptr_next(expected));
until atomic_tagged_ptr_compare_exchange_weak(node_ptr, expected, desired);
```

## 注意事项

1. **避免混用不同内存序**：同一数据的不同操作应使用一致的内存序策略
2. **指针运算边界**：fetch_add/sub 不检查指针有效性，仅做数值运算
3. **tagged_ptr 限制**：标签位数有限，高频更新可能导致标签回卷
4. **编译器优化**：在 Release 模式下性能最佳
5. **调试支持**：Debug 模式下可能有额外检查，影响性能

## 常见使用模式

### 1. 简单计数器
```pascal
var counter: Int32 = 0;

// 线程安全的递增
function GetNextId: Int32;
begin
  // fetch_add 返回旧值，因此 +1 得到新值
  Result := atomic_fetch_add(counter, 1, mo_relaxed) + 1;
end;
```

### 2. 状态标志
```pascal
var ready_flag: Int32 = 0;

// 生产者线程
procedure ProducerThread;
begin
  // ... 准备数据 ...
  atomic_store(ready_flag, 1, mo_release);  // 通知数据就绪
end;

// 消费者线程
procedure ConsumerThread;
begin
  while atomic_load(ready_flag, mo_acquire) = 0 do
    Sleep(1);  // 等待数据就绪
  // ... 处理数据 ...
end;
```

### 3. 无锁链表插入
```pascal
type
  PNode = ^TNode;
  TNode = record
    data: Integer;
    next: PNode;
  end;

var list_head: PNode;

procedure InsertNode(data: Integer);
var
  new_node: PNode;
  old_head: PNode;
begin
  New(new_node);
  new_node^.data := data;

  repeat
    old_head := atomic_load(list_head);
    new_node^.next := old_head;
  until atomic_compare_exchange_weak(list_head, old_head, new_node);
end;
```

### 4. 引用计数
```pascal
type
  TRefCounted = class
  private
    ref_count: Int32;
  public
    constructor Create;
    procedure AddRef;
    procedure Release;
  end;

constructor TRefCounted.Create;
begin
  inherited;
  ref_count := 1;
end;

procedure TRefCounted.AddRef;
begin
  // 引用计数增加通常使用 relaxed 即可
  atomic_fetch_add(ref_count, 1, mo_relaxed);
end;

procedure TRefCounted.Release;
begin
  // fetch_sub 返回旧值；旧值为 1 表示减 1 后到 0
  if atomic_fetch_sub(ref_count, 1, mo_acq_rel) = 1 then
    Free;
end;
```

## 性能优化建议

### 1. 选择合适的内存序
- **高频操作**：优先使用 `mo_relaxed`
- **同步点**：使用 `mo_acquire`/`mo_release`
- **复杂逻辑**：使用 `mo_seq_cst`（默认）

### 2. 减少 CAS 冲突
```pascal
// 避免：高冲突的 CAS 循环
repeat
  old_val := atomic_load(shared_var);
  new_val := expensive_computation(old_val);
until atomic_compare_exchange_weak(shared_var, old_val, new_val);

// 推荐：预计算减少冲突
local_val := atomic_load(shared_var, mo_relaxed);
new_val := expensive_computation(local_val);
repeat
  old_val := local_val;
until atomic_compare_exchange_weak(shared_var, old_val, new_val);
```

### 3. 批量操作
```pascal
// 避免：频繁的单次原子操作
for i := 1 to 1000 do
  atomic_increment(counter);

// 推荐：批量累积后一次更新
local_sum := 0;
for i := 1 to 1000 do
  Inc(local_sum);
atomic_fetch_add(counter, local_sum);
```

## 调试与测试

### 1. 启用调试检查
```pascal
{$IFDEF DEBUG}
  // 在调试模式下可以添加额外检查
  if atomic_load(state) < 0 then
    raise Exception.Create('Invalid state');
{$ENDIF}
```

### 2. 压力测试
```pascal
// 多线程压力测试模板
procedure StressTest;
const
  THREAD_COUNT = 8;
  OPERATIONS_PER_THREAD = 1000000;
var
  threads: array[0..THREAD_COUNT-1] of TThread;
  i: Integer;
begin
  for i := 0 to THREAD_COUNT-1 do
  begin
    threads[i] := TThread.CreateAnonymousThread(
      procedure
      var j: Integer;
      begin
        for j := 1 to OPERATIONS_PER_THREAD do
          // ... 原子操作 ...
      end);
    threads[i].Start;
  end;

  for i := 0 to THREAD_COUNT-1 do
    threads[i].WaitFor;
end;
```

## 示例代码

详细示例请参考 `examples/fafafa.core.atomic/` 目录：
- `example_basic_operations.lpr` - 基础操作演示
- `example_producer_consumer.lpr` - 生产者-消费者模式
- `example_tagged_ptr_aba.lpr` - ABA 问题解决方案
- `example_thread_counter.lpr` - 多线程计数器与性能对比
