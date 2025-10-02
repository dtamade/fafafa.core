unit fafafa.core.sync.mutex.parkinglot.unix;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  {$IFDEF UNIX}BaseUnix, Unix,{$ENDIF}
  fafafa.core.atomic,
  fafafa.core.sync.mutex.parkinglot.base;

type
  {**
   * TParkingLotMutex - Unix 平台的 Parking Lot 互斥锁实现
   *
   * @desc
   *   使用各种 Unix 系统的高效同步原语实现线程等待和唤醒机制。
   *   自动检测并使用最适合的系统调用。
   *
   * @features
   *   - Linux: 使用 futex 系统调用实现真正的用户态锁
   *   - FreeBSD/OpenBSD/NetBSD/DragonFly: 支持 futex 或兼容层
   *   - macOS: 可尝试使用 ulock 系统调用
   *   - 其他 Unix: 使用 sched_yield + nanosleep 的智能退避策略
   *   - 运行时检测系统能力并选择最优实现
   *
   * @performance
   *   在支持高效同步原语的系统上性能接近内核级别，
   *   在其他系统上通过智能退避策略最小化性能损失。
   *}
  TParkingLotMutex = class(TParkingLotMutexBase)
  protected
    function ParkThread(ATimeoutMs: Cardinal = INFINITE): Boolean; override;
    function  UnparkOneThread: Boolean; override;
  end;

function MakeParkingLotMutex: IParkingLotMutex;

implementation

uses
  syscall;

// 时间相关常量和函数
const
  CLOCK_MONOTONIC = 1;

function clock_gettime(clk_id: cint; tp: ptimespec): cint; cdecl; external 'c' name 'clock_gettime';

{$IF DEFINED(LINUX) OR DEFINED(FREEBSD) OR DEFINED(OPENBSD) OR DEFINED(NETBSD) OR DEFINED(DRAGONFLY)}
// futex 系统调用常量
// 支持的系统:
// - Linux: 原生 futex 支持 (2.6+)
// - FreeBSD: futex 兼容层 (12.0+)
// - OpenBSD: futex 系统调用 (6.2+)
// - NetBSD: futex 支持 (9.0+)
// - DragonFly BSD: futex 支持 (5.0+)
const
  FUTEX_WAIT = 0;
  FUTEX_WAKE = 1;
  FUTEX_PRIVATE_FLAG = 128;
{$ENDIF}

{$IFDEF DARWIN}
// macOS ulock 系统调用常量
// macOS 使用 ulock 而不是 futex
const
  UL_COMPARE_AND_WAIT = 1;
  UL_UNFAIR_LOCK = 2;
  ULF_WAKE_ALL = $00000100;
  ULF_NO_ERRNO = $01000000;
{$ENDIF}

type
  TTimeSpec = record
    tv_sec: clong;
    tv_nsec: clong;
  end;
  PTimeSpec = ^TTimeSpec;

{$IF DEFINED(LINUX) OR DEFINED(FREEBSD) OR DEFINED(OPENBSD) OR DEFINED(NETBSD) OR DEFINED(DRAGONFLY)}
// 使用 syscall 单元的 Do_SysCall 函数调用 futex
function futex_syscall(uaddr: PInt32; op: cint; val: cint; timeout: PTimeSpec;
  uaddr2: Pointer; val3: cint): cint; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
begin
  Result := Do_SysCall(syscall_nr_futex, TSysParam(uaddr), TSysParam(op),
    TSysParam(val), TSysParam(timeout), TSysParam(uaddr2), TSysParam(val3));
end;
{$ENDIF}

{$IFDEF DARWIN}
// macOS ulock 系统调用封装
function ulock_wait(operation: cuint32; addr: Pointer; value: cuint64; timeout: cuint32): cint; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
begin
  // macOS 的 ulock_wait 系统调用
  // 注意：这需要 macOS 10.12+ 支持
  Result := Do_SysCall(515, TSysParam(operation), TSysParam(addr),
      TSysParam(value), TSysParam(timeout));
end;

