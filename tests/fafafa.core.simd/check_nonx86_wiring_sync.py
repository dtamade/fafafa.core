#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from dataclasses import asdict, dataclass
from pathlib import Path


@dataclass
class CheckItem:
    name: str
    status: str
    detail: str


def load_text(a_path: Path) -> str:
    return a_path.read_text(encoding="utf-8", errors="ignore")


def write_json(a_path: Path, a_payload: dict) -> None:
    a_path.parent.mkdir(parents=True, exist_ok=True)
    a_path.write_text(json.dumps(a_payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    l_parser = argparse.ArgumentParser(description="Check non-x86 SIMD wiring sync")
    l_parser.add_argument("--root", default=str(Path(__file__).resolve().parent))
    l_parser.add_argument("--json", action="store_true")
    l_parser.add_argument("--summary-line", action="store_true")
    l_parser.add_argument("--strict-extra", action="store_true")
    l_args = l_parser.parse_args()

    l_root = Path(l_args.root).resolve()
    l_repo_root = l_root.parent.parent
    l_src_root = l_repo_root / "src"
    l_docs_root = l_repo_root / "docs"

    l_simd_pas = l_src_root / "fafafa.core.simd.pas"
    l_cpuinfo_pas = l_src_root / "fafafa.core.simd.cpuinfo.pas"
    l_dispatch_pas = l_src_root / "fafafa.core.simd.dispatch.pas"
    l_readme = l_src_root / "fafafa.core.simd.README.md"
    l_stable = l_src_root / "fafafa.core.simd.STABLE"
    l_closeout = l_docs_root / "fafafa.core.simd.closeout.md"

    l_simd_text = load_text(l_simd_pas)
    l_cpuinfo_text = load_text(l_cpuinfo_pas)
    l_dispatch_text = load_text(l_dispatch_pas)
    l_readme_text = load_text(l_readme)
    l_stable_text = load_text(l_stable)
    l_closeout_text = load_text(l_closeout)

    l_checks: list[CheckItem] = []

    l_neon_guard = "{$IFDEF SIMD_ARM_AVAILABLE}" in l_simd_text and ", fafafa.core.simd.neon" in l_simd_text
    l_riscvv_guard = (
        "{$IF DEFINED(SIMD_RISCV_AVAILABLE) AND DEFINED(SIMD_EXPERIMENTAL_RISCVV)}" in l_simd_text
        and ", fafafa.core.simd.riscvv" in l_simd_text
    )
    if l_neon_guard and l_riscvv_guard:
        l_checks.append(CheckItem(
            name="simd_pas_nonx86_guards",
            status="PASS",
            detail="NEON uses SIMD_ARM_AVAILABLE; RISCVV uses explicit SIMD_EXPERIMENTAL_RISCVV opt-in guard",
        ))
    else:
        l_details: list[str] = []
        if not l_neon_guard:
            l_details.append("NEON guard missing or malformed")
        if not l_riscvv_guard:
            l_details.append("RISCVV opt-in guard missing or malformed")
        l_checks.append(CheckItem(
            name="simd_pas_nonx86_guards",
            status="FAIL",
            detail="; ".join(l_details),
        ))

    l_cpuinfo_mentions = all(l_token in l_cpuinfo_text for l_token in ("sbNEON", "sbRISCVV", "HasNEON", "HasRISCVV"))
    l_dispatch_mentions = all(l_token in l_dispatch_text for l_token in ("sbNEON", "sbRISCVV"))
    if l_cpuinfo_mentions and l_dispatch_mentions:
        l_checks.append(CheckItem(
            name="cpuinfo_dispatch_nonx86_symbols",
            status="PASS",
            detail="cpuinfo/dispatch both still expose NEON and RISCVV backend symbols",
        ))
    else:
        l_checks.append(CheckItem(
            name="cpuinfo_dispatch_nonx86_symbols",
            status="FAIL",
            detail="missing NEON/RISCVV symbol references in cpuinfo or dispatch",
        ))

    l_readme_boundary = (
        "sbRISCVV" in l_readme_text
        and "SIMD_EXPERIMENTAL_RISCVV" in l_readme_text
        and "experimental" in l_readme_text.lower()
    )
    if l_readme_boundary:
        l_checks.append(CheckItem(
            name="readme_experimental_boundary",
            status="PASS",
            detail="README documents RISCVV experimental boundary and explicit opt-in",
        ))
    else:
        l_checks.append(CheckItem(
            name="readme_experimental_boundary",
            status="FAIL",
            detail="README missing RISCVV experimental/opt-in boundary wording",
        ))

    l_stable_boundary = "sbRISCVV" in l_stable_text and "experimental" in l_stable_text.lower()
    l_closeout_boundary = "sbRISCVV" in l_closeout_text and "experimental" in l_closeout_text.lower()
    if l_stable_boundary and l_closeout_boundary:
        l_checks.append(CheckItem(
            name="stable_closeout_boundary_docs",
            status="PASS",
            detail="STABLE and closeout docs both preserve non-x86 experimental boundary wording",
        ))
    else:
        l_checks.append(CheckItem(
            name="stable_closeout_boundary_docs",
            status="FAIL",
            detail="STABLE/closeout docs missing non-x86 experimental boundary wording",
        ))

    if l_args.strict_extra:
        l_strict_ok = "SIMD_GATE_WIRING_SYNC=1" in l_stable_text and "wiring-sync" in l_closeout_text
        if l_strict_ok:
            l_checks.append(CheckItem(
                name="strict_gate_docs_reference_wiring",
                status="PASS",
                detail="STABLE and closeout docs both reference wiring-sync gate usage",
            ))
        else:
            l_checks.append(CheckItem(
                name="strict_gate_docs_reference_wiring",
                status="FAIL",
                detail="strict wiring gate references missing in STABLE or closeout docs",
            ))

    l_failed = [l_item for l_item in l_checks if l_item.status != "PASS"]
    l_payload = {
        "status": "PASS" if not l_failed else "FAIL",
        "strict_extra": l_args.strict_extra,
        "checks": [asdict(l_item) for l_item in l_checks],
        "files": {
            "simd": str(l_simd_pas),
            "cpuinfo": str(l_cpuinfo_pas),
            "dispatch": str(l_dispatch_pas),
            "readme": str(l_readme),
            "stable": str(l_stable),
            "closeout": str(l_closeout),
        },
    }

    if l_args.json:
        print(json.dumps(l_payload, ensure_ascii=False, indent=2))
    else:
        for l_item in l_checks:
            print(f"[WIRING-SYNC] {l_item.name}: {l_item.status} - {l_item.detail}")
        if l_args.summary_line:
            print(
                "WIRING_SYNC_SUMMARY "
                f"checks={len(l_checks)} failed={len(l_failed)} status={l_payload['status']} strict_extra={int(l_args.strict_extra)}"
            )

    return 0 if not l_failed else 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as l_exc:
        print(json.dumps({"status": "ERROR", "detail": str(l_exc)}, ensure_ascii=False), file=sys.stderr)
        sys.exit(2)
