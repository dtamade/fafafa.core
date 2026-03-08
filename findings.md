# Findings & Decisions: Layer0+Layer1 梳理 + SIMD 整理

## Requirements
- 目标：把 Layer0/Layer1 的“发现问题 → 处理问题”过程结构化（可复现、可追溯、可持续维护）。
- 重点：SIMD 模块完成度未知且结构较乱，需要先建立地图与完成定义，再做收敛式修复。
- 约束：避免未经讨论的大重构；优先用最小改动解决高风险问题，并用测试回归兜底。

## Observations
- Linux 主线 gate 与 freeze 基线稳定，Windows 实机 evidence 是跨平台 freeze 的唯一真实 blocker。
- GitHub Windows runner 初始被 billing、Windows checkout 非法路径、Lazarus/FPC PATH、batch 自调用、CRLF verifier 兼容性等问题阻塞。
- 这些 blocker 清掉后，Windows runner 已能生成真实 `windows_b07_gate.log`，且包含真实 Windows 字段与非模拟内容。

## Decisions
| Decision | Rationale | Evidence |
|----------|-----------|----------|
| 用 Linux staging artifact + Windows download 替代 Windows checkout | 绕开仓库中的 Windows 非法路径 | `.github/workflows/simd-windows-b07-evidence.yml` |
| 保持 verifier 严格，只修正 CRLF 兼容 | 不放松验收标准，只让 Windows 行尾可正确校验 | `tests/fafafa.core.simd/verify_windows_b07_evidence.sh` |
| 将 Windows evidence collector 改为显式 3 步 closeout gate | 避免 Windows `gate` 主入口的历史批处理兼容问题，同时保留真实实机执行 | `tests/fafafa.core.simd/collect_windows_b07_evidence.bat` |
| 以 batch id `SIMD-20260309-152` 完成 closeout apply | 与 real summary / docs 回填保持一致 | `tests/fafafa.core.simd/logs/windows_b07_closeout_summary.md` |

## Risks / Open Questions
- Windows evidence workflow 目前采用 closeout-specific collector，而不是直接复用完整 `gate` 主入口；后续如需统一，可再做单独收敛。

## Resources (paths / links)
- `docs/fafafa.core.simd.handoff.md`
- `docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md`
- `docs/plans/2026-03-09-simd-full-platform-completeness.md`
- `tests/fafafa.core.simd/logs/windows_b07_gate.log`
- `tests/fafafa.core.simd/logs/windows_b07_closeout_summary.md`
- `tests/fafafa.core.simd/logs/freeze_status.json`

## SIMD Full-Platform Expansion Notes (2026-03-09)

- `evaluate_simd_freeze_status.py` 当前 required 项只包含 Linux gate + Windows evidence / closeout，QEMU / RISCVV 不在 required 集合内。
- `src/fafafa.core.simd.STABLE` 与 `docs/fafafa.core.simd.closeout.md` 仍明确把 `sbRISCVV` 定义为 experimental / limited-maturity backend。
- `tests/fafafa.core.simd/docker/run_multiarch_qemu.sh` 已支持 `nonx86-evidence` / `arch-matrix-evidence` / `nonx86-experimental-asm` / `cpuinfo-*` alias，但默认 gate 不把这些设成 required。
- `tests/fafafa.core.simd/docs/simd_completeness_matrix.md` 仍有 `QEMU CPUInfo opt-in 证据链已对齐` 未完成项。
- Windows closeout is no longer the blocker; cross-platform freeze is already `ready=True`.
- Next scope is stronger than current freeze: QEMU / non-x86 evidence and RISCVV maturity.
- Current docs still state `sbRISCVV` is explicit opt-in experimental and not part of stable/platform-complete support.
- Current QEMU actions exist, but are not required by the cross-platform freeze gate.
- 本机环境具备 `docker` 与 `qemu-riscv64/qemu-aarch64/qemu-x86_64`，可直接重跑 QEMU / non-x86 evidence。
- 当前 `qemu_experimental_report` 报的是“missing experimental summary directory”，说明不是环境缺失，而是尚无最新 `nonx86-experimental-asm` 汇总产物。
- 因此下一步应直接跑 QEMU scenario，先得到真实 non-x86 / RISCVV 证据，再决定是补脚本还是补实现。
- QEMU / non-x86 的真实缺口不只是“还没纳入 gate”，还包括 raw evidence retention、CPUInfo alias 只是折叠到 `nonx86-evidence`、以及 docs/checklist/matrix 未拆成可验收条目。
- `freeze-status` 当前完全不看 QEMU/non-x86 产物，因此现有 `ready=True` 不能代表“全平台完整实现”。
- 现成最小收敛路径应至少覆盖：`qemu-arch-matrix-evidence`、`qemu-nonx86-evidence`、`qemu-nonx86-experimental-asm` / baseline，以及对应文档/状态机接线。
- `src/fafafa.core.simd.riscvv.pas` 是一个非常大的已注册 backend，但它仍然走老的 `TSimdDispatchTable` 路线，且大量 façade 能力只是 scalar delegation。
- `cpuinfo.riscv` 当前 `HasV` 判定过于宽松（`Pos('v', isa) > 0`），会误导 dispatch 把 `sbRISCVV` 当成可用 backend。
- `riscv32` 当前会注册 `sbRISCVV`，但 asm 只在 `CPURISCV64 + SIMD_BACKEND_RISCVV` 下启用，因此形成“注册了 RISCVV、实际却是 scalar fallback”的假象。
- 真正的 RVV 运行覆盖不足：现在主要是 demo / wrapper 级验证，缺少正式 backend smoke / activation / CI lane。
- 源码 opt-in 宏 `SIMD_EXPERIMENTAL_RISCVV` 与 docker/QEMU lane 使用的 `FAFAFA_SIMD_*` 宏目前不一致，脚本和源码口径分裂。
