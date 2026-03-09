# fafafa.core.simd handoff

## 2026-03-09 状态

- Platform claim: `Cross-platform ready`; fresh `full-platform ready` evaluator is now also green for stable/public surface
- Linux gate baseline remains green.
- Windows B07 real evidence is archived and verifier-clean.
- Freeze status is now `ready=True` for `cross-platform`, and `freeze-status-full-platform` is also `ready=True`.

## Acceptance Summary

- Interface status: `TSimdDispatchTable` / facade / base fill completeness checks pass.
- Architecture status: stable facade + dispatch + adapter contract remains intact; Windows closeout uses real evidence instead of relaxed verification.
- Implementation status: Linux gate and fresh QEMU stable/public-surface evidence are green; Windows evidence remains the freeze gate artifact, and `sbRISCVV` stays experimental but now has dedicated compile+stable-smoke evidence.

## Evidence Paths

- Linux evidence summary: `tests/fafafa.core.simd/logs/evidence-20260309-004805-405472/summary.md`
- Backend bench summary: `tests/fafafa.core.simd/logs/backend-bench-20260309-004805-405593/summary.md`
- QEMU arch-matrix summary: `tests/fafafa.core.simd/logs/qemu-multiarch-20260309-092825-2802652/summary.md`
- QEMU CPUInfo full summary: `tests/fafafa.core.simd/logs/qemu-multiarch-20260309-095506-2972416/summary.md`
- RVV opcode lane summary: `tests/fafafa.core.simd/logs/rvv-opcode-lane-20260309-095506/summary.md`
- Arm64 experimental lane summary: `tests/fafafa.core.simd/logs/qemu-multiarch-20260309-120823-3707594/summary.md`
- Windows evidence log: `tests/fafafa.core.simd/logs/windows_b07_gate.log`
- Windows closeout summary: `tests/fafafa.core.simd/logs/windows_b07_closeout_summary.md`
- Freeze JSON: `tests/fafafa.core.simd/logs/freeze_status.json`
- Full-platform freeze command: `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-full-platform`

## Windows Evidence Commands

- GitHub Actions workflow: `.github/workflows/simd-windows-b07-evidence.yml`
- GitHub Actions wrapper: `bash tests/fafafa.core.simd/run_windows_b07_closeout_via_github_actions.sh SIMD-20260310-152`
- GitHub Actions run: `22867922511`
- Windows collector: `tests\fafafa.core.simd\collect_windows_b07_evidence.bat`
- Windows verifier: `tests\fafafa.core.simd\verify_windows_b07_evidence.bat`
- Operator-equivalent command: `tests\fafafa.core.simd\buildOrTest.bat evidence-win-verify`
- Final apply batch id: `SIMD-20260310-152`

- Arm64 experimental report: `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-report`
- Arm64 experimental baseline check: `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-baseline-check`
