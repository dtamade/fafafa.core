#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_SCRIPT="${REPO_ROOT}/tests/run_strict_l0_mainline_closeout.sh"
SHARED_HELPER="${REPO_ROOT}/tests/lib_github_actions_workflow_runs.sh"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

require_arg_value() {
  local aLogFile="$1"
  local aKey="$2"
  local aExpected="$3"
  python3 - "$aLogFile" "$aKey" "$aExpected" <<'PY'
import json
import sys

path, key, expected = sys.argv[1:]
with open(path, "r", encoding="utf-8") as fh:
    data = json.load(fh)
actual = data.get(key)
if actual != expected:
    print(f"{key} mismatch: actual={actual!r} expected={expected!r}", file=sys.stderr)
    sys.exit(1)
PY
}

prepare_test_root() {
  local aRoot="$1"
  mkdir -p "${aRoot}/bin" "${aRoot}/tests"
  cp "${TARGET_SCRIPT}" "${aRoot}/tests/run_strict_l0_mainline_closeout.sh"
  chmod +x "${aRoot}/tests/run_strict_l0_mainline_closeout.sh"
  if [[ -f "${SHARED_HELPER}" ]]; then
    cp "${SHARED_HELPER}" "${aRoot}/tests/lib_github_actions_workflow_runs.sh"
    chmod +x "${aRoot}/tests/lib_github_actions_workflow_runs.sh"
  fi
}

write_stub_git() {
  local aRoot="$1"
  cat >"${aRoot}/bin/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

LArgs=()
while [[ $# -gt 0 ]]; do
  if [[ "${1}" == "-C" ]]; then
    shift 2
    continue
  fi
  LArgs+=("${1}")
  shift
done

case "${LArgs[0]:-}" in
  ls-remote)
    echo "1111111111111111111111111111111111111111	refs/heads/main"
    exit 0
    ;;
esac

echo "[stub-git] unexpected invocation: ${LArgs[*]}" >&2
exit 98
EOF
  chmod +x "${aRoot}/bin/git"
}

write_skip_case_stubs() {
  local aRoot="$1"
  cat >"${aRoot}/bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "run" && "${2:-}" == "view" && "${4:-}" == "--json" && "${5:-}" == "headSha" ]]; then
  case "${3:-}" in
    7101)
      printf '{"headSha":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}\n'
      exit 0
      ;;
    8102)
      printf '{"headSha":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"}\n'
      exit 0
      ;;
  esac
fi

echo "[stub-gh] unexpected invocation: $*" >&2
exit 99
EOF
  chmod +x "${aRoot}/bin/gh"

  cat >"${aRoot}/tests/run_windows_strict_l0_native_evidence_via_github_actions.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "[stub-windows-helper] unexpected invocation: $*" >&2
exit 97
EOF
  chmod +x "${aRoot}/tests/run_windows_strict_l0_native_evidence_via_github_actions.sh"

  cat >"${aRoot}/tests/update_strict_l0_current_state_docs.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
LLog="${DOCS_ARGS_LOG:?}"
python3 - "$LLog" "$@" <<'PY'
import json
import sys

out_path = sys.argv[1]
args = sys.argv[2:]
data = {}
i = 0
while i < len(args):
    key = args[i]
    if key.startswith("--"):
        if i + 1 < len(args) and not args[i + 1].startswith("--"):
            data[key] = args[i + 1]
            i += 2
        else:
            data[key] = True
            i += 1
    else:
        i += 1
with open(out_path, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2, sort_keys=True)
PY
EOF
  chmod +x "${aRoot}/tests/update_strict_l0_current_state_docs.sh"
}

write_dispatch_case_stubs() {
  local aRoot="$1"
  cat >"${aRoot}/bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "workflow" && "${2:-}" == "run" && "${3:-}" == "l0-linux-maintenance.yml" && "${4:-}" == "--ref" && "${5:-}" == "main" ]]; then
  exit 0
fi

if [[ "${1:-}" == "run" && "${2:-}" == "list" ]]; then
  LNow="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  printf '[{"databaseId":9101,"headSha":"1111111111111111111111111111111111111111","headBranch":"main","event":"workflow_dispatch","createdAt":"%s"}]\n' "${LNow}"
  exit 0
fi

if [[ "${1:-}" == "run" && "${2:-}" == "view" && "${4:-}" == "--json" && "${5:-}" == "status,conclusion" ]]; then
  case "${3:-}" in
    9101)
      printf '{"status":"completed","conclusion":"success"}\n'
      exit 0
      ;;
  esac
fi

if [[ "${1:-}" == "run" && "${2:-}" == "view" && "${4:-}" == "--json" && "${5:-}" == "headSha" ]]; then
  case "${3:-}" in
    9101)
      printf '{"headSha":"1111111111111111111111111111111111111111"}\n'
      exit 0
      ;;
    9102)
      printf '{"headSha":"cccccccccccccccccccccccccccccccccccccccc"}\n'
      exit 0
      ;;
  esac
fi

