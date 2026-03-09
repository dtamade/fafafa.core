# Repo Gap Scan Priority Batch-43 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 按 Round-2 计划一次性完成 `sync.barrier` Task01-08（`TTestCase_IBarrier` 的 8 个 wait 语义占位测试），严格执行 TDD。

**Architecture:** 统一 RED 打桩 → 统一 GREEN 并发断言 → 目标项逐项回归 → `TTestCase_IBarrier` 子集回归 → 模块回归。

**Tech Stack:** FreePascal/FPCUnit、`tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.testcase.pas`。

---

## Task01-08（本批）
1. `Test_Wait_MultipleParticipants_OneSerial`
2. `Test_Wait_SerialThread_Identification`
3. `Test_Wait_NonSerialThread_ReturnsFalse`
4. `Test_Wait_Barrier_Reuse_MultipleRounds`
5. `Test_Wait_Barrier_Reuse_DifferentThreadCounts`
6. `Test_Wait_Sequential_Rounds_SerialDistribution`
7. `Test_Wait_Concurrent_Threads_Synchronization`
8. `Test_Wait_Concurrent_Barriers_Independence`

---

## 执行记录（2026-02-11）

### Phase-1：RED
1) 将 8 项占位统一改为显式失败：`Fail('RED Batch-43: ... TODO')`

2) 编译
- `cd tests/fafafa.core.sync.barrier && bash BuildOrTest.sh build`
- 输出：`Linking .../bin/fafafa.core.sync.barrier.test`

3) 逐项 RED 运行
- `for t in <8项>; do ./bin/fafafa.core.sync.barrier.test --format=plain --suite=TTestCase_IBarrier.$t | rg -n "Failed:|Number of failures"; done`
- 输出（节选）：
  - `Test_Wait_MultipleParticipants_OneSerial  Failed: RED Batch-43: ...`
  - `Number of failures:  1`
  - 8 项均 `Number of failures: 1`

### Phase-2：GREEN
1) 一次性补齐 8 项真实并发断言
- 多参与者场景：断言 `DoneCount`、`CountTrue(serialFlags)=1`
- 重用场景：断言多轮复用下每轮严格 `1` 个 serial
- 不同参与者规模：`2/3/5` 跨规模复用稳定性
- 同步场景：通过等待耗时断言验证 barrier 阻塞语义（`Elapsed >= 50ms`）
- 独立性场景：双 barrier 并发互不影响，各自 `serial count = 1`

2) 编译
- `cd tests/fafafa.core.sync.barrier && bash BuildOrTest.sh build`
- 输出：`Linking .../bin/fafafa.core.sync.barrier.test`

### Phase-3：回归
1) 8 项逐项回归
- 命令：
  - `for t in <8项>; do ./bin/fafafa.core.sync.barrier.test --format=plain --suite=TTestCase_IBarrier.$t | rg -n "^  00|Number of failures"; done`
- 输出：8 项全部 `Number of failures: 0`

2) `IBarrier` 子集回归
- `./bin/fafafa.core.sync.barrier.test --format=plain --suite=TTestCase_IBarrier`
- 输出：`Number of errors: 0`，`Number of failures: 0`

3) 模块回归
- `bash BuildOrTest.sh test`
- 输出（关键）：
  - `Time:01.328 N:42 E:0 F:0 I:0`
  - `Number of run tests: 42`
  - `Number of errors:    0`
  - `Number of failures:  0`

---

## 本批改动文件
- `tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.testcase.pas`

## 结论
- Batch-43 整包完成（Task01-08）。
- 8 个 wait 语义占位测试已替换为可执行并发断言，模块回归通过。
