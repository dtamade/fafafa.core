# fafafa.core.thread — 指标与典型用法

本节介绍线程池指标接口 IThreadPoolMetrics 以及典型使用方式，便于观测线程池负载与拒绝策略效果。

更多对象池指标详解请参见：docs/fafafa.core.thread.metrics.md

## 指标接口
- 通过 IThreadPool.GetMetrics 获取只读视图 IThreadPoolMetrics
- 提供字段：
  - ActiveCount: 当前执行中的任务数量
  - PoolSize: 当前线程池内线程数量
  - QueueSize: 等待队列长度
  - TotalSubmitted: 提交任务总数（包含被拒绝）
  - TotalCompleted: 完成任务总数（成功/失败都会计入完成）
  - TotalRejected: 被拒绝的任务总数（Abort/Discard/DiscardOldest）

## 代码示例

```pascal
var
  Pool: IThreadPool;
  M: IThreadPoolMetrics;
begin
  Pool := CreateThreadPool(2, 2, 60000, -1, rpAbort);
  M := Pool.GetMetrics;
  Pool.Submit(function(): Boolean begin Result := True; end);
  // 读取观测
  WriteLn('Active=', M.ActiveCount, ' Pool=', M.PoolSize, ' Queue=', M.QueueSize,
          ' Submitted=', M.TotalSubmitted, ' Completed=', M.TotalCompleted,
          ' Rejected=', M.TotalRejected);
  Pool.Shutdown;
  Pool.AwaitTermination(3000);
end;
```

## 拒绝策略语义（要点）
- Abort: 队列已满时抛出异常，不入队；TotalRejected++
- CallerRuns: 队列已满时在调用线程执行，不入队
- Discard: 丢弃当前任务，Future.Fail；TotalRejected++
- DiscardOldest: 丢弃队列最旧任务（Future.Fail），再入队新任务；TotalRejected++


## 限制与建议（Limitations & Recommendations）

- CallerRuns 背压
  - 含义：当队列满时，提交线程直接执行任务，形成自然限速；可防止系统过载。
  - 建议：与 `QueueCapacity=0/有界` 搭配，适合入口限流；回调/任务保持短小。
- Discard / DiscardOldest 的适用
  - 仅应用于“可丢弃、幂等”的任务；业务需可容忍丢失（如日志采样、遥测批次）。
  - 注意：实现会 `Fail` 对应 Future；调用方不应依赖被丢弃任务的副作用。
- 调度器延迟精度
  - 默认时间粒度为毫秒级（约等于系统 tick/睡眠精度），延迟精度建议在 5–10ms 以上；严格实时要求不适用。
  - 建议：对严格时序要求的场景采用硬实时/高精计时方案，或主动校验误差并重试。
- 通道容量选型
  - capacity=0 无缓冲（同步握手），公平性对多生产者/消费者在 ±25% 误差内；进一步均衡需上层策略。
  - 有缓冲通道：设置合理容量可提升吞吐，但需配合上游限流与超时，避免长尾堆积。

## 收尾与资源
- 线程池在 Shutdown/ShutdownNow 时会唤醒等待并等待所有工作线程自然退出（AwaitTermination）
- 内部通过 FAliveThreads 精确感知“线程真正销毁”时机

## 调试与可观测性（可选）

默认不启用任何线程日志，零开销。启用方式（任选其一）：
- 编译时定义：FAFAFA_THREAD_DEBUG（或 FAFAFA_CORE_THREAD_LOG）
- 运行时环境变量：FAFAFA_THREAD_LOG=1（当使用日志单元且编译打开日志支持时生效）

启用后输出内容（示例）：
- 工作线程启动/退出、keepAlive 收缩、被唤醒、获取/完成任务
- 线程池创建 worker、CallerRuns 触发、入队分支选择
- 可选工作线程名称：Worker-XXXX（仅调试构建）

注意：
- 不启用时为 no-op，不影响性能
- 日志位置：执行目录 logs/thread_*.log

## TaskScheduler 指标

- 通过 ITaskScheduler.GetMetrics 获取只读视图 ITaskSchedulerMetrics：
  - TotalScheduled, TotalExecuted, TotalCancelled

