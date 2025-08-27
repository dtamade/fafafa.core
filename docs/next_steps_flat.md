# fafafa 框架扁平化设计 - 下一步实施计划

> **基于现有代码结构的具体实施建议**

根据你现有的源码结构分析，制定扁平化设计的具体实施步骤。

---

## 📋 现有结构分析

### 当前文件结构 ✅

你的代码已经基本符合扁平化设计：

```
src/
├── fafafa.core.pas                          # ✅ 主入口模块
├── fafafa.core.base.pas                     # ✅ 基础设施
├── fafafa.core.mem.allocator.pas            # ✅ 内存分配器
├── fafafa.core.mem.utils.pas                # ✅ 内存工具
├── fafafa.core.collections.pas              # ✅ 集合主模块
├── fafafa.core.collections.*.pas            # ✅ 具体集合实现
├── fafafa.core.fs.pas                       # ✅ 文件系统主模块
├── fafafa.core.fs.windows.pas               # ✅ Windows实现
├── fafafa.core.fs.unix.pas                  # ✅ Unix实现
└── fafafa.core.math.pas                     # ✅ 数学工具
```

### 需要补充的模块 📝

基于扁平化设计，建议添加以下模块：

```
src/
├── fafafa.core.async.pas                    # 🆕 异步框架主模块
├── fafafa.core.async.types.pas              # 🆕 异步类型定义
├── fafafa.core.async.loop.pas               # 🆕 事件循环
├── fafafa.core.async.future.pas             # 🆕 Future/Promise
├── fafafa.core.async.work.pas               # 🆕 工作队列
├── fafafa.core.fs.types.pas                 # 🆕 文件系统类型
├── fafafa.core.fs.sync.pas                  # 🆕 同步文件操作
├── fafafa.core.fs.async.pas                 # 🆕 异步文件操作
├── fafafa.core.thread.pas                   # 🆕 线程和并发
├── fafafa.core.json.pas                     # 🆕 JSON处理
└── fafafa.core.testing.pas                  # 🆕 测试框架
```

---

## 🚀 优先实施计划

### 第一阶段: 异步框架基础 (1-2周)

#### 1.1 创建异步类型定义

**文件**: `src/fafafa.core.async.types.pas`

```pascal
unit fafafa.core.async.types;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base;

type
  // 事件循环运行模式
  TLoopRunMode = (
    lrmDefault,    // 运行直到没有活跃句柄
    lrmOnce,       // 运行一次I/O轮询
    lrmNoWait      // 非阻塞运行
  );

  // 异步句柄状态
  THandleState = (
    hsInactive,    // 未激活
    hsActive,      // 活跃状态
    hsClosing,     // 正在关闭
    hsClosed       // 已关闭
  );

  // 异步回调类型
  TAsyncCallback = procedure of object;
  TAsyncErrorCallback = procedure(aError: Exception) of object;
  
  // 前向声明
  IEventLoop = interface;
  IAsyncHandle = interface;
  
  // Future接口
  generic IFuture<T> = interface(IInterface)
  ['{FUTURE-INTERFACE-GUID}']
    function IsCompleted: Boolean;
    function GetResult: T;
    function Then<TResult>(aFunc: specialize TFunc<T, TResult>): specialize IFuture<TResult>;
    function Catch(aHandler: TAsyncErrorCallback): specialize IFuture<T>;
    
    property Completed: Boolean read IsCompleted;
    property Result: T read GetResult;
  end;

  // 事件循环接口
  IEventLoop = interface(IInterface)
  ['{EVENT-LOOP-INTERFACE-GUID}']
    function Run(aMode: TLoopRunMode = lrmDefault): Boolean;
    procedure Stop;
    procedure QueueCallback(aCallback: TAsyncCallback);
    
    function IsRunning: Boolean;
    function IsAlive: Boolean;
    
    property Running: Boolean read IsRunning;
  end;

  // 异步句柄接口
  IAsyncHandle = interface(IInterface)
  ['{ASYNC-HANDLE-INTERFACE-GUID}']
    procedure Start;
    procedure Stop;
    procedure Close;
    
    function IsActive: Boolean;
    function IsClosing: Boolean;
    function IsClosed: Boolean;
    
    function GetLoop: IEventLoop;
    function GetState: THandleState;
    
    property Loop: IEventLoop read GetLoop;
    property State: THandleState read GetState;
  end;

implementation

end.
```

