# libuv 设计模式分析与 FreePascal 适配方案

> **目标**: 深入分析libuv的核心设计模式，提取可移植到FreePascal框架的设计理念和实现技巧

本文档分析libuv文件系统模块的关键设计模式，并提出如何将这些模式适配到我们的FreePascal框架中。

---

## 🔍 libuv 核心设计模式分析

### 1. 统一的请求-响应模式 (Request-Response Pattern)

#### libuv 的实现方式

```c
// libuv 的核心结构
struct uv_fs_s {
  UV_REQ_FIELDS           // 通用请求字段
  uv_fs_type fs_type;     // 操作类型
  uv_loop_t* loop;        // 事件循环
  uv_fs_cb cb;            // 回调函数
  ssize_t result;         // 操作结果
  void* ptr;              // 结果数据指针
  const char* path;       // 文件路径
  uv_stat_t statbuf;      // 文件状态缓冲区
};

// 统一的API模式
int uv_fs_open(uv_loop_t* loop, uv_fs_t* req, const char* path, 
               int flags, int mode, uv_fs_cb cb);
int uv_fs_read(uv_loop_t* loop, uv_fs_t* req, uv_file file,
               const uv_buf_t bufs[], unsigned int nbufs, 
               int64_t offset, uv_fs_cb cb);
```

#### FreePascal 适配方案

```pascal
// 统一的异步结果类型
generic IAsyncResult<T> = interface(IInterface)
['{ASYNC-RESULT-GUID}']
  function IsCompleted: Boolean;
  function IsSuccess: Boolean;
  function GetResult: T;
  function GetError: Exception;
  function GetOperation: TAsyncOperation;
  
  property Completed: Boolean read IsCompleted;
  property Success: Boolean read IsSuccess;
  property Result: T read GetResult;
  property Error: Exception read GetError;
end;

// 异步操作基类
TAsyncOperation = class abstract
private
  FLoop: TEventLoop;
  FCallback: TAsyncCallback;
  FCompleted: Boolean;
  FSuccess: Boolean;
  FError: Exception;
protected
  procedure DoExecute; virtual; abstract;
  procedure DoComplete(aSuccess: Boolean; aError: Exception = nil);
public
  constructor Create(aLoop: TEventLoop; aCallback: TAsyncCallback);
  procedure Execute;
  
  property Loop: TEventLoop read FLoop;
  property Completed: Boolean read FCompleted;
  property Success: Boolean read FSuccess;
  property Error: Exception read FError;
end;

// 具体的文件操作
TFileOpenOperation = class(TAsyncOperation)
private
  FPath: string;
  FMode: TFileOpenMode;
  FFlags: TFileOpenFlags;
  FResult: IFile;
protected
  procedure DoExecute; override;
public
  constructor Create(aLoop: TEventLoop; const aPath: string; 
    aMode: TFileOpenMode; aFlags: TFileOpenFlags; aCallback: TAsyncCallback);
  property Result: IFile read FResult;
end;
```

### 2. 事件循环集成模式 (Event Loop Integration)

#### libuv 的设计理念

- 所有异步操作都通过事件循环调度
- 使用线程池处理文件I/O操作
- 回调在主线程中执行，确保线程安全

#### FreePascal 适配方案

```pascal
// 事件循环接口
IEventLoop = interface(IInterface)
['{EVENT-LOOP-GUID}']
  procedure QueueWork(aWork: IAsyncWork);
  procedure QueueCallback(aCallback: TEventCallback);
  function Run(aMode: TRunMode = rmDefault): Boolean;
  procedure Stop;
  
  property IsRunning: Boolean read GetIsRunning;
  property WorkerThreadCount: Integer read GetWorkerThreadCount;
end;

// 异步工作接口
IAsyncWork = interface(IInterface)
['{ASYNC-WORK-GUID}']
  procedure Execute;           // 在工作线程中执行
  procedure OnComplete;        // 在主线程中执行回调
  
  property Priority: TWorkPriority read GetPriority;
  property Cancelled: Boolean read GetCancelled write SetCancelled;
end;

// 文件系统异步工作实现
TFileSystemWork = class(TInterfacedObject, IAsyncWork)
private
  FOperation: TAsyncOperation;
  FCallback: TAsyncCallback;
  FPriority: TWorkPriority;
  FCancelled: Boolean;
public
  constructor Create(aOperation: TAsyncOperation; aCallback: TAsyncCallback;
    aPriority: TWorkPriority = wpNormal);
  
  procedure Execute;
  procedure OnComplete;
  
  property Priority: TWorkPriority read FPriority;
  property Cancelled: Boolean read FCancelled write FCancelled;
end;
```

### 3. 平台抽象模式 (Platform Abstraction)

