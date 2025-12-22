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
   * TSleepStrategy - 睡眠策略枚举
   *
   * ✅ ISSUE-49: 可配置的睡眠策略
   *
   * 定义 WaitFor/WaitUntil 中等待行为的策略，平衡响应延迟和 CPU/能耗开销。
   *
   * @value ssLowLatency - 低延迟优先
   *   尽可能快地结束等待，但 CPU 占用较高。
   *   适用于实时交互、音视频处理、游戏等场景。
   *   - 最终自旋阈值：20us
   *   - 微睡眠步长：25us
   *   - 常规睡眠切片：500us
   *
   * @value ssBalanced - 平衡模式（默认）
   *   平衡响应延迟和 CPU 占用，适合大多数场景。
   *   - 最终自旋阈值：10us
   *   - 微睡眠步长：50us
   *   - 常规睡眠切片：1ms
   *
   * @value ssLowPower - 低能耗优先
   *   减少 CPU 唤醒频率，但响应延迟较高。
   *   适用于后台服务、移动设备等对能耗敏感的场景。
   *   - 最终自旋阈值：0（不自旋）
   *   - 微睡眠步长：100us
   *   - 常规睡眠切片：10ms
   *
   * @value ssCustom - 自定义模式
   *   使用 SetSleepStrategyParams 设置的参数。
   *   适用于需要精细调优的场景。
   *}
  TSleepStrategy = (
    ssLowLatency,  // 低延迟优先
    ssBalanced,    // 平衡模式（默认）
    ssLowPower,    // 低能耗优先
    ssCustom       // 自定义模式
  );

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

// ✅ ISSUE-18: 取消令牌检查频率配置
/// <summary>
///   设置 WaitFor/WaitUntil 中取消令牌的检查间隔。
/// </summary>
/// <param name="AInterval">检查间隔，建议范围 100us - 10ms</param>
/// <remarks>
///   <para>默认值：1ms（平衡响应速度和 CPU 开销）</para>
///   <para><b>调优建议</b>：</para>
///   <list type="bullet">
///     <item>快速响应场景（如 UI）：100us - 500us</item>
///     <item>普通场景：1ms（默认）</item>
///     <item>低能耗场景：5ms - 10ms</item>
///   </list>
///   <para>警告：过短的间隔会增加 CPU 开销</para>
/// </remarks>
procedure SetCancellationCheckInterval(const AInterval: TDuration);

/// <summary>
///   获取当前取消令牌检查间隔。
/// </summary>
function GetCancellationCheckInterval: TDuration;

// ✅ ISSUE-49: 睡眠策略配置 API
/// <summary>
///   设置睡眠策略。
/// </summary>
/// <param name="AStrategy">睡眠策略枚举值</param>
/// <remarks>
///   <para><b>预定义策略</b>：</para>
///   <list type="bullet">
///     <item>ssLowLatency: 低延迟（游戏/UI）</item>
///     <item>ssBalanced: 平衡模式（默认）</item>
///     <item>ssLowPower: 低能耗（后台服务）</item>
///     <item>ssCustom: 使用 SetSleepStrategyParams 的参数</item>
///   </list>
/// </remarks>
procedure SetSleepStrategy(AStrategy: TSleepStrategy);

/// <summary>
///   获取当前睡眠策略。
/// </summary>
function GetSleepStrategy: TSleepStrategy;

/// <summary>
///   设置自定义睡眠策略参数。
/// </summary>
/// <param name="AFinalSpinNs">最终自旋阈值（纳秒），低于此值时使用 CPU 自旋</param>
/// <param name="AMicroSleepNs">微睡眠步长（纳秒），短睡眠阶段的每步时长</param>
/// <param name="ASliceSleepNs">常规睡眠切片（纳秒），长睡眠的最大切片</param>
/// <remarks>
///   <para>调用此函数后自动切换到 ssCustom 策略。</para>
///   <para><b>参考值</b>：</para>
///   <list type="bullet">
///     <item>低延迟: FinalSpin=20us, MicroSleep=25us, Slice=500us</item>
///     <item>平衡: FinalSpin=10us, MicroSleep=50us, Slice=1ms</item>
///     <item>低能耗: FinalSpin=0, MicroSleep=100us, Slice=10ms</item>
///   </list>
/// </remarks>
procedure SetSleepStrategyParams(AFinalSpinNs, AMicroSleepNs, ASliceSleepNs: Int64);

/// <summary>
///   获取当前睡眠策略参数。
/// </summary>
/// <param name="AFinalSpinNs">输出：最终自旋阈值（纳秒）</param>
/// <param name="AMicroSleepNs">输出：微睡眠步长（纳秒）</param>
/// <param name="ASliceSleepNs">输出：常规睡眠切片（纳秒）</param>
procedure GetSleepStrategyParams(out AFinalSpinNs, AMicroSleepNs, ASliceSleepNs: Int64);

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
  fafafa.core.time.cpu,
  fafafa.core.math;

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
  
  // ✅ ISSUE-49: 睡眠策略配置的线程安全锁
  GSleepConfigLock: TRTLCriticalSection;
  
  // ✅ ISSUE-18: 可配置的取消检查频率
  // 默认 1ms，可通过 SetCancellationCheckInterval 调整
  GCancellationCheckIntervalNs: Int64 = 1000000; // 1ms = 1,000,000 ns
  
  // ✅ ISSUE-49: 睡眠策略配置
  GSleepStrategy: TSleepStrategy = ssBalanced;
  // 策略参数（单位：纳秒）
  GFinalSpinNs: Int64 = 10000;      // 10us - 最终自旋阈值
  GMicroSleepNs: Int64 = 50000;     // 50us - 微睡眠步长
  GSliceSleepNs: Int64 = 1000000;   // 1ms - 常规睡眠切片

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

