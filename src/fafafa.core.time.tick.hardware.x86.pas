unit fafafa.core.time.tick.hardware.x86;

{
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.tick.hardware.x86 - x86/x64 硬件计时器（聚合）

📖 概述：
  x86/x64 硬件计时器聚合单元。引入基础实现与平台校准器，
  并导出统一的检测/频率查询与 ITick 实例工厂。

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

uses
  fafafa.core.time.tick.base,
  fafafa.core.time.tick.hardware.base
  {$IFDEF MSWINDOWS}
  , fafafa.core.time.tick.windows
  {$ENDIF}
  {$IFDEF DARWIN}
  , fafafa.core.time.tick.darwin
  {$ENDIF}
  ;

type

  { TX86HardwareTick }
  TX86HardwareTick = class(THardwareTick)
  protected
    function  GetHardwareResolution: UInt64; override;
    procedure Initialize(out aResolution: UInt64; out aIsMonotonic: Boolean; out aTickType: TTickType); override;
  public
    function Tick: UInt64; override;
  end;

function MakeTick: ITick;
function ReadTSC:UInt64;

implementation

uses
  fafafa.core.atomic,
  fafafa.core.time.cpu
  {$IFDEF UNIX}
  , BaseUnix, Unix
  {$IFDEF LINUX},Linux{$ENDIF}
  {$ENDIF}
  ;

var
  // 分辨率缓存与 once 状态（0=未开始，1=进行中，2=完成）
  GHardwareResolutionHz: UInt64 = 0;
  GHardwareResolutionOnce: Int32 = 0;

  {$IFDEF MSWINDOWS}
  GQpcFreq: UInt64 = 0;
  {$ENDIF}
  {$IFDEF DARWIN}
  GMachNumer: UInt64 = 0;
  GMachDenom: UInt64 = 0;
  {$ENDIF}

function ReadTSC:UInt64; assembler; nostackframe;
asm
  rdtsc
  shl rdx, 32
  or rax, rdx
end;

{$IFDEF CPUX86_64}
function ReadTSC:UInt64; assembler; nostackframe;
asm
  rdtsc
  shl rdx, 32
  or rax, rdx
end;
{$ELSEIF DEFINED(CPUI386)}
function ReadTSC:UInt64; assembler; nostackframe;
asm
  rdtsc
  mov dword ptr [Result], eax
  mov dword ptr [Result+4], edx
end;
{$ELSE}
function ReadTSC:UInt64; inline;
begin
  Result := 0;
end;
{$ENDIF}

// 将参考时钟读取为纳秒
function ReadRefNs: UInt64;
{$IFDEF MSWINDOWS}
var
  c, q: UInt64;
  qdiv, qrem: UInt64;
begin
  if (GQpcFreq = 0) then
    if not QueryPerformanceFrequency(GQpcFreq) then
      Exit(0);
  if not QueryPerformanceCounter(c) then Exit(0);
  q := GQpcFreq;
  qdiv := c div q;
  qrem := c - qdiv * q;
  Result := qdiv * NANOSECONDS_PER_SECOND + (qrem * NANOSECONDS_PER_SECOND) div q;
end;
{$ELSEIF DEFINED(DARWIN)}
var
  t: UInt64;
  divq, remq: UInt64;
  info: mach_timebase_info_data_t;
begin
  if (GMachDenom = 0) or (GMachNumer = 0) then
  begin
    // 读取 timebase，一次性缓存
    if mach_timebase_info(@info) <> 0 then Exit(0);
    if info.denom = 0 then Exit(0);
    GMachNumer := info.numer;
    GMachDenom := info.denom;
  end;
  t := mach_absolute_time;
  divq := t div GMachDenom;
  remq := t - divq * GMachDenom;
  Result := divq * GMachNumer + (remq * GMachNumer) div GMachDenom;
end;
{$ELSEIF DEFINED(UNIX)}
var
  ts: TTimeSpec;
begin
  if clock_gettime(CLOCK_MONOTONIC, @ts) <> 0 then Exit(0);
  Result := UInt64(ts.tv_sec) * NANOSECONDS_PER_SECOND + UInt64(ts.tv_nsec);
end;
{$ELSE}
begin
  Result := 0;
end;
{$ENDIF}

function TX86HardwareTick.GetHardwareResolution: UInt64;
var
  calcHz: UInt64;
  state, expected: Int32;
begin
  // 快速路径：已初始化
  state := atomic_load(GHardwareResolutionOnce);
  if state = 2 then
  begin
    {$IFDEF CPU64}
    Result := atomic_load_64(GHardwareResolutionHz, mo_acquire);
    {$ELSE}
    atomic_thread_fence(mo_acquire);
    Result := GHardwareResolutionHz;
    {$ENDIF}
    Exit;
  end;

  // 竞争设置初始化标志（一次性）
  expected := 0;
  if atomic_compare_exchange(GHardwareResolutionOnce, expected, 1) then
  begin
    // 本线程负责计算
    calcHz := 0;
    calcHz := CalibrateFrequencyHzByRefNs(@ReadTSC, @ReadRefNs, 10 * 1000 * 1000);

    // 写入缓存并发布完成标志
    {$IFDEF CPU64}
    atomic_store_64(GHardwareResolutionHz, calcHz);
    {$ELSE}
    GHardwareResolutionHz := calcHz;
    {$ENDIF}
    atomic_thread_fence(mo_release);
    atomic_store(GHardwareResolutionOnce, 2, mo_release);
    Result := calcHz;
    Exit;
  end
  else
  begin
    // 等待初始化线程完成
    while atomic_load(GHardwareResolutionOnce) <> 2 do
      CpuRelax;
    {$IFDEF CPU64}
    Result := atomic_load_64(GHardwareResolutionHz, mo_acquire);
    {$ELSE}
    atomic_thread_fence(mo_acquire);
    Result := GHardwareResolutionHz;
    {$ENDIF}
    Exit;
  end;
end;

procedure TX86HardwareTick.Initialize(out aResolution: UInt64; out aIsMonotonic: Boolean; out aTickType: TTickType);
begin
  aIsMonotonic := True;
  aTickType := ttHighPrecision;
  aResolution := GetHardwareResolution;
end;


// 移除旧的 class var 初始化逻辑；THardwareTick/TTick 构造时会调用 Initialize
function MakeTick: ITick;
begin
  Result := TX86HardwareTick.Create;
end;

function TX86HardwareTick.Tick: UInt64;
begin
  Result := ReadTSC;
end;
end.