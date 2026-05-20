# SIMD Unblock Closeout & Next Attack Roadmap

> Status: superseded historical plan.
>
> This document records an older SIMD execution batch or bounded strategy snapshot.
> It is no longer part of the active whole-module execution chain.
> Before starting from any SIMD plan, check `docs/plans/2026-05-10-simd-plan-status-index.md`.

> Current HEAD note (2026-05-17):
> The "Windows closed" markers below are archived batch facts, not current readiness.
> Latest `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
> is still `ready=False / mainline-ready=True / cross-ready=False`, with
> `win-evidence-preflight=RECENT_BILLING_BLOCK` and `windows_evidence_verify`
> failing at `cmd.exe cannot resolve LAZBUILD command "lazbuild"`.
> For current operator truth, use `docs/fafafa.core.simd.closeout.md` and
> `tests/fafafa.core.simd/docs/windows_b07_closeout_runbook.md`.

更新时间：2026-03-11

## 1. 当前阻塞状态（结论先行）

- **接口阻塞已清零**：`docs/plans/2026-02-09-simd-interface-target-checklist.md` 中 `fafafa.core.simd` 门面接口未勾选项已归零（`[ ] = 0`）。
- **门禁稳定通过**：`VectorOps + check + DispatchAPI + perf-smoke + gate` 串行执行全绿（最新一次：2026-02-09 06:32:37）。
- **Linux 侧可发布候选**：依据 RC 清单，Linux 路径已达发布候选标准。
- **non-x86 收口完成（Linux）**：截至 2026-02-09，NEON/RISCVV 已完成 wiring + runtime parity 双层护栏（Batch106~110）。

## 2. 已完成闭环（对应开发阻塞）

### 2.1 接口清单闭环

Batch82 已补齐并验证以下 5 项：

1. `GetCurrentBackendInfo`
2. `GetAvailableBackendList`
3. `AllocateAligned`
4. `FreeAligned`
5. `IsPointerAligned`

新增测试：

- `TTestCase_VectorOps.Test_BackendInfoAndAlignedMemoryUtilities`
- 覆盖点：后端信息一致性、backend list 可用性、`nil` 对齐行为、默认/显式对齐分配、未对齐偏移断言、内存可写性。

## 3. 剩余阻塞与风险清单（按优先级）

### P0（历史归档事实，非当前 HEAD 状态）

- [x] **Windows 实机证据已归档**
  - 目标文件：`tests/fafafa.core.simd/logs/windows_b07_gate.log`
  - 关闭依据：旧批次 `win-closeout-finalize` 已完成，且当时 `freeze-status` 达到过 `cross-ready=True`。
  - 当前解释：这条 `[x]` 只表示历史归档批次曾闭环，不表示当前 `HEAD` 仍是 `cross-ready=True`。
  - 来源：`tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md`

### P1（不阻塞开发，但建议尽快纳入流程）

- [ ] **Coverage strict-extra 尚未并入默认 gate**
  - 当前状态：默认 gate 已开启 coverage；strict-extra 仍需显式开启（或走 gate-strict）。
  - 风险：后续新增 intrinsics 的“细粒度扩展项”仍可能漏测。
  - 建议：CI nightly 固化 `SIMD_COVERAGE_STRICT_EXTRA=1`（或固定跑 gate-strict）。

- [ ] **证据链自动化尚未固化到 CI 产物**
  - 当前状态：`evidence-linux` 可用，但非默认产线步骤。
  - 风险：回归时证据收集依赖人工触发。

### P2（能力扩展，非当前阻塞）

- [x] **非 x86 后端 dispatch 覆盖收口完成（2026-03-11）**
  - 当前机器检查：`dispatch=558, neon=558, riscvv=558, P0=0/P1=0/P2=0`
  - 后续重点：继续补语义/随机边界 parity 与性能证据，而不是继续补 dispatch 空槽。

## 4. 下一阶段“逐一攻克”目标清单（可直接开干）

### Stage A（历史已完成批次，非当前 HEAD 放行状态）

- [x] 当前推荐的一键 release 收口入口：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh closeout-release SIMD-YYYYMMDD-152`
- [x] 按推荐顺序完成证据闭环：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight`
  - `tests\fafafa.core.simd\buildOrTest.bat evidence-win-verify`
  - `FAFAFA_BUILD_MODE=Release SIMD_QEMU_PLATFORMS='linux/arm/v7 linux/arm64 linux/riscv64' SIMD_GATE_QEMU_NONX86_EVIDENCE=0 SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=1 SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE=0 SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_REPEAT=0 SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE=0 SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize SIMD-YYYYMMDD-152`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
- [x] 归档 `windows_b07_gate.log` 到 `tests/fafafa.core.simd/logs/`
- [x] 更新 RC 清单 P0 项为 `[x]`

**DoD:** 历史批次中的跨平台证据链闭环（Linux + Windows）。

### Stage B（1 天，流程防回退）

- [x] 在 CI（nightly）启用：
  - `SIMD_GATE_COVERAGE=1`
  - `SIMD_COVERAGE_STRICT_EXTRA=1`
- [x] 固化 `evidence-linux` 产物上传（含 `summary.md`）
- [x] 验证 3 次连续通过（避免偶发波动）
  - 当前进度：`3/3`
  - 已通过 run：`22918810451`（2026-03-10）、`22919783249`（2026-03-10）、`22921866560`（2026-03-10）

**DoD:** 新增 intrinsics 漏测可在 gate 前被拦截。

### Stage C（2~4 天，能力增强，不阻塞主线）

- [x] NEON 优先补齐：窄整数 + compare/mask 基础能力
- [x] RISC-V V 优先补齐：mask 操作与基础比较
- [x] 为新增实现补对应最小高价值测试（先 correctness，再 perf）

**2026-03-11 进展补充：**

- 已连续补齐并回归以下 non-x86 高 ROI 槽位：
  - `AndNotI8x16 / AndNotU16x8 / AndNotU8x16`
  - `DotF32x8 / DotF64x2 / DotF64x4`（RVV）
  - `I16x32` core + shift
  - `I8x64` core
  - `U32x16` core + shift
  - `U64x8` core + shift
  - `U8x64` core
- 当前机器检查结果：`dispatch=558, avx2=491, neon=558, riscvv=558, P0=0/P1=0/P2=0`
- 当前 gate：PASS（2026-03-11）
- 最新 backend benchmark summary：`tests/fafafa.core.simd/logs/backend-bench-20260311-103804/summary.md`
  - `VecI16x32Add`：`3.35x`；raw：`3.07x`
  - `VecU32x16Mul`：`0.99x`；raw：`1.00x`
  - `VecU64x8Add`：`0.76x`；raw：`0.80x`
  - `VecU8x64Max`：`3.96x`；raw：`4.31x`
  - 结论：dispatch 覆盖已经收口；`VecU32x16Mul` 的 façade 开销已基本压平，下一步应继续只盯低 ROI 算子裁剪与 stable boundary 收口，而不是继续补 wrapper

**2026-03-11 收口后的下一步优先级：**

1. 保留并复用已有正收益样板：`VecI16x32Add`、`VecU8x64Max`
2. `VecU32x16Mul` 仅做低成本观察，不再作为性能事故处理
3. `VecU64x8Add`、`VecF32x4Add` 降级为观察项，不进入主线优化 backlog
4. 主线工作转向 stable boundary / evidence contract / 文档真相源统一

**DoD:** 非 x86 后端关键路径可用于基础生产场景。

## 5. 推荐执行策略

- 当前开发主线可继续推进，但当前 `HEAD` 应按 `code-green / release-evidence-blocked` 理解，而不是“Windows closeout 已重新收口”。
- 若 latest `win-evidence-preflight` 仍是 `RECENT_BILLING_BLOCK`，先恢复 GitHub Billing/额度，或切到真实 Windows runner。
- 若走手工 Windows 实机路径，`LAZBUILD` 必须解析到 native Windows `.exe/.bat/.cmd`；不要继续用 Wine/cmd 冒充实机。
- 若显式试 `SIMD_WIN_EVIDENCE_USE_BASH_GATE=1`，也只限 `cmd.exe` 真能解析 `bash` 的环境；当前本机 Wine 不属于这种环境，不要把它当成 host-side Unix bridge 逃生口。
- 后端扩展按专题推进，不与门面接口清单混线，持续保持“小批次 + 固定门禁 + 文档回填”。

<!-- SIMD-WIN-CLOSEOUT-2026-03-10 -->

### Windows 实机证据（2026-03-10）

- 状态：已完成
- Evidence Log: tests/fafafa.core.simd/logs/windows_b07_gate.log
- Closeout Summary: tests/fafafa.core.simd/logs/windows_b07_closeout_summary.md
- 结论：P0 “Windows 实机证据未归档” 已关闭。

<!-- SIMD-WIN-CLOSEOUT-2026-03-14 -->

### Windows 实机证据（2026-03-14）

- 状态：已完成
- Evidence Log: tests/fafafa.core.simd/logs/windows_b07_gate.log
- Closeout Summary: tests/fafafa.core.simd/logs/windows_b07_closeout_summary.md
- 结论：P0 “Windows 实机证据未归档” 已关闭。

<!-- SIMD-WIN-CLOSEOUT-2026-03-21 -->

### Windows 实机证据（2026-03-21）

- 状态：已完成
- Evidence Log: tests/fafafa.core.simd/logs/windows-closeout/SIMD-20260320-152/windows_b07_gate.log
- Closeout Summary: tests/fafafa.core.simd/logs/windows-closeout/SIMD-20260320-152/windows_b07_closeout_summary.md
- 结论：P0 “Windows 实机证据未归档” 已关闭。

<!-- SIMD-WIN-CLOSEOUT-2026-03-24 -->

### Windows 实机证据（2026-03-24）

- 状态：已完成
- Evidence Log: tests/fafafa.core.simd/logs/windows_b07_gate.log
- Closeout Summary: tests/fafafa.core.simd/logs/windows_b07_closeout_summary.md
- 结论：P0 “Windows 实机证据未归档” 已关闭。

<!-- SIMD-WIN-CLOSEOUT-2026-04-02 -->

### Windows 实机证据（2026-04-02）

- 状态：已完成
- Evidence Log: tests/fafafa.core.simd/logs/windows-closeout/SIMD-20260402-152/windows_b07_gate.log
- Closeout Summary: tests/fafafa.core.simd/logs/windows-closeout/SIMD-20260402-152/windows_b07_closeout_summary.md
- 结论：P0 “Windows 实机证据未归档” 已关闭。

<!-- SIMD-WIN-CLOSEOUT-2026-05-19 -->
### Windows 实机证据（2026-05-19）

- 状态：已完成
- Evidence Log: tests/fafafa.core.simd/logs/windows-closeout/SIMD-20260519-152/windows_b07_gate.log
- Closeout Summary: tests/fafafa.core.simd/logs/windows-closeout/SIMD-20260519-152/windows_b07_closeout_summary.md
- 结论：P0 “Windows 实机证据未归档” 已关闭。

<!-- SIMD-WIN-CLOSEOUT-2026-05-20 -->
### Windows 实机证据（2026-05-20）

- 状态：已完成
- Evidence Log: tests/fafafa.core.simd/logs/windows-closeout/SIMD-20260520-152/windows_b07_gate.log
- Closeout Summary: tests/fafafa.core.simd/logs/windows-closeout/SIMD-20260520-152/windows_b07_closeout_summary.md
- 结论：P0 “Windows 实机证据未归档” 已关闭。
