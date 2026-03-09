# SIMD Module Remediation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 系统修复 `fafafa.core` 的 SIMD 子系统中“未实现/错误实现/覆盖盲区/设计不一致”问题，使 gate 结果与真实质量一致。

**Architecture:** 采用“先可信度、再覆盖、后功能”的三层策略：先修测试与门禁失真，再补齐可达路径覆盖，最后处理占位实现与模块收敛。对跨平台单元采用“有平台实机证据才宣称完成”的准则。

**Tech Stack:** FreePascal/Lazarus、FPCUnit、Bash gate scripts、Python coverage/wiring checker。

---

## Evidence Baseline (2026-02-17)

- `bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict`：PASS。
- gate 步骤仅执行：
  - `--list-suites`
  - `--suite=TTestCase_AVX2IntrinsicsFallback`
  - cpuinfo portable `TTestCase_PlatformSpecific`
  - cpuinfo.x86 `TTestCase_Global`
  - 过滤 run_all 仅 3 模块（不含 intrinsics.sse/mmx）
- 独立执行：
  - `bash tests/fafafa.core.simd.intrinsics.sse/BuildOrTest.sh test` → PASS（113 tests）
  - `bash tests/fafafa.core.simd.intrinsics.mmx/BuildOrTest.sh test` → PASS（75 tests）
- 量化盲区：
  - `if not HasAVX2 then Exit;`：62 处（`tests/fafafa.core.simd/fafafa.core.simd.testcase.pas`）
  - `if (dt=nil) or not Assigned(dt^....) then Exit`：9 处（同文件）
- 可达性扫描：18 个 `src/fafafa.core.simd*.pas` 单元在 `src/tests`（排除自身）无引用。

## Execution Update (2026-02-19)

### Closed in this round

1. `dispatchapi` 接口覆盖 backlog 已清零并保持：
- `python3 tests/fafafa.core.simd/generate_interface_checklist_v2.py`
- 结果：`total=547 covered=547 backlog=0`

2. AVX-512 512-bit 整数族映射缺口已补齐：
- `U32x16/U64x8/I16x32/I8x64/U8x64` 全族算术/位运算/比较/移位/最值槽位完成 AVX-512 非 scalar 绑定。
- `Implementation Coverage Snapshot` 结果：`avx512=187/557`，`scalar_only=0`。

3. 能力声明与实现一致：
- `sc512BitOps` 已恢复宣称（不再保守禁用），并由测试约束“宣称即非 scalar 映射”。

4. 回归与门禁证据：
- `bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` → `TEST OK / LEAK OK`
- `bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict` → 最终 `[GATE] OK`
- 并发稳定性 repeat：`TTestCase_SimdConcurrent` 10/10 通过。

---

## Issue Inventory (One-by-One)

### P0 - Correctness/Trustworthiness

1. `cpuinfo.x86` 测试存在同名遮蔽 + 恒真断言，导致 AVX/AVX2 测试不可信。
- File: `tests/fafafa.core.simd.cpuinfo.x86/fafafa.core.simd.cpuinfo.x86.testcase.pas:85`
- File: `tests/fafafa.core.simd.cpuinfo.x86/fafafa.core.simd.cpuinfo.x86.testcase.pas:95`

2. gate 与真实覆盖存在偏差：主 gate 不执行 `intrinsics.sse/mmx` 模块测试。
- File: `tests/fafafa.core.simd/BuildOrTest.sh:464`
- File: `tests/run_all_tests_summary_sh.txt:1`

3. `cpuinfo.lazy` 状态机复用 `FBasicInitialized`，x86 基础特性初始化可被提前短路。
- File: `src/fafafa.core.simd.cpuinfo.lazy.pas:191`
- File: `src/fafafa.core.simd.cpuinfo.lazy.pas:285`

4. `EnsureCPUInfoInitialized` 在“初始化异常后回滚到 0”场景可导致等待线程无限等待。
- File: `src/fafafa.core.simd.cpuinfo.pas:316`
- File: `src/fafafa.core.simd.cpuinfo.pas:330`

5. 多个 intrinsics 单元包含明确占位/简化实现（若后续接入将直接错误）。
- File: `src/fafafa.core.simd.intrinsics.aes.pas:45`
- File: `src/fafafa.core.simd.intrinsics.sha.pas:38`
- File: `src/fafafa.core.simd.intrinsics.sse2.pas:623`
- File: `src/fafafa.core.simd.intrinsics.avx.pas:405`

### P1 - Coverage/Design Consistency

6. 覆盖脚本仅覆盖 SSE/MMX，不覆盖 AVX2/AVX512/NEON/SHA/AES 等。
- File: `tests/fafafa.core.simd/check_intrinsics_coverage.py:1`

7. `RegisterBackendRebuilder` 已 no-op，但 backend 仍注册 rebuilder，语义断裂。
- File: `src/fafafa.core.simd.dispatch.pas:1200`
- File: `src/fafafa.core.simd.sse2.pas:11271`
- File: `src/fafafa.core.simd.avx2.pas:8615`

8. `--vector-asm/--no-vector-asm` CLI 与运行时行为不一致（dispatch 初始化后无法切换）。
- File: `tests/fafafa.core.simd/fafafa.core.simd.test.lpr:64`
- File: `src/fafafa.core.simd.dispatch.pas:1116`

