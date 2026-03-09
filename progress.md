# Progress Log: Layer0+Layer1 梳理 + SIMD 整理

## Session: 2026-03-09

### Actions Taken
- 复核 Linux SIMD 主线：`gate-strict`、`freeze-status-linux`、`evidence-linux`、isolated `gate`、`backend-bench` 全部通过。
- 将 Windows B07 evidence workflow 改造成 Linux staging artifact + Windows download 模式，绕开 Windows checkout 非法路径。
- 修复 Windows evidence 链上的 PATH、batch root、自调用、verifier CRLF 兼容等问题。
- 同步剩余 SIMD 源码/测试改动到远端分支，消除 Windows CI 编译 blocker。
- 让 GitHub Windows runner 成功生成真实 `windows_b07_gate.log`，并通过 `verify_windows_b07_evidence.sh`。
- 运行 `finalize-win-evidence` 与 `apply_windows_b07_closeout_updates.sh --apply --batch-id SIMD-20260310-152`。
- 复核 `freeze-status`，确认 cross-platform `ready=True`。

### Test Results
| Command | Expected | Actual | Status |
|---------|----------|--------|--------|
| `bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict` | pass | `[GATE] OK` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux` | ready | `ready=True` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh evidence-linux` | pass | pass | PASS |
| `SIMD_OUTPUT_ROOT=/tmp/simd-cross-platform-audit bash tests/fafafa.core.simd/BuildOrTest.sh gate` | pass | pass | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh backend-bench` | pass | pass | PASS |
| GitHub Actions run `22867922511` | Windows evidence pass | success | PASS |
| `bash tests/fafafa.core.simd/verify_windows_b07_evidence.sh tests/fafafa.core.simd/logs/windows_b07_gate.log` | pass | pass | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh finalize-win-evidence --batch-id SIMD-20260310-152` | summary updated | pass | PASS |
| `bash tests/fafafa.core.simd/apply_windows_b07_closeout_updates.sh --apply --batch-id SIMD-20260310-152` | docs updated | pass | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status` | `ready=True` | `ready=True` | PASS |

### Notes
- 本地核对确认：当前 `freeze-status` 的 required 集合并不包含 QEMU / RISCVV；若要达成“全平台完整实现”，需要先抬高 acceptance criteria，而不是只跑现有 freeze。
- 本地核对确认：QEMU 脚本能力已存在，但文档与 matrix 仍把其视为后续项；`sbRISCVV` 仍在 STABLE / closeout 中被定义为 experimental。
- 当前最终平台口径：`Cross-platform ready`。
- Windows 实机 evidence 现由真实 GitHub Windows runner 产出，非模拟。
- closeout 文档回填 batch id：`SIMD-20260310-152`。

## Session: 2026-03-09 (Full-Platform Expansion)

### Actions Taken
- 将阶段目标从“Windows closeout”切换为“RISCVV / QEMU 全平台完整实现”。
- 建立新的文件化计划，准备对 non-x86 / RISCVV 缺口做系统摸底。

### Notes
- `qemu-arch-matrix-evidence` 已被收敛到 stable/public surface，并完成一次全平台 PASS：`386/amd64/arm-v7/arm64/riscv64`。
- `riscvv-opcode-lane` 已确认 compile-only PASS，但 runtime suite 仍引用缺失的 `TTestCase_NonX86IEEE754`。
- `qemu-cpuinfo-nonx86-full-evidence` 已定位到 ARM helper/behavior 与 RISCV helper/API 两大缺口，后续优先补生产实现，不再盲跑脚本。
- 已直接运行 `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arch-matrix-evidence` 做全平台摸底。
- 当前已确认的真实 blocker：i386 因 `IsNaNSingle` helper 条件编译缺失、arm/arm64/riscv64 因 `atomic` tagged ptr mask 常量与 AArch64-only NEON dot asm 泄漏、amd64 则是 arch-matrix 不该把 AVX2 experimental fallback suite 当成 stable/public surface 必测项。
- 已决定将 arch-matrix 口径收窄到 stable/public surface；experimental ASM 与 CPUInfo opt-in 走独立 lane。
- 当前起点：`freeze-status` 已经是 `ready=True`。
- 新阶段目标：提高完成度口径，而不是修复当前 freeze blocker。


### Actions Taken
- 重写/加固 `cpuinfo.arm` 与 `cpuinfo.riscv` 的非 x86 Linux parser，修复 ARM token 级 crypto/vendor 解析、RISC-V `rv64g`/misa/ISA 选择与 vendor/model 解析。
- 在 `fafafa.core.simd.cpuinfo.test.lpr` 上为 RISC-V runner cleanup 增加 `Halt(ExitCode)` 早退，消除 riscv64 QEMU 下“测试全绿但进程退出 AV”的假失败。
- 将 `run_riscvv_opcode_lane.sh` 改为真实 `SIMD_EXPERIMENTAL_RISCVV` opt-in，并把 runtime suite 切到 stable smoke（`TTestCase_Global` + `TTestCase_DispatchAPI`）。
- 修复 `src/fafafa.core.simd.riscvv.pas` 的 RVV/FPC 方言问题，令 dedicated RVV lane 完成真实 compile-only 与 stable smoke。
- 重新跑通 fresh `qemu-cpuinfo-nonx86-full-evidence` 与 fresh `qemu-arch-matrix-evidence`。
- 重跑 Linux `gate-strict`，确认 stable/public surface 主线无回归。

### Test Results
| Command | Expected | Actual | Status |
|---------|----------|--------|--------|
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-cpuinfo-nonx86-full-evidence` | pass | fresh PASS | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh riscvv-opcode-lane` | compile+smoke pass | compile PASS / stable smoke PASS / bench SKIP | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict` | pass | `[GATE] OK` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arch-matrix-evidence` | pass | fresh PASS | PASS |

### Notes
- 当前更准确的平台口径已提升为：stable/public surface 的 Linux+x86/arm/riscv QEMU 证据链闭环；`sbRISCVV` 仍是 experimental backend，但 compile + stable smoke evidence 已单独闭环。
- `qemu-nonx86-experimental-asm` 不再承担 RISC-V 真正 asm 能力证明；该职责已由 `riscvv-opcode-lane` 承担。
- `freeze-status` 仍沿用旧 required 集合；若本地 logs 被清理，需要重新拉回 Windows artifact 才能恢复 `ready=True`。

| `bash tests/fafafa.core.simd/run_windows_b07_closeout_via_github_actions.sh SIMD-20260310-152 22867922511` | restore real Windows artifact locally | pass + `ready=True` restored | PASS |

- 长期路线图：`docs/plans/2026-03-09-simd-long-range-roadmap.md`
| `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-full-platform` | full-platform evaluator ready | `ready=True` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux` | linux-only evaluator ready | `mode=linux, ready=True` | PASS |

