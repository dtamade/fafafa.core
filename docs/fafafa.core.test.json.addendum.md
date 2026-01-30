# JSON Report: Cleanup timestamp options

This addendum documents optional fields and compile-time switches for the JSON V2 report produced by the test framework.

## Cleanup items

Each failed test may include a cleanup array with details about teardown steps that were executed upon failure.

- cleanup: Array of objects
  - text: string
  - ts?: string (RFC3339)

Notes:
- ts is optional and is enabled by the macro FAFAFA_TEST_JSON_CLEANUP_TS.
- When enabled, ts is emitted in RFC3339 format. Default is UTC with milliseconds.

## Compile-time switches (in src/fafafa.core.settings.inc)

- Enable timestamp field:
  - {$DEFINE FAFAFA_TEST_JSON_CLEANUP_TS}

- Precision (default: milliseconds). Uncomment to switch to seconds:
  - {.$DEFINE FAFAFA_TEST_JSON_CLEANUP_TS_PRECISION_SEC}

- Time zone (default: UTC with trailing Z). Uncomment to switch to local offset:
  - {.$DEFINE FAFAFA_TEST_JSON_CLEANUP_TS_TZ_LOCAL_OFFSET}

Examples:
- Default (UTC+ms): 2025-08-18T10:49:21.123Z
- Seconds-only (UTC): 2025-08-18T10:49:21Z
- Local offset +ms: 2025-08-18T10:49:21.123+08:00

## Compatibility

- Existing consumers not expecting ts remain unaffected when the macro is disabled (default before enabling).
- The JSON schema remains backward-compatible; ts is additive and optional.

## Testing

- The test suite validates cleanup[].ts using a general RFC3339 checker that accepts either UTC (Z) or a signed local offset with optional milliseconds.
- Run: tests\fafafa.core.test\BuildOrTest.bat test

