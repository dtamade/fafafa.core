unit fafafa.core.time;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, DateUtils, fafafa.core.thread.cancel, fafafa.core.time.consts, fafafa.core.sync;


type
  // 持续时间（允许负值，以表达“已过期/剩余为负”）
  TDuration = record
  private
    FNs: Int64; // 纳秒
  public
    class function FromNs(const A: Int64): TDuration; static;
    class function FromUs(const A: Int64): TDuration; static;
    class function FromMs(const A: Int64): TDuration; static;
    class function FromSec(const A: Int64): TDuration; static;

    // 扩展：绝对值/取反与安全构造
    function Abs: TDuration; inline;
    function Neg: TDuration; inline;
    class function TryFromNs(const A: Int64; out D: TDuration): Boolean; static;
    class function TryFromUs(const A: Int64; out D: TDuration): Boolean; static;
    class function TryFromMs(const A: Int64; out D: TDuration): Boolean; static;
    class function TryFromSec(const A: Int64; out D: TDuration): Boolean; static;

    function AsNs: Int64; inline;
    function AsUs: Int64; inline;
    function AsMs: Int64; inline;
    function AsSec: Int64; inline;

    function Add(const B: TDuration): TDuration; inline;
    function Sub(const B: TDuration): TDuration; inline;
    function Mul(const K: Int64): TDuration; inline;
    function Divi(const K: Int64): TDuration; inline;
    function DivBy(const K: Int64): TDuration; inline;

    function Modulo(const B: TDuration): TDuration; inline;

    function IsZero: Boolean; inline;
    function IsNegative: Boolean; inline;
    class function Zero: TDuration; static; inline;

    // Clamp 到 [Min, Max]
    function Clamp(const MinV, MaxV: TDuration): TDuration; inline;


    // 标量和取整/夹取工具
    function Between(const MinV, MaxV: TDuration): TDuration; inline;
    function RoundToUnit(const UnitNs: Int64): TDuration; inline;
    function TruncToUnit(const UnitNs: Int64): TDuration; inline;
    function FloorToUnit(const UnitNs: Int64): TDuration; inline;
    function CeilToUnit(const UnitNs: Int64): TDuration; inline;
    // 便捷：按常用单位
    function RoundToUs: TDuration; inline;
    function RoundToMs: TDuration; inline;
    function RoundToSec: TDuration; inline;
    function TruncToUs: TDuration; inline;
    function TruncToMs: TDuration; inline;
    function TruncToSec: TDuration; inline;
    function FloorToUs: TDuration; inline;
    function FloorToMs: TDuration; inline;
    function FloorToSec: TDuration; inline;
    function CeilToUs: TDuration; inline;
    function CeilToMs: TDuration; inline;
    function CeilToSec: TDuration; inline;


    // 运算符重载（算术）
    class operator +(const A, B: TDuration) res: TDuration; inline;
    class operator -(const A, B: TDuration) res: TDuration; inline;
    class operator *(const A: TDuration; const K: Int64) res: TDuration; inline;
    class operator *(const K: Int64; const A: TDuration) res: TDuration; inline;

    // 比较与工具
    function Compare(const B: TDuration): Integer; inline; // -1/0/1
    function LessThan(const B: TDuration): Boolean; inline;
    function GreaterThan(const B: TDuration): Boolean; inline;
    class function Min(const A, B: TDuration): TDuration; static; inline;
    class function Max(const A, B: TDuration): TDuration; static; inline;

    // 饱和算术
    // 安全算术
    function CheckedMul(const K: Int64; out R: TDuration): Boolean; inline;
    function CheckedDivBy(const K: Int64; out R: TDuration): Boolean;


    // 夹取工具（应属于 TInstant，不在 TDuration 中声明）

    function CheckedDiv(const K: Int64; out R: TDuration): Boolean;
    function CheckedModulo(const B: TDuration; out R: TDuration): Boolean; inline;

    // 饱和算术
    function SaturatingMul(const K: Int64): TDuration;
    function SaturatingDiv(const K: Int64): TDuration;

    function SaturatingAdd(const B: TDuration): TDuration; inline;

    // 运算符重载（比较）
    class operator =(const A, B: TDuration) res: Boolean;
    class operator <>(const A, B: TDuration) res: Boolean;
    class operator <(const A, B: TDuration) res: Boolean;
    class operator >(const A, B: TDuration) res: Boolean;
    class operator <=(const A, B: TDuration) res: Boolean;
    class operator >=(const A, B: TDuration) res: Boolean;

    function SaturatingSub(const B: TDuration): TDuration; inline;
  end;

  // 单调时钟时间点（以纳秒为单位，自某个不变基准起点）
  TInstant = record
  private
    FNsSinceEpoch: UInt64; // 单调时钟的纳秒
  public
    class function FromNsSinceEpoch(const A: UInt64): TInstant; static;
    function AsNsSinceEpoch: UInt64; inline;

    function Add(const D: TDuration): TInstant; inline;
    function Diff(const Older: TInstant): TDuration; inline; // self - Older
    function Since(const Older: TInstant): TDuration; inline; // 别名
    function NonNegativeDiff(const Older: TInstant): TDuration; inline; // max(Diff,0)
    function HasPassed(const NowI: TInstant): Boolean; inline; // self <= NowI

    // 安全算术
    function IsBefore(const Other: TInstant): Boolean; inline;
    function IsAfter(const Other: TInstant): Boolean; inline;

    function CheckedAdd(const D: TDuration; out R: TInstant): Boolean; inline;
    function CheckedSub(const D: TDuration; out R: TInstant): Boolean; inline;

    // 夹取工具
    function Clamp(const MinV, MaxV: TInstant): TInstant; inline;
    function Between(const MinV, MaxV: TInstant): TInstant; inline;


    // 比较与工具
    function Compare(const B: TInstant): Integer; inline; // -1/0/1
    function LessThan(const B: TInstant): Boolean; inline;
    function GreaterThan(const B: TInstant): Boolean; inline;
    class function Min(const A, B: TInstant): TInstant; static; inline;
    class function Max(const A, B: TInstant): TInstant; static; inline;

    // 运算符重载（比较）
    class operator =(const A, B: TInstant) res: Boolean;
    class operator <>(const A, B: TInstant) res: Boolean;
    class operator <(const A, B: TInstant) res: Boolean;
    class operator >(const A, B: TInstant) res: Boolean;
    class operator <=(const A, B: TInstant) res: Boolean;
    class operator >=(const A, B: TInstant) res: Boolean;
  end;

  // 截止时间（基于单调时钟）
  TDeadline = record
  private
    FWhen: TInstant;
  public
    class function FromNow(const D: TDuration; const Clock: IInterface = nil): TDeadline; static; // 若 Clock=nil 使用默认
    class function FromNowMs(const Ms: Int64; const Clock: IInterface = nil): TDeadline; static; inline;
    class function FromNowSec(const Sec: Int64; const Clock: IInterface = nil): TDeadline; static; inline;
    class function FromInstant(const T: TInstant): TDeadline; static; inline;
    function When: TInstant; inline;
    function Remaining(const NowI: TInstant): TDuration; inline;
    function RemainingClampedZero(const NowI: TInstant): TDuration; inline;
    function Expired(const NowI: TInstant): Boolean; inline;
    // 便捷别名/扩展
    function TimeUntil(const NowI: TInstant): TDuration; inline; // = Remaining
    function Overdue(const NowI: TInstant): TDuration; inline; // max(-Remaining, 0)
    function IsExpired(const NowI: TInstant): Boolean; inline; // = Expired

  end;

  // 时钟接口
  IMonotonicClock = interface
    ['{5C2D97D0-3B3A-4A3A-B6A9-7C7E6EAF7C20}']
    function NowInstant: TInstant;
    procedure SleepFor(const D: TDuration);
    procedure SleepUntil(const T: TInstant);
    // 统一的可取消等待接口（最佳实践）
    function WaitFor(const D: TDuration; const Token: ICancellationToken): Boolean;
    function WaitUntil(const T: TInstant; const Token: ICancellationToken): Boolean;
  end;

  ISystemClock = interface
    ['{B4C64E7A-4E3C-4D3F-8C32-9B9E7B1E8F11}']
    function NowUTC: TDateTime;  // 返回真实 UTC
    function NowLocal: TDateTime; // 本地墙钟时间
    function NowUnixMs: Int64;   // 自 1970-01-01T00:00:00Z 起的毫秒
    function NowUnixNs: Int64;   // 自 1970-01-01T00:00:00Z 起的纳秒（基于 TDateTime 精度推算）
  end;

  IClock = interface(IMonotonicClock)
    ['{E7FAD27F-046F-49A8-B7E5-0BCE1B0B9B22}']
    function NowUTC: TDateTime;
    function NowLocal: TDateTime;
  end;

  // 可控单调时钟（测试用）：手动推进时间，便于确定性测试
  TFixedMonotonicClock = class(TInterfacedObject, IMonotonicClock)
  private
    FNow: TInstant;
  public
    constructor Create(const StartAt: TInstant);
    procedure SetNow(const V: TInstant);
    function NowInstant: TInstant;
    procedure SleepFor(const D: TDuration);
    procedure SleepUntil(const T: TInstant);
    function WaitFor(const D: TDuration; const Token: ICancellationToken): Boolean;
    function WaitUntil(const T: TInstant; const Token: ICancellationToken): Boolean;
  end;

