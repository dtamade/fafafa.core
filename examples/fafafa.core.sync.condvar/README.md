# fafafa.core.sync.condvar 示例集合

本目录收纳 `fafafa.core.sync.condvar` 的 current-entry 示例，重点覆盖等待/通知、超时等待、生产者-消费者、MPMC 队列和条件变量与事件/信号量的对比。

## Current entry

- Linux/macOS：`examples/fafafa.core.sync.condvar/BuildOrRun.sh`
- Windows：`examples\fafafa.core.sync.condvar\BuildOrRun.bat`
- 当前示例子项目：
  - `barrier/example_multi_thread_coordination`
  - `cond_vs_event/example_cond_vs_event`
  - `mpmc_queue/example_mpmc_queue`
  - `producer_consumer/example_producer_consumer`
  - `robust_wait/example_robust_wait`
  - `timeout/example_timeout`
  - `wait_notify/example_wait_notify`

## Usage

- Linux/macOS 构建：`bash examples/fafafa.core.sync.condvar/BuildOrRun.sh build`
- Linux/macOS 构建并运行：`bash examples/fafafa.core.sync.condvar/BuildOrRun.sh`
- Windows 构建：`examples\\fafafa.core.sync.condvar\\BuildOrRun.bat build`
- Windows 构建并运行：`examples\\fafafa.core.sync.condvar\\BuildOrRun.bat`

## Notes

- 当前入口默认使用各子项目 `.lpi` 的 `Default` build mode；这里不再强绑 `Release`
- Unix 条件变量示例默认使用 `MakePthreadMutex`，避免把 `pthread_cond_*` 和非 pthread mutex 混用
- 子目录中遗留的 `buildOrTest.bat` 仍属于历史 runner residue，不是 current-entry source of truth

