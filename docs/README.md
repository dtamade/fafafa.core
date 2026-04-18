# fafafa.core 文档说明

推荐从 `docs/INDEX.md` 进入：这里是**唯一需要手工维护**的总索引页。

## 快速入口

- 文档总索引：`docs/INDEX.md`
- 测试指南：`docs/TESTING.md`
- CI 指南：`docs/CI.md`
- 目录结构规范：`docs/standards/DIRECTORY_STANDARDS.md`
- 工程规范：`docs/standards/ENGINEERING_STANDARDS.md`
- 命名规范：`docs/standards/NAMING_CONVENTION_PROJECT.md`

## 文档放置约定（清理后的结构）

- **模块文档（主入口）**：`docs/fafafa.core.<module>.md`
- **模块扩展文档**：`docs/fafafa.core.<module>.*.md`（例如 best-practices / troubleshooting / api）
- **规范/清单**：`docs/standards/`
- **设计与计划**：优先放 `docs/design/` 或 `docs/designs/`
- **报告/复盘/审计/评审**：放 `docs/reports/`、`docs/audits/`、`docs/reviews/`（不要堆在 `docs/` 根目录）
- **ADR**：`docs/adr/`
- **可复用片段**：`docs/partials/`

> 目标：`docs/` 根目录只保留“长期有效”的入口与模块文档，过程性文档集中到子目录，避免越堆越乱。

