# 文档总索引

本页只保留长期有效的入口，不再手工维护一份庞大的“全量清单”。

## 开始阅读

- 文档治理与放置规则：`docs/README.md`
- 架构分层：`docs/ARCHITECTURE_LAYERS.md`
- L0 详细定义：`docs/fafafa.core.l0.foundation.md`
- L0 rescue 收口路线图：`docs/plans/2026-04-07-l0-rescue-split-closeout.md`
- L0 rescue 审计：`docs/audits/2026-04-07-l0-rescue-triage-audit.md`
- 工程规范：`docs/standards/ENGINEERING_STANDARDS.md`
- 目录规范：`docs/standards/DIRECTORY_STANDARDS.md`
- 命名规范：`docs/standards/NAMING_CONVENTION_PROJECT.md`
- 测试指南：`docs/TESTING.md`
- CI 指南：`docs/CI.md`
- 示例总览：`docs/EXAMPLES.md`
- 变更日志：`docs/CHANGELOG.md`

## 模块文档入口

模块主文档使用统一命名：

- `docs/fafafa.core.<module>.md`

模块扩展文档使用：

- `docs/fafafa.core.<module>.<topic>.md`

例如：

- `docs/fafafa.core.base.md`
- `docs/fafafa.core.contracts.md`
- `docs/fafafa.core.bits.md`
- `docs/fafafa.core.platform.md`
- `docs/fafafa.core.layout.md`
- `docs/fafafa.core.endian.md`
- `docs/fafafa.core.atomic.md`
- `docs/fafafa.core.option.md`
- `docs/fafafa.core.result.md`
- `docs/fafafa.core.mem.md`
- `docs/fafafa.core.span.md`
- `docs/fafafa.core.collections.md`
- `docs/fafafa.core.fs.md`
- `docs/fafafa.core.simd.md`

## 领域子目录

当一个主题形成完整文档体系时，放到独立子目录中：

- `docs/collections/`
- `docs/lockfree/`
- `docs/mem/`
- `docs/fs/`
- `docs/term/`
- `docs/simd/`
- `docs/benchmarks/`
- `docs/adr/`
- `docs/standards/`
- `docs/reports/`
- `docs/reviews/`
- `docs/audits/`
- `docs/plans/`
- `docs/legacy/`
- `docs/refactoring/`

## 如何判断一份文档是否权威

按下面顺序判断：

1. `docs/standards/*.md`
2. `docs/ARCHITECTURE_LAYERS.md`
3. `docs/fafafa.core.<module>.md`
4. 领域子目录中的长期文档
5. `docs/plans/`、`docs/reports/`、`docs/reviews/`
6. `docs/legacy/` 与 `archive/reports/`

## 当前特别说明

- `docs/Architecture.md` 这种歧义命名已经停止作为全局架构入口使用。
- 历史 `PHASE0_*` 文档已归档到 `docs/legacy/phase0/`；当前 L0 以 `docs/fafafa.core.l0.foundation.md` 为准。
- `docs/plans/2026-03-24-l0-docs-closeout-roadmap.md` 现在是已完成的历史 closeout；当前 follow-up 以 `docs/plans/2026-04-07-l0-rescue-split-closeout.md` 为准。
- 根目录 `task_plan.md`、`findings.md`、`progress.md` 已从主线移除；最后一份快照归档在 `plans/archive/2026-04-07-mainline-working-set/`。
- 当前 L0 协作入口见 `workers/worker1.md`，当前 triage 判断见 `docs/audits/2026-04-07-l0-rescue-triage-audit.md`。
- `docs/fafafa.core.span.md`、`docs/fafafa.core.contracts.md` 和 `docs/fafafa.core.platform.md` 现在都对应 strict L0 的实体入口。
- 旧的 L0 candidate / merge-closeout 文档已经归档到 `docs/legacy/l0/`，不要再把那批候选结论当作 current-entry。
- `fafafa.core.span2` / `fafafa.core.collections.slice` 不等同于当前 strict L0 的最小 `span`，不要把更宽 slice 语义误读成已进入 L0。
- VecDeque 相关设计文档已归位到 `docs/collections/design/vecdeque-architecture.md`。
- lockfree 领域的 guide/design/report 文档已归位到 `docs/lockfree/`。
- mem 领域的报告与旧版指南已下沉到 `docs/mem/`，根目录只保留稳定入口。
- fs 领域的研究、开发者说明和旧 topic 文档已归位到 `docs/fs/`。
- term 领域的旧 guide、报告和计划文档已归位到 `docs/term/`。
- simd 领域的专题 guide、计划、报告和 closeout/handoff 文档已归位到 `docs/simd/`。
- 已完成的根目录修复报告已迁移到 `archive/reports/`。
- collections / benchmarks 的阶段性 campaign 报告已迁移到 `archive/reports/docs-collections/` 与 `archive/reports/docs-benchmarks/`；原目录只保留归档指路页。
- `docs/reports/` 根下第一批 dated fix/checkpoint 报告已迁移到 `archive/reports/docs-root/`；保留在 `docs/reports/` 的文件应视为仍有领域引用或仍需二次收口的历史报告。
