# fafafa.core.toml TODO（迭代式维护清单）

更新时间：2025-08-14（已多轮推进）
负责人：Augment Agent（fafafa.core.toml 模块开发与维护）

## 现状与目标
- 已建立模块骨架、最小解析器与 Writer（string/int/bool），Root 为 ITomlTable；查找优化为开放定址哈希；测试工程轻量稳定。
- 模块职责：提供 TOML 1.0.0 规范兼容的解析与序列化能力，作为 fafafa.core 配置基础模块；接口优先、跨平台、可扩展。
- 设计基线：对标 Rust/Go/Java 标准库风格（Rust `std::fs`/`serde` 风味、Go `encoding`/`os`, Java NIO/Files 的 API 观感）。

## 技术调研结论（简要）
- 规范：TOML v1.0.0（官方：https://toml.io/en/v1.0.0/）
- 核心特性：
  - 基本类型：String（基本/多行/字面量）、Integer、Float、Boolean
  - 日期时间：OffsetDateTime、LocalDateTime、LocalDate、LocalTime（RFC 3339 家族）
  - 结构：Array、Table、Inline Table、Array of Tables、Dotted Keys
  - 注释：以 `#` 开头
- Pascal 生态：已发现 toml-fp（https://github.com/ikelaiah/toml-fp），可作为对照用例；我们坚持自研接口与实现以保持一致风格与依赖可控。

## 架构与接口草案（接口优先）
- 单元名：`src/fafafa.core.toml.pas`
- 依赖：`fafafa.core.base`, `fafafa.core.mem.allocator`（可选：支持自定义内存分配）
- 类型与接口（命名可能微调）：
  - `TTomlValueType = (tvtString, tvtInteger, tvtFloat, tvtBoolean, tvtOffsetDateTime, tvtLocalDateTime, tvtLocalDate, tvtLocalTime, tvtArray, tvtTable)`
  - `TTomlErrorCode = (tecSuccess, tecInvalidParameter, tecInvalidToml, tecDuplicateKey, tecTypeMismatch, tecMemory, tecFileIO)`
  - `TTomlError = record ... end`（含行列、偏移）
  - `ITomlValue`（不可变）/`ITomlDocument`、`ITomlMutableValue`/`ITomlMutableDocument`（与 JSON 模块风格对齐）
  - Reader Flags：`TTomlReadFlags = set of (trfDefault, trfAllowAsciiOnly, trfAllowMixedNewlines, trfStopWhenDone)`
    - 严格遵循 v1.0.0；额外 Flags 仅限实现层行为（如流式读取、停止条件），不引入非标语法
  - Writer Flags：`TTomlWriteFlags = set of (twfDefault, twfPretty, twfSortKeys, twfSpacesAroundEquals)`
- API 门面：
  - Parse：`function Parse(const AText: RawByteString; out ADoc: ITomlDocument; out AErr: TTomlError): Boolean;`（重载：Stream/FileName）
  - Serialize：`function ToToml(const ADoc: ITomlDocument; const AFlags: TTomlWriteFlags = []): RawByteString;`
  - 查询：`TryGetXxx`（整型/浮点/字符串/布尔/日期时间）、`Get`, `Contains`, `Keys`, `Item[...]`（表/内联表/数组访问）
  - 变更（可选模块化）：`Add`, `Set`, `Remove`, `EnsureTable`, `Push`（数组）

## 规范与约束
- 统一宏配置入口：`src/fafafa.core.settings.inc`（不新增独立 inc），计划增加：
  - `{$DEFINE FAFAFA_TOML_VALIDATE_UTF8}`（默认开）
  - `{$DEFINE FAFAFA_TOML_DISABLE_READER}` / `{$DEFINE FAFAFA_TOML_DISABLE_WRITER}`（默认关）
- 代码风格：
  - 所有局部变量使用 `L` 前缀（如 `LIndex`, `LResult`）。
  - 关键逻辑中文注释，异常信息可验证。
- 错误处理：拒绝重复键（遵循规范；允许“数组表”的合法多次声明），给出精确行列与错误原因。

## TDD 策略
- 测试工程：src/tests/toml_tests.lpi；输出：bin/ 可执行，lib/ 中间产物。
- 构建脚本：src/tests/BuildOrTest.bat（直接调用 lazbuild 构建并运行 --all）。
- 测试单元（已落地）：
  - test_toml_basic.pas（Global + Smoke）
  - test_toml_datetime_basic.pas（Offset/Local Date/Time）
  - test_toml_inline_array_tables.pas（Inline Table / Array of Tables）
  - test_toml_string_number_enhanced.pas（字面量/多行字符串、数字下划线）
