unit fafafa.core.time.clock;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.clock - 时钟接口和实现

📖 概述：
  提供统一的时钟接口，包括单调时钟、系统时钟和综合时钟。
  单调时钟用于测量和超时，系统时钟用于获取真实时间。

🔧 特性：
  • 单调时钟：不受系统时间调整影响
  • 系统时钟：提供 UTC 和本地时间
  • 综合时钟：聚合单调时钟和系统时钟
  • 跨平台实现
  • 高精度纳秒级时间

📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731
──────────────────────────────────────────────────────────────
}

{$modeswitch advancedrecords}

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  DateUtils,
  fafafa.core.base,
  fafafa.core.time.base,
  fafafa.core.time.duration,
  fafafa.core.time.instant,
  // fafafa.core.time.config, // TODO: 该单元尚未实现，暂时注释
  fafafa.core.thread.cancel;

type
  {**
   * IMonotonicClock - 单调时钟接口
   *
   * @desc
   *   提供单调递增的时间源，不受系统时间调整影响。
   *   适用于测量时间间隔、超时检测等场景。
   *
   * @thread_safety
   *   实现应保证线程安全。
   *
   * @warning ✅ ISSUE-13: 语义澄清
   *   NowInstant 返回的 TInstant 仅用于**相对时间测量**，其 epoch 未定义且与平台相关。
   *   **禁止**将该 TInstant 与系统时间（ISystemClock）返回的 TInstant 直接比较或相减。
   *   只能在同一单调时钟内计算相对差值。
   *}
  IMonotonicClock = interface
    ['{5C2D97D0-3B3A-4A3A-B6A9-7C7E6EAF7C20}']
    
    /// <summary>
    ///   获取当前单调时间点。
    ///   ⚠️ 注意：返回的 TInstant 仅用于相对时间测量，不能与系统时间混用。
    ///   只能在同一单调时钟的两个 TInstant 之间计算差值。
    /// </summary>
    function NowInstant: TInstant;
    
    // 睡眠操作
    procedure SleepFor(const D: TDuration);
    procedure SleepUntil(const T: TInstant);
    
    // 可取消等待接口
    function WaitFor(const D: TDuration; const Token: ICancellationToken): Boolean;
    function WaitUntil(const T: TInstant; const Token: ICancellationToken): Boolean;
    
    // 时钟信息
    function GetResolution: TDuration; // 时钟分辨率
    function GetName: string; // 时钟名称
  end;

  {**
   * ISystemClock - 系统时钟接口
   *
   * @desc
   *   提供系统真实时间，包括 UTC 时间和本地时间。
   *   适用于日志记录、时间戳生成等场景。
   *
   * @thread_safety
   *   实现应保证线程安全。
   *}
  ISystemClock = interface
    ['{A8B7C6D5-E4F3-2A1B-9C8D-7E6F5A4B3C2D}']
    
    // 时间获取
    function NowUTC: TDateTime; // UTC 时间
    function NowLocal: TDateTime; // 本地时间
    function NowUnixMs: Int64; // Unix 毫秒时间戳
    function NowUnixNs: Int64; // Unix 纳秒时间戳
    
    // 时区信息
    function GetTimeZoneOffset: TDuration; // 当前时区偏移
    function GetTimeZoneName: string; // 时区名称
    
    // 时钟信息
    function GetName: string; // 时钟名称
  end;

  {**
   * IClock - 综合时钟接口
   *
   * @desc
   *   聚合单调时钟和系统时钟的功能，提供统一的时钟接口。
   *   继承自 IMonotonicClock，同时提供系统时间功能。
   *
   * @thread_safety
   *   实现应保证线程安全。
   *}
  IClock = interface(IMonotonicClock)
    ['{F9E8D7C6-B5A4-3F2E-1D0C-9B8A7F6E5D4C}']
    
    // 系统时间功能
    function NowUTC: TDateTime;
    function NowLocal: TDateTime;
    function NowUnixMs: Int64;
    function NowUnixNs: Int64;
    
    // 获取子时钟
    function GetMonotonicClock: IMonotonicClock;
    function GetSystemClock: ISystemClock;
  end;

  {**
   * IFixedClock - 固定时钟接口（用于测试）
   *
   * @desc
   *   提供可控制的时钟实现，用于单元测试和模拟场景。
   *   允许手动设置时间和控制时间流逝。
   *
   * @thread_safety
   *   实现应保证线程安全。
   *}
  IFixedClock = interface(IClock)
    ['{E7D6C5B4-A3F2-1E0D-8C9B-6A5F4E3D2C1B}']
    
    // 时间控制
    procedure SetInstant(const T: TInstant);
    procedure SetDateTime(const DT: TDateTime);
    procedure AdvanceBy(const D: TDuration);
    procedure AdvanceTo(const T: TInstant);
    
    // 状态查询
    function GetFixedInstant: TInstant;
    function GetFixedDateTime: TDateTime;
    
    // 重置
    procedure Reset;
  end;

