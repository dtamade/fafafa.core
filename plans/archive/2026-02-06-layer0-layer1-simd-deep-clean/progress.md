# Progress Log: Layer0/Layer1 sweep + SIMD deep clean

## Session: 2026-02-06

### Current Status
- **Phase:** 5
- **Started:** 2026-02-06

### Actions Taken
- Layer1 sweep（Linux）：完成 `collections/math/io/bytes/thread/sync/time` 全量模块回归
- Layer0 sweep（Linux）：完成 `base/atomic/option/result/mem.allocator.mimalloc/simd` 回归（含 `simd.cpuinfo.x86`）
- 修复 thread（UNIX）稳定性与可运行性：
  - `tests/fafafa.core.thread/tests_thread.lpr`：UNIX 引入 `cthreads`（修复 runtime error 211）
  - `tests/fafafa.core.thread/BuildOrTest.sh`：修正可执行路径，补充缺失二进制返回码
  - `tests/fafafa.core.thread/Test_threadpool_env_taskitempoolmax.pas`：UNIX 走 `setenv`，避免硬依赖 `Windows`
- 修复 ThreadPool 判满/指标语义：`src/fafafa.core.thread.threadpool.pas`
- 修复 parkinglot FastPath 性能测试 flaky：`tests/fafafa.core.sync.mutex.parkinglot/fafafa.core.sync.mutex.parkinglot.testcase.pas`

### Test Results
| Command | Expected | Actual | Status |
|---------|----------|--------|--------|
| `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.base fafafa.core.atomic fafafa.core.option fafafa.core.result fafafa.core.mem.allocator.mimalloc fafafa.core.simd` | exit 0 | Total=7 Passed=7 Failed=0 | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh check` | exit 0 | `[CHECK] OK (no SIMD-unit warnings/hints)` | PASS |
| `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.collections fafafa.core.math fafafa.core.io fafafa.core.bytes fafafa.core.thread fafafa.core.sync fafafa.core.time` | exit 0 | Total=54 Passed=54 Failed=0 | PASS |

### Notes
- `tests/run_all_tests.sh` 的详细日志会落到：`tests/_run_all_logs_sh/`
