# Repo Gap Scan Priority Batch-50 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 修复 `sync.sem` 测试模块的编译阻塞缺陷（非法 `\n` 字面量污染方法体），恢复可编译和关键构造器测试路径可执行。

**Architecture:** 以编译失败作为 RED 基线，执行最小语法修复（仅替换 3 个损坏方法体），再进行 GREEN 验证（编译通过 + 目标测试路径执行），最后记录模块中与本批无关的既有失败。

**Tech Stack:** FreePascal 3.3.x、`tests/fafafa.core.sync.sem/fafafa.core.sync.sem.enhanced.test.lpr`、FPCUnit。

---

### Task 1: RED 基线（复现编译阻塞）

**Files:**
- Inspect: `tests/fafafa.core.sync.sem/fafafa.core.sync.sem.testcase.pas`

**Step 1: 复现失败**
Run:
- `cd tests/fafafa.core.sync.sem && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.sem.enhanced.test.lpr`

Expected:
- 失败：`Fatal: Illegal character "'\\'" ($5C)`。

### Task 2: GREEN 实现（最小语法修复）

**Files:**
- Modify: `tests/fafafa.core.sync.sem/fafafa.core.sync.sem.testcase.pas`

**Step 1: 修复 3 个损坏方法体**
- `Test_Constructors_Invalid_MaxLEZero`
- `Test_Constructors_Invalid_InitialNegative`
- `Test_Constructors_Invalid_InitialGreaterThanMax`

实施要求：
- 将字面量 `\n` 污染行恢复为标准 Pascal 结构。
- 使用显式 `try/except` 断言 `EInvalidArgument`，避免匿名过程兼容性风险。

**Step 2: 编译与运行验证**
Run:
- `cd tests/fafafa.core.sync.sem && fpc -MObjFPC -Scghi -O1 -g -gl -vewnhibq -FEbin -FUlib -Fi../../src -Fu../../src -Fu../.. fafafa.core.sync.sem.enhanced.test.lpr`
- `./bin/fafafa.core.sync.sem.enhanced.test`

Expected:
- 编译通过。
- 构造器 3 个用例可执行（无 `<failure>`/`<error>` 标记命中这 3 项）。

### Task 3: 回归结论与风险记录

**Files:**
- Modify: `task_plan.md`
- Modify: `findings.md`
- Modify: `progress.md`

**Step 1: 记录命令与输出**
- 记录 RED 编译错误与 GREEN 编译通过证据。
- 记录增强套件现存失败/错误（如有）并标注为“本批未触达”。

**Step 2: 更新优先级**
- 将 `sync.sem` 从“编译阻塞”降级为“运行期质量问题待独立批次处理”。
