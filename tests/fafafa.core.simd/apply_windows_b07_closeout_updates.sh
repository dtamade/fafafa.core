#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT_DEFAULT="$(cd "${ROOT}/../.." && pwd)"
REPO_ROOT="${REPO_ROOT_DEFAULT}"
SUMMARY_PATH="${ROOT}/logs/windows_b07_closeout_summary.md"
APPLY_MODE=0
ALLOW_SIMULATED=0
BATCH_ID=""
SKIP_STRUCTURED=0
FREEZE_JSON_PATH="${ROOT}/logs/freeze_status.json"

print_usage() {
  cat <<USAGE
Usage: $0 [summary-path] [--apply] [--allow-simulated] [--freeze-json <path>] [--target-root <path>] [--batch-id <id>]

Default summary:
  ${ROOT}/logs/windows_b07_closeout_summary.md

Modes:
  (default)            仅输出可粘贴回填片段（不改文件）
  --apply              直接更新目标文档（结构化替换 + 片段追加，幂等）
  --allow-simulated    允许使用 simulated summary 执行 --apply（仅测试用）
  --freeze-json <path> 指定 freeze-status JSON（默认 tests/fafafa.core.simd/logs/freeze_status.json）
  --target-root <path> 指定文档根目录（默认仓库根）
  --batch-id <id>      指定 progress 回填批次标识（默认自动生成）
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      print_usage
      exit 0
      ;;
    --apply)
      APPLY_MODE=1
      shift
      ;;
    --allow-simulated)
      ALLOW_SIMULATED=1
      shift
      ;;
    --freeze-json)
      if [[ $# -lt 2 ]]; then
        echo "[CLOSEOUT] Missing value for --freeze-json"
        exit 2
      fi
      FREEZE_JSON_PATH="$2"
      shift 2
      ;;
    --target-root)
      if [[ $# -lt 2 ]]; then
        echo "[CLOSEOUT] Missing value for --target-root"
        exit 2
      fi
      REPO_ROOT="$2"
      shift 2
      ;;
    --batch-id)
      if [[ $# -lt 2 ]]; then
        echo "[CLOSEOUT] Missing value for --batch-id"
        exit 2
      fi
      BATCH_ID="$2"
      shift 2
      ;;
    *)
      SUMMARY_PATH="$1"
      shift
      ;;
  esac
done

extract_freeze_field() {
  local aJsonPath
  local aField

  aJsonPath="$1"
  aField="$2"

  if command -v python3 >/dev/null 2>&1; then
    python3 - "${aJsonPath}" "${aField}" <<'PY'
import json
import sys

path = sys.argv[1]
field = sys.argv[2]

try:
    payload = json.loads(open(path, encoding="utf-8").read())
except Exception:
    print("")
    sys.exit(0)

value = payload.get(field, "")
if isinstance(value, bool):
    print("true" if value else "false")
else:
    print(str(value))
PY
    return 0
  fi

  if [[ "${aField}" == "freeze_ready" ]]; then
    if grep -E -- '"freeze_ready"[[:space:]]*:[[:space:]]*true' "${aJsonPath}" >/dev/null 2>&1; then
      echo "true"
      return 0
    fi
    if grep -E -- '"freeze_ready"[[:space:]]*:[[:space:]]*false' "${aJsonPath}" >/dev/null 2>&1; then
      echo "false"
      return 0
    fi
    echo ""
    return 0
  fi

  grep -E -- "\"${aField}\"[[:space:]]*:[[:space:]]*\"" "${aJsonPath}" \
    | head -n 1 \
    | sed -E "s/.*\"${aField}\"[[:space:]]*:[[:space:]]*\"([^\"]*)\".*/\1/" \
    || true
}

require_freeze_ready_for_apply() {
  local LMode
  local LFreezeReady

  if [[ ! -f "${FREEZE_JSON_PATH}" ]]; then
    echo "[CLOSEOUT] Refuse apply: freeze json missing: ${FREEZE_JSON_PATH}"
    echo "[CLOSEOUT] Run first: bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status"
    exit 2
  fi

  LMode="$(extract_freeze_field "${FREEZE_JSON_PATH}" "mode" | tr -d '\r' | xargs)"
  LFreezeReady="$(extract_freeze_field "${FREEZE_JSON_PATH}" "freeze_ready" | tr -d '\r' | tr '[:upper:]' '[:lower:]' | xargs)"

  if [[ "${LMode}" != "cross-platform" ]]; then
    echo "[CLOSEOUT] Refuse apply: freeze mode must be cross-platform (actual='${LMode}')"
    echo "[CLOSEOUT] Run first: bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status"
    exit 1
  fi

  if [[ "${LFreezeReady}" != "true" ]]; then
    echo "[CLOSEOUT] Refuse apply: freeze_ready=${LFreezeReady:-<empty>} (json=${FREEZE_JSON_PATH})"
    echo "[CLOSEOUT] Run first: bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status"
    exit 1
  fi

  echo "[CLOSEOUT] Freeze guard OK: mode=${LMode}, freeze_ready=${LFreezeReady}"
}

if [[ ! -f "${SUMMARY_PATH}" ]]; then
  if [[ "${SUMMARY_PATH}" == "${ROOT}/logs/windows_b07_closeout_summary.md" && -f "${ROOT}/logs/windows_b07_closeout_summary.simulated.md" ]]; then
    SUMMARY_PATH="${ROOT}/logs/windows_b07_closeout_summary.simulated.md"
    echo "[CLOSEOUT] Fallback to simulated summary: ${SUMMARY_PATH}"
  else
    echo "[CLOSEOUT] Missing summary: ${SUMMARY_PATH}"
    exit 2
  fi
fi

if [[ "${APPLY_MODE}" == "1" && "${ALLOW_SIMULATED}" != "1" && "${SUMMARY_PATH}" == *".simulated."* ]]; then
  echo "[CLOSEOUT] Refuse to apply with simulated summary without --allow-simulated"
  exit 2
fi

if [[ "${APPLY_MODE}" == "1" && "${ALLOW_SIMULATED}" == "1" && "${SUMMARY_PATH}" == *".simulated."* ]]; then
  SKIP_STRUCTURED=1
  echo "[CLOSEOUT] WARN: simulated summary apply mode enabled, structured replacements will be skipped"
fi

if [[ ! -d "${REPO_ROOT}" ]]; then
  echo "[CLOSEOUT] Missing target root: ${REPO_ROOT}"
  exit 2
fi

to_repo_relative() {
  local aPath

  aPath="$1"
  if [[ "${aPath}" == "${REPO_ROOT}/"* ]]; then
    echo "${aPath#${REPO_ROOT}/}"
    return 0
  fi

  echo "${aPath}"
}

extract_value() {
  local aRegex
  local aLine

  aRegex="$1"
  aLine="$(grep -E -- "${aRegex}" "${SUMMARY_PATH}" | head -n 1 || true)"
  echo "${aLine}"
}

verify_windows_evidence_live() {
  local aEvidencePath
  local LVerifier
  local LLogPath

  aEvidencePath="$1"
  LVerifier="${ROOT}/verify_windows_b07_evidence.sh"
  LLogPath="${aEvidencePath}"

  if [[ -z "${LLogPath}" ]]; then
    return 2
  fi

  if [[ "${LLogPath}" != /* ]]; then
    LLogPath="${REPO_ROOT}/${LLogPath}"
  fi

  if [[ ! -x "${LVerifier}" ]]; then
    return 2
  fi
  if [[ ! -f "${LLogPath}" ]]; then
    return 2
  fi

  if "${LVerifier}" "${LLogPath}" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

LGeneratedLine="$(extract_value '^- Generated:[[:space:]]')"
LEvidenceLine="$(extract_value '^- Evidence Log:[[:space:]]')"

LDate="$(echo "${LGeneratedLine}" | sed -E 's/^- Generated:[[:space:]]*([0-9]{4}-[0-9]{2}-[0-9]{2}).*/\1/')"
if [[ -z "${LDate}" ]]; then
  LDate="$(date '+%Y-%m-%d')"
fi

LEvidencePath="$(echo "${LEvidenceLine}" | sed -E 's/^- Evidence Log:[[:space:]]*//')"
if [[ -z "${LEvidencePath}" ]]; then
  LEvidencePath="${ROOT}/logs/windows_b07_gate.log"
fi

LVerifierState="unknown"
if verify_windows_evidence_live "${LEvidencePath}"; then
  LVerifierState="pass"
else
  case "$?" in
    1) LVerifierState="fail" ;;
    *) LVerifierState="unknown" ;;
  esac
fi

LRelSummary="$(to_repo_relative "$(realpath "${SUMMARY_PATH}")")"
LRelEvidence="$(to_repo_relative "${LEvidencePath}")"
LMarker="SIMD-WIN-CLOSEOUT-${LDate}"

if [[ -z "${BATCH_ID}" ]]; then
  BATCH_ID="SIMD-WIN-CLOSEOUT-${LDate//-/}"
fi

LStatusLine='- 状态：已完成'
LMatrixHeadline="- Windows 实机证据：已归档（${LDate}）"
LCloseoutConclusion='- 结论：P0 “Windows 实机证据未归档” 已关闭。'
LVerificationLine='  - 验证：verify_windows_b07_evidence PASS'
LStageLine='- 跨平台冻结条件满足。'
LEvidenceVerifyResult='PASS'
LFinalizeResult='PASS'
LFreezeResult='PASS'
LApplyResult='PASS'

if [[ "${SUMMARY_PATH}" == *".simulated."* ]]; then
  LStatusLine='- 状态：dry-run 预演完成（非实机）'
  LMatrixHeadline="- Windows 实机证据：dry-run 预演（${LDate}，未归档）"
  LCloseoutConclusion='- 结论：仅 dry-run 预演通过，待 Windows 实机日志补齐后再关闭 P0。'
  LVerificationLine='  - 验证：simulate + verify + finalize (dry-run)'
  LStageLine='- 仅 dry-run 预演通过，跨平台冻结待 Windows 实机证据。'
  LEvidenceVerifyResult='DRYRUN'
  LFinalizeResult='DRYRUN'
  LFreezeResult='PENDING'
  LApplyResult='SKIP'
fi

if [[ "${LVerifierState}" != "pass" ]]; then
  LStatusLine='- 状态：待补齐（Windows 实机证据未通过）'
  LMatrixHeadline="- Windows 实机证据：待补齐（${LDate}）"
  LCloseoutConclusion='- 结论：Windows 实机证据验证未通过，P0 未关闭。'
  if [[ "${LVerifierState}" == "fail" ]]; then
    LVerificationLine='  - 验证：verify_windows_b07_evidence FAIL'
    LEvidenceVerifyResult='FAIL'
  else
    LVerificationLine='  - 验证：verify_windows_b07_evidence UNKNOWN（缺少 verifier 或日志）'
    LEvidenceVerifyResult='UNKNOWN'
  fi
  LStageLine='- 跨平台冻结条件未满足（Windows 证据链未通过）。'
  LFinalizeResult='PENDING'
  LFreezeResult='PENDING'
  LApplyResult='BLOCKED'

  if [[ "${APPLY_MODE}" == "1" ]]; then
    echo "[CLOSEOUT] Refuse apply: windows evidence verification state=${LVerifierState}"
    echo "[CLOSEOUT] Run first: tests\\fafafa.core.simd\\buildOrTest.bat evidence-win-verify"
    exit 1
  fi
fi

ROADMAP_BLOCK=$(cat <<EOM
<!-- ${LMarker} -->
### Windows 实机证据（${LDate}）

${LStatusLine}
- Evidence Log: ${LRelEvidence}
- Closeout Summary: ${LRelSummary}
${LCloseoutConclusion}
EOM
)

MATRIX_BLOCK=$(cat <<EOM
<!-- ${LMarker} -->
${LMatrixHeadline}
  - Log: ${LRelEvidence}
  - Summary: ${LRelSummary}
${LVerificationLine}
EOM
)

PROGRESS_BLOCK=$(cat <<EOM
<!-- ${LMarker} -->
### 批次
- ${BATCH_ID}

### 执行动作
- 在 Windows 实机完成 buildOrTest.bat evidence-win-verify。
- 生成并归档收口摘要：finalize-win-evidence。
- 回填 roadmap / matrix / progress，关闭跨平台证据缺口。

### 命令与结果
| Command | Result |
|---|---|
| tests\\fafafa.core.simd\\buildOrTest.bat evidence-win-verify | ${LEvidenceVerifyResult} |
| bash tests/fafafa.core.simd/BuildOrTest.sh finalize-win-evidence | ${LFinalizeResult} |
| bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status | ${LFreezeResult} |
| bash tests/fafafa.core.simd/apply_windows_b07_closeout_updates.sh --apply --freeze-json tests/fafafa.core.simd/logs/freeze_status.json | ${LApplyResult} |

### 关键证据
- Log: ${LRelEvidence}
- Summary: ${LRelSummary}

### 阶段状态
${LStageLine}
EOM
)

emit_snippets() {
  echo "[CLOSEOUT] Snippets generated from: ${SUMMARY_PATH}"
  if [[ "${SUMMARY_PATH}" == *".simulated."* ]]; then
    echo "[CLOSEOUT] WARN: snippets are from simulated summary; do not close P0 with them"
  fi
  echo
  echo "### Roadmap snippet"
  echo "${ROADMAP_BLOCK}"
  echo
  echo "### Matrix snippet"
  echo "${MATRIX_BLOCK}"
  echo
  echo "### Progress snippet"
  echo "${PROGRESS_BLOCK}"
}

append_once() {
  local aFile
  local aBlock

  aFile="$1"
  aBlock="$2"

  if grep -F -- "${LMarker}" "${aFile}" >/dev/null 2>&1; then
    echo "[CLOSEOUT] SKIP already applied: ${aFile}"
    return 0
  fi

  printf '\n%s\n' "${aBlock}" >> "${aFile}"
  echo "[CLOSEOUT] APPLIED: ${aFile}"
}

apply_structured_replacements() {
  local aRoadmap
  local aMatrix
  local aRc

  aRoadmap="$1"
  aMatrix="$2"
  aRc="$3"

  python3 - "${aRoadmap}" "${aMatrix}" "${aRc}" <<'PY'
from pathlib import Path
import sys

roadmap = Path(sys.argv[1])
matrix = Path(sys.argv[2])
rc = Path(sys.argv[3])

updates = [
    (roadmap, [
        ('- [ ] **Windows 实机证据未归档**', '- [x] **Windows 实机证据已归档**'),
        ('- [ ] 在 Windows 实机执行：', '- [x] 在 Windows 实机执行：'),
        ('- [ ] 归档 `windows_b07_gate.log` 到 `tests/fafafa.core.simd/logs/`', '- [x] 归档 `windows_b07_gate.log` 到 `tests/fafafa.core.simd/logs/`'),
        ('- [ ] 更新 RC 清单 P0 项为 `[x]`', '- [x] 更新 RC 清单 P0 项为 `[x]`'),
    ]),
    (matrix, [
        ('- Windows 证据：脚本入口 + 校验入口已就绪（待 Windows 实机日志）', '- Windows 证据：实机日志已归档（脚本入口 + 校验入口）'),
        ('- [~] Windows 证据脚本+校验器就绪（待实机执行产出）', '- [x] Windows 实机证据已归档（脚本+校验器+日志）'),
    ]),
    (rc, [
        ('- [ ] Windows 实机证据日志已归档（当前缺口）', '- [x] Windows 实机证据日志已归档'),
        ('- Windows 侧：待补实机日志后完成跨平台证据闭环。', '- Windows 侧：实机日志已归档，跨平台证据闭环完成。'),
    ]),
]

for file_path, replacements in updates:
    original = file_path.read_text()
    updated = original
    for old, new in replacements:
        updated = updated.replace(old, new)
    if updated != original:
        file_path.write_text(updated)
        print(f"[CLOSEOUT] STRUCTURED UPDATED: {file_path}")
    else:
        print(f"[CLOSEOUT] STRUCTURED SKIP: {file_path}")
PY
}

if [[ "${APPLY_MODE}" != "1" ]]; then
  emit_snippets
  exit 0
fi

require_freeze_ready_for_apply

ROADMAP_FILE="${REPO_ROOT}/docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md"
MATRIX_FILE="${REPO_ROOT}/tests/fafafa.core.simd/docs/simd_completeness_matrix.md"
RC_FILE="${REPO_ROOT}/tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md"
PROGRESS_FILE="${REPO_ROOT}/progress.md"

for LFile in "${ROADMAP_FILE}" "${MATRIX_FILE}" "${RC_FILE}" "${PROGRESS_FILE}"; do
  if [[ ! -f "${LFile}" ]]; then
    echo "[CLOSEOUT] Missing target file: ${LFile}"
    exit 2
  fi
done

if [[ "${SKIP_STRUCTURED}" != "1" ]]; then
  apply_structured_replacements "${ROADMAP_FILE}" "${MATRIX_FILE}" "${RC_FILE}"
else
  echo "[CLOSEOUT] SKIP structured replacements for simulated summary"
fi
append_once "${ROADMAP_FILE}" "${ROADMAP_BLOCK}"
append_once "${MATRIX_FILE}" "${MATRIX_BLOCK}"
append_once "${PROGRESS_FILE}" "${PROGRESS_BLOCK}"

echo "[CLOSEOUT] APPLY DONE"
