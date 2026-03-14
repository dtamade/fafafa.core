#!/usr/bin/env python3
"""Validate SIMD perf-smoke benchmark output."""

from __future__ import annotations

import argparse
from pathlib import Path


ZERO_SPEEDUP_ROWS = {
    "MemEqual",
    "MemFindByte",
    "SumBytes",
    "CountByte",
    "BitsetPopCount",
    "VecF32x4Add",
    "VecF32x4Mul",
    "VecF32x4Div",
    "VecI32x4Add",
    "VecF32x4Dot",
    "VecF32x8DotApi",
    "VecF32x8DotBatch",
    "ArrSumF32",
    "ArrSumF64",
    "ArrMinMaxF32",
    "ArrMinMaxF64",
    "ArrVarF32",
    "ArrVarF64",
    "ArrKahanF32",
    "ArrKahanF64",
}

MEMORY_ROWS = {
    "MemEqual",
    "MemFindByte",
    "SumBytes",
    "CountByte",
    "BitsetPopCount",
}

PUBLIC_ABI_GROUPS = [
    ("HotMemEqPubCache", "HotMemEqPubGet", "HotMemEqDispGet"),
    ("HotSumPubCache", "HotSumPubGet", "HotSumDispGet"),
]

CACHE_GETTER_TOLERANCE = 0.03
GETTER_DISPATCH_TOLERANCE = 0.03


def parse_speedup_rows(text: str) -> dict[str, float]:
    rows: dict[str, float] = {}
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        parts = line.split()
        if len(parts) < 2:
            continue
        name = parts[0]
        speedup = parts[-1]
        if not speedup.endswith("x"):
            continue
        try:
            rows[name] = float(speedup[:-1])
        except ValueError:
            continue
    return rows


def main() -> int:
    parser = argparse.ArgumentParser(description="Check SIMD perf-smoke benchmark log")
    parser.add_argument("log_file")
    args = parser.parse_args()

    log_path = Path(args.log_file)
    if not log_path.exists():
        print(f"[PERF] FAILED: benchmark log not found: {log_path}")
        return 2

    text = log_path.read_text(encoding="utf-8", errors="ignore")
    if "=== SIMD Benchmark (" not in text:
        print(f"[PERF] FAILED: benchmark header not found in {log_path}")
        return 1

    if "/Scalar)" in text:
        print("[PERF] SKIP (active backend is Scalar)")
        return 0

    rows = parse_speedup_rows(text)

    zero_speedups = [name for name in sorted(ZERO_SPEEDUP_ROWS) if rows.get(name) == 0.0]
    if zero_speedups:
        print("[PERF] FAILED: zero speedup rows detected")
        for name in zero_speedups:
            print(f"  - {name}=0.00x")
        return 1

    memory_regressions = [name for name in sorted(MEMORY_ROWS) if name in rows and rows[name] < 1.0]
    if memory_regressions:
        print("[PERF] FAILED: memory-facade speedup < 1.00x")
        for name in memory_regressions:
            print(f"  - {name}={rows[name]:.2f}x")
        return 1

    missing_public_abi = []
    ordering_failures = []
    for cache_name, getter_name, dispatch_name in PUBLIC_ABI_GROUPS:
        for name in (cache_name, getter_name, dispatch_name):
            if name not in rows:
                missing_public_abi.append(name)
        if any(name not in rows for name in (cache_name, getter_name, dispatch_name)):
            continue

        cache_speedup = rows[cache_name]
        getter_speedup = rows[getter_name]
        dispatch_speedup = rows[dispatch_name]

        if cache_speedup + CACHE_GETTER_TOLERANCE < getter_speedup:
            ordering_failures.append(
                f"{cache_name}={cache_speedup:.2f}x slower than {getter_name}={getter_speedup:.2f}x"
            )
        if getter_speedup <= dispatch_speedup + GETTER_DISPATCH_TOLERANCE:
            ordering_failures.append(
                f"{getter_name}={getter_speedup:.2f}x not meaningfully above {dispatch_name}={dispatch_speedup:.2f}x"
            )

    if missing_public_abi:
        print("[PERF] FAILED: public ABI hot-path benchmark rows missing")
        for name in sorted(set(missing_public_abi)):
            print(f"  - {name}")
        return 1

    if ordering_failures:
        print("[PERF] FAILED: public ABI hot-path ordering regressed")
        for item in ordering_failures:
            print(f"  - {item}")
        return 1

    print("[PERF] OK (non-scalar backend benchmark looks healthy; public ABI hot-path ordering preserved)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
