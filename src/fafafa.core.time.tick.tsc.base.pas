unit fafafa.core.time.tick.tsc.base;

{
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.tick.tsc.base - TSC 基础定义

📖 概述：
  TSC (Time Stamp Counter) 硬件计时器的基础接口和类型定义。
  所有平台实现都基于这些定义。

🔧 特性：
  • 跨平台 TSC 接口定义
  • 硬件计时器抽象
  • 频率校准接口
  • 可用性检测接口

📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731
──────────────────────────────────────────────────────────────
}

{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.time.tick.base;

type
  // TSC 硬件计时器基类
  TTSCTickBase = class(TTick)
  protected
    FTSCFrequency: UInt64;        // TSC 频率 (Hz)
    FIsInvariantTSC: Boolean;     // 是否支持 Invariant TSC
    FIsAvailable: Boolean;        // TSC 是否可用

    // 子类必须实现的平台特定方法
    function DoDetectTSCSupport: Boolean; virtual; abstract;
    function DoCalibrateTSCFrequency: UInt64; virtual; abstract;
    function DoReadTSC: UInt64; virtual; abstract;

    // 初始化 TSC（在构造函数中调用）
    procedure InitializeTSC; virtual;

  public
    constructor Create; override;

    // TSC 特定属性
    property TSCFrequency:   UInt64  read FTSCFrequency;
    property IsInvariantTSC: Boolean read FIsInvariantTSC;
    property IsAvailable:    Boolean read FIsAvailable;

    // 实现 TTick 的抽象方法
    function DoGetCurrentTick: UInt64; override;
    function DoGetResolution: UInt64; override;
    function DoTicksToDuration(const ATicks: UInt64): TDuration; override;
    function DoDurationToTicks(const D: TDuration): UInt64; override;
    function DoIsMonotonic: Boolean; override;
    function DoIsHighResolution: Boolean; override;
    function DoGetMinimumInterval: TDuration; override;
  end;

implementation

{ TTSCTickBase }

constructor TTSCTickBase.Create;
begin
  InitializeTSC;
  inherited Create;

  // 如果 TSC 不可用，抛出异常
  if not FIsAvailable then
    raise ETickNotAvailable.Create('TSC is not available on this system');
end;

procedure TTSCTickBase.InitializeTSC;
begin
  FIsAvailable := False;
  FIsInvariantTSC := False;
  FTSCFrequency := 0;

  // 检测 TSC 支持
  FIsInvariantTSC := DoDetectTSCSupport;
  if FIsInvariantTSC then
  begin
    FTSCFrequency := DoCalibrateTSCFrequency;
    FIsAvailable := FTSCFrequency > 0;
  end;
end;

function TTSCTickBase.DoGetCurrentTick: UInt64;
begin
  if not FIsAvailable then
  begin
    Result := 0;
    Exit;
  end;

  Result := DoReadTSC;
end;

function TTSCTickBase.DoGetResolution: UInt64;
begin
  Result := FTSCFrequency;
end;

function TTSCTickBase.DoTicksToDuration(const ATicks: UInt64): TDuration;
var
  LNanos: UInt64;
begin
  if FTSCFrequency = 0 then
  begin
    Result := TDuration.Zero;
    Exit;
  end;

  // 转换为纳秒，注意避免溢出
  LNanos := (ATicks * 1000000000) div FTSCFrequency;
  Result := TDuration.FromNs(LNanos);
end;

function TTSCTickBase.DoDurationToTicks(const D: TDuration): UInt64;
begin
  if FTSCFrequency = 0 then
  begin
    Result := 0;
    Exit;
  end;

  Result := (D.AsNs * FTSCFrequency) div 1000000000;
end;

function TTSCTickBase.DoIsMonotonic: Boolean;
begin
  Result := FIsInvariantTSC;
end;

function TTSCTickBase.DoIsHighResolution: Boolean;
begin
  Result := FIsAvailable;
end;

function TTSCTickBase.DoGetMinimumInterval: TDuration;
begin
  if FTSCFrequency > 0 then
    Result := DoTicksToDuration(1)
  else
    Result := TDuration.Zero;
end;

end.