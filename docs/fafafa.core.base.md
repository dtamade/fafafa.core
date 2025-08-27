# fafafa.core.base — 基础约定与统一别名

统一类型
- TBytes = array of Byte （全仓唯一真源）

统一异常
- EInvalidArgument, EOutOfRange 等作为核心异常类型，由 core.base 定义并在各模块复用

使用指引
- 任意需要字节序列的模块：uses fafafa.core.base 并使用 TBytes
- 需要 Hex/端序/构建器：uses fafafa.core.bytes
- 命名冲突（如 HexToBytes）时使用限定名（fafafa.core.bytes.HexToBytes）或调整 uses 顺序

关联文档
- docs/framework_design.md（统一类型别名策略）
- docs/fafafa.core.bytes.md（字节序列 API）

