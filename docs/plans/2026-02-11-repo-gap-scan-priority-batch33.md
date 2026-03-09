# Repo Gap Scan Priority Batch-33 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 执行 Batch-D 起始项（Task 21-23），替换 `vecdeque_clean` 队列安全读取占位：
- `Test_Peek`
- `Test_Dequeue_Safe`
- `Test_Pop_Safe`

**Architecture:** 严格 TDD：占位基线 -> RED -> GREEN -> 子批回归。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`。

---

## 执行记录（2026-02-11）

### Task 21: `Test_Peek`
1) RED：最小失败断言后 `N:1 E:0 F:1`（`RED_Peek`）
2) GREEN：实现 `Peek` 返回尾部元素、不改变计数、空容器抛 `EOutOfRange`；复验 `N:1 E:0 F:0`

### Task 22: `Test_Dequeue_Safe`
1) RED：最小失败断言后 `N:1 E:0 F:1`（`RED_Dequeue_Safe`）
2) GREEN：实现 `Dequeue(var)` 空容器 False + 值不变、非空 FIFO 行为；复验 `N:1 E:0 F:0`

### Task 23: `Test_Pop_Safe`
1) RED：最小失败断言后 `N:1 E:0 F:1`（`RED_Pop_Safe`）
2) GREEN：实现 `Pop(out)` 空容器 False、非空按前端弹出；复验 `N:1 E:0 F:0`

### 子批回归
- `Test_Peek`、`Test_Dequeue_Safe`、`Test_Pop_Safe` 串行回归均通过。

---

## 结论
- Batch-D 已完成 Task 21-23（当前进度 `3/10`）。
- 下一步建议：继续 Task 24-30（`Swap/Copy/Fill/Zero/Reverse/SetCapacity/GrowStrategy`）。
