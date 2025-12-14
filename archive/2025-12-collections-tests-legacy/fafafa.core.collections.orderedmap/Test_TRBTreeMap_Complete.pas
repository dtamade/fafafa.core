{$CODEPAGE UTF8}
unit Test_TRBTreeMap_Complete;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections.orderedmap.rb,
  fafafa.core.collections.base;

type
  TTestCase_TRBTreeMap = class(TTestCase)
  published
    procedure Test_InsertOrAssign_TryGet_Remove;
    procedure Test_Ordered_PtrIter;
    procedure Test_Range_Iter;
    procedure Test_Range_Iter_Extra; // 新增扩展边界与托管值测试
    procedure Test_Keys_Values_Views;
    procedure Test_Keys_Values_Views_ReverseAndAlign;
    procedure Test_CustomComparer_LengthFirst;
    procedure Test_ManagedValues_MutationsAndIterate;
    procedure Test_NewAPIs;
    procedure Test_NewAPIs_UpperBound_Edge;
    procedure Test_NewAPIs_LowerBound_Edge;
    procedure Test_RangePagination_Basic;
    procedure Test_RangePagination_Strategies_Equivalence;
    procedure Test_RangeBoundary_Cases;
    procedure Test_RangePagination_InclusiveRight_Alignment;
    procedure Test_CaseInsensitive_Boundary_Consistency;
    procedure Test_RangePagination_VarPageSizes;
    procedure Test_RangePagination_Bidirectional_FromMiddle;
    procedure Test_RangePagination_SparseKeys;
    procedure Test_TryUpdate_Extract_NegativePaths;
    procedure Test_Extract_ManagedValue_Semantics;
    procedure Test_Randomized_Small_Stability;
  end;


implementation

type
  TStrIntMap = specialize TRBTreeMap<string,Integer>;

function CaseInsensitiveCompare(const L, R: string; aData: Pointer): SizeInt;
begin
  Result := CompareText(L, R);
  if Result < 0 then Exit(-1) else if Result > 0 then Exit(1) else Exit(0);
end;

function LengthFirstCompare(const L, R: string; aData: Pointer): SizeInt;
var d: SizeInt;
begin
  d := Length(L) - Length(R);
  if d < 0 then Exit(-1) else if d > 0 then Exit(1);
  Result := CaseInsensitiveCompare(L, R, aData);
end;

procedure TTestCase_TRBTreeMap.Test_InsertOrAssign_TryGet_Remove;
var M: TStrIntMap; got: Integer;
begin
  M := TStrIntMap.Create(@CaseInsensitiveCompare);
  try
    // insert
    AssertTrue(M.InsertOrAssign('a', 1));
    AssertTrue(M.TryGetValue('A', got) and (got=1));
    // update
    AssertFalse(M.InsertOrAssign('A', 9));
    AssertTrue(M.TryGetValue('a', got) and (got=9));
    // remove
    AssertTrue(M.Remove('A'));
    AssertFalse(M.TryGetValue('a', got));
  finally
    M.Free;
  end;
end;

procedure TTestCase_TRBTreeMap.Test_Ordered_PtrIter;
var M: TStrIntMap; It: TPtrIter; P: ^TStrIntMap.TEntry; last: string;
begin
  M := TStrIntMap.Create(@CaseInsensitiveCompare);
  try
    M.InsertOrAssign('b',2);
    M.InsertOrAssign('a',1);
    M.InsertOrAssign('c',3);
    It := M.PtrIter;
    last := '';
    while It.MoveNext do begin
      P := It.GetCurrent;
      if last<>'' then AssertTrue(CompareText(P^.Key, last) > 0);
      last := P^.Key;
    end;
  finally
    M.Free;
  end;
end;

