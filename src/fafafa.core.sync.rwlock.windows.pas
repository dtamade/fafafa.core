unit fafafa.core.sync.rwlock.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Windows, SysUtils,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.rwlock.base, fafafa.core.atomic;


{$IFDEF FAFAFA_CORE_USE_SRWLOCK}
 type
  PSRWLOCK = ^SRWLOCK;
  SRWLOCK = record
    Ptr: Pointer;
  end;

 // SRWLOCK API declarations (pointer form to match usage in this unit)
 procedure InitializeSRWLock(SRWLock: PSRWLOCK); stdcall; external 'kernel32.dll' name 'InitializeSRWLock';
 procedure AcquireSRWLockExclusive(SRWLock: PSRWLOCK); stdcall; external 'kernel32.dll' name 'AcquireSRWLockExclusive';
 procedure ReleaseSRWLockExclusive(SRWLock: PSRWLOCK); stdcall; external 'kernel32.dll' name 'ReleaseSRWLockExclusive';
 function TryAcquireSRWLockExclusive(SRWLock: PSRWLOCK): LongBool; stdcall; external 'kernel32.dll' name 'TryAcquireSRWLockExclusive';
 procedure AcquireSRWLockShared(SRWLock: PSRWLOCK); stdcall; external 'kernel32.dll' name 'AcquireSRWLockShared';
 procedure ReleaseSRWLockShared(SRWLock: PSRWLOCK); stdcall; external 'kernel32.dll' name 'ReleaseSRWLockShared';
 function TryAcquireSRWLockShared(SRWLock: PSRWLOCK): LongBool; stdcall; external 'kernel32.dll' name 'TryAcquireSRWLockShared';
{$ENDIF}

type
  // ===== 可重入性支持 =====

  { 线程重入记录 }
  PThreadReentryRecord = ^TThreadReentryRecord;
  TThreadReentryRecord = record
    ThreadId: TThreadID;
    ReadCount: Integer;     // 该线程的读锁重入次数
    WriteCount: Integer;    // 该线程的写锁重入次数 (0 或 1)
    Next: PThreadReentryRecord;  // 链表指针
  end;

  { 线程重入管理器 - 优化版本使用 TLS 缓存 }
  TThreadReentryManager = class
  private
    FHead: PThreadReentryRecord;
    FCriticalSection: TRTLCriticalSection;  // 保护链表的临界区

    // 性能统计
    FCacheHits: Integer;     // TLS 缓存命中次数
    FCacheMisses: Integer;   // TLS 缓存未命中次数

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
    constructor CreateAlreadyLocked(ALock: TRWLock);  // 内部使用，锁已获取
    destructor Destroy; override;

    // IRWLockReadGuard 接口
    function IsValid: Boolean;
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
    constructor CreateAlreadyLocked(ALock: TRWLock);  // 内部使用，锁已获取
    destructor Destroy; override;

    // IRWLockWriteGuard 接口
    function IsValid: Boolean;
    procedure Release;
  end;

  // ===== RWLock 主实现 =====
  TRWLock = class(TInterfacedObject, IRWLock)
  private
    // 第一个缓存行：核心锁数据（热路径）
    FSRWLock: SRWLOCK;
    FReaderCount: TAtomicCounter; // 版本化原子计数器，防止 ABA 问题
    FWriterThread: TThreadID;     // 写者线程ID
    FLastLockResult: TLockResult; // 最后操作结果

    // 缓存行对齐填充（确保下一组数据在新缓存行）
    FPadding1: array[0..63 - (SizeOf(SRWLOCK) + SizeOf(TAtomicCounter) +
                              SizeOf(TThreadID) + SizeOf(TLockResult)) mod 64] of Byte;

    // 第二个缓存行：性能统计数据（较少访问）
    FContentionCount: Integer;    // 竞争计数
    FSpinCount: Integer;          // 自适应自旋次数

    // 第三个缓存行：管理对象（最少访问）
    FReentryManager: TThreadReentryManager;  // 线程重入管理器

    // 配置选项
    FOptions: TRWLockOptions;     // 锁配置选项

    // 错误处理辅助方法
    procedure HandleSystemError(const AOperation: string);
    procedure HandleTimeout(ATimeoutMs: Cardinal);
    procedure HandleStateError(const AExpectedState, AActualState: string);
    // 可重入性检查辅助方法
    function CheckReentrancy(AThreadId: TThreadID; out ARecord: PThreadReentryRecord): Boolean;
    procedure UpdateReentryRecord(ARecord: PThreadReentryRecord; AIsRead: Boolean; AIncrement: Boolean);
  public
    constructor Create; overload;
    constructor Create(const Options: TRWLockOptions); overload;
    destructor Destroy; override;

    // ===== ISynchronizable 接口 =====
    function GetLastError: TWaitError;

    // ===== 现代化 API =====
    function Read: IRWLockReadGuard;
    function Write: IRWLockWriteGuard;
    function TryRead(ATimeoutMs: Cardinal = 0): IRWLockReadGuard;
    function TryWrite(ATimeoutMs: Cardinal = 0): IRWLockWriteGuard;

    // ===== 传统 API（继承自 IReadWriteLock）=====
    procedure AcquireRead;
    procedure ReleaseRead;
    procedure AcquireWrite;
    procedure ReleaseWrite;
    function TryAcquireRead: Boolean; overload;
    function TryAcquireRead(ATimeoutMs: Cardinal): Boolean; overload;
    function TryAcquireWrite: Boolean; overload;
    function TryAcquireWrite(ATimeoutMs: Cardinal): Boolean; overload;

    // ===== 扩展 API（统一返回 TLockResult）=====
    function TryAcquireReadEx(ATimeoutMs: Cardinal): TLockResult;
    function TryAcquireWriteEx(ATimeoutMs: Cardinal): TLockResult;

    // ===== 状态查询 =====
    function GetReaderCount: Integer;
    function IsWriteLocked: Boolean;

