# fafafa.core.sync.conditionVariable 开发计划（本轮后续）

## 已完成（本轮）
- 修复编译失败与测试阻塞。
- 条件变量/互斥量平台实现补全（GetLastError、TryAcquire(ATimeoutMs)）。
- Wait 的 nil 与非 IMutex 防御（明确异常 + 兜底映射）。
- 测试用例改为短超时轮询 + 强类型异常断言。

## 待办
1. 细化错误码映射
   - Unix: 将 pthread 返回值与 errno 更细致地映射到 TWaitError。
   - Windows: 完善 FLastError 根据 API 返回值设置。
2. Windows 兼容路径清理
   - 无原生 CondVar 分支（信号量/事件组合）补完 Broadcast 精确唤醒数量的逻辑。
3. 性能与精度
   - TryAcquire(ATimeoutMs) 轮询可在需要时替换为更高效机制（如事件/条件变量等待）。
   - 增加计时精度测试与更严格的超时容忍边界校验。
4. 压力测试
   - 扩大 Waiter/Signaler 并发规模，增加长时间 soak 测试用例。
5. 代码清理
   - 去除无用 uses / Hint，统一注释风格与错误信息。

## 里程碑与交付
- M1：错误码映射细化 + Windows 分支完善（1~2 天）。
- M2：性能与压力测试覆盖（1~2 天）。
- M3：收尾清理、文档完善与代码评审（1 天）。

