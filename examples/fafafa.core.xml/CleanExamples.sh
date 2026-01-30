#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rm -rf "${SCRIPT_DIR}/bin" "${SCRIPT_DIR}/lib" || true
echo "Cleaned examples output folders."