// 工厂与便捷函数
function DefaultMonotonicClock: IMonotonicClock;
function DefaultSystemClock: ISystemClock;
function DefaultClock: IClock;


  // 过程类型别名（用于回调）
  type TProc = procedure;

  // 解析/格式化
  function TryParseDuration(const S: string; out D: TDuration): Boolean;
  function ParseDuration(const S: string): TDuration;

  // 超时组合子（同步版）
  function TimeoutFor(const D: TDuration; P: TProc): Boolean;
  function TimeoutUntil(const DL: TInstant; P: TProc): Boolean;

  // 工厂：手动推进时钟（测试用）
  function CreateManualMonotonicClock(const StartAt: TInstant): IMonotonicClock;


// type
//  TProc = procedure;

// 运算符实现（接口区前声明，避免引用顺序问题）


procedure SleepFor(const D: TDuration);
procedure SleepUntil(const T: TInstant);
function NowInstant: TInstant;
function NowUTC: TDateTime;
function NowLocal: TDateTime;
function NowUnixMs: Int64;
function NowUnixNs: Int64;

function TimeIt(const P: TProc): TDuration;
function FormatDurationHuman(const D: TDuration): string;
// 轻量可配置项（保持默认行为不变）
procedure SetDurationFormatUseAbbr(AUseAbbr: Boolean);
function GetDurationFormatUseAbbr: Boolean;
procedure SetDurationFormatSecPrecision(APrecision: Integer);
function GetDurationFormatSecPrecision: Integer;

// 最佳实践：节能与可取消
procedure SleepUntilWithSlack(const T: TInstant; const Slack: TDuration);
function SleepForCancelable(const D: TDuration; const Token: ICancellationToken): Boolean;
function SleepUntilCancelable(const T: TInstant; const Token: ICancellationToken): Boolean;
  // 跨平台睡眠策略配置（Windows/Linux/macOS）
  type
    TSleepStrategy = (EnergySaving, Balanced, LowLatency, UltraLowLatency);
    TPlatformKind = (PlatWindows, PlatLinux, PlatDarwin);
  procedure SetSleepStrategy(AStrategy: TSleepStrategy);
  // SetFinalSpinThresholdNs: 设置所有平台的最终自旋阈值（纳秒）
  procedure SetFinalSpinThresholdNs(ANs: Int64);
  // SetFinalSpinThresholdNsFor: 针对特定平台设置阈值（纳秒）
  procedure SetFinalSpinThresholdNsFor(APlat: TPlatformKind; ANs: Int64);
  {$IFDEF MSWINDOWS}
  // 测试钩子：强制使用 GetTickCount64 退化路径或恢复 QPC 路径（仅测试）
  procedure Test_ForceUseGTC64_ForWindows(AForce: Boolean);
  // 测试钩子：查询 Windows 下 QPC 退化发生次数（仅测试）
  function Test_GetWindowsQpcFallbackCount: LongWord;
  {$ENDIF}
  {$IFDEF DARWIN}
  // 测试钩子：查询 macOS 时间基退化（numer/denom 不可用时退化为 1:1）状态（仅测试）
  function Test_DarwinTimebaseIsFallback: Boolean;
  {$ENDIF}


  // 兼容旧接口：SetLowLatencySleepEnabled(True)=LowLatency, False=EnergySaving
  procedure SetLowLatencySleepEnabled(AEnabled: Boolean);
  function GetSleepStrategy: TSleepStrategy;
  procedure SetSliceSleepMs(AMs: Integer);
  procedure SetSliceSleepMsFor(APlat: TPlatformKind; AMs: Integer);
  function GetSliceSleepMsFor(APlat: TPlatformKind): Integer;
  // 自旋让权节奏：每 N 次自旋尝试让权一次（0=不让权），仅 Balanced 使用
  procedure SetSpinYieldEvery(N: LongWord);
  procedure SetSpinYieldEveryFor(APlat: TPlatformKind; N: LongWord);
  function GetSpinYieldEveryFor(APlat: TPlatformKind): LongWord;




implementation

uses
  {$IFDEF MSWINDOWS}
  Windows
  {$ELSE}
  BaseUnix
    {$IFDEF LINUX}
    , Linux
    {$ENDIF}
    {$IFDEF DARWIN}
    , UnixType
    {$ENDIF}
  {$ENDIF}
  ;



function CreateManualMonotonicClock(const StartAt: TInstant): IMonotonicClock;
begin
  Result := TFixedMonotonicClock.Create(StartAt);
end;

function TryParseDuration(const S: string; out D: TDuration): Boolean;
var
  i, n: Integer;
  numPart, unitPart: string;
  sign: Integer;
  accum: Int64;
  curNum: Int64;
  hadAny: Boolean;
begin
  D := TDuration.Zero;
  if S = '' then Exit(False);
  i := 1; n := Length(S); sign := 1; accum := 0; hadAny := False;
  if (S[i] = '+') or (S[i] = '-') then
  begin
    if S[i] = '-' then sign := -1;
    Inc(i);
    if i > n then Exit(False);
  end;
  while i <= n do
  begin
    // 读取数字
    numPart := '';
    while (i <= n) and (S[i] in ['0'..'9']) do
    begin
      numPart += S[i]; Inc(i);
    end;
    if numPart = '' then Exit(False);
    if not TryStrToInt64(numPart, curNum) then Exit(False);
    // 读取单位（可为空：默认 ns）
    unitPart := '';
    while (i <= n) and (S[i] in ['a'..'z','A'..'Z']) do
    begin
      unitPart += LowerCase(S[i]); Inc(i);
    end;
    if (unitPart = '') then
      accum := accum + curNum // 视为 ns
    else if (unitPart = 'ns') then
      accum := accum + curNum
    else if (unitPart = 'us') or (unitPart = 'µs') then
      accum := accum + curNum * 1000
    else if (unitPart = 'ms') then
      accum := accum + curNum * 1000 * 1000
    else if (unitPart = 's') then
      accum := accum + curNum * 1000 * 1000 * 1000
    else if (unitPart = 'm') then
      accum := accum + curNum * 60 * 1000 * 1000 * 1000
    else if (unitPart = 'h') then
      accum := accum + curNum * 3600 * 1000 * 1000 * 1000
    else
      Exit(False);
    hadAny := True;
  end;
  if not hadAny then Exit(False);
  if sign = -1 then accum := -accum;
  D := TDuration.FromNs(accum);
  Result := True;
end;

function ParseDuration(const S: string): TDuration;
begin
  if not TryParseDuration(S, Result) then
    raise Exception.CreateFmt('Invalid duration: %s', [S]);
end;

function TimeoutFor(const D: TDuration; P: TProc): Boolean;
var
  done: IEvent;
  th: TThread;
begin
  Result := True;
  if not Assigned(P) then Exit(True);
  done := TEvent.Create(True, False);
  th := TThread.CreateAnonymousThread(
    procedure
    begin
      try P(); finally done.SetEvent; end;
    end
  );
  th.FreeOnTerminate := True;
  th.Start;
  // 使用可取消等待组合，避免繁忙等待
  Result := DefaultMonotonicClock.WaitFor(D, nil{no token});
  if not Result then Exit(False);
  // 若时间到，检查是否已完成；再做一次短等待以获取完成信号
  if done.WaitFor(0) = wrSignaled then Exit(True)
  else Exit(False);
end;

function TimeoutUntil(const DL: TInstant; P: TProc): Boolean;
begin
  Result := TimeoutFor(DL.Diff(DefaultMonotonicClock.NowInstant), P);
end;



var
  GDurationFmtUseAbbr: Boolean = True; // 默认使用缩写：ns/us/ms/s
  GDurationFmtSecPrecision: Integer = 0; // 秒的显示小数位（0 表示整数秒）

{$IFDEF DARWIN}
// macOS: 使用 mach_absolute_time 转纳秒
// 这里直接声明外部函数以避免额外依赖
Type
  mach_timebase_info_data_t = record
    numer: UInt32;
    denom: UInt32;
  end;

function mach_timebase_info(var info: mach_timebase_info_data_t): LongInt; cdecl; external name 'mach_timebase_info';
function mach_absolute_time: QWord; cdecl; external name 'mach_absolute_time';
function mach_wait_until(deadline: QWord): LongInt; cdecl; external name 'mach_wait_until';
{$ENDIF}



{$IFDEF CPUX86_64}
procedure CpuRelax; inline; assembler; nostackframe;
asm
  pause
