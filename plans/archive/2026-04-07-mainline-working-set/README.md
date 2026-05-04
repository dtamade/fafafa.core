# 2026-04-07 Mainline Working Set Archive

This directory stores the last committed root-level working set before the L0 mainline cleanup on `2026-04-07`.

It exists for traceability, not as a current source of truth.

## Why this archive exists

- The old root `task_plan.md`, `findings.md`, and `progress.md` had grown into long-running execution logs.
- Most of that content was SIMD-heavy and no longer belonged on the clean L0 mainline surface.
- Mainline now keeps stable conclusions in `docs/plans/`, `docs/audits/`, and `workers/`, and keeps detailed working logs either worktree-local or archived here.

## What moved here

- `task_plan.md`
- `findings.md`
- `progress.md`

## Current control-plane entry points

- `docs/audits/2026-04-07-l0-rescue-triage-audit.md`
- `docs/plans/2026-04-07-l0-rescue-split-closeout.md`
- `workers/worker1.md`
