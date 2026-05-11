# SIMD Review Task Plan

## Goal

审查 `fafafa.core.simd` 当前结构、验证基线和成熟度边界，输出一份可直接执行的整改方案。

## Scope

- `src/fafafa.core.simd*`
- `tests/fafafa.core.simd*`
- `docs/fafafa.core.simd*`
- 相关 `docs/plans/*simd*`

## Phases

| Phase                               | Status    | Notes                                                                                                                                                             |
| ----------------------------------- | --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 建立审查上下文与工作台           | completed | 已切回当前 `main` worktree 真实状态，并接管 scratch 记录                                                                                                          |
| 2. 收集结构、测试、文档与 gate 证据 | completed | 已区分“假红基础设施问题”与 full test 暴露的真实实现缺陷                                                                                                           |
| 3. 提炼问题并按严重度排序           | completed | 当前真实优先级已更新为：SSE2 F64 IEEE754 rounding 语义缺陷 > façade alias 面继续收敛 > runtime snapshot 发布模型稳态化                                            |
| 4. 形成成熟整改方案                 | completed | 当前 Linux fast-gate 已重回绿态；接口挂接完整度为绿，剩余重点转为 release 级跨平台证据刷新，而非 simd stable surface 的新增接口缺口                               |
| 5. SIMD plan hygiene 与主链去干扰   | completed | `docs/plans/*simd*` 已明确分成 `active / historical / superseded`，并落下 `plan-status-index` 作为主入口                                                          |
| 6. Wave 2 active 实施计划补全       | completed | 已新增当前第一波 `seam hardening` active plan，把 `dispatch / dataplane / public ABI / direct / façade fast-path` 的边界、红线、baseline 和完成标准写成独立作战单 |

## Constraints

- 默认使用仓库现有脚本与文档，不做无审批的大规模架构改写
- 审查优先关注 stable surface、dispatch/cpuinfo 语义、非 x86 成熟度、验证闭环
- 若根目录 `task_plan.md/findings.md/progress.md` 与仓库约定冲突，优先使用 worktree-local scratch

## Errors Encountered

| Error                                                                           | Attempt | Resolution                                                                                     |
| ------------------------------------------------------------------------------- | ------- | ---------------------------------------------------------------------------------------------- |
| `mcp__ace_tool__search_context` 首次返回 499                                    | 1       | 缩窄查询后重试成功                                                                             |
| `CLAUDE_PLUGIN_ROOT` 未注入，无法直接调用 planning skill 辅助脚本               | 1       | 改为使用已知 skill 安装路径和 worktree-local scratch                                           |
| `BuildOrTest.sh test` 在 full suite 下 `rc=217`                                 | 1       | 已缩到并发/public ABI 与 IEEE754 两类真实失败，按最小失败面分治修复                            |
| `rg -n` 直接扫 IEEE754 testcase 输出过大                                        | 1       | 改为先定位具体 suite 名称与行号，再按区段读取                                                  |
| `gate` 最后一步 `run_all-chain` 失败                                            | 1       | 已定位为 `cpuinfo.x86` Windows batch runner success-criteria 合同缺口，修复后 `gate` 恢复 PASS |
| 批量给旧 `simd` plan 插入状态头时首次落到了文档尾部                             | 1       | 已去掉错误的跨行匹配方式，先清除误插入块，再把状态头重插到标题下                               |
| `check` 和 `gate` 并发编译同一 `tests/fafafa.core.simd` 输出目录导致临时 rc=2/1 | 1       | 改为串行重跑，确认不是代码回归                                                                 |
| 新增 `SSE2` length/normalize helper 后 `check` 报 inline hints                   | 1       | 去掉 `SSE2LengthWithOptionalZeroW` / `SSE2NormalizeByLength` 的 `inline` 标记后复验通过         |

## 2026-05-09 Subtask

### Goal

按既有方案把 SIMD 接口层收口落地：冻结 backend adapter / intrinsics leaf 口径，补三张真相表，并把 SSE2 归属护栏写进现有检查链。

### Phases

| Phase                       | Status    | Notes                                                                                                                                                               |
| --------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 复核当前主线与旧审查结论 | completed | 已按 `map -> maintenance -> handoff -> src/tests` 顺序回读，并确认当前 `SSE2` 真相仍在 `src/fafafa.core.simd.sse2.pas`                                              |
| 2. 补真相源文档与代码注释   | completed | 已新增 `SIMD_BACKEND_TRUTH.md`、`SIMD_INTRINSICS_DISPOSITION.md`、`SIMD_SSE2_MIGRATION_MAP.md`，并同步到 README/maintenance/interface/handoff/STABLE 与关键单元注释 |
| 3. 把归属判断落成机器护栏   | completed | `check_sse2_structure.py` 已扩展为同时检查 SSE2 文件结构、三张真相表、`simd.sse2 -> intrinsics.sse2` 反向依赖禁令，以及 `intrinsics.x86.sse2` 的 raw-leaf 边界      |
| 4. release 验证与提交收口   | completed | `check_sse2_structure.py`、`check_intrinsics_experimental_status.py`、`BuildOrTest.sh check`、`BuildOrTest.sh gate` 已通过；已完成 review + commit                  |

## 2026-05-09 Documentation Follow-up

### Goal

把“三层目标形态、为什么不是两层、实施时哪些职责能下沉/必须保留”写成正式裁决文档，避免后续实施时重新口头争论架构口径。

### Phases

| Phase                          | Status    | Notes                                                                                                                                                    |
| ------------------------------ | --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 抽出三层/两层争议的裁决问题 | completed | 已确认现有真相表能回答“谁是谁”，但还缺一页专门回答“为什么不是两层、后续怎么实施”的文档                                                                   |
| 2. 落地正式实施基线文档        | completed | 已把主文档重写成“3 个逻辑层 + 核心单元分类 + 4 种 intrinsics 状态 + 1 套依赖准入规则”的版本，不再混淆 namespace、SSE2 局部规则与全局规则                 |
| 3. 同步入口文档与 scratch 记录 | completed | `maintenance`、`disposition`、`migration map` 已补齐 `active leaf` 准入规则与 `experimental isolated` 禁入 stable adapter 的前提，且结构护栏验证继续通过 |

## 2026-05-09 Architecture Review Closure

### Goal

审查 `SIMD_LAYERING_IMPLEMENTATION.md` 是否已经足够“正确、优雅、全局”，并把遗漏的真实代码面补进正式架构口径，确保下一会话可直接按文档实施。

### Phases

| Phase                       | Status    | Notes                                                                                                               |
| --------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------- |
| 1. 对照真实代码面复核主文档 | completed | 已核对 `simd.pas`、`dispatch`、`direct`、`public_abi` include 与 `STABLE/publicabi/interface/maintenance` 文档      |
| 2. 补齐全局架构缺口         | completed | 已把 `public ABI wrapper` 与 `direct dispatch companion` 明确写入主设计文档和入口维护文档，不再让读者自行脑补       |
| 3. 结构验证与文档收口       | completed | `git diff --check`、`check_sse2_structure.py`、`check_intrinsics_experimental_status.py` 均通过；本轮文档收口可提交 |

## 2026-05-09 Publication Seam Closeout

### Goal

把整个 SIMD 模块视角下“最优雅终态”正式写进文档，并把 `dataplane` 从隐藏实现细节提升成显式的 `publication seam`，供下一次新会话直接按此实施。

### Phases

| Phase                          | Status    | Notes                                                                                                                                             |
| ------------------------------ | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 复核 `dataplane` 的真实职责 | completed | 已确认 `simd.pas` façade fast-path、`public_abi`、`direct` 都直接消费 `dataplane`，它已是共享 published binding seam                              |
| 2. 同步主设计与入口文档        | completed | 已把 `SIMD_LAYERING_IMPLEMENTATION`、`interface`、`maintenance`、`map`、`handoff`、`checklist`、`README`、`architecture`、`STABLE` 统一到同一口径 |
| 3. 轻量验证与提交收口          | completed | `git diff --check`、`check_sse2_structure.py`、`check_intrinsics_experimental_status.py` 已通过；待写 review 结论并提交                           |

## 2026-05-09 Whole-Module Refactor Pivot

### Goal

把本轮目标从 `SSE2-first` 的局部架构收口，升级成“整个 `fafafa.core.simd` 模块如何低冗余重构”的总纲，避免后续把某个 family 的迁移策略误当成全局架构。

### Phases

| Phase                           | Status    | Notes                                                                                                                                         |
| ------------------------------- | --------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别当前计划的局部性边界     | completed | 已确认 `SSE2` 方案适合作为高债务试点，但不足以覆盖 `AVX2/AVX-512/NEON/RISCVV` 等 family 的全局治理                                            |
| 2. 写出全模块统一终态与冗余定义 | completed | 已新增全局总纲，明确 `public/control surface -> seam -> companion -> adapter -> raw leaf` 的统一目标，并把“真相源/语义/入口/状态冗余”分开定义 |
| 3. 定义全 ISA 分组与波次        | completed | 已把 family 拆成正样板、高债务、adapter-only、opt-in experimental 四类，并把 `SSE2` 降级成 Wave 3 子计划                                      |
| 4. 把新总纲接入当前阅读入口     | completed | 已把全局总纲接入 `map`，并确认后续新会话可从全模块入口起盘                                                                                    |
| 5. 补 execution-ready 文档部件  | completed | 已新增 family matrix，并把总纲/source-of-truth 分工与 Wave exit criteria 补全                                                                 |
| 6. 补 family-level 子计划       | completed | 已新增 AVX2 正样板、x86 incremental qualification、NEON qualification、RISCVV qualification 四份文档，whole-module 计划不再卡在总纲层         |

## 2026-05-10 Wave 2 Seam Hardening Batch 1

### Goal

开始真正的 Wave 2 实施，先把 `public ABI wrapper` 从“独立 invalidate + 第二套 dispatch truth”收回成严格跟随 `dataplane` published snapshot 的 companion surface。

### Phases

| Phase                          | Status    | Notes                                                                                                                                                                                                                                                                                                           |
| ------------------------------ | --------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 锁定 Batch 1 边界           | completed | 这批只碰 `public_abi.impl.inc`、`simd.pas` 初始化/收尾接线、`dataplane` 相关测试；不打开 family migration，也不扩 runtime/cpuinfo 语义                                                                                                                                                                          |
| 2. public ABI 绑定语义收紧     | completed | `public ABI` 现在按 `PSimdDataPlane` 复用/发布 metadata table，不再维护独立 `target dispatch ptr`，也不再依赖独立 invalidate hook                                                                                                                                                                               |
| 3. fallback 语义收回 dataplane | completed | `PublicAbi*` cdecl wrapper 的兜底路径已从 `GetDispatchTable` 改成读取当前已发布 `dataplane` 槽位，消除第二条 publication path                                                                                                                                                                                   |
| 4. seam 回归验证与提交收口     | completed | `git diff --check`、Release `check`、`TTestCase_DataPlane`、`TTestCase_PublicAbi`、`TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework`、`TTestCase_DispatchAPI`、`TTestCase_RuntimeAPI`、`TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent`、`gate` 已通过；已完成 review + commit |

