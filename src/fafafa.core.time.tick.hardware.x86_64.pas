unit fafafa.core.time.tick.hardware.x86_64;


{
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.tick.hardware.x86_64 - x86_64 硬件计时器

📖 概述：
  64位 x86_64 硬件计时器聚合单元。引入基础实现与平台校准器，
  并导出统一的检测/频率查询与 ITick 实例工厂。

🔧 特性：
  • RDTSC/RDTSCP 指令支持（自动选择最佳序列化路径）
  • Invariant TSC 检测
  • 自动频率校准（参考高精度时钟）
  • 并发安全的一次性初始化

}

{$mode objfpc}
{$I fafafa.core.settings.inc}

{$if not (defined(CPUX64) or defined(CPUX86_64))}
  {$MESSAGE ERROR 'This unit is for 64-bit x86_64 only. Use fafafa.core.time.tick.hardware.i386.pas for 32-bit.'}
{$ifend}

interface

{$IFNDEF FPC}
  {$MESSAGE ERROR 'Delphi/Win64 不支持 inline asm，请改用外部 .obj/.o 或无汇编实现'}
{$ENDIF}

uses
  fafafa.core.time.tick.base;

type
  { TX86_64HardwareTick }
  TX86_64HardwareTick = class(TTick)
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
    {$MESSAGE ERROR 'Unsupported platform for fafafa.core.time.tick.hardware.x86_64'}
  {$ENDIF};

var
  GHardwareResolution:     UInt64 = 0;
  GHardwareResolutionOnce: Int32 = 0; // 0=未开始,1=进行中,2=完成

type
  TReadTscFn = function: UInt64;

var
  GReadTscFn:   TReadTscFn = nil;
  GReadTscOnce: Int32 = 0; // 0=未开始,1=进行中,2=完成

{========================  底层指令路径  ========================}

function ReadTSC_RDTSCP: UInt64; assembler; nostackframe;
asm
  rdtscp
  shl rdx, 32
  or  rax, rdx
  lfence
end;

function ReadTSC_LFENCE_RDTSC: UInt64; assembler; nostackframe;
asm
  lfence
  rdtsc
  shl rdx, 32
  or  rax, rdx
  lfence
end;

function ReadTSC_CPUID_RDTSC: UInt64; assembler; nostackframe;
asm
  push rbx
  xor eax, eax
  cpuid
  rdtsc
  shl rdx, 32
  or  rax, rdx
  pop rbx
end;

{========================  CPU 能力检测  ========================}

// -- 本地极简 CPUID 支持，避免依赖 simd.cpuinfo.x86 --
function HasCPUID: Boolean; inline;
begin
  // 在 x86_64 上 CPUID 必然可用
  Result := True;
end;

procedure CPUID(EAX: LongWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: LongWord);
var
  result_eax, result_ebx, result_ecx, result_edx: LongWord;
begin
  asm
    push rbx
    mov eax, EAX
    cpuid
    mov result_eax, eax
    mov result_ebx, ebx
    mov result_ecx, ecx
    mov result_edx, edx
    pop rbx
  end;
  EAX_Out := result_eax;
  EBX_Out := result_ebx;
  ECX_Out := result_ecx;
  EDX_Out := result_edx;
end;

function CpuHasRDTSCP: Boolean;
var
  LA, LB, LC, LD, LMaxExt: LongWord;
begin
  Result := False;
  if not HasCPUID then Exit;
  CPUID($80000000, LMaxExt, LB, LC, LD);
  if LMaxExt < $80000001 then Exit;
  CPUID($80000001, LA, LB, LC, LD);
  Result := (LD and (1 shl 27)) <> 0; // RDTSCP support
end;

function CpuHasInvariantTSC: Boolean;
var
  LA, LB, LC, LD, LMaxExt: LongWord;
begin
  Result := False;
  if not HasCPUID then Exit;
  CPUID($80000000, LMaxExt, LB, LC, LD);
  if LMaxExt < $80000007 then Exit;
  CPUID($80000007, LA, LB, LC, LD);
  Result := (LD and (1 shl 8)) <> 0; // Invariant TSC
end;

{========================  读 TSC 选择器  ========================}

function ReadTSC: UInt64;
var
  LExpected: Int32;
