unit fafafa.core.sync.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes;

type
  // ===== Exceptions =====
  ESyncError = class(Exception);
  ELockError = class(ESyncError);
  ETimeoutError = class(ESyncError);
  EDeadlockError = class(ESyncError);
  EOnceRecursiveCall = class(ELockError);

  // ===== Enums =====
  TLockState = (
    lsUnlocked,
    lsLocked,
    lsAbandoned
  );

  TWaitResult = (
    wrSignaled,     // 信号状态
    wrTimeout,      // 超时
    wrAbandoned,    // 被放弃 (拥有者异常终止)
    wrError,        // 一般错误
    wrInterrupted   // 被信号中断 (Unix)
  );

  { 详细错误码 }
  TWaitError = (
    weNone,              // 无错误
    weTimeout,           // 超时
    weInvalidHandle,     // 无效句柄
    weResourceExhausted, // 资源耗尽
    weAccessDenied,      // 访问被拒绝
    weDeadlock,          // 检测到死锁
    weNotSupported,      // 功能不支持
    weSystemError,       // 系统错误

    // 自旋锁特有错误类型
    weInvalidState,      // 无效状态
    weReentrancy,        // 重入错误
    weNotOwner,          // 非所有者释放
    weAlreadyReleased    // 重复释放
  );

  // ===== Interfaces =====

  { 基础同步原语接口 - 所有同步对象的基础 }
  ISynchronizable = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    function GetLastError: TWaitError;
  end;

  { 互斥锁接口 }
  ILock = interface(ISynchronizable)
    ['{B8F5A2E1-4C3D-4F2A-9B1E-8D7C6A5F4E3D}']
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
  end;

  { 基础读写锁接口 }
  IReadWriteLock = interface(ISynchronizable)
    ['{C9D0E1F2-A3B4-5C6D-9E0F-1A2B3C4D5E6F}']
    // 读锁操作
    procedure AcquireRead;
    procedure ReleaseRead;
    function TryAcquireRead: Boolean; overload;
    function TryAcquireRead(ATimeoutMs: Cardinal): Boolean; overload;

    // 写锁操作
    procedure AcquireWrite;
    procedure ReleaseWrite;
    function TryAcquireWrite: Boolean; overload;
    function TryAcquireWrite(ATimeoutMs: Cardinal): Boolean; overload;

    // 基础状态查询
    function GetReaderCount: Integer;
    function IsWriteLocked: Boolean;
  end;

implementation


end.

