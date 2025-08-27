unit fafafa.core.signal.owner.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  fpcunit, testregistry, sysutils,
  fafafa.core.signal;

type
  TTestCase_Owner = class(TTestCase)
  private
    FCount: Integer;
    procedure OnSig(const S: TSignal);
  published
    procedure Test_SubscribeOwned_UnsubscribeAll;
  end;

implementation

procedure TTestCase_Owner.OnSig(const S: TSignal);
begin
  Inc(FCount);
end;

procedure TTestCase_Owner.Test_SubscribeOwned_UnsubscribeAll;
var C: ISignalCenter; OwnerObj: TObject; tok: Int64;
begin
  C := SignalCenter; C.Start;
  try
    FCount := 0;
    OwnerObj := TObject.Create;
    try
      tok := C.SubscribeOwned(OwnerObj, [sgInt, sgTerm], @OnSig);
      CheckTrue(tok > 0);
      C.InjectForTest(sgInt);
      Sleep(20);
      CheckTrue(FCount >= 1, 'should receive before UnsubscribeAll');

      C.UnsubscribeAll(OwnerObj);
      C.InjectForTest(sgTerm);
      Sleep(20);
      CheckTrue(FCount = 1, 'should not receive after UnsubscribeAll');
    finally
      OwnerObj.Free;
    end;
  finally
    C.Stop;
  end;
end;

initialization
  RegisterTest(TTestCase_Owner);

end.

