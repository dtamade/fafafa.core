# Findings & Decisions

## Requirements
- 你将离线约 10 小时，希望我执行一个“长时间工作”。
- 你指定工作流程：`planning-with-files` 持久化记录；若涉及新增/改行为，先 `brainstorming` 明确需求与方案，再 `writing-plans` 产出实现计划；按 `executing-plans` 分批执行并在每批后汇报；任何完成声明前必须 `verification-before-completion` 跑验证命令并贴结果。
- 规划文件进 Git：长期入口 `backlog.md`；每轮迭代归档到 `plans/archive/`。
- 由于你未给出具体功能需求，本次默认目标设为：跑关键/全量测试回归并修复失败（若有）。
- 约束：`fafafa.core.collections` 作为“大单元”不得拆分为更多单元文件，只允许在原单元内优化/修复。
- 授权：你要求我“全项目全权做主”，可自主发现问题并推进修复与维护。

## Research Findings
- 当前环境工具链可用：`fpc` 版本 3.3.1；`lazbuild` 版本 4.99。
- 仓库已提供统一测试入口：`bash tests/run_all_tests.sh`（详见 `docs/TESTING.md`）。
- 发现一个高风险问题：`tests/run_all_tests.sh` 使用“脚本所在目录 basename”作为模块名过滤。对 `tests/fafafa.core.collections/vec` 这种嵌套目录会得到模块名 `vec`，导致文档/约定中的 `fafafa.core.collections.vec` 等过滤无法命中，从而出现 **Total=0 但退出码=0** 的“假绿”。
- 发现一个会卡死的问题：`tests/run_all_tests.sh` 会同时执行 `BuildOrTest.sh` 与 `BuildAndTest.sh`；当前 `tests/fafafa.core.lockfree/BuildAndTest.sh` 末尾无条件 `read`，会在全量回归时阻塞；Windows 侧 `tests/run_all_tests.bat` 同理会调用带 `pause` 的 `BuildAndTest.bat`。
- `tests/fafafa.core.fs/BuildOrTest.sh check` 仍失败：构建日志中 `src/` 触发了 4055/4082（`src/fafafa.core.fs.dir.pas`）与 5026（`src/fafafa.core.fs.fileio.pas`）——需要继续“0 warnings/hints”洁净化。
- 已落地修复：`tests/run_all_tests.sh` / `tests/run_all_tests.bat` 模块命名与过滤规则统一；过滤 0 命中返回码=2；同目录优先 `BuildOrTest.*` 避免阻塞；同步更新 `docs/TESTING.md`。
- 覆盖范围提醒：`tests/run_all_tests.sh` 只会发现并执行 `BuildOrTest.sh` / `BuildAndTest.sh`；当前仍有少量模块只有 `.bat`（例如 `tests/fafafa.core.signal` / `tests/fafafa.core.os`），因此 Unix runner 不会覆盖到这些模块（建议下一轮补齐 `.sh` runner 或统一模板）。

## Technical Decisions
| Decision | Rationale |
|----------|-----------|
| 先跑关键模块再全量 | 先快速验证环境/主路径，避免一上来全量耗时且噪声大。 |
| 未经确认不做“增功能/大改动” | 你当前离线，优先做可验证、低风险的修复与回归。 |
| 改进 run_all_tests 过滤与脚本选择策略 | 避免“假绿”和全量回归卡死；让文档建议的模块名能真实命中。 |

## Issues Encountered
| Issue | Resolution |
|-------|------------|
| `fafafa.core.fs` check 仍有 4055/4082/5026 | 已修复：`TFsReadDir.FTypes` 改为 `array of TfsDirEntType`；`TFsFileNoExcept.Write/PWrite` 显式引用 `@ABuffer` |
| `fafafa.core.fs.mmap` check 仍有 4055/5028 | 已修复：移除未使用 const；指针偏移改为 `PByte(...) + ...`；syscall wrapper 局部 `{$WARN 4055 OFF}` |
| `fafafa.core.sync` `tests_sync --all` 卡死（futex wait, 单线程） | 根因：测试套件用 `MakePthreadMutex`（PTHREAD_MUTEX_NORMAL）跑“重入应报错”用例，导致同线程二次 `Acquire` 直接死锁；修复：相关测试改用 `MakeMutex`（ERRORCHECK/或 futex 实现） |
| `run_all_tests` 过滤/假绿/阻塞风险 | 已修复并验证：模块名=相对路径点分；过滤 0 命中 exit 2；默认只跑 `BuildOrTest.*` |

## Resources
- `docs/TESTING.md`
- `tests/run_all_tests.sh`
- `backlog.md`
- `plans/README.md`
