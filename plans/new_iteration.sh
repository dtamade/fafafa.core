#!/usr/bin/env bash
set -euo pipefail

TOPIC="${1:-iteration}"
DATE="$(date +%Y-%m-%d)"

short_hash() {
  local s="$1"

  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$s" | sha256sum | cut -d' ' -f1 | cut -c1-8
    return 0
  fi

  if command -v shasum >/dev/null 2>&1; then
    printf '%s' "$s" | shasum -a 256 | cut -d' ' -f1 | cut -c1-8
    return 0
  fi

  if command -v md5sum >/dev/null 2>&1; then
    printf '%s' "$s" | md5sum | cut -d' ' -f1 | cut -c1-8
    return 0
  fi

  date +%H%M%S
}

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

extract_current_topic() {
  # Extract topic from the current task_plan.md title line:
  #   "# Task Plan: <topic>"
  if [[ ! -f "task_plan.md" ]]; then
    return 1
  fi

  local first_line
  first_line="$(head -n 1 task_plan.md || true)"

  if [[ "$first_line" == \#\ Task\ Plan:* ]]; then
    printf '%s' "${first_line#\# Task Plan: }"
    return 0
  fi

  return 1
}

ARCHIVE_TOPIC=""
if ARCHIVE_TOPIC="$(extract_current_topic)"; then
  :
else
  ARCHIVE_TOPIC="$TOPIC"
fi

ARCHIVE_SLUG="$(slugify "$ARCHIVE_TOPIC")"

if [[ "$ARCHIVE_SLUG" == "iteration" && "$ARCHIVE_TOPIC" != "iteration" ]]; then
  ARCHIVE_SLUG="iteration-$(short_hash "$ARCHIVE_TOPIC")"
fi

ARCHIVE_DIR_BASE="plans/archive/${DATE}-${ARCHIVE_SLUG}"
ARCHIVE_DIR="$ARCHIVE_DIR_BASE"
ARCHIVE_N=2

while [[ -e "$ARCHIVE_DIR" ]]; do
  ARCHIVE_DIR="${ARCHIVE_DIR_BASE}-${ARCHIVE_N}"
  ARCHIVE_N=$((ARCHIVE_N + 1))
done

mkdir -p "plans/archive"
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
