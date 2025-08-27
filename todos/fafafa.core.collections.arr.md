# 开发计划日志：fafafa.core.collections.arr

## 今日/本轮计划
- [x] 门面示例：MakeArr<T>（空/array-of）— 将在 docs/fafafa.core.collections.md 增补最小示例
- [ ] 单测补充：Resize/Put/Get/ToArray 基线用例（小数据）
- [x] 文档微调：在 docs/fafafa.core.collections.md 增加 Arr 示例（本轮提交）

## 技术要点
- IArray<T> 接口的 Append/SaveTo/ToArray 语义与管理类型处理
- 工厂重载与 allocator 传递

## 进展记录
- 2025-08-22：完成基线核验（336 用例全绿），准备补最小示例；确认工厂重载签名与实现一致

## 风险与应对
- 大规模 managed 类型元素初始化/Finalize 的成本；暂缓优化，后续基准期评估

