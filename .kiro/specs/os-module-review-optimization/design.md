# Design Document: fafafa.core.os 模块审查与优化

## Overview

本设计文档描述了 `fafafa.core.os` 模块的审查与优化方案。该模块是一个跨平台操作系统助手模块，提供环境变量管理、系统信息查询、平台能力探测等功能。

### 设计目标

1. **代码质量提升**: 消除重复代码，统一命名规范，完善文档
2. **缓存机制优化**: 确保线程安全，优化锁策略
3. **平台兼容性**: 完善 macOS/Windows 实现，统一跨平台行为
4. **接口设计优化**: 三层 API 架构，门面模式，向后兼容

## Architecture

### 当前架构分析

```
┌─────────────────────────────────────────────────────────────┐
│                    fafafa.core.os.pas                       │
│                      (Public Interface)                      │
├─────────────────────────────────────────────────────────────┤
│  Types: TOSError, TPlatformInfo, TCPUInfo, TMemoryInfo...   │
│  APIs:  os_getenv, os_hostname, os_cpu_info, os_is_admin... │
├─────────────────────────────────────────────────────────────┤
│                    Platform Includes                         │
├──────────────────────┬──────────────────────────────────────┤
│  Windows             │  Unix                                 │
│  .windows.inc        │  .unix.inc + .common.inc             │
│  - Registry access   │  - /proc filesystem                  │
│  - WMI queries       │  - sysctl calls                      │
│  - Win32 API         │  - POSIX APIs                        │
└──────────────────────┴──────────────────────────────────────┘
```

### 优化后架构

```
┌─────────────────────────────────────────────────────────────┐
│                    fafafa.core.os.pas                       │
│                   (Public Interface Layer)                   │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │ Simple API  │  │ Extended API│  │ Result-based API    │ │
│  │ os_hostname │  │ os_*_ex     │  │ os_*_result         │ │
│  │ (string)    │  │ (Bool+out)  │  │ (TResult<T,E>)      │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                    Facade Layer                              │
│  os_system_info, os_platform_info (聚合查询)                │
├─────────────────────────────────────────────────────────────┤
│                    Cache Layer (Thread-Safe)                 │
│  Double-checked locking, Selective invalidation             │
├─────────────────────────────────────────────────────────────┤
│                    Platform Abstraction                      │
├──────────────────────┬──────────────────────────────────────┤
│  Windows Impl        │  Unix Impl                            │
│  .windows.inc        │  .unix.inc                            │
│  (Enhanced)          │  (Linux/macOS/BSD)                    │
└──────────────────────┴──────────────────────────────────────┘
```

## Components and Interfaces

### 1. API 设计范式：统一 Result-based

#### 设计决策
采用 **Rust 风格的 Result-based API** 作为唯一公共接口范式，废弃三层 API 设计。

#### 核心原则
1. **单一范式**: 所有公共 API 返回 `TResult<T, TOSError>`
2. **显式错误处理**: 调用者必须处理错误，避免静默失败
3. **便捷方法**: 通过 Result helper 提供快捷访问

#### 新 API 设计

```pascal
// 主 API: 统一返回 Result
function os_hostname: TOSStringResult;
function os_username: TOSStringResult;
function os_cpu_count: TOSIntResult;
function os_is_admin: TOSBoolResult;
function os_cpu_info: TCPUInfoResult;
function os_memory_info: TMemoryInfoResult;
function os_system_info: TSystemInfoResult;

// Result 便捷方法 (TResult<T,E> helper)
function TResult.IsOk: Boolean;
function TResult.IsErr: Boolean;
function TResult.Unwrap: T;                    // 失败时 panic/raise
function TResult.UnwrapOr(const ADefault: T): T;  // 失败时返回默认值
function TResult.UnwrapOrElse(AFunc: TFunc<T>): T; // 失败时调用函数
function TResult.Expect(const AMsg: string): T;   // 失败时带自定义消息
function TResult.Err: E;                       // 获取错误值
```

#### 使用示例

