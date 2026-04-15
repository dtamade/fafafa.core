# SIMD Implementation Matrix

## Current Focus

这份矩阵只服务于当前 `simd` implementation 审计主线，不讨论 public API 漂亮话。

- 目标一：所有 key slot 的 ownership contract 都要有单一真相源。
- 目标二：`BuildOrTest.sh impl-audit-nonx86` 必须能把 source / runtime / evidence 三层证据串成一条可复验链。
- 目标三：后续 implementation 审查按矩阵推进，不再散点翻文件。
- 目标四：`impl-smoke-nonx86` 作为高频实现回归层，只负责尽快暴露 non-x86 contract 漂移；完整实现审计 / strict closeout 仍分别看 `impl-audit-full` / `closeout-host-local`。
- 目标五：`BuildOrTest.sh impl-audit-full` 作为实现深审主入口，固定先复验 x86 bounded frontier，再跑 non-x86 implementation audit，避免执行顺序漂移。
- 当前额外约束：
  - 这张表可以做 working ledger，但不能单独当成 “Task 2/Task 3 已完成” 的证明。
  - `Task 2 / Task 3` 相关 family 现在都已经有 2026-04-15 fresh evidence，可以按 closeout-ready 理解。
  - `src/fafafa.core.simd.neon.pas` 里的 `NEON hygiene` 当前已 green，但若后续切历史，建议单列为 `NEON shift/select hygiene`。

## Non-X86 Ownership Matrix

