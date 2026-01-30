# IOCP 写/读路径观测清单（Observation Checklist）

用途：用于本地调试/复盘 IOCP 分支（Windows+DEBUG+宏）时，系统化记录一次观测的关键信息，帮助对比不同参数/版本的差异，定位瓶颈与退化。

## 1. 基本信息
- 日期时间：
- 观察人：
- 代码版本/分支/Tag：
- 机器环境：CPU/内存/磁盘/网络说明：
- OS/编译器：Windows 版本、FPC/Lazarus 版本：

## 2. 构建与宏
- 构建模式：Debug（-gl -gh）
- 启用宏：
  - FAFAFA_SOCKET_POLLER_EXPERIMENTAL: true/false
  - FAFAFA_IOCP_DEBUG_STRICT_ASSERT: true/false
  - FAFAFA_IOCP_DEBUG_VERBOSE: true/false（注意：可被运行时覆盖）

## 3. 运行期配置（ini）
- 文件：tests/fafafa.core.socket.poller/bin/iocp_warn_trigger.ini（或同名覆盖）
- [IOCP_LOG]
  - verbose: true/false
- [IOCP_WRITE]
  - max_pending_zero_sends: N（建议先用 1）
  - backoff_ms: M（建议先用 0）
  - warn_p95_ms: X（如 10）
- [IOCP_PENDING_DEMO]
  - enabled: true/false（默认 false）
  - tag: 文本
- [IOCP_WRITE_DEMO]
  - enabled: true/false（默认 false）
  - queue_n: 次数（如 10）

## 4. 执行步骤（建议）
1) 打开 DebugView 或 IDE 输出窗口，准备观察 OutputDebugString
2) 运行测试：
   - tests\\fafafa.core.socket.poller\\buildOrTest.bat test
3) 若只想运行部分演示，可在 ini 打开相应段（WRITE_DEMO、PENDING_DEMO）

## 5. 运行时快照（建议记录）
- Poller 配置（DbgGetConfigText，Runner 帮助已自动输出一份）:
  - 示例：
    - dbg_verbose=
    - pending_recv_ops=
    - pending_send_ops=
    - writeq_entries= / writeq=
    - write_max_pending= / write_backoff_ms= / write_warn_p95_ms=
    - worker_threads= / dbg_stats_handles=

- 一次统计摘要（DbgGetSummaryText，建议在关键阶段调用并记录）:
  - 每个 handle 行包含：
    - posted / read / close / canceled / postFail
    - write / writeFail
    - wlat_avg / wlat_p95（写延迟平均/近似 P95）
  - 观察是否有 [IOCP][WARN] High write latency ...

## 6. 现象记录
- 日志摘录（关键信息即可，注意打点时间）：
  - 例：[IOCP] Completed WRITE: handle=... ov=...
  - 例：[IOCP][WARN] High write latency p95=...ms (> ...ms) handle=...
  - 例：[IOCP] BeforeStop/AfterJoin/BeforeCleanup pending: ...
- 行为描述：
  - seWrite/seRead 回调频率、是否符合预期
  - pending_send_ops / writeq 是否持续偏大

## 7. 参数调整与对比
- 本次参数：max_pending_zero_sends= / backoff_ms= / warn_p95_ms=
- 上次参数：
- 与上次对比（指标变化、日志变化）：
- 是否需要复盘 A/B 结果：是/否

## 8. 结论与动作项
- 结论：
- 风险/隐患：
- 动作项（Owner/截止时间）：
  - [ ] 调整 warn_p95_ms 至 X 并复测（Owner，日期）
  - [ ] 在业务场景 Y 打开 WRITE_DEMO 观察 10 分钟（Owner，日期）
  - [ ] 若 p95 抖动明显，考虑 P² 模式（仅 DEBUG 宏下，可选）（Owner，日期）

## 附录：常见问题
- 看不到详细日志：检查 [IOCP_LOG] verbose=true；或在代码中调用 DbgSetVerbose(true)
- 写事件没有触发：确认在 DoModifyEvents/注册时订阅了 seWrite，并查看 PostZeroSend 是否被阈值拦截
- WARN 太多：适当提高 warn_p95_ms 或减小 queue_n；确认是否为演示场景的“故意放大”结果

