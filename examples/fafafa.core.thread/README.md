# fafafa.core.thread 示例说明
# fafafa.core.thread Examples (Cancel & Bench Matrix)

## 取消最佳实践
- 运行：BuildOrRun_CancelBestPractices.bat
- 包含：
  - cancel_best_practices.lpr（CallerRuns + 有界队列 + Token + FutureWaitOrCancel）
  - cancel_best_practices_with_token_struct.lpr（通过结构体参数传入 Token 并周期检查）

## 基准矩阵（线程数 × 队列容量 × 任务时长）
- 运行：BuildOrRun_BenchMatrix.bat
- 等同于调用 benchmarks/fafafa.core.thread/run_matrix.ps1 或 run_matrix.sh
- 输出 CSV：benchmarks/fafafa.core.thread/bench.csv，可自行以脚本汇总/画图


## 最小命令速查

- 一键构建全部：examples\fafafa.core.thread\BuildOrRun.bat build
- 一键运行全部：examples\fafafa.core.thread\BuildOrRun.bat run
- 单个示例可执行：直接运行 .\bin\example_*.exe（如 example_thread_wait_or_cancel.exe）
- Select 基准对比：
  - compare-select：examples\fafafa.core.thread\BuildOrRun.bat compare-select [ITER] [REPEATS] [CSV]? [STEP]? [SPAN]? [BASE]?
  - compare-select-matrix：examples\fafafa.core.thread\BuildOrRun.bat compare-select-matrix (ITER1,ITER2) REPEATS CSV (STEP1,STEP2) (SPAN1,SPAN2) (BASE1,BASE2)
  - 生成报告（自动选最新 CSV）：examples\fafafa.core.thread\BuildOrRun.bat report-select
  - 指定 CSV 生成报告：examples\fafafa.core.thread\BuildOrRun.bat report-select path\to\file.csv
- Linux/macOS：
  - 先安装 lazbuild（Lazarus）或 fpc
  - 使用 lazbuild 构建单个示例：lazbuild --build-mode=Release example_thread_wait_or_cancel.lpr
  - 或使用 fpc 构建：fpc -MObjFPC -Scghi -O2 -XX -CX -Sd -Si -Sg -Fi. -Fu. -Fu../../src -FEbin example_thread_wait_or_cancel.lpr
  - 运行：./bin/example_thread_wait_or_cancel（Linux/macOS 下通常无 .exe 扩展名）

- Linux/macOS 一键脚本：
  - 位置：examples/fafafa.core.thread/BuildOrRun.sh（需赋权：chmod +x BuildOrRun.sh）
  - 一键构建全部：./BuildOrRun.sh build
  - 一键运行全部：./BuildOrRun.sh run
  - 运行单个示例：./BuildOrRun.sh run example_thread_wait_or_cancel



本目录包含线程并发子系统的三个示例：

- example_thread_channel.lpr
  - 演示容量=0 无缓冲通道的握手语义（Send/Recv 需配对）。
  - 输出：先发送再接收、或先接收再发送，均能正确配对，最终 heaptrc 为 0 未释放。

- example_thread_scheduler.lpr
  - 演示延迟调度（Schedule(task, delayMs)），并读取调度器指标。
  - 输出：打印“Scheduled, waiting.../Elapsed(ms)=.../Flag=TRUE”，heaptrc 为 0 未释放。

- example_thread_best_practices.lpr
  - 最佳实践配置：Core≈CPU、Max≈2×CPU、有界队列≈2×CPU、rpCallerRuns 背压、OnComplete
  - 说明：CallerRuns 在队列满时在调用线程执行，形成自然背压；OnComplete 回调简短且只触发一次。

- example_thread_spawn_token.lpr
  - 演示 TThreads.Spawn 带 ICancellationToken 的重载与协作式取消

## 快速开始（最佳实践）

- WaitOrCancel：Future 协作式取消/超时等待
  - 代码：example_thread_wait_or_cancel.lpr
  - 看点：FutureWaitOrCancel(F, Token, TimeoutMs)
