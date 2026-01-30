#!/usr/bin/env bash
set -euo pipefail
# Run a quick set of demos for core.process (+ optional: thread/lockfree/crypto)
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Always run a couple of process demos (if present)
if [[ -f "${ROOT_DIR}/fafafa.core.process/build.sh" ]]; then
  bash "${ROOT_DIR}/fafafa.core.process/build.sh" || true
fi
if [[ -f "${ROOT_DIR}/fafafa.core.process/run_redirect_demo.sh" ]]; then
  bash "${ROOT_DIR}/fafafa.core.process/run_redirect_demo.sh" || true
fi

# Optional: quick thread demos
if [[ "${1:-}" == "thread" ]]; then
  echo "Running quick thread demos..."
  if [[ -f "${ROOT_DIR}/fafafa.core.thread/BuildOrRun.sh" ]]; then
    bash "${ROOT_DIR}/fafafa.core.thread/BuildOrRun.sh" run || true
  fi
fi

# Optional: quick lockfree demos
if [[ "${1:-}" == "lockfree" ]]; then
  echo "Running quick lockfree demos..."
  if [[ -f "${ROOT_DIR}/fafafa.core.lockfree/BuildOrRun.sh" ]]; then
    bash "${ROOT_DIR}/fafafa.core.lockfree/BuildOrRun.sh" run || true
  fi
fi

# Optional: quick crypto AEAD minimal demo
if [[ "${1:-}" == "crypto" ]]; then
  echo "Running quick crypto AEAD minimal demo..."
  if [[ -f "${ROOT_DIR}/fafafa.core.crypto/BuildOrRun_MinExample.sh" ]]; then
    bash "${ROOT_DIR}/fafafa.core.crypto/BuildOrRun_MinExample.sh" || true
  fi
fi

# Optional: quick crypto file encryption demo
if [[ "${1:-}" == "fileenc" ]]; then
  echo "Running quick crypto file encryption demo..."
  if [[ -f "${ROOT_DIR}/fafafa.core.crypto/BuildOrRun_FileEncryption.sh" ]]; then
    bash "${ROOT_DIR}/fafafa.core.crypto/BuildOrRun_FileEncryption.sh" || true
  fi
fi

echo "All quick demos finished."
