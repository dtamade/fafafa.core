#!/usr/bin/env python3
"""Machine-check SIMD interface -> dispatch -> backend -> tests completeness."""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any


SLOT_RE = re.compile(r"\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(?:function|procedure)\b")
ASSIGN_RE = re.compile(r"\b(?:dispatchTable|table)\.([A-Za-z_][A-Za-z0-9_]*)\s*:=")
TOKEN_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
INCLUDE_RE = re.compile(r"\{\$I\s+([^}]+)\}", re.IGNORECASE)
INTERFACE_DECL_RE = re.compile(
    r"^\s*(?:class\s+)?(?:function|procedure)\s+([A-Za-z_][A-Za-z0-9_]*)\b",
    re.MULTILINE,
)
DECLARED_NAME_RE = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=", re.MULTILINE)
IMPLEMENTATION_SPLIT_RE = re.compile(r"^\s*implementation\s*$", re.IGNORECASE | re.MULTILINE)

CRITICAL_PREFIXES = ("Round", "Trunc", "Floor", "Ceil")
CRITICAL_SUFFIXES = ("F32x4", "F64x2", "F32x8", "F64x4", "F32x16", "F64x8")
NONX86_CHECKLIST_REL = "docs/plans/2026-02-09-simd-nonx86-interface-target-checklist.md"
RISCVV_DOT_TARGET_SLOTS = frozenset(("DotF32x8", "DotF64x2", "DotF64x4"))
NONX86_I16X32_TARGET_SLOTS = frozenset((
    "AddI16x32",
    "SubI16x32",
    "AndI16x32",
    "OrI16x32",
    "XorI16x32",
    "NotI16x32",
    "AndNotI16x32",
    "ShiftLeftI16x32",
    "ShiftRightI16x32",
    "ShiftRightArithI16x32",
    "CmpEqI16x32",
    "CmpLtI16x32",
    "CmpGtI16x32",
    "MinI16x32",
    "MaxI16x32",
))
NONX86_I8X64_TARGET_SLOTS = frozenset((
    "AddI8x64",
    "SubI8x64",
    "AndI8x64",
    "OrI8x64",
    "XorI8x64",
    "NotI8x64",
    "AndNotI8x64",
    "CmpEqI8x64",
    "CmpLtI8x64",
    "CmpGtI8x64",
    "MinI8x64",
    "MaxI8x64",
))
NONX86_U32X16_TARGET_SLOTS = frozenset((
    "AddU32x16",
    "SubU32x16",
    "MulU32x16",
    "AndU32x16",
    "OrU32x16",
    "XorU32x16",
    "NotU32x16",
    "AndNotU32x16",
    "ShiftLeftU32x16",
    "ShiftRightU32x16",
    "CmpEqU32x16",
    "CmpLtU32x16",
    "CmpGtU32x16",
    "CmpLeU32x16",
    "CmpGeU32x16",
    "CmpNeU32x16",
    "MinU32x16",
    "MaxU32x16",
))
NONX86_U64X8_TARGET_SLOTS = frozenset((
    "AddU64x8",
    "SubU64x8",
    "AndU64x8",
    "OrU64x8",
    "XorU64x8",
    "NotU64x8",
    "ShiftLeftU64x8",
    "ShiftRightU64x8",
    "CmpEqU64x8",
    "CmpLtU64x8",
    "CmpGtU64x8",
    "CmpLeU64x8",
    "CmpGeU64x8",
    "CmpNeU64x8",
))
NONX86_U8X64_TARGET_SLOTS = frozenset((
    "AddU8x64",
    "SubU8x64",
    "AndU8x64",
    "OrU8x64",
    "XorU8x64",
    "NotU8x64",
    "CmpEqU8x64",
    "CmpLtU8x64",
    "CmpGtU8x64",
    "MinU8x64",
    "MaxU8x64",
))
NONX86_MASK_HELPER_SLOTS = frozenset((
    "Mask2All",
    "Mask2Any",
    "Mask2None",
    "Mask2PopCount",
    "Mask2FirstSet",
    "Mask4All",
    "Mask4Any",
    "Mask4None",
    "Mask4PopCount",
    "Mask4FirstSet",
    "Mask8All",
    "Mask8Any",
    "Mask8None",
    "Mask8PopCount",
    "Mask8FirstSet",
    "Mask16All",
    "Mask16Any",
    "Mask16None",
    "Mask16PopCount",
    "Mask16FirstSet",
))
NEON_WIDE_WRAPPER_ONLY_SLOTS = frozenset((
    "AddI32x16",
    "AddI64x4",
    "AddI64x8",
    "AndI32x16",
    "AndI64x8",
    "AndNotI32x16",
    "ExtractI32x16",
    "ExtractI32x8",
    "ExtractI64x4",
    "InsertI32x16",
    "InsertI32x8",
    "InsertI64x4",
    "MaxI32x16",
    "MaxI32x8",
    "MinI32x16",
    "MinI32x8",
    "MulI32x16",
    "MulU32x8",
    "NotI32x16",
    "NotI64x8",
    "OrI32x16",
    "OrI64x8",
    "SubI32x16",
    "SubI64x4",
    "SubI64x8",
    "XorI32x16",
    "XorI64x8",
))
NONX86_WIDE_FALLBACK_ONLY_SLOTS = frozenset(
    tuple(sorted(NONX86_I16X32_TARGET_SLOTS))
    + tuple(sorted(NONX86_I8X64_TARGET_SLOTS))
    + tuple(sorted(NONX86_U32X16_TARGET_SLOTS))
    + tuple(sorted(NONX86_U64X8_TARGET_SLOTS))
    + tuple(sorted(NONX86_U8X64_TARGET_SLOTS))
)
RISCVV_BASE_SCALAR_ROUNDING_SLOTS = frozenset((
    "CeilF32x4",
    "CeilF32x8",
    "CeilF32x16",
    "CeilF64x2",
    "CeilF64x4",
    "CeilF64x8",
    "FloorF32x4",
    "FloorF32x8",
    "FloorF32x16",
    "FloorF64x2",
    "FloorF64x4",
    "FloorF64x8",
    "RoundF32x4",
    "RoundF32x8",
    "RoundF32x16",
    "RoundF64x2",
    "RoundF64x4",
    "RoundF64x8",
    "TruncF32x4",
    "TruncF32x8",
    "TruncF32x16",
    "TruncF64x2",
    "TruncF64x4",
    "TruncF64x8",
))
RISCVV_INTENTIONAL_BASE_SCALAR_SLOTS = frozenset(
    ("DotF32x8",)
    + tuple(sorted(NONX86_WIDE_FALLBACK_ONLY_SLOTS))
    + tuple(sorted(RISCVV_BASE_SCALAR_ROUNDING_SLOTS))
)
NEON_INTENTIONAL_BASE_SCALAR_SLOTS = frozenset(
    tuple(sorted(NONX86_WIDE_FALLBACK_ONLY_SLOTS))
    + tuple(sorted(NEON_WIDE_WRAPPER_ONLY_SLOTS))
    + tuple(sorted(NONX86_MASK_HELPER_SLOTS))
)


