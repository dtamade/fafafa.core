{$CODEPAGE UTF8}
unit test_objectPool;

{$mode objfpc}{$H+}

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.objectPool,
  fafafa.core.mem.pool.objectPool;

type
  TTestCase_ObjectPool = class(TTestCase)
  published
    procedure Test_Preallocate_Clear_NoFinalizer;
    procedure Test_Get_Return_Finalizer_Once;
    procedure Test_IPool_Acquire_Baseline;
  end;

implementation

type
  TMyObj = class(TObject)
  public
    class var CtorCount: Integer;
    class var DtorCount: Integer;
    class procedure ResetCounters; static;
    constructor Create; virtual;
    destructor Destroy; override;
  end;

class procedure TMyObj.ResetCounters;
begin
  CtorCount := 0;
  DtorCount := 0;
end;

constructor TMyObj.Create;
begin
  inherited Create;
  Inc(CtorCount);
end;

destructor TMyObj.Destroy;
begin
  Inc(DtorCount);
  inherited Destroy;
end;

var
  GInitCount: Integer = 0;
  GFinalCount: Integer = 0;

function FactoryFn: TObject;
begin
  Result := TMyObj.Create;
end;

procedure InitializerFn(aObj: TObject);
begin
  Inc(GInitCount);
end;

procedure FinalizerFn(aObj: TObject);
begin
  Inc(GFinalCount);
end;

procedure TTestCase_ObjectPool.Test_Preallocate_Clear_NoFinalizer;
var
  LPool: fafafa.core.mem.objectPool.TObjectPool;
begin
  TMyObj.ResetCounters;
  GInitCount := 0;
  GFinalCount := 0;

  LPool := fafafa.core.mem.objectPool.TObjectPool.Create(TMyObj, 8, @FactoryFn, @InitializerFn, @FinalizerFn, nil);
  try
    LPool.Preallocate(3);
    AssertEquals('Preallocate should not call Initializer', 0, GInitCount);
    AssertEquals('Preallocate should not call Finalizer', 0, GFinalCount);
    AssertEquals('CtorCount after Preallocate(3)', 3, TMyObj.CtorCount);

    LPool.Clear; // should Free objects without calling Finalizer

    AssertEquals('Finalizer should NOT be called by Clear', 0, GFinalCount);
    AssertEquals('DtorCount after Clear', 3, TMyObj.DtorCount);
  finally
    LPool.Free;
  end;
end;

procedure TTestCase_ObjectPool.Test_Get_Return_Finalizer_Once;
var
  LPool: fafafa.core.mem.objectPool.TObjectPool;
  LObj: TObject;
begin
  TMyObj.ResetCounters;
  GInitCount := 0;
  GFinalCount := 0;

  LPool := fafafa.core.mem.objectPool.TObjectPool.Create(TMyObj, 8, @FactoryFn, @InitializerFn, @FinalizerFn, nil);
  try
    // Borrow
    LObj := LPool.Get;
    AssertNotNull('Get returns object', LObj);
    AssertEquals('Initializer called once on Get', 1, GInitCount);
    AssertEquals('Finalizer not yet called', 0, GFinalCount);

    // Return
    LPool.Return(LObj);
    AssertEquals('Finalizer called once on Return', 1, GFinalCount);

    // Clear the pool (object currently inside pool)
    LPool.Clear;
    AssertEquals('Finalizer should NOT be called by Clear', 1, GFinalCount);
    AssertEquals('Destructor called once by Clear', 1, TMyObj.DtorCount);
  finally
    LPool.Free;
  end;
end;

procedure TTestCase_ObjectPool.Test_IPool_Acquire_Baseline;
var
  LPool: specialize TObjectPool<TMyObj>;
  LPtr: Pointer;
  LOk: Boolean;

  function FactoryFnT: TMyObj; inline; begin Result := TMyObj.Create; end;
  procedure InitializerFnT(aObj: TMyObj); inline; begin Inc(GInitCount); end;
  procedure FinalizerFnT(aObj: TMyObj); inline; begin Inc(GFinalCount); end;
begin
  // Use the generic facade that implements IPool
  LPool := specialize TObjectPool<TMyObj>.Create(4, @FactoryFnT, @InitializerFnT, @FinalizerFnT);
  try
    LPtr := nil;
    LOk := LPool.Acquire(LPtr);
    AssertTrue('Acquire should succeed', LOk);
    AssertNotNull('Acquire returns non-nil pointer', LPtr);

    LPool.Release(LPtr);
    LPool.Reset;
  finally
    LPool.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_ObjectPool);

end.

