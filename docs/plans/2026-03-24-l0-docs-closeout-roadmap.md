# 2026-03-24 L0 Docs Closeout Roadmap

> Status: completed historical batch.
>
> 当前 L0 follow-up 以 `docs/plans/2026-04-07-l0-rescue-split-closeout.md` 为准。
> 当时的根目录执行镜像已归档到 `plans/archive/2026-04-07-mainline-working-set/`。

**Goal:** 为当前 `fafafa.core` 建立一份长期有效的 L0 文档治理路线图，先收紧根入口和模块域 source-of-truth，再做全仓 residual docs sweep，最后完成根级验收。

**Architecture:** 采用“根入口定锚 -> 按域收口 -> 全仓残留扫尾 -> 根级验收”的串行推进方式。`docs/plans/` 保留长期路线图；当时的执行镜像后来已归档到 `plans/archive/2026-04-07-mainline-working-set/`。

**Tech Stack:** Markdown、`docs/`、`tests/*/README.md`、`examples/*/README.md`、`rg`、`prettier`。

---

## 当前总原则

- 先处理根级入口、umbrella 入口、目录级 README，再处理 guide / design / plan / review / report
- 一个主题只保留一套 current source-of-truth，不再允许第二套“也像主文档”的材料继续上浮
- 默认原地改写；只有路径本身制造混淆时才移动或归档
- 允许为了稳定文档边界做少量支持性修补，但当前主线仍是文档治理
- `simd` 当前不在本路线图的实现范围；这里只做 L0 文档治理和导航边界收敛

## 当前 source-of-truth

先按这个顺序理解本轮治理：

1. `docs/README.md`
2. `docs/INDEX.md`
3. `docs/ARCHITECTURE_LAYERS.md`
4. `docs/fafafa.core.l0.foundation.md`
5. 本路线图 `docs/plans/2026-03-24-l0-docs-closeout-roadmap.md`
6. 当时执行镜像：现已归档到 `plans/archive/2026-04-07-mainline-working-set/`
7. worker 状态：参见当时与后续的 `workers/worker1.md`

## 已完成基线

本路线图建立前，以下阶段已经完成并验证：

- Phase 101: `sync.timespec`、`sync.benchmark`、`namedSharedCounter`、`mutex.parkinglot` 根文档收口
- Phase 102: `tests/fafafa.core.sync.benchmark/`、`tests/fafafa.core.sync.namedSharedCounter/` 等测试入口补 README
- Phase 103: `tests/fafafa.core.sync.sem/`、`namedSemaphore`、`namedRWLock`、`namedLatch`、`namedBarrier` 测试入口补 README
- Phase 104: `namedEvent`、`namedOnce`、`namedWaitGroup`、`namedMutex` 测试入口，以及 `namedSemaphore`、`namedRWLock`、`namedBarrier` 示例入口补 README
- Phase 105: 总路线图落库并挂到 `docs/INDEX.md`
- Phase 106: `sync` umbrella/root 入口 README 收口

这些阶段已经把 `sync` 域最明显的根入口与测试/示例入口缺口收回到当前文档体系里。

## Phase Map

| Phase | Scope                                    | Status   | Exit Criteria                                                                                                         |
| ----- | ---------------------------------------- | -------- | --------------------------------------------------------------------------------------------------------------------- |
| 105   | 建立总路线图并挂到索引                   | complete | `docs/plans` 中有长期路线图，`docs/INDEX.md` 有稳定入口，`task_plan.md` 改为引用这份路线图                            |
| 106   | 收口 `sync` 的 umbrella/root 入口 README | complete | `tests/fafafa.core.sync/`、`tests/fafafa.core.sync.named/`、`examples/fafafa.core.sync.*` 关键根入口都具备当前 README |
| 107   | 收口 `collections` 域                    | complete | `docs/fafafa.core.collections*.md`、`docs/collections/`、相关 `tests/examples` 入口不再传播第二套合同                 |
| 108   | 收口 `time` / `benchmark` / `thread` 域  | complete | 根入口、历史分析、refactoring/topic 旁路文档完成降级或导航化                                                          |
| 109   | 收口 `fs` / `mem` / `lockfree` / `term`  | complete | 子域 README、根入口、历史材料边界稳定，不再与根级入口冲突                                                             |
| 110   | 全仓 residual docs sweep                 | complete | 非上述主域之外仍会上浮的 generic 文档、错位计划/报告、README 缺口和命名冲突完成最后一轮清扫                           |
| 111   | 根级最终验收与 closeout                  | complete | `docs/INDEX.md`、根目录工作流文档、`workers/` 状态与最终 diff/check 全部闭环                                          |

