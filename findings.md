# Findings & Decisions: Layer0+Layer1 梳理 + SIMD 整理

## Requirements
- 目标：把 Layer0/Layer1 的“发现问题 → 处理问题”过程结构化（可复现、可追溯、可持续维护）。
- 重点：SIMD 模块完成度未知且结构较乱，需要先建立地图与完成定义，再做收敛式修复。
- 约束：避免未经讨论的大重构；优先用最小改动解决高风险问题，并用测试回归兜底。

## Observations
- Linux 主线 gate 与 freeze 基线稳定，Windows 实机 evidence 是跨平台 freeze 的唯一真实 blocker。
- GitHub Windows runner 初始被 billing、Windows checkout 非法路径、Lazarus/FPC PATH、batch 自调用、CRLF verifier 兼容性等问题阻塞。
- 这些 blocker 清掉后，Windows runner 已能生成真实 `windows_b07_gate.log`，且包含真实 Windows 字段与非模拟内容。

## Decisions
| Decision | Rationale | Evidence |
|----------|-----------|----------|
| 用 Linux staging artifact + Windows download 替代 Windows checkout | 绕开仓库中的 Windows 非法路径 | `.github/workflows/simd-windows-b07-evidence.yml` |
| 保持 verifier 严格，只修正 CRLF 兼容 | 不放松验收标准，只让 Windows 行尾可正确校验 | `tests/fafafa.core.simd/verify_windows_b07_evidence.sh` |
| 将 Windows evidence collector 改为显式 3 步 closeout gate | 避免 Windows `gate` 主入口的历史批处理兼容问题，同时保留真实实机执行 | `tests/fafafa.core.simd/collect_windows_b07_evidence.bat` |
| 以 batch id `SIMD-20260310-152` 完成 closeout apply | 与 real summary / docs 回填保持一致 | `tests/fafafa.core.simd/logs/windows_b07_closeout_summary.md` |

## Risks / Open Questions
- Windows evidence workflow 目前采用 closeout-specific collector，而不是直接复用完整 `gate` 主入口；后续如需统一，可再做单独收敛。

## Resources (paths / links)
- `docs/fafafa.core.simd.handoff.md`
- `docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md`
- `docs/plans/2026-03-09-simd-full-platform-completeness.md`
- `tests/fafafa.core.simd/logs/windows_b07_gate.log`
- `tests/fafafa.core.simd/logs/windows_b07_closeout_summary.md`
- `tests/fafafa.core.simd/logs/freeze_status.json`

## SIMD Full-Platform Expansion Notes (2026-03-09)

