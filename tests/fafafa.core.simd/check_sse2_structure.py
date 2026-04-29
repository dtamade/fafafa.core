#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


INCLUDE_RE = re.compile(r'^\s*\{\$I\s+([^}]+)\}\s*$', re.IGNORECASE | re.MULTILINE)
REGISTER_HEADER_RE = re.compile(r'^\s*procedure\s+RegisterSSE2Backend\s*;', re.IGNORECASE | re.MULTILINE)
SYMBOL_HEADER_TEMPLATE = r'^\s*(?:function|procedure)\s+{name}\b'


def configure_stdio() -> None:
    for stream_name in ('stdout', 'stderr'):
        stream = getattr(sys, stream_name, None)
        if stream is not None and hasattr(stream, 'reconfigure'):
            stream.reconfigure(errors='backslashreplace')



def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description='Check SSE2 backend structural contracts for register/include layout.'
    )
    parser.add_argument('--json', action='store_true', help='Print machine-readable JSON output.')
    parser.add_argument(
        '--summary-line',
        action='store_true',
        help='Print a single-line summary for log scraping.',
    )
    return parser.parse_args()



def collect_include_names(a_text: str) -> list[str]:
    return [match.group(1).strip().strip("'\"") for match in INCLUDE_RE.finditer(a_text)]



