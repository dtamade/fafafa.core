# fafafa.core.lockfree 工作总结报告（本轮）

## 进度综述
- 完成仓库现状梳理：src/ 中已包含完整的 lock-free 套件（SPSC、MPSC、MPMC、Treiber/PreAlloc Stack、HashMap、Deque、PriorityQueue、RingBuffer、Stats/Perf/Util 等）。
- 代码风格与组织：遵循 fafafa.core.* 命名、单元化、可选宏由 src/fafafa.core.settings.inc 统一控制；tests/ 下已有完整的构建脚本与基准/压力测试工程。
- 实现抽查：TPreAllocMPMCQueue 使用 Vyukov 序列号环与 64 位原子（acquire/release + 可选退避 + 可选 cacheline padding），与文档一致。
- 文档现状：docs/ 下已有 lockfree 系列文档（最佳实践、性能报告、接口草案、内存序说明等）。

## 已完成项（本轮）
1. 仓库结构/实现/测试快速审计，确认接口与实现的对齐度。
2. 识别并记录关键工程问题与后续改进方向（见下）。
3. 按规范建立本模块报告与 todos 清单文件，纳入可执行计划管理。

## 发现的问题与建议方案
- 配置重复：同时存在 src/fafafa.core.settings.inc 与 release/src/fafafa.core.settings.inc。
  - 方案：单一真源（仅保留 src/），发布时复制镜像（与 docs/fafafa.core.settings.plan.md 一致）。
- HashMap 默认策略兜底：Create 传入 nil Hash/Comparer 的安全兜底缺失。
  - 方案：为开放寻址 HashMap 增加 SimpleHash/DefaultComparer 兜底；先补契约测试，再小步落地。
- CODEPAGE 使用：个别库单元存在 {$CODEPAGE UTF8}（库单元应避免）。
  - 方案：按“CODEPAGE 清理策略”分批移除（tests/examples 可保留中文输出）。
- 回收策略：Treiber/HashMap 的删除后回收策略（HP/EBR）尚未落地，长生命周期+高删除率存在内存增长风险。
  - 方案：play/ 下原型验证 HP/EBR，契约/压力跑通后再并入 src。
- 性能开关默认关闭：FAFAFA_LOCKFREE_CACHELINE_PAD / FAFAFA_LOCKFREE_BACKOFF 默认关闭。
  - 方案：在 benchmark/stress 工程内启用宏对比，维持默认对用户零侵入。

## MCP 调研（简述）
- 竞品与参考：
  - Rust：crossbeam/deque、tokio mpsc（bounded/unbounded）、atomic/Ordering 语义；
  - Java：JCTools MPSC/MPMC、ConcurrentLinkedQueue、Disruptor 序列号环；
  - Go：runtime chans（非严格无锁）、x/sync/semaphore；
- 关键结论：
  - Bounded MPMC 基本范式与本仓相符（Vyukov 序列号环 + acq/rel）；
  - 可选退避/填充是必要优化点；
  - 接口分层（IQueue/IStack/IMap）+ 工厂/适配器利于演进与替换；
  - 需要在文档与代码中固定“可见性语义”与“能力标注”。

## 下阶段计划（可执行）
1. 契约与接口层
   - 在 tests/fafafa.core.lockfree/contracts 跑通 IQueue/IStack/IMap 契约用例集；
   - 评审并冻结 TE（类型擦除）/GI（泛型接口）双轨签名；
2. 工程整洁性
   - settings.inc 单源化；
   - 扫描并清理库单元中的 CODEPAGE 宏；
3. 功能与安全
   - HashMap 默认 Hash/Comparer 兜底（先测后改）；
   - 在 play/ 验证 HP/EBR 回收原型；
4. 性能与验证
   - 在 benchmark_micro_* 与 Run_Micro_* 中加入“退避/填充”开关对比矩阵，产出 CSV；
   - 固化吞吐/延迟阈值，纳入性能回归脚本。

## 风险与缓解
- 兼容性：接口层引入保持门面与现有类型别名不变，通过适配器接入。
- 行为变更：HashMap 兜底可能改变极端输入下行为，先以契约测试锁定语义。
- 构建环境：清理 CODEPAGE/路径时严格分批，遇回归立即回滚。

## 里程碑与验收
- M1：接口契约全绿 + settings 单源化完成；
- M2：HashMap 兜底合入 + 性能回归不退化；
- M3：HP/EBR 原型评审与合规文档；

— 本报告将随每轮迭代更新。


## 本轮更新（2025-08-16）
- 修复（原子与内存序）
  - 修正 atomic_compare_exchange_strong_tagged_ptr 传参错误（使用 PInt64(@obj.combined)^ 作为 var 形参）。
  - TMichaelScottQueue<T> 与 TTreiberStack<T> 读路径改为 acquire 原子读取，保持 CAS 为 acq_rel，强化弱内存序可见性保障。
- 一致性修复
  - OA HashMap.Remove 统一使用 KeysEqual，尊重自定义比较器。
- 规范清理
  - 移除 src/fafafa.core.lockfree.util.pas 的 {$CODEPAGE UTF8}。
- 回归验证
  - tests/fafafa.core.lockfree/BuildOrTest.bat test：45/0/0，heaptrc 0 泄漏。

## 后续计划
- 继续推进 todos/fafafa.core.lockfree.md 中“契约测试巩固”和“settings.inc 单源化”。
- 评审 OA HashMap 默认兜底策略（SimpleHash/CompareMem）文档化，并在 contracts 中锁定语义。


