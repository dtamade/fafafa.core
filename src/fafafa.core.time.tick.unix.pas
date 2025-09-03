unit fafafa.core.time.tick.unix;

{
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.tick.unix - Unix Tick 实现

📖 概述：
  Unix 系统（Linux、macOS、FreeBSD 等）的高精度时间测量实现。
  支持 clock_gettime、mach_absolute_time 等平台特定 API。

🔧 特性：
  • Linux: clock_gettime(CLOCK_MONOTONIC)
  • macOS: mach_absolute_time()
  • FreeBSD: clock_gettime(CLOCK_MONOTONIC)
  • 自动选择最佳可用实现

📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731
──────────────────────────────────────────────────────────────
}

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}

{$I fafafa.core.settings.inc}

interface

{$IFNDEF MSWINDOWS}

uses
  {$IFDEF DARWIN}
  MacOSAll,
  {$ELSE}
  BaseUnix, Unix,
  {$ENDIF}
  fafafa.core.time.tick.base,
  fafafa.core.time.tick.tsc;

type
  {$IFDEF DARWIN}
  // macOS mach_absolute_time 实现
  TDarwinHighPrecisionTick = class(TTick)
  private
    FTimebaseInfo: mach_timebase_info_data_t;
  protected
    // 实现抽象方法
    function DoGetCurrentTick: UInt64; override;
    function DoGetResolution: UInt64; override;
    function DoTicksToDuration(const ATicks: UInt64): TDuration; override;
    function DoDurationToTicks(const D: TDuration): UInt64; override;
    function DoIsMonotonic: Boolean; override;
    function DoIsHighResolution: Boolean; override;
    function DoGetMinimumInterval: TDuration; override;
  public
    constructor Create; override;
  end;
  {$ELSE}
  // Linux/Unix clock_gettime 实现
  TUnixHighPrecisionTick = class(TTick)
  protected
    // 实现抽象方法
    function DoGetCurrentTick: UInt64; override;
    function DoGetResolution: UInt64; override;
    function DoTicksToDuration(const ATicks: UInt64): TDuration; override;
    function DoDurationToTicks(const D: TDuration): UInt64; override;
    function DoIsMonotonic: Boolean; override;
    function DoIsHighResolution: Boolean; override;
    function DoGetMinimumInterval: TDuration; override;
  end;
  {$ENDIF}

  // Unix 标准实现（gettimeofday）
  TUnixStandardTick = class(TTick)
  protected
    // 实现抽象方法
    function DoGetCurrentTick: UInt64; override;
    function DoGetResolution: UInt64; override;
    function DoTicksToDuration(const ATicks: UInt64): TDuration; override;
    function DoDurationToTicks(const D: TDuration): UInt64; override;
    function DoIsMonotonic: Boolean; override;
    function DoIsHighResolution: Boolean; override;
    function DoGetMinimumInterval: TDuration; override;
  end;

// Unix 平台工厂函数
function CreateUnixTick(const AType: TTickType): ITick;
function IsUnixTickTypeAvailable(const AType: TTickType): Boolean;

{$ENDIF} // NOT MSWINDOWS

implementation

{$IFNDEF MSWINDOWS}

uses
  SysUtils;

{$IFDEF DARWIN}
{ TDarwinHighPrecisionTick }

constructor TDarwinHighPrecisionTick.Create;
begin
  inherited Create;
  mach_timebase_info(@FTimebaseInfo);
end;

function TDarwinHighPrecisionTick.DoGetCurrentTick: UInt64;
begin
  Result := mach_absolute_time();
end;

function TDarwinHighPrecisionTick.DoGetResolution: UInt64;
begin
  // 返回每秒的 tick 数
  Result := 1000000000 * FTimebaseInfo.denom div FTimebaseInfo.numer;
end;

function TDarwinHighPrecisionTick.DoTicksToDuration(const ATicks: UInt64): TDuration;
var
  nanos: UInt64;
begin
  // 转换为纳秒
  nanos := ATicks * FTimebaseInfo.numer div FTimebaseInfo.denom;
  Result := TDuration.FromNs(nanos);
end;

function TDarwinHighPrecisionTick.DoDurationToTicks(const D: TDuration): UInt64;
begin
  Result := D.AsNs * FTimebaseInfo.denom div FTimebaseInfo.numer;
