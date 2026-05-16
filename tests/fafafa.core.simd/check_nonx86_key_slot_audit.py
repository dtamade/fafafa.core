#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from types import SimpleNamespace


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import check_nonx86_register_truthfulness as register_truthfulness


KEY_SLOTS_BY_BACKEND: dict[str, tuple[str, ...]] = {
    "neon": (
        "AndI64x8",
        "NotI64x8",
        "ShiftLeftI32x16",
        "ShiftRightArithI64x4",
        "SubI32x8",
        "MinU32x8",
        "AddI64x4",
        "MulI32x16",
        "MaxU32x16",
        "SubI64x8",
    ),
    "riscvv": (
        "AndI64x8",
        "NotI64x8",
        "ShiftLeftI32x16",
        "ShiftRightArithI64x4",
        "SubI32x8",
        "MinU32x8",
        "AddI64x4",
        "MulI32x16",
        "MaxU32x16",
        "SubI64x8",
        "SelectF32x8",
        "SelectF64x4",
        "SelectI32x4",
        "ExtractF32x8",
        "ExtractF32x16",
        "ExtractF64x2",
        "ExtractF64x4",
        "ExtractI32x4",
        "ExtractI32x8",
        "ExtractI32x16",
        "ExtractI64x2",
        "ExtractI64x4",
        "AndNotI64x2",
        "MinI64x2",
        "MaxI64x2",
        "AndNotU64x2",
        "CmpEqU64x2",
        "CmpLtU64x2",
        "CmpGtU64x2",
        "MinU64x2",
        "MaxU64x2",
        "AndNotI8x16",
        "AndNotU16x8",
        "AndNotU8x16",
    ),
}

DISPATCHAPI_FILE = SCRIPT_DIR / "fafafa.core.simd.dispatchapi.testcase.pas"
ROUTINE_BLOCK_PATTERN = (
    r"(?ims)^procedure\s+{name}\b.*?"
    r"(?=^procedure\s+TTestCase_|^function\s+TTestCase_|^initialization\b|\Z)"
)
ASSERT_CALL_RE = re.compile(
    r"(?m)^\s*"
    r"(AssertRegisterKeepsBaseScalar|AssertRegisterHasAsmOwnedSlot|AssertRegisterOwnsBackendSlot|AssertHelperOwnedExactScalarSlot|AssertExtractCompanionSlot)"
    r"\(\s*'([^']+)'\s*,"
)
EXPECTATION_PROCEDURES = {
    "neon": (
        "TTestCase_DispatchAPI.Test_NEON_WideFallbackOnlySlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders",
        "TTestCase_DispatchAPI.Test_NEON_NoAsmIntegerFallbackSlots_Reuse_BaseScalar_When_Wrappers_Are_Not_BackendOwned",
    ),
    "riscvv": (
        "TTestCase_DispatchAPI.Test_RISCVV_FacadeSlots_Reuse_BaseScalar_When_Wrappers_Are_ScalarPassThrough",
        "TTestCase_DispatchAPI.Test_RISCVV_WideFallbackOnlySlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders",
        "TTestCase_DispatchAPI.Test_RISCVV_ExtractSlots_Keep_NoAsmCompanionWrappers_And_RuntimeOwnership",
        "TTestCase_DispatchAPI.Test_RISCVV_HelperOwnedExactScalarSlots_Stay_BackendOwned",
        "TTestCase_DispatchAPI.Test_RISCVV_KeyOwnedWideSlots_Stay_BackendOwned",
    ),
}
ASSERT_MODE_TO_EXPECTATION = {
    "AssertRegisterKeepsBaseScalar": "reuse_base_scalar",
    "AssertRegisterHasAsmOwnedSlot": "backend_owned",
    "AssertRegisterOwnsBackendSlot": "backend_owned",
    "AssertHelperOwnedExactScalarSlot": "backend_owned",
    "AssertExtractCompanionSlot": "backend_owned",
}
DEFAULT_UNASSERTED_KEY_SLOT_MODE = "backend_owned"
REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS: dict[str, set[str]] = {
    "riscvv": {
        "AndI64x8",
        "NotI64x8",
        "ShiftLeftI32x16",
        "ShiftRightArithI64x4",
        "SubI32x8",
        "MinU32x8",
        "AddI64x4",
        "MulI32x16",
        "SubI64x8",
        "SelectF32x8",
        "SelectF64x4",
        "SelectI32x4",
        "ExtractF32x8",
        "ExtractF32x16",
        "ExtractF64x2",
        "ExtractF64x4",
        "ExtractI32x4",
        "ExtractI32x8",
        "ExtractI32x16",
        "ExtractI64x2",
        "ExtractI64x4",
        "AndNotI64x2",
        "MinI64x2",
        "MaxI64x2",
        "AndNotU64x2",
        "CmpEqU64x2",
        "CmpLtU64x2",
        "CmpGtU64x2",
        "MinU64x2",
        "MaxU64x2",
        "AndNotI8x16",
        "AndNotU16x8",
        "AndNotU8x16",
    },
}

