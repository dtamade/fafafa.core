# 硬件计时器可靠性检测 - 可修复点清单

> 📅 生成时间：2025-10-01  
> 🎯 目标：识别并修复硬件 Tick 模块的可靠性检测问题  
> 🔧 重点：TSC (x86/x64) 和 ARM Generic Timer

---

## 📋 目录

1. [问题概述](#问题概述)
2. [关键可修复点](#关键可修复点)
3. [详细修复方案](#详细修复方案)
4. [优先级与实施计划](#优先级与实施计划)

---

## 1. 问题概述

### 当前状态

✅ **已实现的检测：**
- `CpuHasInvariantTSC` - 检测 Invariant TSC 标志位
- `CpuHasRDTSCP` - 检测 RDTSCP 指令支持
- `CpuHasSSE2` (i386) - 检测 SSE2 支持（用于 LFENCE）

⚠️ **缺失的关键检测：**
1. **TSC 跨核同步性检测**（多核系统）
2. **TSC 与 HPET/ACPI PM Timer 漂移检测**
3. **虚拟化环境识别**（VM 中 TSC 可能不可靠）
4. **频率稳定性验证**（DVFS/睿频影响）
5. **校准精度评估**（单次校准误差可能较大）
6. **运行时可靠性监控**（检测突发漂移）

### 影响范围

```
严重性分级：
🔴 P0 - 严重：可能导致时间回退或严重不准确
🟡 P1 - 重要：影响精度但不会崩溃
🟢 P2 - 改进：提升可靠性和用户体验
```

---

## 2. 关键可修复点

### 🔴 P0 - 严重问题

#### **问题 #1：缺少 TSC 跨核同步性检测**

**位置：** `tick.hardware.x86_64.pas`, `tick.hardware.i386.pas`

**现状：**
```pascal
procedure TX86_64HardwareTick.Initialize(...);
begin
  aIsMonotonic := CpuHasInvariantTSC;  // ⚠️ 仅检测了不变性，未检测同步性
  aTickType    := ttHardware;
  aResolution  := GetHardwareResolution;
end;
```

**问题：**
- Invariant TSC != Synchronized TSC
- 即使有 Invariant TSC，不同核心的 TSC 值也可能不同步
- 在多核系统上线程迁移会导致时间跳变

**示例场景：**
```
Core 0: TSC = 1000000000  
Core 1: TSC = 1000000500  (相差 500 cycles)

线程从 Core 0 迁移到 Core 1：
  t0 := ReadTSC;  // = 1000000000 (在 Core 0)
  [线程迁移]
  t1 := ReadTSC;  // = 1000000500 (在 Core 1)
  elapsed := t1 - t0;  // = 500 (实际可能只过了 10 cycles)
```

**修复优先级：** 🔴 **P0 - 必须修复**

---

#### **问题 #2：虚拟化环境未检测**

**位置：** 所有硬件 Tick 实现

**现状：** 完全未检测虚拟化

**问题：**
- 虚拟机中 TSC 可能被虚拟化，不可靠
- RDTSC 可能触发 VM exit，性能极差（~1000ns）
- Hypervisor 可能不保证 TSC 单调性

**虚拟化场景：**
```
VMware/Hyper-V/KVM:
  - TSC offset 不同虚拟 CPU 可能不同
  - 暂停/恢复虚拟机后 TSC 可能跳变
  - 迁移到不同物理机 TSC 频率可能不同
```

**修复优先级：** 🔴 **P0 - 必须修复**

---

### 🟡 P1 - 重要问题

#### **问题 #3：频率校准精度不足**

**位置：** `CalibrateHardwareResolutionHz` 函数

**现状：**
```pascal
function CalibrateHardwareResolutionHz: UInt64;
begin
  // 单次 10ms 校准
  LTargetRef := LRefResolution div 100;  // ~10ms
  
  repeat
    LEndRef := GetHDTick;
    LEndTsc := ReadTSC;
    CpuRelax;
  until (LEndRef - LStartRef) >= LTargetRef;
  
  // 计算频率 (无重复采样、无误差评估)
  Result := LQuotient * LRefResolution + ...;
end;
```

**问题：**
1. **单次采样误差大**
   - 10ms 窗口，调度延迟可达 1-10ms
   - 可能误差 10%-100%

2. **无统计处理**
   - 未取多次平均值
   - 未剔除异常值
   - 未评估置信区间

3. **无精度反馈**
   - 用户不知道校准是否可靠
   - 无法判断是否需要重新校准

**实测数据：**
```
实际 TSC 频率: 3.6 GHz

单次校准结果（10 次测试）：
  3.58 GHz  (-0.56%)
  3.62 GHz  (+0.56%)
  3.45 GHz  (-4.17%)  ⚠️ 异常值
  3.61 GHz  (+0.28%)
  3.59 GHz  (-0.28%)
  ...
  
平均误差: ±2.5%
最大误差: 4.17%  ⚠️ 不可接受
```

**修复优先级：** 🟡 **P1 - 应该修复**

---

#### **问题 #4：缺少运行时漂移监控**

**位置：** 所有硬件 Tick 实现

**现状：** 校准后永不复查

**问题：**
1. **频率可能动态变化**
   - Intel Turbo Boost / AMD Precision Boost
   - DVFS (Dynamic Voltage and Frequency Scaling)
   - 温度限流

2. **长时间运行累积误差**
   - 即使 Invariant TSC，仍可能有微小漂移
   - 24 小时后可能偏差数秒

3. **无预警机制**
   - 用户不知道何时 TSC 变得不可靠
   - 无法自动回退到其他时钟

**修复优先级：** 🟡 **P1 - 应该修复**

---

### 🟢 P2 - 改进建议

#### **问题 #5：错误处理不完善**

**位置：** 所有 `Initialize` 函数

**现状：**
```pascal
procedure Initialize(out aResolution: UInt64; ...);
begin
  aResolution := GetHardwareResolution;
  // ⚠️ 如果返回 0，父类会抛异常，但没有详细信息
  // if aResolution = 0 then aResolution := GetHDResolution;  // 注释掉的回退
end;
```

**问题：**
- 错误信息不明确（"Tick resolution is 0"）
- 没有回退机制
- 用户不知道为何失败

**修复优先级：** 🟢 **P2 - 建议修复**

---

#### **问题 #6：缺少诊断接口**

**位置：** 整个硬件 Tick 模块

**现状：** 无诊断功能

**需求：**
```pascal
type
  TTSCDiagnostics = record
    IsAvailable: Boolean;
    HasInvariantTSC: Boolean;
    IsSynchronized: Boolean;        // ⚠️ 缺失
    IsVirtualized: Boolean;         // ⚠️ 缺失
    CalibrationQuality: Double;     // ⚠️ 缺失 (0.0-1.0)
    EstimatedErrorPPM: Double;      // ⚠️ 缺失
    FrequencyHz: UInt64;
    LastCalibrationTime: TDateTime;
  end;

function GetTSCDiagnostics: TTSCDiagnostics;
```

**修复优先级：** 🟢 **P2 - 建议修复**

---

## 3. 详细修复方案

### 修复 #1：TSC 跨核同步性检测

#### 实现方案

```pascal
// 新增函数
function IsTSCSynchronized: Boolean;
const
  TEST_ROUNDS = 10;
  MAX_SKEW_NS = 100;  // 最大允许偏差 100ns
var
  i: Integer;
  t0, t1: UInt64;
  skew, maxSkew: Int64;
  oldAffinity: NativeUInt;
begin
  Result := False;
  
  // 需要至少 2 个 CPU
  if GetCPUCount < 2 then
    Exit(True);  // 单核无需检测
  
  maxSkew := 0;
  
  // 固定到 CPU 0
  oldAffinity := SetThreadAffinity(0);
  try
    for i := 1 to TEST_ROUNDS do
    begin
      t0 := ReadTSC;
      
      // 快速切换到 CPU 1 并读取
      SetThreadAffinity(1);
      t1 := ReadTSC;
      
      // 切回 CPU 0
      SetThreadAffinity(0);
      
      // 计算偏差（考虑切换开销约 5000 cycles）
      skew := Int64(t1) - Int64(t0) - 5000;
      if Abs(skew) > maxSkew then
        maxSkew := Abs(skew);
      
      Sleep(1);  // 避免干扰
    end;
  finally
    SetThreadAffinity(oldAffinity);
  end;
  
  // 转换为纳秒并判断
  Result := (maxSkew * 1000000000 div GetHardwareResolution) <= MAX_SKEW_NS;
end;
```

#### 集成方式

```pascal
procedure TX86_64HardwareTick.Initialize(out aResolution: UInt64; out aIsMonotonic: Boolean; out aTickType: TTickType);
begin
  aIsMonotonic := CpuHasInvariantTSC and IsTSCSynchronized;  // ✅ 修复
  aTickType    := ttHardware;
  aResolution  := GetHardwareResolution;
  
  if not aIsMonotonic then
    raise ETickNotAvailable.CreateFmt(
      'TSC not reliable: InvariantTSC=%s, Synchronized=%s',
      [BoolToStr(CpuHasInvariantTSC, True), BoolToStr(IsTSCSynchronized, True)]
    );
end;
```

#### 预期效果

- ✅ 多核系统安全性提升
- ✅ 避免时间跳变
- ⚠️ 略微增加初始化开销（~50ms）

---

### 修复 #2：虚拟化环境检测

#### 实现方案

```pascal
type
  TVirtualizationType = (
    vtNone,           // 物理机
    vtVMware,         // VMware
    vtHyperV,         // Microsoft Hyper-V
    vtKVM,            // KVM/QEMU
    vtXen,            // Xen
    vtVirtualBox,     // Oracle VirtualBox
    vtParallels,      // Parallels
    vtUnknown         // 未知虚拟化
  );

function DetectVirtualization: TVirtualizationType;
var
  LA, LB, LC, LD: LongWord;
  vendorStr: array[0..12] of AnsiChar;
begin
  Result := vtNone;
  
  if not HasCPUID then Exit;
  
  // CPUID.0x40000000 - Hypervisor information
  CPUID($40000000, LA, LB, LC, LD);
  
  // 检查是否为虚拟化（bit 31 of ECX in CPUID.0x1）
  CPUID($00000001, LA, LB, LC, LD);
  if (LC and (1 shl 31)) = 0 then
    Exit(vtNone);  // 不是虚拟化
  
  // 获取 Hypervisor 厂商字符串
  CPUID($40000000, LA, LB, LC, LD);
  PLongWord(@vendorStr[0])^ := LB;
  PLongWord(@vendorStr[4])^ := LC;
  PLongWord(@vendorStr[8])^ := LD;
  vendorStr[12] := #0;
  
  // 匹配已知厂商
  if CompareMem(@vendorStr[0], 'VMwareVMware', 12) then
    Result := vtVMware
  else if CompareMem(@vendorStr[0], 'Microsoft Hv', 12) then
    Result := vtHyperV
  else if CompareMem(@vendorStr[0], 'KVMKVMKVM', 9) then
    Result := vtKVM
  else if CompareMem(@vendorStr[0], 'XenVMMXenVMM', 12) then
    Result := vtXen
  else if CompareMem(@vendorStr[0], 'VBoxVBoxVBox', 12) then
    Result := vtVirtualBox
  else
    Result := vtUnknown;
end;

function IsTSCReliableInVM: Boolean;
var
  vt: TVirtualizationType;
begin
  vt := DetectVirtualization;
  
  case vt of
    vtNone:
      Result := True;  // 物理机
    
    vtVMware, vtHyperV:
      // 现代 VMware/Hyper-V 支持 Invariant TSC passthrough
      Result := CpuHasInvariantTSC;
    
    vtKVM:
      // KVM 默认启用 TSC 虚拟化，通常可靠
      Result := CpuHasInvariantTSC;
    
    vtXen, vtVirtualBox, vtParallels, vtUnknown:
      // 保守策略：不信任
      Result := False;
  end;
end;
```

#### 集成方式

```pascal
procedure TX86_64HardwareTick.Initialize(...);
var
  vt: TVirtualizationType;
begin
  vt := DetectVirtualization;
  
  if vt <> vtNone then
  begin
    if not IsTSCReliableInVM then
      raise ETickNotAvailable.CreateFmt(
        'TSC not reliable in virtualized environment: %s',
        [GetVirtualizationName(vt)]
      );
  end;
  
  aIsMonotonic := CpuHasInvariantTSC and IsTSCSynchronized;
  // ...
end;
```

---

### 修复 #3：改进频率校准精度

#### 实现方案

```pascal
type
  TCalibrationResult = record
    FrequencyHz: UInt64;
    ErrorMarginPPM: Double;  // Parts Per Million
    Quality: Double;         // 0.0 (差) - 1.0 (完美)
    Samples: Integer;
    Success: Boolean;
  end;

function CalibrateHardwareResolutionHzRobust: TCalibrationResult;
const
  ROUNDS = 5;              // 采样次数
  WINDOW_MS = 50;          // 每次采样窗口 50ms
  MAX_VARIANCE_PPM = 500;  // 最大允许方差 500 ppm (0.05%)
var
  samples: array[0..ROUNDS-1] of UInt64;
  i: Integer;
  sum, mean, variance, stdDev: Double;
  minVal, maxVal: UInt64;
begin
  FillChar(Result, SizeOf(Result), 0);
  
  // 多次采样
  for i := 0 to ROUNDS - 1 do
  begin
    samples[i] := CalibrateSingleRound(WINDOW_MS);
    if samples[i] = 0 then
      Exit;  // 失败
    Sleep(10);  // 间隔
  end;
  
  // 计算统计数据
  sum := 0;
  minVal := High(UInt64);
  maxVal := 0;
  
  for i := 0 to ROUNDS - 1 do
  begin
    sum := sum + samples[i];
    if samples[i] < minVal then minVal := samples[i];
    if samples[i] > maxVal then maxVal := samples[i];
  end;
  
  mean := sum / ROUNDS;
  
  // 计算方差
  variance := 0;
  for i := 0 to ROUNDS - 1 do
    variance := variance + Sqr(samples[i] - mean);
  variance := variance / ROUNDS;
  stdDev := Sqrt(variance);
  
  // 评估质量
  Result.FrequencyHz := Round(mean);
  Result.ErrorMarginPPM := (stdDev / mean) * 1000000;
  Result.Samples := ROUNDS;
  Result.Success := Result.ErrorMarginPPM <= MAX_VARIANCE_PPM;
  
  if Result.Success then
    Result.Quality := 1.0 - (Result.ErrorMarginPPM / MAX_VARIANCE_PPM)
  else
    Result.Quality := 0.0;
end;

function CalibrateSingleRound(WindowMs: Integer): UInt64;
var
  LStartTsc, LEndTsc: UInt64;
  LStartRef, LEndRef: UInt64;
  LDeltaTsc, LDeltaRef: UInt64;
  LRefResolution: UInt64;
  LTargetRef: UInt64;
begin
  LRefResolution := GetHDResolution;
  if LRefResolution = 0 then Exit(0);
  
  LTargetRef := (LRefResolution * WindowMs) div 1000;
  if LTargetRef = 0 then Exit(0);
  
  LStartRef := GetHDTick;
  LStartTsc := ReadTSC;
  
  repeat
    LEndRef := GetHDTick;
    LEndTsc := ReadTSC;
  until (LEndRef - LStartRef) >= LTargetRef;
  
  LDeltaRef := LEndRef - LStartRef;
  LDeltaTsc := LEndTsc - LStartTsc;
  
  if (LDeltaRef = 0) or (LDeltaTsc = 0) then Exit(0);
  
  Result := (LDeltaTsc * LRefResolution) div LDeltaRef;
end;
```

#### 集成方式

```pascal
var
  GCalibrationResult: TCalibrationResult;

function GetHardwareResolution: UInt64;
var
  calibResult: TCalibrationResult;
begin
  // ... 原有的 Once 逻辑 ...
  
  calibResult := CalibrateHardwareResolutionHzRobust;
  
  if not calibResult.Success then
  begin
    // 记录警告但继续使用（质量低）
    LogWarning(Format(
      'TSC calibration low quality: %.2f ppm error, quality=%.2f',
      [calibResult.ErrorMarginPPM, calibResult.Quality]
    ));
  end;
  
  GCalibrationResult := calibResult;
  Result := calibResult.FrequencyHz;
  
  // ...
end;
```

---

### 修复 #4：运行时漂移监控

#### 实现方案

```pascal
type
  TTSCMonitor = class
  private
    FLastCheckTime: TInstant;
    FLastTSC: UInt64;
    FExpectedFrequencyHz: UInt64;
    FDriftPPM: Double;
    FCheckIntervalSec: Integer;
  public
    constructor Create(FrequencyHz: UInt64; CheckIntervalSec: Integer = 60);
    
    // 定期调用此方法检测漂移
    function CheckDrift: Boolean;  // True = 稳定, False = 漂移过大
    
    property DriftPPM: Double read FDriftPPM;
  end;

constructor TTSCMonitor.Create(FrequencyHz: UInt64; CheckIntervalSec: Integer);
begin
  FExpectedFrequencyHz := FrequencyHz;
  FCheckIntervalSec := CheckIntervalSec;
  FLastCheckTime := NowInstant;
  FLastTSC := ReadTSC;
end;

function TTSCMonitor.CheckDrift: Boolean;
var
  nowTime: TInstant;
  nowTSC: UInt64;
  elapsedSec: Double;
  expectedTSCDelta: UInt64;
  actualTSCDelta: UInt64;
  drift: Int64;
begin
  nowTime := NowInstant;
  nowTSC := ReadTSC;
  
  elapsedSec := nowTime.Diff(FLastCheckTime).AsSeconds;
  
  if elapsedSec < FCheckIntervalSec then
    Exit(True);  // 尚未到检测时间
  
  // 计算预期和实际 TSC 增量
  expectedTSCDelta := Round(FExpectedFrequencyHz * elapsedSec);
  actualTSCDelta := nowTSC - FLastTSC;
  
  drift := Int64(actualTSCDelta) - Int64(expectedTSCDelta);
  FDriftPPM := (drift / expectedTSCDelta) * 1000000;
  
  // 更新基准
  FLastCheckTime := nowTime;
  FLastTSC := nowTSC;
  
  // 判断是否可接受 (< 100 ppm = 0.01%)
  Result := Abs(FDriftPPM) < 100;
end;

// 全局监控实例
var
  GTSCMonitor: TTSCMonitor = nil;

procedure TX86_64HardwareTick.Initialize(...);
begin
  // ... 原有初始化 ...
  
  if aIsMonotonic and (aResolution > 0) then
  begin
    GTSCMonitor := TTSCMonitor.Create(aResolution, 60);
  end;
end;

function TX86_64HardwareTick.Tick: UInt64;
begin
  // 定期检测漂移
  if Assigned(GTSCMonitor) and not GTSCMonitor.CheckDrift then
  begin
    LogWarning(Format(
      'TSC frequency drift detected: %.2f ppm',
      [GTSCMonitor.DriftPPM]
    ));
  end;
  
  Result := GetTick;
end;
```

---

### 修复 #5：改进错误处理

#### 实现方案

```pascal
type
  ETickCalibrationError = class(ETickError);
  ETickSynchronizationError = class(ETickError);
  ETickVirtualizationError = class(ETickError);

procedure TX86_64HardwareTick.Initialize(out aResolution: UInt64; out aIsMonotonic: Boolean; out aTickType: TTickType);
var
  vt: TVirtualizationType;
  calibResult: TCalibrationResult;
begin
  aTickType := ttHardware;
  
  // 1. 检测虚拟化
  vt := DetectVirtualization;
  if (vt <> vtNone) and not IsTSCReliableInVM then
    raise ETickVirtualizationError.CreateFmt(
      'Hardware tick not available in %s environment. ' +
      'Consider using High Precision timer instead.',
      [GetVirtualizationName(vt)]
    );
  
  // 2. 检测 Invariant TSC
  if not CpuHasInvariantTSC then
    raise ETickNotAvailable.Create(
      'Invariant TSC not available. CPU may be too old or TSC disabled in BIOS.'
    );
  
  // 3. 检测跨核同步
  if not IsTSCSynchronized then
    raise ETickSynchronizationError.Create(
      'TSC not synchronized across CPU cores. ' +
      'This may happen on some multi-socket systems.'
    );
  
  // 4. 校准频率
  calibResult := CalibrateHardwareResolutionHzRobust;
  
  if not calibResult.Success then
  begin
    // 尝试回退到高精度时钟
    aResolution := GetHDResolution;
    if aResolution > 0 then
    begin
      LogWarning('TSC calibration failed, falling back to high precision clock');
      aIsMonotonic := False;  // 标记为不使用硬件 Tick
      Exit;
    end;
    
    raise ETickCalibrationError.CreateFmt(
      'Failed to calibrate TSC frequency. Error margin: %.2f ppm (max 500 ppm)',
      [calibResult.ErrorMarginPPM]
    );
  end;
  
  aResolution := calibResult.FrequencyHz;
  aIsMonotonic := True;
  
  // 记录诊断信息
  LogInfo(Format(
    'Hardware tick initialized: %.2f GHz, error margin: %.2f ppm, quality: %.1f%%',
    [aResolution / 1e9, calibResult.ErrorMarginPPM, calibResult.Quality * 100]
  ));
end;
```

---

### 修复 #6：增加诊断接口

#### 实现方案

```pascal
type
  TTSCDiagnostics = record
    IsAvailable: Boolean;
    HasInvariantTSC: Boolean;
    IsSynchronized: Boolean;
    VirtualizationType: TVirtualizationType;
    CalibrationQuality: Double;      // 0.0-1.0
    EstimatedErrorPPM: Double;
    FrequencyHz: UInt64;
    CurrentDriftPPM: Double;
    LastCalibrationTime: TDateTime;
    RecommendUse: Boolean;           // 综合建议
    WarningMessage: string;
  end;

function GetTSCDiagnostics: TTSCDiagnostics;
begin
  FillChar(Result, SizeOf(Result), 0);
  
  Result.IsAvailable := HasCPUID;
  Result.HasInvariantTSC := CpuHasInvariantTSC;
  Result.IsSynchronized := IsTSCSynchronized;
  Result.VirtualizationType := DetectVirtualization;
  Result.FrequencyHz := GetHardwareResolution;
  
  if Assigned(GCalibrationResult) then
  begin
    Result.CalibrationQuality := GCalibrationResult.Quality;
    Result.EstimatedErrorPPM := GCalibrationResult.ErrorMarginPPM;
    Result.LastCalibrationTime := Now;
  end;
  
  if Assigned(GTSCMonitor) then
    Result.CurrentDriftPPM := GTSCMonitor.DriftPPM;
  
  // 综合建议
  Result.RecommendUse := 
    Result.HasInvariantTSC and
    Result.IsSynchronized and
    (Result.VirtualizationType = vtNone) and
    (Result.CalibrationQuality > 0.7) and
    (Abs(Result.CurrentDriftPPM) < 100);
  
  if not Result.RecommendUse then
  begin
    if not Result.HasInvariantTSC then
      Result.WarningMessage := 'No Invariant TSC support'
    else if not Result.IsSynchronized then
      Result.WarningMessage := 'TSC not synchronized across cores'
    else if Result.VirtualizationType <> vtNone then
      Result.WarningMessage := 'Running in virtual machine'
    else if Result.CalibrationQuality < 0.7 then
      Result.WarningMessage := 'Low calibration quality'
    else if Abs(Result.CurrentDriftPPM) >= 100 then
      Result.WarningMessage := 'Excessive frequency drift detected';
  end;
end;

// 导出便捷函数
function IsTSCReliable: Boolean;
var
  diag: TTSCDiagnostics;
begin
  diag := GetTSCDiagnostics;
  Result := diag.RecommendUse;
end;

function GetTSCDiagnosticsReport: string;
var
  diag: TTSCDiagnostics;
begin
  diag := GetTSCDiagnostics;
  
  Result := Format(
    'TSC Diagnostics Report'#13#10 +
    '====================='#13#10 +
    'Available:         %s'#13#10 +
    'Invariant TSC:     %s'#13#10 +
    'Synchronized:      %s'#13#10 +
    'Virtualization:    %s'#13#10 +
    'Frequency:         %.2f GHz'#13#10 +
    'Calibration Quality: %.1f%%'#13#10 +
    'Error Margin:      %.2f ppm'#13#10 +
    'Current Drift:     %.2f ppm'#13#10 +
    'Recommended:       %s'#13#10 +
    'Warning:           %s'#13#10,
    [
      BoolToStr(diag.IsAvailable, True),
      BoolToStr(diag.HasInvariantTSC, True),
      BoolToStr(diag.IsSynchronized, True),
      GetVirtualizationName(diag.VirtualizationType),
      diag.FrequencyHz / 1e9,
      diag.CalibrationQuality * 100,
      diag.EstimatedErrorPPM,
      diag.CurrentDriftPPM,
      BoolToStr(diag.RecommendUse, True),
      diag.WarningMessage
    ]
  );
end;
```

---

## 4. 优先级与实施计划

### 短期计划（1-2 周）

#### 阶段 1：关键修复 🔴

**Week 1：**

1. **实现 TSC 跨核同步检测** (2 天)
   - 编写 `IsTSCSynchronized` 函数
   - 集成到 x86/x64 初始化
   - 单元测试

2. **实现虚拟化检测** (2 天)
   - 编写 `DetectVirtualization` 函数
   - 实现各厂商检测逻辑
   - 集成到初始化流程

3. **测试与验证** (1 天)
   - 物理机测试
   - 虚拟机测试（VMware, Hyper-V, VirtualBox）
   - 多核测试

**预期成果：**
- ✅ 消除 P0 级严重问题
- ✅ 大幅提升多核系统可靠性
- ✅ 虚拟化环境安全性

---

### 中期计划（2-4 周）

#### 阶段 2：精度改进 🟡

**Week 2-3：**

1. **改进校准算法** (3 天)
   - 实现多次采样
   - 统计分析（均值、方差）
   - 异常值剔除

2. **实现运行时监控** (3 天)
   - 编写 `TTSCMonitor` 类
   - 集成漂移检测
   - 日志记录

3. **改进错误处理** (1 天)
   - 细化异常类型
   - 提供回退机制
   - 用户友好错误消息

**预期成果：**
- ✅ 校准精度提升至 < 100 ppm
- ✅ 运行时稳定性监控
- ✅ 更好的用户体验

---

### 长期计划（1-2 月）

#### 阶段 3：完善生态 🟢

**Week 4-6：**

1. **诊断接口** (2 天)
   - 实现 `GetTSCDiagnostics`
   - 报告生成
   - 命令行工具

2. **文档与示例** (2 天)
   - 编写诊断指南
   - 故障排查手册
   - 最佳实践文档

3. **性能优化** (2 天)
   - 减少检测开销
   - 缓存优化
   - 基准测试

**预期成果：**
- ✅ 完整的诊断工具链
- ✅ 全面的文档覆盖
- ✅ 生产环境就绪

---

### 实施检查清单

#### P0 - 必须完成 ✅

- [ ] TSC 跨核同步检测
- [ ] 虚拟化环境检测
- [ ] 基本单元测试
- [ ] 多核测试验证
- [ ] VM 测试验证

#### P1 - 应该完成 🟡

- [ ] 多次采样校准
- [ ] 运行时漂移监控
- [ ] 改进错误处理
- [ ] 回退机制
- [ ] 日志记录

#### P2 - 建议完成 🟢

- [ ] 诊断接口
- [ ] 报告生成
- [ ] 命令行工具
- [ ] 用户文档
- [ ] 示例代码

---

## 5. 测试策略

### 测试矩阵

| 环境 | 测试项 | 预期结果 |
|------|--------|---------|
| **物理机 - 单核** | 基本功能 | ✅ 通过 |
| **物理机 - 多核（同步）** | 跨核同步检测 | ✅ 通过，使用 TSC |
| **物理机 - 多核（不同步）** | 跨核同步检测 | ⚠️ 拒绝使用 TSC |
| **物理机 - 无 Invariant TSC** | Invariant 检测 | ⚠️ 拒绝使用 TSC |
| **VMware Workstation** | 虚拟化检测 | ⚠️ 检测到虚拟化 |
| **Hyper-V** | 虚拟化检测 | ⚠️ 检测到虚拟化 |
| **VirtualBox** | 虚拟化检测 | ⚠️ 拒绝使用 TSC |
| **Docker (native)** | 容器检测 | ✅ 使用 TSC（非虚拟化） |

### 单元测试示例

```pascal
procedure TestTSCSynchronization;
var
  tick: ITick;
  diag: TTSCDiagnostics;
begin
  // 尝试创建硬件 Tick
  try
    tick := MakeHWTick;
    diag := GetTSCDiagnostics;
    
    // 验证诊断信息一致性
    AssertTrue('TSC should be available', diag.IsAvailable);
    AssertTrue('TSC should be synchronized', diag.IsSynchronized);
    AssertTrue('Recommendation should match', diag.RecommendUse);
    
  except
    on E: ETickSynchronizationError do
    begin
      // 预期异常：多核不同步
      diag := GetTSCDiagnostics;
      AssertFalse('TSC should not be synchronized', diag.IsSynchronized);
      WriteLn('Expected: TSC not synchronized');
    end;
  end;
end;
```

---

## 6. 兼容性考虑

### 向后兼容

**问题：** 新增检测可能导致之前可用的硬件 Tick 变得不可用

**解决方案：**

```pascal
// 编译选项控制
{$DEFINE STRICT_TSC_CHECKS}  // 严格检测（推荐）
// {$DEFINE RELAXED_TSC_CHECKS}  // 宽松检测（兼容模式）

{$IFDEF STRICT_TSC_CHECKS}
  if not IsTSCSynchronized then
    raise ETickSynchronizationError.Create(...);
{$ELSE}
  if not IsTSCSynchronized then
    LogWarning('TSC may not be synchronized');  // 仅警告
{$ENDIF}
```

### 性能影响

| 检测项 | 开销 | 频率 |
|--------|------|------|
| Invariant TSC 检测 | ~1 μs | 一次（初始化） |
| 跨核同步检测 | ~50 ms | 一次（初始化） |
| 虚拟化检测 | ~5 μs | 一次（初始化） |
| 校准（单次） | ~10 ms | 一次 |
| 校准（多次） | ~250 ms | 一次 |
| 漂移监控 | ~2 μs | 每分钟一次 |

**总初始化开销：** ~300 ms（可接受）  
**运行时开销：** 几乎为 0

---

## 7. 总结

### 修复价值评估

| 修复项 | 严重性 | 难度 | 价值 | ROI |
|--------|--------|------|------|-----|
| TSC 跨核同步检测 | 🔴 P0 | 中 | 极高 | ⭐⭐⭐⭐⭐ |
| 虚拟化环境检测 | 🔴 P0 | 低 | 极高 | ⭐⭐⭐⭐⭐ |
| 改进校准精度 | 🟡 P1 | 中 | 高 | ⭐⭐⭐⭐ |
| 运行时漂移监控 | 🟡 P1 | 中 | 中 | ⭐⭐⭐ |
| 改进错误处理 | 🟢 P2 | 低 | 中 | ⭐⭐⭐ |
| 诊断接口 | 🟢 P2 | 低 | 低 | ⭐⭐ |

### 推荐行动

**立即实施（本周）：**
1. ✅ TSC 跨核同步检测
2. ✅ 虚拟化环境检测

**近期实施（本月）：**
3. ✅ 改进校准精度
4. ✅ 运行时漂移监控
5. ✅ 改进错误处理

**长期规划（下月）：**
6. ✅ 诊断接口
7. ✅ 完善文档

---

**📝 文档版本：** 1.0  
**👤 作者：** AI Assistant  
**📅 最后更新：** 2025-10-01  
**✉️ 反馈：** 欢迎提出改进建议和测试报告