{$IFNDEF FAFAFA_CORE_USE_SRWLOCK}
// 当未启用 SRWLOCK 支持时，提供一个最小的占位实现，避免编译错误。
// 注意：此实现仅用于占位，不能提供真正的 RWLock 语义。
// 在 Windows 上建议启用 FAFAFA_CORE_USE_SRWLOCK（settings.inc 已默认开启）。

  type
    TRWLock = class(TInterfacedObject, IRWLock)
    private
      FLast: TLockResult;
    public
      constructor Create; overload;
      constructor Create(const Options: TRWLockOptions); overload;
      destructor Destroy; override;

      function GetLastError: TWaitError;

      function Read: IRWLockReadGuard; inline;
      function Write: IRWLockWriteGuard; inline;
      function TryRead(ATimeoutMs: Cardinal = 0): IRWLockReadGuard; inline;
      function TryWrite(ATimeoutMs: Cardinal = 0): IRWLockWriteGuard; inline;

      procedure AcquireRead; inline;
      procedure ReleaseRead; inline;
      procedure AcquireWrite; inline;
      procedure ReleaseWrite; inline;
      function TryAcquireRead: Boolean; inline;
      function TryAcquireRead(ATimeoutMs: Cardinal): Boolean; inline;
      function TryAcquireWrite: Boolean; inline;
      function TryAcquireWrite(ATimeoutMs: Cardinal): Boolean; inline;

      function TryAcquireReadEx(ATimeoutMs: Cardinal): TLockResult; inline;
      function TryAcquireWriteEx(ATimeoutMs: Cardinal): TLockResult; inline;

      function GetReaderCount: Integer; inline;
      function IsWriteLocked: Boolean; inline;
      function IsReadLocked: Boolean; inline;
      function GetWriterThread: TThreadID; inline;
      function GetMaxReaders: Integer; inline;

      function GetContentionCount: Integer; inline;
      function GetSpinCount: Integer; inline;

      function GetLastLockResult: TLockResult; inline;

      function ValidateState: Boolean; inline;
      procedure RecoverState; inline;
      function IsHealthy: Boolean; inline;

      function GetPerformanceStats: TLockPerformanceStats; inline;
      procedure ResetPerformanceStats; inline;
      function GetContentionRate: Double; inline;
      function GetAverageWaitTime: Double; inline;
      function GetThroughput: Double; inline;
      function GetSpinEfficiency: Double; inline;
    end;
{$ENDIF}

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

    // 性能监控（满足 IRWLock 接口要求，当前返回最小占位）
    function GetPerformanceStats: TLockPerformanceStats;
    procedure ResetPerformanceStats;
    function GetContentionRate: Double;
    function GetAverageWaitTime: Double;
    function GetThroughput: Double;
    function GetSpinEfficiency: Double;
  end;

