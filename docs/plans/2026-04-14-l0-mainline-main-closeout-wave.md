# L0 Mainline Main Closeout Wave Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 把 `l0-mainline` 这条 strict non-SIMD L0 分支正式回流到 `main`，并在 merged-main 语义下补齐 Linux / Windows evidence、current-state docs、retained refs 审计和最终 closeout 状态。

**Architecture:** 当前 `origin/main` 到 `l0-mainline` 是纯前进关系，优先按 fast-forward 回流，不制造额外 merge noise。关键路径由主控本地完成：确认 merge-ready、推进 `main`、触发 merged-main closeout、回填 current-state docs；并行任务只负责审计、核对、草案和风险前视，不改动 SIMD，不跨出 strict non-SIMD L0 边界。

**Tech Stack:** git branches/worktrees, GitHub Actions evidence workflows, bash closeout scripts, Markdown docs.

---

### Task 1: 固化 merge-ready 前提与执行边界

**Files:**
- Create: `docs/plans/2026-04-14-l0-mainline-main-closeout-wave.md`
- Review: `workers/worker1.md`
- Review: `docs/audits/2026-04-14-l0-premerge-branch-evidence-audit.md`
- Review: `tests/run_strict_l0_mainline_closeout.sh`

**Step 1: 记录当前 merge-ready 事实**

写明：

- `origin/main...l0-mainline` 当前为 `0 6`
- `l0-mainline` 相对 `origin/main` 的 6 个提交全部属于 strict non-SIMD L0
- 当前 pre-merge exact evidence 锚定 `334219275c1d9474b310ac74e1f6f03a7a8ab488`
- `52cea55f...` 只是 docs-only bookkeeping

**Step 2: 锁死执行边界**

写明：

- 不触碰 SIMD
- Windows exact/native evidence 只接受 GitHub Actions / 真实 Windows runner
- merge 前不把 branch evidence 误写成 merged-main current-state
- retained refs 继续执行 shortlist-first / no broad absorb

### Task 2: 并行完成 merge-ready 审计与 post-merge 草案

**Files:**
- Review: `docs/fafafa.core.l0.roadmap.md`
- Review: `docs/fafafa.core.l0.foundation.md`
- Review: `docs/README.md`
- Review: `docs/INDEX.md`
- Review: `workers/worker1.md`
- Review: `tests/audit_strict_l0_retained_refs.sh`
- Review: `tests/report_strict_l0_retained_refs_inventory.sh`

**Step 1: 审计 merge-ready 口径**

并行确认：

- merge 到 `main` 后哪些 current-entry 文档必须改成 merged-main 语义
- 哪些 dated plans / audits 仍然只应留作历史 closeout
- 当前 retained refs 哪些仍承载独立历史、哪些可能在 merge 后安全删除

**Step 2: 形成 post-merge 更新 shortlist**

整理：

- merged-main current-state 必改文件
- 可延后处理的历史归档文件
- 不能现在误删的本地 refs / worktree 锚点

### Task 3: 把 `l0-mainline` 回流到 `main`

**Files:**
- Modify: local git refs only

**Step 1: 基于 `origin/main` 准备 main integration head**

Run:

```bash
git fetch origin --prune
git rev-list --left-right --count origin/main...l0-mainline
```

Expected:

- 输出 `0 6`
- 说明 `main` 可被 `l0-mainline` fast-forward

**Step 2: 推进远端 `main`**

优先执行：

```bash
git push origin l0-mainline:main
```

若远端保护拒绝 direct push，则退化为：

- 基于 `origin/main` 创建 merge-only integration branch
- 推送 integration branch
- 创建 / 合并 PR

**Step 3: 记录 merged-main head**

Run:

```bash
git fetch origin --prune
git rev-parse origin/main
```

Expected:

- `origin/main` 已推进到包含当前 L0 6 个提交的新 head

### Task 4: 在 merged-main 语义下跑 strict L0 closeout

**Files:**
- Use: `tests/run_strict_l0_mainline_closeout.sh`
- Use: `tests/update_strict_l0_current_state_docs.sh`
- Use: `tests/run_windows_strict_l0_native_evidence_via_github_actions.sh`

**Step 1: 触发 merged-main Linux / Windows evidence**

Run:

```bash
bash tests/run_strict_l0_mainline_closeout.sh --apply-docs
```

Expected:

- 远端 `main` 上的 Linux maintenance workflow 成功
- 远端 `main` 上的 Windows native evidence workflow 成功
- current-state docs 只写 merged-main 事实，不混入 pre-merge branch wording

**Step 2: 记录 merged-main evidence**

写明：

- `main` head sha
- Linux run id / sha
- Windows run id / sha
- Windows local snapshot batch id

### Task 5: 回填 current-entry 文档并完成 retained refs 审计

**Files:**
- Modify: `docs/audits/2026-04-11-l0-current-state-audit.md`
- Modify: `docs/fafafa.core.l0.roadmap.md`
- Modify: `docs/fafafa.core.l0.foundation.md`
- Modify: `docs/README.md`
- Modify: `docs/INDEX.md`
- Modify: `workers/worker1.md`
- Review: `docs/audits/2026-04-14-l0-premerge-branch-evidence-audit.md`

**Step 1: 切换 current-entry 到 merged-main**

写明：

- strict L0 当前已经 merged to `main`
- latest exact Linux / Windows evidence 对应的 merged-main head
- pre-merge branch evidence 审计保留为历史 closeout，不再冒充 current-state

**Step 2: 保守处理 retained refs**

Run:

```bash
bash tests/audit_strict_l0_retained_refs.sh
bash tests/report_strict_l0_retained_refs_inventory.sh
bash tests/report_strict_l0_retained_refs_inventory.sh --details
bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh
```

Expected:

- 只把已被 merged-main 吸收且不再承载独立历史的 refs 记入删除 shortlist
- 对仍有独立 patch history 的 refs 明确保留
- 一旦出现 `dangerous_delete_paths=` 或 `reject_wholesale_absorb=yes`，继续拒绝 broad absorb

### Task 6: 最终验证并给出主线状态

**Files:**
- Modify: none

**Step 1: 跑最终校验**

Run:

```bash
git diff --check
bash tests/check_strict_l0_docs_consistency.sh
bash tests/test_strict_l0_docs_consistency_contract.sh
bash tests/test_strict_l0_stable_docs_no_sha_contract.sh
```

Expected:

- docs consistency 通过
- no-sha contract 通过
- 无 patch 格式问题

**Step 2: 汇总结论**

记录：

- 当前 `origin/main` head
- 当前 merged-main Linux / Windows evidence
- 当前保留的 L0 refs
- 当前下一步是否只剩长期 maintenance loop