procedure TTestCase_TRBTreeMap.Test_Range_Iter;
var M: TStrIntMap; It: TPtrIter; P: ^TStrIntMap.TEntry; Cnt: SizeInt;
begin
  M := TStrIntMap.Create(@CaseInsensitiveCompare);
  try
    M.InsertOrAssign('a',1);
    M.InsertOrAssign('b',2);
    M.InsertOrAssign('c',3);
    M.InsertOrAssign('d',4);
    // [b,d)
    It := M.IterateRange('b','d', False);
    Cnt := 0;
    while It.MoveNext do begin
      Inc(Cnt);
      P := It.GetCurrent;
      AssertTrue((CompareText(P^.Key,'b')>=0) and (CompareText(P^.Key,'d')<0));
    end;
    AssertEquals(2, Cnt);
    // [b,d]
    It := M.IterateRange('b','d', True);
    Cnt := 0;
    while It.MoveNext do begin
      Inc(Cnt);
      P := It.GetCurrent;
      AssertTrue((CompareText(P^.Key,'b')>=0) and (CompareText(P^.Key,'d')<=0));
    end;
    AssertEquals(3, Cnt);
  finally
    M.Free;
  end;
end;

// 额外边界测试：Left>Right、Left=Right 两种包含语义；以及反向迭代、托管值类型
procedure TTestCase_TRBTreeMap.Test_Range_Iter_Extra;
var
  M: TStrIntMap;
  It: TPtrIter;
  P: ^TStrIntMap.TEntry;
  Cnt: SizeInt;
  S: string;
  M2: specialize TRBTreeMap<string,string>;

  function CmpS(const L,R:string; aData: Pointer): SizeInt;
  begin
    Result := CompareText(L,R);
    if Result<0 then Exit(-1) else if Result>0 then Exit(1) else Exit(0);
  end;
begin
  M := TStrIntMap.Create(@CaseInsensitiveCompare);
  try
    // 数据
    M.InsertOrAssign('a',1);
    M.InsertOrAssign('b',2);
    M.InsertOrAssign('c',3);
    // Left > Right -> 空
    It := M.IterateRange('d','b', False);
    AssertFalse(It.MoveNext);
    // Left == Right：半开为空
    It := M.IterateRange('b','b', False);
    AssertFalse(It.MoveNext);
    // Left == Right：全闭为单点
    It := M.IterateRange('b','b', True);
    Cnt := 0;
    while It.MoveNext do begin
      Inc(Cnt);
      P := It.GetCurrent;
      AssertEquals('b', P^.Key);
      AssertEquals(2, P^.Value);
    end;
    AssertEquals(1, Cnt);
    // 反向迭代（通过 MovePrev）
    // 直接用反向迭代统计全部元素
    It := M.PtrIter;
    Cnt := 0;
    while It.MovePrev do Inc(Cnt);
    AssertEquals(3, Cnt);
    // 托管类型值：string
    M2 := specialize TRBTreeMap<string,string>.Create(@CaseInsensitiveCompare);
    try
      M2.InsertOrAssign('k','v');
      S := '';
      AssertTrue(M2.TryGetValue('K', S) and (S='v'));
    finally
      M2.Free;
    end;
  finally
    M.Free;
  end;
end;


procedure TTestCase_TRBTreeMap.Test_Keys_Values_Views;
var M: TStrIntMap; KI: specialize TIter<string>; VI: specialize TIter<Integer>;
    lastK, curK: string; lastV: Integer;
begin
  M := TStrIntMap.Create(@CaseInsensitiveCompare);
  try
    M.InsertOrAssign('b',2);
    M.InsertOrAssign('a',1);
    M.InsertOrAssign('c',3);
    KI := M.Keys;
    lastK := '';
    while KI.MoveNext do begin
      curK := KI.GetCurrent;
      if lastK<>'' then AssertTrue(CompareText(curK, lastK) > 0);
      lastK := curK;
    end;
    VI := M.Values;
    lastV := -MaxInt;
    while VI.MoveNext do begin
      lastV := VI.GetCurrent;
      AssertTrue(lastV >= 1);
    end;
  finally
    M.Free;
  end;

end;


procedure TTestCase_TRBTreeMap.Test_CustomComparer_LengthFirst;
var M: specialize TRBTreeMap<string,Integer>;

  var It: TPtrIter; P: ^TStrIntMap.TEntry; lastLen: SizeInt;
