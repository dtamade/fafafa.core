# Repo Gap Scan Priority Batch-41 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在 Batch-40 后继续整包收敛 `vecdeque_clean` 的 19 项 TODO（`ForEach/ForEachUnChecked` 计数变体、`Add/Enqueue/Push` 批量重载、`GetElement*` 与 `Load/Append/Save` 族）。

**Architecture:** 严格 TDD（RED→GREEN→回归）。先统一 RED 暴露占位，再一次性补齐断言；如暴露真实实现缺陷，优先最小修复生产代码。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`、`src/fafafa.core.collections.vecdeque.pas`。

---

## 执行记录摘要（2026-02-11）

### Phase-1：RED（19 项）
- 19 项占位均改为显式失败并逐项验证，结果全部 `Number of failures: 1`。

### Phase-2：GREEN（19 项）
- 一次性补齐 19 项真实断言：
  - `ForEach/ForEachUnChecked`：索引+计数+谓词路径。
  - `Add/Enqueue/Push`：Array/Pointer/Collection 重载。
  - `GetElementManager/GetElementTypeInfo`：元信息一致性。
  - `LoadFromUnChecked/AppendTo/SaveTo`：集合互操作语义。

### Phase-3：真实缺陷修复（生产代码）
- 定位并修复 `Insert` 系列未同步 `FTail` 问题：
  - 文件：`src/fafafa.core.collections.vecdeque.pas`
  - 修复点：
    - `Insert(aIndex, const aPtr, aCount)`
    - `Insert(aIndex, const aArray)`
    - `Insert(aIndex, const aCollection, aStartIndex)`
  - 改动：`Inc(FCount, ...)` 后统一补 `FTail := WrapAdd(FHead, FCount);`

### Phase-4：回归
- 19 项目标用例逐项回归全部 `Number of failures: 0`。
- 当前轮复验命令：
  - `cd tests/fafafa.core.collections/vecdeque && for t in ...; do ./../../bin/tests_vecdeque --format=plain --suite=TTestCase_VecDeque.$t | rg -n "^  00|Number of failures"; done`
- 复验结果：19 项全部 `Number of failures: 0`。

---

## 本批改动文件
- `tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`
- `src/fafafa.core.collections.vecdeque.pas`

## 结论
- Batch-41 整包完成。
- 通过测试补齐触发并修复了 `TVecDeque.Insert` 的尾指针同步缺陷。
