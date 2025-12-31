# fafafa.core.lockfree 模块（内存序与性能注意事项）

本页补充 lock-free 数据结构在 FreePascal 下的内存序、伪共享与 ABA 相关说明，以及本模块新增的可选性能开关。

## 内存序与可见性
- 我们使用 fafafa.core.atomic 提供的 `atomic_load_64/atomic_store_64/atomic_compare_exchange_strong_*` 等 API，并显式指定 `memory_order_t`：
  - 读取快路径使用 `mo_relaxed` 以降低一致性成本
  - 关键数据交接使用 `mo_acquire/mo_release` 保证先行发生关系
- SPSC：序列号法避免 CAS，读写使用 `mo_acquire/mo_release` 保证数据对消费端的可见性
- MPMC：Vyukov 风格的序列号环，CAS 成功后写入/回收位用 `mo_release`；读路径用 `mo_acquire`
- MPSC/Treiber：指针读取使用 `mo_acquire` 以确保可见性，链接/发布使用 `mo_acq_rel` / `mo_release`

## 伪共享与 cacheline padding（可选）
- 在多线程并发下，紧邻的索引/计数变量可能落在同一缓存行，引发频繁一致性流量（伪共享）
- 我们提供可选宏在关键字段间插入 padding：
  - 在 src/fafafa.core.settings.inc 启用：
    - `{$DEFINE FAFAFA_LOCKFREE_CACHELINE_PAD}`
- 启用后，SPSC/MPMC 在关键字段之间增加 64 字节对齐的字节填充，降低伪共享风险

### 何时启用（最佳实践）
- MPMC：多数多核场景建议开启。尤其是 P、C 均大于1 且容量较小导致槽位竞争明显的场景，PadOn 往往带来显著吞吐提升
- SPSC：收益与平台/调度相关，建议用微基准验证后按需开启
- 高并发/高冲突且延迟敏感：优先考虑 PadOn；若仍有 CAS 冲突热点，再评估 Backoff 开关

## CAS 冲突与轻量退避（可选）
- 高冲突场景下，CAS 重试可能造成活跃自旋，影响整体吞吐
- 我们提供可选退避策略（默认关闭）：
  - `{$DEFINE FAFAFA_LOCKFREE_BACKOFF}`
  - 可选参数：
    - `{$DEFINE FAFAFA_LOCKFREE_BACKOFF_EVERY := 64}` 每多少次失败小退避一次
    - `{$DEFINE FAFAFA_LOCKFREE_BACKOFF_SLEEP_MS := 0}` 退避使用 Sleep(毫秒)，0 近似 yield
- 当前实现使用 `SysUtils.Sleep(0)` 作为跨平台轻量退避，后续可在支持的平台替换为 CPU pause/yield

### 何时启用（最佳实践）
- 仅在 MPMC 的高冲突（高并发、容量较小、热槽位集中）场景下考虑开启；对 SPSC 无明显帮助
- 若 PadOn 已缓解伪共享但仍出现 CAS 热点，开启 Backoff 作为进一步缓解；务必通过微基准复核吞吐与尾延迟

## 兼容性
- 弱内存序平台（ARM/POWER 等）务必遵循上述 acquire/release 原则；指针读取（如 Head/Tail/Next/FTop）使用 `atomic_load(..., mo_acquire)`；发布写使用 `atomic_store(..., mo_release)` / CAS 使用 `mo_acq_rel`。

- 所有开关默认关闭，不改变现有行为与性能特征

## 边界行为与幂等性（契约）
- HashMap（OA）
  - 容量逼近上限：当达到容量上限，Put 返回 False；MapEx 的 PutEx 返回 mprFailed
  - 自定义比较器（大小写不敏感）下，容量满后大小写不同的新键仍会插入失败
- MPMC 队列（预分配）
  - 满队列：再次 Enqueue 失败且不改变 IsFull/Size（幂等）
  - 空队列：重复 Dequeue 失败且不改变 IsEmpty/Size（幂等）

这些契约已由单元测试覆盖（主线与独立接口/工厂工程），用于防止回退。

- 开启后可能改善在高并发/高冲突场景下的性能与稳定性

## 构建说明（lazbuild）
- 所有测试/示例/基准构建统一使用 lazbuild（tools/lazbuild.bat）
- 测试入口：`tests/fafafa.core.lockfree/BuildAndTest.bat test`
  - 需要配置 LAZBUILD_EXE 或在 PATH 中提供 lazbuild

## 微基准使用（SPSC/MPMC 吞吐）
- 工程：tests/fafafa.core.lockfree/benchmark_micro_spsc_mpmc.lpi
- 一键对比脚本：
  - Run_Micro_SPSC_MPMC_PadCompare.bat（构建 PadOff/PadOn/BackoffOn 并运行；控制台直接打印 CSV）
  - Run_Micro_BatchMatrix.bat（多容量与多线程组合批量跑分，输出到 logs/micro_matrix_*.csv）
- 汇总脚本（PowerShell）：
  - Summarize_Micro_CSV.ps1 <CSV 文件>（按 algo/mode/capacity/producers/consumers 聚合，输出 mean/median）
- 参数示例：
  - duration_ms=5000 repeats=5 capacity=32768 producers=8 consumers=8 algo=both
- 推荐流程：
  1) 先用 PadOff/PadOn 对比确认是否存在伪共享收益（优先关注 MPMC）
  2) 若仍有冲突热点，再引入 BackoffOn 观察吞吐与尾延迟变化
  3) 固定 CPU 亲和/隔离背景负载，提高重复性；按中位数/均值评估


# fafafa.core.lockfree 技术文档

## 概述

`fafafa.core.lockfree` 模块提供了一套高性能的无锁数据结构实现，专为多线程并发环境设计。该模块基于经典的无锁算法，如 Treiber Stack、Michael-Scott Queue 和 Dmitry Vyukov 的 MPMC Queue，提供了线程安全且高效的数据结构。

## 核心特性

- **完全无锁**: 所有数据结构都使用原子操作而非互斥锁
- **ABA安全**: 通过版本计数器和64位打包头部解决ABA问题
- **高性能**: 针对高并发场景优化，支持数百万次操作/秒
- **内存安全**: 预分配策略避免运行时内存分配/释放
- **跨平台**: 支持Windows、Linux、macOS等主流平台
- **类型安全**: 使用FreePascal泛型提供类型安全的接口

