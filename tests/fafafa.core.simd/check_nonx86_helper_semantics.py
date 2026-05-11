#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
NEON_FILE = ROOT / "src" / "fafafa.core.simd.neon.scalar.wide_memory.inc"
NEON_IMPL_FILE = ROOT / "src" / "fafafa.core.simd.neon.pas"
NEON_SCALAR_FALLBACK_FILE = ROOT / "src" / "fafafa.core.simd.neon.scalar_fallback.inc"
NEON_SCALAR_VECTOR_MATH_FILE = ROOT / "src" / "fafafa.core.simd.neon.scalar.vector_math.inc"
NEON_SCALAR_REDUCTION_FILE = ROOT / "src" / "fafafa.core.simd.neon.scalar.reduction.inc"
NEON_SCALAR_MEMORY_FILE = ROOT / "src" / "fafafa.core.simd.neon.scalar.memory.inc"
NEON_SCALAR_UTILITY_FILE = ROOT / "src" / "fafafa.core.simd.neon.scalar.utility.inc"
NEON_SCALAR_MATH_FILE = ROOT / "src" / "fafafa.core.simd.neon.scalar.math.inc"
NEON_SCALAR_EXT_MATH_FILE = ROOT / "src" / "fafafa.core.simd.neon.scalar.ext_math.inc"
NEON_SCALAR_AUTOWRAP_FILE = ROOT / "src" / "fafafa.core.simd.neon.scalar.autowrap.inc"
RISCVV_FILE = ROOT / "src" / "fafafa.core.simd.riscvv.pas"
RISCVV_FACADE_FILE = ROOT / "src" / "fafafa.core.simd.riscvv.facade.inc"
RISCVV_REGISTER_FILE = ROOT / "src" / "fafafa.core.simd.riscvv.register.inc"
DIRECT_FILE = ROOT / "tests" / "fafafa.core.simd" / "fafafa.core.simd.direct.testcase.pas"
DISPATCHAPI_FILE = ROOT / "tests" / "fafafa.core.simd" / "fafafa.core.simd.dispatchapi.testcase.pas"
DATAPLANE_FILE = ROOT / "tests" / "fafafa.core.simd" / "fafafa.core.simd.dataplane.testcase.pas"
BUILD_OR_TEST_FILE = ROOT / "tests" / "fafafa.core.simd" / "BuildOrTest.sh"
NATIVE_EVIDENCE_FILE = ROOT / "tests" / "fafafa.core.simd" / "collect_nonx86_native_evidence.sh"
NATIVE_EVIDENCE_VERIFY_FILE = ROOT / "tests" / "fafafa.core.simd" / "verify_nonx86_native_evidence.py"
NATIVE_EVIDENCE_IMPORT_FILE = ROOT / "tests" / "fafafa.core.simd" / "import_nonx86_native_evidence_artifacts.sh"
QEMU_RUNNER_FILE = ROOT / "tests" / "fafafa.core.simd" / "docker" / "run_multiarch_qemu.sh"
KEY_SLOT_AUDIT_FILE = ROOT / "tests" / "fafafa.core.simd" / "check_nonx86_key_slot_audit.py"
CHECKLIST_FILE = ROOT / "docs" / "fafafa.core.simd.checklist.md"
CLOSEOUT_FILE = ROOT / "docs" / "fafafa.core.simd.closeout.md"
IMPLEMENTATION_MATRIX_FILE = ROOT / "docs" / "fafafa.core.simd.implementation-matrix.md"


ROUTINE_BLOCK_PATTERN = r"(?ims)^(function|procedure)\s+{name}\b.*?(?=^(function|procedure)\s+[A-Za-z_][A-Za-z0-9_\.]*\b|^initialization\b|\Z)"


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def extract_routine_block(source: str, routine_name: str) -> str:
    block_pattern = re.compile(
        ROUTINE_BLOCK_PATTERN.format(name=re.escape(routine_name)),
    )
    block_match = block_pattern.search(source)
    if not block_match:
        raise AssertionError(f"missing routine: {routine_name}")
    return block_match.group(0)


def normalize(text: str) -> str:
    return re.sub(r"\s+", " ", text.strip())


