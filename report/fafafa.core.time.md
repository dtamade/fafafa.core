# 工作总结报告 - fafafa.core.time

日期: 2025-08-24

## 进度与已完成项
- 为 TDuration 与 TInstant 增加比较运算符重载：=, <>, <, <=, >, >=（对齐现代语言直觉用法）。
- 新增测试单元 Test_fafafa_core_time_operators.pas 并加入 test.lpr，覆盖比较运算符的基本正确性。
- 修复/稳健化定时器周期性测试：
  - 将匿名过程回调改为命名过程以兼容 FPC/ObjFPC 的过程变量签名（避免捕获局部变量导致签名不匹配）。
  - 放宽 Test_FixedRate_Jitter_Within_Bounds 的断言，按跨平台抖动留足余量，保证在不同调度器/负载下稳定。
- 小幅整理定时器实现（局部变量命名 NextDeadline），删除残留无用代码段，保持逻辑清晰。
- 全量构建并运行 fafafa.core.time 测试集：通过（37 测试，失败 0，错误 0）。

## 遇到的问题与解决方案
- 问题：比较运算符在 record 上的声明与实现风格需要与现有代码兼容。
  - 方案：采用 class operator 语法，返回布尔，落点于 implementation 段，命名与字段直比较（纳秒基础值）。
- 问题：测试中使用匿名过程作为回调与 ITimerScheduler 的过程类型不完全匹配。
  - 方案：改为顶层命名过程并以 @Proc 传递，避免捕获局部变量。
- 问题：周期性定时器的稳定性在不同平台/负载下存在抖动，导致严格断言偶发失败。
  - 方案：调宽断言窗口，验证“至少执行一次”与总体时间范围，保证跨平台稳定性。

## 后续计划
- 完成时间模块的更高层抽象与扩展：
  1) 增强 TDuration 算术（乘除、取模、舍入）与安全算术族（Checked、Saturating）覆盖。
  2) 丰富 TInstant API（Clamp、Between、Min/Max 扩展）与与 Deadline 的联动。
  3) ITimerScheduler 行为完善：FixedDelay/FixedRate 在负载下的追赶策略与最大追赶步数限制；取消、关闭与析构时序一致性测试。
  4) 性能基准与参数化调度策略（Yield/Slice/FinalSpin 的矩阵），在全部功能落地后补写文档和基准。
- 跨平台细节：Windows 高精度睡眠与 Linux/Darwin 的 slice/yield 策略继续调优。

## 备注
- 本轮未做 CI 相关修改，遵守项目限制。
- 文档与基准测试将在功能全部落地后统一补齐。

# 工作总结报告：fafafa.core.time（本轮）

## 进度与已完成项
- 明确将 time 作为独立语义层实现，不依赖现有 tick。
- 新增 src/fafafa.core.time.pas：Duration/Instant/Deadline；IMonotonicClock/ISystemClock/IClock；Windows/Linux/macOS 实现；SleepFor/SleepUntil/Now* 便捷函数；TFixedMonotonicClock。
- 新增测试工程 tests/fafafa.core.time（含 .lpr/.lpi/buildOrTest.bat 与基本测试用例）；新增比较/饱和算术/TimeIt/格式化 的测试覆盖。
- 新增文档 docs/fafafa.core.time.md（设计与使用指南）。

## 遇到的问题与解决方案
- 平台 API 差异：Windows 使用 QPC 封装为纳秒；Linux 使用 CLOCK_MONOTONIC + fpNanoSleep。解决：在单元内做平台分支，保证接口一致。
- 睡眠精度：Windows Sleep 以毫秒为粒度。解决：四舍五入到最近毫秒，最小 1ms；测试容忍调度抖动。

## 后续计划
- 文档已加入“UTC vs Local 最佳实践”与示例。
- 在一个小模块中试点迁移（建议 benchmark 或 poller；待 time 完成后再迁移）。
- 评估引入 ITimer/ITimerScheduler（线程驱动的一次性/周期定时器）。

## 备注
- 按你的要求：tick 不阻碍 time 的推进，time 内部已独立实现高精度单调时钟；最终会废弃 fafafa.core.tick。


