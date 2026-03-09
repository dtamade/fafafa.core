#!/usr/bin/env python3
"""Machine-check SIMD interface -> dispatch -> backend -> tests completeness."""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any


SLOT_RE = re.compile(r"\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(?:function|procedure)\b")
ASSIGN_RE = re.compile(r"\b(?:dispatchTable|table)\.([A-Za-z_][A-Za-z0-9_]*)\s*:=")
TOKEN_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
INCLUDE_RE = re.compile(r"\{\$I\s+([^}]+)\}", re.IGNORECASE)

CRITICAL_PREFIXES = ("Round", "Trunc", "Floor", "Ceil")
CRITICAL_SUFFIXES = ("F32x4", "F64x2", "F32x8", "F64x4", "F32x16", "F64x8")


@dataclass(frozen=True)
class SlotCoverage:
    slot: str
    assigned_backends: list[str]
    test_refs: int
    severity: str
    reason: str




def read_text_with_local_includes(path: Path, seen: set[Path] | None = None) -> str:
    if seen is None:
        seen = set()

    path = path.resolve()
    if path in seen:
        return ""
    seen.add(path)

    text = path.read_text(encoding="utf-8", errors="ignore")

    def repl(match: re.Match[str]) -> str:
        include_name = match.group(1).strip()
        include_path = (path.parent / include_name).resolve()
        if not include_path.exists():
            return match.group(0)
        return read_text_with_local_includes(include_path, seen)

    return INCLUDE_RE.sub(repl, text)

def extract_dispatch_slots(dispatch_file: Path) -> list[str]:
    text = read_text_with_local_includes(dispatch_file).splitlines()
    slots: list[str] = []
    in_record = False
    for line in text:
        if not in_record:
            if re.search(r"\bTSimdDispatchTable\s*=\s*record\b", line):
                in_record = True
            continue
        if re.match(r"\s*end;\s*$", line):
            break
        m = SLOT_RE.match(line)
        if m:
            slots.append(m.group(1))
    return slots


def extract_assigned_slots(path: Path, slot_set: set[str]) -> set[str]:
    text = read_text_with_local_includes(path)
    assigned = set(ASSIGN_RE.findall(text))
    return assigned & slot_set


def build_test_token_counter(tests_root: Path) -> dict[str, int]:
    counter: dict[str, int] = {}
    for file in sorted(tests_root.rglob("*.pas")):
        text = file.read_text(encoding="utf-8", errors="ignore")
        for token in TOKEN_RE.findall(text):
            counter[token] = counter.get(token, 0) + 1
    return counter


def is_critical_slot(slot: str) -> bool:
    return slot.startswith(CRITICAL_PREFIXES) and slot.endswith(CRITICAL_SUFFIXES)


def classify_slot(slot: str, assigned_backends: list[str], test_refs: int) -> tuple[str, str]:
    has_scalar = "scalar" in assigned_backends
    simd_backends = [x for x in assigned_backends if x != "scalar"]
    has_nonx86 = ("neon" in assigned_backends) or ("riscvv" in assigned_backends)

    if not has_scalar:
        return ("P0", "missing scalar dispatch assignment")

    if is_critical_slot(slot):
        if test_refs == 0:
            return ("P0", "critical slot has no tests token references")
        if len(simd_backends) == 0:
            return ("P0", "critical slot is scalar-only")
        if not has_nonx86:
            return ("P1", "critical slot has no non-x86 backend assignment")
        if test_refs < 3:
            return ("P2", "critical slot test references are thin")
        return ("OK", "critical slot covered")

    if len(simd_backends) == 0 and test_refs == 0:
        return ("P1", "scalar-only and no tests token references")
    if test_refs == 0:
        return ("P2", "no tests token references")
    return ("OK", "covered")


def should_fail_in_strict(severity_counts: dict[str, int], strict_level: str) -> bool:
    p0 = severity_counts.get("P0", 0)
    p1 = severity_counts.get("P1", 0)
    p2 = severity_counts.get("P2", 0)

    if strict_level == "p0":
        return p0 > 0
    if strict_level == "p1":
        return (p0 + p1) > 0
    # strict_level == "p2"
    return (p0 + p1 + p2) > 0


