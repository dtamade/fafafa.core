#!/usr/bin/env bash
# Cross-platform build/test script for fafafa.core.crypto tests (Linux/macOS)
# Mirrors features of BuildOrTest.bat (Windows) with minimal, safe defaults.

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="${SCRIPT_DIR}/tests_crypto.lpi"
TEST_EXECUTABLE="${SCRIPT_DIR}/bin/tests_crypto"
REPORTS_DIR="${SCRIPT_DIR}/reports"

# Resolve lazbuild: prefer env LAZBUILD_EXE, else use lazbuild from PATH
LAZBUILD_EXE="${LAZBUILD_EXE:-}"
if [[ -z "${LAZBUILD_EXE}" ]]; then
  if command -v lazbuild >/dev/null 2>&1; then
    LAZBUILD_EXE="$(command -v lazbuild)"
  else
    echo "[ERROR] lazbuild not found. Please install Lazarus/FPC and ensure 'lazbuild' is in PATH or set LAZBUILD_EXE=/path/to/lazbuild" >&2
    exit 2
  fi
fi

# Parse args
AEAD_FLAG=0
HMAC_FLAG=0
CLEAN_FLAG=0
NO_NOANON=0
RUN_TESTS=0
for arg in "$@"; do
  case "${arg}" in
    aead|AEAD) AEAD_FLAG=1;;
    hmac|HMAC) HMAC_FLAG=1;;
    clean|CLEAN) CLEAN_FLAG=1;;
    NO_NOANON) NO_NOANON=1;;
    test|TEST) RUN_TESTS=1;;
  esac
done

# Select build mode
BUILD_MODE="Release"
if [[ ${AEAD_FLAG} -eq 1 ]]; then
  BUILD_MODE="AEAD"
  echo "[BuildOrTest] BuildMode: AEAD (defines -dFAFAFA_CORE_AEAD_TESTS)"
elif [[ ${HMAC_FLAG} -eq 1 ]]; then
  BUILD_MODE="HMAC-DEBUG"
  echo "[BuildOrTest] BuildMode: HMAC-DEBUG (adds -dHMAC_DEBUG)"
else
  echo "[BuildOrTest] BuildMode: Release (default)"
fi

# Clean outputs if requested
if [[ ${CLEAN_FLAG} -eq 1 ]]; then
  echo "[BuildOrTest] Cleaning output (lib/bin)"
  rm -rf "${SCRIPT_DIR}/lib" "${SCRIPT_DIR}/bin"
fi

FINAL_RC=0
RC_ON=0
RC_OFF=0

# Pass 1: anon=ON
echo "Building project (anon=ON): ${PROJECT}..."
"${LAZBUILD_EXE}" --build-mode="${BUILD_MODE}" "${PROJECT}"
if [[ $? -ne 0 ]]; then
  echo
  echo "Build failed (anon=ON)."
  exit 1
fi

echo
echo "Build successful (anon=ON)."
echo

if [[ ${RUN_TESTS} -eq 1 ]]; then
  echo "Running tests (anon=ON)..."
  mkdir -p "${REPORTS_DIR}"
  export FAFAFA_CORE_AEAD_DIAG=1
  "${TEST_EXECUTABLE}" --all --format=xml > "${REPORTS_DIR}/tests_crypto.junit.xml"
  RC_ON=$?
  # Rotate AEAD diag log if produced
  if [[ -f "${REPORTS_DIR}/aead_diag.log" ]]; then
    rm -f "${REPORTS_DIR}/aead_diag.on.log" 2>/dev/null || true
    mv "${REPORTS_DIR}/aead_diag.log" "${REPORTS_DIR}/aead_diag.on.log"
  fi
  echo "Test report saved to: ${REPORTS_DIR}/tests_crypto.junit.xml"
fi

# Pass 2: anon=OFF (unless NO_NOANON)
if [[ ${NO_NOANON} -eq 0 ]]; then
  echo
  echo "Building project (anon=OFF): ${PROJECT}..."
  "${LAZBUILD_EXE}" --build-mode=Release-NoAnon "${PROJECT}"
  if [[ $? -ne 0 ]]; then
    echo
    echo "Build failed (anon=OFF)."
    FINAL_RC=1
  else
    echo
    echo "Build successful (anon=OFF)."
    if [[ ${RUN_TESTS} -eq 1 ]]; then
      echo "Running tests (anon=OFF)..."
      export FAFAFA_CORE_AEAD_DIAG=1
      "${TEST_EXECUTABLE}" --all --format=xml > "${REPORTS_DIR}/tests_crypto_noanon.junit.xml"
      RC_OFF=$?
      if [[ -f "${REPORTS_DIR}/aead_diag.log" ]]; then
        rm -f "${REPORTS_DIR}/aead_diag.off.log" 2>/dev/null || true
        mv "${REPORTS_DIR}/aead_diag.log" "${REPORTS_DIR}/aead_diag.off.log"
      fi
      echo "Test report (anon=OFF) saved to: ${REPORTS_DIR}/tests_crypto_noanon.junit.xml"
    fi
  fi
else
  echo "Skipping anon=OFF second pass per NO_NOANON flag."
fi

# Consolidate RC, prefer test RCs
if [[ ${RC_ON} -ne 0 ]]; then FINAL_RC=${RC_ON}; fi
if [[ ${RC_OFF} -ne 0 ]]; then FINAL_RC=${RC_OFF}; fi

exit ${FINAL_RC}
