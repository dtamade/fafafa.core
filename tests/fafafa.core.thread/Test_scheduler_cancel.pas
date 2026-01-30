unit Test_scheduler_cancel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.thread;

type
  TTestCase_Scheduler_Cancel = class(TTestCase)
  published
    procedure Test_Schedule_WithToken_CancelBefore;
  end;

implementation

function Nop(Data: Pointer): Boolean; begin Result := True; end;

procedure TTestCase_Scheduler_Cancel.Test_Schedule_WithToken_CancelBefore;
var S: ITaskScheduler; Cts: ICancellationTokenSource; F: IFuture;
begin
  S := CreateTaskScheduler;
  Cts := CreateCancellationTokenSource;
  Cts.Cancel;
  F := S.Schedule(@Nop, 10, Cts.Token, nil);
  AssertTrue(F = nil);
  S.Shutdown;
end;

initialization
  RegisterTest(TTestCase_Scheduler_Cancel);

end.

