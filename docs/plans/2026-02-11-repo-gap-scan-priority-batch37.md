# Repo Gap Scan Priority Batch-37 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 进入 50 任务完成后的下一轮缺口收敛，整包完成 `vecdeque_clean` 构造器族 9 项占位测试并闭环真实缺陷：
- `Test_Create_Capacity_Allocator`
- `Test_Create_Capacity_Allocator_GrowStrategy`
- `Test_Create_Capacity_Allocator_GrowStrategy_Data`
- `Test_Create_Collection_Allocator_GrowStrategy`
- `Test_Create_Collection_Allocator_GrowStrategy_Data`
- `Test_Create_Pointer_Count_Allocator_GrowStrategy`
- `Test_Create_Pointer_Count_Allocator_GrowStrategy_Data`
- `Test_Create_Array_Allocator_GrowStrategy`
- `Test_Create_Array_Allocator_GrowStrategy_Data`

**Architecture:** 严格 TDD（RED→GREEN→回归）。先统一将 9 项占位改为 RED 失败断言验证，再实现真实断言；若触发实现缺陷，最小修复源码并回归。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`、`src/fafafa.core.collections.vecdeque.pas`。

---

## 扫描结论（2026-02-11）
- 全仓二次扫描后，`vecdeque_clean` 在构造器区域仍有 9 个 `{ TODO: 实现 }` 空测试。
- 目标集中在同一文件、同一语义域（构造器重载），适合一次性整包 TDD 闭环。

---

## 执行记录（2026-02-11）

### Phase-1：RED（9 项统一置失败）
1) 将 9 个占位测试统一改为：`Fail('RED: ... should have real assertions')`。
2) 编译：
- `cd tests/fafafa.core.collections/vecdeque && lazbuild --build-mode=Debug tests_vecdeque.lpi`
3) 逐项执行 RED 验证：
- `./../../bin/tests_vecdeque --format=plain --suite=TTestCase_VecDeque.<TestName>`
- 结果：9 项均 `N:1 E:0 F:1`（符合 RED 预期）。

### Phase-2：GREEN（9 项真实断言实现）
1) 在 `Test_vecdeque_clean.pas` 为 9 项补齐真实断言，覆盖：
- 分配器注入
- 增长策略注入
- `aData` 透传
- `Count/IsEmpty/Capacity` 语义
- 从 `Collection/Pointer/Array` 构造的数据一致性与复制独立性

2) 首轮 GREEN 执行发现真实缺陷：
- `Test_Create_Collection_Allocator_GrowStrategy` 失败：`expected <5> but was: <0>`
- `Test_Create_Collection_Allocator_GrowStrategy_Data` 失败：`expected <3> but was: <0>`

3) 根因与修复：
- 根因：`TVecDeque.Create(const aSrc: TCollection; aAllocator; aGrowStrategy; aData)` 构造器仅初始化缓冲区，未执行 `LoadFrom(aSrc)`。
- 修复：改为复用主构造路径 `Create(0, aAllocator, aGrowStrategy, aData)` 后调用 `LoadFrom(aSrc)`。

4) 同步修正一条测试断言语义：
- `Create(aCapacity, aAllocator)` 默认增长策略按实现为 `nil`（表示使用内置 2 的幂扩容策略），断言改为 `GetGrowStrategy = nil`。

### Phase-3：回归验证
1) 重新编译：
- `cd tests/fafafa.core.collections/vecdeque && lazbuild --build-mode=Debug tests_vecdeque.lpi`

2) 9 项目标用例逐项回归：
- `Test_Create_Capacity_Allocator`
- `Test_Create_Capacity_Allocator_GrowStrategy`
- `Test_Create_Capacity_Allocator_GrowStrategy_Data`
- `Test_Create_Collection_Allocator_GrowStrategy`
- `Test_Create_Collection_Allocator_GrowStrategy_Data`
- `Test_Create_Pointer_Count_Allocator_GrowStrategy`
- `Test_Create_Pointer_Count_Allocator_GrowStrategy_Data`
- `Test_Create_Array_Allocator_GrowStrategy`
- `Test_Create_Array_Allocator_GrowStrategy_Data`
- 输出：9 项均 `N:1 E:0 F:0`。

3) 扩展构造器子集回归（防止局部修复引入回归）：
- 再串行运行 `Test_Create*` 与 `Test_Destroy` 共 15 项。
- 输出：15 项全部 `N:1 E:0 F:0`。

---

## 本批改动文件
- `tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`
- `src/fafafa.core.collections.vecdeque.pas`

## 结论
- Batch-37（下一轮扩展批次）整包完成。
- 同时修复了一个真实实现缺陷（Collection 构造器未加载源数据）。
