# fafafa.core.sync.conditionVariable 示例集合

本目录包含若干经典、易理解的条件变量用法示例（遵循项目规范，UTF-8 编码）：

- producer_consumer/example_producer_consumer
  - 生产者-消费者：Signal 通知、Broadcast 收尾
- wait_notify/example_wait_notify
  - 基础等待-通知机制：无超时等待
- timeout/example_timeout
  - 超时等待：Wait(Mutex, TimeoutMs) 返回 False
- barrier/example_multi_thread_coordination
  - 多线程协调（屏障）：全部到达后 Broadcast 统一放行

构建说明：
- Windows: 进入各示例目录，双击 buildOrTest.bat
- Linux: 在各示例目录执行 lazbuild 对应 .lpi

输出规范：
- 二进制输出在 bin/
- 中间文件在 lib/

