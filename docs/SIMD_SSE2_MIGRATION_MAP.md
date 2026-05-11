# SIMD SSE2 Migration Map

这份表不是“现在就大搬家”的施工单，而是之后每一次 SSE2 收口时必须遵守的分桶图。

核心原则先写死：

- 不做破坏性 rename
- 不一次性搬空 `src/fafafa.core.simd.sse2.pas`
- 迁移的是 raw 128-bit leaf 语义，不是把 `TVec*` façade 整体换名
- 当前发布真相源仍然是 `src/fafafa.core.simd.sse2.pas`

## A - 迁入 `intrinsics.x86.sse2`

这桶只接收“可纯化的 128-bit raw primitive”。

| Family                             | Current `simd.sse2` examples                                               | Migration rule                                                            |
| ---------------------------------- | -------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| raw load/store                     | `SSE2LoadF32x4`、`SSE2StoreF32x4`、`SSE2LoadF64x2`、`SSE2StoreF64x2`       | 只抽 raw `TM128` load/store leaf；`TVec*` façade 名字仍保留在 `simd.sse2` |
| raw set/zero/broadcast             | `SSE2ZeroF32x4`、`SSE2SplatF32x4`、`SSE2ZeroF64x2`、`SSE2SplatF64x2`       | 只抽 raw `set/zero` leaf；adapter 继续负责向量语义包装                    |
| raw arithmetic                     | `SSE2AddF32x4`、`SSE2SubF32x4`、`SSE2MulF32x4`、`SSE2AddI32x4`             | 只抽 raw `add/sub/mul` leaf；外层 `TVec*` API 不迁名                      |
| raw bitwise / compare / shift      | `SSE2AndI32x4`、`SSE2OrI32x4`、`SSE2CmpEqF64x2`、`SSE2ShiftLeftI32x4`      | 只抽 raw ISA building blocks；mask 压缩/翻译仍留在 adapter                |
| raw unpack / pack / shuffle / cast | `SSE2SelectF64x2` 周边 raw 组合、各类 `pack/unpack/shuffle` building block | 只抽 `TM128` leaf；不要把 façade 级 `TMask*` / `TVec*` 选择逻辑带进去     |

规则：

- A 桶迁的是 leaf，不是 façade symbol 本身。
- `intrinsics.x86.sse2` 只接受 `TM128` / raw intrinsic 风格接口。
- 迁一族，补一族 raw semantic parity 证据。
- 只要 `intrinsics.x86.sse2` 的 disposition 仍是 `experimental isolated`，A 桶仍只是目标归属图，不是 stable adapter 可直接依赖它的授权。
- `simd.sse2` 想开始默认委托给 A 桶对象，前提是：目标 leaf 已经是 `active leaf`，或者先拆出新的 `active leaf` 子集。

## B - 永久保留在 `simd.sse2`

| Family                                      | Examples                                                                                                                                     | Keep reason                                    |
| ------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| backend 注册与 dispatch 接线                | `RegisterSSE2Backend`                                                                                                                        | 这是 backend adapter 的职责，不属于 intrinsics |
| `TVec*` / `TMask*` façade 语义              | `SSE2AddF32x4`、`SSE2CmpEqF64x4`、`SSE2SelectF64x2`                                                                                          | façade 语义、mask 语义、返回类型都属于 adapter |
| compare-mask 压缩/翻译                      | `TMask2/TMask4/TMask8/TMask16` 相关翻译逻辑                                                                                                  | raw leaf 不负责 façade 级 mask contract        |
| mem/text/stat helper                        | `MemEqual_SSE2`、`MemFindByte_SSE2`、`MemDiffRange_SSE2`、`Utf8Validate_SSE2`                                                                | 这些是 façade helper，不是 raw ISA leaf        |
| wide emulation / multi-register composition | `fafafa.core.simd.sse2.wide_emulation.inc`、`SSE2AddF32x8`、`SSE2AddF32x16`、`SSE2AddF64x4`、`SSE2AddF64x8`、`SSE2AddI32x8`、`SSE2AddI32x16` | 这些语义天然跨多个 128-bit leaf，归 adapter 层 |

规则：

- 就算以后抽出了 raw leaf，`SSE2*` 这层 adapter 名字仍然保留在 `simd.sse2`。
- `wide_emulation` 不进入 `intrinsics.x86.sse2`。
- `simd.sse2` 不得反向依赖 `intrinsics.sse2`。

## C - 迁移后删除 / 废弃

当前 production export 没有预先指定到这桶。

这不是遗漏，而是保守迁移规则：

- 今天不要预删任何 `simd.sse2` 正式导出符号。
- 只有未来为了迁移临时引入的 bridge/helper，才允许进入 C 桶。
- 这类对象必须在代码和文档里明确标成 temporary bridge，然后在 parity 证据齐全后删除。

一句话说死：

> C 桶当前刻意为空；如果未来有人想删 `simd.sse2` 的正式导出，先补设计和 parity 证据。

当前的 retire baseline 见：

- `docs/plans/2026-05-09-simd-sse2-retire-target-plan.md`
