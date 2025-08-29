unit fafafa.core.sync.mutex.windows;

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  Windows,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex.base,
  fafafa.core.atomic;

// Windows API 类型声明
type
  TRTLCriticalSection = record
    DebugInfo: Pointer;
    LockCount: LongInt;
    RecursionCount: LongInt;
    OwningThread: THandle;
    LockSemaphore: THandle;
    SpinCount: PtrUInt;
  end;
  PRTLCriticalSection = ^TRTLCriticalSection;

{$IFDEF FAFAFA_CORE_USE_SRWLOCK}
  PSRWLOCK = ^SRWLOCK;
  SRWLOCK = record
    Ptr: Pointer;
  end;
{$ENDIF}

// Windows API 函数声明
procedure InitializeCriticalSection(var lpCriticalSection: TRTLCriticalSection); stdcall; external 'kernel32.dll';
procedure DeleteCriticalSection(var lpCriticalSection: TRTLCriticalSection); stdcall; external 'kernel32.dll';
procedure EnterCriticalSection(var lpCriticalSection: TRTLCriticalSection); stdcall; external 'kernel32.dll';
procedure LeaveCriticalSection(var lpCriticalSection: TRTLCriticalSection); stdcall; external 'kernel32.dll';
function TryEnterCriticalSection(var lpCriticalSection: TRTLCriticalSection): LongBool; stdcall; external 'kernel32.dll';

{$IFDEF FAFAFA_CORE_USE_SRWLOCK}
// SRWLOCK API 声明
procedure InitializeSRWLock(var SRWLock: SRWLOCK); stdcall; external 'kernel32.dll';
procedure AcquireSRWLockExclusive(var SRWLock: SRWLOCK); stdcall; external 'kernel32.dll';
procedure ReleaseSRWLockExclusive(var SRWLock: SRWLOCK); stdcall; external 'kernel32.dll';
function TryAcquireSRWLockExclusive(var SRWLock: SRWLOCK): LongBool; stdcall; external 'kernel32.dll';
{$ENDIF}

type
  { 传统互斥锁实现 - 使用 CRITICAL_SECTION（兼容 Windows XP+）}
  TMutex = class(TTryLock, IMutex)
  private
    FCriticalSection: TRTLCriticalSection;
    FOwnerThreadId: LongInt; // 原子变量：0=未锁定，非0=持有锁的线程ID
  public
    constructor Create;
    destructor Destroy; override;

    // ITryLock 继承的方法
    procedure Acquire; override;
    procedure Release; override;
    function TryAcquire: Boolean; override;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; override;  // 重写超时版本

    // IMutex 特有方法
    function GetHandle: Pointer;
  end;

{$IFDEF FAFAFA_CORE_USE_SRWLOCK}
  { 现代互斥锁实现 - 使用 SRWLOCK（要求 Windows Vista+）}
  TSRWMutex = class(TTryLock, IMutex)
  private
    FLock: SRWLOCK;
    FOwnerThreadId: Int32;  // 使用 Int32 以配合 fafafa.core.atomic
  public
    constructor Create;
    destructor Destroy; override;

    // ITryLock 继承的方法
    procedure Acquire; override;
    procedure Release; override;
    function TryAcquire: Boolean; override;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; override;  // 重写超时版本

    // IMutex 特有方法
    function GetHandle: Pointer;
  end;
{$ENDIF}


function MakeMutex: IMutex; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}


implementation

function MakeMutex: IMutex;
begin
  {$IFDEF FAFAFA_CORE_USE_SRWLOCK}
  Result := TSRWMutex.Create;
  {$ELSE}
  Result := TMutex.Create;
  {$ENDIF}
end;



{ TMutex - 传统 CRITICAL_SECTION 实现 }

constructor TMutex.Create;
begin
  inherited Create;
  atomic_store(FOwnerThreadId, 0); // 0 表示未锁定
  InitializeCriticalSection(FCriticalSection);
end;

destructor TMutex.Destroy;
begin
  DeleteCriticalSection(FCriticalSection);
  inherited Destroy;
end;

procedure TMutex.Acquire;
var
  CurrentThreadId: LongInt;
begin
  CurrentThreadId := LongInt(GetCurrentThreadId);

  // 先检查重入（原子读取）
  if atomic_load(FOwnerThreadId) = CurrentThreadId then
    raise ELockError.Create('Non-reentrant mutex: reentrancy detected');

  // 使用 CRITICAL_SECTION 获取锁
  EnterCriticalSection(FCriticalSection);
  try
    // 再次检查重入（防止竞态条件）
    if atomic_load(FOwnerThreadId) = CurrentThreadId then
    begin
      LeaveCriticalSection(FCriticalSection);
      raise ELockError.Create('Non-reentrant mutex: reentrancy detected');
    end;
    // 原子设置所有权
    atomic_store(FOwnerThreadId, CurrentThreadId);
  except
    LeaveCriticalSection(FCriticalSection);
    raise;
  end;
