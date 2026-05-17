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
| `mcp__ace_tool__.search_context` 在这轮 `publicabi` 收口前返回 `ACE_TOKEN` 失效 | 1 | 不在同一失败路径上重试，直接回退到 `git diff` 与本地 `rg/sed` 复核 helper 与断言消息调用面 |
| `DispatchAPI` 长块补丁首轮因上下文未精确命中而未应用 | 1 | 先按区段重新读取 `dispatchapi.testcase` 的目标过程，再做定点 patch，避免误伤长测试块 |
| `check_nonx86_register_truthfulness.py` 首轮把 16 个既有 asm-only wrapper slot 误判成 miswired | 1 | 收紧规则时保留旧 allowlist 仅在 asm-only 上下文同样生效，并为 NEON wide compare 单独引入 asm-only allowlist 后，neon/riscvv strict 复验恢复全绿 |

## 2026-05-16 NEON No-Asm F64 Sqrt/Round/Trunc Dead-Wrapper Cleanup

### Goal

继续收口 `NEON` no-asm `F64` 残余，把已经没有 live source consumer 的 `Sqrt/Round/Trunc` wrapper 从 published ownership 链里彻底移除。

### Phases

| Phase                               | Status    | Notes                                                                                                                                                                           |
| ----------------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. 复核 source-consumer graph       | completed | 已确认 `NEON(Sqrt|Round|Trunc)F64x2/F64x4` 在 no-asm 下只剩 `scalar.autowrap.inc` 自供、`register.inc` 的 asm 绑定源码，以及 `DispatchAPI` 旧护栏，没有其他 live 消费者        |
| 2. 删除 dead wrapper 并收正护栏     | completed | 已删除 `NEONRound/Sqrt/TruncF64x2/F64x4` no-asm wrapper；`DispatchAPI` 四个 dedicated 护栏改成“dead wrapper removed + asm binding still present + no-asm runtime reuse scalar” |
| 3. Release 验证与收口               | completed | `git diff --check`、truthfulness(neon/riscvv)、Release `DispatchAPI`、Release `IEEE754EdgeCases`、`impl-audit-nonx86`、Release `check`、Release `gate` 全部通过                  |

## 2026-05-16 NEON No-Asm Wide Integer Compare Slot-Ownership Cleanup

### Goal

继续沿 `NEON` no-asm slot ownership truth 线，把 wide integer compare 这 36 个 published slot 从“no-asm 仍声称 backend-owned”收回到 base scalar truth；同时保留 wide compare wrapper 作为 narrower-helper composition 的 source companion，并让 checker/dispatch 护栏都按这个真实边界说话。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 wide integer compare 的 source role、register truth 与 checker 旧豁免 | completed | 已确认 `CmpEq/Ge/Gt/Le/Lt/Ne` 的 `I32x8/I32x16/I64x4/I64x8/U32x8/U64x4` 共 36 个 slot 之前在 `src/fafafa.core.simd.neon.register.inc` 里是无条件 backend-owned；但 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 的 no-asm body 只是在组合更窄 helper，没有独立 backend-local truth；旧的 `check_nonx86_register_truthfulness.py` 也只靠宽 compare allowlist 粗放放行 |
| 2. 收回 no-asm published ownership，并同步 checker/dedicated test 语义 | completed | 已把 `src/fafafa.core.simd.neon.register.inc` 中这 36 个 compare 绑定改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}`；`tests/fafafa.core.simd/check_nonx86_register_truthfulness.py` 已把它们从 generic `ALLOWED_WRAPPER_SLOTS_BY_BACKEND['neon']` 拆出，改为 `ALLOWED_ASM_ONLY_WRAPPER_SLOTS_BY_BACKEND['neon']`，同时保留既有 float wrapper allowlist 在 asm-only 上下文的合法性；`dispatchapi` 已新增 `Test_NEON_NoAsmWideIntegerCompareSlots_Keep_SourceCompanions_But_Reuse_BaseScalar`，并把旧 `NoAsmIntegerFallback` 大护栏里的 compare 断言拆出 |
| 3. 串行 release 复验并更新当前 truth | completed | fresh `git diff --check`、`python3 -m py_compile tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`、`truthfulness --backend neon/riscvv --summary-line --strict`、Release `TTestCase_DispatchAPI`、Release `impl-audit-nonx86`、Release `check`、Release `gate` 全部通过；当前 `backend=neon` truthfulness 仍为 `assignments=342 asm_exact=277 asm_suffix_only=10 wrapper_only=55 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`，说明这批收的是 no-asm published ownership 真相，而不是继续删 source companion |

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

## 2026-05-15 Backend Consistency Setup Helper Consolidation

### Goal

继续加强 `simd` 测试层审查并修复，但这次转向新的冗余类型：`backend.consistency.testcase` 里一批 free helper 反复复制同一段结果初始化、backend 保存/跳过判定、`TrySetActiveBackend(...)` 选择逻辑。目标不是删 fixture teardown，而是把这类共享 setup/skip contract 收回 helper，同时保留原本“fallback 不应算通过”的语义。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `backend.consistency` free helper 的重复 setup/skip 形状 | completed | 已确认 `F32x4 Arithmetic/Math/Comparison/Reduction`、`I32x4 Arithmetic/Bitwise` 与 `Facade MemOps` 这 7 个 free helper 都在重复：初始化 `TConsistencyTestResult`、保存原 backend、`IsBackendRegistered(...)` 跳过、`TrySetActiveBackend(...)` 跳过；这类逻辑不受 fixture teardown 直接覆盖 |
| 2. 提取共享 begin/init helper 并保留原有 backend 选择语义 | completed | 已新增 `InitBackendConsistencyResult(...)` 与 `BeginBackendConsistencyTest(...)`；7 个 helper 统一改用共享入口。`Begin...` 继续使用 `TrySetActiveBackend(...)`，并在“未注册 / 当前 CPU/OS 不可用”的早退路径上显式恢复已保存 backend，避免 free helper 提前 `Exit` 后把状态泄漏给后续 case |
| 3. Release 验证与提交收口 | completed | Release `TTestCase_BackendVectorConsistency`、Release `check`、Release `gate` 已通过；说明这轮从“尾部 restore 去重”转到“free helper setup/skip 合同收敛”后，backend consistency 主测试面和整体 gate 都继续稳定 |

## 2026-05-15 Backend Consistency Name And Matrix Truth Consolidation

### Goal

继续加强 `simd` 测试层审查并修复，这次处理 `backend.consistency` 剩余的一处真实真相源分叉：`RunAllConsistencyTests`、`PrintTestSummary`、root wrapper 和 helper meta-test 各自维护 backend 名称/候选 backend/执行矩阵，结果 `SSE3/SSSE3/SSE4.1/SSE4.2` 在摘要里会被打成 `Unknown`。目标是把 backend 名称与 backend 矩阵收成一处，并补回归点锁住这类 drift。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `backend.consistency` 剩余的名称/矩阵重复真相源 | completed | 已确认 `PrintTestSummary(...)` 只覆盖了 `Scalar/SSE2/AVX2/AVX512/NEON/RISCVV`，而 `RunAllConsistencyTests(...)` 实际会跑 `SSE3/SSSE3/SSE4.1/SSE4.2`；同时 `TTestCase_BackendVectorConsistency.Test_VectorOps_Consistency` 还内嵌了另一份本地 `BackendName(...)`，标签也和摘要不完全一致 |
| 2. 收敛 backend 名称 helper 与执行矩阵 | completed | 已在 `backend.consistency.testcase` 对外提供 `CONSISTENCY_BACKENDS` 与 `GetConsistencyBackendName(...)`；`RunAllConsistencyTests(...)` 改用共享 backend 常量 + function-array 驱动，`PrintTestSummary(...)` 与 root wrapper 统一复用同一名称 helper；并新增 `Test_VectorOps_BackendName_Coverage` 锁住中间 x86 tiers 不再回落成 `Unknown` |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_BackendVectorConsistency`、Release `check`、Release `gate` 已通过；说明这轮既修了摘要名称 bug，也把 backend consistency 的矩阵/名称真相源从多份收回成一份，且未影响 run_all/public ABI/non-x86 门禁 |

## 2026-05-15 Backend Consistency Meta-Test Candidate Reuse

### Goal

