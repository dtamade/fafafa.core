program find_iterator_semantics_test;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.collections.base,
  fafafa.core.collections.forwardList;

type
  TIntFL = specialize TForwardList<Integer>;

procedure AssertEq(const Msg: string; A, B: Integer);
begin
  if A <> B then
  begin
    WriteLn('ASSERT FAIL: ', Msg, ' got=', A, ' expect=', B);
    Halt(1);
  end;
end;

procedure Test_Find_Iterator_Started_False;
var
  L: TIntFL;
  it: specialize TIter<Integer>;
  cur: Integer;
begin
  L := TIntFL.Create;
  try
    L.PushFront(1); L.PushFront(2); L.PushFront(3); // 3,2,1
    it := L.Find(2);
    // 约定：Find 返回的迭代器保持 Started=False，首次 MoveNext 命中当前元素
    if not it.MoveNext then Halt(1);
    cur := it.Current;
    AssertEq('Find iterator current', cur, 2);
  finally
    L.Free;
  end;
end;

begin
  try
    Test_Find_Iterator_Started_False;
    WriteLn('Find iterator semantics test passed');
  except
    on E: Exception do
    begin
      WriteLn('Test failed: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.

