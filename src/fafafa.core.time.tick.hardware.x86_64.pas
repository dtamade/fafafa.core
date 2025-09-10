unit fafafa.core.time.tick.tsc.x86_64;

{
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.tick.tsc.x86_64 - x86_64 TSC 实现（ITick）

📖 概述：
  x86_64 平台的 TSC (Time Stamp Counter) 纯计数实现，遵循 ITick 接口。
  仅提供计数与频率信息，不涉及 TDuration。

🔧 特性：
  • RDTSC/RDTSCP 指令
  • CPUID 检测 Invariant TSC
  • 通过 QPC/clock_gettime 校准频率

}

{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.time.tick.base
  {$IFDEF LINUX}, Linux{$ENDIF}
  {$IFNDEF MSWINDOWS}, BaseUnix, Unix{$ENDIF}
  ;

type
  TX86_64TSCTick = class(TInterfacedObject, ITick)
  strict private
    class var FAvailable: Boolean;
    class var FFrequency: UInt64;
    class var FInitialized: Boolean;
  private
    class procedure Initialize; static;
  public
    // ITick
    function GetFrequencyHz: UInt64; {$IFDEF FAFAFA_CORE_INLINING}inline;{$ENDIF}
    function GetIsMonotonic: Boolean; {$IFDEF FAFAFA_CORE_INLINING}inline;{$ENDIF}
    function GetTickType: TTickType; {$IFDEF FAFAFA_CORE_INLINING}inline;{$ENDIF}
    function Tick: UInt64; {$IFDEF FAFAFA_CORE_INLINING}inline;{$ENDIF}

    class function IsAvailable: Boolean; static;
    class function Frequency: UInt64; static;
  end;

function IsX86_64TSCAvailable: Boolean;
function GetX86_64TSCFrequency: UInt64;

implementation

{$IFDEF MSWINDOWS}
type
  BOOL = LongBool;
  PDWORD = ^Cardinal;

function QueryPerformanceCounter(out lpPerformanceCount: Int64): BOOL; stdcall; external 'kernel32' name 'QueryPerformanceCounter';
function QueryPerformanceFrequency(out lpFrequency: Int64): BOOL; stdcall; external 'kernel32' name 'QueryPerformanceFrequency';
procedure Sleep(dwMilliseconds: Cardinal); stdcall; external 'kernel32' name 'Sleep';
{$ENDIF}

// ============ 汇编：读取 TSC ============
function RDTSC: UInt64; assembler; nostackframe;
asm
  rdtsc
  shl rdx, 32
  or rax, rdx
end;

// 可选：RDTSCP（序列化）
function RDTSCP: UInt64; assembler; nostackframe;
asm
  rdtscp
  shl rdx, 32
  or rax, rdx
end;

// ============ CPUID 检测 ============
procedure CPUID(leaf: UInt32; out eax, ebx, ecx, edx: UInt32); assembler;
asm
  push rbx
  mov eax, leaf
  cpuid
  mov [eax], eax
  mov [ebx], ebx
  mov [ecx], ecx
  mov [edx], edx
  pop rbx
end;

function InternalDetectInvariantTSC: Boolean;
var
  eax, ebx, ecx, edx: UInt32;
begin
  try
    CPUID($80000007, eax, ebx, ecx, edx);
    Result := (edx and $100) <> 0; // bit 8: Invariant TSC
  except
    Result := False;
  end;
end;

function InternalCalibrateFrequency: UInt64;
var
  start_tsc, end_tsc: UInt64;
  elapsed_tsc, elapsed_ns: UInt64;
begin
  Result := 0;
  try
    {$IFDEF MSWINDOWS}
    var freq, qpc0, qpc1: Int64;
    if not QueryPerformanceFrequency(freq) then Exit;
    start_tsc := RDTSC;
    QueryPerformanceCounter(qpc0);
    Sleep(10);
    end_tsc := RDTSC;
    QueryPerformanceCounter(qpc1);
    elapsed_tsc := end_tsc - start_tsc;
    elapsed_ns := ((qpc1 - qpc0) * 1000000000) div freq;
    if elapsed_ns > 0 then
      Result := (elapsed_tsc * 1000000000) div elapsed_ns;
    {$ELSE}
    var ts0, ts1: TTimeSpec;
    start_tsc := RDTSC;
    clock_gettime(CLOCK_MONOTONIC, @ts0);
    // 睡眠 10ms 以放大测量窗口
    var req, rem: TTimeSpec;
    req.tv_sec := 0; req.tv_nsec := 10 * 1000 * 1000;
    rem.tv_sec := 0; rem.tv_nsec := 0;
    while (FpNanoSleep(req, rem) <> 0) and (fpgeterrno = ESysEINTR) do
      req := rem;
    end_tsc := RDTSC;
    clock_gettime(CLOCK_MONOTONIC, @ts1);
    elapsed_tsc := end_tsc - start_tsc;
    elapsed_ns := (UInt64(ts1.tv_sec - ts0.tv_sec) * 1000000000) + UInt64(ts1.tv_nsec - ts0.tv_nsec);
    if elapsed_ns > 0 then
      Result := (elapsed_tsc * 1000000000) div elapsed_ns;
    {$ENDIF}
  except
    Result := 0;
  end;
end;

class procedure TX86_64TSCTick.Initialize;
begin
  if FInitialized then Exit;
  FAvailable := InternalDetectInvariantTSC;
  if FAvailable then
  begin
    FFrequency := InternalCalibrateFrequency;
    FAvailable := FFrequency > 0;
  end;
  FInitialized := True;
end;

// ============ ITick ============
function TX86_64TSCTick.GetFrequencyHz: UInt64;
begin
  Initialize;
  Result := FFrequency;
end;

function TX86_64TSCTick.GetIsMonotonic: Boolean;
begin
  Initialize;
  Result := FAvailable;
end;

function TX86_64TSCTick.GetTickType: TTickType;
begin
  Result := ttTSC;
end;

function TX86_64TSCTick.Tick: UInt64;
begin
  Result := RDTSC;
end;

class function TX86_64TSCTick.IsAvailable: Boolean;
begin
  Initialize;
  Result := FAvailable;
end;

class function TX86_64TSCTick.Frequency: UInt64;
begin
  Initialize;
  Result := FFrequency;
end;

function IsX86_64TSCAvailable: Boolean;
begin
  Result := TX86_64TSCTick.IsAvailable;
end;

function GetX86_64TSCFrequency: UInt64;
begin
  Result := TX86_64TSCTick.Frequency;
end;

initialization
  TX86_64TSCTick.FInitialized := False;
  TX86_64TSCTick.FAvailable := False;
  TX86_64TSCTick.FFrequency := 0;

end.


