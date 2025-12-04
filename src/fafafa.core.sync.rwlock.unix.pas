unit fafafa.core.sync.rwlock.unix;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.rwlock.base, fafafa.core.atomic;

const
  ETIMEDOUT = 110;  // Connection timed out
  EBUSY = 16;       // Device or resource busy

type
  // ===== 可重入性支�?=====

  { 线程重入记录 }
  PThreadReentryRecord = ^TThreadReentryRecord;
  TThreadReentryRecord = record
    ThreadId: TThreadID;
    ReadCount: Integer;     // 该线程的读锁重入次数
    WriteCount: Integer;    // 该线程的写锁重入次数 (0 �?1)
    Next: PThreadReentryRecord;  // 链表指针
  end;

  { 线程重入管理�?- 优化版本使用 TLS 缓存 }
  TThreadReentryManager = class
  private
    FHead: PThreadReentryRecord;
    FLock: pthread_mutex_t;  // 保护链表的互斥锁

    // 性能统计
    FCacheHits: Integer;     // TLS 缓存命中次数
    FCacheMisses: Integer;   // TLS 缓存未命中次�?

    // 内部方法
    function FindRecordInList(AThreadId: TThreadID): PThreadReentryRecord;
    procedure UpdateTLSCache(ARecord: PThreadReentryRecord);
  public
    constructor Create;
    destructor Destroy; override;

    function GetOrCreateRecord(AThreadId: TThreadID): PThreadReentryRecord;
    function FindRecord(AThreadId: TThreadID): PThreadReentryRecord;
    procedure RemoveRecord(AThreadId: TThreadID);
    procedure Lock;
    procedure Unlock;

    // 性能统计
    function GetCacheHitRate: Double;
    procedure ResetStats;
  end;

  // 前向声明
  TRWLock = class;

  // ===== 读锁守卫实现 =====
  TRWLockReadGuard = class(TInterfacedObject, IRWLockReadGuard)
  private
    FLock: Pointer;  // 使用 Pointer 避免循环引用
    FReleased: Boolean;
    FValid: Boolean;

    function GetLock: TRWLock; inline;
  public
    constructor Create(ALock: TRWLock);
    constructor CreateFromDowngrade(ALock: TRWLock);  // 用于 Downgrade，不重新获取锁
    destructor Destroy; override;

    // IRWLockReadGuard 接口 (继承自 IGuard)
    function IsLocked: Boolean;
    function IsValid: Boolean;  // 向后兼容，等价于 IsLocked
    procedure Release;
  end;

  // ===== 写锁守卫实现 =====
  TRWLockWriteGuard = class(TInterfacedObject, IRWLockWriteGuard)
  private
    FLock: Pointer;  // 使用 Pointer 避免循环引用
    FReleased: Boolean;
    FValid: Boolean;

    function GetLock: TRWLock; inline;
  public
    constructor Create(ALock: TRWLock);
    destructor Destroy; override;

    // IRWLockWriteGuard 接口 (继承自 IGuard)
    function IsLocked: Boolean;
    function IsValid: Boolean;  // 向后兼容，等价于 IsLocked
    procedure Release;
    function Downgrade: IRWLockReadGuard;
  end;

  // ===== RWLock 主实现 =====
  TRWLock = class(TInterfacedObject, IRWLock, IRWLockDiagnostics)
  private
    // 第一个缓存行：核心锁数据（热路径�?
    FRWLock: pthread_rwlock_t;
    FReaderCount: TAtomicCounter; // 版本化原子计数器，防�?ABA 问题
    FWriterThread: TThreadID;     // 写者线程ID
    FLastLockResult: TLockResult; // 最后操作结�?

    // 缓存行对齐填充（确保下一组数据在新缓存行�?
    FPadding1: array[0..63 - (SizeOf(pthread_rwlock_t) + SizeOf(TAtomicCounter) +
                              SizeOf(TThreadID) + SizeOf(TLockResult)) mod 64] of Byte;

    // 第二个缓存行：性能统计数据（较少访问）
    FContentionCount: Integer;    // 竞争计数
    FSpinCount: Integer;          // 自适应自旋次数
    FSuccessCount: Integer;       // 成功获取锁的次数
    FLastAdjustTime: QWord;       // 上次调整自旋次数的时�?
    FAdaptiveWindow: Integer;     // 自适应调整窗口大小

    // 详细性能统计
    FPerfStats: TLockPerformanceStats;

    // 第三个缓存行：管理对象（最少访问）
    FReentryManager: TThreadReentryManager;  // 线程重入管理�?

    // 配置选项
    FOptions: TRWLockOptions;     // 锁配置选项

    // 毒化状态 (Rust-style Poisoning)
    FPoisoned: Boolean;           // 锁是否被毒化
    FPoisoningThreadId: TThreadID; // 导致毒化的线程 ID
    FPoisoningException: string;   // 导致毒化的异常信息

    // 错误处理辅助方法
    procedure HandleSystemError(const AOperation: string);
    procedure HandleTimeout(ATimeoutMs: Cardinal);
    procedure HandleStateError(const AExpectedState, AActualState: string);

    // 可重入性检查辅助方�?
    function CheckReentrancy(AThreadId: TThreadID; out ARecord: PThreadReentryRecord): Boolean;
    procedure UpdateReentryRecord(ARecord: PThreadReentryRecord; AIsRead: Boolean; AIncrement: Boolean);

    // ===== 自适应自旋优化 =====
    procedure UpdateSpinStatistics(Success: Boolean; SpinCount: Integer);
    procedure AdjustSpinCount;
    function CalculateOptimalSpinCount: Integer;
    function TryAcquireReadLockWithSpin: Boolean;
    function TryAcquireWriteLockWithSpin: Boolean;
  public
    constructor Create; overload;
    constructor Create(const Options: TRWLockOptions); overload;
    destructor Destroy; override;

    // ===== ISynchronizable 接口 =====
    function GetLastError: TWaitError;

    // ===== 现代�?API =====
    function Read: IRWLockReadGuard;
    function Write: IRWLockWriteGuard;
    function TryRead(ATimeoutMs: Cardinal = 0): IRWLockReadGuard;
    function TryWrite(ATimeoutMs: Cardinal = 0): IRWLockWriteGuard;

    // ===== 传统 API（继承自 IReadWriteLock�?====
    procedure AcquireRead;
    procedure ReleaseRead;
    procedure AcquireWrite;
    procedure ReleaseWrite;
    function TryAcquireRead: Boolean; overload;
    function TryAcquireRead(ATimeoutMs: Cardinal): Boolean; overload;
    function TryAcquireWrite: Boolean; overload;
    function TryAcquireWrite(ATimeoutMs: Cardinal): Boolean; overload;

    // ===== 扩展 API（统一返回 TLockResult�?====
    function TryAcquireReadEx(ATimeoutMs: Cardinal): TLockResult;
    function TryAcquireWriteEx(ATimeoutMs: Cardinal): TLockResult;

    // ===== 状态查�?=====
    function GetReaderCount: Integer;
    function IsWriteLocked: Boolean;
    function IsReadLocked: Boolean;
    function GetWriterThread: TThreadID;
    function GetMaxReaders: Integer;

    // ===== 性能统计 =====
    function GetContentionCount: Integer;
    function GetSpinCount: Integer;

    // ===== 错误信息 =====
    function GetLastLockResult: TLockResult;

    // ===== 状态验证和恢复 =====
    function ValidateState: Boolean;
    procedure RecoverState;
    function IsHealthy: Boolean;

    // ===== 毒化支持 (Rust-style Poisoning) =====
    function IsPoisoned: Boolean;
    procedure ClearPoison;
    procedure MarkPoisoned(const AExceptionMessage: string);

    // ===== 性能监控接口实现 =====
    function GetPerformanceStats: TLockPerformanceStats;
    procedure ResetPerformanceStats;
    function GetContentionRate: Double;
    function GetAverageWaitTime: Double;
    function GetThroughput: Double;
    function GetSpinEfficiency: Double;

    // ===== 性能统计辅助方法 =====
    procedure UpdatePerformanceStats(IsRead: Boolean; IsAcquire: Boolean; WaitTime: QWord; SpinCount: Integer);
  end;

