# fafafa.core.bytes — 通用字节序列工具（v0）

目标
- Hex 编解码（严格/宽松）
- 基础切片/拼接/清零
- 端序读写（LE/BE，u16/u32/u64）
- TBytesBuilder（累加器，近似 Go bytes.Buffer / 简化 ByteBuf）

设计要点
- 接口优先，异常统一到 fafafa.core.base（EInvalidArgument/EOutOfRange）
- 不依赖 crypto 子系统；与平台无关
- 零分配优先：读操作不分配；写操作尽量原位，越界抛错
- 统一类型：TBytes 由 fafafa.core.base 统一定义并全仓复用

主要 API
- Hex
  - BytesToHex(A: TBytes): string（别名 HexFromBytes）
  - HexToBytes(S: string): TBytes（别名 BytesFromHex） // 严格：偶数长度，仅 [0-9a-fA-F]
  - TryParseHexLoose(S, out B): Boolean // 宽松：忽略空白/0x/#（兼容旧名 TryHexToBytesLoose）
- 基础
  - BytesSlice(A, index, count): TBytes
  - BytesConcat(A, B): TBytes; BytesConcat(Parts: array of TBytes): TBytes
  - BytesZero(var A)
- 端序读写（越界抛 EOutOfRange）
  - Read/Write U16/U32/U64 的 LE/BE 变体
- TBytesBuilder（Init/Append/AppendByte/AppendUxx/AppendHex/ToBytes/EnsureCapacity）

竞品参考
- Rust bytes/BytesMut：Buf/BufMut trait 的端序读写与按需扩容
- Go bytes.Buffer：简单累加器模型
- Java ByteBuffer/Netty ByteBuf：读写索引 + 丰富端序 API（v1 可考虑演进）

已知限制
- 未提供 readerIndex/writeIndex 零拷贝视图（后续 v1）
- 与 crypto.pas 中的 HexToBytes 同名，建议需要两者同时使用时采用限定名或调整 uses 顺序（当前已在 crypto 门面代理至本单元）

测试
- 见 tests/fafafa.core.bytes/*（FPCUnit）
- 覆盖：Hex、切片/拼接、清零、端序读写、BytesBuilder

关联设计
- 统一类型别名策略详见 docs/framework_design.md
- ByteBuf（读写双指针与零拷贝视图）详见 docs/fafafa.core.bytes.buf.md