## Session: 2026-03-09 (Phase 2 - AArch64 NEON Experimental Lane)

### Actions Taken
- 新建 Phase 2 计划：`docs/plans/2026-03-09-simd-aarch64-neon-experimental-lane-hardening.md`。
- 审计 `src/fafafa.core.simd.neon.pas` 的 arm64 probe 失败点，确认分布在 AArch64 asm 方言、`faddp`、`NEONMask*` / 宽向量注册面。
- 修改 `tests/fafafa.core.simd/docker/run_multiarch_qemu.sh`，让 `nonx86-experimental-asm` summary 能记录 `probe-pass` / `fallback-pass` / `fallback-fail`。

### Notes
- 当前 Phase 2 还在审计+lane 契约收敛阶段，尚未开始大规模修 `neon.pas`。
- 第一优先级是把 experimental arm64 lane 的结果说清楚，而不是抢先扩大 stable surface 声明。
| `SIMD_QEMU_ENABLE_BACKEND_ASM=1 bash tests/fafafa.core.simd/BuildOrTest.sh qemu-nonx86-experimental-asm` | probe/fallback summary truthfulness | PASS with `linux/arm64:fallback-pass`, `linux/riscv64:fallback-pass` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-asm` | dedicated arm64 experimental lane | PASS with `linux/arm64:probe-pass` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-asm` | dedicated arm64 experimental lane rerun | PASS with stable `linux/arm64:probe-pass` and no link-flake lines | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-report` | dedicated arm64 experimental report | PASS (`probe-pass`) | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-report` | scenario-specific experimental report outputs | PASS | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-asm` | dedicated arm64 lane after restoring safe phase2 state | PASS with `linux/arm64:probe-pass` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-asm` | arm64 lane after registration-boundary clarification | PASS with `linux/arm64:probe-pass` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-asm` | return to safe inline registration baseline | PASS with `linux/arm64:probe-pass` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-asm` | arm64 lane after `ApplyNEONMaskOverrides` extraction | PASS with `linux/arm64:probe-pass` | PASS |

