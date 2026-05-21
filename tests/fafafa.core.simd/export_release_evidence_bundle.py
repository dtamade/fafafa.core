#!/usr/bin/env python3
"""Aggregate SIMD release evidence artifacts into one machine-readable bundle."""

from __future__ import annotations

import argparse
import json
from datetime import datetime
from pathlib import Path
from typing import Any


def load_required_json(path: Path, label: str) -> dict[str, Any]:
    if not path.is_file():
        raise FileNotFoundError(f"missing {label}: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def load_optional_json(path: Path | None) -> dict[str, Any] | None:
    if path is None or not path.is_file():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def artifact_entry(path: Path | None) -> dict[str, Any] | None:
    if path is None:
        return None

    entry: dict[str, Any] = {
        "path": str(path),
        "exists": path.exists(),
    }
    if path.exists():
        stat = path.stat()
        entry["size_bytes"] = stat.st_size
        entry["mtime"] = datetime.fromtimestamp(stat.st_mtime).isoformat(timespec="seconds")
    return entry


def iso_timestamp_from_mtime(path: Path) -> str:
    return datetime.fromtimestamp(path.stat().st_mtime).isoformat(timespec="seconds")


def find_latest_step(rows: list[dict[str, Any]], step_name: str) -> dict[str, Any] | None:
    for row in reversed(rows):
        if row.get("step") == step_name:
            return row
    return None


def summarize_gate_rows(rows: list[dict[str, Any]]) -> dict[str, Any]:
    tracked_steps = [
        "gate",
        "build-check",
        "contract-signature",
        "publicabi-signature",
        "publicabi-smoke",
        "evidence-verify",
    ]
    return {
        "latest_rows": {
            step_name: find_latest_step(rows, step_name) for step_name in tracked_steps
        }
    }


def resolve_output_root_path(output_root: str | None, gate_summary_path: Path) -> Path | None:
    if output_root:
        return Path(output_root).resolve()
    if gate_summary_path.parent.name == "logs":
        return gate_summary_path.parent.parent.resolve()
    return None


def find_latest_native_evidence_dir(logs_dir: Path, backend: str) -> tuple[Path, str] | None:
    candidates: list[tuple[Path, str]] = []

    for path in logs_dir.glob(f"native-evidence-{backend}-*"):
        if path.is_dir():
            candidates.append((path.resolve(), "native-evidence"))

    gh_root = logs_dir / "native-evidence-gh" / backend
    if gh_root.is_dir():
        for path in gh_root.glob("run-*"):
            if path.is_dir():
                candidates.append((path.resolve(), "native-evidence-gh"))

    if not candidates:
        return None

    candidates.sort(key=lambda item: (item[0].stat().st_mtime, str(item[0])))
    return candidates[-1]


def summarize_native_evidence(logs_dir: Path, backend: str) -> dict[str, Any]:
    latest = find_latest_native_evidence_dir(logs_dir, backend)
    if latest is None:
        status = "blocked-external-runner" if backend == "riscvv" else "missing"
        return {
            "status": status,
            "path": None,
            "kind": None,
            "summary_exists": False,
            "dispatch_publicabi_log_exists": False,
            "source_revision_exists": False,
        }

    path, kind = latest
    summary_path = path / "summary.md"
    dispatch_log_path = path / "dispatch_publicabi.log"
    source_revision_path = path / "source_revision.txt"

    summary_exists = summary_path.is_file()
    status = "present" if summary_exists else "incomplete"

    return {
        "status": status,
        "path": str(path),
        "kind": kind,
        "mtime": iso_timestamp_from_mtime(path),
        "summary_exists": summary_exists,
        "dispatch_publicabi_log_exists": dispatch_log_path.is_file(),
        "source_revision_exists": source_revision_path.is_file(),
        "summary_path": str(summary_path) if summary_exists else None,
        "dispatch_publicabi_log_path": str(dispatch_log_path) if dispatch_log_path.is_file() else None,
        "source_revision_path": str(source_revision_path) if source_revision_path.is_file() else None,
    }


def build_closeout_policy() -> dict[str, Any]:
    return {
        "mode": "qemu-first",
        "release_ready_source": "freeze_status.freeze_ready",
        "native_evidence": {
            "riscvv": {
                "required_for_current_closeout": False,
                "desired_for_full_native_closeout": True,
            }
        },
    }


def build_external_blockers(native_evidence: dict[str, dict[str, Any]]) -> list[dict[str, Any]]:
    riscvv = native_evidence.get("riscvv", {})
    if riscvv.get("status") != "blocked-external-runner":
        return []

    return [
        {
            "id": "repo-visible-self-hosted-linux-riscv64-runner",
            "scope": "repo-ops",
            "status": "open",
            "affects": "fresh-riscvv-native-evidence",
            "detail": "fresh RISCVV native evidence requires a repo-visible self-hosted Linux/riscv64 runner; repo-ops must provide a working runner solution on a real riscv64 host, using a standard or custom/nonstandard integration that can actually execute the workflow",
        }
    ]


def main() -> int:
    parser = argparse.ArgumentParser(description="Export SIMD release evidence bundle")
    parser.add_argument("--output", required=True, help="Output JSON path")
    parser.add_argument("--profile", default="release-gate", help="Evidence profile name")
    parser.add_argument("--output-root", help="Output root used by gate artifacts")
    parser.add_argument("--gate-summary-json", required=True, help="Path to gate_summary.json")
    parser.add_argument("--dispatch-contract-json", help="Path to dispatch_contract_signature.json")
    parser.add_argument("--public-abi-json", help="Path to public_abi_signature.json")
    parser.add_argument("--freeze-status-json", help="Path to freeze_status.json")
    parser.add_argument("--require-freeze", action="store_true", help="Fail if freeze_status.json is missing")
    args = parser.parse_args()

    output_path = Path(args.output).resolve()
    gate_summary_path = Path(args.gate_summary_json).resolve()
    dispatch_contract_path = Path(args.dispatch_contract_json).resolve() if args.dispatch_contract_json else None
    public_abi_path = Path(args.public_abi_json).resolve() if args.public_abi_json else None
    freeze_status_path = Path(args.freeze_status_json).resolve() if args.freeze_status_json else None
    output_root_path = resolve_output_root_path(args.output_root, gate_summary_path)
    logs_dir = (output_root_path / "logs") if output_root_path is not None else gate_summary_path.parent

    gate_summary = load_required_json(gate_summary_path, "gate summary json")
    dispatch_contract = load_optional_json(dispatch_contract_path)
    public_abi = load_optional_json(public_abi_path)
    freeze_status = load_optional_json(freeze_status_path)

    if args.require_freeze and freeze_status is None:
        raise FileNotFoundError(f"missing required freeze status json: {freeze_status_path}")

    rows = gate_summary.get("rows", [])
    if not isinstance(rows, list):
        raise RuntimeError("gate summary json rows should be a list")

    native_evidence = {
        "neon": summarize_native_evidence(logs_dir, "neon"),
        "riscvv": summarize_native_evidence(logs_dir, "riscvv"),
    }
    closeout_policy = build_closeout_policy()
    external_blockers = build_external_blockers(native_evidence)

    payload = {
        "generated_at": datetime.now().isoformat(timespec="seconds"),
        "profile": args.profile,
        "output_root": None if output_root_path is None else str(output_root_path),
        "gate_summary": gate_summary,
        "gate_steps": summarize_gate_rows(rows),
        "dispatch_contract_signature": dispatch_contract,
        "public_abi_signature": public_abi,
        "freeze_status": freeze_status,
        "release_ready": None if freeze_status is None else freeze_status.get("freeze_ready"),
        "closeout_policy": closeout_policy,
        "native_evidence": native_evidence,
        "external_blockers": external_blockers,
        "artifacts": {
            "gate_summary_json": artifact_entry(gate_summary_path),
            "dispatch_contract_signature_json": artifact_entry(dispatch_contract_path),
            "public_abi_signature_json": artifact_entry(public_abi_path),
            "freeze_status_json": artifact_entry(freeze_status_path),
        },
    }

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
