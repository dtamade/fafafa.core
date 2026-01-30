# 定时器异步回调执行改进计划

## 📋 概述

当前定时器调度器在调度线程上**同步执行**回调，导致调度线程被回调阻塞，影响其他定时器的触发精度。

## 🎯 目标

将定时器回调改为**异步执行**（使用线程池），使调度线程专注于定时器调度，提高触发精度。

## ❌ 当前问题

### 问题表现
- 测试 `Test_FixedDelay_Basic_And_Cancel` 经常失败
- 预期 55ms 内执行 3 次，实际可能只执行 1-2 次
- 回调执行时间（3ms sleep）直接阻塞调度线程

### 问题原因
```pascal
// 当前实现 (fafafa.core.time.timer.pas:645)
try
  cb(); // ← 同步执行，阻塞调度线程 3ms
  Inc(GMetrics.FiredTotal);
except
  // ...
end;

// 时间线分析：
// T0:   定时器到期
// T0:   调度线程开始执行 cb()
// T3:   cb() 完成（sleep 3ms）
// T3:   重新调度下一次触发
// T3:   调度线程继续处理其他定时器
//
// 问题：T0-T3 期间，调度线程无法处理其他到期的定时器！
```

## ✅ 改进方案

### 架构设计

```pascal
type
  // 回调上下文（传递给线程池）
  PCallbackContext = ^TCallbackContext;
  TCallbackContext = record
    Callback: TProc;
    TimerEntry: PTimerEntry;  // 用于固定延迟重新调度
    Kind: TTimerKind;
    Delay: TDuration;         // 固定延迟使用
    Scheduler: TTimerSchedulerImpl; // 回引用
  end;

  TTimerSchedulerImpl = class(TInterfacedObject, ITimerScheduler)
  private
    FCallbackPool: IThreadPool;  // 线程池
    FUseAsyncCallbacks: Boolean; // 开关
    
    procedure ExecuteCallbackAsync(AData: Pointer);
  public
    procedure SetCallbackExecutor(const Pool: IThreadPool);
  end;
```

### 实现步骤

```pascal
// 1. 调度线程：提交任务到线程池
if FUseAsyncCallbacks and Assigned(FCallbackPool) then
begin
  // 异步执行
  ctx := AllocCallbackContext(cb, best, kind, delay);
  FCallbackPool.Submit(@ExecuteCallbackAsync, ctx);
  // 立即继续处理下一个定时器，不等待回调完成
end
else
begin
  // 降级：同步执行（兼容模式）
  cb();
  // 处理固定延迟重新调度...
end;

// 2. 工作线程：执行回调
procedure TTimerSchedulerImpl.ExecuteCallbackAsync(AData: Pointer);
var
  ctx: PCallbackContext;
begin
  ctx := PCallbackContext(AData);
  try
    // 执行用户回调
    ctx^.Callback();
    Inc(GMetrics.FiredTotal);
    
    // 固定延迟：重新调度
    if ctx^.Kind = tkFixedDelay then
    begin
      FLock.Acquire;
      try
        if not ctx^.TimerEntry^.Cancelled then
        begin
          ctx^.TimerEntry^.Deadline := FClock.NowInstant.Add(ctx^.Delay);
          HeapInsert(ctx^.TimerEntry);
          FWakeup.SetEvent;
        end;
      finally
        FLock.Release;
      end;
    end;
  except
    on E: Exception do
    begin
      Inc(GMetrics.ExceptionTotal);
      if Assigned(GTimerExceptionHandler) then
        GTimerExceptionHandler(E);
    end;
  end;
  FreeCallbackContext(ctx);
end;
```

## 🚧 实施前置条件

### 依赖项
- ✅ `fafafa.core.thread.threadpool` 已实现
- ⏳ 线程池需要稳定且测试充分
- ⏳ 确认线程池性能满足定时器需求

### 需要解决的问题

1. **回调上下文生命周期管理**
   - 分配：使用对象池或堆分配
   - 释放：回调执行完成后释放
   - 取消：如果定时器被取消，如何处理已提交的任务？

2. **固定延迟定时器处理**
   - 当前：回调完成后在调度线程重新插入堆
   - 改进：回调完成后在工作线程重新插入堆
   - 注意：需要线程安全的堆操作（已有 FLock 保护）

3. **统计指标线程安全**
   - 当前：已使用 GMetricsLock 保护
   - 改进：保持不变，继续使用锁

4. **异常处理**
   - 工作线程中的异常需要传播到 GTimerExceptionHandler
   - 确保异常不会导致线程池崩溃

5. **性能考量**
   - 每个回调都提交到线程池，开销？
   - 是否需要批处理或内联短回调？
   - 线程池队列满时的处理策略？

## 📊 预期效果

### 性能提升
- ✅ 调度精度提升：调度线程不再被回调阻塞
- ✅ 吞吐量提升：多个回调可以并发执行
- ✅ 固定延迟定时器更精确

### 测试改进
- ✅ `Test_FixedDelay_Basic_And_Cancel` 应该稳定通过
- ✅ 高负载下定时器触发更准时

## 🔧 实施计划

### 阶段 1：准备工作（当前阶段）
- [x] 添加 TODO 标记到代码
- [x] 编写改进计划文档
- [ ] 评估线程池当前状态
- [ ] 设计回调上下文结构

### 阶段 2：原型实现
- [ ] 实现 `ExecuteCallbackAsync` 方法
- [ ] 添加 `SetCallbackExecutor` 接口
- [ ] 实现回调上下文池（可选优化）
- [ ] 添加异步/同步模式切换开关

### 阶段 3：测试验证
- [ ] 单元测试：异步回调基本功能
- [ ] 单元测试：固定延迟定时器精度
- [ ] 性能测试：吞吐量对比
- [ ] 压力测试：高负载稳定性
- [ ] 确认现有测试全部通过

### 阶段 4：集成和优化
- [ ] 调优线程池参数
- [ ] 添加性能指标监控
- [ ] 编写用户文档
- [ ] 默认启用异步模式

## 📝 注意事项

### 兼容性
- 保留同步执行模式作为降级方案
- 通过 `SetCallbackExecutor(nil)` 可禁用异步模式
- API 保持向后兼容

### 调试
- 异步执行增加调试难度
- 建议添加调试日志选项
- 提供同步模式用于简化调试

## 🔗 相关文件

- 主文件：`src/fafafa.core.time.timer.pas`
- 线程池：`src/fafafa.core.thread.threadpool.pas`
- 测试文件：`tests/fafafa.core.time/Test_fafafa_core_time_timer_periodic.pas`

## 📅 时间线

- **2025-10-02**: 创建 TODO 文档，添加代码标记
- **待定**: 开始实施（等待线程池完善确认）
- **待定**: 完成测试和集成

---

**状态**: 🟡 规划中 (Planned)  
**优先级**: 🔴 高 (High) - 影响测试稳定性  
**负责人**: 待定  
