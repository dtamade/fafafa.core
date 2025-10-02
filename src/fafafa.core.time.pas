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
  // 基础与核心类型
  fafafa.core.time.base,
  fafafa.core.time.duration,
  fafafa.core.time.instant,
  // 时钟与便捷函数
  fafafa.core.time.clock,
  // 其他功能模块
  fafafa.core.time.timer,
  fafafa.core.time.stopwatch,
  fafafa.core.time.date,
  fafafa.core.time.timeofday,
  fafafa.core.time.format,
  fafafa.core.time.parse,
  fafafa.core.time.timeout;

type
  // 直接转出常用类型，便于使用方只依赖本门面单元
  TDuration = fafafa.core.time.duration.TDuration;
  TInstant  = fafafa.core.time.instant.TInstant;

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

  // 超时相关
  TDeadline        = fafafa.core.time.timeout.TDeadline;
  {$IFDEF FAFAFA_TIMEOUT_EXPERIMENTAL}
  TTimeoutStrategy = fafafa.core.time.timeout.TTimeoutStrategy;
  TTimeoutState    = fafafa.core.time.timeout.TTimeoutState;
  {$ENDIF}
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

function FormatDurationHuman(const ADuration: TDuration): string; inline;
begin
  Result := fafafa.core.time.format.FormatDurationHuman(ADuration);
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

end.