begin
  M := specialize TRBTreeMap<string,Integer>.Create(@LengthFirstCompare);
  try
    M.InsertOrAssign('bb',2);
    M.InsertOrAssign('a',1);
    M.InsertOrAssign('ccc',3);
    M.InsertOrAssign('aa',4);
    // 验证长度优先，再按不区分大小写字典序
    It := M.PtrIter;
    lastLen := 0;
    while It.MoveNext do begin
      P := It.GetCurrent;
      AssertTrue(Length(P^.Key) >= lastLen);
      lastLen := Length(P^.Key);
    end;
  finally
    M.Free;
  end;
end;

procedure TTestCase_TRBTreeMap.Test_ManagedValues_MutationsAndIterate;
var M: specialize TRBTreeMap<string,string>;
    KI: specialize TIter<string>; VI: specialize TIter<string>;
    s: string;
begin
  M := specialize TRBTreeMap<string,string>.Create(@CaseInsensitiveCompare);
  try
    // 插入与更新
    AssertTrue(M.InsertOrAssign('a','A1'));
    AssertFalse(M.InsertOrAssign('A','A2'));
    AssertTrue(M.InsertOrAssign('b','B1'));
    // 删除并再次插入
    AssertTrue(M.Remove('a'));
    AssertTrue(M.InsertOrAssign('c','C1'));
    // 遍历 Keys/Values
    KI := M.Keys; s := '';


    while KI.MoveNext do s := s + KI.GetCurrent;
    AssertTrue(Length(s) >= 2);
    VI := M.Values; s := '';
    while VI.MoveNext do s := s + VI.GetCurrent;
    AssertTrue(Pos('B1', s)>0);
  finally
    M.Free;
  end;
end;

// 新 API：TryAdd/TryUpdate/Extract/LowerBoundKey/UpperBoundKey

// （性能演示已迁移到 samples，不在单元测试中保留）

procedure TTestCase_TRBTreeMap.Test_NewAPIs;
var M: TStrIntMap; E: TStrIntMap.TEntry; got: Integer;
begin
  M := TStrIntMap.Create(@CaseInsensitiveCompare);
  try
    AssertTrue(M.TryAdd('a',1));
    AssertFalse(M.TryAdd('A',9));
    AssertTrue(M.TryUpdate('a',2));
    AssertTrue(M.TryGetValue('a', got) and (got=2));
    AssertTrue(M.LowerBoundKey('a', E) and (E.Value=2));
    AssertTrue(M.UpperBoundKey('a', E));
    AssertTrue(M.Extract('a', E) and (E.Value=2));
    AssertFalse(M.ContainsKey('a'));
  finally
    M.Free;
  end;
end;


procedure TTestCase_TRBTreeMap.Test_Keys_Values_Views_ReverseAndAlign;
var M: TStrIntMap;
    KI: specialize TIter<string>; VI: specialize TIter<Integer>;
    KList: array[0..2] of string; VList: array[0..2] of Integer;
    I: Integer;
begin
  M := TStrIntMap.Create(@CaseInsensitiveCompare);
  try
    M.InsertOrAssign('b',2);
    M.InsertOrAssign('a',1);
    M.InsertOrAssign('c',3);
    // 反向迭代 keys（用新迭代器直接 MovePrev）
    KI := M.Keys;
    I := 2;
    while KI.MovePrev do begin
      KList[I] := KI.GetCurrent;
      Dec(I);
    end;
    AssertEquals(AnsiString('c'), KList[2]);
    AssertEquals(AnsiString('b'), KList[1]);
    AssertEquals(AnsiString('a'), KList[0]);
    // 反向迭代 values，并与 keys 的顺序对齐（相同下标）
    VI := M.Values;
    I := 2;
    while VI.MovePrev do begin
      VList[I] := VI.GetCurrent;
      Dec(I);
    end;
    // 对齐校验：a->1, b->2, c->3
    AssertEquals(1, VList[0]);
    AssertEquals(2, VList[1]);
    AssertEquals(3, VList[2]);
  finally
    M.Free;
  end;
end;

