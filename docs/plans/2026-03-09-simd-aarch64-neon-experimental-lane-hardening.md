# SIMD AArch64 NEON Experimental Lane Hardening Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 把 `qemu-nonx86-experimental-asm` 里 arm64 暴露的 AArch64/NEON experimental asm 问题，从“污染稳定结论的噪声”收敛成一个可维护、可单独验收的 dedicated lane。

**Architecture:** 保持 stable/public surface 不变，不在 stable arch-matrix 中强开 experimental NEON asm。实现上先把 `neon.pas` 中仅属于 experimental lane 的 AArch64 asm 块、宽向量/Mask 注册项、以及 FPC 3.3.1/GAS 方言不兼容点分离出来，再决定哪些应该修、哪些应该明确 fallback、哪些只保留 dedicated evidence lane。

**Tech Stack:** FreePascal 3.3.1、AArch64 inline asm、Docker/QEMU arm64、`run_multiarch_qemu.sh` probe/fallback、SIMD dispatch registration、file-based planning.

---

### Task 1: Freeze the current arm64 failure surface

**Files:**
- Review: `src/fafafa.core.simd.neon.pas`
- Review: `tests/fafafa.core.simd/docker/run_multiarch_qemu.sh`
- Review: `tests/fafafa.core.simd/BuildOrTest.sh`
- Verify: latest `qemu-nonx86-experimental-asm` arm64 log

**Step 1: Record current arm64 failure classes**

Expected categories:
- AArch64 asm syntax / arrangement failures
- unsupported opcodes under current FPC/GAS path
- missing `NEONMask*` / wide-vector registration symbols
- probe failure fallback behavior that currently still mixes with unstable defines

**Step 2: Separate stable-path invariants from experimental-only symbols**

Output:
- one list of symbols that must stay available for stable/public surface
- one list of symbols that may stay experimental-only / fallback-only

### Task 2: Build a dedicated arm64 experimental lane contract

**Files:**
- Modify: `tests/fafafa.core.simd/docker/run_multiarch_qemu.sh`
- Modify: `tests/fafafa.core.simd/BuildOrTest.sh`
- Modify: docs referencing experimental asm behavior

**Step 1: Define lane behavior**
- stable QEMU arch matrix remains `SIMD_VECTOR_ASM_DISABLED`
- experimental arm64 lane may probe asm
- probe failure may fall back, but summary must clearly distinguish:
  - `probe-pass`
  - `probe-fallback-pass`
  - `fallback-fail`

**Step 2: Avoid using generic `qemu-nonx86-experimental-asm` as the truth source for RVV**
- RVV keeps its dedicated lane
- arm64 gets its own explicit statement in docs/checklists

### Task 3: Audit and classify `src/fafafa.core.simd.neon.pas`

**Files:**
- Modify: `src/fafafa.core.simd.neon.pas`

**Step 1: Group failures by type**
- syntax fixes that are safe and local
- opcodes that need fallback wrappers
- registrations that should not be wired when symbols are absent

**Step 2: Patch the smallest safe subset first**
- prioritize compile blockers that affect dedicated lane creation
- do not widen stable/public surface claims in this task

### Task 4: Make registration/fallback behavior explicit

**Files:**
- Modify: `src/fafafa.core.simd.neon.pas`
- Review: `src/fafafa.core.simd.dispatch.pas`

**Step 1: Ensure absent experimental helpers never break stable registration**
- wide-vector / mask helpers should either exist or cleanly fall back
- no unresolved `NEONMask*` style symbol should leak into stable path

**Step 2: Keep experimental-only overrides clearly guarded**
- guard them behind `FAFAFA_SIMD_NEON_ASM_ENABLED` or a narrower arm64 experimental macro

### Task 5: Verify the lane model

**Files:**
- Verify: new / updated arm64 experimental evidence summary
- Verify: `qemu-arch-matrix-evidence`
- Verify: `freeze-status-full-platform`

