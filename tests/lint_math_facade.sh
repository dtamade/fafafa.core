#!/usr/bin/env bash
# =============================================================================
# lint_math_facade.sh
# 
# Phase 2.5 防回退检测：确保框架代码不直接使用 RTL Math 单元
# 
# 用法:
#   ./lint_math_facade.sh        # 检测 src/ 下是否有违规
#   ./lint_math_facade.sh --fix  # 显示如何修复
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$PROJECT_ROOT/src"

# 白名单：允许直接使用 RTL Math 的底层实现文件
WHITELIST=(
  "fafafa.core.math.float.pas"      # float 子模块需要调用 RTL Math
  "fafafa.core.simd.scalar.pas"     # SIMD scalar 后端可能需要 RTL
)

is_whitelisted() {
  local file="$1"
  local basename
  basename="$(basename "$file")"
  for w in "${WHITELIST[@]}"; do
    if [[ "$basename" == "$w" ]]; then
      return 0
    fi
  done
  return 1
}

echo "============================================="
echo "  fafafa.core.math Facade Lint Check"
echo "============================================="
echo "Project: $PROJECT_ROOT"
echo "Scanning: $SRC_DIR"
echo ""

VIOLATIONS=()

while IFS= read -r -d '' file; do
  if is_whitelisted "$file"; then
    continue
  fi
  
  # 检测 uses 子句中的独立 Math 单元（不是 fafafa.core.math）
  # 匹配模式：uses ... Math ... ; 或 uses Math; 或 , Math,
  if grep -qE '\buses\b.*\bMath\b' "$file" 2>/dev/null; then
    # 排除 fafafa.core.math 系列
    if grep -E '\buses\b.*\bMath\b' "$file" | grep -vq 'fafafa\.core\.math'; then
      VIOLATIONS+=("$file")
    fi
  fi
done < <(find "$SRC_DIR" -type f -name "*.pas" -print0)

echo "White-listed files (allowed to use RTL Math):"
for w in "${WHITELIST[@]}"; do
  echo "  - $w"
done
echo ""

if [ ${#VIOLATIONS[@]} -eq 0 ]; then
  echo "✅ PASS: No RTL Math violations found"
  echo ""
  echo "All source files correctly use fafafa.core.math facade."
  exit 0
else
  echo "❌ FAIL: Found ${#VIOLATIONS[@]} violation(s)"
  echo ""
  echo "Files directly using RTL Math (should use fafafa.core.math instead):"
  for v in "${VIOLATIONS[@]}"; do
    rel_path="${v#$PROJECT_ROOT/}"
    echo "  - $rel_path"
    # 显示违规行
    grep -nE '\buses\b.*\bMath\b' "$v" | grep -v 'fafafa\.core\.math' | while read -r line; do
      echo "      $line"
    done
  done
  echo ""
  
  if [[ "${1:-}" == "--fix" ]]; then
    echo "修复建议："
    echo "  1. 将 'uses Math' 改为 'uses fafafa.core.math'"
    echo "  2. 或添加 fafafa.core.math 到 uses 并移除 Math"
    echo "  3. 如果是底层实现确需 RTL，请添加到白名单"
  else
    echo "运行 '$0 --fix' 查看修复建议"
  fi
  
  exit 1
fi