implementation

// ===== 线程本地存储缓存 =====
threadvar
  // TLS 缓存：每个线程缓存自己的重入记录指针
  ThreadReentryCache: PThreadReentryRecord;

{ TRWLockReadGuard }

function TRWLockReadGuard.GetLock: TRWLock;
begin
  Result := TRWLock(FLock);
end;

constructor TRWLockReadGuard.Create(ALock: TRWLock);
begin
  inherited Create;
  FLock := ALock;
  FReleased := False;
  FValid := Assigned(ALock);

  if FValid then
  begin
    try
      ALock.AcquireRead;
    except
      FValid := False;
      raise;
    end;
  end;
end;

constructor TRWLockReadGuard.CreateFromDowngrade(ALock: TRWLock);
begin
  inherited Create;
  FLock := ALock;
  FReleased := False;
  FValid := Assigned(ALock);
  // 不获取锁 - 假定已经从写锁降级
  // 锁已经由 Downgrade 处理
end;

destructor TRWLockReadGuard.Destroy;
var
  ExObj: TObject;
  ExMsg: string;
  Lock: TRWLock;
begin
  // 检测是否在异常展开过程中（Rust-style Poisoning）
  if IsValid then
  begin
    Lock := GetLock;
    // 只有启用毒化检测时才标记
    if Lock.FOptions.EnablePoisoning then
    begin
      ExObj := ExceptObject;
      if ExObj <> nil then
      begin
        // 有异常且锁有效，标记锁为毒化状态
        if ExObj is Exception then
          ExMsg := Exception(ExObj).Message
        else
          ExMsg := 'Unknown exception';
        Lock.MarkPoisoned(ExMsg);
      end;
    end;
  end;

  Release;
  inherited Destroy;
end;

function TRWLockReadGuard.IsLocked: Boolean;
begin
  Result := FValid and not FReleased;
end;

function TRWLockReadGuard.IsValid: Boolean;
begin
  Result := IsLocked;  // IsValid 为向后兼容的别名
end;

procedure TRWLockReadGuard.Release;
begin
  if IsValid then
  begin
    try
      GetLock.ReleaseRead;
    finally
      FReleased := True;
    end;
  end;
end;

{ TRWLockWriteGuard }

function TRWLockWriteGuard.GetLock: TRWLock;
begin
  Result := TRWLock(FLock);
end;

constructor TRWLockWriteGuard.Create(ALock: TRWLock);
begin
  inherited Create;
  FLock := ALock;
  FReleased := False;
  FValid := Assigned(ALock);

  if FValid then
  begin
    try
      ALock.AcquireWrite;
    except
      FValid := False;
      raise;
    end;
  end;
end;

destructor TRWLockWriteGuard.Destroy;
var
  ExObj: TObject;
  ExMsg: string;
  Lock: TRWLock;
begin
  // 检测是否在异常展开过程中（Rust-style Poisoning）
  if IsValid then
  begin
    Lock := GetLock;
    // 只有启用毒化检测时才标记
    if Lock.FOptions.EnablePoisoning then
    begin
      ExObj := ExceptObject;
      if ExObj <> nil then
      begin
        // 有异常且锁有效，标记锁为毒化状态
        if ExObj is Exception then
          ExMsg := Exception(ExObj).Message
        else
          ExMsg := 'Unknown exception';
        Lock.MarkPoisoned(ExMsg);
      end;
    end;
  end;

  Release;
  inherited Destroy;
end;

function TRWLockWriteGuard.IsLocked: Boolean;
begin
  Result := FValid and not FReleased;
end;

function TRWLockWriteGuard.IsValid: Boolean;
begin
  Result := IsLocked;  // IsValid 为向后兼容的别名
end;

procedure TRWLockWriteGuard.Release;
begin
  if IsValid then
  begin
    try
      GetLock.ReleaseWrite;
    finally
      FReleased := True;
    end;
  end;
end;

function TRWLockWriteGuard.Downgrade: IRWLockReadGuard;
var
  Lock: TRWLock;
  CurrentThreadId: TThreadID;
  ReentryRecord: PThreadReentryRecord;
begin
  if not IsValid then
  begin
    // 守卫无效，返回一个无效的读守卫
    Result := TRWLockReadGuard.CreateFromDowngrade(nil);
    Exit;
  end;

  Lock := GetLock;
  CurrentThreadId := GetCurrentThreadId;
  
  // 在重入管理器中更新状态：写锁 -> 读锁
  Lock.FReentryManager.Lock;
  try
    ReentryRecord := Lock.FReentryManager.FindRecord(CurrentThreadId);
    if ReentryRecord <> nil then
    begin
      // 完全清除写锁计数
      ReentryRecord^.WriteCount := 0;
      // 增加读锁计数
      Inc(ReentryRecord^.ReadCount);
    end;
    
    // 更新内部状态
    AtomicIncrementCounter(Lock.FReaderCount);
    Lock.FWriterThread := 0;
  finally
    Lock.FReentryManager.Unlock;
  end;
  
  // 先释放写锁（用原始 pthread 调用，不经过 ReleaseWrite）
  pthread_rwlock_unlock(@Lock.FRWLock);
  
  // 立即获取读锁
  pthread_rwlock_rdlock(@Lock.FRWLock);
  
  // 创建新的读守卫
  Result := TRWLockReadGuard.CreateFromDowngrade(Lock);
  
  // 失效当前写守卫
  FReleased := True;
end;

{ TThreadReentryManager }

constructor TThreadReentryManager.Create;
begin
  inherited Create;
  FHead := nil;
  FCacheHits := 0;
  FCacheMisses := 0;
  if pthread_mutex_init(@FLock, nil) <> 0 then
    raise ELockError.Create('Failed to initialize reentry manager mutex');
end;

destructor TThreadReentryManager.Destroy;
var
  Current, Next: PThreadReentryRecord;
begin
  // 清理所有记�?
  Current := FHead;
  while Current <> nil do
  begin
    Next := Current^.Next;
    Dispose(Current);
    Current := Next;
  end;

  pthread_mutex_destroy(@FLock);
  inherited Destroy;
end;

procedure TThreadReentryManager.Lock;
begin
  pthread_mutex_lock(@FLock);
end;

procedure TThreadReentryManager.Unlock;
begin
  pthread_mutex_unlock(@FLock);
end;

