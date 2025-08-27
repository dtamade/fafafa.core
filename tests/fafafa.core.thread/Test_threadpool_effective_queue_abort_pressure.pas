unit Test_threadpool_effective_queue_abort_pressure;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

type
  TTestCase_TThreadPool_EffectiveQueue_Abort_Pressure = class(TTestCase)
  published
    procedure Test_Submit_Abort_NoOverflow_UnderPressure;
  end;

implementation

function __BusyWait50ms(Data: Pointer): Boolean;
var T0: QWord;
begin
  T0 := GetTickCount64;
  while (GetTickCount64 - T0) < 50 do ;
  Result := True;
end;

function __ReturnTrue(Data: Pointer): Boolean;
begin
  Result := True;
end;

procedure TTestCase_TThreadPool_EffectiveQueue_Abort_Pressure.Test_Submit_Abort_NoOverflow_UnderPressure;
var
  Pool: IThreadPool;
  I: Integer;
begin
  Pool := CreateThreadPool(1, 1, 60000, 0, TRejectPolicy.rpAbort);
  try
    // 先占用唯一工作线程
    Pool.Submit(@__BusyWait50ms);

    // 快速连续提交 64 次，期望全部被拒绝（不出现整数溢出或其他异常类型）
    for I := 1 to 64 do
    begin
      try
        Pool.Submit(@__ReturnTrue);
        Fail('Expected EThreadPoolError not raised at iteration ' + IntToStr(I));
      except
        on E: EThreadPoolError do ; // OK: 被拒绝
        on E: Exception do Fail('Unexpected exception at iteration ' + IntToStr(I) + ': ' + E.ClassName + ' - ' + E.Message);
      end;
    end;
  finally
    if Assigned(Pool) then begin Pool.Shutdown; Pool.AwaitTermination(2000); end;
  end;
end;

initialization
  RegisterTest(TTestCase_TThreadPool_EffectiveQueue_Abort_Pressure);

end.

