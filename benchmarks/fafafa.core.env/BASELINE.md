# fafafa.core.env 性能基线

**日期**: 2025-12-13
**平台**: Linux x86_64
**编译器**: FPC 3.3.1 -O3 优化
**环境变量数量**: 84

---

## 基础操作

| 操作 | Iterations | Time (ms) | Rate (ops/sec) |
|------|------------|-----------|----------------|
| env_get | 50,000 | 3.07 | 16,286,645 |
| env_lookup | 50,000 | 5.20 | 9,619,084 |
| env_has | 100,000 | 9.55 | 10,467,915 |
| env_iter | 1,000 | 20.27 | 49,324 iter/sec |

## 字符串展开 (env_expand)

| 场景 | Iterations | Time (ms) | Rate (ops/sec) | 备注 |
|------|------------|-----------|----------------|------|
| Simple $VAR | 10,000 | 12.13 | 824,334 | 2 变量 |
| Braced ${VAR} | 10,000 | 15.26 | 655,523 | 2 变量 |
| Mixed syntax | 10,000 | 17.69 | 565,419 | 混合 + PATH |
| No variables | 50,000 | 78.10 | 640,188 | 纯字符串 |
| Long string | 5,000 | 77.19 | 64,773 | 411 chars, 40 vars |

## PATH 处理

| 操作 | Segments | Iterations | Time (ms) | Rate (ops/sec) |
|------|----------|------------|-----------|----------------|
| env_split_paths | 6 | 10,000 | 7.05 | 1,418,641 |
| env_split_paths | 50 | 5,000 | 21.02 | 237,857 |
| env_join_paths | 6 | 10,000 | 10.44 | 957,671 |
| env_join_paths | 50 | 2,000 | 14.64 | 136,659 |

---

## 分析

### 性能亮点
- **基础操作极快**: env_get 达到 1600万+ ops/sec
- **PATH 处理高效**: split/join 百万级 ops/sec

### 潜在优化点
- **env_expand (passthrough)**: 无变量时仍有开销，可考虑快速路径
- **env_expand (long string)**: 多变量场景性能下降明显，考虑批量查找优化
- **env_iter**: 受限于 TStringList 分配，考虑零分配迭代器

---

## 运行方式

```bash
cd benchmarks/fafafa.core.env
lazbuild --build-mode=Release env_benchmark.lpi
./bin/env_benchmark
```
