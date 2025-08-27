# Usage Rendering Improvements — Review Sheet

## Appendix: Real Output (from example_help_schema)

To reproduce:
- Build and run examples/fafafa.core.args.command/example_help_schema

Sample output (your alignment may vary with width; set COLUMNS=80 for stable):

```
Commands:
  run: Run a task

Flags:
  --count [required] [default=1] [int]  Number of times
  --json [bool]                         Output JSON

Args:
  file [required]                        Input file path
```


## Summary
- Introduce TRenderUsageOptions for configurable help output
  - width (0=auto from COLUMNS or fallback 80)
  - wrap (soft-wrapping descriptions)
  - sortSubcommands (stable ordering)
  - markDefaultInChildren (append [default] to default child)
- Keep backward-compatible overload: RenderUsage(Node)
- Improve output readability:
  - Commands section (sorted; mark default)
  - Show aliases for commands and flags
  - Align Flags/Args columns with soft wrapping
- JUnit: ensure testsuite has timestamp and hostname (tests verified)

## Before vs After (Illustrative)

Before (simplified):
- Children not sorted; default child not marked
- Flags/Args not column-aligned; no width-controlled wrapping

After (example):

Commands:
  list [default]: List remotes
  add: Add remote
Default subcommand: list
Aliases: r

Flags:
  --count [required] [default=1] [int]  Number of times to run the task safely with reasonable defaults
  --json (aliases: j) [bool]            Output JSON format for interoperability with tooling

Args:
  file [required]                        Input file path or URI

Notes:
- width defaults to 80; if environment variable COLUMNS is set, it is used
- When wrap=true (default), descriptions are soft-wrapped and aligned

## API

```pascal
// Default options
function RenderUsageOptionsDefault: TRenderUsageOptions;

// Default behavior retained
function RenderUsage(const Node: IBaseCommand): string; overload;

// Configurable behavior
function RenderUsage(const Node: IBaseCommand; const Opts: TRenderUsageOptions): string; overload;
```

Recommended Options patterns:
- Fixed width: Opts.width := 100
- No wrapping: Opts.wrap := False
- Keep registration order: Opts.sortSubcommands := False
- Hide default marking: Opts.markDefaultInChildren := False

## Tests & CI
- All tests green locally (52/52)
- New tests:
  - Default child fallback when next token is an option
  - JUnit testsuite header fields (timestamp, hostname)
- Stability tip for CI: set COLUMNS=80 to avoid width variance across runners

## Risk & Rollback
- Low risk (formatting-focused); backward compatible via existing overload
- Rollback by using the original overload or disabling behaviors via options

## Review Pointers
- Backward compatibility with existing callers
- Readability of alignment/wrapping at 80 cols
- Sorting policy and [default] marking style
- FPC version compatibility (no inline var; SizeInt for widths)

