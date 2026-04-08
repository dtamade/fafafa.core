program example_basic_usage;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}
{$I ..\..\src\fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.sync.namedEvent;

procedure DemoBasicUsage;
var
  LEvent: INamedEvent;
  LGuard: INamedEventGuard;
begin
  WriteLn('=== Basic Usage ===');

  LEvent := CreateNamedEvent('BasicExample', False, False);
  WriteLn('[OK] Created event: ', LEvent.GetName);
  WriteLn('  Manual reset: ', BoolToStr(LEvent.IsManualReset, True));

  LGuard := LEvent.TryWait;
  if Assigned(LGuard) then
    WriteLn('[FAIL] Event should not be signaled yet')
  else
    WriteLn('[OK] Event is not signaled yet');

  LEvent.Signal;
  WriteLn('[OK] Event signaled');

  LGuard := LEvent.TryWait;
  if Assigned(LGuard) then
  begin
    WriteLn('[OK] Guard acquired: ', LGuard.GetName);
    WriteLn('  Guard signaled: ', BoolToStr(LGuard.IsSignaled, True));
  end
  else
    WriteLn('[FAIL] Expected guard after signal');

  WriteLn;
end;

procedure DemoManualResetEvent;
var
  LEvent: INamedEvent;
  LGuard1: INamedEventGuard;
  LGuard2: INamedEventGuard;
begin
  WriteLn('=== Manual Reset Event ===');

  LEvent := CreateNamedEvent('ManualExample', True, False);
  LEvent.Signal;

  LGuard1 := LEvent.TryWait;
  LGuard2 := LEvent.TryWait;

  if Assigned(LGuard1) and Assigned(LGuard2) then
    WriteLn('[OK] Manual reset event stays signaled for multiple waiters')
  else
    WriteLn('[FAIL] Manual reset event did not stay signaled');

  LEvent.Reset;
  if not Assigned(LEvent.TryWait) then
    WriteLn('[OK] Reset cleared the event')
  else
    WriteLn('[FAIL] Reset should clear the event');

  WriteLn;
end;

procedure DemoAutoResetEvent;
var
  LEvent: INamedEvent;
  LGuard1: INamedEventGuard;
  LGuard2: INamedEventGuard;
begin
  WriteLn('=== Auto Reset Event ===');

  LEvent := CreateNamedEvent('AutoExample', False, False);
  LEvent.Signal;

  LGuard1 := LEvent.TryWait;
  LGuard2 := LEvent.TryWait;

  if Assigned(LGuard1) then
    WriteLn('[OK] First waiter acquired auto-reset event')
  else
    WriteLn('[FAIL] First waiter should acquire auto-reset event');

  if not Assigned(LGuard2) then
    WriteLn('[OK] Second waiter sees auto-reset event already consumed')
  else
    WriteLn('[FAIL] Auto-reset event should only release one waiter');

  WriteLn;
end;

procedure DemoTimeoutUsage;
var
  LEvent: INamedEvent;
  LGuard: INamedEventGuard;
  LStartTime: TDateTime;
  LElapsed: Double;
begin
  WriteLn('=== Timeout Usage ===');

  LEvent := CreateNamedEvent('TimeoutExample', False, False);

  LStartTime := Now;
  LGuard := LEvent.TryWaitFor(100);
  LElapsed := (Now - LStartTime) * 24 * 60 * 60 * 1000;

  if not Assigned(LGuard) then
    WriteLn('[OK] 100ms timeout returned nil after ', FormatFloat('0.0', LElapsed), ' ms')
  else
    WriteLn('[FAIL] 100ms timeout should not succeed');

  LStartTime := Now;
  LGuard := LEvent.TryWaitFor(0);
  LElapsed := (Now - LStartTime) * 24 * 60 * 60 * 1000;

  if not Assigned(LGuard) then
    WriteLn('[OK] 0ms timeout returned nil after ', FormatFloat('0.0', LElapsed), ' ms')
  else
    WriteLn('[FAIL] 0ms timeout should return nil immediately');

  WriteLn;
end;

procedure DemoErrorHandling;
begin
  WriteLn('=== Error Handling ===');

  try
    CreateNamedEvent('');
    WriteLn('[FAIL] Empty name should raise');
  except
    on LError: Exception do
      WriteLn('[OK] Empty name raised: ', LError.Message);
  end;

  try
    CreateNamedEvent('Test/Invalid');
    WriteLn('[FAIL] Invalid name should raise');
  except
    on LError: Exception do
      WriteLn('[OK] Invalid name raised: ', LError.Message);
  end;

  WriteLn;
end;

begin
  WriteLn('fafafa.core.sync.namedEvent basic usage');
  WriteLn('=======================================');
  WriteLn;

  try
    DemoBasicUsage;
    DemoManualResetEvent;
    DemoAutoResetEvent;
    DemoTimeoutUsage;
    DemoErrorHandling;
    WriteLn('[OK] All named event demos completed');
  except
    on LError: Exception do
    begin
      WriteLn('[FAIL] Demo error: ', LError.ClassName, ': ', LError.Message);
      Halt(1);
    end;
  end;
end.
