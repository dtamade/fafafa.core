# fafafa.core 工程规范

> 本文件位置：`docs/standards/ENGINEERING_STANDARDS.md`

本文档定义了 fafafa.core 项目的工程标准和最佳实践。

## 1. 构建系统规范

### 1.1 必须使用 lazbuild 编译

所有项目必须通过 Lazarus 项目文件 (`.lpi`) 进行构建：

```bash
# 标准构建命令
/opt/fpcupdeluxe/lazarus/lazbuild --lazarusdir=/opt/fpcupdeluxe/lazarus <project.lpi>

# 或使用系统路径中的 lazbuild
lazbuild <project.lpi>
```

**禁止行为**：
- ❌ 直接使用 `fpc` 命令编译（除非是快速验证）
- ❌ 在源码目录生成编译产物
- ❌ 手动指定输出路径覆盖 lpi 配置

### 1.2 源码目录必须保持清洁

`src/` 目录**禁止**包含任何编译产物：
- `.o` - 目标文件
- `.ppu` - 编译单元文件
- `.compiled` - 编译状态文件
- 可执行文件

**验证命令**：
```bash
find src/ -name "*.o" -o -name "*.ppu" | wc -l
# 期望输出: 0
```

### 1.3 lpi 项目配置标准

每个 `.lpi` 文件必须配置以下输出目录：

```xml
<Target>
  <Filename Value="bin\<executable_name>"/>
</Target>
<SearchPaths>
  <UnitOutputDirectory Value="lib\$(TargetCPU)-$(TargetOS)"/>
</SearchPaths>
```

**目录结构**：
```
project_dir/
├── bin/                    # 可执行文件输出
├── lib/                    # 编译单元输出
│   └── x86_64-linux/       # 平台特定子目录
├── project.lpi             # Lazarus 项目文件
└── project.lpr             # 主程序源文件
```

## 2. 模块组织规范

### 2.1 目录结构

每个模块必须遵循以下目录结构：

```
fafafa.core/
├── src/
│   └── fafafa.core.<module>.pas       # 源代码
├── tests/
│   └── fafafa.core.<module>/          # 单元测试
│       ├── BuildOrTest.lpi            # 测试项目文件
│       ├── BuildOrTest.bat            # Windows 构建脚本
│       ├── BuildOrTest.sh             # Linux/macOS 构建脚本
│       ├── fafafa.core.<module>.testcase.pas
│       ├── bin/                       # 测试可执行文件
│       └── lib/                       # 测试编译单元
├── examples/
│   └── fafafa.core.<module>/          # 示例程序
│       ├── example_<name>.lpi         # 示例项目文件
│       ├── example_<name>.lpr         # 示例源代码
│       ├── bin/                       # 示例可执行文件
│       └── lib/                       # 示例编译单元
└── docs/
    └── fafafa.core.<module>.md        # 模块文档
```

### 2.2 一键构建脚本规范

每个测试目录和示例目录**必须**配备跨平台的一键构建脚本：

**测试目录脚本**：
```
tests/fafafa.core.<module>/
├── BuildOrTest.sh             # Linux/macOS 构建并运行测试
└── BuildOrTest.bat            # Windows 构建并运行测试
```

**示例目录脚本**：
```
examples/fafafa.core.<module>/
├── BuildOrRun.sh              # Linux/macOS 构建并运行示例
└── BuildOrRun.bat             # Windows 构建并运行示例
```

**脚本模板 - BuildOrTest.sh (测试)**：
```bash
#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# 查找 lazbuild
LAZBUILD="${LAZBUILD:-lazbuild}"
if ! command -v "$LAZBUILD" &> /dev/null; then
    if [ -x "/opt/fpcupdeluxe/lazarus/lazbuild" ]; then
        LAZBUILD="/opt/fpcupdeluxe/lazarus/lazbuild --lazarusdir=/opt/fpcupdeluxe/lazarus"
    fi
fi

# 编译
echo "Building tests..."
$LAZBUILD *.lpi

# 运行测试
echo "Running tests..."
./bin/*
```

**脚本模板 - BuildOrTest.bat (测试)**：
```batch
@echo off
setlocal
cd /d "%~dp0"

:: 编译
echo Building tests...
lazbuild *.lpi
if errorlevel 1 exit /b 1

:: 运行测试
echo Running tests...
for %%f in (bin\*.exe) do "%%f"
```

**脚本模板 - BuildOrRun.sh (示例)**：
```bash
#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# 查找 lazbuild
LAZBUILD="${LAZBUILD:-lazbuild}"
if ! command -v "$LAZBUILD" &> /dev/null; then
    if [ -x "/opt/fpcupdeluxe/lazarus/lazbuild" ]; then
        LAZBUILD="/opt/fpcupdeluxe/lazarus/lazbuild --lazarusdir=/opt/fpcupdeluxe/lazarus"
    fi
fi

# 编译
echo "Building example..."
$LAZBUILD *.lpi

# 运行示例
echo "Running example..."
./bin/*
```

**脚本模板 - BuildOrRun.bat (示例)**：
```batch
@echo off
setlocal
cd /d "%~dp0"

:: 编译
echo Building example...
lazbuild *.lpi
if errorlevel 1 exit /b 1

:: 运行示例
echo Running example...
for %%f in (bin\*.exe) do "%%f"
```

### 2.3 模块完成度检查清单

