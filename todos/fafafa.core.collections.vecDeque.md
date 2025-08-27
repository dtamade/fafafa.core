# 开发计划日志：fafafa.core.collections.vecDeque

## 今日/本轮计划
- [ ] 门面示例：MakeVecDeque<T> + PushFront/Back + Shrink
- [ ] 单测补充：AsSlices/MakeContiguous 最小用法；环绕+Clear+批量组合用例
- [x] 回归测试：Clear 后 PushBack/PushFront(批量) 行为
- [x] 文档：在 docs/fafafa.core.collections.vecdeque.md 明确 Clear 语义与 Shrink/ShrinkTo 区分（已补充）


## 技术要点
- 环形缓冲地址布局、掩码与对齐；PowerOfTwo 策略默认友好

## 风险与应对
- make contiguous 的重排代价与时机；后续基准评估