## Session: 2026-03-09 (Phase 2 - F32 Wide Registration Helper Extraction)

### Actions Taken
- 在 `src/fafafa.core.simd.neon.pas` 中新增 `ApplyNEONExperimentalWideF32Overrides`，只抽离 experimental-wide `F32x8/F32x16` 注册项。
- 首轮 helper 因未放入同层 `{$IFNDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` guard，导致 arm64 dedicated probe build 报 `Identifier not found`；已改为 guarded helper。
- 重跑 `qemu-arm64-experimental-asm`、`qemu-arm64-experimental-report`、`qemu-arm64-experimental-baseline-check`，确认 dedicated lane 继续 `probe-pass` 且 blockers/baseline 归零。
- 重跑 fresh `qemu-arch-matrix-evidence` 与 `freeze-status-full-platform`，确认 stable/public surface Linux 主线无回归。

### Test Results
| Command | Expected | Actual | Status |
|---------|----------|--------|--------|
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-asm` | dedicated arm64 lane stays green | PASS with `linux/arm64:probe-pass` in `qemu-multiarch-20260309-142616-39694` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-report` | zero dedicated blockers | `Blockers: 0` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-baseline-check` | zero unexpected regressions | `actual=0, unexpected=0` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arch-matrix-evidence` | stable arch matrix remains green | all platforms PASS in `qemu-multiarch-20260309-142930-53109` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-full-platform` | full-platform ready unchanged | `ready=True` | PASS |

### Notes
- 这次 helper 抽离证明：`RegisterNEONBackend` 可以继续按族别小步外提，但每个 helper 都必须跟随其实际符号可见性的条件编译边界。
- 对 stable/public surface 真正有说服力的回归证据是 fresh `qemu-arch-matrix-evidence`，而不是仅复用旧 `freeze-status` 产物。

## Session: 2026-03-09 (Phase 2 - F64 + Narrow Integer Helper Extraction)

### Actions Taken
- 在 `src/fafafa.core.simd.neon.pas` 中新增 `ApplyNEONExperimentalWideF64Overrides`，将 experimental-wide `F64x2/F64x4/F64x8` 注册整体外提。
- 在同一 guard 内新增 `ApplyNEONExperimentalWideNarrowIntOverrides`，将 `I8x16/I16x8/U8x16/U16x8` 的 `Cmp*` / `Shift*` 注册独立外提。
- 分别重跑 dedicated arm64 lane、scenario report/baseline、以及 fresh stable `qemu-arch-matrix-evidence`，确认两轮 helper 抽离都没有带来回归。

### Test Results
| Command | Expected | Actual | Status |
|---------|----------|--------|--------|
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-asm` | arm64 lane stays green after F64+narrow-int helpers | PASS with `linux/arm64:probe-pass` in `qemu-multiarch-20260309-144733-120311` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-report` | zero dedicated blockers | `Blockers: 0` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-baseline-check` | zero unexpected regressions | `actual=0, unexpected=0` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arch-matrix-evidence` | stable arch matrix remains green after F64+narrow-int helpers | all platforms PASS in `qemu-multiarch-20260309-144945-130285` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-full-platform` | full-platform ready unchanged | `ready=True` | PASS |

### Notes
- `RegisterNEONBackend` 的 experimental-wide 区域现在已至少按 `F32`、`F64`、`narrow-int` 三个家族抽成 helper；继续推进时应优先考虑 `I32/U32`，最后再碰 `I64/U64`。

## Session: 2026-03-09 (Phase 2 - I32/U32 + I64/U64 Helper Extraction)

### Actions Taken
- 在 `src/fafafa.core.simd.neon.pas` 中新增 `ApplyNEONExperimentalWideI32U32Overrides`，将 experimental-wide `I32x4/I32x8/I32x16/U32x4/U32x8` 注册整体外提。
- 新增 `ApplyNEONExperimentalWideI64U64Overrides`，将 experimental-wide `I64x2/I64x4/I64x8/U64x4` 注册整体外提，完成 NEON experimental-wide register 区的家族化 helper 拆分。
- 过程中确认一个新的流程约束：不要并行跑两个都会构建 `aarch64-linux` 的 lane；并发会踩 `tests/fafafa.core.simd/lib2/aarch64-linux`，制造对象文件损坏与假链接错误。
- 清理 `tests/fafafa.core.simd/lib2/aarch64-linux` 与对应测试二进制后，串行重跑 dedicated arm64 lane、report/baseline、stable arch-matrix 与 freeze-status，最终证据恢复干净。

