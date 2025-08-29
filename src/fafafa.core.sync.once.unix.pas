unit fafafa.core.sync.once.unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.once.base;

type
  TOnce = class(TInterfacedObject, IOnce)
  private
    // 高性能设计：缓存行对齐优化，减少伪共享
    // 第一个缓存行：热路径数据（64 字节对齐）
    FDone: LongBool;              // 原子布尔值，快速路径检查
    FState: LongInt;              // 详细状态：0=NotStarted, 1=InProgress, 2=Completed, 3=Poisoned
    FExecutingThreadId: TThreadID; // 当前执行线程ID，用于递归检测

    // 填充到缓存行边界，避免与锁数据伪共享
    FPadding1: array[0..39] of Byte; // 64 - 8 - 4 - 8 = 44 字节填充（考虑对象头）

    // 第二个缓存行：同步数据
    FMutex: pthread_mutex_t;      // 慢速路径同步

    // 第三个缓存行：回调存储
    FCallback: TOnceCallback;     // 存储的回调函数

    const
      STATE_NOT_STARTED = 0;
      STATE_IN_PROGRESS = 1;
      STATE_COMPLETED = 2;
      STATE_POISONED = 3;

    // 内部执行方法
    procedure DoInternal(const AProc: TOnceProc; AForce: Boolean); overload;
    procedure DoInternal(const AMethod: TOnceMethod; AForce: Boolean); overload;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure DoInternal(const AAnonymousProc: TOnceAnonymousProc; AForce: Boolean); overload;
    {$ENDIF}

  public
    constructor Create; overload;
    constructor Create(const AProc: TOnceProc); overload;
    constructor Create(const AMethod: TOnceMethod); overload;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    constructor Create(const AAnonymousProc: TOnceAnonymousProc); overload;
    {$ENDIF}
    destructor Destroy; override;

    // ISynchronizable 接口实现
    function GetLastError: TWaitError;

    // ILock 接口实现
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;

    // IOnce 核心接口实现（Go/Rust 风格）
    procedure Execute; overload;
    procedure Execute(const AProc: TOnceProc); overload;
    procedure Execute(const AMethod: TOnceMethod); overload;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure Execute(const AAnonymousProc: TOnceAnonymousProc); overload;
    {$ENDIF}

    // 强制执行（忽略毒化状态）
    procedure ExecuteForce; overload;
    procedure ExecuteForce(const AProc: TOnceProc); overload;
    procedure ExecuteForce(const AMethod: TOnceMethod); overload;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure ExecuteForce(const AAnonymousProc: TOnceAnonymousProc); overload;
    {$ENDIF}

    // 兼容旧接口（标记为废弃）
    procedure Call(const AProc: TOnceProc); overload; deprecated 'Use Execute instead';
    procedure Call(const AMethod: TOnceMethod); overload; deprecated 'Use Execute instead';
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure Call(const AAnonymousProc: TOnceAnonymousProc); overload; deprecated 'Use Execute instead';
    {$ENDIF}

    // 兼容旧接口（标记为废弃）
    procedure CallForce(const AProc: TOnceProc); overload; deprecated 'Use ExecuteForce instead';
    procedure CallForce(const AMethod: TOnceMethod); overload; deprecated 'Use ExecuteForce instead';
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure CallForce(const AAnonymousProc: TOnceAnonymousProc); overload; deprecated 'Use ExecuteForce instead';
    {$ENDIF}

    // 等待机制
    procedure Wait;
    procedure WaitForce;

    // 状态查询（属性风格，符合 Pascal 约定）
    function GetState: TOnceState;
    function GetCompleted: Boolean;
    function GetPoisoned: Boolean;

    // Reset 功能已移除 - 请创建新的 Once 实例
  end;

implementation

// 错误消息资源字符串
resourcestring
  rsOnceAlreadyPoisoned = 'Once is poisoned due to previous panic';
  rsOnceRecursiveCall = 'Recursive call to Once.Execute() detected from the same thread';
  rsOnceInitFailed = 'Failed to initialize pthread mutex for Once';

