# Repo Gap Scan Priority Batch-31 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 执行 Batch-C 前两项（Task 11-12），替换 `vecdeque_clean` 指针访问占位：
- `Test_GetPtr`
- `Test_GetPtrUnChecked`

**Architecture:** 严格 TDD：占位基线 -> RED -> GREEN -> 目标回归。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`。

---

## 执行记录（2026-02-11）

### Task 11: `Test_GetPtr`
1) 占位基线：`N:1 E:0 F:0`
2) RED：最小失败断言后 `N:1 E:0 F:1`（`GetPtr 应执行实际断言`）
3) GREEN：实现指针读取/写回、wrap 场景映射与越界异常断言；复验 `N:1 E:0 F:0`

### Task 12: `Test_GetPtrUnChecked`
1) 占位基线：`N:1 E:0 F:0`
2) RED：最小失败断言后 `N:1 E:0 F:1`（`GetPtrUnChecked 应执行实际断言`）
3) GREEN：实现指针读取/写回与 wrap 场景映射断言；复验 `N:1 E:0 F:0`

### 目标回归
- `Test_GetPtr`、`Test_GetPtrUnChecked` 串行回归均通过。

---

## 结论
- Batch-C 已完成 Task 11-12。
- 下一步建议：继续 Task 13-20（`Resize/Ensure/Add/Enqueue/Push/Dequeue/Pop`）。
