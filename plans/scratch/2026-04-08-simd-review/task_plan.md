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
| 7. 继续深度审查缺失与冗余           | completed | 已用 live checker / non-x86 impl audit / freeze-status 复核当前真实残余，确认主缺口转为 evidence freshness、alias policy 与 hold-family trigger granularity      |
| 8. 落地仓库内收口方案               | completed | 已完成 alias visibility policy、history placeholder demotion、hold-family trigger table 和 evidence blocker 文档同步；release `check/gate` 继续为绿；当前仅剩 Windows evidence freshness 外部阻塞 |

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
| `mcp__ace_tool__search_context` 在宽整数继续批次里两次超时                       | 1       | 不重复卡在同一大查询，改用更窄的本地 `rg/sed` 直接核公开 API 与测试覆盖                         |
| 同一轮里误把 `TTestCase_DirectDispatchConcurrent` 与 Release `check` 并发启动     | 1       | 这次未触发 `Text file busy/rc=2` 假红，但已立即改回串行验证；`tests/fafafa.core.simd` 继续禁止并发构建 |
| `mcp__ace_tool__search_context` 在 gate/summary 真相检索上再次超时                | 1       | 直接回退到 `tests/fafafa.core.simd/BuildOrTest.sh` 与 `evaluate_simd_freeze_status.py` 读控制流 |
| `win-evidence-via-gh` 首次以远端临时分支名 dispatch 时，本地 `git rev-parse <ref>` 未解析成 SHA | 1       | 先推远端 `simd-win-evidence-20260514-0cbc7204`，再本地创建同名分支指向 `HEAD`，之后 workflow dispatch 成功 |
| GH Windows evidence workflow `25860032794` 被平台 billing/spending limit 拒跑     | 1       | Linux freeze 已补绿；Windows freshness 只能等待账单恢复或改走真实可用 Windows runner 后再刷新 |
| `BuildOrTest.sh gate` 在 `ieee754` fixture 批次首次 build 阶段报 `Can't call the linker ... /usr/bin/ld.bfd error code: -7` | 1 | 定向 `ieee754` suites 与 Release `check` 均已先绿，判断为本机链接器瞬态；串行重跑同一条 Release `gate` 后恢复 PASS |
| `runtime.testcase` 对齐公共 backend fixture 后，首轮 Release build 报 `Syntax error, "identifier" expected but "BEGIN" found` | 1 | 定位为删除局部 cleanup 变量后留下空 `var` 段；删掉陈旧 `var` 后，Release `TTestCase_RuntimeAPI/check/gate` 全部恢复 PASS |

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

## 2026-05-12 RISCVV Splat Forwarder Consolidation

### Goal

把 `src/fafafa.core.simd.riscvv.facade.inc` 里 `F32x4/F32x8/F32x16/F64x2/F64x4/F64x8/I64x4` 的 `Splat` no-ASM fallback 收回 `ScalarSplat*` 真源；只处理纯构造器，不碰 `Zero/Select/Extract/Insert`、asm path 或 register ownership。

### Phases

| Phase                              | Status      | Notes                                                                                                     |
| ---------------------------------- | ----------- | --------------------------------------------------------------------------------------------------------- |
| 1. 识别 exact-contract splat 重复体 | completed   | 7 个 `Splat` wrapper 都是逐 lane 写同一个 `value` 的纯构造器，已有对应 `ScalarSplat*` helper             |
| 2. 落地 scalar truth forwarder     | completed   | `riscvv.facade.inc` 已改成直接委托 `ScalarSplatF32x4/F32x8/F32x16/F64x2/F64x4/F64x8/I64x4`               |
| 3. 扩大 helper semantics 护栏       | completed   | `check_nonx86_helper_semantics.py` 已补 RISCVV `Splat` source-side 断言，summary 从 `checks=406` 扩到 `checks=413` |
| 4. Release 验证与收口              | completed   | `git diff --check`、`py_compile`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 均通过 |

## 2026-05-12 RISCVV Zero Forwarder Consolidation

### Goal

把 `src/fafafa.core.simd.riscvv.facade.inc` 里 `F32x4/F32x8/F32x16/F64x2/F64x4/F64x8/I64x4` 的 `Zero` no-ASM fallback 收回 `ScalarZero*` 真源；只处理纯构造器，不碰 `Select/Extract/Insert`、asm path 或 register ownership。

### Phases

| Phase                             | Status      | Notes                                                                                                     |
| --------------------------------- | ----------- | --------------------------------------------------------------------------------------------------------- |
| 1. 识别 exact-contract zero 重复体 | completed   | 7 个 `Zero` wrapper 都是 `Default(TVec*)` 的纯构造器，已有对应 `ScalarZero*` helper                       |
| 2. 落地 scalar truth forwarder    | completed   | `riscvv.facade.inc` 已改成直接委托 `ScalarZeroF32x4/F32x8/F32x16/F64x2/F64x4/F64x8/I64x4()`             |
| 3. 扩大 helper semantics 护栏      | completed   | `check_nonx86_helper_semantics.py` 已补 RISCVV `Zero` source-side 断言，summary 从 `checks=413` 扩到 `checks=420` |
| 4. Release 验证与收口             | completed   | `git diff --check`、`py_compile`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 均通过 |

### Errors Encountered

| Error | Attempt | Resolution |
| --- | --- | --- |
| missing parentheses on `ScalarZero` calls | 1 | helper checker reported `RISCVVZeroF32x4 missing fragment: Result := ScalarZeroF32x4();`; updated all 7 wrappers to explicit `ScalarZero*()` calls |

## 2026-05-12 RISCVV Shift Forwarder Consolidation

### Goal

把 `src/fafafa.core.simd.riscvv.facade.inc` 里 11 个 `ShiftLeft/ShiftRight/ShiftRightArith` no-ASM fallback 收回 `ScalarShift*` 真源；只处理 exact-contract shift wrappers，不碰 `RcpF64x4`、rounding、clamp、Min/Max、asm path 或 register ownership。

### Phases

| Phase                          | Status      | Notes                                                                                              |
| ------------------------------ | ----------- | -------------------------------------------------------------------------------------------------- |
| 1. 识别 shift 重复体           | completed   | 11 个 wrapper 都已有对应 `ScalarShift*` helper，包含高位/越界 count 的统一合同                    |
| 2. 落地 scalar truth forwarder | completed   | `riscvv.facade.inc` 已改成直接委托 `ScalarShift*`                                                  |
| 3. 扩大 helper semantics 护栏   | completed   | `check_nonx86_helper_semantics.py` 已纳入 11 个 shift forwarder，summary 从 `checks=420` 扩到 `checks=431` |
| 4. Release 验证与收口          | completed   | `git diff --check`、`py_compile`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 全部通过 |

## 2026-05-12 RISCVV I32x4 Shift Forwarder Consolidation

### Goal

把 `src/fafafa.core.simd.riscvv.facade.inc` 里 `I32x4` 的 3 个 shift no-ASM fallback 收回 `ScalarShift*` 真源；只处理 exact-contract shift wrapper，不碰 `Cmp*`、`Min/Max`、`Select/Extract/Insert`、asm path 或 register ownership。

### Phases

| Phase                          | Status    | Notes                                                                                         |
| ------------------------------ | --------- | --------------------------------------------------------------------------------------------- |
| 1. 识别 shift 重复体           | completed | `ScalarShiftLeftI32x4` / `ScalarShiftRightI32x4` / `ScalarShiftRightArithI32x4` 都已存在     |
| 2. 落地 scalar truth forwarder | completed | `RISCVVShiftLeftI32x4` / `ShiftRightI32x4` / `ShiftRightArithI32x4` 已改成直接委托 `ScalarShift*` |
| 3. 扩大 helper semantics 护栏   | completed | `check_nonx86_helper_semantics.py` 已纳入这 3 个 forwarder，summary 从 `checks=431` 扩到 `checks=434` |
| 4. Release 验证与收口          | completed | `git diff --check`、`py_compile`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 全部通过 |

## 2026-05-12 RISCVV Mask Helper Forwarder Consolidation

### Goal

把 `src/fafafa.core.simd.riscvv.facade.inc` 里 `Mask2/Mask4/Mask8/Mask16` 的 `All/Any/None/PopCount/FirstSet` no-ASM fallback 收回 `ScalarMask*` 真源；只处理 exact-contract mask helper，不碰 bitwise mask ops、select、extract/insert、asm path 或 register ownership。

### Phases

| Phase                          | Status    | Notes                                                                                 |
| ------------------------------ | --------- | ------------------------------------------------------------------------------------- |
| 1. 识别 mask 重复体           | completed | `ScalarMask2/4/8/16All/Any/None/PopCount/FirstSet` 都已存在且与 facade 逻辑同构      |
| 2. 落地 scalar truth forwarder | completed | `RISCVVMask2/4/8/16*` 已改成直接委托 `ScalarMask*`                                   |
| 3. 扩大 helper semantics 护栏   | completed | `check_nonx86_helper_semantics.py` 已纳入 20 个 mask forwarder，summary 从 `checks=434` 扩到 `checks=454` |
| 4. Release 验证与收口          | completed | `git diff --check`、`py_compile`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 全部通过 |

## 2026-05-12 RISCVV Vector Math Exact Forwarder Consolidation

### Goal

把 `src/fafafa.core.simd.riscvv.facade.inc` 里 `F32` dot/cross/length 的 5 个 exact-contract no-ASM fallback 收回 `Scalar*` 真源；不碰 `NormalizeF32x4/F32x3`，因为 RISCVV 当前阈值是 `1e-10` 而 scalar 阈值是 `0.0`；不碰 `DotF64x2/F64x4`，因为现有 source-shape 测试要求它们不得直接 scalar forward。

### Phases

| Phase                          | Status    | Notes                                                                                          |
| ------------------------------ | --------- | ---------------------------------------------------------------------------------------------- |
| 1. 识别 exact vector-math 重复体 | completed | `DotF32x4/F32x3`、`CrossF32x3`、`LengthF32x4/F32x3` 与 `Scalar*` 同合同；`DotF64x2/F64x4` 经测试确认不得 scalar forward |
| 2. 落地 scalar truth forwarder | completed | 5 个 RISCVV wrapper 已改成直接委托对应 `Scalar*`；`Normalize*` 保留原实现                     |
| 3. 扩大 helper semantics 护栏   | completed | `check_nonx86_helper_semantics.py` 已纳入这 5 个 forwarder，summary 从 `checks=454` 扩到 `checks=459` |
| 4. Release 验证与收口          | completed | `git diff --check`、`py_compile`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 全部通过 |

### Errors Encountered

| Error | Attempt | Resolution |
| --- | --- | --- |
| `Test_RISCVV_FacadeDotF64_NoAsmSource_Does_Not_ScalarForward` failed after forwarding `DotF64x2/F64x4` | 1 | Reverted both F64 dot wrappers back to local exact arithmetic and kept only the F32 dot/cross/length forwarders |

## 2026-05-12 Facade Hot-Path Dispatch Mirror

### Goal

把 `src/fafafa.core.simd.pas` 普通 façade wrapper 的 dispatch 读取从每次调用 `GetCurrentSimdDataPlaneDispatch` 收紧为本地只读 snapshot mirror；mirror 只由 `dataplane` 发布结果填充，`dispatch` / `runtime` / `cpuinfo` 控制面不下沉到 façade 热路径。

### Phases

| Phase                              | Status      | Notes |
| ---------------------------------- | ----------- | ----- |
| 1. 锁定热路径边界与现状            | completed   | 当前 `simd.pas` 中仍有大量 wrapper 每次调用 `GetCurrentSimdDataPlaneDispatch` |
| 2. 落地 façade local dispatch mirror | completed   | 新增本地 `g_FastSimdDispatchPtr`，由 `RebindSimdFacadeFastPaths` 从 `PSimdDataPlane.Dispatch` 发布 |
| 3. 扩展 dispatch-read-scope 护栏    | completed   | `check_dispatch_read_scope.py` 已阻止 `simd.pas` façade wrapper 回退到 per-call dataplane dispatch getter |
| 4. Release 验证与提交收口           | completed   | `git diff --check`、Release `check`、focused seam suites、Release `gate` 全部通过；待 review + commit |

## 2026-05-12 NEON Comment Hygiene

### Goal

把 `src/fafafa.core.simd.neon.compare.inc`、`src/fafafa.core.simd.neon.scalar.utility.inc`、`src/fafafa.core.simd.neon.scalar.reduction.inc` 里的过程标记和 emoji 注释噪音收掉，保留语义性标题，不改任何 NEON 实现。

### Phases

| Phase                              | Status      | Notes |
| ---------------------------------- | ----------- | ----- |
| 1. 锁定噪音注释范围                | completed   | 噪音主要是 `✅`、`Task 6.2`、`Iteration 2.4`、`P2/P3/P4` 这类过程标记 |
| 2. 清理 NEON 注释标题              | completed   | 统一为中性语义标题，去掉项目过程标签 |
| 3. 复验源码/文档/护栏              | completed   | 注释文本已不再带过程标记，函数体未改 |
| 4. Release 验证与提交收口           | completed   | `git diff --check`、Release `check` 均通过；待 review + commit |

## 2026-05-12 SIMD Redundancy Survey

### Goal

调查 `simd` 的冗余卫生问题，按 `docs/plans` / 顶层文档 / 源码三层分别找出重复 truth source、重复计划入口、重复实现与可合并封装，只输出可收口清单，不在本批扩大架构面。

### Phases

| Phase                              | Status      | Notes |
| ---------------------------------- | ----------- | ----- |
| 1. 盘点 active spine 与历史尾部      | completed   | 已确认当前 active spine，且历史计划/快照都带有明确退役口径 |
| 2. 分类 docs/plans 与顶层 SIMD 文档  | completed   | 已分出 active / historical baseline / superseded / cleanup candidate |
| 3. 扫描源码重复 truth 与重复实现     | completed   | 已确认当前 residual 主要是 fallback thin wrapper 与少数语义敏感 loop |
| 4. 汇总可收口项与后续动作           | completed   | 已形成可执行的卫生建议清单，不扩大架构面 |

## 2026-05-12 SIMD Docs Legacy Hygiene

### Goal

按冗余调查建议收口两处文档卫生：修正 `docs/INDEX.md` 中不存在的 `docs/simd/` 导流，并把 `src/fafafa.core.simd.next-steps.md` 历史草案迁入 `docs/legacy/simd/`，原路径只保留兼容占位。

### Phases

| Phase                              | Status      | Notes |
| ---------------------------------- | ----------- | ----- |
| 1. 修正全局索引导流                | completed   | `docs/INDEX.md` 不再列出不存在的 `docs/simd/`，改指当前模块级文档与 legacy 入口 |
| 2. 迁移历史草案正文                | completed   | 正文已移动到 `docs/legacy/simd/fafafa.core.simd.next-steps.md` |
| 3. 保留旧路径兼容占位              | completed   | `src/fafafa.core.simd.next-steps.md` 现在只负责跳转，不承载旧计划正文 |
| 4. 更新当前活入口说明              | completed   | `src/fafafa.core.simd.README.md` 与 `docs/fafafa.core.simd.md` 已指明 archive 位置 |

## 2026-05-12 SIMD Historical Snapshot Archive

### Goal

继续整治顶层 SIMD 文档噪声：把已经自标为 internal / historical snapshot 的旧分析、审计、质量迭代和 NEON 迭代文档迁入 `docs/legacy/simd/`，原路径只保留跳转占位，避免搜索结果把历史快照误当成当前 truth source。

### Phases

| Phase                              | Status      | Notes |
| ---------------------------------- | ----------- | ----- |
| 1. 锁定迁移范围                    | completed   | 顶层 `SIMD_*` / `NEON_*` 历史快照已确认，不碰 active truth docs |
| 2. 迁移正文到 legacy               | completed   | 正文已迁入 `docs/legacy/simd/` 并集中到归档索引 |
| 3. 原路径留兼容占位                | completed   | 旧链接保留可读，但不再承载正文 |
| 4. 更新当前入口与 scratch 记录      | completed   | 当前 docs 与 scratch 都已指向 `docs/legacy/simd/README.md` |

## 2026-05-12 SIMD Source Reachability Hygiene

### Goal

把 SIMD 源码里“文件存在但不在 live source 链”的真冗余收掉，并补机器护栏，避免后续继续积累 unreachable private include / dead helper unit。

### Phases

| Phase                              | Status      | Notes |
| ---------------------------------- | ----------- | ----- |
| 1. 复核可疑 dead-file 列表         | completed   | 已做 transitive include 闭包，排除 `neon.scalar_fallback.inc` 间接挂接的假阳性 |
| 2. 区分保留特例与真删除对象         | completed   | `neon.scalar.wide_memory.inc` 保留为 audit-only checker 样本；其余 10 个 unreachable 源码确认为删除对象 |
| 3. 落地 source reachability 护栏    | completed   | 已新增 `tests/fafafa.core.simd/check_simd_source_reachability.py` 并接入 `BuildOrTest.sh check` |
| 4. 删除 unreachable 冗余源码并复验 | completed   | 已删除 dead SSE2 `.inc`、`neon.scalar.wide_reduce.inc`、`cpuinfo.x86.asm.pas`；待跑 release 级复验与提交 |

## 2026-05-12 RISCVV Helper Include Forwarder Hygiene

### Goal

继续沿 `Wave 5 / retire + redundancy cleanup` 深审 `src/fafafa.core.simd.riscvv.helpers.inc`，只收掉已经有 `Scalar*` 真源、且不触碰 `Min/Max` / unsigned compare / shift / reduction / select 语义边界的 exact-contract 重复体，同时把 include-file 自身纳入 helper semantics 护栏。

### Phases

| Phase                              | Status      | Notes |
| ---------------------------------- | ----------- | ----- |
| 1. 锁定 helper include 的低风险目标 | completed   | 已确认本批只碰 `U64x2` 基础 arithmetic/bitwise 与 `AndNotI64x2/U64x2`，暂缓 `Min/Max`、unsigned `Cmp*`、shift、reduction、select |
| 2. 收口 helper 重复实现             | completed   | `RISCVVAdd/Sub/And/Or/Xor/NotU64x2` 与 `RISCVVAndNotI64x2/U64x2` 已改成 thin scalar forwarder |
| 3. 扩展 include-file source 护栏    | completed   | `check_nonx86_helper_semantics.py` 已新增 `RISCVV_HELPERS_FILE`，直接校验 helper include 中这 8 个 wrapper |
| 4. Release 验证与提交收口           | completed   | `git diff --check`、`py_compile`、helper checker、Release `impl-audit-nonx86/check/gate` 全绿；待 review + commit |

## 2026-05-12 RISCVV Helper Compare/Shift Forwarder Hygiene

### Goal

继续沿 `riscvv.helpers.inc` 收剩余的 exact-contract 重复体，但只碰已经有 scalar 真源且现有测试明确覆盖的 helper：`U64x2` 的 `CmpEq/Lt/Gt/Min/Max` 与 `I64x2` 的 `ShiftLeft/ShiftRight/ShiftRightArith`。同时把这 8 个 helper 接进 include-file source 护栏，不扩大到 `U64x2` shift、reduction、select 或其它合同面。

### Phases

| Phase                              | Status      | Notes |
| ---------------------------------- | ----------- | ----- |
| 1. 复核候选与放弃项                 | completed   | 已确认 `AVX512ShiftRightArithI32x16` invalid-count 已有测试覆盖；本批主目标回到 `riscvv.helpers.inc` 的真重复体 |
| 2. 收口 compare/shift 重复实现      | completed   | `RISCVVCmpEq/Lt/GtU64x2`、`RISCVVMin/MaxU64x2`、`RISCVVShiftLeft/Right/RightArithI64x2` 已改成 thin scalar forwarder |
| 3. 扩展 helper include 护栏         | completed   | `check_nonx86_helper_semantics.py` 已把这 8 个 helper 纳入 `riscvv_helper_scalar_forwarder_expectations` |
| 4. Release 验证与提交收口           | completed   | `git diff --check`、`py_compile`、helper checker、Release `impl-audit-nonx86/check/gate` 全绿；待 review + commit |

## 2026-05-12 Scalar AndNot Truth Closure

