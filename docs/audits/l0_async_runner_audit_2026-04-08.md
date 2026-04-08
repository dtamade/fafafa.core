# L0 Async Runner Audit

Date: 2026-04-08

Scope:
- `tests/fafafa.core.fs.async`
- `tests/fafafa.core.socket.async`

Findings:
- `socket.async` is healthy on the current Linux toolchain. Direct FPC build and runtime verification pass. The remaining drift was runner naming and missing shell integration.
- `fs.async` has stale test harness bits, but the hard blocker is the source unit `src/fafafa.core.fs.async.pas:21`. It still assumes a generic `IFuture<T>` model that no longer matches the current thread/future layer.

Actions completed:
- normalized `tests/fafafa.core.socket.async` to `BuildOrTest.bat` plus `BuildOrTest.sh`
- removed stale lowercase runner aliases in both async test directories
- removed `tests/fafafa.core.fs.async/test_simple.pas`
- documented the `fs.async` blocker in `tests/fafafa.core.fs.async/README.md`
- kept `fs.async` out of Linux aggregate runner discovery until the source unit is repaired

Roadmap:
1. Repair or retire `src/fafafa.core.fs.async.pas`.
2. Add `tests/fafafa.core.fs.async/BuildOrTest.sh` only after the source compiles.
3. Re-run targeted verification through `tests/run_all_tests.sh`.
