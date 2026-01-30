unit fafafa.core.sync.rwlock.windows;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  Windows, SysUtils,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.rwlock.base,
  fafafa.core.atomic;

type
  // Windows SRWLOCK (pointer form)
  PSRWLOCK = ^SRWLOCK;
  SRWLOCK = record
    Ptr: Pointer;
  end;

procedure InitializeSRWLock(SRWLock: PSRWLOCK); stdcall; external 'kernel32.dll' name 'InitializeSRWLock';
procedure AcquireSRWLockExclusive(SRWLock: PSRWLOCK); stdcall; external 'kernel32.dll' name 'AcquireSRWLockExclusive';
procedure ReleaseSRWLockExclusive(SRWLock: PSRWLOCK); stdcall; external 'kernel32.dll' name 'ReleaseSRWLockExclusive';
function TryAcquireSRWLockExclusive(SRWLock: PSRWLOCK): LongBool; stdcall; external 'kernel32.dll' name 'TryAcquireSRWLockExclusive';
procedure AcquireSRWLockShared(SRWLock: PSRWLOCK); stdcall; external 'kernel32.dll' name 'AcquireSRWLockShared';
procedure ReleaseSRWLockShared(SRWLock: PSRWLOCK); stdcall; external 'kernel32.dll' name 'ReleaseSRWLockShared';
function TryAcquireSRWLockShared(SRWLock: PSRWLOCK): LongBool; stdcall; external 'kernel32.dll' name 'TryAcquireSRWLockShared';

type
  PThreadRec = ^TThreadRec;
  TThreadRec = record
    ThreadId: TThreadID;
    ReadCount: Integer;
    WriteCount: Integer;
    Next: PThreadRec;
  end;

  TThreadRecManager = class
  private
    FHead: PThreadRec;
    FCs: TRTLCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Lock; inline;
    procedure Unlock; inline;
    function Find(AThread: TThreadID): PThreadRec;
    function GetOrCreate(AThread: TThreadID): PThreadRec;
    procedure Remove(AThread: TThreadID);
  end;

  TRWLock = class(TInterfacedObject, IRWLock, IRWLockDiagnostics)
  private
    FSRW: SRWLOCK;
    FReaders: Integer;
    FWriterThread: TThreadID;
    FRecs: TThreadRecManager;
    FLast: TLockResult;
    FContention: Integer;
    FSpin: Integer;
    FPoisoned: Boolean;
  public
    constructor Create; overload;
    constructor Create(const Options: TRWLockOptions); overload;
    destructor Destroy; override;

    // ISynchronizable
    function GetLastError: TWaitError;

    // Modern API
    function Read: IRWLockReadGuard;
    function Write: IRWLockWriteGuard;
    function TryRead(ATimeoutMs: Cardinal = 0): IRWLockReadGuard;
    function TryWrite(ATimeoutMs: Cardinal = 0): IRWLockWriteGuard;

    // Traditional API
    procedure AcquireRead;
    procedure ReleaseRead;
    procedure AcquireWrite;
    procedure ReleaseWrite;
    function TryAcquireRead: Boolean; overload;
    function TryAcquireRead(ATimeoutMs: Cardinal): Boolean; overload;
    function TryAcquireWrite: Boolean; overload;
    function TryAcquireWrite(ATimeoutMs: Cardinal): Boolean; overload;

    // Result variants
    function TryAcquireReadEx(ATimeoutMs: Cardinal): TLockResult;
    function TryAcquireWriteEx(ATimeoutMs: Cardinal): TLockResult;

    // State
    function GetReaderCount: Integer;
    function IsWriteLocked: Boolean;
    function IsReadLocked: Boolean;
    function GetWriterThread: TThreadID;
    function GetMaxReaders: Integer;

    // Stats (minimal)
    function GetContentionCount: Integer;
    function GetSpinCount: Integer;
    function GetLastLockResult: TLockResult;

    // Validation
    function ValidateState: Boolean;
    procedure RecoverState;
    function IsHealthy: Boolean;

    // Poisoning (Rust-style)
    function IsPoisoned: Boolean;
    procedure ClearPoison;

    // Perf (minimal placeholders - IRWLockDiagnostics)
    function GetPerformanceStats: TLockPerformanceStats;
    procedure ResetPerformanceStats;
    function GetContentionRate: Double;
    function GetAverageWaitTime: Double;
    function GetThroughput: Double;
    function GetSpinEfficiency: Double;
  end;

  TRWLockReadGuard = class(TInterfacedObject, IRWLockReadGuard)
  private
    FLock: TRWLock;
    FReleased: Boolean;
  public
    constructor Create(ALock: TRWLock);
    constructor CreateAcquired(ALock: TRWLock); // 宸茬粡鑾峰彇閿佺殑瀹堝崼
    destructor Destroy; override;
    procedure Release;
  end;

  TRWLockWriteGuard = class(TInterfacedObject, IRWLockWriteGuard)
  private
    FLock: TRWLock;
    FReleased: Boolean;
  public
    constructor Create(ALock: TRWLock);
    constructor CreateAcquired(ALock: TRWLock); // 宸茬粡鑾峰彇閿佺殑瀹堝崼
    destructor Destroy; override;
    procedure Release;
  end;

