unit fafafa.core.sync.stampedlock.base;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  IStampedLock - 乐观读写锁接口（base unit）

  参照 Java StampedLock 的语义：
  - 支持乐观读（无锁读取，通过 stamp 验证）
  - 支持悲观读（传统读锁）
  - 支持写锁

  乐观读模式：
  1. 调用 TryOptimisticRead 获取 stamp
  2. 读取数据
  3. 调用 Validate(stamp) 验证是否有写操作发生
  4. 如果验证失败，升级为悲观读

  使用示例：
    var
      Lock: IStampedLock;
      Stamp: Int64;
      Data: Integer;
    begin
      Stamp := Lock.TryOptimisticRead;
      Data := SharedData;
      if not Lock.Validate(Stamp) then
      begin
        Stamp := Lock.ReadLock;
        try
          Data := SharedData;
        finally
          Lock.UnlockRead(Stamp);
        end;
      end;
    end;
}

interface

uses
  fafafa.core.sync.base;

type

  IStampedLock = interface(ISynchronizable)
    ['{E7F8A1B2-3C4D-5E6F-7A8B-9C0D1E2F3A4B}']

    {**
     * WriteLock - 获取写锁
     * @return stamp 用于解锁
     *}
    function WriteLock: Int64;

    {**
     * TryWriteLock - 尝试获取写锁（不阻塞）
     * @return stamp，失败返回 0
     *}
    function TryWriteLock: Int64;

    {**
     * UnlockWrite - 释放写锁
     * @param AStamp 获取时返回的 stamp
     *}
    procedure UnlockWrite(AStamp: Int64);

    {**
     * ReadLock - 获取悲观读锁
     * @return stamp 用于解锁
     *}
    function ReadLock: Int64;

    {**
     * TryReadLock - 尝试获取读锁（不阻塞）
     * @return stamp，失败返回 0
     *}
    function TryReadLock: Int64;

    {**
     * UnlockRead - 释放读锁
     * @param AStamp 获取时返回的 stamp
     *}
    procedure UnlockRead(AStamp: Int64);

    {**
     * TryOptimisticRead - 获取乐观读 stamp
     * @return stamp，如果当前有写锁返回 0
     *}
    function TryOptimisticRead: Int64;

    {**
     * Validate - 验证乐观读是否有效
     * @param AStamp TryOptimisticRead 返回的 stamp
     * @return 如果期间没有写操作返回 True
     *}
    function Validate(AStamp: Int64): Boolean;

    {**
     * IsWriteLocked - 检查是否有写锁
     *}
    function IsWriteLocked: Boolean;

    {**
     * GetReadLockCount - 获取当前读锁数量
     *}
    function GetReadLockCount: Integer;
  end;

implementation

end.
