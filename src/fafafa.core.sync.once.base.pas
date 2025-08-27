unit fafafa.core.sync.once.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base, fafafa.core.sync.base;

type
  // ===== 一次性执行状态 =====
  TOnceState = (
    osNotStarted,   // 尚未开始执行
    osInProgress,   // 正在执行中
    osCompleted     // 已完成执行
  );

  // ===== 回调函数类型 =====
  TOnceProc = procedure;
  TOnceMethod = procedure of object;
  TOnceAnonymousProc = reference to procedure;

  // ===== 一次性执行接口 =====
  IOnce = interface(ILock)
    ['{A1B2C3D4-E5F6-7G8H-9I0J-K1L2M3N4O5P6}']

    // 继承自 ILock 的方法：
    // - procedure Acquire;           // 执行一次性操作（如果尚未执行）
    // - procedure Release;           // 对于 once 语义，此方法为空操作
    // - function TryAcquire: Boolean; // 尝试执行一次性操作，如果已执行则立即返回 True

    // 核心方法：执行构造时传入的回调
    procedure Execute;

    // 状态查询
    function GetState: TOnceState;
    function IsCompleted: Boolean;
    function IsInProgress: Boolean;

    // 重置功能（主要用于测试，生产环境慎用）
    procedure Reset;
  end;

implementation

end.
