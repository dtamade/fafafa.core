# fafafa.core.csv
<!-- Current module version -->
> 当前版本：v0.3.0


> 高性能、跨平台、接口优先的 CSV 读写库。对齐 RFC 4180，支持按块流式读取与可配置方言（Go/Rust/Java 风格）。

> 变更日志：参见仓库根目录的 CHANGELOG.md（fafafa.core.csv 段落）。


## 设计目标
- 接口优先，Reader/Writer/Builder + Dialect
- 跨平台（Windows/Linux/macOS）；不输出中文（测试/示例可用 {$CODEPAGE UTF8}）
- 默认严格 RFC 4180：逗号、双引号转义、CRLF、字段数一致
- 真实流式解析，避免大文件整载内存峰值；精确行列定位

## 方言（Dialect）
TCSVDialect = record（实现字段）
- Delimiter: WideChar (默认 ',')
- Quote: WideChar (默认 '"')
- Escape: WideChar (默认 #0=关闭；若启用则与 DoubleQuote 二选一)
- UseCRLF: Boolean (默认 True；UnixDialect 为 False)
- TrimSpaces: Boolean (默认 False，仅影响读取未引号字段)
- AllowLazyQuotes: Boolean (默认 False)
- AllowVariableFields: Boolean (默认 False)
- HasHeader: Boolean (默认 False)
- Comment: WideChar (默认 #0=关闭；仅在记录起始且未在引号内识别为注释)
- IgnoreEmptyLines: Boolean (默认 False；True 时空行直接跳过)
- QuoteMode: csvQuoteMinimal|csvQuoteAll|csvQuoteNone（默认 Minimal；None 模式下若字段含分隔符/引号/换行/前后空格/首字符为注释符，将抛错）
- DoubleQuote: Boolean (默认 True；写入时 " -> "")
- MaxRecordBytes: SizeUInt (默认 16MiB；单条记录所有字段原始字节累计上限)
- Terminator: csvTermAuto|csvTermCRLF|csvTermLF（默认 Auto=沿用 UseCRLF）
- StrictUTF8: Boolean (默认 False；严格 UTF‑8，遇非法序列抛错)
- ReplaceInvalidUTF8: Boolean (默认 False；遇非法序列以 U+FFFD 替换)
- NameMatchMode: csvNameExact | csvNameAsciiCI（默认 csvNameAsciiCI；见下文名称匹配）
- TrimMode: TECSVTrimMode（默认 csvTrimNone；细粒度 trim 控制，见下文）

### TrimMode（细粒度 Trim 控制）
- TECSVTrimMode 枚举：csvTrimNone | csvTrimHeaders | csvTrimFields | csvTrimAll
- 行为：
  - csvTrimNone：不 trim 任何内容（默认）
  - csvTrimHeaders：仅 trim 表头字段（HasHeader=True 时）
  - csvTrimFields：仅 trim 数据字段（不含表头）
  - csvTrimAll：同时 trim 表头和数据字段
- 向后兼容：TrimSpaces=True 等效于 csvTrimFields（仅 trim 数据字段）
- 注意：仅 trim 未引号包裹的字段；引号包裹的字段保留原始空格

预设：
- DefaultRFC4180
- ExcelDialect（与 RFC4180 接近，区域性分隔符需自行配置）
- UnixDialect（LF 换行）

## API

### Rust csv crate API 对照表

对齐目标：Rust `csv` crate 0.1.x（<https://docs.rs/csv/latest/csv/>）

Reader 配置方法：
- `delimiter(Ch)` → `Delimiter(Ch)` ✓
- `quote(Ch)` → `Quote(Ch)` ✓
- `escape(Ch)` → `Escape(Ch)` ✓
- `has_headers(Bool)` → `HasHeaders(Bool)` / `HasHeader(Bool)` ✓
- `flexible(Bool)` → `Flexible(Bool)` ✓
- `trim(TrimMode)` → `Trim(TECSVTrimMode)` ✓
- `comment(Ch)` → `Comment(Ch)` ✓
- `double_quote(Bool)` → `DoubleQuote(Bool)` ✓
- `quoting(Bool)` → `Quoting(Bool)` ✓

Writer 配置方法：
- `delimiter(Ch)` → `Delimiter(Ch)` ✓
- `quote(Ch)` → `Quote(Ch)` ✓
- `escape(Ch)` → `Escape(Ch)` ✓
- `double_quote(Bool)` → `DoubleQuote(Bool)` ✓
- `quote_style(Mode)` → `QuoteMode(TECSVQuoteMode)` ✓
  - QuoteNecessary → csvQuoteMinimal
  - QuoteAlways → csvQuoteAll
  - QuoteNonNumeric → csvQuoteNonNumeric
  - QuoteNever → csvQuoteNone
- `terminator(Term)` → `Terminator(TECSVTerminator)` / `UseCRLF(Bool)` ✓

便捷创建（对齐 Rust `csv::Reader::from_path` / `csv::Writer::from_path`）：
- `CreateCSVReader(FileName)` ✓
- `CreateCSVReader(Stream, OwnsStream)` ✓
- `CreateCSVWriter(FileName)` ✓
- `CreateCSVWriter(Stream, OwnsStream)` ✓

行为差异：
- Trim 枚举：Rust 支持 Headers/Fields/All/None，Pascal 对应 csvTrimHeaders/csvTrimFields/csvTrimAll/csvTrimNone
- Quoting(False) 行为：禁用引号特殊处理，引号被视为普通字符
- csvQuoteNonNumeric：非数字字段总是加引号（与 Python csv 模块对齐）

- 错误类型
  - ECSVError.CreatePos(Msg, Line, Column)
  - ECSVError.CreatePosEx(Msg, Line, Column, Code) // 带错误码
- 记录视图
  - ICSVRecord: Count, Field(Index), FieldU(Index), TryGetByName(Name, out Value), TryGetByNameU(NameU, out ValueU), AsArray
- 读取
  - ICSVReader: Dialect, Headers, ReadNext(out Rec):Boolean, ReadAll:TCSVTable, Reset, Line, Column
  - ICSVReaderBuilder: FromStream/FromFile/FromString/Dialect/BufferSize/ReuseRecord/MaxRecordBytes/StrictUTF8/ReplaceInvalidUTF8/RecordKind/Delimiter/Quote/HasHeader/Flexible/TrimSpaces/Comment/DoubleQuote/Escape/LazyQuotes/Build
  - 快捷别名：Flexible(Bool) = AllowVariableFields, LazyQuotes(Bool) = AllowLazyQuotes
  - OpenCSVReader(FileName, Dialect)

- 名称匹配（计划项）：NameMatchMode = Exact | AsciiCaseInsensitive（默认 AsciiCI）；非 ASCII 列名建议用 Exact；当前版本中 TryGetByName 的大小写不敏感仅对 ASCII 列名可靠，非 ASCII 列名建议使用 TryGetByNameU（精确匹配）。

- 写入
  - ICSVWriter: Dialect, WriteRow, WriteRowU, WriteAll, Flush, Close
  - ICSVWriterBuilder: ToStream/ToFile/Dialect/WithHeaders/WriteBOM/Terminator/Build
  - OpenCSVWriter(FileName, Dialect)

## 配置优先级（Builder vs Dialect）
- 优先级：Builder 显式设置 > Dialect 值 > 默认值
- 示例：
  - Dialect.StrictUTF8=True，Builder.ReplaceInvalidUTF8(True) ⇒ 最终宽容替换（不抛错）

### 名称匹配（NameMatchMode）
- NameMatchMode: csvNameExact | csvNameAsciiCI（默认 csvNameAsciiCI）
- 建议：
  - ASCII 列名可用 AsciiCI（大小写不敏感）
  - 非 ASCII 列名建议使用 Exact（精确匹配）
- 行为：
  - TryGetByName：受 NameMatchMode 控制
  - TryGetByNameU：当前版本保持与历史兼容（大小写不敏感）；后续版本可切换为受 NameMatchMode 控制的精确匹配
- 重复列名：保留首次出现（FirstWins）
- 性能：解析 Header 后构建 O(1) 的按名索引（开放寻址哈希表，ASCII 小写归一）；线性扫描作为兜底路径

  - Dialect.ReplaceInvalidUTF8=True，Builder.StrictUTF8(True) ⇒ 最终严格（抛错）
- 互斥：StrictUTF8 与 ReplaceInvalidUTF8 互斥，Builder 设置时会自动清理另一项

## Reset/Headers 语义
- HasHeader=True：首条记录作为 Headers，严格字段数检查对表头行跳过一次
- Reset：
  - 清空内部 Headers/状态并重置到流起点；后续再次解析表头
  - 非可寻址流（不支持 Position 的 TStream 子类）上 Reset 可能失败或无效（不建议在此类流上使用 Reset）

## 编码与 BOM 政策
- Reader：跳过 UTF‑8 BOM（EF BB BF）；不支持 UTF‑16/UTF‑32 BOM，若遇到应视为不受支持的编码输入（建议调用方在进入本库前转换为 UTF‑8）
- Writer：默认不写 BOM；可通过 ICSVWriterBuilder.WriteBOM(True) 写入 UTF‑8 BOM

## 流式解析说明
- Reader 默认走真实流式路径：按块从 TStream 读取，默认 256KB，可通过 ICSVReaderBuilder.BufferSize 配置
- 首块按需跳过 UTF-8 BOM
- CR/LF/CRLF 混合兼容；错误定位为“记录起始行/列”（记录级错误列号固定为 1）
- HasHeader=True 时首行作为表头，严格字段数检查跳过一次；严格模式下“全空字段行”不参与设定字段数基线；Reset 会清空 Headers 并在后续读取时重新解析表头
- Flush/Close 语义（重要变更）
  - Flush：仅刷新缓冲数据，不关闭或释放底层句柄；不同平台/RTL 下实现可能是 no-op 或直写
  - Close：释放由 Writer 持有的句柄/流资源
  - 迁移：若 Flush 后立刻读取同一路径，请在 Flush 之后调用 Close 再读取（尤其在 Windows 上）


## Writer 说明
- 需要引号的场景：包含分隔符、引号、换行，或前后空格（消费方常见期望）
- 引号转义：双引号翻倍（" -> ""）
- 换行：UseCRLF=True 则 CRLF，否则 LF；默认不写 BOM
- Header：通过 WithHeaders 指定，仅写入一次

## 典型示例

读取所有记录：

```pascal
var D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; Tbl: TCSVTable;
begin
  D := DefaultRFC4180; D.HasHeader := True;
  R := OpenCSVReader('data.csv', D);
  Tbl := R.ReadAll;
end;
```

逐行读取并按列名访问：

```pascal
var D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; v: string;
begin
  D := DefaultRFC4180; D.HasHeader := True;
  R := OpenCSVReader('data.csv', D);
  while R.ReadNext(Rec) do
    if Rec.TryGetByName('id', v) then ; // use v
end;
```

写入并自动引号：

附：指定行分隔符（Terminator 优先于 UseCRLF）：

```pascal
var D: TCSVDialect; W: ICSVWriter;
begin
  D := DefaultRFC4180;
  W := CSVWriterBuilder.ToFile('out_lf.csv').Dialect(D).Terminator(csvTermLF).Build;
  W.WriteRow(['a','b']);
  W.Close;
end;
```


```pascal
var D: TCSVDialect; W: ICSVWriter;
begin
  D := DefaultRFC4180;
  W := CSVWriterBuilder.ToFile('out.csv').Dialect(D).WithHeaders(['id','name']).Build;
  W.WriteRow(['1','Alice, "engineer"']);
  W.Close;
end;
```

示例：Unicode 读写与推荐接口：

```pascal
var D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; W: ICSVWriter; u: UnicodeString;
begin
  D := DefaultRFC4180; D.HasHeader := True;
  R := OpenCSVReader('in.csv', D);
  while R.ReadNext(Rec) do
    if Rec.TryGetByNameU('名称', u) then ;

  W := CSVWriterBuilder.ToFile('out.csv').Dialect(D).WithHeaders(['id','名称']).Build;
  W.WriteRowU(['1', '你']);
  W.Close;
end;
```

### 编码与 API 使用建议
- Writer：统一以 UTF-8 字节写出，每行在内存中按 RawByteString 拼接，最后一次写入；行尾分隔符按方言（CRLF/LF）。
- Reader：按字节流解析字段，发出前统一将 UTF-8 字节 UTF8Decode 为 UnicodeString 存入内部数组。
- 遵循 RFC 4180：逗号、双引号转义（翻倍）、引号内允许换行；Escape 独立开关可选。
- ICSVRecord 两种访问器：
  - Field(Index): string（兼容旧代码，可能受平台代码页影响）
  - FieldU(Index): UnicodeString（推荐，保证 Unicode 语义）
- 常见建议：
  - 长字段或多语言比较请使用 FieldU；不要对 Field 做字符级比较
  - 写入无需手动 UTF8Encode；直接传 string/UnicodeString
  - 避免用 TStringList 手工保存 CSV 再写入，以免引入编码/换行归一副作用
- 兼容性：保留 Field，新增 FieldU；建议逐步迁移至 FieldU
- 大小写不敏感仅建议用于 ASCII 列名；非 ASCII 列名建议使用精确匹配（TryGetByNameU）或未来的 NameMatchMode=Exact

### 性能实战：零拷贝切片与记录复用
- 零拷贝切片：ICSVRecord.GetFieldSlice(Index, out PAnsiChar, out Len)
  - 返回 UTF‑8 字节切片（指针+长度），无需分配；仅在“下一次 ReadNext 前”有效
- 字节副本：ICSVRecord.TryGetFieldBytes(Index, out RawByteString)
  - 构造副本，可跨记录持有；适合跨线程/延迟处理
- 记录复用：CSVReaderBuilder.ReuseRecord(True)
  - 复用同一记录实例，减少对象分配；注意复用会使旧切片在下一次 ReadNext 后立即失效
- 示例：
```pascal
var p: PAnsiChar; n: SizeInt; b: RawByteString;
if Rec.GetFieldSlice(0, p, n) then begin
  // use p..p+n-1 before next ReadNext
end;
if Rec.TryGetFieldBytes(0, b) then begin
  // b is safe to keep after next ReadNext
end;
```
- 进一步阅读：docs/partials/csv.performance.md


- UTF‑8 非法序列策略（Strict/Replace）
  - StrictUTF8=True：遇非法 UTF‑8 抛 ECSVError（错误位置=记录首列），适用于数据质量要求严格场景
  - ReplaceInvalidUTF8=True：遇非法 UTF‑8 以 U+FFFD 替换；适用于宽容读取
  - 默认（两者 False）：保持历史行为（运行时可能宽容处理），推荐选择 Strict 或 Replace 之一以消除不确定性

### 迁移对照：Field/TryGetByName → FieldU/TryGetByNameU
- 字段长度/内容比较：
  - 旧：Length(Rec.Field(i)) / Rec.Field(i) = Expected
  - 新：Length(Rec.FieldU(i)) / Rec.FieldU(i) = Expected
- 按列名取值：
  - 旧：if Rec.TryGetByName('name', s) then ... {s: string} // 大小写不敏感（建议仅用于 ASCII）
  - 新：if Rec.TryGetByNameU('名称', u) then ... {u: UnicodeString} // 推荐精确匹配（非 ASCII 列名）
- 获取 UTF-8 字节（与外部 UTF-8 API 对接）：
  - 新：UTF8Encode(Rec.FieldU(i)) // 稳定 Unicode 语义

### Flush/Close 与 Terminator 优先级
- Flush：仅刷新缓冲，不关闭底层句柄；对 TFileStream 调用 Flush；其他 TStream 直写。
- Close：释放由 Writer 持有的句柄/流资源；Windows 场景下，若写入后立刻读取同一文件，建议 Close 后再读。
- Terminator：当为 Auto 时沿用 Dialect.UseCRLF；显式设置 Terminator 时优先级高于 UseCRLF。

## 平台与编码注意
- 库层不输出中文；测试/示例单元应在文件头加入 `{$CODEPAGE UTF8}`
- Reader 会跳过 UTF-8 BOM；Writer 默认不写 BOM
- 生产环境建议在 StrictUTF8 或 ReplaceInvalidUTF8 中二选一，避免默认模式对非法 UTF‑8 的不确定行为

### 编码路径与告警清理（维护者说明）
- Writer/Record 对外 string 统一按 UTF-8 字节语义处理；必要处显式 UTF8Encode/UnicodeString 转换，避免隐式窄化告警。
- 此调整不改变行为，仅清理编译告警并确保热路径稳定（预分配 + 单次写出）。

- 详见 docs/partials/csv.encoding_and_api.md：编码策略与 ICSVRecord 两种访问器（Field/FieldU）使用建议

## 版本与宏
- 宏集中于 src/fafafa.core.settings.inc
  - {$DEFINE FAFAFA_CSV_STRICT_RFC4180}（默认）
  - {$DEFINE FAFAFA_CSV_DISABLE_READER}/{$DEFINE FAFAFA_CSV_DISABLE_WRITER}（裁剪体积时使用）
  - {$DEFINE FAFAFA_CSV_ENABLE_ESCAPE}（启用独立 Escape，默认关闭）

## 最佳实践
- 编码与 API
  - 读取后如需字符级长度/内容比较，使用 Rec.FieldU(Index) 以获得稳定的 Unicode 语义；Field(Index) 主要用于兼容旧代码，可能受平台代码页影响
  - 写入侧直接传递 string/UnicodeString 给 WriteRow/WriteAll，Writer 内部统一 UTF‑8 编码，无需手动 UTF8Encode
  - 避免用 TStringList 保存 CSV 后再写入（会引入编码与换行归一副作用）；推荐始终使用本库 Writer
- 读写策略
  - 大文件优先使用 ReadNext 流式读取；ReadAll 仅在数据量可控时使用
  - HasHeader=True 时首行作为表头；严格字段数检查对表头行跳过一次
  - 引号字段内允许 CRLF/LF/CR，按原样保留；是否需要 TrimSpaces 仅影响未引号字段
- 性能建议
  - 复用同一个 Writer，批量写入后再 Flush/Close，避免频繁打开/关闭文件句柄
  - 单行极长（>MB）时，仍建议一次性写出以降低系统调用次数

## 常见坑与最佳实践（补充）
- Flush 后需 Close（Windows）：写入后若要立刻读取同一文件，请在 Flush 之后调用 Close，确保句柄释放与数据可见
- QuoteMode=None 使用限制：当字段包含分隔符/引号/换行/前后空格/首字符为注释符时将抛出 ECSVError（csvErrInvalidFieldForQuoteMode）；如需输出此类字段，请使用 Minimal 或 All
- BufferSize 调优（Reader）：默认 256KB，可通过 ICSVReaderBuilder.BufferSize 设置；建议按磁盘/网络吞吐与记录平均大小调节（64KB–1MB 之间常见）；过大可能增加延迟与缓存压力
- 字符与编码：
  - 读取后做字符级比较/长度时，使用 FieldU，避免平台代码页引发歧义；与外部 UTF‑8 API 对接时使用 UTF8Encode(Rec.FieldU(i))
  - 生产建议 StrictUTF8 或 ReplaceInvalidUTF8 二选一，避免默认模式对非法 UTF‑8 的不确定性
- 严格模式与空行：AllowVariableFields=False 时，“全空字段行”不参与基线设定；必要时结合 IgnoreEmptyLines
- 注释行：仅在记录起始且未在引号内识别；若字段首字符可能与 Comment 冲突，Writer 会自动加引号（QuoteMode≠None）

  - Writer 内部已缓存分隔符与引号/转义字节，并复用行缓冲；单次 WriteRow/WriteRowU 会预计算每列的 UTF‑8 字节与引号需求，减少重复编码与扫描
  - 在高频写入（日志/报表）中建议：
    - 复用 Writer 实例与行缓冲（默认已复用，无需额外配置）
    - 批量写入（WriteAll/WriteAllU）优先；减少跨层调用开销
    - 如 Dialect 很少变化，避免频繁创建/销毁 Writer

- 迁移建议（从 Field 到 FieldU）
  - 将 Length(Rec.Field(i)) 改为 Length(Rec.FieldU(i))
  - 将 Rec.Field(i) = Expected 改为 Rec.FieldU(i) = Expected
  - 若外部 API 需要 UTF‑8 字节，可用 UTF8Encode(Rec.FieldU(i))

更多说明见 docs/partials/csv.encoding_and_api.md。




## 性能建议与基准（建议值）
- Reader.BufferSize：建议默认 256KB；在 NVMe/大顺序读场景可试 1MB；小文件或内存受限时 64KB 也可
- 编译优化：发布用 O3 + Xs；开发/调试用 O1
- 快路径：未引号快路径已启用；如需进一步优化，请结合 play 基准工具验证
- 基准工具（play）：
  - 生成数据：gen_data_min.exe <out.csv> <lines> <cols> [hasHeader=0|1]
  - 读取基准：bench_read_min.exe <csv> [hasHeader=0|1] [outPath] [bufSizeBytes]
  - 输出文件为 UTF-8 文本，形如“Rows=… Fields=… Time(ms)=…”
- 参考结果（本机，仅供参考）：
  - O3: 200000×12 含表头，BufferSize 中位数：64KB≈4373ms；256KB≈4028ms；1MB≈4040ms

## 错误码触发最小示例

快速索引：
- UnexpectedQuote：见“Positions/More”与“ErrorCodes”对应用例
- UnterminatedQuote：见“Positions/More”与“Positions/Asserts”对应用例
- FieldCountMismatch：见 “Reader_Strict / Positions_*” 对应用例
- InvalidUTF8：见 "Reader_InvalidUTF8" 套件（Strict/Replace 两种策略）
- RecordTooLarge：见 "Reader_BuilderOptions.Test_Builder_MaxRecordBytes_Limit"
- InvalidFieldForQuoteMode（写入端）：见 "Writer_Behaviors" 套件中 QuoteMode=None 系列


以下示例均可独立复制运行（需 {$CODEPAGE UTF8} 且 uses fafafa.core.csv）。每段示例创建临时文件写入触发数据，然后调用 OpenCSVReader 读取并捕获异常，打印错误码。

- UnexpectedQuote（csvErrUnexpectedQuote）
```pascal
{$CODEPAGE UTF8}
var D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; F: TextFile; Tmp: string;
begin
  D := DefaultRFC4180; D.AllowLazyQuotes := False; Tmp := 'tmp_unexpected.csv';
  AssignFile(F, Tmp); Rewrite(F); Writeln(F, 'ab"cd,ef'); CloseFile(F);
  try
    R := OpenCSVReader(Tmp, D);
    try R.ReadNext(Rec); except on E: ECSVError do Writeln(Ord(E.Code)); end;
  finally DeleteFile(Tmp); end;
end;
```

- UnterminatedQuote（csvErrUnterminatedQuote）
```pascal
{$CODEPAGE UTF8}
var D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; F: TextFile; Tmp: string;
begin
  D := DefaultRFC4180; D.AllowLazyQuotes := False; Tmp := 'tmp_unterm.csv';
  AssignFile(F, Tmp); Rewrite(F); Writeln(F, '"abc,def'); CloseFile(F);
  try R := OpenCSVReader(Tmp, D); try R.ReadNext(Rec); except on E: ECSVError do Writeln(Ord(E.Code)); end; finally DeleteFile(Tmp); end;
end;
```

- FieldCountMismatch（csvErrFieldCountMismatch）
```pascal
{$CODEPAGE UTF8}
var D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; F: TextFile; Tmp: string;
begin
  D := DefaultRFC4180; D.AllowVariableFields := False; Tmp := 'tmp_mismatch.csv';
  AssignFile(F, Tmp); Rewrite(F); Writeln(F, 'a,b,c'); Writeln(F, '1,2'); CloseFile(F);
  try R := OpenCSVReader(Tmp, D); Assert(R.ReadNext(Rec)); try R.ReadNext(Rec); except on E: ECSVError do Writeln(Ord(E.Code)); end; finally DeleteFile(Tmp); end;
end;
```

- RecordTooLarge（csvErrRecordTooLarge）
```pascal
{$CODEPAGE UTF8}
var D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; F: TextFile; Tmp: string;
begin
  D := DefaultRFC4180; D.MaxRecordBytes := 8; Tmp := 'tmp_toolarge.csv';
  AssignFile(F, Tmp); Rewrite(F); Writeln(F, 'abcdefghij'); CloseFile(F);
  try R := OpenCSVReader(Tmp, D); try R.ReadNext(Rec); except on E: ECSVError do Writeln(Ord(E.Code)); end; finally DeleteFile(Tmp); end;
end;
```

- InvalidUTF8（csvErrInvalidUTF8）
```pascal
{$CODEPAGE UTF8}
var D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; FS: TFileStream; Tmp: string; Raw: RawByteString;
begin
  D := DefaultRFC4180; D.StrictUTF8 := True; Tmp := 'tmp_invalidutf8.csv';
  Raw := 'ok,' + AnsiChar(#$C3) + ',end' + #10; SetCodePage(Raw, CP_UTF8, False);
  FS := TFileStream.Create(Tmp, fmCreate); try FS.WriteBuffer(Pointer(Raw)^, Length(Raw)); finally FS.Free; end;
  try R := OpenCSVReader(Tmp, D); try R.ReadNext(Rec); except on E: ECSVError do Writeln(Ord(E.Code)); end; finally DeleteFile(Tmp); end;
end;
```

## 测试

## 写入侧限制与错误的最小示例

- QuoteMode=None 时的限制（csvErrInvalidFieldForQuoteMode）

当字段包含分隔符/引号/换行/前后空格/首字符为注释符时，且 Dialect.QuoteMode=None，将抛出 ECSVError，错误码 csvErrInvalidFieldForQuoteMode。

```pascal
{$CODEPAGE UTF8}
var D: TCSVDialect; W: ICSVWriter; Raised: Boolean; Code: TECSVErrorCode;
begin
  D := DefaultRFC4180; D.QuoteMode := csvQuoteNone; // 禁止写端加引号
  try
    W := CSVWriterBuilder.ToFile('tmp_writer_none.csv').Dialect(D).Build;
    try
      // 包含分隔符的字段，在 QuoteMode=None 下不允许
      W.WriteRow(['id', 'Alice, engineer']);
    finally
      W.Close;
    end;
  except on E: ECSVError do begin Raised := True; Code := E.Code; end; end;
  Writeln('Raised=', Raised, ' Code=', Ord(Code));
  if FileExists('tmp_writer_none.csv') then DeleteFile('tmp_writer_none.csv');
end;
```

说明：若需要输出上述内容，请选择 csvQuoteMinimal 或 csvQuoteAll。

- 测试工程：tests/fafafa.core.csv/
- 构建/运行：BuildOrTest.bat test（Windows），BuildOrTest.sh test（Linux/macOS）
- 覆盖：Reader/Writer、方言、混合换行、错误定位、BOM 跳过、懒引号与严格字段控制

## 错误码与触发条件（完整）
- csvErrUnexpectedQuote
  - 触发：未引号字段中出现引号（AllowLazyQuotes=False）
  - 定位：Line=坏记录起始行，Column=1
  - 备注：AllowLazyQuotes=True 时将把该引号当作普通字符加入字段
- csvErrUnterminatedQuote
  - 触发：引号字段未闭合（AllowLazyQuotes=False）
  - 定位：Line=坏记录起始行，Column=1
  - 备注：AllowLazyQuotes=True 时宽容到 EOF 并收敛为已闭合
- csvErrFieldCountMismatch
  - 触发：AllowVariableFields=False 且某记录字段数与基线不一致
  - 基线：当 FExpectedFields=-1 时，跳过“全空字段行”（如 ",,," 或 ""），使用下一条非空记录设定；Header 行会跳过一次严格检查
  - 定位：Line=坏记录起始行，Column=1
- csvErrRecordTooLarge
  - 触发：单条记录累计字节数（各字段原始字节总和）超过 Dialect.MaxRecordBytes
  - 定位：Line=记录起始行，Column=1
- csvErrInvalidUTF8
  - 触发：StrictUTF8=True 且字段内存在非法 UTF‑8 序列
  - 行为：ReplaceInvalidUTF8=True 时宽容替换为 U+FFFD，不抛错；默认两者 False 时依赖运行时的解码行为
  - 定位：Line=记录起始行，Column=1
- csvErrInvalidEscape
  - 触发：启用 Escape 且解析到不受支持的组合
  - 当前实现：对未知转义采取保留策略（不抛错）；该码为前瞻保留
- csvErrInvalidFieldForQuoteMode
  - 触发：QuoteMode=None 时字段包含分隔符/引号/换行/前后空格/首字符为注释符
  - 定位：Line/Column=0（写入阶段的参数错误，不涉及读取定位）
- csvErrIndexOutOfRange（预留说明）
  - 触发：字段访问越界
  - 当前实现：Record.Field 越界抛 ERangeError（非 ECSVError）。若需统一为 ECSVError，需配合迁移指南

通用定位规则：
- 记录级错误（例如字段数不一致/未闭合引号/未预期引号）统一以“记录起点”为定位，Column 固定为 1；兼容 CR/LF/CRLF 混合换行

## 变更日志（简）
- Phase 1：统一字符 API；实现真实流式解析；通过现有用例

