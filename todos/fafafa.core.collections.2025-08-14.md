# fafafa.core.collections 开发计划日志（2025-08-14）

## 背景
- 目标：稳定门面工厂 API，完成最小示例与测试一致性检查；排查 ForwardList 相关 heaptrc 输出。

## 今日计划
- [x] 运行门面级集合测试 `tests/fafafa.core.collections/BuildOrTest.bat test`，记录输出
- [x] 基线盘点：门面与工厂函数签名、条件编译宏、docs 现状
- [ ] 归因 heaptrc 泄漏轨迹（ForwardList 创建/释放路径），输出结论与修复建议
- [ ] 最小门面示例：examples/fafafa.core.collections/example_facade_min
- [ ] 文档补充：在 docs/fafafa.core.collections.md 增加示例与测试入口说明

## 技术决策
- 工厂返回接口类型，保持实现可替换性；优先支持 allocator/growthStrategy 注入
- 参考竞品：
  - Rust Vec/VecDeque：TryReserve/ReserveExact/ShrinkTo 语义与增长策略
  - Go slices：capacity/append 语义拆分
  - Java Collections/Deque：接口优先与双端容器能力

## 风险与应对
- heaptrc 输出需要先分类，避免过度修改；优先通过最小可复现程序验证

## 下一步
- 完成 heaptrc 归因及最小修复；提交示例与文档

