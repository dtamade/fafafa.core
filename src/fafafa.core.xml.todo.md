# fafafa.core.xml 开发计划与现状

更新时间：2025-08-12（晚）

## 模块定位
- 路径：src/fafafa.core.xml.pas
- 职责：提供高性能、跨平台、接口优先的 XML 读写与流式处理能力（Pull-Parser 类似 Java StAX），并可选对接 DOM（FPC fcl-xml）。
- 设计理念：
  - 面向接口抽象：IXmlReader/IXmlWriter/IXmlDocument/IXmlNode
  - 流式优先：在大文件场景避免 DOM 全量载入，逐步消费事件
  - 选项丰富：忽略空白、合并文本、保留注释、编码控制、命名空间
  - 错误模型与 JSON/TOML 对齐：TXmlReadFlag/TXmlWriteFlag/TXmlError/EXmlParseError
  - 内存策略与 allocator 对齐（fafafa.core.mem）

## 仓库现状扫描（简述）
- 已存在 src/fafafa.core.xml.pas：
  - IXmlReader/IXmlWriter/IXmlNode/IXmlDocument 接口与枚举初稿已定义；
  - 解析器 TXmlReaderImpl 具备最小功能（Start/EndElement、Text、属性、Whitespace、XML 声明跳过、零拷贝切片），尚未实现注释/CDATA/PI/实体解码/行列号；
  - 存在 TXmlReaderStub（占位），其 Read 方法代码结构损坏（中途插入了函数定义），疑似无法编译；
  - Writer 仅有 TXmlWriterStub，未实现 Create 构造函数；使用 TStringBuilder 但未构造即使用，存在崩溃隐患；
- 其他模块（json/toml）有成熟接口与 TDD 结构，可对齐风格与规范。

### 立即编译风险（P0）
1) TXmlReaderStub.Read 语法损坏，需修复或删除 Stub；
2) TXmlWriterStub.Create 缺失实现，FBuffer 未初始化；
3) TStringBuilder 兼容性需确认，必要时改为自管 StringBuffer；
4) Reader 多数 Flags 未生效；行列号定位未实现。

## 调研摘要（FPC XML 生态）
- fcl-xml（跨平台）：常用单元 DOM, XMLRead, XMLWrite, XMLUtils, XMLConf 等。
- DOM 方式（ReadXMLFile/WriteXMLFile + TXMLDocument）易用但全量载入，占用内存大。
- Lazarus 亦有 laz2_* 前缀的 DOM/XMLRead 变体（可选依赖，尽量不强制）。
- Pull/SAX：fcl-xml包含 SAX 接口单元，但为保持轻依赖与一致 API，初期优先实现轻量 Pull 解析器（不支持 DTD/实体扩展），后续再封装 fcl-xml SAX。

## 初版范围（MVP）
- Reader（Pull）：
  - Token：StartElement/EndElement/Text/CData/Comment/PI/Whitespace/EndDocument
  - 属性与命名空间读取（基本 QName 解析），不实现 DTD/实体展开（文档模式：Well-formed）
  - 输入：String/Pointer/Stream；默认 UTF-8；根据 XML 声明尝试识别编码（先限定 UTF-8，编码识别列为后续）
  - Flags：IgnoreWhitespace、CoalesceText、IgnoreComments、AllowInvalidUnicode（与 JSON 命名风格一致）
  - 错误定位：行列与字节偏移
- Writer：
  - StartElement/EndElement/WriteAttribute/WriteString/WriteCData/WriteComment/PI
  - Pretty/紧凑输出；换行与缩进控制
  - 输出到 String/Stream/File
- DOM 桥接（可选）：
  - OpenDOM(const Text|File|Stream): IXmlDocument（内部使用 fcl-xml 读取）
  - SaveDOM(IXmlDocument, ...)
- 对齐：异常类型、错误记录、CreateXmlReader/Writer 工厂函数，与 json 模块相似接口外观。

## API 草案（与 json/toml 风格对齐）
- 枚举：
  - TXmlToken = (xtStartElement, xtEndElement, xtText, xtCData, xtComment, xtPI, xtWhitespace, xtEndDocument)
  - 读写 Flags：TXmlReadFlag/TXmlWriteFlag; 集合 TXmlReadFlags/TXmlWriteFlags
- 错误：
  - TXmlErrorCode = (xecSuccess, xecInvalidParameter, xecMalformedXml, xecUnexpectedEnd, xecInvalidName, xecInvalidEncoding, xecFileIO, xecMemory)
  - TXmlError = record(Code, Message, Position, Line, Column)
  - EXmlError/EXmlParseError/EXmlWriteError/EXmlValueError
- 接口：
  - IXmlReader: Read(): Boolean; Token/Name/LocalName/Prefix/NamespaceURI/Value/Depth/Attribute APIs
  - IXmlWriter: StartElement/EndElement/WriteAttribute/WriteString/Flush; WriteToString/File/Stream
  - IXmlNode/IXmlDocument: DOM 抽象（根、遍历、属性）
- 工厂：
  - CreateXmlReader(AAllocator: TAllocator = nil): IXmlReader
  - CreateXmlWriter: IXmlWriter

## TDD 计划
- 目录：tests/fafafa.core.xml/
  - tests_xml.lpi + BuildOrTest.bat/.sh（调用 tools/lazbuild.bat，Debug，开启泄漏检测）
  - Test_fafafa_core_xml.pas（Global/Smoke）
  - Test_fafafa_core_xml_reader.pas（元素/属性/命名空间/自闭合/文本/CDATA/注释/PI/错误路径）
  - Test_fafafa_core_xml_writer.pas（Pretty/紧凑/属性转义/空元素）
  - 如需：Test_fafafa_core_xml_dom_bridge.pas

## 示例与 Play
- examples/fafafa.core.xml/: example_xml.lpi，演示：
  - 流式读取统计元素计数、筛选节点
  - Writer 生成简单配置文件
- play/fafafa.core.xml/: 用于小试验与验证

## 迭代路线
1) 定义接口与错误类型（不落地实现，先可编译）
2) Reader 最小可用：Start/EndElement、Text、自闭合、属性、简单命名空间；UTF-8 only
3) Writer 最小可用：Start/End、属性、文本、Pretty/紧凑
4) DOM 桥接（需要时）
5) 编码/命名空间细节完善、性能调优（分配减少、零拷贝读取）
6) 文档与示例完善

## 风险与约束
- XML 规范复杂度高：暂不支持 DTD/实体展开/外部实体，避免安全风险
- 编码识别阶段性限制：先 UTF-8，后续再扩展
- 命名空间边界：先覆盖常见用法，严格校验列为增强项

## 近期成果
- 修复 Reader 非自闭合开始标签未绑定前缀的校验位置
- 测试 26/26 全绿；0 泄漏
- ReadFromStream 优化：支持快速路径 ReadBuffer + 分块回退
- 新增示例与基准（内存/文件）可运行
  - bench_xml_reader：5.59MB，0.359s，14.8 MB/s
  - bench_xml_reader_file：5.59MB，0.125s，42.6 MB/s

## 下一步任务（立即）
- 真流式解析（环形/双缓冲，不累积整串）：保持 API，不改变对上语义
- 增加跨块专项用例（长文本/属性/CDATA/注释/PI/NS）
- 基准扩展：payload/深度矩阵 + 引入 fcl-xml 对比（MB/s + 内存峰值）
- 更新 docs 性能概览