def main() -> int:
    configure_stdio()
    args = parse_args()

    root = Path(__file__).resolve().parents[2]
    src_dir = root / 'src'
    root_unit_path = src_dir / 'fafafa.core.simd.sse2.pas'
    register_inc_path = src_dir / 'fafafa.core.simd.sse2.register.inc'
    wide_inc_path = src_dir / 'fafafa.core.simd.sse2.wide_emulation.inc'
    select_inc_path = src_dir / 'fafafa.core.simd.sse2.select.inc'

    failures: list[str] = []
    duplicate_leaf_names: list[str] = []
    duplicate_leaf_records: list[dict[str, object]] = []
    root_symbol_counts: dict[str, int] = {}
    wide_symbol_counts: dict[str, int] = {}
    select_symbol_counts: dict[str, int] = {}
    wide_section_counts: dict[str, int] = {}

    if not root_unit_path.exists():
        failures.append(f'missing root unit: {root_unit_path.name}')
        root_unit_text = ''
    else:
        root_unit_text = root_unit_path.read_text(encoding='utf-8', errors='replace')

    register_exists = register_inc_path.exists()
    register_text = register_inc_path.read_text(encoding='utf-8', errors='replace') if register_exists else ''
    if not register_exists:
        failures.append(f'missing register include: {register_inc_path.name}')

    select_exists = select_inc_path.exists()
    select_text = select_inc_path.read_text(encoding='utf-8', errors='replace') if select_exists else ''
    if not select_exists:
        failures.append(f'missing select include: {select_inc_path.name}')

    if not wide_inc_path.exists():
        failures.append(f'missing wide include: {wide_inc_path.name}')
        wide_text = ''
        wide_include_names: list[str] = []
    else:
        wide_text = wide_inc_path.read_text(encoding='utf-8', errors='replace')
        wide_include_names = collect_include_names(wide_text)

    root_include_names = collect_include_names(root_unit_text)
    root_include_count = sum(
        1 for item in root_include_names
        if item.lower() == register_inc_path.name.lower()
    )
    if root_include_count != 1:
        failures.append(
            f'root unit must include {register_inc_path.name} exactly once (found {root_include_count})'
        )

    root_wide_include_count = sum(
        1 for item in root_include_names
        if item.lower() == wide_inc_path.name.lower()
    )
    if root_wide_include_count != 1:
        failures.append(
            f'root unit must include {wide_inc_path.name} exactly once (found {root_wide_include_count})'
        )

    root_select_include_count = sum(
        1 for item in root_include_names
        if item.lower() == select_inc_path.name.lower()
    )
    if root_select_include_count != 1:
        failures.append(
            f'root unit must include {select_inc_path.name} exactly once (found {root_select_include_count})'
        )

    root_register_header_count = len(REGISTER_HEADER_RE.findall(root_unit_text))
    if root_register_header_count != 1:
        failures.append(
            'root unit should keep only the interface declaration for RegisterSSE2Backend '
            f'(found {root_register_header_count} headers)'
        )

    register_header_count = len(REGISTER_HEADER_RE.findall(register_text)) if register_exists else 0
    if register_exists and register_header_count != 1:
        failures.append(
            f'{register_inc_path.name} must define RegisterSSE2Backend exactly once '
            f'(found {register_header_count})'
        )

    if select_exists and not select_text.strip():
        failures.append(f'{select_inc_path.name} must not be empty')

    wide_self_include_count = sum(
        1 for item in wide_include_names
        if item.lower() == wide_inc_path.name.lower()
    )
    if wide_self_include_count != 0:
        failures.append(
            f'{wide_inc_path.name} must not self-include (found {wide_self_include_count})'
        )

    leaf_occurrences: dict[str, list[int]] = {}
    for line_no, line in enumerate(wide_text.splitlines(), 1):
        match = re.match(r'^\s*\{\$I\s+([^}]+)\}\s*$', line, re.IGNORECASE)
        if match is None:
            continue
        include_name = match.group(1).strip().strip("'\"")
        if not include_name.lower().startswith('fafafa.core.simd.sse2.'):
            continue
        if include_name.lower() == wide_inc_path.name.lower():
            continue
        leaf_occurrences.setdefault(include_name, []).append(line_no)

    for include_name, line_numbers in sorted(leaf_occurrences.items()):
        if len(line_numbers) > 1:
            duplicate_leaf_names.append(include_name)
            duplicate_leaf_records.append({'include': include_name, 'lines': line_numbers})
    if duplicate_leaf_names:
        failures.append(
            f'{wide_inc_path.name} has duplicate leaf includes: {", ".join(duplicate_leaf_names)}'
        )

    representative_wide_symbols = [
        'SSE2AddF32x16',
        'SSE2AddF64x8',
        'SSE2AddI32x16',
        'SSE2AddI64x4',
        'SSE2AddU32x8',
        'SSE2AddU64x4',
        'SSE2AddI64x8',
        'MemDiffRange_SSE2',
        'Utf8Validate_SSE2',
    ]
    for symbol_name in representative_wide_symbols:
        pattern = re.compile(SYMBOL_HEADER_TEMPLATE.format(name=re.escape(symbol_name)), re.IGNORECASE | re.MULTILINE)
        root_symbol_counts[symbol_name] = len(pattern.findall(root_unit_text))
        wide_symbol_counts[symbol_name] = len(pattern.findall(wide_text))
        if root_symbol_counts[symbol_name] != 1:
            failures.append(
                f'root unit should expose exactly one declaration for {symbol_name} '
                f'(found {root_symbol_counts[symbol_name]})'
            )
        if wide_symbol_counts[symbol_name] != 1:
            failures.append(
                f'{wide_inc_path.name} should provide exactly one implementation header for {symbol_name} '
                f'(found {wide_symbol_counts[symbol_name]})'
            )

    select_symbol_pattern = re.compile(
        SYMBOL_HEADER_TEMPLATE.format(name=re.escape('SSE2SelectF64x2')),
        re.IGNORECASE | re.MULTILINE,
    )
    select_symbol_counts['SSE2SelectF64x2'] = len(select_symbol_pattern.findall(select_text))
    if select_symbol_counts['SSE2SelectF64x2'] != 1:
        failures.append(
            f'{select_inc_path.name} should define SSE2SelectF64x2 exactly once '
            f'(found {select_symbol_counts["SSE2SelectF64x2"]})'
        )
    if len(select_symbol_pattern.findall(wide_text)) != 0:
        failures.append(f'{wide_inc_path.name} must not duplicate SSE2SelectF64x2')

    forbidden_wide_markers = [
        '// === SSE2 Arithmetic Operations ===',
        '// === SSE2 Comparison Operations ===',
        '// === SSE2 Math Functions ===',
        '// === SSE2 Reduction Operations ===',
        '// === SSE2 Memory Operations ===',
        '// === SSE2 Utility Operations ===',
    ]
    for marker in forbidden_wide_markers:
        count = wide_text.count(marker)
        wide_section_counts[marker] = count
        if count != 0:
            failures.append(f'{wide_inc_path.name} must not contain stale duplicated marker: {marker}')

    expected_wide_sections = [
        '// === F32x16 操作 (16×Float32) - 使用 2×F32x8 ===',
        '// === F64x8 操作 (8×Float64) - 使用 2×F64x4 ===',
        '// === I32x16 操作 (16×Int32) - 使用 2×I32x8 ===',
    ]
    for marker in expected_wide_sections:
        count = wide_text.count(marker)
        wide_section_counts[marker] = count
        if count != 1:
            failures.append(
                f'{wide_inc_path.name} should contain section marker exactly once: {marker} '
                f'(found {count})'
            )

    payload = {
        'root_unit': root_unit_path.name,
        'register_include': register_inc_path.name,
        'wide_include': wide_inc_path.name,
        'select_include': select_inc_path.name,
        'register_include_exists': register_exists,
        'root_include_count': root_include_count,
        'root_wide_include_count': root_wide_include_count,
        'root_select_include_count': root_select_include_count,
        'root_register_header_count': root_register_header_count,
        'register_header_count': register_header_count,
        'select_include_exists': select_exists,
        'wide_self_include_count': wide_self_include_count,
        'duplicate_leaf_names': duplicate_leaf_names,
        'duplicate_leaf_records': duplicate_leaf_records,
        'root_symbol_counts': root_symbol_counts,
        'wide_symbol_counts': wide_symbol_counts,
        'select_symbol_counts': select_symbol_counts,
        'wide_section_counts': wide_section_counts,
        'failure_count': len(failures),
        'failures': failures,
        'status': 'ok' if not failures else 'fail',
    }

    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
        return 0 if not failures else 1

    print('[SSE2-STRUCTURE] SSE2 register/include structural contract')
    print(f'  - register_include_exists: {register_exists}')
    print(f'  - root_include_count:      {root_include_count}')
    print(f'  - root_wide_include_count: {root_wide_include_count}')
    print(f'  - root_select_include_count:{root_select_include_count}')
    print(f'  - root_header_count:       {root_register_header_count}')
    print(f'  - register_header_count:   {register_header_count}')
    print(f'  - select_include_exists:   {select_exists}')
    print(f'  - wide_self_include_count: {wide_self_include_count}')
    print(f'  - duplicate_leaf_names:    {len(duplicate_leaf_names)}')
    if duplicate_leaf_records:
        print('  - duplicate_leaf_details:')
        for record in duplicate_leaf_records:
            print(f"    - {record['include']}: lines={record['lines']}")
    if root_symbol_counts:
        print('  - root_symbol_counts:')
        for symbol_name in sorted(root_symbol_counts):
            print(f'    - {symbol_name}: {root_symbol_counts[symbol_name]}')
    if wide_symbol_counts:
        print('  - wide_symbol_counts:')
        for symbol_name in sorted(wide_symbol_counts):
            print(f'    - {symbol_name}: {wide_symbol_counts[symbol_name]}')
    if select_symbol_counts:
        print('  - select_symbol_counts:')
        for symbol_name in sorted(select_symbol_counts):
            print(f'    - {symbol_name}: {select_symbol_counts[symbol_name]}')
    if wide_section_counts:
        print('  - wide_section_counts:')
        for marker, count in sorted(wide_section_counts.items()):
            print(f'    - {marker}: {count}')
    if failures:
        print('  - failures:')
        for item in failures:
            print(f'    - {item}')
    if args.summary_line:
        print(
            'SSE2_STRUCTURE_SUMMARY '
            f'register_include_exists={int(register_exists)} '
            f'root_include_count={root_include_count} '
            f'root_wide_include_count={root_wide_include_count} '
            f'root_select_include_count={root_select_include_count} '
            f'root_header_count={root_register_header_count} '
            f'register_header_count={register_header_count} '
            f'select_include_exists={int(select_exists)} '
            f'wide_self_include_count={wide_self_include_count} '
            f'duplicate_leaf_names={len(duplicate_leaf_names)} '
            f'failure_count={len(failures)} '
            f'status={payload["status"]}'
        )
    if failures:
        return 1
    print('[SSE2-STRUCTURE] OK')
    return 0


if __name__ == '__main__':
    sys.exit(main())
