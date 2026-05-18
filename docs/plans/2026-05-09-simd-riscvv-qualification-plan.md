# SIMD RISCVV Qualification Plan

**Goal:** 把 `RISCVV` 从“opt-in backend + implementation evidence 已存在”的状态，补成一份 family-level qualification plan，明确它为什么现在仍应保持 opt-in、哪些 contract 已经稳定、哪些前提满足后才能讨论更进一步的 stable 化。

**Architecture:** `RISCVV` 当前继续保留为 `opt-in only` backend。stable truth source 仍是 `src/fafafa.core.simd.riscvv.pas`；`src/fafafa.core.simd.intrinsics.rvv.pas` 继续保持 `experimental isolated`。本计划只做 qualification，不做默认 stable 路径扩张。

**Tech Stack:** `src/fafafa.core.simd.riscvv.pas`、`src/fafafa.core.simd.intrinsics.rvv.pas`、`riscvv.facade.inc`、`riscvv.register.inc`、`BuildOrTest.sh` 的 `riscvv-opcode-lane / impl-audit-nonx86 / closeout-host-local`、truthfulness / ABI shape checker。

---

## 当前稳定判断

### truth source

- stable truth source：`src/fafafa.core.simd.riscvv.pas`
- raw leaf：`src/fafafa.core.simd.intrinsics.rvv.pas`
- current disposition：`experimental isolated`
- façade status：`opt-in only`

### 当前最重要的事实

- `RISCVV` 不是“还没工作”的 family；它已经有 dedicated source truth、register truthfulness 和 opcode lane
- 但它仍不适合作为 default stable family，因为当前 stable contract 仍明确要求 opt-in
- 这条 family 最值钱的不是“继续扩默认入口”，而是守住 opt-in 下的 correctness 与 qualification

## 当前必须守住的特殊规则

### 1. opt-in only

`RISCVV` 只有在显式打开相关 experimental/backend 条件时才接入 umbrella unit。

这条边界当前不能放宽。

### 2. opcode lane 不能丢

`riscvv-opcode-lane` 当前不是附属脚本，而是这条 family 的关键 qualification 入口。

如果这条 lane 退化，`RISCVV` 的 raw/asm side 质量会重新变得不可见。

### 3. facade/register hygiene 不能折叠掉

当前文档链已经明确：

- 部分 scalar-pass-through helper 必须继续显式留在 base scalar slot
- `Extract*` 必须保留 asm-gated register 结构，但 no-asm host 应直接 reuse base scalar slot，不该再回流到 RISCVV no-asm wrapper
- `Ceil/Floor/Round/TruncF32x8/F64x4/F32x16/F64x8` 与 `ClampF32x8/F32x16` 现在也已经翻正为 `reuse base scalar`，不该再恢复成 RISCVV family-local scalar-forward wrapper；这组里仍保留 backend-owned 的只剩 `ClampF64x4/F64x8`
- `DotF64x2/F64x4` 也已经翻正为 `reuse base scalar`：source/facade dead scalar-forward owner 与 register binding 都已删除，不该再冒充 RISCVV backend-owned slot

## 当前 verification lane

### 高频 smoke

```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh nonx86-optin-list-suites
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-smoke-nonx86
```

### implementation / contract audit

```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh
python3 tests/fafafa.core.simd/check_riscvv_abi_shape.py --summary-line
python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict
python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --summary-line
```

### host-local / closeout lane

```bash
SIMD_QEMU_PLATFORMS='linux/arm64 linux/riscv64' SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=0 FAFAFA_BUILD_MODE=Release \
bash tests/fafafa.core.simd/BuildOrTest.sh closeout-host-local
```

## 当前 family-level 重点

### source-side

- `Test_RISCVV_KeyOwnedWideSlots_Stay_BackendOwned`
- `Test_RISCVV_WideFallbackOnlySlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders`
- `Test_RISCVV_WideRoundingAndF32ClampSlots_Reuse_BaseScalar_When_ScalarForwarders_Are_Dead`
- `Test_RISCVV_DotF64Slots_Reuse_BaseScalar_When_ScalarForwarders_Are_Dead`
- `riscvv.facade.inc` 中 scalar-pass-through helper 的显式回退
- `riscvv.register.inc` 中 `Extract*` 的 asm-only binding + no-asm scalar reuse 形状，以及 wide `round/clamp` 这 18 个 slot 和 `DotF64x2/F64x4` 已回到 base scalar 的 register truth

### runtime-side

- `register truthfulness strict`
- `key-slot-audit`
- `impl-audit-nonx86`
- `riscvv-opcode-lane`
- `qemu-nonx86-evidence`
- `closeout-host-local`

## 这轮 qualification 的任务

## Task 1：固定 RISCVV 为 opt-in family，而不是半稳定默认 family

当前 whole-module 计划里，这条 family 的正确定位是：

- adapter 已存在
- verification lane 已存在
- 仍然 opt-in
- 当前不扩大默认 stable surface

## Task 2：固定 facade/register hygiene contract

后续任何改动都先守住：

- backend-owned key wide slots
- scalar-pass-through helper 不得误接回 backend wrapper
- `Extract*` asm-gated register 结构不得被“重构优化”掉，也不要重新引回 no-asm RISCVV wrapper
- wide `round/clamp` 这 18 个 slot 不得再恢复成 no-asm RISCVV scalar-forward wrapper；如果未来真要改回 backend-owned，必须连 source/checker/doc/runtime 合同一起重写
- `DotF64x2/F64x4` 不得再恢复成 dead RISCVV scalar-forward owner 或 register-owned backend slot；如果未来真要改回 backend-owned，必须先拿 fresh parity / source / checker / runtime 四层证据一起翻案

## Task 3：固定 ABI / opcode qualification

`RISCVV` 和 `NEON` 最大不同是：

- 它更依赖 toolchain / opcode lane / ABI shape 的健壮性

所以这条 family 的 qualification 不只看 parity，还必须继续看：

- `check_riscvv_abi_shape.py`
- `run_riscvv_opcode_lane.sh`

## Task 4：定义 future promote 前提

如果未来有人想让 `RISCVV` 进入更强的 stable 路径，先满足：

1. opt-in 与 default stable 的边界重新设计清楚
2. raw leaf 有独立 family-specific parity 文档
3. toolchain / opcode lane / ABI shape 不是脆弱前置条件

在这些条件之前，继续按 `hold opt-in / hold isolated` 处理。

## 不做什么

- 不把 `RISCVV` 直接拉进 default façade
- 不因为 current green 就删掉 opcode lane / ABI shape checker
- 不把 facade/register hygiene 重新压回“默认应该自动对”的隐性结构

## 完成标准

这份计划完成后，`RISCVV` 应达到：

1. family-level 定位清楚：opt-in only
2. facade/register/opcode/ABI 四条 qualification 链固定
3. 后续要继续稳定化时，有明确 promote 前提，而不是临时拍板
