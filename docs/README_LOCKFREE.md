# LockFree Facade Usage

> See also: Collections
> - Collections API 索引：docs/API_collections.md
> - TVec 模块文档：docs/fafafa.core.collections.vec.md
> - 集合系统概览：docs/fafafa.core.collections.md


本目录包含 LockFree 门面与示例的说明。

- 便捷构造 API 列表见: `docs/LOCKFREE_API.md`（由脚本生成）
- 示例工程：`examples/fafafa.core.lockfree/`
  - example_lockfree.lpi / example_lockfree.lpr
  - BuildOrRun.bat / BuildOrRun.sh

  - 新增：example_oa_strict_factories.lpr（OA 严格工厂示例：大小写不敏感字符串键、记录键）

- 新增：MPSC 与 Stack 门面与便捷构造（详见下文和 docs/LOCKFREE_API.md）


## 原子统一与内存序指南（精简）

- 原子实现统一至 `fafafa.core.atomic`，不再依赖 `fafafa.core.sync`
- 常用 API：
  - 指针：`atomic_load` / `atomic_store` / `atomic_exchange` / `atomic_compare_exchange_strong`（Pointer 重载；旧命名 wrappers 见 `fafafa.core.atomic.compat`）
  - 64位整型：`atomic_load_64` / `atomic_store_64` / `atomic_compare_exchange_strong_64` / `atomic_fetch_add_64` / `atomic_fetch_sub_64`
  - 普通整型：`atomic_load` / `atomic_store` / `atomic_fetch_add` / `atomic_fetch_sub`
- 内存序建议：
  - CAS/RMW：`mo_acq_rel`
  - 发布写：`mo_release`
  - 读取观测：`mo_acquire`
  - 统计/非关键：`mo_relaxed`
- 典型路径：
  - Treiber/PreAlloc 栈：CAS 用 `mo_acq_rel`；头部加载 `mo_acquire`；IsEmpty 可 `mo_relaxed`
  - MSQueue：修改 head/tail 的 CAS 用 `mo_acq_rel`；读侧 `mo_acquire`
  - MPMC 队列：槽位序号 `mo_acquire`，推进游标 `mo_acq_rel`，发布写 `mo_release`
  - OA HashMap：Empty→Writing（`mo_acq_rel`）→Occupied（`mo_release`），读 `mo_acquire`；计数 `mo_relaxed`

### 内存屏障适配说明（atomic_thread_fence）

- `fafafa.core.atomic` 中的 `atomic_thread_fence(order)` 会对 `mo_acquire/mo_release/mo_acq_rel/mo_seq_cst` 使用统一的读写屏障。
- 为提升可移植性，模块内部提供 `ReadWriteBarrier` 的后备定义：
  - 若存在 `System.MemoryBarrier`，优先调用
  - 否则若存在 `MemoryBarrier`，调用之
  - 否则退化为空操作（在 x86/x64 等强内存模型上通常可接受）
- 如目标平台为弱内存模型（如部分 ARM），建议在 RTL 或平台层提供合适的 `MemoryBarrier`，以确保严格的 acquire/release 语义。
- `mo_consume` 当前实现视同 `mo_acquire` 处理（与 C++ 社区实践一致）。


## 快速示例

```pascal
uses
  fafafa.core.lockfree;

var
  Q: TIntMPSCQueue; // Michael-Scott (MPSC) int 队列（推荐门面类型别名）
begin
  Q := CreateIntMPSCQueue;
  try
    Q.Enqueue(1);
    Q.Enqueue(2);
  finally
    Q.Free;
  end;
end;
```

### 新增门面概览（MPSC / Stack）

- MPSC（主推命名；实现为 Michael-Scott）：
  - CreateIntMPSCQueue / CreateStrMPSCQueue / CreateInt64MPSCQueue / CreatePtrMPSCQueue / CreateDoubleMPSCQueue
  - 门面类型别名：TIntMPSCQueue / TStringMPSCQueue / ...（MSQueue 为同义别名，已弃用）

- Stack：
  - Treiber：CreateIntTreiberStack / CreateStrTreiberStack / ...
  - 预分配安全栈：CreateIntPreAllocStack(ACapacity) / CreateStrPreAllocStack(ACapacity) / ...

