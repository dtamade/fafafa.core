unit Test_future_generic;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread.future, fafafa.core.thread.future.generic;

type
  { TTestCase_TFutureGeneric }
  TTestCase_TFutureGeneric = class(TTestCase)
  private
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_CompleteWith_And_Result_Immediate;
    procedure Test_Result_Timeout;
  end;

implementation

type
  TStringFuture = specialize TFutureT<string>;

procedure TTestCase_TFutureGeneric.SetUp;
begin
  inherited SetUp;
end;

procedure TTestCase_TFutureGeneric.TearDown;
begin
  inherited TearDown;
end;

procedure TTestCase_TFutureGeneric.Test_CompleteWith_And_Result_Immediate;
var
  LFuture: TStringFuture;
  S: string;
begin
  LFuture := TStringFuture.Create;
  try
    LFuture.CompleteWith('ok');
    AssertTrue('Should be done', LFuture.IsDone);
    AssertEquals('ok', LFuture.GetResult);

    // TryGetResult
    AssertTrue('TryGetResult true', LFuture.TryGetResult(S));
    AssertEquals('ok', S);
  finally
    LFuture.Free;
  end;
end;

procedure TTestCase_TFutureGeneric.Test_Result_Timeout;
var
  LFuture: TStringFuture;
begin
  LFuture := TStringFuture.Create;
  try
    AssertException('Timeout should raise', EInvalidOperation,
      procedure
      begin
        LFuture.GetResult(50);
      end);
  finally
    LFuture.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_TFutureGeneric);

end.

