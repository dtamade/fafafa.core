#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RISCVV_FILE = ROOT / 'src' / 'fafafa.core.simd.riscvv.pas'
ROUTINE_BLOCK_PATTERN = r'(?ims)^(function|procedure)\s+{name}\b.*?(?=^(function|procedure)\s+[A-Za-z_][A-Za-z0-9_\.]*\b|^initialization\b|\Z)'
DIRECT_VEC_FUNC_RE = re.compile(
    r'(?im)^function\s+(RISCVV[A-Za-z0-9_]+)\((.*?)\)\s*:\s*(TVec[A-Za-z0-9_]+)\s*;\s*assembler;\s*nostackframe;'
)
RESULT_STORE_RE = re.compile(r'\bvse(?:8|16|32|64)\.v\b[^\n]*\(a0\)', re.IGNORECASE)
A0_LOAD_RE = re.compile(r'\bvle(?:8|16|32|64)\.v\b[^\n]*\(a0\)', re.IGNORECASE)

HIDDEN_RESULT_RETURN_TYPES = {
    'TVecI16x8', 'TVecI8x16',
    'TVecU16x8', 'TVecU8x16',
    'TVecF32x8', 'TVecF32x16',
    'TVecF64x4', 'TVecF64x8',
    'TVecI32x8', 'TVecI32x16',
    'TVecU32x8', 'TVecU32x16',
    'TVecI64x4', 'TVecI64x8',
    'TVecU64x4', 'TVecU64x8',
}

EXPLICIT_ROUTINES: list[tuple[str, list[str]]] = [
    ('RISCVVStoreI64x4', ['vle64.v v0, (a1)', 'vse64.v v0, (a0)']),
    ('RISCVVLoadI64x4Asm', ['vle64.v v0, (a0)', 'vse64.v v0, (a1)']),
    ('RISCVVSplatI64x4Asm', ['vmv.v.x v0, a0', 'vse64.v v0, (a1)']),
    ('RISCVVZeroI64x4Asm', ['vmv.v.i v0, 0', 'vse64.v v0, (a0)']),
    ('RISCVVAddI16x8', ['vle16.v v0, (a1)', 'vle16.v v1, (a2)', 'vse16.v v0, (a0)']),
    ('RISCVVAddI8x16', ['vle8.v v0, (a1)', 'vle8.v v1, (a2)', 'vse8.v v0, (a0)']),
    ('RISCVVAddU16x8', ['vle16.v v0, (a1)', 'vle16.v v1, (a2)', 'vse16.v v0, (a0)']),
    ('RISCVVAddU8x16', ['vle8.v v0, (a1)', 'vle8.v v1, (a2)', 'vse8.v v0, (a0)']),
    ('RISCVVAndNotI16x8', ['Result := ScalarAndNotI16x8(a, b);']),
    ('RISCVVAndNotI8x16', ['for LIndex := 0 to 15 do', 'Result.i[LIndex] := (not a.i[LIndex]) and b.i[LIndex];']),
    ('RISCVVAndNotU16x8', ['for LIndex := 0 to 7 do', 'Result.u[LIndex] := (not a.u[LIndex]) and b.u[LIndex];']),
    ('RISCVVAndNotU8x16', ['for LIndex := 0 to 15 do', 'Result.u[LIndex] := (not a.u[LIndex]) and b.u[LIndex];']),
    ('RISCVVCmpLtI32x8', ['vmv.x.s a0, v0', 'andi a0, a0, 255']),
    ('RISCVVCmpEqI32x16', ['vmv.x.s a0, v0', 'slli a0, a0, 48', 'srli a0, a0, 48']),
    ('RISCVVCmpNeU32x8', ['vle32.v v0, (a0)', 'vle32.v v2, (a1)', 'vmsne.vv v0, v0, v2']),
    ('RISCVVCmpNeU64x4', ['vle64.v v0, (a0)', 'vle64.v v2, (a1)', 'vmsne.vv v0, v0, v2']),
    ('RISCVVExtractI32x8Asm', ['vle32.v v0, (a0)', 'vslidedown.vx v0, v0, a1', 'vmv.x.s a0, v0']),
    ('RISCVVExtractI32x16Asm', ['vle32.v v0, (a0)', 'vslidedown.vx v0, v0, a1', 'vmv.x.s a0, v0']),
    ('RISCVVExtractI64x4Asm', ['vle64.v v0, (a0)', 'vslidedown.vx v0, v0, a1', 'vmv.x.s a0, v0']),
    ('RISCVVInsertI32x8Asm', ['vle32.v v0, (a0)', 'vse32.v v0, (a3)', 'sw a1, (t0)']),
    ('RISCVVInsertI32x16Asm', ['vle32.v v0, (a0)', 'vse32.v v0, (a3)', 'sw a1, (t0)']),
    ('RISCVVInsertI64x4Asm', ['vle64.v v0, (a0)', 'vse64.v v0, (a3)', 'sd a1, (t0)']),
]