- `evaluate_simd_freeze_status.py` 当前 required 项只包含 Linux gate + Windows evidence / closeout，QEMU / RISCVV 不在 required 集合内。
- `src/fafafa.core.simd.STABLE` 与 `docs/fafafa.core.simd.closeout.md` 仍明确把 `sbRISCVV` 定义为 experimental / limited-maturity backend。
- `tests/fafafa.core.simd/docker/run_multiarch_qemu.sh` 已支持 `nonx86-evidence` / `arch-matrix-evidence` / `nonx86-experimental-asm` / `cpuinfo-*` alias，但默认 gate 不把这些设成 required。
- `tests/fafafa.core.simd/docs/simd_completeness_matrix.md` 仍有 `QEMU CPUInfo opt-in 证据链已对齐` 未完成项。
- Windows closeout is no longer the blocker; cross-platform freeze is already `ready=True`.
- Next scope is stronger than current freeze: QEMU / non-x86 evidence and RISCVV maturity.
- Current docs still state `sbRISCVV` is explicit opt-in experimental and not part of stable/platform-complete support.
- Current QEMU actions exist, but are not required by the cross-platform freeze gate.
- 本机环境具备 `docker` 与 `qemu-riscv64/qemu-aarch64/qemu-x86_64`，可直接重跑 QEMU / non-x86 evidence。
- 当前 `qemu_experimental_report` 报的是“missing experimental summary directory”，说明不是环境缺失，而是尚无最新 `nonx86-experimental-asm` 汇总产物。
- 因此下一步应直接跑 QEMU scenario，先得到真实 non-x86 / RISCVV 证据，再决定是补脚本还是补实现。
- QEMU / non-x86 的真实缺口不只是“还没纳入 gate”，还包括 raw evidence retention、CPUInfo alias 只是折叠到 `nonx86-evidence`、以及 docs/checklist/matrix 未拆成可验收条目。
- `freeze-status` 当前完全不看 QEMU/non-x86 产物，因此现有 `ready=True` 不能代表“全平台完整实现”。
- 现成最小收敛路径应至少覆盖：`qemu-arch-matrix-evidence`、`qemu-nonx86-evidence`、`qemu-nonx86-experimental-asm` / baseline，以及对应文档/状态机接线。
- `src/fafafa.core.simd.riscvv.pas` 是一个非常大的已注册 backend，但它仍然走老的 `TSimdDispatchTable` 路线，且大量 façade 能力只是 scalar delegation。
- `cpuinfo.riscv` 当前 `HasV` 判定过于宽松（`Pos('v', isa) > 0`），会误导 dispatch 把 `sbRISCVV` 当成可用 backend。
- `riscv32` 当前会注册 `sbRISCVV`，但 asm 只在 `CPURISCV64 + SIMD_BACKEND_RISCVV` 下启用，因此形成“注册了 RISCVV、实际却是 scalar fallback”的假象。
- 真正的 RVV 运行覆盖不足：现在主要是 demo / wrapper 级验证，缺少正式 backend smoke / activation / CI lane。
- 源码 opt-in 宏 `SIMD_EXPERIMENTAL_RISCVV` 与 docker/QEMU lane 使用的 `FAFAFA_SIMD_*` 宏目前不一致，脚本和源码口径分裂。
- 最新 `qemu-arch-matrix-evidence` 已通过：`386/amd64/arm-v7/arm64/riscv64` 均 PASS，原始 summary 在 `tests/fafafa.core.simd/logs/qemu-multiarch-20260309-074728-2498066/summary.md`。
- `riscvv-opcode-lane` 当前状态是 compile-only PASS、suite FAIL；失败根因不是编译器炸裂，而是脚本还在调用不存在的 `TTestCase_NonX86IEEE754`。
- `qemu-cpuinfo-nonx86-full-evidence` 当前真实 blocker 已收窄成两组：ARM helper/behavior 缺口（`MergeARMFeaturesFromLinuxHWCAP`、`ParseARMProcessorInfoFromCpuInfo`、crypto/vendor/cache 语义），以及 RISCV helper/API 缺口（`ExtractBestRISCVISAFromCpuInfo`、`MergeRISCVFeaturesFromLinuxHWCAP`、`ParseRISCVVendorModelFromCpuInfo`、`LinuxHWCAP/LinuxHWCAP2` 字段）。

- 2026-03-09 最新收敛结果：`qemu-cpuinfo-nonx86-full-evidence` 已 PASS，fresh summary 在 `tests/fafafa.core.simd/logs/qemu-multiarch-20260309-085950-2782967/summary.md`。
- 2026-03-09 最新收敛结果：fresh `qemu-arch-matrix-evidence` 已再次 PASS，summary 在 `tests/fafafa.core.simd/logs/qemu-multiarch-20260309-092825-2802652/summary.md`。
- 2026-03-09 最新收敛结果：`riscvv-opcode-lane` 已从“假 compile-only PASS + 缺失 suite”收敛为“真实 compile-only PASS + stable smoke PASS + bench 默认 SKIP”，summary 在 `tests/fafafa.core.simd/logs/rvv-opcode-lane-20260309-091241/summary.md`。
- `tests/fafafa.core.simd.cpuinfo/fafafa.core.simd.cpuinfo.test.lpr` 在 RISC-V 上增加了 `Halt(ExitCode)` 早退，规避了 FPCUnit runner cleanup 在 riscv64 QEMU 下的退出期 `EAccessViolation`，但不放松任何测试断言。
- `tests/fafafa.core.simd/docker/run_multiarch_qemu.sh` 的 `nonx86-experimental-asm` 现在更明确地把 probe failure fallback 到 `SIMD_VECTOR_ASM_DISABLED`；RISC-V 真正的 experimental evidence 由专门的 `riscvv-opcode-lane` 承担。
- `src/fafafa.core.simd.riscvv.pas` 已收敛掉 `vsetivli` 符号参数、`fa0/ft0/ft1` 别名、`seq/snez` 伪指令，以及一批 dispatch 签名不匹配问题；当前 dedicated lane 已能完成真实编译与 stable smoke。