implementation

// ===== 线程本地存储缓存 =====
threadvar
  // TLS 缓存：每个线程缓存自己的重入记录指针
  ThreadReentryCache: PThreadReentryRecord;

{ TThreadReentryManager }

constructor TThreadReentryManager.Create;
begin
  inherited Create;
  FHead := nil;
  FCacheHits := 0;
  FCacheMisses := 0;
  InitializeCriticalSection(FCriticalSection);
end;

destructor TThreadReentryManager.Destroy;
var
  Current, Next: PThreadReentryRecord;
begin
  // 清理所有记录
  Current := FHead;
  while Current <> nil do
  begin
    Next := Current^.Next;
    Dispose(Current);
    Current := Next;
  end;

  DeleteCriticalSection(FCriticalSection);
  inherited Destroy;
end;

procedure TThreadReentryManager.Lock;
begin
  EnterCriticalSection(FCriticalSection);
end;

procedure TThreadReentryManager.Unlock;
begin
  LeaveCriticalSection(FCriticalSection);
end;

// 优化的 FindRecord 方法：首先检查 TLS 缓存
function TThreadReentryManager.FindRecord(AThreadId: TThreadID): PThreadReentryRecord;
begin
  // 第一步：检查 TLS 缓存
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
    // 创建新记录
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

constructor TRWLockReadGuard.CreateAlreadyLocked(ALock: TRWLock);
begin
  inherited Create;
  FLock := ALock;
  FReleased := False;
  FValid := Assigned(ALock);
  // 注意：不调用 AcquireRead，因为锁已经被获取
end;

destructor TRWLockReadGuard.Destroy;
begin
  Release;
  inherited Destroy;
end;

function TRWLockReadGuard.IsValid: Boolean;
begin
  Result := FValid and not FReleased;
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

constructor TRWLockWriteGuard.CreateAlreadyLocked(ALock: TRWLock);
begin
  inherited Create;
  FLock := ALock;
  FReleased := False;
  FValid := Assigned(ALock);
  // 注意：不调用 AcquireWrite，因为锁已经被获取
end;

destructor TRWLockWriteGuard.Destroy;
begin
  Release;
  inherited Destroy;
end;

function TRWLockWriteGuard.IsValid: Boolean;
begin
  Result := FValid and not FReleased;
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

{ TRWLock }

// 可重入性检查辅助方法
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

  Create(Options);
end;

constructor TRWLock.Create(const Options: TRWLockOptions);
begin
  inherited Create;

  // 保存配置选项
  FOptions := Options;

  InitializeSRWLock(@FSRWLock);
  AtomicStoreCounter(FReaderCount, 0);
  FWriterThread := 0;
  FContentionCount := 0;
  FSpinCount := FOptions.SpinCount;  // 使用配置的自旋次数
  FLastLockResult := lrSuccess;

  // 根据配置初始化重入管理器
  if FOptions.AllowReentrancy then
    FReentryManager := TThreadReentryManager.Create
  else
    FReentryManager := nil;
