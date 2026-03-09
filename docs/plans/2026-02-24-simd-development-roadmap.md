# SIMD Freeze Closure And Next-Wave Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 完成 `simd` 模块跨平台冻结闭环（Linux + Windows 证据一致为 PASS），并启动下一波可持续迭代（门禁加固 + non-x86 增强 + experimental intrinsics 分层收敛）。

**Architecture:** 保持 `fafafa.core.simd` 公共 API 与 `TSimdDispatchTable` ABI 稳定；开发以现有 gate 工具链为单一验收入口（`BuildOrTest.sh/.bat` + Python 检查脚本 + freeze-status），采用“小批次、可回滚、每批可独立验收”的节奏推进。

**Tech Stack:** FreePascal/Lazarus, Bash/CMD runner, Python 校验脚本, GitHub Actions（Windows 证据收集）。

---

### Task 1: 固化现状基线（先确认“现在卡在哪”）

**Files:**
- Read: `tests/fafafa.core.simd/evaluate_simd_freeze_status.py`
- Read: `tests/fafafa.core.simd/logs/gate_summary.md`
- Read: `tests/fafafa.core.simd/logs/windows_b07_gate.log`
- Test: `tests/fafafa.core.simd/check_interface_implementation_completeness.py`
- Test: `tests/fafafa.core.simd/check_backend_adapter_sync.py`
- Test: `tests/fafafa.core.simd/check_nonx86_wiring_sync.py`
- Test: `tests/fafafa.core.simd/check_intrinsics_coverage.py`

**Step 1: 运行冻结状态检查**

Run: `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`  
Expected: `mainline-ready=True` 且 `cross-ready=False`，失败点聚焦 `windows_evidence_verify` / `evidence-verify=SKIP`。

**Step 2: 运行四个结构性检查脚本**

Run:
- `python3 tests/fafafa.core.simd/check_interface_implementation_completeness.py`
- `python3 tests/fafafa.core.simd/check_backend_adapter_sync.py`
- `python3 tests/fafafa.core.simd/check_nonx86_wiring_sync.py`
- `python3 tests/fafafa.core.simd/check_intrinsics_coverage.py`

Expected: 全部 `OK`，确认当前不是“接口/映射缺口”，而是“跨平台证据闭环缺口”。

**Step 3: 记录基线结论到工作日志**

Modify: `progress.md`  
Expected: 留存本轮 freeze 与四项检查结果，避免后续争议。

**Step 4: Commit**

```bash
git add progress.md
git commit -m "docs(simd): capture freeze baseline and structural check results"
```

### Task 2: 采集真实 Windows 证据并通过 verifier

**Files:**
- Read: `.github/workflows/simd-windows-b07-evidence.yml`
- Read: `tests/fafafa.core.simd/run_windows_b07_closeout_via_github_actions.sh`
- Read/Output: `tests/fafafa.core.simd/logs/windows_b07_gate.log`
- Read/Output: `tests/fafafa.core.simd/logs/windows_b07_closeout_summary.md`

**Step 1: 使用 GitHub Actions 拉取真实 Windows 证据**

Run: `bash tests/fafafa.core.simd/run_windows_b07_closeout_via_github_actions.sh SIMD-$(date +%Y%m%d)-152`  
Expected: 输出 `Evidence log updated`，并自动触发 verifier + closeout finalize。

**Step 2: 单独复验 Windows 证据**

Run: `bash tests/fafafa.core.simd/verify_windows_b07_evidence.sh tests/fafafa.core.simd/logs/windows_b07_gate.log`  
Expected: `[EVIDENCE] OK`。

**Step 3: 若失败则做最小修复**

Modify:
- `tests/fafafa.core.simd/collect_windows_b07_evidence.bat`
- `tests/fafafa.core.simd/verify_windows_b07_evidence.bat`
- `tests/fafafa.core.simd/verify_windows_b07_evidence.sh`

修复策略：
- 仅对日志前导元数据匹配做兼容（CRLF、空格、Windows 版本字符串差异）；
- 不放宽“必须真实 Windows 证据”的约束（保留 simulated 拒绝规则）。

**Step 4: Commit**

```bash
git add tests/fafafa.core.simd/collect_windows_b07_evidence.bat tests/fafafa.core.simd/verify_windows_b07_evidence.bat tests/fafafa.core.simd/verify_windows_b07_evidence.sh tests/fafafa.core.simd/logs/windows_b07_gate.log tests/fafafa.core.simd/logs/windows_b07_closeout_summary.md
git commit -m "fix(simd): close windows B07 evidence verification loop"
```

### Task 3: 让 cross gate 变为真正 PASS（不是 SKIP）

**Files:**
- Modify: `tests/fafafa.core.simd/BuildOrTest.sh`
- Modify: `tests/fafafa.core.simd/buildOrTest.bat`
- Test: `tests/fafafa.core.simd/logs/gate_summary.md`

**Step 1: 强制 evidence-verify 成为 required gate step（收口批次）**

Run: `SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate`  
Expected: `gate_summary.md` 中 `evidence-verify` 为 `PASS`（非 `SKIP`）。

**Step 2: 对齐 Windows 脚本行为**

Run: `tests\fafafa.core.simd\buildOrTest.bat gate`（Windows 环境）  
Expected: 关键步骤名与 Linux gate 摘要一致，证据校验阶段可追踪。

**Step 3: Commit**

```bash
git add tests/fafafa.core.simd/BuildOrTest.sh tests/fafafa.core.simd/buildOrTest.bat tests/fafafa.core.simd/logs/gate_summary.md
git commit -m "chore(simd): enforce cross gate evidence-verify as pass-required step"
```

