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
