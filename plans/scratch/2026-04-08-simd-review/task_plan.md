# SIMD Review Task Plan

## Goal

审查 `fafafa.core.simd` 当前结构、验证基线和成熟度边界，输出一份可直接执行的整改方案。

## Scope

- `src/fafafa.core.simd*`
- `tests/fafafa.core.simd*`
- `docs/fafafa.core.simd*`
- 相关 `docs/plans/*simd*`

## Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 建立审查上下文与工作台 | completed | 已切回当前 `main` worktree 真实状态，并接管 scratch 记录 |
| 2. 收集结构、测试、文档与 gate 证据 | completed | 已区分“假红基础设施问题”与 full test 暴露的真实实现缺陷 |
| 3. 提炼问题并按严重度排序 | completed | 当前真实优先级已更新为：SSE2 F64 IEEE754 rounding 语义缺陷 > façade alias 面继续收敛 > runtime snapshot 发布模型稳态化 |
| 4. 形成成熟整改方案 | completed | 当前 Linux fast-gate 已重回绿态；接口挂接完整度为绿，剩余重点转为 release 级跨平台证据刷新，而非 simd stable surface 的新增接口缺口 |
| 5. SIMD plan hygiene 与主链去干扰 | completed | `docs/plans/*simd*` 已明确分成 `active / historical / superseded`，并落下 `plan-status-index` 作为主入口 |
| 6. Wave 2 active 实施计划补全 | completed | 已新增当前第一波 `seam hardening` active plan，把 `dispatch / dataplane / public ABI / direct / façade fast-path` 的边界、红线、baseline 和完成标准写成独立作战单 |

## Constraints

- 默认使用仓库现有脚本与文档，不做无审批的大规模架构改写
- 审查优先关注 stable surface、dispatch/cpuinfo 语义、非 x86 成熟度、验证闭环
- 若根目录 `task_plan.md/findings.md/progress.md` 与仓库约定冲突，优先使用 worktree-local scratch

## Errors Encountered

| Error | Attempt | Resolution |
| --- | --- | --- |
| `mcp__ace_tool__search_context` 首次返回 499 | 1 | 缩窄查询后重试成功 |
| `CLAUDE_PLUGIN_ROOT` 未注入，无法直接调用 planning skill 辅助脚本 | 1 | 改为使用已知 skill 安装路径和 worktree-local scratch |
| `BuildOrTest.sh test` 在 full suite 下 `rc=217` | 1 | 已缩到并发/public ABI 与 IEEE754 两类真实失败，按最小失败面分治修复 |
| `rg -n` 直接扫 IEEE754 testcase 输出过大 | 1 | 改为先定位具体 suite 名称与行号，再按区段读取 |
| `gate` 最后一步 `run_all-chain` 失败 | 1 | 已定位为 `cpuinfo.x86` Windows batch runner success-criteria 合同缺口，修复后 `gate` 恢复 PASS |
| 批量给旧 `simd` plan 插入状态头时首次落到了文档尾部 | 1 | 已去掉错误的跨行匹配方式，先清除误插入块，再把状态头重插到标题下 |

## 2026-05-09 Subtask

### Goal

按既有方案把 SIMD 接口层收口落地：冻结 backend adapter / intrinsics leaf 口径，补三张真相表，并把 SSE2 归属护栏写进现有检查链。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核当前主线与旧审查结论 | completed | 已按 `map -> maintenance -> handoff -> src/tests` 顺序回读，并确认当前 `SSE2` 真相仍在 `src/fafafa.core.simd.sse2.pas` |
| 2. 补真相源文档与代码注释 | completed | 已新增 `SIMD_BACKEND_TRUTH.md`、`SIMD_INTRINSICS_DISPOSITION.md`、`SIMD_SSE2_MIGRATION_MAP.md`，并同步到 README/maintenance/interface/handoff/STABLE 与关键单元注释 |
| 3. 把归属判断落成机器护栏 | completed | `check_sse2_structure.py` 已扩展为同时检查 SSE2 文件结构、三张真相表、`simd.sse2 -> intrinsics.sse2` 反向依赖禁令，以及 `intrinsics.x86.sse2` 的 raw-leaf 边界 |
| 4. release 验证与提交收口 | completed | `check_sse2_structure.py`、`check_intrinsics_experimental_status.py`、`BuildOrTest.sh check`、`BuildOrTest.sh gate` 已通过；已完成 review + commit |