## 2026-05-11 Facade Dispatch Unification

### Goal

把 `src/fafafa.core.simd.pas` 里残留的 façade wrapper 统一收回到 `dataplane` 发布的 dispatch 读取路径，避免 façade 继续显式依赖第二套 dispatch getter 语义。

### Phases

| Phase                           | Status    | Notes                                                                                                                                                                                                                                                                                |
| ------------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1. 找出残留的直接 dispatch 读取 | completed | 已确认 `simd.pas` 里大量 façade wrapper 仍直接调用 `GetDispatchTable`，而不是显式读 `dataplane` published snapshot                                                                                                                                                                   |
| 2. 统一 façade wrapper 读取路径 | completed | 已将 `src/fafafa.core.simd.pas` 中所有 `GetDispatchTable` 调用统一替换为 `GetCurrentSimdDataPlaneDispatch`                                                                                                                                                                           |
| 3. 验证并继续扫残余重复实现     | completed | Release `check`、targeted seam suites、`gate` 已通过；`api` / `ops` / `arrays` 已统一到 `GetDirectDispatchTable`，下一步继续检查 runtime/cpuinfo/family 面是否还有可清理的重复 truth 或多重实现                                                                                      |
| 4. 继续扫剩余消费面             | completed | 已把 `GetDispatchTable` 直读收进 `dispatch-read-scope` 护栏；runtime 内部已去掉 `RegisteredFlags` 重复状态并收拢成共用 snapshot 读取 helper；cpuinfo legacy aliases 与 framework 转发层确认只是 compatibility thin shells；Wave 2 seam hardening 已完成，下一步进入 `Wave 3A / AVX2` |

## 2026-05-11 AVX2 Sample Noise Cleanup

### Goal

把 `AVX2` 样板里历史演进标记清掉，让文件读起来像稳定实现，而不是项目日志。

### Phases

| Phase            | Status    | Notes                                                                                                                                                                                                                         |
| ---------------- | --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 收敛注释噪音  | completed | 已清理 `src/fafafa.core.simd.avx2.pas` / `src/fafafa.core.simd.avx2.register.inc` 中的 `NEW / Iteration / milestone` 标记，保留真正的 section header 与语义注释                                                               |
| 2. 复验样板 lane | completed | `git diff --check`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_AVX2IntrinsicsFallback` 均通过 |
| 3. 继续 Wave 3A  | completed | 继续扫 AVX2 后没有再发现新的真重复实现；最后一块同构选择逻辑也已收成共享 raw helper                                                                                                                                           |

## 2026-05-11 AVX2 CmpEq Family Consolidation

### Goal

把 AVX2 里真实重复的 `CmpEq` 实现收回成按宽度共享的 raw helper，保留 typed thin wrappers 和 dispatch 入口，不去碰语义不同的 `Lt/Gt/Le/Ge/Ne`。

### Phases

| Phase                        | Status    | Notes                                                                                                                                 |
| ---------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别可合并的 Eq 重复簇    | completed | `I32x4/U32x4`、`I16x8/U16x8`、`I8x16/U8x16`、`I64x2/U64x2` 只是在相同宽度上重复了 compare + mask extraction；`F32/F64` 仍保持独立语义 |
| 2. 收回重复实现到 raw helper | completed | 已引入 dword/word/byte/qword width-specific compare helper，typed wrappers 只保留签名和 dispatch 入口                                 |
| 3. Release 验证与收口        | completed | `git diff --check`、Release `DispatchAPI/DirectDispatch`、`check`、`gate` 全部通过；待提交                                            |

## 2026-05-11 AVX2 256-bit CmpEq Consolidation

### Goal

把 AVX2 里 256-bit 的同宽 `CmpEq` 重复实现也收回成 shared raw helper，继续保留 typed wrapper / dispatch 入口，不碰 float compare 语义。

### Phases

| Phase                        | Status    | Notes                                                                                            |
| ---------------------------- | --------- | ------------------------------------------------------------------------------------------------ |
| 1. 识别 256-bit Eq 重复簇    | completed | `I32x8/U32x8`、`I64x4/U64x4` 只是同宽 compare + mask extraction 重复；`F32x8/F64x4` 保持独立语义 |
| 2. 收回重复实现到 raw helper | completed | 已引入 256-bit dword/qword compare helper，typed wrappers 只保留签名和 dispatch 入口             |
| 3. Release 验证与收口        | completed | `git diff --check`、Release `DispatchAPI/DirectDispatch`、`check`、`gate` 全部通过；待提交       |

## 2026-05-11 AVX2 Integer CmpNe Consolidation

### Goal

把 AVX2 整数 `CmpNe` 收成 `CmpEq` 反相的薄封装，保留浮点 `CmpNe` 独立语义，不再重复写一遍 compare + not + mask extraction。

### Phases

| Phase                         | Status    | Notes                                                                                                           |
| ----------------------------- | --------- | --------------------------------------------------------------------------------------------------------------- |
| 1. 识别可合并的整数 CmpNe 簇  | completed | `I32x4/U32x4`、`I16x8/U16x8`、`I8x16/U8x16`、`I64x2/U64x2`、`I32x8/U32x8`、`I64x4/U64x4` 都可直接由 Eq 反相得到 |
| 2. 收回重复实现到 Eq 反相薄壳 | completed | 已让整数 `CmpNe` 只做 mask 翻转，浮点 compare 不动                                                              |
| 3. Release 验证与收口         | completed | `git diff --check`、Release `check`、Release `gate` 全部通过；待提交                                            |

## 2026-05-11 AVX2 Integer Comparison Thin Wrapper Consolidation

### Goal

把 AVX2 整数 `CmpLt/CmpLe/CmpGe` 收成 `CmpGt` 交换参数/反相薄封装，保留 `CmpGt` 的真实比较语义和浮点 compare 独立实现，避免每个 family 再维护一份 compare + NOT + mask extraction。

### Phases

| Phase                                | Status    | Notes                                                                                                                                   |
| ------------------------------------ | --------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别可合并的整数 compare wrappers | completed | `I32x4/U32x4`、`I16x8/U16x8`、`I8x16/U8x16`、`I64x2/U64x2`、`I32x8/U32x8`、`I64x4/U64x4` 的 `CmpLt/CmpLe/CmpGe` 都只是 `CmpGt` 相关薄壳 |
| 2. 收回重复实现到 thin wrapper       | completed | 已让整数 `CmpLt/CmpLe/CmpGe` 统一退回交换参数或 `MASK_ALL_SET xor ...`，其中 `CmpGe` 也直接落到 `CmpGt(b, a)`，`CmpGt` 保持真比较语义   |
| 3. Release 验证与收口                | completed | `git diff --check`、Release `gate` 已通过；待提交                                                                                       |

## 2026-05-11 AVX2 I64x2 Min/Max Selection Consolidation

### Goal

把 `AVX2` 里 `I64x2/U64x2` 的 `Min/Max` lane selection 收成一个共享 raw helper，保留 compare 语义和 typed wrapper，不再维护四份同构的 lane-by-lane if/else。

### Phases

| Phase                  | Status    | Notes                                                                            |
| ---------------------- | --------- | -------------------------------------------------------------------------------- |
| 1. 识别重复选择逻辑    | completed | `MinI64x2 / MaxI64x2 / MinU64x2 / MaxU64x2` 都是同一段 mask 驱动的 lane 选择逻辑 |
| 2. 收回共享 raw helper | completed | 已新增 `AVX2SelectI64x2ByMaskRaw`，四个 wrapper 只保留各自 compare 语义和签名    |
| 3. 验证与收口          | completed | `git diff --check`、Release `gate` 已通过；待提交                                |

## 2026-05-11 X86 Incremental Noise Cleanup

### Goal

把 SSE3 / SSSE3 的历史注释噪音收掉，让 x86 incremental family 读起来一致、干净。

### Phases

| Phase            | Status    | Notes                                                                                                                                                                                                   |
| ---------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 收敛注释噪音  | completed | 已清理 `src/fafafa.core.simd.sse3.pas` / `src/fafafa.core.simd.sse3.register.inc` / `src/fafafa.core.simd.ssse3.pas` / `src/fafafa.core.simd.ssse3.register.inc` 中的 `NEW / Task 5.1 / milestone` 标记 |
| 2. 复验样板 lane | completed | `git diff --check`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check` 均通过                                                                                                 |
| 3. 继续 Wave 3B  | completed | 已确认 `SSSE3` 只保留 direct helper 兼容面，没有新的 owned duplicate override                                                                                                                           |

## 2026-05-11 X86 Incremental Redundancy Collapse

### Goal

把 `SSSE3` 上和 `SSE2` 完全重复的 `MinI8x16 / MaxI8x16` dispatch override 收回，让这条 family 保留真正增量和兼容别名，不再维护多一份同义实现。

### Phases

| Phase                | Status    | Notes                                                                                                  |
| -------------------- | --------- | ------------------------------------------------------------------------------------------------------ |
| 1. 识别重复实现      | completed | 已确认 `SSSE3MinI8x16 / SSSE3MaxI8x16` 只是 SSE2 compare+blend 的重复实现，并没有形成更强的 SSSE3 语义 |
| 2. 收回冗余 override | completed | dispatch table 已直接继承 `SSE3/SSE2` core slots，SSSE3 只保留 compatibility direct helpers            |
| 3. 验证与收口        | completed | `DispatchAPI`、Release `check`、`impl-smoke-x86`、`gate` 均已通过                                      |

## 2026-05-11 AVX2 Lane Helper Consolidation

### Goal

把 AVX2 里重复的 128-bit lane helper 选择/边界逻辑收回到单一 reference 实现，保留 AVX2-owned dispatch slot 与 capability 行为，不再在 backend 里重写同义代码。

### Phases

| Phase                    | Status    | Notes                                                                                                                          |
| ------------------------ | --------- | ------------------------------------------------------------------------------------------------------------------------------ |
| 1. 识别重复 lane helpers | completed | 已确认 `AVX2SelectF32x4 / AVX2ExtractF32x4 / AVX2InsertF32x4 / AVX2SelectF64x2` 与 scalar helper 只是重复的 lane 选择/边界逻辑 |
| 2. 收回 AVX2 重复实现    | completed | 这四个 wrapper 已委托给 scalar reference helper，dispatch ownership 保持不变                                                   |
| 3. Release 验证与收口    | completed | `git diff --check`、`check`、`TTestCase_DispatchAPI`、`gate` 均已通过，工作树只剩计划文件与源码变更                            |