## Phase 107: Collections

目标：

- 把 `collections` 域重新压回“根入口 + 子域 README + guide/design/review/report/status/legacy 分层”的稳定结构
- 停止让旧 completion/report/review/status/plan 文档继续冒充当前 API、当前质量结论或当前路线图

当前 source-of-truth anchors：

- `docs/fafafa.core.collections.md`
- `docs/fafafa.core.collections.api.md`
- `docs/collections/README.md`
- `docs/fafafa.core.collections.vec.md`
- `docs/fafafa.core.collections.vecdeque.md`
- `tests/fafafa.core.collections/README.md`
- `examples/fafafa.core.collections/README.md`
- `examples/collections/README.md`

当前优先处理：

- `archive/reports/docs-collections/COLLECTIONS_100_PERCENT_COMPLETION_REPORT.md`
- `archive/reports/docs-collections/COLLECTIONS_CLEANUP_COMPLETION_REPORT.md`
- `archive/reports/docs-collections/COLLECTIONS_QUALITY_IMPROVEMENT_COMPLETION_REPORT.md`
- `archive/reports/docs-collections/COLLECTIONS_BUGFIX_WORK_SUMMARY.md`
- `docs/collections/reviews/COLLECTIONS_API_CONSISTENCY_REVIEW_2025-11-03.md`
- `docs/collections/reviews/COLLECTIONS_CODE_QUALITY_REVIEW_2025-11-03.md`
- `docs/collections/plans/COLLECTIONS_NEW_CONTAINERS_PLAN_2025-11-03.md`

## Phase 108: Time, Benchmark, Thread

目标：

- 把 `time`、`benchmark`、`thread` 三个已经部分收口的域继续做最后一轮入口校正
- 把 still-floating 的分析稿、refactoring 提案、阶段性总结继续压回“历史参考”角色

本阶段优先处理：

- `docs/fafafa.core.time*.md`
- `docs/topics/time/`
- `docs/refactoring/`
- `docs/fafafa.core.benchmark*.md`
- `docs/benchmarks/`
- `docs/fafafa.core.thread*.md`
- `docs/designs/thread.md`

当前批次进展：

