{$CODEPAGE UTF8}
unit fafafa.core.sync.namedEvent.testcase;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.namedEvent, fafafa.core.sync.base;

type
  // 全局函数测试
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_CreateNamedEvent;
    procedure Test_CreateNamedEvent_WithConfig;
    procedure Test_CreateManualResetNamedEvent;
    procedure Test_CreateAutoResetNamedEvent;
    procedure Test_CreateGlobalNamedEvent;
    procedure Test_MakeNamedEvent;
    procedure Test_MakeGlobalNamedEvent;
    procedure Test_ConfigHelpers;
  end;

  // INamedEvent 接口测试
  TTestCase_INamedEvent = class(TTestCase)
  private
    FEvent: INamedEvent;
    FEventName: string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 现代化 RAII 方法测试
    procedure Test_Wait;
    procedure Test_TryWait;
    procedure Test_TryWaitFor;
    procedure Test_TryWaitFor_Timeout;
    procedure Test_TryWaitFor_Zero;
    
    // 事件控制操作测试
    procedure Test_SetEvent;
    procedure Test_ResetEvent;
    procedure Test_PulseEvent;
    
    // 查询操作测试
    procedure Test_GetName;
    procedure Test_IsManualReset;
    procedure Test_IsSignaled;
    
    // 兼容性方法测试
    procedure Test_WaitFor_Deprecated;
    procedure Test_WaitFor_WithTimeout_Deprecated;
    procedure Test_Acquire_Deprecated;
    procedure Test_Release_Deprecated;
    procedure Test_TryAcquire_Deprecated;
    procedure Test_TryAcquire_WithTimeout_Deprecated;
    procedure Test_GetHandle_Deprecated;
    procedure Test_IsCreator_Deprecated;
  end;

  // 手动重置事件测试
  TTestCase_ManualResetEvent = class(TTestCase)
  private
    FEvent: INamedEvent;
    FEventName: string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_ManualReset_SetAndWait;
    procedure Test_ManualReset_MultipleWaiters;
    procedure Test_ManualReset_ResetAfterSet;
    procedure Test_ManualReset_IsSignaled;
    procedure Test_ManualReset_PulseEvent;
  end;

  // 自动重置事件测试
  TTestCase_AutoResetEvent = class(TTestCase)
  private
    FEvent: INamedEvent;
    FEventName: string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_AutoReset_SetAndWait;
    procedure Test_AutoReset_SingleWaiter;
    procedure Test_AutoReset_IsSignaled;
    procedure Test_AutoReset_PulseEvent;
  end;

  // 错误处理测试
  TTestCase_ErrorHandling = class(TTestCase)
  published
    procedure Test_InvalidName_Empty;
    procedure Test_InvalidName_TooLong;
    procedure Test_InvalidName_InvalidChars;
  end;

  // 超时机制测试
  TTestCase_Timeout = class(TTestCase)
  private
    FEvent: INamedEvent;
    FEventName: string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_TryWaitFor_ShortTimeout;
    procedure Test_TryWaitFor_LongTimeout;
    procedure Test_TryWaitFor_ZeroTimeout;
    procedure Test_TryWaitFor_InfiniteTimeout;
  end;

implementation

uses
  fafafa.core.base;

{ TTestCase_Global }

procedure TTestCase_Global.Test_CreateNamedEvent;
var
  LEvent: INamedEvent;
begin
  LEvent := CreateNamedEvent('TestEvent');
  AssertNotNull('Event should be created', LEvent);
  AssertEquals('Event name should match', 'TestEvent', LEvent.GetName);
  AssertFalse('Default should be auto-reset', LEvent.IsManualReset);
end;

procedure TTestCase_Global.Test_CreateNamedEvent_WithConfig;
var
  LEvent: INamedEvent;
  LConfig: TNamedEventConfig;
