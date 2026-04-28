# Experimental ASM Compiler-Ready Blockers

## Latest Wave (2026-04-27, 13:05)

- canonical compiler-ready lane (`qemu-experimental-compiler-ready`): PASS
  - summary: `tests/fafafa.core.simd/logs/qemu-multiarch-20260427-124015-143571/summary.md`
- host-local strict closeout (`closeout-host-local`, default `SIMD_GATE_QEMU_EXPERIMENTAL_COMPILER_READY=1`): PASS
  - compiler-ready summary: `tests/fafafa.core.simd/logs/qemu-multiarch-20260427-130154-189643/summary.md`
  - gate summary: `tests/fafafa.core.simd/logs/gate_summary.md` (`gate PASS @ 2026-04-27 13:05:21`)
- linux-only freeze (`SIMD_FREEZE_REQUIRE_QEMU_EXPERIMENTAL_COMPILER_READY=1`): PASS
  - output: `tests/fafafa.core.simd/logs/freeze_status.json` (`ready=True, mainline-ready=True`)

## 2026-04-28 RVV Opcode-Ready Runtime Correctness Closeout

- compiler-ready promotion lane remains green; this wave did not redefine compiler-ready boundaries
- dedicated opcode-ready lane fresh rerun: PASS
  - summary: `tests/fafafa.core.simd/logs/rvv-opcode-lane-20260428-050438/summary.md`
  - layered acceptance:
    - compile-only (`project`): PASS
    - suite (`TTestCase_NonX86IEEE754,TTestCase_NonX86BackendParity`): PASS
    - bench (`RISCVV_vs_Scalar`): PASS
- this wave fixed runtime correctness inside the existing opcode-ready lane:
  - narrow `AndNot` wrapper semantics were normalized to `(~a) & b`
  - `CmpNeU32x8/CmpNeU64x4` LMUL>1 source overlap was removed
  - `TMask8/TMask16` compare returns now normalize the whole mask width instead of leaking high-bit garbage
- supporting source-proof also moved forward:
  - `python3 tests/fafafa.core.simd/check_riscvv_abi_shape.py --summary-line` now reports `explicit_checks=22`
  - the `DispatchAPI` truth surface no longer carries stale `wide Trunc backend-owned` assertions

## Contract Boundary (Default vs Promoted Lanes)

1. default `qemu-nonx86-experimental-asm` baseline lane keeps `SIMD_QEMU_ENABLE_BACKEND_ASM=0` and is validated by `qemu-experimental-baseline-check` against `experimental_asm_expected_failures.json`.
2. opt-in probe lane uses `SIMD_QEMU_ENABLE_BACKEND_ASM=1` with default `SIMD_QEMU_BACKEND_ASM_PROBE_MODE=1`; a backend-asm compile failure may retry the fallback path and still keep the scenario PASS.
3. this document tracks the promoted compiler-ready lane: `SIMD_QEMU_ENABLE_BACKEND_ASM=1` plus `FAFAFA_SIMD_NEON_ASM_COMPILER_READY` / `FAFAFA_SIMD_RISCVV_ASM_COMPILER_READY`.
4. RVV opcode-ready validation remains a separate `riscvv-opcode-lane` concern and is not part of the default QEMU baseline lane.

## Dedicated RVV Lane Status (Current)

| Item | Status | Evidence |
|---|---|---|
| compile-only (`project`) opcode verification (prebuilt patched compiler + qemu-x86_64 wrapper) | PASS | `tests/fafafa.core.simd/logs/rvv-opcode-lane-20260428-050438/compile_only.log` |
| suite (`TTestCase_NonX86IEEE754,TTestCase_NonX86BackendParity`) under opcode-ready runtime define | PASS | `tests/fafafa.core.simd/logs/rvv-opcode-lane-20260428-050438/suite.log` |
| bench (`RISCVV_vs_Scalar`) under opcode-ready runtime define | PASS | `tests/fafafa.core.simd/logs/rvv-opcode-lane-20260428-050438/bench.log` |

## Lane Architecture (Now)

1. default `compile_target` is `project`.
2. prebuilt compiler defaults to `/opt/fpcupdeluxe/fpcsrc/compiler/ppcrossrv64_v`.
3. prebuilt units defaults to `/opt/fpcupdeluxe/fpc-rvv-units/riscv64-linux`.
4. smoke lane no longer rewrites asm `.attribute`; it now relies on patched compiler output end-to-end.
5. dedicated opcode-ready lane intentionally keeps `...RISCVV_ASM_OPCODE_READY` in both compile and runtime phases; the stable compiler-ready promotion lane remains a separate, greener contract.

## Resolved Blockers

- `COMPILE_TARGET=project` full target compile under prebuilt patched toolchain: RESOLVED.
- RVV asm attribute workaround in smoke lane: REMOVED.
- RVV lane default promotion from `smoke` to `project`: COMPLETED.
- AArch64 `ppca64` rejected `uxtw` in `I64x2/I64x4` shift helpers: RESOLVED by switching to the compiler-accepted zero-extension pattern (`mov w?, w?` before `dup v?.2d`).
- NEON utility include split broke both compiler-ready asm and scalar-only compile paths: RESOLVED by splitting utility ownership (`shared_utility.inc` only for asm-enabled builds, full `scalar.utility.inc` restored for scalar-only builds).

## Remaining Blockers For Compiler-Ready Lane (Current)

- none (with default `SIMD_QEMU_BUILD_POLICY=if-missing` and warm local images)
- note: if forcing `SIMD_QEMU_BUILD_POLICY=always`, intermittent Docker Hub metadata/network issues can still surface in external environments.
- note: cross-platform `freeze-status` after this source wave still needs fresh Windows evidence on a pushed ref; that is a release-evidence follow-up, not a compiler-ready lane blocker.

## Experimental ASM Probe Snapshot

- latest asm probe report: `tests/fafafa.core.simd/docs/experimental_asm_blockers.md`
- latest default probe summary: `tests/fafafa.core.simd/logs/qemu-multiarch-20260427-040328-242408/summary.md`
- baseline check: `tests/fafafa.core.simd/docs/experimental_asm_expected_failures.json`
- note: the default probe snapshot is green without backend-asm opt-in; it is a different contract from the compiler-ready lane documented above.

## Historical References

- prior failing project-target wave: `tests/fafafa.core.simd/logs/rvv-opcode-lane-20260221-221228/summary.md`
- prior smoke-attribute workaround wave: `tests/fafafa.core.simd/logs/rvv-opcode-lane-20260221-215626/summary.md`
