#!/usr/bin/env python3
"""SIMD intrinsics direct-test coverage checker (SSE/MMX/AVX2 + experimental AES/SHA)."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


def _extract_declared(a_source_text: str, a_prefix: str) -> list[str]:
    l_interface_text = a_source_text.split('implementation', 1)[0]
    l_pattern = rf'\b(?:function|procedure)\s+({a_prefix}_[A-Za-z0-9_]+)\b'
    return sorted(set(re.findall(l_pattern, l_interface_text)))


def _extract_tested_by_suite_name(a_test_text: str, a_prefix: str) -> set[str]:
    l_pattern = rf'\bTest_({a_prefix}_[A-Za-z0-9_]+)\b'
    return set(re.findall(l_pattern, a_test_text))


def _extract_tested_by_symbol_ref(a_test_text: str, a_prefix: str) -> set[str]:
    l_pattern = rf'\b({a_prefix}_[A-Za-z0-9_]+)\b'
    return set(re.findall(l_pattern, a_test_text))


def _extract_tested(a_test_text: str, a_prefix: str, a_mode: str) -> set[str]:
    if a_mode == 'suite_name':
        return _extract_tested_by_suite_name(a_test_text=a_test_text, a_prefix=a_prefix)
    if a_mode == 'symbol_ref':
        return _extract_tested_by_symbol_ref(a_test_text=a_test_text, a_prefix=a_prefix)
    raise ValueError(f'unknown test extraction mode: {a_mode}')


def _check_module(a_name: str, a_src_file: Path, a_test_file: Path, a_prefix: str, a_test_mode: str, a_required: bool) -> dict:
    l_src_text = a_src_file.read_text(encoding='utf-8', errors='ignore')
    l_test_text = a_test_file.read_text(encoding='utf-8', errors='ignore')

    l_declared = _extract_declared(l_src_text, a_prefix)
    l_tested = _extract_tested(a_test_text=l_test_text, a_prefix=a_prefix, a_mode=a_test_mode)

    l_missing = [l_name for l_name in l_declared if l_name not in l_tested]
    l_extra = sorted(l_name for l_name in l_tested if l_name not in l_declared)

    return {
        'module': a_name,
        'prefix': a_prefix,
        'test_mode': a_test_mode,
        'required': a_required,
        'declared_count': len(l_declared),
        'tested_count': len(l_tested),
        'missing_count': len(l_missing),
        'missing': l_missing,
        'extra_count': len(l_extra),
        'extra': l_extra,
    }


def main() -> int:
    l_parser = argparse.ArgumentParser(description='Check SIMD intrinsics direct test coverage for SSE/MMX/AVX2 and experimental AES/SHA.')
    l_parser.add_argument('--json', action='store_true', dest='as_json', help='print JSON output')
    l_parser.add_argument('--strict-extra', action='store_true', dest='strict_extra',
                          help='treat extra test mappings as failure')
    l_parser.add_argument('--require-avx2', action='store_true', dest='require_avx2',
                          help='treat AVX2 missing mappings as failure')
    l_parser.add_argument('--require-experimental', action='store_true', dest='require_experimental',
                          help='treat experimental AES/SHA missing mappings as failure')
    l_args = l_parser.parse_args()

    l_repo_root = Path(__file__).resolve().parents[2]
    l_modules = [
        {
            'name': 'sse',
            'prefix': 'sse',
            'test_mode': 'suite_name',
            'required': True,
            'src': l_repo_root / 'src' / 'fafafa.core.simd.intrinsics.sse.pas',
            'test': l_repo_root / 'tests' / 'fafafa.core.simd.intrinsics.sse' / 'fafafa.core.simd.intrinsics.sse.testcase.pas',
        },
        {
            'name': 'mmx',
            'prefix': 'mmx',
            'test_mode': 'suite_name',
            'required': True,
            'src': l_repo_root / 'src' / 'fafafa.core.simd.intrinsics.mmx.pas',
            'test': l_repo_root / 'tests' / 'fafafa.core.simd.intrinsics.mmx' / 'fafafa.core.simd.intrinsics.mmx.testcase.pas',
        },
        {
            'name': 'avx2',
            'prefix': 'avx2',
            'test_mode': 'symbol_ref',
            'required': l_args.require_avx2,
            'src': l_repo_root / 'src' / 'fafafa.core.simd.intrinsics.avx2.pas',
            'test': l_repo_root / 'tests' / 'fafafa.core.simd' / 'fafafa.core.simd.intrinsics.avx2.testcase.pas',
        },
        {
            'name': 'aes',
            'prefix': 'aes',
            'test_mode': 'symbol_ref',
            'required': l_args.require_experimental,
            'src': l_repo_root / 'src' / 'fafafa.core.simd.intrinsics.aes.pas',
            'test': l_repo_root / 'tests' / 'fafafa.core.simd.intrinsics.experimental' / 'fafafa.core.simd.intrinsics.experimental.testcase.pas',
        },
        {
            'name': 'sha',
            'prefix': 'sha',
            'test_mode': 'symbol_ref',
            'required': l_args.require_experimental,
            'src': l_repo_root / 'src' / 'fafafa.core.simd.intrinsics.sha.pas',
            'test': l_repo_root / 'tests' / 'fafafa.core.simd.intrinsics.experimental' / 'fafafa.core.simd.intrinsics.experimental.testcase.pas',
        },
    ]

    for l_module in l_modules:
        if not l_module['src'].is_file() or not l_module['test'].is_file():
            print(f"[COVERAGE] ERROR: missing file for {l_module['name']}: {l_module['src']} or {l_module['test']}")
            return 2

    l_results = [
        _check_module(
            a_name=l_module['name'],
            a_src_file=l_module['src'],
            a_test_file=l_module['test'],
            a_prefix=l_module['prefix'],
            a_test_mode=l_module['test_mode'],
            a_required=l_module['required'],
        )
        for l_module in l_modules
    ]

    l_total_missing = sum(l_item['missing_count'] for l_item in l_results)
    l_total_missing_required = sum(l_item['missing_count'] for l_item in l_results if l_item['required'])
    l_total_missing_optional = l_total_missing - l_total_missing_required
    l_total_extra = sum(l_item['extra_count'] for l_item in l_results)

    if l_args.as_json:
        print(json.dumps({
            'results': l_results,
            'total_missing': l_total_missing,
            'total_missing_required': l_total_missing_required,
            'total_missing_optional': l_total_missing_optional,
            'total_extra': l_total_extra,
            'strict_extra': l_args.strict_extra,
            'require_avx2': l_args.require_avx2,
            'require_experimental': l_args.require_experimental,
        }, ensure_ascii=False, indent=2))
    else:
        print('[COVERAGE] SIMD intrinsics direct-test mapping')
        for l_item in l_results:
            l_scope = 'required' if l_item['required'] else 'optional'
            print(
                f"  - {l_item['module']}: declared={l_item['declared_count']} "
                f"tested={l_item['tested_count']} missing={l_item['missing_count']} "
                f"extra={l_item['extra_count']} mode={l_item['test_mode']} scope={l_scope}"
            )
            for l_name in l_item['missing']:
                print(f'      missing: {l_name}')
            for l_name in l_item['extra']:
                print(f'      extra: {l_name}')

        if l_total_missing_required == 0 and (not l_args.strict_extra or l_total_extra == 0):
            print('[COVERAGE] OK (no missing direct-test mappings)')
            if l_total_missing_optional > 0:
                print(f'[COVERAGE] WARN (optional module missing mappings: {l_total_missing_optional})')
        elif l_total_missing_required > 0:
            print(f'[COVERAGE] FAILED (missing mappings in required modules: {l_total_missing_required})')
        else:
            print(f'[COVERAGE] FAILED (strict-extra enabled, extra mappings: {l_total_extra})')

    if l_total_missing_required > 0:
        return 1
    if l_args.strict_extra and l_total_extra > 0:
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
