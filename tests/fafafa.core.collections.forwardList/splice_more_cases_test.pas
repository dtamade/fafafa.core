program splice_more_cases_test;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.collections.base,
  fafafa.core.collections.forwardList;

type
  TIntFL = specialize TForwardList<Integer>;

procedure AssertTrue(const Msg: string; Cond: Boolean);
begin
  if not Cond then begin WriteLn('ASSERT FAIL: ', Msg); Halt(1); end;
end;

procedure Test_Splice_EmptySource;
var A,B:TIntFL; pos: specialize TIter<Integer>;
begin
  A := TIntFL.Create; B := TIntFL.Create;
  try
    A.PushFront(2); A.PushFront(1);
    pos := A.BeforeBegin;
    A.Splice(pos, B); // 空源
    AssertTrue('A size unchanged', A.GetCount=2);
  finally A.Free; B.Free; end;
end;

procedure Test_Splice_SameNodeMultipleTimes;
var A,B:TIntFL; pos, first: specialize TIter<Integer>;
begin
  A := TIntFL.Create; B := TIntFL.Create;
  try
    A.PushFront(3); A.PushFront(2); A.PushFront(1);
    B.PushFront(6); B.PushFront(5); B.PushFront(4);
    pos := A.CEnd;
    first := B.BeforeBegin; // 要移动的是 4
    A.Splice(pos, B, first);
    // 再次移动 B 的第一个（现在是 5）
    A.Splice(pos, B, first);
    AssertTrue('B now has 1 element left', B.GetCount=1);
    AssertTrue('A has 5 elements', A.GetCount=5);
  finally A.Free; B.Free; end;
end;

begin
  try
    Test_Splice_EmptySource;
    Test_Splice_SameNodeMultipleTimes;
    WriteLn('Splice more cases test passed');
  except
    on E: Exception do begin
      WriteLn('Test failed: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.