继续沿同一条线收尾：在 `backend consistency` 已经导出 `CONSISTENCY_BACKENDS` 与 `GetConsistencyBackendName(...)` 之后，把 `TTestCase_BackendVectorConsistency.Test_VectorOps_Helper_Preserves_PreviousForcedBackend` 里剩余的本地 candidate 列表和编号式失败信息也收回共享 helper，避免刚统一完的真相源又在 meta-test 里留一份副本。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 meta-test 是否还复制 backend candidate truth source | completed | 已确认 `Test_VectorOps_Helper_Preserves_PreviousForcedBackend` 仍保留本地 `CBackendCandidates`，内容与 `CONSISTENCY_BACKENDS` 相同；helper sanity failure 也只打印 `Ord(LTargetBackend)`，诊断面仍落后于刚统一好的 backend-name helper |
| 2. 统一复用共享 candidate/name helper | completed | 已删掉本地 `CBackendCandidates`，改直接遍历 `CONSISTENCY_BACKENDS`；helper sanity failure 信息也改用 `GetConsistencyBackendName(LTargetBackend)`，不再只输出 backend 编号 |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_BackendVectorConsistency`、Release `check`、Release `gate` 已通过；说明这轮把 meta-test 残余副本也收回共享 helper 后，backend consistency 主线仍保持稳定 |

## 2026-05-15 Backend Consistency Dispatch-Truth Name And Report Helper Reuse

### Goal

继续沿 `backend consistency` 的 control/report 真相源收尾：既然 `dispatch.GetBackendInfo(...)` 已经为注册/未注册 backend 提供 canonical name/description，就不该继续在 `backend.consistency` 里维护一份本地 backend name `case` 表。同时，root wrapper 与 summary 对 `skipped`/failure 文案的解释也已经开始重复，适合收成共享 helper。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 dispatch 层能否作为 backend consistency 名称真相源 | completed | 已确认 `GetBackendInfo(...)` 对 registered/unregistered backend 都会补齐 canonical `Name/Description`，并与 `GetBackendNameTextPtr(...)` 的默认 fallback 语义对齐；因此 `GetConsistencyBackendName(...)` 的本地 `case` 映射已经是重复 truth source |
| 2. 收敛到 dispatch truth，并合并 skip/fail 报告壳 | completed | `GetConsistencyBackendName(...)` 已改为薄封装 `GetBackendInfo(aBackend).Name`；同时新增 `IsConsistencyTestSkipped(...)` 与 `FormatConsistencyFailureText(...)`，让 `PrintTestSummary(...)` 与 `TTestCase_BackendVectorConsistency.Test_VectorOps_Consistency` 共享 `skipped` 判定和 failure 文案拼接，而不再各自解释结果 record |
| 3. Release 验证与提交收口 | completed | `git diff --check`、Release `TTestCase_BackendVectorConsistency`、Release `check`、Release `gate` 已通过；说明这轮继续把 report/control shell 收回共享 helper 后，backend consistency 主线和整体 fast-gate 都保持稳定 |

## 2026-05-15 Smoke Tool Canonical Name Reuse And Standalone Build Fix

### Goal

继续加强 `simd` 辅助 smoke 工具的审查并修复，但这次只处理两类真实问题：一是 `dispatch_preinit_smoke/public_smoke` 仍保留本地 backend-name 薄壳，二是 `public_smoke` 缺少 `{$mode objfpc}{$H+}`，导致它作为独立 `fpc` smoke 入口时会直接编译失败。目标是把名称真相源下沉到 `dispatch.GetBackendInfo(...)`，补齐独立编译合同，并确保手工 smoke 验证不会再次污染 `src/` 树卫生。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 smoke 工具残余重复 helper 与独立编译合同 | completed | 已确认 `dispatch_preinit_smoke` 与 `public_smoke` 都保留本地 `BackendName(...)` 包装；其中 `public_smoke` 还缺 `{$mode objfpc}{$H+}`，在 raw `fpc` 独立编译时会因为 `Result` 关键字不可用而失败 |
| 2. 收敛到 dispatch canonical metadata 并补齐 standalone build 依赖 | completed | 两个 smoke 工具都已删除本地 `BackendName(...)` 薄壳，直接复用 `GetBackendInfo(...).Name`；`public_smoke` 已补 `{$mode objfpc}{$H+}`、引入 `fafafa.core.simd.dispatch`，并顺手把局部变量/参数名收敛到仓库命名规范 |
| 3. Release 验证与提交流水收口 | completed | `git diff --check`、临时目录独立 `fpc` 编译并实际运行 `public_smoke`、Release `check`、Release `gate` 已通过；期间还修正了“raw `fpc` 编译把 `.o/.ppu` 落进 `src/` 导致 gate hygiene 红灯”的验证陷阱，最终 `run_all` 明确回到 `src tree hygiene: no .o/.ppu/.bak artifacts` 绿态 |

## 2026-05-15 Bench Canonical Backend Label Reuse

### Goal

继续沿“小型 runner/utility 的本地真相源”这条线收尾，但这次只处理 `fafafa.core.simd.bench`：它仍保留一份 `GetBenchmarkBackendName(...)` 名称表和一层 `GetBackendName` 包装。目标是把 benchmark 的 skip 文案与标题标签统一下沉到 `dispatch.GetBackendInfo(...).Name`，不碰 benchmark 本体、迭代参数或输出布局。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `bench` 中 backend 名称 helper 的真实使用面 | completed | 已确认 `GetBenchmarkBackendName(...)` 只服务 `TryActivateBenchmarkBackend(...)` 的 skip/fallback 文案和 `PrintBenchResults(...)` 标题标签；没有承载任何 benchmark 逻辑或 platform-specific 行为 |
| 2. 删除本地名称表并直接复用 dispatch canonical metadata | completed | 已删除 `GetBenchmarkBackendName(...)` 与 `GetBackendName`；skip/fallback 文案和 benchmark 标题统一改为 `GetBackendInfo(...).Name`，不再在 bench unit 里重复存储 backend label 本体 |
| 3. Release 验证与提交流水收口 | completed | `git diff --check`、Release `check`、Release `gate` 已通过；说明 bench 被主测试 runner/BuildOrTest 编译进来后仍然稳定，`run_all` 最后也继续保持 5/5 绿态 |

## 2026-05-15 Standalone Program Entry Contract Repair

### Goal

继续把审查范围从主 runner/bench 推到仓库里残留的独立 program 入口：这次目标是修复 `test_backend_ops` / `test_simd_boundary` 的入口合同漂移，包括缺失的 `fafafa.core.settings.inc`、失真的 `test_backend_ops.lpi` 主单元指向、`test_simd_boundary` 的真实 standalone compile 断点，以及它的 UTF-8 banner/summary 输出污染。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核独立 program 入口是否仍受活跃验证覆盖 | completed | 已确认 `test_backend_ops.pas` 与 `test_simd_boundary.pas` 都缺 `{$I ../../src/fafafa.core.settings.inc}`；`test_backend_ops.lpi` 甚至错误指向 `fafafa.core.simd.test.lpr`，`lazbuild -B` 实际会去编整套主测试工程，而不是自己的 program |
| 2. 修入口合同并收掉真实 standalone 缺陷 | completed | 已为两个 program 补 `settings.inc`；`test_backend_ops.lpi` 主单元已改回 `test_backend_ops.pas`；`test_simd_boundary` 的 `NegInfinity` 已改成 `-posInf`；其 banner/summary 文案还进一步显式收为 `UTF8String(...)`，避免旧编码污染落成 `?` |
| 3. 独立构建/运行与主检查链复验 | completed | `git diff --check`、临时目录 `fpc` 编译并实际运行 `test_backend_ops`、临时目录 `fpc` 编译并实际运行 `test_simd_boundary`、UTF-8 输出落盘校验、`lazbuild -B tests/fafafa.core.simd/test_backend_ops.lpi`、Release `check` 已通过；说明这批入口现在既能独立自证，也不再误指向主测试 runner |

## 2026-05-15 DispatchAPI Canonical Backend Name Reuse Batch 1

### Goal

继续加强 `simd` 测试层审查并修复，但这次严格限定在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 当前这一簇残留的局部 `BackendName(...)` 副本：把只用于断言消息的 backend 名称映射收敛到文件级 `DispatchApiBackendName(...) -> GetBackendInfo(...).Name`，不碰 capability membership / backend 分组判断。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核当前一簇 `BackendName(...)` 是否只是消息名来源 | completed | 已确认 `Test_BackendCapabilities_DoNotUnderclaim_Shuffle`、`Test_X86_BackendCapabilities_DoNotUnderclaim_MaskedOps`、`Test_BackendCapabilities_Clear_IntegerOps_When_VectorAsmDisabled`、`Test_X86_BackendCapabilities_Keep_MaskedOps_When_VectorAsmDisabled` 里的局部 `BackendName(...)` 只参与 `AssertTrue/AssertFalse` 文案拼接；真正的 capability 判断仍在 `IsX86MaskedOpsBackend(...)`、`IsVectorAsmGatedX86Backend(...)` 等局部 helper |
| 2. 收敛到文件级 canonical name helper | completed | 已删除这 4 个 procedure 的局部 `BackendName(...)`，统一改用文件级 `DispatchApiBackendName(...)`；这样 `dispatchapi.testcase` 里这一簇失败消息不再自带一份本地 backend 名称表 |
| 3. Release 验证与本批收口 | completed | `git diff --check`、Release `TTestCase_DispatchAPI`、Release `check`、Release `gate` 已全部通过；说明这批只收掉消息层冗余，没有影响 dispatch capability gate |

### Next Slice

- `dispatchapi.testcase` 里剩余局部 `BackendName(...)` 还在约 `10613/10788/10821/10925/10962` 一簇；适合下一批继续做。
- 文件级 `NonX86BackendName(...)` 仍保留，涉及 non-x86 测试消息面，放到后续 non-x86 小批次单独处理更稳。

## 2026-05-15 DispatchAPI Canonical Backend Name Reuse Batch 2

### Goal

继续沿 `dispatchapi.testcase` 的同一条线收尾，把上一批标记出来的下一簇局部 `BackendName(...)` 一次性收掉：覆盖 `x86 shuffle capability`、`x86 grouped wiring checklist`、`non-x86 grouped wiring checklist`、`non-x86 wiring checklist` 与 `non-x86 native wide floor/ceil slot` 这 5 个过程，但仍然只收“断言消息用的 backend 名称源”，不碰 backend gating / asm enable / non-x86 opt-in 判定。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核下一簇局部 `BackendName(...)` 的真实职责 | completed | 已确认 `Test_X86_BackendCapabilities_Clear_Shuffle_When_VectorAsmDisabled`、`Test_NonX86_DispatchTable_WiringChecklist_Grouped`、`Test_X86_DispatchTable_WiringChecklist_Grouped`、`Test_NonX86_DispatchTable_WiringChecklist`、`Test_NonX86_NativeWideFloorCeil_Slots_NotScalar_IfAvailable` 中的局部 `BackendName(...)` 都只参与断言消息拼接；真正的 backend 归类仍由 `IsShuffleCapabilityGatedBackend(...)`、`LBackends[...]`、`{$IFNDEF FAFAFA_SIMD_TEST_*}` 等边界控制 |
| 2. 收敛到文件级 canonical name helper | completed | 已删除这 5 个过程各自的局部 `BackendName(...)`，全部统一改用 `DispatchApiBackendName(...)`；这让 `dispatchapi.testcase` 不再残留 procedure-local backend 名称表 |
| 3. Release 验证与本批收口 | completed | `git diff --check`、Release `TTestCase_DispatchAPI`、Release `check`、Release `gate` 全部通过；`wiring-sync`、`dispatch-read-scope`、`nonx86 helper semantics`、`nonx86 key-slot audit` 也继续为绿 |

### Next Slice

- 当前 `dispatchapi.testcase` 已不再有局部 `BackendName(...)`。
- 剩余明确的名字 helper 是文件级 `NonX86BackendName(...)`；它服务 `TTestCase_NonX86BackendParity` 等 non-x86 测试消息面，更适合作为后续 non-x86 专项小批次处理。

## 2026-05-15 NonX86BackendName Thin Wrapper Dedup

### Goal

继续沿 `dispatchapi.testcase` / `TTestCase_NonX86BackendParity` 的消息层真相源收尾：不大面积改调用点，而是把文件级 `NonX86BackendName(...)` 本体从本地 `case` 名称表收成 `DispatchApiBackendName(...)` 的薄封装，消除 non-x86 名称副本，同时保留现有断言与 parity 测试结构。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `NonX86BackendName(...)` 是否承载额外语义 | completed | 已确认该 helper 虽被 `TTestCase_NonX86BackendParity` 广泛使用，但只向断言消息和 parity 文案提供 backend 名称；backend 集合、asm opt-in、active backend 切换、slot/数值语义都由别处控制 |
| 2. 将 helper 本体收成 canonical thin wrapper | completed | 已把 `NonX86BackendName(...)` 从本地 `case sbNEON/sbRISCVV` 名称表改为 `Result := DispatchApiBackendName(aBackend);`，去掉重复名字真相源但不触碰调用面 |
| 3. Release 验证与本批收口 | completed | `git diff --check`、Release `TTestCase_DispatchAPI,TTestCase_NonX86BackendParity`、Release `check`、Release `gate` 全部通过；`nonx86 helper semantics`、`nonx86 key-slot audit`、`wiring-sync` 继续为绿 |

### Next Slice

- 当前这个文件的 backend 名称 helper 已经都改成 canonical metadata 薄封装。
- 下一步更适合从别的重复 truth source / report shell 入手，而不是继续在这个文件里扫同类名称表。

## 2026-05-15 PublicAbi Canonical Backend Label Reuse

### Goal

继续沿 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 的消息层真相源收尾：把只用于失败消息的 backend 编号展示，从 `IntToStr(Ord(LBackend))` 收成 canonical backend label helper，同时保持 `public ABI capability / pod-info` 的语义判断完全不动。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `publicabi.testcase` 里 backend 编号是否只是消息壳 | completed | 已确认本轮触及的 `Test_PublicApi_BackendPodInfo_*` 过程里，`IntToStr(Ord(LBackend))` 只拼接断言文案；同文件中保留的 `case aBackend of` 仍承担 capability/member 语义判断，不能误删 |
| 2. 收敛到文件级 canonical label helper | completed | 已新增文件级 `PublicAbiBackendName(const aBackend: TSimdBackend): string`，实现为 `GetBackendInfo(aBackend).Name`；并把 pod-info flags、shuffle/masked/integer-ops 相关失败消息全部改用该 helper，不再输出 backend 数字编号 |
| 3. Release 验证与本批收口 | completed | `git diff --check`、Release `check`、Release `gate` 已全部通过；说明这批只改善 public ABI 测试诊断面，没有影响 capability bits、public ABI smoke 或 fast-gate 主链 |

## 2026-05-15 IEEE754 Canonical Backend Label Reuse

### Goal

继续沿 `tests/fafafa.core.simd/fafafa.core.simd.ieee754.testcase.pas` 的 report shell 收口：把 76 处只用于失败消息的 backend ordinal 文案，从 `IntToStr(Ord(LBackend))` 收成 canonical backend label helper，同时完全不触碰 IEEE754 算法、期望值与 invariant 断言本身。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `ieee754.testcase` 里的 backend ordinal 是否只是消息层 | completed | 已确认当前集中块都位于 `AssertSingleSemantics`、`AssertDoubleSemantics`、`Assert*Invariant*` 的首个上下文字符串参数，backend ord 并不参与任何数值计算、lane 选择或 expected/actual 生成 |
| 2. 新增 canonical label helper 并统一替换集中块 | completed | 已新增文件级 `IEEE754BackendName(const aBackend: TSimdBackend): string`，实现为 `GetBackendInfo(aBackend).Name`；并把 `EdgeCases` / `AVX2RoundTruncIEEE754` 相关集中块中的 76 处 `IntToStr(Ord(LBackend))` 统一替换为该 helper |
| 3. Release 验证与本批收口 | completed | `git diff --check`、Release `test --suite=TTestCase_IEEE754EdgeCases,TTestCase_AVX2RoundTruncIEEE754`、Release `check`、Release `gate` 已全部通过；说明这批只改善 IEEE754 测试诊断面，没有改变任何算术/舍入行为 |

## 2026-05-15 DispatchSlots Canonical Backend Label Reuse

### Goal

继续沿 `tests/fafafa.core.simd/fafafa.core.simd.dispatchslots.testcase.pas` 的 report shell 收口：把 562 处 `Backend=` + ordinal 的 slot/metadata 断言文案，从本地编号文本收成 canonical backend label，同时保持 dispatch slot 绑定合同、GetBackendOps metadata 校验和所有断言语义完全不动。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `dispatchslots.testcase` 里的 backend ordinal 是否只是消息层 | completed | 已确认 557 处集中在 `AssertAllDispatchSlotsAssigned(...)` 的 slot-assigned 文案前缀，另 5 处位于 `Test_BackendAdapter_UnregisteredBackendOps_PreserveCanonicalMetadata` 的消息字符串；它们都不参与 slot 检查条件或 metadata 期望值生成 |
| 2. 收敛到 canonical backend label helper | completed | 已新增文件级 `DispatchSlotsBackendName(const aBackend: TSimdBackend): string`，实现为 `GetBackendInfo(aBackend).Name`；`AssertAllDispatchSlotsAssigned(...)` 现统一复用 `LBackendSlotPrefix`，未注册 backend metadata 那 5 条消息也统一改走同一 helper |
| 3. Release 验证与本批收口 | completed | `git diff --check`、Release `test --suite=TTestCase_DispatchAllSlots`、Release `check`、Release `gate` 已全部通过；说明这批只收敛 dispatchslots 诊断前缀，没有影响 dispatch wiring、adapter sync 或 fast-gate 主链 |

## 2026-05-15 DirectDispatch Canonical Backend Label Reuse

### Goal

继续沿 `tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas` 的 report shell 收口：把 493 处 direct parity / direct dispatch / helper assertion 文案中的 backend ordinal，统一收成 canonical backend label，同时完全不触碰 direct dispatch table、parity 计算、lane 期望值和 concurrent 行为逻辑。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `direct.testcase` 里的 backend ordinal 是否只是消息层 | completed | 已确认这 493 处都位于 direct parity、slot assigned、mask helper、mem/text/search、extract/insert 等断言消息字符串；没有任何一处参与实际 direct/facade 结果计算或 backend 切换逻辑 |
| 2. 收敛到 canonical backend label helper | completed | 已新增文件级 `DirectBackendName(const aBackend: TSimdBackend): string`，实现为 `GetBackendInfo(aBackend).Name`；并把 `direct.testcase` 中所有 `+ IntToStr(Ord(LBackend/aBackend))` 消息拼接统一替换为该 helper |
| 3. Release 验证与本批收口 | completed | `git diff --check`、Release `test --suite=TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent`、Release `check`、Release `gate` 已全部通过；说明这批只改善 direct 测试诊断面，没有影响 direct parity、concurrent snapshot 或 fast-gate 主链 |

## 2026-05-15 Backend Ordinal Tail Cleanup

### Goal

把 `tests/fafafa.core.simd` 里剩下的最后 14 处 backend ordinal 消息壳一次性清零：`dispatchapi.testcase` 复用既有 `DispatchApiBackendName(...)`，`simd.testcase` 复用既有 `GetConsistencyBackendName(...)`，同时验证整个 `tests/fafafa.core.simd` 目录内不再残留 `IntToStr(Ord(LBackend/aBackend))` 这类 backend 编号文案。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核剩余 tail 是否仍是纯消息层 | completed | 已确认 `dispatchapi.testcase` 剩余 13 处只是 supported/registered/dispatchable 视图与 canonical metadata 断言文案，`simd.testcase` 剩余 1 处只是 backend consistency helper coverage 的消息字符串 |
| 2. 复用既有 canonical helper 清零 tail | completed | `dispatchapi.testcase` 这 13 处已统一改为 `DispatchApiBackendName(LBackend)`；`simd.testcase` 那 1 处已改为 `GetConsistencyBackendName(LBackend)`；全目录 `rg -n "IntToStr\\(Ord\\((L|a)Backend\\)\\)" tests/fafafa.core.simd --glob '*.pas'` 已无匹配 |
| 3. Release 验证与本批收口 | completed | `git diff --check`、Release `test --suite=TTestCase_DispatchAPI,TTestCase_NonX86BackendParity,TTestCase_BackendVectorConsistency`、Release `check`、Release `gate` 已全部通过；说明这批只清理最后的 backend ordinal 文案，没有影响 dispatch/non-x86/backend consistency 主链 |

## 2026-05-15 Concurrent Canonical Backend Label Reuse

### Goal

在目录级 `IntToStr(Ord(...))` backend ordinal 文案已经清零后，继续深审 `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas`，把剩余通过 `Format(...%d...)`、backend array 描述和 synthetic registration metadata 泄漏出来的 backend 编号也收成 canonical backend name，同时明确保留真正参与断言/seed 的 `Ord(...)` 数值语义。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `concurrent.testcase` 里剩余 `Ord(...)` 的角色 | completed | 已确认 `DescribeBackendInfoLocal`、`DescribeBackendArrayLocal`、`DescribeRuntimeSnapshotLocal`、mixed snapshot 错误文本以及 synthetic first-registration metadata 都只是 report shell；而 `AssertEquals(..., Ord(...))` 数值断言与 `QWord(Ord(LBackend))` seed 仍承载真实比较/随机化语义，不能机械替换 |
| 2. 收敛到 concurrent canonical helper | completed | 已新增 `ConcurrentBackendName(const aBackend: TSimdBackend): string`，实现为 `GetBackendInfo(aBackend).Name`；并把上述描述函数、mixed snapshot 诊断文本与 `ConcurrentFirstRegister_*` metadata 统一改为 backend name |
| 3. Release 验证与本批收口 | completed | 接手前已有 Release `TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework,TTestCase_DirectDispatchConcurrent` 与 Release `check` 绿证据；本轮继续完成 `git diff --check` 与 Release `gate`，确认 fast-gate 中 `PublicAbi` concurrent chain、`TTestCase_DirectDispatchConcurrent`、filtered `run_all` 全部通过 |

## 2026-05-15 Public Smoke Canonical Backend Output

### Goal

继续把深审范围从 testcase/report shell 扩到独立 program 入口：修复 `tests/fafafa.core.simd/fafafa.core.simd.public_smoke.pas` 仍在 user-facing 输出里同时打印 backend ordinal 和 canonical name 的冗余，同时把这个 standalone smoke 做一次真实编译运行验证，不把它误当成主 runner 已覆盖的入口。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `public_smoke` 是否真的独立、以及当前输出冗余形态 | completed | 已确认 `public_smoke.pas` 不是主 `fafafa.core.simd.test.lpi` runner 的一部分；独立 `fpc` 编译运行时会输出 `Backend:    6 (AVX2)`，说明它还把 enum ordinal 暴露到了 user-facing smoke 输出里 |
| 2. 收敛到文件级 canonical backend helper | completed | 已新增 `PublicSmokeBackendName(const aBackend: TSimdBackend): string`，统一让 backend 标题、default-backend fail 文案和 PASS 文案都复用 `GetBackendInfo(...).Name`；标题输出已去掉冗余 ordinal |
| 3. 独立运行与主检查链复验 | completed | `git diff --check`、临时目录 `fpc` 编译并运行 `fafafa.core.simd.public_smoke.pas`、Release `check` 已通过；说明这批既修正了 standalone smoke 的 user-facing 输出，又没有扰动主 SIMD 检查链 |

## 2026-05-15 Public Smoke Check Coverage Wiring

### Goal

在 `public_smoke` 输出已经 canonical 化之后，继续补上它的真实覆盖缺口：把这个 standalone smoke 真正接进 `tests/fafafa.core.simd` 的日常 `check` 链和 Windows batch 对应路径，并补齐 child output 清理，避免它再次变回“只能手动跑”的孤岛入口。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `public_smoke` 未接入 `check` 的真实原因 | completed | 已确认 `BuildOrTest.sh` / `buildOrTest.bat` 里都没有 `public_smoke` runner；而 shell 的 `check` 真执行路径是底部 `case` 里的内联块，不是前面那个看起来相似的辅助段，首次补丁若只落在辅助块上不会生效 |
| 2. 给 shell/bat `check` 补内部 runner 与 output root 清理 | completed | 已为 shell/bat 都补上 `PUBLIC_SMOKE_SRC`、独立 `public.smoke` child output root、内部 `run_public_smoke`/`:run_public_smoke_internal`，并把 `check` 与 `clean` 路径接上，不扩 CLI action 面 |
| 3. Release `check` 验证新接线 | completed | `git diff --check`、Release `check` 已通过；日志中已真实出现 `[PUBLIC-SMOKE] Building...`、`Running...`、`Backend:    AVX2` 与 `[PASS] Default backend is AVX2`，说明这条 smoke 已纳入日常检查链 |

## 2026-05-15 BackendOps And Boundary Check Coverage Wiring

### Goal

继续沿“独立 program 入口没有进入日常闭环”这条线往下补，把已经单独修好但仍偏 manual-only 的 `test_backend_ops` 和 `test_simd_boundary` 真正接进 `tests/fafafa.core.simd` 的 shell/bat `check` 路径，以及 shell `gate` 的 `build-check` 辅助链，同时补齐 child output 清理。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核两个 standalone program 的当前健康度与覆盖缺口 | completed | fresh 独立 `fpc` 编译运行已确认 `test_backend_ops` 为 `Passed 15 / Failed 0`、`test_simd_boundary` 为 `通过 44 / 失败 0`；但 `BuildOrTest.sh` / `buildOrTest.bat` 里都还没有对应 runner，当前只能手动跑到 |
| 2. 给 shell/bat `check` 与 shell `gate_step_build_check` 补内部 runner | completed | 已为 shell 补 `BACKEND_OPS_SRC` / `SIMD_BOUNDARY_SRC`、独立 `backend.ops` / `simd.boundary` child output root、`run_backend_ops_smoke()` / `run_simd_boundary_smoke()`；batch 也补了对应内部 runner 和 `clean` 清理；shell 的 `gate_step_build_check` 与 `case check)` 都已接上这两条路径 |
| 3. Release `check/gate` 验证新接线 | completed | `git diff --check`、Release `check`、Release `gate` 已通过；日志中已真实出现 `BACKEND-OPS`、`SIMD-BOUNDARY`、`PUBLIC-SMOKE`、`DISPATCH-PREINIT` 四段顺序执行，说明这两个 standalone 程序已经进入 daily check 与 fast-gate 的 build-check 闭环 |

## 2026-05-15 Daily Standalone Runner Guard

### Goal

在 `backend_ops / simd_boundary / public_smoke / dispatch_preinit` 已进入 daily coverage 之后，继续补上防回退的脚本自检：给 `BuildOrTest.sh` 增加一条 source-safe guard，确保 shell/bat 两边都还保留这些 standalone runner 的 source、output root、check 调用和关键源文件 sentinel，避免后续又静默漂移回 manual-only。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核现有 guard 形态并确定最小补点 | completed | 已确认仓库已有 `check_dispatch_preinit_smoke_runner_guard()` 这类 grep/source-safe guard；当前最稳的做法不是重构 runner，而是新增同类 `check_daily_standalone_runner_guard()` 并挂到 shell `check` 与 `gate_step_build_check` |
| 2. 增加 daily standalone runner guard | completed | 已新增 `check_daily_standalone_runner_guard()`，校验 shell/bat 中的 `BACKEND_OPS_SRC`、`SIMD_BOUNDARY_SRC`、对应 output root、runner 定义、`check` 调用点，以及 `test_backend_ops.pas` / `test_simd_boundary.pas` 的关键 sentinel |
| 3. Release `check` 验证 guard | completed | `git diff --check` 与 fresh Release `check` 已通过；日志中已真实出现 `[CHECK] OK (daily standalone runner guard present)`，且同一次 `check` 仍继续跑完 `BACKEND-OPS`、`SIMD-BOUNDARY`、`PUBLIC-SMOKE` 与 `DISPATCH-PREINIT` |

## 2026-05-15 Standalone Guard Coverage Tightening

### Goal

继续沿“Windows batch 真实运行证据仍偏弱”这条线补高价值低风险约束，把 standalone runner 的 guard 从“部分 source/check wiring”收紧到“source/check/clean/output-root”一体化，重点覆盖此前还没被 guard 守住的 `public_smoke` 与新增 child output 清理路径，并把 `dispatch_preinit` 的 batch output-root 合同也补完整。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核现有 guard 漏洞而不是重复跑已绿链路 | completed | 已确认 `check_daily_standalone_runner_guard()` 只守住 `backend_ops/simd_boundary`，没有纳入 `public_smoke`；`check_isolated_clean_coverage()` 也还没覆盖 `public.smoke/backend.ops/simd.boundary` 三个 child output；`check_dispatch_preinit_smoke_runner_guard()` 也没约束 batch 的 output-root/root override |
| 2. 收紧 guard 到 clean/output-root/public-smoke 全覆盖 | completed | 已在 `BuildOrTest.sh` 中把 `public_smoke` 纳入 `check_daily_standalone_runner_guard()`，新增 `public_smoke` 源文件 sentinel，并为 batch guard 补上 `public_smoke/backend_ops/simd_boundary` 的 clean 路径和 root override；同时把 `check_isolated_clean_coverage()` 扩到三条 child output，并为 `dispatch_preinit` batch guard 补上 `DISPATCH_PREINIT_OUTPUT_ROOT` 合同 |
| 3. Release 验证并诚实记录 Windows runtime 证据边界 | completed | `git diff --check`、Release `check`、Release `gate` 已再次通过；fresh 日志里已真实出现 `[CHECK] OK (isolated clean coverage present)`、`[CHECK] OK (dispatch preinit smoke guard present)`、`[CHECK] OK (daily standalone runner guard present)`，且 `BACKEND-OPS / SIMD-BOUNDARY / PUBLIC-SMOKE / DISPATCH-PREINIT` 全链继续通过；另外尝试用 `wine` + 临时 wrapper 探测 batch runtime proof 时，`where fpc` 可见 wrapper，但 `fpc -iTP` 未形成可靠完成证据，因此当前仍不能把它当成可发布的 Windows runtime proof |

## 2026-05-15 Windows Evidence Contract Tightening

### Goal

继续沿“Windows batch 真实运行证明仍偏弱”这条主线往前推，但不再强行追整条 gate 真机编译，而是收紧证据层本身：修复 `verify_windows_b07_evidence.{sh,bat}` 会把旧 `windows_b07_gate.log` 误判为 `OK` 的问题，让 verifier、evidence collector、simulated helper、freeze rehearsal 与当前 `1/6 + optional public ABI smoke + standalone runners` 合同重新对齐，并尽量给 batch verifier 这一层补到真实运行证据。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 Windows evidence 真正的覆盖缺口 | completed | 已确认当前仓库里的 `tests/fafafa.core.simd/logs/windows_b07_gate.log` 仍是 2026-04-18 的旧 shape，既没有 `BACKEND-OPS / SIMD-BOUNDARY / PUBLIC-SMOKE / DISPATCH-PREINIT`，也还是 `1/7` 步骤文案；但旧 `verify_windows_b07_evidence.sh` 仍会把它判成 `OK`，说明 verifier 对最近接入的 standalone coverage 完全失明 |
| 2. 收紧 verifier/collector/simulated/rehearsal 到当前合同 | completed | 已更新 `verify_windows_b07_evidence.{sh,bat}`，要求 current gate step shape 与四个 standalone runner 的关键日志标记；同时把 `collect_windows_b07_evidence.bat` 改为在 `1/6` 直接调用 `buildOrTest.bat check`，让 standalone runner 痕迹真实进入 Windows evidence；`simulate_windows_b07_evidence.sh` 与 `rehearse_freeze_status.sh` 里的 PASS 夹具也已同步到新合同；`BuildOrTest.sh` 中守这些文件的 source-safe guard 也全部跟着更新 |
| 3. 多层验证并记录新的 evidence truth | completed | `git diff --check`、`bash tests/fafafa.core.simd/verify_windows_b07_evidence.sh tests/fafafa.core.simd/logs/windows_b07_gate.log`、`wine cmd /c ...verify_windows_b07_evidence.bat ...windows_b07_gate.log`、合成 PASS log 下 shell/batch verifier 双通过、`bash tests/fafafa.core.simd/rehearse_freeze_status.sh`、Release `gate` 已全部按预期完成；最终行为已变成：旧 Windows log 会被 verifier 判 FAIL，而 Linux `gate` 在 `SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=0` 下会诚实降级为 optional evidence `SKIP` 后继续 `OK` |

## 2026-05-15 Gate Label Harmonization

### Goal

再做一次极小的 contract 对齐，消掉 shell `gate` 里残留的 `3/6 SIMD AVX2 fallback suite` 叫法，让它和 batch/evidence/rehearsal 统一成 `3/6 SIMD AVX2 stable vector suites`，避免同一条门禁在不同入口上出现两种口径。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核是否只剩一条 shell 文案漂移 | completed | `rg` 已确认 `tests/fafafa.core.simd/BuildOrTest.sh` 里只有 `echo "[GATE] 3/6 SIMD AVX2 fallback suite"` 还在用旧词，而 batch/evidence/rehearsal 已统一为 `stable vector suites` |
| 2. 对齐 shell gate label | completed | 已把 shell `gate` 的 `3/6` label 改成 `SIMD AVX2 stable vector suites`，其余 step id / gate 行为保持不变 |
| 3. 真实 gate 验证 | completed | `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate` 已再次通过，日志中真实出现新的 `3/6 SIMD AVX2 stable vector suites`，同时旧 `windows_b07_gate.log` 仍会被 evidence verifier 判 FAIL，说明这次只是统一命名，不是放松合同 |

## 2026-05-15 Windows Evidence GH Preflight Blocked

### Goal

确认 GH Windows evidence 的外部前提是否满足，判断能否继续把 fresh Windows runtime proof 往前推。如果环境被 billing/runner 阻塞，就明确记录阻塞，不继续把时间耗在本地无效重试上。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 预检 GH/Workflow 前提 | completed | `gh auth status` 可用，仓库 workflow 也能解析到 `simd-windows-b07-evidence.yml`；说明本机工具链没问题 |
| 2. 运行 GH 预检脚本 | completed | `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight` 返回 `RECENT_BILLING_BLOCK`，说明最近一次相关 workflow run 被 GitHub 直接拒绝启动，原因是 recent account payments failed / spending limit needs to be increased |
| 3. 处理结果 | completed | 这不是本地代码可修问题；当前应视为外部阻塞而不是实现缺陷。fresh Windows runtime evidence 的下一步必须先恢复 GitHub Billing/额度，再重新发起 GH 路径 |

## 2026-05-15 RISCVV I64x2 MinMax Helper Exact-Contract Consolidation

### Goal

继续沿 `simd` 深审里“只收 exact-contract redundancy，不碰语义敏感 float / backend-owned 路径”的纪律往下推，在 `riscvv.helpers.inc` 里拿下当前最小且安全的整数 helper 尾巴。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 helper 边界而不是盲目继续去重 | completed | 已重新核对 `dispatchapi` 与 scratch 记录：`Round/Trunc/Clamp` 仍牵涉 signed-zero / NaN ordering，`NormalizeF32x4/F32x3` 仍有阈值差异，`DotF64x2/F64x4` 仍被测试要求保持 backend-owned；因此这批只收整数 `MinI64x2/MaxI64x2` |
| 2. 收回 `RISCVVMin/MaxI64x2` 的第二份手写逻辑 | completed | 已把 `src/fafafa.core.simd.riscvv.helpers.inc` 中的两个逐 lane `if/else` helper 改为直接调用 `ScalarMinI64x2/ScalarMaxI64x2`，并在 `check_nonx86_helper_semantics.py` 里补上对应 source-side 断言 |
| 3. 串行 release 验证并准备收口 | completed | `git diff --check`、`python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`、串行 Release `check`、串行 Release `gate` 已全部通过；helper summary 已更新到 `checks=477 status=ok` |

## 2026-05-15 RISCVV AndNot Helper Exact-Contract Consolidation

### Goal

在 `Min/MaxI64x2` 收口后继续审 `riscvv.helpers.inc`，只挑“已有 scalar 真源、helper 仍在维护第二份 bitwise 逻辑”的小块继续去重，不把审查扩散到 `select/reduce/float unary` 这类合同面更宽的区域。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核剩余 helper 里是否还有同级别 exact-contract 尾巴 | completed | 已确认下一刀不是 `Neg/Load/Store/Splat/Zero/Select/Reduce`，因为这些多数没有现成同名 scalar helper，或会把这轮工作扩到更宽合同面；当前还能安全收的只剩 `RISCVVAndNotI8x16/U16x8/U8x16` |
| 2. 收回 3 个 `AndNot` helper 的组合式本地实现 | completed | 已把 `RISCVVAndNotI8x16/U16x8/U8x16` 从 `RISCVVNot + RISCVVAnd` 组合逻辑改成直接调用 `ScalarAndNot*`，并在 `check_nonx86_helper_semantics.py` 的 helper 期望表里新增对应 3 条 source-side 断言 |
| 3. 串行 release 验证并准备第二次收口 | completed | `git diff --check`、helper semantics、`impl-audit-nonx86`、串行 Release `check`、串行 Release `gate` 已全部通过；helper summary 已更新到 `checks=480 status=ok`，`key-slot` 与 `RISCVV ABI shape` 继续为绿 |

## 2026-05-15 RISCVV I64x4 Arithmetic-Shift Helper Exact-Contract Consolidation

### Goal

把 `riscvv.helpers.inc` 里最后一个仍保留“已有 scalar 真源、但 helper 还手写着同合同逻辑”的 `ShiftRightArithI64x4` 收回统一真源，然后在同一边界上停手，不再扩大到没有现成 scalar helper 的 `U64x2 shift`、`reduce` 或 `select` 区域。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核第三刀是否仍属同风险 exact-contract | completed | 已确认 `ScalarShiftRightArithI64x4` 现成存在，且其负 count / `count>=64` 归零与 `SarInt64` 逻辑与 helper 本地实现完全一致；反过来 `U64x2 shift`、`reduce`、`select` 仍没有同级别可直接回收的 scalar 真源 |
| 2. 收回 `RISCVVShiftRightArithI64x4` 的本地 loop | completed | 已把 helper 中手写的 count 边界和逐 lane `SarInt64` loop 改成 `Result := ScalarShiftRightArithI64x4(a, shift);`，并在 helper semantics checker 中新增对应 source-side 断言 |
| 3. 串行 release 验证并准备第三次收口 | completed | `git diff --check`、helper semantics、`impl-audit-nonx86`、串行 Release `check`、串行 Release `gate` 已全部通过；helper summary 已更新到 `checks=481 status=ok`，说明这类 helper 级 exact-contract 尾巴已基本清到头 |

## 2026-05-15 RISCVV CmpNeU32x4 Internal Contract Drift Fix

### Goal

继续深审 `RISCVV` 剩余 helper 时，优先修复真实的内部合同漂移，而不是继续机械去重：把 `CmpNeU32x4` 从“asm 路径返回 `TMask4`、fallback helper 却返回 `TVecU32x4`”的分裂状态收回一致，同时保持它仍然是 dispatch 外的内部 helper，不擅自扩公开 surface。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核真实合同与消费面 | completed | 已确认 `dispatch` 和 `register` 都没有 `CmpNeU32x4` 槽位，`facade` 也没有公开同名函数；`sse2.register.inc` 还明确注明 `CmpNeU32x4 not in dispatch table`，说明这条线应视为内部 helper，而不是缺失的公开 API |
| 2. 修复 no-ASM helper 的返回合同漂移 | completed | 已把 `src/fafafa.core.simd.riscvv.helpers.inc` 里的 `RISCVVCmpNeU32x4` 从错误的 `TVecU32x4` 返回改回 `TMask4`，并把实现改成按 lane 置位的 mask 语义，与 asm 版本保持一致 |
| 3. 给 helper checker 补内部签名/语义护栏并复验 | completed | `check_nonx86_helper_semantics.py` 已新增对 `RISCVVCmpNeU32x4` 的签名和 mask-body 断言；`git diff --check`、helper semantics、`impl-audit-nonx86`、串行 Release `check`、串行 Release `gate` 已全部通过，helper summary 更新到 `checks=482 status=ok` |

## 2026-05-15 RISCVV Dead Load/Store/Splat/Zero Residue Removal

### Goal

继续深审 `RISCVV` internal helper/asm 尾巴时，优先清掉确认“只有定义、没有任何消费面”的死残留，而不是把它们错误提升成 façade 或 dispatch contract。本批目标是移除 `I32x4/I64x2` 的 `Load/Store/Splat/Zero` 双轨定义，并把“必须缺席”写进 source-side checker。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 8 个候选符号是否只剩定义 | completed | 全仓检索确认 `RISCVVLoad/Store/Splat/ZeroI32x4` 与 `RISCVVLoad/Store/Splat/ZeroI64x2` 只出现在 `src/fafafa.core.simd.riscvv.pas` 和 `src/fafafa.core.simd.riscvv.helpers.inc`，没有 `dispatch/register/facade/tests/docs` 消费面 |
| 2. 删除 asm + helper 双轨死残留 | completed | 已从 `riscvv.pas` 删除这 8 个 asm 入口，并从 `riscvv.helpers.inc` 删除对应 fallback 定义，避免继续保留无入口的双轨内部死代码 |
| 3. 补“必须缺席”护栏并串行复验 | completed | `check_nonx86_helper_semantics.py` 已新增 `require_routine_absent(...)`，显式要求这 8 个符号在 `riscvv.pas/helpers.inc` 中缺席；`git diff --check`、helper semantics、`impl-audit-nonx86`、串行 Release `check`、串行 Release `gate` 已全部通过，helper summary 更新到 `checks=498 status=ok` |

## 2026-05-15 RISCVV Dead Shift/Reduce/Select Residue Removal

### Goal

继续深审 `RISCVV` internal residue 时，把第二组“只有定义、没有 slot/facade/test 消费”的死尾巴也收掉：`U64x2 shift`、`I32x4/U32x4 reduce`、以及 `I64x2/I32x8/I32x16 select`。这批目标不是抽象去重，而是删除错误保留下来的第二组 asm + helper 双轨死代码，并把缺席护栏继续扩严。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核第二组候选符号是否存在任何真实接线 | completed | 已确认 `RISCVVShiftLeft/RightU64x2`、`RISCVVReduce(Add/Min/Max)I32x4`、`RISCVVReduce(Min/Max)U32x4`、`RISCVVSelectI64x2/I32x8/I32x16` 在 `register/facade/dispatch/simd.pas/tests` 都没有消费面，只剩 `riscvv.pas/helpers.inc` 双轨定义 |
| 2. 删除第二组 asm + helper 双轨死残留 | completed | 已从 `src/fafafa.core.simd.riscvv.pas` 与 `src/fafafa.core.simd.riscvv.helpers.inc` 删除这 10 组内部死入口；`riscvv_abi_shape` 计数自然从 `123` 收到 `121`，没有出现 shape 合同问题 |
| 3. 扩 absent 护栏并串行 release 复验 | completed | `check_nonx86_helper_semantics.py` 已把这 10 组名字加入 `require_routine_absent(...)`；`git diff --check`、helper semantics、`impl-audit-nonx86`、串行 Release `check`、串行 Release `gate` 已全部通过，helper summary 更新到 `checks=518 status=ok` |

## 2026-05-15 RISCVV Dead Neg Residue Removal

### Goal

继续深审 `RISCVV` 时，把最后两条没有真实接线的非 `Asm` internal residue 也收掉：`RISCVVNegF32x4` 与 `RISCVVNegF64x2`。目标不是重写语义，而是确认它们既不在 `register/facade/dispatch/tests` 的 contract 面里，也不该作为独立 helper 残留继续存在。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `RISCVVNegF32x4/F64x2` 的真实消费面 | completed | 全仓检索确认这 2 个名字只出现在 `src/fafafa.core.simd.riscvv.pas` 与 `src/fafafa.core.simd.riscvv.helpers.inc`；`register/facade/dispatch/simd.pas/tests` 都没有公开或测试消费面 |
| 2. 删除 asm + helper 双轨死残留 | completed | 已从 `riscvv.pas` 删除 `NegF32x4/NegF64x2` 的 asm + wrapper 定义，并从 `riscvv.helpers.inc` 删除对应 fallback 定义；删后 fresh 扫描显示 `RISCVV` 非 `Asm` internal residue 数已降到 `0` |
| 3. 扩 absent 护栏并串行 release 复验 | completed | `check_nonx86_helper_semantics.py` 已把这 2 个名字加入 `require_routine_absent(...)`；`git diff --check`、helper semantics、`impl-audit-nonx86`、串行 Release `check`、串行 Release `gate` 已全部通过，helper summary 更新到 `checks=522 status=ok` |

## 2026-05-15 NEON Dead Compare/Reduction/MinMax Residue Removal

### Goal

在 `RISCVV` 非 `Asm` internal residue 清到 `0` 之后，继续把同类“只有定义、没有 register/facade/runtime/tests 消费”的 `NEON` 零调用残留也收掉。本批只删除确认无接线的 `CmpNeU32x4`、`I32x4/U32x4 reduction`、以及 `Min/MaxI64x2`，不把它们错误升级成新 contract。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `NEON` 零调用候选是否真的没有消费面 | completed | 已确认 `NEONCmpNeU32x4`、`NEONReduce(Add/Min/Max)I32x4`、`NEONReduce(Add/Min/Max)U32x4`、`NEONMinI64x2`、`NEONMaxI64x2` 只剩 `compare.inc/scalar.reduction.inc/scalar.utility.inc` 定义，没有 `register/facade/runtime/simd.pas/tests` 消费面 |
| 2. 删除 `NEON` compare/reduction/minmax 死残留 | completed | 已从 `src/fafafa.core.simd.neon.compare.inc` 删除 `CmpNeU32x4` 与 `I32x4/U32x4 reduction` 入口，从 `neon.scalar.reduction.inc` 删除对应 fallback，并从 `neon.scalar.utility.inc` 删除 `Min/MaxI64x2` fallback |
| 3. 扩 absent 护栏并串行 release 复验 | completed | `check_nonx86_helper_semantics.py` 已新增 `NEON_COMPARE_FILE` 并把上述名字加入 `require_routine_absent(...)`；`git diff --check`、helper semantics、`impl-audit-nonx86`、串行 Release `check`、串行 Release `gate` 已全部通过，helper summary 更新到 `checks=537 status=ok`；`gate` 末尾仍只把旧 `windows_b07_gate.log` 诚实降级为 optional `SKIP` |

## 2026-05-15 NEON Single-Use Compare Wrapper Inline Cleanup

### Goal

继续细化 `NEON` 上一批删后只剩的 7 个内部 helper，把真正高复用的 `CombineMask*` 支撑函数与只服务单个聚合调用点的 compare thin wrapper 分开处理。本批目标是删掉 4 个单点冗余 wrapper，并保留 3 个仍有广泛 fan-out 的 mask combine helper。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核剩余 7 个 `NEON` helper 的真实角色 | completed | 已确认 `NEONCombineMask2To4/4To8/8To16` 在 `scalar.autowrap.inc` 内被大量宽比较聚合调用；而 `NEONCmpLeU64x2Wrapper`、`NEONCmpGeU64x2Wrapper`、`NEONCmpNeU64x2Wrapper`、`NEONCmpNeU32x4Wrapper` 都只是单行反相薄壳，且各自只服务单个聚合调用点 |
| 2. 内联 4 个 compare wrapper 并删除定义 | completed | 已从 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 删除 4 个 wrapper 定义，并把 `NEONCmpGeU64x4`、`NEONCmpLeU64x4`、`NEONCmpNeU32x8`、`NEONCmpNeU64x4` 直接改为在 `NEONCombineMask*` 调用点内联 `MASK*_ALL_SET xor ...` 表达式；`CombineMask*` 保持不动 |
| 3. 扩 absent 护栏并串行 release 复验 | completed | `check_nonx86_helper_semantics.py` 已把这 4 个 wrapper 加入 `require_routine_absent(...)`；`git diff --check`、helper semantics、`impl-audit-nonx86`、串行 Release `check`、串行 Release `gate` 已全部通过，helper summary 更新到 `checks=541 status=ok`；`gate` 末尾仍只把旧 `windows_b07_gate.log` 诚实降级为 optional `SKIP` |

## 2026-05-15 NEON Wide Float Memory Utility Asm Binding Repair

### Goal

继续深审 `NEON` 时，修复一个真实接线缺口：wide-float memory/utility 的 `_ASM` helper 早已存在，但 `neon.register.inc` 在 asm 编译路径下没有把这些 slot 直接绑定过去，导致 arm64 native helper 可能被 scalar companion 阴影掉。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 helper / register / runtime truth | completed | 已确认 `src/fafafa.core.simd.neon.scalar.wide_memory.inc` 中已存在 `Load/Store/Splat/Zero F32x8/F32x16/F64x4/F64x8` 的 `_ASM` helper，而 `src/fafafa.core.simd.neon.register.inc` 在 `FAFAFA_SIMD_NEON_ASM_ENABLED` 分支此前没有对这 16 个 slot 做 direct asm binding |
| 2. 修复 asm register 接线缺口 | completed | 已在 `src/fafafa.core.simd.neon.register.inc` 的 asm 分支新增 16 条 `table.* := @..._ASM` 绑定，让 wide-float memory/utility slot 与 `I64x4` 同类路径一致，asm build 下真正走 native helper |
| 3. 增加 source-shape/runtime 护栏并串行 release 复验 | completed | `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 已新增 `Test_NEON_WideFloatMemoryUtilitySlots_Bind_AsmHelpers_When_Available`；fresh `git diff --check`、`python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`、串行 Release `check`、串行 Release `gate` 全部通过，helper summary 更新到 `checks=541 status=ok`；`gate` 尾部仍只把旧 `windows_b07_gate.log` 诚实降级为 optional `SKIP` |

