# SIMD Intrinsics Disposition

这份表只回答一件事：每个 `intrinsics.*` 单元现在是什么状态，能不能被当成当前主线真相源。

状态只允许四种：

- `active leaf`
- `experimental isolated`
- `transitional`
- `retire target`

## 当前 disposition

| Unit | Status | Role | Notes |
| --- | --- | --- | --- |
| `fafafa.core.simd.intrinsics` | `transitional` | 历史 low-level convenience umbrella | 不属于 `fafafa.core.simd` 的主 façade；不负责 backend selection / dispatch registration |
| `fafafa.core.simd.intrinsics.base` | `active leaf` | 低层寄存器与基础类型定义 | `TM128/TM256/TM512` foundation |
| `fafafa.core.simd.intrinsics.mmx` | `active leaf` | 低层 MMX leaf | 有独立测试 lane |
| `fafafa.core.simd.intrinsics.sse` | `active leaf` | 低层 SSE leaf | 有独立测试 lane |
| `fafafa.core.simd.intrinsics.avx2` | `active leaf` | 低层 AVX2 leaf | 当前保留的 active exception；有专门 coverage/test lane |
| `fafafa.core.simd.intrinsics.aes` | `experimental isolated` | x86 AES leaf | 默认入口隔离，仍需 opt-in；当前 experimental tests 锁住 default-reject + placeholder semantics |
| `fafafa.core.simd.intrinsics.sha` | `experimental isolated` | x86 SHA leaf | 默认入口隔离，仍需 opt-in；当前 experimental tests 锁住 default-reject + placeholder semantics |
| `fafafa.core.simd.intrinsics.avx` | `experimental isolated` | x86 AVX leaf | 默认入口隔离，仍需 opt-in；无当前 in-repo bridge consumer；non-x86 分支只保留 compile scaffolding，runtime fail-close |
| `fafafa.core.simd.intrinsics.sse2` | `transitional` | SSE2 compatibility / wrapper layer | experimental opt-in only；non-x86 分支只保留 compile scaffolding，runtime fail-close；迁移完成后进入 retire path |
| `fafafa.core.simd.intrinsics.x86.sse2` | `experimental isolated` | SSE2 raw x86 leaf target | 未来只接收纯 `TM128` raw primitive；当前仍受 experimental guard 保护 |
| `fafafa.core.simd.intrinsics.sse3` | `experimental isolated` | x86 SSE3 leaf | 默认入口隔离，仍需 opt-in；non-x86 分支只保留 compile scaffolding，runtime fail-close |
| `fafafa.core.simd.intrinsics.sse41` | `experimental isolated` | x86 SSE4.1 leaf | 默认入口隔离，仍需 opt-in；non-x86 分支只保留 compile scaffolding，runtime fail-close |
| `fafafa.core.simd.intrinsics.sse42` | `experimental isolated` | x86 SSE4.2 leaf | 默认入口隔离，仍需 opt-in；non-x86 分支只保留 compile scaffolding，runtime fail-close |
| `fafafa.core.simd.intrinsics.avx512` | `experimental isolated` | x86 AVX-512 leaf | 默认入口隔离，仍需 opt-in；non-x86 分支只保留 compile scaffolding，runtime fail-close |
| `fafafa.core.simd.intrinsics.fma3` | `experimental isolated` | x86 FMA3 leaf | 默认入口隔离，仍需 opt-in；non-x86 分支只保留 compile scaffolding，runtime fail-close |
| `fafafa.core.simd.intrinsics.neon` | `experimental isolated` | ARM NEON leaf | 默认入口隔离，仍需 opt-in；只有 `cpuinfo` 报告 `NEON` 的 ARM-class 目标才允许运行 placeholder semantics，其余主机 runtime fail-close |
| `fafafa.core.simd.intrinsics.rvv` | `experimental isolated` | RISC-V V leaf | 默认入口隔离，仍需 opt-in；只有 `cpuinfo` 报告 `RVV` 的 RISC-V 目标才允许运行 placeholder semantics，其余主机 runtime fail-close |
| `fafafa.core.simd.intrinsics.sve` | `experimental isolated` | ARM SVE leaf | 默认入口隔离，仍需 opt-in；只有 `cpuinfo` 报告 `SVE` 的 `AArch64` 目标才允许运行 placeholder semantics，其余主机 runtime fail-close |
| `fafafa.core.simd.intrinsics.sve2` | `experimental isolated` | ARM SVE2 leaf | 默认入口隔离，仍需 opt-in；当前已按 `cpuinfo` 的 `SVE2` 资格收紧 runtime，其余主机 fail-close；这还不是 stable `SVE2` qualification contract |
| `fafafa.core.simd.intrinsics.lasx` | `experimental isolated` | LoongArch LASX leaf | 默认入口隔离，仍需 opt-in；只有 `cpuinfo` 报告 `LASX` 的 `LoongArch64` 目标才允许运行 placeholder semantics，其余主机 runtime fail-close |

