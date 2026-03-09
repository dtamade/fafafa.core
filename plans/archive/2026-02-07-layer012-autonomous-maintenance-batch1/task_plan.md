# Task Plan: 自主发现任务（维护推进 Layer0 + Layer1 + Layer2）

## Goal
建立一个“自主发现 → 自主执行 → 自主归档”的持续维护节奏：在不打断用户的前提下，推进 Layer0/Layer1/Layer2 的基线稳定性与问题闭环，并把任务显式写入 backlog。

## Scope
- In:
  - 将“自主发现任务（Layer0/1/2）”加入 `backlog.md`
  - 基于 `docs/ARCHITECTURE_LAYERS.md` 做 Layer0/1/2 基线审计
  - 执行首个自主子任务（Layer2 模块回归扫线 + 运行脚本规范化）
  - 记录失败矩阵并生成 batch2 任务候选
- Out:
  - 大规模重构或 API 破坏性改动
  - 一次性处理所有历史技术债

## Backlog
- `backlog.md`: **P0 / layer0+layer1+layer2 自主维护推进**
- `backlog.md`: **P0 / simd deep-clean follow-up**
- `backlog.md`: **P0 / layer0+layer1 sweep follow-up**

## Current Phase
Phase 5

## Phases

### Phase 1: Requirements & Baseline
- [x] 恢复会话上下文（`session-catchup` + backlog/归档）
- [x] 读取 `docs/ARCHITECTURE_LAYERS.md`，确认 Layer0/1/2 模块边界
- [x] 盘点 tests 目录，确认 Layer2 可执行模块列表
- [x] 将“自主发现任务”写入 `backlog.md` 的 Now/Next
- **Status:** complete

### Phase 2: Plan & Design
- [x] 定义自主推进规则（每轮：发现 1 个任务 + 完成 1 个子任务）
- [x] 选定首个子任务范围（Layer2 回归扫线模块集合）
- [x] 定义验证口径（命令、退出码、通过标准）
- **Status:** complete

### Phase 3: Implementation
- [x] 执行 Layer2 首轮回归扫线（模块级）
- [x] 修复脚本级阻塞项（`BuildOrTest.sh` 命名/参数）
- [x] 形成失败矩阵并拆分后续最小修复方向
- **Status:** complete

### Phase 4: Verification
- [x] 复核关键结果（模块通过数、失败数、失败类型）
- [x] 更新 `findings.md` 风险与优先级
- **Status:** complete

### Phase 5: Delivery & Archive
- [ ] 更新 `backlog.md`（Now/Next/Done + batch2 指向）
- [ ] 归档三文件到 `plans/archive/2026-02-07-layer012-autonomous-maintenance-batch1/`
- **Status:** in_progress

## Key Questions
1. 如何做到“不中断用户”仍可持续推进？→ **通过 backlog 显式化 + 每轮自主关单 1 个子任务。**
2. Layer2 当前是否稳定？→ **当前不稳定：process/socket 编译失败，toml/xml 测试失败，yaml 通过。**
3. 首轮最有价值产出是什么？→ **把“未被 run_all 覆盖的模块”纳入标准入口并拿到真实失败矩阵。**

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| 采用“自主发现 + 自主执行 + 自主归档”循环 | 满足“不要中断”诉求，同时保持可追溯性 |
| 首轮聚焦 Layer2 sweep | Layer2 更容易暴露跨层集成问题 |
| 先修复脚本入口问题再看源码失败 | 避免把“脚本缺陷”误判为“模块稳定” |

## Verification
- 基线审计：
  - `sed -n '1,260p' docs/ARCHITECTURE_LAYERS.md`
  - `ls -1 tests`
  - `rg -n "layer0|layer1|layer2" docs plans src tests`
- Layer2 sweep（首轮）：
  - `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.crypto fafafa.core.json fafafa.core.process fafafa.core.socket fafafa.core.fs fafafa.core.lockfree fafafa.core.mem fafafa.core.toml fafafa.core.yaml fafafa.core.xml`
  - 结果：`Total 14 / Passed 13 / Failed 1 (toml)`
- 关键模块二次扫线：
  - `bash tests/run_all_tests.sh fafafa.core.toml fafafa.core.xml fafafa.core.process fafafa.core.socket fafafa.core.yaml`
  - 结果：`Total 5 / Passed 1 / Failed 4`
  - 失败：`process(socket 源码编译类) + toml/xml(测试失败)`

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
| `process/socket` 原 `buildOrTest.sh` CRLF 导致 shell 解析失败 | 1 | 改为规范 `BuildOrTest.sh` 入口脚本 |
| `socket` 脚本使用不存在的 `Debug` build mode | 1 | 移除 build-mode 参数，使用默认模式构建 |
| `process/socket/toml/xml` 源码或测试失败 | 1 | 记录为 batch2+ 待修复项，先完成失败矩阵与任务拆分 |
