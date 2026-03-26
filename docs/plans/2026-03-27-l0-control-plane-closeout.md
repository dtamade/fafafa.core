# L0 Control-Plane Closeout Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 补回主线 L0 路线图入口与协作控制面，收紧 backlog/worker 可见度，并清理可安全删除的源码树生成物。

**Architecture:** 本批次只处理控制面与仓库卫生，不扩张 strict L0 范围，也不触碰 SIMD 实现。做法是先把主线缺失的 L0 roadmap 从现有 worktree 真相源回流，再同步 `INDEX`、`backlog`、`workers`，最后清理 `src/` 下可验证为未跟踪生成物的 `.o/.ppu/.bak`。

**Tech Stack:** Markdown, git worktree context, shell verification, repository hygiene.

---

### Task 1: 补回主线 L0 路线图入口

**Files:**
- Create: `docs/plans/2026-03-24-l0-docs-closeout-roadmap.md`
- Modify: `docs/INDEX.md`

**Step 1: 回流缺失路线图**

- 以 `l0-foundation` worktree 中现有 `docs/plans/2026-03-24-l0-docs-closeout-roadmap.md` 为来源，回流到主工作树同路径。

**Step 2: 校准索引口径**

- 复核 `docs/INDEX.md` 中所有对 L0 路线图的引用，确保都指向主工作树已存在文件。

**Step 3: 验证入口不再断链**

Run:
```bash
test -f docs/plans/2026-03-24-l0-docs-closeout-roadmap.md
rg -n "2026-03-24-l0-docs-closeout-roadmap" docs/INDEX.md docs/plans/2026-03-24-l0-docs-closeout-roadmap.md
```

### Task 2: 对齐主线协作控制面

**Files:**
- Create: `workers/worker1.md`
- Modify: `backlog.md`

**Step 1: 补主线 L0 worker**

- 新建 `workers/worker1.md`，明确 L0 owner、worktree、source-of-truth、当前状态与下一步。
- 保留现有 `workers/worker0.md` 的 SIMD 职责，不混改。

**Step 2: 让 backlog 显式反映 L0 状态**

- 在 `backlog.md` 中新增一条 L0 closeout/handoff 条目。
- 重点写清：strict L0 已 green，当前剩余工作是控制面回流与小批量 hygiene，不是继续扩张 L0 边界。

**Step 3: 验证控制面可见度**

Run:
```bash
sed -n '1,160p' workers/worker1.md
rg -n "strict L0|L0" backlog.md workers/worker1.md
```

### Task 3: 清理源码树生成物并验证

**Files:**
- Delete generated files matching: `src/*.o`, `src/*.ppu`, `src/*.bak`

**Step 1: 先确认不是 tracked 文件**

Run:
```bash
git ls-files 'src/*.o' 'src/*.ppu' 'src/*.bak'
```

Expected:
- 无输出

**Step 2: 删除可安全清理的生成物**

Run:
```bash
find src -type f \( -name '*.o' -o -name '*.ppu' -o -name '*.bak' \) -delete
```

**Step 3: 复验 hygiene 与核心控制面**

Run:
```bash
find src -type f \( -name '*.o' -o -name '*.ppu' -o -name '*.bak' \) | sed -n '1,20p'
git diff --check
STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.base fafafa.core.contracts fafafa.core.bits fafafa.core.layout fafafa.core.endian fafafa.core.span fafafa.core.option fafafa.core.result fafafa.core.atomic fafafa.core.mem.allocator.foundation
bash tests/fafafa.core.contracts/BuildOrTest.sh test-no-contracts
```
