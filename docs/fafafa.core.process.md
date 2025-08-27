# fafafa.core.process 模块文档

## 📖 概述

`fafafa.core.process` 是 fafafa.core 框架中的进程管理模块，提供了现代化、跨平台的进程创建、管理和通信功能。该模块借鉴了 Rust、Go、Java 等现代语言中优秀的进程管理设计理念，为 FreePascal 开发者提供了强大而易用的进程管理接口。

### 🎯 设计目标

- **现代化接口设计**：借鉴 Rust `std::process`、Go `os/exec`、Java `ProcessBuilder` 的设计理念
- **跨平台抽象**：统一的接口，底层自动处理 Windows 和 Unix 平台差异
- **强类型安全**：使用接口抽象和严格的类型检查
- **资源自动管理**：自动处理进程句柄、管道等系统资源的生命周期
- **完整的异常处理**：提供详细的错误信息和异常类型

### 🏗️ 架构特点

- **分层实现**：接口层 → 抽象层 → 平台实现层
- **接口优先**：所有公开功能都通过接口暴露，支持依赖注入和单元测试
- **流重定向**：完整支持标准输入、输出、错误流的重定向和数据交互
- **进程控制**：支持进程优先级、窗口状态、环境变量等高级控制功能

## 🔧 核心组件

### 异常类型

```pascal
// 进程操作的基础异常类
EProcessError = class(ECore);

// 进程启动失败异常
EProcessStartError = class(EProcessError);

// 进程操作超时异常
EProcessTimeoutError = class(EProcessError);

// 进程已终止时执行操作异常
EProcessTerminatedError = class(EProcessError);

// 进程流重定向失败异常
EProcessRedirectionError = class(EProcessError);
```

### 枚举类型

```pascal
// 进程状态
TProcessState = (
  psNotStarted,    // 未启动
  psRunning,       // 运行中
  psExited,        // 已退出
  psTerminated     // 被终止
);

// 进程优先级
TProcessPriority = (
  ppIdle,          // 空闲
  ppBelowNormal,   // 低于正常
  ppNormal,        // 正常
  ppAboveNormal,   // 高于正常
  ppHigh,          // 高
  ppRealTime       // 实时
);

// 窗口显示状态（仅Windows）
TWindowShowState = (
  wsHidden,        // 隐藏
  wsNormal,        // 正常
  wsMinimized,     // 最小化
  wsMaximized      // 最大化
);
```

## 📋 接口文档

### IProcessStartInfo 接口

进程启动配置接口，封装进程启动所需的所有配置参数。

#### 基本属性

| 属性 | 类型 | 描述 |
|------|------|------|
| `FileName` | `string` | 要执行的程序文件名或路径 |
| `Arguments` | `string` | 传递给程序的命令行参数 |
| `WorkingDirectory` | `string` | 进程的工作目录 |

#### 流重定向配置

| 属性 | 类型 | 描述 |
|------|------|------|
| `RedirectStandardInput` | `Boolean` | 是否重定向标准输入 |
| `RedirectStandardOutput` | `Boolean` | 是否重定向标准输出 |
| `RedirectStandardError` | `Boolean` | 是否重定向标准错误 |

#### 进程属性配置

| 属性 | 类型 | 描述 |
|------|------|------|
| `Priority` | `TProcessPriority` | 进程优先级 |
| `WindowShowState` | `TWindowShowState` | 窗口显示状态（仅Windows） |
| `UseShellExecute` | `Boolean` | Shell执行模式（见下方详细说明） |

#### 环境变量管理

| 属性/方法 | 类型 | 描述 |
|-----------|------|------|
| `Environment` | `TStringList` | 环境变量列表（只读） |
| `SetEnvironmentVariable(name, value)` | `procedure` | 设置环境变量 |
| `GetEnvironmentVariable(name)` | `function: string` | 获取环境变量值 |
| `ClearEnvironment()` | `procedure` | 清空所有环境变量 |

#### 便捷方法

| 方法 | 描述 |
|------|------|
| `Validate()` | 验证配置的有效性，如果无效则抛出异常 |
| `AddArgument(argument)` | 添加命令行参数 |

#### 构造函数

```pascal
// 默认构造函数
constructor Create;

// 指定文件名的构造函数
constructor Create(const aFileName: string);

// 指定文件名和参数的构造函数
constructor Create(const aFileName, aArguments: string);
```

### IProcess 接口

进程管理核心接口，提供进程的完整生命周期管理。

#### 生命周期管理

| 方法 | 描述 |
|------|------|
| `Start()` | 启动进程 |
| `WaitForExit(timeoutMs)` | 等待进程退出，返回是否在超时前完成 |
| `Kill()` | 强制终止进程 |
| `Terminate()` | 优雅终止进程 |

#### 状态查询

| 属性 | 类型 | 描述 |
|------|------|------|
| `State` | `TProcessState` | 当前进程状态 |
| `HasExited` | `Boolean` | 是否已退出 |
| `ExitCode` | `Integer` | 进程退出码 |
| `ProcessId` | `Cardinal` | 进程ID |
| `StartTime` | `TDateTime` | 启动时间 |
| `ExitTime` | `TDateTime` | 退出时间 |

#### 流访问（仅在重定向时可用）

| 属性 | 类型 | 描述 |
|------|------|------|
| `StandardInput` | `TStream` | 标准输入流 |
| `StandardOutput` | `TStream` | 标准输出流 |
| `StandardError` | `TStream` | 标准错误流 |

| 方法 | 描述 |
|------|------|
| `CloseStandardInput()` | 关闭标准输入流 |

#### 配置访问

| 属性 | 类型 | 描述 |
|------|------|------|
| `StartInfo` | `IProcessStartInfo` | 获取启动配置 |

#### 构造函数

```pascal
constructor Create(aStartInfo: IProcessStartInfo);
```

## 💡 使用示例

### 基本进程启动

