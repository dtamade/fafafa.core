# 工作总结 — fafafa.core.bytes（本轮）

进度与已完成
- 新增 src/fafafa.core.bytes.pas（v0）
  - Hex 编解码（严格/宽松）
  - 切片/拼接/清零
  - 端序读写（u16/u32/u64，LE/BE）
  - TBytesBuilder（累加器）
- 新增测试工程 tests/fafafa.core.bytes/* 并编写用例覆盖全部公开接口
- 新增 docs/fafafa.core.bytes.md 文档

问题与解决方案
- TBytes 类型统一性：先使用 RTL TBytes，避免与 crypto.interfaces.TBytes 冲突；如需全仓统一，可在后续将 TBytes 别名提升到 core.base 做统一导出
- HexToBytes 与 crypto 同名：文档提示使用限定名/uses 顺序规避；若需彻底规避可在后续改前缀

后续计划
- v1 方向：
  - 引入读/写索引、零拷贝 slice/duplicate 视图
  - BytesReader/BytesCursor 便于协议解析
  - 与 IO 模块协作（Reader/Writer 适配）
- 依据使用反馈决定是否把 TBytes 别名上移到 core.base 并清理各子模块的重复定义