#### libuv 的实现策略

- 使用条件编译分离平台特定代码
- 统一的API接口隐藏平台差异
- 针对每个平台优化的实现

#### FreePascal 适配方案

```pascal
// 平台抽象接口
IFileSystemPlatform = interface(IInterface)
['{FS-PLATFORM-GUID}']
  function OpenFile(const aPath: string; aMode: TFileOpenMode; 
    aFlags: TFileOpenFlags): TFileHandle;
  function CloseFile(aHandle: TFileHandle): Boolean;
  function ReadFile(aHandle: TFileHandle; var aBuffer; aSize: SizeUInt): SizeUInt;
  function WriteFile(aHandle: TFileHandle; const aBuffer; aSize: SizeUInt): SizeUInt;
  function GetFileInfo(const aPath: string): TFileInfo;
  function CreateDirectory(const aPath: string; aMode: TFileMode): Boolean;
  // ... 其他平台操作
end;

// 平台工厂
TFileSystemPlatformFactory = class
public
  class function CreatePlatform: IFileSystemPlatform;
end;

// Windows 平台实现
{$IFDEF MSWINDOWS}
TWindowsFileSystemPlatform = class(TInterfacedObject, IFileSystemPlatform)
private
  function TranslateOpenMode(aMode: TFileOpenMode; aFlags: TFileOpenFlags): DWORD;
  function TranslateError(aErrorCode: DWORD): TFileSystemError;
public
  function OpenFile(const aPath: string; aMode: TFileOpenMode; 
    aFlags: TFileOpenFlags): TFileHandle;
  // ... Windows特定实现
end;
{$ENDIF}

// Unix 平台实现  
{$IFDEF UNIX}
TUnixFileSystemPlatform = class(TInterfacedObject, IFileSystemPlatform)
private
  function TranslateOpenFlags(aMode: TFileOpenMode; aFlags: TFileOpenFlags): Integer;
  function TranslateError(aErrno: Integer): TFileSystemError;
public
  function OpenFile(const aPath: string; aMode: TFileOpenMode; 
    aFlags: TFileOpenFlags): TFileHandle;
  // ... Unix特定实现
end;
{$ENDIF}
```

### 4. 内存管理模式 (Memory Management)

#### libuv 的内存管理策略

- 明确的资源生命周期管理
- 用户负责清理请求对象
- 避免内存泄漏的设计模式

#### FreePascal 适配方案

```pascal
// 资源管理接口
IDisposable = interface(IInterface)
['{DISPOSABLE-GUID}']
  procedure Dispose;
  function IsDisposed: Boolean;
  
  property Disposed: Boolean read IsDisposed;
end;

// 自动资源管理
generic TAutoResource<T: IDisposable> = record
private
  FResource: T;
  FOwned: Boolean;
public
  class operator Initialize(var aDest: TAutoResource<T>);
  class operator Finalize(var aDest: TAutoResource<T>);
  class operator Assign(var aDest: TAutoResource<T>; const aSrc: T);
  
  function Get: T;
  function Release: T;
  procedure Reset(const aNewResource: T = Default(T));
  
  property Resource: T read Get;
end;

// 使用示例
procedure ExampleUsage;
var
  AutoFile: TAutoResource<IFile>;
begin
  AutoFile := FileSystem.OpenFile('test.txt', fomRead);
  // 自动清理，无需手动调用Close
  AutoFile.Resource.ReadString;
end; // AutoFile 在此处自动释放
```

---

## 🎯 关键适配策略

### 1. 类型安全增强

**libuv问题**: C语言的弱类型系统容易导致错误
**FreePascal解决方案**: 利用强类型系统和泛型

```pascal
// 类型安全的缓冲区操作
generic TTypedBuffer<T> = class
private
  FData: Pointer;
  FCount: SizeUInt;
  FCapacity: SizeUInt;
  FAllocator: TAllocator;
public
  constructor Create(aCapacity: SizeUInt; aAllocator: TAllocator = nil);
  destructor Destroy; override;
  
  function GetItem(aIndex: SizeUInt): T;
  procedure SetItem(aIndex: SizeUInt; const aValue: T);
  procedure Resize(aNewCapacity: SizeUInt);
  
  property Items[aIndex: SizeUInt]: T read GetItem write SetItem; default;
  property Count: SizeUInt read FCount;
  property Capacity: SizeUInt read FCapacity;
end;

// 类型安全的文件读写
function ReadTyped<T>(aFile: IFile; out aValue: T): Boolean;
function WriteTyped<T>(aFile: IFile; const aValue: T): Boolean;
function ReadArray<T>(aFile: IFile; aCount: SizeUInt): TArray<T>;
```

### 2. 异常安全设计

