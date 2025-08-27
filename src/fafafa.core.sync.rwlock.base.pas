unit fafafa.core.sync.rwlock.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base, fafafa.core.sync.base;

type
  // ===== 锁操作结果枚举 =====
  TLockResult = (
    lrSuccess,      // 成功获取锁
    lrTimeout,      // 超时
    lrWouldBlock,   // 会阻塞（非阻塞调用）
    lrError         // 错误
  );

  // ===== 读锁守卫接口 =====
  IRWLockReadGuard = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    // RAII 读锁守卫，析构时自动释放读锁
    // 无需手动方法，依赖接口引用计数自动释放
  end;

  // ===== 写锁守卫接口 =====
  IRWLockWriteGuard = interface
    ['{B2C3D4E5-F6A7-8901-BCDE-F12345678901}']
    // RAII 写锁守卫，析构时自动释放写锁
    // 无需手动方法，依赖接口引用计数自动释放
  end;

  // ===== RWLock 主接口 =====
  IRWLock = interface
    ['{C3D4E5F6-A7B8-9012-CDEF-123456789012}']
    // ===== 现代化 API（推荐使用）=====
    function Read: IRWLockReadGuard;
    function Write: IRWLockWriteGuard;
    function TryRead(ATimeoutMs: Cardinal = 0): IRWLockReadGuard;
    function TryWrite(ATimeoutMs: Cardinal = 0): IRWLockWriteGuard;

    // ===== 传统 API（向后兼容）=====
    procedure AcquireRead;
    procedure ReleaseRead;
    procedure AcquireWrite;
    procedure ReleaseWrite;
    function TryAcquireRead: Boolean; overload;
    function TryAcquireRead(ATimeoutMs: Cardinal): TLockResult; overload;
    function TryAcquireWrite: Boolean; overload;
    function TryAcquireWrite(ATimeoutMs: Cardinal): TLockResult; overload;

    // ===== 状态查询 =====
    function GetReaderCount: Integer;
    function IsWriteLocked: Boolean;
    function IsReadLocked: Boolean;
    function GetWriterThread: TThreadID;
    function GetMaxReaders: Integer;
  end;

implementation

end.
