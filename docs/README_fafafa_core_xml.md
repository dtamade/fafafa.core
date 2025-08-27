# fafafa.core.xml 使用说明（Reader/Writer + Freeze 最佳实践）

本说明涵盖 XML Reader 的字符串/流式读取、Writer 的格式化输出，以及最小 DOM 冻结（FreezeCurrentNode）的使用建议。

## 关键概念

- 流式模式：通过 ReadFromStream 接口从 TStream 逐段读取，内部分块并维护滑动窗口。
- 切片有效期：零拷贝设计下，值类切片在“下一次 Read 调用前”有效；名称在流式模式会被持久化以用于匹配。
- 延迟压实：token 返回后不立即移动缓冲区，在下一次 Read 前压实，确保当前切片稳定。
- 文本合并：启用 xrfCoalesceText 后，相邻 Text/CDATA 将合并为一个 xtText（字符串模式合并全部；流式模式最小合并）。

## 使用建议

- 长期使用的值请复制，特别是流式模式的 Value 切片。
- 命名空间：元素 NamespaceURI 受默认命名空间影响，属性则不受默认命名空间影响（需前缀绑定）。
- 冻结 DOM：在 xtStartElement 上调用 FreezeCurrentNode 获取只读节点对象，遍历/读取属性等；生命周期由返回的 IXmlDocument/IXmlNode 引用保持。

## 示例

- Reader（字符串，与 xrfCoalesceText）：
```pascal
var R: IXmlReader;
begin
  R := CreateXmlReader.ReadFromString('<root>aa<![CDATA[bb]]>cc</root>', [xrfCoalesceText]);
  while R.Read do
    if R.Token = xtText then
      WriteLn(R.Value); // aabbcc（字符串模式合并全部 Text/CDATA）
end;
```

- Reader（流式，与 xrfIgnoreWhitespace + xrfCoalesceText）：
```pascal
var R: IXmlReader; Tok: TXmlToken;
begin
  R := CreateXmlReader.ReadFromStream(AStream, [xrfIgnoreWhitespace, xrfCoalesceText]);
  while R.Read do
  begin
    Tok := R.Token;
    case Tok of
      xtStartElement: WriteLn('Start: ', R.Name);
      xtText:        WriteLn('Text: ', Copy(R.GetValue, 1, 32), '...');
    end;
  end;
end;
```

- 实战（Reader→Freeze→Writer）：
```pascal
var R: IXmlReader; D: IXmlDocument; N: IXmlNode; W: IXmlWriter; S: String; i: SizeUInt;
begin
  // 读入并构建最小 DOM（同时可用流式逐步消费）
  R := CreateXmlReader.ReadFromString('<r xmlns="urn:d"><a:node xmlns:a="urn:a" a:k="v">t</a:node></r>', [xrfCoalesceText]);
  D := R.ReadAllToDocument; // 若你的版本尚无该便捷函数，可用循环 Read + Freeze 构建
  N := D.Root;
  // 遍历节点与属性（示意）
  for i := 0 to N.GetChildCount-1 do
    WriteLn('child: ', N.GetChild(i).LocalName, ' ns=', N.GetChild(i).NamespaceURI);
  // 写回字符串（省略声明 + pretty）
  W := CreateXmlWriter;
  W.StartDocument('1.0','UTF-8');
  W.StartElement('root');
  W.WriteString('payload');
  W.EndElement;
  W.EndDocument;
  S := W.WriteToString([xwfOmitXmlDecl, xwfPretty]);
  WriteLn(S);
end;
```

- Writer（省略声明 + Pretty）：
```pascal
var W: IXmlWriter; S: String;
begin
  W := CreateXmlWriter;
  W.StartDocument('1.0','UTF-8');
  W.StartElement('root');
  W.WriteString('hello');
  W.EndElement;
  W.EndDocument;
  S := W.WriteToString([xwfOmitXmlDecl, xwfPretty]);
  // 结果无 XML 声明，且缩进/换行已格式化
end;
```

## Flags 与 Freeze 详情

参见 docs/partials/xml.flags_and_freeze.md：
- Reader/Writer Flags 行为与当前支持情况
- Freeze DOM 的结构、访问器与复杂度
- 换行与编码策略说明

## 支持矩阵（简版）
- Reader：
  - xrfIgnoreWhitespace：已实现
  - xrfCoalesceText：已实现（字符串/流式均支持；不跨 Comment/PI）
  - xrfAutoDecodeEncoding：阶段实现（UTF-8+BOM；开启时 UTF-16/32 自动转 UTF-8）
