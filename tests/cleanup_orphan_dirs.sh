#!/usr/bin/env bash
#
# 清理测试产生的孤儿目录
# Issue #9: 清理测试孤儿目录
#
# 用法:
#   bash tests/cleanup_orphan_dirs.sh
#   bash tests/cleanup_orphan_dirs.sh --run
#   bash tests/cleanup_orphan_dirs.sh --root /path/to/search-root
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEARCH_ROOT="${SCRIPT_DIR}"
DRY_RUN=1

print_help() {
  cat <<'EOF'
用法:
  bash tests/cleanup_orphan_dirs.sh
  bash tests/cleanup_orphan_dirs.sh --run
  bash tests/cleanup_orphan_dirs.sh --root /path/to/search-root

说明:
  默认只预览，不删除。
  --run 会实际删除匹配到的孤儿目录。
  --root 可覆盖默认搜索根（默认是 tests/ 目录）。
EOF
}

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run)
      DRY_RUN=0
      ;;
    --root)
      shift
      [[ $# -gt 0 ]] || fail "--root requires a directory argument"
      SEARCH_ROOT="$1"
      ;;
    --help|-h)
      print_help
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
  shift
done

SEARCH_ROOT="$(cd "${SEARCH_ROOT}" && pwd)"
[[ -d "${SEARCH_ROOT}" ]] || fail "search root does not exist: ${SEARCH_ROOT}"

ORPHAN_PATTERNS=(
  "copytree_*"
  "movetree_*"
  "removetree_*"
  "tmp_*"
  "*.tmp"
  "test_output_*"
  "_tmp*"
)

TOTAL_COUNT=0

echo "=== 测试孤儿目录清理工具 ==="
echo "搜索根目录: ${SEARCH_ROOT}"
echo

for pattern in "${ORPHAN_PATTERNS[@]}"; do
  echo "--- 模式: ${pattern} ---"

  FOUND=0
  while IFS= read -r -d '' dir; do
    FOUND=1
    SIZE="$(du -sh "${dir}" 2>/dev/null | cut -f1 || echo "?")"
    echo "  ${dir} (${SIZE})"
    ((TOTAL_COUNT++)) || true

    if [[ "${DRY_RUN}" -eq 0 ]]; then
      rm -rf "${dir}"
      echo "    [已删除]"
    fi
  done < <(find "${SEARCH_ROOT}" -mindepth 1 -type d -name "${pattern}" -print0 2>/dev/null)

  if [[ "${FOUND}" -eq 0 ]]; then
    echo "  (无匹配)"
  fi
done

echo
echo "=== 汇总 ==="
echo "发现孤儿目录: ${TOTAL_COUNT} 个"

if [[ "${DRY_RUN}" -eq 1 ]]; then
  echo
  echo "当前为预览模式。要实际删除，请运行:"
  echo "  bash tests/cleanup_orphan_dirs.sh --run"
else
  echo "已清理: ${TOTAL_COUNT} 个目录"
fi
