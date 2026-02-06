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

## Current Phase
Phase 1

## Phases

### Phase 1: Requirements & Baseline
- [ ] 从 `backlog.md` 选定 1–3 个条目并贴链接（P0/simd、P0/layer0+layer1）
- [ ] 建立 SIMD 单元地图（文件清单/分类/依赖关系）
- [ ] 建立 SIMD 测试矩阵（用例分类 × ISA/backends × 平台）
- [ ] 汇总 Layer0/Layer1 现存问题与证据指针（文档/日志/测试/issue）
- [ ] 将关键发现写入 `findings.md`
- **Status:** in_progress

### Phase 2: Plan & Design
- [ ] 明确最小改动方案（必要时先写 design note）
- [ ] 定义验证口径与命令（写入本文件 Verification）
- **Status:** pending

### Phase 3: Implementation
- [ ] 分批实现（每批都能独立验证）
- [ ] 重要决策与替代方案写入 `findings.md`
- **Status:** pending

### Phase 4: Verification
- [ ] 回归测试（优先模块级，再全量）
- [ ] 记录命令、退出码、关键日志路径到 `progress.md`
- **Status:** pending

### Phase 5: Delivery & Archive
- [ ] 更新 `backlog.md`（Done/Next/链接归档）
- [ ] 归档三文件到 `plans/archive/2026-02-06-<topic>/`
- **Status:** pending

## Key Questions
1. SIMD “完成”意味着什么？（API 稳定性、后端覆盖、跨平台一致性、性能基准）
2. SIMD 目前的主要混乱点是什么？（命名/重复实现/依赖层级/测试组织/平台条件编译）

## Decisions Made
| Decision | Rationale |
|----------|-----------|
|          |           |

## Verification
- `bash tests/fafafa.core.simd/BuildOrTest.sh check`
- `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.atomic fafafa.core.option fafafa.core.math fafafa.core.simd`
- `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.sync`（若本轮涉及 sync）

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
|       | 1       |            |
