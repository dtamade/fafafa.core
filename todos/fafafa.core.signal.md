# fafafa.core.signal 开发计划与待办

更新时间：2025-08-20

## 现状
- MVP 实现与基础测试已落地。
- 最佳实践文档已补充：docs/partials/signal.best_practices.md（包含模式选择、平台差异、FAQ）。


## 下一步（短期）
1) settings.inc 宏化：FAFAFA_SIGNAL_ENABLE_*（WINCH/USR1/USR2 等），默认全开；在 Windows 端宏控 Ctrl 事件安装。
2) API 扩展：
   - SubscribeOnce(Signals, Callback) / UnsubscribeAll(TokenOwner)
   - Channel 化接口：NewSignalChannel(Signals): IChannel（或简化 record 包装）
3) 去抖/合并：对 sgWinch 可选合并最近 N ms 内多次事件。
4) 文档：加入平台行为差异表与常见陷阱（服务/会话、TTY）。

## 中期
- 集成 term 模块：将 term_unix 的 SIGWINCH 迁移为通过 signal center 派发。
- 提供可注入的 ISignalProvider 接口，便于模拟测试。

## 长期
- 进程子系统联动：与 process groups 协调（TERM → 等待 → KILL）。
- 支持线程内自定义 Mask/Scope（需要更复杂设计）。