ALLOWED_BACKEND_OWNED_NO_ASM_SCALAR_WRAPPER_SLOTS_BY_BACKEND: dict[str, set[str]] = {
    "riscvv": {
        "ExtractF32x8",
        "ExtractF32x16",
        "ExtractF64x2",
        "ExtractF64x4",
        "ExtractI32x4",
        "ExtractI32x8",
        "ExtractI32x16",
        "ExtractI64x2",
        "ExtractI64x4",
    },
}


@dataclass(frozen=True)
class SlotExpectation:
    mode: str
    truth_source: str
    explicit_assert_present: bool


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Audit non-x86 key wide slots for truthful implementation ownership."
    )
    parser.add_argument(
        "--backend",
        choices=("neon", "riscvv", "all"),
        default="all",
        help="Backend to inspect (default: all).",
    )
    parser.add_argument("--json", action="store_true", help="Print machine-readable JSON.")
    parser.add_argument(
        "--summary-line",
        action="store_true",
        help="Print one-line summary for log scraping.",
    )
    return parser.parse_args()


def dedupe_reasons(reasons: list[str]) -> list[str]:
    seen: set[str] = set()
    result: list[str] = []
    for item in reasons:
        if item in seen:
            continue
        seen.add(item)
        result.append(item)
    return result


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def extract_procedure_block(source: str, procedure_name: str) -> str:
    pattern = re.compile(
        ROUTINE_BLOCK_PATTERN.format(name=re.escape(procedure_name)),
    )
    match = pattern.search(source)
    if match is None:
        raise RuntimeError(f"missing dispatchapi truth-source procedure: {procedure_name}")
    return match.group(0)


def collect_expected_slot_modes_from_dispatchapi() -> dict[str, dict[str, SlotExpectation]]:
    dispatchapi_source = read_text(DISPATCHAPI_FILE)
    expectations: dict[str, dict[str, SlotExpectation]] = {}

    for backend, procedures in EXPECTATION_PROCEDURES.items():
        expected_slots = set(KEY_SLOTS_BY_BACKEND[backend])
        backend_expectations: dict[str, SlotExpectation] = {}
        for procedure_name in procedures:
            block = extract_procedure_block(dispatchapi_source, procedure_name)
            for assert_name, slot in ASSERT_CALL_RE.findall(block):
                if slot not in expected_slots:
                    continue
                mode = ASSERT_MODE_TO_EXPECTATION[assert_name]
                truth_source = f"{procedure_name}::{assert_name}"
                existing = backend_expectations.get(slot)
                if existing is not None and existing.mode != mode:
                    raise RuntimeError(
                        f"conflicting truth-source expectations for {backend}.{slot}: "
                        f"{existing.mode} vs {mode}"
                    )
                backend_expectations[slot] = SlotExpectation(
                    mode=mode,
                    truth_source=truth_source,
                    explicit_assert_present=True,
                )

        explicit_required_slots = REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS.get(backend, set())
        for slot in expected_slots:
            backend_expectations.setdefault(
                slot,
                SlotExpectation(
                    mode=DEFAULT_UNASSERTED_KEY_SLOT_MODE,
                    truth_source=(
                        "DispatchAPI source truth missing dedicated explicit assert"
                        if slot in explicit_required_slots
                        else "DispatchAPI exception model: no AssertRegisterKeepsBaseScalar "
                        "for this key slot"
                    ),
                    explicit_assert_present=slot not in explicit_required_slots,
                ),
            )
        expectations[backend] = backend_expectations

    validate_expected_slot_modes(expectations)
    return expectations


def validate_expected_slot_modes(
    expectations: dict[str, dict[str, SlotExpectation]]
) -> None:
    expected_backends = set(EXPECTATION_PROCEDURES)
    actual_backends = set(expectations)
    if actual_backends != expected_backends:
        raise RuntimeError(
            f"truth-source backend mismatch: missing={sorted(expected_backends - actual_backends)} "
            f"extra={sorted(actual_backends - expected_backends)}"
        )

    for backend, slot_modes in expectations.items():
        expected_slots = set(KEY_SLOTS_BY_BACKEND[backend])
        backend_slots = set(slot_modes)
        if backend_slots != expected_slots:
            missing = sorted(expected_slots - backend_slots)
            extra = sorted(backend_slots - expected_slots)
            raise RuntimeError(
                f"expected slot-mode mismatch for {backend}: missing={missing} extra={extra}"
            )