## 2026-05-15 NEON Wide Float Asm Shadowing Fix

### Goal

继续深审上一批 wide-float asm 接线后，修复一个更真实的 shadowing 问题：前半段虽然新增了 `_ASM` binding，但后半段又无条件把同一批 slot 重新绑回 `NEON...` scalar-forwarder wrapper，导致 asm 路径仍可能被覆盖；同时把因此变成 dead code 的 16 个 wrapper 一并删掉。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 shadowing 和 dead-wrapper 真相 | completed | 已确认 `src/fafafa.core.simd.neon.register.inc` 在 321-336 先绑 `@..._ASM`，但 465-548 又把 `Load/Store/Splat/Zero F32x8/F32x16/F64x4/F64x8` 无条件重绑到 `@NEON...`；同时这 16 个 `NEON...` wrapper 只剩 `scalar.autowrap.inc + register.inc` 两处，没有其他消费面 |
| 2. 去掉后段覆盖并删除 16 个 dead wrapper | completed | 已从 `neon.register.inc` 删除这 16 条后段 wrapper rebinding，让 asm 路径不再被覆盖、no-asm 直接继承 `FillBaseDispatchTable` 的 base scalar slot；并从 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 删除对应 16 个 dead scalar-forwarder wrapper |
| 3. 补严 source-side 护栏并串行 release 复验 | completed | `dispatchapi` 现已同时断言 `_ASM` binding 存在、后段 wrapper rebinding 缺席、autowrap dead wrapper 缺席；`check_nonx86_helper_semantics.py` 也新增这 16 个 absent guard；fresh `git diff --check`、`python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`、串行 Release `check`、串行 Release `gate` 全部通过，helper summary 更新到 `checks=557 status=ok`；最新 `freeze-status` 仍只红在 Windows evidence freshness / qemu cpuinfo evidence optional skip，`win-evidence-preflight` 继续被 `RECENT_BILLING_BLOCK` 外部阻塞 |

## 2026-05-15 Register Truthfulness Shadowing Guard Upgrade

### Goal

把上一批 `NEON` shadowing 问题提升成通用审计护栏：让 `check_nonx86_register_truthfulness.py` 不再只逐条分类赋值，而是能识别“同一 slot 在会同时生效的上下文里被不同 target 重绑”的 overlapping rebinding，并用 fixture 固化这类回归。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 checker 漏检根因 | completed | 已确认 `check_nonx86_register_truthfulness.py` 之前只按单条 assignment 做 `asm_exact / wrapper_only / ...` 分类，不会判断同一 slot 是否被后续不同 target 覆盖；因此前一版 `NEON` shadowing 才能以 `miswired=0` 漏过 |
| 2. 升级 truthfulness checker 并补 shadowed fixture | completed | 已为脚本新增 overlapping-context rebinding 检测、`conflicting assign` 输出，并新增 `tests/fafafa.core.simd/fixtures/nonx86_register_truthfulness/shadowed/`，能稳定复现“asm-only 先绑、always 后盖”的冲突模式 |
| 3. 用 fixture + 真实仓库串行复验 | completed | `--fixture good` 继续 PASS，`--fixture bad` 继续 FAIL，`--fixture shadowed` 现在正确 FAIL；真实 `--backend neon/riscvv --strict` 仍为 `miswired=0 conflicting_assign=0`；fresh `impl-audit-nonx86`、串行 Release `check`、串行 Release `gate` 全部通过，`gate` 尾部仍只把 non-x86 native evidence root 缺失和旧 `windows_b07_gate.log` 诚实降级为 optional `SKIP` |

## 2026-05-15 NEON No-Asm Float Compare Scalar-Forwarder Cleanup

### Goal

继续收敛 `NEON` 的 `wrapper_only` 余量：把 no-asm 分支里 24 个只会直接转发到 `ScalarCmp*` 的 float compare wrapper 从 `register` / `autowrap` 中移除，让这些 slot 直接继承 `FillBaseDispatchTable` 的 base scalar truth，而不是继续伪装成 backend-owned。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 24 个 compare wrapper 的真实消费面 | completed | 已确认 `CmpEq/Ge/Gt/Le/Lt/Ne × {F32x16,F32x8,F64x4,F64x8}` 在 `src/fafafa.core.simd.neon.register.inc` 里只出现在 no-asm 注册分支；对应 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 函数体全部是单行 `Result := ScalarCmp...`；多数名字全仓只剩 `register + autowrap` 两处，没有其他真实消费面 |
| 2. 回落到 base scalar 并删除 dead wrapper | completed | 已从 `neon.register.inc` 删除这 24 条 no-asm compare assignment，保留 `F64x2` 的本地 loop compare 作为 backend-owned 例外；已从 `neon.scalar.autowrap.inc` 删除对应 24 个 dead scalar-forwarder wrapper |
| 3. 补三层护栏并串行 release 复验 | completed | `dispatchapi` 已新增 `Test_NEON_NoAsmFloatCompareSlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders`；`check_nonx86_helper_semantics.py` 已新增 24 个 absent guard；`check_nonx86_register_truthfulness.py` 已收紧 `ALLOWED_WRAPPER_SLOTS_BY_BACKEND['neon']`；fresh `git diff --check`、helper semantics、truthfulness、`impl-audit-nonx86`、串行 Release `check`、串行 Release `gate` 全部通过；`NEON` truthfulness 现为 `assignments=387 wrapper_only=153 miswired=0 conflicting_assign=0`，`gate` 尾部仍只剩 optional non-x86 native evidence skip 与历史 Windows evidence skip |

## 2026-05-15 NEON Wide Rcp/Reduction Scalar-Forwarder Cleanup

### Goal

继续收敛 `NEON` 的 `wrapper_only` 余量：把 `RcpF64x4` 与 `ReduceAdd/Max/Min/Mul × {F32x16,F32x8,F64x4,F64x8}` 这 17 个只会转发到 `Scalar*` 的 wide wrapper 从 `register` / `autowrap` 中移除，让这些 slot 直接继承 `FillBaseDispatchTable` 的 base scalar truth，并同步收正一处把 `NEON` wide reduction slot 误当成 backend-owned 的 asm-path 测试口径。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 wide `Rcp/Reduce` wrapper 的真实合同与消费面 | completed | 已确认 `NEONRcpF64x4` 与 `ReduceAdd/Max/Min/Mul × {F32x16,F32x8,F64x4,F64x8}` 在 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 里全部只是 `Scalar*` 单行转发；`F64x2` reductions 仍保留 backend-local 实现，因此不在这批 |
| 2. 回落到 base scalar 并删除 17 个 dead wrapper | completed | 已从 `neon.register.inc` 删除 `RcpF64x4` 与 16 个 wide reduction assignment；已从 `neon.scalar.autowrap.inc` 删除对应 17 个 dead scalar-forwarder wrapper，保留 `F64x2` reductions |
| 3. 收正测试口径并串行 release 复验 | completed | `dispatchapi` 已新增 `Test_NEON_WideRcpAndReductionSlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders`；`Test_NativeF64ReduceAddSeedParity_WithVectorAsm_IfAvailable` 已改成对 `NEON` 断言 scalar-slot reuse、对 `RISCVV` 仍要求 native slot；`check_nonx86_helper_semantics.py` 已新增 17 个 absent guard；`check_nonx86_register_truthfulness.py` 已收紧 `ALLOWED_WRAPPER_SLOTS_BY_BACKEND['neon']`；fresh helper semantics、truthfulness、`impl-audit-nonx86`、`TTestCase_NonX86BackendParity`、串行 Release `check`、串行 Release `gate` 全部通过；`NEON` truthfulness 现为 `assignments=370 wrapper_only=136 miswired=0 conflicting_assign=0`，`gate` 尾部仍只剩 optional non-x86 native evidence skip 与历史 Windows evidence skip |

## 2026-05-15 NEON No-Asm Abs/Wide FloorCeil Scalar-Forwarder Cleanup

### Goal

继续沿 `NEON wrapper_only` 余量往下收，只清理 no-asm 分支里“源码上就是 exact `Scalar*` forwarder”的 `Abs` / wide `Floor/Ceil` slot，让这些发布位重新诚实继承 base scalar truth；保留 `CeilF64x2` / `FloorF64x2` 这两个仍带 backend-local loop 的例外，不误碰 `Round/Trunc` 这类语义更宽的家族。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `Abs/Floor/Ceil` 候选是否真的是 dead scalar-forwarder | completed | 已确认 `Abs × {F32x16,F32x8,F64x2,F64x4,F64x8}`、`Ceil × {F32x16,F32x8,F64x4,F64x8}`、`Floor × {F32x16,F32x8,F64x4,F64x8}` 在 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 里都只是单行 `Scalar*` 转发；只有 `CeilF64x2` / `FloorF64x2` 仍是 backend-local loop，因此显式保留 |
| 2. 回落到 base scalar 并删除 13 个 dead wrapper/assignment | completed | 已从 `src/fafafa.core.simd.neon.register.inc` 删除上述 13 个 no-asm assignment，并从 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 删除对应 13 个 dead wrapper；`CeilF64x2` / `FloorF64x2` 继续保留 backend-owned 路径 |
| 3. 收正 truth/test 口径并串行 release 复验 | completed | `dispatchapi` 已新增 `Test_NEON_NoAsmAbsAndWideFloorCeilSlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders`，并把 `wide Floor/Ceil` 与 `Abs` 的旧“native-slot”断言收正为“NEON 复用 scalar、RISCVV 仍要求 native”；`check_nonx86_helper_semantics.py` 已把这 13 个名字改成 absent guard，`check_nonx86_register_truthfulness.py` 已收紧 `ALLOWED_WRAPPER_SLOTS_BY_BACKEND['neon']`；fresh `git diff --check`、`py_compile`、helper semantics、`truthfulness --backend neon/riscvv --strict`、`impl-audit-nonx86`、`TTestCase_NonX86BackendParity`、串行 Release `check`、串行 Release `gate` 全部通过；`NEON` truthfulness 现为 `assignments=357 wrapper_only=123 miswired=0 conflicting_assign=0` |

## 2026-05-15 NEON No-Asm FMA Scalar-Forwarder Cleanup

### Goal

继续沿 `NEON wrapper_only` 收口，但这次针对 `FMA` 家族采用更精确的治理：asm build 继续保留 `neon.pas` 里的真实 backend-local `Fma` 实现，no-asm build 则不再把 exact `ScalarFma*` forwarder 伪装成 backend-owned slot，而是回落到 base scalar truth。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `Fma` 候选的 asm/no-asm 双轨真相 | completed | 已确认 `NEONFmaF32x4` 在 `scalar.ext_math.inc`、`NEONFmaF32x16/F32x8/F64x2/F64x4/F64x8` 在 `scalar.autowrap.inc` 的 no-asm 版本都只是 exact `ScalarFma*` forwarder；但同名函数在 `src/fafafa.core.simd.neon.pas` 里仍有真实 asm 实现，因此不能像前两批那样简单整段删掉 register binding |
| 2. 改成 asm-only binding 并删除 6 个 no-asm dead wrapper | completed | 已把 `register.inc` 中 `FmaF32x4/F32x16/F32x8/F64x2/F64x4/F64x8` 改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定，让 no-asm 直接继承 `FillBaseDispatchTable`；并从 `scalar.ext_math.inc` / `scalar.autowrap.inc` 删除 6 个 no-asm dead scalar-forwarder wrapper |
| 3. 补 no-asm runtime/source 护栏并串行 release 复验 | completed | `dispatchapi` 已新增 `Test_NEON_NoAsmFMASlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders`，断言 no-asm 下 dead wrapper 缺席、asm binding source 仍在、运行时 slot 复用 scalar；`check_nonx86_helper_semantics.py` 已把 6 个名字改成 absent guard，`check_nonx86_register_truthfulness.py` 已移除 wide `Fma` wrapper allowlist；fresh `git diff --check`、`py_compile`、helper semantics、`truthfulness --backend neon/riscvv --strict`、`impl-audit-nonx86`、串行 Release `check`、串行 Release `gate` 全部通过；`NEON` truthfulness 现为 `assignments=357 asm_exact=229 wrapper_only=118 miswired=0 conflicting_assign=0` |

## 2026-05-15 NEON No-Asm Narrow Reciprocal Scalar-Forwarder Cleanup

### Goal

继续沿同一治理模式下切最小安全簇：把 `NEONRcpF32x4 / NEONRsqrtF32x4` 从 no-asm 的伪 backend-owned slot 收回到 base scalar truth，同时保留 asm build 里的真实 `neon.pas` reciprocal owner，不扩大到还存在 live source companion 的 `Add/Sub/Mul/Div/Abs/Sqrt`。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `Rcp/RsqrtF32x4` 的 asm/no-asm 真相与消费面 | completed | 已确认 `scalar.ext_math.inc` 里的 `NEONRcpF32x4/NEONRsqrtF32x4` no-asm 版本只是 exact `ScalarRcp/RsqrtF32x4` forwarder；同名函数在 `src/fafafa.core.simd.neon.pas` 里仍有真实 asm 实现，且全仓无其他 live 消费面，因此这批可以像 `Fma` 一样做成 `asm-only binding + 删 dead wrapper` |
| 2. 改成 asm-only binding 并删除 2 个 no-asm dead wrapper | completed | 已把 `register.inc` 中 `RcpF32x4/RsqrtF32x4` 改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定，并从 `scalar.ext_math.inc` 删除 2 个 no-asm dead scalar-forwarder wrapper |
| 3. 补 no-asm runtime/source 护栏并串行 release 复验 | completed | `dispatchapi` 已新增 `Test_NEON_NoAsmNarrowReciprocalSlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders`，断言 no-asm 下 dead wrapper 缺席、asm binding source 仍在、运行时 `Rcp/RsqrtF32x4` slot 复用 scalar；`check_nonx86_helper_semantics.py` 已把这 2 个名字改成 absent guard；fresh `git diff --check`、`py_compile`、helper semantics、`truthfulness --backend neon/riscvv --strict`、`impl-audit-nonx86`、串行 Release `check`、串行 Release `gate` 全部通过 |

## 2026-05-15 NEON No-Asm F32x8 Arithmetic Dead-Wrapper Cleanup

### Goal

继续沿 `NEON` no-asm slot ownership 深挖，但只收下一簇真正“无 live source consumer”的 float arithmetic dead wrapper：`Add/Sub/Mul/DivF32x8`。这 4 个名字在 no-asm 下只是 exact `Scalar*` forwarder，且全仓没有更宽 no-asm 组合路径继续调用它们，因此可以像 `Fma/Rcp` 一样收回到 base scalar truth。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `F32x8 Add/Sub/Mul/Div` 的 asm/no-asm 真相与消费面 | completed | 已确认 `src/fafafa.core.simd.neon.scalar_fallback.inc` 里的 `NEONAdd/Sub/Mul/DivF32x8` 都只是 exact `Scalar*F32x8` forwarder；`src/fafafa.core.simd.neon.pas` 里仍有真实 asm owner；全仓源码检索确认 no-asm 下没有其他 live source consumer |
| 2. 改成 asm-only binding 并删除 4 个 no-asm dead wrapper | completed | 已把 `src/fafafa.core.simd.neon.register.inc` 中 `Add/Sub/Mul/DivF32x8` 改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定，并从 `src/fafafa.core.simd.neon.scalar_fallback.inc` 删除 4 个 no-asm dead wrapper |
| 3. 收正通用 capability 断言并串行 release 复验 | completed | `dispatchapi` 已新增 `Test_NEON_NoAsmWideF32x8ArithmeticSlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders`，同时把两处通用 `Add/Sub/Mul/DivF32x8` 断言从“总是 native”收正为“NEON 复用 scalar、其余 backend 仍要求 native”；`check_nonx86_helper_semantics.py` 已把这 4 个名字改成 absent guard；fresh `git diff --check`、`py_compile`、helper semantics、`DispatchAPI`、`truthfulness --backend neon/riscvv --strict`、`impl-audit-nonx86`、串行 Release `check`、串行 Release `gate` 全部通过 |

## 2026-05-15 NEON No-Asm Wide Leaf Float Arithmetic Slot-Ownership Cleanup

### Goal

继续沿同一 truth 线往上层 wide leaf arithmetic 收，但这次不删除 wrapper，只修 no-asm runtime slot ownership：`Add/Sub/Mul/DivF32x16` 与 `Add/Sub/Mul/DivF64x8`。这些 wrapper 仍是 asm build 的组合 owner，因此 source companion 要保留；但 no-asm build 不应继续把它们发布成伪 `NEON` native slot。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `F32x16/F64x8 Add/Sub/Mul/Div` 的 source role | completed | 已确认这 8 个 wrapper 位于 `scalar.autowrap.inc`，在 asm build 也承担宽向量组合 owner，因此不能像 `F32x8` 那样直接删除；但它们的 no-asm 路径只是在更小宽度 helper 上做组合，不该继续占据发布后的 `NEON` slot |
| 2. 改成 asm-only binding，保留 source companion | completed | 已把 `register.inc` 中 `Add/Sub/Mul/DivF32x16` 与 `Add/Sub/Mul/DivF64x8` 改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定；`scalar.autowrap.inc` 中 wrapper 全部保留，继续供 asm build 的宽向量组合 owner 使用 |
| 3. 补 source/runtime 护栏并串行 release 复验 | completed | `dispatchapi` 已新增 `Test_NEON_NoAsmWideLeafFloatArithmeticSlots_Keep_SourceCompanions_But_Reuse_BaseScalar`，断言 source companion 仍在、asm binding source 仍在、no-asm runtime slot 复用 scalar；两处通用 `Add/Sub/Mul/DivF32x16/F64x8` capability 断言也已从“总是 native”收正为“NEON 复用 scalar、其余 backend 仍要求 native”；fresh `git diff --check`、`DispatchAPI`、`truthfulness --backend neon/riscvv --strict`、`impl-audit-nonx86`、串行 Release `check`、串行 Release `gate` 全部通过 |

## 2026-05-15 NEON No-Asm Wide Sqrt Slot-Ownership Cleanup

### Goal

继续沿同一 slot-ownership truth 线收正 `NEON` no-asm 的 wide `Sqrt`：`SqrtF32x8`、`SqrtF32x16`、`SqrtF64x4`、`SqrtF64x8`。其中 dead wrapper 要删除，仍被更宽 no-asm graph 消费的 source companion 要保留；但这 4 个 runtime slot 在 no-asm 下都不应继续伪装成 backend-owned。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `Sqrt` 候选的 source role 与消费面 | completed | 已确认 `NEONSqrtF32x8/F32x16/F64x8` 在 no-asm 下只是 exact scalar/leaf 组合且无其他 live source consumer，属于可删 dead wrapper；`NEONSqrtF64x4` 虽然 no-asm runtime slot 也应回落到 scalar，但它仍被 `NEONSqrtF64x8` 的 no-asm source graph 消费，因此只能保留为 source companion |
| 2. 改成 asm-only binding，并只删除真正 dead 的 no-asm wrapper | completed | 已把 `src/fafafa.core.simd.neon.register.inc` 中 `SqrtF32x8/F32x16/F64x4/F64x8` 改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定；已从 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 删除 `NEONSqrtF32x8/F32x16/F64x8` 的 no-asm dead wrapper，保留 `NEONSqrtF64x4` 作为仍被消费的 source companion；`SqrtF64x2` 保持原样 |
| 3. 补 source/runtime/helper 护栏并串行 release 复验 | completed | `dispatchapi` 已新增 `Test_NEON_NoAsmWideSqrtSlots_Keep_Only_Consumed_Companions_And_Reuse_BaseScalar`；两处通用 `SqrtF32x8/F32x16/F64x4/F64x8` capability 断言已从“总是 native”收正为“NEON 复用 scalar、其余 backend 仍要求 native”；`check_nonx86_helper_semantics.py` 已把 `NEONSqrtF32x8/F32x16/F64x8` 改成 absent guard；fresh `git diff --check`、`py_compile`、helper semantics、`DispatchAPI`、`truthfulness --backend neon/riscvv --strict`、`impl-audit-nonx86`、串行 Release `check`、串行 Release `gate` 全部通过；helper summary 现为 `checks=601`，`NEON` truthfulness 现为 `assignments=357 asm_exact=233 asm_suffix_only=10 wrapper_only=114 miswired=0 conflicting_assign=0`，`gate` 尾部为 `GATE OK`，仅诚实保留 optional non-x86 native evidence skip 与历史 `windows_b07_gate.log` evidence skip |

## 2026-05-15 NEON No-Asm Wide MinMax Slot-Ownership Cleanup

### Goal

继续沿同一 slot-ownership truth 线收正 `NEON` no-asm 的 wide `Min/Max`：`Min/MaxF32x8`、`Min/MaxF32x16`、`Min/MaxF64x4`、`Min/MaxF64x8`。这批先确认 `Math.Min/Max` 与 no-asm 本地 `if a<b / if a>b` 语义在 `NaN/±0/相等值` 上一致，再把确实不该继续占 slot 的 no-asm published truth 收回 scalar。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 wide `Min/Max` 的语义与消费面 | completed | 已确认 `NEONMin/MaxF32x4` 与 `NEONMin/MaxF64x2` 的 no-asm 本地比较虽不是 `ScalarMin/Max` 直接转发，但本地 Pascal probe 已验证它们和 `Math.Min/Max` 在 `NaN/±0/相等值` 上语义一致；同时 `NEONMin/MaxF32x8` 在 no-asm 下无其他 live source consumer，而 `F32x16/F64x4/F64x8` wrapper 仍需为 asm build 或更宽 source graph 保留 |
| 2. 改成 asm-only binding，并只删除真正 dead 的 no-asm wrapper | completed | 已把 `src/fafafa.core.simd.neon.register.inc` 中 `Min/MaxF32x8/F32x16/F64x4/F64x8` 改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定；已从 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 删除 `NEONMin/MaxF32x8` 的 no-asm dead wrapper，保留 `NEONMin/MaxF32x16/F64x4/F64x8` 作为仍有 asm/source companion 价值的 wrapper；`Min/MaxF64x2` 保持原样 |
| 3. 补 source/runtime/helper 护栏并串行 release 复验 | completed | `dispatchapi` 已新增 `Test_NEON_NoAsmWideMinMaxSlots_Keep_Necessary_Wrappers_But_Reuse_BaseScalar`；两处通用 `Min/MaxF32x8/F32x16/F64x4/F64x8` capability 断言已从“总是 native”收正为“NEON 复用 scalar、其余 backend 仍要求 native”；`check_nonx86_helper_semantics.py` 已把 `NEONMin/MaxF32x8` 改成 absent guard；fresh `git diff --check`、`py_compile`、helper semantics、`DispatchAPI`、`truthfulness --backend neon/riscvv --strict`、`impl-audit-nonx86`、串行 Release `check`、串行 Release `gate` 全部通过；helper summary 现为 `checks=603`，`NEON` truthfulness 现为 `assignments=357 asm_exact=237 asm_suffix_only=10 wrapper_only=110 miswired=0 conflicting_assign=0`，`gate` 尾部为 `GATE OK`，仍只诚实保留 optional non-x86 native evidence skip 与历史 `windows_b07_gate.log` evidence skip |

## 2026-05-15 NEON No-Asm Wide Clamp Slot-Ownership Cleanup

### Goal

继续沿同一 slot-ownership truth 线收正 `NEON` no-asm 的 wide `Clamp`，但这次不机械套 `Sqrt/MinMax`：只把 `ClampF32x8/F32x16` 的 fake backend-owned slot 收回 scalar，并删除对应 dead wrapper；`ClampF64x2/F64x4/F64x8` 因为仍保留本地 `NaN/signed-zero` fallback 语义，继续保持 backend-owned。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `Clamp` 的 no-asm 语义与消费面 | completed | 已确认 `NEONClampF32x8/F32x16` 在 no-asm 下只是 `NEONClampF32x4` 的分段 forwarder，而 `NEONClampF32x4` 本身又是 exact `ScalarClampF32x4`；同时本地 Pascal probe 已证明 `NEONClampF64x2` 的 no-asm `if/else` loop 与 `ScalarClampF64x2` 在 `NaN` 和 `-0` witness 上不一致，因此 `F64x2/F64x4/F64x8` 不能一起回 scalar |
| 2. 改成部分 asm-only binding，并只删除真正 dead 的 no-asm wrapper | completed | 已把 `src/fafafa.core.simd.neon.register.inc` 中 `ClampF32x8/F32x16` 改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定；保留 `ClampF64x2/F64x4/F64x8` 的 backend-owned register 绑定；已从 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 删除 `NEONClampF32x8/F32x16` dead wrapper，保留 `NEONClampF64x2/F64x4/F64x8` |
| 3. 补 source/runtime/helper 护栏并串行 release 复验 | completed | `dispatchapi` 已新增 `Test_NEON_NoAsmWideClampSlots_Reuse_BaseScalar_Only_For_F32Forwarders_And_Keep_F64LocalFallback`，断言 `F32x8/F32x16` dead wrapper 缺席、asm binding source 仍在、运行时 slot 复用 scalar，同时用 `ClampF64x2` 的 `NaN/-0` witness 钉住 `F64` 链为何继续 backend-owned；两处通用 `ClampF32x8/F32x16` capability 断言已从“总是 native”收正为“NEON 复用 scalar、其余 backend 仍要求 native”；`check_nonx86_helper_semantics.py` 已把 `NEONClampF32x8/F32x16` 改成 absent guard；fresh `git diff --check`、helper semantics、`DispatchAPI`、`impl-audit-nonx86`、串行 Release `check`、串行 Release `gate` 全部通过；helper summary 更新为 `checks=605`，`NEON` truthfulness 更新为 `assignments=357 asm_exact=239 asm_suffix_only=10 wrapper_only=108 miswired=0 conflicting_assign=0`，`gate` 尾部为 `GATE OK`，仍只诚实保留 optional non-x86 native evidence skip 与历史 `windows_b07_gate.log` evidence skip |

## 2026-05-15 Register Truthfulness Allowlist Hygiene Tightening

### Goal

