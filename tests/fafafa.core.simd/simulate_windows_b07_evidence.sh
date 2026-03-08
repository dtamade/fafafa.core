#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
LOG_PATH="${1:-${ROOT}/logs/windows_b07_gate.simulated.log}"
LOG_DIR="$(dirname "${LOG_PATH}")"

mkdir -p "${LOG_DIR}"

cat > "${LOG_PATH}" <<EOM
[B07] Windows evidence capture
[B07] Simulated: yes
[B07] Source: simulate_windows_b07_evidence.sh
[B07] Started: $(date '+%Y-%m-%d %H:%M:%S %z')
[B07] Working dir: C:\\simulated\\fafafa.core\\tests\\fafafa.core.simd
[B07] Command: buildOrTest.bat gate

[GATE] 1/6 Build + check SIMD module
[GATE] 2/6 SIMD list suites
[GATE] 3/6 SIMD AVX2 fallback suite
[GATE] 4/6 CPUInfo portable suites
[GATE] 5/6 CPUInfo x86 suites
[GATE] 6/6 Filtered run_all chain
[GATE] OK

[B07] GATE_EXIT_CODE=0

[B07] run_all summary snapshot
Total:  3
Passed: 3
Failed: 0
[B07] Total: 3
[B07] Passed: 3
[B07] Failed: 0
EOM

echo "[CLOSEOUT] Simulated evidence log written: ${LOG_PATH}"