def make_reason_list(
    backend: str,
    assignment: register_truthfulness.Assignment,
    classification: str,
    wrapper_kind: str | None,
) -> list[str]:
    reasons = list(
        register_truthfulness.build_reason_list(
            backend, assignment, classification, wrapper_kind, True
        )
    )
    if classification in {"scalar_passthrough", "no_def"} and classification not in reasons:
        reasons.append(classification)
    if wrapper_kind == "scalar_forwarder" and "scalar-forwarder" not in reasons:
        reasons.append("scalar-forwarder")
    return reasons


def filter_allowed_backend_owned_reasons(
    backend: str,
    slot: str,
    assignment: register_truthfulness.Assignment,
    classification: str,
    wrapper_kind: str | None,
    reasons: list[str],
) -> list[str]:
    if (
        assignment.context == "no-asm"
        and classification == "wrapper_only"
        and wrapper_kind == "scalar_forwarder"
        and slot in ALLOWED_BACKEND_OWNED_NO_ASM_SCALAR_WRAPPER_SLOTS_BY_BACKEND.get(backend, set())
    ):
        return [reason for reason in reasons if reason not in {"wrapper_only", "scalar-forwarder"}]
    return reasons


def make_missing_record(slot: str, expected_mode: str) -> dict[str, object]:
    return {
        "slot": slot,
        "expected_mode": expected_mode,
        "truth_source": None,
        "target": None,
        "line": None,
        "context": "missing",
        "classification": "missing_assignment",
        "wrapper_kind": None,
        "helper": None,
        "reasons": ["missing-assignment"],
    }


def make_base_scalar_inherited_record(
    slot: str, expected_mode: str, truth_source: str
) -> dict[str, object]:
    return {
        "slot": slot,
        "expected_mode": expected_mode,
        "truth_source": truth_source,
        "target": "<FillBaseDispatchTable>",
        "line": None,
        "context": "inherited",
        "classification": "base_scalar_inherited",
        "wrapper_kind": None,
        "helper": None,
        "reasons": [],
    }


def make_assignment_record(
    slot: str,
    expected_mode: str,
    truth_source: str | None,
    assignment: register_truthfulness.Assignment,
    classification: str,
    wrapper_kind: str | None,
    helper: str | None,
    reasons: list[str],
) -> dict[str, object]:
    return {
        "slot": slot,
        "expected_mode": expected_mode,
        "truth_source": truth_source,
        "target": assignment.target,
        "line": assignment.line,
        "context": assignment.context,
        "classification": classification,
        "wrapper_kind": wrapper_kind,
        "helper": helper,
        "reasons": dedupe_reasons(reasons),
    }


