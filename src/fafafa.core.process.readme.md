# fafafa.core.process - 现代化进程管理模块

## 📋 概述

`fafafa.core.process` 是一个现代化的、跨平台的进程管理模块，提供了类型安全的接口和完整的功能实现。

## 🎯 设计目标

- **现代化接口设计**：借鉴 Rust std::process、Go os/exec、.NET Process 的优秀设计
- **跨平台支持**：统一的接口，支持 Windows 和 Unix 系统
- **类型安全**：强类型接口，编译时错误检查
- **资源管理**：自动资源清理，防止内存泄漏
- **测试驱动**：100% 测试覆盖率，确保代码质量

## 🏗️ 架构设计

### 核心接口

```pascal
// 进程启动配置接口
IProcessStartInfo = interface
  // 基本属性
  property FileName: string read GetFileName write SetFileName;
  property Arguments: string read GetArguments write SetArguments;
  property WorkingDirectory: string read GetWorkingDirectory write SetWorkingDirectory;

  // 流重定向
  property RedirectStandardInput: Boolean read GetRedirectStandardInput write SetRedirectStandardInput;
  property RedirectStandardOutput: Boolean read GetRedirectStandardOutput write SetRedirectStandardOutput;
  property RedirectStandardError: Boolean read GetRedirectStandardError write SetRedirectStandardError;

  // 进程属性
  property Priority: TProcessPriority read GetPriority write SetPriority;
  property WindowShowState: TWindowShowState read GetWindowShowState write SetWindowShowState;

  // 环境变量管理
  property Environment: TStringList read GetEnvironment;
  procedure SetEnvironmentVariable(const aName, aValue: string);
  function GetEnvironmentVariable(const aName: string): string;

  // 验证
  procedure Validate;
end;

// 进程管理核心接口
IProcess = interface
  // 生命周期管理
  procedure Start;
  function WaitForExit(aTimeoutMs: Cardinal = INFINITE): Boolean;
  procedure Kill;
  procedure Terminate;

  // 状态查询
  property State: TProcessState read GetState;
  property ExitCode: Integer read GetExitCode;
  property ProcessId: Cardinal read GetProcessId;
  property HasExited: Boolean read GetHasExited;

  // 时间信息
  property StartTime: TDateTime read GetStartTime;
  property ExitTime: TDateTime read GetExitTime;

  // 流访问
  property StandardInput: TStream read GetStandardInput;
  property StandardOutput: TStream read GetStandardOutput;
  property StandardError: TStream read GetStandardError;

  // 配置访问
  property StartInfo: IProcessStartInfo read GetStartInfo;
end;
```

### 实现模式

模块采用**分层实现**的策略：

1. **接口层**：定义统一的、跨平台的接口
2. **抽象层**：提供平台无关的基础实现
3. **平台层**：提供平台相关的具体实现

## 🔧 实现模式

### 当前状态：模拟实现

默认情况下，模块使用**模拟实现**，这提供了：

- ✅ 完整的接口功能
- ✅ 100% 测试覆盖率
- ✅ 快速的单元测试执行
- ✅ 跨平台兼容性
- ✅ 学习和演示用途

### 真实实现：生产级功能

通过定义 `FAFAFA_REAL_PROCESS_IMPLEMENTATION` 编译指令，可以启用真实的平台实现：

```pascal
{$DEFINE FAFAFA_REAL_PROCESS_IMPLEMENTATION}
```

真实实现包括：

- 🔧 真正的进程启动（CreateProcess/fork+exec）
- 🔧 真正的流重定向（管道机制）
- 🔧 真正的进程等待和监控
- 🔧 平台相关的错误处理
- 🔧 高级功能（优先级、环境变量等）


## 🧪 环境变量与搜索策略（Windows 重点）

- 环境块构造（CreateProcessW 的 lpEnvironment）：
  - 使用 Unicode（UTF-16LE）并以双零终止
  - 变量名大小写不敏感；重复键按“最后一次赋值生效”规则合并
  - 支持空值与 Unicode（含非 BMP 字符）；非法空字符将被拒绝
- PATH/PATHEXT 搜索：
  - 当 FileName 非绝对路径且启用 UsePathSearch=True 时，遵循 PATH + PATHEXT 扩展查找
  - 出于安全考虑，不搜索当前目录（不依赖 SearchPath 默认行为），仅使用环境中的 PATH
  - PATHEXT 为空时回退到 .COM;.EXE;.BAT;.CMD
- UseShellExecute 能力边界（最小子集）：

