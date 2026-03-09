# Findings & Decisions: repo hygiene batch7（reference/DCPcrypt）

## Requirements
- 用户指令“继续工作”，按 `planning-with-files` 进入下一批次清理。
- 本轮聚焦 `backlog.md` 的 **P1 / repo**，保持“小批、可回滚”。

## Observations
- 现有 planning 文件与归档状态完整：`batch6` 已归档到 `plans/archive/2026-02-07-sync-repo-hygiene-batch6/`。
- 全仓 ignored-but-tracked 分布（batch7 前基线）：
  - `reference`: 2869
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
- 选定 `reference/DCPcrypt` 作为 batch7：92 项，属于可控小批。
- 路径级引用检索（`reference/DCPcrypt`）未发现代码/测试/脚本直接依赖；仅 `findings.md` 历史文本命中。
- 已执行 `reference/DCPcrypt` 索引去追踪，验证结果：
  - `git diff --cached --name-status -- reference/DCPcrypt | wc -l` = `92`
  - `git ls-files -ci --exclude-standard reference/DCPcrypt | wc -l` = `0`
  - `git ls-files -ci --exclude-standard | wc -l`：`2907 -> 2815`
  - 本地文件保留（`reference/DCPcrypt/CHANGELOG.txt` 存在）

## Decisions
| Decision | Rationale | Evidence |
|----------|-----------|----------|
| batch7 仅处理 `reference/DCPcrypt` | 体量小（92 项），符合小步治理策略 | `git ls-files -ci --exclude-standard reference/DCPcrypt` |
| 引用检索采用路径级关键字 | 避免把注释中的 “DCPcrypt” 文案误判为目录依赖 | `rg -n "reference/DCPcrypt|reference\\\\DCPcrypt" ...` |
| 继续“仅索引移除，本地保留” | 兼顾仓库卫生与本地参考可用性 | 既有 batch1~6 策略一致性 |
| 维持小批单目录推进节奏 | 降低评审与回滚成本 | batch7 单批 92 项、结果可验证 |

## Risks / Open Questions
- `reference/` 仍有大规模存量（batch7 后约 2777），需继续按目录拆批推进。
- 后续可候选目录规模较大（如 `tomlc99-master` 151、`bubbletea-main` 190），应继续按“引用核对 + 小批推进”执行。

## Resources (paths / links)
- `task_plan.md`
- `backlog.md`
- `progress.md`
- `plans/archive/2026-02-07-sync-repo-hygiene-batch6/`
- `reference/DCPcrypt/`
- `plans/archive/2026-02-07-sync-repo-hygiene-batch7/`（待归档）
