# fafafa.core.ini

现代化、高性能、跨平台的 INI 解析与写出模块。遵循本仓库已有风格，强调：
- 跨平台一致性（UTF-8 优先、明确换行策略）
- 可维护与可替换（接口优先，内部实现可演进）
- 保序/可回放与可重组兼顾（按节粒度 dirty）

## 能力概览
- 解析
  - 支持 [section]、key=value 与 key: value 两种分隔
  - 引号感知：KV 分隔及行内注释会忽略引号内的符号（=/: 与 ;/#）
  - 行内注释：可选 irfInlineComment，开启时剔除 ;/# 后内容
  - 默认节：允许无显式 [section] 的键，前导注释/空行归属文档级 Prelude
- 写出
  - 按节粒度 dirty：未改节严格回放 BodyLines，已改节按写出 Flags 重组输出
  - 换行在生成阶段确定：iwfForceLF → LF；否则使用系统 LineEnding
- 编码
  - 输入统一视为 UTF-8；ParseStream/ParseFile 支持 UTF-8 BOM、UTF-16 LE/BE 自动识别与转换到 UTF-8
  - 输出默认 UTF-8（无 BOM）；可用 iwfWriteBOM 写出 UTF-8 BOM（EF BB BF）
- 错误定位
  - 统一补齐 Err.Line/Column/Position，包含：未闭合节头、空键、未闭合引号、节头尾随非法字符等

## 公共接口（简要）
- IIniSection（只读视图）
  - Name, KeyCount, KeyAt
  - TryGetString/Int/Bool/Float
- IIniDocument（读写门面）
  - SectionCount, SectionNameAt, GetSection
  - TryGet*/Set*
  - HasKey、RemoveKey、RemoveSection（增量 API）
  - ToIni（见写出 Flags）

