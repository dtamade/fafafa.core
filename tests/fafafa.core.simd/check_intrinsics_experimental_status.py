#!/usr/bin/env python3
"""Check that experimental SIMD intrinsics stay isolated from default entry points."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any


EXPERIMENTAL_UNITS = [
    "fafafa.core.simd.intrinsics.aes",
    "fafafa.core.simd.intrinsics.sha",
    "fafafa.core.simd.intrinsics.avx",
    "fafafa.core.simd.intrinsics.sse2",
    "fafafa.core.simd.intrinsics.sse3",
    "fafafa.core.simd.intrinsics.sse41",
    "fafafa.core.simd.intrinsics.sse42",
    "fafafa.core.simd.intrinsics.avx512",
    "fafafa.core.simd.intrinsics.fma3",
    "fafafa.core.simd.intrinsics.neon",
    "fafafa.core.simd.intrinsics.rvv",
    "fafafa.core.simd.intrinsics.sve",
    "fafafa.core.simd.intrinsics.sve2",
    "fafafa.core.simd.intrinsics.lasx",
    "fafafa.core.simd.intrinsics.x86.sse2",
]

DEFAULT_ENTRY_FILES = [
    "src/fafafa.core.simd.pas",
    "src/fafafa.core.simd.intrinsics.pas",
    "tests/fafafa.core.simd/fafafa.core.simd.test.lpr",
    "tests/fafafa.core.simd/BuildOrTest.sh",
    "tests/fafafa.core.simd/buildOrTest.bat",
    "tests/fafafa.core.simd/collect_linux_simd_evidence.sh",
]

# Placeholder-heavy units that must keep an explicit runtime guard.
# Enforce guard-token presence on every unit listed in EXPERIMENTAL_UNITS so
# experimental behavior cannot silently drift into default-callable semantics.
GUARDED_EXPERIMENTAL_FILES = [f"src/{l_unit}.pas" for l_unit in EXPERIMENTAL_UNITS]
REQUIRED_GUARD_TOKEN = "fafafa_simd_experimental_intrinsics"
FORBIDDEN_DEFAULT_DEFINE_PATTERNS = [
    r"(?i)-dFAFAFA_SIMD_EXPERIMENTAL_INTRINSICS\b",
    r"(?i)\{\$DEFINE\s+FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS\}",
]


def _scan_leaks(a_repo_root: Path, a_entry_files: list[str], a_units: list[str]) -> dict[str, list[str]]:
    l_leaks: dict[str, list[str]] = {}
    for l_rel in a_entry_files:
        l_path = a_repo_root / l_rel
        if not l_path.is_file():
            continue
        l_text = l_path.read_text(encoding="utf-8", errors="ignore").lower()
        l_hit_units: list[str] = []
        for l_unit in a_units:
            # Token-aware match: avoid false positives like intrinsics.avx vs intrinsics.avx2.
            l_pattern = r"(?<![a-z0-9_])" + re.escape(l_unit) + r"(?![a-z0-9_])"
            if re.search(l_pattern, l_text):
                l_hit_units.append(l_unit)
        if l_hit_units:
            l_leaks[l_rel] = sorted(l_hit_units)
    return l_leaks


def _scan_guard_markers(a_repo_root: Path, a_files: list[str], a_token: str) -> list[str]:
    l_missing: list[str] = []
    for l_rel in a_files:
        l_path = a_repo_root / l_rel
        if not l_path.is_file():
            l_missing.append(l_rel)
            continue
        l_text = l_path.read_text(encoding="utf-8", errors="ignore").lower()
        if a_token not in l_text:
            l_missing.append(l_rel)
    return sorted(l_missing)


def _scan_forbidden_default_defines(a_repo_root: Path, a_files: list[str], a_patterns: list[str]) -> list[str]:
    l_hits: list[str] = []
    for l_rel in a_files:
        l_path = a_repo_root / l_rel
        if not l_path.is_file():
            continue
        l_text = l_path.read_text(encoding="utf-8", errors="ignore")
        for l_pattern in a_patterns:
            if re.search(l_pattern, l_text):
                l_hits.append(l_rel)
                break
    return sorted(l_hits)


def _render_summary_line(a_result: dict[str, Any]) -> str:
    return (
        "INTRINSICS_EXPERIMENTAL_SUMMARY "
        f"experimental_units={a_result['experimental_units']} "
        f"entry_files={a_result['entry_files']} "
        f"leaked_files={a_result['leaked_files']} "
        f"leaked_units={a_result['leaked_units']} "
        f"missing_guard_markers={a_result['missing_guard_markers']} "
        f"default_define_leaks={a_result['default_define_leaks']}"
    )


def _print_human_result(a_result: dict[str, Any]) -> None:
    print("[EXPERIMENTAL] SIMD intrinsics entry isolation")
    print(f"  - tracked experimental units: {a_result['experimental_units']}")
    print(f"  - checked entry files:        {a_result['entry_files']}")
    print(f"  - leaked files:               {a_result['leaked_files']}")
    print(f"  - leaked units:               {a_result['leaked_units']}")
    print(f"  - missing guard markers:      {a_result['missing_guard_markers']}")
    print(f"  - default-define leaks:       {a_result['default_define_leaks']}")

    if a_result["leaks"]:
        print("[EXPERIMENTAL] Leaks found:")
        for l_file, l_units in a_result["leaks"].items():
            print(f"  - {l_file}")
            for l_unit in l_units:
                print(f"    * {l_unit}")
    if a_result["missing_guard_files"]:
        print("[EXPERIMENTAL] Missing required guard marker in:")
        for l_file in a_result["missing_guard_files"]:
            print(f"  - {l_file}")

    if a_result["default_define_files"]:
        print("[EXPERIMENTAL] Forbidden default entry define found in:")
        for l_file in a_result["default_define_files"]:
            print(f"  - {l_file}")

    if (not a_result["leaks"]) and (not a_result["missing_guard_files"]) and (not a_result["default_define_files"]):
        print("[EXPERIMENTAL] OK (no experimental units in default entry chain)")


def main() -> int:
    l_parser = argparse.ArgumentParser(description="Check experimental intrinsics isolation")
    l_parser.add_argument("--json", action="store_true", help="print machine-readable JSON")
    l_parser.add_argument("--summary-line", action="store_true", help="print one-line summary")
    l_parser.add_argument(
        "--entry-file",
        action="append",
        dest="entry_files",
        default=None,
        help="override/add entry file to scan (repo-relative)",
    )
    l_args = l_parser.parse_args()

    l_repo_root = Path(__file__).resolve().parents[2]
    l_entry_files = l_args.entry_files if l_args.entry_files else list(DEFAULT_ENTRY_FILES)
    l_leaks = _scan_leaks(a_repo_root=l_repo_root, a_entry_files=l_entry_files, a_units=EXPERIMENTAL_UNITS)
    l_leaked_units = sorted({l_unit for l_units in l_leaks.values() for l_unit in l_units})
    l_missing_guard_files = _scan_guard_markers(
        a_repo_root=l_repo_root,
        a_files=GUARDED_EXPERIMENTAL_FILES,
        a_token=REQUIRED_GUARD_TOKEN,
    )
    l_default_define_files = _scan_forbidden_default_defines(
        a_repo_root=l_repo_root,
        a_files=l_entry_files,
        a_patterns=FORBIDDEN_DEFAULT_DEFINE_PATTERNS,
    )

    l_result: dict[str, Any] = {
        "ok": (len(l_leaks) == 0) and (len(l_missing_guard_files) == 0) and (len(l_default_define_files) == 0),
        "experimental_units": len(EXPERIMENTAL_UNITS),
        "entry_files": len(l_entry_files),
        "leaked_files": len(l_leaks),
        "leaked_units": len(l_leaked_units),
        "missing_guard_markers": len(l_missing_guard_files),
        "default_define_leaks": len(l_default_define_files),
        "entry_file_list": l_entry_files,
        "leaks": l_leaks,
        "leaked_unit_list": l_leaked_units,
        "missing_guard_files": l_missing_guard_files,
        "default_define_files": l_default_define_files,
    }

    if l_args.json:
        print(json.dumps(l_result, ensure_ascii=False, sort_keys=True, indent=2))
    else:
        _print_human_result(l_result)

    if l_args.summary_line:
        print(_render_summary_line(l_result))

    return 0 if l_result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
