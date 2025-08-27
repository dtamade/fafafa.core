# fafafa.core.csv 规划与待办（Round 2）

更新时间：2025-08-12
负责人：Augment Agent

## 当前状态速览
- 模块单元已存在：`src/fafafa.core.csv.pas`（提供 Dialect、Reader/Writer/Builder、错误定位等，具备最小可用能力）。
- 测试工程已存在：`tests/fafafa.core.csv/` 下包含多组用例与一键脚本（未在本轮执行）。
- 全局配置集中于 `src/fafafa.core.settings.inc`，CSV 相关宏：`FAFAFA_CSV_STRICT_RFC4180`（默认启用）。Escape 行为完全由 Dialect.Escape 运行时控制（默认 #0 关闭）。

## 调研与基线（摘要，外部参考）
- 标准：RFC 4180（逗号、CRLF、双引号作为转义，字段计数一致）。
- FPC/Lazarus 生态：FCL 自带 csvreadwrite/csvdocument（随机/串行两类 API），支持 UTF-8 与本地代码页；Wiki 参考：Lazarus CsvDocument（2015 起并入 FCL）。
- 竞品模型：
  - Go `encoding/csv`: 可配分隔符、LazyQuotes、严格字段数；Reader/Writer 对称。
  - Rust `csv` crate: `ReaderBuilder`/`WriterBuilder`、header 处理、灵活方言、流式处理。
  - Java Commons CSV: `CSVFormat` 与 `CSVParser`/`CSVPrinter`，多方言与 header 映射。

## 设计目标（与现实现对齐）
- 接口优先、跨平台、可配置方言；默认严格 RFC4180，但允许选项放宽（LazyQuotes/可变字段）。
- Reader 提供 `ReadNext/ReadAll` 与精确行列定位；Writer 提供 Header 一次写入与正确的转义/换行。
- 读取端处理 UTF-8 BOM；写入端默认不写 BOM；不在库中输出中文（仅测试/示例以 UTF8 代码页）。

## 现有实现差距与改进点（MVP→稳定版）
- Reader 目前采用一次性加载 FData + 预留流式缓冲代码：
  - 计划在不破坏 API 下完善真实“分块流式”路径（避免超大文件占用内存）。
  - 校准行列定位在 CR/LF/CRLF 混用下的一致性（已有相应测试用例命名）。
- 严格字段计数：已支持 `AllowVariableFields` 与 header 后跳过严格性一次检查，需对齐测试边界。
- Escape 语义：默认使用双引号成对转义；可选独立 Escape 字符（由 Dialect.Escape 控制，默认 #0 关闭）。
- Writer 引号策略：`NeedsQuoting` 与 `QuoteAndEscape` 已实现，需补充边界用例（前后空格、分隔符、换行、多语言字符）。

## 宏与配置（统一集中于 settings.inc）
- `{$DEFINE FAFAFA_CSV_STRICT_RFC4180}`：默认严格；可在测试中通过 Dialect 放宽。
- `{$DEFINE FAFAFA_CSV_DISABLE_READER}` / `{$DEFINE FAFAFA_CSV_DISABLE_WRITER}`：按需裁剪体积（默认关闭）。
- 删除 `{$DEFINE FAFAFA_CSV_ENABLE_ESCAPE}` 宏；统一由 Dialect.Escape 控制独立 Escape（默认关闭）。

## 交付物清单（维持不变）
- 核心代码：`src/fafafa.core.csv.pas`
- 测试工程：`tests/fafafa.core.csv/`（覆盖 Reader/Writer、方言、错误路径）
- 示例工程：`examples/fafafa.core.csv/`
- 文档：`docs/fafafa.core.csv.md`
- 临时验证：`play/fafafa.core.csv/`

## 下一步任务（建议顺序）
1) 对齐需求选项（通过 寸止 确认）：默认方言（RFC4180/Excel/Unix）、默认 `HasHeader` 与 `TrimSpaces`、流式读取优先级（Escape 由 Dialect.Escape 控制，默认关闭）。
2) 完成 Reader 真流式实现路径，确保与单次加载路径一致（含 BOM 与混合换行）。
3) 覆盖 Writer 边界行为（标题只写一次、CRLF/ LF、引号规则、空字段）。
4) 审核与补齐测试用例映射，确保每个公开接口与宏配置均有测试。
5) 文档与示例补齐（最小示例 + API 列表 + 常见方言配置）。

