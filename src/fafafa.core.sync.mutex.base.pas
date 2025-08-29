unit fafafa.core.sync.mutex.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fafafa.core.sync.base;

type
  // ===== RAII 互斥锁守护接口（前向声明）=====
  IMutexGuard = interface
    ['{D1E2F3A4-B5C6-7D8E-9F0A-1B2C3D4E5F6A}']
    // RAII 模式：构造时自动获取锁，析构时自动释放锁
    // 不需要手动方法，完全依赖生命周期管理
  end;

  // ===== 标准可重入互斥锁接口（主流标准）=====
  IMutex = interface(ILock)
    ['{B8F5A2E1-4C3D-4F2A-9B1E-8D7C6A5F4E3D}']
    // 继承 ILock 的核心方法：Acquire, Release, TryAcquire（无超时）
    // 可重入：同一线程可以多次获取锁，对应多次释放

    // 互斥锁特有的方法
    function GetHandle: Pointer; // 返回平台特定的句柄，用于与条件变量等配合使用
    function GetHoldCount: Integer; // 获取当前线程的重入次数（可选实现）
    function IsHeldByCurrentThread: Boolean; // 检查是否被当前线程持有

    // RAII 支持
    function Lock: IMutexGuard; // 创建 RAII 守护对象，自动管理锁的生命周期
    function TryLock: IMutexGuard; // 尝试创建 RAII 守护对象，失败返回 nil
  end;

  // ===== 非重入互斥锁接口（特殊用途）=====
  INonReentrantMutex = interface(ILock)
    ['{C9E2F4A6-5D8B-4E7C-9F1A-2B3C4D5E6F7A}']
    // 继承 ILock 的核心方法：Acquire, Release, TryAcquire（无超时）
    // 不可重入：同一线程重复获取会失败或阻塞

    // 非重入互斥锁特有的方法
    function GetHandle: Pointer; // 返回平台特定的句柄
  end;

implementation


end.
