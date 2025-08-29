# fafafa.core.sync.namedBarrier

## 概述

`fafafa.core.sync.namedBarrier` 模块提供了高性能、跨平台的命名屏障实现，支持进程间同步。该模块采用现代化的 RAII 模式设计，符合 Rust、Java、Go 等主流开发语言的最佳实践。

## 核心特性

### ✨ 现代化设计
- **RAII 模式**：自动资源管理，无需手动释放屏障
- **类型安全**：强类型接口，编译时错误检查
- **零成本抽象**：高性能实现，无运行时开销

### 🚀 高性能实现
- **Windows**：原生 Win32 Event + 共享内存实现
- **Unix/Linux**：pthread_cond + 共享内存，支持 `pthread_cond_timedwait`
- **优化的超时机制**：无轮询，真正的阻塞式超时

### 🌍 跨平台支持
- **完全隐藏平台差异**：统一的 API 接口
- **自动平台检测**：编译时选择最优实现
- **一致的行为**：跨平台相同的语义

## 架构设计

### 模块结构

```
fafafa.core.sync.namedBarrier/
├── fafafa.core.sync.namedBarrier.base.pas      # 基础接口定义
├── fafafa.core.sync.namedBarrier.windows.pas   # Windows 平台实现
├── fafafa.core.sync.namedBarrier.unix.pas      # Unix/Linux 平台实现
└── fafafa.core.sync.namedBarrier.pas           # 工厂门面层
```

## 快速开始

### 基本使用

```pascal
uses fafafa.core.sync.namedBarrier;

var
  LBarrier: INamedBarrier;
  LGuard: INamedBarrierGuard;
begin
  // 创建命名屏障，3个参与者
  LBarrier := CreateNamedBarrier('MyAppBarrier', 3);

  // RAII 模式：自动管理屏障生命周期
  LGuard := LBarrier.Wait;
  try
    // 所有参与者到达后执行的代码
    WriteLn('所有参与者已到达屏障');
  finally
    LGuard := nil; // 自动清理
  end;
end;
```

### 非阻塞尝试

```pascal
var
  LBarrier: INamedBarrier;
  LGuard: INamedBarrierGuard;
begin
  LBarrier := CreateNamedBarrier('MyAppBarrier', 2);

  // 非阻塞尝试等待屏障
  LGuard := LBarrier.TryWait;
  if Assigned(LGuard) then
  begin
    // 屏障已触发
    WriteLn('屏障已触发，继续执行');
    LGuard := nil;
  end
  else
    WriteLn('屏障未触发，其他参与者尚未到达');
end;
```

### 带超时的等待

```pascal
var
  LBarrier: INamedBarrier;
  LGuard: INamedBarrierGuard;
begin
  LBarrier := CreateNamedBarrier('MyAppBarrier', 4);

  // 等待最多 10 秒
  LGuard := LBarrier.TryWaitFor(10000);
  if Assigned(LGuard) then
  begin
    WriteLn('在超时内所有参与者到达');
    LGuard := nil;
  end
  else
    WriteLn('超时，部分参与者未到达');
end;
```

## API 参考

### 核心接口

#### INamedBarrier

主要的命名屏障接口。

```pascal
INamedBarrier = interface
  // 现代化屏障操作（推荐使用）
  function Wait: INamedBarrierGuard;                              // 阻塞等待
  function TryWait: INamedBarrierGuard;                          // 非阻塞尝试
  function TryWaitFor(ATimeoutMs: Cardinal): INamedBarrierGuard; // 带超时等待

  // 查询操作
  function GetName: string;                    // 获取屏障名称
  function GetParticipantCount: Cardinal;      // 获取参与者数量
  function GetWaitingCount: Cardinal;          // 获取当前等待者数量
  function IsSignaled: Boolean;                // 屏障是否已触发

  // 控制操作
  procedure Reset;                             // 重置屏障
  procedure Signal;                            // 手动触发屏障
end;
```

#### INamedBarrierGuard

RAII 模式的屏障守卫，析构时自动处理屏障状态。

```pascal
INamedBarrierGuard = interface
  function GetName: string;           // 获取屏障名称
  function GetParticipantCount: Cardinal; // 获取参与者数量
  function GetWaitingCount: Cardinal; // 获取当前等待者数量
  function IsLastParticipant: Boolean; // 是否为最后一个参与者
end;
```

### 工厂函数

#### 现代化接口（推荐）

```pascal
// 基本创建
function CreateNamedBarrier(const AName: string): INamedBarrier;
function CreateNamedBarrier(const AName: string; AParticipantCount: Cardinal): INamedBarrier;
function CreateNamedBarrier(const AName: string; const AConfig: TNamedBarrierConfig): INamedBarrier;

// 全局屏障
function CreateGlobalNamedBarrier(const AName: string): INamedBarrier;
function CreateGlobalNamedBarrier(const AName: string; AParticipantCount: Cardinal): INamedBarrier;

// 尝试打开现有屏障
function TryOpenNamedBarrier(const AName: string): INamedBarrier;
```

#### 配置结构

```pascal
TNamedBarrierConfig = record
  TimeoutMs: Cardinal;           // 默认超时时间（毫秒）
  RetryIntervalMs: Cardinal;     // 重试间隔（毫秒）
  MaxRetries: Integer;           // 最大重试次数
  UseGlobalNamespace: Boolean;   // 是否使用全局命名空间
  ParticipantCount: Cardinal;    // 参与者数量
  AutoReset: Boolean;            // 是否自动重置
end;
```

