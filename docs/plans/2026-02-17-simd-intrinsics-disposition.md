# SIMD Intrinsics Disposition (Task 4)

## Goal
- Give explicit A/B/C decisions for low-reach intrinsics-related units.
- Keep default gate path trustworthy by isolating semantic placeholders.

## Decision Matrix

### A - Active in default quality chain
- `fafafa.core.simd.intrinsics.sse`: stable, direct tests in `tests/fafafa.core.simd.intrinsics.sse`.
- `fafafa.core.simd.intrinsics.mmx`: stable, direct tests in `tests/fafafa.core.simd.intrinsics.mmx`.
- `fafafa.core.simd.intrinsics.avx2`: active via fallback suite and AVX2 mapping checker.

### B - Experimental (kept, but isolated from default entry)
- `fafafa.core.simd.intrinsics.aes`
- `fafafa.core.simd.intrinsics.sha`
- `fafafa.core.simd.intrinsics.avx`
- `fafafa.core.simd.intrinsics.sse2`
- `fafafa.core.simd.intrinsics.sse3`
- `fafafa.core.simd.intrinsics.sse41`
- `fafafa.core.simd.intrinsics.sse42`
- `fafafa.core.simd.intrinsics.avx512`
- `fafafa.core.simd.intrinsics.fma3`
- `fafafa.core.simd.intrinsics.neon`
- `fafafa.core.simd.intrinsics.rvv`
- `fafafa.core.simd.intrinsics.sve`
- `fafafa.core.simd.intrinsics.sve2`
- `fafafa.core.simd.intrinsics.lasx`
- `fafafa.core.simd.intrinsics.x86.sse2`

Status rule:
- Source files retain explicit experimental note.
- Default entry chain must not reference the above units.
- Isolation is enforced by:
  - `tests/fafafa.core.simd/check_intrinsics_experimental_status.py`
  - `tests/fafafa.core.simd/BuildOrTest.sh` (`check` + `gate`)
  - `tests/fafafa.core.simd/buildOrTest.bat` (`check` + `gate`)

### C - Archive/Delete
- None in this batch.
- Reason: some units are still useful as future implementation scaffolding, and hard-delete would risk hidden downstream references.

## Verification
- `python3 tests/fafafa.core.simd/check_intrinsics_experimental_status.py`
- `bash tests/fafafa.core.simd/BuildOrTest.sh check`
- `bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict`

## Follow-up
- Add direct tests and semantic implementations for one experimental family at a time (recommended order: `aes/sha` -> `sse2` -> `avx512` -> non-x86 intrinsics).