// 优化�?FindRecord 方法：首先检�?TLS 缓存
function TThreadReentryManager.FindRecord(AThreadId: TThreadID): PThreadReentryRecord;
begin
  // 第一步：检�?TLS 缓存
  if (ThreadReentryCache <> nil) and (ThreadReentryCache^.ThreadId = AThreadId) then
  begin
    Result := ThreadReentryCache;
    InterlockedIncrement(FCacheHits);
    Exit;
  end;

  // 第二步：在链表中查找
  Result := FindRecordInList(AThreadId);
  InterlockedIncrement(FCacheMisses);

  // 第三步：更新 TLS 缓存
  if Result <> nil then
    UpdateTLSCache(Result);
end;

// 在链表中查找记录（原始实现）
function TThreadReentryManager.FindRecordInList(AThreadId: TThreadID): PThreadReentryRecord;
var
  Current: PThreadReentryRecord;
begin
  Result := nil;
  Current := FHead;
  while Current <> nil do
  begin
    if Current^.ThreadId = AThreadId then
    begin
      Result := Current;
      Exit;
    end;
    Current := Current^.Next;
  end;
end;

// 更新 TLS 缓存
procedure TThreadReentryManager.UpdateTLSCache(ARecord: PThreadReentryRecord);
begin
  ThreadReentryCache := ARecord;
end;

function TThreadReentryManager.GetOrCreateRecord(AThreadId: TThreadID): PThreadReentryRecord;
begin
  Result := FindRecord(AThreadId);
  if Result = nil then
  begin
    // 创建新记�?
    New(Result);
    Result^.ThreadId := AThreadId;
    Result^.ReadCount := 0;
    Result^.WriteCount := 0;
    Result^.Next := FHead;
    FHead := Result;

    // 立即更新 TLS 缓存
    UpdateTLSCache(Result);
  end;
end;

procedure TThreadReentryManager.RemoveRecord(AThreadId: TThreadID);
var
  Current, Prev: PThreadReentryRecord;
begin
  Current := FHead;
  Prev := nil;

  while Current <> nil do
  begin
    if Current^.ThreadId = AThreadId then
    begin
      // 清理 TLS 缓存
      if ThreadReentryCache = Current then
        ThreadReentryCache := nil;

      // 找到要删除的记录
      if Prev = nil then
        FHead := Current^.Next
      else
        Prev^.Next := Current^.Next;

      Dispose(Current);
      Exit;
    end;
    Prev := Current;
    Current := Current^.Next;
  end;
end;

// 性能统计方法
function TThreadReentryManager.GetCacheHitRate: Double;
var
  Total: Integer;
begin
  Total := FCacheHits + FCacheMisses;
  if Total = 0 then
    Result := 0.0
  else
    Result := FCacheHits / Total;
end;

procedure TThreadReentryManager.ResetStats;
begin
  FCacheHits := 0;
  FCacheMisses := 0;
end;

{ TRWLock }

// 可重入性检查辅助方�?
function TRWLock.CheckReentrancy(AThreadId: TThreadID; out ARecord: PThreadReentryRecord): Boolean;
begin
  Result := Assigned(FReentryManager);
  ARecord := nil;

  if Result then
  begin
    FReentryManager.Lock;
    try
      ARecord := FReentryManager.FindRecord(AThreadId);
    finally
      FReentryManager.Unlock;
    end;
  end;
end;

procedure TRWLock.UpdateReentryRecord(ARecord: PThreadReentryRecord; AIsRead: Boolean; AIncrement: Boolean);
begin
  if not Assigned(FReentryManager) then
    Exit;

  FReentryManager.Lock;
  try
    if AIsRead then
    begin
      if AIncrement then
        Inc(ARecord^.ReadCount)
      else
        Dec(ARecord^.ReadCount);
    end
    else
    begin
      if AIncrement then
        Inc(ARecord^.WriteCount)
      else
        Dec(ARecord^.WriteCount);
    end;
  finally
    FReentryManager.Unlock;
  end;
end;

constructor TRWLock.Create;
var
  Options: TRWLockOptions;
begin
  // 创建默认配置
  Options.AllowReentrancy := True;
  Options.FairMode := False;
  Options.WriterPriority := False;
  Options.MaxReaders := 1024;
  Options.SpinCount := 4000;
  Options.EnablePoisoning := True;   // 默认启用毒化检测（类似 Rust）
  Options.ReaderBiasEnabled := True; // 默认启用读偏向优化

  Create(Options);
end;

constructor TRWLock.Create(const Options: TRWLockOptions);
var
  Attr: pthread_rwlockattr_t;
begin
  inherited Create;

  // 保存配置选项
  FOptions := Options;

  // 初始化读写锁属�?
  if pthread_rwlockattr_init(@Attr) <> 0 then
    raise ELockError.Create('Failed to initialize rwlock attributes');

  // 设置为进程内共享
  if pthread_rwlockattr_setpshared(@Attr, PTHREAD_PROCESS_PRIVATE) <> 0 then
  begin
    pthread_rwlockattr_destroy(@Attr);
    raise ELockError.Create('Failed to set rwlock pshared attribute');
  end;

  // NOTE: setkind_np 禁用以避免 glibc 优先级继承问题
  // 使用默认的 pthread_rwlock 行为
  // {$IFDEF LINUX}
  // if FOptions.WriterPriority then
  //   pthread_rwlockattr_setkind_np(@Attr, PTHREAD_RWLOCK_PREFER_WRITER_NONRECURSIVE_NP)
  // else if FOptions.FairMode then
  //   pthread_rwlockattr_setkind_np(@Attr, PTHREAD_RWLOCK_PREFER_READER_NP)
  // else
  //   pthread_rwlockattr_setkind_np(@Attr, PTHREAD_RWLOCK_PREFER_WRITER_NONRECURSIVE_NP);
  // {$ENDIF}

  // 初始化读写锁
  if pthread_rwlock_init(@FRWLock, @Attr) <> 0 then
  begin
    pthread_rwlockattr_destroy(@Attr);
    raise ELockError.Create('Failed to initialize pthread rwlock');
  end;

  pthread_rwlockattr_destroy(@Attr);

  // 初始化版本化原子计数�?
  AtomicStoreCounter(FReaderCount, 0);
  FWriterThread := 0;
  atomic_store(FContentionCount, 0);
  atomic_store(FSpinCount, FOptions.SpinCount);  // 使用配置的自旋次�?
  atomic_store(FSuccessCount, 0);
  FLastAdjustTime := GetTickCount64;
  FAdaptiveWindow := 100;  // �?00次操作调整一�?
  FLastLockResult := lrSuccess;

  // 初始化性能统计
  ResetPerformanceStats;

  // 根据配置初始化重入管理器
  if FOptions.AllowReentrancy then
    FReentryManager := TThreadReentryManager.Create
  else
    FReentryManager := nil;
end;

destructor TRWLock.Destroy;
begin
  // 清理重入管理器（如果存在�?
  if Assigned(FReentryManager) then
    FReentryManager.Free;

  pthread_rwlock_destroy(@FRWLock);
  inherited Destroy;
end;

// ===== ISynchronizable 接口 =====

function TRWLock.GetLastError: TWaitError;
begin
  case FLastLockResult of
    lrSuccess: Result := weNone;
    lrTimeout: Result := weTimeout;  // 修复：超时应该映射为 weTimeout
    lrWouldBlock: Result := weResourceExhausted;
    lrError: Result := weSystemError;
  else
    Result := weSystemError;
  end;