end;

procedure TMutex.Release;
var
  CurrentThreadId: LongInt;
begin
  CurrentThreadId := LongInt(GetCurrentThreadId);

  // 检查所有权（原子读取）
  if atomic_load(FOwnerThreadId) <> CurrentThreadId then
    raise ELockError.Create('Mutex not owned by current thread');

  // 原子清除所有权信息
  atomic_store(FOwnerThreadId, 0);

  // 释放 CRITICAL_SECTION
  LeaveCriticalSection(FCriticalSection);
end;

function TMutex.TryAcquire: Boolean;
var
  CurrentThreadId: LongInt;
begin
  CurrentThreadId := LongInt(GetCurrentThreadId);

  // 先检查重入（原子读取）
  if atomic_load(FOwnerThreadId) = CurrentThreadId then
    Exit(False);

  // 尝试获取 CRITICAL_SECTION
  if TryEnterCriticalSection(FCriticalSection) then
  begin
    try
      // 再次检查重入（防止竞态条件）
      if atomic_load(FOwnerThreadId) = CurrentThreadId then
      begin
        // 检测到重入，释放刚获取的锁并返回失败
        LeaveCriticalSection(FCriticalSection);
        Result := False;
      end
      else
      begin
        // 原子设置所有权
        atomic_store(FOwnerThreadId, CurrentThreadId);
        Result := True;
      end;
    except
      LeaveCriticalSection(FCriticalSection);
      Result := False;
    end;
  end
  else
  begin
    Result := False;
  end;
end;

function TMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  CurrentThreadId: LongInt;
begin
  CurrentThreadId := LongInt(GetCurrentThreadId);

  // 对于不可重入锁，检查重入（原子读取）
  // 如果是重入，直接返回失败，不进行等待（因为同一线程永远不会释放自己持有的锁）
  if atomic_load(FOwnerThreadId) = CurrentThreadId then
    Exit(False);

  // 调用基类的优化超时实现
  Result := inherited TryAcquire(ATimeoutMs);
end;


function TMutex.GetHandle: Pointer;
begin
  Result := @FCriticalSection;
end;

{$IFDEF FAFAFA_CORE_USE_SRWLOCK}
{ TSRWMutex - 现代 SRWLOCK 实现 }

constructor TSRWMutex.Create;
begin
  inherited Create;
  InitializeSRWLock(FLock);
  atomic_store(FOwnerThreadId, 0);
end;

destructor TSRWMutex.Destroy;
begin
  inherited Destroy;
end;

procedure TSRWMutex.Acquire;
var
  CurrentThreadId: Int32;
begin
  CurrentThreadId := Int32(GetCurrentThreadId);

  // 检查重入（原子读取）
  if atomic_load(FOwnerThreadId) = CurrentThreadId then
    raise ELockError.Create('Non-reentrant mutex: reentrancy detected');

  // 获取 SRWLOCK
  AcquireSRWLockExclusive(FLock);

  // 设置所有权（原子写入）
  atomic_store(FOwnerThreadId, CurrentThreadId);
end;

procedure TSRWMutex.Release;
var
  CurrentThreadId: Int32;
begin
  CurrentThreadId := Int32(GetCurrentThreadId);

  // 检查所有权（原子读取）
  if atomic_load(FOwnerThreadId) <> CurrentThreadId then
    raise ELockError.Create('Mutex not owned by current thread');

  // 清除所有权（原子写入）
  atomic_store(FOwnerThreadId, 0);

  // 释放 SRWLOCK
  ReleaseSRWLockExclusive(FLock);
end;

function TSRWMutex.TryAcquire: Boolean;
var
  CurrentThreadId: Int32;
begin
  CurrentThreadId := Int32(GetCurrentThreadId);

  // 检查重入（原子读取）
  if atomic_load(FOwnerThreadId) = CurrentThreadId then
  begin
    Result := False;
    Exit;
  end;

  // 尝试获取 SRWLOCK
  if TryAcquireSRWLockExclusive(FLock) then
  begin
    // 设置所有权（原子写入）
    atomic_store(FOwnerThreadId, CurrentThreadId);
    Result := True;
  end
  else
  begin
    Result := False;
  end;
end;

function TSRWMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  CurrentThreadId: Int32;
begin
  CurrentThreadId := Int32(GetCurrentThreadId);

  // 对于不可重入锁，检查重入
  // 如果是重入，直接返回失败，不进行等待（因为同一线程永远不会释放自己持有的锁）
  if atomic_load(FOwnerThreadId) = CurrentThreadId then
    Exit(False);

  // 调用基类的优化超时实现
  Result := inherited TryAcquire(ATimeoutMs);
end;

function TSRWMutex.GetHandle: Pointer;
begin
  Result := @FLock;
end;
{$ENDIF}

end.