def extract_routine_block(source: str, routine_name: str) -> str:
    pattern = re.compile(ROUTINE_BLOCK_PATTERN.format(name=re.escape(routine_name)))
    match = pattern.search(source)
    if not match:
        raise AssertionError(f'missing routine: {routine_name}')
    return match.group(0)


def normalize(text: str) -> str:
    return re.sub(r'\s+', ' ', text.strip())


def require_fragments(body: str, routine_name: str, fragments: list[str]) -> None:
    normalized = normalize(body)
    for fragment in fragments:
        if normalize(fragment) not in normalized:
            raise AssertionError(f'{routine_name} missing fragment: {fragment}')


def main() -> int:
    parser = argparse.ArgumentParser(description='Check RISCVV ABI-sensitive source shape')
    parser.add_argument('--json', action='store_true')
    parser.add_argument('--summary-line', action='store_true')
    args = parser.parse_args()

    source = RISCVV_FILE.read_text(encoding='utf-8')
    direct_functions = 0
    missing_result_store: list[str] = []
    suspicious_a0_loads: list[str] = []
    explicit_checks = 0

    try:
        for match in DIRECT_VEC_FUNC_RE.finditer(source):
            routine_name = match.group(1)
            params = match.group(2).strip()
            return_type = match.group(3)
            if return_type not in HIDDEN_RESULT_RETURN_TYPES:
                continue
            body = extract_routine_block(source, routine_name)
            direct_functions += 1
            if params and not RESULT_STORE_RE.search(body):
                missing_result_store.append(routine_name)
            if params and A0_LOAD_RE.search(body):
                suspicious_a0_loads.append(routine_name)

        for routine_name, fragments in EXPLICIT_ROUTINES:
            require_fragments(extract_routine_block(source, routine_name), routine_name, fragments)
            explicit_checks += 1

        if missing_result_store:
            raise AssertionError('missing result store: ' + ', '.join(missing_result_store))
        if suspicious_a0_loads:
            raise AssertionError('suspicious a0 load in direct vector-return asm: ' + ', '.join(suspicious_a0_loads))

        result = {
            'ok': True,
            'direct_vector_return_functions': direct_functions,
            'explicit_checks': explicit_checks,
            'missing_result_store': missing_result_store,
            'suspicious_a0_loads': suspicious_a0_loads,
        }
        if args.json:
            print(json.dumps(result, ensure_ascii=False, sort_keys=True))
        else:
            print('[RISCVV-ABI] source shape')
            print(f'  - direct vector-return functions: {direct_functions}')
            print(f'  - explicit helper checks:         {explicit_checks}')
            print(f'  - missing result store:           {len(missing_result_store)}')
            print(f'  - suspicious a0 loads:            {len(suspicious_a0_loads)}')
            print('[RISCVV-ABI] OK')
        if args.summary_line:
            print(
                'RISCVV_ABI_SHAPE_SUMMARY '
                f'direct_functions={direct_functions} '
                f'explicit_checks={explicit_checks} '
                f'missing_result_store={len(missing_result_store)} '
                f'suspicious_a0_loads={len(suspicious_a0_loads)} '
                'status=ok'
            )
        return 0
    except AssertionError as exc:
        result = {
            'ok': False,
            'direct_vector_return_functions': direct_functions,
            'explicit_checks': explicit_checks,
            'missing_result_store': missing_result_store,
            'suspicious_a0_loads': suspicious_a0_loads,
            'error': str(exc),
        }
        if args.json:
            print(json.dumps(result, ensure_ascii=False, sort_keys=True))
        else:
            print(f'[RISCVV-ABI] FAILED: {exc}')
        if args.summary_line:
            print(
                'RISCVV_ABI_SHAPE_SUMMARY '
                f'direct_functions={direct_functions} '
                f'explicit_checks={explicit_checks} '
                f'missing_result_store={len(missing_result_store)} '
                f'suspicious_a0_loads={len(suspicious_a0_loads)} '
                'status=fail'
            )
        return 1


if __name__ == '__main__':
    sys.exit(main())
