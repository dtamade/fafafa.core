# fafafa.core.signal 工作总结报告

更新时间：2025-08-22

## 本轮进度与已完成项
- ✅ 在线调研：对齐 Go os/signal、Rust signal-hook/tokio::signal 的最小可用模式（订阅 + 自管道）。
- ✅ 初版实现：src/fafafa.core.signal.pas
  - Unix：SigAction + self-pipe，派发线程内回调
  - Windows：SetConsoleCtrlHandler 桥接 Ctrl 事件
  - 订阅/注销/WaitNext/InjectForTest
- ✅ 扩展 API：SubscribeOwned/UnsubscribeAll（按 Owner 批量注销）
- ✅ sgWinch 去抖：ConfigureWinchDebounce(windowMs) + 连续合并
- ✅ 与 term 集成：默认启用 FAFAFA_TERM_USE_SIGNALCENTER_WINCH，term_unix 通过 signal center 订阅 sgWinch 并派发 tek_sizeChange
- ✅ 单元测试工程：tests/fafafa.core.signal/*（lpi/lpr/testcase + BuildOrTest.bat）
  - 用例：订阅注销、等待+注入、回调分发计数、Owner 批量注销、去抖窗口
- ✅ 文档：docs/fafafa.core.signal.md、docs/partials/signal.best_practices.md 已更新
  - 明确回调/WaitNext/Channel 的消费语义与不要混用的原则；
  - Windows ConsoleCtrlHandler 的吞/放行策略；
  - sgWinch 合并与时间窗口去抖、队列容量/丢弃策略、回调规范、FAQ 等。


## 遇到的问题与解决方案
- 信号处理上下文限制：在 handler 内不可做复杂操作 → 采用 self-pipe/事件队列，在派发线程回调。
- 跨平台映射：Windows 控制台事件与 Unix 信号并不完全等价 → 统一为 TSignal 并在文档中说明语义差异。

## 后续待办与建议
- 增加 Once/Channel 风格 API（基于 fafafa.core.thread.channel 或 lockfree 队列）。
- 对 sgWinch 等高频信号提供合并/去抖选项。
- 提供 Enable/Disable 安装子集信号的配置（通过 settings.inc 宏）。
- 扩充集成测试（交互式 Ctrl+C/Winch）与示例。

