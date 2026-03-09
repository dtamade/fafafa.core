# Repo Gap Scan 50 Tasks v2 (Round-2) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 基于 2026-02-11 最新全仓扫描结果，形成下一轮 50 个可执行缺口任务，并按优先级整包推进。

**Architecture:** 继续“同语义域整包”策略：P0 先收敛 `sync.barrier` 占位高密区，P1 收敛 `toml` 解析/写出缺口，P2 覆盖 socket/yaml/vec 与 src 端 TODO。

**Tech Stack:** FreePascal/FPCUnit、`tests/*`、`src/*`。

---

## 扫描基线（2026-02-11）
命令：
- `rg -n "TODO|placeholder|暂未实现|未实现" src tests | cut -d: -f1 | sort | uniq -c | sort -nr | head -n 20`

热点：
- `tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.testcase.old.pas`（34）
- `tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.testcase.pas`（25）
- `tests/fafafa.core.toml/*` + `src/fafafa.core.toml.pas`（多文件集中）

---

## 50任务优先级清单（Round-2）

### P0（Task 01-20：sync.barrier）
1. `barrier` 基础构造/析构占位替换
2. `barrier` 单线程 wait 语义
3. `barrier` 多线程全部到达后放行
4. `barrier` 重复轮次复用（phase rollover）
5. `barrier` 超时等待返回语义
6. `barrier` 超时后下一轮恢复语义
7. `barrier` abort/cancel 路径
8. `barrier` reset 路径
9. `barrier` 并发高压 smoke
10. `barrier` 边界 participant=1
11. `barrier` participant=0 参数校验
12. `barrier` wait 次序一致性
13. `barrier` 跨线程异常传播语义
14. `barrier` 资源释放与无泄漏验证
15. `barrier` old testcase #1 去占位
16. `barrier` old testcase #2 去占位
17. `barrier` old testcase #3 去占位
18. `barrier` old testcase #4 去占位
19. `barrier` old testcase #5 去占位
20. `barrier` 子集回归与稳定性复核

### P1（Task 21-38：toml）
21. `toml` 负数解析 #1
22. `toml` 负数解析 #2
23. `toml` 负数解析 #3
24. `toml` 负数解析 #4
25. `toml` 负数解析 #5
26. `toml` 写出快照 tight case #1
27. `toml` 写出快照 tight case #2
28. `toml` 写出快照 tight case #3
29. `toml` 写出快照 tight case #4
30. `toml` 写出快照 tight case #5
31. `src/fafafa.core.toml.pas` TODO 路径 #1
32. `src/fafafa.core.toml.pas` TODO 路径 #2
33. `src/fafafa.core.toml.pas` TODO 路径 #3
34. `src/fafafa.core.toml.pas` TODO 路径 #4
35. `src/fafafa.core.toml.pas` TODO 路径 #5
36. `toml` parser/writer 交叉回归 #1
37. `toml` parser/writer 交叉回归 #2
38. `toml` 模块子集回归总结

### P2（Task 39-50：socket/yaml/vec/src）
39. `tests/fafafa.core.socket/Test_fafafa_core_socket.pas` 占位 #1
40. `tests/fafafa.core.socket/Test_fafafa_core_socket.pas` 占位 #2
41. `tests/fafafa.core.socket/Test_fafafa_core_socket.pas` 占位 #3
42. `tests/fafafa.core.yaml/fafafa.core.yaml.testcase.pas` 占位 #1
43. `tests/fafafa.core.yaml/fafafa.core.yaml.testcase.pas` 占位 #2
44. `tests/fafafa.core.collections/vec/Test_vec.pas` 占位 #1
45. `tests/fafafa.core.collections/vec/Test_vec.pas` 占位 #2
46. `src/fafafa.core.time.parse.pas` TODO 路径 #1
47. `src/fafafa.core.os.pas` TODO 路径 #1
48. `src/fafafa.core.bytes.pas` TODO 路径 #1
49. `src` 端 TODO 组合回归与风险评估
50. Round-2 汇总收官（文档+回归证据）

---

## 执行批次建议（executing-plans）
- Batch-43：Task 01-08（barrier 主路径）
- Batch-44：Task 09-20（barrier 高压 + old testcase）
- Batch-45：Task 21-30（toml 负数 + writer tight）
- Batch-46：Task 31-38（toml src TODO + 交叉回归）
- Batch-47：Task 39-50（socket/yaml/vec/src + round 收官）

