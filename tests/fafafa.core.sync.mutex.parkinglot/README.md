# fafafa.core.sync.mutex.parkinglot 测试套件

这是 `fafafa.core.sync.mutex.parkinglot` 模块的完整测试套件，提供全面的单元测试、集成测试和性能基准测试。

## 📋 测试概览

### 测试类别

| 测试类 | 描述 | 测试数量 |
|--------|------|----------|
| `TTestCase_Global` | 全局工厂函数测试 | 1 |
| `TTestCase_IParkingLotMutex` | 基本接口功能测试 | 12 |
| `TTestCase_Concurrency` | 并发和压力测试 | 9 |
| `TTestCase_Performance` | 性能基准测试 | 8 |
| `TTestCase_EdgeCases` | 边界条件和异常测试 | 8 |
| `TTestCase_Platform` | 平台特定功能测试 | 6 |

### 测试覆盖范围

#### ✅ 基本功能测试
- [x] 工厂函数创建
- [x] 基本获取/释放操作
- [x] TryAcquire 成功/失败场景
- [x] 超时获取功能
- [x] RAII 锁守护
- [x] 句柄获取

#### ✅ Parking Lot 特有功能
- [x] 公平释放 (ReleaseFair)
- [x] 快速路径优化
- [x] 智能自旋行为
- [x] 公平性 vs 性能权衡

#### ✅ 并发正确性测试
- [x] 多线程互斥保证
- [x] 高竞争场景处理
- [x] 短/长临界区性能
- [x] FIFO 公平性验证
- [x] 超时机制验证

#### ✅ 性能基准测试
- [x] 无竞争性能测试
- [x] 不同竞争级别性能
- [x] 与标准锁的比较
- [x] 快速路径效率验证

#### ✅ 边界条件测试
- [x] 极值超时处理
- [x] 异常释放场景
- [x] 资源泄漏检测
- [x] 销毁时机处理

#### ✅ 平台集成测试
- [x] Windows/Unix 平台适配
- [x] 系统级等待/唤醒机制
- [x] 原子操作正确性
- [x] 系统集成稳定性

## 🚀 快速开始

### 构建和运行测试

#### Windows
```cmd
# 运行所有测试
buildOrTest.bat

# 仅构建
buildOrTest.bat build

# 清理构建产物
buildOrTest.bat clean
```

#### Linux/macOS
```bash
# 运行所有测试
./buildOrTest.sh

# 仅构建
./buildOrTest.sh build

# 清理构建产物
./buildOrTest.sh clean
```

### 运行特定测试类

```cmd
# 运行基本功能测试
bin\fafafa.core.sync.mutex.parkinglot.test.exe --suite=TTestCase_IParkingLotMutex

# 运行并发测试
bin\fafafa.core.sync.mutex.parkinglot.test.exe --suite=TTestCase_Concurrency

# 运行性能测试
bin\fafafa.core.sync.mutex.parkinglot.test.exe --suite=TTestCase_Performance
```

### 生成测试报告

```cmd
# 生成 JUnit XML 报告
bin\fafafa.core.sync.mutex.parkinglot.test.exe --format=junit --file=results.xml

# 生成纯文本报告
bin\fafafa.core.sync.mutex.parkinglot.test.exe --format=plain --file=results.txt
```

## 📊 性能基准

### 典型性能指标

| 场景 | 操作/秒 | 延迟 (μs) | 备注 |
|------|---------|-----------|------|
| 无竞争获取/释放 | ~10M | <0.1 | 快速路径优化 |
| 低竞争 (2线程) | ~5M | <0.2 | 智能自旋生效 |
| 中等竞争 (4线程) | ~2M | <0.5 | 混合策略 |
| 高竞争 (8+线程) | ~500K | <2.0 | 系统等待机制 |

### 与其他锁类型的比较

| 锁类型 | 无竞争性能 | 低竞争性能 | 高竞争性能 | 公平性 |
|--------|------------|------------|------------|--------|
| Parking Lot Mutex | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| 标准 Mutex | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| 自旋锁 | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐ | ⭐ |
| 临界区 | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐ |

## 🔧 测试配置

### 编译选项
- **Debug 模式**: 启用所有检查和调试信息
- **Release 模式**: 优化性能，用于基准测试
- **内存检查**: 使用 HeapTrc 检测内存泄漏

### 测试参数
```pascal
const
  SMALL_ITERATION_COUNT = 1000;     // 小规模测试
  MEDIUM_ITERATION_COUNT = 10000;   // 中等规模测试
  LARGE_ITERATION_COUNT = 100000;   // 大规模测试
  
  SHORT_TIMEOUT_MS = 10;            // 短超时
  MEDIUM_TIMEOUT_MS = 100;          // 中等超时
  LONG_TIMEOUT_MS = 1000;           // 长超时
```

## 🐛 故障排除

### 常见问题

1. **编译错误**: 确保 `fafafa.core.atomic` 模块已正确编译
2. **测试超时**: 在高负载系统上增加超时值
3. **性能异常**: 检查系统负载和其他进程干扰
4. **平台差异**: 某些测试在不同平台上可能有不同的行为

### 调试技巧

```cmd
# 启用详细输出
bin\fafafa.core.sync.mutex.parkinglot.test.exe --verbose

# 运行单个测试方法
bin\fafafa.core.sync.mutex.parkinglot.test.exe --suite=TTestCase_IParkingLotMutex.Test_Acquire_Release

# 生成性能分析报告
bin\fafafa.core.sync.mutex.parkinglot.test.exe --suite=TTestCase_Performance --verbose
```

## 📈 持续集成

这个测试套件设计为可以在 CI/CD 环境中自动运行：

```yaml
# GitHub Actions 示例
- name: Run Parking Lot Mutex Tests
  run: |
    cd tests/fafafa.core.sync.mutex.parkinglot
    ./buildOrTest.sh
```

## 🤝 贡献指南

添加新测试时请遵循以下规范：

1. **命名约定**: `Test_功能_场景`
2. **文档注释**: 每个测试方法都应有清晰的注释
3. **断言消息**: 提供有意义的失败消息
4. **资源清理**: 确保测试后正确清理资源
5. **平台兼容**: 考虑跨平台兼容性

## 📄 许可证

本测试套件遵循与 fafafa.core 项目相同的许可证。