end;

function TDarwinHighPrecisionTick.DoIsMonotonic: Boolean;
begin
  Result := True;
end;

function TDarwinHighPrecisionTick.DoIsHighResolution: Boolean;
begin
  Result := True;
end;

function TDarwinHighPrecisionTick.DoGetMinimumInterval: TDuration;
begin
  Result := DoTicksToDuration(1);
end;

{$ELSE}
{ TUnixHighPrecisionTick }

function TUnixHighPrecisionTick.DoGetCurrentTick: UInt64;
var
  ts: timespec;
begin
  clock_gettime(CLOCK_MONOTONIC, @ts);
  Result := UInt64(ts.tv_sec) * 1000000000 + UInt64(ts.tv_nsec);
end;

function TUnixHighPrecisionTick.DoGetResolution: UInt64;
begin
  Result := 1000000000; // 纳秒精度，每秒 10^9 ticks
end;

function TUnixHighPrecisionTick.DoTicksToDuration(const ATicks: UInt64): TDuration;
begin
  // tick 就是纳秒
  Result := TDuration.FromNs(ATicks);
end;

function TUnixHighPrecisionTick.DoDurationToTicks(const D: TDuration): UInt64;
begin
  Result := D.AsNs;
end;

function TUnixHighPrecisionTick.DoIsMonotonic: Boolean;
begin
  Result := True;
end;

function TUnixHighPrecisionTick.DoIsHighResolution: Boolean;
begin
  Result := True;
end;

function TUnixHighPrecisionTick.DoGetMinimumInterval: TDuration;
begin
  Result := TDuration.Nanosecond;
end;
{$ENDIF}

{ TUnixStandardTick }

function TUnixStandardTick.DoGetCurrentTick: UInt64;
var
  tv: timeval;
begin
  fpgettimeofday(@tv, nil);
  Result := UInt64(tv.tv_sec) * 1000000 + UInt64(tv.tv_usec);
end;

function TUnixStandardTick.DoGetResolution: UInt64;
begin
  Result := 1000000; // 微秒精度，每秒 10^6 ticks
end;

function TUnixStandardTick.DoTicksToDuration(const ATicks: UInt64): TDuration;
begin
  // tick 是微秒
  Result := TDuration.FromUs(ATicks);
end;

function TUnixStandardTick.DoDurationToTicks(const D: TDuration): UInt64;
begin
  Result := D.AsUs;
end;

function TUnixStandardTick.DoIsMonotonic: Boolean;
begin
  Result := False; // gettimeofday 不是单调的
end;

function TUnixStandardTick.DoIsHighResolution: Boolean;
begin
  Result := False;
end;

function TUnixStandardTick.DoGetMinimumInterval: TDuration;
begin
  Result := TDuration.Microsecond;
end;

// Unix 工厂函数

function CreateUnixTick(const AType: TTickType): ITick;
begin
  case AType of
    ttBest:
      // 优先选择 TSC，如果不可用则使用平台默认高精度实现
      if IsTSCAvailable then
        Result := CreateTSCTick
      else
      begin
        {$IFDEF DARWIN}
        Result := TDarwinHighPrecisionTick.Create;
        {$ELSE}
        Result := TUnixHighPrecisionTick.Create;
        {$ENDIF}
      end;
    ttHighPrecision:
      {$IFDEF DARWIN}
      Result := TDarwinHighPrecisionTick.Create;
      {$ELSE}
      Result := TUnixHighPrecisionTick.Create;
      {$ENDIF}
    ttStandard, ttSystem:
      Result := TUnixStandardTick.Create;
    ttTSC:
      Result := CreateTSCTick;
  else
    raise ETickInvalidArgument.CreateFmt('Unsupported tick type: %d', [Ord(AType)]);
  end;
end;

function IsUnixTickTypeAvailable(const AType: TTickType): Boolean;
begin
  case AType of
    ttBest, ttStandard, ttHighPrecision, ttSystem:
      Result := True;
    ttTSC:
      Result := IsTSCAvailable;
  else
    Result := False;
  end;
end;

{$ENDIF} // NOT MSWINDOWS

end.