- 已把 `docs/fafafa.core.time.md` 改写为 `time` 域根入口，只保留当前 source-of-truth、模块结构、阅读路径和边界。
- 已把 `docs/topics/time/ISO8601_USAGE.md` 收回为历史使用手册，不再让它继续充当当前 API 教程。
- 已把 `docs/fafafa.core.time.naming-convention.md` 收回为历史命名说明，不再让它继续充当当前统一命名规范手册。
- 已把 `docs/topics/time/cron/CRON_QUICK_REFERENCE.md`、`CRON_MACROS_IMPLEMENTATION.md`、`CRON_SCHEDULER_COMPLETE.md` 收回为历史速查卡 / 历史实现报告 / 历史完成报告，不再让它们继续输出当前 quick reference、当前测试统计或当前 merge-ready 结论。
- 已把 `tests/fafafa.core.time/DOC_P1_FIXES_COMPLETE.md`、`CLOCK_FIXES_COMPLETE.md`、`ISSUE_21_SUMMARY.md` 收回为历史测试 / 修复快照，不再让它们继续输出固定通过数、`全部完成` / `生产就绪` / `已关闭` 一类当前结论。
- 已把 `docs/fafafa.core.thread.boundaries.md`、`docs/fafafa.core.thread.token.md`、`docs/fafafa.core.thread.metrics.md`、`docs/fafafa.core.thread.tuning.md` 统一改写为当前补充页范式，补齐 `source-of-truth`、当前验证入口和当前边界，不再继续维持旧式最佳实践 / 实现宣讲 / 变更记录混写结构。
- 已把 `docs/benchmarks/fafafa.core.bytes.buf.microbench.md` 收回为历史微基准草案，并把当前入口明确挂回 `docs/benchmarks/INDEX.md`、`benchmarks/fafafa.core.bytes/README.md`、真实 `.lpr` 程序和 `bytes` / `bytes.buf` 文档。
- `docs/refactoring/time*` 当前复核后已基本符合历史提案定位；`docs/fafafa.core.benchmark.md` 与 `docs/fafafa.core.thread.md` 当前结构也已基本对齐，下一步优先继续扫 `tests/fafafa.core.time/` 其余 residual docs，以及 `benchmark` / `thread` 域剩余尾项。
- 最新残留扫描结果表明：`benchmark` / `thread` 根入口、历史文档和当前补充页已基本对齐；`Phase 108` 下一跳更适合落在 `examples/fafafa.core.benchmark/VALIDATION_REPORT.md`、`MULTITHREADED_USAGE.md` 这类 benchmark sidecar 文档。
- 已新增 `examples/fafafa.core.benchmark/README.md`，把 benchmark 示例目录正式收回为当前导航页，并明确 root `buildOrRun.bat` 只覆盖两个 Windows `Debug` 示例。
- 已把 `examples/fafafa.core.benchmark/MULTITHREADED_USAGE.md` 收敛为当前补充页，只保留多线程入口、示例和验证路径，不再继续维持旧式“最佳实践大全”结构。
- 已把 `examples/fafafa.core.benchmark/VALIDATION_REPORT.md` 收回为 `2025-08-07` 的历史验证快照，不再继续传播固定示例数、固定通过率和“生产就绪”结论。
- `Phase 108` exit scan 已完成：`docs/topics/time/`、`docs/benchmarks/`、`docs/refactoring/time*`、`docs/designs/thread.md`、`tests/fafafa.core.time/*.md`、`examples/fafafa.core.benchmark/`、`examples/fafafa.core.thread/README.md` 范围内没有再发现新的 current-competitor 文档。
- 剩余更可疑的 time 文档主要落在 generic 桶里，例如 `docs/audits/2025-10-02_time_module_comprehensive_audit.md`、`docs/reports/time/TIME_PRODUCTION_READINESS_REPORT.md`、`docs/reports/ISSUE-29-30-31-36-doc-fix-report.md`；这些更适合并入 `Phase 110` 的 residual sweep，而不是继续留在 `Phase 108`。
- 因此，`Phase 108` 可以视为完成，下一步转入 `Phase 109` 的 `fs / mem / lockfree / term` 域收口。

## Phase 109: FS, Mem, Lockfree, Term

目标：

- 把已经开始归位的 `fs`、`mem`、`lockfree`、`term` 域做成稳定子目录模式
- 根目录只保留长期入口，子目录负责 guide / design / plan / report / legacy

本阶段优先处理：

- `docs/fs/`
- `docs/mem/`
- `docs/lockfree/`
- `docs/term/`
- 相关根入口 `docs/fafafa.core.fs*.md`、`docs/fafafa.core.mem*.md`、`docs/fafafa.core.lockfree*.md`、`docs/fafafa.core.term*.md`

当前批次进展：

