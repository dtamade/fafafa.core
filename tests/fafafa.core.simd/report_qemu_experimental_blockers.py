#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable


@dataclass
class Blocker:
    platform: str
    status: str
    category: str
    detail: str
    log_path: str


def parse_summary_rows(a_summary: Path) -> tuple[dict[str, str], list[dict[str, str]]]:
    header: dict[str, str] = {}
    rows: list[dict[str, str]] = []
    for raw_line in a_summary.read_text(encoding='utf-8', errors='ignore').splitlines():
        line = raw_line.rstrip()
        if line.startswith('- '):
            if ': ' in line:
                key, value = line[2:].split(': ', 1)
                header[key.strip().lower().replace(' ', '_')] = value.strip()
            continue
        if not line.startswith('|') or line.startswith('|---') or line.startswith('| Platform |'):
            continue
        cells = [part.strip() for part in line.strip('|').split('|')]
        if len(cells) < 3:
            continue
        rows.append({
            'platform': cells[0],
            'status': cells[1],
            'log': cells[2].strip('`'),
        })
    return header, rows


def extract_detail(a_log_path: Path) -> tuple[str, str]:
    if not a_log_path.is_file():
        return 'missing_log', f'missing log: {a_log_path}'

    text = a_log_path.read_text(encoding='utf-8', errors='ignore')
    tail_lines = text.splitlines()[-80:]
    tail = '\n'.join(tail_lines)
    patterns: list[tuple[str, str]] = [
        ('rvv_opcode_unsupported', r'Unrecognized opcode|Assembler syntax error'),
        ('docker_network', r'failed to resolve source metadata|DeadlineExceeded|i/o timeout'),
        ('test_failure', r'\[TEST\] FAILED|Number of failures:|Number of errors:'),
        ('build_failure', r'\[BUILD\] FAILED|Fatal: Compilation aborted|returned an error exitcode'),
    ]
    for category, pattern in patterns:
        match = re.search(pattern, tail, re.IGNORECASE)
        if match:
            for line in reversed(tail_lines):
                if re.search(pattern, line, re.IGNORECASE):
                    return category, line.strip()
            return category, match.group(0)

    for line in reversed(tail_lines):
        if line.strip().startswith('[WARN]') or line.strip().startswith('[ERROR]'):
            return 'warning_or_error', line.strip()
    return 'unknown', 'no specific blocker signature matched'


def iter_qemu_dirs(a_logs_root: Path) -> Iterable[Path]:
    yield from sorted(a_logs_root.glob('qemu-multiarch-*'))


def pick_latest_experimental_dir(a_logs_root: Path) -> Path | None:
    latest: Path | None = None
    for directory in iter_qemu_dirs(a_logs_root):
        summary = directory / 'summary.md'
        if not summary.is_file():
            continue
        text = summary.read_text(encoding='utf-8', errors='ignore')
        if 'scenario: nonx86-experimental-asm' in text or 'requested-scenario: nonx86-experimental-asm' in text:
            latest = directory
    return latest


def main() -> int:
    parser = argparse.ArgumentParser(description='Report latest QEMU experimental blockers')
    parser.add_argument('--root', default=str(Path(__file__).resolve().parent))
    parser.add_argument('--latest', action='store_true')
    parser.add_argument('--dir', default='')
    args = parser.parse_args()

    root = Path(args.root).resolve()
    logs_root = root / 'logs'
    selected_dir: Path | None
    if args.dir:
        selected_dir = Path(args.dir).resolve()
    else:
        selected_dir = pick_latest_experimental_dir(logs_root)

    if selected_dir is None:
        print('[QEMU-EXPERIMENTAL-REPORT] Missing experimental summary directory', file=sys.stderr)
        return 2

    summary = selected_dir / 'summary.md'
    if not summary.is_file():
        print(f'[QEMU-EXPERIMENTAL-REPORT] Missing summary: {summary}', file=sys.stderr)
        return 2

    header, rows = parse_summary_rows(summary)
    blockers: list[Blocker] = []
    for row in rows:
        if row['status'].upper() != 'FAIL':
            continue
        category, detail = extract_detail(Path(row['log']))
        blockers.append(Blocker(
            platform=row['platform'],
            status=row['status'],
            category=category,
            detail=detail,
            log_path=row['log'],
        ))

    payload = {
        'selected_dir': str(selected_dir),
        'summary': str(summary),
        'scenario': header.get('scenario', ''),
        'requested_scenario': header.get('requested-scenario', ''),
        'blocker_count': len(blockers),
        'blockers': [asdict(item) for item in blockers],
    }

    json_out = logs_root / 'qemu_experimental_blockers.latest.json'
    md_out = logs_root / 'qemu_experimental_blockers.latest.md'
    json_out.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

    md_lines = [
        '# QEMU Experimental Blockers (latest)',
        '',
        f'- Directory: {selected_dir}',
        f'- Summary: {summary}',
        f'- Scenario: {payload["scenario"] or "<unknown>"}',
        f'- Requested Scenario: {payload["requested_scenario"] or "<unknown>"}',
        f'- Blockers: {len(blockers)}',
        '',
    ]
    if blockers:
        md_lines.extend(['| Platform | Category | Detail | Log |', '|---|---|---|---|'])
        for blocker in blockers:
            md_lines.append(
                f'| {blocker.platform} | {blocker.category} | {blocker.detail.replace("|", "/")} | `{blocker.log_path}` |'
            )
    else:
        md_lines.append('No blockers in the latest experimental QEMU run.')
    md_out.write_text('\n'.join(md_lines) + '\n', encoding='utf-8')

    print(
        f'[QEMU-EXPERIMENTAL-REPORT] latest={selected_dir} '
        f'scenario={payload["scenario"] or "<unknown>"} blockers={len(blockers)}'
    )
    if blockers:
        for blocker in blockers:
            print(
                f'[QEMU-EXPERIMENTAL-REPORT] blocker platform={blocker.platform} '
                f'category={blocker.category} detail={blocker.detail}'
            )
    print(f'[QEMU-EXPERIMENTAL-REPORT] JSON: {json_out}')
    print(f'[QEMU-EXPERIMENTAL-REPORT] MD: {md_out}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
