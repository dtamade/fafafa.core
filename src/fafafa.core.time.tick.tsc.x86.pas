unit fafafa.core.time.tick.tsc.x86;

{
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.tick.tsc.x86 - x86/x64 TSC 实现

📖 概述：
  x86/x64 平台的 TSC (Time Stamp Counter) 硬件计时器实现。
  支持 32位 i386 和 64位 x86_64 架构。

🔧 特性：
  • RDTSC/RDTSCP 指令支持
  • Invariant TSC 检测
  • 自动频率校准
  • 32位和64位汇编优化

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

{$IF DEFINED(CPUX86_64) OR DEFINED(CPUI386)}

uses
  fafafa.core.time.tick.tsc.base;

type
  // x86/x64 TSC 实现
  TX86TSCTick = class(TTSCTickBase)
  protected
    // 实现平台特定方法
    function DoDetectTSCSupport: Boolean; override;
    function DoCalibrateTSCFrequency: UInt64; override;
    function DoReadTSC: UInt64; override;
  end;

// x86/x64 平台检测函数
function IsX86TSCAvailable: Boolean;
function GetX86TSCFrequency: UInt64;

{$ENDIF} // x86/x64

implementation

{$IF DEFINED(CPUX86_64) OR DEFINED(CPUI386)}

uses
  SysUtils
  {$IFDEF MSWINDOWS}
  , Windows
  {$ELSE}
  , BaseUnix, Unix
  {$ENDIF}
  ;

// x86/x64 汇编函数

{$IFDEF CPUX86_64}
// 64位版本
function RDTSC: UInt64; assembler; nostackframe;
asm
  rdtsc
  shl rdx, 32
  or rax, rdx
end;

function RDTSCP: UInt64; assembler; nostackframe;
asm
  rdtscp
  shl rdx, 32
  or rax, rdx
end;

// CPUID 检测 (64位)
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
{$ENDIF}

{$IFDEF CPUI386}
// 32位版本
function RDTSC: UInt64; assembler; nostackframe;
asm
  rdtsc
  // EDX:EAX 已经是正确的 64位结果
end;

function RDTSCP: UInt64; assembler; nostackframe;
asm
  rdtscp
  // EDX:EAX 已经是正确的 64位结果
end;

// CPUID 检测 (32位)
procedure CPUID(leaf: UInt32; out eax, ebx, ecx, edx: UInt32); assembler;
asm
  push ebx
  push edi
  mov eax, leaf
  cpuid
  mov edi, eax
  mov [edi], eax
  mov edi, ebx
  mov [edi], ebx
  mov edi, ecx
  mov [edi], ecx
  mov edi, edx
  mov [edi], edx
  pop edi
  pop ebx
end;
{$ENDIF}

// 全局缓存变量
var
  GX86TSCAvailable: Boolean = False;
  GX86TSCFrequency: UInt64 = 0;
  GX86TSCInitialized: Boolean = False;

// 内部检测函数
function InternalDetectX86TSCSupport: Boolean;
var
  eax, ebx, ecx, edx: UInt32;
begin
  try
    // 检查 CPUID.80000007H:EDX[8] - Invariant TSC
    CPUID($80000007, eax, ebx, ecx, edx);
    Result := (edx and $100) <> 0; // bit 8
  except
    Result := False;
  end;
end;

function InternalCalibrateX86TSCFrequency: UInt64;
var
  start_tsc, end_tsc: UInt64;
  elapsed_tsc, elapsed_ns: UInt64;
begin
  Result := 0;

  try
    {$IFDEF MSWINDOWS}
    var freq, start_qpc, end_qpc: Int64;
    if not QueryPerformanceFrequency(freq) then Exit;

    start_tsc := RDTSC;
    QueryPerformanceCounter(start_qpc);
    Sleep(10);
    end_tsc := RDTSC;
    QueryPerformanceCounter(end_qpc);

    elapsed_tsc := end_tsc - start_tsc;
    elapsed_ns := ((end_qpc - start_qpc) * 1000000000) div freq;

    if elapsed_ns > 0 then
      Result := (elapsed_tsc * 1000000000) div elapsed_ns;
    {$ELSE}
    var start_ts, end_ts: timespec;

    start_tsc := RDTSC;
    clock_gettime(CLOCK_MONOTONIC, @start_ts);
    usleep(10000);
    end_tsc := RDTSC;
    clock_gettime(CLOCK_MONOTONIC, @end_ts);

    elapsed_tsc := end_tsc - start_tsc;
    elapsed_ns := (UInt64(end_ts.tv_sec - start_ts.tv_sec) * 1000000000) +
                  UInt64(end_ts.tv_nsec - start_ts.tv_nsec);

    if elapsed_ns > 0 then
      Result := (elapsed_tsc * 1000000000) div elapsed_ns;
    {$ENDIF}
  except
    Result := 0;
  end;
end;

// 初始化 x86 TSC 信息（只执行一次）
procedure InitializeX86TSCInfo;
begin
  if GX86TSCInitialized then Exit;

  GX86TSCAvailable := InternalDetectX86TSCSupport;
  if GX86TSCAvailable then
  begin
    GX86TSCFrequency := InternalCalibrateX86TSCFrequency;
    GX86TSCAvailable := GX86TSCFrequency > 0;
  end;

  GX86TSCInitialized := True;
end;

{ TX86TSCTick }

function TX86TSCTick.DoDetectTSCSupport: Boolean;
begin
  InitializeX86TSCInfo;
  Result := GX86TSCAvailable;
end;

function TX86TSCTick.DoCalibrateTSCFrequency: UInt64;
begin
  InitializeX86TSCInfo;
  Result := GX86TSCFrequency;
end;

function TX86TSCTick.DoReadTSC: UInt64;
begin
  Result := RDTSC;
end;

// 公共接口函数
function IsX86TSCAvailable: Boolean;
begin
  InitializeX86TSCInfo;
  Result := GX86TSCAvailable;
end;

function GetX86TSCFrequency: UInt64;
begin
  InitializeX86TSCInfo;
  Result := GX86TSCFrequency;
end;

initialization
  // 全局变量初始化
  GX86TSCAvailable := False;
  GX86TSCFrequency := 0;
  GX86TSCInitialized := False;

{$ENDIF} // x86/x64

end.