- Select first-wins + 取消未中选 + Join
  - 代码：example_thread_select_best_practices.lpr
  - 看点：Select([F1,F2,F3], ms) → Cts.Cancel → Join([...], ms)
- Channel + Select + Cancellation
  - 代码：example_thread_channel_select_cancel.lpr
  - 看点：两个通道接收者并发，Select 选出先完成者，取消另一个
- Scheduler 延迟任务 + Token 取消 + WaitOrCancel
  - 代码：example_thread_scheduler_cancel_timeout.lpr
  - 看点：Schedule(@Work, delayMs, Token, Data) + FutureWaitOrCancel

## 构建与运行

- 一键构建并运行全部：
  - Windows: BuildOrRun.bat run

- 单独可执行文件：
  - .\bin\example_thread_channel.exe
  - .\bin\example_thread_scheduler.exe
  - .\bin\example_thread_best_practices.exe
  - .\bin\example_thread_future_helpers.exe
  - .\bin\example_thread_select_nonpolling.exe
  - .\bin\example_thread_select_best_practices.exe
  - .\bin\example_thread_select_bench.exe
  - .\bin\example_thread_cancel_io_batch.exe
  - .\bin\example_thread_spawn_token.exe
  - .\bin\example_thread_wait_or_cancel.exe
  - .\bin\example_thread_channel_select_cancel.exe
  - .\bin\example_thread_scheduler_cancel_timeout.exe
  - .\bin\example_thread_channel_timeout_multi_select.exe

- 单独运行某个示例（Windows）：
  - examples\fafafa.core.thread\BuildOrRun.bat run
  - 或直接双击 .\bin\example_thread_cancel_io_batch.exe

- 源码：example_thread_cancel_io_batch.lpr
  - 展示 I/O/批处理 的协作式取消写法与 WaitOrCancel 等待方式

## 注意事项
- Unix 控制台程序需首单元 uses cthreads
- 带中文输出的示例请加 {$CODEPAGE UTF8}
- 若需观察线程内部日志：设置环境变量 FAFAFA_THREAD_LOG=1（或在 Debug 宏下启用更详细日志）

## 协作式取消最佳实践（CancellationToken）
- 线程任务函数尽量采用 function(Pointer): Boolean，返回 True=完成，False=中止
- 在循环或阶段边界主动检查 Token.IsCancellationRequested，命中即尽快返回
- 通过 TThreads.Spawn(@Func, UserDataPtr, Cts.Token) 传入 Token；避免全局单例 Token
- 若传参为接口指针，释放前将指针内容设为 nil，再释放指针，避免引用计数悬挂
- I/O 或等待型任务优先使用 WaitOrCancel 等带 Token 的等待封装
- 取消是协作式的，不保证抢占，请保持任务可中断且短小分段

示例：example_thread_spawn_token.lpr 展示了完整用法

## 基准对比（Select Polling vs NonPolling）

- 一键对比（默认参数，自动生成带时间戳的 CSV）
  - examples\fafafa.core.thread\BuildOrRun.bat compare-select

- 自定义参数
  - examples\fafafa.core.thread\BuildOrRun.bat compare-select 400 3 .\examples\fafafa.core.thread\bin\select_bench_compare_demo.csv 11 100 10
  - 参数：ITER REPEATS [CSV] [STEP] [SPAN] [BASE]

- 批量参数矩阵
  - examples\fafafa.core.thread\BuildOrRun.bat compare-select-matrix (200,400) 3 .\examples\fafafa.core.thread\bin\select_bench_matrix_demo.csv (7,11) (60,100) (20,10)

- 生成报告（自动选最新 CSV）
  - examples\fafafa.core.thread\BuildOrRun.bat report-select

- 指定 CSV 生成报告（可多文件合并）
  - examples\fafafa.core.thread\BuildOrRun.bat report-select .\examples\fafafa.core.thread\bin\select_bench_matrix_demo.csv

- 输出文件
  - CSV 列：mode,N,avg_ms,iter,step,span,base
  - 报告：bin\select_bench_report_YYYYMMDD_HHMMSS.md（包含环境信息 + 均值/标准差/分位数）