## settings.inc 单源化检查（不落地变更）
- 发现：release/src/fafafa.core.settings.inc 与 src 版本存在差异（release 含 FAFAFA_THREAD_SAFE 定义，src 未包含）。
- 风险：直接覆盖 release 版本可能改变发布构建行为。
- 方案：保持 src 为单一真源；发布阶段使用 scripts/sync_settings_inc.bat 复制生成，但在本分支不覆盖 release 文件，避免行为变更。
- 建议：在 release/src/fafafa.core.settings.inc 增加“自动生成请勿手改”的文件头（下一轮变更）。


## 本轮追加更新（2025-08-17）
- 测试与回归
  - fpcunit：tests_lockfree → 50/0/0 通过
  - contracts_runner：IQueue/IStack/IMap → 23/0/0 通过
- 缺陷修复
  - 修复 tests/fafafa.core.lockfree/Test_lockfree.pas 中重复 implementation 标记与零散片段导致的编译错误
  - 补全大小写不敏感哈希/比较器（CaseInsensitiveHash/CaseInsensitiveEqual），确保与 OA HashMap 自定义契约一致
- 健壮性增强（OA HashMap）
  - Put 路径加入有界 CAS 重试与 Writing 状态处理，维持 acquire/release 可见性语义
  - 不改变 API/语义，对高并发场景大幅降低偶发失败概率
- 下一步
  - 文档：在 docs/fafafa.core.lockfree.md 中补充“自定义哈希/比较器最佳实践”与“Writing 状态的内存序说明”
  - 性能：在 micro benchmark 中评估重试+让出对尾延迟的影响（预期可忽略）


## 本轮追加更新（2025-08-17 晚）
- 接口与对齐（P0 完成）
  - ILockFreeQueue<T>：新增 TryEnqueue/TryDequeue、EnqueueBlocking/DequeueBlocking(TimeoutMs)、Close/IsClosed、EnqueueMany/DequeueMany、RemainingCapacity（对齐 Rust/Go/Java 语义）
  - ILockFreeStack<T>：新增 TryPeek/Clear
  - ILockFreeMapEx<K,V>：新增 PutIfAbsent/GetOrAdd/Compute 外观（对齐 Java ConcurrentHashMap 与 Rust entry 风格）
- 适配层实现
  - factories：为 SPSC/MPSC/MPMC 适配器实现上述接口（阻塞采用轻量轮询 + Sleep(0)，MPSC 入队直通，保持语义）
  - mapex.adapters：为 OA 适配器实现 PutIfAbsent/GetOrAdd/Compute
- 回归
  - tests/fafafa.core.lockfree/BuildOrTest.bat test：通过（50/0/0），heaptrc 0 泄漏（新接口的直接契约用例暂放 ifaces_factories.testcase.pas 中，未纳入此 lpr）
- 后续
  - 在 ifaces_factories.* 用例中补充新接口契约（已初步添加），后续独立 lpr 归档并纳入 CI


## 本轮追加更新（2025-08-18）
- 测试与回归
  - tests/fafafa.core.lockfree/BuildOrTest.bat test：50/0/0 通过，heaptrc 0 泄漏
  - contracts_runner：新增 OA HashMap Create(nil,nil) 兜底契约用例，24/0/0 通过
- 功能与一致性
  - OA HashMap：保持 Create(容量) 与 Create(容量, Hash, Equal) 双重构造语义；nil Hash/Equal 情况下走 SimpleHash/CompareMem 兜底（已有实现通过 HashKey/KeysEqual 路径体现）
- 文档与后续
  - 将在 docs/fafafa.core.lockfree.md 中补充“默认兜底策略说明”与“与 MM 实现的区别”


## 本轮追加更新（2025-08-18 晚）
- 性能与稳态
  - TTreiberStack.Push/Pop 的固定 Sleep(1) 退避替换为“轻量自适应退避”（自旋计数→Sleep(0) 让出→偶发 Sleep(1) 降噪）。
  - 预期：降低尾延迟、改善冲突密集场景下的吞吐稳定性。
- 风险与回归
  - 不改变对外 API 与可见语义；已本地编译通过（仅小范围代码改动）。
- 后续
  - 抽象 BackoffPolicy 接口，推广到队列/栈等结构，形成统一配置与测试注入点。


## 本轮追加更新（2025-08-19）
- 修复构建错误（泛型前向声明/适配器工厂）
  - mapex.adapters：移除跨单元重复的工厂前向声明，工厂函数统一留在 factories 单元，避免泛型 CRC 失配导致的 “Forward declaration not solved”。
  - factories：调整 TQueueBuilder/TQueuePolicyWrapper 的声明作用域与语法，兼容当前 FPC trunk 的泛型语法限制（record/class 泛型在 interface 节内以 type 块统一声明）。
- 回归验证
  - 执行 tests/fafafa.core.lockfree/BuildOrTest.bat test：50/0/0 通过，heaptrc 0 泄漏。
- 风险与影响
  - 文档中引用 NewOAHashMapExWithComparer/NewMMHashMapExWithComparer 的示例需确认引用 factories 单元（而非 mapex.adapters）；功能未变，仅位置收敛。
- 后续
  - 在 docs/EXAMPLES.md 与 docs/fafafa.core.lockfree.md 中统一示例引用路径；补充“MapEx 工厂集中于 factories”的说明。
