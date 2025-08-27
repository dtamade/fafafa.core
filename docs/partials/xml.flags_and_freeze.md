# fafafa.core.xml Flags 与 Freeze DOM 说明

本说明补充 Reader/Writer 标志位行为、冻结最小 DOM 的接口与复杂度，以及换行/编码策略。

## Reader Flags
- xrfIgnoreWhitespace：忽略节点间纯空白（Whitespace 事件不返回）
- xrfCoalesceText：合并相邻 Text/CDATA（字符串与流式路径均合并任意连续的 Text/CDATA；跨块时通过安全拼接保持值一致；不会跨 Comment/PI 合并）
- xrfAllowInvalidUnicode：预留，后续用于配置无效序列/码点的处理（报错/替换/直通）

## Writer Flags
- xwfPretty：启用占位符换行与缩进，最终通过 ReplaceNewlinePlaceholders 格式化
- xwfOmitXmlDecl：省略 XML 声明（StartDocument 之后如未即时输出声明，EndDocument/WriteToString 也不会补）
- xwfSortAttrs：按名称字典序输出属性（与去重可组合）
- xwfDedupAttrs：去重同名属性，保留最后一个

## Freeze 最小 DOM
- FreezeCurrentNode：在 xtStartElement 上冻结当前元素为只读节点，返回 IXmlNode
- 结构：保留元素名、ElementNS、属性名/值及 AttrNS；子节点可延迟冻结
- 访问器：
  - Name/LocalName/Prefix/NamespaceURI（元素）
  - GetAttributeName/GetAttributeValue
  - GetAttributeLocalName/GetAttributePrefix/GetAttributeNamespaceURI
- 复杂度：
  - 冻结当前节点 O(attrs)；属性名/值/命名空间按需复制
  - 遍历兄弟/父节点为 O(1) 引用跳转

## 换行与行列
- Reader 行列定位：已支持 CRLF 视作单一换行，也支持 CR-only/LF-only；
  - 字符串模式：每次按需扫描（ComputeLineColumnAt）以确保准确性；
  - 流式模式：使用 token 快照 FTokLine/FTokColumn。

## 编码策略（现状与计划）
- 现状：
  - ReadFromFile(字符串路径)：不解析 BOM/声明编码，假定上层提供兼容编码（建议统一 UTF-8）；
  - ReadFromStream：按字节读取，尚未内建 BOM/encoding 解析与转码；
- 计划：
  - 增加 BOM/声明 encoding 的检测，提供自动转码或“原始字节 + 指定编码”双模式；
  - 文档升级后给出兼容性矩阵与示例。

