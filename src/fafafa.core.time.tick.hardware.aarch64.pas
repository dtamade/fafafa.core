unit fafafa.core.time.tick.hardware.aarch64;

{
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.tick.hardware.aarch64 - ARM64 硬件计时器实现

📖 概述：
  ARM64 平台的硬件计时器实现（基于 Architected System Counter）。
  使用 CNTVCT_EL0 / CNTFRQ_EL0 提供高精度、单调递增的计数。

⚠️ 重要：
  - 大多数主流 Linux/Android 内核默认允许 EL0 读取 CNTVCT_EL0/CNTFRQ_EL0。
    若目标系统禁用 EL0 访问，本单元不做“探测式读取”（try..except 无效），
    请在更高层做能力选择与回退（例如改用 clock_gettime）。
  - 本单元为“严格版”：仅在 CPUAARCH64 下可编译。非 AArch64 直接报错，避免误链接。

🔧 特性：
  • 读取 CNTVCT_EL0（64-bit 单调计数）
  • 读取 CNTFRQ_EL0（频率 Hz）
  • 读取前使用 ISB 序列化测量点
  • 无需校准

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731
──────────────────────────────────────────────────────────────
}

{$I fafafa.core.settings.inc}

{$IFNDEF CPUAARCH64}
  {$MESSAGE ERROR 'fafafa.core.time.tick.hardware.aarch64 仅支持 AArch64 (CPUAARCH64)。'}
{$ENDIF}

interface

uses
  fafafa.core.time.tick.base,
  fafafa.core.time.tick.hardware.base;

type
  TAARCH64HardwareTick = class(THardwareTick)
  strict private
    class var FAvailable: Boolean;
    class var FFrequency: UInt64;
    class var FInitialized: Boolean;
    class procedure EnsureInit; static;
  protected
    function GetHardwareResolution: UInt64; override;
  public
    function Tick: UInt64; {$IFDEF FAFAFA_CORE_INLINING}inline;{$ENDIF}

    class function IsAvailable: Boolean; static;
    class function Frequency: UInt64; static;
  end;

// ARM64 硬件计时器帮助函数（轻便转发）
function IsAvailable: Boolean;
function GetHardwareFrequency: UInt64;
function MakeTick: ITick;

implementation

{$IFDEF CPUAARCH64}
// 读取 CNTVCT_EL0（当前计数，64-bit）
// 在读取前使用 ISB 以获得更稳定的测量点。
// 返回值通过 x0（64-bit）传回，ABI 自然对齐。
function ReadCNTVCT_EL0: UInt64; assembler; nostackframe;
asm
  isb                           // 指令同步屏障
  mrs x0, cntvct_el0            // x0 = CNTVCT_EL0
end;

// 读取 CNTFRQ_EL0（频率 Hz，规范为 32-bit，但用 64-bit 返回）
// 读取前也加 ISB（可选，保持一致性）。
function ReadCNTFRQ_EL0: UInt64; assembler; nostackframe;
asm
  isb
  mrs x0, cntfrq_el0            // x0 = zero-extended CNTFRQ_EL0
end;
{$ENDIF}

{ TAARCH64HardwareTick }

class procedure TAARCH64HardwareTick.EnsureInit;
begin
  if FInitialized then Exit;
  FAvailable := False;
  FFrequency := 0;
  FFrequency := ReadCNTFRQ_EL0;
  FAvailable := (FFrequency <> 0);
  FInitialized := True;
end;

function TAARCH64HardwareTick.GetHardwareResolution: UInt64;
begin
  EnsureInit;
  Result := FFrequency;
end;

function TAARCH64HardwareTick.Tick: UInt64;
begin
  EnsureInit;
  if not FAvailable then
    Exit(0);
  Result := ReadCNTVCT_EL0;
end;

class function TAARCH64HardwareTick.IsAvailable: Boolean;
begin
  EnsureInit;
  Result := FAvailable;
end;

class function TAARCH64HardwareTick.Frequency: UInt64;
begin
  EnsureInit;
  Result := FFrequency;
end;

function IsAvailable: Boolean;
begin
  Result := TAARCH64HardwareTick.IsAvailable;
end;

function GetHardwareFrequency: UInt64;
begin
  Result := TAARCH64HardwareTick.Frequency;
end;

function MakeTick: ITick;
begin
  Result := TAARCH64HardwareTick.Create;
end;

initialization
  TAARCH64HardwareTick.FAvailable := False;
  TAARCH64HardwareTick.FFrequency := 0;
  TAARCH64HardwareTick.FInitialized := False;

end.