## 使用场景

### 1. 多进程启动同步

```pascal
// 进程 A、B、C 都需要等待彼此启动完成
var
  LBarrier: INamedBarrier;
  LGuard: INamedBarrierGuard;
begin
  LBarrier := CreateNamedBarrier('StartupSync', 3);
  
  // 执行初始化工作
  InitializeApplication;
  
  // 等待其他进程完成初始化
  LGuard := LBarrier.Wait;
  try
    // 所有进程都已初始化完成
    StartMainWork;
  finally
    LGuard := nil;
  end;
end;
```

### 2. 分阶段处理

```pascal
// 多个进程分阶段处理数据
var
  LBarrier: INamedBarrier;
  LGuard: INamedBarrierGuard;
  LPhase: Integer;
begin
  LBarrier := CreateNamedBarrier('DataProcessing', 4);
  
  for LPhase := 1 to 3 do
  begin
    WriteLn('执行阶段 ', LPhase);
    ProcessPhase(LPhase);
    
    // 等待所有进程完成当前阶段
    LGuard := LBarrier.Wait;
    try
      WriteLn('阶段 ', LPhase, ' 完成');
    finally
      LGuard := nil;
    end;
    
    // 重置屏障准备下一阶段
    if LGuard.IsLastParticipant then
      LBarrier.Reset;
  end;
end;
```

### 3. 测试同步

```pascal
// 测试中确保所有测试进程同时开始
var
  LBarrier: INamedBarrier;
  LGuard: INamedBarrierGuard;
begin
  LBarrier := CreateNamedBarrier('TestSync', GetTestProcessCount);
  
  // 准备测试环境
  SetupTestEnvironment;
  
  // 等待所有测试进程准备就绪
  LGuard := LBarrier.Wait;
  try
    // 同时开始测试
    RunTest;
  finally
    LGuard := nil;
  end;
end;
```

## 配置选项

### 默认配置

```pascal
var
  LConfig: TNamedBarrierConfig;
begin
  LConfig := DefaultNamedBarrierConfig;
  // TimeoutMs = 30000 (30秒)
  // ParticipantCount = 2
  // AutoReset = True
  // UseGlobalNamespace = False
end;
```

### 自定义配置

```pascal
var
  LConfig: TNamedBarrierConfig;
  LBarrier: INamedBarrier;
begin
  LConfig := NamedBarrierConfigWithParticipants(5);
  LConfig.TimeoutMs := 60000;      // 1分钟超时
  LConfig.AutoReset := False;      // 手动重置
  LConfig.UseGlobalNamespace := True; // 全局命名空间
  
  LBarrier := CreateNamedBarrier('CustomBarrier', LConfig);
end;
```

## 命名规则

### Windows 平台

- 名称长度限制：260 字符 (MAX_PATH)
- 支持 `Global\` 前缀：跨会话共享
- 支持 `Local\` 前缀：当前会话内共享
- 不能包含反斜杠（除前缀外）

### Unix/Linux 平台

- 名称长度限制：255 字符 (NAME_MAX)
- 自动添加路径前缀符合系统规范
- 不能包含路径分隔符
- 区分大小写

## 错误处理

### 异常类型

- `EInvalidArgument`: 无效的屏障名称或参数
- `ELockError`: 屏障操作失败
- `ETimeoutError`: 等待超时

### 常见错误

```pascal
try
  LBarrier := CreateNamedBarrier('', 2);
except
  on E: EInvalidArgument do
    WriteLn('无效参数: ', E.Message);
end;

try
  LGuard := LBarrier.TryWaitFor(5000);
  if not Assigned(LGuard) then
    raise ETimeoutError.Create('等待屏障超时');
except
  on E: ETimeoutError do
    WriteLn('超时错误: ', E.Message);
end;
```

## 性能考虑

### 最佳实践

1. **合理设置参与者数量**：避免设置过多参与者
2. **适当的超时时间**：根据实际需求设置超时
3. **及时释放守卫**：使用 RAII 模式自动管理
4. **避免频繁重置**：重置操作有一定开销

### 性能特征

- **创建开销**：中等（需要创建共享内存）
- **等待开销**：低（使用系统原语）
- **内存使用**：低（共享少量状态）
- **跨进程通信**：高效（基于系统同步原语）

## 线程安全

- ✅ 所有接口都是线程安全的
- ✅ 支持多线程同时等待
- ✅ 支持跨进程安全访问
- ✅ 自动处理竞态条件

## 平台差异

### Windows 特性
- 使用 Event + 共享内存实现
- 支持跨会话全局屏障
- 完整的遗弃状态检测

### Unix 特性
- 使用 pthread_cond + 共享内存实现
- 符合 POSIX 标准
- 支持高精度超时

## 示例代码

完整的示例代码请参考：
- `examples/fafafa.core.sync.namedBarrier/example_basic_usage.pas`
- `examples/fafafa.core.sync.namedBarrier/example_cross_process.pas`

## 相关模块

- `fafafa.core.sync.namedMutex` - 命名互斥锁
- `fafafa.core.sync.namedSemaphore` - 命名信号量
- `fafafa.core.sync.namedEvent` - 命名事件
