#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
HELPER_SCRIPT="${REPO_ROOT}/tests/run_windows_strict_l0_native_evidence_via_github_actions.sh"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

[[ -f "${HELPER_SCRIPT}" ]] || fail "missing L0 native GH helper script"

LTmpDir="$(mktemp -d)"
trap 'rm -rf "${LTmpDir}"' EXIT
mkdir -p "${LTmpDir}/bin"

cat >"${LTmpDir}/bin/git" <<'EOF'
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
  branch)
    if [[ "${LArgs[1]:-}" == "--show-current" ]]; then
      echo "l0-mainline"
      exit 0
    fi
    ;;
  rev-parse)
    case "${LArgs[1]:-}" in
      HEAD)
        echo "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        exit 0
        ;;
      main)
        echo "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
        exit 0
        ;;
      l0-mainline)
        echo "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        exit 0
        ;;
    esac
    ;;
  ls-remote)
    echo "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa	refs/heads/main"
    exit 0
    ;;
  status)
    exit 0
    ;;
esac

echo "[stub-git] unexpected invocation: ${LArgs[*]}" >&2
exit 98
EOF
chmod +x "${LTmpDir}/bin/git"

cat >"${LTmpDir}/bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "auth" && "${2:-}" == "status" ]]; then
  exit 0
fi

if [[ "${1:-}" == "workflow" && "${2:-}" == "run" ]]; then
  echo "simulated dispatch failure" >&2
  exit 3
fi

echo "[stub-gh] unexpected invocation: $*" >&2
exit 99
EOF
chmod +x "${LTmpDir}/bin/gh"

set +e
OUTPUT="$(
  PATH="${LTmpDir}/bin:${PATH}" \
  L0_NATIVE_EVIDENCE_REF=main \
  L0_NATIVE_EVIDENCE_PREFLIGHT=0 \
  bash "${HELPER_SCRIPT}" TEST-L0-MAIN-REF 2>&1
)"
RC=$?
set -e

if [[ "${RC}" != "3" ]]; then
  printf '%s\n' "${OUTPUT}" >&2
  fail "expected simulated dispatch rc=3, got rc=${RC}"
fi

if printf '%s' "${OUTPUT}" | rg -n 'remote ref does not match local HEAD|target ref does not match current worktree HEAD' >/dev/null; then
  printf '%s\n' "${OUTPUT}" >&2
  fail "helper still rejected a stale local named ref when current HEAD already matched remote main"
fi

printf '%s' "${OUTPUT}" | rg -n 'Dispatch workflow: l0-windows-native-evidence.yml \(ref=main, head=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\)' >/dev/null \
  || {
    printf '%s\n' "${OUTPUT}" >&2
    fail "helper did not continue to dispatch with the remote-aligned current HEAD"
  }

printf '%s' "${OUTPUT}" | rg -n 'Workflow dispatch failed: l0-windows-native-evidence.yml' >/dev/null \
  || {
    printf '%s\n' "${OUTPUT}" >&2
    fail "helper did not reach the dispatch path after resolving main ref"
  }

echo "[PASS] strict L0 native evidence main-ref contract verified"
