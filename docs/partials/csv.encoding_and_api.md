# 编码与 API 使用建议（fafafa.core.csv）

## 总览
- Writer：统一以 UTF-8 字节写出，每行在内存中按 RawByteString 拼接，最后一次写入；行尾分隔符按方言（CRLF/LF）。
- Reader：按字节流解析字段，发出前统一将 UTF-8 字节 UTF8Decode 为 UnicodeString 存入内部数组。
- 默认遵循 RFC 4180：逗号、双引号转义（翻倍）、引号内允许换行；Escape 独立开关可选。
- UTF‑8 非法序列策略：
  - StrictUTF8=True：遇非法 UTF‑8 抛 ECSVError（记录级错误，列号固定为 1）
  - ReplaceInvalidUTF8=True：遇非法 UTF‑8 以 U+FFFD 替换
  - 默认（False/False）：保持历史行为（运行时可能宽容处理），建议优先开启 Strict 或 Replace 之一
- Flush/Close 语义：
  - Flush：仅刷新缓冲数据，不关闭/释放句柄；Windows 下读回同一路径通常需 Close 后再读
  - Close：释放 Writer 持有的流/句柄资源
- 名称匹配建议：
  - 大小写不敏感仅建议用于 ASCII 列名；非 ASCII 列名建议使用精确匹配或未来的 NameMatchMode=Exact


## ICSVRecord 的两个访问器
- Field(Index: SizeInt): string
  - 为兼容旧代码的返回类型；在 Windows/FPC 下，string 可能映射为 AnsiString（受系统代码页影响）。
  - 在部分环境中，直接使用 Field 返回值进行字符长度或内容比较，可能出现“按字节计数”的现象。
- FieldU(Index: SizeInt): UnicodeString（推荐）
  - 新增的 Unicode 语义访问器，总是返回 UnicodeString。适合需要字符级比较、长度统计、正则等 Unicode 语义操作。
  - 建议在处理多语言文本、长字段、以及与其他 Unicode API 交互时使用。

## 常见问题与建议
- 读取长的多字节字符字段时，若直接用 Field 做 Length 比较，可能得到按字节的长度；应改为 FieldU。
- 写入时无需自行 UTF8Encode；直接传递 string/UnicodeString，Writer 内部统一 EncodeUTF8。
- 手工构造 CSV 时，不建议用 TStringList 保存再写入（会引入编码和换行归一副作用）；应使用本库 Writer。

## 示例
- 字段内容比对（Unicode 语义）：

```pascal
AssertEquals(Length(Expected), Length(Rec.FieldU(0)));
AssertTrue(Rec.FieldU(0) = Expected);
```

- 写入混合语言文本：

```pascal
W.WriteRow(['id', '名称', '备注']);
W.WriteRow(['1', '你', 'emoji: 😀']);
```

## 兼容性
- 该改动向后兼容：保留 Field 接口，新增 FieldU 接口。
- 现有依赖 Field 的代码继续可用，但推荐逐步迁移到 FieldU 以获得一致的 Unicode 语义。

