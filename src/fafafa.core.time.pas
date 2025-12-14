unit fafafa.core.time;

{$mode objfpc}
{$I fafafa.core.settings.inc}
{*
  fafafa.core.time - 时间模块门面单元（统一出口）

  职责：
  - 仅转出公共接口与便捷函数，不实现具体细节
  - 聚合核心子模块：base、duration、instant、clock、timer、calendar 等
  - 为上层调用提供稳定命名与 API

  注意：本单元不引入任何平台特定的实现代码
*}

interface

uses
  SysUtils,
  // 基础与核心类型
  fafafa.core.time.base,
  fafafa.core.time.duration,
  fafafa.core.time.instant,
  // 时钟与便捷函数
  fafafa.core.time.clock,
  // 其他功能模块
  // TODO: timer 暂时禁用，待 sync 模块修复后恢复
  // fafafa.core.time.timer,
  fafafa.core.time.stopwatch,
  fafafa.core.time.date,
  fafafa.core.time.timeofday,
  // 构建器与辅助 API
  fafafa.core.time.builders,
  // 格式化与解析
  fafafa.core.time.format,
  fafafa.core.time.parse,
  fafafa.core.time.timeout,
  // 新增：时区与日期时间类型 (v1.1.0)
  fafafa.core.time.offset,
  fafafa.core.time.zoneddatetime,
  fafafa.core.time.naivedatetime,
  fafafa.core.time.isoweek,
  // 新增：日历周期类型 (v1.2.0)
  fafafa.core.time.period;

type
  // 直接转出常用类型，便于使用方只依赖本门面单元
  TDuration = fafafa.core.time.duration.TDuration;
  TInstant  = fafafa.core.time.instant.TInstant;
  
  // 日期与时间组件
  TDate      = fafafa.core.time.date.TDate;
  TTimeOfDay = fafafa.core.time.timeofday.TTimeOfDay;
  
  // 新增：构建器类型 (v1.2.0)
  TDateBuilder     = fafafa.core.time.builders.TDateBuilder;
  TTimeBuilder     = fafafa.core.time.builders.TTimeBuilder;
  TDateTimeBuilder = fafafa.core.time.builders.TDateTimeBuilder;
  
  // 新增时区与日期时间类型 (v1.1.0)
  TUtcOffset      = fafafa.core.time.offset.TUtcOffset;
  TZonedDateTime  = fafafa.core.time.zoneddatetime.TZonedDateTime;
  TNaiveDateTime  = fafafa.core.time.naivedatetime.TNaiveDateTime;
  TIsoWeek        = fafafa.core.time.isoweek.TIsoWeek;
  
  // 新增：日历周期和范围类型 (v1.2.0)
  TPeriod    = fafafa.core.time.period.TPeriod;
  TDateRange = fafafa.core.time.date.TDateRange;
  TTimeRange = fafafa.core.time.timeofday.TTimeRange;

  // 时钟接口
  IMonotonicClock = fafafa.core.time.clock.IMonotonicClock;
  ISystemClock    = fafafa.core.time.clock.ISystemClock;
  IClock          = fafafa.core.time.clock.IClock;
  IFixedClock     = fafafa.core.time.clock.IFixedClock;

  // 便捷过程类型
  // TProc alias not available in base; define a local fallback
  TProc = procedure;

  // 异常别名
  ETimeError         = fafafa.core.time.base.ETimeError;
  ETimeoutError      = fafafa.core.time.base.ETimeoutError;
  EInvalidTimeFormat = fafafa.core.time.base.EInvalidTimeFormat;
  ETimeOverflow      = fafafa.core.time.base.ETimeOverflow;

  // Result 风格错误处理 (v1.3.0)
  TTimeErrorKind = fafafa.core.time.base.TTimeErrorKind;
  TDurationResult = fafafa.core.time.base.TDurationResult;
  TInstantResult  = fafafa.core.time.base.TInstantResult;

  // 超时相关
  TDeadline        = fafafa.core.time.timeout.TDeadline;
  {$IFDEF FAFAFA_TIMEOUT_EXPERIMENTAL}
  TTimeoutStrategy = fafafa.core.time.timeout.TTimeoutStrategy;
  TTimeoutState    = fafafa.core.time.timeout.TTimeoutState;
  {$ENDIF}

