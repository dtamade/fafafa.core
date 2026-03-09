#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SRC_DIR = REPO_ROOT / 'src'
PUBLIC_ENTRY_FILES = [
    SRC_DIR / 'fafafa.core.simd.pas',
    SRC_DIR / 'fafafa.core.simd.api.pas',
    SRC_DIR / 'fafafa.core.simd.direct.pas',
    SRC_DIR / 'fafafa.core.simd.dispatch.pas',
]
FORBIDDEN_PATTERNS = [
    re.compile(r'intrinsics\.experimental', re.IGNORECASE),
]


def scan_file(a_path: Path) -> list[str]:
    l_hits: list[str] = []
    l_text = a_path.read_text(encoding='utf-8', errors='ignore').splitlines()
    for l_lineno, l_line in enumerate(l_text, start=1):
        for l_pattern in FORBIDDEN_PATTERNS:
            if l_pattern.search(l_line):
                l_hits.append(f'{a_path.relative_to(REPO_ROOT)}:{l_lineno}: {l_line.strip()}')
    return l_hits


def main() -> int:
    l_missing = [str(l_path.relative_to(REPO_ROOT)) for l_path in PUBLIC_ENTRY_FILES if not l_path.is_file()]
    if l_missing:
        print('[EXPERIMENTAL] Missing public entry files:')
        for l_item in l_missing:
            print(f'  - {l_item}')
        return 2

    l_hits: list[str] = []
    for l_path in PUBLIC_ENTRY_FILES:
        l_hits.extend(scan_file(l_path))

    if l_hits:
        print('[EXPERIMENTAL] FAILED: default public entry chain references experimental intrinsics:')
        for l_hit in l_hits:
            print(f'  - {l_hit}')
        return 1

    print('[EXPERIMENTAL] OK: default public entry chain keeps experimental intrinsics isolated')
    return 0


if __name__ == '__main__':
    sys.exit(main())