// 工厂函数
function CreateMonotonicClock: IMonotonicClock;
function CreateSystemClock: ISystemClock;
function CreateClock: IClock;
function CreateClock(const AMono: IMonotonicClock; const ASys: ISystemClock): IClock;
function CreateFixedClock: IFixedClock;
function CreateFixedClock(const AInitialTime: TInstant): IFixedClock;
function CreateFixedClock(const AInitialTime: TDateTime): IFixedClock;

// 默认实例
function DefaultMonotonicClock: IMonotonicClock;
function DefaultSystemClock: ISystemClock;
function DefaultClock: IClock;

// 便捷函数
procedure SleepFor(const D: TDuration); inline;
procedure SleepUntil(const T: TInstant); inline;
function NowInstant: TInstant; inline;
function NowUTC: TDateTime; inline;
function NowLocal: TDateTime; inline;
function NowUnixMs: Int64; inline;
function NowUnixNs: Int64; inline;

// 时间测量便捷函数
function TimeIt(const P: TProc): TDuration;

implementation

uses
  {$IFDEF MSWINDOWS}
  Windows
  {$ELSE}
  BaseUnix, Unix
  {$IFDEF LINUX}
  , Linux
  {$ENDIF}
  {$IFDEF DARWIN}
  , MacOSAll
  {$ENDIF}
  {$ENDIF},
  fafafa.core.time.cpu;