end;

destructor TRWLock.Destroy;
begin
  // 清理重入管理器（如果存在）
  if Assigned(FReentryManager) then
    FReentryManager.Free;

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

// ===== 现代化 API =====

function TRWLock.Read: IRWLockReadGuard;
begin
  Result := TRWLockReadGuard.Create(Self);
end;

function TRWLock.Write: IRWLockWriteGuard;
begin
  Result := TRWLockWriteGuard.Create(Self);
end;

function TRWLock.TryRead(ATimeoutMs: Cardinal): IRWLockReadGuard;
begin
  Result := nil;
  if TryAcquireReadEx(ATimeoutMs) = lrSuccess then
  begin
    // 使用安全的构造函数创建已获取锁的守卫
    Result := TRWLockReadGuard.CreateAlreadyLocked(Self);
  end;
end;

function TRWLock.TryWrite(ATimeoutMs: Cardinal): IRWLockWriteGuard;
begin
  Result := nil;
  if TryAcquireWriteEx(ATimeoutMs) = lrSuccess then
  begin
    // 使用安全的构造函数创建已获取锁的守卫
    Result := TRWLockWriteGuard.CreateAlreadyLocked(Self);
  end;
end;

// ===== 传统 API =====

procedure TRWLock.AcquireRead;
var
  CurrentThreadId: TThreadID;
  ReentryRecord: PThreadReentryRecord;
  NeedSystemLock: Boolean;
begin
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

  // 第二阶段：获取系统锁（在管理器锁外部）
  AcquireSRWLockShared(@FSRWLock);

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
end;

procedure TRWLock.ReleaseRead;
var
  CurrentThreadId: TThreadID;
  ReentryRecord: PThreadReentryRecord;
  ShouldUnlock: Boolean;
begin
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

    // 如果该线程的读锁计数为0且没有写锁，则需要真正释放系统锁
    if (ReentryRecord^.ReadCount = 0) and (ReentryRecord^.WriteCount = 0) then
    begin
      ShouldUnlock := True;
      // 清理该线程的记录
      FReentryManager.RemoveRecord(CurrentThreadId);
    end;

  finally
    FReentryManager.Unlock;
  end;

  // 在锁外部调用系统 API，避免死锁
  if ShouldUnlock then
    ReleaseSRWLockShared(@FSRWLock);
end;

procedure TRWLock.AcquireWrite;
var
  CurrentThreadId: TThreadID;
  ReentryRecord: PThreadReentryRecord;
  NeedSystemLock: Boolean;
begin
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
        // 该线程已经持有写锁，可重入
        Inc(ReentryRecord^.WriteCount);
        NeedSystemLock := False;
      end
      else if ReentryRecord^.ReadCount > 0 then
      begin
        // 该线程持有读锁，不能升级为写锁（避免死锁）
        raise ERWLockDeadlockError.Create(CurrentThreadId, [CurrentThreadId]);
      end;
    end;
  finally
    FReentryManager.Unlock;
  end;

  // 如果不需要系统锁，直接返回
  if not NeedSystemLock then
    Exit;

  // 第二阶段：获取系统锁（在管理器锁外部）
  AcquireSRWLockExclusive(@FSRWLock);

  // 第三阶段：更新重入记录
  FReentryManager.Lock;
  try
    // 重新查找记录（可能在等待期间被其他操作修改）
    ReentryRecord := FReentryManager.FindRecord(CurrentThreadId);
    if ReentryRecord = nil then
      ReentryRecord := FReentryManager.GetOrCreateRecord(CurrentThreadId);

    Inc(ReentryRecord^.WriteCount);
    FWriterThread := CurrentThreadId;
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

    // 如果该线程的写锁计数为0且没有读锁，则需要真正释放系统锁
    if (ReentryRecord^.WriteCount = 0) and (ReentryRecord^.ReadCount = 0) then
    begin
      ShouldUnlock := True;
      FWriterThread := 0;
      // 清理该线程的记录
      FReentryManager.RemoveRecord(CurrentThreadId);
    end;

  finally
    FReentryManager.Unlock;
  end;

  // 在锁外部调用系统 API，避免死锁
  if ShouldUnlock then
    ReleaseSRWLockExclusive(@FSRWLock);
