#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_SCRIPT="${REPO_ROOT}/tests/audit_strict_l0_retained_refs.sh"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

[[ -f "${TARGET_SCRIPT}" ]] || fail "missing strict L0 retained refs audit script"

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
  rev-parse)
    case "${LArgs[1]:-}" in
      HEAD)
        echo "1111111111111111111111111111111111111111"
        exit 0
        ;;
      l0-mainline-closeout-20260411)
        echo "1111111111111111111111111111111111111111"
        exit 0
        ;;
      l0-sidecar-handoff-20260409)
        echo "2222222222222222222222222222222222222222"
        exit 0
        ;;
      l0-main-rescue)
        echo "3333333333333333333333333333333333333333"
        exit 0
        ;;
      l0-main-tail-cleanup-20260408-final)
        echo "4444444444444444444444444444444444444444"
        exit 0
        ;;
    esac
    ;;
  merge-base)
    case "${LArgs[2]:-}" in
      l0-mainline-closeout-20260411)
        echo "1111111111111111111111111111111111111111"
        exit 0
        ;;
      l0-sidecar-handoff-20260409)
        echo "aaaaaaaabbbbbbbbccccccccddddddddeeeeeeee"
        exit 0
        ;;
      l0-main-rescue)
        echo "9999999999999999999999999999999999999999"
        exit 0
        ;;
      l0-main-tail-cleanup-20260408-final)
        echo "8888888888888888888888888888888888888888"
        exit 0
        ;;
    esac
    ;;
  cherry)
    case "${LArgs[3]:-}" in
      l0-mainline-closeout-20260411)
        exit 0
        ;;
      l0-sidecar-handoff-20260409)
        cat <<'OUT'
+ 2222222 keep sidecar unique patch
OUT
        exit 0
        ;;
      l0-main-rescue)
        cat <<'OUT'
- 3333333 patch equivalent rescue commit
OUT
        exit 0
        ;;
      l0-main-tail-cleanup-20260408-final)
        cat <<'OUT'
+ 4444444 keep cleanup patch one
+ 5555555 keep cleanup patch two
- 6666666 already absorbed patch
OUT
        exit 0
        ;;
    esac
    ;;
esac

echo "[stub-git] unexpected invocation: ${LArgs[*]}" >&2
exit 98
EOF
chmod +x "${LTmpDir}/bin/git"

OUTPUT="$(
  PATH="${LTmpDir}/bin:${PATH}" \
  bash "${TARGET_SCRIPT}" 2>&1
)" || {
  printf '%s\n' "${OUTPUT}" >&2
  fail "retained refs audit script failed under contract stubs"
}

for LPatt in \
  'current_head=1111111111111111111111111111111111111111' \
  'l0-mainline-closeout-20260411' \
  'decision=same-tip' \
  'l0-sidecar-handoff-20260409' \
  'decision=retain-unique-history' \
  'unique_patch_count=1' \
  'l0-main-rescue' \
  'decision=candidate-delete' \
  'equivalent_patch_count=1' \
  'l0-main-tail-cleanup-20260408-final' \
  'unique_patch_count=2' \
  '[PASS] strict L0 retained refs audit completed (non-destructive)'; do
  printf '%s' "${OUTPUT}" | rg -n -F "${LPatt}" >/dev/null \
    || {
      printf '%s\n' "${OUTPUT}" >&2
      fail "retained refs audit output missing literal: ${LPatt}"
    }
done

echo "[PASS] strict L0 retained refs audit contract verified"
