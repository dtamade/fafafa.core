#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path
from typing import List, Tuple


Row = Tuple[str, str, str, int, str, str, str]


def rows_for_scenario(a_scenario: str, a_warn_ms: int, a_fail_ms: int) -> List[Row]:
    l_scenario = a_scenario.lower()
    if l_scenario == 'pass':
        return [
            ('2026-03-08 08:00:00', 'build-check', 'PASS', 5321, 'NORMAL', 'build + check passed', '-'),
            ('2026-03-08 08:00:12', 'dispatch-api', 'PASS', 8912, 'NORMAL', 'dispatch suites passed', '-'),
            ('2026-03-08 08:00:21', 'gate', 'PASS', 14233, 'NORMAL', 'all steps passed', '-'),
        ]
    if l_scenario == 'fail':
        return [
            ('2026-03-08 08:00:00', 'build-check', 'PASS', 6321, 'NORMAL', 'build + check passed', '-'),
            ('2026-03-08 08:00:18', 'evidence-verify', 'FAIL', a_fail_ms + 1, 'FAILED', 'verify-win-evidence failed', 'logs/windows_b07_gate.log'),
            ('2026-03-08 08:00:25', 'gate', 'FAIL', a_fail_ms + 20, 'FAILED', 'failed-step=evidence-verify', '-'),
        ]
    if l_scenario == 'slow':
        return [
            ('2026-03-08 08:00:00', 'build-check', 'PASS', 5120, 'NORMAL', 'build + check passed', '-'),
            ('2026-03-08 08:00:40', 'concurrent-repeat', 'PASS', a_warn_ms + 500, 'SLOW_WARN', 'repeat suite slower than warn threshold', 'logs/repeat.txt'),
            ('2026-03-08 08:02:45', 'gate', 'PASS', a_fail_ms + 1000, 'SLOW_CRIT', 'all steps passed', '-'),
        ]
    return [
        ('2026-03-08 08:00:00', 'build-check', 'PASS', 6420, 'NORMAL', 'build + check passed', '-'),
        ('2026-03-08 08:00:35', 'coverage', 'PASS', a_warn_ms + 250, 'SLOW_WARN', 'coverage checks passed', 'logs/coverage.json'),
        ('2026-03-08 08:01:12', 'evidence-verify', 'FAIL', 1834, 'FAILED', 'verify-win-evidence failed', 'logs/windows_b07_gate.log'),
        ('2026-03-08 08:02:45', 'gate', 'FAIL', a_fail_ms + 50, 'FAILED', 'failed-step=evidence-verify', '-'),
    ]


def main() -> int:
    l_parser = argparse.ArgumentParser(description='Generate SIMD gate summary sample markdown')
    l_parser.add_argument('--scenario', default='mixed', help='mixed|pass|fail|slow')
    l_parser.add_argument('--warn-ms', type=int, default=20000)
    l_parser.add_argument('--fail-ms', type=int, default=120000)
    l_parser.add_argument('--output', required=True)
    l_args = l_parser.parse_args()

    l_output = Path(l_args.output)
    l_output.parent.mkdir(parents=True, exist_ok=True)

    l_lines = [
        '# SIMD Gate Summary',
        '',
        '| Time | Step | Status | DurationMs | Event | Detail | Artifacts |',
        '|---|---|---|---|---|---|---|',
    ]
    for l_row in rows_for_scenario(l_args.scenario, l_args.warn_ms, l_args.fail_ms):
        l_lines.append('| ' + ' | '.join(str(l_item) for l_item in l_row) + ' |')

    l_output.write_text('\n'.join(l_lines) + '\n', encoding='utf-8')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
