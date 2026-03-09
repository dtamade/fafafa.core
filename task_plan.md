# SIMD 收口任务计划

## 目标
- 统一后端优先级定义
- 将 dispatch change hook 改为可多订阅
- 减少 RegisterBackend 的重复重选开销
- 将 gate 增加 release/strict 入口
- 清理 SIMD 源码卫生问题与低风险抽取

## 阶段
- [x] 调研受影响符号与初始化顺序
- [x] 先补测试，覆盖 hook/注册/strict gate
- [x] 实现 dispatch 与 cpuinfo 重构
- [x] 实现 gate release/strict 收口
- [x] 清理备份文件与更新文档
- [x] 跑针对性验证与全量 gate
