# SIMD Backend Truth

这份表只回答一件事：当前默认主线 backend 到底是谁、真相源在哪、它是否接入默认 façade。

先锁死口径：

- `fafafa.core.simd*` 是 backend adapter / backend assembly layer
- backend adapter 负责 `TVec*` / `TMask*` façade 语义、dispatch 注册、backend 能力接线、必要的多寄存器拼装与 façade helper
- `fafafa.core.simd.intrinsics*` 不是默认主线 backend truth source；它们属于低层 raw ISA leaf / experimental boundary，具体归属看 `docs/SIMD_INTRINSICS_DISPOSITION.md`

## 默认主线 backend

| Backend | Class | Truth Source | Default façade | Notes |
| --- | --- | --- | --- | --- |
| `Scalar` | `backend adapter` | `src/fafafa.core.simd.scalar.pas` | `yes` | 标量回退基线 |
| `SSE2` | `backend adapter` | `src/fafafa.core.simd.sse2.pas` | `yes` | 当前 SSE2 真相源；`wide_emulation`、mask 翻译、注册接线仍留在这里 |
| `SSE3` | `backend adapter` | `src/fafafa.core.simd.sse3.pas` | `yes` | 增量 x86 backend adapter |
| `SSSE3` | `backend adapter` | `src/fafafa.core.simd.ssse3.pas` | `yes` | 增量 x86 backend adapter |
| `SSE4.1` | `backend adapter` | `src/fafafa.core.simd.sse41.pas` | `yes` | 增量 x86 backend adapter |
| `SSE4.2` | `backend adapter` | `src/fafafa.core.simd.sse42.pas` | `yes` | 增量 x86 backend adapter |
| `AVX2` | `backend adapter` | `src/fafafa.core.simd.avx2.pas` | `yes` | 默认主线 backend；`intrinsics.avx2` 是保留中的 active leaf exception |
| `AVX-512` | `backend adapter` | `src/fafafa.core.simd.avx512.pas` | `yes` | 默认主线 backend，但成熟度仍受构建配置与验证范围影响 |
| `NEON` | `backend adapter` | `src/fafafa.core.simd.neon.pas` | `yes` | 默认主线 backend |
| `RISCVV` | `backend adapter` | `src/fafafa.core.simd.riscvv.pas` | `opt-in only` | 只有定义 `SIMD_EXPERIMENTAL_RISCVV` 时才接入 umbrella unit |

## 不在这张表里的人

- `src/fafafa.core.simd.intrinsics.sse2.pas`
- `src/fafafa.core.simd.intrinsics.x86.sse2.pas`
- 其他 `src/fafafa.core.simd.intrinsics.*.pas`

这些单元都不是“当前默认 backend truth source”。

如果你要判断 SSE2 当前发布真相源，请直接回到：

- `src/fafafa.core.simd.sse2.pas`
- `docs/SIMD_SSE2_MIGRATION_MAP.md`

## 使用规则

以后新增或迁移一个 ISA family，必须先在这里声明它属于哪一类：

- `backend adapter`
- `raw intrinsics leaf`
- `experimental placeholder`

未声明者，不进入默认主链路。