### Goal

收口 `AndNot` 家族里被 dispatch wrapper 掩住的 scalar 真源漂移：补齐缺失的 `ScalarAndNotI8x16/U8x16`，修正 `ScalarAndNotU16x8/U32x8` 的反向语义，并让 `FillBaseDispatchTable` 回到直接绑定 scalar 真源，而不是继续保留 `DispatchAndNot*` 补洞实现。

### Phases

| Phase                              | Status      | Notes |
| ---------------------------------- | ----------- | ----- |
| 1. 复核公开合同与现状             | completed   | 已确认 tests / comments / facade / RISCVV 都以 `(not a) and b` 为合同，偏差只在 scalar 真源与 base dispatch 补洞面 |
| 2. 修正 scalar 真源并补齐缺口     | completed   | 已新增 `ScalarAndNotI8x16/U8x16`，并修正 `ScalarAndNotU16x8/U32x8` |
| 3. 删除 dispatch 补洞冗余         | completed   | `FillBaseDispatchTable` 已改回直接绑定 `ScalarAndNot*`，`DispatchAndNotI8x16/U16x8/U8x16` 已删除 |
| 4. 补直接语义测试并 release 复验   | completed   | 新增 `I8x16/U16x8/U8x16/U32x8` 4 条 AndNot 语义测试，Release targeted suites、`check`、`gate` 全绿 |

## 2026-05-12 Narrow Compare Direct Guard Coverage

### Goal

继续补 `narrowintegerops` 里缺失的直接 guard，覆盖此前只靠 parity 间接经过的窄整型 compare contract：对 `I16x8/I8x16/U16x8/U8x16` 的 `CmpLe/CmpGe/CmpNe` 增加 dispatch-level 语义测试，并为 `U32x4` 补上 façade 级 `AndNot/CmpLe/CmpGe` 直接测试。

### Phases

| Phase                              | Status      | Notes |
| ---------------------------------- | ----------- | ----- |
| 1. 复核真实 API 边界               | completed   | 已确认四组窄整型 `CmpLe/CmpGe/CmpNe` 不属于 façade，而是 dispatch/scalar contract；`U32x4` 这三项属于 façade |
| 2. 补 dispatch / façade 直接 guard | completed   | `narrowintegerops` 已新增 12 条 narrow dispatch compare 测试和 3 条 `U32x4` façade 测试 |
| 3. 复核 scalar 强制语义            | completed   | `TTestCase_NarrowIntegerOps.SetUp` 已固定 `ForceBackend(sbScalar)`，因此这批 dispatch-level compare 测试直接命中 scalar 真源 |
| 4. Release 验证与提交收口          | completed   | `git diff --check`、Release `TTestCase_NarrowIntegerOps`、Release `check`、Release `gate` 全绿；待 review + commit |

## 2026-05-13 Low-Width Integer Facade Guard Coverage

### Goal

继续沿“只靠 parity 间接覆盖”的证据缺口往下补，把 128-bit 低宽整数 façade 上还没有 direct guard 的公开 contract 补实：`I32x4`、`I64x2` 的 `AndNot/Eq/Lt/Gt/Le/Ge/Ne`，以及 `U64x2` 的 `AndNot/Eq/Lt/Gt`。

### Phases

| Phase                              | Status      | Notes |
| ---------------------------------- | ----------- | ----- |
| 1. 复核 façade 真实边界            | completed   | 已确认 `I32x4/I64x2` 公开暴露 `AndNot + 6 compare`，`U64x2` 公开暴露 `AndNot + Eq/Lt/Gt`，旧 direct tests 缺失 |
| 2. 新增 scalar-forced direct suite | completed   | 已在 `fafafa.core.simd.testcase.pas` 新增 `TTestCase_IntegerFacadeGuards`，直接守这三组 façade contract |
| 3. 同步 runner suite 清单          | completed   | `fafafa.core.simd.test.lpr` 的 `ProcessAllSuites` 已加入新 suite，避免 runner 只靠 `RegisterTest` 仍然选不到 |
| 4. Release 验证与提交收口          | completed   | `git diff --check`、Release `TTestCase_IntegerFacadeGuards`、Release `check`、Release `gate` 全绿；待 review + commit |

## 2026-05-13 Mid/Wide Integer Facade Guard Coverage

### Goal

继续沿同一 direct-guard 证据线补下一簇公开 façade contract，把此前仍主要依赖 parity/多 backend 旁证的 `I64x4`、`I32x16`、`U32x16` 公开 `AndNot/compare` 面补成 scalar-forced direct guard。

### Phases

| Phase                              | Status      | Notes |
| ---------------------------------- | ----------- | ----- |
| 1. 复核 façade 真实边界            | completed   | 已确认 `src/fafafa.core.simd.pas` 公开暴露 `VecI64x4AndNot/CmpLe/CmpGe/CmpNe`、`VecI32x16AndNot/CmpLe/CmpGe/CmpNe`、`VecU32x16AndNot/CmpLe/CmpGe/CmpNe` |
| 2. 扩展现有 scalar-forced direct suite | completed | 继续使用已挂接好的 `TTestCase_IntegerFacadeGuards`，新增 `I64x4`、`I32x16`、`U32x16` 的 direct guard，不再新增 runner 结构 |
| 3. 收口测试层命名歧义              | completed   | `I32x16` 的 `CmpEq/Lt/Gt` 需显式限定到 `fafafa.core.simd.`，避免落到 `simd.utils` 的 `TMaskI32x16` 同名 helper |
| 4. Release 验证与提交收口          | completed   | `git diff --check`、Release `TTestCase_IntegerFacadeGuards`、Release `check`、Release `gate` 全绿；待 review + commit |

## 2026-05-13 Wide Tail Integer Facade Guard Coverage

### Goal

继续按同一证据线扫当前尾部公开 façade contract，把 `U64x8` 的 `CmpLe/CmpGe/CmpNe` 与 `I16x32/I8x64` 的 `AndNot` 从“只有 parity/multi-backend 旁证”补成 scalar-forced direct guard。

### Phases

| Phase                              | Status      | Notes |
| ---------------------------------- | ----------- | ----- |
| 1. 复核 façade 真实边界            | completed   | 已确认 `VecU64x8CmpLe/CmpGe/CmpNe`、`VecI16x32AndNot`、`VecI8x64AndNot` 都是 `src/fafafa.core.simd.pas` 的真实公开 surface |
| 2. 扩展现有 scalar-forced direct suite | completed | 继续扩 `TTestCase_IntegerFacadeGuards`，新增 `U64x8` compare 与 `I16x32/I8x64` AndNot，不引入新的 runner/suite 结构 |
| 3. Release 验证与提交收口          | completed   | `git diff --check`、Release `TTestCase_IntegerFacadeGuards`、Release `check`、Release `gate` 全绿；待 review + commit |

## 2026-05-13 U64x4 Facade Direct Guard Coverage

### Goal

继续把整数 façade 的尾巴收窄到真正只剩 parity 旁证的公开 contract：为 `VecU64x4CmpEq/Lt/Gt/Le/Ge/Ne` 补一条固定 `sbScalar` 的 direct guard。

### Phases

| Phase                              | Status      | Notes |
| ---------------------------------- | ----------- | ----- |
| 1. 复核 `U64x4` 当前证据层现状     | completed   | 已确认 `dispatchapi/direct` 只有 parity 或 expected-mask 旁证，仍缺 scalar-forced direct guard |
| 2. 扩展现有 scalar-forced direct suite | completed | 继续扩 `TTestCase_IntegerFacadeGuards`，新增 `U64x4` unsigned compare mask 测试，不新增 runner 结构 |
| 3. Release 验证与提交收口          | completed   | `git diff --check`、Release `TTestCase_IntegerFacadeGuards`、Release `check`、Release `gate` 全绿；待 review + commit |

## 2026-05-13 I64x8 Facade Direct Guard Coverage

### Goal

继续把宽整数 façade 剩余的“只有 parity/普通 direct 旁证”收窄到固定 `sbScalar` 的统一护栏：为 `VecI64x8CmpEq/Lt/Gt/Le/Ge/Ne` 补一条 scalar-forced direct guard。

### Phases

| Phase                              | Status      | Notes |
| ---------------------------------- | ----------- | ----- |
| 1. 复核 `I64x8` 当前证据层现状     | completed   | 已确认 `src/fafafa.core.simd.pas` 公开暴露 `VecI64x8Cmp*`；现有 `vec512types/dispatchapi` 只提供普通 direct/parity，`vec512types` 本身不强制 `sbScalar` |
| 2. 扩展现有 scalar-forced direct suite | completed | 继续扩 `TTestCase_IntegerFacadeGuards`，新增 `I64x8` signed compare mask 测试，不新增 runner 结构 |
| 3. Release 验证与提交收口          | completed   | `git diff --check`、Release `TTestCase_IntegerFacadeGuards`、Release `check`、串行 Release `gate` 全绿；一次并行 `gate` build rc=2 已确认为共享输出目录假红 |

## 2026-05-13 512-bit Integer Compare Tail Guard Coverage

### Goal

继续把 512-bit 整数 façade 里仍只剩 parity 旁证的 compare 面补成固定 `sbScalar` 的 direct guard：覆盖 `VecI16x32CmpEq/Lt/Gt`、`VecI8x64CmpEq/Lt/Gt` 与 `VecU8x64CmpEq/Lt/Gt`。

### Phases

| Phase                              | Status      | Notes |
| ---------------------------------- | ----------- | ----- |
| 1. 复核剩余公开 compare 边界       | completed   | 已确认 `I16x32/I8x64/U8x64` compare 都是 `src/fafafa.core.simd.pas` 的真实 façade surface；`narrowintegerops` 只覆盖窄族，不覆盖这 3 组 512-bit contract |
| 2. 扩展现有 scalar-forced direct suite | completed | 继续扩 `TTestCase_IntegerFacadeGuards`，新增 3 条 compare guard，不新增 runner / checker / family-local suite |
| 3. Release 验证与提交收口          | completed   | `git diff --check`、Release `TTestCase_IntegerFacadeGuards`、Release `check`、串行 Release `gate` 全绿 |

## 2026-05-13 I32x8 Facade Direct Guard Coverage

### Goal

继续收掉仍停留在“默认后端 family-local 测试”层的公开 façade contract：为 `VecI32x8AndNot/CmpEq/CmpLt/CmpGt/CmpLe/CmpGe/CmpNe` 补齐固定 `sbScalar` 的 direct guard。

### Phases

| Phase                              | Status      | Notes |
| ---------------------------------- | ----------- | ----- |
| 1. 复核 `I32x8` 当前证据层现状     | completed   | 已确认 `veci32x8` suite 虽然覆盖 `AndNot + compare`，但 `SetUp/TearDown` 不固定 `sbScalar`；同目录 `vecu32x8` 则固定 `sbScalar`，两者证据强度不对称 |
| 2. 扩展现有 scalar-forced direct suite | completed | 继续扩 `TTestCase_IntegerFacadeGuards`，新增 `I32x8` 的 `AndNot + compare`，不改旧 family-local suite 语义 |
| 3. Release 验证与提交收口          | completed   | `git diff --check`、Release `TTestCase_IntegerFacadeGuards`、Release `check`、串行 Release `gate` 全绿 |

## 2026-05-13 Wide Float Facade Guard Coverage

### Goal