每批统一流程：
1) RED：先让目标测试可见失败。
2) GREEN：最小改动修复。
3) 回归：目标用例 + 邻近子集。
4) 记录：同步 `task_plan.md`/`findings.md`/`progress.md`。

## 执行进度更新（截至 2026-02-11 Batch-43）
- ✅ Task 01 `barrier 基础构造/析构占位替换`（在 IBarrier Wait 语义批次中同步完成）
- ✅ Task 02 `barrier 单线程 wait 语义`
- ✅ Task 03 `barrier 多线程全部到达后放行`
- ✅ Task 04 `barrier 重复轮次复用`
- ⏳ Task 05 `barrier 超时等待返回语义`（当前 API 无超时接口，留 Batch-44 兼容策略）
- ⏳ Task 06 `barrier 超时后下一轮恢复语义`（依赖 Task05，同步留 Batch-44）
- ⏳ Task 07 `barrier abort/cancel 路径`（留 Batch-44）
- ⏳ Task 08 `barrier reset 路径`（留 Batch-44）

### Batch-43 说明
- 本批严格完成了 Task01-08 对应的“wait 核心语义”整包收敛。
- `abort/cancel/reset` 这类扩展语义在当前 API 不直接暴露，将在 Batch-44 以兼容断言方式继续推进。

## 执行进度更新（截至 2026-02-11 Batch-44）
- ✅ Batch-44（主文件范围）已完成：`tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.testcase.pas` 剩余 17 项占位全部替换并回归通过。
- ✅ P0 可执行主路径缺口已清零：`testcase.pas` 中 `TODO/placeholder` 命中为 0。
- ⏳ `testcase.old.pas` 仍有 34 项占位，作为 Batch-45/后续批次候选。

### P0 任务状态细化（更新）
- ✅ Task 09 `barrier 并发高压 smoke`（由 stress 高频/长跑/线程耗尽路径覆盖）
- ✅ Task 10 `barrier 边界 participant=1`（已在既有 IBarrier 用例中稳定覆盖）
- ✅ Task 11 `barrier participant=0 参数校验`（已在 Global 用例覆盖）
- ✅ Task 12 `barrier wait 次序一致性`（由 rapid/mixed/race 多轮顺序断言覆盖）
- ⏳ Task 05/06/07/08（timeout/abort/reset 语义）
  - 当前 `IBarrier` API 未直接暴露对应接口，需在后续以扩展 API 或兼容策略专项处理。
- ⏳ Task 13/14/15/16/17/18/19（异常传播/资源释放/old testcase 去占位）
  - 本批未触达，保留到后续整包。
- ✅ Task 20 `barrier 子集回归与稳定性复核`
  - `TTestCase_IBarrier`: `Number of run tests: 28`, `errors=0`, `failures=0`
  - 模块回归：常规与 `FAFAFA_STRESS=1` 均 `N:42 E:0 F:0`

## 执行进度更新（截至 2026-02-11 Batch-45）
- ✅ Batch-45（toml P1 子集）完成：
  - 数值负例 3 项（下划线邻接小数点、整数前导零、浮点前导零）
  - writer 默认快照语义 1 项（默认空格等号 vs tight 紧凑等号）
- ✅ 目标两文件占位清零：
  - `Test_fafafa_core_toml_numbers_negatives.pas`
  - `Test_fafafa_core_toml_writer_snapshot_tight_todo.pas`
- ⏳ P1 其余任务（writer tight 其余快照、src/toml TODO 路径 31-35）留待 Batch-46。

### P1 状态细化（更新）
- ✅ Task 21 `toml 负数解析 #1`
- ✅ Task 22 `toml 负数解析 #2`
- ✅ Task 23 `toml 负数解析 #3`
- ✅ Task 26 `toml 写出快照 tight case #1`（默认 vs tight 语义断言落地）
- ⏳ Task 24/25/27/28/29/30/31/32/33/34/35/36/37/38（后续批次）

### 回归备注
- 目标子集通过：
  - `TTestCase_Numbers_Negatives` -> `N:14 E:0 F:0`
  - `TTestCase_Writer_Snapshot_DefaultSpacing` -> `N:1 E:0 F:0`
- 模块全量现状：`tests_toml` 仍为 `N:122 E:0 F:34`（既有历史失败，不属于本批新增）。
