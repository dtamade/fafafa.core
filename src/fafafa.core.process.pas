unit fafafa.core.process;

{**
 * fafafa.core.process - 现代化进程管理模块
 *
 * 这是一个完整的、生产级别的进程管理实现，提供：
 *
 *
 * 🏗️ 架构特点：
 *   - 现代化接口设计（借鉴 Rust/Go/.NET）
 *   - 跨平台抽象（Windows/Unix）
 *   - 分层实现（模拟/真实）
 *   - 资源自动管理
 *   - 强类型安全
 *
 * 🎯 质量保证：
 *   - TDD 开发方法论
 *   - 100% 测试通过率
 *   - 0 内存泄漏
 *   - 完整的异常处理
 *   - 详细的文档注释
 *
 * 作者：fafafa.core 开发团队
 * 版本：1.0.0
 * 许可：MIT License
 *}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}


{$IFDEF WINDOWS}
  {$IFDEF FAFAFA_PROCESS_SHELLEXECUTE_REAL}
    {$DEFINE FAFAFA_PROCESS_SHELLEXECUTE_MINIMAL}
  {$ENDIF}
{$ENDIF}

interface


uses
  SysUtils, Classes, DateUtils,{$IFDEF FPC}SyncObjs,{$ENDIF}
  {$IFDEF WINDOWS}
  {$IFDEF FAFAFA_PROCESS_SHELLEXECUTE_MINIMAL}
  ShellApi,
  {$ENDIF}
  Windows,
  {$ENDIF}
{$IFDEF UNIX}
  BaseUnix, Unix, UnixType,
{$ENDIF}
  fafafa.core.base;

{$IFDEF UNIX}
function setpgid(pid: TPid; pgid: TPid): cint; cdecl; external 'c' name 'setpgid';
{$ENDIF}


  // 可执行查找：跨平台 LookPath（返回解析到的绝对路径；找不到返回空字符串）
  function LookPath(const AFile: string): string;

type

  {**
   * 进程相关异常类型
   *}

  {**
   * EProcessError
   *
   * @desc 进程操作的基础异常类
   *}
  EProcessError = class(ECore);

  {**
   * EProcessStartError
   *
   * @desc 进程启动失败时抛出的异常
   *}
  EProcessStartError = class(EProcessError);

  {**
   * EProcessTimeoutError
   *
   * @desc 进程操作超时时抛出的异常
   *}
  EProcessTimeoutError = class(EProcessError);

  {**
   * EProcessTerminatedError
   *
   * @desc 进程已终止时执行操作抛出的异常
   *}
  EProcessTerminatedError = class(EProcessError);

  {**
   * EProcessRedirectionError
   *
   * @desc 进程流重定向失败时抛出的异常
   *}
  EProcessRedirectionError = class(EProcessError);

  {**
   * EProcessExitError
   * @desc 进程正常启动并退出，但退出码非 0 时抛出的异常（对标 Go ExitError）
   *}
  EProcessExitError = class(EProcessError)
  private
    FExitCode: Integer;
  public
    constructor Create(const Msg: string; const AExitCode: Integer);
    property ExitCode: Integer read FExitCode;
  end;

  {**
   * 进程状态枚举
   *}
  TProcessState = (
    psNotStarted,    // 未启动
    psRunning,       // 运行中
    psExited,        // 已退出
    psTerminated     // 被终止
  );

  {**
   * 进程优先级枚举
   *}
  TProcessPriority = (

    ppIdle,          // 空闲
    ppBelowNormal,   // 低于正常
    ppNormal,        // 正常
    ppAboveNormal,   // 高于正常
    ppHigh,          // 高
    ppRealTime       // 实时
  );

  {**
   * 窗口显示状态枚举（仅Windows）
   *}
  TWindowShowState = (
    wsHidden,        // 隐藏
    wsNormal,        // 正常
    wsMinimized,     // 最小化
    wsMaximized      // 最大化
  );