**Step 1: Stable re-check**
Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arch-matrix-evidence
bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-full-platform
```
Expected:
- both remain green

**Step 2: Experimental arm64 lane**
Run:
```bash
SIMD_QEMU_ENABLE_BACKEND_ASM=1 bash tests/fafafa.core.simd/BuildOrTest.sh qemu-nonx86-experimental-asm
```
Expected:
- summary truthfully distinguishes arm64 probe result vs fallback result
- stable/public surface claim remains unchanged


## 当前进展（2026-03-09）

- `qemu-arm64-experimental-asm` 已经独立落地，并且 latest summary 为 `probe-pass`。
- generic `nonx86-experimental-asm` 仍保留，但主要用于跨平台 probe/fallback 对比；arm64 真正的专项观察入口已转向 dedicated lane。
- 已完成第二个小步 registration helper：`ApplyNEONExperimentalWideF32Overrides`，只承接 experimental-wide `F32x8/F32x16` 注册。
- 已确认 helper 也必须跟随同层 `{$IFNDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` guard；否则 dedicated arm64 probe build 会报 `Identifier not found`。
- fresh `qemu-arm64-experimental-asm` 继续 `probe-pass`：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-142616-39694/summary.md`。
- fresh `qemu-arch-matrix-evidence` 也再次 PASS：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-142930-53109/summary.md`。
- 已完成第三个小步 registration helper：`ApplyNEONExperimentalWideF64Overrides`，承接 experimental-wide `F64x2/F64x4/F64x8` 注册。
- 已完成第四个小步 registration helper：`ApplyNEONExperimentalWideNarrowIntOverrides`，承接 `I8x16/I16x8/U8x16/U16x8` 的 experimental-wide `Cmp*` / `Shift*` 注册。
- fresh `qemu-arm64-experimental-asm` 继续 `probe-pass`：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-144733-120311/summary.md`。
- fresh `qemu-arch-matrix-evidence` 再次 PASS：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-144945-130285/summary.md`。
- 已完成第五个小步 registration helper：`ApplyNEONExperimentalWideI32U32Overrides`，承接 experimental-wide `I32/U32` 注册。
- 已完成第六个小步 registration helper：`ApplyNEONExperimentalWideI64U64Overrides`，承接 experimental-wide `I64/U64` 注册。
- 当前 `RegisterNEONBackend` 的 experimental-wide 区域已全部 helper 化；后续 Phase 2 可把重心从 registration 抽离转到实现层 opcode/fallback hardening。
- 需要新增流程纪律：不要并行运行两个会写同一个 `aarch64-linux` 输出目录的 lane；latest 结论应以串行重跑后的证据为准。
- latest clean `qemu-arm64-experimental-asm` 为 `probe-pass`：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-152018-311706/summary.md`。
- latest clean `qemu-arch-matrix-evidence` 为 PASS：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-152247-329057/summary.md`。
- 已开始从 registration 抽离转向 implementation-layer hardening：先把 `dot/reduce/splat` 中可安全组合的 wide wrapper 收敛到窄 NEON 组合。
- 已把 wide float `Add/Sub/Mul/Div`（`F32x8/F32x16/F64x4/F64x8`）的 asm-enabled 路径改为 `lo/hi` 组合窄 NEON。
- latest clean `qemu-arm64-experimental-asm` 继续 `probe-pass`：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-154903-483461/summary.md`。
- latest clean `qemu-arch-matrix-evidence` 继续 PASS：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-155202-503518/summary.md`。
- 已完成一轮 wide-float math/comparison hardening：把 wide float `Math + Compare` 大批 wrapper 从 `Scalar*` 收敛为窄 NEON 组合。
- 需要注意 Pascal 实现区顺序：若 `F32x16` wrapper 先调用 `F32x8` wrapper，则必须补 `forward` 声明。
- latest clean `qemu-arm64-experimental-asm` 继续 `probe-pass`：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-204347-665815/summary.md`。
- latest clean `qemu-arch-matrix-evidence` 继续 PASS：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-204526-670171/summary.md`。
- 已完成一轮 wide-float `Select + Load/Extract/Insert` hardening：对应 façade 现在优先走窄 NEON 组合。
- 对 `F32x16 -> F32x8` 的调用链需要 `forward` 声明；这是 Pascal 实现区顺序约束的一部分。
- latest clean `qemu-arm64-experimental-asm` 继续 `probe-pass`：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-210439-771359/summary.md`。
- latest clean `qemu-arch-matrix-evidence` 继续 PASS：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-210621-775332/summary.md`。
- 已完成一轮 wide-integer bitwise hardening：`I32/I64/U32` 的 wide bitwise façade 大部分已转为窄 NEON 组合。
- `I64x4 AndNot` 需要注意：下层没有 `NEONAndNotI64x2`，只能用 `And(Not(b))` 的等价组合。
- latest clean `qemu-arm64-experimental-asm` 继续 `probe-pass`：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-212410-857149/summary.md`。
- latest clean `qemu-arch-matrix-evidence` 继续 PASS：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-212603-865400/summary.md`。
- 已完成一轮 wide-integer arithmetic/minmax hardening：有窄 helper 的 wide `Add/Sub/Mul/Min/Max` 已转为 `lo/hi` 组合。
- `U64x4` 这类没有现成窄 helper 的点暂时保留，避免混入新的手写逐 lane 语义。
- latest clean `qemu-arm64-experimental-asm` 继续 `probe-pass`：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-213748-906016/summary.md`。
- latest clean `qemu-arch-matrix-evidence` 继续 PASS：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-213927-909069/summary.md`。
- 已完成一轮 wide-integer access/selection hardening：`I32/I64` 的 `extract/insert/load/select` façade 已显著收敛。
- `I64x4` shift 没有 `I64x2` helper 可复用，必须逐 lane；`CmpNeU32x4` 也需要本地 fallback 补齐。
- latest clean `qemu-arm64-experimental-asm` 继续 `probe-pass`：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-222416-1142098/summary.md`。
- latest clean `qemu-arch-matrix-evidence` 继续 PASS：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-225005-1278406/summary.md`。
