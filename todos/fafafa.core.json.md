# 开发计划日志：fafafa.core.json

## 本轮（2025-08-20）
- 目标：修复增量读取（JsonIncrRead）跨块字符串转义与 UTF-8 多字节边界的“需更多数据”识别，避免错误终止。
- 事实基线：tests/fafafa.core.json 现有 98+ 用例，增量读取边界有 2 个用例不稳定。

### 执行计划
1) 在 JsonIncrRead 中先对当前切片做“临时拷贝试解析”，成功后再在原缓冲上正式解析，避免第一次失败导致缓冲被修改。
2) 对失败时的错误码进行启发式判定：
   - jecUnexpectedEnd 一律视作 jecMore；
   - jecInvalidString/jecInvalidNumber 且错误位置靠近尾部（阈值 8 字节）→ 视作 jecMore；
   - 尾部 8 字节启发式：遇到反斜杠或 UTF-8 起始字节且剩余不足 → 视作 jecMore。
3) 成功解析后推进已消费偏移 Consumed；当 Consumed==Avail 时复位。
4) 回归测试并逐步收敛启发式（避免误判）。

### 当前状态
- 已实现 1)+2)+3)，测试剩余 1 处失败（UTF-8 跨块用例）。
- 下一步：增加“试解析成功→正式解析成功但尾部检查导致 MORE”的回退策略（已取消尾部检查路径），聚焦在失败路径上识别 MORE；必要时对 CopyValidUTF8 的边界行为再定向覆盖。

### 后续（短期）
- 微调 UTF-8 边界判断：基于 JsonDocGetReadSize + 当前位置相对切片尾的关系，而非全切片尾部扫描。
- 若仍不稳定，考虑在 incr 层缓存未完成的 UTF-8 前导字节数量，跨调用拼接再解析（无状态 → 小状态）。
- 完成后更新 docs/report，并补 1~2 条针对 UTF-8 边界的单测。


