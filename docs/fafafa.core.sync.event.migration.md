# fafafa.core.sync.event 迁移指南

## 概述

本指南帮助开发者从旧版本的事件实现迁移到新的改进版本。新版本移除了有问题的兼容性方法，添加了现代化特性，并修复了关键的可靠性问题。

## 重大变更

### 1. 移除的兼容性方法

以下方法已被移除，因为它们提供了混淆的锁语义：

#### 已移除的方法
```pascal
// ❌ 已移除 - 不再可用
procedure Acquire;      // 等价于 WaitFor(INFINITE)
procedure Release;      // no-op，语义混淆
function TryAcquire: Boolean; // 等价于 TryWait
```

#### 迁移方案
```pascal
// 旧代码
Event.Acquire;

// 新代码
Result := Event.WaitFor(INFINITE);
if Result <> wrSignaled then
  raise Exception.Create('Wait failed');

// 或者使用 RAII 守卫
Guard := Event.WaitGuard;
if not Guard.IsValid then
  raise Exception.Create('Wait failed');
```

```pascal
// 旧代码
if Event.TryAcquire then
  // 处理成功情况

// 新代码
if Event.TryWait then
  // 处理成功情况
```

```pascal
// 旧代码
Event.Release; // 这是 no-op，没有实际作用

// 新代码
// 根据需要使用适当的方法：
Event.SetEvent;    // 设置事件信号
Event.ResetEvent;  // 重置事件信号
// 或者让 RAII 守卫自动管理
```

### 2. 新增的现代化特性

#### RAII 守卫模式
```pascal
// 新特性：自动资源管理
var
  Guard: IEventGuard;
begin
  Guard := Event.WaitGuard(5000);
  if Guard.IsValid then
  begin
    // 成功获取事件
    // 守卫会在超出作用域时自动释放
  end;
end;
```

#### 中断支持
```pascal
// 新特性：可中断的等待
Result := Event.WaitForInterruptible(10000);
case Result of
  wrSignaled:  // 正常信号
  wrAbandoned: // 被中断
  wrTimeout:   // 超时
  wrError:     // 错误
end;

// 在另一个线程中中断等待
Event.Interrupt;
```

#### 增强的错误处理
```pascal
// 新特性：详细的错误信息
if Event.WaitFor(1000) = wrError then
begin
  WriteLn('错误码: ', Ord(Event.GetLastError));
  WriteLn('错误描述: ', Event.GetLastErrorMessage);
end;

// 清除错误状态
Event.ClearLastError;
```

#### 调试和监控
```pascal
// 新特性：性能监控
Event.EnableDebugLogging(True);
WriteLn(Event.GetPerformanceCounters);
WriteLn(Event.GetDebugInfo);
Event.ResetPerformanceCounters;
```

## 逐步迁移指南

### 步骤 1: 识别使用了已移除方法的代码

搜索代码库中的以下模式：
```bash
grep -r "\.Acquire\|\.Release\|\.TryAcquire" your_project/
```

### 步骤 2: 替换 Acquire 调用

```pascal
// 旧代码模式 1: 简单的 Acquire
try
  Event.Acquire;
  // 处理逻辑
except
  on E: Exception do
    // 错误处理
end;

// 新代码模式 1: 使用 WaitFor
Result := Event.WaitFor(INFINITE);
if Result = wrSignaled then
begin
  // 处理逻辑
end
else
begin
  // 错误处理
  case Result of
    wrTimeout:  // 不应该发生（无限等待）
    wrAbandoned: // 被中断
    wrError:    // 系统错误
  end;
end;

// 新代码模式 2: 使用 RAII 守卫（推荐）
Guard := Event.WaitGuard;
if Guard.IsValid then
begin
  // 处理逻辑
  // 自动释放，无需手动管理
end
else
begin
  // 错误处理
end;
```

### 步骤 3: 替换 TryAcquire 调用

```pascal
// 旧代码
if Event.TryAcquire then
begin
  // 成功获取
  try
    // 处理逻辑
  finally
    // 旧代码可能有 Release 调用，但它是 no-op
  end;
end
else
begin
  // 获取失败
end;

// 新代码模式 1: 使用 TryWait
if Event.TryWait then
begin
  // 成功获取
  // 处理逻辑
  // 无需手动释放
end
else
begin
  // 获取失败
end;

// 新代码模式 2: 使用 TryWaitGuard（推荐）
Guard := Event.TryWaitGuard;
if Guard.IsValid then
begin
  // 成功获取
  // 处理逻辑
  // 自动释放
end
else
begin
  // 获取失败
end;
```

