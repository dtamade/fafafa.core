# SIMD NEON Qualification Plan

**Goal:** 把 `NEON` 从“adapter 已很成熟，但 raw leaf 仍在 experimental isolated、implementation 证据主要散在 non-x86 ledger”提升到 family-level qualification 可执行状态。

**Architecture:** `NEON` 当前不做“立刻 promote raw leaf”式重构。稳定真相源继续是 `src/fafafa.core.simd.neon.pas`；`src/fafafa.core.simd.intrinsics.neon.pas` 继续保持 `experimental isolated`。这轮只做资格化：把 adapter truth、helper semantics、register truthfulness、QEMU/host-local evidence 和 future leaf promote 条件写清楚。

**Tech Stack:** `src/fafafa.core.simd.neon.pas`、`src/fafafa.core.simd.intrinsics.neon.pas`、`docs/fafafa.core.simd.implementation-matrix.md`、`BuildOrTest.sh impl-smoke-nonx86 / impl-audit-nonx86 / closeout-host-local`、non-x86 truthfulness/semantics checkers。

---

## 当前稳定判断

### truth source

- stable truth source：`src/fafafa.core.simd.neon.pas`
- raw leaf：`src/fafafa.core.simd.intrinsics.neon.pas`
- current disposition：`experimental isolated`

### 当前最重要的事实

- `NEON` backend 不是半成品；已有实现和 non-x86 evidence 已经很强
- 当前阻塞点不是“有没有 backend”，而是 family-level 文档还没把 qualification 条件写死
- `NEON` 目前最适合的动作不是直接 promote leaf，而是先把 adapter truth / helper semantics / non-x86 evidence 三层链条固定住

## 当前必须守住的边界

### adapter 边界

`src/fafafa.core.simd.neon.pas` 继续承担：

- backend 注册
- façade 语义
- wide fallback / select / arithmetic helper
- 与 non-x86 register ownership 对应的 adapter contract

### leaf 边界

`src/fafafa.core.simd.intrinsics.neon.pas` 继续保持：

- experimental isolated
- 不默认进入 stable adapter 新依赖
- 只在后续 promotion 条件满足时，才讨论 active leaf 路径

## 当前 verification lane

### 高频 smoke

```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-smoke-nonx86
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh nonx86-optin-list-suites
```

### 实现审计

```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86
python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict
python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line
python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --summary-line
```

### host-local / closeout lane

```bash
SIMD_QEMU_PLATFORMS='linux/arm64 linux/riscv64' SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=0 FAFAFA_BUILD_MODE=Release \
bash tests/fafafa.core.simd/BuildOrTest.sh closeout-host-local
```

## 这条 family 当前最值得守的证据

### source-side

- `docs/fafafa.core.simd.implementation-matrix.md` 已把 `NEON` 的 high-value ownership slot 列出来
- `NEON hygiene` 当前已 green
- `I64x2/U64x2/U64x4` 左移 widening 语义已和 `I64x4` 对齐

### runtime-side

- `helper semantics`
- `key-slot-audit`
- `register truthfulness strict`
- `impl-audit-nonx86`
- `qemu-nonx86-evidence`
- `closeout-host-local`

### 当前 next action

- hold green
- fail if `NEON shift/select hygiene`、wide integer min/max、或 register ownership 漂移

## 这轮 qualification 的任务

## Task 1：固定 NEON 的 family-level source-of-truth

当前 `NEON` 的 stable truth source 只有一个：

- `src/fafafa.core.simd.neon.pas`

说明：

- `intrinsics.neon` 还不是默认 stable 依赖
- 后续任何“NEON raw leaf 是否可 promote”讨论，都不能跳过这条前提

## Task 2：固定 NEON helper semantics / ownership 链

当前 family-level 重点不是全量 API，而是 high-value contract：

- `ShiftLeftI32x16`
- `ShiftRightArithI64x4`
- `SubI32x8`
- `MinU32x8`
- `wide bitwise / arithmetic dataplane snapshot`

要求：

- `backend_owned` 的继续 backend-owned
- `reuse_base_scalar` 的继续 reuse base scalar
- 不允许“wrapper-only 但还冒充 backend”这类漂移

## Task 3：固定 NEON promotion 前提

`intrinsics.neon` 如果未来要进入 `active leaf`，先满足：

1. 有 family-specific raw tests，而不只是 opt-in compile smoke
2. 有 leaf-level parity 文档
3. 有清楚的 adapter/leaf 职责分账

在这 3 条之前，统一按 `hold isolated` 处理。

## 不做什么

- 不在这轮直接把 `intrinsics.neon` promote 成 `active leaf`
- 不因为 backend 很大、实现很多，就自动等于 leaf 已成熟
- 不把 `NEON` 继续留在“implementation matrix 里有证据，但 family-level 文档缺席”的状态

## 完成标准

这份计划完成后，`NEON` 应达到：

1. family-level truth source 清楚
2. helper semantics / ownership / QEMU evidence 串成一条固定验证链
3. future promote 的前提写死，不再靠临场判断