### Task 4: 文档闭环（避免“代码通过但文档仍显示未完成”）

**Files:**
- Modify: `docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md`
- Modify: `tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md`
- Modify: `tests/fafafa.core.simd/docs/simd_completeness_matrix.md`
- Read: `tests/fafafa.core.simd/docs/interface_implementation_completeness.md`

**Step 1: 更新 Windows 证据状态与勾选项**

将 roadmap/RC checklist/matrix 中 “Windows 证据待补” 改为已完成，并引用最新日志时间与路径。

**Step 2: 同步矩阵数据口径**

将过期统计（如 `dispatch=557`、历史 P2 数）更新为最新快照（当前 `dispatch=558` 且 `P0/P1/P2=0`）。

**Step 3: 复跑冻结状态**

Run: `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`  
Expected: `ready=True`，`mainline-ready=True`，`cross-ready=True`。

**Step 4: Commit**

```bash
git add docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md tests/fafafa.core.simd/docs/simd_completeness_matrix.md
git commit -m "docs(simd): mark windows evidence closure and sync latest completeness metrics"
```

### Task 5: 门禁加固（把现在的人工步骤变成常态）

**Files:**
- Modify: `.github/workflows/ci.yml`
- Modify: `.github/workflows/simd-windows-b07-evidence.yml`
- Modify: `tests/fafafa.core.simd/docs/intrinsics_coverage_workflow.md`

**Step 1: 固化 nightly 严格门禁**

新增/确认 nightly 执行：
- `SIMD_GATE_COVERAGE=1`
- `SIMD_COVERAGE_STRICT_EXTRA=1`
- `SIMD_GATE_WIRING_SYNC=1`
- `SIMD_WIRING_SYNC_STRICT_EXTRA=1`
- `BuildOrTest.sh freeze-status`

**Step 2: 固化证据产物上传**

上传：
- `tests/fafafa.core.simd/logs/gate_summary.md`
- `tests/fafafa.core.simd/logs/gate_summary.json`
- `tests/fafafa.core.simd/logs/windows_b07_gate.log`
- `tests/fafafa.core.simd/logs/windows_b07_closeout_summary.md`

**Step 3: Commit**

```bash
git add .github/workflows/ci.yml .github/workflows/simd-windows-b07-evidence.yml tests/fafafa.core.simd/docs/intrinsics_coverage_workflow.md
git commit -m "ci(simd): harden nightly gate and archive freeze evidence artifacts"
```

### Task 6: non-x86 增强专题（不阻塞发布，但应持续推进）

**Files:**
- Modify: `src/fafafa.core.simd.neon.pas`
- Modify: `src/fafafa.core.simd.riscvv.pas`
- Modify/Test: `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
- Test: `tests/fafafa.core.simd/fafafa.core.simd.ieee754.testcase.pas`
- Test: `tests/fafafa.core.simd/BuildOrTest.sh`

**Step 1: 选定第一批高 ROI 槽位（8~12 个）**

优先：`Narrow compare/mask`、`F32x4/F64x2` 高频核心算子、`floor/ceil` native wide 槽位。

**Step 2: 先加失败用例**

增加 non-x86 仅在 backend 可用时执行的 parity + IEEE754 边界测试，确保先 RED。

**Step 3: 最小实现并通过 gate**

实现 NEON/RISCVV 专用覆盖，保留 `FillBaseDispatchTable` 标量兜底，不引入 ABI 变更。

**Step 4: Commit（按 1 个 backend 或 1 组算子一提交）**

```bash
git add src/fafafa.core.simd.neon.pas src/fafafa.core.simd.riscvv.pas tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas tests/fafafa.core.simd/fafafa.core.simd.ieee754.testcase.pas
git commit -m "feat(simd): expand non-x86 native coverage for selected high-roi slots"
```

### Task 7: experimental intrinsics 分层收敛（长期线）

**Files:**
- Modify: `src/fafafa.core.simd.intrinsics.aes.pas`
- Modify: `src/fafafa.core.simd.intrinsics.sha.pas`
- Modify: `tests/fafafa.core.simd.intrinsics.experimental/fafafa.core.simd.intrinsics.experimental.testcase.pas`
- Test: `tests/fafafa.core.simd/check_intrinsics_experimental_status.py`

**Step 1: 仅选一个子集（AES 或 SHA）推进**

避免一轮跨多个 ISA 模块导致回归面过大。

**Step 2: 在 experimental suite 先 RED 后 GREEN**

Run:
- `bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test-all`
- `python3 tests/fafafa.core.simd/check_intrinsics_experimental_status.py`

Expected: experimental 行为测试通过，默认入口隔离仍为 `OK`。

**Step 3: Commit**

```bash
git add src/fafafa.core.simd.intrinsics.aes.pas src/fafafa.core.simd.intrinsics.sha.pas tests/fafafa.core.simd.intrinsics.experimental/fafafa.core.simd.intrinsics.experimental.testcase.pas
git commit -m "feat(simd): improve experimental intrinsics semantics under opt-in guard"
```

---

## Milestones

1. **M1（0.5~1 天）**：Task 1~4 完成，`freeze-status` 达到 `cross-ready=True`。  
2. **M2（1~2 天）**：Task 5 完成，nightly 门禁与证据归档自动化。  
3. **M3（持续迭代）**：Task 6~7 按批次推进，每批保持 gate 可回归。  

## Out Of Scope (for this plan)

- 不做 `TSimdDispatchTable` 破坏性改动。  
- 不在同一批次内混合“证据收口”和“大规模 backend 重写”。  
- 不将 experimental intrinsics 直接并入默认入口链（先保持隔离）。  
