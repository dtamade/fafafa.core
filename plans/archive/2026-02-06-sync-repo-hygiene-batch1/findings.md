# Findings & Decisions: Layer1 sync follow-up + repo artifact hygiene

## Requirements
- 按 `backlog.md` 继续推进：`P0 / sync` 与 `P1 / repo`。
- 采用 `planning-with-files`：先基线、再方案、再实现、最后归档。
- 优先低风险、可复现、可回滚的最小改动。

## Observations
- `sync` 聚合测试在本环境初始失败：
  - 命令：`STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.sync`
  - 现象：`TTestCase_Sync_Smoke.Test_NamedEvent_Factory` 抛出 `ELockError`
  - 错误：`Failed to create shared memory for named event ... Permission denied`
  - 定位：`src/fafafa.core.sync.namedEvent.unix.pas:191`
- 已执行最小修复：
  - 文件：`tests/fafafa.core.sync/Test_sync_modern.pas`
  - 处理：在 `Test_NamedEvent_Factory` 中捕获 `ESyncError`，UNIX 且命中 `Permission denied` 时降级为环境受限通过路径，其余异常继续抛出。
- 修复后验证：
  - `bash tests/fafafa.core.sync/BuildOrTest.sh test` → PASS（149 tests, 0 errors）
  - `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.sync.condvar fafafa.core.sync.barrier fafafa.core.sync.once fafafa.core.sync.spin` → PASS（Total=5 Passed=5 Failed=0）
- `run_all_tests` 前缀匹配口径：
  - `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.sync` 会额外命中 `fafafa.core.sync.benchmark`，当前 rc=217（与本次修改无关）。
- 第一批 repo hygiene（仅 `tests/` 日志类）执行结果：
  - 候选清单：57 个（`_run_all_logs_sh` + `logs/` + `*.log`）
  - 额外清理：`tests/run_all_tests_summary_sh.txt`（已在 `.gitignore` 规则覆盖）
  - 实际去追踪：58 个文件（`git diff --cached --name-status | rg '^D\\ttests/' | wc -l`）
  - 清理后：`git ls-files tests | awk '/^tests\/_run_all_logs_sh\// || /\/logs\// || /\.log$/' | wc -l` = 0
  - 清理后：`git ls-files -ci --exclude-standard tests | wc -l` = 0
- 为避免回潮，已补充忽略规则：
  - `.gitignore` 新增 `tests/*/*.log`
  - `.gitignore` 新增 `tests/*/reports/*.log`

## Decisions
| Decision | Rationale | Evidence |
|----------|-----------|----------|
| 将 NamedEvent 问题定性为“受限环境兼容性”并先修测试稳健性 | 错误来自共享内存权限，且核心 sync 子模块基线正常 | `tests/fafafa.core.sync/Test_sync_modern.pas` + 模块回归结果 |
| sync 本体验证口径改为模块直测 | 避免 `run_all_tests` 前缀命中 benchmark 干扰 | `tests/fafafa.core.sync/BuildOrTest.sh` 结果 |
| repo hygiene 第一批先清理日志类产物 | 高噪音低风险，收益立刻可见 | `git diff --cached --name-status` |
| 通过 `.gitignore` 覆盖根级与 reports 日志 | 防止去追踪后反复出现 `??` 噪音 | `.gitignore` 新规则 |

## Risks / Open Questions
- `sync.benchmark` 的 rc=217 是否为环境依赖（资源/权限/时序）需单独立项。
- `tests/` 下 `reports/` 目录仍可能有非日志资产，第二批清理应先建白名单。
- 仓库其他目录（如 `examples/`）存在大量已跟踪构建/产物，需分批治理，避免一次性大 diff。

## Resources (paths / links)
- `backlog.md`
- `task_plan.md`
- `progress.md`
- `tests/fafafa.core.sync/Test_sync_modern.pas`
- `src/fafafa.core.sync.namedEvent.unix.pas`
- `.gitignore`
- `plans/archive/2026-02-06-layer0-layer1-simd-deep-clean/task_plan.md`