- 已把 `mem` 域根入口、`guide` / `quickstart` / `architecture` 以及 `docs/mem/README.md`、`tests/examples` 根 README 全部收回当前入口范式。
- 已把 `lockfree` 域根入口、`best-practices` / `cheatsheet`、`docs/lockfree/README.md` 与 `tests/examples` 根 README 全部收回当前入口范式。
- 已把 `fs` 域根入口、`docs/fs/README.md`、`tests/fafafa.core.fs/README.md`、`examples/fafafa.core.fs/README.md` 收口，并把 `README_BUILD.md`、`README_FINAL.md` 压回历史快照层。
- 已把 `term` 域根入口、`quick-reference`、`docs/term/README.md`、`tests/fafafa.core.term*/README.md`、`examples/fafafa.core.term*/README.md` 收口到稳定子目录模式。
- closeout 后又补做了一个小型脚本修复批：`examples/fafafa.core.lockfree/BuildOrRun.sh` 已修复 shell 语法与路径问题，`examples/fafafa.core.fs/build.sh` 已改回 `example_fs.lpi` / `bin/example_fs`，`examples/fafafa.core.term.ui/BuildOrTest.bat` 已改回 `bin\\example_term_ui.exe`。
- 因此，`Phase 109` 已完成；这四个域的“当前入口 / 历史材料 / tests/examples 目录 README”边界已经稳定。

## Phase 110: Repo Residual Docs Sweep

目标：

- 做一轮跨主题 residual sweep，清掉仍会与当前主入口竞争的零散文档
- 解决“文件已不在主域，但命名、位置或标题仍像 current source-of-truth”的尾项

本阶段优先处理：

- 根级 `docs/` 下仍使用 generic 命名、completion/report/roadmap 语气但未被稳定入口接管的文件
- `tests/`、`examples/`、`src/` 侧仍缺 README 或 README 仍写成旧手册的目录
- 错位挂载在不相关子目录里的历史材料
- 与当前 README / INDEX / root module docs 口径冲突的 dated 文档

当前批次进展：

- 已把 `docs/audits/2025-10-02_time_module_comprehensive_audit.md` 改写为 `time` 域历史审计快照。
- 已把 `docs/reports/ISSUE-29-30-31-36-doc-fix-report.md` 改写为 `time.format` / `time.parse` 的历史文档修补快照。
- 已把 `docs/patches/fafafa.core.term.doc_patch.draft.md` 改写为 `term` 域历史 patch 草案。
- 已复核 `docs/reports/time/TIME_PRODUCTION_READINESS_REPORT.md`，确认它当前已经符合历史生产评估快照定位，因此本阶段不再重复改写。
- 因此，`Phase 110` 已完成；最后一批 generic/错位文档已回退到补充或历史层，不再与当前根入口竞争。

## Phase 111: Root Acceptance

目标：

- 完成本轮 L0 文档治理的根级验收
- 给后续同学留下稳定入口，而不是继续依赖聊天上下文恢复状态

验收清单：

- `docs/INDEX.md` 只保留长期入口，并能指向本路线图
- 本轮触达主题的 root/umbrella `tests/examples` 目录都具备 README
- `task_plan.md`、`findings.md`、`progress.md` 与 `workers/worker1.md` 同步到同一阶段
- 本轮触达文件的 `prettier`、`git diff --check`、必要的 `rg` 扫描全部通过
- 旧 `*_PLAN.md`、`*_REPORT.md`、generic 命名文件不再与根入口竞争

当前批次进展：