## 2026-05-11 SSE2 Lane Helper Consolidation

### Goal

把 SSE2 里和 scalar 完全同构的 128-bit lane helper 收回到 reference 实现，保留 SSE2 的 dispatch-owned slot，不再重写同义的 select / extract / insert 边界逻辑。

### Phases

| Phase                    | Status    | Notes                                                                                                                                         |
| ------------------------ | --------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别重复 lane helpers | completed | 已确认 `SSE2SelectF32x4 / SSE2ExtractF32x4 / SSE2InsertF32x4` 与 scalar helper 只是重复的 lane 选择/边界逻辑                                  |
| 2. 收回 SSE2 重复实现    | completed | 这三个 wrapper 已委托给 scalar reference helper，dispatch ownership 保持不变                                                                  |
| 3. Release 验证与收口    | completed | `git diff --check`、`check`、`TTestCase_DispatchAPI`、`gate` 均已通过；`SSE2SelectF64x2` 与 wide-emulation 路径保持原样，因为它们并非同构重复 |

## 2026-05-11 SSE2 Wide Emulation Boundary Normalization

### Goal

把 `SSE2` wide-emulation 的 extract/insert 边界语义统一回 scalar clamp 规则，清掉那组 `index and N` 的 wrap-around 老实现，让 wide vector helper 和全模块其余路径保持一致。

### Phases

| Phase                 | Status    | Notes                                                                                                                      |
| --------------------- | --------- | -------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别边界语义漂移   | completed | 已确认 `SSE2.wide_emulation.inc` 里 18 个 wide extract/insert helper 都在用 wrap-around 索引，而 scalar/reference 走 clamp |
| 2. 统一边界语义       | completed | 这批 wide extract/insert 已改成直接委托 scalar reference helper，dispatch ownership 保持不变                               |
| 3. Release 验证与收口 | completed | `git diff --check`、`TTestCase_DispatchAPI,TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent`、`gate` 均已通过   |

## 2026-05-11 SSE4.1 Blend Kernel Consolidation

### Goal

把 `SSE4.1` 的 bitmask selection 收成单一 native blend kernel，避免 `SelectF32x4` 自己再维护一份 `blendvps` 序列。

### Phases

| Phase                  | Status    | Notes                                                                                |
| ---------------------- | --------- | ------------------------------------------------------------------------------------ |
| 1. 识别重复 blend 路径 | completed | `SSE41SelectF32x4` 与 `SSE41BlendVF32x4` 之前各自维护一份选择/混合逻辑               |
| 2. 收口到单一 kernel   | completed | `SSE41SelectF32x4` 现在只做 `TMask4 -> TMaskF32x4` 展开，然后委托 `SSE41BlendVF32x4` |
| 3. Release 验证与收口  | completed | `git diff --check`、`check`、`TTestCase_DispatchAPI`、`gate` 均已通过                |

## 2026-05-11 SSE4.2 String Helper Consolidation

### Goal

把 `SSE4.2` 的 `FindFirstOf_SSE42 / FindFirstNotOf_SSE42` 收回到同一个 `PCMPESTRI` chunk scanner，避免两条 direct helper 继续维护重复循环与索引逻辑。

### Phases

| Phase                 | Status    | Notes                                                                                                                                     |
| --------------------- | --------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别重复 scanner   | completed | 两个 helper 只有 polarity / 空集合返回值不同，chunk loop 与 result 计算完全同构                                                           |
| 2. 收口到共享 helper  | completed | 新增 `FindFirstPcmpestri_SSE42`；`FindFirstOf` 走 positive polarity，`FindFirstNotOf` 走 negative polarity 并拒绝 chunk-boundary sentinel |
| 3. Release 验证与收口 | completed | `git diff --check`、`TTestCase_BackendSmoke`、`check`、`gate` 均已通过                                                                    |

## 2026-05-11 SSE4.1 Dword Multiply Kernel Consolidation

### Goal

把 `SSE4.1` 里 `PMULLD` 的 signed / unsigned 双份实现收成一个共享 kernel，同时清掉 `SSE4.1` 文件里残留的历史任务标记，让这段实现更像稳定后端，而不是演进日志。

### Phases

| Phase                         | Status    | Notes                                                                           |
| ----------------------------- | --------- | ------------------------------------------------------------------------------- |
| 1. 识别真实重复实现           | completed | `SSE41MulI32x4` 与 `SSE41MulU32x4` 使用同一条 `PMULLD` kernel，只有签名类型不同 |
| 2. 收口共享 kernel 并清理噪音 | completed | 两条 wrapper 已收进单一 shared kernel，`SSE4.1` 里的历史标记也已清掉            |
| 3. Release 验证与收口         | completed | `git diff --check`、`check`、`gate` 均已通过                                    |

## 2026-05-11 AVX2 Dword/Word Multiply Kernel Consolidation

### Goal

把 `AVX2` 里 `MulI32x4 / MulU32x4` 与 `MulI16x8 / MulU16x8` 的重复低位乘法实现收成单一 shared kernel，同时保留 typed wrapper 和 dispatch-owned 入口。

### Phases

| Phase                 | Status    | Notes                                                                                     |
| --------------------- | --------- | ----------------------------------------------------------------------------------------- |
| 1. 识别真实重复实现   | completed | `I32x4/U32x4` 与 `I16x8/U16x8` 的 low-half multiply 只有类型签名不同，asm kernel 完全同构 |
| 2. 收口 shared kernel | completed | 新增 `AVX2MulDwordVecRaw` / `AVX2MulWordVecRaw`，typed wrapper 仍保持原 dispatch 入口     |
| 3. Release 验证与收口 | completed | `git diff --check`、`check`、`gate` 均已通过                                              |

## 2026-05-11 AVX2 128-bit Bitwise Kernel Consolidation

### Goal

把 `AVX2` 里 128-bit 整数向量的 `And / Or / Xor / Not / AndNot` 从 signed/unsigned、width-specific 的重复实现收成共享 raw kernel，保留原 dispatch 入口和类型签名。

### Phases

| Phase                      | Status    | Notes                                                                                                                                           |
| -------------------------- | --------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别重复 bitwise bodies | completed | `I32x4/U32x4`、`I16x8/U16x8`、`I8x16/U8x16`、`I64x2/U64x2` 的 bitwise 语义完全同构                                                              |
| 2. 收口共享 raw kernel     | completed | 新增 `AVX2AndVecRaw` / `AVX2OrVecRaw` / `AVX2XorVecRaw` / `AVX2NotVecRaw` / `AVX2AndNotVecRaw`，所有 128-bit integer wrappers 改为 thin wrapper |
| 3. Release 验证与收口      | completed | `git diff --check`、`check`、`gate` 均已通过                                                                                                    |

## 2026-05-11 RISCVV Facade Scalar Reference Consolidation

### Goal

把 `riscvv.facade.inc` 里与 scalar 完全同合同的 select / extract / insert fallback 收回到 `Scalar*` 真源，避免 RISCVV facade 再维护一份重复的边界和选择逻辑。

### Phases

| Phase                                   | Status    | Notes                                                                                                                                                                                     |
| --------------------------------------- | --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别可复用的 exact-contract fallback | completed | `SelectF32x4 / SelectF32x16 / SelectF64x8 / SelectF32x8(TVecU32x8) / SelectF64x2 / SelectF64x4(TVecU64x4) / SelectI32x4` 以及 exact extract / insert fallback 都可以直接复用 scalar truth |
| 2. 收回重复实现                         | completed | fallback bodies 已改为委托 `ScalarSelect* / ScalarExtract* / ScalarInsert*`，不再维护第二份 clamp / lane 选择真源                                                                         |
| 3. Release 验证与收口                   | completed | `git diff --check`、Release `gate`、`impl-audit-nonx86` 已通过                                                                                                                            |

## 2026-05-11 NEON Scalar Fallback Consolidation

### Goal

把 `NEON` non-ASM scalar fallback 里与 scalar 完全同合同的 lane / U64x2 helper 收回到 `Scalar*` 真源，避免 NEON fallback 再维护第二份标量边界、bitwise、compare、min/max 实现。

### Phases

| Phase                                   | Status    | Notes                                                                                                                                                                                                |
| --------------------------------------- | --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别可复用的 exact-contract fallback | completed | 已确认 `neon.scalar.utility.inc` 的 `SelectF32x4 / ExtractF32x4 / InsertF32x4 / SelectF64x2`、U64x2 exact fallback，以及 `neon.scalar.autowrap.inc` 的 `ExtractF64x2 / InsertF64x2` 都是同合同重复体 |
| 2. 收回重复实现并补 checker             | completed | exact fallback 已委托 `Scalar*`；`check_nonx86_helper_semantics.py` 已补 source-side 护栏                                                                                                            |
| 3. Release 验证与提交收口               | completed | `git diff --check`、non-x86 helper checker、Release `check`、`impl-audit-nonx86`、`gate` 全绿                                                                                                        |

## 2026-05-11 NEON Scalar Fallback Core Arithmetic Consolidation

### Goal

把 `NEON` non-ASM scalar fallback 开头那组基础算术 wrapper 收回到 `Scalar*` 真源，避免 `scalar_fallback.inc` 再维护一份逐 lane arithmetic loop。

### Phases

| Phase                       | Status    | Notes                                                                                                                           |
| --------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别基础算术重复体       | completed | 已确认 `NEONAdd/Sub/Mul/DivF32x4/F32x8/F64x2` 以及 `NEONAdd/Sub/MulI32x4` 都是与 `Scalar*` 完全同合同的逐 lane loop             |
| 2. 收回重复实现并补 checker | completed | `scalar_fallback.inc` 里的这批 wrapper 已全部改成直接委托 `Scalar*`，`check_nonx86_helper_semantics.py` 也补了 source-side 护栏 |
| 3. Release 验证与提交收口   | completed | `git diff --check`、`check_nonx86_helper_semantics.py --summary-line`、Release `check`、`impl-audit-nonx86`、`gate` 串行全绿    |

## 2026-05-11 Central SIMD Comment Noise Cleanup

### Goal

把中央 SIMD 源文件里残留的 `NEW / Task / Iteration / P*` 历史施工标记收掉，让 façade、dispatch、scalar reference 和 SSE2 register/wide-emulation 读起来像稳定代码，而不是批次日志；只改注释，不改变行为。

### Phases

