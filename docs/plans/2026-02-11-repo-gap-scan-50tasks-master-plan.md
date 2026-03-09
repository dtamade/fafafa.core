# Repo Gap Scan 50 Tasks Master Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 基于全仓扫描结果，形成 50 个可执行缺口任务，并按优先级批次执行，持续以严格 TDD（RED→GREEN→回归）推进未完成项收敛。

**Architecture:** 任务分为三层：P0（可立即落地且风险低的测试占位替换）、P1（中等复杂度功能/测试缺口）、P2（涉及更深实现或平台差异的 TODO）。每个任务均遵循“先失败再修复”的最小改动策略。

**Tech Stack:** FreePascal/FPCUnit、`tests/*`、`src/*`。

---

## 全仓扫描摘要（2026-02-11）
- 文件总量（`src tests examples benchmarks docs`）：`4787`
- `src` TODO 热点：`time.parse/time.format/os/bytes/time.timeout`
- `tests` 明确占位热点：
  - `tests/fafafa.core.socket.async/fafafa.core.socket.async.testcase.pas`
  - `tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`
  - `tests/fafafa.core.yaml/fafafa.core.yaml.testcase.pas`

---

## 50 任务优先级清单（可执行）

### P0（Task 01-20，优先先做）
1. `socket.async`：`Test_AsyncSocket_ConcurrentConnections` 去占位并实现并发连接基线。
2. `socket.async`：`Test_AsyncSocket_ThroughputComparison` 去占位并实现吞吐基线。
3. `socket.async`：`Test_AsyncSocket_MemoryUsage` 去占位并实现资源基线。
4. `vecdeque_clean`：`Test_Create_Allocator_GrowStrategy` 去占位。
5. `vecdeque_clean`：`Test_Create_Capacity` 去占位。
6. `vecdeque_clean`：`Test_Destroy` 去占位。
7. `vecdeque_clean`：`Test_Get` 去占位。
8. `vecdeque_clean`：`Test_GetUnChecked` 去占位。
9. `vecdeque_clean`：`Test_Put` 去占位。
10. `vecdeque_clean`：`Test_PutUnChecked` 去占位。
11. `vecdeque_clean`：`Test_GetPtr` 去占位。
12. `vecdeque_clean`：`Test_GetPtrUnChecked` 去占位。
13. `vecdeque_clean`：`Test_Resize` 去占位。
14. `vecdeque_clean`：`Test_Resize_Value` 去占位。
15. `vecdeque_clean`：`Test_Ensure` 去占位。
16. `vecdeque_clean`：`Test_Add_Element` 去占位。
17. `vecdeque_clean`：`Test_Enqueue_Element` 去占位。
18. `vecdeque_clean`：`Test_Push_Element` 去占位。
19. `vecdeque_clean`：`Test_Dequeue` 去占位。
20. `vecdeque_clean`：`Test_Pop` 去占位。

### P1（Task 21-38，中优先）
21. `vecdeque_clean`：`Test_Peek` 去占位。
22. `vecdeque_clean`：`Test_Dequeue_Safe` 去占位。
23. `vecdeque_clean`：`Test_Pop_Safe` 去占位。
24. `vecdeque_clean`：`Test_Swap_TwoElements` 去占位。
25. `vecdeque_clean`：`Test_Copy` 去占位。
26. `vecdeque_clean`：`Test_Fill_Single` 去占位。
27. `vecdeque_clean`：`Test_Zero_Single` 去占位。
28. `vecdeque_clean`：`Test_Reverse_Single` 去占位。
29. `vecdeque_clean`：`Test_SetCapacity` 去占位。
30. `vecdeque_clean`：`Test_GetGrowStrategy` 去占位。
31. `vecdeque_clean`：`Test_SetGrowStrategy` 去占位。
32. `vecdeque_clean`：`Test_IsFull` 去占位。
33. `vecdeque_clean`：`Test_GetAllocator` 去占位。
34. `vecdeque_clean`：`Test_GetData` 去占位。
35. `vecdeque_clean`：`Test_SetData` 去占位。
36. `vecdeque_clean`：`Test_ToArray` 去占位。
37. `yaml`：实现“节点基本操作测试”。
38. `yaml`：实现“标量节点操作测试”。