## 2026-05-09 Documentation Follow-up

### Goal

把“三层目标形态、为什么不是两层、实施时哪些职责能下沉/必须保留”写成正式裁决文档，避免后续实施时重新口头争论架构口径。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 抽出三层/两层争议的裁决问题 | completed | 已确认现有真相表能回答“谁是谁”，但还缺一页专门回答“为什么不是两层、后续怎么实施”的文档 |
| 2. 落地正式实施基线文档 | completed | 已把主文档重写成“3 个逻辑层 + 核心单元分类 + 4 种 intrinsics 状态 + 1 套依赖准入规则”的版本，不再混淆 namespace、SSE2 局部规则与全局规则 |
| 3. 同步入口文档与 scratch 记录 | completed | `maintenance`、`disposition`、`migration map` 已补齐 `active leaf` 准入规则与 `experimental isolated` 禁入 stable adapter 的前提，且结构护栏验证继续通过 |

## 2026-05-09 Architecture Review Closure

### Goal

审查 `SIMD_LAYERING_IMPLEMENTATION.md` 是否已经足够“正确、优雅、全局”，并把遗漏的真实代码面补进正式架构口径，确保下一会话可直接按文档实施。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 对照真实代码面复核主文档 | completed | 已核对 `simd.pas`、`dispatch`、`direct`、`public_abi` include 与 `STABLE/publicabi/interface/maintenance` 文档 |
| 2. 补齐全局架构缺口 | completed | 已把 `public ABI wrapper` 与 `direct dispatch companion` 明确写入主设计文档和入口维护文档，不再让读者自行脑补 |
| 3. 结构验证与文档收口 | completed | `git diff --check`、`check_sse2_structure.py`、`check_intrinsics_experimental_status.py` 均通过；本轮文档收口可提交 |

## 2026-05-09 Publication Seam Closeout

### Goal

把整个 SIMD 模块视角下“最优雅终态”正式写进文档，并把 `dataplane` 从隐藏实现细节提升成显式的 `publication seam`，供下一次新会话直接按此实施。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `dataplane` 的真实职责 | completed | 已确认 `simd.pas` façade fast-path、`public_abi`、`direct` 都直接消费 `dataplane`，它已是共享 published binding seam |
| 2. 同步主设计与入口文档 | completed | 已把 `SIMD_LAYERING_IMPLEMENTATION`、`interface`、`maintenance`、`map`、`handoff`、`checklist`、`README`、`architecture`、`STABLE` 统一到同一口径 |
| 3. 轻量验证与提交收口 | completed | `git diff --check`、`check_sse2_structure.py`、`check_intrinsics_experimental_status.py` 已通过；待写 review 结论并提交 |

## 2026-05-09 Whole-Module Refactor Pivot

### Goal

把本轮目标从 `SSE2-first` 的局部架构收口，升级成“整个 `fafafa.core.simd` 模块如何低冗余重构”的总纲，避免后续把某个 family 的迁移策略误当成全局架构。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 识别当前计划的局部性边界 | completed | 已确认 `SSE2` 方案适合作为高债务试点，但不足以覆盖 `AVX2/AVX-512/NEON/RISCVV` 等 family 的全局治理 |
| 2. 写出全模块统一终态与冗余定义 | completed | 已新增全局总纲，明确 `public/control surface -> seam -> companion -> adapter -> raw leaf` 的统一目标，并把“真相源/语义/入口/状态冗余”分开定义 |
| 3. 定义全 ISA 分组与波次 | completed | 已把 family 拆成正样板、高债务、adapter-only、opt-in experimental 四类，并把 `SSE2` 降级成 Wave 3 子计划 |
| 4. 把新总纲接入当前阅读入口 | completed | 已把全局总纲接入 `map`，并确认后续新会话可从全模块入口起盘 |
| 5. 补 execution-ready 文档部件 | completed | 已新增 family matrix，并把总纲/source-of-truth 分工与 Wave exit criteria 补全 |
| 6. 补 family-level 子计划 | completed | 已新增 AVX2 正样板、x86 incremental qualification、NEON qualification、RISCVV qualification 四份文档，whole-module 计划不再卡在总纲层 |