### Test Results
| Command | Expected | Actual | Status |
|---------|----------|--------|--------|
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-asm` | arm64 lane stays green after I32/U32+I64/U64 helpers | PASS with `linux/arm64:probe-pass` in `qemu-multiarch-20260309-152018-311706` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-report` | zero dedicated blockers | `Blockers: 0` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-baseline-check` | zero unexpected regressions | `actual=0, unexpected=0` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arch-matrix-evidence` | stable arch matrix remains green after all helper extraction | all platforms PASS in `qemu-multiarch-20260309-152247-329057` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-full-platform` | full-platform ready unchanged | `ready=True` | PASS |

### Notes
- `RegisterNEONBackend` 的 experimental-wide 注册已经全部家族化；后续如果继续推进，应优先处理实现函数层的 opcode / fallback / asm 方言问题，而不是再动大块注册结构。
- 验证层面新增一条硬规则：同一时间只允许一个 `aarch64-linux` lane 写 `tests/fafafa.core.simd/lib2/aarch64-linux`。

## Session: 2026-03-09 (Phase 2 - Implementation-Layer Composition Hardening)

### Actions Taken
- 将 `NEONDotF32x8`、`NEONDotF64x2`、`NEONDotF64x4` 的 asm-enabled 路径改为组合已稳定的窄 NEON `Dot/Mul/ReduceAdd`。
- 将 `NEONReduceAddF32x8_ASM` / `NEONReduceAddF32x16_ASM` 从直接 `ScalarReduceAdd*` 替换为按 `lo/hi` 组合窄 NEON 的 reduce。
- 将 `NEONSplatF64x4_ASM` / `NEONSplatF64x8_ASM` 改为按 `lo/hi` 组合 narrower splat；将 wide float `Add/Sub/Mul/Div`（`F32x8/F32x16/F64x4/F64x8`）改为组合窄 NEON。
- 严格串行验证 dedicated arm64 lane、report/baseline、stable arch-matrix 与 freeze-status，确认实现层 hardening 没有污染主线。

### Test Results
| Command | Expected | Actual | Status |
|---------|----------|--------|--------|
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-asm` | arm64 lane stays green after implementation-layer hardening | PASS with `linux/arm64:probe-pass` in `qemu-multiarch-20260309-154903-483461` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-report` | zero dedicated blockers | `Blockers: 0` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-baseline-check` | zero unexpected regressions | `actual=0, unexpected=0` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arch-matrix-evidence` | stable arch matrix remains green after implementation-layer hardening | all platforms PASS in `qemu-multiarch-20260309-155202-503518` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-full-platform` | full-platform ready unchanged | `ready=True` | PASS |

### Notes
- 当前实现层 hardening 证明：很多 wide NEON 路径可以先用“窄 NEON 组合”收敛，而不需要立即重写复杂 AArch64 汇编。
- 下一轮如果继续，应优先处理 wide `Abs/Min/Max/Sqrt/Floor/Ceil/Round/Trunc/Fma/Clamp/Select` 这类仍直接掉 `Scalar*` 的浮点族。

## Session: 2026-03-09 (Phase 2 - Wide Float Math/Compare Hardening)

### Actions Taken
- 将 wide float `Abs/Min/Max/Sqrt/Floor/Ceil/Round/Trunc/Fma/Clamp`（`F32x8/F32x16/F64x4/F64x8`）从直接 `Scalar*` 改为 `lo/hi` 组合窄 NEON。
- 将 wide float `CmpEq/CmpGe/CmpGt/CmpLe/CmpLt/CmpNe`（`F32x8/F32x16/F64x4/F64x8`）从直接 `ScalarCmp*` 改为组合窄 compare 并合并 bitmask。
- 为实现区中先调用后定义的 `F32x8` compare/math wrappers 增加 `forward` 声明，修复 `arm/v7` stable lane 的 Pascal 前向可见性问题。
- 串行清理 `aarch64-linux` / `arm-linux` 产物并重跑 dedicated arm64、report/baseline、stable arch-matrix、freeze-status，确认这轮 hardening 无回归。

