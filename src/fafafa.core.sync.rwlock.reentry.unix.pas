unit fafafa.core.sync.rwlock.reentry.unix;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, UnixType, pthreads,
  fafafa.core.sync.rwlock.base;

type
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
    FLock: pthread_mutex_t;  // 保护链表的互斥锁

    // 性能统计（仅用于诊断，命中率估算）
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
  if pthread_mutex_init(@FLock, nil) <> 0 then
    raise ELockError.Create('Failed to initialize reentry manager mutex');
end;

Destructor TThreadReentryManager.Destroy;
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

// 优化版 FindRecord 方法：首先检查 TLS 缓存
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

end.
