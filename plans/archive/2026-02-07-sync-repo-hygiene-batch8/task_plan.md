# Task Plan: repo hygiene batch8（reference/tomlc99-master）

## Goal
继续推进 `backlog.md` 的 **P1 / repo**，以“小批、可回滚”方式去追踪 `reference/tomlc99-master` 下 ignored-but-tracked 项，确保仅移除索引、不影响本地文件。

## Scope
- In:
  - 盘点并去追踪 `reference/tomlc99-master` 已跟踪但被 `.gitignore` 忽略的文件
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
- [x] 盘点 ignored-but-tracked 分布并选定最小批次 `reference/tomlc99-master`
- [x] 验证仓库内无 `reference/tomlc99-master` 路径引用
- [x] 获取 batch8 基线数量
- **Status:** complete

### Phase 2: Implementation
- [x] 去追踪 `reference/tomlc99-master` 全量 ignored-but-tracked 项
- [x] 保留本地文件（仅索引层变更）
- **Status:** complete

### Phase 3: Verification
- [x] 校验 `reference/tomlc99-master` ignored-but-tracked 归零
- [x] 校验 staged delete 数量与基线数量一致
- [x] 校验全仓 ignored-but-tracked 总量按预期下降
- **Status:** complete

### Phase 4: Delivery & Archive
- [ ] 更新 `backlog.md` Now/Done 与累计计数
- [ ] 归档三文件到 `plans/archive/2026-02-07-sync-repo-hygiene-batch8/`
- **Status:** in_progress

## Key Questions
1. batch8 是否能保持低风险？→ **是，范围限定单一子目录 `reference/tomlc99-master`。**
2. 是否存在代码/脚本引用风险？→ **未发现 `reference/tomlc99-master` 路径引用。**
3. 是否会删除本地参考文件？→ **不会，本地文件保留（如 `reference/tomlc99-master/README.md` 仍存在）。**

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| 本轮只处理 `reference/tomlc99-master` | 在 `reference/` 存量中属于可控批次（151 项），便于审阅与回滚 |
| 引用检查采用“路径级”匹配 | 避免把一般文本提及误判为目录依赖 |
| 继续采用“仅索引移除”策略 | 保持工作区本地文件可用，最小化破坏性 |

## Verification
- Baseline:
  - `git ls-files -ci --exclude-standard reference/tomlc99-master | wc -l`
  - `rg -n "reference/tomlc99-master|reference\\tomlc99-master" src tests examples docs *.md *.sh *.bat`
  - 结果：基线 `151`，路径级引用检索无命中
- After implementation:
  - `git diff --cached --name-status -- reference/tomlc99-master | wc -l`
  - `git ls-files -ci --exclude-standard reference/tomlc99-master | wc -l`
  - `git ls-files -ci --exclude-standard | wc -l`
  - `ls -l reference/tomlc99-master/README.md`
  - 结果：staged delete `151`、子目录 ignored-but-tracked `0`、全仓 `2815 -> 2664`、本地文件保留

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
| 暂无 | - | - |