### Test Results
| Command | Expected | Actual | Status |
|---------|----------|--------|--------|
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-asm` | arm64 lane stays green after wide-float math/compare hardening | PASS with `linux/arm64:probe-pass` in `qemu-multiarch-20260309-204347-665815` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-report` | zero dedicated blockers | `Blockers: 0` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-baseline-check` | zero unexpected regressions | `actual=0, unexpected=0` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arch-matrix-evidence` | stable arch matrix remains green after wide-float math/compare hardening | all platforms PASS in `qemu-multiarch-20260309-204526-670171` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-full-platform` | full-platform ready unchanged | `ready=True` | PASS |

### Notes
- 现在 wide float 还大面积直接掉 `Scalar*` 的主要只剩 `Select`、`Load/Extract/Insert`、以及部分 `Reduce*/Splat/Zero/Rcp`。
- 下一轮最合理的是补 `Select` 与 `Load/Extract/Insert`，它们能进一步清掉 wide float façade 的剩余 scalar 依赖。

## Session: 2026-03-09 (Phase 2 - Wide Float Select/Load/Extract/Insert Hardening)

### Actions Taken
- 将 wide float `Select + Load/Extract/Insert`（`F32x8/F32x16/F64x4/F64x8`）从直接 `Scalar*` 改为 `lo/hi` 组合窄 NEON。
- 为 `F32x16` 先调用 `F32x8` 的实现链补充 `forward` 声明，修复 Pascal 实现区的顺序可见性问题。
- 串行清理 `aarch64-linux` / `arm-linux` 产物并重跑 dedicated arm64、report/baseline、stable arch-matrix、freeze-status，确认该轮 hardening 无回归。

### Test Results
| Command | Expected | Actual | Status |
|---------|----------|--------|--------|
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-asm` | arm64 lane stays green after wide-float select/load/extract/insert hardening | PASS with `linux/arm64:probe-pass` in `qemu-multiarch-20260309-210439-771359` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-report` | zero dedicated blockers | `Blockers: 0` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-baseline-check` | zero unexpected regressions | `actual=0, unexpected=0` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arch-matrix-evidence` | stable arch matrix remains green after wide-float select/load/extract/insert hardening | all platforms PASS in `qemu-multiarch-20260309-210621-775332` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-full-platform` | full-platform ready unchanged | `ready=True` | PASS |

### Notes
- wide float façade 中剩余最显眼的直接 `Scalar*` 依赖已经大幅下降；下一刀更适合回到 wide integer bitwise/utility 族，或者专门处理 `RcpF64x4` 这类孤立点。

## Session: 2026-03-09 (Phase 2 - Wide Integer Bitwise Hardening)

### Actions Taken
- 将 wide integer bitwise `And/AndNot/Or/Xor/Not` 中的 `I32/I64/U32` 路径从直接 `Scalar*` 改为 `lo/hi` 组合窄 NEON；`U32x4` 改为显式逐 lane 实现。
- 修正 `I64x4 AndNot` 的等价实现：用 `NEONAndI64x2(a, NEONNotI64x2(b))` 代替不存在的 `NEONAndNotI64x2`。
- 串行清理 `aarch64-linux` / `arm-linux` 产物并重跑 dedicated arm64、report/baseline、stable arch-matrix、freeze-status，确认该轮 hardening 无回归。