def audit_backend(backend: str) -> dict[str, object]:
    root = register_truthfulness.repo_root()
    config = register_truthfulness.build_config(
        root, SimpleNamespace(backend=backend, fixture=None)
    )
    register_truthfulness.validate_inputs(config)

    facts_asm = register_truthfulness.collect_symbol_facts(
        config.source_files, config.asm_symbol, True
    )
    facts_no_asm = register_truthfulness.collect_symbol_facts(
        config.source_files, config.asm_symbol, False
    )
    assignments = register_truthfulness.parse_assignments(
        config.register_file, config.asm_symbol
    )

    slot_records: list[dict[str, object]] = []
    issues: list[dict[str, object]] = []
    expected_modes = collect_expected_slot_modes_from_dispatchapi()[backend]
    key_slots = KEY_SLOTS_BY_BACKEND[backend]

    for slot in key_slots:
        expectation = expected_modes[slot]
        expected_mode = expectation.mode
        slot_assignments = [item for item in assignments if item.slot == slot]

        if expected_mode == "reuse_base_scalar":
            if not slot_assignments:
                record = make_base_scalar_inherited_record(
                    slot, expected_mode, expectation.truth_source
                )
                if not expectation.explicit_assert_present:
                    record["reasons"].append("missing-explicit-dispatchapi-assert")
                    issues.append(record)
                slot_records.append(record)
                continue

            for assignment in slot_assignments:
                facts = facts_asm if assignment.context != "no-asm" else facts_no_asm
                classification, wrapper_kind, helper = register_truthfulness.classify_target(
                    assignment.target, facts
                )
                reasons = ["unexpected-assignment-for-base-scalar-slot"]
                reasons.extend(
                    make_reason_list(backend, assignment, classification, wrapper_kind)
                )
                record = make_assignment_record(
                    slot,
                    expected_mode,
                    expectation.truth_source,
                    assignment,
                    classification,
                    wrapper_kind,
                    helper,
                    reasons,
                )
                slot_records.append(record)
                issues.append(record)
            continue

        if not slot_assignments:
            record = make_missing_record(slot, expected_mode)
            record["truth_source"] = expectation.truth_source
            if not expectation.explicit_assert_present:
                record["reasons"].append("missing-explicit-dispatchapi-assert")
            slot_records.append(record)
            issues.append(record)
            continue

        for assignment in slot_assignments:
            facts = facts_asm if assignment.context != "no-asm" else facts_no_asm
            classification, wrapper_kind, helper = register_truthfulness.classify_target(
                assignment.target, facts
            )
            reasons = make_reason_list(
                backend, assignment, classification, wrapper_kind
            )
            reasons = filter_allowed_backend_owned_reasons(
                backend, slot, assignment, classification, wrapper_kind, reasons
            )
            if not expectation.explicit_assert_present:
                reasons.insert(0, "missing-explicit-dispatchapi-assert")
            record = make_assignment_record(
                slot,
                expected_mode,
                expectation.truth_source,
                assignment,
                classification,
                wrapper_kind,
                helper,
                reasons,
            )
            slot_records.append(record)
            if reasons:
                issues.append(record)

    return {
        "backend": backend,
        "register_file": str(config.register_file),
        "slots_checked": len(key_slots),
        "records": slot_records,
        "issue_count": len(issues),
        "issues": issues,
        "ok": len(issues) == 0,
    }


def render_summary(report: dict[str, object]) -> str:
    backends = ",".join(str(item["backend"]) for item in report["backends"])
    return (
        "NONX86_KEY_SLOT_AUDIT_SUMMARY "
        f"backends={backends} "
        f"slots={report['slots_checked']} "
        f"issues={report['issue_count']} "
        f"status={'ok' if report['ok'] else 'fail'}"
    )


def print_human_report(report: dict[str, object]) -> None:
    for backend_report in report["backends"]:
        print(
            f"[KEY-SLOT-AUDIT] backend={backend_report['backend']} "
            f"register={backend_report['register_file']}"
        )
        for record in backend_report["records"]:
            reason_text = ""
            if record["reasons"]:
                reason_text = " reasons=" + ",".join(str(item) for item in record["reasons"])
            helper_text = ""
            if record["helper"]:
                helper_text = f" helper={record['helper']}"
            wrapper_text = ""
            if record["wrapper_kind"]:
                wrapper_text = f" wrapper={record['wrapper_kind']}"
            truth_source_text = ""
            if record["truth_source"]:
                truth_source_text = f" truth={record['truth_source']}"
            target_text = str(record["target"]) if record["target"] is not None else "<missing>"
            line_text = str(record["line"]) if record["line"] is not None else "n/a"
            print(
                f"  - {record['slot']} [{record['expected_mode']}] -> {target_text} "
                f"(class={record['classification']}, context={record['context']}{wrapper_text}{helper_text}, line={line_text}{truth_source_text})"
                f"{reason_text}"
            )
        if backend_report["ok"]:
            print(
                f"[KEY-SLOT-AUDIT] backend={backend_report['backend']} ok "
                f"slots={backend_report['slots_checked']}"
            )
        else:
            print(
                f"[KEY-SLOT-AUDIT] backend={backend_report['backend']} issues={backend_report['issue_count']}"
            )


def main() -> int:
    args = parse_args()
    selected_backends = ("neon", "riscvv") if args.backend == "all" else (args.backend,)
    backend_reports = [audit_backend(backend) for backend in selected_backends]
    report = {
        "backends": backend_reports,
        "slots_checked": sum(len(KEY_SLOTS_BY_BACKEND[item["backend"]]) for item in backend_reports),
        "issue_count": sum(int(item["issue_count"]) for item in backend_reports),
        "ok": all(bool(item["ok"]) for item in backend_reports),
    }

    if args.json:
        print(json.dumps(report, ensure_ascii=False, sort_keys=True))
    else:
        print_human_report(report)

    if args.summary_line:
        print(render_summary(report))

    return 0 if report["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