end;

// ===== 现代�?API =====

function TRWLock.Read: IRWLockReadGuard;
begin
  Result := TRWLockReadGuard.Create(Self);
end;

function TRWLock.Write: IRWLockWriteGuard;
begin
  Result := TRWLockWriteGuard.Create(Self);
end;

function TRWLock.TryRead(ATimeoutMs: Cardinal): IRWLockReadGuard;
var
  Guard: TRWLockReadGuard;
begin
  Result := nil;

  // 毒化检查 (Rust-style Poisoning) - TryRead 返回 nil 而不是抛异常
  if FOptions.EnablePoisoning and FPoisoned then
    Exit;

  if TryAcquireReadEx(ATimeoutMs) = lrSuccess then
  begin
    // 创建一个特殊的守卫，不再次获取�?
    Guard := TRWLockReadGuard.Create(nil);

    // 手动设置守卫状态（绕过构造函数的 AcquireRead 调用�?
    Guard.FLock := Self;
    Guard.FValid := True;
    Guard.FReleased := False;

    Result := Guard;
  end;
end;

function TRWLock.TryWrite(ATimeoutMs: Cardinal): IRWLockWriteGuard;
var
  Guard: TRWLockWriteGuard;
  AcqResult: TLockResult;
begin
  Result := nil;

  // 毒化检查 (Rust-style Poisoning) - TryWrite 返回 nil 而不是抛异常
  if FOptions.EnablePoisoning and FPoisoned then
    Exit;

  AcqResult := TryAcquireWriteEx(ATimeoutMs);
  if AcqResult = lrSuccess then
  begin
    // 创建一个特殊的守卫，不再次获取锁
    Guard := TRWLockWriteGuard.Create(nil);

    // 手动设置守卫状态（绕过构造函数的 AcquireWrite 调用）
    Guard.FLock := Self;
    Guard.FValid := True;
    Guard.FReleased := False;

    Result := Guard;
  end;
end;

// ===== 传统 API =====

procedure TRWLock.AcquireRead;
var
  CurrentThreadId: TThreadID;
  ReentryRecord: PThreadReentryRecord;
  NeedSystemLock: Boolean;
  StartTime: QWord;
  CurrentReaders: Integer;
begin
  // 毒化检查 (Rust-style Poisoning)
  if FOptions.EnablePoisoning and FPoisoned then
    raise ERWLockPoisonError.Create(FPoisoningThreadId, FPoisoningException);

  // ===== 快速路径：非重入模式 =====
  // 当禁用重入支持时，直接使用 pthread_rwlock，避免管理器锁开销
  if not FOptions.AllowReentrancy then
  begin
    // MaxReaders 检查
    CurrentReaders := AtomicLoadCounter(FReaderCount);
    if CurrentReaders >= FOptions.MaxReaders then
      raise ERWLockCapacityException.Create(1, FOptions.MaxReaders, GetCurrentThreadId);

    if not TryAcquireReadLockWithSpin then
      raise ELockError.Create('Failed to acquire read lock');
    AtomicIncrementCounter(FReaderCount);
    Exit;
  end;

  // ===== 慢路径：支持重入 =====
  StartTime := GetTickCount64;
  CurrentThreadId := GetCurrentThreadId;
  NeedSystemLock := True;

  // 第一阶段：快速检查可重入性
  FReentryManager.Lock;
  try
    ReentryRecord := FReentryManager.FindRecord(CurrentThreadId);

    if ReentryRecord <> nil then
    begin
      // 该线程已经持有锁
      if ReentryRecord^.WriteCount > 0 then
      begin
        // 该线程持有写锁，可以直接获取读锁（写锁降级）
        Inc(ReentryRecord^.ReadCount);
        AtomicIncrementCounter(FReaderCount);
        NeedSystemLock := False;
      end
      else if ReentryRecord^.ReadCount > 0 then
      begin
        // 该线程已经持有读锁，可重入
        Inc(ReentryRecord^.ReadCount);
        AtomicIncrementCounter(FReaderCount);
        NeedSystemLock := False;
      end;
    end;
  finally
    FReentryManager.Unlock;
  end;

  // 如果不需要系统锁，直接返回
  if not NeedSystemLock then
    Exit;

  // MaxReaders 检查（在获取系统锁之前）
  CurrentReaders := AtomicLoadCounter(FReaderCount);
  if CurrentReaders >= FOptions.MaxReaders then
    raise ERWLockCapacityException.Create(1, FOptions.MaxReaders, GetCurrentThreadId);

  // 第二阶段：获取系统锁（在管理器锁外部）
  // 使用自适应自旋优化
  if not TryAcquireReadLockWithSpin then
    raise ELockError.Create('Failed to acquire read lock');

  // 第三阶段：更新重入记录
  FReentryManager.Lock;
  try
    // 重新查找记录（可能在等待期间被其他操作修改）
    ReentryRecord := FReentryManager.FindRecord(CurrentThreadId);
    if ReentryRecord = nil then
      ReentryRecord := FReentryManager.GetOrCreateRecord(CurrentThreadId);

    Inc(ReentryRecord^.ReadCount);
    AtomicIncrementCounter(FReaderCount);

    // 确保读锁获取的内存可见性
    MemoryBarrierAcquire;
  finally
    FReentryManager.Unlock;
  end;

  // 更新性能统计
  UpdatePerformanceStats(True, True, GetTickCount64 - StartTime, 0);
end;

procedure TRWLock.ReleaseRead;
var
  CurrentThreadId: TThreadID;
  ReentryRecord: PThreadReentryRecord;
  ShouldUnlock: Boolean;
begin
  // ===== 快速路径：非重入模式 =====
  if not FOptions.AllowReentrancy then
  begin
    AtomicDecrementCounter(FReaderCount);
    if pthread_rwlock_unlock(@FRWLock) <> 0 then
      raise ELockError.Create('Failed to release read lock');
    Exit;
  end;

  // ===== 慢路径：支持重入 =====
  CurrentThreadId := GetCurrentThreadId;
  ShouldUnlock := False;

  FReentryManager.Lock;
  try
    ReentryRecord := FReentryManager.FindRecord(CurrentThreadId);

    if ReentryRecord = nil then
      raise ERWLockStateError.Create('Read lock not held', 'Released', CurrentThreadId);

    if ReentryRecord^.ReadCount <= 0 then
      raise ERWLockStateError.Create('Read lock not held', 'Released', CurrentThreadId);

    // 确保释放前的内存操作完成
    MemoryBarrierRelease;

    // 减少重入计数
    Dec(ReentryRecord^.ReadCount);
    AtomicDecrementCounter(FReaderCount);

    // 如果该线程的读锁计数�?且没有写锁，则需要真正释放系统锁
    if (ReentryRecord^.ReadCount = 0) and (ReentryRecord^.WriteCount = 0) then
    begin
      ShouldUnlock := True;
      // 清理该线程的记录
      FReentryManager.RemoveRecord(CurrentThreadId);
    end;

  finally
    FReentryManager.Unlock;
  end;

  // 在锁外部调用系统 API，避免死�?
  if ShouldUnlock then
  begin
    if pthread_rwlock_unlock(@FRWLock) <> 0 then
      raise ELockError.Create('Failed to release read lock');
  end;
end;