## 解释规则

- `active leaf` 不等于“默认 backend adapter”；它只说明该单元作为低层 leaf 仍在活跃维护并有对应测试/检查 lane。
- `experimental isolated` 说明该单元默认不进入 stable façade/gate 主链路。
- `transitional` 说明该单元还在承接历史兼容或迁移包袱，不能把它误读成最终落点。
- `retire target` 只有在迁移证据和 parity 证据齐全时才会使用；当前这批没有预先标死的删除对象。

## adapter 依赖准入规则

这里再补一条实施纪律，避免后续把状态表只当注释看：

- default stable backend adapter 只允许新增依赖 `active leaf`
- `experimental isolated` 不能作为 default stable adapter 的新增实现依赖
- `transitional` 不能作为新的长期落点；它只承接兼容和迁移包袱
- 如果某个实验单元想被 stable adapter 使用，先 promote 成 `active leaf`，或者先拆出新的 `active leaf` 子集

## 当前最容易误判的点

- `fafafa.core.simd.intrinsics.sse2` 不是当前 SSE2 发布真相源。
- `fafafa.core.simd.intrinsics.sse2` 的 non-x86 分支也不是 experimental runtime 合同；它只保留编译脚手架。
- `fafafa.core.simd.intrinsics.avx` 继续是 hold family；当前也没有任何仓库内 bridge consumer 可以把它误当成活跃依赖。
- `fafafa.core.simd.intrinsics.sse3/sse41/sse42/avx512/fma3` 也都是 x86-only experimental lane；non-x86 运行期同样不是 contract。
- `fafafa.core.simd.intrinsics.aes/sha` 和上面这批不同：当前有实验测试明确锁住 default-reject + placeholder semantics，但这仍然不是 stable leaf contract。
- `fafafa.core.simd.intrinsics.neon/rvv` 也不是“任何主机开了 experimental 宏都能跑”的 contract；当前只允许 `cpuinfo` 已确认对应 ISA 的目标主机进入 runtime placeholder semantics。
- `fafafa.core.simd.intrinsics.sve/sve2` 当前也不是“任何 `AArch64` experimental host 都能跑”的 contract；`sve` 只在 `cpuinfo` 报告 `SVE` 时放行，`sve2` 只在 `cpuinfo` 报告 `SVE2` 时放行。
- `fafafa.core.simd.intrinsics.lasx` 现在也不是“任何 `LoongArch64` experimental host 都能跑”的 contract；只有 `cpuinfo` 报告 `LASX` 时才放行。
- `fafafa.core.simd.intrinsics.x86.sse2` 也不是当前 SSE2 发布真相源。
- 当前 SSE2 发布真相源仍然是 `src/fafafa.core.simd.sse2.pas`。
- 只要 `fafafa.core.simd.intrinsics.x86.sse2` 仍是 `experimental isolated`，default stable `simd.sse2` 就不应新增对它的默认依赖。

如果要继续推进 SSE2 分账，请下一步直接看 `docs/SIMD_SSE2_MIGRATION_MAP.md`。
