# Main vs L0 Audit Plan

## Goal

Confirm whether `main` contains any uncommitted L0-scoped changes that are newer/correct and still missing from the kept L0 worktree.

## Steps

- [completed] Catalog `main` uncommitted files and filter likely L0 scope
- [completed] Compare filtered files against `l0-main-tail-cleanup-20260408`
- [completed] Classify results: already in L0 / should merge / intentionally exclude

## Notes

- `simd-foundation` is out of scope and must not be touched.
- `main` has mixed uncommitted work; do not auto-merge broad changes.
- Result: no `main`-only L0 source delta was found; mismatches are docs, generated artifacts, and archived/control-plane text where the kept L0 worktree is ahead.
