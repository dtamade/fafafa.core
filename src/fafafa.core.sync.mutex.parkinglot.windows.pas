unit fafafa.core.sync.mutex.parkinglot.windows;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.atomic,
  fafafa.core.sync.mutex.parkinglot.base;

// Windows API 声明
type
  THandle = PtrUInt; // define locally to avoid requiring Windows unit
  HMODULE = THandle;
  DWORD = Cardinal;
  BOOL = LongBool;
  SIZE_T = PtrUInt;

function GetModuleHandle(lpModuleName: PChar): HMODULE; stdcall; external 'kernel32.dll' name 'GetModuleHandleA';
function GetProcAddress(hModule: HMODULE; lpProcName: PChar): Pointer; stdcall; external 'kernel32.dll' name 'GetProcAddress';
function GetTickCount: DWORD; stdcall; external 'kernel32.dll' name 'GetTickCount';
procedure Sleep(dwMilliseconds: DWORD); stdcall; external 'kernel32.dll' name 'Sleep';
function SwitchToThread: BOOL; stdcall; external 'kernel32.dll' name 'SwitchToThread';
function WaitForSingleObject(hHandle: THandle; dwMilliseconds: DWORD): DWORD; stdcall; external 'kernel32.dll' name 'WaitForSingleObject';
function CloseHandle(hObject: THandle): BOOL; stdcall; external 'kernel32.dll' name 'CloseHandle';
function CreateSemaphoreW(lpSemaphoreAttributes: Pointer; lInitialCount: LongInt; lMaximumCount: LongInt; lpName: PWideChar): THandle; stdcall; external 'kernel32.dll' name 'CreateSemaphoreW';
function ReleaseSemaphore(hSemaphore: THandle; lReleaseCount: LongInt; lpPreviousCount: Pointer): BOOL; stdcall; external 'kernel32.dll' name 'ReleaseSemaphore';
type
  TRTLCriticalSectionX = record
    DebugInfo: Pointer;
    LockCount: LongInt;
    RecursionCount: LongInt;
    OwningThread: THandle;
    LockSemaphore: THandle;
    SpinCount: PtrUInt;
  end;

// 为避免与 System.Windows 单元的名称冲突，使用带前缀的声�?
procedure WinInitializeCriticalSection(var lpCriticalSection: TRTLCriticalSectionX); stdcall; external 'kernel32.dll' name 'InitializeCriticalSection';
procedure WinEnterCriticalSection(var lpCriticalSection: TRTLCriticalSectionX); stdcall; external 'kernel32.dll' name 'EnterCriticalSection';
procedure WinLeaveCriticalSection(var lpCriticalSection: TRTLCriticalSectionX); stdcall; external 'kernel32.dll' name 'LeaveCriticalSection';
procedure WinDeleteCriticalSection(var lpCriticalSection: TRTLCriticalSectionX); stdcall; external 'kernel32.dll' name 'DeleteCriticalSection';

type
  {**
   * TParkingLotMutex - Windows 平台�?Parking Lot 互斥锁实�?
   *
   * @desc
   *   使用 Windows 8.1+ �?WaitOnAddress/WakeByAddressSingle API
   *   实现高效的线程等待和唤醒机制。对于旧版本 Windows�?
   *   回退�?SwitchToThread + Sleep 的组合策略�?
   *
   * @features
   *   - Windows 8.1+: 使用 WaitOnAddress 实现真正的地址等待
   *   - Windows 7/XP: 使用智能退避策略模拟等�?
   *   - 自动检测系统能力并选择最优实�?
   *
   * @performance
   *   在支�?WaitOnAddress 的系统上性能接近内核 futex�?
   *   在旧系统上通过智能退避策略最小化性能损失�?
   *}
  TParkingLotMutex = class(TParkingLotMutexBase)
  private
    // XP 回退：每锁一个信号量 + 等待者计�?
    FSem: THandle;
    FWaiters: Int32;

    // 仅用于旧�?CS 回退（保留以便调试极端长尾）
    FUsingFallback: Boolean;
    function TryEnterFallbackMode: Boolean;
    procedure ExitFallbackMode;

    procedure EnsureSemaphore; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

  protected
    function ParkThread(ATimeoutMs: Cardinal = INFINITE): Boolean; override;
    function  UnparkOneThread: Boolean; override;

  public
    constructor Create; override;
    destructor Destroy; override;
  end;

function MakeParkingLotMutex: IParkingLotMutex;

implementation


