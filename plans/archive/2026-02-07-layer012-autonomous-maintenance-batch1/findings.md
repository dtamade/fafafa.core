# Findings & Decisions: 自主发现任务（维护推进 Layer0 + Layer1 + Layer2）

## Requirements
- 用户要求：**自主创建任务、不要中断、立即加入任务体系**。
- 目标：维护推进 Layer0 / Layer1 / Layer2，而不是仅做 repo hygiene。

## Observations
- `backlog.md` 已加入新的进行中条目：`P0 / layer0+layer1+layer2 自主维护推进`。
- `docs/ARCHITECTURE_LAYERS.md` 已确认分层边界：
  - Layer0: `base/atomic/option/result/mem.allocator/simd`
  - Layer1: `collections/math/io/bytes/thread/sync/time`
  - Layer2: `crypto/json/process/socket/lockfree/fs/mem(高级)`
- 关键机制发现：`tests/run_all_tests.sh` 仅识别 `BuildOrTest.sh` 或 `BuildAndTest.sh`（大小写敏感）。
- Layer2 首轮 sweep 前，部分模块脚本入口不规范：
  - `fafafa.core.process`/`fafafa.core.socket` 仅有 `buildOrTest.sh`（小写）
  - `fafafa.core.yaml` 缺少 Linux `BuildOrTest.sh`
  - `toml/xml` 脚本未传 `--all`，会先触发 FPCUnit usage 退出
- 已完成脚本层修复：
  - 新增 `tests/fafafa.core.process/BuildOrTest.sh`
  - 新增 `tests/fafafa.core.socket/BuildOrTest.sh`
  - 新增 `tests/fafafa.core.yaml/BuildOrTest.sh`
  - 修复 `tests/fafafa.core.toml/BuildOrTest.sh` 测试参数为 `--all --format=plain`
  - 修复 `tests/fafafa.core.xml/BuildOrTest.sh` 测试参数为 `--all --format=plain`
- Layer2 当前失败矩阵（batch1）：
  - `process`：编译失败（`fpSetpgid` 未找到、`fafafa.core.process.unix.inc` 多处标识符/语法错误）
  - `socket`：编译失败（`fafafa.core.socket.linux.inc` 语法错误：`BEGIN` 期望处出现 `USES`）
  - `toml`：可运行但大量用例断言失败
  - `xml`：可运行但多项用例断言失败
  - `yaml`：通过

## Decisions
| Decision | Rationale | Evidence |
|----------|-----------|----------|
| 将“自主维护推进”固化到 backlog Now/Next | 建立不中断的可持续推进机制 | `backlog.md` 新条目 |
| 先修复 run_all 入口脚本规范问题 | 保证 sweep 覆盖真实模块，不被脚本命名误导 | `run_all_tests.sh` 收集逻辑 |
| batch1 聚焦“拿真实失败矩阵”而非一次性修复全部 | 降低改动风险，优先建立可执行任务链 | 二次 sweep 结果稳定复现 |
| batch2 优先 process/socket 编译失败 | 编译阻断优先级高于测试断言失败 | process/socket 无法进入有效测试阶段 |

## Risks / Open Questions
- `process/socket` 当前为编译级阻断，修复可能涉及 Layer2 实现与条件编译分支。
- `toml/xml` 失败项较多，需按“公共根因 > 单测逐项”策略拆批，不宜一次性全修。
- 需要持续验证 Layer0/1 基线未被 Layer2 修复回压破坏。

## Resources (paths / links)
- `task_plan.md`
- `backlog.md`
- `progress.md`
- `docs/ARCHITECTURE_LAYERS.md`
- `tests/run_all_tests.sh`
- `tests/_run_all_logs_sh/fafafa.core.process.log`
- `tests/_run_all_logs_sh/fafafa.core.socket.log`
- `tests/_run_all_logs_sh/fafafa.core.toml.log`
- `tests/_run_all_logs_sh/fafafa.core.xml.log`
- `plans/archive/2026-02-06-layer0-layer1-simd-deep-clean/`