```pascal
// 方式 1: 显式错误处理 (推荐)
var
  LResult: TOSStringResult;
begin
  LResult := os_hostname;
  if LResult.IsOk then
    WriteLn('Hostname: ', LResult.Unwrap)
  else
    WriteLn('Error: ', OSErrorToString(LResult.Err));
end;

// 方式 2: 使用默认值 (快速原型)
var
  LHostname: string;
begin
  LHostname := os_hostname.UnwrapOr('unknown');
end;

// 方式 3: 断言成功 (测试/已知安全场景)
var
  LHostname: string;
begin
  LHostname := os_hostname.Expect('Failed to get hostname');
end;
```

#### 废弃的 API (向后兼容过渡期)

```pascal
// 标记为 deprecated，保留一个版本周期
function os_hostname_ex(out S: string): Boolean; deprecated 'Use os_hostname.UnwrapOr instead';
function os_hostname_result: TOSStringResult; deprecated 'Use os_hostname instead';
```

#### 迁移策略
1. **Phase 1**: 新增统一 Result API，保留旧 API 并标记 deprecated
2. **Phase 2**: 更新文档和示例使用新 API
3. **Phase 3**: 下一个主版本移除废弃 API

### 2. 缓存系统设计

#### 2.1 缓存结构
```pascal
type
  TOSCacheEntry<T> = record
    Value: T;
    Valid: Boolean;
    Timestamp: TDateTime;  // 可选: TTL 支持
  end;
```

#### 2.2 线程安全策略
- 使用 `TCriticalSection` 保护缓存访问
- 双重检查锁定模式减少锁竞争
- 初始化/销毁在 `initialization`/`finalization` 中完成

```pascal
// 双重检查锁定模式
function GetCachedValue: T;
begin
  if not g_cache_valid then
  begin
    EnterCriticalSection(g_cache_cs);
    try
      if not g_cache_valid then  // 二次检查
      begin
        g_cache_value := ComputeValue;
        g_cache_valid := True;
      end;
    finally
      LeaveCriticalSection(g_cache_cs);
    end;
  end;
  Result := g_cache_value;
end;
```

#### 2.3 缓存失效策略
- `os_cache_reset`: 重置所有缓存
- `os_cache_reset_ex(flags)`: 选择性重置
- 依赖缓存自动级联失效

### 3. 平台抽象层设计

#### 3.1 接口统一
所有平台实现必须提供相同的内部函数签名：

```pascal
// 内部实现函数 (在 .inc 文件中)
function _os_hostname_impl: string;
function _os_memory_info_impl(out Info: TMemoryInfo): Boolean;
function _os_storage_info_impl(out Info: TStorageInfoArray): Boolean;
```

#### 3.2 平台特定行为
- 不支持的功能返回 `oseNotSupported`
- 提供有意义的回退值
- 文档记录平台差异

### 4. 错误处理设计

#### 4.1 错误类型映射
```pascal
function SystemErrorToOSError(SystemCode: Integer): TOSError;
// Windows: GetLastError -> TOSError
// Unix: errno -> TOSError
```

#### 4.2 错误传播规则
1. 内部函数可以抛出异常
2. 公共 API 必须捕获异常并转换为 Result/Boolean
3. 简单 API 静默失败，返回默认值

## Data Models

### 核心数据结构

```pascal
// 错误类型 (已存在，保持不变)
TOSError = (
  oseSuccess, oseNotFound, osePermissionDenied,
  oseInvalidInput, oseSystemError, oseTimeout,
  oseOutOfMemory, oseNotSupported, oseAlreadyExists,
  oseInterrupted, oseInvalidData, oseUnexpectedEof,
  oseResourceBusy, oseNetworkError, oseOther
);

// 系统信息结构 (已存在，保持不变)
TCPUInfo = record ... end;
TMemoryInfo = record ... end;
TStorageInfo = record ... end;
TNetworkInterface = record ... end;
TSystemInfo = record ... end;

// 缓存标志 (已存在)
TOSCacheFlags = set of (
  oscTimezone, oscTimezoneIana, oscCpuModel,
  oscIsAdmin, oscKernelVersion, oscOSVersionDetailed
);
```

### 新增/优化数据结构