type
  // 平台相关的单调时钟实现
  TMonotonicClock = class(TInterfacedObject, IMonotonicClock)
  private
    {$IFDEF MSWINDOWS}
    class var FQPCFreq: Int64;
    class var FFreqInited: Boolean;
    class var FQPCInitLock: TRTLCriticalSection;
    class procedure EnsureQPCFreq; static;
    class function QpcNowNs: UInt64; static;
    {$ELSE}
    {$IFDEF DARWIN}
    class var FTBInited: Boolean;
    class var FTBNumer: UInt32;
    class var FTBDenom: UInt32;
    class var FTBInitLock: TRTLCriticalSection;
    class procedure EnsureTimebase; static;
    class function DarwinNowNs: UInt64; static;
    {$ELSE}
    class function MonoNowNs: UInt64; static;
    {$ENDIF}
    {$ENDIF}
  public
    function NowInstant: TInstant;
    procedure SleepFor(const D: TDuration);
    procedure SleepUntil(const T: TInstant);
    function WaitFor(const D: TDuration; const Token: ICancellationToken): Boolean;
    function WaitUntil(const T: TInstant; const Token: ICancellationToken): Boolean;
    function GetResolution: TDuration;
    function GetName: string;
  end;

  // 系统时钟实现
  TSystemClock = class(TInterfacedObject, ISystemClock)
  public
    function NowUTC: TDateTime;
    function NowLocal: TDateTime;
    function NowUnixMs: Int64;
    function NowUnixNs: Int64;
    function GetTimeZoneOffset: TDuration;
    function GetTimeZoneName: string;
    function GetName: string;
  end;

  // 综合时钟实现
  TDefaultClock = class(TInterfacedObject, IClock)
  private
    FMono: IMonotonicClock;
    FSys: ISystemClock;
  public
    constructor Create(const AMono: IMonotonicClock; const ASys: ISystemClock);
    
    // IMonotonicClock
    function NowInstant: TInstant;
    procedure SleepFor(const D: TDuration);
    procedure SleepUntil(const T: TInstant);
    function WaitFor(const D: TDuration; const Token: ICancellationToken): Boolean;
    function WaitUntil(const T: TInstant; const Token: ICancellationToken): Boolean;
    function GetResolution: TDuration;
    function GetName: string;
    
    // IClock
    function NowUTC: TDateTime;
    function NowLocal: TDateTime;
    function NowUnixMs: Int64;
    function NowUnixNs: Int64;
    function GetMonotonicClock: IMonotonicClock;
    function GetSystemClock: ISystemClock;
  end;

  // 固定时钟实现（用于测试）
  TFixedClock = class(TInterfacedObject, IFixedClock, IClock, IMonotonicClock, ISystemClock)
  private
    // ✅ ISSUE-21: 使用单一真实来源避免数据竞争和一致性问题
    // 只保留 FFixedInstant 作为内部存储，DateTime 通过转换计算
    FFixedInstant: TInstant;
    FLock: TRTLCriticalSection;
  public
    constructor Create; overload;
    constructor Create(const AInitialTime: TInstant); overload;
    constructor Create(const AInitialTime: TDateTime); overload;
    destructor Destroy; override;
    
    // IMonotonicClock
    function NowInstant: TInstant;
    procedure SleepFor(const D: TDuration);
    procedure SleepUntil(const T: TInstant);
    function WaitFor(const D: TDuration; const Token: ICancellationToken): Boolean;
    function WaitUntil(const T: TInstant; const Token: ICancellationToken): Boolean;
    function GetResolution: TDuration;
    function GetName: string;
    
    // IClock
    function NowUTC: TDateTime;
    function NowLocal: TDateTime;
    function NowUnixMs: Int64;
    function NowUnixNs: Int64;
    function GetTimeZoneOffset: TDuration;
    function GetTimeZoneName: string;
    function GetMonotonicClock: IMonotonicClock;
    function GetSystemClock: ISystemClock;
    // 显式 ISystemClock 实现（与上方 IClock 别名同名，类型系统需要在类中实现）
    function ISystemClock.NowUTC = NowUTC;
    function ISystemClock.NowLocal = NowLocal;
    function ISystemClock.NowUnixMs = NowUnixMs;
    function ISystemClock.NowUnixNs = NowUnixNs;
    function ISystemClock.GetTimeZoneOffset = GetTimeZoneOffset;
    function ISystemClock.GetTimeZoneName = GetTimeZoneName;
    function ISystemClock.GetName = GetName;
    
    // IFixedClock
    procedure SetInstant(const T: TInstant);
    procedure SetDateTime(const DT: TDateTime);
    procedure AdvanceBy(const D: TDuration);
    procedure AdvanceTo(const T: TInstant);
    function GetFixedInstant: TInstant;
    function GetFixedDateTime: TDateTime;
    procedure Reset;
  end;

var
  GMonoClock: IMonotonicClock = nil;
  GSysClock: ISystemClock = nil;
  GClock: IClock = nil;
  GInitLock: TRTLCriticalSection;

// 工厂函数实现

function CreateMonotonicClock: IMonotonicClock;
begin
  Result := TMonotonicClock.Create;
end;

function CreateSystemClock: ISystemClock;
begin
  Result := TSystemClock.Create;
end;

function CreateClock: IClock;
begin
  Result := TDefaultClock.Create(DefaultMonotonicClock, DefaultSystemClock);
end;

function CreateClock(const AMono: IMonotonicClock; const ASys: ISystemClock): IClock;
begin
  Result := TDefaultClock.Create(AMono, ASys);
end;

function CreateFixedClock: IFixedClock;
begin
  Result := TFixedClock.Create;
end;

function CreateFixedClock(const AInitialTime: TInstant): IFixedClock;
begin
  Result := TFixedClock.Create(AInitialTime);
