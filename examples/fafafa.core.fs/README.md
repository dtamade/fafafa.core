# fafafa.core.fs Examples

这个目录包含了 fafafa.core.fs 文件系统模块的演示示例，展示了模块的各种功能和特性。

## 📁 示例列表

### ✅ 可用示例 (标准命名)

| 示例文件 | 功能描述 | 演示内容 |
|---------|---------|---------|
| `example_fs_basic.lpr` | 基础文件操作 | 文件创建、读写、删除等基本操作 |
| `example_fs_advanced.lpr` | 高级功能演示 | 文件属性、权限、高级操作 |
| `example_fs_performance.lpr` | 性能对比测试 | 与标准库的性能对比 |
| `example_fs_benchmark.lpr` | 基准测试 | 详细的性能基准测试 |
| `example_copytree_follow/example_copytree_follow.lpr` | FollowSymlinks 示例 | 目录树复制中 symlink 的 True/False 行为（Windows 需管理员/开发者模式或设置 FAFAFA_TEST_SYMLINK=1） |
| `example_copytree_preserve/example_copytree_preserve.lpr` | PreserveTimes/Perms 示例 | 目录树复制时时间与权限的 best‑effort 保留（POSIX 有效；Windows 仅时间戳 best‑effort） |
| `example_writefileatomic/example_writefileatomic.lpr` | 原子写入示例 | 先写临时文件，成功后 fs_replace 原子覆盖目标；Windows/Linux 一键脚本 |
| `example_resolve_and_walk/example_resolve_and_walk.lpr` | 路径解析与遍历 | Resolve/ResolvePathEx（不触盘/触盘）与 WalkDir 过滤/统计演示（Windows/Linux 一键脚本） |
| `example_canonicalize_vs_resolve/example_canonicalize_vs_resolve.lpr` | 路径解析矩阵演示 | Resolve / ResolvePathEx / Canonicalize 行为对比（Windows/Linux 一键脚本） |


### ℹ️ Windows 长路径注意事项
- 若需演示/测试超长路径（>260），请确保系统 LongPathsEnabled 可用，并视需要在工程中启用宏 FAFAFA_CORE_FS_ENABLE_WIN_LONGPATH（src/fafafa.core.settings.inc）
- 示例/测试条件开关：PowerShell 下 `$env:FAFAFA_TEST_WIN_LONGPATH="1"`；CMD 下 `set FAFAFA_TEST_WIN_LONGPATH=1`
- 详见：docs/fafafa.core.fs.md 的“Windows 长路径行为与限制 / ValidatePath（Windows 路径长度判定）”小节

### ⚠️ 需要修复的示例

| 示例文件 | 状态 | 问题描述 |
|---------|------|---------|
| `example_fs_showcase.lpr` | 编译错误 | 类型兼容性问题 |
| `example_fs_path.lpr` | 需要检查 | 可能的编译问题 |

## 🔨 构建和运行

### 一键构建与运行（标准脚本）
```bat
REM 构建所有示例（调用 tools\lazbuild.bat 或回退 fpc）
BuildExamples.bat

REM 运行已构建的示例（逐个暂停）
RunExamples.bat

REM 清理产物
CleanExamples.bat
```

> 兼容性提示：旧脚本 build_examples*.bat / clean_examples*.bat 将在一个版本保留，后续移除。请迁移到新脚本。

### 单独构建
```bash
# 构建单个示例
fpc -Mobjfpc -Fu"..\..\src" -FE. -gl -O2 -o"example_fs_basic.exe" "example_fs_basic.lpr"
```

### 运行示例
```bat
cd bin
example_fs_basic.exe
example_fs_advanced.exe
example_fs_performance.exe
example_fs_benchmark.exe
example_fs_path.exe
example_copytree_follow.exe
```


### PreserveTimes/Perms 运行提示
- 本示例：`example_copytree_preserve/`
  - POSIX：可观察到 chmod 低 9 位与 mtime（含纳秒级）在复制后基本一致（best‑effort，受 ACL/umask/挂载点影响）
  - Windows：仅 best‑effort 设置时间戳（SetFileTime）；权限模型不同于 POSIX，示例会打印提示，建议使用 ACL 工具链管理权限
