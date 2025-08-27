unit fafafa.core.mem.pool.typedObjectPool;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.mem.objectPool,
  fafafa.core.mem.allocator;

type
  // 独立强类型门面：使用组合委托到基础泛型对象池
  generic TTypedObjectPoolFacade<T: TObject> = class
  private
    type TInnerPool = specialize TTypedObjectPool<T>;
  private
    FInner: TInnerPool;
  public
    constructor Create(aObjectClass: TClass; aMaxSize: Integer = 100;
      aFactory: TObjectFactory = nil;
      aInitializer: TObjectInitializer = nil;
      aFinalizer: TObjectFinalizer = nil;
      aAllocator: IAllocator = nil);
    destructor Destroy; override;

    // 兼容指针式接口（不实现 IPool，仅便捷）
    function Acquire(out AUnit: Pointer): Boolean; inline;
    procedure Release(AUnit: Pointer); inline;
    procedure Reset; inline;

    // 强类型 API
    function GetTyped: T; inline;
    procedure Return(aObject: T); inline;

    // 其他委托
    procedure Preallocate(aCount: Integer); inline;
  end;

implementation

constructor TTypedObjectPoolFacade.Create(aObjectClass: TClass; aMaxSize: Integer;
  aFactory: TObjectFactory;
  aInitializer: TObjectInitializer;
  aFinalizer: TObjectFinalizer;
  aAllocator: IAllocator);
begin
  inherited Create;
  FInner := TInnerPool.Create(
    aObjectClass, aMaxSize, aFactory, aInitializer, aFinalizer, aAllocator);
end;

destructor TTypedObjectPoolFacade.Destroy;
begin
  FreeAndNil(FInner);
  inherited Destroy;
end;

function TTypedObjectPoolFacade.Acquire(out AUnit: Pointer): Boolean;
var
  LObj: T;
begin
  LObj := FInner.Get;
  AUnit := Pointer(LObj);
  Result := AUnit <> nil;
end;

procedure TTypedObjectPoolFacade.Release(AUnit: Pointer);
begin
  if AUnit = nil then Exit;
  FInner.Return(T(AUnit));
end;

procedure TTypedObjectPoolFacade.Reset;
begin
  FInner.Clear;
end;

function TTypedObjectPoolFacade.GetTyped: T;
begin
  Result := FInner.Get;
end;

procedure TTypedObjectPoolFacade.Return(aObject: T);
begin
  FInner.Return(aObject);
end;

procedure TTypedObjectPoolFacade.Preallocate(aCount: Integer);
begin
  FInner.Preallocate(aCount);
end;

end.