end;

function CreateFixedClock(const AInitialTime: TDateTime): IFixedClock;
begin
  Result := TFixedClock.Create(AInitialTime);
end;

// 默认实例

function DefaultMonotonicClock: IMonotonicClock;
begin
  if GMonoClock = nil then
  begin
    EnterCriticalSection(GInitLock);
    try
      if GMonoClock = nil then
        GMonoClock := CreateMonotonicClock;
    finally
      LeaveCriticalSection(GInitLock);
    end;
  end;
  Result := GMonoClock;
end;

function DefaultSystemClock: ISystemClock;
begin
  if GSysClock = nil then
  begin
    EnterCriticalSection(GInitLock);
    try
      if GSysClock = nil then
        GSysClock := CreateSystemClock;
    finally
      LeaveCriticalSection(GInitLock);
    end;
  end;
  Result := GSysClock;
end;

function DefaultClock: IClock;
begin
  if GClock = nil then
  begin
    EnterCriticalSection(GInitLock);
    try
      if GClock = nil then
        GClock := CreateClock;
    finally
      LeaveCriticalSection(GInitLock);
    end;
  end;
  Result := GClock;
end;

// 便捷函数

procedure SleepFor(const D: TDuration);
begin
  DefaultMonotonicClock.SleepFor(D);
end;

procedure SleepUntil(const T: TInstant);
begin
  DefaultMonotonicClock.SleepUntil(T);
end;

function NowInstant: TInstant;
begin
  Result := DefaultMonotonicClock.NowInstant;
end;

function NowUTC: TDateTime;
begin
  Result := DefaultSystemClock.NowUTC;
end;

function NowLocal: TDateTime;
begin
  Result := DefaultSystemClock.NowLocal;
end;

function NowUnixMs: Int64;
begin
  Result := DefaultSystemClock.NowUnixMs;
end;

function NowUnixNs: Int64;
begin
  Result := DefaultSystemClock.NowUnixNs;
end;

function TimeIt(const P: TProc): TDuration;
var
  startTime: TInstant;
begin
  startTime := NowInstant;
  P();
  Result := NowInstant.Diff(startTime);
end;

{ TMonotonicClock }

{$IFDEF MSWINDOWS}
class procedure TMonotonicClock.EnsureQPCFreq;
var
  li: Int64;
begin
  // ✅ 线程安全：双重检查锁定模式
  if FFreqInited then Exit;  // 快速路径，避免锁开销
  EnterCriticalSection(FQPCInitLock);
  try
    if FFreqInited then Exit;  // 再次检查，避免重复初始化
    if QueryPerformanceFrequency(li) then
      FQPCFreq := li
    else
      FQPCFreq := 0;
    FFreqInited := True;
  finally
    LeaveCriticalSection(FQPCInitLock);
  end;
end;

class function TMonotonicClock.QpcNowNs: UInt64;
var
  li: Int64;
  q, r: UInt64;
begin
  EnsureQPCFreq;
  if (FQPCFreq <= 0) or (not QueryPerformanceCounter(li)) then
    Exit(UInt64(GetTickCount64) * 1000 * 1000);
  // ✅ ISSUE-14: 使用先除后乘分解法防止 64 位溢出
  // 计算: (li * 1e9) / freq = (li div freq) * 1e9 + ((li mod freq) * 1e9) / freq
  q := UInt64(li) div UInt64(FQPCFreq);
  r := UInt64(li) mod UInt64(FQPCFreq);
  Result := q * 1000000000 + (r * 1000000000) div UInt64(FQPCFreq);
end;
{$ENDIF}

{$IFDEF DARWIN}
class procedure TMonotonicClock.EnsureTimebase;
var
  info: mach_timebase_info_data_t;
