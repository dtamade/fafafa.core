# fafafa.core.benchmark 开发计划日志

## 本轮计划完成情况
- [x] 停止快手接口自动打印（宏保护，默认关闭）
- [x] 引入全局 Reporter 注入点（默认 nil）
- [x] 初步清理 turbo/smart 等叙述性接口中的 writeln
- [x] 修复构建问题（non-inline var 分支补声明）并通过构建

## 下一步计划（可执行）
- [ ] 将以下函数迁移到 examples/fafafa.core.benchmark（或改为纯函数+外部 Reporter 渲染）：
  - [ ] monitored_benchmark / monitored_benchmark(title,...)
  - [ ] regression_test / continuous_benchmark
  - [x] analyzed_benchmark / predictive_benchmark / adaptive_benchmark / ultimate_benchmark / ai_benchmark （迁移示例已添加）
  - [ ] template_benchmark / cross_platform_benchmark
  - [x] file_reporter 示例（写文件）
- [ ] 在 tests 中改用 Reporter 校验输出，去除对库内 writeln 的依赖
- [ ] 补充文档：默认 Reporter 注入、示例迁移用法
- [ ] 与 term 集成后新增 TermReporter
- [x] 增补 ASCII-only Reporter 用法与 examples 运行说明（docs/report 已更新）

## 备注
- Reporter 中的 writeln 属于职责内输出，保留
- 示例与测试中需要中文输出的单元头保持 {$CODEPAGE UTF8}



## 更新（2025-08-18）
- [x] 修复 tests_benchmark 缺失导出的测试过程声明（CSV tabular counters）。
- [ ] 增补 JUnit Reporter 快照最小测试（生成并校验核心字段 time/testcase）。
- [ ] CLI：在 --help 中列出 --baseline/--regress-threshold/--timeout-ms/--overhead-correction。
- [ ] Pause/Resume/Overhead：补齐统计边界用例，覆盖 <1us 超小窗口与单样本校正。


## 在线调研与结论（2025-08-18）
- Criterion.rs：统计驱动、CSV/HTML 报告、预热与测量隔离、黑洞防优化、基线回归检测
- Go testing.B：b.N/b.RunParallel、Pause/Resume、Bytes/Items 速率、子基准
- JMH：fork/iteration/预热分离、黑洞、模式选择

采纳要点：
1) KeepRunning 采用“粗估→指数放大→单步收缩”的稳定收敛算法，目标 MinDurationMs，MaxDurationMs 兜底
2) 预热与测量严格隔离；支持 Pause/Resume 在预热阶段但不计入样本
3) 多线程起跑使用栅栏；线程局部 bytes/items 聚合
4) Reporter 唯一输出通道；库层不直接输出

## 近期可执行任务（追加）
- [ ] 校准稳定性冒烟用例（极短窗口 5ms / 20ms）
- [ ] 预热样本剔除用例（WarmupIterations>0，统计不含预热）
- [ ] 多线程同步最小用例（2/4 线程，SyncThreads=True）
- [ ] JSON/CSV Reporter 置信度/百分位字段快照