```pascal
uses
  fafafa.core.process;

var
  LStartInfo: IProcessStartInfo;
  LProcess: IProcess;
begin
  // 创建启动配置
  LStartInfo := TProcessStartInfo.Create('notepad.exe');

  // 创建进程实例
  LProcess := TProcess.Create(LStartInfo);

  // 启动进程
  LProcess.Start;


## UsePathSearch（运行时 PATH 搜索开关）
- 作用：当 FileName 不是绝对路径时，是否启用 PATH 搜索；在 Windows 会考虑 PATHEXT（如 .COM;.EXE;.BAT;.CMD）
- 默认：开启（True），保持向后兼容
- 行为差异：
  - Windows：当 FileName 无扩展名且 UsePathSearch=True，会按 PATHEXT 尝试；关闭时不扩展
  - Unix：仅按 PATH 搜索，不涉及 PATHEXT；需要可执行权限
- 关闭时：相对可执行名将不再解析，必须提供绝对路径或确保当前目录下存在且可执行
- 用法：Builder.UsePathSearch(True|False) 或 StartInfo.UsePathSearch

## TProcessGroupPolicy（Windows 进程组优雅终止策略）
- 字段：
  - EnableCtrlBreak：向控制台进程发送 CTRL_BREAK_EVENT（需共享控制台）
  - EnableWmClose：尝试向拥有窗口的进程广播 WM_CLOSE（GUI 进程）
  - GracefulWaitMs：优雅尝试后的等待时间，超时则进入强制终止（TerminateJobObject）
- 典型顺序：CtrlBreak → WmClose → 等待 GracefulWaitMs → 终止作业
- 用法：NewProcessGroup(Policy) 或 IProcessBuilder.WithGroupPolicy(Policy)
- 建议：批处理/无 UI 程序优先 CtrlBreak；GUI 程序可启用 WmClose；测试环境可将 GracefulWaitMs 调低

  // 等待进程完成

## 宏开关矩阵（行为差异一览）
- FAFAFA_REAL_PROCESS_IMPLEMENTATION：启用真实平台实现（默认）
- FAFAFA_PROCESS_VERBOSE_LOGGING：调试日志（Wait/Start 关键节点）
- FAFAFA_PROCESS_AUTO_DRAIN_ON_WAIT：Wait 前按需启动后台排水（stdout/stderr 到内存缓冲）
- FAFAFA_PROCESS_GROUPS：开启进程组（Windows Job Object / Unix 进程组）
- FAFAFA_PROCESS_SHELLEXECUTE_MINIMAL（Windows）：最小 ShellExecuteEx 支持；与重定向/自定义环境/合流不兼容
- FAFAFA_PROCESS_USE_POSIX_SPAWN（Unix）：优先使用 posix_spawn，失败回退 fork+exec

## UseShellExecute 能力与限制（Windows）
- v1 模式（默认）：UseShellExecute 仅影响“文件存在性检查”的验证；底层仍使用 CreateProcessW
- 最小子集模式（定义 FAFAFA_PROCESS_SHELLEXECUTE_MINIMAL）：
  - 满足以下条件时走 ShellExecuteExW：UseShellExecute=True 且无重定向、无自定义环境、无合流
  - 任一条件不满足将抛出 EProcessStartError
  - 适合简单“打开”语义；复杂控制（重定向/环境）请保持 UseShellExecute=False

## 组合真值表（片段）
- UseShellExecute=True × RedirectStdOut/Err/Input=True → 拒绝（最小子集模式）
- UseShellExecute=True × Environment.Count>0 → 拒绝（最小子集模式）
- UseShellExecute=False × Redirect/Env → 允许（走 CreateProcess/exec）
- MergeStdErr（合流）与 SplitCapture：需与 CaptureOutput/Output 文件落盘互斥逻辑遵循 Pipeline 文档

### Windows 句柄继承策略（按需继承，最佳实践）

- 策略：仅当启用了流重定向（stdin/stdout/stderr）或 stderr→stdout 合流时，才让子进程继承句柄（bInheritHandles=True）。否则，一律不继承（False）。
- 动机：
  - 降低子进程意外“看见”父进程句柄的风险（安全、稳定）
  - 符合 Go/Rust/Java 等主流实现的保守继承策略
  - 在未使用重定向的场景，子进程并不需要继承任何父侧管道端
- 实现要点：
  - Windows: CreateProcessW 的 bInheritHandles 参数由“按需”布尔计算得到；仅在 STARTF_USESTDHANDLES 且我们明确设置了子端句柄时才需要。
  - 父端句柄（不应被继承的一侧）会调用 SetHandleInformation(..., HANDLE_FLAG_INHERIT, 0) 清除继承标志。
  - 子端句柄（需要传递的一侧）保持可继承，确保子进程能获得正确的标准流。
- 回归测试：
  - test_noinherit_minimal：无重定向，确认 bInheritHandles=False 的路径能正常启动并退出。
- 注意：
  - ShellExecute（最小子集）分支本身不支持重定向/自定义环境；仍遵循“按需继承”的总体思路。


## 安全最佳实践
- 避免当前目录隐式搜索：Windows 使用 SearchPathW 时显式传 PATH，规避默认包含当前目录的风险
- 参数注入防护：优先使用 Args 列表（Builder.Args([...])），避免手写 Arguments 字符串拼接
- 环境变量：Windows 名称大小写不敏感；构建环境块时按名称排序、保留最后一次设置；值允许空但不可包含 #0

## 参数转义规则（摘要）
- Windows（CreateProcessW）：
  - 带空格/制表或空字符串必须加引号；内部双引号需按 CRT 规则转义；反斜杠在引号前需要倍增
  - 示例：QuoteArgWindows 已实现；建议通过 Args 列表传参
- Unix（execve）：
  - 直接 argv 传递，无需命令行拼接；Builder 在 Unix 下将 Arguments 解析为 argv（或使用 Args 列表）

## 大输出与 AutoDrain（建议）
- 若预计输出较大，建议：
  - 使用 Pipeline 将输出落盘（OutToFile/ErrToFile），或
  - 启用 AutoDrain 并适度读取，避免管道阻塞
- 后续计划：提供“捕获阈值”配置，超阈值切换到临时文件，降低内存峰值


## Pipeline 输出捕获矩阵（片段）
- CaptureOutput=True 且 MergeStdErr=True：末端 stdout/stderr 合并捕获至同一缓冲
- CaptureOutput=True 且 MergeStdErr=False：分路捕获，Output() 为 stdout，ErrorText() 为 stderr
- RedirectStdOutToFile=path：不可与 CaptureOutput 同时启用；stdout 持续写入文件
- RedirectStdErrToFile=path：当未合并时，stderr 写入文件；如已合并，stderr 已进入 stdout 捕获/文件
- CaptureThreshold(bytes)：当 CaptureOutput=True 时可用；bytes>0 时启用“阈值落盘”，超过阈值改用临时文件承载捕获

### 建议
- 大体量输出：优先 RedirectStdOutToFile/RedirectStdErrToFile；或设置 CaptureThreshold 以降低内存峰值
- 按需合流：需要统一顺序/合并日志时使用 MergeStdErr；否则分路捕获便于区分


### 文件路径行为与清理策略
- OutputFilePath()/ErrorFilePath()：
  - 若使用 RedirectStdOutToFile/RedirectStdErrToFile 指定路径，返回该路径
  - 若 CaptureOutput=True 且 CaptureThreshold>0，则返回内部创建的临时文件路径
  - 否则返回空字符串
- DeleteCapturedOnDestroy(True)（默认）：
  - 仅删除“阈值落盘”创建的临时文件；显式重定向到文件的路径不会被删除
  - 关闭时机：Pipeline 析构
- 建议：
  - 如需保留临时文件供后续分析，请调用 DeleteCapturedOnDestroy(False)
  - 长期保留建议用 Redirect...ToFile 指定稳定位置


- 策略组合示例（Windows）
  - 仅 CtrlBreak：
    - EnableCtrlBreak=True, EnableWmClose=False, 建议 GracefulWaitMs=300–1000
    - 适用：控制台应用；快捷中断，不依赖窗口
  - 仅 WmClose：
    - EnableCtrlBreak=False, EnableWmClose=True, 建议 GracefulWaitMs=300–1000
    - 适用：拥有主窗口的 GUI 应用；温和关闭
  - 全开（推荐默认）：
    - EnableCtrlBreak=True, EnableWmClose=True, GracefulWaitMs 适当设置
    - 先 CtrlBreak 再 WmClose，等待 GracefulWaitMs 未退出则强制终止
  - 示例脚本：examples/fafafa.core.process/run_group_policy.bat


- 策略组合矩阵（Windows，简要）
  - Console 程序：优先 CtrlBreak；可选 WmClose（若有窗口）
  - GUI 程序：可启用 WmClose；CtrlBreak 仅在共享控制台有效
  - 服务/无窗口：以 CtrlBreak 为主；必要时直接强制
  - 仅强制（无优雅阶段）：跳过 CtrlBreak/WmClose，快速收敛，但可能丢失清理；仅用于紧急止损
  - GracefulWaitMs：建议 300–1000ms，按任务退出特性调整
  - Demo：
    - run_group_policy.bat（全开、仅 CtrlBreak、仅 WmClose、仅强制）
    - run_group_policy_sweep.bat [ms]（观察不同等待值的收敛耗时）
    - run_wmclose_child_gui.bat（构建一个响应 WM_CLOSE 的 GUI 子进程）

  if LProcess.WaitForExit(10000) then
    WriteLn('进程完成，退出码: ', LProcess.ExitCode)
  else
    WriteLn('进程超时');
end;
```