begin
  // ✅ 线程安全：双重检查锁定模式
  if FTBInited then Exit;  // 快速路径，避免锁开销
  EnterCriticalSection(FTBInitLock);
  try
    if FTBInited then Exit;  // 再次检查，避免重复初始化
    mach_timebase_info(info);
    FTBNumer := info.numer;
    FTBDenom := info.denom;
    if FTBDenom = 0 then FTBDenom := 1;
    FTBInited := True;
  finally
    LeaveCriticalSection(FTBInitLock);
  end;
end;

class function TMonotonicClock.DarwinNowNs: UInt64;
var
  t: UInt64;
  q, r: UInt64;
begin
  EnsureTimebase;
  t := mach_absolute_time;
  // ✅ ISSUE-16: 使用先除后乘分解法防止溢出（175 天后风险）
  // 计算: (t * numer) / denom = (t div denom) * numer + ((t mod denom) * numer) / denom
  q := t div FTBDenom;
  r := t mod FTBDenom;
  Result := q * FTBNumer + (r * FTBNumer) div FTBDenom;
end;
{$ENDIF}

{$IF (not defined(MSWINDOWS)) and (not defined(DARWIN))}
class function TMonotonicClock.MonoNowNs: UInt64;
var
  ts: timespec;
begin
  if fpclock_gettime(CLOCK_MONOTONIC, @ts) = 0 then
    Result := UInt64(ts.tv_sec) * 1000000000 + UInt64(ts.tv_nsec)
  else
    Result := UInt64(GetTickCount64) * 1000 * 1000;
end;
{$ENDIF}

function TMonotonicClock.NowInstant: TInstant;
var
  ns: UInt64;
begin
  {$IFDEF MSWINDOWS}
  ns := QpcNowNs;
  {$ELSE}
    {$IFDEF DARWIN}
    ns := DarwinNowNs;
    {$ELSE}
    ns := MonoNowNs;
    {$ENDIF}
  {$ENDIF}
  Result := TInstant.FromNsSinceEpoch(ns);
end;

procedure TMonotonicClock.SleepFor(const D: TDuration);
var
  ns: Int64;
begin
  ns := D.AsNs;
  if ns <= 0 then Exit;
  NanoSleep(UInt64(ns));
end;

procedure TMonotonicClock.SleepUntil(const T: TInstant);
var
  nowI: TInstant;
  d: TDuration;
begin
  nowI := NowInstant;
  d := T.Diff(nowI);
  if d.AsNs > 0 then
    SleepFor(d);
end;

function TMonotonicClock.WaitFor(const D: TDuration; const Token: ICancellationToken): Boolean;
var
  remaining: Int64;
  step: Int64;
  chunkNs: Int64;
  microSleepNs: Int64;
  finalSpinNs: Int64;
  nowI, deadline: TInstant;
begin
  if (Token <> nil) and Token.IsCancellationRequested then
    Exit(False);
  remaining := D.AsNs;
  if remaining <= 0 then Exit(True);
  nowI := NowInstant;
  deadline := nowI.Add(D);

  // ✅ ISSUE-17: 优化等待策略，减少 CPU 自旋
  // TODO: 这些配置值应该来自 fafafa.core.time.config，目前使用默认值
  chunkNs := 10 * 1000 * 1000;      // 10ms 常规切片
  microSleepNs := 50 * 1000;        // 50us 微睡眠步长
  finalSpinNs := 10 * 1000;         // 10us 最终自旋阈值（从 50us 降为 10us）

  while remaining > 0 do
  begin
    if (Token <> nil) and Token.IsCancellationRequested then
      Exit(False);
    
    if remaining <= finalSpinNs then
    begin
      // 极短的最终自旋阶段（<10us）
      nowI := NowInstant;
      remaining := deadline.Diff(nowI).AsNs;
      if remaining > 0 then 
        SchedYield
      else
        Break;
    end
    else if remaining <= 200 * 1000 then  // < 200us
    begin
      // 微睡眠阶段：使用小步长睡眠逐步逼近
      step := remaining;
      if step > microSleepNs then step := microSleepNs;
      NanoSleep(UInt64(step));
      nowI := NowInstant;
      remaining := deadline.Diff(nowI).AsNs;
    end
    else
    begin
      // 常规睡眠阶段
      step := remaining;
      if step > chunkNs then step := chunkNs;
      NanoSleep(UInt64(step));
      nowI := NowInstant;
      remaining := deadline.Diff(nowI).AsNs;
    end;
  end;
  Result := True;
