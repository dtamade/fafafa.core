# Default Strategy Performance Report
ECHO 处于关闭状态。
Generated: 2025/08/15 周五 13:31:36.97
ECHO 处于关闭状态。
## Inputs
- Matrix script: examples/fafafa.core.lockfree/bench_matrix_default_modes.bat
- CSV stats tool: tools/csv_stats.exe
- Output CSV:
^- bin/bench_default_linear.csv
^- bin/bench_default_double.csv
- Output stats:
^- bin/stats_default_linear.csv
^- bin/stats_default_double.csv
ECHO 处于关闭状态。
## How to read
- Group by: mode,nkeys,capmul100,maxload1000,probe,dist,unique
- Compare matching groups across the two stats files; look at avg/median/p95/count
- For rand, multi-seed is enabled (default: 42/123/2025), so count=3
ECHO 处于关闭状态。
## Stats: Default Linear
ECHO 处于关闭状态。
```csv
group_key,avg_ms,median_ms,p95_ms,count
oa	20000	80	600	default	seq	0,41.667,39.500,70.250,6
oa	20000	80	600	default	rand	0,33.000,31.000,47.000,18
oa	20000	80	600	default	repeat	1000,38.500,38.500,45.250,2
oa	20000	100	600	default	seq	0,36.333,31.000,47.000,6
oa	20000	100	600	default	rand	0,39.944,39.500,49.250,18
oa	20000	100	600	default	repeat	1000,31.500,31.500,45.450,2
oa	20000	120	600	default	seq	0,36.333,31.000,59.000,6
oa	20000	120	600	default	rand	0,34.778,31.000,49.400,18
oa	20000	120	600	default	repeat	1000,31.000,31.000,31.000,2
oa	20000	150	600	default	seq	0,36.500,31.500,47.000,6
oa	20000	150	600	default	rand	0,36.389,31.500,47.000,18
oa	20000	150	600	default	repeat	1000,31.000,31.000,31.000,2
oa	20000	200	600	default	seq	0,46.667,38.500,105.500,6
oa	20000	200	600	default	rand	0,44.444,47.000,65.250,18
oa	20000	200	600	default	repeat	1000,31.500,31.500,31.950,2
oa	20000	300	600	default	seq	0,46.833,47.000,58.250,6
oa	20000	300	600	default	rand	0,40.667,39.000,62.150,18
oa	20000	300	600	default	repeat	1000,31.500,31.500,45.450,2
oa	20000	80	600	default	repeat	5000,39.500,39.500,46.250,2
oa	20000	100	600	default	repeat	5000,39.000,39.000,46.200,2
oa	20000	120	600	default	repeat	5000,31.500,31.500,31.950,2
oa	20000	150	600	default	repeat	5000,31.000,31.000,31.000,2
oa	20000	200	600	default	repeat	5000,39.000,39.000,46.200,2
oa	20000	300	600	default	repeat	5000,78.500,78.500,106.850,2
oa	20000	80	600	default	repeat	10000,31.000,31.000,31.000,2
oa	20000	100	600	default	repeat	10000,47.000,47.000,47.000,2
oa	20000	120	600	default	repeat	10000,46.500,46.500,60.450,2
oa	20000	150	600	default	repeat	10000,39.500,39.500,46.250,2
oa	20000	200	600	default	repeat	10000,54.500,54.500,61.250,2
oa	20000	300	600	default	repeat	10000,31.000,31.000,31.000,2
```
ECHO 处于关闭状态。
## Stats: Default Double
ECHO 处于关闭状态。
```csv
group_key,avg_ms,median_ms,p95_ms,count
oa	20000	80	600	default	seq	0,44.167,47.000,47.000,6
oa	20000	80	600	default	rand	0,39.056,39.500,47.000,18
oa	20000	80	600	default	repeat	1000,47.000,47.000,61.400,2
oa	20000	100	600	default	seq	0,38.833,38.500,47.000,6
oa	20000	100	600	default	rand	0,39.944,32.000,62.150,18
oa	20000	100	600	default	repeat	1000,31.000,31.000,31.000,2
oa	20000	120	600	default	seq	0,34.000,31.500,43.250,6
oa	20000	120	600	default	rand	0,34.722,31.000,47.000,18
oa	20000	120	600	default	repeat	1000,32.000,32.000,32.000,2
oa	20000	150	600	default	seq	0,65.333,39.500,141.250,6
oa	20000	150	600	default	rand	0,39.111,32.000,49.400,18
oa	20000	150	600	default	repeat	1000,31.000,31.000,31.000,2
oa	20000	200	600	default	seq	0,31.167,31.000,43.000,6
oa	20000	200	600	default	rand	0,33.833,31.000,47.000,18
oa	20000	200	600	default	repeat	1000,23.000,23.000,30.200,2
oa	20000	300	600	default	seq	0,44.333,31.500,74.250,6
oa	20000	300	600	default	rand	0,44.333,47.000,65.250,18
oa	20000	300	600	default	repeat	1000,55.000,55.000,62.200,2
oa	20000	80	600	default	repeat	5000,39.000,39.000,46.200,2
oa	20000	100	600	default	repeat	5000,39.000,39.000,46.200,2
oa	20000	120	600	default	repeat	5000,47.000,47.000,74.900,2
oa	20000	150	600	default	repeat	5000,39.000,39.000,46.200,2
oa	20000	200	600	default	repeat	5000,31.000,31.000,31.000,2
oa	20000	300	600	default	repeat	5000,54.500,54.500,61.250,2
oa	20000	80	600	default	repeat	10000,39.000,39.000,46.200,2
oa	20000	100	600	default	repeat	10000,39.000,39.000,46.200,2
oa	20000	120	600	default	repeat	10000,39.000,39.000,46.200,2
oa	20000	150	600	default	repeat	10000,39.000,39.000,46.200,2
oa	20000	200	600	default	repeat	10000,47.000,47.000,47.000,2
oa	20000	300	600	default	repeat	10000,31.000,31.000,31.000,2
```
ECHO 处于关闭状态。
---
For more details, see docs/README_LOCKFREE.md (Benchmark and Strategy sections).
