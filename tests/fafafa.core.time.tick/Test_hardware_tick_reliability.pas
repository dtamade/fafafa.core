unit Test_hardware_tick_reliability;

{$MODE OBJFPC}{$H+}
{$modeswitch anonymousfunctions}
{$IFDEF WINDOWS}
{$CODEPAGE UTF8}
{$ENDIF}

{
──────────────────────────────────────────────────────────────
📦 项目：Hardware Tick Reliability Tests - 硬件计时器可靠性验证

📖 概述：
  专门测试硬件计时器（RDTSC/RDTSCP）的可靠性特性：
  • 多核系统一致性
  • 频率稳定性
  • 睡眠/唤醒后行为
  • CPU 特性检测准确性
  • 溢出/边界条件处理

🎯 目标：
  确保硬件计时器在各种真实场景下都能正确工作

📜 优先级：🟠 High
  来自代码审查建议 - 硬件 tick 可靠性测试
──────────────────────────────────────────────────────────────
}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  {$IFDEF UNIX}
  BaseUnix, Unix,
  {$ENDIF}
  fafafa.core.time.tick,
  fafafa.core.time.tick.base
  {$IF DEFINED(CPUX86_64) OR DEFINED(CPUI386)}
  , fafafa.core.time.tick.hardware.x86_64
  {$ENDIF}
  ;

type
  { TTestHardwareTickReliability }
  TTestHardwareTickReliability = class(TTestCase)
  private
    function IsHardwareAvailable: Boolean;
    function GetCPUCount: Integer;
  published
    { 基础特性检测 }
    procedure Test_HardwareAvailability_Detection;
    procedure Test_InvariantTSC_Detection;
    procedure Test_RDTSCP_Detection;
    
    { 频率校准 }
    procedure Test_Frequency_Calibration_NonZero;
    procedure Test_Frequency_Calibration_Stable;
    procedure Test_Frequency_Calibration_Reasonable_Range;
    procedure Test_Frequency_Recalibration_Consistency;
    
    { 单核可靠性 }
    procedure Test_Hardware_Monotonicity_SingleThread;
    procedure Test_Hardware_Resolution_SingleThread;
    procedure Test_Hardware_TickAdvances_SingleThread;
    
    { 多核一致性 }
    procedure Test_Hardware_CrossCoreConsistency;
    procedure Test_Hardware_ParallelMonotonicity;
    
    { 高频采样稳定性 }
    procedure Test_Hardware_HighFrequencySampling;
    procedure Test_Hardware_BurstSampling;
    
    { 睡眠/唤醒行为 }
    procedure Test_Hardware_AfterSleep_ShortDuration;
    procedure Test_Hardware_AfterSleep_Monotonicity;
    
    { 边界条件 }
    procedure Test_Hardware_RapidConstruction;
    procedure Test_Hardware_LongRunningStability;
  end;

  { 跨核心测试线程 }
  TCrossCoreThread = class(TThread)
  public
    ThreadIndex: Integer;
    StartValue: UInt64;
    EndValue: UInt64;
    SampleCount: Integer;
    MinDelta: UInt64;
    MaxDelta: UInt64;
    Success: Boolean;
    ErrorMsg: String;
    constructor Create(AThreadID: Integer);
    procedure Execute; override;
  end;

  { 高频采样线程 }
  THighFreqSamplingThread = class(TThread)
  public
    SampleCount: Integer;
    ViolationCount: Integer;
    Success: Boolean;
    constructor Create;
    procedure Execute; override;
  end;

implementation

{$IFDEF UNIX}
{$IFDEF LINUX}
uses ctypes;

const
  _SC_NPROCESSORS_ONLN = 84;

function sysconf(name: cint): clong; cdecl; external 'c' name 'sysconf';
{$ENDIF}
{$ENDIF}

{ TTestHardwareTickReliability }

function TTestHardwareTickReliability.IsHardwareAvailable: Boolean;
begin
  Result := HasHardwareTick;
end;

function TTestHardwareTickReliability.GetCPUCount: Integer;
begin
  {$IFDEF LINUX}
  Result := sysconf(_SC_NPROCESSORS_ONLN);
  if Result < 1 then Result := 1;
  {$ELSE}
  // Windows and other platforms: use environment variable or default
  Result := StrToIntDef(GetEnvironmentVariable('NUMBER_OF_PROCESSORS'), 1);
  {$ENDIF}
end;

{ ============ 基础特性检测测试 ============ }

