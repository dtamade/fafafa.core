#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys
from pathlib import Path


def extract_detect_body(a_text: str) -> str:
    a_signature = 'function DetectX86Features: TX86Features;'
    a_next = 'procedure DetectX86VendorAndModel'

    try:
        a_start = a_text.rindex(a_signature)
    except ValueError as a_exc:
        raise RuntimeError(f'missing signature: {a_signature}') from a_exc

    try:
        a_end = a_text.index(a_next, a_start)
    except ValueError as a_exc:
        raise RuntimeError(f'missing boundary after DetectX86Features: {a_next}') from a_exc

    return a_text[a_start:a_end]


def inspect_detector(a_path: Path) -> dict[str, object]:
    a_text = a_path.read_text(encoding='utf-8')
    a_body = extract_detect_body(a_text)
    a_delegate = 'Result := X86FeaturesFromCPUID(' in a_body
    a_manual_assigns = a_body.count('Result.Has')

    return {
        'path': a_path,
        'delegate': a_delegate,
        'manual_assigns': a_manual_assigns,
    }


def main() -> int:
    a_parser = argparse.ArgumentParser(
        description='Check x86 cpuinfo platform detectors delegate feature assembly to X86FeaturesFromCPUID.'
    )
    a_parser.add_argument('--summary-line', action='store_true')
    a_args = a_parser.parse_args()

    a_repo_root = Path(__file__).resolve().parents[2]
    a_files = [
        a_repo_root / 'src' / 'fafafa.core.simd.cpuinfo.x86.i386.pas',
        a_repo_root / 'src' / 'fafafa.core.simd.cpuinfo.x86.x86_64.pas',
    ]

    a_results = [inspect_detector(a_path) for a_path in a_files]
    a_issues: list[str] = []

    for a_result in a_results:
        a_name = a_result['path'].name
        if not a_result['delegate']:
            a_issues.append(f'{a_name}: missing X86FeaturesFromCPUID delegation')
        if a_result['manual_assigns'] != 0:
            a_issues.append(
                f"{a_name}: DetectX86Features still has {a_result['manual_assigns']} direct Result.Has assignments"
            )

    print('[CPUINFO-X86-SYNC] platform detector delegation')
    for a_result in a_results:
        print(f"  - {a_result['path'].name}: delegate={int(a_result['delegate'])} manual_assigns={a_result['manual_assigns']}")

    if a_issues:
        print('[CPUINFO-X86-SYNC] FAIL')
        for a_issue in a_issues:
            print(f'  - {a_issue}')
    else:
        print('[CPUINFO-X86-SYNC] OK')

    print(
        'CPUINFO_X86_SYNC_SUMMARY '
        f"files={len(a_results)} delegate_ok={sum(1 for a_result in a_results if a_result['delegate'])} "
        f"manual_assigns={sum(int(a_result['manual_assigns']) for a_result in a_results)} issues={len(a_issues)}"
    )

    if a_issues:
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