function ulock_wake(operation: cuint32; addr: Pointer; wake_value: cuint64): cint;
  {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
begin
  // macOS 的 ulock_wake 系统调用
  Result := Do_SysCall(516, TSysParam(operation), TSysParam(addr),
      TSysParam(wake_value));
end;
{$ENDIF}

var
  // 全局同步原语支持状态
  GHasFutex:    Boolean = False;
  GHasUlock:    Boolean = False;
  GInitialized: Boolean = False;

// futex 初始化函数
procedure InitializeFutex;
{$IF DEFINED(LINUX) OR DEFINED(FREEBSD) OR DEFINED(OPENBSD) OR DEFINED(NETBSD) OR DEFINED(DRAGONFLY)}
var
  LTestAddr: Int32;
  LTestResult: cint;
{$ENDIF}
begin
  {$IF DEFINED(LINUX) OR DEFINED(FREEBSD) OR DEFINED(OPENBSD) OR DEFINED(NETBSD) OR DEFINED(DRAGONFLY)}
  // 通过实际调用测试 futex 支持
  LTestAddr := 0;
  LTestResult := futex_syscall(@LTestAddr, FUTEX_WAKE, 1, nil, nil, 0);
  // 如果返回值不是 -1 或者 errno 不是 ENOSYS，说明支持 futex
  GHasFutex := (LTestResult >= 0) or (fpgeterrno <> ESysENOSYS);
  {$ELSE}
  GHasFutex := False;
  {$ENDIF}
end;

// ulock 初始化函数
procedure InitializeUlock;
{$IFDEF DARWIN}
var
  LTestAddr: Int32;
  LTestResult: cint;
{$ENDIF}
begin
  {$IFDEF DARWIN}
  // 测试 macOS ulock 支持
  // 使用一个安全的测试方式：尝试唤醒一个不存在的等待者
  LTestAddr := 0;
  LTestResult := ulock_wake(UL_COMPARE_AND_WAIT, @LTestAddr, 0);
  // 如果返回值不是 -1 或者 errno 不是 ENOSYS，说明支持 ulock
  // 注意：即使没有等待者，ulock_wake 也应该返回 0 而不是错误
  GHasUlock := (LTestResult >= 0) or (fpgeterrno <> ESysENOSYS);
  {$ELSE}
  GHasUlock := False;
  {$ENDIF}
end;

// 全局初始化函数
procedure InitializePlatform;
begin
  if GInitialized then
    Exit;

  // 初始化默认值
  GHasFutex := False;
  GHasUlock := False;

  // 分别初始化各个平台的同步原语
  InitializeFutex;
  InitializeUlock;

  GInitialized := True;
end;

function HasFutexSupport: Boolean; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
begin
  if not GInitialized then
    InitializePlatform;
  Result := GHasFutex;
end;

function HasUlockSupport: Boolean; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
begin
  if not GInitialized then
    InitializePlatform;
  Result := GHasUlock;
end;

// 获取当前时间（毫秒）
function GetCurrentTimeMs: QWord;
var
  LTimeSpec: TTimeSpec;
begin
  if clock_gettime(CLOCK_MONOTONIC, @LTimeSpec) = 0 then
    Result := QWord(LTimeSpec.tv_sec) * 1000 + QWord(LTimeSpec.tv_nsec) div 1000000
  else
    Result := 0;
end;

{**
 * PlatformWait - 跨平台的原子等待函数
 *
 * @param Addr 要监视的内存地址
 * @param ExpectedValue 期望的值
 * @param TimeoutMs 超时时间（毫秒）
 * @return 成功返回 True，超时或失败返回 False
 *
 * @desc
 *   根据平台能力自动选择最优的等待机制：
 *   - Linux/BSD: 使用 futex
 *   - macOS: 使用 ulock
 *   - 其他: 智能退避策略
 *}
function PlatformWait(Addr: PInt32; ExpectedValue: Int32; TimeoutMs: Cardinal): Boolean;
{$IF DEFINED(LINUX) OR DEFINED(FREEBSD) OR DEFINED(OPENBSD) OR DEFINED(NETBSD) OR DEFINED(DRAGONFLY)}
var
  LTimeSpec: TTimeSpec;
  LTimeSpecPtr: PTimeSpec;
  LRet: cint;
{$ENDIF}
{$IFDEF DARWIN}
var
  LRet: cint;
{$ENDIF}
var
  LBackoffCount: Integer;
  LStartTime: QWord;
begin
  if HasFutexSupport then
  begin
    {$IF DEFINED(LINUX) OR DEFINED(FREEBSD) OR DEFINED(OPENBSD) OR DEFINED(NETBSD) OR DEFINED(DRAGONFLY)}
    // 使用 futex 等待
    if TimeoutMs = INFINITE then
      LTimeSpecPtr := nil
    else
    begin
      LTimeSpec.tv_sec := TimeoutMs div 1000;
      LTimeSpec.tv_nsec := (TimeoutMs mod 1000) * 1000000;
      LTimeSpecPtr := @LTimeSpec;
    end;

    LRet := futex_syscall(Addr, FUTEX_WAIT or FUTEX_PRIVATE_FLAG, ExpectedValue, LTimeSpecPtr, nil, 0);
    // futex_wait 返回 0 表示被唤醒，-1 表示错误或超时
    // EINTR 表示被信号中断，EAGAIN 表示值已改变，ETIMEDOUT 表示超时
    case LRet of
      0: Result := True;  // 被正常唤醒
      -1:
        case fpgeterrno of
          ESysEINTR: Result := True;   // 被信号中断，视为成功
          ESysEAGAIN: Result := True;  // 值已改变，视为成功
          ESysETIMEDOUT: Result := False; // 超时
          else Result := False;        // 其他错误
        end;
      else Result := False; // 意外的返回值
    end;
    {$ELSE}
    Result := False;
    {$ENDIF}
  end
  {$IFDEF DARWIN}
  else if HasUlockSupport then
  begin
    // 使用 macOS ulock 等待
    // 注意：ulock_wait 的 value 参数是 cuint64，需要转换
    if TimeoutMs = INFINITE then
      LRet := ulock_wait(UL_COMPARE_AND_WAIT, Addr, cuint64(ExpectedValue), 0)
    else
      LRet := ulock_wait(UL_COMPARE_AND_WAIT, Addr, cuint64(ExpectedValue), TimeoutMs * 1000); // 转换为微秒

    Result := (LRet = 0) or (fpgeterrno = ESysEINTR);
  end
  {$ENDIF}
  else
  begin
    // 回退到高级智能退避策略
    LBackoffCount := 0;
    LStartTime := GetCurrentTimeMs;
    var LSpinCount: Integer := 0;

    repeat
      // 检查值是否改变
      if atomic_load(Addr^, mo_relaxed) <> ExpectedValue then
        Exit(True);

      // 检查超时
      if (TimeoutMs <> INFINITE) and (GetCurrentTimeMs - LStartTime >= TimeoutMs) then
        Exit(False);

      // 多阶段高级退避策略
      case LBackoffCount of
        0..15:
          begin
            // 阶段1：CPU 暂停 + 紧密自旋
            // 使用指数退避的自旋次数
            for var i := 1 to (1 shl LBackoffCount) do
            begin
              {$IF DEFINED(CPUX86_64) OR DEFINED(CPUI386)}
              asm
                pause; // Intel PAUSE 指令
              end;
              {$ELSEIF DEFINED(CPUAARCH64)}
              asm
                yield; // ARM YIELD 指令
              end;
              {$ELSE}
              // 其他架构：简单的内存屏障
              ReadBarrier;
              {$ENDIF}

              // 每8次暂停后检查一次状态
              if (i and 7 = 0) and (atomic_load(Addr^, mo_relaxed) <> ExpectedValue) then
                Exit(True);
            end;
          end;
        16..31:
          begin
            // 阶段2：让出 CPU 给同优先级线程
            {$IFDEF UNIX}
            fpSched_yield;
            {$ELSE}
            Sleep(0);
            {$ENDIF}
          end;
        32..47:
          begin
            // 阶段3：微秒级睡眠，使用指数退避
            var LMicroSleep := 1 shl ((LBackoffCount - 32) div 4); // 1, 2, 4, 8 微秒
            {$IFDEF UNIX}
            var LSleepTime: TTimeSpec;
            begin
              LSleepTime.tv_sec := 0;
              LSleepTime.tv_nsec := LMicroSleep * 1000; // 转换为纳秒
              fpNanoSleep(@LSleepTime, nil);
            end;
            {$ELSE}
            if LMicroSleep >= 1000 then
              Sleep(LMicroSleep div 1000)
            else
              Sleep(0);
            {$ENDIF}
          end;
        48..63:
          begin
            // 阶段4：毫秒级睡眠，指数退避
            var LMilliSleep := 1 shl ((LBackoffCount - 48) div 4); // 1, 2, 4, 8ms
            {$IFDEF UNIX}
            var LSleepTime: TTimeSpec;
            begin
              LSleepTime.tv_sec := LMilliSleep div 1000;
              LSleepTime.tv_nsec := (LMilliSleep mod 1000) * 1000000;
              fpNanoSleep(@LSleepTime, nil);
            end;
            {$ELSE}
            Sleep(LMilliSleep);
            {$ENDIF}
          end;
        else
          begin
            // 阶段5：较长睡眠，但限制最大值
            var LMaxSleep := 16; // 最大16ms
            var LSleepTime: Integer := 1 shl ((LBackoffCount - 64) div 8);
            if LSleepTime > LMaxSleep then LSleepTime := LMaxSleep;
            {$IFDEF UNIX}
            var LTimeSpec: TTimeSpec;
            begin
              LTimeSpec.tv_sec := LSleepTime div 1000;
              LTimeSpec.tv_nsec := (LSleepTime mod 1000) * 1000000;
              fpNanoSleep(@LTimeSpec, nil);
            end;
            {$ELSE}
            Sleep(LSleepTime);
            {$ENDIF}
          end;
      end;

      Inc(LBackoffCount);
      // 防止计数器无限增长，重置到合理的阶段
      if LBackoffCount > 100 then
        LBackoffCount := 32; // 重置到阶段3

      // 安全检查：避免真正的无限循环
      if (TimeoutMs = INFINITE) and (GetCurrentTimeMs - LStartTime > 60000) then
      begin
        // 即使是无限等待，也在 60 秒后重新检查一次状态
        LStartTime := GetCurrentTimeMs;
        LBackoffCount := 0; // 重置退避计数器
      end;

    until False;
  end;
end;

{**
 * PlatformWake - 跨平台的原子唤醒函数
 *
 * @param Addr 要唤醒的内存地址
 * @return 成功返回 True，失败返回 False
 *
 * @desc
 *   根据平台能力自动选择最优的唤醒机制：
 *   - Linux/BSD: 使用 futex
 *   - macOS: 使用 ulock
 *   - 其他: 无操作（依赖轮询检测）
 *}
function PlatformWake(Addr: PInt32): Boolean;
{$IF DEFINED(LINUX) OR DEFINED(FREEBSD) OR DEFINED(OPENBSD) OR DEFINED(NETBSD) OR DEFINED(DRAGONFLY)}
var
  LRet: cint;
{$ENDIF}
{$IFDEF DARWIN}
var
  LRet: cint;
{$ENDIF}
begin
  if HasFutexSupport then
  begin
    {$IF DEFINED(LINUX) OR DEFINED(FREEBSD) OR DEFINED(OPENBSD) OR DEFINED(NETBSD) OR DEFINED(DRAGONFLY)}
    // 使用 futex 唤醒
    LRet := futex_syscall(Addr, FUTEX_WAKE or FUTEX_PRIVATE_FLAG, 1, nil, nil, 0);
    // futex_wake 返回被唤醒的线程数，-1 表示错误
    // 返回 0 表示没有线程在等待，这也是正常情况
    Result := LRet >= 0;
    {$ELSE}
    Result := False;
    {$ENDIF}
  end
  {$IFDEF DARWIN}
  else if HasUlockSupport then
  begin
    // 使用 macOS ulock 唤醒
    // UL_COMPARE_AND_WAIT 用于唤醒等待在 compare_and_wait 上的线程
    LRet := ulock_wake(UL_COMPARE_AND_WAIT or ULF_WAKE_ALL, Addr, 0);
    Result := LRet >= 0;
  end
  {$ENDIF}
  else
  begin
    // 回退策略：无法直接唤醒，依赖轮询检测
    Result := False;
  end;
end;

{ TParkingLotMutex }

function TParkingLotMutex.ParkThread(ATimeoutMs: Cardinal): Boolean;
var
  LExpectedState: Int32;
begin
  // 验证状态：确保我们应该等待
  LExpectedState := atomic_load(FState, mo_relaxed);
  if (LExpectedState and (LOCKED_BIT or PARKED_BIT)) <> (LOCKED_BIT or PARKED_BIT) then
    Exit(True); // 状态已改变，不需要等待

  // 使用全局的平台等待函数
  Result := PlatformWait(@FState, LExpectedState, ATimeoutMs);
end;

function TParkingLotMutex.UnparkOneThread: Boolean;
begin
  // 使用全局的平台唤醒函数
  Result := PlatformWake(@FState);
end;

function MakeParkingLotMutex: IParkingLotMutex;
begin
  Result := TParkingLotMutex.Create;
end;

initialization
  InitializePlatform;

end.