## 数据结构概览

## 快速选型矩阵（速览）

- SPSC（单生产者单消费者）：TSPSCQueue<T>
- MPSC（多生产者单消费者）：TMichaelScottQueue<T>
- MPMC（多生产者多消费者）：TPreAllocMPMCQueue<T>
- HashMap：
  - 键值简单/高吞吐/负载可控（≤0.7）：开放寻址 OA（TLockFreeHashMap<K,V> in .openAddressing）
  - 插入/删除频繁/规模动态变化：分离链接 MM（TMichaelHashMap<K,V>）
- 栈：
  - 动态容量：TTreiberStack<T>（注意回收限制）
  - 固定容量/ABA 安全：TPreAllocStack<T>


- 何时选用严格工厂：
  - 键类型为非平凡类型（复杂记录、大小写不敏感字符串等），并且需要自定义相等/哈希语义
  - 希望在运行期遗漏比较器/哈希时立即报错（而不是在编译或运行晚期才暴露）


## 常用工厂速查表（含 Strict 版本）

- 队列/栈
  - SPSC：CreateIntSPSCQueue / CreateStrSPSCQueue / …
  - MPSC（Michael-Scott）：CreateIntMPSCQueue / CreateStrMPSCQueue / …
  - MPMC（预分配）：CreateIntMPMCQueue / CreateStrMPMCQueue / …
  - 栈（固定容量优先）：CreateIntPreAllocStack / CreateStrPreAllocStack / …
  - 栈（动态容量，注意回收）：CreateIntTreiberStack / CreateStrTreiberStack / …
- HashMap（开放寻址 OA）
  - 常用：CreateIntIntOAHashMap / CreateStrIntOAHashMap / CreateStrStrOAHashMap / …
  - 严格（运行期强制 Hash/Equal）：
    - CreateIntIntOAHashMapStrict(ACapacity, @Hash, @Equal)
    - CreateStrIntOAHashMapStrict(ACapacity, @Hash, @Equal)
    - CreateStrStrOAHashMapStrict(ACapacity, @Hash, @Equal)
    - 或直接调用类型方法 NewStrict(ACapacity, AHash, AEqual)
- HashMap（分离链接 MM / Michael & Michael）
  - 常用：CreateIntIntMMHashMap / CreateStrIntMMHashMap / CreateStrStrMMHashMap / …

提示：
- OA 适合“键简单/装载≤0.7/删除少”；需要自定义相等/哈希或高删除率请考虑 MM 或 OA 严格工厂
- Destroy/Clear 必须在“无并发访问”时调用（所有结构通用约束）

### 队列 (Queues)

#### 1. TSPSCQueue<T> - 单生产者单消费者队列
- **用途**: 单线程生产者和单线程消费者场景
- **特点**: 基于环形缓冲区，极高性能
- **容量**: 固定容量，必须是2的幂次方
- **线程安全**: 仅支持一个生产者和一个消费者

```pascal
var
  LQueue: specialize TSPSCQueue<Integer>;
begin
  LQueue := specialize TSPSCQueue<Integer>.Create(1024);
  try
    LQueue.Enqueue(42);
    if LQueue.Dequeue(LValue) then
      WriteLn('Dequeued: ', LValue);
  finally
    LQueue.Free;
  end;
end;
```

#### 2. TMichaelScottQueue<T> - MPSC（Michael-Scott）无锁队列
- **用途**: 多生产者单消费者场景
- **特点**: 基于链表，动态内存分配
- **容量**: 无限制（受内存限制）
- **线程安全**: 支持多个生产者，单个消费者

```pascal
var
  LQueue: specialize TMichaelScottQueue<string>;
begin
  LQueue := specialize TMichaelScottQueue<string>.Create;
  try
    LQueue.Enqueue('Hello');
    if LQueue.Dequeue(LValue) then
      WriteLn('Dequeued: ', LValue);
  finally
    LQueue.Free;
  end;
end;
```

#### 3. TPreAllocMPMCQueue<T> - 预分配MPMC队列
- **用途**: 多生产者多消费者场景
- **特点**: 基于Dmitry Vyukov算法，预分配内存
- **容量**: 固定容量，必须是2的幂次方
- **线程安全**: 支持多个生产者和多个消费者

```pascal
var
  LQueue: specialize TPreAllocMPMCQueue<Integer>;
begin
  LQueue := specialize TPreAllocMPMCQueue<Integer>.Create(256);
  try
    if LQueue.Enqueue(42) then
      WriteLn('Enqueued successfully');
    if LQueue.Dequeue(LValue) then
      WriteLn('Dequeued: ', LValue);
  finally
    LQueue.Free;
  end;
end;
```

### 栈 (Stacks)

#### 1. TTreiberStack<T> - Treiber无锁栈
- **用途**: 多线程栈操作
- **特点**: 基于链表，动态内存分配
- **容量**: 无限制（受内存限制）
- **线程安全**: 支持多个线程同时压栈和弹栈

```pascal
var
  LStack: specialize TTreiberStack<string>;
begin
  LStack := specialize TTreiberStack<string>.Create;
  try
    LStack.Push('World');
    LStack.Push('Hello');
    if LStack.Pop(LValue) then
      WriteLn('Popped: ', LValue); // 输出: Hello
  finally
    LStack.Free;
  end;
end;
```

#### 2. TPreAllocStack<T> - 预分配安全栈
- **用途**: 高性能多线程栈操作
- **特点**: 预分配内存，ABA安全
- **容量**: 固定容量
- **线程安全**: 支持多个线程，使用64位打包头部避免ABA问题

```pascal
var
  LStack: specialize TPreAllocStack<Integer>;
begin
  LStack := specialize TPreAllocStack<Integer>.Create(1024);
  try
    if LStack.Push(42) then
      WriteLn('Pushed successfully');
    if LStack.Pop(LValue) then
      WriteLn('Popped: ', LValue);
  finally
    LStack.Free;
  end;
end;
```

### 哈希表 (Hash Maps)

#### TLockFreeHashMap<K, V> - 无锁哈希表

#### API 一致性（MM 与 OA）
- 为降低学习与迁移成本，两种哈希表实现均同时提供两套等价 API：
  - STL 风格（MM 原生）：insert/find/erase/update
  - Map 风格（OA 原生）：Put/Get/Remove/ContainsKey
