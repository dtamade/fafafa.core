unit fafafa.core.async;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, SyncObjs,
  fafafa.core.base,
  fafafa.core.thread.types,
  fafafa.core.thread.future,
  fafafa.core.thread.pool;

type
  // 前向声明
  IAsyncClient = interface;
  IAsyncServer = interface;
  IAsyncFile = interface;
  IAsyncTimer = interface;
  generic IAsyncStream<T> = interface;

  // 异步任务类型
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  generic TAsyncTask<T> = reference to function: specialize IFuture<T>;
  generic TAsyncFunc<T, TResult> = reference to function(const Value: T): specialize IFuture<TResult>;
  generic TAsyncPredicate<T> = reference to function(const Value: T): specialize IFuture<Boolean>;
  generic TAsyncAction<T> = reference to procedure(const Value: T);
  generic TAsyncGenerator<T> = reference to function: specialize IAsyncStream<T>;

  // 异步事件类型
  TAsyncEvent = reference to procedure;
  TAsyncDataEvent = reference to procedure(const Data: TBytes);
  TAsyncErrorEvent = reference to procedure(const Error: Exception);
  TAsyncConnectionEvent = reference to procedure(Client: IAsyncClient);
  {$ENDIF}

  // 异步流接口
  generic IAsyncStream<T> = interface(IInterface)
  ['{ASYNC-STREAM-INTERFACE-GUID}']
    // 转换操作
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    function Map<TResult>(const Mapper: specialize TAsyncFunc<T, TResult>): specialize IAsyncStream<TResult>;
    function Filter(const Predicate: specialize TAsyncPredicate<T>): specialize IAsyncStream<T>;
    {$ENDIF}
    function Take(Count: Integer): specialize IAsyncStream<T>;
    function Skip(Count: Integer): specialize IAsyncStream<T>;

    // 聚合操作
    function ToArray: specialize IFuture<specialize TArray<T>>;
    function Count: specialize IFuture<Integer>;
    function First: specialize IFuture<T>;
    function Last: specialize IFuture<T>;

    // 订阅操作
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    function ForEach(const Action: specialize TAsyncAction<T>): specialize IFuture<Boolean>;
    {$ENDIF}
  end;

  // 异步网络客户端接口
  IAsyncClient = interface(IInterface)
  ['{ASYNC-CLIENT-INTERFACE-GUID}']
    function Send(const Data: TBytes): specialize IFuture<Integer>;
    function SendText(const Text: string): specialize IFuture<Integer>;
    function Receive(MaxSize: Integer = 4096): specialize IFuture<TBytes>;
    function ReceiveText: specialize IFuture<string>;
    function Close: specialize IFuture<Boolean>;

    // 流式接口
    function AsStream: specialize IAsyncStream<TBytes>;
    function AsTextStream: specialize IAsyncStream<string>;

    // 属性
    function GetRemoteAddress: string;
    function GetRemotePort: Word;
    function IsConnected: Boolean;

    property RemoteAddress: string read GetRemoteAddress;
    property RemotePort: Word read GetRemotePort;
    property Connected: Boolean read IsConnected;
  end;

  // 异步网络服务器接口
  IAsyncServer = interface(IInterface)
  ['{ASYNC-SERVER-INTERFACE-GUID}']
    function Accept: specialize IAsyncStream<IAsyncClient>;
    function Stop: specialize IFuture<Boolean>;

    // 配置
    procedure SetMaxConnections(Count: Integer);
    procedure SetKeepAlive(Enabled: Boolean; TimeoutMs: Cardinal = 30000);

    // 属性
    function GetLocalAddress: string;
    function GetLocalPort: Word;
    function IsListening: Boolean;

    property LocalAddress: string read GetLocalAddress;
    property LocalPort: Word read GetLocalPort;
    property Listening: Boolean read IsListening;
  end;

  // 异步定时器接口
  IAsyncTimer = interface(IInterface)
  ['{ASYNC-TIMER-INTERFACE-GUID}']
    function Stop: specialize IFuture<Boolean>;
    function Reset(MilliSeconds: Cardinal): specialize IFuture<Boolean>;

    function GetInterval: Cardinal;
    function IsActive: Boolean;

    property Interval: Cardinal read GetInterval;
    property Active: Boolean read IsActive;
  end;

  // 异步文件接口（扩展现有的）
  IAsyncFile = interface(IInterface)
  ['{ASYNC-FILE-EXT-INTERFACE-GUID}']
    function Read(Size: SizeUInt): specialize IFuture<TBytes>;
    function Write(const Data: TBytes): specialize IFuture<SizeUInt>;
    function ReadText: specialize IFuture<string>;
    function WriteText(const Text: string): specialize IFuture<Boolean>;
    function Seek(Offset: Int64; Origin: TSeekOrigin): specialize IFuture<Int64>;
    function GetSize: specialize IFuture<Int64>;
    function Flush: specialize IFuture<Boolean>;
    function Close: specialize IFuture<Boolean>;

    function GetFileName: string;
    function IsOpen: Boolean;

    property FileName: string read GetFileName;
    property Open: Boolean read IsOpen;
  end;

  // 全局异步操作入口
  Async = class sealed
  private
    class var FInitialized: Boolean;
    class var FLock: TCriticalSection;

    class procedure EnsureInitialized;
    class procedure InternalInitialize;
    class procedure InternalFinalize;
  public
    // === 网络操作 ===
    class function Connect(const Host: string; Port: Word): specialize IFuture<IAsyncClient>;
    class function Listen(const Host: string; Port: Word): specialize IFuture<IAsyncServer>;
    class function HttpGet(const URL: string): specialize IFuture<string>;
    class function HttpPost(const URL, Data: string): specialize IFuture<string>;

    // === 文件操作 ===
    class function ReadFile(const Path: string): specialize IFuture<TBytes>;
    class function WriteFile(const Path: string; const Data: TBytes): specialize IFuture<Boolean>;
    class function ReadText(const Path: string): specialize IFuture<string>;
    class function WriteText(const Path: string; const Text: string): specialize IFuture<Boolean>;
    class function OpenFile(const Path: string; Mode: TFileMode): specialize IFuture<IAsyncFile>;

    // === 定时器操作 ===
    class function Delay(MilliSeconds: Cardinal): specialize IFuture<Boolean>;
    class function Timeout<T>(Future: specialize IFuture<T>; TimeoutMs: Cardinal): specialize IFuture<T>;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    class function Interval(MilliSeconds: Cardinal; const Action: TAsyncEvent): IAsyncTimer;
    {$ENDIF}

    // === 并发控制 ===
    class function WhenAll<T>(const Futures: array of specialize IFuture<T>): specialize IFuture<specialize TArray<T>>;
    class function WhenAny<T>(const Futures: array of specialize IFuture<T>): specialize IFuture<T>;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    class function Parallel<T>(const Tasks: array of specialize TAsyncTask<T>): specialize IFuture<specialize TArray<T>>;
    {$ENDIF}

    // === 流操作 ===
    class function FromArray<T>(const Items: array of T): specialize IAsyncStream<T>;
    class function Range(Start, Count: Integer): specialize IAsyncStream<Integer>;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    class function Generate<T>(const Generator: specialize TAsyncGenerator<T>): specialize IAsyncStream<T>;
    {$ENDIF}

    // === 运行时控制 ===
    class procedure Run; // 启动异步运行时（可选调用）
    class procedure Shutdown; // 优雅关闭
    class function IsRunning: Boolean;
  end;

  // 异常类型
  EAsyncException = class(ECore);  // ✅ ASYNC-001: 继承自 ECore
  EAsyncTimeoutException = class(EAsyncException);
  EAsyncConnectionException = class(EAsyncException);
  EAsyncIOException = class(EAsyncException);

