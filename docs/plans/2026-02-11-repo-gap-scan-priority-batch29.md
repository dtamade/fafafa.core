# Repo Gap Scan Priority Batch-29 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 执行 Batch-B 前三项（Task 04-06），替换 `vecdeque_clean` 占位测试：
- `Test_Create_Allocator_GrowStrategy`
- `Test_Create_Capacity`
- `Test_Destroy`

**Architecture:** 严格 TDD：每个任务先 RED（最小失败断言）→ GREEN（最小真实断言实现）→ 目标用例复验。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`。

---

## 扫描结论（2026-02-11）
- `Test_vecdeque_clean.pas` 中上述 3 个目标均为 `TODO` 占位实现。
- 当前模块存在历史已知失败：`Test_Contains_Element_Index_Count`，不属于本批范围。

---

## 执行记录（2026-02-11）

### Task 04: `Test_Create_Allocator_GrowStrategy`
1) 占位基线
- `cd tests/fafafa.core.collections/vecdeque && ./bin/tests_vecdeque --format=plain --suite=TTestCase_VecDeque.Test_Create_Allocator_GrowStrategy`
- 输出：`N:1 E:0 F:0`

2) RED
- 占位改最小失败断言后：
- `fpc ... tests_vecdeque.lpr && ./bin/tests_vecdeque --format=plain --suite=TTestCase_VecDeque.Test_Create_Allocator_GrowStrategy`
- 输出：`N:1 E:0 F:1`（`Create(aAllocator,aGrowStrategy) 应执行实际断言`）

3) GREEN
- 实现：构造 `TVecDequeInt.Create(TVecDequeInt.VECDEQUE_DEFAULT_CAPACITY, LAllocator, LGrowStrategy)`，断言分配器/策略/空状态/计数/容量/Data。
- 同命令复验：`N:1 E:0 F:0`

### Task 05: `Test_Create_Capacity`
1) 占位基线
- `./bin/tests_vecdeque --format=plain --suite=TTestCase_VecDeque.Test_Create_Capacity`
- 输出：`N:1 E:0 F:0`

2) RED
- 占位改最小失败断言后：
- `fpc ... tests_vecdeque.lpr && ./bin/tests_vecdeque --format=plain --suite=TTestCase_VecDeque.Test_Create_Capacity`
- 输出：`N:1 E:0 F:1`（`Create(aCapacity) 应执行实际断言`）

3) GREEN
- 实现：校验 `Create(10)` 与 `Create(0)` 的空状态、计数、容量下界与 2 幂约束、默认分配器。
- 同命令复验：`N:1 E:0 F:0`

### Task 06: `Test_Destroy`
1) 占位基线
- `./bin/tests_vecdeque --format=plain --suite=TTestCase_VecDeque.Test_Destroy`
- 输出：`N:1 E:0 F:0`

2) RED
- 占位改最小失败断言后：
- `fpc ... tests_vecdeque.lpr && ./bin/tests_vecdeque --format=plain --suite=TTestCase_VecDeque.Test_Destroy`
- 输出：`N:1 E:0 F:1`（`Destroy 应执行实际断言`）

3) GREEN
- 实现：三组销毁路径（空容器/有元素容器/自定义分配器容器）断言不异常并校验关键状态。
- 同命令复验：`N:1 E:0 F:0`

---

## 结论
- Batch-29 已完成 Task 04-06 的占位替换。
- 下一步：继续 Batch-B 的 Task 07-10（`Get/GetUnChecked/Put/PutUnChecked`）。
