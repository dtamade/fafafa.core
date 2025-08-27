# IOCP 调试与 WARN 验证指南（Windows + DEBUG + 宏）

本文档介绍如何在 Windows 上启用 IOCP 宏分支的调试能力、查看调试日志与统计摘要，以及如何使用示例测试触发并验证 WARN 级别提示。

> 快速上手：请先阅读“观测清单”以了解如何记录关键指标和参数对比：
> tests/fafafa.core.socket.poller/OBSERVATION-CHECKLIST.md


## 前提条件
- 平台：Windows
- 构建：Debug（带 -gl -gh 等调试/泄漏检测标志）
- 宏：按需启用（默认关闭，不影响主线）
  - `FAFAFA_SOCKET_POLLER_EXPERIMENTAL`：启用 IOCP 轮询器分支（实验）
  - `FAFAFA_IOCP_DEBUG_STRICT_ASSERT`：严格断言（可选，默认关闭）。析构时仍有挂起 I/O 将抛异常

在 `src/fafafa.core.settings.inc` 中按需开启上述宏。

## 调试输出与统计摘要
- IOCP 分支在 DEBUG 下输出轻量日志（OutputDebugString）：
  - 完成取消：`[IOCP] Canceled: handle=... ov=...`
  - 完成读取：`[IOCP] Completed READ: bytes=... handle=... ov=...`
  - 完成关闭：`[IOCP] Completed CLOSE: handle=... ov=...`
  - 停止/析构时的挂起列表：`[IOCP] BeforeStop/AfterJoin/BeforeCleanup pending: ...`
  - 析构阶段统计摘要：`[IOCP] Summary handle=H posted=P read=R close=C canceled=X postFail=F fail%=FF cancel%=CC`
  - 阈值报警：
    - `fail% >= 30` 时：`[IOCP][WARN] High post failure rate on handle=H (FF%)`
    - `cancel% >= 50` 且无完成时：`[IOCP][WARN] High cancel rate without completions handle=H (CC%)`
  - 若析构仍有挂起 I/O：`[IOCP][ASSERT] Pending ops not empty at destroy: count=N`

查看方式：使用 Microsoft DebugView 或 IDE 调试器查看 OutputDebugString 输出。

## 示例测试
以下测试仅在 Windows + Debug + `FAFAFA_SOCKET_POLLER_EXPERIMENTAL` 开启时编译：
- `Test_IOCP_Smoke_Windows.pas`：基础 smoke
- `Test_IOCP_Debug_Stats_Windows.pas`：演示 `DbgGetSummaryText`/`DbgResetStats`
- `Test_IOCP_Warn_Trigger_Windows.pas`：通过多次注册/注销触发取消，便于观测 WARN
- `Test_IOCP_Pending_Demo_Windows.pas`：打印 pending 列表与摘要（不做断言，演示用途；受 VERBOSE 控制详单/汇总）
  - 可通过 iocp_warn_trigger.ini 的 `[IOCP_PENDING_DEMO]` 段控制是否启用（enabled=true/false，默认 false），以及可选的 `tag` 文本

运行全部测试：
```
tests\fafafa.core.socket.poller\buildOrTest.bat test
```

## 日志等级开关（VERBOSE）
- 宏：`FAFAFA_IOCP_DEBUG_VERBOSE`（默认关闭）
  - 关闭：仅输出关键 Summary 与 WARN；pending 列表输出计数
  - 开启：输出每次事件（取消/读取/关闭）与完整 pending 列表，便于细粒度诊断
  - 建议：仅在需要时开启，避免噪音过大
- 运行时：`[IOCP_LOG] verbose=true/false`（Warn_Trigger 会读取；Pending_Demo 启用时强制 True）

## WARN 触发测试配置（独立 INI）
`Test_IOCP_Warn_Trigger_Windows` 支持从独立 ini 文件覆盖默认参数，以避免与其他模块的测试配置混淆。

