# Task Plan: fafafa.core 夜间回归与修复

## Goal
在你离线（约 10 小时）期间：跑通关键/全量测试；若存在失败则修复并补齐回归验证；输出清晰的结果与后续建议。

## Backlog
- 长期维护入口：`backlog.md`
- 本轮相关条目：P0/tests（run_all_tests runner）、P0/quality（0 warnings/hints）

## Roles (人物)
| 角色 | 负责内容 |
|------|----------|
| Maintainer（我） | 发现问题、制定方案、实施修复、验证与记录 |
| CI/Runner Owner（我） | 维护 `tests/run_all_tests.*`、避免假绿与阻塞 |
| Module Owner（我） | 针对失败模块做最小修复与回归用例补齐 |

## Current Phase
Phase 5

## Phases

### Phase 1: Baseline & Discovery
- [x] 建立 `task_plan.md` / `findings.md` / `progress.md`
- [x] 建立长期维护入口：`backlog.md` + `plans/README.md`
- [x] 确认工具链可用（`fpc` / `lazbuild`）
- [x] 跑关键模块测试（STOP_ON_FAIL=1）
- [x] 先通过严格 0 warning/hint 检查：`fafafa.core.fs` / `fafafa.core.simd`
- [x] 如关键模块通过，再跑全量回归（本轮以“覆盖受影响模块集”为主，详见 progress.md）
- [x] 记录汇总与关键日志路径到 progress.md
- [x] 修复 run_all_tests 的“假绿/阻塞”风险并验证
- **Status:** complete

### Phase 2: Triage & Root Cause
- [x] 汇总失败模块与错误类型（编译/运行/断言）
- [x] 最小化复现（单模块 BuildOrTest）
- [x] 把根因与候选方案写入 findings.md
- **Status:** complete

### Phase 3: Fix (Batch Execution)
- [x] 对每个失败点：补回归测试/用例（如缺失）
- [x] 实施最小修复（避免不必要重构）
- [x] 每批修复后：回跑相关模块测试并记录
- **Status:** complete

### Phase 4: Verification
- [x] 回跑关键模块
- [x] 回跑全量回归（或至少覆盖受影响模块集）
- [x] 记录验证命令、退出码、汇总文件位置
- **Status:** complete

### Phase 5: Delivery
- [x] 汇总改动点、风险、以及建议的后续动作
- [x] 指出任何仍需你确认/决策的事项
- **Status:** complete

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| 默认工作目标 = “跑测试→修复失败→验证” | 你只给了流程要求但未给具体功能需求；这是最稳妥且可独立推进的长任务。 |
| `run_all_tests.*` 模块名规则 = `tests/` 下相对路径（分隔符→`.`） | 让嵌套目录过滤可用，避免 Total=0 仍 exit 0 的假绿。 |
| 默认只跑同目录的 `BuildOrTest.*` | 避免 `BuildAndTest.*` 交互式脚本导致全量回归阻塞。 |

## Errors Encountered
| Error | Resolution |
|-------|------------|
