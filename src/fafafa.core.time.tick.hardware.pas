unit fafafa.core.time.tick.hardware;

{
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.tick.hardware - 硬件计时器门面

📖 概述：
  硬件计时器模块的统一入口（x86 RDTSC / ARM System Counter）。
  重新导出各平台实现的公共接口与工厂。

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
  fafafa.core.time.tick.base
  {$IF DEFINED(CPUX86_64) OR DEFINED(CPUI386)}
  , fafafa.core.time.tick.hardware.x86
  {$ELSEIF DEFINED(CPUAARCH64)}
  , fafafa.core.time.tick.hardware.aarch64
  {$ELSEIF DEFINED(CPURISCV)}
  , fafafa.core.time.tick.hardware.riscv
  {$ELSEIF DEFINED(CPUARM) OR DEFINED(ARMV7A) OR DEFINED(USE_ARCH_TIMER)}
  , fafafa.core.time.tick.hardware.armv7a
  {$ELSE}
    {$MESSAGE ERROR 'Unsupported architecture'}
  {$ENDIF}
  ;


function IsAvailable: Boolean; inline;
function MakeTick: ITick;

implementation

function IsAvailable: Boolean;
begin
  {$IF DEFINED(CPUX86_64) OR DEFINED(CPUI386) OR
   DEFINED(CPUAARCH64)  OR DEFINED(CPURISCV) OR
   DEFINED(CPUARM) OR DEFINED(ARMV7A) OR DEFINED(USE_ARCH_TIMER)}
  Result := True;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function MakeTick: ITick;
begin
  {$IF DEFINED(CPUX86_64) OR DEFINED(CPUI386)}
  Result := fafafa.core.time.tick.hardware.x86.MakeTick;
  {$ELSEIF DEFINED(CPUAARCH64)}
  Result := fafafa.core.time.tick.hardware.aarch64.MakeTick;
  {$ELSEIF DEFINED(CPURISCV)}
  Result := fafafa.core.time.tick.hardware.riscv.MakeTick;
  {$ELSEIF DEFINED(CPUARM) OR DEFINED(ARMV7A) OR DEFINED(USE_ARCH_TIMER)}
  Result := fafafa.core.time.tick.hardware.armv7a.MakeTick;
  {$ELSE}
  raise ETickNotAvailable.Create('Hardware tick is not supported on this architecture');
  {$ENDIF}
end;

end.