end;
{$ELSE}
procedure CpuRelax; inline;
begin
  // no-op on non-x86
end;
{$ENDIF}

type
  // 单调时钟实现（平台相关）
  TMonotonicClock = class(TInterfacedObject, IMonotonicClock)
  private
    {$IFDEF MSWINDOWS}
    class var FQPCFreq: Int64;
    class var FFreqInited: Boolean;
    class var FUseGTC64: Boolean; // 初始化后固定：True=使用 GetTickCount64 退化路径
    class var FFallbackCount: LongWord; // 测试可见：记录退化发生次数
    class procedure EnsureQPCFreq; static;
    class function QpcNowNs: UInt64; static;
    {$ELSE}
    {$IFDEF DARWIN}
    class var FTBInited: Boolean;
    class var FTBNumer: UInt32;
    class var FTBDenom: UInt32;
    class procedure EnsureTimebase; static;
    class function DarwinNowNs: UInt64; static;
    class function DarwinTicksFromNs(const ns: UInt64): UInt64; static;
    {$ELSE}
    class function MonoNowNs: UInt64; static;
    {$ENDIF}
    {$ENDIF}
  public
    function NowInstant: TInstant;
  private
    {$IFDEF MSWINDOWS}
    class procedure BusyWaitUntilWindows(const Target: TInstant); static;
    {$ENDIF}

  public
    procedure SleepFor(const D: TDuration);
    procedure SleepUntil(const T: TInstant);
    function WaitFor(const D: TDuration; const Token: ICancellationToken): Boolean;
    function WaitUntil(const T: TInstant; const Token: ICancellationToken): Boolean;
  end;

  TSystemClock = class(TInterfacedObject, ISystemClock)
  public
    function NowUTC: TDateTime;  // 真实 UTC
    function NowLocal: TDateTime; // 本地时间
    function NowUnixMs: Int64;
    function NowUnixNs: Int64;
  end;

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
    // IClock
    function NowUTC: TDateTime;
    function NowLocal: TDateTime;
  end;

var
  GInitLock: ILock = nil;
  GMono: IMonotonicClock = nil;
  GSys: ISystemClock = nil;
  GClock: IClock = nil;
  GLowLatencySleepEnabled: Boolean = False; // backward-compat flag
  GSleepStrategy: TSleepStrategy = EnergySaving;
  GFinalSpinThresholdNsWindows: Int64 = 2 * NANOSECONDS_PER_MILLI;
  GFinalSpinThresholdNsLinux:   Int64 = 2 * NANOSECONDS_PER_MILLI;
  GFinalSpinThresholdNsDarwin:  Int64 = 2 * NANOSECONDS_PER_MILLI;
  GSliceSleepMsLinux: Integer = 1;   // Balanced/LowLatency 片段睡眠（ms）
  GSliceSleepMsDarwin: Integer = 1;  // Balanced/LowLatency 片段睡眠（ms）
  GSpinYieldEveryWindows: LongWord = 2048; // Balanced 忙等让权节奏（0=禁用）
  GSpinYieldEveryLinux:   LongWord = 2048; // Balanced 忙等让权节奏（0=禁用）
  GSpinYieldEveryDarwin:  LongWord = 2048; // 预留（当前 Darwin 阈值内走绝对等待）

{ TDuration }
class function TDuration.FromNs(const A: Int64): TDuration;
begin
  Result.FNs := A;
end;

class function TDuration.FromUs(const A: Int64): TDuration;
begin
  Result.FNs := A * NANOSECONDS_PER_MICRO;
end;

class function TDuration.FromMs(const A: Int64): TDuration;
begin
  Result.FNs := A * NANOSECONDS_PER_MILLI;
end;

class function TDuration.FromSec(const A: Int64): TDuration;
begin
  Result.FNs := A * NANOSECONDS_PER_SECOND;
end;

function TDuration.AsNs: Int64;
begin
  Result := FNs;
end;

function TDuration.AsUs: Int64;
begin
  Result := FNs div NANOSECONDS_PER_MICRO;
end;

function TDuration.AsMs: Int64;
begin
  Result := FNs div NANOSECONDS_PER_MILLI;
end;

function TDuration.Between(const MinV, MaxV: TDuration): TDuration;
begin
  Result := Clamp(MinV, MaxV);
end;

function TDuration.RoundToUnit(const UnitNs: Int64): TDuration;
var u, half, r: Int64;
begin
  if UnitNs <= 1 then Exit(Self);
  u := UnitNs; half := u div 2;
  if FNs >= 0 then r := (FNs + half) div u * u
  else r := -(((-FNs) + half) div u * u);
  Result.FNs := r;
end;

function TDuration.TruncToUnit(const UnitNs: Int64): TDuration;
var u, r: Int64;
begin
  if UnitNs <= 1 then Exit(Self);
  u := UnitNs;
  r := FNs div u * u;
  Result.FNs := r;
end;

function TDuration.FloorToUnit(const UnitNs: Int64): TDuration;
var u, r, q: Int64;
begin
  if UnitNs <= 1 then Exit(Self);
  u := UnitNs;
  q := FNs div u; // towards zero
  if (FNs < 0) and (FNs mod u <> 0) then Dec(q);
  r := q * u;
  Result.FNs := r;
end;

function TDuration.CeilToUnit(const UnitNs: Int64): TDuration;
var u, r, q: Int64;
begin
  if UnitNs <= 1 then Exit(Self);
  u := UnitNs;
  q := FNs div u; // towards zero
  if (FNs > 0) and (FNs mod u <> 0) then Inc(q);
  r := q * u;
  Result.FNs := r;
end;

function TDuration.RoundToUs: TDuration; begin Result := RoundToUnit(NANOSECONDS_PER_MICRO); end;
function TDuration.RoundToMs: TDuration; begin Result := RoundToUnit(NANOSECONDS_PER_MILLI); end;
function TDuration.RoundToSec: TDuration; begin Result := RoundToUnit(NANOSECONDS_PER_SECOND); end;
function TDuration.TruncToUs: TDuration; begin Result := TruncToUnit(NANOSECONDS_PER_MICRO); end;
function TDuration.TruncToMs: TDuration; begin Result := TruncToUnit(NANOSECONDS_PER_MILLI); end;
function TDuration.TruncToSec: TDuration; begin Result := TruncToUnit(NANOSECONDS_PER_SECOND); end;
function TDuration.FloorToUs: TDuration; begin Result := FloorToUnit(NANOSECONDS_PER_MICRO); end;
function TDuration.FloorToMs: TDuration; begin Result := FloorToUnit(NANOSECONDS_PER_MILLI); end;
function TDuration.FloorToSec: TDuration; begin Result := FloorToUnit(NANOSECONDS_PER_SECOND); end;
function TDuration.CeilToUs: TDuration; begin Result := CeilToUnit(NANOSECONDS_PER_MICRO); end;
function TDuration.CeilToMs: TDuration; begin Result := CeilToUnit(NANOSECONDS_PER_MILLI); end;
function TDuration.CeilToSec: TDuration; begin Result := CeilToUnit(NANOSECONDS_PER_SECOND); end;

class operator TDuration.+(const A, B: TDuration) res: TDuration;
begin res.FNs := A.FNs + B.FNs; end;
class operator TDuration.-(const A, B: TDuration) res: TDuration;
begin res.FNs := A.FNs - B.FNs; end;
class operator TDuration.*(const A: TDuration; const K: Int64) res: TDuration;
begin res.FNs := A.FNs * K; end;
class operator TDuration.*(const K: Int64; const A: TDuration) res: TDuration;
begin res.FNs := A.FNs * K; end;


function TDuration.AsSec: Int64;
begin
  Result := FNs div NANOSECONDS_PER_SECOND;
end;

function TDuration.Add(const B: TDuration): TDuration;
begin
  Result.FNs := FNs + B.FNs;
end;


function TDuration.Mul(const K: Int64): TDuration;
begin
  Result.FNs := FNs * K;
end;

function TDuration.Divi(const K: Int64): TDuration;
begin
  if K = 0 then
    Result := TDuration.Zero
  else
    Result.FNs := FNs div K;
end;

function TDuration.DivBy(const K: Int64): TDuration;
begin
  Result := Divi(K);
end;

function TDuration.Modulo(const B: TDuration): TDuration;
var d: Int64;
begin
  if B.FNs = 0 then begin Result := TDuration.Zero; Exit; end;
  d := FNs mod B.FNs;
  Result.FNs := d;
end;

function TDuration.Compare(const B: TDuration): Integer;
begin
  if FNs < B.FNs then Exit(-1)
  else if FNs > B.FNs then Exit(1)
  else Exit(0);
end;

function TDuration.LessThan(const B: TDuration): Boolean;
begin
  Result := FNs < B.FNs;
end;

function TDuration.GreaterThan(const B: TDuration): Boolean;
begin
  Result := FNs > B.FNs;
