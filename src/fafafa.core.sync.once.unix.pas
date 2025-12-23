unit fafafa.core.sync.once.unix;

{
  Unix/Linux 平台一次性执行实�?

  特性：
  - 基于 pthread_once_t 系统实现 (可�?
  - 默认使用原子操作 + 互斥�?fallback 实现
  - �?Unix 系统兼容�?(Linux, macOS, FreeBSD �?
  - 支持异常恢复和毒化状态管�?
  - 内存屏障和缓存行对齐优化

  实现策略�?
  - 快速路径：无锁原子操作检查完成状�?
  - 慢速路径：使用 pthread_mutex_t 进行同步执行
  - 异常处理：失败时标记为毒化状�?
  - 递归检测：防止同一线程递归调用
  - 内存模型：正确的 acquire/release 语义
}

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Unix, UnixType, pthreads,
  fafafa.core.sync.base, fafafa.core.sync.once.base;

// 内存屏障函数声明
{$IFDEF CPUX86_64}
procedure MemoryBarrier; inline;
function LoadAcquire(var Target: LongBool): LongBool; inline;
procedure StoreRelease(var Target: LongBool; Value: LongBool); inline;
{$ELSE}
procedure MemoryBarrier; inline;
function LoadAcquire(var Target: LongBool): LongBool; inline;
procedure StoreRelease(var Target: LongBool; Value: LongBool); inline;
{$ENDIF}

type
  TOnce = class(TSynchronizable, IOnce)
  private
    // 修复缓存行对齐：正确计算Unix平台的字段大小和填充
    // 第一个缓存行：热路径数据（高频访问）
    FDone: LongBool;              // 1字节：原子布尔值，快速路径检�?
    FState: LongInt;              // 4字节：详细状�?
    FExecutingThreadId: TThreadID; // 8字节：当前执行线程ID (64位系�?

    // 精确计算填充：确保下一个字段在新缓存行开�?
    // 对象�?8字节) + FDone(1字节) + 对齐填充(3字节) + FState(4字节) + FExecutingThreadId(8字节) = 24字节
    // 需要填�?64 - 24 = 40字节 到缓存行边界
    FPadding1: array[0..39] of Byte;

    // 第二个缓存行：同步数据（64字节对齐）
    FMutex: pthread_mutex_t;      // pthread互斥锁

    // pthread_mutex_t 在Linux x64上通常�?0字节，需要填充到缓存行边�?
    // 64 - 40 = 24字节填充
    FPadding2: array[0..23] of Byte;

    // 第三个缓存行：回调存储（64字节对齐�?
    FCallback: TOnceCallback;     // 存储的回调函�?

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

    // 移除ILock接口方法：IOnce不再继承ILock，避免语义混�?
    // 这些方法已被移除，因为Once不是传统意义的锁

    // IOnce 核心接口实现（Go/Rust 风格�?
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



    // 等待机制
    procedure Wait;
    procedure WaitForce;

    // 状态查询（属性风格，符合 Pascal 约定�?
    function GetState: TOnceState;
    function GetCompleted: Boolean;
    function GetPoisoned: Boolean;

    // Reset 功能已移�?- 请创建新�?Once 实例
  end;

implementation

// 内存屏障函数实现
// 使用 FPC 内建的内存屏障函数，更可靠且跨平�?
procedure MemoryBarrier; inline;
begin
  {$IFDEF FPC}
  ReadBarrier;
  WriteBarrier;
  {$ELSE}
  // 其他编译器的实现
  {$ENDIF}
end;

function LoadAcquire(var Target: LongBool): LongBool; inline;
begin
  Result := Target;
  {$IFDEF FPC}
  ReadBarrier; // 确保后续读取不会重排序到此之�?
  {$ENDIF}
end;

procedure StoreRelease(var Target: LongBool; Value: LongBool); inline;
begin
  {$IFDEF FPC}
  WriteBarrier; // 确保前面的写入不会重排序到此之后
  {$ENDIF}
  Target := Value;
end;

// 错误消息资源字符�?
resourcestring
  rsOnceAlreadyPoisoned = 'Once is poisoned due to previous panic';
  rsOnceRecursiveCall = 'Recursive call to Once.Execute() detected from the same thread';
  rsOnceInitFailed = 'Failed to initialize pthread mutex for Once';

// 中文错误消息（可选）
{$IFDEF FAFAFA_CORE_CHINESE_MESSAGES}
resourcestring
  rsOnceAlreadyPoisonedCN = 'Once 已因先前的异常而中�?;
  rsOnceRecursiveCallCN = '检测到同一线程�?Once.Execute() 的递归调用';
  rsOnceInitFailedCN = '初始�?Once �?pthread 互斥锁失�?;
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

  // 初始化回调为�?
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
  Create; // 调用基础构造函�?
  FCallback.CallbackType := octProc;
  FCallback.Proc := AProc;
end;

constructor TOnce.Create(const AMethod: TOnceMethod);
begin
  Create; // 调用基础构造函�?
  FCallback.CallbackType := octMethod;
  FCallback.Method := AMethod;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
constructor TOnce.Create(const AAnonymousProc: TOnceAnonymousProc);
begin
  Create; // 调用基础构造函�?
  FCallback.CallbackType := octAnonymous;
  FCallback.AnonymousProc := AAnonymousProc;
end;
{$ENDIF}

// ISynchronizable 接口实现
function TOnce.GetLastError: TWaitError;
begin
  // Once 不使用传统的等待错误，总是返回无错�?
  Result := weNone;
end;

// ILock 接口方法已移除：IOnce不再继承ILock
// 这避免了语义混乱，Once不是传统意义的锁

// IOnce Execute 方法实现
procedure TOnce.Execute;
var
  NilProc: TOnceProc;
begin
  case FCallback.CallbackType of
    octNone:
    begin
      NilProc := nil;
      DoInternal(NilProc, False); // 无回调，但仍需标记为完�?
    end;
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
var
  NilProc: TOnceProc;
begin
  case FCallback.CallbackType of
    octNone:
    begin
      NilProc := nil;
      DoInternal(NilProc, True); // 无回调，但仍需标记为完�?
    end;
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



destructor TOnce.Destroy;
begin
  // 销毁互斥锁
  pthread_mutex_destroy(@FMutex);
  inherited Destroy;
end;

// 核心内部实现：高性能原子快速路�?+ 慢速路�?
procedure TOnce.DoInternal(const AProc: TOnceProc; AForce: Boolean);
begin
  // 快速路径：使用 acquire 语义读取，确保内存可见�?
  // 修复：使�?LoadAcquire 替代简单的 FDone 读取，解决内存屏障缺失问�?
  if LoadAcquire(FDone) and not AForce then
  begin
    // 如果是毒化状态且不强制执行，抛出异常
    // 这里仍需要锁，因为状态检查需要与状态设置同�?
    pthread_mutex_lock(@FMutex);
    try
      if FState = STATE_POISONED then
        raise ELockError.Create(rsOnceAlreadyPoisoned);
    finally
      pthread_mutex_unlock(@FMutex);
    end;
    Exit;
  end;

  // 递归调用检测（在获取锁之前检查，避免死锁�?
  if FExecutingThreadId = GetCurrentThreadId then
    raise EOnceRecursiveCall.Create(rsOnceRecursiveCall);

  // 慢速路径：需要同步执�?
  pthread_mutex_lock(@FMutex);
  try
    // 双重检查锁定模�?- 在锁内再次检�?
    if LoadAcquire(FDone) and not AForce then
    begin
      if FState = STATE_POISONED then
        raise ELockError.Create(rsOnceAlreadyPoisoned);
      Exit;
    end;

    // 检查当前状态，确保并发安全
    case FState of
      STATE_NOT_STARTED:
      begin
        // 只有第一个线程能进入这里
        FState := STATE_IN_PROGRESS;
        FExecutingThreadId := GetCurrentThreadId;
      end;

      STATE_IN_PROGRESS:
      begin
        // 其他线程：正在执行中，不强制执行则直接返�?
        if not AForce then
          Exit
        else
        begin
          // 强制执行：重置状�?
          FState := STATE_IN_PROGRESS;
          FExecutingThreadId := GetCurrentThreadId;
        end;
      end;

      STATE_COMPLETED:
      begin
        // 已完成，强制执行时重新执�?
        if AForce then
        begin
          FState := STATE_IN_PROGRESS;
          FExecutingThreadId := GetCurrentThreadId;
        end
        else
          Exit;
      end;

      STATE_POISONED:
      begin
        // 毒化状�?
        if not AForce then
          raise ELockError.Create(rsOnceAlreadyPoisoned)
        else
        begin
          // 强制执行：从毒化状态恢�?
          FState := STATE_IN_PROGRESS;
          FExecutingThreadId := GetCurrentThreadId;
        end;
      end;
    end;

    try
      try
        // 执行用户回调
        if Assigned(AProc) then
          AProc();

        // 标记为已完成
        FState := STATE_COMPLETED;
        // 使用 release 语义存储，确保所有前面的操作对其他线程可�?
        StoreRelease(FDone, True);  // 启用快速路�?
      except
        // 异常处理：标记为毒化状�?
        FState := STATE_POISONED;
        // 使用 release 语义存储，确保毒化状态对其他线程可见
        StoreRelease(FDone, True);  // 即使毒化也设�?Done，避免重复执�?
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
  // 快速路径：使用 acquire 语义读取，确保内存可见�?
  if LoadAcquire(FDone) and not AForce then
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

  // 递归调用检测（在获取锁之前检查，避免死锁�?
  if FExecutingThreadId = GetCurrentThreadId then
    raise EOnceRecursiveCall.Create(rsOnceRecursiveCall);

  // 慢速路径：需要同步执�?
  pthread_mutex_lock(@FMutex);
  try
    if LoadAcquire(FDone) and not AForce then
    begin
      if FState = STATE_POISONED then
        raise ELockError.Create(rsOnceAlreadyPoisoned);
      Exit;
    end;

    // 检查当前状态，确保并发安全
    case FState of
      STATE_NOT_STARTED:
      begin
        FState := STATE_IN_PROGRESS;
        FExecutingThreadId := GetCurrentThreadId;
      end;

      STATE_IN_PROGRESS:
      begin
        if not AForce then
          Exit
        else
        begin
          FState := STATE_IN_PROGRESS;
          FExecutingThreadId := GetCurrentThreadId;
        end;
      end;

      STATE_COMPLETED:
      begin
        if AForce then
        begin
          FState := STATE_IN_PROGRESS;
          FExecutingThreadId := GetCurrentThreadId;
        end
        else
          Exit;
      end;

      STATE_POISONED:
      begin
        if not AForce then
          raise ELockError.Create(rsOnceAlreadyPoisoned)
        else
        begin
          FState := STATE_IN_PROGRESS;
          FExecutingThreadId := GetCurrentThreadId;
        end;
      end;
    end;

    try
      try
        if Assigned(AMethod) then
          AMethod();

        FState := STATE_COMPLETED;
        // 使用 release 语义存储，确保所有前面的操作对其他线程可�?
        StoreRelease(FDone, True);
      except
        FState := STATE_POISONED;
        // 使用 release 语义存储，确保毒化状态对其他线程可见
        StoreRelease(FDone, True);
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
  // 快速路径：使用 acquire 语义读取，确保内存可见�?
  if LoadAcquire(FDone) and not AForce then
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

  // 慢速路径：需要同步执�?
  // 递归调用检测（在获取锁之前检查，避免死锁�?
  if FExecutingThreadId = GetCurrentThreadId then
    raise EOnceRecursiveCall.Create(rsOnceRecursiveCall);

  pthread_mutex_lock(@FMutex);
  try
    if LoadAcquire(FDone) and not AForce then
    begin
      if FState = STATE_POISONED then
        raise ELockError.Create(rsOnceAlreadyPoisoned);
      Exit;
    end;

    // 检查当前状态，确保并发安全
    case FState of
      STATE_NOT_STARTED:
      begin
        FState := STATE_IN_PROGRESS;
        FExecutingThreadId := GetCurrentThreadId;
      end;

      STATE_IN_PROGRESS:
      begin
        if not AForce then
          Exit
        else
        begin
          FState := STATE_IN_PROGRESS;
          FExecutingThreadId := GetCurrentThreadId;
        end;
      end;

      STATE_COMPLETED:
      begin
        if AForce then
        begin
          FState := STATE_IN_PROGRESS;
          FExecutingThreadId := GetCurrentThreadId;
        end
        else
          Exit;
      end;

      STATE_POISONED:
      begin
        if not AForce then
          raise ELockError.Create(rsOnceAlreadyPoisoned)
        else
        begin
          FState := STATE_IN_PROGRESS;
          FExecutingThreadId := GetCurrentThreadId;
        end;
      end;
    end;

    try
      try
        if Assigned(AAnonymousProc) then
          AAnonymousProc();

        FState := STATE_COMPLETED;
        // 使用 release 语义存储，确保所有前面的操作对其他线程可�?
        StoreRelease(FDone, True);
      except
        FState := STATE_POISONED;
        // 使用 release 语义存储，确保毒化状态对其他线程可见
        StoreRelease(FDone, True);
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

// 等待机制实现（Rust 风格�?
procedure TOnce.Wait;
begin
  // 快速路径：使用 acquire 语义读取，确保内存可见�?
  if LoadAcquire(FDone) then
  begin
    // 检查是否毒�?
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
    while not LoadAcquire(FDone) do
    begin
      pthread_mutex_unlock(@FMutex);
      Sleep(1); // 1ms 等待
      pthread_mutex_lock(@FMutex);
    end;

    // 检查最终状�?
    if FState = STATE_POISONED then
      raise ELockError.Create(rsOnceAlreadyPoisoned);
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

procedure TOnce.WaitForce;
begin
  // 强制等待，忽略毒化状态，使用 acquire 语义读取
  while not LoadAcquire(FDone) do
    Sleep(1); // 1ms 等待
end;

// 状态查询方�?
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
      Result := osNotStarted; // 默认�?
    end;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TOnce.GetCompleted: Boolean;
begin
  // 优化：使�?acquire 语义读取，无需�?
  // 如果 FDone �?true，则状态必须是 COMPLETED �?POISONED
  if LoadAcquire(FDone) then
  begin
    // 需要锁来安全读取状�?
    pthread_mutex_lock(@FMutex);
    try
      Result := (FState = STATE_COMPLETED);
    finally
      pthread_mutex_unlock(@FMutex);
    end;
  end
  else
    Result := False; // 未完�?
end;

function TOnce.GetPoisoned: Boolean;
begin
  // 优化：使�?acquire 语义读取，无需�?
  // 如果 FDone �?false，则肯定不是毒化状�?
  if LoadAcquire(FDone) then
  begin
    // 需要锁来安全读取状�?
    pthread_mutex_lock(@FMutex);
    try
      Result := (FState = STATE_POISONED);
    finally
      pthread_mutex_unlock(@FMutex);
    end;
  end
  else
    Result := False; // 未完成，不可能毒�?
end;

// Reset 方法已移�?- 不安全且不符合主流语言实践
// 如需重新执行，请创建新的 Once 实例

end.
