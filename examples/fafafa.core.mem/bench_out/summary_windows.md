# Windows Baseline Summary

Source: results_windows.csv (high-precision via fafafa.core.tick)

## Highlights (avg over runs)
- MemPool Alloc/Free (64B): ~76.8 ops/ms (avg_ms=2603, runs=5)
- StackPool default Alloc (32B): ~50,000 ops/ms (avg_ms=4, runs=5)
- StackPool AllocAligned(32): ~50,000 ops/ms (avg_ms=4, runs=5)
- SlabPool 64+128 pair (96B logical/op): ~1,299 ops/ms (avg_ms=231, runs=5)

StackPool 默认对齐与显式对齐在本机数据上相当；若在其他 CPU/内存子系统上有差异，可通过 --iters/--runs 放大量测，或切换 Release 进一步观察差距。

## Raw
```
case,variant,iterations,bytes_per_op,runs,avg_ms,min_ms,max_ms,ops_per_ms_avg
MemPool,Alloc/Free,200000,64,5,2603,2066,3228,76.834
StackPool,Alloc(default),200000,32,5,4,4,7,50000.000
StackPool,AllocAligned(32),200000,32,5,4,3,7,50000.000
SlabPool,Alloc/Free 64+128,300000,96,5,231,188,277,1298.701
```

## Notes
- 计时使用 ITick（优先高精度 QueryPerformanceCounter）；多轮统计 avg/min/max，提升稳定性。
- 参数：默认 --iters=200000（Slab=150000 等效），--runs=5；可通过命令行覆盖。
- 环境：Windows/x64/Debug；如需对比 Release 或 CRT/INLINE 开关，后续可以自动化矩阵运行输出。