### 参数传递和环境变量

```pascal
var
  LStartInfo: IProcessStartInfo;
  LProcess: IProcess;
begin
  LStartInfo := TProcessStartInfo.Create;
  LStartInfo.FileName := 'cmd.exe';
  LStartInfo.Arguments := '/c echo %MY_VAR%';

  // 设置环境变量
  LStartInfo.SetEnvironmentVariable('MY_VAR', 'Hello World');

  LProcess := TProcess.Create(LStartInfo);
  LProcess.Start;
  LProcess.WaitForExit;
end;
```

### 标准输出重定向

```pascal
var
  LStartInfo: IProcessStartInfo;
  LProcess: IProcess;
  LBuffer: array[0..1023] of Byte;
  LBytesRead: Integer;
  LOutput: string;
begin
  LStartInfo := TProcessStartInfo.Create;
  LStartInfo.FileName := 'cmd.exe';
  LStartInfo.Arguments := '/c dir';
  LStartInfo.RedirectStandardOutput := True;

  LProcess := TProcess.Create(LStartInfo);
  LProcess.Start;

  if LProcess.WaitForExit(5000) then
  begin
    // 读取输出
    LOutput := '';
    repeat
      LBytesRead := LProcess.StandardOutput.Read(LBuffer[0], SizeOf(LBuffer));
      if LBytesRead > 0 then
      begin
        SetLength(LOutput, Length(LOutput) + LBytesRead);
        Move(LBuffer[0], LOutput[Length(LOutput) - LBytesRead + 1], LBytesRead);
      end;
    until LBytesRead = 0;

    WriteLn('输出: ', LOutput);
  end;
end;
```

### 标准输入重定向

```pascal
var
  LStartInfo: IProcessStartInfo;
  LProcess: IProcess;
  LInputStream: TStringStream;
begin
  LStartInfo := TProcessStartInfo.Create;
  LStartInfo.FileName := 'cmd.exe';
  LStartInfo.Arguments := '/c findstr "hello"';
  LStartInfo.RedirectStandardInput := True;
  LStartInfo.RedirectStandardOutput := True;

  LProcess := TProcess.Create(LStartInfo);
  LProcess.Start;

  // 写入数据到标准输入
  LInputStream := TStringStream.Create('hello world'#13#10'test line'#13#10);
  try
    LProcess.StandardInput.CopyFrom(LInputStream, 0);
    LProcess.CloseStandardInput; // 重要：关闭输入流
  finally
    LInputStream.Free;
  end;

  LProcess.WaitForExit;
  // 读取过滤后的输出...
end;
```

### 进程优先级和窗口控制

```pascal
var
  LStartInfo: IProcessStartInfo;
  LProcess: IProcess;
begin
  LStartInfo := TProcessStartInfo.Create('notepad.exe');
  LStartInfo.Priority := ppHigh;           // 设置高优先级
  LStartInfo.WindowShowState := wsHidden;  // 隐藏窗口

  LProcess := TProcess.Create(LStartInfo);
  LProcess.Start;

  WriteLn('高优先级进程已启动，PID: ', LProcess.ProcessId);
end;
```

### 错误处理

