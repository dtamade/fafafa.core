# Progress Log: repo hygiene batch8（reference/tomlc99-master）

## Session: 2026-02-07

### Current Status
- **Phase:** 4 - Delivery & Archive
- **Started:** 2026-02-07

### Actions Taken
- 按 `planning-with-files` 恢复上下文：执行 `session-catchup.py`，读取 `task_plan.md`/`findings.md`/`progress.md`。
- 校验基线：`batch7` 归档与 `backlog.md` 状态一致。
- 统计当前 ignored-but-tracked 顶层分布，确认主要存量在 `reference/`。
- 统计 `reference/` 子目录规模，选定 `reference/tomlc99-master`（151 项）作为 batch8。
- 检索 `src/tests/examples/docs` 与根脚本/文档中 `reference/tomlc99-master` 路径引用，未发现直接命中。
- 将三份 planning 文件切换到 batch8 目标与阶段。
- 执行 `reference/tomlc99-master` 全量去追踪（仅索引移除）：151 项。
- 验证去追踪后子目录 ignored-but-tracked 归零，且 staged delete 数量与基线一致。
- 验证全仓 ignored-but-tracked 总量下降，并确认本地参考文件仍存在。

### Test Results
| Command | Expected | Actual | Status |
|---------|----------|--------|--------|
| `python3 /home/dtamade/.codex/skills/planning-with-files/scripts/session-catchup.py "$(pwd)"` | 能恢复上下文 | 退出码 0，无异常输出 | PASS |
| `git ls-files -ci --exclude-standard \| awk -F/ '{print $1}' \| sort \| uniq -c \| sort -nr` | 显示顶层分布 | `reference 2777, lib 32, src 5, .claude 1` | PASS |
| `git ls-files -ci --exclude-standard reference | awk -F/ '{print $2}' | sort | uniq -c | sort -nr` | 显示子目录分布 | `tomlc99-master 151`（可控批次） | PASS |
| `rg -n "reference/tomlc99-master|reference\\tomlc99-master" src tests examples docs *.md *.sh *.bat` | 无路径级引用 | 空输出 | PASS |
| `git ls-files -ci --exclude-standard reference/tomlc99-master | wc -l` | 获取 batch8 基线 | `151` | INFO |
| `git diff --cached --name-status -- reference/tomlc99-master | wc -l` | staged delete 与基线一致 | `151` | PASS |
| `git ls-files -ci --exclude-standard reference/tomlc99-master | wc -l` (after) | 子目录归零 | `0` | PASS |
| `git ls-files -ci --exclude-standard | wc -l` | 全仓总量下降 | `2815 -> 2664` | PASS |
| `ls -l reference/tomlc99-master/README.md` | 本地文件保留 | 文件存在 | PASS |

### Notes
- 当前已完成 Phase 1~3，进入 Phase 4（交付与归档）。
- 待做（交付前）：更新 `backlog.md` 累计计数与 Done 记录，并归档到 `plans/archive/2026-02-07-sync-repo-hygiene-batch8/`。
