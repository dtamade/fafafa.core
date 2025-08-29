unit fafafa.core.sync.mutex.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Windows, SysUtils,
  fafafa.core.sync.base, fafafa.core.sync.mutex.base;

type
  // 前向声明
  TMutex = class;

  // RAII 互斥锁守护实现
  TMutexGuard = class(TInterfacedObject, IMutexGuard)
  private
    FMutex: TMutex;
    FLocked: Boolean;
  public
    constructor Create(AMutex: TMutex; ATryLock: Boolean = False);
    destructor Destroy; override;
    function IsLocked: Boolean;
  end;

  // 标准可重入互斥锁实现（使用 CRITICAL_SECTION）
  TMutex = class(TInterfacedObject, IMutex)
  private
    FCriticalSection: CRITICAL_SECTION;
    FLastError: TWaitError;
  public
    constructor Create;
    destructor Destroy; override;
    // ILock
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean; overload;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
    // ISynchronizable
    function GetLastError: TWaitError;
    // IMutex
    function GetHandle: Pointer;
    function GetHoldCount: Integer;
    function IsHeldByCurrentThread: Boolean;
    // RAII 支持
    function Lock: IMutexGuard;
    function TryLock: IMutexGuard;
  end;

  // 非重入互斥锁实现（使用 SRWLOCK）
  TNonReentrantMutex = class(TInterfacedObject, INonReentrantMutex)
  private
    FLock: SRWLOCK;
    FLastError: TWaitError;
  public
    constructor Create;
    destructor Destroy; override;
    // ILock
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean; overload;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
    // ISynchronizable
    function GetLastError: TWaitError;
    // INonReentrantMutex
    function GetHandle: Pointer;
  end;

implementation

{ TMutexGuard - RAII 互斥锁守护实现 }

constructor TMutexGuard.Create(AMutex: TMutex; ATryLock: Boolean);
begin
  inherited Create;
  FMutex := AMutex;
  FLocked := False;

  if ATryLock then
  begin
    FLocked := FMutex.TryAcquire;
  end
  else
  begin
    FMutex.Acquire;
    FLocked := True;
  end;
end;

destructor TMutexGuard.Destroy;
begin
  if FLocked then
    FMutex.Release;
  inherited Destroy;
end;

function TMutexGuard.IsLocked: Boolean;
begin
  Result := FLocked;
end;

{ TMutex - 可重入互斥锁实现 }

constructor TMutex.Create;
begin
  inherited Create;
  InitializeCriticalSection(FCriticalSection);
  FLastError := weNone;
end;

destructor TMutex.Destroy;
begin
  DeleteCriticalSection(FCriticalSection);
  inherited Destroy;
end;

procedure TMutex.Acquire;
begin
  // 使用 CRITICAL_SECTION，天然支持可重入
  EnterCriticalSection(FCriticalSection);
  FLastError := weNone;
end;

procedure TMutex.Release;
begin
  // 使用 CRITICAL_SECTION，自动处理重入计数
  LeaveCriticalSection(FCriticalSection);
  FLastError := weNone;
end;

function TMutex.TryAcquire: Boolean;
begin
  // 使用 CRITICAL_SECTION，支持可重入
  Result := TryEnterCriticalSection(FCriticalSection);

  if Result then
    FLastError := weNone
  else
    FLastError := weTimeout; // TryAcquire 失败通常是因为锁被占用
end;

function TMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var start: QWord;
begin
  if ATimeoutMs = 0 then Exit(TryAcquire);
  start := GetTickCount64;
  while GetTickCount64 - start < ATimeoutMs do
  begin
    if TryAcquire then Exit(True);
    Sleep(1);
  end;
  Result := False;
end;

function TMutex.GetLastError: TWaitError;
begin
  Result := FLastError;
end;



function TMutex.GetHandle: Pointer;
begin
  Result := @FCriticalSection;
end;

function TMutex.GetHoldCount: Integer;
begin
  // Windows CRITICAL_SECTION 没有直接获取重入次数的API
  // 这里返回简化的实现：总是返回0
  // 在实际应用中，可能需要维护额外的状态信息
  Result := 0;
end;

function TMutex.IsHeldByCurrentThread: Boolean;
begin
  // 注意：CRITICAL_SECTION 没有直接检查持有者的API
  // 这里返回简化的实现：总是返回 False
  // 在实际应用中，可能需要维护额外的状态信息
  Result := False;
end;

function TMutex.Lock: IMutexGuard;
begin
  Result := TMutexGuard.Create(Self, False);
end;

function TMutex.TryLock: IMutexGuard;
begin
  Result := TMutexGuard.Create(Self, True);
  if not TMutexGuard(Result).IsLocked then
    Result := nil; // 获取锁失败，返回 nil
end;

{ TNonReentrantMutex - 非重入互斥锁实现 }

constructor TNonReentrantMutex.Create;
begin
  inherited Create;
  InitializeSRWLock(FLock);
  FLastError := weNone;
end;

destructor TNonReentrantMutex.Destroy;
begin
  // SRWLOCK 无需显式销毁
  inherited Destroy;
end;

procedure TNonReentrantMutex.Acquire;
begin
  AcquireSRWLockExclusive(FLock);
  FLastError := weNone;
end;

procedure TNonReentrantMutex.Release;
begin
  ReleaseSRWLockExclusive(FLock);
  FLastError := weNone;
end;

function TNonReentrantMutex.TryAcquire: Boolean;
begin
  Result := TryAcquireSRWLockExclusive(FLock);

  if Result then
    FLastError := weNone
  else
    FLastError := weTimeout;
end;

function TNonReentrantMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var start: QWord;
begin
  if ATimeoutMs = 0 then Exit(TryAcquire);
  start := GetTickCount64;
  while GetTickCount64 - start < ATimeoutMs do
  begin
    if TryAcquire then Exit(True);
    Sleep(1);
  end;
  Result := False;
end;

function TNonReentrantMutex.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

function TNonReentrantMutex.GetHandle: Pointer;
begin
  Result := @FLock;
end;

end.