backend | slot | expected contract | source truth | runtime evidence | current status | next action
--- | --- | --- | --- | --- | --- | ---
NEON | AndI64x8 | reuse_base_scalar | DispatchAPI source truth: `Test_NEON_NoAsmIntegerFallbackSlots_Reuse_BaseScalar_When_Wrappers_Are_Not_BackendOwned` | `Test_WideSignedBitwiseShiftParity_IfAvailable` + `Test_DataPlane_WideBitwiseShiftSnapshot_Follows_CurrentDispatchSemantics` | covered by `key-slot-audit` + parity suites | fail if register assignment reappears
NEON | NotI64x8 | reuse_base_scalar | DispatchAPI source truth: `Test_NEON_NoAsmIntegerFallbackSlots_Reuse_BaseScalar_When_Wrappers_Are_Not_BackendOwned` | `Test_WideSignedBitwiseShiftParity_IfAvailable` + `Test_DataPlane_WideBitwiseShiftSnapshot_Follows_CurrentDispatchSemantics` | covered by `key-slot-audit` + parity suites | fail if register assignment reappears
NEON | ShiftLeftI32x16 | backend_owned | DispatchAPI source truth: `Test_NEON_NoAsmIntegerFallbackSlots_Reuse_BaseScalar_When_Wrappers_Are_Not_BackendOwned` | `Test_WideSignedBitwiseShiftParity_IfAvailable` + `Test_DataPlane_WideBitwiseShiftSnapshot_Follows_CurrentDispatchSemantics` | covered by `key-slot-audit` + parity suites | fail if slot devolves to wrapper/scalar
NEON | ShiftRightArithI64x4 | backend_owned | DispatchAPI source truth: `Test_NEON_NoAsmIntegerFallbackSlots_Reuse_BaseScalar_When_Wrappers_Are_Not_BackendOwned` | `Test_WideSignedBitwiseShiftParity_IfAvailable` + `Test_DataPlane_WideBitwiseShiftSnapshot_Follows_CurrentDispatchSemantics` | covered by `key-slot-audit` + parity suites | fail if slot devolves to wrapper/scalar
NEON | SubI32x8 | backend_owned | DispatchAPI source truth: `Test_NEON_NoAsmIntegerFallbackSlots_Reuse_BaseScalar_When_Wrappers_Are_Not_BackendOwned` | `Test_WideIntegerArithmeticMinMaxParity_IfAvailable` + `Test_DataPlane_WideArithmeticMinMaxSnapshot_Follows_CurrentDispatchSemantics` | covered by `key-slot-audit` + parity suites | fail if slot devolves to wrapper/scalar
NEON | MinU32x8 | backend_owned | DispatchAPI source truth: `Test_NEON_NoAsmIntegerFallbackSlots_Reuse_BaseScalar_When_Wrappers_Are_Not_BackendOwned` | `Test_WideIntegerArithmeticMinMaxParity_IfAvailable` + `Test_DataPlane_WideArithmeticMinMaxSnapshot_Follows_CurrentDispatchSemantics` | covered by `key-slot-audit` + parity suites | fail if slot devolves to wrapper/scalar
NEON | AddI64x4 | reuse_base_scalar | DispatchAPI source truth: `Test_NEON_NoAsmIntegerFallbackSlots_Reuse_BaseScalar_When_Wrappers_Are_Not_BackendOwned` | `Test_WideIntegerArithmeticMinMaxParity_IfAvailable` + `Test_DataPlane_WideArithmeticMinMaxSnapshot_Follows_CurrentDispatchSemantics` | covered by `key-slot-audit` + parity suites | fail if register assignment reappears
NEON | MulI32x16 | reuse_base_scalar | DispatchAPI source truth: `Test_NEON_NoAsmIntegerFallbackSlots_Reuse_BaseScalar_When_Wrappers_Are_Not_BackendOwned` | `Test_WideIntegerArithmeticMinMaxParity_IfAvailable` + `Test_DataPlane_WideArithmeticMinMaxSnapshot_Follows_CurrentDispatchSemantics` | covered by `key-slot-audit` + parity suites | fail if register assignment reappears
NEON | MaxU32x16 | reuse_base_scalar | DispatchAPI source truth: `Test_NEON_WideFallbackOnlySlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders` | `Test_WideIntegerArithmeticMinMaxParity_IfAvailable` + `Test_DataPlane_WideArithmeticMinMaxSnapshot_Follows_CurrentDispatchSemantics` | covered by `key-slot-audit` + parity suites | fail if register assignment reappears
NEON | SubI64x8 | reuse_base_scalar | DispatchAPI source truth: `Test_NEON_NoAsmIntegerFallbackSlots_Reuse_BaseScalar_When_Wrappers_Are_Not_BackendOwned` | `Test_WideIntegerArithmeticMinMaxParity_IfAvailable` + `Test_DataPlane_WideArithmeticMinMaxSnapshot_Follows_CurrentDispatchSemantics` | covered by `key-slot-audit` + parity suites | fail if register assignment reappears
RISCVV | AndI64x8 | backend_owned | DispatchAPI source truth: no `AssertRegisterKeepsBaseScalar` exception in RISCVV key-slot procedures | `Test_WideSignedBitwiseShiftParity_IfAvailable` + `BuildOrTest.sh impl-audit-nonx86` | covered by `key-slot-audit` + register truthfulness strict | tighten later if dedicated source assert is added
RISCVV | NotI64x8 | backend_owned | DispatchAPI source truth: no `AssertRegisterKeepsBaseScalar` exception in RISCVV key-slot procedures | `Test_WideSignedBitwiseShiftParity_IfAvailable` + `BuildOrTest.sh impl-audit-nonx86` | covered by `key-slot-audit` + register truthfulness strict | tighten later if dedicated source assert is added
RISCVV | ShiftLeftI32x16 | backend_owned | DispatchAPI source truth: no `AssertRegisterKeepsBaseScalar` exception in RISCVV key-slot procedures | `Test_WideSignedBitwiseShiftParity_IfAvailable` + `BuildOrTest.sh impl-audit-nonx86` | covered by `key-slot-audit` + register truthfulness strict | tighten later if dedicated source assert is added
RISCVV | ShiftRightArithI64x4 | backend_owned | DispatchAPI source truth: no `AssertRegisterKeepsBaseScalar` exception in RISCVV key-slot procedures | `Test_WideSignedBitwiseShiftParity_IfAvailable` + `BuildOrTest.sh impl-audit-nonx86` | covered by `key-slot-audit` + register truthfulness strict | tighten later if dedicated source assert is added
RISCVV | ShiftLeftU32x8 | reuse_base_scalar | Facade source truth: `riscvv.facade.inc` explicit `Result := ScalarShiftLeftU32x8(a, count);` | `TTestCase_NonX86BackendParity` + fresh `qemu-nonx86-evidence` (`linux/arm64`, `linux/riscv64`) | source truth explicit; parity boundary already covered | fail if facade drifts back to wrapper-only/backend-local indirection
RISCVV | ShiftRightU32x8 | reuse_base_scalar | Facade source truth: `riscvv.facade.inc` explicit `Result := ScalarShiftRightU32x8(a, count);` | `TTestCase_NonX86BackendParity` + fresh `qemu-nonx86-evidence` (`linux/arm64`, `linux/riscv64`) | source truth explicit; parity boundary already covered | fail if facade drifts back to wrapper-only/backend-local indirection
RISCVV | SubI32x8 | backend_owned | DispatchAPI source truth: no `AssertRegisterKeepsBaseScalar` exception in RISCVV key-slot procedures | `Test_WideIntegerArithmeticMinMaxParity_IfAvailable` + `BuildOrTest.sh impl-audit-nonx86` | covered by `key-slot-audit` + register truthfulness strict | tighten later if dedicated source assert is added
RISCVV | MinU32x8 | backend_owned | DispatchAPI source truth: no `AssertRegisterKeepsBaseScalar` exception in RISCVV key-slot procedures | `Test_WideIntegerArithmeticMinMaxParity_IfAvailable` + `BuildOrTest.sh impl-audit-nonx86` | covered by `key-slot-audit` + register truthfulness strict | tighten later if dedicated source assert is added
RISCVV | AddI64x4 | backend_owned | DispatchAPI source truth: no `AssertRegisterKeepsBaseScalar` exception in RISCVV key-slot procedures | `Test_WideIntegerArithmeticMinMaxParity_IfAvailable` + `BuildOrTest.sh impl-audit-nonx86` | covered by `key-slot-audit` + register truthfulness strict | tighten later if dedicated source assert is added
RISCVV | MulI32x16 | backend_owned | DispatchAPI source truth: no `AssertRegisterKeepsBaseScalar` exception in RISCVV key-slot procedures | `Test_WideIntegerArithmeticMinMaxParity_IfAvailable` + `BuildOrTest.sh impl-audit-nonx86` | covered by `key-slot-audit` + register truthfulness strict | tighten later if dedicated source assert is added
RISCVV | MaxU32x16 | reuse_base_scalar | DispatchAPI source truth: `Test_RISCVV_WideFallbackOnlySlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders` | `Test_WideIntegerArithmeticMinMaxParity_IfAvailable` + `BuildOrTest.sh impl-audit-nonx86` | covered by `key-slot-audit` + parity suites | fail if register assignment reappears
RISCVV | SubI64x8 | backend_owned | DispatchAPI source truth: no `AssertRegisterKeepsBaseScalar` exception in RISCVV key-slot procedures | `Test_WideIntegerArithmeticMinMaxParity_IfAvailable` + `BuildOrTest.sh impl-audit-nonx86` | covered by `key-slot-audit` + register truthfulness strict | tighten later if dedicated source assert is added

