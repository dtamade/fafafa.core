program tests_treeset_no_fpcunit;

{$mode objfpc}{$H+}
{$modeswitch anonymousfunctions}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.base,
  fafafa.core.collections.orderedset.rb,
  fafafa.core.collections,
  fafafa.core.test.core,
  fafafa.core.test.runner;

procedure RegisterTests;
begin
  Test('treeset/rb/create-only', procedure(const ctx: ITestContext)
  var S: specialize TRBTreeSet<Integer>;
  begin
    S := specialize TRBTreeSet<Integer>.Create;
    S.Free;
  end);

  Test('treeset/rb/smoke-create-insert', procedure(const ctx: ITestContext)
  var
    S: specialize TRBTreeSet<Integer>;
  begin
    S := specialize TRBTreeSet<Integer>.Create;
    try
      ctx.AssertTrue(S.Insert(1), 'insert 1');
      ctx.AssertTrue(S.Insert(2), 'insert 2');
      ctx.AssertTrue(S.ContainsKey(1), 'contains 1');
      ctx.AssertTrue(S.ContainsKey(2), 'contains 2');
      ctx.AssertTrue(not S.ContainsKey(3), 'not contains 3');
    finally
      S.Free;
    end;
  end);

  Test('treeset/rb/ordered-insert-and-iter', procedure(const ctx: ITestContext)
  var
    S: specialize TRBTreeSet<Integer>;
    I, Prev, Cur: Integer;
    It: specialize TIter<Integer>;
    HasFirst: Boolean;
  begin
    S := specialize TRBTreeSet<Integer>.Create;
    try
      for I := 1 to 100 do S.Insert(Random(50));
      It := S.Iter;
      HasFirst := It.MoveNext;
      if HasFirst then
      begin
        Prev := It.Current;
        while It.MoveNext do
        begin
          Cur := It.Current;
          ctx.AssertTrue(Cur > Prev, 'in-order strictly increasing');
          Prev := Cur;
        end;
      end;
    finally
      S.Free;
    end;
  end);

  Test('treeset/rb/lower-upper-bound', procedure(const ctx: ITestContext)
  var
    S: specialize TRBTreeSet<Integer>;
    v: Integer;
  begin
    S := specialize TRBTreeSet<Integer>.Create;
    try
      S.Insert(10); S.Insert(20); S.Insert(30);
      ctx.AssertTrue(S.LowerBound(15, v) and (v=20), 'lb(15)=20');
      ctx.AssertTrue(S.UpperBound(20, v) and (v=30), 'ub(20)=30');
      ctx.AssertTrue(not S.LowerBound(31, v), 'lb(31) none');
      ctx.AssertTrue(S.LowerBound(5, v) and (v=10), 'lb(5)=10');
    finally
      S.Free;
    end;
  end);

end;

begin
  Randomize;
  RegisterTests;
  TestMain;
end.



  Test('treeset/rb/insert-duplicate-and-count', procedure(const ctx: ITestContext)
  var
    S: specialize TRBTreeSet<Integer>;
  begin
    S := specialize TRBTreeSet<Integer>.Create;
    try
      ctx.AssertTrue(S.Insert(42), 'first insert should be True');
      ctx.AssertTrue(S.GetCount = 1, 'count=1 after first insert');
      ctx.AssertTrue(not S.Insert(42), 'duplicate insert should be False');
      ctx.AssertTrue(S.GetCount = 1, 'count still 1 after duplicate');
    finally
      S.Free;
    end;
  end);

  Test('treeset/rb/iter-empty', procedure(const ctx: ITestContext)
  var
    S: specialize TRBTreeSet<Integer>;
    It: specialize TIter<Integer>;
  begin
    S := specialize TRBTreeSet<Integer>.Create;
    try
      It := S.Iter;
      ctx.AssertTrue(not It.MoveNext, 'empty MoveNext=False');
      ctx.AssertTrue(not It.MovePrev, 'empty MovePrev=False');
    finally
      S.Free;
    end;
  end);

  Test('treeset/rb/iter-reverse', procedure(const ctx: ITestContext)
  var
    S: specialize TRBTreeSet<Integer>;
    I, Prev, Cur: Integer;
    It: specialize TIter<Integer>;
    Has: Boolean;
  begin
    S := specialize TRBTreeSet<Integer>.Create;
    try
      for I := 1 to 10 do S.Insert(I);
      It := S.Iter;
      Has := It.MovePrev; // first call positions at max
      if Has then
      begin
        Prev := It.Current;
        while It.MovePrev do
        begin
          Cur := It.Current;
          ctx.AssertTrue(Cur < Prev, 'reverse strictly decreasing');
          Prev := Cur;
        end;
      end
      else
        ctx.Fail('expected non-empty iterator');
    finally
      S.Free;
    end;
  end);

  Test('treeset/rb/upper-bound-edge', procedure(const ctx: ITestContext)
  var
    S: specialize TRBTreeSet<Integer>;
    v: Integer;
  begin
    S := specialize TRBTreeSet<Integer>.Create;
    try
      S.Insert(10); S.Insert(20); S.Insert(30);
      ctx.AssertTrue(S.UpperBound(0, v) and (v=10), 'ub(0)=10');
      ctx.AssertTrue(S.UpperBound(10, v) and (v=20), 'ub(10)=20');
      ctx.AssertTrue(S.UpperBound(29, v) and (v=30), 'ub(29)=30');
      ctx.AssertTrue(not S.UpperBound(30, v), 'ub(30) none');
      ctx.AssertTrue(not S.UpperBound(31, v), 'ub(31) none');
    finally
      S.Free;
    end;
  end);