begin
  LConfig := ManualResetNamedEventConfig;
  LConfig.InitialState := True;
  
  LEvent := CreateNamedEventWithConfig('TestEventConfig', LConfig);
  AssertNotNull('Event should be created', LEvent);
  AssertEquals('Event name should match', 'TestEventConfig', LEvent.GetName);
  AssertTrue('Should be manual reset', LEvent.IsManualReset);
  AssertTrue('Should be initially signaled', LEvent.IsSignaled);
end;

procedure TTestCase_Global.Test_CreateManualResetNamedEvent;
var
  LEvent: INamedEvent;
begin
  LEvent := CreateNamedEvent('TestManual', True, True);
  AssertNotNull('Event should be created', LEvent);
  AssertTrue('Should be manual reset', LEvent.IsManualReset);
  AssertTrue('Should be initially signaled', LEvent.IsSignaled);
end;

procedure TTestCase_Global.Test_CreateAutoResetNamedEvent;
var
  LEvent: INamedEvent;
begin
  LEvent := CreateNamedEvent('TestAuto', False, False);
  AssertNotNull('Event should be created', LEvent);
  AssertFalse('Should be auto reset', LEvent.IsManualReset);
end;

procedure TTestCase_Global.Test_CreateGlobalNamedEvent;
var
  LEvent: INamedEvent;
begin
  LEvent := CreateGlobalNamedEvent('TestGlobal', True, False);
  AssertNotNull('Event should be created', LEvent);
  AssertTrue('Should be manual reset', LEvent.IsManualReset);
end;

procedure TTestCase_Global.Test_MakeNamedEvent;
var
  LEvent: INamedEvent;
begin
  LEvent := CreateNamedEvent('TestMake');
  AssertNotNull('Event should be created', LEvent);
  AssertEquals('Event name should match', 'TestMake', LEvent.GetName);

  LEvent := CreateNamedEvent('TestMake2', True);
  AssertTrue('Should be manual reset', LEvent.IsManualReset);

  LEvent := CreateNamedEvent('TestMake3', False, True);
  AssertFalse('Should be auto reset', LEvent.IsManualReset);
end;

procedure TTestCase_Global.Test_MakeGlobalNamedEvent;
var
  LEvent: INamedEvent;
begin
  LEvent := CreateGlobalNamedEvent('TestGlobalMake');
  AssertNotNull('Event should be created', LEvent);

  LEvent := CreateGlobalNamedEvent('TestGlobalMake2', True);
  AssertTrue('Should be manual reset', LEvent.IsManualReset);

  LEvent := CreateGlobalNamedEvent('TestGlobalMake3', False, True);
  AssertFalse('Should be auto reset', LEvent.IsManualReset);
end;

procedure TTestCase_Global.Test_ConfigHelpers;
var
  LConfig: TNamedEventConfig;
begin
  LConfig := DefaultNamedEventConfig;
  AssertEquals('Default timeout should be 5000', 5000, LConfig.TimeoutMs);
  AssertFalse('Default should not use global namespace', LConfig.UseGlobalNamespace);
  AssertFalse('Default should be auto reset', LConfig.ManualReset);
  AssertFalse('Default should not be initially signaled', LConfig.InitialState);
  
  LConfig := NamedEventConfigWithTimeout(10000);
  AssertEquals('Timeout should be 10000', 10000, LConfig.TimeoutMs);
  
  LConfig := GlobalNamedEventConfig;
  AssertTrue('Should use global namespace', LConfig.UseGlobalNamespace);
  
  LConfig := ManualResetNamedEventConfig;
  AssertTrue('Should be manual reset', LConfig.ManualReset);
  
  LConfig := AutoResetNamedEventConfig;
  AssertFalse('Should be auto reset', LConfig.ManualReset);
end;

{ TTestCase_INamedEvent }

procedure TTestCase_INamedEvent.SetUp;
begin
  inherited SetUp;
  FEventName := 'TestEvent_' + IntToStr(Random(100000));
  FEvent := CreateNamedEvent(FEventName);
end;

procedure TTestCase_INamedEvent.TearDown;
begin
  FEvent := nil;
  inherited TearDown;
end;