**libuv特点**: 基于错误码的错误处理
**FreePascal增强**: 结合异常和错误码的混合模式

```pascal
// 错误处理策略
TFileSystemErrorMode = (
  femException,    // 抛出异常
  femErrorCode,    // 返回错误码
  femBoth          // 同时支持两种模式
);

// 可配置的错误处理
IFileSystemConfig = interface(IInterface)
['{FS-CONFIG-GUID}']
  function GetErrorMode: TFileSystemErrorMode;
  procedure SetErrorMode(aMode: TFileSystemErrorMode);
  
  property ErrorMode: TFileSystemErrorMode read GetErrorMode write SetErrorMode;
end;

// 统一的结果类型
generic TFileSystemResult<T> = record
  Success: Boolean;
  Value: T;
  Error: TFileSystemError;
  ErrorMessage: string;
  
  class function Ok(const aValue: T): TFileSystemResult<T>; static;
  class function Fail(aError: TFileSystemError; const aMessage: string): TFileSystemResult<T>; static;
  
  function IsOk: Boolean;
  function IsError: Boolean;
  function GetValueOrDefault(const aDefault: T): T;
  function GetValueOrRaise: T;
end;
```

### 3. 现代化API设计

**目标**: 提供比libuv更易用的高级API

```pascal
// 流式API设计
IFileStream = interface(IInterface)
['{FILE-STREAM-GUID}']
  function Read(aSize: SizeUInt): TBytes;
  function ReadLine: string;
  function ReadAll: string;
  function Write(const aData: TBytes): SizeUInt;
  function WriteLine(const aLine: string): SizeUInt;
  function Seek(aOffset: Int64; aOrigin: TSeekOrigin = soBeginning): Int64;
  
  // 链式操作支持
  function Then(aOperation: TFileOperation): IFileStream;
  function Filter(aPredicate: TFilePredicate): IFileStream;
  function Transform(aTransform: TFileTransform): IFileStream;
end;

// 便利的工厂方法
TFileSystem = class
public
  // 同步操作
  class function OpenRead(const aPath: string): IFileStream;
  class function OpenWrite(const aPath: string; aAppend: Boolean = False): IFileStream;
  class function CreateTemp(const aPrefix: string = 'tmp'): IFileStream;
  
  // 异步操作
  class function OpenReadAsync(const aPath: string): IFuture<IFileStream>;
  class function OpenWriteAsync(const aPath: string; aAppend: Boolean = False): IFuture<IFileStream>;
  
  // 便利方法
  class function ReadAllText(const aPath: string; aEncoding: TEncoding = nil): string;
  class function WriteAllText(const aPath: string; const aText: string; aEncoding: TEncoding = nil): Boolean;
  class function ReadAllBytes(const aPath: string): TBytes;
  class function WriteAllBytes(const aPath: string; const aData: TBytes): Boolean;
end;
```

---

## 📊 性能优化策略

### 1. 内存池优化

借鉴libuv的内存管理，结合框架的分配器系统：

```pascal
// 文件系统专用内存池
TFileSystemMemoryPool = class(TMemoryPool)
private
  FBufferPool: TObjectPool<TFileBuffer>;
  FRequestPool: TObjectPool<TAsyncRequest>;
public
  constructor Create(aAllocator: TAllocator);
  destructor Destroy; override;
  
  function GetBuffer(aSize: SizeUInt): TFileBuffer;
  procedure ReturnBuffer(aBuffer: TFileBuffer);
  
  function GetRequest: TAsyncRequest;
  procedure ReturnRequest(aRequest: TAsyncRequest);
end;
```

### 2. 批量操作优化

```pascal
// 批量文件操作
IBatchFileOperation = interface(IInterface)
['{BATCH-FILE-OP-GUID}']
  function AddRead(const aPath: string): IBatchFileOperation;
  function AddWrite(const aPath: string; const aData: TBytes): IBatchFileOperation;
  function AddCopy(const aSrc, aDest: string): IBatchFileOperation;
  function Execute: TArray<TFileSystemResult<Boolean>>;
  function ExecuteAsync: IFuture<TArray<TFileSystemResult<Boolean>>>;
end;

// 使用示例
procedure BatchExample;
var
  Batch: IBatchFileOperation;
  Results: TArray<TFileSystemResult<Boolean>>;
begin
  Batch := FileSystem.CreateBatch
    .AddRead('file1.txt')
    .AddRead('file2.txt')
    .AddWrite('output.txt', SomeData);
  
  Results := Batch.Execute;
  // 处理批量操作结果
end;
```

这个分析文档展示了如何将libuv的核心设计模式适配到FreePascal框架中，既保持了libuv的高性能特性，又充分利用了Pascal的类型安全和现代编程特性。
