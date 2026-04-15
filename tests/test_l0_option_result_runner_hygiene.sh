#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

for dir in \
  "tests/fafafa.core.option" \
  "tests/fafafa.core.result"
do
  [[ -f "${dir}/BuildOrTest.bat" ]] || { echo "[FAIL] missing ${dir}/BuildOrTest.bat"; exit 1; }
  [[ -f "${dir}/BuildOrTest.sh" ]] || { echo "[FAIL] missing ${dir}/BuildOrTest.sh"; exit 1; }
  [[ ! -e "${dir}/buildOrTest.bat" ]] || { echo "[FAIL] stale lowercase runner remains in ${dir}"; exit 1; }
done

echo "[PASS] strict L0 option/result runners are aligned with current batch hygiene"
