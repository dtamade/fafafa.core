# SIMD Completeness Closeout Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在不破坏默认 gate 的前提下，完成 SIMD 模块“接口完整度可证明 + 实现缺口可追踪 + 非 x86 证据可复验”的最终收口。

**Architecture:** 采用双轨策略：`stable lane`（默认 gate）只允许已验证语义；`experimental lane`（显式开关）隔离 NEON/RVV/SVE/LASX 等不稳定路径。通过自动化检查脚本把“接口声明、dispatch wiring、后端实现、测试覆盖、QEMU 证据”串成单一闭环，任何缺口都能被定位到具体文件和函数族。

**Tech Stack:** FreePascal/Lazarus, Bash, Python3, QEMU Docker multi-arch, existing BuildOrTest runner.

---

### Task 1: 产出 experimental asm 缺口自动报告

**Files:**
- Create: `tests/fafafa.core.simd/report_qemu_experimental_blockers.py`
- Create: `tests/fafafa.core.simd/docs/experimental_asm_blockers.md`
- Modify: `tests/fafafa.core.simd/BuildOrTest.sh`
- Modify: `tests/fafafa.core.simd/buildOrTest.bat`

**Step 1: 写失败用例（脚本层）**
- 新建报告脚本最小断言：当输入日志目录不存在时，返回非零并输出 `ERROR: log dir not found`。

**Step 2: 运行失败验证**
- Run: `python3 tests/fafafa.core.simd/report_qemu_experimental_blockers.py --log-dir /tmp/not-exist`
- Expected: 非零退出；包含 `ERROR: log dir not found`。

**Step 3: 最小实现**
- 解析 `tests/fafafa.core.simd/logs/qemu-multiarch-*/` 中 experimental 场景日志。
- 按 `backend(neon/riscvv)` + `category(opcode/syntax/symbol)` 聚合 Top blockers。
- 输出 markdown 报告到 `tests/fafafa.core.simd/docs/experimental_asm_blockers.md`。

**Step 4: 通过验证**
- Run: `python3 tests/fafafa.core.simd/report_qemu_experimental_blockers.py --latest`
- Expected: 0 退出；报告文件生成并含 `arm64`、`riscv64` 两节。

**Step 5: Commit**
```bash
git add tests/fafafa.core.simd/report_qemu_experimental_blockers.py tests/fafafa.core.simd/docs/experimental_asm_blockers.md tests/fafafa.core.simd/BuildOrTest.sh tests/fafafa.core.simd/buildOrTest.bat
git commit -m "simd: add experimental qemu blocker report action"
```

### Task 2: 建立 experimental 预期失败基线（防回归/防漂移）

**Files:**
- Create: `tests/fafafa.core.simd/docs/experimental_asm_expected_failures.json`
- Create: `tests/fafafa.core.simd/check_experimental_failure_baseline.py`
- Modify: `tests/fafafa.core.simd/BuildOrTest.sh`

**Step 1: 写失败用例**
- 先让 checker 在没有 baseline 文件时失败并提示 `baseline missing`。

**Step 2: 运行失败验证**
- Run: `python3 tests/fafafa.core.simd/check_experimental_failure_baseline.py --log-dir tests/fafafa.core.simd/logs/qemu-multiarch-20260219-075439`
- Expected: 非零退出；提示 baseline missing。

**Step 3: 最小实现**
- baseline 记录：平台、backend、关键错误签名、允许最小/最大失败数。
- checker 对比最新日志：
  - 新增未知失败 => FAIL
  - 已知失败消失 => WARN（正向信号）
  - 失败类别漂移 => FAIL

**Step 4: 通过验证**
- Run: `python3 tests/fafafa.core.simd/check_experimental_failure_baseline.py --latest`
- Expected: 当前状态下 PASS（或 WARN+0 exit 取决于设计），输出对比摘要。

**Step 5: Commit**
```bash
git add tests/fafafa.core.simd/docs/experimental_asm_expected_failures.json tests/fafafa.core.simd/check_experimental_failure_baseline.py tests/fafafa.core.simd/BuildOrTest.sh
git commit -m "simd: add experimental asm failure baseline checker"
```

### Task 3: 接口完整度机器检查（接口->dispatch->后端->测试）

**Files:**
- Modify: `tests/fafafa.core.simd/generate_interface_checklist_v2.py`
- Create: `tests/fafafa.core.simd/check_interface_implementation_completeness.py`
- Modify: `tests/fafafa.core.simd/docs/simd_completeness_matrix.md`
- Modify: `tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md`

**Step 1: 写失败用例**
- 对一个已知关键族（例如 `Round/Trunc/Floor/Ceil`）先断言：若缺少任一 backend wiring 或 suite 覆盖，脚本必须 FAIL。

**Step 2: 运行失败验证**
- Run: `python3 tests/fafafa.core.simd/check_interface_implementation_completeness.py --strict`
- Expected: 当前阶段先 FAIL（暴露真实缺口）。

**Step 3: 最小实现**
- 扫描：
  - 公共接口：`src/fafafa.core.simd.pas`
  - dispatch/wiring：`src/fafafa.core.simd.dispatch.pas`
  - 后端实现：`src/fafafa.core.simd.scalar.pas`, `src/fafafa.core.simd.sse2.pas`, `src/fafafa.core.simd.avx2.pas`, `src/fafafa.core.simd.avx512.pas`, `src/fafafa.core.simd.neon.pas`, `src/fafafa.core.simd.riscvv.pas`
  - 测试映射：`tests/fafafa.core.simd/*.testcase.pas`
- 输出 machine-readable summary（json + md）。