继续把 512-bit 浮点公开 façade 从“只有 operator/default-backend/parity 旁证”补成固定 `sbScalar` 的 direct guard，覆盖 `F32x16/F64x8` 的算术、compare、extended math、reduce、load/store/select` 主 contract。

### Phases

| Phase                              | Status      | Notes |
| ---------------------------------- | ----------- | ----- |
| 1. 复核 512-bit float 当前证据层现状 | completed | 已确认 `vec512types` 不固定 `sbScalar`，而且 `Add/Sub/Mul` 主要走 operator；`F32x16` compare 走 `TMaskF32x16` vector-mask surface，不等于公开 façade `_Mask` contract |
| 2. 在现有主 runner 补 scalar direct guard | completed | 已在 `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` 新增并列 `TTestCase_FloatFacadeGuards`，并同步 `test.lpr` suite manifest；未改 `vec512types` 生命周期，也未新增 family-local runner |
| 3. 修正测试期望并完成 Release 验证 | completed | 首轮 targeted run 仅暴露 `ReduceAdd` 期望值写错；修正到 `F32x16=13.5`、`F64x8=5.5` 后，Release targeted/check/gate 全绿 |

## 2026-05-13 Wide Float Remaining API Guard Coverage

### Goal

继续把 `F32x16/F64x8` 公开 façade 里仍只剩 parity/默认后端旁证的剩余 API 收成固定 `sbScalar` 的 direct guard，覆盖 `Abs/Sqrt/Min/Max`，以及 `F32x16` 的 `Extract/Insert`。

### Phases

| Phase                              | Status      | Notes |
| ---------------------------------- | ----------- | ----- |
| 1. 复核 wide-float 剩余 API 当前证据层现状 | completed | 已确认这批主要还停留在 `dispatchapi` parity；`vec512types` 不固定 `sbScalar`，也没有完整覆盖 `F64x8` 剩余 math API |
| 2. 扩展现有 scalar direct suite     | completed | 继续扩 `TTestCase_FloatFacadeGuards`，新增 2 条测试覆盖 `F32x16` 的 `Abs/Sqrt/Min/Max/Extract/Insert` 与 `F64x8` 的 `Abs/Sqrt/Min/Max`，未改 runner 结构 |
| 3. Release 验证与提交收口           | completed | `git diff --check`、Release `TTestCase_FloatFacadeGuards`、Release `check`、串行 Release `gate` 全绿；待 review + commit |

## 2026-05-13 Wide Integer Remaining Ops Guard Coverage

### Goal

继续把 512-bit 宽整数 façade 中仍主要依赖 parity 旁证的剩余公开操作补成固定 `sbScalar` 的 direct guard，优先覆盖 `I32x16/U32x16/I64x8/U64x8` 的算术、位运算、移位、最值与 `I32x16` 的 `Extract/Insert`。

### Phases

| Phase                              | Status      | Notes |
| ---------------------------------- | ----------- | ----- |
| 1. 复核 wide-integer 剩余公开边界  | completed   | 已确认本轮最高价值缺口落在 `I32x16/U32x16/I64x8/U64x8` 的 remaining ops；这些函数在 `src/fafafa.core.simd.pas` 都是公开 façade surface，而不是 backend-only helper |
| 2. 扩展现有 scalar direct suite     | completed   | 继续扩 `TTestCase_IntegerFacadeGuards`，新增 4 条测试覆盖 `I32x16/U32x16/I64x8/U64x8` 的 remaining public ops，不新增 runner/suite，也不改实现 |
| 3. 修正测试期望并完成 Release 验证 | completed   | 首轮 targeted run 仅暴露 `VecU32x16Sub` 的 `UInt32` 回绕期望未显式钉型；修正后 `git diff --check`、Release targeted/check/gate 全绿 |

## 2026-05-13 Wide Narrow-Lane Integer Remaining Ops Guard Coverage

### Goal

继续把 `I16x32/I8x64/U8x64` 三簇宽整数 façade 中仍主要依赖 parity 旁证的剩余公开操作补成固定 `sbScalar` 的 direct guard，优先覆盖算术、位运算、移位与最值。

### Phases

| Phase                              | Status      | Notes |
| ---------------------------------- | ----------- | ----- |
| 1. 复核这三簇剩余公开边界          | completed   | 已确认 `src/fafafa.core.simd.pas` 公开暴露 `I16x32` 的 `Add/Sub/bitwise/shift/minmax`，`I8x64/U8x64` 的 `Add/Sub/bitwise/minmax`；现有 `IntegerFacadeGuards` 仅覆盖 compare 和部分 `AndNot` |
| 2. 扩展现有 scalar direct suite     | completed   | 继续扩 `TTestCase_IntegerFacadeGuards`，新增 `I16x32/I8x64/U8x64` 的 remaining ops guard，不新增 runner/suite，也不改实现 |
| 3. 修正测试期望并完成 Release 验证 | completed   | 首轮 targeted run 仅暴露 `VecI16x32ShiftLeft` 期望未显式收回 16-bit lane；修正为 `Word(...)` 后 `git diff --check`、Release targeted/check/gate 全绿 |

## 2026-05-13 I64x4 U64x4 Remaining Ops Guard Coverage

### Goal

继续把 `I64x4/U64x4` 两簇 256-bit 整数 façade 中仍只靠 parity 旁证的 remaining ops 收成固定 `sbScalar` 的 direct guard，覆盖 `Add/Sub/bitwise/shift`，以及 `I64x4` 的 `ShiftRightArith`。

### Phases

| Phase                              | Status      | Notes |
| ---------------------------------- | ----------- | ----- |
| 1. 复核这两簇公开剩余边界          | completed   | 已确认 `src/fafafa.core.simd.pas` 公开暴露 `I64x4` 的 `Add/Sub/And/Or/Xor/Not/ShiftLeft/ShiftRight/ShiftRightArith` 与 `U64x4` 的 `Add/Sub/And/Or/Xor/Not/ShiftLeft/ShiftRight`；现有 `IntegerFacadeGuards` 只覆盖 `I64x4` 的 `AndNot + compare` 与 `U64x4` 的 compare |
| 2. 扩展现有 scalar direct suite     | completed   | 继续扩 `TTestCase_IntegerFacadeGuards`，新增 `Test_VecI64x4_RemainingOps_Basic` 与 `Test_VecU64x4_RemainingOps_Basic`，不新增 runner/suite，也不改实现 |
| 3. Release 验证与提交收口          | completed   | `git diff --check`、Release `TTestCase_IntegerFacadeGuards`、Release `check`、串行 Release `gate` 全绿；没有出现新的实现回归 |

## 2026-05-13 I32x8 I64x2 U64x2 Remaining Ops Guard Coverage

### Goal

继续把 `I32x8/I64x2/U64x2` 三簇整数 façade 中仍停留在默认后端 family-local 测试或 parity 旁证层的剩余公开操作补成固定 `sbScalar` 的 direct guard，覆盖 `I32x8` 的 `Add/Sub/Mul/bitwise/shift/minmax/Extract/Insert`、`I64x2` 的 `Add/Sub/bitwise/shift/minmax/Extract/Insert`，以及 `U64x2` 的 `Add/Sub/bitwise/minmax`。

### Phases

| Phase                              | Status      | Notes |
| ---------------------------------- | ----------- | ----- |
| 1. 复核这三簇当前证据层现状        | completed   | 已确认 `veci32x8` suite 虽然覆盖面很全，但不固定 `sbScalar`；`I64x2/U64x2` 的 remaining ops 主要停留在 `dispatchapi/direct` parity，而 `IntegerFacadeGuards` 仅覆盖 `AndNot + compare` |
| 2. 扩展现有 scalar direct suite     | completed   | 继续扩 `TTestCase_IntegerFacadeGuards`，新增 `Test_VecI32x8_RemainingOps_Basic`、`Test_VecI64x2_RemainingOps_Basic`、`Test_VecU64x2_RemainingOps_Basic`，不新增 runner/suite，也不改实现 |
| 3. Release 验证与提交收口          | completed   | `git diff --check`、Release `TTestCase_IntegerFacadeGuards`、Release `check`、串行 Release `gate` 全绿；没有出现新的测试期望红灯或实现回归 |

## 2026-05-14 I32x4 Remaining Ops Guard Coverage

### Goal

继续把 `I32x4` 这簇 128-bit 整数 façade 中仍停留在 parity / 非 scalar-direct 测试层的剩余公开操作补成固定 `sbScalar` 的 direct guard，覆盖 `Add/Sub/Mul/bitwise/shift/minmax/Extract/Insert`。

### Phases

| Phase                              | Status      | Notes |
| ---------------------------------- | ----------- | ----- |
| 1. 复核 `I32x4` 当前证据层现状     | completed   | 已确认 `src/fafafa.core.simd.pas` 公开暴露 `I32x4` 的 `Add/Sub/Mul/And/Or/Xor/Not/ShiftLeft/ShiftRight/ShiftRightArith/Min/Max/Extract/Insert`；现有 `IntegerFacadeGuards` 只覆盖 `AndNot + compare` |
| 2. 扩展现有 scalar direct suite     | completed   | 继续扩 `TTestCase_IntegerFacadeGuards`，新增 `Test_VecI32x4_RemainingOps_Basic`，不新增 runner/suite，也不改实现 |
| 3. Release 验证与提交收口          | completed   | `git diff --check`、Release `TTestCase_IntegerFacadeGuards`、Release `check`、串行 Release `gate` 全绿；没有出现新的测试期望红灯或实现回归 |

## 2026-05-14 F64x2 Direct Float Facade Guard Coverage

### Goal

继续把 `F64x2` 这簇 128-bit 浮点 façade 中仍停留在 rounding/FMA、operator overload 或 parity 旁证层的剩余公开操作补成固定 `sbScalar` 的 direct guard，覆盖 `Add/Sub/Mul/Div`、`compare/reduce/select`、`Abs/Sqrt/Min/Max`、`Load/Store/Splat/Zero`、`Extract/Insert`。

### Phases

| Phase                              | Status    | Notes |
| ---------------------------------- | --------- | ----- |
| 1. 复核 `F64x2` 当前证据层现状     | completed | 已确认 `TTestCase_VectorOps` 只固定 `sbScalar` 覆盖 `Floor/Ceil/Round/Trunc/Fma`，`TTestCase_OperatorOverloads` 只覆盖 `+/-/*//`，而 `dispatchapi/direct` 的 `F64x2` 主要是 parity/旁证，不等价于 public façade direct guard |
| 2. 扩展现有 scalar direct suite     | completed | 继续扩 `TTestCase_FloatFacadeGuards`，新增 4 条 `F64x2` 测试覆盖 arithmetic、compare/reduce/select、extended math/load-store、remaining math/extract-insert，不新增 runner/suite，也不改实现 |
| 3. Release 验证与提交收口          | completed | `git diff --check`、Release `TTestCase_FloatFacadeGuards`、Release `check`、串行 Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 Float Utility Facade Tail Guard Coverage

### Goal

继续把浮点公开 façade 的 utility 尾巴补成固定 `sbScalar` 的 direct guard，优先收口 `F64x2Dot`、`F32x8Dot/Select/ExtractInsert`，以及 `F64x4Rcp/Dot/Select/ExtractInsert`。

### Phases

| Phase                              | Status    | Notes |
| ---------------------------------- | --------- | ----- |
| 1. 复核 float utility 当前证据层现状 | completed | 已确认 `F32x8/F64x4` 的 family-local suite 虽然固定 `sbScalar`，但 utility 面仍缺 public façade 直调：`F32x8` 主要缺 `Dot/Select/ExtractInsert`，`F64x4` 主要缺 `Rcp/Dot/Select/ExtractInsert`；同时已回源码确认两族并不存在公开的 `Load/Store/Splat/Zero` façade |
| 2. 补齐 float utility direct guard  | completed | 已在 `TTestCase_FloatFacadeGuards` 给 `F64x2` 补 `Dot` 断言，并在 `vecf32x8/vecf64x4` family-local scalar suite 中各新增 1 条 public utility façade 测试，不改生产实现 |
| 3. Release 验证与提交收口          | completed | `git diff --check`、Release targeted suite、Release `check`、串行 Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 F32x4 Utility Facade Tail Guard Coverage

### Goal

继续把 `F32x4` 公开 façade 里仍主要停留在 parity 或非 scalar-direct 测试层的 utility 尾巴补成固定 `sbScalar` 的 direct guard，优先收口 `Zero/LoadAligned/StoreAligned/Select`，并顺手把 `Extract/Insert` 放进同一条 façade contract 证据链。

### Phases

| Phase                              | Status    | Notes |
| ---------------------------------- | --------- | ----- |
| 1. 复核 `F32x4` utility 当前证据层现状 | completed | 已确认 `TTestCase_VectorOps` 虽然固定 `sbScalar`，但只覆盖 `Add/Sub/Mul/Div`、基础 math、`Load/Store/Splat/Compare/Dot/Length/Normalize`；`Zero/LoadAligned/StoreAligned/Select` 仍主要停留在 `dispatchapi` parity，而 `Extract/Insert` 主要落在 `ShuffleSWizzle/EdgeCases` 非 scalar-direct 面 |
| 2. 扩展现有 scalar direct suite     | completed | 继续扩已固定 `sbScalar` 的 `TTestCase_VectorOps`，新增 `Test_VecF32x4_UtilityFacade_Basic` 覆盖 `Zero/LoadAligned/StoreAligned/Select/Extract/Insert`，不新增 runner/suite，也不改实现 |
| 3. Release 验证与提交收口          | completed | `git diff --check`、Release `TTestCase_VectorOps`、Release `check`、串行 Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 Shuffle Swizzle Facade Scalarization

### Goal

继续把 `shuffle/swizzle` 这一簇公开 façade 从“普通行为测试”收成固定 `sbScalar` 的 direct guard，优先覆盖 `F32x4/F64x2/I32x4` 的 `Shuffle/Shuffle2/Blend/Unpack/Broadcast/Reverse/Rotate/Insert/Extract`。

### Phases

| Phase                              | Status    | Notes |
| ---------------------------------- | --------- | ----- |
| 1. 复核 `shuffle/swizzle` 当前证据层现状 | completed | 已确认 `TTestCase_ShuffleSWizzle` 现有覆盖面其实很全，但 suite 自身没有 `SetUp/TearDown`；这些公开 façade 主要只在普通行为测试里出现，`dispatchapi/direct` 也没有把它们补成 fixed-`sbScalar` direct guard |
| 2. 收敛为 scalar direct suite      | completed | 未新开 runner，也未补重复 testcase；直接给 `TTestCase_ShuffleSWizzle` 加 `SetUp/TearDown`，统一固定 `ForceBackend(sbScalar)` / `ResetBackendSelection`，把现有 `F32x4/F64x2/I32x4` shuffle/blend/unpack/broadcast/reverse/rotate/insert/extract` 全部收进 façade direct evidence |
| 3. Release 验证与提交收口          | completed | `git diff --check`、Release `TTestCase_ShuffleSWizzle`、Release `check`、串行 Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 Gather Scatter Facade Scalarization

### Goal

继续把 `Gather/Scatter` 这一簇公开 façade 从“普通行为测试”收成固定 `sbScalar` 的 direct guard，优先覆盖 `VecF32x4Gather/Scatter` 与 `VecI32x4Gather/Scatter`。

### Phases

| Phase                              | Status    | Notes |
| ---------------------------------- | --------- | ----- |
| 1. 复核 `Gather/Scatter` 当前证据层现状 | completed | 已确认 `TTestCase_GatherScatter` 现有覆盖面已经覆盖 `F32x4/I32x4` 的 gather/scatter 与零索引/大跨步边界，但 suite 自身没有 `SetUp/TearDown`，而 `dispatchapi/direct` 也没有把这簇补成 fixed-`sbScalar` direct guard |
| 2. 收敛为 scalar direct suite      | completed | 未新开 runner，也未复制 testcase；直接给 `TTestCase_GatherScatter` 增加 `SetUp/TearDown`，统一固定 `ForceBackend(sbScalar)` / `ResetBackendSelection`，把现有 gather/scatter 测试整体升级成 façade direct evidence |
| 3. Release 验证与提交收口          | completed | `git diff --check`、Release `TTestCase_GatherScatter`、Release `check`、串行 Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 Math Functions Facade Scalarization

### Goal

继续把 `MathFunctions` 这一簇公开 façade 从“普通行为测试”收成固定 `sbScalar` 的 direct guard，优先覆盖 `VecF32x4` 的三角、指数/对数与反三角函数族。

### Phases

| Phase                              | Status    | Notes |
| ---------------------------------- | --------- | ----- |
| 1. 复核 `MathFunctions` 当前证据层现状 | completed | 已确认 `TTestCase_MathFunctions` 现有覆盖面已包含 `VecF32x4Sin/Cos/SinCos/Tan/Exp/Exp2/Log/Log2/Log10/Pow/Asin/Acos/Atan/Atan2`，但 suite 自身没有 `SetUp/TearDown`，而其余测试面对这簇 mainly 仍是 edgecase / parity 旁证 |
| 2. 收敛为 scalar direct suite      | completed | 未新开 runner，也未复制 testcase；直接给 `TTestCase_MathFunctions` 增加 `SetUp/TearDown`，统一固定 `ForceBackend(sbScalar)` / `ResetBackendSelection`，把现有 math façade 测试整体升级成 direct evidence |
| 3. Release 验证与提交收口          | completed | `git diff --check`、Release `TTestCase_MathFunctions`、Release `check`、串行 Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 Advanced Algorithms Facade Scalarization

### Goal

继续把 `AdvancedAlgorithms` 这一簇公开 façade 从“普通行为测试”收成固定 `sbScalar` 的 direct guard，优先覆盖 `SortNet`、`PrefixSum` 与 `StrFindChar` 相关算法入口。

### Phases

| Phase                              | Status    | Notes |
| ---------------------------------- | --------- | ----- |
| 1. 复核 `AdvancedAlgorithms` 当前证据层现状 | completed | 已确认 `TTestCase_AdvancedAlgorithms` 现有覆盖面已包含 `SortNet4/8`、`PrefixSumI32x4/F32x4`、`PrefixSumArrayI32/F32` 与 `StrFindChar`，但 suite 自身没有 `SetUp/TearDown`，其余测试面对这簇主要仍是 edgecase / checklist 旁证 |
| 2. 收敛为 scalar direct suite      | completed | 未新开 runner，也未复制 testcase；直接给 `TTestCase_AdvancedAlgorithms` 增加 `SetUp/TearDown`，统一固定 `ForceBackend(sbScalar)` / `ResetBackendSelection`，把现有算法 façade 测试整体升级成 direct evidence |
| 3. Release 验证与提交收口          | completed | `git diff --check`、Release `TTestCase_AdvancedAlgorithms`、Release `check`、串行 Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 Global Facade Scalarization

### Goal

继续把 `Global` 这一簇公开全局 façade 从“普通行为测试”收成固定 `sbScalar` 的 direct guard，优先覆盖内存、统计、文本、搜索与位集函数入口。

### Phases

| Phase                              | Status    | Notes |
| ---------------------------------- | --------- | ----- |
| 1. 复核 `Global` 当前证据层现状 | completed | 已确认 `TTestCase_Global` 现有覆盖面已包含 `MemEqual/MemFindByte/MemDiffRange/MemCopy/MemSet/MemReverse`、`SumBytes/MinMaxBytes/CountByte`、`Utf8Validate/AsciiIEqual/ToLowerAscii/ToUpperAscii`、`BytesIndexOf`、`BitsetPopCount`，但 suite 自身没有 `SetUp/TearDown`；而跨 backend 旁证则由 `TTestCase_BackendConsistency` 另行承担 |
| 2. 收敛为 scalar direct suite      | completed | 未新开 runner，也未复制 testcase；直接给 `TTestCase_Global` 增加 `SetUp/TearDown`，统一固定 `ForceBackend(sbScalar)` / `ResetBackendSelection`，把现有全局 façade 测试整体升级成 direct evidence |
| 3. Release 验证与提交收口          | completed | `git diff --check`、Release `TTestCase_Global`、Release `check`、串行 Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 Type Conversion Facade Scalarization

### Goal

继续把 `TypeConversion` 这一簇公开转换 façade 从“普通行为测试”收成固定 `sbScalar` 的 direct guard，优先覆盖 `IntoBits/FromBits`、`Cast`、`Widen/Narrow` 与 `F32/F64` 精度转换入口。

### Phases

| Phase                              | Status    | Notes |
| ---------------------------------- | --------- | ----- |
| 1. 复核 `TypeConversion` 当前证据层现状 | completed | 已确认 `TTestCase_TypeConversion` 现有覆盖面已包含 `VecF32x4IntoBits/VecI32x4FromBitsF32`、`VecF64x2IntoBits/VecI64x2FromBitsF64`、`VecF32x4CastToI32x4/VecI32x4CastToF32x4`、`VecF64x2CastToI64x2/VecI64x2CastToF64x2`、`VecI16x8WidenLoI32x4/VecI16x8WidenHiI32x4/VecI32x4NarrowToI16x8`、`VecF32x4ToF64x2Lo/VecF64x2ToF32x4`，但 suite 自身没有 `SetUp/TearDown` |
| 2. 收敛为 scalar direct suite      | completed | 未新开 runner，也未复制 testcase；直接给 `TTestCase_TypeConversion` 增加 `SetUp/TearDown`，统一固定 `ForceBackend(sbScalar)` / `ResetBackendSelection`，把现有转换 façade 测试整体升级成 direct evidence |
| 3. Release 验证与提交收口          | completed | `git diff --check`、Release `TTestCase_TypeConversion`、Release `check`、串行 Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 Vector Mask Facade Scalarization

### Goal

继续把 `VectorMaskTypes` 这一簇公开 mask façade 从“普通行为测试”收成固定 `sbScalar` 的 direct guard，优先覆盖 `MaskF32x4*`、`MaskI32x4*`、`MaskF64x2*` 与 `MaskF32x4Select`。

### Phases

| Phase                              | Status    | Notes |
| ---------------------------------- | --------- | ----- |
| 1. 复核 `VectorMaskTypes` 当前证据层现状 | completed | 已确认 `TTestCase_VectorMaskTypes` 现有覆盖面已包含 `MaskF32x4AllTrue/AllFalse/Set/Test/ToBitmask/Any/All/None`、掩码逻辑运算 `and/or/xor/not`、`MaskI32x4AllTrue/ToBitmask`、`MaskF64x2AllTrue/ToBitmask` 与 `MaskF32x4Select`，但 suite 自身没有 `SetUp/TearDown` |
| 2. 收敛为 scalar direct suite      | completed | 未新开 runner，也未复制 testcase；直接给 `TTestCase_VectorMaskTypes` 增加 `SetUp/TearDown`，统一固定 `ForceBackend(sbScalar)` / `ResetBackendSelection`，把现有 mask façade 测试整体升级成 direct evidence |
| 3. Release 验证与提交收口          | completed | `git diff --check`、Release `TTestCase_VectorMaskTypes`、Release `check`、串行 Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 Large Data Global Facade Scalarization

### Goal

继续把 `LargeData` 这一簇大尺寸/非对齐/odd-size 的公开全局 façade 测试，从“普通边界回归”收成固定 `sbScalar` 的 direct guard，优先覆盖 `MemEqual/SumBytes/MemFindByte/CountByte`。

### Phases

| Phase                              | Status    | Notes |
| ---------------------------------- | --------- | ----- |
| 1. 复核 `LargeData` / `UnsignedVectorTypes` 优先级 | completed | 已确认 `TTestCase_LargeData` 真实调用的是公开全局 façade `MemEqual/SumBytes/MemFindByte/CountByte`，覆盖 1MB、非对齐和 odd-size 合约；相比之下 `TTestCase_UnsignedVectorTypes` 主要是 typedef/layout/raw-access 断言，因此本轮优先级更低 |
| 2. 收敛 `LargeData` 为 scalar direct suite | completed | 未新开 runner，也未复制 testcase；直接给 `TTestCase_LargeData` 增加 `SetUp/TearDown`，统一固定 `ForceBackend(sbScalar)` / `ResetBackendSelection`，把现有大数据边界 façade 测试整体升级成 direct evidence |
| 3. Release 验证与提交收口          | completed | `git diff --check`、Release `TTestCase_LargeData`、Release `check`、串行 Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 Saturating Arithmetic Facade Scalarization

### Goal

继续把 `SaturatingArithmetic` 这一簇饱和算术 façade 从“普通边界行为测试”收成固定 `sbScalar` 的 direct guard，优先覆盖 `VecI8x16Sat*`、`VecI16x8Sat*`、`VecU8x16Sat*` 与 `VecU16x8Sat*`。

### Phases

| Phase                              | Status    | Notes |
| ---------------------------------- | --------- | ----- |
| 1. 复核剩余未 scalarize public suites 优先级 | completed | 已确认 `dispatch/dataplane/publicabi/runtime/concurrent` 属于控制面/并发面，不适合按 `sbScalar` 套；`memutils aliases` 与 `vec512types` 里混有较多别名/类型层断言，而 `TTestCase_SaturatingArithmetic` 直接覆盖公开饱和算术 façade contract，优先级更高 |
| 2. 收敛 `SaturatingArithmetic` 为 scalar direct suite | completed | 未新开 runner，也未复制 testcase；直接给 `TTestCase_SaturatingArithmetic` 增加 `SetUp/TearDown`，统一固定 `ForceBackend(sbScalar)` / `ResetBackendSelection`，把现有饱和算术 façade 测试整体升级成 direct evidence |
| 3. Release 验证与提交收口          | completed | `git diff --check`、Release `TTestCase_SaturatingArithmetic`、Release `check`、串行 Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 Vec512 Object Mask Facade Guard Extraction

### Goal

继续清理 `vec512types` 的“缺失与冗余”混合问题：不整包 scalarize，也不复制 testcase，只把真正仍缺 fixed-`sbScalar` direct evidence 的 `TMaskF32x16` / 对象掩码 façade 层拆成独立 guard suite。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `vec512types` 的真实剩余价值 | completed | 已确认 `VecF32x16/VecF64x8/VecI32x16/VecI64x8` 大量 512-bit façade 算术与 plain-mask contract 已被 `TTestCase_FloatFacadeGuards`、`TTestCase_IntegerFacadeGuards` 与 `dispatchapi` 旁证覆盖；真正还值得 direct-guard 化的是返回 `TMaskF32x16` 的对象掩码 façade |
| 2. 提取对象掩码 façade guard suite | completed | 在 `fafafa.core.simd.vec512types.testcase.pas` 新增 `TTestCase_Vec512MaskFacadeGuards`，补 `SetUp/TearDown` 固定 `ForceBackend(sbScalar)` / `ResetBackendSelection`，并把 `AllTrue/AllFalse/ToBitmask/Any-All-None/CmpEq/CmpLt/LogicOps/Select` 8 个方法从混合型 `TTestCase_Vec512Types` 迁出 |
| 3. Release 验证与提交收口 | completed | 首轮定向验证先暴露 runner 集成缺口：`fafafa.core.simd.test.lpr` 的 `HandleSuite` 清单未纳入新 suite；补齐后，`git diff --check`、Release `TTestCase_Vec512MaskFacadeGuards`、Release `check`、串行 Release `gate` 全绿，并已清理 `tests/fafafa.core.simd/__pycache__/` |

## 2026-05-14 ImageProc Facade Scalarization

### Goal

继续把高价值 public façade suite 收回 fixed-`sbScalar` contract 语义，优先处理 `fafafa.core.simd.imageproc` 这一整簇公开图像 API，而不是回头去做 `UnsignedVectorTypes` 或 `memutils aliases` 这类低价值类型/别名测试。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `ImageProc` 与剩余候选优先级 | completed | 已确认 `TTestCase_ImageProc` 覆盖的是 `CreateImage/FreeImage/GetPixelRGB/SetPixelRGB/ImageAdd/Subtract/Multiply/Blend/RGBToGrayscale/GrayscaleToRGB/ApplyBrightness/Contrast/Gamma/GaussianBlur/Sharpen/EdgeDetection` 等真实公开 API；相比之下 `UnsignedVectorTypes`、`RustStyleAliases`、`Memutils` 更偏 typedef/layout/alias/tooling 层 |
| 2. 收敛 `ImageProc` 为 scalar direct suite | completed | 保留原有 fixture 生命周期与 alpha-mode 恢复逻辑，只补 `fafafa.core.simd.base` / `fafafa.core.simd.dispatch` 依赖，并在 `SetUp/TearDown` 中加入 `ForceBackend(sbScalar)` / `ResetBackendSelection` |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_ImageProc`、Release `check`、串行 Release `gate` 全绿，并已清理 `tests/fafafa.core.simd/__pycache__/` |

## 2026-05-14 Builder Facade Scalarization

### Goal

继续把高价值 public façade suite 收回 fixed-`sbScalar` contract 语义，优先处理 `TVecF32x4Builder` 这一层 fluent builder façade，而不是回头去做 `UnsignedVectorTypes`、`RustStyleAliases`、`Memutils` 或控制面 suite。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `Builder` 与剩余候选优先级 | completed | 已确认 `TTestCase_Builder` 覆盖的是 `FromValues/Splat/Load/Build/Add/MulScalar/AddScalar/Normalize/Clamp/ReduceAdd/ReduceMin/ReduceMax/Lerp` 等真实 public builder façade；相比之下 `UnsignedVectorTypes`、`RustStyleAliases`、`Memutils` 更偏 typedef/layout/alias/tooling 层，而 `dispatch/dataplane/publicabi/runtime/concurrent` 属于控制面/并发面 |
| 2. 收敛 `Builder` 为 scalar direct suite | completed | 未新开 runner，也未复制 testcase；直接给 `TTestCase_Builder` 增加 `SetUp/TearDown`，统一固定 `ForceBackend(sbScalar)` / `ResetBackendSelection`，把现有 builder façade 测试整体升级成 direct evidence |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_Builder`、Release `check`、串行 Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 EdgeCases Scalarization

### Goal

继续把仍有高价值 contract 的边界语义测试收回 fixed-`sbScalar` 语义，优先处理 `TTestCase_EdgeCases` 这一簇 NaN/Inf/overflow/unaligned/index-saturation 边界，而不是回头去做 `UnsignedVectorTypes`、`RustStyleAliases`、`Memutils` 这类低价值类型/工具层测试。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `EdgeCases` 与剩余候选优先级 | completed | 已确认 `TTestCase_EdgeCases` 覆盖的是 `VecF32x4 +/-/*//` 的 NaN/Inf contract、`SortNet4F32` 的 NaN 排序语义、`VecI32x4` overflow、`PrefixSumI32` overflow、`MemEqual/MemFindByte/SumBytes` 的极端非对齐/跨页行为，以及 `VecF32x4Extract/Insert` index saturation；虽然混有少量 `utils` helper 边界，但语义价值仍明显高于 `UnsignedVectorTypes`、`RustStyleAliases`、`Memutils` |
| 2. 收敛 `EdgeCases` 为 scalar direct suite | completed | 不新开 runner，也不复制 testcase；在保留 FPU exception mask fixture 的前提下，直接给 `TTestCase_EdgeCases` 增加 `ForceBackend(sbScalar)` / `ResetBackendSelection`，把现有边界 contract 测试整体升级成 direct evidence |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_EdgeCases`、Release `check`、串行 Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 VecI32x8 Family Scalarization