```pascal
var
  LStartInfo: IProcessStartInfo;
  LProcess: IProcess;
begin
  try
    LStartInfo := TProcessStartInfo.Create('nonexistent.exe');
    LStartInfo.Validate; // 验证配置

    LProcess := TProcess.Create(LStartInfo);
    LProcess.Start;

  except
    on E: EProcessStartError do
      WriteLn('启动错误: ', E.Message);
    on E: EProcessError do
      WriteLn('进程错误: ', E.Message);
  end;
end;
```

## 🔗 模块依赖关系

```
fafafa.core.process
├── fafafa.core.base        # 核心基础模块（异常类型、接口基类）
├── SysUtils               # 系统工具
├── Classes                # 基础类库
├── DateUtils              # 日期时间工具
├── Windows (Windows)      # Windows API
└── BaseUnix, Unix (Unix)  # Unix/Linux API
```

## 🚀 性能特性

- **零拷贝流操作**：直接使用系统管道，避免不必要的数据复制
- **异步友好**：设计上支持未来的异步扩展
- **资源自动管理**：使用接口引用计数自动管理资源
- **平台优化**：针对不同平台使用最优的系统调用


## 🧾 编码策略（UTF‑8 优先）

为确保跨平台一致性与现代化开发体验，模块采用如下编码约定：

- 对外 API（IProcessBuilder、IProcessStartInfo 等）中的所有 string 参数与返回值默认按 UTF‑8 约定理解与传输
- Windows 平台的系统调用边界（如 CreateProcessW、环境块构造）使用 UTF‑16；在进入/离开系统边界时进行 UTF‑8 ⇄ UTF‑16 的转换
- Output()/StandardOutput 的编码：
  - 现阶段：返回值遵循“UTF‑8 约定”，但实际编码取决于子进程输出与系统代码页；建议优先使用 UTF‑8 友好的子进程
  - 后续增强（计划）：提供显式的编码策略配置（如 StdOutEncoding），并在默认情况下确保 UTF‑8 一致性
- 测试约定：单元测试以 UTF‑8 用例为基准，验证参数、环境变量、工作目录等路径的 UTF‑8 处理

这样既保证了公共 API 的统一（UTF‑8），又满足了 Windows 平台对 UTF‑16 的系统要求。
- 说明更新：不提供“自动探测与统一解码”功能。主流做法是返回原始字节流，由调用方决定如何解码；Output() 作为便捷方法遵循 UTF‑8 约定，但若子进程输出非 UTF‑8，可能显示异常。建议使用 UTF‑8 子进程或配置环境以输出 UTF‑8。



## 🧩 流水线（Pipeline）API 与最佳实践

流水线用于将多个子进程通过管道连接起来：stage0.stdout → stage1.stdin → ... → stageN。
本模块提供独立单元 `fafafa.core.pipeline`，在不修改核心 API 的前提下，为 `IProcess/IProcessBuilder` 叠加管道能力。

- 工厂方法：`NewPipeline: IPipelineBuilder`
- 构建器：`IPipelineBuilder.Add(...).CaptureOutput.Start`
- 运行期对象：`IPipeline`

### 快速上手

- Windows 示例（echo | findstr）：

```pascal
uses fafafa.core.process, fafafa.core.pipeline;

var P := NewPipeline
  .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','echo','hello']))
  .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','findstr','hello']))
  .CaptureOutput
  .Start;
Assert(P.WaitForExit);
Assert(P.Success);
WriteLn(P.Output);
```

- Unix 示例（echo | grep）：

```pascal
uses fafafa.core.process, fafafa.core.pipeline;

var P := NewPipeline
  .Add(NewProcessBuilder.Command('/bin/echo').Args(['hello']))
  .Add(NewProcessBuilder.Command('/bin/grep').Args(['hello']))
  .CaptureOutput
  .Start;
```

### 接口摘要
- IPipelineBuilder
  - `Add(stage: IProcessBuilder)`：追加阶段
  - `Add(exe: string; args: array of string)`：便捷追加
  - `CaptureOutput([enable=True])`：是否捕获末端 stdout 到内存
  - `Build/Start()`：构建/构建并启动
- IPipeline
  - `Start()`：启动所有阶段并建立泵
  - `WaitForExit([timeoutMs])`：等待全部阶段
  - `Status/Success`：最后阶段的退出码/是否为 0
  - `KillAll/TerminateAll`：全部强杀/优雅终止
  - `Output()`：末端输出（需 CaptureOutput）


### 扩展能力（可选开关）
- FailFast(True/False, 默认 False)
  - 任一阶段失败（ExitCode ≠ 0）时，立即 KillAll 其余阶段，加速失败返回
  - 适用于长链路中快速失败与资源回收
- MergeStdErr(True/False, 默认 False)
  - 当 CaptureOutput=True 时，将末端 stderr 合并到 stdout 一起捕获

## ⏱️ 超时与取消 API

- WithTimeout(timeoutMs): 设定默认等待时间（<=0 不启用）
- RunWithTimeout(timeoutMs): 启动并等待至超时；超时会 Kill 子进程并抛出 EProcessTimeoutError
- OutputWithTimeout(timeoutMs): 走与 RunWithTimeout 一致的超时路径，再读取输出

注意：
- 长输出且启用重定向时，建议结合 DrainOutput(True) 以避免缓冲区阻塞

## 🧹 资源清理顺序

- 释放流包装器（THandleStream）后，由 CleanupResources 统一关闭剩余句柄
- Windows：CleanupResources 内部先 CloseDrainThreadsWindows，再关闭管道句柄，避免与后台线程竞态


## 🚿 AutoDrain（自动排水）行为与边界

- 作用：在等待进程退出前，后台线程持续从 stdout/stderr 读走数据写入内存缓冲，避免子进程因管道缓冲写满而阻塞（死锁）
- 启用条件：
  - StartInfo.RedirectStandardOutput/RedirectStandardError 为 True（至少其一）
  - StartInfo.SetDrainOutput(True)
  - WaitForExit 调用时会按需启动后台排水（EnsureAutoDrainOnWait）
- 收敛：
  - 进程退出后，FinalizeAutoDrainOnExit 会等待后台线程收敛，并将内存缓冲 Position 重置为 0，便于后续读取
