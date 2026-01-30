unit Test_threadpool_cancel;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

Type
  TTestCase_ThreadPool_Cancel = class(TTestCase)
  published
    procedure Test_Submit_Func_PreCancelled_ReturnsNil;
    procedure Test_Submit_Method_PreCancelled_ReturnsNil;
    procedure Test_Submit_Ref_PreCancelled_ReturnsNil;
  end;

implementation

type
  TWorker = class
  public
    function DoWork(Data: Pointer): Boolean;
  end;

function WorkFunc(Data: Pointer): Boolean;
begin
  Result := True;
end;

function TWorker.DoWork(Data: Pointer): Boolean;
begin
  Result := True;
end;

procedure TTestCase_ThreadPool_Cancel.Test_Submit_Func_PreCancelled_ReturnsNil;
var P: IThreadPool; C: ICancellationTokenSource; F: IFuture;
begin
  P := CreateFixedThreadPool(1);
  try
    C := CreateCancellationTokenSource;
    C.Cancel;
    F := P.Submit(@WorkFunc, C.Token, nil);
    AssertTrue('pre-cancel should return nil', F = nil);
  finally
    P.Shutdown; P.AwaitTermination(2000);
  end;
end;

procedure TTestCase_ThreadPool_Cancel.Test_Submit_Method_PreCancelled_ReturnsNil;
var P: IThreadPool; C: ICancellationTokenSource; F: IFuture; W: TWorker;
begin
  P := CreateFixedThreadPool(1);
  W := TWorker.Create;
  try
    C := CreateCancellationTokenSource;
    C.Cancel;
    F := P.Submit(@W.DoWork, C.Token, nil);
    AssertTrue('pre-cancel should return nil', F = nil);
  finally
    W.Free; P.Shutdown; P.AwaitTermination(2000);
  end;
end;

procedure TTestCase_ThreadPool_Cancel.Test_Submit_Ref_PreCancelled_ReturnsNil;
var P: IThreadPool; C: ICancellationTokenSource; F: IFuture;
begin
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  P := CreateFixedThreadPool(1);
  try
    C := CreateCancellationTokenSource;
    C.Cancel;
    F := P.Submit(function(): Boolean begin Result := True; end, C.Token);
    AssertTrue('pre-cancel should return nil', F = nil);
  finally
    P.Shutdown; P.AwaitTermination(2000);
  end;
  {$ELSE}
  // skip when anonymous references not enabled
  AssertTrue(True);
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_ThreadPool_Cancel);

end.