end;

function TRWLock.TryAcquireRead: Boolean;
begin
  Result := TryAcquireSRWLockShared(@FSRWLock);
  if Result then
    AtomicIncrementCounter(FReaderCount);
end;

function TRWLock.TryAcquireRead(ATimeoutMs: Cardinal): Boolean;
begin
  Result := TryAcquireReadEx(ATimeoutMs) = lrSuccess;
end;

function TRWLock.TryAcquireReadEx(ATimeoutMs: Cardinal): TLockResult;
var
  StartTime: DWORD;
  ElapsedMs: DWORD;
  SpinCount: Integer;
  i: Integer;
begin
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

  StartTime := GetTickCount;
  SpinCount := FSpinCount;

  repeat
    // 自适应自旋阶段
    for i := 1 to SpinCount do
    begin
      if TryAcquireSRWLockShared(@FSRWLock) then
      begin
        AtomicIncrementCounter(FReaderCount);
        // 成功获取锁，减少竞争计数
        InterlockedDecrement(FContentionCount);
        Result := lrSuccess;
        FLastLockResult := lrSuccess;
        Exit;
      end;

      // CPU 暂停指令，减少功耗
      {$IFDEF CPUX86_64}
      asm pause; end;
      {$ENDIF}
    end;

    // 增加竞争计数
    InterlockedIncrement(FContentionCount);

    // 检查超时
    ElapsedMs := GetTickCount - StartTime;
    if ElapsedMs >= ATimeoutMs then
    begin
      Result := lrTimeout;
      FLastLockResult := lrTimeout;
      Exit;
    end;

    // 自适应调整自旋次数
    if FContentionCount > 100 then
    begin
      if FSpinCount div 2 > 100 then
        FSpinCount := FSpinCount div 2
      else
        FSpinCount := 100;
    end
    else if FContentionCount < 10 then
    begin
      if FSpinCount * 2 < 8000 then
        FSpinCount := FSpinCount * 2
      else
        FSpinCount := 8000;
    end;

    // 短暂休眠避免忙等待
    Sleep(1);
  until False;
end;

function TRWLock.TryAcquireWrite: Boolean;
begin
  Result := TryAcquireSRWLockExclusive(@FSRWLock);
  if Result then
    FWriterThread := GetCurrentThreadId;
end;

function TRWLock.TryAcquireWrite(ATimeoutMs: Cardinal): Boolean;
begin
  Result := TryAcquireWriteEx(ATimeoutMs) = lrSuccess;
end;

function TRWLock.TryAcquireWriteEx(ATimeoutMs: Cardinal): TLockResult;
var
  StartTime: DWORD;
  ElapsedMs: DWORD;
  SpinCount: Integer;
  i: Integer;
begin
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

  StartTime := GetTickCount;
  SpinCount := FSpinCount;

  repeat
    // 自适应自旋阶段
    for i := 1 to SpinCount do
    begin
      if TryAcquireSRWLockExclusive(@FSRWLock) then
      begin
        FWriterThread := GetCurrentThreadId;
        // 成功获取锁，减少竞争计数
        InterlockedDecrement(FContentionCount);
        Result := lrSuccess;
        Exit;
      end;

      // CPU 暂停指令，减少功耗
      {$IFDEF CPUX86_64}
      asm pause; end;
      {$ENDIF}
    end;

    // 增加竞争计数
    InterlockedIncrement(FContentionCount);

    // 检查超时
    ElapsedMs := GetTickCount - StartTime;
    if ElapsedMs >= ATimeoutMs then
    begin
      Result := lrTimeout;
      Exit;
    end;

    // 短暂休眠避免忙等待
    Sleep(1);
  until False;