### Test Results
| Command | Expected | Actual | Status |
|---------|----------|--------|--------|
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-asm` | arm64 lane stays green after wide-integer bitwise hardening | PASS with `linux/arm64:probe-pass` in `qemu-multiarch-20260309-212410-857149` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-report` | zero dedicated blockers | `Blockers: 0` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-baseline-check` | zero unexpected regressions | `actual=0, unexpected=0` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arch-matrix-evidence` | stable arch matrix remains green after wide-integer bitwise hardening | all platforms PASS in `qemu-multiarch-20260309-212603-865400` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-full-platform` | full-platform ready unchanged | `ready=True` | PASS |

### Notes
- wide integer 接下来最适合继续收的，是 `Add/Sub/Min/Max/Compare/Shift/Select/Load/Extract/Insert` 这些仍直接掉 `Scalar*` 的族。

## Session: 2026-03-09 (Phase 2 - Wide Integer Arithmetic/MinMax Hardening)

### Actions Taken
- 将有现成窄 helper 的 wide integer `Add/Sub/Mul/Min/Max`（主要是 `I32/I64/U32` 路径）从直接 `Scalar*` 改为 `lo/hi` 组合窄 NEON。
- 本轮明确跳过 `U64x4` 的算术/最值族，先不引入新的逐 lane 语义实现。
- 串行清理 `aarch64-linux` / `arm-linux` 产物并重跑 dedicated arm64、report/baseline、stable arch-matrix、freeze-status，确认该轮 hardening 无回归。

### Test Results
| Command | Expected | Actual | Status |
|---------|----------|--------|--------|
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-asm` | arm64 lane stays green after wide-integer arithmetic/minmax hardening | PASS with `linux/arm64:probe-pass` in `qemu-multiarch-20260309-213748-906016` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-report` | zero dedicated blockers | `Blockers: 0` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-baseline-check` | zero unexpected regressions | `actual=0, unexpected=0` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arch-matrix-evidence` | stable arch matrix remains green after wide-integer arithmetic/minmax hardening | all platforms PASS in `qemu-multiarch-20260309-213927-909069` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-full-platform` | full-platform ready unchanged | `ready=True` | PASS |

### Notes
- 下一轮最合理的是继续收 `wide integer compare + shift + extract/insert/select/load`，或者回到 `U64x4` 这类缺窄 helper 的孤立点。

## Session: 2026-03-09 (Phase 2 - Wide Integer Access/Selection Hardening)

### Actions Taken
- 将 `I32/I64` 的 wide `extract/insert/load/select` façade 从直接 `Scalar*` 改为 `lo/hi` 组合或显式逐 lane 实现。
- 补齐了 `NEONCmpNeU32x4` 的 fallback 实现，并把 `I64x4` 左/右移改成逐 lane 版本，避免依赖不存在的 `I64x2` shift helper。
- 串行清理 `aarch64-linux` / `arm-linux` 产物并重跑 dedicated arm64、report/baseline、stable arch-matrix、freeze-status，确认该轮 hardening 无回归。

### Test Results
| Command | Expected | Actual | Status |
|---------|----------|--------|--------|
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-asm` | arm64 lane stays green after wide-integer access/selection hardening | PASS with `linux/arm64:probe-pass` in `qemu-multiarch-20260309-222416-1142098` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-report` | zero dedicated blockers | `Blockers: 0` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-baseline-check` | zero unexpected regressions | `actual=0, unexpected=0` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arch-matrix-evidence` | stable arch matrix remains green after wide-integer access/selection hardening | all platforms PASS in `qemu-multiarch-20260309-225005-1278406` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-full-platform` | full-platform ready unchanged | `ready=True` | PASS |

### Notes
- wide integer 现在剩余最显眼的直接 `Scalar*` 依赖主要集中在 `U64x4` 孤点，以及少量窄 `I32x4/U32x4` 的基础 fallback。

## Session: 2026-03-09 (Phase 2 - Wide Integer Compare/Shift Hardening)

### Actions Taken
- 将有现成窄 helper 的 wide integer `compare + shift`（主要是 `I32/I64/U32`）从直接 `Scalar*` 改为 `lo/hi` 组合窄 NEON。
- 再次确认 `I64x4` 左/右移没有 `I64x2` helper 可复用，因此稳定方案是逐 lane 实现。
- 串行清理 `aarch64-linux` / `arm-linux` 产物并重跑 dedicated arm64、report/baseline、stable arch-matrix、freeze-status，确认该轮 hardening 无回归。

### Test Results
| Command | Expected | Actual | Status |
|---------|----------|--------|--------|
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-asm` | arm64 lane stays green after wide-integer compare/shift hardening | PASS with `linux/arm64:probe-pass` in `qemu-multiarch-20260309-222912-1173344` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-report` | zero dedicated blockers | `Blockers: 0` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-baseline-check` | zero unexpected regressions | `actual=0, unexpected=0` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arch-matrix-evidence` | stable arch matrix remains green after wide-integer compare/shift hardening | all platforms PASS in `qemu-multiarch-20260309-223050-1177262` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-full-platform` | full-platform ready unchanged | `ready=True` | PASS |

