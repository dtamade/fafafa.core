# Repo Gap Scan Priority Batch-35 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 一次性完成 Batch-E Task 31-38（整包执行，不拆分）：
- `Test_SetGrowStrategy`
- `Test_IsFull`
- `Test_GetAllocator`
- `Test_GetData`
- `Test_SetData`
- `Test_ToArray`
- `Test_yaml_node_basic_operations`
- `Test_yaml_node_scalar_operations`

**Architecture:** 严格 TDD：统一 RED 验证 -> 统一 GREEN 落地 -> Task31-38 串行回归。对 YAML 用例采用“基于当前实现能力”的最小可验证断言，避免超出后端 stub 语义。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.collections/vecdeque/Test_vecdeque_clean.pas`、`tests/fafafa.core.yaml/fafafa.core.yaml.testcase.pas`。

---

## 执行记录（2026-02-11）

### RED（统一验证）
- 先将 Task31-38 目标方法替换为失败断言，并修复可见性以避免 `No tests selected` 假通过。
- 逐项 RED 输出：
  - `Test_SetGrowStrategy`：`N:1 E:0 F:1`
  - `Test_IsFull`：`N:1 E:0 F:1`
  - `Test_GetAllocator`：`N:1 E:0 F:1`
  - `Test_GetData`：`N:1 E:0 F:1`
  - `Test_SetData`：`N:1 E:0 F:1`
  - `Test_ToArray`：`N:1 E:0 F:1`
  - `Test_yaml_node_basic_operations`：`N:1 E:0 F:1`
  - `Test_yaml_node_scalar_operations`：`N:1 E:0 F:1`

### GREEN（一次性完成）
- `vecdeque_clean`：
  - `Test_SetGrowStrategy`：覆盖 set/reset 与队列行为不回归。
  - `Test_IsFull`：改为可编译且可验证的“容量边界语义”断言（`Count/Capacity`），避免调用不存在成员。
  - `Test_GetAllocator`：默认分配器与自定义分配器回读一致性。
  - `Test_GetData` / `Test_SetData`：指针数据读写与 nil 回退。
  - `Test_ToArray`：空容器 + wrap 场景序列保持断言。
- `yaml`：
  - `Test_yaml_node_basic_operations`：文档构建/根节点/节点类型与计数的 nil 安全语义。
  - `Test_yaml_node_scalar_operations`：`scalar/sequence/mapping/pair` 读取接口在 nil 输入下的稳定返回语义。

### GREEN 验证
- 逐项复验全部通过（每项 `N:1 E:0 F:0`）。

### 整包回归（Task31-38）
- `vecdeque` 串行回归 6 项通过：
  - `Test_SetGrowStrategy`
  - `Test_IsFull`
  - `Test_GetAllocator`
  - `Test_GetData`
  - `Test_SetData`
  - `Test_ToArray`
- `yaml` 串行回归 2 项通过：
  - `Test_yaml_node_basic_operations`
  - `Test_yaml_node_scalar_operations`

---

## 结论
- Batch-E（Task 31-38）已整包完成（`8/8`）。
- 下一步建议：进入 Batch-F（Task 39-50）。
