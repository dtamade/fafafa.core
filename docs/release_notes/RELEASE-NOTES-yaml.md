# Release Notes · YAML 模块（阶段性）

本说明面向使用者，汇总 YAML 模块当前阶段的能力与变更。更详细的工程变更请参阅 docs/CHANGES.md 与 report/fafafa.core.yaml.md。

## 概览
- 解析器：flow/非 flow 路径统一使用 tokenizer 驱动；对外事件序列不变（零语义变化）
- 切分器：增强对引号、!!tag、!<...>、关键字/数字等形态的切分（仅切分，不解语义）
- 连续分隔符策略：采用“容忍”，多余逗号将被跳过（如需严格校验可反馈需求）；分号不是 YAML 分隔符

## 使用者影响
- API 与事件序列不变，现有代码无需改动
- 引号内分隔符不会被拆分；flow/非 flow 行为保持一致
- 解析稳定性提升，对混合分隔/注释/空值/嵌套/quoted key/value 等场景更友好

## 快速回归
- Windows（Lazarus/FPC）：
  1) 进入 tests/fafafa.core.yaml/
  2) 运行 buildOrTest.bat
  3) 预期：全部通过（>50 项），无内存泄漏


## 实现路线调整（本轮）
- 统一采用 tokenizer（src/fafafa.core.yaml.tokenizer.pas）作为唯一切分实现。
- 移除历史重构遗留：src/fafafa.core.yaml.scan.pas、src/fafafa.core.yaml.input.pas、src/fafafa.core.yaml.scanner.pas。
- parse 占位单元已移除对 .scan 的引用，保持可编译。
- 示例 quick_example 与测试套件通过验证，未见回归。

## 已知限制与后续计划
- 编译器 warnings（case 未涵盖等）暂不收敛，待功能完全落地后统一处理
- TAG/ANCHOR/ALIAS 的语义层处理尚未启用，当前仅 tokenizer/scanner 级别切分
- 如需将“连续分隔符”改为严格校验，将在 parser 中增加校验并同步更新测试

## 反馈
- 欢迎就 YAML 模块用法、案例与需求提出反馈；我们将根据实际使用情况优先完善对应路径

