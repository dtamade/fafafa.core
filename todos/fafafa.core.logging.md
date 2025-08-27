# fafafa.core.logging TODO / 日志

## M1（进行中）
- [x] 设计接口与 Facade 草案
- [x] 默认 SimpleLogger/Factory + ConsoleSink + TextFormatter
- [x] JsonFormatter 基本版
- [x] 测试工程与冒烟用例（Console/Text/Json、AsyncTextSink 适配器）
- [x] TextFormatter 追加 attrs 输出
- [ ] 文档补充更多示例与 API 节摘要

## M2（计划）
- [ ] AsyncQueueSink（有界队列、批量刷新、丢弃策略/Flush）
- [ ] 基准压测脚手架（对比 Console 同步）

## M3（计划）
- [ ] FileSink + Rolling（大小/日期）、路径策略
- [ ] Text/JSON 格式化开关与字段排序

