# Repo Gap Scan Priority Batch-53 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在全仓复扫后，收敛 `tests/fafafa.core.collections/vec/Test_vec.pas` 中 3 个 `Contains_*_RefFunc` 占位测试，替换为真实匿名函数语义断言并保持 vec 模块稳定通过。

**Architecture:** 先固定现状基线（3 项占位真通过），再统一 RED（显式失败）验证，再实现最小真实断言（包含范围/起始索引/越界异常路径），最后进行目标回归与子集回归。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.collections/vec/Test_vec.pas`、`tests/fafafa.core.collections/vec/tests_vec.lpr`、`src/fafafa.core.collections.vec.pas`（只读语义对齐）。

---

## 全仓扫描快照（2026-02-12 Batch-53）
- `rg --files src tests examples benchmarks docs | wc -l` => `4819`
- `rg -n --glob 'src/**/*.pas' "TODO|FIXME|未实现|待实现|暂未|placeholder" | wc -l` => `47`
- `rg -n --glob 'tests/**/*.pas' "\{ TODO: 实现 \}|待实现', True\)|TODO|placeholder|暂未实现|未实现" | wc -l` => `58`
- `find tests -mindepth 1 -maxdepth 1 -type d -name 'fafafa.core*' | wc -l` => `151`

## 优先级（可执行性优先）
- `P0`：`tests/fafafa.core.collections/vec/Test_vec.pas` 3 个占位测试（活跃入口 `tests_vec.lpr` 已注册可执行）。
- `P1`：`tests/fafafa.core.socket/Test_fafafa_core_socket.pas`（当前命中主要来自“未实现”文案，不是占位断言）。
- `P2`：`tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.testcase.old.pas`（34 命中，但不在当前 `lpr` 活跃入口）。

---

### Task 1: RED 基线（3 项统一显式失败）

**Files:**
- Modify: `tests/fafafa.core.collections/vec/Test_vec.pas`

**Step 1: Write failing tests**
- 将以下 3 项在 `{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}` 分支下改为 `Fail('RED Batch-53: ...')`：
  - `Test_Contains_StartIndex_RefFunc`
  - `Test_Contains_StartIndex_Count_RefFunc`
  - `Test_Contains_RefFunc`

**Step 2: Compile + verify RED**
Run:
- `cd /home/dtamade/projects/fafafa.core && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUtests/fafafa.core.collections/vec/lib -Fi./src -Fu./src -Fu./tests -Fu./tests/fafafa.core.collections/vec tests/fafafa.core.collections/vec/tests_vec.lpr`
- `./bin/tests_vec --format=plain --suite=TTestCase_Vec.Test_Contains_StartIndex_RefFunc | tee /tmp/vec-b53-red-1.log >/dev/null`
- `./bin/tests_vec --format=plain --suite=TTestCase_Vec.Test_Contains_StartIndex_Count_RefFunc | tee /tmp/vec-b53-red-2.log >/dev/null`
- `./bin/tests_vec --format=plain --suite=TTestCase_Vec.Test_Contains_RefFunc | tee /tmp/vec-b53-red-3.log >/dev/null`
- `rg -n "Number of failures:|RED Batch-53" /tmp/vec-b53-red-1.log /tmp/vec-b53-red-2.log /tmp/vec-b53-red-3.log`

Expected:
- 三项均 `Number of failures: 1`。

### Task 2: GREEN 实现（最小真实语义断言）

**Files:**
- Modify: `tests/fafafa.core.collections/vec/Test_vec.pas`

**Step 1: Minimal implementation**
- `Test_Contains_StartIndex_RefFunc`：验证 startIndex 生效、命中/不命中及越界异常。
- `Test_Contains_StartIndex_Count_RefFunc`：验证 startIndex+count 范围约束、count=0、越界异常。
- `Test_Contains_RefFunc`：验证无范围时的 ref-func 语义（命中与不命中）。

**Step 2: Compile + verify GREEN**
Run:
- `cd /home/dtamade/projects/fafafa.core && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUtests/fafafa.core.collections/vec/lib -Fi./src -Fu./src -Fu./tests -Fu./tests/fafafa.core.collections/vec tests/fafafa.core.collections/vec/tests_vec.lpr`
- `./bin/tests_vec --format=plain --suite=TTestCase_Vec.Test_Contains_StartIndex_RefFunc | tee /tmp/vec-b53-green-1.log >/dev/null`
- `./bin/tests_vec --format=plain --suite=TTestCase_Vec.Test_Contains_StartIndex_Count_RefFunc | tee /tmp/vec-b53-green-2.log >/dev/null`
- `./bin/tests_vec --format=plain --suite=TTestCase_Vec.Test_Contains_RefFunc | tee /tmp/vec-b53-green-3.log >/dev/null`
- `rg -n "Number of failures:|Number of errors:" /tmp/vec-b53-green-1.log /tmp/vec-b53-green-2.log /tmp/vec-b53-green-3.log`

Expected:
- 三项均 `Number of failures: 0`、`Number of errors: 0`。

### Task 3: 回归与记录同步

**Files:**
- Modify: `task_plan.md`
- Modify: `findings.md`
- Modify: `progress.md`

**Step 1: Regression**
Run:
- `./bin/tests_vec --format=plain --suite=TTestCase_Vec | tee /tmp/vec-b53-regression-suite.log >/dev/null`
- `rg -n "Number of run tests:|Number of failures:|Number of errors:" /tmp/vec-b53-regression-suite.log`

Expected:
- `TTestCase_Vec` 子集 `errors=0`, `failures=0`。

**Step 2: Update planning files**
- 记录扫描快照、RED/GREEN/回归命令与关键输出。