def render_markdown(
    report: dict[str, Any],
    out_path: Path,
) -> None:
    lines: list[str] = []
    lines.append("# SIMD Interface/Implementation Completeness Report")
    lines.append("")
    lines.append(f"- generated_at: {report['generated_at']}")
    lines.append(f"- dispatch_slots_total: `{report['dispatch_slots_total']}`")
    lines.append(f"- strict: `{report['strict']}`")
    lines.append(f"- strict_level: `{report['strict_level']}`")
    lines.append("- analyzer: `heuristic token/assignment scan (not semantic proof)`")
    lines.append("")
    lines.append("## Backend Slot Coverage")
    lines.append("")
    for backend, count in report["backend_slot_counts"].items():
        lines.append(f"- {backend}: `{count}/{report['dispatch_slots_total']}`")
    lines.append("")
    lines.append("## Severity Summary")
    lines.append("")
    lines.append(f"- P0: `{report['severity_counts'].get('P0', 0)}`")
    lines.append(f"- P1: `{report['severity_counts'].get('P1', 0)}`")
    lines.append(f"- P2: `{report['severity_counts'].get('P2', 0)}`")
    lines.append("")
    lines.append("## P0 Items")
    lines.append("")
    if not report["p0_items"]:
        lines.append("- none")
    else:
        for item in report["p0_items"]:
            lines.append(f"- `{item['slot']}`: {item['reason']}")
    lines.append("")
    lines.append("## P1 Items (Top 80)")
    lines.append("")
    if not report["p1_items"]:
        lines.append("- none")
    else:
        for item in report["p1_items"][:80]:
            lines.append(f"- `{item['slot']}`: {item['reason']}")
    lines.append("")
    lines.append("## P2 Items (Top 80)")
    lines.append("")
    if not report["p2_items"]:
        lines.append("- none")
    else:
        for item in report["p2_items"][:80]:
            lines.append(f"- `{item['slot']}`: {item['reason']}")
    lines.append("")

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Check SIMD interface implementation completeness")
    parser.add_argument("--strict", action="store_true", help="enable strict failure by severity threshold")
    parser.add_argument(
        "--strict-level",
        choices=("p0", "p1", "p2"),
        default="p2",
        help="strict threshold: p0=fail on P0, p1=fail on P0/P1, p2=fail on P0/P1/P2",
    )
    parser.add_argument(
        "--json-file",
        default="tests/fafafa.core.simd/logs/interface_completeness.json",
        help="Output JSON file path (repo-relative)",
    )
    parser.add_argument(
        "--md-file",
        default="tests/fafafa.core.simd/docs/interface_implementation_completeness.md",
        help="Output markdown file path (repo-relative)",
    )
    parser.add_argument("--json", action="store_true", help="print JSON to stdout")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[2]
    dispatch_file = repo_root / "src" / "fafafa.core.simd.dispatch.pas"
    tests_root = repo_root / "tests" / "fafafa.core.simd"

    backend_files = {
        "scalar": dispatch_file,
        "sse2": repo_root / "src" / "fafafa.core.simd.sse2.pas",
        "sse3": repo_root / "src" / "fafafa.core.simd.sse3.pas",
        "ssse3": repo_root / "src" / "fafafa.core.simd.ssse3.pas",
        "sse41": repo_root / "src" / "fafafa.core.simd.sse41.pas",
        "sse42": repo_root / "src" / "fafafa.core.simd.sse42.pas",
        "avx2": repo_root / "src" / "fafafa.core.simd.avx2.pas",
        "avx512": repo_root / "src" / "fafafa.core.simd.avx512.pas",
        "neon": repo_root / "src" / "fafafa.core.simd.neon.pas",
        "riscvv": repo_root / "src" / "fafafa.core.simd.riscvv.pas",
    }

    slots = extract_dispatch_slots(dispatch_file)
    slot_set = set(slots)
    test_counter = build_test_token_counter(tests_root)

    backend_assigned: dict[str, set[str]] = {}
    for backend, file in backend_files.items():
        backend_assigned[backend] = extract_assigned_slots(file, slot_set)

    items: list[SlotCoverage] = []
    severity_counts = {"P0": 0, "P1": 0, "P2": 0}
    for slot in sorted(slots):
        assigned_backends = [backend for backend in backend_files.keys() if slot in backend_assigned[backend]]
        severity, reason = classify_slot(slot=slot, assigned_backends=assigned_backends, test_refs=test_counter.get(slot, 0))
        items.append(
            SlotCoverage(
                slot=slot,
                assigned_backends=assigned_backends,
                test_refs=test_counter.get(slot, 0),
                severity=severity,
                reason=reason,
            )
        )
        if severity in severity_counts:
            severity_counts[severity] += 1

    p0_items = [
        {
            "slot": x.slot,
            "assigned_backends": x.assigned_backends,
            "test_refs": x.test_refs,
            "reason": x.reason,
        }
        for x in items
        if x.severity == "P0"
    ]
    p1_items = [
        {
            "slot": x.slot,
            "assigned_backends": x.assigned_backends,
            "test_refs": x.test_refs,
            "reason": x.reason,
        }
        for x in items
        if x.severity == "P1"
    ]
    p2_items = [
        {
            "slot": x.slot,
            "assigned_backends": x.assigned_backends,
            "test_refs": x.test_refs,
            "reason": x.reason,
        }
        for x in items
        if x.severity == "P2"
    ]

    report: dict[str, Any] = {
        "generated_at": datetime.now().isoformat(timespec="seconds"),
        "strict": bool(args.strict),
        "strict_level": args.strict_level,
        "analyzer": "heuristic-token-assignment-scan",
        "dispatch_slots_total": len(slots),
        "backend_slot_counts": {k: len(v) for k, v in backend_assigned.items()},
        "severity_counts": severity_counts,
        "p0_items": p0_items,
        "p1_items": p1_items,
        "p2_items": p2_items,
    }

    json_path = Path(args.json_file)
    if not json_path.is_absolute():
        json_path = repo_root / json_path
    md_path = Path(args.md_file)
    if not md_path.is_absolute():
        md_path = repo_root / md_path

    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    render_markdown(report=report, out_path=md_path)

    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        strict_fail = should_fail_in_strict(severity_counts, args.strict_level)
        print("[SIMD-COMPLETENESS] interface->dispatch->backend->tests")
        print(f"  - dispatch_slots_total: {report['dispatch_slots_total']}")
        print(f"  - backend_slot_counts: {report['backend_slot_counts']}")
        print(f"  - severity_counts: {report['severity_counts']}")
        print(f"  - strict_level: {report['strict_level']}")
        print("  - analyzer: heuristic token/assignment scan (not semantic proof)")
        print(f"  - json: {json_path}")
        print(f"  - markdown: {md_path}")
        if p0_items:
            print("  - P0 preview:")
            for item in p0_items[:10]:
                print(f"    * {item['slot']}: {item['reason']}")
        if args.strict and strict_fail:
            print("[SIMD-COMPLETENESS] FAIL (strict threshold breached)")
        elif p0_items:
            print("[SIMD-COMPLETENESS] FAIL (P0 exists)")
        else:
            print("[SIMD-COMPLETENESS] OK")

    if args.strict and should_fail_in_strict(severity_counts, args.strict_level):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
