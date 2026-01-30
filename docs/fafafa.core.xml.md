# fafafa.core.xml

高性能、跨平台、接口优先的 XML 读写与流式处理模块（Pull/StAX 风格），支持命名空间、零拷贝读取视图、Pretty Writer。

## 设计理念
- 接口优先：Reader/Writer/Document/Node 抽象，便于替换与扩展
- 流式优先：在大文件场景避免 DOM 全载入；最小内存占用
- 错误模型统一：与 fafafa.core.json/toml 对齐，含行列定位
- 安全与性能：默认禁用 DTD/实体展开；Allocator 接口减少分配

## 公共 API（草案）
- Reader（零拷贝 N-系视图 + String 便利接口）：GetNameN/GetValueN/GetAttribute*NN/TryGetAttributeN 等，避免不必要分配，性能优先。

- Reader
  - IXmlReader
    - Read(): Boolean；Token: TXmlToken
    - 名称：Name/LocalName/Prefix/NamespaceURI
    - 值：Value；属性访问：AttributeCount/GetAttribute(i)/GetAttributeByName
    - Depth/IsEmptyElement/Line/Column/Position
  - CreateXmlReader(AAllocator: TAllocator = nil): IXmlReader
- Writer
  - IXmlWriter
    - StartElement/EndElement/WriteAttribute/WriteString/WriteCData/WriteComment/PI/Flush
    - WriteToString/WriteToStream/WriteToFile
  - CreateXmlWriter: IXmlWriter
- DOM 桥接（可选）
  - OpenDOM/SaveDOM：内部基于 fcl-xml 以减少依赖暴露

## 典型用法
- 流式读取
```pascal
var R: IXmlReader;
R := CreateXmlReader.ReadFromString('<root a="1"><x/>text</root>', [xrfIgnoreWhitespace]);
while R.Read do
begin
  case R.Token of
    xtStartElement: ;
    xtText: ;
    xtEndElement: ;
  end;
end;
```

- 写入
```pascal
var W: IXmlWriter;
W := CreateXmlWriter;
W.StartDocument('1.0','UTF-8');
W.StartElementNS('', 'root', 'urn:demo');
W.WriteAttribute('a','1');
W.StartElement('x');
W.EndElement; // x
W.WriteString('text');
W.EndElement; // root
WriteLn(W.WriteToString([xwfPretty]));
```

