#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path


@dataclass
class Blocker:
    platform: str
    category: str
    detail: str
    log_path: str


def parse_summary_rows(a_summary: Path) -> tuple[dict[str, str], list[dict[str, str]]]:
    header: dict[str, str] = {}
    rows: list[dict[str, str]] = []
    for raw_line in a_summary.read_text(encoding='utf-8', errors='ignore').splitlines():
        line = raw_line.rstrip()
        if line.startswith('- ') and ': ' in line:
            key, value = line[2:].split(': ', 1)
            header[key.strip().lower().replace(' ', '_')] = value.strip()
            continue
        if not line.startswith('|') or line.startswith('|---') or line.startswith('| Platform |'):
            continue
        cells = [part.strip() for part in line.strip('|').split('|')]
        if len(cells) >= 3:
            rows.append({'platform': cells[0], 'status': cells[1], 'log': cells[2].strip('`')})
    return header, rows


def extract_detail(a_log_path: Path) -> tuple[str, str]:
    if not a_log_path.is_file():
        return 'missing_log', f'missing log: {a_log_path}'
    tail_lines = a_log_path.read_text(encoding='utf-8', errors='ignore').splitlines()[-80:]
    tail = '\n'.join(tail_lines)
    patterns: list[tuple[str, str]] = [
        ('rvv_opcode_unsupported', r'Unrecognized opcode|Assembler syntax error'),
        ('docker_network', r'failed to resolve source metadata|DeadlineExceeded|i/o timeout'),
        ('test_failure', r'\[TEST\] FAILED|Number of failures:|Number of errors:'),
        ('build_failure', r'\[BUILD\] FAILED|Fatal: Compilation aborted|returned an error exitcode'),
    ]
    for category, pattern in patterns:
        if re.search(pattern, tail, re.IGNORECASE):
            for line in reversed(tail_lines):
                if re.search(pattern, line, re.IGNORECASE):
                    return category, line.strip()
            return category, pattern
    return 'unknown', 'no specific blocker signature matched'


def pick_latest_experimental_dir(a_logs_root: Path) -> Path | None:
    latest: Path | None = None
    for directory in sorted(a_logs_root.glob('qemu-multiarch-*')):
        summary = directory / 'summary.md'
        if not summary.is_file():
            continue
        text = summary.read_text(encoding='utf-8', errors='ignore')
        if 'scenario: nonx86-experimental-asm' in text or 'requested-scenario: nonx86-experimental-asm' in text:
            latest = directory
    return latest


def parse_allowed(a_raw: str) -> set[tuple[str, str]]:
    result: set[tuple[str, str]] = set()
    for item in a_raw.split(','):
        item = item.strip()
        if not item or ':' not in item:
            continue
        platform, category = item.split(':', 1)
        result.add((platform.strip(), category.strip()))
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description='Check latest QEMU experimental blockers against baseline')
    parser.add_argument('--root', default=str(Path(__file__).resolve().parent))
    parser.add_argument('--latest', action='store_true')
    parser.add_argument('--dir', default='')
    args = parser.parse_args()

    root = Path(args.root).resolve()
    logs_root = root / 'logs'
    selected_dir = Path(args.dir).resolve() if args.dir else pick_latest_experimental_dir(logs_root)
    if selected_dir is None:
        print('[QEMU-EXPERIMENTAL-BASELINE] Missing experimental summary directory', file=sys.stderr)
        return 2

    summary = selected_dir / 'summary.md'
    header, rows = parse_summary_rows(summary)
    actual: list[Blocker] = []
    for row in rows:
        if row['status'].upper() != 'FAIL':
            continue
        category, detail = extract_detail(Path(row['log']))
        actual.append(Blocker(row['platform'], category, detail, row['log']))

    allowed_raw = os.environ.get('SIMD_QEMU_EXPERIMENTAL_ALLOWED_BLOCKERS', 'linux/riscv64:rvv_opcode_unsupported')
    allowed = parse_allowed(allowed_raw)
    unexpected = [item for item in actual if (item.platform, item.category) not in allowed]

    payload = {
        'selected_dir': str(selected_dir),
        'summary': str(summary),
        'scenario': header.get('scenario', ''),
        'allowed': sorted(f'{platform}:{category}' for platform, category in allowed),
        'actual': [asdict(item) for item in actual],
        'unexpected': [asdict(item) for item in unexpected],
        'status': 'PASS' if not unexpected else 'FAIL',
    }

    json_out = logs_root / 'qemu_experimental_baseline.latest.json'
    md_out = logs_root / 'qemu_experimental_baseline.latest.md'
    json_out.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

    md_lines = [
        '# QEMU Experimental Failure Baseline (latest)',
        '',
        f'- Directory: {selected_dir}',
        f'- Summary: {summary}',
        f'- Scenario: {payload["scenario"] or "<unknown>"}',
        f'- Allowed: {", ".join(payload["allowed"]) if payload["allowed"] else "<none>"}',
        f'- Status: {payload["status"]}',
        '',
    ]
    if actual:
        md_lines.extend(['| Platform | Category | Detail | Log | Allowed |', '|---|---|---|---|---|'])
        for item in actual:
            allowed_flag = 'yes' if (item.platform, item.category) in allowed else 'no'
            md_lines.append(
                f'| {item.platform} | {item.category} | {item.detail.replace("|", "/")} | `{item.log_path}` | {allowed_flag} |'
            )
    else:
        md_lines.append('No blockers in the latest experimental QEMU run.')
    md_out.write_text('\n'.join(md_lines) + '\n', encoding='utf-8')

    print(
        f'[QEMU-EXPERIMENTAL-BASELINE] latest={selected_dir} '
        f'scenario={payload["scenario"] or "<unknown>"} '
        f'actual={len(actual)} unexpected={len(unexpected)}'
    )
    print(f'[QEMU-EXPERIMENTAL-BASELINE] JSON: {json_out}')
    print(f'[QEMU-EXPERIMENTAL-BASELINE] MD: {md_out}')
    return 0 if not unexpected else 1


if __name__ == '__main__':
    sys.exit(main())
