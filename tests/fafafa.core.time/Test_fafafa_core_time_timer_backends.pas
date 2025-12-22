unit Test_fafafa_core_time_timer_backends;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

{*
  定时器后端工厂测试

  验证 ITimerQueueBackend 工厂函数的基本功能：
  - 工厂注册机制
  - 后端创建
  - 后端名称

  注意：完整的后端功能测试需要与 TTimerSchedulerImpl 集成，
  因为后端操作的 Entry 结构与调度器紧耦合。
*}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time.timer.backend,
  fafafa.core.time.timer.backend.heap,
  fafafa.core.time.timer.backend.wheel;

type
  TTestCase_TimerBackends = class(TTestCase)
  published
    // 工厂函数测试
    procedure Test_CreateBinaryHeapBackend_ReturnsNonNil;
    procedure Test_CreateBinaryHeapBackend_CorrectName;
    procedure Test_CreateHashedWheelBackend_ReturnsNonNil;
    procedure Test_CreateHashedWheelBackend_CorrectName;
    procedure Test_CreateHashedWheelBackend_CustomConfig;
    procedure Test_CreateDefaultBackend_IsBinaryHeap;

    // 后端基础属性测试
    procedure Test_BinaryHeap_InitiallyEmpty;
    procedure Test_HashedWheel_InitiallyEmpty;
  end;

implementation

{ 工厂函数测试 }

procedure TTestCase_TimerBackends.Test_CreateBinaryHeapBackend_ReturnsNonNil;
var
  backend: ITimerQueueBackend;
begin
  backend := CreateBinaryHeapBackend;
  CheckTrue(backend <> nil, 'CreateBinaryHeapBackend should return non-nil');
end;

procedure TTestCase_TimerBackends.Test_CreateBinaryHeapBackend_CorrectName;
var
  backend: ITimerQueueBackend;
begin
  backend := CreateBinaryHeapBackend;
  CheckEquals('BinaryHeap', backend.GetName, 'Name should be BinaryHeap');
end;

procedure TTestCase_TimerBackends.Test_CreateHashedWheelBackend_ReturnsNonNil;
var
  backend: ITimerQueueBackend;
begin
  backend := CreateHashedWheelBackend;
  CheckTrue(backend <> nil, 'CreateHashedWheelBackend should return non-nil');
end;

procedure TTestCase_TimerBackends.Test_CreateHashedWheelBackend_CorrectName;
var
  backend: ITimerQueueBackend;
begin
  backend := CreateHashedWheelBackend;
  CheckEquals('HashedWheel', backend.GetName, 'Name should be HashedWheel');
end;

procedure TTestCase_TimerBackends.Test_CreateHashedWheelBackend_CustomConfig;
var
  backend: ITimerQueueBackend;
begin
  // 测试自定义配置
  backend := CreateHashedWheelBackend(128, 5);
  CheckTrue(backend <> nil, 'CreateHashedWheelBackend with custom config should work');
  CheckEquals('HashedWheel', backend.GetName, 'Name should be HashedWheel');
end;

procedure TTestCase_TimerBackends.Test_CreateDefaultBackend_IsBinaryHeap;
var
  backend: ITimerQueueBackend;
begin
  backend := CreateDefaultBackend;
  CheckTrue(backend <> nil, 'CreateDefaultBackend should return non-nil');
  CheckEquals('BinaryHeap', backend.GetName, 'Default backend should be BinaryHeap');
end;

{ 后端基础属性测试 }

procedure TTestCase_TimerBackends.Test_BinaryHeap_InitiallyEmpty;
var
  backend: ITimerQueueBackend;
begin
  backend := CreateBinaryHeapBackend;
  CheckEquals(0, backend.Count, 'Initial count should be 0');
  CheckTrue(backend.IsEmpty, 'Should be empty initially');
end;

procedure TTestCase_TimerBackends.Test_HashedWheel_InitiallyEmpty;
var
  backend: ITimerQueueBackend;
begin
  backend := CreateHashedWheelBackend;
  CheckEquals(0, backend.Count, 'Initial count should be 0');
  CheckTrue(backend.IsEmpty, 'Should be empty initially');
end;

initialization
  RegisterTest(TTestCase_TimerBackends);

end.
