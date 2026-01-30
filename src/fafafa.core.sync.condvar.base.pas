unit fafafa.core.sync.condvar.base;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base; // for ILock

type

  {**
   * TCondVarWaitResult - Rust-style condition variable wait result
   *
   * @desc
   *   Lightweight value type representing the result of a timed condvar wait.
   *   Zero heap allocation, stack-allocated like Rust's WaitTimeoutResult.
   *
   * @rust_equivalent std::sync::WaitTimeoutResult
   *
   * @example
   *   result := condvar.WaitFor(lock, 1000);
   *   if result.TimedOut then
   *     WriteLn('Wait timed out after 1 second');
   *}
  TCondVarWaitResult = record
  private
    FTimedOut: Boolean;
  public
    {**
     * TimedOut - Check if the wait timed out
     *
     * @return True if the wait timed out before being signaled,
     *         False if the wait was woken by Signal/Broadcast
     *
     * @rust_equivalent WaitTimeoutResult::timed_out()
     *}
    function TimedOut: Boolean; inline;

    {**
     * Create a result indicating the wait was signaled (not timed out)
     *}
    class function Signaled: TCondVarWaitResult; static; inline;

    {**
     * Create a result indicating the wait timed out
     *}
    class function Timeout: TCondVarWaitResult; static; inline;
  end;

  {**
   * ICondVar - 条件变量接口
   *
   * @desc
   *   提供线程间的等待/通知机制。
   *
   * @warning
   *   Wait(ILock) 接受任意 ILock，但只有 IMutex 能保证原子语义。
   *   传入其他类型的锁可能导致微妙的竞态条件。
   *   建议优先使用 IMutex 作为参数。
   *
   * @semantics
   *   - Wait(IMutex): 保证原子释放+等待（推荐）
   *   - Wait(ILock):  近似行为，可能有竞态窗口（慎用）
   *
   * @spurious_wakeups
   * **虚假唤醒（Spurious Wakeups）**：
   *
   * 条件变量可能在没有被显式 Signal/Broadcast 的情况下唤醒等待线程。
   * 这是所有条件变量实现的固有特性，不是 bug。
   *
   * **原因**：
   * 1. 操作系统调度：内核可能在信号处理或线程调度时唤醒线程
   * 2. 多核竞态：在多核系统上，Signal 和 Wait 之间的竞态条件
   * 3. 实现优化：某些平台为了性能优化允许虚假唤醒
   *
   * **正确处理方式**：
   * 始终在循环中检查条件，而不是使用 if 语句：
   *
   * ```pascal
   * // ✅ 正确：使用 while 循环
   * var guard := mutex.Lock();
   * try
   *   while not condition do
   *     condvar.Wait(guard);
   *   // 条件满足，执行操作
   * finally
   *   guard := nil;
   * end;
   *
   * // ❌ 错误：使用 if 语句
   * var guard := mutex.Lock();
   * try
   *   if not condition then
   *     condvar.Wait(guard);  // 虚假唤醒后条件可能仍不满足！
   *   // 可能在条件不满足时执行操作
   * finally
   *   guard := nil;
   * end;
   * ```
   *
   * **为什么必须使用循环**：
   * 1. 防止虚假唤醒：即使没有 Signal，线程也可能被唤醒
   * 2. 处理多线程竞争：多个线程可能同时被唤醒，但只有一个能满足条件
   * 3. 保证正确性：确保在条件真正满足时才继续执行
   *
   * **超时等待的处理**：
   * 带超时的等待也需要循环检查：
   *
   * ```pascal
   * var guard := mutex.Lock();
   * try
   *   while not condition do
   *   begin
   *     if not condvar.Wait(guard, 1000) then
   *     begin
   *       // 超时处理
   *       Exit;
   *     end;
   *   end;
   *   // 条件满足，执行操作
   * finally
   *   guard := nil;
   * end;
   * ```
   *
   * @posix_equivalent pthread_cond_wait (允许虚假唤醒)
   * @windows_equivalent SleepConditionVariableCS (允许虚假唤醒)
   * @rust_equivalent std::sync::Condvar (文档明确说明虚假唤醒)
   *}
  ICondVar = interface(ISynchronizable)
    ['{F9CAE7D8-8A7B-4E5F-9C8D-7B6A5E4D3C2B}']

    {**
     * Wait - 等待条件变量（接受任意 ILock）
     *
     * @param ALock 要释放的锁
     *
     * @warning
     *   只有当 ALock 实际是 IMutex 并提供底层 pthread_mutex_t 时，
     *   才能保证"原子释放+等待"的强语义。其他 ILock 实现
     *   只能提供近似行为，极端竞态下可能遗漏唤醒。
     *}
    procedure Wait(const ALock: ILock); overload;

    {**
     * Wait - 带超时的等待
     *
     * @param ALock 要释放的锁
     * @param ATimeoutMs 超时时间（毫秒）
     * @return True 如果被唤醒，False 如果超时
     *
     * @warning 同 Wait(ILock)
     *}
    function Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean; overload;

    {**
     * WaitFor - Modern API: 带超时的等待，返回结果值 (Rust-style)
     *
     * @param ALock 要释放的锁
     * @param ATimeoutMs 超时时间（毫秒）
     * @return TCondVarWaitResult 包含超时状态的结果值（栈分配，零堆开销）
     *
     * @rust_equivalent Condvar::wait_timeout() -> WaitTimeoutResult
     *
     * @example
     *   result := condvar.WaitFor(lock, 1000);
     *   if result.TimedOut then
     *     // 超时处理
     *   else
     *     // 被唤醒
     *}
    function WaitFor(const ALock: ILock; ATimeoutMs: Cardinal): TCondVarWaitResult;

    { 唤醒一个等待线程 }
    procedure Signal;

    { 唤醒所有等待线程 }
    procedure Broadcast;
  end;

implementation

{ TCondVarWaitResult }

function TCondVarWaitResult.TimedOut: Boolean;
begin
  Result := FTimedOut;
end;

class function TCondVarWaitResult.Signaled: TCondVarWaitResult;
begin
  Result.FTimedOut := False;
end;

class function TCondVarWaitResult.Timeout: TCondVarWaitResult;
begin
  Result.FTimedOut := True;
end;

end.