echo "[stub-gh] unexpected invocation: $*" >&2
exit 99
EOF
  chmod +x "${aRoot}/bin/gh"

  cat >"${aRoot}/tests/run_windows_strict_l0_native_evidence_via_github_actions.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "${1:-}" == "CASE2-BATCH" ]] || {
  echo "[stub-windows-helper] unexpected batch id: ${1:-}" >&2
  exit 96
}
echo "[L0-NATIVE-EVIDENCE-GH] Watching run: 9102"
EOF
  chmod +x "${aRoot}/tests/run_windows_strict_l0_native_evidence_via_github_actions.sh"

  cat >"${aRoot}/tests/update_strict_l0_current_state_docs.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
LLog="${DOCS_ARGS_LOG:?}"
python3 - "$LLog" "$@" <<'PY'
import json
import sys

out_path = sys.argv[1]
args = sys.argv[2:]
data = {}
i = 0
while i < len(args):
    key = args[i]
    if key.startswith("--"):
        if i + 1 < len(args) and not args[i + 1].startswith("--"):
            data[key] = args[i + 1]
            i += 2
        else:
            data[key] = True
            i += 1
    else:
        i += 1
with open(out_path, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2, sort_keys=True)
PY
EOF
  chmod +x "${aRoot}/tests/update_strict_l0_current_state_docs.sh"
}

[[ -f "${TARGET_SCRIPT}" ]] || fail "missing strict L0 mainline closeout script"

LTmpDir="$(mktemp -d)"
trap 'rm -rf "${LTmpDir}"' EXIT

LCase1Root="${LTmpDir}/case1"
prepare_test_root "${LCase1Root}"
write_stub_git "${LCase1Root}"
write_skip_case_stubs "${LCase1Root}"
LCase1Log="${LTmpDir}/case1-docs.json"

set +e
DOCS_ARGS_LOG="${LCase1Log}" \
PATH="${LCase1Root}/bin:${PATH}" \
bash "${LCase1Root}/tests/run_strict_l0_mainline_closeout.sh" \
  --skip-linux \
  --skip-windows \
  --apply-docs \
  --main-sha "1111111111111111111111111111111111111111" \
  --linux-run-id "7101" \
  --windows-run-id "8102" >/dev/null 2>&1
LCase1Rc=$?
set -e

[[ "${LCase1Rc}" == "0" ]] || fail "skip/apply-docs E2E path failed with rc=${LCase1Rc}"

require_arg_value "${LCase1Log}" "--main-sha" "1111111111111111111111111111111111111111" \
  || fail "skip/apply-docs path did not forward main sha"
require_arg_value "${LCase1Log}" "--linux-run-id" "7101" \
  || fail "skip/apply-docs path did not forward linux run id"
require_arg_value "${LCase1Log}" "--windows-run-id" "8102" \
  || fail "skip/apply-docs path did not forward windows run id"
require_arg_value "${LCase1Log}" "--linux-run-sha" "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" \
  || fail "skip/apply-docs path did not resolve linux run head sha from gh run view"
require_arg_value "${LCase1Log}" "--windows-run-sha" "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" \
  || fail "skip/apply-docs path did not resolve windows run head sha from gh run view"

LCase2Root="${LTmpDir}/case2"
prepare_test_root "${LCase2Root}"
write_stub_git "${LCase2Root}"
write_dispatch_case_stubs "${LCase2Root}"
LCase2Log="${LTmpDir}/case2-docs.json"

set +e
DOCS_ARGS_LOG="${LCase2Log}" \
PATH="${LCase2Root}/bin:${PATH}" \
L0_MAINLINE_CLOSEOUT_BATCH_ID="CASE2" \
L0_MAINLINE_CLOSEOUT_WINDOWS_LOCAL_BATCH_ID="CASE2-BATCH" \
bash "${LCase2Root}/tests/run_strict_l0_mainline_closeout.sh" \
  --apply-docs >/dev/null 2>&1
LCase2Rc=$?
set -e

[[ "${LCase2Rc}" == "0" ]] || fail "dispatch/apply-docs E2E path failed with rc=${LCase2Rc}"

require_arg_value "${LCase2Log}" "--linux-run-id" "9101" \
  || fail "dispatch/apply-docs path did not capture linux run id"
require_arg_value "${LCase2Log}" "--windows-run-id" "9102" \
  || fail "dispatch/apply-docs path did not capture windows run id from helper output"
require_arg_value "${LCase2Log}" "--linux-run-sha" "1111111111111111111111111111111111111111" \
  || fail "dispatch/apply-docs path did not forward linux run head sha"
require_arg_value "${LCase2Log}" "--windows-run-sha" "cccccccccccccccccccccccccccccccccccccccc" \
  || fail "dispatch/apply-docs path did not forward windows run head sha"
require_arg_value "${LCase2Log}" "--windows-local-batch-id" "CASE2-BATCH" \
  || fail "dispatch/apply-docs path did not forward windows batch id"

echo "[PASS] strict L0 mainline closeout E2E contract verified"
