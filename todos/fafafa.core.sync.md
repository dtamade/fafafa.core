# todos: fafafa.core.sync

## 当前状态
- 模块实现：已包含 Mutex/SpinLock/RWLock/Semaphore/Event/CondVar/Barrier/Atomic
- 文档：docs/fafafa.core.sync.md 存在
- 测试：tests/fafafa.core.sync 工程齐备且可运行
- 本轮修复：BuildOrTest.bat 传参与日志/报告输出

## 近期可执行计划（小步快跑）
1. Unix 定时等待完善（短期）
   - Mutex.TryAcquire(timeout) 与 Event.WaitFor(timeout)：改为基于 pthread_*_timed* 实现
   - ConditionVariable.Wait(timeout)：使用 pthread_cond_timedwait
   - 注意：使用 CLOCK_MONOTONIC（若可用），fallback CLOCK_REALTIME
   - 验证：新增最小单元用例，校验边界（0、1、N ms）

2. Windows 路径的改良（中期）
   - 读写锁评估 SRWLOCK（Vista+）；新增宏 FAFAFA_SYNC_USE_SRWLOCK 控制
   - 条件变量评估 CONDITION_VARIABLE + SleepConditionVariableCS 实现

3. 公平性与饥饿测试（中期）
   - 设计压力用例：读优先/写优先/公平轮转三矩阵
   - 保持默认实现简单稳定，提供宏开启高级策略路径

4. 示例与文档（短期）
   - examples/fafafa.core.sync：演示 AutoLock、RWLock、Semaphore 常见模式
   - docs/fafafa.core.sync.md 增补“等待/超时语义”“最佳实践矩阵”

5. 工具脚本一致性（短期）
   - 对齐所有 tests/*/BuildOrTest.bat 风格（--all + --format=xml，记录 last-run.txt）

## 风险与边界
- 需保持默认构建最小依赖与稳定性，Timed API 在部分旧平台可退化为轮询
- 不引入全局 CODEPAGE；仅测试/示例输出中文

## 完成定义（DoD）
- Debug/Release 构建通过；heaptrc 无泄漏
- Windows + Unix 至少一侧完成 timed* API 落地与用例
- 文档与示例可运行，覆盖 RAII 与常见组合

