# fafafa.core.test — 调研与方案（Round 1）

## 模块目标
为全仓库提供一致、可复用、跨平台的测试基础设施（infrastructure）：
- 提供标准化的测试 Runner 入口与输出格式（人类可读 + 机器可读XML/JUnit）。
- 提供常用测试工具：临时目录/文件管理、确定性随机、快照对比、时间与时钟抽象、重复性重试（针对不稳定异步）。
- 融合现有仓库实践（fpcunit + lazbuild + 目录规范），并可选支持 TestInsight（IDE 内快速反馈）。
- 面向后续模块按统一规范编写 Tests/Examples，提升收尾速度与一致性。

## 竞品与生态调研摘要
- FPCUnit（官方/维基）
  - TTestCase + RegisterTest + consoletestrunner/xmlreporter；支持 ITestListener 扩展。
  - OneTimeSetup/TearDown via testdecorator。
  - XML 输出（旧格式 + 类 DUnit2 风格，通过 xmlreporter）。
  - Lazarus 提供 GUI/Console Runner，TestInsight 支持（fpcunittestinsight）。
- Alternatives：DUnit2 / FPTest
  - 功能更强，但对 FPC/Lazarus 的无缝程度与现有仓库风格不完全一致；
  - 当前仓库已经大量使用 fpcunit，切换成本高，不建议短期更换核心框架。
- 结论
  - 以 FPCUnit 为核心；利用 ITestListener 扩展统一输出；可选接入 TestInsight；
  - 将“测试工程脚手架 + 运行脚本 + 输出目录规范”标准化并模板化。