更多清单见 docs/LOCKFREE_API.md


## 门面最佳实践（推荐）

- 推荐优先使用门面别名与 Create… 便捷构造，而不是在使用处直接泛型特化
- 好处：
  - 语义清晰、接口统一，便于 IDE 搜索与替换
  - 避免在 interface 段直接 specialize 带来的语法敏感性
  - 更利于后续统一 API 演进（只需改门面实现）

对照示例：

- 直接特化（不推荐）
  ```pascal
  var
    Q: specialize TSPSCQueue<Integer>;
  begin
    Q := specialize TSPSCQueue<Integer>.Create(1024);
    try
      Q.Enqueue(1);
    finally
      Q.Free;
    end;
  end;
  ```

- 门面别名 + 便捷构造（推荐）
  ```pascal
  var
    Q: TIntegerSPSCQueue;
  begin
    Q := CreateIntSPSCQueue(1024);
    try
      Q.Enqueue(1);
    finally
      Q.Free;
    end;
  end;
  ```


## HashMap 选型指南

- 两种实现：
  - MM（分离链接）：`fafafa.core.lockfree.hashmap`（桶 + 无锁链表，标记指针防 ABA）
  - OA（开放寻址）：`fafafa.core.lockfree.hashmap.openAddressing`（单数组 + 探测序列，更 cache-friendly）

- 选择建议（重要）：
  - 字符串键：优先使用 MM，保证“值相等”语义；当前版本不建议用 OA 处理字符串键，除非显式提供值语义的 Hash/Equal（中期将提供可插拔方案）。
  - 整数/指针键：OA 与 MM 均可。延迟敏感、内存亲和更好→OA；高冲突/稳定语义→MM。

- 负载与容量：
  - OA：容量取 2 的幂，负载因子建议控制在 0.5–0.7；探测链过长时应扩容或重建。
  - MM：关注链表长度分布；冲突上升时增加桶数或采用更强 hash。

- 并发与性能：
  - 高冲突时使用指数退避；优先使用批量 API（如 PutMany/RemoveMany）以减少共享状态争用。
  - 关键字段启用 cacheline padding（宏开关）降低伪共享。

- 生命周期与安全：
  - 删除路径建议配合 Hazard Pointers（HP）或 Epoch‑Based Reclamation（EBR）回收；不要“删除后立即复用地址”以避免 ABA。

- 工厂/门面：
  - TE 工厂默认遵循“安全优先”：string→MM；如需 OA + 自定义 Hash/Equal，请使用专用工厂或等待中期可插拔实现。


- 如何选择：
  - 追求吞吐/低延迟、键值简单、装载因子≤0.7：优先 OA
  - 插入/删除频繁、规模动态、并发争用高：优先 MM

- 门面便捷构造：
  - OA: CreateIntIntOAHashMap / CreateIntStrOAHashMap / CreateStrIntOAHashMap / CreateStrStrOAHashMap
  - MM: CreateIntIntMMHashMap / CreateIntStrMMHashMap / CreateStrIntMMHashMap / CreateStrStrMMHashMap


## CI / 报告自动化

- GitHub Actions: Perf Report (Aggregate Only)
  - 触发方式：手动（workflow_dispatch）与每日定时（UTC 18:00）
  - 功能：只基于已有 CSV 聚合并生成报告，不进行编译与基准测试
  - 产物：report/latest/** 与 bin/stats_default_*.csv（作为 artifact 上传）
  - 参数：
    - alert_delta：阈值百分比（默认 20）
    - alert_metric：avg|median|p95（默认 avg）
- 本地仅聚合脚本：scripts/perf_report_reportonly.bat
  - 环境变量：ALERT_DELTA、ALERT_METRIC
  - 输出：report/时间戳目录 + report/latest 镜像


- 完整矩阵工作流：Perf Bench (Full Matrix)
  - 触发方式：手动（workflow_dispatch）
  - 步骤：使用 Chocolatey 安装 FPC/Lazarus → lazbuild 编译 → 跑全矩阵脚本 → 聚合与生成报告
  - 参数：alert_delta、alert_metric（同上）
  - 注意：首次安装工具链耗时较长；若安装失败可重试或改用国内源