把 `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py` 自己的 `NEON` wrapper allowlist 收回到当前真实状态，并把 “allowlist 比现实更宽” 也纳入 fail-close，避免后续已经修掉的 slot 名字继续留在豁免名单里。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核真实 `wrapper_only` 集合与 allowlist 差值 | completed | 已确认当前 `NEON` allowlist 有 `134` 项，但真实 `wrapper_only` 只有 `108` 个唯一 slot，存在 `26` 个 stale allowlist 名字；`RISCVV` 当前 `26/26` 完全对齐，没有旧豁免残留 |
| 2. 收紧 `NEON` allowlist 并把 stale allowlist 变成 fail-close | completed | 已从 `ALLOWED_WRAPPER_SLOTS_BY_BACKEND['neon']` 删除 `ClampF32x8/F32x16`、`LoadF32x8/F32x16/F64x4/F64x8`、`Min/MaxF32x8/F64x4`、`Splat*`、`Sqrt*`、`Store*`、`Zero*` 这 26 个旧名字；report 现新增 `unused_allowlist_count/slots`，只要 allowlist 宽于当前真实 `wrapper_only` 集合就直接失败 |
| 3. 更新 scratch 并串行 release 复验 | completed | 已同步更新 scratch 三件套，并完成 `git diff --check`、`py_compile`、`truthfulness --backend neon/riscvv --strict`、`impl-audit-nonx86`、串行 Release `check`、串行 Release `gate`；fresh 结果里 `unused_allowlist=0`（neon/riscvv）且 `gate` 尾部仍只剩 optional non-x86 native evidence skip 与历史 `windows_b07_gate.log` evidence skip；提交前会清理 `tests/fafafa.core.simd/__pycache__/` |

## 2026-05-15 NEON No-Asm Narrow I16/U16 Shift Slot-Ownership Cleanup

### Goal

继续沿 `NEON` no-asm slot ownership truth 线，把最后一簇仍然以 `scalar_forwarder` 形态占着发布 slot 的 narrow `I16x8/U16x8` shift 收回到 base scalar truth：`ShiftLeftI16x8`、`ShiftLeftU16x8`、`ShiftRightArithI16x8`、`ShiftRightI16x8`、`ShiftRightU16x8`。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `I16x8/U16x8` narrow shift 的 source role 与消费面 | completed | 全仓检索确认这 5 个名字只出现在 `src/fafafa.core.simd.neon.register.inc`、`src/fafafa.core.simd.neon.scalar.autowrap.inc` 和 `src/fafafa.core.simd.neon.pas`；no-asm 下它们都只是 exact `ScalarShift*` forwarder，没有更宽 no-asm source consumer，asm build 里则仍有真实 owner |
| 2. 改成 asm-only binding 并删除 5 个 no-asm dead wrapper | completed | 已把 `register.inc` 中这 5 个 shift slot 改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定，并从 `neon.scalar.autowrap.inc` 删除对应 5 个 no-asm dead wrapper；`check_nonx86_helper_semantics.py` 已把这 5 个名字改成 absent guard，`check_nonx86_register_truthfulness.py` 已从 `NEON` wrapper allowlist 删除它们 |
| 3. 补 dispatchapi 护栏并串行 release 复验 | completed | 已新增 `Test_NEON_NoAsmNarrowI16U16ShiftSlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders`；fresh `git diff --check`、`py_compile`、helper semantics、`truthfulness --backend neon/riscvv --strict`、Release `DispatchAPI`、`impl-audit-nonx86`、串行 Release `check`、串行 Release `gate` 全部通过；`NEON` truthfulness 现为 `asm_exact=244 wrapper_only=103 unused_allowlist=0` |

## 2026-05-15 Register Truthfulness Mixed-Body Classification Fix

### Goal

修正 `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py` 对“同名 symbol 有多份 Pascal body”时的误判：不能再因为其中一份 body 含有 `Scalar*` forwarder，就把整个 target 错判成 `scalar_forwarder`。这批要把 `NEONSelectF32x4` 这类 mixed body 真相收正，并用 fixture 固化回归。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 mixed-body 误判根因与真实 witness | completed | 已确认旧 `detect_wrapper_kind(...)` 会把 `a_info.bodies` 直接拼成一个字符串后再做 `Scalar*` 搜索；只要任一 body 是 scalar forwarder，整个 target 就会被压成 `scalar_forwarder`。`NEONSelectF32x4` 正是实锤：`src/fafafa.core.simd.neon.pas` 里有本地 per-lane 实现，而 `src/fafafa.core.simd.neon.scalar.utility.inc` 里又有同名 `ScalarSelectF32x4` forwarder，旧逻辑会错把它算成 `wrapper_only + scalar_forwarder` |
| 2. 拆成逐 body 分类并补 mixed fixture | completed | 已新增 `classify_wrapper_body(...)`，并把 `detect_wrapper_kind(...)` 改成逐个 body 归类：只要任一 body 是非 scalar 的本地实现，就直接返回 `pascal_owned`；若没有本地实现但存在 asm helper body，则返回 `asm_helper_forwarder`；仅当所有 body 都是 scalar forwarder 时才返回 `scalar_forwarder`。同时 `parse_args()` 已支持 `--fixture mixed`，并新增 `fixtures/nonx86_register_truthfulness/mixed/` 固化“同名函数同时存在本地 body 与 scalar body”的回归场景 |
| 3. 更新 scratch 并串行 release 复验 | completed | `git diff --check`、`python3 -m py_compile tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`、`truthfulness --fixture good/bad/shadowed/mixed --summary-line --strict`、`truthfulness --backend neon/riscvv --summary-line --strict`、Release `impl-audit-nonx86`、串行 Release `check`、串行 Release `gate` 均已通过；`NEONSelectF32x4` 当前已回到 `wrapper_only + pascal_owned`，`NEON` 的 `asm-only + scalar_forwarder` 分组从 `16` 降到 `15`，`gate` 尾部仍只诚实保留 optional non-x86 native evidence skip 与历史 `windows_b07_gate.log` evidence skip |

## 2026-05-15 NEON Extract/Insert/Select Scalar-Only Slot Cleanup

### Goal

继续清掉 mixed-body 修复后残余的 `NEON asm-only + scalar_forwarder` 组里最后 15 个纯标量转发 slot：`Extract*`、`Insert*`、`Select*`。这一批要把发布 truth 收回到 base scalar table，同时删掉 `neon.scalar.autowrap.inc` 里已无 live source consumer 的 dead wrapper，并补齐 `dispatchapi` / checker 护栏。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 15 个残余 slot 的 source truth 与消费面 | completed | 已确认 `ExtractF32x16/F32x8/F64x4/I32x4/I64x2`、`InsertF32x16/F32x8/F64x4/I32x4/I64x2`、`SelectF32x16/F32x8/F64x4/F64x8/I32x4` 当前只出现在 `src/fafafa.core.simd.neon.register.inc` 与 `src/fafafa.core.simd.neon.scalar.autowrap.inc`；其 body 全部是 exact `Scalar*` forwarder，且没有其他 live source consumer，因此都应回到 base scalar truth |
| 2. 删除 dead wrapper、收回 register truth，并收正 testcase helper 作用域 | completed | 已从 `src/fafafa.core.simd.neon.register.inc` 删除这 15 个 `NEON` 绑定，并从 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 删除对应 dead wrapper；`tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 已把这 15 个名字改成 absent guard，`tests/fafafa.core.simd/check_nonx86_register_truthfulness.py` 已从 `NEON` allowlist 删除它们；`dispatchapi` 新增 `Test_NEON_ExtractInsertSelectSlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders`，同时把几处 `NonX86BackendParity` 的局部 helper 作用域错位收正，并把 testcase 内误用的实现细节 `InvalidateSimdDataPlane` 改成公开接口 `RebindSimdDataPlane` |
| 3. 串行 release 复验并同步 scratch | completed | fresh `git diff --check`、`python3 -m py_compile ...helper_semantics.py ...register_truthfulness.py`、`helper_semantics --summary-line`、`truthfulness --backend neon/riscvv --summary-line --strict`、Release `TTestCase_DispatchAPI`、Release `impl-audit-nonx86`、Release `check`、Release `gate` 全部通过；当前 `backend=neon` truthfulness 为 `assignments=342 asm_exact=244 asm_suffix_only=10 wrapper_only=88 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`，说明 mixed-body 修复后残余的 `asm-only + scalar_forwarder` 已清零；提交前已清理 `tests/fafafa.core.simd/__pycache__/` |

## 2026-05-15 NEON Narrow F64x2 Memory/Construction Slot Cleanup

### Goal

继续沿 `NEON` no-asm slot ownership truth 线，把 `LoadF64x2`、`StoreF64x2`、`SplatF64x2`、`ZeroF64x2` 这 4 个 narrow `F64x2` memory/construction slot 从伪 backend-owned 发布状态收回到 base scalar truth；其中 asm leaf 继续保留，no-asm dead wrapper 要删除，并同步 `DispatchAPI` 与 non-x86 checker 契约。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 4 个 `F64x2` slot 的 source truth 与消费面 | completed | 已确认 `NEONLoadF64x2/StoreF64x2/SplatF64x2/ZeroF64x2` 全仓只命中 `src/fafafa.core.simd.neon.pas`、`src/fafafa.core.simd.neon.scalar.autowrap.inc`、`src/fafafa.core.simd.neon.register.inc`；`autowrap` 中这 4 个 no-asm body 都没有其他 live source consumer，而 `src/fafafa.core.simd.neon.pas` 里仍保留真实 asm leaf |
| 2. 删除 dead wrapper、收回 register truth，并补 dedicated/no-asm 护栏 | completed | 已从 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 删除 `NEONLoadF64x2/StoreF64x2/SplatF64x2/ZeroF64x2` 的 no-asm dead wrapper；`src/fafafa.core.simd.neon.register.inc` 中这 4 个 slot 已改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定；`tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 已把这 4 个名字改成 absent guard，`tests/fafafa.core.simd/check_nonx86_register_truthfulness.py` 已从 `NEON` allowlist 删除它们；`dispatchapi` 新增 `Test_NEON_NoAsmNarrowF64MemorySlots_Reuse_BaseScalar_When_Wrappers_Have_No_Live_SourceConsumers` |
| 3. 收正通用 capability 断言并串行 release 复验 | completed | `Test_NativeNarrowHelperSurfaceParity_WithVectorAsm_IfAvailable` 中 `LoadF64x2/SplatF64x2` 已从“总是 native”收正为 `AssertBackendOwnedSlotIfExpected(...)`；`Test_NativeAlignedLoadAndZeroParity_WithVectorAsm_IfAvailable` 中 `ZeroF64x2` 也已改成 NEON 允许复用 scalar 的条件断言；fresh `git diff --check`、`python3 -m py_compile ...helper_semantics.py ...register_truthfulness.py`、`helper_semantics --summary-line`、`truthfulness --backend neon/riscvv --summary-line --strict`、Release `TTestCase_DispatchAPI`、Release `impl-audit-nonx86`、Release `check`、Release `gate` 全部通过；当前 `backend=neon` truthfulness 为 `assignments=342 asm_exact=248 asm_suffix_only=10 wrapper_only=84 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1` |

## 2026-05-15 NEON No-Asm F64x4 Wide Leaf Arithmetic Slot-Ownership Cleanup

### Goal

继续沿 `NEON` slot ownership truth 线，把 `Add/Sub/Mul/DivF64x4` 从 no-asm fake backend-owned 发布状态收回到 base scalar truth；但和 `F64x2` dead wrapper 不同，这一批要保留 `scalar.autowrap.inc` 里的 `F64x4` wrapper，因为它们仍被 `F64x8` source graph 消费。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `Add/Sub/Mul/DivF64x4` 的 source role 与消费面 | completed | 已确认 `NEONAdd/Sub/Mul/DivF64x4` 只在 `src/fafafa.core.simd.neon.pas`、`src/fafafa.core.simd.neon.scalar.autowrap.inc`、`src/fafafa.core.simd.neon.register.inc` 与测试中命中；其 no-asm body 只是两次 `NEON*F64x2` 组合，而 `NEONAdd/Sub/Mul/DivF64x8` 仍继续消费这些 `F64x4` wrapper，因此它们属于“应保留 source companion，但 runtime slot 不该继续 no-asm backend-owned”的类型 |
| 2. 收回 register truth，保留 source companion，并同步 dedicated/generic 测试 | completed | 已把 `src/fafafa.core.simd.neon.register.inc` 中 `Add/Sub/Mul/DivF64x4` 改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定；`src/fafafa.core.simd.neon.scalar.autowrap.inc` 中对应 4 个 wrapper 全部保留；`tests/fafafa.core.simd/check_nonx86_register_truthfulness.py` 已从 `NEON` allowlist 删除这 4 个名字；`Test_NEON_NoAsmWideLeafFloatArithmeticSlots_Keep_SourceCompanions_But_Reuse_BaseScalar` 已扩进 `F64x4` 的 wrapper/source/runtime 断言 |
| 3. 收正通用 capability 断言并串行 release 复验 | completed | 两处通用 `DispatchAPI` 宽浮点 capability 断言里，`Add/Sub/Mul/DivF64x4` 已从“总是 native”收正为 `AssertNeonReusesScalarOtherwiseNative(...)`；fresh `git diff --check`、`python3 -m py_compile tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`、`helper_semantics --summary-line`、`truthfulness --backend neon/riscvv --summary-line --strict`、Release `TTestCase_DispatchAPI`、Release `impl-audit-nonx86`、Release `check`、Release `gate` 全部通过；当前 `backend=neon` truthfulness 为 `assignments=342 asm_exact=252 asm_suffix_only=10 wrapper_only=80 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1` |

## 2026-05-15 NEON No-Asm Wide Round/Trunc Slot-Ownership Cleanup

### Goal

继续沿 `NEON` no-asm slot ownership truth 线，把 wide `Round/Trunc` 残余收正：删除已无 source consumer 的 `Round/TruncF32x8/F32x16/F64x8` dead wrapper，把 `Round/TruncF64x4` 保留为 `F64x8` no-asm source companion，同时把这些 slot 的 runtime truth 收回到 base scalar table。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 wide `Round/Trunc` source role 与消费面 | completed | 已确认 `Round/TruncF32x8/F32x16/F64x8` 的 no-asm wrapper 全仓只剩 `register + neon.pas + autowrap`，没有其他 live source consumer；`Round/TruncF64x4` 仍被 `Round/TruncF64x8` no-asm graph 消费，因此必须保留为 source companion；`Round/TruncF64x2` 继续保持 backend-owned，不在本批回收范围 |
| 2. 收回 register truth、删除 dead wrapper，并同步 checker/dedicated test | completed | 已把 `src/fafafa.core.simd.neon.register.inc` 中 `Round/TruncF32x8/F32x16/F64x4/F64x8` 改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定；已从 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 删除 `NEONRoundF32x8/F32x16/F64x8` 与 `NEONTruncF32x8/F32x16/F64x8` 这 6 个 dead wrapper，并保留 `NEONRoundF64x4/NEONTruncF64x4`；`tests/fafafa.core.simd/check_nonx86_register_truthfulness.py` 已从 `NEON` allowlist 删除对应 wide `Round/Trunc` 名字，仅保留 `RoundF64x2/TruncF64x2`；`tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 已把被删的 6 个 wrapper 改成 absent guard；`dispatchapi` 新增 `Test_NEON_NoAsmWideRoundTruncSlots_Keep_Only_Consumed_Companions_And_Reuse_BaseScalar` |
| 3. 收正通用 capability 断言并串行 release 复验 | completed | `DispatchAPI` 两处 wide `Round/Trunc` capability 段里，`Round/TruncF32x8/F32x16/F64x4/F64x8` 已从 `AssertNativeSlotNotScalar(...)` 收正为 `AssertNeonReusesScalarOtherwiseNative(...)`；fresh `git diff --check`、`python3 -m py_compile tests/fafafa.core.simd/check_nonx86_helper_semantics.py tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`、`helper_semantics --summary-line`、`truthfulness --backend neon/riscvv --summary-line --strict`、Release `TTestCase_DispatchAPI`、Release `impl-audit-nonx86`、Release `check`、Release `gate` 全部通过；当前 `backend=neon` truthfulness 为 `assignments=342 asm_exact=260 asm_suffix_only=10 wrapper_only=72 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1` |

## 2026-05-15 NEON No-Asm Narrow F64 Compare/Simple Reduction Slot Cleanup

### Goal

继续沿 `NEON` no-asm slot ownership truth 线，把没有更宽 source consumer、且 no-asm body 与 `Scalar*` 逐字同义的窄 `F64x2` compare/simple reduction 壳回收掉：`CmpEq/Ge/Gt/Le/Lt/NeF64x2` 与 `ReduceAdd/ReduceMulF64x2`。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 8 个 `F64x2` slot 的 source role 与语义边界 | completed | 已确认这 8 个名字在 `src/` 内只命中 `src/fafafa.core.simd.neon.pas`、`src/fafafa.core.simd.neon.register.inc`、`src/fafafa.core.simd.neon.scalar.autowrap.inc`，没有任何更宽 no-asm source consumer；并且其 no-asm body 与 `ScalarCmp*/ScalarReduceAdd/ScalarReduceMulF64x2` 逐字同义，不像 `Clamp/Max/Min/ReduceMax/ReduceMin` 那样保留本地 fallback 语义差异 |
| 2. 收回 register truth、删除 dead wrapper，并同步 checker/dedicated test | completed | 已把 `src/fafafa.core.simd.neon.register.inc` 中 `CmpEq/Ge/Gt/Le/Lt/NeF64x2` 与 `ReduceAdd/ReduceMulF64x2` 改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定；已从 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 删除对应 8 个 no-asm dead wrapper；`tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 已把这 8 个名字改成 absent guard；`tests/fafafa.core.simd/check_nonx86_register_truthfulness.py` 已从 `NEON` allowlist 删除 6 个 compare 与 `ReduceAdd/ReduceMulF64x2`；`dispatchapi` 新增 `Test_NEON_NoAsmNarrowF64CompareAndSimpleReductionSlots_Reuse_BaseScalar_When_Wrappers_Have_No_SourceConsumers` |
| 3. 串行 release 复验并更新残余图 | completed | fresh `git diff --check`、`python3 -m py_compile tests/fafafa.core.simd/check_nonx86_helper_semantics.py tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`、`helper_semantics --summary-line`、`truthfulness --backend neon/riscvv --summary-line --strict`、Release `TTestCase_DispatchAPI`、Release `impl-audit-nonx86`、Release `check`、Release `gate` 全部通过；当前 `backend=neon` truthfulness 为 `assignments=342 asm_exact=268 asm_suffix_only=10 wrapper_only=64 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1` |

## 2026-05-15 NEON No-Asm Narrow F64 Sqrt Slot-Ownership Cleanup

### Goal

继续沿 `NEON` no-asm slot ownership truth 线，把 `SqrtF64x2` 的 published slot 收回到 base scalar truth；但和前面那些已经没有 source consumer 的窄壳不同，这一批必须保留 `NEONSqrtF64x2/NEONSqrtF64x4` 作为更宽 no-asm fallback graph 的 source companion。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `SqrtF64x2` 的 source role，并同时核清 `Ceil/Floor/Round/TruncF64x2` 的语义边界 | completed | 已确认 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 中 `NEONSqrtF64x2` 只是逐 lane `Sqrt`，与 `src/fafafa.core.simd.scalar.pas` 中 `ScalarSqrtF64x2` 同义；但 `NEONSqrtF64x4` 的 no-asm graph 仍通过两次 `NEONSqrtF64x2` 消费它。与此同时，`ScalarFloor/Ceil/Round/TruncF64x2` 明确带 `NaN/Inf` guard，且 `Round/Trunc` 还会做 signed-zero 归一化，而 no-asm `NEONFloor/Ceil/Round/TruncF64x2` 只是直接 `Floor/Ceil/Round/Trunc`，因此这几项不能按“纯形状同义”一起回收 |
| 2. 收回 `SqrtF64x2` runtime slot ownership，但保留 source companion 与 asm 绑定源 | completed | 已把 `src/fafafa.core.simd.neon.register.inc` 中 `table.SqrtF64x2 := @NEONSqrtF64x2;` 收进 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}`；`table.SqrtF64x4 := @NEONSqrtF64x4;` 继续保持 asm-only 绑定；`tests/fafafa.core.simd/check_nonx86_register_truthfulness.py` 已从 `ALLOWED_WRAPPER_SLOTS_BY_BACKEND['neon']` 删除 `SqrtF64x2`；`src/fafafa.core.simd.neon.scalar.autowrap.inc` 中 `NEONSqrtF64x2/NEONSqrtF64x4` wrapper 全部保留 |
| 3. 补 dedicated dispatch 护栏并串行 release 复验 | completed | `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 已新增 `Test_NEON_NoAsmNarrowF64SqrtSlot_Keep_SourceCompanion_But_Reuse_BaseScalar`；本批 `git diff --check`、`python3 -m py_compile tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`、`truthfulness --backend neon/riscvv --summary-line --strict`、Release `TTestCase_DispatchAPI`、Release `impl-audit-nonx86`、Release `check`、Release `gate` 全部通过；当前 `backend=neon` truthfulness 为 `assignments=342 asm_exact=269 asm_suffix_only=10 wrapper_only=63 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`，说明 `wrapper_only` 已从 `64` 再降到 `63` |

## 2026-05-16 NEON No-Asm Narrow F64 Round-Family Slot/Fallback Alignment

### Goal

继续沿 `NEON` no-asm slot ownership truth 线，把 `Ceil/Floor/Round/TruncF64x2` 这组窄 `F64x2` published slot 收回到 base scalar truth；同时把它们的 no-asm fallback shape 也真正收正成最小必要形态：
- `Floor/CeilF64x2`：既然 wide `F64` no-asm wrapper 早已不存在，就把 dead wrapper 直接删掉
- `Round/TruncF64x2`：因为 `F64x4` no-asm graph 仍要消费它们，所以保留 source companion，但 body 改成 exact `Scalar*F64x2` forwarder

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `Floor/Ceil` 与 `Round/Trunc` 的 source role 差异 | completed | 已确认 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 中 `NEONRound/TruncF64x4` 仍通过两次 `NEONRound/TruncF64x2` 消费窄 wrapper；相反，`NEONFloor/CeilF64x2` 在 `src/` 中已没有任何 no-asm source consumer，wide `F64x4/F64x8` floor/ceil wrapper 只剩 asm 叶子 |
| 2. 收正 no-asm fallback 形态并收回 4 个 narrow `F64x2` published slot | completed | 已从 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 删除 dead `NEONCeilF64x2/NEONFloorF64x2`；已把 `NEONRoundF64x2/NEONTruncF64x2` 改成 `Result := ScalarRound/TruncF64x2(a);`；`src/fafafa.core.simd.neon.register.inc` 中 `table.Ceil/Floor/Round/TruncF64x2 := @NEON...` 已全部收进 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}`；`tests/fafafa.core.simd/check_nonx86_register_truthfulness.py` 已从 `NEON` allowlist 删除这 4 个名字 |
| 3. 补 dedicated 护栏并串行 release 复验 | completed | `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 已新增 `Test_NEON_NoAsmNarrowF64RoundFamilySlots_Keep_Only_Necessary_SourceCompanions_And_Reuse_BaseScalar`，同时本批 `git diff --check`、`py_compile`、`truthfulness --backend neon/riscvv --summary-line --strict`、Release `TTestCase_DispatchAPI`、Release `TTestCase_IEEE754EdgeCases`、Release `impl-audit-nonx86`、Release `check`、Release `gate` 全部通过；当前 `backend=neon` truthfulness 为 `assignments=342 asm_exact=273 asm_suffix_only=10 wrapper_only=59 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`，说明 `wrapper_only` 已从 `63` 再降到 `59` |

## 2026-05-16 NEON No-Asm Narrow F64 Min/Max Slot/Fallback Alignment

### Goal

继续沿 `NEON` no-asm slot ownership truth 线，把 `MaxF64x2/MinF64x2` 的 published slot 收回到 base scalar truth；同时保留窄 `F64x2` source companion 给 `F64x4/F64x8` no-asm fallback graph 使用。本批明确不混入 `ReduceMax/ReduceMinF64x2`，避免把更高风险的语义链和 `Min/Max` 一起处理。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `Max/MinF64x2` 的 source role 与语义边界 | completed | 已确认 `NEONMax/MinF64x4` 的 no-asm graph 仍通过两次 `NEONMax/MinF64x2` 消费窄 wrapper，因此 `Max/MinF64x2` 不是 dead wrapper；同时 `ScalarMax/MinF64x2` 已是当前 stable scalar truth，本批只把窄 no-asm body 收正为 exact `Scalar*` forwarder，并明确把 `ReduceMax/ReduceMinF64x2` 留在下一批单独审查 |
| 2. 收正 no-asm fallback 形态并收回 2 个 narrow `F64x2` published slot | completed | `src/fafafa.core.simd.neon.scalar.autowrap.inc` 中 `NEONMaxF64x2/NEONMinF64x2` 已改成 `Result := ScalarMax/MinF64x2(a, b);`；`src/fafafa.core.simd.neon.register.inc` 中 `table.MaxF64x2 := @NEONMaxF64x2;` 与 `table.MinF64x2 := @NEONMinF64x2;` 已全部收进 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}`；`tests/fafafa.core.simd/check_nonx86_register_truthfulness.py` 已从 `NEON` allowlist 删除 `MaxF64x2/MinF64x2` |
| 3. 补 dedicated 护栏并串行 release 复验 | completed | `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 已新增 `Test_NEON_NoAsmNarrowF64MinMaxSlots_Keep_SourceCompanion_But_Reuse_BaseScalar`，同时本批 `git diff --check`、`python3 -m py_compile tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`、`truthfulness --backend neon/riscvv --summary-line --strict`、Release `TTestCase_DispatchAPI`、Release `TTestCase_IEEE754EdgeCases`、Release `impl-audit-nonx86`、Release `check`、Release `gate` 全部通过；当前 `backend=neon` truthfulness 为 `assignments=342 asm_exact=275 asm_suffix_only=10 wrapper_only=57 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`，说明 `wrapper_only` 已从 `59` 再降到 `57` |

## 2026-05-16 NEON No-Asm Narrow F64 Extrema Reduction Slot Cleanup

### Goal

