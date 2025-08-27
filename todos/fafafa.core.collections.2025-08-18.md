# 开发计划日志：fafafa.core.collections（2025-08-20 补充）

## 本轮可执行任务（最小闭环）
- [ ] 文档：在 docs/fafafa.core.collections.md 增加“增长策略速查表 + 最小示例（Vec/VecDeque/Arr）”
- [ ] 示例：为 Vec/VecDeque/Arr 分别补 1 个最小用法片段（门面）
- [ ] 测试：
  - Vec：TryReserve/Reserve/ReserveExact、Shrink/ShrinkTo 基本正负用例
  - VecDeque：Clear→PushFront/Back 批量组合、make_contiguous/AsSlices 最小用例
  - Arr：Resize/Put/Get/ToArray 小数据基线

## 备注
- 保持默认增长策略为 PowerOfTwo；对大对象/碎片敏感场景推荐 Factor/GoldenRatio/Fixed/Exact/AlignedWrapper

# fafafa.core.collections 开发计划日志（2025-08-18）

## 今日目标
- 修复 ForwardList 编译问题，确保门面级测试可构建、可运行。
- 记录并初步分类 heaptrc 输出（可能为时序打印而非稳定泄漏）。

## 当日进展
- [x] 修复 `TForwardList.Sort` 中临时变量类型错误（将 `integer`/`var L := FHead` 改为 `L: PSingleNode`）。
- [x] 运行 `tests/fafafa.core.collections/BuildOrTest.bat test`，构建成功、测试运行完成；观察到 ForwardList 相关 heaptrc Call trace。
- [x] 输出本轮工作总结到 `report/fafafa.core.collections.round-2025-08-18.md`。

## 待办与下一步
1) heaptrc 归因与最小复现
   - [ ] 新建 `plays/fafafa.core.collections.forwardList/` 最小示例，复现 `MakeForwardList -> Create -> Destroy` 序列并在进程末尾采样。
   - [ ] 审计 `TElementManager<T>` 与 `TForwardList<T>` 构造/析构链，确认无循环引用；必要时为测试引入显式 `Finalize` 钩子（仅测试）。
2) 文档与示例
   - [ ] 在 `docs/fafafa.core.collections.md` 增补门面工厂示例与增长策略说明。
   - [ ] 增加 `examples/fafafa.core.collections/example_facade_min`（UTF-8 + 构建脚本）。
3) 进一步测试
   - [ ] 增加 GrowthStrategy 行为测试（PowerOfTwo/Factor/GoldenRatio），覆盖 `Reserve/ReserveExact/Shrink/ShrinkTo` 边界。

## 备注
- 保持接口优先与可替换性；避免在未确认泄漏性质前大改析构路径。