def require_fragments(body: str, fragments: list[str], routine_name: str) -> None:
    normalized = normalize(body)
    for fragment in fragments:
        normalized_fragment = normalize(fragment)
        if normalized_fragment not in normalized:
            raise AssertionError(
                f"{routine_name} missing fragment: {fragment}"
            )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Check non-x86 helper/native-evidence semantics and source-side parity coverage from source."
    )
    parser.add_argument("--summary-line", action="store_true")
    args = parser.parse_args()

    neon_source = read_text(NEON_FILE)
    neon_impl_source = read_text(NEON_IMPL_FILE)
    neon_scalar_fallback_source = read_text(NEON_SCALAR_FALLBACK_FILE)
    neon_scalar_vector_math_source = read_text(NEON_SCALAR_VECTOR_MATH_FILE)
    neon_scalar_reduction_source = read_text(NEON_SCALAR_REDUCTION_FILE)
    neon_scalar_memory_source = read_text(NEON_SCALAR_MEMORY_FILE)
    neon_scalar_utility_source = read_text(NEON_SCALAR_UTILITY_FILE)
    neon_scalar_math_source = read_text(NEON_SCALAR_MATH_FILE)
    neon_scalar_ext_math_source = read_text(NEON_SCALAR_EXT_MATH_FILE)
    neon_scalar_autowrap_source = read_text(NEON_SCALAR_AUTOWRAP_FILE)
    riscvv_source = read_text(RISCVV_FILE)
    riscvv_facade_source = read_text(RISCVV_FACADE_FILE)
    riscvv_register_source = read_text(RISCVV_REGISTER_FILE)
    direct_source = read_text(DIRECT_FILE)
    dispatchapi_source = read_text(DISPATCHAPI_FILE)
    dataplane_source = read_text(DATAPLANE_FILE)
    build_or_test_source = read_text(BUILD_OR_TEST_FILE)
    native_evidence_source = read_text(NATIVE_EVIDENCE_FILE)
    native_evidence_verify_source = read_text(NATIVE_EVIDENCE_VERIFY_FILE)
    native_evidence_import_source = read_text(NATIVE_EVIDENCE_IMPORT_FILE)
    qemu_runner_source = read_text(QEMU_RUNNER_FILE)
    key_slot_audit_source = read_text(KEY_SLOT_AUDIT_FILE)
    checklist_source = read_text(CHECKLIST_FILE)
    closeout_source = read_text(CLOSEOUT_FILE)
    implementation_matrix_source = read_text(IMPLEMENTATION_MATRIX_FILE)

    checks = 0

    routine_expectations: list[tuple[str, str, list[str]]] = [
        (neon_source, "NEONLoadI64x4_ASM", [
            "ldp   q0, q1, [x0]",
            "umov  x0, v0.d[0]",
            "umov  x1, v0.d[1]",
            "umov  x2, v1.d[0]",
            "umov  x3, v1.d[1]",
        ]),
        (neon_source, "NEONStoreI64x4_ASM", [
            "fmov  d0, x1",
            "fmov  d2, x2",
            "ins   v0.d[1], v2.d[0]",
            "fmov  d1, x3",
            "fmov  d3, x4",
            "ins   v1.d[1], v3.d[0]",
            "stp   q0, q1, [x0]",
        ]),
        (neon_source, "NEONSplatI64x4_ASM", [
            "dup   v0.2d, x0",
            "dup   v1.2d, x0",
            "umov  x0, v0.d[0]",
            "umov  x1, v0.d[1]",
            "umov  x2, v1.d[0]",
            "umov  x3, v1.d[1]",
        ]),
        (neon_source, "NEONZeroI64x4_ASM", [
            "mov   x0, xzr",
            "mov   x1, xzr",
            "mov   x2, xzr",
            "mov   x3, xzr",
        ]),
        (neon_impl_source, "NEONShiftLeftI32x16", [
            "if (count < 0) or (count >= 32) then",
            "Exit(ScalarShiftLeftI32x16(a, count));",
            "Result := NEONShiftLeftI32x16Asm(a, count);",
        ]),
        (neon_impl_source, "NEONShiftRightArithI64x4", [
            "if (count < 0) or (count >= 64) then",
            "Exit(ScalarShiftRightArithI64x4(a, count));",
            "Result := NEONShiftRightArithI64x4Asm(a, count);",
        ]),
        (neon_impl_source, "NEONShiftRightI64x2", [
            "if (count < 0) or (count >= 64) then",
            "Exit(ScalarShiftRightI64x2(a, count));",
            "Result := NEONShiftRightI64x2Asm(a, count);",
        ]),
        (neon_impl_source, "NEONShiftRightArithI64x2", [
            "if (count < 0) or (count >= 64) then",
            "Exit(ScalarShiftRightArithI64x2(a, count));",
            "Result := NEONShiftRightArithI64x2Asm(a, count);",
        ]),
        (neon_impl_source, "NEONShiftLeftI64x4Asm", [
            "ldp   q0, q1, [x0]",
            "uxtw  x1, w1",
            "dup   v2.2d, x1",
            "ushl   v0.2d, v0.2d, v2.2d",
            "ushl   v1.2d, v1.2d, v2.2d",
            "stp   q0, q1, [x8]",
        ]),
        (neon_impl_source, "NEONShiftLeftI64x2", [
            "uxtw  x2, w2",
            "dup   v1.2d, x2",
            "ushl   v0.2d, v0.2d, v1.2d",
        ]),
        (neon_impl_source, "NEONShiftLeftU64x2", [
            "uxtw  x2, w2",
            "dup   v1.2d, x2",
            "ushl   v0.2d, v0.2d, v1.2d",
        ]),
        (neon_impl_source, "NEONShiftLeftU64x4", [
            "ldp   q0, q1, [x0]",
            "uxtw  x1, w1",
            "dup   v2.2d, x1",
            "ushl   v0.2d, v0.2d, v2.2d",
            "ushl   v1.2d, v1.2d, v2.2d",
            "stp   q0, q1, [x8]",
        ]),
        (neon_impl_source, "NEONShiftRightU64x2", [
            "if (count < 0) or (count >= 64) then",
            "Result.u[0] := 0;",
            "Result.u[1] := 0;",
            "Result := NEONShiftRightU64x2Asm(a, count);",
        ]),
        (neon_impl_source, "NEONShiftRightU64x4", [
            "if (count < 0) or (count >= 64) then",
            "Exit(ScalarShiftRightU64x4(a, count));",
            "Result := NEONShiftRightU64x4Asm(a, count);",
        ]),
        (neon_impl_source, "NEONSelectF32x4", [
            "for LIndex := 0 to 3 do",
            "if (mask and (1 shl LIndex)) <> 0 then",
            "Result.f[LIndex] := a.f[LIndex]",
            "else",
            "Result.f[LIndex] := b.f[LIndex];",
        ]),
        (neon_scalar_fallback_source, "NEONAddF32x4", [
            "Result := ScalarAddF32x4(a, b);",
        ]),
        (neon_scalar_fallback_source, "NEONSubF32x4", [
            "Result := ScalarSubF32x4(a, b);",
        ]),
        (neon_scalar_fallback_source, "NEONMulF32x4", [
            "Result := ScalarMulF32x4(a, b);",
        ]),
        (neon_scalar_fallback_source, "NEONDivF32x4", [
            "Result := ScalarDivF32x4(a, b);",
        ]),
        (neon_scalar_fallback_source, "NEONAddF32x8", [
            "Result := ScalarAddF32x8(a, b);",
        ]),
        (neon_scalar_fallback_source, "NEONSubF32x8", [
            "Result := ScalarSubF32x8(a, b);",
        ]),
        (neon_scalar_fallback_source, "NEONMulF32x8", [
            "Result := ScalarMulF32x8(a, b);",
        ]),
        (neon_scalar_fallback_source, "NEONDivF32x8", [
            "Result := ScalarDivF32x8(a, b);",
        ]),
        (neon_scalar_fallback_source, "NEONAddF64x2", [
            "Result := ScalarAddF64x2(a, b);",
        ]),
        (neon_scalar_fallback_source, "NEONSubF64x2", [
            "Result := ScalarSubF64x2(a, b);",
        ]),
        (neon_scalar_fallback_source, "NEONMulF64x2", [
            "Result := ScalarMulF64x2(a, b);",
        ]),
        (neon_scalar_fallback_source, "NEONDivF64x2", [
            "Result := ScalarDivF64x2(a, b);",
        ]),
        (neon_scalar_fallback_source, "NEONAddI32x4", [
            "Result := ScalarAddI32x4(a, b);",
        ]),
        (neon_scalar_fallback_source, "NEONSubI32x4", [
            "Result := ScalarSubI32x4(a, b);",
        ]),
        (neon_scalar_fallback_source, "NEONMulI32x4", [
            "Result := ScalarMulI32x4(a, b);",
        ]),
        (neon_scalar_vector_math_source, "NEONDotF32x4", [
            "Result := ScalarDotF32x4(a, b);",
        ]),
        (neon_scalar_vector_math_source, "NEONDotF32x3", [
            "Result := ScalarDotF32x3(a, b);",
        ]),
        (neon_scalar_vector_math_source, "NEONCrossF32x3", [
            "Result := ScalarCrossF32x3(a, b);",
        ]),
        (neon_scalar_vector_math_source, "NEONLengthF32x4", [
            "Result := ScalarLengthF32x4(a);",
        ]),
        (neon_scalar_vector_math_source, "NEONLengthF32x3", [
            "Result := ScalarLengthF32x3(a);",
        ]),
        (neon_scalar_vector_math_source, "NEONNormalizeF32x4", [
            "Result := ScalarNormalizeF32x4(a);",
        ]),
        (neon_scalar_vector_math_source, "NEONNormalizeF32x3", [
            "Result := ScalarNormalizeF32x3(a);",
        ]),
        (neon_scalar_reduction_source, "NEONReduceAddF32x4", [
            "Result := ScalarReduceAddF32x4(a);",
        ]),
        (neon_scalar_reduction_source, "NEONReduceMulF32x4", [
            "Result := ScalarReduceMulF32x4(a);",
        ]),
        (neon_scalar_memory_source, "NEONLoadF32x4", [
            "Result := ScalarLoadF32x4(p);",
        ]),
        (neon_scalar_memory_source, "NEONLoadF32x4Aligned", [
            "Result := ScalarLoadF32x4Aligned(p);",
        ]),
        (neon_scalar_memory_source, "NEONStoreF32x4", [
            "ScalarStoreF32x4(p, a);",
        ]),
        (neon_scalar_memory_source, "NEONStoreF32x4Aligned", [
            "ScalarStoreF32x4Aligned(p, a);",
        ]),
        (neon_scalar_utility_source, "NEONSplatF32x4", [
            "Result := ScalarSplatF32x4(value);",
        ]),
        (neon_scalar_utility_source, "NEONSelectF32x4", [
            "Result := ScalarSelectF32x4(mask, a, b);",
        ]),
        (neon_scalar_utility_source, "NEONExtractF32x4", [
            "Result := ScalarExtractF32x4(a, index);",
        ]),
        (neon_scalar_utility_source, "NEONInsertF32x4", [
            "Result := ScalarInsertF32x4(a, value, index);",
        ]),
        (neon_scalar_utility_source, "NEONAndNotI64x2", [
            "Result := ScalarAndNotI64x2(a, b);",
        ]),
        (neon_scalar_utility_source, "NEONAddU64x2", [
            "Result := ScalarAddU64x2(a, b);",
        ]),
        (neon_scalar_utility_source, "NEONSubU64x2", [
            "Result := ScalarSubU64x2(a, b);",
        ]),
        (neon_scalar_utility_source, "NEONAndU64x2", [
            "Result := ScalarAndU64x2(a, b);",
        ]),
        (neon_scalar_utility_source, "NEONOrU64x2", [
            "Result := ScalarOrU64x2(a, b);",
        ]),
        (neon_scalar_utility_source, "NEONXorU64x2", [
            "Result := ScalarXorU64x2(a, b);",
        ]),
        (neon_scalar_utility_source, "NEONNotU64x2", [
            "Result := ScalarNotU64x2(a);",
        ]),
        (neon_scalar_utility_source, "NEONAndNotU64x2", [
            "Result := ScalarAndNotU64x2(a, b);",
        ]),
        (neon_scalar_utility_source, "NEONCmpEqU64x2", [
            "Result := ScalarCmpEqU64x2(a, b);",
        ]),
        (neon_scalar_utility_source, "NEONCmpLtU64x2", [
            "Result := ScalarCmpLtU64x2(a, b);",
        ]),
        (neon_scalar_utility_source, "NEONCmpGtU64x2", [
            "Result := ScalarCmpGtU64x2(a, b);",
        ]),
        (neon_scalar_utility_source, "NEONMinU64x2", [
            "Result := ScalarMinU64x2(a, b);",
        ]),
        (neon_scalar_utility_source, "NEONMaxU64x2", [
            "Result := ScalarMaxU64x2(a, b);",
        ]),
        (neon_scalar_utility_source, "NEONSelectF64x2", [
            "Result := ScalarSelectF64x2(mask, a, b);",
        ]),
        (neon_scalar_autowrap_source, "NEONExtractF64x2", [
            "Result := ScalarExtractF64x2(a, index);",
        ]),
        (neon_scalar_autowrap_source, "NEONInsertF64x2", [
            "Result := ScalarInsertF64x2(a, value, index);",
        ]),
        (neon_scalar_math_source, "NEONAbsF32x4", [
            "Result := ScalarAbsF32x4(a);",
        ]),
        (neon_scalar_math_source, "NEONSqrtF32x4", [
            "Result := ScalarSqrtF32x4(a);",
        ]),
        (neon_scalar_ext_math_source, "NEONFmaF32x4", [
            "Result := ScalarFmaF32x4(a, b, c);",
        ]),
        (neon_scalar_ext_math_source, "NEONRcpF32x4", [
            "Result := ScalarRcpF32x4(a);",
        ]),
        (neon_scalar_ext_math_source, "NEONRsqrtF32x4", [
            "Result := ScalarRsqrtF32x4(a);",
        ]),
        (neon_scalar_autowrap_source, "NEONAbsF32x16", [
            "Result := ScalarAbsF32x16(a);",
        ]),
        (neon_scalar_autowrap_source, "NEONAbsF32x8", [
            "Result := ScalarAbsF32x8(a);",
        ]),
        (neon_scalar_autowrap_source, "NEONAbsF64x2", [
            "Result := ScalarAbsF64x2(a);",
        ]),
        (neon_scalar_autowrap_source, "NEONAbsF64x4", [
            "Result := ScalarAbsF64x4(a);",
        ]),
        (neon_scalar_autowrap_source, "NEONAbsF64x8", [
            "Result := ScalarAbsF64x8(a);",
        ]),
        (neon_scalar_autowrap_source, "NEONFmaF32x16", [
            "Result := ScalarFmaF32x16(a, b, c);",
        ]),
        (neon_scalar_autowrap_source, "NEONFmaF32x8", [
            "Result := ScalarFmaF32x8(a, b, c);",
        ]),
        (neon_scalar_autowrap_source, "NEONFmaF64x2", [
            "Result := ScalarFmaF64x2(a, b, c);",
        ]),
        (neon_scalar_autowrap_source, "NEONFmaF64x4", [
            "Result := ScalarFmaF64x4(a, b, c);",
        ]),
        (neon_scalar_autowrap_source, "NEONFmaF64x8", [
            "Result := ScalarFmaF64x8(a, b, c);",
        ]),
        (neon_scalar_autowrap_source, "NEONCeilF32x16", [
            "Result := ScalarCeilF32x16(a);",
        ]),
        (neon_scalar_autowrap_source, "NEONCeilF32x8", [
            "Result := ScalarCeilF32x8(a);",
        ]),
        (neon_scalar_autowrap_source, "NEONCeilF64x4", [
            "Result := ScalarCeilF64x4(a);",
        ]),
        (neon_scalar_autowrap_source, "NEONCeilF64x8", [
            "Result := ScalarCeilF64x8(a);",
        ]),
        (neon_scalar_autowrap_source, "NEONFloorF32x16", [
            "Result := ScalarFloorF32x16(a);",
        ]),
        (neon_scalar_autowrap_source, "NEONFloorF32x8", [
            "Result := ScalarFloorF32x8(a);",
        ]),
        (neon_scalar_autowrap_source, "NEONFloorF64x4", [
            "Result := ScalarFloorF64x4(a);",
        ]),
        (neon_scalar_autowrap_source, "NEONFloorF64x8", [
            "Result := ScalarFloorF64x8(a);",
        ]),
        (riscvv_source, "RISCVVExtractF32x4", [
            "LIndex := index;",
            "if LIndex < 0 then",
            "LIndex := 0",
            "else if LIndex > 3 then",
            "LIndex := 3;",
            "Result := RISCVVExtractF32x4Asm(a, LIndex);",
        ]),
        (riscvv_source, "RISCVVExtractF32x8", [
            "LIndex := index;",
            "if LIndex < 0 then",
            "LIndex := 0",
            "else if LIndex > 7 then",
            "LIndex := 7;",
            "Result := RISCVVExtractF32x8Asm(a, LIndex);",
        ]),
        (riscvv_source, "RISCVVExtractF32x16", [
            "LIndex := index;",
            "if LIndex < 0 then",
            "LIndex := 0",
            "else if LIndex > 15 then",
            "LIndex := 15;",
            "Result := RISCVVExtractF32x16Asm(a, LIndex);",
        ]),
        (riscvv_source, "RISCVVExtractF64x2", [
            "LIndex := index;",
            "if LIndex < 0 then",
            "LIndex := 0",
            "else if LIndex > 1 then",
            "LIndex := 1;",
            "Result := RISCVVExtractF64x2Asm(a, LIndex);",
        ]),
        (riscvv_source, "RISCVVExtractF64x4", [
            "LIndex := index;",
            "if LIndex < 0 then",
            "LIndex := 0",
            "else if LIndex > 3 then",
            "LIndex := 3;",
            "Result := RISCVVExtractF64x4Asm(a, LIndex);",
        ]),
        (riscvv_source, "RISCVVExtractI32x4", [
            "LIndex := index;",
            "if LIndex < 0 then",
            "LIndex := 0",
            "else if LIndex > 3 then",
            "LIndex := 3;",
            "Result := RISCVVExtractI32x4Asm(a, LIndex);",
        ]),
        (riscvv_source, "RISCVVStoreI64x4", [
            "vsetivli zero, 4, 0xD9",
            "vle64.v v0, (a1)",
            "vse64.v v0, (a0)",
        ]),
        (riscvv_source, "RISCVVLoadI64x4Asm", [
            "vsetivli zero, 4, 0xD9",
            "vle64.v v0, (a0)",
            "vse64.v v0, (a1)",
        ]),
        (riscvv_source, "RISCVVSplatI64x4Asm", [
            "vsetivli zero, 4, 0xD9",
            "vmv.v.x v0, a0",
            "vse64.v v0, (a1)",
        ]),
        (riscvv_source, "RISCVVZeroI64x4Asm", [
            "vsetivli zero, 4, 0xD9",
            "vmv.v.i v0, 0",
            "vse64.v v0, (a0)",
        ]),
        (riscvv_source, "RISCVVExtractI32x8Asm", [
            "vsetivli zero, 8, 0xD1",
            "vle32.v v0, (a0)",
            "vslidedown.vx v0, v0, a1",
            "vmv.x.s a0, v0",
        ]),
        (riscvv_source, "RISCVVExtractI32x16Asm", [
            "vsetivli zero, 16, 0xD2",
            "vle32.v v0, (a0)",
            "vslidedown.vx v0, v0, a1",
            "vmv.x.s a0, v0",
        ]),
        (riscvv_source, "RISCVVExtractI64x4Asm", [
            "vsetivli zero, 4, 0xD9",
            "vle64.v v0, (a0)",
            "vslidedown.vx v0, v0, a1",
            "vmv.x.s a0, v0",
        ]),
        (riscvv_source, "RISCVVInsertI32x8", [
            "LIndex := index;",
            "if LIndex < 0 then",
            "LIndex := 0",
            "else if LIndex > 7 then",
            "LIndex := 7;",
            "RISCVVInsertI32x8Asm(a, value, LIndex, Result);",
        ]),
        (riscvv_source, "RISCVVInsertI32x16", [
            "LIndex := index;",
            "if LIndex < 0 then",
            "LIndex := 0",
            "else if LIndex > 15 then",
            "LIndex := 15;",
            "RISCVVInsertI32x16Asm(a, value, LIndex, Result);",
        ]),
        (riscvv_source, "RISCVVInsertI64x4", [
            "LIndex := index;",
            "if LIndex < 0 then",
            "LIndex := 0",
            "else if LIndex > 3 then",
            "LIndex := 3;",
            "RISCVVInsertI64x4Asm(a, value, LIndex, Result);",
        ]),
        (riscvv_source, "RISCVVExtractI32x8", [
            "LIndex := index;",
            "if LIndex < 0 then",
            "LIndex := 0",
            "else if LIndex > 7 then",
            "LIndex := 7;",
            "Result := RISCVVExtractI32x8Asm(a, LIndex);",
        ]),
        (riscvv_source, "RISCVVExtractI32x16", [
            "LIndex := index;",
            "if LIndex < 0 then",
            "LIndex := 0",
            "else if LIndex > 15 then",
            "LIndex := 15;",
            "Result := RISCVVExtractI32x16Asm(a, LIndex);",
        ]),
        (riscvv_source, "RISCVVExtractI64x4", [
            "LIndex := index;",
            "if LIndex < 0 then",
            "LIndex := 0",
            "else if LIndex > 3 then",
            "LIndex := 3;",
            "Result := RISCVVExtractI64x4Asm(a, LIndex);",
        ]),
        (riscvv_source, "RISCVVExtractI64x2", [
            "LIndex := index;",
            "if LIndex < 0 then",
            "LIndex := 0",
            "else if LIndex > 1 then",
            "LIndex := 1;",
            "Result := RISCVVExtractI64x2Asm(a, LIndex);",
        ]),
        (riscvv_facade_source, "RISCVVShiftLeftU32x8", [
            "Result := ScalarShiftLeftU32x8(a, count);",
        ]),
        (riscvv_facade_source, "RISCVVShiftRightU32x8", [
            "Result := ScalarShiftRightU32x8(a, count);",
        ]),
        (riscvv_facade_source, "RISCVVMinU32x8", [
            "Result := ScalarMinU32x8(a, b);",
        ]),
        (riscvv_facade_source, "RISCVVMaxU32x8", [
            "Result := ScalarMaxU32x8(a, b);",
        ]),
        (riscvv_facade_source, "RISCVVMinI16x8", [
            "Result := ScalarMinI16x8(a, b);",
        ]),
        (riscvv_facade_source, "RISCVVMaxI16x8", [
            "Result := ScalarMaxI16x8(a, b);",
        ]),
        (riscvv_facade_source, "RISCVVMinI8x16", [
            "Result := ScalarMinI8x16(a, b);",
        ]),
        (riscvv_facade_source, "RISCVVMaxI8x16", [
            "Result := ScalarMaxI8x16(a, b);",
        ]),
        (riscvv_facade_source, "RISCVVMinU16x8", [
            "Result := ScalarMinU16x8(a, b);",
        ]),
        (riscvv_facade_source, "RISCVVMaxU16x8", [
            "Result := ScalarMaxU16x8(a, b);",
        ]),
        (riscvv_facade_source, "RISCVVMinU32x4", [
            "Result := ScalarMinU32x4(a, b);",
        ]),
        (riscvv_facade_source, "RISCVVMaxU32x4", [
            "Result := ScalarMaxU32x4(a, b);",
        ]),
        (riscvv_facade_source, "RISCVVMinU8x16", [
            "Result := ScalarMinU8x16(a, b);",
        ]),
        (riscvv_facade_source, "RISCVVMaxU8x16", [
            "Result := ScalarMaxU8x16(a, b);",
        ]),
        (direct_source, "TTestCase_DirectDispatch.Test_DirectDispatchTable_MultiBackend_SignedWideCompareMaskMatrix_Parity", [
            "ScalarCmpEqI32x8",
            "ScalarCmpLtI64x4",
            "ScalarCmpEqI32x16",
            "ScalarCmpNeI64x8",
            "AssertMask4HelperParity",
            "AssertMask8HelperParity",
            "AssertMask16HelperParity",
        ]),
        (direct_source, "TTestCase_DirectDispatch.Test_DirectDispatchTable_MultiBackend_WideBitwiseShiftMatrix_Parity", [
            "C_SHIFT32: array[0..8] of Integer = (-1, 0, 1, 7, 31, 32, 63, 64, 95)",
            "C_SHIFT64: array[0..7] of Integer = (-1, 0, 1, 7, 31, 63, 64, 95)",
            "LDirectDispatch^.AndNotI32x8",
            "VecI32x8AndNot",
            "LDirectDispatch^.ShiftLeftI32x16",
            "VecI32x16ShiftRightArith",
            "VecI64x4ShiftRightArith",
            "LScalarTable.ShiftRightArithI64x4",
        ]),
        (direct_source, "TTestCase_DirectDispatch.Test_DirectDispatchTable_MultiBackend_WideArithmeticMinMaxMatrix_Parity", [
            "LDirectDispatch^.AddI32x8",
            "VecI32x8Mul",
            "LDirectDispatch^.MaxU32x8",
            "LDirectDispatch^.SubI64x4",
            "VecI32x16Mul",
            "LDirectDispatch^.MinI32x16",
            "VecI64x8Add",
            "VecU64x8Add",
            "LDirectDispatch^.SubU64x8",
        ]),
        (dispatchapi_source, "TTestCase_NonX86BackendParity.Test_WideSignedBitwiseShiftParity_IfAvailable", [
            "C_SHIFT32: array[0..8] of Integer = (-1, 0, 1, 7, 31, 32, 63, 64, 95)",
            "C_SHIFT64: array[0..7] of Integer = (-1, 0, 1, 7, 31, 63, 64, 95)",
            "Assigned(LBackendTable.AndI32x8)",
            "Assigned(LBackendTable.ShiftLeftI32x16)",
            "Assigned(LBackendTable.ShiftRightArithI64x4)",
            "Assigned(LBackendTable.AndI64x8)",
            "Assigned(LBackendTable.NotI64x8)",
            "AssertVecI32x8Equal('AndI32x8 parity",
            "LoadI32x8FromArray(C_I32X8_SHIFT_PROBE",
            "ShiftRightArithI32x8 exact c=-1",
            "ShiftRightArithI32x16 exact c=64",
            "ShiftRightArithI64x4 exact c=64",
            "ShiftRightArithI64x4 exact c=95",
            "AssertVecI64x4Equal('ShiftRightArithI64x4 parity",
            "AssertVecI64x8Equal('AndI64x8 parity",
            "VecI64x8Not",
        ]),
        (dispatchapi_source, "TTestCase_NonX86BackendParity.Test_WideCompareMaskParity_IfAvailable", [
            "Assigned(LBackendTable.CmpEqI32x8)",
            "Assigned(LBackendTable.CmpEqU32x8)",
            "Assigned(LBackendTable.CmpEqI64x4)",
            "Assigned(LBackendTable.CmpEqU64x4)",
            "Assigned(LBackendTable.CmpEqI32x16)",
            "Assigned(LBackendTable.CmpEqI64x8)",
            "AssertMask4HelperParity",
            "AssertMask8HelperParity",
            "AssertMask16HelperParity",
            "LoadI32x8OneHotProbe",
            "LoadI64x4OneHotProbe",
            "LoadI32x16OneHotProbe",
            "LoadI64x8OneHotProbe",
            "LoadU32x8OneHotProbe",
            "LoadU64x4OneHotProbe",
            "CmpLtI32x8 onehot-lt lane=",
            "CmpLtI64x4 onehot-lt lane=",
            "CmpLtI32x16 onehot-lt lane=",
            "CmpLtI64x8 onehot-lt lane=",
            "CmpLtU32x8 onehot-lt lane=",
            "CmpLtU64x4 onehot-lt lane=",
            "VecI32x16CmpEq",
            "VecU64x4CmpGe",
            "VecI64x8CmpLt",
        ]),
        (dispatchapi_source, "TTestCase_NonX86BackendParity.Test_WideIntegerArithmeticMinMaxParity_IfAvailable", [
            "Assigned(LBackendTable.AddI32x8)",
            "Assigned(LBackendTable.SubI32x8)",
            "Assigned(LBackendTable.MulI32x8)",
            "Assigned(LBackendTable.MinU32x8)",
            "Assigned(LBackendTable.MaxU32x8)",
            "Assigned(LBackendTable.AddI64x4)",
            "Assigned(LBackendTable.SubI64x4)",
            "Assigned(LBackendTable.MinI32x16)",
            "Assigned(LBackendTable.MulI32x16)",
            "Assigned(LBackendTable.MaxI32x16)",
            "Assigned(LBackendTable.AddU32x16)",
            "Assigned(LBackendTable.MulU32x16)",
            "Assigned(LBackendTable.MaxU32x16)",
            "Assigned(LBackendTable.AddI64x8)",
            "Assigned(LBackendTable.SubI64x8)",
            "Assigned(LBackendTable.SubU64x8)",
            "VecU32x8Min",
            "VecI32x16Mul",
            "VecI64x8Add",
            "VecI64x8Sub",
            "VecU32x16Max",
            "VecU64x8Add",
            "MulI32x8 truncation backend contract",
            "MulU32x8 truncation backend contract",
            "AddU32x8 lane-tag backend contract",
            "AddU64x4 lane-tag backend contract",
            "SubU64x4 lane-tag backend contract",
        ]),
        (dataplane_source, "TTestCase_DataPlane.Test_DataPlane_CompareMaskSnapshot_Follows_CurrentDispatchSemantics", [
            "Assigned(LDataPlane^.Dispatch^.CmpLtI64x4)",
            "for LCaseIdx := 0 to 3 do",
            "data-plane dispatch Mask4All should match scalar helper",
            "data-plane dispatch Mask8Any should match scalar helper",
            "Assigned(LDataPlane^.Dispatch^.Mask8PopCount)",
            "data-plane dispatch Mask16PopCount should match scalar helper",
            "ScalarCmpLtI64x8",
            "ScalarMask16FirstSet",
            "LDirectDispatch^.CmpLtI32x16",
        ]),
        (dataplane_source, "TTestCase_DataPlane.Test_DataPlane_WideBitwiseShiftSnapshot_Follows_CurrentDispatchSemantics", [
            "C_SHIFT32: array[0..7] of Integer = (-1, 0, 1, 7, 31, 32, 63, 64)",
            "C_SHIFT64: array[0..7] of Integer = (-1, 0, 1, 7, 31, 63, 64, 95)",
            "for LCaseIdx := 0 to 2 do",
            "for LShiftIndex := 0 to High(C_SHIFT32) do",
            "Assigned(LDataPlane^.Dispatch^.AndNotI32x16)",
            "Assigned(LDataPlane^.Dispatch^.ShiftLeftI32x16)",
            "Assigned(LDataPlane^.Dispatch^.AndI64x8)",
            "Assigned(LDataPlane^.Dispatch^.OrI64x8)",
            "Assigned(LDataPlane^.Dispatch^.XorI64x8)",
            "Assigned(LDataPlane^.Dispatch^.NotI64x8)",
            "Assigned(LDataPlane^.Dispatch^.ShiftRightI64x4)",
            "ScalarShiftLeftI32x16",
            "ScalarAndI64x8",
            "ScalarOrI64x8",
            "ScalarXorI64x8",
            "ScalarNotI64x8",
            "ScalarAndNotI64x4",
            "ScalarShiftRightArithI64x4",
            "LDirectDispatch^.AndI64x8",
            "LDirectDispatch^.OrI64x8",
            "LDirectDispatch^.XorI64x8",
            "LDirectDispatch^.NotI64x8",
            "LDirectDispatch^.ShiftRightI64x4",
        ]),
        (dataplane_source, "TTestCase_DataPlane.Test_DataPlane_WideArithmeticMinMaxSnapshot_Follows_CurrentDispatchSemantics", [
            "for LCaseIdx := 0 to 2 do",
            "Assigned(LDataPlane^.Dispatch^.AddI32x8)",
            "Assigned(LDataPlane^.Dispatch^.MulI32x8)",
            "Assigned(LDataPlane^.Dispatch^.SubI32x8)",
            "Assigned(LDataPlane^.Dispatch^.AddU32x8)",
            "Assigned(LDataPlane^.Dispatch^.SubU32x8)",
            "Assigned(LDataPlane^.Dispatch^.MulU32x8)",
            "Assigned(LDataPlane^.Dispatch^.MinU32x8)",
            "Assigned(LDataPlane^.Dispatch^.MaxU32x8)",
            "Assigned(LDataPlane^.Dispatch^.AddI64x4)",
            "Assigned(LDataPlane^.Dispatch^.SubI64x4)",
            "Assigned(LDataPlane^.Dispatch^.AddU64x4)",
            "Assigned(LDataPlane^.Dispatch^.SubU64x4)",
            "Assigned(LDataPlane^.Dispatch^.AddI32x16)",
            "Assigned(LDataPlane^.Dispatch^.MinI32x16)",
            "Assigned(LDataPlane^.Dispatch^.MulI32x16)",
            "Assigned(LDataPlane^.Dispatch^.MinU32x16)",
            "Assigned(LDataPlane^.Dispatch^.AddI64x8)",
            "Assigned(LDataPlane^.Dispatch^.SubI64x8)",
            "Assigned(LDataPlane^.Dispatch^.MaxU32x16)",
            "Assigned(LDataPlane^.Dispatch^.SubU64x8)",
            "ScalarAddI32x8",
            "ScalarAddU32x8",
            "ScalarSubU32x8",
            "ScalarMulU32x8",
            "ScalarMinU32x8",
            "ScalarAddI64x4",
            "ScalarSubI64x4",
            "ScalarAddU64x4",
            "ScalarSubU64x4",
            "ScalarAddI32x16",
            "ScalarMulI32x16",
            "ScalarMinU32x16",
            "ScalarMulU32x16",
            "ScalarSubI64x8",
            "ScalarMaxU32x16",
            "LDirectDispatch^.AddU32x8",
            "LDirectDispatch^.MulU32x8",
            "LDirectDispatch^.MinU32x8",
            "LDirectDispatch^.AddI64x4",
            "LDirectDispatch^.SubI64x4",
            "LDirectDispatch^.AddU64x4",
            "LDirectDispatch^.SubU64x4",
            "LDirectDispatch^.AddI32x16",
            "LDirectDispatch^.MulI32x16",
            "LDirectDispatch^.MinU32x16",
            "LDirectDispatch^.SubI64x8",
            "LDirectDispatch^.AddU64x8",
            "data-plane dispatch MaxU32x16 should match direct dispatch case=",
            "data-plane dispatch SubU64x8 should match direct dispatch case=",
        ]),
    ]

    riscvv_scalar_forwarder_expectations: list[tuple[str, str]] = []
    for suffix in ("I32x4", "I32x8", "U32x8"):
        for op in ("Add", "Sub", "Mul", "And", "Or", "Xor"):
            riscvv_scalar_forwarder_expectations.append(
                (f"RISCVV{op}{suffix}", f"Scalar{op}{suffix}(a, b)")
            )
        for op in ("Eq", "Lt", "Gt", "Le", "Ge", "Ne"):
            riscvv_scalar_forwarder_expectations.append(
                (f"RISCVVCmp{op}{suffix}", f"ScalarCmp{op}{suffix}(a, b)")
            )

    for suffix in ("I64x2",):
        for op in ("Add", "Sub", "And", "Or", "Xor"):
            riscvv_scalar_forwarder_expectations.append(
                (f"RISCVV{op}{suffix}", f"Scalar{op}{suffix}(a, b)")
            )
        for op in ("Eq", "Lt", "Gt", "Le", "Ge", "Ne"):
            riscvv_scalar_forwarder_expectations.append(
                (f"RISCVVCmp{op}{suffix}", f"ScalarCmp{op}{suffix}(a, b)")
            )
        riscvv_scalar_forwarder_expectations.append(("RISCVVNotI64x2", "ScalarNotI64x2(a)"))

    for suffix in ("I32x4", "I32x8", "U32x8"):
        riscvv_scalar_forwarder_expectations.extend(
            [
                (f"RISCVVAndNot{suffix}", f"ScalarAndNot{suffix}(a, b)"),
                (f"RISCVVNot{suffix}", f"ScalarNot{suffix}(a)"),
            ]
        )

    for suffix in ("I16x8", "I64x4", "I64x8", "I8x16", "U16x8", "U32x4", "U64x4", "U8x16"):
        for op in ("Add", "Sub", "And", "Or", "Xor"):
            riscvv_scalar_forwarder_expectations.append(
                (f"RISCVV{op}{suffix}", f"Scalar{op}{suffix}(a, b)")
            )
        riscvv_scalar_forwarder_expectations.append((f"RISCVVNot{suffix}", f"ScalarNot{suffix}(a)"))

    for suffix in ("I16x8", "I32x16", "I64x4", "I64x8", "I8x16", "U16x8", "U64x4", "U8x16"):
        for op in ("Eq", "Lt", "Gt", "Le", "Ge", "Ne"):
            riscvv_scalar_forwarder_expectations.append(
                (f"RISCVVCmp{op}{suffix}", f"ScalarCmp{op}{suffix}(a, b)")
            )

    for suffix in ("U32x4",):
        for op in ("Eq", "Lt", "Gt", "Le", "Ge"):
            riscvv_scalar_forwarder_expectations.append(
                (f"RISCVVCmp{op}{suffix}", f"ScalarCmp{op}{suffix}(a, b)")
            )

    for suffix in ("I16x8", "U16x8", "U32x4"):
        riscvv_scalar_forwarder_expectations.append(
            (f"RISCVVMul{suffix}", f"ScalarMul{suffix}(a, b)")
        )

    for suffix in ("I16x8", "I64x4", "U32x4"):
        riscvv_scalar_forwarder_expectations.append(
            (f"RISCVVAndNot{suffix}", f"ScalarAndNot{suffix}(a, b)")
        )

    for suffix in ("I32x4", "I32x8", "I32x16"):
        riscvv_scalar_forwarder_expectations.extend(
            [
                (f"RISCVVMin{suffix}", f"ScalarMin{suffix}(a, b)"),
                (f"RISCVVMax{suffix}", f"ScalarMax{suffix}(a, b)"),
            ]
        )

    routine_expectations.extend(
        (riscvv_facade_source, routine_name, [f"Result := {scalar_call};"])
        for routine_name, scalar_call in riscvv_scalar_forwarder_expectations
    )

    for source, routine_name, fragments in routine_expectations:
        require_fragments(extract_routine_block(source, routine_name), fragments, routine_name)
        checks += 1

    document_expectations = [
        (
            key_slot_audit_source,
            "check_nonx86_key_slot_audit.py",
            [
                "DISPATCHAPI_FILE =",
                "EXPECTATION_PROCEDURES =",
                "ASSERT_MODE_TO_EXPECTATION =",
                "collect_expected_slot_modes_from_dispatchapi",
                "extract_procedure_block",
                "AssertRegisterKeepsBaseScalar",
                "AssertRegisterHasAsmOwnedSlot",
                "AssertRegisterOwnsBackendSlot",
            ],
        ),
        (
            native_evidence_source,
            "collect_nonx86_native_evidence.sh",
            [
                "run_step runtime_parity",
                "run_step impl_audit_nonx86",
                "bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_NonX86BackendParity,TTestCase_DataPlane",
                "bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86",
                "bash tests/fafafa.core.simd/docker/run_fpc_tests.sh --vector-asm --suite=TTestCase_NonX86BackendParity,TTestCase_DataPlane",
                "## Runtime Parity (TTestCase_NonX86BackendParity,TTestCase_DataPlane)",
                "## Implementation Audit",
            ],
        ),
        (
            build_or_test_source,
            "BuildOrTest.sh",
            [
                "non-x86 native evidence helper missing runtime parity pattern",
                "run_nonx86_impl_smoke() {",
                "NONX86_IMPL_SMOKE_SUMMARY",
                "impl-smoke-nonx86)",
                "bash \"${ROOT}/BuildOrTest.sh\" test --suite=TTestCase_NonX86BackendParity",
                "bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_NonX86BackendParity,TTestCase_DataPlane",
                "bash tests/fafafa.core.simd/docker/run_fpc_tests.sh --vector-asm --suite=TTestCase_NonX86BackendParity,TTestCase_DataPlane",
                "## Runtime Parity (TTestCase_NonX86BackendParity,TTestCase_DataPlane)",
            ],
        ),
        (
            native_evidence_verify_source,
            "verify_nonx86_native_evidence.py",
            [
                "## Runtime Parity (TTestCase_NonX86BackendParity,TTestCase_DataPlane)",
                "--suite=TTestCase_NonX86BackendParity,TTestCase_DataPlane",
                "def failed_result(",
                'HEADER_PATTERN = re.compile(r"^# SIMD Non-X86 Native Evidence \\((\\d{8}-\\d{6})\\)$", re.MULTILINE)',
                'SYNTHETIC_OUTPUT_ROOT_MARKER = "/tmp/simd-import-smoke"',
                "def require_summary_stamp_matches(",
                "summary stamp mismatch: header=",
                "synthetic import-smoke marker detected:",
                "backend={backend} directory={evidence_dir} summary={summary_path} environment={env_path}",
                "if runner_kind == 'canonical':",
                "## Implementation Audit",
                "NONX86_IMPL_AUDIT_SUMMARY",
                "else:",
                "## Build Smoke",
            ],
        ),
        (
            native_evidence_import_source,
            "import_nonx86_native_evidence_artifacts.sh",
            [
                "Usage: import_nonx86_native_evidence_artifacts.sh [--backend neon|riscvv|all] <source-dir> [source-dir...]",
                'DEST_ROOT="${SIMD_NONX86_NATIVE_EVIDENCE_IMPORT_DEST:-${ROOT}/fixtures/native-evidence}"',
                'SYNTHETIC_OUTPUT_ROOT_MARKER="/tmp/simd-import-smoke"',
                'paths_equal() {',
                'verify_source_dir_integrity() {',
                'summary stamp ${LStamp} does not match directory stamp ${LDirStamp}',
                'Synthetic import-smoke evidence is not allowed',
                'resolve_latest_backend_dir() {',
                "native-evidence-neon-*",
                "native-evidence-riscvv-*",
                'already lives under ${DEST_ROOT}',
                'python3 "${VERIFY_SCRIPT}" --root "${DEST_ROOT}" --backend "${REQUESTED_BACKEND}" --summary-line',
            ],
        ),
        (
            qemu_runner_source,
            "docker/run_multiarch_qemu.sh",
            [
                "build_nonx86_evidence_cmd() {",
                'LDirectParityLog="\\${SIMD_OUTPUT_ROOT}/logs/direct_nonx86_runtime_parity.txt";',
                '--suite=TTestCase_NonX86BackendParity,TTestCase_DataPlane',
                "bash tests/fafafa.core.simd/run_backend_benchmarks.sh",
            ],
        ),
        (
            checklist_source,
            "docs/fafafa.core.simd.checklist.md",
            [
                "x86_64 主机只能跑 source checker",
                "bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86",
                "bash tests/fafafa.core.simd/BuildOrTest.sh closeout-host-local",
                "bash tests/fafafa.core.simd/BuildOrTest.sh import-nonx86-native-evidence",
                "bash tests/fafafa.core.simd/BuildOrTest.sh closeout-host-local-from-import",
                "qemu-nonx86-evidence",
                "SIMD_GATE_QEMU_NONX86_EVIDENCE=1",
                "SIMD_GATE_REQUIRE_NONX86_NATIVE_EVIDENCE=0",
                "python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line",
                "python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --summary-line",
                "docs/fafafa.core.simd.implementation-matrix.md",
                "没有硬件时，不再把 native host 当成 blocker",
                "compare/mask / shift/bitwise / arithmetic/minmax 的 source-side 语义矩阵",
                "backend_owned",
                "reuse_base_scalar",
                "Test_DirectDispatchTable_MultiBackend_SignedWideCompareMaskMatrix_Parity",
                "Test_WideCompareMaskParity_IfAvailable",
                "Test_WideSignedBitwiseShiftParity_IfAvailable",
                "Test_WideIntegerArithmeticMinMaxParity_IfAvailable",
                "Test_DataPlane_WideBitwiseShiftSnapshot_Follows_CurrentDispatchSemantics",
                "Test_DataPlane_WideArithmeticMinMaxSnapshot_Follows_CurrentDispatchSemantics",
            ],
        ),
        (
            closeout_source,
            "docs/fafafa.core.simd.closeout.md",
            [
                "2026-04-11 implementation audit snapshot",
                "NONX86_IMPL_AUDIT_SUMMARY",
                "NONX86_HELPER_SEMANTICS_SUMMARY",
                "NONX86_KEY_SLOT_AUDIT_SUMMARY",
                "impl-smoke-nonx86",
                "WIRING_SYNC_SUMMARY",
                "closeout-host-local",
                "import-nonx86-native-evidence",
                "closeout-host-local-from-import",
                "docs/fafafa.core.simd.implementation-matrix.md",
                "TTestCase_NonX86BackendParity,TTestCase_DataPlane",
                "TTestCase_NonX86BackendParity,TTestCase_DirectDispatch,TTestCase_DataPlane",
                "DataPlane wide snapshot",
                "QEMU non-x86 runtime evidence",
                "当前 arm64 / riscv64 closeout 的充分证明",
            ],
        ),
        (
            implementation_matrix_source,
            "docs/fafafa.core.simd.implementation-matrix.md",
            [
                "# SIMD Implementation Matrix",
                "## Current Focus",
                "## Non-X86 Ownership Matrix",
                "backend | slot | expected contract | source truth | runtime evidence | current status | next action",
                "impl-smoke-nonx86",
                "NEON | AndI64x8 | reuse_base_scalar",
                "RISCVV | MaxU32x16 | reuse_base_scalar",
                "DispatchAPI source truth",
                "BuildOrTest.sh impl-audit-nonx86",
            ],
        ),
        (
            riscvv_register_source,
            "src/fafafa.core.simd.riscvv.register.inc",
            [
                "table.ShiftLeftU32x8 := @RISCVVShiftLeftU32x8;",
                "table.ShiftRightU32x8 := @RISCVVShiftRightU32x8;",
                "asm-enabled builds resolve these symbols to native RVV implementations",
                "no-asm builds resolve the same symbols to explicit scalar-passthrough",
                "second register-only branch",
                "Neighboring U32x16/U64x8 families intentionally fall through to",
                "FillBaseDispatchTable instead.",
            ],
        ),
    ]

    for body, label, fragments in document_expectations:
        require_fragments(body, fragments, label)
        checks += 1

    if args.summary_line:
        print(f"NONX86_HELPER_SEMANTICS_SUMMARY checks={checks} status=ok")
    else:
        print(f"checked {checks} helper/native-evidence semantics from source")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"NONX86_HELPER_SEMANTICS_ERROR {exc}", file=sys.stderr)
        raise SystemExit(1)