继续沿 `NEON` no-asm slot ownership truth 线，把 `ReduceMaxF64x2/ReduceMinF64x2` 的 published slot 收回到 base scalar truth。与上一批 `Min/MaxF64x2` 不同，这一对 reduction 在 `src/` 中没有任何更宽 no-asm source consumer，因此这批要直接删除 no-asm dead wrapper，并补上专门的 IEEE754 特殊值测试来固定当前 scalar `Math.Max/Min` 的 NaN/零值次序语义。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `ReduceMax/ReduceMinF64x2` 的语义边界与 source consumer | completed | 已确认 `NEONReduceMax/ReduceMinF64x2` 在 `src/` 内只命中 `src/fafafa.core.simd.neon.pas`、`src/fafafa.core.simd.neon.register.inc`、`src/fafafa.core.simd.neon.scalar.autowrap.inc`，没有任何更宽 no-asm source consumer；并通过本地 Pascal probe 复核了 `ScalarReduceMin/MaxF64x2` 的 `Math.Min/Max` 与 no-asm `if a<b` / `if a>b` 在 `NaN`、`+0/-0`、相等值上的当前 FPC 行为一致 |
| 2. 删除 dead wrapper、收回 published slot，并补 dedicated/runtime/IEEE754 护栏 | completed | 已从 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 删除 `NEONReduceMaxF64x2/NEONReduceMinF64x2` no-asm dead wrapper；`src/fafafa.core.simd.neon.register.inc` 中 `table.ReduceMaxF64x2 := @NEONReduceMaxF64x2;` 与 `table.ReduceMinF64x2 := @NEONReduceMinF64x2;` 已全部收进 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}`；`tests/fafafa.core.simd/check_nonx86_register_truthfulness.py` 已从 `NEON` allowlist 删除 `ReduceMaxF64x2/ReduceMinF64x2`；`dispatchapi` 新增 `Test_NEON_NoAsmNarrowF64ExtremaReductionSlots_Reuse_BaseScalar_When_Wrappers_Have_No_SourceConsumers`；`ieee754.testcase` 新增 `Test_F64_ReduceMinMax_SpecialCases` 固定 scalar 当前 NaN/zero-order truth |
| 3. 串行 release 复验并更新残余图 | completed | 本批 `git diff --check`、`python3 -m py_compile tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`、`truthfulness --backend neon/riscvv --summary-line --strict`、Release `TTestCase_DispatchAPI`、Release `TTestCase_IEEE754_F64`、Release `impl-audit-nonx86`、Release `check`、Release `gate` 全部通过；当前 `backend=neon` truthfulness 为 `assignments=342 asm_exact=277 asm_suffix_only=10 wrapper_only=55 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`，说明 `wrapper_only` 已从 `57` 再降到 `55` |

## 2026-05-16 Non-x86 Wrapper Context Truthfulness Checker Hardening

### Goal

继续收紧 `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py` 自身的真值模型，不再把所有 `wrapper_only` 豁免混成一类；明确区分 `always / asm-only / no-asm` 三种合法上下文，避免 checker 既放过错误的 published ownership，又把合法的 companion wrapper 误报成 miswired。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核当前 `wrapper_only` 的真实上下文归属 | completed | 已确认旧 checker 的盲区不在 backend 源码，而在 allowlist 语义过粗：`NEON ClampF64x2/F64x4/F64x8` 与 `RISCVV Extract*` 实际属于 `no-asm wrapper-only`；`NEON` wide float/select/andnot 与 wide integer compare，以及 `RISCVV SelectF32x8/F64x4/I32x4` 则属于 `asm-only wrapper-only`；`RISCVV` 其余少量 `wrapper_only` 才是 `always` |
| 2. 收紧 checker 规则与 report 口径 | completed | 已把旧的通用 `ALLOWED_WRAPPER_SLOTS_BY_BACKEND` 拆成 `ALLOWED_ALWAYS_WRAPPER_SLOTS_BY_BACKEND`、`ALLOWED_ASM_ONLY_WRAPPER_SLOTS_BY_BACKEND`、`ALLOWED_NO_ASM_ONLY_WRAPPER_SLOTS_BY_BACKEND`；`build_reason_list()` 现在按 assignment `context` 精确校验；human/json report 也新增 `always wrapper ok / asm-only wrapper ok / no-asm wrapper ok` 与对应 slot 列表 |
| 3. 严格复验并同步 scratch 收口 | completed | 本批源码状态下 `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`、`truthfulness --backend neon --summary-line --strict`、`truthfulness --backend riscvv --summary-line --strict`、Release `impl-audit-nonx86`、Release `check`、Release `gate` 均已通过；fresh strict 结果为 `neon: assignments=342 asm_exact=277 asm_suffix_only=10 wrapper_only=55 miswired=0 unused_allowlist=0`，其 context split 为 `always=0 / asm-only=52 / no-asm=3`；`riscvv: assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 miswired=0 unused_allowlist=0`，其 context split 为 `always=14 / asm-only=3 / no-asm=9` |

## 2026-05-16 RISCVV Helper-Owned Exact-Scalar Slot Ownership Guard

### Goal

继续沿 non-x86 truth 审查往下切，把 `RISCVV` 当前 `always wrapper-only` 里那一簇“no-asm source 是 exact scalar helper forwarder，但 published slot 仍故意 backend-owned”的 `I64/U64`/窄 `AndNot` 槽位补成 dedicated `DispatchAPI` 护栏，避免仓库里只剩 allowlist 知道它们“合法”，却没人守住它们为什么合法。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核这簇 `RISCVV always wrapper-only` 的真实 source/register/runtime 关系 | completed | 已确认 `AndNotI64x2/MinI64x2/MaxI64x2/AndNotU64x2/CmpEqU64x2/CmpLtU64x2/CmpGtU64x2/MinU64x2/MaxU64x2/AndNotI8x16/AndNotU16x8/AndNotU8x16` 在 `src/fafafa.core.simd.riscvv.helpers.inc` 中都是 exact `Scalar*` forwarder，但 `src/fafafa.core.simd.riscvv.register.inc` 仍无条件把这些 slot 绑定到 `RISCVV*` 符号，因此它们的真实性质不是“应回收到 scalar”，而是“helper-owned but intentionally backend-owned” |
| 2. 新增 dedicated ownership 护栏 | completed | 已在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `Test_RISCVV_HelperOwnedExactScalarSlots_Stay_BackendOwned`，对上述 12 个 slot 同时固定三层真相：`helpers.inc` 里 exact scalar body 仍存在、`register.inc` 仍保持 backend-owned 绑定、runtime `sbRISCVV` dispatch slot 仍不复用 scalar 指针 |
| 3. 串行 Release 复验并同步 scratch 收口 | completed | 本批 `git diff --check`、Release `TTestCase_DispatchAPI`、Release `check`、Release `gate` 全部通过；`check` 里 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=20 issues=0 status=ok`、`NONX86_HELPER_SEMANTICS_SUMMARY checks=643 status=ok` 继续保持绿态，`gate` 末尾仍只诚实保留 optional non-x86 native evidence skip 与历史 Windows evidence optional skip |

## 2026-05-16 Non-x86 Key-Slot Audit Coverage Expansion

### Goal

把刚补上的 `RISCVV` 12 个 helper-owned exact-scalar slot 继续纳入 Python 侧 `check_nonx86_key_slot_audit.py`，让 `check` 阶段也能直接审计这批 truth，而不是只靠单个 `DispatchAPI` testcase。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 让 key-slot audit 认识新的 truth source | completed | 已把 `check_nonx86_key_slot_audit.py` 从全局 `KEY_SLOTS` 改成按 backend 维护的 `KEY_SLOTS_BY_BACKEND`；`riscvv` 新增 12 个 helper-owned slot；`EXPECTATION_PROCEDURES['riscvv']` 已纳入 `Test_RISCVV_HelperOwnedExactScalarSlots_Stay_BackendOwned`；解析器也新增识别 `AssertHelperOwnedExactScalarSlot` |
| 2. 收正显式断言要求与报告口径 | completed | `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['riscvv']` 已补入这 12 个 slot，避免它们再次退回“默认 backend_owned 例外”；fresh `key-slot-audit` 输出现已直接列出 `AndNotI64x2/MinI64x2/.../AndNotU8x16`，并把 `riscvv` slot 总数从 `10` 提升到 `22` |
| 3. 最小必要复验并收口 | completed | 按新工作法只跑了 `git diff --check`、`python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --summary-line`、Release `check`；结果全部通过，summary 现为 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=32 issues=0 status=ok` |

## 2026-05-16 RISCVV Select Key-Slot Explicit Ownership Coverage

### Goal

把 `RISCVV SelectF32x8/SelectF64x4/SelectI32x4` 从“只有 register-truthfulness allowlist 知道”的状态，提升成 `key-slot audit + DispatchAPI dedicated assert` 都显式覆盖的 ownership truth，避免这 3 个 `asm-only wrapper-only` slot 后续静悄悄退回 scalar。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核当前 coverage 缺口是否真实存在 | completed | 已确认 `check_nonx86_register_truthfulness.py` 明确把 `RISCVV SelectF32x8/SelectF64x4/SelectI32x4` 归类为合法 `asm-only wrapper-only`，但 `check_nonx86_key_slot_audit.py` 之前完全不跟踪这 3 个 slot；`DispatchAPI` dedicated test 里也只显式钉住了 `SelectF64x4`，`SelectF32x8/SelectI32x4` 仍只靠 generic parity 与 allowlist 间接覆盖 |
| 2. 把 3 个 Select slot 提升为显式 truth source | completed | 已在 `tests/fafafa.core.simd/check_nonx86_key_slot_audit.py` 把 `SelectF32x8/SelectF64x4/SelectI32x4` 纳入 `KEY_SLOTS_BY_BACKEND['riscvv']` 与 `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['riscvv']`；并在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 的 `Test_RISCVV_WideFallbackOnlySlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders` 中补齐这 3 个 slot 的 `AssertRegisterOwnsBackendSlot` 与 runtime ownership 断言 |
| 3. 按最小 release 链复验并收口 | completed | 本批按新工作法只跑了 `git diff --check`、`python3 -m py_compile tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`、`python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --summary-line`、Release `TTestCase_DispatchAPI`、Release `check`；全部通过，fresh summary 已更新为 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=35 issues=0 status=ok`，其中 `backend=riscvv ok slots=25` |

## 2026-05-16 RISCVV Extract Companion Ownership Coverage

### Goal

把 `RISCVV ExtractF32x8/F32x16/F64x2/F64x4/I32x4/I32x8/I32x16/I64x2/I64x4` 这 9 个合法 `no-asm wrapper-only` 槽位，从“truthfulness checker 知道但 key-slot audit 不理解”的状态，提升成 `key-slot audit + DispatchAPI dedicated testcase` 都显式覆盖的 ownership truth。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `Extract*` 的真实 source/register/runtime 形态 | completed | 已确认 `src/fafafa.core.simd.riscvv.facade.inc` 中 9 个 `Extract*` 在 no-asm 侧都是 exact `ScalarExtract*` companion wrapper；`src/fafafa.core.simd.riscvv.pas` 中同名 wrapper 在 asm-enabled 侧继续做索引饱和并调用 `RISCVVExtract*Asm`；`src/fafafa.core.simd.riscvv.register.inc` 对每个 slot 都保留了显式 `{$IFDEF RISCVV_ASSEMBLY}` / `{$ELSE}` 双分支绑定，因此它们不是“应回收到 scalar”的 residual，而是合法的双相 backend-owned companion slot |
| 2. 把 9 个 `Extract*` 提升成显式 truth source，并补齐 key-slot 审计模型 | completed | 已在 `tests/fafafa.core.simd/check_nonx86_key_slot_audit.py` 把 9 个 `Extract*` 纳入 `KEY_SLOTS_BY_BACKEND['riscvv']`、`EXPECTATION_PROCEDURES['riscvv']`、`REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['riscvv']`；并在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `Test_RISCVV_ExtractSlots_Keep_NoAsmCompanionWrappers_And_RuntimeOwnership`；同时修正 key-slot audit 本身，使其显式接受这类“asm 侧 helper-backed、no-asm 侧 exact scalar companion wrapper、但 runtime slot 继续 backend-owned”的合法 mixed-context 形态 |
| 3. 按最小 release 链复验并收口 | completed | 本批先用 `python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --backend riscvv --summary-line` 抓到审计模型缺口，再补齐模型后重跑 `git diff --check`、`python3 -m py_compile tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`、`python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --backend riscvv --summary-line`、Release `TTestCase_DispatchAPI`、Release `check`；全部通过，fresh summary 已更新为 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=44 issues=0 status=ok`，其中 `backend=riscvv ok slots=34` |

## 2026-05-16 RISCVV Dot Key-Slot Audit Lift

### Goal

把 `RISCVV DotF64x2/DotF64x4` 这最后一对尚未进入 `key-slot audit` 的 `wrapper_only` policy slot 提升进常规 `check` 门禁，避免它们继续只活在 dedicated `DispatchAPI` testcase 里。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核当前 residual 是否真实存在 | completed | 已对照 `check_nonx86_register_truthfulness.py --backend riscvv --json --strict` 与当前 `KEY_SLOTS_BY_BACKEND['riscvv']`，确认 `RISCVV current_wrapper_only_slots` 里仍未进入 `key-slot audit` 的只剩 `DotF64x2/DotF64x4` 这两个名字 |
| 2. 把 `DotF64x2/F64x4` 提升成常规 key-slot | completed | 已在 `tests/fafafa.core.simd/check_nonx86_key_slot_audit.py` 把 `DotF64x2/ DotF64x4` 纳入 `KEY_SLOTS_BY_BACKEND['riscvv']` 与 `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['riscvv']`；无需新增 Pascal testcase，因为 `TTestCase_DispatchAPI.Test_RISCVV_FacadeSlots_Reuse_BaseScalar_When_Wrappers_Are_ScalarPassThrough` 已经显式固定了 register ownership 与 runtime slot ownership |
| 3. 按脚本批次最小链复验并收口 | completed | 本批只跑了 `git diff --check`、`python3 -m py_compile tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`、`python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --backend riscvv --summary-line`、Release `check`；全部通过，fresh summary 已更新为 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=46 issues=0 status=ok`，其中 `backend=riscvv ok slots=36` |

## 2026-05-16 NEON Clamp Key-Slot Audit Lift

### Goal

把 `NEON ClampF64x2/F64x4/F64x8` 这 3 个当前仅活在 truthfulness allowlist 与 dedicated `DispatchAPI` testcase 里的合法 `no-asm wrapper-only` slot，正式提升进 `key-slot audit` 常规门禁。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核当前 coverage 缺口是否真实存在 | completed | 已用 `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --json --strict` 复核，确认 `NEON current_no_asm_wrapper_slots` 只剩 `ClampF64x2/F64x4/F64x8`；同时现有 `python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --backend neon --summary-line` 仍只审计 10 个旧 key slot，说明这 3 个名字尚未进入常规 `check` |
| 2. 把 3 个 `ClampF64*` 提升成常规 key-slot | completed | 已在 `tests/fafafa.core.simd/check_nonx86_key_slot_audit.py` 把 `ClampF64x2/F64x4/F64x8` 纳入 `KEY_SLOTS_BY_BACKEND['neon']`；把 `TTestCase_DispatchAPI.Test_NEON_NoAsmWideClampSlots_Reuse_BaseScalar_Only_For_F32Forwarders_And_Keep_F64LocalFallback` 纳入 `EXPECTATION_PROCEDURES['neon']`；并让解析器显式识别 `AssertAsmBindingStillPresent` 作为 `backend_owned` truth source，同时对这 3 个 slot 开启 `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['neon']` |
| 3. 按脚本批次最小链复验并收口 | completed | 本批只跑 `git diff --check`、`python3 -m py_compile tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`、`python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --backend neon --summary-line`、Release `check`；全部通过，fresh summary 已更新为 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon slots=13 issues=0 status=ok`，全局 summary 更新为 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=49 issues=0 status=ok` |

## 2026-05-16 NEON Wide MinMax Key-Slot Audit Lift

### Goal

把 `NEON MaxF32x16/MaxF64x8/MinF32x16/MinF64x8` 这 4 个当前仅活在 truthfulness allowlist 与 dedicated `DispatchAPI` testcase 里的合法 `asm-only wrapper-only` slot，正式提升进 `key-slot audit` 常规门禁。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核当前 coverage 缺口是否真实存在 | completed | 已对照 `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --json --strict` 与当前 `KEY_SLOTS_BY_BACKEND['neon']`，确认 `MaxF32x16/MaxF64x8/MinF32x16/MinF64x8` 仍属于 `NEON missing_from_key`；同时 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 里的 `Test_NEON_NoAsmWideMinMaxSlots_Keep_Necessary_Wrappers_But_Reuse_BaseScalar` 已现成固定了 `AssertAsmBindingStillPresent` 与 runtime scalar-reuse truth |
| 2. 把 4 个 wide `Min/Max` slot 提升成常规 key-slot | completed | 已在 `tests/fafafa.core.simd/check_nonx86_key_slot_audit.py` 把 `MaxF32x16/MaxF64x8/MinF32x16/MinF64x8` 纳入 `KEY_SLOTS_BY_BACKEND['neon']`；把 `Test_NEON_NoAsmWideMinMaxSlots_Keep_Necessary_Wrappers_But_Reuse_BaseScalar` 纳入 `EXPECTATION_PROCEDURES['neon']`；并对这 4 个 slot 开启 `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['neon']` |
| 3. 按脚本批次最小链复验并收口 | completed | 本批只跑 `git diff --check`、`python3 -m py_compile tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`、`python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --backend neon --summary-line`、Release `check`；全部通过，fresh summary 已更新为 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon slots=17 issues=0 status=ok`，全局 summary 更新为 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=53 issues=0 status=ok` |

## 2026-05-16 NEON Wide Leaf Float Arithmetic Key-Slot Audit Lift

### Goal

把 `NEON Add/Sub/Mul/DivF32x16` 与 `Add/Sub/Mul/DivF64x8` 这 8 个当前仅活在 truthfulness allowlist 与 dedicated `DispatchAPI` testcase 里的合法 `asm-only wrapper-only` slot，正式提升进 `key-slot audit` 常规门禁。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核当前 coverage 缺口是否真实存在 | completed | 已对照 `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --json --strict` 与当前 `KEY_SLOTS_BY_BACKEND['neon']`，确认 `AddF32x16/AddF64x8/SubF32x16/SubF64x8/MulF32x16/MulF64x8/DivF32x16/DivF64x8` 仍属于 `NEON missing_from_key`；同时 `Test_NEON_NoAsmWideLeafFloatArithmeticSlots_Keep_SourceCompanions_But_Reuse_BaseScalar` 已现成固定了 `AssertAsmBindingStillPresent` 与 runtime scalar-reuse truth |
| 2. 把 8 个 wide arithmetic slot 提升成常规 key-slot | completed | 已在 `tests/fafafa.core.simd/check_nonx86_key_slot_audit.py` 把 `Add/Sub/Mul/DivF32x16` 与 `Add/Sub/Mul/DivF64x8` 纳入 `KEY_SLOTS_BY_BACKEND['neon']`；把 `Test_NEON_NoAsmWideLeafFloatArithmeticSlots_Keep_SourceCompanions_But_Reuse_BaseScalar` 纳入 `EXPECTATION_PROCEDURES['neon']`；并对这 8 个 slot 开启 `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['neon']` |
| 3. 按脚本批次最小链复验并收口 | completed | 本批只跑 `git diff --check`、`python3 -m py_compile tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`、`python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --backend neon --summary-line`、Release `check`；全部通过，fresh summary 已更新为 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon slots=25 issues=0 status=ok`，全局 summary 更新为 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=61 issues=0 status=ok` |

## 2026-05-16 NEON SelectF32x4 Dedicated Truth Lift

### Goal

把 `NEON SelectF32x4` 从“只有 asm source 断言和分散的泛化能力测试知道”的状态，补成 dedicated `source + register + runtime` truth source，并正式提升进 `key-slot audit` 常规门禁。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核当前 truth 是否缺 dedicated coverage | completed | 已确认 `SelectF32x4` 在 `check_nonx86_register_truthfulness.py` 中属于合法 `asm-only wrapper-only`，`src/fafafa.core.simd.neon.pas` 提供 asm-enabled backend-local lane loop，`src/fafafa.core.simd.neon.scalar.utility.inc` 提供 no-asm `ScalarSelectF32x4` companion wrapper，`src/fafafa.core.simd.neon.register.inc` 仅在 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 下绑定 `table.SelectF32x4 := @NEONSelectF32x4;`；但旧 dedicated testcase 只检查 asm source 不直接 scalar-forward，仍缺 register/runtime 明示护栏 |
| 2. 补 dedicated testcase 并接进 key-slot audit | completed | 已扩展 `Test_NEON_SelectF32x4_AsmEnabledSource_Does_Not_ScalarForward`，让它同时固定 asm source 不直转 scalar、no-asm scalar companion 仍存在、register asm-only binding 仍存在，以及 runtime `sbNEON` slot 在 asm-compiled 时 backend-owned、否则回落 scalar；同时已把 `SelectF32x4` 纳入 `tests/fafafa.core.simd/check_nonx86_key_slot_audit.py` 的 `KEY_SLOTS_BY_BACKEND['neon']`、`EXPECTATION_PROCEDURES['neon']` 与 `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['neon']` |
| 3. 按 Pascal 批次最小链复验并收口 | completed | 本批跑 `git diff --check`、`python3 -m py_compile tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`、`python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --backend neon --summary-line`、Release `TTestCase_DispatchAPI`、Release `check`；全部通过，fresh summary 已更新为 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon slots=26 issues=0 status=ok`，全局 summary 更新为 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=62 issues=0 status=ok` |

## 2026-05-16 NEON AndNot Ownership Lift

### Goal

把 `NEON AndNotI8x16/AndNotU16x8/AndNotU8x16` 从“只有 truthfulness checker 知道它们是合法 asm-only wrapper-owned slot”的状态，补成 dedicated `source + register + runtime` truth source，并正式提升进 `key-slot audit` 常规门禁。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核当前 truth 是否缺 dedicated coverage | completed | 已确认这 3 个 slot 在 `check_nonx86_register_truthfulness.py` 中都属于合法 `asm-only wrapper-only`；`src/fafafa.core.simd.neon.compare.inc` 中对应实现不是 scalar-forward，而是 backend-local composition（`NEONAnd*` + `NEONNot*`）；`src/fafafa.core.simd.neon.register.inc` 在 asm-enabled 下显式发布 `table.AndNotI8x16/U16x8/U8x16 := @NEONAndNot*`；当前缺口是没有 dedicated testcase 把这组 source/register/runtime truth 收拢成单一事实源 |
| 2. 补 dedicated testcase 并接进 key-slot audit | completed | 已在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `Test_NEON_AndNotSlots_Keep_AsmOwnedCompositions_And_RuntimeOwnership`，让它同时固定 compare source 中 backend-local composition 仍存在、register asm-only binding 仍存在，以及 runtime `sbNEON` slot 在 asm-compiled 时 backend-owned、否则回落 scalar；同时已把这 3 个 slot 纳入 `tests/fafafa.core.simd/check_nonx86_key_slot_audit.py` 的 `KEY_SLOTS_BY_BACKEND['neon']`、`EXPECTATION_PROCEDURES['neon']` 与 `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['neon']` |
| 3. 按 Pascal 批次最小链复验并收口 | completed | 本批跑 `git diff --check`、`python3 -m py_compile tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`、`python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --backend neon --summary-line`、Release `TTestCase_DispatchAPI`、Release `check`；全部通过，fresh summary 已更新为 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon slots=29 issues=0 status=ok`，全局 summary 更新为 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=65 issues=0 status=ok` |

## 2026-05-16 NEON Wide Integer Compare Key-Slot Audit Lift

### Goal

把 `NEON` 当前剩余的 36 个 `wide integer compare` 合法 `asm-only wrapper-only` slot，一次性提升进 `key-slot audit` 常规门禁，收口 `NEON missing_from_key`。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核现成 dedicated truth source 是否足够覆盖整簇 | completed | 已确认 `python3 ...check_nonx86_register_truthfulness.py --backend neon --json --strict` 对账后，`NEON missing_from_key` 仅剩 `CmpEq/CmpGe/CmpGt/CmpLe/CmpLt/CmpNe` 六大家族共 36 个 `asm-only wrapper-only` slot；同时 `Test_NEON_NoAsmWideIntegerCompareSlots_Keep_SourceCompanions_But_Reuse_BaseScalar` 已现成固定了 source companion、关键 composition witness、register asm binding 与 runtime scalar-reuse truth，无需再改 Pascal testcase |
| 2. 把 36 个 wide integer compare slot 提升成常规 key-slot | completed | 已在 `tests/fafafa.core.simd/check_nonx86_key_slot_audit.py` 把这 36 个 `Cmp*` slot 全部纳入 `KEY_SLOTS_BY_BACKEND['neon']`；把 `Test_NEON_NoAsmWideIntegerCompareSlots_Keep_SourceCompanions_But_Reuse_BaseScalar` 纳入 `EXPECTATION_PROCEDURES['neon']`；并对这 36 个 slot 开启 `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['neon']` |
| 3. 按脚本批次最小链复验并收口 | completed | 本批只跑 `git diff --check`、`python3 -m py_compile tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`、`python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --backend neon --summary-line`、Release `check`；全部通过，fresh summary 已更新为 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon slots=65 issues=0 status=ok`，全局 summary 亦为 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=101 issues=0 status=ok` |

## 2026-05-16 Non-x86 Key-Slot Cluster Dedup

### Goal

把 `tests/fafafa.core.simd/check_nonx86_key_slot_audit.py` 里已经重复硬编码的 key-slot 簇抽成共享定义，降低后续继续扩 `NEON/RISCVV` ownership 门禁时的 drift 风险，同时保持现有审计语义不变。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核当前结构冗余是否真实存在 | completed | 已确认同一批 slot 名字同时散落在 `KEY_SLOTS_BY_BACKEND`、`REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS` 与局部 backend 例外里；尤其是 `NEON` 36 个 wide compare、`RISCVV` 9 个 extract、12 个 helper-owned slot 都已出现“同一真相多处手填”的形态 |
| 2. 抽出共享 slot 簇并让门禁常量复用 | completed | 已在脚本顶部提炼 `NEON_*` / `RISCVV_*` 共享 tuple 簇，并让 `KEY_SLOTS_BY_BACKEND`、`REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS`、`ALLOWED_BACKEND_OWNED_NO_ASM_SCALAR_WRAPPER_SLOTS_BY_BACKEND` 复用同一真源，保持计数与语义不变 |
| 3. 按 checker 批次最小链复验并收口 | completed | 已跑 `git diff --check`、`python3 -m py_compile tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`、`python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --summary-line`、Release `check`；summary 继续保持 `backend=neon ok slots=65`、`backend=riscvv ok slots=36`、`NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=101 issues=0 status=ok`，说明本批只做结构去冗余，没有改变审计语义 |

## 2026-05-16 Check Optional Non-x86 Opt-In Listing

### Goal

把 `tests/fafafa.core.simd/BuildOrTest.sh check` 与 `tests/fafafa.core.simd/buildOrTest.bat check` 里的 `nonx86 opt-in list-suites` 阶段收成可显式跳过的 optional 检查，保留默认行为不变，但让纯 checker / Python 审查批次能避免额外非必要构建。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `check` 的重路径是否已有开关 | completed | 已确认 `BuildOrTest.sh check` / `buildOrTest.bat check` 当前都无 `nonx86 opt-in list-suites` 跳过开关；`wiring-sync` 与 `experimental` 有 env 开关，但 non-x86 opt-in 没有，因此纯 Python 审查也会被额外拖进 `neon/riscvv` opt-in 构建 |
| 2. 为 shell/batch `check` 对齐 optional 开关 | completed | 已为 shell 与 batch 都新增 `SIMD_CHECK_NONX86_OPTIN` 分支：默认未设时继续执行 `nonx86-optin-list-suites`，设为 `0` 时明确跳过并输出原因 |
| 3. 按脚本批次最小链复验并收口 | completed | 已跑 `git diff --check`、`bash -n tests/fafafa.core.simd/BuildOrTest.sh`、`FAFAFA_BUILD_MODE=Release SIMD_CHECK_NONX86_OPTIN=0 bash tests/fafafa.core.simd/BuildOrTest.sh check`；日志已明确出现 `[CHECK] SKIP optional non-x86 opt-in suite listing`，且整条 Release `check` 继续通过。Windows 批处理本轮只做静态对照，未在本机执行 |

## 2026-05-16 Windows Check Non-x86 Audit Parity

### Goal

把 `tests/fafafa.core.simd/buildOrTest.bat check` 当前落后的 non-x86 Python 审查补齐到与 shell `check` 更一致的覆盖面，至少收回 `helper-semantics`、`key-slot-audit`、`riscvv-abi-shape`、`source-reachability` 这 4 条已经在 shell 默认门禁里的检查。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 batch `check` 与 shell `check` 的真实差异 | completed | 已确认 shell `check` 默认会跑 `run_nonx86_helper_semantics_check`、`run_nonx86_key_slot_audit_check`、`run_riscvv_abi_shape_check`、`run_source_reachability_check`；而 batch `check` 之前只跑到 `register_include/dispatch_read_scope/sse2_structure/suite_manifest`，这 4 条 non-x86 审查都掉线了 |
| 2. 在 batch runner 补齐最小原生 Python 入口并接回 `check` | completed | 已在 `tests/fafafa.core.simd/buildOrTest.bat` 新增 `:nonx86_helper_semantics_check`、`:key_slot_audit_check_internal`、`:riscvv_abi_shape_check`、`:source_reachability_check` 四个原生 Python 入口，并把它们接回 `check` 主线；同时在 `BuildOrTest.sh` 的 Windows runner parity guard 中增加对应 source-safe pattern，防止以后再次掉线 |
| 3. 按 shell 主门禁做 source-safe 复验并收口 | completed | 已跑 `git diff --check`、`bash -n tests/fafafa.core.simd/BuildOrTest.sh`、`FAFAFA_BUILD_MODE=Release SIMD_CHECK_NONX86_OPTIN=0 bash tests/fafafa.core.simd/BuildOrTest.sh check`；日志显示 `windows runner parity signatures present`、`Python checker runtime guard present`，且 `helper-semantics / key-slot-audit / riscvv-abi / source-reachability` 都继续通过。Windows batch 本轮仍未做实机运行，只能算静态对齐已收口 |

## 2026-05-16 Targeted Python Audit Actions Exposure

### Goal