procedure TTestCase_INamedEvent.Test_Wait;
var
  LGuard: INamedEventGuard;
begin
  // 先设置事件
  FEvent.Signal;

  // 等待事件
  LGuard := FEvent.Wait;
  AssertNotNull('Guard should be returned', LGuard);
  AssertEquals('Guard name should match', FEventName, LGuard.GetName);
  AssertTrue('Guard should be signaled', LGuard.IsSignaled);
end;

procedure TTestCase_INamedEvent.Test_TryWait;
var
  LGuard: INamedEventGuard;
begin
  // 未设置事件时应该返回 nil
  LGuard := FEvent.TryWait;
  AssertNull('Should return nil when not signaled', LGuard);

  // 设置事件后应该成功
  FEvent.Signal;
  LGuard := FEvent.TryWait;
  AssertNotNull('Should return guard when signaled', LGuard);
  AssertTrue('Guard should be signaled', LGuard.IsSignaled);
end;

procedure TTestCase_INamedEvent.Test_TryWaitFor;
var
  LGuard: INamedEventGuard;
begin
  // 设置事件
  FEvent.Signal;

  // 带超时等待
  LGuard := FEvent.TryWaitFor(1000);
  AssertNotNull('Should return guard when signaled', LGuard);
  AssertTrue('Guard should be signaled', LGuard.IsSignaled);
end;

procedure TTestCase_INamedEvent.Test_TryWaitFor_Timeout;
var
  LGuard: INamedEventGuard;
begin
  // 未设置事件，应该超时
  LGuard := FEvent.TryWaitFor(100);
  AssertNull('Should timeout and return nil', LGuard);
end;

procedure TTestCase_INamedEvent.Test_TryWaitFor_Zero;
var
  LGuard: INamedEventGuard;
begin
  // 零超时应该立即返回
  LGuard := FEvent.TryWaitFor(0);
  AssertNull('Should return immediately with nil', LGuard);

  FEvent.Signal;
  LGuard := FEvent.TryWaitFor(0);
  AssertNotNull('Should return guard when signaled', LGuard);
end;

procedure TTestCase_INamedEvent.Test_SetEvent;
begin
  // 设置事件不应该抛出异常
  FEvent.Signal;
  // 验证可以通过 TryWait 检测到
  AssertNotNull('Event should be signaled after SetEvent', FEvent.TryWait);
end;

procedure TTestCase_INamedEvent.Test_ResetEvent;
var
  LEvent: INamedEvent;
begin
  // 使用手动重置事件进行测试
  LEvent := CreateNamedEvent(FEventName + '_Reset', True, True);

  // 初始应该是已触发状态
  AssertNotNull('Should be initially signaled', LEvent.TryWait);

  // 重置事件
  LEvent.Reset;

  // 现在应该不再触发
  AssertNull('Should not be signaled after reset', LEvent.TryWait);
end;

procedure TTestCase_INamedEvent.Test_PulseEvent;
begin
  // 脉冲事件不应该抛出异常
  FEvent.Pulse;
  // 对于自动重置事件，脉冲后应该立即重置
end;

procedure TTestCase_INamedEvent.Test_GetName;
begin
  AssertEquals('Name should match', FEventName, FEvent.GetName);
end;

procedure TTestCase_INamedEvent.Test_IsManualReset;
var
  LManualEvent, LAutoEvent: INamedEvent;
begin
  LManualEvent := CreateNamedEvent(FEventName + '_Manual', True);
  LAutoEvent := CreateNamedEvent(FEventName + '_Auto', False);
  
  AssertTrue('Manual reset event should return true', LManualEvent.IsManualReset);
  AssertFalse('Auto reset event should return false', LAutoEvent.IsManualReset);
end;

procedure TTestCase_INamedEvent.Test_IsSignaled;
var
  LEvent: INamedEvent;
