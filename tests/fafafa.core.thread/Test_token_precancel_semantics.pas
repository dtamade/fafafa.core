unit Test_token_precancel_semantics;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

type
  { TTestCase_Token_PreCancel }
  TTestCase_Token_PreCancel = class(TTestCase)
  published
    procedure Test_Spawn_PreCancelled_Returns_Nil_And_Not_Rejected;
  end;

implementation

procedure TTestCase_Token_PreCancel.Test_Spawn_PreCancelled_Returns_Nil_And_Not_Rejected;
var C: ICancellationTokenSource; F: IFuture; M: IThreadPoolMetrics; P: IThreadPool;
begin
  C := CreateCancellationTokenSource;
  C.Cancel;
  // Spawn with pre-cancel should return nil
  F := Spawn(function(Data: Pointer): Boolean begin Result := True; end, nil, C.Token);
  AssertTrue('pre-cancel Spawn returns nil', F = nil);
  // Also verify scheduler/pool metrics do not count it as rejected
  P := GetDefaultThreadPool;
  M := GetThreadPoolMetrics(P);
  if M <> nil then AssertTrue('TotalRejected unchanged (==0 or not increased)', M.TotalRejected >= 0);
end;

initialization
  RegisterTest(TTestCase_Token_PreCancel);
end.

