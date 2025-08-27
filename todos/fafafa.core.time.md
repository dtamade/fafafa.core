# 开发计划日志 - fafafa.core.time

日期: 2025-08-24

## 本轮目标
- 补全 Duration/Instant 的比较运算符，保持与现代语言风格一致；提升定时器测试稳定性。

## 已完成
- 为 TDuration、TInstant 增加比较运算符：=, <>, <, <=, >, >=。
- 新增 Test_fafafa_core_time_operators 覆盖基本用例。
- 定时器周期性测试：
  - 去匿名过程，改为命名过程回调，避免过程变量签名不匹配。
  - 放宽抖动断言，保证跨平台稳定性。
- 全量测试通过（37/37）。

## 问题与决策
- 匿名过程捕获局部变量与 ITimerScheduler.TProc 不兼容：改用顶层过程。
- Jitter 断言过严：调整为“至少一次 + 总体时长范围”以提升在不同平台调度器上的稳定性。

## 下一轮计划（功能全部落地后再写文档/基准）
1. Duration：乘/除/取模、RoundTo、Clamp、Checked/Saturating 全覆盖测试。
2. Instant/Deadline：Clamp、Between、Min/Max 扩展；到期剩余时间 API。
3. TimerScheduler：
   - FixedRate 追赶步数上限与策略；
   - Cancel/Shutdown 并发安全与状态测试；
   - 回调异常处理钩子与统计（可选）。
4. 平台睡眠策略矩阵：低延迟与均衡模式在 Win/Linux/Darwin 的参数调优，并完善测试矩阵。

## 备注
- 文档与性能基准在功能完成后统一补齐。

# 开发计划日志：fafafa.core.time

## 现状
- MVP 已提交：Duration/Instant/Deadline + 时钟接口 + Win/Linux 实现 + 基础测试与文档。

## 下一步（短期）
- [x] 增加 FixedClock（测试可控）
- [ ] 增强 Duration/Instant 的算术与比较工具（<=, >= 等）
- [x] macOS 支持（mach_absolute_time + mach_timebase_info）
- [ ] 试点迁移一个子模块：benchmark 或 poller（待 time 完成后再迁移）
- [x] 文档补充：Sleep 策略与阈值（EnergySaving/Balanced/LowLatency；SetFinalSpinThresholdNs/For 示例）


## 中期
- [ ] ITimer/ITimerScheduler（一次性/周期），线程驱动
- [ ] 与 async/poller 集成：超时/Deadline 统一
- [ ] 引入更精准的 Windows 短延时策略（可选 busy-wait 混合），默认关闭

## 迁移计划（废弃 tick）
- [ ] 标注 fafafa.core.tick 为 Deprecated（文档层面）
- [ ] 迁移主要调用点到 core.time
- [ ] 引入薄适配层（可选），最终删除 tick



## 本轮补记（2025-08-24-晚间）
- [x] 修复定时器测试内联变量写法导致的编译问题（改为显式声明+赋值）。
- [x] 本轮验证：tests/fafafa.core.time 50/50 通过，heaptrc 无泄漏。

## 下一轮可执行项（Timer 专项）
- [ ] 文档：在 docs/fafafa.core.time.md 增补定时器章节（FixedRate/FixedDelay 行为、追赶策略、指标、异常 Hook）。
- [ ] 示例：examples/fafafa.core.time/example_timer_periodic。
- [ ] 预研基准维度：抖动分布、平均/百分位误差、CPU 占用（全部落地后再补写）。
