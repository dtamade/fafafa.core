# Main vs L0 Audit Findings

- Audit started from `main` after worktree consolidation.
- Root `task_plan.md`, `findings.md`, and `progress.md` are archived pointers, so this audit uses a scratch plan directory.
- First comparison pass: all L0-scoped source files currently modified/untracked on `main` match the kept L0 worktree, excluding the intentionally out-of-scope `simd` files.
- Remaining mismatches are concentrated in docs, README files, and directory-level comparisons that still need finer inspection.
- Directory-level mismatches under `examples/fafafa.core.platform/` and `tests/fafafa.core.platform/` are compiled artifacts and logs, not source differences.
- Text diffs in `docs/INDEX.md`, `docs/README.md`, `docs/fafafa.core.mem*.md`, `tests/fafafa.core.atomic/README.md`, and `tests/fafafa.core.mem.allocator.foundation/README.md` show the kept L0 worktree is ahead of `main`, mostly by removing stale paths and documenting current NoContracts / archive behavior.
- `main` does not contain a newer L0 source implementation than the kept L0 worktree.
- Fresh verification script result: `SOURCE_CODE_ISSUES 0` for current dirty `src/`, `tests/`, and `examples/` files on `main` after excluding out-of-scope SIMD paths and docs.
