# Findings & Decisions: Layer0+Layer1 梳理 + SIMD 整理

## Requirements
- 目标：把 Layer0/Layer1 的“发现问题 → 处理问题”过程结构化（可复现、可追溯、可持续维护）。
- 重点：SIMD 模块完成度未知且结构较乱，需要先建立地图与完成定义，再做收敛式修复。
- 约束：避免未经讨论的大重构；优先用最小改动解决高风险问题，并用测试回归兜底。

## Observations
- `src/` 下 SIMD 单元数量：59 个 `fafafa.core.simd*.pas`（其中 `cpuinfo.*` 13 个、`intrinsics.*` 19 个）。
- `src/fafafa.core.simd.STABLE` 已修复过期引用：`simd.types` → `simd.base`（类型单元已收敛到 `src/fafafa.core.simd.base.pas`）。
- `tests/fafafa.core.simd/` 体量很大（`fafafa.core.simd.testcase.pas` ~ 598KB），且目录内混有大量编译产物（`.o/.ppu`，虽已在 `.gitignore` 中忽略但会影响可读性）。
- SIMD 测试程序自带 CLI（suite/list-suites/bench/...），与其他模块常见的 `--all/--format/--progress` 不一致；需要在 Layer0/1 的“测试 runner 规范”层面收敛。

## SIMD 完成定义（DoD / Definition of Done）

### 稳定边界（对外承诺）
- 稳定入口（建议外部只依赖这些）：`fafafa.core.simd`、`fafafa.core.simd.api`、`fafafa.core.simd.cpuinfo`
- 类型与基础：`fafafa.core.simd.base`（向量/Mask/Backend 类型与常量）
- 派发：`fafafa.core.simd.dispatch`（Dispatch Table + backend 选择）
- 其它后端 / intrinsics / 平台细节：默认视为实现细节，可演进（不做强稳定承诺）

### 后端范围（最小集合）
- 必须：Scalar（全平台）、x86/x86_64 SSE2（x86 基线）
- 推荐：x86_64 AVX2（主力高性能后端）
- 可选：AVX-512（受宏/平台/编译器影响）、ARM NEON（依赖 FPC 版本与目标平台）
- 实验：RISC-V V（功能与性能以“可用优先”，逐步补齐）

### 必要验证（每次改动前/后）
- 编译卫生：`bash tests/fafafa.core.simd/BuildOrTest.sh check`（SIMD 单元 0 warnings/hints）
- 回归：`bash tests/fafafa.core.simd/BuildOrTest.sh test`（PASS + 0 leak）
- 集成（最小）：`STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.simd`

## 文档收敛范围（本轮口径）
- 对外模块文档：`docs/fafafa.core.simd*.md`（simd/api/cpuinfo/intrinsics）+ `src/fafafa.core.simd.STABLE`
- 过程性/规划性文档：`docs/SIMD_*` 仅作内部记录，允许与实现短期不一致（以免“多个真相”互相冲突）
- `src/fafafa.core.simd.next-steps.md` 标记为早期草案（历史参考），避免误导

## SIMD Unit Map（草案）

### Public / Infra（入口与基础设施）
- `src/fafafa.core.simd.pas`（主入口：re-export types + 引入各后端）
- `src/fafafa.core.simd.base.pas`（向量/Mask/Backend 类型定义）
- `src/fafafa.core.simd.dispatch.pas`（派发与后端选择）
- `src/fafafa.core.simd.cpuinfo.pas`（CPU 特性检测门面）
- `src/fafafa.core.simd.api.pas`（高阶门面：mem/text/stat 等）
- `src/fafafa.core.simd.memutils.pas`、`src/fafafa.core.simd.utils.pas`、`src/fafafa.core.simd.ops.pas`
- `src/fafafa.core.simd.backend.iface.pas`、`src/fafafa.core.simd.backend.adapter.pas`
- `src/fafafa.core.simd.direct.pas`、`src/fafafa.core.simd.arrays.pas`、`src/fafafa.core.simd.imageproc.pas`、`src/fafafa.core.simd.builder.pas`

### Backends（实现细节）
- Scalar：`src/fafafa.core.simd.scalar.pas`
- x86：`src/fafafa.core.simd.sse2.pas`、`src/fafafa.core.simd.sse3.pas`、`src/fafafa.core.simd.ssse3.pas`、`src/fafafa.core.simd.sse41.pas`、`src/fafafa.core.simd.sse42.pas`、`src/fafafa.core.simd.avx2.pas`、`src/fafafa.core.simd.avx512.pas`
- i386：`src/fafafa.core.simd.sse2.i386.pas`
- ARM：`src/fafafa.core.simd.neon.pas`
- RISC-V：`src/fafafa.core.simd.riscvv.pas`

