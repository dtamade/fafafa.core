# Task Plan: repo hygiene batch7（reference/DCPcrypt）

## Goal
继续推进 `backlog.md` 的 **P1 / repo**，以“小批、可回滚”方式去追踪 `reference/DCPcrypt` 下 ignored-but-tracked 项，确保仅移除索引、不影响本地文件。

## Scope
- In:
  - 盘点并去追踪 `reference/DCPcrypt` 已跟踪但被 `.gitignore` 忽略的文件
  - 更新 `backlog.md` 与三份 planning 文件并归档
- Out:
  - 大规模跨目录清理
  - 改动 `src/`、公共 API、测试逻辑

## Backlog
- `backlog.md`: **P1 / repo**

## Current Phase
Phase 4

## Phases

### Phase 1: Requirements & Baseline
- [x] 恢复会话上下文（`session-catchup` + 读取三文件）
- [x] 盘点 ignored-but-tracked 分布并选定最小批次 `reference/DCPcrypt`
- [x] 验证仓库内无 `reference/DCPcrypt` 路径引用
- [x] 获取 batch7 基线数量
- **Status:** complete

### Phase 2: Implementation
- [x] 去追踪 `reference/DCPcrypt` 全量 ignored-but-tracked 项
- [x] 保留本地文件（仅索引层变更）
- **Status:** complete

### Phase 3: Verification
- [x] 校验 `reference/DCPcrypt` ignored-but-tracked 归零
- [x] 校验 staged delete 数量与基线数量一致
- [x] 校验全仓 ignored-but-tracked 总量按预期下降
- **Status:** complete

### Phase 4: Delivery & Archive
- [x] 更新 `backlog.md` Now/Done 与累计计数
- [ ] 归档三文件到 `plans/archive/2026-02-07-sync-repo-hygiene-batch7/`
- **Status:** in_progress

## Key Questions
1. batch7 是否能保持低风险？→ **是，范围限定单一子目录 `reference/DCPcrypt`。**
2. 是否存在代码/脚本引用风险？→ **未发现 `reference/DCPcrypt` 路径引用。**
3. 是否会删除本地参考文件？→ **不会，本地文件保留（如 `reference/DCPcrypt/CHANGELOG.txt` 仍存在）。**

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| 本轮只处理 `reference/DCPcrypt` | 在 `reference/` 存量中属于较小批次（92 项），便于审阅与回滚 |
| 引用检查采用“路径级”匹配 | `DCPcrypt` 关键词在代码注释中出现，但不等于目录依赖 |
| 继续采用“仅索引移除”策略 | 保持工作区本地文件可用，最小化破坏性 |

## Verification
- Baseline:
  - `git ls-files -ci --exclude-standard reference/DCPcrypt | wc -l`
  - `rg -n "reference/DCPcrypt|reference\\\\DCPcrypt" src tests examples docs *.md *.sh *.bat`
  - 结果：基线 `92`，仅 `findings.md` 历史备注命中
- After implementation:
  - `git diff --cached --name-status -- reference/DCPcrypt | wc -l`
  - `git ls-files -ci --exclude-standard reference/DCPcrypt | wc -l`
  - `git ls-files -ci --exclude-standard | wc -l`
  - `ls -l reference/DCPcrypt/CHANGELOG.txt`
  - 结果：staged delete `92`、子目录 ignored-but-tracked `0`、全仓 `2907 -> 2815`、本地文件保留

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
| 暂无 | - | - |