implementation

uses
  fafafa.core.async.runtime,
  fafafa.core.async.stream,
  fafafa.core.async.network,
  fafafa.core.async.file,
  fafafa.core.async.timer;

{ Async }

class procedure Async.EnsureInitialized;
begin
  if not FInitialized then
  begin
    FLock.Enter;
    try
      if not FInitialized then
        InternalInitialize;
    finally
      FLock.Leave;
    end;
  end;
end;

class procedure Async.InternalInitialize;
begin
  // 初始化异步运行时
  TAsyncRuntime.Initialize;
  FInitialized := True;
end;

class procedure Async.InternalFinalize;
begin
  if FInitialized then
  begin
    TAsyncRuntime.Finalize;
    FInitialized := False;
  end;
end;

class function Async.Connect(const Host: string; Port: Word): specialize IFuture<IAsyncClient>;
begin
  EnsureInitialized;
  Result := TAsyncNetwork.Connect(Host, Port);
end;

class function Async.Listen(const Host: string; Port: Word): specialize IFuture<IAsyncServer>;
begin
  EnsureInitialized;
  Result := TAsyncNetwork.Listen(Host, Port);
end;

class function Async.HttpGet(const URL: string): specialize IFuture<string>;
begin
  EnsureInitialized;
  Result := TAsyncNetwork.HttpGet(URL);