procedure TRWLock.AcquireWrite;
var
  CurrentThreadId: TThreadID;
  ReentryRecord: PThreadReentryRecord;
  NeedSystemLock: Boolean;
begin
  // 毒化检查 (Rust-style Poisoning)
  if FOptions.EnablePoisoning and FPoisoned then
    raise ERWLockPoisonError.Create(FPoisoningThreadId, FPoisoningException);

  // ===== 快速路径：非重入模式 =====
  if not FOptions.AllowReentrancy then
  begin
    if not TryAcquireWriteLockWithSpin then
      raise ELockError.Create('Failed to acquire write lock');
    FWriterThread := GetCurrentThreadId;
    Exit;
  end;

  // ===== 慢路径：支持重入 =====
  CurrentThreadId := GetCurrentThreadId;
  NeedSystemLock := True;

  // 第一阶段：快速检查可重入性和冲突
  FReentryManager.Lock;
  try
    ReentryRecord := FReentryManager.FindRecord(CurrentThreadId);

    if ReentryRecord <> nil then
    begin
      if ReentryRecord^.WriteCount > 0 then
      begin
        // 该线程已经持有写锁，可重�?
        Inc(ReentryRecord^.WriteCount);
        NeedSystemLock := False;
      end
      else if ReentryRecord^.ReadCount > 0 then
      begin
        // 该线程持有读锁，不能升级为写锁（避免死锁�?
        raise ERWLockDeadlockError.Create(CurrentThreadId, [CurrentThreadId]);
      end;
    end;
  finally
    FReentryManager.Unlock;
  end;

  // 如果不需要系统锁，直接返�?
  if not NeedSystemLock then
    Exit;

  // 第二阶段：获取系统锁（在管理器锁外部�?
  // 使用自适应自旋优化
  if not TryAcquireWriteLockWithSpin then
    raise ELockError.Create('Failed to acquire write lock');

  // 第三阶段：更新重入记�?
  FReentryManager.Lock;
  try
    // 重新查找记录（可能在等待期间被其他操作修改）
    ReentryRecord := FReentryManager.FindRecord(CurrentThreadId);
    if ReentryRecord = nil then
      ReentryRecord := FReentryManager.GetOrCreateRecord(CurrentThreadId);

    Inc(ReentryRecord^.WriteCount);
    FWriterThread := CurrentThreadId;

    // 确保写锁获取的内存可见�?
    MemoryBarrierAcquire;
  finally
    FReentryManager.Unlock;
  end;
end;

procedure TRWLock.ReleaseWrite;
var
  CurrentThreadId: TThreadID;
  ReentryRecord: PThreadReentryRecord;
  ShouldUnlock: Boolean;
begin
  // ===== 快速路径：非重入模式 =====
  if not FOptions.AllowReentrancy then
  begin
    MemoryBarrierRelease;
    FWriterThread := 0;
    if pthread_rwlock_unlock(@FRWLock) <> 0 then
      raise ELockError.Create('Failed to release write lock');
    Exit;
  end;

  // ===== 慢路径：支持重入 =====
  CurrentThreadId := GetCurrentThreadId;
  ShouldUnlock := False;

  FReentryManager.Lock;
  try
    ReentryRecord := FReentryManager.FindRecord(CurrentThreadId);

    if ReentryRecord = nil then
      raise ERWLockStateError.Create('Write lock not held', 'Released', CurrentThreadId);

    if ReentryRecord^.WriteCount <= 0 then
      raise ERWLockStateError.Create('Write lock not held', 'Released', CurrentThreadId);

    // 减少重入计数
    Dec(ReentryRecord^.WriteCount);

    // 如果该线程的写锁计数�?且没有读锁，则需要真正释放系统锁
    if (ReentryRecord^.WriteCount = 0) and (ReentryRecord^.ReadCount = 0) then
    begin
      // 确保释放前的内存操作完成
      MemoryBarrierRelease;

      ShouldUnlock := True;
      FWriterThread := 0;
      // 清理该线程的记录
      FReentryManager.RemoveRecord(CurrentThreadId);
    end;

  finally
    FReentryManager.Unlock;
  end;

  // 在锁外部调用系统 API，避免死�?
  if ShouldUnlock then
  begin
    if pthread_rwlock_unlock(@FRWLock) <> 0 then
      raise ELockError.Create('Failed to release write lock');
  end;
end;

function TRWLock.TryAcquireRead: Boolean;
var
  CurrentThreadId: TThreadID;
  ReentryRecord: PThreadReentryRecord;
  NeedSystemLock: Boolean;
  CurrentReaders: Integer;
begin
  CurrentThreadId := GetCurrentThreadId;
  Result := False;
  NeedSystemLock := True;

  // MaxReaders 检查
  CurrentReaders := AtomicLoadCounter(FReaderCount);
  if CurrentReaders >= FOptions.MaxReaders then
    Exit(False);  // TryAcquire 返回 False 而不是抛异常

  // 第一阶段：快速检查可重入性
  FReentryManager.Lock;
  try
    ReentryRecord := FReentryManager.FindRecord(CurrentThreadId);

    if ReentryRecord <> nil then
    begin
      // 该线程已经持有锁
      if ReentryRecord^.WriteCount > 0 then
      begin
        // 该线程持有写锁，可以直接获取读锁（写锁降级）
        Inc(ReentryRecord^.ReadCount);
        AtomicIncrementCounter(FReaderCount);
        Result := True;
        NeedSystemLock := False;
      end
      else if ReentryRecord^.ReadCount > 0 then
      begin
        // 该线程已经持有读锁，可重�?
        Inc(ReentryRecord^.ReadCount);
        AtomicIncrementCounter(FReaderCount);
        Result := True;
        NeedSystemLock := False;
      end;
    end;
  finally
    FReentryManager.Unlock;
  end;

  // 如果不需要系统锁，直接返�?
  if not NeedSystemLock then
    Exit;

  // 第二阶段：尝试获取系统锁
  if pthread_rwlock_tryrdlock(@FRWLock) = 0 then
  begin
    // 第三阶段：更新重入记�?
    FReentryManager.Lock;
    try
      ReentryRecord := FReentryManager.FindRecord(CurrentThreadId);
      if ReentryRecord = nil then
        ReentryRecord := FReentryManager.GetOrCreateRecord(CurrentThreadId);

      Inc(ReentryRecord^.ReadCount);
      AtomicIncrementCounter(FReaderCount);
      Result := True;
    finally
      FReentryManager.Unlock;
    end;
  end;
end;

function TRWLock.TryAcquireRead(ATimeoutMs: Cardinal): Boolean;
begin
  Result := TryAcquireReadEx(ATimeoutMs) = lrSuccess;
end;

function TRWLock.TryAcquireReadEx(ATimeoutMs: Cardinal): TLockResult;
var
  CurrentThreadId: TThreadID;
  ReentryRecord: PThreadReentryRecord;
  AbsTime: timespec;
  CurrentTime: timeval;
  NanoSecs: Int64;
  LockResult: Integer;
  NeedSystemLock: Boolean;
