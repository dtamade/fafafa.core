unit fafafa.core.sync.mutex.native;

{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base;

type
  {$IFDEF WINDOWS}
  // 直接使用 Windows API 的 Mutex 实现
  TNativeWinMutex = class(TInterfacedObject, ITryLock)
  private
    FHandle: THandle;
    FData: Pointer;
  public
    constructor Create;
    destructor Destroy; override;
    
    // ISynchronizable 接口实现
    function GetData: Pointer;
    procedure SetData(aData: Pointer);
    
    // ILock 接口实现
    procedure Acquire;
    procedure Release;
    function LockGuard: ILockGuard;
    
    // ITryLock 接口实现
    function TryAcquire: Boolean;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean;
  end;

  // 直接使用 Windows CRITICAL_SECTION 的实现
  TNativeCriticalSection = class(TInterfacedObject, ITryLock)
  private
    FCriticalSection: TRTLCriticalSection;
    FData: Pointer;
  public
    constructor Create;
    destructor Destroy; override;
    
    // ISynchronizable 接口实现
    function GetData: Pointer;
    procedure SetData(aData: Pointer);
    
    // ILock 接口实现
    procedure Acquire;
    procedure Release;
    function LockGuard: ILockGuard;
    
    // ITryLock 接口实现
    function TryAcquire: Boolean;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean;
  end;

  // 直接使用 Windows SRWLOCK 的实现
  TNativeSRWLock = class(TInterfacedObject, ITryLock)
  private
    FSRWLock: Pointer; // SRWLOCK 结构
    FData: Pointer;
  public
    constructor Create;
    destructor Destroy; override;
    
    // ISynchronizable 接口实现
    function GetData: Pointer;
    procedure SetData(aData: Pointer);
    
    // ILock 接口实现
    procedure Acquire;
    procedure Release;
    function LockGuard: ILockGuard;
    
    // ITryLock 接口实现
    function TryAcquire: Boolean;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean;
  end;

  {$ELSE}
  // 直接使用 Pthread API 的 Mutex 实现
  TNativePthreadMutex = class(TInterfacedObject, ITryLock)
  private
    FMutex: pthread_mutex_t;
    FData: Pointer;
  public
    constructor Create;
    destructor Destroy; override;
    
    // ISynchronizable 接口实现
    function GetData: Pointer;
    procedure SetData(aData: Pointer);
    
    // ILock 接口实现
    procedure Acquire;
    procedure Release;
    function LockGuard: ILockGuard;
    
    // ITryLock 接口实现
    function TryAcquire: Boolean;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean;
  end;

  // 直接使用 Pthread 快速 Mutex 的实现
  TNativePthreadFastMutex = class(TInterfacedObject, ITryLock)
  private
    FMutex: pthread_mutex_t;
    FData: Pointer;
  public
    constructor Create;
    destructor Destroy; override;
    
    // ISynchronizable 接口实现
    function GetData: Pointer;
    procedure SetData(aData: Pointer);
    
    // ILock 接口实现
    procedure Acquire;
    procedure Release;
    function LockGuard: ILockGuard;
    
    // ITryLock 接口实现
    function TryAcquire: Boolean;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean;
  end;
  {$ENDIF}

// 工厂函数
{$IFDEF WINDOWS}
function MakeNativeWinMutex: ITryLock;
function MakeNativeCriticalSection: ITryLock;
function MakeNativeSRWLock: ITryLock;
{$ELSE}
function MakeNativePthreadMutex: ITryLock;
function MakeNativePthreadFastMutex: ITryLock;
{$ENDIF}

implementation

uses
  {$IFDEF WINDOWS}
  Windows,
  {$ELSE}
  BaseUnix, Unix, pthreads,
  {$ENDIF}
  Classes;

{$IFDEF WINDOWS}

// Windows API 声明
type
  TAcquireSRWLockExclusive = procedure(SRWLock: Pointer); stdcall;
  TReleaseSRWLockExclusive = procedure(SRWLock: Pointer); stdcall;
  TTryAcquireSRWLockExclusive = function(SRWLock: Pointer): BOOL; stdcall;
  TInitializeSRWLock = procedure(SRWLock: Pointer); stdcall;

var
  AcquireSRWLockExclusiveFunc: TAcquireSRWLockExclusive = nil;
  ReleaseSRWLockExclusiveFunc: TReleaseSRWLockExclusive = nil;
  TryAcquireSRWLockExclusiveFunc: TTryAcquireSRWLockExclusive = nil;
  InitializeSRWLockFunc: TInitializeSRWLock = nil;
  HasSRWLock: Boolean = False;

procedure InitSRWLock;
var
  Kernel32: HMODULE;
begin
  Kernel32 := GetModuleHandle('kernel32.dll');
  if Kernel32 <> 0 then
  begin
    AcquireSRWLockExclusiveFunc := TAcquireSRWLockExclusive(GetProcAddress(Kernel32, 'AcquireSRWLockExclusive'));
    ReleaseSRWLockExclusiveFunc := TReleaseSRWLockExclusive(GetProcAddress(Kernel32, 'ReleaseSRWLockExclusive'));
    TryAcquireSRWLockExclusiveFunc := TTryAcquireSRWLockExclusive(GetProcAddress(Kernel32, 'TryAcquireSRWLockExclusive'));
    InitializeSRWLockFunc := TInitializeSRWLock(GetProcAddress(Kernel32, 'InitializeSRWLock'));
    HasSRWLock := Assigned(AcquireSRWLockExclusiveFunc) and Assigned(ReleaseSRWLockExclusiveFunc) and
                  Assigned(TryAcquireSRWLockExclusiveFunc) and Assigned(InitializeSRWLockFunc);
  end;
end;

function MakeNativeWinMutex: ITryLock;
begin
  Result := TNativeWinMutex.Create;
end;

function MakeNativeCriticalSection: ITryLock;
begin
  Result := TNativeCriticalSection.Create;
end;

function MakeNativeSRWLock: ITryLock;
begin
  Result := TNativeSRWLock.Create;
end;

{ TNativeWinMutex }

constructor TNativeWinMutex.Create;
begin
  inherited Create;
  FHandle := CreateMutex(nil, False, nil);
  if FHandle = 0 then
    raise Exception.Create('Failed to create Windows Mutex');
  FData := nil;
end;

destructor TNativeWinMutex.Destroy;
begin
  if FHandle <> 0 then
    CloseHandle(FHandle);
  inherited Destroy;
end;

function TNativeWinMutex.GetData: Pointer;
begin
  Result := FData;
end;

procedure TNativeWinMutex.SetData(aData: Pointer);
begin
  FData := aData;
end;

function TNativeWinMutex.LockGuard: ILockGuard;
begin
  Result := nil;
end;

procedure TNativeWinMutex.Acquire;
begin
  WaitForSingleObject(FHandle, INFINITE);
end;

procedure TNativeWinMutex.Release;
begin
  ReleaseMutex(FHandle);
end;

function TNativeWinMutex.TryAcquire: Boolean;
begin
  Result := WaitForSingleObject(FHandle, 0) = WAIT_OBJECT_0;
end;

function TNativeWinMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
begin
  Result := WaitForSingleObject(FHandle, ATimeoutMs) = WAIT_OBJECT_0;
end;

{ TNativeCriticalSection }

constructor TNativeCriticalSection.Create;
begin
  inherited Create;
  InitializeCriticalSection(FCriticalSection);
  FData := nil;
end;

destructor TNativeCriticalSection.Destroy;
begin
  DeleteCriticalSection(FCriticalSection);
  inherited Destroy;
end;

function TNativeCriticalSection.GetData: Pointer;
begin
  Result := FData;
end;

procedure TNativeCriticalSection.SetData(aData: Pointer);
begin
  FData := aData;
end;

function TNativeCriticalSection.LockGuard: ILockGuard;
begin
  Result := nil;
end;

procedure TNativeCriticalSection.Acquire;
begin
  EnterCriticalSection(FCriticalSection);
end;

procedure TNativeCriticalSection.Release;
begin
  LeaveCriticalSection(FCriticalSection);
end;

function TNativeCriticalSection.TryAcquire: Boolean;
begin
  Result := TryEnterCriticalSection(FCriticalSection);
end;

function TNativeCriticalSection.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  StartTime: DWORD;
begin
  if TryAcquire then
    Exit(True);

  if ATimeoutMs = 0 then
    Exit(False);

  StartTime := GetTickCount;
  repeat
    if TryAcquire then
      Exit(True);
    Sleep(1);
  until (GetTickCount - StartTime) >= ATimeoutMs;

  Result := False;
end;

{ TNativeSRWLock }

constructor TNativeSRWLock.Create;
begin
  inherited Create;
  if not HasSRWLock then
    raise Exception.Create('SRWLOCK not available on this Windows version');

  GetMem(FSRWLock, SizeOf(Pointer)); // SRWLOCK 是一个指针大小的结构
  InitializeSRWLockFunc(FSRWLock);
  FData := nil;
end;

destructor TNativeSRWLock.Destroy;
begin
  if FSRWLock <> nil then
    FreeMem(FSRWLock);
  inherited Destroy;
end;

function TNativeSRWLock.GetData: Pointer;
begin
  Result := FData;
end;

procedure TNativeSRWLock.SetData(aData: Pointer);
begin
  FData := aData;
end;

function TNativeSRWLock.LockGuard: ILockGuard;
begin
  Result := nil;
end;

procedure TNativeSRWLock.Acquire;
begin
  AcquireSRWLockExclusiveFunc(FSRWLock);
end;

procedure TNativeSRWLock.Release;
begin
  ReleaseSRWLockExclusiveFunc(FSRWLock);
end;

function TNativeSRWLock.TryAcquire: Boolean;
begin
  Result := TryAcquireSRWLockExclusiveFunc(FSRWLock);
end;

function TNativeSRWLock.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  StartTime: DWORD;
begin
  if TryAcquire then
    Exit(True);

  if ATimeoutMs = 0 then
    Exit(False);

  StartTime := GetTickCount;
  repeat
    if TryAcquire then
      Exit(True);
    Sleep(1);
  until (GetTickCount - StartTime) >= ATimeoutMs;

  Result := False;
end;

{$ELSE}

function MakeNativePthreadMutex: ITryLock;
begin
  Result := TNativePthreadMutex.Create;
end;

function MakeNativePthreadFastMutex: ITryLock;
begin
  Result := TNativePthreadFastMutex.Create;
end;

{ TNativePthreadMutex }

constructor TNativePthreadMutex.Create;
var
  Attr: pthread_mutexattr_t;
begin
  inherited Create;

  // 创建标准 pthread mutex
  pthread_mutexattr_init(@Attr);
  pthread_mutexattr_settype(@Attr, PTHREAD_MUTEX_NORMAL);

  if pthread_mutex_init(@FMutex, @Attr) <> 0 then
    raise Exception.Create('Failed to create pthread mutex');

  pthread_mutexattr_destroy(@Attr);
  FData := nil;
end;

destructor TNativePthreadMutex.Destroy;
begin
  pthread_mutex_destroy(@FMutex);
  inherited Destroy;
end;

function TNativePthreadMutex.GetData: Pointer;
begin
  Result := FData;
end;

procedure TNativePthreadMutex.SetData(aData: Pointer);
begin
  FData := aData;
end;

function TNativePthreadMutex.LockGuard: ILockGuard;
begin
  Result := nil;
end;

procedure TNativePthreadMutex.Acquire;
begin
  pthread_mutex_lock(@FMutex);
end;

procedure TNativePthreadMutex.Release;
begin
  pthread_mutex_unlock(@FMutex);
end;

function TNativePthreadMutex.TryAcquire: Boolean;
begin
  Result := pthread_mutex_trylock(@FMutex) = 0;
end;

function TNativePthreadMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  StartTime: DWORD;
begin
  if TryAcquire then
    Exit(True);

  if ATimeoutMs = 0 then
    Exit(False);

  StartTime := GetTickCount;
  repeat
    if TryAcquire then
      Exit(True);
    usleep(1000); // 1ms
  until (GetTickCount - StartTime) >= ATimeoutMs;

  Result := False;
end;

{ TNativePthreadFastMutex }

constructor TNativePthreadFastMutex.Create;
var
  Attr: pthread_mutexattr_t;
begin
  inherited Create;

  // 创建快速 pthread mutex (adaptive)
  pthread_mutexattr_init(@Attr);
  pthread_mutexattr_settype(@Attr, PTHREAD_MUTEX_ADAPTIVE_NP);

  if pthread_mutex_init(@FMutex, @Attr) <> 0 then
    raise Exception.Create('Failed to create pthread fast mutex');

  pthread_mutexattr_destroy(@Attr);
  FData := nil;
end;

destructor TNativePthreadFastMutex.Destroy;
begin
  pthread_mutex_destroy(@FMutex);
  inherited Destroy;
end;

function TNativePthreadFastMutex.GetData: Pointer;
begin
  Result := FData;
end;

procedure TNativePthreadFastMutex.SetData(aData: Pointer);
begin
  FData := aData;
end;

function TNativePthreadFastMutex.LockGuard: ILockGuard;
begin
  Result := nil;
end;

procedure TNativePthreadFastMutex.Acquire;
begin
  pthread_mutex_lock(@FMutex);
end;

procedure TNativePthreadFastMutex.Release;
begin
  pthread_mutex_unlock(@FMutex);
end;

function TNativePthreadFastMutex.TryAcquire: Boolean;
begin
  Result := pthread_mutex_trylock(@FMutex) = 0;
end;

function TNativePthreadFastMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  StartTime: DWORD;
begin
  if TryAcquire then
    Exit(True);

  if ATimeoutMs = 0 then
    Exit(False);

  StartTime := GetTickCount;
  repeat
    if TryAcquire then
      Exit(True);
    usleep(1000); // 1ms
  until (GetTickCount - StartTime) >= ATimeoutMs;

  Result := False;
end;

{$ENDIF}

{$IFDEF WINDOWS}
initialization
  InitSRWLock;
{$ENDIF}

end.
