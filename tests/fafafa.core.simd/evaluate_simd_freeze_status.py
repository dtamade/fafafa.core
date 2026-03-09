#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
from dataclasses import dataclass, asdict
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional


REQUIRED_GATE_STEPS_BASE = [
    "build-check",
    "interface-completeness",
    "cross-backend-parity",
    "wiring-sync",
    "coverage",
    "simd-list-suites",
    "simd-avx2-fallback",
    "cpuinfo-portable",
    "cpuinfo-x86",
    "run-all-chain",
]
QEMU_CPUINFO_NONX86_STEP = "qemu-cpuinfo-nonx86-evidence"
QEMU_CPUINFO_NONX86_REQUIRE_ENV = "SIMD_FREEZE_REQUIRE_QEMU_CPUINFO_NONX86_EVIDENCE"
QEMU_CPUINFO_NONX86_PLATFORM_ENV = (
    "SIMD_QEMU_PLATFORMS='linux/arm/v7 linux/arm64 linux/riscv64' "
)
QEMU_CPUINFO_NONX86_GATE_CMD = (
    "FAFAFA_BUILD_MODE=Release "
    + QEMU_CPUINFO_NONX86_PLATFORM_ENV
    +
    "SIMD_GATE_QEMU_NONX86_EVIDENCE=0 "
    "SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=1 "
    "SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE=0 "
    "SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_REPEAT=0 "
    "SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE=0 "
    "bash tests/fafafa.core.simd/BuildOrTest.sh gate"
)
QEMU_CPUINFO_NONX86_FULL_STEP = "qemu-cpuinfo-nonx86-full-evidence"
QEMU_CPUINFO_NONX86_FULL_REQUIRE_ENV = "SIMD_FREEZE_REQUIRE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE"
QEMU_CPUINFO_NONX86_FULL_PLATFORM_ENV = (
    "SIMD_QEMU_PLATFORMS='linux/arm/v7 linux/arm64 linux/riscv64' "
)
QEMU_CPUINFO_NONX86_FULL_GATE_CMD = (
    "FAFAFA_BUILD_MODE=Release "
    + QEMU_CPUINFO_NONX86_FULL_PLATFORM_ENV
    +
    "SIMD_GATE_QEMU_NONX86_EVIDENCE=0 "
    "SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=0 "
    "SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE=1 "
    "SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE=0 "
    "bash tests/fafafa.core.simd/BuildOrTest.sh gate"
)
QEMU_CPUINFO_NONX86_FULL_REPEAT_STEP = "qemu-cpuinfo-nonx86-full-repeat"
QEMU_CPUINFO_NONX86_FULL_REPEAT_REQUIRE_ENV = (
    "SIMD_FREEZE_REQUIRE_QEMU_CPUINFO_NONX86_FULL_REPEAT"
)
QEMU_CPUINFO_NONX86_FULL_REPEAT_GATE_CMD = (
    "FAFAFA_BUILD_MODE=Release "
    + QEMU_CPUINFO_NONX86_FULL_PLATFORM_ENV
    +
    "SIMD_GATE_QEMU_NONX86_EVIDENCE=0 "
    "SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=0 "
    "SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE=0 "
    "SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_REPEAT=1 "
    "SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE=0 "
    "bash tests/fafafa.core.simd/BuildOrTest.sh gate"
)
CROSS_GATE_FAIL_CLOSE_CMD = (
    "FAFAFA_BUILD_MODE=Release "
    "SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 "
    "bash tests/fafafa.core.simd/BuildOrTest.sh gate"
)
CPUINFO_LAZY_REPEAT_STEP = "cpuinfo-lazy-repeat"
CPUINFO_LAZY_REPEAT_REQUIRE_ENV = "SIMD_FREEZE_REQUIRE_CPUINFO_LAZY_REPEAT"
CPUINFO_LAZY_REPEAT_GATE_CMD = (
    "FAFAFA_BUILD_MODE=Release "
    "SIMD_GATE_CPUINFO_LAZY_REPEAT=5 "
    "SIMD_GATE_QEMU_NONX86_EVIDENCE=0 "
    "SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=0 "
    "SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE=0 "
    "bash tests/fafafa.core.simd/BuildOrTest.sh gate"
)
QEMU_CPUINFO_NONX86_REQUIRED_PLATFORMS = (
    "linux/arm/v7",
    "linux/arm64",
    "linux/riscv64",
)
QEMU_CPUINFO_NONX86_SCENARIO = "cpuinfo-nonx86-evidence"
QEMU_CPUINFO_NONX86_FULL_SCENARIO = "cpuinfo-nonx86-full-evidence"
QEMU_CPUINFO_NONX86_FULL_REPEAT_SCENARIO = "cpuinfo-nonx86-full-repeat"
QEMU_MULTIARCH_DIR_RE = re.compile(r"^qemu-multiarch-(\d{8})-(\d{6})$")


@dataclass
class CheckItem:
    name: str
    required: bool
    status: str
    detail: str


def compute_ready(check_items: List[CheckItem], include_windows: bool) -> bool:
    for item in check_items:
        if not item.required:
            continue
        if not include_windows and item.name.startswith("cross_"):
            continue
        if not include_windows and item.name.startswith("windows_"):
            continue
        if item.status in {"PENDING", "FAIL"}:
            return False
    return True


def parse_gate_summary_rows(summary_path: Path) -> List[Dict[str, str]]:
    if not summary_path.is_file():
        return []

    rows: List[Dict[str, str]] = []
    for raw_line in summary_path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw_line.strip()
        if not line.startswith("|"):
            continue
        if line.startswith("| Time |") or line.startswith("|---"):
            continue

        cells = [part.strip() for part in line.strip("|").split("|")]
        if len(cells) < 7:
            continue

        rows.append(
            {
                "time": cells[0],
                "step": cells[1],
                "status": cells[2],
                "duration_ms": cells[3],
                "event": cells[4],
                "detail": cells[5],
                "artifacts": cells[6],
            }
        )

    return rows


