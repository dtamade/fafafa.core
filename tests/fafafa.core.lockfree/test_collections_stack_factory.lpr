program test_collections_stack_factory;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.collections.stack,
  fafafa.core.lockfree.stack;

type
  TIntStack = specialize IStack<Integer>;

procedure TestTreiber;
var
  S: TIntStack;
  v: Integer;
  i: Integer;
begin
  WriteLn('== Treiber via MakeTreiberStack ==');
  S := specialize MakeTreiberStack<Integer>();

  // empty pop
  if S.Pop(v) then
    raise Exception.Create('Treiber: Pop on empty should be False');

  // push 1..5
  for i := 1 to 5 do S.Push(i);

  // TryPeek may be unsupported (returns False); do not assert strong behavior
  S.TryPeek(v);

  // pop 5..1
  for i := 5 downto 1 do
  begin
    if not S.Pop(v) then raise Exception.Create('Treiber: Pop failed');
    if v <> i then raise Exception.CreateFmt('Treiber: LIFO violated, got %d expect %d', [v, i]);
  end;

  if S.Pop(v) then
    raise Exception.Create('Treiber: Pop after drain should be False');

  WriteLn('Treiber OK');
end;

procedure TestPrealloc;
var
  S: TIntStack;
  v: Integer;
  i: Integer;
begin
  WriteLn('== PreAlloc via MakePreallocStack ==');
  S := specialize MakePreallocStack<Integer>(4);

  // empty TryPeek
  if S.TryPeek(v) then
    raise Exception.Create('PreAlloc: TryPeek on empty should be False');

  // push 1..4
  for i := 1 to 4 do S.Push(i);

  // Count/IsEmpty sanity
  if (S.Count <> 4) or S.IsEmpty then
    raise Exception.Create('PreAlloc: Count/IsEmpty mismatch');

  // TryPeek weak snapshot: may see 4
  S.TryPeek(v);

  // pop 4..1
  for i := 4 downto 1 do
  begin
    if not S.Pop(v) then raise Exception.Create('PreAlloc: Pop failed');
    if v <> i then raise Exception.CreateFmt('PreAlloc: LIFO violated, got %d expect %d', [v, i]);
  end;

  if S.TryPeek(v) then
    raise Exception.Create('PreAlloc: TryPeek after drain should be False');

  S.Clear; // best-effort no-op on empty
  WriteLn('PreAlloc OK');
end;

begin
  try
    TestTreiber;
    TestPrealloc;
    WriteLn('All OK');
  except
    on E: Exception do
    begin
      WriteLn('FAILED: ', E.Message);
      Halt(1);
    end;
  end;
end.