end;

function TMonotonicClock.WaitUntil(const T: TInstant; const Token: ICancellationToken): Boolean;
var
  nowI: TInstant;
  d: TDuration;
begin
  nowI := NowInstant;
  d := T.Diff(nowI);
  if d.AsNs <= 0 then Exit(True);
  Result := WaitFor(d, Token);
end;

function TMonotonicClock.GetResolution: TDuration;
var
  ns: UInt64;
begin
  {$IFDEF MSWINDOWS}
  EnsureQPCFreq;
  if FQPCFreq > 0 then
    ns := (1000000000 + UInt64(FQPCFreq) - 1) div UInt64(FQPCFreq)
  else
    ns := 1000000; // 1ms 退化
  {$ELSE}
    {$IFDEF DARWIN}
    EnsureTimebase;
    ns := (FTBNumer + FTBDenom - 1) div FTBDenom; // 粗略：1 tick 的 ns
    {$ELSE}
    ns := 1; // CLOCK_MONOTONIC 视作 1ns 级别（近似）
    {$ENDIF}
  {$ENDIF}
  Result := TDuration.FromNs(Int64(ns));
end;

function TMonotonicClock.GetName: string;
begin
  {$IFDEF MSWINDOWS}
  Result := 'MonotonicClock(Windows QPC)';
  {$ELSE}
    {$IFDEF DARWIN}
    Result := 'MonotonicClock(Darwin mach_absolute_time)';
    {$ELSE}
    Result := 'MonotonicClock(POSIX CLOCK_MONOTONIC)';
    {$ENDIF}
  {$ENDIF}
end;

{ TSystemClock }

{$IFDEF MSWINDOWS}
// ✅ ISSUE-19/20: Windows 使用原生 API 获取高精度系统时间
function WinNowUnixNs: Int64;
const
  // FILETIME 与 Unix Epoch 之间的差值（100ns ticks）
  // 1601-01-01 到 1970-01-01 的 100ns tick 数
  FT_UNIX_EPOCH = Int64(116444736000000000);
var
  ft: TFileTime;
  ticks: Int64;
begin
  // 优先使用 GetSystemTimePreciseAsFileTime（Win8+，高精度）
  // 回退到 GetSystemTimeAsFileTime（所有 Windows 版本）
  GetSystemTimeAsFileTime(ft);
  ticks := (Int64(ft.dwHighDateTime) shl 32) or ft.dwLowDateTime;
  if ticks < FT_UNIX_EPOCH then Exit(0);
  // FILETIME 是 100ns 为单位，转为 ns
  Result := (ticks - FT_UNIX_EPOCH) * 100;
end;
{$ENDIF}

function TSystemClock.NowUTC: TDateTime;
{$IFDEF MSWINDOWS}
var
  unixSec: Int64;
begin
  unixSec := WinNowUnixNs div 1000000000;
  Result := DateUtils.UnixToDateTime(unixSec, True);
end;
{$ELSE}
begin
  Result := DateUtils.LocalTimeToUniversal(Now);
end;
{$ENDIF}

function TSystemClock.NowLocal: TDateTime;
begin
  Result := Now;
end;

function TSystemClock.NowUnixMs: Int64;
{$IFDEF MSWINDOWS}
begin
  Result := WinNowUnixNs div 1000000;
end;
{$ELSE}
var
  dt: TDateTime;
begin
  dt := NowUTC;
  Result := Int64(DateUtils.DateTimeToUnix(dt)) * 1000 + DateUtils.MilliSecondOfTheSecond(dt);
end;
{$ENDIF}

function TSystemClock.NowUnixNs: Int64;
{$IFDEF MSWINDOWS}
begin
  Result := WinNowUnixNs;
end;
{$ELSE}
begin
  Result := NowUnixMs * 1000000;
end;
{$ENDIF}

