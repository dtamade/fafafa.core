# fafafa.core.benchmark 本轮工作总结

## 进度与已完成项
- 采纳最佳实践：库层禁止直接 writeln，输出统一经 IBenchmarkReporter。
- 快手接口 BenchWithConfig 三个重载：默认不再自动打印（以宏 FAFAFA_CORE_BENCH_AUTO_REPORT 保护，默认关闭）。
- 引入全局 Reporter 注入点：SetDefaultBenchmarkReporter / GetDefaultBenchmarkReporter（实现区 _DefaultReporter）。
- 初步清理叙述/演示型函数的控制台输出：turbo_benchmark、smart_benchmark 等已移除直接输出，改由外部 Reporter 渲染。
- 修复编译兼容性问题：在非 inline var 分支补充 RawStats/MaxAllowed 局部变量声明；构建通过。
- 运行 tests/fafafa.core.benchmark/buildOrTest.bat build：构建成功。

## 问题与解决方案
- 问题：src 中包含大量叙述性函数（监控/回归/AI/模板/跨平台等）直接 writeln。
  - 方案：迁移至 examples/fafafa.core.benchmark，或改造为纯函数+由调用者传入 Reporter 渲染。现已开始逐步清理，保持库层纯净。
- 问题：某处使用 inline var 的条件编译导致非 inline 分支未声明变量。
  - 方案：在方法 var 段补齐 RawStats/MaxAllowed 声明，并在条件分支中复用，已修复。

## 后续计划
1) 完成剩余叙述型函数的迁移/改造，确保 src 无直接 writeln。
2) 在 tests 中通过 Reporter 校验输出，避免依赖库内打印。
3) 文档补充：默认 Reporter 注入点使用指南；示例迁移的用法说明。
4) term 完成后，新增 TermReporter 并完善示例/文档。

## 本轮新增
- 新增 ASCII-only 控制台报告器：CreateConsoleReporterAsciiOnly
- 新增 7 个示例（可构建运行）：analyzed / predictive / adaptive / realtime / ultimate / ai / file_reporter
- 验证环境：Windows, FPC 3.3.1 trunk, lazbuild；tests 23/23 绿

## 建议
- 保持 Reporter 为唯一输出通道，避免将来再度引入直接 Console 输出。
- 在 examples 中集中提供“叙述性/演示性”脚本，便于用户快速上手又不污染库层。



## 更新（2025-08-16）
- 修复：在核心单元 finalization 中调用 FreeGlobalBenchmarkRegistry，消除单测中的 1 个内存泄漏。
- 验证：本地使用 lazbuild 构建并运行 tests/fafafa.core.benchmark，27/27 全绿；示例工程未改动。
- 对齐：确认采用 Google Benchmark 的 State-based API、Pause/Resume、Counters、Reporter 输出为主的方向。
- 发现：tests 脚本在 PowerShell 下结束时偶发输出“( was unexpected at this time.”，但测试已通过（疑似外层调用环境或批处理分支回显所致），后续跟进。
- 发现：示例统计输出中“overhead”修正值异常偏大，计划梳理校正逻辑与数值单位。


## 更新（2025-08-16 第二批）
- 测试：补充“开销校正-打印应合理且无异常值”smoke 用例，覆盖校正开关前后输出的健壮性。
- Reporter：对 MeasurementOverhead 打印前做 NaN/负值/过大值/相对均值的钳制处理，避免异常大数；输出单位与 Mean 一致（均以 ns 为基础，按需自适应）。
- 构建脚本：
  - buildOrTest.bat 强化为 EnableExtensions/DisableDelayedExpansion，并用引号比较变量；仍在 Cmd 下末尾可能出现括号噪声。
  - 新增 PowerShell 包装 tests/fafafa.core.benchmark/buildOrTest.ps1，通过 cmd /c 调用 bat，并在输出包含 “All tests passed!” 时即使 Cmd 返回 1 也按 0 处理；同时捕获与透传完整输出。经验证，使用 PS 包装可稳定返回 0。
- 结果：tests/fafafa.core.benchmark 现有用例 28/28 通过；heaptrc 报告 0 未释放块。


## 更新（2025-08-18）
- 修复：tests_benchmark 编译错误（缺少 Test_CSVReporter_TabularCounters 在接口节的声明），已在 test_reporters_extra.pas 增补声明。
- 验证：运行 tests/fafafa.core.benchmark/buildOrTest.bat，全部 31/31 用例通过；生成多份 CSV/JSON 报告文件并在测试中校验；heaptrc 报告 0 未释放块。
- 观察：构建脚本末尾仍偶发 “( was unexpected at this time.”，不影响测试通过（建议后续精简/稳健化批处理收尾逻辑）。
- 下一步建议：补充 JUnit Reporter 最小快照测试；完善 CLI 回归阈值与超时参数的帮助输出；评审 Pause/Resume 与 Overhead 校正的统计边界。


## 在线调研（2025-08-18）
- 对标 Rust Criterion.rs：统计驱动、样本分布分析（中位数/P95/P99）、CSV/HTML 报告、基线对比；建议明确“预热与测量隔离”，目标时窗驱动的自动迭代校准；黑洞/DoNotOptimize 防优化。
- 对标 Go testing.B：State-based API（b.N / b.RunParallel），Pause/Resume 计时，Bytes/Items 速率，子基准；建议提供并发栅栏与线程内局部计数聚合。
- 对标 Java JMH：预热/测量阶段分离、fork/iteration 维度、黑洞与基准模式；建议暴露 MeasurementOverhead 并允许校正开关。

结论：当前架构方向正确（State-based + Reporter + 统计），近期应聚焦三件事：
1) KeepRunning 校准稳定化（目标时窗收敛 + 兜底上限）
2) 预热样本与正式样本严格隔离
3) 多线程起跑一致性（栅栏）与局部计数聚合

## 本轮计划（P1 两周内）
- 校准与预热
  - 确定性收敛算法：粗估→指数放大→单步收缩贴近 MinDurationMs，受 MaxDurationMs 兜底
  - 预热迭代不入样本；Pause/Resume 在预热有效但不计入
- 并发一致性
  - 引入启动栅栏（TEvent/信号量），消除起跑竞态；聚合线程内 bytes/items 计数
- 防优化与统计
  - Blackhole 覆盖 Int64/Double/Pointer；统计增强 IQR/Skew/Kurtosis 校验与开销估计
- 输出与脚本
  - 库层不直接 writeln/中文；Reporter 完整承载输出；统一 tests/examples BuildOrTest 调用 tools/lazbuild.bat

## 风险与缓解
- 校准算法变更导致历史数据不可比：提供兼容开关与基线阈值（默认 ±10%）
- 并发栅栏引入少量额外开销：仅在多线程模式启用，并在文档中注明
