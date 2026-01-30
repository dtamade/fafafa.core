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
  end;

  // INamedEvent 接口测试（基础）
  TTestCase_INamedEvent = class(TTestCase)
  private
    FEvent: INamedEvent;
    FEventName: string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Wait;
    procedure Test_TryWait;
    procedure Test_TryWaitFor;
    procedure Test_TryWaitFor_Timeout;
    procedure Test_Set_Reset;
    procedure Test_Getters;
  end;

  // 手动重置事件测试
  TTestCase_ManualResetEvent = class(TTestCase)
  private
    FEvent: INamedEvent;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_PulseEvent;
  end;

  // 自动重置事件测试
  TTestCase_AutoResetEvent = class(TTestCase)
  private
    FEvent: INamedEvent;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_PulseEvent;
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
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_TryWaitFor_ShortTimeout;
    procedure Test_TryWaitFor_InfiniteTimeout;
  end;

implementation

{ TTestCase_Global }

procedure TTestCase_Global.Test_CreateNamedEvent;
var
  LEvent: INamedEvent;
begin
  LEvent := CreateNamedEvent('TestEvent');
  CheckNotNull(LEvent, 'CreateNamedEvent should return event');
  CheckEquals('TestEvent', LEvent.GetName, 'Name should match');
end;

procedure TTestCase_Global.Test_CreateNamedEvent_WithConfig;
var
  LEvent: INamedEvent;
begin
  // 手动重置，初始未触发
  LEvent := CreateNamedEvent('ConfigEvent', True, False);
  CheckNotNull(LEvent);
  CheckTrue(LEvent.IsManualReset, 'ManualReset should be true');
end;

procedure TTestCase_Global.Test_CreateManualResetNamedEvent;
var
  LEvent: INamedEvent;
begin
  LEvent := CreateNamedEvent('ManualResetEvent', True, False);
  CheckNotNull(LEvent);
  CheckTrue(LEvent.IsManualReset);
end;

procedure TTestCase_Global.Test_CreateAutoResetNamedEvent;
var
  LEvent: INamedEvent;
begin
  LEvent := CreateNamedEvent('AutoResetEvent', False, False);
  CheckNotNull(LEvent);
  CheckFalse(LEvent.IsManualReset);
end;

procedure TTestCase_Global.Test_CreateGlobalNamedEvent;
var
  LEvent: INamedEvent;
