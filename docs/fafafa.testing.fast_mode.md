# 测试快模式（FAF_TEST_*）使用指南

本指南说明如何在本地或 CI 中加速测试、提升可观测性，而不影响对外库行为。

## 环境变量
- FAF_TEST_KEEPALIVE_MS
  - 作用：覆盖线程池 KeepAlive（毫秒）
  - 场景：缩短空闲线程回收时间，加快与 KeepAlive 相关用例
- FAF_TEST_FAST
  - 作用：快速模式开关（'1'/'true'）
  - 行为：若 KeepAlive > 250ms，则降为 200ms（保守下限）；未设 FAF_TEST_KEEPALIVE_MS 时生效
- FAF_TEST_TIMEOUT_SEC
  - 作用：BuildOrTest 脚本整体超时（秒），超时自动 Kill 测试进程，返回 101
  - 默认：180

上述变量仅在测试进程内生效；库对外行为不受影响。

## 如何运行
- 快速子集（smoke/代表性）：
  ```bat
  tests\fafafa.core.thread\BuildOrTest.bat test-quick
  ```
- 全量并导出日志/heaptrc/慢用例榜单：
  ```bat
  tests\fafafa.core.thread\BuildOrTest.bat test-full
  ```
- 自定义更“快”的设置（示例）：
  ```bat
  set FAF_TEST_FAST=1
  set FAF_TEST_KEEPALIVE_MS=150
  set FAF_TEST_TIMEOUT_SEC=60
  tests\fafafa.core.thread\BuildOrTest.bat test-full
  ```

## 输出与排查
- 日志目录：tests/.../logs/
  - run_full_*.log / run_full_*.err.log：stdout / stderr
  - heaptrc_full_*.log：内存泄漏跟踪
- 控制台末尾打印 Top 慢用例（前 10），便于快速定位

## 注意事项
- 快模式仅用于测试，不应在生产环境设置
- 若遇到平台差异或不稳定，可先取消 FAF_TEST_FAST 并适当增大超时
- 建议结合 --progress 输出或简要汇总，更易判断是否“卡住”

