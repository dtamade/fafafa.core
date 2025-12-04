unit fafafa.core.sync.condvar.base;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base, fafafa.core.sync.mutex.base; // for ILock, IMutex

type

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
     *   才能保证“原子释放+等待”的强语义。其他 ILock 实现
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

    { 唤醒一个等待线程 }
    procedure Signal;

    { 唤醒所有等待线程 }
    procedure Broadcast;
  end;

implementation

end.