## 写出/读取 Flags（补充）
- 写（TIniWriteFlags）
  - iwfSpacesAroundEquals：在分隔符两侧留空格
  - iwfPreferColon：优先使用 ':' 作为分隔符
  - iwfBoolUpperCase：布尔字面量 TRUE/FALSE
  - iwfForceLF：统一使用 LF 换行
  - iwfWriteBOM：ToFile 写出 UTF-8 BOM（EF BB BF）
  - iwfStableKeyOrder：节已脏、需要重组时对键名排序，获得稳定顺序；未脏回放不改顺序
  - iwfTrailingNewline：在输出末尾确保存在一个换行（仅当输出非空时生效）；与 iwfForceLF 协同作用
  - iwfNoSectionSpacer：不在每个节后自动追加空行，适合紧凑格式
  - iwfQuoteValuesWhenNeeded：当值包含分隔符(=/:)、注释符(;/#)、或首尾空格时按需加双引号，避免解析歧义（更通用、更稳健）
  - iwfQuoteSpaces：值中包含任意空格或制表符时加引号（更严格的规范化写出）
- 读（TIniReadFlags）
  - irfInlineComment：开启行内注释（; 或 #）。默认会在值外层为成对引号时去除外层引号（简单版，无转义）
  - irfAllowQuotedValue：与 irfInlineComment 配合使用时，保留外层引号，不做去除
  - irfStrictKeyChars：严格键名字符集，仅允许 [A-Za-z0-9_.-]
  - irfCaseSensitiveSections / irfCaseSensitiveKeys：大小写敏感
  - irfDuplicateKeyError：重复键报错；默认覆盖最后一个


注：内部还存在 IIniSectionInternal/IIniDocumentInternal 用于回放与脏标，不对外暴露。

## 用法示例

```pascal
uses fafafa.core.ini;

var Doc: IIniDocument; Err: TIniError;
if Parse(RawByteString('[core]\nname = fafafa'), Doc, Err) then
begin
  WriteLn(Doc.GetSection('core').Contains('name'));
  WriteLn(String(ToIni(Doc, [iwfSpacesAroundEquals])));
end;
```

### 进阶门面示例


### 读 Flags 示例

```pascal
var Doc: IIniDocument; Err: TIniError; S: String;
// 严格键名字符
AssertTrue(Parse(RawByteString('[s]\na-b=1\n'), Doc, Err, [irfStrictKeyChars]));
// 保留外层引号
AssertTrue(Parse(RawByteString('[s]\na="v;#"\n'), Doc, Err, [irfInlineComment, irfAllowQuotedValue]));
AssertTrue(Doc.TryGetString('s','a', S));
AssertEquals('"v;#"', S);
```

- 写入文件（ToFile）：

```pascal
var Doc: IIniDocument; Err: TIniError;
Parse(RawByteString('[a]\na=1\n'), Doc, Err);
if ToFile(Doc, 'out.ini', [iwfSpacesAroundEquals, iwfForceLF]) then
  WriteLn('Wrote out.ini');
```

- 解析并获取编码（ParseFileEx）：

```pascal
var Doc: IIniDocument; Err: TIniError; Enc: String;
if ParseFileEx('out.ini', Doc, Err, Enc, []) then
  WriteLn('Encoding='+Enc);
```


## 同名分段（重复 section）行为
- 默认允许同名分段；解析时将同名分段的键聚合到同一个 IIniSection（键视图）
- 未脏（document 未修改）且捕获到 Entries 时：ToIni 回放原始文本，因此会保留源文件中的多个相同节头，以及它们之间的注释/空行
- 已脏（调用过 Set*/Remove* 等修改）：ToIni 采用重组路径，每个节名仅输出一次节头；同名分段的键被合并输出
- 写出顺序：若 iwfStableKeyOrder 开启，对键名排序；否则按内部顺序
- 实践建议：
  - 若希望保持源文件中“多节头 + 注释/空白”的布局，请避免在该文档上做修改，从而走“未脏回放”路径
  - 需要修改并保持格式稳定时，可开启 iwfStableKeyOrder，并接受“合并为单节头”的结果


## 设计对齐
- 统一宏入口：{$I fafafa.core.settings.inc}
- 接口抽象 + 门面函数 Parse/ParseFile/ParseStream/ToIni
- 不在库中输出中文；测试与示例可用 {$CODEPAGE UTF8}


## 推荐 Flag 组合（实践指引）
- 可读优先（稳定且便于审阅）：
  - 写：iwfSpacesAroundEquals, iwfStableKeyOrder, iwfTrailingNewline
  - CLI：--spaces --stable-order --trailing-newline
- 行内注释与引号策略（速查）
  - 读（irfInlineComment）：剔除 ;/# 后内容，默认去外层成对引号；irfAllowQuotedValue 可保留外层引号
  - 写：
    - iwfQuoteValuesWhenNeeded：仅在分隔符(=/:)、注释符(;/#)、或首尾空格存在时加引号
    - iwfQuoteSpaces：值包含任意空格或制表符即加引号（更严格）

- 最小扰动（尽量不引入无谓引号）：
  - 写：iwfSpacesAroundEquals, iwfQuoteValuesWhenNeeded
  - CLI：--spaces --quote-values-when-needed
- 严格规范（统一可解析且稳健）：
  - 写：iwfSpacesAroundEquals, iwfQuoteSpaces, iwfStableKeyOrder, iwfTrailingNewline
  - CLI：--spaces --quote-spaces --stable-order --trailing-newline

说明：
- 未脏且存在 Entries 时仍走“原样回放”，写 Flag 仅在重组路径生效
- iwfQuoteValuesWhenNeeded 更通用，iwfQuoteSpaces 更严格；按团队风格择一或按场景切换



## 竞品与系统对比（MCP 调研摘要）

- FreePascal/Lazarus 标准单元（IniFiles / TMemIniFile）
  - 优点：稳定、内置；易用的读写 API
  - 局限：
    - 编码：历史上偏向 ANSI/本地编码；UTF-8/UTF-16 需手动处理；BOM/UTF-16 自动探测与统一到 UTF-8 不完善
    - 格式保留：不保留注释/空行/节与键顺序，无法“无损回放”；重复 section 的原样回放也不提供
    - 行内注释：没有“引号感知的行内注释”模式，容易把值中的 ;/# 误判为注释
    - 性能：简单实现，小文件足够；大文件/频繁 round-trip 时存在额外解析/格式损耗

- Go-ini（gopkg.in/ini.v1）
  - 特性：支持注释、空行、分隔符两种形式、大小写控制、键排序、直写文件等
  - 局限：不同版本对注释与引号的处理存在差异；回放策略以“重组”为主
  - 借鉴：读/写 Flags 的可组合性、Bool 大小写控制、稳定排序

- .NET Microsoft.Extensions.Configuration.Ini
  - 特性：统一配置抽象，支持环境替换等；但在“注释/空白保留、原样回放”方面并非目标
  - 借鉴：键大小写与覆盖策略的明确定义

- Java Apache Commons Configuration (INI)
  - 特性：多后端统一；对 INI 支持较稳健
  - 局限：同样不以“原样回放/注释保留”为目标

- Rust 生态（ini crate / toml-rs）
  - toml-rs：强调语义与类型化；ini crate 在“无损回放”支持有限或高度依赖实现版本
  - 借鉴：
    - 解码统一：I/O 层面先探测再统一到 UTF-8
    - 写出时的换行/末尾换行策略显式化

### 我们的差异化价值
- 无损回放优先：内部维护 Entries（Prelude/SectionHeader/Key/Comment/Blank），在未脏情况下严格回放；在节未脏且有 BodyLines 时，回放节主体。
- 引号感知的行内注释：irfInlineComment + irfAllowQuotedValue，避免把值内的 ;/# 误当注释。
- 统一编码策略：ParseFileEx/ParseStream 探测 UTF-8 BOM、UTF-16 LE/BE → 统一转 UTF-8；写出可选 UTF-8 BOM（iwfWriteBOM）。
- 写出策略现代化：iwfForceLF、iwfStableKeyOrder、iwfTrailingNewline、iwfBoolUpperCase 等，以“可配置”为核心。

### 差距与优先改进建议（可落地）
1) 解析准确性与健壮性
   - 待办：基于轻量 tokenizer 重写 InternalParseFromStrings，使引号、转义、键名字符、行内注释边界处理更一致；补齐“节头尾随非法字符/未闭合节头/未闭合引号”等 Err.Line/Column/Position 断言测试。
2) 原样回放的覆盖面
   - 待办：补强 Entries 捕获（当前已包含 Raw、HeaderPad、BodyLines），扩展对“默认节（无节头）的键 + 文档级 Prelude + 节间空行”更细粒度控制，确保 round-trip 样例稳定。
