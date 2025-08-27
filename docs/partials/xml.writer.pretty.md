# Writer Pretty 机制与规则（实现说明）

本说明面向维护者，概述 Writer 在 Pretty 模式下的占位符与缩进机制，以及属性排序/去重流程。

## 占位符与缩进
- NL 占位符：在 Buffer 中插入形如 `#{NLd}` 的占位符，d 为缩进深度（0 表示顶层）。
  - WriteIndent：仅当 Buffer 非空且末尾不是 NL 占位符时插入；避免文档开头产生多余换行与重复 NL。
  - EndsWithNLPlaceholder：通过字符索引检查 Buffer 末尾是否为 `#{NL` 前缀（不使用 Substring）。
- 输出阶段：`ReplaceNewlinePlaceholders(S, Pretty)`
  - Pretty=true：将 `#{NLd}` 展开为 LineEnding + (d*2 空格)。
  - Pretty=false：`StripAnyPlaceholders` 清理所有 NL 占位符，保证紧凑输出。

## 开始/结束标签收尾
- `WriteToString(AFlags)` 在拼接前会：
  1) 若存在未闭合的开始标签，先通过 `EnsureOpenTagClosed` 写入 `>`（必要时附带属性占位符）。
  2) 循环 `EndElement` 补齐所有未闭合元素。
- `EndElement`：
  - 若上一输出为文本（`FLastWasText=True`），闭合标签紧随同一行输出。
  - 若上一输出为 PI（`FLastWasPI=True`），必要时先输出 `#{NL0}` 再闭合；否则按常规 `WriteIndent`+`</name>`。

## 属性排序/去重（占位符替换）
- 写入阶段：属性一律 `EnqueueAttr` 入队；在关闭开始标签前，通过 `AppendAttrPlaceholder(ASelfClose)` 捕获当前属性组并在流中写入 `#{ATTRk}` 或 `#{ATTRk/}`。
- 格式化阶段：`PrettyFormat(S)` 扫描 `#{ATTRk}` 占位符并调用 `BuildAttrString` 生成属性串，然后替换占位符。
- `BuildAttrString`：
  - 去重（`xwfDedupAttrs`）：保留最后一次赋值。实现以稳定覆盖策略，对同名属性在临时数组中覆盖旧值，避免错误的删除/移动导致的越界。
  - 排序（`xwfSortAttrs`）：按名称字典序冒泡排序（简洁实现，规模小影响可忽略）。

## 命名空间与属性
- `WriteAttributeNS` 会在需要时声明命名空间（`xmlns`/`xmlns:prefix`），并将带前缀的属性名入队。属性命名空间不受默认 ns 影响。

## 测试约定摘要
- `TTestCase_Xml_Writer_Pretty_Strict` 校验：
  - Text 紧跟闭合同一行；注释/PI 各占独立行；自闭合 `<x/>` 格式正确。
  - PI 后在根级闭合时不强制 NL0；在嵌套级闭合时会先 NL0 再闭合。
- `TTestCase_Xml_Writer_Attr_Flags` 校验：
  - 排序、去重、组合三种模式的输出一致性。

## 用例 — 规则对照表（摘录）
- Test_Pretty_Exact_Nested_Empty → 空元素嵌套：子元素 `</x>`/`<x/>` 均按层级缩进，父闭合前换行。
- Test_Pretty_Comment_PI_Positioning → 注释/PI 独占行；若紧随 PI 处于嵌套级闭合，则先 NL0 再 `</name>`。
- Test_Pretty_SelfClosing_With_Attr_And_Nesting → 自闭合节点在同一行输出 `<node .../>`，兄弟与父闭合遵循缩进换行。
- Test_Pretty_NS_Text_Inline_Close_No_Isolated_Gt → 带前缀元素含属性与内联文本，`>` 与文本同一行输出，不出现行首孤立 `>`。
- Test_Attr_Sort / Test_Attr_Dedup_KeepLast / Test_Attr_Sort_Dedup_Combined → 占位符统一替换后输出，先去重后排序。

## 常见坑与调试提示
- 文档开头多余换行：确保 WriteIndent 在 `FBuffer.Length=0` 时直接返回。
- 连续换行：调用 WriteIndent 前检查 `EndsWithNLPlaceholder`，避免插入重复 NL 占位符。
- PI 后闭合位置异常：遇到 `FLastWasPI=True` 时，若当前深度>0 再插入 `#{NL0}`，根级闭合不需要。
- 属性去重导致崩溃：务必在临时数组上进行“最后一次覆盖”，再排序与拼接，避免就地删除导致的越界。
- 非 Pretty 输出仍出现占位符：确认 `StripAnyPlaceholders` 在 `Pretty=false` 路径执行。

## 维护建议
- 修改 Pretty 行为前先阅读上述规则，并回归运行 `tests\fafafa.core.xml\BuildOrTest.bat test`。
- 如需性能优化，优先优化占位符扫描与拼接；现实现已通过基准用例验证无 AV 与合理时延。
