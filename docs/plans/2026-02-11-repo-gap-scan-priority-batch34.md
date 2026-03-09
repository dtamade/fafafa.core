# Repo Gap Scan Priority Batch-34 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 一次性完成 Batch-D 余下 Task 24-30（整包执行，不拆分）：
- `Test_Swap_TwoElements`
- `Test_Copy`
- `Test_Fill_Single`
- `Test_Zero_Single`
- `Test_Reverse_Single`
- `Test_SetCapacity`
- `Test_GetGrowStrategy`

**Architecture:** 严格 TDD：统一 RED 验证 -> 统一 GREEN 落地 -> Task21-30 整包回归。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`。

---

## 执行记录（2026-02-11）

### RED（统一验证）
- Task24-30 统一替换为最小失败断言并编译。
- `Swap/Copy/Fill/Zero/Reverse` 均得到 `N:1 E:0 F:1`。
- `SetCapacity/GetGrowStrategy` 初始出现 `No tests selected`，定位为测试可见性问题。

### 结构修复
- 将 IVec 批次测试声明从 `protected` 切回 `published`，使 `SetCapacity/GetGrowStrategy` 被 FPCUnit 注册。
- 修复后两项 RED 复验：
  - `Test_SetCapacity`: `N:1 E:0 F:1`（`RED_SetCapacity`）
  - `Test_GetGrowStrategy`: `N:1 E:0 F:1`（`RED_GetGrowStrategy`）

### GREEN（一次性完成）
- `Test_Swap_TwoElements`：交换结果与越界异常断言。
- `Test_Copy`：重叠复制路径与越界异常断言。
- `Test_Fill_Single`：单点填充与越界异常断言。
- `Test_Zero_Single`：单点清零与越界异常断言。
- `Test_Reverse_Single`：单点反转 no-op 与越界异常断言。
- `Test_SetCapacity`：扩容后容量/序列保持与缩到 `count` 以下异常断言。
- `Test_GetGrowStrategy`：默认 `nil`（内建增长）与 set/reset 后一致性断言。

### GREEN 验证
- Task24-30 单项复验全部通过（每项 `N:1 E:0 F:0`）。

### 整包回归（Task21-30）
- 串行回归 10 项全部通过：
  - `Test_Peek`
  - `Test_Dequeue_Safe`
  - `Test_Pop_Safe`
  - `Test_Swap_TwoElements`
  - `Test_Copy`
  - `Test_Fill_Single`
  - `Test_Zero_Single`
  - `Test_Reverse_Single`
  - `Test_SetCapacity`
  - `Test_GetGrowStrategy`

---

## 结论
- Batch-D（Task 21-30）已整包完成（`10/10`）。
- 下一步建议：进入 Batch-E（Task 31-38）。