## X86 Bounded Frontier Ledger

backend | slot / family | expected contract | source truth | runtime evidence | current status | next action
--- | --- | --- | --- | --- | --- | ---
AVX512 | U32x16 / U64x8 shift boundary | backend_owned; invalid-count => zero; `0 / width-1 / width` boundary must stay explicit | DispatchAPI source truth: `Test_AVX512_U32x16_U64x8_ShiftBoundary_Contracts` | `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` + `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check` | 2026-04-14 fresh green; bounded frontier closed without reopening wider AVX512 audit | hold green; only reopen if a fresh red point lands on wide shift boundary semantics
AVX2 | SelectF32x16 / SelectF64x8 | vector-asm-gated backend_owned; wide select must stay on AVX2 wide emulation and match scalar lane semantics | DispatchAPI source truth: `Test_AVX2_WideSelect_Parity_WithScalar_When_VectorAsmEnabled` | `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` + `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check` | 2026-04-14 fresh green; proof upgraded from `dispatch == facade` to direct scalar parity | hold green; fail if register binding or scalar lane parity drifts
AVX2 | FmaF32x16 / FmaF64x8 | vector-asm-gated backend_owned; wide FMA must remain exact lo/hi half composition over native FmaF32x8 / FmaF64x4 | DispatchAPI source truth: `Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_AVX2FMA_When_FusedPathUsable` + `Test_AVX2_WideFma_ExactInputs_FollowsHalfComposition` | `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` + `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check` | 2026-04-14 fresh green; proof upgraded from wide-facade parity to register truth + half-composition + exact-input runtime parity | hold green; fail if register ownership, lo/hi composition, or fused-path capability semantics regresses

## Working Rules

- `reuse_base_scalar` 槽位的首要风险不是“没实现”，而是误接回 backend wrapper。
- `backend_owned` 槽位的首要风险不是“未赋值”，而是悄悄退回 scalar-forwarder / wrapper-only 还继续冒充 backend 能力。
- 任何实现侧修复都必须至少给出一条 source truth 和一条 runtime evidence，不能只贴 diff。

## Task 2 / Task 3 回填模板

这两组现在已经按同一格式回填完成，后续维护直接沿下面口径继续：

- `Task 2 / shift-bitwise`：
  - `runtime evidence`：
    - [qemu-multiarch-20260414-083827-1057268/summary.md](/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd/logs/qemu-multiarch-20260414-083827-1057268/summary.md)
    - [qemu-multiarch-20260414-085109-1103235/summary.md](/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd/logs/qemu-multiarch-20260414-085109-1103235/summary.md)
    - [qemu-multiarch-20260414-085836-1128552/summary.md](/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd/logs/qemu-multiarch-20260414-085836-1128552/summary.md)
  - `current status`：2026-04-15 fresh on `helper semantics checks=41` + `impl-audit-full` + `impl-audit-nonx86` + `qemu-nonx86-evidence` + `closeout-host-local`
  - `next action`：hold green; fail if NEON shift fallback / NEON select lane semantics / wide shift boundary semantics regresses