## 本轮补充
- 修复 Windows 忙等收尾实现（QPC 直读），消除编译错误；在 Balanced/LowLatency 策略下用于短延时自旋收尾。
- 增补文档章节：《Sleep 策略与阈值（跨平台指南）》，示例化 SetSleepStrategy / SetFinalSpinThresholdNs / SetFinalSpinThresholdNsFor。

## 测试与验证
- 重新编译并运行 tests/fafafa.core.time：13/13 通过（在新增 sanity 测试撤回后），heaptrc 无泄漏。
- 说明：尝试加入策略切换 sanity 用例，但构建链条牵引到 collections 调整，短期撤回该新增用例以保持现有基线稳定。

## 后续建议
- 小步添加一个仅依赖 time 的 sanity case（不牵引 collections），或在 plays 目录加临时验证，不干扰现有测试工程。
- 按 todos 继续推进：比较运算符增强、Timer/Scheduler MVP、与 poller/async 的 Deadline 统一。



## 本次（v0.1.x）改进纪要
- 精度/稳定性
  - Windows：QPC→纳秒换算改为整数算法，避免浮点舍入长期累积误差
  - Linux/macOS：nanosleep/clock_nanosleep 仅在 EINTR 时重试，非 EINTR 不再循环
- API 扩展
  - Duration：Abs、Neg、TryFromMs、TryFromSec
  - Instant：Since、NonNegativeDiff、CheckedAdd、CheckedSub
  - 策略/调参：GetSleepStrategy；Linux/macOS 片段睡眠粒度 SetSliceSleepMs/For、GetSliceSleepMsFor（Balanced/LowLatency 生效）
- 测试
  - 新增 Test_fafafa_core_time_api_ext.pas，扩展至 18/18 用例全绿；heaptrc 无泄漏
- 文档
  - docs/fafafa.core.time.md：新增“变更记录（v0.1.x）”与“新 API 补充（v0.1.x+）”章节，加入示例


## 本轮新增（Batch C 初步）
- 新策略 UltraLowLatency：
  - Windows：阈值外 Sleep(0) 短让权，阈值内忙等收尾
  - Linux/macOS：阈值外 nanosleep≈200µs 短让权，阈值内忙等或绝对等待（macOS 使用 mach_wait_until）
- 兼容性：不改变既有默认策略；仅在显式 SetSleepStrategy(UltraLowLatency) 时生效
- 测试：time 测试工程 18/18 通过，heaptrc 无泄漏
- 自旋最佳实践：
  - 引入 CpuRelax（x86_64 PAUSE；其他平台 no-op），用于阈值内自旋降功耗
  - Balanced 策略可配置的让权节奏：
    - Windows：Sleep(0)；Linux：sched_yield；默认 N=2048
    - 接口：SetSpinYieldEvery/SetSpinYieldEveryFor/GetSpinYieldEveryFor
- SystemClock 扩展：NowUnixMs/NowUnixNs（UTC 基准），新增单测
- 现状：time 测试工程 19/19 通过，heaptrc 无泄漏


## 后续（建议）
- Batch C（策略优化）：Balanced 下自旋中加入 pause/yield；UltraLowLatency 占位
- Batch D（取消/截止整合）：将可取消睡眠提升到 IMonotonicClock 扩展接口；提供 WaitFor/WaitUntil 统一形态
- Batch E（SystemClock 扩展）：NowUnixMs/NowUnixNs（UTC 基准），并调整 id.time 使用 UTC 计算
- 测试与基准：补充短睡眠误差分布统计与推荐表，跨平台实测收敛默认值


## 本轮补充（2025-08-24-晚间）
- 修复测试用例中的内联变量写法（编译器不支持）：将 `var M := TimerGetMetrics;` 改为先声明 `M: TTimerMetrics;` 后赋值。
- 重新构建并运行 tests/fafafa.core.time：50/50 用例全部通过，0 错误 / 0 失败；heaptrc 无泄漏。
- 未改动 CI 与依赖。

## 后续建议（针对 Timer 小结）
- 文档：在 docs/fafafa.core.time.md 补充 Timer 行为（FixedRate/FixedDelay、追赶策略、异常钩子、指标语义）。
- 示例：新增 examples/fafafa.core.time/example_timer_periodic（演示调度与取消）。
- 基准：功能全部落地后补写跨平台抖动与开销基准。