## 2026-05-10 Wave 2 Seam Hardening Batch 1

### Goal

开始真正的 Wave 2 实施，先把 `public ABI wrapper` 从“独立 invalidate + 第二套 dispatch truth”收回成严格跟随 `dataplane` published snapshot 的 companion surface。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 锁定 Batch 1 边界 | completed | 这批只碰 `public_abi.impl.inc`、`simd.pas` 初始化/收尾接线、`dataplane` 相关测试；不打开 family migration，也不扩 runtime/cpuinfo 语义 |
| 2. public ABI 绑定语义收紧 | completed | `public ABI` 现在按 `PSimdDataPlane` 复用/发布 metadata table，不再维护独立 `target dispatch ptr`，也不再依赖独立 invalidate hook |
| 3. fallback 语义收回 dataplane | completed | `PublicAbi*` cdecl wrapper 的兜底路径已从 `GetDispatchTable` 改成读取当前已发布 `dataplane` 槽位，消除第二条 publication path |
| 4. seam 回归验证与提交收口 | completed | `git diff --check`、Release `check`、`TTestCase_DataPlane`、`TTestCase_PublicAbi`、`TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework`、`TTestCase_DispatchAPI`、`TTestCase_RuntimeAPI`、`TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent`、`gate` 已通过；已完成 review + commit |

## 2026-05-11 Facade Dispatch Unification

### Goal

把 `src/fafafa.core.simd.pas` 里残留的 façade wrapper 统一收回到 `dataplane` 发布的 dispatch 读取路径，避免 façade 继续显式依赖第二套 dispatch getter 语义。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 找出残留的直接 dispatch 读取 | completed | 已确认 `simd.pas` 里大量 façade wrapper 仍直接调用 `GetDispatchTable`，而不是显式读 `dataplane` published snapshot |
| 2. 统一 façade wrapper 读取路径 | completed | 已将 `src/fafafa.core.simd.pas` 中所有 `GetDispatchTable` 调用统一替换为 `GetCurrentSimdDataPlaneDispatch` |
| 3. 验证并继续扫残余重复实现 | completed | Release `check`、targeted seam suites、`gate` 已通过；`api` / `ops` / `arrays` 已统一到 `GetDirectDispatchTable`，下一步继续检查 runtime/cpuinfo/family 面是否还有可清理的重复 truth 或多重实现 |
| 4. 继续扫剩余消费面 | completed | 已把 `GetDispatchTable` 直读收进 `dispatch-read-scope` 护栏；runtime 内部已去掉 `RegisteredFlags` 重复状态并收拢成共用 snapshot 读取 helper；cpuinfo legacy aliases 与 framework 转发层确认只是 compatibility thin shells；Wave 2 seam hardening 已完成，下一步进入 `Wave 3A / AVX2` |

## 2026-05-11 AVX2 Sample Noise Cleanup

### Goal