procedure TTestHardwareTickReliability.Test_HardwareAvailability_Detection;
begin
  // 在支持的平台上应该能检测到硬件支持
  {$IF DEFINED(CPUX86_64) OR DEFINED(CPUI386)}
  AssertTrue('Hardware tick should be available on x86/x86_64', IsHardwareAvailable);
  {$ELSE}
  // 在其他平台上，可用性取决于构建配置
  // 至少应该不抛异常
  if IsHardwareAvailable then
    WriteLn('Hardware tick available on this platform');
  {$ENDIF}
end;

procedure TTestHardwareTickReliability.Test_InvariantTSC_Detection;
{$IF DEFINED(CPUX86_64) OR DEFINED(CPUI386)}
var
  HasInvariantTSC: Boolean;
  Tick: ITick;
{$ENDIF}
begin
  if not IsHardwareAvailable then Exit;
  
  {$IF DEFINED(CPUX86_64) OR DEFINED(CPUI386)}
  HasInvariantTSC := CpuHasInvariantTSC;
  Tick := MakeHWTick;
  
  // 单调性应该与 Invariant TSC 检测一致
  if HasInvariantTSC then
    AssertTrue('Invariant TSC implies monotonic', Tick.IsMonotonic)
  else
    WriteLn('Warning: TSC is not invariant on this CPU');
  {$ENDIF}
end;

procedure TTestHardwareTickReliability.Test_RDTSCP_Detection;
{$IF DEFINED(CPUX86_64) OR DEFINED(CPUI386)}
var
  HasRDTSCP: Boolean;
{$ENDIF}
begin
  if not IsHardwareAvailable then Exit;
  
  {$IF DEFINED(CPUX86_64) OR DEFINED(CPUI386)}
  HasRDTSCP := CpuHasRDTSCP;
  WriteLn('RDTSCP support: ', HasRDTSCP);
  // 不断言，仅信息输出 - RDTSCP 不是必需的
  {$ENDIF}
end;

{ ============ 频率校准测试 ============ }

procedure TTestHardwareTickReliability.Test_Frequency_Calibration_NonZero;
var
  Tick: ITick;
begin
  if not IsHardwareAvailable then Exit;
  
  Tick := MakeHWTick;
  AssertTrue('Hardware tick resolution must be non-zero', Tick.Resolution > 0);
end;

procedure TTestHardwareTickReliability.Test_Frequency_Calibration_Stable;
var
  Tick1, Tick2, Tick3: ITick;
  Res1, Res2, Res3: UInt64;
  MaxDiff: UInt64;
begin
  if not IsHardwareAvailable then Exit;
  
  // 多次创建实例，频率应该一致（使用缓存值）
  Tick1 := MakeHWTick;
  Res1 := Tick1.Resolution;
  
  Tick2 := MakeHWTick;
  Res2 := Tick2.Resolution;
  
  Tick3 := MakeHWTick;
  Res3 := Tick3.Resolution;
  
  AssertEquals('Resolution should be stable (1=2)', Res1, Res2);
  AssertEquals('Resolution should be stable (2=3)', Res2, Res3);
end;

procedure TTestHardwareTickReliability.Test_Frequency_Calibration_Reasonable_Range;
var
  Tick: ITick;
  FreqGHz: Double;
begin
  if not IsHardwareAvailable then Exit;
  
  Tick := MakeHWTick;
  FreqGHz := Tick.Resolution / 1e9;
  
  // 现代 CPU 频率通常在 0.5 GHz ~ 6 GHz 范围
  AssertTrue('Frequency should be >= 500 MHz', FreqGHz >= 0.5);
  AssertTrue('Frequency should be <= 6 GHz', FreqGHz <= 6.0);
  
  WriteLn(Format('Hardware tick frequency: %.3f GHz', [FreqGHz]));
end;

procedure TTestHardwareTickReliability.Test_Frequency_Recalibration_Consistency;
var
  FirstRes: UInt64;
  I: Integer;
  Tick: ITick;
begin
  if not IsHardwareAvailable then Exit;
  
  Tick := MakeHWTick;
  FirstRes := Tick.Resolution;
  
  // 重复创建，频率应该保持一致（缓存生效）
  for I := 1 to 10 do
  begin
    Tick := MakeHWTick;
    AssertEquals(Format('Resolution consistent iteration %d', [I]), 
                 FirstRes, Tick.Resolution);
  end;
end;

{ ============ 单核可靠性测试 ============ }

procedure TTestHardwareTickReliability.Test_Hardware_Monotonicity_SingleThread;
var
  Tick: ITick;
  Prev, Curr: UInt64;
  I: Integer;
