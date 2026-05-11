# SIMD Family Decision Baseline

**Goal:** 把剩下的 family-level `promote / hold / future-trigger` 决策冻结成单页基线，避免后续每次都从 `family matrix` 重新口头讨论。

**Architecture:** 这不是新 wave，也不是新的迁移图。它只负责收口已经存在的 family 分类，把当前默认判断写死，让 `family matrix` 继续只做排队和指路。

**Scope:** `SSE3`、`SSE4.1`、`SSE4.2`、`AVX-512`、`NEON`、`RISCVV`、`AES`、`SHA`、`AVX`、`FMA3`、`SVE`、`SVE2`、`LASX`。

---

## 为什么需要这页

`family matrix` 已经能告诉后续会话：

- 当前 family 的 stable truth source 是谁
- raw leaf 当前在哪里
- 当前走哪条 verification lane
- 当前属于哪一波

但它还会反复留下三类判断空位：

1. 这条 family 现在到底是继续 qualification，还是应该 promote
2. 这条 family 是 hold，还是应该进入默认 stable 路径
3. 哪些 family 只需要 future-trigger baseline，不需要临场争论

这页就是把这三类空位一次性冻结掉。

## 决策基线

### x86 qualification group

Families:

- `SSE3`
- `SSE4.1`
- `SSE4.2`
- `AVX-512`

Current decision:

- 继续停留在 qualification / hold green
- 继续以 shared raw parity baseline 作为约束
- 不把 representative parity 直接等同于 promote trigger
- 不在没有 fresh red 的情况下重新打开 promote / split 争论

What changes this:

- 真实的 fresh red
- 明确的 contract gap
- 需要 family-specific raw qualification 的新事实

What does not change this:

- smoke 先绿
- 文档看起来更整齐
- 想减少 family 数量

### non-x86 qualification group

Families:

- `NEON`
- `RISCVV`

Current decision:

- 继续保持 qualification / opt-in
- 保持 stable adapter truth source 不变
- 保持 backend ownership、helper semantics、register truthfulness 和 opcode/ABI lane 的分层判断
- 不因为 fallback wrapper 变薄，就把 raw leaf 误判成默认 stable

What changes this:

- adapter truth、helper semantics、register truthfulness、opcode/ABI lane 同时过线
- family-specific evidence 明确满足 promote 前提

What does not change this:

- 只删了重复 wrapper
- smoke 绿了
- wrapper 更短了

### experimental hold group

Families:

- `AES`
- `SHA`
- `AVX`
- `FMA3`
- `SVE`
- `SVE2`
- `LASX`

Current decision:

- 继续保持 `experimental isolated` / hold
- 不进入 stable default path
- 不因为实现看起来相似，就默认拉进主线

Reopen only when all of these exist:

1. 明确的 stable adapter use case
2. family-specific raw leaf 或 representative parity lane
3. 能把 adapter / leaf / gate 写成单一真相源

What does not change this:

- smoke green
- 文件数变少
- 某条实验路径看起来“差不多能用”

## 这页的作用边界

- `family matrix` 继续负责排队和指路
- `execution index` 继续负责告诉新会话先看哪一页
- 这页负责把剩余的政策判断冻住
- 以后如果某个 family 真正变了状态，先改这页，再改对应 family plan

## 当前结论

- `SSE2` 仍然只走自己的 retire target baseline
- `SSSE3` 继续保持 adapter-only，不进入 raw-leaf promote 讨论
- `SSE3 / SSE4.1 / SSE4.2 / AVX-512` 继续 qualification，不默认 promote
- `NEON / RISCVV` 继续 qualification / opt-in，不默认 stable
- `AES / SHA / AVX / FMA3 / SVE / SVE2 / LASX` 继续 hold，不默认 reopen

## Completion criteria

这页算收口完成时，应该满足：

1. 后续会话不再需要重新猜这些 family 的默认决策
2. `family matrix` 可以只保留当前状态和下一动作，不再重复 policy judgment
3. 任何 family 真要变更，都能先落到这页，再落到对应 family plan