- Windows artifact was re-downloaded from GitHub run `22867922511` after local `clean` removed `logs/`; local `freeze-status` is back to `ready=True`.

- 长期路线图：`docs/plans/2026-03-09-simd-long-range-roadmap.md`
- Phase 1 full-platform freeze evaluator 已落地：`freeze-status` 保留 cross-platform，新增 `freeze-status-full-platform` 评估 fresh QEMU arch matrix / CPUInfo full / RVV lane。
- Phase 2 arm64 audit 已确认当前失败可分为 4 类：AArch64 asm arrangement/syntax（如 `.d`）、不被当前 FPC/GAS 接受的 opcode（如 `faddp`）、缺失 `NEONMask*`/宽向量 helper、以及 experimental probe/fallback 语义未在 summary 中显式化。
- `src/fafafa.core.simd.neon.pas` 当前 stable/public surface 的关键不变量仍是：在 `SIMD_VECTOR_ASM_DISABLED` 下，stable arch-matrix 能通过；experimental lane 的编译失败不应再污染 stable/public surface 结论。
- `tests/fafafa.core.simd/docker/run_multiarch_qemu.sh` 已开始支持在 `nonx86-experimental-asm` summary 中写出 `probe-pass` / `fallback-pass` / `fallback-fail`。
- fresh `qemu-nonx86-experimental-asm` 已验证新的 lane 口径：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-104815-3158486/summary.md` 现在显式记录 `linux/arm64:fallback-pass` 与 `linux/riscv64:fallback-pass`。
- arm64 dedicated experimental lane 已落地：`bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arm64-experimental-asm` 会把 `SIMD_QEMU_PLATFORMS=linux/arm64` 与 `SIMD_QEMU_ENABLE_BACKEND_ASM=1` 固化下来。
- 最新 arm64 dedicated experimental lane 结果为 `probe-pass`：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-113613-3507394/summary.md`。
- 在隔离 experimental 产物目录后，arm64 dedicated lane 已稳定收敛为 `probe-pass`，而且本次日志中不再出现首轮 `DEBUGSTART_$FAFAFA.CORE.SIMD` 链接抖动。
- 当前 Phase 2 的最小安全策略是：先用 dedicated lane 证明 arm64 probe 可过，再逐步从 `neon.pas` 中移除对 FPC/GAS 不友好的 experimental asm 块；stable/full-platform 声明保持不变。
- Phase 2 tooling 已扩展到 arm64 dedicated lane：`qemu-arm64-experimental-report` / `qemu-arm64-experimental-baseline-check` 现在可以直接读取 `arm64-experimental-asm` 场景。
- Experimental report/baseline 工具现在按场景输出独立产物；arm64 dedicated lane 不再覆盖 generic `nonx86-experimental-asm` 的 latest 报告。
- 2026-03-09 latest dedicated arm64 lane 继续保持 `probe-pass`：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-124915-3897918/summary.md`。
- `RegisterNEONBackend` 当前可以安全分成两层理解：`table.AddF32x4..Mask16*` 属于 stable/core registration；从 `Auto-generated Registration for 100% Coverage` 开始的大块宽向量/宽掩码覆盖属于 experimental-wide registration。
- `RegisterNEONBackend` 当前已用注释和 guard 明确成两层：`Stable Core Registration Overrides` 与 `Experimental-Wide Registration Overrides`，但还没有正式拆成单独 helper 过程；这是下一轮 Phase 2 的主要切入点。
- latest arm64 dedicated lane 在保留上述分层边界后仍为 `probe-pass`：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-125947-3969127/summary.md`。
- 尝试一次性抽 `RegisterNEONBackend` helper 会把 `neon.pas` 结构拉坏；当前更安全的策略是先保留 register 主体内联，只通过注释与 guard 明确 stable core / experimental-wide 边界，再逐小块抽取。
- 已验证“小块 helper 化”路线可行：`Mask*` 注册已独立抽成 `ApplyNEONMaskOverrides`，arm64 dedicated lane 仍保持 `probe-pass`。
- 这说明后续可以继续按族别小步抽离 `RegisterNEONBackend`，而不必再尝试一次性大规模 helper 化。
- 第二个已验证可行的小步 helper 是 `ApplyNEONExperimentalWideF32Overrides`：只搬 `{$IFNDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 内的 `F32x8/F32x16` 注册，不改任何实现函数。
- 这类 helper 本身也必须放在同层 `{$IFNDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` guard 下；否则 arm64 dedicated probe build 会因为 `NEONAddF32x16` / `NEONCmpEqF32x8` 等仅在 non-ASM fallback 区存在的符号而触发 `Identifier not found`。
- fresh arm64 dedicated lane 在上述 guarded helper 收敛后继续保持 `probe-pass`：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-142616-39694/summary.md`。
- fresh arm64 scenario report / baseline 也已归零：`tests/fafafa.core.simd/logs/qemu_experimental_blockers.arm64-experimental-asm.latest.md` 为 `Blockers: 0`，`tests/fafafa.core.simd/logs/qemu_experimental_baseline.arm64-experimental-asm.latest.md` 为 `unexpected=0`。
- fresh stable arch-matrix 在这次 helper 抽离后再次 PASS：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-142930-53109/summary.md`；`freeze-status-full-platform` 继续 `ready=True` 且已指向该 fresh summary。
- 第三个已验证可行的小步 helper 是 `ApplyNEONExperimentalWideF64Overrides`：把 experimental-wide `F64x2/F64x4/F64x8` 注册整体外提，仍保持与 non-ASM fallback 相同的 guard 边界。
- 第四个已验证可行的小步 helper 是 `ApplyNEONExperimentalWideNarrowIntOverrides`：只搬 `I8x16/I16x8/U8x16/U16x8` 的 `Cmp*` 与 `Shift*` 注册。
- fresh arm64 dedicated lane 在 F64 + narrow-int 两轮 helper 之后继续保持 `probe-pass`：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-144733-120311/summary.md`。
- fresh stable arch-matrix 在 F64 + narrow-int 两轮 helper 之后再次 PASS：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-144945-130285/summary.md`；`freeze-status-full-platform` 仍为 `ready=True` 且已指向该 fresh summary。
- 第五个已验证可行的小步 helper 是 `ApplyNEONExperimentalWideI32U32Overrides`：承接 experimental-wide `I32x4/I32x8/I32x16/U32x4/U32x8` 注册。
- 第六个已验证可行的小步 helper 是 `ApplyNEONExperimentalWideI64U64Overrides`：承接 experimental-wide `I64x2/I64x4/I64x8/U64x4` 注册。
- 到目前为止，`RegisterNEONBackend` 的 experimental-wide 区域已全部抽成 helper；register 主体内只剩 helper 调用，stable/core 与 experimental-wide 的边界已经非常清楚。
- 一个新的流程性发现：不要并行运行两个都会构建 `aarch64-linux` 产物的 lane（如 `qemu-arm64-experimental-asm` 与 `qemu-arch-matrix-evidence`）；它们会共享 `tests/fafafa.core.simd/lib2/aarch64-linux`，从而触发对象文件损坏或链接期未定义符号。
- 在清理 `tests/fafafa.core.simd/lib2/aarch64-linux` 后串行重跑，latest arm64 dedicated lane 恢复为 `probe-pass`：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-152018-311706/summary.md`。
- latest stable arch-matrix 也已在串行模式下再次 PASS：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-152247-329057/summary.md`；`freeze-status-full-platform` 继续 `ready=True` 并指向该 fresh summary。
- 实现层第一批 hardening 已完成：`NEONDotF32x8`、`NEONDotF64x2`、`NEONDotF64x4` 的 asm-enabled 路径不再直接掉 `ScalarDot*`，而是组合已稳定的窄 NEON `Dot/Mul/ReduceAdd`。
- `NEONReduceAddF32x8_ASM` / `NEONReduceAddF32x16_ASM` 现在改为组合 `NEONDotF32x4` 与分层 reduce，不再直接掉 `ScalarReduceAdd*`。
- `NEONSplatF64x4_ASM` / `NEONSplatF64x8_ASM` 现在改为组合 `NEONSplatF64x2` / `NEONSplatF64x4`，不再直接掉 `ScalarSplatF64*`。
- 实现层第二批 hardening 已完成：wide float `Add/Sub/Mul/Div`（`F32x8/F32x16/F64x4/F64x8`）的 asm-enabled 路径改为 `lo/hi` 组合窄 NEON，而不是直接掉 `Scalar*`。
- latest dedicated arm64 lane 在上述实现层 hardening 后继续 `probe-pass`：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-154903-483461/summary.md`。
- latest stable arch-matrix 在上述实现层 hardening 后继续 PASS：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-155202-503518/summary.md`；`freeze-status-full-platform` 仍为 `ready=True`。
- wide-float math hardening 已继续推进：`Abs/Min/Max/Sqrt/Floor/Ceil/Round/Trunc/Fma/Clamp` 的 `F32x8/F32x16/F64x4/F64x8` 路径已改为 `lo/hi` 组合窄 NEON，不再直接掉 `Scalar*`。
- wide-float comparison hardening 也已推进：`CmpEq/CmpGe/CmpGt/CmpLe/CmpLt/CmpNe` 的 `F32x8/F32x16/F64x4/F64x8` 路径已改为组合窄 NEON compare，再合并 bitmask。
- 在 Pascal 实现区，`F32x16` 先于 `F32x8` compare/math wrappers 定义，因此需要对被前向调用的 `F32x8` wrapper 增加 `forward` 声明；这属于实现层顺序约束，不是算法问题。
- latest dedicated arm64 lane 在 wide-float math/comparison hardening 后继续 `probe-pass`：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-204347-665815/summary.md`。
- latest stable arch-matrix 在 wide-float math/comparison hardening 后继续 PASS：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-204526-670171/summary.md`；`freeze-status-full-platform` 仍然 `ready=True`。
- wide-float `Select + Load/Extract/Insert` hardening 也已完成：`F32x8/F32x16/F64x4/F64x8` 的这些 façade 现在优先走 `lo/hi` 组合窄 NEON，不再直接掉 `Scalar*`。
- 对 `F32x16` 来说，`Load/Extract/Insert/Select` 在 Pascal 实现区会先调用 `F32x8` 同名 wrapper，因此需要补 `forward` 声明；这是第二个被确认的实现顺序约束。
- latest dedicated arm64 lane 在 wide-float select/load/extract/insert hardening 后继续 `probe-pass`：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-210439-771359/summary.md`。
- latest stable arch-matrix 在上述 hardening 后继续 PASS：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-210621-775332/summary.md`；`freeze-status-full-platform` 仍然 `ready=True`。
- wide integer bitwise hardening 已继续推进：`I32/I64/U32` 的 wide `And/AndNot/Or/Xor/Not` 路径已改为 `lo/hi` 组合窄 NEON；`U32x4` 的窄位操作则改成显式逐 lane 实现。
- `I64x4` 的 `AndNot` 不能调用不存在的 `NEONAndNotI64x2`；正确的等价组合是 `NEONAndI64x2(a, NEONNotI64x2(b))`。
- latest dedicated arm64 lane 在 wide-integer bitwise hardening 后继续 `probe-pass`：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-212410-857149/summary.md`。
- latest stable arch-matrix 在上述 hardening 后继续 PASS：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-212603-865400/summary.md`；`freeze-status-full-platform` 仍然 `ready=True`。
- wide integer arithmetic/minmax hardening 已继续推进：有现成窄 helper 的 `Add/Sub/Mul/Min/Max`（主要是 `I32/I64/U32` 的 wide 路径）已改为 `lo/hi` 组合窄 NEON。
- 这一轮刻意没有碰缺少窄 helper 的 `U64x4 Add/Sub/Min/Max`，避免在未明确环绕/比较语义的情况下引入手写逐 lane 实现。
- latest dedicated arm64 lane 在 wide-integer arithmetic/minmax hardening 后继续 `probe-pass`：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-213748-906016/summary.md`。
- latest stable arch-matrix 在上述 hardening 后继续 PASS：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-213927-909069/summary.md`；`freeze-status-full-platform` 仍然 `ready=True`。
- wide integer `extract/insert/load/select` hardening 也已推进：`I32/I64` 的访问 façade 现在优先走 `lo/hi` 组合或显式逐 lane，而不是直接掉 `Scalar*`。
- 这一轮确认了两个额外的实现约束：`CmpNeU32x4` 需要在 NEON fallback 中显式补齐；`I64x4` 左/右移没有可复用的 `I64x2` helper，必须直接按逐 lane 语义实现。
- latest dedicated arm64 lane 在 wide-integer access/selection hardening 后继续 `probe-pass`：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-222416-1142098/summary.md`。
- latest stable arch-matrix 在上述 hardening 后继续 PASS：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-225005-1278406/summary.md`；`freeze-status-full-platform` 仍然 `ready=True`。
- wide integer compare/shift hardening 已继续推进：有现成窄 helper 的 `I32/I64/U32` wide compare/shift 已大面积改为 `lo/hi` 组合窄 NEON。
- `I64x4` 左/右移再次确认只能按逐 lane 实现；`U64x4` compare/shift 仍保留为下一轮孤点处理。
- latest dedicated arm64 lane 在 wide-integer compare/shift hardening 后继续 `probe-pass`：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-222912-1173344/summary.md`。
- latest stable arch-matrix 在上述 hardening 后继续 PASS：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-223050-1177262/summary.md`；`freeze-status-full-platform` 仍然 `ready=True`。
- `U64x4` 孤点已继续收敛：当前 `bitwise + compare + shift` 已全部改为本地逐 lane 实现，不再直接掉 `Scalar*`。
- latest dedicated arm64 lane 在 `U64x4` 孤点 hardening 后继续 `probe-pass`：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-232853-1440501/summary.md`。
- latest stable arch-matrix 在上述 hardening 后继续 PASS：`tests/fafafa.core.simd/logs/qemu-multiarch-20260309-234221-1513375/summary.md`；`freeze-status-full-platform` 仍然 `ready=True`。

- 窄 `I32x4/U32x4` 基础 fallback 也已继续本地化：`compare/minmax/shift` 等不再直接掉 `Scalar*`。
- latest dedicated arm64 lane 在 narrow-int tail cleanup 后继续 `probe-pass`：`tests/fafafa.core.simd/logs/qemu-multiarch-20260310-002806-1725327/summary.md`。
- latest stable arch-matrix 在 narrow-int tail cleanup 后继续 PASS：`tests/fafafa.core.simd/logs/qemu-multiarch-20260310-003117-1738835/summary.md`；`freeze-status-full-platform` 仍然 `ready=True`。

- 目标区（约 `6200-9300`）里的整数 `Scalar*` wrapper 已基本清空；剩余显眼 `Scalar*` 主要转向 `reduce/zero/splat/rcp` 与少量非整数 façade。
- latest dedicated arm64 lane 在整数 `Scalar*` cleanup 后继续 `probe-pass`：`tests/fafafa.core.simd/logs/qemu-multiarch-20260310-005735-1893012/summary.md`。
- latest stable arch-matrix 在整数 `Scalar*` cleanup 后继续 PASS：`tests/fafafa.core.simd/logs/qemu-multiarch-20260310-010522-1949191/summary.md`；`freeze-status-full-platform` 仍然 `ready=True`。
