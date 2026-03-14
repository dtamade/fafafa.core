# Progress

- 已完成：SIMD 模块审查、主 gate 实跑、关键风险归类。
- 已完成：新增 dispatch 多订阅 hook 能力，并补上去重/移除测试。
- 已完成：抽取 `src/fafafa.core.simd.backend.priority.pas` 作为后端顺序与优先级真相源。
- 已完成：`RegisterBackend` 改为“仅在 dispatch 已初始化时立即重选”，同时移除 dispatch 单元的 eager 初始化。
- 已完成：`gate-strict` 在 `sh/bat` 中默认启用 `SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1`。
- 已完成：清理 `src/fafafa.core.simd.riscvv.pas.backup`。
- 已验证：`TTestCase_DispatchAPI`、`TTestCase_DirectDispatch`、`cpuinfo:TTestCase_Global`、普通 `gate` 通过。
- 第二波开始：目标是低风险拆分 dispatch/cpuinfo/门面层，不改后端语义。
- 第二波完成：通过 include 拆分 simd 类型别名、框架包装、cpuinfo backend 选择、dispatch hook 实现。
- 第三波开始：目标是拆 backend 注册/初始化区块，先不动算子主体。
- 第三波进展：已将 SSE2/AVX2/NEON 的注册与 initialization 区块抽到独立 register.inc。
- 第三波完成：SSE2/AVX2/NEON 的注册与 initialization 区块已拆到独立 register.inc。
- 已修正 check_interface_implementation_completeness.py，使其递归展开本地 {$I ...} include，拆分后统计保持稳定。
- 第四波开始：拆 sse3/ssse3/sse41/sse42/avx512/riscvv 的注册与 initialization 区块。
- 第四波进展：已将 sse3/ssse3/sse41/sse42/avx512/riscvv 的注册区抽到独立 register.inc。
- 第四波验证中：gate 正常，DispatchAPI 首次因并发构建出现 missing binary，将顺序补跑。
- 第四波完成：sse3/ssse3/sse41/sse42/avx512/riscvv 的注册与 initialization 区块已拆到独立 register.inc。
- 第五波开始：拆 avx512/riscvv 的 helper 与 facade 区块，保持语义不变。
- 第五波进展：已抽出 avx512.facade.inc、riscvv.facade.inc、riscvv.helpers.inc。
- 第五波完成：avx512 facade/memory 区与 riscvvv facade/helper 区已拆到独立 include。
- 第六波进展：已抽出 sse2.memory.inc、sse2.facade_extra.inc、avx2.facade.inc。
- 第六波完成：已抽出 sse2.memory.inc、sse2.facade_extra.inc、avx2.facade.inc，并完成回归。
- 第七波开始：拆 neon facade/helper、avx512 fallback、sse2.i386 注册块。
- 第七波进展：已抽出 neon.facade_asm/scalar/platform、avx512.fallback、sse2.i386.register。
- 第七波完成：已抽出 neon facade 三段、avx512 fallback、sse2.i386.register，并通过回归。
- 第八波开始：继续拆 avx512/neon 的低风险 helper 分段。
- 第八波进展：已抽出 avx512.mask_sat.inc、neon.dot.inc。
- 第八波完成：已抽出 avx512.mask_sat.inc 与 neon.dot.inc，并通过回归。
- 第九波开始：优先拆 NEON 的 comparison/reduction/memory utility 分段。
- 第九波进展：已抽出 neon.scalar_fallback.inc。
- 第九波进展：已抽出 AVX512 family includes 与 NEON scalar compare/math/reduction/memory/utility includes。
- 新一轮开始：继续细拆 AVX512 整数 family include。
- 继续轮完成：已抽出 AVX512 F32x16/F64x8 family includes 与 NEON scalar 子段 includes，并通过回归。
- 新一轮开始：继续细拆 AVX512 整数 family include。
- 新一轮进展：已抽出 AVX512 整数 family includes。
- 新一轮完成：已抽出 AVX512 整数 family includes，并通过回归。
- 下一波开始：转向 NEON 剩余大段，优先拆 wrapper/reduction/memory 操作区。
- 继续轮进展：已抽出 neon.scalar.autowrap.inc、neon.scalar.wide_reduce.inc、neon.scalar.wide_memory.inc。
- 继续轮完成：已抽出 neon.scalar.autowrap/wide_reduce/wide_memory，并通过回归。
- 当前 AVX512 与 NEON 的 helper/family 已基本按注释边界拆成 include。
- 新阶段开始：转向拆 tests/fafafa.core.simd/fafafa.core.simd.testcase.pas 这类超大测试文件。
- 继续轮进展：已抽出 neon.scalar.autowrap.inc、neon.scalar.wide_reduce.inc、neon.scalar.wide_memory.inc。
- 方向切换：开始拆 tests/fafafa.core.simd/fafafa.core.simd.testcase.pas 的大块测试结构。
- 测试文件拆分：已抽出 testcase.types/backend_group/feature_group/register include。
- 测试侧拆分完成：testcase.types/backend_group/feature_group/register 已抽出，关键 suite 与 gate 通过。
- 已按要求回滚 tests/fafafa.core.simd/fafafa.core.simd.testcase.pas 的拆分；后续不再拆单元测试文件。
- 继续轮进展：已抽出 neon.reduce.inc、neon.memory.inc、neon.utility.inc、neon.compare.inc。
- 继续轮完成：已抽出 neon.reduce/memory/utility/compare，并通过回归。
- 继续代码侧进展：已抽出 AVX2 f32x8/f64x4/i32x8/wide_emulation family includes。
- 继续代码侧进展：已抽出 SSE2 后半段 family includes。
- 继续代码侧进展：已抽出 SSE2 f32x8/ext_math/vector_math/saturating/i64x2/mask/select/wide_emulation includes。
- 继续代码侧进展：已抽出 SSE2 后半段 family includes。
- 继续代码侧进展：已抽出 SSE2 后半段 family includes。
- 尝试继续细拆 SSE2 family 时发现已超出低风险边界，已回退该文件到稳定状态；DispatchAPI/Direct/gate 重新通过。
- 方向调整：停止高风险 SSE2 细拆，改做 src/ 侧结构文档与收口说明。
- 下一步改做 SIMD 结构总览/维护指南，不再继续高风险代码拆分。
- 维护指南已补 include 清单与维护者检查表；README/模块文档入口已校对。
- 已新增短版 SIMD 阅读地图，并从维护指南与 README 挂入口。
- 继续文档线：准备新增一页 SIMD 当前状态与后续建议总结。
- 维护指南已补命名规则与目录速查统计。
- 继续文档收口：准备新增 SIMD 最终交接总结页。
- 已新增最终交接总结页，并从维护指南挂入口。
- 已新增 SIMD 极简行动清单，并从维护指南与交接总结挂入口。

