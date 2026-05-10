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
| 4. release 验证与提交收口 | in_progress | `check_sse2_structure.py`、`check_intrinsics_experimental_status.py`、`BuildOrTest.sh check`、`BuildOrTest.sh gate` 已通过；剩余是 review + commit |

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
| 4. seam 回归验证与提交收口 | in_progress | `git diff --check`、Release `check`、`TTestCase_DataPlane`、`TTestCase_PublicAbi`、`TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework`、`TTestCase_DispatchAPI`、`TTestCase_RuntimeAPI`、`TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent`、`gate` 已通过；剩余 review 结论 + commit |

## 2026-05-11 Facade Dispatch Unification

### Goal

把 `src/fafafa.core.simd.pas` 里残留的 façade wrapper 统一收回到 `dataplane` 发布的 dispatch 读取路径，避免 façade 继续显式依赖第二套 dispatch getter 语义。

### Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 找出残留的直接 dispatch 读取 | completed | 已确认 `simd.pas` 里大量 façade wrapper 仍直接调用 `GetDispatchTable`，而不是显式读 `dataplane` published snapshot |
| 2. 统一 façade wrapper 读取路径 | completed | 已将 `src/fafafa.core.simd.pas` 中所有 `GetDispatchTable` 调用统一替换为 `GetCurrentSimdDataPlaneDispatch` |
| 3. 验证并继续扫残余重复实现 | completed | Release `check`、targeted seam suites、`gate` 已通过；`api` / `ops` / `arrays` 已统一到 `GetDirectDispatchTable`，下一步继续检查 runtime/cpuinfo/family 面是否还有可清理的重复 truth 或多重实现 |
| 4. 继续扫剩余消费面 | in_progress | 已把 `GetDispatchTable` 直读收进 `dispatch-read-scope` 护栏；runtime 内部已去掉 `RegisteredFlags` 重复状态并收拢成共用 snapshot 读取 helper；继续检查 cpuinfo legacy aliases、framework 转发层和 family / adapter 面是否还存在重复实现、第二条 truth 或可合并的多路径封装 |
