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
- cond_vs_event/example_cond_vs_event
  - 对比条件变量与事件的唤醒语义
- mpmc_queue/example_mpmc_queue
  - 多生产者多消费者队列示例
- robust_wait/example_robust_wait
  - 谓词循环与稳健等待写法

构建说明：
- Windows:
  - 构建全部示例：`BuildOrRun.bat build`
  - 构建并运行全部示例：`BuildOrRun.bat`
  - 构建单个子示例：进入子目录执行 `BuildOrRun.bat build`
- Linux:
  - 构建全部示例：`./BuildOrRun.sh build`
  - 构建并运行全部示例：`./BuildOrRun.sh`
  - 构建单个子示例：进入子目录执行 `./BuildOrRun.sh build`

输出规范：
- 二进制输出在 bin/
- 中间文件在 lib/