procedure TTestCase_TRBTreeMap.Test_NewAPIs_UpperBound_Edge;
var M: TStrIntMap; E: TStrIntMap.TEntry;
begin
  M := TStrIntMap.Create(@CaseInsensitiveCompare);
  try
    AssertTrue(M.TryAdd('a',1));
    AssertTrue(M.TryAdd('b',2));
    AssertTrue(M.TryAdd('c',3));
    // 大于所有键
    AssertFalse(M.UpperBoundKey('z', E));
    // 小于所有键 => 返回最小元素
    AssertTrue(M.UpperBoundKey('' , E));
    AssertEquals(1, E.Value);

  finally
    M.Free;
  end;
end;

procedure TTestCase_TRBTreeMap.Test_RangePagination_Basic;
var M: TStrIntMap; lastKey, firstKey: string; It: TPtrIter; P: ^TStrIntMap.TEntry; n: Integer; i: Integer;
begin
  M := TStrIntMap.Create(@CaseInsensitiveCompare);
  try
    // 数据：k00001..k00030 -> 1..30
    for i := 1 to 30 do M.InsertOrAssign('k' + Format('%.5d', [i]), i);

    // Page1 next from k00001 size=5
    lastKey := '';
    n := 0; It := M.IterateRange('k00001', 'k99999', True);
    while (n<5) and It.MoveNext do begin P := It.GetCurrent; Inc(n); lastKey := P^.Key; end;
    AssertEquals(5, n);
    AssertEquals(AnsiString('k00005'), lastKey);

    // Page2 next from lastKey+1 size=5
    n := 0; It := M.IterateRange(lastKey + #1, 'k99999', True);
    while (n<5) and It.MoveNext do begin P := It.GetCurrent; Inc(n); lastKey := P^.Key; end;
    AssertEquals(5, n);
    AssertEquals(AnsiString('k00010'), lastKey);

    // Prev page before k00011 size=3
    firstKey := '';
    It := M.IterateRange('', 'k00011', False);
    while It.MoveNext do ; // seek to end of the range
    n := 0;
    while (n<3) and It.MovePrev do begin P := It.GetCurrent; Inc(n); firstKey := P^.Key; end;
    AssertEquals(3, n);
    AssertEquals(AnsiString('k00008'), firstKey);
  finally
    M.Free;
  end;
end;



procedure TTestCase_TRBTreeMap.Test_NewAPIs_LowerBound_Edge;
var M: TStrIntMap; E: TStrIntMap.TEntry;
begin
  M := TStrIntMap.Create(@CaseInsensitiveCompare);
  try
    AssertTrue(M.TryAdd('b',2));
    AssertTrue(M.TryAdd('d',4));
    // 小于最小键 => 返回最小（b,2）
    AssertTrue(M.LowerBoundKey('a', E));
    AssertEquals(2, E.Value);
    // 大于最大键 => 返回 False
    AssertFalse(M.LowerBoundKey('z', E));
  finally
    M.Free;
  end;
end;


procedure TTestCase_TRBTreeMap.Test_RangePagination_Strategies_Equivalence;
var M: TStrIntMap; lastA, lastB: string; It: TPtrIter; P: ^TStrIntMap.TEntry; n: Integer; i: Integer; It2: TPtrIter; Q: ^TStrIntMap.TEntry; n2: Integer; E, E2: TStrIntMap.TEntry;
begin
  M := TStrIntMap.Create(@CaseInsensitiveCompare);
  try
    for i := 1 to 20 do M.InsertOrAssign('k' + Format('%.5d', [i]), i);

    // 策略A：lastKey + #1
    n := 0; It := M.IterateRange('k00001','k99999',True);
    while (n<7) and It.MoveNext do begin P := It.GetCurrent; Inc(n); lastA := P^.Key; end; // k00007
    n := 0; It := M.IterateRange(lastA + #1,'k99999',True);
    while (n<7) and It.MoveNext do begin P := It.GetCurrent; Inc(n); lastA := P^.Key; end; // k00014

    // 策略B：UpperBoundKey(lastKey)

    n := 0; It := M.IterateRange('k00001','k99999',True);
    while (n<7) and It.MoveNext do begin P := It.GetCurrent; Inc(n); lastB := P^.Key; end; // k00007
    if M.UpperBoundKey(lastB, E) then lastB := E.Key else lastB := 'k99999';
    n := 0; It := M.IterateRange(lastB,'k99999',True);
    while (n<7) and It.MoveNext do begin P := It.GetCurrent; Inc(n); lastB := P^.Key; end; // k00014

    AssertEquals(AnsiString('k00014'), lastA);
    AssertEquals(AnsiString('k00014'), lastB);


    // 大小写变体同键分页：验证两策略一致
    M.InsertOrAssign('Key', 100);
    M.InsertOrAssign('kEy', 200);
    // 先取 1 个，停在 'Key'
    n2 := 0; It2 := M.IterateRange('Key','k99999',True);
    while (n2<1) and It2.MoveNext do begin Q := It2.GetCurrent; Inc(n2); lastA := Q^.Key; end;
    // 策略C：lastKey + #1
    if lastA<>'' then begin
      It2 := M.IterateRange(lastA + #1,'k99999',True);
      if It2.MoveNext then begin Q := It2.GetCurrent; lastA := Q^.Key; end;
    end;
    // 策略D：UpperBoundKey(lastKey)
    if M.UpperBoundKey('Key', E2) then lastB := E2.Key else lastB := 'k99999';
    AssertEquals(AnsiString(lastA), lastB);


  finally
    M.Free;
  end;
end;

procedure TTestCase_TRBTreeMap.Test_RangeBoundary_Cases;
var M: TStrIntMap; It: TPtrIter; E: TStrIntMap.TEntry; n: Integer; P: ^TStrIntMap.TEntry;
begin
  M := TStrIntMap.Create(@CaseInsensitiveCompare);
  try
    // 空 Map：范围与边界查询
    It := M.IterateRange('a','z',True);
    AssertFalse(It.MoveNext);

    AssertFalse(M.LowerBoundKey('a', E));
    AssertFalse(M.UpperBoundKey('a', E));

    // 不足一页：仅 3 个元素，请求 5 个
    M.InsertOrAssign('b',2);
    M.InsertOrAssign('c',3);
    M.InsertOrAssign('d',4);
    n := 0;
    It := M.IterateRange('a','z',True);
    while (n<5) and It.MoveNext do begin P := It.GetCurrent; Inc(n); end;
    AssertEquals(3, n);

    // 跨边界：小于最小/大于最大
    It := M.IterateRange('A','B',True); // 小于最小（不区分大小写比较器）
    AssertFalse(It.MoveNext);
    It := M.IterateRange('y','z',True); // 大于最大
    AssertFalse(It.MoveNext);
  finally
    M.Free;
  end;
end;

procedure TTestCase_TRBTreeMap.Test_RangePagination_InclusiveRight_Alignment;
var M: TStrIntMap; It: TPtrIter; P: ^TStrIntMap.TEntry; lastKey: string; n: Integer; i: Integer; E: TStrIntMap.TEntry;
begin
  M := TStrIntMap.Create(@CaseInsensitiveCompare);
  try
    // k00001..k00006
    for i := 1 to 6 do M.InsertOrAssign('k' + Format('%.5d', [i]), i);

    // 半开 [L,R)：取 [k00001,k00003) => k00001,k00002；下一页从 lastKey+1 开始应为 k00003
    n := 0; lastKey := '';
    It := M.IterateRange('k00001','k00003', False);
    while (n<10) and It.MoveNext do begin P := It.GetCurrent; Inc(n); lastKey := P^.Key; end;
    AssertEquals(2, n); AssertEquals(AnsiString('k00002'), lastKey);
    It := M.IterateRange(lastKey + #1, 'k99999', True);
    AssertTrue(It.MoveNext); P := It.GetCurrent; AssertEquals(AnsiString('k00003'), P^.Key);

    // 全闭 [L,R]：取 [k00001,k00003] => k00001,k00002,k00003；下一页从 UpperBound(k00003) 应为 k00004
    n := 0; lastKey := '';
    It := M.IterateRange('k00001','k00003', True);
    while (n<10) and It.MoveNext do begin P := It.GetCurrent; Inc(n); lastKey := P^.Key; end;
    AssertEquals(3, n); AssertEquals(AnsiString('k00003'), lastKey);

    AssertTrue(M.UpperBoundKey(lastKey, E));
    It := M.IterateRange(E.Key, 'k99999', True);
    AssertTrue(It.MoveNext); P := It.GetCurrent; AssertEquals(AnsiString('k00004'), P^.Key);
  finally
    M.Free;
  end;
end;

procedure TTestCase_TRBTreeMap.Test_CaseInsensitive_Boundary_Consistency;
var M: TStrIntMap; E: TStrIntMap.TEntry; got: Integer;
begin
  M := TStrIntMap.Create(@CaseInsensitiveCompare);
  try
    // 'a' 与 'A' 视为同键
    AssertTrue(M.TryAdd('a',1));
    AssertFalse(M.TryAdd('A',2));
    AssertTrue(M.TryGetValue('A', got) and (got=1));

    // LowerBound/UpperBound 在大小写变化下应一致
    AssertTrue(M.LowerBoundKey('a', E)); AssertEquals(AnsiString('a'), E.Key);
    AssertTrue(M.LowerBoundKey('A', E)); AssertEquals(AnsiString('a'), E.Key);

    // UpperBoundKey 跳过等值键（大小写变体）
    M.InsertOrAssign('b',2);
    AssertTrue(M.UpperBoundKey('A', E)); AssertEquals(AnsiString('b'), E.Key);
  finally
    M.Free;
  end;
end;



procedure TTestCase_TRBTreeMap.Test_RangePagination_VarPageSizes;
var M: TStrIntMap; It: TPtrIter; P: ^TStrIntMap.TEntry; lastKey: string; n, i: Integer;
begin
  M := TStrIntMap.Create(@CaseInsensitiveCompare);
  try
    for i := 1 to 7 do M.InsertOrAssign('k' + Format('%.5d', [i]), i);
    // size=1
    lastKey := ''; n := 0; It := M.IterateRange('k00001','k99999',True);
    while (n<1) and It.MoveNext do begin P := It.GetCurrent; Inc(n); lastKey := P^.Key; end;
    AssertEquals(1, n); AssertEquals(AnsiString('k00001'), lastKey);
    // next size=10（超过剩余元素）
    n := 0; It := M.IterateRange(lastKey + #1,'k99999',True);
    while (n<10) and It.MoveNext do begin P := It.GetCurrent; Inc(n); lastKey := P^.Key; end;
    AssertEquals(6, n); AssertEquals(AnsiString('k00007'), lastKey);
  finally
    M.Free;
  end;
end;

procedure TTestCase_TRBTreeMap.Test_RangePagination_Bidirectional_FromMiddle;
var M: TStrIntMap; It: TPtrIter; P: ^TStrIntMap.TEntry; lastKey, firstKey: string; n, i: Integer;
begin
  M := TStrIntMap.Create(@CaseInsensitiveCompare);
  try
    for i := 1 to 10 do M.InsertOrAssign('k' + Format('%.5d', [i]), i);
    // 从中间 k00006 开始，向前取 3，再向后取 3，检查相邻不重叠
    firstKey := ''; It := M.IterateRange('', 'k00006', False); while It.MoveNext do ;
    n := 0; while (n<3) and It.MovePrev do begin P := It.GetCurrent; if n=0 then firstKey := P^.Key; Inc(n); end;
    AssertEquals(3, n); AssertEquals(AnsiString('k00004'), firstKey);
    lastKey := ''; It := M.IterateRange('k00006', 'k99999', True);
    n := 0; while (n<3) and It.MoveNext do begin P := It.GetCurrent; lastKey := P^.Key; Inc(n); end;
    AssertEquals(3, n); AssertEquals(AnsiString('k00008'), lastKey);
  finally
    M.Free;
  end;
end;

procedure TTestCase_TRBTreeMap.Test_RangePagination_SparseKeys;
var M: TStrIntMap; It: TPtrIter; P: ^TStrIntMap.TEntry; lastKey: string; n: Integer;
begin
  M := TStrIntMap.Create(@CaseInsensitiveCompare);
  try
    // 稀疏：k00001,k00003,k00007
    M.InsertOrAssign('k00001',1);
    M.InsertOrAssign('k00003',3);
    M.InsertOrAssign('k00007',7);
    // 从 k00001 size=2 => 取 k00001,k00003；下一页应落到 k00007
    n := 0; lastKey := ''; It := M.IterateRange('k00001','k99999',True);
    while (n<2) and It.MoveNext do begin P := It.GetCurrent; lastKey := P^.Key; Inc(n); end;
    AssertEquals(2, n); AssertEquals(AnsiString('k00003'), lastKey);
    It := M.IterateRange(lastKey + #1,'k99999',True);
    AssertTrue(It.MoveNext); P := It.GetCurrent; AssertEquals(AnsiString('k00007'), P^.Key);
  finally
    M.Free;
  end;
end;



procedure TTestCase_TRBTreeMap.Test_TryUpdate_Extract_NegativePaths;
var M: TStrIntMap; E: TStrIntMap.TEntry; got: Integer;
begin
  M := TStrIntMap.Create(@CaseInsensitiveCompare);
  try
    // TryUpdate 不存在
    AssertFalse(M.TryUpdate('no', 1));
    // Extract 不存在
    AssertFalse(M.Extract('no', E));
    // 插入后 Extract 一次成功、再次失败
    AssertTrue(M.TryAdd('a', 1));
    AssertTrue(M.Extract('a', E) and (E.Value=1));
    AssertFalse(M.Extract('a', E));
    // Extract 后 TryGetValue 不再命中
    AssertFalse(M.TryGetValue('a', got));
  finally
    M.Free;
  end;
end;

procedure TTestCase_TRBTreeMap.Test_Extract_ManagedValue_Semantics;
var M: specialize TRBTreeMap<string,AnsiString>; E: specialize TRBTreeMap<string,AnsiString>.TEntry; v: AnsiString;
begin
  M := specialize TRBTreeMap<string,AnsiString>.Create(@CaseInsensitiveCompare);
  try
    v := 'hello';
    AssertTrue(M.TryAdd('k', v));
    // Extract 应搬移出值，不再占有内部资源
    AssertTrue(M.Extract('k', E));
    AssertEquals(AnsiString('hello'), E.Value);
    // 再次 Extract 应失败
    AssertFalse(M.Extract('k', E));
  finally
    M.Free;
  end;
end;

procedure TTestCase_TRBTreeMap.Test_Randomized_Small_Stability;
const N = 200; // 小规模，快速
var M: TStrIntMap; L: array of string; i, ins, del, upd: Integer; got: Integer; It: TPtrIter; P: ^TStrIntMap.TEntry; last: string;

  function KeyOf(i: Integer): string; inline;
  begin
    Result := 'k' + Format('%.5d', [i]);
  end;

begin
  Randomize;
  M := TStrIntMap.Create(@CaseInsensitiveCompare);
  try
    SetLength(L, N);
    for i := 0 to N-1 do L[i] := KeyOf(i);

    // 初始化计数器，避免未初始化告警
    ins := 0; upd := 0; del := 0;

    // 随机操作序列
    for i := 0 to N*2-1 do begin
      case Random(3) of
        0: begin // insert or assign
             if M.InsertOrAssign(L[Random(N)], i) then Inc(ins) else Inc(upd);
           end;
        1: begin // remove
             if M.Remove(L[Random(N)]) then Inc(del);
           end;
        2: begin // tryupdate
             M.TryUpdate(L[Random(N)], i);
           end;
      end;
    end;

    // 有序性与计数 sanity：遍历单调
    last := '';
    It := M.PtrIter;
    while It.MoveNext do begin
      P := It.GetCurrent;
      if last<>'' then AssertTrue(CompareText(P^.Key, last) > 0);
      last := P^.Key;
    end;

    // Spot check：若存在某键，TryGetValue 必须返回
    if M.InsertOrAssign('zzzz', 1) then ;
    AssertTrue(M.TryGetValue('ZZZZ', got));
  finally
    M.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_TRBTreeMap);


end.