#### 1.2 创建简单的事件循环

**文件**: `src/fafafa.core.async.loop.pas`

```pascal
unit fafafa.core.async.loop;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils,
  fafafa.core.base,
  fafafa.core.collections,
  fafafa.core.async.types;

type
  // 简单的事件循环实现
  TEventLoop = class(TInterfacedObject, IEventLoop)
  private
    FRunning: Boolean;
    FStopped: Boolean;
    FCallbacks: specialize TVec<TAsyncCallback>;
    FHandles: specialize TVec<IAsyncHandle>;
  protected
    procedure ProcessCallbacks;
    procedure ProcessHandles;
  public
    constructor Create;
    destructor Destroy; override;
    
    function Run(aMode: TLoopRunMode = lrmDefault): Boolean;
    procedure Stop;
    procedure QueueCallback(aCallback: TAsyncCallback);
    
    // 句柄管理
    procedure RegisterHandle(aHandle: IAsyncHandle);
    procedure UnregisterHandle(aHandle: IAsyncHandle);
    
    function IsRunning: Boolean;
    function IsAlive: Boolean;
    
    property Running: Boolean read IsRunning;
  end;

// 便利函数
function CreateEventLoop: IEventLoop;

implementation

constructor TEventLoop.Create;
begin
  inherited Create;
  FRunning := False;
  FStopped := False;
  FCallbacks := specialize TVec<TAsyncCallback>.Create;
  FHandles := specialize TVec<IAsyncHandle>.Create;
end;

destructor TEventLoop.Destroy;
begin
  Stop;
  FCallbacks.Free;
  FHandles.Free;
  inherited Destroy;
end;

function TEventLoop.Run(aMode: TLoopRunMode): Boolean;
begin
  FRunning := True;
  FStopped := False;
  
  try
    repeat
      ProcessCallbacks;
      ProcessHandles;
      
      // 根据模式决定是否继续
      case aMode of
        lrmOnce: Break;
        lrmNoWait: Break;
        lrmDefault: if not IsAlive or FStopped then Break;
      end;
      
      // 简单的休眠，实际实现中应该使用平台特定的I/O多路复用
      if aMode = lrmDefault then
        Sleep(1);
        
    until FStopped;
    
    Result := IsAlive;
  finally
    FRunning := False;
  end;
end;

procedure TEventLoop.Stop;
begin
  FStopped := True;
end;

procedure TEventLoop.QueueCallback(aCallback: TAsyncCallback);
begin
  FCallbacks.Add(aCallback);
end;

procedure TEventLoop.RegisterHandle(aHandle: IAsyncHandle);
begin
  FHandles.Add(aHandle);
end;

procedure TEventLoop.UnregisterHandle(aHandle: IAsyncHandle);
begin
  FHandles.Remove(aHandle);
end;

function TEventLoop.IsRunning: Boolean;
begin
  Result := FRunning;
end;

function TEventLoop.IsAlive: Boolean;
begin
  Result := (FHandles.Count > 0) or (FCallbacks.Count > 0);
end;

procedure TEventLoop.ProcessCallbacks;
var
  Callback: TAsyncCallback;
  I: Integer;
begin
  // 处理所有待执行的回调
  for I := 0 to FCallbacks.Count - 1 do
  begin
    Callback := FCallbacks[I];
    try
      Callback();
    except
      on E: Exception do
      begin
        // 记录异常，但不中断循环
        WriteLn('Callback error: ', E.Message);
      end;
    end;
  end;
  
  FCallbacks.Clear;
end;

procedure TEventLoop.ProcessHandles;
var
  Handle: IAsyncHandle;
  I: Integer;
begin
  // 处理所有活跃句柄
  for I := FHandles.Count - 1 downto 0 do
  begin
    Handle := FHandles[I];
    
    // 移除已关闭的句柄
    if Handle.IsClosed then
    begin
      FHandles.RemoveAt(I);
      Continue;
    end;
    
    // 这里应该处理句柄的I/O事件
    // 当前是简化实现
  end;
end;

function CreateEventLoop: IEventLoop;
begin
  Result := TEventLoop.Create;
end;

end.
```