end;

class function Async.HttpPost(const URL, Data: string): specialize IFuture<string>;
begin
  EnsureInitialized;
  Result := TAsyncNetwork.HttpPost(URL, Data);
end;

class function Async.ReadFile(const Path: string): specialize IFuture<TBytes>;
begin
  EnsureInitialized;
  Result := TAsyncFileSystem.ReadFile(Path);
end;

class function Async.WriteFile(const Path: string; const Data: TBytes): specialize IFuture<Boolean>;
begin
  EnsureInitialized;
  Result := TAsyncFileSystem.WriteFile(Path, Data);
end;

class function Async.ReadText(const Path: string): specialize IFuture<string>;
begin
  EnsureInitialized;
  Result := TAsyncFileSystem.ReadText(Path);
end;

class function Async.WriteText(const Path: string; const Text: string): specialize IFuture<Boolean>;
begin
  EnsureInitialized;
  Result := TAsyncFileSystem.WriteText(Path, Text);
end;

class function Async.OpenFile(const Path: string; Mode: TFileMode): specialize IFuture<IAsyncFile>;
begin
  EnsureInitialized;
  Result := TAsyncFileSystem.OpenFile(Path, Mode);
end;

class function Async.Delay(MilliSeconds: Cardinal): specialize IFuture<Boolean>;
begin
  EnsureInitialized;
  Result := TAsyncTimer.Delay(MilliSeconds);
end;

class function Async.Timeout<T>(Future: specialize IFuture<T>; TimeoutMs: Cardinal): specialize IFuture<T>;
begin
  EnsureInitialized;
  Result := TAsyncTimer.Timeout<T>(Future, TimeoutMs);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
class function Async.Interval(MilliSeconds: Cardinal; const Action: TAsyncEvent): IAsyncTimer;
begin
  EnsureInitialized;
  Result := TAsyncTimer.Interval(MilliSeconds, Action);
end;
{$ENDIF}

class function Async.WhenAll<T>(const Futures: array of specialize IFuture<T>): specialize IFuture<specialize TArray<T>>;
begin
  EnsureInitialized;
  Result := TAsyncCombinators.WhenAll<T>(Futures);
end;

class function Async.WhenAny<T>(const Futures: array of specialize IFuture<T>): specialize IFuture<T>;
begin
  EnsureInitialized;
  Result := TAsyncCombinators.WhenAny<T>(Futures);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
class function Async.Parallel<T>(const Tasks: array of specialize TAsyncTask<T>): specialize IFuture<specialize TArray<T>>;
begin
  EnsureInitialized;
  Result := TAsyncCombinators.Parallel<T>(Tasks);
end;
{$ENDIF}

class function Async.FromArray<T>(const Items: array of T): specialize IAsyncStream<T>;
begin
  EnsureInitialized;
  Result := TAsyncStreamFactory.FromArray<T>(Items);
end;

class function Async.Range(Start, Count: Integer): specialize IAsyncStream<Integer>;
begin
  EnsureInitialized;
  Result := TAsyncStreamFactory.Range(Start, Count);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
class function Async.Generate<T>(const Generator: specialize TAsyncGenerator<T>): specialize IAsyncStream<T>;
begin
  EnsureInitialized;
  Result := TAsyncStreamFactory.Generate<T>(Generator);
end;
{$ENDIF}

class procedure Async.Run;
begin
  EnsureInitialized;
  TAsyncRuntime.Instance.Run;
end;

class procedure Async.Shutdown;
begin
  if FInitialized then
    TAsyncRuntime.Instance.Shutdown;
end;

class function Async.IsRunning: Boolean;
begin
  if FInitialized then
    Result := TAsyncRuntime.Instance.IsRunning
  else
    Result := False;
end;

initialization
  Async.FLock := TCriticalSection.Create;

finalization
  Async.InternalFinalize;
  FreeAndNil(Async.FLock);

end.