def extract_latest_gate_run(rows: List[Dict[str, str]]) -> Optional[List[Dict[str, str]]]:
    if not rows:
        return None

    terminal_idx: Optional[int] = None
    for idx in range(len(rows) - 1, -1, -1):
        row = rows[idx]
        if row.get("step") == "gate" and row.get("status") in {"PASS", "FAIL"}:
            terminal_idx = idx
            break

    if terminal_idx is None:
        return None

    start_idx = 0
    for idx in range(terminal_idx, -1, -1):
        row = rows[idx]
        if row.get("step") == "gate" and row.get("status") == "START":
            start_idx = idx
            break

    return rows[start_idx : terminal_idx + 1]


def check_line_markdown_x(path: Path, contains_text: str) -> Optional[bool]:
    if not path.is_file():
        return None

    for line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        if contains_text in line:
            return line.strip().startswith("- [x]")
    return False


def run_verify_script(verify_script: Path, log_path: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["bash", str(verify_script), str(log_path)],
        text=True,
        capture_output=True,
        check=False,
    )


def parse_bool_env(name: str, default: bool = False) -> bool:
    raw = os.environ.get(name)
    if raw is None:
        return default
    normalized = raw.strip().lower()
    if normalized in {"1", "true", "yes", "on"}:
        return True
    if normalized in {"0", "false", "no", "off", ""}:
        return False
    return default


def build_required_gate_steps(
    include_windows_evidence_step: bool,
    include_qemu_cpuinfo_nonx86_step: bool = False,
    include_qemu_cpuinfo_nonx86_full_step: bool = False,
    include_qemu_cpuinfo_nonx86_full_repeat_step: bool = False,
    include_cpuinfo_lazy_repeat_step: bool = False,
) -> List[str]:
    steps = list(REQUIRED_GATE_STEPS_BASE)
    if include_windows_evidence_step:
        steps.append("evidence-verify")
    if include_qemu_cpuinfo_nonx86_step:
        steps.append(QEMU_CPUINFO_NONX86_STEP)
    if include_qemu_cpuinfo_nonx86_full_step:
        steps.append(QEMU_CPUINFO_NONX86_FULL_STEP)
    if include_qemu_cpuinfo_nonx86_full_repeat_step:
        steps.append(QEMU_CPUINFO_NONX86_FULL_REPEAT_STEP)
    if include_cpuinfo_lazy_repeat_step:
        steps.append(CPUINFO_LAZY_REPEAT_STEP)
    return steps


def evaluate_required_gate_steps(
    run_rows: List[Dict[str, str]], required_steps: List[str]
) -> tuple[bool, str]:
    step_status: Dict[str, str] = {}
    step_detail: Dict[str, str] = {}
    for row in run_rows:
        step = row.get("step", "")
        if step == "gate":
            continue
        step_status[step] = row.get("status", "")
        step_detail[step] = row.get("detail", "")

    missing_steps: List[str] = []
    non_pass_steps: List[str] = []
    for required_step in required_steps:
        status = step_status.get(required_step)
        if status is None:
            missing_steps.append(required_step)
        elif (
            required_step == "evidence-verify"
            and status == "PASS"
            and "skip" in step_detail.get(required_step, "").lower()
        ):
            non_pass_steps.append("evidence-verify=SKIP(marked-as-pass)")
        elif status != "PASS":
            non_pass_steps.append(f"{required_step}={status}")

    if missing_steps or non_pass_steps:
        parts: List[str] = []
        if missing_steps:
            parts.append(f"missing: {', '.join(missing_steps)}")
        if non_pass_steps:
            parts.append(f"non-pass: {', '.join(non_pass_steps)}")
        return False, "; ".join(parts)

    return True, "all required gate steps are PASS (no SKIP/FAIL)"


def find_latest_step_row(run_rows: List[Dict[str, str]], step_name: str) -> Optional[Dict[str, str]]:
    for row in reversed(run_rows):
        if row.get("step") == step_name:
            return row
    return None


def parse_gate_row_time(row: Dict[str, str]) -> Optional[datetime]:
    raw = row.get("time", "").strip()
    if not raw or raw == "-":
        return None
    try:
        return datetime.strptime(raw, "%Y-%m-%d %H:%M:%S")
    except ValueError:
        return None


def freshness_check(name: str, path: Path, max_age_hours: float, required: bool = True) -> CheckItem:
    if not path.is_file():
        return CheckItem(name=name, required=required, status="FAIL", detail=f"missing {path}")

    now = datetime.now()
    mtime = datetime.fromtimestamp(path.stat().st_mtime)
    age_hours = (now - mtime).total_seconds() / 3600.0

    if age_hours <= max_age_hours:
        return CheckItem(
            name=name,
            required=required,
            status="PASS",
            detail=(
                f"mtime={mtime:%Y-%m-%d %H:%M:%S}, age_hours={age_hours:.2f}, "
                f"threshold_hours={max_age_hours:.2f}"
            ),
        )

    return CheckItem(
        name=name,
        required=required,
        status="FAIL",
        detail=(
            f"stale mtime={mtime:%Y-%m-%d %H:%M:%S}, age_hours={age_hours:.2f}, "
            f"threshold_hours={max_age_hours:.2f}"
        ),
    )


def parse_default_fresh_hours() -> float:
    raw = os.environ.get("SIMD_FREEZE_MAX_AGE_HOURS", "72")
    try:
        value = float(raw)
    except ValueError:
        return 72.0
    if value <= 0:
        return 72.0
    return value