implementation

{ TThreadRecManager }

constructor TThreadRecManager.Create;
begin
  inherited Create;
  FHead := nil;
  InitializeCriticalSection(FCs);
end;

destructor TThreadRecManager.Destroy;
var
  C, N: PThreadRec;
begin
  C := FHead;
  while C <> nil do
  begin
    N := C^.Next;
    Dispose(C);
    C := N;
  end;
  DeleteCriticalSection(FCs);
  inherited Destroy;
end;

procedure TThreadRecManager.Lock;
begin
  EnterCriticalSection(FCs);
end;

procedure TThreadRecManager.Unlock;
begin
  LeaveCriticalSection(FCs);
end;

function TThreadRecManager.Find(AThread: TThreadID): PThreadRec;
var
  C: PThreadRec;
begin
  Result := nil;
  C := FHead;
  while C <> nil do
  begin
    if C^.ThreadId = AThread then
      Exit(C);
    C := C^.Next;
  end;
end;

function TThreadRecManager.GetOrCreate(AThread: TThreadID): PThreadRec;
begin
  Result := Find(AThread);
  if Result = nil then
  begin
    New(Result);
    Result^.ThreadId := AThread;
    Result^.ReadCount := 0;
    Result^.WriteCount := 0;
    Result^.Next := FHead;
    FHead := Result;
  end;
end;

procedure TThreadRecManager.Remove(AThread: TThreadID);
var
  C, P: PThreadRec;
begin
  P := nil;
  C := FHead;
  while C <> nil do
  begin
    if C^.ThreadId = AThread then
    begin
      if P = nil then FHead := C^.Next else P^.Next := C^.Next;
      Dispose(C);
      Exit;
    end;
    P := C;
    C := C^.Next;
  end;
end;

{ TRWLockReadGuard }

constructor TRWLockReadGuard.Create(ALock: TRWLock);
begin
  inherited Create;
  FLock := ALock;
  FReleased := False;
  if Assigned(FLock) then
    FLock.AcquireRead;
end;

constructor TRWLockReadGuard.CreateAcquired(ALock: TRWLock);
begin
  inherited Create;
  FLock := ALock;
  FReleased := False;
  // 涓嶈幏鍙栭攣锛氬閮ㄥ凡鑾峰彇
end;

destructor TRWLockReadGuard.Destroy;
begin
  Release;
  inherited Destroy;
end;

procedure TRWLockReadGuard.Release;
begin
  if (not FReleased) and Assigned(FLock) then
  begin
    FReleased := True;
    FLock.ReleaseRead;
  end;
end;

{ TRWLockWriteGuard }