## Select（首个完成）

- 函数：Select(const AFutures: array of IFuture; ATimeoutMs: Cardinal): Integer
- 语义：返回首个完成的 Future 的索引；超时返回 -1
- 实现策略：
  - 默认采用“非轮询（回调聚合）”（当启用匿名引用 FAFAFA_CORE_ANONYMOUS_REFERENCES 且未定义 FAFAFA_THREAD_SELECT_FORCE_POLLING）
  - 回退：定义 FAFAFA_THREAD_SELECT_FORCE_POLLING 强制使用“轻量轮询 + 短 WaitFor”；或当编译器不支持匿名引用时自动采用轮询（与历史一致）
- 注意：入参加入 nil 将被忽略；空数组直接返回 -1


### Select 行为切换与宏
- 默认：当编译器支持匿名引用（FAFAFA_CORE_ANONYMOUS_REFERENCES）时，Select 采用“非轮询（回调聚合）”实现
- 回退：若需强制使用轮询实现，编译时定义 FAFAFA_THREAD_SELECT_FORCE_POLLING 即可
- 兼容：若编译器不支持匿名引用，则自动采用轮询实现（与历史一致）

- 宏开关（历史/兼容）：FAFAFA_THREAD_SELECT_NONPOLLING
  - 过去用于手动开启非轮询路径；现已默认开启（在匿名引用可用时）
  - 如需暂时停用，请使用 FAFAFA_THREAD_SELECT_FORCE_POLLING 回退


### Select 宏与回退速查（Best Practices）
- 默认行为：当编译器支持匿名引用（FAFAFA_CORE_ANONYMOUS_REFERENCES）时，启用“非轮询（回调聚合）”Select；否则使用轮询
- 强制回退：定义 FAFAFA_THREAD_SELECT_FORCE_POLLING 可强制使用“轻量轮询 + 短 WaitFor”实现
- 历史宏：FAFAFA_THREAD_SELECT_NONPOLLING 曾用于手动开启非轮询；现已在支持匿名引用时默认开启，不建议单独使用（如需停用请用 FORCE_POLLING）
- 稳定性建议：非轮询模式在多数场景更高效；如遇平台差异或偶发抖动，可临时使用 FORCE_POLLING 回退确认问题归因


### 基准测试与结果解读（可选）
- 工作流：Thread Select Bench (Manual)
  - 入口：GitHub Actions → 选择该工作流 → Run workflow
  - 输入 iter（默认 200）控制每个用例的迭代次数
  - 平台：Windows、Linux 各运行两次（Polling 与 NonPolling 宏）
- 产物（Artifacts）：
  - bench_windows.txt / bench_windows_nonpolling.txt
  - bench_linux.txt / bench_linux_nonpolling.txt
  - bench_summary_windows.md / bench_summary_linux.md（汇总表，包含 N=2/8/32 的平均耗时与差值）
- 典型结论读取方式：
  - 若 NonPolling avg 明显低于 Polling avg，说明回调聚合在该平台/环境下更高效
  - 若差距不明显或反向，说明轮询实现更稳定或该环境下回调优势不明显
  - 建议至少观察多次运行（≥10）以过滤 CI 噪声


- 可视化图表（Artifacts）：
  - bench_delta_pct_windows.png / bench_delta_pct_linux.png（时间序列：NonPolling 相对 Polling 的百分比差，越低越好）
  - bench_compare_latest_windows.png / bench_compare_latest_linux.png（最新一轮：两种模式的柱状对比）
- 如何固定图表链接（推荐其一）：
  1) 在 GitHub Releases 新建一个 Release，将上述 PNG 作为附件上传，获得稳定 URL；然后在文档中引用该 URL
  2) 或者将 PNG 复制到 docs/assets/ 下（注意 repo 体积与频率），用相对路径在文档中引用
  3) 不建议直接引用 Actions Artifacts 的临时链接（会过期）

  - ActiveTasks：当前挂起/等待执行的任务数
  - AverageDelayMs：调度时设置的平均延迟（粗略，按提交时的延迟累加/计数）

