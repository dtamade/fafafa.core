# 开发计划日志：fafafa.core.ini

## 目标
- 提供现代、可扩展的 INI 解析/写出模块，接口优先，跨平台一致性。

## 今日（D1）
- [x] 门面与接口最小实现（Parse/ToIni）
- [x] 基础测试工程与脚本
- [x] 文档与报告

## 下一步
- [ ] 解析器替换为基于 Token 的条目序列，保留注释与顺序
- [ ] IIniDocument/IIniSection 扩展：TryGetInt/Bool/Float
- [ ] ToIni 支持注释回写、节间空行策略
- [ ] 行续接与转义处理（兼容常见实现）
- [ ] Bench 对比：IniFiles/TMemIniFile vs 本实现（解析/写出）

## 参考
- Rust: https://github.com/toml-rs/toml (风格参考)
- Go: https://github.com/go-ini/ini
- Java: Apache Commons Configuration (INI)
- .NET: Microsoft.Extensions.Configuration.Ini



## 今日（D2）计划
- [ ] 设计并实现轻量 tokenizer（引号感知的 inline comment 截断）
- [ ] 集成 tokenizer 到 InternalParseFromStrings，不改公开接口
- [ ] 增补测试：引号内 ;/#、未闭合引号错误、default-only+prelude、UTF-16 BOM 样例、错误定位断言
- [ ] 激活 per-section dirty 写出语义：未改节回放、已改节重组

## 备注
- HashMap 优化等待 fafafa.core.collections.hashmap 实现以后处理


## 今日（D3）计划（2025-08-22）
- [ ] Tokenizer 实现（状态机：Normal/SingleQuote/DoubleQuote；事件：KV 分隔、注释起始、行终止）
- [ ] 将 tokenizer 接入 InternalParseFromStrings（保留 Entries/Prelude/HeaderPad/BodyLines 行为）
- [ ] 新增/修复测试：
  - [ ] 行内注释引号边界（quotes、edge_quotes）
  - [ ] 错误定位（error_positions）
  - [ ] 编码样例（utf16_bom）
  - [ ] 回放场景（roundtrip_*）
- [ ] CLI inifmt 与 ToFile/ToIni flags 行为一致性抽样验证
