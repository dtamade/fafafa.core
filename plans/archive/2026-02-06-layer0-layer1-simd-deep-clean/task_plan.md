# Task Plan: Layer0/Layer1 sweep + SIMD deep clean

## Goal
建立 Layer0/Layer1 的可执行问题清单（含复现命令/优先级/建议修复路径），并对 SIMD 做“文档单一真相 + 过期内容收敛 + P0/P1 问题关单”第一批闭环。

## Scope
- In:
  - Layer0/Layer1：按 `docs/ARCHITECTURE_LAYERS.md` 做模块级 sweep（build/test），记录失败点与复现命令
  - SIMD：收敛文档/规划文档的权威来源；清理过期/误导内容；对 P0/P1 做第一批修复与回归
- Out:
  - 大规模重构（跨模块拆分/重命名/迁移）除非必要且先达成一致
  - 一次性把所有平台/架构都跑绿（本轮先把 Linux 基线与对外口径收敛）

## Current Phase
Phase 5

## Phases

### Phase 1: Requirements & Baseline
- [x] 从 `backlog.md` 选定 1–3 个条目并贴链接（P0/simd deep-clean、P0/layer0+layer1 sweep）
- [x] 复现/确认基线（失败点、warning/hint、性能退化等）
- [x] 将关键发现写入 `findings.md`
- **Status:** complete

### Phase 2: Plan & Design
- [x] 明确最小改动方案（必要时先写 design note）
- [x] 定义验证口径与命令（写入本文件 Verification）
- **Status:** complete

### Phase 3: Implementation
- [x] 分批实现（每批都能独立验证）
- [x] 重要决策与替代方案写入 `findings.md`
- **Status:** complete

### Phase 4: Verification
- [x] 回归测试（优先模块级，再全量）
- [x] 记录命令、退出码、关键日志路径到 `progress.md`
- **Status:** complete

### Phase 5: Delivery & Archive
- [x] 更新 `backlog.md`（Done/Next/链接归档）
- [x] 归档三文件到 `plans/archive/2026-02-06-<topic>/`
- **Status:** complete

## Key Questions
1. Layer0/Layer1 当前基线是否全绿？失败点集中在哪些模块/平台条件？
2. SIMD 的“权威文档”应是哪几份？哪些 `docs/SIMD_*` 属于历史记录/可归档？

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| ThreadPool `QueueCapacity` 判满语义改为“入队后有效队列长度” | capacity 表示允许排队数量；capacity=0 仍应允许空闲 worker 直接接任务，避免把正常 Submit 全部拒绝 |
| 指标口径：`TotalSubmitted` 计入入队与 CallerRuns；`TotalRejected` 不包含 CallerRuns | CallerRuns 属于“回退执行”而非“丢弃/拒绝”；但仍应被 Submitted 计数覆盖，方便容量与回退观测 |
| parkinglot FastPath 性能用例用“稳定竞争 + 更高迭代数”去除抖动 | 避免计时粒度/调度噪声导致 flaky 的误报 |
| UNIX thread tests 强制引入 `cthreads`，并让 env var 测试跨平台 | 解决 Linux runtime error 211 与非 Windows 下编译/运行一致性问题 |

## Verification
- 基线 sweep（Layer0/Layer1）：
  - `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.base fafafa.core.atomic fafafa.core.option fafafa.core.result fafafa.core.mem.allocator.mimalloc fafafa.core.simd`
  - `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.collections fafafa.core.math fafafa.core.io fafafa.core.bytes fafafa.core.thread fafafa.core.sync fafafa.core.time`
- SIMD 改动的最小回归：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh test`

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
| Linux 下 thread tests runtime error 211（未启用线程支持） | 1 | `tests/fafafa.core.thread/tests_thread.lpr` 在 uses 前部引入 `cthreads`（UNIX） |
| parkinglot FastPath 性能用例偶发失败（计时抖动/无稳定竞争） | 1 | 引入稳定竞争线程 + 提升迭代数，避免时间分辨率误报 |
| `tests/fafafa.core.thread/BuildOrTest.sh` 可执行路径错误 | 1 | 修正为 `../../bin/tests_thread`，并补充缺失二进制时返回 127 |
| env var 测试硬依赖 `Windows` 单元导致 UNIX 无法编译 | 1 | UNIX 使用 `setenv`，Windows 分支保留 `SetEnvironmentVariable` |
