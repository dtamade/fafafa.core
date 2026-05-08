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
| 2. 落地正式实施基线文档 | completed | 已新增 `docs/SIMD_LAYERING_IMPLEMENTATION.md`，写死三层目标形态、两层不成立的前提、adapter/leaf 硬边界与迁移纪律 |
| 3. 同步入口文档与 scratch 记录 | completed | `map/maintenance/handoff/interface/README` 与当前 scratch 记录已统一指向这份新基线 |
