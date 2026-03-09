# Repo Gap Scan Priority Batch-52 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在完成全仓复扫后，优先收敛 `sync.sem.enhanced` 中 3 个活跃占位测试，确保测试语义真实可执行并保持模块全绿。

**Architecture:** 先做全仓缺口快照并确认可执行目标，然后对 3 个占位测试统一 RED（显式失败）建立基线，再以最小实现改为真实并发/恢复语义断言并做回归。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.sync.sem/fafafa.core.sync.sem.enhanced.testcase.pas`、`tests/fafafa.core.sync.sem/fafafa.core.sync.sem.enhanced.test.lpr`。

---

## 全仓扫描快照（2026-02-12 Batch-52）
- `rg --files src tests examples benchmarks docs | wc -l` => `4818`
- `rg -n --glob 'src/**/*.pas' "TODO|FIXME|未实现|待实现|暂未|placeholder" | wc -l` => `47`
- `rg -n --glob 'tests/**/*.pas' "\{ TODO: 实现 \}|待实现', True\)|TODO|placeholder|暂未实现|未实现" | wc -l` => `61`
- `find tests -mindepth 1 -maxdepth 1 -type d -name 'fafafa.core*' | wc -l` => `151`

## 优先级（可执行性优先）
- `P0`：`tests/fafafa.core.sync.sem/fafafa.core.sync.sem.enhanced.testcase.pas`（3 个占位测试在活跃 `lpr` 中，能直接验证）。
- `P1`：`tests/fafafa.core.socket/Test_fafafa_core_socket.pas`（6 占位，需网络环境约束评估）。
- `P2`：`tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.testcase.old.pas`（34 占位，但当前不在 `fafafa.core.sync.barrier.test.lpr` 编译入口内）。

---

### Task 1: RED 基线（将 3 个占位测试显式置失败）

**Files:**
- Modify: `tests/fafafa.core.sync.sem/fafafa.core.sync.sem.enhanced.testcase.pas`

**Step 1: Write failing tests**
- 将以下 3 个占位测试统一改为 `Fail('RED Batch-52: ...')`：
  - `Test_Timeout_Cancellation`
  - `Test_Timeout_MultipleWaiters`
  - `Test_Recovery_AfterException`

**Step 2: Run and verify RED**
Run:
- `cd tests/fafafa.core.sync.sem && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.sem.enhanced.test.lpr`
- `./bin/fafafa.core.sync.sem.enhanced.test --format=plain --suite=TTestCase_Enhanced | tee /tmp/sem-enhanced-b52-red.log >/dev/null`
- `rg -n "Number of run tests:|Number of failures:|Test_Timeout_Cancellation|Test_Timeout_MultipleWaiters|Test_Recovery_AfterException" /tmp/sem-enhanced-b52-red.log`

Expected:
- 目标 3 项全部失败（`Number of failures: 3`）。

### Task 2: GREEN 实现（最小真实语义）

**Files:**
- Modify: `tests/fafafa.core.sync.sem/fafafa.core.sync.sem.enhanced.testcase.pas`

**Step 1: Minimal implementation**
- `Test_Timeout_Cancellation`：验证超时等待者不会“偷走”后续释放许可。
- `Test_Timeout_MultipleWaiters`：验证分批释放可唤醒多个等待者且计数归零。
- `Test_Recovery_AfterException`：验证异常路径后信号量计数恢复且可继续获取。

**Step 2: Run and verify GREEN**
Run:
- `cd tests/fafafa.core.sync.sem && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.sem.enhanced.test.lpr`
- `./bin/fafafa.core.sync.sem.enhanced.test --format=plain --suite=TTestCase_Enhanced | tee /tmp/sem-enhanced-b52-green.log >/dev/null`
- `rg -n "Number of run tests:|Number of failures:|Number of errors:" /tmp/sem-enhanced-b52-green.log`

Expected:
- `Number of failures: 0`
- `Number of errors: 0`

### Task 3: 模块回归与记录同步

**Files:**
- Modify: `task_plan.md`
- Modify: `findings.md`
- Modify: `progress.md`

**Step 1: Module regression**
Run:
- `cd tests/fafafa.core.sync.sem && ./bin/fafafa.core.sync.sem.enhanced.test | tee /tmp/sem-enhanced-b52-regression.log >/dev/null`
- `rg -n "Tests run:|Failures:|Errors:" /tmp/sem-enhanced-b52-regression.log`

Expected:
- `Tests run: 42`
- `Failures: 0`
- `Errors: 0`

**Step 2: Update planning files**
- 在 `task_plan.md/findings.md/progress.md` 写入：扫描快照、RED/GREEN 命令、关键输出、后续优先级。