```pascal
// Result 类型别名 (已存在，确保完整)
TOSStringResult = specialize TResult<string, TOSError>;
TOSBoolResult = specialize TResult<Boolean, TOSError>;
TOSIntResult = specialize TResult<Integer, TOSError>;
TCPUInfoResult = specialize TResult<TCPUInfo, TOSError>;
TMemoryInfoResult = specialize TResult<TMemoryInfo, TOSError>;
// ... 其他 Result 类型
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

基于需求分析，以下是本模块需要验证的正确性属性：

### Property 1: 缓存线程安全性
*For any* 并发访问场景，当多个线程同时读取或重置缓存时，不应发生数据竞争或缓存值损坏。

**Validates: Requirements 2.1, 2.2, 2.4**

### Property 2: 缓存重置传播
*For any* 缓存重置操作，所有依赖的缓存项都应被正确失效，后续访问应重新计算值。

**Validates: Requirements 2.3**

### Property 3: 平台错误处理一致性
*For any* 不支持的平台功能调用，应返回 `oseNotSupported` 错误码；对于平台特定失败，应提供有意义的回退值。

**Validates: Requirements 3.1, 3.4**

### Property 4: CPU 使用率非阻塞
*For any* CPU 使用率查询，应使用增量采样方式，不阻塞调用线程，且返回值在 [0.0, 1.0] 范围内或 -1（未知）。

**Validates: Requirements 4.4**

### Property 5: 错误处理一致性
*For any* 公共 API 调用，应满足：(1) Result-based 变体存在且正确工作，(2) 系统错误正确映射到 TOSError，(3) 不抛出异常到调用者，(4) 错误消息有意义。

**Validates: Requirements 5.1, 5.2, 5.3, 5.4**

### Property 6: 输入验证安全性
*For any* 用户提供的输入（路径、环境变量名/值），应进行验证和清理，防止缓冲区溢出和注入攻击。

**Validates: Requirements 7.2, 7.3, 7.5**

### Property 7: Result API 一致性
*For any* 公共 API 调用，返回的 Result 应满足：(1) IsOk 和 IsErr 互斥，(2) Unwrap 在 IsErr 时抛出异常，(3) UnwrapOr 在 IsErr 时返回默认值，(4) 错误类型正确映射。

**Validates: Requirements 9.2, 9.6, 10.1, 10.3**

## Error Handling

### 错误处理策略

1. **内部层**: 可以使用异常进行错误传播
2. **公共 API 层**: 必须捕获所有异常，转换为适当的返回值
3. **日志**: 关键错误应记录（如果启用日志）

### 错误映射表

| 系统错误 (Windows) | 系统错误 (Unix) | TOSError |
|-------------------|-----------------|----------|
| ERROR_FILE_NOT_FOUND | ENOENT | oseNotFound |
| ERROR_ACCESS_DENIED | EACCES, EPERM | osePermissionDenied |
| ERROR_NOT_ENOUGH_MEMORY | ENOMEM | oseOutOfMemory |
| ERROR_INVALID_PARAMETER | EINVAL | oseInvalidInput |
| ERROR_ALREADY_EXISTS | EEXIST | oseAlreadyExists |
| (其他) | (其他) | oseSystemError |

## Testing Strategy

### 测试框架
- 使用 FPCUnit 进行单元测试
- 使用 FPCCheck (如果可用) 或自定义属性测试框架进行属性测试

### 测试类型

#### 1. 单元测试
- 每个公共函数的基本功能测试
- 边界条件测试（空值、极大值、特殊字符）
- 错误条件测试（权限拒绝、资源不存在）

#### 2. 属性测试
- **Property 1 (缓存线程安全)**: 多线程并发访问测试，验证无数据竞争
- **Property 2 (缓存重置)**: 设置缓存 → 重置 → 验证失效
- **Property 5 (错误处理)**: 随机输入测试，验证无异常泄露
- **Property 7 (API 一致性)**: 对比三层 API 行为一致性

#### 3. 集成测试
- 跨函数一致性（如 `os_platform_info` 与单独查询结果一致）
- 平台特定行为验证

### 测试配置
- 属性测试最少运行 100 次迭代
- 并发测试使用 4-8 个线程
- 条件编译支持平台特定测试

### 测试标注格式
```pascal
// **Feature: os-module-review-optimization, Property 1: Cache Thread Safety**
// **Validates: Requirements 2.1, 2.2, 2.4**
procedure TestCacheThreadSafety;
```
