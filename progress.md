# Progress Log: Layer0+Layer1 梳理 + SIMD 整理

## Session: 2026-03-09

### Actions Taken
- 复核 Linux SIMD 主线：`gate-strict`、`freeze-status-linux`、`evidence-linux`、isolated `gate`、`backend-bench` 全部通过。
- 将 Windows B07 evidence workflow 改造成 Linux staging artifact + Windows download 模式，绕开 Windows checkout 非法路径。
- 修复 Windows evidence 链上的 PATH、batch root、自调用、verifier CRLF 兼容等问题。
- 同步剩余 SIMD 源码/测试改动到远端分支，消除 Windows CI 编译 blocker。
- 让 GitHub Windows runner 成功生成真实 `windows_b07_gate.log`，并通过 `verify_windows_b07_evidence.sh`。
- 运行 `finalize-win-evidence` 与 `apply_windows_b07_closeout_updates.sh --apply --batch-id SIMD-20260309-152`。
- 复核 `freeze-status`，确认 cross-platform `ready=True`。

### Test Results
| Command | Expected | Actual | Status |
|---------|----------|--------|--------|
| `bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict` | pass | `[GATE] OK` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux` | ready | `ready=True` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh evidence-linux` | pass | pass | PASS |
| `SIMD_OUTPUT_ROOT=/tmp/simd-cross-platform-audit bash tests/fafafa.core.simd/BuildOrTest.sh gate` | pass | pass | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh backend-bench` | pass | pass | PASS |
| GitHub Actions run `22831091227` | Windows evidence pass | success | PASS |
| `bash tests/fafafa.core.simd/verify_windows_b07_evidence.sh tests/fafafa.core.simd/logs/windows_b07_gate.log` | pass | pass | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh finalize-win-evidence --batch-id SIMD-20260309-152` | summary updated | pass | PASS |
| `bash tests/fafafa.core.simd/apply_windows_b07_closeout_updates.sh --apply --batch-id SIMD-20260309-152` | docs updated | pass | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status` | `ready=True` | `ready=True` | PASS |

### Notes
- 本地核对确认：当前 `freeze-status` 的 required 集合并不包含 QEMU / RISCVV；若要达成“全平台完整实现”，需要先抬高 acceptance criteria，而不是只跑现有 freeze。
- 本地核对确认：QEMU 脚本能力已存在，但文档与 matrix 仍把其视为后续项；`sbRISCVV` 仍在 STABLE / closeout 中被定义为 experimental。
- 当前最终平台口径：`Cross-platform ready`。
- Windows 实机 evidence 现由真实 GitHub Windows runner 产出，非模拟。
- closeout 文档回填 batch id：`SIMD-20260309-152`。

## Session: 2026-03-09 (Full-Platform Expansion)

### Actions Taken
- 将阶段目标从“Windows closeout”切换为“RISCVV / QEMU 全平台完整实现”。
- 建立新的文件化计划，准备对 non-x86 / RISCVV 缺口做系统摸底。

### Notes
- 已直接运行 `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arch-matrix-evidence` 做全平台摸底。
- 当前已确认的真实 blocker：i386 因 `IsNaNSingle` helper 条件编译缺失、arm/arm64/riscv64 因 `atomic` tagged ptr mask 常量与 AArch64-only NEON dot asm 泄漏、amd64 则是 arch-matrix 不该把 AVX2 experimental fallback suite 当成 stable/public surface 必测项。
- 已决定将 arch-matrix 口径收窄到 stable/public surface；experimental ASM 与 CPUInfo opt-in 走独立 lane。
- 当前起点：`freeze-status` 已经是 `ready=True`。
- 新阶段目标：提高完成度口径，而不是修复当前 freeze blocker。

