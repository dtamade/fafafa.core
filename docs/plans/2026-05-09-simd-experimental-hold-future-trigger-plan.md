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

## Family-specific trigger table

| Family | Current state | Reopen only when | Required lane before reopen | Not a trigger |
| ------ | ------------- | ---------------- | --------------------------- | ------------- |
| `AES` | `experimental isolated` | `simd` 主线里出现必须由 stable adapter 暴露的 AES block/round/helper use-case，而不是继续放在独立 crypto 路径 | `experimental-intrinsics` isolation + family-specific backend smoke + representative parity/reference-vector lane | 只是在源码里看起来能复用 AES 指令，或只是想减少文件数 |
| `SHA` | `experimental isolated` | `simd` 主线里出现必须由 stable adapter 暴露的 SHA round/hash helper use-case，而不是继续停在实验 leaf | `experimental-intrinsics` isolation + family-specific backend smoke + representative parity/reference-vector lane | smoke 先绿，或只是觉得 SHA 和 AES 规则应该一起放开 |
| `AVX` | `experimental isolated` | 出现一个不能继续落在 `AVX2`/现有 x86 adapter 上的稳定 `AVX-only` adapter target | `experimental-intrinsics` isolation + `check_avx_backend_smoke` 类 lane + representative parity lane | 仅因为 `AVX` 和 `AVX2` 很接近，或希望把文件名统一 |
| `FMA3` | `experimental isolated` | stable adapter 需要显式承诺 fused-multiply-add 语义，且不能继续由 `AVX2` adapter/internal helper 吸收 | 现有 `check_fma3_backend_smoke` + representative parity lane + single-source adapter/leaf mapping | 只因为已有 smoke，或某几个 helper 看起来可以直接接线 |
| `SVE` | `experimental isolated` | 出现 distinct-from-NEON 的稳定 ARM scalable-vector use-case，并且需要 `simd` 主线默认维护 | `experimental-intrinsics` isolation + opt-in smoke + representative parity lane + evidence path | 仅因为目标机器支持 SVE，或想提前为未来平台铺文件 |
| `SVE2` | `experimental isolated` | 出现 distinct-from-SVE/NEON 的稳定 byte/permute/widen use-case，需要单独 default adapter 讨论 | `experimental-intrinsics` isolation + opt-in smoke + representative parity lane + evidence path | 仅因为 `SVE2` 更强，或想顺手和 `SVE` 一起解锁 |
| `LASX` | `experimental isolated` | 仓库决定接纳 LoongArch stable adapter 目标，并能给出持续的 smoke/evidence lane | `experimental-intrinsics` isolation + family-specific smoke/parity lane + host/CI evidence path | 只是 leaf 看起来完整，或只想让 matrix 更对称 |

这张表是当前 hold family 的唯一 reopen 细化基线。以后如果某个 family 真要变成 active queue，先改这张表，再改 `family matrix` 和对应 family plan。

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

如果某个 family 将来真的被提起，再把上表里的 required lane 落成正式入口；在那之前不要提前把它们写成 active queue。

## Completion criteria

这份文档完成时，应该满足：

1. 当前 hold family 的默认状态写死为 `experimental isolated` 或 equivalent hold judgment
2. 未来触发条件写成 family-specific 口径，不再靠聊天上下文临场判断
3. `docs/plans/2026-05-09-simd-family-matrix.md` 能直接引用这份 baseline，而不是自己再发明一套 trigger 规则
