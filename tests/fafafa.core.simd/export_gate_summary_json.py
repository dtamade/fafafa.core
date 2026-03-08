#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import List, Dict


def parse_rows(a_path: Path) -> List[Dict[str, str]]:
    l_rows: List[Dict[str, str]] = []
    for l_raw_line in a_path.read_text(encoding='utf-8', errors='ignore').splitlines():
        l_line = l_raw_line.strip()
        if not l_line.startswith('|'):
            continue
        if l_line.startswith('| Time |') or l_line.startswith('|---'):
            continue
        l_cells = [l_part.strip() for l_part in l_line.strip('|').split('|')]
        if len(l_cells) < 7:
            continue
        l_rows.append(
            {
                'time': l_cells[0],
                'step': l_cells[1],
                'status': l_cells[2],
                'duration_ms': l_cells[3],
                'event': l_cells[4],
                'detail': l_cells[5],
                'artifacts': l_cells[6],
            }
        )
    return l_rows


def filter_rows(a_rows: List[Dict[str, str]], a_filter: str) -> List[Dict[str, str]]:
    l_filter = a_filter.upper()
    if l_filter == 'ALL':
        return a_rows
    if l_filter == 'FAIL':
        return [l_row for l_row in a_rows if l_row.get('status') == 'FAIL']
    if l_filter == 'SLOW':
        return [
            l_row
            for l_row in a_rows
            if l_row.get('event') in {'SLOW_WARN', 'SLOW_CRIT', 'SLOW_FAIL'}
        ]
    return a_rows


def main() -> int:
    l_parser = argparse.ArgumentParser(description='Export SIMD gate summary markdown as JSON')
    l_parser.add_argument('--input', required=True, help='Path to gate_summary.md')
    l_parser.add_argument('--output', required=True, help='Path to output JSON file')
    l_parser.add_argument('--filter', default='ALL', help='ALL|FAIL|SLOW')
    l_parser.add_argument('--warn-ms', type=int, default=20000, help='Warn threshold')
    l_parser.add_argument('--fail-ms', type=int, default=120000, help='Fail threshold')
    l_args = l_parser.parse_args()

    l_input = Path(l_args.input)
    l_output = Path(l_args.output)
    if not l_input.is_file():
        raise SystemExit(f'missing input: {l_input}')

    l_rows = parse_rows(l_input)
    l_filtered = filter_rows(l_rows, l_args.filter)
    l_payload = {
        'input': str(l_input),
        'filter': l_args.filter.upper(),
        'warn_ms': l_args.warn_ms,
        'fail_ms': l_args.fail_ms,
        'total_rows': len(l_rows),
        'matched_rows': len(l_filtered),
        'rows': l_filtered,
    }

    l_output.parent.mkdir(parents=True, exist_ok=True)
    l_output.write_text(json.dumps(l_payload, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
