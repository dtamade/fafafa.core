# SIMD SSE2 Retire Target Plan

**Goal:** 冻结 `SSE2` 的 retire target 列表，明确哪些东西永远留在 adapter，哪些东西只有在 raw leaf 迁移证据齐全后才允许进入 delete bucket。

**Architecture:** 这不是一份“现在就删 SSE2”的施工单。当前发布真相仍然是 `src/fafafa.core.simd.sse2.pas`；`src/fafafa.core.simd.intrinsics.sse2.pas` 仍是 transitional compatibility wrapper；`src/fafafa.core.simd.intrinsics.x86.sse2.pas` 仍是未来 raw leaf target。C 桶当前保持空白，只记录未来可删除对象的准入条件。

**Tech Stack:** `src/fafafa.core.simd.sse2.pas`、`src/fafafa.core.simd.intrinsics.sse2.pas`、`src/fafafa.core.simd.intrinsics.x86.sse2.pas`、`docs/SIMD_SSE2_MIGRATION_MAP.md`、`docs/SIMD_INTRINSICS_DISPOSITION.md`、`tests/fafafa.core.simd/check_sse2_structure.py`、`BuildOrTest.sh impl-smoke-sse2 / check / gate`。

---

## 当前冻结结论

- `SSE2` 当前没有任何 production export 进入 retire bucket。
- `docs/SIMD_SSE2_MIGRATION_MAP.md` 的 C 桶继续保持空白。
- 任何未来 retire target 都必须先有 replacement、parity、release gate 和 migration map 更新。

## 永久保留在 adapter

这些职责不进入 C 桶：

- backend 注册与 dispatch 接线
- `TVec*` / `TMask*` façade 语义
- compare-mask 压缩 / 翻译
- mem / text / stat helper
- `wide_emulation`
- 多寄存器组合语义

## 未来才可能进入 C 桶

只有满足下面条件，才允许把对象写进 retire target 列表：

1. `intrinsics.x86.sse2` 已经成为 `active leaf`
2. `simd.sse2` 侧已有 replacement 并通过 release parity
3. `check_sse2_structure.py` 继续把角色标记、依赖边界和 migration map 判定为绿
4. `check` / `gate` 继续保持绿

典型候选只包括：

- 临时 bridge/helper
- 只为迁移而存在的兼容壳
- 迁移后不再需要的文档级 shim

## 不会进入 C 桶

这些对象是 SSE2 现在必须保留的 adapter 责任：

- `RegisterSSE2Backend`
- 任何 `TVec*` / `TMask*` 公共 API
- `wide_emulation`
- `Mem*` / `Utf8Validate*` / `Stat*` 一类 façade helper
- 任何 dispatch / runtime / control-plane 依赖

## Verification lane

Run:

```bash
python3 tests/fafafa.core.simd/check_sse2_structure.py --summary-line
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-smoke-sse2
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

## Completion criteria

这份文档完成时，应该满足：

1. `SSE2` 的 retire bucket 继续保持空白，直到有真正的 replacement 和 parity 证据。
2. 一旦某个对象进入 C 桶，它就必须同时写清 replacement、删除条件和验证 lane。
3. `docs/SIMD_SSE2_MIGRATION_MAP.md`、`docs/SIMD_INTRINSICS_DISPOSITION.md`、`docs/SIMD_BACKEND_TRUTH.md` 仍然相互一致。