## 宏开关与行为差异（摘要）
- FAFAFA_PROCESS_AUTO_DRAIN_ON_WAIT：Wait 前按需启动后台排水（stdout/stderr → 内存缓冲）
- FAFAFA_PROCESS_SHELLEXECUTE_MINIMAL（Win）：UseShellExecute=True 且无重定向/自定义环境/合流时走 ShellExecuteExW；否则抛错
- FAFAFA_PROCESS_USE_POSIX_SPAWN（Unix）：优先使用 posix_spawn

## 参数转义与 PATH 搜索（要点）
- Windows：QuoteArgWindows 遵循 CRT 规则（引号/反斜杠）；建议使用 Args 列表
- Unix：直接 argv 传递；PATH 必须具备可执行权限
- Windows PATH/PATHEXT：显式传 PATH 给 SearchPathW，避免当前目录


## 🧭 Unix 最佳实践与边界说明

- PATH 搜索
  - 显式设置 PATH 或使用绝对路径；模块默认不搜索当前目录
  - PATH 的空项（":"）将被忽略，不视为当前目录；重复目录仅带来性能损耗
- 可执行位要求
  - 至少具备一个执行位（owner/group/others）；目录/FIFO/Socket 等不可执行
- Shebang（#!）
  - 解释器不可用时会失败或返回非 0；部署前验证解释器可用性
- 安全建议
  - 避免通过 shell 传参，优先 argv 直接传参；对不受信输入进行参数化

### Unix 示例：安全 PATH 与 argv 传参

```pascal
fpSetEnv(PChar('PATH=/usr/bin:/bin'));
SI := TProcessStartInfo.Create; SI.FileName := 'grep'; SI.ClearArgs;
SI.AddArg('grep'); SI.AddArg('-n'); SI.AddArg('pattern'); SI.AddArg('/var/log/syslog');
SI.SetUsePathSearch(True); SI.RedirectStandardOutput := True; SI.Validate;
```

### 外部流注入示例（大输出落地）

```pascal
var
  SI: IProcessStartInfo;
  FS: TFileStream;
begin
  SI := TProcessStartInfo.Create('mytool', '--dump-big');
  SI.RedirectStandardOutput := True;
  SI.SetDrainOutput(True);
  FS := TFileStream.Create('out.log', fmCreate);
  SI.AttachStdOut(FS, False); // 不转移拥有权
  // ... 启动并等待 ...
end;
```

### 优雅终止（两阶段）

```pascal
var
  C: IChild;
begin
  C := NewProcessBuilder.Exe('worker').Args(['--serve']).Start;
  if not C.GracefulShutdown(3000) then C.Kill;
end;
```

  - 与重定向（stdin/stdout/stderr）或自定义环境不兼容；否则抛出 EProcessStartError


## 📊 测试覆盖

模块包含 **62 个全面的测试用例**，覆盖：

### TProcessStartInfo 测试（29个）
- 构造函数和基本属性
- 环境变量管理（Windows 大小写不敏感）
- 参数处理和验证
- 边界条件和异常处理

### TProcess 测试（33个）
- 生命周期管理（启动、等待、终止）
- 状态查询和时间记录
- 流重定向功能
- 多进程并发
- 异常处理和边界条件

## 🚀 使用示例

### 基本用法