### Goal

继续把仍停留在“默认后端 family suite”层的公开 256-bit family contract 收回 fixed-`sbScalar` 语义，优先处理 `TTestCase_VecI32x8`，而不是回头去做 `UnsignedVectorTypes`、`RustStyleAliases`、`Memutils` 这类低价值类型/工具层测试。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `VecI32x8` 与剩余候选优先级 | completed | 已确认 `TTestCase_VecI32x8` 覆盖的是 `Add/Sub/Mul/Neg`、`And/Or/Xor/Not/AndNot`、`ShiftLeft/ShiftRight`、`CmpEq/Lt/Gt/Le/Ge/Ne`、`Min/Max`、`Splat/Zero/LoadStore/SizeOf` 与 overflow/max-min 边界；相比之下 `UnsignedVectorTypes`、`RustStyleAliases`、`Memutils` 更偏 typedef/layout/alias/tooling 层，而 `PublicAbi`、`SSE2Contracts` 属于控制面或 backend-owned 合同 |
| 2. 收敛 `VecI32x8` 为 scalar direct suite | completed | 不新开 runner，也不复制 testcase；补齐 `fafafa.core.simd.base` 依赖，并直接给 `TTestCase_VecI32x8` 增加 `ForceBackend(sbScalar)` / `ResetBackendSelection`，把现有 family suite 升级成 fixed-`sbScalar` 的 direct evidence |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_VecI32x8`、Release `check`、串行 Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 IEEE754 Fixture Mask Restore

### Goal

继续加强审查混合型 IEEE754 suites，优先修复真实 fixture 泄漏，而不是继续机械做 scalarization：让 `TTestCase_IEEE754_F64`、`TTestCase_IEEE754EdgeCases` 与 `TTestCase_AVX2RoundTruncIEEE754` 在 `SetUp` 修改 FPU exception mask 后，`TearDown` 必须恢复原始 mask。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `ieee754.testcase` 的真实风险点 | completed | 已确认这三组 suite 都会在 `SetUp` 里 `SetExceptionMask([...])`，但 `TearDown` 只做 `ResetToAutomaticBackend`，没有恢复原始 FPU mask；对比 `EdgeCases` 与多个局部测试的 `savedMask -> SetExceptionMask(savedMask)` 模式，这属于真实测试层状态泄漏 |
| 2. 修复 FPU mask fixture 泄漏 | completed | 给 `TTestCase_IEEE754_F64`、`TTestCase_IEEE754EdgeCases` 与 `TTestCase_AVX2RoundTruncIEEE754` 各自增加 `FSavedExceptionMask`，在 `SetUp` 里先 `GetExceptionMask` 再改 mask，并在 `TearDown` 里恢复原始 mask，同时保留既有 backend reset 语义不变 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_IEEE754_F64,TTestCase_IEEE754EdgeCases,TTestCase_AVX2RoundTruncIEEE754`、Release `check`、串行 Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 Fixture Backend Restore Symmetry

### Goal

继续沿 `publicabi / sse2contracts / dataplane / concurrent` 高价值 suite 做 fixture 生命周期审查，优先修复“进入测试前有强制 backend 选择，但测试结束后被静默丢成 automatic”的全局状态泄漏，而不是回头处理低价值 alias/type suite。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核高价值 suite 的状态恢复对称性 | completed | 已确认 `publicabi.testcase` 的 `SetUp/TearDown` 只会通过 `ResetPublicAbiSyntheticHookState` 强制落到 `vector asm=False + automatic backend`；`sse2contracts`、`dataplane` 及 `concurrent` 相关 suite 也普遍只恢复 `vector asm`，却没有恢复进入测试前的 active backend 选择 |
| 2. 修复 fixture backend restore 泄漏 | completed | 给 `TTestCase_PublicAbi`、`TTestCase_SSE2Contracts`、`TTestCase_DataPlane` 增加保存/恢复进入测试前 `vector asm + current backend` 的夹具逻辑，并在 `concurrent.testcase` 提取 `TSimdStatefulTestCase` 统一为 `TTestCase_SimdConcurrent*` 四个 suite 做同样的恢复 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_PublicAbi,TTestCase_DataPlane,TTestCase_SSE2Contracts,TTestCase_SimdConcurrent,TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework,TTestCase_SimdConcurrentRegistration`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 IEEE754 Fixture State Restore Symmetry

### Goal

继续沿 mixed/control-plane 高价值测试面审查 `ieee754.testcase`，修复“已恢复 FPU exception mask，但仍把进入测试前 backend/vector-asm 选择静默丢成 automatic”的夹具状态泄漏。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `ieee754.testcase` 的剩余状态泄漏 | completed | 已确认上一批只修了 `FSavedExceptionMask`；但 `TTestCase_IEEE754_F64` 的 `SetUp` 会强制 `sbScalar`，`TTestCase_IEEE754EdgeCases`、`TTestCase_AVX2RoundTruncIEEE754` 与 `TTestCase_NonX86IEEE754` 也都会在测试中切 `vector asm/backend`，而文件级 fixture 结束时仍只回到 `automatic`，没有恢复进入测试前的真实 backend 选择 |
| 2. 修复 IEEE754 fixture backend/vector-asm 恢复不对称 | completed | 给 `TTestCase_IEEE754_F64`、`TTestCase_IEEE754EdgeCases`、`TTestCase_AVX2RoundTruncIEEE754` 增加 `FSavedVectorAsm/FSavedBackend`，并给 `TTestCase_NonX86IEEE754` 增加 `SetUp/TearDown` 保存/恢复进入测试前状态；恢复顺序保持为先还原 `vector asm`，再 `ResetToAutomaticBackend`，必要时 `TrySetActiveBackend(savedBackend)` |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_IEEE754_F64,TTestCase_IEEE754EdgeCases,TTestCase_AVX2RoundTruncIEEE754,TTestCase_NonX86IEEE754`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 Direct Fixture State Restore Symmetry

### Goal

继续沿 control-plane 高价值 suite 审查 `direct.testcase`，修复其大量 multi-backend parity / concurrent 测试在结束时只回 `automatic`、却不恢复进入测试前 backend/vector-asm 选择的夹具泄漏。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `direct.testcase` 的 fixture 恢复对称性 | completed | 已确认 `TTestCase_DirectDispatch` 与 `TTestCase_DirectDispatchConcurrent` 都没有 fixture 级 `SetUp/TearDown`；大量测试方法与 `RunDirectDispatchConcurrentReRegisterSnapshotConsistency` 结束时只做 `ResetToAutomaticBackend`，有些还会切 `SetVectorAsmEnabled(True/False)`，但不会恢复进入测试前的真实 backend 选择 |
| 2. 修复 direct suite 的状态恢复泄漏 | completed | 在 `fafafa.core.simd.direct.testcase.pas` 提取 `TDirectDispatchStatefulTestCase`，统一给 `TTestCase_DirectDispatch` 与 `TTestCase_DirectDispatchConcurrent` 保存/恢复进入测试前的 `vector asm + current backend`，避免逐个改动几十个 test body |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 Backend Consistency Helper State Restore

### Goal

继续沿高价值 control-plane/helper 测试往下审查 `backend.consistency.testcase`，修复其 helper-style consistency 测试与 `TTestCase_BackendVectorConsistency` wrapper 在结束时只回 `automatic`、却不恢复进入前 backend 选择的状态泄漏，并补上可证伪的强制-backend 回归点。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `backend.consistency.testcase` 与外层 wrapper 的状态恢复对称性 | completed | 已确认 7 个 helper-style consistency 函数都在切 `TrySetActiveBackend/SetActiveBackend(sbScalar)/SetActiveBackend(backend)` 后只 `ResetToAutomaticBackend`；`TTestCase_BackendVectorConsistency.Test_VectorOps_Consistency` 末尾也只回 automatic |
| 2. 修复 helper 与 wrapper 的 backend 恢复泄漏，并补回归点 | completed | 在 `backend.consistency.testcase` 提取 `SaveBackendConsistencyState/RestoreBackendConsistencyState`，统一恢复进入前 backend；同时让 `TTestCase_BackendVectorConsistency` 恢复进入前 backend，并新增 `Test_VectorOps_Helper_Preserves_PreviousForcedBackend` 与 `Test_VectorOps_Consistency_Preserves_PreviousForcedBackend` |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_BackendVectorConsistency`、Release `check`、Release `gate` 全绿 |

## 2026-05-14 DispatchAPI Fixture State Restore

### Goal

继续沿最密集的 control-plane suite 审查 `dispatchapi.testcase`，通过类级 fixture 保存/恢复 `vector asm + current backend`，修复 `TTestCase_DispatchAPI` 大量测试在结束时只回 `automatic`、却不恢复进入前 backend 选择的状态泄漏。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `TTestCase_DispatchAPI` 的状态恢复对称性 | completed | 已确认类本身没有 fixture 级 `SetUp/TearDown`；大量测试只在局部 finally 中恢复 `vector asm` 或 `ResetToAutomaticBackend`，没有统一恢复进入前 backend 选择 |
| 2. 提取类级 fixture 恢复层 | completed | 在 `dispatchapi.testcase` 提取 `TDispatchAPIStatefulTestCase`，统一保存/恢复进入前的 `vector asm + current backend`，并让 `TTestCase_DispatchAPI` 继承它 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DispatchAPI`、Release `check`、Release `gate` 全绿 |

## 2026-05-14 DispatchAPI Companion Classes Fixture State Restore

### Goal

继续沿 `dispatchapi.testcase` 的剩余 companion 类审查状态恢复对称性，复用现有 `TDispatchAPIStatefulTestCase`，修复 `TTestCase_X86MaskedFmaContract`、`TTestCase_RISCVVMaskedOpsContract`、`TTestCase_RISCVFallbackDispatchContract`、`TTestCase_NonX86BackendParity` 在结束时不能统一恢复进入前 backend/vector-asm 状态的夹具泄漏。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 companion 类的状态恢复对称性 | completed | 已确认 4 个类都仍然裸继承 `TTestCase`，但内部会切 `SetVectorAsmEnabled(True/False)`、`TrySetActiveBackend(...)` 或 `ResetToAutomaticBackend`，没有统一 fixture 恢复层 |
| 2. 复用现有 stateful fixture 基类 | completed | 让 `TTestCase_X86MaskedFmaContract`、`TTestCase_RISCVVMaskedOpsContract`、`TTestCase_RISCVFallbackDispatchContract`、`TTestCase_NonX86BackendParity` 全部继承 `TDispatchAPIStatefulTestCase` |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release companion suites、Release `check`、Release `gate` 全绿 |

## 2026-05-14 DispatchSlots Fixture Backend Restore

### Goal

继续沿剩余裸 `TTestCase` + backend 切换热点审查 `dispatchslots.testcase`，通过类级 fixture 保存/恢复进入测试前 backend，修复 `TTestCase_DispatchAllSlots` 结束时只回 `automatic`、却不恢复进入前强制 backend 选择的状态泄漏。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `TTestCase_DispatchAllSlots` 的状态恢复对称性 | completed | 已确认多个测试会遍历 `TrySetActiveBackend(...)` 或直接 `ResetToAutomaticBackend`，但类本身没有 fixture 级 `SetUp/TearDown` |
| 2. 提取类级 backend 恢复层 | completed | 在 `TTestCase_DispatchAllSlots` 增加 `FSavedBackend` 与 `SetUp/TearDown`，统一保存/恢复进入测试前 backend |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DispatchAllSlots`、Release `check`、Release `gate` 全绿 |

## 2026-05-14 Simd.TestCase Stateful Fixture Consolidation

### Goal

继续沿主入口 `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` 审查 fixture 恢复对称性，统一修复 `Global`、`BackendSmoke`、`AVX2/AVX512VectorAsm` 和一串强制 `sbScalar` 的 façade suite 在结束时只回 `automatic`、却不恢复进入测试前 backend/vector-asm 状态的泄漏，并顺手去掉重复 `SetUp/TearDown` 样板。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `simd.testcase` 主文件里的状态泄漏与重复夹具 | completed | 已确认 `TTestCase_Global`、`TTestCase_BackendSmoke`、`TTestCase_AVX2VectorAsm`、`TTestCase_AVX512VectorAsm` 以及 `VectorOps/IntegerFacadeGuards/FloatFacadeGuards/LargeData/OperatorOverloads/VectorMaskTypes/TypeConversion/Builder/GatherScatter/ShuffleSWizzle/MathFunctions/AdvancedAlgorithms` 都存在同类问题：切 backend 或 vector-asm 后只 `ResetBackendSelection`，没有恢复进入测试前真实状态 |
| 2. 抽共享 stateful fixture 并替换重复 `SetUp/TearDown` | completed | 在 `fafafa.core.simd.testcase.pas` 提取 `TSimdBackendStatefulTestCase`、`TScalarBackendStatefulTestCase` 与 `TSimdVectorAsmBackendStatefulTestCase`；让 `Global/BackendSmoke/AVX2/AVX512` 与整串 scalar suite 统一继承，恢复顺序固定为先恢复 `vector asm`，再 `ResetBackendSelection`，必要时 `TrySetActiveBackend(savedBackend)` |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_Global`、`TTestCase_BackendSmoke`、`TTestCase_AVX2VectorAsm`、`TTestCase_IntegerFacadeGuards`、Release `check`、Release `gate` 全绿；过程中已确认并行跑同一 Lazarus runner 会产生 `Text file busy/rc=2` 假红，因此最终验证全部改回串行 |

## 2026-05-14 Scalarized Small Suites Backend Restore

### Goal

继续沿分散的小型 façade/test utility suite 审查“已经 scalarize，但 `TearDown` 仍只回 automatic”的残余状态泄漏，统一修复 `edgecases/vecf32x8/vecf64x4/veci32x8/vecu32x8/narrowintegerops/imageproc/saturating/vec512types` 这一批小文件对进入测试前 backend 选择的不对称恢复。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核小型 scalarized suite 的状态恢复模式 | completed | 已确认 `TTestCase_EdgeCases`、`TTestCase_VecF32x8`、`TTestCase_VecF64x4`、`TTestCase_VecI32x8`、`TTestCase_VecU32x8`、`TTestCase_NarrowIntegerOps`、`TTestCase_ImageProc`、`TTestCase_SaturatingArithmetic`、`TTestCase_Vec512MaskFacadeGuards` 都在 `SetUp` 里 `ForceBackend(sbScalar)`，但 `TearDown` 仍只 `ResetBackendSelection` |
| 2. 给 9 个 suite 补进入前 backend 保存/恢复 | completed | 为每个类补 `FSavedBackend`，`SetUp` 保存 `GetCurrentBackend`，`TearDown` 在保留原有异常 mask / image resource / blend-mode 清理顺序的同时，统一 `ResetBackendSelection` 并在必要时 `TrySetActiveBackend(savedBackend)` |
| 3. Release 验证与提交收口 | completed | 9 个受影响 suite 的定向 Release 测试、Release `check`、Release `gate` 全绿；这批没有新增 runner 或改动任何生产实现 |

## 2026-05-14 Direct Local Restore Consolidation

### Goal

继续沿 `direct.testcase` 深审 method-level 状态恢复，修复 `TTestCase_DirectDispatch` 在内部临时切 backend/vector-asm 后只回 `automatic`、却不恢复进入测试前 direct/backend 状态的局部不对称，并补最小回归断言。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `direct.testcase` 剩余的局部恢复不对称 | completed | 已确认类级 fixture 虽然已存在，但 `Rebind_AfterForceBackend`、`AutoRebind_AfterDispatchSetActiveBackend` 与大量 multi-backend parity test 的 `finally` 仍只 `ResetToAutomaticBackend`，会抹掉进入测试前的 forced backend 语义 |
| 2. 抽 direct-local restore helper 并替换局部 finally | completed | 在 `TDirectDispatchStatefulTestCase` 提取 `RestoreFixtureDirectDispatchState`，统一恢复保存的 `vector asm + backend` 并 `RebindDirectDispatch`；同时让两条前导 smoke test 显式断言路径跑完后会回到原 backend，`WideIntegerHelperMatrix_Parity` 去掉局部 `LOldVectorAsm` 样板 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DirectDispatch`、Release `TTestCase_DirectDispatchConcurrent`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 PublicAbi Local Restore Consolidation

### Goal

继续沿 `publicabi.testcase` 深审 method-level 状态恢复冗余，先收掉一批完全同构的外层 `LOldVectorAsm + ResetToAutomaticBackend` 样板，让 `public ABI` 测试在结束时统一回到进入测试前 `vector asm + backend` 状态。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `publicabi.testcase` 的类级与局部恢复模式 | completed | 已确认文件虽有 `SetUp/TearDown` 保存 `FSavedVectorAsm/FSavedBackend`，但仍残留大量外层 `finally` 只恢复 `LOldVectorAsm` 并 `ResetToAutomaticBackend`，没有复用类级保存状态 |
| 2. 提取 local restore helper 并替换同构 finally | completed | 在 `TTestCase_PublicAbi` 提取 `RestorePublicAbiLocalState`，统一恢复 `vector asm + backend`；已覆盖 `VectorAsmRoundTrip`、`ActiveBackendId/StableState`、`FailedHookMutation`、`RollbackRestore`、以及 `HookLateForce/AutomaticReset/RegisterBackend/DataPlaneParity` 路径里剩余的 simple exact-pattern 外层 finally |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_PublicAbi`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 Concurrent Local Restore Consolidation

### Goal