constructor TRWLockWriteGuard.Create(ALock: TRWLock);
begin
  inherited Create;
  FLock := ALock;
  FReleased := False;
  if Assigned(FLock) then
    FLock.AcquireWrite;
end;

constructor TRWLockWriteGuard.CreateAcquired(ALock: TRWLock);
begin
  inherited Create;
  FLock := ALock;
  FReleased := False;
  // 涓嶈幏鍙栭攣锛氬閮ㄥ凡鑾峰彇
end;

destructor TRWLockWriteGuard.Destroy;
begin
  Release;
  inherited Destroy;
end;

procedure TRWLockWriteGuard.Release;
begin
  if (not FReleased) and Assigned(FLock) then
  begin
    // Only release when current thread owns the write lock; prevents invalid state
        if FLock.IsWriteLocked and (FLock.GetWriterThread = GetCurrentThreadId) then
    begin
      FReleased := True;
      FLock.ReleaseWrite;
    end
    else
      FReleased := True;
  end;
end;

{ TRWLock }

constructor TRWLock.Create;
begin
  inherited Create;
  InitializeSRWLock(@FSRW);
  FReaders := 0;
  FWriterThread := 0;
  FRecs := TThreadRecManager.Create;
  FLast := lrSuccess;
  FContention := 0;
  FSpin := 4000; // 榛樿鑷棆閰嶇疆锛堢敤浜庣粺璁℃樉绀猴級
end;

constructor TRWLock.Create(const Options: TRWLockOptions);
begin
  Create;
end;

destructor TRWLock.Destroy;
begin
  FRecs.Free;
  inherited Destroy;
end;

function TRWLock.GetLastError: TWaitError;
begin
  case FLast of
    lrSuccess: Result := weNone;
    lrTimeout: Result := weTimeout;
    lrWouldBlock: Result := weResourceExhausted;
  else
    Result := weSystemError;
  end;
end;

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
    Result := TRWLockReadGuard.CreateAcquired(Self);
end;

function TRWLock.TryWrite(ATimeoutMs: Cardinal): IRWLockWriteGuard;
begin
  Result := nil;
  if TryAcquireWriteEx(ATimeoutMs) = lrSuccess then
    Result := TRWLockWriteGuard.CreateAcquired(Self);
end;

procedure TRWLock.AcquireRead;
var
  id: TThreadID;
  rec: PThreadRec;
begin
  id := GetCurrentThreadId;
  FRecs.Lock;
  try
    rec := FRecs.Find(id);
    if rec <> nil then
    begin
      // Reentrant (writer or reader)
      Inc(rec^.ReadCount);
      atomic_increment(FReaders);
      Exit;
    end;
  finally
    FRecs.Unlock;
  end;

  // First time for this thread
  AcquireSRWLockShared(@FSRW);

  FRecs.Lock;
  try
    rec := FRecs.GetOrCreate(id);
    Inc(rec^.ReadCount);
    atomic_increment(FReaders);
  finally
    FRecs.Unlock;
  end;
  FLast := lrSuccess;
end;

procedure TRWLock.ReleaseRead;
var
  id: TThreadID;
  rec: PThreadRec;
  needReleaseShared: Boolean;
begin
  id := GetCurrentThreadId;
  needReleaseShared := False;

  FRecs.Lock;
  try
    rec := FRecs.Find(id);
    if (rec = nil) or (rec^.ReadCount <= 0) then
      raise ERWLockError.Create(Format('Read lock not held (Released), Thread: %d', [id]), lrError);

    Dec(rec^.ReadCount);
    atomic_decrement(FReaders);

    if (rec^.ReadCount = 0) and (rec^.WriteCount = 0) then
    begin
      // This thread had acquired a shared lock earlier (no write)
      needReleaseShared := True;
      FRecs.Remove(id);
    end;
  finally
    FRecs.Unlock;
  end;

  if needReleaseShared then
    ReleaseSRWLockShared(@FSRW);