示例：
```pascal
var S: ITaskScheduler; M: ITaskSchedulerMetrics; F: IFuture;
begin
  S := CreateTaskScheduler;
  F := S.Schedule(function (Data: Pointer): Boolean begin Result := True; end, 100, nil);
  F.WaitFor(2000);
  M := S.GetMetrics;
  WriteLn('Scheduled=', M.GetTotalScheduled, ' Executed=', M.GetTotalExecuted,
          ' Cancelled=', M.GetTotalCancelled, ' Active=', M.GetActiveTasks,
          ' AvgDelayMs=', M.GetAverageDelayMs:0:1);
  S.Shutdown;
  - 轻量观测（默认关闭）：
    - 调度器：SetObservedMetricsEnabled(True) 或环境变量 FAFAFA_SCHED_METRICS=1；读取 M.GetObservedAverageDelayMs
    - 线程池：TThreadPool.SetObservedMetricsEnabled(True)；读取 Pool.GetMetrics.QueueObservedAverageMs
    - 线程池也支持环境变量：FAFAFA_POOL_METRICS=1（等价于代码开关）


  示例（≤10行）：
  ```pascal
  var S: ITaskScheduler; P: IThreadPool; MS: ITaskSchedulerMetrics; MP: IThreadPoolMetrics;
  begin
    S := CreateTaskScheduler; P := CreateFixedThreadPool(2);
    TTaskScheduler.SetObservedMetricsEnabled(True);
    TThreadPool.SetObservedMetricsEnabled(True);
    // ... 提交/调度若干任务 ...
    MS := S.GetMetrics; MP := P.GetMetrics;
    WriteLn('sched.avg.observed.ms=', MS.GetObservedAverageDelayMs:0:2,
            ' pool.queue.avg.ms=', MP.QueueObservedAverageMs:0:2);
    S.Shutdown; P.Shutdown; P.AwaitTermination(2000);

  快速演示（仅构建并运行 Metrics 示例）：
  - Windows: examples\fafafa.core.thread\BuildOrRun.bat run-metrics
  - 输出 CSV（追加）：examples/fafafa.core.thread/bin/metrics_light.csv，字段为 timestamp,sched_avg_ms,pool_queue_avg_ms

  end;
  ```

end;
```



# fafafa.core.thread

本模块提供现代化的并发抽象：
- 线程池：IThreadPool / TThreadPool，支持拒绝策略、keepAlive、任务提交（函数/方法/匿名函数）
- Future：IFuture / TFuture，支持 WaitFor/Cancel/OnComplete/Map/AndThen
- ThreadLocal、CountDownLatch、Channel（容量>0 缓冲；容量=0 无缓冲握手）
- Scheduler：ITaskScheduler / TTaskScheduler，最小可用延迟调度

## 推荐默认配置（建议优先）
- CreateFixedThreadPool(GetCPUCount) 或自定义：Core≈CPU，Max≈2×CPU
- 有界队列（≈2×CPU）+ TRejectPolicy.rpCallerRuns（自然背压）
- Cached：CreateCachedThreadPool() 现采用保守上限 Max=min(64, 4×CPU)，且≥8
- 使用 Token 进行协作式取消；为 I/O/循环设置超时与取消点

## 反模式与风险提示
- 避免无界队列 + 无界线程上限（过去常见配置，极易过载/抖动）
- 回调里执行阻塞操作（OnComplete/ContinueWith 应短小、非阻塞）
- 长时间持锁 + 回调链（可能导致锁竞争与抖动）

## 门面与兼容性
- 建议优先使用静态类门面：TThreads.*（语义清晰，避免命名冲突）
- 全局函数保留为兼容别名（后续考虑添加 @deprecated 注释，提供迁移指引）
- 两者语义一致；若出现歧义，请以 TThreads 为准

## 设计理念
- 面向接口抽象，门面统一导出（fafafa.core.thread.pas）
- 借鉴 Rust/Go/Java 的接口风格；跨平台（Windows/Unix）
- 线程安全、可替换实现；默认策略安全保守

