unit fafafa.core.time.tick.hardware.riscv64;


{
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.tick.hardware.riscv64 - RISC-V 64 硬件计时器（聚合）

📖 概述：
  RISC-V 64 位硬件计时器聚合单元。引入基础实现与平台校准器，
  并导出统一的检测/频率查询与 ITick 实例工厂。

🔧 特性：
  • CSR time/cycle 读取支持（用户态可读，受上级模式放行控制）

⚠️ 说明：
  • 用户态读取 time/cycle 是否可行，受上级模式（S/M）通过 mcounteren/scounteren 的放行控制；未放行会触发非法指令。
  • 若仅启用 cycle 路径，频率可能受 DVFS 影响，长期换算可能轻微漂移（单调性不受影响）。

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

{$IFNDEF FPC}
  {$MESSAGE ERROR 'Delphi/RISC-V 不支持 inline asm，请改用外部 .o/.obj 或无汇编实现'}
{$ENDIF}

{$if not defined(CPURISCV64)}
  {$MESSAGE ERROR 'This unit is for RISC-V 64 (rv64) only.'}
{$ifend}

uses
  fafafa.core.time.tick.base;

type
  { TRISCV64HardwareTick }
  TRISCV64HardwareTick = class(TTick)
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
    {$MESSAGE ERROR 'Unsupported platform for fafafa.core.time.tick.hardware.riscv64'}
  {$ENDIF};

{$IFDEF FPC}
  {$asmmode default}
{$ENDIF}

// 宏优先级说明：
// 若同时启用 FAFAFA_CORE_USE_RISCV_TIME_CSR 与 FAFAFA_CORE_USE_RISCV_CYCLE_CSR，则优先使用 time 路径；
// 仅在未启用 FAFAFA_CORE_USE_RISCV_TIME_CSR 且启用了 FAFAFA_CORE_USE_RISCV_CYCLE_CSR 时，才使用 cycle。

var
  GHardwareResolution:     UInt64 = 0; // 频率（Hz）
  GHardwareResolutionOnce: Int32  = 0; // 0=未开始,1=进行中,2=完成

const
  CSR_TIME   = $C01; // time（说明：asm 中仍使用字面量）
  CSR_CYCLE  = $C00; // cycle
  MIN_HZ: UInt64 = 1000;                     // 1 kHz 下限
  MAX_HZ: UInt64 = 10 * 1000 * 1000 * 1000;  // 10 GHz 上限

{========================  低层 CSR 读取  ========================}

{$if defined(CPURISCV64) and defined(FAFAFA_CORE_USE_RISCV_TIME_CSR)}
// 注意：U 模式读取 time 是否允许，取决于上级模式通过 mcounteren/scounteren 放行
function ReadTimeCSR64: UInt64; assembler; nostackframe;
asm
  csrr a0, 0xC01      // time (CSR_TIME)
end;
{$elseif defined(CPURISCV64) and defined(FAFAFA_CORE_USE_RISCV_CYCLE_CSR)}
// 注意：cycle 在部分平台会随 DVFS 变化，频率非恒定；单调性保证但换算长期可能漂移
function ReadTimeCSR64: UInt64; assembler; nostackframe;
asm
  csrr a0, 0xC00      // cycle (CSR_CYCLE)
end;
{$else}
function ReadTimeCSR64: UInt64; inline;
begin
  Result := 0;
end;
{$endif}

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
  LStartCnt := ReadTimeCSR64;
  if (LStartRef = 0) or (LStartCnt = 0) then
    Exit(0);

  repeat
    LEndRef := GetHDTick;
    LEndCnt := ReadTimeCSR64;
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

{========================  一次性获取频率  ========================}

function GetHardwareResolution: UInt64;
{$if not (defined(FAFAFA_CORE_USE_RISCV_TIME_CSR) or defined(FAFAFA_CORE_USE_RISCV_CYCLE_CSR))}
begin
  Exit(0);
end;
{$else}
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
    LHz := CalibrateHardwareResolutionHz;
    if (LHz < MIN_HZ) or (LHz > MAX_HZ) then
      LHz := 0;
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
              LHz := CalibrateHardwareResolutionHz;
              if (LHz < MIN_HZ) or (LHz > MAX_HZ) then
                LHz := 0;
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
{$endif}

{========================  ITick 接口实现  ========================}

function GetTick: UInt64;
{$if not (defined(FAFAFA_CORE_USE_RISCV_TIME_CSR) or defined(FAFAFA_CORE_USE_RISCV_CYCLE_CSR))}
begin
  Exit(0);
end;
{$else}
begin
  Result := ReadTimeCSR64;
end;
{$endif}

function MakeTick: ITick;
begin
  Result := TRISCV64HardwareTick.Create;
end;

procedure TRISCV64HardwareTick.Initialize(out aResolution: UInt64; out aIsMonotonic: Boolean; out aTickType: TTickType);
begin
  {$if defined(FAFAFA_CORE_USE_RISCV_TIME_CSR) or defined(FAFAFA_CORE_USE_RISCV_CYCLE_CSR)}
  aIsMonotonic := True;            // 启用任一 CSR 时单调
  {$else}
  aIsMonotonic := False;           // 未启用 CSR 读取时不宣称单调
  {$endif}
  aTickType    := ttHardware; // 硬件计时器
  aResolution  := GetHardwareResolution;
  // 可选兜底：若 aResolution=0，可回退到参考时钟
  // if aResolution = 0 then aResolution := GetHDResolution;
end;

function TRISCV64HardwareTick.Tick: UInt64;
begin
  Result := GetTick;
end;

end.
