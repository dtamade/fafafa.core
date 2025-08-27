# fafafa.core.yaml 本轮“可交付”收尾说明（2025-08-20）

## 范围与目标
- 落地门面 API：yaml_* / TYaml* / YAML_*，隐藏 TFy*/PFy*
- 对齐移植基线：解析器/事件/基础类型与最小文档模型/发射器接口
- 测试 58/58 通过，避免行为新增/破坏

## 交付检查
- 对外 API：统一门面单元 `fafafa.core.yaml` 导出；未暴露 fy_*
- 内部单元头部标注：yaml.types / yaml.scan / yaml.doc
- 文档：docs/yaml_quickstart.md，docs/README.md 索引，report/fafafa.core.yaml.md（设计进度）
- 构建与测试：tests/fafafa.core.yaml/buildOrTest.bat → 58/58，heaptrc 0 泄漏

## 剩余工作（后续迭代）
- 扩充 tokenizer/scan 细节与完整 parser 覆盖
- 文档模型与发射器完整实现
- 性能与内存优化；错误诊断系统

## 文档新增
- docs/yaml_api_contract.md（对外 API 契约）
- docs/yaml_support_matrix.md（支持特性矩阵）
- examples/fafafa.core.yaml/quick_example（最小可运行示例）


本轮状态：可交付（内部演示与基础能力验证）。


## 实现去重与路线统一（本轮新增）
- 决策：统一采用 tokenizer 路线（src/fafafa.core.yaml.tokenizer.pas），移除早期重构遗留的 scan/input/scanner 实现栈。
- 已移除文件：
  - src/fafafa.core.yaml.scan.pas
  - src/fafafa.core.yaml.input.pas
  - src/fafafa.core.yaml.scanner.pas
- 占位修复：
  - src/fafafa.core.yaml.parse.pas 去除对 .scan 的 uses，并保留解析器骨架（待后续对接 tokenizer 状态）。
- 影响评估：
  - 门面/实现/示例/测试的活跃路径均基于 tokenizer，不依赖上述已删单元；quick_example 运行验证通过。
- 脚本优化：
  - examples/fafafa.core.yaml/quick_example/run_example_win.bat 支持优先固定 FPC 路径、否则回退 PATH。

