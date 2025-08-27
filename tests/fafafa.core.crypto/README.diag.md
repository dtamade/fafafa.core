# AES-GCM diagnostics — best practices

This page documents the diagnostics log and switches used by the crypto tests (AEAD mode).

## Quick start

- Generate two logs (anon=ON/OFF):
  - tests\fafafa.core.crypto\BuildOrTest.bat test aead
- Single run (skip anon=OFF second pass):
  - tests\fafafa.core.crypto\BuildOrTest.bat test aead NO_NOANON

Outputs will be written under tests/fafafa.core.crypto/reports/.

## Log files

- aead_diag.on.log   — run with anon=ON (default build)
- aead_diag.off.log  — run with anon=OFF (Release-NoAnon)
- aead_diag.prev.log — previous run snapshot (rotated from aead_diag.log at start)

Each new run writes to aead_diag.log first; the batch script renames it to on/off accordingly after each pass.

## Log header (once per run)

Lines appended at the beginning of the file:
- [timestamp] diag start
- Run: Exe=<full path to tests executable>
- Mode: anon=ON|OFF
- ReportsDir: <reports directory>
- DiagEnv: FAFAFA_CORE_AEAD_DIAG=...
- DiagEnv: FAFAFA_CORE_AEAD_DIAG_VERBOSE=...

## Test case sections

On test-case change, a short section header is emitted (unless disabled by verbosity):
- ===
- Case: <FullName> (leaf=<LeafName>) (id=<FNV64 16-hex>)

Followed by per-step blocks:
- ---
- [timestamp] <Title> [<FullName>]: <hex>
- Key/Nonce/AAD/PT/CT/TAG lines as applicable

Rationale:
- Human-readable and grep-friendly
- Stable CaseId enables cross-run aggregation without leaking names

## Environment variables

- FAFAFA_CORE_AEAD_DIAG
  - 1 to enable diagnostics; the test script sets this for you
- FAFAFA_CORE_AEAD_DIAG_VERBOSE
  - default: on; set to 0 to suppress the === / Case headers
- FAFAFA_CURRENT_TEST
  - set automatically by the test runner before each test; used to annotate titles
- FAFAFA_CURRENT_TEST_ID
  - optional; if set by a caller, it will be used by our JUnit listener as the CaseId. If empty, the listener falls back to the test name
- FAFAFA_JUNIT_NO_SYSOUT
  - set to 1 to disable writing <system-out>CaseId=...</system-out> within each testcase

## JUnit report and CaseId

Our in-repo JUnit listener writes CaseId to <system-out> if FAFAFA_JUNIT_NO_SYSOUT != 1. The default crypto batch script currently writes an XML report using FpcUnit's built-in formatter; if you want CaseId inside the report, switch to our test runner with --format=junit or run both formats in parallel.

## Optional: enable our JUnit report (with CaseId)

- By default, the batch script only emits the FPCUnit XML report.
- To additionally generate our JUnit report (each testcase has system-out: CaseId=...), set an environment variable before running the script:

  Windows (cmd):

      set FAFAFA_ENABLE_AUX_JUNIT=1
      tests\fafafa.core.crypto\BuildOrTest.bat test aead

  PowerShell:

      $env:FAFAFA_ENABLE_AUX_JUNIT='1'
      tests\fafafa.core.crypto\BuildOrTest.bat test aead

  Bash:

      FAFAFA_ENABLE_AUX_JUNIT=1 tests/fafafa.core.crypto/BuildOrTest.sh test aead

- Notes:
  - The current crypto test binary is based on FPCUnit's runner, which does not support --format=junit; the script guards the extra call behind FAFAFA_ENABLE_AUX_JUNIT to avoid noise.
  - When/if you migrate to our runner (fafafa.core.test.runner), --format=junit and --junit=<path> are supported natively.


## Compatibility

- The added lines do not change the existing per-line data format; existing consumers remain compatible.
- Verbosity and rotation are optional and safe by default.