| Phase                     | Status    | Notes                                                                                                                                                                           |
| ------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别中央注释噪音面     | completed | 已确认噪音主要集中在 `simd.pas`、`dispatch.pas`、`sse2.register.inc`、`sse2.wide_emulation.inc` 与 `scalar.pas`；其中前四个文件已完成清理，`scalar.pas` 因混合 CRLF/LF 单独延后 |
| 2. 收敛历史标记           | completed | 已移除前四个文件与 `scalar.pas` 里的 `NEW / Task / Iteration / P*` 标签、`✅` 标记和无意义 inline `Added` 注释；`scalar.pas` 采用改动行 LF 处理，避免整文件行尾噪音             |
| 3. Release 验证与提交收口 | completed | `git diff --check` 与 Release `check` 已通过                                                                                                                                    |

## 2026-05-11 SSE2 Root Comment Noise Cleanup

### Goal

清理 `src/fafafa.core.simd.sse2.pas` 里残留的历史施工标记，让 SSE2 backend adapter 的注释表达当前结构事实，而不是旧批次日志；本批只改注释，不物理拆分、不触碰 ASM leaf 或 dispatch wiring。

### Phases

| Phase               | Status    | Notes                                                                                                                  |
| ------------------- | --------- | ---------------------------------------------------------------------------------------------------------------------- |
| 1. 锁定稳定边界     | completed | 文档已明确 `sse2.pas` 是当前 SSE2 backend adapter truth source，适合注释清理和小范围 helper 审查，不适合无设计的大拆分 |
| 2. 收敛历史注释标记 | completed | 已移除 `✅ / NEW / P* / Task / Iteration / 2026-02-05` 这类历史痕迹，保留真实 safety/performance/ISA 说明              |
| 3. 验证与提交收口   | completed | `git diff --check`、`check_sse2_structure.py --summary-line` 与 Release `check` 已通过                                 |

## 2026-05-11 SSE2 Narrow Compare Thin Wrapper Consolidation

### Goal

把 `SSE2` 窄整型 `CmpLe/CmpGe/CmpNe` 从完整重复 ASM 体收回成围绕 `CmpGt/CmpEq` 的薄封装，保留当前 mask contract、dispatch-owned 入口和 `sse2.pas` 稳定边界。

### Phases

| Phase                 | Status    | Notes                                                                                                                  |
| --------------------- | --------- | ---------------------------------------------------------------------------------------------------------------------- |
| 1. 识别可收敛重复体   | completed | `I16x8/I8x16/U16x8/U8x16` 的 `Le/Ge/Ne` 都只是 `Gt/Eq` 结果按当前 mask 宽度反相；浮点比较和真实 `Eq/Gt` ASM 不纳入本批 |
| 2. 收回 thin wrapper  | completed | 12 个 wrapper 已改成 `MASK*_ALL_SET xor SSE2CmpGt/Eq...`，避免继续维护 `NOT + compare + pmovmskb` 的重复 ASM           |
| 3. Release 验证与收口 | completed | `git diff --check`、`NarrowIntegerOps`、`DispatchAPI`、Release `check`、Release `gate` 全部通过                        |

## 2026-05-11 SSE2 Integer Compare Thin Wrapper Completion

### Goal

把 `SSE2` 里剩余的整数比较家族继续收紧到统一模式：`Lt/Le/Ge/Ne` 全部只是 `Eq/Gt` 的薄封装，`I32x4/U32x4` 跟已完成的窄整型 family 保持一致，不再维护任何重复的 `Lt` ASM 体。

### Phases

| Phase                    | Status    | Notes                                                                                                                        |
| ------------------------ | --------- | ---------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别残余重复体        | completed | `I32x4/U32x4` 的 `Lt` 仍是完整 `pcmpgtd + movmskps` / sign-flip 体，和 `Gt(b,a)` 完全同合同；`Le/Ge/Ne` 也应继续保持薄壳风格 |
| 2. 收回剩余 thin wrapper | completed | `I32x4/U32x4` 的 `Lt` 已改成 `Gt(b,a)`，`Le/Ge/Ne` 统一成 `MASK4_ALL_SET xor ...`；比较家族现在只保留 `Eq/Gt` 为真实 ASM     |
| 3. Release 验证与收口    | completed | `git diff --check`、`NarrowIntegerOps`、`DispatchAPI`、`check`、`gate` 全部通过                                              |

## 2026-05-11 SSE2 128-bit Bitwise Kernel Consolidation

### Goal

把 `SSE2` active 128-bit 整数位运算从 signed/unsigned、lane-width-specific 的重复 ASM 体收成共享 raw kernel，保留 typed wrapper、dispatch 入口和 `sse2.pas` backend adapter 边界；同时清理未被 include 的旧 `i64x2_compare` 死文件。

### Phases

| Phase                      | Status    | Notes                                                                                                                                                                                           |
| -------------------------- | --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别重复 bitwise bodies | completed | `I32x4/U32x4`、`I16x8/U16x8`、`I8x16/U8x16` 与 active `I64x2` 的 `And/Or/Xor/Not/AndNot` 都是同一 128-bit bitwise 语义                                                                          |
| 2. 收口共享 raw kernel     | completed | 新增 `SSE2AndVecRaw` / `SSE2OrVecRaw` / `SSE2XorVecRaw` / `SSE2NotVecRaw` / `SSE2AndNotVecRaw`，typed wrappers 改为 thin wrapper                                                                |
| 3. 清理孤立旧实现          | completed | 删除未被任何 include 链引用的 `src/fafafa.core.simd.sse2.i64x2_compare.inc`，避免旧 scalar/compare 片段继续干扰架构判断                                                                         |
| 4. Release 验证与收口      | completed | `git diff --check`、`check_sse2_structure.py --summary-line`、`NarrowIntegerOps`、`DispatchAPI`、`check`、`gate` 已通过；删除孤立文件后已复验 `diff --check`、SSE2 structure 与 Release `check` |

## 2026-05-11 SSE2 Shift Raw Helper Consolidation

### Goal

把 `SSE2` 的 shift 家族收成共享 raw helper，让 128-bit typed wrapper 与 wide-emulation 256/512-bit wrapper 都复用同一套 `word / dword / qword` shift kernel，避免每个宽度 / signedness 再维护一遍 load-shift-store 体。

### Phases

| Phase                    | Status    | Notes                                                                                                                                       |
| ------------------------ | --------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别可合并的 shift 簇 | completed | `I16x8/I32x4/U16x8/U32x4` 与 `I32x8/I32x16/U32x8/U64x4/I64x4/I64x8` 的 shift 已确认只是同一批 128-bit chunk 逻辑在不同宽度上的重复展开      |
| 2. 收口共享 raw helper   | completed | 已新增 `SSE2Shift*WordVecRaw` / `SSE2Shift*DwordVecRaw` / `SSE2Shift*QwordVecRaw`，typed wrapper 与 wide-emulation 已统一复用               |
| 3. Release 验证与收口    | completed | `git diff --check`、`check_sse2_structure.py --summary-line`、`NarrowIntegerOps`、`DispatchAPI`、`DirectDispatch`、`check`、`gate` 全部通过 |

## 2026-05-11 RISCVV Integer MinMax Fallback Consolidation

### Goal

把 `RISCVV` non-ASM fallback 里与 scalar 完全同合同的整数 `Min/Max` 循环收回到 `ScalarMin/Max*` 真源；保留 RISCVV asm 路径和 register ownership，不把 backend-owned 槽位误降成 base scalar。

### Phases

| Phase                                   | Status    | Notes                                                                                                                                                |
| --------------------------------------- | --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别 exact-contract integer fallback | completed | 已确认 `U32x8/I16x8/I8x16/U16x8/U32x4/U8x16` 的 non-ASM `Min/Max` 都只是逐 lane 标量比较；浮点 `Min/Max` 因 IEEE754 NaN / signed-zero 语义不纳入本批 |
| 2. 收回 scalar truth                    | completed | 12 个 RISCVV non-ASM fallback wrapper 已改为直接委托对应 `ScalarMin/Max*`；真实 RVV asm `vmin/vmax/vminu/vmaxu` 实现保持不变                         |
| 3. Release 验证与收口                   | completed | `git diff --check`、`impl-smoke-nonx86`、`impl-audit-nonx86`、Release `check`、Release `gate` 全部通过                                               |

## 2026-05-11 RISCVV Facade Arithmetic/Bitwise/Compare Consolidation

### Goal

继续收 `RISCVV` non-ASM facade 里的 exact-contract 重复体，把 `I32x4 / I64x2 / I32x8 / U32x8` 这几组 arithmetic、bitwise、compare、min/max wrapper 统一收回 `Scalar*` 真源；保留 register ownership、asm path 和现有 non-x86 contract。

### Phases

| Phase                                      | Status    | Notes                                                                                                                                             |
| ------------------------------------------ | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别可继续收口的 exact-contract wrapper | completed | 已确认 `I32x4 / I64x2 / I32x8 / U32x8` 的 add/sub/mul/bitwise/compare/min/max fallback 仍是手写 lane loop，同合同 scalar 真源都已存在             |
| 2. 收回 scalar truth 并补 checker 护栏     | completed | `src/fafafa.core.simd.riscvv.facade.inc` 已改成直接委托 `Scalar*`；`check_nonx86_helper_semantics.py` 已补 source-side 断言，避免同合同循环壳回流 |
| 3. Release 验证与收口                      | completed | 已完成 `git diff --check`、non-x86 helper checker、`impl-smoke-nonx86`、`impl-audit-nonx86`、Release `check`、Release `gate`，结果全绿            |

## 2026-05-11 NEON Scalar Math/Utility Forwarder Consolidation

### Goal

继续收 `NEON` non-ASM scalar fallback 里与 `Scalar*` 完全同合同的基础 math / utility wrapper，把 `Splat / Abs / Sqrt / Fma / Rcp / Rsqrt` 这类重复逐 lane 体收回 scalar 真源；不触碰浮点 `Min/Max`、rounding、clamp 等 NaN / signed-zero 语义仍需单独证明的路径。

### Phases

| Phase                                        | Status    | Notes                                                                                                                                              |
| -------------------------------------------- | --------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别 exact-contract math/utility fallback | completed | 已确认 `NEONSplatF32x4`、`NEONAbs/SqrtF32x4`、`NEONFma/Rcp/RsqrtF32x4`、fallback-only wide `Abs/Fma` 都只是 scalar 真源的重复体                    |
| 2. 收回 scalar truth 并补 checker 护栏       | completed | `neon.scalar.utility/math/ext_math/autowrap.inc` 已改成直接委托 `Scalar*`；`check_nonx86_helper_semantics.py` 检查数提升至 176，锁住新增 forwarder |
| 3. Release 验证与收口                        | completed | `git diff --check`、`py_compile`、non-x86 helper checker、`impl-smoke-nonx86`、`impl-audit-nonx86`、Release `check`、Release `gate` 全部通过       |

## 2026-05-11 NEON Scalar Floor/Ceil Wide Forwarder Consolidation

### Goal

