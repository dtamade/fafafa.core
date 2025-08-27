program strict_eraseafter_and_splice_mix_tests;

{$mode objfpc}{$H+}
{$DEFINE FAFAFA_CORE_STRICT_ERASEAFTER}

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.collections.base,
  fafafa.core.collections.forwardList;

type
  TIntFL = specialize TForwardList<Integer>;

procedure ExpectException(const Msg: string; Proc: TProcedure);
begin
  try
    Proc;
    WriteLn('ASSERT FAIL(no exception): ', Msg); Halt(1);
  except
    on E: Exception do WriteLn('OK expected: ', Msg, ' -> ', E.ClassName);
  end;
end;

procedure Test_EraseAfter_Strict_Unreachable_ShouldRaise;
var L: TIntFL; it,last: specialize TIter<Integer>;
begin
  L := TIntFL.Create;
  try
    L.PushFront(3); L.PushFront(2); L.PushFront(1); // 列表为 1,2,3
    // 构造不可达：aPosition 指向 2，aLast 指向 1（从 2 的 next 开始无法到达 1）
    it := L.Iter; it.MoveNext; it.MoveNext; // 现在 it 在元素 2
    last := L.Iter; last.MoveNext;          // 现在 last 在元素 1
    try
      L.EraseAfter(it, last);
      WriteLn('ASSERT FAIL(no exception): EraseAfter strict unreachable'); Halt(1);
    except
      on E: Exception do WriteLn('OK expected: EraseAfter strict unreachable -> ', E.ClassName);
    end;
  finally
    L.Free;
  end;
end;

procedure Test_Splice_Combinations;
var A,B:TIntFL; pos, first, last: specialize TIter<Integer>;
begin
  A := TIntFL.Create; B := TIntFL.Create;
  try
    // A 空表；B: 1,2,3
    B.PushFront(3); B.PushFront(2); B.PushFront(1);
    pos := A.BeforeBegin;
    first := B.Iter; // begin -> 1
    last := B.Iter;  // 构造空区间：first==last 表示不移动
    A.Splice(pos, B, first, last); // 空区间不变

    // 取 [begin, end) 整表插入到 A 头（before_begin 后）
    first := B.Iter;
    last := B.CEnd;
    A.Splice(pos, B, first, last);

    // 单元素 splice_after：将 A 的 begin 后一个元素移动到末尾
    first := A.BeforeBegin;
    pos := A.CEnd; // 末尾
    A.Splice(pos, A, first);

    WriteLn('Splice combinations executed');
  finally
    A.Free; B.Free;
  end;
end;

begin
  try
    Test_EraseAfter_Strict_Unreachable_ShouldRaise;
    Test_Splice_Combinations;
    WriteLn('Strict EraseAfter and Splice mix tests passed');
  except
    on E: Exception do begin
      WriteLn('Test failed: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.

