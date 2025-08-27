# 工作总结报告（本轮）：fafafa.core.collections — 2025-08-20

## 在线调研与竞品对比（Vec / VecDeque / 动态数组增长）
- Rust
  - Vec：几何扩容，保证摊销 O(1)。常见策略为按需至少翻倍或接近翻倍；支持 reserve/try_reserve/shrink_to_fit 等 API。
  - VecDeque：环形缓冲区实现，容量通常为 2 的幂，head/tail 指针环绕；提供 make_contiguous 线性化以便切片/批量操作。
- Go
  - slice：小容量阶段采用近似 2× 扩容；容量超过阈值（历史上约 1024）后采用 ~1.25× 渐进增长，兼顾碎片与复制成本。
- Java
  - ArrayList：1.5× 增长（new = old + old>>1）。
  - ArrayDeque：容量保持 2 的幂，位掩码加速取模与环绕。

对我们意味着：
- 默认策略“2 的幂”对 CPU 友好（位运算/预取/VecDeque 环绕），与哈希类结构一致；
- 面向大对象或低碎片诉求，可替换为 Factor/GoldenRatio/Fixed/Exact 等策略；
- 需要提供“精确扩容/收缩”与“策略扩容”的双轨 API，以覆盖不同性能/内存目标。

## 代码库现状与契合度
- 已有接口/实现：
  - IArray/IVec/IDeque/IStack 等接口完备；TVec、TVecDeque、TArr 与丰富算法 API 已存在。
  - 增长策略体系完整：TDoubling/TFactor/TPowerOfTwo/TGoldenRatio/TFixed/TCustom/AlignedWrapper/Exact（通过 ResizeExact/ReserveExact 类能力）。
- 测试与文档：
  - tests/ 下已具备 vec/vecdeque/arr 各自的 FPCUnit 工程与大量用例；
  - docs/ 下存在模块文档与指南（TVecDeque_Guide、README_VecDeque、fafafa.core.collections.*）。
- 结论：当前设计与主流语言模型高度契合，无需大改；本轮聚焦小步收敛：文档对齐、接口语义核对、用例补强与最小示例。

## 本轮完成
- 梳理与核对：对齐 src/tests/docs 三方现状，确认 IVec/TVec、TVecDeque、Arr 的接口外观与增长策略已符合竞品实践。
- 建立本轮记录：新增本文件，准备同步 todos/ 与各子模块报告的“本轮更新”。

## 遇到的问题与处理
- 线上检索接口暂不可用（无搜索结果），改以既有知识与仓库内文档/测试交叉佐证。
- 发现已有测试覆盖广泛，不宜在当前周期大改；决定先微调文档与补少量门面示例/用例以闭环。

## 下一步计划（可执行最小集）
1) 文档微调
   - 在 docs/fafafa.core.collections.md 增加“增长策略对照速查”与 TVec/TVecDeque/Arr 最小示例。
2) 门面/示例
   - Vec：MakeVec<T> + ReserveExact/ShrinkTo 示例；
   - VecDeque：MakeVecDeque<T> + PushFront/Back + Shrink + make_contiguous 示例；
   - Arr：MakeArr<T>（空/array-of）示例。
3) 测试补强（单元）
   - Vec：TryReserve/Reserve/ReserveExact、Shrink/ShrinkTo 的正负用例；
   - VecDeque：Clear→PushFront/Back 批量组合、AsSlices/make_contiguous 最小用例；
   - Arr：Resize/Put/Get/ToArray 基线用例（小数据）。

## 建议
- 保持默认增长策略为“2 的幂”（TPowerOfTwoGrowStrategy），在 API 文档中明确其优势与适用场景；
- 避免大规模接口重构，将精力用于示例/文档与关键行为测试的补强；
- 后续单独开基准轮次再评估不同策略曲线（小容量/大容量分段）。

