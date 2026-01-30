# Collections 性能基准测试

本目录包含 fafafa.core.collections 模块的性能基准测试程序。

## 📊 已完成的基准测试

### benchmark_maps - Maps 性能对比

对比 `HashMap`、`TreeMap`、`LinkedHashMap` 的性能。

**运行**:
```bash
cd /home/dtamade/projects/fafafa.core/benchmarks/collections
./bin/benchmark_maps
```

**测试场景**:
- 插入 1K/10K/100K 元素
- 随机查找 10K 次
- 输出格式化的性能对比表格

**关键发现**（插入 100K 元素）:
- HashMap: 4ms（最快，纯哈希表）
- LinkedHashMap: 16ms（4x 慢，维护链表）
- TreeMap: 18ms（4.5x 慢，维护平衡树）

## 🔧 编译

使用 lazbuild:
```bash
lazbuild -B benchmark_maps.lpi
```

## 📁 文件结构

```
benchmarks/collections/
├── benchmark_maps.pas          # Maps 性能基准测试源码
├── benchmark_maps.lpi          # Lazarus 项目文件
├── benchmark_maps_results.txt  # 最新测试结果
├── bin/                        # 编译输出目录
├── lib/                        # 中间文件目录
├── charts/                     # 性能图表目录（待生成）
└── README.md                   # 本文档
```

## 🚀 待添加的基准测试

- `benchmark_sequences.pas` - Vec vs VecDeque vs List
- `benchmark_sets.pas` - BitSet vs HashSet<Integer>
- `benchmark_overall.pas` - 综合性能对比

## 📈 性能分析

详细的性能分析和图表将在 `docs/COLLECTIONS_PERFORMANCE_ANALYSIS.md` 中提供。

---

**更新时间**: 2025-10-28  
**状态**: ✅ Maps 基准测试完成