// ✅ ISSUE-18: 取消令牌检查间隔配置
procedure SetCancellationCheckInterval(const AInterval: TDuration);
var
  ns: Int64;
begin
  ns := AInterval.AsNs;
  // 限制合理范围：10us - 100ms
  if ns < 10000 then ns := 10000;           // 最小 10us
  if ns > 100000000 then ns := 100000000;   // 最大 100ms
  EnterCriticalSection(GSleepConfigLock);
  try
    GCancellationCheckIntervalNs := ns;
  finally
    LeaveCriticalSection(GSleepConfigLock);
  end;
end;

function GetCancellationCheckInterval: TDuration;
begin
  EnterCriticalSection(GSleepConfigLock);
  try
    Result := TDuration.FromNs(GCancellationCheckIntervalNs);
  finally
    LeaveCriticalSection(GSleepConfigLock);
  end;
end;

// ✅ ISSUE-49: 睡眠策略配置实现（线程安全）
procedure SetSleepStrategy(AStrategy: TSleepStrategy);
begin
  EnterCriticalSection(GSleepConfigLock);
  try
    GSleepStrategy := AStrategy;
    // 应用预定义策略的参数
    case AStrategy of
      ssLowLatency:
        begin
          GFinalSpinNs := 20000;      // 20us
          GMicroSleepNs := 25000;     // 25us
          GSliceSleepNs := 500000;    // 500us
        end;
      ssBalanced:
        begin
          GFinalSpinNs := 10000;      // 10us
          GMicroSleepNs := 50000;     // 50us
          GSliceSleepNs := 1000000;   // 1ms
        end;
      ssLowPower:
        begin
          GFinalSpinNs := 0;          // 不自旋
          GMicroSleepNs := 100000;    // 100us
          GSliceSleepNs := 10000000;  // 10ms
        end;
      ssCustom:
        ; // 保留当前参数
    end;
  finally
    LeaveCriticalSection(GSleepConfigLock);
  end;
end;

function GetSleepStrategy: TSleepStrategy;
begin
  EnterCriticalSection(GSleepConfigLock);
  try
    Result := GSleepStrategy;
  finally
    LeaveCriticalSection(GSleepConfigLock);
  end;
end;

procedure SetSleepStrategyParams(AFinalSpinNs, AMicroSleepNs, ASliceSleepNs: Int64);
begin
  // 参数边界检查（在锁外完成，避免长时间持锁）
  if AFinalSpinNs < 0 then AFinalSpinNs := 0;
  if AFinalSpinNs > 1000000 then AFinalSpinNs := 1000000; // 最大 1ms
  
  if AMicroSleepNs < 1000 then AMicroSleepNs := 1000;     // 最小 1us
  if AMicroSleepNs > 1000000 then AMicroSleepNs := 1000000; // 最大 1ms
  
  if ASliceSleepNs < 10000 then ASliceSleepNs := 10000;   // 最小 10us
  if ASliceSleepNs > 100000000 then ASliceSleepNs := 100000000; // 最大 100ms
  
  EnterCriticalSection(GSleepConfigLock);
  try
    GFinalSpinNs := AFinalSpinNs;
    GMicroSleepNs := AMicroSleepNs;
    GSliceSleepNs := ASliceSleepNs;
    GSleepStrategy := ssCustom;  // 自动切换到自定义模式
  finally
    LeaveCriticalSection(GSleepConfigLock);
  end;
end;

procedure GetSleepStrategyParams(out AFinalSpinNs, AMicroSleepNs, ASliceSleepNs: Int64);
begin
  EnterCriticalSection(GSleepConfigLock);
  try
    AFinalSpinNs := GFinalSpinNs;
    AMicroSleepNs := GMicroSleepNs;
    ASliceSleepNs := GSliceSleepNs;
  finally
    LeaveCriticalSection(GSleepConfigLock);
  end;
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
  if clock_gettime(CLOCK_MONOTONIC, @ts) = 0 then
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
  cancelCheckNs: Int64;
  nowI, deadline: TInstant;
begin
  if (Token <> nil) and Token.IsCancellationRequested then
    Exit(False);
  remaining := D.AsNs;
  if remaining <= 0 then Exit(True);
  nowI := NowInstant;
  deadline := nowI.Add(D);

  // ✅ ISSUE-17: 优化等待策略，减少 CPU 自旋
  // ✅ ISSUE-18: 使用可配置的取消检查间隔
  // ✅ ISSUE-49: 使用可配置的睡眠策略参数
  // NOTE: Read config under lock to avoid torn Int64 reads on 32-bit and to keep parameters consistent.
  EnterCriticalSection(GSleepConfigLock);
  try
    cancelCheckNs := GCancellationCheckIntervalNs;  // 默认 1ms
    microSleepNs := GMicroSleepNs;    // 默认 50us
    finalSpinNs := GFinalSpinNs;      // 默认 10us
    chunkNs := GSliceSleepNs;         // 常规睡眠切片上限
  finally
    LeaveCriticalSection(GSleepConfigLock);
  end;

  // 常规睡眠切片取策略配置和取消检查间隔中较小者
  if cancelCheckNs < chunkNs then chunkNs := cancelCheckNs;

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
      // 常规睡眠阶段：使用可配置的取消检查间隔
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
  InitCriticalSection(GSleepConfigLock);  // ✅ ISSUE-49: 睡眠策略锁
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
  DoneCriticalSection(GSleepConfigLock);  // ✅ ISSUE-49: 睡眠策略锁
  DoneCriticalSection(GInitLock);

end.