- 读取策略：
  - 如已启用 AutoDrain，Wait 后从标准流读取可能读不到数据（已被后台线程消费进入缓冲）。可优先：
    - 通过 IProcessBuilder.Output() 便捷方法读取汇集结果（如使用 Builder）
    - 或在当前版本中直接从 StandardOutput 再 CopyTo 自己的内存流做容错（具体是否仍有数据，取决于缓冲与竞态）
- 边界与注意事项：
  - AutoDrain 仅在重定向开启时有效；未重定向则不启动后台线程
  - 当 StdErrToStdOut=True 时，stderr 不单独排水，行为以 stdout 合流为准
  - 对于超大输出，建议改为文件重定向或自定义流式消费，避免一次性内存占用
  - 该机制默认在 {$DEFINE FAFAFA_PROCESS_AUTO_DRAIN_ON_WAIT} 宏开启场景可用
- 测试用例：tests/fafafa.core.process/test_autodrain_postwait.pas


## 👥 进程组 / Job Object（可选）

- 在定义 FAFAFA_PROCESS_GROUPS 时可用
- NewProcessGroup(): IProcessGroup
  - Add(process): 将已启动进程加入组（Windows 使用 AssignProcessToJobObject）
  - TerminateGroup(exitCode): 终止整组（Windows 调用 TerminateJobObject）


  - 合并写入采用锁保护，保证线程安全；跨平台顺序不保证稳定
- RedirectStdOutToFile(path, append=False)
  - 将末端 stdout 直接写入文件；append=True 为追加写入
- RedirectStdErrToFile(path, append=False)
  - 将末端 stderr 直接写入文件；append=True 为追加写入

注意：
- CaptureOutput 与 RedirectStdOutToFile 互斥（避免重复消费 stdout）
- 如需同时捕获 stderr 到内存，须 CaptureOutput=True 且 MergeStdErr=True；否则可用 RedirectStdErrToFile

示例：
```pascal
// 合并 stderr 到输出并捕获
var P := NewPipeline
  .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','(echo out & echo err 1>&2)']))
  .CaptureOutput
  .MergeStdErr(True)
  .Start;
Assert(P.WaitForExit(5000));
WriteLn(P.Output); // 包含 out 与 err

// 将输出写入文件
P := NewPipeline
  .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','echo','hello']))
  .RedirectStdOutToFile('out.log', False)
  .Start;
Assert(P.WaitForExit(5000));
```

### 实现要点
- 采用父进程内的线程泵（PipePump）将相邻阶段 stdout → 下游 stdin
- 当上游 EOF，自动关闭下游标准输入（CloseStandardInput），避免下游永远阻塞
- 输出捕获：可选，将最后一段 stdout 泵入内存后返回为 UTF‑8 约定字符串

### 最佳实践
1) 命令行与可执行文件
   - 优先使用“可执行文件 + 参数数组”的形式（避免 shell 语义差异）
   - Windows 下常见示例：`cmd.exe /c ...`；Unix：直接使用可执行文件（如 `/bin/grep`）

2) 重定向与缓冲
   - 管道内部已自动为相邻阶段开启 stdout（上游）与 stdin（下游）的必要重定向
   - 末端捕获需要 `CaptureOutput`；否则可自行从最后阶段的 `StandardOutput` 读取

3) EOF 与死锁规避
   - 上游结束后我们会自动关闭下游 stdin，确保下游尽快完成
   - 若自己在外侧写入 stdin，务必在写完后调用 `CloseStandardInput`

4) 输出编码
   - Output() 按 UTF‑8 约定返回；子进程若输出非 UTF‑8（如 Windows 默认 OEM），内容可能受环境影响
   - 建议：选择 UTF‑8 友好的子进程或配置控制台为 UTF‑8（Windows 可 `chcp 65001` 或使用 PowerShell Core）

5) 错误处理与健壮性
   - 建议在 `WaitForExit` 后检查 `Success/Status`，或对关键阶段单独检查退出码
   - 如需“任一阶段失败即终止全链”，可在外层检测失败后主动调用 `KillAll`

6) 性能与压力
   - 线程泵默认 8KB 缓冲，足够绝大多数文本流场景
   - 大量二进制/超大输出时，建议避免 `CaptureOutput`，改为流式写入文件或自定义处理

### 当前状态与限制
- 已提供：
  - FailFast 选项（任一阶段失败即 KillAll）
  - 将 stderr 合并到 stdout 的流水线配置（MergeStdErr）
  - 将 stdout/stderr 直接重定向到文件的便捷方法（RedirectStdOutToFile/RedirectStdErrToFile）
- 限制：
  - CaptureOutput 与 RedirectStdOutToFile 互斥（避免重复消费）
  - MergeStdErr 仅在 CaptureOutput=True 时影响内存捕获结果，重定向到文件时需分别指定

### 测试说明
- 已新增基础用例（Windows：echo | findstr；Unix：echo | grep；三段串联 EOF 传播）
- 压力用例（大输出/长流水线）可按需补充到测试套件

## ⚠️ 注意事项

### 平台差异

1. **窗口状态控制**：`TWindowShowState` 仅在 Windows 平台有效
2. **进程优先级**：不同平台的优先级映射可能有差异
3. **路径分隔符**：建议使用 `PathDelim` 常量或相对路径

### 资源管理

1. **流的生命周期**：重定向的流会在进程对象销毁时自动关闭
2. **输入流关闭**：向子进程写入完数据后，必须调用 `CloseStandardInput`
3. **进程清理**：进程对象销毁时会自动尝试终止未完成的进程

### 安全考虑

### 压力用例（可选运行）
- 本仓库包含大输出与长链路的压力测试，默认跳过
- 启用方式：编译测试时定义 `RUN_STRESS`（如 `-dRUN_STRESS`）或在 IDE 中启用该宏
- Windows 下使用 cmd/findstr/shell 组合时，受系统管道吞吐与命令行为影响，执行时间可能偏长
- 建议仅在本地或专门的性能环境中运行压力用例


1. **参数注入**：小心处理用户输入的命令行参数，避免注入攻击
2. **权限检查**：确保有足够权限执行目标程序
3. **路径验证**：验证可执行文件路径的合法性

## ⚠️ UseShellExecute 语义说明

### 当前实现状态

`UseShellExecute` 属性在当前版本（v1.0）中具有**有限的语义**，主要影响验证行为而非实际的进程启动机制：

