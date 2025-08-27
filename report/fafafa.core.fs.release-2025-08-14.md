# Release Notes · fafafa.core.fs · Freeze Completion (2025-08-14)

This release finalizes the freeze window for fafafa.core.fs with zero public API/behavior changes and focuses on stability, docs alignment, and test determinism.

## Highlights
- API/Scope Freeze in effect (see report/fafafa.core.fs.freeze.md)
- All tests green in default environment; heaptrc reports zero leaks
- New ResolvePathEx (non-breaking): opt-in realpath when TouchDisk=True and FollowLinks=True
- Conditional tests (opt-in) for Windows long paths and symlinks
- Documentation alignment; API inventory & perf baseline recorded

## What’s New (non-breaking)
- Path: ResolvePathEx(const Path; FollowLinks; TouchDisk=False)
  - Default: Normalize+absolute (no disk touch)
  - TouchDisk=True & FollowLinks=True: try fs_realpath on existing paths; fallback on failure
- Tests:
  - Test_ResolveEx_* cases
  - Test_fafafa_core_fs_longpath (Win, gated by FAFAFA_TEST_WIN_LONGPATH)
  - Test_fafafa_core_fs_symlink (Unix default; Win gated by FAFAFA_TEST_SYMLINK)
- Docs:
  - FS_UNIFIED_ERRORS confirmed as default-on
  - Best practices for conditional tests added to docs/fafafa.core.fs.md
  - API Inventory: report/fafafa.core.fs.api-inventory.md
  - Perf baseline: report/fafafa.core.fs.perf-baseline.md

## How to run conditional tests
- Windows long path (>260):
  - PowerShell:  $env:FAFAFA_TEST_WIN_LONGPATH="1"; tests\fafafa.core.fs\BuildOrTest.bat test
  - CMD:        set FAFAFA_TEST_WIN_LONGPATH=1 && tests\fafafa.core.fs\BuildOrTest.bat test
- Symlink:
  - Unix (default on): set FAFAFA_TEST_SYMLINK=0 to disable
  - Windows (requires admin/dev-mode):
    - PowerShell:  $env:FAFAFA_TEST_SYMLINK="1"; tests\fafafa.core.fs\BuildOrTest.bat test
    - CMD:        set FAFAFA_TEST_SYMLINK=1 && tests\fafafa.core.fs\BuildOrTest.bat test

## Compatibility
- No breaking changes; public API and defaults unchanged
- FS_UNIFIED_ERRORS remains default-on

## Where to find things
- Freeze policy: report/fafafa.core.fs.freeze.md
- API inventory: report/fafafa.core.fs.api-inventory.md
- Perf baseline: report/fafafa.core.fs.perf-baseline.md
- Module docs: docs/fafafa.core.fs.md

— Released by Augment Agent · FreePascal Framework Architect / TDD Expert

