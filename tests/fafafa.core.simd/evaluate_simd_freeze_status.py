#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import subprocess
from dataclasses import dataclass, asdict
from datetime import datetime
from pathlib import Path
from typing import List, Optional, Dict, Tuple


@dataclass
class CheckItem:
    name: str
    required: bool
    status: str
    detail: str


def parse_markdown_table_rows(summary_path: Path) -> List[List[str]]:
    if not summary_path.is_file():
        return []

    rows: List[List[str]] = []
    for raw_line in summary_path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw_line.strip()
        if not line.startswith("|"):
            continue
        if line.startswith("|---"):
            continue
        cells = [part.strip() for part in line.strip("|").split("|")]
        rows.append(cells)
    return rows


def find_latest_summary(logs_dir: Path, prefix: str) -> Optional[Path]:
    candidates = sorted(logs_dir.glob(f"{prefix}-*/summary.md"))
    if not candidates:
        return None
    return candidates[-1]


def read_qemu_summary_status(summary_path: Path) -> Tuple[Optional[bool], str]:
    if not summary_path or not summary_path.is_file():
        return None, "summary missing"

    rows = parse_markdown_table_rows(summary_path)
    result_rows = [row for row in rows if len(row) >= 3 and row[0] not in {"Platform", "Step"}]
    if not result_rows:
        return None, f"no result rows in {summary_path}"

    failed = [row for row in result_rows if row[1] != "PASS"]
    if failed:
        detail = ", ".join(f"{row[0]}={row[1]}" for row in failed)
        return False, f"{summary_path}: {detail}"
    return True, f"all rows PASS in {summary_path}"


def find_latest_summary_for_scenario(logs_dir: Path, prefix: str, scenario: str) -> Optional[Path]:
    candidates = sorted(logs_dir.glob(f"{prefix}-*/summary.md"))
    matched: List[Path] = []
    for path in candidates:
        content = path.read_text(encoding="utf-8", errors="ignore")
        if f"scenario: {scenario}" in content or f"requested-scenario: {scenario}" in content:
            matched.append(path)
    if not matched:
        return None
    return matched[-1]


def read_rvv_lane_status(summary_path: Path) -> Tuple[Optional[bool], str]:
    if not summary_path or not summary_path.is_file():
        return None, "summary missing"

    rows = parse_markdown_table_rows(summary_path)
    step_rows = [row for row in rows if len(row) >= 3 and row[0] not in {"Step", "Platform"}]
    if not step_rows:
        return None, f"no layered acceptance rows in {summary_path}"

    compile_status = None
    smoke_status = None
    bench_status = None
    for row in step_rows:
        step = row[0].lower()
        status = row[1]
        if step == "compile-only":
            compile_status = status
        elif step.startswith("stable-smoke") or step.startswith("suite"):
            smoke_status = status
        elif step == "bench":
            bench_status = status

    if compile_status != "PASS":
        return False, f"{summary_path}: compile-only={compile_status or 'missing'}"
    if smoke_status != "PASS":
        return False, f"{summary_path}: stable-smoke={smoke_status or 'missing'}"
    if bench_status not in {None, "PASS", "SKIP"}:
        return False, f"{summary_path}: bench={bench_status}"

    detail = f"compile-only=PASS, stable-smoke=PASS, bench={bench_status or 'missing'} in {summary_path}"
    return True, detail