// 中文错误消息（可选）
{$IFDEF FAFAFA_CORE_CHINESE_MESSAGES}
resourcestring
  rsOnceAlreadyPoisonedCN = 'Once 已因先前的异常而中毒';
  rsOnceRecursiveCallCN = '检测到同一线程对 Once.Execute() 的递归调用';
  rsOnceInitFailedCN = '初始化 Once 的 pthread 互斥锁失败';
{$ENDIF}

{ TOnce }

constructor TOnce.Create;
begin
  inherited Create;
  FDone := False;               // 原子布尔值初始化
  FState := STATE_NOT_STARTED;  // 详细状态初始化
  FExecutingThreadId := 0;      // 初始化执行线程ID

  // 初始化互斥锁
  if pthread_mutex_init(@FMutex, nil) <> 0 then
    raise ELockError.Create(rsOnceInitFailed);

  // 初始化回调为空
  FCallback.CallbackType := octNone;
  FCallback.Proc := nil;
  FCallback.Method := nil;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  FCallback.AnonymousProc := nil;
  {$ENDIF}

  // 调试输出
  {$IFDEF FAFAFA_CORE_DEBUG_ONCE}
  WriteLn('[DEBUG] Once instance created: ', IntToHex(PtrUInt(Self), 16));
  {$ENDIF}
end;

constructor TOnce.Create(const AProc: TOnceProc);
begin
  Create; // 调用基础构造函数
  FCallback.CallbackType := octProc;
  FCallback.Proc := AProc;
end;

constructor TOnce.Create(const AMethod: TOnceMethod);
begin
  Create; // 调用基础构造函数
  FCallback.CallbackType := octMethod;
  FCallback.Method := AMethod;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
constructor TOnce.Create(const AAnonymousProc: TOnceAnonymousProc);
begin
  Create; // 调用基础构造函数
  FCallback.CallbackType := octAnonymous;
  FCallback.AnonymousProc := AAnonymousProc;
end;
{$ENDIF}

// ISynchronizable 接口实现
function TOnce.GetLastError: TWaitError;
begin
  // Once 不使用传统的等待错误，总是返回无错误
  Result := weNone;
end;

// ILock 接口实现
procedure TOnce.Acquire;
begin
  Execute; // Acquire 等同于 Execute
end;

procedure TOnce.Release;
begin
  // Release 对于 Once 来说是无操作，因为一旦完成就不能重置
  // 这里什么都不做，保持接口兼容性
end;

function TOnce.TryAcquire: Boolean;
begin
  // TryAcquire 检查是否已完成
  Result := GetCompleted;
end;

function TOnce.TryAcquire(ATimeoutMs: Cardinal): Boolean;
begin
  // 对于 Once，超时版本的 TryAcquire 与无超时版本相同
  // 因为 Once 要么已完成（立即返回），要么需要执行（但我们不在这里执行）
  Result := GetCompleted;
end;

// IOnce Execute 方法实现
procedure TOnce.Execute;
begin
  case FCallback.CallbackType of
    octNone: ; // 无回调，什么都不做
    octProc: DoInternal(FCallback.Proc, False);
    octMethod: DoInternal(FCallback.Method, False);
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    octAnonymous: DoInternal(FCallback.AnonymousProc, False);
    {$ENDIF}
  end;
end;

procedure TOnce.Execute(const AProc: TOnceProc);
begin
  DoInternal(AProc, False);
end;

procedure TOnce.Execute(const AMethod: TOnceMethod);
begin
  DoInternal(AMethod, False);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TOnce.Execute(const AAnonymousProc: TOnceAnonymousProc);
begin
  DoInternal(AAnonymousProc, False);
end;
{$ENDIF}

// ExecuteForce 方法实现
procedure TOnce.ExecuteForce;
begin
  case FCallback.CallbackType of
    octNone: ; // 无回调，什么都不做
    octProc: DoInternal(FCallback.Proc, True);
    octMethod: DoInternal(FCallback.Method, True);
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    octAnonymous: DoInternal(FCallback.AnonymousProc, True);
    {$ENDIF}
  end;
end;

procedure TOnce.ExecuteForce(const AProc: TOnceProc);
begin
  DoInternal(AProc, True);
end;

procedure TOnce.ExecuteForce(const AMethod: TOnceMethod);
begin
  DoInternal(AMethod, True);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TOnce.ExecuteForce(const AAnonymousProc: TOnceAnonymousProc);
