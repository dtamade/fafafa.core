# Repo Gap Scan Priority Batch-30 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 执行 Batch-B 剩余任务（Task 07-10），替换 `vecdeque_clean` IArray 基础访问占位：
- `Test_Get`
- `Test_GetUnChecked`
- `Test_Put`
- `Test_PutUnChecked`

**Architecture:** 严格 TDD：每个任务均执行 占位基线 -> RED -> GREEN -> 目标回归。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`。

---

## 执行记录（2026-02-11）

### Task 07: `Test_Get`
1) 占位基线：`N:1 E:0 F:0`
2) RED（最小失败断言）：`N:1 E:0 F:1`（`Get 应执行实际断言`）
3) GREEN：实现顺序读 + wrap 后逻辑顺序 + 越界异常断言；复验 `N:1 E:0 F:0`

### Task 08: `Test_GetUnChecked`
1) 占位基线：`N:1 E:0 F:0`
2) RED（最小失败断言）：`N:1 E:0 F:1`（`GetUnChecked 应执行实际断言`）
3) GREEN：实现顺序读 + wrap 后逻辑顺序断言；复验 `N:1 E:0 F:0`

### Task 09: `Test_Put`
1) 占位基线：`N:1 E:0 F:0`
2) RED（最小失败断言）：`N:1 E:0 F:1`（`Put 应执行实际断言`）
3) GREEN：实现常规写 + wrap 后写 + 越界异常断言；复验 `N:1 E:0 F:0`

### Task 10: `Test_PutUnChecked`
1) 占位基线：`N:1 E:0 F:0`
2) RED（最小失败断言）：`N:1 E:0 F:1`（`PutUnChecked 应执行实际断言`）
3) GREEN：实现常规写 + wrap 后写断言；复验 `N:1 E:0 F:0`

### 目标回归（Task04-10）
- 命令（串行执行 7 个目标用例）：
  - `for t in Test_Create_Allocator_GrowStrategy Test_Create_Capacity Test_Destroy Test_Get Test_GetUnChecked Test_Put Test_PutUnChecked; do ./bin/tests_vecdeque --format=plain --suite=TTestCase_VecDeque.$t; done`
- 输出：7 项全部 `N:1 E:0 F:0`

---

## 结论
- Batch-B（Task 04-10）已全部完成。
- 下一批入口：Batch-C（Task 11-20，`GetPtr/GetPtrUnChecked/Resize/.../Pop`）。
