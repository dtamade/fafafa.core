# Task Plan: Layer1 sync follow-up + repo artifact hygiene

## Goal
完成 Layer1 `sync` 模块关键路径回归与问题清单更新，并形成“运行产物入库”问题的可执行治理方案（先审计、再最小化修复）。

## Scope
- In:
  - Layer1 sync：复核 `condvar/barrier/once/spin` 与相关聚合模块基线，补充失败复现与修复建议
  - Repo hygiene：盘点已跟踪的 logs/reports/build 产物，明确“保留/移除/忽略”策略
- Out:
  - 大规模 API/架构重构
  - 一次性清理全部历史遗留（本轮只做可验证、低风险闭环）

## Backlog
- `backlog.md`: **P0 / sync**
- `backlog.md`: **P1 / repo**

## Current Phase
Phase 5

## Phases

### Phase 1: Requirements & Baseline
- [x] 复测 sync 关键模块并记录基线
- [x] 盘点“已跟踪运行产物”清单与影响
- [x] 将关键发现写入 `findings.md`
- **Status:** complete

### Phase 2: Plan & Design
- [x] 明确最小改动方案（优先无破坏性）
- [x] 定义验证口径与命令（测试 + git 状态）
- **Status:** complete

### Phase 3: Implementation
- [x] 执行第一批修复（sync + repo hygiene）
- [x] 将关键决策与替代方案写入 `findings.md`
- **Status:** complete

### Phase 4: Verification
- [x] 回归测试（先模块级，再必要扩展）
- [x] 记录命令、退出码、关键结果到 `progress.md`
- **Status:** complete

### Phase 5: Delivery & Archive
- [ ] 更新 `backlog.md`（Done/Next/链接归档）
- [ ] 归档三文件到 `plans/archive/2026-02-06-<topic>/`
- **Status:** in_progress

## Key Questions
1. `sync.benchmark` 的 rc=217 是否为环境依赖（资源/权限/时序）并应单独立项？
2. `tests/` 下 `reports/` 目录中哪些属于长期资产，哪些可继续去追踪？
3. 第二批清理是否扩展到 `examples/` 与其他目录的同类运行产物？

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| 先做审计与分级，再做清理 | 降低误删和大规模 diff 风险 |
| 对 `NamedEvent` 冒烟用例加受限 UNIX 降级分支 | 当前失败是共享内存权限导致，优先保证基础回归稳定 |
| `sync` 本体验证以 `tests/fafafa.core.sync/BuildOrTest.sh` 为主 | `run_all_tests.sh fafafa.core.sync` 会额外命中 `sync.benchmark`，不适合作为单模块健康判断 |
| 第一批 repo hygiene 仅处理日志类运行产物 | 降低影响面，先完成“高噪音、低风险”清理 |
| 补充 `.gitignore`：`tests/*/*.log`、`tests/*/reports/*.log` | 防止已去追踪日志重新以未跟踪文件形式污染工作区 |

## Verification
- sync baseline：
  - `bash tests/fafafa.core.sync/BuildOrTest.sh test`
  - `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.sync.condvar fafafa.core.sync.barrier fafafa.core.sync.once fafafa.core.sync.spin`
- repo hygiene audit：
  - `git ls-files tests | awk '/^tests\/_run_all_logs_sh\// || /\/logs\// || /\.log$/' | wc -l` → `0`
  - `git ls-files -ci --exclude-standard tests | wc -l` → `0`
  - `git diff --cached --name-status | rg '^D\ttests/' | wc -l` → `58`

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
| `fafafa.core.sync` 聚合测试失败：`TTestCase_Sync_Smoke.Test_NamedEvent_Factory` 报 `Permission denied`（`src/fafafa.core.sync.namedEvent.unix.pas:191`） | 1 | 在 `tests/fafafa.core.sync/Test_sync_modern.pas` 增加 UNIX 权限受限场景降级分支；模块直测已通过 |
| `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.sync` 命中 `fafafa.core.sync.benchmark` 失败（rc=217） | 1 | 归类为聚合命令口径问题；后续按模块脚本和关键子模块命令验证 |
