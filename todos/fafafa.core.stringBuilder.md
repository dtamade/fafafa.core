# 开发计划：fafafa.core.stringBuilder

## 当前目标
- 提供跨平台 UTF-8 字符串构建器接口与实现，并与现有 bytes 模块一致的增长策略

## 任务清单
- [x] 设计与实现 IStringBuilder/TUTF8StringBuilder
- [ ] 单元测试目录与用例
- [ ] 性能基准与与 TStringBuilder 对比
- [ ] 扩展便捷 API（AppendInt/AppendFloat）

## 备注
- 避免在热路径上进行多余的编码转换；尽量使用 AppendBytes 直写 UTF-8 数据
- 与 csv/json/toml writer 的互操作与替换评估