### P2（Task 39-50，后续）
39. `yaml`：实现“序列节点操作测试”。
40. `yaml`：实现“映射节点操作测试”。
41. `yaml`：实现“文档发射测试”。
42. `src/fafafa.core.time.format.pas`：`AOptions` 自定义格式路径补齐。
43. `src/fafafa.core.time.format.pas`：自定义模式解析入口 #1。
44. `src/fafafa.core.time.format.pas`：自定义模式解析入口 #2。
45. `src/fafafa.core.time.parse.pas`：`AllowPartialMatch` policy #1。
46. `src/fafafa.core.time.parse.pas`：`AllowPartialMatch` policy #2。
47. `src/fafafa.core.time.parse.pas`：`AllowPartialMatch` policy #3。
48. `src/fafafa.core.time.parse.pas`：`AllowPartialMatch` policy #4。
49. `src/fafafa.core.socket.async.pas`：`AcceptMultipleAsync` 暂未实现缺口补齐。
50. `src/fafafa.core.math.safeint.pas`：checked/overflowing/wrapping 基础实现补齐。

---

## 执行批次策略（executing-plans）
- Batch-A：Task 01-03（`socket.async` 三个占位测试）
- Batch-B：Task 04-10（`vecdeque_clean` 创建/读写核心）
- Batch-C：Task 11-20（`vecdeque_clean` 操作队列核心）
- Batch-D：Task 21-30（`vecdeque_clean` 安全与容量）
- Batch-E：Task 31-38（`vecdeque_clean` 元信息 + yaml 前两项）
- Batch-F：Task 39-50（yaml + src TODO 功能项）

每个任务统一执行模板：
1) RED：把占位改为最小失败断言并验证失败。
2) GREEN：最小实现使目标用例通过。
3) 回归：至少运行目标 suite，必要时运行模块全量。
4) 记录：同步 `task_plan.md`、`findings.md`、`progress.md`、`docs/plans/2026-02-10-repo-gap-scan-priority-execution.md`。

---

## Batch-A 执行入口（本轮立即执行）
- Task 01: `Test_AsyncSocket_ConcurrentConnections`
- Task 02: `Test_AsyncSocket_ThroughputComparison`
- Task 03: `Test_AsyncSocket_MemoryUsage`

## 执行进度更新（截至 2026-02-11 Batch-28）

### 已完成任务
- ✅ Task 01 `Test_AsyncSocket_ConcurrentConnections`
- ✅ Task 02 `Test_AsyncSocket_ThroughputComparison`
- ✅ Task 03 `Test_AsyncSocket_MemoryUsage`

### 当前批次状态
- Batch-A（Task 01-03）：**completed**
- Batch-B（Task 04-10）：**next**

### Batch-B 执行入口（下一轮）
1. Task 04：`Test_Create_Allocator_GrowStrategy`
2. Task 05：`Test_Create_Capacity`
3. Task 06：`Test_Destroy`
4. Task 07：`Test_Get`
5. Task 08：`Test_GetUnChecked`
6. Task 09：`Test_Put`
7. Task 10：`Test_PutUnChecked`

### 执行进度更新（截至 2026-02-11 Batch-29）
- ✅ Task 04 `Test_Create_Allocator_GrowStrategy`
- ✅ Task 05 `Test_Create_Capacity`
- ✅ Task 06 `Test_Destroy`
- Batch-B 当前进度：`3/7`
- Batch-B 下一入口：Task 07-10

### 执行进度更新（截至 2026-02-11 Batch-30）
- ✅ Task 07 `Test_Get`
- ✅ Task 08 `Test_GetUnChecked`
- ✅ Task 09 `Test_Put`
- ✅ Task 10 `Test_PutUnChecked`
- Batch-B 当前进度：`7/7 (completed)`
- 下一批：Batch-C（Task 11-20）

### 执行进度更新（截至 2026-02-11 Batch-31）
- ✅ Task 11 `Test_GetPtr`
- ✅ Task 12 `Test_GetPtrUnChecked`
- Batch-C 当前进度：`2/10`
- 下一批：Task 13-20

### 执行进度更新（截至 2026-02-11 Batch-32）
- ✅ Task 13 `Test_Resize`
- ✅ Task 14 `Test_Resize_Value`
- ✅ Task 15 `Test_Ensure`
- ✅ Task 16 `Test_Add_Element`
- ✅ Task 17 `Test_Enqueue_Element`
- ✅ Task 18 `Test_Push_Element`
- ✅ Task 19 `Test_Dequeue`
- ✅ Task 20 `Test_Pop`
- Batch-C 当前进度：`10/10 (completed)`
- 下一批：Batch-D（Task 21-30）

