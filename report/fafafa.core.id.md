# fafafa.core.id 工作总结报告（阶段更新）

## 进度与已完成项
- ✅ 在线调研：RFC 9562（May 2024）复核；v4/v7 选择建议与排序/索引影响
- ✅ UUID 核心：src/fafafa.core.id.pas（v4/v7 生成、解析、序列化、v7 时间戳提取）
- ✅ ULID：src/fafafa.core.id.ulid.pas（生成/编解码/时间戳），docs/fafafa.core.id.ulid.md
- ✅ KSUID：src/fafafa.core.id.ksuid.pas（生成/编解码/时间戳），docs/fafafa.core.id.ksuid.md
- ✅ Snowflake：src/fafafa.core.id.snowflake.pas（线程安全，回拨等待），docs/fafafa.core.id.snowflake.md
- ✅ ULID 单调器：src/fafafa.core.id.ulid.monotonic.pas（同毫秒内递增，线程安全）
- ✅ 测试：tests/fafafa.core.id/（UUID/ULID/KSUID/Snowflake 用例）
- ✅ 示例：examples/fafafa.core.id（打印 4 类 ID 与时间戳）

## 遇到的问题与解决方案
- 时间来源统一：采用 DateUtils 计算 Unix 毫秒；封装 NowUnixMs（保持可替换）
- 版本/Variant 比特：按 RFC 设置 v4/v7 的 version nibble 与 IETF variant（10b）

## 后续计划
- [ ] 文档补充：数据库 BINARY(16)/BINARY(20)/BIGINT 字段建议与索引实操
- [ ] Snowflake：可配置 workerId/epoch（环境变量/配置中心/命令行）
- [ ] 编解码扩展：Base58/Base64URL；UUID 无连字符解析（Relaxed）
- [ ] 性能对比与基准：多线程吞吐测试（各方案 10w/100w 样本）



## 本轮进展（2025-08-22）
- ✅ 修复与完善：
  - 修正 tests/fafafa.core.id/BuildOrTest.bat 执行路径（nbin -> bin）
  - id.codec：将 Base58 编码入口参数改为 const，避免“const 变量赋值”编译错误
  - ulid.monotonic：补充对 fafafa.core.crypto.random 的 uses 以访问 GetSecureRandom
  - 统一时间来源：新增 src/fafafa.core.id.time.pas，所有 ID 模块改用统一 NowUnixMs/NowUnixSeconds（基于 fafafa.core.time）
  - 示例增强：examples/fafafa.core.id/example_id.lpr 启用 PrintEncodings 输出 Base64URL/Base58 示例
- ✅ 验证：tests/fafafa.core.id 全部 17 项用例通过（E=0, F=0），Win64 下 -gl 启用无异常

## 下一步计划
- 文档补充：数据库字段与索引建议、跨语言兼容性提示
- Snowflake 配置来源建议（env/args/配置中心）与最佳实践
- 增加性能基准示例与测量脚本（多线程吞吐）


- ✅ 文档增强：
  - docs/fafafa.core.id.md 增补数据库字段/索引建议（MySQL/PostgreSQL 示例）
  - docs/fafafa.core.id.ksuid.md 增补 BINARY(20)/文本 27 字符 DDL 示例与排序规则建议
- ✅ 用例增强：
  - 新增 KSUID 跨秒字典序测试（确保文本编码跨秒严格递增）
