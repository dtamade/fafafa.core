# Select Bench Report (20250817_161628)

Environment:
- OS: Microsoft Windows 11 专业版 10.0.26100
- Machine: TM1801 (12 cores, 31.8 GB RAM)
- CPU: Intel(R) Core(TM) i7-8750H CPU @ 2.20GHz

Input CSV(s):
- .\bin\select_bench_matrix_demo_tag.csv

Meta param sets (iter,step,span,base[,tag]):
- 200, 7, 60, 20, tag=demo

## Global overview (by N)
| N | polling avg | std | nonpolling avg | std | delta ms | delta % |
|---:|------------:|----:|---------------:|----:|---------:|--------:|
| 2 | 31.482 | 0.88 | 31.25 | 0 | -0.232 | -0.74 |
| 8 | 43.245 | 1.414 | 41.105 | 0 | -2.14 | -4.95 |
| 32 | 32.878 | 0.293 | 33.1 | 0 | 0.222 | 0.68 |

## Overview by tag (all N)
| tag | polling avg | std | nonpolling avg | std | delta ms | delta % |
|:----|------------:|----:|---------------:|----:|---------:|--------:|
| demo | 35.868 | 5.797 | 35.152 | 5.238 | -0.716 | -2 |

## Results by parameter group

### iter=200 step=7 span=60 base=20 | tag=demo
| N | polling avg | p50 | p90 | p99 | std | nonpolling avg | p50 | p90 | p99 | std | delta ms | delta % |
|---:|------------:|----:|----:|----:|----:|---------------:|----:|----:|----:|----:|---------:|--------:|
| 2 | 31.482 | 31.482 | 31.98 | 32.093 | 0.88 | 31.25 | 31.25 | 31.25 | 31.25 | 0 | -0.232 | -0.74 |
| 8 | 43.245 | 43.245 | 44.045 | 44.225 | 1.414 | 41.105 | 41.105 | 41.105 | 41.105 | 0 | -2.14 | -4.95 |
| 32 | 32.878 | 32.878 | 33.044 | 33.081 | 0.293 | 33.1 | 33.1 | 33.1 | 33.1 | 0 | 0.222 | 0.68 |
