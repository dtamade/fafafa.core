# YAML 模块对外 API 契约与兼容策略

本页明确 YAML 模块的对外契约，旨在保证调用方稳定升级与可预期行为。

## 对外可用范围（承诺兼容）
- 单元：`fafafa.core.yaml`
- 前缀：
  - 函数：`yaml_*`
  - 类型：`TYaml*` / `PYaml*`
  - 常量：`YAML_*`

上述符号在小版本升级中保持二进制/源级兼容（alpha 阶段除外，见下）。

## 内部实现（不承诺兼容）
- 单元：`fafafa.core.yaml.types` / `fafafa.core.yaml.impl` / `fafafa.core.yaml.scan` / `fafafa.core.yaml.doc` 等
- 前缀：`TFy*` / `PFy*` / `fy_*`

内部符号仅供模块内部使用，随实现演进可能变更或移除。

## 版本与阶段约定
- 当前阶段：alpha
  - 版本标签：`yaml-0.1.0-alpha.*` 或 `yaml-alpha*`
  - 在 alpha 阶段，我们尽量保持门面 API 稳定；如需变更，将在 Release Notes 明确说明

## 行为基线（当前实现）
- 解析器事件：支持标量、flow 映射 `{}`、flow 序列 `[]`，以及基本注释/空白处理
- 特性约束：不完全等同 YAML 1.2 规范；目标是最小可用+可渐进增强
- 实验性/非标准行为：默认关闭；如需开启，将通过明确的配置项（flags/options）控制并在文档中标注

## 使用建议
- 仅通过门面单元 `fafafa.core.yaml`
- 避免直接使用 TFy*/PFy* 或 fy_* 符号
- 升级前阅读 Release Notes / 支持矩阵，评估行为差异

