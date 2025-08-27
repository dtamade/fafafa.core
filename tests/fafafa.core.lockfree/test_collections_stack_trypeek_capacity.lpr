program test_collections_stack_trypeek_capacity;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.lockfree.stack,
  fafafa.core.collections.stack;

type
  TIntStack = specialize IStack<Integer>;

procedure TestPreallocTryPeekCapacity;
var
  S: TIntStack;
  v: Integer;
  i: Integer;
begin
  WriteLn('== PreAlloc TryPeek/Capacity ==');
  S := specialize MakePreallocStack<Integer>(3);

  // empty
  if not S.IsEmpty then raise Exception.Create('PreAlloc: expected empty at start');
  if S.TryPeek(v) then raise Exception.Create('PreAlloc: TryPeek on empty should be False');

  // fill to capacity 1..3
  for i := 1 to 3 do S.Push(i);
  if S.Count <> 3 then raise Exception.Create('PreAlloc: Count should be 3');
  if not S.TryPeek(v) then raise Exception.Create('PreAlloc: TryPeek after fill should be True');
  if v <> 3 then raise Exception.CreateFmt('PreAlloc: TryPeek got %d expect 3', [v]);

  // push beyond capacity should raise
  try
    S.Push(4);
    raise Exception.Create('PreAlloc: Push beyond capacity should raise');
  except
    on E: Exception do ;
  end;

  // pop one then push again
  if not S.Pop(v) then raise Exception.Create('PreAlloc: Pop failed after full');
  if v <> 3 then raise Exception.CreateFmt('PreAlloc: Pop got %d expect 3', [v]);
  S.Push(4);
  if S.Count <> 3 then raise Exception.Create('PreAlloc: Count should return to 3');

  S.Clear;
  if not S.IsEmpty then raise Exception.Create('PreAlloc: not empty after Clear');
  if S.TryPeek(v) then raise Exception.Create('PreAlloc: TryPeek after Clear should be False');

  WriteLn('PreAlloc TryPeek/Capacity OK');
end;

procedure TestTreiberTryPeek;
var
  S: TIntStack;
  v: Integer;
begin
  WriteLn('== Treiber TryPeek ==');
  S := specialize MakeTreiberStack<Integer>();
  S.Push(1);
  if S.TryPeek(v) then
    raise Exception.Create('Treiber: TryPeek should be False (unsupported)');
  if not S.Pop(v) then raise Exception.Create('Treiber: Pop failed');
  if v <> 1 then raise Exception.CreateFmt('Treiber: Pop got %d expect 1', [v]);
  WriteLn('Treiber TryPeek OK');
end;

begin
  try
    TestPreallocTryPeekCapacity;
    TestTreiberTryPeek;
    WriteLn('All TryPeek/Capacity cases OK');
  except
    on E: Exception do
    begin
      WriteLn('FAILED: ', E.Message);
      Halt(1);
    end;
  end;
end.