继续沿 `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` 深审 method-level 状态恢复冗余，先收掉 `TSimdStatefulTestCase` 之下那批完全同构的外层 `LOldVectorAsm + ResetToAutomaticBackend` finally 样板，让 concurrent/public-framework/registration 控制面测试也统一回到进入测试前的 `vector asm + backend` 状态。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `concurrent.testcase` 的类级与局部恢复模式 | completed | 已确认 `TSimdStatefulTestCase` 本身已保存 `FSavedVectorAsm/FSavedBackend` 并在 `TearDown` 恢复，但 `TTestCase_SimdConcurrentPublicAbi`、`TTestCase_SimdConcurrentFramework`、`TTestCase_SimdConcurrentRegistration` 与 `DispatchMixed_ControlPlane` 仍残留一批外层 `finally` 只恢复 `LOldVectorAsm` 并 `ResetToAutomaticBackend` |
| 2. 提取 concurrent-local restore helper 并替换同构 finally | completed | 在 `TSimdStatefulTestCase` 提取 `RestoreSimdLocalState`，让 `TearDown` 也复用它；随后把 14 处 simple exact-pattern 外层 finally 统一切到 `RestoreSimdLocalState(LOldVectorAsm, FSavedBackend)`，不改内部轮次级 `ResetToAutomaticBackend` 语义块 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_SimdConcurrent,TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework,TTestCase_SimdConcurrentRegistration`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 DispatchAPI Local Restore Consolidation

### Goal

继续沿 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 深审 method-level 状态恢复冗余，复用现有 `TDispatchAPIStatefulTestCase`，把 control-plane 与后段 SSE2/AVX/SSE4.x 语义 parity 测试里成批 outer finally 的 `vector asm + automatic reset` 两行样板统一收回 helper。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `dispatchapi.testcase` 的类级与局部恢复模式 | completed | 已确认文件虽然已有 `TDispatchAPIStatefulTestCase` 保存 `FSavedVectorAsm/FSavedBackend`，但 method-level 仍残留大量 outer finally 手写 `SetVectorAsmEnabled(LOldVectorAsm); ResetToAutomaticBackend;`，以及后段同义的反序 `ResetToAutomaticBackend; SetVectorAsmEnabled(LOldVectorAsm);` |
| 2. 提取 dispatchapi-local restore helper 并替换同构 finally | completed | 在 `TDispatchAPIStatefulTestCase` 提取 `RestoreDispatchApiLocalState`，让 `TearDown` 也复用它；随后先清掉前半段 control-plane/metadata 区的 26 处 exact-pattern outer finally，再清掉后半段 SSE2/AVX/SSE3/SSSE3/SSE4.x parity 区 8 处反序 outer finally |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DispatchAPI`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 DispatchAPI Pure VectorAsm Outer Finally Cleanup

### Goal

继续沿同一份 `dispatchapi.testcase` 深审 `TTestCase_DispatchAPI` 本体里剩余的 pure `SetVectorAsmEnabled(LOldVectorAsm)` outer finally，把这第三类局部恢复残余也统一收回 `RestoreDispatchApiLocalState`，但不越界去动 companion 类或内层 rollback/backend mutation 状态机块。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `TTestCase_DispatchAPI` 剩余 pure vector-asm-only outer finally | completed | 已确认前两批两行式 outer finally 清空后，`TTestCase_DispatchAPI` 本体里还残留 15 处 procedure 末尾只写 `SetVectorAsmEnabled(LOldVectorAsm);` 的 outer finally；这些路径同样会绕开已保存的 `FSavedBackend` |
| 2. 复用 `RestoreDispatchApiLocalState` 收掉第三类残余 | completed | 已把这 15 处 pure `vector asm` outer finally 统一切到 `RestoreDispatchApiLocalState(LOldVectorAsm, FSavedBackend)`；仍刻意保留 companion 类、纯 toggle 审计路径与内层 `ResetToAutomaticBackend` 状态机块不动 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DispatchAPI`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已再次清理 |

## 2026-05-14 DispatchAPI Capability And Companion Pure Outer Finally Cleanup

### Goal

继续纠偏 `dispatchapi.testcase` 的 pure `vector asm` 残余边界判断：把后段 `AVX512/NEON/RISCVV/AVX2/SSE3/SSSE3/SSE4.x` capability/override 路径和两条 `RISCVVMaskedOpsContract` companion contract 里剩余的 simple outer finally 也统一收回 `RestoreDispatchApiLocalState`，但仍然不碰长方法内部 helper finally 与复杂 rollback/backend mutation 块。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核上一批之后的剩余 pure outer finally 归属 | completed | 已确认上一批锁定的 15 处不是全部；继续复核后，又定位到 20 处新的 simple outer finally：`RISCVVMaskedOpsContract` 2 处 + `TTestCase_DispatchAPI` 后段 capability/public-ABI/override 路径 18 处 |
| 2. 复用 `RestoreDispatchApiLocalState` 收掉剩余顶层 simple outer finally | completed | 已把这 20 处纯 `SetVectorAsmEnabled(LOldVectorAsm)` 的顶层 outer finally 统一切到 `RestoreDispatchApiLocalState(LOldVectorAsm, FSavedBackend)`；长方法内部 local helper / nested procedure 的局部 finally 继续保留原位 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DispatchAPI`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已再次清理 |

## 2026-05-14 NonX86BackendParity Local Restore Cleanup

### Goal

继续沿 `dispatchapi.testcase` 里仍然继承 `TDispatchAPIStatefulTestCase` 的 companion parity 类深审，把 `TTestCase_NonX86BackendParity` 中剩余的 pure `SetVectorAsmEnabled(LOldVectorAsm)` 顶层 outer finally 统一收回 `RestoreDispatchApiLocalState`，同时保留 `FreeAligned(...)`、局部缓冲复位等本地资源清理顺序。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `TTestCase_NonX86BackendParity` 的剩余顶层 outer finally | completed | 已确认 `dispatchapi.testcase` 里剩余的顶层裸 `SetVectorAsmEnabled(LOldVectorAsm)` 已全部集中到 `TTestCase_NonX86BackendParity` 的 16 条 vector-asm parity test |
| 2. 复用 `RestoreDispatchApiLocalState` 收掉 companion parity 样板 | completed | 已把这 16 处顶层 outer finally 统一切到 `RestoreDispatchApiLocalState(LOldVectorAsm, FSavedBackend)`；对 `FreeAligned(...)`、局部 buffer 复位等 test-local 清理语句保持原有相对顺序 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DispatchAPI,TTestCase_NonX86BackendParity`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已再次清理 |

## 2026-05-14 NonX86BackendParity Backend Restore Cleanup

### Goal

继续沿同一组 `TTestCase_NonX86BackendParity` 做更细一层收口：把 12 处顶层 `finally ResetToAutomaticBackend;` 从“回 automatic”改成恢复进入测试前保存的 `FSavedVectorAsm + FSavedBackend`，并保留 `RandSeed` 与本地资源清理顺序，不机械触碰内部 rollback/helper 状态机块。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `TTestCase_NonX86BackendParity` 里剩余的顶层 automatic-reset finally | completed | 已确认上一批 pure `vector asm` outer finally 清空后，这个 companion parity 类里还剩 12 处顶层 `finally ResetToAutomaticBackend;`，且都位于 test body 末尾，不属于内部 helper / nested procedure 局部恢复 |
| 2. 复用 `RestoreDispatchApiLocalState` 收掉这批 backend-restore 样板 | completed | 已把这 12 处统一切到 `RestoreDispatchApiLocalState(FSavedVectorAsm, FSavedBackend)`；`Test_WideInteger_FuzzSeed_Parity_IfAvailable` 继续先执行 `RandSeed := LOriginalSeed;`，没有打乱已有本地清理顺序 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DispatchAPI,TTestCase_NonX86BackendParity`、Release `check`、Release `gate` 全绿；当前 `dispatchapi.testcase` 剩余 `ResetToAutomaticBackend` 命中已主要收敛到复杂 rollback/backend mutation/helper 状态机块 |

## 2026-05-14 DispatchAPI Tail Reset Redundancy Cleanup

### Goal

继续沿 `dispatchapi.testcase` 深审剩余 `ResetToAutomaticBackend` 命中，但这次只收真正的尾声冗余：删除 20 处“已经把原 backend table 注册回去、下一步马上退出给 `TDispatchAPIStatefulTestCase.TearDown`，却仍额外再 reset 一次 automatic”的末尾 reset，不触碰测试前置条件 reset、hook 合同断言中的中途 reset，或跨测试手工探针路径。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 分类剩余 `ResetToAutomaticBackend` 命中 | completed | 已把剩余命中缩分成四类：fixture/helper 本体、测试前置条件 reset、中途 hook/rollback 状态机 reset、以及“恢复原 table 后立刻返回”的尾声冗余 reset；本轮只处理最后一类 |
| 2. 删除尾声重复 automatic reset | completed | 已从 `TTestCase_DispatchAPI` 相关测试里删除 20 处尾声 `ResetToAutomaticBackend`，覆盖 hook mutation、register/metadata、benchmark activation、以及一串 `Vec*Facade_Tracks_CurrentDispatchTable_After_ReRegister` 路径；保留 `RegisterBackend(..., LOriginalTable)` 本身不动 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DispatchAPI`、Release `check`、Release `gate` 全绿；这批之后剩余 `ResetToAutomaticBackend` 更集中到真正承担语义职责的 setup/mid-test/hook-state-machine 路径 |

## 2026-05-14 RISCV Fallback Probe Fixture Hardening

### Goal

继续沿剩余复杂点深审 `dispatchapi.testcase`，修掉 `TTestCase_RISCVFallbackDispatchContract.Test_RollbackRestoreSuccess_Keep_RepresentativeWideSlots_Assigned` 里“手工创建 `TTestCase_DispatchAPI` 并直接调用测试方法、但没有显式跑 inner `SetUp/TearDown`”的夹具边界风险，让这条 cross-test probe 不再依赖对象零值或外层手工 reset 掩盖。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 cross-test probe 的真实依赖 | completed | 已确认这条 probe 是全文件唯一一处手工 `Create` 测试类再直接调 `Test_*` 的模式，而被调方法 `Test_TrySetActiveBackend_RollbackRestore_Success_Preserves_ForcedSelection` 的 finally 明确依赖 `FSavedVectorAsm/FSavedBackend` |
| 2. 显式跑 inner fixture 并去掉掩盖性 reset | completed | 已在 probe 中引入 `LInnerSetupDone`，改为显式 `LCase.SetUp -> Test_* -> LCase.TearDown`；同时删除块尾靠 `ResetToAutomaticBackend` 掩盖 inner fixture 缺失的做法 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_RISCVFallbackDispatchContract,TTestCase_DispatchAPI`、Release `check`、Release `gate` 全绿；当前这条 probe 已从“隐式依赖测试类零值”收口成显式 fixture 契约 |

## 2026-05-14 PublicAbi Double Restore Cleanup

### Goal

继续沿 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 深审已进入 helper 化之后的复杂尾声恢复，先删掉那些“先 `RestoreOriginalActiveBackend(...)`，随后又立刻 `RestorePublicAbiLocalState(...)` 或直接返回”的双恢复冗余，只保留真正还有后续断言依赖中间 backend 状态的调用点。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `publicabi.testcase` 里剩余 `RestoreOriginalActiveBackend(...)` 的语义归属 | completed | 已逐段确认 9 处命中都属于尾声双恢复：它们后面要么直接 `end;`，要么马上再走 `RestorePublicAbiLocalState(...)`，中间没有新的断言依赖“先恢复回原 backend”的状态；仅 `Test_PublicApi_Table_Refreshes_AfterBackendSwitch` 还需要保留，因为 finally 后仍有断言要求 active backend 追踪恢复后的 backend |
| 2. 删除双恢复冗余并保留真实依赖点 | completed | 已从 `CachedTable_*`、`Stable_Cdecl_EntryPoints`、`BackendRoundTrip`、`BackendPodInfo_Refreshes`、`ActiveBackendId_*`、`FailedHookMutation_*`、`RollbackRestore_*` 等 9 条路径删去尾声 `RestoreOriginalActiveBackend(...)`；保留唯一真实需要的 `Table_Refreshes_AfterBackendSwitch` 调用点不动 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_PublicAbi`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 PublicAbi Capability Pure Outer Finally Cleanup

### Goal

继续沿 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 深审 capability/pod-info 路径，把那批顶层 pure `SetVectorAsmEnabled(LOldVectorAsm)` outer finally 统一收回 `RestorePublicAbiLocalState(...)`，让这些测试在切换 `vector asm` 触发 backend 重选后，也回到类级保存的 `FSavedVectorAsm/FSavedBackend`，而不是只恢复 `vector asm`。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 capability/pod-info 路径剩余 pure `vector asm` outer finally | completed | 已确认 `publicabi.testcase` 里剩余 14 处顶层裸 `SetVectorAsmEnabled(LOldVectorAsm)` 都集中在 `BackendPodInfo_CapabilityBits_*` 相关用例；这些测试会通过 `SetVectorAsmEnabled(True/False)` 触发 active backend 重选，但尾声只恢复 `vector asm`，没有复用类级保存的 backend |
| 2. 复用 `RestorePublicAbiLocalState` 收掉顶层纯恢复样板 | completed | 已把这 14 处统一切到 `RestorePublicAbiLocalState(LOldVectorAsm, FSavedBackend)`，覆盖 `x86 shuffle/masked/integer`、`AVX2/AVX512`、`NEON`、`RISCVV` capability bits 用例；不触碰 hook/reset 状态机路径与 `src/` 生产实现 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_PublicAbi`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 PublicAbi Empty Finally And Duplicate Table Restore Cleanup

### Goal

继续沿 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 深审复杂 hook/rollback 路径，但这次只收最确定的 exact-contract 冗余：删除空 `finally` 壳，以及把“正常流已经 `RegisterBackend(...original...)` 恢复原 table，outer finally 还会再恢复一次”的双表恢复收口成条件式 cleanup，不改任何中途断言语义。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `publicabi` 剩余 exact-contract 冗余 | completed | 已确认 3 处空 `finally` 只是在前几轮删除恢复逻辑后留下的壳；另有一批 hook/rollback/failure 路径在正常流里已经显式 `RegisterBackend(...original...)`，但 outer finally 仍会再做一遍相同恢复 |
| 2. 删除空 `finally` 并收紧 duplicate table restore | completed | 已去掉 3 处空 `finally`；为 `CachedTable_Cdecl_EntryPoints_Follow_CurrentDataPlane_After_ReRegister` 加 `LOriginalTableRestored`，并在 7 条 hook/rollback/register 路径里把 `*TableCaptured` 在显式恢复原 table 后立刻清掉，避免 outer finally 再重复 `RegisterBackend(...)` |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_PublicAbi`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 PublicAbi Failed Hook Fixture Restore Guard

### Goal

继续沿 `publicabi` 的复杂 failure 路径深审异常兜底，补上 `Test_PublicApi_FailedHookMutation_DoesNotRevive_PreviouslyRequestedBackend_AfterRestore` 里“requested backend table 被 hook 改掉，但异常路径没有 outer restore guard”的夹具缺口，让这条测试和后面几条同类路径一样，即使中途断言或调用异常也能恢复原 table。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 failure 路径的 table-restore 兜底差异 | completed | 已确认同文件多数 hook/rollback 测试都已有 `*TableCaptured` 外层兜底，但 `FailedHookMutation_DoesNotRevive_PreviouslyRequestedBackend_AfterRestore` 仍只在正常流末尾手工 `RegisterBackend(LRequestedBackend, LOriginalTable)`，异常路径会跳过这步 |
| 2. 补 outer restore guard 并保留正常流语义 | completed | 已为该测试补 `LRequestedTableCaptured`，在捕获原 table 后置 `True`、在正常流恢复成功后置 `False`，并在 outer finally 中条件恢复原 table；中途 hook/断言语义不动 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_PublicAbi`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 PublicAbi RollbackForceSuccess Higher-Restore Dedup

### Goal

继续沿 `publicabi` 的 complex hook/state-machine 路径深审成功分支 cleanup，收掉 `Test_PublicApi_RollbackRestore_Success_Preserves_ForcedSelection` 中“normal path 已恢复 higher-priority backends，但 outer finally 还会再恢复一轮”的重复 restore，同时保留异常路径兜底。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 rollback-force-success hook 的真实变更范围 | completed | 已核对 `PublicAbiHookRollbackForceSuccessWithoutForcedIntent`：hook 会临时改 target table 和一批 higher-priority backend tables；正常流在 `TrySetActiveBackend(...)` 成功后会先恢复 higher-priority backends，而 outer finally 仍按 `LTargetTableCaptured + HigherCount` 再恢复一次 |
| 2. 在成功恢复完成后清掉 duplicate restore 状态 | completed | 已在成功流末尾、完成 higher-priority backend 恢复并做完 active-backend 断言后，将 `LTargetTableCaptured := False` 与 `GPublicAbiHookRollbackForceSuccessHigherCount := 0`，让 outer finally 只继续承担异常路径兜底 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_PublicAbi`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 DataPlane And IEEE754 Local Restore Alignment

### Goal

把 `tests/fafafa.core.simd` 里剩余的两类顶层旧夹具恢复形状继续收口：`dataplane` 中只恢复 `vector asm + automatic` 的 local finally，以及 `ieee754` 中跨多个类反复出现的同类 finally / tearDown，统一改成“恢复到保存的 backend”语义，避免测试体尾声和类级 fixture 恢复契约继续分叉。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `dataplane` / `ieee754` 剩余旧恢复形状 | completed | 已确认 `dataplane.testcase` 还剩 1 处 `SetVectorAsmEnabled(LOldVectorAsm); ResetToAutomaticBackend;` 的顶层 finally；`ieee754.testcase` 里有 4 个 tearDown 和 6 个方法级 finally 仍沿用同类旧形状，且 `TTestCase_NonX86IEEE754.Test_NonX86_RoundTruncFloorCeil_NaNInf_IfAvailable` 外层 finally 甚至只恢复了 `vector asm` |
| 2. 提取 helper 并统一 local restore 契约 | completed | 已为 `dataplane` / `ieee754` 各自补 `Restore*LocalState(...)` helper；`dataplane` tearDown 与 `VectorAsmRoundTrip` finally、`ieee754` 的 4 个 tearDown 与 6 个方法级 finally 全部统一到“恢复保存 backend”语义；首轮编译发现顶层 helper 不能直接调用 `AssertTrue`，随后改成返回 `Boolean` 并把断言留在类方法/测试方法里 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DataPlane`、Release `TTestCase_IEEE754EdgeCases`、Release `TTestCase_AVX2RoundTruncIEEE754`、Release `TTestCase_NonX86IEEE754`、Release `TTestCase_IEEE754_F64`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 DispatchSlots And SSE2Contracts Restore Alignment

### Goal

继续沿小 testcase 文件清理剩余的旧恢复形状，把 `dispatchslots` 中 backend-only 尾声只做 `ResetToAutomaticBackend` 的路径，以及 `sse2contracts` 的老式 tearDown，统一到“恢复保存 backend”契约，避免这些 companion tests 继续把 backend drift 留到更晚才暴露。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `dispatchslots` / `sse2contracts` 剩余 restore 分叉 | completed | 已确认 `dispatchslots.testcase` 的类级 `TearDown` 仍是手写 `ResetToAutomaticBackend + TrySetActiveBackend(FSavedBackend)`，且 `Test_AllSelectableBackends_AllDispatchSlots_Assigned`、`Test_BackendAdapter_ActiveBackend_RoundTrip_NoNilAndCorePointersStable`、`Test_BackendAdapter_RegisteredBackendOps_PreserveCanonicalTextMetadata_After_ReRegister` 还残留 method-level `ResetToAutomaticBackend`；`sse2contracts.testcase` 仍有老式 `vector asm + automatic + TrySetActiveBackend` tearDown |
| 2. 提取 helper 并统一小文件恢复契约 | completed | 已为 `dispatchslots` 补 `RestoreDispatchSlotsLocalState(...)`，为 `sse2contracts` 补 `RestoreSSE2ContractsLocalState(...)`；`dispatchslots` 的类级 tearDown 和 3 个方法尾声、`sse2contracts` 的 tearDown 全部切到 helper 返回 `Boolean` + 调用点断言的形状 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DispatchAllSlots`、Release `TTestCase_SSE2Contracts`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 Concurrent VectorAsm Restore Alignment

### Goal

继续沿 `concurrent` 收最后两条最确定的 method-level restore 残点，把 `TTestCase_SimdConcurrent` 中仍只恢复 `vector asm` 的两个顶层 finally 统一切回已有的 `RestoreSimdLocalState(...)`，避免这些并发夹具把 backend drift 留给更晚的 tearDown。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `concurrent` 剩余 old-shape finally | completed | 已确认 `fafafa.core.simd.concurrent.testcase.pas` 中 `Test_Concurrent_VectorAsmToggle_DispatchReadConsistency` 与 `Test_Concurrent_VectorAsmToggle_MultiWriter_DispatchRead` 的 outer finally 仍只做 `SetVectorAsmEnabled(LOldVectorAsm)`；同文件其余同类顶层恢复大多已切到 `RestoreSimdLocalState(LOldVectorAsm, FSavedBackend)` |
| 2. 复用现有 helper 收口这两条 finally | completed | 已直接把两处 finally 改为 `RestoreSimdLocalState(LOldVectorAsm, FSavedBackend)`；没有扩到 `direct` 的全局过程 cleanup，因为那条还需要先补原始 backend 捕获，适合下一批单独处理 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_SimdConcurrent`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 Direct Concurrent Snapshot Cleanup Restore Alignment

