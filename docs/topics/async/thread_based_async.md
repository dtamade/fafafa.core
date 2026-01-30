# 基于线程池的异步设计

> **核心理念**: 摒弃libuv的事件循环模式，采用更适合FreePascal的线程池异步模式

基于你的建议，重新设计框架的异步调用风格，不依赖事件循环，而是基于线程池实现。

---

## 🎯 设计理念对比

### libuv事件循环模式 ❌

```c
// libuv的事件驱动模式
uv_loop_t* loop = uv_default_loop();
uv_fs_t req;

uv_fs_read(loop, &req, file, &buf, 1, 0, on_read_callback);
uv_run(loop, UV_RUN_DEFAULT);  // 事件循环驱动
```

**问题**:
- 单线程事件循环，无法充分利用多核
- 复杂的句柄生命周期管理
- 回调地狱，难以调试
- 不符合Pascal的编程习惯

### 线程池模式 ✅

```pascal
// 基于线程池的异步模式
var AsyncFS := CreateAsyncFileSystem;

AsyncFS.ReadTextAsync('large_file.txt')
  .Then<Integer>(function(const Content: string): Integer
    begin
      Result := ProcessContent(Content);  // 在主线程执行
    end)
  .Catch(procedure(E: Exception)
    begin
      WriteLn('Error: ', E.Message);
    end);
```

**优势**:
- 充分利用多核CPU
- 简单的线程模型，易于理解和调试
- Future/Promise模式，避免回调地狱
- 符合Pascal的面向对象编程风格

---

## 🏗️ 核心架构设计

### 1. 线程池核心

```pascal
// 线程池接口 (基于 docs/thread.md 的设计)
IThreadPool = interface(IInterface)
['{THREAD-POOL-INTERFACE-GUID}']
  // 提交无返回值任务
  procedure Execute(const aProc: TThreadProc);
  procedure Execute(const aMethod: TThreadMethod);
  
  // 提交有返回值任务，返回Future
  function Submit<T>(const aFunc: specialize TFunc<T>): specialize IFuture<T>;
  
  // 线程池管理
  function GetActiveThreadCount: Integer;
  function GetQueuedTaskCount: Integer;
  procedure Shutdown(aWaitForCompletion: Boolean = True);
  
  property ActiveThreads: Integer read GetActiveThreadCount;
  property QueuedTasks: Integer read GetQueuedTaskCount;
end;

// 线程池实现
TThreadPool = class(TInterfacedObject, IThreadPool)
private
  FCoreThreads: Integer;
  FMaxThreads: Integer;
  FKeepAliveTime: Cardinal;
  FWorkQueue: IThreadSafeQueue<IWorkItem>;
  FWorkerThreads: TList<TWorkerThread>;
  FShutdown: Boolean;
public
  constructor Create(aCoreThreads: Integer = 4; aMaxThreads: Integer = 16; 
    aKeepAliveTime: Cardinal = 60000);
  destructor Destroy; override;
  
  function Submit<T>(const aFunc: specialize TFunc<T>): specialize IFuture<T>;
  procedure Execute(const aProc: TThreadProc);
  procedure Shutdown(aWaitForCompletion: Boolean = True);
end;
```

### 2. Future/Promise实现

```pascal
// Future接口 (基于 docs/thread.md 的设计)
generic IFuture<T> = interface(IInterface)
['{FUTURE-INTERFACE-GUID}']
  function IsDone: Boolean;
  function IsCancelled: Boolean;
  function GetValue(aTimeout: Cardinal = INFINITE): T;
  procedure Cancel;
  
  // 链式调用支持
  function Then<TResult>(const aFunc: specialize TFunc<T, TResult>): specialize IFuture<TResult>;
  function Catch(const aHandler: TExceptionHandler): specialize IFuture<T>;
  function Finally(const aAction: TAction): specialize IFuture<T>;
  
  property Done: Boolean read IsDone;
  property Cancelled: Boolean read IsCancelled;
end;

// Future实现
generic TFuture<T> = class(TInterfacedObject, specialize IFuture<T>)
private
  FValue: T;
  FException: Exception;
  FCompleted: Boolean;
  FCancelled: Boolean;
  FEvent: TEvent;
  FLock: TCriticalSection;
public
  constructor Create;
  destructor Destroy; override;
  
  function IsDone: Boolean;
  function GetValue(aTimeout: Cardinal = INFINITE): T;
  procedure SetValue(const aValue: T);
  procedure SetException(aException: Exception);
  procedure Cancel;
  
  function Then<TResult>(const aFunc: specialize TFunc<T, TResult>): specialize IFuture<TResult>;
end;
```

