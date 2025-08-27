# 策略注入（Backoff/Blocking）最佳实践

本文说明 fafafa.core.lockfree 在不改变外观 API 的情况下，如何通过“策略注入”获得更稳的性能与更清晰的阻塞语义。

## BackoffPolicy（退避策略）
- 模块：src/fafafa.core.lockfree.backoff.pas
- 接口：IBackoffPolicy，默认实现 TAdaptiveBackoffPolicy
- 便捷函数：BackoffStep(var FailCount)
- 作用：统一自旋冲突路径的让出行为（Sleep(0) 为主，偶发 Sleep(1) 微眠），降低尾延迟尖峰

示例（Treiber 栈/MPMC 队列冲突路径）：

```pascal
BackoffStep(LFailCount);
```

## BlockingPolicy（阻塞策略）
- 模块：src/fafafa.core.lockfree.blocking.pas
- 接口：IBlockingPolicy，默认/Noop 策略
- 集成点：TQueuePolicyWrapper（factories 层包装器）
- Builder：TQueueBuilder<T>.WithBlockingPolicy(const P: IBlockingPolicy)

示例（Builder 注入策略并阻塞 10ms 超时）：

```pascal
var QB: specialize TQueueBuilder<Integer>;
    Q: specialize ILockFreeQueue<Integer>;
    V: Integer;
begin
  QB := specialize TQueueBuilder<Integer>.New.Capacity(8).ModelMPMC
    .BlockingPolicy(TQueueBuilder<Integer>.TBlockingPolicy.bpSleep)
    .WithBlockingPolicy(GetDefaultBlockingPolicy);
  Q := QB.Build;
  if not Q.DequeueBlocking(V, 10) then
    WriteLn('Timeout');
end;
```

## 推荐实践
- 默认即可：不设置任何策略，获得稳定的“让出优先”行为
- 压力/基准：按需注入 Noop 或自定义策略观测差异
- 一致性：优先使用 BackoffStep 统一自旋点，避免散落 Sleep(0/1)
- API 心智：非阻塞用 Try*；阻塞/超时通过 *Blocking(TimeoutMs)



## 更新与统一（2025-08）
- BackoffStep 已用于 MPMC 队列与 OA HashMap 的争用/重试分支；避免直接 Sleep(0/1)
- settings.inc：在 Release 构建中默认启用 FAFAFA_LOCKFREE_BACKOFF；DEBUG 下关闭
- 建议：按需打开 FAFAFA_LOCKFREE_CACHELINE_PAD，用于 SPSC/MPMC/ringBuffer 的关键字段隔离
- 内存序建议：发布使用 release、消费使用 acquire、统计使用 relaxed，CAS 使用 acq_rel