end;

class function TDuration.Min(const A, B: TDuration): TDuration;
begin
  if A.FNs <= B.FNs then Result := A else Result := B;
end;

class function TDuration.Max(const A, B: TDuration): TDuration;
begin
  if A.FNs >= B.FNs then Result := A else Result := B;
end;

function TDuration.SaturatingAdd(const B: TDuration): TDuration;
var
  x, y, r: Int64;
begin
  x := FNs; y := B.FNs;
  // 检测有符号加法溢出
  r := x + y;
  if ((x > 0) and (y > 0) and (r < 0)) then
    r := High(Int64)
  else if ((x < 0) and (y < 0) and (r > 0)) then
    r := Low(Int64);
  Result.FNs := r;
end;

class operator TDuration.=(const A, B: TDuration) res: Boolean;
begin
  res := A.FNs = B.FNs;
end;

class operator TDuration.<>(const A, B: TDuration) res: Boolean;
begin
  res := A.FNs <> B.FNs;
end;

class operator TDuration.<(const A, B: TDuration) res: Boolean;
begin
  res := A.FNs < B.FNs;
end;

class operator TDuration.>(const A, B: TDuration) res: Boolean;
begin
  res := A.FNs > B.FNs;
end;

class operator TDuration.<=(const A, B: TDuration) res: Boolean;
begin
  res := A.FNs <= B.FNs;
end;

class operator TDuration.>=(const A, B: TDuration) res: Boolean;
begin
  res := A.FNs >= B.FNs;
end;


function TDuration.Abs: TDuration;
begin
  if FNs < 0 then
  begin
    if FNs = Low(Int64) then
      // |Low(Int64)| 饱和为 High(Int64)
      Result.FNs := High(Int64)
    else
      Result.FNs := -FNs
  end
  else
    Result.FNs := FNs;
end;

function TDuration.Neg: TDuration;
begin
  if FNs = Low(Int64) then
    Result.FNs := High(Int64) // 饱和到最大正值，避免溢出
  else
    Result.FNs := -FNs;
end;

class function TDuration.TryFromNs(const A: Int64; out D: TDuration): Boolean;
begin
  D.FNs := A; // 直接赋值，无溢出
  Exit(True);
end;

class function TDuration.TryFromUs(const A: Int64; out D: TDuration): Boolean;
var tmp: Int64;
begin
  Result := True;
  {$PUSH}{$Q+}
  try
    tmp := A * NANOSECONDS_PER_MICRO;
  except
    on E: EIntOverflow do begin Result := False; Exit; end;
  end;
  {$POP}
  D.FNs := tmp;
end;

class function TDuration.TryFromMs(const A: Int64; out D: TDuration): Boolean;
var tmp: Int64;
begin
  Result := True;
  {$PUSH}{$Q+}
  try
    tmp := A * NANOSECONDS_PER_MILLI;
  except
    on E: EIntOverflow do begin Result := False; Exit; end;
  end;
  {$POP}
  D.FNs := tmp;
end;

class function TDuration.TryFromSec(const A: Int64; out D: TDuration): Boolean;
var tmp: Int64;
begin
  Result := True;

  {$PUSH}{$Q+}
  try
    tmp := A * NANOSECONDS_PER_SECOND;
  except
    on E: EIntOverflow do begin Result := False; Exit; end;
  end;
  {$POP}
  D.FNs := tmp;
end;

function TDuration.SaturatingMul(const K: Int64): TDuration;
var x, r: Int64;
begin
  x := FNs;
  {$PUSH}{$Q+}
  try
    r := x * K;
  except
    on E: EIntOverflow do
    begin
      if ((x >= 0) and (K >= 0)) or ((x < 0) and (K < 0)) then
        r := High(Int64)
      else
        r := Low(Int64);
    end;
  end;
  {$POP}
  Result.FNs := r;
end;

function TDuration.SaturatingDiv(const K: Int64): TDuration;
var x, r: Int64;
begin
  x := FNs;
  if K = 0 then
  begin
    // 约定：除以零返回 0（避免异常），也可选择饱和为极值
    r := 0;
  end
  else if (x = Low(Int64)) and (K = -1) then
    // 特殊溢出：最小负数 / -1
    r := High(Int64)
  else
    r := x div K;
  Result.FNs := r;
end;

function TDuration.CheckedDiv(const K: Int64; out R: TDuration): Boolean;
begin
  Result := CheckedDivBy(K, R);
end;

function TDuration.CheckedDivBy(const K: Int64; out R: TDuration): Boolean;
var tmp: Int64;
begin
  if K = 0 then begin Result := False; Exit; end;
  if (FNs = Low(Int64)) and (K = -1) then begin Result := False; Exit; end;
  tmp := FNs div K;
  R.FNs := tmp;
  Result := True;
end;

function TDuration.CheckedMul(const K: Int64; out R: TDuration): Boolean;
var a, b, absA, absB: Int64; ov: Boolean; prod: Int64;
begin
  a := FNs; b := K;
  // 特例：a=Low(Int64) 且 b=-1 会溢出
  if (a = Low(Int64)) and (b = -1) then begin Result := False; Exit; end;
  // 0 任一为 0 安全
  if (a = 0) or (b = 0) then begin R.FNs := 0; Result := True; Exit; end;
  // 预判溢出：|a| > High(Int64) div |b|
  if a < 0 then absA := -a else absA := a;
  if b < 0 then absB := -b else absB := b;
  ov := absA > (High(Int64) div absB);
  if ov then begin Result := False; Exit; end;
  prod := a * b;
  R.FNs := prod;
  Result := True;
end;

function TDuration.CheckedModulo(const B: TDuration; out R: TDuration): Boolean;
var tmp: Int64;
begin
  if B.FNs = 0 then begin Result := False; Exit; end;
  tmp := FNs mod B.FNs;
  R.FNs := tmp;
  Result := True;
end;


function TDuration.SaturatingSub(const B: TDuration): TDuration;
var
  x, y, r: Int64;
begin
  x := FNs; y := B.FNs;
  r := x - y;
  if ((x > 0) and (y < 0) and (r < 0)) then
    r := High(Int64)
  else if ((x < 0) and (y > 0) and (r > 0)) then
    r := Low(Int64);
  Result.FNs := r;
end;

function TInstant.Compare(const B: TInstant): Integer;
begin
  if FNsSinceEpoch < B.FNsSinceEpoch then Exit(-1)
  else if FNsSinceEpoch > B.FNsSinceEpoch then Exit(1)
  else Exit(0);
end;

function TInstant.LessThan(const B: TInstant): Boolean;
begin
  Result := FNsSinceEpoch < B.FNsSinceEpoch;
end;

function TInstant.GreaterThan(const B: TInstant): Boolean;
begin
  Result := FNsSinceEpoch > B.FNsSinceEpoch;
end;
class function TDeadline.FromNowMs(const Ms: Int64; const Clock: IInterface): TDeadline;
begin
  Result := FromNow(TDuration.FromMs(Ms), Clock);
end;

class function TDeadline.FromNowSec(const Sec: Int64; const Clock: IInterface): TDeadline;
begin
  Result := FromNow(TDuration.FromSec(Sec), Clock);
end;

function TDeadline.RemainingClampedZero(const NowI: TInstant): TDuration;
var
  r: TDuration;
begin
  r := Remaining(NowI);
  if r.IsNegative then
    Result := TDuration.Zero
  else
    Result := r;
end;


class function TInstant.Min(const A, B: TInstant): TInstant;
begin
  if A.FNsSinceEpoch <= B.FNsSinceEpoch then Result := A else Result := B;
end;

class function TInstant.Max(const A, B: TInstant): TInstant;
begin
  if A.FNsSinceEpoch >= B.FNsSinceEpoch then Result := A else Result := B;
end;

function TDuration.Sub(const B: TDuration): TDuration;
begin
  Result.FNs := FNs - B.FNs;
end;

function TDuration.IsZero: Boolean;
begin
  Result := FNs = 0;
end;

function TDuration.IsNegative: Boolean;
begin
  Result := FNs < 0;
end;

class function TDuration.Zero: TDuration;
begin
  Result.FNs := 0;
end;

function TDuration.Clamp(const MinV, MaxV: TDuration): TDuration;
var
  V: Int64;
begin
  V := FNs;
  if V < MinV.FNs then V := MinV.FNs
  else if V > MaxV.FNs then V := MaxV.FNs;
  Result.FNs := V;
end;

function TInstant.Since(const Older: TInstant): TDuration;
begin
  Result := Diff(Older);
end;

function TInstant.NonNegativeDiff(const Older: TInstant): TDuration;
var d: TDuration;
begin
  d := Diff(Older);
  if d.IsNegative then
    Result := TDuration.Zero
  else
    Result := d;
end;