begin
  CurrentThreadId := GetCurrentThreadId;

  if ATimeoutMs = 0 then
  begin
    if TryAcquireRead then
    begin
      Result := lrSuccess;
      FLastLockResult := lrSuccess;
    end
    else
    begin
      Result := lrWouldBlock;
      FLastLockResult := lrWouldBlock;
    end;
    Exit;
  end;

  NeedSystemLock := True;

  // 第一阶段：快速检查可重入�?
  FReentryManager.Lock;
  try
    ReentryRecord := FReentryManager.FindRecord(CurrentThreadId);

    if ReentryRecord <> nil then
    begin
      // 该线程已经持有锁
      if ReentryRecord^.WriteCount > 0 then
      begin
        // 该线程持有写锁，可以直接获取读锁（写锁降级）
        Inc(ReentryRecord^.ReadCount);
        AtomicIncrementCounter(FReaderCount);
        Result := lrSuccess;
        FLastLockResult := lrSuccess;
        NeedSystemLock := False;
      end
      else if ReentryRecord^.ReadCount > 0 then
      begin
        // 该线程已经持有读锁，可重�?
        Inc(ReentryRecord^.ReadCount);
        AtomicIncrementCounter(FReaderCount);
        Result := lrSuccess;
        FLastLockResult := lrSuccess;
        NeedSystemLock := False;
      end;
    end;
  finally
    FReentryManager.Unlock;
  end;

  // 如果不需要系统锁，直接返�?
  if not NeedSystemLock then
    Exit;

  // 第二阶段：计算绝对超时时间并获取系统�?
  fpgettimeofday(@CurrentTime, nil);
  NanoSecs := (CurrentTime.tv_sec * 1000000000) + (CurrentTime.tv_usec * 1000) + (ATimeoutMs * 1000000);
  AbsTime.tv_sec := NanoSecs div 1000000000;
  AbsTime.tv_nsec := NanoSecs mod 1000000000;

  LockResult := pthread_rwlock_timedrdlock(@FRWLock, @AbsTime);
  case LockResult of
    0: begin
      // 第三阶段：更新重入记�?
      FReentryManager.Lock;
      try
        ReentryRecord := FReentryManager.FindRecord(CurrentThreadId);
        if ReentryRecord = nil then
          ReentryRecord := FReentryManager.GetOrCreateRecord(CurrentThreadId);

        Inc(ReentryRecord^.ReadCount);
        AtomicIncrementCounter(FReaderCount);
        Result := lrSuccess;
        FLastLockResult := lrSuccess;
      finally
        FReentryManager.Unlock;
      end;
    end;
    ETIMEDOUT: begin
      Result := lrTimeout;
      FLastLockResult := lrTimeout;
    end;
    EBUSY: begin
      Result := lrWouldBlock;
      FLastLockResult := lrWouldBlock;
    end;
    else begin
      Result := lrError;
      FLastLockResult := lrError;
    end;
  end;
end;

function TRWLock.TryAcquireWrite: Boolean;
var
  CurrentThreadId: TThreadID;
  ReentryRecord: PThreadReentryRecord;
  NeedSystemLock: Boolean;
begin
  CurrentThreadId := GetCurrentThreadId;
  Result := False;
  NeedSystemLock := True;

  // 第一阶段：快速检查可重入性和冲突
  FReentryManager.Lock;
  try
    ReentryRecord := FReentryManager.FindRecord(CurrentThreadId);

    if ReentryRecord <> nil then
    begin
      if ReentryRecord^.WriteCount > 0 then
      begin
        // 该线程已经持有写锁，可重�?
        Inc(ReentryRecord^.WriteCount);
        Result := True;
        NeedSystemLock := False;
      end
      else if ReentryRecord^.ReadCount > 0 then
      begin
        // 该线程持有读锁，不能升级为写�?
        Result := False;
        NeedSystemLock := False;
      end;
    end;
  finally
    FReentryManager.Unlock;
  end;

  // 如果不需要系统锁，直接返�?
  if not NeedSystemLock then
    Exit;

  // 第二阶段：尝试获取系统锁
  if pthread_rwlock_trywrlock(@FRWLock) = 0 then
  begin
    // 第三阶段：更新重入记�?
    FReentryManager.Lock;
    try
      ReentryRecord := FReentryManager.FindRecord(CurrentThreadId);
      if ReentryRecord = nil then
        ReentryRecord := FReentryManager.GetOrCreateRecord(CurrentThreadId);

      Inc(ReentryRecord^.WriteCount);
      FWriterThread := CurrentThreadId;
      Result := True;
    finally
      FReentryManager.Unlock;
    end;
  end;
end;

function TRWLock.TryAcquireWrite(ATimeoutMs: Cardinal): Boolean;
begin
  Result := TryAcquireWriteEx(ATimeoutMs) = lrSuccess;
end;

function TRWLock.TryAcquireWriteEx(ATimeoutMs: Cardinal): TLockResult;
var
  CurrentThreadId: TThreadID;
  ReentryRecord: PThreadReentryRecord;
  AbsTime: timespec;
  CurrentTime: timeval;
  NanoSecs: Int64;
  LockResult: Integer;
  NeedSystemLock: Boolean;
begin
  CurrentThreadId := GetCurrentThreadId;

  if ATimeoutMs = 0 then
  begin
    if TryAcquireWrite then
    begin
      Result := lrSuccess;
      FLastLockResult := lrSuccess;
    end
    else
    begin
      Result := lrWouldBlock;
      FLastLockResult := lrWouldBlock;
    end;
    Exit;
  end;

  NeedSystemLock := True;

  // 第一阶段：快速检查可重入性和冲突
  FReentryManager.Lock;
  try
    ReentryRecord := FReentryManager.FindRecord(CurrentThreadId);

    if ReentryRecord <> nil then
    begin
      if ReentryRecord^.WriteCount > 0 then
      begin
        // 该线程已经持有写锁，可重�?
        Inc(ReentryRecord^.WriteCount);
        Result := lrSuccess;
        FLastLockResult := lrSuccess;
        Exit;  // 直接返回，不需要调用系�?API
      end
      else if ReentryRecord^.ReadCount > 0 then
      begin
        // 该线程持有读锁，不能升级为写�?
        Result := lrWouldBlock;
        FLastLockResult := lrWouldBlock;
        Exit;  // 直接返回
      end;
    end;
  finally
    FReentryManager.Unlock;
  end;

  // 第二阶段：计算绝对超时时间并获取系统�?
  fpgettimeofday(@CurrentTime, nil);
  NanoSecs := (CurrentTime.tv_sec * 1000000000) + (CurrentTime.tv_usec * 1000) + (ATimeoutMs * 1000000);
  AbsTime.tv_sec := NanoSecs div 1000000000;
  AbsTime.tv_nsec := NanoSecs mod 1000000000;

  LockResult := pthread_rwlock_timedwrlock(@FRWLock, @AbsTime);
  case LockResult of
    0: begin
      // 第三阶段：更新重入记录（首次获取锁）
      FReentryManager.Lock;
      try
        ReentryRecord := FReentryManager.FindRecord(CurrentThreadId);
        if ReentryRecord = nil then
          ReentryRecord := FReentryManager.GetOrCreateRecord(CurrentThreadId);

        Inc(ReentryRecord^.WriteCount);
        FWriterThread := CurrentThreadId;
        Result := lrSuccess;
        FLastLockResult := lrSuccess;
      finally
        FReentryManager.Unlock;
      end;
    end;
    ETIMEDOUT: begin
      Result := lrTimeout;
      FLastLockResult := lrTimeout;
    end;
    EBUSY: begin
      Result := lrWouldBlock;
      FLastLockResult := lrWouldBlock;
    end;
    else begin
      Result := lrError;
      FLastLockResult := lrError;
    end;
  end;