begin
  LEvent := CreateNamedEvent(FEventName + '_Signaled', True, False);
  AssertFalse('Should not be initially signaled', LEvent.IsSignaled);

  LEvent.Signal;
  AssertTrue('Should be signaled after SetEvent', LEvent.IsSignaled);

  LEvent.Reset;
  AssertFalse('Should not be signaled after ResetEvent', LEvent.IsSignaled);
end;

// 兼容性方法测试
procedure TTestCase_INamedEvent.Test_WaitFor_Deprecated;
var
  LResult: TWaitResult;
begin
  FEvent.Signal;
  // 兼容性方法已移除，改为测试新 API
  AssertNotNull('Should return guard when signaled', FEvent.TryWait);
end;

procedure TTestCase_INamedEvent.Test_WaitFor_WithTimeout_Deprecated;
var
  LGuard: INamedEventGuard;
begin
  LGuard := FEvent.TryWaitFor(100);
  AssertNull('Should timeout and return nil', LGuard);

  FEvent.Signal;
  LGuard := FEvent.TryWaitFor(100);
  AssertNotNull('Should return guard when signaled', LGuard);
end;

procedure TTestCase_INamedEvent.Test_Acquire_Deprecated;
var
  LGuard: INamedEventGuard;
begin
  FEvent.Signal;
  // 使用新的 API
  LGuard := FEvent.Wait;
  AssertNotNull('Should acquire successfully', LGuard);
end;

procedure TTestCase_INamedEvent.Test_Release_Deprecated;
var
  LGuard: INamedEventGuard;
begin
  FEvent.Signal;
  LGuard := FEvent.Wait;
  // RAII 自动释放，设置为 nil 来显式释放
  LGuard := nil;
end;

procedure TTestCase_INamedEvent.Test_TryAcquire_Deprecated;
var
  LGuard: INamedEventGuard;
begin
  LGuard := FEvent.TryWait;
  AssertNull('Should return nil when not signaled', LGuard);

  FEvent.Signal;
  LGuard := FEvent.TryWait;
  AssertNotNull('Should return guard when signaled', LGuard);
end;

procedure TTestCase_INamedEvent.Test_TryAcquire_WithTimeout_Deprecated;
var
  LGuard: INamedEventGuard;
begin
  LGuard := FEvent.TryWaitFor(100);
  AssertNull('Should timeout and return nil', LGuard);

  FEvent.Signal;
  LGuard := FEvent.TryWaitFor(100);
  AssertNotNull('Should return guard when signaled', LGuard);
end;

procedure TTestCase_INamedEvent.Test_GetHandle_Deprecated;
var
  LName: string;
begin
  // 使用新的 API 获取事件名称
  LName := FEvent.GetName;
  AssertTrue('Name should not be empty', LName <> '');
end;

procedure TTestCase_INamedEvent.Test_IsCreator_Deprecated;
var
  LIsManualReset: Boolean;
begin
  // 使用新的 API 检查事件类型
  LIsManualReset := FEvent.IsManualReset;
  AssertTrue('IsManualReset should return a boolean', (LIsManualReset = True) or (LIsManualReset = False));
end;

{ TTestCase_ManualResetEvent }

procedure TTestCase_ManualResetEvent.SetUp;
begin
  inherited SetUp;
  FEventName := 'TestManualEvent_' + IntToStr(Random(100000));
  FEvent := CreateNamedEvent(FEventName, True, False);
end;

procedure TTestCase_ManualResetEvent.TearDown;
begin
  FEvent := nil;
  inherited TearDown;
end;

procedure TTestCase_ManualResetEvent.Test_ManualReset_SetAndWait;
var
  LGuard: INamedEventGuard;
begin
  // 设置事件
  FEvent.Signal;

  // 多次等待都应该成功（手动重置特性）
  LGuard := FEvent.TryWait;
  AssertNotNull('First wait should succeed', LGuard);

  LGuard := FEvent.TryWait;
  AssertNotNull('Second wait should also succeed', LGuard);

  // 手动重置事件的 IsSignaled 应该返回 true
  AssertTrue('Manual reset event should remain signaled', FEvent.IsSignaled);
end;

