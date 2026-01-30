# fafafa.core.process 示例程序

本目录包含了 `fafafa.core.process` 模块的完整使用示例，演示了现代化进程管理的各种功能。

## 📁 文件结构

```
examples/fafafa.core.process/
├── example_process.lpr     # 主程序源代码
├── example_process.lpi     # Lazarus 项目文件
├── build.bat              # Windows 构建脚本
├── build.sh               # Linux 构建脚本
├── run.bat                # Windows 运行脚本
├── run.sh                 # Linux 运行脚本
├── README.md              # 本文件
└── lib/                   # 编译中间文件目录
├── example_pipeline_failfast.pas # 管线：合并错误流+捕获输出+FailFast 最小演示
├── build_failfast.bat            # Windows: 构建 failfast 示例
├── example_pipeline_failfast.lpi  # Lazarus 项目（failfast 示例）
├── run_failfast.sh                # Linux: 构建&运行 failfast 示例


- example_autodrain.lpr  AutoDrain 最小示例（Builder + 非 Builder 读取）

- build_autodrain.bat       # Windows: 构建 AutoDrain 示例
- run_autodrain.bat         # Windows: 构建并运行 AutoDrain 示例
- run_autodrain.sh          # Linux: 构建并运行 AutoDrain 示例
- example_combined_vs_capture_all.lpr  CombinedOutput vs CaptureAll 对比示例
- build_combined_vs_capture_all.bat     Windows: 构建示例
- run_combined_vs_capture_all.bat       Windows: 构建并运行示例
- run_combined_vs_capture_all.sh        Linux: 构建并运行示例
- example_silent_interactive.lpr        Silent vs Interactive 示例
- build_silent_interactive.bat           Windows: 构建示例
- run_silent_interactive.bat             Windows: 构建并运行示例
- run_silent_interactive.sh              Linux: 构建并运行示例
- example_background_foreground.lpr     Background vs Foreground 示例
- build_background_foreground.bat        Windows: 构建示例
- run_background_foreground.bat          Windows: 构建并运行示例
- example_timeout_killon_timeout.lpr  Timeout + KillOnTimeout 示例
- build_timeout_killon_timeout.bat     Windows: 构建示例
- run_timeout_killon_timeout.bat       Windows: 构建并运行示例
- example_group_policy.lpr             进程组策略（Windows Job Object）示例
- build_group_policy.bat               Windows: 构建示例
- run_group_policy.bat                 Windows: 构建并运行示例
- example_group_policy_sweep.lpr       Job Object GracefulWaitMs 扫描示例（输出终止耗时）
- build_group_policy_sweep.bat          Windows: 构建示例
- run_group_policy_sweep.bat            Windows: 运行示例（可选传参 ms，例如 0/200/500/1000）


- example_pipeline_best_practices.lpr  Pipeline 末端输出最佳实践（合流 vs 分路）

- example_pipeline_redirect_and_split.lpr Pipeline：stdout→文件，stderr→内存（分路）
- build_pipeline_redirect_and_split.bat  Windows: 构建示例
- run_pipeline_redirect_and_split.bat    Windows: 运行示例



- example_wmclose_child_gui.lpr        简易 GUI 子进程（响应 WM_CLOSE）
- build_wmclose_child_gui.bat           Windows: 构建 GUI 子进程
- run_wmclose_child_gui.bat             Windows: 运行 GUI 子进程




├── example_redirect_file_and_capture_err.pas # stdout→文件，stderr→内存捕获

├── example_capture_stdout_redirect_err.pas  # stdout→内存捕获，stderr→文件
├── run_capture_stdout_redirect_err.bat       # Windows: 构建&运行该示例
├── run_capture_stdout_redirect_err.sh        # Linux: 构建&运行该示例

├── example_both_redirect_to_file.pas       # stdout/stderr 都重定向到文件（Pipeline）
├── run_both_redirect_to_file.bat           # Windows: 构建&运行该示例
├── run_both_redirect_to_file.sh            # Linux: 构建&运行该示例


```

## 🎯 示例功能

本示例程序演示了以下功能：

### 1. 基本进程启动和等待
- 创建进程启动配置
- 启动进程并获取进程ID
- 等待进程完成并获取退出码
- 计算进程运行时间

### 2. 参数传递和环境变量
- 向子进程传递命令行参数
- 设置自定义环境变量
- 验证环境变量在子进程中的可用性

