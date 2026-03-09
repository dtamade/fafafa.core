# Findings & Decisions: repo hygiene batch8（reference/tomlc99-master）

## Requirements
- 用户指令“按建议继续做”，按 `planning-with-files` 推进下一批 repo hygiene。
- 本轮聚焦 `backlog.md` 的 **P1 / repo**，继续“小批、可回滚”。

## Observations
- 现有 planning 文件与归档状态完整：`batch7` 已归档到 `plans/archive/2026-02-07-sync-repo-hygiene-batch7/`。
- 全仓 ignored-but-tracked 分布（batch8 前基线）：
  - `reference`: 2777
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
- 选定 `reference/tomlc99-master` 作为 batch8：151 项，体量可控。
- 路径级引用检索（`reference/tomlc99-master`）未发现代码/测试/脚本直接依赖。
- 已执行 `reference/tomlc99-master` 索引去追踪，验证结果：
  - `git diff --cached --name-status -- reference/tomlc99-master | wc -l` = `151`
  - `git ls-files -ci --exclude-standard reference/tomlc99-master | wc -l` = `0`
  - `git ls-files -ci --exclude-standard | wc -l`：`2815 -> 2664`
  - 本地文件保留（`reference/tomlc99-master/README.md` 存在）

## Decisions
| Decision | Rationale | Evidence |
|----------|-----------|----------|
| batch8 仅处理 `reference/tomlc99-master` | 体量可控（151 项），符合小步治理策略 | `git ls-files -ci --exclude-standard reference/tomlc99-master` |
| 引用检索采用路径级关键字 | 避免把非路径提及误判为目录依赖 | `rg -n "reference/tomlc99-master|reference\\tomlc99-master" ...` |
| 继续“仅索引移除，本地保留” | 兼顾仓库卫生与本地参考可用性 | 既有 batch1~7 策略一致性 |
| 维持单目录批次推进 | 降低评审与回滚成本 | batch8 单批 151 项、结果可验证 |

## Risks / Open Questions
- `reference/` 仍有较大存量（batch8 后约 2626），需继续按目录拆批推进。
- 后续候选目录体量更大（如 `bubbletea-main` 190），建议继续“引用核对 + 小批推进”。

## Resources (paths / links)
- `task_plan.md`
- `backlog.md`
- `progress.md`
- `plans/archive/2026-02-07-sync-repo-hygiene-batch7/`
- `reference/tomlc99-master/`
- `plans/archive/2026-02-07-sync-repo-hygiene-batch8/`（待归档）
