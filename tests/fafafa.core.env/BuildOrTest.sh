#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(cd -- "$SCRIPT_DIR/../.." && pwd)

FPC_BIN=${FPC_BIN:-fpc}

CPU="$($FPC_BIN -iTP)"
OS="$($FPC_BIN -iTO)"
TRIPLET="${CPU}-${OS}"

# Try to infer FPC units root from the ppcx64 location.
UNITS_ROOT=""
PPC_BIN="$(command -v ppcx64 || true)"
if [[ -n "$PPC_BIN" ]]; then
  PPC_REAL="$(readlink -f "$PPC_BIN" 2>/dev/null || echo "$PPC_BIN")"
  # ppcx64 is usually: <FPC_ROOT>/bin/<triplet>/ppcx64
  FPC_ROOT_CANDIDATE="$(cd -- "$(dirname -- "$PPC_REAL")/../.." && pwd)"
  if [[ -d "$FPC_ROOT_CANDIDATE/units/$TRIPLET" ]]; then
    UNITS_ROOT="$FPC_ROOT_CANDIDATE/units/$TRIPLET"
  fi
fi

# Fallback candidates for distro installs.
if [[ -z "$UNITS_ROOT" ]]; then
  FPC_VER="$($FPC_BIN -iV 2>/dev/null || true)"
  for c in \
    "/usr/lib/fpc/${FPC_VER}/units/${TRIPLET}" \
    "/usr/lib/x86_64-linux-gnu/fpc/${FPC_VER}/units/${TRIPLET}" \
    "/usr/lib/fpc/units/${TRIPLET}" \
    "$HOME/freePascal/fpc/units/${TRIPLET}" \
    "$HOME/fpc/units/${TRIPLET}" \
    ; do
    if [[ -d "$c" ]]; then
      UNITS_ROOT="$c"
      break
    fi
  done
fi

FU=()
add_fu() {
  local d="$1"
  [[ -d "$d" ]] && FU+=("-Fu$d")
}

# Project sources
add_fu "$ROOT_DIR/src"
add_fu "$SCRIPT_DIR"

# FPC std + FCL units needed by FPCUnit console runner
if [[ -n "$UNITS_ROOT" ]]; then
  add_fu "$UNITS_ROOT/rtl"
  add_fu "$UNITS_ROOT/rtl-objpas"
  add_fu "$UNITS_ROOT/fcl-base"
  add_fu "$UNITS_ROOT/fcl-xml"
  add_fu "$UNITS_ROOT/fcl-fpcunit"
fi

BIN_DIR="$SCRIPT_DIR/bin"
mkdir -p "$BIN_DIR"

OUT_BIN="$BIN_DIR/fafafa.core.env.test"

echo "[env] Building tests (${TRIPLET})..."
"$FPC_BIN" \
  "${FU[@]}" \
  -dFAFAFA_ENV_DEBUG_ITER \
  -FE"$BIN_DIR" \
  -FU"$BIN_DIR" \
  -o"$OUT_BIN" \
  "$SCRIPT_DIR/fafafa.core.env.test.lpr"

echo

action="${1:-test}"
if [[ "$action" == "build" ]]; then
  echo "[env] Build OK (build-only)."
  exit 0
fi

echo "[env] Running tests..."
"$OUT_BIN" --all --format=plainnotiming
