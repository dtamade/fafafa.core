# Repo Gap Scan & P0 Fixes (Batch-60) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在 Linux 上完成全仓缺口复扫，并以 `tests/run_all_tests.sh` 的 fail-fast 输出为主线，优先修复 P0 阻塞点（先让全仓测试 runner 可继续推进）。

**Architecture:** 以“证据驱动”的方式推进：先用 `rg` 做静态缺口扫描，再用 `STOP_ON_FAIL=1 bash tests/run_all_tests.sh` 定位首个真实失败模块；每个修复严格遵循 RED→GREEN→Regression（行为修复必须先有失败测试；脚本/构建阻塞用“失败复现→最小修复→验证通过”闭环替代）。

**Tech Stack:** Bash、FreePascal/FPC、Lazarus/lazbuild、ripgrep。

---

## Agent Team（角色分工）
- **Implementer（代码）**：执行每个任务的 RED→GREEN→Regression；禁止顺手重构。
- **Reviewer（审查）**：检查是否引入不必要改动、是否破坏既有约定（例如路径分隔符、输出目录、非交互）。
- **Coordinator（推进）**：记录每步命令与关键输出到 `progress.md`，并同步更新 `task_plan.md/findings.md`。

---

### Task 0: 全仓缺口扫描（快照）

**Files:**
- Update: `findings.md`
- Update: `progress.md`

**Step 1: 统计文件规模**

Run:
```bash
rg --files src tests examples benchmarks docs | wc -l
```

Expected:
- 输出一个整数（当前环境基线约 4.8k）。

**Step 2: src 未完成项计数**

Run:
```bash
rg -n --glob 'src/**/*.pas' 'TODO|FIXME|XXX|HACK|未实现|待实现|暂未|placeholder' src | wc -l
```

Expected:
- 输出一个整数。

**Step 3: tests 占位/未完成计数**

Run:
```bash
rg -n --glob 'tests/**/*.pas' "{ TODO: 实现 }|待实现', True)|TODO|placeholder|暂未实现|未实现|FIXME|XXX" tests | wc -l
```

Expected:
- 输出一个整数。

**Step 4: 记录 Top 文件**

Run:
```bash
rg -n --glob 'src/**/*.pas' 'TODO|FIXME|XXX|HACK|未实现|待实现|暂未|placeholder' src | cut -d: -f1 | sort | uniq -c | sort -nr | head -20
rg -n --glob 'tests/**/*.pas' "{ TODO: 实现 }|待实现', True)|TODO|placeholder|暂未实现|未实现|FIXME|XXX" tests | cut -d: -f1 | sort | uniq -c | sort -nr | head -20
```

Expected:
- 输出 Top20 文件列表（用于后续 P1/P2 拆批）。

---

### Task 1: 修复 `fafafa.core.archiver` 在 Linux 的构建阻塞（P0）

**Files:**
- Modify: `tests/fafafa.core.archiver/BuildOrTest.sh`
- Modify: `tests/fafafa.core.archiver/fafafa.core.archiver.test.lpi`

**Step 1: RED（复现 fail-fast 首个失败点）**

Run:
```bash
STOP_ON_FAIL=1 bash tests/run_all_tests.sh
tail -n 160 tests/fafafa.core.archiver/logs/build.txt
```

Expected:
- `[FAIL] fafafa.core.archiver (rc=2)`
- `Path ".../tests/fafafa.core.archiver/lib/x86_64-linux/" does not exist`

**Step 2: GREEN（最小修复：输出目录与脚本口径对齐）**

Edits:
- `BuildOrTest.sh`：
  - 在 build 前创建 `lib/<TargetCPU>-<TargetOS>/`（例如 `lib/x86_64-linux/`）。
- `fafafa.core.archiver.test.lpi`：
  - 将 `Target/Filename` 从 `..\bin\tests_archiver` 调整为本模块目录：`bin/fafafa.core.archiver.test`
  - 将 `UnitOutputDirectory` 从 `lib\$(TargetCPU)-$(TargetOS)` 调整为 `lib/$(TargetCPU)-$(TargetOS)`

**Step 3: Verify（模块自测）**

Run:
```bash
bash tests/fafafa.core.archiver/BuildOrTest.sh test
```

Expected:
- `[BUILD] OK`
- `[TEST] OK`
- `[LEAK] OK`

**Step 4: Regression（继续 runner）**

Run:
```bash
STOP_ON_FAIL=1 bash tests/run_all_tests.sh
```

Expected:
- 不再在 `fafafa.core.archiver` 处失败；若出现新失败模块，进入 Task 2。

---

### Task 2: 继续清理 runner 的下一个失败模块（迭代，直到全绿或明确阻塞）

**Files:**
- Modify: `src/...` 或 `tests/...`（按失败点确定）

**Step 1: RED（获取下一个失败模块与日志）**

Run:
```bash
STOP_ON_FAIL=1 bash tests/run_all_tests.sh
tail -n 120 tests/_run_all_logs_sh/<failed-module>.log
```

Expected:
- 输出新的 `[FAIL] <module>` 与失败原因。

**Step 2: GREEN（严格 TDD 修复）**
- 若为行为 bug：先补/改单测让其稳定失败，再做最小实现修复。
- 若为编译/脚本阻塞：先稳定复现，再做最小修复。

**Step 3: Verify**

Run:
```bash
bash tests/<failed-module>/BuildOrTest.sh test
STOP_ON_FAIL=1 bash tests/run_all_tests.sh
```

Expected:
- 失败点前移或全绿。