把 `helper-semantics`、`source-reachability`、`riscvv-abi-shape` 从“只挂在 `check` 主线内部”的状态提升成可直接调用的公开 action，减少后续纯 Python 审查批次为整条 `check` 付费的次数，同时保持 shell/batch usage 和 parity guard 一致。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核当前 runner 真实缺口 | completed | 已确认 `BuildOrTest.sh` 只有内部函数没有公开 case；`buildOrTest.bat` 只有内部 label 没有顶部 dispatch / usage 暴露；这导致后续要跑单条 Python 审查时只能借道整条 `check` |
| 2. 暴露 shell/batch 公开 action，并补齐 parity 真相源 | completed | 已在 shell case/usage 中新增 `helper-semantics`、`source-reachability`、`riscvv-abi-shape`；已在 batch 顶部 dispatch、usage/help 中同步公开这 3 个 action，并补 `check_windows_runner_parity()` 的 required pattern，避免 shell/batch action 表再次漂移 |
| 3. 串行最小验证并收口 | completed | 已串行跑 `git diff --check`、`bash -n tests/fafafa.core.simd/BuildOrTest.sh`、`bash tests/fafafa.core.simd/BuildOrTest.sh helper-semantics`、`bash tests/fafafa.core.simd/BuildOrTest.sh source-reachability`、`bash tests/fafafa.core.simd/BuildOrTest.sh riscvv-abi-shape`、`FAFAFA_BUILD_MODE=Release SIMD_CHECK_NONX86_OPTIN=0 bash tests/fafafa.core.simd/BuildOrTest.sh check`；全部通过。Windows batch 本轮仍是 source-safe 对齐，未做实机运行 |

## 2026-05-16 Windows Closeout Wrapper Parity

### Goal

把 batch runner 里已经缺失的一组 Windows closeout / freeze-status 公开入口补齐到与 shell runner 更一致，让 Windows/CMD 用户也能直达 shell 已公开的收口 action，同时继续由 `check_windows_runner_parity()` 守住 action 表、usage/help 和 wrapper 真相源。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 审计 shell/batch 公开 action 差集 | completed | 已对比 `BuildOrTest.sh` 与 `buildOrTest.bat` 的 action 表，确认 `win-evidence-via-gh`、`win-closeout-dryrun`、`win-closeout-snippets`、`freeze-status`、`freeze-status-linux`、`freeze-status-rehearsal` 都是 shell 已公开、batch 缺入口的真实差集；剩余 shell-only 只保留 `evidence-linux`、`native-evidence`、`verify-nonx86-native-evidence`、`restore-nightly-evidence`、`gate-summary-selfcheck` 这类仍未桥接的动作 |
| 2. 补 batch bash-delegate wrapper，并同步 parity required pattern | completed | 已在 `tests/fafafa.core.simd/buildOrTest.bat` 为上述 6 个 action 新增顶部 dispatch、usage/help 和 `bash %ROOT%BuildOrTest.sh ...` wrapper label；已在 `tests/fafafa.core.simd/BuildOrTest.sh` 的 `check_windows_runner_parity()` 中移除它们的 shell-only 豁免，并补 required dispatch / usage / help / run-line pattern |
| 3. 做轻量 shell 烟测与 Release `check` 复验 | completed | 已跑 `git diff --check`、`bash -n tests/fafafa.core.simd/BuildOrTest.sh`、action 差集脚本、`bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-dryrun`、`FAFAFA_BUILD_MODE=Release SIMD_CHECK_NONX86_OPTIN=0 bash tests/fafafa.core.simd/BuildOrTest.sh check`；`win-closeout-dryrun` 与整条 Release `check` 均通过。Windows batch 仍未做实机执行，本轮验证仍以 source-safe parity 为主 |

## 2026-05-16 Remaining Evidence Action Parity

### Goal

把 runner parity 里剩余的 shell-only 公开证据/自检动作继续收缩到只剩内联特例：补齐 `gate-summary-selfcheck`、`evidence-linux`、`native-evidence`、`verify-nonx86-native-evidence`、`restore-nightly-evidence` 的 batch wrapper，并让 shell parity guard 不再对它们长期豁免。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核剩余差集是否真的是公开入口缺口 | completed | fresh action diff 已确认 runner 剩余 shell-only 只剩 `evidence-linux`、`gate-summary-selfcheck`、`native-evidence`、`restore-nightly-evidence`、`verify-nonx86-native-evidence`，再加上 batch 内联/特例的 `debug`、`release`、`verify-win-evidence`；说明这 5 条是最后一组可对齐的公开入口 |
| 2. 补 batch wrapper 并撤掉 parity guard 的 shell-only allow | completed | 已在 `tests/fafafa.core.simd/buildOrTest.bat` 为这 5 条动作新增顶部 dispatch、usage/help 与 `bash %ROOT%BuildOrTest.sh ...` wrapper；已在 `tests/fafafa.core.simd/BuildOrTest.sh` 的 `LAllowedShellOnly` 中只保留 `import-nonx86-native-evidence`，并把这 5 条补进 required dispatch / usage / help / run-line pattern |
| 3. 用轻量 selfcheck 和 Release `check` 做收口验证 | completed | 已跑 `git diff --check`、`bash -n tests/fafafa.core.simd/BuildOrTest.sh`、fresh action diff、`bash tests/fafafa.core.simd/BuildOrTest.sh gate-summary-selfcheck`、`FAFAFA_BUILD_MODE=Release SIMD_CHECK_NONX86_OPTIN=0 bash tests/fafafa.core.simd/BuildOrTest.sh check`；`gate-summary-selfcheck` 与 Release `check` 均通过，剩余 action 差集已收缩到 shell 内联/特例与 Windows alias |

## 2026-05-16 Batch Inline Action Normalization

### Goal

继续把 runner parity 从“还剩内联特例”收成“只剩平台 alias”：将 batch 顶部仍内联处理的 `debug`、`release`、`verify-win-evidence`、`evidence-win-verify` 全部标准化成显式 label dispatch，并让 shell parity guard 按新结构守住它们。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 确认剩余差集已收敛到内联特例 | completed | fresh action diff 证明，在上一批后 runner 剩余 shell-only 已只剩 `debug`、`release`、`verify-win-evidence` 这类 batch 内联控制流，而 batch-only 只剩 Windows alias `evidence-win`；这说明继续补 action 表已没意义，真正剩下的是 dispatch 结构标准化 |
| 2. 把内联分支改成显式 label，并同步 parity required pattern | completed | 已在 `tests/fafafa.core.simd/buildOrTest.bat` 把 `debug`、`release`、`verify-win-evidence`、`evidence-win-verify` 改为 `goto :debug_action / :release_action / :verify_win_evidence / :evidence_win_verify`，并把原逻辑迁到显式 label；已在 `tests/fafafa.core.simd/BuildOrTest.sh` 的 `check_windows_runner_parity()` required pattern 中同步改成新 dispatch 线并补 label/script variable 线索 |
| 3. 用差集脚本与 Release `check` 验证“只剩 alias” | completed | 已跑 `git diff --check`、`bash -n tests/fafafa.core.simd/BuildOrTest.sh`、fresh action diff、`FAFAFA_BUILD_MODE=Release SIMD_CHECK_NONX86_OPTIN=0 bash tests/fafafa.core.simd/BuildOrTest.sh check`；结果已收缩到 `remaining shell_only: []`、`remaining batch_only: ['evidence-win', 'evidence-win-verify']`，且 Release `check` 继续通过 |

## 2026-05-16 Runner Parity Quick Path

### Goal

把 runner 相关批次从“每次都要借道 `BuildOrTest.sh check` 才能证明 action parity 没坏”收紧成一个专用轻量入口，避免后续继续在这条线上反复跑大链。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核剩余问题是否真在 action namespace，而不是功能逻辑 | completed | 已确认正式 `check_windows_runner_parity()` / `check_cpuinfo_runner_parity()` 本来就能静态证明当前 shell/batch 与 cpuinfo runner 的 dispatch/help/guard 口径；真正低效点是这些证明只能挂在 `BuildOrTest.sh check` 大链里顺带执行 |
| 2. 暴露专用 `runner-parity` 轻量入口并接通 batch 代理 | completed | 已在 `tests/fafafa.core.simd/BuildOrTest.sh` 新增 `runner-parity` action，专门调用 `check_windows_runner_parity()` 与 `check_cpuinfo_runner_parity()`；同时在 `tests/fafafa.core.simd/buildOrTest.bat` 新增同名 wrapper，经 `bash %ROOT%BuildOrTest.sh runner-parity` 代理执行，并同步补齐 shell/batch usage/help/parity required pattern |
| 3. 用轻量验证证明以后无需再借道大链 | completed | 已跑 `git diff --check`、`bash -n tests/fafafa.core.simd/BuildOrTest.sh`、fresh action diff、`bash tests/fafafa.core.simd/BuildOrTest.sh runner-parity`；结果为 `remaining shell_only: []`、`remaining batch_only: ['evidence-win', 'evidence-win-verify']`，且输出同时给出 `windows runner parity signatures present`、`cpuinfo runner parity signatures present`、`runner parity quick path` |

## 2026-05-16 Runner Parity Call-Site Unification

### Goal

在 `runner-parity` 已经成为正式 fast path 之后，把 `check` 与 `gate_step_build_check()` 中还残留的分散旧调用也统一收口，避免同一条 runner 证明链在主门禁里继续保留两套入口。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核主门禁里是否仍有旧调用残留 | completed | 已确认 `tests/fafafa.core.simd/BuildOrTest.sh` 里除 `run_runner_parity()` 本体外，`check` case 与 `gate_step_build_check()` 仍各自直接调用一遍 `check_windows_runner_parity()` / `check_cpuinfo_runner_parity()`；这正是 fast path 落地后留下的调用面冗余 |
| 2. 统一主门禁调用面 | completed | 已把 `check` case 与 `gate_step_build_check()` 中的成对旧调用改为单次 `run_runner_parity`，让 runner 证明链在主门禁和显式 action 上都只剩一个入口 |
| 3. 轻量验证并确认无行为漂移 | completed | 已跑 `git diff --check`、`bash -n tests/fafafa.core.simd/BuildOrTest.sh`、`bash tests/fafafa.core.simd/BuildOrTest.sh runner-parity`；输出仍为 `windows runner parity signatures present`、`cpuinfo runner parity signatures present`、`runner parity quick path`，说明统一后快路径本体未受影响 |

## 2026-05-16 Gate Build-Check Static Guard Parity

### Goal

继续沿主门禁 drift 线收口，把 `gate_step_build_check()` 中遗漏的一组低成本静态护栏补齐到与 `check` 更一致，避免 gate 绿了却没有覆盖 `helper-semantics`、`key-slot-audit`、`source-reachability`、`sse2-structure` 这类已经被日常 `check` 视为默认门禁的审查。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 确认差异是否真的未被 gate 后续步骤覆盖 | completed | 已逐段复核 `run_gate()`：`experimental intrinsics` 与 `register truthfulness` 确实会在 gate 后半段单独建步；但 `helper-semantics`、`key-slot-audit`、`source-reachability`、`sse2-structure` 以及 `windows cpuinfo.x86 batch success-criteria smoke` 并没有被任何后续 gate step 补跑，属于真实 coverage 缺口 |
| 2. 把缺失的低成本静态护栏补回 `gate_step_build_check()` | completed | 已在 `tests/fafafa.core.simd/BuildOrTest.sh` 的 `gate_step_build_check()` 中补入 `run_nonx86_helper_semantics_check`、`run_nonx86_key_slot_audit_check`、`run_windows_cpuinfo_x86_batch_build_success_criteria_smoke`、`run_source_reachability_check`、`run_sse2_structure_check`；保留 `experimental` / `register truthfulness` 继续由 gate 独立步骤负责，避免重复建步 |
| 3. 用 gate 级定向验证确认主门禁已补齐 | completed | 已跑 `git diff --check`、`bash -n tests/fafafa.core.simd/BuildOrTest.sh`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`；fresh gate 通过，build-check 段现在已实际输出 `HELPER-SEMANTICS`、`KEY-SLOT-AUDIT`、`SOURCE-REACHABILITY`、`SSE2-STRUCTURE` 与 `windows cpuinfo.x86 batch success-criteria smoke` 的结果 |

## 2026-05-16 Shared Static Build-Check Core

### Goal

在 `check` 与 `gate_step_build_check()` 已经多次出现 drift 之后，把两边共同的静态 build-check 核心提成单一 helper，减少后续再出现“先补一边、忘另一边”的结构性风险。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核当前剩余差异哪些是有意的 | completed | fresh 清单比对显示，`check` 与 `gate_step_build_check()` 在补完 coverage 后，真正剩余差异已只剩 `check` 的 `Backend adapter sync (python-only)` 提示、`SIMD_CHECK_NONX86_OPTIN` 分支、`wiring-sync`、`register truthfulness` 与 experimental isolation；共同静态核心从 `run_runner_parity` 到 `run_dispatch_preinit_smoke` 已完全同构 |
| 2. 抽共享 helper 并保留各自差异 | completed | 已在 `tests/fafafa.core.simd/BuildOrTest.sh` 新增 `run_static_build_check_core()`，把共同静态 core 收到一处；`check` case 改为 `build/check log + adapter-sync echo + run_static_build_check_core + check-only optionals`，`gate_step_build_check()` 改为 `build/check log + run_static_build_check_core + gate-only nonx86-optin list` |
| 3. 验证共享 helper 没改坏 check/gate | completed | 已跑 `git diff --check`、`bash -n tests/fafafa.core.simd/BuildOrTest.sh`、`FAFAFA_BUILD_MODE=Release SIMD_CHECK_NONX86_OPTIN=0 bash tests/fafafa.core.simd/BuildOrTest.sh check`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`；两条主链均通过，说明这次是结构去重，不是行为漂移 |

## 2026-05-16 IEEE754 Empty Finally Cleanup

### Goal

按更高效的工作法收一个小闭环：不再继续机械深挖 runner/build-check，而是只清 `tests/fafafa.core.simd/fafafa.core.simd.ieee754.testcase.pas` 里已确认的空 `finally` 与失效 `oldVectorAsm` 捕获，保留所有仍承载真实 restore 语义的 `ResetToAutomaticBackend` 块不动。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 区分空壳 cleanup 与真实 restore 块 | completed | 已确认 `ieee754.testcase` 顶层仍有 10 处空 `finally`，其中多处还保留未使用的 `oldVectorAsm/LOldVectorAsm`；而 non-x86 每后端迭代里的 `finally ResetToAutomaticBackend` 仍承载真实 backend 切换收尾，不能混改 |
| 2. 删除空 `finally` 与失效局部变量 | completed | 已删除 `IEEE754EdgeCases`、`AVX2RoundTruncIEEE754`、`NonX86IEEE754` 中这些纯空 outer `finally`，并同步删掉对应的 `oldVectorAsm`/`LOldVectorAsm` 局部变量与赋值；测试逻辑、backend 选择与数值断言保持不变 |
| 3. 做轻量 release 验证 | completed | 已跑 `git diff --check`，并用 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IEEE754EdgeCases --suite=TTestCase_AVX2RoundTruncIEEE754 --suite=TTestCase_NonX86IEEE754` 验证；构建、测试与 leak check 均通过 |

## 2026-05-16 DataPlane Empty Finally Cleanup

### Goal

继续按小闭环方式清理 `tests/fafafa.core.simd/fafafa.core.simd.dataplane.testcase.pas` 中一个已证实无语义负担的空 `finally`，去掉误导性的局部状态捕获，但不改任何 SIMD 生产逻辑或 dataplane 发布语义。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 确认该 cleanup 是否真的冗余 | completed | 已复核 `TTestCase_DataPlane` 的基类链：`TSimdVectorAsmStatefulTestCase.TearDown` 会恢复 `FSavedVectorAsm`，`TSimdBackendStatefulTestCase.TearDown` 会恢复 `FSavedBackend`；因此该用例外层空 `finally` 与未使用的 `LOldVectorAsm` 不再承担 method-local restore 责任 |
| 2. 删除空 `finally` 与失效局部变量 | completed | 已在 `Test_DataPlane_VectorAsmRoundTrip_Reuses_PreviouslyPublishedSnapshot` 删除未使用的 `LOldVectorAsm` 及其赋值，并移除纯空 outer `try/finally`；向量汇编开关切换、backend 判定与 dataplane 快照断言保持不变 |
| 3. 做定向 release 验证并收口 | completed | 已跑 `git diff --check`，并用 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DataPlane` 验证；构建、测试与 leak check 均通过 |

## 2026-05-16 PublicAbi Early Empty Finally Cleanup

### Goal

继续沿 `empty finally + assigned-but-never-used vector-asm state capture` 这条高确定性冗余线，先收 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 前部两处与 `dataplane/ieee754` 同类的空壳 cleanup，不扩到后面更复杂的 hook/rollback 语义测试。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核候选是否具备和前批相同的安全前提 | completed | 已确认 `TTestCase_PublicAbi = class(TSimdVectorAsmStatefulTestCase)`，因此 `TearDown` 仍会恢复 `FSavedVectorAsm` 与 `FSavedBackend`；前部两处命中都表现为 `LOldVectorAsm := IsVectorAsmEnabled` 后无读取，且 outer `finally` 为空，符合“空壳 cleanup”特征 |
| 2. 只清前部两处高确定性命中 | completed | 已在 `Test_PublicApi_Table_Uses_Stable_Cdecl_EntryPoints_AfterBackendSwitch` 与 `Test_PublicApi_VectorAsmRoundTrip_Reuses_PreviouslyPublishedMetadataTable` 删除未使用的 `LOldVectorAsm` 及纯空 outer `try/finally`；backend/vector-asm 切换流程和断言保持不变 |
| 3. 做定向 release 验证并收口 | completed | 已跑 `git diff --check`，并用 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi` 验证；构建、测试与 leak check 均通过 |

## 2026-05-16 PublicAbi CapabilityBits Empty Finally Cleanup

### Goal

继续沿 `publicabi.testcase` 的同一条高确定性冗余线推进，把前部一串 capability-bits 测试里共享同样基类恢复前提、未使用 `LOldVectorAsm`、且 outer `finally` 为空的命中一次性收掉，同时保持验证仍只落在 `TTestCase_PublicAbi`。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核这一串命中是否都还是“空壳 cleanup” | completed | 已复核 `1394..1815` 一带的 capability-bits 用例：它们都在 `TTestCase_PublicAbi` 下，流程只做 `SetVectorAsmEnabled(True/False)` + capability bit / representative slot 断言，没有 method-local restore；`LOldVectorAsm` 统一只赋值不读取，outer `finally` 统一为空 |
| 2. 成组删除死变量与空 `finally` | completed | 已在 9 个 capability-bits 用例中删除未使用的 `LOldVectorAsm` 与纯空 outer `try/finally`：x86 shuffle/masked ops/always-on integer、AVX2 shuffle、AVX512 FMA/shuffle/vector-asm gated bits 等断言逻辑保持不变 |
| 3. 继续用单 suite release 验证收口 | completed | 已跑 `git diff --check`，并再次用 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi` 验证；构建、测试与 leak check 均通过 |

## 2026-05-16 PublicAbi NEON RISCVV Empty Finally Cleanup

### Goal

继续沿 `publicabi.testcase` 的 capability-bits 线往下推进，但只覆盖已证实和前两批同形态的 5 个 `NEON/RISCVV` 用例：删除未使用 `LOldVectorAsm` 与纯空 outer `try/finally`，不触碰后续真正带 restore 的 refresh/hook 逻辑。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 NEON/RISCVV 段里哪些还是同类冗余 | completed | 已逐段读 `1859..2108` 一带：`Clear_NEONVectorAsmGatedBits_WhenVectorAsmDisabled` 以及 4 个 `RISCVV` capability/gated-bits 用例都只做 vector-asm 开关与 capability bit/slot 断言；而后续 `Refreshes_WhenBackendBecomesNonDispatchable` 已带真实 `RegisterBackend` restore，明确排除 |
| 2. 只清 5 个同类命中 | completed | 已在 `Clear_NEON...`、`Expose_RISCVVIntegerOps...`、`Expose_RISCVVFMA...`、`Expose_RISCVVShuffle...`、`Clear_RISCVVVectorAsmGatedBits...` 中删除未使用的 `LOldVectorAsm` 与纯空 outer `try/finally`；NEON/RISCVV capability 判定与 runtime rebuild 断言保持不变 |
| 3. 继续用单 suite release 验证收口 | completed | 已跑 `git diff --check`，并再次用 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi` 验证；构建、测试与 leak check 均通过 |

## 2026-05-16 PublicAbi PostCapability Empty Finally Cleanup

### Goal

在 `publicabi.testcase` capability-bits 段之后，继续清理一小批同样高确定性的 outer 空壳 cleanup，但明确只覆盖“真实 restore 已由内层 finally 或基类 TearDown 承担”的方法，不碰那些外层 finally 自身还带条件 restore 的路径。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 给后续命中做语义分层 | completed | 已复核 `2091..2403` 一带：`ActiveBackendId_Tracks_RegisterSlot_After_ReRegister`、`StableState_Tracks_CurrentBackend_After_ControlPlaneSwitches`、`ActiveBackendId_Tracks_FinalState_When_HookReRegister_Overrides_ForcedSelection`、`FailedHookMutation_Restores_AutomaticBackend_Immediately` 都满足“`LOldVectorAsm` 无读取 + outer finally 为空 + 真正 restore 在内层 finally 或 TearDown”；而 `FailedHookMutation_DoesNotRevive...` / `Restores_PreviousForcedBackend` 这类外层 finally 自带条件 restore，明确排除 |
| 2. 只清 4 个高确定性命中 | completed | 已在上述 4 个方法中删除未使用的 `LOldVectorAsm` 与纯空 outer `try/finally`；identity re-register、stable-state、failed-hook automatic restore 的实际 backend/hook restore 逻辑保持不变 |
| 3. 继续用单 suite release 验证收口 | completed | 已跑 `git diff --check`，并再次用 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi` 验证；构建、测试与 leak check 均通过 |

## 2026-05-16 PublicAbi Automatic Restore Empty Finally Cleanup

### Goal

继续在 `publicabi.testcase` 后半段清理一组 automatic-backend / vector-asm late-force 同类空壳 cleanup，只覆盖外层 `finally` 为空、真实 hook cleanup 已由内层 finally 承担的方法；不碰更后面“previous forced backend preserve”那串语义更重的路径。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 automatic/vector-asm late-force 组的语义边界 | completed | 已复核 `2946..3201` 一带：`ResetToAutomaticBackend_HookLateForce_Restores_AutomaticBackend`、`Refreshes_WhenVectorAsmDisabled_ReSelects_Away_From_ScalarBacked_CurrentBackend`、`ResetToAutomaticBackend_HookLateForce_DuringRestore_Restores_AutomaticBackend`、`SetVectorAsmEnabled_HookLateForce_Restores_AutomaticBackend`、`SetVectorAsmEnabled_HookLateForce_DuringRestore_Restores_AutomaticBackend` 都满足“`LOldVectorAsm` 无读取 + outer finally 为空 + 真正 hook cleanup 在内层 finally 或由 TearDown 统一恢复”；而更后面的 previous-forced preserve 路径先不碰 |
| 2. 只清 5 个同类命中 | completed | 已在上述 5 个方法中删除未使用的 `LOldVectorAsm` 与纯空 outer `try/finally`；automatic best backend、scalar force、dispatch hook remove/reset 的实际收尾逻辑保持不变 |
| 3. 继续用单 suite release 验证收口 | completed | 已跑 `git diff --check`，并再次用 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi` 验证；构建、测试与 leak check 均通过 |

## 2026-05-16 PublicAbi Previous Forced Empty Finally Cleanup

### Goal

继续推进到 `publicabi.testcase` 里的 previous-forced preserve 段，但只收 4 个仍然满足“外层 finally 为空、真实 restore 在内层 finally 或 TearDown”条件的命中，不碰后面那些外层 finally 自带 table-capture restore 的 `RegisterBackend ... preserves previous forced backend` 路径。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 给 previous-forced preserve 段继续做语义分层 | completed | 已复核 `3183..3454` 一带：`SetVectorAsmEnabled_HookLateAutomaticReset_Preserves_PreviousForcedBackend`、`...DuringRestore...`、`SetVectorAsmEnabled_HookLateForce_DuringRestore_Preserves_PreviousForcedBackend`、`RegisterBackend_HookLateForce_Restores_AutomaticBackend` 都满足“`LOldVectorAsm` 无读取 + outer finally 为空 + 真正 hook cleanup 在内层 finally”；而 `RegisterBackend_HookLateAutomaticReset_Preserves_PreviousForcedBackend` / `RegisterBackend_HookLateForce_DuringRestore_Preserves_PreviousForcedBackend` 的外层 finally 还承担 `if LPreviousTableCaptured then RegisterBackend(...)`，明确排除 |
| 2. 只清 4 个高确定性命中 | completed | 已在上述 4 个方法中删除未使用的 `LOldVectorAsm` 与纯空 outer `try/finally`；previous forced backend、hook reset/late-force、RegisterBackend late-force 的实际 cleanup 逻辑保持不变 |
| 3. 继续用单 suite release 验证收口 | completed | 已跑 `git diff --check`，并再次用 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi` 验证；构建、测试与 leak check 均通过 |

## 2026-05-16 PublicAbi Remaining Empty Finally Cleanup Repair

### Goal

收掉 `publicabi.testcase` 本轮最后 4 个同类空壳 cleanup 命中，并修平半途删改留下的 Pascal 结构错误；继续坚持“只动 testcase、只跑 `TTestCase_PublicAbi` release 验证”的最小闭环。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核最后 4 个目标方法的真实边界 | completed | 已确认 `CachedTable_RemainsCallable_Across_Rebind` 与 `CachedTable_Preserves_PreviousSnapshot_Metadata_Across_Rebind` 只是纯空 outer `try/finally`；`BackendPodInfo_Refreshes_WhenBackendBecomesNonDispatchable` 与 `RollbackRestore_ReSelects_RequestedBackend_Before_Return` 的真实 restore 仍分别由内层 `RegisterBackend(...)` / hook cleanup `finally` 承担 |
| 2. 修正半删状态并完成剩余 cleanup | completed | 已删除前两处纯空 outer `try/finally`；并把后两处误留下的孤立 outer `try` 一并去掉，顺手删除 `RollbackRestore_ReSelects_RequestedBackend_Before_Return` 中未使用的 `LOldVectorAsm` |
| 3. 用单 suite release 复验收口 | completed | 已跑 `git diff --check`，并用 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi` 复验；构建、测试与 leak check 全部通过 |

## 2026-05-16 PublicAbi Remaining Dead VectorAsm Capture Cleanup

### Goal

继续留在 `publicabi.testcase` 同一条高确定性收口线上，但这次不再碰任何 `finally` 结构，只清掉剩余 9 个“声明 + 赋值但从不读取”的 `LOldVectorAsm` 死变量。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核剩余 `LOldVectorAsm` 是否全部为死变量 | completed | 已用 `rg -n "LOldVectorAsm"` 复核当前文件只剩 9 组“声明 + `IsVectorAsmEnabled` 赋值”，没有任何读取；这些方法的 outer `finally` 仍承担条件 `RegisterBackend(...)` restore，因此本批明确只删变量不动 restore 结构 |
| 2. 删除剩余 9 个死变量捕获 | completed | 已在失败 hook、rollback restore、late-force、RegisterBackend previous-forced preserve 等 9 个 `publicabi` 方法中删除 `LOldVectorAsm` 局部变量与赋值，不改其 inner/outer `finally` 逻辑 |
| 3. 用同一条最小 release 验证链收口 | completed | 已跑 `git diff --check`，并再次用 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi` 验证；构建、测试与 leak check 全部通过 |

## 2026-05-16 DispatchApi Front Empty Finally And Dead VectorAsm Cleanup

### Goal