继续收 `NEON` non-ASM scalar fallback 里宽向量 `Floor/Ceil` 的 exact-contract wrapper，把 `F32x8 / F32x16 / F64x4 / F64x8` 这几组从手写逐 lane 体收回 scalar 真源；`F32x4 / F64x2`、`Round/Trunc`、`Clamp` 仍保留为后续单独证明的语义敏感路径。

### Phases

| Phase                                           | Status    | Notes                                                                                                                                        |
| ----------------------------------------------- | --------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别 exact-contract wide floor/ceil fallback | completed | 已确认 `NEONFloor/CeilF32x8/F32x16/F64x4/F64x8` 都只是和 `ScalarFloor/Ceil*` 同合同的 guard+round wrapper                                    |
| 2. 收回 scalar truth 并补 checker 护栏          | completed | `neon.scalar.autowrap.inc` 已改成直接委托 `ScalarFloor/Ceil*`；`check_nonx86_helper_semantics.py` 已补 8 条 source-side 断言                 |
| 3. Release 验证与收口                           | completed | `git diff --check`、`py_compile`、non-x86 helper checker、`impl-smoke-nonx86`、`impl-audit-nonx86`、Release `check`、Release `gate` 全部通过 |

## 2026-05-11 SSSE3 Raw-Leaf Wording Harmonization

### Goal

把 `SSSE3` 在 active x86 文档里的口径统一成 `adapter-only`，不再把不存在的 dedicated raw leaf target 写成待补项。

### Phases

| Phase                   | Status    | Notes                                                                                                                                        |
| ----------------------- | --------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 找出冲突表述         | completed | `execution index` / `global architecture plan` 曾把 `SSSE3` 写成待补 raw-leaf target，而 `family matrix` 已明确它是 adapter-only in practice |
| 2. 统一 active 文档口径 | completed | x86 plan、execution index、global plan 与 family matrix 已统一成 `adapter-only / no dedicated raw leaf target`                               |
| 3. 验证与收口           | completed | `rg` 复核不再有 active-doc 冲突，`git diff --check` 通过；同时清掉 execution index 里过期的 `Wave 2` 未开始表述                              |

## 2026-05-11 SSE2 Retire Target Baseline

### Goal

把 `SSE2` 的 retire bucket 冻结说明写成正式文档，明确哪些对象永远留在 adapter，哪些对象只有在 raw leaf 迁移证据齐全后才可能进入 C 桶。

### Phases

| Phase                          | Status    | Notes                                                                                                                                               |
| ------------------------------ | --------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别当前 retire 口径        | completed | `SSE2` 迁移图已经把 A/B/C 桶写死，但还缺一份专门冻结 retire baseline 的 closeout 文档                                                               |
| 2. 落地 retire target baseline | completed | 已新增 `docs/plans/2026-05-09-simd-sse2-retire-target-plan.md`，并接入 active chain、execution index、global plan、family matrix 与 migration map   |
| 3. 验证与收口                  | completed | `prettier --write`、`git diff --check`、`check_sse2_structure.py --summary-line`、`check_intrinsics_experimental_status.py --summary-line` 全部通过 |

## 2026-05-11 Experimental Hold Future Trigger Baseline

### Goal

把 `AES / SHA / AVX / FMA3 / SVE / SVE2 / LASX` 的 hold 规则写成统一的 future-trigger baseline，避免后续靠临场判断决定这些 experimental family 什么时候值得重开。

### Phases

| Phase                           | Status    | Notes                                                                                                                                               |
| ------------------------------- | --------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别 hold 家族               | completed | 当前需要冻结 future-trigger 规则的家族已经在 active plans 里写清：`AES / SHA / AVX / FMA3 / SVE / SVE2 / LASX`                                      |
| 2. 落地 future-trigger baseline | completed | 已新增 `docs/plans/2026-05-09-simd-experimental-hold-future-trigger-plan.md` 并接入 active 入口                                                     |
| 3. 验证与收口                   | completed | `prettier --write`、`git diff --check`、`check_sse2_structure.py --summary-line`、`check_intrinsics_experimental_status.py --summary-line` 全部通过 |

## 2026-05-11 X86 Raw Parity Baseline

### Goal

把 `SSE3 / SSE4.1 / SSE4.2 / AVX-512` 的 representative parity 口径单独落成 baseline，让 `Wave 3C` 的职责收回到 qualification，而不是继续把 parity 决策散在 smoke 叙述里。

### Phases

| Phase                      | Status    | Notes                                                                                                                                                                             |
| -------------------------- | --------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别 shared parity 口径 | completed | 已确认这组 family 需要共享 raw parity baseline，而不是继续按“只有 smoke 看起来绿”来判断                                                                                           |
| 2. 接入 active 文档链      | completed | 已新增 `docs/plans/2026-05-09-simd-x86-raw-parity-plan.md`，并接入 `plan-status-index`、`execution-index`、`global plan`、`family matrix` 与 `x86 incremental qualification plan` |
| 3. 验证与收口              | completed | `git diff --check`、`check_sse2_structure.py --summary-line`、`check_intrinsics_experimental_status.py --summary-line` 全部通过                                                   |

## 2026-05-11 NEON Scalar Vector Math Forwarder Consolidation

### Goal

把 `NEON` non-ASM scalar fallback 里的 `Dot / Cross / Length / Normalize` vector-math 重复体收回到 `Scalar*` 真源；保留 ARM64 asm 实现和 register ownership，不把语义敏感的 rounding / clamp / native compare 路径混进本批。

### Phases

| Phase                                       | Status    | Notes                                                                                                                                                |
| ------------------------------------------- | --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别 exact-contract vector-math fallback | completed | 已核对 `ScalarDot/Cross/Length/NormalizeF32x3/F32x4` 与原 `neon.scalar.vector_math.inc` non-ASM fallback 同合同，包括 `NormalizeF32x3` 的 `w=0` 语义 |
| 2. 收回 scalar truth 并补 checker 护栏      | completed | `src/fafafa.core.simd.neon.scalar.vector_math.inc` 已改为直接委托 `Scalar*`，`check_nonx86_helper_semantics.py` 检查数提升至 191                     |
| 3. Release 验证与收口                       | completed | `git diff --check`、helper checker、`impl-smoke-nonx86`、`impl-audit-nonx86`、Release `check`、Release `gate` 全部通过                               |

## 2026-05-11 AVX2 256-bit Dword Shared Kernel Consolidation

### Goal

把 `AVX2` 里 `I32x8/U32x8` 的 `Add/Sub/Mul/And/Or/Xor/Not/AndNot/ShiftLeft/ShiftRight(logical)` 重复体收回共享 dword raw helper；保留 signed/unsigned 比较、`Min/Max` 与 arithmetic right shift 的独立语义，不动 dispatch / register ownership。

### Phases

| Phase                                     | Status    | Notes                                                                                                 |
| ----------------------------------------- | --------- | ----------------------------------------------------------------------------------------------------- |
| 1. 识别可安全合并的 dword repeaters       | completed | 只收位语义同构的 arithmetic / bitwise / logical shift；`Cmp*`、`Min/Max`、`ShiftRightArithI32x8` 不动 |
| 2. 落地 shared raw helper 并收口 wrappers | completed | `avx2.i32x8_family.inc` 新增 256-bit dword raw kernels，`I32x8/U32x8` 入口改为薄封装                  |
| 3. Release 验证与收口                     | completed | `git diff --check`、Release targeted suite、Release `check`、Release `gate` 全部通过                  |

## 2026-05-11 AVX2 256-bit Qword Shared Kernel Consolidation

### Goal

把 `AVX2` 里 `I64x4/U64x4` 的 `Add/Sub/And/Or/Xor/Not/ShiftLeft/ShiftRight(logical)` 重复体收回共享 qword raw helper；保留 compare / min-max / 语义敏感边界不动，继续维持 dispatch / register ownership。

### Phases

| Phase                                     | Status    | Notes                                                                                                                                                          |
| ----------------------------------------- | --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别可安全合并的 qword repeaters       | completed | `I64x4/U64x4` 的算术、bitwise、logical shift 都是同一条 qword 位语义的 exact-contract 重复体                                                                   |
| 2. 落地 shared raw helper 并收口 wrappers | completed | `avx2.i32x8_family.inc` 新增 `AVX2*QwordVecRaw256`，`src/fafafa.core.simd.avx2.pas` 里的 `I64x4/U64x4` 入口已改成薄封装                                        |
| 3. Release 验证与收口                     | completed | `git diff --check`、Release targeted suite、Release `check`、Release `gate` 全部通过；`check` 首次并发起跑失败是和 `gate` 争同一输出目录，串行重跑后已恢复正常 |

## 2026-05-11 AVX2 128-bit Arithmetic/Shift Shared Kernel Consolidation

### Goal

把 `AVX2` 里剩余的 128-bit 整数 `Add/Sub/ShiftLeft/ShiftRight(logical)` 重复体继续收回共享 raw helper：`I32x4/U32x4`、`I16x8/U16x8` 的加减和逻辑移位，以及 `I8x16/U8x16` 的加减；保留 `ShiftRightArith*`、`Cmp*`、`Min/Max` 的独立语义，不动 dispatch / register ownership。

### Phases

| Phase                                                  | Status    | Notes                                                                                                                                                                             |
| ------------------------------------------------------ | --------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别可安全合并的 128-bit arithmetic/shift repeaters | completed | `I32x4/U32x4`、`I16x8/U16x8`、`I8x16/U8x16` 的 add/sub 以及 dword/word logical shift 都是 exact-contract 重复体                                                                   |
| 2. 落地 shared raw helper 并收口 wrappers              | completed | `src/fafafa.core.simd.avx2.pas` 已新增 dword/word/byte add-sub raw helper 和 dword/word shift raw helper，相关 typed wrapper 已改成薄封装                                         |
| 3. Release 验证与收口                                  | completed | `git diff --check`、`TTestCase_NarrowIntegerOps`、`TTestCase_AVX2VectorAsm`、`TTestCase_DispatchAPI`、`TTestCase_DirectDispatch`、`TTestCase_DataPlane`、`check`、`gate` 全部通过 |

## 2026-05-11 SIMD Active Plan Status Sync

### Goal

把 `execution-index` / `global architecture plan` 的当前波次状态同步到最新代码事实，避免后续会话继续从过期的 `Wave 3C / Wave 4A / Wave 4B` 默认起手。

### Phases

