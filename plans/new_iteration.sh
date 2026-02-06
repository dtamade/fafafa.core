#!/usr/bin/env bash
set -euo pipefail

TOPIC="${1:-iteration}"
DATE="$(date +%Y-%m-%d)"

slugify() {
  # keep it filesystem-friendly and stable
  # - lowercase
  # - non-alnum => '-'
  # - collapse dashes
  local s="$1"
  s="$(printf '%s' "$s" | tr '[:upper:]' '[:lower:]')"
  s="$(printf '%s' "$s" | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')"
  if [[ -z "$s" ]]; then
    s="iteration"
  fi
  printf '%s' "$s"
}

sed_escape_repl() {
  # escape replacement for sed s/// where delimiter is '/'
  printf '%s' "$1" | sed -e 's/[\\/&]/\\&/g'
}

SLUG="$(slugify "$TOPIC")"
ARCHIVE_DIR="plans/archive/${DATE}-${SLUG}"

mkdir -p "plans/archive"
if [[ -e "$ARCHIVE_DIR" ]]; then
  echo "ERROR: archive dir already exists: $ARCHIVE_DIR" >&2
  exit 1
fi
mkdir -p "$ARCHIVE_DIR"

move_file() {
  local src="$1"
  local dst="$2"
  if [[ ! -f "$src" ]]; then
    return 0
  fi

  if git ls-files --error-unmatch "$src" >/dev/null 2>&1; then
    git mv "$src" "$dst"
  else
    mv "$src" "$dst"
  fi
}

move_file "task_plan.md" "$ARCHIVE_DIR/task_plan.md"
move_file "findings.md" "$ARCHIVE_DIR/findings.md"
move_file "progress.md" "$ARCHIVE_DIR/progress.md"

render_template() {
  local template="$1"
  local out="$2"
  local topic_escaped
  topic_escaped="$(sed_escape_repl "$TOPIC")"

  if [[ ! -f "$template" ]]; then
    echo "ERROR: missing template: $template" >&2
    exit 1
  fi

  sed \
    -e "s/{{TOPIC}}/${topic_escaped}/g" \
    -e "s/{{DATE}}/${DATE}/g" \
    "$template" > "$out"
}

render_template "plans/templates/task_plan.md" "task_plan.md"
render_template "plans/templates/findings.md" "findings.md"
render_template "plans/templates/progress.md" "progress.md"

echo "OK: new iteration initialized"
echo "Topic:   $TOPIC"
echo "Archive: $ARCHIVE_DIR"

