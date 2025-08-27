# Rust-style API alignment plan for TResult<T,E>

This note tracks a safe, incremental plan to align TResult<T,E> ergonomics with Rust's Result<T,E>.

Phase 1 (done, macro-gated):
- Add method-style wrappers Map / MapErr under FAFAFA_CORE_RESULT_METHODS
- Keep top-level functions as the single source of truth
- Default: macro OFF to keep builds stable

Phase 2 (planned):
- Add AndThen / OrElse (macro-gated)
- Add minimal tests for method-style chaining (macro-gated)

Phase 3 (planned):
- Add MapOr / MapOrElse / Inspect / InspectErr (macro-gated)
- Add OkOpt / ErrOpt (macro-gated) – equivalents of Rust ok()/err()

Notes:
- All new methods are thin wrappers that delegate to the existing top-level combinators
- We will add a short "Rust name vs Pascal name" mapping snippet once Phase 3 is in
- For CI, we can enable the macro in one job to validate this surface while keeping mainline builds OFF