## 关键 API
- 线程池
  - CreateThreadPool(core,max,keepAliveMs[,queue,policy])
  - CreateFixedThreadPool / CreateCachedThreadPool / CreateSingleThreadPool
  - 提示：CreateCachedThreadPool 采用保守上限（Max=min(64, 4×CPU)，且≥8）以避免无界扩张；如需自定义请使用带参数重载
  - Submit(ATask[,AData]) / Shutdown / AwaitTermination
  - Facade：建议优先使用 TThreads.*（全局函数为兼容保留，后续计划标注 @deprecated）
- Future
  - WaitFor(timeout) / Cancel / IsDone / IsCancelled
  - OnComplete / Map / AndThen
- 通道
  - CreateChannel(capacity)
  - Send(value) / Recv(out value) / Close()
  - 容量=0：发送放入后等待接收取走（握手）
  - 关闭语义：Close 后禁止发送（Send 返回 False），允许接收耗尽缓冲区（无剩余数据时 Recv/TryRecv 返回 False）
- 调度器
  - CreateTaskScheduler
  - Schedule(task, delayMs[, data])
  - 事件驱动等待（时间堆 + 精确休眠），减少空转并提升定时精度
  - Shutdown / IsShutdown

## 使用示例
参见 examples/fafafa.core.thread：
- example_thread_channel.lpr：演示容量=0 无缓冲通道的握手语义
- example_thread_scheduler.lpr：延迟调度与指标读取
- example_thread_best_practices.lpr：Fixed≈CPU、有界队列≈2×CPU、rpCallerRuns 背压、OnComplete 示例

## 最佳实践与指南
- 协作式取消（Token）：docs/fafafa.core.thread.token.md
- 测试快模式（FAF_TEST_*）：docs/fafafa.testing.fast_mode.md

## 注意事项
- Unix 控制台程序需首单元 uses cthreads
- 中文输出的测试/示例需 {$CODEPAGE UTF8}
- 调度器采用事件驱动等待（时间堆 + 精确休眠），大幅降低空闲 CPU 唤醒并提升到期精度；可通过观测延迟指标评估效果

## 依赖关系
- sync：锁/事件等同步原语
- future：Future 实现，供线程池/调度器使用
- threadpool：任务执行引擎
- channel：线程间通信

### 取消语义与最佳实践（Scheduler/Pool/Future）

- 预取消（Pre-Cancel）
  - IThreadPool.Submit(…, Token) / ITaskScheduler.Schedule(…, Token) / Spawn(…, Token)
  - 若传入 Token 已取消，则直接返回 nil，不入队；不计入拒绝/队列

- 提交后、执行前取消（Post-Submit, Pre-Exec）
  - 线程池：任务对象保存 Token；在工作线程执行前检查 Token.IsCancellationRequested
    - 已取消则对 Future 调用 Cancel，并跳过任务执行
  - 调度器：调度项保存 Token；在到期提交到线程池前检查 Token.IsCancellationRequested
    - 已取消则取消对应 Future 并丢弃任务（不执行）

- 进行中取消（Cooperative）
  - 任务内部周期检查 Token.IsCancellationRequested 并尽快退出；对外用 FutureWaitOrCancel 协调等待

- OnComplete 一次性语义
  - 无论在完成前或完成后注册回调，均只触发一次；实现保持“锁外执行 + 清空回调”保证幂等

- 建议
  - 使用 CallerRuns 背压 + 有界队列搭配 Token，防止过载与长尾
  - 设置合理的超时与取消点（I/O 边界、批处理边界、循环节拍）

- scheduler：延迟任务调度器

## 变更记录（摘）
- 修复门面递归互调问题，建立内部单例
- 通道容量=0握手语义实现；修复锁释放问题
- 调度器最小可用实现；避免与门面循环依赖



---

## 快速开始（测试与示例）
- 运行单元测试（Debug + 泄漏检测）
  - Windows: tests\fafafa.core.thread\BuildOrTest.bat test
  - Linux:   tests/fafafa.core.thread/BuildOrTest.sh test
