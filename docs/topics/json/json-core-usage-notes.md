# fafafa.core.json 使用说明（新增与最佳实践）

## 编码策略
- 本库底层数据均以 UTF-8 编码存储。
- IJsonValue.GetString 通过 UTF8String -> String 转换，受系统 codepage 影响；推荐在跨平台/非 UTF-8 locale 下优先使用 GetUtf8String。
- GetStringLength 返回的是字节长度（UTF-8），不是字符数。

## 生命周期与所有权
- 任何 IJsonValue 的生命周期都依赖其所属的 IJsonDocument；本模块内部已确保 TJsonValueImpl 持有文档接口的强引用（通过内部桥接接口），因此 IJsonValue 可独立安全使用。
- 建议仍在业务层面尽量将 Document 与 Value 同步管理，避免跨线程误用。

## Try/OrDefault 语义
- TryGet 系列（JsonTryGetInt/UInt/Bool/Float/Str）永不抛异常，失败返回 False。
- TryGetInt/UInt 仅在底层为整数类型时返回 True；浮点数将返回 False。
- OrDefault 系列不会抛异常；若类型不匹配或缺失，返回默认值。

## Null 语义
- IJsonValue.IsNull 在 FValue=nil 或 JSON Null 时均返回 True；GetType 在 FValue=nil 时返回 jvtNull。

## Reader/Writer 新增能力
- IJsonReader.ReadFromFile / ReadFromStream：从文件/流读取；ReadFromStream 会完整读入内存后再解析。
- IJsonWriter.WriteToFile / WriteToStream：写出到文件/流；WriteToStream 使用 JsonWrite 生成内存缓冲再写出，之后释放缓冲。

## JSON Pointer 便捷函数
- JsonGetIntOrDefaultByPtr/JsonGet...ByPtr：按 Pointer 路径获取并返回默认值，严格不抛异常。

## for-in 枚举器
- JsonArrayItems(ARoot): 支持 for item in JsonArrayItems(root) do ...
- JsonObjectPairs(ARoot): 支持 for p in JsonObjectPairs(root) do （p.Key 为 String，p.Value 为 IJsonValue）
- JsonObjectPairsUtf8(ARoot): 同上但键为 UTF8String（减少编码转换）。

## 性能建议
- 大数据量遍历优先使用 Raw 的 ForEach 或 for-in 枚举器，以减少不必要的复制与分配。
- 若仅比较键名，优先使用 UTF-8 原生接口（如 *_Utf8）避免 String/codepage 往返转换。

## 异常类型
- 解析相关抛 EJsonParseError；数值边界等抛 EJsonValueError（含错误码）。
- 写入/参数问题不再使用 ParseError；后续可引入 Writer/Argument 专用异常类型（兼容期内先复用）。


## 运行测试
- Windows (CMD): `tests\\run_json_tests.bat`
- Windows (PowerShell): `./tests/run_json_tests.ps1`
- Linux/macOS: `./tests/run_json_tests.sh`

注意：若 lazbuild 未在 PATH 中，请安装 Lazarus 或通过环境变量/参数指定 lazbuild 路径（见脚本内说明）。

## 最佳实践：for-in 与 Pointer + 默认值
- for-in 枚举数组：`for v in JsonArrayItems(root.GetObjectValue('arr')) do ...`
- for-in 枚举对象：`for p in JsonObjectPairs(root.GetObjectValue('obj')) do ...`，p.Key 为 String；若希望避免 codepage 往返，使用 `JsonObjectPairsUtf8`。
- Pointer + 默认值：`JsonGetIntOrDefaultByPtr(root, '/a/b/0', -1)`，路径缺失返回指定默认值，永不抛异常。

完整示例见：`examples/fafafa.core.json/example_forin_and_ptr_best_practices.lpr`

## UTF-8 友好 API 与建议
- 推荐在跨平台环境使用 `GetUtf8String` 获取值；若严格使用 UTF-8 键，优先使用 Raw/Utf8 的对象访问接口（后续提供 `GetObjectValueUtf8/HasObjectKeyUtf8` 等别名）。
- 比较字符串建议使用 UTF8String，以避免系统 String codepage 差异造成的行为不一致。
### UTF-8 键的便捷函数
- JsonHasKeyUtf8(ARoot, UTF8StringKey)
- JsonGetValueUtf8(ARoot, UTF8StringKey): IJsonValue

以上函数避免 String/UTF-8 的反复编码转换，建议在跨平台环境中优先使用。


## 运行示例
- Windows (CMD): `examples\\run_examples.bat`
- Windows (PowerShell): `./examples/run_examples.ps1`
- 也可用 Lazarus 打开 `examples/fafafa.core.json/example_forin_and_ptr_best_practices.lpr` 运行

- 构建并运行所有示例：
  - Windows (CMD): `examples\\run_all_examples.bat`
  - Windows (PowerShell): `./examples/run_all_examples.ps1`