### CPUInfo（平台 / 架构实现）
- `src/fafafa.core.simd.cpuinfo.base.pas`
- `src/fafafa.core.simd.cpuinfo.(windows|unix|darwin).pas`
- `src/fafafa.core.simd.cpuinfo.(x86|x86.base|x86.asm|x86.i386|x86.x86_64).pas`
- `src/fafafa.core.simd.cpuinfo.arm.pas`
- `src/fafafa.core.simd.cpuinfo.riscv.pas`
- `src/fafafa.core.simd.cpuinfo.(lazy|diagnostic).pas`

### Intrinsics（更底层的指令封装）
- `src/fafafa.core.simd.intrinsics.*.pas`（SSE/AVX/NEON/RVV/SVE/AES/SHA/MMX/...）

## SIMD 测试矩阵（初版）

### Runner / CLI
- 构建+运行（默认跑全套）：`bash tests/fafafa.core.simd/BuildOrTest.sh test`
- 列出 suites：`tests/fafafa.core.simd/bin2/fafafa.core.simd.test --list-suites`
- 只跑部分 suites：`tests/fafafa.core.simd/bin2/fafafa.core.simd.test --suite=TTestCase_Memutils --suite=TTestCase_DispatchAPI`

### Suites（当前可用）
- Global / Dispatch：`TTestCase_Global`、`TTestCase_DispatchAPI`
- Backend 一致性/冒烟：`TTestCase_BackendConsistency`、`TTestCase_BackendVectorConsistency`、`TTestCase_BackendSmoke`
- VectorAsm/Requirements：`TTestCase_AVX2VectorAsm`、`TTestCase_AVX512VectorAsm`、`TTestCase_AVX512BackendRequirements`
- 功能分类：`TTestCase_VectorOps`、`TTestCase_Memutils`、`TTestCase_ShuffleSWizzle`、`TTestCase_GatherScatter`、`TTestCase_MathFunctions`、`TTestCase_SaturatingArithmetic`、`TTestCase_NarrowIntegerOps`…
- 类型/别名：`TTestCase_UnsignedVectorTypes`、`TTestCase_VectorMaskTypes`、`TTestCase_TypeConversion`、`TTestCase_RustStyleAliases`、`TTestCase_Vec512Types`
- 其它：`TTestCase_SimdConcurrent`、`TTestCase_LargeData`、`TTestCase_EdgeCases`、`TTestCase_AdvancedAlgorithms`…

## Layer0 / Layer1 问题清单（基线快照）

### 已确认“历史问题已恢复/已修复”
- 2026-01-30 的 Layer1 验证报告中提到 `Condvar/Barrier/Once/Spin` 编译失败；当前已通过回归：
  - `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.sync.condvar fafafa.core.sync.barrier fafafa.core.sync.once fafafa.core.sync.spin` → Total=5 Passed=5 Failed=0

### 仍需收敛/待办（与本轮目标强相关）
- SIMD 文档与稳定性标记存在过期/不一致（`simd.STABLE`、`simd.next-steps.md`、`simd.README.md` 等），需要统一“完成定义”和对外承诺边界。
- SIMD 测试 runner 与仓库其它模块的 CLI 约定不一致（不支持 `--all/--format/--progress`），需要统一规范或提供适配层。
- Unix `run_all_tests.sh` 目前无法覆盖仅提供 `.bat` runner 的测试模块（如 `tests/fafafa.core.signal` / `tests/fafafa.core.os`）。

## Decisions
| Decision | Rationale | Evidence |
|----------|-----------|----------|
| SIMD DoD：稳定边界以 `fafafa.core.simd` 门面为主 | 降低 surface，避免锁死内部细节 | `src/fafafa.core.simd.STABLE` + 本文件 DoD |
| 文档收敛：模块文档优先 `docs/fafafa.core.simd*.md` | 避免多个计划文档互相矛盾 | 见“文档收敛范围” |
| 测试 runner：短期保持 SIMD CLI，不强行统一 | 避免引入全仓适配层与额外风险 | `tests/fafafa.core.simd/BuildOrTest.*` 统一入口 |

## Risks / Open Questions
-

## Resources (paths / links)
- `backlog.md`
- `WORKING.md`
- `docs/ARCHITECTURE_LAYERS.md`
- `tests/fafafa.core.simd/`
- `src/fafafa.core.simd.pas`