- 运行示例（线程通道/调度器）
  - Windows: examples\fafafa.core.thread\BuildOrRun.bat run
  - 输出目录：examples/fafafa.core.thread/bin
  - 中间产物：examples/fafafa.core.thread/lib

## 公共 API 说明（摘要）
- 线程池
  - CreateThreadPool(core, max=0, keepAliveMs=60000[, queueCap, rejectPolicy]): IThreadPool
  - CreateFixedThreadPool(n): IThreadPool
  - CreateCachedThreadPool(): IThreadPool
  - CreateSingleThreadPool(): IThreadPool
  - IThreadPool.Submit(ATask: TTaskFunc; AData: Pointer=nil): IFuture
  - IThreadPool.Shutdown(); IThreadPool.AwaitTermination(timeoutMs)
- Future（在 {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES} 下提供 OnComplete/ContinueWith）
  - IFuture.WaitFor(timeoutMs=INFINITE): Boolean
  - IFuture.IsDone/IsCancelled; IFuture.Cancel
  - IFuture.OnComplete(ACallback: reference to function: Boolean)
  - IFuture.ContinueWith(ACallback: reference to function: Boolean): IFuture
- 通道（IChannel）
  - CreateChannel(capacity=0): IChannel
  - IChannel.Send(Value: Pointer; TimeoutMs=INFINITE): Boolean
  - IChannel.Recv(out Value: Pointer; TimeoutMs=INFINITE): Boolean
  - IChannel.Close
  - 语义：capacity=0 为无缓冲通道，发送/接收需配对握手
  - Token 友好重载（协作式取消）
    - Spawn/SpawnBlocking(…, Token): 预取消返回 nil
    - IThreadPool.Submit(…, Token): 预取消返回 nil；不计入队列/拒绝
    - ITaskScheduler.Schedule(…, Token): 预取消返回 nil
    - FutureWaitOrCancel(F, Token, TimeoutMs): 等待完成或取消/超时
    - 辅助：IsCancelled(Token) inline

- 调度器（ITaskScheduler）
  - CreateTaskScheduler(): ITaskScheduler
  - ITaskScheduler.Schedule(Task: TTaskFunc; DelayMs: Cardinal; Data: Pointer=nil): IFuture
  - ITaskScheduler.Shutdown
- 工具方法
  - Spawn(ATask: TTaskFunc; AData: Pointer=nil): IFuture
  - SpawnBlocking(ATask: TTaskFunc; AData: Pointer=nil): IFuture
    - 说明：SpawnBlocking 提交到独立的阻塞线程池（尺寸=min(4, max(2, CPUCount))），避免阻塞默认线程池
  - Join(const Futures: array of IFuture; TimeoutMs=INFINITE): Boolean


## Future 组合助手（纯函数）

- FutureAll(Fs, TimeoutMs): 等同 Join，全部完成返回 True
- FutureAny(Fs, TimeoutMs): 等同 Select，返回最先完成的索引（超时=-1）
- FutureTimeout(F, TimeoutMs): 等同 F.WaitFor

示例：
```
var F1,F2: IFuture; I: Integer;
F1 := Spawn(@MyTask, nil);
F2 := Spawn(@MyTask, nil);
AssertTrue(FutureAll([F1,F2], 3000));
I := FutureAny([F1,F2], 3000);
AssertTrue(I>=0);
AssertTrue(FutureTimeout(F1, 3000));
```

### Map / Then 组合助手

- FutureMap(F, Mapper, Data): 在 F 完成后执行映射函数（薄封装 IFuture.Map）
- FutureThen(F, Next, Data): 在 F 完成后执行下一个任务（薄封装 IFuture.AndThen）

示例：
```
function Nop(Data: Pointer): Boolean; begin Result := True; end;
var F1,F2: IFuture;
F1 := Spawn(@MyTask, nil);
F2 := FutureMap(F1, @Nop, nil);
AssertTrue(FutureAll([F1,F2], 3000));
F2 := FutureThen(F1, @Nop, nil);
AssertTrue(FutureAll([F1,F2], 3000));
```

### 等待或取消（FutureWaitOrCancel）

