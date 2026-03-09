# Repo Gap Scan Priority Batch-38 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在 Batch-37 后继续整包收敛 `vecdeque_clean` 的 7 个紧邻 TODO：
- `Test_Create_Allocator_GrowStrategy_Data`
- `Test_PtrIter`
- `Test_SerializeToArrayBuffer`
- `Test_AppendUnChecked`
- `Test_AppendToUnChecked`
- `Test_SaveToUnChecked`
- `Test_GetMemory`

**Architecture:** 严格 TDD（RED→GREEN→回归）。先统一 RED，再一次性补齐断言；如遇编译问题先修测试实现，不扩散到无关模块。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`。

---

## 扫描结论（2026-02-11）
- 上轮 Batch-37 完成构造器族后，`Test_vecdeque_clean.pas` 在 1260 附近仍有连续 TODO 区块。
- 本批 7 项处于同语义域（构造补全 + ICollection/IArray 基础能力），适合整包闭环。

---

## 执行记录（2026-02-11）

### Phase-1：RED（7 项统一置失败）
1) 将 7 项 TODO 全部改为最小失败断言 `Fail('RED ...')`。
2) 编译：
- `cd tests/fafafa.core.collections/vecdeque && lazbuild --build-mode=Debug tests_vecdeque.lpi`
3) 逐项执行：
- `./../../bin/tests_vecdeque --format=plain --suite=TTestCase_VecDeque.<TestName>`
4) 输出：7 项均 `N:1 E:0 F:1`。

### Phase-2：GREEN（一次性实现断言）
1) `Test_Create_Allocator_GrowStrategy_Data`
- 覆盖 `allocator/growStrategy/data/count/capacity` 基础语义。

2) `Test_PtrIter`
- 覆盖空容器迭代、wrap 后逻辑顺序、`Reset` 复位再迭代。

3) `Test_SerializeToArrayBuffer`
- 覆盖完整序列与部分序列拷贝、`aDst=nil` 异常、`aCount>Count` 异常。

4) `Test_AppendUnChecked`
- 覆盖 Pointer / VecDeque / TArray 三条追加路径，以及空操作路径。

5) `Test_AppendToUnChecked`
- 覆盖源容器 wrap 场景追加到目标容器，验证目标拼接顺序与源不变。

6) `Test_SaveToUnChecked`
- 覆盖当前实现语义（在 `TVecDeque` 中等同 `AppendToUnChecked`，不清空目标）。

7) `Test_GetMemory`
- 覆盖空容器返回 `nil`、非空返回首逻辑元素指针、wrap 场景和指针写回。

### 编译期修正（测试代码）
- 首轮 GREEN 编译失败 3 处：
  - 原因：将 `TIntegerArray`（动态数组）误当作容器类使用。
  - 修复：改为 `specialize TArray<Integer>` 容器对象，并使用 `Put` 填值。

### Phase-3：回归验证
1) 重新编译通过：
- `cd tests/fafafa.core.collections/vecdeque && lazbuild --build-mode=Debug tests_vecdeque.lpi`

2) 7 项目标测试逐项回归：
- 全部 `N:1 E:0 F:0`。

3) 扩展子集回归（7 项 + 既有 `Get/GetUnChecked/Put/PutUnChecked`）：
- 共 11 项均通过。

---

## 本批改动文件
- `tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`

## 结论
- Batch-38 整包完成。
- 本批无新增源码缺陷，主要完成 TODO 测试补齐与语义稳定化。
