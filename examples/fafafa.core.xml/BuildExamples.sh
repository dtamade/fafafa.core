#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LAZBUILD_BIN="${LAZBUILD:-lazbuild}"
FPC_BIN="${FPC:-fpc}"
BIN_DIR="${SCRIPT_DIR}/bin"
LIB_DIR="${SCRIPT_DIR}/lib/$(uname -m)-$(uname | tr '[:upper:]' '[:lower:]')"

mkdir -p "${BIN_DIR}" "${LIB_DIR}"

resolve_lazbuild() {
  if command -v "${LAZBUILD_BIN}" >/dev/null 2>&1; then
    echo "${LAZBUILD_BIN}"
    return 0
  fi

  return 1
}

build_with_lazbuild() {
  local proj_lpi="$1"
  local laz

  laz="$(resolve_lazbuild)" || return 1
  echo "[BUILD] lazbuild ${proj_lpi} --ws=nogui (project default mode)"
  "${laz}" --ws=nogui "${proj_lpi}"
}

build_with_fpc() {
  local main_lpr="$1"
  local out_name="$2"

  echo "[BUILD] fpc ${main_lpr} -> ${BIN_DIR}/${out_name}"
  "${FPC_BIN}" -MObjFPC -Scaghi -O1 -g -gl -l -vewnhibq \
    -Fu"${ROOT_DIR}/src" -Fu"${SCRIPT_DIR}" \
    -Fi"${LIB_DIR}" -FU"${LIB_DIR}" -FE"${BIN_DIR}" \
    "${main_lpr}"
}

if build_with_lazbuild "${SCRIPT_DIR}/example_xml_reader.lpi"; then
  :
fi

if build_with_lazbuild "${SCRIPT_DIR}/example_xml_writer.lpi"; then
  :
fi

[[ -x "${BIN_DIR}/example_xml_reader" || -x "${BIN_DIR}/example_xml_reader.exe" ]] || \
  build_with_fpc "${SCRIPT_DIR}/example_xml_reader.lpr" example_xml_reader
[[ -x "${BIN_DIR}/example_xml_writer" || -x "${BIN_DIR}/example_xml_writer.exe" ]] || \
  build_with_fpc "${SCRIPT_DIR}/example_xml_writer.lpr" example_xml_writer

echo "[OK] Examples built into ${BIN_DIR} (libs in ${LIB_DIR})"
