{$CODEPAGE UTF8}
unit test_objectPool_typed;

{$mode objfpc}{$H+}

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.pool.typedObjectPool;

type
  TTestCase_ObjectPool_Typed = class(TTestCase)
  published
    procedure Test_Typed_Basic_Get_Return;
  end;

implementation

type
  TMyObj2 = class(TObject)
  public
    class var Ctor: Integer;
    class var Dtor: Integer;
    constructor Create; reintroduce;
    destructor Destroy; override;
    class procedure Reset; static;
  end;

constructor TMyObj2.Create;
begin
  inherited Create;
  Inc(Ctor);
end;

destructor TMyObj2.Destroy;
begin
  Inc(Dtor);
  inherited Destroy;
end;

class procedure TMyObj2.Reset;
begin
  Ctor := 0;
  Dtor := 0;
end;

procedure TTestCase_ObjectPool_Typed.Test_Typed_Basic_Get_Return;
var
  LPool: specialize TTypedObjectPoolFacade<TMyObj2>;
  P: Pointer;
  O: TMyObj2;
begin
  TMyObj2.Reset;
  LPool := specialize TTypedObjectPoolFacade<TMyObj2>.Create(TMyObj2, 4);
  try
    // Acquire via typed API
    O := LPool.GetTyped;
    AssertNotNull(O);
    LPool.Return(O);

    // Acquire via pointer API for compatibility
    P := nil;
    AssertTrue(LPool.Acquire(P));
    AssertNotNull(P);
    LPool.Release(P);

    // Reset
    LPool.Reset;
  finally
    LPool.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_ObjectPool_Typed);

end.

