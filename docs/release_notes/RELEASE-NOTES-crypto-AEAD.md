# Release Notes — fafafa.core.crypto v0.6.0-AEAD-Ready

Date: 2025-08-14

Highlights
- AES‑256‑GCM (GHASH) hardened: constant‑time tag compare; explicit zeroization for intermediates
- ChaCha20‑Poly1305 available; shared AEAD interface parity
- Minimal authoritative KATs added (GHASH zero‑anchor; GCM taglen 12/16 matrix; negative tamper tests)
- Cross‑platform quickstart + one‑click scripts; examples and micro‑bench included

What’s new
- Security
  - GCM.Open uses SecureCompare for tag verify; clears CalcTag/GivenTag/EJ0/H/S/C/J0Block on both fail/pass paths; GH.Reset
  - GCM.Seal clears EJ0/H/S/C/J0Block after building output; GH.Reset
  - GHASH locals initialized and cleared (GFMult128/Update/Finalize)
- Tests
  - Added GHASH zero‑anchor vector; AES‑GCM KAT minimal set; tamper negative tests
  - Test entry uses de‑dup fixed
- Tooling & Docs
  - docs/fafafa.core.crypto.cross-platform-checklist.md
  - scripts/build_or_test_crypto.{bat,sh}
  - examples/fafafa.core.crypto/example_crypto_gcm_{basic,tag12}.lpr
  - plays/fafafa.core.crypto/bench_gcm_throughput.lpr
  - docs/fafafa.core.crypto.md updated: AEAD status, security notes, example entry points

Compatibility
- No API surface changes; behavior preserved
- Requires FPC/Lazarus capable of compiling existing tests (see checklist)

Next
- Optional: further static‑analysis noise reduction in non‑critical units (no behavior change)
- Optional: performance notes per platform/CPU in plays/ results



## GHASH backend selection and performance

- Default policy (auto): prefer CLMUL when CPU supports PCLMUL; otherwise fall back to Pure
- Environment overrides:
  - FAFAFA_GHASH_IMPL=pure | clmul | auto (default)
  - DEBUG-only guard: FAFAFA_GHASH_USE_EXPERIMENTAL=1 (development safety)
  - Optional one-time log (DEBUG): FAFAFA_GHASH_LOG_BACKEND=1

Performance (Windows x86_64, Release-CLMUL; representative):
- 1MB: Pure ~4.27 MB/s vs CLMUL ~62.50 MB/s (≈14.6x)
- 8MB: Pure ~4.57 MB/s vs CLMUL ~126.98 MB/s (≈27.8x)

See also:
- docs/README_crypto_GHASH_backends.md (usage, env vars, reproduction)
- report/fafafa.core.crypto.ghash_bench_summary.md (more numbers)