### 步骤 4: 移除 Release 调用

```pascal
// 旧代码
Event.Acquire;
try
  // 处理逻辑
finally
  Event.Release; // ❌ 这是 no-op，移除它
end;

// 新代码：根据实际需求决定
Guard := Event.WaitGuard;
if Guard.IsValid then
begin
  // 处理逻辑
  // 如果需要显式重置事件状态：
  if Event.IsManualReset then
    Event.ResetEvent; // 只有在确实需要时才调用
end;
```

### 步骤 5: 利用新特性改进代码

#### 使用中断支持
```pascal
// 改进：支持取消操作
Result := Event.WaitForInterruptible(TimeoutMs);
case Result of
  wrSignaled:  // 正常完成
  wrAbandoned: // 被用户取消
  wrTimeout:   // 超时
  wrError:     // 错误
end;
```

#### 添加错误处理
```pascal
// 改进：详细的错误处理
Result := Event.WaitFor(TimeoutMs);
if Result = wrError then
begin
  LogError('Event wait failed: ' + Event.GetLastErrorMessage);
  // 根据错误类型采取不同的恢复策略
  case Event.GetLastError of
    weResourceExhausted: // 资源不足，稍后重试
    weSystemError:       // 系统错误，记录并报告
    // 其他错误类型...
  end;
end;
```

#### 添加性能监控
```pascal
// 改进：性能监控（开发/调试时）
{$IFDEF DEBUG}
Event.EnableDebugLogging(True);
{$ENDIF}

// 定期输出性能统计
if ShouldLogPerformance then
  LogInfo(Event.GetPerformanceCounters);
```

## 常见迁移问题

### 问题 1: 编译错误 "Method not found"

**错误信息**: `Error: identifier idents no member "Acquire"`

**解决方案**: 按照上述指南替换已移除的方法调用。

### 问题 2: 语义变化导致的逻辑错误

**问题**: 旧代码依赖 `Release` 的 no-op 行为

**解决方案**: 
```pascal
// 如果旧代码期望 Release 重置事件状态
// 需要显式调用 ResetEvent（仅对手动重置事件）
if Event.IsManualReset then
  Event.ResetEvent;
```

### 问题 3: 异常处理模式变化

**问题**: 新的 `WaitFor` 返回结果而不是抛出异常

**解决方案**:
```pascal
// 旧模式：异常驱动
try
  Event.Acquire;
  // 成功逻辑
except
  // 错误处理
end;

// 新模式：结果检查
Result := Event.WaitFor(TimeoutMs);
if Result = wrSignaled then
begin
  // 成功逻辑
end
else
begin
  // 错误处理
  if Result = wrError then
    raise Exception.Create(Event.GetLastErrorMessage);
end;
```

## 性能影响

### 正面影响
1. **修复了 Windows PulseEvent 不可靠问题**，提高了可靠性
2. **无锁快速路径优化**，提升了高频调用性能
3. **原子操作优化**，减少了系统调用开销

### 注意事项
1. **调试日志开销**：仅在开发时启用
2. **性能计数器开销**：轻微，但在极高频场景下可考虑禁用
3. **RAII 守卫开销**：轻微的对象创建开销，但提供了更好的安全性

## 测试建议

### 迁移后测试清单
1. ✅ 所有原有功能正常工作
2. ✅ 并发场景下的正确性
3. ✅ 错误处理路径
4. ✅ 性能回归测试
5. ✅ 内存泄漏检查
6. ✅ 长时间运行稳定性

### 测试代码示例
```pascal
// 基础功能测试
procedure TestBasicFunctionality;
var
  Event: IEvent;
  Guard: IEventGuard;
begin
  Event := CreateEvent(False, False);
  
  // 测试基础操作
  Event.SetEvent;
  Assert(Event.TryWait, 'TryWait should succeed');
  
  // 测试 RAII 守卫
  Event.SetEvent;
  Guard := Event.TryWaitGuard;
  Assert(Guard.IsValid, 'Guard should be valid');
  
  // 测试错误处理
  Assert(Event.GetLastError = weNone, 'Should have no error');
end;
```

## 总结

新版本的 `fafafa.core.sync.event` 提供了：
- ✅ 更清晰的语义（移除混淆的锁接口）
- ✅ 更高的可靠性（修复 PulseEvent 问题）
- ✅ 现代化特性（RAII、中断支持、调试能力）
- ✅ 更好的性能（无锁优化）
- ✅ 更强的错误处理

迁移工作主要涉及替换已移除的方法调用，并可选择性地利用新特性改进代码质量。建议逐步迁移，充分测试每个变更。