- `Task 3 / arithmetic-minmax-mul`：
  - `runtime evidence`：
    - [qemu-multiarch-20260414-083827-1057268/summary.md](/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd/logs/qemu-multiarch-20260414-083827-1057268/summary.md)
    - [qemu-multiarch-20260414-085109-1103235/summary.md](/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd/logs/qemu-multiarch-20260414-085109-1103235/summary.md)
    - [qemu-multiarch-20260414-085836-1128552/summary.md](/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd/logs/qemu-multiarch-20260414-085836-1128552/summary.md)
  - `current status`：2026-04-15 fresh on targeted release suites + `impl-audit-full` + `impl-audit-nonx86` + `qemu-nonx86-evidence` + `closeout-host-local`
  - `next action`：hold green; fail if truncation probe / lane-tag probe / dataplane snapshot coverage regresses
- `NEON hygiene`：
  - `source truth`：`check_nonx86_helper_semantics.py` 现在会锁 `NEONShiftLeftI32x16`、`NEONShiftRightArithI64x4`、`NEONShiftLeftI64x4Asm`、`NEONSelectF32x4`
  - `runtime evidence`：跟 `Task 2` 共用 2026-04-14 fresh QEMU + closeout summaries
  - `current status`：green in current worktree
  - `next action`：如果后续切历史，可单列为 `NEON shift/select hygiene`
- `RISCVV facade/register hygiene`：
  - `source truth`：`riscvv.facade.inc` 现在把 scalar-pass-through facade helper 留在 base scalar slot；其中 `RISCVVShiftLeftU32x8` / `RISCVVShiftRightU32x8` 已显式回到 `ScalarShiftLeftU32x8` / `ScalarShiftRightU32x8`。`riscvv.register.inc` 里的 `ExtractI64x4`、`ExtractI32x8`、`ExtractI32x16` 保留显式 asm-gated 结构，不能直接折叠成 unconditional binding
  - `runtime evidence`：`NONX86_REGISTER_TRUTHFULNESS_SUMMARY backend=riscvv assignments=467 asm_exact=337 asm_suffix_only=110 wrapper_only=20 scalar_passthrough=0 no_def=0 miswired=0 strict=1` + `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=riscvv slots=10 issues=0 status=ok` + `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
  - `current status`：green in current worktree
  - `next action`：hold green; do not collapse those `Extract*` branches unless the truthfulness checker contract changes with it

## Execution Baseline

每一轮 implementation 审查至少 fresh 跑下面这几条：

- x86 bounded frontier：`impl-smoke-x86`，固定重跑 `DispatchAPI` 里当前已经钉住的 `AVX512 shift boundary`、`AVX2 wide select`、`AVX2 wide FMA composition` proof；它是高频 smoke，不替代 full closeout。
- 高频日常层：`impl-smoke-nonx86`，只用来快速确认 helper semantics / wiring ownership / targeted parity 没有 fresh 漂移；它不是 `impl-audit-nonx86` 或 `closeout-host-local` 的替代品。
- 实现深审主线：`impl-audit-full`，固定顺序 `impl-smoke-x86 -> impl-audit-nonx86`；它是当前 worktree 的 full implementation audit 入口，`closeout-host-local` 也应复用这条链，而不是绕过 x86 frontier。
- 当前没有 `arm64` / `riscv64` 实机时，fresh `linux/arm64` + `linux/riscv64` QEMU 结果已经足够作为 non-x86 closeout 证明；本轮 formalized closeout 对应的 summary 是 [qemu-multiarch-20260415-231755-781545/summary.md](/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-freeze-closeout-20260415/tests/fafafa.core.simd/logs/qemu-multiarch-20260415-231755-781545/summary.md) 和 [qemu-multiarch-20260415-232437-788450/summary.md](/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-freeze-closeout-20260415/tests/fafafa.core.simd/logs/qemu-multiarch-20260415-232437-788450/summary.md)。

```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-smoke-x86
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-smoke-nonx86
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-full
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86
SIMD_QEMU_BUILD_POLICY=if-missing SIMD_QEMU_PLATFORMS='linux/arm64 linux/riscv64' FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh qemu-nonx86-evidence
SIMD_QEMU_PLATFORMS='linux/arm64 linux/riscv64' SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=0 FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh closeout-host-local
```