把 `AVX2` 样板里历史演进标记清掉，让文件读起来像稳定实现，而不是项目日志。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 收敛注释噪音 | completed | 已清理 `src/fafafa.core.simd.avx2.pas` / `src/fafafa.core.simd.avx2.register.inc` 中的 `NEW / Iteration / milestone` 标记，保留真正的 section header 与语义注释 |
| 2. 复验样板 lane | completed | `git diff --check`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_AVX2IntrinsicsFallback` 均通过 |
| 3. 继续 Wave 3A | pending | 下一步保持 AVX2 为正样板，继续检查是否还有真实的重复实现可合并 |

## 2026-05-11 AVX2 CmpEq Family Consolidation

### Goal

把 AVX2 里真实重复的 `CmpEq` 实现收回成按宽度共享的 raw helper，保留 typed thin wrappers 和 dispatch 入口，不去碰语义不同的 `Lt/Gt/Le/Ge/Ne`。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 识别可合并的 Eq 重复簇 | completed | `I32x4/U32x4`、`I16x8/U16x8`、`I8x16/U8x16`、`I64x2/U64x2` 只是在相同宽度上重复了 compare + mask extraction；`F32/F64` 仍保持独立语义 |
| 2. 收回重复实现到 raw helper | completed | 已引入 dword/word/byte/qword width-specific compare helper，typed wrappers 只保留签名和 dispatch 入口 |
| 3. Release 验证与收口 | completed | `git diff --check`、Release `DispatchAPI/DirectDispatch`、`check`、`gate` 全部通过；待提交 |

## 2026-05-11 AVX2 256-bit CmpEq Consolidation

### Goal

把 AVX2 里 256-bit 的同宽 `CmpEq` 重复实现也收回成 shared raw helper，继续保留 typed wrapper / dispatch 入口，不碰 float compare 语义。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 识别 256-bit Eq 重复簇 | completed | `I32x8/U32x8`、`I64x4/U64x4` 只是同宽 compare + mask extraction 重复；`F32x8/F64x4` 保持独立语义 |
| 2. 收回重复实现到 raw helper | completed | 已引入 256-bit dword/qword compare helper，typed wrappers 只保留签名和 dispatch 入口 |
| 3. Release 验证与收口 | completed | `git diff --check`、Release `DispatchAPI/DirectDispatch`、`check`、`gate` 全部通过；待提交 |

## 2026-05-11 AVX2 Integer CmpNe Consolidation

### Goal

把 AVX2 整数 `CmpNe` 收成 `CmpEq` 反相的薄封装，保留浮点 `CmpNe` 独立语义，不再重复写一遍 compare + not + mask extraction。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 识别可合并的整数 CmpNe 簇 | completed | `I32x4/U32x4`、`I16x8/U16x8`、`I8x16/U8x16`、`I64x2/U64x2`、`I32x8/U32x8`、`I64x4/U64x4` 都可直接由 Eq 反相得到 |
| 2. 收回重复实现到 Eq 反相薄壳 | completed | 已让整数 `CmpNe` 只做 mask 翻转，浮点 compare 不动 |
| 3. Release 验证与收口 | completed | `git diff --check`、Release `check`、Release `gate` 全部通过；待提交 |

## 2026-05-11 AVX2 Integer Comparison Thin Wrapper Consolidation

### Goal

把 AVX2 整数 `CmpLt/CmpLe/CmpGe` 收成 `CmpGt` 交换参数/反相薄封装，保留 `CmpGt` 的真实比较语义和浮点 compare 独立实现，避免每个 family 再维护一份 compare + NOT + mask extraction。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 识别可合并的整数 compare wrappers | completed | `I32x4/U32x4`、`I16x8/U16x8`、`I8x16/U8x16`、`I64x2/U64x2`、`I32x8/U32x8`、`I64x4/U64x4` 的 `CmpLt/CmpLe/CmpGe` 都只是 `CmpGt` 相关薄壳 |
| 2. 收回重复实现到 thin wrapper | completed | 已让整数 `CmpLt/CmpLe/CmpGe` 统一退回交换参数或 `MASK_ALL_SET xor ...`，其中 `CmpGe` 也直接落到 `CmpGt(b, a)`，`CmpGt` 保持真比较语义 |
| 3. Release 验证与收口 | completed | `git diff --check`、Release `gate` 已通过；待提交 |

## 2026-05-11 AVX2 I64x2 Min/Max Selection Consolidation

### Goal

把 `AVX2` 里 `I64x2/U64x2` 的 `Min/Max` lane selection 收成一个共享 raw helper，保留 compare 语义和 typed wrapper，不再维护四份同构的 lane-by-lane if/else。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 识别重复选择逻辑 | completed | `MinI64x2 / MaxI64x2 / MinU64x2 / MaxU64x2` 都是同一段 mask 驱动的 lane 选择逻辑 |
| 2. 收回共享 raw helper | completed | 已新增 `AVX2SelectI64x2ByMaskRaw`，四个 wrapper 只保留各自 compare 语义和签名 |
| 3. 验证与收口 | completed | `git diff --check`、Release `gate` 已通过；待提交 |

## 2026-05-11 X86 Incremental Noise Cleanup

### Goal

把 SSE3 / SSSE3 的历史注释噪音收掉，让 x86 incremental family 读起来一致、干净。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 收敛注释噪音 | completed | 已清理 `src/fafafa.core.simd.sse3.pas` / `src/fafafa.core.simd.sse3.register.inc` / `src/fafafa.core.simd.ssse3.pas` / `src/fafafa.core.simd.ssse3.register.inc` 中的 `NEW / Task 5.1 / milestone` 标记 |
| 2. 复验样板 lane | completed | `git diff --check`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check` 均通过 |
| 3. 继续 Wave 3B | pending | 下一步进入 SSSE3 关系更明确的分组检查，确认还有没有真实重复实现可合并 |