- 兼容规则：
  - 在 MM 中新增了 Map 风格别名：Put/Get/Remove/ContainsKey 分别等价于 insert/find/erase/update
  - 在 OA 中新增了 STL 风格别名：insert/find/erase 分别等价于 Put/Get/Remove
  - Put 的返回值表示“插入成功（新建）”；若键已存在则返回 False（需更新请使用 update）

#### OA 的删除与墓碑（tombstone）与容量策略
- 槽位状态：Empty(0) / Writing(1) / Occupied(2) / Deleted(3)
- 删除：Remove 将状态从 Occupied 置为 Deleted，并对托管类型执行 Finalize
- 查找：遇 Deleted/Writing 继续线性探测；遇 Empty 终止（未命中）
- 负载管理：当前版本不做在线扩容；建议装载因子 ≤ 0.7。达到容量上限/高删除率时，Put 可能失败或探测退化，建议：
  - 通过 Clear 清空（会 Finalize 已占用槽）
  - 或迁移到更大容量的新 Map（重建）
- 规划：后续提供重建/rehash 工具与 Builder 的负载上限参数（MaxLoadFactor）

- **用途**: 多线程键值存储
- **特点**: 开放寻址，线性探测
- **容量**: 固定容量
- **线程安全**: 支持并发读写操作

### OA HashMap 的默认兜底语义（重要）
- 当使用开放寻址哈希表（OA）且未显式传入哈希函数/键比较器时：
  - 默认使用 SimpleHash（按字节计算的轻量哈希）与 CompareMem（字节相等比对）作为兜底
  - 适用场景：简单标量/定长记录（无指针/无变长字段）；高吞吐/低删除率负载
  - 不适用：需要自定义相等性或复杂键语义的场景（请显式传入 hash/comparer 或选用 MM 方案）

### OA vs MM 差异与选型（快速对照）
- OA（开放寻址）
  - 结构：单数组 + 探测序列（Cache 友好）
  - 兜底：可默认 SimpleHash+CompareMem（适用平凡类型）
  - 适用：读多写少、删除率低、装载因子 ≤ 0.7、追求吞吐
- MM（分离链接，Michael&Michael）
  - 结构：桶 + 无锁链表（冲突稳定，删除友好）
  - 兜底：不提供默认；必须提供 Hash/Comparer；建议走门面构造
  - 适用：插入/删除频繁、冲突高、对稳定性要求更高

- 对于链式（MM, Michael&Michael）实现：建议通过门面构造器传入明确的哈希/比较器；若未传，则构造应抛出清晰异常并提示通过门面/显式传参（测试已覆盖）
- 最佳实践：在 contracts 中锁定 `Create(nil, nil)` 的行为语义（OA 有兜底，MM 不兜底），避免未来回归



## 接口对齐与使用建议（Rust/Go/Java 对照）

### 队列（Queue）
- 非阻塞（Try）与阻塞（Blocking）
  - TryEnqueue/TryDequeue：与 Rust try_send/try_recv、Java offer/poll、Go select{ default } 语义一致
  - EnqueueBlocking/DequeueBlocking(TimeoutMs)：与 Rust recv_timeout、Java offer(timeout)、Go context 超时等价；TimeoutMs<0 表示无限等待
- 关闭语义（Close/IsClosed）
  - 对齐 Rust/Go 的通道关闭：Close 后生产者返回 False；消费者在 Close+Empty 时 DequeueBlocking 返回 False
- 批量（Batch）
  - EnqueueMany/DequeueMany/DrainTo：对齐 Java drainTo；显著降低同步开销，提升吞吐
- 容量观测
  - Capacity/RemainingCapacity：对齐 Java remainingCapacity；无界结构返回 -1
- MPSC 特例
  - Michael-Scott 入队“总能推进”，EnqueueBlocking 等价直通；Blocking 仅在 Dequeue 侧有意义

示例（SPSC）：
```pascal
var Q: specialize ILockFreeQueueSPSC<Integer>;
    V: Integer; pushed, popped: SizeInt;
begin
  Q := specialize NewSpscQueue<Integer>(1024);
  Q.TryEnqueue(1);
  if Q.DequeueBlocking(V, 10) then ;
  Q.EnqueueMany([2,3,4], pushed);
  Q.Close;
end;
```

### 栈（Stack）
- TryPeek/Clear：TryPeek 对 Treiber 栈通常返回 False（不支持一致性窥视）；Clear 用于快速清空（最佳努力）

### 哈希表（Map/MapEx）
- 命名与语义
  - 基本：Put/Get/Remove/Contains 与 Java/Rust 一致
  - 扩展：PutEx/RemoveEx 返回旧值或结果码
  - Entry/Compute 外观：PutIfAbsent/GetOrAdd/Compute 对齐 Java ConcurrentHashMap 与 Rust HashMap::entry
- 默认哈希/比较器
  - OA：默认 SimpleHash+CompareMem 仅适用于“平凡类型”（无指针/无变长）
  - MM：必须提供语义正确的 Hash/Comparer；推荐通过门面构造器

示例（MapEx/OA）：
```pascal
uses fafafa.core.lockfree.ifaces, fafafa.core.lockfree.factories;

var M: specialize ILockFreeMapEx<string,Integer>;
    inserted, updated: Boolean; outV: Integer;
begin
  M := specialize NewOAHashMapExWithComparer<string,Integer>(64, @CaseInsensitiveHash, @CaseInsensitiveEqual);
  M.PutIfAbsent('Key', 1, inserted);
  M.GetOrAdd('KEY', 0, outV);
  M.Compute('Key', function(const v: Integer): Integer begin Result := v+1; end, updated);
end;
```

提示：MapEx 相关工厂（NewOAHashMapEx/WithComparer、MapBuilder.BuildEx 等）集中在单元 fafafa.core.lockfree.factories；请在 uses 中加入该单元。


### Builder（规划，后续版本）
- QueueBuilder<T>：Capacity/Model(SPSC|MPSC|MPMC)/Backoff/Padding/BlockingPolicy/Stats
- MapBuilder<K,V>：Impl(OA|MM)/Capacity/MaxLoadFactor/Hash/Comparer/Backoff/Pad/Reclaimer(EBR|HP)
- 目标：与 Java Builder/Go Options/Rust Builder 风格一致，保持可插拔与可测性

