# 开发计划日志 — fafafa.core.bytes

## 目标演进

### v0（已落地）
- Hex 编解码、切片/拼接/清零、端序读写、BytesBuilder

### v0.1（本轮优化完成）
- [x] 性能优化：内存增长策略分层优化
- [x] API一致性：统一异常处理
- [x] 新增高性能批量操作：AppendFill、AppendRepeat
- [x] 关键路径内联优化
- [x] 文档与示例更新

## 短期待办（已完成）
- [x] 跑通 tests/fafafa.core.bytes，观察边界/溢出行为
- [x] 补充 BytesBuilder API：AppendHex
- [x] 统一 TBytes 于 core.base，crypto Hex 代理至 core.bytes
- [x] 新增别名：HexFromBytes、BytesFromHex；新增 TryParseHexLoose
- [x] 优化内存增长策略
- [x] 统一错误处理
- [x] 新增批量操作API

## 中期计划（v1）
- [ ] ByteBuf 风格完善：readerIndex/writeIndex、零拷贝 slice/duplicate
- [ ] BytesReader/BytesCursor 抽象
- [ ] 与 IO 模块的 reader/writer 适配器
- [ ] 性能基准测试框架
- [ ] SIMD 加速支持

## 长期规划
- [ ] 内存池集成
- [ ] 压缩算法集成
- [ ] 网络序列化优化

## 风险与注意点
- 统一别名与单一实现已确立：TBytes 单一真源在 core.base；Hex 工具单一真源在 core.bytes
- 端序读写的溢出检查需保持严格一致性（抛 EOutOfRange）
- 新增API需要相应的测试用例覆盖
- 性能优化需要基准测试验证效果

