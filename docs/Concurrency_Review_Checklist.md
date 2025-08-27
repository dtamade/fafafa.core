# 并发/Lock-Free 代码评审清单（Checklist）

面向 FreePascal / fafafa.core.* 模块的简明评审清单。用于 PR 评审、自检与基线回归。

## 1) 架构与 API
- 是否优先面向接口（IQueue/IStack/IMap），具体类走适配/门面？
- 门面（fafafa.core.lockfree）导出是否稳定（别名、便捷构造器不破坏）？
- 是否避免在 interface 段直接 specialize（统一通过别名/门面）？

## 2) 原子与内存序
- 是否统一使用 fafafa.core.atomic 的 atomic_* API（禁止混用 TInterlocked）？
- 读取快路径：memory_order_relaxed；数据交接：release/acquire；CAS/RMW：acq_rel？
- 指针访问是否仅通过 atomic_load_ptr/atomic_store_ptr/CAS？32 位指针原子性是否考虑？

## 3) 数据结构选型与语义
- SPSC：固定容量（2^n），环/序列号；MPSC：Michael-Scott 链式；MPMC：Vyukov 序列号环？
- HashMap：OA vs MM 选型是否合理（文档/注释说明）？
- OA “兜底”策略：未显式 hash/comparer 时 SimpleHash/CompareMem；MM 通过门面默认/显式传参？

## 4) ABA/内存回收
- Treiber/链式结构是否避免“逻辑删除后立即释放”？
- 是否使用预分配+版本计数，或在 play/ 完成 HP/EBR 原型再并入？
- Destroy/析构阶段确保无并发访问？

## 5) 性能与可选开关（默认关闭）
- 伪共享：FAFAFA_LOCKFREE_CACHELINE_PAD 是否可控，关键字段间按需 padding？
- 退避：FAFAFA_LOCKFREE_BACKOFF（EVERY/SLEEP_MS）是否配置合理，避免忙等？
- HashMap 装载因子与容量规划是否合理（≤0.7 优先）？
- 热路径审计：避免隐式分配/大对象拷贝；cache-friendly 访问？

## 6) 跨平台
- UNIX 是否需要 cthreads（如需）？
- Windows 控制台编码/长路径：示例/测试层处理，库单元不污染？
- 64/32 位差异：Pointer/Int64 的原子操作选择与屏障语义是否正确？

## 7) 构建与配置
- 单一真源：仅维护 src/fafafa.core.settings.inc；release/src 通过脚本镜像？
- 工程 SearchPaths（LPI/LPR）是否包含 ../../src 以支持 {$I fafafa.core.settings.inc}？
- src/* 禁止 {$CODEPAGE UTF8}；中文输出仅限 tests/examples？

## 8) 测试（高效不过度）
- 契约：tests/fafafa.core.lockfree/contracts（IQueue/IStack/IMap）全绿？
- 功能/压力：tests/fafafa.core.lockfree/*（SPSC/MPSC/MPMC/Stack/HashMap）通过？
- 命名约定：TTestCase_类型名；Test_函数名/重载；全局函数在 TTestCase_Global？
- 异常断言：包含关键词（中/英）即可，避免强绑定完整消息？

## 9) 性能回归
- 使用 Run_Micro_* 批处理生成 CSV，覆盖 PAD/Backoff 开关矩阵？
- 固化吞吐/延迟阈值，不退化为基本线（文档/脚本记录）？

## 10) 文档与可回滚
- report/ 与 todos/ 是否更新（进度、问题、方案、后续）？
- docs/fafafa.core.lockfree.md 是否同步语义/内存序说明？
- 变更是否小步、可回滚（遇失败立即回退到全绿点）？

---

快速过线清单（勾选项）
- [ ] 原子 API/内存序规范一致
- [ ] 无隐式分配/ABA 风险已处理
- [ ] 开关默认关闭；性能矩阵已有数据或不退化
- [ ] SearchPaths 与 settings 单源一致
- [ ] 库单元无 CODEPAGE；tests/examples 中文输出正常
- [ ] 契约/功能/压力测试全绿；异常断言稳健
- [ ] 文档与报告已更新，可回滚

