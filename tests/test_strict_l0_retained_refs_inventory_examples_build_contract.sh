#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_SCRIPT="${REPO_ROOT}/tests/report_strict_l0_retained_refs_inventory.sh"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

[[ -f "${TARGET_SCRIPT}" ]] || fail "missing strict L0 retained refs inventory script"

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
        echo "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
        exit 0
        ;;
    esac
    ;;
  cherry)
    case "${LArgs[3]:-}" in
      l0-mainline-closeout-20260411)
        cat <<'OUT'
+ 1111111 example drift batch
OUT
        exit 0
        ;;
      l0-sidecar-handoff-20260409)
        cat <<'OUT'
+ 2222222 example build scripts
OUT
        exit 0
        ;;
      l0-main-rescue)
        cat <<'OUT'
+ 3333333 generated outputs
OUT
        exit 0
        ;;
      l0-main-tail-cleanup-20260408-final)
        cat <<'OUT'
+ 4444444 test artifacts
OUT
        exit 0
        ;;
    esac
    ;;
  show)
    case "${LArgs[3]:-}" in
      1111111)
        cat <<'OUT'
examples/fafafa.core.sync.mutex/example_performance_comparison.lpr
OUT
        exit 0
        ;;
      2222222)
        cat <<'OUT'
examples/fafafa.core.env/BuildOrRun.sh
OUT
        exit 0
        ;;
      3333333)
        cat <<'OUT'
examples/fafafa.core.atomic/bin/example_basic_operations
OUT
        exit 0
        ;;
      4444444)
        cat <<'OUT'
tests/_run_all_logs_sh/fafafa.core.base.log
tests/fafafa.core.sync.mutex/test_mutex_timeout
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
  bash "${TARGET_SCRIPT}" --details 2>&1
)" || {
  printf '%s\n' "${OUTPUT}" >&2
  fail "retained refs inventory examples/build mode failed under contract stubs"
}

for LPatt in \
  'current_head=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb' \
  'example_source_paths=1' \
  'build_script_paths=1' \
  'generated_output_paths=1' \
  'test_artifact_paths=2' \
  'sample_example_source_paths=examples/fafafa.core.sync.mutex/example_performance_comparison.lpr' \
  'sample_build_script_paths=examples/fafafa.core.env/BuildOrRun.sh' \
  'sample_generated_output_paths=examples/fafafa.core.atomic/bin/example_basic_operations' \
  'sample_test_artifact_paths=tests/_run_all_logs_sh/fafafa.core.base.log | tests/fafafa.core.sync.mutex/test_mutex_timeout' \
  '[PASS] strict L0 retained refs inventory completed'; do
  printf '%s' "${OUTPUT}" | rg -n -F "${LPatt}" >/dev/null \
    || {
      printf '%s\n' "${OUTPUT}" >&2
      fail "retained refs inventory examples/build output missing literal: ${LPatt}"
    }
done

echo "[PASS] strict L0 retained refs inventory examples/build contract verified"
