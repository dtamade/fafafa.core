unit fafafa.core.time.tick.hardware.armv7a;


{
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.tick.hardware.armv7a - ARMv7-A 硬件计时器实现

📖 概述：
  ARMv7-A 平台的硬件计时器（Architected Generic Timer）实现。
  *仅在* 构建期明确启用（CPUARM + ARMV7A + FAFAFA_USE_ARCH_TIMER）时，使用
  CNTPCT（当前计数）/ CNTFRQ（频率 Hz）。未启用或不可用时，本类标记为
  不可用，Tick() 返回 0。

⚠️ 重要：
  - 很多内核配置下，用户态读取 CNTPCT/CNTFRQ 会触发非法指令（SIGILL）。
    Pascal 的 try..except 抓不住信号，因此本单元不做“探测式”读取。
    是否启用由构建期宏控制，确保在你的目标上是允许的再开启 FAFAFA_USE_ARCH_TIMER。
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

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

{$IFNDEF FPC}
  {$MESSAGE ERROR 'Delphi/ARMv7 不支持 inline asm，请改用外部 .o/.obj 或无汇编实现'}
{$ENDIF}

{$if not (defined(CPUARM) and defined(ARMV7A))}
  {$MESSAGE ERROR 'This unit is for ARMv7-A only.'}
{$ifend}

uses
  fafafa.core.time.tick.base;

type
  { TARMV7AHardwareTick }
  TARMV7AHardwareTick = class(TTick)
  protected
    procedure Initialize(out aResolution: UInt64; out aIsMonotonic: Boolean; out aTickType: TTickType); override;
  public
    function Tick: UInt64; override;
  end;

function GetHardwareResolution: UInt64; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
function GetTick: UInt64; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
function MakeTick: ITick; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

implementation

uses
  fafafa.core.atomic,
  fafafa.core.time.cpu
  {$IFDEF MSWINDOWS}
  , fafafa.core.time.tick.windows
  {$ELSEIF DEFINED(DARWIN)}
  , fafafa.core.time.tick.darwin
  {$ELSEIF DEFINED(UNIX)}
  , fafafa.core.time.tick.unix
  {$ELSE}
    {$MESSAGE ERROR 'Unsupported platform for fafafa.core.time.tick.hardware.armv7a'}
  {$ENDIF};

{$if defined(CPUARM) and defined(ARMV7A) and defined(FAFAFA_USE_ARCH_TIMER)}
function ReadCNTPCT: UInt64; assembler; nostackframe;
asm
  isb                               // 指令同步屏障：读前序列化
  mrrc p15, 0, r0, r1, c14          // r1:r0 = CNTPCT[63:0]
end;

function ReadCNTFRQ: UInt64; assembler; nostackframe;
asm
  // 规范为 32-bit；扩展为 64-bit 返回
  mrc p15, 0, r0, c14, c0, 0        // r0 = CNTFRQ (lower 32)
  mov r1, #0                        // r1 = 0 -> 组合成 64-bit
end;
{$else}
function ReadCNTPCT: UInt64; inline;
begin
  Result := 0;
end;

function ReadCNTFRQ: UInt64; inline;
begin
  Result := 0;
end;
{$endif}

var
  GHardwareResolution:     UInt64 = 0; // 频率（Hz）
  GHardwareResolutionOnce: Int32  = 0; // 0=未开始,1=进行中,2=完成

function CalibrateHardwareResolutionHz: UInt64;
var
  LStartCnt, LEndCnt: UInt64;
  LStartRef, LEndRef: UInt64;
  LDeltaCnt, LDeltaRef: UInt64;
  LRefResolution, LQuotient, LRemainder: UInt64;
  LTargetRef: UInt64;
begin
  // 参考时钟分辨率（Hz）
  LRefResolution := GetHDResolution;
  if LRefResolution = 0 then
    Exit(0);

  // 约 10ms 采样窗口（以参考时钟 tick 计）
  LTargetRef := LRefResolution div 100;
  if LTargetRef = 0 then
    LTargetRef := 1;

  // 对称采样：Ref→CNT / Ref→CNT
  LStartRef := GetHDTick;
  LStartCnt := ReadCNTPCT;
  if (LStartRef = 0) or (LStartCnt = 0) then
    Exit(0);

  repeat
    LEndRef := GetHDTick;
    LEndCnt := ReadCNTPCT;
    CpuRelax;
  until (LEndRef - LStartRef) >= LTargetRef;

  LDeltaRef := LEndRef - LStartRef;
  LDeltaCnt := LEndCnt - LStartCnt;
  if (LDeltaRef = 0) or (LDeltaCnt = 0) then
    Exit(0);

  // 频率：deltaCnt / (deltaRef / refHz) = deltaCnt * refHz / deltaRef
  LQuotient  := LDeltaCnt div LDeltaRef;
  LRemainder := LDeltaCnt - LQuotient * LDeltaRef;
  Result := LQuotient * LRefResolution + (LRemainder * LRefResolution) div LDeltaRef;
end;

function GetHardwareResolution: UInt64;
var
  LState, LExpected: Int32;
  LHz: UInt64;
begin
  // 快路径
  LState := atomic_load(GHardwareResolutionOnce, mo_acquire);
  if LState = 2 then
    Exit(GHardwareResolution);

  // 竞争初始化
  LExpected := 0;
  if atomic_compare_exchange(GHardwareResolutionOnce, LExpected, 1) then
  begin
    // 先尝试从 CNTFRQ 直接读取
    LHz := ReadCNTFRQ;
    if LHz = 0 then
      LHz := CalibrateHardwareResolutionHz;

    if LHz = 0 then
    begin
      // 失败回滚，让其他线程或下次调用重试
      atomic_store(GHardwareResolutionOnce, 0, mo_release);
      Exit(0);
    end;

    GHardwareResolution := LHz;
    atomic_store(GHardwareResolutionOnce, 2, mo_release);
    Result := LHz;
  end
  else
  begin
    // 等待；若中途回滚为 0，则尝试接手
    while True do
    begin
      LState := atomic_load(GHardwareResolutionOnce, mo_acquire);
      case LState of
        2: Exit(GHardwareResolution);
        0:
          begin
            LExpected := 0;
            if atomic_compare_exchange(GHardwareResolutionOnce, LExpected, 1) then
            begin
              LHz := ReadCNTFRQ;
              if LHz = 0 then
                LHz := CalibrateHardwareResolutionHz;

              if LHz = 0 then
              begin
                atomic_store(GHardwareResolutionOnce, 0, mo_release);
                Exit(0);
              end;

              GHardwareResolution := LHz;
              atomic_store(GHardwareResolutionOnce, 2, mo_release);
              Exit(LHz);
            end;
          end;
      else
        CpuRelax; // =1 进行中
      end;
    end;
  end;
end;

function GetTick: UInt64;
begin
  Result := ReadCNTPCT;
end;

function MakeTick: ITick;
begin
  Result := TARMV7AHardwareTick.Create;
end;

procedure TARMV7AHardwareTick.Initialize(out aResolution: UInt64; out aIsMonotonic: Boolean; out aTickType: TTickType);
begin
  {$IFDEF FAFAFA_USE_ARCH_TIMER}
  aIsMonotonic := True;             // 通用计时器单调递增（启用架构计时器时）
  {$ELSE}
  aIsMonotonic := False;            // 未启用架构计时器时不宣称单调
  {$ENDIF}
  aTickType    := ttHardware;  // 硬件计时器
  aResolution  := GetHardwareResolution;
  // 可选兜底：若 aResolution=0，可回退到参考时钟
  // if aResolution = 0 then aResolution := GetHDResolution;
end;

function TARMV7AHardwareTick.Tick: UInt64;
begin
  Result := GetTick;
end;

end.