@dataclass(frozen=True)
class SlotCoverage:
    slot: str
    assigned_backends: list[str]
    test_refs: int
    severity: str
    reason: str


@dataclass(frozen=True)
class InterfaceSurfaceSpec:
    relative_path: str
    label: str
    required_functions: tuple[str, ...] = ()
    forbidden_functions: tuple[str, ...] = ()
    required_names: tuple[str, ...] = ()
    forbidden_names: tuple[str, ...] = ()
    required_substrings: tuple[str, ...] = ()


@dataclass(frozen=True)
class InterfaceSurfaceIssue:
    area: str
    severity: str
    reason: str


INTERFACE_SURFACE_SPECS: tuple[InterfaceSurfaceSpec, ...] = (
    InterfaceSurfaceSpec(
        relative_path="src/fafafa.core.simd.framework.intf.inc",
        label="top-level façade narrow re-export contract",
        required_functions=(
            "GetCPUInfo",
            "GetCurrentRuntimeSnapshot",
            "GetCurrentBackend",
            "GetCurrentBackendInfo",
            "GetCPUInformation",
            "GetSupportedBackendList",
            "GetBestSupportedBackend",
            "IsBackendRegisteredInBinary",
            "GetRegisteredBackendList",
            "GetDispatchableBackendList",
            "GetBestDispatchableBackend",
            "GetAvailableBackendList",
            "TrySetCurrentBackend",
            "SetCurrentBackend",
            "ResetCurrentBackendSelection",
            "TryForceBackend",
            "ForceBackend",
            "ResetBackendSelection",
            "AllocateAligned",
            "FreeAligned",
            "IsPointerAligned",
        ),
        forbidden_functions=(
            "GetSupportedBackends",
            "GetAvailableBackends",
            "GetBestBackendOnCPU",
            "GetBestBackend",
            "GetCurrentSimdRuntimeSnapshot",
        ),
    ),
    InterfaceSurfaceSpec(
        relative_path="src/fafafa.core.simd.runtime.pas",
        label="runtime canonical control-plane contract",
        required_functions=(
            "GetCurrentRuntimeSnapshot",
            "GetCurrentSimdRuntimeSnapshot",
            "GetCurrentBackend",
            "GetCurrentBackendInfo",
            "IsBackendRegisteredInBinary",
            "GetRegisteredBackendList",
            "GetDispatchableBackendList",
            "GetAvailableBackendList",
            "GetBestDispatchableBackend",
            "TrySetCurrentBackend",
            "SetCurrentBackend",
            "ResetCurrentBackendSelection",
        ),
        required_names=("TSimdRuntimeSnapshot",),
        forbidden_functions=(
            "GetCPUInformation",
            "TryForceBackend",
            "ForceBackend",
            "ResetBackendSelection",
            "GetAvailableBackends",
            "GetBestBackendOnCPU",
        ),
    ),
    InterfaceSurfaceSpec(
        relative_path="src/fafafa.core.simd.cpuinfo.pas",
        label="cpuinfo CPU/OS capability contract",
        required_functions=(
            "GetCPUInfo",
            "DetectCPUArchitecture",
            "HasFeature",
            "IsBackendSupportedOnCPU",
            "GetSupportedBackendList",
            "GetSupportedBackends",
            "GetAvailableBackends",
            "GetBestSupportedBackend",
            "GetBestBackendOnCPU",
            "GetBestBackend",
            "ResetCPUInfo",
            "HasSSE2",
            "HasSSE3",
            "HasSSSE3",
            "HasSSE41",
            "HasSSE42",
            "HasAVX2",
            "HasAVX512",
            "HasNEON",
            "HasRISCVV",
        ),
        required_names=("TSimdBackendArray",),
        forbidden_functions=(
            "GetDispatchableBackendList",
            "GetAvailableBackendList",
            "GetRegisteredBackendList",
            "IsBackendRegisteredInBinary",
            "TrySetCurrentBackend",
            "SetCurrentBackend",
            "ResetCurrentBackendSelection",
            "TryForceBackend",
            "ForceBackend",
            "ResetBackendSelection",
        ),
    ),
    InterfaceSurfaceSpec(
        relative_path="src/fafafa.core.simd.public_abi.intf.inc",
        label="public ABI wrapper contract",
        required_functions=(
            "GetSimdAbiVersionMajor",
            "GetSimdAbiVersionMinor",
            "GetSimdAbiSignature",
            "TryGetSimdBackendPodInfo",
            "GetSimdBackendNamePtr",
            "GetSimdBackendDescriptionPtr",
            "GetSimdPublicApi",
            "fafafa_simd_abi_version_major",
            "fafafa_simd_abi_version_minor",
            "fafafa_simd_abi_signature",
            "fafafa_simd_get_backend_pod_info",
            "fafafa_simd_backend_name",
            "fafafa_simd_backend_description",
            "fafafa_simd_get_public_api",
        ),
        required_names=(
            "TFafafaSimdAbiFlags",
            "TFafafaSimdBackendPodInfo",
            "PFafafaSimdBackendPodInfo",
            "TFafafaSimdPublicApi",
            "PFafafaSimdPublicApi",
        ),
    ),
    InterfaceSurfaceSpec(
        relative_path="src/fafafa.core.simd.STABLE",
        label="stable truth file contract",
        required_substrings=(
            "`fafafa.core.simd.runtime`",
            "`fafafa.core.simd.cpuinfo`",
            "documented public ABI wrapper",
            "top-level façade intentionally re-exports only a narrow convenience subset",
            "public surface contract inside `interface-completeness`",
            "src/fafafa.core.simd.runtime.pas",
            "src/fafafa.core.simd.public_abi.intf.inc",
        ),
    ),
)




