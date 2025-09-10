unit fafafa.core.time.tick.hardware.base;

{
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.tick.hardware.base - 硬件计时器基类

📖 概述：
  硬件计时器基类，提供 IHardwareTick 与频率/可用性状态。

🔧 特性：
  • 跨平台 TSC 硬件计时器
  • 自动选择平台实现
  • 统一的对外接口
  • 模块化架构设计

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

  THardwareTick = class(TTick)
  protected
    function  GetHardwareResolution: UInt64; virtual; abstract;
    procedure Initialize(out aResolution: UInt64; out aIsMonotonic: Boolean; out aTickType: TTickType); override;
  end;

  // 计数器与参考时钟读取函数类型（参考时钟需返回纳秒）
  TReadCounterFunc = function: UInt64;
  TReadRefNsFunc  = function: UInt64;

// 基于参考时钟（纳秒）校准计数器频率（Hz），默认窗口 10ms
function CalibrateFrequencyHzByRefNs(aReadCounter: TReadCounterFunc; aReadRefNs: TReadRefNsFunc; aWindowNs: UInt64 = 10000000): UInt64;

implementation

function CalibrateFrequencyHzByRefNs(aReadCounter: TReadCounterFunc; aReadRefNs: TReadRefNsFunc; aWindowNs: UInt64): UInt64;
var
  c0, c1: UInt64;
  r0, r1: UInt64;
  elapsedRef, elapsedCnt: UInt64;
begin
  Result := 0;
  if (not Assigned(aReadCounter)) or (not Assigned(aReadRefNs)) or (aWindowNs = 0) then Exit;

  c0 := aReadCounter();
  r0 := aReadRefNs();
  repeat
    r1 := aReadRefNs();
    elapsedRef := r1 - r0;
  until elapsedRef >= aWindowNs;
  c1 := aReadCounter();
  elapsedCnt := c1 - c0;

  if elapsedRef > 0 then
    Result := (elapsedCnt * NANOSECONDS_PER_SECOND) div elapsedRef;
end;

{ THardwareTick }

procedure THardwareTick.Initialize(out aResolution: UInt64; out aIsMonotonic: Boolean; out aTickType: TTickType);
begin
  aIsMonotonic := True;
  aTickType    := ttHardware;
  aResolution  := GetHardwareResolution;
end;

end.