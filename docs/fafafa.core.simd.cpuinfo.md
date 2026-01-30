# fafafa.core.simd.cpuinfo 模块文档

## 概述

`fafafa.core.simd.cpuinfo` 模块提供跨平台的 CPU 特性检测功能，支持 x86/x64 和 ARM 架构的 SIMD 指令集检测。

## 主要功能

### CPU 信息检测
- **厂商识别**: Intel, AMD, ARM, Qualcomm, Samsung, Apple 等
- **型号检测**: 完整的 CPU 型号字符串
- **架构识别**: x86, x64, ARM32, ARM64

### SIMD 特性检测

#### x86/x64 平台
- **SSE 系列**: SSE, SSE2, SSE3, SSSE3, SSE4.1, SSE4.2
- **AVX 系列**: AVX, AVX2, FMA
- **AVX-512**: AVX512F, AVX512DQ, AVX512BW (实验性)

#### ARM 平台
- **NEON**: ARM Advanced SIMD
- **浮点**: 硬件浮点支持
- **SVE**: Scalable Vector Extension
- **加密**: 硬件加密指令

### 后端管理
- **自动选择**: 根据 CPU 特性自动选择最佳 SIMD 后端
- **可用性检查**: 检查特定后端是否可用
- **优先级排序**: 按性能优先级排列可用后端

## 通用能力与架构映射

通用能力 (TGenericFeature) 到各 ISA 的基线映射：

- gfSimd128：x86(SSE2+) / ARM(NEON/AdvSIMD) / RISC-V(V)
- gfSimd256：x86(AVX2)
- gfSimd512：x86(AVX-512F)
- gfAES：x86(AES-NI) / ARM(Crypto)
- gfSHA：x86(SHA ext) / ARM(Crypto)
- gfFMA：x86(FMA3)

注意（x86 OS 门槛）：

- AVX 可用：需 OSXSAVE = 1 且 XCR0[1:0] = 11b（XMM & YMM 上下文）
- AVX-512 可用：还需 XCR0[7:5] = 111b（ZMM 上下文）

本库已在 x86 实现中纳入上述门槛，`HasFeature/HasX86` 返回“可用”视图。

## API 参考

### 主要函数

```pascal
// 获取 CPU 信息（线程安全）
function GetCPUInfo: TCPUInfo;

// 检查后端可用性
function IsBackendAvailable(backend: TSimdBackend): Boolean;

// 获取可用后端列表（按优先级排序）
function GetAvailableBackends: TSimdBackendArray;

// 获取最佳后端
function GetBestBackend: TSimdBackend;

// 获取后端详细信息
function GetBackendInfo(backend: TSimdBackend): TSimdBackendInfo;

// 重置 CPU 信息（用于测试）
procedure ResetCPUInfo;
```

### 数据结构

```pascal
// CPU 信息结构
TCPUInfo = record
  Vendor: string;           // CPU 厂商
  Model: string;            // CPU 型号
  X86: TX86Features;        // x86 特性
  ARM: TARMFeatures;        // ARM 特性
end;

// x86 特性
TX86Features = record
  HasSSE: Boolean;
  HasSSE2: Boolean;
  HasSSE3: Boolean;
  HasSSSE3: Boolean;
  HasSSE41: Boolean;
  HasSSE42: Boolean;
  HasAVX: Boolean;
  HasAVX2: Boolean;
  HasFMA: Boolean;
  HasAVX512F: Boolean;
  HasAVX512DQ: Boolean;
  HasAVX512BW: Boolean;
end;

// ARM 特性
TARMFeatures = record
  HasNEON: Boolean;
  HasFP: Boolean;
  HasAdvSIMD: Boolean;
  HasSVE: Boolean;
  HasCrypto: Boolean;
end;

// SIMD 后端枚举
TSimdBackend = (
  sbScalar,     // 标量实现（总是可用）
  sbSSE2,       // SSE2 实现
  sbAVX2,       // AVX2 实现
  sbAVX512,     // AVX-512 实现
  sbNEON        // ARM NEON 实现
);
```

## 使用示例

### 基本用法