type
  // Windows API 函数类型定义
  TWaitOnAddress       = function(Address: Pointer; CompareAddress: Pointer; AddressSize: SIZE_T; dwMilliseconds: DWORD): BOOL; stdcall;
  TWakeByAddressSingle = procedure(Address: Pointer); stdcall;

  // NTDLL Keyed Events（Vista/7�?
  LARGE_INTEGER = record
    QuadPart: Int64;
  end;
  PLARGE_INTEGER = ^LARGE_INTEGER;
  TNtCreateKeyedEvent = function(out KeyedEventHandle: THandle; DesiredAccess: Cardinal; ObjectAttributes: Pointer; Flags: Cardinal): LongInt; stdcall;
  TNtWaitForKeyedEvent = function(KeyedEventHandle: THandle; Key: Pointer; Alertable: LongBool; Timeout: PLARGE_INTEGER): LongInt; stdcall;
  TNtReleaseKeyedEvent = function(KeyedEventHandle: THandle; Key: Pointer; Alertable: LongBool; Timeout: PLARGE_INTEGER): LongInt; stdcall;

const
  // 扩展的状态位定义
  FALLBACK_BIT = 4;  // 表示正在使用 CriticalSection 回退
  STATUS_SUCCESS = 0;
  WAIT_OBJECT_0 = 0;
  WAIT_TIMEOUT  = 258;
  KEYEDEVENT_ALL_ACCESS = $001F0003;

var
  // 全局 WaitOnAddress API 状�?
  GWaitOnAddressFunc: Pointer = nil;
  GWakeByAddressSingleFunc: Pointer = nil;
  GHasWaitOnAddress: Boolean = False;

  // NTDLL Keyed Events 状态（Vista/7�?
  GNtCreateKeyedEvent: TNtCreateKeyedEvent = nil;
  GNtWaitForKeyedEvent: TNtWaitForKeyedEvent = nil;
  GNtReleaseKeyedEvent: TNtReleaseKeyedEvent = nil;
  GHasKeyedEvents: Boolean = False;
  GKeyedEventHandle: THandle = 0;

  // 初始化标�?
  GInitialized: Boolean = False;

  // 全局回退 CriticalSection（已弃用：仅保留以备极端调试�?
  GFallbackCS: TRTLCriticalSectionX;
  GFallbackCSInitialized: Int32 = 0;  // 使用 Int32 以支持原子操�?

// 初始化回退 CriticalSection（线程安全）
procedure InitializeFallbackCS;
var
  LExpected: Int32;
begin
  // 使用原子操作确保线程安全的初始化
  if atomic_load(GFallbackCSInitialized, mo_acquire) = 0 then
  begin
    // 双重检查锁定模�?
    LExpected := 0;
    if atomic_compare_exchange_strong(GFallbackCSInitialized, LExpected, 1) then
    begin
      WinInitializeCriticalSection(GFallbackCS);
      // 内存屏障确保初始化完成后才设置标�?
      atomic_store(GFallbackCSInitialized, 2, mo_release);  // 2 表示初始化完�?
    end
    else
    begin
      // 等待其他线程完成初始�?
      while atomic_load(GFallbackCSInitialized, mo_acquire) < 2 do
        Sleep(0);
    end;
  end;
end;

// 全局初始化函�?
procedure InitializeWaitOnAddress;
var
  LKernel32, LNtDll: HMODULE;
  status: LongInt;
begin
  if GInitialized then
    Exit;

  LKernel32 := GetModuleHandle('kernel32.dll');
  if LKernel32 <> 0 then
  begin
    GWaitOnAddressFunc := GetProcAddress(LKernel32, 'WaitOnAddress');
    GWakeByAddressSingleFunc := GetProcAddress(LKernel32, 'WakeByAddressSingle');
    GHasWaitOnAddress := Assigned(GWaitOnAddressFunc) and Assigned(GWakeByAddressSingleFunc);
  end;

  // 解析 NTDLL Keyed Events（Vista/7�?
  LNtDll := GetModuleHandle('ntdll.dll');
  if LNtDll <> 0 then
  begin
    Pointer(GNtCreateKeyedEvent)  := GetProcAddress(LNtDll, 'NtCreateKeyedEvent');
    Pointer(GNtWaitForKeyedEvent) := GetProcAddress(LNtDll, 'NtWaitForKeyedEvent');
    Pointer(GNtReleaseKeyedEvent) := GetProcAddress(LNtDll, 'NtReleaseKeyedEvent');
    if Assigned(GNtCreateKeyedEvent) and Assigned(GNtWaitForKeyedEvent) and Assigned(GNtReleaseKeyedEvent) then
    begin
      status := GNtCreateKeyedEvent(GKeyedEventHandle, KEYEDEVENT_ALL_ACCESS, nil, 0);
      GHasKeyedEvents := (status = STATUS_SUCCESS) and (GKeyedEventHandle <> 0);
    end;
  end;

  // 初始化回退机制（仅用于极端调试�?
  InitializeFallbackCS;

  GInitialized := True;
end;

function HasWaitOnAddressSupport: Boolean; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
begin
  if not GInitialized then
    InitializeWaitOnAddress;
  Result := GHasWaitOnAddress;
end;

{ TParkingLotMutex }

constructor TParkingLotMutex.Create;
begin
  inherited Create;
  FSem := 0;
  atomic_store(FWaiters, 0, mo_relaxed);
  FUsingFallback := False;
