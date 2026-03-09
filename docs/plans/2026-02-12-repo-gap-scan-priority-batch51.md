# Repo Gap Scan Priority Batch-51 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在全仓复扫后优先收敛 `sync.sem` 当前真实故障（`1 failure + 1 error`），并以严格 TDD 将增强套件恢复到可稳定通过。

**Architecture:** 先固定 RED 基线（编译通过但运行失败），然后分两步最小 GREEN：
1) 修复 `TSemGuard.Release` 在 Unix 路径的计数语义（手动释放后 `GetCount=0`）；
2) 修复 `Test_MultiWaiters_ReleaseExactlyK` 的匿名线程闭包越界写入（替换为显式线程类），最后做模块回归。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.sync.sem`、`src/fafafa.core.sync.sem.unix.pas`、`src/fafafa.core.sync.sem.base.pas`。

---

## 全仓扫描快照（2026-02-12）
- `rg --files src tests examples benchmarks docs | wc -l` => `4817`
- `rg -n --glob 'src/**/*.pas' "TODO|FIXME|未实现|待实现|暂未|placeholder" | wc -l` => `47`
- `rg -n --glob 'tests/**/*.pas' "\{ TODO: 实现 \}|待实现', True\)|TODO|placeholder|暂未实现|未实现" | wc -l` => `61`
- `find tests -mindepth 1 -maxdepth 1 -type d -name 'fafafa.core*' | wc -l` => `151`

## 优先级
- `P0` `sync.sem` 真实失败：`TTestCase_Enhanced.Test_Guard_ManualReleaseMultiple`、`TTestCase_Enhanced.Test_MultiWaiters_ReleaseExactlyK`。
- `P1` `tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.testcase.old.pas`（34 占位）。
- `P2` `tests/fafafa.core.socket/Test_fafafa_core_socket.pas`（6 占位）。

---

### Task 1: RED 基线固化（sync.sem enhanced）

**Files:**
- Inspect: `tests/fafafa.core.sync.sem/fafafa.core.sync.sem.enhanced.testcase.pas`
- Inspect: `src/fafafa.core.sync.sem.unix.pas`

**Step 1: Compile + Run RED**
Run:
- `cd tests/fafafa.core.sync.sem && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.sem.enhanced.test.lpr`
- `./bin/fafafa.core.sync.sem.enhanced.test | tee /tmp/sem-enhanced-b51-red.log >/dev/null`
- `rg -n "Tests run:|Failures:|Errors:|Test_Guard_ManualReleaseMultiple|Test_MultiWaiters_ReleaseExactlyK|<failure|<error" /tmp/sem-enhanced-b51-red.log`

Expected:
- `Tests run: 42`
- `Failures: 1`
- `Errors: 1`

### Task 2: GREEN-1 修复 Guard 计数语义

**Files:**
- Modify: `src/fafafa.core.sync.sem.unix.pas`
- Modify: `src/fafafa.core.sync.sem.base.pas`

**Step 1: Minimal fix**
- `TSemGuard.Release` 在成功释放后统一设置 `FCount := 0`（与 Windows 路径一致）。

**Step 2: Verify**
Run:
- `cd tests/fafafa.core.sync.sem && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.sem.enhanced.test.lpr`
- `./bin/fafafa.core.sync.sem.enhanced.test | tee /tmp/sem-enhanced-b51-green1.log >/dev/null`
- `rg -n "Failures:|Errors:|Test_Guard_ManualReleaseMultiple|<failure|<error" /tmp/sem-enhanced-b51-green1.log`

Expected:
- `Test_Guard_ManualReleaseMultiple` 不再失败。
- 可能仍保留 `Test_MultiWaiters_ReleaseExactlyK` 错误（待 Task 3）。

### Task 3: GREEN-2 修复 MultiWaiters 崩溃

**Files:**
- Modify: `tests/fafafa.core.sync.sem/fafafa.core.sync.sem.enhanced.testcase.pas`

**Step 1: Minimal fix**
- 新增显式等待线程类（替代 `CreateAnonymousThread` 闭包写数组）。
- `Test_MultiWaiters_ReleaseExactlyK` 改为线程对象结果汇总，避免闭包捕获索引导致越界。

**Step 2: Verify + Regression**
Run:
- `cd tests/fafafa.core.sync.sem && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.sem.enhanced.test.lpr`
- `./bin/fafafa.core.sync.sem.enhanced.test | tee /tmp/sem-enhanced-b51-green2.log >/dev/null`
- `rg -n "Tests run:|Failures:|Errors:|Test_Guard_ManualReleaseMultiple|Test_MultiWaiters_ReleaseExactlyK|<failure|<error" /tmp/sem-enhanced-b51-green2.log`

Expected:
- `Tests run: 42`
- `Failures: 0`
- `Errors: 0`

### Task 4: 记录与回写

**Files:**
- Modify: `task_plan.md`
- Modify: `findings.md`
- Modify: `progress.md`

**Step 1: Update evidence**
- 写入 RED/GREEN 命令、关键输出、剩余风险。