def read_text_with_local_includes(path: Path, seen: set[Path] | None = None) -> str:
    if seen is None:
        seen = set()

    path = path.resolve()
    if path in seen:
        return ""
    seen.add(path)

    text = path.read_text(encoding="utf-8", errors="ignore")

    def repl(match: re.Match[str]) -> str:
        include_name = match.group(1).strip()
        include_path = (path.parent / include_name).resolve()
        if not include_path.exists():
            return match.group(0)
        return read_text_with_local_includes(include_path, seen)

    return INCLUDE_RE.sub(repl, text)


def read_interface_surface_text(path: Path) -> str:
    text = path.read_text(encoding="utf-8", errors="ignore")
    if path.suffix.lower() ==".pas":
        parts = IMPLEMENTATION_SPLIT_RE.split(text, maxsplit=1)
        if parts:
            text = parts[0]
    return text


def extract_declared_functions(path: Path) -> set[str]:
    return set(INTERFACE_DECL_RE.findall(read_interface_surface_text(path)))


def extract_declared_names(path: Path) -> set[str]:
    return set(DECLARED_NAME_RE.findall(read_interface_surface_text(path)))


def collect_interface_surface_issues(repo_root: Path) -> list[InterfaceSurfaceIssue]:
    issues: list[InterfaceSurfaceIssue] = []

    for spec in INTERFACE_SURFACE_SPECS:
        path = repo_root / spec.relative_path
        if not path.exists():
            issues.append(
                InterfaceSurfaceIssue(
                    area=spec.label,
                    severity="P0",
                    reason=f"missing contract file: {spec.relative_path}",
                )
            )
            continue

        text = read_interface_surface_text(path)
        declared_functions = extract_declared_functions(path)
        declared_names = extract_declared_names(path)

        for name in spec.required_functions:
            if name not in declared_functions:
                issues.append(
                    InterfaceSurfaceIssue(
                        area=spec.label,
                        severity="P0",
                        reason=f"missing required function `{name}` in {spec.relative_path}",
                    )
                )

        for name in spec.forbidden_functions:
            if name in declared_functions:
                issues.append(
                    InterfaceSurfaceIssue(
                        area=spec.label,
                        severity="P0",
                        reason=f"unexpected function `{name}` leaked into {spec.relative_path}",
                    )
                )

        for name in spec.required_names:
            if name not in declared_names:
                issues.append(
                    InterfaceSurfaceIssue(
                        area=spec.label,
                        severity="P0",
                        reason=f"missing required declared name `{name}` in {spec.relative_path}",
                    )
                )

        for name in spec.forbidden_names:
            if name in declared_names:
                issues.append(
                    InterfaceSurfaceIssue(
                        area=spec.label,
                        severity="P0",
                        reason=f"unexpected declared name `{name}` leaked into {spec.relative_path}",
                    )
                )

        for snippet in spec.required_substrings:
            if snippet not in text:
                issues.append(
                    InterfaceSurfaceIssue(
                        area=spec.label,
                        severity="P0",
                        reason=f"missing required boundary text `{snippet}` in {spec.relative_path}",
                    )
                )

    return issues