begin
  LEvent := CreateGlobalNamedEvent('test_global_event');
  CheckNotNull(LEvent);
  {$IFDEF WINDOWS}
  CheckTrue(Pos('Global\', LEvent.GetName) = 1, 'On Windows name should contain Global\ prefix');
  {$ELSE}
  CheckEquals('test_global_event', LEvent.GetName, 'On Unix, original name expected');
  {$ENDIF}
end;

{ TTestCase_INamedEvent }

procedure TTestCase_INamedEvent.SetUp;
begin
  inherited SetUp;
  FEventName := 'IE_' + IntToStr(Random(100000));
  FEvent := CreateNamedEvent(FEventName);
end;

procedure TTestCase_INamedEvent.TearDown;
begin
  FEvent := nil;
  inherited TearDown;
end;

procedure TTestCase_INamedEvent.Test_Wait;
var
  G: INamedEventGuard;
begin
  FEvent.Signal;
  G := FEvent.Wait;
  CheckNotNull(G, 'Wait should return guard when signaled');
end;

procedure TTestCase_INamedEvent.Test_TryWait;
var
  G: INamedEventGuard;
begin
  G := FEvent.TryWait;
  CheckNull(G, 'TryWait should return nil initially');
  FEvent.Signal;
  G := FEvent.TryWait;
  CheckNotNull(G, 'TryWait should return guard when signaled');
end;

procedure TTestCase_INamedEvent.Test_TryWaitFor;
var
  G: INamedEventGuard;
begin
  FEvent.Signal;
  G := FEvent.TryWaitFor(1000);
  CheckNotNull(G, 'TryWaitFor should return guard when signaled');
end;

procedure TTestCase_INamedEvent.Test_TryWaitFor_Timeout;
var
  G: INamedEventGuard;
begin
  G := FEvent.TryWaitFor(50);
  CheckNull(G, 'TryWaitFor should timeout and return nil');
end;

procedure TTestCase_INamedEvent.Test_Set_Reset;
var
  G: INamedEventGuard;
begin
  FEvent.Signal;
  G := FEvent.TryWait;
  CheckNotNull(G, 'Signal should allow one waiter');
  FEvent.Reset;
  G := FEvent.TryWait;
  CheckNull(G, 'After Reset, TryWait should fail');
end;

procedure TTestCase_INamedEvent.Test_Getters;
begin
  CheckEquals(FEventName, FEvent.GetName, 'GetName should match');
  // 默认配置为自动重置
  CheckFalse(FEvent.IsManualReset, 'Default should be auto-reset');
end;

{ TTestCase_ManualResetEvent }

procedure TTestCase_ManualResetEvent.SetUp;
begin
  inherited SetUp;
  FEvent := CreateNamedEvent('ManualPulse', True, False);
end;

procedure TTestCase_ManualResetEvent.TearDown;
begin
  FEvent := nil;
  inherited TearDown;
end;

procedure TTestCase_ManualResetEvent.Test_PulseEvent;
var
  G: INamedEventGuard;
begin
  FEvent.Pulse;
  G := FEvent.TryWait;
  CheckNotNull(G, 'ManualReset: Pulse should set signaled');
  // 手动重置下应保持触发
  G := FEvent.TryWait;
  CheckNotNull(G, 'ManualReset: Pulse should remain signaled');
end;

{ TTestCase_AutoResetEvent }

procedure TTestCase_AutoResetEvent.SetUp;
begin
  inherited SetUp;
  FEvent := CreateNamedEvent('AutoPulse', False, False);
end;

procedure TTestCase_AutoResetEvent.TearDown;
begin
  FEvent := nil;
  inherited TearDown;
end;

procedure TTestCase_AutoResetEvent.Test_PulseEvent;
var
  G: INamedEventGuard;
begin
  FEvent.Pulse;
  // 自动重置：Pulse 后应处于未触发（若无等待者）
  G := FEvent.TryWait;
  CheckNull(G, 'AutoReset: Pulse should not remain signaled');
end;

{ TTestCase_ErrorHandling }

procedure TTestCase_ErrorHandling.Test_InvalidName_Empty;
  procedure DoCall; begin CreateNamedEvent(''); end;
begin
  AssertException(EInvalidArgument, @DoCall);
end;

procedure TTestCase_ErrorHandling.Test_InvalidName_TooLong;
  procedure DoCall;
  var
    S: string;
  begin
    S := StringOfChar('A', 300);
    CreateNamedEvent(S);
  end;
begin
  AssertException(EInvalidArgument, @DoCall);
end;

procedure TTestCase_ErrorHandling.Test_InvalidName_InvalidChars;
{$IFDEF WINDOWS}
  procedure DoCall; begin CreateNamedEvent('Test\Event'); end;
{$ENDIF}
{$IFDEF UNIX}
  procedure DoCall; begin CreateNamedEvent('Test/Event'); end;
{$ENDIF}
begin
  AssertException(EInvalidArgument, @DoCall);
end;

{ TTestCase_Timeout }

procedure TTestCase_Timeout.SetUp;
begin
  inherited SetUp;
  FEvent := CreateNamedEvent('TimeoutEvent');
end;

procedure TTestCase_Timeout.TearDown;
begin
  FEvent := nil;
  inherited TearDown;
end;

procedure TTestCase_Timeout.Test_TryWaitFor_ShortTimeout;
var
  G: INamedEventGuard;
  T0, T1: TDateTime;
begin
  T0 := Now;
  G := FEvent.TryWaitFor(100);
  T1 := Now;
  CheckNull(G, 'Short timeout should return nil');
  CheckTrue(((T1 - T0) * 24 * 60 * 60 * 1000) >= 80, 'Elapsed should be ~100ms');
end;

procedure TTestCase_Timeout.Test_TryWaitFor_InfiniteTimeout;
var
  G: INamedEventGuard;
begin
  FEvent.Signal;
  G := FEvent.TryWaitFor(Cardinal(-1));
  CheckNotNull(G, 'Infinite timeout should behave like Wait');
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_INamedEvent);
  RegisterTest(TTestCase_ManualResetEvent);
  RegisterTest(TTestCase_AutoResetEvent);
  RegisterTest(TTestCase_ErrorHandling);
  RegisterTest(TTestCase_Timeout);

end.