把同样的高确定性清理方法扩到 `dispatchapi.testcase` 前段，但仍然只处理两类命中：
- 纯空 outer `try/finally`
- `LOldVectorAsm` 只声明和赋值、但从不读取的死状态捕获

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `dispatchapi` 前段候选的真实边界 | completed | 已逐段复核 `990..1675`：前部 5 个简单 API 用例与数个 hook/rollback 用例里存在纯空 outer `finally`；另有一组 rollback / previous-forced 用例虽然 outer `finally` 仍承担条件 `RegisterBackend(...)` restore，但 `LOldVectorAsm` 依旧只声明和赋值、无任何读取 |
| 2. 只收高确定性前段命中 | completed | 已删除 5 个简单 API 用例和 4 个 hook/rollback 用例中的纯空 outer `try/finally`；并在 8 个 rollback / previous-forced 方法里删除未使用的 `LOldVectorAsm`，保留所有 inner/outer restore 逻辑不变 |
| 3. 用单 suite release 复验收口 | completed | 已跑 `git diff --check`，并用 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` 复验；构建、测试与 leak check 全部通过 |

## 2026-05-16 DispatchApi Mid Empty Finally And Dead VectorAsm Cleanup

### Goal

继续沿 `dispatchapi.testcase` 同一条高确定性清理线推进到 `1684..2328` 区间，只收两类命中：
- outer `finally` 真正为空的测试壳
- `LOldVectorAsm` 只声明和赋值、但不读取的死状态捕获

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核中段候选的真实边界 | completed | 已逐段复核 `1684..2328`：`BackendInfoAvailableFalse_IsNotSelectable`、`ResetToAutomaticBackend...`、`SetVectorAsmEnabled...`、`RegisterBackend_HookLateForce...`、`RegisterBackend_Canonicalizes...` 等方法存在纯空 outer `finally`；而 `SetActiveBackend_HookLateFailure_Preserves_PreviousForcedBackend`、`RegisterBackend_HookLateAutomaticReset_Preserves_PreviousForcedBackend`、`RegisterBackend_HookLateForce_DuringRestore_Preserves_PreviousForcedBackend` 的 outer `finally` 仍承担条件 `RegisterBackend(...)` restore，只能删 `LOldVectorAsm` |
| 2. 只收中段高确定性命中 | completed | 已删除 10 个方法中的纯空 outer `try/finally`，并在 12 个方法中删除未使用的 `LOldVectorAsm`；所有 inner `finally`、hook reset 与条件 restore 保持不变 |
| 3. 用单 suite release 复验收口 | completed | 已跑 `git diff --check`，并再次用 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` 复验；构建、测试与 leak check 全部通过 |

## 2026-05-16 DispatchApi Metadata And Snapshot Empty Finally Cleanup

### Goal

继续把同样的 fail-close 清理法推进到 `dispatchapi.testcase` 的 `2277..2810` 区间，重点收掉 metadata / snapshot round-trip 这一簇里的纯空 outer `finally` 与未读取的 `LOldVectorAsm`。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 metadata/snapshot 簇的真实边界 | completed | 已逐段复核 `2277..2810`：`SupportedAliases_StayCpuOnly_WhenBackendBecomesNonDispatchable`、`RegisteredBackendDispatchTable_PreservesCanonicalTextMetadata_After_ReRegister`、`CurrentBackendInfo_PreservesCanonicalTextMetadata_After_ReRegister` 都只剩纯空 outer `finally`；`PublicSmokeDefaultBackendPredictor...`、`VectorAsmDisabled_ReSelects_Away...`、`RegisterBackend_SameBackendRoundTrip...`、`SetVectorAsmEnabled_RoundTrip...` 同时带纯空 outer `finally` 和未读取 `LOldVectorAsm` |
| 2. 只收这一簇高确定性命中 | completed | 已删除 7 个方法中的纯空 outer `try/finally`，并删除 4 个方法中的未使用 `LOldVectorAsm`；内层 `RegisterBackend(...)` restore 与 snapshot 断言保持不变 |
| 3. 用单 suite release 复验收口 | completed | 已跑 `git diff --check`，并再次用 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` 复验；构建、测试与 leak check 全部通过 |

## 2026-05-16 DispatchApi Facade Dispatch Tracking Empty Finally Cleanup

### Goal

继续沿 `dispatchapi.testcase` 的高确定性清理线推进到 `2796..3445`，把 `current backend stable-state` 与一组 facade dispatch tracking 测试中的纯空 outer `finally` 和未读取的 `LOldVectorAsm` 收掉。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 facade tracking 簇的真实边界 | completed | 已逐段复核 `2796..3445`：`CurrentBackendHelpers_StayAligned_After_ControlPlaneSwitches` 带未读取 `LOldVectorAsm` 且 outer `finally` 为空；`VecF32x4Reduce`、`VecF64x2Reduce`、`VecF64x2Math`、`VecF32VectorMath`、`VecWideFloatDot`、`VecF64x4Reduce`、`VecF32x8Reduce`、`VecF64x8Reduce`、`VecF32x16Reduce` 这串 facade dispatch tracking 测试都由内层 `RegisterBackend(...)` restore，outer `finally` 纯空 |
| 2. 只收这一簇高确定性命中 | completed | 已删除 10 个方法中的纯空 outer `try/finally`，并删除 `CurrentBackendHelpers_StayAligned_After_ControlPlaneSwitches` 中未使用的 `LOldVectorAsm`；所有内层 restore 和 facade parity / dispatch 跟踪断言保持不变 |
| 3. 用单 suite release 复验收口 | completed | 已跑 `git diff --check`，并再次用 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` 复验；构建、测试与 leak check 全部通过 |

## 2026-05-16 DispatchApi SSE2 Impl Audit Empty Finally Cleanup

### Goal

继续沿 `dispatchapi.testcase` 的高确定性清理线推进到 `5128..5459` 这一簇 SSE2 实现审计测试，只收两类已证实无行为价值的冗余：
- `LOldVectorAsm` 只声明和赋值、但从不读取
- outer `try/finally` 的 `finally` 体完全为空

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 SSE2 审计簇的真实边界 | completed | 已逐段复核 `Test_SSE2_I32x4_U32x4_Mul_Use_NonScalar_Impl_And_Keep_Parity`、`Test_SSE2_I64x2_Compare_Use_NonScalar_Impl_And_Keep_Parity`、`Test_SSE2_F32VectorMath_Use_NonScalar_Impl_And_Keep_Parity`：三者都只有 `SetVectorAsmEnabled(True)`、backend 选择与 parity 断言，没有任何 outer restore；其 `LOldVectorAsm` 仅做 `IsVectorAsmEnabled` 捕获且后续无读取 |
| 2. 只收这一簇高确定性命中 | completed | 已在上述 3 个 SSE2 测试中删除纯空 outer `try/finally`，并删除对应未使用的 `LOldVectorAsm`；所有 SSE2 source-shape 审计、dispatch/backend 断言与 parity 断言保持不变 |
| 3. 用单 suite release 复验收口 | completed | 已跑 `git diff --check`，并再次用 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` 复验；构建、测试与 leak check 全部通过 |

## 2026-05-16 DispatchApi RISCVV And AVX512 Empty Finally Cleanup

### Goal

继续沿 `dispatchapi.testcase` 的高确定性清理线推进到 `9358..10471`，只收掉 5 条 `RISCVV/AVX512` 审计与 parity 测试里的两类确定性冗余：
- `LOldVectorAsm` 只声明和赋值、但从不读取
- outer `try/finally` 的 `finally` 体完全为空

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 RISCVV/AVX512 簇的真实边界 | completed | 已逐段复核 `Test_RISCVV_RegisterSource_Deduplicates_WideRoundingAssignments_And_Keeps_F64x2_Exception`、`Test_AVX512_U32x16_U64x8_MappingAndParity`、`Test_AVX512_U32x16_U64x8_ShiftBoundary_Contracts`、`Test_AVX512_I16x32_I8x64_U8x64_MappingAndParity`、`Test_AVX512_F32x16_F64x8_IEEE754_MappingAndParity`：这 5 条测试都只有 source-shape / mapping / parity 断言，outer `finally` 完全为空，没有任何 backend/table restore；`LOldVectorAsm` 仅做 `IsVectorAsmEnabled` 捕获且后续无读取 |
| 2. 只收这一簇高确定性命中 | completed | 已在上述 5 个 `RISCVV/AVX512` 测试中删除纯空 outer `try/finally`，并删除对应未使用的 `LOldVectorAsm`；所有 source-shape、mapping、capability 与 parity 断言保持不变 |
| 3. 用单 suite release 复验收口 | completed | 已跑 `git diff --check`，并再次用 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` 复验；构建、测试与 leak check 全部通过 |

## 2026-05-16 DispatchApi Capability And AVX2 FMA Empty Finally Cleanup

### Goal

继续沿 `dispatchapi.testcase` 的高确定性清理线推进到 `10549..10944`，只收掉 backend-capability / AVX2-FMA 合同测试里的两类确定性冗余：
- `LOldVectorAsm` 只声明和赋值、但从不读取
- outer `try/finally` 的 `finally` 体完全为空

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 capability/FMA 簇的真实边界 | completed | 已逐段复核 `Test_BackendCapabilities_DoNotUnderclaim_Shuffle`、`Test_X86_BackendCapabilities_DoNotUnderclaim_MaskedOps`、`Test_BackendCapabilities_Clear_IntegerOps_When_VectorAsmDisabled`、`Test_X86_BackendCapabilities_Keep_IntegerOps_When_AlwaysOn_NarrowSlots_Remain_NonScalar`、`Test_X86_BackendCapabilities_Keep_MaskedOps_When_VectorAsmDisabled`、`Test_AVX2_BackendCapabilities_Expose_FMA_When_FusedPathUsable`、`Test_AVX2_BackendCapabilities_Clear_FMA_When_VectorAsmDisabled`、`Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_AVX2FMA_When_FusedPathUsable`：这 8 条测试都只做 capability/FMA 合同断言，outer `finally` 完全为空，没有任何 backend/table restore；`LOldVectorAsm` 仅做 `IsVectorAsmEnabled` 捕获且后续无读取 |
| 2. 只收这一簇高确定性命中 | completed | 已在上述 8 个 capability/FMA 测试中删除纯空 outer `try/finally`，并删除对应未使用的 `LOldVectorAsm`；所有 capability、FMA witness、public ABI 能力位与 vector-asm disable 合同断言保持不变 |
| 3. 用单 suite release 复验收口 | completed | 已跑 `git diff --check`，并再次用 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` 复验；构建、测试与 leak check 全部通过 |

## 2026-05-16 DispatchApi WideFma WideSelect And BackendCapability Empty Finally Cleanup

### Goal

继续沿 `dispatchapi.testcase` 的高确定性清理线推进到 `10946..11435`，只收掉 AVX2 wide-FMA/source-shape、AVX2 wide-select parity、`X86MaskedFmaContract`、`RISCVVMaskedOpsContract` 与 `AVX512` capability 合同测试里的两类确定性冗余：
- `LOldVectorAsm` 只声明和赋值、但从不读取
- outer `try/finally` 的 `finally` 体完全为空

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 wide/source-shape 与 capability 合同簇的真实边界 | completed | 已逐段复核 `Test_AVX2_WideFma_ExactInputs_FollowsHalfComposition`、`Test_AVX2_WideSelect_Parity_WithScalar_When_VectorAsmEnabled`、`TTestCase_X86MaskedFmaContract.Test_AVX2_FmaSlots_StayScalar_When_HardwareFmaUnavailable`、`TTestCase_RISCVVMaskedOpsContract.Test_RISCVV_BackendCapabilities_Expose_MaskedOps_When_MaskSlots_AreNative`、`TTestCase_RISCVVMaskedOpsContract.Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_RISCVVMaskedOps_When_MaskSlots_AreNative`、`Test_AVX512_BackendCapabilities_Expose_FMA_When_WideFmaSlots_AreNative`、`Test_AVX512_BackendCapabilities_Expose_Shuffle_When_WideSelectSlots_AreNative`、`Test_AVX512_BackendCapabilities_Clear_VectorAsmGatedBits_When_VectorAsmDisabled`：这 8 条测试的 outer `finally` 都完全为空，没有任何 backend/table restore；source-shape 相关真实释放只在内层 `LSourceLines.Free` 承担；`LOldVectorAsm` 仅做 `IsVectorAsmEnabled` 捕获且后续无读取 |
| 2. 只收这一簇高确定性命中 | completed | 已在上述 8 个测试中删除纯空 outer `try/finally`，并删除对应未使用的 `LOldVectorAsm`；所有 wide-FMA half composition、wide-select parity、hardware-FMA absence、RISCVV masked-ops 与 AVX512 capability 断言保持不变 |
| 3. 用单 suite release 复验收口 | completed | 已跑 `git diff --check`，并再次用 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` 复验；构建、测试与 leak check 全部通过 |

## 2026-05-16 DispatchApi Neon Riscvv And AVX2 Shuffle Capability Empty Finally Cleanup

### Goal

继续沿 `dispatchapi.testcase` 的高确定性清理线推进到 `11485..11825`，只收掉 `NEON` / `RISCVV` backend-capability、`AVX2` shuffle capability 与 public-ABI 合同测试里的两类确定性冗余：
- `LOldVectorAsm` 只声明和赋值、但从不读取
- outer `try/finally` 的 `finally` 体完全为空

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `NEON/RISCVV/AVX2 shuffle` 合同簇的真实边界 | completed | 已逐段复核 `Test_NEON_BackendCapabilities_Clear_VectorAsmGatedBits_When_VectorAsmDisabled`、`Test_RISCVV_BackendCapabilities_Expose_IntegerOps_When_IntegerSlots_AreNative`、`Test_RISCVV_BackendCapabilities_Expose_FMA_When_FmaSlots_AreNonScalar`、`Test_RISCVV_BackendCapabilities_Expose_Shuffle_When_RepresentativeSlots_AreNonScalar`、`Test_RISCVV_BackendCapabilities_Clear_VectorAsmGatedBits_When_VectorAsmDisabled`、`Test_AVX2_BackendCapabilities_Expose_Shuffle_When_NativeShuffleSlotsUsable`、`Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_AVX2Shuffle_When_NativeShuffleSlotsUsable`、`Test_AVX2_BackendCapabilities_Clear_Shuffle_When_VectorAsmDisabled`、`Test_PublicApi_BackendPodInfo_CapabilityBits_Clear_AVX2VectorAsmGatedBits_When_VectorAsmDisabled`：这 9 条测试都只做 `SetVectorAsmEnabled(True/False)`、backend/public-ABI 信息读取与 capability/slot 合同断言，outer `finally` 完全为空，没有任何 backend/table restore；`LOldVectorAsm` 仅做 `IsVectorAsmEnabled` 捕获且后续无读取 |
| 2. 只收这一簇高确定性命中 | completed | 已在上述 9 个 `NEON/RISCVV/AVX2 shuffle` 合同测试中删除纯空 outer `try/finally`，并删除对应未使用的 `LOldVectorAsm`；所有 vector-asm disable、capability、slot fallback 与 public ABI 位断言保持不变 |
| 3. 用单 suite release 复验收口 | completed | 已跑 `git diff --check`，并再次用 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` 复验；构建、测试与 leak check 全部通过 |

## 2026-05-16 DispatchApi X86 Override Reuse And Semantic Parity Empty Finally Cleanup

### Goal

继续沿 `dispatchapi.testcase` 的高确定性清理线推进到 `11960..12580`，只收掉 `SSSE3/SSE41/SSE42` override-reuse 审计和 `SSE3/SSSE3/SSE41/SSE42` runtime semantic parity 测试里的两类确定性冗余：
- `LOldVectorAsm` 只声明和赋值、但从不读取
- outer `try/finally` 的 `finally` 体完全为空

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 x86 override reuse / semantic parity 簇的真实边界 | completed | 已逐段复核 `Test_SSSE3_RepresentativeOverrides_Reuse_SSE3_CoreSlots`、`Test_SSE41_RepresentativeOverrides_Reuse_SSSE3_CoreSlots`、`Test_SSE42_RepresentativeOverride_Reuse_SSE41_CoreSlots`、`Test_SSE3_RepresentativeSemanticParity_WithScalar_IfDispatchable`、`Test_SSSE3_RepresentativeSemanticParity_WithScalar_IfDispatchable`、`Test_SSE41_RepresentativeSemanticParity_WithScalar_IfDispatchable`、`Test_SSE42_RepresentativeSemanticParity_WithScalar_IfDispatchable`：前 3 条测试的 source-shape 资源释放仍只由内层 `LSourceLines.Free` 承担；7 条测试的 outer `finally` 全都为空，没有任何 backend/table restore；`LOldVectorAsm` 仅做 `IsVectorAsmEnabled` 捕获且后续无读取 |
| 2. 只收这一簇高确定性命中 | completed | 已在上述 7 个 x86 override-reuse / semantic parity 测试中删除纯空 outer `try/finally`，并删除对应未使用的 `LOldVectorAsm`；所有 cloned-slot/source-shape、dispatchable parity 与 backend/slot 断言保持不变 |
| 3. 用单 suite release 复验收口 | completed | 已跑 `git diff --check`，并再次用 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` 复验；构建、测试与 leak check 全部通过 |

## 2026-05-16 DispatchApi AVX512 PassThrough And X86 Shuffle Capability Empty Finally Cleanup

### Goal

继续沿 `dispatchapi.testcase` 的高确定性清理线推进到 `12548..12692`，只收掉 `AVX512` pass-through facade/source-shape 审计与 `x86 shuffle capability clear` 合同测试里的两类确定性冗余：
- `LOldVectorAsm` 只声明和赋值、但从不读取
- outer `try/finally` 的 `finally` 体完全为空

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 AVX512 pass-through / x86 shuffle capability 簇的真实边界 | completed | 已逐段复核 `Test_AVX512_PassThroughFacadeSlots_Reuse_AVX2_When_Wrappers_Are_Just_Forwarders`、`Test_X86_BackendCapabilities_Clear_Shuffle_When_VectorAsmDisabled`：前者的 source-shape 资源释放仍只由内层 `LSourceLines.Free` 承担，后者只做 capability rebuild 断言；2 条测试的 outer `finally` 都为空，没有任何 backend/table restore；`LOldVectorAsm` 仅做 `IsVectorAsmEnabled` 捕获且后续无读取 |
| 2. 只收这一簇高确定性命中 | completed | 已在上述 2 个 AVX512/x86 合同测试中删除纯空 outer `try/finally`，并删除对应未使用的 `LOldVectorAsm`；所有 pass-through wrapper/source-shape、cloned-slot 复用与 x86 shuffle capability clear 断言保持不变 |
| 3. 用单 suite release 复验收口 | completed | 已跑 `git diff --check`，并再次用 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` 复验；构建、测试与 leak check 全部通过 |

## 2026-05-16 DispatchApi NonX86 Wide Slot Contract Empty Finally Cleanup

### Goal

继续沿 `dispatchapi.testcase` 的高确定性清理线推进到 `12945..13340`，只收掉 `non-x86 wide slot` 合同测试里的两类确定性冗余：
- `LOldVectorAsm` 只声明和赋值、但从不读取
- outer `try/finally` 的 `finally` 体完全为空

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 non-x86 wide-slot 合同簇的真实边界 | completed | 已逐段复核 `Test_NonX86_NativeWideFloorCeil_Slots_NotScalar_IfAvailable`、`TTestCase_NonX86BackendParity.Test_NativeWideFloorCeilSlots_NotScalar_IfAvailable`：两条测试都只做 `SetVectorAsmEnabled(True)`、backend 注册可达性筛选、wide slot 合同断言与 `LCheckedBackends` 统计；outer `finally` 完全为空，没有任何 backend/table restore；`LOldVectorAsm` 仅做 `IsVectorAsmEnabled` 捕获且后续无读取 |
| 2. 只收这一簇高确定性命中 | completed | 已在上述 2 个 non-x86 wide-slot 合同测试中删除纯空 outer `try/finally`，并删除对应未使用的 `LOldVectorAsm`；所有 slot-not-scalar / NEON scalar-reuse 例外断言与 `LCheckedBackends` 逻辑保持不变 |
| 3. 用单 suite release 复验收口 | completed | 已跑 `git diff --check`，并再次用 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` 复验；构建、测试与 leak check 全部通过 |

## 2026-05-16 NonX86 Runtime Parity Empty Finally Cleanup

### Goal

继续沿 non-x86 runtime parity 合同测试推进到 `13343..14054`，只收掉这 3 条测试里的两类确定性冗余：
- `LOldVectorAsm` 只声明和赋值、但从不读取
- outer `try/finally` 的 `finally` 体完全为空

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 non-x86 runtime parity 簇的真实边界 | completed | 已逐段复核 `TTestCase_NonX86BackendParity.Test_NativeNarrowFloatCoreParity_WithVectorAsm_IfAvailable`、`TTestCase_NonX86BackendParity.Test_NativeNarrowHelperSurfaceParity_WithVectorAsm_IfAvailable`、`TTestCase_NonX86BackendParity.Test_NativeWideLoadAndZeroParity_WithVectorAsm_IfAvailable`：3 条测试都只做 `SetVectorAsmEnabled(True)`、backend 注册/激活筛选、dispatch-table 与 facade parity 断言，以及 `LCheckedBackends` 统计；outer `finally` 完全为空，没有任何 backend/table restore；`LOldVectorAsm` 仅做 `IsVectorAsmEnabled` 捕获且后续无读取 |
| 2. 只收这一簇高确定性命中 | completed | 已在上述 3 个 non-x86 runtime parity 测试中删除纯空 outer `try/finally`，并删除对应未使用的 `LOldVectorAsm`；所有 dispatch-table / facade parity、slot-native 断言与 `LCheckedBackends` 逻辑保持不变 |
| 3. 用单 suite release 复验收口 | completed | 已跑 `git diff --check`，并再次用 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` 复验；构建、测试与 leak check 全部通过 |

## 2026-05-16 NonX86 Wide Splat Dot Reduce Normalize Empty Finally Cleanup

### Goal

继续沿 `TTestCase_NonX86BackendParity` 的高确定性清理线推进到 `14232..14865`，只收掉这 4 条测试里的两类确定性冗余：
- `LOldVectorAsm` 只声明和赋值、但从不读取
- outer `try/finally` 的 `finally` 体完全为空

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `14232..14865` 候选簇的真实边界 | completed | 已逐段复核 `TTestCase_NonX86BackendParity.Test_NativeWideSplatParity_WithVectorAsm_IfAvailable`、`TTestCase_NonX86BackendParity.Test_NativeF64DotParity_WithVectorAsm_IfAvailable`、`TTestCase_NonX86BackendParity.Test_NativeF64ReduceAddSeedParity_WithVectorAsm_IfAvailable`、`TTestCase_NonX86BackendParity.Test_NativeNormalizeEdgeParity_WithVectorAsm_IfAvailable`：4 条测试都只做 `SetVectorAsmEnabled(True)`、backend 注册/激活筛选、dispatch-table 与 facade parity 或 slot 断言，以及 `LCheckedBackends` 统计；outer `finally` 完全为空，没有任何 backend/table restore；`LOldVectorAsm` 仅做 `IsVectorAsmEnabled` 捕获且后续无读取。相邻 `Test_NativeVectorMathParity_WithVectorAsm_IfAvailable` 的 `finally` 非空，`14056..14230` 的 `FreeAligned(...)` 真实清理也已继续排除 |
| 2. 只收这一簇高确定性命中 | completed | 已在上述 4 个 non-x86 parity 测试中删除纯空 outer `try/finally`，并删除对应未使用的 `LOldVectorAsm`；所有 splat/dot/reduce/normalize 断言、NEON scalar-reuse 例外与 `LCheckedBackends` 逻辑保持不变 |
| 3. 用单 suite release 复验收口 | completed | 已跑 `git diff --check`，并再次用 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` 复验；构建、测试与 leak check 全部通过 |

## 2026-05-16 NonX86 Helper And Core Parity Empty Finally Cleanup

### Goal

