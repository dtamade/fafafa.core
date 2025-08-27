program merge_and_splice_edge_tests;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.collections.base,
  fafafa.core.collections.forwardList;

type
  TIntFL = specialize TForwardList<Integer>;

function CmpDesc(const x,y: Integer; data: Pointer): Int64; begin Exit(Int64(y)-Int64(x)); end;

procedure AssertTrue(const Msg: string; Cond: Boolean);
begin
  if not Cond then begin WriteLn('ASSERT FAIL: ', Msg); Halt(1); end;
end;

procedure AssertEq(const Msg: string; A, B: Integer);
begin
  if A <> B then begin WriteLn('ASSERT FAIL: ', Msg, ' got=',A,' expect=',B); Halt(1); end;
end;

function ToArray(L: TIntFL): specialize TGenericArray<Integer>;
begin
  Exit(L.ToArray);
end;

procedure Test_Merge_DefaultCompare_Sorted;
var A,B:TIntFL; arr: specialize TGenericArray<Integer>; i: Integer;
begin
  A := TIntFL.Create; B := TIntFL.Create;
  try
    // A: 1,3,5 ; B: 2,4,6
    A.PushFront(5); A.PushFront(3); A.PushFront(1);
    B.PushFront(6); B.PushFront(4); B.PushFront(2);
    A.Sort; B.Sort;
    A.Merge(B);
    AssertTrue('B cleared after merge', B.GetCount=0);
    arr := ToArray(A);
    AssertEq('len', Length(arr), 6);
    for i:=0 to High(arr) do AssertEq('sorted', arr[i], i+1);
  finally A.Free; B.Free; end;
end;

procedure Test_Merge_MethodCompare;
var A,B:TIntFL; arr: specialize TGenericArray<Integer>;
begin
  A := TIntFL.Create; B := TIntFL.Create;
  try
    A.PushFront(1); A.PushFront(3); A.PushFront(5);
    B.PushFront(2); B.PushFront(4); B.PushFront(6);
    // 自定义比较：降序（方法重载）
    A.Merge(B, @CmpDesc, nil);
    arr := ToArray(A);
    AssertTrue('merged size', Length(arr)=6);
    AssertTrue('desc order', (arr[0]=6) and (arr[5]=1));
  finally A.Free; B.Free; end;
end;

procedure Test_Splice_BeforeBegin_And_End;
var A,B:TIntFL; pos, first, last: specialize TIter<Integer>; arr: specialize TGenericArray<Integer>;
begin
  A := TIntFL.Create; B := TIntFL.Create;
  try
    // A: 10,20 ; B: 1,2,3
    A.PushFront(20); A.PushFront(10);
    B.PushFront(3); B.PushFront(2); B.PushFront(1);

    // splice [begin, end) 到 A 的 before_begin 后一个位置（等价插在头结点之后）
    pos := A.BeforeBegin;
    first := B.Iter; // B 的 begin
    last := B.CEnd;  // 到末尾
    A.Splice(pos, B, first, last);

    // A 现在应为：10,1,2,3,20 或 1,2,3 插到头结点之后，具体取决于实现语义（此处按实现语义：插在头结点之后）
    arr := ToArray(A);
    AssertEq('A size', Length(arr), 5);
    AssertTrue('B empty', B.GetCount=0);
  finally A.Free; B.Free; end;
end;

procedure Test_Splice_Single_Element;
var A,B:TIntFL; first, pos: specialize TIter<Integer>; arr: specialize TGenericArray<Integer>;
begin
  A := TIntFL.Create; B := TIntFL.Create;
  try
    A.PushFront(3); A.PushFront(2); A.PushFront(1);
    B.PushFront(6); B.PushFront(5); B.PushFront(4);

    // 将 B 的第一个元素(4) 插入到 A 的末尾
    first := B.BeforeBegin; // 之后的单个元素是 4
    pos := A.CEnd;          // 插入到 A 的开头（实现中 CEnd 表示开头插入）
    A.Splice(pos, B, first);

    arr := ToArray(A);
    AssertEq('A size', Length(arr), 4);
    AssertTrue('B size 2', B.GetCount=2);
  finally A.Free; B.Free; end;
end;

begin
  try
    Test_Merge_DefaultCompare_Sorted;
    Test_Merge_MethodCompare;
    Test_Splice_BeforeBegin_And_End;
    Test_Splice_Single_Element;
    WriteLn('Merge and Splice edge tests passed');
  except
    on E: Exception do begin
      WriteLn('Test failed: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.

