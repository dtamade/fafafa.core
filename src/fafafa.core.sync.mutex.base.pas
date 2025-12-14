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

  IMutex = interface(ITryLock)
    ['{55391DAE-AC96-4911-B998-FC8D2675FA2A}']
    function GetHandle: Pointer; // 返回平台特定的句柄

    // ===== Poisoning 支持 (Rust-style) =====
    {**
     * IsPoisoned - 检查 Mutex 是否被毒化
     *
     * @return True 如果 Mutex 已被毒化
     *
     * @desc
     *   当持有锁的线程在异常中死亡时，Mutex 会被标记为毒化。
     *   后续的获取操作将失败或抛出异常。
     *}
    function IsPoisoned: Boolean;

    {**
     * ClearPoison - 清除毒化状态
     *
     * @desc
     *   恢复 Mutex 到正常状态。
     *   通常用于确认数据已被恢复或不需要关心后。
     *}
    procedure ClearPoison;

    {**
     * MarkPoisoned - 标记为毒化
     *
     * @param AExceptionMessage 导致毒化的异常信息
     *
     * @desc
     *   手动标记 Mutex 为毒化状态。
     *   通常由 Guard 在异常时自动调用。
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
