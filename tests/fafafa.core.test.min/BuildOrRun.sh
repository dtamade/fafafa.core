#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
LAZBUILD="${SCRIPT_DIR}/../../tools/lazbuild.sh"
if [[ ! -x "${LAZBUILD}" ]]; then
  echo "[INFO] tools/lazbuild.sh not found or not executable, using lazbuild in PATH"
  LAZBUILD="lazbuild"
fi

PROJECT_LPI="${SCRIPT_DIR}/tests_core_min.lpi"
PROJECT_LPR="${SCRIPT_DIR}/tests_core_min.lpr"
if [[ -f "${PROJECT_LPI}" ]]; then PROJECT="${PROJECT_LPI}"; else PROJECT="${PROJECT_LPR}"; fi
BIN_DIR="${SCRIPT_DIR}/bin"
OUT_DIR="${SCRIPT_DIR}/out"
EXE="${BIN_DIR}/tests_core_min"

mkdir -p "${BIN_DIR}" "${SCRIPT_DIR}/lib" "${OUT_DIR}"

cmd="${1:-run}"
shift || true

print_summary() {
  echo "Artifacts:"
  [[ -x "${EXE}" ]] && echo "  EXE: ${EXE}"
  [[ -f "${BIN_DIR}/__last_build.log" ]] && echo "  LOG: ${BIN_DIR}/__last_build.log"
  [[ -f "${OUT_DIR}/report.json" ]] && echo "  JSON: ${OUT_DIR}/report.json"
  [[ -f "${OUT_DIR}/junit.xml" ]] && echo "  JUNIT: ${OUT_DIR}/junit.xml"
}


case "${cmd}" in
  build)
    set +e
    "${LAZBUILD}" "${PROJECT}" >"${BIN_DIR}/__last_build.log" 2>&1
    CODE=$?
    set -e
    if [[ ${CODE} -ne 0 ]]; then
      echo "Build failed with code ${CODE}."
      if grep -q "Invalid compiler" "${BIN_DIR}/__last_build.log" 2>/dev/null; then
        echo
        echo "[Hint] lazbuild 报告 Invalid compiler \"\": 可能是 Lazarus/FPC 工具链未初始化。"
        echo "       解决方法："
        echo "       1) 打开一次 Lazarus IDE 完成初始配置；或"
        echo "       2) 先运行主套件：tests/fafafa.core.test/BuildOrTest.bat test（Windows），"
        echo "          或 tests/fafafa.core.test/BuildOrTest.sh test（Linux/macOS）"
        echo "       然后再执行本脚本 build"
        echo
      fi
      cat "${BIN_DIR}/__last_build.log" || true
      exit ${CODE}
    fi
    echo "Build successful."; print_summary
    ;;
  run)
    if [[ ! -x "${EXE}" ]]; then
      echo "[INFO] Executable not found, building first..."
      "${LAZBUILD}" "${PROJECT}"
    fi
    "${EXE}" "$@"; print_summary
    ;;
  run-json)
    if [[ ! -x "${EXE}" ]]; then
      echo "[INFO] Executable not found, building first..."
      "${LAZBUILD}" "${PROJECT}"
    fi
    export FAFAFA_TEST_USE_SINK_JSON=1
    "${EXE}" --json="${OUT_DIR}/report.json" "$@"; print_summary
    ;;
  run-junit)
    if [[ ! -x "${EXE}" ]]; then
      echo "[INFO] Executable not found, building first..."
      "${LAZBUILD}" "${PROJECT}"
    fi
    "${EXE}" --junit="${OUT_DIR}/junit.xml" "$@"; print_summary
    ;;
  *)
    echo "Usage: $(basename "$0") [build|run|run-json|run-junit [args...]]"
    exit 2
    ;;
 esac