| 检查项 | 要求 |
|--------|------|
| 源代码 | `src/fafafa.core.<module>.pas` 存在 |
| 单元测试 | `tests/fafafa.core.<module>/` 目录存在且包含 lpi 文件 |
| 测试脚本 | `BuildOrTest.sh` 和 `BuildOrTest.bat` 存在 |
| 示例程序 | `examples/fafafa.core.<module>/` 目录存在且包含 lpi 文件 |
| 示例脚本 | `BuildOrRun.sh` 和 `BuildOrRun.bat` 存在 |
| 文档 | `docs/fafafa.core.<module>.md` 存在 |
| 编译通过 | lazbuild 编译无错误 |
| 测试通过 | 所有测试用例通过 |

## 3. 测试规范

### 3.1 测试项目配置

测试项目 lpi 文件必须配置：

```xml
<Target>
  <Filename Value="bin\tests_<module>"/>
</Target>
<SearchPaths>
  <IncludeFiles Value="$(ProjOutDir);..\..\src"/>
  <OtherUnitFiles Value="..\..\src"/>
  <UnitOutputDirectory Value="lib\$(TargetCPU)-$(TargetOS)"/>
</SearchPaths>
```

### 3.2 运行测试

```bash
# 运行单个模块测试
cd tests/fafafa.core.<module>
bash BuildOrTest.sh

# 运行全量测试
bash tests/run_all_tests.sh

# 快速回归测试（核心模块）
STOP_ON_FAIL=1 bash tests/run_all_tests.sh \
  fafafa.core.collections.arr \
  fafafa.core.collections.base \
  fafafa.core.collections.vec \
  fafafa.core.collections.vecdeque
```

### 3.3 内存泄漏检测

使用 HeapTrc 进行内存泄漏检测：

```bash
# 在 lpi 中启用 HeapTrc
<Linking>
  <Debugging>
    <UseHeaptrc Value="True"/>
  </Debugging>
</Linking>
```

期望输出：`0 unfreed memory blocks`

## 4. 示例程序规范

### 4.1 示例项目配置

示例项目 lpi 文件必须配置：

```xml
<Target>
  <Filename Value="bin\example_<name>"/>
</Target>
<SearchPaths>
  <IncludeFiles Value="$(ProjOutDir);..\..\src"/>
  <OtherUnitFiles Value="..\..\src"/>
  <UnitOutputDirectory Value="lib\$(TargetCPU)-$(TargetOS)"/>
</SearchPaths>
```

### 4.2 示例代码规范

- 必须包含清晰的注释说明
- 必须演示模块的核心功能
- 必须能独立编译运行
- 输出应清晰易懂

## 5. 文档规范

### 5.1 模块文档结构

每个模块文档应包含：

```markdown
# fafafa.core.<module>

## 概述
模块功能简介

## 快速开始
基本使用示例

## API 参考
### 类型
### 函数
### 常量

## 示例
完整示例代码

## 最佳实践
使用建议和注意事项

## 更新日志
版本变更记录
```

### 5.2 文档位置

| 文档类型 | 位置 |
|----------|------|
| 模块文档 | `docs/fafafa.core.<module>.md` |
| API 参考 | `docs/API_Reference.md` |
| 变更日志 | `docs/CHANGELOG.md` |
| 架构文档 | `docs/Architecture.md` |

## 6. 归档规范

### 6.1 归档目录结构

```
archive/
├── reports/
│   ├── working/           # 工作日志
│   ├── code-reviews/      # 代码审查报告
│   ├── issues/            # 问题修复报告
│   └── summaries/         # 阶段总结
└── <year>-<month>-<topic>/  # 历史归档
```

### 6.2 归档规则

- 过时的报告文件必须移至 `archive/` 目录
- 根目录禁止创建临时报告文件
- 超过 6 个月的报告可压缩归档

## 7. 模块分层规范

### 7.1 层次结构

```
Layer 0 (基础层):
  - fafafa.core.base      # 基础类型和工具
  - fafafa.core.mem       # 内存管理
  - fafafa.core.math      # 数学运算
  - fafafa.core.option    # Option 类型
  - fafafa.core.result    # Result 类型

Layer 1 (核心层):
  - fafafa.core.collections.*  # 集合类型
  - fafafa.core.atomic         # 原子操作
  - fafafa.core.sync.*         # 同步原语

Layer 2 (功能层):
  - fafafa.core.json      # JSON 处理
  - fafafa.core.fs        # 文件系统
  - fafafa.core.process   # 进程管理
  - ...
```

### 7.2 依赖规则

- 高层模块可依赖低层模块
- 同层模块应避免循环依赖
- 禁止低层模块依赖高层模块

## 8. 版本控制规范

### 8.1 提交信息格式

使用中文提交信息，格式：

```
<类型>: <简短描述>

<详细说明（可选）>
```

类型：
- `✨ 新增` - 新功能
- `🐛 修复` - Bug 修复
- `📝 文档` - 文档更新
- `♻️ 重构` - 代码重构
- `✅ 测试` - 测试相关
- `🔧 配置` - 配置变更

### 8.2 分支策略

- `main` - 主分支，保持稳定
- `feature/*` - 功能分支
- `fix/*` - 修复分支

---

## 附录：快速检查命令

```bash
# 检查源码目录清洁度
find src/ -name "*.o" -o -name "*.ppu" | wc -l

# 编译所有测试
for lpi in tests/*/BuildOrTest.lpi; do
  lazbuild "$lpi"
done

# 编译所有示例
for lpi in examples/*/*.lpi; do
  lazbuild "$lpi"
done

# 运行全量测试
bash tests/run_all_tests.sh
```

---

*最后更新: 2026-01-13*