function TInstant.CheckedAdd(const D: TDuration; out R: TInstant): Boolean;
var dNs: Int64; inc, decv: UInt64; base: UInt64;
begin
  dNs := D.AsNs;
  if dNs >= 0 then
  begin
    inc := UInt64(dNs);
    if (High(UInt64) - FNsSinceEpoch) < inc then
      Exit(False)
    else
      base := FNsSinceEpoch + inc;
  end
  else
  begin
    decv := UInt64(-dNs);
    if FNsSinceEpoch < decv then
      Exit(False)
    else
      base := FNsSinceEpoch - decv;
  end;
  R := TInstant.FromNsSinceEpoch(base);
  Result := True;
end;

function TInstant.CheckedSub(const D: TDuration; out R: TInstant): Boolean;
begin
  Result := CheckedAdd(D.Neg, R);
end;

{ TInstant }

function TInstant.IsBefore(const Other: TInstant): Boolean;
begin Result := FNsSinceEpoch < Other.FNsSinceEpoch; end;
function TInstant.IsAfter(const Other: TInstant): Boolean;
begin Result := FNsSinceEpoch > Other.FNsSinceEpoch; end;


class function TInstant.FromNsSinceEpoch(const A: UInt64): TInstant;
begin
  Result.FNsSinceEpoch := A;
end;

function TInstant.AsNsSinceEpoch: UInt64;
begin
  Result := FNsSinceEpoch;
end;

function TInstant.Clamp(const MinV, MaxV: TInstant): TInstant;
begin
  if FNsSinceEpoch < MinV.FNsSinceEpoch then Exit(MinV)
  else if FNsSinceEpoch > MaxV.FNsSinceEpoch then Exit(MaxV)
  else Exit(Self);
end;

function TInstant.Between(const MinV, MaxV: TInstant): TInstant;
begin
  Result := Clamp(MinV, MaxV);
end;


function TInstant.Add(const D: TDuration): TInstant;
var
  dNs: Int64;
  base: UInt64;
  inc, decv: UInt64;
begin
  // 饱和无符号加/减：避免 UInt64->Int64 转换导致的错误归零
  dNs := D.AsNs;
  if dNs >= 0 then
  begin
    inc := UInt64(dNs);
    if (High(UInt64) - FNsSinceEpoch) < inc then
      base := High(UInt64)
    else
      base := FNsSinceEpoch + inc;
  end
  else
  begin
    decv := UInt64(-dNs);
    if FNsSinceEpoch < decv then
      base := 0
    else
      base := FNsSinceEpoch - decv;
  end;
  Result.FNsSinceEpoch := base;
end;


class operator TInstant.=(const A, B: TInstant) res: Boolean;
begin
  res := A.FNsSinceEpoch = B.FNsSinceEpoch;
end;

class operator TInstant.<>(const A, B: TInstant) res: Boolean;
begin
  res := A.FNsSinceEpoch <> B.FNsSinceEpoch;
end;

class operator TInstant.<(const A, B: TInstant) res: Boolean;
begin
  res := A.FNsSinceEpoch < B.FNsSinceEpoch;
end;

class operator TInstant.>(const A, B: TInstant) res: Boolean;
begin
  res := A.FNsSinceEpoch > B.FNsSinceEpoch;
end;

class operator TInstant.<=(const A, B: TInstant) res: Boolean;
begin
  res := A.FNsSinceEpoch <= B.FNsSinceEpoch;
end;

class operator TInstant.>=(const A, B: TInstant) res: Boolean;
begin
  res := A.FNsSinceEpoch >= B.FNsSinceEpoch;
end;

function TInstant.Diff(const Older: TInstant): TDuration;
var
  Cur, Old: UInt64;
  Delta: Int64;
begin
  Cur := FNsSinceEpoch;
  Old := Older.FNsSinceEpoch;
  if Cur >= Old then
    Delta := Int64(Cur - Old)
  else
    // 不期望单调倒退；出现时按负值表达
    Delta := -Int64(Old - Cur);
  Result := TDuration.FromNs(Delta);
end;

function TInstant.HasPassed(const NowI: TInstant): Boolean;
begin
  Result := NowI.FNsSinceEpoch >= FNsSinceEpoch;
end;

{ TDeadline }
class function TDeadline.FromNow(const D: TDuration; const Clock: IInterface): TDeadline;
var
  I: TInstant;
  Mono: IMonotonicClock;
begin
  if (Clock <> nil) and Supports(Clock, IMonotonicClock, Mono) then
    I := Mono.NowInstant
  else
    I := DefaultMonotonicClock.NowInstant;
  Result.FWhen := I.Add(D);
end;

class function TDeadline.FromInstant(const T: TInstant): TDeadline;
begin
  Result.FWhen := T;
end;

function TDeadline.When: TInstant;
begin
  Result := FWhen;
end;

function TDeadline.Remaining(const NowI: TInstant): TDuration;
begin
  Result := FWhen.Diff(NowI);
end;
{$IFDEF DARWIN}
class procedure TMonotonicClock.EnsureTimebase;
begin
  if not FTBInited then
  begin
    {$PUSH}
    {$WARN 5024 off}
    varinfo: mach_timebase_info_data_t;
    {$POP}
    if mach_timebase_info(varinfo) = 0 then
    begin
      FTBNumer := varinfo.numer;
      FTBDenom := varinfo.denom;
      if (FTBNumer = 0) or (FTBDenom = 0) then
      begin
        // 标记退化：以 1:1 近似，并记录一次（测试可见）
        FTBNumer := 1;
        FTBDenom := 1;
      end;
      FTBInited := True;
    end
    else
    begin
      // 回退：若无法获取 timebase，则将比例设为 1:1
      FTBNumer := 1;
      FTBDenom := 1;
      FTBInited := True;
    end;
  end;
end;

class function TMonotonicClock.DarwinNowNs: UInt64;
var
  t: QWord;
  ns: UInt64;
begin
  EnsureTimebase;
  t := mach_absolute_time;
  // 纳秒 = ticks * numer / denom
  ns := (t * FTBNumer) div FTBDenom;
  Result := ns;
end;

class function TMonotonicClock.DarwinTicksFromNs(const ns: UInt64): UInt64;
var
  ticks: UInt64;
begin
  EnsureTimebase;
{$IFDEF DARWIN}
function Test_DarwinTimebaseIsFallback: Boolean;
begin
  // 退化即 numer/denom 被设为 1:1（见 EnsureTimebase 的退化逻辑）
  Result := (FTBNumer = 1) and (FTBDenom = 1);
end;
{$ENDIF}

  // ticks = ns * denom / numer；若处于退化(1:1)则直接返回 ns
  if FTBNumer = 0 then
    Exit(ns)
  else
  begin
    ticks := (ns * FTBDenom) div FTBNumer;
    Result := ticks;
  end;
end;
{$ENDIF}


function TDeadline.Expired(const NowI: TInstant): Boolean;
begin
  Result := FWhen.HasPassed(NowI);
end;

function TDeadline.TimeUntil(const NowI: TInstant): TDuration;
begin
  Result := Remaining(NowI);
end;

function TDeadline.Overdue(const NowI: TInstant): TDuration;
var r: TDuration;
begin
  r := Remaining(NowI);
  if r.IsNegative then
    Result := r.Neg
  else
    Result := TDuration.Zero;
end;

function TDeadline.IsExpired(const NowI: TInstant): Boolean;
begin
  Result := Expired(NowI);
end;

{ TMonotonicClock }
{$IFDEF MSWINDOWS}
class procedure TMonotonicClock.EnsureQPCFreq;
begin
  if not FFreqInited then
  begin
    if not QueryPerformanceFrequency(FQPCFreq) then
      FQPCFreq := 0;
    // 初始化后固定退化路径
    FUseGTC64 := (FQPCFreq <= 0);
    FFreqInited := True;
  end;
end;

class function TMonotonicClock.QpcNowNs: UInt64;
var
  C: Int64;
  ns, fq, q, r, part: UInt64;
begin
  EnsureQPCFreq;
  // 初始化后固定路径，避免运行时切换造成非连续性
  if FUseGTC64 then
  begin
    ns := UInt64(GetTickCount64) * UInt64(NANOSECONDS_PER_MILLI);
    Exit(ns);
  end;
  if not QueryPerformanceCounter(C) then
  begin
    // 即使 QPC 临时失败，也保持使用 GTC64；不再回到 QPC
    FUseGTC64 := True;
    Inc(FFallbackCount);
    ns := UInt64(GetTickCount64) * UInt64(NANOSECONDS_PER_MILLI);
    Exit(ns);
  end;
  // 使用整数换算避免浮点舍入误差：
  // ns = (C / FQPCFreq) * 1e9 + (C mod FQPCFreq) * 1e9 / FQPCFreq
  fq := UInt64(FQPCFreq);
  q := UInt64(C) div fq;
  r := UInt64(C) mod fq;
  part := (r * UInt64(NANOSECONDS_PER_SECOND)) div fq;
  ns := q * UInt64(NANOSECONDS_PER_SECOND) + part;


  Result := ns;
