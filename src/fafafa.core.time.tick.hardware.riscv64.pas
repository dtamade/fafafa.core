unit fafafa.core.time.tick.hardware.riscv64;

{
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.tick.hardware.riscv64 - riscv64 硬件计时器（聚合）

📖 概述：
  riscv64 硬件计时器聚合单元。引入基础实现与平台校准器，
  并导出统一的检测/频率查询与 ITick 实例工厂。

🔧 特性：
  • CSR 指令支持

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
  fafafa.core.time.tick.base,
  fafafa.core.time.tick.hardware.riscv.base
  {$IFDEF MSWINDOWS}
  , fafafa.core.time.tick.hardware.riscv.windows
  {$ENDIF}
  {$IFDEF UNIX}
  , fafafa.core.time.tick.hardware.riscv.unix
  {$ENDIF}
  {$IFDEF DARWIN}
  , fafafa.core.time.tick.hardware.x86.darwin
  {$ENDIF}
  ;

type
  TX86HardwareTick = fafafa.core.time.tick.hardware.x86.base.TX86HardwareTick;

function IsAvailable: Boolean;
function GetHardwareFrequency: UInt64;
function MakeTick: ITick;


implementation

function IsAvailable: Boolean;
begin
  Result := TX86HardwareTick.IsAvailable;
end;

function GetHardwareFrequency: UInt64;
begin
  Result := TX86HardwareTick.Frequency;
end;

function MakeTick: ITick;
begin
  Result := TX86HardwareTick.Create;
end;

end.