const
  // Module version information
  TIME_MODULE_VERSION = '1.3.0';
  TIME_MODULE_VERSION_MAJOR = 1;
  TIME_MODULE_VERSION_MINOR = 3;
  TIME_MODULE_VERSION_PATCH = 0;
  TIME_MODULE_BUILD_DATE = '2025-12-04';

// Result 风格构造器（委托 base 单元）
function TryDurationFromSec(const ASec: Int64): TDurationResult; inline;
function TryDurationFromMs(const AMs: Int64): TDurationResult; inline;
function TryDurationFromUs(const AUs: Int64): TDurationResult; inline;
function TryDurationFromNs(const ANs: Int64): TDurationResult; inline;
function TryInstantAdd(const AInstant: TInstant; const ADur: TDuration): TInstantResult; inline;
function TryInstantSub(const AInstant: TInstant; const ADur: TDuration): TInstantResult; inline;
function TryDurationAdd(const A, B: TDuration): TDurationResult; inline;
function TryDurationSub(const A, B: TDuration): TDurationResult; inline;
function TryDurationMul(const A: TDuration; const Factor: Int64): TDurationResult; inline;
function TryDurationDiv(const A: TDuration; const Divisor: Int64): TDurationResult; inline;

function DefaultMonotonicClock: IMonotonicClock; inline;
function DefaultSystemClock: ISystemClock; inline;
function DefaultClock: IClock; inline;

// 便捷时间函数（委托 clock 单元）
procedure SleepFor(const D: TDuration); inline;
procedure SleepUntil(const T: TInstant); inline;
function NowInstant: TInstant; inline;
function NowUTC: TDateTime; inline;
function NowLocal: TDateTime; inline;
function NowUnixMs: Int64; inline;
function NowUnixNs: Int64; inline;

// 计时便捷函数
function TimeIt(const P: TProc): TDuration; inline;

// 新增便捷函数 (v1.2.0) - 快速获取当前日期时间
function NowDate: TDate; inline;
function NowTime: TTimeOfDay; inline;
function NowZoned: TZonedDateTime; inline;
function NowNaive: TNaiveDateTime; inline;

// 构建器便捷函数（通过门面直接访问 Builder 模式）
function DateBuilder: TDateBuilder; inline;
function TimeBuilder: TTimeBuilder; inline;
function DateTimeBuilder: TDateTimeBuilder; inline;

// Formatting helpers exposed via facade
function FormatDurationHuman(const ADuration: TDuration): string; inline;
procedure SetDurationFormatUseAbbr(AUseAbbr: Boolean); inline;
procedure SetDurationFormatSecPrecision(APrecision: Integer); inline;

// 便捷扩展：通过类型帮助器补充额外 API
type
  TInstantHelper = type helper for TInstant
  public
    // 非负差值：如果 Older 更大则返回 0
    function NonNegativeDiff(const Older: TInstant): TDuration; inline;
    
    // v1.2.0: 快速方法 - 计算经过时间
    {** 计算从 Self 到当前时刻的经过时间 *}
    function Elapsed: TDuration; inline;
    {** DurationSince 别名，等同 Since *}
    function DurationSince(const Older: TInstant): TDuration; inline;
  end;

implementation

function DefaultMonotonicClock: IMonotonicClock; inline;
begin
  Result := fafafa.core.time.clock.DefaultMonotonicClock;
end;

function DefaultSystemClock: ISystemClock; inline;
begin
  Result := fafafa.core.time.clock.DefaultSystemClock;
end;

function DefaultClock: IClock; inline;
begin
  Result := fafafa.core.time.clock.DefaultClock;
end;

procedure SleepFor(const D: TDuration); inline;
begin
  fafafa.core.time.clock.SleepFor(D);
end;

procedure SleepUntil(const T: TInstant); inline;
begin
  fafafa.core.time.clock.SleepUntil(T);
end;

function NowInstant: TInstant; inline;
begin
  Result := fafafa.core.time.clock.NowInstant;
end;

function NowUTC: TDateTime; inline;
begin
  Result := fafafa.core.time.clock.NowUTC;
end;

function NowLocal: TDateTime; inline;
begin
  Result := fafafa.core.time.clock.NowLocal;