end;

destructor TParkingLotMutex.Destroy;
begin
  if FSem <> 0 then CloseHandle(FSem);
  inherited Destroy;
end;

procedure TParkingLotMutex.EnsureSemaphore;
begin
  if FSem = 0 then
  begin
    // 初始计数 0，最大计数一个较大�?
    FSem := CreateSemaphoreW(nil, 0, $7FFFFFFF, nil);
  end;
end;

function TParkingLotMutex.TryEnterFallbackMode: Boolean;
var
  LCurrentState, LNewState: Int32;
begin
  // 原子地设�?FALLBACK_BIT，表示进入回退模式
  repeat
    LCurrentState := atomic_load(FState, mo_acquire);

    // 如果已经有其他线程在使用回退模式，返�?False
    if (LCurrentState and FALLBACK_BIT) <> 0 then
      Exit(False);

    // 设置 FALLBACK_BIT
    LNewState := LCurrentState or FALLBACK_BIT;
  until atomic_compare_exchange_weak(FState, LCurrentState, LNewState);

  // 成功设置标志位后，进�?CriticalSection
  InitializeFallbackCS;
  WinEnterCriticalSection(GFallbackCS);
  FUsingFallback := True;
  Result := True;
end;

procedure TParkingLotMutex.ExitFallbackMode;
var
  LCur, LNew: Int32;
begin
  if not FUsingFallback then
    Exit;

  // 先退�?CriticalSection
  WinLeaveCriticalSection(GFallbackCS);

  // 然后原子地清�?FALLBACK_BIT（采�?CAS 循环�?
  repeat
    LCur := atomic_load(FState, mo_acquire);
    LNew := LCur and (not FALLBACK_BIT);
  until atomic_compare_exchange_weak(FState, LCur, LNew);
  FUsingFallback := False;
end;

function TParkingLotMutex.ParkThread(ATimeoutMs: Cardinal): Boolean;
var
  LExpectedState: Int32;
  TimeoutNt: LARGE_INTEGER;
  PTimeoutNt: PLARGE_INTEGER;
  dw: DWORD;
begin
  // 验证状态：确保我们应该等待
  LExpectedState := atomic_load(FState, mo_relaxed);
  if (LExpectedState and (LOCKED_BIT or PARKED_BIT)) <> (LOCKED_BIT or PARKED_BIT) then
    Exit(True); // 状态已改变，不需要等�?

  if HasWaitOnAddressSupport then
  begin
    // Windows 8+: 使用 WaitOnAddress 实现真正的地址等待
    Result := TWaitOnAddress(GWaitOnAddressFunc)(@FState, @LExpectedState, SizeOf(Int32), ATimeoutMs);
    Exit;
  end;

  if GHasKeyedEvents and (GKeyedEventHandle <> 0) then
  begin
    // Vista/7: 使用 Keyed Events
    if ATimeoutMs = INFINITE then PTimeoutNt := nil
    else begin TimeoutNt.QuadPart := -Int64(ATimeoutMs) * 10000; PTimeoutNt := @TimeoutNt; end;
    Result := (GNtWaitForKeyedEvent(GKeyedEventHandle, @FState, False, PTimeoutNt) = STATUS_SUCCESS);
    Exit;
  end;

  // XP: 每锁一个信号量 + waiters 计数
  EnsureSemaphore;
  atomic_increment(FWaiters);
  try
    dw := WaitForSingleObject(FSem, ATimeoutMs);
    Result := (dw = WAIT_OBJECT_0);
  finally
    atomic_decrement(FWaiters);
  end;
end;

function TParkingLotMutex.UnparkOneThread: Boolean;
begin
  if HasWaitOnAddressSupport then
  begin
    // Windows 8+: 使用 WakeByAddressSingle 唤醒单个线程
    TWakeByAddressSingle(GWakeByAddressSingleFunc)(@FState);
    Exit(True);
  end;

  if GHasKeyedEvents and (GKeyedEventHandle <> 0) then
  begin
    Result := (GNtReleaseKeyedEvent(GKeyedEventHandle, @FState, False, nil) = STATUS_SUCCESS);
    Exit;
  end;

  // XP: 若有等待者，释放一个信号量令其醒来；若没有，保持静默（不累积计数以避免误唤醒新来的线程�?
  if atomic_load(FWaiters, mo_relaxed) > 0 then
  begin
    EnsureSemaphore;
    Result := ReleaseSemaphore(FSem, 1, nil);
  end
  else
    Result := False;
end;

function MakeParkingLotMutex: IParkingLotMutex;
begin
  Result := TParkingLotMutex.Create;
end;

initialization
  InitializeWaitOnAddress;

finalization
  if atomic_load(GFallbackCSInitialized, mo_acquire) = 2 then
    WinDeleteCriticalSection(GFallbackCS);
  if GKeyedEventHandle <> 0 then CloseHandle(GKeyedEventHandle);

end.