### Goal

继续沿上一轮锁定的 `direct` 残点收口 `RunDirectDispatchConcurrentReRegisterSnapshotConsistency`：在恢复 scalar 原表后，不再只回到 `automatic`，而是回到调用前真实 backend 再 rebind direct dispatch，避免这个全局过程把 backend drift 留给外层 fixture。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `direct` 全局过程 cleanup 的真实缺口 | completed | 已确认 `fafafa.core.simd.direct.testcase.pas` 中 `RunDirectDispatchConcurrentReRegisterSnapshotConsistency` 的 finally 只做 `RegisterBackend(sbScalar, LOriginalTable); ResetToAutomaticBackend; RebindDirectDispatch;`；该过程在进入时没有保存原 backend，因此返回后会把状态留在 automatic，直到更外层 `TearDown` 才恢复 |
| 2. 补原 backend 捕获并在 finally 中恢复 | completed | 已为该过程补 `LOriginalBackend := GetCurrentBackend`，并在恢复 scalar 原表后于 finally 中尝试 `TrySetActiveBackend(LOriginalBackend)`；若失败则抛出明确异常，随后再 `RebindDirectDispatch` |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DirectDispatchConcurrent`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 DispatchAPI Basic Restore And BackendConsistency Entry-State Alignment

### Goal

继续沿“方法尾声只回 automatic”的残点收口两簇低风险测试夹具：一是 `dispatchapi` 最前面的基础 API 测试，它们已经有类级 `FSavedBackend + RestoreDispatchApiLocalState(...)` 却还在方法级 finally 只做 `ResetToAutomaticBackend`；二是根 `testcase` 里 backend-consistency 的包装/元测试，在 plain `TTestCase` 下验证过程中会强制切 backend，但退出时仍停在 automatic 而不是回到进入前真实 backend。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `dispatchapi` / 根 `testcase` 的尾声 restore 形状 | completed | 已确认 `TTestCase_DispatchAPI` 最前 4 个基础 API 测试的 finally 仍只做 `ResetToAutomaticBackend`，与同文件后续大量 `RestoreDispatchApiLocalState(...)` 形状分叉；同时 `TTestCase_BackendVectorConsistency` 是 plain `TTestCase`，其 2 条元测试和 1 条 wrapper 测试虽然会校验“调用内部保持 forced backend”，但退出测试时仍只回到 automatic |
| 2. 统一到保存 backend / 进入态 restore 契约 | completed | 已将 `dispatchapi` 这 4 条基础测试的 finally 改为复用现成 `RestoreDispatchApiLocalState(FSavedVectorAsm, FSavedBackend)`；在根 `testcase` 新增 `RestoreBackendVectorConsistencyLocalState(...)`，并让 backend-consistency 的 wrapper 与 2 条元测试在 finally 中回到进入前真实 backend |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DispatchAPI`、Release `TTestCase_BackendVectorConsistency`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 DispatchAPI BackendOnly Metadata Restore Alignment

### Goal

继续沿 `dispatchapi` 剩余 backend-only / metadata 测试收掉“方法内先把 control-plane 切到 automatic 或当前 backend 场景，但退出时仍把 backend 漂给外层 tearDown”的分叉，重点覆盖不涉及复杂 hook 状态机的 5 条测试：`SetActiveBackend_Unavailable_FallsBackToScalar`、`BackendInfoAvailableFalse_IsNotSelectable`、`SupportedAliases_StayCpuOnly_WhenBackendBecomesNonDispatchable`、`RegisteredBackendDispatchTable_PreservesCanonicalTextMetadata_After_ReRegister`、`CurrentBackendInfo_PreservesCanonicalTextMetadata_After_ReRegister`。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 backend-only / metadata 残点 | completed | 已确认这 5 条 `dispatchapi` 测试都会在方法内显式 `ResetToAutomaticBackend` 或围绕“当前 backend”重注册做断言，但退出时要么只回 automatic，要么完全依赖外层 `TearDown` 恢复 `FSavedBackend`，与同文件大量 helper-based cleanup 契约继续分叉 |
| 2. 统一到类级 saved-state restore 契约 | completed | 已将 `Test_SetActiveBackend_Unavailable_FallsBackToScalar` 的 finally 改为 `RestoreDispatchApiLocalState(FSavedVectorAsm, FSavedBackend)`；并为其余 4 条 backend-only / metadata 测试补 outer `try...finally`，让它们在内部仍保持 automatic/current-backend 语义验证，但退出测试时恢复到类级保存状态 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DispatchAPI`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 DispatchAPI Facade CurrentDispatch Restore Alignment

### Goal

继续沿 `dispatchapi` 后段的 facade/current-dispatch 跟踪测试收尾，只补“方法退出仍把 backend 状态漂给外层 `TearDown`”这一层 restore 分叉，不改 synthetic re-register、current dispatch slot 断言和 facade 跟踪语义。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 facade/current-dispatch easy wins 残点 | completed | 已确认 9 条 `dispatchapi` facade/current-dispatch 测试仍缺 outer saved-state restore：`Test_VecF32x4ReduceFacade_Tracks_CurrentDispatchTable_After_ReRegister`、`Test_VecF64x2ReduceFacade_Tracks_CurrentDispatchTable_After_ReRegister`、`Test_VecF64x2MathFacade_Tracks_CurrentDispatchTable_After_ReRegister`、`Test_VecF32VectorMathFacade_Tracks_CurrentDispatchTable_After_ReRegister`、`Test_VecWideFloatDotFacade_Tracks_CurrentDispatchTable_After_ReRegister`、`Test_VecF64x4ReduceFacade_Tracks_CurrentDispatchTable_After_ReRegister`、`Test_VecF32x8ReduceFacade_Tracks_CurrentDispatchTable_After_ReRegister`、`Test_VecF64x8ReduceFacade_Tracks_CurrentDispatchTable_After_ReRegister`、`Test_VecF32x16ReduceFacade_Tracks_CurrentDispatchTable_After_ReRegister` |
| 2. 统一 facade 测试的最外层退出态 restore | completed | 9 条测试都补了 outer `try...finally`，最外层统一 `RestoreDispatchApiLocalState(FSavedVectorAsm, FSavedBackend)`；内层 `RegisterBackend(LBackend, LOriginalTable)` 回滚、synthetic slot 注入和 facade/current-dispatch 断言保持原样 |
| 3. Release 验证证据同步 | completed | 这批改动已跑过 `git diff --check`、Release `TTestCase_DispatchAPI`、Release `check`、Release `gate` 并全部通过；当前 turn 只需在提交前再次清理可能回流的 `tests/fafafa.core.simd/__pycache__/` 即可收口 |

## 2026-05-14 PublicAbi Cached Publication Restore Alignment

### Goal

继续沿 `publicabi` 里最稳的 current-publication easy wins 收口，只补“方法内改动 active backend / public ABI 当前发布态，但最外层仍把恢复留给类级 `TearDown`”这一层 cleanup 分叉，不碰 hook-heavy rollback state machine。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `publicabi` easy wins 残点 | completed | 通过精确文件审查确认最值得先收的是 3 条测试：`Test_PublicApi_CachedTable_RemainsCallable_Across_Rebind`、`Test_PublicApi_CachedTable_Preserves_PreviousSnapshot_Metadata_Across_Rebind`、`Test_PublicApi_BackendPodInfo_Refreshes_WhenBackendBecomesNonDispatchable`；前两条在 rebind 后直接退出，后一条在把当前 backend 标成 unavailable 后触发 re-selection，但三者都仍把 saved-state 恢复留给 outer `TearDown` |
| 2. 统一到类级 `RestorePublicAbiLocalState(...)` 契约 | completed | 两条 cached/publication rebind 测试补 outer `try...finally`，统一在方法退出时恢复 `FSavedVectorAsm + FSavedBackend`；`BackendPodInfo_Refreshes_WhenBackendBecomesNonDispatchable` 也补 outer restore，同时保留内层 `RegisterBackend(LOriginalBackend, LOriginalTable)` 负责表回滚，避免混淆“当前发布态恢复”和“注册表恢复”两个层级 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_PublicAbi`、Release `check`、Release `gate` 全绿；提交前仍需再次清理可能回流的 `tests/fafafa.core.simd/__pycache__/` |

## 2026-05-14 DispatchAPI AVX512 Cleanup Dedup And Hook Restore Alignment

### Goal

继续沿 `dispatchapi` 收更后段的 cleanup 冗余和缺口：清掉 AVX512 parity/contract tests 中“内层 `ResetToAutomaticBackend` + 外层 saved-state restore”的重复退出态样板，同时把 hook 多订阅测试的 finally 从“只回 automatic”对齐到类级保存态恢复。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `dispatchapi` 后段 cleanup 冗余/缺口 | completed | 已确认 4 条 AVX512 tests `Test_AVX512_U32x16_U64x8_MappingAndParity`、`Test_AVX512_U32x16_U64x8_ShiftBoundary_Contracts`、`Test_AVX512_I16x32_I8x64_U8x64_MappingAndParity`、`Test_AVX512_F32x16_F64x8_IEEE754_MappingAndParity` 都存在“内层 `ResetToAutomaticBackend` + 外层 `RestoreDispatchApiLocalState(...)`”双重 method-exit cleanup；同时 `Test_DispatchChangedHooks_MultiSubscriber_Dedup_And_Remove` 的 finally 还只做 `ResetToAutomaticBackend`，把 saved backend 恢复留给 `TearDown` |
| 2. 去掉重复退出态样板并补 hook saved-state restore | completed | 已移除 4 条 AVX512 tests 的 inner `finally ResetToAutomaticBackend`，保留外层 `RestoreDispatchApiLocalState(...)` 作为唯一 method-exit cleanup；hook 多订阅测试则保留中途用于驱动通知语义的 `ResetToAutomaticBackend` 步骤，只把 finally 收口改成 `RemoveDispatchChangedHook(...)` 后接 `RestoreDispatchApiLocalState(FSavedVectorAsm, FSavedBackend)` |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DispatchAPI`、Release `check`、Release `gate` 全绿；提交前仍需再次清理可能回流的 `tests/fafafa.core.simd/__pycache__/` |

## 2026-05-14 IEEE754 EdgeCases Restore Alignment

### Goal

继续沿 `ieee754` 收 method-exit old-shape cleanup，只处理 `TTestCase_IEEE754EdgeCases` 中 3 条最稳的 edge-case tests，把“只回 automatic”或“手写 vector-asm + automatic”退出态统一对齐到现成的 `RestoreIEEE754LocalState(...)`，不碰 non-x86 loop 内可能兼具迭代隔离语义的 `ResetToAutomaticBackend`。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `ieee754` 剩余 old-shape finally | completed | 已确认 `Test_F32x4_RoundTrunc_NaNInf_Scalar`、`Test_F32x4_RoundTrunc_NaNInf_SSE2`、`Test_Wide_RoundTrunc_NaNInf_Scalar` 仍分别使用“只回 automatic”或“`SetVectorAsmEnabled(oldVectorAsm); ResetToAutomaticBackend;`”的 method-exit cleanup；而 non-x86 property/loop tests 里的同类 `ResetToAutomaticBackend` 更像 iteration-level control-plane 隔离，暂不归到这一批 |
| 2. 统一 edge-case tests 的退出态 restore 契约 | completed | 3 条测试都改为在 finally 里 `AssertTrue(..., RestoreIEEE754LocalState(...))`；scalar tests 使用 `FSavedVectorAsm + FSavedBackend`，SSE2 test 使用 `oldVectorAsm + FSavedBackend`，与同文件既有 helper-based cleanup 形状重新对齐 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_IEEE754EdgeCases`、Release `check`、Release `gate` 全绿；提交前仍需再次清理可能回流的 `tests/fafafa.core.simd/__pycache__/` |

## 2026-05-14 Scalar Backend Fixture Base-Class Consolidation

### Goal

继续沿 simd 测试层 cleanup/去冗余往下收，把几份“小 testcase 文件重复 backend fixture 样板”统一切到现成的 `TScalarBackendStatefulTestCase`，只动纯 scalar fixture，不碰带额外 FPU/image 清理语义的复杂 testcase。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核纯 scalar fixture 候选与基类契约 | completed | 已确认 `vecf32x8`、`veci32x8`、`vecu32x8`、`narrowintegerops`、`vecf64x4`、`saturating` 6 份 testcase 都重复了同一套 `GetDispatchTable -> save backend -> ForceBackend(sbScalar)` / `ResetBackendSelection -> TrySetActiveBackend(FSavedBackend)` 样板；仓内现成 `TScalarBackendStatefulTestCase` 已提供同等契约 |
| 2. 统一继承到 `TScalarBackendStatefulTestCase` | completed | 6 个 testcase 全部改继承 `TScalarBackendStatefulTestCase`，删除各自的 `FSavedBackend/SetUp/TearDown` 重复实现；`vecf32x8` 与 `vecf64x4` 保留 `fafafa.core.simd.scalar`，因为文件内部仍显式调用 `Scalar*` helper 作为期望值来源 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release 定向 suites（`VecF32x8/VecI32x8/VecU32x8/NarrowIntegerOps/VecF64x4/SaturatingArithmetic`）、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 Vec512 Mask Guard Fixture Consolidation

### Goal

继续沿“纯 scalar fixture 去重”往下推进，但只收 `vec512types` 里最稳的 `TTestCase_Vec512MaskFacadeGuards`，不碰同文件普通类型测试，也不把这次扩成更复杂的 AVX512/guard 语义改动。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `Vec512MaskFacadeGuards` 是否只是 pure scalar guard | completed | 已确认该 suite 只是在 fixed `sbScalar` 下验证 `MaskF32x16` façade contract，本身没有额外 vector-asm/FPU/image 生命周期语义；文件内重复的 `FSavedBackend/SetUp/TearDown` 形状与上一批 6 个纯 fixture testcase 一致 |
| 2. 切到统一 scalar fixture 基类 | completed | `TTestCase_Vec512MaskFacadeGuards` 已改继承 `TScalarBackendStatefulTestCase`，删除本地 `FSavedBackend/SetUp/TearDown`；文件增加 `fafafa.core.simd.testcase`，并移除只被旧夹具使用的 `fafafa.core.simd.dispatch` |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_Vec512MaskFacadeGuards`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 EdgeCases And ImageProc Fixture Consolidation

### Goal

继续沿 stateful fixture 去重往下收，但保留 `edgecases` 的 FPU exception mask 生命周期和 `imageproc` 的 image/blend-mode 生命周期，只把重复的 backend 保存/恢复收回现成公共基类。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `edgecases` / `imageproc` 的附加清理语义 | completed | 已确认 `edgecases` 除 backend 之外还要保存/恢复 `TFPUExceptionMask`，而 `imageproc` 还要保存/恢复 `TImageBlendAlphaMode` 并释放 `FSrc1/FSrc2/FDest`；两者都不是纯 scalar fixture，不能像前几批那样机械整文件切 `TScalarBackendStatefulTestCase` |
| 2. 只把 backend 保存/恢复收回公共基类 | completed | `TTestCase_EdgeCases` 改继承 `TSimdBackendStatefulTestCase`，本地只保留 `ForceBackend(sbScalar)` 与 FPU mask 生命周期；`TTestCase_ImageProc` 改继承 `TScalarBackendStatefulTestCase`，本地只保留 image/blend 清理；两文件均引入 `fafafa.core.simd.testcase`，移除仅给旧 backend fixture 用的 `dispatch` 依赖 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_EdgeCases,TTestCase_ImageProc`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 DataPlane And SSE2Contracts Fixture Consolidation

### Goal

继续沿 stateful fixture 去重往下收，但只把 `dataplane` / `sse2contracts` 里重复的 backend 保存/恢复收回公共基类；`vector-asm` 开关仍保留为 testcase 本地状态，不把这批强行升级成更重的 vector-asm 专属基类改造。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `dataplane` / `sse2contracts` 的 backend 与 vector-asm 生命周期边界 | completed | 已确认两份 testcase 都同时重复 `FOldBackend + FOldVectorAsm` 样板，但真正通用的是 backend save/restore；`vector-asm` 状态仍是 testcase 专属，而 `TSimdVectorAsmBackendStatefulTestCase` 对这批文件来说平台条件更窄、契约更重 |
| 2. 只把 backend 保存/恢复收回 `TSimdBackendStatefulTestCase` | completed | `TTestCase_DataPlane` 与 `TTestCase_SSE2Contracts` 都已改继承 `TSimdBackendStatefulTestCase`，删除本地 `FOldBackend`，保留 `FOldVectorAsm`；`TearDown` 统一先恢复 vector-asm，再 `inherited TearDown` 恢复 backend；`dataplane` 的方法级 local restore 也同步从 `FOldBackend` 切到 `FSavedBackend` |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_SSE2Contracts,TTestCase_DataPlane`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 Concurrent And Direct Stateful Base Consolidation

### Goal

继续沿 stateful fixture 去重往下收，但这次目标是 `concurrent` / `direct` 里各自的本地 stateful 基类：把重复的 backend 生命周期收回 `TSimdBackendStatefulTestCase`，保留方法级 restore helper 与 `RebindDirectDispatch` 这类 testcase 专属语义。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `concurrent` / `direct` 本地 stateful 基类与公共 backend 基类的重合面 | completed | 已确认 `TSimdStatefulTestCase` 与 `TDirectDispatchStatefulTestCase` 都重复了 `GetDispatchTable -> save current backend -> TearDown restore backend`；真正 testcase 专属的剩余状态分别是 `vector-asm` 与 `direct dispatch rebind` |
| 2. 只把类级 backend 生命周期收回 `TSimdBackendStatefulTestCase` | completed | 两个本地基类都已改继承 `TSimdBackendStatefulTestCase`，删除本地 `FSavedBackend`；`SetUp` 不再重复保存 backend；`concurrent` 的 `TearDown` 改成只恢复 vector-asm 后 `inherited TearDown`；`direct` 的 `TearDown` 则在同样顺序后补 `RebindDirectDispatch` |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release 定向 suites（`SimdConcurrent/PublicAbi/Framework/Registration` 与 `DirectDispatch/DirectDispatchConcurrent`）、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 DispatchSlots Backend Fixture Consolidation

### Goal

继续沿 stateful fixture 去重往下收，但这次先把 `dispatchslots` 的 active/current 语义前提核实清楚；只有在确认 `GetCurrentBackend` 与 `GetActiveBackend` 都锚在同一个 published dispatch backend truth 上后，才把类级 backend fixture 收回 `TSimdBackendStatefulTestCase`。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `dispatchslots` 的 active/current backend truth source | completed | 已确认 `GetActiveBackend` 直接读取 published dispatch table 的 `Backend`；`runtime` 的 `BuildSimdRuntimePublishedState` 在有 dispatch 时也直接把 `CurrentBackend := LDispatch^.Backend`，因此类级 backend fixture 的 truth source 当前对齐 |
| 2. 只把类级 backend 生命周期收回 `TSimdBackendStatefulTestCase` | completed | `TTestCase_DispatchAllSlots` 已改继承 `TSimdBackendStatefulTestCase`，删除本地 `FSavedBackend/SetUp/TearDown`；suite 内部的 `RestoreDispatchSlotsLocalState(...)` 与所有 `GetActiveBackend/TrySetActiveBackend/ResetToAutomaticBackend` 断言保持原样 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DispatchAllSlots`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 PublicAbi And DispatchApi Fixture Consolidation