def extract_dispatch_slots(dispatch_file: Path) -> list[str]:
    text = read_text_with_local_includes(dispatch_file).splitlines()
    slots: list[str] = []
    in_record = False
    for line in text:
        if not in_record:
            if re.search(r"\bTSimdDispatchTable\s*=\s*record\b", line):
                in_record = True
            continue
        if re.match(r"\s*end;\s*$", line):
            break
        m = SLOT_RE.match(line)
        if m:
            slots.append(m.group(1))
    return slots


def extract_assigned_slots(path: Path, slot_set: set[str]) -> set[str]:
    text = read_text_with_local_includes(path)
    assigned = set(ASSIGN_RE.findall(text))
    return assigned & slot_set


def apply_intentional_base_scalar_coverage(backend: str, assigned_slots: set[str]) -> set[str]:
    if backend == "neon":
        # RegisterNEONBackend starts from FillBaseDispatchTable. These wide
        # fallback-only helper families, wide wrapper-only integer slots, and
        # mask helpers intentionally inherit the published scalar slots instead
        # of restating NEON-local scalar forwarders.
        return assigned_slots | NEON_INTENTIONAL_BASE_SCALAR_SLOTS
    if backend == "riscvv":
        # RegisterRISCVVBackend starts from FillBaseDispatchTable. After the
        # dead-wrapper cleanup, these slots intentionally inherit the published
        # scalar slot instead of restating a RISCVV-specific scalar forwarder.
        return assigned_slots | RISCVV_INTENTIONAL_BASE_SCALAR_SLOTS
    return assigned_slots


