# fafafa.core.xml Examples

本目录包含 XML 模块的最小可运行示例：
- example_xml_reader.lpr：演示拉式 Reader 的事件遍历、忽略空白/注释、Text/CDATA/PI 处理
- example_xml_writer.lpr：演示 Writer 的默认/前缀命名空间、属性转义与 Pretty 输出
- example_writer_pretty_ns.lpr：展示 Pretty + 命名空间（默认/前缀）组合使用与注释/PI
- example_writer_attr_flags.lpr：展示属性排序(xwfSortAttrs)/去重(xwfDedupAttrs) 的效果
- example_writer_attr_pretty_combined.lpr：排序+去重+Pretty 组合演示
- example_xml_reader_autodecode.lpr：演示 AutoDecode 读取 UTF-16/32（带 BOM）输入并流式遍历

## 先决条件
- 已配置 tools\lazbuild.bat（可通过环境变量 LAZBUILD_EXE 指向 lazbuild.exe）

## 一键构建与运行

Windows:
```
examples\fafafa.core.xml\BuildExamples.bat
examples\fafafa.core.xml\RunExamples.bat
```

清理：
```
examples\fafafa.core.xml\CleanExamples.bat
```

输出路径：
- 可执行：examples/fafafa.core.xml/bin/
- 中间产物：examples/fafafa.core.xml/lib/

## CODEPAGE 提醒
- 示例/测试文件头已加 `{$CODEPAGE UTF8}`，避免 Windows 控制台中文输出异常；库单元不加该宏。

## 期望输出（示例节选）
- Reader（简化示例）：
```
Start<root> attrCount=0
Start<item> attrCount=1
Text="hello & world"
End</item>
...
Total <item> count = 2
```
- Writer（Pretty 模式）：
```
<?xml version="1.0" encoding="UTF-8"?>
<root version="1.0" xmlns="urn:demo">
  <ns1:item xmlns:ns1="urn:ns1" ns1:attr="value &amp; &quot;quoted&quot;">hello</ns1:item>
  <empty/>
</root>
```