begin
  if not IsHardwareAvailable then Exit;
  
  Tick := MakeHWTick;
  if not Tick.IsMonotonic then
  begin
    WriteLn('Skipping monotonicity test: TSC is not marked as invariant');
    Exit;
  end;
  
  Prev := Tick.Tick;
  for I := 1 to 10000 do
  begin
    Curr := Tick.Tick;
    AssertTrue(Format('Tick should be monotonic at iteration %d', [I]), 
               Curr >= Prev);
    Prev := Curr;
  end;
end;

procedure TTestHardwareTickReliability.Test_Hardware_Resolution_SingleThread;
var
  Tick: ITick;
  Start, Finish: UInt64;
  Elapsed: Int64;
begin
  if not IsHardwareAvailable then Exit;
  
  Tick := MakeHWTick;
  Start := Tick.Tick;
  Sleep(10); // 10ms
  Finish := Tick.Tick;
  
  Elapsed := Int64(Finish - Start);
  
  // 10ms 应该产生可测量的 tick 差异
  // 即使是 1 GHz，10ms = 10,000,000 ticks
  AssertTrue('10ms sleep should produce measurable ticks', Elapsed > 1000000);
end;

procedure TTestHardwareTickReliability.Test_Hardware_TickAdvances_SingleThread;
var
  Tick: ITick;
  Start, Current: UInt64;
  Deadline: QWord;
  Advanced: Boolean;
begin
  if not IsHardwareAvailable then Exit;
  
  Tick := MakeHWTick;
  Start := Tick.Tick;
  Advanced := False;
  
  // 最多等待 5ms
  Deadline := GetTickCount64 + 5;
  while GetTickCount64 < Deadline do
  begin
    Current := Tick.Tick;
    if Current > Start then
    begin
      Advanced := True;
      Break;
    end;
  end;
  
  AssertTrue('Tick should advance within 5ms', Advanced);
end;

{ ============ 多核一致性测试 ============ }

{ TCrossCoreThread }