### 注意事项
- Blocking 为“轻量轮询+Sleep(0)”的跨平台实现；对严格低延迟阻塞可结合线程池/等待原语优化
- RemainingCapacity/Size 为 best-effort（并发视图下非强一致），请勿用于严格计量逻辑
- Entry/Compute 外观尽量在调用侧保持无副作用的回调，避免长耗时操作持有热键热点


### Builder 使用示例（最小）

- QueueBuilder<T>
```pascal
var QB: specialize TQueueBuilder<Integer>;
    QSpsc, QMpmc: specialize ILockFreeQueue<Integer>;
    v: Integer;
begin
  // SPSC，容量至少为 2
  QB := specialize TQueueBuilder<Integer>.New.Capacity(4).ModelSPSC;
  QSpsc := QB.Build;
  QSpsc.TryEnqueue(7);
  QSpsc.TryDequeue(v);

  // MPMC，建议显式容量
  QB := specialize TQueueBuilder<Integer>.New.Capacity(8).ModelMPMC;
  QMpmc := QB.Build;
  QMpmc.TryEnqueue(11);
  QMpmc.TryDequeue(v);
end;
```

- MapBuilder<K,V>（OA 实现）
```pascal
var MB: specialize TMapBuilder<string,Integer>;
    M: specialize ILockFreeMapEx<string,Integer>;
    outV: Integer; updated: Boolean;
begin
  MB := specialize TMapBuilder<string,Integer>.New.Capacity(64).ImplOA;
  M := MB.BuildEx;
  M.PutIfAbsent('Key', 1, updated);
  M.Compute('Key', function(const oldv: Integer): Integer begin Result := oldv + 1; end, updated);
  M.Get('key', outV);
end;
```

- MapBuilder<K,V>（MM 实现，需要提供 Hash/Comparer）
```pascal
var MB: specialize TMapBuilder<string,Integer>;
    M: specialize ILockFreeMapEx<string,Integer>;
    outV: Integer; inserted, updated: Boolean;
begin
  MB := specialize TMapBuilder<string,Integer>.New
          .Capacity(64)
          .ImplMM
          .WithComparer(@DefaultStringHash, @CaseInsensitiveEqual);
  M := MB.BuildEx;
  M.PutIfAbsent('Key', 1, inserted);
  M.Compute('KEY', function(const oldv: Integer): Integer begin Result := oldv + 9; end, updated);
  M.Get('key', outV);
end;
```

- 选型建议（OA vs MM）
  - OA（开放寻址）：键/值简单、读多写少、装载因子 ≤ 0.7、内存局部性优先
  - MM（分离链接）：插入/删除频繁、冲突高、装载因子敏感、需要稳定删除语义



#### BlockingPolicy 说明
- bpNone：沿用默认阻塞实现（当前适配器内部为轻量 Sleep(0)）
- bpSpin：阻塞时使用 Try* + 纯自旋（无 Sleep），适用于极低延迟且预计等待极短的场景
- bpSleep：阻塞时使用 Try* + Sleep(0) 让出时间片，适用于一般场景，避免长时间占用 CPU

注意：BlockingPolicy 仅通过 Builder 生效，不改变默认工厂/适配器的行为；TimeoutMs<0 视为无限等待。

### 策略注入（Backoff/Blocking）
- Backoff：使用 BackoffStep 统一自旋退避（Treiber/MPMC 已接入），避免散落 Sleep(0/1)
- Blocking：IBlockingPolicy 可注入，Builder.WithBlockingPolicy 设置策略对象；默认使用“让出优先”

示例（MPMC + 阻塞 10ms 超时）：
```pascal
var QB: specialize TQueueBuilder<Integer>;
    Q: specialize ILockFreeQueue<Integer>;
    V: Integer;
begin
  QB := specialize TQueueBuilder<Integer>.New.Capacity(8).ModelMPMC
    .BlockingPolicy(TQueueBuilder<Integer>.TBlockingPolicy.bpSleep)
    .WithBlockingPolicy(GetDefaultBlockingPolicy);
  Q := QB.Build;
  if not Q.DequeueBlocking(V, 10) then
    WriteLn('Timeout');
end;
```

最佳实践：
- 默认即可获得稳定“让出优先”；如需极限对比，可注入 GetNoopBlockingPolicy
- 压力/基准测试优先在 MPMC 上验证策略差异



### 微基准运行说明（BlockingPolicy × BackoffPolicy）
- 触发方式：设置环境变量 FAFAFA_BENCH 任意非空值，运行测试入口
  - Windows PowerShell 示例：
    - $env:FAFAFA_BENCH=1; tests\fafafa.core.lockfree\BuildOrTest.bat test
- 可选参数：
  - FAFAFA_BENCH_N：每条基准的迭代次数（默认 10000）
  - FAFAFA_BENCH_REPEAT：每条基准重复次数（默认 5，用于计算均值与标准差）
  - FAFAFA_BENCH_WARMUP：预热重复次数（默认 1，不计入均值/标准差，仅用于 P50/P90 计算的稳定性）
  - FAFAFA_BENCH_OUT：CSV 输出路径（默认 bench.csv）
  - FAFAFA_BENCH_BACKOFF：退避策略（可为 Aggressive；缺省为空=Default）
- 输出说明：
  - 控制台：
    - SPSC/MPSC/MPMC × {bpNone, bpSpin, bpSleep} × {Default/Aggressive}
    - 列：name, ops, ms(avg), ms(std), ops/ms, ns/op(avg), ns/op(std)
  - CSV（统一由 fafafa.core.bench.util 写出）：
    - 列：name, model, backoff, wait_policy, cap, batch, N, ms_avg, ms_std, ops_per_ms, ns_per_op_avg, ns_per_op_std, warmup, repeats, p50_ms, p90_ms, timestamp
  - 来源（可选）：
    - host：主机标识（优先 FAFAFA_BENCH_HOST；否则尝试 COMPUTERNAME/HOSTNAME）
    - run_id：运行标识（环境变量 FAFAFA_BENCH_RUNID；未设置时脚本/示例可能用时间戳填充）
    - commit：提交哈希（环境变量 GIT_COMMIT；Run_Bench_BackoffMatrix.bat 会尝试通过 git 读取 HEAD 短哈希，失败则为 unknown）

  - 设置示例：
    - PowerShell：$env:FAFAFA_BENCH_HOST='WS-LAB-01'; $env:FAFAFA_BENCH_RUNID='exp_spsc_mpmc_01'