## 风险与注意事项
- 巨大文件的内存占用与性能：需要真实流式解析路径以降低峰值内存。
- 不同方言与 Excel 兼容性：默认 RFC4180；Excel 区域性分隔符（如分号）交由 Dialect 配置。
- Windows 路径与中文：库层不输出中文；测试/示例文件使用 `{$CODEPAGE UTF8}`。

## 进度与日志
- 2025-08-11：完成需求梳理与 API 草案，创建初版规划。
- 2025-08-12：完成代码与测试现状盘点；完成外部资料梳理；制定改进路线与确认项清单。

## 本轮总结与计划（2025-08-12）
- 决策确认：1A 2A 3A 4A（严格 RFC4180、独立 Escape 由 Dialect.Escape 控制且默认关闭、先做真实流式、先跑测试）。
- 执行进展：
  - 修复 ParseRecord 内部 BufLen 作用域问题以恢复编译（不改变外部 API）。
  - 使用 tests/fafafa.core.csv/BuildOrTest.bat 成功构建，运行测试显示有 1 个失败（输出为 "...F.."，fpcunit plain 输出最小化，待进一步定位具体用例）。
  - 现有 Reader 已走 64KB 分块路径（EnsureBuffered + BOM 跳过）并通过多数用例；Writer 通过基础与边界多数用例。
- 下一步（按优先级）：
  1) 通过更详细的测试运行参数或单测定位，精确找出失败的用例名称与断言（可能与 CR-only 行/位置计数/Writer Header 行为相关）。
  2) 完成 Reader 真流式路径的细节校准：
     - CR/LF/CRLF 混合下的 FLine/FCol 与 FRecordStartLine/Col 的一致性；
     - 末尾 EOF 与懒引号的边界处理；
     - TryGetByName 与 header 严格字段数跳过一次的交互覆盖。
  3) Writer 边界：仅写一次 Header、CRLF/LF 输出一致、引号翻倍、前后空格与分隔符包含场景。
  4) 补充文档中的“流式实现说明”与示例，保持 docs/fafafa.core.csv.md 与实现一致。
- 风险与建议：
  - 测试输出目前未直接打印失败详情，建议在批处理脚本中增加 --format=xml/junit 输出到文件或 -p 运行，并将失败用例名写入 last-run.txt，便于 CI 与本地排查。


## 本轮更新（2025-08-13）
- 研究综述（参考竞品与标准实践）：
  - RFC 4180：逗号分隔、字段可用双引号包裹，内部双引号以两连表示；默认换行为 CRLF，允许最后一行无换行；严格字段数常见。
  - Go encoding/csv：Comma/FieldsPerRecord/LazyQuotes/TrimLeadingSpace/ReuseRecord；Reader/Writer 对称、流式；默认严格计数（-1 表示不检查）。
  - Rust csv crate：ReaderBuilder/WriterBuilder、headers 可选、灵活分隔与引号、无 BOM 输出、支持流式与 serde。
  - Java Commons CSV：CSVFormat（多方言预设）+ CSVParser/CSVPrinter，header 映射便捷；Excel/Unix/RFC 等预设。
  - FPC CsvDocument：提供 csvdocument/csvreadwrite，UTF-8 支持，偏一次性载入；生态常见但接口不够现代化。
- 现状评估：
  - 已具备方言、Reader/Writer/Builder、BOM 跳过、严格字段与 LazyQuotes、TrimSpaces、HasHeader、CRLF/LF 输出选择。
  - Reader 已走 64KB 分块流式读取；行列定位和 CR/LF/CRLF 混合与严谨度需再对齐测试。
  - Writer 支持首行 header 一次性写入与必要转义；Flush/Close 在 Windows 上释放句柄以利读取。
- 待确认决策：
  1) 是否建议在特定方言中开启 Escape（宏已移除，统一由 Dialect.Escape 运行时控制，默认关闭以保持 RFC4180 简洁模型）。
  2) Excel 方言是否默认 TrimSpaces=False、UseCRLF=True；Unix 方言 UseCRLF=False。
  3) 默认 HasHeader=False（与竞品一致）。
- 下一步行动（建议）：
  1) 跑通 tests/fafafa.core.csv 全量测试，捕获失败用例名称与断言文本。
  2) 校准 Reader 在 CR-only/混合换行/EOF 边界的行列与字段发出逻辑；保持严格/宽松模式一致性。
  3) 审核 Writer 边界（仅一次 Header、尾随分隔符、空字段、前后空格引号规则）。
  4) 文档与示例补齐；完善一键脚本输出 junit/xml 便于定位问题。
- 风险：超大文件的边界与地区性 Excel 方言（分号分隔）由 Dialect 解决；需在文档中明确。