## 2026-05-11 X86 Incremental Redundancy Collapse

### Goal

把 `SSSE3` 上和 `SSE2` 完全重复的 `MinI8x16 / MaxI8x16` dispatch override 收回，让这条 family 保留真正增量和兼容别名，不再维护多一份同义实现。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 识别重复实现 | completed | 已确认 `SSSE3MinI8x16 / SSSE3MaxI8x16` 只是 SSE2 compare+blend 的重复实现，并没有形成更强的 SSSE3 语义 |
| 2. 收回冗余 override | completed | dispatch table 已直接继承 `SSE3/SSE2` core slots，SSSE3 只保留 compatibility direct helpers |
| 3. 验证与收口 | completed | `DispatchAPI`、Release `check`、`impl-smoke-x86`、`gate` 均已通过 |

## 2026-05-11 AVX2 Lane Helper Consolidation

### Goal

把 AVX2 里重复的 128-bit lane helper 选择/边界逻辑收回到单一 reference 实现，保留 AVX2-owned dispatch slot 与 capability 行为，不再在 backend 里重写同义代码。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 识别重复 lane helpers | completed | 已确认 `AVX2SelectF32x4 / AVX2ExtractF32x4 / AVX2InsertF32x4 / AVX2SelectF64x2` 与 scalar helper 只是重复的 lane 选择/边界逻辑 |
| 2. 收回 AVX2 重复实现 | completed | 这四个 wrapper 已委托给 scalar reference helper，dispatch ownership 保持不变 |
| 3. Release 验证与收口 | completed | `git diff --check`、`check`、`TTestCase_DispatchAPI`、`gate` 均已通过，工作树只剩计划文件与源码变更 |

## 2026-05-11 SSE2 Lane Helper Consolidation

### Goal

把 SSE2 里和 scalar 完全同构的 128-bit lane helper 收回到 reference 实现，保留 SSE2 的 dispatch-owned slot，不再重写同义的 select / extract / insert 边界逻辑。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 识别重复 lane helpers | completed | 已确认 `SSE2SelectF32x4 / SSE2ExtractF32x4 / SSE2InsertF32x4` 与 scalar helper 只是重复的 lane 选择/边界逻辑 |
| 2. 收回 SSE2 重复实现 | completed | 这三个 wrapper 已委托给 scalar reference helper，dispatch ownership 保持不变 |
| 3. Release 验证与收口 | completed | `git diff --check`、`check`、`TTestCase_DispatchAPI`、`gate` 均已通过；`SSE2SelectF64x2` 与 wide-emulation 路径保持原样，因为它们并非同构重复 |

## 2026-05-11 SSE2 Wide Emulation Boundary Normalization

### Goal

把 `SSE2` wide-emulation 的 extract/insert 边界语义统一回 scalar clamp 规则，清掉那组 `index and N` 的 wrap-around 老实现，让 wide vector helper 和全模块其余路径保持一致。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 识别边界语义漂移 | completed | 已确认 `SSE2.wide_emulation.inc` 里 18 个 wide extract/insert helper 都在用 wrap-around 索引，而 scalar/reference 走 clamp |
| 2. 统一边界语义 | completed | 这批 wide extract/insert 已改成直接委托 scalar reference helper，dispatch ownership 保持不变 |
| 3. Release 验证与收口 | completed | `git diff --check`、`TTestCase_DispatchAPI,TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent`、`gate` 均已通过 |

