#!/usr/bin/env python3
"""Verify the machine-readable SIMD gate summary contract."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


DEFAULT_REQUIRED_STEPS = [
    "build-check",
    "interface-completeness",
    "adapter-sync-pascal",
    "adapter-sync",
    "wiring-sync",
    "simd-list-suites",
    "simd-avx2-fallback",
    "cross-backend-parity",
    "cpuinfo-portable",
    "cpuinfo-x86",
    "run-all-chain",
    "experimental-intrinsics",
    "coverage",
]


def load_rows(summary_json: Path) -> list[dict[str, str]]:
    payload = json.loads(summary_json.read_text(encoding="utf-8"))
    rows = payload.get("rows", [])
    if not isinstance(rows, list):
      raise ValueError("rows is not a list")
    normalized: list[dict[str, str]] = []
    for row in rows:
        if isinstance(row, dict):
            normalized.append({str(k): str(v) for k, v in row.items()})
    return normalized


def latest_status(rows: list[dict[str, str]], step: str) -> tuple[str, str]:
    for row in reversed(rows):
        if row.get("step") == step:
            return row.get("status", ""), row.get("detail", "")
    return "", ""


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify SIMD gate summary JSON")
    parser.add_argument("--summary-json", required=True, help="Path to gate_summary.json")
    parser.add_argument(
        "--require-step",
        action="append",
        dest="required_steps",
        default=[],
        help="Additional required step that must be PASS",
    )
    args = parser.parse_args()

    summary_json = Path(args.summary_json)
    if not summary_json.is_file():
        print(f"[GATE-SUMMARY-VERIFY] Missing summary json: {summary_json}")
        return 2

    try:
        rows = load_rows(summary_json)
    except Exception as exc:  # noqa: BLE001
        print(f"[GATE-SUMMARY-VERIFY] Invalid summary json: {summary_json} ({exc})")
        return 2

    if not rows:
        print(f"[GATE-SUMMARY-VERIFY] No rows in summary json: {summary_json}")
        return 2

    required_steps = list(DEFAULT_REQUIRED_STEPS)
    for step in args.required_steps:
        if step not in required_steps:
            required_steps.append(step)

    failures: list[str] = []

    gate_status, gate_detail = latest_status(rows, "gate")
    if gate_status != "PASS":
        failures.append(f"gate={gate_status or 'missing'} detail={gate_detail or 'n/a'}")

    for step in required_steps:
        status, detail = latest_status(rows, step)
        if status != "PASS":
            failures.append(f"{step}={status or 'missing'} detail={detail or 'n/a'}")

    if failures:
        print(f"[GATE-SUMMARY-VERIFY] FAIL: {summary_json}")
        for item in failures:
            print(f"  - {item}")
        return 1

    print(f"[GATE-SUMMARY-VERIFY] OK: {summary_json}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
