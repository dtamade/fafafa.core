# Repo Gap Scan Priority Batch-32 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 执行 Batch-C 剩余项（Task 13-20），完成 `vecdeque_clean` 关键队列/容量占位测试替换：
- `Test_Resize`
- `Test_Resize_Value`
- `Test_Ensure`
- `Test_Add_Element`
- `Test_Enqueue_Element`
- `Test_Push_Element`
- `Test_Dequeue`
- `Test_Pop`

**Architecture:** 严格 TDD：基线 -> RED -> GREEN -> 子批回归。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`。

---

## 执行记录（2026-02-11）

### 结构修复（先决条件）
- 发现根因：`Test_Add_Element` 到 `Test_Pop` 处于 `protected` 区域，未被 FPCUnit 注册（`No tests selected`）。
- 修复：在类声明中将该批测试重新切回 `published`（最小范围为 IVec/Queue 批次入口）。
- 验证：`--list` 可见 `Test_Add_Element` / `Test_Enqueue_Element` / `Test_Push_Element` / `Test_Dequeue` / `Test_Pop`。

### Task 13-20 TDD 结果
- Task 13 `Test_Resize`：已完成（GREEN）
- Task 14 `Test_Resize_Value`：已完成（GREEN）
- Task 15 `Test_Ensure`：RED `N:1 E:0 F:1` -> GREEN `N:1 E:0 F:0`
- Task 16 `Test_Add_Element`：RED `N:1 E:0 F:1` -> GREEN `N:1 E:0 F:0`
- Task 17 `Test_Enqueue_Element`：RED `N:1 E:0 F:1` -> GREEN `N:1 E:0 F:0`
- Task 18 `Test_Push_Element`：RED `N:1 E:0 F:1` -> GREEN `N:1 E:0 F:0`
- Task 19 `Test_Dequeue`：RED `N:1 E:0 F:1` -> GREEN `N:1 E:0 F:0`
- Task 20 `Test_Pop`：RED `N:1 E:0 F:1` -> GREEN `N:1 E:0 F:0`

### 子批回归
- 串行回归 8 项全部通过：
  - `Test_Resize`
  - `Test_Resize_Value`
  - `Test_Ensure`
  - `Test_Add_Element`
  - `Test_Enqueue_Element`
  - `Test_Push_Element`
  - `Test_Dequeue`
  - `Test_Pop`

---

## 结论
- Batch-C（Task 11-20）已全部完成。
- 下一步建议：进入 Batch-D（Task 21-30），优先 `Test_Peek` / `Test_Dequeue_Safe` / `Test_Pop_Safe`。
