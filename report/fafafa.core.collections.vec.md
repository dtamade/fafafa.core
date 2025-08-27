# 工作总结报告：fafafa.core.collections.vec

## 本轮进度与已完成项
- 修复 TVec 单元 interface/implementation 段落混放导致的致命编译错误（将默认策略懒加载函数移至 implementation）
- 默认增长策略对齐文档：明确为 TFactorGrowStrategy(1.5)，并在示例中改用 V.Push/V.Insert 及 ShrinkToFit
- 新增滞回相关单测：阈值边界（等于 max(2*Count,128) 不收缩）、大于阈值（收缩至 Count）、小 Count 走最小阈值128 分支
- 测试脚本修正：统一输出路径至仓库 bin/，并强制 Debug 构建
- 内存泄漏治理：
  - TVec.Destroy/SetGrowStrategy/SetGrowStrategyI 仅释放“非共享实例”的策略对象
  - TInterfaceGrowthStrategyAdapter.Destroy 将接口引用置空，避免潜在引用环
  - vec 单元 finalization 释放 _VecDefaultFactorStrategy 懒加载单例

## 遇到的问题与解决方案
- 问题：GetVecDefaultFactorStrategy 误放 interface 段，触发 “IMPLEMENTATION expected”
  - 解决：移动到 implementation，并保留懒加载单例
- 文档与实现不一致（ShrinkToFitExact/默认策略/分配器名）
  - 解决：修正文档为 Shrink/ShrinkToFit，默认策略为 1.5x，分配器示例改 GetRtlAllocator
- 运行时 heaptrc 显示 7 块未释放内存（增长策略接口相关）
  - 解决：
    - 在 TVec.Destroy/SetGrowStrategy/SetGrowStrategyI 中释放非共享策略实例
    - 在 TInterfaceGrowthStrategyAdapter.Destroy 中清空接口引用
    - 在 vec 单元 finalization 中释放默认因子策略单例

## 后续计划
- 复跑全量 TVec 单测以确认 heaptrc 是否完全归零（如仍有残留，再做最小补丁）
- 审视 GrowStrategy 接口视图路径的覆盖率，补充必要用例
- 与 VecDeque/Arr 的策略生命周期管理对齐并补用例

## 备注
- 与 VecDeque/ForwardList 的接口一致性保持，便于统一算法与迭代器



## 2025-08-20 本轮补充
- 在线调研：Rust Vec、Go slice、Java ArrayList/Deque 增长策略
- 统一决策：TVec 默认策略采用 Factor(1.5)；VecDeque 保持 2 的幂
- 文档与示例同步完成（TFactor 说明、无 ShrinkToFitExact）
