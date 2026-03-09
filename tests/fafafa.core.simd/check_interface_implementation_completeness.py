#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable

INCLUDE_RE = re.compile(r"^\s*\{\$I\s+([^}]+)\}\s*$", re.IGNORECASE)
DISPATCH_RECORD_START_RE = re.compile(r"\bTSimdDispatchTable\s*=\s*record\b")
SLOT_RE = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(?:function|procedure)\b")
ASSIGN_RE = re.compile(r"\b(?:dispatchTable|table)\.([A-Za-z_][A-Za-z0-9_]*)\s*:=")
FACADE_DISPATCH_ACCESS_RE = re.compile(r"\b[A-Za-z_][A-Za-z0-9_]*Dispatch[A-Za-z0-9_]*\^\.([A-Za-z_][A-Za-z0-9_]*)\b")
README_LINK_RE = re.compile(r"`([^`]+fafafa\.core\.simd\.[^`]+)`")


@dataclass
class CheckItem:
    name: str
    status: str
    detail: str


def read_text_with_local_includes(a_path: Path, a_seen: set[Path] | None = None) -> str:
    if a_seen is None:
        a_seen = set()

    a_path = a_path.resolve()
    if a_path in a_seen:
        return ""
    a_seen.add(a_path)

    l_text = a_path.read_text(encoding="utf-8", errors="ignore")

    def repl(a_match: re.Match[str]) -> str:
        l_include_name = a_match.group(1).strip().strip("'\"")
        l_include_path = (a_path.parent / l_include_name).resolve()
        if not l_include_path.is_file():
            return a_match.group(0)
        return read_text_with_local_includes(l_include_path, a_seen)

    return INCLUDE_RE.sub(repl, l_text)


def extract_dispatch_slots(a_dispatch_text: str) -> list[str]:
    l_slots: list[str] = []
    l_in_record = False
    for l_line in a_dispatch_text.splitlines():
        if not l_in_record:
            if DISPATCH_RECORD_START_RE.search(l_line):
                l_in_record = True
            continue
        if re.match(r"^\s*end;\s*$", l_line):
            break
        l_match = SLOT_RE.match(l_line)
        if l_match:
            l_slots.append(l_match.group(1))
    return l_slots


def extract_fill_base_section(a_dispatch_text: str) -> str:
    l_parts = a_dispatch_text.split("implementation", 1)
    if len(l_parts) != 2:
        raise RuntimeError("implementation section not found in dispatch")

    l_impl_text = l_parts[1]
    l_start = l_impl_text.rfind("procedure FillBaseDispatchTable")
    if l_start < 0:
        raise RuntimeError("FillBaseDispatchTable implementation not found")

    l_rest = l_impl_text[l_start:]
    l_next_proc = re.search(
        r"(?m)^procedure\s+[A-Za-z_][A-Za-z0-9_]*\s*\(",
        l_rest[len("procedure FillBaseDispatchTable"):],
    )
    if l_next_proc is None:
        return l_rest
    return l_rest[: len("procedure FillBaseDispatchTable") + l_next_proc.start()]


def extract_assigned_slots(a_text: str, a_slot_set: set[str]) -> set[str]:
    return {l_slot for l_slot in ASSIGN_RE.findall(a_text) if l_slot in a_slot_set}


def extract_facade_dispatch_slots(a_facade_text: str) -> set[str]:
    return set(FACADE_DISPATCH_ACCESS_RE.findall(a_facade_text))


def extract_readme_links(a_readme_text: str) -> list[str]:
    l_links: list[str] = []
    for l_match in README_LINK_RE.finditer(a_readme_text):
        l_path = l_match.group(1)
        if l_path.endswith(('.md', '.STABLE')):
            l_links.append(l_path)
    return sorted(set(l_links))