begin
  if Assigned(GReadTscFn) then
    Exit(GReadTscFn());

  LExpected := 0;
  if atomic_compare_exchange(GReadTscOnce, LExpected, 1) then
  begin
    if CpuHasRDTSCP then
      GReadTscFn := @ReadTSC_RDTSCP
    else
      GReadTscFn := @ReadTSC_LFENCE_RDTSC; // x86_64 基线具备 SSE2
    atomic_store(GReadTscOnce, 2, mo_release);
  end
  else
  begin
    while atomic_load(GReadTscOnce, mo_acquire) <> 2 do
      CpuRelax;
  end;

  Result := GReadTscFn();
end;

{========================  频率校准  ========================}

function CalibrateHardwareResolutionHz: UInt64;
var
  LStartTsc, LEndTsc: UInt64;
  LStartRef, LEndRef: UInt64;
  LDeltaTsc, LDeltaRef: UInt64;
  LRefResolution, LQuotient, LRemainder: UInt64;
  LTargetRef: UInt64;
begin
  // 参考时钟参数
  LRefResolution := GetHDResolution;
  if LRefResolution = 0 then
    Exit(0);

  // 目标窗口 ~10ms（以参考时钟 tick 计）
  LTargetRef := LRefResolution div 100;
  if LTargetRef = 0 then
    LTargetRef := 1;

  LStartRef := GetHDTick;
  LStartTsc := ReadTSC;
  if (LStartRef = 0) or (LStartTsc = 0) then
    Exit(0);

  repeat
    LEndRef := GetHDTick;
    LEndTsc := ReadTSC;
    CpuRelax;
  until (LEndRef - LStartRef) >= LTargetRef;

  LDeltaRef := LEndRef - LStartRef;
  LDeltaTsc := LEndTsc - LStartTsc;
  if (LDeltaRef = 0) or (LDeltaTsc = 0) then
    Exit(0);

  // 频率：deltaTsc / (deltaRef / res) = deltaTsc * res / deltaRef
  LQuotient  := LDeltaTsc div LDeltaRef;
  LRemainder := LDeltaTsc - LQuotient * LDeltaRef;
  Result := LQuotient * LRefResolution + (LRemainder * LRefResolution) div LDeltaRef;
end;

{========================  一次性获取频率  ========================}

function GetHardwareResolution: UInt64;
var
  LState, LExpected: Int32;
begin
  // 快路径
  LState := atomic_load(GHardwareResolutionOnce, mo_acquire);
  if LState = 2 then
    Exit(GHardwareResolution);

  LExpected := 0;
  if atomic_compare_exchange(GHardwareResolutionOnce, LExpected, 1) then
  begin
    Result := CalibrateHardwareResolutionHz;
    if Result = 0 then
    begin
      // 回滚状态，允许其他线程或下次调用重试
      atomic_store(GHardwareResolutionOnce, 0, mo_release);
      Exit(0);
    end;
    GHardwareResolution := Result;
    atomic_store(GHardwareResolutionOnce, 2, mo_release);
  end
  else
  begin
    // 等待其他线程完成；若发现回滚为 0，则尝试接手
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
              Result := CalibrateHardwareResolutionHz;
              if Result = 0 then
              begin
                atomic_store(GHardwareResolutionOnce, 0, mo_release);
                Exit(0);
              end;
              GHardwareResolution := Result;
              atomic_store(GHardwareResolutionOnce, 2, mo_release);
              Exit(Result);
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
  Result := ReadTSC;
end;

function MakeTick: ITick;
begin
  Result := TX86_64HardwareTick.Create;
end;

procedure TX86_64HardwareTick.Initialize(out aResolution: UInt64; out aIsMonotonic: Boolean; out aTickType: TTickType);
begin
  aIsMonotonic := CpuHasInvariantTSC; // 保守：仅在 invariant TSC 才宣称单调
  aTickType    := ttHardware;
  aResolution  := GetHardwareResolution;
  // 可选兜底：若 aResolution=0，可视需要回退到 GetHDResolution
  // if aResolution = 0 then aResolution := GetHDResolution;
end;

function TX86_64HardwareTick.Tick: UInt64;
begin
  Result := GetTick;
end;

end.
