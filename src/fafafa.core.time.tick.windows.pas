unit fafafa.core.time.tick.windows;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}

{$I fafafa.core.settings.inc}

interface

{$IFDEF MSWINDOWS}

uses
  Windows,
  fafafa.core.time.tick.base,
  fafafa.core.time.tick.tsc;

type
  // Windows QueryPerformanceCounter 实现
  TWindowsHighPrecisionTick = class(TTick)
  private
    FFrequency: Int64;
  protected
    // 实现抽象方法
    function DoGetCurrentTick: UInt64; override;
    function DoGetResolution: UInt64; override;
    function DoTicksToDuration(const ATicks: UInt64): TDuration; override;
    function DoDurationToTicks(const D: TDuration): UInt64; override;
    function DoIsMonotonic: Boolean; override;
    function DoIsHighResolution: Boolean; override;
  public
    constructor Create; override;
  end;

  // Windows GetTickCount64 标准实现
  TWindowsStandardTick = class(TTick)
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

// Windows 平台工厂函数
function CreateWindowsTick(const AType: TTickType): ITick;
function IsWindowsTickTypeAvailable(const AType: TTickType): Boolean;

{$ENDIF} // MSWINDOWS

implementation

{$IFDEF MSWINDOWS}

{ TWindowsHighPrecisionTick }

constructor TWindowsHighPrecisionTick.Create;
begin
  QueryPerformanceFrequency(FFrequency);
  inherited Create;
end;

function TWindowsHighPrecisionTick.DoGetCurrentTick: UInt64;
var
  counter: Int64;
begin
  QueryPerformanceCounter(counter);
  Result := UInt64(counter);
end;

function TWindowsHighPrecisionTick.DoGetResolution: UInt64;
begin
  Result := UInt64(FFrequency);
end;

function TWindowsHighPrecisionTick.DoTicksToDuration(const ATicks: UInt64): TDuration;
var
  nanos: UInt64;
begin
  // 转换为纳秒
  nanos := (ATicks * 1000000000) div UInt64(FFrequency);
  Result := TDuration.FromNs(nanos);
end;

function TWindowsHighPrecisionTick.DoDurationToTicks(const D: TDuration): UInt64;
begin
  Result := (D.AsNs * UInt64(FFrequency)) div 1000000000;
end;

function TWindowsHighPrecisionTick.DoIsMonotonic: Boolean;
begin
  Result := True;
end;

function TWindowsHighPrecisionTick.DoIsHighResolution: Boolean;
begin
  Result := True;
end;

{ TWindowsStandardTick }

function TWindowsStandardTick.DoGetCurrentTick: UInt64;
begin
  Result := GetTickCount64;
end;

function TWindowsStandardTick.DoGetResolution: UInt64;
begin
  Result := 1000; // 1000 ticks per second (millisecond resolution)
end;

function TWindowsStandardTick.DoTicksToDuration(const ATicks: UInt64): TDuration;
begin
  // GetTickCount64 返回毫秒
  Result := TDuration.FromMs(ATicks);
end;

function TWindowsStandardTick.DoDurationToTicks(const D: TDuration): UInt64;
begin
  Result := D.AsMs;
end;

function TWindowsStandardTick.DoIsMonotonic: Boolean;
begin
  Result := True;
end;

function TWindowsStandardTick.DoIsHighResolution: Boolean;
begin
  Result := False;
end;

function TWindowsStandardTick.DoGetMinimumInterval: TDuration;
begin
  Result := TDuration.Millisecond;
end;

// Windows 工厂函数

function CreateWindowsTick(const AType: TTickType): ITick;
begin
  case AType of
    ttBest:
      // 优先选择 TSC，如果不可用则使用 QueryPerformanceCounter
      if IsTSCAvailable then
        Result := CreateTSCTick
      else
        Result := TWindowsHighPrecisionTick.Create;
    ttHighPrecision:
      Result := TWindowsHighPrecisionTick.Create;
    ttStandard, ttSystem:
      Result := TWindowsStandardTick.Create;
    ttTSC:
      Result := CreateTSCTick;
  else
    raise ETickInvalidArgument.CreateFmt('Unsupported tick type: %d', [Ord(AType)]);
  end;
end;

function IsWindowsTickTypeAvailable(const AType: TTickType): Boolean;
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

{$ENDIF} // MSWINDOWS

end.