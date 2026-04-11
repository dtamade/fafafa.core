# 2026-04-07 L0 Rescue Split Closeout

> 这份计划记录的是 `2026-04-07` 那一轮 rescue split closeout 的阶段语境。
> 当前 stable L0 roadmap 以 `docs/fafafa.core.l0.roadmap.md` 为准；`docs/plans/2026-04-09-l0-kernel-span2-closeout.md` 只保留后续 batch 的执行 closeout 语境。

## 目标

在 strict L0 已经 merge 到 `main` 的前提下，把主线控制面和 root 污染收干净，同时把 `l0-main-rescue` 压回“只可拆批、不可整合并”的状态。

## 执行边界

- 执行 worktree：`/home/dtamade/projects/fafafa.core/.claude/worktrees/l0-main-promotion-20260407`
- 执行分支：`l0-main-followup-20260407`
- 根目录脏 `main` 不作为执行面
- `l0-main-rescue` 不是 merge target
- SIMD 实现、SIMD CI、SIMD closeout 不经 L0 线回流

## Phase 1: 合并后主线复验

状态：complete

已完成：

- merge `PR #6`
- fetch `origin/main`
- 基于 merged main 切 follow-up 分支
- 在 merged main 上重新跑 strict L0 回归

验收结果：

- `11/11` L0 模块回归通过
- `contracts` no-contracts 通过
- `contracts/platform` example 通过
- `git diff --check` 通过

## Phase 2: 主线控制面清污

状态：complete

已完成：

- 根目录 `task_plan.md` / `findings.md` / `progress.md` 从主线删除
- 最后一份 working-set 归档到 `plans/archive/2026-04-07-mainline-working-set/`
- 新增 L0 rescue 审计与 follow-up 路线图
- 刷新 `docs/INDEX.md`、`docs/README.md`、`plans/README.md`、`backlog.md`、`workers/README.md`、`workers/worker1.md`
- 删除过期 `workers/worker0.md`
- 将 root 历史报告、working 文档和一次性脚本移入 archive

## Phase 3: 非 SIMD rescue 拆批

状态：complete

已完成批次：

1. `tools/tests/docs`
   - 收紧 `tests/run_all_tests.sh`、`tests/test_repo_hygiene_guard.sh`、`tools/lazbuild.sh`
   - 同步 `docs/README.md`、`docs/INDEX.md`、`plans/README.md` 的 current-entry 约束
2. `base/atomic/option/result` examples
   - 统一 example runner 口径
   - 修复 `example_base.lpr` 与 `example_result_filters_and_try.lpr` 的示例表达
3. `mem allocator` 与 `time.tick.hardware.*`
   - `callbackAllocator` 改用统一 contracts
   - `tests/fafafa.core.mem.allocator.foundation/` 与 `tests/fafafa.core.mem/` 补齐 `NoContracts` 模式
   - 5 个 `time.tick.hardware.*` 单元完成一致性清理
4. 剩余非 SIMD 文档
   - 更新 `docs/fafafa.core.mem.guide.md`
   - 更新 `docs/changelog/CHANGELOG_fafafa.core.mem.md`
   - 刷新对应测试 README

规则已执行：

- 每一批都保持独立 review
- 每一批都补 fresh verification
- 全程未把 SIMD-only 文件夹混入同批回流

## Phase 4: SIMD 残留 handoff

状态：complete

已完成：

- 在 `docs/audits/2026-04-07-l0-rescue-triage-audit.md` 明确 SIMD / CI / evidence 残留不经 L0 线回流
- 在 `docs/INDEX.md`、`workers/worker1.md`、`backlog.md` 固化 current-entry 与边界说明
- 保持 `tests/fafafa.core.simd/**`、`.github/workflows/simd-*`、`docs/fafafa.core.simd*` 只做 handoff，不混入本批

## Phase 5: 第二轮 root 清污

状态：complete

已完成：

- 根目录历史报告、working 文档和一次性脚本已归档
- 删除仍留在根目录、但不再承担 current-entry 角色的 stray 产物
- current-entry 已收敛到 `docs/`、`plans/archive/` 与 `workers/`

## 当前验收命令

```bash
STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.base fafafa.core.contracts fafafa.core.bits fafafa.core.layout fafafa.core.endian fafafa.core.span fafafa.core.option fafafa.core.result fafafa.core.atomic fafafa.core.mem.allocator.foundation fafafa.core.platform
bash tests/fafafa.core.contracts/BuildOrTest.sh test-no-contracts
bash examples/fafafa.core.contracts/BuildOrRun.sh run
bash examples/fafafa.core.platform/BuildOrRun.sh run
bash examples/fafafa.core.atomic/BuildOrRun.sh build
bash examples/fafafa.core.base/BuildOrRun.sh build
bash examples/fafafa.core.option/BuildOrRun.sh build
bash examples/fafafa.core.result/BuildOrRun.sh build
bash tests/fafafa.core.mem.allocator.foundation/BuildOrTest.sh test
bash tests/fafafa.core.mem.allocator.foundation/BuildOrTest.sh test-no-contracts
bash tests/fafafa.core.mem/BuildOrTest.sh test
bash tests/fafafa.core.mem/BuildOrTest.sh test-no-contracts
bash tests/fafafa.core.time.tick/BuildOrTest.sh test
git diff --check
```
