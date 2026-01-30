# ADR-0001: Test Kernel Design (No-CI, Framework-first)

Status: Proposed
Date: 2025-08-16
Authors: core team

## Context
- 项目将自研测试框架，目标是“设计先行”：清晰的模块边界、稳定的小接口、低耦合可扩展。
- 近期不面向 CI 集成，不输出外部格式（JUnit/JSON）作为刚性约束；相关能力作为可插拔适配器，不侵入核心。
- 核心关注：注册-调度-事件-断言-上下文；可选能力（快照、诊断、报告）通过 Listener/Adapter 插件化。

## Decision
建立最小可用（MVP）的测试内核模块，并规定边界与扩展点：

- Kernel（接口与基础类型）
  - ITestContext：断言、日志、临时资源、子测试、清理机制、时钟访问
  - ITestListener：统一事件（OnStart/OnTestStart/OnSuccess/OnFailure/OnSkipped/OnEnd）
  - IClock：NowUTC / NowMonotonicMs，提供 SystemClock/FixedClock
  - 异常：ETestFailure，ETestSkip
- Runtime（注册与调度）
  - Test(path, proc)：函数式注册
  - Run(name, proc)：层级子测试，名称通过“/”构成层级
  - 过滤接口 ITestFilter（MVP 仅支持子串匹配）
- Assert
  - AssertTrue/Equals/Fail/Throws/NotThrows/Skip/Assume（MVP：True/Equals/Fail/Skip/Assume）
- Listener（最小内置）
  - ConsoleListener：面向人读的简洁输出，不包含 CI 字段
- Optional（后续增强，非核心）
  - Snapshot：文本/JSON 基线比对（明确更新开关，默认关闭）
  - Diag：轻量诊断输出（可通过环境/参数启停），与业务日志隔离
  - Adapters：对接外部 Runner/报告（JUnit/JSON/FPCUnit 桥接等），默认不加载

## Non-Goals（此 ADR 不做的事）
- 不绑定 CI；不要求生成 JUnit/JSON 报告
- 不引入并发/分片调度的复杂实现（仅保留扩展点）
- 不更改现有 FPCUnit 工程入口（可并行提供我方 Runner 入口）

## Interfaces（摘要）
- ITestContext
  - Name: string
  - AssertTrue(ACondition, AMsg?)
  - AssertEquals(AExpected, AActual, AMsg?)
  - Fail(AMsg)
  - Log(AMsg)
  - Run(name, proc)
  - AddCleanup/RunCleanupsNow
  - Clock: IClock
- IClock
  - NowUTC: TDateTime
  - NowMonotonicMs: QWord
  - 实现：SystemClock、FixedClock
- ITestListener
  - OnStart(ATotal)
  - OnTestStart(AName)
  - OnTestSuccess(AName, ElapsedMs)
  - OnTestFailure(AName, Message, ElapsedMs)
  - OnTestSkipped(AName, ElapsedMs)
  - OnEnd(ATotal, AFailed, ElapsedMs)
- ITestFilter（MVP）
  - Matches(testPath: string): boolean（先实现“子串匹配”）

## Events & Flow
1) 解析参数/环境 → 构建 Filter
2) NotifyStart(total)
3) 对匹配用例：NotifyTestStart → 执行 → Success/Failure/Skipped
4) 子测试执行通过 Context.Run 递归
5) NotifyEnd(total, failed, elapsed)

## Extensibility
- Listener 插件：输出到控制台/文件/外部格式（非核心）
- Filter 插件：正则/标签/表达式（后续）
- 调度器：并发/分片（后续）
- 快照：按文件类型扩展规范化器

## Migration Strategy
- 保留现有 FPCUnit 入口（不破坏既有工程流）
- 并行提供自研 Runner 入口（独立可执行）
- 逐步迁移现有测试到 Test(...) API（分模块、分批）
- 将 JUnit/JSON 等外部格式监听器下沉到 adapters 目录，默认不加载

## Milestones
- M1（核心闭环）
  - kernel/runtime/assert/clock 完整
  - ConsoleListener 落地
  - Filter：子串匹配
- M2（可选增强）
  - snapshot 初版（文本/JSON）；diag 可开关
  - 标签过滤/失败重试（接口就绪）
- M3（适配与迁移）
  - adapters：FPCUnit 桥接；按需外部格式
  - 渐进迁移测试到自研 Runner

## Risks & Mitigations
- 范围蔓延：以 MVP 为先，外部格式/CI 一律适配器化
- 兼容性：并行入口与清晰边界，避免一次性切换
- 学习成本：接口小而稳，提供简短示例与文档

## Status & Next Steps
- 当前代码已具备初版 core/runtime/listener（可在此 ADR 基础上做轻量重构与文档化）
- 下一步：
  1) 将与 CI 报告直接相关的监听器（XML/JUnit/JSON）迁到 adapters（文档标注“默认不加载”）
  2) 补齐 ConsoleListener 文档示例
  3) 为 Runner 增加 Filter 子串参数（若未提供则全跑）