- 运行方式：
  - Windows: `examples\fafafa.core.fs\example_copytree_preserve\buildOrRun.bat`
  - Linux/macOS: 仿照 Windows 脚本，用 fpc 编译并运行（需将 `src/` 加入 -Fu）

也可使用 RunExamples.bat 一键运行。

## 📋 示例详细说明

### 1. example_fs_basic.lpr - 基础文件操作
**演示内容:**
- 文件创建和写入
- 文件读取和内容验证
- 文件删除和清理
- 基本错误处理

**预期输出:**
```
=== fafafa.core.fs 基础文件操作演示 ===
✓ 文件创建成功
✓ 数据写入成功
✓ 文件读取成功
✓ 内容验证通过
✓ 文件删除成功
```

### 2. example_fs_advanced.lpr - 高级功能演示
**演示内容:**
- 文件属性和权限操作
- 目录创建和遍历
- 文件复制和移动
- 高级错误处理

**预期输出:**
```
=== fafafa.core.fs 高级功能演示 ===
✓ 目录操作成功
✓ 文件属性设置成功
✓ 权限控制验证通过
✓ 文件复制成功
```

### 3. example_fs_performance.lpr - 性能对比
**演示内容:**
- 与标准库的读写性能对比
- 大文件操作性能测试
- 批量操作性能对比
- 内存使用效率对比

**预期输出:**
```
=== fafafa.core.fs 性能对比测试 ===
📊 小文件读写: fafafa.core.fs 比标准库快 15%
📊 大文件操作: fafafa.core.fs 比标准库快 25%
📊 批量操作: fafafa.core.fs 比标准库快 30%
```

### 4. example_fs_benchmark.lpr - 基准测试
**演示内容:**
- 详细的性能基准测试
- 不同文件大小的性能表现
- 并发操作性能测试
- 内存映射性能测试

**预期输出:**
```
=== fafafa.core.fs 基准测试 ===
📈 文件读取基准: 1000 次操作，平均 0.5ms
📈 文件写入基准: 1000 次操作，平均 0.8ms
📈 内存映射基准: 100MB 文件，映射时间 2ms
```

## 🎯 命名规范

所有示例文件遵循统一的命名规范：
```
example_fs_<功能名>.lpr
```

这个规范确保了：
- **一致性**: 所有示例都有统一的前缀
- **可识别性**: 一眼就能看出是文件系统模块的示例
- **可扩展性**: 便于添加新的示例类型

## 🔧 开发指南

### 添加新示例
1. 创建新文件: `example_fs_<新功能>.lpr`
2. 添加到构建脚本中
3. 更新此 README 文档
4. 确保示例有清晰的输出和注释

### 示例代码规范
```pascal
program example_fs_<功能名>;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$UNITPATH ..\..\src}

uses
  SysUtils,
  fafafa.core.fs;

begin
  WriteLn('=== fafafa.core.fs <功能名>演示 ===');
  WriteLn;

  // 演示代码

  WriteLn;
  WriteLn('=== 演示完成 ===');
end.
```

## 📊 测试覆盖

当前示例覆盖的功能模块：
- ✅ 基础文件操作 (CRUD)
- ✅ 高级文件操作 (属性、权限)
- ✅ 性能测试和基准
- ⚠️ 内存映射 (需要修复)
- ⚠️ 路径操作 (需要检查)
- ❌ 异步操作 (等待 Thread 模块)
- ❌ 虚拟文件系统 (未来功能)

## 🚀 下一步计划

1. **修复现有问题**: 解决 showcase 和 path 示例的编译错误
2. **添加新示例**: 内存映射专项演示
3. **改进输出**: 更美观的演示效果
4. **性能优化**: 基于基准测试结果优化
5. **文档完善**: 添加更详细的使用说明

---

*最后更新: 2025-01-06*
*状态: 4个示例可用，2个需要修复*
