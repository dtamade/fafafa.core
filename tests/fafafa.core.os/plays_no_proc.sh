#!/usr/bin/env bash
# Quick local script to simulate minimal environment without /proc for manual checks
# WARNING: For local manual use only. It uses unshare/mount namespaces, needs CAP_SYS_ADMIN.
set -euo pipefail

if ! command -v unshare >/dev/null 2>&1; then
  echo "unshare not found; please install util-linux" >&2
  exit 1
fi

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT
mkdir -p "$workdir/root"

# Start a new mount namespace, do not mount /proc
unshare -Umnpf --mount-proc=false sh -c '
  set -e
  echo "Inside namespace (no /proc mounted):"
  mount | grep proc || true
  # Run tests binary if present, otherwise print a hint
  if [ -x ./tests/fafafa.core.os/bin/tests_os ]; then
    ./tests/fafafa.core.os/bin/tests_os -a -p --format=plain || true
  else
    echo "Run build first, then rerun this script." >&2
  fi
'