end;

function NowUnixMs: Int64; inline;
begin
  Result := fafafa.core.time.clock.NowUnixMs;
end;

function NowUnixNs: Int64; inline;
begin
  Result := fafafa.core.time.clock.NowUnixNs;
end;

function TimeIt(const P: TProc): TDuration; inline;
begin
  Result := fafafa.core.time.clock.TimeIt(P);
end;

// 新增便捷函数实现 (v1.2.0)

function NowDate: TDate; inline;
begin
  Result := TDate.FromDateTime(Now);
end;

function NowTime: TTimeOfDay; inline;
begin
  Result := TTimeOfDay.Now;
end;

function NowZoned: TZonedDateTime; inline;
begin
  Result := TZonedDateTime.NowLocal;
end;

function NowNaive: TNaiveDateTime; inline;
begin
  Result := TNaiveDateTime.Now;
end;

function DateBuilder: TDateBuilder; inline;
begin
  Result := fafafa.core.time.builders.DateBuilder;
end;

function TimeBuilder: TTimeBuilder; inline;
begin
  Result := fafafa.core.time.builders.TimeBuilder;
end;

function DateTimeBuilder: TDateTimeBuilder; inline;
begin
  Result := fafafa.core.time.builders.DateTimeBuilder;
end;

function FormatDurationHuman(const ADuration: TDuration): string; inline;
begin
  Result := fafafa.core.time.format.FormatDurationHuman(ADuration);
end;

// Result 风格构造器实现
function TryDurationFromSec(const ASec: Int64): TDurationResult; inline;
begin
  Result := fafafa.core.time.base.TryDurationFromSec(ASec);
end;

function TryDurationFromMs(const AMs: Int64): TDurationResult; inline;
begin
  Result := fafafa.core.time.base.TryDurationFromMs(AMs);
end;

function TryDurationFromUs(const AUs: Int64): TDurationResult; inline;
begin
  Result := fafafa.core.time.base.TryDurationFromUs(AUs);
end;

function TryDurationFromNs(const ANs: Int64): TDurationResult; inline;
begin
  Result := fafafa.core.time.base.TryDurationFromNs(ANs);
end;

function TryInstantAdd(const AInstant: TInstant; const ADur: TDuration): TInstantResult; inline;
begin
  Result := fafafa.core.time.base.TryInstantAdd(AInstant, ADur);
end;

function TryInstantSub(const AInstant: TInstant; const ADur: TDuration): TInstantResult; inline;
begin
  Result := fafafa.core.time.base.TryInstantSub(AInstant, ADur);
end;

function TryDurationAdd(const A, B: TDuration): TDurationResult; inline;
begin
  Result := fafafa.core.time.base.TryDurationAdd(A, B);
end;

function TryDurationSub(const A, B: TDuration): TDurationResult; inline;
begin
  Result := fafafa.core.time.base.TryDurationSub(A, B);
end;

function TryDurationMul(const A: TDuration; const Factor: Int64): TDurationResult; inline;
begin
  Result := fafafa.core.time.base.TryDurationMul(A, Factor);
end;

function TryDurationDiv(const A: TDuration; const Divisor: Int64): TDurationResult; inline;
begin
  Result := fafafa.core.time.base.TryDurationDiv(A, Divisor);
end;

procedure SetDurationFormatUseAbbr(AUseAbbr: Boolean); inline;
begin
  fafafa.core.time.format.SetDurationFormatUseAbbr(AUseAbbr);
end;

procedure SetDurationFormatSecPrecision(APrecision: Integer); inline;
begin
  fafafa.core.time.format.SetDurationFormatSecPrecision(APrecision);
end;

{ TInstantHelper }

function TInstantHelper.NonNegativeDiff(const Older: TInstant): TDuration;
var d: TDuration;
begin
  d := Self.Diff(Older);
  if d.IsNegative then Result := TDuration.Zero else Result := d;
end;

function TInstantHelper.Elapsed: TDuration;
begin
  // 计算从 Self 到当前时刻的经过时间
  Result := fafafa.core.time.clock.NowInstant.Since(Self);
end;

function TInstantHelper.DurationSince(const Older: TInstant): TDuration;
begin
  Result := Self.Since(Older);
end;

end.






