# L0 Pre-Merge CI Closeout Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Push the current `l0-mainline` head to a remote-visible ref, collect fresh Linux/Windows CI evidence for that exact branch head, and record a pre-merge evidence snapshot without falsely rewriting `main`-state docs.

**Architecture:** Treat this as a strict non-SIMD L0 pre-merge closeout, not a `main` closeout. Reuse the existing GitHub Actions workflows and shell verifiers, but keep documentation updates branch-scoped until merge actually happens. The `main` docs backfill helper stays reserved for true `origin/main` closeout because it writes merged-main semantics.

**Tech Stack:** git, GitHub CLI (`gh`), existing L0 shell automation, GitHub Actions workflows, Markdown control-plane docs.

---

### Task 1: Make the current L0 head remote-visible

**Files:**
- Modify: remote ref `origin/l0-mainline`
- Verify: `workers/worker1.md`

**Step 1: Confirm the worktree is clean**

Run:

```bash
git status --short
```

Expected: no output.

**Step 2: Push the current branch head to the remote L0 ref**

Run:

```bash
git push origin HEAD:refs/heads/l0-mainline
```

Expected: remote `l0-mainline` fast-forwards to the current local head.

**Step 3: Verify the remote SHA**

Run:

```bash
git rev-parse HEAD
git rev-parse --verify refs/remotes/origin/l0-mainline
```

Expected: both SHAs match.

### Task 2: Collect Linux maintenance evidence for the branch head

**Files:**
- Read: `tests/run_strict_l0_mainline_closeout.sh`
- Read: `.github/workflows/l0-linux-maintenance.yml`
- Record later in: `docs/audits/2026-04-13-l0-premerge-ci-evidence-audit.md`

**Step 1: Dispatch the Linux workflow against `l0-mainline`**

Run:

```bash
L0_MAINLINE_CLOSEOUT_MAIN_REF=l0-mainline \
L0_MAINLINE_CLOSEOUT_BATCH_ID=L0-20260413-l0-premerge-ci \
bash tests/run_strict_l0_mainline_closeout.sh --skip-windows
```

Expected: a Linux workflow run id is found, watched to completion, and exits PASS.

**Step 2: Capture the run id and head SHA**

Expected output contains:

```text
[INFO] linux_run_id=<id>
[INFO] main_ref=l0-mainline
[INFO] main_sha=<sha>
```

### Task 3: Collect exact Windows native evidence for the same branch head

**Files:**
- Read: `tests/run_windows_strict_l0_native_evidence_via_github_actions.sh`
- Read: `.github/workflows/l0-windows-native-evidence.yml`
- Record later in: `docs/audits/2026-04-13-l0-premerge-ci-evidence-audit.md`

**Step 1: Dispatch the Windows workflow against `l0-mainline`**

Run:

```bash
L0_NATIVE_EVIDENCE_REF=l0-mainline \
L0_NATIVE_EVIDENCE_POLL_MAX_TRIES=180 \
bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh \
  L0-20260413-l0-premerge-ci-windows
```

Expected: workflow dispatches, downloads `l0-windows-native-evidence`, and shell verification passes.

**Step 2: Capture the run id and snapshot path**

Expected output contains:

```text
[L0-NATIVE-EVIDENCE-GH] Watching run: <id>
...
[PASS] strict L0 native evidence shell verifier contract verified
```

### Task 4: Record a branch-scoped pre-merge evidence snapshot

**Files:**
- Create: `docs/audits/2026-04-13-l0-premerge-ci-evidence-audit.md`
- Modify: `workers/worker1.md`
- Modify: `docs/audits/2026-04-13-l0-retained-refs-tenth-mem-callback-doc-guard-audit.md`

**Step 1: Write a dedicated pre-merge audit**

Requirements:

- State exact `l0-mainline` head SHA
- State Linux and Windows workflow run ids and run SHAs
- State that this is pre-merge branch evidence, not `origin/main` closeout
- State that `update_strict_l0_current_state_docs.sh` was intentionally not applied because it writes merged-main semantics

**Step 2: Refresh worker control-plane**

Requirements:

- Add the new pre-merge audit to `Source of truth`
- Note that remote `l0-mainline` now matches local head
- Note that exact Windows native evidence now exists for the branch-visible head

**Step 3: Refresh the tenth-wave audit**

Requirements:

- Replace the old “remote mismatch / pending push” blocker with the actual branch-evidence result
- Keep the scope statement explicit: evidence is for `l0-mainline` pre-merge closeout, not for merged `main`

### Task 5: Run final merge-ready verification

**Files:**
- Verify only

**Step 1: Re-run shortlist and retained-refs guards**

Run:

```bash
bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh
bash tests/audit_strict_l0_retained_refs.sh
```

Expected: `closeout` and `rescue` still reject wholesale absorb.

**Step 2: Re-run document and diff hygiene**

Run:

```bash
git diff --check
bash tests/check_strict_l0_docs_consistency.sh
```

Expected: PASS.

**Step 3: Commit the pre-merge closeout docs**

Run:

```bash
git add docs/plans/2026-04-13-l0-premerge-ci-closeout-plan.md \
        docs/audits/2026-04-13-l0-premerge-ci-evidence-audit.md \
        docs/audits/2026-04-13-l0-retained-refs-tenth-mem-callback-doc-guard-audit.md \
        workers/worker1.md
git commit -m "docs(l0): record pre-merge CI closeout evidence"
```

Expected: one docs-only commit with branch-scoped CI evidence.
