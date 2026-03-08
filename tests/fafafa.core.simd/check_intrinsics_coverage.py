#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path


@dataclass
class CheckItem:
    name: str
    status: str
    detail: str


SUITES_REQUIRED_STABLE = [
    'TTestCase_DispatchAPI',
    'TTestCase_VecI32x8',
    'TTestCase_VecU32x8',
    'TTestCase_VecF64x4',
]


def load_text(a_path: Path) -> str:
    return a_path.read_text(encoding='utf-8', errors='ignore')


def has_printed_suite(a_text: str, a_suite: str) -> bool:
    return f"WriteLn('  {a_suite}')" in a_text or f'WriteLn("  {a_suite}")' in a_text


def has_registered_suite(a_text: str, a_suite: str) -> bool:
    l_pattern = re.compile(
        rf"ShouldRunSuite\('{re.escape(a_suite)}'\).*?AddTest\({re.escape(a_suite)}\.Suite\)",
        re.DOTALL,
    )
    if l_pattern.search(a_text):
        return True
    return f'AddTest({a_suite}.Suite)' in a_text or f'RegisterTest({a_suite})' in a_text


def main() -> int:
    l_parser = argparse.ArgumentParser(description='Check SIMD intrinsics coverage wiring')
    l_parser.add_argument('--root', default=str(Path(__file__).resolve().parent))
    l_parser.add_argument('--json', action='store_true')
    l_parser.add_argument('--summary-line', action='store_true')
    l_parser.add_argument('--strict-extra', action='store_true')
    l_parser.add_argument('--require-avx2', action='store_true')
    l_parser.add_argument('--require-experimental', action='store_true')
    l_args = l_parser.parse_args()

    l_root = Path(l_args.root).resolve()
    l_repo_root = l_root.parent.parent
    l_tests_root = l_repo_root / 'tests'
    l_docs_root = l_repo_root / 'docs'

    l_main_test_lpr = l_root / 'fafafa.core.simd.test.lpr'
    l_avx2_testcase = l_root / 'fafafa.core.simd.intrinsics.avx2.testcase.pas'
    l_experimental_root = l_tests_root / 'fafafa.core.simd.intrinsics.experimental'
    l_experimental_runner = l_experimental_root / 'BuildOrTest.sh'
    l_experimental_lpr = l_experimental_root / 'fafafa.core.simd.intrinsics.experimental.test.lpr'
    l_experimental_testcase = l_experimental_root / 'fafafa.core.simd.intrinsics.experimental.testcase.pas'
    l_closeout_doc = l_docs_root / 'fafafa.core.simd.closeout.md'
    l_maintenance_doc = l_docs_root / 'fafafa.core.simd.maintenance.md'

    l_main_text = load_text(l_main_test_lpr)
    l_checks: list[CheckItem] = []

    l_missing_listed = [l_suite for l_suite in SUITES_REQUIRED_STABLE if not has_printed_suite(l_main_text, l_suite)]
    if l_missing_listed:
        l_checks.append(CheckItem(
            name='stable_gate_suites_listed',
            status='FAIL',
            detail='missing listed suites: ' + ', '.join(l_missing_listed),
        ))
    else:
        l_checks.append(CheckItem(
            name='stable_gate_suites_listed',
            status='PASS',
            detail=f'all {len(SUITES_REQUIRED_STABLE)} stable gate suites are listed in PrintAvailableSuites',
        ))

    l_missing_registered = [l_suite for l_suite in SUITES_REQUIRED_STABLE if not has_registered_suite(l_main_text, l_suite)]
    if l_missing_registered:
        l_checks.append(CheckItem(
            name='stable_gate_suites_registered',
            status='FAIL',
            detail='missing registered suites: ' + ', '.join(l_missing_registered),
        ))
    else:
        l_checks.append(CheckItem(
            name='stable_gate_suites_registered',
            status='PASS',
            detail=f'all {len(SUITES_REQUIRED_STABLE)} stable gate suites are wired into testSuite.AddTest',
        ))

    if l_args.require_avx2:
        l_has_avx2_unit = 'fafafa.core.simd.intrinsics.avx2.testcase' in l_main_text and l_avx2_testcase.is_file()
        l_has_avx2_list = has_printed_suite(l_main_text, 'TTestCase_AVX2IntrinsicsFallback')
        l_has_avx2_register = has_registered_suite(l_main_text, 'TTestCase_AVX2IntrinsicsFallback')
        if l_has_avx2_unit and l_has_avx2_list and l_has_avx2_register:
            l_checks.append(CheckItem(
                name='avx2_intrinsics_fallback_coverage',
                status='PASS',
                detail='AVX2 fallback testcase file, suite listing, and suite registration are all present',
            ))
        else:
            l_details: list[str] = []
            if not l_has_avx2_unit:
                l_details.append('missing avx2 testcase unit wiring')
            if not l_has_avx2_list:
                l_details.append('missing AVX2 suite listing')
            if not l_has_avx2_register:
                l_details.append('missing AVX2 suite registration')
            l_checks.append(CheckItem(
                name='avx2_intrinsics_fallback_coverage',
                status='FAIL',
                detail='; '.join(l_details),
            ))

    if l_args.require_experimental:
        l_runner_ok = l_experimental_runner.is_file()
        l_project_ok = l_experimental_lpr.is_file()
        l_testcase_ok = l_experimental_testcase.is_file()
        if l_runner_ok and l_project_ok and l_testcase_ok:
            l_checks.append(CheckItem(
                name='experimental_intrinsics_runner',
                status='PASS',
                detail='experimental runner and minimal test project are present',
            ))
        else:
            l_details: list[str] = []
            if not l_runner_ok:
                l_details.append(f'missing {l_experimental_runner.relative_to(l_repo_root)}')
            if not l_project_ok:
                l_details.append(f'missing {l_experimental_lpr.relative_to(l_repo_root)}')
            if not l_testcase_ok:
                l_details.append(f'missing {l_experimental_testcase.relative_to(l_repo_root)}')
            l_checks.append(CheckItem(
                name='experimental_intrinsics_runner',
                status='FAIL',
                detail='; '.join(l_details),
            ))

    if l_args.strict_extra:
        l_maintenance_text = load_text(l_maintenance_doc)
        l_closeout_text = load_text(l_closeout_doc)
        l_has_maintenance_phrase = 'gate、coverage、adapter、wiring' in l_maintenance_text
        l_has_closeout_gate = 'gate-strict' in l_closeout_text and 'SIMD_GATE_' in l_closeout_text
        if l_has_maintenance_phrase and l_has_closeout_gate:
            l_checks.append(CheckItem(
                name='docs_reference_coverage_gate',
                status='PASS',
                detail='maintenance and closeout docs both mention coverage/gate expectations',
            ))
        else:
            l_details: list[str] = []
            if not l_has_maintenance_phrase:
                l_details.append('maintenance doc missing gate/coverage/adapter/wiring phrase')
            if not l_has_closeout_gate:
                l_details.append('closeout doc missing gate-strict SIMD_GATE_* guidance')
            l_checks.append(CheckItem(
                name='docs_reference_coverage_gate',
                status='FAIL',
                detail='; '.join(l_details),
            ))

    l_failed = [l_item for l_item in l_checks if l_item.status != 'PASS']
    l_payload = {
        'status': 'PASS' if not l_failed else 'FAIL',
        'strict_extra': l_args.strict_extra,
        'require_avx2': l_args.require_avx2,
        'require_experimental': l_args.require_experimental,
        'checks': [asdict(l_item) for l_item in l_checks],
        'files': {
            'main_test_lpr': str(l_main_test_lpr),
            'avx2_testcase': str(l_avx2_testcase),
            'experimental_runner': str(l_experimental_runner),
            'experimental_lpr': str(l_experimental_lpr),
            'experimental_testcase': str(l_experimental_testcase),
            'closeout_doc': str(l_closeout_doc),
            'maintenance_doc': str(l_maintenance_doc),
        },
        'metrics': {
            'stable_suite_count': len(SUITES_REQUIRED_STABLE),
            'failed_check_count': len(l_failed),
        },
    }

    if l_args.json:
        print(json.dumps(l_payload, ensure_ascii=False, indent=2))
    else:
        for l_item in l_checks:
            print(f'[COVERAGE] {l_item.name}: {l_item.status} - {l_item.detail}')
        if l_args.summary_line:
            print(
                'COVERAGE_SUMMARY '
                f"checks={len(l_checks)} failed={len(l_failed)} status={l_payload['status']} "
                f'strict_extra={int(l_args.strict_extra)} require_avx2={int(l_args.require_avx2)} '
                f'require_experimental={int(l_args.require_experimental)}'
            )

    return 0 if not l_failed else 1


if __name__ == '__main__':
    try:
        sys.exit(main())
    except Exception as l_exc:
        print(json.dumps({'status': 'ERROR', 'detail': str(l_exc)}, ensure_ascii=False), file=sys.stderr)
        sys.exit(2)