```
var F: IFuture; C := CreateCancellationTokenSource; ok: Boolean;
F := Spawn(@MyTask, nil);
// 在 3s 内等待；若用户提前取消则立即返回 False
ok := FutureWaitOrCancel(F, C.Token, 3000);
if not ok then WriteLn('cancelled or timeout');
```



## 压测指南（开发期建议）



### 取消最佳实践（Best Practices）

- 协作式取消（10行示例）：
```
function ProcessBatch(Data: Pointer): Boolean;
var i, n: Integer; Token: ICancellationToken;
begin
  n := NativeInt(Data);
  for i := 1 to n do
  begin
    if (i mod 100) = 0 then
    begin
      // 每100步检查一次是否被取消，并让权
      if IsCancelled(Token) then Exit(False);
      SysUtils.Sleep(0);
    end;
    // ... 执行一步工作 ...
  end;
  Result := True;
end;

var P: IThreadPool; C := CreateCancellationTokenSource; F: IFuture; ok: Boolean;
P := CreateFixedThreadPool(2);
F := P.Submit(@ProcessBatch, C.Token, Pointer(5000));
SysUtils.Sleep(50); C.Cancel;
ok := FutureWaitOrCancel(F, C.Token, 3000);
```

- 何时使用 Token：
  - 用户中止、请求超时、批处理停止等需要“尽早放弃未执行任务”的场景
  - 在 Spawn/SpawnBlocking/Submit/Schedule 入参处传入 Token；若已取消，则立即返回 nil，不入队


- 何时使用 Token：
  - 用户中止、请求超时、批处理停止等需要“尽早放弃未执行任务”的场景
  - 在 Spawn/SpawnBlocking/Submit/Schedule 入参处传入 Token；若已取消，则立即返回 nil，不入队

- 提交前拦截（预取消）：
  - IThreadPool.Submit(…, Token)：预取消直接返回 nil；不计入队列与拒绝计数
  - ITaskScheduler.Schedule(…, Token)：预取消直接返回 nil
  - Spawn/SpawnBlocking(…, Token)：预取消直接返回 nil

- 进行中取消（协作式）：
  - 在线程函数/方法内部，周期检查 Token.IsCancellationRequested 并尽快返回 False 结束
  - 对外等待端使用 FutureWaitOrCancel(F, Token, TimeoutMs)：统一处理“完成、取消、超时”

- 示例（≤10 行）：

- I/O 边界示例：在读/写前检查取消，避免无谓占用
```
function CopyStream(Data: Pointer): Boolean;
var Ctx: ^record InS, OutS: TStream; Token: ICancellationToken; end;
    Buf: array[0..8191] of Byte; n: Integer;
begin
  Ctx := Data; Token := Ctx^.Token;
  repeat
    if IsCancelled(Token) then Exit(False);
    n := Ctx^.InS.Read(Buf, SizeOf(Buf));
    if n<=0 then Break;
    if IsCancelled(Token) then Exit(False);
    Ctx^.OutS.WriteBuffer(Buf, n);
  until False;
  Result := True;
end;
```

- 批处理边界示例：每批次前检查并让权
```
function ProcessBatch(Data: Pointer): Boolean;
var Items: ^TList; i, batch: Integer; Token: ICancellationToken;
begin
  Items := Data; Token := GetTokenSomewhere;
  i := 0;
  while i<Items^.Count do
  begin
    if IsCancelled(Token) then Exit(False);
    for batch := 1 to 100 do
    begin
      if i>=Items^.Count then Break;
      // ... 处理 Items^[i] ...
      Inc(i);
    end;
    SysUtils.Sleep(0); // 让权，提升整体响应性
  end;
  Result := True;
end;
```

```
var P: IThreadPool; C := CreateCancellationTokenSource; F: IFuture; ok: Boolean;
P := CreateFixedThreadPool(2);
F := P.Submit(@MyFunc, C.Token, nil); // 预取消则 F=nil
ok := FutureWaitOrCancel(F, C.Token, 3000);
if not ok then WriteLn('cancelled or timeout');
```