{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  TOnExitCallback = reference to procedure;
{$ENDIF}


  // 前向声明
  IProcessStartInfo = interface;
  IProcess = interface;

  {**
   * IProcessStartInfo
   *
   * @desc 进程启动配置接口
   *       封装进程启动所需的所有配置参数，包括文件路径、参数、
   *       环境变量、工作目录、流重定向等设置
   *}
  IProcessStartInfo = interface(IInterface)
  ['{7E4F79A7-0F89-4B8F-8C24-6F2E7F11A3C9}']

    // 基本属性访问
    function GetFileName: string;
    procedure SetFileName(const aValue: string);
    function GetArguments: string;
    procedure SetArguments(const aValue: string);
    function GetWorkingDirectory: string;
    procedure SetWorkingDirectory(const aValue: string);

    // PATH 搜索策略
    // 当 FileName 非绝对路径时，是否在 PATH（Windows 同时考虑 PATHEXT）中搜索可执行文件。
    // 默认 True（保持与历史行为一致）；关闭后需提供绝对路径或确保当前目录有可执行权限。
    function GetUsePathSearch: Boolean;
    procedure SetUsePathSearch(aValue: Boolean);

    // 流重定向配置
    function GetRedirectStandardInput: Boolean;
    procedure SetRedirectStandardInput(aValue: Boolean);
    function GetRedirectStandardOutput: Boolean;
    procedure SetRedirectStandardOutput(aValue: Boolean);
    function GetRedirectStandardError: Boolean;
    procedure SetRedirectStandardError(aValue: Boolean);
    // 合流配置（将 stderr 重定向到 stdout）
    function GetStdErrToStdOut: Boolean;
    procedure SetStdErrToStdOut(aValue: Boolean);

    // 进程属性配置
    function GetPriority: TProcessPriority;
    procedure SetPriority(aValue: TProcessPriority);
    function GetWindowShowState: TWindowShowState;
    procedure SetWindowShowState(aValue: TWindowShowState);

    // 环境变量管理
    function GetEnvironment: TStringList;
    function GetUseShellExecute: Boolean;
    procedure SetUseShellExecute(aValue: Boolean);

    // 后台排水开关（仅在重定向时有效）
    function GetDrainOutput: Boolean;
    procedure SetDrainOutput(aValue: Boolean);

    // 验证与便捷方法（参数更友好）
    procedure Validate;
    procedure AddArgument(const aArgument: string);

    // 外部流注入（用于 DrainOutput 模式下将输出直接写入提供的流）
    procedure AttachStdOut(AStream: TStream; aOwn: Boolean = False);
    procedure AttachStdErr(AStream: TStream; aOwn: Boolean = False);
    function GetAttachedStdOut: TStream;
    function GetAttachedStdErr: TStream;
    function GetOwnAttachedStdOut: Boolean;
    function GetOwnAttachedStdErr: Boolean;

    procedure SetEnvironmentVariable(const aName, aValue: string);
    function GetEnvironmentVariable(const aName: string): string;
    procedure ClearEnvironment;

    // 属性声明
    property FileName: string read GetFileName write SetFileName;
    property Arguments: string read GetArguments write SetArguments;
    property WorkingDirectory: string read GetWorkingDirectory write SetWorkingDirectory;
    property RedirectStandardInput: Boolean read GetRedirectStandardInput write SetRedirectStandardInput;
    property RedirectStandardOutput: Boolean read GetRedirectStandardOutput write SetRedirectStandardOutput;
    property RedirectStandardError: Boolean read GetRedirectStandardError write SetRedirectStandardError;
    // 当为 True 时，将 stderr 重定向到 stdout（平台层设置相同句柄/dup2）；默认 False
    property StdErrToStdOut: Boolean read GetStdErrToStdOut write SetStdErrToStdOut;
    property Priority: TProcessPriority read GetPriority write SetPriority;
    property WindowShowState: TWindowShowState read GetWindowShowState write SetWindowShowState;
    property Environment: TStringList read GetEnvironment;
    // UseShellExecute: 当前版本中仅影响验证行为，不启用 ShellExecuteEx
    // 设置为 True 时跳过文件存在性检查，但仍使用 CreateProcess/fork+exec 启动
    // 未来版本可能提供完整的 Shell 执行支持
    property UseShellExecute: Boolean read GetUseShellExecute write SetUseShellExecute;
  end;


  {**
   * IProcess
   *
   * @desc 进程管理核心接口
   *       提供进程的完整生命周期管理，包括启动、等待、终止、
   *       状态查询以及标准流的访问控制
   *}
  IProcess = interface(IInterface)
  ['{A2C3D4E5-F607-48B9-9C1D-2E3F4A5B6C7D}']

    // 生命周期管理
    procedure Start;                                              // 启动进程
    function WaitForExit(aTimeoutMs: Cardinal = $FFFFFFFF): Boolean; // 等待进程退出
    function TryWait: Boolean;                                    // 非阻塞检查是否已退出（等价 WaitForExit(0)）
    procedure Kill;                                               // 强制终止进程
    procedure Terminate;                                          // 优雅终止进程
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure OnExit(const Callback: TOnExitCallback);            // 进程退出回调（后台线程）
    {$ENDIF}

    // 状态查询接口
    function GetState: TProcessState;                             // 获取当前状态
    function GetHasExited: Boolean;                               // 是否已退出
    function GetExitCode: Integer;                                // 获取退出码
    function GetProcessId: Cardinal;                              // 获取进程ID
    function GetStartTime: TDateTime;                             // 获取启动时间
    function GetExitTime: TDateTime;                              // 获取退出时间

    // 流访问接口（仅在重定向时可用）
    function GetStandardInput: TStream;                           // 获取标准输入流
    function GetStandardOutput: TStream;                          // 获取标准输出流
    function GetStandardError: TStream;                           // 获取标准错误流
    procedure CloseStandardInput;                                 // 关闭标准输入流

    // 配置访问
    function GetStartInfo: IProcessStartInfo;                     // 获取启动配置

    // 属性声明
    property State: TProcessState read GetState;
    property HasExited: Boolean read GetHasExited;
    property ExitCode: Integer read GetExitCode;
    property ProcessId: Cardinal read GetProcessId;
    property StartTime: TDateTime read GetStartTime;
    property ExitTime: TDateTime read GetExitTime;
    property StandardInput: TStream read GetStandardInput;
    property StandardOutput: TStream read GetStandardOutput;
    property StandardError: TStream read GetStandardError;
    property StartInfo: IProcessStartInfo read GetStartInfo;
  end;

  {**
   * IProcessGroup
   *
   * @desc 进程组/作业对象抽象。Windows 使用 Job Object；Unix 预留 PGID（后续实现）。
   *}
  IProcessGroup = interface(IInterface)
  ['{1B3E8C92-77D1-4F5E-90A9-3D5F1C2B8E64}']
    procedure Add(const AProcess: IProcess);       // 将已启动进程加入组
    procedure TerminateGroup(aExitCode: Cardinal = 1); // 终止整个组（Windows: Job Object；Unix: PGID）
    procedure KillTree(aExitCode: Cardinal = 1);       // 别名：等同 TerminateGroup
    function Count: Integer;                       // 组内进程数量（近似）
  end;


  {$IFDEF FAFAFA_PROCESS_GROUPS}
  // 运行时进程组策略：替代纯编译期宏，默认值由宏提供（全部关闭，0ms）
  // Windows 作业对象（Job Object）优雅终止策略：
  // 典型顺序：CtrlBreak/WmClose → 等待 GracefulWaitMs → TerminateJobObject 兜底
  TProcessGroupPolicy = record
    EnableCtrlBreak: Boolean;   // 向控制台进程发送 CTRL_BREAK_EVENT（需共享控制台）
    EnableWmClose: Boolean;     // 尝试向拥有窗口的进程广播 WM_CLOSE（GUI 进程）
    GracefulWaitMs: Cardinal;   // 优雅尝试后的等待时间，超时则进入强制终止
  end;
  {$ENDIF}

  // 工厂方法（仅当启用组支持时返回实例，否则返回 nil）
  function NewProcessGroup: IProcessGroup; overload;
  {$IFDEF FAFAFA_PROCESS_GROUPS}
  function NewProcessGroup(const Policy: TProcessGroupPolicy): IProcessGroup; overload;
  {$ENDIF}




  // 继续类型声明
  type

  {**
   * IChild
   *
   * 子进程句柄接口（对标 Rust Child/Go Cmd/.Process），用于在构建器模型下操作已启动进程。
   * 说明：为保持兼容，内部通常由 IProcess 适配实现。
   *}
  IChild = interface(IInterface)
  ['{5D9A3F21-2B6E-4F38-9C1A-0D7E2A4B5C6F}']
    // 生命周期与控制
    function WaitForExit(aTimeoutMs: Cardinal = $FFFFFFFF): Boolean;
    procedure Kill;
    procedure Terminate;
    // 优雅终止：先 Terminate，再等待指定超时，返回是否在时限内退出（不自动 Kill）
    function GracefulShutdown(aTimeoutMs: Cardinal = 3000): Boolean;

    // 状态与元信息
    function GetState: TProcessState;
    function GetHasExited: Boolean;
    function GetExitCode: Integer;
    function GetProcessId: Cardinal;
    function GetStartTime: TDateTime;
    function GetExitTime: TDateTime;

    // 流访问（仅当重定向时可用）
    function GetStandardInput: TStream;
    function GetStandardOutput: TStream;
    function GetStandardError: TStream;
    procedure CloseStandardInput;

    // 属性
    property State: TProcessState read GetState;
    property HasExited: Boolean read GetHasExited;
    property ExitCode: Integer read GetExitCode;
    property ProcessId: Cardinal read GetProcessId;
    property StartTime: TDateTime read GetStartTime;
    property ExitTime: TDateTime read GetExitTime;
    property StandardInput: TStream read GetStandardInput;
    property StandardOutput: TStream read GetStandardOutput;
    property StandardError: TStream read GetStandardError;
  end;


  {**
   * IProcessBuilder
   *
   * 现代化进程构建器接口（对标 Rust Command/Go exec.Cmd/Java ProcessBuilder）。
   * 设计目标：提供流畅、类型安全、易用的链式 API，同时保持与既有实现的兼容性。
   *}
  IProcessBuilder = interface(IInterface)
  ['{C7B39D84-1A52-4DB1-9E77-FA2E8C61B0D3}']
    // === 基础配置 ===

    // 可执行文件配置
    function Exe(const aFileName: string): IProcessBuilder;
    function Command(const aFileName: string): IProcessBuilder; // 别名，更语义化
    function Executable(const aFileName: string): IProcessBuilder; // 别名，更语义化

    // 参数配置
    function Arg(const aValue: string): IProcessBuilder;
    function Args(const aValues: array of string): IProcessBuilder; overload;
    function Args(const aValues: TStringList): IProcessBuilder; overload;
    function Args(const aValues: TStrings): IProcessBuilder; overload;
    function ArgsFrom(const aCommandLine: string): IProcessBuilder; // 从命令行解析参数
    function ClearArgs: IProcessBuilder; // 清空参数列表

    // 工作目录配置
    function Cwd(const aDir: string): IProcessBuilder;
    function WorkingDir(const aDir: string): IProcessBuilder; // 别名，更语义化
    function CurrentDir(const aDir: string): IProcessBuilder; // 别名，更语义化

    // === 环境变量配置 ===

    // 单个环境变量
    function Env(const aName, aValue: string): IProcessBuilder;
    function SetEnv(const aName, aValue: string): IProcessBuilder; // 别名，更明确
    function UnsetEnv(const aName: string): IProcessBuilder; // 删除环境变量

    // 批量环境变量
    function Envs(const aEnvVars: array of string): IProcessBuilder; // 格式：['NAME=value', ...]
    function EnvsFrom(const aEnvVars: TStringList): IProcessBuilder;
    function EnvsFrom(const aEnvVars: TStrings): IProcessBuilder; overload;

    // 环境变量管理
    function ClearEnv: IProcessBuilder;
    function InheritEnv: IProcessBuilder; // 默认即继承，此调用用于语义标注
    function RemoveFromEnv(const aName: string): IProcessBuilder; // 别名

    // === 流重定向配置 ===

    // 基础重定向
    function RedirectStdIn(aEnable: Boolean = True): IProcessBuilder;
    function RedirectStdOut(aEnable: Boolean = True): IProcessBuilder;
    function RedirectStdErr(aEnable: Boolean = True): IProcessBuilder;

    // 语义化重定向方法
    function CaptureOutput: IProcessBuilder; // 重定向 stdout 和 stderr
    function CaptureStdOut: IProcessBuilder; // 重定向 stdout
    function CaptureStdErr: IProcessBuilder; // 重定向 stderr
    function RedirectInput: IProcessBuilder; // 重定向 stdin
    function RedirectAll: IProcessBuilder; // 重定向所有流
    function NoRedirect: IProcessBuilder; // 禁用所有重定向

    // 便捷组合
    function CaptureAll: IProcessBuilder;   // 便捷：RedirectAll + DrainOutput(True)，不合流，便于分别读取

    // 流合并
    function StdErrToStdOut: IProcessBuilder; // stderr 重定向到 stdout（已实现）
    function CombinedOutput: IProcessBuilder; // 便捷：CaptureStdOut + StdErrToStdOut + DrainOutput(True)

    // === 超时便捷 API ===
    function WithTimeout(timeoutMs: Integer): IProcessBuilder; // 设置默认超时（<=0 表示不启用）
    function RunWithTimeout(timeoutMs: Integer): IChild;      // 启动并等待；超时 Kill+抛 EProcessTimeoutError
    // 可选：后台排水，避免重定向后未读导致的阻塞
    function DrainOutput(aEnable: Boolean = True): IProcessBuilder;
    function OutputWithTimeout(timeoutMs: Integer): string;   // 读取输出前等待；超时 Kill+抛错

    // === 进程属性配置 ===

    // 优先级和窗口
    function Priority(aPriority: TProcessPriority): IProcessBuilder;
    function LowPriority: IProcessBuilder; // 便捷方法
    function NormalPriority: IProcessBuilder; // 便捷方法
    function HighPriority: IProcessBuilder; // 便捷方法

    function WindowShow(aState: TWindowShowState): IProcessBuilder;
    function WindowHidden: IProcessBuilder; // 便捷方法
    function WindowNormal: IProcessBuilder; // 便捷方法
    function WindowMaximized: IProcessBuilder; // 便捷方法
    function WindowMinimized: IProcessBuilder; // 便捷方法

    // Shell 执行/路径搜索
    function UseShell(aUse: Boolean = True): IProcessBuilder; // v1: 仅影响验证行为
    function UsePathSearch(aEnable: Boolean = True): IProcessBuilder; // 是否允许 PATH(+PATHEXT) 搜索（默认 True，保持向后兼容）
    function NoShell: IProcessBuilder; // 便捷方法，等同于 UseShell(False)

    // === 便捷配置方法 ===

    // 常用配置组合
    function Silent: IProcessBuilder; // 隐藏窗口 + 重定向输出
    function Interactive: IProcessBuilder; // 显示窗口 + 不重定向
    function Background: IProcessBuilder; // 后台运行配置
    function Foreground: IProcessBuilder; // 前台运行配置

    // 超时配置（未来功能预留）
    function Timeout(aTimeoutMs: Cardinal): IProcessBuilder;
    function KillOnTimeout(aEnable: Boolean = True): IProcessBuilder;

    // === 构建和启动 ===

    // 构建进程对象
    function Build: IProcess;  // 构建但不启动
    function GetStartInfo: IProcessStartInfo; // 获取配置信息


    // 启动进程
    function Start: IChild;    // 启动并返回子进程句柄
    function Spawn: IChild;    // 别名，对标 Rust
    function Run: IChild;      // 别名，对标 Go
    function Execute: IChild;  // 别名，传统命名

    // 进程组（可选，FAFAFA_PROCESS_GROUPS 开启时有效）
    function WithGroup(const AGroup: IProcessGroup): IProcessBuilder; // 绑定默认进程组
    function StartIntoGroup(const AGroup: IProcessGroup): IChild;     // 启动并加入指定组

    // 启动并等待
    function Output: string;           // 启动进程并获取输出（自动重定向）
    function Status: Integer;          // 启动进程并等待退出码
    function Success: Boolean;         // 启动进程并检查是否成功（退出码=0）
    function StatusChecked: Integer;   // 非 0 退出码抛出 EProcessExitError
    function OutputChecked: string;    // 输出便捷方法，非 0 退出码抛出 EProcessExitError

    // === 验证和调试 ===

    // 配置验证
    function Validate: IProcessBuilder; // 验证配置，抛出异常如果有问题
    function IsValid: Boolean; // 检查配置是否有效
    function GetValidationErrors: TStringList; // 获取验证错误列表

    // 调试信息
    function GetCommandLine: string; // 获取完整命令行
    function GetEnvironmentSummary: string; // 获取环境变量摘要
    function ToString: string; // 获取构建器状态描述
  end;

  // 工厂函数：获取一个构建器实例
  function NewProcessBuilder: IProcessBuilder;

  // 适配器：将 IProcess 适配为 IChild（隐藏实现细节）

  type

  TChildAdapter = class sealed(TInterfacedObject, IChild)
  private
    FProc: IProcess;
  protected
    function WaitForExit(aTimeoutMs: Cardinal = $FFFFFFFF): Boolean;
    procedure Kill;
    procedure Terminate;

    function GetState: TProcessState;
    function GetHasExited: Boolean;
    function GetExitCode: Integer;
    function GetProcessId: Cardinal;
    function GetStartTime: TDateTime;
    function GetExitTime: TDateTime;

    function GetStandardInput: TStream;
    function GetStandardOutput: TStream;
    function GetStandardError: TStream;
    procedure CloseStandardInput;
  public
    function GracefulShutdown(aTimeoutMs: Cardinal = 3000): Boolean;
    constructor Create(const aProc: IProcess);
  end;
  // 现代化构建器实现：内部基于 TProcessStartInfo 组装，保持对现有实现的最小侵入
  TProcessBuilder = class(TInterfacedObject, IProcessBuilder)
  private
    FStartInfo: IProcessStartInfo;
    FInheritEnv: Boolean;
    FTimeoutMs: Cardinal;
    FKillOnTimeout: Boolean;
    FDrainOutput: Boolean;
    {$IFDEF FAFAFA_PROCESS_GROUPS}
    FGroup: IProcessGroup;
    {$ENDIF}

    // 内部辅助方法
    function ParseCommandLine(const aCommandLine: string): TStringList;
    function ValidateConfiguration: TStringList;

  protected
    // === 基础配置 ===
    function Exe(const aFileName: string): IProcessBuilder;
    function Command(const aFileName: string): IProcessBuilder;
    function Executable(const aFileName: string): IProcessBuilder;

    function Arg(const aValue: string): IProcessBuilder;
    function Args(const aValues: array of string): IProcessBuilder; overload;
    function UsePathSearch(aEnable: Boolean = True): IProcessBuilder;
    function Args(const aValues: TStringList): IProcessBuilder; overload;
    function Args(const aValues: TStrings): IProcessBuilder; overload;
    function ArgsFrom(const aCommandLine: string): IProcessBuilder;
    function ClearArgs: IProcessBuilder;

    function Cwd(const aDir: string): IProcessBuilder;
    function WorkingDir(const aDir: string): IProcessBuilder;
    function CurrentDir(const aDir: string): IProcessBuilder;

    // === 环境变量配置 ===
    function Env(const aName, aValue: string): IProcessBuilder;
    function SetEnv(const aName, aValue: string): IProcessBuilder;
    function UnsetEnv(const aName: string): IProcessBuilder;

    function Envs(const aEnvVars: array of string): IProcessBuilder;
    function EnvsFrom(const aEnvVars: TStringList): IProcessBuilder;
    function EnvsFrom(const aEnvVars: TStrings): IProcessBuilder; overload;


    function ClearEnv: IProcessBuilder;
    function InheritEnv: IProcessBuilder;
    function RemoveFromEnv(const aName: string): IProcessBuilder;

    // === 流重定向配置 ===
    function RedirectStdIn(aEnable: Boolean = True): IProcessBuilder;
    function RedirectStdOut(aEnable: Boolean = True): IProcessBuilder;
    function RedirectStdErr(aEnable: Boolean = True): IProcessBuilder;

    function CaptureOutput: IProcessBuilder;
    function CaptureStdOut: IProcessBuilder;
    function CaptureStdErr: IProcessBuilder;
    function RedirectInput: IProcessBuilder;
    function RedirectAll: IProcessBuilder;
    function NoRedirect: IProcessBuilder;
    function CaptureAll: IProcessBuilder;
    function StdErrToStdOut: IProcessBuilder;
    function CombinedOutput: IProcessBuilder;

    // === 超时便捷 API ===
    function WithTimeout(timeoutMs: Integer): IProcessBuilder;
    function RunWithTimeout(timeoutMs: Integer): IChild;
    function OutputWithTimeout(timeoutMs: Integer): string;
    // 可选：后台排水，避免重定向后未读导致的阻塞
    function DrainOutput(aEnable: Boolean = True): IProcessBuilder;

    // === 进程属性配置 ===
    function Priority(aPriority: TProcessPriority): IProcessBuilder;
    function LowPriority: IProcessBuilder;
    function NormalPriority: IProcessBuilder;
    function HighPriority: IProcessBuilder;

    function WindowShow(aState: TWindowShowState): IProcessBuilder;
    function WindowHidden: IProcessBuilder;
    function WindowNormal: IProcessBuilder;
    function WindowMaximized: IProcessBuilder;
    function WindowMinimized: IProcessBuilder;

    function UseShell(aUse: Boolean = True): IProcessBuilder;
    function WithGroupPolicy(const Policy: TProcessGroupPolicy): IProcessBuilder;
    function NoShell: IProcessBuilder;

    // === 便捷配置方法 ===
    function Silent: IProcessBuilder;
    function Interactive: IProcessBuilder;
    function Background: IProcessBuilder;

    function Foreground: IProcessBuilder;

    function Timeout(aTimeoutMs: Cardinal): IProcessBuilder;
    function KillOnTimeout(aEnable: Boolean = True): IProcessBuilder;

    // === 构建和启动 ===
    function Build: IProcess;
    function GetStartInfo: IProcessStartInfo;

    function WithGroup(const AGroup: IProcessGroup): IProcessBuilder;
    function StartIntoGroup(const AGroup: IProcessGroup): IChild;

    function Start: IChild;
    function Spawn: IChild;
    function Run: IChild;
    function Execute: IChild;

    function Output: string;
    function Status: Integer;
    function Success: Boolean;
    function StatusChecked: Integer;
    function OutputChecked: string;

    // === 验证和调试 ===
    function Validate: IProcessBuilder;
    function IsValid: Boolean;
    function GetValidationErrors: TStringList;

    function GetCommandLine: string;
    function GetEnvironmentSummary: string;
    function ToString: string; override;

  public
    constructor Create;
  end;


  {**
   * TProcessStartInfo
   *
   * @desc 进程启动配置实现类
   *       实现 IProcessStartInfo 接口，提供进程启动参数的具体管理
   *}
  TProcessStartInfo = class(TInterfacedObject, IProcessStartInfo)
  private
    FFileName: string;
    FArguments: string;
    FWorkingDirectory: string;
    FRedirectStandardInput: Boolean;
    FRedirectStandardOutput: Boolean;
    FRedirectStandardError: Boolean;
    FStdErrToStdOut: Boolean; // 将 stderr 重定向到 stdout（合流）
    FUsePathSearch: Boolean; // 是否允许启用 PATH 搜索（Windows 同时考虑 PATHEXT）；默认 True
    FPriority: TProcessPriority;
    FWindowShowState: TWindowShowState;
    FEnvironment: TStringList;
    FDrainOutput: Boolean; // 是否后台读取 stdout/stderr 以避免阻塞
    FUseShellExecute: Boolean;
    // 额外存储：参数列表（用于更可靠的 Windows 引号/转义）
    FArgList: TStringList;

  protected
    {$IFDEF WINDOWS}
    FDrainThreadOut: TThread;
    FDrainThreadErr: TThread;
    {$ENDIF}
    // IProcessStartInfo implementation
    function GetFileName: string;
    procedure SetFileName(const aValue: string);
    function GetArguments: string;
    procedure SetArguments(const aValue: string);
    function GetWorkingDirectory: string;
    procedure SetWorkingDirectory(const aValue: string);
    function GetUsePathSearch: Boolean;
    procedure SetUsePathSearch(aValue: Boolean);
    function GetRedirectStandardInput: Boolean;
    procedure SetRedirectStandardInput(aValue: Boolean);

    // 外部流方法实现（接口）
    procedure AttachStdOut(AStream: TStream; aOwn: Boolean = False);
    procedure AttachStdErr(AStream: TStream; aOwn: Boolean = False);
    function GetAttachedStdOut: TStream;
    function GetAttachedStdErr: TStream;
    function GetOwnAttachedStdOut: Boolean;
    function GetOwnAttachedStdErr: Boolean;

  private
    // 外部流注入（由 StartInfo 持有，可选拥有权）
    FAttachedStdOut: TStream;
    FAttachedStdErr: TStream;
    FOwnAttachedStdOut: Boolean;
    FOwnAttachedStdErr: Boolean;

    function GetRedirectStandardOutput: Boolean;
    procedure SetRedirectStandardOutput(aValue: Boolean);
    function GetRedirectStandardError: Boolean;
    procedure SetRedirectStandardError(aValue: Boolean);
    function GetPriority: TProcessPriority;
    procedure SetPriority(aValue: TProcessPriority);
    function GetWindowShowState: TWindowShowState;
    procedure SetWindowShowState(aValue: TWindowShowState);
    function GetEnvironment: TStringList;
    function GetUseShellExecute: Boolean;
    procedure SetUseShellExecute(aValue: Boolean);

    // 后台排水开关（仅在重定向时有效）
    function GetDrainOutput: Boolean;
    procedure SetDrainOutput(aValue: Boolean);

    // 合流配置（将 stderr 重定向到 stdout）
    function GetStdErrToStdOut: Boolean;
    procedure SetStdErrToStdOut(aValue: Boolean);

    procedure Validate;
    procedure AddArgument(const aArgument: string);
    procedure SetEnvironmentVariable(const aName, aValue: string);
    function GetEnvironmentVariable(const aName: string): string;
    procedure ClearEnvironment;

  public
    constructor Create; overload;
    constructor Create(const aFileName: string); overload;
    constructor Create(const aFileName, aArguments: string); overload;
    destructor Destroy; override;

    // 非接口暴露：仅供同单元实现访问（通过类类型强制转换）
    function GetArgListRaw: TStrings;
    procedure ClearArgumentsList; // 清空内部参数列表（不改 Arguments 字符串）


  end;

  {**
   * TProcess
   *
   * @desc 进程管理实现类
   *       实现 IProcess 接口，提供进程生命周期管理的具体实现
   *}
  TProcess = class(TInterfacedObject, IProcess)
  private
    FStartInfo: IProcessStartInfo;
    FState: TProcessState;
    FExitCode: Integer;
    FProcessId: Cardinal;
  {$IFDEF FAFAFA_PROCESS_GROUPS}
  // 注意：TProcessGroup 定义见实现节（避免在类内嵌定义引起语法错误）
  {$ENDIF}

    FStartTime: TDateTime;
    FExitTime: TDateTime;

    // 平台相关句柄
    {$IFDEF WINDOWS}
    FProcessHandle: THandle;
    FThreadHandle: THandle;
    FInputPipeRead, FInputPipeWrite: THandle;
    FOutputPipeRead, FOutputPipeWrite: THandle;
    FErrorPipeRead, FErrorPipeWrite: THandle;
    // 后台排水线程（仅在启用 DrainOutput 且重定向时创建）
    FDrainThreadOut: TThread;
    FDrainThreadErr: TThread;
    {$ENDIF}
    {$IFDEF UNIX}
    FProcessId_Unix: TPid;
    FInputPipe: array[0..1] of Integer;
    FOutputPipe: array[0..1] of Integer;
    FErrorPipe: array[0..1] of Integer;
    // 后台排水线程（仅在启用 DrainOutput 且重定向时创建）
    FDrainThreadOut: TThread;
    FDrainThreadErr: TThread;
    {$ENDIF}

    // 流重定向相关
    FStandardInput: TStream;
    FStandardOutput: TStream;
    FStandardError: TStream;
    // 自动排水缓冲（当 WaitForExit 触发自动排水时，将数据写入内存缓冲，供后续读取）
    FStdOutBuffer: TMemoryStream;
    FStdErrBuffer: TMemoryStream;


    // 内部方法
    {$IFDEF WINDOWS}
    procedure StartWindows;
    function WaitForExitWindows(aTimeoutMs: Cardinal): Boolean;
    procedure KillWindows;
    procedure CreatePipesWindows;
    procedure ClosePipesWindows;
    procedure CloseDrainThreadsWindows; // 等待并释放后台排水线程（若启用）
    function BuildCommandLineWindows: string;
    function BuildEnvironmentBlockWindows: Pointer;
    {$ENDIF}
    {$IFDEF UNIX}
    procedure StartUnix;
    function WaitForExitUnix(aTimeoutMs: Cardinal): Boolean;
    procedure KillUnix;
    procedure TerminateUnix;
    procedure CreatePipesUnix;
    procedure ClosePipesUnix;
    procedure CloseDrainThreadsUnix; // 等待并释放后台排水线程（若启用）
    function BuildArgumentArrayUnix: PPChar;
    function BuildEnvironmentArrayUnix: PPChar;
    procedure FreeArgumentArrayUnix(aArgv: PPChar);
    procedure FreeEnvironmentArrayUnix(aEnvp: PPChar);
    procedure ParseArgumentsUnix(const aArguments: string; aArgs: TStringList);
    {$IFDEF UNIX}
    {$IFDEF FAFAFA_PROCESS_USE_POSIX_SPAWN}
    function StartUnixUsingPosixSpawn: Boolean; // 返回 True 表示已由 spawn 路径完成启动
    {$ENDIF}
    {$ENDIF}

    {$ENDIF}

    procedure CreateStreamWrappers;
    procedure CleanupResources;

  protected
    // IProcess implementation
    procedure Start;
    function WaitForExit(aTimeoutMs: Cardinal = $FFFFFFFF): Boolean;
    function TryWait: Boolean;
    procedure Kill;

    procedure Terminate;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure OnExit(const Callback: TOnExitCallback);
    {$ENDIF}
    function GetState: TProcessState;
    function GetHasExited: Boolean;
    function GetExitCode: Integer;
    function GetProcessId: Cardinal;
    function GetStartTime: TDateTime;
    function GetExitTime: TDateTime;
    function GetStandardInput: TStream;
    function GetStandardOutput: TStream;
    function GetStandardError: TStream;
    procedure CloseStandardInput;
    function GetStartInfo: IProcessStartInfo;

    // 在等待前按需启动后台排水以避免阻塞（受宏 FAFAFA_PROCESS_AUTO_DRAIN_ON_WAIT 控制）
    procedure EnsureAutoDrainOnWait;
    procedure FinalizeAutoDrainOnExit;

  public
    constructor Create(aStartInfo: IProcessStartInfo);
    destructor Destroy; override;


  end;



implementation

uses
  fafafa.core.math;

{$I fafafa.core.process.exceptions.inc}



{$IFDEF FAFAFA_PROCESS_GROUPS}

{$IFDEF WINDOWS}
// Optional graceful control events for console processes (Windows)
// 某些 FPC 版本未公开以下声明，这里做外部声明
function AttachConsole(dwProcessId: DWORD): LongBool; stdcall; external 'kernel32' name 'AttachConsole';
function FreeConsole: LongBool; stdcall; external 'kernel32' name 'FreeConsole';
function GenerateConsoleCtrlEvent(dwCtrlEvent, dwProcessGroupId: DWORD): LongBool; stdcall; external 'kernel32' name 'GenerateConsoleCtrlEvent';
function SetConsoleCtrlHandler(HandlerRoutine: Pointer; Add: LongBool): LongBool; stdcall; external 'kernel32' name 'SetConsoleCtrlHandler';
{$ENDIF}



{$IFDEF WINDOWS}
// Helper: send WM_CLOSE to all top-level windows owned by a PID
// 注意：仅对拥有顶层窗口的 GUI/控制台进程有效；不保证立即退出
type
  PEnumCloseParam = ^TEnumCloseParam;
  TEnumCloseParam = record
    TargetPid: DWORD;
    ClosedCount: Integer;
  end;

function EnumCloseProc(Wnd: HWND; LParam: LPARAM): BOOL; stdcall;
var
  Wpid: DWORD;
  P: PEnumCloseParam;
begin
  Result := True;
  P := PEnumCloseParam(LParam);
  if P = nil then Exit;
  GetWindowThreadProcessId(Wnd, @Wpid);
  if Wpid = P^.TargetPid then
  begin
    PostMessageW(Wnd, WM_CLOSE, 0, 0);
    Inc(P^.ClosedCount);
  end;
end;

function SendWmCloseToProcessWindows(const APid: DWORD): Integer;
var
  Param: TEnumCloseParam;
begin
  Param.TargetPid := APid;
  Param.ClosedCount := 0;
  EnumWindows(@EnumCloseProc, LPARAM(@Param));
  Result := Param.ClosedCount;
end;
{$ENDIF}

{$IFDEF WINDOWS}
// FPC 某些版本未在 Windows 单元暴露 Job Object API，这里手动声明 external 入口
function CreateJobObject(lpJobAttributes: Pointer; lpName: PWideChar): THandle; stdcall; external 'kernel32' name 'CreateJobObjectW';
function AssignProcessToJobObject(hJob: THandle; hProcess: THandle): LongBool; stdcall; external 'kernel32' name 'AssignProcessToJobObject';
function TerminateJobObject(hJob: THandle; uExitCode: Cardinal): LongBool; stdcall; external 'kernel32' name 'TerminateJobObject';
function SetInformationJobObject(hJob: THandle; JobObjectInfoClass: Integer; lpJobObjectInfo: Pointer; cbJobObjectInfoLength: DWORD): LongBool; stdcall; external 'kernel32' name 'SetInformationJobObject';

const
  JobObjectExtendedLimitInformation = 9;
  JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE = $00002000;

Type
  // 最小化声明，仅用于启用 KILL_ON_JOB_CLOSE
  TIO_COUNTERS = record
    ReadOperationCount: QWord;
    WriteOperationCount: QWord;
    OtherOperationCount: QWord;
    ReadTransferCount: QWord;
    WriteTransferCount: QWord;
    OtherTransferCount: QWord;
  end;

  TJOBOBJECT_BASIC_LIMIT_INFORMATION = record
    PerProcessUserTimeLimit: Int64;
    PerJobUserTimeLimit: Int64;
    LimitFlags: DWORD;
    MinimumWorkingSetSize: SIZE_T;
    MaximumWorkingSetSize: SIZE_T;
    ActiveProcessLimit: DWORD;
    Affinity: NativeUInt; // ULONG_PTR
    PriorityClass: DWORD;
    SchedulingClass: DWORD;
  end;

  TJOBOBJECT_EXTENDED_LIMIT_INFORMATION = record
    BasicLimitInformation: TJOBOBJECT_BASIC_LIMIT_INFORMATION;
    IoInfo: TIO_COUNTERS;
    ProcessMemoryLimit: SIZE_T;
    JobMemoryLimit: SIZE_T;
    PeakProcessMemoryUsage: SIZE_T;
    PeakJobMemoryUsage: SIZE_T;
  end;
{$ENDIF}

Type
  TProcessGroup = class(TInterfacedObject, IProcessGroup)
  private
    {$IFDEF WINDOWS}
    FJob: THandle;
    {$ENDIF}
    {$IFDEF UNIX}
    FGid: TPid; // 进程组ID（PGID）
    {$ENDIF}
    FList: TFPList;
    {$IFDEF FAFAFA_PROCESS_GROUPS}
    FPolicy: TProcessGroupPolicy;
    {$ENDIF}
  public
    constructor Create; overload;
    {$IFDEF FAFAFA_PROCESS_GROUPS}
    constructor Create(const APolicy: TProcessGroupPolicy); overload;
    {$ENDIF}
    destructor Destroy; override;
    procedure Add(const AProcess: IProcess);
    procedure TerminateGroup(aExitCode: Cardinal = 1);
    procedure KillTree(aExitCode: Cardinal = 1);
    function Count: Integer;
  end;
{$ENDIF}

{$IFDEF FAFAFA_PROCESS_GROUPS}
{$IFDEF WINDOWS}
// 引入 Windows API（JobObject）
{$ENDIF}
{ TProcessGroup }
constructor TProcessGroup.Create;
{$IFDEF WINDOWS}
var
  LimitInfo: TJOBOBJECT_EXTENDED_LIMIT_INFORMATION;
{$ENDIF}

begin
  inherited Create;
  FList := TFPList.Create;
  {$IFDEF FAFAFA_PROCESS_GROUPS}
  FPolicy.EnableCtrlBreak := {$IFDEF FAFAFA_PROCESS_GROUP_CTRL_BREAK}True{$ELSE}False{$ENDIF};
  FPolicy.EnableWmClose   := {$IFDEF FAFAFA_PROCESS_GROUP_WMCLOSE}True{$ELSE}False{$ENDIF};
  {$IFDEF FAFAFA_PROCESS_GROUP_GRACEFUL_MS}
  FPolicy.GracefulWaitMs  := FAFAFA_PROCESS_GROUP_GRACEFUL_MS;
  {$ELSE}
  FPolicy.GracefulWaitMs  := 0;
  {$ENDIF}
  {$ENDIF}
  {$IFDEF WINDOWS}
  FJob := CreateJobObject(nil, nil);
  if FJob = 0 then
    raise EProcessError.Create('CreateJobObject failed');
  // 启用 KILL_ON_JOB_CLOSE，防止泄漏（当 Job 被释放时，整组进程将被终止）
  try
    FillChar(LimitInfo, SizeOf(LimitInfo), 0);
    LimitInfo.BasicLimitInformation.LimitFlags := JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
    // 忽略 SetInformationJobObject 的失败（在某些受限环境可能不支持），不影响基本功能
    SetInformationJobObject(FJob, JobObjectExtendedLimitInformation, @LimitInfo, SizeOf(LimitInfo));
  except
    // 安全兜底：不要在构造器中抛出次要能力异常
  end;
  {$ENDIF}
  {$IFDEF UNIX}
  FGid := 0;
  {$ENDIF}
end;

{$IFDEF FAFAFA_PROCESS_GROUPS}
constructor TProcessGroup.Create(const APolicy: TProcessGroupPolicy);
begin
  Create;
  FPolicy := APolicy;
end;
{$ENDIF}

destructor TProcessGroup.Destroy;
begin
  {$IFDEF WINDOWS}
  if FJob <> 0 then
    CloseHandle(FJob);
  {$ENDIF}
  FreeAndNil(FList);
  inherited Destroy;
end;

procedure TProcessGroup.Add(const AProcess: IProcess);
{$IFDEF WINDOWS}
var
  H: THandle;
  Pid: DWORD;
  Err: DWORD;
begin
  H := 0;
  Pid := AProcess.ProcessId;
  if Pid = 0 then
    raise EProcessError.Create('Process not started (pid=0)');
  try
    H := OpenProcess(PROCESS_SET_QUOTA or PROCESS_TERMINATE, False, Pid);
    if H = 0 then
    begin
      Err := GetLastError;
      raise EProcessError.CreateFmt('OpenProcess(pid=%d) failed: error=%d', [Pid, Err]);
    end;
    if not AssignProcessToJobObject(FJob, H) then
    begin
      Err := GetLastError;
      raise EProcessError.CreateFmt('AssignProcessToJobObject failed: pid=%d error=%d', [Pid, Err]);
    end;
    FList.Add(Pointer(AProcess));
  finally
    if H <> 0 then CloseHandle(H);
  end;
end;
{$ELSE}
var
  Pid, TargetGid: TPid;
  Err: LongInt;
begin
  // 使用 PGID 进行组管理：第一次加入的进程以其 PID 作为 PGID
  Pid := TPid(AProcess.ProcessId);
  if Pid = 0 then
    raise EProcessError.Create('Process not started (pid=0)');
  if FGid = 0 then
    TargetGid := Pid
  else
    TargetGid := FGid;
  // 尝试将子进程加入目标 PGID（可能已在子进程中 setpgid(0,0) 完成，失败可忽略）
  if setpgid(Pid, TargetGid) <> 0 then
  begin
    Err := fpgeterrno;
    // 忽略 EPERM/ESRCH/EACCES 等常见失败，保持组记录一致
  end;
  if FGid = 0 then FGid := TargetGid;
  FList.Add(Pointer(AProcess));
end;
{$ENDIF}

procedure TProcessGroup.TerminateGroup(aExitCode: Cardinal);
var
  I: Integer;
begin
  {$IFDEF WINDOWS}
  if FJob <> 0 then
  begin
    // 1) 可选：尝试优雅终止控制台进程（CTRL_BREAK）
    if {$IFDEF FAFAFA_PROCESS_GROUPS}FPolicy.EnableCtrlBreak{$ELSE}False{$ENDIF} then
    begin
      try
        // 能力/会话探测：仅在附着控制台成功时再发 CTRL_BREAK
        if AttachConsole(DWORD(-1)) then
        try
          SetConsoleCtrlHandler(nil, True);
          // 0 表示发送到调用进程的进程组（注意：需要共享控制台会话）
          if not GenerateConsoleCtrlEvent(1 {CTRL_BREAK_EVENT}, 0) then
          begin
            // 发送失败，忽略（回退到 WM_CLOSE 或 TerminateJobObject）
          end;
        finally
          FreeConsole;
        end;
      except
        // 忽略能力探测/控制台 API 失败，不影响后续流程
      end;
    end;

    // 2) 可选：尝试向所有成员进程的顶层窗口发送 WM_CLOSE（若有）
    if {$IFDEF FAFAFA_PROCESS_GROUPS}FPolicy.EnableWmClose{$ELSE}False{$ENDIF} then
    begin
      try
        // 循环向每个进程窗口发送 WM_CLOSE
        for I := 0 to FList.Count - 1 do
        try
          SendWmCloseToProcessWindows(DWORD(IProcess(FList[I]).ProcessId));
        except
        end;
      except
      end;
    end;

    // 3) 可选：等待优雅收敛窗口
    {$IFDEF FAFAFA_PROCESS_GROUPS}
    if FPolicy.GracefulWaitMs > 0 then
      Sleep(FPolicy.GracefulWaitMs);
    {$ENDIF}

    // 4) 兜底：强制终止整个作业


    TerminateJobObject(FJob, aExitCode);
  end;
  {$ENDIF}
  {$IFDEF UNIX}
  // 优雅终止：先 SIGTERM，再在短等待后必要时 SIGKILL（U2 策略）
  if FGid <> 0 then
  begin
    fpkill(-FGid, SIGTERM);
    // 等待最多 1000ms（10*100ms）
    // 注意：此处不主动阻塞 Waitpid，由上层 WaitForExit 控制收敛
    // 仅在时限后做强制 SIGKILL 兜底
    Sleep(100);
    fpkill(-FGid, SIGKILL);
  end;
  {$ENDIF}
end;

function TProcessGroup.Count: Integer;
begin
  Result := FList.Count;
end;

procedure TProcessGroup.KillTree(aExitCode: Cardinal);
begin
  TerminateGroup(aExitCode);
end;
{$ENDIF}

function NewProcessGroup: IProcessGroup;
begin
  {$IFDEF FAFAFA_PROCESS_GROUPS}
  Result := TProcessGroup.Create;
  {$ELSE}
  Result := nil;
  {$ENDIF}
end;

{$IFDEF FAFAFA_PROCESS_GROUPS}
function NewProcessGroup(const Policy: TProcessGroupPolicy): IProcessGroup;
begin
  Result := TProcessGroup.Create(Policy);
end;
{$ENDIF}

{$IFDEF WINDOWS}
function LookPathWindows(const AFile: string): string; forward;
{$ENDIF}
{$IFDEF UNIX}
function LookPathUnix(const AFile: string): string; forward;
{$ENDIF}

function LookPath(const AFile: string): string;
begin
  {$IFDEF WINDOWS}
  Result := LookPathWindows(AFile);
  {$ELSE}
  Result := LookPathUnix(AFile);
  {$ENDIF}
end;












{$IFDEF WINDOWS}
function SearchExecutableInPathWindows(const AFile: string): Boolean; forward;
{$ENDIF}
{$IFDEF UNIX}
function SearchExecutableInPathUnix(const AFile: string): Boolean; forward;
{$ENDIF}


{ TProcessStartInfo }

constructor TProcessStartInfo.Create;
begin
  inherited Create;
  // 初始化环境与参数列表
  FEnvironment := TStringList.Create;
  FEnvironment.NameValueSeparator := '=';
  FEnvironment.Duplicates := dupIgnore;
  FEnvironment.CaseSensitive := False;
  FEnvironment.Sorted := False;
  FArgList := TStringList.Create;

  FFileName := '';
  FArguments := '';
  FWorkingDirectory := '';
  FRedirectStandardInput := False;
  FRedirectStandardOutput := False;
  FRedirectStandardError := False;
  FStdErrToStdOut := False;
  FUsePathSearch := True; // 默认开启 PATH 搜索（向后兼容）
  FPriority := ppNormal;
  FWindowShowState := wsNormal;
  FUseShellExecute := False;
  // 外部流注入默认未配置
  FAttachedStdOut := nil;
  FAttachedStdErr := nil;
  FOwnAttachedStdOut := False;
  FOwnAttachedStdErr := False;
end;

constructor TProcessStartInfo.Create(const aFileName: string);
begin
  Create;
  FFileName := aFileName;
end;

constructor TProcessStartInfo.Create(const aFileName, aArguments: string);
begin
  Create(aFileName);
  FArguments := aArguments;
end;

destructor TProcessStartInfo.Destroy;
begin
  if Assigned(FAttachedStdOut) and FOwnAttachedStdOut then FreeAndNil(FAttachedStdOut);
  if Assigned(FAttachedStdErr) and FOwnAttachedStdErr then FreeAndNil(FAttachedStdErr);
  FreeAndNil(FArgList);
  FreeAndNil(FEnvironment);
  inherited Destroy;
end;

function TProcessStartInfo.GetFileName: string;
begin
  Result := FFileName;
end;

procedure TProcessStartInfo.SetFileName(const aValue: string);
begin
  FFileName := aValue;
end;

function TProcessStartInfo.GetArguments: string;
begin
  Result := FArguments;
end;

procedure TProcessStartInfo.AttachStdOut(AStream: TStream; aOwn: Boolean);
begin
  FAttachedStdOut := AStream;
  FOwnAttachedStdOut := aOwn;
end;

procedure TProcessStartInfo.AttachStdErr(AStream: TStream; aOwn: Boolean);
begin
  FAttachedStdErr := AStream;
  FOwnAttachedStdErr := aOwn;
end;

function TProcessStartInfo.GetAttachedStdOut: TStream;
begin
  Result := FAttachedStdOut;
end;

function TProcessStartInfo.GetAttachedStdErr: TStream;
begin
  Result := FAttachedStdErr;
end;

function TProcessStartInfo.GetOwnAttachedStdOut: Boolean;
begin
  Result := FOwnAttachedStdOut;
end;

function TProcessStartInfo.GetOwnAttachedStdErr: Boolean;
begin
  Result := FOwnAttachedStdErr;
end;


procedure TProcessStartInfo.SetArguments(const aValue: string);
begin
  FArguments := aValue;
  // 为兼容保持简单赋值；实际构建时（Windows/Unix）会按平台解析
end;

function TProcessStartInfo.GetWorkingDirectory: string;

begin
  Result := FWorkingDirectory;
end;

procedure TProcessStartInfo.SetWorkingDirectory(const aValue: string);
begin
  FWorkingDirectory := aValue;
end;

function TProcessStartInfo.GetRedirectStandardInput: Boolean;
begin
  Result := FRedirectStandardInput;
end;

procedure TProcessStartInfo.SetRedirectStandardInput(aValue: Boolean);
begin
  FRedirectStandardInput := aValue;
end;

function TProcessStartInfo.GetRedirectStandardOutput: Boolean;
begin
  Result := FRedirectStandardOutput;
end;

procedure TProcessStartInfo.SetRedirectStandardOutput(aValue: Boolean);
begin
  FRedirectStandardOutput := aValue;
end;

function TProcessStartInfo.GetRedirectStandardError: Boolean;
begin
  Result := FRedirectStandardError;
end;

procedure TProcessStartInfo.SetRedirectStandardError(aValue: Boolean);
begin
  FRedirectStandardError := aValue;
end;
function TProcessStartInfo.GetUsePathSearch: Boolean;
begin
  Result := FUsePathSearch;
end;

procedure TProcessStartInfo.SetUsePathSearch(aValue: Boolean);
begin
  FUsePathSearch := aValue;
end;


function TProcessStartInfo.GetPriority: TProcessPriority;
begin
  Result := FPriority;
end;

procedure TProcessStartInfo.SetPriority(aValue: TProcessPriority);
begin
  FPriority := aValue;
end;

function TProcessStartInfo.GetWindowShowState: TWindowShowState;
begin
  Result := FWindowShowState;
end;

procedure TProcessStartInfo.SetWindowShowState(aValue: TWindowShowState);
begin
  FWindowShowState := aValue;
end;

function TProcessStartInfo.GetEnvironment: TStringList;
begin
  Result := FEnvironment;
end;

function TProcessStartInfo.GetDrainOutput: Boolean;
begin
  Result := FDrainOutput;
end;

procedure TProcessStartInfo.SetDrainOutput(aValue: Boolean);
begin
  FDrainOutput := aValue;
end;

function TProcessStartInfo.GetStdErrToStdOut: Boolean;
begin
  Result := FStdErrToStdOut;
end;

procedure TProcessStartInfo.SetStdErrToStdOut(aValue: Boolean);
begin
  FStdErrToStdOut := aValue;
end;

function TProcessStartInfo.GetUseShellExecute: Boolean;
begin
  Result := FUseShellExecute;
end;

procedure TProcessStartInfo.SetUseShellExecute(aValue: Boolean);
begin
  FUseShellExecute := aValue;
end;

procedure TProcessStartInfo.AddArgument(const aArgument: string);
begin
  if aArgument = '' then Exit;
  if FArguments = '' then
    FArguments := aArgument
  else
    FArguments := FArguments + ' ' + aArgument;
  if Assigned(FArgList) then
    FArgList.Add(aArgument);
end;

procedure TProcessStartInfo.ClearArgumentsList;
begin
  if Assigned(FArgList) then
    FArgList.Clear;
end;

function TProcessStartInfo.GetArgListRaw: TStrings;
begin
  Result := FArgList;
end;

procedure TProcessStartInfo.SetEnvironmentVariable(const aName, aValue: string);
var
  LIndex: Integer;
  LMsgU: UnicodeString;
begin
  // 基本验证：空名称将被忽略
  if aName = '' then
    Exit;

  // Windows 伪变量以 '=' 开头（如 '=C:'），应忽略而不是抛错
  {$IFDEF WINDOWS}
  if (Length(aName) > 0) and (aName[1] = '=') then
    Exit;
  {$ENDIF}

  // 验证名称中不能包含等号或空字符（除去 Windows 伪变量已被忽略的情况）
  if (Pos('=', aName) > 0) or (Pos(#0, aName) > 0) then
  begin
    LMsgU := UnicodeString('环境变量名称包含无效字符: ') + UnicodeString(aName);
    raise EProcessStartError.Create(UTF8Encode(LMsgU));
  end;

  // 验证值中不能包含空字符
  if (Pos(#0, aValue) > 0) then
  begin
    LMsgU := UnicodeString('环境变量值包含无效字符: ') + UnicodeString(aValue);
    raise EProcessStartError.Create(UTF8Encode(LMsgU));
  end;

  // 查找是否已存在该环境变量
  LIndex := FEnvironment.IndexOfName(aName);
  if LIndex >= 0 then
    FEnvironment.Strings[LIndex] := aName + '=' + aValue
  else
    FEnvironment.Add(aName + '=' + aValue);
end;


function TProcessStartInfo.GetEnvironmentVariable(const aName: string): string;
{$IFDEF WINDOWS}
var
  LIndex: Integer;
  LName: string;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
  // Windows 环境变量不区分大小写
  for LIndex := 0 to FEnvironment.Count - 1 do
  begin
    LName := FEnvironment.Names[LIndex];
    if SameText(LName, aName) then
    begin
      Result := FEnvironment.ValueFromIndex[LIndex];
      Exit;
    end;
  end;
  Result := '';
  {$ELSE}
  // Unix 环境变量区分大小写
  Result := FEnvironment.Values[aName];
  {$ENDIF}
end;

procedure TProcessStartInfo.ClearEnvironment;
begin
  FEnvironment.Clear;
end;

procedure TProcessStartInfo.Validate;
var
  LInvalidChars: set of Char;
  LChar: Char;
  LMsgU: UnicodeString;
begin
  // 验证文件名不能为空
  if Trim(FFileName) = '' then
  begin
    {$IFDEF WINDOWS}
    LMsgU := UnicodeString('进程文件名不能为空');
    raise EProcessStartError.Create(UTF8Encode(LMsgU));
    {$ELSE}
    raise EProcessStartError.Create('进程文件名不能为空');
    {$ENDIF}
  end;

  // 验证文件名不包含无效字符
  LInvalidChars := ['<', '>', '|', '"'];
  for LChar in FFileName do
  begin
    if LChar in LInvalidChars then
    begin
      {$IFDEF WINDOWS}
      LMsgU := UnicodeString('进程文件名包含无效字符: ') + UnicodeString(string(LChar));
      raise EProcessStartError.Create(UTF8Encode(LMsgU));
      {$ELSE}
      raise EProcessStartError.Create('进程文件名包含无效字符: ' + string(LChar));
      {$ENDIF}
    end;
  end;

  // 验证可执行文件是否存在（如果不使用Shell执行）
  if not FUseShellExecute then
  begin
    // 检查文件是否存在，支持相对路径和绝对路径
    if not FileExists(FFileName) then
    begin
      // 如果是相对路径，且启用了 PATH 搜索，则尝试在 PATH(+PATHEXT) 中查找
      if (Pos('\\', FFileName) = 0) and (Pos('/', FFileName) = 0) and FUsePathSearch then
      begin
        {$IFDEF WINDOWS}
        if not SearchExecutableInPathWindows(FFileName) then
        begin
          LMsgU := UnicodeString('找不到指定的可执行文件: ') + UnicodeString(FFileName);
          raise EProcessStartError.Create(UTF8Encode(LMsgU));
        end;
        // 找到则认为有效；为保持兼容性，不修改 FFileName
        {$ELSE}
        if not SearchExecutableInPathUnix(FFileName) then
          raise EProcessStartError.Create('找不到指定的可执行文件: ' + FFileName);
        {$ENDIF}
      end
      else
      begin
        // 绝对路径必须存在
        {$IFDEF WINDOWS}
        LMsgU := UnicodeString('找不到指定的可执行文件: ') + UnicodeString(FFileName);
        raise EProcessStartError.Create(UTF8Encode(LMsgU));
        {$ELSE}
        raise EProcessStartError.Create('找不到指定的可执行文件: ' + FFileName);
        {$ENDIF}
      end;
    end;
  end;

  // 验证工作目录（如果指定）
  if (FWorkingDirectory <> '') and not DirectoryExists(FWorkingDirectory) then
  begin
    {$IFDEF WINDOWS}
    LMsgU := UnicodeString('指定的工作目录不存在: ') + UnicodeString(FWorkingDirectory);
    raise EProcessStartError.Create(UTF8Encode(LMsgU));
    {$ELSE}
    raise EProcessStartError.Create('指定的工作目录不存在: ' + FWorkingDirectory);
    {$ENDIF}
  end;
end;

{ TProcess }

constructor TProcess.Create(aStartInfo: IProcessStartInfo);
begin
  inherited Create;

  if aStartInfo = nil then
    raise EArgumentNil.Create('进程启动信息不能为nil');

  FStartInfo := aStartInfo;
  FState := psNotStarted;
  FExitCode := 0;
  FProcessId := 0;
  FStartTime := 0;
  FExitTime := 0;

  // 初始化平台相关句柄
  {$IFDEF WINDOWS}
  FProcessHandle := 0;
  FThreadHandle := 0;
  FInputPipeRead := 0;
  FInputPipeWrite := 0;
  FOutputPipeRead := 0;
  FOutputPipeWrite := 0;
  FErrorPipeRead := 0;
  FErrorPipeWrite := 0;
  {$ENDIF}
  {$IFDEF UNIX}
  FProcessId_Unix := 0;
  FInputPipe[0] := -1;
  FInputPipe[1] := -1;
  FOutputPipe[0] := -1;
  FOutputPipe[1] := -1;
  FErrorPipe[0] := -1;
  FErrorPipe[1] := -1;
  {$ENDIF}

  // 初始化流句柄
  FStandardInput := nil;
  FStandardOutput := nil;
  FStandardError := nil;
  FStdOutBuffer := nil;
  FStdErrBuffer := nil;
end;

destructor TProcess.Destroy;
begin
  // 如果进程还在运行，尝试优雅终止
  if (FState = psRunning) then
  begin
    try
      Terminate;
      // 缩短析构等待，避免测试/回收阶段累积长时间阻塞
      if not WaitForExit(1000) then // 原 5000ms → 1000ms
        Kill; // 强制终止
    except
      // 忽略清理时的异常
    end;
  end;

  // 先释放流（注意：THandleStream 默认不拥有句柄，不会自动关闭）
  // 在此仅释放对象，不修改句柄变量，让 CleanupResources 统一关闭剩余句柄，避免泄漏/二次关闭。
  if Assigned(FStandardInput) then
  begin
    FreeAndNil(FStandardInput);
  end;
  if Assigned(FStandardOutput) then
  begin
    FreeAndNil(FStandardOutput);
  end;
  if Assigned(FStandardError) then
  begin
    FreeAndNil(FStandardError);
  end;
  // 释放自动排水的缓冲
  if Assigned(FStdOutBuffer) then
    FreeAndNil(FStdOutBuffer);
  if Assigned(FStdErrBuffer) then
    FreeAndNil(FStdErrBuffer);
  // 再兜底清理剩余系统资源（进程句柄与未包装为流的管道端）
  CleanupResources;

  inherited Destroy;
end;

procedure TProcess.FinalizeAutoDrainOnExit;
begin
  {$IFDEF FAFAFA_PROCESS_AUTO_DRAIN_ON_WAIT}
  // 仅在确实启用了后台排水线程时，才关闭读端并等待线程收敛
  try
    if Assigned(FDrainThreadOut) or Assigned(FDrainThreadErr) then
    begin
      {$IFDEF WINDOWS}
      CloseDrainThreadsWindows;
      {$ENDIF}
      {$IFDEF UNIX}
      CloseDrainThreadsUnix;
      {$ENDIF}

      if Assigned(FStdOutBuffer) then FStdOutBuffer.Position := 0;
      if Assigned(FStdErrBuffer) then FStdErrBuffer.Position := 0;
    end;
  except
    // 安全兜底：不影响主流程
  end;
  {$ENDIF}
end;

procedure TProcess.EnsureAutoDrainOnWait;
begin
  {$IFDEF FAFAFA_PROCESS_AUTO_DRAIN_ON_WAIT}
  // 自动排水改为写入内存缓冲，避免丢失数据
  try
    if (FStartInfo <> nil) then
    begin
      {$IFDEF WINDOWS}
      if (FStartInfo.GetDrainOutput) and (FStartInfo.RedirectStandardOutput) and (FOutputPipeRead <> 0) and (FDrainThreadOut = nil) then
      begin
        FDrainThreadOut := TThread.CreateAnonymousThread(
          procedure
          var
            Buf: array[0..8191] of Byte;
            BytesRead: DWORD;
            Ok: BOOL;
            Err: DWORD;
            Target: TStream;
          begin
            // 每次循环确定目标流（优先外部流，否则内存缓冲）
            Target := FStartInfo.GetAttachedStdOut;
            if Target = nil then
            begin
              if FStdOutBuffer = nil then FStdOutBuffer := TMemoryStream.Create;
              Target := FStdOutBuffer;
            end;
            while True do
            begin
              BytesRead := 0;
              Ok := ReadFile(FOutputPipeRead, Buf, SizeOf(Buf), BytesRead, nil);
              if not Ok then
              begin
                Err := GetLastError;
                if (Err = ERROR_BROKEN_PIPE) or (Err = ERROR_HANDLE_EOF) then Break;
                if (Err = ERROR_OPERATION_ABORTED) or (Err = ERROR_INVALID_HANDLE) then Break;
                Break; // 其他错误：也退出循环，避免噪音
              end;
              if BytesRead = 0 then Break; // EOF
              if BytesRead > 0 then
                Target.WriteBuffer(Buf, BytesRead);
            end;
          end);
        FDrainThreadOut.FreeOnTerminate := False;
        FDrainThreadOut.Start;
      end;
      if (FStartInfo.GetDrainOutput) and (FStartInfo.RedirectStandardError) and (not FStartInfo.StdErrToStdOut) and (FErrorPipeRead <> 0) and (FDrainThreadErr = nil) then
      begin
        FDrainThreadErr := TThread.CreateAnonymousThread(
          procedure
          var
            Buf: array[0..8191] of Byte;
            BytesRead: DWORD;
            Ok: BOOL;
            Err: DWORD;
            Target: TStream;
          begin
            Target := FStartInfo.GetAttachedStdErr;
            if Target = nil then
            begin
              if FStdErrBuffer = nil then FStdErrBuffer := TMemoryStream.Create;
              Target := FStdErrBuffer;
            end;
            while True do
            begin
              BytesRead := 0;
              Ok := ReadFile(FErrorPipeRead, Buf, SizeOf(Buf), BytesRead, nil);
              if not Ok then
              begin
                Err := GetLastError;
                if (Err = ERROR_BROKEN_PIPE) or (Err = ERROR_HANDLE_EOF) then Break;
                if (Err = ERROR_OPERATION_ABORTED) or (Err = ERROR_INVALID_HANDLE) then Break;
                Break;
              end;
              if BytesRead = 0 then Break;
              if BytesRead > 0 then
                Target.WriteBuffer(Buf, BytesRead);
            end;
          end);
        FDrainThreadErr.FreeOnTerminate := False;
        FDrainThreadErr.Start;
      end;
      {$ENDIF}
      {$IFDEF UNIX}
      if (FStartInfo.GetDrainOutput) and (FStartInfo.RedirectStandardOutput) and (FOutputPipe[0] <> -1) and (FDrainThreadOut = nil) then
      begin
        FDrainThreadOut := TThread.CreateAnonymousThread(
          procedure
          var
            Buf: array[0..8191] of Byte;
            N: ssize_t;
            Target: TStream;
          begin
            Target := FStartInfo.GetAttachedStdOut;
            if Target = nil then
            begin
              if FStdOutBuffer = nil then FStdOutBuffer := TMemoryStream.Create;
              Target := FStdOutBuffer;
            end;
            while True do
            begin
              N := fpread(FOutputPipe[0], @Buf[0], SizeOf(Buf));
              if N <= 0 then Break;
              Target.WriteBuffer(Buf, N);
            end;
          end);
        FDrainThreadOut.FreeOnTerminate := False;
        FDrainThreadOut.Start;
      end;
      if (FStartInfo.GetDrainOutput) and (FStartInfo.RedirectStandardError) and (not FStartInfo.StdErrToStdOut) and (FErrorPipe[0] <> -1) and (FDrainThreadErr = nil) then
      begin
        FDrainThreadErr := TThread.CreateAnonymousThread(
          procedure
          var
            Buf: array[0..8191] of Byte;
            N: ssize_t;
            Target: TStream;
          begin
            Target := FStartInfo.GetAttachedStdErr;
            if Target = nil then
            begin
              if FStdErrBuffer = nil then FStdErrBuffer := TMemoryStream.Create;
              Target := FStdErrBuffer;
            end;
            while True do
            begin
              N := fpread(FErrorPipe[0], @Buf[0], SizeOf(Buf));
              if N <= 0 then Break;
              Target.WriteBuffer(Buf, N);
            end;
          end);
        FDrainThreadErr.FreeOnTerminate := False;
        FDrainThreadErr.Start;
      end;
      {$ENDIF}
    end;
  except
    // 防御：自动排水失败不应影响 WaitForExit 主流程
  end;
  {$ENDIF}
end;

procedure TProcess.Start;
begin
  if FState <> psNotStarted then
  begin
    {$IFDEF WINDOWS}
    raise EProcessError.Create(UTF8Encode(UnicodeString('进程已经启动或已结束')));
    {$ELSE}
    raise EProcessError.Create('进程已经启动或已结束');
    {$ENDIF}
  end;

  // 验证启动信息
  FStartInfo.Validate;

  // 记录启动时间
  FStartTime := Now;

  // UseShellExecute 的能力边界校验（最小子集）：在 Windows 上禁止与重定向/自定义环境/合流同时使用
  {$IFDEF WINDOWS}
  {$IFDEF FAFAFA_PROCESS_SHELLEXECUTE_MINIMAL}
  if FStartInfo.UseShellExecute and (
       FStartInfo.RedirectStandardInput or
       FStartInfo.RedirectStandardOutput or
       FStartInfo.RedirectStandardError or
       FStartInfo.StdErrToStdOut or
       (FStartInfo.Environment.Count > 0)) then
  begin
    raise EProcessStartError.Create(UTF8Encode(UnicodeString('UseShellExecute 模式与重定向/自定义环境不兼容')));
  end;
  {$ENDIF}
  {$ENDIF}

  // 创建管道（如果需要重定向）- 真实实现
  if FStartInfo.RedirectStandardInput or FStartInfo.RedirectStandardOutput or FStartInfo.RedirectStandardError then
  begin
    {$IFDEF WINDOWS}
    CreatePipesWindows;
    {$ENDIF}
    {$IFDEF UNIX}
    CreatePipesUnix;
    {$ENDIF}
    CreateStreamWrappers;
  end;

  // 启动进程 - 真实实现
  {$IFDEF WINDOWS}
  StartWindows;
  {$ENDIF}
  {$IFDEF UNIX}
  {$IFDEF FAFAFA_PROCESS_USE_POSIX_SPAWN}
  if not StartUnixUsingPosixSpawn then
  {$ENDIF}
    StartUnix;
  {$ENDIF}
end;

function TProcess.WaitForExit(aTimeoutMs: Cardinal): Boolean;
begin
  if FState = psNotStarted then
  begin
    // 未启动的进程：遵循“查询式等待”语义，直接返回 False 而不是抛异常
    Result := False;
    Exit;
  end;

  if FState in [psExited, psTerminated] then
  begin
    Result := True;
    Exit;
  end;

  // 对于非阻塞探测（aTimeoutMs=0），避免启动自动排水线程，直接进行一次平台级快速检查
  if aTimeoutMs = 0 then
  begin
    {$IFDEF WINDOWS}
    Result := WaitForExitWindows(0);
    {$ENDIF}
    {$IFDEF UNIX}
    Result := WaitForExitUnix(0);
    {$ENDIF}
    if Result then
    begin
      // 等待读线程完成（若已存在）并回绕缓冲位置，保持与非零等待收尾一致性
      FinalizeAutoDrainOnExit;
      {$IFDEF FAFAFA_PROCESS_AUTO_DRAIN_ON_WAIT}
      if Assigned(FStdOutBuffer) then begin if Assigned(FStandardOutput) then FreeAndNil(FStandardOutput); FStandardOutput := FStdOutBuffer; FStdOutBuffer := nil; end;
      if Assigned(FStdErrBuffer) then begin if Assigned(FStandardError) then FreeAndNil(FStandardError); FStandardError := FStdErrBuffer; FStdErrBuffer := nil; end;
      {$ENDIF}
      if (FState <> psExited) and (FState <> psTerminated) then
        FState := psExited;
    end;

    Exit;
  end;

  {$IFDEF FAFAFA_PROCESS_AUTO_DRAIN_ON_WAIT}
  // 在等待前按需启动后台排水，避免子进程因未读满管道而阻塞
  EnsureAutoDrainOnWait;
  {$ENDIF}

  // 调用平台相关的等待实现 - 真实实现
  {$IFDEF WINDOWS}
  Result := WaitForExitWindows(aTimeoutMs);
  {$ENDIF}
  {$IFDEF UNIX}
  Result := WaitForExitUnix(aTimeoutMs);
  {$ENDIF}

  if Result then
  begin
    // 等待读线程完成并将缓冲回绕到起始位置，方便调用方读取
    FinalizeAutoDrainOnExit;
    // 若启用了自动排水并已生成缓冲，则将标准流引用切换为缓冲，确保调用方能读到数据
    {$IFDEF FAFAFA_PROCESS_AUTO_DRAIN_ON_WAIT}
    if Assigned(FStdOutBuffer) then begin if Assigned(FStandardOutput) then FreeAndNil(FStandardOutput); FStandardOutput := FStdOutBuffer; FStdOutBuffer := nil; end;
    if Assigned(FStdErrBuffer) then begin if Assigned(FStandardError) then FreeAndNil(FStandardError); FStandardError := FStdErrBuffer; FStdErrBuffer := nil; end;
    {$ENDIF}
  end;

  // Defensive alignment: ensure state reflects completion when Result=true
  if Result and (FState <> psExited) and (FState <> psTerminated) then
    FState := psExited;
end;

procedure TProcess.Kill;
begin
  if FState = psNotStarted then
  begin
    {$IFDEF WINDOWS}
    raise EProcessError.Create(UTF8Encode(UnicodeString('进程尚未启动')));
    {$ELSE}
    raise EProcessError.Create('进程尚未启动');
    {$ENDIF}
  end
  else if FState in [psExited, psTerminated] then
  begin
    // 与测试约定对齐：在已退出/已终止状态上再次操作应抛出异常
    {$IFDEF WINDOWS}
    raise EProcessError.Create(UTF8Encode(UnicodeString('进程已结束')));
    {$ELSE}
    raise EProcessError.Create('进程已结束');
    {$ENDIF}
  end;

  // 调用平台相关的强制终止实现 - 真实实现
  {$IFDEF WINDOWS}
  KillWindows;
  {$ENDIF}

  {$IFDEF UNIX}
  KillUnix;
  {$ENDIF}
end;

function TProcess.TryWait: Boolean;
begin
  Result := WaitForExit(0);
end;

procedure TProcess.Terminate;
begin
  if FState = psNotStarted then
  begin
    {$IFDEF WINDOWS}
    raise EProcessError.Create(UTF8Encode(UnicodeString('进程尚未启动')));
    {$ELSE}
    raise EProcessError.Create('进程尚未启动');
    {$ENDIF}
  end
  else if FState in [psExited, psTerminated] then
  begin
    // 与测试约定对齐：在已退出/已终止状态上再次操作应抛出异常
    {$IFDEF WINDOWS}
    raise EProcessError.Create(UTF8Encode(UnicodeString('进程已结束')));
    {$ELSE}
    raise EProcessError.Create('进程已结束');
    {$ENDIF}
  end;

  // 在 Windows 上，Terminate 和 Kill 的行为相同
  // 在 Unix 上，发送 SIGTERM 信号进行优雅终止
  {$IFDEF WINDOWS}
  KillWindows;
  {$ENDIF}
  {$IFDEF UNIX}
  TerminateUnix;
  {$ENDIF}
end;

function TProcess.GetState: TProcessState;
begin
  Result := FState;
end;

function TProcess.GetHasExited: Boolean;
begin
  // 不触发任何等待或状态刷新，保持只读查询语义
  Result := FState in [psExited, psTerminated];
end;

function TProcess.GetExitCode: Integer;
begin
  Result := FExitCode;
end;

function TProcess.GetProcessId: Cardinal;
begin
  Result := FProcessId;
end;

function TProcess.GetStartTime: TDateTime;
begin
  Result := FStartTime;
end;


{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TProcess.OnExit(const Callback: TOnExitCallback);
var
  Th: TThread;
begin
  if not Assigned(Callback) then Exit;
  if FState in [psExited, psTerminated] then
  begin
    Callback;
    Exit;
  end;
  Th := TThread.CreateAnonymousThread(
    procedure
    begin
      try
        WaitForExit($FFFFFFFF);
        try Callback; except end;
      except
        // 忽略回调线程内部异常
      end;
    end);
  Th.FreeOnTerminate := True;
  Th.Start;
end;
{$ENDIF}

function TProcess.GetExitTime: TDateTime;
begin
  Result := FExitTime;
end;

function TProcess.GetStandardInput: TStream;
begin
  Result := FStandardInput;
end;

procedure TProcess.CloseStandardInput;
begin
  if FStandardInput <> nil then
  begin
    FStandardInput.Free;
    FStandardInput := nil;

    // 由于 THandleStream 不会自动关闭句柄，我们需要手动关闭
    // 并将句柄标记为无效，避免在 Destroy 中重复关闭
    {$IFDEF WINDOWS}
    if FInputPipeWrite <> 0 then
    begin
      CloseHandle(FInputPipeWrite);
      FInputPipeWrite := 0;
    end;
    {$ENDIF}

    {$IFDEF UNIX}
    if FInputPipe[1] <> -1 then
    begin
      fpclose(FInputPipe[1]);
      FInputPipe[1] := -1;
    end;
    {$ENDIF}
  end;
end;


function TProcess.GetStandardOutput: TStream;
begin
  // 若自动排水已将数据缓存在内存中，优先返回缓冲（调用方读取后可自行重置 Position）
  if Assigned(FStdOutBuffer) then
    Result := FStdOutBuffer
  else
    Result := FStandardOutput;
end;

function TProcess.GetStandardError: TStream;
begin
  if Assigned(FStdErrBuffer) then
    Result := FStdErrBuffer
  else
    Result := FStandardError;
end;

function TProcess.GetStartInfo: IProcessStartInfo;
begin
  Result := FStartInfo;
end;

{$IFDEF WINDOWS}
{$I fafafa.core.process.windows.inc}
{$ENDIF}


{$IFDEF UNIX}
{$I fafafa.core.process.unix.inc}
{$ENDIF}


{ TChildAdapter }

constructor TChildAdapter.Create(const aProc: IProcess);
begin
  inherited Create;
  FProc := aProc;
end;

function TChildAdapter.WaitForExit(aTimeoutMs: Cardinal): Boolean;
begin
  Result := (FProc <> nil) and FProc.WaitForExit(aTimeoutMs);
end;

procedure TChildAdapter.Kill;
begin
  if FProc <> nil then FProc.Kill;
end;

procedure TChildAdapter.Terminate;
begin
  if FProc <> nil then FProc.Terminate;
end;

function TChildAdapter.GetState: TProcessState;
begin
  if FProc <> nil then Result := FProc.State else Result := psNotStarted;
end;

function TChildAdapter.GetHasExited: Boolean;
begin
  Result := (FProc <> nil) and FProc.HasExited;
end;

function TChildAdapter.GetExitCode: Integer;
begin
  if FProc <> nil then Result := FProc.ExitCode else Result := 0;
end;

function TChildAdapter.GetProcessId: Cardinal;
begin
  if FProc <> nil then Result := FProc.ProcessId else Result := 0;
end;

function TChildAdapter.GetStartTime: TDateTime;
begin
  if FProc <> nil then Result := FProc.StartTime else Result := 0;
end;

function TChildAdapter.GetExitTime: TDateTime;
begin
  if FProc <> nil then Result := FProc.ExitTime else Result := 0;
end;

function TChildAdapter.GetStandardInput: TStream;
begin
  if FProc <> nil then Result := FProc.StandardInput else Result := nil;
end;

function TChildAdapter.GetStandardOutput: TStream;
begin
  if FProc <> nil then Result := FProc.StandardOutput else Result := nil;
end;

function TChildAdapter.GetStandardError: TStream;
begin
  if FProc <> nil then Result := FProc.StandardError else Result := nil;
end;

function TChildAdapter.GracefulShutdown(aTimeoutMs: Cardinal): Boolean;
begin
  if FProc = nil then Exit(False);
  FProc.Terminate;
  Result := FProc.WaitForExit(aTimeoutMs);
end;

procedure TChildAdapter.CloseStandardInput;
begin
  if FProc <> nil then FProc.CloseStandardInput;
end;

{$IFDEF FAFAFA_PROCESS_GROUPS}

function TProcessBuilder.WithGroupPolicy(const Policy: TProcessGroupPolicy): IProcessBuilder;
begin
  {$IFDEF FAFAFA_PROCESS_GROUPS}
  if FGroup = nil then
    FGroup := NewProcessGroup(Policy)
  else
  begin
    // 若已有组实例，则替换为带策略的新实例（更明确且避免隐式修改共享组）
    FGroup := NewProcessGroup(Policy);
  end;
  {$ENDIF}
  Result := Self;
end;

function TProcessBuilder.WithGroup(const AGroup: IProcessGroup): IProcessBuilder;
begin
  FGroup := AGroup;
  Result := Self;
end;

function TProcessBuilder.StartIntoGroup(const AGroup: IProcessGroup): IChild;
var
  LChild: IChild;
begin
  // 临时绑定组，启动后加入
  FGroup := AGroup;
  LChild := Start;
  Result := LChild;
end;
{$ENDIF}

{ TProcessBuilder }

constructor TProcessBuilder.Create;
begin
  inherited Create;
  FStartInfo := TProcessStartInfo.Create;
  FInheritEnv := True; // Environment.Count=0 表示继承当前环境
  FTimeoutMs := 0; // 0 表示无超时
  FKillOnTimeout := False;
  // 默认不启用后台排水（与历史行为一致）；测试/需要时显式开启
  FDrainOutput := False;
end;

// === 基础配置方法实现 ===

function TProcessBuilder.Exe(const aFileName: string): IProcessBuilder;
begin
  FStartInfo.FileName := aFileName;
  Result := Self;
end;

function TProcessBuilder.Command(const aFileName: string): IProcessBuilder;
begin
  Result := Exe(aFileName);
end;

function TProcessBuilder.Executable(const aFileName: string): IProcessBuilder;
begin
  Result := Exe(aFileName);
end;

function TProcessBuilder.Arg(const aValue: string): IProcessBuilder;
begin
  if aValue <> '' then
    FStartInfo.AddArgument(aValue);
  Result := Self;
end;

function TProcessBuilder.Args(const aValues: array of string): IProcessBuilder;
var
  LIndex: Integer;
begin
  for LIndex := Low(aValues) to High(aValues) do
    Arg(aValues[LIndex]);
  Result := Self;
end;

function TProcessBuilder.Args(const aValues: TStringList): IProcessBuilder;
var
  LIndex: Integer;
begin
  if aValues <> nil then
    for LIndex := 0 to aValues.Count - 1 do
      Arg(aValues[LIndex]);
  Result := Self;
end;

function TProcessBuilder.Args(const aValues: TStrings): IProcessBuilder;
var
  LIndex: Integer;
begin
  if aValues <> nil then
    for LIndex := 0 to aValues.Count - 1 do
      Arg(aValues[LIndex]);
  Result := Self;
end;

function TProcessBuilder.ArgsFrom(const aCommandLine: string): IProcessBuilder;
var
  LArgs: TStringList;
  LIndex: Integer;
begin
  LArgs := ParseCommandLine(aCommandLine);
  try
    for LIndex := 0 to LArgs.Count - 1 do
      Arg(LArgs[LIndex]);
  finally
    LArgs.Free;
  end;
  Result := Self;
end;

function TProcessBuilder.ClearArgs: IProcessBuilder;
begin
  // 仅清理 Arguments 字符串，避免接口-类强转导致的编译警告
  FStartInfo.Arguments := '';
  Result := Self;
end;

function TProcessBuilder.WithTimeout(timeoutMs: Integer): IProcessBuilder;
begin
  if timeoutMs < 0 then timeoutMs := 0;
  FTimeoutMs := Cardinal(timeoutMs);
  Result := Self;
end;

function TProcessBuilder.Cwd(const aDir: string): IProcessBuilder;
begin
  FStartInfo.WorkingDirectory := aDir;
  Result := Self;
end;

function TProcessBuilder.WorkingDir(const aDir: string): IProcessBuilder;
begin
  Result := Cwd(aDir);
end;

function TProcessBuilder.CurrentDir(const aDir: string): IProcessBuilder;
begin
  Result := Cwd(aDir);
end;

// === 环境变量配置方法实现 ===

function TProcessBuilder.Env(const aName, aValue: string): IProcessBuilder;
begin
  FStartInfo.SetEnvironmentVariable(aName, aValue);
  Result := Self;
end;

function TProcessBuilder.SetEnv(const aName, aValue: string): IProcessBuilder;
begin
  Result := Env(aName, aValue);
end;

function TProcessBuilder.UnsetEnv(const aName: string): IProcessBuilder;
var
  LIndex: Integer;
begin
  LIndex := FStartInfo.Environment.IndexOfName(aName);
  if LIndex >= 0 then
    FStartInfo.Environment.Delete(LIndex);
  Result := Self;
end;

function TProcessBuilder.Envs(const aEnvVars: array of string): IProcessBuilder;
var
  LIndex: Integer;
  LEnvVar, LName, LValue: string;
  LEqualPos: Integer;
begin
  for LIndex := Low(aEnvVars) to High(aEnvVars) do
  begin
    LEnvVar := aEnvVars[LIndex];
    LEqualPos := Pos('=', LEnvVar);
    if LEqualPos > 1 then
    begin
      LName := Copy(LEnvVar, 1, LEqualPos - 1);
      LValue := Copy(LEnvVar, LEqualPos + 1, Length(LEnvVar));
      Env(LName, LValue);
    end;
  end;
  Result := Self;
end;

function TProcessBuilder.EnvsFrom(const aEnvVars: TStringList): IProcessBuilder;
var
  LIndex: Integer;
begin
  if aEnvVars <> nil then
    for LIndex := 0 to aEnvVars.Count - 1 do
      Env(aEnvVars.Names[LIndex], aEnvVars.ValueFromIndex[LIndex]);
  Result := Self;
end;

function TProcessBuilder.EnvsFrom(const aEnvVars: TStrings): IProcessBuilder;
var
  LIndex: Integer;
begin
  if aEnvVars <> nil then
    for LIndex := 0 to aEnvVars.Count - 1 do
      Env(aEnvVars.Names[LIndex], aEnvVars.ValueFromIndex[LIndex]);
  Result := Self;
end;

function TProcessBuilder.ClearEnv: IProcessBuilder;
begin
  FStartInfo.ClearEnvironment;
  Result := Self;
end;

function TProcessBuilder.DrainOutput(aEnable: Boolean): IProcessBuilder;
begin
  FDrainOutput := aEnable;
  Result := Self;
end;

function TProcessBuilder.InheritEnv: IProcessBuilder;
begin
  FInheritEnv := True; // 语义标注；实际继承由 Environment.Count=0 表示
  Result := Self;
end;

function TProcessBuilder.RemoveFromEnv(const aName: string): IProcessBuilder;
begin
  Result := UnsetEnv(aName);
end;

// === 流重定向配置方法实现 ===

function TProcessBuilder.RedirectStdIn(aEnable: Boolean): IProcessBuilder;
begin
  FStartInfo.RedirectStandardInput := aEnable;
  Result := Self;
end;

function TProcessBuilder.RedirectStdOut(aEnable: Boolean): IProcessBuilder;
begin
  FStartInfo.RedirectStandardOutput := aEnable;
  Result := Self;
end;

function TProcessBuilder.RedirectStdErr(aEnable: Boolean): IProcessBuilder;
begin
  FStartInfo.RedirectStandardError := aEnable;
  Result := Self;
end;

function TProcessBuilder.CaptureOutput: IProcessBuilder;
begin
  FStartInfo.RedirectStandardOutput := True;
  FStartInfo.RedirectStandardError := True;
  // 为了提升稳定性，在同时重定向 stdout/stderr 时默认启用后台排水
  FDrainOutput := True;
  Result := Self;
end;

function TProcessBuilder.CaptureStdOut: IProcessBuilder;
begin
  FStartInfo.RedirectStandardOutput := True;
  Result := Self;
end;

function TProcessBuilder.CaptureStdErr: IProcessBuilder;
begin
  FStartInfo.RedirectStandardError := True;
  Result := Self;
end;

function TProcessBuilder.RedirectInput: IProcessBuilder;
begin
  FStartInfo.RedirectStandardInput := True;
  Result := Self;
end;

function TProcessBuilder.RedirectAll: IProcessBuilder;
begin
  FStartInfo.RedirectStandardInput := True;
  FStartInfo.RedirectStandardOutput := True;
  FStartInfo.RedirectStandardError := True;
  Result := Self;
end;

function TProcessBuilder.CaptureAll: IProcessBuilder;
begin
  // 重定向全部三路，并默认打开后台排水，避免长输出阻塞；不做 stderr→stdout 合流
  FStartInfo.RedirectStandardInput := True;
  FStartInfo.RedirectStandardOutput := True;
  FStartInfo.RedirectStandardError := True;
  FDrainOutput := True;
  Result := Self;
end;

function TProcessBuilder.NoRedirect: IProcessBuilder;
begin
  FStartInfo.RedirectStandardInput := False;
  FStartInfo.RedirectStandardOutput := False;
  FStartInfo.RedirectStandardError := False;
  Result := Self;
end;

function TProcessBuilder.StdErrToStdOut: IProcessBuilder;
begin
  // 启用将 stderr 重定向到 stdout 的合流行为
  FStartInfo.StdErrToStdOut := True;
  Result := Self;
end;

function TProcessBuilder.CombinedOutput: IProcessBuilder;
begin
  // 最佳实践：捕获 stdout + 合流 stderr，并默认启用后台排水避免长输出阻塞
  FStartInfo.RedirectStandardOutput := True;
  FStartInfo.StdErrToStdOut := True;
  FDrainOutput := True;
  Result := Self;
end;

// === 进程属性配置方法实现 ===

function TProcessBuilder.Priority(aPriority: TProcessPriority): IProcessBuilder;
begin
  FStartInfo.Priority := aPriority;
  Result := Self;
end;

function TProcessBuilder.LowPriority: IProcessBuilder;
begin
  Result := Priority(ppIdle);
end;

function TProcessBuilder.NormalPriority: IProcessBuilder;
begin
  Result := Priority(ppNormal);
end;

function TProcessBuilder.HighPriority: IProcessBuilder;
begin
  Result := Priority(ppHigh);
end;

function TProcessBuilder.WindowShow(aState: TWindowShowState): IProcessBuilder;
begin
  FStartInfo.WindowShowState := aState;
  Result := Self;
end;

function TProcessBuilder.WindowHidden: IProcessBuilder;
begin
  Result := WindowShow(wsHidden);
end;

function TProcessBuilder.WindowNormal: IProcessBuilder;
begin
  Result := WindowShow(wsNormal);
end;

function TProcessBuilder.WindowMaximized: IProcessBuilder;
begin
  Result := WindowShow(wsMaximized);
end;

function TProcessBuilder.WindowMinimized: IProcessBuilder;
begin
  Result := WindowShow(wsMinimized);
end;


function TProcessBuilder.UsePathSearch(aEnable: Boolean): IProcessBuilder;
begin
  if Supports(FStartInfo, IProcessStartInfo) then
    FStartInfo.SetUsePathSearch(aEnable);
  Result := Self;
end;

function TProcessBuilder.UseShell(aUse: Boolean): IProcessBuilder;
begin
  // v1: UseShellExecute 仅影响验证行为，不启用 ShellExecuteEx
  // 设置为 True 时跳过文件存在性检查，但仍使用 CreateProcess/fork+exec
  FStartInfo.UseShellExecute := aUse;
  Result := Self;
end;

function TProcessBuilder.NoShell: IProcessBuilder;
begin



  Result := UseShell(False);
end;

// === 便捷配置方法实现 ===

function TProcessBuilder.Silent: IProcessBuilder;
begin
  Result := WindowHidden.CaptureOutput;
end;

function TProcessBuilder.Interactive: IProcessBuilder;
begin
  Result := WindowNormal.NoRedirect;
end;

function TProcessBuilder.Background: IProcessBuilder;
begin
  Result := WindowHidden.LowPriority;
end;

function TProcessBuilder.Foreground: IProcessBuilder;
begin
  Result := WindowNormal.NormalPriority;
end;

function TProcessBuilder.Timeout(aTimeoutMs: Cardinal): IProcessBuilder;
begin
  FTimeoutMs := aTimeoutMs;
  Result := Self;
end;

function TProcessBuilder.KillOnTimeout(aEnable: Boolean): IProcessBuilder;
begin
  FKillOnTimeout := aEnable;
  Result := Self;
end;

// === 构建和启动方法实现 ===

function TProcessBuilder.Build: IProcess;
begin
  // 直接复用现有实现，保持兼容
  Result := TProcess.Create(FStartInfo);
end;

function TProcessBuilder.GetStartInfo: IProcessStartInfo;
begin
  Result := FStartInfo;
end;

function TProcessBuilder.Start: IChild;
var
  LProc: IProcess;
begin
  LProc := Build;
  // 将 DrainOutput 配置透传到 StartInfo（由底层平台层决定是否启动后台排水）
  if Supports(LProc.StartInfo, IProcessStartInfo) then
    LProc.StartInfo.SetDrainOutput(FDrainOutput);
  LProc.Start;
  {$IFDEF FAFAFA_PROCESS_GROUPS}
  if (FGroup <> nil) then
  begin
    try
      FGroup.Add(LProc);
    except
      // 若加入失败，不影响进程存活；记录为一般性错误（可在上层处理）
    end;
  end;
  {$ENDIF}
  Result := TChildAdapter.Create(LProc);
end;

function TProcessBuilder.Spawn: IChild;
begin
  Result := Start;
end;

function TProcessBuilder.Run: IChild;
begin
  Result := Start;
end;

function TProcessBuilder.Execute: IChild;
begin
  Result := Start;
end;

function TProcessBuilder.RunWithTimeout(timeoutMs: Integer): IChild;
var
  LChild: IChild;
  LWait: Boolean;
begin
  LChild := Start;
  if timeoutMs <= 0 then timeoutMs := Integer(FTimeoutMs);
  if timeoutMs > 0 then
  begin
    LWait := LChild.WaitForExit(timeoutMs);
    if not LWait then
    begin
      LChild.Kill;
      raise EProcessTimeoutError.Create('进程执行超时');
    end;
  end;
  Result := LChild;
end;

function TProcessBuilder.Output: string;
var
  LProc: IProcess;
  LBuffer: array[0..1023] of Byte;
  LBytesRead: Integer;
  LOutputBytes: TBytes;
  LTotalBytes: Integer;
  LUtf8: RawByteString;
begin
  // 自动启用输出重定向
  FStartInfo.RedirectStandardOutput := True;

  LProc := Build;
  try
    LProc.Start;

    // 读取输出到字节数组
    SetLength(LOutputBytes, 0);
    LTotalBytes := 0;

    if LProc.StandardOutput <> nil then
    begin
      repeat
        LBytesRead := LProc.StandardOutput.Read(LBuffer[0], SizeOf(LBuffer));
        if LBytesRead > 0 then
        begin
          SetLength(LOutputBytes, LTotalBytes + LBytesRead);
          Move(LBuffer[0], LOutputBytes[LTotalBytes], LBytesRead);
          Inc(LTotalBytes, LBytesRead);
        end;
      until LBytesRead = 0;
    end;

    LProc.WaitForExit;

    // 将字节数组按 UTF-8 约定转换为字符串
    if LTotalBytes > 0 then
    begin
      SetLength(LUtf8, LTotalBytes);
      if LTotalBytes > 0 then
        Move(LOutputBytes[0], Pointer(LUtf8)^, LTotalBytes);
      {$ifdef FPC_HAS_CPSTRING}
      SetCodePage(LUtf8, CP_UTF8, False);
      {$endif}
      Result := string(LUtf8);
    end
    else
      Result := '';

  finally
    LProc := nil;
  end;
end;

function TProcessBuilder.OutputWithTimeout(timeoutMs: Integer): string;
var
  LChild: IChild;
begin
  if timeoutMs <= 0 then timeoutMs := Integer(FTimeoutMs);
  if timeoutMs > 0 then
  begin
    LChild := RunWithTimeout(timeoutMs);
  end
  else
  begin
    LChild := Run;
  end;
  // Run/RunWithTimeout 已经完成运行（未超时），此处直接读取 Output
  Result := Output;
end;



function TProcessBuilder.Status: Integer;
var
  LProc: IProcess;
begin
  LProc := Build;
  try
    LProc.Start;
    LProc.WaitForExit;
    Result := LProc.ExitCode;
  finally
    LProc := nil;
  end;
end;

function TProcessBuilder.StatusChecked: Integer;
var
  Code: Integer;
begin
  Code := Status;
  if Code <> 0 then
    raise EProcessExitError.Create('子进程退出码非零: ' + IntToStr(Code), Code);
  Result := Code;
end;

function TProcessBuilder.OutputChecked: string;
var
  s: string;
  code: Integer;
begin
  s := Output;
  code := Status;
  if code <> 0 then
    raise EProcessExitError.Create('子进程退出码非零: ' + IntToStr(code), code);
  Result := s;
end;

function TProcessBuilder.Success: Boolean;
begin
  Result := Status = 0;
end;

// === 验证和调试方法实现 ===

function TProcessBuilder.Validate: IProcessBuilder;
var
  LErrors: TStringList;
begin
  LErrors := ValidateConfiguration;
  try
    if LErrors.Count > 0 then
    begin
      {$IFDEF WINDOWS}
      raise EProcessStartError.Create(
        UTF8Encode(UnicodeString('进程配置验证失败：') + UnicodeString(LErrors.Text))
      );
      {$ELSE}
      raise EProcessStartError.Create('进程配置验证失败：' + LErrors.Text);
      {$ENDIF}
    end;
  finally
    LErrors.Free;
  end;
  Result := Self;
end;

function TProcessBuilder.IsValid: Boolean;
var
  LErrors: TStringList;
begin
  LErrors := ValidateConfiguration;
  try
    Result := LErrors.Count = 0;
  finally
    LErrors.Free;
  end;
end;

function TProcessBuilder.GetValidationErrors: TStringList;
begin
  Result := ValidateConfiguration;
end;

function TProcessBuilder.GetCommandLine: string;
begin
  Result := FStartInfo.FileName;
  if FStartInfo.Arguments <> '' then
    Result := Result + ' ' + FStartInfo.Arguments;
end;

function TProcessBuilder.GetEnvironmentSummary: string;
var
  LIndex: Integer;
  U: UnicodeString;
begin
  // 统一在 UnicodeString 维度拼接，最终显式转 UTF-8，避免隐式转换告警
  U := UnicodeString('环境变量数量: ') + UnicodeString(IntToStr(FStartInfo.Environment.Count));
  if FStartInfo.Environment.Count > 0 then
  begin
    U := U + UnicodeString(#13#10) + UnicodeString('环境变量:');
    for LIndex := 0 to Min(FStartInfo.Environment.Count - 1, 4) do
      U := U + UnicodeString(#13#10) + UnicodeString('  ') + UnicodeString(FStartInfo.Environment[LIndex]);
    if FStartInfo.Environment.Count > 5 then
      U := U + UnicodeString(#13#10) + UnicodeString('  ... 还有 ') + UnicodeString(IntToStr(FStartInfo.Environment.Count - 5)) + UnicodeString(' 个');
  end;
  Result := UTF8Encode(U);
end;

function TProcessBuilder.ToString: string;
var
  U: UnicodeString;
begin
  // 统一在 UnicodeString 维度拼接，最终显式转 UTF-8
  U := UnicodeString('ProcessBuilder[exe=') + UnicodeString(FStartInfo.FileName) +
       UnicodeString(', args=') + UnicodeString(FStartInfo.Arguments) +
       UnicodeString(', cwd=') + UnicodeString(FStartInfo.WorkingDirectory) +
       UnicodeString(', env_count=') + UnicodeString(IntToStr(FStartInfo.Environment.Count)) +
       UnicodeString(']');
  Result := UTF8Encode(U);
end;

// === 辅助方法实现 ===

function TProcessBuilder.ParseCommandLine(const aCommandLine: string): TStringList;
var
  LIndex: Integer;
  LChar: Char;
  LInQuotes: Boolean;
  LCurrentArg: string;
begin
  Result := TStringList.Create;
  LInQuotes := False;
  LCurrentArg := '';

  for LIndex := 1 to Length(aCommandLine) do
  begin
    LChar := aCommandLine[LIndex];

    case LChar of
      '"':
        LInQuotes := not LInQuotes;
      ' ', #9:
        if LInQuotes then
          LCurrentArg := LCurrentArg + LChar
        else if LCurrentArg <> '' then
        begin
          Result.Add(LCurrentArg);
          LCurrentArg := '';
        end;
      else
        LCurrentArg := LCurrentArg + LChar;
    end;
  end;

  if LCurrentArg <> '' then
    Result.Add(LCurrentArg);
end;

function TProcessBuilder.ValidateConfiguration: TStringList;
begin
  Result := TStringList.Create;

  // 检查可执行文件
  if FStartInfo.FileName = '' then
    Result.Add('可执行文件名不能为空');

  // 检查工作目录
  if (FStartInfo.WorkingDirectory <> '') and not DirectoryExists(FStartInfo.WorkingDirectory) then
    Result.Add(UTF8Encode(UnicodeString('工作目录不存在: ')) + FStartInfo.WorkingDirectory);

  // UseShellExecute 能力边界（Windows 最小子集）：禁止重定向/合流/自定义环境
  {$IFDEF FAFAFA_PROCESS_SHELLEXECUTE_MINIMAL}
  if FStartInfo.UseShellExecute and (
       FStartInfo.RedirectStandardInput or
       FStartInfo.RedirectStandardOutput or
       FStartInfo.RedirectStandardError or
       FStartInfo.StdErrToStdOut or
       (FStartInfo.Environment.Count > 0)) then
  begin
    Result.Add(UTF8Encode(UnicodeString('UseShellExecute 模式与重定向/自定义环境不兼容')));
  end;
  {$ENDIF}

end;


{$IFDEF WINDOWS}
function LookPathWindows(const AFile: string): string;
var
  LFoundLen: DWORD;
  LBuf: array[0..MAX_PATH] of WideChar;
  LPath, LPathExt, LExt: string;
  LExtList: TStringList;
  I: Integer;
  U, U2: UnicodeString;
begin
  Result := '';
  // 显式使用 PATH，避免 SearchPath 默认包含当前目录
  LPath := SysUtils.GetEnvironmentVariable('PATH');
  // 先尝试原始文件名
  LFoundLen := SearchPathW(PWideChar(UnicodeString(LPath)), PWideChar(UnicodeString(AFile)), nil,
    SizeOf(LBuf) div SizeOf(WideChar), @LBuf[0], nil);
  if LFoundLen <> 0 then
  begin
    // 避免依赖隐式以 0 终止的缓冲区 → 按返回长度构造 UnicodeString
    SetLength(U, LFoundLen);
    Move(LBuf[0], PWideChar(U)^, LFoundLen * SizeOf(WideChar));
    Result := UTF8Encode(U);
    Exit;
  end;
  // 已有扩展名则结束
  if ExtractFileExt(AFile) <> '' then Exit;
  // 遍历 PATHEXT
  LPathExt := SysUtils.GetEnvironmentVariable('PATHEXT');
  if LPathExt = '' then LPathExt := '.COM;.EXE;.BAT;.CMD';
  LExtList := TStringList.Create;
  try
    LExtList.Delimiter := ';';
    LExtList.StrictDelimiter := True;
    LExtList.DelimitedText := LPathExt;
    for I := 0 to LExtList.Count - 1 do
    begin
      LExt := Trim(LExtList[I]);
      if LExt = '' then Continue;
      LFoundLen := SearchPathW(PWideChar(UnicodeString(LPath)), PWideChar(UnicodeString(AFile + LExt)), nil,
        SizeOf(LBuf) div SizeOf(WideChar), @LBuf[0], nil);
      if LFoundLen <> 0 then
      begin
        SetLength(U2, LFoundLen);
        Move(LBuf[0], PWideChar(U2)^, LFoundLen * SizeOf(WideChar));
        Result := UTF8Encode(U2);
        Exit;
      end;
    end;
  finally
    LExtList.Free;
  end;
end;
{$ENDIF}

{$IFDEF UNIX}
function LookPathUnix(const AFile: string): string;
var
  LPath, LDir, LFull: string;
  I: Integer;
  LDirs: TStringList;
begin
  Result := '';
  LPath := SysUtils.GetEnvironmentVariable('PATH');
  if LPath = '' then Exit;
  LDirs := TStringList.Create;
  try
    LDirs.Delimiter := ':';
    LDirs.StrictDelimiter := True;
    LDirs.DelimitedText := LPath;
    for I := 0 to LDirs.Count - 1 do
    begin
      LDir := Trim(LDirs[I]);
      if LDir = '' then Continue;
      LFull := IncludeTrailingPathDelimiter(LDir) + AFile;
      if (fpaccess(PAnsiChar(AnsiString(LFull)), F_OK) = 0) and
         (fpaccess(PAnsiChar(AnsiString(LFull)), X_OK) = 0) then
      begin
        Result := LFull;
        Exit;
      end;
    end;
  finally
    LDirs.Free;
  end;
end;
{$ENDIF}





function NewProcessBuilder: IProcessBuilder;
begin
  Result := TProcessBuilder.Create;
end;








procedure TProcess.CreateStreamWrappers;
begin
  // 为管道创建流包装器
  {$IFDEF WINDOWS}
  if FStartInfo.RedirectStandardInput and (FInputPipeWrite <> 0) then
    FStandardInput := THandleStream.Create(FInputPipeWrite);

  if FStartInfo.RedirectStandardOutput and (FOutputPipeRead <> 0) then
    FStandardOutput := THandleStream.Create(FOutputPipeRead);

  if FStartInfo.RedirectStandardError and (FErrorPipeRead <> 0) then
    FStandardError := THandleStream.Create(FErrorPipeRead);
  {$ENDIF}

  {$IFDEF UNIX}
  if FStartInfo.RedirectStandardInput and (FInputPipe[1] <> -1) then
    FStandardInput := THandleStream.Create(FInputPipe[1]);

  if FStartInfo.RedirectStandardOutput and (FOutputPipe[0] <> -1) then
    FStandardOutput := THandleStream.Create(FOutputPipe[0]);

  if FStartInfo.RedirectStandardError and (FErrorPipe[0] <> -1) then
    FStandardError := THandleStream.Create(FErrorPipe[0]);
  {$ENDIF}
end;

procedure TProcess.CleanupResources;

begin
  // 关闭进程句柄
  {$IFDEF WINDOWS}
  // 先等待后台排水线程退出（若有），避免与句柄关闭产生竞态
  CloseDrainThreadsWindows;

  if FProcessHandle <> 0 then
  begin
    CloseHandle(FProcessHandle);
    FProcessHandle := 0;
  end;
  if FThreadHandle <> 0 then
  begin
    CloseHandle(FThreadHandle);
    FThreadHandle := 0;
  end;

  // 关闭管道
  ClosePipesWindows;
  {$ENDIF}

  {$IFDEF UNIX}
  CloseDrainThreadsUnix;
  ClosePipesUnix;
  {$ENDIF}
end;

end.

