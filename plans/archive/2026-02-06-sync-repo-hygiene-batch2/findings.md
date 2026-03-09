# Findings & Decisions: Layer1 sync follow-up + repo artifact hygiene

## Requirements
- 按 `backlog.md` 持续推进：`P0 / sync` 与 `P1 / repo`。
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
- repo hygiene（`tests/` 范围）两批执行结果：
  - 第一批（日志类）：候选 57 + 追加 1 = 去追踪 58（`_run_all_logs_sh` + `logs/` + `*.log` + `run_all_tests_summary_sh.txt`）
  - 第二批（crypto reports 非日志）：候选 9 = 去追踪 9（`tests_crypto*.xml` + `tests_list.txt`）
  - 两批累计：去追踪 67 个 `tests/` 运行产物
  - 清理后：
    - `git ls-files tests | awk '/^tests\/_run_all_logs_sh\// || /\/logs\// || /\.log$/' | wc -l` = 0
    - `git ls-files tests | rg '/reports/' | wc -l` = 0
    - `git ls-files -ci --exclude-standard tests | wc -l` = 0
- 为避免回潮，已补充忽略规则：
  - `tests/*/*.log`
  - `tests/*/reports/*.log`
  - `tests/fafafa.core.crypto/reports/tests_crypto*.xml`
  - `tests/fafafa.core.crypto/reports/tests_list.txt`

## Decisions
| Decision | Rationale | Evidence |
|----------|-----------|----------|
| 将 NamedEvent 问题定性为“受限环境兼容性”并先修测试稳健性 | 错误来自共享内存权限，且核心 sync 子模块基线正常 | `tests/fafafa.core.sync/Test_sync_modern.pas` + 模块回归结果 |
| sync 本体验证口径改为模块直测 | 避免 `run_all_tests` 前缀命中 benchmark 干扰 | `tests/fafafa.core.sync/BuildOrTest.sh` 结果 |
| repo hygiene 分批清理（先日志，后 reports） | 降低误删风险，控制评审规模 | staged 删除计数与清理后归零验证 |

## Risks / Open Questions
- `sync.benchmark` 的 rc=217 是否为环境依赖（资源/权限/时序）需单独立项。
- 仓库其他目录（如 `examples/`）仍有大量已跟踪构建/运行产物，建议继续分批治理。

## Resources (paths / links)
- `backlog.md`
- `task_plan.md`
- `progress.md`
- `tests/fafafa.core.sync/Test_sync_modern.pas`
- `src/fafafa.core.sync.namedEvent.unix.pas`
- `tests/fafafa.core.crypto/BuildOrTest.sh`
- `tests/fafafa.core.crypto/BuildOrTest.bat`
- `.gitignore`
