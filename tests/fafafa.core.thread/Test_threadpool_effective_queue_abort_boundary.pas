unit Test_threadpool_effective_queue_abort_boundary;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

type
  TTestCase_TThreadPool_EffectiveQueue_Abort = class(TTestCase)
  published
    // 验证 rpAbort 策略下，有效队列=0 场景不会产生整数溢出，但会被正确拒绝
    procedure Test_Submit_Abort_NoOverflow_WithIdleWorkers;
  end;

implementation

function __BusyWait100ms(Data: Pointer): Boolean;
var T0: QWord;
begin
  T0 := GetTickCount64;
  while (GetTickCount64 - T0) < 100 do ;
  Result := True;
end;

function __ReturnTrue(Data: Pointer): Boolean;
begin
  Result := True;
end;

procedure TTestCase_TThreadPool_EffectiveQueue_Abort.Test_Submit_Abort_NoOverflow_WithIdleWorkers;
var
  Pool: IThreadPool;
begin
  Pool := CreateThreadPool(1, 1, 60000, 0, TRejectPolicy.rpAbort);
  try
    // 首先占用唯一工作线程，制造队列容量=0 的即时拒绝窗口
    Pool.Submit(@__BusyWait100ms);

    // 紧接着再次提交，应触发 EThreadPoolError（拒绝），但不应发生整数溢出异常
    try
      Pool.Submit(@__ReturnTrue);
      Fail('Expected EThreadPoolError not raised');
    except
      on E: EThreadPoolError do ; // OK
      on E: Exception do Fail('Unexpected exception: ' + E.ClassName + ' - ' + E.Message);
    end;
  finally
    if Assigned(Pool) then begin Pool.Shutdown; Pool.AwaitTermination(2000); end;
  end;
end;

initialization
  RegisterTest(TTestCase_TThreadPool_EffectiveQueue_Abort);

end.