- 约定：
  - 协作式取消不会强制中断线程；任务需自行检查 Token 并尽快退出
  - 预取消返回 nil 时不创建 Future；调用者需判空
  - 对于需要资源清理的任务，请在退出路径中完成清理

#### 协作式取消代码段示例

- 循环型任务：在合适的频率点检查取消并让权，兼顾响应性与性能
```
function LongCompute(Data: Pointer): Boolean;
var i: Integer; Token: ICancellationToken;
begin
  Token := ICancellationToken(Data); // 示例：通过 Data 传入或在闭包/对象字段中持有
  for i := 1 to 1000000 do
  begin
    if IsCancelled(Token) then Exit(False); // 尽快退出
    // ... 执行少量工作 ...
    if (i mod 1000)=0 then SysUtils.Sleep(0); // 让出时间片，提升整体公平性
  end;
  Result := True;
end;
```

- 对象方法（推荐）：将 Token 放在对象字段，避免裸指针传递
```
type TWorker = class
  Token: ICancellationToken;
  function Run(Data: Pointer): Boolean;
end;
function TWorker.Run(Data: Pointer): Boolean;
begin
  // 周期或关键点检查 Token
  if IsCancelled(Token) then Exit(False);
  Result := True;
end;
```


### 取消（最小可用）

- 类型：ICancellationToken / ICancellationTokenSource，位于 fafafa.core.thread.cancel
- 创建：`var cts := CreateCancellationTokenSource; token := cts.Token; cts.Cancel;`
- 说明：当前为协作式取消；Future/池已具备扩展点，后续将提供 WaitOrCancel/Spawn(…; Token) 重载。

### Scheduler + Token / Channel.SendTimeout 示例（≤10行）

- Scheduler + Token（预取消直接返回 nil）：
```
var S: ITaskScheduler; C := CreateCancellationTokenSource; F: IFuture;
S := CreateTaskScheduler; C.Cancel; F := S.Schedule(function (D: Pointer): Boolean begin Result:=True; end, 50, C.Token, nil);
AssertTrue(F=nil); S.Shutdown;
```

- Channel.SendTimeout（容量=0 无接收者时超时）：
```
var C: IChannel; ok: Boolean;
C := CreateChannel(0); ok := C.SendTimeout(Pointer(1), 50); AssertFalse(ok);
```


- 通道公平性（capacity=0，无缓冲）：
  - 多生产者/多消费者，各发 5k/10k 条消息；统计每消费者的分配，验证误差在 ±25% 内，总量一致。
  - 命令参考：tests\fafafa.core.thread\BuildOrTest.bat test（或在专用压测分支上增加独立 target）。
- 线程池 keepAlive 缩容：
  - 潮汐负载（爆发→静默→爆发），观测非核心线程在静默期收敛至 Core。
- 建议：在 Debug 构建下配合 FAFAFA_THREAD_DEBUG 或环境变量 FAFAFA_THREAD_LOG=1 观察行为；Release 不建议开日志。

## 指标输出为 JSON（便于前端展示）

```pascal
uses SysUtils, fafafa.core.thread;

function MetricsToJSON(const M: IThreadPoolMetrics): string;
begin
  if M=nil then Exit('{}');
  Result := Format('{"active":%d,"pool":%d,"queue":%d,"submitted":%d,"completed":%d,"rejected":%d}',
                   [M.ActiveCount, M.PoolSize, M.QueueSize, M.TotalSubmitted, M.TotalCompleted, M.TotalRejected]);
end;

var P: IThreadPool; M: IThreadPoolMetrics;
begin
  P := CreateFixedThreadPool(GetCPUCount);
  try
    M := P.GetMetrics;
    WriteLn(MetricsToJSON(M));
  finally
    P.Shutdown; P.AwaitTermination(3000);
  end;
end.
```

  - GetCPUCount(): Integer; Sleep(ms); Yield()