end;
{$ELSE}
class function TMonotonicClock.MonoNowNs: UInt64;
var
  ts: timespec;
begin
  // CLOCK_MONOTONIC
  clock_gettime(CLOCK_MONOTONIC, @ts);
  Result := UInt64(ts.tv_sec) * UInt64(NANOSECONDS_PER_SECOND) + UInt64(ts.tv_nsec);
end;
{$ENDIF}

function TMonotonicClock.NowInstant: TInstant;

begin
  {$IFDEF MSWINDOWS}
  Result := TInstant.FromNsSinceEpoch(QpcNowNs);
  {$ELSE}
    {$IFDEF DARWIN}
    Result := TInstant.FromNsSinceEpoch(DarwinNowNs);
    {$ELSE}
    Result := TInstant.FromNsSinceEpoch(MonoNowNs);
    {$ENDIF}
  {$ENDIF}
end;

{$IFDEF MSWINDOWS}
class procedure TMonotonicClock.BusyWaitUntilWindows(const Target: TInstant);
var
  deadlineNs, nowNs: UInt64;
  iter: LongWord;
begin
  // 忙等至目标时刻；使用 QPC 纳秒时间，避免接口分发开销
  deadlineNs := Target.AsNsSinceEpoch;
  iter := 0;
  repeat
    nowNs := QpcNowNs;
    Inc(iter);
    // Balanced：定期让权降低能耗；UltraLowLatency：也引入可配置的让权节奏，避免单核/高负载饿死
    if (((GSleepStrategy = Balanced) or (GSleepStrategy = UltraLowLatency)) and
        (GSpinYieldEveryWindows <> 0) and ((iter mod GSpinYieldEveryWindows) = 0)) then
      Windows.Sleep(0)
    else
      CpuRelax;
  until nowNs >= deadlineNs;
end;
{$ENDIF}


function TimeIt(const P: TProc): TDuration;
var
  c: IMonotonicClock;
  t0, t1: TInstant;
begin
  c := DefaultMonotonicClock;
  t0 := c.NowInstant;

  if Assigned(P) then P();
  t1 := c.NowInstant;
  Result := t1.Diff(t0);
end;

function FormatDurationHuman(const D: TDuration): string;
var
  ns, absns, us, ms, sec: Int64;
  s: string;
  prec: Integer;
begin
  ns := D.AsNs;
  absns := Abs(ns);
  if absns < 1000 then
  begin
    if GDurationFmtUseAbbr then Exit(IntToStr(ns) + 'ns')
    else Exit(IntToStr(ns) + ' nanoseconds');
  end;
  if absns < NANOSECONDS_PER_MILLI then
  begin
    us := ns div NANOSECONDS_PER_MICRO;
    if GDurationFmtUseAbbr then Exit(IntToStr(us) + 'us')
    else Exit(IntToStr(us) + ' microseconds');
  end
  else if absns < NANOSECONDS_PER_SECOND then
  begin
    ms := ns div NANOSECONDS_PER_MILLI;
    if GDurationFmtUseAbbr then Exit(IntToStr(ms) + 'ms')
    else Exit(IntToStr(ms) + ' milliseconds');
  end
  else
  begin
    // 秒：支持轻量小数位
    prec := GDurationFmtSecPrecision;
    if prec <= 0 then
    begin
      sec := ns div NANOSECONDS_PER_SECOND;
      if GDurationFmtUseAbbr then Exit(IntToStr(sec) + 's')
      else Exit(IntToStr(sec) + ' seconds');
    end
    else
    begin
      // 简单实现：使用固定小数位格式化，避免复杂的手工舍入逻辑
      s := FloatToStrF(ns / 1e9, ffFixed, 18, prec);
      if GDurationFmtUseAbbr then Exit(s + 's')
      else Exit(s + ' seconds');
    end;
  end;
end;

procedure SetDurationFormatUseAbbr(AUseAbbr: Boolean);
begin
  GDurationFmtUseAbbr := AUseAbbr;
end;

function GetDurationFormatUseAbbr: Boolean;
begin
  Result := GDurationFmtUseAbbr;
end;

procedure SetDurationFormatSecPrecision(APrecision: Integer);
begin
  if APrecision < 0 then APrecision := 0;
  if APrecision > 9 then APrecision := 9; // 合理上限，避免无意义的过高精度
  GDurationFmtSecPrecision := APrecision;
end;

function GetDurationFormatSecPrecision: Integer;
begin
  Result := GDurationFmtSecPrecision;
end;


procedure TMonotonicClock.SleepFor(const D: TDuration);

var
  ns: Int64;
  ms: QWord;
{$IFNDEF MSWINDOWS}
  req, rem: timespec;
{$ENDIF}
  target: TInstant;
  remainNs: Int64;
begin
  ns := D.AsNs;
  if ns <= 0 then Exit;
  {$IFDEF MSWINDOWS}
  case GSleepStrategy of
    EnergySaving:
      begin
        // 四舍五入到最近的毫秒（最小 1ms）
        ms := QWord((ns + NANOSECONDS_PER_MILLI div 2) div NANOSECONDS_PER_MILLI);
        if ms = 0 then ms := 1;
        Windows.Sleep(DWORD(ms));
      end;
    Balanced, LowLatency, UltraLowLatency:
      begin
        // Balanced/LowLatency：Sleep(1) 降能耗 + 最后阈值内自旋
        // UltraLowLatency：改用更短让权 Sleep(0)
        target := NowInstant.Add(TDuration.FromNs(ns));
        while True do
        begin
          remainNs := target.Diff(NowInstant).AsNs;
          if remainNs <= 0 then Break;
          if remainNs > GFinalSpinThresholdNsWindows then
          begin
            if GSleepStrategy = UltraLowLatency then
              Windows.Sleep(0)
            else
              Windows.Sleep(1);
          end
          else
          begin
            BusyWaitUntilWindows(target);
            Break;
          end;
        end;
      end;
  end;
  {$ELSE}
  {$IFDEF LINUX}
  if GSleepStrategy = EnergySaving then
  begin
    // 直接相对睡眠（EINTR 重试）
    req.tv_sec := time_t(ns div NANOSECONDS_PER_SECOND);
    req.tv_nsec := LongInt(ns mod NANOSECONDS_PER_SECOND);
    while fpNanoSleep(@req, @rem) <> 0 do
    begin
      if fpgeterrno = ESysEINTR then
        req := rem
      else
        Break;
    end;
  end
  else
  begin
    // Balanced/LowLatency：片段睡眠 + 最后阈值忙等收尾
    target := NowInstant.Add(TDuration.FromNs(ns));
    while True do
    begin
      remainNs := target.Diff(NowInstant).AsNs;
      if remainNs <= 0 then Break;
      if remainNs > GFinalSpinThresholdNsLinux then
      begin
        // Balanced: 片段睡眠；UltraLowLatency: 更短让权
        req.tv_sec := 0;
        if GSleepStrategy = UltraLowLatency then
          req.tv_nsec := LongInt(NANOSECONDS_PER_MICRO * 200) // 约 0.2ms 让权
        else
          req.tv_nsec := LongInt(GSliceSleepMsLinux * NANOSECONDS_PER_MILLI);
        while fpNanoSleep(@req, @rem) <> 0 do
        begin
          if fpgeterrno = ESysEINTR then req := rem else Break;
        end;
      end
      else
      begin
        // 阈值内忙等：Balanced 定期让权，LowLatency/UltraLowLatency 紧凑自旋
        iter := 0;
        while True do
        begin
          remainNs := target.Diff(NowInstant).AsNs;
          if remainNs <= 0 then Break;
          {$IFDEF LINUX}
          if (GSleepStrategy = Balanced) and (GSpinYieldEveryLinux <> 0) and ((iter mod GSpinYieldEveryLinux) = 0) then
            fpSchedYield
          else
          {$ENDIF}
            CpuRelax;
          Inc(iter);
        end;
      end;
    end;
  end;
  {$ELSEIF Defined(DARWIN)}
  if GSleepStrategy = EnergySaving then
  begin
    // 直接相对睡眠（EINTR 重试）
    req.tv_sec := time_t(ns div NANOSECONDS_PER_SECOND);
    req.tv_nsec := LongInt(ns mod NANOSECONDS_PER_SECOND);
    while fpNanoSleep(@req, @rem) <> 0 do
    begin
      if fpgeterrno = ESysEINTR then
        req := rem
      else
        Break;
    end;
  end
  else
  begin
    // macOS：在 Balanced/LowLatency/UltraLowLatency 下，优先使用绝对等待减少漂移：
    // 1) 若距离到期 > threshold：先分片 nanosleep 让权；
    // 2) 一旦进入阈值窗口：改为基于 mach_wait_until 的绝对等待直达目标。
    target := NowInstant.Add(TDuration.FromNs(ns));
    while True do
    begin
      remainNs := target.Diff(NowInstant).AsNs;
      if remainNs <= 0 then Break;
      if remainNs > GFinalSpinThresholdNsDarwin then
      begin
        req.tv_sec := 0;
        if GSleepStrategy = UltraLowLatency then
          req.tv_nsec := LongInt(NANOSECONDS_PER_MICRO * 200)
        else
          req.tv_nsec := LongInt(GSliceSleepMsDarwin * NANOSECONDS_PER_MILLI);
        while fpNanoSleep(@req, @rem) <> 0 do
        begin
          if fpgeterrno = ESysEINTR then req := rem else Break;
        end;
      end
      else
      begin
        // 阈值窗口内直接绝对等待到目标，避免 busy-loop
        mach_wait_until(DarwinTicksFromNs(target.AsNsSinceEpoch));
        Break;
      end;
    end;
  end;
  {$ELSE}
  // 其它 Unix 路径（保守）
  req.tv_sec := time_t(ns div NANOSECONDS_PER_SECOND);
  req.tv_nsec := LongInt(ns mod NANOSECONDS_PER_SECOND);
  while fpNanoSleep(@req, @rem) <> 0 do