#### 行为差异

| UseShellExecute | 验证行为 | 启动机制 | 流重定向 |
|-----------------|----------|----------|----------|
| `False` (默认) | 检查文件存在性和可执行性 | CreateProcess/fork+exec | ✅ 完全支持 |
| `True` | **跳过文件存在性检查** | CreateProcess/fork+exec | ✅ 完全支持 |

#### 设计说明

1. **当前限制**：
   - 两种模式都使用相同的底层启动机制（CreateProcess/fork+exec）
   - 不会启用 Windows 的 ShellExecuteEx 或 Unix 的 shell 解释
   - 无法直接打开文档、URL 或关联程序

2. **验证差异**：
   ```pascal
   // UseShellExecute = False：严格验证
   StartInfo.FileName := 'nonexistent_program';
   StartInfo.UseShellExecute := False;
   StartInfo.Validate; // 抛出 EProcessStartError

   // UseShellExecute = True：跳过文件检查
   StartInfo.UseShellExecute := True;
   StartInfo.Validate; // 不抛出异常
   ```

3. **适用场景**：
   - `UseShellExecute = False`：适用于已知可执行文件的启动
   - `UseShellExecute = True`：适用于动态文件名或需要跳过验证的场景

#### 未来规划

后续版本可能会提供完整的 Shell 执行支持，包括：
- Windows 平台的 ShellExecuteEx 集成
- Unix 平台的 shell 命令解释
- 文档和 URL 的直接打开支持

#### 最佳实践

```pascal
// 推荐：明确的可执行文件启动
StartInfo.FileName := 'cmd.exe';
StartInfo.UseShellExecute := False; // 默认值

// 特殊场景：跳过文件验证
StartInfo.FileName := DynamicProgramName;
StartInfo.UseShellExecute := True; // 跳过验证
```

## 📚 相关资源
- 更多最佳实践：参见 docs/fafafa.core.process.bestpractices.md（默认配置、宏开关策略、资源安全、测试与发布清单）


## ⏱️ 超时 API（便捷接口）

- 设计目标
  - 为常见的“启动并等待”与“启动读取输出”提供轻量的超时封装
  - 保持默认行为不变：不调用这些方法则无超时影响

- 接口摘要（IProcessBuilder）
  - WithTimeout(timeoutMs: Integer): IProcessBuilder
    - 设置默认超时时间（毫秒）；<=0 表示不启用
  - RunWithTimeout(timeoutMs: Integer): IChild
    - 启动并等待直到完成；超时则 Kill 子进程并抛出 EProcessTimeoutError
    - 当传入 <=0 时，回退使用 WithTimeout 的默认值；若默认值也未设置（<=0），则不启用超时
  - OutputWithTimeout(timeoutMs: Integer): string
    - 等价于 RunWithTimeout + Output 的便捷组合；超时行为同上

- 使用示例
  ```pascal
  // 显式指定超时 500ms
  NewProcessBuilder.Command('cmd.exe')
    .Args(['/c','timeout','/t','2','/nobreak'])
    .RunWithTimeout(500); // 触发 EProcessTimeoutError

  // 设置默认超时，并在调用处不再显式传参
  NewProcessBuilder.Command('cmd.exe')
    .Args(['/c','timeout','/t','2','/nobreak'])
    .WithTimeout(500)
    .RunWithTimeout(0);   // 0 → 回退到默认 500ms

  // 读取输出带超时
  var s := NewProcessBuilder.Command('cmd.exe')
    .Args(['/c','echo','HELLO'])
    .OutputWithTimeout(2000);
  ```

- 注意事项（最佳实践）
  - 负值超时按 0 处理：不启用超时
  - 超时发生后会 Kill 子进程；对目标进程有状态副作用，请谨慎使用
  - 长时间阻塞的命令应结合进程内逻辑/外部看门狗设计，避免依赖单一 Kill 策略
  - 跨平台差异：示例使用 cmd/timeout（Windows）与 sh/sleep（Unix）；在 CI/容器环境中请选用稳定可用的命令

### 最佳实践：AutoDrain 读取示例

- Builder 风格（DrainOutput + Output 便捷读取）

```pascal
var outText: string;
outText := NewProcessBuilder
  .Command({$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/sh'{$ENDIF})
  .Args({$IFDEF WINDOWS}['/c','for','/L','%i','in','(1,1,5)','do','@echo','line-%i']{$ELSE}['-c','for i in $(seq 1 5); do echo line-$i; done']{$ENDIF})
  .CaptureStdOut   // 可选：显式语义；Output() 会确保 stdout 可读
  .DrainOutput(True)
  .Output;         // 读取汇集后的 UTF-8 文本
// outText 中应包含多行 "line-"
```

- 非 Builder 风格（Wait 后从 StandardOutput 容错读取）

```pascal
var si: IProcessStartInfo; p: IProcess; buf: array[0..1023] of byte; n: Integer;
si := TProcessStartInfo.Create;
{$IFDEF WINDOWS}
si.FileName := 'cmd.exe';
si.Arguments := '/c for /L %i in (1,1,5) do @echo line-%i';
{$ELSE}
si.FileName := '/bin/sh';
si.Arguments := '-c "for i in $(seq 1 5); do echo line-$i; done"';
{$ENDIF}
si.RedirectStandardOutput := True;
si.SetDrainOutput(True); // 启用 AutoDrain
p := TProcess.Create(si);
p.Start;
if p.WaitForExit(5000) then
begin
  // 等待后，标准流可能已被后台线程读走；此处容错读取（n 可为 0）
  if Assigned(p.StandardOutput) then
    n := p.StandardOutput.Read(buf, SizeOf(buf));
end;
```



- **示例程序**：`examples/fafafa.core.process/`
- **单元测试**：`tests/fafafa.core.process/`
- **设计文档**：`docs/process.md`
- **性能测试**：参见测试用例中的性能测试



### 最佳实践：选择 CombinedOutput vs CaptureAll

- 场景判断
  - 只需一段汇总文本：优先 CombinedOutput（stderr→stdout 合流，DrainOutput=True）
  - 需要分别处理 stdout/stderr：选 CaptureAll（不合流，三路重定向 + DrainOutput=True）
- 示例