- 规则：先写测试再实现，小步快跑；尽量保持 N:通过、E/F:0；异常用断言与宏控制。

## 里程碑与交付（更新）
- M1 基础可用（完成）
  1) 测试骨架与构建脚本（已完成）
  2) 解析核心：键值/字符串/整数/布尔/注释（已完成）
  3) Writer 最小实现（已完成）
- M2 增量完善（进行中）
  1) 查找性能优化：开放定址哈希（已完成）
  2) dotted keys 与 [table] 头解析（已完成，含冲突检测）
  3) 字符串解析增强：字面量/三引号多行、数字下划线（已完成）
  4) Writer 保持紧凑输出，后续再支持嵌套序列化（进行中）
  5) Writer 最佳实践：默认紧凑等号；twfSpacesAroundEquals 控制空格；数组以 [a, b, c] 输出，浮点含小数点/指数；twfSortKeys 排序、twfPretty 空行（已完成）

- M3 扩展与优化（待定）
  1) 流式 Reader（大文件）
  2) 分配器接入与零拷贝路径
  3) 性能基准与回归测试

## 风险与应对
- 语法细节易错（多行字符串、转义、日期时间）：严格用例驱动，先红后绿，小步提交。
- 键重复/表重开边界：实现状态机+作用域规则，所有分支写用例。
- 跨平台差异（换行/编码）：统一使用 UTF-8；测试覆盖 CRLF/CR/LF。

## 今日计划（下一步）
- 编写测试工程骨架与首批 Reader 用例（键值、字符串、数字、布尔、注释）。
- 起草 `fafafa.core.settings.inc` 的 TOML 相关宏提案（仅文档，不改动代码）。
- 输出 API 草案与最小门面函数声明（文档）。



## 本轮工作总结（2025-08-12 / 需求梳理+规划）
- 已完成：
  - 在线调研 TOML v1.0.0 规范要点（键/值、dotted keys、表/内联表、数组表、日期时间族）。
  - 审阅现有实现与测试：Reader 已覆盖 string/int/bool、数组（整型/字符串/布尔，单层）、dotted keys、重复键检测；Writer 递归输出并支持 twfSortKeys/twfPretty/twfSpacesAroundEquals（当前默认输出含空格）。
  - 确认工程脚手架与一键测试脚本（tests/fafafa.core.toml/BuildOrTest.bat）可用。
- 发现的问题：
  - 文档对 twfSpacesAroundEquals 的描述与实现/测试不完全一致（文档曾表述“默认紧凑”，当前实现与用例均为“默认含空格”）。
  - Reader 尚未接入 Float 读取（有 ReadFloat 原型但未在分支中使用），日期时间/内联表/[table] 头、数组表等也未实现。
  - Writer Float 输出为占位（0），需要实现 IEEE754 格式化；Spaces flag 目前等价于无效（默认即含空格）。
- 计划（短期）：
  1) 对齐文档与行为：将 docs 说明更新为“默认含空格；flag 预留显式控制策略”，暂不改变现有行为以保持测试稳定。
  2) 增量实现 Float 读取+写出（按 TOML v1.0.0 小数/指数语法，错误用例回退/报错策略测试驱动）。
  3) 引入 [table] 头解析，与 dotted keys 一致化处理，防止重复定义；补充用例。
  4) 预研并排期：日期时间族、Inline Table、Array of Tables（逐步 TDD）。
- 备注：继续坚持接口优先（ITomlValue/ITomlTable/ITomlDocument），兼顾性能（当前开放定址哈希保持插入顺序）。


## 本轮工作总结（2025-08-13 / 功能完善 + 回归全绿）

## 本轮工作总结（2025-08-14 / AoT 顺序稳定 + Builder 最小 API + 全量绿）
- 已完成：
  - Writer：数组表 [[path]] 与常规子表 [path] 的输出顺序稳定为“标量 → AoT → 子表”，与快照一致；数组与浮点输出规范化（1 → 1.0；数组元素逗号后空格在 Pretty/Space 模式下开启）。
  - Reader：在 [[a]] 之后的 [a.b] 会将 b 解析到 AoT 的最后一个表项，修复了之前上下文错误导致的快照不一致。
  - Builder：新增 EnsureArray(path)、PushTable(path) 两个最小 API；BeginTable 支持 dotted path 穿越 AoT（自动落到 AoT 最后一项，空数组会自动追加新表）。
  - Tests：
    - 新增 toml-writer-aot-nested-complex（2 例，覆盖 AoT 条目内含数组与子表）；
    - 新增 toml-builder-aot-basic（1 例，使用 Builder 构造 [[fruit]] + [fruit.info] 并比对快照）。
  - 回归：32/32 全绿。
