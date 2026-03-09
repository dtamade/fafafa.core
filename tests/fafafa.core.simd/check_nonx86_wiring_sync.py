#!/usr/bin/env python3
"""
Check non-x86 wiring checklist consistency between:
1) legacy manual wiring assertions
2) grouped wiring assertions
3) non-x86 interface checklist markdown markers
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any


def extract_method_body(source_text: str, method_name: str) -> str:
    pattern = re.compile(
        rf"procedure\s+TTestCase_DispatchAPI\.{re.escape(method_name)}\s*;(?P<body>.*?)(?=\nprocedure\s+TTestCase_DispatchAPI\.|\ninitialization\b)",
        re.IGNORECASE | re.DOTALL,
    )
    match = pattern.search(source_text)
    if not match:
        raise RuntimeError(f"method not found: {method_name}")
    return match.group("body")


def parse_slots_from_assigned(method_body: str) -> set[str]:
    return set(re.findall(r"Assigned\(LTable\.([A-Za-z0-9_]+)\)", method_body))


def parse_slots_from_grouped(method_body: str) -> set[str]:
    return set(re.findall(r"Pointer\(LTable\.([A-Za-z0-9_]+)\)", method_body))


def evaluate_exit_code(result: dict[str, Any], strict_extra: bool) -> int:
    if result["missing_in_grouped"]:
        return 1
    if strict_extra and result["extra_in_grouped"]:
        return 1
    if result["missing_markers"]:
        return 1
    return 0


def render_summary_line(result: dict[str, Any], strict_extra: bool) -> str:
    return (
        "WIRING_SYNC_SUMMARY "
        f"legacy={result['legacy_count']} "
        f"grouped={result['grouped_count']} "
        f"missing={len(result['missing_in_grouped'])} "
        f"extra={len(result['extra_in_grouped'])} "
        f"markers_missing={len(result['missing_markers'])} "
        f"strict_extra={1 if strict_extra else 0}"
    )


def print_human_result(result: dict[str, Any], strict_extra: bool) -> None:
    print("[WIRING-SYNC] non-x86 wiring consistency")
    print(f"  - legacy slots:  {result['legacy_count']}")
    print(f"  - grouped slots: {result['grouped_count']}")
    print(f"  - missing in grouped: {len(result['missing_in_grouped'])}")
    print(f"  - extra in grouped:   {len(result['extra_in_grouped'])}")

    if result["missing_in_grouped"]:
        print("[WIRING-SYNC] Missing grouped slots:")
        for slot in result["missing_in_grouped"]:
            print(f"  - {slot}")

    if result["extra_in_grouped"]:
        if strict_extra:
            print("[WIRING-SYNC] Extra grouped slots (strict mode):")
        else:
            print("[WIRING-SYNC] Extra grouped slots (non-strict, info):")
        for slot in result["extra_in_grouped"]:
            print(f"  - {slot}")

    if result["missing_markers"]:
        print("[WIRING-SYNC] Checklist missing markers:")
        for marker in result["missing_markers"]:
            print(f"  - {marker}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Check non-x86 wiring sync")
    parser.add_argument("--strict-extra", action="store_true", help="fail when grouped slots are beyond legacy slots")
    parser.add_argument("--json", action="store_true", help="print machine-readable JSON result")
    parser.add_argument("--summary-line", action="store_true", help="print one-line summary for gate logs")
    parser.add_argument("--testcase", default="tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas")
    parser.add_argument("--checklist", default="docs/plans/2026-02-09-simd-nonx86-interface-target-checklist.md")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[2]
    testcase_path = repo_root / args.testcase
    checklist_path = repo_root / args.checklist

    if not testcase_path.exists() or not checklist_path.exists():
        error_result = {
            "ok": False,
            "error": "input-file-missing",
            "testcase_exists": testcase_path.exists(),
            "checklist_exists": checklist_path.exists(),
            "testcase": str(testcase_path),
            "checklist": str(checklist_path),
        }
        if args.json:
            print(json.dumps(error_result, ensure_ascii=False, sort_keys=True))
        else:
            if not testcase_path.exists():
                print(f"[WIRING-SYNC] Missing testcase: {testcase_path}")
            if not checklist_path.exists():
                print(f"[WIRING-SYNC] Missing checklist: {checklist_path}")
        return 2

    try:
        testcase_text = testcase_path.read_text(encoding="utf-8")
        checklist_text = checklist_path.read_text(encoding="utf-8")

        legacy_body = extract_method_body(testcase_text, "Test_NonX86_DispatchTable_WiringChecklist")
        grouped_body = extract_method_body(testcase_text, "Test_NonX86_DispatchTable_WiringChecklist_Grouped")

        legacy_slots = parse_slots_from_assigned(legacy_body)
        grouped_slots = parse_slots_from_grouped(grouped_body)

        checklist_markers = {
            "wiring_grouped_line": [
                "Wiring grouped-batch assertions",
                "Wiring 分组批量断言已落地",
                "`Wiring` grouped-batch assertions",
            ],
            "wiring_grouped_method": ["Test_NonX86_DispatchTable_WiringChecklist_Grouped"],
            "wiring_grouped_tag": ["WiringGrouped"],
        }

        missing_markers = [
            name
            for name, marker_candidates in checklist_markers.items()
            if not any(marker in checklist_text for marker in marker_candidates)
        ]

        result = {
            "legacy_count": len(legacy_slots),
            "grouped_count": len(grouped_slots),
            "missing_in_grouped": sorted(legacy_slots - grouped_slots),
            "extra_in_grouped": sorted(grouped_slots - legacy_slots),
            "missing_markers": missing_markers,
            "strict_extra": bool(args.strict_extra),
            "testcase": str(testcase_path),
            "checklist": str(checklist_path),
        }
        exit_code = evaluate_exit_code(result, bool(args.strict_extra))
        result["ok"] = exit_code == 0
        result["exit_code"] = exit_code

        if args.json:
            print(json.dumps(result, ensure_ascii=False, sort_keys=True))
        else:
            print_human_result(result, bool(args.strict_extra))
            if exit_code == 0:
                print("[WIRING-SYNC] OK")

        if args.summary_line:
            print(render_summary_line(result, bool(args.strict_extra)))

        return exit_code
    except RuntimeError as exc:
        error_result = {
            "ok": False,
            "error": "runtime-error",
            "message": str(exc),
        }
        if args.json:
            print(json.dumps(error_result, ensure_ascii=False, sort_keys=True))
        else:
            print(f"[WIRING-SYNC] ERROR: {exc}")
        return 2


if __name__ == "__main__":
    sys.exit(main())