<!-- SIMD-WIN-CLOSEOUT-2026-03-10 -->
### 批次
- SIMD-20260310-152

### 执行动作
- 在 Windows 实机完成 buildOrTest.bat evidence-win-verify。
- 生成并归档收口摘要：finalize-win-evidence。
- 回填 roadmap / matrix / progress，关闭跨平台证据缺口。

### 命令与结果
| Command | Result |
|---|---|
| tests\fafafa.core.simd\buildOrTest.bat evidence-win-verify | PASS |
| bash tests/fafafa.core.simd/BuildOrTest.sh finalize-win-evidence | PASS |
| bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status | PASS |
| bash tests/fafafa.core.simd/apply_windows_b07_closeout_updates.sh --apply --freeze-json tests/fafafa.core.simd/logs/freeze_status.json | PASS |

### 关键证据
- Log: tests/fafafa.core.simd/logs/windows_b07_gate.log
- Summary: tests/fafafa.core.simd/logs/windows_b07_closeout_summary.md

### 阶段状态
- 跨平台冻结条件满足。

<!-- SIMD-NIGHTLY-CLOSEOUT-2026-03-10 -->
### 批次
- SIMD-NIGHTLY-20260310

### 执行动作
- 建立独立 `simd-nightly-closeout` workflow，拆分 Linux evidence、Windows evidence、freeze audit 三段。
- 修正 Linux runner / Windows closeout helper / freeze 判定链路中的实际落地问题。
- 将 nightly 口径收回 stable lane，experimental 继续隔离跟踪。