def parse_qemu_summary(summary_path: Path) -> Optional[Dict[str, object]]:
    if not summary_path.is_file():
        return None

    scenario = ""
    platform_status: Dict[str, str] = {}
    for raw_line in summary_path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw_line.strip()
        if line.startswith("- scenario:"):
            scenario = line.split(":", 1)[1].strip()
            continue

        if not line.startswith("|"):
            continue
        if line.startswith("| Platform |") or line.startswith("|---"):
            continue

        cells = [part.strip() for part in line.strip("|").split("|")]
        if len(cells) < 2:
            continue

        platform = cells[0]
        status = cells[1]
        if platform:
            platform_status[platform] = status

    if not scenario:
        return None

    return {"scenario": scenario, "platform_status": platform_status}


def parse_qemu_multiarch_batch_time(summary_path: Path) -> Optional[datetime]:
    match = QEMU_MULTIARCH_DIR_RE.match(summary_path.parent.name)
    if match is None:
        return None
    raw_batch = f"{match.group(1)}{match.group(2)}"
    try:
        return datetime.strptime(raw_batch, "%Y%m%d%H%M%S")
    except ValueError:
        return None


def find_latest_qemu_summary_for_scenario(
    logs_dir: Path, scenario: str, not_after: Optional[datetime] = None
) -> Optional[Path]:
    candidates: List[tuple[datetime, Path]] = []
    for summary_path in logs_dir.glob("qemu-multiarch-*/summary.md"):
        parsed = parse_qemu_summary(summary_path)
        if parsed is None:
            continue
        if parsed.get("scenario") != scenario:
            continue

        batch_time = parse_qemu_multiarch_batch_time(summary_path)
        sort_time = batch_time or datetime.fromtimestamp(summary_path.stat().st_mtime)
        if not_after is not None and sort_time > not_after:
            continue

        candidates.append((sort_time, summary_path))

    if not candidates:
        return None

    candidates.sort(key=lambda item: item[0], reverse=True)
    return candidates[0][1]


