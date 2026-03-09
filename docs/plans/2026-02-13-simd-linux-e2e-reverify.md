# SIMD (Linux) E2E Re-Verify Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在 Linux 上对 `fafafa.core.simd` 做一次“缺口扫描 → 全链路 gate（strict）→ evidence 留痕 → freeze-status-linux”复跑验证；若发现缺口或回归，按严格 TDD（先失败、再修复、再通过）闭环修复。

**Architecture:** 以 `tests/fafafa.core.simd/BuildOrTest.sh` 为主验证入口（gate/evidence/freeze-status）；再对 `tests/fafafa.core.simd.cpuinfo*` 与 `tests/fafafa.core.simd.intrinsics.*` 子模块分别跑 `BuildOrTest.sh test`，确保 `cpuinfo/intrinsics` 的独立入口同样稳定。

**Tech Stack:** Bash、ripgrep、FreePascal/FPC、Lazarus/lazbuild、Python3（可选）。

---

## Agent Team（角色分工）
- **Implementer（代码）**：只在出现失败/缺口时做最小修复；任何行为变化必须先写失败测试再修复（严格 TDD）。
- **Reviewer（审查）**：检查是否引入 `src/fafafa.core.simd.*` 的 warning/hint、是否破坏 dispatch table 语义、是否引入 Linux-only 行为。
- **Coordinator（推进/计划）**：维护 `task_plan.md/findings.md/progress.md`，确保每一步命令与关键输出可追溯。

---

### Task 1: SIMD 缺口扫描（只记录，不修全仓）

**Files:**
- Update: `findings.md`
- Update: `progress.md`

**Step 1: 扫描 src/simd TODO**

Run:
```bash
rg -n --glob 'src/fafafa.core.simd*.pas' 'TODO|FIXME|XXX|HACK|placeholder|未实现|待实现|暂未' src || true
```

Expected:
- 无匹配，或仅文档/注释级别的记录（不影响 gate）。

**Step 2: 扫描 tests/simd TODO/skip**

Run:
```bash
rg -n --glob 'tests/fafafa.core.simd*/**/*.pas' 'TODO|FIXME|XXX|HACK|placeholder|未实现|待实现|暂未' tests/fafafa.core.simd* || true
rg -n --glob 'tests/fafafa.core.simd*/**/*.pas' '\\bSKIP\\b|\\bskip\\b|skipped' tests/fafafa.core.simd* || true
```

Expected:
- 仅出现“环境/CPU 不支持导致的可解释 skip”，不出现“占位未实现”。

---

### Task 2: SIMD Gate（Linux 主线验证，strict）

**Files:**
- Verify: `tests/fafafa.core.simd/BuildOrTest.sh`
- Logs (generated): `tests/fafafa.core.simd/logs/`

**Step 1: Check（编译 + warning/hint 门禁）**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh check
```

Expected:
- `[BUILD] OK`
- `[CHECK] OK (no SIMD-unit warnings/hints)`

**Step 2: Gate（开启 wiring-sync + strict coverage + perf-smoke）**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict
```

Expected:
- `[GATE] OK`

---

### Task 3: Evidence（Linux 留痕）

**Files:**
- Logs (generated): `tests/fafafa.core.simd/logs/evidence-*/`

**Step 1: evidence-linux**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh evidence-linux
```

Expected:
- 输出 `EVIDENCE DONE: .../logs/evidence-*/`
- 输出 `EVIDENCE SUMMARY: .../summary.md`

---

### Task 4: Freeze Status（Linux-only）

**Files:**
- Verify: `tests/fafafa.core.simd/BuildOrTest.sh`

**Step 1: freeze-status-linux**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux
```

Expected:
- `ready=True`

---

### Task 5: 子模块独立入口验证（cpuinfo / intrinsics）

**Files:**
- Verify: `tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh`
- Verify: `tests/fafafa.core.simd.cpuinfo.x86/BuildOrTest.sh`
- Verify: `tests/fafafa.core.simd.intrinsics.sse/BuildOrTest.sh`
- Verify: `tests/fafafa.core.simd.intrinsics.mmx/BuildOrTest.sh`

**Step 1: cpuinfo**

Run:
```bash
bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh test --list-suites
bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh test
```

Expected:
- `[BUILD] OK` + `[CHECK] OK` + `[TEST] OK` + `[LEAK] OK`

**Step 2: cpuinfo.x86**

Run:
```bash
bash tests/fafafa.core.simd.cpuinfo.x86/BuildOrTest.sh test --list-suites
bash tests/fafafa.core.simd.cpuinfo.x86/BuildOrTest.sh test
```

Expected:
- `[BUILD] OK` + `[CHECK] OK` + `[TEST] OK` + `[LEAK] OK`

**Step 3: intrinsics.sse / intrinsics.mmx**

Run:
```bash
bash tests/fafafa.core.simd.intrinsics.sse/BuildOrTest.sh test
bash tests/fafafa.core.simd.intrinsics.mmx/BuildOrTest.sh test
```

Expected:
- `[BUILD] OK` + `[CHECK] OK` + `[TEST] OK` + `[LEAK] OK`

---

### Task 6: 记录与收口

**Files:**
- Update: `task_plan.md`
- Update: `findings.md`
- Update: `progress.md`

**Step 1: 记录关键输出**
- 将本次命令与关键输出摘要追加到 `progress.md`

**Step 2: 更新批次状态**
- 在 `task_plan.md` 追加 Batch 条目，并标记 completed（Linux-only）。