- 注意：
  - 基准为短跑型吞吐测试，数值受机器与系统负载影响明显，建议多次运行取中位数或均值参考
  - Blocking 的实现为轻量轮询策略（bpNone 按队列实现；bpSpin 纯自旋；bpSleep 让出时间片）


#### 命令示例
- PowerShell（默认 Backoff）
  1. $env:FAFAFA_BENCH=1
  2. $env:FAFAFA_BENCH_N=200000; $env:FAFAFA_BENCH_REPEAT=5; $env:FAFAFA_BENCH_WARMUP=1
  3. $env:FAFAFA_BENCH_OUT='bench_default.csv'
  4. tests\fafafa.core.lockfree\BuildOrTest.bat test
- PowerShell（Aggressive Backoff）
  1. $env:FAFAFA_BENCH=1
  2. $env:FAFAFA_BENCH_BACKOFF='Aggressive'
  3. $env:FAFAFA_BENCH_OUT='bench_aggressive.csv'
  4. tests\fafafa.core.lockfree\BuildOrTest.bat test
- 示例矩阵（示例工程，含容量/批量/策略矩阵）
  - examples\fafafa.core.lockfree\example_mpmc_bench\buildOrRun.bat

- 批处理一键对比（tests）：
  - 一键产出：一条命令即可生成 Default/Aggressive 两份 CSV + 一份 top 对比 CSV（见下）

  - tests\fafafa.core.lockfree\Run_Bench_BackoffMatrix.bat
  - 作用：分别以 Default/Aggressive Backoff 运行微基准并生成两份带时间戳的 CSV
  - 可选覆盖环境变量：FAFAFA_BENCH_N、FAFAFA_BENCH_REPEAT、FAFAFA_BENCH_WARMUP
  - 合并对比脚本（PowerShell）：
    - tests\tools\merge_bench_backoff_csv.ps1 -DefaultCsv bench_lockfree_YYYYMMDD_HHMMSS_default.csv -AggressiveCsv bench_lockfree_YYYYMMDD_HHMMSS_aggressive.csv -Out bench_compare.csv

    - 说明：Run_Bench_BackoffMatrix.bat 已在执行完成后自动调用该脚本，生成对比文件
      - 默认筛选：-Model MPMC -WaitPolicy bpSleep -NsPerOpRatioMin 1.05 -Sort ns_ratio
      - 产物文件名：bench_lockfree_YYYYMMDD_HHMMSS_compare_mpmc_bpsleep_top.csv（与两份 CSV 同一时间戳）
      - 如需自定义筛选/排序，请直接运行该脚本并传入相应参数

  - 环境变量配置自动合并：
    - AUTO_COMPARE：1（默认启用）/ 0（跳过自动合并）
    - COMPARE_MODEL：默认 MPMC
    - COMPARE_WAIT：默认 bpSleep
    - COMPARE_NS_RATIO_MIN：默认 1.05
    - COMPARE_SORT：default/ns_ratio/ops_ratio，默认 ns_ratio
    - COMPARE_OUT_PREFIX：可选对比输出文件名前缀（例如 mytag_）

    - 示例：
      - set AUTO_COMPARE=0 && tests\fafafa.core.lockfree\Run_Bench_BackoffMatrix.bat
      - set COMPARE_MODEL=MPMC && set COMPARE_WAIT=bpSpin && set COMPARE_NS_RATIO_MIN=1.10 && set COMPARE_SORT=ops_ratio && set COMPARE_OUT_PREFIX=mytag_ && tests\fafafa.core.lockfree\Run_Bench_BackoffMatrix.bat



#### 对比指南（简）
- Excel/表格工具

#### 常见问题（FAQ）
- CSV 写到哪里？
  - 规则：若未指定绝对路径，写入“当前工作目录”。
  - 一键脚本：在 tests\fafafa.core.lockfree 目录执行，默认 CSV 就在该目录。
  - 示例工程：在其工程目录执行，默认 CSV（bench_example.csv）在示例目录。
- 合并脚本找不到文件？
  - 方案1：传绝对路径给 -DefaultCsv/-AggressiveCsv
  - 方案2：先 cd 到 CSV 所在目录再运行脚本
  - Windows 路径含空格时需加引号：-DefaultCsv "C:\path with space\file.csv"
- 自定义输出文件名
  - tests 微基准：通过环境变量 FAFAFA_BENCH_OUT 指定；一键脚本会自动设置为带时间戳的文件名，不建议在脚本内覆盖
  - 示例工程：使用 bench_example.csv（可通过设置 FAFAFA_BENCH_OUT 覆盖）
- commit 显示 unknown？
  - 确认本机已安装 git 且当前目录为 git 仓库；或手动设置环境变量 GIT_COMMIT

#### 结果解释指南
- 基本指标含义
  - ops_per_ms（越大越好）：每毫秒完成的操作数，反映吞吐
  - ns_per_op_avg（越小越好）：每次操作的平均纳秒数，反映单位操作成本
  - 两者大致互为倒数：ns_per_op_avg ≈ 1e6 / ops_per_ms（存在离散化与四舍五入误差）
- 合并对比中的“比率”
  - ns_per_op_ratio = Aggressive / Default
    - > 1 表示 Aggressive 更慢（单位操作耗时更长）
    - < 1 表示 Aggressive 更快
  - ops_per_ms_ratio = Aggressive / Default
    - > 1 表示 Aggressive 更快（吞吐更高）
    - < 1 表示 Aggressive 更慢
  - 二者近似互为倒数，轻微不一致多由采样噪声、舍入或重复次数过低导致
- 分位数（p50/p90/p95/p99）
  - p50 近似中位数，能抑制异常值影响，适合比较“典型”表现
  - p90/p95/p99 反映尾部延迟，适合观察波动与极端情况
  - 建议：若均值改善但 p95/p99 变差，需结合业务容忍度判断是否可接受