def qemu_platform_coverage_check(
    name: str,
    logs_dir: Path,
    scenario: str,
    required_platforms: List[str],
    required: bool,
    gate_step_time: Optional[datetime] = None,
) -> CheckItem:
    summary_path = find_latest_qemu_summary_for_scenario(logs_dir, scenario, not_after=gate_step_time)
    if summary_path is None:
        if gate_step_time is None:
            miss_detail = f"missing qemu summary for scenario={scenario}"
        else:
            miss_detail = (
                f"missing qemu summary for scenario={scenario} at/before "
                f"gate-step-time={gate_step_time:%Y-%m-%d %H:%M:%S}"
            )
        return CheckItem(
            name=name,
            required=required,
            status="FAIL" if required else "SKIP",
            detail=miss_detail,
        )

    parsed = parse_qemu_summary(summary_path)
    if parsed is None:
        return CheckItem(
            name=name,
            required=required,
            status="FAIL" if required else "SKIP",
            detail=f"invalid qemu summary format: {summary_path}",
        )

    platform_status = parsed.get("platform_status", {})
    if not isinstance(platform_status, dict):
        return CheckItem(
            name=name,
            required=required,
            status="FAIL" if required else "SKIP",
            detail=f"invalid qemu platform table in {summary_path}",
        )

    missing: List[str] = []
    non_pass: List[str] = []
    for platform in required_platforms:
        status = platform_status.get(platform)
        if status is None:
            missing.append(platform)
        elif status != "PASS":
            non_pass.append(f"{platform}={status}")

    if missing or non_pass:
        parts: List[str] = [f"summary={summary_path}"]
        if missing:
            parts.append(f"missing: {', '.join(missing)}")
        if non_pass:
            parts.append(f"non-pass: {', '.join(non_pass)}")
        return CheckItem(
            name=name,
            required=required,
            status="FAIL" if required else "SKIP",
            detail="; ".join(parts),
        )

    return CheckItem(
        name=name,
        required=required,
        status="PASS",
        detail=(
            f"summary={summary_path}, "
            f"required platforms PASS: {', '.join(required_platforms)}"
        ),
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Evaluate SIMD cross-platform freeze readiness")
    parser.add_argument(
        "--root",
        default=str(Path(__file__).resolve().parent),
        help="Path to tests/fafafa.core.simd directory",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print JSON payload to stdout",
    )
    parser.add_argument(
        "--json-file",
        default="",
        help="Write JSON payload to file",
    )
    parser.add_argument(
        "--linux-only",
        action="store_true",
        help="Evaluate Linux mainline readiness only (ignore Windows closeout items)",
    )
    parser.add_argument(
        "--fresh-hours",
        type=float,
        default=parse_default_fresh_hours(),
        help="Maximum acceptable artifact age in hours (default: env SIMD_FREEZE_MAX_AGE_HOURS or 72)",
    )
    args = parser.parse_args()

    root = Path(args.root).resolve()
    repo_root = root.parent.parent
    logs_dir = root / "logs"

    gate_summary = logs_dir / "gate_summary.md"
    windows_log = logs_dir / "windows_b07_gate.log"
    windows_log_sim = logs_dir / "windows_b07_gate.simulated.log"
    closeout_summary = logs_dir / "windows_b07_closeout_summary.md"
    closeout_summary_sim = logs_dir / "windows_b07_closeout_summary.simulated.md"

    verify_script = root / "verify_windows_b07_evidence.sh"

    roadmap_doc = repo_root / "docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md"
    matrix_doc = root / "docs/simd_completeness_matrix.md"
    rc_doc = root / "docs/simd_release_candidate_checklist.md"

    checks: List[CheckItem] = []
    next_actions: List[str] = []
    default_batch_id = f"SIMD-{datetime.now():%Y%m%d}-152"
    require_qemu_cpuinfo_nonx86_step = parse_bool_env(
        QEMU_CPUINFO_NONX86_REQUIRE_ENV, default=False
    )
    require_qemu_cpuinfo_nonx86_full_step = parse_bool_env(
        QEMU_CPUINFO_NONX86_FULL_REQUIRE_ENV, default=False
    )
    require_qemu_cpuinfo_nonx86_full_repeat_step = parse_bool_env(
        QEMU_CPUINFO_NONX86_FULL_REPEAT_REQUIRE_ENV, default=False
    )
    require_cpuinfo_lazy_repeat_step = parse_bool_env(
        CPUINFO_LAZY_REPEAT_REQUIRE_ENV, default=False
    )
    required_gate_steps_mainline = build_required_gate_steps(
        include_windows_evidence_step=False,
        include_qemu_cpuinfo_nonx86_step=require_qemu_cpuinfo_nonx86_step,
        include_qemu_cpuinfo_nonx86_full_step=require_qemu_cpuinfo_nonx86_full_step,
        include_qemu_cpuinfo_nonx86_full_repeat_step=require_qemu_cpuinfo_nonx86_full_repeat_step,
        include_cpuinfo_lazy_repeat_step=require_cpuinfo_lazy_repeat_step,
    )
    required_gate_steps_cross = build_required_gate_steps(
        include_windows_evidence_step=True,
        include_qemu_cpuinfo_nonx86_step=require_qemu_cpuinfo_nonx86_step,
        include_qemu_cpuinfo_nonx86_full_step=require_qemu_cpuinfo_nonx86_full_step,
        include_qemu_cpuinfo_nonx86_full_repeat_step=require_qemu_cpuinfo_nonx86_full_repeat_step,
        include_cpuinfo_lazy_repeat_step=require_cpuinfo_lazy_repeat_step,
    )
    required_gate_steps = (
        required_gate_steps_mainline if args.linux_only else required_gate_steps_cross
    )

    rows = parse_gate_summary_rows(gate_summary)
    latest_gate_run = extract_latest_gate_run(rows)
    if latest_gate_run is None:
        checks.append(
            CheckItem(
                name="linux_gate_summary",
                required=True,
                status="FAIL",
                detail=f"missing terminal gate row in {gate_summary}",
            )
        )
        next_actions.append("bash tests/fafafa.core.simd/BuildOrTest.sh gate")
    else:
        terminal_row = latest_gate_run[-1]
        required_ok_mainline, required_detail_mainline = evaluate_required_gate_steps(
            latest_gate_run, required_gate_steps_mainline
        )
        required_ok_cross, required_detail_cross = evaluate_required_gate_steps(
            latest_gate_run, required_gate_steps_cross
        )

        if terminal_row["status"] == "PASS":
            checks.append(
                CheckItem(
                    name="linux_gate_summary",
                    required=True,
                    status="PASS",
                    detail=(
                        f"gate PASS at {terminal_row['time']}, event={terminal_row['event']}, "
                        f"duration_ms={terminal_row['duration_ms']}"
                    ),
                )
            )
        elif required_ok_mainline:
            checks.append(
                CheckItem(
                    name="linux_gate_summary",
                    required=True,
                    status="PASS",
                    detail=(
                        "latest gate terminal status is FAIL but all mainline-required "
                        "steps are PASS"
                    ),
                )
            )
        else:
            checks.append(
                CheckItem(
                    name="linux_gate_summary",
                    required=True,
                    status="FAIL",
                    detail=(
                        f"latest gate status={terminal_row['status']} at {terminal_row['time']} "
                        f"(detail={terminal_row['detail']})"
                    ),
                )
            )
            next_actions.append("bash tests/fafafa.core.simd/BuildOrTest.sh gate")

        checks.append(
            CheckItem(
                name="linux_gate_required_steps_mainline",
                required=True,
                status="PASS" if required_ok_mainline else "FAIL",
                detail=required_detail_mainline,
            )
        )
        if not required_ok_mainline:
            next_actions.append("bash tests/fafafa.core.simd/BuildOrTest.sh gate")

        if args.linux_only:
            checks.append(
                CheckItem(
                    name="cross_gate_required_steps",
                    required=False,
                    status="SKIP",
                    detail="linux-only mode: cross gate step check skipped",
                )
            )
        else:
            checks.append(
                CheckItem(
                    name="cross_gate_required_steps",
                    required=True,
                    status="PASS" if required_ok_cross else "FAIL",
                    detail=required_detail_cross,
                )
            )
            if not required_ok_cross:
                next_actions.append("bash tests/fafafa.core.simd/BuildOrTest.sh gate")

        qemu_cpuinfo_nonx86_row = find_latest_step_row(
            latest_gate_run, QEMU_CPUINFO_NONX86_STEP
        )
        if qemu_cpuinfo_nonx86_row is None:
            checks.append(
                CheckItem(
                    name="linux_qemu_cpuinfo_nonx86_evidence",
                    required=require_qemu_cpuinfo_nonx86_step,
                    status="FAIL" if require_qemu_cpuinfo_nonx86_step else "SKIP",
                    detail=(
                        f"missing {QEMU_CPUINFO_NONX86_STEP} in latest gate run; "
                        f"set {QEMU_CPUINFO_NONX86_REQUIRE_ENV}=1 to require this step"
                    ),
                )
            )
            if require_qemu_cpuinfo_nonx86_step:
                next_actions.append(QEMU_CPUINFO_NONX86_GATE_CMD)
        else:
            qemu_cpuinfo_nonx86_status = qemu_cpuinfo_nonx86_row.get("status", "")
            qemu_cpuinfo_nonx86_detail = qemu_cpuinfo_nonx86_row.get("detail", "")
            if qemu_cpuinfo_nonx86_status == "PASS":
                checks.append(
                    CheckItem(
                        name="linux_qemu_cpuinfo_nonx86_evidence",
                        required=require_qemu_cpuinfo_nonx86_step,
                        status="PASS",
                        detail=(
                            f"step PASS at {qemu_cpuinfo_nonx86_row.get('time', '-')}, "
                            f"event={qemu_cpuinfo_nonx86_row.get('event', '-')}, "
                            f"duration_ms={qemu_cpuinfo_nonx86_row.get('duration_ms', '-')}"
                        ),
                    )
                )
                qemu_cpuinfo_nonx86_step_time = parse_gate_row_time(qemu_cpuinfo_nonx86_row)
                coverage_check = qemu_platform_coverage_check(
                    name="linux_qemu_cpuinfo_nonx86_evidence_platforms",
                    logs_dir=logs_dir,
                    scenario=QEMU_CPUINFO_NONX86_SCENARIO,
                    required_platforms=list(QEMU_CPUINFO_NONX86_REQUIRED_PLATFORMS),
                    required=require_qemu_cpuinfo_nonx86_step,
                    gate_step_time=qemu_cpuinfo_nonx86_step_time,
                )
                checks.append(coverage_check)
                if coverage_check.status == "FAIL":
                    next_actions.append(QEMU_CPUINFO_NONX86_GATE_CMD)
            elif (
                qemu_cpuinfo_nonx86_status == "SKIP"
                and not require_qemu_cpuinfo_nonx86_step
            ):
                checks.append(
                    CheckItem(
                        name="linux_qemu_cpuinfo_nonx86_evidence",
                        required=False,
                        status="SKIP",
                        detail=(
                            f"step SKIP in latest gate run ({qemu_cpuinfo_nonx86_detail}); "
                            f"set {QEMU_CPUINFO_NONX86_REQUIRE_ENV}=1 to enforce"
                        ),
                    )
                )
            else:
                checks.append(
                    CheckItem(
                        name="linux_qemu_cpuinfo_nonx86_evidence",
                        required=require_qemu_cpuinfo_nonx86_step,
                        status="FAIL",
                        detail=(
                            f"step status={qemu_cpuinfo_nonx86_status} "
                            f"(detail={qemu_cpuinfo_nonx86_detail})"
                        ),
                    )
                )
                next_actions.append(QEMU_CPUINFO_NONX86_GATE_CMD)

        qemu_cpuinfo_nonx86_full_row = find_latest_step_row(
            latest_gate_run, QEMU_CPUINFO_NONX86_FULL_STEP
        )
        if qemu_cpuinfo_nonx86_full_row is None:
            checks.append(
                CheckItem(
                    name="linux_qemu_cpuinfo_nonx86_full_evidence",
                    required=require_qemu_cpuinfo_nonx86_full_step,
                    status="FAIL" if require_qemu_cpuinfo_nonx86_full_step else "SKIP",
                    detail=(
                        f"missing {QEMU_CPUINFO_NONX86_FULL_STEP} in latest gate run; "
                        f"set {QEMU_CPUINFO_NONX86_FULL_REQUIRE_ENV}=1 to require this step"
                    ),
                )
            )
            if require_qemu_cpuinfo_nonx86_full_step:
                next_actions.append(QEMU_CPUINFO_NONX86_FULL_GATE_CMD)
        else:
            qemu_cpuinfo_nonx86_full_status = qemu_cpuinfo_nonx86_full_row.get("status", "")
            qemu_cpuinfo_nonx86_full_detail = qemu_cpuinfo_nonx86_full_row.get("detail", "")
            if qemu_cpuinfo_nonx86_full_status == "PASS":
                checks.append(
                    CheckItem(
                        name="linux_qemu_cpuinfo_nonx86_full_evidence",
                        required=require_qemu_cpuinfo_nonx86_full_step,
                        status="PASS",
                        detail=(
                            f"step PASS at {qemu_cpuinfo_nonx86_full_row.get('time', '-')}, "
                            f"event={qemu_cpuinfo_nonx86_full_row.get('event', '-')}, "
                            f"duration_ms={qemu_cpuinfo_nonx86_full_row.get('duration_ms', '-')}"
                        ),
                    )
                )
                qemu_cpuinfo_nonx86_full_step_time = parse_gate_row_time(
                    qemu_cpuinfo_nonx86_full_row
                )
                coverage_check = qemu_platform_coverage_check(
                    name="linux_qemu_cpuinfo_nonx86_full_evidence_platforms",
                    logs_dir=logs_dir,
                    scenario=QEMU_CPUINFO_NONX86_FULL_SCENARIO,
                    required_platforms=list(QEMU_CPUINFO_NONX86_REQUIRED_PLATFORMS),
                    required=require_qemu_cpuinfo_nonx86_full_step,
                    gate_step_time=qemu_cpuinfo_nonx86_full_step_time,
                )
                checks.append(coverage_check)
                if coverage_check.status == "FAIL":
                    next_actions.append(QEMU_CPUINFO_NONX86_FULL_GATE_CMD)
            elif (
                qemu_cpuinfo_nonx86_full_status == "SKIP"
                and not require_qemu_cpuinfo_nonx86_full_step
            ):
                checks.append(
                    CheckItem(
                        name="linux_qemu_cpuinfo_nonx86_full_evidence",
                        required=False,
                        status="SKIP",
                        detail=(
                            f"step SKIP in latest gate run ({qemu_cpuinfo_nonx86_full_detail}); "
                            f"set {QEMU_CPUINFO_NONX86_FULL_REQUIRE_ENV}=1 to enforce"
                        ),
                    )
                )
            else:
                checks.append(
                    CheckItem(
                        name="linux_qemu_cpuinfo_nonx86_full_evidence",
                        required=require_qemu_cpuinfo_nonx86_full_step,
                        status="FAIL",
                        detail=(
                            f"step status={qemu_cpuinfo_nonx86_full_status} "
                            f"(detail={qemu_cpuinfo_nonx86_full_detail})"
                        ),
                    )
                )
                next_actions.append(QEMU_CPUINFO_NONX86_FULL_GATE_CMD)

        qemu_cpuinfo_nonx86_full_repeat_row = find_latest_step_row(
            latest_gate_run, QEMU_CPUINFO_NONX86_FULL_REPEAT_STEP
        )
        if qemu_cpuinfo_nonx86_full_repeat_row is None:
            checks.append(
                CheckItem(
                    name="linux_qemu_cpuinfo_nonx86_full_repeat",
                    required=require_qemu_cpuinfo_nonx86_full_repeat_step,
                    status="FAIL" if require_qemu_cpuinfo_nonx86_full_repeat_step else "SKIP",
                    detail=(
                        f"missing {QEMU_CPUINFO_NONX86_FULL_REPEAT_STEP} in latest gate run; "
                        f"set {QEMU_CPUINFO_NONX86_FULL_REPEAT_REQUIRE_ENV}=1 to require this step"
                    ),
                )
            )
            if require_qemu_cpuinfo_nonx86_full_repeat_step:
                next_actions.append(QEMU_CPUINFO_NONX86_FULL_REPEAT_GATE_CMD)
        else:
            qemu_cpuinfo_nonx86_full_repeat_status = qemu_cpuinfo_nonx86_full_repeat_row.get(
                "status", ""
            )
            qemu_cpuinfo_nonx86_full_repeat_detail = qemu_cpuinfo_nonx86_full_repeat_row.get(
                "detail", ""
            )
            if qemu_cpuinfo_nonx86_full_repeat_status == "PASS":
                checks.append(
                    CheckItem(
                        name="linux_qemu_cpuinfo_nonx86_full_repeat",
                        required=require_qemu_cpuinfo_nonx86_full_repeat_step,
                        status="PASS",
                        detail=(
                            f"step PASS at {qemu_cpuinfo_nonx86_full_repeat_row.get('time', '-')}, "
                            f"event={qemu_cpuinfo_nonx86_full_repeat_row.get('event', '-')}, "
                            f"duration_ms={qemu_cpuinfo_nonx86_full_repeat_row.get('duration_ms', '-')}"
                        ),
                    )
                )
                qemu_cpuinfo_nonx86_full_repeat_step_time = parse_gate_row_time(
                    qemu_cpuinfo_nonx86_full_repeat_row
                )
                coverage_check = qemu_platform_coverage_check(
                    name="linux_qemu_cpuinfo_nonx86_full_repeat_platforms",
                    logs_dir=logs_dir,
                    scenario=QEMU_CPUINFO_NONX86_FULL_REPEAT_SCENARIO,
                    required_platforms=list(QEMU_CPUINFO_NONX86_REQUIRED_PLATFORMS),
                    required=require_qemu_cpuinfo_nonx86_full_repeat_step,
                    gate_step_time=qemu_cpuinfo_nonx86_full_repeat_step_time,
                )
                checks.append(coverage_check)
                if coverage_check.status == "FAIL":
                    next_actions.append(QEMU_CPUINFO_NONX86_FULL_REPEAT_GATE_CMD)
            elif (
                qemu_cpuinfo_nonx86_full_repeat_status == "SKIP"
                and not require_qemu_cpuinfo_nonx86_full_repeat_step
            ):
                checks.append(
                    CheckItem(
                        name="linux_qemu_cpuinfo_nonx86_full_repeat",
                        required=False,
                        status="SKIP",
                        detail=(
                            f"step SKIP in latest gate run ({qemu_cpuinfo_nonx86_full_repeat_detail}); "
                            f"set {QEMU_CPUINFO_NONX86_FULL_REPEAT_REQUIRE_ENV}=1 to enforce"
                        ),
                    )
                )
            else:
                checks.append(
                    CheckItem(
                        name="linux_qemu_cpuinfo_nonx86_full_repeat",
                        required=require_qemu_cpuinfo_nonx86_full_repeat_step,
                        status="FAIL",
                        detail=(
                            f"step status={qemu_cpuinfo_nonx86_full_repeat_status} "
                            f"(detail={qemu_cpuinfo_nonx86_full_repeat_detail})"
                        ),
                    )
                )
                next_actions.append(QEMU_CPUINFO_NONX86_FULL_REPEAT_GATE_CMD)

        cpuinfo_lazy_repeat_row = find_latest_step_row(
            latest_gate_run, CPUINFO_LAZY_REPEAT_STEP
        )
        if cpuinfo_lazy_repeat_row is None:
            checks.append(
                CheckItem(
                    name="linux_cpuinfo_lazy_repeat",
                    required=require_cpuinfo_lazy_repeat_step,
                    status="FAIL" if require_cpuinfo_lazy_repeat_step else "SKIP",
                    detail=(
                        f"missing {CPUINFO_LAZY_REPEAT_STEP} in latest gate run; "
                        f"set {CPUINFO_LAZY_REPEAT_REQUIRE_ENV}=1 to require this step"
                    ),
                )
            )
            if require_cpuinfo_lazy_repeat_step:
                next_actions.append(CPUINFO_LAZY_REPEAT_GATE_CMD)
        else:
            cpuinfo_lazy_repeat_status = cpuinfo_lazy_repeat_row.get("status", "")
            cpuinfo_lazy_repeat_detail = cpuinfo_lazy_repeat_row.get("detail", "")
            if cpuinfo_lazy_repeat_status == "PASS":
                checks.append(
                    CheckItem(
                        name="linux_cpuinfo_lazy_repeat",
                        required=require_cpuinfo_lazy_repeat_step,
                        status="PASS",
                        detail=(
                            f"step PASS at {cpuinfo_lazy_repeat_row.get('time', '-')}, "
                            f"event={cpuinfo_lazy_repeat_row.get('event', '-')}, "
                            f"duration_ms={cpuinfo_lazy_repeat_row.get('duration_ms', '-')}"
                        ),
                    )
                )
            elif (
                cpuinfo_lazy_repeat_status == "SKIP"
                and not require_cpuinfo_lazy_repeat_step
            ):
                checks.append(
                    CheckItem(
                        name="linux_cpuinfo_lazy_repeat",
                        required=False,
                        status="SKIP",
                        detail=(
                            f"step SKIP in latest gate run ({cpuinfo_lazy_repeat_detail}); "
                            f"set {CPUINFO_LAZY_REPEAT_REQUIRE_ENV}=1 to enforce"
                        ),
                    )
                )
            else:
                checks.append(
                    CheckItem(
                        name="linux_cpuinfo_lazy_repeat",
                        required=require_cpuinfo_lazy_repeat_step,
                        status="FAIL",
                        detail=(
                            f"step status={cpuinfo_lazy_repeat_status} "
                            f"(detail={cpuinfo_lazy_repeat_detail})"
                        ),
                    )
                )
                next_actions.append(CPUINFO_LAZY_REPEAT_GATE_CMD)

    checks.append(freshness_check("linux_gate_summary_freshness", gate_summary, args.fresh_hours, required=True))
    if checks[-1].status != "PASS":
        next_actions.append("bash tests/fafafa.core.simd/BuildOrTest.sh gate")

    if windows_log.is_file():
        checks.append(
            CheckItem(
                name="windows_evidence_log",
                required=True,
                status="PASS",
                detail=f"found {windows_log}",
            )
        )
    elif windows_log_sim.is_file():
        checks.append(
            CheckItem(
                name="windows_evidence_log",
                required=True,
                status="FAIL",
                detail=(
                    f"real log missing ({windows_log}), only simulated exists ({windows_log_sim})"
                ),
            )
        )
        next_actions.append("tests\\fafafa.core.simd\\buildOrTest.bat evidence-win-verify")
    else:
        checks.append(
            CheckItem(
                name="windows_evidence_log",
                required=True,
                status="FAIL",
                detail=f"missing {windows_log}",
            )
        )
        next_actions.append("tests\\fafafa.core.simd\\buildOrTest.bat evidence-win-verify")

    checks.append(freshness_check("windows_evidence_freshness", windows_log, args.fresh_hours, required=True))
    if checks[-1].status != "PASS":
        next_actions.append("tests\\fafafa.core.simd\\buildOrTest.bat evidence-win-verify")

    windows_verify_ok: Optional[bool] = None
    if args.linux_only:
        windows_verify_ok = None
        checks.append(
            CheckItem(
                name="windows_evidence_verify",
                required=False,
                status="SKIP",
                detail="linux-only mode: verifier skipped",
            )
        )
    elif windows_log.is_file() and verify_script.is_file():
        verify_proc = run_verify_script(verify_script, windows_log)
        if verify_proc.returncode == 0:
            windows_verify_ok = True
            checks.append(
                CheckItem(
                    name="windows_evidence_verify",
                    required=True,
                    status="PASS",
                    detail="verify_windows_b07_evidence.sh passed",
                )
            )
        else:
            windows_verify_ok = False
            stderr_msg = (verify_proc.stderr or "").strip()
            stdout_msg = (verify_proc.stdout or "").strip()
            detail_msg = stderr_msg if stderr_msg else stdout_msg
            checks.append(
                CheckItem(
                    name="windows_evidence_verify",
                    required=True,
                    status="FAIL",
                    detail=f"verifier failed rc={verify_proc.returncode}: {detail_msg}",
                )
            )
            next_actions.append("tests\\fafafa.core.simd\\buildOrTest.bat evidence-win-verify")
    elif not verify_script.is_file():
        windows_verify_ok = False
        checks.append(
            CheckItem(
                name="windows_evidence_verify",
                required=True,
                status="FAIL",
                detail=f"missing verifier script: {verify_script}",
            )
        )
    else:
        windows_verify_ok = False
        checks.append(
            CheckItem(
                name="windows_evidence_verify",
                required=True,
                status="FAIL",
                detail="skip until real windows evidence log is available",
            )
        )

    if closeout_summary.is_file():
        summary_text = closeout_summary.read_text(encoding="utf-8", errors="ignore")
        has_result_pass = "- Result: PASS" in summary_text
        has_result_fail = "- Result: FAIL" in summary_text
        if windows_verify_ok is True:
            if has_result_pass:
                checks.append(
                    CheckItem(
                        name="windows_closeout_summary",
                        required=True,
                        status="PASS",
                        detail=f"summary matches verifier PASS: {closeout_summary}",
                    )
                )
            else:
                checks.append(
                    CheckItem(
                        name="windows_closeout_summary",
                        required=True,
                        status="FAIL",
                        detail=(
                            "summary missing '- Result: PASS' while verifier passes: "
                            f"{closeout_summary}"
                        ),
                    )
                )
        elif windows_verify_ok is False:
            if has_result_fail:
                checks.append(
                    CheckItem(
                        name="windows_closeout_summary",
                        required=True,
                        status="PASS",
                        detail=f"summary matches verifier FAIL: {closeout_summary}",
                    )
                )
            else:
                checks.append(
                    CheckItem(
                        name="windows_closeout_summary",
                        required=True,
                        status="FAIL",
                        detail=(
                            "stale/invalid closeout summary: verifier fails but summary "
                            "missing '- Result: FAIL': "
                            f"{closeout_summary}"
                        ),
                    )
                )
        elif has_result_pass or has_result_fail:
            checks.append(
                CheckItem(
                    name="windows_closeout_summary",
                    required=True,
                    status="PASS",
                    detail=f"summary contains result marker: {closeout_summary}",
                )
            )
        else:
            checks.append(
                CheckItem(
                    name="windows_closeout_summary",
                    required=True,
                    status="FAIL",
                    detail=(
                        "summary missing '- Result: PASS' or '- Result: FAIL': "
                        f"{closeout_summary}"
                    ),
                )
            )
    elif closeout_summary_sim.is_file():
        checks.append(
            CheckItem(
                name="windows_closeout_summary",
                required=True,
                status="FAIL",
                detail=(
                    f"real closeout summary missing ({closeout_summary}), "
                    f"only simulated exists ({closeout_summary_sim})"
                ),
            )
        )
        next_actions.append(
            f"bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize {default_batch_id}"
        )
    else:
        checks.append(
            CheckItem(
                name="windows_closeout_summary",
                required=True,
                status="FAIL",
                detail=f"missing {closeout_summary}",
            )
        )
        next_actions.append(
            f"bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize {default_batch_id}"
        )

    if checks and checks[-1].name == "windows_closeout_summary" and checks[-1].status != "PASS":
        next_actions.append(
            f"bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize {default_batch_id}"
        )

    checks.append(freshness_check("windows_closeout_freshness", closeout_summary, args.fresh_hours, required=True))
    if checks[-1].status != "PASS":
        next_actions.append(
            f"bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize {default_batch_id}"
        )

    roadmap_closed = check_line_markdown_x(roadmap_doc, "Windows 实机证据")
    if roadmap_closed is True:
        checks.append(CheckItem("roadmap_windows_closed", False, "PASS", "roadmap checkbox is [x]"))
    elif roadmap_closed is False:
        checks.append(CheckItem("roadmap_windows_closed", False, "PENDING", "roadmap Windows closeout checkbox still open"))
    else:
        checks.append(CheckItem("roadmap_windows_closed", False, "FAIL", f"missing doc: {roadmap_doc}"))

    rc_closed = check_line_markdown_x(rc_doc, "Windows 实机证据日志已归档")
    if rc_closed is True:
        checks.append(CheckItem("rc_windows_closed", False, "PASS", "RC checklist Windows evidence row is [x]"))
    elif rc_closed is False:
        checks.append(CheckItem("rc_windows_closed", False, "PENDING", "RC checklist Windows evidence row still [ ]"))
    else:
        checks.append(CheckItem("rc_windows_closed", False, "FAIL", f"missing doc: {rc_doc}"))

    matrix_text = matrix_doc.read_text(encoding="utf-8", errors="ignore") if matrix_doc.is_file() else ""
    if not matrix_text:
        checks.append(CheckItem("matrix_windows_closed", False, "FAIL", f"missing doc: {matrix_doc}"))
    elif "Windows 证据：实机日志已归档" in matrix_text or "[x] Windows 实机证据已归档" in matrix_text:
        checks.append(CheckItem("matrix_windows_closed", False, "PASS", "completeness matrix marks Windows evidence as archived"))
    else:
        checks.append(CheckItem("matrix_windows_closed", False, "PENDING", "completeness matrix still indicates pending Windows evidence"))

    if args.linux_only:
        for item in checks:
            if item.name.startswith("windows_"):
                item.required = False
                if item.status in {"FAIL", "PENDING"}:
                    item.status = "SKIP"
                    item.detail = f"linux-only mode: {item.detail}"

        next_actions = [
            action
            for action in next_actions
            if "buildOrTest.bat" not in action
            and "finalize-win-evidence" not in action
            and "win-evidence-preflight" not in action
            and "win-closeout-" not in action
        ]

    mainline_ready = compute_ready(checks, include_windows=False)
    if args.linux_only:
        cross_ready: Optional[bool] = None
        freeze_ready = mainline_ready
    else:
        cross_ready = compute_ready(checks, include_windows=True)
        freeze_ready = cross_ready

    if not freeze_ready and not args.linux_only:
        preferred_actions = [
            "bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight",
            (
                "FAFAFA_BUILD_MODE=Release "
                f"bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-via-gh {default_batch_id}"
            ),
            "tests\\fafafa.core.simd\\buildOrTest.bat evidence-win-verify",
            CROSS_GATE_FAIL_CLOSE_CMD,
            f"bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize {default_batch_id}",
            f"bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-3cmd {default_batch_id}",
        ]
        next_actions = preferred_actions + next_actions
        next_actions = [
            action
            for action in next_actions
            if action != "bash tests/fafafa.core.simd/BuildOrTest.sh gate"
        ]

    dedup_actions: List[str] = []
    for action in next_actions:
        if action not in dedup_actions:
            dedup_actions.append(action)

    payload = {
        "mode": "linux-only" if args.linux_only else "cross-platform",
        "linux_only": args.linux_only,
        # Keep `ready` for backward-compatible consumers.
        "ready": freeze_ready,
        "freeze_ready": freeze_ready,
        "mainline_ready": mainline_ready,
        "cross_ready": cross_ready,
        "require_qemu_cpuinfo_nonx86_full_evidence": require_qemu_cpuinfo_nonx86_full_step,
        "require_qemu_cpuinfo_nonx86_full_repeat": require_qemu_cpuinfo_nonx86_full_repeat_step,
        "require_cpuinfo_lazy_repeat": require_cpuinfo_lazy_repeat_step,
        "root": str(root),
        "fresh_hours": args.fresh_hours,
        "required_gate_steps": required_gate_steps,
        "required_gate_steps_mainline": required_gate_steps_mainline,
        "required_gate_steps_cross": required_gate_steps_cross,
        "checks": [asdict(item) for item in checks],
        "next_actions": dedup_actions,
    }

    if args.json_file:
        json_path = Path(args.json_file)
        json_path.parent.mkdir(parents=True, exist_ok=True)
        json_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))

    display_checks = checks
    if args.linux_only:
        display_checks = [
            item
            for item in checks
            if "windows" not in item.name and not item.name.startswith("cross_")
        ]

    print("[FREEZE] SIMD freeze status")
    cross_ready_display = "N/A" if cross_ready is None else str(cross_ready)
    print(
        f"[FREEZE] mode={payload['mode']}, ready={payload['freeze_ready']}, "
        f"mainline-ready={mainline_ready}, cross-ready={cross_ready_display}, "
        f"fresh_hours={payload['fresh_hours']:.2f}"
    )
    for item in display_checks:
        print(f"[FREEZE] {item.status:<7} {item.name}: {item.detail}")

    if dedup_actions:
        print("[FREEZE] next-actions:")
        for action in dedup_actions:
            print(f"  - {action}")

    return 0 if freeze_ready else 1


if __name__ == "__main__":
    raise SystemExit(main())