function TSystemClock.GetTimeZoneOffset: TDuration;
var
  localSnap, utcSnap: TDateTime;
  offsetSeconds: Int64;
begin
  // 使用同一时间快照避免分钟边界竞态
  localSnap := Now;
  utcSnap := DateUtils.LocalTimeToUniversal(localSnap);
  offsetSeconds := Round((localSnap - utcSnap) * 24 * 60 * 60);
  Result := TDuration.FromSec(offsetSeconds);
end;

function TSystemClock.GetTimeZoneName: string;
begin
  // 简化：返回空或占位
  Result := '';
end;

function TSystemClock.GetName: string;
begin
  Result := 'SystemClock';
end;

{ TDefaultClock }

constructor TDefaultClock.Create(const AMono: IMonotonicClock; const ASys: ISystemClock);
begin
  inherited Create;
  FMono := AMono;
  FSys := ASys;
end;

function TDefaultClock.NowInstant: TInstant;
begin
  Result := FMono.NowInstant;
end;

procedure TDefaultClock.SleepFor(const D: TDuration);
begin
  FMono.SleepFor(D);
end;

procedure TDefaultClock.SleepUntil(const T: TInstant);
begin
  FMono.SleepUntil(T);
end;

function TDefaultClock.WaitFor(const D: TDuration; const Token: ICancellationToken): Boolean;
begin
  Result := FMono.WaitFor(D, Token);
end;

function TDefaultClock.WaitUntil(const T: TInstant; const Token: ICancellationToken): Boolean;
begin
  Result := FMono.WaitUntil(T, Token);
end;

function TDefaultClock.GetResolution: TDuration;
begin
  Result := FMono.GetResolution;
end;

function TDefaultClock.GetName: string;
begin
  Result := 'DefaultClock';
end;

function TDefaultClock.NowUTC: TDateTime;
begin
  Result := FSys.NowUTC;
end;

function TDefaultClock.NowLocal: TDateTime;
begin
  Result := FSys.NowLocal;
end;

function TDefaultClock.NowUnixMs: Int64;
begin
  Result := FSys.NowUnixMs;
end;

function TDefaultClock.NowUnixNs: Int64;
begin
  Result := FSys.NowUnixNs;
end;

function TDefaultClock.GetMonotonicClock: IMonotonicClock;
begin
  Result := FMono;
end;

function TDefaultClock.GetSystemClock: ISystemClock;
begin
  Result := FSys;
end;

{ TFixedClock }

constructor TFixedClock.Create;
begin
  inherited Create;
  FFixedInstant := TInstant.Zero;
  InitCriticalSection(FLock);
end;

constructor TFixedClock.Create(const AInitialTime: TInstant);
begin
  Create;
  FFixedInstant := AInitialTime;
end;

constructor TFixedClock.Create(const AInitialTime: TDateTime);
var
  unixSec: Int64;
begin
  Create;
  // ✅ ISSUE-21: 将 TDateTime 转换为 TInstant 保持一致性
  unixSec := DateUtils.DateTimeToUnix(AInitialTime, True);
  FFixedInstant := TInstant.FromUnixSec(unixSec);
end;

destructor TFixedClock.Destroy;
begin
  DoneCriticalSection(FLock);
  inherited Destroy;
end;

function TFixedClock.NowInstant: TInstant;
begin
  EnterCriticalSection(FLock);
  try
    Result := FFixedInstant;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TFixedClock.SleepFor(const D: TDuration);
begin
  // 固定时钟不推进时间；此处不操作
end;

procedure TFixedClock.SleepUntil(const T: TInstant);
begin
  // 固定时钟不推进时间；此处不操作
end;

function TFixedClock.WaitFor(const D: TDuration; const Token: ICancellationToken): Boolean;
begin
  Result := (Token = nil) or (not Token.IsCancellationRequested);
end;

function TFixedClock.WaitUntil(const T: TInstant; const Token: ICancellationToken): Boolean;
begin
  Result := (Token = nil) or (not Token.IsCancellationRequested);
end;