### 3. 异步文件系统实现

```pascal
// 异步文件系统 - 完全基于线程池
TAsyncFileSystem = class(TInterfacedObject, IAsyncFileSystem)
private
  FThreadPool: IThreadPool;
  FOwnsThreadPool: Boolean;
public
  constructor Create(aThreadPool: IThreadPool = nil);
  destructor Destroy; override;
  
  // 所有异步操作都提交到线程池
  function ReadFileAsync(const aPath: string): IFuture<TBytes>;
  function WriteFileAsync(const aPath: string; const aData: TBytes): IFuture<Boolean>;
  function ReadTextAsync(const aPath: string; aEncoding: TEncoding = nil): IFuture<string>;
  function WriteTextAsync(const aPath: string; const aText: string; aEncoding: TEncoding = nil): IFuture<Boolean>;
  
  function StatAsync(const aPath: string): IFuture<TFileStat>;
  function ExistsAsync(const aPath: string): IFuture<Boolean>;
  function DeleteAsync(const aPath: string): IFuture<Boolean>;
  function CopyAsync(const aSrc, aDest: string): IFuture<Boolean>;
end;

// 实现示例
function TAsyncFileSystem.ReadTextAsync(const aPath: string; aEncoding: TEncoding): IFuture<string>;
begin
  // 捕获参数到匿名函数
  var PathCopy := aPath;
  var EncodingCopy := aEncoding;
  
  Result := FThreadPool.Submit<string>(
    function: string
    begin
      // 在工作线程中执行同步操作
      try
        Result := fs_read_text(PathCopy, EncodingCopy);
      except
        on E: Exception do
          raise;  // 异常会被Future捕获并传播
      end;
    end
  );
end;

function TAsyncFileSystem.CopyAsync(const aSrc, aDest: string): IFuture<Boolean>;
begin
  var SrcCopy := aSrc;
  var DestCopy := aDest;
  
  Result := FThreadPool.Submit<Boolean>(
    function: Boolean
    begin
      // 在工作线程中执行可能耗时的文件复制
      Result := fs_copyfile(SrcCopy, DestCopy);
    end
  );
end;
```

---

## 🚀 使用示例

### 基本异步操作

```pascal
program AsyncFileExample;

uses
  fafafa.core.fs,
  fafafa.core.thread;

begin
  // 创建异步文件系统 (使用默认线程池)
  var AsyncFS := CreateAsyncFileSystem;
  
  // 异步读取文件
  var Future := AsyncFS.ReadTextAsync('large_file.txt');
  
  // 可以在等待期间做其他工作
  WriteLn('File reading started...');
  DoOtherWork;
  
  // 获取结果 (会阻塞直到完成)
  try
    var Content := Future.GetValue(5000);  // 5秒超时
    WriteLn('File content length: ', Length(Content));
  except
    on E: Exception do
      WriteLn('Read failed: ', E.Message);
  end;
end.
```

### Future链式调用

