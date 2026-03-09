# Task Plan: Layer0+Layer1 梳理 + SIMD 整理

## Goal
输出一份可执行的 Layer0/Layer1 问题清单（含复现/优先级/建议修复路径），并对 SIMD 模块建立“单元地图 + 测试矩阵 + 完成定义”，完成第一批高优先级修复与回归验证。

## Scope
- In:
  - SIMD：梳理架构/依赖/命名、测试覆盖与缺口；输出完成定义；修复高优先级问题
  - Layer0/Layer1：汇总历史发现与当前状态，形成可执行的修复清单（sync/simd 优先）
- Out:
  - 大规模重构（跨多个模块的拆分/重命名/迁移）除非必要且先达成一致
  - 追求“一次性全量全平台全通过”（本轮以建立基线与收敛关键风险为主）

## Backlog
- `backlog.md`：P0 / simd
- `backlog.md`：P0 / layer0+layer1

## Current Phase
Phase 5

## Phases

### Phase 1: Requirements & Baseline
- [x] 从 `backlog.md` 选定 1–3 个条目并贴链接（P0/simd、P0/layer0+layer1）
- [x] 建立 SIMD 单元地图（文件清单/分类/依赖关系）
- [x] 建立 SIMD 测试矩阵（用例分类 × ISA/backends × 平台）
- [x] 汇总 Layer0/Layer1 现存问题与证据指针（文档/日志/测试/issue）
- [x] 将关键发现写入 `findings.md`
- **Status:** complete

### Phase 2: Plan & Design
- [x] 定义 SIMD “完成定义”（最小后端集合/稳定 API 边界/兼容策略）
- [x] 明确文档收敛范围（更新哪些文件，哪些标记为过期/弃用）
- [x] 定义测试 runner 收敛方案（保持现状/适配层/统一 CLI）
- [x] 更新 Verification 口径（本轮需要跑哪些 suite/哪些模块）
- **Status:** complete

### Phase 3: Implementation
- [x] 分批实现（每批都能独立验证）
- [x] 重要决策与替代方案写入 `findings.md`
- **Status:** complete

### Phase 4: Verification
- [x] 回归测试（优先模块级，再全量）
- [x] 记录命令、退出码、关键日志路径到 `progress.md`
- **Status:** complete

### Phase 5: Delivery & Archive
- [x] 更新 `backlog.md`（Done/Next/链接归档）
- [x] 归档三文件到 `plans/archive/2026-02-06-<topic>/`
- **Status:** complete

## Key Questions
1. SIMD “完成”意味着什么？（API 稳定性、后端覆盖、跨平台一致性、性能基准）
2. SIMD 目前的主要混乱点是什么？（命名/重复实现/依赖层级/测试组织/平台条件编译）

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| SIMD DoD：对外稳定边界以 `fafafa.core.simd` 门面为主 | 降低“能用但不可控”的 surface，减少无意锁死内部实现 | 
| 文档收敛：模块文档以 `docs/fafafa.core.simd*.md` 与 `src/fafafa.core.simd.STABLE` 为准 | 避免多个“计划文档”互相打架，先保证一套正确的对外说明 |
| 测试 runner：短期保持 SIMD 自带 CLI，不强行统一 | 避免引入大范围兼容层；以 `BuildOrTest.*` 作为统一入口 |

## Verification
- `bash tests/fafafa.core.simd/BuildOrTest.sh check`
- `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.atomic fafafa.core.option fafafa.core.math fafafa.core.simd`
- `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.sync`（若本轮涉及 sync）

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
|       | 1       |            |