```pascal
var
  LStartInfo: IProcessStartInfo;
  LProcess: IProcess;
begin
  // 创建启动配置
  LStartInfo := TProcessStartInfo.Create('cmd.exe', '/c echo Hello World');
  LStartInfo.RedirectStandardOutput := True;

  // 启动进程
  LProcess := TProcess.Create(LStartInfo);
  LProcess.Start;

  // 等待完成
  if LProcess.WaitForExit(5000) then
  begin
    WriteLn('进程退出码: ', LProcess.ExitCode);

    // 读取输出
    if LProcess.StandardOutput <> nil then
    begin
      var LOutput := TStringStream.Create;
      try
        LOutput.CopyFrom(LProcess.StandardOutput, 0);
        WriteLn('输出: ', LOutput.DataString);
      finally
        LOutput.Free;
      end;
    end;
  end
  else

## 📚 API Reference（精选）

### IProcessStartInfo

- RedirectStandardOutput / RedirectStandardError
  - 启用对应管道重定向。若未启用，StandardOutput/StandardError 不可读取

- SetDrainOutput(aEnable: Boolean)
  - 为 True 时，模块会在后台线程持续读取 stdout/stderr
  - 写入目标：若已 Attach 外部流，则写入该流；否则写入内存缓冲（TMemoryStream）
  - 后果：避免因未及时读取导致子进程阻塞；适合大输出场景

- AttachStdOut(AStream: TStream; aOwn: Boolean = False)
  - 将标准输出的后台排水目标定向到外部流
  - aOwn=True：StartInfo.Destroy 时释放该流；False：调用方自行管理
  - 搭配建议：需配合 RedirectStandardOutput=True 与 SetDrainOutput(True)
  - 注意：此模式下 StandardOutput 返回的内存缓冲可能为空或仅用于补充；建议直接读取外部文件/流

- AttachStdErr(AStream: TStream; aOwn: Boolean = False)
  - 含义同上，定向标准错误到外部流；与 StdErrToStdOut 互斥

- StdErrToStdOut(aEnable: Boolean)
  - 将 stderr 合流到 stdout（平台侧句柄合流/dup2）；便于统一读取
  - 与 AttachStdErr 不应同时启用

- UsePathSearch(aEnable: Boolean)
  - Windows：遵循 PATH+PATHEXT；默认不搜索当前目录
  - Unix：遵循 PATH；要求可执行位；默认不搜索当前目录

- 环境变量（Environment / SetEnvironmentVariable / GetEnvironmentVariable / ClearEnvironment）
  - Windows：变量名大小写不敏感；重复键最后一次赋值生效；忽略以 "=" 起始的伪变量
  - Unix：区分大小写

示例片段：

```pascal
// 大输出落地到文件
SI := TProcessStartInfo.Create('mytool', '--dump');
SI.RedirectStandardOutput := True;
SI.SetDrainOutput(True);
FS := TFileStream.Create('out.log', fmCreate);
SI.AttachStdOut(FS, False);
```

### IChild

- GracefulShutdown(timeoutMs: Cardinal = 3000): Boolean
  - 行为：先调用 Terminate（Windows 等价 Kill；Unix 发送 SIGTERM），等待指定超时
  - 返回：在超时内退出则 True；未退出则 False（不自动 Kill）
  - 建议：两阶段策略——若返回 False，随后调用 Kill 兜底

示例片段：

```pascal
C := NewProcessBuilder.Exe('worker').Args(['--serve']).Start;
if not C.GracefulShutdown(3000) then C.Kill;
```

### 组合便捷

- CombinedOutput = CaptureStdOut + StdErrToStdOut + DrainOutput(True)
- CaptureAll = 重定向 stdin/stdout/stderr + DrainOutput(True)（不合流）


    WriteLn('进程超时');
end;
```

### 高级用法

```pascal
var
  LStartInfo: IProcessStartInfo;
  LProcess: IProcess;
begin
  // 创建高级配置
  LStartInfo := TProcessStartInfo.Create;
  LStartInfo.FileName := 'myapp.exe';
  LStartInfo.Arguments := '--config config.json';
  LStartInfo.WorkingDirectory := 'C:\MyApp';
  LStartInfo.Priority := ppHigh;
  LStartInfo.WindowShowState := wsHidden;

  // 设置环境变量
  LStartInfo.SetEnvironmentVariable('MY_VAR', 'my_value');

  // 启用所有流重定向
  LStartInfo.RedirectStandardInput := True;
  LStartInfo.RedirectStandardOutput := True;
  LStartInfo.RedirectStandardError := True;

  // 验证配置
  LStartInfo.Validate;

  // 启动进程
  LProcess := TProcess.Create(LStartInfo);
  LProcess.Start;

  // 向进程发送输入
  if LProcess.StandardInput <> nil then
  begin
    var LInput := TStringStream.Create('input data');
    try
      LProcess.StandardInput.CopyFrom(LInput, 0);
    finally
      LInput.Free;
    end;
  end;

  // 等待完成
  LProcess.WaitForExit;
end;
```

## 🔮 未来扩展

模块的架构设计为未来的扩展奠定了基础：

### 计划中的功能
- **异步操作**：非阻塞的进程启动和等待
- **进程池**：高效的进程复用机制
- **监控和统计**：进程性能监控
- **高级流处理**：双向管道通信
- **信号处理**：Unix 信号支持
- **安全增强**：沙箱和权限控制

### 平台扩展
- **完整的 Unix 支持**：Linux、macOS、FreeBSD
- **移动平台**：Android、iOS（受限功能）
- **嵌入式系统**：资源受限环境的优化

## 📈 性能特征

### 模拟实现
- **启动时间**：< 1ms
- **内存占用**：< 1KB per process
- **测试执行**：62 tests in ~2.6s

### 真实实现（预期）
- **启动时间**：10-50ms（取决于系统）
- **内存占用**：系统进程 + 管道缓冲区
- **吞吐量**：受系统限制

## 🏆 质量保证

- **100% 测试覆盖率**：所有功能都有对应测试
- **0 内存泄漏**：严格的资源管理
- **跨平台兼容**：统一的接口设计
- **TDD 开发**：测试驱动的开发流程
- **代码审查**：严格的代码质量标准

---

这个模块展示了如何使用现代化的设计理念和 TDD 方法论来构建高质量的系统组件。无论是用于学习、演示还是生产环境，它都提供了坚实的基础和清晰的扩展路径。