begin
  if fpgeterrno = ESysEINTR then
    req := rem
  else
    Break;
end;
  {$ENDIF}
  {$ENDIF}
// macOS 说明：EnergySaving 模式采用 nanosleep（相对，EINTR 重试）；
// Balanced/LowLatency/UltraLowLatency 模式：先分片 nanosleep，再在阈值内使用 mach_wait_until 进行绝对等待，减少漂移。

end;

{ TFixedMonotonicClock }
constructor TFixedMonotonicClock.Create(const StartAt: TInstant);
begin
  inherited Create;
  FNow := StartAt;
end;

procedure TFixedMonotonicClock.SetNow(const V: TInstant);
begin
  FNow := V;
end;

function TFixedMonotonicClock.NowInstant: TInstant;
begin
  Result := FNow;
end;

procedure TFixedMonotonicClock.SleepFor(const D: TDuration);
begin
  FNow := FNow.Add(D);
end;

procedure SetSpinYieldEvery(N: LongWord);
begin
  GSpinYieldEveryWindows := N;
  GSpinYieldEveryLinux := N;
  GSpinYieldEveryDarwin := N;
end;

procedure SetSpinYieldEveryFor(APlat: TPlatformKind; N: LongWord);
begin
  case APlat of
    PlatWindows: GSpinYieldEveryWindows := N;
    PlatLinux:   GSpinYieldEveryLinux := N;
    PlatDarwin:  GSpinYieldEveryDarwin := N;
  end;
end;

function GetSpinYieldEveryFor(APlat: TPlatformKind): LongWord;
begin
  case APlat of
    PlatWindows: Result := GSpinYieldEveryWindows;
    PlatLinux:   Result := GSpinYieldEveryLinux;
    PlatDarwin:  Result := GSpinYieldEveryDarwin;
  else
    Result := 0;
  end;
end;

procedure TFixedMonotonicClock.SleepUntil(const T: TInstant);
var
  d: TDuration;
begin
  d := T.Diff(FNow);
  if not d.IsNegative then
    FNow := T;
end;

function TFixedMonotonicClock.WaitFor(const D: TDuration; const Token: ICancellationToken): Boolean;
begin
  Result := SleepForCancelable(D, Token);
end;

function TFixedMonotonicClock.WaitUntil(const T: TInstant; const Token: ICancellationToken): Boolean;
begin
  Result := SleepUntilCancelable(T, Token);
end;

procedure TMonotonicClock.SleepUntil(const T: TInstant);
var
  nowI: TInstant;
  remain: TDuration;
{$IFDEF LINUX}
  ts: timespec;
  res: LongInt;
  n: UInt64;
{$ELSEIF Defined(DARWIN)}
  targetNs: UInt64;
  targetTicks: UInt64;
{$ENDIF}
begin
  {$IFDEF LINUX}
  // 使用 CLOCK_MONOTONIC 的绝对睡眠，减少漂移；EINTR 重试
  n := T.AsNsSinceEpoch;
  ts.tv_sec := time_t(n div NANOSECONDS_PER_SECOND);
  ts.tv_nsec := LongInt(n mod NANOSECONDS_PER_SECOND);
  while True do
  begin
    res := clock_nanosleep(CLOCK_MONOTONIC, 1 {TIMER_ABSTIME}, @ts, nil);
    if (res = 0) or (res <> ESysEINTR) then Break;
  end;
  {$ELSEIF Defined(DARWIN)}
  // 使用 mach_wait_until 做绝对睡眠（基于 mach_absolute_time）
  targetNs := T.AsNsSinceEpoch;
  targetTicks := DarwinTicksFromNs(targetNs);
  mach_wait_until(targetTicks);
  {$ELSE}
  nowI := NowInstant;
  remain := T.Diff(nowI);
  if not remain.IsNegative then
    SleepFor(remain);
  {$ENDIF}

end;

{ TSystemClock }
function TSystemClock.NowUTC: TDateTime;
begin
  // 返回真实 UTC 时间（通过本地->UTC 转换）
  Result := LocalTimeToUniversal(Now);
end;
function TSystemClock.NowUnixMs: Int64;
{$IFDEF MSWINDOWS}
var
  ft: FILETIME; ft64: UInt64;
  type TGetSystemTimePreciseAsFileTime = procedure(out AFileTime: FILETIME); stdcall;
  function GetPreciseProc: TGetSystemTimePreciseAsFileTime;
  var h: HMODULE; p: Pointer;
  begin
    // 运行时解析以兼容旧系统；解析失败则返回 nil。
    h := GetModuleHandle('kernel32.dll');
    if h = 0 then Exit(nil);
    p := GetProcAddress(h, 'GetSystemTimePreciseAsFileTime');
    if p = nil then Exit(nil);
    Result := TGetSystemTimePreciseAsFileTime(p);
  end;
var Precise: TGetSystemTimePreciseAsFileTime;
begin
  Precise := GetPreciseProc;
  if Assigned(Precise) then
    Precise(ft)
  else
    GetSystemTimeAsFileTime(ft);
  ft64 := (UInt64(ft.dwHighDateTime) shl 32) or UInt64(ft.dwLowDateTime);
  // FILETIME: 100ns 自 1601-01-01 起；转为 ms 自 1970-01-01 起
  Result := Int64((ft64 div 10000) - 11644473600000);
end;
{$ELSEIF Defined(LINUX)}
var ts: timespec;
begin
  // Linux: CLOCK_REALTIME，直接返回自 UNIX 纪元起的毫秒
  clock_gettime(CLOCK_REALTIME, @ts);
  Result := Int64(ts.tv_sec) * 1000 + (Int64(ts.tv_nsec) div 1000000);
end;
{$ELSEIF Defined(DARWIN)}
var tv: timeval;
begin
  // macOS: gettimeofday（墙钟），毫秒
  fpgettimeofday(@tv, nil);
  Result := Int64(tv.tv_sec) * 1000 + (Int64(tv.tv_usec) div 1000);
end;
{$ELSE}
var dt: TDateTime;
begin
  // 其它平台：退回 TDateTime 推算（名义精度，非硬件纳秒）
  dt := NowUTC;
  Result := DateTimeToUnix(dt) * 1000 + MilliSecondOf(dt);
end;
{$ENDIF}

function TSystemClock.NowUnixNs: Int64;
{$IFDEF MSWINDOWS}
var
  ft: FILETIME; ft64: UInt64;
  type TGetSystemTimePreciseAsFileTime = procedure(out AFileTime: FILETIME); stdcall;
  function GetPreciseProc: TGetSystemTimePreciseAsFileTime;
  var h: HMODULE; p: Pointer;
  begin
    h := GetModuleHandle('kernel32.dll');
    if h = 0 then Exit(nil);
    p := GetProcAddress(h, 'GetSystemTimePreciseAsFileTime');
    if p = nil then Exit(nil);
    Result := TGetSystemTimePreciseAsFileTime(p);
  end;
var Precise: TGetSystemTimePreciseAsFileTime;
begin
  Precise := GetPreciseProc;
  if Assigned(Precise) then
    Precise(ft)
  else
    GetSystemTimeAsFileTime(ft);
  ft64 := (UInt64(ft.dwHighDateTime) shl 32) or UInt64(ft.dwLowDateTime);
  // FILETIME 100ns -> ns; 再减去 1601->1970 的偏移
  Result := Int64((ft64 * 100) - (11644473600000 * Int64(1000000)));
end;
{$ELSEIF Defined(LINUX)}
var ts: timespec;
begin
  clock_gettime(CLOCK_REALTIME, @ts);
  Result := Int64(ts.tv_sec) * 1000000000 + Int64(ts.tv_nsec);
