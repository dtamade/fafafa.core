# AES-GCM 基准归档目录

结构约定：
- report/benchmarks/fafafa.core.crypto/gcm/
  - YYYY-MM-DD/
    - gcm_win64.csv
    - gcm_linux_x86_64.csv
    - gcm_macos_arm64.csv
  - merged.csv  （所有日期的汇总，含 Date/Host 列）

采集流程（Windows 示例）：
1) 运行 examples\fafafa.core.crypto\BuildOrRun_BenchCSV.bat 生成 examples\fafafa.core.crypto\bench_results\gcm_baseline.csv
2) 运行 scripts\archive_gcm_bench.bat 将 CSV 归档至当前日期目录（自动创建）
3) 可选：运行 scripts\merge_gcm_bench.bat 生成 merged.csv 用于长期对比

注意：
- merged.csv 在每次合并时会被覆盖重写
- CSV 列：tag_len,pt_len,iters,bytes,ms,mb_per_s,Date,Host
- Date 从目录名推断，Host 从文件名推断

