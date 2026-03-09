# SIMD (Linux) Finalization Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在 Linux 上把 `fafafa.core.simd` 相关模块（含 intrinsics / cpuinfo）做到“可验证、可留证据、可复跑”的完成态。

**Architecture:** 以 `tests/fafafa.core.simd/BuildOrTest.sh gate` 作为主验证链路；以 `evidence-linux` 产出可审计证据目录；补齐/修正仓库指引（`AGENTS.md`）中 SIMD CPUInfo 的实际跑法，避免误导。

**Tech Stack:** Bash、ripgrep、FreePascal/FPC、Lazarus/lazbuild。

---

### Task 0: 复扫缺口快照（仅记录，不修全仓）

**Files:**
- Update: `findings.md`
- Update: `progress.md`

**Step 1: 统计规模**

Run:
```bash
rg --files src tests examples benchmarks docs | wc -l
```

**Step 2: src 未完成项计数**

Run:
```bash
rg -n --glob 'src/**/*.pas' 'TODO|FIXME|XXX|HACK|未实现|待实现|暂未|placeholder' src | wc -l
```

**Step 3: tests 未完成项计数**

Run:
```bash
rg -n --glob 'tests/**/*.pas' 'TODO|FIXME|XXX|HACK|未实现|待实现|暂未|placeholder' tests | wc -l
```

---

### Task 1: SIMD Gate（Linux 主线验证）

**Files:**
- (none)

**Step 1: 执行 gate**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

Expected:
- `[GATE] OK`
- `tests/_run_all_logs_sh` 中有 `=fafafa.core.simd` / `=fafafa.core.simd.cpuinfo` / `=fafafa.core.simd.cpuinfo.x86` 的过滤执行证据。

---

### Task 2: Evidence（Linux 留证据）

**Files:**
- (none)

**Step 1: 产出 evidence 目录**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh evidence-linux
```

Expected:
- 输出新目录：`tests/fafafa.core.simd/logs/evidence-YYYYMMDD-HHMMSS/`
- `summary.md` 包含 sse/mmx/coverage/wiring-sync/perf-smoke/gate 关键摘要。

---

### Task 3: Freeze Status（Linux 就绪度）

**Files:**
- (none)

**Step 1: 仅 Linux 冻结检查**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux
```

Expected:
- `ready=True`（Linux-only）。

---

### Task 4: 修正 `AGENTS.md` 中 SIMD CPUInfo 运行指引（与仓库实际一致）

**Files:**
- Modify: `AGENTS.md`

**Step 1: RED（发现文档与仓库不一致）**
- 事实：仓库根不存在 `test/` 目录，但 `AGENTS.md` 当前引用 `test\\run_cpuinfo_tests.lpr` 等路径。

**Step 2: GREEN（最小修正，保持结构不大改）**
- 将 “SIMD CPU 信息子系统” 的独立 `test/` 路径改为当前仓库真实入口：
  - `bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh test --list-suites`
  - `bash tests/fafafa.core.simd.cpuinfo.x86/BuildOrTest.sh test --list-suites`
  - 或统一入口：`bash tests/fafafa.core.simd/BuildOrTest.sh gate`

**Step 3: Verify**

Run:
```bash
rg -n 'test\\\\run_cpuinfo_tests|test\\\\test_cpuinfo' AGENTS.md || true
```

Expected:
- 无匹配（旧路径引用被清理）。