### Goal

继续沿 stateful fixture 去重往下收，但这次目标是 `publicabi` / `dispatchapi` 这两个 hook-heavy control-plane testcase：只把类级 backend 生命周期收回 `TSimdBackendStatefulTestCase`，保留方法级 restore helper、synthetic hook state 和 rollback 语义不动。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `publicabi` / `dispatchapi` 的类级 fixture 与方法级控制面语义边界 | completed | 已确认两边的类级基类仍重复 `GetDispatchTable -> save current backend -> TearDown restore backend`；真正 testcase 专属的类级剩余状态只剩 `vector-asm`，而方法级 helper / hook state machine 则必须保留 |
| 2. 只把类级 backend 生命周期收回 `TSimdBackendStatefulTestCase` | completed | `TTestCase_PublicAbi` 与 `TDispatchAPIStatefulTestCase` 都已改继承 `TSimdBackendStatefulTestCase`，删除本地 `FSavedBackend`；`SetUp` 不再重复保存 backend；`publicabi` 的 `TearDown` 先 reset synthetic hooks 再恢复 vector-asm 后 `inherited TearDown`；`dispatchapi` 的 `TearDown` 则恢复 vector-asm 后 `inherited TearDown`；两边的方法级 restore helper 保持原样 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_PublicAbi,TTestCase_DispatchAPI`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 IEEE754 Fixture Consolidation

### Goal

继续沿 stateful fixture 去重往下收，但这次目标是 `ieee754` 文件里 4 个仍自带 `FSavedBackend` 的 testcase：只把类级 backend 生命周期收回 `TSimdBackendStatefulTestCase`，保留 exception mask、scalar force 和 `RestoreIEEE754LocalState(...)` 这些数值测试语义不动。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `ieee754` 的 backend / vector-asm / exception-mask 分层 | completed | 已确认 4 个 testcase 都重复 backend fixture，但 `F64/EdgeCases/AVX2RoundTrunc` 还额外维护 `TFPUExceptionMask`，`F64` 还会 class-level force scalar，`RestoreIEEE754LocalState(...)` 也仍广泛服务于方法级 local restore |
| 2. 只把类级 backend 生命周期收回 `TSimdBackendStatefulTestCase` | completed | 4 个 testcase 都已改继承 `TSimdBackendStatefulTestCase`，删除本地 `FSavedBackend`；`SetUp` 不再重复保存 backend；`TearDown` 统一先恢复 vector-asm 再 `inherited TearDown`，带 exception mask 的 suite 再恢复 mask；`F64` 继续保留本地 `SetActiveBackend(sbScalar)` |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_IEEE754_F64,TTestCase_IEEE754EdgeCases,TTestCase_AVX2RoundTruncIEEE754,TTestCase_NonX86IEEE754`、Release `check`、Release `gate` 全绿；`tests/fafafa.core.simd/__pycache__/` 已清理 |

## 2026-05-14 Restore-State Helper Consolidation

### Goal

继续沿 stateful fixture 去重往下收，但这次只上提多份 testcase 里完全同构的“恢复 `vector-asm + backend`” helper；保留各文件的 testcase 专属断言、method-level cleanup 编排和 `ieee754` 的数值语义不动。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 restore helper 的同构范围与保留边界 | completed | 已确认 `dataplane`、`publicabi`、`dispatchapi`、`concurrent`、`ieee754` 都还保留同构的 `SetVectorAsmEnabled -> ResetToAutomaticBackend -> TrySetActiveBackend` 恢复体；但各文件在调用点周围的断言、hook rollback 或数值测试编排仍是 testcase 专属，不能一并抹平 |
| 2. 把共享 restore 体上提到公共 testcase 单元 | completed | `fafafa.core.simd.testcase.pas` 已新增 `RestoreSavedBackendAndVectorAsmState(...)`；`RestoreDataPlaneLocalState(...)`、`RestoreIEEE754LocalState(...)`、`TTestCase_PublicAbi.RestorePublicAbiLocalState(...)`、`TDispatchAPIStatefulTestCase.RestoreDispatchApiLocalState(...)`、`TSimdStatefulTestCase.RestoreSimdLocalState(...)` 现都只保留各自 suite 的断言壳或薄转发 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、此前已跑绿的 focused suites 继续成立；本轮 closeout 重新串行跑过 Release `check` 与 Release `gate`，全部通过；提交前仍需清理可能回流的 `tests/fafafa.core.simd/__pycache__/` |

## 2026-05-14 Backend-Only Restore Helper Consolidation

### Goal

继续沿 restore helper 去重往下收，但这次只处理 backend-only 的恢复体：把 `dispatchslots` 与 `backend vector consistency` 仍重复的 `ResetToAutomaticBackend -> TrySetActiveBackend` 公共部分收回 testcase 公共 helper，同时保留 `dispatchslots` 的 `GetActiveBackend` 语义断言壳不变。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `runtime` 与 backend-only 候选的语义边界 | completed | 已确认 `runtime.testcase` 的 finally 不只是恢复 backend 值，还在保“自动选择 vs 强制后端”的 control-plane 语义，因此这轮不动；真正可继续统一的是 `dispatchslots` 与 `TTestCase_BackendVectorConsistency` 的 backend-only local restore |
| 2. 把 backend-only restore 体上提到公共 testcase helper | completed | `fafafa.core.simd.testcase.pas` 已新增 `RestoreSavedBackendState(...)`；`RestoreSavedBackendAndVectorAsmState(...)` 复用它；`RestoreBackendVectorConsistencyLocalState(...)` 与 `dispatchslots` 的 `RestoreDispatchSlotsLocalState(...)` 现改成薄转发，其中 `dispatchslots` 继续追加 `GetActiveBackend = aOriginalBackend` 的 raw dispatch 语义校验 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DispatchAllSlots,TTestCase_BackendVectorConsistency`、Release `check`、Release `gate` 全绿；提交前仍需清理可能回流的 `tests/fafafa.core.simd/__pycache__/` |

## 2026-05-14 PublicAbi Active-Backend Restore Helper Consolidation

### Goal

继续收 backend-only restore 残点，但这次只处理 `publicabi` 里仍保留的 `RestoreOriginalActiveBackend(...)` 重复实现；保持 helper 名称和调用点语义不变，只把实现收回现成的 `RestoreSavedBackendState(...)`。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `publicabi` restore helper 是否属于普通 backend-only 语义 | completed | 已确认 `RestoreOriginalActiveBackend(...)` 只是 `ResetToAutomaticBackend -> TrySetActiveBackend(...)` 的重复体，不带 `runtime` 那种 automatic-vs-forced 分支语义，也不涉及 vector-asm / synthetic hook 生命周期 |
| 2. 把 `publicabi` helper 改成公共 backend-only restore 薄转发 | completed | `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 中的 `RestoreOriginalActiveBackend(...)` 已改成直接调用 `RestoreSavedBackendState(...)`，保留原 helper 名称和所有调用点不动 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_PublicAbi`、Release `check`、Release `gate` 全绿；提交前仍需清理可能回流的 `tests/fafafa.core.simd/__pycache__/` |

## 2026-05-14 Shared Fixture Helper Unit Extraction

### Goal

继续加强 `simd` 测试层审查并修复，但这次目标不是再做一个局部替换，而是把已经被多轮验证稳定的 backend/vector-asm fixture helper 正式抽成一个 test-only 共享单元，解除 `backend.consistency` 因依赖方向导致的 helper 隔离。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核剩余冗余的结构根因 | completed | 已确认 `backend.consistency.testcase` 的本地 `Save/RestoreBackendConsistencyState` 之所以一直保留，不是语义特殊，而是因为 `testcase.pas` 反向 `uses` 它，直接复用 `testcase` 里的公共 helper 会形成单元循环 |
| 2. 抽出共享 fixture helper 单元 | completed | 已新增 `tests/fafafa.core.simd/fafafa.core.simd.fixturehelpers.pas`，承载 `TSimdSavedBackendState`、`SaveActiveBackendState(...)`、`RestoreSavedBackendState(...)`、`RestoreSavedBackendAndVectorAsmState(...)`；`testcase.pas` 现保留兼容 wrapper，`backend.consistency.testcase.pas` 改复用共享单元，不再自带底层 save/restore 实现 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release 定向 suites（`DispatchAllSlots / BackendVectorConsistency / PublicAbi / DataPlane / DispatchAPI / SimdConcurrent / SimdConcurrentPublicAbi / IEEE754_F64`）、Release `check`、Release `gate` 全绿；提交前仍需清理可能回流的 `tests/fafafa.core.simd/__pycache__/` |

## 2026-05-14 Direct Dispatch Fixture Restore Consolidation

### Goal

继续加强 `simd` 测试层冗余审查，但这次只处理 `direct.testcase` 中仍手写的“shared restore 主体 + direct rebind”组合体：把 backend/vector-asm restore 主体收回共享 helper，同时保留 `RebindDirectDispatch` 和 direct 专属断言不动。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `direct` helper 的共享部分与专属部分 | completed | 已确认 `TDirectDispatchStatefulTestCase.RestoreFixtureDirectDispatchState` 里重复的是 `SetVectorAsmEnabled -> ResetToAutomaticBackend -> TrySetActiveBackend` 主体；真正 direct 专属的只剩 `RebindDirectDispatch` 与其后的断言壳 |
| 2. 让 `direct` fixture restore 复用共享 helper | completed | `RestoreFixtureDirectDispatchState` 已改成 `RestoreSavedBackendAndVectorAsmState(FSavedVectorAsm, FSavedBackend)` 后再 `RebindDirectDispatch`，保留 direct rebind 顺序和断言语义不变 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent`、Release `check`、Release `gate` 全绿；提交前仍需清理可能回流的 `tests/fafafa.core.simd/__pycache__/` |

## 2026-05-14 Single-Use Wrapper Cleanup

### Goal