### 3. 标准输出重定向
- 重定向子进程的标准输出
- 从父进程读取子进程的输出数据
- 处理大量输出数据的读取

### 4. 标准输入重定向
- 重定向子进程的标准输入
- 向子进程写入数据
- 正确关闭输入流

### 5. 进程优先级和窗口状态控制
- 设置进程优先级（高、正常、低等）
- 控制窗口显示状态（隐藏、正常、最小化等）

### 6. 错误处理和异常管理
- 处理无效的可执行文件
- 处理无效的工作目录
- 处理在已终止进程上的操作
- 展示各种异常类型的捕获

## 🚀 快速开始

### Windows 环境

1. **构建项目**：
   ```batch
   # Debug 模式（默认）
   build.bat

   # Release 模式
   build.bat release
   ```

2. **运行示例**：
   ```batch
   # 自动构建并运行
   run.bat

   # 或直接运行可执行文件
   ..\..\bin\example_process.exe
   ```

3. **AutoDrain 示例（建议先阅读 docs/fafafa.core.process.md 的“AutoDrain 行为与边界”）**：
   ```batch
   run_autodrain.bat
   ```


### Linux 环境

1. **构建项目**：
   ```bash
   # Debug 模式（默认）
   ./build.sh

   # Release 模式
   ./build.sh release
   ```

2. **运行示例**：
   ```bash
   # 自动构建并运行
   ./run.sh

   # 或直接运行可执行文件
   ../../bin/example_process

3. **AutoDrain 示例（推荐先读文档的“AutoDrain 行为与边界”）**：
   ```bash
   # 构建并运行 AutoDrain 示例
   ./run_autodrain.sh
   ```

   ```

## 📋 系统要求

### 编译环境
- **FreePascal**: 3.2.0 或更高版本
- **Lazarus**: 2.0.0 或更高版本（可选，用于IDE开发）

### 运行环境
- **Windows**: Windows 7 或更高版本
- **Linux**: 任何现代 Linux 发行版
- **macOS**: macOS 10.12 或更高版本（理论支持，未测试）

### 依赖模块
- `fafafa.core.base` - 核心基础模块
- `fafafa.core.process` - 进程管理模块

## 🔧 构建配置

项目支持两种构建模式：

### Debug 模式
- 包含调试信息
- 启用运行时检查（范围检查、IO检查等）
- 启用内存泄漏检测
- 优化级别：无优化

### Release 模式
- 不包含调试信息
- 禁用运行时检查
- 启用智能链接
- 优化级别：最高优化

## 📖 代码示例

以下是一个简单的使用示例：

```pascal
uses
  fafafa.core.process;

var
  LStartInfo: IProcessStartInfo;
  LProcess: IProcess;
begin
  // 创建进程配置
  LStartInfo := TProcessStartInfo.Create;
  LStartInfo.FileName := 'cmd.exe';
  LStartInfo.Arguments := '/c echo Hello World';
  LStartInfo.RedirectStandardOutput := True;

  // 创建并启动进程
  LProcess := TProcess.Create(LStartInfo);
  LProcess.Start;

  // 等待完成并读取输出
  if LProcess.WaitForExit(5000) then
  begin
    // 读取输出数据...
    WriteLn('进程完成，退出码: ', LProcess.ExitCode);
  end;
end;
```

## 🐛 故障排除

### 常见问题

1. **找不到 lazbuild**
   - 确保 Lazarus 已正确安装
   - 检查 PATH 环境变量
   - 修改构建脚本中的路径设置

2. **编译错误**
   - 检查 FreePascal 版本是否符合要求
   - 确保所有依赖模块都在正确的路径下
   - 检查项目文件中的路径配置

3. **运行时错误**
   - 检查目标平台的系统要求
   - 确保有足够的权限执行程序
   - 查看详细的错误信息

### 获取帮助

如果遇到问题，请：
1. 查看构建日志中的详细错误信息
2. 检查系统环境和依赖
3. 参考 `docs/fafafa.core.process.md` 中的详细文档
4. 查看测试用例了解正确的使用方法

## 📄 许可证

本示例程序遵循 MIT 许可证，详情请参见项目根目录的 LICENSE 文件。

## 🤝 贡献

欢迎提交问题报告、功能请求和代码贡献。请确保：
- 遵循现有的代码风格
- 添加适当的测试用例
- 更新相关文档

---

**fafafa.core 开发团队**
版本：1.0.0
更新时间：2025-01-06
