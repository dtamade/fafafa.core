# Project Hardening Roadmap Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 提升 `fafafa.core` 的门禁可信度、跨平台测试一致性、仓库入口清晰度与热点模块可维护性。

**Architecture:** 先做“低风险高收益”的工程治理，再做热点模块的分批拆分。整个过程避免大重构，优先利用现有 runner、现有文档索引与现有模块边界，围绕 `tests/`、`.github/workflows/ci.yml`、`docs/` 和超大 Pascal 单元做最小可验证修改。

**Tech Stack:** Free Pascal / Lazarus、Bash、Batch、GitHub Actions、Markdown 文档。

---

### Task 1: 统一仓库入口

**Files:**
- Create: `README.md`
- Modify: `docs/README.md`
- Modify: `docs/INDEX.md`
- Reference: `START_GUIDE.md`
- Reference: `CLAUDE.md`

**Step 1: 写最小根入口文档**

在 `README.md` 中只保留四部分：项目概览、构建/测试入口、文档入口、核心目录说明。

**Step 2: 明确入口职责分层**

让 `README.md` 指向 `docs/INDEX.md`、`START_GUIDE.md`、`tests/run_all_tests.sh`，避免与 `docs/README.md` 重复堆叠说明。

**Step 3: 对齐文档索引**

在 `docs/README.md` 与 `docs/INDEX.md` 中加入根入口说明，明确：根目录入口负责导航，`docs/` 负责长期文档。

**Step 4: 验证入口一致性**

Run: `rg -n "README.md|docs/INDEX.md|START_GUIDE.md|run_all_tests" README.md docs/README.md docs/INDEX.md`

Expected: 三个入口文件互相可达，且没有互相冲突的“唯一入口”表述。

**Step 5: Commit**

```bash
git add README.md docs/README.md docs/INDEX.md
git commit -m "docs: add unified repository entrypoint"
```

### Task 2: 把 CI 分成硬门禁与软观测

**Files:**
- Modify: `.github/workflows/ci.yml`
- Modify: `docs/CI.md`
- Reference: `tests/fafafa.core.simd/BuildOrTest.sh`
- Reference: `tests/fafafa.core.os/BuildOrTest.sh`

**Step 1: 列出必须为红的任务**

在 `ci.yml` 中标注 required jobs：至少包含 Linux 编译检查与核心 smoke tests。

**Step 2: 清理 required jobs 中的软失败**

移除 required jobs 内的 `|| true` 和不必要的 `continue-on-error`。

**Step 3: 保留信息性任务但改名**

把 macOS/实验平台保留为 informational jobs，名字中显式注明 `informational` 或 `soft-fail`。

**Step 4: 更新 CI 文档**

在 `docs/CI.md` 中写清 required / informational 的语义、失败处理与 artifact 期望。

**Step 5: 做最小本地验证**

Run: `rg -n "\|\| true|continue-on-error" .github/workflows/ci.yml`

Expected: required jobs 不再含软失败语义；仅信息性 job 保留软失败说明。

**Step 6: 跑关键模块 smoke check**

Run: `bash tests/fafafa.core.simd/BuildOrTest.sh check`

Run: `bash tests/fafafa.core.os/BuildOrTest.sh check`

Expected: 两个关键模块至少能在本地完成编译检查。

**Step 7: Commit**

```bash
git add .github/workflows/ci.yml docs/CI.md
git commit -m "ci: separate required gates from informational jobs"
```

### Task 3: 建立测试 runner parity 基线

**Files:**
- Create: `tests/_meta/check_runner_parity.sh`
- Modify: `tests/run_all_tests.sh`
- Modify: `tests/run_all_tests.bat`
- Create: `docs/reviews/2026-03-08-runner-parity.md`
- Reference: `tests/fafafa.core.color`
- Reference: `tests/fafafa.core.ini`
- Reference: `tests/fafafa.core.logging`
- Reference: `tests/fafafa.core.signal`
- Reference: `tests/fafafa.core.test`

**Step 1: 写 runner parity 审计脚本**

在 `tests/_meta/check_runner_parity.sh` 中输出：只有 `.bat` 没有 `.sh` 的目录、只有 `.sh` 没有 `.bat` 的目录、命名不一致目录。

**Step 2: 生成基线报告**

运行审计脚本并把当前缺口写入 `docs/reviews/2026-03-08-runner-parity.md`。

**Step 3: 为高价值模块补齐缺失 runner**

优先补 `fafafa.core.test`、`fafafa.core.ini`、`fafafa.core.logging`、`fafafa.core.signal`、`fafafa.core.color` 的 `.sh` runner。

**Step 4: 在统一入口脚本中加入提示**

让 `tests/run_all_tests.sh` 或 `tests/run_all_tests.bat` 在发现缺失 runner 时输出可读警告，而不是静默跳过。

**Step 5: 验证 parity 输出**

Run: `bash tests/_meta/check_runner_parity.sh`

Expected: 报告能稳定列出缺口，且核心模块缺口显著下降。

**Step 6: Commit**

```bash
git add tests/_meta/check_runner_parity.sh tests/run_all_tests.sh tests/run_all_tests.bat docs/reviews/2026-03-08-runner-parity.md
git commit -m "test: add runner parity audit and close key gaps"
```

### Task 4: 防止旧二进制掩盖源码问题

**Files:**
- Create: `tests/_meta/verify_fresh_build.sh`
- Modify: `tests/fafafa.core.simd/BuildOrTest.sh`
- Modify: `tests/fafafa.core.test/BuildOrTest.sh`
- Modify: `tests/run_all_tests.sh`

**Step 1: 提炼新鲜构建检查逻辑**