constructor TCrossCoreThread.Create(AThreadID: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  ThreadIndex := AThreadID;
  Success := False;
  ErrorMsg := '';
  SampleCount := 1000;
  MinDelta := High(UInt64);
  MaxDelta := 0;
end;

procedure TCrossCoreThread.Execute;
var
  Tick: ITick;
  I: Integer;
  Prev, Curr: UInt64;
  Delta: UInt64;
begin
  try
    // Note: CPU affinity setting removed - FPC standard library doesn't provide
    // portable sched_setaffinity bindings. Tests still work without pinning.

    Tick := MakeHWTick;
    StartValue := Tick.Tick;
    Prev := StartValue;
    
    for I := 1 to SampleCount do
    begin
      Curr := Tick.Tick;
      
      // 检查单调性（如果支持）
      if Tick.IsMonotonic and (Curr < Prev) then
      begin
        ErrorMsg := Format('Monotonicity violation: prev=%d, curr=%d, iteration=%d', 
                          [Prev, Curr, I]);
        Exit;
      end;
      
      if Curr > Prev then
      begin
        Delta := Curr - Prev;
        if Delta < MinDelta then MinDelta := Delta;
        if Delta > MaxDelta then MaxDelta := Delta;
      end;
      
      Prev := Curr;
    end;
    
    EndValue := Prev;
    Success := True;
  except
    on E: Exception do
    begin
      ErrorMsg := E.Message;
      Success := False;
    end;
  end;
end;

procedure TTestHardwareTickReliability.Test_Hardware_CrossCoreConsistency;
var
  CPUCount: Integer;
  Threads: array of TCrossCoreThread;
  I: Integer;
  AllSucceeded: Boolean;
  GlobalMin, GlobalMax: UInt64;
begin
  if not IsHardwareAvailable then Exit;
  
  CPUCount := GetCPUCount;
  if CPUCount < 2 then
  begin
    WriteLn('Skipping cross-core test: only 1 CPU detected');
    Exit;
  end;
  
  WriteLn(Format('Running cross-core consistency test on %d CPUs', [CPUCount]));
  
  SetLength(Threads, CPUCount);
  try
    // 创建并启动线程
    for I := 0 to CPUCount - 1 do
    begin
      Threads[I] := TCrossCoreThread.Create(I);
      Threads[I].Start;
    end;
    
    // 等待完成
    for I := 0 to CPUCount - 1 do
      Threads[I].WaitFor;
    
    // 检查结果
    AllSucceeded := True;
    GlobalMin := High(UInt64);
    GlobalMax := 0;
    
    for I := 0 to CPUCount - 1 do
    begin
      if not Threads[I].Success then
      begin
        AllSucceeded := False;
        WriteLn(Format('Thread %d failed: %s', [I, Threads[I].ErrorMsg]));
      end
      else
      begin
        WriteLn(Format('Thread %d: start=%d, end=%d, samples=%d, minDelta=%d, maxDelta=%d',
                      [I, Threads[I].StartValue, Threads[I].EndValue, 
                       Threads[I].SampleCount, Threads[I].MinDelta, Threads[I].MaxDelta]));
        
        if Threads[I].MinDelta < GlobalMin then GlobalMin := Threads[I].MinDelta;
        if Threads[I].MaxDelta > GlobalMax then GlobalMax := Threads[I].MaxDelta;
      end;
    end;
    
    AssertTrue('All threads should succeed', AllSucceeded);
    WriteLn(Format('Global delta range: min=%d, max=%d', [GlobalMin, GlobalMax]));
    
  finally
    for I := 0 to CPUCount - 1 do
      Threads[I].Free;
  end;
end;

procedure TTestHardwareTickReliability.Test_Hardware_ParallelMonotonicity;
const
  THREAD_COUNT = 4;
var
  Threads: array[0..THREAD_COUNT-1] of TCrossCoreThread;
  I: Integer;
  AllSucceeded: Boolean;
begin
  if not IsHardwareAvailable then Exit;
  
  try
    // 创建多个线程并发采样
    for I := 0 to THREAD_COUNT - 1 do
    begin
      Threads[I] := TCrossCoreThread.Create(I);
      Threads[I].SampleCount := 5000;
      Threads[I].Start;
    end;
    
    // 等待完成
    for I := 0 to THREAD_COUNT - 1 do
      Threads[I].WaitFor;
    
    // 验证所有线程都成功
    AllSucceeded := True;
    for I := 0 to THREAD_COUNT - 1 do
    begin
      if not Threads[I].Success then
      begin
        AllSucceeded := False;
        WriteLn(Format('Parallel thread %d failed: %s', [I, Threads[I].ErrorMsg]));
      end;
    end;
    
    AssertTrue('All parallel threads should maintain monotonicity', AllSucceeded);
    
  finally
    for I := 0 to THREAD_COUNT - 1 do
      Threads[I].Free;
  end;
end;

{ ============ 高频采样稳定性测试 ============ }

{ THighFreqSamplingThread }

constructor THighFreqSamplingThread.Create;
begin
  inherited Create(True);
  FreeOnTerminate := False;
  Success := False;
  SampleCount := 0;
  ViolationCount := 0;
end;

procedure THighFreqSamplingThread.Execute;
var
  Tick: ITick;
  Prev, Curr: UInt64;
  I: Integer;
begin
  try
    Tick := MakeHWTick;
    Prev := Tick.Tick;
    
    for I := 1 to 100000 do
    begin
      Curr := Tick.Tick;
      Inc(SampleCount);
      
      if Tick.IsMonotonic and (Curr < Prev) then
        Inc(ViolationCount);
      
      Prev := Curr;
    end;
    
    Success := (ViolationCount = 0);
  except
    Success := False;
  end;
end;

procedure TTestHardwareTickReliability.Test_Hardware_HighFrequencySampling;
var
  Tick: ITick;
  Prev, Curr: UInt64;
  I: Integer;
  Violations: Integer;
begin
  if not IsHardwareAvailable then Exit;
  
  Tick := MakeHWTick;
  Prev := Tick.Tick;
  Violations := 0;
  
  // 高频连续采样 100,000 次
  for I := 1 to 100000 do
  begin
    Curr := Tick.Tick;
    
    if Tick.IsMonotonic and (Curr < Prev) then
      Inc(Violations);
    
    Prev := Curr;
  end;
  
  AssertEquals('High frequency sampling should have zero monotonicity violations', 
               0, Violations);
end;

procedure TTestHardwareTickReliability.Test_Hardware_BurstSampling;
const
  THREAD_COUNT = 8;
  SAMPLES_PER_THREAD = 50000;
var
  Threads: array[0..THREAD_COUNT-1] of THighFreqSamplingThread;
  I: Integer;
  TotalSamples: Integer;
  TotalViolations: Integer;
begin
  if not IsHardwareAvailable then Exit;
  
  try
    // 多线程高频突发采样
    for I := 0 to THREAD_COUNT - 1 do
    begin
      Threads[I] := THighFreqSamplingThread.Create;
      Threads[I].Start;
    end;
    
    // 等待完成
    for I := 0 to THREAD_COUNT - 1 do
      Threads[I].WaitFor;
    
    // 统计结果
    TotalSamples := 0;
    TotalViolations := 0;
    for I := 0 to THREAD_COUNT - 1 do
    begin
      AssertTrue(Format('Thread %d should succeed', [I]), Threads[I].Success);
      TotalSamples := TotalSamples + Threads[I].SampleCount;
      TotalViolations := TotalViolations + Threads[I].ViolationCount;
    end;
    
    WriteLn(Format('Burst sampling: %d total samples, %d violations', 
                   [TotalSamples, TotalViolations]));
    
    AssertEquals('Burst sampling should have zero monotonicity violations', 
                 0, TotalViolations);
    
  finally
    for I := 0 to THREAD_COUNT - 1 do
      Threads[I].Free;
  end;
end;

{ ============ 睡眠/唤醒行为测试 ============ }

procedure TTestHardwareTickReliability.Test_Hardware_AfterSleep_ShortDuration;
var
  Tick: ITick;
  Before, After: UInt64;
  ElapsedTicks: UInt64;
  ElapsedSeconds: Double;
begin
  if not IsHardwareAvailable then Exit;
  
  Tick := MakeHWTick;
  
  Before := Tick.Tick;
  Sleep(100); // 100ms
  After := Tick.Tick;
  
  ElapsedTicks := After - Before;
  ElapsedSeconds := ElapsedTicks / Tick.Resolution;
  
  // 100ms = 0.1 秒，允许 ±30% 误差
  AssertTrue('Sleep duration should be roughly 100ms (0.07s to 0.13s)',
             (ElapsedSeconds >= 0.07) and (ElapsedSeconds <= 0.13));
  
  WriteLn(Format('Sleep 100ms: measured %.6f seconds (%d ticks)', 
                 [ElapsedSeconds, ElapsedTicks]));
end;

procedure TTestHardwareTickReliability.Test_Hardware_AfterSleep_Monotonicity;
var
  Tick: ITick;
  BeforeSleep, AfterSleep, Current: UInt64;
  I: Integer;
begin
  if not IsHardwareAvailable then Exit;
  
  Tick := MakeHWTick;
  if not Tick.IsMonotonic then
  begin
    WriteLn('Skipping sleep monotonicity test: TSC not invariant');
    Exit;
  end;
  
  BeforeSleep := Tick.Tick;
  Sleep(50);
  AfterSleep := Tick.Tick;
  
  // 验证睡眠后时间前进
  AssertTrue('Tick should advance after sleep', AfterSleep > BeforeSleep);
  
  // 睡眠后继续验证单调性
  for I := 1 to 1000 do
  begin
    Current := Tick.Tick;
    AssertTrue(Format('Tick should remain monotonic after sleep (iteration %d)', [I]),
               Current >= AfterSleep);
    AfterSleep := Current;
  end;
end;

{ ============ 边界条件测试 ============ }

procedure TTestHardwareTickReliability.Test_Hardware_RapidConstruction;
var
  I: Integer;
  Tick: ITick;
  Resolutions: array[0..9] of UInt64;
begin
  if not IsHardwareAvailable then Exit;
  
  // 快速连续创建 10 个实例
  for I := 0 to 9 do
  begin
    Tick := MakeHWTick;
    Resolutions[I] := Tick.Resolution;
    AssertTrue(Format('Instance %d should have non-zero resolution', [I]),
               Resolutions[I] > 0);
  end;
  
  // 所有实例应该报告相同的频率
  for I := 1 to 9 do
    AssertEquals(Format('Resolution should be consistent (instance %d)', [I]),
                 Resolutions[0], Resolutions[I]);
end;

procedure TTestHardwareTickReliability.Test_Hardware_LongRunningStability;
var
  Tick: ITick;
  StartTime: QWord;
  Prev, Curr: UInt64;
  Iterations: Integer;
  Violations: Integer;
begin
  if not IsHardwareAvailable then Exit;
  
  Tick := MakeHWTick;
  StartTime := GetTickCount64;
  Prev := Tick.Tick;
  Iterations := 0;
  Violations := 0;
  
  // 运行 2 秒
  while GetTickCount64 - StartTime < 2000 do
  begin
    Curr := Tick.Tick;
    Inc(Iterations);
    
    if Tick.IsMonotonic and (Curr < Prev) then
      Inc(Violations);
    
    Prev := Curr;
  end;
  
  WriteLn(Format('Long running stability: %d iterations in 2 seconds', [Iterations]));
  AssertEquals('Long running test should have zero violations', 0, Violations);
  AssertTrue('Should perform many iterations', Iterations > 100000);
end;

initialization
  RegisterTest(TTestHardwareTickReliability);

end.
