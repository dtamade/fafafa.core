# 开发计划日志 — fafafa.core.bytes

目标（v0 已落地）
- Hex 编解码、切片/拼接/清零、端序读写、BytesBuilder

短期待办（本轮）
- [x] 跑通 tests/fafafa.core.bytes，观察边界/溢出行为
- [x] 补充 BytesBuilder API：AppendHex
- [x] 统一 TBytes 于 core.base，crypto Hex 代理至 core.bytes
- [x] 新增别名：HexFromBytes、BytesFromHex；新增 TryParseHexLoose

中期计划（v1）
- [ ] ByteBuf 风格：readerIndex/writeIndex、零拷贝 slice/duplicate
- [ ] BytesReader/BytesCursor 抽象
- [ ] 与 IO 模块的 reader/writer 适配器

风险与注意点
- 统一别名与单一实现已确立：TBytes 单一真源在 core.base；Hex 工具单一真源在 core.bytes
- 端序读写的溢出检查需保持严格一致性（抛 EOutOfRange）

