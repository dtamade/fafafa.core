# 非轮询 Select 验证计划（fafafa.core.thread）

## 目标
- 在不破坏主线稳定性的前提下，引入基于 IFuture.OnComplete 的非轮询 Select，实现回调聚合，降低 CPU 忙等
- 跨平台验证（Windows/Linux），观察收益与稳定性，必要时回退

## 实施策略
1) 默认行为保持稳定
- 门面 Select 默认“轻量轮询 + 短 WaitFor”，跨平台最稳
- 通过宏 FAFAFA_THREAD_SELECT_NONPOLLING 切换到回调聚合实现

2) CI 并行验证
- 工作流：.github/workflows/thread-select-nonpolling.yml
  - Windows/Linux 并行作业，开启 -dFAFAFA_THREAD_SELECT_NONPOLLING
  - 运行 fafafa.core.thread 全量测试
  - 产出 JUnit 报告（tests.junit.xml）

3) 手动基准与趋势
- 工作流：.github/workflows/thread-select-bench.yml（workflow_dispatch）
  - 输入 iter（默认 200），分别跑 Polling 与 NonPolling
  - 产出 bench_windows*.txt / bench_linux*.txt
  - 生成 bench_summary_windows.md / bench_summary_linux.md
  - 文件带时间戳（yyyyMMdd-HHmmss），便于长期收集

## 验收标准
- 正确性：非轮询作业连跑 ≥10 次，两平台均 0 失败；与默认路径一致的语义
- 性能：在至少一平台上，NonPolling avg 明显优于 Polling（建议 ≥10%）；另一个平台不劣化 >10%
- 资源：无明显 CPU 飙升/泄漏；内存泄漏报告为 0

## 回退策略
- 非轮询实现以宏控制，默认不启用
- 若出现平台兼容问题或收益不足，保持现状，不切换默认

## 附：操作指引
- 触发非轮询验证：Actions → Thread Select (Non-Polling, Macro)
- 触发基准测试：Actions → Thread Select Bench (Manual) → iter=200（可调）
- 文档解读：docs/fafafa.core.thread.md → Select（首个完成）/ 基准测试与结果解读

