# fafafa.core.bytes.buf — v1 设计与实现（阶段性）

已实现 API（原型）
- 索引/容量：ReaderIndex/WriterIndex/Capacity/ReadableBytes/WritableBytes
- 写：WriteU8/U16/U32/U64（LE/BE）、WriteBytes
- 读：ReadU8/U16/U32/U64（LE/BE）、ReadBytes(n)
- 视图：Slice(offset,len)、Duplicate()
- 维护：EnsureWritable(n)（仅 root 可扩容）、Compact()/DiscardReadBytes()（仅 root），ToBytes()

互操作 API
- FromBuilder(const BB: TBytesBuilder): IByteBuf（复制，避免别名）
- ByteBufToBuilder(const Buf: IByteBuf): TBytesBuilder（复制，保持独立性）

约束与语义
- Root 与 View：
  - Root：FOffset=0 且 FLen=Length(FBuf)，允许 EnsureWritable/Compact
  - View：由 Slice/Duplicate 派生，共享底层存储但索引独立；禁止扩容与 Compact
- 边界检查：
  - 读越界、写越界、视图非法操作一律抛 EOutOfRange
  - 参数非法抛 EInvalidArgument

示例（视图非法操作）
- 在 Slice/Duplicate 返回的视图上调用 EnsureWritable/Compact 将抛 EOutOfRange

规划（下一步）
- 策略：Compact/DiscardReadBytes 的性能权衡（何时触发、阈值）
- 更全面的视图一致性测试与文档化

背景与参考
- Rust bytes/BytesMut（Buf/BufMut）
- Java Netty ByteBuf（读写索引、slice/duplicate）
- Go bytes.Buffer（作为简化累加器参考）
