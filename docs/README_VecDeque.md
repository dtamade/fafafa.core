# FreePascal VecDeque - 现代化双端队列实现

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![FreePascal](https://img.shields.io/badge/FreePascal-3.2+-blue.svg)](https://www.freepascal.org/)
[![Tests](https://img.shields.io/badge/Tests-Passing-green.svg)](#测试验证)

一个高性能、类型安全的 FreePascal 双端队列（VecDeque）实现，基于 Rust 标准库设计，提供现代化的 API 和卓越的性能。

## 🌟 特性亮点

### ⚡ 高性能
- **O(1) 双端操作** - PushFront/Back, PopFront/Back
- **环形缓冲区** - 高效的内存利用
- **批量操作优化** - 针对大数据集优化
- **5种排序算法** - QuickSort, MergeSort, HeapSort, IntroSort, InsertionSort

### 🛡️ 类型安全
- **特化类型支持** - TIntegerVecDeque, TStringVecDeque
- **编译时类型检查** - 避免运行时类型错误
- **安全的比较机制** - 杜绝类型假设问题

### 🦀 Rust 风格 API
- **AsSlices** - 获取连续内存片段，零拷贝访问
- **MakeContiguous** - 内存重排优化
- **TryReserve** - 无异常的内存预留
- **Drain** - 范围删除并返回元素
- **SplitOff** - 高效的容器分割

### 🔧 现代化设计
- **统一错误处理** - 一致的异常机制
- **内存管理优化** - ShrinkTo, 智能增长策略
- ⚙️ 默认增长策略：采用“2 的幂”增长（TPowerOfTwoGrowStrategy），与环形缓冲的掩码/对齐友好，降低扩容次数
- ⚠️ UnChecked 方法契约：所有 UnChecked 版本不做任何参数/边界检查；array of T 入参需非空且范围由调用方保证（详见 docs/UnChecked_Methods_Summary.md）

- **并行操作支持** - 多核性能优化
- **全面测试覆盖** - 生产级质量保证

## 🚀 快速开始

### 安装

```bash
# 克隆仓库
git clone https://github.com/your-repo/fafafa-collections.git
cd fafafa-collections

# 编译库
fpc -Mobjfpc -O3 src/fafafa.core.collections.vecdeque.pas
```

### 基础使用

```pascal
program example;
uses
  fafafa.core.collections.vecdeque.specialized;

var
  LDeque: TIntegerVecDeque;
  i: Integer;
begin
  // 创建 VecDeque
  LDeque := TIntegerVecDeque.Create;
  try
    // 添加元素
    LDeque.PushBack(1);
    LDeque.PushBack(2);
    LDeque.PushFront(0);

    // 访问元素
    WriteLn('First: ', LDeque.Front);  // 0
    WriteLn('Last: ', LDeque.Back);    // 2

    // 排序
    LDeque.Sort;

    // 遍历
    for i := 0 to LDeque.GetCount - 1 do
      WriteLn(LDeque.Get(i));

    // 特化功能
    WriteLn('Sum: ', LDeque.Sum);
    WriteLn('Average: ', LDeque.Average:0:2);

  finally
    LDeque.Free;

### 增长策略示例

```pascal
uses
  fafafa.core.collections.vecdeque,
  fafafa.core.collections.base; // TGrowthStrategy, TAlignedWrapperStrategy, TPowerOfTwoGrowStrategy

var
  LDeque: specialize TVecDeque<Integer>;
  LAligned: TGrowthStrategy;
begin
  LDeque := specialize TVecDeque<Integer>.Create;
  try
    // 恢复默认策略（2 的幂增长）
    LDeque.SetGrowStrategy(nil);

    // 使用对齐包装策略：在 2 的幂增长的基础上，容量对齐到 64 字节
    LAligned := TAlignedWrapperStrategy.Create(TPowerOfTwoGrowStrategy.GetGlobal, 64);
    try
      LDeque.SetGrowStrategy(LAligned);
      // ... 进行批量 Push/Write 操作
    finally
      LAligned.Free; // 自定义策略生命周期由调用方负责
    end;
  finally
    LDeque.Free;
  end;
end.
```

## 📊 性能基准

| 操作 | 时间复杂度 | 实测性能 (元素/秒) |
|------|------------|-------------------|
| PushBack | O(1)* | > 10,000,000 |
| PushFront | O(1)* | > 10,000,000 |
| PopBack | O(1) | > 10,000,000 |
| PopFront | O(1) | > 10,000,000 |
| Get/Set | O(1) | > 50,000,000 |
| Sort | O(n log n) | 666,666 (MergeSort) |

*摊销时间复杂度

## 🏗️ 架构设计

### 核心组件

```
fafafa.core.collections.vecdeque
├── TVecDeque<T>              # 泛型双端队列
├── TIntegerVecDeque          # Integer 特化版本
├── TStringVecDeque           # String 特化版本
└── TParallelUtils            # 并行操作工具
```

### 内存布局

```
环形缓冲区布局:
[....HHHHHHHHTTTTT.....]  连续存储
[TTTTTT.......HHHHHHHH]  分割存储

H = Head (前端)
T = Tail (后端)
. = 空闲空间
```

## 📖 详细文档

- [API 参考手册](API_Reference.md) - 完整的 API 文档
- [使用指南](User_Guide.md) - 详细的使用教程
- [性能优化指南](Performance_Guide.md) - 性能调优建议
- [最佳实践](Best_Practices.md) - 生产使用建议
- [架构设计](Architecture.md) - 内部实现详解
- Best Practices（collections 策略组合与对齐）：docs/partials/collections.best_practices.md
- 最小示例一键脚本（Windows/Linux）：examples/fafafa.core.collections.vecdeque/BuildOrTest_Examples.(bat|sh)

## 🧪 测试验证

我们的实现经过了全面的测试验证：

```bash
# 运行所有测试
./tests/buildOrTest.bat

# 运行性能测试
./bin/simple_rust_test.exe

# 运行合规性测试
./bin/test_core_improvements.exe
```

### 测试覆盖

- ✅ **116个单元测试** - 全部通过
- ✅ **类型安全测试** - 验证类型安全机制
- ✅ **Rust 合规性测试** - 验证 Rust 风格功能
- ✅ **性能基准测试** - 验证性能表现
- ✅ **内存安全测试** - 验证内存管理
- ✅ **边界条件测试** - 验证边界处理

## 🤝 贡献指南

我们欢迎社区贡献！请参阅 [CONTRIBUTING.md](CONTRIBUTING.md) 了解详情。

### 开发环境

- FreePascal 3.2.0+
- Lazarus IDE (推荐)
- Git

### 提交流程

1. Fork 项目
2. 创建特性分支
3. 编写测试
4. 提交代码
5. 创建 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

## 🙏 致谢

- 感谢 Rust 标准库团队的优秀设计
- 感谢 FreePascal 社区的支持
- 感谢所有贡献者的努力

## 📞 联系我们

- 问题报告: [GitHub Issues](https://github.com/your-repo/issues)
- 讨论交流: [GitHub Discussions](https://github.com/your-repo/discussions)
- 邮件联系: your-email@example.com

---

**让 FreePascal 拥有现代化的数据结构！** 🚀