继续沿 `TTestCase_NonX86BackendParity` 的高确定性清理线推进到 `14847..16921`，一次性收掉这段连续 helper/core parity 测试里的两类确定性冗余：
- `LOldVectorAsm` 只声明和赋值、但从不读取
- outer `try/finally` 的 `finally` 体完全为空

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `14847..16921` 连续候选簇的真实边界 | completed | 已逐段复核 12 条连续方法：`Test_NativeWideInsertHelperParity_WithVectorAsm_IfAvailable`、`Test_NativeWideIntegerExtractEdgeParity_WithVectorAsm_IfAvailable`、`Test_NativeNarrowFloatHelperParity_WithVectorAsm_IfAvailable`、`Test_NativeNarrowIntegerCoreParity_WithVectorAsm_IfAvailable`、`Test_NativeNarrowIntegerHelperParity_WithVectorAsm_IfAvailable`、`Test_MinimalDispatchParity_IfAvailable`、`Test_ExtendedFloatParity_IfAvailable`、`Test_NarrowAndNotParity_IfAvailable`、`Test_DotParity_IfAvailable`、`Test_I16x32_CoreParity_IfAvailable`、`Test_I8x64_CoreParity_IfAvailable`、`Test_U32x16_U64x8_CoreParity_IfAvailable`；前 5 条同时带未读取 `LOldVectorAsm` 和空 outer `finally`，后 7 条只带空 outer `finally`。这 12 条都只做 backend 注册/激活筛选、dispatch-table/facade parity 与 slot 断言，没有任何 backend/table restore、hook cleanup 或资源释放；当前批次明确停在 `16923+` 之前，不把 `WideInteger_FuzzSeed` 及后续长段带进来 |
| 2. 只收这一簇高确定性命中 | completed | 已在上述 12 个 non-x86 helper/core parity 测试中删除纯空 outer `try/finally`；其中前 5 条同步删除未使用 `LOldVectorAsm`。所有 helper/core parity、lane/mask/shift 断言与 `LChecked/LCheckedBackends` 逻辑保持不变 |
| 3. 用单 suite release 复验收口 | completed | 已跑 `git diff --check`，并再次用 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` 复验；构建、测试与 leak check 全部通过 |

## 2026-05-16 NonX86 Mask And Shift Empty Finally Cleanup

### Goal

继续沿 `TTestCase_NonX86BackendParity` 的高确定性清理线推进到 `17092..19067`，只收掉这 4 条 mask/shift/minmax 测试里的纯空 outer `finally`，同时明确跳过带真实 `RandSeed` restore 的 fuzz 段：
- `Test_WideCompareMaskParity_IfAvailable`
- `Test_I32x4_BitwiseShiftParity_IfAvailable`
- `Test_WideSignedBitwiseShiftParity_IfAvailable`
- `Test_WideIntegerArithmeticMinMaxParity_IfAvailable`

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `17092..19067` 候选簇的真实边界 | completed | 已逐段复核 `Test_WideInteger_FuzzSeed_Parity_IfAvailable` 到 `Test_WideIntegerArithmeticMinMaxParity_IfAvailable`：`WideInteger_FuzzSeed` 的 `finally` 会恢复 `RandSeed`，属于真实状态清理，必须跳过；其后的 `WideCompareMaskParity`、`I32x4_BitwiseShiftParity`、`WideSignedBitwiseShiftParity`、`WideIntegerArithmeticMinMaxParity` 都只做 backend 注册/激活筛选、compare/mask/shift/minmax parity 与 facade/helper 断言，outer `finally` 完全为空，没有任何 restore、hook cleanup 或资源释放 |
| 2. 只收这一簇高确定性命中 | completed | 已在 `WideCompareMaskParity`、`I32x4_BitwiseShiftParity`、`WideSignedBitwiseShiftParity`、`WideIntegerArithmeticMinMaxParity` 中删除纯空 outer `try/finally`；同时补回 `WideInteger_FuzzSeed` 包裹 `RandSeed` restore 的真实 outer `try`，保留所有 compare/mask helper、exact shift probe、lane contract 与 arithmetic/minmax 断言不变 |
| 3. 用单 suite release 复验收口 | completed | `git diff --check` 已通过；`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` 已绿，结果为 `[BUILD] OK`、`[TEST] OK`、`[LEAK] OK` |

## 2026-05-16 Completion Audit Reset

### Goal

停止继续机械扫描 `dispatchapi.testcase` 的空壳 `finally`，切回真正决定 `freeze-status` 的 closeout/evidence 路径，只做小闭环、高确定性的收口动作。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 对齐当前真实 stop-point | completed | 已确认 `dispatchapi.testcase` 最后一批 `17092..19067` 已收口，`WideInteger_FuzzSeed` 的真实 `RandSeed` restore 已保住；继续沿这条线机械删空壳的价值已经很低 |
| 2. 回写当前 completion-audit 真状态 | completed | 已确认这轮真实绿态是：`git diff --check`、Release `TTestCase_DispatchAPI`、`check_nonx86_register_truthfulness.py --backend neon/riscvv --strict`、`check_nonx86_key_slot_audit.py`、`check_nonx86_helper_semantics.py`、`check_nonx86_wiring_sync.py`、Release `check`；当前真实红态来自 `freeze-status` |
| 3. 串行验证本地可推进 blocker | completed | `qemu-cpuinfo-nonx86-evidence` 已验证：未提权时失败于 Docker socket 权限；提权后 `linux/arm/v7`、`linux/arm64`、`linux/riscv64` 全平台 PASS。随后按 `freeze-status` next-action 重跑 canonical `gate`，Linux mainline-required steps 已全部转绿 |
| 4. 复核 Windows evidence 是否仍为外部阻塞 | completed | `win-evidence-preflight` 当前返回 `STATUS=PASS CODE=OK EXIT=0`，说明 workflow 入口本身当前可用；`freeze-status` 现只剩旧 `windows_b07_gate.log` freshness / verify / closeout freshness 红态 |
| 5. 清理工作树并重试 GH Windows evidence | completed | 已清掉 `__pycache__`、提交并推送 `731cc0d7`，随后成功 dispatch `win-evidence-via-gh SIMD-20260516-152`；run id=`25967172435` |
| 6. 确认最终外部阻塞并收口 | completed | 远端 workflow 已给出最终结论：`25967172435` 在 `Prepare Windows SIMD Source` 阶段即失败，原因是 `recent account payments have failed or your spending limit needs to be increased`；当前剩余 blocker 已确定为 GitHub Actions billing/runner 外部问题，而不是本地 SIMD 实现、gate 或脚本逻辑 |

## 2026-05-17 Closeout Doc Truth-Sync

### Goal

继续加强 SIMD 审查时，不再重开实现层泛审查，而是修掉 active closeout/checklist 文档里对 QEMU 证据链的混写和 stop-point 漂移，避免后续会话继续误判 `freeze-status` 红点。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核脚本真行为与 active docs 漂移 | completed | 已确认 `closeout-host-local` / `gate-strict` 仍主要消费 `qemu-nonx86-evidence`，而 canonical `gate` / `freeze-status` / `win-closeout-finalize` 另外要求 `qemu-cpuinfo-nonx86-evidence`；`docs/fafafa.core.simd.closeout.md` / `docs/fafafa.core.simd.checklist.md` 仍把两者混写 |
| 2. 修正文档真相源 | completed | 已同步 `docs/fafafa.core.simd.closeout.md`、`docs/fafafa.core.simd.checklist.md`、`docs/fafafa.core.simd.implementation-matrix.md`：明确 host-local runtime evidence 与 CPUInfo cross evidence 的双轨语义，并把 Windows blocker 更新为 GH run `25967172435` 的 billing/spending-limit 失败 |
| 3. 最小验证并准备提交 | in_progress | `git diff --check` 已通过；active 文档关键事实已用 `rg` 复核到位。下一步给出简短 review 结论后提交这一批 docs truth-sync |

## 2026-05-17 SSE2 Transitional Non-x86 Fail-Close

### Goal

继续沿 `SSE2 transitional debt` 收口一个真实契约问题：禁止 `src/fafafa.core.simd.intrinsics.sse2.pas` 在 non-x86 + `FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS` 下把 placeholder body 误当成可执行语义。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核实验测试与文档契约 | completed | 已确认现有 `experimental` 测试只约束 `x86_64` 路径；non-x86 分支没有任何 runtime 语义证据，当前 placeholder body 只会误导 bring-up |
| 2. 收口 non-x86 runtime 边界 | completed | `intrinsics.sse2` 现已在 initialization 里对 non-x86 experimental 运行期 fail-close，并把源码注释、disposition 与 migration map 同步到“compile scaffolding only” |
| 3. 最小验证与收口 | completed | `git diff --check`、`check_sse2_structure.py --summary-line`、`tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test`、`FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=1 ... BuildOrTest.sh test` 全部通过 |

## 2026-05-17 AVX Hold-Lane Truth Sync

### Goal

继续沿 experimental intrinsics 的高确定性边界收口 `AVX`：修掉“internal bridge for AVX2-focused tests”的陈旧口径，并禁止 non-x86 experimental runtime 静默执行 placeholder 语义。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核真实 consumer 与验证 lane | completed | 已确认 `intrinsics.avx` 当前没有任何仓库内 consumer，只有 `check_avx_backend_smoke` 与 `experimental-intrinsics` isolation；family matrix 旧行把 lane 写窄了 |
| 2. 收口源码与文档真相 | completed | `intrinsics.avx` 现已在 initialization 里对 non-x86 experimental 运行期 fail-close；源文件头、disposition 与 family matrix 已同步到“hold family / no current bridge consumer / check_avx_backend_smoke” |
| 3. 最小验证与收口 | completed | `git diff --check`、关键 `rg` 复核、`tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test`、`FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=1 ... BuildOrTest.sh test` 全部通过 |

## 2026-05-17 X86 Experimental Lane Fail-Close Batch

### Goal

把 `SSE3/SSE4.1/SSE4.2/AVX-512/FMA3` 这批仍允许 non-x86 experimental runtime 静默执行的 x86-only intrinsics 单元一起收正，并让 `check_intrinsics_experimental_status.py` 对这条边界 fail-close。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核同类命中是否成批存在 | completed | 已确认 `sse3/sse41/sse42/avx512/fma3` 当前都只有 `EnsureExperimentalIntrinsicsEnabled`，无 x86-target runtime guard；现有 verification lane 也都仍是 x86 smoke / representative parity / isolation |
| 2. 源码 + docs + checker 一起收口 | completed | 这 5 个单元现已全部补上 non-x86 fail-close；`docs/SIMD_INTRINSICS_DISPOSITION.md` 与 `check_intrinsics_experimental_status.py` 已同步成静态护栏 |
| 3. 最小验证与收口 | completed | `git diff --check`、`check_intrinsics_experimental_status.py --summary-line`、`tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test`、`FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=1 ... BuildOrTest.sh test` 全部通过 |

## 2026-05-17 AES SHA Hold-Lane Truth Sync

### Goal

把 `AES/SHA` 这类 hold family 的 active docs 从 “experimental-intrinsics isolation only” 收正到当前真实口径：它们还有 default-reject + placeholder semantics 的实验测试 lane，但这仍然不是 stable contract。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 active docs 与实验测试真相 | completed | 已确认 family matrix / disposition 仍把 `AES/SHA` 写得过窄，但 `TTestCase_SimdIntrinsicsExperimental` 已明确覆盖 default reject 与 opt-in placeholder semantics |
| 2. 文档真相同步 | completed | `SIMD_INTRINSICS_DISPOSITION.md`、`simd-family-matrix.md`、`simd-experimental-hold-future-trigger-plan.md` 已同步到当前真实 lane；`git diff --check` 与关键 `rg` 复核通过 |

## 2026-05-17 SVE SVE2 LASX Hold-Family Runtime Fail-Close

### Goal

继续沿 hold-family 小闭环收口 `SVE/SVE2/LASX` 的运行期资格问题：避免它们在非目标主机或明显不具备 base 资格的主机上，仅因打开 `FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS` 就静默装载 placeholder semantics。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 `cpuinfo` 能力面与当前 runtime guard 缺口 | completed | 已确认仓库已有 `ARM.HasSVE` 检测但没有 `HasSVE` quick helper；`SVE/SVE2/LASX` 当前都只看 experimental define，没有 target-specific runtime fail-close |
| 2. 收紧源码与验证脚本 | completed | 已补 `cpuinfo.HasSVE`，并把 `intrinsics.sve/sve2/lasx` 收紧为 target-specific runtime fail-close；`BuildOrTest.sh` 现已新增 3 个 non-qualified-host runtime reject smoke；`check_intrinsics_experimental_status.py` 也已升格这条边界 |
| 3. 文档和 scratch 真相同步 | completed | `SIMD_INTRINSICS_DISPOSITION.md`、`simd-family-matrix.md`、`simd-experimental-hold-future-trigger-plan.md` 与 scratch 记录已同步到 “hold family + runtime fail-close” 口径 |
| 4. 最小验证与收口 | completed | `git diff --check`、`check_intrinsics_experimental_status.py --summary-line`、默认/experimental 两轮 `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test` 全部通过；在当前 `x86_64` 主机上 `SVE/SVE2/LASX` runtime reject smoke 均为绿 |

## 2026-05-17 LASX Cpuinfo Feature-Level Qualification

### Goal

继续沿 `LASX` 这条最小残余收口，把 `intrinsics.lasx` 从“只按 `LoongArch64` 主机级放行”收紧到“只有 `cpuinfo` 报告 `LASX` 才放行”，同时不打开 stable backend 路线。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核最小可行面 | completed | 已确认可以只补 `SIMD_LOONGARCH_AVAILABLE + cpuinfo.loongarch + HasLASX`，不需要引入 stable backend / dispatch 新路径 |
| 2. 落地最小 cpuinfo 链 | completed | 已新增 `cpuinfo.loongarch` 最小骨架，并把 eager/lazy/diagnostic 以及 `intrinsics.lasx` runtime guard 接到 `HasLASX` |
| 3. 测试与 closeout 护栏同步 | completed | 已同步 `cpuinfo` 测试、experimental checker/smoke、`closeout` 文档护栏与 active docs |
| 4. 最小验证与收口 | completed | `git diff --check`、`check_intrinsics_experimental_status.py --summary-line`、默认/experimental 两轮 `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test`、`tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh test`、`tests/fafafa.core.simd/BuildOrTest.sh check` 已通过 |

## 2026-05-17 NEON RVV Qualification-Leaf Runtime Fail-Close

### Goal

继续加强 intrinsics 审查，但不混入 stable adapter qualification：只把 `intrinsics.neon` / `intrinsics.rvv` 这两个 experimental leaf 的 runtime 资格收紧到对应 ISA 主机，避免在非合格主机上因 experimental define 而静默装载。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核 leaf 现状与验证缺口 | completed | 已确认 `intrinsics.neon/rvv` 目前只有 generic experimental guard，没有 target-specific runtime qualification；`BuildOrTest.sh` 也没有 dedicated reject smoke |
| 2. 收紧源码与验证脚本 | completed | `intrinsics.neon` 现已要求 `HasNEON`，`intrinsics.rvv` 现已要求 `HasRISCVV`；`BuildOrTest.sh` 与 `check_intrinsics_experimental_status.py` 已新增 qualification-family runtime fail-close 覆盖 |
| 3. 文档和 scratch 真相同步 | completed | `SIMD_INTRINSICS_DISPOSITION.md` 与 `simd-family-matrix.md` 已同步到 “qualification family 仍不 promote，但 leaf runtime 不再 any-host opt-in” 口径 |
| 4. 最小验证与收口 | completed | `git diff --check`、`check_intrinsics_experimental_status.py --summary-line`、默认/experimental 两轮 `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test` 全部通过；当前 `x86_64` 主机上的 `NEON/RVV` runtime reject smoke 已 fresh 变绿 |

## 2026-05-17 SVE2 Exact Runtime Qualification

### Goal

继续收口一个已知 residual：把 `intrinsics.sve2` 从“借用 base-`SVE` 资格”的近似状态，升级成真正要求 `SVE2` 能力的 runtime qualification。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核仓库与本机头文件证据 | completed | 已确认仓库当前只有 `HasSVE`、没有 `HasSVE2`；本机 Linux 头文件存在 `HWCAP2_SVE2` 定义，因此这条能力位可直接建模 |
| 2. 补 `cpuinfo` 与 `intrinsics.sve2` | completed | 已为 `TARMFeatures`/`cpuinfo.arm`/`cpuinfo.pas` 补 `HasSVE2`，并把 `intrinsics.sve2` runtime guard 从 `HasSVE` 收紧到 `HasSVE2` |
| 3. 同步 checker / smoke / docs | completed | `check_intrinsics_experimental_status.py`、`BuildOrTest.sh` 与 active docs 已同步到 `SVE2` 精确资格口径；非 `AArch64` 主机上的 reject smoke 允许观察到依赖 `intrinsics.sve` 的上游 fail-close token |
| 4. 最小验证与收口 | completed | `git diff --check`、`check_intrinsics_experimental_status.py --summary-line`、默认/experimental 两轮 `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test` 全部通过；`SVE2` reject smoke 已恢复为绿 |

## 2026-05-17 Experimental X86 Header Truth Sync And Python Cache Hygiene

### Goal

停止“大扫除式泛查”，只收一个最小真问题：把 `sse3/sse41/sse42/avx512/fma3` 这些 experimental x86 intrinsics 单元的源码头口径收正到当前 disposition/runtime 真相，同时消掉 Python checker 反复制造的 worktree 噪音。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核是否存在真漂移 | completed | 已确认这 5 个单元在实现层早就有 experimental + non-x86 fail-close 护栏，但源码头没有像 `intrinsics.avx` 那样显式写出当前 contract；另外 `.gitignore` 仍未忽略 `__pycache__/`，当前 worktree 已出现 `tests/fafafa.core.simd/__pycache__/` 噪音 |
| 2. 最小源码/仓库卫生收口 | completed | 这 5 个 x86 intrinsics 单元已补统一 experimental status 说明；`.gitignore` 已补 `__pycache__/` 规则，避免 Python checker 再把 status 弄脏 |
| 3. 验证与 closeout | completed | `git diff --check`、`check_intrinsics_experimental_status.py --summary-line`、默认/experimental 两轮 `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test` 已通过；`comment_swallow` hygiene 与 x86/hold-family smoke 全绿 |

## 2026-05-17 SIMD Generated Artifact Hygiene Cleanup

### Goal

清理 `tests/fafafa.core.simd/` 下误入版本库的生成产物，避免 core dump、smoke 编译输出和无扩展名 ELF 测试二进制继续污染 SIMD 审查面，并补足对应 ignore 护栏。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核哪些文件是误跟踪的生成产物 | completed | 已确认 `simd_test` 是 x86_64 ELF 可执行文件，`qemu_fafafa.core.simd.test_20260220-232704_195.core` 是 9.3M AArch64 core dump，`bin2-smoke/link60.res` 与 `bin2-smoke/ppas.sh` 是 `rvv_opcode_smoke` 编译生成物；`rg` 未发现真实源码/脚本依赖它们 |
| 2. 删除误入版本库的产物并补 ignore | completed | 已删除上述 4 个 tracked artifacts，并在 `tests/fafafa.core.simd/.gitignore` 补 `/bin2-smoke/`、`/simd_test`、`/*.core`，把这类 SIMD 生成产物收进仓库卫生护栏 |
| 3. 最小验证与收口 | completed | `git diff --check` 通过；`git check-ignore -v --no-index` 已命中 `/bin2-smoke/`、`/simd_test`、`/*.core`；`check_simd_source_reachability.py --summary-line` 与 `check_intrinsics_experimental_status.py --summary-line` 继续为绿 |

## 2026-05-17 Register Truthfulness Gate Promotion

### Goal

把 `check_nonx86_register_truthfulness.py` 从“依赖 `SIMD_ENABLE_*` 的可选 lane”收正为默认静态门禁，因为它本身不需要 opt-in backend 编译，却能直接守住 non-x86 register ownership truth。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核当前 gap 是否真实存在 | completed | 已确认 `BuildOrTest.sh check` 当前仍输出 `[REG-TRUTH] SKIP (enable SIMD_ENABLE_NEON_BACKEND=1 or SIMD_ENABLE_RISCVV_BACKEND=1)`；但直接运行 `check_nonx86_register_truthfulness.py --backend neon/riscvv --summary-line --strict` 都能稳定通过，说明这是门禁覆盖缺口，不是编译前置条件 |
| 2. shell/batch runner 收口 | completed | 已把 shell/batch 的 `register_truthfulness_check` 改成无条件同时审 `neon` + `riscvv`，并把 `gate` 中对应步骤从 opt-in skip 改成默认执行 |
| 3. release 验证与收口 | completed | `git diff --check`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate` 已通过；默认 `check` 与 `gate` 中的 `REG-TRUTH` 现在都会真实执行 `neon+riscvv` 两条静态 truth 审查 |

## 2026-05-17 Metadata Query Scope Guard

### Goal

把 `GetBackendInfo` / `TryGetRegisteredBackendDispatchTable` / backend text getters 的使用边界也拉进默认门禁，防止 `dispatch-read-scope` 之外又悄悄长出第二条 metadata truth path。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核当前是否存在护栏缺口 | completed | 已确认当前只有 `dispatch-read-scope` 守 `GetDispatchTable`；production 源里虽然 `GetBackendInfo` / `TryGetRegisteredBackendDispatchTable` 还只停留在 `dispatch/runtime/public ABI/backend adapter` 这些内部面，但默认 `check` 没有任何 checker 固化这条边界 |
| 2. 新 checker + runner 收口 | completed | 已新增 `check_metadata_query_scope.py`，静态扫描 `src/fafafa.core.simd*.pas/inc` 中 4 个 metadata-query helpers 的调用面；并把 `metadata-query-scope` action 接进 shell/batch runner 与默认 `check` 主链 |
| 3. release 验证与收口 | completed | `git diff --check`、`python3 tests/fafafa.core.simd/check_metadata_query_scope.py --summary-line`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check` 已通过；新 checker 在 release `check` 中真实执行并返回 `forbidden_hits=0` |

## 2026-05-17 Dataplane Consumer Scope Guard

### Goal

把 `GetCurrentSimdDataPlane` / `GetCurrentSimdDataPlaneDispatch` / `RebindSimdDataPlane` 这组 publication-consumer helper 的 production 使用边界也固化进默认门禁，防止 `dataplane` seam 之外悄悄长出第二条 dataplane consumer path。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核当前是否存在护栏缺口 | completed | 已确认 production 命中面当前仍干净：`GetCurrentSimdDataPlane` 只在 `dataplane/public_abi.impl/simd.pas`，`GetCurrentSimdDataPlaneDispatch` 只在 `dataplane/public_abi.impl/direct`，`RebindSimdDataPlane` 只在 `dataplane/direct`；但默认 `check` 尚无任何 checker 固化这条边界 |
| 2. checker + shell/batch parity 收口 | completed | 已新增 `check_dataplane_consumer_scope.py`，并补齐 `BuildOrTest.sh` / `buildOrTest.bat` 的 `dataplane-consumer-scope` action、默认 `check` 接线、usage/parity/selfcheck 字符串与 maintenance 说明 |
| 3. release 验证与收口 | completed | `git diff --check`、`python3 tests/fafafa.core.simd/check_dataplane_consumer_scope.py --summary-line`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check` 已通过；新 checker 在 release `check` 中真实执行并返回 `forbidden_hits=0` |

## 2026-05-17 Direct Dispatch Scope Guard

### Goal

把 `GetDirectDispatchTable` 这条 companion fast-path 的 production 使用边界也固化进默认门禁，防止 `api/arrays/ops/direct` 之外再悄悄长出新的 direct fast-path surface。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核当前是否存在护栏缺口 | completed | 已确认 production 命中面当前只落在 `src/fafafa.core.simd.api.pas`、`src/fafafa.core.simd.arrays.pas`、`src/fafafa.core.simd.ops.pas`、`src/fafafa.core.simd.direct.pas`；`RebindDirectDispatch` 则只在 `direct` 自身，没有其他 production caller；但默认 `check` 尚无任何 checker 固化 `GetDirectDispatchTable` 这条边界 |
| 2. checker + shell/batch parity 收口 | completed | 已新增 `check_direct_dispatch_scope.py`，并补齐 `BuildOrTest.sh` / `buildOrTest.bat` 的 `direct-dispatch-scope` action、默认 `check` 接线、usage/parity/selfcheck 字符串与 maintenance 说明 |
| 3. release 验证与收口 | completed | `git diff --check`、`python3 tests/fafafa.core.simd/check_direct_dispatch_scope.py --summary-line`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check` 已通过；新 checker 在 release `check` 中真实执行并返回 `forbidden_hits=0` |

## 2026-05-17 Check Default Wiring-Sync Promotion

### Goal

把 `wiring-sync` 从 `check` 里的 opt-in lane 收正成默认门禁，因为它已经是成熟、纯 Python、低成本的静态对账，不该继续默认漏掉。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核这是不是当前真实缺口 | completed | 已确认 `gate` 默认已包含 `wiring-sync`，真正遗漏的是 shell/batch `check` 仍要求 `SIMD_CHECK_WIRING_SYNC=1`；同时 direct strict run 与开启该变量后的 Release `check` 都已通过，说明不是实验态 lane |
| 2. shell/batch + 活跃文档同步收口 | completed | 已把 shell `check` 改成默认执行 `wiring-sync`、仅在 `SIMD_CHECK_WIRING_SYNC=0` 时跳过；batch 入口和 shell 内部的 batch parity 签名也同步收正，并更新 maintenance/workflow/checklist/scratch 真相 |
| 3. Release 验证与本批收口 | completed | `git diff --check`、strict `check_nonx86_wiring_sync.py`、Release `BuildOrTest.sh check` 已通过；默认 `check` 现在会真实执行 `wiring-sync`，且仍允许用 `SIMD_CHECK_WIRING_SYNC=0` 显式降载 |

## 2026-05-17 Freeze Gate-Summary Fallback

### Goal

收掉 `freeze-status` 的一个 runner/artifact 级真缺口：routine `gate` 会覆盖 `logs/gate_summary.md`，导致较早那份带 `qemu-cpuinfo-nonx86-evidence` 的 closeout gate truth 丢失；需要让 gate summary 在覆盖前自动留档，并让 `freeze-status` 能把这些留档当 fallback candidate。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核这是不是当前真实缺口 | completed | fresh `freeze-status` 已直接显示 latest `gate_summary.md` 里的 `qemu-cpuinfo-nonx86-evidence=SKIP` 会把 `linux_gate_required_steps_mainline` / `cross_gate_required_steps` 打红；而 `evaluate_simd_freeze_status.py` 现有 fallback 只扫 `logs/windows-closeout/<batch>/gate_summary.md`，当前仓库并无这类 batch gate summary 可回退 |
| 2. gate summary 留档 + freeze fallback 收口 | completed | 已让 shell `reset_gate_summary` 在覆盖前自动备份旧 summary 到 `logs/rehearsal/backups/`，并让 `evaluate_simd_freeze_status.py` 把这些 backup 也纳入候选；selection suffix 也从“closeout gate snapshot”收正成更准确的通用“gate snapshot” |
| 3. active docs / scratch 真相同步 | completed | 已把 `closeout.md` / `checklist.md` 里“canonical gate_summary.md 恒等于 closeout truth”的旧说法收正成“latest fast-gate 可能覆盖 canonical，freeze-status 会优先回退到 backup/batch snapshot”的口径，并记录本批 gap/repair |

## 2026-05-17 Linux CPUInfo Evidence Refresh Closeout

### Goal

停止继续泛审查，直接把当前最有价值的 closeout 证据跑完并写回真相源：确认 Linux CPUInfo QEMU cross evidence 已重新补绿，然后把 stop-point 收敛到 Windows evidence 外部阻塞。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 跑完 canonical gate 的 Linux CPUInfo QEMU evidence lane | completed | 已在提权后完成 `FAFAFA_BUILD_MODE=Release SIMD_QEMU_PLATFORMS='linux/arm/v7 linux/arm64 linux/riscv64' SIMD_GATE_QEMU_NONX86_EVIDENCE=0 SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=1 SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE=0 SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_REPEAT=0 SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE=0 SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=0 bash tests/fafafa.core.simd/BuildOrTest.sh gate`；`arm/v7`、`arm64`、`riscv64` 全部 PASS，gate 最终 `OK` |
| 2. 复核 freeze stop-point | completed | `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux` 已是 `ready=True` / `mainline-ready=True`；full `freeze-status` 当前只红在 `cross_gate_required_steps: evidence-verify=SKIP` 与旧 Windows evidence freshness / verify |
| 3. active docs / scratch 回写当前真相 | completed | 已把 `closeout.md`、`checklist.md`、`findings.md`、`progress.md` 更新到 “Linux 绿、Windows blocker 仍在” 的停点，避免下一轮再从 `qemu-cpuinfo-nonx86-evidence=SKIP` 的旧状态重开 |

## 2026-05-17 Freeze Next-Action Billing Fail-Close

### Goal

继续收口一个 runner 级效率问题：当 `win-evidence-preflight` 已经明确返回 `RECENT_BILLING_BLOCK` 时，`freeze-status` 不该再继续推荐 `win-evidence-via-gh`、fail-close gate 和 stale Windows verify 这些注定无效的动作。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核这是不是当前真实缺口 | completed | 已重新运行 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight`，结果为 `STATUS=FAIL CODE=RECENT_BILLING_BLOCK EXIT=31`；旧版 `freeze-status` 仍会继续推荐 `win-evidence-via-gh` / `evidence-win-verify` / fail-close gate，属于误导性 next-actions |
| 2. 收紧 `freeze-status` 的 preflight 感知 | completed | `evaluate_simd_freeze_status.py` 现已读取 `logs/win_preflight_latest.json`，新增 `windows_preflight_latest` 检查项；若 fresh preflight 仍是 `RECENT_BILLING_BLOCK`，next-actions 会收敛到 billing / 手工 Windows runner 路径，不再继续推荐注定失败的 GH evidence / stale verify 命令 |
| 3. 最小验证与真相同步 | completed | `python3 -m py_compile tests/fafafa.core.simd/evaluate_simd_freeze_status.py`、full `freeze-status`、`freeze-status-linux` 已通过预期验证；active docs / scratch 已同步到最新 preflight 真相 |

## 2026-05-17 Implementation Matrix Sync Guard

### Goal

给 active `docs/fafafa.core.simd.implementation-matrix.md` 增加独立 fail-close checker，并把它接进默认 `check`，但规则面只守护当前 active ledger，不把矩阵误判成全量 key-slot 台账。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 复核半成品 checker 的真实失败面 | completed | 首次 `python3 tests/fafafa.core.simd/check_implementation_matrix_sync.py --summary-line` 直接报 `issues=83`；根因不是文档缺 83 行，而是脚本把 `check_nonx86_key_slot_audit.py` 的全量 key-slot 期望错误套到了只记录 active ledger 的 implementation matrix |
| 2. 收窄 checker 到 active ledger 真边界 | completed | `check_implementation_matrix_sync.py` 现显式锁定当前 22 条 non-x86 active rows 和 10 条 x86 bounded-frontier rows；non-x86 只校验这些 active rows 的缺失/多余/contract mismatch，不再要求文档覆盖全量 key-slot |
| 3. 补齐 matrix 自身不在 key-slot audit 内的例外 | completed | `RISCVV.ShiftLeftU32x8` / `ShiftRightU32x8` 仍是 active matrix row，但真相源在 `riscvv.facade.inc`，不在 `key-slot-audit` 的 dispatchapi ledger；checker 已把这两行作为本地 manual contract 收进去 |
| 4. 接线、Release 验证与收口 | completed | 新 checker 已接入 `BuildOrTest.sh check` / `buildOrTest.bat` / active docs；`python3 -m py_compile`、独立 `--summary-line`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`、`git diff --check` 全部通过 |

## 2026-05-17 SIMD Tracked Res Artifact Hygiene

### Goal

继续沿“小闭环”清理 `simd` 子树里仍被 Git 跟踪的 `.res` 生成物，避免后续构建把 Lazarus/FPC 资源二进制继续伪装成源码资产。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 核实 `.res` 是否真是生成物 | completed | 已确认 `git ls-files tests/fafafa.core.simd* | rg '\\.res$'` 只命中 3 个文件；`file` 均为 `Microsoft Visual C binary resource file`，且对应 `fafafa.core.simd.test.lpr` / `test_backend_ops.pas` / `fafafa.core.simd.intrinsics.mmx.test.lpr` 都没有 `{$R *.res}` 源码引用 |
| 2. 收正 ignore 并移出版本库 | completed | `tests/fafafa.core.simd/.gitignore` 已补 `/*.res`；新增 `tests/fafafa.core.simd.intrinsics.mmx/.gitignore`；3 个 tracked `.res` 已从 Git 索引移除，不再作为 repo 资产保留 |
| 3. Release/runner 回归与状态复核 | completed | `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd.intrinsics.mmx/BuildOrTest.sh test`、`git diff --check` 已通过；`fafafa.core.simd.test.res` / `intrinsics.mmx.test.res` 能被正常重建且因 ignore 不再污染状态，`test_backend_ops.res` 删除后主 check 继续通过，证明它不是必需源码资产 |
