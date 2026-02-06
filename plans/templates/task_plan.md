# Task Plan: {{TOPIC}}

## Goal
[一句话描述本轮迭代的终态]

## Scope
- In:
- Out:

## Current Phase
Phase 1

## Phases

### Phase 1: Requirements & Baseline
- [ ] 从 `backlog.md` 选定 1–3 个条目并贴链接
- [ ] 复现/确认基线（失败点、warning/hint、性能退化等）
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
- [ ] 归档三文件到 `plans/archive/{{DATE}}-<topic>/`
- **Status:** pending

## Key Questions
1. [要回答的关键问题]
2. [要回答的关键问题]

## Decisions Made
| Decision | Rationale |
|----------|-----------|
|          |           |

## Verification
- `STOP_ON_FAIL=1 bash tests/run_all_tests.sh <modules...>`
- `bash tests/run_all_tests.sh`（全量时注意避免交互阻塞）

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
|       | 1       |            |