**Step 4: 通过验证**
- Run: `python3 tests/fafafa.core.simd/check_interface_implementation_completeness.py --strict`
- Expected: 0 退出；若仍有缺口，需明确列为 `P0/P1/P2`。

**Step 5: Commit**
```bash
git add tests/fafafa.core.simd/generate_interface_checklist_v2.py tests/fafafa.core.simd/check_interface_implementation_completeness.py tests/fafafa.core.simd/docs/simd_completeness_matrix.md tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md
git commit -m "simd: add machine-checkable completeness verification"
```

### Task 4: AVX2 IEEE754 异常值一致性补齐（Round/Trunc/Floor/Ceil）

**Files:**
- Modify: `tests/fafafa.core.simd/fafafa.core.simd.ieee754.testcase.pas`
- Modify: `tests/fafafa.core.simd/fafafa.core.simd.test.lpr`

**Step 1: 写失败测试**
- 新增 `TTestCase_AVX2IEEE754Extended`，覆盖 `F32x8/F32x16/F64x4/F64x8` 在 `sbAVX2 + vector asm=True` 下的 NaN/Inf 行为，与 Scalar/SSE2 比较。

**Step 2: 运行失败验证**
- Run: `bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_AVX2IEEE754Extended`
- Expected: 先 FAIL（若存在未对齐语义）。

**Step 3: 最小实现（若需要）**
- 仅修复必要实现（优先 `src/fafafa.core.simd.avx2.pas`，必要时 `src/fafafa.core.simd.scalar.pas`/`src/fafafa.core.simd.sse2.pas` 对齐语义）。

**Step 4: 通过验证**
- Run: `bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_AVX2IEEE754Extended`
- Run: `bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict`
- Expected: 全绿。

**Step 5: Commit**
```bash
git add tests/fafafa.core.simd/fafafa.core.simd.ieee754.testcase.pas tests/fafafa.core.simd/fafafa.core.simd.test.lpr src/fafafa.core.simd.avx2.pas src/fafafa.core.simd.scalar.pas src/fafafa.core.simd.sse2.pas
git commit -m "simd: close avx2 ieee754 round-trunc-floor-ceil parity gaps"
```

### Task 5: Dispatch 并发边界压测升级（混合 writer 场景）

**Files:**
- Modify: `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas`
- Modify: `tests/fafafa.core.simd/BuildOrTest.sh`
- Modify: `src/fafafa.core.simd.dispatch.pas` (only if race found)

**Step 1: 写失败测试**
- 新增混合并发 case：并行调用 `SetActiveBackend/ResetToAutomaticBackend/GetDispatchTable/SetVectorAsmEnabled`。
- 每轮校验：无 nil dispatch、无崩溃、结果可计算。

**Step 2: 运行失败验证**
- Run: `bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrent`
- Expected: 若有竞态则可稳定复现。

**Step 3: 最小实现（若需要）**
- 若检测到竞态：在 dispatch 管理层增加轻量串行化保护（保持读路径开销最小）。

**Step 4: 通过验证**
- Run: `bash tests/fafafa.core.simd/BuildOrTest.sh test-concurrent-repeat 20`
- Expected: 20/20 PASS。

**Step 5: Commit**
```bash
git add tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas tests/fafafa.core.simd/BuildOrTest.sh src/fafafa.core.simd.dispatch.pas
git commit -m "simd: strengthen dispatch concurrent safety under mixed writers"
```

### Task 6: 非 x86 证据闭环与发布判定

**Files:**
- Modify: `tests/fafafa.core.simd/collect_linux_simd_evidence.sh`
- Modify: `tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md`
- Modify: `task_plan.md`
- Modify: `findings.md`
- Modify: `progress.md`

**Step 1: 写失败检查**
- 在 release checklist 中增加强制项：
  - stable qemu evidence PASS（arm64+riscv64）
  - experimental report 产出且 baseline 检查通过。

**Step 2: 运行失败验证**
- Run: `bash tests/fafafa.core.simd/collect_linux_simd_evidence.sh`
- Expected: 若缺少新报告/基线校验，流程失败。

**Step 3: 最小实现**
- 将 Task1/Task2 动作串进 evidence pipeline，并写入 summary。

**Step 4: 通过验证**
- Run: `SIMD_QEMU_RETRIES=1 SIMD_QEMU_PLATFORMS='linux/arm64 linux/riscv64' bash tests/fafafa.core.simd/BuildOrTest.sh qemu-nonx86-evidence`
- Run: `SIMD_QEMU_RETRIES=1 SIMD_QEMU_PLATFORMS='linux/arm64 linux/riscv64' bash tests/fafafa.core.simd/BuildOrTest.sh qemu-nonx86-experimental-asm`
- Run: `bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict`
- Expected: stable lane PASS；experimental lane 可失败但报告与baseline校验 PASS。

**Step 5: Commit**
```bash
git add tests/fafafa.core.simd/collect_linux_simd_evidence.sh tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md task_plan.md findings.md progress.md
git commit -m "simd: close nonx86 evidence loop and release checklist"
```

---

## 执行顺序（建议）
1. Task 1
2. Task 2
3. Task 3
4. Task 5
5. Task 4
6. Task 6

## 完成标准（必须同时满足）
- `BuildOrTest.sh gate-strict` 稳定通过。
- `qemu-nonx86-evidence` 在 `arm64+riscv64` 通过。
- `qemu-nonx86-experimental-asm` 结果可解释（报告 + baseline checker 可复验）。
- `simd_completeness_matrix` 更新到当前日期，包含接口/实现/测试三维数据。
- `task_plan.md/findings.md/progress.md` 有完整变更闭环记录。