在 `tests/_meta/verify_fresh_build.sh` 中实现“源码比二进制新则强制重建”或“显式 `check` 时总是重建”的公共逻辑。

**Step 2: 先接入高风险模块**

先在 `fafafa.core.simd` 与 `fafafa.core.test` 两个 runner 上接入，验证不会再直接复用陈旧二进制。

**Step 3: 统一总入口行为**

让 `tests/run_all_tests.sh` 支持一个显式环境变量，例如 `RUN_ACTION=check` 或 `FORCE_REBUILD=1`，用于 CI 和本地回归。

**Step 4: 验证旧二进制防线**

Run: `touch src/fafafa.core.simd.dispatch.pas && bash tests/fafafa.core.simd/BuildOrTest.sh check`

Expected: 脚本触发重建，而不是直接运行已有二进制。

**Step 5: Commit**

```bash
git add tests/_meta/verify_fresh_build.sh tests/fafafa.core.simd/BuildOrTest.sh tests/fafafa.core.test/BuildOrTest.sh tests/run_all_tests.sh
git commit -m "test: guard against stale binaries in module runners"
```

### Task 5: 先做热点大文件拆分地图，再做小步拆分

**Files:**
- Create: `docs/reviews/2026-03-08-large-file-hotspots.md`
- Modify: `src/fafafa.core.term.pas`
- Modify: `src/fafafa.core.simd.pas`
- Modify: `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas`
- Modify: `tests/fafafa.core.collections/vec/Test_vec.pas`

**Step 1: 写热点拆分地图**

先在 `docs/reviews/2026-03-08-large-file-hotspots.md` 中记录每个大文件的功能簇、依赖面、推荐拆分顺序。

**Step 2: 选择一个最安全文件做试点**

优先从测试文件开始，例如 `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` 或 `tests/fafafa.core.collections/vec/Test_vec.pas`，按测试簇拆成多个文件。

**Step 3: 只做边界内提取**

对 `term` 与 `simd` 仅做已有边界上的 include / helper 提取，不改公共 API，不做架构重写。

**Step 4: 每次拆分后跑最小验证**

Run: `bash tests/fafafa.core.simd/BuildOrTest.sh check`

Run: `bash tests/fafafa.core.collections/vec/BuildOrTest.sh check`

Expected: 拆分后编译行为不变，测试入口不变。

**Step 5: Commit**

```bash
git add docs/reviews/2026-03-08-large-file-hotspots.md src/fafafa.core.term.pas src/fafafa.core.simd.pas tests/fafafa.core.simd/fafafa.core.simd.testcase.pas tests/fafafa.core.collections/vec/Test_vec.pas
git commit -m "refactor: begin incremental decomposition of large hotspots"
```

### Task 6: 给 TODO 与过程文档建立真相源分级

**Files:**
- Create: `docs/standards/DEBT_CLASSIFICATION.md`
- Modify: `docs/README.md`
- Modify: `docs/INDEX.md`
- Create: `docs/reviews/2026-03-08-root-doc-noise.md`
- Reference: `task_plan.md`
- Reference: `findings.md`
- Reference: `progress.md`
- Reference: `AUTONOMOUS_WORK_SESSION_REPORT.md`

**Step 1: 定义债务分级**

在 `docs/standards/DEBT_CLASSIFICATION.md` 中定义 `release-blocker`、`important`、`backlog` 三档，并规定 TODO 文档如何标注。

**Step 2: 盘点根目录过程文档**

把当前根目录中的过程性 `.md` / `.txt` 清单写入 `docs/reviews/2026-03-08-root-doc-noise.md`，区分长期保留与应迁移/归档。

**Step 3: 更新文档入口**

在 `docs/README.md` 与 `docs/INDEX.md` 中注明：根目录只保留少量入口与当前协作文件，其余过程文档应收敛到 `docs/reports/`、`docs/reviews/` 或 `docs/plans/`。

**Step 4: 验证文档索引可达**

Run: `rg -n "DEBT_CLASSIFICATION|docs/reviews|docs/plans|docs/reports" docs/README.md docs/INDEX.md`

Expected: 债务分级与过程文档归档规则都能从文档入口被发现。

**Step 5: Commit**

```bash
git add docs/standards/DEBT_CLASSIFICATION.md docs/README.md docs/INDEX.md docs/reviews/2026-03-08-root-doc-noise.md
git commit -m "docs: classify technical debt and document source-of-truth rules"
```

### Task 7: 建立项目级退出标准

**Files:**
- Modify: `docs/CI.md`
- Modify: `docs/TESTING.md`
- Create: `docs/reviews/2026-03-08-hardening-exit-criteria.md`

**Step 1: 定义 Phase 1 完成条件**

至少包含四条：required CI 无软失败、核心模块 runner parity 达标、根入口清晰、关键热点有拆分地图。

**Step 2: 定义 Phase 2 完成条件**

至少包含三条：旧二进制防线接入主要模块、超大测试文件开始拆分、TODO 分级落地。

**Step 3: 将退出标准写入文档**

在 `docs/reviews/2026-03-08-hardening-exit-criteria.md` 中给出每项标准的验证命令、产物与责任边界。

**Step 4: 验证文档互链**

Run: `rg -n "hardening-exit-criteria|runner-parity|large-file-hotspots" docs/CI.md docs/TESTING.md docs/reviews/2026-03-08-hardening-exit-criteria.md`

Expected: 退出标准可从测试与 CI 文档中跳转到。

**Step 5: Commit**

```bash
git add docs/CI.md docs/TESTING.md docs/reviews/2026-03-08-hardening-exit-criteria.md
git commit -m "docs: define hardening exit criteria"
```