## 异常与错误处理
- 统一异常基类：ECore（来自 fafafa.core.base）
- 线程池：EThreadPoolError（构造/参数/拒绝策略等错误）
- Future：EFutureError、EFutureTimeoutError、EFutureCancelledError
- 参数错误：EInvalidArgument
- 重要约定：
  - 线程池内部仅将异常消息复制并包装为新的 Exception 传给 Future.Fail，避免对 RTL 管理的异常对象进行释放引发双重释放/访问违例
  - Future 的回调（OnComplete/ContinueWith）在锁外执行，且通过清空 FOnComplete 确保“调用一次”的语义

## 竞品模型对标（语义一致性）

## 调研纪要（Tokio/Go/Java 对标，2025-08-16）
- Tokio：spawn/spawn_blocking 语义已映射；回调（OnComplete/ContinueWith）一次性触发、锁外执行，避免死锁
- Go：Channel capacity=0 的同步握手语义一致；公平性测试覆盖 MPMC 场景
- Java：ThreadPoolExecutor keepAlive/拒绝策略对齐；CompletableFuture thenApply/thenCompose→Map/AndThen
- FPC 跨平台：Event/Mutex 在 Windows 使用内核对象；Unix 使用 pthread/cond 组合；部分带超时路径采用简化轮询以求稳定

- Rust Tokio
  - spawn：在默认运行时线程池执行任务 → 对应 Spawn
  - spawn_blocking：阻塞型任务 → 对应 SpawnBlocking（内部阻塞池，大小=min(4,max(2,CPU)))
- Go channel
  - 容量=0：无缓冲通道需发送/接收握手 → IChannel capacity=0 保证配对语义
  - 容量>0：有缓冲通道 → IChannel 支持设置 capacity
- Java
  - ThreadPoolExecutor.keepAliveTime：非核心线程空闲超时回收；可扩展 allowCoreThreadTimeOut → 本实现默认回收非核心线程；核心线程保持；可按需求扩展
  - CompletableFuture.thenApply/thenCompose → Map/AndThen/ContinueWith/OnComplete 提供等效组合

## 行为与注意事项
- OnComplete/ContinueWith
  - 回调只调用一次，且在锁外调用；若需要多回调可用链式组合
- Channel 无缓冲语义
  - 发送先/接收先均能正确配对；并发下需注意公平性，框架提供基础保证并有相关测试
- 线程池 keepAlive
  - 非核心线程在空闲保持期后收缩；可通过测试验证收敛至核心线程数
- 平台与中文输出
  - Unix 控制台程序需首单元 uses cthreads
  - 带中文输出的测试/示例加 {$CODEPAGE UTF8}；类库单元不加


## Join / Select 使用速览（简版）

更多边界与异常语义见：docs/fafafa.core.thread.boundaries.md

- Join：等待一组 Future 全部完成（可超时）
  示例：

```
var F1,F2,F3: IFuture;
F1 := Spawn(@MyTask, Pointer(1));
F2 := Spawn(@MyTask, Pointer(2));
F3 := Spawn(@MyTask, Pointer(3));
AssertTrue(Join([F1,F2,F3], 3000));
```

## 故障排查（Metrics 为 0 的常见原因）
- 未开启开关：
  - 调度器：TTaskScheduler.SetObservedMetricsEnabled(True) 或设置环境变量 FAFAFA_SCHED_METRICS=1
  - 线程池：TThreadPool.SetObservedMetricsEnabled(True) 或设置环境变量 FAFAFA_POOL_METRICS=1
- 没有产生样本：
  - 例：没有提交任务（线程池）或没有调度任务（调度器），计数为 0 时均值自然为 0
- 计时粒度限制：
  - Windows/Linux 下示例实现以毫秒粒度计时，极短的驻留/延迟会被四舍五入为 0
  - 建议用稍长延迟或更高压力来观测平均值
- 度量在进程级：
  - 环境变量开关在进程内生效；不同进程分别控制，不会跨进程影响

- Select（任意一个完成）：当前可通过轻量轮询实现，后续提供一等 API。
  建议：
  - 轻量：循环 WaitFor(50) + IsDone 检查
  - 重量：将 Future.OnComplete 链到共享通道，由通道实现“谁先完成谁先投递”

注意：Join/Select 不改变 Future 生命周期；接口引用计数自动释放。