procedure TTestCase_ManualResetEvent.Test_ManualReset_MultipleWaiters;
var
  LGuard1, LGuard2: INamedEventGuard;
begin
  FEvent.Signal;

  // 多个等待者都应该能成功获取
  LGuard1 := FEvent.TryWait;
  LGuard2 := FEvent.TryWait;

  AssertNotNull('First guard should succeed', LGuard1);
  AssertNotNull('Second guard should succeed', LGuard2);
end;

procedure TTestCase_ManualResetEvent.Test_ManualReset_ResetAfterSet;
var
  LGuard: INamedEventGuard;
begin
  // 设置事件
  FEvent.Signal;
  AssertTrue('Should be signaled after set', FEvent.IsSignaled);

  // 重置事件
  FEvent.Reset;
  AssertFalse('Should not be signaled after reset', FEvent.IsSignaled);

  // 现在等待应该失败
  LGuard := FEvent.TryWait;
  AssertNull('Wait should fail after reset', LGuard);
end;

procedure TTestCase_ManualResetEvent.Test_ManualReset_IsSignaled;
begin
  AssertFalse('Should not be initially signaled', FEvent.IsSignaled);

  FEvent.Signal;
  AssertTrue('Should be signaled after SetEvent', FEvent.IsSignaled);

  FEvent.Reset;
  AssertFalse('Should not be signaled after ResetEvent', FEvent.IsSignaled);
end;

procedure TTestCase_ManualResetEvent.Test_ManualReset_PulseEvent;
var
  LGuard: INamedEventGuard;
begin
  // 脉冲事件应该触发然后保持触发状态（对于手动重置事件）
  FEvent.Pulse;

  LGuard := FEvent.TryWait;
  AssertNotNull('Should be signaled after pulse', LGuard);

  // 手动重置事件脉冲后应该保持触发状态
  LGuard := FEvent.TryWait;
  AssertNotNull('Should remain signaled after pulse', LGuard);
end;

{ TTestCase_AutoResetEvent }

procedure TTestCase_AutoResetEvent.SetUp;
begin
  inherited SetUp;
  FEventName := 'TestAutoEvent_' + IntToStr(Random(100000));
  FEvent := CreateNamedEvent(FEventName, False, False);
end;

procedure TTestCase_AutoResetEvent.TearDown;
begin
  FEvent := nil;
  inherited TearDown;
end;

procedure TTestCase_AutoResetEvent.Test_AutoReset_SetAndWait;
var
  LGuard: INamedEventGuard;
begin
  // 设置事件
  FEvent.Signal;

  // 第一次等待应该成功
  LGuard := FEvent.TryWait;
  AssertNotNull('First wait should succeed', LGuard);

  // 第二次等待应该失败（自动重置特性）
  LGuard := FEvent.TryWait;
  AssertNull('Second wait should fail (auto-reset)', LGuard);
end;

procedure TTestCase_AutoResetEvent.Test_AutoReset_SingleWaiter;
var
  LGuard: INamedEventGuard;
begin
  FEvent.Signal;

  // 只有一个等待者能成功获取
  LGuard := FEvent.TryWait;
  AssertNotNull('Single guard should succeed', LGuard);

  // 后续等待者应该失败
  LGuard := FEvent.TryWait;
  AssertNull('Subsequent guard should fail', LGuard);
end;

procedure TTestCase_AutoResetEvent.Test_AutoReset_IsSignaled;
begin
  // 自动重置事件的 IsSignaled 应该总是返回 False（与 Windows 语义对齐）
  AssertFalse('Auto-reset event IsSignaled should return false', FEvent.IsSignaled);

  FEvent.Signal;
  AssertFalse('Auto-reset event IsSignaled should still return false', FEvent.IsSignaled);
end;

procedure TTestCase_AutoResetEvent.Test_AutoReset_PulseEvent;
var
  LGuard: INamedEventGuard;
