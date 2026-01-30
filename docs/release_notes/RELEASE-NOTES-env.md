# Release Notes — fafafa.core.env v1.2

Date: 2025-12-16

## Summary
`fafafa.core.env` is a modern, cross-platform environment utilities facade (Windows/Linux/macOS/Android), inspired by Rust `std::env` and Go `os`.

This module provides:
- Environment get/set/unset + enumeration
- RAII override guards for tests
- String expansion: `$VAR`, `${VAR}` (+ Windows `%VAR%`)
- PATH split/join helpers (platform separator)
- Current dir / executable path
- User dirs (home/temp/config/cache) with platform fallbacks
- Security helpers: sensitive-name detection + masking for safe logging
- Typed getters: bool/int/uint/duration/size/float/list/paths
- Optional Result-style wrappers (macro-gated)

## Compatibility
- Default API follows “C-style” failure handling: returns empty string / False (no exceptions).
- `env_required` is the exception: it raises `EEnvVarNotFound` when undefined.
- Iterator API `env_iter` is optimized (direct environ/env-block traversal) and supports early-exit cleanup.

## Validation (acceptance commands)
From repository root:

- Run module tests:
  - `bash tests/run_all_tests.sh fafafa.core.env`
  - or: `./tests/fafafa.core.env/bin/fafafa.core.env.test --all --format=plainnotiming`

- Validate documentation examples:
  - `./benchmarks/fafafa.core.env/bin/doc_examples_test`

- Run examples (Linux/macOS):
  - `bash examples/fafafa.core.env/BuildOrRun.sh run all`

## Docs
- API reference: `docs/fafafa.core.env.md`
- Roadmap: `docs/fafafa.core.env.roadmap.md`
- Report: `report/fafafa.core.env.md`
- Bench baseline: `benchmarks/fafafa.core.env/BASELINE.md`