begin
  DoInternal(AAnonymousProc, True);
end;
{$ENDIF}

// 兼容旧接口（标记为废弃）
// 高性能核心实现：Go 风格的快速路径 + 慢速路径
procedure TOnce.Call(const AProc: TOnceProc);
begin
  DoInternal(AProc, False);
end;

procedure TOnce.Call(const AMethod: TOnceMethod);
begin
  DoInternal(AMethod, False);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TOnce.Call(const AAnonymousProc: TOnceAnonymousProc);
begin
  DoInternal(AAnonymousProc, False);
end;
{$ENDIF}

procedure TOnce.CallForce(const AProc: TOnceProc);
begin
  DoInternal(AProc, True);
end;

procedure TOnce.CallForce(const AMethod: TOnceMethod);
begin
  DoInternal(AMethod, True);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TOnce.CallForce(const AAnonymousProc: TOnceAnonymousProc);
begin
  DoInternal(AAnonymousProc, True);
end;
{$ENDIF}

destructor TOnce.Destroy;
begin
  // 销毁互斥锁
  pthread_mutex_destroy(@FMutex);
  inherited Destroy;
end;

// 核心内部实现：高性能原子快速路径 + 慢速路径
procedure TOnce.DoInternal(const AProc: TOnceProc; AForce: Boolean);
begin
  // 快速路径：原子读取，无锁检查（Go 风格优化）
  // 在 Unix 下使用简单的布尔检查，依赖 mutex 提供内存屏障
  if FDone and not AForce then
  begin
    // 如果是毒化状态且不强制执行，抛出异常
    pthread_mutex_lock(@FMutex);
    try
      if FState = STATE_POISONED then
        raise ELockError.Create(rsOnceAlreadyPoisoned);
    finally
      pthread_mutex_unlock(@FMutex);
    end;
    Exit;
  end;

  // 递归调用检测（在获取锁之前检查，避免死锁）
  if FExecutingThreadId = GetCurrentThreadId then
    raise EOnceRecursiveCall.Create(rsOnceRecursiveCall);

  // 慢速路径：需要同步执行
  pthread_mutex_lock(@FMutex);
  try
    // 双重检查锁定模式
    if FDone and not AForce then
    begin
      if FState = STATE_POISONED then
        raise ELockError.Create(rsOnceAlreadyPoisoned);
      Exit;
    end;

    // 如果是毒化状态且不强制执行，抛出异常
    if (FState = STATE_POISONED) and not AForce then
      raise ELockError.Create(rsOnceAlreadyPoisoned);

    // 标记为进行中
    FState := STATE_IN_PROGRESS;
    FExecutingThreadId := GetCurrentThreadId;

    try
      try
        // 执行用户回调
        if Assigned(AProc) then
          AProc();

        // 标记为已完成
        FState := STATE_COMPLETED;
        // 在 Unix 下，mutex 的 unlock 提供了 release 语义
        FDone := True;  // 启用快速路径
      except
        // 异常处理：标记为毒化状态
        FState := STATE_POISONED;
        // 在 Unix 下，mutex 的 unlock 提供了 release 语义
        FDone := True;  // 即使毒化也设置 Done，避免重复执行
        raise;
      end;
    finally
      // 清除执行线程ID
      FExecutingThreadId := 0;
    end;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

procedure TOnce.DoInternal(const AMethod: TOnceMethod; AForce: Boolean);
begin
  // 快速路径：原子读取，无锁检查
  if FDone and not AForce then
  begin
    pthread_mutex_lock(@FMutex);
    try
      if FState = STATE_POISONED then
        raise ELockError.Create(rsOnceAlreadyPoisoned);
    finally
      pthread_mutex_unlock(@FMutex);
    end;
    Exit;
  end;

  // 递归调用检测（在获取锁之前检查，避免死锁）
  if FExecutingThreadId = GetCurrentThreadId then
    raise EOnceRecursiveCall.Create(rsOnceRecursiveCall);

  // 慢速路径：需要同步执行
  pthread_mutex_lock(@FMutex);
  try
    if FDone and not AForce then
    begin
      if FState = STATE_POISONED then
        raise ELockError.Create(rsOnceAlreadyPoisoned);
      Exit;
    end;

    if (FState = STATE_POISONED) and not AForce then
      raise ELockError.Create(rsOnceAlreadyPoisoned);

    FState := STATE_IN_PROGRESS;
    FExecutingThreadId := GetCurrentThreadId;

    try
      try
        if Assigned(AMethod) then
          AMethod();

        FState := STATE_COMPLETED;
        // 在 Unix 下，mutex 的 unlock 提供了 release 语义
        FDone := True;
      except
        FState := STATE_POISONED;
        // 在 Unix 下，mutex 的 unlock 提供了 release 语义
        FDone := True;
        raise;
      end;
    finally
      // 清除执行线程ID
      FExecutingThreadId := 0;
    end;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TOnce.DoInternal(const AAnonymousProc: TOnceAnonymousProc; AForce: Boolean);
