# Select Bench Report (20250817_002533)

Environment:
- OS: Microsoft Windows 11 专业版 10.0.26100
- Machine: TM1801 (12 cores, 31.8 GB RAM)
- CPU: Intel(R) Core(TM) i7-8750H CPU @ 2.20GHz

Input CSV(s):
- .\examples\fafafa.core.thread\bin\select_bench_compare_20250816_233322.csv

Meta param sets (iter,step,span,base):
- 200, 7, 60, 20

## Results by parameter group

### iter=200 step=7 span=60 base=20
| N | polling avg | p50 | p90 | p99 | std | nonpolling avg | p50 | p90 | p99 | std | delta ms | delta % |
|---:|------------:|----:|----:|----:|----:|---------------:|----:|----:|----:|----:|---------:|--------:|
| 2 | 33.27 | 30.935 | 38.155 | 42.439 | 5.394 | 31.401 | 31.015 | 32.491 | 33.332 | 1.143 | -1.869 | -5.62 |
| 8 | 39.957 | 40.445 | 41.074 | 41.223 | 1.756 | 38.735 | 39.285 | 40.646 | 40.839 | 2.033 | -1.222 | -3.06 |
| 32 | 32.29 | 32.18 | 32.918 | 33.172 | 0.608 | 33.077 | 33.295 | 33.8 | 34.079 | 0.788 | 0.787 | 2.44 |