end;

// ===== 状态查询 =====

function TRWLock.GetReaderCount: Integer;
begin
  Result := AtomicLoadCounter(FReaderCount);  // 原子读取，防止 ABA 问题
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
  // Windows SRWLOCK 理论上支持的最大读者数量
  Result := High(Integer);
end;

// ===== 性能统计 =====

function TRWLock.GetContentionCount: Integer;
begin
  Result := FContentionCount;
end;

function TRWLock.GetSpinCount: Integer;
begin
  Result := FSpinCount;
end;

// ===== 错误信息 =====

function TRWLock.GetLastLockResult: TLockResult;
begin
  Result := FLastLockResult;
end;

// ===== 错误处理辅助方法 =====

procedure TRWLock.HandleSystemError(const AOperation: string);
var
  ErrorCode: DWORD;
  ErrorMsg: string;
begin
  ErrorCode := Windows.GetLastError;
  case ErrorCode of
    ERROR_TIMEOUT:
      begin
        FLastLockResult := lrTimeout;
        ErrorMsg := 'Operation timed out';
      end;
    ERROR_INVALID_HANDLE:
      begin
        FLastLockResult := lrError;
        ErrorMsg := 'Invalid lock handle';
      end;
    ERROR_ACCESS_DENIED:
      begin
        FLastLockResult := lrError;
        ErrorMsg := 'Access denied';
      end;
    ERROR_INVALID_PARAMETER:
      begin
        FLastLockResult := lrError;
        ErrorMsg := 'Invalid parameter';
      end;
  else
    FLastLockResult := lrError;
    ErrorMsg := 'System error ' + IntToStr(ErrorCode);
  end;

  raise ERWLockSystemError.Create(Integer(ErrorCode), ErrorMsg, TThreadID(GetCurrentThreadId));
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

  // 读取当前状态
  CurrentReaderCount := AtomicLoadCounter(FReaderCount);
  CurrentWriterThread := FWriterThread;

  // 验证读者计数不能为负数
  if CurrentReaderCount < 0 then
  begin
    Result := False;
    Exit;
  end;

  // 验证写锁状态一致性
  if IsWriteLocked then
  begin
    // 如果有写锁，读者计数应该为0
    if CurrentReaderCount > 0 then
    begin
      Result := False;
      Exit;
    end;

{$IFNDEF FAFAFA_CORE_USE_SRWLOCK}
{ Minimal stub implementations }
constructor TRWLock.Create;
begin
  inherited Create;
  FLast := lrSuccess;
end;

constructor TRWLock.Create(const Options: TRWLockOptions);
begin
  Create;
end;

destructor TRWLock.Destroy;
begin
  inherited Destroy;
end;

function TRWLock.GetLastError: TWaitError;
begin
  Result := weNone;
end;

function TRWLock.Read: IRWLockReadGuard;
begin
  Result := nil;
end;

function TRWLock.Write: IRWLockWriteGuard;
begin
  Result := nil;
end;

function TRWLock.TryRead(ATimeoutMs: Cardinal): IRWLockReadGuard;
begin
  Result := nil;
end;

function TRWLock.TryWrite(ATimeoutMs: Cardinal): IRWLockWriteGuard;
begin
  Result := nil;
end;

procedure TRWLock.AcquireRead;
begin
end;

procedure TRWLock.ReleaseRead;
begin
end;

procedure TRWLock.AcquireWrite;
begin
end;

procedure TRWLock.ReleaseWrite;
begin
end;

function TRWLock.TryAcquireRead: Boolean;
begin
  Result := False;
end;

function TRWLock.TryAcquireRead(ATimeoutMs: Cardinal): Boolean;
begin
  Result := False;
end;

function TRWLock.TryAcquireWrite: Boolean;
begin
  Result := False;
