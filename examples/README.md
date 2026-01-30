# Examples 快速指南
> 统一示例索引：docs/EXAMPLES.md（含集合/文件系统/终端模块示例总表与一键脚本）



本目录提供“一键切换 Sink 输出”的脚本与各模块示例的快速索引。以下命令均在仓库根目录执行。

## 一键脚本（Runner / Benchmark）

- Windows PowerShell（推荐）
  - 位置：examples\sink.quick-switch.ps1
  - 用法：
    - Runner（控制台/JSON/JUnit）
      - `examples\sink.quick-switch.ps1 -target runner -sink console`
      - `examples\sink.quick-switch.ps1 -target runner -sink json -outfile out\report.json`
      - `examples\sink.quick-switch.ps1 -target runner -sink junit -outfile out\report.xml`
    - Benchmark（控制台/JSON）
      - `examples\sink.quick-switch.ps1 -target bench -sink console`
      - `examples\sink.quick-switch.ps1 -target bench -sink json -outfile out\bench.json`
    - Thread examples（线程示例统一入口）
      - `examples\sink.quick-switch.ps1 -target thread`
      - 运行单个线程示例：`examples\fafafa.core.thread\BuildOrRun.bat run example_thread_wait_or_cancel`



- Linux/macOS Bash
  - 位置：examples/sink.quick-switch.sh
  - 首次需赋权：`chmod +x examples/sink.quick-switch.sh`
  - 用法：
    - Runner（控制台/JSON/JUnit）
      - `./examples/sink.quick-switch.sh runner console`
      - `./examples/sink.quick-switch.sh runner json out/report.json`
      - `./examples/sink.quick-switch.sh runner junit out/report.xml`
    - Thread examples（线程示例统一入口）
      - `./examples/sink.quick-switch.sh thread`
      - 运行单个线程示例：`./examples/fafafa.core.thread/BuildOrRun.sh run example_thread_wait_or_cancel`


    - Benchmark（控制台/JSON）
      - `./examples/sink.quick-switch.sh bench console`
      - `./examples/sink.quick-switch.sh bench json out/bench.json`

说明
- Sink 开关为可选；不设置则继续使用默认 Reporter
- Benchmark 的 JSON Sink 已与默认 JSON Reporter 位等，可安全启用
- 所有时间戳统一为 UTC Z（RFC3339）

## 其他示例索引
- fafafa.core.process
  - example_process.lpr / example_group.pas / example_path_search.pas
  - example_pipeline_failfast.pas（FailFast + MergeStdErr + CaptureOutput）
  - 新增：example_redirect_file_and_capture_err.pas（stdout→文件，stderr→内存）
  - 构建：build.bat / build.sh / build_failfast.bat / run.sh / run_failfast.sh
  - example_capture_stdout_redirect_err.pas（stdout→内存，stderr→文件）
  - example_both_redirect_to_file.pas（stdout/stderr → 文件）
- fafafa.core.thread
  - BuildOrRun.bat run（默认运行：channel/scheduler/best_practices/future_helpers/cancel_io_batch/metrics/spawn_token/wait_or_cancel/channel_select_cancel/scheduler_cancel_timeout）
  - 重点示例（最佳实践）：
    - example_thread_wait_or_cancel.lpr —— FutureWaitOrCancel 协作式取消/超时
    - example_thread_select_best_practices.lpr —— Select first-wins + 取消未中选 + Join
    - example_thread_channel_select_cancel.lpr —— Channel + Select + Cancellation 组合
    - example_thread_scheduler_cancel_timeout.lpr —— Scheduler 延迟任务 + Token 取消 + WaitOrCancel
    - example_thread_channel_timeout_multi_select.lpr —— 多源 Channel + Select 超时 + 协作式取消
  - 基础示例：
    - example_thread_channel.lpr —— 通道（无缓冲握手/有缓冲）
    - example_thread_scheduler.lpr —— 延迟调度
    - example_thread_future_helpers.lpr —— Future 辅助方法
    - example_thread_spawn_token.lpr —— Spawn 携带 Token
    - example_thread_cancel_io_batch.lpr —— IO 批处理取消
    - example_metrics_light.lpr —— 轻量指标
    - example_thread_select_nonpolling.lpr / example_thread_select_bench.lpr —— 非轮询 Select/基准（可选）
  - 详见：examples/fafafa.core.thread/README.md（更完整用法与注意事项）
- fafafa.core.lockfree
  - BuildOrRun.bat run / BuildOrRun.sh run（example + bench + 严格工厂示例）
  - 新增：example_oa_strict_factories.lpr（OA 严格工厂：大小写不敏感字符串键、记录键）

- fafafa.core.crypto
  - 一键运行最小 AEAD Append/In-Place 示例：
    - Windows: examples\fafafa.core.crypto\BuildOrRun_MinExample.bat
    - Linux/macOS: examples/fafafa.core.crypto/BuildOrRun_MinExample.sh
  - 示例源码：examples/fafafa.core.crypto/example_aead_inplace_append_min.pas
  - 说明：若 lazbuild 未在 PATH，请设置 LAZBUILD_EXE 指向 lazbuild 可执行文件

### Crypto 快速导航（AEAD/文件加解密/清理）
- AEAD 最小示例（Append / In‑Place）：
  - Windows: examples\fafafa.core.crypto\BuildOrRun_MinExample.bat
  - Linux/macOS: ./examples/fafafa.core.crypto/BuildOrRun_MinExample.sh
  - 预期输出（示例）：Append: CT+Tag len=21, Append: PT len=5 ok=TRUE, InPlace: CT+Tag len=28, InPlace: PT len=12
- 文件加解密（含负向用例）：
  - Windows: examples\fafafa.core.crypto\BuildOrRun_FileEncryption.bat
  - Linux/macOS: ./examples/fafafa.core.crypto/BuildOrRun_FileEncryption.sh
  - 日志：examples/fafafa.core.crypto/fileenc.log（控制台 + 文件双写；包含“错误密码解密失败”）
- 清理脚本（多次演示后快速复原）：
  - Windows：examples\fafafa.core.crypto\Cleanup_Outputs.bat
  - Linux/macOS：./examples/fafafa.core.crypto/Cleanup_Outputs.sh



更多模块示例请进入对应子目录查看 README 或构建脚本。