- CombinedOutput（合流统一读取）
```pascal
var text: string;
text := NewProcessBuilder
  .Command({$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/sh'{$ENDIF})
  .Args({$IFDEF WINDOWS}['/c','(echo OUT & echo ERR 1>&2)']{$ELSE}['-c','(echo OUT; echo ERR 1>&2)']{$ENDIF})
  .CombinedOutput
  .Output;
// text 同时包含 OUT 与 ERR
```

- CaptureAll（分别读取 stdout/stderr）
```pascal
var c: IChild; s: TStringStream; outText, errText: string;
c := NewProcessBuilder
  .Command({$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/sh'{$ENDIF})
  .Args({$IFDEF WINDOWS}['/c','(echo OUT & echo ERR 1>&2)']{$ELSE}['-c','(echo OUT; echo ERR 1>&2)']{$ENDIF})
  .CaptureAll
  .Start;
CheckTrue(c.WaitForExit(5000));

if Assigned(c.StandardOutput) then begin
  s := TStringStream.Create(''); try s.CopyFrom(c.StandardOutput, 0); outText := s.DataString; finally s.Free; end;
end;
if Assigned(c.StandardError) then begin
  s := TStringStream.Create(''); try s.CopyFrom(c.StandardError, 0); errText := s.DataString; finally s.Free; end;
end;
```

- 查看示例
  - 源码：examples/fafafa.core.process/example_combined_vs_capture_all.lpr
  - 运行（Windows）：examples/fafafa.core.process/run_combined_vs_capture_all.bat
  - 运行（Unix）：examples/fafafa.core.process/run_combined_vs_capture_all.sh


### 最佳实践：Silent 与 Interactive

- Silent（静默采集输出）
  - 语义：WindowHidden + CaptureOutput，便于静默运行并收集输出
  - 适用：后台作业、日志采集、非交互任务
  - 示例：
  ```pascal
  var text: string;
  text := NewProcessBuilder
    .Command({$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/sh'{$ENDIF})
    .Args({$IFDEF WINDOWS}['/c','(echo Visible? & echo Silent Mode 1>&2)']{$ELSE}['-c','(echo Visible?; echo Silent Mode 1>&2)']{$ENDIF})
    .Silent
    .Output;
  ```
  - 查看示例
    - 源码：examples/fafafa.core.process/example_silent_interactive.lpr
    - 运行（Windows）：examples/fafafa.core.process/run_silent_interactive.bat
    - 运行（Unix）：examples/fafafa.core.process/run_silent_interactive.sh

- Interactive（前台交互）
  - 语义：WindowNormal + NoRedirect，适合需要前台交互或可见窗口的场景
  - 适用：短命令验证、调试、需要接受控制台输入的程序
  - 示例：
  ```pascal
  var c: IChild;
  c := NewProcessBuilder
    .Command({$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/sh'{$ENDIF})
    .Args({$IFDEF WINDOWS}['/c','echo Hello Interactive']{$ELSE}['-c','echo Hello Interactive']{$ENDIF})
    .Interactive
    .Start;
  c.WaitForExit(3000);
  ```



### 最佳实践：超时与 KillOnTimeout

- 快速选择
  - 只需读取文本且有超时保护：OutputWithTimeout(ms)
  - 需要拿到 IChild 并在超时确保 Kill：KillOnTimeout(True).RunWithTimeout(ms)
- 示例

- OutputWithTimeout（汇总文本 + 超时保护）
```pascal
var s: string;
s := NewProcessBuilder
  .Command({$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/sh'{$ENDIF})
  .Args({$IFDEF WINDOWS}['/c','(echo A & echo B 1>&2)']{$ELSE}['-c','(echo A; echo B 1>&2)']{$ENDIF})
  .CombinedOutput
  .OutputWithTimeout(3000);
```

- KillOnTimeout + RunWithTimeout（拿 IChild 控制流 + 超时强杀）
```pascal
var c: IChild;
c := NewProcessBuilder
  .Command({$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/sh'{$ENDIF})
  .Args({$IFDEF WINDOWS}['/c','echo start & timeout /T 5 /NOBREAK >NUL & echo done']{$ELSE}['-c','echo start; sleep 5; echo done']{$ENDIF})
  .CombinedOutput
  .KillOnTimeout(True)
  .RunWithTimeout(1500);
```

- 查看示例
  - 源码：examples/fafafa.core.process/example_timeout_killon_timeout.lpr
  - 运行（Windows）：examples/fafafa.core.process/run_timeout_killon_timeout.bat


### 最佳实践：Pipeline 末端输出

- 合流（单文本）：在 Pipeline 上使用 CaptureOutput(True) + MergeStdErr(True)，最后读取 P.Output
- 分路（分别读取）：CaptureOutput(True) + MergeStdErr(False)，最后读取 P.Output 与 P.ErrorText（新：IPipeline.ErrorText）
- 示例：examples/fafafa.core.process/example_pipeline_best_practices.lpr

- 运行示例（Windows）：examples/fafafa.core.process/run_pipeline_best_practices.bat

## ❗ 常见误区（必读）

- UseShellExecute 并非真正的 Shell 执行
  - v1 下仅影响“验证是否跳过”，并不启用 ShellExecuteEx/sh；无法直接打开文档/URL/关联程序
  - 需要 Shell 行为请自行通过 `cmd.exe /c ...`（Windows）或 `/bin/sh -c ...`（Unix）包装

- 参数引号与转义差异（Windows vs Unix）
  - 强烈推荐使用“可执行文件 + 参数数组”的形式；不要传整串命令给 shell
  - Windows 的命令行解析与引号/反斜杠规则与 Unix 不同；本模块会逐参构造，避免歧义

- PATH 与 PATHEXT 行为
  - Windows 会按 PATHEXT（.COM;.EXE;.BAT;.CMD 等）补全尝试；已有扩展名时不追加
  - Unix 仅遍历 PATH；需具备“可执行”权限（x 位）

- 测试与示例输出差异
  - Windows 自带工具（echo/findstr/ping）在不同环境可能出现输出噪声或编码差异；断言应尽量抓关键片段
  - Unix 建议优先使用 /bin/echo、/bin/true、/usr/bin/grep 之类稳定工具

