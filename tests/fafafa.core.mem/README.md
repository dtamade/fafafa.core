# fafafa.core.mem 单元测试项目

## 项目概述

这是 `fafafa.core.mem` 模块的完整 FPCUnit 单元测试项目，使用 lazbuild 构建，启用内存泄漏检测。

## 项目结构

```
tests/fafafa.core.mem/
├── tests_mem.lpi                    # Lazarus 项目文件（仅 fpcunit 单元）
├── tests_mem.lpr                    # 主程序文件
├── Test_fafafa_core_mem.pas         # 核心内存单元测试
├── test_slabPool.pas                # SlabPool 详细测试
├── test_mem_utils.pas               # 内存工具函数测试
├── test_mem_allocator.pas           # 内存分配器测试
├── BuildAndTest.bat                 # 构建和测试脚本
└── README.md                        # 本文档
```

## 单测运行方式（mem-only）

```bash
# 构建 Debug 并运行测试（可追踪泄漏）
tests\fafafa.core.mem\BuildAndTest.bat
# 或手动：
lazbuild --build-mode=Debug tests\fafafa.core.mem\tests_mem.lpi
tests\fafafa.core.mem\bin\tests_mem_debug.exe --all --format=plain
```

## 示例程序位置（已迁移）
- 原跨域/集成型程序已迁移至：`examples/fafafa.core.mem/`
- 包括：`Test_memory_map*.pas`、`Test_shared_memory*.pas`、`Test_mapped_*.pas`、`Test_enhanced_*.pas`、`real_benchmark.pas`、`helper_sharedmem.*`
- 示例构建与运行：`examples\fafafa.core.mem\BuildAndRun.bat debug run`（产物输出到 `examples/.../bin`）


## 快速开始

### 构建和运行测试

```bash
# 方法1: 使用构建脚本 (推荐)
tests\fafafa.core.mem\BuildAndTest.bat

# 方法2: 手动构建
lazbuild --build-mode=Debug tests\fafafa.core.mem\tests_mem.lpi
bin\tests_mem_debug.exe --all --format=plain
```

## 测试覆盖

- **总测试数**: 51个
- **测试类数**: 9个
- **通过率**: 100%

### 测试模块

1. **TTestCase_CoreMem** (6个测试) - 核心内存功能
2. **TTestCase_MemPool** (4个测试) - 内存池
3. **TTestCase_StackPool** (4个测试) - 栈池
4. **TTestCase_SlabPool** (4个测试) - SlabPool基础
5. **TTestCase_SlabPool_Basic** (9个测试) - SlabPool基础功能
6. **TTestCase_SlabPool_SizeClasses** (5个测试) - 大小类别
7. **TTestCase_SlabPool_PageMerging** (5个测试) - 页面合并
8. **TTestCase_SlabPool_Performance** (5个测试) - 性能监控
9. **TTestCase_SlabPool_Configuration** (4个测试) - 配置选项
10. **TTestCase_SlabPool_EdgeCases** (5个测试) - 边界条件

## 内存泄漏检测

项目启用了完整的内存泄漏检测：

- **编译器选项**: `-gh` (heap trace), `-gl` (line info)
- **Lazarus配置**: `UseHeaptrc=True`
- **运行时检查**: 所有内存分配/释放都被监控

### 内存泄漏报告示例

```
Heap dump by heaptrc unit
2153 memory blocks allocated : 3405816
2153 memory blocks freed     : 3405816
0 unfreed memory blocks : 0
```

## 技术要求

- **Lazarus IDE** (用于 lazbuild)
- **Free Pascal Compiler** 3.3.1+
- **FPCUnit** 框架
- **Windows** 操作系统

## 项目特点

- ✅ 使用 lazbuild 正确构建
- ✅ 启用内存泄漏检测
- ✅ 完整的 SlabPool 测试覆盖
- ✅ 严格遵循现有代码风格
- ✅ 快速执行 (~3毫秒)
- ✅ 100% 测试通过率
