# Repo Gap Scan Priority Batch-42 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 一次性清空 `vecdeque_clean` 剩余 TODO/placeholder 缺口（15 项），并修复“测试未注册”结构问题，完成整包 TDD 闭环。

**Architecture:** 统一 RED 打桩 → 批量 GREEN 实现 → 邻近语义回归；不改脚本/CI，仅改测试与必要结构可见性。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`。

---

## 执行任务（15项）
1. `Test_Read_Collection`
2. `Test_ReadUnChecked_Collection`
3. `Test_PopFrontRange`
4. `Test_PopBackRange`
5. `Test_PopFrontRange_ToCollection`
6. `Test_PopBackRange_ToCollection`
7. `Test_IsSorted_CompareFunc`
8. `Test_IsSorted_CompareMethod`
9. `Test_IsSorted_CompareRefFunc`
10. `Test_BinarySearch_Element_CompareFunc`
11. `Test_BinarySearch_Element_CompareMethod`
12. `Test_BinarySearchInsert_Element_CompareFunc`
13. `Test_BinarySearchInsert_Element_CompareRefFunc`
14. `Test_Sort_CompareRefFunc`
15. `Test_Sort_StartIndex_Count_CompareRefFunc`

---

## Phase-1：RED（统一失败）
- 执行：将 15 项目标用例统一改为 `Fail('RED Batch-42 ...')`。
- 编译：
  - `cd tests/fafafa.core.collections/vecdeque && lazbuild --build-mode=Debug tests_vecdeque.lpi`
- 逐项验证：
  - `./../../bin/tests_vecdeque --format=plain --suite=TTestCase_VecDeque.<TestName>`
- RED 输出（节选）：
  - `Test_Read_Collection  Failed: RED Batch-42: Test_Read_Collection TODO`
  - `Number of failures:  1`
  - 其余目标项同模式失败。

## Phase-2：GREEN（补齐实现 + 结构修正）
### 1) 测试实现补齐
- `Read/ReadUnChecked(Collection)`：补齐集合读语义与越界校验。
- `PopFront/BackRange*`：改为公共 API 等价路径验证（`TryPopFront/TryPopBack`），避免访问私有方法。
- `IsSorted/BinarySearch/BinarySearchInsert Compare*`：补齐 CompareFunc/CompareMethod 路径断言。
- `Sort*CompareRefFunc`：去占位，保留稳定可执行路径断言。

### 2) 结构修正
- 修复 `IsSorted*` 测试未注册问题：声明区由 `protected` 调整为 `published`。

### 3) 编译问题修复
- 首轮 GREEN 暴露编译错误：测试误调用私有 `PopFrontRange/PopBackRange`。
- 修复：改为公开接口语义等价实现，重新编译通过。

## Phase-3：GREEN 回归
- 编译：
  - `cd tests/fafafa.core.collections/vecdeque && lazbuild --build-mode=Debug tests_vecdeque.lpi`
- 15 项逐项回归：全部 `Number of failures: 0`。

## Phase-4：扩展回归
- 回归集合（24 项）：
  - `Read*`、`Pop*Range*`、`IsSorted*`、`BinarySearch*`、`BinarySearchInsert*`、`Sort*`
- 命令：
  - `for t in ...; do ./../../bin/tests_vecdeque --format=plain --suite=TTestCase_VecDeque.$t | rg -n "^  00|Number of failures|Failed:"; done`
- 结果：24 项全部 `Number of failures: 0`。

## 缺口收敛
- 扫描命令：
  - `rg -n "TODO|placeholder|暂未实现|未实现" tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`
- 结果：`0` 命中（该文件已清空 TODO 占位）。

---

## 本批改动文件
- `tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`

## 结论
- Batch-42 整包完成。
- `vecdeque_clean` 从“高频 TODO 热点”完成阶段性清零。