#### 1.3 创建异步框架主模块

**文件**: `src/fafafa.core.async.pas`

```pascal
unit fafafa.core.async;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.async.types,
  fafafa.core.async.loop;

// 重新导出核心类型
type
  TLoopRunMode = fafafa.core.async.types.TLoopRunMode;
  THandleState = fafafa.core.async.types.THandleState;
  TAsyncCallback = fafafa.core.async.types.TAsyncCallback;
  TAsyncErrorCallback = fafafa.core.async.types.TAsyncErrorCallback;
  
  IEventLoop = fafafa.core.async.types.IEventLoop;
  IAsyncHandle = fafafa.core.async.types.IAsyncHandle;
  
  generic IFuture<T> = fafafa.core.async.types.IFuture<T>;
  
  TEventLoop = fafafa.core.async.loop.TEventLoop;

// 重新导出便利函数
function CreateEventLoop: IEventLoop;

implementation

function CreateEventLoop: IEventLoop;
begin
  Result := fafafa.core.async.loop.CreateEventLoop;
end;

end.
```

### 第二阶段: 文件系统重构 (1周)

#### 2.1 重构现有文件系统模块

基于你现有的 `fafafa.core.fs.pas`，创建类型定义模块：

**文件**: `src/fafafa.core.fs.types.pas`

```pascal
unit fafafa.core.fs.types;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.base;

type
  // 从现有的 fafafa.core.fs.pas 中提取类型定义
  TFileHandle = type Integer;
  TFileOpenFlags = set of (fofCreate, fofExclusive, fofTruncate);
  TFileOpenMode = (fomRead, fomWrite, fomReadWrite, fomAppend);
  
  // 文件信息结构
  TFileInfo = record
    Path: string;
    Size: Int64;
    IsDirectory: Boolean;
    IsReadOnly: Boolean;
    CreationTime: TDateTime;
    LastWriteTime: TDateTime;
  end;
  
  // 核心接口定义
  IFile = interface(IInterface)
  ['{FILE-INTERFACE-GUID}']
    function Read(var aBuffer; aSize: SizeUInt): SizeUInt;
    function Write(const aBuffer; aSize: SizeUInt): SizeUInt;
    function ReadString: string;
    function WriteString(const aText: string): SizeUInt;
    procedure Close;
    
    function GetSize: Int64;
    function GetPosition: Int64;
    
    property Size: Int64 read GetSize;
    property Position: Int64 read GetPosition;
  end;
  
  IFileSystem = interface(IInterface)
  ['{FILESYSTEM-INTERFACE-GUID}']
    function OpenFile(const aPath: string; aMode: TFileOpenMode; 
      aFlags: TFileOpenFlags = []): IFile;
    function FileExists(const aPath: string): Boolean;
    function GetFileInfo(const aPath: string): TFileInfo;
    function DeleteFile(const aPath: string): Boolean;
  end;

implementation

end.
```

---

## 📝 实施检查清单

### 第一阶段完成标准

- [ ] 创建 `fafafa.core.async.types.pas` - 异步类型定义
- [ ] 创建 `fafafa.core.async.loop.pas` - 基础事件循环
- [ ] 创建 `fafafa.core.async.pas` - 异步主模块
- [ ] 编写简单的异步测试用例
- [ ] 验证事件循环基本功能

### 第二阶段完成标准

- [ ] 创建 `fafafa.core.fs.types.pas` - 文件系统类型
- [ ] 重构现有文件系统代码以使用新接口
- [ ] 保持现有测试的兼容性
- [ ] 添加新的接口测试用例

### 测试验证

```pascal
// 简单的异步测试
program TestAsync;

uses
  fafafa.core.async;

begin
  var Loop := CreateEventLoop;
  
  Loop.QueueCallback(procedure
    begin
      WriteLn('Hello from async callback!');
    end);
  
  Loop.Run(lrmOnce);
  WriteLn('Event loop completed');
end.
```

这个实施计划基于你现有的代码结构，采用渐进式的方法，确保不会破坏现有功能的同时，逐步建立起完整的扁平化异步框架。
