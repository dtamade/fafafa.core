# fafafa.core.test — Adapters（外部格式/工具适配层）

定位
- 适配器层对接外部 Runner/报告格式（如 JUnit/JSON/FPCUnit 桥接）
- 非核心；默认不加载；仅在需要对接外部系统时显式启用

核心与适配的边界
- 核心（kernel/runtime/assert/clock/listener.console）只关心：注册-调度-断言-上下文-事件
- Adapters 负责：
  - 将事件转为外部格式（JUnit/JSON）
  - 或将外部 Runner/注册系统桥接到我方事件流（如 FPCUnit → Notify*）

使用建议
- 项目内默认仅启用 ConsoleListener；不输出外部格式
- 如需与平台/工具对接，在 adapters 下添加对应监听器或桥接，运行时显式引用
- 示例：
  - JUnitListener（适配）：输出 <testsuite>/<testcase>，可在 <system-out> 中携带自定义字段（如 CaseId）
  - JsonListener（适配）：输出结构化 JSON 供工具消费

设计原则
- 插件式：监听器/桥接通过接口注入，不修改核心模块
- 稳定性：适配层不应更改核心事件语义，遵循 OnStart/OnTestStart/OnSuccess/OnFailure/OnSkipped/OnEnd
- 最小依赖：避免引入重量级依赖；必要时在适配层内自包含

迁移策略
- 现有 JUnit/JSON 监听器视为 adapters 角色；保持代码位置暂不迁移，先通过文档约定边界
- 后续如需目录迁移，建议新建 src/fafafa.core.test.adapters/ 并调整搜索路径，再逐步引用

常见问题
- 适配层在未启用时不应影响性能或行为
- 适配层如需大量 IO，应明确由开关控制并具备容错策略

