# Benchmarks 索引（快速入口）

已规范化的微基准入口：

- Bytes / ByteBuf
  - 路径：benchmarks/fafafa.core.bytes/fafafa.core.bytes.bench.lpr
  - 说明：比较 BytesConcat vs TBytesBuilder.Append；ByteBuf EnsureWritable 增长；Read/Compact
- JSON 读写
  - 路径：benchmarks/fafafa.core.json/fafafa.core.json.perf_rw.lpr
  - 说明：Reader/Writer 性能；ForEach 与 Pointer+TryGet 的差异；对象键遍历（String vs Raw）
- Collections — OrderedMap
  - 路径：benchmarks/fafafa.core.collections/orderedmap_perf.lpr
  - 说明：TryAdd 与 InsertOrAssign 的命中/更新路径对比

通用规则
- 不纳入 CI，仅用于本地快速对比
- 每个 .lpr 文件内部均设置 `{$UNITPATH ../../src}`，可直接用 lazbuild 或 fpc 构建
- 建议输出简洁、稳定，避免运行时间过长（秒级以内为宜）

