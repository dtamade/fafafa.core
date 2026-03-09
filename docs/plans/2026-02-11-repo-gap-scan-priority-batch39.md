# Repo Gap Scan Priority Batch-39 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在 Batch-38 后继续整包收敛 `vecdeque_clean` 的 4 个区间/unchecked 算法 TODO：
- `Test_SwapUnChecked_TwoElements`
- `Test_Swap_Range`
- `Test_Swap_Stride`
- `Test_CopyUnChecked`

**Architecture:** 严格 TDD（RED→GREEN→回归）。先统一 RED，再一次性补齐断言，保持与现有 `Test_Swap_TwoElements` / `Test_Copy` 的语义风格一致；不改 CI/脚本，不扩散到无关模块。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`。

---

## 扫描结论（2026-02-11）
- Batch-38 完成后，`vecdeque_clean` 在 `Swap/Copy` 邻域仍有 4 个连续 TODO，占位风险高且与现有已实现测试强相关。
- 同轮全仓快扫（`rg -n "TODO|placeholder|暂未实现|未实现" src tests`）显示：
  - `tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas` 仍是 TODO 热点（43 条）。
  - 紧邻下一优先可继续处理 `Fill/Zero/Reverse` 的 range/unchecked 6 项。

---

## 执行记录（2026-02-11）

### Phase-1：RED（4 项统一失败验证）
1) 保持 4 项为最小失败断言 `Fail('RED ...')`。
2) 编译：
- `cd tests/fafafa.core.collections/vecdeque && lazbuild --build-mode=Debug tests_vecdeque.lpi`
3) 逐项执行：
- `./../../bin/tests_vecdeque --format=plain --suite=TTestCase_VecDeque.Test_SwapUnChecked_TwoElements`
- `./../../bin/tests_vecdeque --format=plain --suite=TTestCase_VecDeque.Test_Swap_Range`
- `./../../bin/tests_vecdeque --format=plain --suite=TTestCase_VecDeque.Test_Swap_Stride`
- `./../../bin/tests_vecdeque --format=plain --suite=TTestCase_VecDeque.Test_CopyUnChecked`
4) 输出：4 项均 `N:1 E:0 F:1`。

### Phase-2：GREEN（一次性补齐真实断言）
在 `Test_vecdeque_clean.pas` 实现 4 项：
1) `Test_SwapUnChecked_TwoElements`
- 覆盖基础交换、同索引 no-op、wrap 场景交换与 count 不变。

2) `Test_Swap_Range`
- 覆盖基础区间交换、重叠区间的顺序交换语义、wrap 场景、越界异常（`EOutOfRange`）。

3) `Test_Swap_Stride`
- 覆盖 stride 交换基础语义、`stride=1` 行为、wrap 场景与 count 不变。

4) `Test_CopyUnChecked`
- 覆盖非重叠拷贝、重叠拷贝（前向/后向）、`aCount=0` no-op、wrap 场景。

### 编译期修正（测试代码）
- 首轮 GREEN 编译失败 4 处：`AssertEquals` 对 `LCountBefore` 与 `GetCount` 存在重载歧义。
- 修复：统一改为 `SizeInt(...)` 比较。

### Phase-3：回归验证
1) 重编译通过：
- `cd tests/fafafa.core.collections/vecdeque && lazbuild --build-mode=Debug tests_vecdeque.lpi`

2) 4 项目标测试逐项回归：
- 全部 `N:1 E:0 F:0`。

3) 扩展子集回归（+ 邻近 `Test_Swap_TwoElements`、`Test_Copy`）：
- 共 6 项全部 `N:1 E:0 F:0`。

---

## 本批改动文件
- `tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`

## 结论
- Batch-39 整包完成。
- 下一批建议：Batch-40 优先 `Fill/Zero/Reverse` 的 `Range/UnChecked` 6 项，占位密集且与当前区块同语义域。
