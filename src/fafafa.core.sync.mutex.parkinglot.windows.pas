unit fafafa.core.sync.mutex.parkinglot.windows;

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
type
  TRTLCriticalSectionX = record
    DebugInfo: Pointer;
    LockCount: LongInt;
    RecursionCount: LongInt;
    OwningThread: THandle;
    LockSemaphore: THandle;
    SpinCount: PtrUInt;
  end;

// 为避免与 System.Windows 单元的名称冲突，使用带前缀的声明
procedure WinInitializeCriticalSection(var lpCriticalSection: TRTLCriticalSectionX); stdcall; external 'kernel32.dll' name 'InitializeCriticalSection';
procedure WinEnterCriticalSection(var lpCriticalSection: TRTLCriticalSectionX); stdcall; external 'kernel32.dll' name 'EnterCriticalSection';
procedure WinLeaveCriticalSection(var lpCriticalSection: TRTLCriticalSectionX); stdcall; external 'kernel32.dll' name 'LeaveCriticalSection';
procedure WinDeleteCriticalSection(var lpCriticalSection: TRTLCriticalSectionX); stdcall; external 'kernel32.dll' name 'DeleteCriticalSection';

type
  {**
   * TParkingLotMutex - Windows 平台的 Parking Lot 互斥锁实现
   *
   * @desc
   *   使用 Windows 8.1+ 的 WaitOnAddress/WakeByAddressSingle API
   *   实现高效的线程等待和唤醒机制。对于旧版本 Windows，
   *   回退到 SwitchToThread + Sleep 的组合策略。
   *
   * @features
   *   - Windows 8.1+: 使用 WaitOnAddress 实现真正的地址等待
   *   - Windows 7/XP: 使用智能退避策略模拟等待
   *   - 自动检测系统能力并选择最优实现
   *
   * @performance
   *   在支持 WaitOnAddress 的系统上性能接近内核 futex，
   *   在旧系统上通过智能退避策略最小化性能损失。
   *}
  TParkingLotMutex = class(TParkingLotMutexBase)
  private
    FUsingFallback: Boolean;  // 标记是否正在使用 CriticalSection 回退

    // 安全地进入 CriticalSection 回退模式
    function TryEnterFallbackMode: Boolean;
    // 安全地退出 CriticalSection 回退模式
    procedure ExitFallbackMode;

  protected
    function ParkThread(ATimeoutMs: Cardinal = INFINITE): Boolean; override;
    function  UnparkOneThread: Boolean; override;

  public
    constructor Create; override;
  end;

function MakeParkingLotMutex: IParkingLotMutex;

implementation

type
  // Windows API 函数类型定义
  TWaitOnAddress       = function(Address: Pointer; CompareAddress: Pointer; AddressSize: SIZE_T; dwMilliseconds: DWORD): BOOL; stdcall;
  TWakeByAddressSingle = procedure(Address: Pointer); stdcall;

const
  // 扩展的状态位定义
  FALLBACK_BIT = 4;  // 表示正在使用 CriticalSection 回退

var
  // 全局 WaitOnAddress API 状态
  GWaitOnAddressFunc: Pointer = nil;
  GWakeByAddressSingleFunc: Pointer = nil;
  GHasWaitOnAddress: Boolean = False;
  GInitialized: Boolean = False;

  // 全局回退 CriticalSection（用于极端情况）
  GFallbackCS: TRTLCriticalSectionX;
  GFallbackCSInitialized: Int32 = 0;  // 使用 Int32 以支持原子操作

// 初始化回退 CriticalSection（线程安全）
procedure InitializeFallbackCS;
var
  LExpected: Int32;
begin
  // 使用原子操作确保线程安全的初始化
  if atomic_load(GFallbackCSInitialized, mo_acquire) = 0 then
  begin
    // 双重检查锁定模式
    LExpected := 0;
    if atomic_compare_exchange_strong(GFallbackCSInitialized, LExpected, 1) then
    begin
      WinInitializeCriticalSection(GFallbackCS);
      // 内存屏障确保初始化完成后才设置标志
      atomic_store(GFallbackCSInitialized, 2, mo_release);  // 2 表示初始化完成
    end
    else
    begin
      // 等待其他线程完成初始化
      while atomic_load(GFallbackCSInitialized, mo_acquire) < 2 do
        Sleep(0);
    end;
  end;
end;

// 全局初始化函数
procedure InitializeWaitOnAddress;
var
  LKernel32: HMODULE;
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

  // 初始化回退机制
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
  FUsingFallback := False;
end;

function TParkingLotMutex.TryEnterFallbackMode: Boolean;
var
  LCurrentState, LNewState: Int32;
begin
  // 原子地设置 FALLBACK_BIT，表示进入回退模式
  repeat
    LCurrentState := atomic_load(FState, mo_acquire);

    // 如果已经有其他线程在使用回退模式，返回 False
    if (LCurrentState and FALLBACK_BIT) <> 0 then
      Exit(False);

    // 设置 FALLBACK_BIT
    LNewState := LCurrentState or FALLBACK_BIT;
  until atomic_compare_exchange_weak(FState, LCurrentState, LNewState);

  // 成功设置标志位后，进入 CriticalSection
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

  // 先退出 CriticalSection
  WinLeaveCriticalSection(GFallbackCS);

  // 然后原子地清除 FALLBACK_BIT（采用 CAS 循环）
  repeat
    LCur := atomic_load(FState, mo_acquire);
    LNew := LCur and (not FALLBACK_BIT);
  until atomic_compare_exchange_weak(FState, LCur, LNew);
  FUsingFallback := False;