- 已把 `docs/plans/2026-03-24-l0-docs-closeout-roadmap.md`、`task_plan.md`、`findings.md`、`progress.md`、`workers/worker1.md` 同步到同一阶段，避免状态继续散落在聊天上下文里。
- 已复核 `tests/fafafa.core.mem`、`tests/fafafa.core.lockfree`、`tests/fafafa.core.fs`、`tests/fafafa.core.term`、`tests/fafafa.core.term.ui` 与对应 `examples/` 根 README，确认 touched root/umbrella 目录都具备当前 README。
- 已对 `Phase 109-111` 触达文件跑定向 `prettier`、`git diff --check`、`git diff --no-index --check /dev/null workers/worker1.md` 与 README 结构扫描。
- closeout 后补做的 3 个脚本修复，先被纳入最小 smoke；随后 `tests/test_example_entry_scripts.sh` 已扩成 targeted current-entry runner contract scan，当前会锁定 `fs` / `lockfree` / `term.ui` 在 `examples/tests` 下的主入口接线。
- 扩展扫描过程中又修复了 `tests/fafafa.core.term.ui/BuildOrTest.sh` 的 cwd 依赖与无效错误处理，使它与其他稳定入口一样由脚本目录锚定项目和产物。
- 继续往下推进时，又修复了 `examples/fafafa.core.mem/BuildAndRun.sh`、`examples/fafafa.core.term/build_examples.sh`、`examples/fafafa.core.term/BuildOrRun_UI_Showcase.sh` 的 CRLF/bash 语法问题与 stale current-entry 接线；`tests/test_example_entry_scripts.sh` 也已同步扩到 `mem` / `term` 的 stable current-entry。
- 最后一轮继续把同类 targeted scan 扩到 `time` / `thread`：`time` 的 tests/examples root README 已补齐并与当前 runner 对齐；`thread` 的 Windows test runner 也已修掉 `smoke` 分支中的硬编码 `lazbuild` 路径与 fallthrough 问题。
- 再往下一轮确认 `benchmark` 已经具备可纳入 gate 的 root current-entry：tests 侧 shell runner 已收回到 wrapper/PATH fallback，Windows 侧新增 `BuildOrTest.bat` 供 `run_all_tests.bat` 发现；examples root `buildOrRun.bat` 与 `quick-runner.bat` 里的硬编码工具路径也已清掉。
- closeout 后继续按“Windows 可见度”补小批时，又确认 `tests/run_all_tests.bat` 只会发现 `BuildOrTest.bat` / `BuildAndTest.bat`；`tests/fafafa.core.time/` 之前只有小写 `buildOrTest.bat`，因此已补上 `BuildOrTest.bat` wrapper，并同步 README 与 contract scan，避免 `time` 被 Windows 仓库级跑批漏掉。
- 再继续沿同一路径往下扫时，又把 `option` / `result` / `process` 三个目录收进同一范式：都补上 `BuildOrTest.bat` wrapper、tests 根 README，并把 wrapper/impl 合同纳入 targeted scan，避免这三个目录继续被 Windows 仓库级跑批漏掉。
- 再继续收尾 `env` / `test` / `test.min` 时，又确认 `env` 并不存在新的 Windows wrapper 缺口；这批真正需要补的是 tests 根 README 与 shell runner 漂移。`tests/fafafa.core.env/README.md`、`tests/fafafa.core.test/README.md` 已补齐，`tests/fafafa.core.test.min/README.md` 已按 root validation / interactive sidecar 分层重写；`tests/fafafa.core.test/BuildOrTest.sh` 与 `tests/fafafa.core.test.min/BuildOrTest.sh` 也已统一回 `tools/lazbuild.sh` / PATH fallback，并纳入 targeted scan。
- 再继续把同一范式扩到 `xml` / `toml` / `json` 时，又确认这三者的主缺口不在 Windows wrapper，而在 tests 根入口说明和 shell runner 漂移：`xml` README 已改写为 current-entry 页，`toml` / `json` README 已补齐；同时 `json` shell runner 已从 cwd-sensitive + debug-only 可执行路径收回到 `tests_json.lpi -> bin/tests_json[.exe]` 的统一入口，并纳入 targeted scan。
- 再往下一轮又把同类 current-entry 收口扩到 `args.base` / `os` / `mem.allocator.mimalloc`：`args.base` 的 shell runner 已去掉硬编码 `--lazarusdir`，`os` 已修回 `bin/tests_os[.exe]` 合同并补上 Windows root wrapper，`mem.allocator.mimalloc` 也已收回 explicit project/executable/DLL contract 与 tests 根 README。
- 继续往下时，又把 `args.config` / `mem.manager.rtl` / `mem.manager.crt` 收进同一范式：旧 shell/batch runner、Windows root wrapper 缺口与 tests 根 README 缺口都已补齐，并统一到 today root contract。
- 真正开始回跑这些目录的 shell tests 后，额外暴露了一个控制面问题：broad `src/* Warning/Hint` gate 会被 unrelated `simd` warning 误伤；因此当前 `args` / `os` / `mem` 这批 root runner 的 build-log 检查已经统一收回到模块局部 `src/` 范围。
- `mem.allocator.mimalloc` / `mem.manager.rtl` / `mem.manager.crt` 的真实回跑还确认 Lazarus 在 Linux 下可能产出 non-suffixed 可执行名，因此 runner 现在会优先尝试 debug 命名产物，同时兼容 fallback 到默认目标文件名。
- 最新这批已经不再只是 static contract check：`args.base`、`os`、`args.config`、`mem.allocator.mimalloc`、`mem.manager.rtl`、`mem.manager.crt` 的真实 shell tests 都已通过。
- 因此，`Phase 111` 已完成；本轮 L0 文档治理已经完成 closeout，并给后续同学留下稳定的 current-entry 导航面。