9. 接口清单资产已漂移：历史清单 439，当前接口声明统计 546。
- File: `docs/plans/2026-02-09-simd-interface-target-checklist.md:13`
- File: `src/fafafa.core.simd.pas:1`
- File: `src/fafafa.core.simd.api.pas:1`

10. 大量疑似死单元未接入主链路，增加维护噪音与误导风险。
- File: `src/fafafa.core.simd.cpuinfo.lazy.pas:1`
- File: `src/fafafa.core.simd.cpuinfo.diagnostic.pas:1`
- File: `src/fafafa.core.simd.intrinsics.x86.sse2.pas:1`
- File: `src/fafafa.core.simd.vector.pas:1`

### P2 - Maintainability

11. 单文件体量过大（核心与测试均超大），定位与回归成本高。
- File: `src/fafafa.core.simd.pas:1`（约 7414 行）
- File: `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas:1`（约 21067 行）

12. build/gate 仅卡 src warning/hint，不卡测试 warning（会放过低质量测试代码）。
- File: `tests/fafafa.core.simd/BuildOrTest.sh:95`
- File: `tests/fafafa.core.simd.cpuinfo.x86/BuildOrTest.sh:82`

---

## Phased Execution

### Task 1: 修复测试可信度（P0）

**Files:**
- Modify: `tests/fafafa.core.simd.cpuinfo.x86/fafafa.core.simd.cpuinfo.x86.testcase.pas`
- Modify: `tests/fafafa.core.simd.cpuinfo.x86/BuildOrTest.sh`

**Steps:**
1. 修复 `HasAVX/HasAVX2` 同名遮蔽变量。
2. 将 `AssertTrue(..., True)` 改为“语义断言”或明确平台条件断言。
3. 将测试 warning 视为失败（至少在 cpuinfo.x86 模块先落地）。
4. 验证：
```bash
bash tests/fafafa.core.simd.cpuinfo.x86/BuildOrTest.sh test --suite=TTestCase_Global
```

### Task 2: gate 覆盖闭环（P0/P1）

**Files:**
- Modify: `tests/fafafa.core.simd/BuildOrTest.sh`
- Modify: `tests/fafafa.core.simd/check_intrinsics_coverage.py`

**Steps:**
1. gate 引入 `intrinsics.sse/mmx` 真实执行步骤（非仅 coverage 映射）。
2. 扩展 coverage checker 至至少 `avx2`（随后再扩展 AVX/AVX512/NEON）。
3. 为 `SIMD_GATE_COVERAGE=1` 时新增失败阈值：缺失映射即 fail。
4. 验证：
```bash
SIMD_GATE_COVERAGE=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

### Task 3: cpuinfo 并发与 lazy 修复（P0）

**Files:**
- Modify: `src/fafafa.core.simd.cpuinfo.pas`
- Modify: `src/fafafa.core.simd.cpuinfo.lazy.pas`
- Add: `tests/fafafa.core.simd.cpuinfo/fafafa.core.simd.cpuinfo.lazy.testcase.pas`

**Steps:**
1. 修复 `EnsureCPUInfoInitialized` 的等待策略，避免 state=0 时死等。
2. 拆分 lazy 初始化标志（BasicInfo vs X86Basic），避免状态复用。
3. 增加 lazy 功能测试（字段完整性、并发一致性、Reset 行为）。
4. 验证：
```bash
bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh test
```

### Task 4: 占位 intrinsics 处理策略（P1）

**Files:**
- Candidate: `src/fafafa.core.simd.intrinsics.*.pas`

**Steps:**
1. 对 18 个低可达单元做三分决策：
   - A: 接入主链路并补测试
   - B: 标记 experimental 并从默认 gate 排除
   - C: 归档/删除（若确认为死代码）
2. 对 `aes/sha/sse2(avx)` 等“语义明显错误”的单元，若保留必须加 `experimental + 未保证语义` 明确注记与禁用入口。
3. 验证：
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh check
bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict
```

### Task 5: 接口清单与模块化收敛（P1/P2）

**Files:**
- Update: `docs/plans/2026-02-09-simd-interface-target-checklist.md` (或新日期版)
- Refactor candidates: `src/fafafa.core.simd.pas`, `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas`

**Steps:**
1. 重新生成当前接口清单（546 基线）。
2. 将未覆盖接口自动标注为 backlog。
3. 拆分超大测试文件（按 suite 分文件），降低回归成本。

---

## Exit Criteria (Definition of Done)

- `gate` 不再依赖“空跑/跳过”获得全绿。
- `cpuinfo` 相关测试能覆盖 lazy 与并发异常路径。
- 占位 intrinsics 不再处于“默认可见但语义错误”状态。
- 接口清单与当前源码同步，无明显漂移。
- 至少一次 `gate-strict` + 独立 intrinsics 子模块回归全绿。

---

## Recommended Execution Order

1. Task 1（修测试可信度）
2. Task 2（修 gate 覆盖）
3. Task 3（修 cpuinfo 并发/lazy）
4. Task 4（处置占位/死代码 intrinsics）
5. Task 5（清单与模块化收敛）
