unit fafafa.core.time.tick.hardware.armv7a;

{
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.tick.hardware.armv7a - ARMv7-A 硬件计时器实现

📖 概述：
  ARMv7-A 平台的硬件计时器（Architected Generic Timer）实现。
  *仅在* 构建期明确启用（CPUARM + ARMV7A + USE_ARCH_TIMER）时，使用
  CNTPCT（当前计数）/ CNTFRQ（频率 Hz）。未启用或不可用时，本类标记为
  不可用，Tick() 返回 0。

⚠️ 重要：
  - 很多内核配置下，用户态读取 CNTPCT/CNTFRQ 会触发非法指令（SIGILL）。
    Pascal 的 try..except 抓不住信号，因此本单元不做“探测式”读取。
    是否启用由构建期宏控制，确保在你的目标上是允许的再开启 USE_ARCH_TIMER。
  - 如果需要自动回退到 clock_gettime(CLOCK_MONOTONIC_RAW)，建议在上层工厂单元处理。

🔧 特性：
  • 读取 CNTPCT（64-bit）
  • 读取 CNTFRQ（频率 Hz，32-bit → 64-bit）
  • 单调递增（若可用）
  • 轻量实现，无校准

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
  fafafa.core.time.tick.hardware.base;

type
  // ARMv7-A 硬件计时器
  TARMV7AHardwareTick = class(THardwareTick)
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

function MakeTick: ITick;

implementation

{$if defined(CPUARM) and defined(ARMV7A) and defined(USE_ARCH_TIMER)}
// 读取 CNTPCT（当前计数，64 位）
// 说明：在读取前插入 ISB，确保测量点序列化更稳定。
function ReadCNTPCT: UInt64; assembler; nostackframe;
asm
  isb                               // 指令同步屏障
  mrrc p15, 0, r0, r1, c14          // r1:r0 = CNTPCT[63:0]
end;

// 读取 CNTFRQ（频率 Hz，规范为 32-bit；此处扩展为 64-bit 返回）
// 注意：返回 64-bit 时需要把 r1 清 0。
function ReadCNTFRQ: UInt64; assembler; nostackframe;
asm
  mrc p15, 0, r0, c14, c0, 0        // r0 = CNTFRQ (lower 32)
  mov r1, #0                        // r1 = 0 -> 组合成 64-bit
end;
{$else} // 非 ARMv7-A 或未启用 USE_ARCH_TIMER：提供安全的桩实现
function ReadCNTPCT: UInt64; inline;
begin
  Result := 0;
end;

function ReadCNTFRQ: UInt64; inline;
begin
  Result := 0;
end;
{$endif}

{ TARMV7AHardwareTick }

class procedure TARMV7AHardwareTick.EnsureInit;
begin
  if FInitialized then Exit;
  FAvailable := False;
  FFrequency := 0;
{$if defined(CPUARM) and defined(ARMV7A) and defined(USE_ARCH_TIMER)}
  FFrequency := ReadCNTFRQ;
  FAvailable := (FFrequency <> 0);
{$endif}
  FInitialized := True;
end;

function TARMV7AHardwareTick.GetHardwareResolution: UInt64;
begin
  EnsureInit;
  Result := FFrequency;
end;

function TARMV7AHardwareTick.Tick: UInt64;
begin
  EnsureInit;
  if not FAvailable then
    Exit(0); // 也可改为 raise ENotAvailable.Create('ARMv7-A timer not available');
  Result := ReadCNTPCT;
end;

class function TARMV7AHardwareTick.IsAvailable: Boolean;
begin
  EnsureInit;
  Result := FAvailable;
end;

class function TARMV7AHardwareTick.Frequency: UInt64;
begin
  EnsureInit;
  Result := FFrequency;
end;

function MakeTick: ITick;
begin
  Result := TARMV7AHardwareTick.Create;
end;

initialization
  TARMV7AHardwareTick.FAvailable := False;
  TARMV7AHardwareTick.FFrequency := 0;
  TARMV7AHardwareTick.FInitialized := False;

end.