3) 写出策略细化
   - 待办：在 ToIni 中增加“节间空行策略（如 compact/keep-one/keep-all）”与“键值转义策略（空白/分隔符/注释符）”；在 dirty 节的键重组时，根据 flags 控制是否保留原值空白或做标准化。
4) 编码与平台一致性
   - 待办：补充更多样本（UTF-16 LE/BE、无 BOM UTF-8、混合换行 CRLF/LF）测试；ToFile 在 Windows 下也以二进制方式输出；明确 CLI 的 --lf/--trailing-newline 与 ToFile 一致。
5) 性能与基准
   - 待办：添加 benchmarks：对比 IniFiles/TMemIniFile 与本实现（解析/写出/round-trip），并在 docs/RELEASE_NOTES 中记录实测数据与样本规模。

### 测试补强建议（对应改进项）
- 边界/错误定位：未闭合引号、节头非法字符、空键、重复键（开启 irfDuplicateKeyError）、大小写敏感的双节多键覆盖顺序。
- 原样回放：含多节头/多注释/多空行的 round-trip 精准一致；默认节 + Prelude + 节间空行的组合。
- 编码：UTF-16 LE/BE（带/不带 BOM）、UTF-8 BOM、有/无末尾换行的行为；--lf 与 iwfTrailingNewline 组合。
- 写出 flags：iwfPreferColon/iwfSpacesAroundEquals/iwfBoolUpperCase/iwfStableKeyOrder/iwfTrailingNewline 的全组合抽样。