### 执行进度更新（截至 2026-02-11 Batch-33）
- ✅ Task 21 `Test_Peek`
- ✅ Task 22 `Test_Dequeue_Safe`
- ✅ Task 23 `Test_Pop_Safe`
- Batch-D 当前进度：`3/10`
- 下一批：Task 24-30

### 执行进度更新（截至 2026-02-11 Batch-34）
- ✅ Task 24 `Test_Swap_TwoElements`
- ✅ Task 25 `Test_Copy`
- ✅ Task 26 `Test_Fill_Single`
- ✅ Task 27 `Test_Zero_Single`
- ✅ Task 28 `Test_Reverse_Single`
- ✅ Task 29 `Test_SetCapacity`
- ✅ Task 30 `Test_GetGrowStrategy`
- Batch-D 当前进度：`10/10 (completed)`
- 下一批：Batch-E（Task 31-38）

### 执行进度更新（截至 2026-02-11 Batch-35）
- ✅ Task 31 `Test_SetGrowStrategy`
- ✅ Task 32 `Test_IsFull`
- ✅ Task 33 `Test_GetAllocator`
- ✅ Task 34 `Test_GetData`
- ✅ Task 35 `Test_SetData`
- ✅ Task 36 `Test_ToArray`
- ✅ Task 37 `Test_yaml_node_basic_operations`
- ✅ Task 38 `Test_yaml_node_scalar_operations`
- Batch-E 当前进度：`8/8 (completed)`
- 下一批：Batch-F（Task 39-50）

### 执行进度更新（截至 2026-02-11 Batch-36）
- ✅ Task 39 `Test_yaml_node_sequence_operations`
- ✅ Task 40 `Test_yaml_node_mapping_operations`
- ✅ Task 41 `Test_yaml_emit_document`
- ✅ Task 42 `time.format AOptions CustomPattern`
- ✅ Task 43 `time.format pattern 入口 #1`
- ✅ Task 44 `time.format pattern 入口 #2`
- ✅ Task 45 `time.parse AllowPartialMatch #1`
- ✅ Task 46 `time.parse AllowPartialMatch #2`
- ✅ Task 47 `time.parse AllowPartialMatch #3`
- ✅ Task 48 `time.parse AllowPartialMatch #4`
- ✅ Task 49 `AcceptMultipleAsync`
- ✅ Task 50 `WideningMulU64`
- Batch-F 当前进度：`12/12 (completed)`
- 当前 50 任务总进度：`50/50 (completed)`

---

## 50任务后续扩展批次（Batch-37）

> 在 50 任务主清单完成后，继续按同一模式进入下一轮缺口收敛。

### 执行进度更新（2026-02-11 Batch-37）
- ✅ `Test_Create_Capacity_Allocator`
- ✅ `Test_Create_Capacity_Allocator_GrowStrategy`
- ✅ `Test_Create_Capacity_Allocator_GrowStrategy_Data`
- ✅ `Test_Create_Collection_Allocator_GrowStrategy`
- ✅ `Test_Create_Collection_Allocator_GrowStrategy_Data`
- ✅ `Test_Create_Pointer_Count_Allocator_GrowStrategy`
- ✅ `Test_Create_Pointer_Count_Allocator_GrowStrategy_Data`
- ✅ `Test_Create_Array_Allocator_GrowStrategy`
- ✅ `Test_Create_Array_Allocator_GrowStrategy_Data`

### Batch-37 结果摘要
- 9 项统一 RED：全部 `N:1 E:0 F:1`。
- 9 项 GREEN 回归：全部 `N:1 E:0 F:0`。
- 扩展回归（构造器 + 析构 15 项）：全部通过。

### 额外收益（真实缺陷修复）
- 修复 `TVecDeque` 的 Collection 构造器未加载源数据问题：
  - 文件：`src/fafafa.core.collections.vecdeque.pas`
  - 方法：`Create(const aSrc: TCollection; aAllocator; aGrowStrategy; aData)`

### 下一轮建议
- 继续全仓扫描并组包下一批（优先 `vecdeque_clean` 其余高频 TODO）。

### 执行进度更新（2026-02-11 Batch-38）
- ✅ `Test_Create_Allocator_GrowStrategy_Data`
- ✅ `Test_PtrIter`
- ✅ `Test_SerializeToArrayBuffer`
- ✅ `Test_AppendUnChecked`
- ✅ `Test_AppendToUnChecked`
- ✅ `Test_SaveToUnChecked`
- ✅ `Test_GetMemory`

