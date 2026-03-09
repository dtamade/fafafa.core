# Findings & Decisions: repo hygiene batch6（reference/xxHash-dev）

## Requirements
- 用户指令“继续工作”，按 `planning-with-files` 进入下一批次清理。
- 本轮聚焦 `backlog.md` 的 **P1 / repo**，保持“小批、可回滚”。

## Observations
- 现有 planning 文件与归档状态完整：`batch5` 已归档到 `plans/archive/2026-02-07-sync-repo-hygiene-batch5/`。
- 全仓 ignored-but-tracked 分布（当前基线）：
  - `reference`: 2958
  - `lib`: 32
  - `src`: 5
  - `.claude`: 1
- `reference/` 子目录分布前几名：
  - `yyjson-master` 795
  - `nginx-master` 489
  - `libuv-1.x` 421
  - `libfyaml-master` 366
  - `ratatui-main` 365
  - `bubbletea-main` 190
  - `tomlc99-master` 151
  - `DCPcrypt` 92
  - `xxHash-dev` 89
- 选定 `reference/xxHash-dev` 作为 batch6：89 项，属于可控小批。
- 代码/脚本/文档引用检索（`src tests examples docs *.md *.sh *.bat`）未发现 `xxHash-dev` 直接引用。
- 已执行 `reference/xxHash-dev` 索引去追踪，验证结果：
  - `git diff --cached --name-status -- reference/xxHash-dev | wc -l` = `89`
  - `git ls-files -ci --exclude-standard reference/xxHash-dev | wc -l` = `0`
  - `git ls-files -ci --exclude-standard | wc -l`：`2996 -> 2907`
  - 本地文件保留（`reference/xxHash-dev/README.md` 存在）

## Decisions
| Decision | Rationale | Evidence |
|----------|-----------|----------|
| batch6 仅处理 `reference/xxHash-dev` | 体量小（89 项），符合小步治理策略 | `git ls-files -ci --exclude-standard reference/xxHash-dev` |
| 清理前先做引用检索 | 降低误删真实依赖风险 | `rg -n "reference/xxHash-dev|reference\\\\xxHash-dev|xxHash-dev" ...` 无命中 |
| 继续“仅索引移除，本地保留” | 兼顾仓库卫生与本地参考可用性 | 既有 batch1~5 策略一致性 |
| 维持小批单目录推进节奏 | 降低评审与回滚成本 | batch6 单批 89 项、结果可验证 |

## Risks / Open Questions
- `reference/` 仍有大规模存量（batch6 后约 2869），需继续按目录拆批推进。
- `reference/DCPcrypt` 等可能与历史工作流关联更强，后续批次需再做使用面核对。

## Resources (paths / links)
- `task_plan.md`
- `backlog.md`
- `progress.md`
- `reference/xxHash-dev/`
- `plans/archive/2026-02-07-sync-repo-hygiene-batch5/`
- `plans/archive/2026-02-07-sync-repo-hygiene-batch6/`（待归档）
