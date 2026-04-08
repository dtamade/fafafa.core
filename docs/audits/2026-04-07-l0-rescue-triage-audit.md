# 2026-04-07 L0 Rescue Triage Audit

> 这份审计记录的是 `2026-04-07` 的 rescue triage 结论。
> 当前 active L0 triage 以 `docs/audits/2026-04-09-l0-current-state-audit.md` 为准。

## 结论先行

这次审计回答的是一个很具体的问题：`PR #6` 合并之后，L0 还应该继续做什么，哪些东西绝对不要再通过 L0 这条线带回主线。

结论：

- `main` 已经通过 merge commit `7b5e9e7f` 接收了 strict L0 promotion。
- `l0-main-rescue` 是混合快照，不是 merge target。
- rescue 里的大头是 SIMD、CI、closeout、evidence 相关材料，不属于 L0 回流面。
- 这轮最先要清的是主线控制面污染，而不是继续 broad merge rescue。

## 审计基线

对比基线：

- merged main anchor: `7b5e9e7f`
- promotion anchor: `2ea1e94b`
- rescue snapshot: `ecfc1c3f`

使用的主 diff：

```bash
git diff --name-status l0-main-promotion-20260407..l0-main-rescue
```

## 已确认稳定的部分

`PR #6` 合并后，L0 面的回归仍然通过：

```bash
STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.base fafafa.core.contracts fafafa.core.bits fafafa.core.layout fafafa.core.endian fafafa.core.span fafafa.core.option fafafa.core.result fafafa.core.atomic fafafa.core.mem.allocator.foundation fafafa.core.platform
bash tests/fafafa.core.contracts/BuildOrTest.sh test-no-contracts
bash examples/fafafa.core.contracts/BuildOrRun.sh run
bash examples/fafafa.core.platform/BuildOrRun.sh run
git diff --check
```

这意味着 rescue triage 不需要靠“整包回流”来维持 L0 绿色。

## 审计发现

### 1. 主线最大的脏点是控制面，不是 L0 功能本身

主线最需要清理的是这些控制面污染：

- 根目录 `task_plan.md`
- 根目录 `findings.md`
- 根目录 `progress.md`
- 过期的 `workers/worker1.md`
- 仍把根目录执行镜像当 current source-of-truth 的索引/说明文档

这些文件会让仓库看起来像“当前状态散落在根目录 scratch log 里”，这和 L0 主线需要的稳定入口相冲突。

### 2. rescue 里绝大多数残留属于 SIMD 线

下面这些路径明确不经过 L0 lane：

- `.github/workflows/simd-*`
- `docs/fafafa.core.simd*`
- `docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md`
- `tests/fafafa.core.simd/**`
- `tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh`
- `src/fafafa.core.simd.neon.register.inc`

决策：这些内容只做 handoff，不做 L0 回流。

### 3. 有一小批非 SIMD rescue 差异值得后续单独拆批

后续可以逐文件审查，但不能整树带回：

- `docs/CI.md`
- `tests/run_all_tests.sh`
- `tests/test_repo_hygiene_guard.sh`
- `tools/lazbuild.sh`
- `examples/fafafa.core.atomic/BuildOrRun.sh`
- `examples/fafafa.core.base/BuildOrRun.sh`
- `examples/fafafa.core.option/BuildOrRun.sh`
- `examples/fafafa.core.result/BuildOrRun.sh`
- `examples/fafafa.core.base/example_base.lpr`
- `examples/fafafa.core.result/example_result_filters_and_try.lpr`
- `src/fafafa.core.mem.allocator.callbackAllocator.pas`
- `src/fafafa.core.time.tick.hardware.aarch64.pas`
- `src/fafafa.core.time.tick.hardware.armv7a.pas`
- `src/fafafa.core.time.tick.hardware.i386.pas`
- `src/fafafa.core.time.tick.hardware.riscv32.pas`
- `src/fafafa.core.time.tick.hardware.riscv64.pas`

决策：这些差异只能按小批次、带 fresh verification 回来。

### 4. rescue 中有明显不能接收的删除集

`l0-main-rescue` 会删掉 `examples/fafafa.core.contracts/`，这和 merged main 当前已经 fresh 验证通过的入口相冲突。

决策：这类删除集直接拒绝，不纳入后续回流。

### 5. root 清污必须连同历史报告和一次性脚本一起做

除了 working-log，仓库根目录还堆着一批历史报告、工作总结和一次性脚本：

- `AUTONOMOUS_WORK_SESSION_REPORT.md`
- `COMPILATION_ERRORS_FIX_REPORT.md`
- `CRYPTO_CROSS_PLATFORM_FIX_REPORT.md`
- `MATH_FIX_REPORT.md`
- `SYNC_MODULES_FIX_REPORT.md`
- `WORKING.md`
- `WORKING_IMPROVED_EXAMPLE.md`
- `START_GUIDE.md`
- `build_and_run_memory_leak_tests.sh`
- `fix_sync_lpi_include_paths.py`
- `fix_sync_thread_support.sh`

决策：这批内容应该归档或移出根目录，不继续冒充当前入口。

## 批次决策

| 批次 | 范围 | owner | 结论 |
| --- | --- | --- | --- |
| A | PR `#6` merge + merged-main verification | L0 | 完成 |
| B | 主线控制面清污 | L0 | 本轮完成 |
| C | 非 SIMD rescue 候选 | L0 | 后续拆批 |
| D | SIMD / CI / evidence 残留 | SIMD owner | handoff |
| E | 破坏当前验证入口的 rescue 删除集 | reject | 不接收 |

## 当前主线入口

- L0 定义：`docs/fafafa.core.l0.foundation.md`
- L0 审计：`docs/audits/2026-04-07-l0-rescue-triage-audit.md`
- L0 路线图：`docs/plans/2026-04-07-l0-rescue-split-closeout.md`
- 当前 L0 worker：`workers/worker1.md`
