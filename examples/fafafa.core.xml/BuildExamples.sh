#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LAZBUILD="${LAZBUILD:-lazbuild}"
BIN_DIR="${SCRIPT_DIR}/bin"
LIB_DIR="${SCRIPT_DIR}/lib/$(uname -m)-$(uname | tr '[:upper:]' '[:lower:]')"

mkdir -p "${BIN_DIR}" "${LIB_DIR}"

build_with_lazbuild() {
  local proj_lpi="$1"
  echo "[lazbuild] ${proj_lpi}"
  "${LAZBUILD}" "${proj_lpi}" --bm=Debug --ws=nogui || return 1
}

build_with_fpc() {
  local main_lpr="$1"
  local out_name="$2"
  echo "[fpc] ${main_lpr} -> ${BIN_DIR}/${out_name}"
  fpc -MObjFPC -Scaghi -O1 -g -gl -l -vewnhibq \
      -Fu"${ROOT_DIR}/src" -Fu"${SCRIPT_DIR}" \
      -Fi"${LIB_DIR}" -FU"${LIB_DIR}" -FE"${BIN_DIR}" \
      "${main_lpr}"
}

# Try lazbuild first, fallback to fpc
if command -v "${LAZBUILD}" >/dev/null 2>&1; then
  build_with_lazbuild "${SCRIPT_DIR}/example_xml_reader.lpi" || true
  build_with_lazbuild "${SCRIPT_DIR}/example_xml_writer.lpi" || true
fi

# If binaries not produced, fallback to fpc direct
[[ -x "${BIN_DIR}/example_xml_reader" || -x "${BIN_DIR}/example_xml_reader.exe" ]] || \
  build_with_fpc "${SCRIPT_DIR}/example_xml_reader.lpr" example_xml_reader
[[ -x "${BIN_DIR}/example_xml_writer" || -x "${BIN_DIR}/example_xml_writer.exe" ]] || \
  build_with_fpc "${SCRIPT_DIR}/example_xml_writer.lpr" example_xml_writer

echo "[OK] Examples built into ${BIN_DIR} (libs in ${LIB_DIR})"

