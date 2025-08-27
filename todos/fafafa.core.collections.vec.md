# 开发计划日志：fafafa.core.collections.vec

## 今日/本轮计划
- [ ] 门面示例：MakeVec<T> + ReserveExact/ShrinkTo 最小用法
- [ ] 单测补充：TryReserveExact/Reserve/ReserveExact、Shrink/ShrinkTo 的可用性用例
- [ ] 文档微调：增长策略简表与使用示例

## 技术要点
- 增长策略：Doubling/Factor/PowerOfTwo/GoldenRatio/Exact/AlignedWrapper
- TryReserve/Reserve/ReserveExact 的异常/非异常语义

## 风险与应对
- 不同增长策略在小容量与大容量下曲线差异；测试/基准中可视化