## 执行约定

- 每完成一个 phase，都把结论同步到：
  - `task_plan.md`
  - `findings.md`
  - `progress.md`
  - `workers/worker1.md`
- 新增 README 一律沿用当前章节范式：
  - `## 当前 source-of-truth`
  - `## 当前目录结构` 或 `## 当前测试集合` / `## 当前示例入口`
  - `## 当前推荐入口`
  - `## 当前脚本行为`
  - `## 当前环境边界` 或 `## 当前边界`

## 当前结论

本路线图现在的 `105-111` 七个阶段已经全部收口完成：先收 `collections`，再收 `time/benchmark/thread`、`fs/mem/lockfree/term`，然后完成全仓 residual sweep 与根级验收；closeout 后补的示例/测试脚本缺口也已经继续演进成一轮 targeted current-entry runner contract scan，并已扩到 `mem` / `term` / `time` / `thread` / `benchmark` / `env` / `test` / `test.min` / `xml` / `toml` / `json` / `args.base` / `os` / `mem.allocator.mimalloc` / `args.config` / `mem.manager.rtl` / `mem.manager.crt`。同时，当前 `args` / `os` / `mem` 这一批 root runner 的 build-log gate 已经收回到模块局部范围，不再被 unrelated `simd` warning 误伤；最近一轮也已经用真实 shell tests 证明这些入口不是只有静态合同 green。

最新一轮又把这套范式继续扩到 `core.test` / `core.test.min` / `args.command` / `args.validation` / `args.help` / `args.errors`：`core.test` shell runner 的产物合同已经修回到真实 `bin/tests[.exe]`，`core.test*` 的 build-log gate 也已收回到 `fafafa.core.test*` 当前模块范围；四个 `args` 子模块则统一回 `tools/lazbuild.sh` / PATH fallback、模块局部 warning scope 与 tests 根 README。真实回跑时，这条新 gate 还顺手暴露并收掉了 `fafafa.core.test*` 自身的一批 Hint，因此现在这批入口已经不只是 contract green，而是带着真实 shell tests 的 current-entry green。

文档 closeout 已经正式转入真实代码修复阶段。第一条落地批次是 `docs/plans/2026-03-25-args-config-empty-string-preservation.md`：它修复了 `args.config` 在 JSON/TOML flatten 阶段把合法空字符串值误丢的问题，并补齐了模块级与 FPCUnit 集成级回归。后续如果继续推进，更适合直接在这些 runner-stable 的 L0 单元上做真实行为修复，或把仍残留 broad gate 的 runner（例如 `tests/fafafa.core.test/BuildOrTest.sh`）按同一范式收回到模块局部范围，而不是重新发明当前入口体系。

最新一轮已经把这条“真实 L0 修复”主线继续往下推进到 foundation 本身：`fafafa.core.bits`、`fafafa.core.layout`、`fafafa.core.endian` 已经落地为 strict L0 source-of-truth，原先散落在 `math.intutil`、`mem.layout`、`bytes` 中的 bit/layout/endian 语义现在分别收回到 compat / consumer 角色。同时，`tests/test_example_entry_scripts.sh` 也已把这三个新目录纳入 current-entry contract scan，因此这轮不是只有代码落地，也包括最小控制面的同步收口。当前已用 `bits/layout/endian` 自身 tests、`mem` / `bytes` compat 回归和 `TTestMathIntUtil` 定向 suite 证明这批改动是 green；唯一仍存在的是与本批无关的 `math` 全量 facade 规则失败。