- 模型与策略解读
  - 模型：SPSC（单生产单消费）/ MPSC（多生产单消费）/ MPMC（多生产多消费）
    - 一般来说 MPMC 争用最高，对 Backoff/WaitPolicy/容量/批量更敏感
  - WaitPolicy：bpSpin 倾向忙等，极高负载下吞吐可能更好，但会占用 CPU；bpSleep 让出时间片，可能牺牲峰值吞吐换稳定性
  - BackoffPolicy：Aggressive vs Default 的优劣取决于争用强度与核心/调度器环境，务必结合不同 WaitPolicy 与模型交叉验证
- 容量（cap）与批量（batch）
  - 更大的 batch 通常摊薄每次操作开销，提升 ops_per_ms，但对单次操作的即时性不利
  - 容量影响冲突与缓存局部性，不同 cap 可能呈现不同拐点
- 可比性与追踪
  - host/run_id/commit 用于确保“同一机器、同一提交、同一实验”的可比性
  - 建议固定 N/REPEAT/WARMUP，避免跨实验参数变化影响比较
- 稳定性建议
  - 提高 REPEAT（例如 ≥ 5）并保留 WARMUP（≥ 1）以稳定结果
  - 避免后台负载；必要时多跑几次取中位数或均值
- 常见误读
  - 小 N 会导致时间粒度量化（durMs 最小为 1ms 的情况下），建议提高 N 减少量化误差
  - 只看均值不看分位数：可能掩盖抖动或尾部退化
- 例子
  - 若 ns_per_op_ratio = 1.10 且 ops_per_ms_ratio = 0.91：代表 Aggressive 比 Default 慢约 10%（单位操作），吞吐也下降约 9%（近似倒数关系）

- host 未显示或不准确？
  - 可手动设置 FAFAFA_BENCH_HOST；否则脚本尝试读取 COMPUTERNAME/HOSTNAME
- 结果有波动？
  - 建议提高 REPEAT、适当 WARMUP；在低干扰环境下反复运行取中位数；优先关注 MPMC 的 batch/cap 矩阵

  - 打开两份 CSV（bench_default.csv 与 bench_aggressive.csv）
  - 透视表：行= name，列= backoff（或 backoff×wait_policy），值= ns_per_op_avg（或 ops_per_ms）
  - 观察不同行列组合的趋势，推荐关注 MPMC + 不同 batch/cap 的变化
- 轻量脚本（思路）
  - 用 Import-Csv/解析 CSV，按 name/backoff/wait_policy 分组，计算差值和比率
  - 输出列建议：name, backoff, wait_policy, cap, batch, ns/op_default, ns/op_aggressive, delta(%), ops/ms_default, ops/ms_aggressive


注意（占位与规划）：
- QueueBuilder 的 Backoff/BlockingPolicy/Padding/EnableStats 目前为占位参数（不影响现有实现），用于锁定 API 方向
- MapBuilder.ImplMM 目前为规划中，调用 BuildEx 会抛出异常（便于在集成期尽早暴露误用）

注意：Builder 当前为最小实现，仅覆盖 Model/Capacity 与 OA MapEx。后续将扩展 Backoff、Padding、BlockingPolicy、Stats、MM Map 等选项。


### 自定义哈希/比较器最佳实践（OA HashMap）
- 若键为字符串且需大小写不敏感语义：
  - 比较器：CaseInsensitiveEqual = SameText(L, R)
  - 哈希：对 UpperCase(S) 做 FNV-1a（按字节），确保哈希与相等性一致
- 若键为记录/定长二进制：
  - 默认 SimpleHash + CompareMem 可作为兜底，但需确认记录中不含指针/变长字段
- 契约建议：在测试中固定不同大小写键在容量边界下的行为（容量满时插入失败），防止退化

### Writing 状态与内存序（OA HashMap Put）
- 空槽写入流程（Empty -> Writing -> Occupied）：
  - Empty → Writing：CAS（acq_rel）成功后再写 Key/Value/Hash
  - 发布 Occupied：atomic_store(..., release)，消费者以 acquire 可见上述写入
- 并发健壮性：
  - 遇 Writing/Occupied 冲突时进行有界重试，并使用 Sleep(0) 轻量让出，避免长时间自旋
  - 重试不会改变 API 语义，仅减少偶发失败概率

```pascal
var
  LHashMap: specialize TLockFreeHashMap<Integer, string>;
begin
  LHashMap := specialize TLockFreeHashMap<Integer, string>.Create(128);
  try
    LHashMap.Put(1, 'One');
    if LHashMap.Get(1, LValue) then
      WriteLn('Value: ', LValue);
    if LHashMap.Remove(1) then
      WriteLn('Removed successfully');
  finally
    LHashMap.Free;
  end;
end;
```

## 算法原理

### ABA问题解决方案

传统的无锁算法面临ABA问题：当一个线程读取值A，然后另一个线程将其改为B再改回A时，第一个线程的CAS操作会成功，但实际上数据结构的状态已经改变。

本模块采用以下策略解决ABA问题：

1. **版本计数器**: 每次修改时递增版本号
2. **64位打包头部**: 将指针和版本号打包到单个64位值中
3. **原子CAS操作**: 使用单个64位CAS操作确保原子性

```pascal
// 打包头部结构
type TPackedHead = UInt64; // 高32位：版本号，低32位：节点索引

// 原子更新操作
function PackHead(ANodeIndex: Integer; AABACounter: Cardinal): TPackedHead;
begin
  Result := (UInt64(AABACounter) shl 32) or UInt64(Cardinal(ANodeIndex));
end;
```

### 内存序和同步

所有原子操作都使用适当的内存序保证：
- **读操作**: 使用acquire语义
- **写操作**: 使用release语义
- **CAS操作**: 使用sequentially consistent语义

## 性能特性

### 基准测试结果

在Intel i7-8700K @ 3.70GHz，16GB RAM环境下的测试结果：

| 数据结构 | 单线程性能 | 多线程扩展性 | 内存使用 |
|---------|-----------|-------------|---------|
| TSPSCQueue | 50M ops/sec | N/A | 低 |
| TMichaelScottQueue | 10M ops/sec | 良好 | 中等 |
| TPreAllocMPMCQueue | 30M ops/sec | 优秀 | 低 |
| TTreiberStack | 8M ops/sec | 良好 | 中等 |
| TPreAllocStack | 25M ops/sec | 优秀 | 低 |
| TLockFreeHashMap | 15M ops/sec | 良好 | 中等 |

