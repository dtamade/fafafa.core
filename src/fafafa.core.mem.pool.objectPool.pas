unit fafafa.core.mem.pool.objectPool;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base,
  fafafa.core.mem.allocator.base,
  fafafa.core.mem.allocator.rtlAllocator,
  fafafa.core.mem.pool;

type

  generic IObjectPool<T: TObject> = interface(IPool)
  ['{6B2E8E2D-0C3A-4E6C-9D7F-2B7E4B7A9A10}']
    function  AcquireObject(out aObject: T): Boolean;
    procedure ReleaseObject(aObject: T);
  end;

  generic TObjectPool<T: TObject> = class(TInterfacedObject, IPool)
  type
    TObjectCreatorFunc     = function: T;
    TObjectCreatorMethod   = function: T of object;
    TObjectCreatorRefFunc  = reference to function: T;
    TObjectInitFunc        = procedure (aObject: T);
    TObjectInitMethod      = procedure (aObject: T) of object;
    TObjectInitRefFunc     = reference to procedure(aObject: T);
    TObjectFinalizeFunc    = procedure (aObject: T);
    TObjectFinalizeMethod  = procedure (aObject: T) of object;
    TObjectFinalizeRefFunc = reference to procedure(aObject: T);

    TObjectCreatorProxy  = function(aCreator: Pointer): T;
    TObjectInitProxy     = procedure (aInit: Pointer; aObject: T);
    TObjectFinalizeProxy = procedure (aFinalize: Pointer; aObject: T);
  private
    FAllocator:      IAllocator;
    FMaxSize:        SizeUInt;
    FCurrentObjects: SizeUInt;

    // Object storage
    FPool:     array of T;
    FFreeTop:  SizeInt;

    FCreator:  Pointer;
    FInit:     Pointer;
    FFinalize: Pointer;

    FCreatorType:   (ctNone, ctFunc, ctMethod, ctRefFunc);
    FInitType:      (itNone, itFunc, itMethod, itRefFunc);
    FFinalizeType:  (ftNone, ftFunc, ftMethod, ftRefFunc);
  protected
    function  CreateObject: T;
    procedure InitObject(aObject: T);
    procedure FinalizeObject(aObject: T);

    function  GetMaxObjects: SizeUInt;
    function  GetCurrentObjects: SizeUInt;

  public
    constructor Create(aAllocator: IAllocator; aMaxSize: SizeUInt; aCreator: TObjectCreatorFunc; aInit: TObjectInitFunc; aFinalize: TObjectFinalizeFunc);
    constructor Create(aAllocator: IAllocator; aCreator: TObjectCreatorFunc; aInit: TObjectInitFunc; aFinalize: TObjectFinalizeFunc);
    constructor Create(aAllocator: IAllocator; aCreator: TObjectCreatorFunc; aInit: TObjectInitFunc);
    constructor Create(aAllocator: IAllocator; aCreator: TObjectCreatorFunc);
    constructor Create(aMaxSize: SizeUInt; aCreator: TObjectCreatorFunc; aInit: TObjectInitFunc; aFinalize: TObjectFinalizeFunc);
    constructor Create(aCreator: TObjectCreatorFunc; aInit: TObjectInitFunc; aFinalize: TObjectFinalizeFunc);
    constructor Create(aCreator: TObjectCreatorFunc; aInit: TObjectInitFunc);
    constructor Create(aCreator: TObjectCreatorFunc);

    constructor Create(aAllocator: IAllocator; aMaxSize: SizeUInt; aCreator: TObjectCreatorMethod; aInit: TObjectInitMethod; aFinalize: TObjectFinalizeMethod);
    constructor Create(aAllocator: IAllocator; aCreator: TObjectCreatorMethod; aInit: TObjectInitMethod; aFinalize: TObjectFinalizeMethod);
    constructor Create(aAllocator: IAllocator; aCreator: TObjectCreatorMethod; aInit: TObjectInitMethod);
    constructor Create(aAllocator: IAllocator; aCreator: TObjectCreatorMethod);
    constructor Create(aMaxSize: SizeUInt; aCreator: TObjectCreatorMethod; aInit: TObjectInitMethod; aFinalize: TObjectFinalizeMethod);
    constructor Create(aCreator: TObjectCreatorMethod; aInit: TObjectInitMethod; aFinalize: TObjectFinalizeMethod);
    constructor Create(aCreator: TObjectCreatorMethod; aInit: TObjectInitMethod);
    constructor Create(aCreator: TObjectCreatorMethod);

    constructor Create(aAllocator: IAllocator; aMaxSize: SizeUInt; aCreator: TObjectCreatorRefFunc; aInit: TObjectInitRefFunc; aFinalize: TObjectFinalizeRefFunc);
    constructor Create(aAllocator: IAllocator; aCreator: TObjectCreatorRefFunc; aInit: TObjectInitRefFunc; aFinalize: TObjectFinalizeRefFunc);
    constructor Create(aAllocator: IAllocator; aCreator: TObjectCreatorRefFunc; aInit: TObjectInitRefFunc);
    constructor Create(aAllocator: IAllocator; aCreator: TObjectCreatorRefFunc);
    constructor Create(aMaxSize: SizeUInt; aCreator: TObjectCreatorRefFunc; aInit: TObjectInitRefFunc; aFinalize: TObjectFinalizeRefFunc);
    constructor Create(aCreator: TObjectCreatorRefFunc; aInit: TObjectInitRefFunc; aFinalize: TObjectFinalizeRefFunc);
    constructor Create(aCreator: TObjectCreatorRefFunc; aInit: TObjectInitRefFunc);
    constructor Create(aCreator: TObjectCreatorRefFunc);

    destructor Destroy; override;

    function  Acquire(out aObject: Pointer): Boolean;
    procedure Release(aObject: Pointer);

    function  AcquireObject(out aObject: T): Boolean;
    procedure ReleaseObject(aObject: T);

    procedure Reset;

    property MaxObjects: SizeUInt read GetMaxObjects;
    property CurrentObjects: SizeUInt read GetCurrentObjects;
  end;



