unit fafafa.core.simd.sync;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

// === 跨平台原子操作和内存屏障 ===

// 原子操作
function InterlockedCompareExchange(var Target: LongInt; NewValue, Comparand: LongInt): LongInt;
function InterlockedExchange(var Target: LongInt; NewValue: LongInt): LongInt;
function InterlockedIncrement(var Target: LongInt): LongInt;
function InterlockedDecrement(var Target: LongInt): LongInt;

// 内存屏障
procedure ReadBarrier;
procedure WriteBarrier;
procedure MemoryBarrier;

// 线程切换
procedure ThreadSwitch; inline;

implementation

uses
  {$IFDEF WINDOWS}
  Windows
  {$ELSE}
  {$IFDEF UNIX}
  Unix, unixtype
  {$ENDIF}
  {$ENDIF};

// === 原子操作实现 ===

function InterlockedCompareExchange(var Target: LongInt; NewValue, Comparand: LongInt): LongInt;
begin
  {$IFDEF WINDOWS}
  Result := Windows.InterlockedCompareExchange(Target, NewValue, Comparand);
  {$ELSE}
  // FPC 内置原子操作
  Result := System.InterlockedCompareExchange(Target, NewValue, Comparand);
  {$ENDIF}
end;

function InterlockedExchange(var Target: LongInt; NewValue: LongInt): LongInt;
begin
  {$IFDEF WINDOWS}
  Result := Windows.InterlockedExchange(Target, NewValue);
  {$ELSE}
  // FPC 内置原子操作
  Result := System.InterlockedExchange(Target, NewValue);
  {$ENDIF}
end;

function InterlockedIncrement(var Target: LongInt): LongInt;
begin
  {$IFDEF WINDOWS}
  Result := Windows.InterlockedIncrement(Target);
  {$ELSE}
  Result := System.InterlockedIncrement(Target);
  {$ENDIF}
end;

function InterlockedDecrement(var Target: LongInt): LongInt;
begin
  {$IFDEF WINDOWS}
  Result := Windows.InterlockedDecrement(Target);
  {$ELSE}
  Result := System.InterlockedDecrement(Target);
  {$ENDIF}
end;

// === 内存屏障实现 ===

procedure ReadBarrier;
begin
  {$IFDEF CPUX86_64}
  // x86-64: LFENCE 指令
  asm
    lfence
  end;
  {$ELSEIF DEFINED(CPUX86)}
  // x86: 锁定前缀的空操作
  asm
    lock add dword ptr [esp], 0
  end;
  {$ELSEIF DEFINED(CPUAARCH64)}
  // ARM64: DMB 指令
  asm
    dmb ishld
  end;
  {$ELSE}
  // 通用：编译器屏障
  System.ReadBarrier;
  {$ENDIF}
end;

procedure WriteBarrier;
begin
  {$IFDEF CPUX86_64}
  // x86-64: SFENCE 指令
  asm
    sfence
  end;
  {$ELSEIF DEFINED(CPUX86)}
  // x86: 锁定前缀的空操作
  asm
    lock add dword ptr [esp], 0
  end;
  {$ELSEIF DEFINED(CPUAARCH64)}
  // ARM64: DMB 指令
  asm
    dmb ishst
  end;
  {$ELSE}
  // 通用：编译器屏障
  System.WriteBarrier;
  {$ENDIF}
end;

procedure MemoryBarrier;
begin
  {$IFDEF CPUX86_64}
  // x86-64: MFENCE 指令
  asm
    mfence
  end;
  {$ELSEIF DEFINED(CPUX86)}
  // x86: 锁定前缀的空操作
  asm
    lock add dword ptr [esp], 0
  end;
  {$ELSEIF DEFINED(CPUAARCH64)}
  // ARM64: DMB 指令
  asm
    dmb ish
  end;
  {$ELSE}
  // 通用：全屏障
  System.ReadWriteBarrier;
  {$ENDIF}
end;

// === 线程切换 ===

{$IFDEF UNIX}
function sched_yield: cint; cdecl; external 'c' name 'sched_yield';
{$ENDIF}

procedure ThreadSwitch;
begin
  {$IFDEF WINDOWS}
  Windows.Sleep(0);
  {$ELSEIF DEFINED(UNIX)}
  // Unix: sched_yield
  sched_yield;
  {$ELSE}
  // 通用：短暂延迟
  Sleep(0);
  {$ENDIF}
end;

end.