- 优先读取位置（按顺序）：
  1. `tests\fafafa.core.socket.poller\bin\iocp_warn_trigger.ini`
  2. `tests\fafafa.core.socket.poller\iocp_warn_trigger.ini`

- 配置示例（已提供模板文件）：`tests\fafafa.core.socket.poller\iocp_warn_trigger.ini`
```
[IOCP_WARN]
; 放大取消完成的循环次数
loops=10

; 等待取消完成被 worker 处理的毫秒数
wait_ms=50

; 是否启用“弱断言”：断言 cancel% >= 50 或 fail% >= 30
weak_assert=false
```

> 提示：若弱断言偶发失败，可适当增大 `loops` 或 `wait_ms`（如 loops=20, wait_ms=80），以提高稳定性。

## 可选：编译期开关启用弱断言
`Test_IOCP_Warn_Trigger_Windows` 同时支持编译期宏 `IOCP_WARN_WEAK_ASSERT` 作为默认值开关（仅 Debug + IOCP 宏）：
- 定义该宏时，默认启用弱断言；仍可被 ini 中 `weak_assert` 覆盖

## 最佳实践与注意事项
- 默认保持宏关闭，主线测试绿色
- 调试与实验在本地启用宏进行；抓取 DebugView 日志 + 测试输出的 Summary 文本，便于问题定位
- 如需更严格保护：开启 `FAFAFA_IOCP_DEBUG_STRICT_ASSERT` 以在析构阶段对未清空的挂起 I/O 直接抛异常
- 不建议在生产构建中启用上述调试/实验宏

## 常见问题
- 看到 `[IOCP][ASSERT] Pending ops not empty ...`：
  - 表示析构阶段仍有未完成的 overlapped I/O。先检查日志中的 BeforeStop/AfterJoin/BeforeCleanup 列表，确认是否存在未取消/未完成的投递
  - 若开启了严格断言宏，将抛异常，便于在测试环境快速定位


## 常见场景建议参数组合（INI）
以下参数仅建议组合，按需调整；默认为安静模式，不影响主线。

- 高频写演示（便于观察 seWrite 时序与延迟）
  - [IOCP_LOG] verbose=true
  - [IOCP_WRITE_DEMO] enabled=true, queue_n=10..50
  - [IOCP_WRITE] max_pending_zero_sends=1..2, backoff_ms=0..5, warn_p95_ms=10..20

- 稳定性观察（安静）
  - [IOCP_LOG] verbose=false
  - [IOCP_WRITE_DEMO] enabled=false
  - [IOCP_PENDING_DEMO] enabled=false
  - [IOCP_WRITE] warn_p95_ms=0（禁用告警）

- 弱断言验证（Warn_Trigger）
  - [IOCP_WARN] weak_assert=true, loops=20, wait_ms=80
  - 调试中可暂时 [IOCP_LOG] verbose=true；回归时建议关闭

- Pending 列表演示
  - [IOCP_PENDING_DEMO] enabled=true, tag=MyLabel
  - [IOCP_LOG] verbose=true（打印详单与汇总）

示例：
```
[IOCP_LOG]
verbose=true

[IOCP_WRITE]
max_pending_zero_sends=2
backoff_ms=5
warn_p95_ms=15

[IOCP_WRITE_DEMO]
enabled=true
queue_n=20

[IOCP_WARN]
weak_assert=false
loops=10
wait_ms=50

[IOCP_PENDING_DEMO]
enabled=false
tag=PendingDemo
```

- 取消/失败比例偏低，WARN 未触发：
  - 这是正常的；按需增大 `loops`、`wait_ms`，或改为本地启用 `IOCP_WARN_WEAK_ASSERT` 宏

## 相关文件
- 源码：`src/fafafa.core.socket.poller.pas`
- 设置：`src/fafafa.core.settings.inc`
- 测试：`tests/fafafa.core.socket.poller/*.pas`
- 配置模板：`tests/fafafa.core.socket.poller/iocp_warn_trigger.ini`