begin
  // 快速路径：原子读取，无锁检查
  if FDone and not AForce then
  begin
    pthread_mutex_lock(@FMutex);
    try
      if FState = STATE_POISONED then
        raise ELockError.Create(rsOnceAlreadyPoisoned);
    finally
      pthread_mutex_unlock(@FMutex);
    end;
    Exit;
  end;

  // 慢速路径：需要同步执行
  // 递归调用检测（在获取锁之前检查，避免死锁）
  if FExecutingThreadId = GetCurrentThreadId then
    raise EOnceRecursiveCall.Create(rsOnceRecursiveCall);

  pthread_mutex_lock(@FMutex);
  try
    if FDone and not AForce then
    begin
      if FState = STATE_POISONED then
        raise ELockError.Create(rsOnceAlreadyPoisoned);
      Exit;
    end;

    if (FState = STATE_POISONED) and not AForce then
      raise ELockError.Create(rsOnceAlreadyPoisoned);

    FState := STATE_IN_PROGRESS;
    FExecutingThreadId := GetCurrentThreadId;

    try
      try
        if Assigned(AAnonymousProc) then
          AAnonymousProc();

        FState := STATE_COMPLETED;
        // 在 Unix 下，mutex 的 unlock 提供了 release 语义
        FDone := True;
      except
        FState := STATE_POISONED;
        // 在 Unix 下，mutex 的 unlock 提供了 release 语义
        FDone := True;
        raise;
      end;
    finally
      // 清除执行线程ID
      FExecutingThreadId := 0;
    end;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;
{$ENDIF}

// 等待机制实现（Rust 风格）
procedure TOnce.Wait;
begin
  // 快速路径：如果已完成，直接返回
  if FDone then
  begin
    // 检查是否毒化
    pthread_mutex_lock(@FMutex);
    try
      if FState = STATE_POISONED then
        raise ELockError.Create(rsOnceAlreadyPoisoned);
    finally
      pthread_mutex_unlock(@FMutex);
    end;
    Exit;
  end;

  // 慢速路径：等待完成
  pthread_mutex_lock(@FMutex);
  try
    while not FDone do
    begin
      pthread_mutex_unlock(@FMutex);
      Sleep(1); // 1ms 等待
      pthread_mutex_lock(@FMutex);
    end;

    // 检查最终状态
    if FState = STATE_POISONED then
      raise ELockError.Create(rsOnceAlreadyPoisoned);
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

procedure TOnce.WaitForce;
begin
  // 强制等待，忽略毒化状态
  while not FDone do
    Sleep(1); // 1ms 等待
end;

// 状态查询方法
function TOnce.GetState: TOnceState;
begin
  pthread_mutex_lock(@FMutex);
  try
    case FState of
      STATE_NOT_STARTED: Result := osNotStarted;
      STATE_IN_PROGRESS: Result := osInProgress;
      STATE_COMPLETED: Result := osCompleted;
      STATE_POISONED: Result := osPoisoned;
    else
      Result := osNotStarted; // 默认值
    end;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TOnce.GetCompleted: Boolean;
begin
  pthread_mutex_lock(@FMutex);
  try
    Result := (FState = STATE_COMPLETED);
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TOnce.GetPoisoned: Boolean;
begin
  pthread_mutex_lock(@FMutex);
  try
    Result := (FState = STATE_POISONED);
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

// Reset 方法已移除 - 不安全且不符合主流语言实践
// 如需重新执行，请创建新的 Once 实例

end.