- Writer：
  - xwfOmitXmlDecl：已实现（由 WriteToString 决策）
  - xwfPretty：已实现
  - xwfSortAttrs/xwfDedupAttrs：已实现（属性排序/去重后再输出）
- Freeze：
  - 元素 NamespaceURI：已实现（ElemNS）
  - 属性 NamespaceURI：已实现（AttrNS）

## 变更记录（摘要）
- 新增：xrfCoalesceText 完整合并（字符串/流式）
- 新增：xwfOmitXmlDecl 生效（声明由 WriteToString 统一决策）
- 新增：XmlReadAllToDocument 便捷函数
- 新增：冻结元素 NamespaceURI（IXmlNode.NamespaceURI 返回真实 URI）

## 缓冲区大小与调优

- 初始缓冲默认值：256KB
- 可通过重载设置：ReadFromStream(AStream, Flags, InitialBufCap) / ReadFromFile(FileName, Flags, InitialBufCap)
- 调优建议：
  - 小缓冲（<=64KB）：低内存或随机 IO；跨块更频繁，FScratch 拼接更常见
  - 中等缓冲（128–512KB）：吞吐/内存平衡，一般推荐
  - 大缓冲（>=1MB）：顺序 IO 且内存充裕，减少跨块次数

## 性能 / 内存权衡

- xrfCoalesceText：
  - 优点：减少上层 token 合并逻辑、降低 token 数、可能提升吞吐
  - 代价：长文本时 FScratch/FValueOwned 分配增多；推荐在需要“完整文本段”的场景开启
- xwfOmitXmlDecl：
  - 优点：输出更简洁、便于内嵌
  - 代价：丢失 encoding 提示；适合明确 UTF-8 或外层容器已知编码的场景
- xwfPretty：
  - 优点：便于阅读与 diff
  - 代价：额外字符串处理成本；生产环境如追求吞吐，可关闭

## 性能指南速查（场景 → 建议）

- 顺序读取大文件，逐 token 消费（低内存）：
  - Reader：ReadFromStream([...])，缓冲 256–512KB；关闭 xrfCoalesceText；避免复制 Value
  - Writer：默认；关闭 xwfPretty；按需 xwfOmitXmlDecl
- 需要获取完整文本段（如提取正文）：
  - Reader：开启 xrfCoalesceText；注意长文本分配；仍建议逐 token 消费
  - Writer：可配合 xwfPretty 便于对比
- 嵌入到其它容器（编码已知）：
  - Writer：开启 xwfOmitXmlDecl；默认 UTF-8
- 人工审核/调试输出：
  - Writer：开启 xwfPretty；必要时保留 XML 声明便于外部工具识别编码
- 小缓冲（<=64KB）或随机 IO：
  - Reader：预期跨块多，合并/拼接更频繁；根据场景权衡 xrfCoalesceText；若只做过滤，可关闭合并以减少分配

> 编码支持（当前阶段）：默认 AssumeUTF8；Reader 支持 UTF-8（含 BOM 自动跳过）。未开启 AutoDecode 时，检测到 UTF-16/UTF-32 BOM 将抛出 xecInvalidEncoding；当开启 xrfAutoDecodeEncoding 时，支持 UTF-16(LE/BE) 与 UTF-32(LE/BE) 自动转码为 UTF-8。
- Flags 与编码（当前实现）：
  - 默认行为 AssumeUTF8：仅接受 UTF-8（含 BOM），遇 UTF-16/UTF-32 报 xecInvalidEncoding
  - xrfAutoDecodeEncoding：启用对 UTF-16(LE/BE) 与 UTF-32(LE/BE) 的自动转码→UTF-8



## Bench 使用

- 通过环境变量 XML_BUF_SIZE 指定缓冲大小（Windows PowerShell 示例）：
  $env:XML_BUF_SIZE=262144; examples/fafafa.core.xml/bin/bench_xml_reader_file.exe path\to\big.xml

## 测试

- 跨块用例：
  - Test_fafafa_core_xml_reader_stream_chunks.pas（Text/CDATA/PI）
  - Test_fafafa_core_xml_reader_stream_smallbuf.pas（极小缓冲文本+实体）
  - Test_fafafa_core_xml_reader_attr_entities_smallbuf.pas（极小缓冲属性值+实体）

## 兼容性与限制

- FreePascal 3.2+ / Lazarus 2.0+
- 实体解码遵循既有实现；跨块拼接已覆盖 Text/CDATA/PI 与属性值；CRLF/CR 行列定位已修复

## 后续优化方向

- 更细粒度的 EnsureLookahead 策略
- xrfCoalesceText 在流式模式的完全相邻合并（可选）
- Reader 编码：BOM/encoding 解析与可选转码