| Phase                                | Status    | Notes                                                                                                                           |
| ------------------------------------ | --------- | ------------------------------------------------------------------------------------------------------------------------------- |
| 1. 复核当前 code queue 与 plan queue | completed | 重新核对 git log、scratch 记录与 active plans，确认 Wave 4 主要 code batches 已落地，默认执行队列应切到 Wave 5                  |
| 2. 修正 active plan 状态文档         | completed | 已同步更新 `docs/plans/2026-05-10-simd-execution-index.md` 与 `docs/plans/2026-05-09-simd-global-architecture-refactor-plan.md` |
| 3. 记录下一步收口方向                | completed | 当前不再继续开新代码 batch；后续要么进入 Wave 5 的 evidence-backed cleanup，要么等 fresh red 再回到 family plan                 |

## 2026-05-11 SIMD Family Decision Baseline

### Goal

把剩下的 family-level `promote / hold / future-trigger` 决策冻结成单页基线，避免后续每次都从 `family matrix` 重新口头讨论。

### Phases

| Phase                                    | Status    | Notes                                                                                                                                                              |
| ---------------------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1. Consolidate remaining decision gaps   | completed | 新增 `docs/plans/2026-05-11-simd-family-decision-baseline.md`，把 x86 qualification、non-x86 qualification、experimental hold 的默认判断一次性冻住                 |
| 2. Sync active indexes and family matrix | completed | 已把新基线接入 `docs/plans/2026-05-10-simd-plan-status-index.md`、`docs/plans/2026-05-10-simd-execution-index.md` 与 `docs/plans/2026-05-09-simd-family-matrix.md` |
| 3. Verify docs hygiene                   | completed | `npx prettier --write` 与 `git diff --check` 通过；本批只动文档，没有触碰源码                                                                                      |

## 2026-05-11 AVX512 Placeholder Helper Consolidation

### Goal

把 `src/fafafa.core.simd.intrinsics.avx512.pas` 里 `load / loadu / store / storeu / set1 / add / sub / mul / div / mask_add / maskz_add` 的重复循环收成单一内部 helper，保留 experimental placeholder 语义与初始化门控，不扩大公开 surface。

### Phases

| Phase                                     | Status    | Notes                                                                                          |
| ----------------------------------------- | --------- | ---------------------------------------------------------------------------------------------- |
| 1. 识别可合并的 placeholder repeaters     | completed | 这 11 个函数只是同宽 `TM512` 浮点循环的不同 load/store / op / mask 变体                     |
| 2. 落地局部 helper 收口                  | completed | 已新增 `AVX512LoadF32x16`、`AVX512StoreF32x16`、`AVX512SetF32x16`、`AVX512ApplyF32x16Binary`、`AVX512ApplyF32x16MaskAdd`，公开函数薄封装 |
| 3. Release / experimental 验证与收口      | completed | `git diff --check`、`tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh check`、Release `check`、Release `gate` 全部通过 |

## 2026-05-11 Generic Intrinsics Load/Set Helper Consolidation

### Goal

把 `src/fafafa.core.simd.intrinsics.pas` 里 `load / loadu / store / storeu / set1_epi32 / set1_epi16 / set1_epi8` 的 placeholder 重复体收成文件内 helper，同时把该文件的混合换行整理成 LF；本批不碰 compare / min-max / shift / floating math。

### Phases

| Phase                                   | Status      | Notes                                                                                         |
| --------------------------------------- | ----------- | --------------------------------------------------------------------------------------------- |
| 1. 识别安全重复体                       | completed   | `load/loadu`、`store/storeu` 是 identical body；`set1_epi*` 只是不同 lane 宽度的重复填充值逻辑 |
| 2. 落地局部 helper 与换行清理           | completed   | 已新增 `SIMDLoadTM128` / `SIMDStoreTM128` 与 `SIMDSetTM128I*` helper，并把文件整理成 LF         |
| 3. Release / experimental 验证与提交收口 | completed   | `git diff --check`、experimental check、Release `check`、Release `gate` 已通过；runtime getter fallback 红点已在独立收口批次中解决 |

## 2026-05-11 Runtime Getter Snapshot Fallback Closure

### Goal

修复 `GetCurrentBackendInfo` / dispatchable helper 在并发 `RegisterBackend` 或 vector-asm toggle 下仍可能走直接 fallback、返回非同代 runtime state 的问题；所有 runtime/control-plane getter fallback 都必须回到 `GetCurrentRuntimeSnapshot`。

### Phases

| Phase                                   | Status      | Notes                                                                                                  |
| --------------------------------------- | ----------- | ------------------------------------------------------------------------------------------------------ |
| 1. 复现 gate 红点                       | completed   | Release `gate` 在 `TTestCase_SimdConcurrentFramework` 抓到 `current backend info` 与 `dispatchable helper` mixed snapshot |
| 2. 收紧 runtime getter fallback         | completed   | `GetCurrentBackend*`、registered/dispatchable list、best dispatchable backend 的 fallback 已统一回到 `GetCurrentRuntimeSnapshot` |
| 3. Targeted 并发验证                    | completed   | `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentFramework` 通过 |
| 4. Full release gate 收口               | completed   | Release `check` 与 Release `gate` 已复跑通过，runtime getter fallback 收口已被全链路门禁确认绿态       |

## 2026-05-11 AVX Placeholder Helper Consolidation

### Goal

把 `src/fafafa.core.simd.intrinsics.avx.pas` 里 `load / loadu / store / storeu / set1_ps / set1_pd` 和纯占位 `cmp / blend / shuffle / permute / unpack / testz / testc / testnzc / extract / insert` 收成文件内 helper，继续保持 experimental placeholder 语义，不扩大公开 surface。

### Phases

| Phase                             | Status      | Notes                                                                                                         |
| --------------------------------- | ----------- | ------------------------------------------------------------------------------------------------------------- |
| 1. 识别安全重复体                 | completed   | `load/loadu`、`store/storeu`、`set1_ps/set1_pd` 以及一组纯占位 return 体都是同合同重复体                    |
| 2. 落地文件内 helper 收口         | completed   | 已新增 `AVXLoadTM256`、`AVXStoreTM256`、`AVXSetTM256F32/F64`、`AVXCopyTM256`、`AVXExtractF128TM128`、`AVXInsertF128TM256` |
| 3. Release / experimental 验证收口 | completed   | `git diff --check`、experimental `check`、Release `check`、Release `gate` 全部通过                         |

## 2026-05-11 SSE3/SSE41 Experimental Intrinsics Cleanup

### Goal

修掉 `sse3` / `sse41` 里真实的 comment-swallow 与逻辑残缺点，把 `loaddup / dp / round / insert` 的实验性回归补齐到最小可验证集合，不扩大 scope，不改公开面。

### Phases

| Phase                               | Status    | Notes                                                                                                  |
| ----------------------------------- | --------- | ------------------------------------------------------------------------------------------------------ |
| 1. 修复源码里的真实残缺             | completed | `sse3_loaddup_pd` 恢复实际加载；`sse41_dp_pd`、`sse41_round_ps`、`sse41_insert_ps` 去掉 comment-swallow / 缺失逻辑 |
| 2. 补最小 x86 实验性回归            | completed | 新增 `TTestCase_SimdIntrinsicsExperimentalX86`，覆盖 `sse3_loaddup_pd` / `sse41_dp_pd` / `sse41_round_ps` / `sse41_insert_ps` |
| 3. Release 验证与收口               | completed | experimental `check`、`test --suite=TTestCase_SimdIntrinsicsExperimentalX86`、Release `check`、Release `gate` 全通过 |

## 2026-05-11 SSE4.1 Rounding Helper Consolidation

### Goal

把 `sse41_round_ps / sse41_round_pd / sse41_round_ss / sse41_round_sd` 的重复 rounding case 收成单一私有 helper，同时保留现有 placeholder 语义与 lane ownership，不碰其他 SSE4.1 路径。

### Phases

| Phase                     | Status    | Notes                                                                                                              |
| ------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------ |
| 1. 识别重复 rounding case  | completed | 4 个 rounding wrapper 共享同一套 `round / Int` case 分支，只是 lane width 和 preserve pattern 不同                 |
| 2. 落地私有 helper 与回归  | completed | 新增 `SSE41RoundScalar`，`round_ps/pd/ss/sd` 改为直调，并补了 `round_pd` / `round_ss` / `round_sd` 回归          |
| 3. Release 验证与收口     | completed | `git diff --check`、experimental `check`、`test --suite=TTestCase_SimdIntrinsicsExperimentalX86`、Release `check`、Release `gate` 全通过 |

## 2026-05-11 SSE4.1 Conversion Helper Consolidation

### Goal

把 `sse41_cvtepi8_epi16 / cvtepi8_epi32 / cvtepi8_epi64 / cvtepi16_epi32 / cvtepi16_epi64 / cvtepi32_epi64` 与对应 `cvtepu*` 的重复扩展 loop 收成少量私有 helper，同时保留现有 placeholder 语义和 lane ownership，不碰其他 `SSE4.1` 路径。

### Phases

| Phase                    | Status    | Notes                                                                                                                          |
| ------------------------ | --------- | ------------------------------------------------------------------------------------------------------------------------------ |
| 1. 识别扩展重复体        | completed | signed / unsigned 的 lane 扩展 loop 只是目标宽度不同，结构上完全同构                                                          |
| 2. 落地私有 helper 与回归 | completed | 新增 `SSE41ExtendSigned*` / `SSE41ExtendUnsigned*` helpers，并补了 `Test_SSE41_ConvertExtends_SignedAndUnsigned` 回归 |
| 3. Release 验证与收口    | completed | `git diff --check`、experimental `check`、`test --suite=TTestCase_SimdIntrinsicsExperimentalX86`、Release `check`、Release `gate` 全通过 |

## 2026-05-11 SSE4.1 Min/Max Helper Consolidation

### Goal

把 `sse41_max_epi8 / max_epi32 / max_epu16 / max_epu32` 与对应 `min_*` 的重复逐 lane 选择 loop 收成类型专属私有 helper，同时保留 experimental placeholder 语义、signed/unsigned contract 和公开函数名。

### Phases

| Phase                    | Status    | Notes                                                                                                                  |
| ------------------------ | --------- | ---------------------------------------------------------------------------------------------------------------------- |
| 1. 识别 min/max 重复簇   | completed | 八个 wrapper 只在 lane type 与 `>` / `<` 方向上不同，属于 exact-contract duplicate                                     |
| 2. 落地私有 helper 与回归 | completed | 新增 `SSE41MinMaxI8x16/I32x4/U16x8/U32x4`，并补 `Test_SSE41_MinMax_SignedAndUnsigned` |
| 3. Release 验证与收口    | completed | `git diff --check`、experimental `check`、targeted experimental suite、Release `check`、Release `gate` 全通过            |

## 2026-05-11 SSE4.1 Blend Helper Consolidation

### Goal

把 `sse41_blend_ps / blend_pd / blendv_ps / blendv_pd / blendv_epi8` 的重复 lane selection 收成私有 helper，同时保留 imm8 / sign-bit mask contract 和公开函数名，不改其它 SSE4.1 路径。

