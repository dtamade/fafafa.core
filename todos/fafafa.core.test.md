# 开发计划日志 - fafafa.core.test
- [done] IClock + TTickClock 适配与测试
- [next] docs 增补 IClock/TTickClock 示例（已提交初版）


## 今日目标
- 自举 v0 能力：runner/utils/snapshot/listeners + 自测工程
- 完成 JSON/JUnit 输出与 CLI 参数基本流程

## 进展记录
- [done] ITestContext（断言/子测试/表驱动/TempDir）
- [done] runner（过滤/输出开关/列表）
- [done] listener.console/junit/json（fpjson 实现）
- [done] 测试工程 + 脚本；4/4 用例通过
- [done] JSON 报告（V2）结构化 cleanup 文档与示例（docs/fafafa.core.test.md 已补充）


- [ ] 修复脚本：确保 tests/BuildOrTest.bat 在 lazbuild 失败时不打印成功提示（已完成，需要在其他 test 项目模板同步）
- [ ] args 文档对齐：在 docs/fafafa.core.args.md 补充“键名归一化与 no- 前缀”细节与示例（已完成）
- [ ] diagnostics 文档对齐：在 docs/fafafa.core.args.command.md 补充 GetBestMatchPath 诊断说明（已完成）
- [ ] 添加更多边界用例：
  - [ ] `--no-k=v` 与 `--k=v` 混合顺序覆盖性
  - [ ] `-no-k` 与 `/no-k` 在 StopAtDoubleDash=False 下的行为
  - [ ] 大小写混合与别名组合的长路径匹配

## 待办（短期）
- [ ] docs.md 补充 CLI/JSON/JUnit 结构说明与示例
- [ ] ctx.AssertRaises/Skip，ctx.Cleanup（资源释放挂钩）
- [ ] IClock（Fixed/Monotonic），确定性 RNG（seed）
- [ ] --junit 兼容性验证（GitLab/Jenkins），字段对齐
- [ ] 快照：JSON/TOML 归一化、TEST_SNAPSHOT_UPDATE 支持
- [done] 快照：A1 逐行上下文 diff（TEST_SNAPSHOT_DIFF_CONTEXT）
- [done] 快照：A2 TOML 语义规范化（Parse + ToToml[twfPretty,twfSortKeys]）
- [next] 文档：在 docs 增补 Diff 示例与环境变量说明、TOML 规范化说明
- [next] A3：ctx.Cleanup 增强（资源释放链、失败时依然执行、异常聚合）
- [next] A3 Cleanup 展示优化：
  - Console：清理条目编号/对齐；
  - JSON：为 cleanup item 增补时间戳字段（可选），并保留向后兼容；
  - JUnit：system-err 中按统一模板输出；

- [done] A3 Cleanup：成功/失败/跳过三类清理异常策略与基础用例
- [next] A3 Cleanup：异常聚合格式化（编号、时间）、Listener 侧展示优化



## 风险/依赖
- fcl-json 依赖路径：需保证 Lazarus 安装路径变量 $(LazarusDir) 可用
- Windows/Linux 行为差异：路径/换行/权限

## 备注
- 若后续推广到各模块，建议提供 test 项目模板脚本生成器（tools/test_template.*）

