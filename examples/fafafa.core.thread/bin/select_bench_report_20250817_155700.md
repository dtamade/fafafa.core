# Select Bench Report (20250817_155700)

Environment:
- OS: Microsoft Windows 11 专业版 10.0.26100
- Machine: TM1801 (12 cores, 31.8 GB RAM)
- CPU: Intel(R) Core(TM) i7-8750H CPU @ 2.20GHz

Input CSV(s):
- .\bin\quick_demo.csv

Meta param sets (iter,step,span,base[,tag]):
- 200, 7, 60, 20, tag=quick

## Global overview (by N)
| N | polling avg | std | nonpolling avg | std | delta ms | delta % |
|---:|------------:|----:|---------------:|----:|---------:|--------:|
| 2 | 30.785 | 0 | 30.94 | 0 | 0.155 | 0.5 |
| 8 | 36.95 | 0 | 36.505 | 0 | -0.445 | -1.2 |
| 32 | 32.555 | 0 | 34.155 | 0 | 1.6 | 4.91 |

## Overview by tag (all N)
| tag | polling avg | std | nonpolling avg | std | delta ms | delta % |
|:----|------------:|----:|---------------:|----:|---------:|--------:|
| quick | 33.43 | 3.174 | 33.867 | 2.794 | 0.437 | 1.31 |

## Results by parameter group

### iter=200 step=7 span=60 base=20 | tag=quick
| N | polling avg | p50 | p90 | p99 | std | nonpolling avg | p50 | p90 | p99 | std | delta ms | delta % |
|---:|------------:|----:|----:|----:|----:|---------------:|----:|----:|----:|----:|---------:|--------:|
| 2 | 30.785 | 30.785 | 30.785 | 30.785 | 0 | 30.94 | 30.94 | 30.94 | 30.94 | 0 | 0.155 | 0.5 |
| 8 | 36.95 | 36.95 | 36.95 | 36.95 | 0 | 36.505 | 36.505 | 36.505 | 36.505 | 0 | -0.445 | -1.2 |
| 32 | 32.555 | 32.555 | 32.555 | 32.555 | 0 | 34.155 | 34.155 | 34.155 | 34.155 | 0 | 1.6 | 4.91 |
