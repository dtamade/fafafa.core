# Test Runner (fafafa.core.test.runner)

This runner powers our unit tests with pluggable listeners and now uses `fafafa.core.args` for CLI parsing.

## Usage

```
tests.exe [--filter=substr] [--junit=path] [--json=path]
          [--console=mode] [--no-console] [--no-junit] [--no-json]
          [--list] [--help] [--version] [--summary-only]

--filter=substr   Run tests whose names contain substr
--junit=path      Write JUnit XML to path
--json=path       Write JSON report to path
--console=mode    Console output mode: none | file:PATH (default: console stdout)
--no-console      Disable console listener (same as --console=none)
--no-junit        Disable JUnit listener
--no-json         Disable JSON listener
--list            List matching test names and exit
--summary-only    Only print the final summary line
--help, -h, /?    Show this help
--version         Show runner version

## List JSON & Sorting

```
--list-json[=path]     Output matching test names as JSON array (to stdout or file)
--list-json-pretty     Pretty-print JSON (default is compact)
--list-sort=alpha|none Sort names (default alpha) or keep registration order
--list-sort-case       Use case-sensitive alpha sort (default case-insensitive)
```

Notes
- Default: alpha sort + case-insensitive → stable, reproducible output
- File write errors print to stderr and exit with code 2

## Environment Defaults & Exit Codes

Environment variables
- FAFAFA_TEST_JUNIT_FILE  Default --junit path when not specified and JUnit not disabled
- FAFAFA_TEST_JSON_FILE   Default --json path when not specified and JSON not disabled

Exit codes
- 0: All tests passed (skips allowed unless --fail-on-skip)
- 1: Any test failed, or --fail-on-skip with any skipped
- 2: Runner error (e.g., writing --list-json to file failed)

## One-click Scripts Overview

For convenience and consistent defaults, use the helper scripts:

- Windows (PowerShell): scripts/run-tests-ci.ps1
  - Parameters:
    - -FailOnSkip (default: on)
    - -TopSlowest=N (default: 5)
  - Behavior:
    - Ensures FAFAFA_TEST_JUNIT_FILE / FAFAFA_TEST_JSON_FILE default paths
    - Creates output directories as needed
    - Invokes: `tests.exe --ci [--fail-on-skip] --top-slowest=N`

- Linux/macOS (Bash): scripts/run-tests-ci.sh
  - Env:
    - FAIL_ON_SKIP=1/0 (default 1)
    - TOP_SLOWEST=N (default 5)
  - Behavior: same as PowerShell version

List JSON helpers:
  - Options:
    - PowerShell: -Pretty, -Sort alpha|none, -SortCase, -Filter, -CI
    - Bash (env): PRETTY_JSON=1, SORT_MODE=alpha|none, SORT_CASE=1; positional $1 as Filter; adds --filter-ci by default
  - Examples:
    - PowerShell: `powershell -File scripts/list-tests.ps1 -Filter core -CI -Pretty -Sort none -SortCase`
    - Bash: `PRETTY_JSON=1 SORT_MODE=none SORT_CASE=1 ./scripts/list-tests.sh core`

- Windows: powershell -File scripts/list-tests.ps1 -Filter core -CI
- Linux/macOS: ./scripts/list-tests.sh core


  - Debugging helpers:
    - PowerShell: add -DebugRaw to print primary/fallback status and counts, saves raw XML to temp
    - Bash: set DEBUG_RAW=1 to print primary/fallback status and xml length

```

## Implementation notes
- Args parsing is handled by `TArgs.FromProcess` (see `fafafa.core.args`).
- `--console=file:PATH` writes output to a file sink; `--console=none` disables console listener.
- `--summary-only` toggles a lightweight console listener variant.
- Custom listeners can be added via `AddListener()`.


- Register test procs as closures (reference to procedure), not "is nested" functions:
  - Rationale: Nested procs can lose their static link after RegisterTests returns, causing AV on deferred invocation.
  - See: docs/partials/testing.best_practices.md



## Sink (opt-in) switches

These environment variables enable sink-based reporters to validate new implementations without changing defaults.

- FAFAFA_TEST_USE_SINK_CONSOLE=1
  - Use sink-based console reporter (human-friendly lines, with cleanup section)
- FAFAFA_TEST_USE_SINK_JSON=1
  - Use sink-based JSON reporter (schema compatible with existing JSON listener; V2 adds structured cleanup when available)
- FAFAFA_TEST_USE_SINK_JUNIT=1
  - Use sink-based JUnit reporter (strict XML 1.0 escaping, cleanup details via CDATA)

Notes
- Default behavior remains unchanged when variables are not set
- Timestamps are UTC Z (RFC3339) for determinism
- CaseId is included in JUnit system-out to aid cross-run correlation

- Benchmark side note: FAFAFA_BENCH_USE_SINK_JSON is now bit-equal to the default JSON reporter; safe to enable when needed.
