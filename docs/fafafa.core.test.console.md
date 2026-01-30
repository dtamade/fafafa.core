# fafafa.core.test — Console Listener 使用与最佳实践

目标
- 面向人读的精简输出；默认启用；不依赖 CI/外部格式
- 体现最小可用：开始/成功/失败/跳过 与总览

快速上手
- 注册测试（函数式）：
  - Test('pkg/sub/name', procedure(ctx: ITestContext) begin ... end);
  - 使用 ctx.Run('child', ...) 组织层级子测试（名称以 "/" 连接）
- 运行（我方 Runner）：
  - TestMain 解析参数后执行；支持 --filter 子串过滤、--list 列出用例、--version
  - 示例（伪）：
    - tests.exe --filter=aes/gcm

事件与输出（示例）
- 开始：
  - == Running tests ==
- 成功：
  - [ OK ] pkg/sub/name (12 ms)
- 失败：
  - [FAIL] pkg/sub/name (23 ms): message
- 结束（在 ConsoleListener 内部统计）：
  - == Done: seen=..., failed=..., elapsed=...ms ==

最佳实践
- 用例命名：以 package/feature/case 组织；子测试用 ctx.Run 构造层级
- 断言：优先使用 AssertTrue/AssertEquals/Fail/Skip/Assume；失败消息尽量明确
- 清理：使用 AddCleanup/RunCleanupsNow，避免资源泄漏
- 可重复性：必要时使用 FixedClock/Deterministic 输入；减少对系统时间随机性的依赖
- 过滤：使用 --filter 控制运行集合，便于定位问题

与诊断日志（diag）的关系
- ConsoleListener 输出面向人；diag 为可选的详细二进制/十六进制流水（默认关闭）
- 不建议将 diag 作为核心输出；仅在排障期间临时开启

非目标
- 不输出 CI/外部格式；不强行生成文件
- 不绑定并发/分片等复杂调度（可在 Runner 层后续扩展）

故障排查
- 没有任何输出：确认 Runner 是否添加了 ConsoleListener；或被 --no-console 显式禁用
- 过滤后无用例：检查 --filter 子串是否匹配完整用例路径

附录：接口摘要（简）
- ITestContext：AssertTrue/Equals/Fail/Log/Run/AddCleanup/Clock
- ITestListener：OnStart/OnTestStart/OnTestSuccess/OnTestFailure/OnTestSkipped/OnEnd
- IClock：NowUTC/NowMonotonicMs（SystemClock/FixedClock）

