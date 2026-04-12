# fafafa.core 文档说明

推荐从 `docs/INDEX.md` 进入：这里是**唯一需要手工维护**的总索引页。

## 快速入口

- 文档总索引：`docs/INDEX.md`
- L0 稳定路线图：`docs/fafafa.core.l0.roadmap.md`
- L0 详细定义：`docs/fafafa.core.l0.foundation.md`
- 当前 L0 审计：`docs/audits/2026-04-11-l0-current-state-audit.md`
- retained refs 第二波吸收审计：`docs/audits/2026-04-12-l0-retained-refs-second-absorption-audit.md`
- L0 post-merge 稳定化计划：`docs/plans/2026-04-11-l0-post-merge-stabilization-plan.md`
- L0 历史批次 / 审计归档：`docs/legacy/l0/README.md`
- 测试指南：`docs/TESTING.md`
- CI 指南：`docs/CI.md`
- 目录结构规范：`docs/standards/DIRECTORY_STANDARDS.md`
- 工程规范：`docs/standards/ENGINEERING_STANDARDS.md`
- 命名规范：`docs/standards/NAMING_CONVENTION_PROJECT.md`

## L0 当前导航

- L0 的稳定文档栈固定为：`docs/ARCHITECTURE_LAYERS.md` + `docs/fafafa.core.l0.foundation.md` + `docs/fafafa.core.l0.roadmap.md` + 最新 `docs/audits/*l0*.md`
- strict L0 模块入口统一收在 `docs/INDEX.md` 的 `Strict L0 模块入口` 区段
- strict L0 已经合并到 `main`；superseded 的 dated L0 plans/audits 统一下沉到 `docs/legacy/l0/`
- 当前如果要继续沿 L0 维护，优先看最新 audit、roadmap、foundation 和 post-merge stabilization plan
- Linux x64 的日常维护入口固定为：`bash tests/run_strict_l0_maintenance_loop.sh`

## 文档放置约定（清理后的结构）

- **模块文档（主入口）**：`docs/fafafa.core.<module>.md`
- **模块扩展文档**：`docs/fafafa.core.<module>.*.md`（例如 best-practices / troubleshooting / api）
- **规范/清单**：`docs/standards/`
- **稳定路线图 / 主题设计**：优先使用长期可维护的主题入口，例如 `docs/fafafa.core.l0.roadmap.md`
- **执行批次计划**：放 `docs/plans/YYYY-MM-DD-*.md`，只描述某一轮 dated batch，不再承担长期 current-entry
- **L0 历史批次 / 审计**：统一下沉到 `docs/legacy/l0/`
- **报告/复盘/审计/评审**：放 `docs/reports/`、`docs/audits/`、`docs/reviews/`（不要堆在 `docs/` 根目录）
- **历史报告归档**：统一下沉到 `archive/reports/docs-root/`、`archive/reports/docs-collections/`、`archive/reports/docs-benchmarks/`；原目录只保留 README 指路页
- **ADR**：`docs/adr/`
- **可复用片段**：`docs/partials/`
- **执行日志 / scratch 计划**：不要长期留在仓库根目录；需要入库时，直接归档到 `plans/archive/`，稳定结论再提升到 `docs/plans/` 或 `docs/audits/`

> 目标：`docs/` 根目录只保留“长期有效”的入口与模块文档，过程性文档集中到子目录，避免越堆越乱。
