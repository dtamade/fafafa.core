unit fafafa.core.time.tick.hardware.aarch64;


{
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.tick.hardware.aarch64 - AArch64 硬件计时器

📖 概述：
  64位 ARM（AArch64）硬件计时器聚合单元。优先使用架构通用计时器：
  - CNTVCT_EL0：单调递增计数器（virtual count）
  - CNTFRQ_EL0：计数器频率（Hz）
  若频率寄存器不可用，则回退到参考高精度时钟进行校准。

🔧 特性：
  • 读取 CNTVCT_EL0 获取 Ticks（用户态可读，通常不陷阱）
  • 读取 CNTFRQ_EL0 获取频率；失败则自动校准
  • 并发安全的一次性初始化（CAS + acquire/release）
  • 平台分支与前述 x86/x86_64 单元一致（DARWIN 优先于 UNIX）

⚠️ 说明：
  - 本单元使用 FPC 的内联汇编。Delphi/ARM64 默认不支持内联汇编，
    将在编译期提示使用外部 .o/.obj 或无汇编实现。
──────────────────────────────────────────────────────────────
}

{$I fafafa.core.settings.inc}

{$if not (defined(CPUAARCH64) or defined(CPUARM64))}
  {$MESSAGE ERROR 'This unit is for 64-bit AArch64 only.'}
{$ifend}

interface

{$IFNDEF FPC}
  {$MESSAGE ERROR 'Delphi/ARM64 不支持 inline asm，请改用外部 .o/.obj 或无汇编实现（例如通过系统 API 读取计时器）'}
{$ENDIF}

uses
  fafafa.core.time.tick.base;

type
  { TAArch64HardwareTick }
  TAArch64HardwareTick = class(TTick)
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
    {$MESSAGE ERROR 'Unsupported platform for fafafa.core.time.tick.hardware.aarch64'}
  {$ENDIF};

{$IFDEF FPC}
  {$asmmode default} // AArch64 下使用 FPC 默认汇编语法
{$ENDIF}

var
  GHardwareResolution:     UInt64 = 0; // 频率（Hz）
  GHardwareResolutionOnce: Int32  = 0; // 0=未开始,1=进行中,2=完成

{========================  低层寄存器读取  ========================}

{$IF DEFINED(FPC) AND DEFINED(FAFAFA_USE_ARCH_TIMER)}
function ReadCNTVCT: UInt64; assembler; nostackframe;
asm
  isb                     // 确保之前的状态变化对本次读取可见
  mrs x0, cntvct_el0      // x0 <- 当前计数 (EL0 可见)
  // 可选更保守：在读后再序列化一次（默认不需要以降低开销）
  // isb
end;

function ReadCNTFRQ: UInt64; assembler; nostackframe;
asm
  // 频率通常不变；严格场景可在读前 isb（通过编译期开关启用）
  {$IFDEF FAFAFA_ARM_ISB_BEFORE_CNTFRQ}
  isb                     // 可选序列化（默认关闭以减少开销）
  {$ENDIF}
  mrs x0, cntfrq_el0      // x0 <- 频率（Hz）
end;
{$ELSE}
function ReadCNTVCT: UInt64; inline; begin Result := 0; end;
function ReadCNTFRQ: UInt64; inline; begin Result := 0; end;
{$ENDIF}

{========================  频率获取与校准  ========================}

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
  LStartCnt := ReadCNTVCT;
  if (LStartRef = 0) or (LStartCnt = 0) then
    Exit(0);

  repeat
    LEndRef := GetHDTick;
    LEndCnt := ReadCNTVCT;
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
    // 先尝试从 CNTFRQ_EL0 直接读取
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

{========================  ITick 接口实现  ========================}

function GetTick: UInt64;
begin
  Result := ReadCNTVCT;
end;

function MakeTick: ITick;
begin
  Result := TAArch64HardwareTick.Create;
end;

procedure TAArch64HardwareTick.Initialize(out aResolution: UInt64; out aIsMonotonic: Boolean; out aTickType: TTickType);
begin
  aIsMonotonic := True;             // AArch64 通用计时器单调递增（EL0 可见）
  aTickType    := ttHardware;  // 硬件计时器
  aResolution  := GetHardwareResolution;
  // 可选兜底：若 aResolution=0，可回退到参考时钟
  // if aResolution = 0 then aResolution := GetHDResolution;
end;

function TAArch64HardwareTick.Tick: UInt64;
begin
  Result := GetTick;
end;

end.
