# fafafa.core.id 开发计划日志（M1→M2）

## 目标（M1）
- 提供 UUID v4/v7 生成、序列化/解析、v7 时间戳提取
- 对齐 RFC 9562；跨平台；零外部依赖（复用内部 CSPRNG）

## 现状（本轮完成）
- UUID v4/v7、ULID、KSUID、Snowflake 全部落地
- ULID 单调器已提供（IUlidGenerator）
- 测试与示例工程就绪

## 下一步（可执行）
- [x] 文档增强：数据库字段建议（UUID/ULID BINARY(16)，KSUID BINARY(20)，Snowflake BIGINT）、索引与排序示例
- [x] 统一时间来源：新增 fafafa.core.id.time 并在各模块采用（基于 fafafa.core.time）
- [x] 示例增强：启用 Base64URL/Base58 编解码输出
- [ ] Snowflake 配置：workerId/epoch 来源与默认策略说明
- [ ] 编解码扩展：UUID 无连字符解析（Relaxed）API 包装（TryParseUuidNoDash/UuidToStringNoDash）
- [ ] 单元测试分层：为 UlidMonotonic/Snowflake 分设 TTestCase 并显式覆盖全部公开接口

## 研究事项
- Snowflake 时钟回拨策略的可插拔化（wait/throw/fallback）与观测指标
- 编解码扩展的跨语言兼容性（base62/base58 variant 差异）