```pascal
program AsyncChainExample;

uses
  fafafa.core.fs,
  fafafa.core.thread;

begin
  var AsyncFS := CreateAsyncFileSystem;
  
  // 链式异步操作
  AsyncFS.ReadTextAsync('input.txt')
    .Then<string>(function(const Content: string): string
      begin
        // 在主线程中处理内容
        Result := UpperCase(Content);
        WriteLn('Content processed');
      end)
    .Then<Boolean>(function(const ProcessedContent: string): Boolean
      begin
        // 异步写入处理后的内容
        var WriteFuture := AsyncFS.WriteTextAsync('output.txt', ProcessedContent);
        Result := WriteFuture.GetValue;  // 等待写入完成
      end)
    .Then<Boolean>(function(const WriteResult: Boolean): Boolean
      begin
        WriteLn('Write completed: ', WriteResult);
        Result := WriteResult;
      end)
    .Catch(procedure(E: Exception)
      begin
        WriteLn('Error in chain: ', E.Message);
      end);
  
  WriteLn('Async chain started');
  ReadLn;  // 等待用户输入，让异步操作完成
end.
```

### 并发文件操作

```pascal
program ConcurrentFileExample;

uses
  fafafa.core.fs,
  fafafa.core.thread,
  fafafa.core.collections;

begin
  var AsyncFS := CreateAsyncFileSystem;
  var Files := TVec<string>.Create;
  var Futures := TVec<IFuture<string>>.Create;
  
  // 准备文件列表
  Files.Add('file1.txt');
  Files.Add('file2.txt');
  Files.Add('file3.txt');
  
  // 并发读取所有文件
  for var FileName in Files do
  begin
    var Future := AsyncFS.ReadTextAsync(FileName);
    Futures.Add(Future);
  end;
  
  // 等待所有文件读取完成
  for var i := 0 to Futures.Count - 1 do
  begin
    try
      var Content := Futures[i].GetValue;
      WriteLn('File ', Files[i], ' size: ', Length(Content));
    except
      on E: Exception do
        WriteLn('Failed to read ', Files[i], ': ', E.Message);
    end;
  end;
  
  Files.Free;
  Futures.Free;
end.
```

### 自定义线程池

```pascal
program CustomThreadPoolExample;

uses
  fafafa.core.fs,
  fafafa.core.thread;

begin
  // 创建专用的文件I/O线程池
  var FileIOPool := TThreadPool.Create(
    2,      // 核心线程数
    8,      // 最大线程数  
    30000   // 线程保活时间(30秒)
  );
  
  try
    // 使用自定义线程池创建异步文件系统
    var AsyncFS := CreateAsyncFileSystem(FileIOPool);
    
    // 执行大量并发文件操作
    var Futures := TVec<IFuture<Boolean>>.Create;
    try
      for var i := 1 to 100 do
      begin
        var Future := AsyncFS.WriteTextAsync(
          Format('output_%d.txt', [i]), 
          Format('Content for file %d', [i])
        );
        Futures.Add(Future);
      end;
      
      // 等待所有操作完成
      var SuccessCount := 0;
      for var Future in Futures do
      begin
        if Future.GetValue then
          Inc(SuccessCount);
      end;
      
      WriteLn('Successfully wrote ', SuccessCount, ' files');
    finally
      Futures.Free;
    end;
  finally
    FileIOPool.Shutdown(True);  // 等待所有任务完成后关闭
  end;
end.
```

---

## 💡 设计优势总结

### 1. 性能优势
- **多核利用**: 充分利用多核CPU，而不是单线程事件循环
- **并发度高**: 可以同时执行多个文件I/O操作
- **无阻塞**: 主线程不会被文件I/O阻塞

### 2. 编程体验
- **符合Pascal习惯**: 面向对象的设计，符合Pascal程序员的习惯
- **易于调试**: 清晰的调用栈，便于调试和错误定位
- **类型安全**: 强类型的Future<T>，编译时类型检查

### 3. 架构简洁
- **无复杂状态**: 不需要管理复杂的事件循环状态
- **资源管理简单**: 线程池自动管理工作线程生命周期
- **易于测试**: 可以轻松模拟和测试异步操作

### 4. 扩展性好
- **可配置**: 线程池大小、超时时间等都可配置
- **可组合**: Future支持链式调用和组合操作
- **可取消**: 支持任务取消机制

这种基于线程池的异步设计更适合FreePascal框架，既保持了高性能，又提供了现代化的异步编程体验，同时避免了libuv事件循环模式的复杂性。
