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
  {$IF DEFINED(CPUI386) OR DEFINED(CPUX86)}
  , fafafa.core.time.tick.hardware.x86
  {$ELSEIF DEFINED(CPUX86_64)}
  , fafafa.core.time.tick.hardware.x86_64
  {$ELSEIF DEFINED(CPUAARCH64) AND DEFINED(FAFAFA_USE_ARCH_TIMER)}
  , fafafa.core.time.tick.hardware.aarch64
  {$ELSEIF DEFINED(CPURISCV64)}
  , fafafa.core.time.tick.hardware.riscv64
  {$ELSEIF DEFINED(CPURISCV32)}
  , fafafa.core.time.tick.hardware.riscv32
  {$ELSEIF DEFINED(CPUARM) AND DEFINED(ARMV7A)}
  , fafafa.core.time.tick.hardware.armv7a
  {$ENDIF}
  ;


function IsAvailable: Boolean; inline;
function MakeTick: ITick;

implementation

function IsAvailable: Boolean;
begin
  {$IF DEFINED(CPUX86_64) OR DEFINED(CPUI386)}
    Result := True;
  {$ELSEIF DEFINED(CPUAARCH64) AND DEFINED(FAFAFA_USE_ARCH_TIMER)}
    Result := True;
  {$ELSEIF DEFINED(CPUARM) AND DEFINED(ARMV7A) AND DEFINED(FAFAFA_USE_ARCH_TIMER)}
    Result := True;
  {$ELSEIF DEFINED(CPURISCV32) AND (DEFINED(FAFAFA_CORE_USE_RISCV_TIME_CSR) OR DEFINED(FAFAFA_CORE_USE_RISCV_CYCLE_CSR))}
    Result := True;
  {$ELSEIF DEFINED(CPURISCV64) AND (DEFINED(FAFAFA_CORE_USE_RISCV_TIME_CSR) OR DEFINED(FAFAFA_CORE_USE_RISCV_CYCLE_CSR))}
    Result := True;
  {$ELSE}
    Result := False;
  {$ENDIF}
end;

function MakeTick: ITick;
begin
  {$IF DEFINED(CPUI386) OR DEFINED(CPUX86)}
    Result := fafafa.core.time.tick.hardware.x86.MakeTick;
  {$ELSEIF DEFINED(CPUX86_64)}
    Result := fafafa.core.time.tick.hardware.x86_64.MakeTick;
  {$ELSEIF DEFINED(CPUAARCH64)}
    {$IFDEF FAFAFA_USE_ARCH_TIMER}
      Result := fafafa.core.time.tick.hardware.aarch64.MakeTick;
    {$ELSE}
      raise ETickNotAvailable.Create('AArch64 hardware tick requires FAFAFA_USE_ARCH_TIMER');
    {$ENDIF}
  {$ELSEIF DEFINED(CPURISCV64)}
    {$IF DEFINED(FAFAFA_CORE_USE_RISCV_TIME_CSR) OR DEFINED(FAFAFA_CORE_USE_RISCV_CYCLE_CSR)}
      Result := fafafa.core.time.tick.hardware.riscv64.MakeTick;
    {$ELSE}
      raise ETickNotAvailable.Create('RISC-V 64 hardware tick requires FAFAFA_CORE_USE_RISCV_TIME_CSR or FAFAFA_CORE_USE_RISCV_CYCLE_CSR');
    {$ENDIF}
  {$ELSEIF DEFINED(CPURISCV32)}
    {$IF DEFINED(FAFAFA_CORE_USE_RISCV_TIME_CSR) OR DEFINED(FAFAFA_CORE_USE_RISCV_CYCLE_CSR)}
      Result := fafafa.core.time.tick.hardware.riscv32.MakeTick;
    {$ELSE}
      raise ETickNotAvailable.Create('RISC-V 32 hardware tick requires FAFAFA_CORE_USE_RISCV_TIME_CSR or FAFAFA_CORE_USE_RISCV_CYCLE_CSR');
    {$ENDIF}
  {$ELSEIF DEFINED(CPUARM) AND DEFINED(ARMV7A)}
    {$IFDEF FAFAFA_USE_ARCH_TIMER}
      Result := fafafa.core.time.tick.hardware.armv7a.MakeTick;
    {$ELSE}
      raise ETickNotAvailable.Create('ARMv7-A hardware tick requires FAFAFA_USE_ARCH_TIMER');
    {$ENDIF}
  {$ELSE}
    raise ETickNotAvailable.Create('Hardware tick is not supported on this architecture');
  {$ENDIF}
end;

end.