继续加强 `simd` 测试层冗余审查，但只处理已经退化成 single-use exact pass-through 的 helper：删掉没有附加语义的单次转发壳，保留仍带断言或 control-plane 语义的本地 helper。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 盘点 single-use exact wrapper 候选 | completed | 已确认 `dataplane` 的 `RestoreDataPlaneLocalState(...)`、`publicabi` 的 `RestoreOriginalActiveBackend(...)`、`backend.consistency` 的 `SaveBackendConsistencyState(...)` 都是无附加语义的单次转发壳 |
| 2. 删除纯 pass-through 壳并保留语义 helper | completed | 已删除上述 3 个 exact wrapper；`backend.consistency` 的 `RestoreBackendConsistencyState(...)` 保留，因为它仍追加 active-backend 断言语义 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DataPlane,TTestCase_PublicAbi,TTestCase_BackendVectorConsistency`、Release `check`、Release `gate` 全绿；提交前仍需清理可能回流的 `tests/fafafa.core.simd/__pycache__/` |

## 2026-05-14 Freeze Snapshot Fallback Hardening

### Goal

继续加强 `simd` closeout 审查，但这次不再碰生产实现或 testcase 冗余，而是修复 `freeze-status` 的一个真实发布收口坑点：普通 fast gate 会覆盖 canonical `gate_summary.md`，导致后续 `freeze-status` 误丢此前已通过的 closeout gate 证据。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `freeze-status` 与 closeout snapshot 的真实绑定方式 | completed | 已确认 `BuildOrTest.sh gate` 默认 `reset_gate_summary`，所以问题不只是“选错 latest run”，而是 canonical `logs/gate_summary.md` 会被后续普通 gate 覆盖；`evaluate_simd_freeze_status.py` 当前又只消费单一路径，因此 closeout 证据缺少稳定快照入口 |
| 2. 修复有效 gate 摘要选择与 batch snapshot 保留 | completed | `evaluate_simd_freeze_status.py` 现会在未显式 override 时同时扫描 canonical `gate_summary.md` 与 `logs/windows-closeout/*/gate_summary.md`，只在“最新 gate 基础步骤仍绿、但缺的是 closeout 证据步骤”时回退到最近一份满足 closeout 约束的 snapshot；`run_windows_b07_closeout_finalize.sh` 也改为把实际 freeze 使用的 gate summary 保存进 batch 目录 |
| 3. Rehearsal / real freeze 验证与提交收口 | completed | `python3 -m py_compile`、`bash -n`、`bash tests/fafafa.core.simd/rehearse_freeze_status.sh` 全绿；新增 batch-fallback rehearsal 锁住“canonical 被 fast gate 覆盖后仍可回选 closeout snapshot”场景；真实 Release `freeze-status` 继续只剩 Windows freshness 外部阻塞 |

## 2026-05-14 Shared VectorAsm Fixture Base Extraction

### Goal

继续加强 `simd` 测试层审查并修复，但这次不再盯 backend lifecycle，而是把 `dataplane` 与 `sse2contracts` 仍重复的一层 `vector-asm` fixture 生命周期收回公共基类，同时保留 `AVX2/AVX512 vectorasm` 专项的 refresh-registration 语义。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核重复体与现有基类层次 | completed | 已确认 `dataplane.testcase` 与 `sse2contracts.testcase` 都仍保留同构的 `FOldVectorAsm + SetUp/TearDown`；而现有 `TSimdVectorAsmBackendStatefulTestCase` 又额外承载 `RefreshVectorAsmBackendRegistration` 语义，层级过厚，不适合这两份普通 suite 直接复用 |
| 2. 抽出更薄的公共 `vector-asm stateful` 基类 | completed | `fafafa.core.simd.testcase.pas` 已新增 `TSimdVectorAsmStatefulTestCase`，只负责保存/恢复 `IsVectorAsmEnabled`；`TSimdVectorAsmBackendStatefulTestCase` 现改为继承它，并把 `RefreshVectorAsmBackendRegistration` 收进 `RestoreVectorAsmState` override；`dataplane` 与 `sse2contracts` 已直接改继承新薄基类 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DataPlane,TTestCase_SSE2Contracts`、Release `check`、Release `gate` 全绿；本轮没有改变 dataplane/SSE2 contract 的被测语义，只是收回了重复 fixture 生命周期 |

## 2026-05-14 EdgeCases Scalar Fixture Alignment

### Goal

继续加强 `simd` 测试层审查并修复，但这次只处理 `edgecases` 里一处已经退化成重复表达的 scalar fixture：让 suite 直接继承现有 `TScalarBackendStatefulTestCase`，保留 FPU exception mask 的本地语义，不再在 `SetUp` 里重复 `ForceBackend(sbScalar)`。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `edgecases` 是否真的只需要 scalar fixture | completed | 已确认 `TTestCase_EdgeCases` 的本地额外语义只有保存/恢复 `TFPUExceptionMask`；backend 侧始终只是 scalar guard，没有 vector-asm、runtime snapshot 或 per-test backend 编排 |
| 2. 对齐到公共 scalar fixture 基类 | completed | `TTestCase_EdgeCases` 已从 `TSimdBackendStatefulTestCase` 改继承 `TScalarBackendStatefulTestCase`，并删除 `SetUp` 中重复的 `ForceBackend(sbScalar)`；FPU mask 保存/恢复逻辑保持不变 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_EdgeCases`、Release `check`、Release `gate` 全绿；`gate` 本轮按串行收口，避免共享输出目录造成假红 |

## 2026-05-14 Concurrent Fixture Base Alignment

### Goal

继续加强 `simd` 测试层审查并修复，但这次目标是把 `concurrent.testcase` 自己复制的一层 `backend + vector-asm` fixture 生命周期收回现成公共基类，只保留 suite-specific 的本地 restore 断言 helper，不去动任何并发 worker 或控制面被测逻辑。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `TSimdStatefulTestCase` 与公共基类的差异 | completed | 已确认 `TSimdStatefulTestCase.SetUp/TearDown` 只是保存/恢复 `FSavedVectorAsm`，与 `TSimdVectorAsmStatefulTestCase` 完全同构；真正 suite-specific 的只剩 `RestoreSimdLocalState(...)` 这个带断言的本地 helper |
| 2. 对齐到公共 `vector-asm stateful` 基类 | completed | `TSimdStatefulTestCase` 已改继承 `TSimdVectorAsmStatefulTestCase`，删除本地 `FSavedVectorAsm` 字段与重复 `SetUp/TearDown`；`RestoreSimdLocalState(...)` 与所有并发 suite 的调用点保持不变 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_SimdConcurrent,TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework`、Release `check`、Release `gate` 全绿；本轮仍按串行验证，避免共享输出目录假红 |

## 2026-05-14 DispatchAPI Fixture Base Alignment

### Goal

继续加强 `simd` 测试层审查并修复，但这次只处理 `dispatchapi.testcase` 里仍复制的一层 `backend + vector-asm` fixture 生命周期，把它对齐到现成的 `TSimdVectorAsmStatefulTestCase`，保留 `RestoreDispatchApiLocalState(...)` 这种 suite-specific 的中途恢复断言 helper，不改任何 Dispatch API 被测逻辑。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `TDispatchAPIStatefulTestCase` 的本地语义边界 | completed | 已确认它的 `SetUp/TearDown` 与刚收掉的 `TSimdStatefulTestCase` 同型：仅保存/恢复 `FSavedVectorAsm`；真正 suite-specific 的只剩 `RestoreDispatchApiLocalState(...)` 对 backend restore 成功的断言 |
| 2. 对齐到公共 `vector-asm stateful` 基类 | completed | `TDispatchAPIStatefulTestCase` 已改继承 `TSimdVectorAsmStatefulTestCase`，删除本地 `FSavedVectorAsm` 字段与重复 `SetUp/TearDown`；所有 `RestoreDispatchApiLocalState(...)` 调用点保持不变 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DispatchAPI`、Release `check`、Release `gate` 全绿；本轮同样按串行验证收口 |

## 2026-05-14 PublicAbi Fixture Base Alignment

### Goal

继续加强 `simd` 测试层审查并修复，但这次只处理 `publicabi.testcase` 里重复的一层 `backend + vector-asm` fixture 生命周期。保留 `ResetPublicAbiSyntheticHookState` 的时序和 `RestorePublicAbiLocalState(...)` 的 suite-specific 断言 helper，只把公共 lifecycle 下沉到 `TSimdVectorAsmStatefulTestCase`。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `publicabi` 的本地 fixture 是否仍有独立时序要求 | completed | 已确认 `SetUp/TearDown` 唯一额外要求是 `ResetPublicAbiSyntheticHookState` 必须包在 fixture 前后；`FSavedVectorAsm + SetUp/TearDown` 本体仍与公共 `vector-asm stateful` 基类同构 |
| 2. 保留 hook reset 顺序，收回重复 lifecycle | completed | `TTestCase_PublicAbi` 已改继承 `TSimdVectorAsmStatefulTestCase`，删除本地 `FSavedVectorAsm` 与手写 vector-asm restore；`SetUp/TearDown` 只保留 hook-state reset 顺序，`RestorePublicAbiLocalState(...)` 与所有调用点不变 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_PublicAbi`、Release `check`、Release `gate` 全绿；`gate` 里的 public ABI concurrent regression chain 也继续通过 |

## 2026-05-14 Direct Fixture Base Alignment

### Goal

继续加强 `simd` 测试层审查并修复，但这次只处理 `direct.testcase` 里重复的一层 `backend + vector-asm` fixture 生命周期。保留 `RestoreFixtureDirectDispatchState(...)` 里的 `RebindDirectDispatch` 语义，只把公共 lifecycle 下沉到 `TSimdVectorAsmStatefulTestCase`。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `direct` 的本地 fixture 和公共基类差异 | completed | 已确认 `TDirectDispatchStatefulTestCase.SetUp` 只是在保存 `FSavedVectorAsm`；本地真正额外语义只剩中途 restore 后需要 `RebindDirectDispatch`，以及最终 teardown 后也要再 rebind 一次 direct table |
| 2. 对齐到公共 `vector-asm stateful` 基类 | completed | `TDirectDispatchStatefulTestCase` 已改继承 `TSimdVectorAsmStatefulTestCase`，删除本地 `FSavedVectorAsm` 与重复 `SetUp`；`TearDown` 只保留 `inherited TearDown` 后的 `RebindDirectDispatch`，`RestoreFixtureDirectDispatchState(...)` 保持不变 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent`、Release `check`、Release `gate` 全绿；`direct` 的 rebind 语义在定向 suite 和 gate 里都继续通过 |

## 2026-05-14 IEEE754 Fixture Base Alignment

### Goal

继续加强 `simd` 测试层审查并修复，但这次不碰任何 rounding/special-value 测试体，只把 `ieee754.testcase` 里重复的 fixture 生命周期抽成局部专用基类：统一 `exception mask + vector-asm restore`，并让 `NonX86IEEE754` 直接复用公共 `TSimdVectorAsmStatefulTestCase`。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核四个 IEEE754 suite 的 fixture 差异 | completed | 已确认 `F64`、`EdgeCases`、`AVX2RoundTrunc` 三组只是重复 `FSavedVectorAsm + FSavedExceptionMask + SetUp/TearDown`，其中 `F64` 额外多一步 `SetActiveBackend(sbScalar)`；`NonX86IEEE754` 则只重复了 `vector-asm` lifecycle |
| 2. 抽本地 `masked vector-asm` 基类并对齐 suite | completed | `ieee754.testcase.pas` 已新增局部 `TIEEE754MaskedVectorAsmStatefulTestCase`；`F64` 现只 override `SetUp` 追加 `SetActiveBackend(sbScalar)`；`EdgeCases` 和 `AVX2RoundTrunc` 直接复用新基类；`NonX86IEEE754` 直接改继承 `TSimdVectorAsmStatefulTestCase` |
| 3. Release 验证与提交收口 | completed | Release `TTestCase_IEEE754_F64,TTestCase_IEEE754EdgeCases,TTestCase_AVX2RoundTruncIEEE754,TTestCase_NonX86IEEE754`、Release `check`、Release `gate` 全绿；期间首轮 gate 遇到链接器瞬态，串行重跑后恢复 PASS |

## 2026-05-14 VectorAsm Backend Setup Sharing

### Goal

继续加强 `simd` 测试层审查并修复，但这次只处理 `AVX2/AVX512 vectorasm` 两个 suite 仍保留的同构 `SetUp` 壳：把“开启 vector asm + refresh backend registration + force target backend”的 setup contract 下沉到现有 `TSimdVectorAsmBackendStatefulTestCase`，不改任何向量算法或生产实现。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `AVX2/AVX512 vectorasm` 的本地 setup 是否已退化成重复壳 | completed | 已确认两者的 `SetUp` 完全同构：`SetVectorAsmEnabled(True)`、重新注册目标 backend 刷新 dispatch table、再 `ForceBackend(...)`；差异只剩目标 backend 枚举与具体 `Register*Backend` 实现 |
| 2. 把 setup contract 提升到公共 backend-stateful 基类 | completed | `TSimdVectorAsmBackendStatefulTestCase` 已新增抽象 `GetVectorAsmTargetBackend` 与共享 `SetUp`；`AVX2/AVX512` suite 删除本地 `SetUp`，仅保留目标 backend 与注册实现 |
| 3. Release 验证与提交收口 | completed | Release `TTestCase_AVX2VectorAsm,TTestCase_AVX512VectorAsm`、Release `check`、Release `gate` 全绿；本轮继续串行收口，避免 `tests/fafafa.core.simd` 共享输出目录假红 |

## 2026-05-14 Fixture Helper Truth-Source Consolidation

### Goal

继续加强 `simd` 测试基础设施审查，但这次不再处理 suite fixture 生命周期，而是收敛一处更深的 helper 冗余：去掉 `fafafa.core.simd.testcase` 对 `fixturehelpers` 的同名转发 façade，让 backend/vector-asm save-restore 只保留一个真实 helper 来源。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `testcase` 是否只是 `fixturehelpers` 的转发表面 | completed | 已确认 `RestoreSavedBackendState` 与 `RestoreSavedBackendAndVectorAsmState` 在 `testcase` 中完全直通 `fixturehelpers`，没有附加任何 suite-specific 语义；调用者只是经由 `testcase` 间接依赖它们 |
| 2. 让调用者直接依赖真实 helper 单元 | completed | 已删除 `testcase` 里的同名 façade；`dataplane/direct/dispatchapi/publicabi/concurrent/ieee754/dispatchslots` 现直接 `uses fafafa.core.simd.fixturehelpers` |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release 定向 suite、Release `check`、Release `gate` 全绿；说明 helper 真相源收敛没有破坏外围 runner、CPUInfo、public ABI 或 dispatch contract 链路 |

## 2026-05-14 Runtime Backend Fixture Alignment

### Goal

继续加强 `simd` 测试层审查并修复，但这次只处理 `runtime.testcase` 里仍手工保存/恢复 backend 的 3 个控制面测试：让 `TTestCase_RuntimeAPI` 直接挂回现有 `TSimdBackendStatefulTestCase`，把 cleanup 交还公共 fixture，而不改任何 runtime 实现或断言语义。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `runtime` suite 是否符合公共 backend fixture 边界 | completed | 已确认 `RuntimeAPI` suite 不需要 vector-asm、hook reset、rebind 或 exception-mask 语义；它的特殊点只在少数测试里手工 cleanup backend，与 `TSimdBackendStatefulTestCase` 完全同边界 |
| 2. 对齐到公共 backend-stateful 基类 | completed | `TTestCase_RuntimeAPI` 已改继承 `TSimdBackendStatefulTestCase`；3 个控制面测试删除手工保存/恢复 backend 的 finally 清理，只保留原有 runtime/facade 行为断言 |
| 3. Release 验证与提交收口 | completed | 首轮定向 build 因空 `var` 段报语法错，最小修正后 Release `TTestCase_RuntimeAPI`、Release `check`、Release `gate` 全绿；本轮仍然只是测试 fixture 对齐，不改 runtime 生产逻辑 |

## 2026-05-14 Verified Restore Helper Consolidation

### Goal

继续加强 `simd` 测试基础设施审查并修复，但这次不再只是对齐基类，而是把多处“restore 后再比一次 backend getter”的重复验证壳下沉到 `fixturehelpers`：统一 `backend-only` 与 `backend+vectorasm` 的 verified restore helper，收走 `dispatchslots/backend.consistency/backend vector consistency/ieee754` 的局部 wrapper，以及 `concurrent/dataplane/dispatchapi/publicabi` 的重复布尔拼接。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核哪些 local helper 只剩“restore + backend getter 校验” | completed | 已确认 `RestoreDispatchSlotsLocalState`、`RestoreBackendVectorConsistencyLocalState`、`RestoreIEEE754LocalState` 这类点都没有 suite-specific 语义；`concurrent/publicabi/dispatchapi/dataplane` 里的局部 restore 断言也只是在重复同一验证拼接 |
| 2. 抽共享 verified restore helper 并收掉局部薄壳 | completed | `fixturehelpers` 已新增 `RestoreSavedBackendStateAndVerify` 与 `RestoreSavedBackendAndVectorAsmStateAndVerify`；相关 suite/helper 改为直接复用，删除 `dispatchslots` / `backend vector consistency` / `ieee754` 的冗余局部 wrapper |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release 定向 suite、Release `check`、Release `gate` 全绿；说明共享 callback-style verified restore helper 在 FPC 下可稳定工作，且未影响 run_all/public ABI/cpuinfo 外围链路 |

## 2026-05-14 Direct Restore Helper Alignment

### Goal

继续加强 `simd` 测试层审查并修复，但这次只收 `direct.testcase` 在 verified helper 批次后仍残留的两段手工 restore 本体：保留 `RebindDirectDispatch` 这种 suite-specific 后处理动作，把“恢复 backend/vectorasm 并校验 backend 已回到原值”的主体统一交还 `fixturehelpers`。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `direct` 剩余 local restore helper 的真实语义边界 | completed | 已确认 `TDirectDispatchStatefulTestCase.RestoreFixtureDirectDispatchState` 与并发 cleanup 的特殊点只剩 `RebindDirectDispatch`；restore state + verify backend restored 本体已经不应继续手写 |
| 2. 对齐到共享 verified restore helper | completed | `RestoreFixtureDirectDispatchState` 现改用 `RestoreSavedBackendAndVectorAsmStateAndVerify(...)`；`RunDirectDispatchConcurrentReRegisterSnapshotConsistency` 的 cleanup 改用 `RestoreSavedBackendStateAndVerify(...)`，同时保留原有 `RegisterBackend(sbScalar, ...)` 与 `RebindDirectDispatch` 时序 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent`、Release `check`、Release `gate` 全绿；本轮继续串行验证，避免 `tests/fafafa.core.simd` 共享输出目录假红 |

## 2026-05-14 Backend Fixture Restore Contract Alignment

### Goal

继续加强 `simd` 测试基础设施审查并修复，但这次不再盯单个 suite，而是收掉公共 `backend-stateful` 基类自身还保留的手工 restore choreography，并顺手清掉 `publicabi` 中唯一剩下的裸 `RestoreSavedBackendState(...)` 调用，让 verified helper 真正成为 backend restore 的统一 contract。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核剩余 raw backend-restore caller 的真实影响面 | completed | 精确扫描后确认 stable test path 里最显眼的残点只剩两处：`TSimdBackendStatefulTestCase.TearDown` 自己仍手写 `ResetBackendSelection + TrySetActiveBackend + getter compare`，以及 `publicabi` 一处 finally cleanup 仍只做未校验的 `RestoreSavedBackendState(...)` |
| 2. 对齐到共享 verified helper contract | completed | `TSimdBackendStatefulTestCase.TearDown` 现改用 `RestoreSavedBackendStateAndVerify(FSavedBackend, @GetCurrentBackend)`；`publicabi` 那处 finally cleanup 同步改用 `RestoreSavedBackendStateAndVerify(LOriginalBackend, @GetCurrentBackend)` |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_RuntimeAPI,TTestCase_PublicAbi`、Release `check`、Release `gate` 全绿；说明公共 backend fixture 收口后，`vector-asm` 派生 suite、public ABI smoke 和 run_all 链路都继续稳定 |

## 2026-05-14 DispatchSlots Redundant Finally Cleanup Removal

### Goal

继续加强 `simd` 测试层审查并修复，但这次只清 `dispatchslots.testcase` 里三处与公共 `TSimdBackendStatefulTestCase` teardown 完全重叠的手工 backend-restore finally：不改 dispatch contract 断言本体，只删冗余 cleanup，并同步去掉不再需要的 `fixturehelpers` 依赖。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `dispatchslots` 的手工 restore 是否已被公共基类覆盖 | completed | 已确认 `TTestCase_DispatchAllSlots` 直接继承 `TSimdBackendStatefulTestCase`，而 3 个 finally 里的 `RestoreSavedBackendStateAndVerify(FSavedBackend, @GetActiveBackend)` 只发生在方法末尾；这些点与 suite teardown 的 backend restore contract 完全重叠 |
| 2. 删除冗余 finally cleanup | completed | 已删除 `Test_AllSelectableBackends_AllDispatchSlots_Assigned`、`Test_BackendAdapter_ActiveBackend_RoundTrip_NoNilAndCorePointersStable`、`Test_BackendAdapter_RegisteredBackendOps_PreserveCanonicalTextMetadata_After_ReRegister` 末尾的手工 backend restore；第三个测试只保留必要的 `RegisterBackend(LBackend, LOriginalTable)` 注册表恢复；`dispatchslots.testcase` 也去掉了未再使用的 `fixturehelpers` |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DispatchAllSlots`、Release `check`、Release `gate` 全绿；说明 dispatch contract/adapter roundtrip/re-register 路径在回归公共 teardown 后依然稳定 |

## 2026-05-15 Concurrent Tail Restore Cleanup Removal

### Goal

继续加强 `simd` 测试层审查并修复，但这次把 `concurrent.testcase` 中一整批只出现在方法尾部的 `RestoreSimdLocalState(...)` 清理掉：这些调用不再承载中途恢复语义，而是与 `TSimdVectorAsmStatefulTestCase.TearDown` 完全重叠。目标是不改并发断言逻辑和本地 register rollback，只删多余尾部 restore，并移除失效的 wrapper/依赖。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `concurrent` 本地 restore wrapper 的使用形状 | completed | 已确认 `TSimdStatefulTestCase.RestoreSimdLocalState(...)` 只在多个测试的 `finally` 尾部调用，调用后立即结束测试；没有任何一次是在同一测试中用于“恢复后继续断言” |
| 2. 删除冗余 tail restore 与失效 wrapper | completed | 已删除 `TSimdStatefulTestCase.RestoreSimdLocalState(...)` 声明/实现、`concurrent.testcase` 对 `fixturehelpers` 的依赖，以及所有方法尾部 `RestoreSimdLocalState(LOldVectorAsm, FSavedBackend)` 调用；保留了线程释放、`RegisterBackend(..., LOriginalTable/LRestoreTable)` 这类真正 suite-local rollback |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_SimdConcurrent,TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework,TTestCase_SimdConcurrentRegistration`、Release `check`、Release `gate` 全绿；说明并发/teardown 时序在回归公共 `vector-asm` fixture 后依然稳定 |

## 2026-05-15 PublicAbi Tail Restore Cleanup Removal

### Goal

继续加强 `simd` 测试层审查并修复，但这次只处理 `publicabi.testcase` 里已经退化成纯尾部 cleanup 的 `RestorePublicAbiLocalState(...)`：不改 public ABI 断言本体，也不改 hook/reset/register rollback，只把所有“调用后测试立刻结束”的 local restore 和对应 wrapper 删除，让 `TSimdVectorAsmStatefulTestCase.TearDown` 成为唯一 restore contract。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `publicabi` local restore 是否还承载 post-restore 语义 | completed | 已确认 `RestorePublicAbiLocalState(...)` 的全部调用点后面都直接收尾，没有任何一次是在同一测试中“恢复后继续观察”；文件内仅剩一处与此无关的 backend-only `RestoreSavedBackendStateAndVerify(...)` |
| 2. 删除冗余 tail restore 与失效 wrapper | completed | 已删除 `RestorePublicAbiLocalState(...)` 声明/实现，以及全部尾部 `RestorePublicAbiLocalState(FSavedVectorAsm/LOldVectorAsm, FSavedBackend)` 调用；`publicabi` 仍保留 `fixturehelpers`，因为 `Test_PublicApi_ActiveBackendId_Tracks_RuntimeSelection` 还直接使用 backend-only verified restore |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_PublicAbi`、Release `check`、Release `gate` 全绿；说明 public ABI table/cached snapshot/metadata/control-plane regression 链路在回归公共 teardown 后依然稳定 |

## 2026-05-15 DispatchApi Tail Restore Cleanup Removal

### Goal

继续加强 `simd` 测试层审查并修复，但这次只处理 `dispatchapi.testcase` 里已经退化成纯尾部 cleanup 的 `RestoreDispatchApiLocalState(...)`：不改 dispatch/public/backend contract 断言本体，也不改 hook reset、register rollback 或 non-x86 parity 主体，只把所有“调用后测试立刻结束”的 local restore 和对应 wrapper 删除，让 `TSimdVectorAsmStatefulTestCase.TearDown` 继续作为唯一 backend/vector-asm restore contract。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `dispatchapi` local restore 是否还承载 post-restore 语义 | completed | 已确认 `RestoreDispatchApiLocalState(...)` 只是一层 `RestoreSavedBackendAndVectorAsmStateAndVerify(...)` 包装；调用点共 117 处，其中 `FSavedVectorAsm` 31 处、`LOldVectorAsm` 86 处。机械扫描显示绝大多数调用后直接 `end;`，少数只跟 `FreeAligned(...)`、局部变量清零或 `if LChecked = 0 then ...` 这类不依赖“已恢复 backend/vector-asm”的收尾语句 |
| 2. 删除冗余 tail restore 与失效 wrapper | completed | 已删除 `TDispatchAPIStatefulTestCase.RestoreDispatchApiLocalState(...)` 声明/实现、`dispatchapi.testcase` 对 `fafafa.core.simd.fixturehelpers` 的依赖，以及全部 117 处尾部 `RestoreDispatchApiLocalState(FSavedVectorAsm/LOldVectorAsm, FSavedBackend)` 调用；保留所有 hook/reset/register rollback、`FreeAligned(...)`、non-x86 parity 断言与 suite-local 资源释放 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DispatchAPI`、Release `check`、Release `gate` 全绿；说明 `dispatchapi` 在回归公共 teardown 后，dispatch contract/public ABI smoke/non-x86 opt-in/cpuinfo/run_all 链路都继续稳定 |

## 2026-05-15 DataPlane And IEEE754 Tail Verified-Restore Cleanup

### Goal

继续加强 `simd` 测试层审查并修复，但这次不再盯 local wrapper，而是收掉 `dataplane.testcase` 与 `ieee754.testcase` 里那些已经退化成纯尾部 cleanup 的 direct verified-restore caller：它们同样运行在 `TSimdVectorAsmStatefulTestCase` 派生类里，调用后直接结束测试，因此不该再重复执行公共 teardown contract。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `dataplane/ieee754` direct verified-restore caller 是否还承载 post-restore 语义 | completed | 已确认 `dataplane` 仅 1 处、`ieee754` 共 10 处 `RestoreSavedBackendAndVectorAsmStateAndVerify(...)` 调用，且都位于 `finally` 尾部；机械扫描显示调用后统一直接 `end;`，没有任何一处是在恢复后继续依赖 backend/vector-asm 状态做同测断言 |
| 2. 删除冗余 tail caller 与失效依赖 | completed | 已删除 `dataplane.testcase` 与 `ieee754.testcase` 中全部 11 处尾部 verified-restore 调用，并同步删除两文件对 `fafafa.core.simd.fixturehelpers` 的失效依赖；测试主体、异常 mask、非 x86/AVX2/SSE2 IEEE754 断言与 dataplane snapshot 断言保持不变 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DataPlane,TTestCase_IEEE754EdgeCases,TTestCase_AVX2RoundTruncIEEE754,TTestCase_NonX86IEEE754`、Release `check`、Release `gate` 全绿；说明这类 direct verified-restore caller 也只是历史 cleanup 复制体，而不是 suite-specific 状态语义 |

## 2026-05-15 Direct Tail Restore Split Cleanup

### Goal

继续加强 `simd` 测试层审查并修复，但这次把 `direct.testcase` 里“混合 helper”进一步拆开：保留那 2 处恢复后还要继续观察 `dispatch/direct` 对齐的 `RestoreFixtureDirectDispatchState(...)` 调用，删除其余所有已经退化成纯尾部 cleanup 的调用，让 `TSimdVectorAsmStatefulTestCase.TearDown + RebindDirectDispatch` 成为这些测试的唯一收口路径。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `direct` 调用点是否混有 post-restore 语义 | completed | 已确认 `RestoreFixtureDirectDispatchState(...)` 共 28 处使用中，仅 `Test_DirectDispatchTable_Rebind_AfterForceBackend` 与 `Test_DirectDispatchTable_AutoRebind_AfterDispatchSetActiveBackend` 这 2 处在 finally 之后继续断言 `dispatch/direct` 已随恢复状态重新对齐；其余 26 处要么直接 `end;`，要么只剩 `FreeAligned(...)` 这类资源释放 |
| 2. 删除尾部 cleanup 调用并保留必要 post-restore caller | completed | 已删除 `direct.testcase` 中 26 处尾部 `RestoreFixtureDirectDispatchState(...)` 调用，保留 2 处真正需要“恢复后继续观察 direct table”语义的调用；`RestoreFixtureDirectDispatchState` helper 本身保留，因为它仍承载 `RebindDirectDispatch + verified restore` 的组合 contract |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent`、Release `check`、Release `gate` 全绿；说明 `direct` 已被细分成“真 post-restore 语义”与“纯尾部 cleanup”两类，而不会把 `RebindDirectDispatch` 这条本地 contract 一起误删 |