end;

// ===== 状态查�?=====

function TRWLock.GetReaderCount: Integer;
begin
  Result := AtomicLoadCounter(FReaderCount);  // 原子读取，防�?ABA 问题
end;

function TRWLock.IsWriteLocked: Boolean;
begin
  Result := FWriterThread <> 0;
end;

function TRWLock.IsReadLocked: Boolean;
begin
  Result := AtomicLoadCounter(FReaderCount) > 0;
end;

function TRWLock.GetWriterThread: TThreadID;
begin
  Result := FWriterThread;
end;

function TRWLock.GetMaxReaders: Integer;
begin
  // 返回配置的最大读者数量
  Result := FOptions.MaxReaders;
end;

// ===== 性能统计 =====

function TRWLock.GetContentionCount: Integer;
begin
  Result := atomic_load(FContentionCount);
end;

function TRWLock.GetSpinCount: Integer;
begin
  Result := atomic_load(FSpinCount);
end;

// ===== 错误信息 =====

function TRWLock.GetLastLockResult: TLockResult;
begin
  Result := FLastLockResult;
end;

// ===== 错误处理辅助方法 =====

procedure TRWLock.HandleSystemError(const AOperation: string);
var
  ErrorCode: Integer;
  ErrorMsg: string;
begin
  ErrorCode := fpgeterrno;
  case ErrorCode of
    ESysETIMEDOUT:
      begin
        FLastLockResult := lrTimeout;
        ErrorMsg := 'Operation timed out';
      end;
    ESysEINVAL:
      begin
        FLastLockResult := lrError;
        ErrorMsg := 'Invalid parameter';
      end;
    ESysEDEADLK:
      begin
        FLastLockResult := lrError;
        ErrorMsg := 'Deadlock detected';
      end;
    ESysEBUSY:
      begin
        FLastLockResult := lrWouldBlock;
        ErrorMsg := 'Resource busy';
      end;
    ESysEPERM:
      begin
        FLastLockResult := lrError;
        ErrorMsg := 'Operation not permitted';
      end;
  else
    FLastLockResult := lrError;
    ErrorMsg := Format('System error %d', [ErrorCode]);
  end;

  raise ERWLockSystemError.Create(ErrorCode, ErrorMsg, GetCurrentThreadId);
end;

procedure TRWLock.HandleTimeout(ATimeoutMs: Cardinal);
begin
  FLastLockResult := lrTimeout;
  raise ERWLockTimeoutError.Create(ATimeoutMs, GetCurrentThreadId);
end;

procedure TRWLock.HandleStateError(const AExpectedState, AActualState: string);
begin
  FLastLockResult := lrError;
  raise ERWLockStateError.Create(AExpectedState, AActualState, GetCurrentThreadId);
end;

// ===== 状态验证和恢复 =====

function TRWLock.ValidateState: Boolean;
var
  CurrentReaderCount: Integer;
  CurrentWriterThread: TThreadID;
begin
  Result := True;

  // 读取当前状�?
  CurrentReaderCount := AtomicLoadCounter(FReaderCount);
  CurrentWriterThread := FWriterThread;

  // 验证读者计数不能为负数
  if CurrentReaderCount < 0 then
  begin
    Result := False;
    Exit;
  end;

  // 验证写锁状态一致�?
  if IsWriteLocked then
  begin
    // 如果有写锁，读者计数应该为0
    if CurrentReaderCount > 0 then
    begin
      Result := False;
      Exit;
    end;

    // 写者线程ID应该有效
    if CurrentWriterThread = 0 then
    begin
      Result := False;
      Exit;
    end;
  end
  else
  begin
    // 如果没有写锁，写者线程ID应该�?
    if CurrentWriterThread <> 0 then
    begin
      Result := False;
      Exit;
    end;
  end;

  // 验证读锁状态一致�?
  if IsReadLocked then
  begin
    // 如果有读锁，读者计数应该大�?
    if CurrentReaderCount <= 0 then
    begin
      Result := False;
      Exit;
    end;

    // 如果有读锁，不应该有写锁
    if IsWriteLocked then
    begin
      Result := False;
      Exit;
    end;
  end
  else
  begin
    // 如果没有读锁，读者计数应该为0
    if CurrentReaderCount <> 0 then
    begin
      Result := False;
      Exit;
    end;
  end;
end;

procedure TRWLock.RecoverState;
begin
  // 尝试恢复锁状�?
  try
    // 重置读者计�?
    if AtomicLoadCounter(FReaderCount) < 0 then
      AtomicStoreCounter(FReaderCount, 0);

    // 检查写锁状�?
    if not IsWriteLocked and (FWriterThread <> 0) then
      FWriterThread := 0;

    // 重置错误状�?
    FLastLockResult := lrSuccess;

    // 重置竞争统计（可选）
    if FContentionCount < 0 then
      FContentionCount := 0;

  except
    on E: Exception do
    begin
      // 恢复失败，记录错�?
      FLastLockResult := lrError;
      raise ERWLockSystemError.Create(0, 'State recovery failed: ' + E.Message, GetCurrentThreadId);
    end;
  end;
end;

function TRWLock.IsHealthy: Boolean;
begin
  Result := ValidateState and (FLastLockResult <> lrError);
end;

// ===== 自适应自旋优化实现 =====

procedure TRWLock.UpdateSpinStatistics(Success: Boolean; SpinCount: Integer);
begin
  // 更新统计信息
  if Success then
  begin
    atomic_increment(FSuccessCount);
    // 成功获取锁，可能减少竞争计数
    if atomic_load(FContentionCount) > 0 then
      atomic_decrement(FContentionCount);
  end
  else
  begin
    // 失败或需要自旋，增加竞争计数
    atomic_increment(FContentionCount);
  end;

  // 定期调整自旋次数
  if (atomic_load(FSuccessCount) + atomic_load(FContentionCount)) mod FAdaptiveWindow = 0 then
    AdjustSpinCount;
end;

procedure TRWLock.AdjustSpinCount;
var
  CurrentTime: QWord;
  TimeDelta: QWord;
  ContentionRate: Double;
  NewSpinCount: Integer;
begin
  CurrentTime := GetTickCount64;
  TimeDelta := CurrentTime - FLastAdjustTime;

  // 至少间隔100ms才调�?
  if TimeDelta < 100 then
    Exit;

  // 计算竞争�?
  if (atomic_load(FSuccessCount) + atomic_load(FContentionCount)) > 0 then
    ContentionRate := atomic_load(FContentionCount) / (atomic_load(FSuccessCount) + atomic_load(FContentionCount))
  else
    ContentionRate := 0.0;

  NewSpinCount := CalculateOptimalSpinCount;

  // 平滑调整，避免剧烈变�?
  if NewSpinCount > atomic_load(FSpinCount) then
    atomic_store(FSpinCount, atomic_load(FSpinCount) + ((NewSpinCount - atomic_load(FSpinCount)) div 4))
  else if NewSpinCount < atomic_load(FSpinCount) then
    atomic_store(FSpinCount, atomic_load(FSpinCount) - ((atomic_load(FSpinCount) - NewSpinCount) div 4));

  // 限制范围
  if atomic_load(FSpinCount) < 100 then
    atomic_store(FSpinCount, 100)
  else if atomic_load(FSpinCount) > 16000 then
    atomic_store(FSpinCount, 16000);

  FLastAdjustTime := CurrentTime;

  // 重置计数器，开始新的统计周�?
  atomic_store(FSuccessCount, 0);
  atomic_store(FContentionCount, 0);
