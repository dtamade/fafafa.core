unit fafafa.core.sync.mutex.parkinglot;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.mutex.parkinglot.base
  {$IFDEF WINDOWS}, fafafa.core.sync.mutex.parkinglot.windows{$ENDIF}
  {$IFDEF UNIX}, fafafa.core.sync.mutex.parkinglot.unix{$ENDIF};

type
  {**
   * IParkingLotMutex - 高性能 Parking Lot 互斥锁接口
   *
   * @desc
   *   基于 Rust parking_lot 设计的高性能互斥锁。
   *   使用原子操作 + 智能自旋 + 系统级等待的混合策略。
   *}
  IParkingLotMutex = fafafa.core.sync.mutex.parkinglot.base.IParkingLotMutex;

  {**
   * TParkingLotMutex - 平台特定的 Parking Lot 互斥锁实现类型别名
   *
   * @desc
   *   在 Windows 平台使用 WaitOnAddress/WakeByAddressSingle 实现，
   *   在 Unix 平台使用 futex 或智能退避策略实现。
   *   具体实现由编译时配置决定。
   *}
  {$IFDEF WINDOWS}
  TParkingLotMutex = fafafa.core.sync.mutex.parkinglot.windows.TParkingLotMutex;
  {$ENDIF}
  {$IFDEF UNIX}
  TParkingLotMutex = fafafa.core.sync.mutex.parkinglot.unix.TParkingLotMutex;
  {$ENDIF}

{**
 * MakeParkingLotMutex - 创建 Parking Lot 互斥锁实例
 *
 * @return 新创建的 Parking Lot 互斥锁接口
 *
 * @desc
 *   工厂函数，创建平台特定的 Parking Lot 互斥锁实现。
 *   返回的接口支持高性能的锁操作和公平性控制。
 *
 * @performance
 *   在大多数场景下性能优于传统 mutex：
 *   - 低竞争：接近自旋锁性能
 *   - 中等竞争：智能自旋减少上下文切换
 *   - 高竞争：系统等待避免 CPU 浪费
 *
 * @usage
 *   var mutex: IParkingLotMutex;
 *   begin
 *     mutex := MakeParkingLotMutex;
 *     mutex.Acquire;
 *     try
 *       // 临界区代码
 *     finally
 *       mutex.Release;
 *     end;
 *   end;
 *}
function MakeParkingLotMutex: IParkingLotMutex;

implementation

function MakeParkingLotMutex: IParkingLotMutex;
begin
  {$IF DEFINED(WINDOWS)}
    Result := fafafa.core.sync.mutex.parkinglot.windows.MakeParkingLotMutex();
  {$ELSEIF DEFINED(UNIX)}
    Result := fafafa.core.sync.mutex.parkinglot.unix.MakeParkingLotMutex();
  {$ELSE}
    {$ERROR 'Unsupported platform for fafafa.core.sync.mutex.parkinglot'}
  {$ENDIF}
end;

end.