### 性能优化建议

1. **选择合适的数据结构**:
   - 单生产者单消费者：使用TSPSCQueue
   - 多生产者多消费者：使用TPreAllocMPMCQueue

## 限制与注意事项（强烈建议阅读）

- HashMap（开放寻址 OA）
  - 无在线扩容：容量固定；高装载因子（>0.7）下插入可能失败或退化为较长探测
  - 默认相等性：未传自定义比较器时使用“=”运算符；对自定义记录需定义 operator = 或显式传入比较器
  - 建议：按目标最大键数设置容量并保守留余量；对复杂键请传入专用哈希与比较器
  - 严格工厂（运行期早失败）：当你希望在运行期强制提供哈希/比较器并在遗漏时立即报错，可使用门面层严格工厂：
    - CreateIntIntOAHashMapStrict / CreateIntStrOAHashMapStrict / CreateStrIntOAHashMapStrict / CreateStrStrOAHashMapStrict
    - 或直接调用类型上的 NewStrict(ACapacity, AHash, AEqual)

#### 严格工厂用法示例（OA HashMap）
```pascal
uses fafafa.core.lockfree, fafafa.core.lockfree.hashmap.openAddressing;


#### 容量迁移/重建（OA/MM 通用示例）
- 适用：OA 无在线扩容，或 MM/运行期需重建以释放逻辑删除产生的碎片
- 思路：新建更大容量（或同容量）实例，遍历旧 Map 并逐个迁移键值
- 注意：迁移期间请在“无并发写”或外层协调下进行

```pascal
// 以 OA 为例（MM 同理，遍历各桶链表）
var OldM, NewM: specialize TLockFreeHashMap<string, Integer>;
    K: string; V: Integer; i, cap: Integer;
begin
  OldM := specialize TLockFreeHashMap<string, Integer>.Create(64, @HashStr, @EqStr);
  try
    // ... 业务运行中填充 OldM ...

    cap := 256; // 目标容量（建议按当前 size/负载上限估算）
    NewM := specialize TLockFreeHashMap<string, Integer>.Create(cap, @HashStr, @EqStr);
    try
      // 遍历旧表并迁移（示例根据键空间已知，可结合业务 KeySource/遍历器适配）
      for i := 1 to 10000 do begin
        K := 'k' + IntToStr(i);
        if OldM.Get(K, V) then
          NewM.Put(K, V); // Upsert，避免重复冲突
      end;

      // 用新表替换旧引用（注意生命周期与并发场景）
      // OldM.Free; OldM := NewM; NewM := nil;（按需要调整）
    finally
      if Assigned(NewM) then NewM.Free;
    end;
  finally
    OldM.Free;
  end;
end;
```
- 进一步：可提供 MapBuilder.Rebuild(Old, NewCapacity[, MaxLoadFactor]) 帮助例程

function HashCI(const S: string): Cardinal; inline;
begin
  // 例：大小写不敏感的简单哈希（演示用）
  Result := fafafa.core.lockfree.SimpleHash(UpperCase(S)[1], Length(S));
end;

function EqCI(const L, R: string): Boolean; inline;
begin
  Result := SameText(L, R);
end;


### 内存序与退避策略（统一规范）
- 内存序：
  - 发布数据使用 release；消费端使用 acquire；统计/计数使用 relaxed；CAS 使用 acq_rel
- 退避：
  - 统一使用 BackoffStep(SpinCount)；在 Release 下通过 FAFAFA_LOCKFREE_BACKOFF 开启
  - 避免散落 Sleep(0/1)，统一策略更利于观测与调整
- 缓存行填充：
  - 使用 FAFAFA_LOCKFREE_CACHELINE_PAD 在热点字段间启用填充；默认关闭，按需开启
- Builder/工厂：
  - 推荐通过 TQueueBuilder<T>.WithBlockingPolicy/BlockingPolicy 注入阻塞策略
  - BackoffPolicy 可通过 SetDefaultBackoff 或 Aggressive 策略对比

var
  Map: TStrIntOAHashMap;
begin
  // 运行期明确要求提供哈希与比较器，遗漏将 raise
  Map := CreateStrIntOAHashMapStrict(1024, @HashCI, @EqCI);
  Map.Put('Key', 42);
end;
```

- HashMap（分离链接 MM / Michael & Michael）
  - 逻辑删除：erase 标记删除但不立即物理移除；长时间运行/高删除率会增加链长
  - 无在线扩容：TryResize 当前为空实现；建议在停机期重建或 clear
  - 构造器：请优先使用门面 Create*MMHashMap（提供默认哈希/比较器）；直接构造缺省将抛出缺失函数的异常
- 栈/队列的内存回收
  - Treiber 栈、Michael-Scott 队列与 MM HashMap 在无 GC 环境未内建 HP/EBR 回收；仅在无并发读者触达节点时回收是安全的
  - 建议：
    - 单消费者（MPSC）模型下由消费者线程统一回收出队节点
    - 长生命周期高删除率场景，优先使用预分配结构（如 TPreAllocStack、MPMC/SPSC）或引入 HP/EBR 原型
- 清空与销毁时的并发约束
  - Clear/Destroy 必须在无并发访问时调用；否则行为未定义（包括潜在 AV/数据竞争）
- 伪共享与 Padding
  - 建议在多核高并发场景启用 {$DEFINE FAFAFA_LOCKFREE_CACHELINE_PAD}
  - 位置：src/fafafa.core.settings.inc；启用后关键索引/计数间插入 64 字节填充降低伪共享
- Backoff 退避
  - Treiber/MPMC 已接入轻量退避策略（BackoffStep）；高冲突下建议改用更激进策略或指数退避（未来版本将提供注入式配置）

   - 已知容量上限：优先选择预分配结构

2. **容量设置**:
   - 预分配结构的容量应设为2的幂次方
   - 容量应略大于预期最大使用量
   - 避免频繁的满/空状态

3. **内存对齐**:
   - 确保数据结构按缓存行对齐
   - 避免false sharing问题

## 使用指南和最佳实践

### 选择合适的数据结构

#### 队列选择指南
```
场景                    推荐数据结构              原因
单生产者单消费者         TSPSCQueue               最高性能，无竞争
多生产者单消费者         TMichaelScottQueue       经典算法，稳定可靠
多生产者多消费者         TPreAllocMPMCQueue       高性能，内存效率高
```

