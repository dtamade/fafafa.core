# fafafa.core.env 性能基线

**最后更新**: 2025-12-15
**平台**: Linux x86_64
**编译器**: FPC 3.3.1 -O3 优化
**环境变量数量**: 84

---

## 基础操作

| 操作 | Iterations | Time (ms) | Rate (ops/sec) |
|------|------------|-----------|----------------|
| env_get | 50,000 | 3.26 | 15,342,129 |
| env_lookup | 50,000 | 5.10 | 9,805,844 |
| env_has | 100,000 | 9.63 | 10,382,060 |
| env_iter | 1,000 | 15.18 | 65,898 iter/sec |

## 字符串展开 (env_expand) - 已优化 ✅

| 场景 | Rate (ops/sec) | vs v1.0 | 备注 |
|------|----------------|---------|------|
| Simple $VAR | 1,694,054 | **+105%** | 2 变量 |
| Braced ${VAR} | 1,602,051 | **+144%** | 2 变量 |
| Mixed syntax | 744,546 | **+32%** | 混合 + PATH |
| **No variables** | **10,836,585** | **+1593%** | 快速路径优化 ⚡ |
| Long string | 120,712 | **+86%** | 411 chars, 40 vars |

## PATH 处理 - 已优化 ✅

| 操作 | Segments | Rate (ops/sec) | vs v1.0 |
|------|----------|----------------|--------|
| env_split_paths | 6 | 2,586,653 | **+82%** |
| env_split_paths | 50 | 392,773 | **+65%** |
| env_join_paths | 6 | 1,854,599 | **+94%** |
| env_join_paths | 50 | 267,666 | **+96%** |

---

## 优化历史

### v1.1 优化 (2025-12-14)
- **快速路径**: 无变量标记时直接返回原字符串，避免 StringBuilder 分配
- **批量追加**: 普通字符批量追加，减少 Append 调用次数
- **性能提升**: passthrough 场景提升 **16.9x**

### v1.2 优化 (2025-12-15)
- **env_iter (Unix)**: 直接迭代 libc environ，避免每次创建 TStringList（约 +29% iter/sec）

### 待优化
- **env_iter (Windows)**: 仍可考虑更轻量的迭代方式（避免预构建 TStringList）

---

## 运行方式

```bash
cd benchmarks/fafafa.core.env
lazbuild --build-mode=Release env_benchmark.lpi
./bin/env_benchmark
```
