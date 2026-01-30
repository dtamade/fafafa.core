unit Test_scheduler_basic;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

type
  { TTestCase_TTaskScheduler_Basic }
  TTestCase_TTaskScheduler_Basic = class(TTestCase)
  published
    procedure Test_Schedule_Func_Delayed_Exec;
    procedure Test_Schedule_Shutdown_Behavior;
    procedure Test_Schedule_Cancel_Before_Due;
  end;

  TRunHelper = class
  public
    function RunSetTrue(Data: Pointer): Boolean;
  end;

implementation

function TRunHelper.RunSetTrue(Data: Pointer): Boolean;
begin
  if Data <> nil then
    PBoolean(Data)^ := True;
  Result := True;
end;

procedure TTestCase_TTaskScheduler_Basic.Test_Schedule_Func_Delayed_Exec;
var
  LScheduler: ITaskScheduler;
  LFuture: IFuture;
  LStart, LEnd: QWord;
  LExecuted: Boolean;
  LHelper: TRunHelper;
begin
  LScheduler := CreateTaskScheduler;
  LExecuted := False;
  LHelper := TRunHelper.Create;
  try
    LStart := GetTickCount64;
    // 使用对象方法以满足 TTaskMethod 类型
    LFuture := LScheduler.Schedule(@LHelper.RunSetTrue, 150, @LExecuted);
    AssertNotNull('Future should be created', LFuture);
    AssertTrue('Future should complete within 1s', LFuture.WaitFor(1000));
    LEnd := GetTickCount64;
    AssertTrue('Task should be delayed (~>=120ms)', (LEnd - LStart) >= 120);
    AssertTrue('Task flag should be set', LExecuted);
  finally
    LHelper.Free;
  end;
  LScheduler.Shutdown;
end;

procedure TTestCase_TTaskScheduler_Basic.Test_Schedule_Shutdown_Behavior;
var
  LScheduler: ITaskScheduler;
begin
  LScheduler := CreateTaskScheduler;
  LScheduler.Shutdown;
  AssertTrue('Scheduler should be shutdown', LScheduler.IsShutdown);
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('Scheduling after shutdown should fail', ETaskSchedulerError,
    procedure
    begin
      LScheduler.Schedule(function: Boolean begin Result := True; end, 10);
    end);
  {$ELSE}
  AssertException('Scheduling after shutdown should fail', ETaskSchedulerError,
    procedure
    var F: IFuture;
    begin
      F := LScheduler.Schedule(
        function (Data: Pointer): Boolean
        begin
          Result := True;
        end,
        10, nil
      );
    end);
  {$ENDIF}
end;

procedure TTestCase_TTaskScheduler_Basic.Test_Schedule_Cancel_Before_Due;
var
  LScheduler: ITaskScheduler;
  LFuture: IFuture;
  LExecuted: Boolean;
  LHelper: TRunHelper;
begin
  LScheduler := CreateTaskScheduler;
  LExecuted := False;
  LHelper := TRunHelper.Create;
  try
    // 使用对象方法以满足 TTaskMethod 类型
    LFuture := LScheduler.Schedule(@LHelper.RunSetTrue, 500, @LExecuted);
    AssertNotNull('Future should be created', LFuture);
    // 立即取消
    AssertTrue('Cancel should return true (pending)', LFuture.Cancel);
    // 等待一段时间确保不会执行
    Sleep(200);
    AssertTrue('Future should report done after cancel', LFuture.IsDone);
    AssertTrue('Future should report cancelled', LFuture.IsCancelled);
    AssertFalse('Cancelled task should not run', LExecuted);
  finally
    LHelper.Free;
  end;
  LScheduler.Shutdown;
end;

initialization
  RegisterTest(TTestCase_TTaskScheduler_Basic);

end.

