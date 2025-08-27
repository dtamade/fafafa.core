{$CODEPAGE UTF8}
program iterator_dispatch;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$UNITPATH ../../src}

uses
  SysUtils{$IFDEF MSWINDOWS}, Windows{$ENDIF};

const
  ITERATION_COUNT = 10000000; // 一千万次（默认，不阻塞太久）

// 多态接口
type
  IBenchIterator = interface
  ['{1A7E8A5A-5B1A-4D7E-8F2B-2E4A6E1A0E4A}']
    function MoveNext: Boolean;
  end;

  TDummyState = record
    Counter: Integer;
  end;
  PDummyState = ^TDummyState;

  TPolymorphicIterator = class(TInterfacedObject, IBenchIterator)
  private
    FState: PDummyState;
  public
    constructor Create;
    destructor Destroy; override;
    function MoveNext: Boolean; virtual;
  end;

// 回调版本
  TMoveNextProc = function(aState: PDummyState): Boolean of object;

  TCallbackIterator = class
  private
    FState: PDummyState;
    FMoveNextProc: TMoveNextProc;
    FOwner: TObject;
  public
    constructor Create(aOwner: TObject; aMoveNextProc: TMoveNextProc);
    destructor Destroy; override;
    function MoveNext: Boolean;
  end;

  TDummyContainer = class
  public
    function MoveNextImplementation(aState: PDummyState): Boolean;
  end;

{ TPolymorphicIterator }
constructor TPolymorphicIterator.Create;
begin
  inherited Create;
  New(FState);
  FState^.Counter := 0;
end;

destructor TPolymorphicIterator.Destroy;
begin
  Dispose(FState);
  inherited Destroy;
end;

function TPolymorphicIterator.MoveNext: Boolean;
begin
  Inc(FState^.Counter);
  Result := FState^.Counter < ITERATION_COUNT;
end;

{ TCallbackIterator }
constructor TCallbackIterator.Create(aOwner: TObject; aMoveNextProc: TMoveNextProc);
begin
  inherited Create;
  New(FState);
  FState^.Counter := 0;
  FOwner := aOwner;
  FMoveNextProc := aMoveNextProc;
end;

destructor TCallbackIterator.Destroy;
begin
  Dispose(FState);
  inherited Destroy;
end;

function TCallbackIterator.MoveNext: Boolean;
begin
  Result := FMoveNextProc(FState);
end;

{ TDummyContainer }
function TDummyContainer.MoveNextImplementation(aState: PDummyState): Boolean;
begin
  Inc(aState^.Counter);
  Result := aState^.Counter < ITERATION_COUNT;
end;

// helpers
function NowMs: QWord; inline;
begin
  {$IFDEF MSWINDOWS}
  Result := GetTickCount64;
  {$ELSE}
  Result := MilliSecondOf(Now);
  {$ENDIF}
end;

procedure Bench;
var LPolyIter: IBenchIterator; LCallbackIter: TCallbackIterator; LContainer: TDummyContainer;
    LStartTime, LEndTime: QWord;
begin
  WriteLn('Iterations per test: ', ITERATION_COUNT);
  // 多态
  LPolyIter := TPolymorphicIterator.Create;
  LStartTime := NowMs;
  while LPolyIter.MoveNext do ;
  LEndTime := NowMs;
  WriteLn('Polymorphic (Virtual Call) Time: ', LEndTime - LStartTime, ' ms');
  LPolyIter := nil;
  // 回调
  LContainer := TDummyContainer.Create;
  LCallbackIter := TCallbackIterator.Create(LContainer, @LContainer.MoveNextImplementation);
  LStartTime := NowMs;
  while LCallbackIter.MoveNext do ;
  LEndTime := NowMs;
  WriteLn('Callback (Method Pointer) Time:  ', LEndTime - LStartTime, ' ms');
  LCallbackIter.Free; LContainer.Free;
end;

begin
  WriteLn('=== Iterator dispatch microbench ===');
  Bench;
end.

