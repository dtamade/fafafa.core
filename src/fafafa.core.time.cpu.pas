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

implementation


{$IFDEF UNIX}
  {$IFNDEF LINUX}
  function libc_sched_yield: cint; cdecl; external 'c' name 'sched_yield';
  {$ENDIF}
{$ENDIF}

{$IFDEF WINDOWS}
// Windows API 函数声明
function SwitchToThread: LongBool; stdcall; external 'kernel32.dll';
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
  {$IFDEF WINDOWS}
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
{$IFDEF UNIX}
  {$IFDEF LINUX}
  sched_yield;
  {$ELSE}
  libc_sched_yield;
  {$ENDIF}
{$ELSE}
  {$IFDEF WINDOWS}
  SwitchToThread;
  {$ENDIF}
{$ENDIF}
end;

{$IFDEF MSWINDOWS}
procedure SchedYield;
begin
  SwitchToThread; // Windows 等价 sched_yield
end;
{$ENDIF}

end.
