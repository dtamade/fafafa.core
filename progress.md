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
- 当前连续通过计数：`2/3`。

### 阶段状态
- Stage B 已完成 nightly 接线与 evidence 归档固化，剩余项仅为连续通过次数补足到 `3/3`。
