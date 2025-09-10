{
  fafafa.core.time.cpu - CPU 相关的时间优化函数

  本模块提供 CPU 级别的优化函数，主要用于高性能同步原语中的自旋等待优化。
  作为 fafafa.core.time 的子模块，避免与 sync 模块的循环依赖。

  主要功能：
  - CpuRelax: 跨平台的 CPU 暂停指令，优化自旋等待
  - 支持多种 CPU 架构的原生指令优化

  作者: fafafa.core 开发团队
  版本: 1.0.0
}
unit fafafa.core.time.cpu;

{$I fafafa.core.settings.inc}

interface

{
  CpuRelax - CPU 暂停指令

  在自旋等待循环中调用，用于：
  1. 减少 CPU 功耗
  2. 提高超线程性能
  3. 给其他线程让出执行机会

  支持的架构：
  - x86/x86_64: pause 指令
  - ARM/AArch64: yield 指令
  - PowerPC: or 27,27,27 提示指令
  - MIPS: ssnop (super scalar nop)
  - RISC-V: nop 指令
  - SPARC: membar 内存屏障
  - 其他架构: 系统调用后备方案

  使用示例：
    for SpinCount := 1 to MaxSpins do
    begin
      if TryAcquireLock() then Exit(True);
      CpuRelax;  // 优化自旋等待
    end;
}
procedure CpuRelax;
procedure SchedYield; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
procedure NanoSleep(const aNS: UInt64); {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

implementation

{$IFDEF MSWINDOWS}
// Windows 平台：基础类型定义与 API 声明
type
  THandle = PtrUInt;

// Windows API 函数直接声明
function GetModuleHandle(lpModuleName: PChar): THandle; stdcall; external 'kernel32.dll' name 'GetModuleHandleA';
function GetProcAddress(hModule: THandle; lpProcName: PChar): Pointer; stdcall; external 'kernel32.dll' name 'GetProcAddress';
function Sleep(dwMilliseconds: Cardinal): Cardinal; stdcall; external 'kernel32.dll' name 'Sleep';
function GetTickCount64: UInt64; stdcall; external 'kernel32.dll' name 'GetTickCount64';
{$ENDIF}

{$IFDEF UNIX}
uses
  BaseUnix;

{$ENDIF}

{$IFDEF MSWINDOWS}
// Windows API 函数声明
function SwitchToThread: LongBool; stdcall; external 'kernel32.dll';

type
  PLargeInteger = ^Int64; // 最小化定义，避免引入完整 Windows 单元
  TNtDelayExecution = function(Alertable: LongBool; DelayInterval: PLargeInteger): LongInt; stdcall;

var
  NtDelayExecution: TNtDelayExecution = nil;

procedure InitNtDelayExecution;
var
  hNtDll: THandle;
begin
  if Assigned(NtDelayExecution) then Exit;
  hNtDll := GetModuleHandle('ntdll.dll');
  if hNtDll <> 0 then
    NtDelayExecution := TNtDelayExecution(GetProcAddress(hNtDll, 'NtDelayExecution'));
end;
{$ENDIF}

{$IF defined(CPUX86_64) or defined(CPUI386)}
procedure CpuRelax; assembler; nostackframe;
asm
  pause
end;

{$ELSEIF defined(CPUARM) or defined(CPUAARCH64)}
procedure CpuRelax; assembler; nostackframe;
asm
  // ARM 建议使用 YIELD，若编译器不支持，可改为 NOP
  yield
end;

{$ELSEIF defined(CPUPOWERPC) or defined(CPUPOWERPC64)}
procedure CpuRelax; assembler; nostackframe;
asm
  // PowerPC 推荐自旋提示：or 27,27,27
  or 27,27,27
end;

{$ELSEIF defined(CPUMIPS) or defined(CPUMIPS64)}
procedure CpuRelax; assembler; nostackframe;
asm
  // MIPS 推荐 ssnop（safe nop），比普通 nop 更适合自旋
  ssnop
end;

{$ELSEIF defined(CPURISCV32) or defined(CPURISCV64)}
procedure CpuRelax; assembler; nostackframe;
asm
  // RISC-V 目前没有标准 pause，使用 nop
  nop
end;

{$ELSEIF defined(CPUSPARC) or defined(CPUSPARC64)}
procedure CpuRelax; assembler; nostackframe;
asm
  // SPARC 使用内存屏障，比单纯 nop 更有意义
  membar #LoadLoad
end;

{$ELSE}
procedure CpuRelax; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
begin
  // 未知架构的后备方案
  {$IFDEF MSWINDOWS}
  SwitchToThread();
  {$ELSEIF defined(UNIX)}
  fpSleep(0);  // FPC 的 Unix 让出时间片函数
  {$ELSE}
  // 最后的后备方案：什么都不做
  {$ENDIF}
end;
{$ENDIF}

procedure SchedYield;
begin
{$IFDEF MSWINDOWS}
  SwitchToThread;
{$ELSE}
  FpSched_Yield;
{$ENDIF}
end;


procedure NanoSleep(const aNS: UInt64);
{$IFDEF MSWINDOWS}
var
  LInterval: Int64;
  LStartTick: UInt64;
  LUnits: UInt64;
begin
  // 以 100ns 为单位进行饱和，负数表示相对时间
  LUnits := aNS div 100;
  if LUnits > UInt64(High(Int64)) then
    LInterval := -High(Int64)
  else
    LInterval := -Int64(LUnits);

  if Assigned(NtDelayExecution) then
    NtDelayExecution(False, @LInterval)
  else
  begin
    if aNS >= 1000000 then
      Sleep(aNS div 1000000)
    else
    begin
      LStartTick := GetTickCount64;
      while (GetTickCount64 - LStartTick) * 1000000 < aNS do
        SwitchToThread;
    end;
  end;
end;
{$ELSE}
var
  LReq, LRem: BaseUnix.TTimeSpec;
begin
  LReq.tv_sec  := aNS div 1000000000;
  LReq.tv_nsec := aNS mod 1000000000;

  // 防止 32 位 tv_sec 溢出
  {$IFDEF CPU32}
  if LReq.tv_sec > High(LongInt) then
    LReq.tv_sec := High(LongInt);
  {$ENDIF}

  LRem.tv_sec := 0;
  LRem.tv_nsec := 0;
  // 可能被信号中断，按需重试
  while (FpNanoSleep(LReq, LRem) <> 0) and (fpgeterrno = ESysEINTR) do
    LReq := LRem;
end;
{$ENDIF}

initialization

{$IFDEF MSWINDOWS}
  InitNtDelayExecution;

{$ENDIF}

end.
