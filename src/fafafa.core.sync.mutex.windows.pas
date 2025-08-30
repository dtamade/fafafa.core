unit fafafa.core.sync.mutex.windows;

{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base,
  fafafa.core.sync.mutex.base;

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
  InitializeCriticalSection(FCriticalSection);
end;

destructor TMutex.Destroy;
begin
  DeleteCriticalSection(FCriticalSection);
  inherited Destroy;
end;

procedure TMutex.Acquire;
begin
  // 直接获取锁，不检查重入
  // 如果同一线程重复获取，CRITICAL_SECTION 会允许重入
  // 但通过不跟踪所有者来保持简单的 Mutex 语义
  EnterCriticalSection(FCriticalSection);
end;

procedure TMutex.Release;
begin
  LeaveCriticalSection(FCriticalSection);
end;

function TMutex.TryAcquire: Boolean;
begin
  Result := TryEnterCriticalSection(FCriticalSection);
end;

function TMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
begin
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
end;

destructor TSRWMutex.Destroy;
begin
  inherited Destroy;
end;

procedure TSRWMutex.Acquire;
begin
  AcquireSRWLockExclusive(FLock);
end;

procedure TSRWMutex.Release;
begin
  ReleaseSRWLockExclusive(FLock);
end;

function TSRWMutex.TryAcquire: Boolean;
begin
  Result := TryAcquireSRWLockExclusive(FLock);
end;

function TSRWMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
begin
  Result := inherited TryAcquire(ATimeoutMs);
end;

function TSRWMutex.GetHandle: Pointer;
begin
  Result := @FLock;
end;
{$ENDIF}

end.