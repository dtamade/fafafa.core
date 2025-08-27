# 工作总结报告：fafafa.core.args

更新时间：2025-08-19
负责人：Augment Agent

## 本轮进展
- 基线核验：未做代码改动，完整回归 tests/fafafa.core.test，86/86 通过，退出码 0。
- 文档/现状复查：docs/fafafa.core.args.md 与 docs/fafafa.core.args.command.md 与实现一致；选项开关、no- 前缀、Windows 兼容规则与测试一致。

- 历史记录（上轮）：
  - 文档：补强“Compatibility Notes”“Source Precedence (recommended)”小节，新增 CONFIG→ENV→CLI 合并示例（含 TOML/JSON 条件编译宏），补充 StopAtDoubleDash=False 与 Windows/Unix 混合示例。
  - 示例：完善 example_env_merge 的 README，说明宏开关、CONFIG 拍扁规则、ENV 前缀惯例与优先级。
  - 测试：新增 1 条用例锁定 Windows 形式下带赋值的 no- 前缀与大小写不敏感组合的“后写覆盖”语义；并回归全量测试。

- 测试基线
  - 执行：tests/fafafa.core.test/BuildOrTest.bat test
  - 结果：86/86 通过；退出码 0

## 本轮代码改动（Windows 宽字符 argv）
- 新增宏：FAFAFA_ARGS_WIN_WIDE（默认启用）
- Windows 下 FromProcess 通过 CommandLineToArgvW 收集 argv 并统一转 UTF‑8，避免本地代码页误读；失败回退 ParamStr
- 非 Windows 平台不受影响；解析语义不变

## 验证
- 执行：tests/fafafa.core.test/BuildOrTest.bat test
- 结果：91/91 通过；退出码 0

## 本轮代码改动（ENV 过滤与规范化扩展）
- 新增 API：ArgvFromEnvEx(Prefix, Allow, Deny, Flags)，保持 ArgvFromEnv 兼容不变
- 过滤：Allow（白名单，若非空仅包含其内键）→ Deny（黑名单进一步排除），均基于归一化键（去前缀、小写、'_'→'-'）
- 值规范化 Flags：
  - efTrimValues（去除值两端空白）
  - efLowercaseBools（TRUE/FALSE → true/false）

## 本轮代码改动（Usage 渲染选项增强）
- RenderUsageOptions 增加 showSectionHeaders、groupFlagsBy/groupPositionalsBy
  - 默认值保持兼容（true/gbNone）
  - 支持 gbRequired、gbAlpha 分组/排序策略
- 输出依然为纯文本，不引入 ANSI/颜色；wrap/width 行为不变

## 验证（Usage 扩展）
- 新增快照用例：usage_no_headers_w80
- 执行：tests/fafafa.core.test/BuildOrTest.bat test
- 结果：95/95 通过；退出码 0

- 新增测试：Test_core_env_filtering（4 项），跨平台设置环境变量（Windows.SetEnvironmentVariable / BaseUnix.FpSetEnv）

## 验证（ENV 扩展）
- 执行：tests/fafafa.core.test/BuildOrTest.bat test
- 结果：95/95 通过；退出码 0



## 关键改动摘要（代码）
- 新增：Windows 宽字符 argv 收集（FAFAFA_ARGS_WIN_WIDE，默认启用）；其余历史变更保留如下：
- src/fafafa.core.args.pas：
  - Windows “/” 形式在带赋值时（/no-xxx=value、/no-xxx:value），EnableNoPrefixNegation=True 时同步映射基础键（xxx）为该值，确保与长选项一致的“最后一次赋值覆盖”行为。
  - 其他解析规则保持不变。
- tests/fafafa.core.test/Test_core_args.pas：
  - 新增用例：Test_NoPrefix_Negation_Windows_CI_Override_LastWins。
- docs/fafafa.core.args.md：
  - 补充行为细节说明（合并顺序、no- 前缀、Windows 兼容）。
- examples/fafafa.core.args.command/example_env_merge/README.md：
  - Notes 中新增 Windows “/no-xxx=value/:value” 同步映射基础键并保持 last‑write‑wins 的说明。
- tests/fafafa.core.test 项目配置：
  - 规范化 helpers 引用：移除 LPR uses 中的直接单元引用，改为通过 LPI SearchPaths (helpers) 提供；移除 LPI Units 下的孤立条目，确保以 LPR 为主程序构建，生成 tests.exe 稳定。

## 验证
- 构建与测试：`tests/fafafa.core.test/BuildOrTest.bat test`
  - 退出码：0
  - 总测试数：86
  - 失败：0

## 遇到的问题与解决方案
- 本轮无新问题；历史问题与方案复述：
  - StopAtDoubleDash=False 的语义边界 → 保留 `--` 为位置参数并切换剩余为位置参数。
  - 负数值与下一个 token 判定冲突 → `--` 与 `/` 起始 token 永不作为值；`-` 起始仅在开关允许且为负数样式时作为值。
  - `--no-xxx` 与显式赋值覆盖 → 采用“最后一次赋值覆盖”，并在 Windows 形式带赋值时同步映射基础键。

## 后续计划与建议
- 文档微调（已完成）：新增“与 GetOpt/CustApp 的对比与迁移”小节与最小示例（docs/fafafa.core.args.md）
- 规划选项（不破坏现状）：
  - 自动 Usage/Help 渲染增强（保持“调用方决定是否打印”的原则）。
  - ENV 解析的白名单/黑名单过滤与类型提示（轻量）。
  - YAML 支持（ArgvFromYaml），待依赖成熟再推进。


## 本轮新增（args.command）
- 安全性：移除 Register 中对处理器的试探执行（不再 `Execute(nil)`）
- 语义：Register 仅合并别名/子树，不覆盖已存在处理器；目标无处理器时仅拷贝描述
- 测试：新增 2 项覆盖（FirstWins、NoExecuteOnMerge）
- 文档：新增 docs/fafafa.core.args.command.md
- 全量测试：41/41 通过


## 本轮新增（args.config）
- 新增 ArgvFromToml 最小实现：
  - 拍扁表为点分路径，键名小写并将 '_'→'-'
  - 标量 → --k=v；标量数组 → 重复 --k=v；复杂结构暂不处理
- 新增测试 Test_core_args_config（3 项）并纳入总测试工程
- 文档更新：docs/fafafa.core.args.md 增补 TOML 配置映射章节
- 回归结果：所有测试通过（除预期的演示失败/跳过用例不影响）

## 下一步计划
- ArgvFromJson：与 TOML 一致的映射与规则
- TOML 进一步扩展：array-of-tables 的路径与索引规范（如 items.0.name）
- 文档：给出 CONFIG/ENV/CLI 合并顺序的更详示例与注意事项


## 本轮策略选择（配置源未就绪）
- JSON / YAML / TOML 模块仍在开发中，默认不启用相关宏；库侧保持“仅 ENV + CLI”的稳定行为
- args.config.* 的文件映射 API 在未启用宏或解析失败时，统一返回空数组，不抛错、不打印日志，保证可预期降级
- 文档已新增“可选数据源与降级策略（最佳实践）”小节，明确合并顺序：CONFIG -> ENV -> CLI（后者覆盖前者）
- 示例已具备 example_env_merge，演示 ENV + CLI 合并（Windows/Unix 通用）
