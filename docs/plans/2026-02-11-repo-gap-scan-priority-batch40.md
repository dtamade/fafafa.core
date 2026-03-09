# Repo Gap Scan Priority Batch-40 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在 Batch-39 后继续整包收敛 `vecdeque_clean` 的 6 个区间/unchecked TODO：
- `Test_Fill_Range`
- `Test_FillUnChecked`
- `Test_Zero_Range`
- `Test_ZeroUnChecked`
- `Test_Reverse_Range`
- `Test_ReverseUnChecked`

**Architecture:** 严格 TDD（RED→GREEN→回归）。先统一 RED，再一次性补齐断言，覆盖基础、zero-count、wrap 与边界异常语义；不修改脚本/CI。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`。

---

## 扫描结论（2026-02-11）
- Batch-39 完成后，`Fill/Zero/Reverse` 区块仍有 6 个连续 TODO，且与前批 `Swap/Copy` 同语义域，适合继续整包推进。
- 全仓快扫结果（`rg -n "TODO|placeholder|暂未实现|未实现" src tests`）显示：
  - `vecdeque_clean` TODO 由 `43` 降至 `37`（本批收敛 6 项）。
  - 仍是当前首要热点文件。

---

## 执行记录（2026-02-11）

### Phase-1：RED（6 项统一失败验证）
1) 将 6 项占位统一改为 `Fail('RED ...')`。
2) 编译：
- `cd tests/fafafa.core.collections/vecdeque && lazbuild --build-mode=Debug tests_vecdeque.lpi`
3) 逐项执行：
- `./../../bin/tests_vecdeque --format=plain --suite=TTestCase_VecDeque.Test_Fill_Range`
- `./../../bin/tests_vecdeque --format=plain --suite=TTestCase_VecDeque.Test_FillUnChecked`
- `./../../bin/tests_vecdeque --format=plain --suite=TTestCase_VecDeque.Test_Zero_Range`
- `./../../bin/tests_vecdeque --format=plain --suite=TTestCase_VecDeque.Test_ZeroUnChecked`
- `./../../bin/tests_vecdeque --format=plain --suite=TTestCase_VecDeque.Test_Reverse_Range`
- `./../../bin/tests_vecdeque --format=plain --suite=TTestCase_VecDeque.Test_ReverseUnChecked`
4) 输出：6 项均 `N:1 E:0 F:1`。

### Phase-2：GREEN（一次性补齐真实断言）
1) `Fill` 系列
- 覆盖 range/unchecked 的基础语义、`aCount=0` no-op、wrap 场景、`Fill(range)` 越界异常。

2) `Zero` 系列
- 覆盖 range/unchecked 的基础语义、`aCount=0` no-op、wrap 场景、`Zero(range)` 越界异常。

3) `Reverse` 系列
- 覆盖 range/unchecked 的基础语义、`aCount=0/1` no-op、整段 reverse、wrap 场景、`Reverse(range)` 越界异常。

### Phase-3：回归验证
1) 重新编译通过：
- `cd tests/fafafa.core.collections/vecdeque && lazbuild --build-mode=Debug tests_vecdeque.lpi`

2) 6 项目标测试逐项回归：
- 全部 `N:1 E:0 F:0`。

3) 扩展子集回归（+ 单元素邻近用例）：
- `Test_Fill_Single`
- `Test_Fill_Range`
- `Test_FillUnChecked`
- `Test_Zero_Single`
- `Test_Zero_Range`
- `Test_ZeroUnChecked`
- `Test_Reverse_Single`
- `Test_Reverse_Range`
- `Test_ReverseUnChecked`
- 输出：9 项全部 `N:1 E:0 F:0`。

---

## 本批改动文件
- `tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`

## 结论
- Batch-40 整包完成。
- 下一批建议：继续 `vecdeque_clean` 的 `ForEach/ForEachUnChecked` 计数区间 TODO（同文件可低切换成本推进）。
