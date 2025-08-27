# fafafa.core.settings.inc 统一与 CODEPAGE 清理计划（草案）

本计划旨在以最小风险、可回滚的方式，统一框架配置入口并清理库单元中的 CODEPAGE 宏，确保构建与行为一致性，同时保持对现有示例/测试的友好支持。

---

## 1. 现状与目标

- 现状
  - 存在两个配置文件：
    - src/fafafa.core.settings.inc（主线）
    - release/src/fafafa.core.settings.inc（发布目录）
  - 若工具链或工程文件引用不一致，可能导致宏定义差异与行为漂移。
  - 少数库单元（如部分 lockfree 单元）含有 `{$CODEPAGE UTF8}`，与“库单元不输出中文，不加 CODEPAGE”规范不符。

- 目标
  - 统一配置入口为：src/fafafa.core.settings.inc（单一真源，Single Source of Truth）。
  - 移除库单元中的 CODEPAGE 宏；仅在示例、测试、工具脚本中保留。
  - 保持跨平台构建一致性；最大限度兼容现有脚本与工程。

---

## 2. 原则与边界

- 原则
  - 文档先行、小步落地、可回滚。
  - 不破坏现有对外 API 与门面；默认构建保持稳定。
  - 条件编译宏命名前缀统一：FAFAFA_*，避免歧义。

- 边界
  - 本轮不直接修改 src 代码与设置，仅提交计划与清单。
  - 后续以小 PR 执行，每次仅改一小类文件并验证构建。

---

## 3. 统一策略（settings.inc）

- 单一真源：src/fafafa.core.settings.inc
- 引用规范：
  - 所有单元使用相对包含：`{$I fafafa.core.settings.inc}`，前提是工程/搜索路径包含 src 目录。
  - Lazarus LPI/LPR 中的 OtherUnitFiles/IncludeFiles 保证含 `../../src` 或等效路径。
- 发布目录策略：
  - release/src/fafafa.core.settings.inc 改为软链接/镜像（可选），或在发布流程中从 src 复制生成；不再手工维护两份内容。
- 宏分层建议：
  - Core 特性宏：FAFAFA_CORE_*（如分配器、内联、匿名函数开关）
  - 模块特性宏：FAFAFA_PROCESS_*、FAFAFA_TERM_*、FAFAFA_SOCKET_* 等
  - 测试/压力宏：FAFAFA_CORE_ENABLE_CONCURRENCY_TESTS、FAFAFA_CORE_ENABLE_STRESS_TESTS（仅 tests 下解析）

---

## 4. CODEPAGE 清理策略

- 规范
  - 库单元（src/*）不加入 `{$CODEPAGE UTF8}`；默认由编译器/工程字符集处理。
  - 示例（examples/*）、测试（tests/*）、临时验证（play/*）可保留 `{$CODEPAGE UTF8}`，用于中文输出与终端兼容。
- 执行步骤
  1) 扫描 src 目录，列出含 CODEPAGE 宏的单元清单。
  2) 分批移除，并在 PR 中说明“无中文常量输出/日志”，不影响行为。
  3) 若个别库单元确需中文（不建议），改由资源或常量转义，避免依赖 CODEPAGE。

---

## 5. 分阶段落地计划

- Phase A：工程对齐（不改源码）
  - 检查所有 LPI/LPR：SearchPaths.IncludeFiles/OtherUnitFiles 是否包含 `../../src`。
  - 确认 tests/examples 的构建脚本在 Debug/Release 下均包含 src。

- Phase B：settings.inc 单源化
  - 将 release/src/fafafa.core.settings.inc 改为镜像生成（CI/CD 发布脚本负责复制）。
  - 在 README/CI 文档中注明“禁止直接编辑 release 下的 settings.inc”。

- Phase C：CODEPAGE 清理（小步）
  - 批次 1：lockfree 相关库单元的 CODEPAGE 移除；构建与 tests 回归。
  - 批次 2：其余子系统（mem/fs/thread/term 等）按模块逐步清理。
  - 每批次均运行现有 BuildOrTest 脚本，保留失败回滚预案。

- Phase D：CI 校验与守护
  - 在 CI 中加入：
    - 检查 release/src/fafafa.core.settings.inc 与 src 版本一致（或不存在差异）。
    - 检查 src/* 不得出现 `{$CODEPAGE` 宏（白名单除外：无）。

---

## 6. 风险评估与缓解

- 可能风险
  - 个别工程文件仍引用 release/src，导致找不到 settings.inc。
  - CODEPAGE 清理后，个别库单元的字符串常量若含中文（不应当），终端输出异常。
  - Windows 控制台编码差异导致示例/测试输出乱码。

- 缓解策略
  - 为受影响工程提供一次性修正（更新 OtherUnitFiles/IncludeFiles）。
  - 在 examples/tests 顶部保留 `{$CODEPAGE UTF8}`，并在脚本中设置 `chcp 65001`（Windows 环境可选）。
  - 文档、提交信息中明确变更范围与回滚方法。

---

## 7. 执行清单（建议）

- 文档与基线
  - [ ] 合并本计划到主文档索引（docs/README.md 链接）
  - [ ] 在模块 TODO 中登记（lockfree 为起点模块）

- 工程与脚本
  - [ ] 审核所有 LPI/LPR 的 SearchPaths，确保包含 src
  - [ ] 审核 tools/lazbuild.bat 与各 BuildOrTest 脚本包含路径

- settings.inc 单源化
  - [ ] 调整发布流程：release/src 版本由 CI 从 src 拷贝生成
  - [ ] 在仓库贡献指南中注明“settings 只改 src 版本”

- CODEPAGE 清理（分批）
  - [ ] 批次 1：lockfree 子系统的库单元（不含 tests/examples）
  - [ ] 批次 2：mem 子系统
  - [ ] 批次 3：fs/thread/term 等其余模块

- CI 守护
  - [ ] 新增 CI 检查：settings.inc 一致性 & src 不得含 CODEPAGE 宏

---

## 8. 沟通与回滚策略

- 每一批次变更均形成变更说明与回滚说明（包含受影响工程列表、验证步骤）。
- 任一批次构建失败或测试回归，即刻回滚该批次并记录原因，后续以更小粒度推进。

---

## 9. 结论

通过统一设置入口与清理库单元 CODEPAGE，可以显著降低构建漂移风险、保证跨平台一致性，并为后续模块化与接口抽象提供稳定基础。计划采用“文档先行 + 小步验证 + CI 守护”的方式推进，确保安全可控。


## 10. 发布流程草案（CI/脚本层）

- 触发条件：打标签或主分支发布任务
- 步骤：
  1) 清理 release/src 目录
  2) 复制 src/fafafa.core.settings.inc -> release/src/fafafa.core.settings.inc
  3) 生成发布包并校验文件一致性

示例（PowerShell 伪代码）：

```powershell
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = Join-Path $root 'src/fafafa.core.settings.inc'
$dstDir = Join-Path $root 'release/src'
$dst = Join-Path $dstDir 'fafafa.core.settings.inc'
if (Test-Path $dstDir) { Remove-Item $dstDir -Recurse -Force }
New-Item -ItemType Directory -Path $dstDir | Out-Null
Copy-Item $src $dst -Force
# 校验
if ((Get-FileHash $src).Hash -ne (Get-FileHash $dst).Hash) { throw 'settings.inc mismatch' }
```

说明：仅示例；实际 CI 需要适配 Runner 环境（Windows/Linux）。
