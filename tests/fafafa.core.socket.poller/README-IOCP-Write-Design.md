# IOCP 写事件（seWrite）最小实现设计草案

目标：在不破坏现有稳定性前提下，为 IOCP 轮询器补充最小可用的写事件能力。该设计仅作为草案，后续实现将放置在 `FAFAFA_SOCKET_POLLER_EXPERIMENTAL` 宏下，并尽可能在 DEBUG 下提供可观测性（日志/统计）。

## 背景 & 约束
- IOCP 不直接提供“可写”通知；写通常是同步/异步 send 派发后完成提示（可利用投递完成体现“可写”）
- 我们现有的 IOCP 分支已实现：
  - Zero-byte recv + 完成回调统计
  - 取消/读取/关闭的细粒度日志、摘要统计与阈值 WARN
  - 挂起列表与析构前摘要
- 目标是尽量小步：先不引入复杂的发送缓冲与拥塞控制，只提供“有待发送的数据时，派发写并回传完成事件”的基础能力

## 最小能力定义
- 接口层：当订阅 seWrite 时，表示“该 socket 有待发送的数据”
- Poller 行为：
  - 若 socket 被订阅了 seWrite，且内部“发送队列”非空，则尝试一次投递（WSASend）
  - 完成后以 seWrite 事件形式返回给上层；上层据此继续驱动发送队列（如继续投递或清空标志/退订）
- 非目标：此阶段不实现复杂发送缓冲、拆包/合并、Nagle 控制、背压算法，仅最小“投递->完成->回调”

## 关键数据结构（宏内）
- 在 IOCP poller 中增加：
  - 发送跟踪数组 FSendOps[]：记录已投递的 WSASend 对应的 OVERLAPPED 与句柄
  - 轻量“待发送标志/队列长度计数”（可由上层维护数据，poller 仅持有标志，或未来再扩展）

## 投递策略
- 当 DoModifyEvents 或 RegisterSocket 指明 seWrite 时：
  - 若“待发送标志”为 True，则尝试投递一次 WSASend（最小 size 的 buffer 或上层提供的当前 chunk）
  - 投递成功则加入 FSendOps，等待完成；失败则计入 PostFail 并择机重试（避免自旋，可加退避）
- 完成回调：
  - 由 IOCP 完成时识别是“发送完成”，映射为 seWrite 事件
  - 释放 OVERLAPPED 跟踪；上报 seWrite
  - 若“待发送标志”仍 True，可在上层处理后再次触发 DoModifyEvents 以继续投递

## 取消与停止流程
- Stop/Destroy 与现有 recv 路径一致：CancelIoEx + 等待工作线程归并完成
- 在析构时：
  - 输出 BeforeCleanup 的 pending（包含 Recv/Send 两类）
  - 输出摘要（扩展统计：CompletedWrite，PostFailWrite 等）
  - 严格断言按开关控制

## 调试与可观测性（DEBUG）
- 统计扩展：
  - 在 TDbgHandleStats 中加入 CompletedWrite、PostFailWrite
- 日志：
  - VERBOSE 输出 WSASend 投递与完成的详细行
  - 摘要扩展显示 write 的计数与比例
- 测试：
  - 新增 Test_IOCP_Write_Demo_Windows.pas：演示最小写事件（WSASend(0)）触发 seWrite 回调
  - 开关：tests\\fafafa.core.socket.poller\\bin\\iocp_warn_trigger.ini 中 [IOCP_WRITE_DEMO] enabled=true
  - 可配合 [IOCP_LOG] verbose=true 观察详细日志/统计（DbgGetConfigText 可查看 pending_send_ops）
  - 仅在 Debug + 宏下编译运行，不做强断言，主要用于观察日志/摘要

## 风险与缓解
- 写路径常见风险：
  - 投递过快导致拥塞或堆内存增长
  - 与上层发送缓冲的职责边界不清
- 缓解：
  - 第一阶段不做自动重投与队列，完全由上层控制“何时订阅 seWrite/何时再投递”
  - Poller 只提供一次投递与完成回告能力，尽量把背压放在上层

## 里程碑
- M1：在 IOCP 宏内添加写投递跟踪与完成映射（不改变默认行为）

## 观测与防护开关（运行期 INI）
- [IOCP_WRITE]
  - max_pending_zero_sends：每句柄允许的 0 字节发送最大并发/排队数（默认 1）
  - backoff_ms：当超过阈值时的简单退避间隔毫秒（默认 0，即不退避）
- [IOCP_WRITE_DEMO]
  - enabled：是否启用写演示（默认 false）
  - queue_n：演示中尝试触发写的次数（默认 1）

建议：在本地调试时打开 [IOCP_LOG] verbose=true，配合 Runner 打印的 DbgGetConfigText 观察 pending_send_ops/writeq。


## 观测与防护开关（运行期 INI）
- [IOCP_WRITE]
  - max_pending_zero_sends：每句柄允许的 0 字节发送最大并发/排队数（默认 1）
  - backoff_ms：当超过阈值时的简单退避间隔毫秒（默认 0，即不退避）
- [IOCP_WRITE_DEMO]
  - enabled：是否启用写演示（默认 false）
  - queue_n：演示中尝试触发写的次数（默认 1）

建议：在本地调试时打开 [IOCP_LOG] verbose=true，配合 Runner 打印的 DbgGetConfigText 观察 pending_send_ops/writeq。

- M2：扩展 DEBUG 统计与日志；补充最小写触发测试（仅演示）
- M3：观察实际场景日志，评估是否需要轻量发送队列与退避策略；如需，再开宏分支

## 总结
- 按最小原则先让 seWrite 的“投递-完成-回调”闭环跑通，不碰复杂队列
- 保持所有改动在 IOCP 宏 + Debug 下可观测，默认关闭不影响主线
- 先文档对齐，后逐步实现，期间通过现有 VERBOSE/INI 机制定位问题

