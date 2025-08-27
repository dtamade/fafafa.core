# fafafa.core.term Contracts Addendum

本附录补充四类关键契约：错误模型、线程安全、配置优先级、事件语义。作为 docs/fafafa.core.term.contracts.md 的延伸，先行落地，后续可合并。

## 1) 错误模型（Error Model）
- 目标：避免隐式全局错误串带来的并发不确定性；对标 Rust/Go/Java 的常见做法。
- 约定：
  - 新增推荐模式：能失败的 API 返回 (ok:boolean, code:term_errcode_t=0, message:string='') 或暴露 term_result_t；旧有 Boolean 返回保持兼容。
  - term_last_error 仅用于调试场景，不保证线程安全，也不建议作为业务分支依据。
  - 不变量或参数非法 → 抛异常；能力暂不可用/瞬时失败 → 返回 False/err code，不抛异常。

## 2) 线程安全（Thread-Safety）
- 输出：当前实现默认“调用方在单线程上下文中使用”。未来如需并发输出，将通过内部序列化或提供 term_lock()/term_unlock() 明确期望。
- 事件：单生产者（底层采集）+ 单消费者（上层循环）模型；不建议多线程同时读写事件队列。
- 配置：运行时 Setter 应在“无并发调用输出/事件 API”时使用，避免与 I/O 交错。

## 3) 配置优先级（Config Precedence）
- 编译期默认 < 环境变量（term_init 读取一次） < 运行时 Setter（即时生效）。
- term_get_effective_config（建议新增）用于导出当前生效配置快照，便于诊断与测试。
- 环境变量建议：
  - FAFAFA_TERM_PASTE_DEFAULTS / FAFAFA_TERM_PASTE_KEEP_LAST
  - FAFAFA_TERM_PASTE_BACKEND=ring|default
  - 诊断：FAFAFA_TERM_TRACE=info|debug（建议新增）

## 4) 事件语义（Events Semantics）
- Collect(frame_budget) 的边界：
  - 鼠标 move：仅在同一 Collect 调用内合并（同帧），跨 Collect 不合并。
  - 滚轮：方向反转或被按键/点击分隔则切段。
  - Resize：去抖期间仅保留最后一个尺寸，遇到非 Resize 事件立即停止去抖并产出当前保留的尺寸。
- API 形态建议：Poll(timeout)/TryPoll()/Collect(budget) 三态，和 tests 中用例一致。

---
本附录为执行性约定，优先指导测试与实现落地；合并入主 Contracts 文档后，本文件可删除。