### Notes
- wide integer 剩余最显眼的孤点已经收窄到 `U64x4` 一族，以及部分窄 `I32x4/U32x4` 基础 fallback。

## Session: 2026-03-09 (Phase 2 - U64x4 Isolated Hardening)

### Actions Taken
- 将 `U64x4` 的 `bitwise + compare + shift` 从直接 `Scalar*` 改为本地逐 lane 实现。
- 串行清理 `aarch64-linux` / `arm-linux` 产物并重跑 dedicated arm64、report/baseline、stable arch-matrix、freeze-status，确认这批孤点改动无回归。

### Test Results
| Command | Expected | Actual | Status |
|---------|----------|--------|--------|
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-asm` | arm64 lane stays green after U64x4 hardening | PASS with `linux/arm64:probe-pass` in `qemu-multiarch-20260309-232853-1440501` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-report` | zero dedicated blockers | `Blockers: 0` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-baseline-check` | zero unexpected regressions | `actual=0, unexpected=0` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arch-matrix-evidence` | stable arch matrix remains green after U64x4 hardening | all platforms PASS in `qemu-multiarch-20260309-234221-1513375` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-full-platform` | full-platform ready unchanged | `ready=True` | PASS |

### Notes
- 当前剩余明显的 `Scalar*` 依赖已经主要收缩到少量窄 `I32x4/U32x4` 基础 fallback，以及 `U64x4 add/sub` 这类仍需明确是否值得继续本地化的点。

## Session: 2026-03-10 (Phase 2 - Narrow Integer Tail Cleanup)

### Actions Taken
- 将剩余的窄 `I32x4/U32x4` 基础 fallback（`compare/minmax/shift` 等）改为本地逐 lane 实现，尽量清空该段显眼的 `Scalar*` 依赖。
- 串行清理 `aarch64-linux` / `arm-linux` 产物并重跑 dedicated arm64、report/baseline、stable arch-matrix、freeze-status，确认该轮 cleanup 无回归。

### Test Results
| Command | Expected | Actual | Status |
|---------|----------|--------|--------|
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-asm` | arm64 lane stays green after narrow-int tail cleanup | PASS with `linux/arm64:probe-pass` in `qemu-multiarch-20260310-002806-1725327` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-report` | zero dedicated blockers | `Blockers: 0` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-baseline-check` | zero unexpected regressions | `actual=0, unexpected=0` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arch-matrix-evidence` | stable arch matrix remains green after narrow-int tail cleanup | all platforms PASS in `qemu-multiarch-20260310-003117-1738835` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-full-platform` | full-platform ready unchanged | `ready=True` | PASS |

### Notes
- 当前 `neon.pas` 在主实现区里显眼的整数 `Scalar*` 依赖已经显著减少；下一轮若继续，应转去 `saturating/narrow-int` 或 `reduce/zero/rcp` 这类剩余块。

## Session: 2026-03-10 (Phase 2 - Integer Scalar Cleanup Milestone)

### Actions Taken
- 重写 `saturating + narrow-int + I64x2 + mask ops`，并补齐剩余 `I32/U32/U64` 的基础 fallback，使 `neon.pas` 目标实现区中的整数 `Scalar*` 依赖基本清空。
- 多次串行清理 `aarch64-linux` / `arm-linux` 产物并重跑 dedicated arm64、report/baseline、stable arch-matrix、freeze-status，确认清理后的实现层仍稳定。

### Test Results
| Command | Expected | Actual | Status |
|---------|----------|--------|--------|
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-asm` | arm64 lane stays green after integer scalar cleanup | PASS with `linux/arm64:probe-pass` in `qemu-multiarch-20260310-005735-1893012` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-report` | zero dedicated blockers | `Blockers: 0` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-baseline-check` | zero unexpected regressions | `actual=0, unexpected=0` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arch-matrix-evidence` | stable arch matrix remains green after integer scalar cleanup | all platforms PASS in `qemu-multiarch-20260310-010522-1949191` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-full-platform` | full-platform ready unchanged | `ready=True` | PASS |

### Notes
- 下一阶段最值当的目标已从“整数 `Scalar*` 收尾”切到“`reduce/zero/splat/rcp` 等剩余 façade hardening”，以及需要判断是否继续处理非关键的 ASCII/mem façade。
