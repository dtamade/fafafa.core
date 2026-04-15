# L0 CI And Stable Docs Hardening Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 把 strict non-SIMD L0 的 Linux manual/reusable CI 入口接到单入口维护脚本上，并让稳定文档不再硬编码瞬时 `main@<sha>` 信息。

**Architecture:** 先用 shell contract test 锁住两件事：一是 `.github/workflows/l0-linux-maintenance.yml` 必须存在并直接调用 `tests/run_strict_l0_maintenance_loop.sh`；二是 docs checker 必须显式检查 `README`、`INDEX`、`CI`、`roadmap` 不再含有 transient `main@<sha>`。然后补 workflow、扩展 checker、收紧稳定文档措辞，最后做 fresh 验证并提交 checkpoint。

**Tech Stack:** GitHub Actions YAML, bash contract tests, ripgrep, Markdown docs, git commit.

---

### Task 1: 先写 failing contract tests

**Files:**
- Create: `tests/test_strict_l0_linux_ci_workflow_contract.sh`
- Create: `tests/test_strict_l0_stable_docs_no_sha_contract.sh`

**Step 1: 跑 workflow contract test**

Run:

```bash
bash tests/test_strict_l0_linux_ci_workflow_contract.sh
```

Expected: 因 workflow 尚未存在而失败。

**Step 2: 跑 stable docs no-sha contract test**

Run:

```bash
bash tests/test_strict_l0_stable_docs_no_sha_contract.sh
```

Expected: 因 docs checker 还未验证 transient main SHA removal 而失败。

### Task 2: 实现 Linux manual/reusable CI workflow

**Files:**
- Create: `.github/workflows/l0-linux-maintenance.yml`
- Modify: `docs/CI.md`
- Modify: `docs/TESTING.md`

**Step 1: 新增 workflow**

要求：

- `workflow_dispatch`
- `workflow_call`
- `ubuntu-latest`
- 安装 `fpc` / `lazarus`
- 直接执行 `bash tests/run_strict_l0_maintenance_loop.sh`

**Step 2: 在 CI/TESTING 文档里登记入口**

要求：

- 说明这是 strict L0 的 Linux manual/reusable CI 入口
- 保持“Windows exact evidence 只来自 GitHub Actions”这条纪律不变

### Task 3: 扩展 docs checker 并清理稳定文档中的 transient SHA

**Files:**
- Modify: `tests/check_strict_l0_docs_consistency.sh`
- Modify: `docs/README.md`
- Modify: `docs/INDEX.md`
- Modify: `docs/CI.md`
- Modify: `docs/fafafa.core.l0.roadmap.md`

**Step 1: 在 checker 里增加 no-sha contract**

要求：

- 明确检查 `README`、`INDEX`、`CI`、`roadmap` 不含 `main@<sha>`
- 明确检查 `.github/workflows/l0-linux-maintenance.yml` 存在且引用维护脚本

**Step 2: 改 stable docs**

要求：

- 用“已合并到 `main`”替代 `main@f6585dd9`
- 把 exact SHA 留给 dated audit / legacy / plan，不留在稳定文档主叙述里

### Task 4: fresh 验证并提交 checkpoint

**Files:**
- Modify: git history only

**Step 1: 跑新增 contract tests**

Run:

```bash
bash tests/test_strict_l0_linux_ci_workflow_contract.sh
bash tests/test_strict_l0_stable_docs_no_sha_contract.sh
```

Expected: PASS

**Step 2: 跑完整维护闭环**

Run:

```bash
bash tests/run_strict_l0_maintenance_loop.sh
git diff --check
```

Expected: PASS

**Step 3: 提交 checkpoint**

Run:

```bash
git add .github/workflows/l0-linux-maintenance.yml docs/README.md docs/INDEX.md docs/CI.md docs/TESTING.md docs/fafafa.core.l0.roadmap.md tests/check_strict_l0_docs_consistency.sh tests/run_strict_l0_maintenance_loop.sh tests/test_strict_l0_linux_ci_workflow_contract.sh tests/test_strict_l0_stable_docs_no_sha_contract.sh
git commit -m "📝 文档: 固化 L0 CI 与稳定文档维护入口"
```

Expected: 当前 L0 hardening 批次形成可追踪 checkpoint。
