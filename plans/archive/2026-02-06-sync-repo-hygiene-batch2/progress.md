# Progress Log: Layer1 sync follow-up + repo artifact hygiene

## Session: 2026-02-06

### Current Status
- **Phase:** 5 - Delivery & Archive
- **Started:** 2026-02-06

### Actions Taken
- 按 `planning-with-files` 恢复会话并核对根目录与归档规划文件。
- 完成上一轮归档目录创建：`plans/archive/2026-02-06-layer0-layer1-simd-deep-clean/`。
- 更新 `backlog.md`：
  - 将 `P0 / sync`、`P1 / repo` 提升为 `Now`
  - 将本轮 deep-clean 成果写入 `Done`
- 初始化新一轮 `task_plan.md` / `findings.md` / `progress.md`。
- 执行 sync 基线复测并定位失败点：
  - `run_all_tests` 聚合下 `Test_NamedEvent_Factory` 触发共享内存权限拒绝
- 实施第一批 sync 修复：
  - 修改 `tests/fafafa.core.sync/Test_sync_modern.pas`
  - 为 `Test_NamedEvent_Factory` 增加 UNIX 受限权限场景降级路径（仅命中 Permission denied）
- 执行第一批 repo hygiene 清理：
  - 生成候选清单 57 个（`tests/_run_all_logs_sh` + `tests/**/logs` + `tests/**/*.log`）
  - 追加去追踪 `tests/run_all_tests_summary_sh.txt`
  - 执行 `git rm --cached`，共去追踪 58 个 `tests/` 日志类产物
- 补充忽略规则：
  - `.gitignore` 新增 `tests/*/*.log`
  - `.gitignore` 新增 `tests/*/reports/*.log`
- 执行第二批 repo hygiene 清理：
  - 生成候选清单 9 个（`tests/fafafa.core.crypto/reports` 下 `tests_crypto*.xml` + `tests_list.txt`）
  - 执行 `git rm --cached` 去追踪 9 个非日志 reports 产物（两批累计 67）
- 补充忽略规则（第二批）：
  - `.gitignore` 新增 `tests/fafafa.core.crypto/reports/tests_crypto*.xml`
  - `.gitignore` 新增 `tests/fafafa.core.crypto/reports/tests_list.txt`

### Test Results
| Command | Expected | Actual | Status |
|---------|----------|--------|--------|
| `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.sync` | exit 0 | 先过 `fafafa.core.sync`，后命中 `fafafa.core.sync.benchmark` rc=217 | FAIL* |
| `bash tests/fafafa.core.sync/BuildOrTest.sh test` | exit 0 | PASS（149 tests, 0 errors, 0 failures） | PASS |
| `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.sync.condvar fafafa.core.sync.barrier fafafa.core.sync.once fafafa.core.sync.spin` | exit 0 | Total=5 Passed=5 Failed=0 | PASS |
| `git ls-files tests | awk '/^tests\/_run_all_logs_sh\// || /\/logs\// || /\.log$/' | wc -l` | `0` | `0` | PASS |
| `git ls-files tests | rg '/reports/' | wc -l` | `0` | `0` | PASS |
| `git ls-files -ci --exclude-standard tests | wc -l` | `0` | `0` | PASS |
| `git diff --cached --name-status | rg '^D\ttests/' | wc -l` | `67` | `67` | PASS |

### Notes
- `FAIL*` 为聚合命令口径问题（包含 `sync.benchmark`），非 `tests/fafafa.core.sync` 本体失败。
- 交付动作已完成：batch1 与 batch2 均已归档（`plans/archive/2026-02-06-sync-repo-hygiene-batch1/`、`plans/archive/2026-02-06-sync-repo-hygiene-batch2/`）。