### Phases

| Phase                        | Status    | Notes                                                                                                   |
| ---------------------------- | --------- | ------------------------------------------------------------------------------------------------------- |
| 1. 识别 blend 重复簇         | completed | `blend_ps/pd` 与 `blendv_ps/pd/epi8` 都是同合同 lane selection 重复体，只是 mask 来源和 lane 宽度不同 |
| 2. 落地私有 helper 与回归     | completed | 新增 `SSE41BlendF32x4/F64x2/VF32x4/VF64x2/VE8x16`，并补 `Test_SSE41_Blend_ImmediateAndVariableMasks` |
| 3. Release 验证与收口        | completed | `git diff --check`、experimental `check`、targeted experimental suite、Release `check`、Release `gate` 全通过 |

## 2026-05-11 SSE4.1 Insert/Extract Lane Clamp Consolidation

### Goal

把 `SSE41InsertF32x4 / SSE41ExtractF32x4` 共享的 lane clamp 收成单一私有 helper，并补上 SSE4.1 代表性 parity，保留现有 insert/extract contract 和 dispatch 签名，不碰长度 / 归一化路径。

### Phases

| Phase                         | Status    | Notes                                                                                       |
| ----------------------------- | --------- | ------------------------------------------------------------------------------------------- |
| 1. 识别重复 clamp 逻辑        | completed | `InsertF32x4` 与 `ExtractF32x4` 共享同一段 lane index saturation / clamp 逻辑              |
| 2. 落地私有 helper 与回归     | completed | 新增 `SSE41ClampF32x4Index`，并把 `Test_SSE41_RepresentativeSemanticParity_WithScalar_IfDispatchable` 补进 insert/extract parity |
| 3. Release 验证与收口        | completed | `git diff --check`、`TTestCase_DispatchAPI`、Release `check`、Release `gate` 全通过        |

## 2026-05-11 SSE4.1 Normalize Helper Consolidation

### Goal

把 `SSE41NormalizeF32x4 / SSE41NormalizeF32x3` 共享的 length-divide 和 zero-vector fallback 收成单一私有 helper，保留 `F32x3` 清零 `w` lane 的 contract，不改 dispatch 签名、不碰 length 计算路径。

### Phases

| Phase                         | Status    | Notes                                                                                          |
| ----------------------------- | --------- | ---------------------------------------------------------------------------------------------- |
| 1. 识别重复 normalize body    | completed | 两个 wrapper 都是先计算 length，再按 length 分支做向量除法或 zero-vector fallback               |
| 2. 落地私有 helper 收口       | completed | 新增 `SSE41NormalizeByLength`，`F32x4/F32x3` wrapper 只保留 length source 和 `w` lane policy |
| 3. Release 验证与收口         | completed | `git diff --check`、`TTestCase_DispatchAPI`、Release `check`、Release `gate` 全通过             |

## 2026-05-11 AVX2 Normalize Helper Consolidation

### Goal

把 `AVX2LengthF32x4 / AVX2LengthF32x3` 与 `AVX2NormalizeF32x4 / AVX2NormalizeF32x3` 的重复 length-divide / zero-w 逻辑收成两个私有 helper，保留 `F32x3` 的 `w=0` contract，不改 dispatch 签名。

### Phases

| Phase                        | Status    | Notes                                                                                          |
| ---------------------------- | --------- | ---------------------------------------------------------------------------------------------- |
| 1. 识别重复 length/normalize | completed | `LengthF32x4/F32x3` 与 `NormalizeF32x4/F32x3` 共享同一套 zero-w + sqrt/divide 控制流         |
| 2. 落地私有 helper 收口       | completed | 新增 `AVX2LengthWithOptionalZeroW` 与 `AVX2NormalizeByLength`，四个 wrapper 变成 thin shell |
| 3. Release 验证与收口         | completed | `git diff --check`、`TTestCase_AVX2VectorAsm`、Release `check`、Release `gate` 全通过        |

## 2026-05-11 SSE3 Normalize Helper Consolidation

### Goal

把 `SSE3LengthF32x4 / SSE3LengthF32x3` 与 `SSE3NormalizeF32x4 / SSE3NormalizeF32x3` 的重复 zero-w / length / divide 控制流收成两个私有 helper，保留 SSE3 backend-owned slot 和现有 `F32x3` 清零合同。

### Phases

| Phase                        | Status    | Notes                                                                                          |
| ---------------------------- | --------- | ---------------------------------------------------------------------------------------------- |
| 1. 识别重复 length/normalize | completed | SSE3 的 length/normalize 与 AVX2/SSE4.1 同属 exact-contract helper consolidation               |
| 2. 落地私有 helper 收口       | completed | 新增 `SSE3LengthWithOptionalZeroW` 与 `SSE3NormalizeByLength`，wrapper 只保留 length source 和 `w` policy |
| 3. Release 验证与收口         | completed | `git diff --check`、`TTestCase_DispatchAPI,TTestCase_DirectDispatch`、Release `check`、Release `gate` 全通过 |

## 2026-05-11 SSE2 F32 Vector Math Helper Consolidation

### Goal

把 `SSE2` 的 F32 length / normalize 重复 body 收成单一私有 helper，补上 SSE2 代表性 normalize / zero-vector parity，并清理未被构建引用的 `sse2.vector_math.inc` 镜像文件。

### Phases

| Phase                         | Status    | Notes                                                                                                                                              |
| ----------------------------- | --------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别重复 length/normalize  | completed | `LengthF32x4/F32x3` 与 `NormalizeF32x4/F32x3` 只是 zero-w / length / divide 的重复 body                                                           |
| 2. 落地私有 helper 收口       | completed | 新增 `SSE2LengthWithOptionalZeroW` 与 `SSE2NormalizeByLength`，四个 wrapper 只保留 length source 和 `w` policy                                   |
| 3. 补 SSE2 parity 证据        | completed | `DispatchAPI` 现在直接覆盖 `LengthF32x4/F32x3`、`NormalizeF32x4/F32x3`、zero-vector 和 `F32x3 w=0` 语义                                        |
| 4. 清理死镜像与 release 验证   | completed | 删除未被任何 `include` 引用的 `src/fafafa.core.simd.sse2.vector_math.inc`；`git diff --check`、`check`、`gate` 均通过                              |

## 2026-05-11 NEON Scalar Memory/Reduction Forwarder Consolidation

### Goal

把 `src/fafafa.core.simd.neon.scalar.memory.inc` 里 `F32x4` 的 load/store，以及 `src/fafafa.core.simd.neon.scalar.reduction.inc` 里 `F32x4` 的 `ReduceAdd/ReduceMul` 收回 `Scalar*` 真源；保留 `ReduceMin/ReduceMax` 和整数 reduction 的 local 实现，不碰语义敏感路径。

### Phases

| Phase                   | Status      | Notes                                                                                           |
| ----------------------- | ----------- | ----------------------------------------------------------------------------------------------- |
| 1. 识别可安全收口的薄壳 | completed   | `Load/Store F32x4` 与 `ReduceAdd/ReduceMul F32x4` 都是 exact-contract 的重复壳                |
| 2. 落地 scalar forwarder | completed   | `neon.scalar.memory.inc` 与 `neon.scalar.reduction.inc` 已改为直调 `Scalar*` 真源，并补 checker |
| 3. Release 验证与收口   | completed   | `git diff --check`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 全绿  |

## 2026-05-12 Public ABI Dataplane Doc Guard

### Goal

把 active public ABI 文档里的旧 `dispatch table fallback` 口径改成当前事实：`public ABI wrapper` 的兜底路径仍消费 published `dataplane`，不再维护第二条 publication truth；同时把这条口径纳入 `dispatch-read-scope` 机器护栏。

### Phases

| Phase                              | Status      | Notes                                                                                  |
| ---------------------------------- | ----------- | -------------------------------------------------------------------------------------- |
| 1. 定位 active 文档漂移            | completed   | `docs/fafafa.core.simd.publicabi.md` 仍写着兜底回读 dispatch table                     |
| 2. 同步文档与机器护栏              | completed   | 文档已改成 dataplane fallback；`check_dispatch_read_scope.py` 已新增 active doc guard |
| 3. Release 验证与收口              | completed   | `py_compile`、`dispatch-read-scope`、Release `check`、Release `gate` 全绿              |

## 2026-05-12 RISCVV Integer Fallback Forwarder Expansion

### Goal

把 `src/fafafa.core.simd.riscvv.facade.inc` 里剩余一批 exact-contract integer arithmetic / bitwise non-ASM fallback 收回 `Scalar*` 真源；保留 RVV asm 路径、register ownership、compare / shift / float 语义敏感路径不动。

### Phases

| Phase                                | Status      | Notes                                                                                                                              |
| ------------------------------------ | ----------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别可安全合并的 integer fallback | completed   | 新增覆盖 `I16x8/I8x16/I64x4/I64x8/U16x8/U32x4/U64x4/U8x16` 的 add/sub/bitwise/not，以及小范围 mul/andnot |
| 2. 落地 scalar truth forwarder        | completed   | `riscvv.facade.inc` 的对应逐 lane 循环已改成 `Scalar*` 直调，不改 `riscvv.register.inc` 的 backend-owned slot                   |
| 3. 扩大 helper semantics 护栏         | completed   | `check_nonx86_helper_semantics.py` 已加入新增 forwarder 断言，summary 从 197 扩到 251                                             |
| 4. Release 验证与提交收口             | completed   | `git diff --check`、`py_compile`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 全部通过                  |

## 2026-05-12 RISCVV Integer Compare Forwarder Expansion

### Goal

把 `src/fafafa.core.simd.riscvv.facade.inc` 里剩余一批 exact-contract integer compare fallback 收回 `ScalarCmp*` 真源；只动 integer compare，不碰 float compare、shift、min/max、register ownership 或 asm 路径。

### Phases

| Phase                                | Status      | Notes                                                                                                                              |
| ------------------------------------ | ----------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| 1. 识别可安全合并的 compare fallback | completed   | `I16x8/I8x16/I32x16/I64x4/I64x8/U16x8/U32x4/U64x4/U8x16` 的 `Eq/Lt/Gt/Le/Ge/Ne` 都只是逐 lane compare 重复体                 |
| 2. 落地 scalar truth forwarder       | completed   | `riscvv.facade.inc` 的对应 compare wrapper 已改成直接委托 `ScalarCmp*`，不改 `riscvv.register.inc` 的 slot ownership             |
| 3. 扩大 helper semantics 护栏        | completed   | `check_nonx86_helper_semantics.py` 已把 RISCVV compare forwarder 覆盖扩到 `checks=304`                                           |
| 4. Release 验证与收口                | completed   | `git diff --check`、`py_compile`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 全部通过               |