implementation

{ TObjectPool<T> }

function TObjectPool.GetMaxObjects: SizeUInt;
begin
  Result := FMaxSize;
end;

function TObjectPool.GetCurrentObjects: SizeUInt;
begin
  Result := FCurrentObjects;
end;

function TObjectPool.CreateObject: T;
begin
  case FCreatorType of
    ctFunc:    if FCreator <> nil then Result := TObjectCreatorFunc(FCreator^)() else Result := T.Create;
    ctMethod:  if FCreator <> nil then Result := TObjectCreatorMethod(FCreator^)() else Result := T.Create;
    ctRefFunc: if FCreator <> nil then Result := TObjectCreatorRefFunc(FCreator^)() else Result := T.Create;
    else       Result := T.Create;
  end;
end;

procedure TObjectPool.InitObject(aObject: T);
begin
  case FInitType of
    itFunc:    if FInit <> nil then TObjectInitFunc(FInit^)(aObject);
    itMethod:  if FInit <> nil then TObjectInitMethod(FInit^)(aObject);
    itRefFunc: if FInit <> nil then TObjectInitRefFunc(FInit^)(aObject);
  end;
end;

procedure TObjectPool.FinalizeObject(aObject: T);
begin
  case FFinalizeType of
    ftFunc:    if FFinalize <> nil then TObjectFinalizeFunc(FFinalize^)(aObject);
    ftMethod:  if FFinalize <> nil then TObjectFinalizeMethod(FFinalize^)(aObject);
    ftRefFunc: if FFinalize <> nil then TObjectFinalizeRefFunc(FFinalize^)(aObject);
  end;
end;

// Core constructor - all others delegate to this
constructor TObjectPool.Create(aAllocator: IAllocator; aMaxSize: SizeUInt; aCreator: TObjectCreatorFunc; aInit: TObjectInitFunc; aFinalize: TObjectFinalizeFunc);
begin
  inherited Create;

  if aMaxSize = 0 then
    FMaxSize := 100
  else
    FMaxSize := aMaxSize;

  if aAllocator = nil then
    FAllocator := GetRtlAllocator
  else
    FAllocator := aAllocator;

  FCurrentObjects := 0;
  FFreeTop := 0;

  SetLength(FPool, FMaxSize);

  // Setup creator
  FCreator := @aCreator;
  FCreatorType := ctFunc;

  // Setup init
  if @aInit <> nil then
  begin
    FInit := @aInit;
    FInitType := itFunc;
  end
  else
  begin
    FInit := nil;
    FInitType := itNone;
  end;

  // Setup finalize
  if @aFinalize <> nil then
  begin
    FFinalize := @aFinalize;
    FFinalizeType := ftFunc;
  end
  else
  begin
    FFinalize := nil;
    FFinalizeType := ftNone;
  end;
end;

destructor TObjectPool.Destroy;
var
  i: SizeInt;
begin
  // Free all objects in pool
  for i := 0 to FFreeTop - 1 do
  begin
    if FPool[i] <> nil then
      FPool[i].Free;
  end;

  SetLength(FPool, 0);
  inherited Destroy;