def build_test_token_counter(tests_root: Path) -> dict[str, int]:
    counter: dict[str, int] = {}
    for file in sorted(tests_root.rglob("*.pas")):
        text = file.read_text(encoding="utf-8", errors="ignore")
        for token in TOKEN_RE.findall(text):
            counter[token] = counter.get(token, 0) + 1
    return counter


def extract_nonx86_p0_target_slots(checklist_path: Path) -> set[str]:
    if not checklist_path.exists():
        return set()

    text = checklist_path.read_text(encoding="utf-8", errors="ignore")
    start_marker = "## 3) P0 清单"
    end_marker = "## 4) P1 清单"
    start = text.find(start_marker)
    if start < 0:
        return set()
    end = text.find(end_marker, start)
    if end < 0:
        end = len(text)

    section = text[start:end]
    return set(re.findall(r"`([A-Za-z_][A-Za-z0-9_]*)`", section))


def is_critical_slot(slot: str) -> bool:
    return slot.startswith(CRITICAL_PREFIXES) and slot.endswith(CRITICAL_SUFFIXES)


def classify_slot(
    slot: str,
    assigned_backends: list[str],
    test_refs: int,
    nonx86_target_slots: set[str],
) -> tuple[str, str]:
    has_scalar = "scalar" in assigned_backends
    simd_backends = [x for x in assigned_backends if x != "scalar"]
    has_nonx86 = ("neon" in assigned_backends) or ("riscvv" in assigned_backends)

    if not has_scalar:
        return ("P0", "missing scalar dispatch assignment")

    if slot in RISCVV_DOT_TARGET_SLOTS and "riscvv" not in assigned_backends:
        return ("P1", "riscvv high-roi dot slot missing backend assignment")

    if slot in NONX86_I16X32_TARGET_SLOTS:
        missing_nonx86 = [x for x in ("neon", "riscvv") if x not in assigned_backends]
        if missing_nonx86:
            return (
                "P1",
                "non-x86 high-roi I16x32 slot missing backend assignment: " + ",".join(missing_nonx86),
            )

    if slot in NONX86_I8X64_TARGET_SLOTS:
        missing_nonx86 = [x for x in ("neon", "riscvv") if x not in assigned_backends]
        if missing_nonx86:
            return (
                "P1",
                "non-x86 high-roi I8x64 slot missing backend assignment: " + ",".join(missing_nonx86),
            )

    if slot in NONX86_U32X16_TARGET_SLOTS:
        missing_nonx86 = [x for x in ("neon", "riscvv") if x not in assigned_backends]
        if missing_nonx86:
            return (
                "P1",
                "non-x86 high-roi U32x16 slot missing backend assignment: " + ",".join(missing_nonx86),
            )

    if slot in NONX86_U64X8_TARGET_SLOTS:
        missing_nonx86 = [x for x in ("neon", "riscvv") if x not in assigned_backends]
        if missing_nonx86:
            return (
                "P1",
                "non-x86 high-roi U64x8 slot missing backend assignment: " + ",".join(missing_nonx86),
            )

    if slot in NONX86_U8X64_TARGET_SLOTS:
        missing_nonx86 = [x for x in ("neon", "riscvv") if x not in assigned_backends]
        if missing_nonx86:
            return (
                "P1",
                "non-x86 high-roi U8x64 slot missing backend assignment: " + ",".join(missing_nonx86),
            )

    if slot in nonx86_target_slots:
        missing_nonx86 = [x for x in ("neon", "riscvv") if x not in assigned_backends]
        if missing_nonx86:
            return (
                "P1",
                "non-x86 P0 target missing backend assignment: " + ",".join(missing_nonx86),
            )
        if test_refs == 0:
            return ("P2", "non-x86 P0 target has no tests token references")
        return ("OK", "non-x86 P0 target covered")

    if is_critical_slot(slot):
        if test_refs == 0:
            return ("P0", "critical slot has no tests token references")
        if len(simd_backends) == 0:
            return ("P0", "critical slot is scalar-only")
        if not has_nonx86:
            return ("P1", "critical slot has no non-x86 backend assignment")
        if test_refs < 3:
            return ("P2", "critical slot test references are thin")
        return ("OK", "critical slot covered")

    if len(simd_backends) == 0 and test_refs == 0:
        return ("P1", "scalar-only and no tests token references")
    if test_refs == 0:
        return ("P2", "no tests token references")
    return ("OK", "covered")