## 与本仓库现状的对齐
- 已有：src/tests/* 使用 fpcunit 与 RegisterTest；tools/lazbuild.bat；tools/test_template.bat；统一 bin/lib 输出；
- 方案：保持现有构建与目录规范，新增统一化 Runner/Utils/Listener，给各模块测试工程复用。

## 拟定模块边界与组成
- 单元划分（初版）：
  1) fafafa.core.test.runner
     - 封装标准化的启动逻辑：
       - 优先检测 TestInsight（IsTestinsightListening/RunRegisteredTests）。
       - 否则走 Console Runner：支持 --all、--format（plain/xml/junit）等参数；
       - 统一环境变量/参数开关（如 TEST_FORMAT, TEST_SEED, TEST_SNAPSHOT_UPDATE）。
  2) fafafa.core.test.utils
     - 临时目录/文件（如 EnsureTempDir, WithTempDir 自动清理）；
     - 确定性随机（SetDeterministicSeed/GetSeed）；
     - 轻量断言包装（RequireTrue/RequireEquals：在消息中输出调用点与上下文）；
     - 小型 TestClock 接口：IClock/Now()，并提供 FixedClock/MonotonicClock，便于时间相关测试。
  3) fafafa.core.test.snapshot
     - 快照测试工具：
       - CompareSnapshot(name, actual, normalizer?, options)；
       - 约定快照目录：tests/<module>/snapshots/；
       - 支持环境变量 TEST_SNAPSHOT_UPDATE=1 时更新基线；
       - 针对文本/JSON/TOML 提供简单标准化（行尾、空白、排序器）。
  4) fafafa.core.test.listener.junit（或 xml）
     - 基于 xmlreporter 的适配层，输出 JUnit 兼容文件（用于 CI 汇总，后续接 Jenkins/GitLab）。
  5) fafafa.core.test (facade)
     - 对外统一导入（uses）与常量开关；集中 {$I src/fafafa.core.settings.inc}；

- 命名与风格
  - 倾向 Rust/Go/Java 的 API 外观：轻量、纯函数、清晰职责；
  - Pascal 实现以接口优先（如 IClock），便于替换与扩展；
  - 不在库代码单元输出中文；仅测试/示例若需中文输出时加 {$CODEPAGE UTF8}。

## 构建与目录规范（沿用并标准化）
- 测试工程：tests/fafafa.core.test/
  - 工程文件：tests_fafafa.core.test.lpi（Debug 配置，启用内存泄漏检查）。
  - 输出：bin/tests.exe；中间产物：lib/
  - 一键脚本：BuildOrTest.bat / BuildOrTest.sh（基于 tools/lazbuild.bat；先清理再构建；可参数 test）。
- 示例工程：examples/fafafa.core.test/
  - example_fafafa.core.test.lpi；输出到 examples/.../bin 与 lib。
- 临时验证：play/fafafa.core.test/

## 最小可行集（Milestone 1）
- runner + utils 的最小实现（无外部依赖，仅 FPC/Lazarus 自带包）。
- 提供 XML/JUnit 输出（通过 xmlreporter；JUnit 兼容度先覆盖常见字段）。
- snapshot：先支持“文本/JSON（保持稳定排序）”两类。
- 创建测试工程（fpcunit 自测 runner/utils/snapshot），脚本齐备，CI-ready。

## 可选增强（后续里程碑）
- TestInsight 自动检测与切换（IDE 直联快速反馈）。
- 数据驱动测试（表格/CSV/JSON 驱动）；
- 简易 property-based 试验工具（有限随机、多轮次）与失败收敛报告；
- 并行/分片执行（按套件拆分并在 CI 并行 Job 跑）。

## 风险与约束
- JUnit 兼容性：需与目标 CI 对齐（如 GitLab/Jenkins）字段映射验证。
- 快照更新策略：严格管控开关，避免 CI 环境误更新。
- 兼容 Windows/Linux 的路径与换行规范（文本快照归一）。

## 下一步（待确认后执行）
1) 建立 tests/fafafa.core.test/ 工程与脚本。
2) 实现 runner/utils/snapshot/listener 四个单元的 v0 版。
3) 编写 fpcunit 覆盖：所有公开 API/路径；
4) 在 docs/ 新增 fafafa.core.test.md（API 用法与示例）；
5) 选择 1–2 个现有模块试点迁移到新 Runner（验证可用性并收集改进点）。



## Rust 与 Go 单元测试框架要点与借鉴（补充）

- Rust（cargo test / 内建测试框架）
  - 关键特性：#[test]、#[should_panic]、#[ignore]、#[cfg(test)]、模块化 tests mod；并行执行默认开启；doctest（文档示例可执行）；社区常用 property-based（proptest/quickcheck）；基准常用 criterion。
  - 借鉴点：
    - 编译期隔离测试代码（等价 Pascal 中保持库代码与测试代码分离，测试放在 tests/ 工程）。
    - 断言宏风格（assert_eq!/panics）→ 我们提供 Assert/Require/Throws 等；支持“应当抛出”语义。
    - Doctest 思想 → 用 examples/ 工程+脚本自动化验证示例；不把示例编进库单元。
    - Property-based 思想 → 作为 v2 目标提供 CheckAll/Generators。
    - 默认并行 → 我们在 Runner 层提供可选并行度与资源隔离（TempDir、独立 RNG）。

- Go（testing 包 / go test）
  - 关键特性：TestXxx(t *testing.T)、子测试 t.Run、表驱动用例、t.Helper/t.Cleanup、t.TempDir、t.Parallel；BenchmarkXxx、ExampleXxx、Go 1.18+ FuzzXxx；标签/过滤由命名与 -run/-bench/-tags 控制。
  - 借鉴点：
    - ITestContext ≈ t *testing.T：统一断言、子测试、资源、日志、跳过。
    - 子测试与表驱动 → ctx.Run(name, proc) + Registry.CaseOf<T>(cases, proc)。
    - 资源管理 → TempDir/Cleanup 内建；快速定位失败（Helper 语义通过报告调用点实现）。
    - 并发 → t.Parallel 思想移植到 Runner 的并行度控制与测试级并发标记。
    - 基准与 Fuzz → 保持与单测解耦（现有 fafafa.core.benchmark 负责基准；Fuzz/Property 进 v2）。

## 我们的架构选型（基于 Rust/Go 综合）

- 对外范式：以 Go 风格为主（t *testing.T → ITestContext），配合 Rust 的“应 panic/文档示例/并行默认可选”理念。
- 兼容层：保留 fpcunit 类 + published 方法模式（平滑迁移），同时提供函数式注册 + 子测试现代 API。
- Runner/Listener：解耦执行与输出（Console + JUnit XML），后续可加 JSON/Digest；可选 TestInsight。
- 上下文：
  - ctx.Assert/Require/Check、ctx.Run（子测试）、ctx.TempDir/TempFile、ctx.Cleanup、ctx.SeededRng、ctx.Clock、ctx.Log/Skip/Tags。
  - 支持“应当抛出/应当失败”路径（Rust #[should_panic] 对应 Throws/ExpectPanic）。
- 并行与隔离：Runner 支持 --parallel；每个测试拿到独立临时目录、随机种子；避免快照/文件写入互相影响。
- 表驱动：Registry.CaseOf<T>(cases, proc) + 名称模板，失败报告带上用例名/索引。
- 快照：文本/JSON 归一化（换行/空白/键排序），本地显式 TEST_SNAPSHOT_UPDATE=1 才允许更新；CI 禁止更新。
- 计划路线：
  - v0：Runner/Listener/Context/子测试/表驱动/TempDir/RNG/Clock/快照（文本+JSON）。
  - v1：条件与假设（Assume）、并行优化、TestInsight、自定义参数解析器。
  - v2：Property-based/Generators、Fuzz 适配、并行分片执行。