def write_json(a_path: Path, a_payload: dict) -> None:
    a_path.parent.mkdir(parents=True, exist_ok=True)
    a_path.write_text(json.dumps(a_payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def write_md(a_path: Path, a_payload: dict) -> None:
    a_path.parent.mkdir(parents=True, exist_ok=True)
    l_lines = [
        "# SIMD interface completeness report",
        "",
        f"Status: **{a_payload['status']}**",
        "",
        "## Checks",
        "",
    ]
    for l_item in a_payload["checks"]:
        l_lines.append(f"- `{l_item['name']}`: **{l_item['status']}** — {l_item['detail']}")
    l_lines.extend(
        [
            "",
            "## Metrics",
            "",
            f"- facade dispatch slot refs: `{a_payload['metrics']['facade_slot_count']}`",
            f"- dispatch table slots: `{a_payload['metrics']['dispatch_slot_count']}`",
            f"- base fill assigned slots: `{a_payload['metrics']['base_fill_slot_count']}`",
        ]
    )
    a_path.write_text("\n".join(l_lines) + "\n", encoding="utf-8")


def main() -> int:
    l_parser = argparse.ArgumentParser(description="Check SIMD façade/dispatch completeness")
    l_parser.add_argument("--root", default=str(Path(__file__).resolve().parent))
    l_parser.add_argument("--strict", action="store_true")
    l_parser.add_argument("--strict-level", default="p2")
    l_parser.add_argument("--json-file", default="")
    l_parser.add_argument("--md-file", default="")
    l_args = l_parser.parse_args()

    l_root = Path(l_args.root).resolve()
    l_repo_root = l_root.parent.parent
    l_src_root = l_repo_root / "src"
    l_docs_root = l_repo_root / "docs"

    l_facade_file = l_src_root / "fafafa.core.simd.pas"
    l_dispatch_file = l_src_root / "fafafa.core.simd.dispatch.pas"
    l_readme_file = l_src_root / "fafafa.core.simd.README.md"

    l_checks: list[CheckItem] = []

    if not l_facade_file.is_file() or not l_dispatch_file.is_file():
        raise RuntimeError("required simd source files are missing")

    l_facade_text = read_text_with_local_includes(l_facade_file)
    l_dispatch_text = read_text_with_local_includes(l_dispatch_file)

    l_facade_slots = extract_facade_dispatch_slots(l_facade_text)
    l_dispatch_slots = extract_dispatch_slots(l_dispatch_text)
    l_dispatch_slot_set = set(l_dispatch_slots)
    l_fill_base_text = extract_fill_base_section(l_dispatch_text)
    l_fill_base_slots = extract_assigned_slots(l_fill_base_text, l_dispatch_slot_set)

    l_missing_in_dispatch = sorted(l_facade_slots - l_dispatch_slot_set)
    l_missing_in_fill_base = sorted(l_facade_slots - l_fill_base_slots)

    if l_missing_in_dispatch:
        l_checks.append(CheckItem(
            name="facade_slots_declared_in_dispatch",
            status="FAIL",
            detail="missing in TSimdDispatchTable: " + ", ".join(l_missing_in_dispatch[:20]),
        ))
    else:
        l_checks.append(CheckItem(
            name="facade_slots_declared_in_dispatch",
            status="PASS",
            detail=f"all {len(l_facade_slots)} façade slot refs exist in TSimdDispatchTable",
        ))

    if l_missing_in_fill_base:
        l_checks.append(CheckItem(
            name="facade_slots_covered_by_base_fill",
            status="FAIL",
            detail="missing in FillBaseDispatchTable: " + ", ".join(l_missing_in_fill_base[:20]),
        ))
    else:
        l_checks.append(CheckItem(
            name="facade_slots_covered_by_base_fill",
            status="PASS",
            detail=f"all {len(l_facade_slots)} façade slot refs have base fallback coverage",
        ))

    if l_readme_file.is_file():
        l_readme_links = extract_readme_links(l_readme_file.read_text(encoding="utf-8", errors="ignore"))
        l_missing_docs = sorted(
            l_link for l_link in l_readme_links if not (l_repo_root / l_link).is_file()
        )
        if l_missing_docs:
            l_checks.append(CheckItem(
                name="readme_simd_links_exist",
                status="FAIL",
                detail="missing referenced files: " + ", ".join(l_missing_docs[:20]),
            ))
        else:
            l_checks.append(CheckItem(
                name="readme_simd_links_exist",
                status="PASS",
                detail=f"all {len(l_readme_links)} referenced SIMD docs/STABLE files exist",
            ))
    else:
        l_checks.append(CheckItem(
            name="readme_simd_links_exist",
            status="FAIL",
            detail=f"missing {l_readme_file}",
        ))

    l_status = "PASS" if all(l_item.status == "PASS" for l_item in l_checks) else "FAIL"
    l_payload = {
        "status": l_status,
        "strict": bool(l_args.strict),
        "strict_level": l_args.strict_level,
        "checks": [asdict(l_item) for l_item in l_checks],
        "metrics": {
            "facade_slot_count": len(l_facade_slots),
            "dispatch_slot_count": len(l_dispatch_slots),
            "base_fill_slot_count": len(l_fill_base_slots),
        },
        "files": {
            "facade": str(l_facade_file),
            "dispatch": str(l_dispatch_file),
            "readme": str(l_readme_file),
            "docs_root": str(l_docs_root),
        },
    }

    if l_args.json_file:
        write_json(Path(l_args.json_file), l_payload)
    if l_args.md_file:
        write_md(Path(l_args.md_file), l_payload)

    print(json.dumps(l_payload, ensure_ascii=False, indent=2))
    return 0 if l_status == "PASS" else 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as l_exc:
        print(json.dumps({"status": "ERROR", "detail": str(l_exc)}, ensure_ascii=False), file=sys.stderr)
        sys.exit(2)
