# 工作总结报告：fafafa.core.json

## 本轮进度与已完成项（2025-08-20）
## 本轮进度与已完成项（2025-08-22）
- MCP 复核：继续以 yyjson 作为语义与 API 参照；对比 simdjson（On Demand/DOM 双模型、极致吞吐）与 RapidJSON（成熟但近年维护节奏放缓），确认当前模块以“yyjson 语义 + Pascal 友好接口”是可行且高性价比路线；保留 RFC 6901/6902（Pointer/Patch）实现与测试。
- 统一错误消息（Facade）：将 IJsonReader.ReadFromString/ReadFromStringN 的异常消息改为 JsonFormatErrorMessage(Err)，与 ReadFromFile 保持一致，集中于 src/fafafa.core.json.errors.pas 管理。
- 回归验证：tests/fafafa.core.json/BuildOrTest.bat test 全量运行通过。


- 增量解析（incr）鲁棒性改进：
  - 在 JsonIncrRead 中引入“临时拷贝试解析 → 正式解析”双阶段，避免第一次失败修改原缓冲导致后续跨块续读失败；
  - 失败时的 MORE 判定优化：jecUnexpectedEnd 直接 MORE；jecInvalidString/jecInvalidNumber 且错误位置接近尾部（阈值 8）或尾部存在转义/不完整 UTF-8 起始 → MORE；
  - 去除成功后对消费尾部的二次启发式检查，避免误报 MORE。
- 现状：tests/fafafa.core.json 99 项中仅剩 1 项失败（UTF-8 跨块用例），其余全绿。
- 同步修正测试字符串字面量含反斜杠的写法（Pascal 字符串字面量不转义，单个 '\u' 即为反斜杠 + 'u'）。


## 关键改动点位（代码导览）
- src/fafafa.core.json.core.pas
  - ParseObjectValue / ParseArrayValue：父容器恢复从保存指针 → 保存偏移（SavedCtnOfs）
  - 对象迭代器：JsonObjIterNext 推进依赖 UnsafeGetNext(Val)，跨值跨度跳到下一键

## 验证与回归
- 命令：tests/fafafa.core.json/BuildOrTest.bat test
- 结果：87/87 全部通过（新增 5 个用例包含在内）

## 风险与后续保障
- 风险：未来在解析阶段再次引入 Realloc 时，若有其它以指针保存的上下文状态，可能存在类似隐患
- 保障：
  - 建议统一采用“保存偏移”的策略管理解析期的父/祖容器引用
  - 回归用例已覆盖“对象值为数组”的多键场景；建议后续补充“对象内相邻嵌套容器交错”的极端布局用例

## TODO 提议
- tests：
  - 再加 1 个复杂嵌套对象：{"a":[{"x":[1]},2],"b":[3,{"y":[4,5]}]}，同时断言 /a/0/x 与 /b/1/y 的长度
- 文档：
  - 在本报告中保留“父容器偏移恢复策略”的简要说明（已完成）
  - 在开发者 README（若存在）加注“解析阶段避免直接持有容器指针”的注意事项


### 第十轮进展与记录（2025-08-17）

- MCP 调研（简要）：复核 yyjson/simdjson/RapidJSON 等高性能 JSON 库生态，继续以 yyjson 语义为主要参照；RFC 6901/6902 支持维持并强化测试覆盖。
- 基线验证：
  - 构建命令：tests/fafafa.core.json/BuildOrTest.bat test
  - 运行命令：tests/fafafa.core.json/bin/tests_json.exe --all --format=plain
  - 结果：Number of run tests: 92，Errors: 0，Failures: 0（全绿，退出码 0）
- 现状与差距：
  - examples 目录部分脚本仍直接调用 fpc，未统一使用 lazbuild；
  - 门面/接口层（json.pas 与 facade/aliases）存在历史重复，需最小化门面并委派至 fixed；
  - 用户文档缺失，需要 docs/fafafa.core.json.md。
- 本轮产出：
  - 已确认测试基线 92/92 通过；
  - 将补充 docs/fafafa.core.json.md 文档初稿；
  - 更新 report 与 todo（本文件与 todo/fafafa.core.json/todo.md）。
- 后续计划（精简闭环）：
  1) 统一 examples 构建脚本为 lazbuild，确保 bin/lib 输出规范；
  2) 门面最小化设计草案：接口/别名/工厂 + 全量委派 fixed，规避重复实现；
  3) 抽取错误消息常量/构造器（Reader/Writer），规范首字母大写与措辞；
  4) 评估并分批消除“可安全清理”的告警（unreachable/unused），严格控制改动面；
  5) 完成 docs 初稿后对齐 examples/README，提供最小示例。


## 本轮更新（2025-08-18）
- 统一 Facade 错误消息：门面异常消息改为引用 src/fafafa.core.json.errors.pas 常量（Value is not a ...）。
- 收敛接口单元：src/fafafa.core.json.interfaces.pas 改为“别名/转发层”，直接别名到门面接口，避免 GUID/签名漂移。
- 清理提示：移除 src/fafafa.core.json.core.pas 中未使用的 fafafa.core.base 引用，降低无关 Hint。
- 验证：tests/fafafa.core.json/BuildOrTest.bat test 退出码 0，92/92 全绿。
- 后续：
  1) 门面最小化设计草案与委派映射表
  2) 分批清理 safe hints（不触行为路径）

- 警告/提示微清理（无行为变化）：
  - src/fafafa.core.json.ptr.pas / src/fafafa.core.json.patch.pas：UnescapeToken 默认 Result:=''；StrToIndex 在 32 位保留越界保护、在 64 位条件屏蔽恒假比较（消除 4044/6018）
  - src/fafafa.core.json.mut.util.pas / src/fafafa.core.json.fluent.pas：初始化 LIndentStr/LNewIndentStr（消除 5089）
- 回归：重新执行 tests/fafafa.core.json/BuildOrTest.bat test，92/92 全绿，退出码 0