## 2026-05-11 SSE4.1 Blend Kernel Consolidation

### Goal

把 `SSE4.1` 的 bitmask selection 收成单一 native blend kernel，避免 `SelectF32x4` 自己再维护一份 `blendvps` 序列。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 识别重复 blend 路径 | completed | `SSE41SelectF32x4` 与 `SSE41BlendVF32x4` 之前各自维护一份选择/混合逻辑 |
| 2. 收口到单一 kernel | completed | `SSE41SelectF32x4` 现在只做 `TMask4 -> TMaskF32x4` 展开，然后委托 `SSE41BlendVF32x4` |
| 3. Release 验证与收口 | completed | `git diff --check`、`check`、`TTestCase_DispatchAPI`、`gate` 均已通过 |

## 2026-05-11 SSE4.2 String Helper Consolidation

### Goal

把 `SSE4.2` 的 `FindFirstOf_SSE42 / FindFirstNotOf_SSE42` 收回到同一个 `PCMPESTRI` chunk scanner，避免两条 direct helper 继续维护重复循环与索引逻辑。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 识别重复 scanner | completed | 两个 helper 只有 polarity / 空集合返回值不同，chunk loop 与 result 计算完全同构 |
| 2. 收口到共享 helper | completed | 新增 `FindFirstPcmpestri_SSE42`；`FindFirstOf` 走 positive polarity，`FindFirstNotOf` 走 negative polarity 并拒绝 chunk-boundary sentinel |
| 3. Release 验证与收口 | completed | `git diff --check`、`TTestCase_BackendSmoke`、`check`、`gate` 均已通过 |

## 2026-05-11 SSE4.1 Dword Multiply Kernel Consolidation

### Goal

把 `SSE4.1` 里 `PMULLD` 的 signed / unsigned 双份实现收成一个共享 kernel，同时清掉 `SSE4.1` 文件里残留的历史任务标记，让这段实现更像稳定后端，而不是演进日志。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 识别真实重复实现 | completed | `SSE41MulI32x4` 与 `SSE41MulU32x4` 使用同一条 `PMULLD` kernel，只有签名类型不同 |
| 2. 收口共享 kernel 并清理噪音 | completed | 两条 wrapper 已收进单一 shared kernel，`SSE4.1` 里的历史标记也已清掉 |
| 3. Release 验证与收口 | completed | `git diff --check`、`check`、`gate` 均已通过 |

## 2026-05-11 AVX2 Dword/Word Multiply Kernel Consolidation

### Goal

把 `AVX2` 里 `MulI32x4 / MulU32x4` 与 `MulI16x8 / MulU16x8` 的重复低位乘法实现收成单一 shared kernel，同时保留 typed wrapper 和 dispatch-owned 入口。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 识别真实重复实现 | completed | `I32x4/U32x4` 与 `I16x8/U16x8` 的 low-half multiply 只有类型签名不同，asm kernel 完全同构 |
| 2. 收口 shared kernel | completed | 新增 `AVX2MulDwordVecRaw` / `AVX2MulWordVecRaw`，typed wrapper 仍保持原 dispatch 入口 |
| 3. Release 验证与收口 | completed | `git diff --check`、`check`、`gate` 均已通过 |

## 2026-05-11 AVX2 128-bit Bitwise Kernel Consolidation

### Goal

把 `AVX2` 里 128-bit 整数向量的 `And / Or / Xor / Not / AndNot` 从 signed/unsigned、width-specific 的重复实现收成共享 raw kernel，保留原 dispatch 入口和类型签名。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 识别重复 bitwise bodies | completed | `I32x4/U32x4`、`I16x8/U16x8`、`I8x16/U8x16`、`I64x2/U64x2` 的 bitwise 语义完全同构 |
| 2. 收口共享 raw kernel | completed | 新增 `AVX2AndVecRaw` / `AVX2OrVecRaw` / `AVX2XorVecRaw` / `AVX2NotVecRaw` / `AVX2AndNotVecRaw`，所有 128-bit integer wrappers 改为 thin wrapper |
| 3. Release 验证与收口 | completed | `git diff --check`、`check`、`gate` 均已通过 |