end;

function TRWLock.TryAcquireWrite(ATimeoutMs: Cardinal): Boolean;
begin
  Result := False;
end;

function TRWLock.TryAcquireReadEx(ATimeoutMs: Cardinal): TLockResult;
begin
  Result := lrWouldBlock;
end;

function TRWLock.TryAcquireWriteEx(ATimeoutMs: Cardinal): TLockResult;
begin
  Result := lrWouldBlock;
end;

function TRWLock.GetReaderCount: Integer;
begin
  Result := 0;
end;

function TRWLock.IsWriteLocked: Boolean;
begin
  Result := False;
end;

function TRWLock.IsReadLocked: Boolean;
begin
  Result := False;
end;

function TRWLock.GetWriterThread: TThreadID;
begin
  Result := 0;
end;

function TRWLock.GetMaxReaders: Integer;
begin
  Result := 0;
end;

function TRWLock.GetContentionCount: Integer;
begin
  Result := 0;
end;

function TRWLock.GetSpinCount: Integer;
begin
  Result := 0;
end;

function TRWLock.GetLastLockResult: TLockResult;
begin
  Result := FLast;
end;

function TRWLock.ValidateState: Boolean;
begin
  Result := True;
end;

procedure TRWLock.RecoverState;
begin
end;

function TRWLock.IsHealthy: Boolean;
begin
  Result := ValidateState and (FLastLockResult <> lrError);
end;

function TRWLock.GetPerformanceStats: TLockPerformanceStats;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

procedure TRWLock.ResetPerformanceStats;
begin
end;

function TRWLock.GetContentionRate: Double;
begin
  Result := 0.0;
end;

function TRWLock.GetAverageWaitTime: Double;
begin
  Result := 0.0;
end;

function TRWLock.GetThroughput: Double;
begin
  Result := 0.0;
end;

function TRWLock.GetSpinEfficiency: Double;
begin
  Result := 1.0;
end;
{$ENDIF}

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
    // 如果没有写锁，写者线程ID应该为0
    if CurrentWriterThread <> 0 then
    begin
      Result := False;
      Exit;
    end;
  end;

  // 验证读锁状态一致性
  if IsReadLocked then
  begin
    // 如果有读锁，读者计数应该大于0
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
  // 尝试恢复锁状态
  try
    // 重置读者计数
    if AtomicLoadCounter(FReaderCount) < 0 then
      AtomicStoreCounter(FReaderCount, 0);

    // 检查写锁状态
    if not IsWriteLocked and (FWriterThread <> 0) then
      FWriterThread := 0;

    // 重置错误状态
    FLastLockResult := lrSuccess;

    // 重置竞争统计（可选）
    if FContentionCount < 0 then
      FContentionCount := 0;

  except
    on E: Exception do
    begin
      // 恢复失败，记录错误
      FLastLockResult := lrError;
      raise ERWLockSystemError.Create(0, 'State recovery failed: ' + E.Message, GetCurrentThreadId);
    end;
  end;
end;

function TRWLock.IsHealthy: Boolean;
begin
  Result := ValidateState and (FLastLockResult <> lrError);
end;


{$IFDEF FAFAFA_CORE_USE_SRWLOCK}
function TRWLock.GetPerformanceStats: TLockPerformanceStats;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.ContentionEvents := FContentionCount;
  Result.TotalSpinCount := FSpinCount;
end;

procedure TRWLock.ResetPerformanceStats;
begin
  FContentionCount := 0;
  // 不重置自旋配置
end;

function TRWLock.GetContentionRate: Double;
begin
  Result := FContentionCount;
end;

function TRWLock.GetAverageWaitTime: Double;
begin
  Result := 0.0;
end;

function TRWLock.GetThroughput: Double;
begin
  Result := 0.0;
end;

function TRWLock.GetSpinEfficiency: Double;
begin
  Result := 1.0;
end;
{$ENDIF}

end.
