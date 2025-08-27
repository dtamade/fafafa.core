# CHANGELOG: fafafa.core.benchmark

## 2025-08-17
- Reporter: CSV 支持 counters=tabular，将所有结果中的计数器名称展开为列
- Reporter: Console 输出追加 Counters 块，用于调试
- IBenchmarkState 增加只读访问器（GetBytesProcessed/GetItemsProcessed/GetComplexityN/GetCounters）
- TBenchmarkResultV2 从 State 拷贝上述字段与 counters，贯通了 counters 管道
- 测试：
  - 新增 Reporter-CSV counters=tabular 与 Reporter-JSON 宽松快照测试（RUN_EXTRA_REPORTER_TESTS 环境变量开启）
  - 边界：开销校正极小耗时/小样本用例
- 文档：新增 docs/fafafa.core.benchmark.md Quickstart；README 链接入口