def should_fail_in_strict(severity_counts: dict[str, int], strict_level: str) -> bool:
    p0 = severity_counts.get("P0", 0)
    p1 = severity_counts.get("P1", 0)
    p2 = severity_counts.get("P2", 0)

    if strict_level == "p0":
        return p0 > 0
    if strict_level == "p1":
        return (p0 + p1) > 0
    # strict_level == "p2"
    return (p0 + p1 + p2) > 0


def render_markdown(
    report: dict[str, Any],
    out_path: Path,
) -> None:
    lines: list[str] = []
    lines.append("# SIMD Public Surface + Interface/Implementation Completeness Report")
    lines.append("")
    lines.append(f"- generated_at: {report['generated_at']}")
    lines.append(f"- dispatch_slots_total: `{report['dispatch_slots_total']}`")
    lines.append(f"- strict: `{report['strict']}`")
    lines.append(f"- strict_level: `{report['strict_level']}`")
    lines.append(f"- interface_surface_issues: `{len(report['interface_surface_issues'])}`")
    lines.append("- analyzer: `heuristic token/assignment scan (not semantic proof)`")
    lines.append("")
    lines.append("## Public Interface Surface Contract")
    lines.append("")
    if not report["interface_surface_issues"]:
        lines.append("- none")
    else:
        for item in report["interface_surface_issues"]:
            lines.append(f"- `{item['area']}`: {item['reason']}")
    lines.append("")
    lines.append("## Backend Slot Coverage")
    lines.append("")
    for backend, count in report["backend_slot_counts"].items():
        lines.append(f"- {backend}: `{count}/{report['dispatch_slots_total']}`")
    lines.append("")
    lines.append("## Severity Summary")
    lines.append("")
    lines.append(f"- P0: `{report['severity_counts'].get('P0', 0)}`")
    lines.append(f"- P1: `{report['severity_counts'].get('P1', 0)}`")
    lines.append(f"- P2: `{report['severity_counts'].get('P2', 0)}`")
    lines.append("")
    lines.append("## P0 Items")
    lines.append("")
    if not report["p0_items"]:
        lines.append("- none")
    else:
        for item in report["p0_items"]:
            lines.append(f"- `{item['slot']}`: {item['reason']}")
    lines.append("")
    lines.append("## P1 Items (Top 80)")
    lines.append("")
    if not report["p1_items"]:
        lines.append("- none")
    else:
        for item in report["p1_items"][:80]:
            lines.append(f"- `{item['slot']}`: {item['reason']}")
    lines.append("")
    lines.append("## P2 Items (Top 80)")
    lines.append("")
    if not report["p2_items"]:
        lines.append("- none")
    else:
        for item in report["p2_items"][:80]:
            lines.append(f"- `{item['slot']}`: {item['reason']}")
    lines.append("")

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Check SIMD interface implementation completeness")
    parser.add_argument("--strict", action="store_true", help="enable strict failure by severity threshold")
    parser.add_argument(
        "--strict-level",
        choices=("p0", "p1", "p2"),
        default="p2",
        help="strict threshold: p0=fail on P0, p1=fail on P0/P1, p2=fail on P0/P1/P2",
    )
    parser.add_argument(
        "--json-file",
        default="tests/fafafa.core.simd/logs/interface_completeness.json",
        help="Output JSON file path (repo-relative)",
    )
    parser.add_argument(
        "--md-file",
        default="tests/fafafa.core.simd/docs/interface_implementation_completeness.md",
        help="Output markdown file path (repo-relative)",
    )
    parser.add_argument("--json", action="store_true", help="print JSON to stdout")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[2]
    dispatch_file = repo_root / "src" / "fafafa.core.simd.dispatch.pas"
    tests_root = repo_root / "tests" / "fafafa.core.simd"
    nonx86_checklist = repo_root / NONX86_CHECKLIST_REL

    backend_files = {
        "scalar": dispatch_file,
        "sse2": repo_root / "src" / "fafafa.core.simd.sse2.pas",
        "sse3": repo_root / "src" / "fafafa.core.simd.sse3.pas",
        "ssse3": repo_root / "src" / "fafafa.core.simd.ssse3.pas",
        "sse41": repo_root / "src" / "fafafa.core.simd.sse41.pas",
        "sse42": repo_root / "src" / "fafafa.core.simd.sse42.pas",
        "avx2": repo_root / "src" / "fafafa.core.simd.avx2.pas",
        "avx512": repo_root / "src" / "fafafa.core.simd.avx512.pas",
        "neon": repo_root / "src" / "fafafa.core.simd.neon.pas",
        "riscvv": repo_root / "src" / "fafafa.core.simd.riscvv.pas",
    }

    slots = extract_dispatch_slots(dispatch_file)
    slot_set = set(slots)
    test_counter = build_test_token_counter(tests_root)
    nonx86_target_slots = extract_nonx86_p0_target_slots(nonx86_checklist) & slot_set
    surface_issues = collect_interface_surface_issues(repo_root)

    backend_assigned: dict[str, set[str]] = {}
    for backend, file in backend_files.items():
        backend_assigned[backend] = apply_intentional_base_scalar_coverage(
            backend=backend,
            assigned_slots=extract_assigned_slots(file, slot_set),
        )

    items: list[SlotCoverage] = []
    severity_counts = {"P0": 0, "P1": 0, "P2": 0}
    for slot in sorted(slots):
        assigned_backends = [backend for backend in backend_files.keys() if slot in backend_assigned[backend]]
        severity, reason = classify_slot(
            slot=slot,
            assigned_backends=assigned_backends,
            test_refs=test_counter.get(slot, 0),
            nonx86_target_slots=nonx86_target_slots,
        )
        items.append(
            SlotCoverage(
                slot=slot,
                assigned_backends=assigned_backends,
                test_refs=test_counter.get(slot, 0),
                severity=severity,
                reason=reason,
            )
        )
        if severity in severity_counts:
            severity_counts[severity] += 1

    for issue in surface_issues:
        if issue.severity in severity_counts:
            severity_counts[issue.severity] += 1

    p0_items = [
        {
            "slot": x.slot,
            "assigned_backends": x.assigned_backends,
            "test_refs": x.test_refs,
            "reason": x.reason,
        }
        for x in items
        if x.severity == "P0"
    ]
    p0_items.extend(
        {
            "slot": f"[surface] {x.area}",
            "assigned_backends": [],
            "test_refs": 0,
            "reason": x.reason,
        }
        for x in surface_issues
        if x.severity == "P0"
    )
    p1_items = [
        {
            "slot": x.slot,
            "assigned_backends": x.assigned_backends,
            "test_refs": x.test_refs,
            "reason": x.reason,
        }
        for x in items
        if x.severity == "P1"
    ]
    p1_items.extend(
        {
            "slot": f"[surface] {x.area}",
            "assigned_backends": [],
            "test_refs": 0,
            "reason": x.reason,
        }
        for x in surface_issues
        if x.severity == "P1"
    )
    p2_items = [
        {
            "slot": x.slot,
            "assigned_backends": x.assigned_backends,
            "test_refs": x.test_refs,
            "reason": x.reason,
        }
        for x in items
        if x.severity == "P2"
    ]
    p2_items.extend(
        {
            "slot": f"[surface] {x.area}",
            "assigned_backends": [],
            "test_refs": 0,
            "reason": x.reason,
        }
        for x in surface_issues
        if x.severity == "P2"
    )

    report: dict[str, Any] = {
        "generated_at": datetime.now().isoformat(timespec="seconds"),
        "strict": bool(args.strict),
        "strict_level": args.strict_level,
        "analyzer": "heuristic-token-assignment-scan",
        "dispatch_slots_total": len(slots),
        "backend_slot_counts": {k: len(v) for k, v in backend_assigned.items()},
        "severity_counts": severity_counts,
        "interface_surface_issues": [
            {
                "area": x.area,
                "severity": x.severity,
                "reason": x.reason,
            }
            for x in surface_issues
        ],
        "p0_items": p0_items,
        "p1_items": p1_items,
        "p2_items": p2_items,
    }

    json_path = Path(args.json_file)
    if not json_path.is_absolute():
        json_path = repo_root / json_path
    md_path = Path(args.md_file)
    if not md_path.is_absolute():
        md_path = repo_root / md_path

    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    render_markdown(report=report, out_path=md_path)

    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        strict_fail = should_fail_in_strict(severity_counts, args.strict_level)
        print("[SIMD-COMPLETENESS] public-surface + interface->dispatch->backend->tests")
        print(f"  - dispatch_slots_total: {report['dispatch_slots_total']}")
        print(f"  - backend_slot_counts: {report['backend_slot_counts']}")
        print(f"  - severity_counts: {report['severity_counts']}")
        print(f"  - interface_surface_issues: {len(surface_issues)}")
        print(f"  - strict_level: {report['strict_level']}")
        print("  - analyzer: heuristic token/assignment scan (not semantic proof)")
        print(f"  - json: {json_path}")
        print(f"  - markdown: {md_path}")
        if surface_issues:
            print("  - public surface preview:")
            for item in surface_issues[:10]:
                print(f"    * {item.area}: {item.reason}")
        if p0_items:
            print("  - P0 preview:")
            for item in p0_items[:10]:
                print(f"    * {item['slot']}: {item['reason']}")
        if args.strict and strict_fail:
            print("[SIMD-COMPLETENESS] FAIL (strict threshold breached)")
        elif p0_items:
            print("[SIMD-COMPLETENESS] FAIL (P0 exists)")
        else:
            print("[SIMD-COMPLETENESS] OK")

    if args.strict and should_fail_in_strict(severity_counts, args.strict_level):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
