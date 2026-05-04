# SIMD Review Findings

## Structural Observations

- `fafafa.core.simd` 已有较完整的文档体系，包含 `map`、`maintenance`、`checklist`、`handoff`、`publicabi` 和 `cpuinfo` 专项文档。
- 模块分层清晰地围绕 `public facade -> dispatch -> backend -> infra(cpuinfo/base/memutils)` 展开。
- 仓库明确区分了 stable surface 与 experimental surface，尤其强调 `sbRISCVV` 为显式 opt-in。
- 当前维护文档反复强调：真正成熟的主线是 `simd/dispatch/cpuinfo/avx2/avx512/neon` 的“按需修正”，而不是继续做大规模结构拆分。
- `SSE2` 被仓库显式标记为“稳定边界但不宜继续硬拆”的特殊区，说明其历史包袱和编译器敏感性仍是核心维护风险。

## Initial Risks To Validate

- 文档成熟度是否高于代码和测试现实，特别是 non-x86 / AVX-512 / public ABI 的验证闭环。
- `dispatch/cpuinfo/publicabi` 语义是否在代码、测试、文档三处完全同步。
- `BuildOrTest.sh gate` 与 evidence 脚本是否已成为可靠的发布门禁，还是仍依赖人工补洞。

## Program State Signals

- `backlog.md` 中 SIMD 长期板的当前未完成主项已明显收敛到 `SIMD-B23(candidate)`：fresh Linux/Windows evidence refresh，把 `freeze-status` 从 freshness/source-newer-than-evidence 红态拉回绿态。
- 历史上大量 SIMD 批次已经标记为完成，说明当前问题更像“成熟化收尾”和“证据闭环”而不是“核心能力缺失”。
- 维护文档与 backlog 一致传递同一方向：`gate` 适合作为日常快门禁，`gate-strict/freeze-status/native-evidence/win-evidence-via-gh` 才是发布级收口链路。

## Source/Gate Truth Signals

- 当前 worktree 存在未提交的 SIMD 相关改动，至少涉及 `src/fafafa.core.simd.pas`、`src/fafafa.core.simd.dispatch.pas`、`src/fafafa.core.simd.direct.pas`、`src/fafafa.core.simd.public_abi.impl.inc`，审查必须覆盖增量 diff，而不能只看静态现状。
- `tests/fafafa.core.simd/BuildOrTest.sh` 已形成较强的多层门禁骨架：`check -> suite smoke -> gate -> gate-strict -> freeze-status/native-evidence`。
- `BuildOrTest.sh` 明确把 `contract-signature`、`publicabi-signature`、non-x86 opt-in smoke、Windows evidence、freeze-status` 等纳入收口链路，说明成熟度瓶颈更可能在证据新鲜度与跨平台执行成本，而非缺少门禁入口。

## Diff Review Notes

- 当前 diff 仅做原子 API 统一替换：把 `atomic_load_ptr/atomic_store_ptr` 切到 `atomic_load/atomic_store` 的 `Pointer` 重载。
- `src/fafafa.core.atomic.pas` 已直接提供 `Pointer` 的重载实现，显式 `mo_acquire/mo_release` 路径与旧接口语义一致；仓库文档也把 `_ptr` 后缀视为可收敛的冗余接口。
- 到目前为止，增量 diff 未显示新的状态机、边界语义或 ABI 形状变更，更像一次 API 口径统一而非行为修改。

## Verification Notes

- `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check` 通过。
- `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` 通过。
- `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch` 通过。
- 当前尚未发现这次 atomic API 替换导致的编译、dispatch、direct dispatch 回归。
- `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate` 通过。
- `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status` 失败，但失败项集中在发布级证据链，而非代码行为。

## Release-Readiness Gaps

- `freeze-status` 已确认 Linux 主 gate 新鲜且通过，但 `qemu-cpuinfo-nonx86-evidence` 在最近 gate 里为 `SKIP`，因此 mainline/cross ready 仍为 `False`。
- Windows evidence 已存在且 verifier 通过，但 `windows_b07_gate.log` 与 `windows_b07_closeout_summary.md` 均已超过 freshness 阈值，且旧于最新 SIMD 源码。
- 这说明当前 SIMD 的成熟度问题不是“没有测试”或“当前 diff 有 bug”，而是“发布级跨平台证据没有按当前源码时间线刷新”。

## Evidence Sources

- `docs/fafafa.core.simd.md`
- `docs/fafafa.core.simd.cpuinfo.md`
- `docs/fafafa.core.simd.checklist.md`
- `docs/fafafa.core.simd.handoff.md`
- `src/fafafa.core.simd.README.md`
- `tests/fafafa.core.simd/BuildOrTest.sh`