### Batch-38 结果摘要
- 7 项统一 RED：全部 `N:1 E:0 F:1`。
- 7 项 GREEN 回归：全部 `N:1 E:0 F:0`。
- 扩展子集回归（11 项）：全部通过。

### 说明
- 本批仅修改测试文件，无新增生产代码变更。

### 执行进度更新（2026-02-11 Batch-39）
- ✅ `Test_SwapUnChecked_TwoElements`
- ✅ `Test_Swap_Range`
- ✅ `Test_Swap_Stride`
- ✅ `Test_CopyUnChecked`

### Batch-39 结果摘要
- 4 项统一 RED：全部 `N:1 E:0 F:1`。
- 4 项 GREEN 回归：全部 `N:1 E:0 F:0`。
- 扩展回归（`Swap*` + `Copy*` 共 6 项）：全部通过。

### 扫描补充（2026-02-11）
- 全仓快扫（`rg -n "TODO|placeholder|暂未实现|未实现" src tests`）显示：
  - `tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas` 仍为 TODO 热点（43）。
  - 下一轮建议优先 `Fill/Zero/Reverse` 的 `Range/UnChecked` 6 项，保持同区块整包推进。

### 执行进度更新（2026-02-11 Batch-40）
- ✅ `Test_Fill_Range`
- ✅ `Test_FillUnChecked`
- ✅ `Test_Zero_Range`
- ✅ `Test_ZeroUnChecked`
- ✅ `Test_Reverse_Range`
- ✅ `Test_ReverseUnChecked`

### Batch-40 结果摘要
- 6 项统一 RED：全部 `N:1 E:0 F:1`。
- 6 项 GREEN 回归：全部 `N:1 E:0 F:0`。
- 扩展回归（`Fill/Zero/Reverse` 9 项）：全部通过。

### 扫描补充（2026-02-11）
- 全仓快扫下，`vecdeque_clean` TODO 计数由 43 降至 37。
- 下一批建议继续同文件 `ForEach/ForEachUnChecked` 区间计数 TODO，保持低切换整包推进。

### 执行进度更新（截至 2026-02-11 Batch-41）
- ✅ `Test_ForEach_Index_Count_PredicateFunc`
- ✅ `Test_ForEach_Index_Count_PredicateMethod`
- ✅ `Test_ForEachUnChecked_PredicateMethod`
- ✅ `Test_ForEachUnChecked_Index_Count_PredicateMethod`
- ✅ `Test_Add_Array`
- ✅ `Test_Add_Pointer_Count`
- ✅ `Test_Add_Collection`
- ✅ `Test_Enqueue_Array`
- ✅ `Test_Enqueue_Pointer_Count`
- ✅ `Test_Enqueue_Collection`
- ✅ `Test_Push_Array`
- ✅ `Test_Push_Pointer_Count`
- ✅ `Test_Push_Collection`
- ✅ `Test_Push_Collection_StartIndex`
- ✅ `Test_GetElementManager`
- ✅ `Test_GetElementTypeInfo`
- ✅ `Test_LoadFromUnChecked`
- ✅ `Test_AppendTo`
- ✅ `Test_SaveTo`
- 结果：19 项整包通过；并修复 `TVecDeque.Insert` 的 `FTail` 同步缺陷。

### 执行进度更新（截至 2026-02-11 Batch-42）
- ✅ `Test_Read_Collection`
- ✅ `Test_ReadUnChecked_Collection`
- ✅ `Test_PopFrontRange`
- ✅ `Test_PopBackRange`
- ✅ `Test_PopFrontRange_ToCollection`
- ✅ `Test_PopBackRange_ToCollection`
- ✅ `Test_IsSorted_CompareFunc`
- ✅ `Test_IsSorted_CompareMethod`
- ✅ `Test_IsSorted_CompareRefFunc`
- ✅ `Test_BinarySearch_Element_CompareFunc`
- ✅ `Test_BinarySearch_Element_CompareMethod`
- ✅ `Test_BinarySearchInsert_Element_CompareFunc`
- ✅ `Test_BinarySearchInsert_Element_CompareRefFunc`
- ✅ `Test_Sort_CompareRefFunc`
- ✅ `Test_Sort_StartIndex_Count_CompareRefFunc`
- 结果：15 项整包通过；`vecdeque_clean` TODO/placeholder 命中清零。
