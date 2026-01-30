# example_resolve_and_walk

最小可运行示例，演示 fafafa.core.fs 的两类常用能力：
- 路径解析：ResolvePathEx（不触盘 vs 触盘+跟随符号链接）
- 目录遍历：WalkDir（带 PreFilter/PostFilter 过滤）

## 构建与运行

- Windows（PowerShell/CMD）：
  - 进入本目录
  - 执行 buildOrRun.bat（内部调用 lazbuild）

- Linux/macOS（bash）：
  - 进入本目录
  - 执行 ./buildOrRun.sh（内部调用 lazbuild）

如需自定义 lazbuild 路径，可设置环境变量 LAZBUILD_EXE。

## 预期输出（节选）

```
--- ResolvePathEx demo ---
Input  : example.tmp
Abs    : D:\...\example.tmp
Real   : D:\...\example.tmp
--- WalkDir demo ---
0: <repo_root>
1: <repo_root>\bin
1: <repo_root>\docs
1: <repo_root>\src
1: ...
```

说明：
- ResolvePathEx 默认不触盘；若需真实路径，传入 TouchDisk=True（若不存在则回退为绝对规范路径）
- WalkDir 的 PreFilter 跳过“以 . 开头”的目录子树；PostFilter 仅回调非空文件

## 常见问题（快速排查）

- Can't find unit fafafa.core.fs
  - 检查 example_resolve_and_walk.lpi 的 <OtherUnitFiles> 是否指向仓库 src 目录（本示例已配置为 ../../../src）
  - 使用 lazbuild 时确保工作目录正确，或在脚本中使用绝对路径
- Windows 真实路径/长路径异常
  - 确认系统 LongPathsEnabled，且（如需）启用 FAFAFA_CORE_FS_ENABLE_WIN_LONGPATH 宏
- Windows 符号链接相关失败
  - 需管理员权限或启用 Developer Mode；测试/示例前设置 FAFAFA_TEST_SYMLINK=1
- 输出与预期不同
  - ResolvePathEx 默认不触盘；若需真实路径，请传 TouchDisk=True；另注意 FollowLinks 的取值

## 参考文档
- 主文档与最佳实践：docs/fafafa.core.fs.md（含示例输出/FAQ）
- 示例索引：docs/EXAMPLES.md（含“快速排查”）