end;

function TRWLock.CalculateOptimalSpinCount: Integer;
var
  ContentionRate: Double;
  TotalOperations: Integer;
begin
  TotalOperations := atomic_load(FSuccessCount) + atomic_load(FContentionCount);

  if TotalOperations = 0 then
  begin
    Result := FOptions.SpinCount;  // 返回默认�?
    Exit;
  end;

  ContentionRate := atomic_load(FContentionCount) / TotalOperations;

  // 基于竞争率调整自旋次�?
  if ContentionRate < 0.1 then
    // 低竞争：增加自旋次数，减少系统调�?
    Result := Round(FOptions.SpinCount * 1.5)
  else if ContentionRate < 0.3 then
    // 中等竞争：使用默认�?
    Result := FOptions.SpinCount
  else if ContentionRate < 0.6 then
    // 高竞争：减少自旋次数
    Result := Round(FOptions.SpinCount * 0.7)
  else
    // 极高竞争：大幅减少自旋次�?
    Result := Round(FOptions.SpinCount * 0.4);

  // 确保最小�?
  if Result < 50 then
    Result := 50;
end;

function TRWLock.TryAcquireReadLockWithSpin: Boolean;
var
  SpinCount: Integer;
  MaxSpin: Integer;
  i: Integer;
  Success: Boolean;
begin
  // 读偏向优化：读锁通常能快速获取，减少自旋次数
  if FOptions.ReaderBiasEnabled then
    MaxSpin := atomic_load(FSpinCount) div 4  // 读偏向：只自旋 1/4 次数
  else
    MaxSpin := atomic_load(FSpinCount);

  SpinCount := 0;

  // 第一阶段：自适应自旋
  for i := 1 to MaxSpin do
  begin
    if pthread_rwlock_tryrdlock(@FRWLock) = 0 then
    begin
      UpdateSpinStatistics(True, SpinCount);
      Result := True;
      Exit;
    end;

    Inc(SpinCount);

    // CPU 暂停指令，减少功耗和总线竞争
    {$IFDEF CPUX86_64}
    asm pause; end;
    {$ENDIF}
  end;

  // 第二阶段：阻塞等待
  Success := pthread_rwlock_rdlock(@FRWLock) = 0;
  UpdateSpinStatistics(Success, SpinCount);
  Result := Success;
end;

function TRWLock.TryAcquireWriteLockWithSpin: Boolean;
var
  SpinCount: Integer;
  i: Integer;
  Success: Boolean;
begin
  SpinCount := 0;

  // 第一阶段：自适应自旋
  for i := 1 to atomic_load(FSpinCount) do
  begin
    if pthread_rwlock_trywrlock(@FRWLock) = 0 then
    begin
      UpdateSpinStatistics(True, SpinCount);
      Result := True;
      Exit;
    end;

    Inc(SpinCount);

    // CPU 暂停指令，减少功耗和总线竞争
    {$IFDEF CPUX86_64}
    asm pause; end;
    {$ENDIF}
  end;

  // 第二阶段：阻塞等�?
  Success := pthread_rwlock_wrlock(@FRWLock) = 0;
  UpdateSpinStatistics(Success, SpinCount);
  Result := Success;
end;

// ===== 性能监控接口实现 =====

function TRWLock.GetPerformanceStats: TLockPerformanceStats;
begin
  Result := FPerfStats;
end;

procedure TRWLock.ResetPerformanceStats;
begin
  FillChar(FPerfStats, SizeOf(FPerfStats), 0);
  FPerfStats.StartTime := GetTickCount64;
  FPerfStats.LastResetTime := FPerfStats.StartTime;
  FPerfStats.MinWaitTime := High(Int64);
end;

function TRWLock.GetContentionRate: Double;
begin
  if FPerfStats.TotalAcquireAttempts > 0 then
    Result := FPerfStats.ContentionEvents / FPerfStats.TotalAcquireAttempts
  else
    Result := 0.0;
end;

function TRWLock.GetAverageWaitTime: Double;
begin
  if FPerfStats.SuccessfulAcquires > 0 then
    Result := FPerfStats.TotalWaitTime / FPerfStats.SuccessfulAcquires
  else
    Result := 0.0;
end;

function TRWLock.GetThroughput: Double;
var
  ElapsedTime: QWord;
begin
  ElapsedTime := GetTickCount64 - FPerfStats.StartTime;
  if ElapsedTime > 0 then
    Result := (FPerfStats.SuccessfulAcquires * 1000.0) / ElapsedTime
  else
    Result := 0.0;
end;

function TRWLock.GetSpinEfficiency: Double;
begin
  if FPerfStats.TotalSpinCount > 0 then
    Result := FPerfStats.SpinSuccesses / FPerfStats.TotalSpinCount
  else
    Result := 0.0;
end;

procedure TRWLock.UpdatePerformanceStats(IsRead: Boolean; IsAcquire: Boolean; WaitTime: QWord; SpinCount: Integer);
begin
  if IsAcquire then
  begin
    atomic_increment_64(FPerfStats.TotalAcquireAttempts);
    if IsRead then
      atomic_increment_64(FPerfStats.ReadAcquireAttempts)
    else
      atomic_increment_64(FPerfStats.WriteAcquireAttempts);

    atomic_increment_64(FPerfStats.SuccessfulAcquires);
    if IsRead then
      atomic_increment_64(FPerfStats.ReadSuccesses)
    else
      atomic_increment_64(FPerfStats.WriteSuccesses);

    // 更新等待时间统计
    atomic_fetch_add_64(FPerfStats.TotalWaitTime, Int64(WaitTime));

    // 更新最大等待时间
    if WaitTime > QWord(atomic_load_64(FPerfStats.MaxWaitTime)) then
      atomic_store_64(FPerfStats.MaxWaitTime, Int64(WaitTime));

    // 更新最小等待时间
    if (WaitTime < QWord(atomic_load_64(FPerfStats.MinWaitTime))) and (WaitTime > 0) then
      atomic_store_64(FPerfStats.MinWaitTime, Int64(WaitTime));

    // 更新自旋统计
    if SpinCount > 0 then
    begin
      atomic_fetch_add_64(FPerfStats.TotalSpinCount, SpinCount);
      atomic_increment_64(FPerfStats.SpinSuccesses);
    end;
  end
  else
  begin
    // 释放操作
    atomic_increment_64(FPerfStats.TotalReleases);
  end;
end;

// ===== 毒化支持 (Rust-style Poisoning) =====

function TRWLock.IsPoisoned: Boolean;
begin
  Result := FPoisoned;
end;

procedure TRWLock.ClearPoison;
begin
  FPoisoned := False;
  FPoisoningThreadId := 0;
  FPoisoningException := '';
end;

procedure TRWLock.MarkPoisoned(const AExceptionMessage: string);
begin
  if not FPoisoned then
  begin
    FPoisoned := True;
    FPoisoningThreadId := GetCurrentThreadId;
    FPoisoningException := AExceptionMessage;
  end;
end;

end.
