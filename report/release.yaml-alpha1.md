# Release: yaml-alpha1

本次里程碑聚焦 YAML 模块的最小可用与对外契约，完成门面稳定、解析器增强、测试与示例就绪。

## 亮点
- 门面 API 完成：统一通过 `fafafa.core.yaml` 暴露 yaml_* / TYaml* / YAML_*；内部 TFy*/PFy* 保持实现细节
- 解析器增强：
  - 正确处理 flow 序列项为内嵌映射的情况（+MAP, 键/值, -MAP 作为一个序列项）
  - flow 映射的值可为嵌套 flow 映射或序列
  - 更鲁棒的分隔符与注释混合场景（遵循规范；非标准分隔符不作为默认行为）
- 文档与示例：
  - docs/yaml_quickstart.md（快速上手）
  - docs/yaml_api_contract.md（对外 API 契约与兼容策略）
  - docs/yaml_support_matrix.md（支持特性矩阵）
  - examples/fafafa.core.yaml/quick_example（win/unix 运行脚本）

## 质量
- 测试：58/58 全部通过
- 内存：heaptrc 0 泄漏
- 编译：少量 Note（如 inline 未内联），不影响功能

## 兼容性
- 对外不再暴露 fy_*；仅通过 `fafafa.core.yaml` 门面访问
- alpha 阶段，尽量保持门面 API 稳定；如需变更，会在 Release Notes 明确说明

## 手工验收（无 CI）
- 运行 tests/fafafa.core.yaml/buildOrTest.bat → 期望 58/58 通过
- 运行 examples/fafafa.core.yaml/quick_example/run_example_win.bat（或 run_example_unix.sh）→ 期望事件序列正确打印

## Tag 建议
- yaml-alpha1 或 yaml-0.1.0-alpha.1