### 关键结果
- GitHub Actions `22918810451`：`SIMD Nightly Closeout` 全绿。
- GitHub Actions `22919783249`：`SIMD Nightly Closeout` 全绿。
- GitHub Actions `22921866560`：`SIMD Nightly Closeout` 全绿。
- 当前连续通过计数：`3/3`。

### 阶段状态
- Stage B 已完成：nightly 接线、evidence 归档固化、以及 `3/3` 连续通过验证。

<!-- SIMD-STAGEC-NONX86-COVERAGE-2026-03-11 -->
### 批次
- SIMD-STAGEC-20260311

### 执行动作
- 以小批次连续补齐 non-x86（`sbNEON` / `sbRISCVV`）dispatch 缺口。
- 新增并验证 `AndNot narrow`、`RVV dot`、`I16x32`、`I8x64`、`U32x16`、`U64x8`、`U8x64` 与 `I16x32 shift` 等高 ROI 槽位。
- 将 non-x86 高 ROI 目标槽位接入 `check_interface_implementation_completeness.py`，固定“先红后绿”的本地红灯。

### 关键结果
- `python3 tests/fafafa.core.simd/check_interface_implementation_completeness.py --strict --json`：PASS
- `bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`：PASS
- `bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAllSlots`：PASS
- `bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS
- `SIMD_GATE_PERF_SMOKE=1 SIMD_PERF_VECTOR_ASM=auto bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict`：已确认 `perf=1` 进入 gate 摘要，且 `perf-smoke` 记录为 `PASS`
- 当前机器检查覆盖：`dispatch=558, neon=558, riscvv=558, P0=0/P1=0/P2=0`
- 已新增 fixed-seed fuzz parity：覆盖 `I16x32/I8x64/U32x16/U64x8/U8x64` 的宽整型语义护栏。
- 已扩展 benchmark 样本：`VecI16x32Add / VecU32x16Mul / VecU64x8Add / VecU8x64Max`
- 已给 benchmark runner 增加口径提示：默认 `--bench-only` 若 `vector-asm` 关闭，会明确提示部分向量行可能仍是 scalar fallback。
- 已给 `run_backend_benchmarks.sh` 增加 x86_64 `AVX2_vs_Scalar` 稳定路径，并已刷新最新 summary：`tests/fafafa.core.simd/logs/backend-bench-20260311-103804/summary.md`
- 已将 `perf-smoke` 默认口径对齐到 `x86_64/AMD64 -> --bench-only --vector-asm`，并实跑通过。
- 已新增 raw-dispatch 基准行：
  - `VecF32x4AddRaw`
  - `VecI16x32AddRaw`
  - `VecU32x16MulRaw`
  - `VecU64x8AddRaw`
  - `VecU8x64MaxRaw`
- 已为热点门面接入 hook 绑定的 cached fast-path：`VecF32x4Add / VecI16x32Add / VecU32x16Mul / VecU64x8Add / VecU8x64Max`
- 已新增 raw-dispatch benchmark 对照：用于区分“门面/dispatch 开销”与“后端算子本体开销”。
- 已将 façade fast-path 的热路径读取从显式 `mo_acquire` 收紧为平台默认读序：
  - `x86/x86_64` 走 relaxed，去掉 `_compiler_barrier` 调用
  - 弱序平台仍保留 acquire 级别默认语义
- 已在 façade 层补齐 backend 状态四层语义入口：
  - `supported_on_cpu`：`GetSupportedBackendList` / `GetBestSupportedBackend`
  - `registered`：`GetRegisteredBackendList` / `IsBackendRegisteredInBinary`
  - `dispatchable`：`GetDispatchableBackendList` / `GetAvailableBackendList`
  - `active`：`GetCurrentBackend` / `GetCurrentBackendInfo`
- 已扩展 `DispatchAPI` 一致性测试，固定 `supported ⊇ registered ⊇ dispatchable` 与 `active ∈ dispatchable`
- 已在类型定义与 roundtrip 测试里补齐 dispatch contract guard：
  - `TSimdBackendInfo` / `TSimdDispatchTable` 明确声明为 in-repo contract，而非 public binary ABI
  - `DispatchAllSlots` 现固定校验 `BackendInfo.Name/Description/Capabilities/Available/Priority` roundtrip 不漂移
- 已新增 machine-readable dispatch contract signature guard：
  - 脚本：`tests/fafafa.core.simd/check_dispatch_contract_signature.py`
  - 产物：`tests/fafafa.core.simd/logs/dispatch_contract_signature.json`
  - `gate` 默认已带上 `contract-signature` 结构检查
- 已新增 machine-readable public ABI signature/layout guard：
  - 脚本：`tests/fafafa.core.simd/check_public_abi_signature.py`
  - 产物：`tests/fafafa.core.simd/logs/public_abi_signature.json`
  - `gate` / `gate-strict` 默认已带上 `publicabi-signature` 结构检查
- 已确认 `contract-signature` 已进入 release-gate / `gate-strict` 完整门禁，并通过 closeout 口径复验：
  - `SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=0 SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=1 SIMD_GATE_EXPERIMENTAL_TESTS=0 SIMD_GATE_PERF_SMOKE=1 SIMD_PERF_VECTOR_ASM=auto bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict`
  - QEMU 证据：`tests/fafafa.core.simd/logs/qemu-multiarch-20260311-211136-2040384/summary.md`
- 新阶段开始：public ABI wrapper / signature 设计转入实现。
- 已在 `fafafa.core.simd` 单元内落下第一版 public ABI skeleton：
  - `TFafafaSimdBackendPodInfo`
  - `TFafafaSimdPublicApi`
  - `GetSimdAbiVersionMajor/Minor`
  - `GetSimdAbiSignature`
  - `TryGetSimdBackendPodInfo`
  - `GetSimdBackendNamePtr` / `GetSimdBackendDescriptionPtr`
  - `GetSimdPublicApi`
- 已实现“绑定后直调”的 public data-plane：
  - `GetSimdPublicApi` 返回缓存后的 public API table
  - 当前 table 已绑定 `MemEqual / MemFindByte / MemDiffRange / SumBytes / CountByte / BitsetPopCount / Utf8Validate / AsciiIEqual`
  - backend 切换后通过 dispatch hook 自动重绑
- 已把 public API table 切到 C ABI shim：
  - public function pointer 类型显式 `cdecl`
  - shim 调用缓存后的 bound 函数指针，不重复查内部 dispatch table
- 已把 public ABI 热点调用范式做成 bench 证据：
  - `tests/fafafa.core.simd/fafafa.core.simd.bench.pas`
  - 新增 32-byte hot-path 行：`HotMemEqPubCache / HotMemEqPubGet / HotMemEqDispGet / HotSumPubCache / HotSumPubGet / HotSumDispGet`
  - 用于持续对比 façade、缓存后的 public API table、重复 `GetSimdPublicApi`、重复 `GetDispatchTable` 这几种写法
- 已把 public ABI 热点调用关系接进 `perf-smoke` 自动校验：
  - 脚本：`tests/fafafa.core.simd/check_perf_smoke_log.py`
  - shell / batch runner 都会在有 Python 时复用它
  - 当前护栏：`PubCache` 不应明显慢于 `PubGet`，且 `PubGet` 应明显快于 `DispGet`
- 已新增 `TTestCase_PublicAbi`，覆盖：
  - public API table metadata
  - backend POD flags 一致性
  - façade data-plane parity
- 已新增 external smoke 模块：`tests/fafafa.core.simd.publicabi/`
  - 共享库：`fafafa.core.simd.publicabi.lpr`
  - C header：`publicabi_smoke.h`
  - C harness：`publicabi_smoke.c`
  - `BuildOrTest.sh test` 已可完成 `shared library + dlsym + public api table` smoke
- 已将 `publicabi-smoke` 接入主 `gate`
  - shell gate 默认会跑 `tests/fafafa.core.simd.publicabi/BuildOrTest.sh test`
  - 这样 public ABI wrapper 不再只是独立 smoke，而是主模块日常门禁的一部分
- 已为 public ABI 模块补导出符号校验：
  - `BuildOrTest.sh validate-exports`
  - 通过 `readelf --wide --dyn-syms` 校验 `fafafa_simd_*` 必要符号
- 已补 Windows external smoke 入口：
  - `tests/fafafa.core.simd.publicabi/BuildOrTest.bat`
  - `tests/fafafa.core.simd.publicabi/publicabi_smoke.ps1`
  - Windows 路径通过 PowerShell + C# P/Invoke 做导出与最小 data-plane smoke
- 最新稳定 backend benchmark（`tests/fafafa.core.simd/logs/backend-bench-20260311-103804/summary.md`）：
  - `VecI16x32Add`：`3.35x`；`VecI16x32AddRaw`：`3.07x`
  - `VecU32x16Mul`：`0.99x`；`VecU32x16MulRaw`：`1.00x`
  - `VecU64x8Add`：`0.76x`；`VecU64x8AddRaw`：`0.80x`
  - `VecU8x64Max`：`3.96x`；`VecU8x64MaxRaw`：`4.31x`
  - `VecF32x4Add`：`0.76x`；`VecF32x4AddRaw`：`0.89x`
- 当前 benchmark 结论已经可以收口：
  - `VecI16x32Add`：门面与 raw 都已确认正收益，且 façade 热路径进一步减负后收益更明显。
  - `VecU32x16Mul`：已从明确负收益拉回到接近持平；现阶段不再是高优先级性能事故。
  - `VecU64x8Add`：raw 仍低于 scalar，说明 AVX2 宽仿真本体尚未证明 ROI，优化优先级下降。
  - `VecU8x64Max`：门面与 raw 都持续正收益，仍可作为宽字节类 fast-path 样板。
  - `VecF32x4Add`：raw 与门面都不占优，不应作为下一轮优化重点。

### 阶段状态
- Stage C 第一轮能力扩展已形成阶段性收口：non-x86 在当前机器检查口径下达到满覆盖，并保持 gate 通过。
- 下一阶段重点应转向“高 ROI 维护清单”，不再把低价值优化当主线：
  - 保留并复用：`VecI16x32Add`、`VecU8x64Max`
  - 仅低成本观察：`VecU32x16Mul`
  - 降级观察，不再主动深挖：`VecU64x8Add`、`VecF32x4Add`
  - 继续主线收口：stable boundary、evidence contract、文档真相源统一

<!-- SIMD-WIN-CLOSEOUT-2026-03-14 -->
### 批次
- SIMD-20260314-156

### 执行动作
- 在 Windows 实机完成 buildOrTest.bat evidence-win-verify。
- 生成并归档收口摘要：finalize-win-evidence。
- 回填 roadmap / matrix / progress，关闭跨平台证据缺口。

### 命令与结果
| Command | Result |
|---|---|
| tests\fafafa.core.simd\buildOrTest.bat evidence-win-verify | PASS |
| bash tests/fafafa.core.simd/BuildOrTest.sh finalize-win-evidence | PASS |
| bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status | PASS |
| bash tests/fafafa.core.simd/apply_windows_b07_closeout_updates.sh --apply --freeze-json tests/fafafa.core.simd/logs/freeze_status.json | PASS |

### 关键证据
- Log: tests/fafafa.core.simd/logs/windows_b07_gate.log
- Summary: tests/fafafa.core.simd/logs/windows_b07_closeout_summary.md

### 阶段状态
- 跨平台冻结条件满足。
