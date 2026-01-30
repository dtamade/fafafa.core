# 目录结构规范

> 本文件位置：`docs/standards/DIRECTORY_STANDARDS.md`

本文档定义 fafafa.core 项目的目录结构标准，供 AI 助手和开发者遵循。

## 核心目录结构

```
fafafa.core/
├── src/                          # 源代码（只读，除非明确修改）
├── tests/                        # 单元测试
│   └── fafafa.core.<module>/     # 按模块组织
├── examples/                     # 示例代码
│   └── fafafa.core.<module>/     # 按模块组织
├── plays/                        # 实验性验证代码
│   └── fafafa.core.<module>/     # 按模块组织
├── benchmarks/                   # 性能基准测试
│   └── fafafa.core.<module>/     # 按模块组织
├── docs/                         # 文档
├── tools/                        # 开发工具脚本
├── workings/                     # 工作日志归档
└── reference/                    # 参考资料（不纳入 git）
```

## 目录用途说明

### tests/ - 单元测试

**用途**: 存放正式的单元测试代码

**结构**:
```
tests/
├── fafafa.core.collections.vec/
│   ├── BuildOrTest.bat
│   ├── BuildOrTest.sh
│   ├── Test_vec.pas
│   └── tests_vec.lpi
├── fafafa.core.collections.hashmap/
│   └── ...
└── run_all_tests.bat/.sh
```

**命名约定**:
- 目录名: fafafa.core.<module>
- 测试文件: Test_<feature>.pas 或 tests_<module>.pas
- 项目文件: tests_<module>.lpi
- 构建脚本: BuildOrTest.bat / BuildOrTest.sh

### examples/ - 示例代码

**用途**: 存放演示模块用法的示例程序

**结构**:
```
examples/
├── fafafa.core.collections/
│   ├── example_vec_basic.pas
│   ├── example_hashmap_usage.pas
│   └── README.md
├── fafafa.core.json/
│   └── ...
└── README.md
```

**命名约定**:
- 目录名: fafafa.core.<module>
- 示例文件: example_<feature>.pas
- 每个目录应有 README.md 说明示例内容

### plays/ - 实验性验证代码

**用途**: 存放临时的实验性代码、概念验证、调试脚本

**特点**:
- 代码质量要求较低
- 可以快速迭代
- 验证完成后可删除或归档
- 不纳入正式测试套件

**结构**:
```
plays/
├── fafafa.core.collections.vec/
│   ├── play_boundary_test.pas
│   ├── play_memory_debug.pas
│   └── notes.md
└── fafafa.core.simd/
    └── ...
```

**命名约定**:
- 目录名: fafafa.core.<module>
- 实验文件: play_<description>.pas
- 可选笔记: notes.md

### benchmarks/ - 性能基准测试

**用途**: 存放性能测试和基准比较代码

**结构**:
```
benchmarks/
├── fafafa.core.collections/
│   ├── benchmark_vec_insert.pas
│   ├── benchmark_hashmap_lookup.pas
│   └── results/
└── README.md
```

**命名约定**:
- 目录名: fafafa.core.<module>
- 基准文件: benchmark_<feature>.pas
- 结果目录: results/

## 禁止行为

### 根目录禁止

- 不得在根目录创建临时测试文件（.pas、.lpr）
- 不得在根目录创建可执行文件（.exe、无扩展名二进制）
- 不得在根目录创建临时报告文件（*_REPORT.md、CODE_REVIEW_*.md）
- 不得在根目录创建临时目录（temp/、tmp/、test/）

### 目录混用禁止

- 不得将单元测试放入 examples/
- 不得将示例代码放入 tests/
- 不得将实验代码放入 tests/ 或 examples/
- 不得将文档放入 src/

## 新模块检查清单

创建新模块时，按需创建以下目录：

- [ ] tests/fafafa.core.<module>/ - 单元测试（必须）
- [ ] examples/fafafa.core.<module>/ - 示例代码（推荐）
- [ ] plays/fafafa.core.<module>/ - 实验代码（按需）
- [ ] benchmarks/fafafa.core.<module>/ - 性能测试（按需）
- [ ] docs/fafafa.core.<module>.md - 模块文档（推荐）

## .gitignore 规则

以下内容应在 .gitignore 中排除：

```gitignore
# 参考资料目录（不纳入版本控制）
/reference/

# 构建产物
*.exe
*.o
*.ppu
*.compiled
/bin/
/lib/

# 临时文件
*.bak
*.tmp
*~

# IDE 文件
*.lps
```

## AI 助手指南

### 创建测试时

正确: tests/fafafa.core.collections.vec/Test_boundary.pas
错误: test_vec_boundary.pas (根目录)
错误: tests/test_boundary.pas (缺少模块目录)

### 创建示例时

正确: examples/fafafa.core.json/example_parse_file.pas
错误: example_json.pas (根目录)
错误: examples/json_example.pas (缺少模块目录)

### 创建实验代码时

正确: plays/fafafa.core.simd/play_avx512_test.pas
错误: play_simd.pas (根目录)
错误: simd_experiment.pas (根目录)

---

**最后更新**: 2026-01-14