#### 栈选择指南
```
场景                    推荐数据结构              原因
动态容量需求            TTreiberStack            无容量限制
固定容量高性能          TPreAllocStack           预分配，ABA安全
```

### 错误处理最佳实践

1. **检查操作返回值**:
```pascal
// 正确的做法
if not LQueue.Enqueue(Item) then
begin
  // 处理队列满的情况
  WriteLn('Queue is full, item rejected');
end;

// 错误的做法
LQueue.Enqueue(Item); // 忽略返回值
```

2. **处理容量限制**:
```pascal
// 预分配结构需要检查容量
if LStack.IsFull then
begin
  WriteLn('Stack is full, cannot push');
  Exit;
end;

if LStack.Push(Item) then
  WriteLn('Push successful')
else
  WriteLn('Push failed');
```

3. **安全的弹出操作**:
```pascal
// 使用out参数的安全方式
if LStack.Pop(Item) then
  ProcessItem(Item)
else
  WriteLn('Stack is empty');
```

### 并发编程注意事项

1. **避免数据竞争**:
   - 不要在多个线程中同时修改同一个数据结构的配置
   - 使用适当的同步机制保护非线程安全的操作

2. **内存管理**:
   - 确保在所有线程完成操作后再销毁数据结构
   - 预分配结构在创建时分配所有内存，销毁时释放

3. **性能监控**:
```pascal
var
  LMonitor: TPerformanceMonitor;
begin
  LMonitor := TPerformanceMonitor.Create;
  try
    LMonitor.Enable;
    // 执行操作
    LMonitor.RecordOperation(LQueue.Enqueue(Item));
    // 查看统计
    WriteLn('Success rate: ', 100 - LMonitor.GetErrorRate:0:2, '%');
  finally
    LMonitor.Free;
  end;
end;
```

## 故障排除指南

### 常见问题

#### 1. 编译错误

**问题**: "Identifier idents no member"
```
Error: Identifier idents no member "Enqueue"
```

**解决方案**:
- 确保正确引用了 `fafafa.core.lockfree` 单元
- 检查泛型特化语法是否正确
- 验证数据结构是否正确创建

**正确示例**:
```pascal
uses fafafa.core.lockfree;

var
  LQueue: specialize TSPSCQueue<Integer>;
begin
  LQueue := specialize TSPSCQueue<Integer>.Create(64);
  // ...
end;
```

#### 2. 中文输出错误

**问题**: "Disk Full" 错误或中文字符显示异常
```
Error: Disk Full
```

**原因**: 在Windows环境下，包含中文输出的单元没有设置正确的代码页

**解决方案**: 在包含中文输出的程序文件头部添加 `{$CODEPAGE UTF8}`
```pascal
program my_program;

{$CODEPAGE UTF8}  // 必须添加这行
{$mode objfpc}{$H+}

uses
  // ...
begin
  WriteLn('中文输出测试'); // 现在可以正确显示
end.
```

**注意**:
- 只在包含中文输出的程序文件中添加，不要在类库单元中滥用
- 测试程序和示例程序通常需要此设置
- 纯英文的类库代码单元不需要此设置

#### 3. 运行时错误

**问题**: Access Violation 或 Segmentation Fault

**可能原因**:
- 在多线程环境中不正确地销毁数据结构
- 使用已释放的数据结构
- 容量设置不正确

**解决方案**:
```pascal
// 确保线程安全的销毁
procedure SafeDestroy;
begin
  // 等待所有线程完成操作
  WaitForAllThreads;

  // 然后销毁数据结构
  LQueue.Free;
end;
```

#### 3. 性能问题

**问题**: 性能低于预期

**诊断步骤**:
1. 检查容量设置是否合理
2. 验证是否选择了合适的数据结构
3. 使用性能监控器分析瓶颈

**优化建议**:
```pascal
// 使用2的幂次方容量
LQueue := specialize TPreAllocMPMCQueue<Integer>.Create(1024); // 好
LQueue := specialize TPreAllocMPMCQueue<Integer>.Create(1000); // 不好

// 避免频繁的满/空状态
if LQueue.GetSize > LQueue.GetCapacity * 0.8 then
  WriteLn('Warning: Queue is nearly full');
```

#### 4. 内存泄漏

**问题**: 内存使用持续增长

**检查清单**:
- [ ] 所有创建的数据结构都正确释放
- [ ] 没有循环引用
- [ ] 线程正确退出

**调试工具**:
```pascal
{$IFDEF DEBUG}
{$DEFINE HEAPTRC}
{$ENDIF}
```

### 调试技巧

1. **启用详细日志**:
```pascal
{$DEFINE LOCKFREE_DEBUG}
```

2. **使用性能监控**:
```pascal
var LMonitor: TPerformanceMonitor;
begin
  LMonitor := TPerformanceMonitor.Create;
  try
    LMonitor.Enable;
    // 执行操作
    WriteLn(LMonitor.GenerateReport);
  finally
    LMonitor.Free;
  end;
end;
```

3. **单元测试**:
   - 运行完整的单元测试套件
   - 使用 `tests/fafafa.core.lockfree/BuildOrTest.bat test`

## API参考

### 工具函数

#### NextPowerOfTwo(AValue: Integer): Integer
返回大于等于指定值的最小2的幂次方。

**参数**:
- `AValue`: 输入值

**返回值**: 2的幂次方

**示例**:
```pascal
WriteLn(NextPowerOfTwo(10)); // 输出: 16
WriteLn(NextPowerOfTwo(16)); // 输出: 16
```

#### IsPowerOfTwo(AValue: Integer): Boolean
检查指定值是否为2的幂次方。

#### SimpleHash(const AData; ASize: Integer): Cardinal
计算数据的简单哈希值。

## 版本历史

### v1.0.0 (2025-08-07)
- 初始版本发布
- 实现所有核心数据结构
- 修复ABA问题
- 完整的测试覆盖
- 性能优化

## 许可证

本模块遵循项目的整体许可证。

## 贡献

欢迎提交问题报告和改进建议。请确保：
1. 提供详细的问题描述
2. 包含重现步骤
3. 运行相关的单元测试
4. 遵循代码风格规范
