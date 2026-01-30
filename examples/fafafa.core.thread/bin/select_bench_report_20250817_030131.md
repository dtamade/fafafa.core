# Select Bench Report (20250817_030131)

Environment:
- OS: Microsoft Windows 11 专业版 10.0.26100
- Machine: TM1801 (12 cores, 31.8 GB RAM)
- CPU: Intel(R) Core(TM) i7-8750H CPU @ 2.20GHz

Input CSV(s):
- .\examples\fafafa.core.thread\bin\select_bench_tag_demo.csv

Meta param sets (iter,step,span,base[,tag]):
- 200, 7, 60, 20, tag=demo

## Global overview (by N)
| N | polling avg | std | nonpolling avg | std | delta ms | delta % |
|---:|------------:|----:|---------------:|----:|---------:|--------:|
| 2 | 42.895 | 3.224 | 36.075 | 0.552 | -6.82 | -15.9 |
| 8 | 39.642 | 1.892 | 36.568 | 0.364 | -3.074 | -7.75 |
| 32 | 32.492 | 0.004 | 30.918 | 1.637 | -1.574 | -4.84 |

## Overview by tag (all N)
| tag | polling avg | std | nonpolling avg | std | delta ms | delta % |
|:----|------------:|----:|---------------:|----:|---------:|--------:|
| demo | 38.343 | 5.045 | 34.52 | 2.908 | -3.823 | -9.97 |

## Results by parameter group

### iter=200 step=7 span=60 base=20 | tag=demo
| N | polling avg | p50 | p90 | p99 | std | nonpolling avg | p50 | p90 | p99 | std | delta ms | delta % |
|---:|------------:|----:|----:|----:|----:|---------------:|----:|----:|----:|----:|---------:|--------:|
| 2 | 42.895 | 42.895 | 44.719 | 45.129 | 3.224 | 36.075 | 36.075 | 36.387 | 36.457 | 0.552 | -6.82 | -15.9 |
| 8 | 39.642 | 39.642 | 40.712 | 40.953 | 1.892 | 36.568 | 36.568 | 36.774 | 36.82 | 0.364 | -3.074 | -7.75 |
| 32 | 32.492 | 32.492 | 32.495 | 32.495 | 0.004 | 30.918 | 30.918 | 31.844 | 32.052 | 1.637 | -1.574 | -4.84 |
