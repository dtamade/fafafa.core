unit fafafa.core.sync.mutex.base;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses SysUtils, fafafa.core.sync.base;

type

  {**
   * EMutexPoisonError - Mutex 毒化异常
   *
   * @desc
   *   当 Mutex 被毒化后尝试获取锁时抛出。
   *   类似 Rust 的 PoisonError<MutexGuard>.
   *}
  EMutexPoisonError = class(ELockError)
  private
    FPoisoningThreadId: TThreadID;
    FPoisoningException: string;
  public
    constructor Create(APoisoningThreadId: TThreadID; const APoisoningException: string);
    property PoisoningThreadId: TThreadID read FPoisoningThreadId;
    property PoisoningException: string read FPoisoningException;
  end;

  {**
   * @desc 互斥锁接口
   * @details 提供互斥锁功能，支持 Poison 机制
   *
   * @poison_mechanism
   * Poison 机制用于检测线程在持有锁时发生异常的情况：
   *
   * 1. **Poison 触发条件**：
   *    - 线程在持有锁时抛出未捕获的异常
   *    - 守卫析构时检测到异常状态
   *
   * 2. **Poison 状态**：
   *    - 锁被标记为 "poisoned"
   *    - `IsPoisoned()` 返回 True
   *
   * 3. **Poison 影响**：
   *    - 后续 `Lock()` 调用返回 poisoned 守卫
   *    - 守卫的 `IsPoisoned()` 方法返回 True
   *    - 可以选择忽略 poison 状态继续使用
   *
   * 4. **Poison 恢复**：
   *    - 调用 `ClearPoison()` 清除 poison 状态
   *    - 或者通过守卫继续使用（自行承担风险）
   *
   * @usage
   *   // 基本使用
   *   var guard := mutex.Lock();
   *   try
   *     // 临界区代码
   *   finally
   *     guard := nil;
   *   end;
   *
   *   // 检查 Poison 状态
   *   if mutex.IsPoisoned() then
   *   begin
   *     WriteLn('Warning: Mutex is poisoned!');
   *     mutex.ClearPoison();  // 清除 poison 状态
   *   end;
   *
   *   // 使用 poisoned 守卫
   *   var guard := mutex.Lock();
   *   if guard.IsPoisoned() then
   *   begin
   *     WriteLn('Warning: Guard is poisoned, but continuing...');
   *     // 自行承担风险继续使用
   *   end;
   *
   * @thread_safety 线程安全
   * @rust_equivalent std::sync::Mutex
   *}
  IMutex = interface(ITryLock)
    ['{55391DAE-AC96-4911-B998-FC8D2675FA2A}']
    function GetHandle: Pointer; // 返回平台特定的句柄

    // ===== Poisoning 支持 (Rust-style) =====
    {**
     * @desc 检查锁是否处于 poisoned 状态
     * @returns 如果锁被 poison 返回 True，否则返回 False
     *}
    function IsPoisoned: Boolean;

    {**
     * @desc 清除锁的 poison 状态
     * @details 清除后，锁恢复正常状态，可以安全使用
     *}
    procedure ClearPoison;

    {**
     * @desc 标记锁为 poisoned 状态
     * @param AExceptionMessage 导致毒化的异常信息
     * @details 手动标记 Mutex 为毒化状态，通常由 Guard 在异常时自动调用
     *}
    procedure MarkPoisoned(const AExceptionMessage: string);
  end;

implementation

{ EMutexPoisonError }

constructor EMutexPoisonError.Create(APoisoningThreadId: TThreadID; const APoisoningException: string);
begin
  inherited CreateFmt('Mutex is poisoned by thread %d: %s', [APoisoningThreadId, APoisoningException]);
  FPoisoningThreadId := APoisoningThreadId;
  FPoisoningException := APoisoningException;
end;

end.
