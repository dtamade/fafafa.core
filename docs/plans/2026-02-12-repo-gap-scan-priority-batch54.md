# Repo Gap Scan Priority Batch-54 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在全仓复扫后，收敛 `tests/fafafa.core.collections/vec/Test_vec.pas` 中 4 个 UnChecked RefFunc 临时跳过测试，替换为真实断言并保持 vec 子集稳定通过。

**Architecture:** 先固化“占位真通过”基线，再统一 RED（显式失败）验证，再实现最小真实语义断言（Sort/IsSorted/BinarySearch/BinarySearchInsert 的 RefFunc 路径），最后进行目标回归与 `TTestCase_Vec` 子集回归。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.collections/vec/Test_vec.pas`、`tests/fafafa.core.collections/vec/tests_vec.lpr`、`src/fafafa.core.collections.vec.pas`（只读语义对齐）。

---

## 全仓扫描快照（2026-02-12 Batch-54）
- `rg --files src tests examples benchmarks docs | wc -l` => `4820`
- `rg -n --glob 'src/**/*.pas' "TODO|FIXME|未实现|待实现|暂未|placeholder" | wc -l` => `47`
- `rg -n --glob 'tests/**/*.pas' "\{ TODO: 实现 \}|待实现', True\)|TODO|placeholder|暂未实现|未实现" | wc -l` => `55`
- `find tests -mindepth 1 -maxdepth 1 -type d -name 'fafafa.core*' | wc -l` => `151`

## 优先级（可执行性优先）
- `P0`：`tests/fafafa.core.collections/vec/Test_vec.pas` 4 个活跃入口占位测试（`tests_vec.lpr` 已注册可执行）。
  - `Test_SortUnChecked_RefFunc`
  - `Test_IsSortedUnChecked_RefFunc`
  - `Test_BinarySearchUnChecked_RefFunc`
  - `Test_BinarySearchInsertUnChecked_RefFunc`
- `P1`：`tests/fafafa.core.socket/Test_fafafa_core_socket.pas`
- `P2`：`tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.testcase.old.pas`（当前不在活跃 `lpr` 入口）

---

### Task 1: RED 基线（4 项统一显式失败）

**Files:**
- Modify: `tests/fafafa.core.collections/vec/Test_vec.pas`

**Step 1: Write failing tests**
- 将以下 4 项在 `{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}` 分支改为 `Fail('RED Batch-54: ...')`：
  - `Test_SortUnChecked_RefFunc`
  - `Test_IsSortedUnChecked_RefFunc`
  - `Test_BinarySearchUnChecked_RefFunc`
  - `Test_BinarySearchInsertUnChecked_RefFunc`

**Step 2: Compile + verify RED**
Run:
- `cd /home/dtamade/projects/fafafa.core && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUtests/fafafa.core.collections/vec/lib -Fi./src -Fu./src -Fu./tests -Fu./tests/fafafa.core.collections/vec tests/fafafa.core.collections/vec/tests_vec.lpr`
- `./bin/tests_vec --format=plain --suite=TTestCase_Vec.Test_SortUnChecked_RefFunc | tee /tmp/vec-b54-red-1.log >/dev/null`
- `./bin/tests_vec --format=plain --suite=TTestCase_Vec.Test_IsSortedUnChecked_RefFunc | tee /tmp/vec-b54-red-2.log >/dev/null`
- `./bin/tests_vec --format=plain --suite=TTestCase_Vec.Test_BinarySearchUnChecked_RefFunc | tee /tmp/vec-b54-red-3.log >/dev/null`
- `./bin/tests_vec --format=plain --suite=TTestCase_Vec.Test_BinarySearchInsertUnChecked_RefFunc | tee /tmp/vec-b54-red-4.log >/dev/null`
- `rg -n "RED Batch-54|Number of failures:" /tmp/vec-b54-red-1.log /tmp/vec-b54-red-2.log /tmp/vec-b54-red-3.log /tmp/vec-b54-red-4.log`

Expected:
- 四项均 `Number of failures: 1`。

### Task 2: GREEN 实现（最小真实语义断言）

**Files:**
- Modify: `tests/fafafa.core.collections/vec/Test_vec.pas`

**Step 1: Minimal implementation**
- `Test_SortUnChecked_RefFunc`：使用 `SizeInt` 返回的匿名比较器验证降序排序。
- `Test_IsSortedUnChecked_RefFunc`：验证已排序返回 `True`，逆序返回 `False`。
- `Test_BinarySearchUnChecked_RefFunc`：验证命中索引与未命中负值语义。
- `Test_BinarySearchInsertUnChecked_RefFunc`：验证未命中返回负编码插入点，命中返回非负索引。

**Step 2: Compile + verify GREEN**
Run:
- `cd /home/dtamade/projects/fafafa.core && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUtests/fafafa.core.collections/vec/lib -Fi./src -Fu./src -Fu./tests -Fu./tests/fafafa.core.collections/vec tests/fafafa.core.collections/vec/tests_vec.lpr`
- `./bin/tests_vec --format=plain --suite=TTestCase_Vec.Test_SortUnChecked_RefFunc | tee /tmp/vec-b54-green-1.log >/dev/null`
- `./bin/tests_vec --format=plain --suite=TTestCase_Vec.Test_IsSortedUnChecked_RefFunc | tee /tmp/vec-b54-green-2.log >/dev/null`
- `./bin/tests_vec --format=plain --suite=TTestCase_Vec.Test_BinarySearchUnChecked_RefFunc | tee /tmp/vec-b54-green-3.log >/dev/null`
- `./bin/tests_vec --format=plain --suite=TTestCase_Vec.Test_BinarySearchInsertUnChecked_RefFunc | tee /tmp/vec-b54-green-4.log >/dev/null`
- `rg -n "Number of run tests:|Number of errors:|Number of failures:" /tmp/vec-b54-green-1.log /tmp/vec-b54-green-2.log /tmp/vec-b54-green-3.log /tmp/vec-b54-green-4.log`

Expected:
- 四项均 `Number of failures: 0`、`Number of errors: 0`。

### Task 3: 回归与记录同步

**Files:**
- Modify: `task_plan.md`
- Modify: `findings.md`
- Modify: `progress.md`

**Step 1: Regression**
Run:
- `cd /home/dtamade/projects/fafafa.core && ./bin/tests_vec --format=plain --suite=TTestCase_Vec | tee /tmp/vec-b54-reg.log >/dev/null`
- `rg -n "Number of run tests:|Number of errors:|Number of failures:" /tmp/vec-b54-reg.log`

Expected:
- `TTestCase_Vec` 子集 `errors=0`, `failures=0`。

**Step 2: Update planning files**
- 记录 Batch-54 扫描快照、RED/GREEN/回归命令与关键输出。
