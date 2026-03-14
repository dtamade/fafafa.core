# SIMD x86 SSE2 Byte-Shift Intrinsics Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make experimental x86 SSE2 byte-shift helpers (`simd_slli_si128`, `simd_srli_si128`, `simd_srai_si128`) correct for all shift counts, and lock semantics with tests.

**Architecture:** Keep the existing SSE2 inline-asm approach (because `pslldq/psrldq` require an immediate), but extend the branch table to cover every shift count `0..15` (and `>=16` as the defined zero/fill behavior). For `simd_srai_si128`, define it as “arithmetic right shift of the 128-bit value by bytes” and fill vacated high bytes with `0x00` or `0xFF` based on the sign bit of the original highest byte.

**Tech Stack:** Free Pascal (FPC) inline assembler, fpcunit, `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh`.

---

### Task 1: Add failing tests for byte shifts

**Files:**
- Modify: `tests/fafafa.core.simd.intrinsics.experimental/fafafa.core.simd.intrinsics.experimental.testcase.pas`

**Step 1: Write the failing tests**

- Add a new test case class compiled only when:
  - `FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS` is defined, and
  - `CPUX86_64` (avoid i386 non-SSE2 hosts).
- Cover these semantics:
  - `simd_slli_si128(a, n)` shifts left by `n` bytes, zero-filling low bytes; `n>=16` yields zero.
  - `simd_srli_si128(a, n)` shifts right by `n` bytes, zero-filling high bytes; `n>=16` yields zero.
  - `simd_srai_si128(a, n)` shifts right by `n` bytes, filling high bytes with `0x00` (if `a[15]` has sign bit 0) or `0xFF` (if sign bit 1); `n>=16` yields all fill bytes.
- Make sure the test includes shift counts that are currently broken (e.g. `3,5,7,9,10,11,13,14,15`).

**Step 2: Run tests to verify RED**

Run:
```bash
FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=1 bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test
```

Expected: FAIL on at least one of the “non power-of-two” shift counts due to the current incomplete branch table; and FAIL for `simd_srai_si128` sign-fill semantics (currently zero-fill).

---

### Task 2: Fix x86 SSE2 implementations (GREEN)

**Files:**
- Modify: `src/fafafa.core.simd.intrinsics.x86.sse2.pas`

**Step 1: Fix `simd_slli_si128` and `simd_srli_si128`**

- Remove the accidental non-comment Chinese text in the Windows branch (it must be a real comment).
- Extend the branch table to handle every shift count `1..15` (plus `0` and `>=16` fast paths).

**Step 2: Implement correct `simd_srai_si128`**

- Implement “byte arithmetic shift right” (sign extend from the original highest byte).
- Keep the same `0` and `>=16` fast paths as in the tests.

**Step 3: Run tests to verify GREEN**

Run:
```bash
FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=1 bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test
```

Expected: PASS.

**Step 4: Optional extra check**

Run:
```bash
FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=1 bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh check
```

Expected: PASS (includes hygiene + backend smoke compiles).