def parse_gate_summary_last_gate_status(summary_path: Path) -> Optional[Dict[str, str]]:
    if not summary_path.is_file():
        return None

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

    gate_rows = [row for row in rows if row.get("step") == "gate"]
    if not gate_rows:
        return None

    return gate_rows[-1]


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
        "--mode",
        choices=["cross-platform", "linux", "full-platform"],
        default="cross-platform",
        help="Freeze evaluation mode",
    )
    args = parser.parse_args()

    if args.linux_only:
        args.mode = "linux"

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

    if args.mode == "linux":
        args.mode = "linux"

    checks: List[CheckItem] = []
    next_actions: List[str] = []
    default_batch_id = f"SIMD-{datetime.now():%Y%m%d}-152"

    if gate_summary.is_file():
        last_gate = parse_gate_summary_last_gate_status(gate_summary)
        if last_gate is None:
            checks.append(
                CheckItem(
                    name="linux_gate_summary",
                    required=True,
                    status="FAIL",
                    detail=f"missing gate row in {gate_summary}",
                )
            )
            next_actions.append("bash tests/fafafa.core.simd/BuildOrTest.sh gate")
        elif last_gate["status"] == "PASS":
            checks.append(
                CheckItem(
                    name="linux_gate_summary",
                    required=True,
                    status="PASS",
                    detail=(
                        f"gate PASS at {last_gate['time']}, event={last_gate['event']}, "
                        f"duration_ms={last_gate['duration_ms']}"
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
                        f"latest gate status={last_gate['status']} at {last_gate['time']} "
                        f"(detail={last_gate['detail']})"
                    ),
                )
            )
            next_actions.append("bash tests/fafafa.core.simd/BuildOrTest.sh gate")
    else:
        checks.append(
            CheckItem(
                name="linux_gate_summary",
                required=True,
                status="FAIL",
                detail=f"missing {gate_summary}",
            )
        )
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
                status="PENDING",
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
                status="PENDING",
                detail=f"missing {windows_log}",
            )
        )
        next_actions.append("tests\\fafafa.core.simd\\buildOrTest.bat evidence-win-verify")

    if windows_log.is_file() and verify_script.is_file():
        verify_proc = run_verify_script(verify_script, windows_log)
        if verify_proc.returncode == 0:
            checks.append(
                CheckItem(
                    name="windows_evidence_verify",
                    required=True,
                    status="PASS",
                    detail="verify_windows_b07_evidence.sh passed",
                )
            )
        else:
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
            next_actions.append("tests\\fafafa.core.simd\\buildOrTest.bat verify-win-evidence")
    elif not verify_script.is_file():
        checks.append(
            CheckItem(
                name="windows_evidence_verify",
                required=True,
                status="FAIL",
                detail=f"missing verifier script: {verify_script}",
            )
        )
    else:
        checks.append(
            CheckItem(
                name="windows_evidence_verify",
                required=True,
                status="PENDING",
                detail="skip until real windows evidence log is available",
            )
        )

    if closeout_summary.is_file():
        checks.append(
            CheckItem(
                name="windows_closeout_summary",
                required=True,
                status="PASS",
                detail=f"found {closeout_summary}",
            )
        )
    elif closeout_summary_sim.is_file():
        checks.append(
            CheckItem(
                name="windows_closeout_summary",
                required=True,
                status="PENDING",
                detail=(
                    f"real closeout summary missing ({closeout_summary}), "
                    f"only simulated exists ({closeout_summary_sim})"
                ),
            )
        )
        next_actions.append("bash tests/fafafa.core.simd/BuildOrTest.sh finalize-win-evidence")
    else:
        checks.append(
            CheckItem(
                name="windows_closeout_summary",
                required=True,
                status="PENDING",
                detail=f"missing {closeout_summary}",
            )
        )
        next_actions.append("bash tests/fafafa.core.simd/BuildOrTest.sh finalize-win-evidence")

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

    if args.mode == "full-platform":
        qemu_arch_summary = find_latest_summary_for_scenario(logs_dir, "qemu-multiarch", "arch-matrix-evidence")
        qemu_arch_pass, qemu_arch_detail = read_qemu_summary_status(qemu_arch_summary)
        checks.append(
            CheckItem(
                name="qemu_arch_matrix",
                required=True,
                status="PASS" if qemu_arch_pass else ("FAIL" if qemu_arch_pass is False else "PENDING"),
                detail=qemu_arch_detail if qemu_arch_summary else "missing fresh qemu arch-matrix summary",
            )
        )
        if qemu_arch_pass is not True:
            next_actions.append("bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arch-matrix-evidence")

        qemu_cpuinfo_summary = find_latest_summary_for_scenario(logs_dir, "qemu-multiarch", "cpuinfo-nonx86-full-evidence")
        qemu_cpuinfo_pass, qemu_cpuinfo_detail = read_qemu_summary_status(qemu_cpuinfo_summary)
        checks.append(
            CheckItem(
                name="qemu_cpuinfo_nonx86_full",
                required=True,
                status="PASS" if qemu_cpuinfo_pass else ("FAIL" if qemu_cpuinfo_pass is False else "PENDING"),
                detail=qemu_cpuinfo_detail if qemu_cpuinfo_summary else "missing fresh qemu cpuinfo non-x86 full summary",
            )
        )
        if qemu_cpuinfo_pass is not True:
            next_actions.append("bash tests/fafafa.core.simd/BuildOrTest.sh qemu-cpuinfo-nonx86-full-evidence")

        rvv_summary = find_latest_summary(logs_dir, "rvv-opcode-lane")
        rvv_pass, rvv_detail = read_rvv_lane_status(rvv_summary)
        checks.append(
            CheckItem(
                name="riscvv_opcode_lane",
                required=True,
                status="PASS" if rvv_pass else ("FAIL" if rvv_pass is False else "PENDING"),
                detail=rvv_detail if rvv_summary else "missing RVV opcode lane summary",
            )
        )
        if rvv_pass is not True:
            next_actions.append("bash tests/fafafa.core.simd/BuildOrTest.sh riscvv-opcode-lane")

    matrix_text = matrix_doc.read_text(encoding="utf-8", errors="ignore") if matrix_doc.is_file() else ""
    if not matrix_text:
        checks.append(CheckItem("matrix_windows_closed", False, "FAIL", f"missing doc: {matrix_doc}"))
    elif "Windows 证据：实机日志已归档" in matrix_text or "[x] Windows 实机证据已归档" in matrix_text:
        checks.append(CheckItem("matrix_windows_closed", False, "PASS", "completeness matrix marks Windows evidence as archived"))
    else:
        checks.append(CheckItem("matrix_windows_closed", False, "PENDING", "completeness matrix still indicates pending Windows evidence"))

    if args.mode == "linux":
        for item in checks:
            if (
                item.name.startswith("windows_")
                or item.name in {"roadmap_windows_closed", "rc_windows_closed", "matrix_windows_closed"}
            ):
                item.required = False
                item.status = "SKIP"
                item.detail = f"linux-only mode: {item.detail}"

        next_actions = [
            action
            for action in next_actions
            if "buildOrTest.bat" not in action
            and "finalize-win-evidence" not in action
            and "win-closeout-" not in action
        ]

    if any(item.status in {"PENDING", "FAIL"} for item in checks if item.required):
        freeze_ready = False
    else:
        freeze_ready = True

    if not freeze_ready and args.mode == "cross-platform":
        next_actions.append(f"bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize {default_batch_id}")
        next_actions.append(f"bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-3cmd {default_batch_id}")

    dedup_actions: List[str] = []
    for action in next_actions:
        if action not in dedup_actions:
            dedup_actions.append(action)

    payload = {
        "mode": args.mode,
        "freeze_ready": freeze_ready,
        "root": str(root),
        "checks": [asdict(item) for item in checks],
        "next_actions": dedup_actions,
    }

    if args.json_file:
        json_path = Path(args.json_file)
        json_path.parent.mkdir(parents=True, exist_ok=True)
        json_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))

    print("[FREEZE] SIMD freeze status")
    print(f"[FREEZE] mode={payload['mode']}, ready={payload['freeze_ready']}")
    for item in checks:
        print(f"[FREEZE] {item.status:<7} {item.name}: {item.detail}")

    if dedup_actions:
        print("[FREEZE] next-actions:")
        for action in dedup_actions:
            print(f"  - {action}")

    return 0 if freeze_ready else 1


if __name__ == "__main__":
    raise SystemExit(main())
