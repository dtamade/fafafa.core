# SIMD Experimental Hold Future Trigger Plan

**Goal:** 冻结当前 `experimental isolated` / hold 家族的重新开线条件，避免后续因为“看起来能做”就把它们误拉进 stable default 路径。

**Scope:** `AES`、`SHA`、`AVX`、`FMA3`、`SVE`、`SVE2`、`LASX`。

**Architecture:** 这不是迁移计划，也不是要把这些 family 立刻接进默认 façade。它只回答一件事：什么条件下，某个当前 hold 的 experimental family 才值得重新进入单独计划或 promote 讨论。

---

## 当前基线

- `AES`、`SHA`、`AVX`、`SVE`、`SVE2`、`LASX` 继续保持 `experimental isolated`
- `FMA3` 保留自己的 smoke lane，但仍不进入 stable default 路径
- 当前没有任何一个 family 进入新的 default stable adapter 依赖

## 重新开线的触发条件

只有同时满足下面三条，才算值得重开一个 family 的实施计划：

1. 出现明确的 stable adapter use case，不再只是“顺手可以接”
2. 有 family-specific raw leaf 或 representative parity lane
3. 能把 `adapter / leaf / gate` 三层职责写成单一真相源，不引入第二套控制面

## 不算触发条件的事

- 代码看起来和现有 active leaf 很像
- 某个 experimental smoke 先绿了
- 想减少文件数
- 想把 hold family 直接塞进默认 stable adapter

## 当前 verification lane

```bash
python3 tests/fafafa.core.simd/check_intrinsics_experimental_status.py --summary-line
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

如果某个 family 将来真的被提起，再补它自己的 smoke / parity lane；在那之前不要提前把它们写成 active queue。

## Completion criteria

这份文档完成时，应该满足：

1. 当前 hold family 的默认状态写死为 `experimental isolated` 或 equivalent hold judgment
2. 未来触发条件写成统一口径，不再靠聊天上下文临场判断
3. `docs/plans/2026-05-09-simd-family-matrix.md` 能直接引用这份 baseline，而不是自己再发明一套 trigger 规则