end;

procedure TRWLock.AcquireWrite;
var
  id: TThreadID;
  rec: PThreadRec;
begin
  id := GetCurrentThreadId;
  FRecs.Lock;
  try
    rec := FRecs.Find(id);
    if rec <> nil then
    begin
      if rec^.WriteCount > 0 then
      begin
        Inc(rec^.WriteCount);
        FLast := lrSuccess;
        Exit;
      end
      else if rec^.ReadCount > 0 then
      begin
        // Upgrade not allowed: would deadlock
        raise ERWLockError.Create(Format('Potential deadlock detected: upgrade not allowed, Thread: %d', [id]), lrError);
      end;
    end;
  finally
    FRecs.Unlock;
  end;

  AcquireSRWLockExclusive(@FSRW);
  FWriterThread := id;
  FRecs.Lock;
  try
    rec := FRecs.GetOrCreate(id);
    Inc(rec^.WriteCount);
  finally
    FRecs.Unlock;
  end;
  FLast := lrSuccess;
end;

procedure TRWLock.ReleaseWrite;
var
  id: TThreadID;
  rec: PThreadRec;
  needReleaseExclusive: Boolean;
begin
  id := GetCurrentThreadId;
  needReleaseExclusive := False;

  FRecs.Lock;
  try
    rec := FRecs.Find(id);
    if (rec = nil) or (rec^.WriteCount <= 0) then
      raise ERWLockError.Create(Format('Write lock not held (Released), Thread: %d', [id]), lrError);

    Dec(rec^.WriteCount);
    if rec^.WriteCount = 0 then
    begin
      FWriterThread := 0;
      needReleaseExclusive := True;
      if rec^.ReadCount = 0 then
        FRecs.Remove(id);
    end;
  finally
    FRecs.Unlock;
  end;

  if needReleaseExclusive then
    ReleaseSRWLockExclusive(@FSRW);
end;

function TRWLock.TryAcquireRead: Boolean;
var
  id: TThreadID;
  rec: PThreadRec;
begin
  id := GetCurrentThreadId;
  FRecs.Lock;
  try
    rec := FRecs.Find(id);
    if rec <> nil then
    begin
      Inc(rec^.ReadCount);
      atomic_increment(FReaders);
      FLast := lrSuccess;
      Exit(True);
    end;
  finally
    FRecs.Unlock;
  end;

  Result := TryAcquireSRWLockShared(@FSRW);
  if Result then
  begin
    FRecs.Lock;
    try
      rec := FRecs.GetOrCreate(id);
      Inc(rec^.ReadCount);
      atomic_increment(FReaders);
    finally
      FRecs.Unlock;
    end;
    FLast := lrSuccess;
  end
  else
    FLast := lrWouldBlock;
end;

function TRWLock.TryAcquireRead(ATimeoutMs: Cardinal): Boolean;
begin
  Result := TryAcquireReadEx(ATimeoutMs) = lrSuccess;
end;

function TRWLock.TryAcquireWrite: Boolean;
var
  id: TThreadID;
  rec: PThreadRec;
begin
  id := GetCurrentThreadId;
  FRecs.Lock;
  try
    rec := FRecs.Find(id);
    if rec <> nil then
    begin
      if rec^.WriteCount > 0 then
      begin
        Inc(rec^.WriteCount);
        FLast := lrSuccess;
        Exit(True);
      end
      else if rec^.ReadCount > 0 then
      begin
        // upgrade not allowed -> would block immediately
        FLast := lrWouldBlock;
        Exit(False);
      end;
    end;
  finally
    FRecs.Unlock;
  end;

  Result := TryAcquireSRWLockExclusive(@FSRW);
  if Result then
  begin
    FWriterThread := id;
    FRecs.Lock;
    try
      rec := FRecs.GetOrCreate(id);
      Inc(rec^.WriteCount);
    finally
      FRecs.Unlock;
    end;
    FLast := lrSuccess;
  end
  else
    FLast := lrWouldBlock;