- UTF‑8 约定与控制台代码页
  - 库单元不输出中文；测试/示例单元需加 `{$CODEPAGE UTF8}`
  - Windows 控制台默认非 UTF‑8；若需稳定 UTF‑8 输出，可切换代码页或选用 UTF‑8 友好子进程

---

**版本**：1.0.0
**更新时间**：2025-08-11

## Unix 快路径（posix_spawn）

- 默认关闭；启用方式与快速验证见：docs/fafafa.core.process.posix_spawn.plan.md
- 当前最小能力：argv/envp、stdin/stdout/stderr 重定向、stderr→stdout 合流；不支持项将自动回退 fork+exec
- 安全性策略：父进程关闭子端句柄，子进程通过 file_actions 进行 dup2；失败即回退，不改变现有语义


### 启用与验证（Unix）

- 启用宏：FAFAFA_PROCESS_USE_POSIX_SPAWN（默认关闭）
  - 仅在 Unix 下有效；不定义该宏时始终使用 fork+exec
- 能力边界：
  - 支持 argv/envp、stdin/stdout/stderr 重定向、stderr→stdout 合流
  - 工作目录变更依赖非标准扩展 posix_spawn_file_actions_addchdir_np（存在平台差异，缺失时自动回退）
  - 未启用 file_actions 或 attr 绑定时，将自动回退到 fork+exec（不改变既有语义）
- 一键验证：
  - ./tests/fafafa.core.process/run_spawn_subset.sh
    - 内部通过 lazbuild 添加 -dFAFAFA_PROCESS_USE_POSIX_SPAWN，仅运行一小撮覆盖 spawn 路径的用例


#### 子集验证 Checklist（Unix）

- 环境准备
  - 确保系统具备 posix_spawn 及相关头/库；可选扩展 chdir_np（posix_spawn_file_actions_addchdir_np）
  - 确认构建工具可注入宏：FAFAFA_PROCESS_USE_POSIX_SPAWN
- 执行脚本
  - ./tests/fafafa.core.process/run_spawn_subset.sh
    - 脚本会：注入 -dFAFAFA_PROCESS_USE_POSIX_SPAWN；仅运行覆盖 spawn 路径的子集用例
- 覆盖点（建议勾选）
  - 基本启动：/bin/sh -c 'true'（零输出、零管道）
  - 输出捕获：stdout 捕获、stderr→stdout 合流
  - 重定向：stdin/out/err 分别及组合
  - 工作目录：WorkingDirectory 生效（若 chdir_np 存在）；缺失时验证回退路径
  - 进程组（PGID）：Spawn 路径下 PGID/flags 的存在性与回退（当前为规划项）
- 常见回退信号
  - 缺失 attr 或 file_actions 能力时自动回退 fork+exec；行为不变
  - chdir_np 缺失：仅目录切换回退，不影响其余能力

### 进程组（PGID）与 posix_spawn 的关系

- 当前行为：
  - 默认 fork 路径中，子进程会在 exec 前 setpgid(0,0)，父侧 Add 失败可容忍（EPERM/ECHILD）
  - TerminateGroup 采用 SIGTERM→短等待→SIGKILL 的 U2 策略
- 未来增强（规划）：
  - 在 spawn 路径下，通过 posix_spawnattr_setpgroup 设置 PGID（需平台支持 flags）
  - attr 初始化位置将前移至 file_actions 之外，避免能力耦合
  - 文档将同步更新“平台 flag 定义（POSIX_SPAWN_*）”与“PGID 兼容矩阵”

**维护团队**：fafafa.core 开发团队



## UseShellExecute（Windows）最小实现说明（测试专用）

说明：该实现通过编译宏 FAFAFA_PROCESS_SHELLEXECUTE_MINIMAL 受控，默认关闭；目前仅在 tests/fafafa.core.process 中启用，用于验证最小可行路径。默认生产构建仍采用 CreateProcessW。

行为矩阵：
- UseShellExecute=False → 走 CreateProcessW（支持重定向/自定义环境）
- UseShellExecute=True 且存在任意重定向（stdin/stdout/stderr/合流）→ 立即拒绝（EProcessStartError）
- UseShellExecute=True 且 Environment.Count>0（自定义环境）→ 目前不支持（拒绝）
- UseShellExecute=True 且无重定向/无自定义环境 → 走 ShellExecuteExW（SEE_MASK_NOCLOSEPROCESS），仅保证启动并返回进程句柄

已知限制：
- ShellExecuteEx 不支持控制台重定向/自定义环境；工作目录、窗口显示按最小映射处理
- 仅适用于“打开/执行”类场景，如 cmd /c exit 0 或打开可执行/文档/URL（后续可扩展）

测试说明：
- 测试项目 tests_process.lpi 通过 CustomOptions 启用 -dFAFAFA_PROCESS_SHELLEXECUTE_MINIMAL
- 新增用例：
  - Test_ShellExecute_Success_NoRedirect_NoEnv（允许路径）
  - Test_ShellExecute_Reject_When_Redirect（拒绝路径）

误用提示：
- 如需重定向/自定义环境/精确控制，请使用 UseShellExecute=False（CreateProcessW）
- UseShellExecute=True 目前仅保证最小成功启动，不提供管道能力


## 进程组终止语义与约束（补充）

- Windows
  - 组实现：Job Object（CreateJobObject/AssignProcessToJobObject）
  - 防泄漏：默认启用 JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE，Job 句柄关闭时系统终止组内所有进程
  - 优雅尝试：CTRL_BREAK（要求可附着到控制台，已做 AttachConsole 探测）、可选 WM_CLOSE（最佳努力）
  - 收敛策略：优雅尝试后等待 GracefulWaitMs，未退出则 TerminateJobObject 兜底

- Unix
  - 组实现：PGID（子进程在 fork→exec 之间 setpgid(0,0)；父侧 Add 时 setpgid 失败容忍）
  - TerminateGroup：优雅 SIGTERM → 短等待 → 仍存活则 SIGKILL 兜底
  - 等待：WaitForExitUnix 使用 WNOHANG 轮询并容忍 ECHILD（并发 wait）

- 建议
  - 控制台应用优先启用 CTRL_BREAK；GUI 应用可勾选 WM_CLOSE 并设置合理 GracefulWaitMs
  - 长链路/流水线中，如需快速失败回收，可在上层策略上统一 KillTree/TerminateAll