```pascal
uses fafafa.core.simd.cpuinfo;

var
  cpuInfo: TCPUInfo;
  bestBackend: TSimdBackend;
begin
  // 获取 CPU 信息
  cpuInfo := GetCPUInfo;
  WriteLn('CPU: ', cpuInfo.Vendor, ' ', cpuInfo.Model);
  
  // 获取最佳后端
  bestBackend := GetBestBackend;
  WriteLn('Best SIMD backend: ', GetBackendName(bestBackend));
  
  // 检查特定特性
  if cpuInfo.X86.HasAVX2 then
    WriteLn('AVX2 is supported');
    
  if cpuInfo.ARM.HasNEON then
    WriteLn('NEON is supported');
end;
```

### 后端选择

```pascal
var
  backends: TSimdBackendArray;
  backend: TSimdBackend;
  info: TSimdBackendInfo;
  i: Integer;
begin
  // 获取所有可用后端
  backends := GetAvailableBackends;
  
  WriteLn('Available SIMD backends:');
  for i := 0 to Length(backends) - 1 do
  begin
    backend := backends[i];
    info := GetBackendInfo(backend);
    WriteLn('  ', info.Name, ' (Priority: ', info.Priority, ')');
  end;
  
  // 选择特定后端
  if IsBackendAvailable(sbAVX2) then
  begin
    WriteLn('Using AVX2 backend');
    // 使用 AVX2 实现
  end
  else if IsBackendAvailable(sbSSE2) then
  begin
    WriteLn('Using SSE2 backend');
    // 使用 SSE2 实现
  end
  else
  begin
    WriteLn('Using scalar backend');
    // 使用标量实现
  end;
end;
```

## 线程安全

所有公共函数都是线程安全的：

- `GetCPUInfo` 使用延迟初始化和双重检查锁定
- 初始化只执行一次，后续调用直接返回缓存结果
- 在 Windows 上使用 `TRTLCriticalSection`
- 在其他平台使用改进的自旋锁

## 性能特性

- **初始化**: 首次调用 `GetCPUInfo` 时执行检测（约 1-5ms）
- **后续调用**: 直接返回缓存结果（< 1μs）
- **内存占用**: 约 1KB 的静态数据
- **编译优化**: 只编译目标平台的代码

## 平台支持

### Windows
- **x86**: Windows 7+ (32位/64位)
- **ARM**: Windows 10+ ARM64

### Linux
- **x86**: 任何支持 CPUID 的发行版
- **ARM**: 通过 `/proc/cpuinfo` 检测特性

### macOS
- **x86**: macOS 10.9+
- **ARM**: macOS 11+ (Apple Silicon)

## 编译选项

在 `fafafa.core.settings.inc` 中配置：

```pascal
// 启用 x86 支持
{$DEFINE SIMD_X86_AVAILABLE}
{$DEFINE SIMD_BACKEND_SSE2}
{$DEFINE SIMD_BACKEND_AVX2}

// 启用 ARM 支持
{$DEFINE SIMD_ARM_AVAILABLE}
{$DEFINE SIMD_BACKEND_NEON}
```

## 错误处理

- 所有函数都有完善的异常处理
- 检测失败时返回安全的默认值
- 不会抛出异常到用户代码
- 提供详细的调试信息

## 测试

运行单元测试：

```bash
cd tests/fafafa.core.simd.cpuinfo
buildOrTest.bat
```

测试覆盖：
- ✅ 基础功能测试
- ✅ 线程安全测试
- ✅ 性能测试
- ✅ 平台特定测试
- ✅ 错误处理测试

## 已知限制

1. **CPUID 实现**: 当前使用回退实现，需要真实的 CPUID 指令
2. **AVX-512**: 实验性支持，默认禁用
3. **ARM 检测**: 依赖 `/proc/cpuinfo`，在某些嵌入式系统上可能不可用

## 版本历史

- **v1.0**: 初始版本，基础 CPU 检测
- **v1.1**: 添加线程安全支持
- **v1.2**: 重构为模块化架构
- **v1.3**: 完善错误处理和测试覆盖

## 贡献指南

1. 遵循项目编码规范
2. 添加相应的单元测试
3. 更新文档
4. 确保跨平台兼容性
