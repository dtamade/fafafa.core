# fafafa.core.stringBuilder

目标：提供一个高性能、跨平台的“编码无关”字符串构建器（类似 Go strings.Builder / Java StringBuilder），支持链式 API 与容量管理，遵循项目接口优先策略。

## 设计摘要
- 接口：IStringBuilder
- 实现：TStringBuilderRaw（内部以 TBytesBuilder 聚合，按 1.5x 增长）
- 编码无关：Append/AppendBytes 原样拷贝字节，Length 表示“字节长度”；不内置任何编码/校验
- 导出：ToString（原样转为 string）、AsBytes（TBytes 拷贝）
- 工厂：MakeStringBuilder(ACapacity: SizeInt = 0)

## API 概览
- Capacity/Length/EnsureCapacity/Clear
- Append(string), AppendLine(), AppendLine(string)
- AppendChar(Char)
- AppendBytes(TBytes|Pointer,Count)

## 互操作
- 与 fafafa.core.bytes 的 TBytesBuilder 统一增长策略
- 可用于日志、文本序列化、临时缓冲

## 性能建议
- 追加大量小片段时，预估容量调用 EnsureCapacity

## 未来扩展
- 增加 Format/AppendInt/AppendFloat 快速路径
- 可选的 UTF-8 适配器单元（独立于核心 builder）

