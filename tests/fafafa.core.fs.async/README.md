# fafafa.core.fs.async Test Status

`tests/fafafa.core.fs.async` has been cleaned to the current L0 baseline, but the module is not ready for Linux aggregate test discovery yet.

Current state on April 8, 2026:
- `BuildOrTest.bat` is the maintained manual/Windows entrypoint.
- stale lowercase `buildOrTest.bat` has been removed.
- unused `test_simple.pas` has been removed.
- Linux `BuildOrTest.sh` is intentionally not present.

Current blocker:
- building `run_async_tests.lpr` fails in `src/fafafa.core.fs.async.pas:21`
- the unit still uses `IFuture<T>` syntax and thread-pool assumptions that do not match the current `fafafa.core.thread` future model

Why there is no `BuildOrTest.sh` yet:
- `tests/run_all_tests.sh` auto-discovers every `BuildOrTest.sh`
- adding a shell runner now would make the Linux aggregate test entrypoint fail immediately on a known stale source file

Next steps:
1. Repair or retire `src/fafafa.core.fs.async.pas` against the current future/thread-pool APIs.
2. Re-add `BuildOrTest.sh` only after the module compiles.
3. Re-enroll the module in Linux aggregate verification.