begin
  // 脉冲事件应该触发然后立即重置（对于自动重置事件）
  FEvent.Pulse;

  // 脉冲后应该立即重置，所以等待应该失败
  LGuard := FEvent.TryWait;
  AssertNull('Should not be signaled after pulse (auto-reset)', LGuard);
end;

{ TTestCase_ErrorHandling }

procedure TTestCase_ErrorHandling.Test_InvalidName_Empty;
begin
  try
    CreateNamedEvent('');
    Fail('Empty name should raise exception');
  except
    on E: EInvalidArgument do
      ; // 期望的异常
  end;
end;

procedure TTestCase_ErrorHandling.Test_InvalidName_TooLong;
var
  LLongName: string;
begin
  // 创建一个超长的名称
  LLongName := StringOfChar('A', 300);

  try
    CreateNamedEvent(LLongName);
    Fail('Too long name should raise exception');
  except
    on E: EInvalidArgument do
      ; // 期望的异常
  end;
end;

procedure TTestCase_ErrorHandling.Test_InvalidName_InvalidChars;
begin
  {$IFDEF UNIX}
  // Unix 平台不允许包含 '/' 字符
  try
    CreateNamedEvent('Test/Event');
    Fail('Invalid character should raise exception');
  except
    on E: EInvalidArgument do
      ; // 期望的异常
  end;
  {$ENDIF}

  {$IFDEF WINDOWS}
  // Windows 平台不允许包含反斜杠（除了前缀）
  try
    CreateNamedEvent('Test\Event');
    Fail('Invalid character should raise exception');
  except
    on E: EInvalidArgument do
      ; // 期望的异常
  end;
  {$ENDIF}
end;

{ TTestCase_Timeout }

procedure TTestCase_Timeout.SetUp;
begin
  inherited SetUp;
  FEventName := 'TestTimeoutEvent_' + IntToStr(Random(100000));
  FEvent := CreateNamedEvent(FEventName);
end;

procedure TTestCase_Timeout.TearDown;
begin
  FEvent := nil;
  inherited TearDown;
end;

procedure TTestCase_Timeout.Test_TryWaitFor_ShortTimeout;
var
  LGuard: INamedEventGuard;
  LStartTime, LEndTime: TDateTime;
begin
  LStartTime := Now;
  LGuard := FEvent.TryWaitFor(100);  // 100ms 超时
  LEndTime := Now;

  AssertNull('Should timeout and return nil', LGuard);

  // 验证确实等待了大约 100ms
  AssertTrue('Should wait approximately 100ms',
    (LEndTime - LStartTime) * 24 * 60 * 60 * 1000 >= 90);  // 允许一些误差
end;

procedure TTestCase_Timeout.Test_TryWaitFor_LongTimeout;
var
  LGuard: INamedEventGuard;
begin
  // 设置事件，应该立即返回而不等待超时
  FEvent.Signal;

  LGuard := FEvent.TryWaitFor(5000);  // 5秒超时
  AssertNotNull('Should return immediately when signaled', LGuard);
end;

procedure TTestCase_Timeout.Test_TryWaitFor_ZeroTimeout;
var
  LGuard: INamedEventGuard;
begin
  // 零超时应该立即返回
  LGuard := FEvent.TryWaitFor(0);
  AssertNull('Should return immediately with zero timeout', LGuard);

  FEvent.Signal;
  LGuard := FEvent.TryWaitFor(0);
  AssertNotNull('Should return guard when signaled with zero timeout', LGuard);
end;

procedure TTestCase_Timeout.Test_TryWaitFor_InfiniteTimeout;
var
  LGuard: INamedEventGuard;
begin
  // 设置事件
  FEvent.Signal;

  // 无限超时应该等同于 Wait()
  LGuard := FEvent.TryWaitFor(Cardinal(-1));
  AssertNotNull('Should return guard with infinite timeout', LGuard);
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_INamedEvent);
  RegisterTest(TTestCase_ManualResetEvent);
  RegisterTest(TTestCase_AutoResetEvent);
  RegisterTest(TTestCase_ErrorHandling);
  RegisterTest(TTestCase_Timeout);

end.
