# fafafa.core.args Performance Benchmarks

## 概述

这个目录包含 fafafa.core.args 模块的性能基准测试，用于测量和分析参数解析的性能表现。

## 基准测试项目

### 1. 核心解析性能 (`args_parsing_benchmark.lpr`)
- 基本参数解析性能
- 不同参数数量的扩展性测试
- 各种参数格式的解析速度对比

### 2. 配置选项影响 (`args_options_benchmark.lpr`)
- 不同 TArgsOptions 配置对性能的影响
- 大小写敏感 vs 不敏感
- 短标志组合 vs 单独解析

### 3. 内存使用分析 (`args_memory_benchmark.lpr`)
- 内存分配模式分析
- 大量参数时的内存使用情况
- 内存泄漏检测

### 4. 子命令性能 (`args_command_benchmark.lpr`)
- 子命令路由性能
- 深层嵌套命令的性能影响
- 命令别名解析性能

### 5. 配置合并性能 (`args_config_merge_benchmark.lpr`)
- CONFIG→ENV→CLI 合并性能
- 不同配置源的解析速度
- 大型配置文件的处理性能

## 运行方式

```bash
# 编译所有基准测试
lazbuild --build-mode=Release *.lpr

# 运行单个基准测试
./args_parsing_benchmark

# 运行所有基准测试
./run_all_benchmarks.sh
```

## 性能目标

基于主流参数解析库的性能表现，我们的目标：

- **简单解析**: > 100,000 args/sec
- **复杂解析**: > 10,000 args/sec  
- **内存效率**: < 1KB per 100 args
- **子命令路由**: < 1μs per lookup

## 基准测试结果

运行基准测试后，结果将保存在 `results/` 目录中，包括：
- 性能数据 CSV 文件
- 内存使用报告
- 性能回归检测报告