- 最佳实践：
  - Writer
    - 默认紧凑等号：`key=value`；`twfSpacesAroundEquals` → `key = value`。
    - 打开 `twfPretty` 时段落之间插入空行；与 `twfSortKeys` 合用保持可读性与确定性。
    - 数组元素输出：`[a, b, c]`；浮点确保小数点或指数（如 `1` → `1.0`）。
  - Reader
    - AoT 与 [table] 头混用时，`[[a]]` 后续的 `[a.b]` 会指向 AoT 的“最后一项”。
  - Builder
    - 构造 AoT：`EnsureArray('a').PushTable('a')` 追加一项并切到该表；随后可直接 `PutXxx` 写键值。
    - 构造子表：`BeginTable('a.b')` 支持跨 AoT 自动落位；完成后 `EndTable` 返回上一层。
- 待办：
  - 扩展更多 AoT 混合层级快照（Compact/Pretty 两套），覆盖数组内再含 AoT 的场景。
  - 将 Builder 示例提炼为文档示例片段，并在 README/开发指南中引用。

- 已完成：
  - Reader：日期/时间族最小解析（Offset/LocalDateTime/LocalDate/LocalTime）；Inline Table、Array of Tables（含冲突）；字符串增强（单引号字面量、三引号多行）；数字下划线（整数/浮点）；错误定位统一（SetError / SetErrorAtStart）。
  - Writer：默认紧凑等号；Spaces flag 控制空格；浮点输出 '.' 小数点且保证含小数点/指数；数组标准形态 [a, b, c]；支持数组表 [[path]] 展开；Pretty 空行与 SortKeys 排序。
  - Tests：新增与调整多项快照与负例（flags、数组、数组表、时间类型、错误位置、数字下划线），合计 27 例，E:0 F:0。
  - 工程：新增独立 TOML 测试工程与一键脚本（src/tests/toml_tests.lpi，BuildOrTest.bat）。
- 遇到的问题：
  - 少量路径的错误定位风格需要统一，已通过辅助过程 SetErrorAtStart 收敛。
- 下一步计划：
  1) Writer 支持更深层嵌套与混合结构快照；
  2) Builder 增加 Push/EnsureArray 辅助 API（已于 2025-08-14 实现并通过用例）；
  3) 时间类型 Writer 固化 RFC3339 输出 + 快照；
  4) CI 跑全量，锁定快照稳定性。
- 备注：保持接口优先、小步快跑与稳定回归。


## 本轮工作总结（2025-08-12 / 立项复盘 + 基线验证）
- 已完成：
  - 扫描 src/ 与 tests/ 目录，核对现有接口、实现与测试布局。
  - 运行 tests/fafafa.core.toml/BuildOrTest.bat test 获取当前基线：45 例中 2 失败（Inline Table/Array of Tables 用例）。
  - 发现解析器在数组/数值分支附近存在结构性语法错误（编译器报错：行约 1336，“; 期望但遇到 ELSE”）。
- 问题与原因：
  - 在 else-if (P in ['{','[',...]) 分支内部，Inline Table 处理结束后多了一个多余的 end;，导致随后的“if P^='[' then ...”从属关系错误，引发语法冲突。
  - 脚本输出出现“Build successful”但之前有 lazbuild Fatal 编译错误日志，可能是 lazbuild 返回码/脚本判断存在不一致，需要后续核实。
- 下一步计划（短期 TDD）：
  1) 修复解析分支结构（去除多余 end;，将数组处理纳入同一分支），本地重建并跑回归。
  2) 对齐 Inline Table 与 Array of Tables 行为，补齐 Reader 路径写入与取值逻辑，使相关测试通过。
  3) 回归全部 Writer 用例，确认浮点与日期时间输出稳定。
- 风险与应对：
  - 分支结构修复容易牵动后续 Continue/Break 语义，修复后必须跑全量 TOML 用例回归。