end;

function TObjectPool.AcquireObject(out aObject: T): Boolean;
begin
  Result := False;
  aObject := nil;

  // Try to get from pool first
  if FFreeTop > 0 then
  begin
    Dec(FFreeTop);
    aObject := FPool[FFreeTop];
    FPool[FFreeTop] := nil;
    Dec(FCurrentObjects);
    Result := True;
  end
  else
  begin
    // Create new object if we haven't reached max size
    if FCurrentObjects < FMaxSize then
    begin
      aObject := CreateObject;
      Result := aObject <> nil;
    end;
  end;

  // Initialize object if we got one
  if Result and (aObject <> nil) and (FInitType <> itNone) then
    InitObject(aObject);
end;

procedure TObjectPool.ReleaseObject(aObject: T);
begin
  if aObject = nil then Exit;

  // Finalize object
  if FFinalizeType <> ftNone then
    FinalizeObject(aObject);

  // Return to pool if there's space
  if FCurrentObjects < FMaxSize then
  begin
    FPool[FFreeTop] := aObject;
    Inc(FFreeTop);
    Inc(FCurrentObjects);
  end
  else
  begin
    // Pool is full, destroy object
    aObject.Free;
  end;
end;

function TObjectPool.Acquire(out aObject: Pointer): Boolean;
var
  LObj: T;
begin
  Result := AcquireObject(LObj);
  aObject := Pointer(LObj);
end;

procedure TObjectPool.Release(aObject: Pointer);
begin
  if aObject <> nil then
    ReleaseObject(T(aObject));
end;

procedure TObjectPool.Reset;
var
  i: SizeInt;
begin
  // Free all objects in pool
  for i := 0 to FFreeTop - 1 do
  begin
    if FPool[i] <> nil then
      FPool[i].Free;
  end;

  FFreeTop := 0;
  FCurrentObjects := 0;
end;

// Function pointer constructors
constructor TObjectPool.Create(aAllocator: IAllocator; aCreator: TObjectCreatorFunc; aInit: TObjectInitFunc; aFinalize: TObjectFinalizeFunc);
begin
  Create(aAllocator, 0, aCreator, aInit, aFinalize);
end;

constructor TObjectPool.Create(aAllocator: IAllocator; aCreator: TObjectCreatorFunc; aInit: TObjectInitFunc);
begin
  Create(aAllocator, 0, aCreator, aInit, nil);
end;

constructor TObjectPool.Create(aAllocator: IAllocator; aCreator: TObjectCreatorFunc);
begin
  Create(aAllocator, 0, aCreator, nil, nil);
end;

constructor TObjectPool.Create(aMaxSize: SizeUInt; aCreator: TObjectCreatorFunc; aInit: TObjectInitFunc; aFinalize: TObjectFinalizeFunc);
begin
  Create(nil, aMaxSize, aCreator, aInit, aFinalize);
end;

constructor TObjectPool.Create(aCreator: TObjectCreatorFunc; aInit: TObjectInitFunc; aFinalize: TObjectFinalizeFunc);
begin
  Create(nil, 0, aCreator, aInit, aFinalize);
end;

constructor TObjectPool.Create(aCreator: TObjectCreatorFunc; aInit: TObjectInitFunc);
begin
  Create(nil, 0, aCreator, aInit, nil);
end;

constructor TObjectPool.Create(aCreator: TObjectCreatorFunc);
begin
  Create(nil, 0, aCreator, nil, nil);
end;

// Method pointer constructors - need separate implementation
constructor TObjectPool.Create(aAllocator: IAllocator; aMaxSize: SizeUInt; aCreator: TObjectCreatorMethod; aInit: TObjectInitMethod; aFinalize: TObjectFinalizeMethod);
begin
  inherited Create;

  if aMaxSize = 0 then
    FMaxSize := 100
  else
    FMaxSize := aMaxSize;

  if aAllocator = nil then
    FAllocator := GetRtlAllocator
  else
    FAllocator := aAllocator;

  FCurrentObjects := 0;
  FFreeTop := 0;

  SetLength(FPool, FMaxSize);

  // Setup creator
  FCreator := @aCreator;
  FCreatorType := ctMethod;

  // Setup init
  if @aInit <> nil then
  begin
    FInit := @aInit;
    FInitType := itMethod;
  end
  else
  begin
    FInit := nil;
    FInitType := itNone;
  end;

  // Setup finalize
  if @aFinalize <> nil then
  begin
    FFinalize := @aFinalize;
    FFinalizeType := ftMethod;
  end
  else
  begin
    FFinalize := nil;
    FFinalizeType := ftNone;
  end;
