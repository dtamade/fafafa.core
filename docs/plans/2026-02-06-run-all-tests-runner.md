# run_all_tests Runner Fix Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 修复 `tests/run_all_tests.*` 的“假绿”与“阻塞”风险，并让过滤模块名与目录结构一致（支持嵌套目录 → 点分模块名）。

**Architecture:** 模块名从脚本所在目录的 `tests/` 相对路径推导（路径分隔符转 `.`）；同目录优先 `BuildOrTest.*`，`BuildAndTest.*` 仅作为 fallback；若传入过滤但 0 命中则返回非 0。

**Tech Stack:** Bash、Windows Batch

---

### Task 1: 修复 `tests/run_all_tests.sh`（模块命名、过滤、去重、避免阻塞）

**Files:**
- Modify: `tests/run_all_tests.sh`

**Step 1: 复现“假绿”现象（现状应失败但会通过）**

Run: `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.collections.vec`

Expected (current buggy behavior): `Total:  0` 且 exit 0。

**Step 2: 实现模块名推导与过滤升级**
- 模块名 = `tests/` 相对目录路径，`/` → `.`
- 过滤匹配规则：
  - `filter == module`
  - `module` 以 `filter.` 开头（组过滤）
  - `filter == basename`（兼容旧用法）
- 传入过滤但 0 命中 → exit 2
- 同目录同时存在 `BuildOrTest.sh` 与 `BuildAndTest.sh`：只执行 `BuildOrTest.sh`

**Step 3: 验证修复**
- Run: `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.collections.vec`
  - Expected: `Total:  1`，且看到 `[PASS] fafafa.core.collections.vec`
- Run: `bash tests/run_all_tests.sh __no_such_module__`
  - Expected: exit 2，summary 明确提示 0 命中

---

### Task 2: 修复 `tests/run_all_tests.bat`（同等语义）

**Files:**
- Modify: `tests/run_all_tests.bat`

**Step 1: 实现模块名推导（相对目录 + `\\`→`.`）**
- 例：`tests\\fafafa.core.collections\\vec\\BuildOrTest.bat` → `fafafa.core.collections.vec`

**Step 2: 避免执行 `BuildAndTest.bat` 的 `pause` 阻塞**
- 若同目录存在 `BuildOrTest.bat`，则跳过 `BuildAndTest.bat`

**Step 3: 过滤 0 命中 → exit /b 2**

---

### Task 3: 更新文档，避免继续传播错误示例

**Files:**
- Modify: `docs/TESTING.md`

**Step 1: 更新模块过滤示例**
- 将 `fafafa.core.collections.vec` / `fafafa.core.collections.vecdeque` 改为可命中的模块名规则，并说明“嵌套目录会被转换成点分模块名”。
- 保留“关键模块回归”示例，但不要再给出当前不存在的 `fafafa.core.collections.arr/base` 过滤项。

---

### Task 4: 验证（verification-before-completion）

**Commands:**
- `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.collections.vec fafafa.core.collections.vecdeque fafafa.core.collections`
- `bash tests/run_all_tests.sh`（至少确保不因 `BuildAndTest.*` 阻塞）

**Expected:**
- 所有命令 exit 0，summary Total > 0；全量回归无阻塞。