## 2026-05-12 RISCVV I32x16 MinMax Tail Completion

### Goal

把 `src/fafafa.core.simd.riscvv.facade.inc` 里剩余的 `I32x16` integer `Min/Max` 手写循环收回 `ScalarMin/MaxI32x16` 真源；不碰 float min/max，也不改 register ownership。

### Phases

| Phase                          | Status      | Notes                                                                                               |
| ------------------------------ | ----------- | --------------------------------------------------------------------------------------------------- |
| 1. 识别唯一剩余的 min/max 尾巴 | completed   | 当前只剩 `MinI32x16/MaxI32x16` 还在手写逐 lane 分支                                               |
| 2. 落地 scalar truth forwarder | completed   | 两个 wrapper 已改成直接委托 `ScalarMinI32x16/ScalarMaxI32x16`                                      |
| 3. 扩大 helper semantics 护栏   | completed   | `check_nonx86_helper_semantics.py` 已把 `I32x16` min/max 计入 compare/minmax forwarder 覆盖，checks=306 |
| 4. Release 验证与收口          | completed   | `git diff --check`、`py_compile`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 全部通过 |

## 2026-05-12 RISCVV I32x16 Arithmetic/Bitwise Tail Completion

### Goal

把 `src/fafafa.core.simd.riscvv.facade.inc` 里剩余的 `I32x16` arithmetic / bitwise non-ASM 手写循环收回 `Scalar*I32x16` 真源；不碰 RVV asm path、`riscvv.register.inc` ownership、shift、compare 或浮点语义边界。

### Phases

| Phase                          | Status      | Notes                                                                                                  |
| ------------------------------ | ----------- | ------------------------------------------------------------------------------------------------------ |
| 1. 识别 arithmetic/bitwise 尾巴 | completed   | `Add/Sub/Mul/And/Or/Xor/Not/AndNotI32x16` 仍是逐 lane loop，且对应 `Scalar*I32x16` helper 已存在      |
| 2. 落地 scalar truth forwarder | completed   | 8 个 wrapper 已改成直接委托对应 `Scalar*I32x16`                                                        |
| 3. 扩大 helper semantics 护栏   | completed   | `check_nonx86_helper_semantics.py` 已纳入这 8 个 forwarder                                            |
| 4. Release 验证与收口          | completed   | `git diff --check`、`py_compile`、helper checker、`impl-audit-nonx86`、Release `check`、`gate` 全绿 |

## 2026-05-12 RISCVV Wide Float Arithmetic Forwarder Consolidation

### Goal

把 `src/fafafa.core.simd.riscvv.facade.inc` 里的 `F32x16/F64x8` 基础四则运算 no-ASM fallback 收回 `Scalar*` 真源；只处理 `Add/Sub/Mul/Div` exact-contract wrapper，不碰 `Min/Max`、rounding、clamp、FMA、asm path 或 register ownership。

### Phases

| Phase                               | Status      | Notes                                                                                                       |
| ----------------------------------- | ----------- | ----------------------------------------------------------------------------------------------------------- |
| 1. 识别 wide float arithmetic 重复体 | completed   | `Add/Sub/Mul/DivF32x16` 和 `Add/Sub/Mul/DivF64x8` 与对应 `Scalar*` helper 是同合同逐 lane 四则运算       |
| 2. 落地 scalar truth forwarder      | completed   | 8 个 wrapper 已改成直接委托 `ScalarAdd/Sub/Mul/DivF32x16/F64x8`                                            |
| 3. 扩大 helper semantics 护栏        | completed   | `check_nonx86_helper_semantics.py` 已纳入这 8 个 forwarder，预期 summary 从 `checks=314` 扩到 `checks=322` |
| 4. Release 验证与收口               | completed   | `git diff --check`、`py_compile`、helper checker、`impl-audit-nonx86`、Release `check`、`gate` 全绿      |

## 2026-05-12 RISCVV Narrow Float Arithmetic/Compare Forwarder Consolidation

### Goal

把 `src/fafafa.core.simd.riscvv.facade.inc` 里的 `F32x4/F64x2` 基础 arithmetic / compare no-ASM fallback 收回 `Scalar*` 真源；只处理 `Add/Sub/Mul/Div` 与 `Eq/Lt/Gt/Le/Ge/Ne` exact-contract wrapper，不碰 `Min/Max`、rounding、clamp、FMA、asm path 或 register ownership。

### Phases

| Phase                                       | Status      | Notes                                                                                                     |
| ------------------------------------------- | ----------- | --------------------------------------------------------------------------------------------------------- |
| 1. 识别 narrow float arithmetic/compare 重复体 | completed   | `Add/Sub/Mul/Div` 与 `CmpEq/Lt/Gt/Le/Ge/NeF32x4/F64x2` 都已有对应 `Scalar*` helper                        |
| 2. 落地 scalar truth forwarder              | completed   | 20 个 wrapper 已改成直接委托 `Scalar*F32x4/F64x2`                                                        |
| 3. 扩大 helper semantics 护栏                | completed   | `check_nonx86_helper_semantics.py` 已纳入这 20 个 forwarder，预期 summary 从 `checks=322` 扩到 `checks=342` |
| 4. Release 验证与收口                       | completed   | `git diff --check`、`py_compile`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 已全部通过，当前批次收口完成 |

## 2026-05-12 RISCVV Mid Float Arithmetic/Compare Forwarder Consolidation

### Goal

把 `src/fafafa.core.simd.riscvv.facade.inc` 里的 `F32x8/F64x4` 基础 arithmetic fallback 和 `F32x8/F64x4/F64x8/F32x16` compare fallback 收回 `Scalar*` 真源；只处理 `Add/Sub/Mul/Div` 与 `Eq/Lt/Gt/Le/Ge/Ne` exact-contract wrapper，不碰 `Min/Max`、rounding、clamp、FMA、asm path 或 register ownership。

### Phases

| Phase                                      | Status      | Notes                                                                                                            |
| ------------------------------------------ | ----------- | ---------------------------------------------------------------------------------------------------------------- |
| 1. 识别 mid float arithmetic/compare 重复体 | completed   | `Add/Sub/Mul/Div` 与 `CmpEq/Lt/Gt/Le/Ge/NeF32x8/F64x4/F64x8/F32x16` 都已有对应 `Scalar*` helper               |
| 2. 落地 scalar truth forwarder             | completed   | 32 个 wrapper 已改成直接委托 `Scalar*`                                                                         |
| 3. 扩大 helper semantics 护栏               | completed   | `check_nonx86_helper_semantics.py` 已纳入这 32 个 forwarder，summary 从 `checks=342` 扩到 `checks=374`           |
| 4. Release 验证与收口                      | completed   | `git diff --check`、`py_compile`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 全部通过 |

## 2026-05-12 RISCVV Abs/Sqrt Forwarder Consolidation

### Goal

把 `src/fafafa.core.simd.riscvv.facade.inc` 里 `F32x4/F64x2/F32x8/F64x4/F32x16/F64x8` 的 `Abs/Sqrt` no-ASM fallback 收回 `Scalar*` 真源；只处理这 12 个 unary exact-contract wrapper，不碰 `Min/Max`、rounding、clamp、FMA、`Rcp/Rsqrt`、asm path 或 register ownership。

### Phases

| Phase                          | Status      | Notes                                                                                                  |
| ------------------------------ | ----------- | ------------------------------------------------------------------------------------------------------ |
| 1. 识别 unary float 重复体      | completed   | 这 12 个 `Abs/Sqrt` wrapper 都已有对应 `Scalar*` helper                                                |
| 2. 落地 scalar truth forwarder  | completed   | 12 个 wrapper 已改成直接委托对应 `ScalarAbs/Sqrt*`                                                     |
| 3. 扩大 helper semantics 护栏    | completed   | `check_nonx86_helper_semantics.py` 已纳入这 12 个 forwarder，summary 预期从 `checks=374` 到 `checks=386` |
| 4. Release 验证与收口           | completed   | `git diff --check`、`py_compile`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 全部通过 |

## 2026-05-12 RISCVV Fma/Rcp/Rsqrt Forwarder Consolidation

### Goal

把 `src/fafafa.core.simd.riscvv.facade.inc` 里 `F32x4/F64x2/F32x8/F64x4/F32x16/F64x8` 的 `Fma` no-ASM fallback 以及 `F32x4` 的 `Rcp/Rsqrt` 收回 `Scalar*` 真源；保留 `RcpF64x4`、`Min/Max`、rounding、clamp、asm path 和 register ownership 不动。

### Phases

| Phase                                       | Status      | Notes                                                                                                         |
| ------------------------------------------- | ----------- | ------------------------------------------------------------------------------------------------------------- |
| 1. 识别 exact-contract ext math 重复体       | completed   | 6 个 `Fma` wrapper 与 `F32x4` 的 `Rcp/Rsqrt` 都已有对应 `Scalar*` helper；`RcpF64x4` 因零特判不纳入本批       |
| 2. 落地 scalar truth forwarder              | completed   | `riscvv.facade.inc` 已改成直接委托 `ScalarFma*` / `ScalarRcpF32x4` / `ScalarRsqrtF32x4`                      |
| 3. 扩大 helper semantics 护栏                | completed   | `check_nonx86_helper_semantics.py` 已补 RISCVV Fma / `Rcp` / `Rsqrt` source-side 断言，summary 扩到 `checks=394` |
| 4. Release 验证与收口                       | completed   | `git diff --check`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 均通过              |

## 2026-05-12 RISCVV Floor/Ceil Forwarder Consolidation

### Goal

把 `src/fafafa.core.simd.riscvv.facade.inc` 里 `F32x4/F64x2/F32x8/F64x4/F32x16/F64x8` 的 `Floor/Ceil` no-ASM fallback 收回 `Scalar*` 真源；保留 `Round/Trunc/Clamp`、`RcpF64x4`、asm path 和 register ownership 不动。

### Phases

| Phase                                     | Status      | Notes                                                                                                       |
| ----------------------------------------- | ----------- | ----------------------------------------------------------------------------------------------------------- |
| 1. 识别 exact-contract floor/ceil 重复体    | completed   | 这 12 个 `Floor/Ceil` wrapper 都已有对应 `Scalar*` helper，且属于比 `Round/Trunc/Clamp` 更低风险的纯壳 |
| 2. 落地 scalar truth forwarder            | completed   | `riscvv.facade.inc` 已改成直接委托 `ScalarFloor/Ceil*`                                                     |
| 3. 扩大 helper semantics 护栏              | completed   | `check_nonx86_helper_semantics.py` 已补 RISCVV `Floor/Ceil` source-side 断言，summary 扩到 `checks=406`   |
| 4. Release 验证与收口                     | completed   | `git diff --check`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 均通过          |