end;

function TParkingLotMutex.ParkThread(ATimeoutMs: Cardinal): Boolean;
var
  LExpectedState: Int32;
  LBackoffCount: Integer;
  LSpinCount: Integer;
  LStartTime: DWORD;
  i: Integer;
  LSleepTime: Integer;
begin
  // 验证状态：确保我们应该等待
  LExpectedState := atomic_load(FState, mo_relaxed);
  if (LExpectedState and (LOCKED_BIT or PARKED_BIT)) <> (LOCKED_BIT or PARKED_BIT) then
    Exit(True); // 状态已改变，不需要等待

  if HasWaitOnAddressSupport then
  begin
    // Windows 8.1+: 使用 WaitOnAddress 实现真正的地址等待
    Result := TWaitOnAddress(GWaitOnAddressFunc)(@FState, @LExpectedState, SizeOf(Int32), ATimeoutMs);
  end
  else
  begin
    // Windows 7/XP: 使用高级智能退避策略
    LBackoffCount := 0;
    LSpinCount := 0;
    LStartTime := GetTickCount;

    repeat
      // 检查状态是否改变
      if atomic_load(FState, mo_relaxed) <> LExpectedState then
        Exit(True);

      // 检查超时（如果有设置）
      if (ATimeoutMs <> INFINITE) and (GetTickCount - LStartTime >= ATimeoutMs) then
        Exit(False);

      // 多阶段智能退避策略
      case LBackoffCount of
        0..15:
          begin
            // 阶段1：CPU 暂停指令 + 紧密自旋
            // 使用 PAUSE 指令减少功耗并提高超线程性能
            for i := 1 to (1 shl LBackoffCount) do
            begin
              asm
                pause; // Intel PAUSE 指令，减少功耗
              end;
              // 每几次 PAUSE 后检查一次状态
              if (i and 7 = 0) and (atomic_load(FState, mo_relaxed) <> LExpectedState) then
                Exit(True);
            end;
          end;
        16..31:
          begin
            // 阶段2：让出时间片给同优先级线程
            SwitchToThread;
          end;
        32..47:
          begin
            // 阶段3：让出时间片给所有线程
            Sleep(0);
          end;
        48..63:
          begin
            // 阶段4：短暂睡眠，使用指数退避
            Sleep(1 shl ((LBackoffCount - 48) div 4)); // 1, 2, 4, 8ms
          end;
        64..79:
          begin
            // 阶段5：较长睡眠，但限制最大值
            LSleepTime := 1 shl ((LBackoffCount - 64) div 8);
            if LSleepTime > 16 then LSleepTime := 16;
            Sleep(LSleepTime);
          end;
        else
          begin
            // 阶段6：极端情况下使用 CriticalSection 回退
            // 这是最后的手段，用于处理极长时间的竞争
            if TryEnterFallbackMode then
            try
              // 在回退模式中再次检查状态
              if atomic_load(FState, mo_relaxed) and (LOCKED_BIT or PARKED_BIT) = (LOCKED_BIT or PARKED_BIT) then
              begin
                // 短暂等待，让持锁线程有机会释放
                Sleep(1);
              end;
            finally
              ExitFallbackMode;
            end
            else
            begin
              // 如果无法进入回退模式（其他线程已在使用），回到较早的阶段
              LBackoffCount := 32;
              Continue;
            end;

            // 重置计数器，避免一直使用 CriticalSection
            LBackoffCount := 48; // 重置到阶段4
          end;
      end;

      Inc(LBackoffCount);
      // 防止计数器无限增长，在合理范围内循环
      if LBackoffCount > 100 then
        LBackoffCount := 32; // 重置到阶段3，避免过度睡眠

    until False;
  end;

  // 默认返回 True（被唤醒或状态改变）
  Result := True;
end;

function TParkingLotMutex.UnparkOneThread: Boolean;
var
  LCurrentState: Int32;
begin
  // 检查是否有线程在使用回退模式
  LCurrentState := atomic_load(FState, mo_acquire);

  if HasWaitOnAddressSupport then
  begin
    // Windows 8.1+: 使用 WakeByAddressSingle 唤醒单个线程
    TWakeByAddressSingle(GWakeByAddressSingleFunc)(@FState);
    Result := True; // WakeByAddressSingle 不返回唤醒的线程数
  end
  else
  begin
    // Windows 7/XP: 无法直接唤醒，依赖轮询检测
    // 但如果有线程在回退模式中，它们会在 CriticalSection 中等待
    Result := False;
  end;

  // 注意：不需要特殊处理 FALLBACK_BIT，因为：
  // 1. 在回退模式中的线程会在 CriticalSection 中短暂等待后自动退出
  // 2. 状态变化会被等待线程检测到
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

end.