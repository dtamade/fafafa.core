# YAML 模块阶段性变更说明（Unreleased）
# TOML 模块阶段性变更说明（Unreleased）

本说明记录了本轮对 TOML 模块（fafafa.core.toml）的修复与增强，聚焦一致性、性能与可迁移性。

## 变更摘要
- Reader：修正 TryGet* 语义（仅路径存在且类型匹配时返回 True）；新增 Has/TryGetValue 通用 API
- Parser：新增 `trfUseV2`，在 Parse 时可路由到 v2 解析器；v2 禁止 NaN/Inf（与 TOML 1.0 一致）
- Builder：表写入防重复键（同键覆盖，不追加）；数组强制同构类型
- Writer：优化字符串转义与输出行缓冲，避免 O(n^2) 拼接；默认等号风格为 `key = value`，`twfTightEquals` 为紧凑
- 文档：更新 flags 说明，新增升级指南 docs/UPGRADE-fafafa.core.toml-v2.md
- 测试：新增 Has/TryGetValue 与 v2 路由 smoke 用例；全量用例通过

## 兼容性与注意事项
- TryGet* 行为收紧：历史代码若使用默认值或空串判断“存在性”，请迁移到 Has/TryGetValue 或检查返回 Boolean
- `twfSpacesAroundEquals` 标注为废弃；默认输出即带空格；如需紧凑，使用 `twfTightEquals`
- Builder 改为同键覆盖与数组同构：与 TOML 规范一致，减少不确定行为

## 迁移建议
- 渐进启用 `trfUseV2`：在测试/灰度环境对关键配置进行 v1/v2 双跑对比，按服务或配置目录分批切换
- 参考升级指南：docs/UPGRADE-fafafa.core.toml-v2.md（包含双跑策略、回退方案与最佳实践）

---


本说明记录了当前阶段对 yaml 解析相关模块（scanner/tokenizer/parser）的重构与用例补强，重点在于：
- 将解析器（parser）在非 flow 映射路径上切换为 tokenizer 驱动
- 保持对外事件序列与既有行为兼容（零语义变化）
- 补充覆盖关键边界场景的测试用例，确保迁移后的稳定性

## 变更摘要
- Parser：非 flow 映射路径全面切换为 tokenizer 驱动；保留 keyBOL 兼容逻辑；内部新增 expect_key 占位引导（不改变语义，仅用于未来状态切分）。
- Scanner：增强切分稳健性（引号标量、!! 长标签前缀、!<...> 尖括号标签、关键字/数字段等）。
- Tokenizer：对接 scanner 的切分；保持位置信息；辅助接口完善。
- 测试：新增多条 parser/tokenizer 用例，覆盖 flow/非 flow、混合分隔、注释、空值、行首键、嵌套、quoted key/value、额外分隔符等。

## 影响范围
- 受影响单元：
  - src/fafafa.core.yaml.impl.pas（解析器实现）
  - src/fafafa.core.yaml.scan.pas（扫描/切分）
  - tests/fafafa.core.yaml/*（测试用例）
- 对外 API：无变更（保持函数签名、事件类型与序列）

## 行为兼容性与不变点
- 事件序列：与迁移前一致（+STR,+DOC,[+MAP/+SEQ/SCALAR...],-DOC,-STR）。
- keyBOL（键在行首）兼容逻辑保留：对末尾空值的最后一对，按既有特例直接结束映射。
- expect_key：仅作为内部占位引导，逗号后 True、冒号后 False，不改变对外语义。

## 内部重构要点
- Parser 非 flow 映射路径：
  - 原 Parser_ScanNextPair 已下线；统一使用 Parser_Token_ScanNextPair_NonFlow。
  - 预取下一对时同步维护 scan_i 并计算 keyBOL（通过 key_ptr 前一字符是否换行）。
- Flow 路径：
  - 解析 pair 及序列 item 时统一由 tokenizer 提供 token 流；跳过多余分隔符（容忍策略）。
- Scanner：
  - 引号标量（双引号支持反斜杠转义、单引号 '' 视为转义）。
  - TAG 切分：支持 !! 长前缀与 !<angle-bracket> 形式（仅切分，不做语义）。
  - 关键字 true/false/null/~ 与简单数值段整体切分（仍以 SCALAR 形式交由上层处理）。

## 新增/更新的测试要点（节选）
- Tokenizer：
  - 多分隔符（逗号）：a,,b => SCALAR,COMMA,COMMA,SCALAR,EOF
  - 长标签前缀与尖括号：!!tag:val、!<ns:tag:more>、!!!weird:val
  - 引号标量、关键字与数字段、flow 符号与位置
- Parser：
  - 非 flow 多行混合分隔+注释、键在行首+空值收尾边界
  - Flow 混合嵌套：{a:[1,2], b:{c:3}}
  - Flow 映射 quoted key（"a,b"、'c:d'）
  - Flow 序列混合分隔+注释跨行：[a, b, # cmt \n c]
  - Flow 映射包含额外分隔符：{a:1,, b:2;; c:3}（容忍策略）
  - 非 flow value 为引号标量且含分隔符：k1: "a,b"; k2: 'c:d'

## 配置与兼容
- YAML_PCF_RESOLVE_DOCUMENT：用于启用文档级解析（映射/序列）。
- 未引入新的对外配置项。

## 已知限制与后续工作
- 编译器 warnings（case 未涵盖等）暂未收敛，待功能完全落地后统一处理。
- 目前对连续分隔符采用“容忍”策略（跳过多余逗号）。如需改为严格报错，可在 parser 流程中增加校验并更新用例预期。
- TAG/ANCHOR/ALIAS 的语义层处理暂未引入（仅 tokenizer/scanner 切分）；后续可按 libfyaml 规则渐进式对齐。

## 升级与回归
- 升级影响：对外 API/事件序列不变；无需修改调用代码。
- 建议在本地执行 YAML 套件回归：
  - Windows（Lazarus/FPC）
    - 进入 tests/fafafa.core.yaml/
    - 运行 buildOrTest.bat
  - 预期：所有用例通过（>50 项），无内存泄漏。

## 变更动机与收益
- 统一解析路径到 tokenizer 驱动，减少双实现分歧与维护成本。
- 通过增强切分与用例覆盖，提升边界场景的稳定性与可回归性。

## 附录：主要修改点（按文件）
- src/fafafa.core.yaml.impl.pas
  - 增加 expect_key 字段；在流/非流路径中维护（占位）
  - 阶段 2/4 切换至 Parser_Token_ScanNextPair_NonFlow；预取后更新 scan_i & keyBOL
  - 保留 flow 分支下基于 tokenizer 的 pair/item 解析
- src/fafafa.core.yaml.scan.pas
  - TAG 切分增强（!! 前缀、!<...> 形式）
  - 引号标量与数字/关键字切分增强
- tests/
  - tokenizer 与 parser 用例大幅补强，详见测试文件注释

---
如对“连续分隔符容忍”或其他边界行为有不同预期，请告知，我们可快速调整实现和用例预期以达成一致。