end;

constructor TObjectPool.Create(aAllocator: IAllocator; aCreator: TObjectCreatorMethod; aInit: TObjectInitMethod; aFinalize: TObjectFinalizeMethod);
begin
  Create(aAllocator, 0, aCreator, aInit, aFinalize);
end;

constructor TObjectPool.Create(aAllocator: IAllocator; aCreator: TObjectCreatorMethod; aInit: TObjectInitMethod);
begin
  Create(aAllocator, 0, aCreator, aInit, nil);
end;

constructor TObjectPool.Create(aAllocator: IAllocator; aCreator: TObjectCreatorMethod);
begin
  Create(aAllocator, 0, aCreator, nil, nil);
end;

constructor TObjectPool.Create(aMaxSize: SizeUInt; aCreator: TObjectCreatorMethod; aInit: TObjectInitMethod; aFinalize: TObjectFinalizeMethod);
begin
  Create(nil, aMaxSize, aCreator, aInit, aFinalize);
end;

constructor TObjectPool.Create(aCreator: TObjectCreatorMethod; aInit: TObjectInitMethod; aFinalize: TObjectFinalizeMethod);
begin
  Create(nil, 0, aCreator, aInit, aFinalize);
end;

constructor TObjectPool.Create(aCreator: TObjectCreatorMethod; aInit: TObjectInitMethod);
begin
  Create(nil, 0, aCreator, aInit, nil);
end;

constructor TObjectPool.Create(aCreator: TObjectCreatorMethod);
begin
  Create(nil, 0, aCreator, nil, nil);
end;

// Reference function constructors - need separate implementation
constructor TObjectPool.Create(aAllocator: IAllocator; aMaxSize: SizeUInt; aCreator: TObjectCreatorRefFunc; aInit: TObjectInitRefFunc; aFinalize: TObjectFinalizeRefFunc);
begin
  inherited Create;

  if aMaxSize = 0 then
    FMaxSize := 100
  else
    FMaxSize := aMaxSize;

  if aAllocator = nil then
    FAllocator := GetRtlAllocator
  else
    FAllocator := aAllocator;

  FCurrentObjects := 0;
  FFreeTop := 0;

  SetLength(FPool, FMaxSize);

  // Setup creator
  FCreator := @aCreator;
  FCreatorType := ctRefFunc;

  // Setup init
  if @aInit <> nil then
  begin
    FInit := @aInit;
    FInitType := itRefFunc;
  end
  else
  begin
    FInit := nil;
    FInitType := itNone;
  end;

  // Setup finalize
  if @aFinalize <> nil then
  begin
    FFinalize := @aFinalize;
    FFinalizeType := ftRefFunc;
  end
  else
  begin
    FFinalize := nil;
    FFinalizeType := ftNone;
  end;
end;

constructor TObjectPool.Create(aAllocator: IAllocator; aCreator: TObjectCreatorRefFunc; aInit: TObjectInitRefFunc; aFinalize: TObjectFinalizeRefFunc);
begin
  Create(aAllocator, 0, aCreator, aInit, aFinalize);
end;

constructor TObjectPool.Create(aAllocator: IAllocator; aCreator: TObjectCreatorRefFunc; aInit: TObjectInitRefFunc);
begin
  Create(aAllocator, 0, aCreator, aInit, nil);
end;

constructor TObjectPool.Create(aAllocator: IAllocator; aCreator: TObjectCreatorRefFunc);
begin
  Create(aAllocator, 0, aCreator, nil, nil);
end;

constructor TObjectPool.Create(aMaxSize: SizeUInt; aCreator: TObjectCreatorRefFunc; aInit: TObjectInitRefFunc; aFinalize: TObjectFinalizeRefFunc);
begin
  Create(nil, aMaxSize, aCreator, aInit, aFinalize);
end;

constructor TObjectPool.Create(aCreator: TObjectCreatorRefFunc; aInit: TObjectInitRefFunc; aFinalize: TObjectFinalizeRefFunc);
begin
  Create(nil, 0, aCreator, aInit, aFinalize);
end;

constructor TObjectPool.Create(aCreator: TObjectCreatorRefFunc; aInit: TObjectInitRefFunc);
begin
  Create(nil, 0, aCreator, aInit, nil);
end;

constructor TObjectPool.Create(aCreator: TObjectCreatorRefFunc);
begin
  Create(nil, 0, aCreator, nil, nil);
end;

end.