end;
{$ELSEIF Defined(DARWIN)}
var tv: timeval;
begin
  fpgettimeofday(@tv, nil);
  Result := Int64(tv.tv_sec) * 1000000000 + Int64(tv.tv_usec) * 1000;
end;
{$ELSE}
var dt: TDateTime;
begin
  dt := NowUTC;
  // 名义纳秒刻度：由毫秒推算
  Result := Int64(DateTimeToUnix(dt)) * 1000000000 + Int64(MilliSecondOf(dt)) * 1000000;
end;
{$ENDIF}


function TSystemClock.NowLocal: TDateTime;
begin
  Result := Now; // 本地墙钟
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

function TMonotonicClock.WaitFor(const D: TDuration; const Token: ICancellationToken): Boolean;
begin
  Result := SleepForCancelable(D, Token);
end;

function TMonotonicClock.WaitUntil(const T: TInstant; const Token: ICancellationToken): Boolean;
begin
  Result := SleepUntilCancelable(T, Token);
end;

procedure TDefaultClock.SleepFor(const D: TDuration);
begin
  FMono.SleepFor(D);
end;

function TDefaultClock.WaitFor(const D: TDuration; const Token: ICancellationToken): Boolean;
begin
  Result := SleepForCancelable(D, Token);
end;

function TDefaultClock.WaitUntil(const T: TInstant; const Token: ICancellationToken): Boolean;
begin
  Result := SleepUntilCancelable(T, Token);
end;

function SleepForCancelable(const D: TDuration; const Token: ICancellationToken): Boolean;
var
  left, step, minStep, maxStep: TDuration;
  thisStep: TDuration;
begin
  if not Assigned(Token) or D.IsNegative or D.IsZero then Exit(True);
  left := D;
  // 动态时间片：步进策略与全局 Sleep 策略对齐
  case GetSleepStrategy of
    EnergySaving: begin minStep := TDuration.FromMs(1);  maxStep := TDuration.FromMs(50); end;
    Balanced:     begin minStep := TDuration.FromMs(1);  maxStep := TDuration.FromMs(20); end;
    LowLatency:   begin minStep := TDuration.FromMs(1);  maxStep := TDuration.FromMs(10); end;
    UltraLowLatency: begin minStep := TDuration.FromMs(1);  maxStep := TDuration.FromMs(5); end;
  end;
  while left.GreaterThan(TDuration.Zero) do
  begin
    if Token.IsCancellationRequested then Exit(False);
    // step = clamp(left/2, 1ms..50ms)
    step := TDuration.FromNs(left.AsNs div 2);
    step := step.Clamp(minStep, maxStep);
    thisStep := TDuration.Min(left, step);
    SleepFor(thisStep);
    left := left.Sub(thisStep);
  end;
  Result := True;
end;

function SleepUntilCancelable(const T: TInstant; const Token: ICancellationToken): Boolean;
var
  nowI: TInstant;
  remain, step, minStep, maxStep: TDuration;
begin
  if not Assigned(Token) then
  begin
    SleepUntil(T);
    Exit(True);
  end;
  case GetSleepStrategy of
    EnergySaving: begin minStep := TDuration.FromMs(1);  maxStep := TDuration.FromMs(50); end;
    Balanced:     begin minStep := TDuration.FromMs(1);  maxStep := TDuration.FromMs(20); end;
    LowLatency:   begin minStep := TDuration.FromMs(1);  maxStep := TDuration.FromMs(10); end;
    UltraLowLatency: begin minStep := TDuration.FromMs(1);  maxStep := TDuration.FromMs(5); end;
  end;
  while True do
  begin
    if Token.IsCancellationRequested then Exit(False);
    nowI := NowInstant;
    remain := T.Diff(nowI);
    if remain.IsNegative or remain.IsZero then Exit(True);
    // step = clamp(remain/2, min..max)
    step := TDuration.FromNs(remain.AsNs div 2).Clamp(minStep, maxStep);
    SleepFor(step);
  end;
end;

function GetSleepStrategy: TSleepStrategy;
begin
  Result := GSleepStrategy;
end;

procedure SetSliceSleepMs(AMs: Integer);
begin
  if AMs < 0 then AMs := 0;
  GSliceSleepMsLinux := AMs;
  GSliceSleepMsDarwin := AMs;
end;

procedure SetSliceSleepMsFor(APlat: TPlatformKind; AMs: Integer);
begin
  if AMs < 0 then AMs := 0;
  case APlat of
    PlatLinux:   GSliceSleepMsLinux := AMs;
    PlatDarwin:  GSliceSleepMsDarwin := AMs;
    else ;
  end;
end;

function GetSliceSleepMsFor(APlat: TPlatformKind): Integer;
begin
  case APlat of
    PlatLinux:  Result := GSliceSleepMsLinux;
    PlatDarwin: Result := GSliceSleepMsDarwin;
  else
    Result := 1;
  end;
end;



procedure TDefaultClock.SleepUntil(const T: TInstant);
begin
  FMono.SleepUntil(T);
end;

procedure SetSleepStrategy(AStrategy: TSleepStrategy);
begin
  GSleepStrategy := AStrategy;
  GLowLatencySleepEnabled := (AStrategy = LowLatency);
end;

procedure SetFinalSpinThresholdNs(ANs: Int64);
begin
  if ANs < 0 then ANs := 0;
  GFinalSpinThresholdNsWindows := ANs;
  GFinalSpinThresholdNsLinux := ANs;
  GFinalSpinThresholdNsDarwin := ANs;
end;

procedure SetFinalSpinThresholdNsFor(APlat: TPlatformKind; ANs: Int64);
begin
  if ANs < 0 then ANs := 0;
  case APlat of
    PlatWindows: GFinalSpinThresholdNsWindows := ANs;
    PlatLinux:   GFinalSpinThresholdNsLinux := ANs;
    PlatDarwin:  GFinalSpinThresholdNsDarwin := ANs;
  end;
end;

procedure SetLowLatencySleepEnabled(AEnabled: Boolean);
begin
  if AEnabled then
    SetSleepStrategy(LowLatency)
  else
    SetSleepStrategy(EnergySaving);
end;

function TDefaultClock.NowUTC: TDateTime;
begin
  Result := FSys.NowUTC;
end;

function TDefaultClock.NowLocal: TDateTime;
begin
  Result := FSys.NowLocal;
end;

function NowUnixMs: Int64;
begin
  Result := DefaultSystemClock.NowUnixMs;
end;

function NowUnixNs: Int64;
begin
  Result := DefaultSystemClock.NowUnixNs;
end;

procedure EnsureInitLock;
begin
  if GInitLock = nil then
    GInitLock := TMutex.Create;
end;


{ Factories and helpers }
function DefaultMonotonicClock: IMonotonicClock;
begin
  if GMono = nil then
  begin
    EnsureInitLock;
    GInitLock.Acquire;
    try
      if GMono = nil then
        GMono := TMonotonicClock.Create;
    finally
      GInitLock.Release;
    end;
  end;
  Result := GMono;
end;

{$IFDEF MSWINDOWS}
function Test_GetWindowsQpcFallbackCount: LongWord;
begin
  Result := TMonotonicClock.FFallbackCount;
end;
{$ENDIF}


function DefaultSystemClock: ISystemClock;
begin
  if GSys = nil then
  begin
    EnsureInitLock;
    GInitLock.Acquire;
    try
      if GSys = nil then
        GSys := TSystemClock.Create;
    finally
      GInitLock.Release;
    end;
  end;
  Result := GSys;
end;

function DefaultClock: IClock;
begin
  if GClock = nil then
  begin
    EnsureInitLock;
    GInitLock.Acquire;
    try
      if GClock = nil then
        GClock := TDefaultClock.Create(DefaultMonotonicClock, DefaultSystemClock);
    finally
      GInitLock.Release;
    end;
  end;
  Result := GClock;
end;

procedure SleepFor(const D: TDuration);
begin
  DefaultMonotonicClock.SleepFor(D);
end;

procedure SleepUntil(const T: TInstant);
begin
  DefaultMonotonicClock.SleepUntil(T);
end;

// 实现前置声明的 SleepUntilWithSlack
procedure SleepUntilWithSlack(const T: TInstant; const Slack: TDuration);
var
  nowI: TInstant;
  remain: TDuration;
begin
  nowI := NowInstant;
  remain := T.Diff(nowI);
  if remain.IsNegative then Exit;
  if remain.GreaterThan(Slack) then
    SleepFor(remain.Sub(Slack));
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

{$IFDEF MSWINDOWS}
procedure Test_ForceUseGTC64_ForWindows(AForce: Boolean);
begin
  TMonotonicClock.FFreqInited := True;
  TMonotonicClock.FUseGTC64 := AForce;
  if not AForce then
    TMonotonicClock.FFreqInited := False;
end;
{$ENDIF}



initialization
  // 延迟初始化，首次调用时创建默认时钟

finalization
  GClock := nil;
  GMono := nil;
  GSys := nil;
  GInitLock := nil;


end.