end;

function TRWLock.TryAcquireWrite(ATimeoutMs: Cardinal): Boolean;
begin
  Result := TryAcquireWriteEx(ATimeoutMs) = lrSuccess;
end;

function TRWLock.TryAcquireReadEx(ATimeoutMs: Cardinal): TLockResult;
var
  start, now: QWord;
begin
  if TryAcquireRead then
  begin
    FLast := lrSuccess;
    Exit(lrSuccess);
  end;

  if ATimeoutMs = 0 then
  begin
    FLast := lrWouldBlock;
    Exit(lrWouldBlock);
  end;

  start := GetTickCount64;
  repeat
    if TryAcquireRead then
    begin
      FLast := lrSuccess;
      Exit(lrSuccess);
    end;
    now := GetTickCount64;
    if (now - start) >= ATimeoutMs then
    begin
      FLast := lrTimeout;
      Exit(lrTimeout);
    end;
    Sleep(1);
  until False;
end;

function TRWLock.TryAcquireWriteEx(ATimeoutMs: Cardinal): TLockResult;
var
  start, now: QWord;
  id: TThreadID;
  rec: PThreadRec;
begin
  // immediate would-block when current thread holds a read lock (no upgrade)
  id := GetCurrentThreadId;
  FRecs.Lock;
  try
    rec := FRecs.Find(id);
    if (rec <> nil) and (rec^.WriteCount = 0) and (rec^.ReadCount > 0) then
    begin
      FLast := lrWouldBlock;
      Exit(lrWouldBlock);
    end;
  finally
    FRecs.Unlock;
  end;
  if TryAcquireWrite then
  begin
    FLast := lrSuccess;
    Exit(lrSuccess);
  end;

  if ATimeoutMs = 0 then
  begin
    FLast := lrWouldBlock;
    Exit(lrWouldBlock);
  end;

  start := GetTickCount64;
  repeat
    if TryAcquireWrite then
    begin
      FLast := lrSuccess;
      Exit(lrSuccess);
    end;
    now := GetTickCount64;
    if (now - start) >= ATimeoutMs then
    begin
      FLast := lrTimeout;
      Exit(lrTimeout);
    end;
    Sleep(1);
  until False;
end;

function TRWLock.GetReaderCount: Integer;
begin
  Result := FReaders;
end;

function TRWLock.IsWriteLocked: Boolean;
begin
  Result := FWriterThread <> 0;
end;

function TRWLock.IsReadLocked: Boolean;
begin
  Result := FReaders > 0;
end;

function TRWLock.GetWriterThread: TThreadID;
begin
  Result := FWriterThread;
end;

function TRWLock.GetMaxReaders: Integer;
begin
  Result := High(Integer);
end;

function TRWLock.GetContentionCount: Integer;
begin
  Result := FContention;
end;

function TRWLock.GetSpinCount: Integer;
begin
  Result := FSpin;
end;

function TRWLock.GetLastLockResult: TLockResult;
begin
  Result := FLast;
end;

function TRWLock.ValidateState: Boolean;
begin
  Result := (FReaders >= 0) and (not(IsWriteLocked and (FReaders > 0)));
end;

procedure TRWLock.RecoverState;
begin
  if FReaders < 0 then FReaders := 0;
  if (FReaders > 0) and (FWriterThread <> 0) then
    FReaders := 0; // prefer writer state
  FLast := lrSuccess;
end;

function TRWLock.IsHealthy: Boolean;
begin
  Result := ValidateState and (FLast <> lrError) and (not FPoisoned);
end;

function TRWLock.IsPoisoned: Boolean;
begin
  Result := FPoisoned;
end;

procedure TRWLock.ClearPoison;
begin
  FPoisoned := False;
end;

function TRWLock.GetPerformanceStats: TLockPerformanceStats;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

procedure TRWLock.ResetPerformanceStats;
begin
  // no-op
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

end.

