program negative_edge_tests;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.collections.base,
  fafafa.core.collections.forwardList;

type
  TIntFL = specialize TForwardList<Integer>;






procedure Test_SelfSplice_ShouldRaise;
var A:TIntFL; pos: specialize TIter<Integer>;
begin
  A := TIntFL.Create;
  try
    A.PushFront(1); A.PushFront(2);
    pos := A.CEnd;
    try
      A.Splice(pos, A);
      WriteLn('ASSERT FAIL(no exception): self splice'); Halt(1);
    except
      on E: Exception do WriteLn('OK expected: self splice -> ', E.ClassName);
    end;
  finally A.Free; end;
end;

procedure Test_IteratorOwnership_ShouldRaise;
var A,B:TIntFL; pos: specialize TIter<Integer>;
begin
  A := TIntFL.Create; B := TIntFL.Create;
  try
    A.PushFront(1); B.PushFront(2);
    pos := B.CEnd; // 错误：pos 属于 B
    try
      A.Splice(pos, B);
      WriteLn('ASSERT FAIL(no exception): iterator ownership'); Halt(1);
    except
      on E: Exception do WriteLn('OK expected: iterator ownership -> ', E.ClassName);
    end;
  finally A.Free; B.Free; end;
end;

begin
  try
    Test_SelfSplice_ShouldRaise;
    Test_IteratorOwnership_ShouldRaise;
    WriteLn('Negative edge tests passed');
  except
    on E: Exception do begin
      WriteLn('Test failed: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.

