# Findings & Decisions: Layer0/Layer1 sweep + SIMD deep clean

## Requirements
- 输出：Layer0/Layer1 sweep 的失败清单（模块 → 复现命令 → 现象 → 建议修复路径 → 验证命令）。
- SIMD：将“对外模块文档”与“内部规划/历史记录”分层；避免多个文档互相矛盾。
- 约束：小步快跑，每批修复都能独立回归；不做未经讨论的大重构。

## Observations
- Layer0 基线（Linux）已确认全绿：`fafafa.core.{base,atomic,option,result,mem.allocator.mimalloc,simd}`（含 `simd.cpuinfo.x86`）
- Layer1 基线（Linux）已确认全绿：`fafafa.core.{collections,math,io,bytes,thread,sync,time}`
- 已修复并回归验证：
  - `fafafa.core.thread`：UNIX 测试程序缺 `cthreads` 导致 runtime error 211；`BuildOrTest.sh` 运行路径错误；部分测试硬依赖 `Windows` 单元
  - `fafafa.core.thread.threadpool`：队列容量判满语义与指标（Submitted/RejectedCallerRuns）不一致，导致容量=0 时容易“全拒绝/误计数”
  - `fafafa.core.sync.mutex.parkinglot`：FastPath 性能用例偶发失败（计时/调度抖动），需要稳定竞争场景
  - SIMD 文档/标记：收敛 `simd.types` 过期引用，明确 `simd.base` 为类型单元；保留 `build.bat` 但改为 wrapper

## Decisions
| Decision | Rationale | Evidence |
|----------|-----------|----------|
| ThreadPool `QueueCapacity` 判满基于“入队后有效队列长度” | capacity 是“允许排队数量”，判满应基于入队后的有效值；capacity=0 仍允许空闲 worker 直接接任务 | `src/fafafa.core.thread.threadpool.pas` + `tests/fafafa.core.thread/Test_threadpool_reject_metrics.pas` |
| 指标口径：`TotalSubmitted` 计入入队与 CallerRuns；CallerRuns 计入 `RejectedCallerRuns` 但不计入 `TotalRejected` | CallerRuns 是“回退执行”而非“丢弃/拒绝”，但仍需要可观测的 submitted 与回退计数 | `src/fafafa.core.thread.threadpool.pas` + `tests/fafafa.core.thread/Test_threadpool_reject_metrics.pas` |
| parkinglot FastPath 性能用例引入稳定竞争线程并提高迭代数 | 避免时间分辨率/调度噪声导致的 flaky 误报 | `tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas` |
| UNIX thread tests 强制 `cthreads`；env var 测试跨平台实现 | 修复 Linux runtime error 211，并让测试在 UNIX/Windows 都可编译运行 | `tests/fafafa.core.thread/tests_thread.lpr` + `tests/fafafa.core.thread/Test_threadpool_env_taskitempoolmax.pas` |

## Risks / Open Questions
- 运行产物进入版本库：`tests/_run_all_logs_sh/*.log`、各模块 `logs/*.txt` 等目前是“已跟踪文件”，每次运行都会造成大 diff；需要评估是否 `git rm --cached` + `.gitignore` 管控（见 `backlog.md` 的 P1/repo）
- SIMD 的 P1/P2 项目量较大（256-bit 类型/测试、NEON/RVV 覆盖、intrinsics 文档等），需要拆分成多个小迭代（每轮 1–3 项）

## Resources (paths / links)
- `docs/ARCHITECTURE_LAYERS.md`
- `docs/SIMD_COMPREHENSIVE_AUDIT_REPORT.md`
- `src/fafafa.core.thread.threadpool.pas`
- `tests/run_all_tests.sh`
- `tests/fafafa.core.simd/BuildOrTest.sh`

## Layer0/Layer1 Sweep（本轮关单清单）

| ID | 模块 | 现象 | 复现命令 | 修复 | 验证 |
|----|------|------|----------|------|------|
| L1-TH-001 | `fafafa.core.thread` | Linux runtime error 211 | `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.thread` | `cthreads`（UNIX） | `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.thread` |
| L1-TH-002 | `fafafa.core.thread` | `BuildOrTest.sh` 找不到可执行文件 | `bash tests/fafafa.core.thread/BuildOrTest.sh` | 修正路径 + 缺失返回码 | `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.thread` |
| L1-TH-003 | `fafafa.core.thread.threadpool` | 指标：CallerRuns 路径计数不一致 | `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.thread` | Submitted/RejectedCallerRuns 对齐 | `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.thread` |
| L1-SY-001 | `fafafa.core.sync.mutex.parkinglot` | FastPath 性能用例偶发失败 | `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.sync.mutex.parkinglot` | 稳定竞争 + 提升迭代数 | `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.sync.mutex.parkinglot` |