- 预期输出（Pretty）：

  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <root xmlns="urn:demo" version="1.0">
    <ns1:item xmlns:ns1="urn:ns1" ns1:attr="value &amp; &quot;quoted&quot;">hello</ns1:item>
    <empty/>
  </root>
  ```


### Writer Pretty 与命名空间（NS）
- Pretty 行为：
  - 每层缩进 2 个空格；元素、注释、PI 各占独立行
  - 写入 Text/CDATA/PI/Comment 前会自动关闭未闭合的开始标签
  - 自闭合元素保持 `<x/>` 形式；非自闭合 `</x>` 会在新行缩进输出
- 命名空间策略：
  - StartElementNS 会根据 URI 查找/复用前缀；必要时自动声明 xmlns 或 xmlns:prefix
  - 属性命名空间不受默认 ns 影响，需显式前缀；未绑定前缀会抛错/拒绝
  - 保留前缀约束：xml 只能绑定到 XML_NS_URI；xmlns 仅用于声明，不能绑定到其他 URI
- 实现说明：详见 docs/partials/xml.writer.pretty.md（占位符机制、属性排序/去重细节）
- 示例：参见 examples/fafafa.core.xml/example_writer_pretty_ns.lpr

## 支持矩阵（与当前实现对齐）
- Reader
  - 事件：StartElement/EndElement/Text/CDATA/Comment/PI/Whitespace
  - Flags：
    - xrfIgnoreWhitespace：已实现
    - xrfCoalesceText：已实现（字符串/流式均合并相邻 Text/CDATA，不跨 Comment/PI）
    - xrfAutoDecodeEncoding：阶段实现（UTF-8+BOM；启用后支持 UTF-16/32 自动转 UTF-8，冲突策略见“限制与兼容性”）
  - 行列/位置：支持 CRLF/CR/LF；字符串模式按需扫描；流式模式使用 token 快照
  - 命名空间：默认 ns 影响元素，不影响属性；未绑定前缀报错
- Writer
  - Flags：
    - xwfOmitXmlDecl：已实现（由 WriteToString 决策是否省略）
    - xwfPretty：已实现
    - xwfSortAttrs/xwfDedupAttrs：已实现（属性排序/去重，先去重后排序）
  - 命名空间：自动声明/复用前缀；保留 xml/xmlns 约束
- Freeze 最小 DOM
  - FreezeCurrentNode：在 StartElement 上冻结当前元素为只读节点
  - 提供 ElementNS/AttrNS；导航与属性访问 O(1)/O(attrs)

## Bench 使用与调优
- 构建 Bench 示例：
  - lazbuild examples\fafafa.core.xml\bench_xml_reader_file.lpi --bm=Debug
- 运行：
  - Windows PowerShell
    - $env:XML_BUF_SIZE=262144; examples/fafafa.core.xml/bin/bench_xml_reader_file.exe path\to\big.xml
- 编码注意：如输入为 UTF-16/32，建议开启 xrfAutoDecodeEncoding 或先离线转 UTF-8
- 调优建议：
  - 小缓冲（≤64KB）：低内存/随机 IO；跨块更频繁，FScratch 拼接更常见
  - 中缓冲（128–512KB）：吞吐/内存平衡，通用推荐
  - 大缓冲（≥1MB）：顺序 IO 且内存充裕，减少跨块次数
  - 逐 token 消费场景建议关闭 xrfCoalesceText；需要完整文本段可开启，但注意分配成本

## 构建与测试
- 构建：仅使用 lazbuild（不要直接调用 fpc）
- 单元测试：
  - 构建：lazbuild tests\fafafa.core.xml\tests_xml.lpi --bm=Debug
  - 运行：tests\fafafa.core.xml\bin\tests_xml.exe --all --format=plain
- 示例：
  - lazbuild examples\fafafa.core.xml\example_xml_reader.lpi --bm=Debug
  - lazbuild examples\fafafa.core.xml\example_xml_writer.lpi --bm=Debug
  - lazbuild examples\fafafa.core.xml\example_xml_config.lpi --bm=Debug
  - lazbuild examples\fafafa.core.xml\bench_xml_reader_file.lpi --bm=Debug

## 编码支持矩阵与示例
- 输入与行为（AutoDecode Off/On）：
  - UTF-8（无 BOM）：接受；声明 encoding=“UTF-8”亦可
  - UTF-8（有 BOM）：接受（BOM 跳过）；声明 UTF-8 亦可
  - UTF-16LE/UTF-16BE（有 BOM）：
    - Off：报 xecInvalidEncoding
    - On：自动转 UTF-8；若声明非 UTF-8 或与 BOM 冲突，报 xecInvalidEncoding
  - UTF-32LE/UTF-32BE（有 BOM）：
    - Off：报 xecInvalidEncoding
    - On：自动转 UTF-8；若声明非 UTF-8 或与 BOM 冲突，报 xecInvalidEncoding
  - 无 BOM + 声明非 UTF-8（如 UTF-16/32/ISO-8859-1）：Off/On 均报 xecInvalidEncoding（不依据声明转码）
- 示例（PowerShell）：
  - $env:XML_BUF_SIZE=262144; examples/fafafa.core.xml/bin/bench_xml_reader_file.exe path\to\utf16le.xml
    - 建议加 flag：xrfAutoDecodeEncoding
- 诊断技巧：在测试 runner 下可用 plainlog 或 junit 输出核对用例明细（见“构建与测试”）

## 限制与兼容性（当前阶段）
- 编码：
  - 默认 Assume UTF-8；支持跳过 UTF-8 BOM
  - 无 BOM 且声明 encoding 非 UTF-8（如 UTF-16/UTF-32/ISO-8859-1 等）：一律报 xecInvalidEncoding（不会基于声明转码）
  - 未开启 xrfAutoDecodeEncoding 时，如遇 UTF-16/UTF-32（带 BOM）将报 xecInvalidEncoding
  - 开启 xrfAutoDecodeEncoding 时：
    - 支持 UTF-16(LE/BE) 与 UTF-32(LE/BE) 的 BOM 识别与自动转码为 UTF-8
    - 如 BOM 与 XML 声明的 encoding 冲突，优先 BOM；若声明非 UTF-8 或与 BOM 指示不一致，报 xecInvalidEncoding（对应 tests 覆盖）
- DTD/外部实体：不处理，避免安全与复杂性（后续按需评估）
- 零拷贝切片：值类切片在“下一次 Read 前”有效；名称在流式模式会被持久化用于匹配
- 命名空间：默认 ns 仅作用于元素，不作用于属性；属性需前缀绑定
- 兼容性：FreePascal 3.2+/Lazarus 2.0+；跨平台优先

## 写入属性的排序与去重
- xwfSortAttrs：对开始标签中的属性按名字典序排序输出
- xwfDedupAttrs：属性重名时保留最后一次赋值（其余同名移除）
- 两者可组合使用：先去重再排序
- 组合示例输出（Pretty + Sort + Dedup）：

  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <root a="1" b="3">
    <child y="8" z="9"/>
  </root>
  ```

- 示例：参见 examples/fafafa.core.xml/example_writer_attr_flags.lpr

## 路线图
- v0：Reader/Writer MVP + NS + 错误模型 + 测试/示例（完成）
- v1：更细粒度的 EnsureLookahead、流式 Coalesce 精细化、性能基准与优化
- v2：编码自动检测/转码完善、可选 DOM 桥接/XPath 示例
