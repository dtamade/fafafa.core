# fafafa.core.thread 收尾清单（Wrap‑up Checklist）

目标：一次性完成“零泄漏 + 压测通过 + 文档最终版 + 版本与变更记录”。平时仅做快速回归，收尾阶段集中执行本清单。

## 1) 泄漏清零
- 关注点：rpAbort 拒绝路径（Future 预分配 + TaskItem 释放链）、Submit 异常路径、工作线程/CallerRuns 释放前清空接口引用
- 动作：
  - 打开 heaptrc（Debug 构建），全量运行一次 test-full
  - 若有残留：在 Debug 宏下启用轻量日志（Future.Create/Destroy、Submit 异常路径、TaskItem Dispose 处）一次性定位
  - 修复后再次 test-full，确认 0 未释放块
- 退出条件：heaptrc 报告 0 unfreed blocks

## 2) 压力测试
- 无缓冲通道公平性（0 容量）：
  - 多生产者/多消费者，更高消息量（如每生产者 5k/10k）
  - 公平分布断言：以理想值为基，误差容忍（例如 ±25%）；总量一致
- 线程池 keepAlive 缩容：
  - 多轮潮汐负载（爆发→静默→爆发），观测非核心线程回收至核心规模
- 退出条件：
  - 公平性：总量一致、各桶在容忍区间
  - keepAlive：静默期结束后线程数收敛至核心大小

## 3) 文档最终 pass
- docs/fafafa.core.thread.md：
  - 异常与边界场景补充一页纸（提交被拒/取消/超时/关闭后的行为）
  - 与示例/脚本一致性复核（命令、路径、输出目录）
- 示例 README：保留一句“SpawnBlocking 使用独立阻塞池”提示

## 4) 版本与变更记录
- 设定版本号（示例：0.2.x）
- 新增 CHANGELOG.md：
  - 修复：CallerRuns 稳定、Submit 异常释放、TaskItem 接口清空等
  - 优化：Join 快路径、线程池扩容启发式微调、脚本 test-quick
  - 文档：Join/Select 用法、阻塞池说明
  - 已知限制与后续计划

## 5) 脚本与命令
- 快速子集（开发期）：
  - Windows: tests\fafafa.core.thread\BuildOrTest.bat test-quick
- 全量 + 泄漏检测（收尾期）：
  - Windows: tests\fafafa.core.thread\BuildOrTest.bat test
  - Linux:   tests/fafafa.core.thread/BuildOrTest.sh test（如需对等脚本则补齐）

## 6) 退出标准（Definition of Done）
- 单元测试全绿（66/66 或更多）
- heaptrc 0 泄漏
- 压测符合阈值（公平性误差在允许范围、keepAlive 缩容正常）
- 文档最终版、CHANGELOG 就绪、版本号更新

## 附：当前状态快照（非阻塞）
- 用例：多次全量 66/66 通过（日常仅做快速回归）
- 泄漏：0 unfreed blocks（Debug + heaptrc 全量验证通过）
- 已做的关键改进：CallerRuns 行为、Submit 异常释放、TaskItem 接口清空、Join 快路径、Spawn/SpawnBlocking 防御、线程池扩容启发式微调、test-quick 子集脚本