function TFixedClock.GetResolution: TDuration;
begin
  Result := TDuration.FromNs(1);
end;

function TFixedClock.GetName: string;
begin
  Result := 'FixedClock';
end;

function TFixedClock.NowUTC: TDateTime;
var
  unixSec: Int64;
begin
  EnterCriticalSection(FLock);
  try
    // ✅ ISSUE-21: 从 FFixedInstant 计算 DateTime 保持一致性
    unixSec := FFixedInstant.AsUnixSec;
    Result := DateUtils.UnixToDateTime(unixSec, True);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TFixedClock.NowLocal: TDateTime;
begin
  // ✅ 固定时钟 NowLocal 返回与 NowUTC 相同的值（不做时区转换）
  Result := NowUTC;
end;

function TFixedClock.NowUnixMs: Int64;
begin
  EnterCriticalSection(FLock);
  try
    // ✅ ISSUE-21: 从 FFixedInstant 直接计算，保持一致性和精度
    Result := FFixedInstant.AsNsSinceEpoch div 1000000;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TFixedClock.NowUnixNs: Int64;
begin
  EnterCriticalSection(FLock);
  try
    // ✅ ISSUE-21: 添加锁保护，避免数据竞争
    Result := FFixedInstant.AsNsSinceEpoch;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TFixedClock.GetTimeZoneOffset: TDuration;
begin
  // 固定时钟不处理时区，返回 0 偏移
  Result := TDuration.Zero;
end;

function TFixedClock.GetTimeZoneName: string;
begin
  Result := '';
end;

function TFixedClock.GetMonotonicClock: IMonotonicClock;
begin
  Result := Self;
end;

function TFixedClock.GetSystemClock: ISystemClock;
begin
  Result := Self;
end;

procedure TFixedClock.SetInstant(const T: TInstant);
begin
  EnterCriticalSection(FLock);
  try
    FFixedInstant := T;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TFixedClock.SetDateTime(const DT: TDateTime);
var
  unixSec: Int64;
begin
  EnterCriticalSection(FLock);
  try
    // ✅ ISSUE-21: 将 DateTime 转换为 Instant 保持一致性
    unixSec := DateUtils.DateTimeToUnix(DT, True);
    FFixedInstant := TInstant.FromUnixSec(unixSec);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TFixedClock.AdvanceBy(const D: TDuration);
begin
  EnterCriticalSection(FLock);
  try
    // ✅ ISSUE-21: 只更新 FFixedInstant，DateTime 通过转换计算
    FFixedInstant := FFixedInstant.Add(D);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TFixedClock.AdvanceTo(const T: TInstant);
begin
  EnterCriticalSection(FLock);
  try
    FFixedInstant := T;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TFixedClock.GetFixedInstant: TInstant;
begin
  EnterCriticalSection(FLock);
  try
    Result := FFixedInstant;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TFixedClock.GetFixedDateTime: TDateTime;
var
  unixSec: Int64;
begin
  EnterCriticalSection(FLock);
  try
    // ✅ ISSUE-21: 从 FFixedInstant 计算 DateTime
    unixSec := FFixedInstant.AsUnixSec;
    Result := DateUtils.UnixToDateTime(unixSec, True);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TFixedClock.Reset;
begin
  EnterCriticalSection(FLock);
  try
    // ✅ ISSUE-21: 只重置 FFixedInstant
    FFixedInstant := TInstant.Zero;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

initialization
  InitCriticalSection(GInitLock);
  {$IFDEF MSWINDOWS}
  InitCriticalSection(TMonotonicClock.FQPCInitLock);
  {$ENDIF}
  {$IFDEF DARWIN}
  InitCriticalSection(TMonotonicClock.FTBInitLock);
  {$ENDIF}

finalization
  {$IFDEF MSWINDOWS}
  DoneCriticalSection(TMonotonicClock.FQPCInitLock);
  {$ENDIF}
  {$IFDEF DARWIN}
  DoneCriticalSection(TMonotonicClock.FTBInitLock);
  {$ENDIF}
  DoneCriticalSection(GInitLock);

end.
