program test_collections_stack_concurrency;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, SyncObjs,
  fafafa.core.lockfree.stack,
  fafafa.core.collections.stack,
  fafafa.core.atomic;

type
  TIntStack = specialize IStack<Integer>;

  TProducer = class(TThread)
  private
    FStack: TIntStack;
    FStartValue: Integer;
    FCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const AStack: TIntStack; AStart, ACount: Integer);
  end;

  TConsumer = class(TThread)
  private
    FStack: TIntStack;
    FTarget: Integer;
    FPopped: PInteger;
  protected
    procedure Execute; override;
  public
    constructor Create(const AStack: TIntStack; ATarget: Integer; var APopped: Integer);
  end;

constructor TProducer.Create(const AStack: TIntStack; AStart, ACount: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FStack := AStack;
  FStartValue := AStart;
  FCount := ACount;
end;

procedure TProducer.Execute;
var i: Integer;
begin
  for i := 0 to FCount - 1 do
    FStack.Push(FStartValue + i);
end;

constructor TConsumer.Create(const AStack: TIntStack; ATarget: Integer; var APopped: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FStack := AStack;
  FTarget := ATarget;
  FPopped := @APopped;
end;

procedure TConsumer.Execute;
var v: Integer;
begin
  while atomic_load(FPopped^) < FTarget do
  begin
    if FStack.Pop(v) then
      atomic_increment(FPopped^)
    else
      Sleep(0);
  end;
end;

procedure RunCase(const AName: string; const AStack: TIntStack; Producers, ItemsPerProducer: Integer);
var
  threads: array of TProducer;
  consumer: TConsumer;
  i, popped: Integer;
  target: Integer;
begin
  WriteLn('== ', AName, ' ==');
  SetLength(threads, Producers);
  popped := 0;
  target := Producers * ItemsPerProducer;

  // create producers with disjoint ranges
  for i := 0 to Producers - 1 do
    threads[i] := TProducer.Create(AStack, i*ItemsPerProducer, ItemsPerProducer);

  consumer := TConsumer.Create(AStack, target, popped);

  for i := 0 to Producers - 1 do threads[i].Start;
  consumer.Start;

  for i := 0 to Producers - 1 do begin threads[i].WaitFor; threads[i].Free; end;
  consumer.WaitFor; consumer.Free;

  if popped <> target then
    raise Exception.CreateFmt('%s: popped %d != %d', [AName, popped, target]);

  if not AStack.IsEmpty then
    raise Exception.CreateFmt('%s: stack not empty after run; Count=%d', [AName, AStack.Count]);

  WriteLn(AName, ' OK');
end;

begin
  try
    // Treiber: unbounded, P producers + 1 consumer (single popper to avoid reclamation hazards under Immediate mode)
    RunCase('Treiber', specialize MakeTreiberStack<Integer>(), 4, 10000);

    // PreAlloc: bounded, same pattern
    RunCase('PreAlloc', specialize MakePreallocStack<Integer>(200000), 4, 50000);

    WriteLn('All concurrency cases OK');
  except
    on E: Exception do
    begin
      WriteLn('FAILED: ', E.Message);
      Halt(1);
    end;
  end;
end.

